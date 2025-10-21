# 内核陷阱向量入口
# 保存/恢复寄存器，调用 kerneltrap()

.section .text
.globl kernelvec
.align 4

.set UART0, 0x10000000
.set UART_THR, 0
kernelvec:

    # 🔥 调试：输出 'K'，证明进入中断
    li t0, UART0
    li t1, 'K'
    sw t1, UART_THR(t0)   # 向串口发送字符 'K'
    # 保存所有寄存器到 trapframe
    addi sp, sp, -256
    sd ra, 0(sp)
    sd sp, 8(sp)
    sd gp, 16(sp)
    sd tp, 24(sp)
    sd t0, 32(sp)
    sd t1, 40(sp)
    sd t2, 48(sp)
    sd s0, 56(sp)
    sd s1, 64(sp)
    sd a0, 72(sp)
    sd a1, 80(sp)
    sd a2, 88(sp)
    sd a3, 96(sp)
    sd a4, 104(sp)
    sd a5, 112(sp)
    sd a6, 120(sp)
    sd a7, 128(sp)
    sd s2, 136(sp)
    sd s3, 144(sp)
    sd s4, 152(sp)
    sd s5, 160(sp)
    sd s6, 168(sp)
    sd s7, 176(sp)
    sd s8, 184(sp)
    sd s9, 192(sp)
    sd s10, 200(sp)
    sd s11, 208(sp)
    sd t3, 216(sp)
    sd t4, 224(sp)
    sd t5, 232(sp)
    sd t6, 240(sp)

    # 保存 CSR 寄存器
//    csrr t0, sepc
//    csrr t1, sstatus
//    sd t0, 248(sp)
//    sd t1, 256(sp)

    # 调用 C 处理函数
//    mv a0, sp
    call kerneltrap

    # 恢复 CSR 寄存器
//    ld t0, 248(sp)
//    ld t1, 256(sp)
//    csrw sepc, t0
//    csrw sstatus, t1

    # 恢复所有寄存器
    ld ra, 0(sp)
    ld sp, 8(sp)
    ld gp, 16(sp)
    ld tp, 24(sp)
    ld t0, 32(sp)
    ld t1, 40(sp)
    ld t2, 48(sp)
    ld s0, 56(sp)
    ld s1, 64(sp)
    ld a0, 72(sp)
    ld a1, 80(sp)
    ld a2, 88(sp)
    ld a3, 96(sp)
    ld a4, 104(sp)
    ld a5, 112(sp)
    ld a6, 120(sp)
    ld a7, 128(sp)
    ld s2, 136(sp)
    ld s3, 144(sp)
    ld s4, 152(sp)
    ld s5, 160(sp)
    ld s6, 168(sp)
    ld s7, 176(sp)
    ld s8, 184(sp)
    ld s9, 192(sp)
    ld s10, 200(sp)
    ld s11, 208(sp)
    ld t3, 216(sp)
    ld t4, 224(sp)
    ld t5, 232(sp)
    ld t6, 240(sp)
    addi sp, sp, 256

    sret

