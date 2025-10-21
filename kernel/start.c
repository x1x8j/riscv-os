#include "riscv.h"
#include "defs.h"

// 全局时钟计数器
volatile uint64 ticks = 0;

// 获取当前时间
uint64 get_time(void) {
  return r_time();
}

// 设置下次时钟中断
//void set_next_timer(void) {
  // 设置较短的时间间隔来测试中断
//  uint64 current = get_time();
//  uint64 next = current + 100000;  // 0.1秒后中断
//  printf("Setting timer: current=%lu, next=%lu\n", current, next);
  
  //直接写 mtimecmp 寄存器（
//  *(volatile uint64*)0x02004000 = next;

//  uint64 back = *(volatile uint64*)0x02004000;
//  printf("Read back: %lu\n", back);

//  printf("Direct write to mtimecmp done\n");
//}
void set_next_timer() {
  uint64 now = r_time();
  uint64 next = now + 50000;
  printf("hhhhhh");
  w_stimecmp(next);
}
#define MTIMECMP  ((uint64*)0x02004000)
#define MTIME     ((uint64*)0x0200BFF8)

//void set_next_timer() {
//  uint64 now = *MTIME;
//  uint64 next = now + 1000000;
//  *MTIMECMP = next;
//  printf("Setting next timer: now = %lu, next = %lu\n", now, next);
//}


// 初始化定时器 (xv6 风格)
//void timerinit(void) {
//  ticks = 0;
//  set_next_timer();
//}
//
// ask each hart to generate timer interrupts.
//void
//timerinit()
//{
  // enable supervisor-mode timer interrupts.
//  w_mie(r_mie() | MIE_STIE);
  
  // enable the sstc extension (i.e. stimecmp).
//  w_menvcfg(r_menvcfg() | (1L << 63)); 
  
  // allow supervisor to use stimecmp and time.
//  w_mcounteren(r_mcounteren() | 2);
  
  // ask for the very first timer interrupt.
//  w_stimecmp(r_time() + 1000000);
//}
void timerinit(void) {
  // 1. 启用 SSTC 扩展
  w_menvcfg(r_menvcfg() | (1UL << 63));

  // 2. 允许 S-Mode 访问 time 寄存器
  w_mcounteren(r_mcounteren() | 2);

  // 3. 委托 S-Mode 软件中断和时钟中断到 S-Mode 处理
  w_mideleg(r_mideleg() | (1 << 5));  // MTIP -> STIP
  w_mideleg(r_mideleg() | (1 << 1));  // MSIP -> SSIP

  // 4. 开启 S-Mode 时钟中断使能
  w_sie(r_sie() | SIE_STIE);

  // 5. 设置第一次 stimecmp
  set_next_timer();  // ← 调用这个函数
}


// 测试时钟中断
void test_timer_interrupt(void) {
  printf("Testing timer interrupt...\n");
  printf("Time: %lu, Ticks: %lu\n", get_time(), ticks);
  
  uint64 start_ticks = ticks;
  printf("Waiting for interrupts...\n");
  
  // 等待 2 次时钟中断
  int timeout = 0;
  while (ticks < start_ticks + 2 && timeout < 500) {
    printf("Wait %d, ticks=%lu\n", timeout, ticks);
    for (volatile int i = 0; i < 100000; i++);
    timeout++;
  }
  
  printf("Test done: %lu interrupts, timeout=%d\n", ticks - start_ticks, timeout);
}

// 机器模式初始化
void start(void) {
  printf("Starting machine mode initialization...\n");
  
  // 委托时钟中断给 S 模式
  w_mideleg(r_mideleg() | (1L << 5));
  printf("Delegated timer interrupt to S-mode, mideleg: 0x%lx\n", r_mideleg());
  
  // 委托软件中断给 S 模式
  w_mideleg(r_mideleg() | (1L << 1));
  
  // 委托外部中断给 S 模式
  w_mideleg(r_mideleg() | (1L << 9));
  
  // 委托一些异常给 S 模式
  w_medeleg(r_medeleg() | (1L << 8));  // 用户态系统调用
  w_medeleg(r_medeleg() | (1L << 12)); // 指令页故障
  w_medeleg(r_medeleg() | (1L << 13)); // 加载页故障
  w_medeleg(r_medeleg() | (1L << 15)); // 存储页故障
  
  // 设置 S 模式陷阱向量
  extern void kernelvec(void);
  w_stvec((uint64)kernelvec);
  printf("Set S-modetrap vector\n");
  
  // 使能 S 模式中断
  w_sie(r_sie() | SIE_STIE | SIE_SSIE | SIE_SEIE);
  printf("Enabled S-mode interrupts\n");
  
  // 使能全局中断
  w_sstatus(r_sstatus() | SSTATUS_SIE);
  printf("Enabled global interrupts\n");
  
  // 初始化定时器
  timerinit();
  printf("Timer initalized\n");

  // 调用 trap_init 初始化中断处理
  trap_init();

  // 跳转到 main 函数
  extern void main(void);
  main();
}


