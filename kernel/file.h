// 文件结构体，表示一个文件描述符
struct file {
  enum { FD_NONE, FD_PIPE, FD_INODE, FD_DEVICE } type;  // 文件类型，可能是无效、管道、inode 或设备
  int ref;  // 引用计数
  char readable;  // 文件是否可读
  char writable;  // 文件是否可写
  struct pipe *pipe;  // 如果是管道类型，指向管道结构体
  struct inode *ip;  // 如果是 inode 或设备类型，指向对应的 inode 结构体
  uint off;  // 文件偏移量（仅对 FD_INODE 类型有效）
  short major;  // 设备的主设备号（仅对 FD_DEVICE 类型有效）
};

// 设备号处理宏
#define major(dev)  ((dev) >> 16 & 0xFFFF)  // 提取设备的主设备号
#define minor(dev)  ((dev) & 0xFFFF)  // 提取设备的次设备号
#define mkdev(m,n)  ((uint)((m)<<16| (n)))  // 根据主次设备号生成设备号

// 内存中的 inode 副本
struct inode {
  uint dev;  // 设备号
  uint inum;  // inode 编号
  int ref;  // 引用计数
  struct sleeplock lock;  // 用于保护该 inode 的自旋锁
  int valid;  // inode 是否已从磁盘读取

  short type;  // 文件类型，来自磁盘 inode
  short major;  // 设备的主设备号（对于设备文件）
  short minor;  // 设备的次设备号（对于设备文件）
  short nlink;  // 链接计数，表示该 inode 被多少个目录项引用
  uint size;  // 文件大小
  uint addrs[NDIRECT+1];  // 数据块地址数组，包括直接块和间接块
};

// 设备功能函数映射表
struct devsw {
  int (*read)(int, uint64, int);  // 设备的读取函数
  int (*write)(int, uint64, int);  // 设备的写入函数
};

// 设备交换表，存储所有设备的读写函数
extern struct devsw devsw[];

// 控制台设备编号（通常是 1）
#define CONSOLE 1

