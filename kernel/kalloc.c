// 物理内存分配器，用于为用户进程、内核栈、页表页和管道缓冲区分配内存。
// 每次分配/释放的单位是完整的 4096 字节物理页。

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

// 预估系统中最大可用物理页数（根据 PHYSTOP 和 end 计算得出）
#define NPAGE 32723

// 声明 freerange 函数：将一段物理内存范围内的所有页释放到空闲链表
void freerange(void *pa_start, void *pa_end);

// 外部变量：end 是内核镜像结束后的第一个地址（由链接脚本 kernel.ld 定义）
extern char end[];

/*
 * 接下来的目标：
 * 确保每个物理页只有在最后一个页表项（PTE）引用消失时才被真正释放（不能提前释放！）。
 * 实现方式：在 kalloc.c 中为每个物理页维护一个引用计数（reference count）。
 */

// 全局数组：记录每个物理页的引用次数
// reference[i] 表示第 i 个可用物理页当前被多少个虚拟地址映射引用
char reference[NPAGE];

// 空闲页链表中的节点结构（每页开头可当作 struct run 使用）
struct run {
    // int ref_count;  // 曾考虑将引用计数嵌入页内，但最终改用外部数组 reference[]
    struct run *next; // 指向下一个空闲页
};

// 内存分配器的全局状态：包含自旋锁和空闲页链表头
struct {
    struct spinlock lock;     // 保护 freelist 的并发访问
    struct run *freelist;     // 空闲物理页组成的单向链表
} kmem;

// 根据物理地址 pa 计算其在 reference 数组中的索引
// 注意：物理页从 PGROUNDUP(end) 开始编号为 0
int
getrefindex(void *pa) {
    // 将 pa 与第一个可用物理页地址做差，再除以页大小，得到页号
    int index = ((char*)pa - (char*)PGROUNDUP((uint64)end)) / PGSIZE;
    return index;
}

// 获取指定物理页 pa 当前的引用计数
int
getref(void *pa) {
    return reference[getrefindex(pa)];
}

// 增加物理页 pa 的引用计数（tip 用于调试日志标识调用位置）
void
addref(char *tip, void *pa) {
    reference[getrefindex(pa)]++; // 引用计数加 1
    // 可选调试输出：
    // printf("%s: addref: %d, pa: %p \n", tip, reference[getrefindex(pa)], pa);
}

// 减少物理页 pa 的引用计数（tip 用于调试日志）
void
subref(char *tip, void *pa) {
    int index = getrefindex(pa);
    // 如果已经是 0，不再减少（防止下溢）
    if (reference[index] == 0)
        return;
    reference[index]--; // 引用计数减 1
    // 可选调试输出：
    // printf("%s: subref: %d, pa: %p \n", tip, reference[index], pa);
}

// 初始化物理内存分配器
void
kinit() {
    // 初始化自旋锁，名称为 "kmem"
    initlock(&kmem.lock, "kmem");
    // 将从 end 到 PHYSTOP 的所有物理内存加入空闲链表
    freerange(end, (void*)PHYSTOP);
}

// 将 [pa_start, pa_end) 范围内的所有完整物理页释放到空闲链表
void
freerange(void *pa_start, void *pa_end) {
    char *p;
    // 从 pa_start 向上对齐到页边界，作为起始地址
    p = (char*)PGROUNDUP((uint64)pa_start);
    // 打印初始化范围（调试用）
    printf("start ~ end:%p ~ %p\n", p, pa_end);

    // 遍历每一页
    for (; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
        // 初始化该页的引用计数为 0（尚未被任何虚拟地址引用）
        reference[getrefindex(p)] = 0;
        // 调用 kfree 将该页加入空闲链表（此时 ref=0，会立即加入）
        kfree(p);
    }
}

// 释放一个物理页 pa
// pa 必须是由 kalloc() 分配的（初始化阶段除外）
void
kfree(void *pa) {
    struct run *r;

    // 安全检查：地址必须页对齐，且在合法物理内存范围内
    if (((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
        panic("kfree");

    // 关键点：每次 kfree 都应减少引用计数（因为很多地方会调用 kfree）
    subref("kfree()", (void *)pa);

    // 获取当前引用计数
    int ref_count = getref(pa);

    // 只有当引用计数降为 0 时，才真正将该页放回空闲链表
    if (ref_count == 0) {
        // 用垃圾值填充页面，便于检测悬空指针（use-after-free）
        memset(pa, 1, PGSIZE);

        r = (struct run*)pa;
        // 加锁保护 freelist
        acquire(&kmem.lock);
        r->next = kmem.freelist;   // 插入到空闲链表头部
        kmem.freelist = r;
        release(&kmem.lock);
    }
    // 如果 ref_count > 0，说明还有其他虚拟地址在使用此页，不能释放
}

// 分配一个 4096 字节的物理页
// 成功返回物理地址，失败返回 0
void *
kalloc(void) {
    struct run *r;

    // 加锁，从空闲链表中取出一页
    acquire(&kmem.lock);
    r = kmem.freelist;
    if (r)
        kmem.freelist = r->next;
    release(&kmem.lock);

    // 如果成功分配到一页
    if (r) {
        // 用垃圾值填充页面，便于检测未初始化内存的使用
        memset((char*)r, 5, PGSIZE);

        // 设置该页的引用计数为 1（因为刚分配，有一个使用者）
        int index = getrefindex((void *)r);
        reference[index] = 1;
    }

    return (void*)r;
}
