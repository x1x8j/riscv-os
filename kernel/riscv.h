#include"types.h"
#define PGSIZE 4096
#define PGROUNDUP(sz)  (((sz)+PGSIZE-1) & ~(PGSIZE-1))
#define PGROUNDDOWN(a) (((a)) & ~(PGSIZE-1))

// 页表项标志位
#define PTE_V (1L << 0) // 有效
#define PTE_R (1L << 1)
#define PTE_W (1L << 2)
#define PTE_X (1L << 3)
#define PTE_U (1L << 4)

// 从 PTE 提取物理地址
#define PTE2PA(pte)  (((pte) >> 10) << 12)
#define PA2PTE(pa)   (((uint64)(pa) >> 12) << 10)

// Sv39 地址解析
#define PXSHIFT(level)  (12 + (9 * (level)))
#define PX(level, va)   ((((uint64) (va)) >> PXSHIFT(level)) & 0x1FF)

// 写 satp
static inline void w_satp(uint64 x) {
  asm volatile("csrw satp, %0" : : "r"(x));
}

// 刷新 TLB
static inline void sfence_vma() {
  asm volatile("sfence.vma zero, zero");
}

