#include"types.h"
// kalloc.c
void   kinit(void);
void*  kalloc(void);
void   kfree(void *);

// vm.c
typedef uint64* pagetable_t;
typedef uint64 pte_t;

void      kvminit(void);
void      kvminithart(void);
int       mappages(pagetable_t, uint64, uint64, int);
pte_t*    walk(pagetable_t, uint64, int);
void      dump_pagetable(pagetable_t, int);

// printf.c
void printf(const char *fmt, ...);
void panic(const char *s) __attribute__((noreturn));

// string.c
int             memcmp(const void*, const void*, uint);
void*           memmove(void*, const void*, uint);
void*           memset(void*, int, uint);
char*           safestrcpy(char*, const char*, int);
int             strlen(const char*);
int             strncmp(const char*, const char*, uint);
char*           strncpy(char*, const char*, int);
