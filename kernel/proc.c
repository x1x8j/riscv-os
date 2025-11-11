#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

// 所有 CPU 的结构体数组
struct cpu cpus[NCPU];

// 进程表，最多 NPROC 个进程
struct proc proc[NPROC];

// init 进程的指针
struct proc *initproc;

// 下一个可用的 PID，从 1 开始
int nextpid = 1;

// 用于保护 nextpid 的自旋锁
struct spinlock pid_lock;

extern void forkret(void);          // 子进程首次调度时执行的函数
static void freeproc(struct proc *p); // 释放进程资源的辅助函数

extern char trampoline[]; // trampoline.S 中的跳板代码

// 用于确保 wait() 等待父进程的唤醒不会丢失。
// 在使用 p->parent 时帮助遵守内存模型。
// 必须在获取任何 p->lock 之前先获取此锁。
struct spinlock wait_lock;

// 为每个进程分配一页内核栈。
// 将其映射到高地址空间，后面跟一个无效的保护页（guard page）。
void
proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc(); // 分配物理页
    if(pa == 0)
      panic("kalloc");   // 内存不足，崩溃
    uint64 va = KSTACK((int) (p - proc)); // 计算该进程内核栈的虚拟地址
    // 将物理页映射到内核页表中的指定虚拟地址
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// 初始化进程表。
void
procinit(void)
{
  struct proc *p;
  
  // 初始化 PID 锁和等待锁
  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  
  for(p = proc; p < &proc[NPROC]; p++) {
      initlock(&p->lock, "proc"); // 为每个进程初始化自己的锁
      p->state = UNUSED;          // 初始状态为未使用
      p->kstack = KSTACK((int) (p - proc)); // 设置内核栈地址
  }
}

// 必须在中断关闭的情况下调用，
// 以防止进程在被移动到不同 CPU 时发生竞争。
int
cpuid()
{
  int id = r_tp(); // 读取当前 CPU 的 hart ID（RISC-V 的 tp 寄存器）
  return id;
}

// 返回当前 CPU 对应的 cpu 结构体。
// 必须在中断关闭的情况下调用。
struct cpu*
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// 返回当前进程的 proc 结构体指针，若无则返回 0。
struct proc*
myproc(void)
{
  push_off();           // 关闭中断并保存状态
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();            // 恢复中断状态
  return p;
}

// 分配一个新的 PID。
int
allocpid()
{
  int pid;
  
  acquire(&pid_lock);   // 获取锁
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);   // 释放锁

  return pid;
}

// 在进程表中查找一个状态为 UNUSED 的进程。
// 如果找到，初始化其内核运行所需的状态，并返回时保持 p->lock 已锁定。
// 如果没有空闲进程或内存分配失败，则返回 0。
static struct proc*
allocproc(void)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->state == UNUSED) {
      goto found; // 找到了，跳转到初始化部分
    } else {
      release(&p->lock); // 没找到，释放锁继续找
    }
  }
  return 0; // 没有空闲进程

found:
  p->pid = allocpid();     // 分配 PID
  p->state = USED;         // 标记为已使用

  p->ticks = 0;            // 已运行的时钟滴答数
  p->timeslice = 5;        // 时间片长度（用于调度）

  // 为 trapframe 分配一页内存
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    freeproc(p);           // 分配失败，清理资源
    release(&p->lock);
    return 0;
  }

  // 创建一个空的用户页表
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // 设置新进程的上下文，使其首次运行时从 forkret 开始执行，
  // forkret 最终会返回到用户空间。
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;        // 返回地址设为 forkret
  p->context.sp = p->kstack + PGSIZE;     // 栈指针指向内核栈顶部

  return p;
}

// 释放一个 proc 结构及其关联的所有数据，
// 包括用户内存页。
// 调用时必须已持有 p->lock。
static void
freeproc(struct proc *p)
{
  if(p->trapframe)
    kfree((void*)p->trapframe); // 释放 trapframe 页
  p->trapframe = 0;
  
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz); // 释放用户页表及内存
  p->pagetable = 0;
  p->sz = 0;           // 用户内存大小清零
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;      // 清空进程名
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;   // 标记为未使用
}

// 为给定进程创建一个用户页表，初始不包含用户内存，
// 但会映射 trampoline 和 trapframe 页面。
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // 创建一个空的页表
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // 将 trampoline 代码映射到用户虚拟地址空间的最高处。
  // 只有内核在进出用户空间时使用它，因此不需要 PTE_U（用户可访问）权限。
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // 将 trapframe 页面映射到 trampoline 页面正下方，
  // 供 trampoline.S 使用。
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// 释放进程的页表，并释放其引用的物理内存。
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0); // 解除 trampoline 映射
  uvmunmap(pagetable, TRAPFRAME, 1, 0);  // 解除 trapframe 映射
  uvmfree(pagetable, sz);                // 释放用户内存
}

// 设置第一个用户进程（init 进程）。
void
userinit(void)
{
  struct proc *p;

  p = allocproc();      // 分配一个新进程
  initproc = p;         // 记录为 init 进程
  
  p->cwd = namei("/");  // 设置当前工作目录为根目录

  safestrcpy(p->name, "init", sizeof(p->name)); // 设置进程名为 "init"

  p->state = RUNNABLE;  // 标记为可运行

  release(&p->lock);    // 释放锁，允许调度器调度它
}

// 增长或缩减用户内存 n 字节。
// 成功返回 0，失败返回 -1。
int
growproc(int n)
{
  uint64 sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
    // 检查是否超过 TRAPFRAME 地址（用户空间上限）
    if(sz + n > TRAPFRAME) {
      return -1;
    }
    // 分配新页
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
      return -1;
    }
  } else if(n < 0){
    // 释放内存
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// 创建一个新进程，复制父进程。
// 设置子进程的内核栈，使其看起来像是从 fork() 系统调用返回。
int
kfork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc(); // 当前进程是父进程

  // 分配新进程结构
  if((np = allocproc()) == 0){
    return -1;
  }

  // 复制父进程的用户内存到子进程
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // 复制保存的用户寄存器（trapframe）
  *(np->trapframe) = *(p->trapframe);

  // 使子进程中的 fork() 返回 0
  np->trapframe->a0 = 0;

  // 增加打开文件描述符的引用计数
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd); // 复制当前工作目录

  safestrcpy(np->name, p->name, sizeof(p->name)); // 复制进程名

  pid = np->pid;

  release(&np->lock);

  // 设置父子关系
  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  // 将子进程标记为可运行
  acquire(&np->lock);
  np->state = RUNNABLE;
  release(&np->lock);

  return pid;
}

// 将 p 的所有子进程交给 init 进程收养。
// 调用者必须持有 wait_lock。
void
reparent(struct proc *p)
{
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->parent == p){
      pp->parent = initproc;
      wakeup(initproc); // 唤醒 init，让它可以 wait 这些孤儿进程
    }
  }
}

// 退出当前进程。此函数永不返回。
// 已退出的进程会进入僵尸状态，直到其父进程调用 wait()。
void
kexit(int status)
{
  struct proc *p = myproc();

  if(p == initproc)
    panic("init exiting"); // init 进程不能退出

  // 关闭所有打开的文件
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  // 释放当前工作目录的 inode 引用
  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // 将所有子进程交给 init 收养
  reparent(p);

  // 父进程可能正在 wait() 中睡眠，唤醒它
  wakeup(p->parent);
  
  acquire(&p->lock);

  p->xstate = status;   // 保存退出状态
  p->state = ZOMBIE;    // 进入僵尸状态

  release(&wait_lock);

  // 跳转到调度器，永不返回
  sched();
  panic("zombie exit");
}

// 等待一个子进程退出，并返回其 PID。
// 如果当前进程没有子进程，返回 -1。
int
kwait(uint64 addr)
{
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for(;;){
    // 扫描进程表，查找已退出的子进程
    havekids = 0;
    for(pp = proc; pp < &proc[NPROC]; pp++){
      if(pp->parent == p){
        // 确保子进程已完成 exit() 或 swtch()
        acquire(&pp->lock);

        havekids = 1;
        if(pp->state == ZOMBIE){
          // 找到一个僵尸子进程
          pid = pp->pid;
          // 如果提供了地址，将退出状态拷贝到用户空间
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
                                  sizeof(pp->xstate)) < 0) {
            release(&pp->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(pp); // 释放子进程资源
          release(&pp->lock);
          release(&wait_lock);
          return pid;
        }
        release(&pp->lock);
      }
    }

    // 如果没有子进程，或当前进程已被杀死，则返回 -1
    if(!havekids || killed(p)){
      release(&wait_lock);
      return -1;
    }
    
    // 没有可回收的子进程，睡眠等待
    sleep(p, &wait_lock);  //DOC: wait-sleep
  }
}

// 每个 CPU 的进程调度器。
// 每个 CPU 在初始化完成后调用 scheduler()。
// 调度器永不返回，它循环执行以下操作：
//  - 选择一个进程运行
//  - 通过 swtch 切换到该进程
//  - 该进程最终会通过 swtch 切换回调度器
void
scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();

  c->proc = 0;

  static struct proc *last_scheduled = 0;  // 记住上次调度的位置

  for(;;){

    intr_on();
    intr_off();

    struct proc *start = last_scheduled ? last_scheduled : proc;
    p = start;
    do {
      // 如果超出数组末尾，回绕到开头
      if (p >= &proc[NPROC])
        p = proc;
      acquire(&p->lock);
      if (p->state == RUNNABLE) {
        // 找到可运行进程
        last_scheduled = p + 1;  // 下次从下一个开始
        if (last_scheduled >= &proc[NPROC])
          last_scheduled = proc;
        // 切换到该进程
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);
        // 返回后：当前进程已切换回来
        c->proc = 0;
        release(&p->lock);
        break;  // 跳出 do-while，重新开始调度循环
      }
      release(&p->lock);
      p++;
    } while (p != start);  // 扫描一圈都没找到就继续空转

  }
}
// 切换到调度器。调用时必须只持有 p->lock，
// 并且已经更改了 proc->state。
// 保存和恢复 intena，因为 intena 是当前内核线程的属性，
// 而不是当前 CPU 的属性。
// （理想情况下应为 proc->intena 和 proc->noff，但这会在少数持有锁但无进程的场景中出错）
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched RUNNING");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// 主动让出 CPU，进入下一轮调度。
void
yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  sched();
  release(&p->lock);
}

// 子进程首次被调度器调度时，会切换到 forkret。
void
forkret(void)
{
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();

  // 仍持有来自 scheduler 的 p->lock。
  release(&p->lock);

  if (first) {
    // 文件系统初始化必须在普通进程上下文中运行
    // （例如，因为它会调用 sleep），因此不能在 main() 中运行。
    fsinit(ROOTDEV);

    first = 0;
    // 确保其他 CPU 能看到 first=0。
    __sync_synchronize();

    // 现在可以调用 kexec() 了。
    // 将 kexec 的返回值（argc）放入 a0。
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    if (p->trapframe->a0 == -1) {
      panic("exec");
    }
  }

  // 返回用户空间，模拟 usertrap() 的返回过程。
  prepare_return();
  uint64 satp = MAKE_SATP(p->pagetable); // 构造 SATP 寄存器值（页表基址）
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline); // 计算 userret 在 trampoline 中的地址
  // 跳转到 trampoline 中的 userret，传入页表参数
  ((void (*)(uint64))trampoline_userret)(satp);
}

// 在 chan 通道上睡眠，释放条件锁 lk。
// 唤醒后重新获取 lk。
void
sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();
  
  // 必须获取 p->lock 才能
  // 修改 p->state 并调用 sched。
  // 一旦持有 p->lock，就能保证
  // 不会错过任何 wakeup（因为 wakeup 也会锁 p->lock），
  // 因此可以安全地释放 lk。

  acquire(&p->lock);  //DOC: sleeplock1
  release(lk);

  // 进入睡眠
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // 清理
  p->chan = 0;

  // 重新获取原始的锁
  release(&p->lock);
  acquire(lk);
}

// 唤醒所有在 chan 通道上睡眠的进程。
// 调用者应持有条件锁。
void
wakeup(void *chan)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    if(p != myproc()){ // 不唤醒自己
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
        p->state = RUNNABLE; // 标记为可运行
      }
      release(&p->lock);
    }
  }
}

// 杀死指定 PID 的进程。
// 被杀进程不会立即退出，而是在下次尝试返回用户空间时退出（见 trap.c 中的 usertrap()）。
int
kkill(int pid)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1; // 标记为已杀死
      if(p->state == SLEEPING){
        // 如果正在睡眠，将其唤醒以便退出
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1; // 未找到
}

// 设置进程 p 的 killed 标志。
void
setkilled(struct proc *p)
{
  acquire(&p->lock);
  p->killed = 1;
  release(&p->lock);
}

// 检查进程 p 是否已被标记为 killed。
int
killed(struct proc *p)
{
  int k;
  
  acquire(&p->lock);
  k = p->killed;
  release(&p->lock);
  return k;
}

// 根据 usr_dst 决定将数据拷贝到用户地址还是内核地址。
// 成功返回 0，失败返回 -1。
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len); // 拷贝到用户空间
  } else {
    memmove((char *)dst, src, len); // 拷贝到内核空间
    return 0;
  }
}

// 根据 usr_src 决定从用户地址还是内核地址拷贝数据。
// 成功返回 0，失败返回 -1。
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len); // 从用户空间拷贝
  } else {
    memmove(dst, (char*)src, len); // 从内核空间拷贝
    return 0;
  }
}


// 系统调用：dump_proc —— 将所有进程信息拷贝到用户提供的缓冲区。
int
sys_dump_proc(void)
{
    uint64 addr;
    // 获取用户传入的指针地址（第0个参数）
    argaddr(0, &addr);

    if (addr == 0)
        return -1;  // 无效地址

    for (int i = 0; i < NPROC; i++) {
        struct proc *p = &proc[i];
        acquire(&p->lock);
        struct pstat ps;
        ps.inuse = (p->state != UNUSED);
        ps.pid = p->pid;
        ps.state = p->state;
        safestrcpy(ps.name, p->name, sizeof(ps.name));
        release(&p->lock);

        // 安全拷贝到用户空间
        if (copyout(myproc()->pagetable, addr + i * sizeof(ps), (char*)&ps, sizeof(ps)) < 0) {
            return -1;
        }
    }
    return 0;
}
