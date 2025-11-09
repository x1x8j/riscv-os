// 磁盘文件系统格式。
// 内核和用户程序都使用这个头文件。

#define ROOTINO  1   // 根目录的 i 号
#define BSIZE 1024  // 块大小

// 磁盘布局：
// [ 启动块 | 超级块 | 日志 | inode 块 |
//                      空闲位图 | 数据块 ]
//
// mkfs 计算超级块并构建一个初始的文件系统。
// 超级块描述磁盘布局：
struct superblock {
  uint magic;        // 必须是 FSMAGIC
  uint size;         // 文件系统映像的大小（以块为单位）
  uint nblocks;      // 数据块的数量
  uint ninodes;      // inode 的数量
  uint nlog;         // 日志块的数量
  uint logstart;     // 第一个日志块的块号
  uint inodestart;   // 第一个 inode 块的块号
  uint bmapstart;    // 第一个空闲位图块的块号
};

#define FSMAGIC 0x10203040 // 文件系统的魔数，标识文件系统格式

#define NDIRECT 12 // 直接地址指针数量
#define NINDIRECT (BSIZE / sizeof(uint)) // 间接地址指针的数量
#define MAXFILE (NDIRECT + NINDIRECT) // 最大文件大小（包括直接和间接地址）

// 磁盘上的 inode 结构
struct dinode {
  short type;           // 文件类型
  short major;          // 主设备号（仅对 T_DEVICE 类型有效）
  short minor;          // 次设备号（仅对 T_DEVICE 类型有效）
  short nlink;          // 文件系统中指向该 inode 的链接数
  uint size;            // 文件的大小（字节数）
  uint addrs[NDIRECT+1];   // 数据块地址（包括直接和间接地址）
};

#define IPB           (BSIZE / sizeof(struct dinode)) // 每块 inode 的数量

// 获取指定 inode 所在的块
#define IBLOCK(i, sb)     ((i) / IPB + sb.inodestart)

#define BPB           (BSIZE*8) // 每块位图的位数

// 获取指定数据块所在的空闲位图块
#define BBLOCK(b, sb) ((b)/BPB + sb.bmapstart)

// 目录是一个文件，包含一系列 dirent 结构。
#define DIRSIZ 14 // 目录项的最大名称长度

// 目录项结构。
// name 字段最多可包含 DIRSIZ 个字符，且不以 NUL 字符结尾。
struct dirent {
  ushort inum;          // inode 号
  char name[DIRSIZ] __attribute__((nonstring)); // 文件或目录的名称（不包含 NUL 字符）
};

