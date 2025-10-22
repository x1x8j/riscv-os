#include "types.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"

// 全局变量用于中断计数（需在中断处理函数中访问）
volatile int timer_interrupt_count = 0;
//volatile int timer_done = 0;
// 声明测试函数
void test_timer_interrupt(void);
void trapinithart(void); 

void main() {
    // 初始化陷阱处理（设置中断向量）
    trapinithart();
    
    // 启动中断测试
    test_timer_interrupt();
    
    // 测试完成后进入循环
    printf("All tests completed. Entering idle loop.\n");
    while (1) {
        // 等待中断
        w_sstatus(r_sstatus() | SSTATUS_SIE);  // 确保中断使能
        asm volatile("wfi");  // 等待中断指令，降低CPU占用
    }
}

void test_timer_interrupt(void) {
    printf("Starting timer interrupt test...\n");

    // 1. 开启 M 模式的全局中断
//    w_mstatus(r_mstatus() | MSTATUS_MIE);

    // 2. 委托 S 模式定时器中断到 S 模式
//    w_mideleg(r_mideleg() | (1UL << 5));  // STIE

    // 3. 开启 S 模式的定时器中断和全局中断
    w_sie(r_sie() | SIE_STIE);
    w_sstatus(r_sstatus() | SSTATUS_SIE);

    // 4. 设置第一次定时器中断
    uint64 now = r_time();
    w_stimecmp(now + 1000000);  // 1M 周期后触发

    // 5. 重置计数
    timer_interrupt_count = 0;

    // 6. 等待中断
    // 等待10次中断完成（循环等待标志位）
    while(timer_interrupt_count<10);

    // 7. 记录时间
    uint64 end_time = r_time();
    uint64 total_cycles = end_time - now;
    uint64 avg_cycles = total_cycles/10;

    printf("=== Timer interrupt test completed ===\n");
    printf("Total interrupts: %d\n", timer_interrupt_count);
    printf("Total cycles: %lu\n", total_cycles);
    printf("Average interval: %lu cycles\n", avg_cycles);
    printf("Expected: ~1000000 cycles\n");
}

