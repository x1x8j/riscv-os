// 虚拟内存管理模块
// 实现内核页表、用户页表、页表遍历、映射、释放、复制等核心功能
// 支持写时复制（Copy-on-Write, COW）fork

#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "elf.h"
#include "riscv.h"
#include "defs.h"
#include "spinlock.h"
#include "proc.h"
#include "fs.h"

/*
 * 内核的全局页表（所有 CPU 共享）
 */
pagetable_t kernel_pagetable;

// 外部符号：由链接脚本 kernel.ld 定义，指向内核代码段结束位置
extern char etext[];

// 外部符号：trampoline.S 中定义的 trampoline 页起始地址
extern char trampoline[];

// 构建内核的直接映射页表（物理地址 = 虚拟地址）
pagetable_t
kvmmake(void)
{
  pagetable_t kpgtbl;

  // 分配一页作为顶级页表
  kpgtbl = (pagetable_t) kalloc();
  if (kpgtbl == 0)
    panic("kvmmake: out of memory");
  memset(kpgtbl, 0, PGSIZE); // 清零页表

  // 映射 UART0 寄存器（用于串口通信）
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);

  // 映射 VirtIO 磁盘设备寄存器
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

  // 映射 PLIC（平台级中断控制器），大小为 64MB
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);

  // 映射内核代码段：只读 + 可执行
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);

  // 映射内核数据段和使用的物理内存：可读可写
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);

  // 映射 trampoline 页到最高虚拟地址（供 trap 使用）
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);

  // 为每个进程分配并映射内核栈（在 proc.c 中实现）
  proc_mapstacks(kpgtbl);
  
  return kpgtbl;
}

// 向内核页表添加一个映射（仅在启动时使用）
// 不刷新 TLB，也不开启分页
void
kvmmap(pagetable_t kpgtbl, uint64 va, uint64 pa, uint64 sz, int perm)
{
  if (mappages(kpgtbl, va, sz, pa, perm) != 0)
    panic("kvmmap: out of memory");
}

// 初始化全局内核页表
void
kvminit(void)
{
  kernel_pagetable = kvmmake();
}

// 将当前 CPU 的页表寄存器切换为内核页表，并启用分页
void
kvminithart(void)
{
  // 确保之前的页表写入已完成
  sfence_vma();

  // 写入 satp 寄存器，启用 Sv39 分页模式
  w_satp(MAKE_SATP(kernel_pagetable));

  // 刷新 TLB，清除旧条目
  sfence_vma();
}

// 在页表 pagetable 中查找虚拟地址 va 对应的 PTE（页表项）
// 如果 alloc 非 0，则在需要时分配中间页表页
// 返回指向该 PTE 的指针，失败返回 0
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
  // 检查虚拟地址是否超出用户地址空间上限
  if (va >= MAXVA)
    panic("walk: virtual address too high");

  // RISC-V Sv39 有三级页表（level 2 -> 1 -> 0）
  for (int level = 2; level > 0; level--) {
    // 计算当前 level 的页表索引
    pte_t *pte = &pagetable[PX(level, va)];
    
    if (*pte & PTE_V) {
      // 该页表项有效，跳转到下一级页表
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      // 该页表项无效，若允许分配则创建新页表页
      if (!alloc || (pagetable = (pagetable_t)kalloc()) == 0)
        return 0;
      memset(pagetable, 0, PGSIZE); // 清零新页表
      // 设置当前 PTE 指向新页表页，并标记为有效
      *pte = PA2PTE(pagetable) | PTE_V;
    }
  }
  // 返回最后一级（叶子）PTE 的地址
  return &pagetable[PX(0, va)];
}

// 查找用户虚拟地址 va 对应的物理地址
// 仅用于用户页（必须含 PTE_U 标志）
// 成功返回物理地址，失败返回 0
uint64
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    return 0;

  pte = walk(pagetable, va, 0); // 不分配新页表
  if (pte == 0)
    return 0;
  if ((*pte & PTE_V) == 0) // 页未分配
    return 0;
  if ((*pte & PTE_U) == 0) // 不是用户页
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}

// 为虚拟地址范围 [va, va+size) 建立映射到物理地址 [pa, pa+size)
// va 和 size 必须页对齐
// 成功返回 0，失败返回 -1
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
  uint64 a, last;
  pte_t *pte;

  // 参数校验
  if ((va % PGSIZE) != 0)
    panic("mappages: va not page-aligned");
  if ((size % PGSIZE) != 0)
    panic("mappages: size not page-aligned");
  if (size == 0)
    panic("mappages: zero size");
  
  a = va;
  last = va + size - PGSIZE;
  for (;;) {
    // 获取或创建对应 PTE
    if ((pte = walk(pagetable, a, 1)) == 0)
      return -1;

    // 安全检查：如果 PTE 已存在且有效，且不是 COW 页，则禁止重映射
    // （COW 页允许多次映射，因为父子进程共享）
    if ((*pte & PTE_COW) == 0 && (*pte & PTE_V))
      panic("mappages: attempt to remap non-COW page");

    // 设置新的 PTE：物理地址 + 权限 + 有效位
    *pte = PA2PTE(pa) | perm | PTE_V;

    if (a == last)
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}

// 创建一个空的用户页表
// 成功返回页表指针，失败返回 0
pagetable_t
uvmcreate()
{
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
  if (pagetable == 0)
    return 0;
  memset(pagetable, 0, PGSIZE);
  return pagetable;
}

// 解除从 va 开始的 npages 个页的映射
// 如果 do_free 非 0，则释放对应的物理页
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
  uint64 a;
  pte_t *pte;

  if ((va % PGSIZE) != 0)
    panic("uvmunmap: not aligned");

  for (a = va; a < va + npages * PGSIZE; a += PGSIZE) {
    pte = walk(pagetable, a, 0);
    if (pte == 0) // 页表项不存在
      continue;
    if ((*pte & PTE_V) == 0) // 页未分配
      continue;
    
    if (do_free) {
      uint64 pa = PTE2PA(*pte);
      // 释放物理页（内部会减少引用计数）
      kfree((void*)pa);
    }
    // 清除 PTE
    *pte = 0;
  }
}

// 扩展用户内存：从 oldsz 扩展到 newsz
// xperm 用于指定是否可执行（如代码段）
// 成功返回 new size，失败返回 0
uint64
uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz, int xperm)
{
  char *mem;
  uint64 a;

  if (newsz < oldsz)
    return oldsz;

  oldsz = PGROUNDUP(oldsz);
  for (a = oldsz; a < newsz; a += PGSIZE) {
    mem = kalloc(); // 分配物理页
    if (mem == 0) {
      uvmdealloc(pagetable, a, oldsz); // 回滚已分配的页
      return 0;
    }
    memset(mem, 0, PGSIZE); // 清零
    // 映射到用户地址空间：可读、用户态、可选可执行
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0) {
      kfree(mem);
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
  }
  return newsz;
}

// 缩小用户内存：从 oldsz 缩小到 newsz
// 成功返回 new size
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  if (newsz >= oldsz)
    return oldsz;

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz)) {
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}

// 递归释放页表页（不释放叶子物理页）
// 调用前必须确保所有叶子映射已被移除
void
freewalk(pagetable_t pagetable)
{
  for (int i = 0; i < 512; i++) {
    pte_t pte = pagetable[i];
    // 如果 PTE 有效，且没有 R/W/X 权限，则它指向下一级页表
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0) {
      uint64 child = PTE2PA(pte);
      freewalk((pagetable_t)child); // 递归释放子页表
      pagetable[i] = 0;
    } else if (pte & PTE_V) {
      // 叶子 PTE 未被清除，说明还有物理页未释放
      panic("freewalk: leaf page still mapped");
    }
  }
  kfree((void*)pagetable); // 释放当前页表页
}

// 释放用户进程的所有内存：先释放物理页，再释放页表
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
  if (sz > 0)
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
  freewalk(pagetable);
}

// COW fork 的核心：复制父进程页表到子进程
// 不复制物理内容，而是共享物理页，并标记为 COW
// 成功返回 0，失败返回 -1
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for (i = 0; i < sz; i += PGSIZE) {
    // 获取父进程的 PTE
    if ((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if ((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");

    pa = PTE2PA(*pte);

    // 修改父进程 PTE：清除可写位，设置 COW 标志
    *pte = (*pte & ~PTE_W) | PTE_COW;
    flags = PTE_FLAGS(*pte); // 获取新权限（不含 PTE_W，含 PTE_COW）

    // 子进程直接映射到同一物理地址 pa（不分配新页！）
    if (mappages(new, i, PGSIZE, (uint64)pa, flags) != 0) {
      printf("uvmcopy(): cannot map page\n");
      goto err;
    }

    // 增加该物理页的引用计数（因为现在父子都引用它）
    addref("uvmcopy()", (void*)pa);
  }
  return 0;

err:
  // 出错时回滚：释放子进程已映射的页
  uvmunmap(new, 0, i / PGSIZE, 1);
  return -1;
}

// 将某页标记为不可被用户访问（用于 exec 的栈保护页）
void
uvmclear(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  pte = walk(pagetable, va, 0);
  if (pte == 0)
    panic("uvmclear");
  *pte &= ~PTE_U; // 清除用户访问位
}

// 从内核空间向用户空间复制数据
// 如果目标页是 COW 页，则触发写时复制
// 成功返回 0，失败返回 -1
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;
  pte_t *pte;

  while (len > 0) {
    va0 = PGROUNDDOWN(dstva);
    if (va0 >= MAXVA)
      return -1;

    pte = walk(pagetable, va0, 0);
    if (pte == 0 || (*pte & PTE_V) == 0)
      return -1;

    // 如果是 COW 页，需要先复制
    if (*pte & PTE_COW) {
      char *mem;
      if ((mem = kalloc()) == 0) {
        printf("copyout(): memory allocation failed\n");
        return -1;
      }

      uint64 pa = walkaddr(pagetable, va0);
      if (pa) {
        memmove(mem, (char*)pa, PGSIZE); // 复制原页内容

        // 新权限：可写 + 去掉 COW 标志
        int perm = PTE_FLAGS(*pte);
        perm |= PTE_W;
        perm &= ~PTE_COW;

        // 重新映射 va0 到新页 mem
        if (mappages(pagetable, va0, PGSIZE, (uint64)mem, perm) != 0) {
          printf("copyout(): cannot map new page\n");
          kfree(mem);
          return -1;
        }

        // 释放原物理页（减少引用计数）
        kfree((void*)pa);
      } else {
        kfree(mem);
        return -1;
      }
    }

    // 获取最终物理地址（可能是原页或新复制的页）
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;

    // 复制数据
    n = PGSIZE - (dstva - va0);
    if (n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);

    len -= n;
    src += n;
    dstva = va0 + PGSIZE;
  }
  return 0;
}

// 从用户空间向内核空间复制数据
// 支持懒加载（lazy allocation）：如果页未分配，调用 vmfault 分配
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0) {
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0) {
      // 页未分配，尝试懒加载
      if ((pa0 = vmfault(pagetable, va0, 0)) == 0) {
        return -1;
      }
    }
    n = PGSIZE - (srcva - va0);
    if (n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);

    len -= n;
    dst += n;
    srcva = va0 + PGSIZE;
  }
  return 0;
}

// 从用户空间复制一个以 '\0' 结尾的字符串到内核
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0) {
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    if (n > max)
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while (n > 0) {
      if (*p == '\0') {
        *dst = '\0';
        got_null = 1;
        break;
      } else {
        *dst = *p;
      }
      --n;
      --max;
      p++;
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  return got_null ? 0 : -1;
}

// 懒加载支持：当访问未分配的堆页时，动态分配物理页
// 用于 sys_sbrk()
uint64
vmfault(pagetable_t pagetable, uint64 va, int read)
{
  uint64 mem;
  struct proc *p = myproc();

  if (va >= p->sz) // 超出进程内存大小
    return 0;
  va = PGROUNDDOWN(va);
  if (ismapped(pagetable, va)) // 已映射
    return 0;

  mem = (uint64) kalloc();
  if (mem == 0)
    return 0;
  memset((void *) mem, 0, PGSIZE);
  if (mappages(p->pagetable, va, PGSIZE, mem, PTE_W | PTE_U | PTE_R) != 0) {
    kfree((void *)mem);
    return 0;
  }
  return mem;
}

// 检查虚拟地址是否已被映射
int
ismapped(pagetable_t pagetable, uint64 va)
{
  pte_t *pte = walk(pagetable, va, 0);
  if (pte == 0) {
    return 0;
  }
  if (*pte & PTE_V) {
    return 1;
  }
  return 0;
}
