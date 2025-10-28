#include "types.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"

void main();
void timerinit();

// 定义一块对齐的内存区域，用于 CPU 的栈。
__attribute__ ((aligned (16))) char stack0[4096];


void
start()
{
  // 设置 M 模式的 Privilege Mode（特权模式），切换到 S 模式（超级用户模式）
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;
  x |= MSTATUS_MPP_S;
  w_mstatus(x);
  // 将机器模式下的异常程序计数器（mepc）设置为 main 函数的地址。
  w_mepc((uint64)main);
  // 禁用分页（物理内存地址映射）
  w_satp(0);
  // 委托异常和中断到 S 模式（超级用户模式）
  w_medeleg(0xffff);
  w_mideleg(0xffff);
  // 启用 S 模式下的外部中断（SEIE）和定时器中断（STIE）
  w_sie(r_sie() | SIE_SEIE | SIE_STIE);
  // 配置物理内存保护（PMP），允许 S 模式访问所有物理内存
  w_pmpaddr0(0x3fffffffffffffull);
  w_pmpcfg0(0xf);

  timerinit();

  uint64 stack_top = (uint64)(stack0 + 4096);
  w_sscratch(stack_top);
  // 使用 mret 跳转到超级用户模式，并开始执行 main 函数
  asm volatile("mret");
}


void
timerinit()
{
  // 1. 启用超级用户模式的定时器中断
  w_mie(r_mie() | MIE_STIE);
  // 2. 启用 SSTC 扩展（启用定时器比较功能）
  w_menvcfg(r_menvcfg() | (1L << 63)); 
  // 3. 允许使用计数器和时间比较
  w_mcounteren(r_mcounteren() | 2);
  // 4. 设置第一个定时器中断
  w_stimecmp(r_time() + 1000000);
}
