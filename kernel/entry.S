.section .text
.global _start
.extern stack0
_start:

//    li t0, 0x10000000       # UART 基地址（THR寄存器）
//    li t1, 'S'              # 启动标记
//    sb t1, 0(t0)

    # 设置栈指针
    la sp, stack0+4096
//    li t1, 'P'              # 字符P表示栈已设置
//    sb t1, 0(t0)

//    # 跳转到C主函数
//    call main
    # 跳转到start函数进行机器模式初始化
    call start
spin:
    j spin                  # 死循环




