#include "riscv.h"
#include "defs.h"

// 外部函数声明
extern void kernelvec(void);
extern uint64 ticks;
extern void set_next_timer(void);
extern int devintr(void);

// 中断处理函数类型
typedef void (*interrupt_handler_t)(void);

// 中断处理函数表
static interrupt_handler_t interrupt_handlers[16];

// 注册中断处理函数
static void register_interrupt(int irq, interrupt_handler_t handler) {
  if (irq >= 0 && irq < 16) {
    interrupt_handlers[irq] = handler;
  }
}

// 使能时钟中断
static void enable_timer_interrupt(void) {
  w_sie(r_sie() | SIE_STIE);
}

// 初始化陷阱处理
void trap_init(void) {
  // 设置陷阱向量基址
  w_stvec((uint64)kernelvec);
  
  // 使能时钟中断
  enable_timer_interrupt();
  
  // 全局使能中断
  intr_on();
  
  // 注册时钟中断处理函数
  register_interrupt(IRQ_S_TIMER, clockintr);
  
  // 打印寄存器状态
  printf("SIE=%lx SSTATUS=%lx STVEC=%lx TIME=%ld STIMECMP=%ld\n",
           r_sie(), r_sstatus(), r_stvec(), r_time(), r_stimecmp());

}

// 处理中断
//static void handle_interrupt(uint64 scause) {
//  int irq = scause & SCAUSE_CODE_MASK;
  
//  if (irq >= 0 && irq < 16 && interrupt_handlers[irq]) {
//    interrupt_handlers[irq]();
//  } else {
//    printf("unknown interrupt: %d\n", irq);
//  }
//}

// 处理异常
void handle_exception(struct trapframe *tf) {
  uint64 scause = r_scause();
  
  switch (scause) {
    case 8:  // 系统调用
      printf("syscall not implemented\n");
      break;
    case 12: // 指令页故障
      panic("instruction page fault");
      break;
    case 13: // 加载页故障
      panic("load page fault");
      break;
    case 15: // 存储页故障
      panic("store page fault");
      break;
    default:
      printf("unknown exception: %lu\n", scause);
      panic("unknown exception");
  }
}

//extern void clockintr(void);
// 时钟中断处理函数 
//void clockintr(void) {
//  ticks++;
//  printf("Timer interrupt: ticks = %lu, time = %lu\n", ticks, get_time());
//  set_next_timer();
//  printf("Set next timer interrupt\n");
//}

// 测试异常处理
void test_exception_handling(void) {
  printf("Testing exception handling...\n");
  
  // 测试非法指令异常 (如果支持)
  printf("Testing illegal instruction exception...\n");
  // 注意：这可能会导致系统崩溃，所以先注释掉
  // asm volatile(".word 0x00000000"); // 非法指令
  
  // 测试内存访问异常
  printf("Testing memory access exception...\n");
  // 尝试访问未映射的内存地址
//  volatile uint64 *bad_ptr = (uint64 *)0x1000000000; // 高地址，可能未映射
  // 注意：这也可能导致页故障，先注释掉
  // uint64 val = *bad_ptr;
  
  printf("Exception tests completed (simplified)\n");
}

// 测试中断性能开销
void test_interrupt_overhead(void) {
  printf("Testing interrupt overhead...\n");
  
  // 测量中断处理的时间开销
  uint64 start_time, end_time;
  uint64 start_ticks = ticks;
  
  printf("Measuring interrupt processing overhead...\n");
  
  // 等待几次中断来测量开销
  start_time = get_time();
  while (ticks < start_ticks + 3) {
    // 忙等待
  }
  end_time = get_time();
  
  uint64 total_cycles = end_time - start_time;
  uint64 interrupt_count = ticks - start_ticks;
  uint64 avg_cycles_per_interrupt = total_cycles / interrupt_count;
  
  printf("Interrupt performance results:\n");
  printf("  Total cycles: %lu\n", total_cycles);
  printf("  Interrupt count: %lu\n", interrupt_count);
  printf("  Average cycles per interrupt: %lu\n", avg_cycles_per_interrupt);
  
  // 分析中断频率对系统性能的影响
  printf("Analyzing interrupt frequency impact...\n");
  
  // 测试高频率中断的影响
  uint64 test_start = get_time();
  uint64 test_ticks_start = ticks;
  
  // 执行一些计算任务
  volatile uint64 sum = 0;
  for (int i = 0; i < 1000000; i++) {
    sum += i;
  }
  
  uint64 test_end = get_time();
  uint64 test_ticks_end = ticks;
  
  printf("Performance test results:\n");
  printf("  Computation cycles: %lu\n", test_end - test_start);
  printf("  Interrupts during computation: %lu\n", test_ticks_end - test_ticks_start);
  printf("  Sum result: %lu\n", sum);
}

// 内核陷阱处理函数

//void kerneltrap(struct trapframe *tf) {

//  printf("🔥 TRAP ENTERED!\n");
//  uint64 scause = r_scause();
  
//  if (scause & SCAUSE_INTERRUPT_MASK) {
    // 中断
//    handle_interrupt(scause);
//  } else {
    // 异常
//    handle_exception(tf);
//  }
//}
//
// interrupts and exceptions from kernel code go here via kernelvec,
// on whatever the current kernel stack is.
// 译：从内核代码的中断和异常会经由kernelvec到达这里
// 无论当前的内核栈是什么
void 
kerneltrap()
{
  printf("9999999999999999999999999");
  // 保存当前CPU的一些重要的寄存器
  // 因为有可能当前处理的是一个时钟中断，进而会导致CPU的调度
  // 再次返回到此进程时，sepc，sstatus和scause寄存器可能已经面目全非了
  // 所以必须保留下来以备将来恢复
  int which_dev = 0;
  uint64 sepc = r_sepc();
  uint64 sstatus = r_sstatus();
  uint64 scause = r_scause();
  
  // 异常检测，检查是否是从内核态而来的陷阱
  // 并且检查中断是否已经关闭
  // 注意，这里保证中断关闭，其实相当于禁止了中断的进一步嵌套
  if((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: not from supervisor mode");
  if(intr_get() != 0)
    panic("kerneltrap: interrupts enabled");
  
  // 尝试使用devintr去响应中断(包括时钟中断和外部中断)
  // devintr也相当于一个中转站，它会通过检查scause寄存器中的值
  // 确定中断的类型并加以分门别类的处理
  // 返回值表明了中断的类型，0表示没能识别中断来源，那其实也就意味着这是个异常
  // 打印出必要的debug信息后陷入panic即可
  

  if((which_dev = devintr()) == 0){
    printf("scause %p\n", scause);
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    panic("kerneltrap");
  }

  // give up the CPU if this is a timer interrupt.
  // 如果是一个时间中断，那么就会产生CPU的调度，当前进程放弃CPU
  // yield函数的细节在此不再展开
//  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
//    yield();

  // the yield() may have caused some traps to occur,
  // so restore trap registers for use by kernelvec.S's sepc instruction.
  // 译：yield调度CPU到另外一个进程时，可能在那个新的进程中会有陷阱发生
  // 所以为了kernelvec.S中的sret(这里注释有误？)指令所用，恢复陷阱寄存器
  w_sepc(sepc);
  w_sstatus(sstatus);
}

//void
//clockintr()
//{
//  if(cpuid() == 0){
//    acquire(&tickslock);
//    ticks++;
//    wakeup(&ticks);
//    release(&tickslock);
//  }
  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
//  w_stimecmp(r_time() + 1000000);
//}

void clockintr() {
  ticks++;  // 增加滴答数
  printf("Tick %d\n", ticks);
  set_next_timer();  // ⏱️ 立即设置下一次中断
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

//  if(scause == 0x8000000000000009L){
    // this is a supervisor external interrupt, via PLIC.

    // irq indicates which device interrupted.
//    int irq = plic_claim();

//    if(irq == UART0_IRQ){
//      uartintr();
//    } else if(irq == VIRTIO0_IRQ){
//      virtio_disk_intr();
//    } else if(irq){
//      printf("unexpected interrupt irq=%d\n", irq);
//    }

    // the PLIC allows each device to raise at most one
    // interrupt at a time; tell the PLIC the device is
    // now allowed to interrupt again.
//    if(irq)
//      plic_complete(irq);

//    return 1;
//  } else 
  if(scause == 0x8000000000000005L){
    // timer interrupt.
    clockintr();
    printf("LLLLLLLLllllllll");
    return 2;
  } else {
    return 0;
  }
}
