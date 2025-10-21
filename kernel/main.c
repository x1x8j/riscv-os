#include "riscv.h"
#include "defs.h"
#include "assert.h"
#include "memlayout.h"

extern uint64 ticks;
extern pagetable_t kernel_pagetable;
extern char etext[]; 
extern void kernelvec(void);

   
// 主函数

void main(void) {
    printf("Kernel starting...\n");

    // 初始化物理内存分配器
//    kinit();
    // 初始化中断处理
    trap_init();
    
    printf("\n=== 中断功能测试 ===\n");
    
    // 检查中断状态
    printf("SIE=0x%lx, SIP=0x%lx, SSTATUS=0x%lx\n", r_sie(), r_sip(), r_sstatus());
    printf("STIE=%d, SIE=%d, Time=%lu\n", 
           (r_sie() & SIE_STIE) ? 1 : 0,
           (r_sstatus() & SSTATUS_SIE) ? 1 : 0,
           get_time());
    
    // 在 main() 中，初始化后加：
    printf("kernelvec = %p\n", kernelvec);
    printf("stvec     = %p\n", r_stvec());
    printf("SIE       = 0x%lx\n", r_sie());
    printf("SSTATUS   = 0x%lx\n", r_sstatus());
   
    printf("=== Time Monitor: Checking if mtime increases ===\n");
for (int i = 0; i < 10; i++) {
  uint64 t = get_time();
  printf("  t[%d] = %lu\n", i, t);
  // 延迟一小会儿，让时间有机会增长
  for (volatile int j = 0; j < 200000; j++) {}
}
printf("=== End of Time Monitor ===\n");

    // 1. 测试时钟中断
    test_timer_interrupt();
    
    // 如果时钟中断不工作，尝试手动触发中断测试
    if (ticks == 0) {
        printf("Timer interrupts not working, trying manual interrupt test...\n");
        
        // 手动设置一个软件中断来测试中断处理机制
        printf("Setting software interrupt...\n");
        w_sip(r_sip() | SIP_SSIP);
        printf("SIP after setting: 0x%lx\n", r_sip());
        
        // 等待一下看是否有中断
        for (volatile int i = 0; i < 1000000; i++);
        printf("After waiting, ticks: %lu\n", ticks);
        
        printf("Timer interrupts not working, skipping other tests\n");
        printf("All tests completed!\n");
        while(1);
    }
    
    // 2. 测试异常处理
    test_exception_handling();
    
    // 3. 测试中断性能开销
    test_interrupt_overhead();

    printf("All tests completed!\n");

    while(1);

}


