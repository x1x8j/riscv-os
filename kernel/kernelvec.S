.globl kernelvec
.align 4
kernelvec:
    # 切换到内核栈
    csrw sscratch, sp         # 将当前栈指针保存在 sscratch
    csrr sp, sscratch         # 从 sscratch 恢复栈指针，切换到内核栈

    # 保存 ra 和 s0 寄存器
    addi sp, sp, -256         # 为保存寄存器分配空间
    sd ra, 0(sp)              # 保存 ra 寄存器
    sd s0, 8(sp)              # 保存 s0 寄存器

    # 保存调用者保存的寄存器（t0 - t6 和 a0 - a7）
    sd t0, 16(sp)             # 保存 t0
    sd t1, 24(sp)             # 保存 t1
    sd t2, 32(sp)             # 保存 t2
    sd t3, 40(sp)             # 保存 t3
    sd t4, 48(sp)             # 保存 t4
    sd t5, 56(sp)             # 保存 t5
    sd t6, 64(sp)             # 保存 t6
    sd a0, 72(sp)             # 保存 a0
    sd a1, 80(sp)             # 保存 a1
    sd a2, 88(sp)             # 保存 a2
    sd a3, 96(sp)             # 保存 a3
    sd a4, 104(sp)            # 保存 a4
    sd a5, 112(sp)            # 保存 a5
    sd a6, 120(sp)            # 保存 a6
    sd a7, 128(sp)            # 保存 a7

    # 调用 C 函数 kerneltrap 处理中断
    call kerneltrap           # 调用 C 函数处理异常或中断

    # 恢复寄存器
    ld ra, 0(sp)              # 恢复 ra 寄存器
    ld s0, 8(sp)              # 恢复 s0 寄存器
    ld t0, 16(sp)             # 恢复 t0
    ld t1, 24(sp)             # 恢复 t1
    ld t2, 32(sp)             # 恢复 t2
    ld t3, 40(sp)             # 恢复 t3
    ld t4, 48(sp)             # 恢复 t4
    ld t5, 56(sp)             # 恢复 t5
    ld t6, 64(sp)             # 恢复 t6
    ld a0, 72(sp)             # 恢复 a0
    ld a1, 80(sp)             # 恢复 a1
    ld a2, 88(sp)             # 恢复 a2
    ld a3, 96(sp)             # 恢复 a3
    ld a4, 104(sp)            # 恢复 a4
    ld a5, 112(sp)            # 恢复 a5
    ld a6, 120(sp)            # 恢复 a6
    ld a7, 128(sp)            # 恢复 a7

    # 恢复栈指针
    addi sp, sp, 256          # 恢复栈指针

    # 恢复 sp
    csrw sscratch, sp
    csrr sp, sscratch

    # 恢复到用户模式
    sret                      # 执行 sret 返回到用户模式

