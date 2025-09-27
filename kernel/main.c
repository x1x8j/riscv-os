#include "riscv.h"
#include "defs.h"
#include "assert.h"

void test_physical_memory(void) {
    printf("== Memory allocator test ==\n");

    void *p1 = kalloc();
    void *p2 = kalloc();
    assert(p1 != p2);
    assert(((uint64)p1 & 0xFFF) == 0); // page alignment check

    *(int*)p1 = 0x12345678;
    assert(*(int*)p1 == 0x12345678);

    printf("Memory allocator test passed!\n");
}

void test_pagetable(void) {
    printf("== Page table mapping test ==\n");

    pagetable_t pt = (pagetable_t)kalloc();
    memset(pt, 0, PGSIZE);

    uint64 va = 0x4000;
    uint64 pa = (uint64)kalloc();
    assert(mappages(pt, va, pa, PTE_R | PTE_W) == 0);

    pte_t *pte = walk(pt, va, 0);
    assert(pte && (*pte & PTE_V));
    assert(PTE2PA(*pte) == pa);
    assert(*pte & PTE_R);
    assert(*pte & PTE_W);

    printf("Page table mapping test passed!\n");
}

void test_virtual_memory(void) {
    printf("== Virtual memory test ==\n");

    kvminit();
    kvminithart();

    printf("Paging enabled, continuing kernel execution...\n");
}

void main(void) {
    printf("Kernel starting...\n");

    kinit();  // initialize physical memory allocator

    test_physical_memory();
    test_pagetable();
    test_virtual_memory();

    printf("All tests completed!\n");

    while(1) { }
}

