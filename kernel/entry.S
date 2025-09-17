.section .text
.global _start
_start:

    li t0, 0x10000000       # UART 基地址（THR寄存器）
    li t1, 'S'              # 启动标记
    sb t1, 0(t0)

    # 设置栈指针
    la sp, stack_top
    li t1, 'P'              # 字符P表示栈已设置
    sb t1, 0(t0)

    # 跳转到C主函数
    call main

spin:
    j spin                  # 死循环


# BSS / 栈空间
.section .bss
    .align 16
stack:
    .space 4096*4           # 16KB栈
stack_top:

