// user/test.c
#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[]) {
  int pid;

  // 启动第一个子进程
  pid = fork();
  if (pid == 0) {
    while(1) {
      printf("A");
//      pause(1);
    }
    exit(0);  // 修复：加参数
  }

  // 启动第二个子进程
  pid = fork();
  if (pid == 0) {
    while(1) {
      printf("B");
//      pause(1);
    }
    exit(0);  // 修复：加参数
  }

  pid = fork();
  if (pid == 0) {
    while(1) {
      printf("C");
//      pause(1);
    }
    exit(0);  // 修复：加参数
  }

  pid = fork();
  if (pid == 0) {
    while(1) {
      printf("D");
//      pause(1);
    }
    exit(0);  // 修复：加参数
  }

  pid = fork();
  if (pid == 0) {
    while(1) {
      printf("E");
//      pause(1);
    }
    exit(0);  // 修复：加参数
  }


  // 父进程等待两个子进程结束（虽然它们不会主动结束）
  wait((int *) 0);  // 修复：传 NULL 指针
  wait((int *) 0);
  wait((int *) 0);
  wait((int *) 0);
  wait((int *) 0);


  exit(0);  // 修复：加参数
}
