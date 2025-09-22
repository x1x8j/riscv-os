#include<stdarg.h>

void uart_putc(char c);
void uart_puts(const char *s);

// 单字符输出
void console_putc(char c) {
    uart_putc(c);
}

// 输出字符串
void console_puts(const char *s) {
    for(; *s; s++)
        console_putc(*s);
}

// 初始化 console（这里不需要锁）
void console_init(void) {
    // 空函数
}

// 清屏，光标回左上角
void clear_screen(void) {
    uart_puts("\033[2J\033[H");
}

// 清除当前行
void clear_line(void) {
    uart_puts("\033[K");
}

void goto_xy(int x, int y) {
    console_putc('\033');
    console_putc('[');

    if (y >= 10) console_putc('0' + y/10);
    console_putc('0' + y%10);

    console_putc(';');

    if (x >= 10) console_putc('0' + x/10);
    console_putc('0' + x%10);

    console_putc('H');
}


void printf_color(int color, const char *s) {
    console_putc('\033');
    console_putc('[');
    if (color >= 10) console_putc('0' + color/10);
    console_putc('0' + color%10);
    console_putc('m');

    // 输出字符串
    for (int i=0; s[i]; i++)
        console_putc(s[i]);

    uart_puts("\033[0m"); // 复位颜色
}
