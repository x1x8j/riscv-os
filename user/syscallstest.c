// user/syscallstest.c
#include "kernel/types.h"
#include "user.h"
#include "kernel/fcntl.h"

// 手动实现 itoa（用于打印数字）
void itoa(int n, char *buf) {
    if (n == 0) {
        buf[0] = '0';
        buf[1] = '\0';
        return;
    }
    int i = 0;
    char temp[12];
    while (n > 0) {
        temp[i++] = '0' + (n % 10);
        n /= 10;
    }
    temp[i] = '\0';
    int len = i;
    for (int j = 0; j < len; j++) {
        buf[j] = temp[len - 1 - j];
    }
    buf[len] = '\0';
}

void test_basic_syscalls(void) {
    printf("\n=== Testing basic system calls ===\n");

    int pid = getpid();
    printf("Current PID: %d\n", pid);

    int child = fork();
    if (child == 0) {
        printf("Child process: PID=%d\n", getpid());
        exit(42);
    } else if (child > 0) {
        int status;
        wait(&status);
        // xv6: status 是子进程 exit() 的参数
        printf("Child exited with status: %d\n", status);
    } else {
        printf("Fork failed!\n");
    }
}

void test_parameter_passing(void) {
    printf("\n=== Testing parameter passing and edge cases ===\n");

    int fd = open("/dev/console", O_WRONLY);
    if (fd >= 0) {
        char msg[] = "Test write to console\n";
        int bytes_written = write(fd, msg, sizeof(msg) - 1);
        printf("Wrote %d bytes to console\n", bytes_written);
        close(fd);
    }

    printf("Testing invalid syscalls...\n");
    // 尝试无效系统调用参数（xv6 通常返回 -1）
    int res = write(-1, "bad", 3);
    printf("Write to bad fd returned: %d\n", res); // 应为 -1
}

void test_security(void) {
    printf("\n=== Testing security / invalid memory access ===\n");

    // 尝试写入无效地址（应被内核阻止）
    int result = write(1, (void*)0x1, 1);
    printf("Write to invalid address returned: %d\n", result); // 应为 -1

    // 尝试读取无效地址（同样应失败）
    result = read(0, (void*)0x1, 1);
    printf("Read to invalid address returned: %d\n", result); // 应为 -1
}

void test_syscall_performance(void) {
    printf("\n=== Testing system call performance ===\n");

    const int N = 10000;
    int start = uptime();
    for (int i = 0; i < N; i++) {
        getpid(); // 轻量级系统调用
    }
    int end = uptime();

    printf("%d getpid() calls took %d ticks\n", N, end - start);
    // xv6 tick ≈ 10ms，所以乘以 10 得到近似毫秒（粗略）
    printf("Approximate time: %d ms\n", (end - start) * 10);
}

int main(int argc, char *argv[]) {
    printf("=== xv6 System Call Test Suite ===\n");

    test_basic_syscalls();
    test_parameter_passing();
//    test_security();
    test_syscall_performance();

    printf("\n=== All syscall tests completed ===\n");
    exit(0);
}
