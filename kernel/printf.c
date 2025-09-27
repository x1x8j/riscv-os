#include <stdarg.h>

void console_putc(char c);
void console_puts(const char *s);

static char digits[] = "0123456789abcdef";

static void print_number(int num, int base, int sign) {
    char buf[20];
    int i = 0;
    unsigned int x;

    if(sign && num < 0)
        x = (unsigned int)(-(long long)num); // INT_MIN 安全处理
    else
        x = (unsigned int)num;

    do {
        buf[i++] = digits[x % base];
        x /= base;
    } while(x != 0);

    if(sign && num < 0)
        buf[i++] = '-';

    while(--i >= 0)
        console_putc(buf[i]);
}

static void printptr(unsigned long long x) {
    console_puts("0x");
    for(int i = (sizeof(x)*2 - 1); i >= 0; i--)
        console_putc(digits[(x >> (i*4)) & 0xf]);
}

int printf(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    for(int i=0; fmt[i]; i++){
        if(fmt[i] != '%'){
            console_putc(fmt[i]);
            continue;
        }
        i++;
        char c = fmt[i];
        switch(c){
            case 'd': print_number(va_arg(ap, int), 10, 1); break;
            case 'u': print_number(va_arg(ap, unsigned int), 10, 0); break;
            case 'x': print_number(va_arg(ap, unsigned int), 16, 0); break;
            case 'l': // 支持 %ld / %lx
                if(fmt[i+1] == 'd') { print_number(va_arg(ap, long), 10, 1); i++; break; }
                if(fmt[i+1] == 'x') { print_number(va_arg(ap, unsigned long), 16, 0); i++; break; }
                // 未知 l? 就直接输出
                console_putc('%'); console_putc('l'); break;
            case 'c': console_putc(va_arg(ap, int)); break;
            case 's': {
                char *s = va_arg(ap, char*);
                if(!s) s = "(null)";
                for(; *s; s++) console_putc(*s);
                break;
            }
            case 'p': printptr(va_arg(ap, unsigned long long)); break;
            case '%': console_putc('%'); break;
            default:
                console_putc('%'); console_putc(c); // 未知格式
        }
    }
    va_end(ap);
    return 0;
}

int sprintf(char *buf, const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    char *p = buf;
    for(int i=0; fmt[i]; i++){
        if(fmt[i] != '%'){
            *p++ = fmt[i];
            continue;
        }
        i++;
        char c = fmt[i];
        switch(c){
            case 'd': {
                char tmp[20]; int len = 0;
                long long num = va_arg(ap, int);
                unsigned long long x = (num<0)?-(long long)num:num;
                do { tmp[len++] = digits[x % 10]; x /= 10; } while(x);
                if(num<0) tmp[len++] = '-';
                while(len--) *p++ = tmp[len];
                break;
            }
            case 's': {
                char *s = va_arg(ap, char*);
                if(!s) s = "(null)";
                while(*s) *p++ = *s++;
                break;
            }
            default: *p++ = '%'; *p++ = c; break;
        }
    }
    *p = 0;
    va_end(ap);
    return p - buf;
}

void panic(const char *s) 
{ 
	printf("panic: %s\n", s); 
	for(;;); 
}

