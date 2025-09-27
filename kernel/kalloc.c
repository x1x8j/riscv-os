#include "riscv.h"
#include "defs.h"
#include "types.h"
#include "memlayout.h"

extern char end[];   // 由 kernel.ld 提供，内核末尾地址


// 空闲页链表节点
struct run {
    struct run *next;
};

// freelist 头指针
static struct run *freelist;

// kfree: 将一页放回 freelist
void kfree(void *pa) {
    if (((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
        panic("kfree: invalid pa");

    // 填充垃圾数据，帮助捕捉 bug
    memset(pa, 1, PGSIZE);

    struct run *r = (struct run*)pa;
    r->next = freelist;
    freelist = r;
}

// kalloc: 分配一页
void* kalloc(void) {
    struct run *r = freelist;
    if (r) {
        freelist = r->next;
        memset((char*)r, 5, PGSIZE); // 填充垃圾数据
        return (void*)r;
    }
    return 0;
}

// 初始化物理内存分配器
void kinit(void) {
    char *p = (char*)PGROUNDUP((uint64)end);
    for (; p + PGSIZE <= (char*)PHYSTOP; p += PGSIZE) {
        kfree(p);
    }
}

