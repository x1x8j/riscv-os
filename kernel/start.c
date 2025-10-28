#include "types.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"

void main();
void timerinit();

__attribute__ ((aligned (16))) char stack0[4096];


void
start()
{
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;
  x |= MSTATUS_MPP_S;
  w_mstatus(x);

  w_mepc((uint64)main);

  w_satp(0);

  w_medeleg(0xffff);
  w_mideleg(0xffff);
  w_sie(r_sie() | SIE_SEIE | SIE_STIE);

  w_pmpaddr0(0x3fffffffffffffull);
  w_pmpcfg0(0xf);


  timerinit();

  int id = 0;
  w_tp(id);

  __asm__ volatile("csrr %0, mhartid" : "=r"(id));
  uint64 stack_top = (uint64)(stack0 + (id + 1) * 4096);
  w_sscratch(stack_top);

  asm volatile("mret");
}


void
timerinit()
{
  w_mie(r_mie() | MIE_STIE);
  
  w_menvcfg(r_menvcfg() | (1L << 63)); 
  
  w_mcounteren(r_mcounteren() | 2);

  w_stimecmp(r_time() + 1000000);
}
