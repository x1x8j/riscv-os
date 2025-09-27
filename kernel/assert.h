// kernel/assert.h
#pragma once
#include "defs.h"

// 简易 assert 宏
#define assert(x)                                  \
  do {                                            \
    if (!(x)) {                                   \
      printf("Assertion failed: %s\nFile: %s, Line: %d\n", \
             #x, __FILE__, __LINE__);            \
      for(;;);  /* 停止内核 */                   \
    }                                             \
  } while (0)

