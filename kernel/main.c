#include "riscv.h"
#include "defs.h"
#include "assert.h"
#include "memlayout.h"
// 1. 物理内存分配器测试
void test_physical_memory(void) {
    printf("== Memory allocator test ==\n");

    void *p1 = kalloc();
    void *p2 = kalloc();
    assert(p1 != p2);
    assert(((uint64)p1 & 0xFFF) == 0); // 页对齐检查

    // 测试写入和读取
    *(int*)p1 = 0x12345678;
    assert(*(int*)p1 == 0x12345678);

    // 释放再分配
    kfree(p1);
    void *p3 = kalloc();
    assert(p3 != 0);   // p3 可能等于 p1（取决分配策略）

    kfree(p2);
    kfree(p3);

    printf("Memory allocator test passed!\n");
}

// 2. 页表功能测试
void test_pagetable(void) {
    printf("== Page table mapping test ==\n");

    // 分配根页表
    pagetable_t pt = (pagetable_t)kalloc();
    memset(pt, 0, PGSIZE);

    // 单页映射测试
    uint64 va = 0x4000;                // 任意虚拟地址
    uint64 pa = (uint64)kalloc();      // 分配物理页
    assert(pa != 0);

    assert(mappages(pt, va, pa, PGSIZE, PTE_R | PTE_W) == 0);

    // 检查单页映射
    pte_t *pte = walk(pt, va, 0);
    assert(pte && (*pte & PTE_V));
    assert(PTE2PA(*pte) == pa);
    assert(*pte & PTE_R);
    assert(*pte & PTE_W);
    assert(!(*pte & PTE_X));
    printf("Single page: VA 0x%lx -> PA 0x%lx, PTE=0x%lx\n", va, pa, *pte);

    // 多页映射测试
    for(int i = 1; i <= 2; i++){
        uint64 v = va + i*PGSIZE;
        uint64 p = (uint64)kalloc();
        assert(p != 0);

        int ret = mappages(pt, v, p, PGSIZE, PTE_R|PTE_W);
        assert(ret == 0);

        pte_t *p_multi = walk(pt, v, 0);
        assert(p_multi && (*p_multi & PTE_V));
        assert(PTE2PA(*p_multi) == p);
        assert(*p_multi & PTE_R);
        assert(*p_multi & PTE_W);
        printf("Multi-page: VA 0x%lx -> PA 0x%lx, PTE=0x%lx\n", v, p, *p_multi);
    }

    // 重复映射测试（应该失败）
    int ret = mappages(pt, va, pa, PGSIZE, PTE_R|PTE_W);
    assert(ret == -1);
    printf("Duplicate mapping correctly rejected.\n");

    // 权限组合测试（只读/只执行/只写）
    uint64 test_va = 0x8000;
    uint64 test_pa = (uint64)kalloc();
    assert(test_pa != 0);

    ret = mappages(pt, test_va, PGSIZE, test_pa, PTE_R | PTE_X);
    assert(ret == 0);
    pte_t *pte_perm = walk(pt, test_va, 0);
    assert(pte_perm && (*pte_perm & PTE_V));
    assert(*pte_perm & PTE_R);
    assert(*pte_perm & PTE_X);
    assert(!(*pte_perm & PTE_W));
    printf("Permission test: VA 0x%lx -> PA 0x%lx, PTE=0x%lx\n", test_va, test_pa, *pte_perm);

    printf("Page table mapping test passed!\n");
}


extern pagetable_t kernel_pagetable;
extern char etext[]; 
void test_virtual_memory(void) {
    printf("== Virtual memory test ==\n");

    // 1. 初始化内核页表
    kvminit();

    // 2. 激活页表
    kvminithart();
    printf("Paging enabled.\n");

    // 3. 静态检查关键映射
    pte_t *pte;

    // 内核代码段 R+X
    pte = walk(kernel_pagetable, KERNBASE, 0);
    assert(pte && (*pte & PTE_V) && (*pte & PTE_X));
    printf("Kernel code mapping OK: VA 0x%lx -> PA 0x%lx\n", KERNBASE, PTE2PA(*pte));

    // 内核数据段 R+W
    pte = walk(kernel_pagetable, KERNBASE + (uint64)etext, 0);
    assert(pte && (*pte & PTE_V) && (*pte & PTE_W));
    printf("Kernel data mapping OK: VA 0x%lx -> PA 0x%lx\n", (uint64)etext, PTE2PA(*pte));

    // UART 映射
    pte = walk(kernel_pagetable, UART0, 0);
    assert(pte && (*pte & PTE_V) && (*pte & PTE_W));
    printf("UART mapping OK: VA 0x%lx -> PA 0x%lx\n", UART0, PTE2PA(*pte));

    // 4. 动态测试内核代码可执行性
    printf("Kernel code execution test: ");
    console_putc('C'); 
    printf("\nKernel code execution test passed.\n");

  
    // 5. 测试内核数据读写
    volatile uint64 *data_test = (uint64 *)(KERNBASE + 0x1000);
    *data_test = 0x12345678ABCDEF00ULL;
    assert(*data_test == 0x12345678ABCDEF00ULL);
    printf("Kernel data read/write test passed.\n");

    // 6. 测试设备访问（UART 输出）
    console_putc('X');
    printf("\nUART output test passed.\n");

 
    printf("Virtual memory test completed successfully.\n");
}


   
// 主函数
void main(void) {
    printf("Kernel starting...\n");

    // 初始化物理内存分配器
    kinit();

    // 分层测试
    test_physical_memory();
    test_pagetable();
    test_virtual_memory();

    printf("All tests completed!\n");

    while(1);

}

