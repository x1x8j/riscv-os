#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "fs.h"
#include "buf.h"

// 简单的日志系统，允许并发的文件系统调用。
// 日志事务包含多个文件系统调用的更新。
// 日志系统仅在没有活动的文件系统调用时才提交，因此不需要考虑
// 是否可能写入未提交的文件系统调用的更新到磁盘。
// 每个文件系统调用应该调用 begin_op()/end_op() 来标记开始和结束。
// 通常 begin_op() 只是增加正在进行的文件系统调用计数并返回。
// 但是如果日志空间接近用尽，它会在最后一个未完成的 end_op() 提交时进入睡眠。
// 日志是一个物理重做日志，包含磁盘块。
// 日志在磁盘上的格式：
//   头块，包含块 A, B, C 等的块号
//   块 A
//   块 B
//   块 C
//   ...
// 日志附加操作是同步的。

// 日志头的内容，用于磁盘上的头块以及在内存中跟踪已提交的块号。
struct logheader {
  int n;  // 日志中块的数量
  int block[LOGBLOCKS];  // 日志中的各个块号
};

// 日志结构体，包含锁、日志状态和日志头
struct log {
  struct spinlock lock;  // 日志的自旋锁
  int start;  // 日志起始位置
  int outstanding;  // 正在执行的文件系统调用数量
  int committing;  // 是否正在提交日志
  int dev;  // 日志所在的设备
  struct logheader lh;  // 日志头
};
struct log log;

// 日志恢复的辅助函数
static void recover_from_log(void);
// 日志提交的辅助函数
static void commit();

// 初始化日志
void initlog(int dev, struct superblock *sb)
{
  // 检查日志头结构体是否过大
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  // 初始化日志自旋锁
  initlock(&log.lock, "log");
  log.start = sb->logstart;  // 设置日志起始位置
  log.dev = dev;  // 设置日志设备
  recover_from_log();  // 从日志中恢复
}

// 将已提交的块从日志复制到它们的目标位置
static void install_trans(int recovering)
{
  int tail;

  // 遍历日志中的所有块
  for (tail = 0; tail < log.lh.n; tail++) {
    if(recovering) {
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    }
    // 读取日志块和目标块
    struct buf *lbuf = bread(log.dev, log.start + tail + 1);  // 读取日志块
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]);  // 读取目标块
    // 将日志块的数据复制到目标块
    memmove(dbuf->data, lbuf->data, BSIZE);
    bwrite(dbuf);  // 将目标块写回磁盘
    if(recovering == 0)
      bunpin(dbuf);  // 提交后解锁目标块
    brelse(lbuf);  // 释放日志块
    brelse(dbuf);  // 释放目标块
  }
}

// 从磁盘读取日志头到内存中的日志头
static void read_head(void)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;  // 读取日志中的块数量
  for (i = 0; i < log.lh.n; i++) {
    log.lh.block[i] = lh->block[i];  // 读取每个日志块的块号
  }
  brelse(buf);  // 释放缓冲区
}

// 将内存中的日志头写回磁盘
static void write_head(void)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;  // 更新日志中的块数量
  for (i = 0; i < log.lh.n; i++) {
    hb->block[i] = log.lh.block[i];  // 更新每个日志块的块号
  }
  bwrite(buf);  // 写回日志头块
  brelse(buf);  // 释放缓冲区
}

// 从日志中恢复
static void recover_from_log(void)
{
  read_head();  // 读取日志头
  install_trans(1);  // 如果已提交，从日志复制到磁盘
  log.lh.n = 0;  // 清空日志中的块数量
  write_head();  // 清空日志
}

// 文件系统调用开始时调用
void begin_op(void)
{
  acquire(&log.lock);  // 获取日志锁
  while(1){
    if(log.committing){
      // 如果日志正在提交，进入睡眠
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGBLOCKS){
      // 如果当前操作可能耗尽日志空间，等待提交
      sleep(&log, &log.lock);
    } else {
      log.outstanding += 1;  // 增加正在进行的操作计数
      release(&log.lock);  // 释放日志锁
      break;
    }
  }
}

// 文件系统调用结束时调用
// 如果这是最后一个待处理的操作，则提交日志
void end_op(void)
{
  int do_commit = 0;

  acquire(&log.lock);  // 获取日志锁
  log.outstanding -= 1;  // 减少待处理操作计数
  if(log.committing)
    panic("log.committing");  // 不允许在提交时结束操作
  if(log.outstanding == 0){
    do_commit = 1;  // 如果没有待处理的操作，则标记为需要提交
    log.committing = 1;  // 标记日志为正在提交
  } else {
    // 如果正在等待日志空间，唤醒等待的进程
    wakeup(&log);
  }
  release(&log.lock);  // 释放日志锁

  if(do_commit){
    // 在不持有锁的情况下调用 commit()，因为不允许持有锁时睡眠
    commit();
    acquire(&log.lock);
    log.committing = 0;  // 提交完成，恢复日志状态
    wakeup(&log);  // 唤醒可能在等待提交的进程
    release(&log.lock);  // 释放日志锁
  }
}

// 将已修改的块从缓存写入日志
static void write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
    struct buf *to = bread(log.dev, log.start + tail + 1);  // 读取日志块
    struct buf *from = bread(log.dev, log.lh.block[tail]);  // 读取缓存块
    memmove(to->data, from->data, BSIZE);  // 将缓存块的数据复制到日志块
    bwrite(to);  // 写入日志块
    brelse(from);  // 释放缓存块
    brelse(to);  // 释放日志块
  }
}

// 提交事务，将日志中的块写回磁盘并清空日志
static void commit()
{
  if (log.lh.n > 0) {
    write_log();     // 将已修改的块从缓存写入日志
    write_head();    // 写入日志头到磁盘，真正提交
    install_trans(0); // 将写入操作应用到实际位置
    log.lh.n = 0;    // 清空日志中的块数量
    write_head();    // 清空日志
  }
}

// 当修改完缓冲区数据并且不再使用时，调用此函数。
// 记录块号并将缓冲区锁定，通过增加引用计数。
// commit()/write_log() 将执行磁盘写操作。
// log_write() 替代 bwrite(); 典型用法是：
//   bp = bread(...)
//   修改 bp->data[]
//   log_write(bp)
//   brelse(bp)
void log_write(struct buf *b)
{
  int i;

  acquire(&log.lock);  // 获取日志锁
  if (log.lh.n >= LOGBLOCKS)
    panic("too big a transaction");  // 如果日志块数量超过最大值，出错
  if (log.outstanding < 1)
    panic("log_write outside of trans");  // 如果在没有事务的情况下调用，出错

  for (i = 0; i < log.lh.n; i++) {
    if (log.lh.block[i] == b->blockno)   // 如果块已经存在于日志中，跳过
      break;
  }
  log.lh.block[i] = b->blockno;  // 将块号记录到日志中
  if (i == log.lh.n) {  // 如果是新块，添加到日志
    bpin(b);  // 锁定块
    log.lh.n++;  // 增加日志中的块数量
  }
  release(&log.lock);  // 释放日志锁
}

