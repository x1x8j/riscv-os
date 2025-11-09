// 支持涉及文件描述符的系统调用的辅助函数。

#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "fs.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "file.h"
#include "stat.h"
#include "proc.h"

struct devsw devsw[NDEV];  // 设备交换表
struct {
  struct spinlock lock;    // 保护文件表的自旋锁
  struct file file[NFILE]; // 文件表
} ftable;

// 文件表初始化
void
fileinit(void)
{
  initlock(&ftable.lock, "ftable");  // 初始化文件表的自旋锁
}

// 分配一个新的文件结构体
struct file*
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);  // 获取文件表锁
  // 遍历文件表，找到引用计数为 0 的文件结构体
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
      f->ref = 1;  // 设置引用计数为 1
      release(&ftable.lock);  // 释放文件表锁
      return f;  // 返回分配的文件结构体
    }
  }
  release(&ftable.lock);  // 如果没有空闲文件结构体，释放锁
  return 0;  // 没有可用的文件结构体
}

// 增加文件结构体的引用计数
struct file*
filedup(struct file *f)
{
  acquire(&ftable.lock);  // 获取文件表锁
  if(f->ref < 1)  // 如果引用计数小于 1，说明文件结构体无效
    panic("filedup");
  f->ref++;  // 增加引用计数
  release(&ftable.lock);  // 释放文件表锁
  return f;  // 返回文件结构体
}

// 关闭文件结构体 f，减少引用计数，当引用计数为 0 时关闭文件
void
fileclose(struct file *f)
{
  struct file ff;

  acquire(&ftable.lock);  // 获取文件表锁
  if(f->ref < 1)  // 如果引用计数小于 1，说明文件结构体无效
    panic("fileclose");
  if(--f->ref > 0){  // 如果引用计数大于 0，直接返回
    release(&ftable.lock);
    return;
  }
  ff = *f;  // 备份文件结构体
  f->ref = 0;  // 重置引用计数
  f->type = FD_NONE;  // 重置文件类型
  release(&ftable.lock);  // 释放文件表锁

  // 如果文件类型是管道（pipe），则关闭管道
  if(ff.type == FD_PIPE){
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    begin_op();  // 开始一个文件系统操作
    iput(ff.ip);  // 释放 inode
    end_op();  // 结束文件系统操作
  }
}

// 获取文件 f 的元数据（如文件大小、类型等）
// addr 是一个用户虚拟地址，指向 struct stat 结构
int
filestat(struct file *f, uint64 addr)
{
  struct proc *p = myproc();  // 获取当前进程
  struct stat st;
  
  // 如果文件是 inode 类型或设备类型
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    ilock(f->ip);  // 锁定 inode
    stati(f->ip, &st);  // 获取 inode 的元数据
    iunlock(f->ip);  // 解锁 inode
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)  // 将元数据复制到用户地址
      return -1;
    return 0;
  }
  return -1;  // 其他类型文件不支持
}

// 从文件 f 中读取数据。
// addr 是一个用户虚拟地址。
int
fileread(struct file *f, uint64 addr, int n)
{
  int r = 0;

  if(f->readable == 0)  // 如果文件不可读，返回 -1
    return -1;

  // 根据文件类型执行不同的读取操作
  if(f->type == FD_PIPE){
    r = piperead(f->pipe, addr, n);  // 从管道中读取
  } else if(f->type == FD_DEVICE){
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)  // 如果设备不支持读取，返回 -1
      return -1;
    r = devsw[f->major].read(1, addr, n);  // 调用设备的读取函数
  } else if(f->type == FD_INODE){
    ilock(f->ip);  // 锁定 inode
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)  // 从 inode 中读取数据
      f->off += r;  // 更新文件偏移量
    iunlock(f->ip);  // 解锁 inode
  } else {
    panic("fileread");  // 不支持的文件类型
  }

  return r;  // 返回读取的字节数
}

// 向文件 f 中写入数据。
// addr 是一个用户虚拟地址。
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)  // 如果文件不可写，返回 -1
    return -1;

  // 根据文件类型执行不同的写入操作
  if(f->type == FD_PIPE){
    ret = pipewrite(f->pipe, addr, n);  // 向管道中写入
  } else if(f->type == FD_DEVICE){
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)  // 如果设备不支持写入，返回 -1
      return -1;
    ret = devsw[f->major].write(1, addr, n);  // 调用设备的写入函数
  } else if(f->type == FD_INODE){
    // 分多次写入，以避免超过最大日志事务大小，包括 inode、间接块、分配块等
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
      int n1 = n - i;
      if(n1 > max)  // 如果写入数据超过最大限制，分批次写入
        n1 = max;

      begin_op();  // 开始一个文件系统操作
      ilock(f->ip);  // 锁定 inode
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
        f->off += r;  // 更新文件偏移量
      iunlock(f->ip);  // 解锁 inode
      end_op();  // 结束文件系统操作

      if(r != n1){  // 如果写入不完全，退出
        break;
      }
      i += r;
    }
    ret = (i == n ? n : -1);  // 如果写入完全成功，返回写入字节数，否则返回 -1
  } else {
    panic("filewrite");  // 不支持的文件类型
  }

  return ret;  // 返回写入的字节数
}

