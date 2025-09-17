ENTRY(_start)

SECTIONS
{
    . = 0x80000000;         /* 内核加载起始地址 */

    .text : {
        *(.text*)           /* 所有代码段 */
    }

    .rodata : {
        *(.rodata*)         /* 只读数据 */
    }

    .data : {
        *(.data*)           /* 已初始化数据 */
    }

    .bss : {
        *(.bss*)            /* 未初始化数据 */
    }

    PROVIDE(end = .);       /* 定义内核结束符号 */
}

