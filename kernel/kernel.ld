ENTRY(_start)

SECTIONS
{
    . = 0x80000000;         /* 内核加载起始地址 */

    /* 代码段 */
    .text : ALIGN(16) {
        *(.text*)
    }

    /* 只读数据段靠近代码 */
    .rodata : ALIGN(16) {
        *(.rodata*)
    }

    /* 已初始化数据段 */
    .data : ALIGN(16) {
        *(.data*)
    }

    /* 未初始化数据段 */
    .bss : ALIGN(16) {
        *(.bss*)
    }

    PROVIDE(end = .);       /* 定义内核结束符号 */
}

