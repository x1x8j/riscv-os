# 上下文切换
#   void swtch(struct context *old, struct context *new);
# 保存当前寄存器到 old，然后从 new 加载寄存器。

.globl swtch
swtch:
        # 保存当前的寄存器到 old 中
        sd ra, 0(a0)   # 保存返回地址寄存器 ra
        sd sp, 8(a0)   # 保存栈指针寄存器 sp
        sd s0, 16(a0)  # 保存寄存器 s0
        sd s1, 24(a0)  # 保存寄存器 s1
        sd s2, 32(a0)  # 保存寄存器 s2
        sd s3, 40(a0)  # 保存寄存器 s3
        sd s4, 48(a0)  # 保存寄存器 s4
        sd s5, 56(a0)  # 保存寄存器 s5
        sd s6, 64(a0)  # 保存寄存器 s6
        sd s7, 72(a0)  # 保存寄存器 s7
        sd s8, 80(a0)  # 保存寄存器 s8
        sd s9, 88(a0)  # 保存寄存器 s9
        sd s10, 96(a0) # 保存寄存器 s10
        sd s11, 104(a0)# 保存寄存器 s11

        # 从 new 加载寄存器
        ld ra, 0(a1)   # 加载返回地址寄存器 ra
        ld sp, 8(a1)   # 加载栈指针寄存器 sp
        ld s0, 16(a1)  # 加载寄存器 s0
        ld s1, 24(a1)  # 加载寄存器 s1
        ld s2, 32(a1)  # 加载寄存器 s2
        ld s3, 40(a1)  # 加载寄存器 s3
        ld s4, 48(a1)  # 加载寄存器 s4
        ld s5, 56(a1)  # 加载寄存器 s5
        ld s6, 64(a1)  # 加载寄存器 s6
        ld s7, 72(a1)  # 加载寄存器 s7
        ld s8, 80(a1)  # 加载寄存器 s8
        ld s9, 88(a1)  # 加载寄存器 s9
        ld s10, 96(a1) # 加载寄存器 s10
        ld s11, 104(a1)# 加载寄存器 s11

        ret             # 返回，完成上下文切换

