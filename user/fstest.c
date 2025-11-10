// user/fstest.c
#include "kernel/types.h"
#include "user.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"

void test_filesystem_integrity(void) {
    printf("\n=== Testing filesystem integrity ===\n");

    int fd = open("testfile", O_CREATE | O_RDWR);
    if (fd < 0) exit(1);
    write(fd, "OK", 2);
    close(fd);

    fd = open("testfile", O_RDONLY);
    if (fd < 0) exit(1);
    char buf[4];
    read(fd, buf, 2);
    close(fd);
    unlink("testfile");

    if (buf[0] != 'O' || buf[1] != 'K') exit(1);
    printf("Filesystem integrity test passed\n");
}

void test_concurrent_access(void) {
    printf("\n=== Testing concurrent file access ===\n");

    // 创建 4 个不同名字的文件：f0, f1, f2, f3
    for (int i = 0; i < 4; i++) {
        if (fork() == 0) {
            const char* names[] = {"f0", "f1", "f2", "f3"};
            for (int j = 0; j < 30; j++) {
                int fd = open(names[i], O_CREATE | O_RDWR);
                if (fd >= 0) {
                    write(fd, &j, sizeof(j));
                    close(fd);
                    unlink(names[i]);
                }
            }
            exit(0);
        }
    }

    for (int i = 0; i < 4; i++)
        wait((int *)0);

    printf("Concurrent access test completed\n");
}

void test_crash_recovery(void) {
    printf("\n=== Testing crash recovery (simulated) ===\n");

    // 创建 partial_0 到 partial_9 → 改为创建 p0, p1, ..., p9
    const char* parts[] = {
        "p0", "p1", "p2", "p3", "p4",
        "p5", "p6", "p7", "p8", "p9"
    };

    for (int i = 0; i < 10; i++) {
        int fd = open(parts[i], O_CREATE | O_RDWR);
        if (fd >= 0) {
            write(fd, "x", 1);
            close(fd);
            // 不 unlink，模拟崩溃残留
        }
    }

    printf("Crash recovery test setup complete. Check for p0-p9 files.\n");
    printf("Reboot to test recovery behavior.\n");
}

void test_filesystem_performance(void) {
    printf("\n=== Testing filesystem performance ===\n");

    int start = uptime();
    const char* smalls[] = {
        "s0","s1","s2","s3","s4","s5","s6","s7","s8","s9"
    };
    // 创建 100 个小文件（循环 10 次，每次 10 个）
    for (int round = 0; round < 10; round++) {
        for (int i = 0; i < 10; i++) {
            int fd = open(smalls[i], O_CREATE | O_RDWR);
            if (fd >= 0) {
                write(fd, ".", 1);
                close(fd);
            }
        }
    }
    int time_small = uptime() - start;

    start = uptime();
    int fd = open("big", O_CREATE | O_RDWR);
    if (fd >= 0) {
        char b[512] = {0};
        for (int i = 0; i < 200; i++) // ~100KB
            write(fd, b, sizeof(b));
        close(fd);
    }
    int time_big = uptime() - start;

    printf("100 small files: %d ticks\n", time_small);
    printf("Big file (~100KB): %d ticks\n", time_big);

    // 清理
    for (int i = 0; i < 10; i++) unlink(smalls[i]);
    unlink("big");
    for (int i = 0; i < 10; i++) {
        const char* pfiles[] = {"p0","p1","p2","p3","p4","p5","p6","p7","p8","p9"};
        unlink(pfiles[i]);
    }

    printf("Performance test cleanup done\n");
}

int main(void) {
    printf("=== xv6 Filesystem Test Suite (Minimal Safe Version) ===\n");

    test_filesystem_integrity();
    test_concurrent_access();
    test_crash_recovery();
    test_filesystem_performance();

    printf("\n=== All tests completed successfully ===\n");
    exit(0);
}
