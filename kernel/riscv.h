#include"types.h"
#define PGSIZE 4096
#define PGROUNDUP(sz)  (((sz)+PGSIZE-1) & ~(PGSIZE-1))
#define PGROUNDDOWN(a) (((a)) & ~(PGSIZE-1))

// 页表项标志位
#define PTE_V (1L << 0) // 有效
#define PTE_R (1L << 1)
#define PTE_W (1L << 2)
#define PTE_X (1L << 3)
#define PTE_U (1L << 4)

// 从 PTE 提取物理地址
#define PTE2PA(pte)  (((pte) >> 10) << 12)
#define PA2PTE(pa)   (((uint64)(pa) >> 12) << 10)

// Sv39 地址解析
#define PXSHIFT(level)  (12 + (9 * (level)))
#define PX(level, va)   ((((uint64) (va)) >> PXSHIFT(level)) & 0x1FF)

// 在 riscv.h 的中断相关常量部分添加
#define MSTATUS_MIE (1L << 3)  
// 在 riscv.h 的中断相关常量部分添加
#define MIE_MTIE (1L << 7)  // Machine Timer Interrupt Enable
#define MSTATUS_MPP_MASK (3L << 11) // previous mode.
#define MSTATUS_MPP_M (3L << 11)
#define MSTATUS_MPP_S (1L << 11)
#define MSTATUS_MPP_U (0L << 11)

// 写 satp
static inline void w_satp(uint64 x) {
  asm volatile("csrw satp, %0" : : "r"(x));
}

// 刷新 TLB
static inline void sfence_vma() {
  asm volatile("sfence.vma zero, zero");
}

// CSR 操作函数
static inline uint64 r_mstatus(void) {
  uint64 x;
  asm volatile("csrr %0, mstatus" : "=r" (x) );
  return x;
}

static inline void w_mstatus(uint64 x) {
  asm volatile("csrw mstatus, %0" : : "r" (x));
}

static inline uint64 r_mie(void) {
  uint64 x;
  asm volatile("csrr %0, mie" : "=r" (x) );
  return x;
}

static inline void w_mie(uint64 x) {
  asm volatile("csrw mie, %0" : : "r" (x));
}

static inline uint64 r_mip(void) {
  uint64 x;
  asm volatile("csrr %0, mip" : "=r" (x) );
  return x;
}

static inline void w_mip(uint64 x) {
  asm volatile("csrw mip, %0" : : "r" (x));
}

static inline uint64 r_mtvec(void) {
  uint64 x;
  asm volatile("csrr %0, mtvec" : "=r" (x) );
  return x;
}

static inline void w_mtvec(uint64 x) {
  asm volatile("csrw mtvec, %0" : : "r" (x));
}

static inline uint64 r_mideleg(void) {
  uint64 x;
  asm volatile("csrr %0, mideleg" : "=r" (x) );
  return x;
}

static inline void w_mideleg(uint64 x) {
  asm volatile("csrw mideleg, %0" : : "r" (x));
}

static inline uint64 r_medeleg(void) {
  uint64 x;
  asm volatile("csrr %0, medeleg" : "=r" (x) );
  return x;
}

static inline void w_medeleg(uint64 x) {
  asm volatile("csrw medeleg, %0" : : "r" (x));
}

static inline uint64 r_sstatus(void) {
  uint64 x;
  asm volatile("csrr %0, sstatus" : "=r" (x) );
  return x;
}

static inline void w_sstatus(uint64 x) {
  asm volatile("csrw sstatus, %0" : : "r" (x));
}

static inline uint64 r_sie(void) {
  uint64 x;
  asm volatile("csrr %0, sie" : "=r" (x) );
  return x;
}

static inline void w_sie(uint64 x) {
  asm volatile("csrw sie, %0" : : "r" (x));
}

static inline uint64 r_sip(void) {
  uint64 x;
  asm volatile("csrr %0, sip" : "=r" (x) );
  return x;
}

static inline void w_sip(uint64 x) {
  asm volatile("csrw sip, %0" : : "r" (x));
}

static inline uint64 r_stvec(void) {
  uint64 x;
  asm volatile("csrr %0, stvec" : "=r" (x) );
  return x;
}

static inline void w_stvec(uint64 x) {
  asm volatile("csrw stvec, %0" : : "r" (x));
}

static inline uint64 r_scause(void) {
  uint64 x;
  asm volatile("csrr %0, scause" : "=r" (x) );
  return x;
}

static inline uint64 r_sepc(void) {
  uint64 x;
  asm volatile("csrr %0, sepc" : "=r" (x) );
  return x;
}

static inline void w_sepc(uint64 x) {
  asm volatile("csrw sepc, %0" : : "r" (x));
}

static inline uint64 r_stval(void) {
  uint64 x;
  asm volatile("csrr %0, stval" : "=r" (x) );
  return x;
}



static inline uint64 r_time(void) {
  uint64 x;
  asm volatile("csrr %0, time" : "=r" (x) );
  return x;
}



// 中断相关常量
#define SSTATUS_SIE (1L << 1)  // Supervisor Interrupt Enable
#define SSTATUS_SPP (1L << 8) // Previous mode, 1=Supervisor, 0=User

#define SIE_SEIE (1L << 9) // external
#define SIE_STIE (1L << 5) // timer
#define SIE_SSIE (1L << 1) // software

#define SIP_SEIP (1L << 9) // external
#define SIP_STIP (1L << 5) // timer
#define SIP_SSIP (1L << 1) // software

#define SCAUSE_INTERRUPT_MASK (1ULL << 63)
#define SCAUSE_CODE_MASK (0xFFULL)

#define IRQ_S_SOFT 1
#define IRQ_S_TIMER 5
#define IRQ_S_EXT 9

// 中断使能控制
static inline void intr_on(void) {
  w_sstatus(r_sstatus() | SSTATUS_SIE);
}

static inline void intr_off(void) {
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
}

static inline int intr_get(void) {
  uint64 x = r_sstatus();
  return (x & SSTATUS_SIE) != 0;
}

// trapframe 结构体
struct trapframe {
  /*   0 */ uint64 kernel_satp;   // kernel page table
  /*   8 */ uint64 kernel_sp;     // top of process's kernel stack
  /*  16 */ uint64 kernel_trap;  // usertrap()
  /*  24 */ uint64 epc;          // saved user program counter
  /*  32 */ uint64 kernel_hartid;// saved kernel tp
  /*  40 */ uint64 ra;
  /*  48 */ uint64 sp;
  /*  56 */ uint64 gp;
  /*  64 */ uint64 tp;
  /*  72 */ uint64 t0;
  /*  80 */ uint64 t1;
  /*  88 */ uint64 t2;
  /*  96 */ uint64 s0;
  /* 104 */ uint64 s1;
  /* 112 */ uint64 a0;
  /* 120 */ uint64 a1;
  /* 128 */ uint64 a2;
  /* 136 */ uint64 a3;
  /* 144 */ uint64 a4;
  /* 152 */ uint64 a5;
  /* 160 */ uint64 a6;
  /* 168 */ uint64 a7;
  /* 176 */ uint64 s2;
  /* 184 */ uint64 s3;
  /* 192 */ uint64 s4;
  /* 200 */ uint64 s5;
  /* 208 */ uint64 s6;
  /* 216 */ uint64 s7;
  /* 224 */ uint64 s8;
  /* 232 */ uint64 s9;
  /* 240 */ uint64 s10;
  /* 248 */ uint64 s11;
  /* 256 */ uint64 t3;
  /* 264 */ uint64 t4;
  /* 272 */ uint64 t5;
  /* 280 */ uint64 t6;
};
#define MIE_STIE (1L << 5)  // supervisor timer
// Supervisor Timer Comparison Register
static inline uint64
r_stimecmp()
{
  uint64 x;
  // asm volatile("csrr %0, stimecmp" : "=r" (x) );
  asm volatile("csrr %0, 0x14d" : "=r" (x) );
  return x;
}

static inline void 
w_stimecmp(uint64 x)
{
  // asm volatile("csrw stimecmp, %0" : : "r" (x));
  asm volatile("csrw 0x14d, %0" : : "r" (x));
  // 先写高32位，再写低32位
  // 顺序很重要：先高后低，避免中间状态匹配
//  asm volatile("csrw 0x14e, %0" : : "r" (x >> 32));  // stimecmp_hi
//  asm volatile("csrw 0x14d, %0" : : "r" (x & 0xFFFFFFFF));  // stimecmp_lo
}


// Machine Environment Configuration Register
static inline uint64
r_menvcfg()
{
  uint64 x;
  // asm volatile("csrr %0, menvcfg" : "=r" (x) );
  asm volatile("csrr %0, 0x30a" : "=r" (x) );
  return x;
}

static inline void 
w_menvcfg(uint64 x)
{
  // asm volatile("csrw menvcfg, %0" : : "r" (x));
  asm volatile("csrw 0x30a, %0" : : "r" (x));
}

// Machine-mode Counter-Enable
static inline void 
w_mcounteren(uint64 x)
{
  asm volatile("csrw mcounteren, %0" : : "r" (x));
}

static inline uint64
r_mcounteren()
{
  uint64 x;
  asm volatile("csrr %0, mcounteren" : "=r" (x) );
  return x;
}

// 在 riscv.h 中添加（比如放在其他 CSR 函数附近）
static inline uint64 r_mhartid(void) {
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x));
  return x;
}


// 在 riscv.h 中添加（放在其他 CSR 操作函数附近）
static inline void w_mscratch(uint64 x) {
  asm volatile("csrw mscratch, %0" : : "r" (x));
}

// 通常也需要对应的读函数，一起添加
static inline uint64 r_mscratch(void) {
  uint64 x;
  asm volatile("csrr %0, mscratch" : "=r" (x));
  return x;
}


static inline void
w_mepc(uint64 x)
{
  asm volatile("csrw mepc, %0" : : "r" (x));
}

// Physical Memory Protection
static inline void
w_pmpcfg0(uint64 x)
{
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
}

static inline void
w_pmpaddr0(uint64 x)
{
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
}
static inline void
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
}

// sscratch register
static inline void w_sscratch(uint64 x) {
  asm volatile("csrw sscratch, %0" : : "r" (x));
}

static inline uint64 r_sscratch() {
  uint64 x;
  asm volatile("csrr %0, sscratch" : "=r" (x));
  return x;
}
