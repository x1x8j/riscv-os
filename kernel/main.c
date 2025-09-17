extern void uart_puts(const char *);

void main() {
    uart_puts("Hello OS\n");  // 输出字符串

    while(1); // 死循环，防止程序返回导致 QEMU 重启
}

