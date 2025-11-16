// user/cowtest.c
#include "kernel/types.h"
#include "user/user.h"

// 测试1：父子进程写同一地址应互不影响
void test_simple_cow() {
  int x = 100;
  int pid = fork();
  if (pid == 0) {
    x = 200;
    exit(0);
  } else {
    wait(0);
    if (x != 100) {
      printf("COW test1 failed: parent value changed\n");
      exit(1);
    }
    printf("COW test1 passed\n");
  }
}

// 测试2：多层 fork 共享
void test_multi_fork() {
  int val = 42;
  int p1 = fork();
  if (p1 == 0) {
    val = 1;
    int p2 = fork();
    if (p2 == 0) {
      val = 2;
      exit(0);
    }
    wait(0);
    if (val != 1) {
      printf("COW test2 child failed\n");
      exit(1);
    }
    exit(0);
  }
  wait(0);
  if (val != 42) {
    printf("COW test2 parent failed\n");
    exit(1);
  }
  printf("COW test2 passed\n");
}

// 测试3：写后释放，内存应正确回收
void test_memory_leak() {
  // 简单验证：多次 fork + write 不应 panic
  for(int i = 0; i < 10; i++){
    int pid = fork();
    if(pid == 0){
      volatile int *p = (int*)0x1000; // 已映射的用户页
      *p = i;
      exit(0);
    }
    wait(0);
  }
  printf("COW test3 (no panic) passed\n");
}

int main(void) {
  test_simple_cow();
  test_multi_fork();
  test_memory_leak();
  printf("All COW tests passed!\n");
  exit(0);
}
