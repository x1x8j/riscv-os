// 缓冲区缓存系统
//
// 缓冲区缓存是一个链表，链表中的每个元素是一个 buf 结构体，
// 存储着磁盘块内容的缓存副本。缓存磁盘块可以减少磁盘读取的次数，
// 也为多个进程使用同一磁盘块提供了同步点。

// 接口说明：
// * 要获取某个磁盘块的缓冲区，调用 bread。
// * 修改缓冲区数据后，调用 bwrite 将数据写入磁盘。
// * 完成对缓冲区的使用后，调用 brelse。
// * 调用 brelse 后，不要再使用该缓冲区。
// * 每次只能有一个进程使用缓冲区，
//     因此不要保持缓冲区的引用超过必要的时间。

#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "buf.h"

// 缓冲区缓存结构体
struct {
  struct spinlock lock;  // 缓冲区缓存的锁
  struct buf buf[NBUF];  // 缓冲区数组

  // 通过 prev/next 形成的所有缓冲区的链表
  // 按照缓冲区的使用时间排序
  // head.next 是最近使用的，head.prev 是最久未使用的
  struct buf head;  
} bcache;

// 初始化缓冲区缓存
void
binit(void)
{
  struct buf *b;

  // 初始化缓冲区缓存的锁
  initlock(&bcache.lock, "bcache");

  // 创建缓冲区链表
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf + NBUF; b++){
    b->next = bcache.head.next;
    b->prev = &bcache.head;
    initsleeplock(&b->lock, "buffer");  // 初始化缓冲区的睡眠锁
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}

// 查找缓冲区缓存中是否存在指定磁盘设备的块
// 如果找到，返回该缓冲区；如果没有找到，分配一个新的缓冲区
static struct buf*
bget(uint dev, uint blockno)
{
  struct buf *b;

  acquire(&bcache.lock);  // 获取缓冲区缓存的锁

  // 查找缓存中是否已存在指定的磁盘块
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    if(b->dev == dev && b->blockno == blockno){
      b->refcnt++;  // 增加引用计数
      release(&bcache.lock);  // 释放缓冲区缓存的锁
      acquiresleep(&b->lock);  // 获取缓冲区的睡眠锁
      return b;  // 返回缓冲区
    }
  }

  // 没有找到缓存的块
  // 从链表的尾部回收最久未使用的缓冲区
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    if(b->refcnt == 0) {
      b->dev = dev;  // 设置设备号
      b->blockno = blockno;  // 设置块号
      b->valid = 0;  // 设置为无效
      b->refcnt = 1;  // 引用计数设置为 1
      release(&bcache.lock);  // 释放缓冲区缓存的锁
      acquiresleep(&b->lock);  // 获取缓冲区的睡眠锁
      return b;  // 返回新的缓冲区
    }
  }

  panic("bget: no buffers");  // 如果没有找到可用的缓冲区，发生错误
}

// 获取指定磁盘块的缓冲区并返回，内容从磁盘读取
struct buf*
bread(uint dev, uint blockno)
{
  struct buf *b;

  b = bget(dev, blockno);  // 获取缓冲区
  if(!b->valid) {
    virtio_disk_rw(b, 0);  // 从磁盘读取数据到缓冲区
    b->valid = 1;  // 设置缓冲区为有效
  }
  return b;  // 返回缓冲区
}

// 将缓冲区 b 的内容写入磁盘，必须先锁定缓冲区
void
bwrite(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("bwrite");  // 检查是否持有缓冲区的锁
  virtio_disk_rw(b, 1);  // 将缓冲区内容写入磁盘
}

// 释放锁定的缓冲区，并将其移到最近使用的位置
void
brelse(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("brelse");  // 检查是否持有缓冲区的锁

  releasesleep(&b->lock);  // 释放缓冲区的睡眠锁

  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
  b->refcnt--;  // 减少引用计数
  if (b->refcnt == 0) {
    // 如果没有其他进程在使用该缓冲区
    // 将缓冲区移到链表头部
    b->next->prev = b->prev;
    b->prev->next = b->next;
    b->next = bcache.head.next;
    b->prev = &bcache.head;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
  
  release(&bcache.lock);  // 释放缓冲区缓存的锁
}

// 增加缓冲区 b 的引用计数，用于防止缓冲区被释放
void
bpin(struct buf *b) {
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
  b->refcnt++;  // 增加引用计数
  release(&bcache.lock);  // 释放缓冲区缓存的锁
}

// 减少缓冲区 b 的引用计数，用于缓冲区的释放
void
bunpin(struct buf *b) {
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
  b->refcnt--;  // 减少引用计数
  release(&bcache.lock);  // 释放缓冲区缓存的锁
}

