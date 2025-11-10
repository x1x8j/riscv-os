// user/proctest.c
#include "kernel/types.h"
#include "user.h"
#include "kernel/fcntl.h"
#include "kernel/stat.h"
#include "kernel/param.h"

#define SCHED_WORKERS 4      // 明确指定调度器测试的 worker 数量
#define MAX_TEST_PROC 8      // 进程创建测试的最大尝试数

void debug_proc_table(void);

// 忙等待模拟 sleep（单位：时钟滴答）
void delay(int ticks) {
    int start = uptime();
    while (uptime() - start < ticks)
        ;
}

// 手动将非负整数转为字符串（buf 至少 12 字节）
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

    // 反转
    int len = i;
    for (int j = 0; j < len; j++) {
        buf[j] = temp[len - 1 - j];
    }
    buf[len] = '\0';
}

// ==========================
// 1. 简单任务
// ==========================
void simple_task(void) {
    printf("Simple task running\n");
//    debug_proc_table();
    exit(0);
}

// ==========================
// 2. CPU 密集型任务（忙循环）
// ==========================
void cpu_intensive_task(void) {
    volatile long sum = 0;
    for (long i = 0; i < 500000; i++) {
        sum += i;
    }
    printf("CPU task computed sum = %d\n", (int)(sum % 1000000));
    exit(0);
}

// ==========================
// 3. 生产者任务（通过 pipe）
// ==========================
void producer_task(int write_fd) {
    for (int i = 0; i < 5; i++) {
        write(write_fd, &i, sizeof(i));
        printf("Produced: %d\n", i);
        delay(20); // 模拟工作间隔
    }
    close(write_fd);
    exit(0);
}

// ==========================
// 4. 消费者任务（通过 pipe）
// ==========================
void consumer_task(int read_fd) {
    int val;
    while (read(read_fd, &val, sizeof(val)) == sizeof(val)) {
        printf("Consumed: %d\n", val);
        delay(5); // 础保输出不被吞掉
    }
    close(read_fd);
    exit(0);
}

// ==========================
// 5. 调试进程表（模拟输出）
// ==========================

void debug_proc_table(void) {
    printf("\n=== Real Process Table ===\n");
    printf("PID\tSTATE\tNAME\n");

    struct pstat stats[NPROC];
    if (dump_proc(stats) < 0) {
        printf("Failed to get process table\n");
        return;
    }

    for (int i = 0; i < NPROC; i++) {
        if (stats[i].inuse) {
            char *state_str = "???";
            switch (stats[i].state) {
                case 0: state_str = "UNUSED"; break;
                case 2: state_str = "SLEEPING"; break;
                case 3: state_str = "RUNNABLE"; break;
                case 4: state_str = "RUNNING"; break;
                case 5: state_str = "ZOMBIE"; break;
            }
            printf("%d\t%s\t%s\n", stats[i].pid, state_str, stats[i].name);
        }
    }
}

// ==========================
// 6. 测试进程创建
// ==========================
void test_process_creation(void) {
    printf("Testing process creation...\n");

    int total_created = 0;

    // 第一个子进程：用于打印消息
    int pid = fork();
    if (pid < 0) {
        printf("fork failed!\n");
    } else if (pid == 0) {
        printf("Child process running\n");
        exit(0);
    } else {
        total_created++;
        wait((int *)0);
    }

    // 批量创建 MAX_TEST_PROC 个子进程
    for (int i = 0; i < MAX_TEST_PROC; i++) {
        pid = fork();
        if (pid < 0) {
            // fork 失败，停止创建
            break;
        }
        if (pid == 0) {
            // 子进程什么都不做，直接退出
            exit(0);
        }
        total_created++;
    }

    printf("Created %d processes\n", total_created);

    // 等待剩余子进程（第一个已 wait，这里等剩下的）
    for (int i = 0; i < total_created - 1; i++) {
        wait((int *)0);
    }
}

// ==========================
// 7. 测试调度器（时间片轮转）
// ==========================
void test_scheduler(void) {
    printf("Testing scheduler with %d workers...\n", SCHED_WORKERS);

    int start_time = uptime();
    int created = 0;

    for (int i = 0; i < SCHED_WORKERS; i++) {
        int pid = fork();
        if (pid < 0) {
            printf("fork failed at worker %d\n", i);
            break;
        }
        if (pid == 0) {
            volatile long x = 0;
            for (long j = 0; j < 200000; j++) {
                x += j;
            }
            printf("Worker %d finished\n", i);
            exit(0);
        }
        created++;
    }

    // 等待所有成功创建的子进程
    for (int i = 0; i < created; i++) {
        wait((int *)0);
    }

    int end_time = uptime();
    printf("Scheduler test completed in %d ticks\n", end_time - start_time);
}

// ==========================
// 8. 测试同步（pipe 实现生产者-消费者）
// ==========================
void test_synchronization(void) {
    printf("Testing synchronization (basic producer-consumer)...\n");

    int pipefd[2];
    if (pipe(pipefd) != 0) {
        printf("pipe failed!\n");
        exit(1);
    }

    int pid1 = fork();
    if (pid1 < 0) {
        printf("fork producer failed\n");
        exit(1);
    }
    if (pid1 == 0) {
        close(pipefd[0]);
        producer_task(pipefd[1]);
    }

    int pid2 = fork();
    if (pid2 < 0) {
        printf("fork consumer failed\n");
        exit(1);
    }
    if (pid2 == 0) {
        close(pipefd[1]);
        consumer_task(pipefd[0]);
    }

    // 父进程关闭 pipe 并等待
    close(pipefd[0]);
    close(pipefd[1]);

    wait((int *)0); // 等待任意一个子进程
    wait((int *)0); // 等待另一个

    printf("Synchronization test completed\n");
}

// ==========================
// 主函数
// ==========================
int main(int argc, char *argv[]) {
    printf("=== Starting xv6 Comprehensive Test Suite ===\n");

//    debug_proc_table();
    test_process_creation();
    test_scheduler();
    test_synchronization();

    // 单独测试简单任务
    if (fork() == 0) {
        debug_proc_table();
        simple_task();
//	printf("Simple task running (my PID = %d)\n", getpid());
    }
    wait((int *)0);

    if (fork() == 0) {
        cpu_intensive_task();
    }
    wait((int *)0);


    debug_proc_table();


    printf("=== All tests completed ===\n");
    exit(0);
}
