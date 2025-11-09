// 内核上下文切换时保存的寄存器。
struct context {
  uint64 ra;  // 返回地址
  uint64 sp;  // 堆栈指针

  // 调用者保存的寄存器
  uint64 s0;
  uint64 s1;
  uint64 s2;
  uint64 s3;
  uint64 s4;
  uint64 s5;
  uint64 s6;
  uint64 s7;
  uint64 s8;
  uint64 s9;
  uint64 s10;
  uint64 s11;
};

// 单个CPU的状态。
struct cpu {
  struct proc *proc;        // 当前运行的进程，或为NULL
  struct context context;   // 切换到scheduler时的上下文
  int noff;                 // push_off()的嵌套深度
  int intena;               // push_off()之前中断是否启用
};

//extern struct cpu cpus[NCPU];  // 存储CPU的状态
extern struct cpu cpu;

// 每个进程在trap处理代码中的数据。
// 位于trampoline页下方的单独一页，
// 在内核页表中没有特别映射。
// uservec会在trampoline.S中保存用户寄存器到trapframe中，
// 然后初始化trapframe中的内核栈指针(kernel_sp)、
// 内核hartid(kernel_hartid)、内核页表(kernel_satp)，
// 并跳转到kernel_trap。
// usertrapret()和userret在trampoline.S中设置trapframe中的内核寄存器，
// 从trapframe恢复用户寄存器，切换到用户页表并进入用户空间。
// trapframe中包括了callee-saved的用户寄存器(s0-s11)，因为
// 从usertrapret()返回用户时不会通过整个内核调用栈。
struct trapframe {
  /*   0 */ uint64 kernel_satp;   // 内核页表
  /*   8 */ uint64 kernel_sp;     // 进程的内核栈顶
  /*  16 */ uint64 kernel_trap;   // 用户陷入内核时的处理函数(usertrap())
  /*  24 */ uint64 epc;           // 保存的用户程序计数器
  /*  32 */ uint64 kernel_hartid; // 保存的内核线程ID
  /*  40 */ uint64 ra;            // 返回地址
  /*  48 */ uint64 sp;            // 堆栈指针
  /*  56 */ uint64 gp;            // 全局指针
  /*  64 */ uint64 tp;            // 线程指针
  /*  72 */ uint64 t0;            // 临时寄存器t0
  /*  80 */ uint64 t1;            // 临时寄存器t1
  /*  88 */ uint64 t2;            // 临时寄存器t2
  /*  96 */ uint64 s0;            // callee-saved寄存器s0
  /* 104 */ uint64 s1;            // callee-saved寄存器s1
  /* 112 */ uint64 a0;            // 参数寄存器a0
  /* 120 */ uint64 a1;            // 参数寄存器a1
  /* 128 */ uint64 a2;            // 参数寄存器a2
  /* 136 */ uint64 a3;            // 参数寄存器a3
  /* 144 */ uint64 a4;            // 参数寄存器a4
  /* 152 */ uint64 a5;            // 参数寄存器a5
  /* 160 */ uint64 a6;            // 参数寄存器a6
  /* 168 */ uint64 a7;            // 参数寄存器a7
  /* 176 */ uint64 s2;            // callee-saved寄存器s2
  /* 184 */ uint64 s3;            // callee-saved寄存器s3
  /* 192 */ uint64 s4;            // callee-saved寄存器s4
  /* 200 */ uint64 s5;            // callee-saved寄存器s5
  /* 208 */ uint64 s6;            // callee-saved寄存器s6
  /* 216 */ uint64 s7;            // callee-saved寄存器s7
  /* 224 */ uint64 s8;            // callee-saved寄存器s8
  /* 232 */ uint64 s9;            // callee-saved寄存器s9
  /* 240 */ uint64 s10;           // callee-saved寄存器s10
  /* 248 */ uint64 s11;           // callee-saved寄存器s11
  /* 256 */ uint64 t3;            // 临时寄存器t3
  /* 264 */ uint64 t4;            // 临时寄存器t4
  /* 272 */ uint64 t5;            // 临时寄存器t5
  /* 280 */ uint64 t6;            // 临时寄存器t6
};

enum procstate { UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE };

// 每个进程的状态
struct proc {
  struct spinlock lock;         // 进程锁

  // p->lock必须在使用这些字段时被加锁
  enum procstate state;         // 进程状态
  void *chan;                   // 如果非零，表示进程正在某个通道上休眠
  int killed;                   // 如果非零，表示进程已被杀死
  int xstate;                   // 进程退出状态，返回给父进程
  int pid;                      // 进程ID

  // wait_lock必须在使用这些字段时被加锁
  struct proc *parent;          // 父进程

  // 以下是进程私有的字段，不需要加锁
  uint64 kstack;                // 内核栈的虚拟地址
  uint64 sz;                    // 进程内存大小（字节）
  pagetable_t pagetable;        // 用户页表
  struct trapframe *trapframe;  // trampoline.S的trapframe数据页
  struct context context;       // 切换到此处以运行进程
  struct file *ofile[NOFILE];   // 打开的文件
  struct inode *cwd;            // 当前工作目录
  char name[16];                // 进程名称（用于调试）
};

