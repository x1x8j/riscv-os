        #
        # 低级代码处理从用户空间到内核的陷阱
        # 以及从内核返回到用户空间的过程。
        #
        # 内核将此代码所在的页面映射到相同的虚拟地址（TRAMPOLINE）
        # 在用户空间和内核空间中，以便在切换页表时继续工作。
        # kernel.ld 会将此代码放置在页面边界上。
        #

#include "riscv.h"
#include "memlayout.h"

.section trampsec
.globl trampoline
.globl usertrap
trampoline:
.align 4
.globl uservec
uservec:    
	#
        # trap.c 会设置 stvec 指向此处，因此
        # 来自用户空间的陷阱从这里开始，
        # 在超级用户模式下，但使用的是
        # 用户页表。
        #

        # 将用户的 a0 保存到 sscratch 寄存器中，
        # 以便 a0 可以用于访问 TRAPFRAME。
        csrw sscratch, a0

        # 每个进程都有一个独立的 p->trapframe 内存区域，
        # 但是它在每个进程的用户页表中
        # 被映射到相同的虚拟地址（TRAPFRAME）。
        li a0, TRAPFRAME
        
        # 将用户的寄存器保存到 TRAPFRAME 中
        sd ra, 40(a0)  # 保存返回地址
        sd sp, 48(a0)  # 保存堆栈指针
        sd gp, 56(a0)  # 保存全局指针
        sd tp, 64(a0)  # 保存线程指针
        sd t0, 72(a0)  # 保存临时寄存器 t0
        sd t1, 80(a0)  # 保存临时寄存器 t1
        sd t2, 88(a0)  # 保存临时寄存器 t2
        sd s0, 96(a0)  # 保存保存寄存器 s0
        sd s1, 104(a0) # 保存保存寄存器 s1
        sd a1, 120(a0) # 保存 a1
        sd a2, 128(a0) # 保存 a2
        sd a3, 136(a0) # 保存 a3
        sd a4, 144(a0) # 保存 a4
        sd a5, 152(a0) # 保存 a5
        sd a6, 160(a0) # 保存 a6
        sd a7, 168(a0) # 保存 a7
        sd s2, 176(a0) # 保存 s2
        sd s3, 184(a0) # 保存 s3
        sd s4, 192(a0) # 保存 s4
        sd s5, 200(a0) # 保存 s5
        sd s6, 208(a0) # 保存 s6
        sd s7, 216(a0) # 保存 s7
        sd s8, 224(a0) # 保存 s8
        sd s9, 232(a0) # 保存 s9
        sd s10, 240(a0) # 保存 s10
        sd s11, 248(a0) # 保存 s11
        sd t3, 256(a0)  # 保存临时寄存器 t3
        sd t4, 264(a0)  # 保存临时寄存器 t4
        sd t5, 272(a0)  # 保存临时寄存器 t5
        sd t6, 280(a0)  # 保存临时寄存器 t6

	# 将用户的 a0 保存到 p->trapframe->a0 中
        csrr t0, sscratch
        sd t0, 112(a0)

        # 初始化内核堆栈指针，从 p->trapframe->kernel_sp 获取
        ld sp, 8(a0)

        # 将线程指针 tp 设置为当前的 hartid，从 p->trapframe->kernel_hartid 获取
        ld tp, 32(a0)

        # 加载 usertrap() 的地址，从 p->trapframe->kernel_trap 获取
        ld t0, 16(a0)

        # 获取内核页表地址，从 p->trapframe->kernel_satp 获取
        ld t1, 0(a0)

        # 等待所有先前的内存操作完成，以便它们使用用户页表
        sfence.vma zero, zero

        # 安装内核页表
        csrw satp, t1

        # 刷新现在已经过时的用户条目
        sfence.vma zero, zero

        # 调用 usertrap()
        jalr t0

.globl userret
userret:
        # usertrap() 返回到这里，a0 中包含用户的 satp。
        # 从内核返回到用户。

        # 切换到用户页表
        sfence.vma zero, zero
        csrw satp, a0
        sfence.vma zero, zero

        li a0, TRAPFRAME

        # 恢复除了 a0 之外的所有寄存器
        ld ra, 40(a0)
        ld sp, 48(a0)
        ld gp, 56(a0)
        ld tp, 64(a0)
        ld t0, 72(a0)
        ld t1, 80(a0)
        ld t2, 88(a0)
        ld s0, 96(a0)
        ld s1, 104(a0)
        ld a1, 120(a0)
        ld a2, 128(a0)
        ld a3, 136(a0)
        ld a4, 144(a0)
        ld a5, 152(a0)
        ld a6, 160(a0)
        ld a7, 168(a0)
        ld s2, 176(a0)
        ld s3, 184(a0)
        ld s4, 192(a0)
        ld s5, 200(a0)
        ld s6, 208(a0)
        ld s7, 216(a0)
        ld s8, 224(a0)
        ld s9, 232(a0)
        ld s10, 240(a0)
        ld s11, 248(a0)
        ld t3, 256(a0)
        ld t4, 264(a0)
        ld t5, 272(a0)
        ld t6, 280(a0)

	# 恢复用户的 a0
        ld a0, 112(a0)
        
        # 返回用户模式和用户程序计数器 (pc)
        # usertrapret() 设置了 sstatus 和 sepc。
        sret

