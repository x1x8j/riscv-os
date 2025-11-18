// cowtest.c：用于测试 copy-on-write (COW) fork 实现的正确性
#include "kernel/types.h"
#include "kernel/memlayout.h"  // 包含 PHYSTOP 等内存布局定义
#include "user/user.h"

// 测试1：分配超过一半物理内存后 fork，验证 COW 能避免内存耗尽
void simpletest() {
  // 计算物理内存总大小（PHYSTOP - KERNBASE 是用户可用物理内存上限）
  uint64 phys_size = PHYSTOP - KERNBASE;
  // 分配约 2/3 的物理内存（在非 COW 系统中，fork 会因复制失败而崩溃）
  int sz = (phys_size / 3) * 2;

  printf("simple: ");

  // 使用 sbrk 扩展堆，分配 sz 字节内存
  char *p = sbrk(sz);
  if (p == (char*)0xffffffffffffffffL) {
    printf("sbrk(%d) failed\n", sz);
    exit(-1);
  }

  // 向每一页写入当前进程 ID（确保所有页都被“使用”，防止懒分配绕过测试）
  for (char *q = p; q < p + sz; q += 4096) {
    *(int*)q = getpid();
  }

  // 尝试 fork —— 如果没有 COW，内核会尝试复制所有页，导致内存不足而失败
  int pid = fork();
  if (pid < 0) {
    printf("fork() failed\n");
    exit(-1);
  }

  if (pid == 0) {
    // 子进程直接退出（不写内存，仅验证 fork 成功）
    exit(0);
  }

  // 父进程等待子进程结束
  wait(0);

  // 释放之前分配的内存
  if (sbrk(-sz) == (char*)0xffffffffffffffffL) {
    printf("sbrk(-%d) failed\n", sz);
    exit(-1);
  }

  printf("ok\n");
}

// 测试2：三个进程并发写同一块 COW 内存区域，
// 验证：1) 写操作隔离；2) 复制的页能被正确释放；3) 不会耗尽内存
void threetest() {
  uint64 phys_size = PHYSTOP - KERNBASE;
  int sz = phys_size / 4;  // 分配 1/4 物理内存
  int pid1, pid2;

  printf("three: ");

  char *p = sbrk(sz);
  if (p == (char*)0xffffffffffffffffL) {
    printf("sbrk(%d) failed\n", sz);
    exit(-1);
  }

  // 第一次 fork：创建子进程1
  pid1 = fork();
  if (pid1 < 0) {
    printf("fork failed\n");
    exit(-1);
  }

  if (pid1 == 0) {
    // 子进程1：再 fork 出子进程2
    pid2 = fork();
    if (pid2 < 0) {
      printf("fork failed");
      exit(-1);
    }
    if (pid2 == 0) {
      // 子进程2：写前 4/5 的内存区域
      for (char *q = p; q < p + (sz/5)*4; q += 4096) {
        *(int*)q = getpid();  // 写入自己的 PID
      }
      // 验证写入内容是否正确（防止 COW 复制失败或映射错误）
      for (char *q = p; q < p + (sz/5)*4; q += 4096) {
        if (*(int*)q != getpid()) {
          printf("wrong content\n");
          exit(-1);
        }
      }
      exit(0);  
    }

    // 子进程1：写前 1/2 的内存区域
    for (char *q = p; q < p + (sz/2); q += 4096) {
      *(int*)q = 9999;
    }
    exit(0);
  }

  // 父进程：写整个内存区域
  for (char *q = p; q < p + sz; q += 4096) {
    *(int*)q = getpid();
  }

  // 等待子进程1结束（子进程1 会等待子进程2）
  wait(0);

  // 稍等片刻，让子进程完全退出，释放其占用的物理页
  pause(1);

  // 验证父进程自己的内存内容未被子进程修改
  for (char *q = p; q < p + sz; q += 4096) {
    if (*(int*)q != getpid()) {
      printf("wrong content\n");
      exit(-1);
    }
  }

  // 释放内存
  if (sbrk(-sz) == (char*)0xffffffffffffffffL) {
    printf("sbrk(-%d) failed\n", sz);
    exit(-1);
  }

  printf("ok\n");
}

// 全局缓冲区（用于测试系统调用是否会触发 COW）
char junk1[4096];  // 填充页对齐，避免编译器优化
int fds[2];
char junk2[4096];
char buf[4096];   // 关键：这个缓冲区会被子进程通过 read() 修改
char junk3[4096];

// 测试3：验证内核的 copyout() 是否能正确处理 COW
// （例如 read() 系统调用向用户空间写数据时，应触发 COW）
void filetest() {
  printf("file: ");

  // 父进程初始化 buf[0] 为 99
  buf[0] = 99;

  // 创建 4 个子进程，每个通过 pipe 读取一个不同整数
  for (int i = 0; i < 4; i++) {
    if (pipe(fds) != 0) {
      printf("pipe() failed\n");
      exit(-1);
    }

    int pid = fork();
    if (pid < 0) {
      printf("fork failed\n");
      exit(-1);
    }

    if (pid == 0) {
      // 子进程：从 pipe 读取数据到 buf
      pause(1);  // 确保父进程先 write
      if (read(fds[0], buf, sizeof(i)) != sizeof(i)) {
        printf("error: read failed\n");
        exit(1);
      }
      pause(1);
      int j = *(int*)buf;
      if (j != i) {
        printf("error: read the wrong value\n");
        exit(1);
      }
      exit(0);
    }

    // 父进程：向 pipe 写入整数 i
    if (write(fds[1], &i, sizeof(i)) != sizeof(i)) {
      printf("error: write failed\n");
      exit(-1);
    }
    // 关闭 pipe（虽然不影响测试，但好习惯）
    close(fds[0]);
    close(fds[1]);
  }

  // 等待所有子进程结束
  int xstatus = 0;
  for (int i = 0; i < 4; i++) {
    wait(&xstatus);
    if (xstatus != 0) {
      exit(1);
    }
  }

  // 关键检查：父进程的 buf[0] 应仍为 99
  // 如果 COW 未在 copyout() 中处理，子进程的 read() 会直接修改父进程的页！
  if (buf[0] != 99) {
    printf("error: child overwrote parent\n");
    exit(1);
  }

  printf("ok\n");
}

// 主函数：按顺序运行所有测试
int main(int argc, char *argv[]) {
  printf("section 1:\n");
  simpletest();  // 第一次大内存测试

  printf("section 2:\n");
  // 再次运行 simpletest，验证第一次测试释放的内存确实被回收了
  // 如果 COW 页未正确释放，第二次可能失败
  simpletest();

  printf("section 3:\n");
  // 连续三次运行 threetest，进一步压力测试内存分配与回收
  threetest();
  threetest();
  threetest();

  // 测试系统调用路径下的 COW 行为
  filetest();

  printf("ALL COW TESTS PASSED\n");
  exit(0);
}
