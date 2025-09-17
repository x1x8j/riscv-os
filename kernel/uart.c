typedef unsigned char uchar;

#define UART0 0x10000000
#define THR  ((volatile uchar *)(UART0 + 0))  // Transmit Holding Register
#define LSR  ((volatile uchar *)(UART0 + 5))  // Line Status Register
#define LSR_THRE 0x20  // Transmit Holding Register Empty

// 输出一个字符
void uart_putc(char c) {
    while ((*LSR & LSR_THRE) == 0); // 等待 THR 空
    *THR = c;
}

// 输出字符串
void uart_puts(const char *s) {
    for (int i = 0; s[i] != '\0'; i++) {
        uart_putc(s[i]);
    }
}

