#include "riscv.h"
#include "defs.h"
#include "assert.h"

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

    // 测试映射
    uint64 va = 0x4000;                // 任意虚拟地址
    uint64 pa = (uint64)kalloc();      // 分配物理页
    assert(pa != 0);

    assert(mappages(pt, va, pa, PTE_R | PTE_W) == 0);

    // 查找 PTE
    pte_t *pte = walk(pt, va, 0);
    assert(pte && (*pte & PTE_V));
    assert(PTE2PA(*pte) == pa);

    // 测试权限位
    assert(*pte & PTE_R);
    assert(*pte & PTE_W);
    assert(!(*pte & PTE_X));

    printf("Page table mapping test passed!\n");
}

// 3. 虚拟内存激活测试
void test_virtual_memory(void) {
    printf("== Virtual memory test ==\n");

    // 初始化内核页表
    kvminit();

    // 手动检查关键映射（内核数据、UART等）
    // 注意：map_region 在 kvminit 里已经做了
    // 这里主要是提醒你做检查点：
    //   1. 内核代码是否映射 (R+X)
    //   2. 内核数据是否映射 (R+W)
    //   3. 栈是否映射
    //   4. UART 是否映射

    kvminithart(); // 激活内核页表
    printf("Paging enabled, continuing kernel execution...\n");

    // 测试设备访问：输出一个字符
    console_putc('X');

    printf("\nVirtual memory test passed!\n");
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

    while(1) { }
}

