#include "riscv.h"
#include "defs.h"

pte_t* walk(pagetable_t pagetable, uint64 va, int alloc) {
  if(va >= (1L << 39)) return 0;  // Sv39 只支持 39 位 VA

  for(int level = 2; level > 0; level--) {
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc) return 0;
      void *newpage = kalloc();
      if(newpage == 0) return 0;
      memset(newpage, 0, PGSIZE);
      *pte = PA2PTE(newpage) | PTE_V;
      pagetable = (pagetable_t)newpage;
    }
  }
  return &pagetable[PX(0, va)];
}

int mappages(pagetable_t pagetable, uint64 va, uint64 pa, int perm) {
  va = PGROUNDDOWN(va);
  pa = PGROUNDDOWN(pa);
  pte_t *pte = walk(pagetable, va, 1);
  if(pte == 0) return -1;
  if(*pte & PTE_V) return -1; // 已经映射
  *pte = PA2PTE(pa) | perm | PTE_V;
  return 0;
}

void dump_pagetable(pagetable_t pagetable, int level) {
  for(int i = 0; i < 512; i++) {
    pte_t pte = pagetable[i];
    if(pte & PTE_V) {
      printf("%*s[%d] pte=%p pa=%p\n", level*2, "",
             i, pte, PTE2PA(pte));
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
        dump_pagetable((pagetable_t)PTE2PA(pte), level+1);
      }
    }
  }
}

// 内核页表
pagetable_t kernel_pagetable;

void kvminit(void) {
  kernel_pagetable = (pagetable_t)kalloc();
  memset(kernel_pagetable, 0, PGSIZE);

  // 映射 UART0 示例
  mappages(kernel_pagetable, 0x10000000, 0x10000000, PTE_R|PTE_W);
}

void kvminithart(void) {
  w_satp(((uint64)kernel_pagetable >> 12) | (8L << 60)); // MODE=Sv39
  sfence_vma();
}

