#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "syscall.h"
#include "defs.h"

// 从当前进程的地址 addr 获取一个 uint64 类型的值。
int
fetchaddr(uint64 addr, uint64 *ip)
{
  struct proc *p = myproc();
  // 检查 addr 是否在进程内存范围内，防止越界访问
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // 这两个条件都需要检查，防止溢出
    return -1;
  // 使用 copyin 从进程的页表中读取数据
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    return -1;
  return 0;
}

// 从当前进程的地址 addr 获取一个以 null 结尾的字符串。
// 返回字符串长度（不包括 null 字符），出错则返回 -1。
int
fetchstr(uint64 addr, char *buf, int max)
{
  struct proc *p = myproc();
  // 使用 copyinstr 从进程的页表中读取字符串
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    return -1;
  return strlen(buf);  // 返回字符串长度
}

// 获取第 n 个系统调用的原始参数（未处理过的原始值）
static uint64
argraw(int n)
{
  struct proc *p = myproc();
  switch (n) {
  case 0:
    return p->trapframe->a0;
  case 1:
    return p->trapframe->a1;
  case 2:
    return p->trapframe->a2;
  case 3:
    return p->trapframe->a3;
  case 4:
    return p->trapframe->a4;
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");  // 如果参数 n 无效，触发 panic
  return -1;
}

// 获取第 n 个 32 位的系统调用参数并将其存入 ip 中
void
argint(int n, int *ip)
{
  *ip = argraw(n);  // 通过 argraw 获取原始参数并存储
}

// 获取第 n 个参数并将其作为指针返回。
// 不进行合法性检查，因为 copyin 和 copyout 会处理这些检查。
void
argaddr(int n, uint64 *ip)
{
  *ip = argraw(n);  // 通过 argraw 获取原始参数并存储
}

// 获取第 n 个参数，假设它是一个以 null 结尾的字符串。
// 将该字符串拷贝到 buf 中，最多拷贝 max 个字符。
// 成功时返回字符串长度（包括 null），出错时返回 -1。
int
argstr(int n, char *buf, int max)
{
  uint64 addr;
  argaddr(n, &addr);  // 获取第 n 个参数的地址
  return fetchstr(addr, buf, max);  // 使用 fetchstr 获取字符串内容
}

// 处理系统调用的函数声明
extern uint64 sys_fork(void);
extern uint64 sys_exit(void);
extern uint64 sys_wait(void);
extern uint64 sys_pipe(void);
extern uint64 sys_read(void);
extern uint64 sys_kill(void);
extern uint64 sys_exec(void);
extern uint64 sys_fstat(void);
extern uint64 sys_chdir(void);
extern uint64 sys_dup(void);
extern uint64 sys_getpid(void);
extern uint64 sys_sbrk(void);
extern uint64 sys_pause(void);
extern uint64 sys_uptime(void);
extern uint64 sys_open(void);
extern uint64 sys_write(void);
extern uint64 sys_mknod(void);
extern uint64 sys_unlink(void);
extern uint64 sys_link(void);
extern uint64 sys_mkdir(void);
extern uint64 sys_close(void);

// 一个数组，将系统调用号与相应的系统调用函数映射
static uint64 (*syscalls[])(void) = {
[SYS_fork]    sys_fork,
[SYS_exit]    sys_exit,
[SYS_wait]    sys_wait,
[SYS_pipe]    sys_pipe,
[SYS_read]    sys_read,
[SYS_kill]    sys_kill,
[SYS_exec]    sys_exec,
[SYS_fstat]   sys_fstat,
[SYS_chdir]   sys_chdir,
[SYS_dup]     sys_dup,
[SYS_getpid]  sys_getpid,
[SYS_sbrk]    sys_sbrk,
[SYS_pause]   sys_pause,
[SYS_uptime]  sys_uptime,
[SYS_open]    sys_open,
[SYS_write]   sys_write,
[SYS_mknod]   sys_mknod,
[SYS_unlink]  sys_unlink,
[SYS_link]    sys_link,
[SYS_mkdir]   sys_mkdir,
[SYS_close]   sys_close,
};

// 系统调用的入口函数
void
syscall(void)
{
  int num;
  struct proc *p = myproc();

  num = p->trapframe->a7;  // 从 trapframe 中获取系统调用号
  // 检查系统调用号是否合法，且确保有对应的处理函数
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    // 根据系统调用号查找对应的系统调用函数并调用
    // 系统调用的返回值会存储在 p->trapframe->a0 中
    p->trapframe->a0 = syscalls[num]();
  } else {
    // 如果找不到有效的系统调用，打印错误信息
    printf("%d %s: unknown sys call %d\n",
            p->pid, p->name, num);
    p->trapframe->a0 = -1;  // 设置返回值为 -1 表示错误
  }
}

