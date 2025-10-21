# kernelvec.S
.globl kernelvec
.align 4
kernelvec:
    # 切换到内核栈
    csrw sscratch, sp
    csrr sp, sscratch

    # 保存 ra 和 s0
    addi sp, sp, -16
    sd   ra, 8(sp)
    sd   s0, 0(sp)

    # 调用 C 函数
    call kerneltrap

    # 恢复寄存器
    ld   ra, 8(sp)
    ld   s0, 0(sp)
    addi sp, sp, 16

    # 恢复 sp
    csrw sscratch, sp
    csrr sp, sscratch

    # 返回
    sret
