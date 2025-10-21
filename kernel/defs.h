#include"types.h"

// console.c
void            console_putc(int);

// kalloc.c
void   kinit(void);
void*  kalloc(void);
void   kfree(void *);

// vm.c
typedef uint64* pagetable_t;
typedef uint64 pte_t;

void      kvminit(void);
void      kvminithart(void);
int       mappages(pagetable_t, uint64, uint64, uint64, int);
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

// trap.c
extern uint     ticks;
void            trapinithart(void);
void            trap_init(void);
void            kerneltrap(void);
void            handle_exception(struct trapframe*);

// start.c
void            start(void);
uint64          get_time(void);
void            timerinit(void);
void            set_next_timer(void);
void            test_timer_interrupt(void);

// trap.c
void            clockintr(void);
void            test_exception_handling(void);
void            test_interrupt_overhead(void);
