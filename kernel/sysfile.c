//
// 文件系统系统调用。
// 主要进行参数检查，因为我们不信任用户代码，并调用 file.c 和 fs.c 中的函数。
//

#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "stat.h"
#include "spinlock.h"
#include "proc.h"
#include "fs.h"
#include "sleeplock.h"
#include "file.h"
#include "fcntl.h"

// 获取第n个系统调用参数作为文件描述符，并返回该描述符及对应的文件结构。
static int
argfd(int n, int *pfd, struct file **pf)
{
  int fd;
  struct file *f;

  argint(n, &fd);  // 获取系统调用参数中的文件描述符
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)  // 检查文件描述符的有效性
    return -1;
  if(pfd)
    *pfd = fd;
  if(pf)
    *pf = f;
  return 0;
}

// 为给定文件分配一个文件描述符。
// 成功时接管调用者的文件引用。
static int
fdalloc(struct file *f)
{
  int fd;
  struct proc *p = myproc();

  for(fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd] == 0){  // 查找一个未使用的文件描述符
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;  // 没有可用的文件描述符
}

uint64
sys_dup(void)
{
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    return -1;
  if((fd=fdalloc(f)) < 0)  // 为文件分配新的文件描述符
    return -1;
  filedup(f);  // 增加文件引用计数
  return fd;
}

uint64
sys_read(void)
{
  struct file *f;
  int n;
  uint64 p;

  argaddr(1, &p);  // 获取读取数据的用户空间地址
  argint(2, &n);  // 获取读取字节数
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    return -1;
  return fileread(f, p, n);  // 从文件中读取数据
}

uint64
sys_write(void)
{
  struct file *f;
  int n;
  uint64 p;
  
  argaddr(1, &p);  // 获取写入数据的用户空间地址
  argint(2, &n);  // 获取写入字节数
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    return -1;

  return filewrite(f, p, n);  // 向文件中写入数据
}

uint64
sys_close(void)
{
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)  // 获取文件描述符并返回文件结构
    return -1;
  myproc()->ofile[fd] = 0;  // 关闭文件描述符
  fileclose(f);  // 关闭文件
  return 0;
}

uint64
sys_fstat(void)
{
  struct file *f;
  uint64 st; // 用户指针指向 struct stat

  argaddr(1, &st);  // 获取 stat 结构体地址
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    return -1;
  return filestat(f, st);  // 获取文件状态信息
}

// 创建新路径 new，作为指向与 old 相同 inode 的另一个目录项（即硬链接）
uint64
sys_link(void)
{
  char name[DIRSIZ];        // 存放 new 路径中的最后一级文件名（如 "b" in "/a/b"）
  char new[MAXPATH], old[MAXPATH];  // 用户传入的两个路径字符串

  // 从系统调用参数中获取 old 和 new 路径（参数0=old, 参数1=new）
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    return -1;  // 路径无效或太长

  begin_op();  // 开始一个文件系统事务（用于日志一致性）

  // 通过 old 路径查找其对应的 inode（增加引用计数）
  if((ip = namei(old)) == 0){
    end_op();
    return -1;  // old 路径不存在
  }

  ilock(ip);  // 锁住该 inode，防止并发修改

  // 硬链接不能用于目录（避免目录环路，简化文件系统）
  if(ip->type == T_DIR){
    iunlockput(ip);  // 解锁并减少引用计数
    end_op();
    return -1;
  }

  // 先增加链接计数（nlink），后续若失败再回滚
  ip->nlink++;
  iupdate(ip);   // 将修改写回磁盘（inode 块）
  iunlock(ip);   // 解锁 inode（但仍持有引用）

  // 解析 new 路径：得到其父目录 dp 和文件名 name
  if((dp = nameiparent(new, name)) == 0)
    goto bad;  // new 路径无效或父目录不存在

  ilock(dp);  // 锁住父目录 inode

  // 检查是否在同一设备上（xv6 不支持跨设备硬链接）
  // 并尝试在父目录中添加新目录项：name -> ip->inum
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    iunlockput(dp);  // 添加失败，释放父目录
    goto bad;
  }

  iunlockput(dp);  // 成功添加，解锁并释放父目录引用
  iput(ip);        // 释放最初由 namei 获取的 ip 引用

  end_op();        // 提交事务
  return 0;        // 成功

bad:
  //  发生错误：回滚之前增加的 nlink
  ilock(ip);
  ip->nlink--;     // 恢复原链接数
  iupdate(ip);
  iunlockput(ip);  // 解锁并释放引用
  end_op();
  return -1;
}

// 判断目录 dp 是否为空（除了 "." 和 ".." 外没有其他有效目录项）
static int
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;  // 目录项结构：{ inum, name[DIRSIZ] }

  // 从偏移 2*sizeof(de) 开始扫描（跳过前两项："." 和 ".."）
  for(off = 2 * sizeof(de); off < dp->size; off += sizeof(de)){
    // 从目录 inode 中读取一个目录项到 de
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");  // 读取出错

    // 如果该目录项的 inum != 0，说明是一个有效文件/目录
    if(de.inum != 0)
      return 0;  // 非空
  }
  return 1;  // 所有后续项 inum==0，目录为空
}

uint64
sys_unlink(void)
{
  struct inode *ip, *dp;  // ip: 要删除的文件；dp: 其父目录
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;  // 在父目录中找到该文件的偏移位置

  // 获取用户传入的路径
  if(argstr(0, path, MAXPATH) < 0)
    return -1;

  begin_op();

  // 解析路径：得到父目录 dp 和文件名 name
  if((dp = nameiparent(path, name)) == 0){
    end_op();
    return -1;
  }

  ilock(dp);  // 锁住父目录

  // 不能删除 "." 或 ".."（防止破坏目录结构）
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  // 在父目录中查找 name 对应的 inode，并返回其偏移 off
  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;  // 文件不存在

  ilock(ip);  // 锁住目标 inode

  // 安全检查：nlink 不应小于 1
  if(ip->nlink < 1)
    panic("unlink: nlink < 1");

  // 如果是目录，必须为空才能删除
  if(ip->type == T_DIR && !isdirempty(ip)){
    iunlockput(ip);  // 解锁并释放 ip
    goto bad;
  }

  // 删除目录项：将对应位置的 dirent 清零（inum=0）
  memset(&de, 0, sizeof(de));
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    panic("unlink: writei");  // 写入失败

  // 如果删除的是目录，则父目录的链接数减 1
  // （因为子目录中的 ".." 指向父目录，现在这个子目录没了）
  if(ip->type == T_DIR){
    dp->nlink--;
    iupdate(dp);  // 更新父目录 inode
  }
  iunlockput(dp);  // 解锁并释放父目录

  // 目标文件的链接数减 1
  ip->nlink--;
  iupdate(ip);

  // 如果 nlink 变为 0 且无进程打开它，inode 和数据块会被回收（在 iput 中处理）
  iunlockput(ip);

  end_op();
  return 0;

bad:
  iunlockput(dp);  // 出错时只释放父目录（ip 未被锁定或已处理）
  end_op();
  return -1;
}


// 创建指定路径的 inode（用于 open(O_CREATE)、mkdir、mknod）
static struct inode*
create(char *path, short type, short major, short minor)
{
  struct inode *ip, *dp;  // ip: 新 inode；dp: 父目录
  char name[DIRSIZ];

  // 解析路径：获取父目录 dp 和最后一级文件名 name
  if((dp = nameiparent(path, name)) == 0)
    return 0;

  ilock(dp);  // 锁住父目录

  // 检查是否已存在同名文件
  if((ip = dirlookup(dp, name, 0)) != 0){
    iunlockput(dp);
    ilock(ip);
    // 若是普通文件创建，且已存在普通文件或设备，则复用（用于 open(O_CREATE)）
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
      return ip;
    iunlockput(ip);
    return 0;  // 其他情况视为冲突
  }

  // 分配新 inode
  if((ip = ialloc(dp->dev, type)) == 0){
    iunlockput(dp);
    return 0;
  }

  ilock(ip);
  ip->major = major;
  ip->minor = minor;
  ip->nlink = 1;
  iupdate(ip);

  // 若为目录，创建 "." 和 ".."
  if(type == T_DIR){
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
      goto fail;
  }

  // 在父目录中添加新目录项
  if(dirlink(dp, name, ip->inum) < 0)
    goto fail;

  // 若为目录，父目录链接数 +1（因 ".." 指向它）
  if(type == T_DIR){
    dp->nlink++;
    iupdate(dp);
  }

  iunlockput(dp);
  return ip;  // 成功返回新 inode（调用者需负责释放）

fail:
  // 失败：标记 inode 为未使用（nlink=0），便于回收
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}

uint64
sys_open(void)
{
  char path[MAXPATH];
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  // 获取第二个参数：打开模式（如 O_RDONLY, O_WRONLY, O_CREATE, O_TRUNC）
  argint(1, &omode);
  // 获取第一个参数：文件路径
  if((n = argstr(0, path, MAXPATH)) < 0)
    return -1;

  begin_op();  // 开始文件系统事务

  if(omode & O_CREATE){
    // 创建新文件（类型为普通文件，设备号为0）
    ip = create(path, T_FILE, 0, 0);
    if(ip == 0){
      end_op();
      return -1;
    }
  } else {
    // 打开已有文件
    if((ip = namei(path)) == 0){
      end_op();
      return -1;
    }
    ilock(ip);
    // 目录只能以只读方式打开（不能写入目录内容）
    if(ip->type == T_DIR && omode != O_RDONLY){
      iunlockput(ip);
      end_op();
      return -1;
    }
  }

  // 检查设备文件合法性
  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    iunlockput(ip);
    end_op();
    return -1;
  }

  // 分配内核 file 结构和进程文件描述符
  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    if(f) fileclose(f);  // 清理资源
    iunlockput(ip);
    end_op();
    return -1;
  }

  // 设置 file 结构
  if(ip->type == T_DEVICE){
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    f->off = 0;  // 初始偏移为0
  }
  f->ip = ip;
  f->readable = !(omode & O_WRONLY);           // 非仅写即为可读
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);

  // 若指定了 O_TRUNC 且是普通文件，则清空内容
  if((omode & O_TRUNC) && ip->type == T_FILE){
    itrunc(ip);  // 释放所有数据块，size=0
  }

  iunlock(ip);  // 此时 file 已持有 ip 引用，无需再锁
  end_op();

  return fd;  // 返回用户态文件描述符
}


uint64
sys_mkdir(void)
{
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
  // 从用户获取路径，并调用 create 创建类型为 T_DIR 的 inode
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    end_op();
    return -1;
  }
  // 成功创建后，释放对 inode 的引用（create 返回时已锁定）
  iunlockput(ip);
  end_op();
  return 0;
}

uint64
sys_mknod(void)
{
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
  // 获取设备主/次设备号
  argint(1, &major);
  argint(2, &minor);
  // 创建类型为 T_DEVICE 的 inode
  if((argstr(0, path, MAXPATH)) < 0 ||
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    end_op();
    return -1;
  }
  iunlockput(ip);
  end_op();
  return 0;
}

uint64
sys_chdir(void)
{
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();  // 获取当前进程

  begin_op();
  // 查找目标路径的 inode
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    end_op();
    return -1;
  }
  ilock(ip);
  // 必须是目录
  if(ip->type != T_DIR){
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);  // 不需要一直锁住

  // 释放旧的工作目录（减少引用计数）
  iput(p->cwd);
  end_op();

  // 更新为新的工作目录（create/namei 返回的 ip 已有引用）
  p->cwd = ip;
  return 0;
}

uint64
sys_exec(void)
{
  char path[MAXPATH], *argv[MAXARG];  // argv 缓存内核空间指针
  int i;
  uint64 uargv, uarg;  // 用户空间地址

  // 获取用户传入的 argv 数组地址（第二个参数）
  argaddr(1, &uargv);
  // 获取程序路径（第一个参数）
  if(argstr(0, path, MAXPATH) < 0) {
    return -1;
  }

  memset(argv, 0, sizeof(argv));

  // 从用户空间逐个拷贝命令行参数到内核
  for(i = 0; ; i++){
    if(i >= NELEM(argv))  // 超过最大参数数量
      goto bad;
    // 读取 argv[i] 的用户地址（即字符串指针）
    if(fetchaddr(uargv + sizeof(uint64)*i, (uint64*)&uarg) < 0)
      goto bad;
    if(uarg == 0){  // 遇到 NULL 表示结束
      argv[i] = 0;
      break;
    }
    // 为每个参数分配内核内存
    argv[i] = kalloc();
    if(argv[i] == 0)
      goto bad;
    // 从用户空间拷贝字符串内容（最多一页）
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
      goto bad;
  }

  // 调用 kexec 加载 ELF 并替换当前进程内存
  int ret = kexec(path, argv);

  // 无论成功与否，都要释放内核分配的参数内存
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    kfree(argv[i]);

  return ret;  // 成功返回0，失败返回-1

bad:
  // 出错时清理已分配的内存
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    kfree(argv[i]);
  return -1;
}

uint64
sys_pipe(void)
{
  uint64 fdarray;  // 用户传入的 int[2] 数组地址
  struct file *rf, *wf;  // 读端和写端的 file 结构
  int fd0, fd1;
  struct proc *p = myproc();

  // 获取用户数组地址
  argaddr(0, &fdarray);
  // 分配管道的两个 file 结构（共享一个 pipe 结构）
  if(pipealloc(&rf, &wf) < 0)
    return -1;

  fd0 = -1;
  // 为读端和写端分别分配文件描述符
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    // 分配失败：回滚
    if(fd0 >= 0)
      p->ofile[fd0] = 0;  // 清除已分配的 fd
    fileclose(rf);
    fileclose(wf);
    return -1;
  }

  // 将两个 fd 写回用户空间的 fdarray[0] 和 fdarray[1]
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
     copyout(p->pagetable, fdarray + sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    // 写回失败：清理
    p->ofile[fd0] = 0;
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }

  return 0;  // 成功
}
