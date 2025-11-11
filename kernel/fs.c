
#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "stat.h"
#include "spinlock.h"
#include "proc.h"
#include "sleeplock.h"
#include "fs.h"
#include "buf.h"
#include "file.h"


struct superblock sb; 

// 从设备 dev 的第 1 块读取超级块sb
static void
readsb(int dev, struct superblock *sb)
{
  struct buf *bp;

  bp = bread(dev, 1);                 // 超级块固定在磁盘块 1
  memmove(sb, bp->data, sizeof(*sb)); // 拷贝到内存
  brelse(bp);                         // 释放缓冲区
}

// 初始化文件系统：读超级块、验证魔数、初始化日志、回收孤儿 inode
void
fsinit(int dev) {
  readsb(dev, &sb);
  if(sb.magic != FSMAGIC)
    panic("invalid file system");     // 魔数校验失败，非 xv6 文件系统
  initlog(dev, &sb);                  // 初始化日志系统（用于崩溃恢复）
  ireclaim(dev);                      // 回收 nlink=0 的 inode（上次未清理的）
}

// 将指定磁盘块清零（用于新分配的块）
static void
bzero(int dev, int bno)
{
  struct buf *bp;
  bp = bread(dev, bno);
  memset(bp->data, 0, BSIZE);         // 清空内容
  log_write(bp);                      // 通过日志写入（保证一致性）
  brelse(bp);
}

// 分配一个空闲磁盘块（返回块号，0 表示无空间）
static uint
balloc(uint dev)
{
  int b, bi, m;
  struct buf *bp;

  // 遍历所有块位图块（每块管理 BPB=8*BSIZE 个块）
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb));   // 读取位图块
    // 遍历该位图块中的每一位
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
      m = 1 << (bi % 8);
      if((bp->data[bi/8] & m) == 0){  // 该位为 0 → 块空闲
        bp->data[bi/8] |= m;          // 标记为已用
        log_write(bp);                // 写回位图
        brelse(bp);
        bzero(dev, b + bi);           // 清零新块
        return b + bi;                // 返回块号
      }
    }
    brelse(bp);
  }
  printf("balloc: out of blocks\n");
  return 0;
}

// 释放磁盘块（将位图对应位清零）
static void
bfree(int dev, uint b)
{
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
  bi = b % BPB;
  m = 1 << (bi % 8);
  if((bp->data[bi/8] & m) == 0)
    panic("freeing free block");      // 防止重复释放
  bp->data[bi/8] &= ~m;               // 清除使用标记
  log_write(bp);
  brelse(bp);
}

// 内存 inode 表（缓存最近使用的 inode）
struct {
  struct spinlock lock;
  struct inode inode[NINODE];         // 最多缓存 NINODE 个 inode
} itable;

// 初始化 inode 表锁和每个 inode 的 sleeplock
void
iinit()
{
  int i = 0;
  initlock(&itable.lock, "itable");
  for(i = 0; i < NINODE; i++) {
    initsleeplock(&itable.inode[i].lock, "inode");
  }
}

static struct inode* iget(uint dev, uint inum);

// 在磁盘上分配一个新 inode（类型为 type），返回未锁定但已引用的内存 inode
struct inode*
ialloc(uint dev, short type)
{
  int inum;
  struct buf *bp;
  struct dinode *dip;                 // 磁盘 inode 结构

  // 从 inum=1 开始扫描（0 是无效号）
  for(inum = 1; inum < sb.ninodes; inum++){
    bp = bread(dev, IBLOCK(inum, sb)); // 读取包含该 inode 的磁盘块
    dip = (struct dinode*)bp->data + inum%IPB; // 定位到具体 inode
    if(dip->type == 0){              // type=0 表示空闲
      memset(dip, 0, sizeof(*dip));
      dip->type = type;
      log_write(bp);                 // 写回磁盘（标记为已用）
      brelse(bp);
      return iget(dev, inum);        // 返回内存 inode（引用+1）
    }
    brelse(bp);
  }
  printf("ialloc: no inodes\n");
  return 0;
}

// 将内存 inode 内容写回磁盘（必须在持有 ip->lock 时调用）
void
iupdate(struct inode *ip)
{
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
  dip = (struct dinode*)bp->data + ip->inum%IPB;
  // 同步关键字段
  dip->type = ip->type;
  dip->major = ip->major;
  dip->minor = ip->minor;
  dip->nlink = ip->nlink;
  dip->size = ip->size;
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
  log_write(bp);
  brelse(bp);
}

// 获取设备 dev 上编号为 inum 的 inode（不加锁，不读磁盘）
static struct inode*
iget(uint dev, uint inum)
{
  struct inode *ip, *empty;

  acquire(&itable.lock);

  // 先查缓存：是否已在内存？
  empty = 0;
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
      ip->ref++;                    // 引用计数+1
      release(&itable.lock);
      return ip;
    }
    if(empty == 0 && ip->ref == 0) // 记录第一个空闲槽
      empty = ip;
  }

  // 未命中：复用空闲槽
  if(empty == 0)
    panic("iget: no inodes");

  ip = empty;
  ip->dev = dev;
  ip->inum = inum;
  ip->ref = 1;                     // 初始引用为1
  ip->valid = 0;                   // 数据尚未从磁盘读入
  release(&itable.lock);

  return ip;
}

// 增加引用计数（用于复制指针）
struct inode*
idup(struct inode *ip)
{
  acquire(&itable.lock);
  ip->ref++;
  release(&itable.lock);
  return ip;
}

// 锁定 inode（必要时从磁盘读入）
void
ilock(struct inode *ip)
{
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquiresleep(&ip->lock);         // 使用 sleeplock（可睡眠）

  if(ip->valid == 0){              // 首次使用：从磁盘读入
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    ip->type = dip->type;
    ip->major = dip->major;
    ip->minor = dip->minor;
    ip->nlink = dip->nlink;
    ip->size = dip->size;
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    brelse(bp);
    ip->valid = 1;
    if(ip->type == 0)
      panic("ilock: no type");   // 不应出现空闲 inode 被锁定
  }
}

// 解锁 inode
void
iunlock(struct inode *ip)
{
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    panic("iunlock");
  releasesleep(&ip->lock);
}

// 减少引用计数；若为最后一个引用且 nlink=0，则释放 inode 和数据块
void
iput(struct inode *ip)
{
  acquire(&itable.lock);

  // 检查是否需要真正删除（nlink=0 且无其他引用）
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    acquiresleep(&ip->lock);       // 安全：此时只有本进程引用
    release(&itable.lock);

    itrunc(ip);                    // 释放所有数据块
    ip->type = 0;                  // 标记为未使用
    iupdate(ip);                   // 写回磁盘
    ip->valid = 0;

    releasesleep(&ip->lock);
    acquire(&itable.lock);
  }

  ip->ref--;                       // 减少引用
  release(&itable.lock);
}

// 常用组合：先解锁再减少引用
void
iunlockput(struct inode *ip)
{
  iunlock(ip);
  iput(ip);
}


// 扫描所有 inode，回收 nlink=0 的（上次 crash 未清理的）
void
ireclaim(int dev)
{
  for (int inum = 1; inum < sb.ninodes; inum++) {
    struct inode *ip = 0;
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    if (dip->type != 0 && dip->nlink == 0) {  // 孤儿 inode
      printf("ireclaim: orphaned inode %d\n", inum);
      ip = iget(dev, inum);        // 获取内存 inode
    }
    brelse(bp);
    if (ip) {
      begin_op();                  // 必须在事务中
      ilock(ip);
      iunlock(ip);
      iput(ip);                    // 触发删除
      end_op();
    }
  }
}

// 返回 inode 第 bn 个数据块的磁盘地址（若不存在则分配）
static uint
bmap(struct inode *ip, uint bn)
{
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){                // 直接块
    if((addr = ip->addrs[bn]) == 0){
      addr = balloc(ip->dev);
      if(addr == 0) return 0;
      ip->addrs[bn] = addr;
    }
    return addr;
  }
  bn -= NDIRECT;

  if(bn < NINDIRECT){              // 一级间接块
    if((addr = ip->addrs[NDIRECT]) == 0){
      addr = balloc(ip->dev);
      if(addr == 0) return 0;
      ip->addrs[NDIRECT] = addr;
    }
    bp = bread(ip->dev, addr);
    a = (uint*)bp->data;
    if((addr = a[bn]) == 0){
      addr = balloc(ip->dev);
      if(addr){
        a[bn] = addr;
        log_write(bp);            // 更新间接块
      }
    }
    brelse(bp);
    return addr;
  }

  panic("bmap: out of range");
}

// 截断 inode：释放所有数据块
void
itrunc(struct inode *ip)
{
  int i, j;
  struct buf *bp;
  uint *a;

  // 释放直接块
  for(i = 0; i < NDIRECT; i++){
    if(ip->addrs[i]){
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }

  // 释放间接块中的块，并释放间接块本身
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
  iupdate(ip);
}

// 从 inode 读取数据到 dst（支持用户/内核地址）
int
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off) return 0;
  if(off + n > ip->size) n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0) break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
      brelse(bp);
      tot = -1; break;
    }
    brelse(bp);
  }
  return tot;
}

// 向 inode 写入数据（支持用户/内核地址）
int
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off) return -1;
  if(off + n > MAXFILE*BSIZE) return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0) break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
      brelse(bp); break;
    }
    log_write(bp);                 // 通过日志写入
    brelse(bp);
  }

  if(off > ip->size) ip->size = off;
  iupdate(ip);                     // 即使 size 未变，addrs 可能已更新
  return tot;
}

// Directories

// 比较两个目录项名称（最多 DIRSIZ 字节）
int
namecmp(const char *s, const char *t)
{
  return strncmp(s, t, DIRSIZ);
}

// 在目录 dp 中查找名为 name 的条目
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR) panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlookup read");
    if(de.inum == 0) continue;     // 空条目
    if(namecmp(name, de.name) == 0){
      if(poff) *poff = off;
      inum = de.inum;
      return iget(dp->dev, inum);  // 返回对应 inode
    }
  }
  return 0;
}

// 在目录 dp 中添加 (name, inum) 条目
int
dirlink(struct inode *dp, char *name, uint inum)
{
  int off;
  struct dirent de;
  struct inode *ip;

  // 禁止重名
  if((ip = dirlookup(dp, name, 0)) != 0){
    iput(ip);
    return -1;
  }

  // 查找空闲条目（inum=0）或追加到末尾
  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
  de.inum = inum;
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    return -1;
  return 0;
}

// Paths

// 从 path 中提取下一个路径元素到 name，返回剩余部分
static char*
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/') path++;       // 跳过前导 '/'
  if(*path == 0) return 0;
  s = path;
  while(*path != '/' && *path != 0) path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);       // 截断超长名
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/') path++;       // 跳过后续 '/'
  return path;
}

// 通用路径解析
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    struct inode *ip, *next;
    // 第一步：确定路径解析的起点
    if(*path == '/') {
        // 绝对路径：从根目录开始
        // ROOTDEV 是根文件系统所在的设备号，ROOTINO 是根目录的 inode 编号（通常为 1）
        ip = iget(ROOTDEV, ROOTINO);
    } else {
        // 相对路径：从当前进程的工作目录（cwd）开始
        // idup() 增加 cwd 的引用计数，防止在遍历过程中被释放
        ip = idup(myproc()->cwd);
    }

    // 第二步：循环解析路径中的每一个组件（如 "a", "b", "c"）
    // skipelem(path, name) 会将当前路径的第一个有效组件拷贝到 name 中，
    // 并返回剩余路径的起始地址；若无更多组件则返回 0，退出循环。
    while((path = skipelem(path, name)) != 0) {
        // 锁定当前目录的 inode，确保在查找子项期间内容不会被并发修改
        ilock(ip);
        // 检查当前 inode 是否为目录类型
        // 如果不是目录（比如是个普通文件），却还要继续向下查找（如 "file/sub"），则路径非法，返回失败。
        if(ip->type != T_DIR) {
            iunlockput(ip);  // 先解锁，再减少引用计数（put）
            return 0;
        }

        // 特殊情况：调用者要求“父目录”，且当前组件是路径的最后一个
        if(nameiparent && *path == '\0') {
            iunlock(ip);  
            return ip;
        }

        // 在当前目录中查找名为 'name' 的子项
        // dirlookup(ip, name, 0) 返回该子项对应的 inode 指针，若不存在则返回 0
        if((next = dirlookup(ip, name, 0)) == 0) {
            iunlockput(ip);  // 查找失败，释放当前 inode
            return 0;
        }

        // 查找成功：准备进入下一级
        // 释放当前 inode（解锁 + 引用计数减 1）
        iunlockput(ip);
        // 将 ip 指向找到的子项，继续下一轮解析
        ip = next;
    }

    // 第三步：处理路径解析完成后的边界情况
    // 如果调用者要求“父目录”，但路径中根本没有有效组件或路径为空（如 ""），这意味着请求“根目录的父目录”——这是非法的！
    if(nameiparent) {
        iput(ip);  // 释放已获取的 inode（如根目录）
        return 0;  // 返回失败
    }
    // 正常情况：返回最终找到的 inode
    return ip;
}

// 解析完整路径，返回最终 inode
struct inode*
namei(char *path)
{
  char name[DIRSIZ];
  return namex(path, 0, name);
}

// 解析路径，返回父目录 inode，并将最后一级存入 name
struct inode*
nameiparent(char *path, char *name)
{
  return namex(path, 1, name);
}
