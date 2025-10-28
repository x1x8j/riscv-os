.globl kernelvec
.align 4
kernelvec:
    # 切换到内核栈
    csrw sscratch, sp        
    csrr sp, sscratch         # 从 sscratch 恢复栈指针，切换到内核栈

    # 保存 ra 和 s0 寄存器
    addi sp, sp, -256         # 为保存寄存器分配空间
    sd ra, 0(sp)              # 保存 ra 寄存器
    sd s0, 8(sp)              # 保存 s0 寄存器

    # 保存调用者保存的寄存器（t0 - t6 和 a0 - a7）
    sd t0, 16(sp)            
    sd t1, 24(sp)           
    sd t2, 32(sp)             
    sd t3, 40(sp)             
    sd t4, 48(sp)           
    sd t5, 56(sp)        
    sd t6, 64(sp)            
    sd a0, 72(sp)          
    sd a1, 80(sp)            
    sd a2, 88(sp)            
    sd a3, 96(sp)             
    sd a4, 104(sp)            
    sd a5, 112(sp)           
    sd a6, 120(sp)            
    sd a7, 128(sp)            

    call kerneltrap           # 调用 C 函数处理异常或中断

    # 恢复寄存器
    ld ra, 0(sp)             
    ld s0, 8(sp)             
    ld t0, 16(sp)            
    ld t1, 24(sp)            
    ld t2, 32(sp)            
    ld t3, 40(sp)            
    ld t4, 48(sp)            
    ld t5, 56(sp)            
    ld t6, 64(sp)           
    ld a0, 72(sp)     
    ld a1, 80(sp)            
    ld a2, 88(sp)             
    ld a3, 96(sp)            
    ld a4, 104(sp)           
    ld a5, 112(sp)          
    ld a6, 120(sp)           
    ld a7, 128(sp)         

    # 恢复栈指针
    addi sp, sp, 256    

    # 恢复 sp
    csrw sscratch, sp
    csrr sp, sscratch

    sret                    

