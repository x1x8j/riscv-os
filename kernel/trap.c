// 中断和异常处理模块
// 负责处理来自用户态的系统调用、设备中断、页错误等

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

// 用于保护全局 tick 计数器的自旋锁
struct spinlock tickslock;
// 全局时钟滴答计数器（由定时器中断递增）
uint ticks;

// 外部声明：trampoline.S 中定义的 trampoline 页起始地址和 uservec 入口
extern char trampoline[], uservec[];

// kernelvec.S 中定义的内核异常向量入口（处理内核态发生的中断/异常）
void kernelvec();

// 声明设备中断处理函数（在其他文件中实现）
extern int devintr();

// 初始化 trap 相关的锁
void
trapinit(void)
{
  // 初始化 tickslock，名称为 "time"
  initlock(&tickslock, "time");
}

// 为当前 hart（CPU 核心）设置内核态异常向量
void
trapinithart(void)
{
  // 将 stvec（Supervisor Trap Vector Base Register）指向 kernelvec
  // 这样当 CPU 在内核态发生异常时，会跳转到 kernelvec 处理
  w_stvec((uint64)kernelvec);
}

//
// 处理来自用户空间的中断、异常或系统调用
// 由 trampoline.S 调用，处理完后返回用户态
// 返回值是用户页表的 satp 值，供 trampoline.S 切换使用
//
uint64
usertrap(void)
{
  int which_dev = 0; // 记录是否是设备中断，以及是哪种设备

  // 安全检查：确保当前确实是从用户态陷入内核的
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    panic("usertrap: 不是从用户模式调用的！");

  // 切换异常向量：现在处于内核态，后续若再发生异常，应跳转到 kernelvec
  w_stvec((uint64)kernelvec);  // DOC: kernelvec

  // 获取当前运行的进程结构体
  struct proc *p = myproc();

  // 保存用户程序的程序计数器（即发生异常时的指令地址）
  p->trapframe->epc = r_sepc();

  // 判断异常原因（scause 寄存器）
  if (r_scause() == 8) {
    // 系统调用（ecall 指令触发）
    
    // 如果进程已被标记为 killed，直接退出
    if (killed(p))
      kexit(-1);

    // ecall 指令本身会停在该指令处，但我们希望返回后执行下一条指令
    p->trapframe->epc += 4;

    // 此时已保存完 sepc/scause/sstatus，可以安全开启中断
    intr_on();

    // 执行系统调用分发
    syscall();
  
  } else if ((which_dev = devintr()) != 0) {
    // 是设备中断（如 UART、磁盘、定时器等），devintr 已处理，无需额外操作
    // ok
  
  } else if (r_scause() == 15) {
    // 写操作导致的页错误（Store/AMO page fault）
    // 这很可能是尝试写一个被标记为 COW（写时复制）的只读页

    pte_t* pte; 
    // 获取引发异常的虚拟地址，并向下对齐到页边界
    uint64 va = PGROUNDDOWN(r_stval());
    
    // 安全检查：虚拟地址不能超过用户地址空间上限
    if (va >= MAXVA) {
      printf("虚拟地址超出 MAXVA 范围！\n");
      p->killed = 1;
      goto end;
    }
    
    // 安全检查：虚拟地址不能超过进程当前分配的内存大小（sz）
    if (va > p->sz) {
      printf("虚拟地址超出进程内存大小 sz！\n");
      p->killed = 1;
      goto end;
    }
    
    // 查找该虚拟地址对应的页表项（PTE），不创建新页表
    pte = walk(p->pagetable, va, 0);
    
    // 验证 PTE 是否合法且确实是 COW 页：
    // - PTE 必须存在
    // - 必须设置了 PTE_COW 标志
    // - 必须是有效页（PTE_V）
    // - 必须是用户页（PTE_U）
    if (pte == 0 || ((*pte) & PTE_COW) == 0 || 
        ((*pte) & PTE_V) == 0 || ((*pte) & PTE_U) == 0) {
      printf("usertrap: PTE 不存在 或 不是 COW 页\n");
      p->killed = 1;
      goto end;
    }

    // 确认是 COW 页，执行写时复制
    if (*pte & PTE_COW) {
      char *mem; // 用于指向新分配的物理页

      // 分配一个新的物理页
      if ((mem = kalloc()) == 0) {
        printf("usertrap(): 内存分配失败！\n");
        p->killed = 1;
        goto end;
      }

      // 可选：清零新页（实际会被 memmove 覆盖，可省略）
      memset(mem, 0, PGSIZE);

      // 获取原物理页地址（walkaddr 会自动解析 PTE 得到物理地址）
      uint64 pa = walkaddr(p->pagetable, va);
      if (pa) {
        // 将原页内容复制到新页
        memmove(mem, (char*)pa, PGSIZE);

        // 构造新的页表项权限：
        // 保留原有标志（如 PTE_U, PTE_R, PTE_V），加上可写（PTE_W），移除 COW 标志
        int perm = PTE_FLAGS(*pte);
        perm |= PTE_W;     // 允许写入
        perm &= ~PTE_COW;  // 不再是 COW 页

        // 将虚拟地址 va 重新映射到新物理页 mem
        if (mappages(p->pagetable, va, PGSIZE, (uint64)mem, perm) != 0) {
          printf("usertrap(): 无法映射新页！\n");
          kfree(mem); // 分配失败，释放新页
          p->killed = 1;
          goto end;
        }

        // 关键：释放原来的物理页
        // 注意：kfree 会减少引用计数，只有当引用归零时才真正放回空闲链表
        kfree((void*) pa);
      } else {
        printf("usertrap(): 无法获取原物理地址，va: %lx \n", va);
        p->killed = 1;
        goto end;
      }
    } else {
      // 理论上不会走到这里（前面已检查 PTE_COW）
      printf("usertrap(): 页错误不是由 COW 引起的！\n");
      p->killed = 1;
      goto end;
    }
  
  } else {
    // 未知的异常原因，打印调试信息并杀死进程
    printf("usertrap(): 未预期的 scause 异常码 0x%lx，进程 pid=%d\n", r_scause(), p->pid);
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval()); 
    p->killed = 1;
  }

end:
  // 如果进程被标记为 killed，立即退出
  if (p->killed)
    kexit(-1);

  // 如果是定时器中断（which_dev == 2），主动让出 CPU（实现时间片轮转）
  if (which_dev == 2) {
    yield(); // 触发调度器选择下一个进程
  }

  // 准备从内核返回用户态所需的寄存器状态
  prepare_return();

  // 构造用户页表的 satp 值，供 trampoline.S 切换页表使用
  uint64 satp = MAKE_SATP(p->pagetable);

  // 返回 satp 值（通过 a0 寄存器传给 trampoline.S）
  return satp;
}

//
// 设置 trapframe 和控制寄存器，为返回用户空间做准备
//
void
prepare_return(void)
{
  struct proc *p = myproc();

  // 即将把异常处理目标从 kerneltrap 切换回 usertrap，
  // 为防止内核代码异常跳转到 usertrap（灾难性错误），先关闭中断
  intr_off();

  // 设置 stvec 指向 trampoline 页中的 uservec 入口
  // 这样下次用户态发生异常时，会通过 trampoline 跳转到 usertrap
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
  w_stvec(trampoline_uservec);

  // 设置 trapframe 中的内核上下文信息，供下次陷入内核时恢复使用
  p->trapframe->kernel_satp = r_satp();         // 当前内核页表
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // 内核栈顶
  p->trapframe->kernel_trap = (uint64)usertrap; // 用户异常处理函数地址
  p->trapframe->kernel_hartid = r_tp();         // 当前 CPU 核心 ID

  // 设置 sret 指令返回用户态所需的寄存器状态
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // 清除 SPP 位：下次 sret 返回用户态（Privilege = User）
  x |= SSTATUS_SPIE; // 允许用户态开启中断（SPIE = 1）
  w_sstatus(x);

  // 设置返回用户态的程序计数器（即上次保存的 epc）
  w_sepc(p->trapframe->epc);
}

// 
// 处理来自内核代码的中断和异常（通过 kernelvec 调用）
// 使用当前进程的内核栈
//
void 
kerneltrap()
{
  int which_dev = 0;
  uint64 sepc = r_sepc();      // 保存异常发生时的 sepc
  uint64 sstatus = r_sstatus(); // 保存 sstatus
  uint64 scause = r_scause();   // 异常原因

  // 安全检查：必须是从内核态（SPP=1）进入的
  if ((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: 不是从 Supervisor 模式调用的！");
  
  // 安全检查：内核态不应开启中断
  if (intr_get() != 0)
    panic("kerneltrap: 内核态中断未关闭！");

  // 尝试处理设备中断
  if ((which_dev = devintr()) == 0) {
    // 未知来源的中断或异常，打印信息并 panic
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    panic("kerneltrap");
  }

  // 如果是定时器中断（which_dev == 2），且当前有运行的进程
  if (which_dev == 2 && myproc() != 0) {
    struct proc *p = myproc();
    // 增加当前进程已使用的 tick 数
    acquire(&p->lock);
    p->ticks++;
    // 检查是否用完时间片（假设 timeslice 已在别处定义）
    int need_yield = (p->ticks >= p->timeslice);
    if (need_yield) {
      p->ticks = 0; // 重置时间片计数器
    }
    release(&p->lock);

    // 如果时间片用完，主动让出 CPU
    if (need_yield) {
      yield();
    }
  }

  // yield() 可能导致上下文切换，恢复 sepc 和 sstatus 供 kernelvec.S 使用
  w_sepc(sepc);
  w_sstatus(sstatus);
}

// 定时器中断处理函数
void
clockintr()
{
  // 只在 CPU 0 上更新全局 ticks（避免多核竞争）
  if (cpuid() == 0) {
    acquire(&tickslock);
    ticks++;           // 全局滴答数加一
    wakeup(&ticks);    // 唤醒等待 ticks 变化的进程（如 sleep）
    release(&tickslock);
  }

  // 请求下一次定时器中断（约 0.1 秒后）
  // 同时清除当前中断请求
  w_stimecmp(r_time() + 1000000);
}

// 
// 检查是否是外部中断或软件中断，并进行处理
// 返回值：
//   2 —— 定时器中断
//   1 —— 其他设备中断（UART、磁盘等）
//   0 —— 未识别的中断
//
int
devintr()
{
  uint64 scause = r_scause();

  if (scause == 0x8000000000000009L) {
    // Supervisor 外部中断（通过 PLIC 控制器）

    // 查询 PLIC，获取具体是哪个设备发出的中断
    int irq = plic_claim();

    if (irq == UART0_IRQ) {
      uartintr();        // 处理串口中断
    } else if (irq == VIRTIO0_IRQ) {
      virtio_disk_intr(); // 处理磁盘中断
    } else if (irq) {
      printf("意外的中断 irq=%d\n", irq);
    }

    // 告诉 PLIC 该设备已完成中断处理，允许再次触发中断
    if (irq)
      plic_complete(irq);

    return 1; // 设备中断
  } else if (scause == 0x8000000000000005L) {
    // 定时器中断
    clockintr();
    return 2;
  } else {
    // 未知中断源
    return 0;
  }
}
