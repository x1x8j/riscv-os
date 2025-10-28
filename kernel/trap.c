#include "types.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"

extern volatile int timer_interrupt_count;  // 在 trap.c 中引用 main.c 中定义的 interrupt_count
uint ticks;

void kernelvec();

extern int devintr();

// 设置 stvec 寄存器，指向 kernelvec 函数，以便处理中断
void
trapinithart(void)
{
  w_stvec((uint64)kernelvec);
}

// 以下是各类异常处理函数，每个异常触发时都会调用对应的函数进行处理
void handle_floating_point_exception() {
    panic("Floating-point exception");
}

void handle_illegal_instruction() {
    panic("Illegal instruction");
}

void handle_instruction_address_misalignment() {
    panic("Instruction address misaligned");
}

void handle_instruction_access_fault() {
    panic("Instruction access fault");
}

void handle_breakpoint() {
    panic("Breakpoint");
}

void handle_load_address_misalignment() {
    panic("Load address misaligned");
}

void handle_load_access_fault() {
    panic("Load access fault");
}

void handle_store_address_misalignment() {
    panic("Store address misaligned");
}

void handle_store_access_fault() {
    panic("Store access fault");
}

void handle_user_ecall() {
    panic("User environment call");
}

void handle_supervisor_ecall() {
    panic("Supervisor environment call");
}

void handle_timer_interrupt() {
    panic("Timer interrupt");
}

void handle_external_interrupt() {
    panic("External interrupt");
}

void handle_load_page_fault() {
    panic("Load page fault");
}

void handle_store_page_fault() {
    panic("Store page fault");
}

// 处理异常的主函数，根据异常的 cause（原因）来判断处理哪个异常
void handle_exception() {
    uint64 cause = r_scause();  // 获取异常的原因

    switch (cause) {
        case 0:  // 浮点异常 (Floating-point exception)
            handle_floating_point_exception();  // 处理浮点异常
            break;
        case 1:  // 非法指令 (Illegal instruction)
            handle_illegal_instruction();  // 处理非法指令
            break;
        case 2:  // 指令地址未对齐 (Instruction address misaligned)
            handle_instruction_address_misalignment();  // 处理指令地址未对齐
            break;
        case 3:  // 指令访问故障 (Instruction access fault)
            handle_instruction_access_fault();  // 处理指令访问故障
            break;
        case 4:  // 断点 (Breakpoint)
            handle_breakpoint();  // 处理断点
            break;
        case 5:  // 加载地址未对齐 (Load address misaligned)
            handle_load_address_misalignment();  // 处理加载地址未对齐
            break;
        case 6:  // 加载访问故障 (Load access fault)
            handle_load_access_fault();  // 处理加载访问故障
            break;
        case 7:  // 存储地址未对齐 (Store address misaligned)
            handle_store_address_misalignment();  // 处理存储地址未对齐
            break;
        case 8:  // 存储访问故障 (Store access fault)
            handle_store_access_fault();  // 处理存储访问故障
            break;
        case 9:  // 用户模式环境调用 (User environment call)
            handle_user_ecall();  // 处理用户模式环境调用
            break;
        case 10: // 监督模式环境调用 (Supervisor environment call)
            handle_supervisor_ecall();  // 处理监督模式环境调用
            break;
        case 11: // 计时器中断 (Timer interrupt)
            handle_timer_interrupt();  // 处理计时器中断
            break;
        case 12: // 外部中断 (External interrupt)
            handle_external_interrupt();  // 处理外部中断
            break;
        case 13: // 加载页故障 (Load page fault)
            handle_load_page_fault();  // 处理加载页故障
            break;
        case 14: // 存储页故障 (Store page fault)
            handle_store_page_fault();  // 处理存储页故障
            break;
        case 15: // 存储页故障 (Store page fault)
            handle_store_page_fault();  // 处理存储页故障
            break;
        default:
            printf("Unknown exception: scause=0x%lx\n", cause);
            panic("Unknown exception");
    }
}

// kerneltrap 是系统调用和中断的主要处理函数
void 
kerneltrap()
{
 // printf("[TRAP] Entering kerneltrap!\n");
  int which_dev = 0;
  uint64 sepc = r_sepc(); // 获取异常发生时的程序计数器（sepc）
  uint64 sstatus = r_sstatus(); // 获取状态寄存器（sstatus）
  uint64 scause = r_scause(); // 获取异常原因（scause）

  // 检查当前是否处于 S模式（超级用户模式）
  if((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: not from supervisor mode");
  // 检查中断是否已启用
  if(intr_get() != 0)
    panic("kerneltrap: interrupts enabled");
  // 调用 devintr() 函数来处理设备中断，返回值为中断类型
  if((which_dev = devintr()) == 0){
    // interrupt or trap from an unknown source
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    handle_exception();
    //panic("kerneltrap");
  }

  // if(which_dev == 2 && myproc() != 0)
  //   yield();
  
  // 恢复 sepc 和 sstatus 寄存器的值，准备返回
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void
clockintr()
{
  ticks++;
  timer_interrupt_count++;

  printf("Tick %d\n", timer_interrupt_count);
    // 假设希望10次中断后停止
  if (timer_interrupt_count>= 10) {
    // 关闭时钟中断
    w_sie(r_sie() & ~SIE_STIE);
    printf("Timer interrupt stopped after %d ticks\n", timer_interrupt_count);
    return;
  }
  // 设置定时器比较寄存器，使得下次定时器中断将在 1 秒后触发
  w_stimecmp(r_time() + 1000000);
}


int
devintr()
{
  uint64 scause = r_scause();

   if(scause == 0x8000000000000009L){
     // 如果是外部中断（来自设备），处理外部中断
     return 1;
   } else 
  if(scause == 0x8000000000000005L){
    // 定时器中断
    clockintr();
    return 2; // 定时器中断已处理
  } else {
    return 0; // 未知中断
  }
}


