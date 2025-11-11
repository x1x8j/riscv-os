#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct spinlock tickslock;
uint ticks;

extern char trampoline[], uservec[];

// in kernelvec.S, calls kerneltrap().
void kernelvec();

extern int devintr();

void
trapinit(void)
{
  initlock(&tickslock, "time");
}

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
  w_stvec((uint64)kernelvec);
}

//
// handle an interrupt, exception, or system call from user space.
// called from, and returns to, trampoline.S
// return value is user satp for trampoline.S to switch to.
//
uint64
usertrap(void)
{
  int which_dev = 0;  // 设备中断标志

  // 如果当前不在用户模式下（SSTATUS_SPP不为0），触发 panic。
  if((r_sstatus() & SSTATUS_SPP) != 0)
    panic("usertrap: not from user mode");

  // 设置内核中断向量。将所有中断和异常都发送到 kerneltrap()。
  // 因为当前已进入内核模式，所以需要更改中断处理函数。
  w_stvec((uint64)kernelvec);  //DOC: kernelvec

  // 获取当前进程的指针
  struct proc *p = myproc();
  
  // 保存用户程序计数器的值。sepc 存储用户程序的下一条指令地址。
  p->trapframe->epc = r_sepc();

  // 检查发生的异常类型（通过 scause 寄存器）。如果是系统调用（scause == 8），进行系统调用处理。
  if(r_scause() == 8){
    // 如果进程已被杀死，调用 kexit 退出进程
    if(killed(p))
      kexit(-1);

    // sepc 指向 ecall 指令位置，但我们要跳到下一条指令
    p->trapframe->epc += 4;

    // 在此之前，我们已保存了 scause, sepc 和 sstatus 的值，
    // 因此现在可以启用中断。
    intr_on();

    // 调用系统调用处理函数
    syscall();
  } 
  // 如果发生设备中断，则调用 devintr 处理设备中断。
  else if((which_dev = devintr()) != 0){
    // 设备中断处理成功
  } 
  // 如果发生页错误（页面缺失或访问非法地址），通过 vmfault 进行处理。
  // scause 为 15 或 13 时，表示页错误（13为访问违规，15为缺页）。
  else if((r_scause() == 15 || r_scause() == 13) &&
           vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    // 页错误发生，处理惰性分配页面
  } else {
    // 如果发生了未知的异常，打印错误信息并标记进程为已杀死。
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    setkilled(p);  // 标记进程为已杀死
  }

  // 如果进程已被杀死，调用 kexit() 退出进程
  if(killed(p))
    kexit(-1);

  // 如果发生了定时器中断（which_dev == 2），让当前进程主动让出 CPU
  if(which_dev == 2){
    // 定时器中断后，需要主动让出 CPU。
    yield();
  }

  // 返回之前的设置，准备恢复用户态
  prepare_return();

  // 获取当前进程的页表，并将其设置为 satp（内存管理寄存器），用于返回到用户空间
  uint64 satp = MAKE_SATP(p->pagetable);

  // 返回 satp 的值，交给 trampoline.S 进行处理。
  // satp 值存放在 a0 寄存器中，系统将根据 satp 设置页表并恢复用户态。
  return satp;
}


//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
  struct proc *p = myproc();

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
  p->trapframe->kernel_trap = (uint64)usertrap;
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()

  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
  x |= SSTATUS_SPIE; // enable interrupts in user mode
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
}

// interrupts and exceptions from kernel code go here via kernelvec,
// on whatever the current kernel stack is.
void 
kerneltrap()
{
  int which_dev = 0;
  uint64 sepc = r_sepc();
  uint64 sstatus = r_sstatus();
  uint64 scause = r_scause();
  
  if((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: not from supervisor mode");
  if(intr_get() != 0)
    panic("kerneltrap: interrupts enabled");

  if((which_dev = devintr()) == 0){
    // interrupt or trap from an unknown source
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    panic("kerneltrap");
  }

  // give up the CPU if this is a timer interrupt.
//  if(which_dev == 2 && myproc() != 0)
//    yield();
  if(which_dev == 2&&myproc()!=0) { // timer interrupt
    // 增加当前进程已用 tick 数
//    printf("===============kernel===============");
    struct proc *p = myproc();
    acquire(&p->lock);
    p->ticks++;
    int need_yield = (p->ticks >= p->timeslice);
    if (need_yield) {
      p->ticks = 0; // 重置时间片计数器
    }
    release(&p->lock);

    if (need_yield) {
      yield(); // 时间片用完，主动让出 CPU
    }
  }

  // the yield() may have caused some traps to occur,
  // so restore trap registers for use by kernelvec.S's sepc instruction.
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void
clockintr()
{
  if(cpuid() == 0){
    acquire(&tickslock);
    ticks++;
    wakeup(&ticks);
    release(&tickslock);
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
}

// check if it's an external interrupt or software interrupt,
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    // this is a supervisor external interrupt, via PLIC.

    // irq indicates which device interrupted.
    int irq = plic_claim();

    if(irq == UART0_IRQ){
      uartintr();
    } else if(irq == VIRTIO0_IRQ){
      virtio_disk_intr();
    } else if(irq){
      printf("unexpected interrupt irq=%d\n", irq);
    }

    // the PLIC allows each device to raise at most one
    // interrupt at a time; tell the PLIC the device is
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
  }
}

