void uart_putc(char c);

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

