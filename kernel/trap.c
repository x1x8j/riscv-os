#include "types.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"

extern volatile int timer_interrupt_count;  // 在 trap.c 中引用 main.c 中定义的 interrupt_count
uint ticks;

//extern char trampoline[], uservec[];

// in kernelvec.S, calls kerneltrap().
void kernelvec();

extern int devintr();

// void
// trapinit(void)
// {
//   initlock(&tickslock, "time");
// }

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
  w_stvec((uint64)kernelvec);
}


void handle_floating_point_exception() {
    panic("Floating-point exception");
}

void handle_illegal_instruction() {
    panic("Illegal instruction");
}

void handle_instruction_address_misalignment() {
    panic("Instruction address misaligned");
}

void handle_instruction_access_fault() {
    panic("Instruction access fault");
}



void handle_breakpoint() {
    panic("Breakpoint");
}

void handle_load_address_misalignment() {
    panic("Load address misaligned");
}

void handle_load_access_fault() {
    panic("Load access fault");
}

void handle_store_address_misalignment() {
    panic("Store address misaligned");
}

void handle_store_access_fault() {
    panic("Store access fault");
}

void handle_user_ecall() {
    panic("User environment call");
}

void handle_supervisor_ecall() {
    panic("Supervisor environment call");
}

void handle_timer_interrupt() {
    panic("Timer interrupt");
}

void handle_external_interrupt() {
    panic("External interrupt");
}

void handle_load_page_fault() {
    panic("Load page fault");
}

void handle_store_page_fault() {
    panic("Store page fault");
}

void handle_exception() {
    uint64 cause = r_scause();  // 获取异常的原因

    switch (cause) {
        case 0:  // 浮点异常 (Floating-point exception)
            handle_floating_point_exception();  // 处理浮点异常
            break;
        case 1:  // 非法指令 (Illegal instruction)
            handle_illegal_instruction();  // 处理非法指令
            break;
        case 2:  // 指令地址未对齐 (Instruction address misaligned)
            handle_instruction_address_misalignment();  // 处理指令地址未对齐
            break;
        case 3:  // 指令访问故障 (Instruction access fault)
            handle_instruction_access_fault();  // 处理指令访问故障
            break;
        case 4:  // 断点 (Breakpoint)
            handle_breakpoint();  // 处理断点
            break;
        case 5:  // 加载地址未对齐 (Load address misaligned)
            handle_load_address_misalignment();  // 处理加载地址未对齐
            break;
        case 6:  // 加载访问故障 (Load access fault)
            handle_load_access_fault();  // 处理加载访问故障
            break;
        case 7:  // 存储地址未对齐 (Store address misaligned)
            handle_store_address_misalignment();  // 处理存储地址未对齐
            break;
        case 8:  // 存储访问故障 (Store access fault)
            handle_store_access_fault();  // 处理存储访问故障
            break;
        case 9:  // 用户模式环境调用 (User environment call)
            handle_user_ecall();  // 处理用户模式环境调用
            break;
        case 10: // 监督模式环境调用 (Supervisor environment call)
            handle_supervisor_ecall();  // 处理监督模式环境调用
            break;
        case 11: // 计时器中断 (Timer interrupt)
            handle_timer_interrupt();  // 处理计时器中断
            break;
        case 12: // 外部中断 (External interrupt)
            handle_external_interrupt();  // 处理外部中断
            break;
        case 13: // 加载页故障 (Load page fault)
            handle_load_page_fault();  // 处理加载页故障
            break;
        case 14: // 存储页故障 (Store page fault)
            handle_store_page_fault();  // 处理存储页故障
            break;
        case 15: // 存储页故障 (Store page fault)
            handle_store_page_fault();  // 处理存储页故障
            break;
        default:
            printf("Unknown exception: scause=0x%lx\n", cause);
            panic("Unknown exception");
    }
}

// handle an interrupt, exception, or system call from user space.
// called from, and returns to, trampoline.S
// return value is user satp for trampoline.S to switch to.
//
// uint64
// usertrap(void)
// {
//   int which_dev = 0;

//   if((r_sstatus() & SSTATUS_SPP) != 0)
//     panic("usertrap: not from user mode");

//   // send interrupts and exceptions to kerneltrap(),
//   // since we're now in the kernel.
//   w_stvec((uint64)kernelvec);  //DOC: kernelvec

//   struct proc *p = myproc();
  
//   // save user program counter.
//   p->trapframe->epc = r_sepc();
  
//   if(r_scause() == 8){
//     // system call

//     if(killed(p))
//       kexit(-1);

//     // sepc points to the ecall instruction,
//     // but we want to return to the next instruction.
//     p->trapframe->epc += 4;

//     // an interrupt will change sepc, scause, and sstatus,
//     // so enable only now that we're done with those registers.
//     intr_on();

//     syscall();
//   } else if((which_dev = devintr()) != 0){
//     // ok
//   } else if((r_scause() == 15 || r_scause() == 13) &&
//             vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
//     // page fault on lazily-allocated page
//   } else {
//     printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
//     printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
//     setkilled(p);
//   }

//   if(killed(p))
//     kexit(-1);

//   // give up the CPU if this is a timer interrupt.
//   if(which_dev == 2)
//     yield();

//   prepare_return();

//   // the user page table to switch to, for trampoline.S
//   uint64 satp = MAKE_SATP(p->pagetable);

//   // return to trampoline.S; satp value in a0.
//   return satp;
// }

//
// set up trapframe and control registers for a return to user space
//
// void
// prepare_return(void)
// {
//   struct proc *p = myproc();

//   // we're about to switch the destination of traps from
//   // kerneltrap() to usertrap(). because a trap from kernel
//   // code to usertrap would be a disaster, turn off interrupts.
//   intr_off();

//   // send syscalls, interrupts, and exceptions to uservec in trampoline.S
//   uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
//   w_stvec(trampoline_uservec);

//   // set up trapframe values that uservec will need when
//   // the process next traps into the kernel.
//   p->trapframe->kernel_satp = r_satp();         // kernel page table
//   p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
//   p->trapframe->kernel_trap = (uint64)usertrap;
//   p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()

//   // set up the registers that trampoline.S's sret will use
//   // to get to user space.
  
//   // set S Previous Privilege mode to User.
//   unsigned long x = r_sstatus();
//   x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
//   x |= SSTATUS_SPIE; // enable interrupts in user mode
//   w_sstatus(x);

//   // set S Exception Program Counter to the saved user pc.
//   w_sepc(p->trapframe->epc);
// }

// interrupts and exceptions from kernel code go here via kernelvec,
// on whatever the current kernel stack is.
void 
kerneltrap()
{
 // printf("[TRAP] Entering kerneltrap!\n");
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
    handle_exception();
    //panic("kerneltrap");
    
  }

  // give up the CPU if this is a timer interrupt.
  // if(which_dev == 2 && myproc() != 0)
  //   yield();

  // the yield() may have caused some traps to occur,
  // so restore trap registers for use by kernelvec.S's sepc instruction.
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void
clockintr()
{
  // if(cpuid() == 0){
  //   acquire(&tickslock);
  //   ticks++;
  //   wakeup(&ticks);
  //   release(&tickslock);
  // }
  ticks++;
  timer_interrupt_count++;

  printf("Tick %d\n", timer_interrupt_count);
    // 假设希望10次中断后停止
  if (timer_interrupt_count>= 10) {
    // 关闭时钟中断
    w_sie(r_sie() & ~SIE_STIE);
    printf("Timer interrupt stopped after %d ticks\n", timer_interrupt_count);
    return;
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
  //   // this is a supervisor external interrupt, via PLIC.

  //   // irq indicates which device interrupted.
  //   int irq = plic_claim();

  //   if(irq == UART0_IRQ){
  //     uartintr();
  //   } else if(irq == VIRTIO0_IRQ){
  //     virtio_disk_intr();
  //   } else if(irq){
  //     printf("unexpected interrupt irq=%d\n", irq);
  //   }

  //   // the PLIC allows each device to raise at most one
  //   // interrupt at a time; tell the PLIC the device is
  //   // now allowed to interrupt again.
  //   if(irq)
  //     plic_complete(irq);

     return 1;
   } else 
  if(scause == 0x8000000000000005L){
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
  }
}


