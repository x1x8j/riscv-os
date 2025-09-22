int printf(const char *fmt, ...);
void clear_screen(void);
void clear_line(void);
void goto_xy(int x, int y);
void printf_color(int color, const char *s);

void test_printf_basic() {
    printf("Testing integer: %d\n", 42);
    printf("Testing negative: %d\n", -123);
    printf("Testing zero: %d\n", 0);
    printf("Testing hex: 0x%x\n", 0xABC);
    printf("Testing string: %s\n", "Hello");
    printf("Testing char: %c\n", 'X');
    printf("Testing percent: %%\n");
}

void test_printf_edge_cases() {
    printf("INT_MAX: %d\n", 2147483647);
    printf("INT_MIN: %d\n", -2147483648);
    printf("NULL string: %s\n", (char*)0);
    printf("Empty string: %s\n", "");
}

void test_console_features(void) {
    // 清屏
    clear_screen();

    // 输出普通文本
    printf("Hello, this is a test!\n");

    // 光标定位到第 10 行，第 20 列
    goto_xy(20, 10);
    printf("Cursor moved here!\n");

    // 彩色输出
    printf_color(31, "This is red text\n");    // 红色
    printf_color(32, "This is green text\n");  // 绿色
    printf_color(34, "This is blue text\n");   // 蓝色

    // 清除当前行
    goto_xy(0, 12);
    clear_line();
    printf("This line was cleared before!\n");
}


int main() {
    test_printf_basic();
    test_printf_edge_cases();
    test_console_features();
    printf("\n");
    while(1);
    return 0;
}

