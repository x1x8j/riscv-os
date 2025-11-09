struct buf {
  int valid;   // 缓冲区中的数据是否已经从磁盘读取？如果是，表示该缓冲区是有效的
  int disk;    // 磁盘是否“拥有”此缓冲区？如果是，表示该缓冲区的数据来自磁盘
  uint dev;    // 设备编号，表示缓冲区属于哪个设备
  uint blockno;  // 磁盘块号，标识缓冲区缓存的是哪个磁盘块
  struct sleeplock lock;  // 睡眠锁，用于同步，保证对缓冲区的互斥访问
  uint refcnt;  // 引用计数，表示当前缓冲区有多少地方正在使用
  struct buf *prev;  // 前一个缓冲区（双向链表），用于实现 LRU 缓存策略
  struct buf *next;  // 下一个缓冲区（双向链表），用于实现 LRU 缓存策略
  uchar data[BSIZE];  // 缓冲区数据，存储从磁盘读取到的数据（每个磁盘块的大小）
};

