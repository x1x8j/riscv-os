#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
#include "vm.h"

// 进程退出系统调用
uint64
sys_exit(void)
{
  int n;
  argint(0, &n);  // 获取退出码
  kexit(n);       // 调用内核的退出函数
  return 0;       // 不会执行到这里
}

// 获取当前进程的进程ID
uint64
sys_getpid(void)
{
  return myproc()->pid;  // 返回当前进程的 PID
}

// 创建一个新的子进程
uint64
sys_fork(void)
{
  return kfork();  // 调用内核的 fork 函数
}

// 等待子进程退出
uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);  // 获取等待子进程状态的地址
  return kwait(p);  // 调用内核的 wait 函数
}

// 扩展或收缩进程的内存
uint64
sys_sbrk(void)
{
  uint64 addr;
  int t;
  int n;

  argint(0, &n);  // 获取内存增量
  argint(1, &t);  // 获取是否懒加载标志
  addr = myproc()->sz;  // 获取当前进程的内存大小

  if(t == SBRK_EAGER || n < 0) {  // 如果是急切分配或要求收缩内存
    if(growproc(n) < 0) {  // 调用内核的 growproc 函数调整内存
      return -1;  // 内存分配失败
    }
  } else {  // 如果是懒加载分配
    if(addr + n < addr)  // 防止内存溢出
      return -1;
    if(addr + n > TRAPFRAME)  // 限制内存的最大值
      return -1;
    myproc()->sz += n;  // 调整进程的内存大小
  }
  return addr;  // 返回原内存地址
}

// 让当前进程挂起指定时间
uint64
sys_pause(void)
{
  int n;
  uint ticks0;

  argint(0, &n);  // 获取暂停的时长（以时钟滴答为单位）
  if(n < 0)  // 如果给定的时长为负，则设置为 0
    n = 0;
  acquire(&tickslock);  // 获取时钟锁
  ticks0 = ticks;  // 记录当前的时钟滴答数
  while(ticks - ticks0 < n){  // 持续等待直到经过了指定的时间
    if(killed(myproc())){  // 如果进程被杀死，退出等待
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);  // 进程进入休眠状态，等待时钟更新
  }
  release(&tickslock);  // 释放时钟锁
  return 0;  // 返回
}

// 终止指定进程
uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);  // 获取进程 ID
  return kkill(pid);  // 调用内核的 kill 函数终止进程
}

// 返回自系统启动以来经过的时钟滴答数
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);  // 获取时钟锁
  xticks = ticks;  // 获取当前的时钟滴答数
  release(&tickslock);  // 释放时钟锁
  return xticks;  // 返回时钟滴答数
}

