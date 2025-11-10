
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + ((hartid + 1) * 4096)
        la sp, stack0
    80000000:	00008117          	auipc	sp,0x8
    80000004:	87010113          	addi	sp,sp,-1936 # 80007870 <stack0>
        li a0, 1024*4
    80000008:	6505                	lui	a0,0x1
        csrr a1, mhartid
    8000000a:	f14025f3          	csrr	a1,mhartid
        addi a1, a1, 1
    8000000e:	0585                	addi	a1,a1,1
        mul a0, a0, a1
    80000010:	02b50533          	mul	a0,a0,a1
        add sp, sp, a0
    80000014:	912a                	add	sp,sp,a0
        # jump to start() in start.c
        call start
    80000016:	04a000ef          	jal	ra,80000060 <start>

000000008000001a <spin>:
spin:
        j spin
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
}

// ask each hart to generate timer interrupts.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
#define MIE_STIE (1L << 5)  // supervisor timer
static inline uint64
r_mie()
{
  uint64 x;
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000022:	304027f3          	csrr	a5,mie
  // enable supervisor-mode timer interrupts.
  w_mie(r_mie() | MIE_STIE);
    80000026:	0207e793          	ori	a5,a5,32
}

static inline void 
w_mie(uint64 x)
{
  asm volatile("csrw mie, %0" : : "r" (x));
    8000002a:	30479073          	csrw	mie,a5
static inline uint64
r_menvcfg()
{
  uint64 x;
  // asm volatile("csrr %0, menvcfg" : "=r" (x) );
  asm volatile("csrr %0, 0x30a" : "=r" (x) );
    8000002e:	30a027f3          	csrr	a5,0x30a
  
  // enable the sstc extension (i.e. stimecmp).
  w_menvcfg(r_menvcfg() | (1L << 63)); 
    80000032:	577d                	li	a4,-1
    80000034:	177e                	slli	a4,a4,0x3f
    80000036:	8fd9                	or	a5,a5,a4

static inline void 
w_menvcfg(uint64 x)
{
  // asm volatile("csrw menvcfg, %0" : : "r" (x));
  asm volatile("csrw 0x30a, %0" : : "r" (x));
    80000038:	30a79073          	csrw	0x30a,a5

static inline uint64
r_mcounteren()
{
  uint64 x;
  asm volatile("csrr %0, mcounteren" : "=r" (x) );
    8000003c:	306027f3          	csrr	a5,mcounteren
  
  // allow supervisor to use stimecmp and time.
  w_mcounteren(r_mcounteren() | 2);
    80000040:	0027e793          	ori	a5,a5,2
  asm volatile("csrw mcounteren, %0" : : "r" (x));
    80000044:	30679073          	csrw	mcounteren,a5
// machine-mode cycle counter
static inline uint64
r_time()
{
  uint64 x;
  asm volatile("csrr %0, time" : "=r" (x) );
    80000048:	c01027f3          	rdtime	a5
  
  // ask for the very first timer interrupt.
  w_stimecmp(r_time() + 1000000);
    8000004c:	000f4737          	lui	a4,0xf4
    80000050:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000054:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80000056:	14d79073          	csrw	0x14d,a5
}
    8000005a:	6422                	ld	s0,8(sp)
    8000005c:	0141                	addi	sp,sp,16
    8000005e:	8082                	ret

0000000080000060 <start>:
{
    80000060:	1141                	addi	sp,sp,-16
    80000062:	e406                	sd	ra,8(sp)
    80000064:	e022                	sd	s0,0(sp)
    80000066:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000006c:	7779                	lui	a4,0xffffe
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffddc87>
    80000072:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000074:	6705                	lui	a4,0x1
    80000076:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000007a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007c:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000080:	00001797          	auipc	a5,0x1
    80000084:	d6278793          	addi	a5,a5,-670 # 80000de2 <main>
    80000088:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    8000008c:	4781                	li	a5,0
    8000008e:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000092:	67c1                	lui	a5,0x10
    80000094:	17fd                	addi	a5,a5,-1
    80000096:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    8000009a:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    8000009e:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE);
    800000a2:	2207e793          	ori	a5,a5,544
  asm volatile("csrw sie, %0" : : "r" (x));
    800000a6:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000aa:	57fd                	li	a5,-1
    800000ac:	83a9                	srli	a5,a5,0xa
    800000ae:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000b2:	47bd                	li	a5,15
    800000b4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000b8:	f65ff0ef          	jal	ra,8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000bc:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000c0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000c2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000c4:	30200073          	mret
}
    800000c8:	60a2                	ld	ra,8(sp)
    800000ca:	6402                	ld	s0,0(sp)
    800000cc:	0141                	addi	sp,sp,16
    800000ce:	8082                	ret

00000000800000d0 <consolewrite>:
// user write() system calls to the console go here.
// uses sleep() and UART interrupts.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000d0:	7159                	addi	sp,sp,-112
    800000d2:	f486                	sd	ra,104(sp)
    800000d4:	f0a2                	sd	s0,96(sp)
    800000d6:	eca6                	sd	s1,88(sp)
    800000d8:	e8ca                	sd	s2,80(sp)
    800000da:	e4ce                	sd	s3,72(sp)
    800000dc:	e0d2                	sd	s4,64(sp)
    800000de:	fc56                	sd	s5,56(sp)
    800000e0:	f85a                	sd	s6,48(sp)
    800000e2:	f45e                	sd	s7,40(sp)
    800000e4:	f062                	sd	s8,32(sp)
    800000e6:	1880                	addi	s0,sp,112
  char buf[32]; // move batches from user space to uart.
  int i = 0;

  while(i < n){
    800000e8:	04c05463          	blez	a2,80000130 <consolewrite+0x60>
    800000ec:	8a2a                	mv	s4,a0
    800000ee:	8aae                	mv	s5,a1
    800000f0:	89b2                	mv	s3,a2
  int i = 0;
    800000f2:	4901                	li	s2,0
    int nn = sizeof(buf);
    if(nn > n - i)
    800000f4:	4bfd                	li	s7,31
    int nn = sizeof(buf);
    800000f6:	02000c13          	li	s8,32
      nn = n - i;
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    800000fa:	5b7d                	li	s6,-1
    800000fc:	a025                	j	80000124 <consolewrite+0x54>
    800000fe:	86a6                	mv	a3,s1
    80000100:	01590633          	add	a2,s2,s5
    80000104:	85d2                	mv	a1,s4
    80000106:	f9040513          	addi	a0,s0,-112
    8000010a:	0a8020ef          	jal	ra,800021b2 <either_copyin>
    8000010e:	03650263          	beq	a0,s6,80000132 <consolewrite+0x62>
      break;
    uartwrite(buf, nn);
    80000112:	85a6                	mv	a1,s1
    80000114:	f9040513          	addi	a0,s0,-112
    80000118:	71e000ef          	jal	ra,80000836 <uartwrite>
    i += nn;
    8000011c:	0124893b          	addw	s2,s1,s2
  while(i < n){
    80000120:	01395963          	bge	s2,s3,80000132 <consolewrite+0x62>
    if(nn > n - i)
    80000124:	412984bb          	subw	s1,s3,s2
    80000128:	fc9bdbe3          	bge	s7,s1,800000fe <consolewrite+0x2e>
    int nn = sizeof(buf);
    8000012c:	84e2                	mv	s1,s8
    8000012e:	bfc1                	j	800000fe <consolewrite+0x2e>
  int i = 0;
    80000130:	4901                	li	s2,0
  }

  return i;
}
    80000132:	854a                	mv	a0,s2
    80000134:	70a6                	ld	ra,104(sp)
    80000136:	7406                	ld	s0,96(sp)
    80000138:	64e6                	ld	s1,88(sp)
    8000013a:	6946                	ld	s2,80(sp)
    8000013c:	69a6                	ld	s3,72(sp)
    8000013e:	6a06                	ld	s4,64(sp)
    80000140:	7ae2                	ld	s5,56(sp)
    80000142:	7b42                	ld	s6,48(sp)
    80000144:	7ba2                	ld	s7,40(sp)
    80000146:	7c02                	ld	s8,32(sp)
    80000148:	6165                	addi	sp,sp,112
    8000014a:	8082                	ret

000000008000014c <consoleread>:
// user_dst indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000014c:	7159                	addi	sp,sp,-112
    8000014e:	f486                	sd	ra,104(sp)
    80000150:	f0a2                	sd	s0,96(sp)
    80000152:	eca6                	sd	s1,88(sp)
    80000154:	e8ca                	sd	s2,80(sp)
    80000156:	e4ce                	sd	s3,72(sp)
    80000158:	e0d2                	sd	s4,64(sp)
    8000015a:	fc56                	sd	s5,56(sp)
    8000015c:	f85a                	sd	s6,48(sp)
    8000015e:	f45e                	sd	s7,40(sp)
    80000160:	f062                	sd	s8,32(sp)
    80000162:	ec66                	sd	s9,24(sp)
    80000164:	e86a                	sd	s10,16(sp)
    80000166:	1880                	addi	s0,sp,112
    80000168:	8aaa                	mv	s5,a0
    8000016a:	8a2e                	mv	s4,a1
    8000016c:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000016e:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000172:	0000f517          	auipc	a0,0xf
    80000176:	6fe50513          	addi	a0,a0,1790 # 8000f870 <cons>
    8000017a:	1f3000ef          	jal	ra,80000b6c <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000017e:	0000f497          	auipc	s1,0xf
    80000182:	6f248493          	addi	s1,s1,1778 # 8000f870 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000186:	0000f917          	auipc	s2,0xf
    8000018a:	78290913          	addi	s2,s2,1922 # 8000f908 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    8000018e:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000190:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    80000192:	4ca9                	li	s9,10
  while(n > 0){
    80000194:	07305363          	blez	s3,800001fa <consoleread+0xae>
    while(cons.r == cons.w){
    80000198:	0984a783          	lw	a5,152(s1)
    8000019c:	09c4a703          	lw	a4,156(s1)
    800001a0:	02f71163          	bne	a4,a5,800001c2 <consoleread+0x76>
      if(killed(myproc())){
    800001a4:	660010ef          	jal	ra,80001804 <myproc>
    800001a8:	69d010ef          	jal	ra,80002044 <killed>
    800001ac:	e125                	bnez	a0,8000020c <consoleread+0xc0>
      sleep(&cons.r, &cons.lock);
    800001ae:	85a6                	mv	a1,s1
    800001b0:	854a                	mv	a0,s2
    800001b2:	45b010ef          	jal	ra,80001e0c <sleep>
    while(cons.r == cons.w){
    800001b6:	0984a783          	lw	a5,152(s1)
    800001ba:	09c4a703          	lw	a4,156(s1)
    800001be:	fef703e3          	beq	a4,a5,800001a4 <consoleread+0x58>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001c2:	0017871b          	addiw	a4,a5,1
    800001c6:	08e4ac23          	sw	a4,152(s1)
    800001ca:	07f7f713          	andi	a4,a5,127
    800001ce:	9726                	add	a4,a4,s1
    800001d0:	01874703          	lbu	a4,24(a4)
    800001d4:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001d8:	057d0f63          	beq	s10,s7,80000236 <consoleread+0xea>
    cbuf = c;
    800001dc:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001e0:	4685                	li	a3,1
    800001e2:	f9f40613          	addi	a2,s0,-97
    800001e6:	85d2                	mv	a1,s4
    800001e8:	8556                	mv	a0,s5
    800001ea:	77f010ef          	jal	ra,80002168 <either_copyout>
    800001ee:	01850663          	beq	a0,s8,800001fa <consoleread+0xae>
    dst++;
    800001f2:	0a05                	addi	s4,s4,1
    --n;
    800001f4:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    800001f6:	f99d1fe3          	bne	s10,s9,80000194 <consoleread+0x48>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    800001fa:	0000f517          	auipc	a0,0xf
    800001fe:	67650513          	addi	a0,a0,1654 # 8000f870 <cons>
    80000202:	203000ef          	jal	ra,80000c04 <release>

  return target - n;
    80000206:	413b053b          	subw	a0,s6,s3
    8000020a:	a801                	j	8000021a <consoleread+0xce>
        release(&cons.lock);
    8000020c:	0000f517          	auipc	a0,0xf
    80000210:	66450513          	addi	a0,a0,1636 # 8000f870 <cons>
    80000214:	1f1000ef          	jal	ra,80000c04 <release>
        return -1;
    80000218:	557d                	li	a0,-1
}
    8000021a:	70a6                	ld	ra,104(sp)
    8000021c:	7406                	ld	s0,96(sp)
    8000021e:	64e6                	ld	s1,88(sp)
    80000220:	6946                	ld	s2,80(sp)
    80000222:	69a6                	ld	s3,72(sp)
    80000224:	6a06                	ld	s4,64(sp)
    80000226:	7ae2                	ld	s5,56(sp)
    80000228:	7b42                	ld	s6,48(sp)
    8000022a:	7ba2                	ld	s7,40(sp)
    8000022c:	7c02                	ld	s8,32(sp)
    8000022e:	6ce2                	ld	s9,24(sp)
    80000230:	6d42                	ld	s10,16(sp)
    80000232:	6165                	addi	sp,sp,112
    80000234:	8082                	ret
      if(n < target){
    80000236:	0009871b          	sext.w	a4,s3
    8000023a:	fd6770e3          	bgeu	a4,s6,800001fa <consoleread+0xae>
        cons.r--;
    8000023e:	0000f717          	auipc	a4,0xf
    80000242:	6cf72523          	sw	a5,1738(a4) # 8000f908 <cons+0x98>
    80000246:	bf55                	j	800001fa <consoleread+0xae>

0000000080000248 <consputc>:
{
    80000248:	1141                	addi	sp,sp,-16
    8000024a:	e406                	sd	ra,8(sp)
    8000024c:	e022                	sd	s0,0(sp)
    8000024e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000250:	10000793          	li	a5,256
    80000254:	00f50863          	beq	a0,a5,80000264 <consputc+0x1c>
    uartputc_sync(c);
    80000258:	67c000ef          	jal	ra,800008d4 <uartputc_sync>
}
    8000025c:	60a2                	ld	ra,8(sp)
    8000025e:	6402                	ld	s0,0(sp)
    80000260:	0141                	addi	sp,sp,16
    80000262:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000264:	4521                	li	a0,8
    80000266:	66e000ef          	jal	ra,800008d4 <uartputc_sync>
    8000026a:	02000513          	li	a0,32
    8000026e:	666000ef          	jal	ra,800008d4 <uartputc_sync>
    80000272:	4521                	li	a0,8
    80000274:	660000ef          	jal	ra,800008d4 <uartputc_sync>
    80000278:	b7d5                	j	8000025c <consputc+0x14>

000000008000027a <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    8000027a:	1101                	addi	sp,sp,-32
    8000027c:	ec06                	sd	ra,24(sp)
    8000027e:	e822                	sd	s0,16(sp)
    80000280:	e426                	sd	s1,8(sp)
    80000282:	e04a                	sd	s2,0(sp)
    80000284:	1000                	addi	s0,sp,32
    80000286:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    80000288:	0000f517          	auipc	a0,0xf
    8000028c:	5e850513          	addi	a0,a0,1512 # 8000f870 <cons>
    80000290:	0dd000ef          	jal	ra,80000b6c <acquire>

  switch(c){
    80000294:	47d5                	li	a5,21
    80000296:	0af48063          	beq	s1,a5,80000336 <consoleintr+0xbc>
    8000029a:	0297c663          	blt	a5,s1,800002c6 <consoleintr+0x4c>
    8000029e:	47a1                	li	a5,8
    800002a0:	0cf48f63          	beq	s1,a5,8000037e <consoleintr+0x104>
    800002a4:	47c1                	li	a5,16
    800002a6:	10f49063          	bne	s1,a5,800003a6 <consoleintr+0x12c>
  case C('P'):  // Print process list.
    procdump();
    800002aa:	753010ef          	jal	ra,800021fc <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002ae:	0000f517          	auipc	a0,0xf
    800002b2:	5c250513          	addi	a0,a0,1474 # 8000f870 <cons>
    800002b6:	14f000ef          	jal	ra,80000c04 <release>
}
    800002ba:	60e2                	ld	ra,24(sp)
    800002bc:	6442                	ld	s0,16(sp)
    800002be:	64a2                	ld	s1,8(sp)
    800002c0:	6902                	ld	s2,0(sp)
    800002c2:	6105                	addi	sp,sp,32
    800002c4:	8082                	ret
  switch(c){
    800002c6:	07f00793          	li	a5,127
    800002ca:	0af48a63          	beq	s1,a5,8000037e <consoleintr+0x104>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800002ce:	0000f717          	auipc	a4,0xf
    800002d2:	5a270713          	addi	a4,a4,1442 # 8000f870 <cons>
    800002d6:	0a072783          	lw	a5,160(a4)
    800002da:	09872703          	lw	a4,152(a4)
    800002de:	9f99                	subw	a5,a5,a4
    800002e0:	07f00713          	li	a4,127
    800002e4:	fcf765e3          	bltu	a4,a5,800002ae <consoleintr+0x34>
      c = (c == '\r') ? '\n' : c;
    800002e8:	47b5                	li	a5,13
    800002ea:	0cf48163          	beq	s1,a5,800003ac <consoleintr+0x132>
      consputc(c);
    800002ee:	8526                	mv	a0,s1
    800002f0:	f59ff0ef          	jal	ra,80000248 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800002f4:	0000f797          	auipc	a5,0xf
    800002f8:	57c78793          	addi	a5,a5,1404 # 8000f870 <cons>
    800002fc:	0a07a683          	lw	a3,160(a5)
    80000300:	0016871b          	addiw	a4,a3,1
    80000304:	0007061b          	sext.w	a2,a4
    80000308:	0ae7a023          	sw	a4,160(a5)
    8000030c:	07f6f693          	andi	a3,a3,127
    80000310:	97b6                	add	a5,a5,a3
    80000312:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000316:	47a9                	li	a5,10
    80000318:	0af48f63          	beq	s1,a5,800003d6 <consoleintr+0x15c>
    8000031c:	4791                	li	a5,4
    8000031e:	0af48c63          	beq	s1,a5,800003d6 <consoleintr+0x15c>
    80000322:	0000f797          	auipc	a5,0xf
    80000326:	5e67a783          	lw	a5,1510(a5) # 8000f908 <cons+0x98>
    8000032a:	9f1d                	subw	a4,a4,a5
    8000032c:	08000793          	li	a5,128
    80000330:	f6f71fe3          	bne	a4,a5,800002ae <consoleintr+0x34>
    80000334:	a04d                	j	800003d6 <consoleintr+0x15c>
    while(cons.e != cons.w &&
    80000336:	0000f717          	auipc	a4,0xf
    8000033a:	53a70713          	addi	a4,a4,1338 # 8000f870 <cons>
    8000033e:	0a072783          	lw	a5,160(a4)
    80000342:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000346:	0000f497          	auipc	s1,0xf
    8000034a:	52a48493          	addi	s1,s1,1322 # 8000f870 <cons>
    while(cons.e != cons.w &&
    8000034e:	4929                	li	s2,10
    80000350:	f4f70fe3          	beq	a4,a5,800002ae <consoleintr+0x34>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000354:	37fd                	addiw	a5,a5,-1
    80000356:	07f7f713          	andi	a4,a5,127
    8000035a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000035c:	01874703          	lbu	a4,24(a4)
    80000360:	f52707e3          	beq	a4,s2,800002ae <consoleintr+0x34>
      cons.e--;
    80000364:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    80000368:	10000513          	li	a0,256
    8000036c:	eddff0ef          	jal	ra,80000248 <consputc>
    while(cons.e != cons.w &&
    80000370:	0a04a783          	lw	a5,160(s1)
    80000374:	09c4a703          	lw	a4,156(s1)
    80000378:	fcf71ee3          	bne	a4,a5,80000354 <consoleintr+0xda>
    8000037c:	bf0d                	j	800002ae <consoleintr+0x34>
    if(cons.e != cons.w){
    8000037e:	0000f717          	auipc	a4,0xf
    80000382:	4f270713          	addi	a4,a4,1266 # 8000f870 <cons>
    80000386:	0a072783          	lw	a5,160(a4)
    8000038a:	09c72703          	lw	a4,156(a4)
    8000038e:	f2f700e3          	beq	a4,a5,800002ae <consoleintr+0x34>
      cons.e--;
    80000392:	37fd                	addiw	a5,a5,-1
    80000394:	0000f717          	auipc	a4,0xf
    80000398:	56f72e23          	sw	a5,1404(a4) # 8000f910 <cons+0xa0>
      consputc(BACKSPACE);
    8000039c:	10000513          	li	a0,256
    800003a0:	ea9ff0ef          	jal	ra,80000248 <consputc>
    800003a4:	b729                	j	800002ae <consoleintr+0x34>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003a6:	f00484e3          	beqz	s1,800002ae <consoleintr+0x34>
    800003aa:	b715                	j	800002ce <consoleintr+0x54>
      consputc(c);
    800003ac:	4529                	li	a0,10
    800003ae:	e9bff0ef          	jal	ra,80000248 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800003b2:	0000f797          	auipc	a5,0xf
    800003b6:	4be78793          	addi	a5,a5,1214 # 8000f870 <cons>
    800003ba:	0a07a703          	lw	a4,160(a5)
    800003be:	0017069b          	addiw	a3,a4,1
    800003c2:	0006861b          	sext.w	a2,a3
    800003c6:	0ad7a023          	sw	a3,160(a5)
    800003ca:	07f77713          	andi	a4,a4,127
    800003ce:	97ba                	add	a5,a5,a4
    800003d0:	4729                	li	a4,10
    800003d2:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    800003d6:	0000f797          	auipc	a5,0xf
    800003da:	52c7ab23          	sw	a2,1334(a5) # 8000f90c <cons+0x9c>
        wakeup(&cons.r);
    800003de:	0000f517          	auipc	a0,0xf
    800003e2:	52a50513          	addi	a0,a0,1322 # 8000f908 <cons+0x98>
    800003e6:	273010ef          	jal	ra,80001e58 <wakeup>
    800003ea:	b5d1                	j	800002ae <consoleintr+0x34>

00000000800003ec <consoleinit>:

void
consoleinit(void)
{
    800003ec:	1141                	addi	sp,sp,-16
    800003ee:	e406                	sd	ra,8(sp)
    800003f0:	e022                	sd	s0,0(sp)
    800003f2:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    800003f4:	00007597          	auipc	a1,0x7
    800003f8:	c1c58593          	addi	a1,a1,-996 # 80007010 <etext+0x10>
    800003fc:	0000f517          	auipc	a0,0xf
    80000400:	47450513          	addi	a0,a0,1140 # 8000f870 <cons>
    80000404:	6e8000ef          	jal	ra,80000aec <initlock>

  uartinit();
    80000408:	3e2000ef          	jal	ra,800007ea <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000040c:	0001f797          	auipc	a5,0x1f
    80000410:	5d478793          	addi	a5,a5,1492 # 8001f9e0 <devsw>
    80000414:	00000717          	auipc	a4,0x0
    80000418:	d3870713          	addi	a4,a4,-712 # 8000014c <consoleread>
    8000041c:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000041e:	00000717          	auipc	a4,0x0
    80000422:	cb270713          	addi	a4,a4,-846 # 800000d0 <consolewrite>
    80000426:	ef98                	sd	a4,24(a5)
}
    80000428:	60a2                	ld	ra,8(sp)
    8000042a:	6402                	ld	s0,0(sp)
    8000042c:	0141                	addi	sp,sp,16
    8000042e:	8082                	ret

0000000080000430 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    80000430:	7139                	addi	sp,sp,-64
    80000432:	fc06                	sd	ra,56(sp)
    80000434:	f822                	sd	s0,48(sp)
    80000436:	f426                	sd	s1,40(sp)
    80000438:	f04a                	sd	s2,32(sp)
    8000043a:	0080                	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    8000043c:	c219                	beqz	a2,80000442 <printint+0x12>
    8000043e:	06054f63          	bltz	a0,800004bc <printint+0x8c>
    x = -xx;
  else
    x = xx;
    80000442:	4881                	li	a7,0
    80000444:	fc840693          	addi	a3,s0,-56

  i = 0;
    80000448:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    8000044a:	00007617          	auipc	a2,0x7
    8000044e:	bee60613          	addi	a2,a2,-1042 # 80007038 <digits>
    80000452:	883e                	mv	a6,a5
    80000454:	2785                	addiw	a5,a5,1
    80000456:	02b57733          	remu	a4,a0,a1
    8000045a:	9732                	add	a4,a4,a2
    8000045c:	00074703          	lbu	a4,0(a4)
    80000460:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    80000464:	872a                	mv	a4,a0
    80000466:	02b55533          	divu	a0,a0,a1
    8000046a:	0685                	addi	a3,a3,1
    8000046c:	feb773e3          	bgeu	a4,a1,80000452 <printint+0x22>

  if(sign)
    80000470:	00088b63          	beqz	a7,80000486 <printint+0x56>
    buf[i++] = '-';
    80000474:	fe040713          	addi	a4,s0,-32
    80000478:	97ba                	add	a5,a5,a4
    8000047a:	02d00713          	li	a4,45
    8000047e:	fee78423          	sb	a4,-24(a5)
    80000482:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    80000486:	02f05563          	blez	a5,800004b0 <printint+0x80>
    8000048a:	fc840713          	addi	a4,s0,-56
    8000048e:	00f704b3          	add	s1,a4,a5
    80000492:	fff70913          	addi	s2,a4,-1
    80000496:	993e                	add	s2,s2,a5
    80000498:	37fd                	addiw	a5,a5,-1
    8000049a:	1782                	slli	a5,a5,0x20
    8000049c:	9381                	srli	a5,a5,0x20
    8000049e:	40f90933          	sub	s2,s2,a5
    consputc(buf[i]);
    800004a2:	fff4c503          	lbu	a0,-1(s1)
    800004a6:	da3ff0ef          	jal	ra,80000248 <consputc>
  while(--i >= 0)
    800004aa:	14fd                	addi	s1,s1,-1
    800004ac:	ff249be3          	bne	s1,s2,800004a2 <printint+0x72>
}
    800004b0:	70e2                	ld	ra,56(sp)
    800004b2:	7442                	ld	s0,48(sp)
    800004b4:	74a2                	ld	s1,40(sp)
    800004b6:	7902                	ld	s2,32(sp)
    800004b8:	6121                	addi	sp,sp,64
    800004ba:	8082                	ret
    x = -xx;
    800004bc:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    800004c0:	4885                	li	a7,1
    x = -xx;
    800004c2:	b749                	j	80000444 <printint+0x14>

00000000800004c4 <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    800004c4:	7131                	addi	sp,sp,-192
    800004c6:	fc86                	sd	ra,120(sp)
    800004c8:	f8a2                	sd	s0,112(sp)
    800004ca:	f4a6                	sd	s1,104(sp)
    800004cc:	f0ca                	sd	s2,96(sp)
    800004ce:	ecce                	sd	s3,88(sp)
    800004d0:	e8d2                	sd	s4,80(sp)
    800004d2:	e4d6                	sd	s5,72(sp)
    800004d4:	e0da                	sd	s6,64(sp)
    800004d6:	fc5e                	sd	s7,56(sp)
    800004d8:	f862                	sd	s8,48(sp)
    800004da:	f466                	sd	s9,40(sp)
    800004dc:	f06a                	sd	s10,32(sp)
    800004de:	ec6e                	sd	s11,24(sp)
    800004e0:	0100                	addi	s0,sp,128
    800004e2:	8a2a                	mv	s4,a0
    800004e4:	e40c                	sd	a1,8(s0)
    800004e6:	e810                	sd	a2,16(s0)
    800004e8:	ec14                	sd	a3,24(s0)
    800004ea:	f018                	sd	a4,32(s0)
    800004ec:	f41c                	sd	a5,40(s0)
    800004ee:	03043823          	sd	a6,48(s0)
    800004f2:	03143c23          	sd	a7,56(s0)
  va_list ap;
  int i, cx, c0, c1, c2;
  char *s;

  if(panicking == 0)
    800004f6:	00007797          	auipc	a5,0x7
    800004fa:	34e7a783          	lw	a5,846(a5) # 80007844 <panicking>
    800004fe:	cb9d                	beqz	a5,80000534 <printf+0x70>
    acquire(&pr.lock);

  va_start(ap, fmt);
    80000500:	00840793          	addi	a5,s0,8
    80000504:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000508:	000a4503          	lbu	a0,0(s4)
    8000050c:	24050363          	beqz	a0,80000752 <printf+0x28e>
    80000510:	4981                	li	s3,0
    if(cx != '%'){
    80000512:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    80000516:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    8000051a:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    8000051e:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    80000522:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    80000526:	07000d93          	li	s11,112
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000052a:	00007b97          	auipc	s7,0x7
    8000052e:	b0eb8b93          	addi	s7,s7,-1266 # 80007038 <digits>
    80000532:	a01d                	j	80000558 <printf+0x94>
    acquire(&pr.lock);
    80000534:	0000f517          	auipc	a0,0xf
    80000538:	3e450513          	addi	a0,a0,996 # 8000f918 <pr>
    8000053c:	630000ef          	jal	ra,80000b6c <acquire>
    80000540:	b7c1                	j	80000500 <printf+0x3c>
      consputc(cx);
    80000542:	d07ff0ef          	jal	ra,80000248 <consputc>
      continue;
    80000546:	84ce                	mv	s1,s3
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000548:	0014899b          	addiw	s3,s1,1
    8000054c:	013a07b3          	add	a5,s4,s3
    80000550:	0007c503          	lbu	a0,0(a5)
    80000554:	1e050f63          	beqz	a0,80000752 <printf+0x28e>
    if(cx != '%'){
    80000558:	ff5515e3          	bne	a0,s5,80000542 <printf+0x7e>
    i++;
    8000055c:	0019849b          	addiw	s1,s3,1
    c0 = fmt[i+0] & 0xff;
    80000560:	009a07b3          	add	a5,s4,s1
    80000564:	0007c903          	lbu	s2,0(a5)
    if(c0) c1 = fmt[i+1] & 0xff;
    80000568:	1e090563          	beqz	s2,80000752 <printf+0x28e>
    8000056c:	0017c783          	lbu	a5,1(a5)
    c1 = c2 = 0;
    80000570:	86be                	mv	a3,a5
    if(c1) c2 = fmt[i+2] & 0xff;
    80000572:	c789                	beqz	a5,8000057c <printf+0xb8>
    80000574:	009a0733          	add	a4,s4,s1
    80000578:	00274683          	lbu	a3,2(a4)
    if(c0 == 'd'){
    8000057c:	03690863          	beq	s2,s6,800005ac <printf+0xe8>
    } else if(c0 == 'l' && c1 == 'd'){
    80000580:	05890263          	beq	s2,s8,800005c4 <printf+0x100>
    } else if(c0 == 'u'){
    80000584:	0d990163          	beq	s2,s9,80000646 <printf+0x182>
    } else if(c0 == 'x'){
    80000588:	11a90863          	beq	s2,s10,80000698 <printf+0x1d4>
    } else if(c0 == 'p'){
    8000058c:	15b90163          	beq	s2,s11,800006ce <printf+0x20a>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    80000590:	06300793          	li	a5,99
    80000594:	16f90963          	beq	s2,a5,80000706 <printf+0x242>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    80000598:	07300793          	li	a5,115
    8000059c:	16f90f63          	beq	s2,a5,8000071a <printf+0x256>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    800005a0:	03591c63          	bne	s2,s5,800005d8 <printf+0x114>
      consputc('%');
    800005a4:	8556                	mv	a0,s5
    800005a6:	ca3ff0ef          	jal	ra,80000248 <consputc>
    800005aa:	bf79                	j	80000548 <printf+0x84>
      printint(va_arg(ap, int), 10, 1);
    800005ac:	f8843783          	ld	a5,-120(s0)
    800005b0:	00878713          	addi	a4,a5,8
    800005b4:	f8e43423          	sd	a4,-120(s0)
    800005b8:	4605                	li	a2,1
    800005ba:	45a9                	li	a1,10
    800005bc:	4388                	lw	a0,0(a5)
    800005be:	e73ff0ef          	jal	ra,80000430 <printint>
    800005c2:	b759                	j	80000548 <printf+0x84>
    } else if(c0 == 'l' && c1 == 'd'){
    800005c4:	03678163          	beq	a5,s6,800005e6 <printf+0x122>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    800005c8:	03878d63          	beq	a5,s8,80000602 <printf+0x13e>
    } else if(c0 == 'l' && c1 == 'u'){
    800005cc:	09978a63          	beq	a5,s9,80000660 <printf+0x19c>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    800005d0:	03878b63          	beq	a5,s8,80000606 <printf+0x142>
    } else if(c0 == 'l' && c1 == 'x'){
    800005d4:	0da78f63          	beq	a5,s10,800006b2 <printf+0x1ee>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    800005d8:	8556                	mv	a0,s5
    800005da:	c6fff0ef          	jal	ra,80000248 <consputc>
      consputc(c0);
    800005de:	854a                	mv	a0,s2
    800005e0:	c69ff0ef          	jal	ra,80000248 <consputc>
    800005e4:	b795                	j	80000548 <printf+0x84>
      printint(va_arg(ap, uint64), 10, 1);
    800005e6:	f8843783          	ld	a5,-120(s0)
    800005ea:	00878713          	addi	a4,a5,8
    800005ee:	f8e43423          	sd	a4,-120(s0)
    800005f2:	4605                	li	a2,1
    800005f4:	45a9                	li	a1,10
    800005f6:	6388                	ld	a0,0(a5)
    800005f8:	e39ff0ef          	jal	ra,80000430 <printint>
      i += 1;
    800005fc:	0029849b          	addiw	s1,s3,2
    80000600:	b7a1                	j	80000548 <printf+0x84>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    80000602:	03668463          	beq	a3,s6,8000062a <printf+0x166>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000606:	07968b63          	beq	a3,s9,8000067c <printf+0x1b8>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    8000060a:	fda697e3          	bne	a3,s10,800005d8 <printf+0x114>
      printint(va_arg(ap, uint64), 16, 0);
    8000060e:	f8843783          	ld	a5,-120(s0)
    80000612:	00878713          	addi	a4,a5,8
    80000616:	f8e43423          	sd	a4,-120(s0)
    8000061a:	4601                	li	a2,0
    8000061c:	45c1                	li	a1,16
    8000061e:	6388                	ld	a0,0(a5)
    80000620:	e11ff0ef          	jal	ra,80000430 <printint>
      i += 2;
    80000624:	0039849b          	addiw	s1,s3,3
    80000628:	b705                	j	80000548 <printf+0x84>
      printint(va_arg(ap, uint64), 10, 1);
    8000062a:	f8843783          	ld	a5,-120(s0)
    8000062e:	00878713          	addi	a4,a5,8
    80000632:	f8e43423          	sd	a4,-120(s0)
    80000636:	4605                	li	a2,1
    80000638:	45a9                	li	a1,10
    8000063a:	6388                	ld	a0,0(a5)
    8000063c:	df5ff0ef          	jal	ra,80000430 <printint>
      i += 2;
    80000640:	0039849b          	addiw	s1,s3,3
    80000644:	b711                	j	80000548 <printf+0x84>
      printint(va_arg(ap, uint32), 10, 0);
    80000646:	f8843783          	ld	a5,-120(s0)
    8000064a:	00878713          	addi	a4,a5,8
    8000064e:	f8e43423          	sd	a4,-120(s0)
    80000652:	4601                	li	a2,0
    80000654:	45a9                	li	a1,10
    80000656:	0007e503          	lwu	a0,0(a5)
    8000065a:	dd7ff0ef          	jal	ra,80000430 <printint>
    8000065e:	b5ed                	j	80000548 <printf+0x84>
      printint(va_arg(ap, uint64), 10, 0);
    80000660:	f8843783          	ld	a5,-120(s0)
    80000664:	00878713          	addi	a4,a5,8
    80000668:	f8e43423          	sd	a4,-120(s0)
    8000066c:	4601                	li	a2,0
    8000066e:	45a9                	li	a1,10
    80000670:	6388                	ld	a0,0(a5)
    80000672:	dbfff0ef          	jal	ra,80000430 <printint>
      i += 1;
    80000676:	0029849b          	addiw	s1,s3,2
    8000067a:	b5f9                	j	80000548 <printf+0x84>
      printint(va_arg(ap, uint64), 10, 0);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4601                	li	a2,0
    8000068a:	45a9                	li	a1,10
    8000068c:	6388                	ld	a0,0(a5)
    8000068e:	da3ff0ef          	jal	ra,80000430 <printint>
      i += 2;
    80000692:	0039849b          	addiw	s1,s3,3
    80000696:	bd4d                	j	80000548 <printf+0x84>
      printint(va_arg(ap, uint32), 16, 0);
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	4601                	li	a2,0
    800006a6:	45c1                	li	a1,16
    800006a8:	0007e503          	lwu	a0,0(a5)
    800006ac:	d85ff0ef          	jal	ra,80000430 <printint>
    800006b0:	bd61                	j	80000548 <printf+0x84>
      printint(va_arg(ap, uint64), 16, 0);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4601                	li	a2,0
    800006c0:	45c1                	li	a1,16
    800006c2:	6388                	ld	a0,0(a5)
    800006c4:	d6dff0ef          	jal	ra,80000430 <printint>
      i += 1;
    800006c8:	0029849b          	addiw	s1,s3,2
    800006cc:	bdb5                	j	80000548 <printf+0x84>
      printptr(va_arg(ap, uint64));
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	addi	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006de:	03000513          	li	a0,48
    800006e2:	b67ff0ef          	jal	ra,80000248 <consputc>
  consputc('x');
    800006e6:	856a                	mv	a0,s10
    800006e8:	b61ff0ef          	jal	ra,80000248 <consputc>
    800006ec:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ee:	03c9d793          	srli	a5,s3,0x3c
    800006f2:	97de                	add	a5,a5,s7
    800006f4:	0007c503          	lbu	a0,0(a5)
    800006f8:	b51ff0ef          	jal	ra,80000248 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006fc:	0992                	slli	s3,s3,0x4
    800006fe:	397d                	addiw	s2,s2,-1
    80000700:	fe0917e3          	bnez	s2,800006ee <printf+0x22a>
    80000704:	b591                	j	80000548 <printf+0x84>
      consputc(va_arg(ap, uint));
    80000706:	f8843783          	ld	a5,-120(s0)
    8000070a:	00878713          	addi	a4,a5,8
    8000070e:	f8e43423          	sd	a4,-120(s0)
    80000712:	4388                	lw	a0,0(a5)
    80000714:	b35ff0ef          	jal	ra,80000248 <consputc>
    80000718:	bd05                	j	80000548 <printf+0x84>
      if((s = va_arg(ap, char*)) == 0)
    8000071a:	f8843783          	ld	a5,-120(s0)
    8000071e:	00878713          	addi	a4,a5,8
    80000722:	f8e43423          	sd	a4,-120(s0)
    80000726:	0007b903          	ld	s2,0(a5)
    8000072a:	00090d63          	beqz	s2,80000744 <printf+0x280>
      for(; *s; s++)
    8000072e:	00094503          	lbu	a0,0(s2)
    80000732:	e0050be3          	beqz	a0,80000548 <printf+0x84>
        consputc(*s);
    80000736:	b13ff0ef          	jal	ra,80000248 <consputc>
      for(; *s; s++)
    8000073a:	0905                	addi	s2,s2,1
    8000073c:	00094503          	lbu	a0,0(s2)
    80000740:	f97d                	bnez	a0,80000736 <printf+0x272>
    80000742:	b519                	j	80000548 <printf+0x84>
        s = "(null)";
    80000744:	00007917          	auipc	s2,0x7
    80000748:	8d490913          	addi	s2,s2,-1836 # 80007018 <etext+0x18>
      for(; *s; s++)
    8000074c:	02800513          	li	a0,40
    80000750:	b7dd                	j	80000736 <printf+0x272>
    }

  }
  va_end(ap);

  if(panicking == 0)
    80000752:	00007797          	auipc	a5,0x7
    80000756:	0f27a783          	lw	a5,242(a5) # 80007844 <panicking>
    8000075a:	c38d                	beqz	a5,8000077c <printf+0x2b8>
    release(&pr.lock);

  return 0;
}
    8000075c:	4501                	li	a0,0
    8000075e:	70e6                	ld	ra,120(sp)
    80000760:	7446                	ld	s0,112(sp)
    80000762:	74a6                	ld	s1,104(sp)
    80000764:	7906                	ld	s2,96(sp)
    80000766:	69e6                	ld	s3,88(sp)
    80000768:	6a46                	ld	s4,80(sp)
    8000076a:	6aa6                	ld	s5,72(sp)
    8000076c:	6b06                	ld	s6,64(sp)
    8000076e:	7be2                	ld	s7,56(sp)
    80000770:	7c42                	ld	s8,48(sp)
    80000772:	7ca2                	ld	s9,40(sp)
    80000774:	7d02                	ld	s10,32(sp)
    80000776:	6de2                	ld	s11,24(sp)
    80000778:	6129                	addi	sp,sp,192
    8000077a:	8082                	ret
    release(&pr.lock);
    8000077c:	0000f517          	auipc	a0,0xf
    80000780:	19c50513          	addi	a0,a0,412 # 8000f918 <pr>
    80000784:	480000ef          	jal	ra,80000c04 <release>
  return 0;
    80000788:	bfd1                	j	8000075c <printf+0x298>

000000008000078a <panic>:

void
panic(char *s)
{
    8000078a:	1101                	addi	sp,sp,-32
    8000078c:	ec06                	sd	ra,24(sp)
    8000078e:	e822                	sd	s0,16(sp)
    80000790:	e426                	sd	s1,8(sp)
    80000792:	e04a                	sd	s2,0(sp)
    80000794:	1000                	addi	s0,sp,32
    80000796:	84aa                	mv	s1,a0
  panicking = 1;
    80000798:	4905                	li	s2,1
    8000079a:	00007797          	auipc	a5,0x7
    8000079e:	0b27a523          	sw	s2,170(a5) # 80007844 <panicking>
  printf("panic: ");
    800007a2:	00007517          	auipc	a0,0x7
    800007a6:	87e50513          	addi	a0,a0,-1922 # 80007020 <etext+0x20>
    800007aa:	d1bff0ef          	jal	ra,800004c4 <printf>
  printf("%s\n", s);
    800007ae:	85a6                	mv	a1,s1
    800007b0:	00007517          	auipc	a0,0x7
    800007b4:	87850513          	addi	a0,a0,-1928 # 80007028 <etext+0x28>
    800007b8:	d0dff0ef          	jal	ra,800004c4 <printf>
  panicked = 1; // freeze uart output from other CPUs
    800007bc:	00007797          	auipc	a5,0x7
    800007c0:	0927a223          	sw	s2,132(a5) # 80007840 <panicked>
  for(;;)
    800007c4:	a001                	j	800007c4 <panic+0x3a>

00000000800007c6 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007c6:	1141                	addi	sp,sp,-16
    800007c8:	e406                	sd	ra,8(sp)
    800007ca:	e022                	sd	s0,0(sp)
    800007cc:	0800                	addi	s0,sp,16
  initlock(&pr.lock, "pr");
    800007ce:	00007597          	auipc	a1,0x7
    800007d2:	86258593          	addi	a1,a1,-1950 # 80007030 <etext+0x30>
    800007d6:	0000f517          	auipc	a0,0xf
    800007da:	14250513          	addi	a0,a0,322 # 8000f918 <pr>
    800007de:	30e000ef          	jal	ra,80000aec <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartinit>:
extern volatile int panicking; // from printf.c
extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    800007ea:	1141                	addi	sp,sp,-16
    800007ec:	e406                	sd	ra,8(sp)
    800007ee:	e022                	sd	s0,0(sp)
    800007f0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007f2:	100007b7          	lui	a5,0x10000
    800007f6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007fa:	f8000713          	li	a4,-128
    800007fe:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000802:	470d                	li	a4,3
    80000804:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000808:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000080c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000810:	469d                	li	a3,7
    80000812:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000816:	00e780a3          	sb	a4,1(a5)

  initlock(&tx_lock, "uart");
    8000081a:	00007597          	auipc	a1,0x7
    8000081e:	83658593          	addi	a1,a1,-1994 # 80007050 <digits+0x18>
    80000822:	0000f517          	auipc	a0,0xf
    80000826:	10e50513          	addi	a0,a0,270 # 8000f930 <tx_lock>
    8000082a:	2c2000ef          	jal	ra,80000aec <initlock>
}
    8000082e:	60a2                	ld	ra,8(sp)
    80000830:	6402                	ld	s0,0(sp)
    80000832:	0141                	addi	sp,sp,16
    80000834:	8082                	ret

0000000080000836 <uartwrite>:
// transmit buf[] to the uart. it blocks if the
// uart is busy, so it cannot be called from
// interrupts, only from write() system calls.
void
uartwrite(char buf[], int n)
{
    80000836:	715d                	addi	sp,sp,-80
    80000838:	e486                	sd	ra,72(sp)
    8000083a:	e0a2                	sd	s0,64(sp)
    8000083c:	fc26                	sd	s1,56(sp)
    8000083e:	f84a                	sd	s2,48(sp)
    80000840:	f44e                	sd	s3,40(sp)
    80000842:	f052                	sd	s4,32(sp)
    80000844:	ec56                	sd	s5,24(sp)
    80000846:	e85a                	sd	s6,16(sp)
    80000848:	e45e                	sd	s7,8(sp)
    8000084a:	0880                	addi	s0,sp,80
    8000084c:	84aa                	mv	s1,a0
    8000084e:	8aae                	mv	s5,a1
  acquire(&tx_lock);
    80000850:	0000f517          	auipc	a0,0xf
    80000854:	0e050513          	addi	a0,a0,224 # 8000f930 <tx_lock>
    80000858:	314000ef          	jal	ra,80000b6c <acquire>

  int i = 0;
  while(i < n){ 
    8000085c:	05505b63          	blez	s5,800008b2 <uartwrite+0x7c>
    80000860:	8a26                	mv	s4,s1
    80000862:	0485                	addi	s1,s1,1
    80000864:	3afd                	addiw	s5,s5,-1
    80000866:	1a82                	slli	s5,s5,0x20
    80000868:	020ada93          	srli	s5,s5,0x20
    8000086c:	9aa6                	add	s5,s5,s1
    while(tx_busy != 0){
    8000086e:	00007497          	auipc	s1,0x7
    80000872:	fde48493          	addi	s1,s1,-34 # 8000784c <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    80000876:	0000f997          	auipc	s3,0xf
    8000087a:	0ba98993          	addi	s3,s3,186 # 8000f930 <tx_lock>
    8000087e:	00007917          	auipc	s2,0x7
    80000882:	fca90913          	addi	s2,s2,-54 # 80007848 <tx_chan>
    }   
      
    WriteReg(THR, buf[i]);
    80000886:	10000bb7          	lui	s7,0x10000
    i += 1;
    tx_busy = 1;
    8000088a:	4b05                	li	s6,1
    8000088c:	a005                	j	800008ac <uartwrite+0x76>
      sleep(&tx_chan, &tx_lock);
    8000088e:	85ce                	mv	a1,s3
    80000890:	854a                	mv	a0,s2
    80000892:	57a010ef          	jal	ra,80001e0c <sleep>
    while(tx_busy != 0){
    80000896:	409c                	lw	a5,0(s1)
    80000898:	fbfd                	bnez	a5,8000088e <uartwrite+0x58>
    WriteReg(THR, buf[i]);
    8000089a:	000a4783          	lbu	a5,0(s4)
    8000089e:	00fb8023          	sb	a5,0(s7) # 10000000 <_entry-0x70000000>
    tx_busy = 1;
    800008a2:	0164a023          	sw	s6,0(s1)
  while(i < n){ 
    800008a6:	0a05                	addi	s4,s4,1
    800008a8:	015a0563          	beq	s4,s5,800008b2 <uartwrite+0x7c>
    while(tx_busy != 0){
    800008ac:	409c                	lw	a5,0(s1)
    800008ae:	f3e5                	bnez	a5,8000088e <uartwrite+0x58>
    800008b0:	b7ed                	j	8000089a <uartwrite+0x64>
  }

  release(&tx_lock);
    800008b2:	0000f517          	auipc	a0,0xf
    800008b6:	07e50513          	addi	a0,a0,126 # 8000f930 <tx_lock>
    800008ba:	34a000ef          	jal	ra,80000c04 <release>
}
    800008be:	60a6                	ld	ra,72(sp)
    800008c0:	6406                	ld	s0,64(sp)
    800008c2:	74e2                	ld	s1,56(sp)
    800008c4:	7942                	ld	s2,48(sp)
    800008c6:	79a2                	ld	s3,40(sp)
    800008c8:	7a02                	ld	s4,32(sp)
    800008ca:	6ae2                	ld	s5,24(sp)
    800008cc:	6b42                	ld	s6,16(sp)
    800008ce:	6ba2                	ld	s7,8(sp)
    800008d0:	6161                	addi	sp,sp,80
    800008d2:	8082                	ret

00000000800008d4 <uartputc_sync>:
// interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800008d4:	1101                	addi	sp,sp,-32
    800008d6:	ec06                	sd	ra,24(sp)
    800008d8:	e822                	sd	s0,16(sp)
    800008da:	e426                	sd	s1,8(sp)
    800008dc:	1000                	addi	s0,sp,32
    800008de:	84aa                	mv	s1,a0
  if(panicking == 0)
    800008e0:	00007797          	auipc	a5,0x7
    800008e4:	f647a783          	lw	a5,-156(a5) # 80007844 <panicking>
    800008e8:	cb89                	beqz	a5,800008fa <uartputc_sync+0x26>
    push_off();

  if(panicked){
    800008ea:	00007797          	auipc	a5,0x7
    800008ee:	f567a783          	lw	a5,-170(a5) # 80007840 <panicked>
    for(;;)
      ;
  }

  // wait for UART to set Transmit Holding Empty in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800008f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800008f6:	c789                	beqz	a5,80000900 <uartputc_sync+0x2c>
    for(;;)
    800008f8:	a001                	j	800008f8 <uartputc_sync+0x24>
    push_off();
    800008fa:	232000ef          	jal	ra,80000b2c <push_off>
    800008fe:	b7f5                	j	800008ea <uartputc_sync+0x16>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000900:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000904:	0207f793          	andi	a5,a5,32
    80000908:	dfe5                	beqz	a5,80000900 <uartputc_sync+0x2c>
    ;
  WriteReg(THR, c);
    8000090a:	0ff4f513          	andi	a0,s1,255
    8000090e:	100007b7          	lui	a5,0x10000
    80000912:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  if(panicking == 0)
    80000916:	00007797          	auipc	a5,0x7
    8000091a:	f2e7a783          	lw	a5,-210(a5) # 80007844 <panicking>
    8000091e:	c791                	beqz	a5,8000092a <uartputc_sync+0x56>
    pop_off();
}
    80000920:	60e2                	ld	ra,24(sp)
    80000922:	6442                	ld	s0,16(sp)
    80000924:	64a2                	ld	s1,8(sp)
    80000926:	6105                	addi	sp,sp,32
    80000928:	8082                	ret
    pop_off();
    8000092a:	286000ef          	jal	ra,80000bb0 <pop_off>
}
    8000092e:	bfcd                	j	80000920 <uartputc_sync+0x4c>

0000000080000930 <uartgetc>:

// try to read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000930:	1141                	addi	sp,sp,-16
    80000932:	e422                	sd	s0,8(sp)
    80000934:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    80000936:	100007b7          	lui	a5,0x10000
    8000093a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000093e:	8b85                	andi	a5,a5,1
    80000940:	cb91                	beqz	a5,80000954 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000942:	100007b7          	lui	a5,0x10000
    80000946:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000094a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000094e:	6422                	ld	s0,8(sp)
    80000950:	0141                	addi	sp,sp,16
    80000952:	8082                	ret
    return -1;
    80000954:	557d                	li	a0,-1
    80000956:	bfe5                	j	8000094e <uartgetc+0x1e>

0000000080000958 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000958:	1101                	addi	sp,sp,-32
    8000095a:	ec06                	sd	ra,24(sp)
    8000095c:	e822                	sd	s0,16(sp)
    8000095e:	e426                	sd	s1,8(sp)
    80000960:	1000                	addi	s0,sp,32
  ReadReg(ISR); // acknowledge the interrupt
    80000962:	100004b7          	lui	s1,0x10000
    80000966:	0024c783          	lbu	a5,2(s1) # 10000002 <_entry-0x6ffffffe>

  acquire(&tx_lock);
    8000096a:	0000f517          	auipc	a0,0xf
    8000096e:	fc650513          	addi	a0,a0,-58 # 8000f930 <tx_lock>
    80000972:	1fa000ef          	jal	ra,80000b6c <acquire>
  if(ReadReg(LSR) & LSR_TX_IDLE){
    80000976:	0054c783          	lbu	a5,5(s1)
    8000097a:	0207f793          	andi	a5,a5,32
    8000097e:	eb89                	bnez	a5,80000990 <uartintr+0x38>
    // UART finished transmitting; wake up sending thread.
    tx_busy = 0;
    wakeup(&tx_chan);
  }
  release(&tx_lock);
    80000980:	0000f517          	auipc	a0,0xf
    80000984:	fb050513          	addi	a0,a0,-80 # 8000f930 <tx_lock>
    80000988:	27c000ef          	jal	ra,80000c04 <release>

  // read and process incoming characters, if any.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000098c:	54fd                	li	s1,-1
    8000098e:	a831                	j	800009aa <uartintr+0x52>
    tx_busy = 0;
    80000990:	00007797          	auipc	a5,0x7
    80000994:	ea07ae23          	sw	zero,-324(a5) # 8000784c <tx_busy>
    wakeup(&tx_chan);
    80000998:	00007517          	auipc	a0,0x7
    8000099c:	eb050513          	addi	a0,a0,-336 # 80007848 <tx_chan>
    800009a0:	4b8010ef          	jal	ra,80001e58 <wakeup>
    800009a4:	bff1                	j	80000980 <uartintr+0x28>
      break;
    consoleintr(c);
    800009a6:	8d5ff0ef          	jal	ra,8000027a <consoleintr>
    int c = uartgetc();
    800009aa:	f87ff0ef          	jal	ra,80000930 <uartgetc>
    if(c == -1)
    800009ae:	fe951ce3          	bne	a0,s1,800009a6 <uartintr+0x4e>
  }
}
    800009b2:	60e2                	ld	ra,24(sp)
    800009b4:	6442                	ld	s0,16(sp)
    800009b6:	64a2                	ld	s1,8(sp)
    800009b8:	6105                	addi	sp,sp,32
    800009ba:	8082                	ret

00000000800009bc <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009bc:	1101                	addi	sp,sp,-32
    800009be:	ec06                	sd	ra,24(sp)
    800009c0:	e822                	sd	s0,16(sp)
    800009c2:	e426                	sd	s1,8(sp)
    800009c4:	e04a                	sd	s2,0(sp)
    800009c6:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009c8:	03451793          	slli	a5,a0,0x34
    800009cc:	e7a9                	bnez	a5,80000a16 <kfree+0x5a>
    800009ce:	84aa                	mv	s1,a0
    800009d0:	00020797          	auipc	a5,0x20
    800009d4:	1a878793          	addi	a5,a5,424 # 80020b78 <end>
    800009d8:	02f56f63          	bltu	a0,a5,80000a16 <kfree+0x5a>
    800009dc:	47c5                	li	a5,17
    800009de:	07ee                	slli	a5,a5,0x1b
    800009e0:	02f57b63          	bgeu	a0,a5,80000a16 <kfree+0x5a>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009e4:	6605                	lui	a2,0x1
    800009e6:	4585                	li	a1,1
    800009e8:	258000ef          	jal	ra,80000c40 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    800009ec:	0000f917          	auipc	s2,0xf
    800009f0:	f5c90913          	addi	s2,s2,-164 # 8000f948 <kmem>
    800009f4:	854a                	mv	a0,s2
    800009f6:	176000ef          	jal	ra,80000b6c <acquire>
  r->next = kmem.freelist;
    800009fa:	01893783          	ld	a5,24(s2)
    800009fe:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a00:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a04:	854a                	mv	a0,s2
    80000a06:	1fe000ef          	jal	ra,80000c04 <release>
}
    80000a0a:	60e2                	ld	ra,24(sp)
    80000a0c:	6442                	ld	s0,16(sp)
    80000a0e:	64a2                	ld	s1,8(sp)
    80000a10:	6902                	ld	s2,0(sp)
    80000a12:	6105                	addi	sp,sp,32
    80000a14:	8082                	ret
    panic("kfree");
    80000a16:	00006517          	auipc	a0,0x6
    80000a1a:	64250513          	addi	a0,a0,1602 # 80007058 <digits+0x20>
    80000a1e:	d6dff0ef          	jal	ra,8000078a <panic>

0000000080000a22 <freerange>:
{
    80000a22:	7179                	addi	sp,sp,-48
    80000a24:	f406                	sd	ra,40(sp)
    80000a26:	f022                	sd	s0,32(sp)
    80000a28:	ec26                	sd	s1,24(sp)
    80000a2a:	e84a                	sd	s2,16(sp)
    80000a2c:	e44e                	sd	s3,8(sp)
    80000a2e:	e052                	sd	s4,0(sp)
    80000a30:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a32:	6785                	lui	a5,0x1
    80000a34:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a38:	94aa                	add	s1,s1,a0
    80000a3a:	757d                	lui	a0,0xfffff
    80000a3c:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a3e:	94be                	add	s1,s1,a5
    80000a40:	0095ec63          	bltu	a1,s1,80000a58 <freerange+0x36>
    80000a44:	892e                	mv	s2,a1
    kfree(p);
    80000a46:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a48:	6985                	lui	s3,0x1
    kfree(p);
    80000a4a:	01448533          	add	a0,s1,s4
    80000a4e:	f6fff0ef          	jal	ra,800009bc <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a52:	94ce                	add	s1,s1,s3
    80000a54:	fe997be3          	bgeu	s2,s1,80000a4a <freerange+0x28>
}
    80000a58:	70a2                	ld	ra,40(sp)
    80000a5a:	7402                	ld	s0,32(sp)
    80000a5c:	64e2                	ld	s1,24(sp)
    80000a5e:	6942                	ld	s2,16(sp)
    80000a60:	69a2                	ld	s3,8(sp)
    80000a62:	6a02                	ld	s4,0(sp)
    80000a64:	6145                	addi	sp,sp,48
    80000a66:	8082                	ret

0000000080000a68 <kinit>:
{
    80000a68:	1141                	addi	sp,sp,-16
    80000a6a:	e406                	sd	ra,8(sp)
    80000a6c:	e022                	sd	s0,0(sp)
    80000a6e:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a70:	00006597          	auipc	a1,0x6
    80000a74:	5f058593          	addi	a1,a1,1520 # 80007060 <digits+0x28>
    80000a78:	0000f517          	auipc	a0,0xf
    80000a7c:	ed050513          	addi	a0,a0,-304 # 8000f948 <kmem>
    80000a80:	06c000ef          	jal	ra,80000aec <initlock>
  freerange(end, (void*)PHYSTOP);
    80000a84:	45c5                	li	a1,17
    80000a86:	05ee                	slli	a1,a1,0x1b
    80000a88:	00020517          	auipc	a0,0x20
    80000a8c:	0f050513          	addi	a0,a0,240 # 80020b78 <end>
    80000a90:	f93ff0ef          	jal	ra,80000a22 <freerange>
}
    80000a94:	60a2                	ld	ra,8(sp)
    80000a96:	6402                	ld	s0,0(sp)
    80000a98:	0141                	addi	sp,sp,16
    80000a9a:	8082                	ret

0000000080000a9c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000a9c:	1101                	addi	sp,sp,-32
    80000a9e:	ec06                	sd	ra,24(sp)
    80000aa0:	e822                	sd	s0,16(sp)
    80000aa2:	e426                	sd	s1,8(sp)
    80000aa4:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aa6:	0000f497          	auipc	s1,0xf
    80000aaa:	ea248493          	addi	s1,s1,-350 # 8000f948 <kmem>
    80000aae:	8526                	mv	a0,s1
    80000ab0:	0bc000ef          	jal	ra,80000b6c <acquire>
  r = kmem.freelist;
    80000ab4:	6c84                	ld	s1,24(s1)
  if(r)
    80000ab6:	c485                	beqz	s1,80000ade <kalloc+0x42>
    kmem.freelist = r->next;
    80000ab8:	609c                	ld	a5,0(s1)
    80000aba:	0000f517          	auipc	a0,0xf
    80000abe:	e8e50513          	addi	a0,a0,-370 # 8000f948 <kmem>
    80000ac2:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000ac4:	140000ef          	jal	ra,80000c04 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000ac8:	6605                	lui	a2,0x1
    80000aca:	4595                	li	a1,5
    80000acc:	8526                	mv	a0,s1
    80000ace:	172000ef          	jal	ra,80000c40 <memset>
  return (void*)r;
}
    80000ad2:	8526                	mv	a0,s1
    80000ad4:	60e2                	ld	ra,24(sp)
    80000ad6:	6442                	ld	s0,16(sp)
    80000ad8:	64a2                	ld	s1,8(sp)
    80000ada:	6105                	addi	sp,sp,32
    80000adc:	8082                	ret
  release(&kmem.lock);
    80000ade:	0000f517          	auipc	a0,0xf
    80000ae2:	e6a50513          	addi	a0,a0,-406 # 8000f948 <kmem>
    80000ae6:	11e000ef          	jal	ra,80000c04 <release>
  if(r)
    80000aea:	b7e5                	j	80000ad2 <kalloc+0x36>

0000000080000aec <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000aec:	1141                	addi	sp,sp,-16
    80000aee:	e422                	sd	s0,8(sp)
    80000af0:	0800                	addi	s0,sp,16
  lk->name = name;
    80000af2:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000af4:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000af8:	00053823          	sd	zero,16(a0)
}
    80000afc:	6422                	ld	s0,8(sp)
    80000afe:	0141                	addi	sp,sp,16
    80000b00:	8082                	ret

0000000080000b02 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b02:	411c                	lw	a5,0(a0)
    80000b04:	e399                	bnez	a5,80000b0a <holding+0x8>
    80000b06:	4501                	li	a0,0
  return r;
}
    80000b08:	8082                	ret
{
    80000b0a:	1101                	addi	sp,sp,-32
    80000b0c:	ec06                	sd	ra,24(sp)
    80000b0e:	e822                	sd	s0,16(sp)
    80000b10:	e426                	sd	s1,8(sp)
    80000b12:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b14:	6904                	ld	s1,16(a0)
    80000b16:	4d3000ef          	jal	ra,800017e8 <mycpu>
    80000b1a:	40a48533          	sub	a0,s1,a0
    80000b1e:	00153513          	seqz	a0,a0
}
    80000b22:	60e2                	ld	ra,24(sp)
    80000b24:	6442                	ld	s0,16(sp)
    80000b26:	64a2                	ld	s1,8(sp)
    80000b28:	6105                	addi	sp,sp,32
    80000b2a:	8082                	ret

0000000080000b2c <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b2c:	1101                	addi	sp,sp,-32
    80000b2e:	ec06                	sd	ra,24(sp)
    80000b30:	e822                	sd	s0,16(sp)
    80000b32:	e426                	sd	s1,8(sp)
    80000b34:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b36:	100024f3          	csrr	s1,sstatus
    80000b3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b3e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b40:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80000b44:	4a5000ef          	jal	ra,800017e8 <mycpu>
    80000b48:	5d3c                	lw	a5,120(a0)
    80000b4a:	cb99                	beqz	a5,80000b60 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b4c:	49d000ef          	jal	ra,800017e8 <mycpu>
    80000b50:	5d3c                	lw	a5,120(a0)
    80000b52:	2785                	addiw	a5,a5,1
    80000b54:	dd3c                	sw	a5,120(a0)
}
    80000b56:	60e2                	ld	ra,24(sp)
    80000b58:	6442                	ld	s0,16(sp)
    80000b5a:	64a2                	ld	s1,8(sp)
    80000b5c:	6105                	addi	sp,sp,32
    80000b5e:	8082                	ret
    mycpu()->intena = old;
    80000b60:	489000ef          	jal	ra,800017e8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000b64:	8085                	srli	s1,s1,0x1
    80000b66:	8885                	andi	s1,s1,1
    80000b68:	dd64                	sw	s1,124(a0)
    80000b6a:	b7cd                	j	80000b4c <push_off+0x20>

0000000080000b6c <acquire>:
{
    80000b6c:	1101                	addi	sp,sp,-32
    80000b6e:	ec06                	sd	ra,24(sp)
    80000b70:	e822                	sd	s0,16(sp)
    80000b72:	e426                	sd	s1,8(sp)
    80000b74:	1000                	addi	s0,sp,32
    80000b76:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000b78:	fb5ff0ef          	jal	ra,80000b2c <push_off>
  if(holding(lk))
    80000b7c:	8526                	mv	a0,s1
    80000b7e:	f85ff0ef          	jal	ra,80000b02 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000b82:	4705                	li	a4,1
  if(holding(lk))
    80000b84:	e105                	bnez	a0,80000ba4 <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000b86:	87ba                	mv	a5,a4
    80000b88:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000b8c:	2781                	sext.w	a5,a5
    80000b8e:	ffe5                	bnez	a5,80000b86 <acquire+0x1a>
  __sync_synchronize();
    80000b90:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000b94:	455000ef          	jal	ra,800017e8 <mycpu>
    80000b98:	e888                	sd	a0,16(s1)
}
    80000b9a:	60e2                	ld	ra,24(sp)
    80000b9c:	6442                	ld	s0,16(sp)
    80000b9e:	64a2                	ld	s1,8(sp)
    80000ba0:	6105                	addi	sp,sp,32
    80000ba2:	8082                	ret
    panic("acquire");
    80000ba4:	00006517          	auipc	a0,0x6
    80000ba8:	4c450513          	addi	a0,a0,1220 # 80007068 <digits+0x30>
    80000bac:	bdfff0ef          	jal	ra,8000078a <panic>

0000000080000bb0 <pop_off>:

void
pop_off(void)
{
    80000bb0:	1141                	addi	sp,sp,-16
    80000bb2:	e406                	sd	ra,8(sp)
    80000bb4:	e022                	sd	s0,0(sp)
    80000bb6:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000bb8:	431000ef          	jal	ra,800017e8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bbc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000bc0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000bc2:	e78d                	bnez	a5,80000bec <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	02f05963          	blez	a5,80000bf8 <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    80000bca:	37fd                	addiw	a5,a5,-1
    80000bcc:	0007871b          	sext.w	a4,a5
    80000bd0:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000bd2:	eb09                	bnez	a4,80000be4 <pop_off+0x34>
    80000bd4:	5d7c                	lw	a5,124(a0)
    80000bd6:	c799                	beqz	a5,80000be4 <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bd8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000bdc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000be0:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000be4:	60a2                	ld	ra,8(sp)
    80000be6:	6402                	ld	s0,0(sp)
    80000be8:	0141                	addi	sp,sp,16
    80000bea:	8082                	ret
    panic("pop_off - interruptible");
    80000bec:	00006517          	auipc	a0,0x6
    80000bf0:	48450513          	addi	a0,a0,1156 # 80007070 <digits+0x38>
    80000bf4:	b97ff0ef          	jal	ra,8000078a <panic>
    panic("pop_off");
    80000bf8:	00006517          	auipc	a0,0x6
    80000bfc:	49050513          	addi	a0,a0,1168 # 80007088 <digits+0x50>
    80000c00:	b8bff0ef          	jal	ra,8000078a <panic>

0000000080000c04 <release>:
{
    80000c04:	1101                	addi	sp,sp,-32
    80000c06:	ec06                	sd	ra,24(sp)
    80000c08:	e822                	sd	s0,16(sp)
    80000c0a:	e426                	sd	s1,8(sp)
    80000c0c:	1000                	addi	s0,sp,32
    80000c0e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c10:	ef3ff0ef          	jal	ra,80000b02 <holding>
    80000c14:	c105                	beqz	a0,80000c34 <release+0x30>
  lk->cpu = 0;
    80000c16:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c1a:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c1e:	0f50000f          	fence	iorw,ow
    80000c22:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c26:	f8bff0ef          	jal	ra,80000bb0 <pop_off>
}
    80000c2a:	60e2                	ld	ra,24(sp)
    80000c2c:	6442                	ld	s0,16(sp)
    80000c2e:	64a2                	ld	s1,8(sp)
    80000c30:	6105                	addi	sp,sp,32
    80000c32:	8082                	ret
    panic("release");
    80000c34:	00006517          	auipc	a0,0x6
    80000c38:	45c50513          	addi	a0,a0,1116 # 80007090 <digits+0x58>
    80000c3c:	b4fff0ef          	jal	ra,8000078a <panic>

0000000080000c40 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000c40:	1141                	addi	sp,sp,-16
    80000c42:	e422                	sd	s0,8(sp)
    80000c44:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000c46:	ca19                	beqz	a2,80000c5c <memset+0x1c>
    80000c48:	87aa                	mv	a5,a0
    80000c4a:	1602                	slli	a2,a2,0x20
    80000c4c:	9201                	srli	a2,a2,0x20
    80000c4e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000c52:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000c56:	0785                	addi	a5,a5,1
    80000c58:	fee79de3          	bne	a5,a4,80000c52 <memset+0x12>
  }
  return dst;
}
    80000c5c:	6422                	ld	s0,8(sp)
    80000c5e:	0141                	addi	sp,sp,16
    80000c60:	8082                	ret

0000000080000c62 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000c62:	1141                	addi	sp,sp,-16
    80000c64:	e422                	sd	s0,8(sp)
    80000c66:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000c68:	ca05                	beqz	a2,80000c98 <memcmp+0x36>
    80000c6a:	fff6069b          	addiw	a3,a2,-1
    80000c6e:	1682                	slli	a3,a3,0x20
    80000c70:	9281                	srli	a3,a3,0x20
    80000c72:	0685                	addi	a3,a3,1
    80000c74:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000c76:	00054783          	lbu	a5,0(a0)
    80000c7a:	0005c703          	lbu	a4,0(a1)
    80000c7e:	00e79863          	bne	a5,a4,80000c8e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000c82:	0505                	addi	a0,a0,1
    80000c84:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000c86:	fed518e3          	bne	a0,a3,80000c76 <memcmp+0x14>
  }

  return 0;
    80000c8a:	4501                	li	a0,0
    80000c8c:	a019                	j	80000c92 <memcmp+0x30>
      return *s1 - *s2;
    80000c8e:	40e7853b          	subw	a0,a5,a4
}
    80000c92:	6422                	ld	s0,8(sp)
    80000c94:	0141                	addi	sp,sp,16
    80000c96:	8082                	ret
  return 0;
    80000c98:	4501                	li	a0,0
    80000c9a:	bfe5                	j	80000c92 <memcmp+0x30>

0000000080000c9c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000c9c:	1141                	addi	sp,sp,-16
    80000c9e:	e422                	sd	s0,8(sp)
    80000ca0:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000ca2:	c205                	beqz	a2,80000cc2 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000ca4:	02a5e263          	bltu	a1,a0,80000cc8 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000ca8:	1602                	slli	a2,a2,0x20
    80000caa:	9201                	srli	a2,a2,0x20
    80000cac:	00c587b3          	add	a5,a1,a2
{
    80000cb0:	872a                	mv	a4,a0
      *d++ = *s++;
    80000cb2:	0585                	addi	a1,a1,1
    80000cb4:	0705                	addi	a4,a4,1
    80000cb6:	fff5c683          	lbu	a3,-1(a1)
    80000cba:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000cbe:	fef59ae3          	bne	a1,a5,80000cb2 <memmove+0x16>

  return dst;
}
    80000cc2:	6422                	ld	s0,8(sp)
    80000cc4:	0141                	addi	sp,sp,16
    80000cc6:	8082                	ret
  if(s < d && s + n > d){
    80000cc8:	02061693          	slli	a3,a2,0x20
    80000ccc:	9281                	srli	a3,a3,0x20
    80000cce:	00d58733          	add	a4,a1,a3
    80000cd2:	fce57be3          	bgeu	a0,a4,80000ca8 <memmove+0xc>
    d += n;
    80000cd6:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000cd8:	fff6079b          	addiw	a5,a2,-1
    80000cdc:	1782                	slli	a5,a5,0x20
    80000cde:	9381                	srli	a5,a5,0x20
    80000ce0:	fff7c793          	not	a5,a5
    80000ce4:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000ce6:	177d                	addi	a4,a4,-1
    80000ce8:	16fd                	addi	a3,a3,-1
    80000cea:	00074603          	lbu	a2,0(a4)
    80000cee:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000cf2:	fee79ae3          	bne	a5,a4,80000ce6 <memmove+0x4a>
    80000cf6:	b7f1                	j	80000cc2 <memmove+0x26>

0000000080000cf8 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000cf8:	1141                	addi	sp,sp,-16
    80000cfa:	e406                	sd	ra,8(sp)
    80000cfc:	e022                	sd	s0,0(sp)
    80000cfe:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d00:	f9dff0ef          	jal	ra,80000c9c <memmove>
}
    80000d04:	60a2                	ld	ra,8(sp)
    80000d06:	6402                	ld	s0,0(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d12:	ce11                	beqz	a2,80000d2e <strncmp+0x22>
    80000d14:	00054783          	lbu	a5,0(a0)
    80000d18:	cf89                	beqz	a5,80000d32 <strncmp+0x26>
    80000d1a:	0005c703          	lbu	a4,0(a1)
    80000d1e:	00f71a63          	bne	a4,a5,80000d32 <strncmp+0x26>
    n--, p++, q++;
    80000d22:	367d                	addiw	a2,a2,-1
    80000d24:	0505                	addi	a0,a0,1
    80000d26:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000d28:	f675                	bnez	a2,80000d14 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	a809                	j	80000d3e <strncmp+0x32>
    80000d2e:	4501                	li	a0,0
    80000d30:	a039                	j	80000d3e <strncmp+0x32>
  if(n == 0)
    80000d32:	ca09                	beqz	a2,80000d44 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000d34:	00054503          	lbu	a0,0(a0)
    80000d38:	0005c783          	lbu	a5,0(a1)
    80000d3c:	9d1d                	subw	a0,a0,a5
}
    80000d3e:	6422                	ld	s0,8(sp)
    80000d40:	0141                	addi	sp,sp,16
    80000d42:	8082                	ret
    return 0;
    80000d44:	4501                	li	a0,0
    80000d46:	bfe5                	j	80000d3e <strncmp+0x32>

0000000080000d48 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000d48:	1141                	addi	sp,sp,-16
    80000d4a:	e422                	sd	s0,8(sp)
    80000d4c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000d4e:	872a                	mv	a4,a0
    80000d50:	8832                	mv	a6,a2
    80000d52:	367d                	addiw	a2,a2,-1
    80000d54:	01005963          	blez	a6,80000d66 <strncpy+0x1e>
    80000d58:	0705                	addi	a4,a4,1
    80000d5a:	0005c783          	lbu	a5,0(a1)
    80000d5e:	fef70fa3          	sb	a5,-1(a4)
    80000d62:	0585                	addi	a1,a1,1
    80000d64:	f7f5                	bnez	a5,80000d50 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000d66:	86ba                	mv	a3,a4
    80000d68:	00c05c63          	blez	a2,80000d80 <strncpy+0x38>
    *s++ = 0;
    80000d6c:	0685                	addi	a3,a3,1
    80000d6e:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000d72:	fff6c793          	not	a5,a3
    80000d76:	9fb9                	addw	a5,a5,a4
    80000d78:	010787bb          	addw	a5,a5,a6
    80000d7c:	fef048e3          	bgtz	a5,80000d6c <strncpy+0x24>
  return os;
}
    80000d80:	6422                	ld	s0,8(sp)
    80000d82:	0141                	addi	sp,sp,16
    80000d84:	8082                	ret

0000000080000d86 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000d86:	1141                	addi	sp,sp,-16
    80000d88:	e422                	sd	s0,8(sp)
    80000d8a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000d8c:	02c05363          	blez	a2,80000db2 <safestrcpy+0x2c>
    80000d90:	fff6069b          	addiw	a3,a2,-1
    80000d94:	1682                	slli	a3,a3,0x20
    80000d96:	9281                	srli	a3,a3,0x20
    80000d98:	96ae                	add	a3,a3,a1
    80000d9a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000d9c:	00d58963          	beq	a1,a3,80000dae <safestrcpy+0x28>
    80000da0:	0585                	addi	a1,a1,1
    80000da2:	0785                	addi	a5,a5,1
    80000da4:	fff5c703          	lbu	a4,-1(a1)
    80000da8:	fee78fa3          	sb	a4,-1(a5)
    80000dac:	fb65                	bnez	a4,80000d9c <safestrcpy+0x16>
    ;
  *s = 0;
    80000dae:	00078023          	sb	zero,0(a5)
  return os;
}
    80000db2:	6422                	ld	s0,8(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strlen>:

int
strlen(const char *s)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000dbe:	00054783          	lbu	a5,0(a0)
    80000dc2:	cf91                	beqz	a5,80000dde <strlen+0x26>
    80000dc4:	0505                	addi	a0,a0,1
    80000dc6:	87aa                	mv	a5,a0
    80000dc8:	4685                	li	a3,1
    80000dca:	9e89                	subw	a3,a3,a0
    80000dcc:	00f6853b          	addw	a0,a3,a5
    80000dd0:	0785                	addi	a5,a5,1
    80000dd2:	fff7c703          	lbu	a4,-1(a5)
    80000dd6:	fb7d                	bnez	a4,80000dcc <strlen+0x14>
    ;
  return n;
}
    80000dd8:	6422                	ld	s0,8(sp)
    80000dda:	0141                	addi	sp,sp,16
    80000ddc:	8082                	ret
  for(n = 0; s[n]; n++)
    80000dde:	4501                	li	a0,0
    80000de0:	bfe5                	j	80000dd8 <strlen+0x20>

0000000080000de2 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000de2:	1141                	addi	sp,sp,-16
    80000de4:	e406                	sd	ra,8(sp)
    80000de6:	e022                	sd	s0,0(sp)
    80000de8:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000dea:	1ef000ef          	jal	ra,800017d8 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000dee:	00007717          	auipc	a4,0x7
    80000df2:	a6270713          	addi	a4,a4,-1438 # 80007850 <started>
  if(cpuid() == 0){
    80000df6:	c51d                	beqz	a0,80000e24 <main+0x42>
    while(started == 0)
    80000df8:	431c                	lw	a5,0(a4)
    80000dfa:	2781                	sext.w	a5,a5
    80000dfc:	dff5                	beqz	a5,80000df8 <main+0x16>
      ;
    __sync_synchronize();
    80000dfe:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e02:	1d7000ef          	jal	ra,800017d8 <cpuid>
    80000e06:	85aa                	mv	a1,a0
    80000e08:	00006517          	auipc	a0,0x6
    80000e0c:	2a850513          	addi	a0,a0,680 # 800070b0 <digits+0x78>
    80000e10:	eb4ff0ef          	jal	ra,800004c4 <printf>
    kvminithart();    // turn on paging
    80000e14:	080000ef          	jal	ra,80000e94 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000e18:	5ae010ef          	jal	ra,800023c6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000e1c:	498040ef          	jal	ra,800052b4 <plicinithart>
  }

  scheduler();        
    80000e20:	655000ef          	jal	ra,80001c74 <scheduler>
    consoleinit();
    80000e24:	dc8ff0ef          	jal	ra,800003ec <consoleinit>
    printfinit();
    80000e28:	99fff0ef          	jal	ra,800007c6 <printfinit>
    printf("\n");
    80000e2c:	00006517          	auipc	a0,0x6
    80000e30:	29450513          	addi	a0,a0,660 # 800070c0 <digits+0x88>
    80000e34:	e90ff0ef          	jal	ra,800004c4 <printf>
    printf("xv6 kernel is booting\n");
    80000e38:	00006517          	auipc	a0,0x6
    80000e3c:	26050513          	addi	a0,a0,608 # 80007098 <digits+0x60>
    80000e40:	e84ff0ef          	jal	ra,800004c4 <printf>
    printf("\n");
    80000e44:	00006517          	auipc	a0,0x6
    80000e48:	27c50513          	addi	a0,a0,636 # 800070c0 <digits+0x88>
    80000e4c:	e78ff0ef          	jal	ra,800004c4 <printf>
    kinit();         // physical page allocator
    80000e50:	c19ff0ef          	jal	ra,80000a68 <kinit>
    kvminit();       // create kernel page table
    80000e54:	2ca000ef          	jal	ra,8000111e <kvminit>
    kvminithart();   // turn on paging
    80000e58:	03c000ef          	jal	ra,80000e94 <kvminithart>
    procinit();      // process table
    80000e5c:	0d5000ef          	jal	ra,80001730 <procinit>
    trapinit();      // trap vectors
    80000e60:	542010ef          	jal	ra,800023a2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000e64:	562010ef          	jal	ra,800023c6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000e68:	436040ef          	jal	ra,8000529e <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000e6c:	448040ef          	jal	ra,800052b4 <plicinithart>
    binit();         // buffer cache
    80000e70:	3e5010ef          	jal	ra,80002a54 <binit>
    iinit();         // inode table
    80000e74:	158020ef          	jal	ra,80002fcc <iinit>
    fileinit();      // file table
    80000e78:	038030ef          	jal	ra,80003eb0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000e7c:	528040ef          	jal	ra,800053a4 <virtio_disk_init>
    userinit();      // first user process
    80000e80:	44b000ef          	jal	ra,80001aca <userinit>
    __sync_synchronize();
    80000e84:	0ff0000f          	fence
    started = 1;
    80000e88:	4785                	li	a5,1
    80000e8a:	00007717          	auipc	a4,0x7
    80000e8e:	9cf72323          	sw	a5,-1594(a4) # 80007850 <started>
    80000e92:	b779                	j	80000e20 <main+0x3e>

0000000080000e94 <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000e9a:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000e9e:	00007797          	auipc	a5,0x7
    80000ea2:	9ba7b783          	ld	a5,-1606(a5) # 80007858 <kernel_pagetable>
    80000ea6:	83b1                	srli	a5,a5,0xc
    80000ea8:	577d                	li	a4,-1
    80000eaa:	177e                	slli	a4,a4,0x3f
    80000eac:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000eae:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000eb2:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000eb6:	6422                	ld	s0,8(sp)
    80000eb8:	0141                	addi	sp,sp,16
    80000eba:	8082                	ret

0000000080000ebc <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000ebc:	7139                	addi	sp,sp,-64
    80000ebe:	fc06                	sd	ra,56(sp)
    80000ec0:	f822                	sd	s0,48(sp)
    80000ec2:	f426                	sd	s1,40(sp)
    80000ec4:	f04a                	sd	s2,32(sp)
    80000ec6:	ec4e                	sd	s3,24(sp)
    80000ec8:	e852                	sd	s4,16(sp)
    80000eca:	e456                	sd	s5,8(sp)
    80000ecc:	e05a                	sd	s6,0(sp)
    80000ece:	0080                	addi	s0,sp,64
    80000ed0:	84aa                	mv	s1,a0
    80000ed2:	89ae                	mv	s3,a1
    80000ed4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000ed6:	57fd                	li	a5,-1
    80000ed8:	83e9                	srli	a5,a5,0x1a
    80000eda:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000edc:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ede:	02b7fc63          	bgeu	a5,a1,80000f16 <walk+0x5a>
    panic("walk");
    80000ee2:	00006517          	auipc	a0,0x6
    80000ee6:	1e650513          	addi	a0,a0,486 # 800070c8 <digits+0x90>
    80000eea:	8a1ff0ef          	jal	ra,8000078a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000eee:	060a8263          	beqz	s5,80000f52 <walk+0x96>
    80000ef2:	babff0ef          	jal	ra,80000a9c <kalloc>
    80000ef6:	84aa                	mv	s1,a0
    80000ef8:	c139                	beqz	a0,80000f3e <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000efa:	6605                	lui	a2,0x1
    80000efc:	4581                	li	a1,0
    80000efe:	d43ff0ef          	jal	ra,80000c40 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000f02:	00c4d793          	srli	a5,s1,0xc
    80000f06:	07aa                	slli	a5,a5,0xa
    80000f08:	0017e793          	ori	a5,a5,1
    80000f0c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000f10:	3a5d                	addiw	s4,s4,-9
    80000f12:	036a0063          	beq	s4,s6,80000f32 <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    80000f16:	0149d933          	srl	s2,s3,s4
    80000f1a:	1ff97913          	andi	s2,s2,511
    80000f1e:	090e                	slli	s2,s2,0x3
    80000f20:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000f22:	00093483          	ld	s1,0(s2)
    80000f26:	0014f793          	andi	a5,s1,1
    80000f2a:	d3f1                	beqz	a5,80000eee <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000f2c:	80a9                	srli	s1,s1,0xa
    80000f2e:	04b2                	slli	s1,s1,0xc
    80000f30:	b7c5                	j	80000f10 <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    80000f32:	00c9d513          	srli	a0,s3,0xc
    80000f36:	1ff57513          	andi	a0,a0,511
    80000f3a:	050e                	slli	a0,a0,0x3
    80000f3c:	9526                	add	a0,a0,s1
}
    80000f3e:	70e2                	ld	ra,56(sp)
    80000f40:	7442                	ld	s0,48(sp)
    80000f42:	74a2                	ld	s1,40(sp)
    80000f44:	7902                	ld	s2,32(sp)
    80000f46:	69e2                	ld	s3,24(sp)
    80000f48:	6a42                	ld	s4,16(sp)
    80000f4a:	6aa2                	ld	s5,8(sp)
    80000f4c:	6b02                	ld	s6,0(sp)
    80000f4e:	6121                	addi	sp,sp,64
    80000f50:	8082                	ret
        return 0;
    80000f52:	4501                	li	a0,0
    80000f54:	b7ed                	j	80000f3e <walk+0x82>

0000000080000f56 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80000f56:	57fd                	li	a5,-1
    80000f58:	83e9                	srli	a5,a5,0x1a
    80000f5a:	00b7f463          	bgeu	a5,a1,80000f62 <walkaddr+0xc>
    return 0;
    80000f5e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80000f60:	8082                	ret
{
    80000f62:	1141                	addi	sp,sp,-16
    80000f64:	e406                	sd	ra,8(sp)
    80000f66:	e022                	sd	s0,0(sp)
    80000f68:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000f6a:	4601                	li	a2,0
    80000f6c:	f51ff0ef          	jal	ra,80000ebc <walk>
  if(pte == 0)
    80000f70:	c105                	beqz	a0,80000f90 <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    80000f72:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80000f74:	0117f693          	andi	a3,a5,17
    80000f78:	4745                	li	a4,17
    return 0;
    80000f7a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80000f7c:	00e68663          	beq	a3,a4,80000f88 <walkaddr+0x32>
}
    80000f80:	60a2                	ld	ra,8(sp)
    80000f82:	6402                	ld	s0,0(sp)
    80000f84:	0141                	addi	sp,sp,16
    80000f86:	8082                	ret
  pa = PTE2PA(*pte);
    80000f88:	00a7d513          	srli	a0,a5,0xa
    80000f8c:	0532                	slli	a0,a0,0xc
  return pa;
    80000f8e:	bfcd                	j	80000f80 <walkaddr+0x2a>
    return 0;
    80000f90:	4501                	li	a0,0
    80000f92:	b7fd                	j	80000f80 <walkaddr+0x2a>

0000000080000f94 <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80000f94:	715d                	addi	sp,sp,-80
    80000f96:	e486                	sd	ra,72(sp)
    80000f98:	e0a2                	sd	s0,64(sp)
    80000f9a:	fc26                	sd	s1,56(sp)
    80000f9c:	f84a                	sd	s2,48(sp)
    80000f9e:	f44e                	sd	s3,40(sp)
    80000fa0:	f052                	sd	s4,32(sp)
    80000fa2:	ec56                	sd	s5,24(sp)
    80000fa4:	e85a                	sd	s6,16(sp)
    80000fa6:	e45e                	sd	s7,8(sp)
    80000fa8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80000faa:	03459793          	slli	a5,a1,0x34
    80000fae:	e7a9                	bnez	a5,80000ff8 <mappages+0x64>
    80000fb0:	8aaa                	mv	s5,a0
    80000fb2:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    80000fb4:	03461793          	slli	a5,a2,0x34
    80000fb8:	e7b1                	bnez	a5,80001004 <mappages+0x70>
    panic("mappages: size not aligned");

  if(size == 0)
    80000fba:	ca39                	beqz	a2,80001010 <mappages+0x7c>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    80000fbc:	79fd                	lui	s3,0xfffff
    80000fbe:	964e                	add	a2,a2,s3
    80000fc0:	00b609b3          	add	s3,a2,a1
  a = va;
    80000fc4:	892e                	mv	s2,a1
    80000fc6:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80000fca:	6b85                	lui	s7,0x1
    80000fcc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80000fd0:	4605                	li	a2,1
    80000fd2:	85ca                	mv	a1,s2
    80000fd4:	8556                	mv	a0,s5
    80000fd6:	ee7ff0ef          	jal	ra,80000ebc <walk>
    80000fda:	c539                	beqz	a0,80001028 <mappages+0x94>
    if(*pte & PTE_V)
    80000fdc:	611c                	ld	a5,0(a0)
    80000fde:	8b85                	andi	a5,a5,1
    80000fe0:	ef95                	bnez	a5,8000101c <mappages+0x88>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80000fe2:	80b1                	srli	s1,s1,0xc
    80000fe4:	04aa                	slli	s1,s1,0xa
    80000fe6:	0164e4b3          	or	s1,s1,s6
    80000fea:	0014e493          	ori	s1,s1,1
    80000fee:	e104                	sd	s1,0(a0)
    if(a == last)
    80000ff0:	05390863          	beq	s2,s3,80001040 <mappages+0xac>
    a += PGSIZE;
    80000ff4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80000ff6:	bfd9                	j	80000fcc <mappages+0x38>
    panic("mappages: va not aligned");
    80000ff8:	00006517          	auipc	a0,0x6
    80000ffc:	0d850513          	addi	a0,a0,216 # 800070d0 <digits+0x98>
    80001000:	f8aff0ef          	jal	ra,8000078a <panic>
    panic("mappages: size not aligned");
    80001004:	00006517          	auipc	a0,0x6
    80001008:	0ec50513          	addi	a0,a0,236 # 800070f0 <digits+0xb8>
    8000100c:	f7eff0ef          	jal	ra,8000078a <panic>
    panic("mappages: size");
    80001010:	00006517          	auipc	a0,0x6
    80001014:	10050513          	addi	a0,a0,256 # 80007110 <digits+0xd8>
    80001018:	f72ff0ef          	jal	ra,8000078a <panic>
      panic("mappages: remap");
    8000101c:	00006517          	auipc	a0,0x6
    80001020:	10450513          	addi	a0,a0,260 # 80007120 <digits+0xe8>
    80001024:	f66ff0ef          	jal	ra,8000078a <panic>
      return -1;
    80001028:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000102a:	60a6                	ld	ra,72(sp)
    8000102c:	6406                	ld	s0,64(sp)
    8000102e:	74e2                	ld	s1,56(sp)
    80001030:	7942                	ld	s2,48(sp)
    80001032:	79a2                	ld	s3,40(sp)
    80001034:	7a02                	ld	s4,32(sp)
    80001036:	6ae2                	ld	s5,24(sp)
    80001038:	6b42                	ld	s6,16(sp)
    8000103a:	6ba2                	ld	s7,8(sp)
    8000103c:	6161                	addi	sp,sp,80
    8000103e:	8082                	ret
  return 0;
    80001040:	4501                	li	a0,0
    80001042:	b7e5                	j	8000102a <mappages+0x96>

0000000080001044 <kvmmap>:
{
    80001044:	1141                	addi	sp,sp,-16
    80001046:	e406                	sd	ra,8(sp)
    80001048:	e022                	sd	s0,0(sp)
    8000104a:	0800                	addi	s0,sp,16
    8000104c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000104e:	86b2                	mv	a3,a2
    80001050:	863e                	mv	a2,a5
    80001052:	f43ff0ef          	jal	ra,80000f94 <mappages>
    80001056:	e509                	bnez	a0,80001060 <kvmmap+0x1c>
}
    80001058:	60a2                	ld	ra,8(sp)
    8000105a:	6402                	ld	s0,0(sp)
    8000105c:	0141                	addi	sp,sp,16
    8000105e:	8082                	ret
    panic("kvmmap");
    80001060:	00006517          	auipc	a0,0x6
    80001064:	0d050513          	addi	a0,a0,208 # 80007130 <digits+0xf8>
    80001068:	f22ff0ef          	jal	ra,8000078a <panic>

000000008000106c <kvmmake>:
{
    8000106c:	1101                	addi	sp,sp,-32
    8000106e:	ec06                	sd	ra,24(sp)
    80001070:	e822                	sd	s0,16(sp)
    80001072:	e426                	sd	s1,8(sp)
    80001074:	e04a                	sd	s2,0(sp)
    80001076:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001078:	a25ff0ef          	jal	ra,80000a9c <kalloc>
    8000107c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000107e:	6605                	lui	a2,0x1
    80001080:	4581                	li	a1,0
    80001082:	bbfff0ef          	jal	ra,80000c40 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001086:	4719                	li	a4,6
    80001088:	6685                	lui	a3,0x1
    8000108a:	10000637          	lui	a2,0x10000
    8000108e:	100005b7          	lui	a1,0x10000
    80001092:	8526                	mv	a0,s1
    80001094:	fb1ff0ef          	jal	ra,80001044 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001098:	4719                	li	a4,6
    8000109a:	6685                	lui	a3,0x1
    8000109c:	10001637          	lui	a2,0x10001
    800010a0:	100015b7          	lui	a1,0x10001
    800010a4:	8526                	mv	a0,s1
    800010a6:	f9fff0ef          	jal	ra,80001044 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    800010aa:	4719                	li	a4,6
    800010ac:	040006b7          	lui	a3,0x4000
    800010b0:	0c000637          	lui	a2,0xc000
    800010b4:	0c0005b7          	lui	a1,0xc000
    800010b8:	8526                	mv	a0,s1
    800010ba:	f8bff0ef          	jal	ra,80001044 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800010be:	00006917          	auipc	s2,0x6
    800010c2:	f4290913          	addi	s2,s2,-190 # 80007000 <etext>
    800010c6:	4729                	li	a4,10
    800010c8:	80006697          	auipc	a3,0x80006
    800010cc:	f3868693          	addi	a3,a3,-200 # 7000 <_entry-0x7fff9000>
    800010d0:	4605                	li	a2,1
    800010d2:	067e                	slli	a2,a2,0x1f
    800010d4:	85b2                	mv	a1,a2
    800010d6:	8526                	mv	a0,s1
    800010d8:	f6dff0ef          	jal	ra,80001044 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800010dc:	4719                	li	a4,6
    800010de:	46c5                	li	a3,17
    800010e0:	06ee                	slli	a3,a3,0x1b
    800010e2:	412686b3          	sub	a3,a3,s2
    800010e6:	864a                	mv	a2,s2
    800010e8:	85ca                	mv	a1,s2
    800010ea:	8526                	mv	a0,s1
    800010ec:	f59ff0ef          	jal	ra,80001044 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800010f0:	4729                	li	a4,10
    800010f2:	6685                	lui	a3,0x1
    800010f4:	00005617          	auipc	a2,0x5
    800010f8:	f0c60613          	addi	a2,a2,-244 # 80006000 <_trampoline>
    800010fc:	040005b7          	lui	a1,0x4000
    80001100:	15fd                	addi	a1,a1,-1
    80001102:	05b2                	slli	a1,a1,0xc
    80001104:	8526                	mv	a0,s1
    80001106:	f3fff0ef          	jal	ra,80001044 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000110a:	8526                	mv	a0,s1
    8000110c:	59a000ef          	jal	ra,800016a6 <proc_mapstacks>
}
    80001110:	8526                	mv	a0,s1
    80001112:	60e2                	ld	ra,24(sp)
    80001114:	6442                	ld	s0,16(sp)
    80001116:	64a2                	ld	s1,8(sp)
    80001118:	6902                	ld	s2,0(sp)
    8000111a:	6105                	addi	sp,sp,32
    8000111c:	8082                	ret

000000008000111e <kvminit>:
{
    8000111e:	1141                	addi	sp,sp,-16
    80001120:	e406                	sd	ra,8(sp)
    80001122:	e022                	sd	s0,0(sp)
    80001124:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001126:	f47ff0ef          	jal	ra,8000106c <kvmmake>
    8000112a:	00006797          	auipc	a5,0x6
    8000112e:	72a7b723          	sd	a0,1838(a5) # 80007858 <kernel_pagetable>
}
    80001132:	60a2                	ld	ra,8(sp)
    80001134:	6402                	ld	s0,0(sp)
    80001136:	0141                	addi	sp,sp,16
    80001138:	8082                	ret

000000008000113a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000113a:	1101                	addi	sp,sp,-32
    8000113c:	ec06                	sd	ra,24(sp)
    8000113e:	e822                	sd	s0,16(sp)
    80001140:	e426                	sd	s1,8(sp)
    80001142:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001144:	959ff0ef          	jal	ra,80000a9c <kalloc>
    80001148:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000114a:	c509                	beqz	a0,80001154 <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000114c:	6605                	lui	a2,0x1
    8000114e:	4581                	li	a1,0
    80001150:	af1ff0ef          	jal	ra,80000c40 <memset>
  return pagetable;
}
    80001154:	8526                	mv	a0,s1
    80001156:	60e2                	ld	ra,24(sp)
    80001158:	6442                	ld	s0,16(sp)
    8000115a:	64a2                	ld	s1,8(sp)
    8000115c:	6105                	addi	sp,sp,32
    8000115e:	8082                	ret

0000000080001160 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001160:	7139                	addi	sp,sp,-64
    80001162:	fc06                	sd	ra,56(sp)
    80001164:	f822                	sd	s0,48(sp)
    80001166:	f426                	sd	s1,40(sp)
    80001168:	f04a                	sd	s2,32(sp)
    8000116a:	ec4e                	sd	s3,24(sp)
    8000116c:	e852                	sd	s4,16(sp)
    8000116e:	e456                	sd	s5,8(sp)
    80001170:	e05a                	sd	s6,0(sp)
    80001172:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001174:	03459793          	slli	a5,a1,0x34
    80001178:	e785                	bnez	a5,800011a0 <uvmunmap+0x40>
    8000117a:	8a2a                	mv	s4,a0
    8000117c:	892e                	mv	s2,a1
    8000117e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001180:	0632                	slli	a2,a2,0xc
    80001182:	00b609b3          	add	s3,a2,a1
    80001186:	6b05                	lui	s6,0x1
    80001188:	0335e763          	bltu	a1,s3,800011b6 <uvmunmap+0x56>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000118c:	70e2                	ld	ra,56(sp)
    8000118e:	7442                	ld	s0,48(sp)
    80001190:	74a2                	ld	s1,40(sp)
    80001192:	7902                	ld	s2,32(sp)
    80001194:	69e2                	ld	s3,24(sp)
    80001196:	6a42                	ld	s4,16(sp)
    80001198:	6aa2                	ld	s5,8(sp)
    8000119a:	6b02                	ld	s6,0(sp)
    8000119c:	6121                	addi	sp,sp,64
    8000119e:	8082                	ret
    panic("uvmunmap: not aligned");
    800011a0:	00006517          	auipc	a0,0x6
    800011a4:	f9850513          	addi	a0,a0,-104 # 80007138 <digits+0x100>
    800011a8:	de2ff0ef          	jal	ra,8000078a <panic>
    *pte = 0;
    800011ac:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800011b0:	995a                	add	s2,s2,s6
    800011b2:	fd397de3          	bgeu	s2,s3,8000118c <uvmunmap+0x2c>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    800011b6:	4601                	li	a2,0
    800011b8:	85ca                	mv	a1,s2
    800011ba:	8552                	mv	a0,s4
    800011bc:	d01ff0ef          	jal	ra,80000ebc <walk>
    800011c0:	84aa                	mv	s1,a0
    800011c2:	d57d                	beqz	a0,800011b0 <uvmunmap+0x50>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    800011c4:	611c                	ld	a5,0(a0)
    800011c6:	0017f713          	andi	a4,a5,1
    800011ca:	d37d                	beqz	a4,800011b0 <uvmunmap+0x50>
    if(do_free){
    800011cc:	fe0a80e3          	beqz	s5,800011ac <uvmunmap+0x4c>
      uint64 pa = PTE2PA(*pte);
    800011d0:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    800011d2:	00c79513          	slli	a0,a5,0xc
    800011d6:	fe6ff0ef          	jal	ra,800009bc <kfree>
    800011da:	bfc9                	j	800011ac <uvmunmap+0x4c>

00000000800011dc <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800011dc:	1101                	addi	sp,sp,-32
    800011de:	ec06                	sd	ra,24(sp)
    800011e0:	e822                	sd	s0,16(sp)
    800011e2:	e426                	sd	s1,8(sp)
    800011e4:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800011e6:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800011e8:	00b67d63          	bgeu	a2,a1,80001202 <uvmdealloc+0x26>
    800011ec:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800011ee:	6785                	lui	a5,0x1
    800011f0:	17fd                	addi	a5,a5,-1
    800011f2:	00f60733          	add	a4,a2,a5
    800011f6:	767d                	lui	a2,0xfffff
    800011f8:	8f71                	and	a4,a4,a2
    800011fa:	97ae                	add	a5,a5,a1
    800011fc:	8ff1                	and	a5,a5,a2
    800011fe:	00f76863          	bltu	a4,a5,8000120e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001202:	8526                	mv	a0,s1
    80001204:	60e2                	ld	ra,24(sp)
    80001206:	6442                	ld	s0,16(sp)
    80001208:	64a2                	ld	s1,8(sp)
    8000120a:	6105                	addi	sp,sp,32
    8000120c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000120e:	8f99                	sub	a5,a5,a4
    80001210:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001212:	4685                	li	a3,1
    80001214:	0007861b          	sext.w	a2,a5
    80001218:	85ba                	mv	a1,a4
    8000121a:	f47ff0ef          	jal	ra,80001160 <uvmunmap>
    8000121e:	b7d5                	j	80001202 <uvmdealloc+0x26>

0000000080001220 <uvmalloc>:
  if(newsz < oldsz)
    80001220:	08b66963          	bltu	a2,a1,800012b2 <uvmalloc+0x92>
{
    80001224:	7139                	addi	sp,sp,-64
    80001226:	fc06                	sd	ra,56(sp)
    80001228:	f822                	sd	s0,48(sp)
    8000122a:	f426                	sd	s1,40(sp)
    8000122c:	f04a                	sd	s2,32(sp)
    8000122e:	ec4e                	sd	s3,24(sp)
    80001230:	e852                	sd	s4,16(sp)
    80001232:	e456                	sd	s5,8(sp)
    80001234:	e05a                	sd	s6,0(sp)
    80001236:	0080                	addi	s0,sp,64
    80001238:	8aaa                	mv	s5,a0
    8000123a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000123c:	6985                	lui	s3,0x1
    8000123e:	19fd                	addi	s3,s3,-1
    80001240:	95ce                	add	a1,a1,s3
    80001242:	79fd                	lui	s3,0xfffff
    80001244:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001248:	06c9f763          	bgeu	s3,a2,800012b6 <uvmalloc+0x96>
    8000124c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000124e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001252:	84bff0ef          	jal	ra,80000a9c <kalloc>
    80001256:	84aa                	mv	s1,a0
    if(mem == 0){
    80001258:	c11d                	beqz	a0,8000127e <uvmalloc+0x5e>
    memset(mem, 0, PGSIZE);
    8000125a:	6605                	lui	a2,0x1
    8000125c:	4581                	li	a1,0
    8000125e:	9e3ff0ef          	jal	ra,80000c40 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001262:	875a                	mv	a4,s6
    80001264:	86a6                	mv	a3,s1
    80001266:	6605                	lui	a2,0x1
    80001268:	85ca                	mv	a1,s2
    8000126a:	8556                	mv	a0,s5
    8000126c:	d29ff0ef          	jal	ra,80000f94 <mappages>
    80001270:	e51d                	bnez	a0,8000129e <uvmalloc+0x7e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001272:	6785                	lui	a5,0x1
    80001274:	993e                	add	s2,s2,a5
    80001276:	fd496ee3          	bltu	s2,s4,80001252 <uvmalloc+0x32>
  return newsz;
    8000127a:	8552                	mv	a0,s4
    8000127c:	a039                	j	8000128a <uvmalloc+0x6a>
      uvmdealloc(pagetable, a, oldsz);
    8000127e:	864e                	mv	a2,s3
    80001280:	85ca                	mv	a1,s2
    80001282:	8556                	mv	a0,s5
    80001284:	f59ff0ef          	jal	ra,800011dc <uvmdealloc>
      return 0;
    80001288:	4501                	li	a0,0
}
    8000128a:	70e2                	ld	ra,56(sp)
    8000128c:	7442                	ld	s0,48(sp)
    8000128e:	74a2                	ld	s1,40(sp)
    80001290:	7902                	ld	s2,32(sp)
    80001292:	69e2                	ld	s3,24(sp)
    80001294:	6a42                	ld	s4,16(sp)
    80001296:	6aa2                	ld	s5,8(sp)
    80001298:	6b02                	ld	s6,0(sp)
    8000129a:	6121                	addi	sp,sp,64
    8000129c:	8082                	ret
      kfree(mem);
    8000129e:	8526                	mv	a0,s1
    800012a0:	f1cff0ef          	jal	ra,800009bc <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800012a4:	864e                	mv	a2,s3
    800012a6:	85ca                	mv	a1,s2
    800012a8:	8556                	mv	a0,s5
    800012aa:	f33ff0ef          	jal	ra,800011dc <uvmdealloc>
      return 0;
    800012ae:	4501                	li	a0,0
    800012b0:	bfe9                	j	8000128a <uvmalloc+0x6a>
    return oldsz;
    800012b2:	852e                	mv	a0,a1
}
    800012b4:	8082                	ret
  return newsz;
    800012b6:	8532                	mv	a0,a2
    800012b8:	bfc9                	j	8000128a <uvmalloc+0x6a>

00000000800012ba <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800012ba:	7179                	addi	sp,sp,-48
    800012bc:	f406                	sd	ra,40(sp)
    800012be:	f022                	sd	s0,32(sp)
    800012c0:	ec26                	sd	s1,24(sp)
    800012c2:	e84a                	sd	s2,16(sp)
    800012c4:	e44e                	sd	s3,8(sp)
    800012c6:	e052                	sd	s4,0(sp)
    800012c8:	1800                	addi	s0,sp,48
    800012ca:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800012cc:	84aa                	mv	s1,a0
    800012ce:	6905                	lui	s2,0x1
    800012d0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800012d2:	4985                	li	s3,1
    800012d4:	a811                	j	800012e8 <freewalk+0x2e>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800012d6:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800012d8:	0532                	slli	a0,a0,0xc
    800012da:	fe1ff0ef          	jal	ra,800012ba <freewalk>
      pagetable[i] = 0;
    800012de:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800012e2:	04a1                	addi	s1,s1,8
    800012e4:	01248f63          	beq	s1,s2,80001302 <freewalk+0x48>
    pte_t pte = pagetable[i];
    800012e8:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800012ea:	00f57793          	andi	a5,a0,15
    800012ee:	ff3784e3          	beq	a5,s3,800012d6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800012f2:	8905                	andi	a0,a0,1
    800012f4:	d57d                	beqz	a0,800012e2 <freewalk+0x28>
      panic("freewalk: leaf");
    800012f6:	00006517          	auipc	a0,0x6
    800012fa:	e5a50513          	addi	a0,a0,-422 # 80007150 <digits+0x118>
    800012fe:	c8cff0ef          	jal	ra,8000078a <panic>
    }
  }
  kfree((void*)pagetable);
    80001302:	8552                	mv	a0,s4
    80001304:	eb8ff0ef          	jal	ra,800009bc <kfree>
}
    80001308:	70a2                	ld	ra,40(sp)
    8000130a:	7402                	ld	s0,32(sp)
    8000130c:	64e2                	ld	s1,24(sp)
    8000130e:	6942                	ld	s2,16(sp)
    80001310:	69a2                	ld	s3,8(sp)
    80001312:	6a02                	ld	s4,0(sp)
    80001314:	6145                	addi	sp,sp,48
    80001316:	8082                	ret

0000000080001318 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001318:	1101                	addi	sp,sp,-32
    8000131a:	ec06                	sd	ra,24(sp)
    8000131c:	e822                	sd	s0,16(sp)
    8000131e:	e426                	sd	s1,8(sp)
    80001320:	1000                	addi	s0,sp,32
    80001322:	84aa                	mv	s1,a0
  if(sz > 0)
    80001324:	e989                	bnez	a1,80001336 <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001326:	8526                	mv	a0,s1
    80001328:	f93ff0ef          	jal	ra,800012ba <freewalk>
}
    8000132c:	60e2                	ld	ra,24(sp)
    8000132e:	6442                	ld	s0,16(sp)
    80001330:	64a2                	ld	s1,8(sp)
    80001332:	6105                	addi	sp,sp,32
    80001334:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001336:	6605                	lui	a2,0x1
    80001338:	167d                	addi	a2,a2,-1
    8000133a:	962e                	add	a2,a2,a1
    8000133c:	4685                	li	a3,1
    8000133e:	8231                	srli	a2,a2,0xc
    80001340:	4581                	li	a1,0
    80001342:	e1fff0ef          	jal	ra,80001160 <uvmunmap>
    80001346:	b7c5                	j	80001326 <uvmfree+0xe>

0000000080001348 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001348:	ce49                	beqz	a2,800013e2 <uvmcopy+0x9a>
{
    8000134a:	715d                	addi	sp,sp,-80
    8000134c:	e486                	sd	ra,72(sp)
    8000134e:	e0a2                	sd	s0,64(sp)
    80001350:	fc26                	sd	s1,56(sp)
    80001352:	f84a                	sd	s2,48(sp)
    80001354:	f44e                	sd	s3,40(sp)
    80001356:	f052                	sd	s4,32(sp)
    80001358:	ec56                	sd	s5,24(sp)
    8000135a:	e85a                	sd	s6,16(sp)
    8000135c:	e45e                	sd	s7,8(sp)
    8000135e:	0880                	addi	s0,sp,80
    80001360:	8aaa                	mv	s5,a0
    80001362:	8b2e                	mv	s6,a1
    80001364:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001366:	4481                	li	s1,0
    80001368:	a029                	j	80001372 <uvmcopy+0x2a>
    8000136a:	6785                	lui	a5,0x1
    8000136c:	94be                	add	s1,s1,a5
    8000136e:	0544fe63          	bgeu	s1,s4,800013ca <uvmcopy+0x82>
    if((pte = walk(old, i, 0)) == 0)
    80001372:	4601                	li	a2,0
    80001374:	85a6                	mv	a1,s1
    80001376:	8556                	mv	a0,s5
    80001378:	b45ff0ef          	jal	ra,80000ebc <walk>
    8000137c:	d57d                	beqz	a0,8000136a <uvmcopy+0x22>
      continue;   // page table entry hasn't been allocated
    if((*pte & PTE_V) == 0)
    8000137e:	6118                	ld	a4,0(a0)
    80001380:	00177793          	andi	a5,a4,1
    80001384:	d3fd                	beqz	a5,8000136a <uvmcopy+0x22>
      continue;   // physical page hasn't been allocated
    pa = PTE2PA(*pte);
    80001386:	00a75593          	srli	a1,a4,0xa
    8000138a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000138e:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    80001392:	f0aff0ef          	jal	ra,80000a9c <kalloc>
    80001396:	89aa                	mv	s3,a0
    80001398:	c105                	beqz	a0,800013b8 <uvmcopy+0x70>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000139a:	6605                	lui	a2,0x1
    8000139c:	85de                	mv	a1,s7
    8000139e:	8ffff0ef          	jal	ra,80000c9c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800013a2:	874a                	mv	a4,s2
    800013a4:	86ce                	mv	a3,s3
    800013a6:	6605                	lui	a2,0x1
    800013a8:	85a6                	mv	a1,s1
    800013aa:	855a                	mv	a0,s6
    800013ac:	be9ff0ef          	jal	ra,80000f94 <mappages>
    800013b0:	dd4d                	beqz	a0,8000136a <uvmcopy+0x22>
      kfree(mem);
    800013b2:	854e                	mv	a0,s3
    800013b4:	e08ff0ef          	jal	ra,800009bc <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800013b8:	4685                	li	a3,1
    800013ba:	00c4d613          	srli	a2,s1,0xc
    800013be:	4581                	li	a1,0
    800013c0:	855a                	mv	a0,s6
    800013c2:	d9fff0ef          	jal	ra,80001160 <uvmunmap>
  return -1;
    800013c6:	557d                	li	a0,-1
    800013c8:	a011                	j	800013cc <uvmcopy+0x84>
  return 0;
    800013ca:	4501                	li	a0,0
}
    800013cc:	60a6                	ld	ra,72(sp)
    800013ce:	6406                	ld	s0,64(sp)
    800013d0:	74e2                	ld	s1,56(sp)
    800013d2:	7942                	ld	s2,48(sp)
    800013d4:	79a2                	ld	s3,40(sp)
    800013d6:	7a02                	ld	s4,32(sp)
    800013d8:	6ae2                	ld	s5,24(sp)
    800013da:	6b42                	ld	s6,16(sp)
    800013dc:	6ba2                	ld	s7,8(sp)
    800013de:	6161                	addi	sp,sp,80
    800013e0:	8082                	ret
  return 0;
    800013e2:	4501                	li	a0,0
}
    800013e4:	8082                	ret

00000000800013e6 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800013e6:	1141                	addi	sp,sp,-16
    800013e8:	e406                	sd	ra,8(sp)
    800013ea:	e022                	sd	s0,0(sp)
    800013ec:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800013ee:	4601                	li	a2,0
    800013f0:	acdff0ef          	jal	ra,80000ebc <walk>
  if(pte == 0)
    800013f4:	c901                	beqz	a0,80001404 <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800013f6:	611c                	ld	a5,0(a0)
    800013f8:	9bbd                	andi	a5,a5,-17
    800013fa:	e11c                	sd	a5,0(a0)
}
    800013fc:	60a2                	ld	ra,8(sp)
    800013fe:	6402                	ld	s0,0(sp)
    80001400:	0141                	addi	sp,sp,16
    80001402:	8082                	ret
    panic("uvmclear");
    80001404:	00006517          	auipc	a0,0x6
    80001408:	d5c50513          	addi	a0,a0,-676 # 80007160 <digits+0x128>
    8000140c:	b7eff0ef          	jal	ra,8000078a <panic>

0000000080001410 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001410:	c2d5                	beqz	a3,800014b4 <copyinstr+0xa4>
{
    80001412:	715d                	addi	sp,sp,-80
    80001414:	e486                	sd	ra,72(sp)
    80001416:	e0a2                	sd	s0,64(sp)
    80001418:	fc26                	sd	s1,56(sp)
    8000141a:	f84a                	sd	s2,48(sp)
    8000141c:	f44e                	sd	s3,40(sp)
    8000141e:	f052                	sd	s4,32(sp)
    80001420:	ec56                	sd	s5,24(sp)
    80001422:	e85a                	sd	s6,16(sp)
    80001424:	e45e                	sd	s7,8(sp)
    80001426:	0880                	addi	s0,sp,80
    80001428:	8a2a                	mv	s4,a0
    8000142a:	8b2e                	mv	s6,a1
    8000142c:	8bb2                	mv	s7,a2
    8000142e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001430:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001432:	6985                	lui	s3,0x1
    80001434:	a035                	j	80001460 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001436:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000143a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000143c:	0017b793          	seqz	a5,a5
    80001440:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001444:	60a6                	ld	ra,72(sp)
    80001446:	6406                	ld	s0,64(sp)
    80001448:	74e2                	ld	s1,56(sp)
    8000144a:	7942                	ld	s2,48(sp)
    8000144c:	79a2                	ld	s3,40(sp)
    8000144e:	7a02                	ld	s4,32(sp)
    80001450:	6ae2                	ld	s5,24(sp)
    80001452:	6b42                	ld	s6,16(sp)
    80001454:	6ba2                	ld	s7,8(sp)
    80001456:	6161                	addi	sp,sp,80
    80001458:	8082                	ret
    srcva = va0 + PGSIZE;
    8000145a:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000145e:	c4b9                	beqz	s1,800014ac <copyinstr+0x9c>
    va0 = PGROUNDDOWN(srcva);
    80001460:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001464:	85ca                	mv	a1,s2
    80001466:	8552                	mv	a0,s4
    80001468:	aefff0ef          	jal	ra,80000f56 <walkaddr>
    if(pa0 == 0)
    8000146c:	c131                	beqz	a0,800014b0 <copyinstr+0xa0>
    n = PGSIZE - (srcva - va0);
    8000146e:	41790833          	sub	a6,s2,s7
    80001472:	984e                	add	a6,a6,s3
    if(n > max)
    80001474:	0104f363          	bgeu	s1,a6,8000147a <copyinstr+0x6a>
    80001478:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000147a:	955e                	add	a0,a0,s7
    8000147c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001480:	fc080de3          	beqz	a6,8000145a <copyinstr+0x4a>
    80001484:	985a                	add	a6,a6,s6
    80001486:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001488:	41650633          	sub	a2,a0,s6
    8000148c:	14fd                	addi	s1,s1,-1
    8000148e:	9b26                	add	s6,s6,s1
    80001490:	00f60733          	add	a4,a2,a5
    80001494:	00074703          	lbu	a4,0(a4)
    80001498:	df59                	beqz	a4,80001436 <copyinstr+0x26>
        *dst = *p;
    8000149a:	00e78023          	sb	a4,0(a5)
      --max;
    8000149e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800014a2:	0785                	addi	a5,a5,1
    while(n > 0){
    800014a4:	ff0796e3          	bne	a5,a6,80001490 <copyinstr+0x80>
      dst++;
    800014a8:	8b42                	mv	s6,a6
    800014aa:	bf45                	j	8000145a <copyinstr+0x4a>
    800014ac:	4781                	li	a5,0
    800014ae:	b779                	j	8000143c <copyinstr+0x2c>
      return -1;
    800014b0:	557d                	li	a0,-1
    800014b2:	bf49                	j	80001444 <copyinstr+0x34>
  int got_null = 0;
    800014b4:	4781                	li	a5,0
  if(got_null){
    800014b6:	0017b793          	seqz	a5,a5
    800014ba:	40f00533          	neg	a0,a5
}
    800014be:	8082                	ret

00000000800014c0 <ismapped>:
  return mem;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
    800014c0:	1141                	addi	sp,sp,-16
    800014c2:	e406                	sd	ra,8(sp)
    800014c4:	e022                	sd	s0,0(sp)
    800014c6:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    800014c8:	4601                	li	a2,0
    800014ca:	9f3ff0ef          	jal	ra,80000ebc <walk>
  if (pte == 0) {
    800014ce:	c519                	beqz	a0,800014dc <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    800014d0:	6108                	ld	a0,0(a0)
    return 0;
    800014d2:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    800014d4:	60a2                	ld	ra,8(sp)
    800014d6:	6402                	ld	s0,0(sp)
    800014d8:	0141                	addi	sp,sp,16
    800014da:	8082                	ret
    return 0;
    800014dc:	4501                	li	a0,0
    800014de:	bfdd                	j	800014d4 <ismapped+0x14>

00000000800014e0 <vmfault>:
{
    800014e0:	7179                	addi	sp,sp,-48
    800014e2:	f406                	sd	ra,40(sp)
    800014e4:	f022                	sd	s0,32(sp)
    800014e6:	ec26                	sd	s1,24(sp)
    800014e8:	e84a                	sd	s2,16(sp)
    800014ea:	e44e                	sd	s3,8(sp)
    800014ec:	e052                	sd	s4,0(sp)
    800014ee:	1800                	addi	s0,sp,48
    800014f0:	89aa                	mv	s3,a0
    800014f2:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    800014f4:	310000ef          	jal	ra,80001804 <myproc>
  if (va >= p->sz)
    800014f8:	653c                	ld	a5,72(a0)
    800014fa:	00f4ec63          	bltu	s1,a5,80001512 <vmfault+0x32>
    return 0;
    800014fe:	4981                	li	s3,0
}
    80001500:	854e                	mv	a0,s3
    80001502:	70a2                	ld	ra,40(sp)
    80001504:	7402                	ld	s0,32(sp)
    80001506:	64e2                	ld	s1,24(sp)
    80001508:	6942                	ld	s2,16(sp)
    8000150a:	69a2                	ld	s3,8(sp)
    8000150c:	6a02                	ld	s4,0(sp)
    8000150e:	6145                	addi	sp,sp,48
    80001510:	8082                	ret
    80001512:	892a                	mv	s2,a0
  va = PGROUNDDOWN(va);
    80001514:	75fd                	lui	a1,0xfffff
    80001516:	8ced                	and	s1,s1,a1
  if(ismapped(pagetable, va)) {
    80001518:	85a6                	mv	a1,s1
    8000151a:	854e                	mv	a0,s3
    8000151c:	fa5ff0ef          	jal	ra,800014c0 <ismapped>
    return 0;
    80001520:	4981                	li	s3,0
  if(ismapped(pagetable, va)) {
    80001522:	fd79                	bnez	a0,80001500 <vmfault+0x20>
  mem = (uint64) kalloc();
    80001524:	d78ff0ef          	jal	ra,80000a9c <kalloc>
    80001528:	8a2a                	mv	s4,a0
  if(mem == 0)
    8000152a:	d979                	beqz	a0,80001500 <vmfault+0x20>
  mem = (uint64) kalloc();
    8000152c:	89aa                	mv	s3,a0
  memset((void *) mem, 0, PGSIZE);
    8000152e:	6605                	lui	a2,0x1
    80001530:	4581                	li	a1,0
    80001532:	f0eff0ef          	jal	ra,80000c40 <memset>
  if (mappages(p->pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    80001536:	4759                	li	a4,22
    80001538:	86d2                	mv	a3,s4
    8000153a:	6605                	lui	a2,0x1
    8000153c:	85a6                	mv	a1,s1
    8000153e:	05093503          	ld	a0,80(s2) # 1050 <_entry-0x7fffefb0>
    80001542:	a53ff0ef          	jal	ra,80000f94 <mappages>
    80001546:	dd4d                	beqz	a0,80001500 <vmfault+0x20>
    kfree((void *)mem);
    80001548:	8552                	mv	a0,s4
    8000154a:	c72ff0ef          	jal	ra,800009bc <kfree>
    return 0;
    8000154e:	4981                	li	s3,0
    80001550:	bf45                	j	80001500 <vmfault+0x20>

0000000080001552 <copyout>:
  while(len > 0){
    80001552:	cec1                	beqz	a3,800015ea <copyout+0x98>
{
    80001554:	711d                	addi	sp,sp,-96
    80001556:	ec86                	sd	ra,88(sp)
    80001558:	e8a2                	sd	s0,80(sp)
    8000155a:	e4a6                	sd	s1,72(sp)
    8000155c:	e0ca                	sd	s2,64(sp)
    8000155e:	fc4e                	sd	s3,56(sp)
    80001560:	f852                	sd	s4,48(sp)
    80001562:	f456                	sd	s5,40(sp)
    80001564:	f05a                	sd	s6,32(sp)
    80001566:	ec5e                	sd	s7,24(sp)
    80001568:	e862                	sd	s8,16(sp)
    8000156a:	e466                	sd	s9,8(sp)
    8000156c:	e06a                	sd	s10,0(sp)
    8000156e:	1080                	addi	s0,sp,96
    80001570:	8c2a                	mv	s8,a0
    80001572:	8b2e                	mv	s6,a1
    80001574:	8bb2                	mv	s7,a2
    80001576:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    80001578:	74fd                	lui	s1,0xfffff
    8000157a:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA)
    8000157c:	57fd                	li	a5,-1
    8000157e:	83e9                	srli	a5,a5,0x1a
    80001580:	0697e763          	bltu	a5,s1,800015ee <copyout+0x9c>
    80001584:	6d05                	lui	s10,0x1
    80001586:	8cbe                	mv	s9,a5
    80001588:	a015                	j	800015ac <copyout+0x5a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000158a:	409b0533          	sub	a0,s6,s1
    8000158e:	0009861b          	sext.w	a2,s3
    80001592:	85de                	mv	a1,s7
    80001594:	954a                	add	a0,a0,s2
    80001596:	f06ff0ef          	jal	ra,80000c9c <memmove>
    len -= n;
    8000159a:	413a0a33          	sub	s4,s4,s3
    src += n;
    8000159e:	9bce                	add	s7,s7,s3
  while(len > 0){
    800015a0:	040a0363          	beqz	s4,800015e6 <copyout+0x94>
    if(va0 >= MAXVA)
    800015a4:	055ce763          	bltu	s9,s5,800015f2 <copyout+0xa0>
    va0 = PGROUNDDOWN(dstva);
    800015a8:	84d6                	mv	s1,s5
    dstva = va0 + PGSIZE;
    800015aa:	8b56                	mv	s6,s5
    pa0 = walkaddr(pagetable, va0);
    800015ac:	85a6                	mv	a1,s1
    800015ae:	8562                	mv	a0,s8
    800015b0:	9a7ff0ef          	jal	ra,80000f56 <walkaddr>
    800015b4:	892a                	mv	s2,a0
    if(pa0 == 0) {
    800015b6:	e901                	bnez	a0,800015c6 <copyout+0x74>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    800015b8:	4601                	li	a2,0
    800015ba:	85a6                	mv	a1,s1
    800015bc:	8562                	mv	a0,s8
    800015be:	f23ff0ef          	jal	ra,800014e0 <vmfault>
    800015c2:	892a                	mv	s2,a0
    800015c4:	c90d                	beqz	a0,800015f6 <copyout+0xa4>
    pte = walk(pagetable, va0, 0);
    800015c6:	4601                	li	a2,0
    800015c8:	85a6                	mv	a1,s1
    800015ca:	8562                	mv	a0,s8
    800015cc:	8f1ff0ef          	jal	ra,80000ebc <walk>
    if((*pte & PTE_W) == 0)
    800015d0:	611c                	ld	a5,0(a0)
    800015d2:	8b91                	andi	a5,a5,4
    800015d4:	c39d                	beqz	a5,800015fa <copyout+0xa8>
    n = PGSIZE - (dstva - va0);
    800015d6:	01a48ab3          	add	s5,s1,s10
    800015da:	416a89b3          	sub	s3,s5,s6
    if(n > len)
    800015de:	fb3a76e3          	bgeu	s4,s3,8000158a <copyout+0x38>
    800015e2:	89d2                	mv	s3,s4
    800015e4:	b75d                	j	8000158a <copyout+0x38>
  return 0;
    800015e6:	4501                	li	a0,0
    800015e8:	a811                	j	800015fc <copyout+0xaa>
    800015ea:	4501                	li	a0,0
}
    800015ec:	8082                	ret
      return -1;
    800015ee:	557d                	li	a0,-1
    800015f0:	a031                	j	800015fc <copyout+0xaa>
    800015f2:	557d                	li	a0,-1
    800015f4:	a021                	j	800015fc <copyout+0xaa>
        return -1;
    800015f6:	557d                	li	a0,-1
    800015f8:	a011                	j	800015fc <copyout+0xaa>
      return -1;
    800015fa:	557d                	li	a0,-1
}
    800015fc:	60e6                	ld	ra,88(sp)
    800015fe:	6446                	ld	s0,80(sp)
    80001600:	64a6                	ld	s1,72(sp)
    80001602:	6906                	ld	s2,64(sp)
    80001604:	79e2                	ld	s3,56(sp)
    80001606:	7a42                	ld	s4,48(sp)
    80001608:	7aa2                	ld	s5,40(sp)
    8000160a:	7b02                	ld	s6,32(sp)
    8000160c:	6be2                	ld	s7,24(sp)
    8000160e:	6c42                	ld	s8,16(sp)
    80001610:	6ca2                	ld	s9,8(sp)
    80001612:	6d02                	ld	s10,0(sp)
    80001614:	6125                	addi	sp,sp,96
    80001616:	8082                	ret

0000000080001618 <copyin>:
  while(len > 0){
    80001618:	c6c9                	beqz	a3,800016a2 <copyin+0x8a>
{
    8000161a:	715d                	addi	sp,sp,-80
    8000161c:	e486                	sd	ra,72(sp)
    8000161e:	e0a2                	sd	s0,64(sp)
    80001620:	fc26                	sd	s1,56(sp)
    80001622:	f84a                	sd	s2,48(sp)
    80001624:	f44e                	sd	s3,40(sp)
    80001626:	f052                	sd	s4,32(sp)
    80001628:	ec56                	sd	s5,24(sp)
    8000162a:	e85a                	sd	s6,16(sp)
    8000162c:	e45e                	sd	s7,8(sp)
    8000162e:	e062                	sd	s8,0(sp)
    80001630:	0880                	addi	s0,sp,80
    80001632:	8baa                	mv	s7,a0
    80001634:	8aae                	mv	s5,a1
    80001636:	8932                	mv	s2,a2
    80001638:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    8000163a:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    8000163c:	6b05                	lui	s6,0x1
    8000163e:	a035                	j	8000166a <copyin+0x52>
    80001640:	412984b3          	sub	s1,s3,s2
    80001644:	94da                	add	s1,s1,s6
    if(n > len)
    80001646:	009a7363          	bgeu	s4,s1,8000164c <copyin+0x34>
    8000164a:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000164c:	413905b3          	sub	a1,s2,s3
    80001650:	0004861b          	sext.w	a2,s1
    80001654:	95aa                	add	a1,a1,a0
    80001656:	8556                	mv	a0,s5
    80001658:	e44ff0ef          	jal	ra,80000c9c <memmove>
    len -= n;
    8000165c:	409a0a33          	sub	s4,s4,s1
    dst += n;
    80001660:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001662:	01698933          	add	s2,s3,s6
  while(len > 0){
    80001666:	020a0163          	beqz	s4,80001688 <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    8000166a:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    8000166e:	85ce                	mv	a1,s3
    80001670:	855e                	mv	a0,s7
    80001672:	8e5ff0ef          	jal	ra,80000f56 <walkaddr>
    if(pa0 == 0) {
    80001676:	f569                	bnez	a0,80001640 <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001678:	4601                	li	a2,0
    8000167a:	85ce                	mv	a1,s3
    8000167c:	855e                	mv	a0,s7
    8000167e:	e63ff0ef          	jal	ra,800014e0 <vmfault>
    80001682:	fd5d                	bnez	a0,80001640 <copyin+0x28>
        return -1;
    80001684:	557d                	li	a0,-1
    80001686:	a011                	j	8000168a <copyin+0x72>
  return 0;
    80001688:	4501                	li	a0,0
}
    8000168a:	60a6                	ld	ra,72(sp)
    8000168c:	6406                	ld	s0,64(sp)
    8000168e:	74e2                	ld	s1,56(sp)
    80001690:	7942                	ld	s2,48(sp)
    80001692:	79a2                	ld	s3,40(sp)
    80001694:	7a02                	ld	s4,32(sp)
    80001696:	6ae2                	ld	s5,24(sp)
    80001698:	6b42                	ld	s6,16(sp)
    8000169a:	6ba2                	ld	s7,8(sp)
    8000169c:	6c02                	ld	s8,0(sp)
    8000169e:	6161                	addi	sp,sp,80
    800016a0:	8082                	ret
  return 0;
    800016a2:	4501                	li	a0,0
}
    800016a4:	8082                	ret

00000000800016a6 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    800016a6:	7139                	addi	sp,sp,-64
    800016a8:	fc06                	sd	ra,56(sp)
    800016aa:	f822                	sd	s0,48(sp)
    800016ac:	f426                	sd	s1,40(sp)
    800016ae:	f04a                	sd	s2,32(sp)
    800016b0:	ec4e                	sd	s3,24(sp)
    800016b2:	e852                	sd	s4,16(sp)
    800016b4:	e456                	sd	s5,8(sp)
    800016b6:	e05a                	sd	s6,0(sp)
    800016b8:	0080                	addi	s0,sp,64
    800016ba:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800016bc:	0000e497          	auipc	s1,0xe
    800016c0:	6dc48493          	addi	s1,s1,1756 # 8000fd98 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800016c4:	8b26                	mv	s6,s1
    800016c6:	00006a97          	auipc	s5,0x6
    800016ca:	93aa8a93          	addi	s5,s5,-1734 # 80007000 <etext>
    800016ce:	04000937          	lui	s2,0x4000
    800016d2:	197d                	addi	s2,s2,-1
    800016d4:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800016d6:	00014a17          	auipc	s4,0x14
    800016da:	0c2a0a13          	addi	s4,s4,194 # 80015798 <tickslock>
    char *pa = kalloc();
    800016de:	bbeff0ef          	jal	ra,80000a9c <kalloc>
    800016e2:	862a                	mv	a2,a0
    if(pa == 0)
    800016e4:	c121                	beqz	a0,80001724 <proc_mapstacks+0x7e>
    uint64 va = KSTACK((int) (p - proc));
    800016e6:	416485b3          	sub	a1,s1,s6
    800016ea:	858d                	srai	a1,a1,0x3
    800016ec:	000ab783          	ld	a5,0(s5)
    800016f0:	02f585b3          	mul	a1,a1,a5
    800016f4:	2585                	addiw	a1,a1,1
    800016f6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800016fa:	4719                	li	a4,6
    800016fc:	6685                	lui	a3,0x1
    800016fe:	40b905b3          	sub	a1,s2,a1
    80001702:	854e                	mv	a0,s3
    80001704:	941ff0ef          	jal	ra,80001044 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001708:	16848493          	addi	s1,s1,360
    8000170c:	fd4499e3          	bne	s1,s4,800016de <proc_mapstacks+0x38>
  }
}
    80001710:	70e2                	ld	ra,56(sp)
    80001712:	7442                	ld	s0,48(sp)
    80001714:	74a2                	ld	s1,40(sp)
    80001716:	7902                	ld	s2,32(sp)
    80001718:	69e2                	ld	s3,24(sp)
    8000171a:	6a42                	ld	s4,16(sp)
    8000171c:	6aa2                	ld	s5,8(sp)
    8000171e:	6b02                	ld	s6,0(sp)
    80001720:	6121                	addi	sp,sp,64
    80001722:	8082                	ret
      panic("kalloc");
    80001724:	00006517          	auipc	a0,0x6
    80001728:	a4c50513          	addi	a0,a0,-1460 # 80007170 <digits+0x138>
    8000172c:	85eff0ef          	jal	ra,8000078a <panic>

0000000080001730 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001730:	7139                	addi	sp,sp,-64
    80001732:	fc06                	sd	ra,56(sp)
    80001734:	f822                	sd	s0,48(sp)
    80001736:	f426                	sd	s1,40(sp)
    80001738:	f04a                	sd	s2,32(sp)
    8000173a:	ec4e                	sd	s3,24(sp)
    8000173c:	e852                	sd	s4,16(sp)
    8000173e:	e456                	sd	s5,8(sp)
    80001740:	e05a                	sd	s6,0(sp)
    80001742:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001744:	00006597          	auipc	a1,0x6
    80001748:	a3458593          	addi	a1,a1,-1484 # 80007178 <digits+0x140>
    8000174c:	0000e517          	auipc	a0,0xe
    80001750:	21c50513          	addi	a0,a0,540 # 8000f968 <pid_lock>
    80001754:	b98ff0ef          	jal	ra,80000aec <initlock>
  initlock(&wait_lock, "wait_lock");
    80001758:	00006597          	auipc	a1,0x6
    8000175c:	a2858593          	addi	a1,a1,-1496 # 80007180 <digits+0x148>
    80001760:	0000e517          	auipc	a0,0xe
    80001764:	22050513          	addi	a0,a0,544 # 8000f980 <wait_lock>
    80001768:	b84ff0ef          	jal	ra,80000aec <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000176c:	0000e497          	auipc	s1,0xe
    80001770:	62c48493          	addi	s1,s1,1580 # 8000fd98 <proc>
      initlock(&p->lock, "proc");
    80001774:	00006b17          	auipc	s6,0x6
    80001778:	a1cb0b13          	addi	s6,s6,-1508 # 80007190 <digits+0x158>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000177c:	8aa6                	mv	s5,s1
    8000177e:	00006a17          	auipc	s4,0x6
    80001782:	882a0a13          	addi	s4,s4,-1918 # 80007000 <etext>
    80001786:	04000937          	lui	s2,0x4000
    8000178a:	197d                	addi	s2,s2,-1
    8000178c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000178e:	00014997          	auipc	s3,0x14
    80001792:	00a98993          	addi	s3,s3,10 # 80015798 <tickslock>
      initlock(&p->lock, "proc");
    80001796:	85da                	mv	a1,s6
    80001798:	8526                	mv	a0,s1
    8000179a:	b52ff0ef          	jal	ra,80000aec <initlock>
      p->state = UNUSED;
    8000179e:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800017a2:	415487b3          	sub	a5,s1,s5
    800017a6:	878d                	srai	a5,a5,0x3
    800017a8:	000a3703          	ld	a4,0(s4)
    800017ac:	02e787b3          	mul	a5,a5,a4
    800017b0:	2785                	addiw	a5,a5,1
    800017b2:	00d7979b          	slliw	a5,a5,0xd
    800017b6:	40f907b3          	sub	a5,s2,a5
    800017ba:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800017bc:	16848493          	addi	s1,s1,360
    800017c0:	fd349be3          	bne	s1,s3,80001796 <procinit+0x66>
  }
}
    800017c4:	70e2                	ld	ra,56(sp)
    800017c6:	7442                	ld	s0,48(sp)
    800017c8:	74a2                	ld	s1,40(sp)
    800017ca:	7902                	ld	s2,32(sp)
    800017cc:	69e2                	ld	s3,24(sp)
    800017ce:	6a42                	ld	s4,16(sp)
    800017d0:	6aa2                	ld	s5,8(sp)
    800017d2:	6b02                	ld	s6,0(sp)
    800017d4:	6121                	addi	sp,sp,64
    800017d6:	8082                	ret

00000000800017d8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800017d8:	1141                	addi	sp,sp,-16
    800017da:	e422                	sd	s0,8(sp)
    800017dc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800017de:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800017e0:	2501                	sext.w	a0,a0
    800017e2:	6422                	ld	s0,8(sp)
    800017e4:	0141                	addi	sp,sp,16
    800017e6:	8082                	ret

00000000800017e8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800017e8:	1141                	addi	sp,sp,-16
    800017ea:	e422                	sd	s0,8(sp)
    800017ec:	0800                	addi	s0,sp,16
    800017ee:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800017f0:	2781                	sext.w	a5,a5
    800017f2:	079e                	slli	a5,a5,0x7
  return c;
}
    800017f4:	0000e517          	auipc	a0,0xe
    800017f8:	1a450513          	addi	a0,a0,420 # 8000f998 <cpus>
    800017fc:	953e                	add	a0,a0,a5
    800017fe:	6422                	ld	s0,8(sp)
    80001800:	0141                	addi	sp,sp,16
    80001802:	8082                	ret

0000000080001804 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001804:	1101                	addi	sp,sp,-32
    80001806:	ec06                	sd	ra,24(sp)
    80001808:	e822                	sd	s0,16(sp)
    8000180a:	e426                	sd	s1,8(sp)
    8000180c:	1000                	addi	s0,sp,32
  push_off();
    8000180e:	b1eff0ef          	jal	ra,80000b2c <push_off>
    80001812:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001814:	2781                	sext.w	a5,a5
    80001816:	079e                	slli	a5,a5,0x7
    80001818:	0000e717          	auipc	a4,0xe
    8000181c:	15070713          	addi	a4,a4,336 # 8000f968 <pid_lock>
    80001820:	97ba                	add	a5,a5,a4
    80001822:	7b84                	ld	s1,48(a5)
  pop_off();
    80001824:	b8cff0ef          	jal	ra,80000bb0 <pop_off>
  return p;
}
    80001828:	8526                	mv	a0,s1
    8000182a:	60e2                	ld	ra,24(sp)
    8000182c:	6442                	ld	s0,16(sp)
    8000182e:	64a2                	ld	s1,8(sp)
    80001830:	6105                	addi	sp,sp,32
    80001832:	8082                	ret

0000000080001834 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001834:	7179                	addi	sp,sp,-48
    80001836:	f406                	sd	ra,40(sp)
    80001838:	f022                	sd	s0,32(sp)
    8000183a:	ec26                	sd	s1,24(sp)
    8000183c:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    8000183e:	fc7ff0ef          	jal	ra,80001804 <myproc>
    80001842:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    80001844:	bc0ff0ef          	jal	ra,80000c04 <release>

  if (first) {
    80001848:	00006797          	auipc	a5,0x6
    8000184c:	fe87a783          	lw	a5,-24(a5) # 80007830 <first.1>
    80001850:	cf8d                	beqz	a5,8000188a <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    80001852:	4505                	li	a0,1
    80001854:	429010ef          	jal	ra,8000347c <fsinit>

    first = 0;
    80001858:	00006797          	auipc	a5,0x6
    8000185c:	fc07ac23          	sw	zero,-40(a5) # 80007830 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    80001860:	0ff0000f          	fence

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    80001864:	00006517          	auipc	a0,0x6
    80001868:	93450513          	addi	a0,a0,-1740 # 80007198 <digits+0x160>
    8000186c:	fca43823          	sd	a0,-48(s0)
    80001870:	fc043c23          	sd	zero,-40(s0)
    80001874:	fd040593          	addi	a1,s0,-48
    80001878:	4ad020ef          	jal	ra,80004524 <kexec>
    8000187c:	6cbc                	ld	a5,88(s1)
    8000187e:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    80001880:	6cbc                	ld	a5,88(s1)
    80001882:	7bb8                	ld	a4,112(a5)
    80001884:	57fd                	li	a5,-1
    80001886:	02f70d63          	beq	a4,a5,800018c0 <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    8000188a:	355000ef          	jal	ra,800023de <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    8000188e:	68a8                	ld	a0,80(s1)
    80001890:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80001892:	04000737          	lui	a4,0x4000
    80001896:	00005797          	auipc	a5,0x5
    8000189a:	80678793          	addi	a5,a5,-2042 # 8000609c <userret>
    8000189e:	00004697          	auipc	a3,0x4
    800018a2:	76268693          	addi	a3,a3,1890 # 80006000 <_trampoline>
    800018a6:	8f95                	sub	a5,a5,a3
    800018a8:	177d                	addi	a4,a4,-1
    800018aa:	0732                	slli	a4,a4,0xc
    800018ac:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800018ae:	577d                	li	a4,-1
    800018b0:	177e                	slli	a4,a4,0x3f
    800018b2:	8d59                	or	a0,a0,a4
    800018b4:	9782                	jalr	a5
}
    800018b6:	70a2                	ld	ra,40(sp)
    800018b8:	7402                	ld	s0,32(sp)
    800018ba:	64e2                	ld	s1,24(sp)
    800018bc:	6145                	addi	sp,sp,48
    800018be:	8082                	ret
      panic("exec");
    800018c0:	00006517          	auipc	a0,0x6
    800018c4:	8e050513          	addi	a0,a0,-1824 # 800071a0 <digits+0x168>
    800018c8:	ec3fe0ef          	jal	ra,8000078a <panic>

00000000800018cc <allocpid>:
{
    800018cc:	1101                	addi	sp,sp,-32
    800018ce:	ec06                	sd	ra,24(sp)
    800018d0:	e822                	sd	s0,16(sp)
    800018d2:	e426                	sd	s1,8(sp)
    800018d4:	e04a                	sd	s2,0(sp)
    800018d6:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    800018d8:	0000e917          	auipc	s2,0xe
    800018dc:	09090913          	addi	s2,s2,144 # 8000f968 <pid_lock>
    800018e0:	854a                	mv	a0,s2
    800018e2:	a8aff0ef          	jal	ra,80000b6c <acquire>
  pid = nextpid;
    800018e6:	00006797          	auipc	a5,0x6
    800018ea:	f4e78793          	addi	a5,a5,-178 # 80007834 <nextpid>
    800018ee:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800018f0:	0014871b          	addiw	a4,s1,1
    800018f4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    800018f6:	854a                	mv	a0,s2
    800018f8:	b0cff0ef          	jal	ra,80000c04 <release>
}
    800018fc:	8526                	mv	a0,s1
    800018fe:	60e2                	ld	ra,24(sp)
    80001900:	6442                	ld	s0,16(sp)
    80001902:	64a2                	ld	s1,8(sp)
    80001904:	6902                	ld	s2,0(sp)
    80001906:	6105                	addi	sp,sp,32
    80001908:	8082                	ret

000000008000190a <proc_pagetable>:
{
    8000190a:	1101                	addi	sp,sp,-32
    8000190c:	ec06                	sd	ra,24(sp)
    8000190e:	e822                	sd	s0,16(sp)
    80001910:	e426                	sd	s1,8(sp)
    80001912:	e04a                	sd	s2,0(sp)
    80001914:	1000                	addi	s0,sp,32
    80001916:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001918:	823ff0ef          	jal	ra,8000113a <uvmcreate>
    8000191c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000191e:	cd05                	beqz	a0,80001956 <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001920:	4729                	li	a4,10
    80001922:	00004697          	auipc	a3,0x4
    80001926:	6de68693          	addi	a3,a3,1758 # 80006000 <_trampoline>
    8000192a:	6605                	lui	a2,0x1
    8000192c:	040005b7          	lui	a1,0x4000
    80001930:	15fd                	addi	a1,a1,-1
    80001932:	05b2                	slli	a1,a1,0xc
    80001934:	e60ff0ef          	jal	ra,80000f94 <mappages>
    80001938:	02054663          	bltz	a0,80001964 <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    8000193c:	4719                	li	a4,6
    8000193e:	05893683          	ld	a3,88(s2)
    80001942:	6605                	lui	a2,0x1
    80001944:	020005b7          	lui	a1,0x2000
    80001948:	15fd                	addi	a1,a1,-1
    8000194a:	05b6                	slli	a1,a1,0xd
    8000194c:	8526                	mv	a0,s1
    8000194e:	e46ff0ef          	jal	ra,80000f94 <mappages>
    80001952:	00054f63          	bltz	a0,80001970 <proc_pagetable+0x66>
}
    80001956:	8526                	mv	a0,s1
    80001958:	60e2                	ld	ra,24(sp)
    8000195a:	6442                	ld	s0,16(sp)
    8000195c:	64a2                	ld	s1,8(sp)
    8000195e:	6902                	ld	s2,0(sp)
    80001960:	6105                	addi	sp,sp,32
    80001962:	8082                	ret
    uvmfree(pagetable, 0);
    80001964:	4581                	li	a1,0
    80001966:	8526                	mv	a0,s1
    80001968:	9b1ff0ef          	jal	ra,80001318 <uvmfree>
    return 0;
    8000196c:	4481                	li	s1,0
    8000196e:	b7e5                	j	80001956 <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001970:	4681                	li	a3,0
    80001972:	4605                	li	a2,1
    80001974:	040005b7          	lui	a1,0x4000
    80001978:	15fd                	addi	a1,a1,-1
    8000197a:	05b2                	slli	a1,a1,0xc
    8000197c:	8526                	mv	a0,s1
    8000197e:	fe2ff0ef          	jal	ra,80001160 <uvmunmap>
    uvmfree(pagetable, 0);
    80001982:	4581                	li	a1,0
    80001984:	8526                	mv	a0,s1
    80001986:	993ff0ef          	jal	ra,80001318 <uvmfree>
    return 0;
    8000198a:	4481                	li	s1,0
    8000198c:	b7e9                	j	80001956 <proc_pagetable+0x4c>

000000008000198e <proc_freepagetable>:
{
    8000198e:	1101                	addi	sp,sp,-32
    80001990:	ec06                	sd	ra,24(sp)
    80001992:	e822                	sd	s0,16(sp)
    80001994:	e426                	sd	s1,8(sp)
    80001996:	e04a                	sd	s2,0(sp)
    80001998:	1000                	addi	s0,sp,32
    8000199a:	84aa                	mv	s1,a0
    8000199c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000199e:	4681                	li	a3,0
    800019a0:	4605                	li	a2,1
    800019a2:	040005b7          	lui	a1,0x4000
    800019a6:	15fd                	addi	a1,a1,-1
    800019a8:	05b2                	slli	a1,a1,0xc
    800019aa:	fb6ff0ef          	jal	ra,80001160 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    800019ae:	4681                	li	a3,0
    800019b0:	4605                	li	a2,1
    800019b2:	020005b7          	lui	a1,0x2000
    800019b6:	15fd                	addi	a1,a1,-1
    800019b8:	05b6                	slli	a1,a1,0xd
    800019ba:	8526                	mv	a0,s1
    800019bc:	fa4ff0ef          	jal	ra,80001160 <uvmunmap>
  uvmfree(pagetable, sz);
    800019c0:	85ca                	mv	a1,s2
    800019c2:	8526                	mv	a0,s1
    800019c4:	955ff0ef          	jal	ra,80001318 <uvmfree>
}
    800019c8:	60e2                	ld	ra,24(sp)
    800019ca:	6442                	ld	s0,16(sp)
    800019cc:	64a2                	ld	s1,8(sp)
    800019ce:	6902                	ld	s2,0(sp)
    800019d0:	6105                	addi	sp,sp,32
    800019d2:	8082                	ret

00000000800019d4 <freeproc>:
{
    800019d4:	1101                	addi	sp,sp,-32
    800019d6:	ec06                	sd	ra,24(sp)
    800019d8:	e822                	sd	s0,16(sp)
    800019da:	e426                	sd	s1,8(sp)
    800019dc:	1000                	addi	s0,sp,32
    800019de:	84aa                	mv	s1,a0
  if(p->trapframe)
    800019e0:	6d28                	ld	a0,88(a0)
    800019e2:	c119                	beqz	a0,800019e8 <freeproc+0x14>
    kfree((void*)p->trapframe);
    800019e4:	fd9fe0ef          	jal	ra,800009bc <kfree>
  p->trapframe = 0;
    800019e8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    800019ec:	68a8                	ld	a0,80(s1)
    800019ee:	c501                	beqz	a0,800019f6 <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    800019f0:	64ac                	ld	a1,72(s1)
    800019f2:	f9dff0ef          	jal	ra,8000198e <proc_freepagetable>
  p->pagetable = 0;
    800019f6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    800019fa:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    800019fe:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001a02:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001a06:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001a0a:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001a0e:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001a12:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001a16:	0004ac23          	sw	zero,24(s1)
}
    80001a1a:	60e2                	ld	ra,24(sp)
    80001a1c:	6442                	ld	s0,16(sp)
    80001a1e:	64a2                	ld	s1,8(sp)
    80001a20:	6105                	addi	sp,sp,32
    80001a22:	8082                	ret

0000000080001a24 <allocproc>:
{
    80001a24:	1101                	addi	sp,sp,-32
    80001a26:	ec06                	sd	ra,24(sp)
    80001a28:	e822                	sd	s0,16(sp)
    80001a2a:	e426                	sd	s1,8(sp)
    80001a2c:	e04a                	sd	s2,0(sp)
    80001a2e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a30:	0000e497          	auipc	s1,0xe
    80001a34:	36848493          	addi	s1,s1,872 # 8000fd98 <proc>
    80001a38:	00014917          	auipc	s2,0x14
    80001a3c:	d6090913          	addi	s2,s2,-672 # 80015798 <tickslock>
    acquire(&p->lock);
    80001a40:	8526                	mv	a0,s1
    80001a42:	92aff0ef          	jal	ra,80000b6c <acquire>
    if(p->state == UNUSED) {
    80001a46:	4c9c                	lw	a5,24(s1)
    80001a48:	cb91                	beqz	a5,80001a5c <allocproc+0x38>
      release(&p->lock);
    80001a4a:	8526                	mv	a0,s1
    80001a4c:	9b8ff0ef          	jal	ra,80000c04 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a50:	16848493          	addi	s1,s1,360
    80001a54:	ff2496e3          	bne	s1,s2,80001a40 <allocproc+0x1c>
  return 0;
    80001a58:	4481                	li	s1,0
    80001a5a:	a089                	j	80001a9c <allocproc+0x78>
  p->pid = allocpid();
    80001a5c:	e71ff0ef          	jal	ra,800018cc <allocpid>
    80001a60:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001a62:	4785                	li	a5,1
    80001a64:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001a66:	836ff0ef          	jal	ra,80000a9c <kalloc>
    80001a6a:	892a                	mv	s2,a0
    80001a6c:	eca8                	sd	a0,88(s1)
    80001a6e:	cd15                	beqz	a0,80001aaa <allocproc+0x86>
  p->pagetable = proc_pagetable(p);
    80001a70:	8526                	mv	a0,s1
    80001a72:	e99ff0ef          	jal	ra,8000190a <proc_pagetable>
    80001a76:	892a                	mv	s2,a0
    80001a78:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001a7a:	c121                	beqz	a0,80001aba <allocproc+0x96>
  memset(&p->context, 0, sizeof(p->context));
    80001a7c:	07000613          	li	a2,112
    80001a80:	4581                	li	a1,0
    80001a82:	06048513          	addi	a0,s1,96
    80001a86:	9baff0ef          	jal	ra,80000c40 <memset>
  p->context.ra = (uint64)forkret;
    80001a8a:	00000797          	auipc	a5,0x0
    80001a8e:	daa78793          	addi	a5,a5,-598 # 80001834 <forkret>
    80001a92:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001a94:	60bc                	ld	a5,64(s1)
    80001a96:	6705                	lui	a4,0x1
    80001a98:	97ba                	add	a5,a5,a4
    80001a9a:	f4bc                	sd	a5,104(s1)
}
    80001a9c:	8526                	mv	a0,s1
    80001a9e:	60e2                	ld	ra,24(sp)
    80001aa0:	6442                	ld	s0,16(sp)
    80001aa2:	64a2                	ld	s1,8(sp)
    80001aa4:	6902                	ld	s2,0(sp)
    80001aa6:	6105                	addi	sp,sp,32
    80001aa8:	8082                	ret
    freeproc(p);
    80001aaa:	8526                	mv	a0,s1
    80001aac:	f29ff0ef          	jal	ra,800019d4 <freeproc>
    release(&p->lock);
    80001ab0:	8526                	mv	a0,s1
    80001ab2:	952ff0ef          	jal	ra,80000c04 <release>
    return 0;
    80001ab6:	84ca                	mv	s1,s2
    80001ab8:	b7d5                	j	80001a9c <allocproc+0x78>
    freeproc(p);
    80001aba:	8526                	mv	a0,s1
    80001abc:	f19ff0ef          	jal	ra,800019d4 <freeproc>
    release(&p->lock);
    80001ac0:	8526                	mv	a0,s1
    80001ac2:	942ff0ef          	jal	ra,80000c04 <release>
    return 0;
    80001ac6:	84ca                	mv	s1,s2
    80001ac8:	bfd1                	j	80001a9c <allocproc+0x78>

0000000080001aca <userinit>:
{
    80001aca:	1101                	addi	sp,sp,-32
    80001acc:	ec06                	sd	ra,24(sp)
    80001ace:	e822                	sd	s0,16(sp)
    80001ad0:	e426                	sd	s1,8(sp)
    80001ad2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ad4:	f51ff0ef          	jal	ra,80001a24 <allocproc>
    80001ad8:	84aa                	mv	s1,a0
  initproc = p;
    80001ada:	00006797          	auipc	a5,0x6
    80001ade:	d8a7b323          	sd	a0,-634(a5) # 80007860 <initproc>
  p->cwd = namei("/");
    80001ae2:	00005517          	auipc	a0,0x5
    80001ae6:	6c650513          	addi	a0,a0,1734 # 800071a8 <digits+0x170>
    80001aea:	691010ef          	jal	ra,8000397a <namei>
    80001aee:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001af2:	478d                	li	a5,3
    80001af4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001af6:	8526                	mv	a0,s1
    80001af8:	90cff0ef          	jal	ra,80000c04 <release>
}
    80001afc:	60e2                	ld	ra,24(sp)
    80001afe:	6442                	ld	s0,16(sp)
    80001b00:	64a2                	ld	s1,8(sp)
    80001b02:	6105                	addi	sp,sp,32
    80001b04:	8082                	ret

0000000080001b06 <growproc>:
{
    80001b06:	1101                	addi	sp,sp,-32
    80001b08:	ec06                	sd	ra,24(sp)
    80001b0a:	e822                	sd	s0,16(sp)
    80001b0c:	e426                	sd	s1,8(sp)
    80001b0e:	e04a                	sd	s2,0(sp)
    80001b10:	1000                	addi	s0,sp,32
    80001b12:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001b14:	cf1ff0ef          	jal	ra,80001804 <myproc>
    80001b18:	892a                	mv	s2,a0
  sz = p->sz;
    80001b1a:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001b1c:	02905963          	blez	s1,80001b4e <growproc+0x48>
    if(sz + n > TRAPFRAME) {
    80001b20:	00b48633          	add	a2,s1,a1
    80001b24:	020007b7          	lui	a5,0x2000
    80001b28:	17fd                	addi	a5,a5,-1
    80001b2a:	07b6                	slli	a5,a5,0xd
    80001b2c:	02c7ea63          	bltu	a5,a2,80001b60 <growproc+0x5a>
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001b30:	4691                	li	a3,4
    80001b32:	6928                	ld	a0,80(a0)
    80001b34:	eecff0ef          	jal	ra,80001220 <uvmalloc>
    80001b38:	85aa                	mv	a1,a0
    80001b3a:	c50d                	beqz	a0,80001b64 <growproc+0x5e>
  p->sz = sz;
    80001b3c:	04b93423          	sd	a1,72(s2)
  return 0;
    80001b40:	4501                	li	a0,0
}
    80001b42:	60e2                	ld	ra,24(sp)
    80001b44:	6442                	ld	s0,16(sp)
    80001b46:	64a2                	ld	s1,8(sp)
    80001b48:	6902                	ld	s2,0(sp)
    80001b4a:	6105                	addi	sp,sp,32
    80001b4c:	8082                	ret
  } else if(n < 0){
    80001b4e:	fe04d7e3          	bgez	s1,80001b3c <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001b52:	00b48633          	add	a2,s1,a1
    80001b56:	6928                	ld	a0,80(a0)
    80001b58:	e84ff0ef          	jal	ra,800011dc <uvmdealloc>
    80001b5c:	85aa                	mv	a1,a0
    80001b5e:	bff9                	j	80001b3c <growproc+0x36>
      return -1;
    80001b60:	557d                	li	a0,-1
    80001b62:	b7c5                	j	80001b42 <growproc+0x3c>
      return -1;
    80001b64:	557d                	li	a0,-1
    80001b66:	bff1                	j	80001b42 <growproc+0x3c>

0000000080001b68 <kfork>:
{
    80001b68:	7139                	addi	sp,sp,-64
    80001b6a:	fc06                	sd	ra,56(sp)
    80001b6c:	f822                	sd	s0,48(sp)
    80001b6e:	f426                	sd	s1,40(sp)
    80001b70:	f04a                	sd	s2,32(sp)
    80001b72:	ec4e                	sd	s3,24(sp)
    80001b74:	e852                	sd	s4,16(sp)
    80001b76:	e456                	sd	s5,8(sp)
    80001b78:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001b7a:	c8bff0ef          	jal	ra,80001804 <myproc>
    80001b7e:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001b80:	ea5ff0ef          	jal	ra,80001a24 <allocproc>
    80001b84:	0e050663          	beqz	a0,80001c70 <kfork+0x108>
    80001b88:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001b8a:	048ab603          	ld	a2,72(s5)
    80001b8e:	692c                	ld	a1,80(a0)
    80001b90:	050ab503          	ld	a0,80(s5)
    80001b94:	fb4ff0ef          	jal	ra,80001348 <uvmcopy>
    80001b98:	04054863          	bltz	a0,80001be8 <kfork+0x80>
  np->sz = p->sz;
    80001b9c:	048ab783          	ld	a5,72(s5)
    80001ba0:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001ba4:	058ab683          	ld	a3,88(s5)
    80001ba8:	87b6                	mv	a5,a3
    80001baa:	058a3703          	ld	a4,88(s4)
    80001bae:	12068693          	addi	a3,a3,288
    80001bb2:	0007b803          	ld	a6,0(a5) # 2000000 <_entry-0x7e000000>
    80001bb6:	6788                	ld	a0,8(a5)
    80001bb8:	6b8c                	ld	a1,16(a5)
    80001bba:	6f90                	ld	a2,24(a5)
    80001bbc:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001bc0:	e708                	sd	a0,8(a4)
    80001bc2:	eb0c                	sd	a1,16(a4)
    80001bc4:	ef10                	sd	a2,24(a4)
    80001bc6:	02078793          	addi	a5,a5,32
    80001bca:	02070713          	addi	a4,a4,32
    80001bce:	fed792e3          	bne	a5,a3,80001bb2 <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001bd2:	058a3783          	ld	a5,88(s4)
    80001bd6:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001bda:	0d0a8493          	addi	s1,s5,208
    80001bde:	0d0a0913          	addi	s2,s4,208
    80001be2:	150a8993          	addi	s3,s5,336
    80001be6:	a829                	j	80001c00 <kfork+0x98>
    freeproc(np);
    80001be8:	8552                	mv	a0,s4
    80001bea:	debff0ef          	jal	ra,800019d4 <freeproc>
    release(&np->lock);
    80001bee:	8552                	mv	a0,s4
    80001bf0:	814ff0ef          	jal	ra,80000c04 <release>
    return -1;
    80001bf4:	597d                	li	s2,-1
    80001bf6:	a09d                	j	80001c5c <kfork+0xf4>
  for(i = 0; i < NOFILE; i++)
    80001bf8:	04a1                	addi	s1,s1,8
    80001bfa:	0921                	addi	s2,s2,8
    80001bfc:	01348963          	beq	s1,s3,80001c0e <kfork+0xa6>
    if(p->ofile[i])
    80001c00:	6088                	ld	a0,0(s1)
    80001c02:	d97d                	beqz	a0,80001bf8 <kfork+0x90>
      np->ofile[i] = filedup(p->ofile[i]);
    80001c04:	32e020ef          	jal	ra,80003f32 <filedup>
    80001c08:	00a93023          	sd	a0,0(s2)
    80001c0c:	b7f5                	j	80001bf8 <kfork+0x90>
  np->cwd = idup(p->cwd);
    80001c0e:	150ab503          	ld	a0,336(s5)
    80001c12:	544010ef          	jal	ra,80003156 <idup>
    80001c16:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001c1a:	4641                	li	a2,16
    80001c1c:	158a8593          	addi	a1,s5,344
    80001c20:	158a0513          	addi	a0,s4,344
    80001c24:	962ff0ef          	jal	ra,80000d86 <safestrcpy>
  pid = np->pid;
    80001c28:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001c2c:	8552                	mv	a0,s4
    80001c2e:	fd7fe0ef          	jal	ra,80000c04 <release>
  acquire(&wait_lock);
    80001c32:	0000e497          	auipc	s1,0xe
    80001c36:	d4e48493          	addi	s1,s1,-690 # 8000f980 <wait_lock>
    80001c3a:	8526                	mv	a0,s1
    80001c3c:	f31fe0ef          	jal	ra,80000b6c <acquire>
  np->parent = p;
    80001c40:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001c44:	8526                	mv	a0,s1
    80001c46:	fbffe0ef          	jal	ra,80000c04 <release>
  acquire(&np->lock);
    80001c4a:	8552                	mv	a0,s4
    80001c4c:	f21fe0ef          	jal	ra,80000b6c <acquire>
  np->state = RUNNABLE;
    80001c50:	478d                	li	a5,3
    80001c52:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001c56:	8552                	mv	a0,s4
    80001c58:	fadfe0ef          	jal	ra,80000c04 <release>
}
    80001c5c:	854a                	mv	a0,s2
    80001c5e:	70e2                	ld	ra,56(sp)
    80001c60:	7442                	ld	s0,48(sp)
    80001c62:	74a2                	ld	s1,40(sp)
    80001c64:	7902                	ld	s2,32(sp)
    80001c66:	69e2                	ld	s3,24(sp)
    80001c68:	6a42                	ld	s4,16(sp)
    80001c6a:	6aa2                	ld	s5,8(sp)
    80001c6c:	6121                	addi	sp,sp,64
    80001c6e:	8082                	ret
    return -1;
    80001c70:	597d                	li	s2,-1
    80001c72:	b7ed                	j	80001c5c <kfork+0xf4>

0000000080001c74 <scheduler>:
{
    80001c74:	715d                	addi	sp,sp,-80
    80001c76:	e486                	sd	ra,72(sp)
    80001c78:	e0a2                	sd	s0,64(sp)
    80001c7a:	fc26                	sd	s1,56(sp)
    80001c7c:	f84a                	sd	s2,48(sp)
    80001c7e:	f44e                	sd	s3,40(sp)
    80001c80:	f052                	sd	s4,32(sp)
    80001c82:	ec56                	sd	s5,24(sp)
    80001c84:	e85a                	sd	s6,16(sp)
    80001c86:	e45e                	sd	s7,8(sp)
    80001c88:	e062                	sd	s8,0(sp)
    80001c8a:	0880                	addi	s0,sp,80
    80001c8c:	8792                	mv	a5,tp
  int id = r_tp();
    80001c8e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001c90:	00779b13          	slli	s6,a5,0x7
    80001c94:	0000e717          	auipc	a4,0xe
    80001c98:	cd470713          	addi	a4,a4,-812 # 8000f968 <pid_lock>
    80001c9c:	975a                	add	a4,a4,s6
    80001c9e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ca2:	0000e717          	auipc	a4,0xe
    80001ca6:	cfe70713          	addi	a4,a4,-770 # 8000f9a0 <cpus+0x8>
    80001caa:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001cac:	4c11                	li	s8,4
        c->proc = p;
    80001cae:	079e                	slli	a5,a5,0x7
    80001cb0:	0000ea17          	auipc	s4,0xe
    80001cb4:	cb8a0a13          	addi	s4,s4,-840 # 8000f968 <pid_lock>
    80001cb8:	9a3e                	add	s4,s4,a5
        found = 1;
    80001cba:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001cbc:	00014997          	auipc	s3,0x14
    80001cc0:	adc98993          	addi	s3,s3,-1316 # 80015798 <tickslock>
    80001cc4:	a83d                	j	80001d02 <scheduler+0x8e>
      release(&p->lock);
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	f3dfe0ef          	jal	ra,80000c04 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ccc:	16848493          	addi	s1,s1,360
    80001cd0:	03348563          	beq	s1,s3,80001cfa <scheduler+0x86>
      acquire(&p->lock);
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	e97fe0ef          	jal	ra,80000b6c <acquire>
      if(p->state == RUNNABLE) {
    80001cda:	4c9c                	lw	a5,24(s1)
    80001cdc:	ff2795e3          	bne	a5,s2,80001cc6 <scheduler+0x52>
        p->state = RUNNING;
    80001ce0:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001ce4:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001ce8:	06048593          	addi	a1,s1,96
    80001cec:	855a                	mv	a0,s6
    80001cee:	64a000ef          	jal	ra,80002338 <swtch>
        c->proc = 0;
    80001cf2:	020a3823          	sd	zero,48(s4)
        found = 1;
    80001cf6:	8ade                	mv	s5,s7
    80001cf8:	b7f9                	j	80001cc6 <scheduler+0x52>
    if(found == 0) {
    80001cfa:	000a9463          	bnez	s5,80001d02 <scheduler+0x8e>
      asm volatile("wfi");
    80001cfe:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001d02:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001d06:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001d0a:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001d0e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001d12:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001d14:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001d18:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001d1a:	0000e497          	auipc	s1,0xe
    80001d1e:	07e48493          	addi	s1,s1,126 # 8000fd98 <proc>
      if(p->state == RUNNABLE) {
    80001d22:	490d                	li	s2,3
    80001d24:	bf45                	j	80001cd4 <scheduler+0x60>

0000000080001d26 <sched>:
{
    80001d26:	7179                	addi	sp,sp,-48
    80001d28:	f406                	sd	ra,40(sp)
    80001d2a:	f022                	sd	s0,32(sp)
    80001d2c:	ec26                	sd	s1,24(sp)
    80001d2e:	e84a                	sd	s2,16(sp)
    80001d30:	e44e                	sd	s3,8(sp)
    80001d32:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d34:	ad1ff0ef          	jal	ra,80001804 <myproc>
    80001d38:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001d3a:	dc9fe0ef          	jal	ra,80000b02 <holding>
    80001d3e:	c92d                	beqz	a0,80001db0 <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d40:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001d42:	2781                	sext.w	a5,a5
    80001d44:	079e                	slli	a5,a5,0x7
    80001d46:	0000e717          	auipc	a4,0xe
    80001d4a:	c2270713          	addi	a4,a4,-990 # 8000f968 <pid_lock>
    80001d4e:	97ba                	add	a5,a5,a4
    80001d50:	0a87a703          	lw	a4,168(a5)
    80001d54:	4785                	li	a5,1
    80001d56:	06f71363          	bne	a4,a5,80001dbc <sched+0x96>
  if(p->state == RUNNING)
    80001d5a:	4c98                	lw	a4,24(s1)
    80001d5c:	4791                	li	a5,4
    80001d5e:	06f70563          	beq	a4,a5,80001dc8 <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001d62:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001d66:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001d68:	e7b5                	bnez	a5,80001dd4 <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d6a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001d6c:	0000e917          	auipc	s2,0xe
    80001d70:	bfc90913          	addi	s2,s2,-1028 # 8000f968 <pid_lock>
    80001d74:	2781                	sext.w	a5,a5
    80001d76:	079e                	slli	a5,a5,0x7
    80001d78:	97ca                	add	a5,a5,s2
    80001d7a:	0ac7a983          	lw	s3,172(a5)
    80001d7e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001d80:	2781                	sext.w	a5,a5
    80001d82:	079e                	slli	a5,a5,0x7
    80001d84:	0000e597          	auipc	a1,0xe
    80001d88:	c1c58593          	addi	a1,a1,-996 # 8000f9a0 <cpus+0x8>
    80001d8c:	95be                	add	a1,a1,a5
    80001d8e:	06048513          	addi	a0,s1,96
    80001d92:	5a6000ef          	jal	ra,80002338 <swtch>
    80001d96:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001d98:	2781                	sext.w	a5,a5
    80001d9a:	079e                	slli	a5,a5,0x7
    80001d9c:	97ca                	add	a5,a5,s2
    80001d9e:	0b37a623          	sw	s3,172(a5)
}
    80001da2:	70a2                	ld	ra,40(sp)
    80001da4:	7402                	ld	s0,32(sp)
    80001da6:	64e2                	ld	s1,24(sp)
    80001da8:	6942                	ld	s2,16(sp)
    80001daa:	69a2                	ld	s3,8(sp)
    80001dac:	6145                	addi	sp,sp,48
    80001dae:	8082                	ret
    panic("sched p->lock");
    80001db0:	00005517          	auipc	a0,0x5
    80001db4:	40050513          	addi	a0,a0,1024 # 800071b0 <digits+0x178>
    80001db8:	9d3fe0ef          	jal	ra,8000078a <panic>
    panic("sched locks");
    80001dbc:	00005517          	auipc	a0,0x5
    80001dc0:	40450513          	addi	a0,a0,1028 # 800071c0 <digits+0x188>
    80001dc4:	9c7fe0ef          	jal	ra,8000078a <panic>
    panic("sched RUNNING");
    80001dc8:	00005517          	auipc	a0,0x5
    80001dcc:	40850513          	addi	a0,a0,1032 # 800071d0 <digits+0x198>
    80001dd0:	9bbfe0ef          	jal	ra,8000078a <panic>
    panic("sched interruptible");
    80001dd4:	00005517          	auipc	a0,0x5
    80001dd8:	40c50513          	addi	a0,a0,1036 # 800071e0 <digits+0x1a8>
    80001ddc:	9affe0ef          	jal	ra,8000078a <panic>

0000000080001de0 <yield>:
{
    80001de0:	1101                	addi	sp,sp,-32
    80001de2:	ec06                	sd	ra,24(sp)
    80001de4:	e822                	sd	s0,16(sp)
    80001de6:	e426                	sd	s1,8(sp)
    80001de8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001dea:	a1bff0ef          	jal	ra,80001804 <myproc>
    80001dee:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001df0:	d7dfe0ef          	jal	ra,80000b6c <acquire>
  p->state = RUNNABLE;
    80001df4:	478d                	li	a5,3
    80001df6:	cc9c                	sw	a5,24(s1)
  sched();
    80001df8:	f2fff0ef          	jal	ra,80001d26 <sched>
  release(&p->lock);
    80001dfc:	8526                	mv	a0,s1
    80001dfe:	e07fe0ef          	jal	ra,80000c04 <release>
}
    80001e02:	60e2                	ld	ra,24(sp)
    80001e04:	6442                	ld	s0,16(sp)
    80001e06:	64a2                	ld	s1,8(sp)
    80001e08:	6105                	addi	sp,sp,32
    80001e0a:	8082                	ret

0000000080001e0c <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001e0c:	7179                	addi	sp,sp,-48
    80001e0e:	f406                	sd	ra,40(sp)
    80001e10:	f022                	sd	s0,32(sp)
    80001e12:	ec26                	sd	s1,24(sp)
    80001e14:	e84a                	sd	s2,16(sp)
    80001e16:	e44e                	sd	s3,8(sp)
    80001e18:	1800                	addi	s0,sp,48
    80001e1a:	89aa                	mv	s3,a0
    80001e1c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001e1e:	9e7ff0ef          	jal	ra,80001804 <myproc>
    80001e22:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001e24:	d49fe0ef          	jal	ra,80000b6c <acquire>
  release(lk);
    80001e28:	854a                	mv	a0,s2
    80001e2a:	ddbfe0ef          	jal	ra,80000c04 <release>

  // Go to sleep.
  p->chan = chan;
    80001e2e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001e32:	4789                	li	a5,2
    80001e34:	cc9c                	sw	a5,24(s1)

  sched();
    80001e36:	ef1ff0ef          	jal	ra,80001d26 <sched>

  // Tidy up.
  p->chan = 0;
    80001e3a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001e3e:	8526                	mv	a0,s1
    80001e40:	dc5fe0ef          	jal	ra,80000c04 <release>
  acquire(lk);
    80001e44:	854a                	mv	a0,s2
    80001e46:	d27fe0ef          	jal	ra,80000b6c <acquire>
}
    80001e4a:	70a2                	ld	ra,40(sp)
    80001e4c:	7402                	ld	s0,32(sp)
    80001e4e:	64e2                	ld	s1,24(sp)
    80001e50:	6942                	ld	s2,16(sp)
    80001e52:	69a2                	ld	s3,8(sp)
    80001e54:	6145                	addi	sp,sp,48
    80001e56:	8082                	ret

0000000080001e58 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    80001e58:	7139                	addi	sp,sp,-64
    80001e5a:	fc06                	sd	ra,56(sp)
    80001e5c:	f822                	sd	s0,48(sp)
    80001e5e:	f426                	sd	s1,40(sp)
    80001e60:	f04a                	sd	s2,32(sp)
    80001e62:	ec4e                	sd	s3,24(sp)
    80001e64:	e852                	sd	s4,16(sp)
    80001e66:	e456                	sd	s5,8(sp)
    80001e68:	0080                	addi	s0,sp,64
    80001e6a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80001e6c:	0000e497          	auipc	s1,0xe
    80001e70:	f2c48493          	addi	s1,s1,-212 # 8000fd98 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80001e74:	4989                	li	s3,2
        p->state = RUNNABLE;
    80001e76:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e78:	00014917          	auipc	s2,0x14
    80001e7c:	92090913          	addi	s2,s2,-1760 # 80015798 <tickslock>
    80001e80:	a801                	j	80001e90 <wakeup+0x38>
      }
      release(&p->lock);
    80001e82:	8526                	mv	a0,s1
    80001e84:	d81fe0ef          	jal	ra,80000c04 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e88:	16848493          	addi	s1,s1,360
    80001e8c:	03248263          	beq	s1,s2,80001eb0 <wakeup+0x58>
    if(p != myproc()){
    80001e90:	975ff0ef          	jal	ra,80001804 <myproc>
    80001e94:	fea48ae3          	beq	s1,a0,80001e88 <wakeup+0x30>
      acquire(&p->lock);
    80001e98:	8526                	mv	a0,s1
    80001e9a:	cd3fe0ef          	jal	ra,80000b6c <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80001e9e:	4c9c                	lw	a5,24(s1)
    80001ea0:	ff3791e3          	bne	a5,s3,80001e82 <wakeup+0x2a>
    80001ea4:	709c                	ld	a5,32(s1)
    80001ea6:	fd479ee3          	bne	a5,s4,80001e82 <wakeup+0x2a>
        p->state = RUNNABLE;
    80001eaa:	0154ac23          	sw	s5,24(s1)
    80001eae:	bfd1                	j	80001e82 <wakeup+0x2a>
    }
  }
}
    80001eb0:	70e2                	ld	ra,56(sp)
    80001eb2:	7442                	ld	s0,48(sp)
    80001eb4:	74a2                	ld	s1,40(sp)
    80001eb6:	7902                	ld	s2,32(sp)
    80001eb8:	69e2                	ld	s3,24(sp)
    80001eba:	6a42                	ld	s4,16(sp)
    80001ebc:	6aa2                	ld	s5,8(sp)
    80001ebe:	6121                	addi	sp,sp,64
    80001ec0:	8082                	ret

0000000080001ec2 <reparent>:
{
    80001ec2:	7179                	addi	sp,sp,-48
    80001ec4:	f406                	sd	ra,40(sp)
    80001ec6:	f022                	sd	s0,32(sp)
    80001ec8:	ec26                	sd	s1,24(sp)
    80001eca:	e84a                	sd	s2,16(sp)
    80001ecc:	e44e                	sd	s3,8(sp)
    80001ece:	e052                	sd	s4,0(sp)
    80001ed0:	1800                	addi	s0,sp,48
    80001ed2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ed4:	0000e497          	auipc	s1,0xe
    80001ed8:	ec448493          	addi	s1,s1,-316 # 8000fd98 <proc>
      pp->parent = initproc;
    80001edc:	00006a17          	auipc	s4,0x6
    80001ee0:	984a0a13          	addi	s4,s4,-1660 # 80007860 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ee4:	00014997          	auipc	s3,0x14
    80001ee8:	8b498993          	addi	s3,s3,-1868 # 80015798 <tickslock>
    80001eec:	a029                	j	80001ef6 <reparent+0x34>
    80001eee:	16848493          	addi	s1,s1,360
    80001ef2:	01348b63          	beq	s1,s3,80001f08 <reparent+0x46>
    if(pp->parent == p){
    80001ef6:	7c9c                	ld	a5,56(s1)
    80001ef8:	ff279be3          	bne	a5,s2,80001eee <reparent+0x2c>
      pp->parent = initproc;
    80001efc:	000a3503          	ld	a0,0(s4)
    80001f00:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80001f02:	f57ff0ef          	jal	ra,80001e58 <wakeup>
    80001f06:	b7e5                	j	80001eee <reparent+0x2c>
}
    80001f08:	70a2                	ld	ra,40(sp)
    80001f0a:	7402                	ld	s0,32(sp)
    80001f0c:	64e2                	ld	s1,24(sp)
    80001f0e:	6942                	ld	s2,16(sp)
    80001f10:	69a2                	ld	s3,8(sp)
    80001f12:	6a02                	ld	s4,0(sp)
    80001f14:	6145                	addi	sp,sp,48
    80001f16:	8082                	ret

0000000080001f18 <kexit>:
{
    80001f18:	7179                	addi	sp,sp,-48
    80001f1a:	f406                	sd	ra,40(sp)
    80001f1c:	f022                	sd	s0,32(sp)
    80001f1e:	ec26                	sd	s1,24(sp)
    80001f20:	e84a                	sd	s2,16(sp)
    80001f22:	e44e                	sd	s3,8(sp)
    80001f24:	e052                	sd	s4,0(sp)
    80001f26:	1800                	addi	s0,sp,48
    80001f28:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80001f2a:	8dbff0ef          	jal	ra,80001804 <myproc>
    80001f2e:	89aa                	mv	s3,a0
  if(p == initproc)
    80001f30:	00006797          	auipc	a5,0x6
    80001f34:	9307b783          	ld	a5,-1744(a5) # 80007860 <initproc>
    80001f38:	0d050493          	addi	s1,a0,208
    80001f3c:	15050913          	addi	s2,a0,336
    80001f40:	00a79f63          	bne	a5,a0,80001f5e <kexit+0x46>
    panic("init exiting");
    80001f44:	00005517          	auipc	a0,0x5
    80001f48:	2b450513          	addi	a0,a0,692 # 800071f8 <digits+0x1c0>
    80001f4c:	83ffe0ef          	jal	ra,8000078a <panic>
      fileclose(f);
    80001f50:	028020ef          	jal	ra,80003f78 <fileclose>
      p->ofile[fd] = 0;
    80001f54:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80001f58:	04a1                	addi	s1,s1,8
    80001f5a:	01248563          	beq	s1,s2,80001f64 <kexit+0x4c>
    if(p->ofile[fd]){
    80001f5e:	6088                	ld	a0,0(s1)
    80001f60:	f965                	bnez	a0,80001f50 <kexit+0x38>
    80001f62:	bfdd                	j	80001f58 <kexit+0x40>
  begin_op();
    80001f64:	407010ef          	jal	ra,80003b6a <begin_op>
  iput(p->cwd);
    80001f68:	1509b503          	ld	a0,336(s3)
    80001f6c:	39e010ef          	jal	ra,8000330a <iput>
  end_op();
    80001f70:	46b010ef          	jal	ra,80003bda <end_op>
  p->cwd = 0;
    80001f74:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80001f78:	0000e497          	auipc	s1,0xe
    80001f7c:	a0848493          	addi	s1,s1,-1528 # 8000f980 <wait_lock>
    80001f80:	8526                	mv	a0,s1
    80001f82:	bebfe0ef          	jal	ra,80000b6c <acquire>
  reparent(p);
    80001f86:	854e                	mv	a0,s3
    80001f88:	f3bff0ef          	jal	ra,80001ec2 <reparent>
  wakeup(p->parent);
    80001f8c:	0389b503          	ld	a0,56(s3)
    80001f90:	ec9ff0ef          	jal	ra,80001e58 <wakeup>
  acquire(&p->lock);
    80001f94:	854e                	mv	a0,s3
    80001f96:	bd7fe0ef          	jal	ra,80000b6c <acquire>
  p->xstate = status;
    80001f9a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80001f9e:	4795                	li	a5,5
    80001fa0:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80001fa4:	8526                	mv	a0,s1
    80001fa6:	c5ffe0ef          	jal	ra,80000c04 <release>
  sched();
    80001faa:	d7dff0ef          	jal	ra,80001d26 <sched>
  panic("zombie exit");
    80001fae:	00005517          	auipc	a0,0x5
    80001fb2:	25a50513          	addi	a0,a0,602 # 80007208 <digits+0x1d0>
    80001fb6:	fd4fe0ef          	jal	ra,8000078a <panic>

0000000080001fba <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    80001fba:	7179                	addi	sp,sp,-48
    80001fbc:	f406                	sd	ra,40(sp)
    80001fbe:	f022                	sd	s0,32(sp)
    80001fc0:	ec26                	sd	s1,24(sp)
    80001fc2:	e84a                	sd	s2,16(sp)
    80001fc4:	e44e                	sd	s3,8(sp)
    80001fc6:	1800                	addi	s0,sp,48
    80001fc8:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80001fca:	0000e497          	auipc	s1,0xe
    80001fce:	dce48493          	addi	s1,s1,-562 # 8000fd98 <proc>
    80001fd2:	00013997          	auipc	s3,0x13
    80001fd6:	7c698993          	addi	s3,s3,1990 # 80015798 <tickslock>
    acquire(&p->lock);
    80001fda:	8526                	mv	a0,s1
    80001fdc:	b91fe0ef          	jal	ra,80000b6c <acquire>
    if(p->pid == pid){
    80001fe0:	589c                	lw	a5,48(s1)
    80001fe2:	01278b63          	beq	a5,s2,80001ff8 <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80001fe6:	8526                	mv	a0,s1
    80001fe8:	c1dfe0ef          	jal	ra,80000c04 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80001fec:	16848493          	addi	s1,s1,360
    80001ff0:	ff3495e3          	bne	s1,s3,80001fda <kkill+0x20>
  }
  return -1;
    80001ff4:	557d                	li	a0,-1
    80001ff6:	a819                	j	8000200c <kkill+0x52>
      p->killed = 1;
    80001ff8:	4785                	li	a5,1
    80001ffa:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80001ffc:	4c98                	lw	a4,24(s1)
    80001ffe:	4789                	li	a5,2
    80002000:	00f70d63          	beq	a4,a5,8000201a <kkill+0x60>
      release(&p->lock);
    80002004:	8526                	mv	a0,s1
    80002006:	bfffe0ef          	jal	ra,80000c04 <release>
      return 0;
    8000200a:	4501                	li	a0,0
}
    8000200c:	70a2                	ld	ra,40(sp)
    8000200e:	7402                	ld	s0,32(sp)
    80002010:	64e2                	ld	s1,24(sp)
    80002012:	6942                	ld	s2,16(sp)
    80002014:	69a2                	ld	s3,8(sp)
    80002016:	6145                	addi	sp,sp,48
    80002018:	8082                	ret
        p->state = RUNNABLE;
    8000201a:	478d                	li	a5,3
    8000201c:	cc9c                	sw	a5,24(s1)
    8000201e:	b7dd                	j	80002004 <kkill+0x4a>

0000000080002020 <setkilled>:

void
setkilled(struct proc *p)
{
    80002020:	1101                	addi	sp,sp,-32
    80002022:	ec06                	sd	ra,24(sp)
    80002024:	e822                	sd	s0,16(sp)
    80002026:	e426                	sd	s1,8(sp)
    80002028:	1000                	addi	s0,sp,32
    8000202a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202c:	b41fe0ef          	jal	ra,80000b6c <acquire>
  p->killed = 1;
    80002030:	4785                	li	a5,1
    80002032:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002034:	8526                	mv	a0,s1
    80002036:	bcffe0ef          	jal	ra,80000c04 <release>
}
    8000203a:	60e2                	ld	ra,24(sp)
    8000203c:	6442                	ld	s0,16(sp)
    8000203e:	64a2                	ld	s1,8(sp)
    80002040:	6105                	addi	sp,sp,32
    80002042:	8082                	ret

0000000080002044 <killed>:

int
killed(struct proc *p)
{
    80002044:	1101                	addi	sp,sp,-32
    80002046:	ec06                	sd	ra,24(sp)
    80002048:	e822                	sd	s0,16(sp)
    8000204a:	e426                	sd	s1,8(sp)
    8000204c:	e04a                	sd	s2,0(sp)
    8000204e:	1000                	addi	s0,sp,32
    80002050:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002052:	b1bfe0ef          	jal	ra,80000b6c <acquire>
  k = p->killed;
    80002056:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000205a:	8526                	mv	a0,s1
    8000205c:	ba9fe0ef          	jal	ra,80000c04 <release>
  return k;
}
    80002060:	854a                	mv	a0,s2
    80002062:	60e2                	ld	ra,24(sp)
    80002064:	6442                	ld	s0,16(sp)
    80002066:	64a2                	ld	s1,8(sp)
    80002068:	6902                	ld	s2,0(sp)
    8000206a:	6105                	addi	sp,sp,32
    8000206c:	8082                	ret

000000008000206e <kwait>:
{
    8000206e:	715d                	addi	sp,sp,-80
    80002070:	e486                	sd	ra,72(sp)
    80002072:	e0a2                	sd	s0,64(sp)
    80002074:	fc26                	sd	s1,56(sp)
    80002076:	f84a                	sd	s2,48(sp)
    80002078:	f44e                	sd	s3,40(sp)
    8000207a:	f052                	sd	s4,32(sp)
    8000207c:	ec56                	sd	s5,24(sp)
    8000207e:	e85a                	sd	s6,16(sp)
    80002080:	e45e                	sd	s7,8(sp)
    80002082:	e062                	sd	s8,0(sp)
    80002084:	0880                	addi	s0,sp,80
    80002086:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002088:	f7cff0ef          	jal	ra,80001804 <myproc>
    8000208c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000208e:	0000e517          	auipc	a0,0xe
    80002092:	8f250513          	addi	a0,a0,-1806 # 8000f980 <wait_lock>
    80002096:	ad7fe0ef          	jal	ra,80000b6c <acquire>
    havekids = 0;
    8000209a:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000209c:	4a15                	li	s4,5
        havekids = 1;
    8000209e:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800020a0:	00013997          	auipc	s3,0x13
    800020a4:	6f898993          	addi	s3,s3,1784 # 80015798 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020a8:	0000ec17          	auipc	s8,0xe
    800020ac:	8d8c0c13          	addi	s8,s8,-1832 # 8000f980 <wait_lock>
    havekids = 0;
    800020b0:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800020b2:	0000e497          	auipc	s1,0xe
    800020b6:	ce648493          	addi	s1,s1,-794 # 8000fd98 <proc>
    800020ba:	a899                	j	80002110 <kwait+0xa2>
          pid = pp->pid;
    800020bc:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800020c0:	000b0c63          	beqz	s6,800020d8 <kwait+0x6a>
    800020c4:	4691                	li	a3,4
    800020c6:	02c48613          	addi	a2,s1,44
    800020ca:	85da                	mv	a1,s6
    800020cc:	05093503          	ld	a0,80(s2)
    800020d0:	c82ff0ef          	jal	ra,80001552 <copyout>
    800020d4:	00054f63          	bltz	a0,800020f2 <kwait+0x84>
          freeproc(pp);
    800020d8:	8526                	mv	a0,s1
    800020da:	8fbff0ef          	jal	ra,800019d4 <freeproc>
          release(&pp->lock);
    800020de:	8526                	mv	a0,s1
    800020e0:	b25fe0ef          	jal	ra,80000c04 <release>
          release(&wait_lock);
    800020e4:	0000e517          	auipc	a0,0xe
    800020e8:	89c50513          	addi	a0,a0,-1892 # 8000f980 <wait_lock>
    800020ec:	b19fe0ef          	jal	ra,80000c04 <release>
          return pid;
    800020f0:	a891                	j	80002144 <kwait+0xd6>
            release(&pp->lock);
    800020f2:	8526                	mv	a0,s1
    800020f4:	b11fe0ef          	jal	ra,80000c04 <release>
            release(&wait_lock);
    800020f8:	0000e517          	auipc	a0,0xe
    800020fc:	88850513          	addi	a0,a0,-1912 # 8000f980 <wait_lock>
    80002100:	b05fe0ef          	jal	ra,80000c04 <release>
            return -1;
    80002104:	59fd                	li	s3,-1
    80002106:	a83d                	j	80002144 <kwait+0xd6>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002108:	16848493          	addi	s1,s1,360
    8000210c:	03348063          	beq	s1,s3,8000212c <kwait+0xbe>
      if(pp->parent == p){
    80002110:	7c9c                	ld	a5,56(s1)
    80002112:	ff279be3          	bne	a5,s2,80002108 <kwait+0x9a>
        acquire(&pp->lock);
    80002116:	8526                	mv	a0,s1
    80002118:	a55fe0ef          	jal	ra,80000b6c <acquire>
        if(pp->state == ZOMBIE){
    8000211c:	4c9c                	lw	a5,24(s1)
    8000211e:	f9478fe3          	beq	a5,s4,800020bc <kwait+0x4e>
        release(&pp->lock);
    80002122:	8526                	mv	a0,s1
    80002124:	ae1fe0ef          	jal	ra,80000c04 <release>
        havekids = 1;
    80002128:	8756                	mv	a4,s5
    8000212a:	bff9                	j	80002108 <kwait+0x9a>
    if(!havekids || killed(p)){
    8000212c:	c709                	beqz	a4,80002136 <kwait+0xc8>
    8000212e:	854a                	mv	a0,s2
    80002130:	f15ff0ef          	jal	ra,80002044 <killed>
    80002134:	c50d                	beqz	a0,8000215e <kwait+0xf0>
      release(&wait_lock);
    80002136:	0000e517          	auipc	a0,0xe
    8000213a:	84a50513          	addi	a0,a0,-1974 # 8000f980 <wait_lock>
    8000213e:	ac7fe0ef          	jal	ra,80000c04 <release>
      return -1;
    80002142:	59fd                	li	s3,-1
}
    80002144:	854e                	mv	a0,s3
    80002146:	60a6                	ld	ra,72(sp)
    80002148:	6406                	ld	s0,64(sp)
    8000214a:	74e2                	ld	s1,56(sp)
    8000214c:	7942                	ld	s2,48(sp)
    8000214e:	79a2                	ld	s3,40(sp)
    80002150:	7a02                	ld	s4,32(sp)
    80002152:	6ae2                	ld	s5,24(sp)
    80002154:	6b42                	ld	s6,16(sp)
    80002156:	6ba2                	ld	s7,8(sp)
    80002158:	6c02                	ld	s8,0(sp)
    8000215a:	6161                	addi	sp,sp,80
    8000215c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000215e:	85e2                	mv	a1,s8
    80002160:	854a                	mv	a0,s2
    80002162:	cabff0ef          	jal	ra,80001e0c <sleep>
    havekids = 0;
    80002166:	b7a9                	j	800020b0 <kwait+0x42>

0000000080002168 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002168:	7179                	addi	sp,sp,-48
    8000216a:	f406                	sd	ra,40(sp)
    8000216c:	f022                	sd	s0,32(sp)
    8000216e:	ec26                	sd	s1,24(sp)
    80002170:	e84a                	sd	s2,16(sp)
    80002172:	e44e                	sd	s3,8(sp)
    80002174:	e052                	sd	s4,0(sp)
    80002176:	1800                	addi	s0,sp,48
    80002178:	84aa                	mv	s1,a0
    8000217a:	892e                	mv	s2,a1
    8000217c:	89b2                	mv	s3,a2
    8000217e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002180:	e84ff0ef          	jal	ra,80001804 <myproc>
  if(user_dst){
    80002184:	cc99                	beqz	s1,800021a2 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    80002186:	86d2                	mv	a3,s4
    80002188:	864e                	mv	a2,s3
    8000218a:	85ca                	mv	a1,s2
    8000218c:	6928                	ld	a0,80(a0)
    8000218e:	bc4ff0ef          	jal	ra,80001552 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002192:	70a2                	ld	ra,40(sp)
    80002194:	7402                	ld	s0,32(sp)
    80002196:	64e2                	ld	s1,24(sp)
    80002198:	6942                	ld	s2,16(sp)
    8000219a:	69a2                	ld	s3,8(sp)
    8000219c:	6a02                	ld	s4,0(sp)
    8000219e:	6145                	addi	sp,sp,48
    800021a0:	8082                	ret
    memmove((char *)dst, src, len);
    800021a2:	000a061b          	sext.w	a2,s4
    800021a6:	85ce                	mv	a1,s3
    800021a8:	854a                	mv	a0,s2
    800021aa:	af3fe0ef          	jal	ra,80000c9c <memmove>
    return 0;
    800021ae:	8526                	mv	a0,s1
    800021b0:	b7cd                	j	80002192 <either_copyout+0x2a>

00000000800021b2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800021b2:	7179                	addi	sp,sp,-48
    800021b4:	f406                	sd	ra,40(sp)
    800021b6:	f022                	sd	s0,32(sp)
    800021b8:	ec26                	sd	s1,24(sp)
    800021ba:	e84a                	sd	s2,16(sp)
    800021bc:	e44e                	sd	s3,8(sp)
    800021be:	e052                	sd	s4,0(sp)
    800021c0:	1800                	addi	s0,sp,48
    800021c2:	892a                	mv	s2,a0
    800021c4:	84ae                	mv	s1,a1
    800021c6:	89b2                	mv	s3,a2
    800021c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800021ca:	e3aff0ef          	jal	ra,80001804 <myproc>
  if(user_src){
    800021ce:	cc99                	beqz	s1,800021ec <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    800021d0:	86d2                	mv	a3,s4
    800021d2:	864e                	mv	a2,s3
    800021d4:	85ca                	mv	a1,s2
    800021d6:	6928                	ld	a0,80(a0)
    800021d8:	c40ff0ef          	jal	ra,80001618 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800021dc:	70a2                	ld	ra,40(sp)
    800021de:	7402                	ld	s0,32(sp)
    800021e0:	64e2                	ld	s1,24(sp)
    800021e2:	6942                	ld	s2,16(sp)
    800021e4:	69a2                	ld	s3,8(sp)
    800021e6:	6a02                	ld	s4,0(sp)
    800021e8:	6145                	addi	sp,sp,48
    800021ea:	8082                	ret
    memmove(dst, (char*)src, len);
    800021ec:	000a061b          	sext.w	a2,s4
    800021f0:	85ce                	mv	a1,s3
    800021f2:	854a                	mv	a0,s2
    800021f4:	aa9fe0ef          	jal	ra,80000c9c <memmove>
    return 0;
    800021f8:	8526                	mv	a0,s1
    800021fa:	b7cd                	j	800021dc <either_copyin+0x2a>

00000000800021fc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800021fc:	715d                	addi	sp,sp,-80
    800021fe:	e486                	sd	ra,72(sp)
    80002200:	e0a2                	sd	s0,64(sp)
    80002202:	fc26                	sd	s1,56(sp)
    80002204:	f84a                	sd	s2,48(sp)
    80002206:	f44e                	sd	s3,40(sp)
    80002208:	f052                	sd	s4,32(sp)
    8000220a:	ec56                	sd	s5,24(sp)
    8000220c:	e85a                	sd	s6,16(sp)
    8000220e:	e45e                	sd	s7,8(sp)
    80002210:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002212:	00005517          	auipc	a0,0x5
    80002216:	eae50513          	addi	a0,a0,-338 # 800070c0 <digits+0x88>
    8000221a:	aaafe0ef          	jal	ra,800004c4 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000221e:	0000e497          	auipc	s1,0xe
    80002222:	cd248493          	addi	s1,s1,-814 # 8000fef0 <proc+0x158>
    80002226:	00013917          	auipc	s2,0x13
    8000222a:	6ca90913          	addi	s2,s2,1738 # 800158f0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000222e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002230:	00005997          	auipc	s3,0x5
    80002234:	fe898993          	addi	s3,s3,-24 # 80007218 <digits+0x1e0>
    printf("%d %s %s", p->pid, state, p->name);
    80002238:	00005a97          	auipc	s5,0x5
    8000223c:	fe8a8a93          	addi	s5,s5,-24 # 80007220 <digits+0x1e8>
    printf("\n");
    80002240:	00005a17          	auipc	s4,0x5
    80002244:	e80a0a13          	addi	s4,s4,-384 # 800070c0 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002248:	00005b97          	auipc	s7,0x5
    8000224c:	018b8b93          	addi	s7,s7,24 # 80007260 <states.0>
    80002250:	a829                	j	8000226a <procdump+0x6e>
    printf("%d %s %s", p->pid, state, p->name);
    80002252:	ed86a583          	lw	a1,-296(a3)
    80002256:	8556                	mv	a0,s5
    80002258:	a6cfe0ef          	jal	ra,800004c4 <printf>
    printf("\n");
    8000225c:	8552                	mv	a0,s4
    8000225e:	a66fe0ef          	jal	ra,800004c4 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002262:	16848493          	addi	s1,s1,360
    80002266:	03248163          	beq	s1,s2,80002288 <procdump+0x8c>
    if(p->state == UNUSED)
    8000226a:	86a6                	mv	a3,s1
    8000226c:	ec04a783          	lw	a5,-320(s1)
    80002270:	dbed                	beqz	a5,80002262 <procdump+0x66>
      state = "???";
    80002272:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002274:	fcfb6fe3          	bltu	s6,a5,80002252 <procdump+0x56>
    80002278:	1782                	slli	a5,a5,0x20
    8000227a:	9381                	srli	a5,a5,0x20
    8000227c:	078e                	slli	a5,a5,0x3
    8000227e:	97de                	add	a5,a5,s7
    80002280:	6390                	ld	a2,0(a5)
    80002282:	fa61                	bnez	a2,80002252 <procdump+0x56>
      state = "???";
    80002284:	864e                	mv	a2,s3
    80002286:	b7f1                	j	80002252 <procdump+0x56>
  }
}
    80002288:	60a6                	ld	ra,72(sp)
    8000228a:	6406                	ld	s0,64(sp)
    8000228c:	74e2                	ld	s1,56(sp)
    8000228e:	7942                	ld	s2,48(sp)
    80002290:	79a2                	ld	s3,40(sp)
    80002292:	7a02                	ld	s4,32(sp)
    80002294:	6ae2                	ld	s5,24(sp)
    80002296:	6b42                	ld	s6,16(sp)
    80002298:	6ba2                	ld	s7,8(sp)
    8000229a:	6161                	addi	sp,sp,80
    8000229c:	8082                	ret

000000008000229e <sys_dump_proc>:

int
sys_dump_proc(void)
{
    8000229e:	711d                	addi	sp,sp,-96
    800022a0:	ec86                	sd	ra,88(sp)
    800022a2:	e8a2                	sd	s0,80(sp)
    800022a4:	e4a6                	sd	s1,72(sp)
    800022a6:	e0ca                	sd	s2,64(sp)
    800022a8:	fc4e                	sd	s3,56(sp)
    800022aa:	1080                	addi	s0,sp,96
    uint64 addr;
    // 获取用户传入的指针地址（第0个参数）
    argaddr(0, &addr);  // 注意：argaddr 是 void，不返回错误
    800022ac:	fc840593          	addi	a1,s0,-56
    800022b0:	4501                	li	a0,0
    800022b2:	50e000ef          	jal	ra,800027c0 <argaddr>

    if (addr == 0)
    800022b6:	fc843783          	ld	a5,-56(s0)
    800022ba:	cfad                	beqz	a5,80002334 <sys_dump_proc+0x96>
    800022bc:	0000e497          	auipc	s1,0xe
    800022c0:	adc48493          	addi	s1,s1,-1316 # 8000fd98 <proc>
    800022c4:	00013997          	auipc	s3,0x13
    800022c8:	4d498993          	addi	s3,s3,1236 # 80015798 <tickslock>
    800022cc:	4901                	li	s2,0
        return -1;  // 无效地址

    for (int i = 0; i < NPROC; i++) {
        struct proc *p = &proc[i];  // ← 现在在 proc.c 中，proc[] 可见！
        acquire(&p->lock);
    800022ce:	8526                	mv	a0,s1
    800022d0:	89dfe0ef          	jal	ra,80000b6c <acquire>
        struct pstat ps;
        ps.inuse = (p->state != UNUSED);
    800022d4:	4c9c                	lw	a5,24(s1)
    800022d6:	00f03733          	snez	a4,a5
    800022da:	fae42423          	sw	a4,-88(s0)
        ps.pid = p->pid;
    800022de:	5898                	lw	a4,48(s1)
    800022e0:	fae42623          	sw	a4,-84(s0)
        ps.state = p->state;
    800022e4:	fcf42023          	sw	a5,-64(s0)
        safestrcpy(ps.name, p->name, sizeof(ps.name));
    800022e8:	4641                	li	a2,16
    800022ea:	15848593          	addi	a1,s1,344
    800022ee:	fb040513          	addi	a0,s0,-80
    800022f2:	a95fe0ef          	jal	ra,80000d86 <safestrcpy>
        release(&p->lock);
    800022f6:	8526                	mv	a0,s1
    800022f8:	90dfe0ef          	jal	ra,80000c04 <release>

        // 安全拷贝到用户空间
        if (copyout(myproc()->pagetable, addr + i * sizeof(ps), (char*)&ps, sizeof(ps)) < 0) {
    800022fc:	d08ff0ef          	jal	ra,80001804 <myproc>
    80002300:	46f1                	li	a3,28
    80002302:	fa840613          	addi	a2,s0,-88
    80002306:	fc843583          	ld	a1,-56(s0)
    8000230a:	95ca                	add	a1,a1,s2
    8000230c:	6928                	ld	a0,80(a0)
    8000230e:	a44ff0ef          	jal	ra,80001552 <copyout>
    80002312:	00054963          	bltz	a0,80002324 <sys_dump_proc+0x86>
    for (int i = 0; i < NPROC; i++) {
    80002316:	16848493          	addi	s1,s1,360
    8000231a:	0971                	addi	s2,s2,28
    8000231c:	fb3499e3          	bne	s1,s3,800022ce <sys_dump_proc+0x30>
            return -1;
        }
    }
    return 0;
    80002320:	4501                	li	a0,0
    80002322:	a011                	j	80002326 <sys_dump_proc+0x88>
            return -1;
    80002324:	557d                	li	a0,-1
}
    80002326:	60e6                	ld	ra,88(sp)
    80002328:	6446                	ld	s0,80(sp)
    8000232a:	64a6                	ld	s1,72(sp)
    8000232c:	6906                	ld	s2,64(sp)
    8000232e:	79e2                	ld	s3,56(sp)
    80002330:	6125                	addi	sp,sp,96
    80002332:	8082                	ret
        return -1;  // 无效地址
    80002334:	557d                	li	a0,-1
    80002336:	bfc5                	j	80002326 <sys_dump_proc+0x88>

0000000080002338 <swtch>:
# 保存当前寄存器到 old，然后从 new 加载寄存器。

.globl swtch
swtch:
        # 保存当前的寄存器到 old 中
        sd ra, 0(a0)   # 保存返回地址寄存器 ra
    80002338:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)   # 保存栈指针寄存器 sp
    8000233c:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)  # 保存寄存器 s0
    80002340:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)  # 保存寄存器 s1
    80002342:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)  # 保存寄存器 s2
    80002344:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)  # 保存寄存器 s3
    80002348:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)  # 保存寄存器 s4
    8000234c:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)  # 保存寄存器 s5
    80002350:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)  # 保存寄存器 s6
    80002354:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)  # 保存寄存器 s7
    80002358:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)  # 保存寄存器 s8
    8000235c:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)  # 保存寄存器 s9
    80002360:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0) # 保存寄存器 s10
    80002364:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)# 保存寄存器 s11
    80002368:	07b53423          	sd	s11,104(a0)

        # 从 new 加载寄存器
        ld ra, 0(a1)   # 加载返回地址寄存器 ra
    8000236c:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)   # 加载栈指针寄存器 sp
    80002370:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)  # 加载寄存器 s0
    80002374:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)  # 加载寄存器 s1
    80002376:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)  # 加载寄存器 s2
    80002378:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)  # 加载寄存器 s3
    8000237c:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)  # 加载寄存器 s4
    80002380:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)  # 加载寄存器 s5
    80002384:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)  # 加载寄存器 s6
    80002388:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)  # 加载寄存器 s7
    8000238c:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)  # 加载寄存器 s8
    80002390:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)  # 加载寄存器 s9
    80002394:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1) # 加载寄存器 s10
    80002398:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)# 加载寄存器 s11
    8000239c:	0685bd83          	ld	s11,104(a1)

        ret             # 返回，完成上下文切换
    800023a0:	8082                	ret

00000000800023a2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800023a2:	1141                	addi	sp,sp,-16
    800023a4:	e406                	sd	ra,8(sp)
    800023a6:	e022                	sd	s0,0(sp)
    800023a8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800023aa:	00005597          	auipc	a1,0x5
    800023ae:	ee658593          	addi	a1,a1,-282 # 80007290 <states.0+0x30>
    800023b2:	00013517          	auipc	a0,0x13
    800023b6:	3e650513          	addi	a0,a0,998 # 80015798 <tickslock>
    800023ba:	f32fe0ef          	jal	ra,80000aec <initlock>
}
    800023be:	60a2                	ld	ra,8(sp)
    800023c0:	6402                	ld	s0,0(sp)
    800023c2:	0141                	addi	sp,sp,16
    800023c4:	8082                	ret

00000000800023c6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800023c6:	1141                	addi	sp,sp,-16
    800023c8:	e422                	sd	s0,8(sp)
    800023ca:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800023cc:	00003797          	auipc	a5,0x3
    800023d0:	e7478793          	addi	a5,a5,-396 # 80005240 <kernelvec>
    800023d4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800023d8:	6422                	ld	s0,8(sp)
    800023da:	0141                	addi	sp,sp,16
    800023dc:	8082                	ret

00000000800023de <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    800023de:	1141                	addi	sp,sp,-16
    800023e0:	e406                	sd	ra,8(sp)
    800023e2:	e022                	sd	s0,0(sp)
    800023e4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800023e6:	c1eff0ef          	jal	ra,80001804 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023ea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800023ee:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800023f0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800023f4:	04000737          	lui	a4,0x4000
    800023f8:	00004797          	auipc	a5,0x4
    800023fc:	c0878793          	addi	a5,a5,-1016 # 80006000 <_trampoline>
    80002400:	00004697          	auipc	a3,0x4
    80002404:	c0068693          	addi	a3,a3,-1024 # 80006000 <_trampoline>
    80002408:	8f95                	sub	a5,a5,a3
    8000240a:	177d                	addi	a4,a4,-1
    8000240c:	0732                	slli	a4,a4,0xc
    8000240e:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002410:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002414:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002416:	18002773          	csrr	a4,satp
    8000241a:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000241c:	6d38                	ld	a4,88(a0)
    8000241e:	613c                	ld	a5,64(a0)
    80002420:	6685                	lui	a3,0x1
    80002422:	97b6                	add	a5,a5,a3
    80002424:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002426:	6d3c                	ld	a5,88(a0)
    80002428:	00000717          	auipc	a4,0x0
    8000242c:	0f470713          	addi	a4,a4,244 # 8000251c <usertrap>
    80002430:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002432:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002434:	8712                	mv	a4,tp
    80002436:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002438:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000243c:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002440:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002444:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002448:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000244a:	6f9c                	ld	a5,24(a5)
    8000244c:	14179073          	csrw	sepc,a5
}
    80002450:	60a2                	ld	ra,8(sp)
    80002452:	6402                	ld	s0,0(sp)
    80002454:	0141                	addi	sp,sp,16
    80002456:	8082                	ret

0000000080002458 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002458:	1101                	addi	sp,sp,-32
    8000245a:	ec06                	sd	ra,24(sp)
    8000245c:	e822                	sd	s0,16(sp)
    8000245e:	e426                	sd	s1,8(sp)
    80002460:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    80002462:	b76ff0ef          	jal	ra,800017d8 <cpuid>
    80002466:	cd19                	beqz	a0,80002484 <clockintr+0x2c>
  asm volatile("csrr %0, time" : "=r" (x) );
    80002468:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    8000246c:	000f4737          	lui	a4,0xf4
    80002470:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80002474:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80002476:	14d79073          	csrw	0x14d,a5
}
    8000247a:	60e2                	ld	ra,24(sp)
    8000247c:	6442                	ld	s0,16(sp)
    8000247e:	64a2                	ld	s1,8(sp)
    80002480:	6105                	addi	sp,sp,32
    80002482:	8082                	ret
    acquire(&tickslock);
    80002484:	00013497          	auipc	s1,0x13
    80002488:	31448493          	addi	s1,s1,788 # 80015798 <tickslock>
    8000248c:	8526                	mv	a0,s1
    8000248e:	edefe0ef          	jal	ra,80000b6c <acquire>
    ticks++;
    80002492:	00005517          	auipc	a0,0x5
    80002496:	3d650513          	addi	a0,a0,982 # 80007868 <ticks>
    8000249a:	411c                	lw	a5,0(a0)
    8000249c:	2785                	addiw	a5,a5,1
    8000249e:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    800024a0:	9b9ff0ef          	jal	ra,80001e58 <wakeup>
    release(&tickslock);
    800024a4:	8526                	mv	a0,s1
    800024a6:	f5efe0ef          	jal	ra,80000c04 <release>
    800024aa:	bf7d                	j	80002468 <clockintr+0x10>

00000000800024ac <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800024ac:	1101                	addi	sp,sp,-32
    800024ae:	ec06                	sd	ra,24(sp)
    800024b0:	e822                	sd	s0,16(sp)
    800024b2:	e426                	sd	s1,8(sp)
    800024b4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800024b6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    800024ba:	57fd                	li	a5,-1
    800024bc:	17fe                	slli	a5,a5,0x3f
    800024be:	07a5                	addi	a5,a5,9
    800024c0:	00f70d63          	beq	a4,a5,800024da <devintr+0x2e>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    800024c4:	57fd                	li	a5,-1
    800024c6:	17fe                	slli	a5,a5,0x3f
    800024c8:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    800024ca:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    800024cc:	04f70463          	beq	a4,a5,80002514 <devintr+0x68>
  }
}
    800024d0:	60e2                	ld	ra,24(sp)
    800024d2:	6442                	ld	s0,16(sp)
    800024d4:	64a2                	ld	s1,8(sp)
    800024d6:	6105                	addi	sp,sp,32
    800024d8:	8082                	ret
    int irq = plic_claim();
    800024da:	60f020ef          	jal	ra,800052e8 <plic_claim>
    800024de:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800024e0:	47a9                	li	a5,10
    800024e2:	02f50363          	beq	a0,a5,80002508 <devintr+0x5c>
    } else if(irq == VIRTIO0_IRQ){
    800024e6:	4785                	li	a5,1
    800024e8:	02f50363          	beq	a0,a5,8000250e <devintr+0x62>
    return 1;
    800024ec:	4505                	li	a0,1
    } else if(irq){
    800024ee:	d0ed                	beqz	s1,800024d0 <devintr+0x24>
      printf("unexpected interrupt irq=%d\n", irq);
    800024f0:	85a6                	mv	a1,s1
    800024f2:	00005517          	auipc	a0,0x5
    800024f6:	da650513          	addi	a0,a0,-602 # 80007298 <states.0+0x38>
    800024fa:	fcbfd0ef          	jal	ra,800004c4 <printf>
      plic_complete(irq);
    800024fe:	8526                	mv	a0,s1
    80002500:	609020ef          	jal	ra,80005308 <plic_complete>
    return 1;
    80002504:	4505                	li	a0,1
    80002506:	b7e9                	j	800024d0 <devintr+0x24>
      uartintr();
    80002508:	c50fe0ef          	jal	ra,80000958 <uartintr>
    8000250c:	bfcd                	j	800024fe <devintr+0x52>
      virtio_disk_intr();
    8000250e:	26a030ef          	jal	ra,80005778 <virtio_disk_intr>
    80002512:	b7f5                	j	800024fe <devintr+0x52>
    clockintr();
    80002514:	f45ff0ef          	jal	ra,80002458 <clockintr>
    return 2;
    80002518:	4509                	li	a0,2
    8000251a:	bf5d                	j	800024d0 <devintr+0x24>

000000008000251c <usertrap>:
{
    8000251c:	1101                	addi	sp,sp,-32
    8000251e:	ec06                	sd	ra,24(sp)
    80002520:	e822                	sd	s0,16(sp)
    80002522:	e426                	sd	s1,8(sp)
    80002524:	e04a                	sd	s2,0(sp)
    80002526:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002528:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000252c:	1007f793          	andi	a5,a5,256
    80002530:	eba5                	bnez	a5,800025a0 <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002532:	00003797          	auipc	a5,0x3
    80002536:	d0e78793          	addi	a5,a5,-754 # 80005240 <kernelvec>
    8000253a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000253e:	ac6ff0ef          	jal	ra,80001804 <myproc>
    80002542:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002544:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002546:	14102773          	csrr	a4,sepc
    8000254a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000254c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002550:	47a1                	li	a5,8
    80002552:	04f70d63          	beq	a4,a5,800025ac <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    80002556:	f57ff0ef          	jal	ra,800024ac <devintr>
    8000255a:	892a                	mv	s2,a0
    8000255c:	e945                	bnez	a0,8000260c <usertrap+0xf0>
    8000255e:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002562:	47bd                	li	a5,15
    80002564:	08f70863          	beq	a4,a5,800025f4 <usertrap+0xd8>
    80002568:	14202773          	csrr	a4,scause
    8000256c:	47b5                	li	a5,13
    8000256e:	08f70363          	beq	a4,a5,800025f4 <usertrap+0xd8>
    80002572:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    80002576:	5890                	lw	a2,48(s1)
    80002578:	00005517          	auipc	a0,0x5
    8000257c:	d6050513          	addi	a0,a0,-672 # 800072d8 <states.0+0x78>
    80002580:	f45fd0ef          	jal	ra,800004c4 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002584:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002588:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    8000258c:	00005517          	auipc	a0,0x5
    80002590:	d7c50513          	addi	a0,a0,-644 # 80007308 <states.0+0xa8>
    80002594:	f31fd0ef          	jal	ra,800004c4 <printf>
    setkilled(p);
    80002598:	8526                	mv	a0,s1
    8000259a:	a87ff0ef          	jal	ra,80002020 <setkilled>
    8000259e:	a035                	j	800025ca <usertrap+0xae>
    panic("usertrap: not from user mode");
    800025a0:	00005517          	auipc	a0,0x5
    800025a4:	d1850513          	addi	a0,a0,-744 # 800072b8 <states.0+0x58>
    800025a8:	9e2fe0ef          	jal	ra,8000078a <panic>
    if(killed(p))
    800025ac:	a99ff0ef          	jal	ra,80002044 <killed>
    800025b0:	ed15                	bnez	a0,800025ec <usertrap+0xd0>
    p->trapframe->epc += 4;
    800025b2:	6cb8                	ld	a4,88(s1)
    800025b4:	6f1c                	ld	a5,24(a4)
    800025b6:	0791                	addi	a5,a5,4
    800025b8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025ba:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800025be:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025c2:	10079073          	csrw	sstatus,a5
    syscall();
    800025c6:	246000ef          	jal	ra,8000280c <syscall>
  if(killed(p))
    800025ca:	8526                	mv	a0,s1
    800025cc:	a79ff0ef          	jal	ra,80002044 <killed>
    800025d0:	e139                	bnez	a0,80002616 <usertrap+0xfa>
  prepare_return();
    800025d2:	e0dff0ef          	jal	ra,800023de <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800025d6:	68a8                	ld	a0,80(s1)
    800025d8:	8131                	srli	a0,a0,0xc
    800025da:	57fd                	li	a5,-1
    800025dc:	17fe                	slli	a5,a5,0x3f
    800025de:	8d5d                	or	a0,a0,a5
}
    800025e0:	60e2                	ld	ra,24(sp)
    800025e2:	6442                	ld	s0,16(sp)
    800025e4:	64a2                	ld	s1,8(sp)
    800025e6:	6902                	ld	s2,0(sp)
    800025e8:	6105                	addi	sp,sp,32
    800025ea:	8082                	ret
      kexit(-1);
    800025ec:	557d                	li	a0,-1
    800025ee:	92bff0ef          	jal	ra,80001f18 <kexit>
    800025f2:	b7c1                	j	800025b2 <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    800025f4:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    800025f8:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    800025fc:	164d                	addi	a2,a2,-13
    800025fe:	00163613          	seqz	a2,a2
    80002602:	68a8                	ld	a0,80(s1)
    80002604:	eddfe0ef          	jal	ra,800014e0 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002608:	f169                	bnez	a0,800025ca <usertrap+0xae>
    8000260a:	b7a5                	j	80002572 <usertrap+0x56>
  if(killed(p))
    8000260c:	8526                	mv	a0,s1
    8000260e:	a37ff0ef          	jal	ra,80002044 <killed>
    80002612:	c511                	beqz	a0,8000261e <usertrap+0x102>
    80002614:	a011                	j	80002618 <usertrap+0xfc>
    80002616:	4901                	li	s2,0
    kexit(-1);
    80002618:	557d                	li	a0,-1
    8000261a:	8ffff0ef          	jal	ra,80001f18 <kexit>
  if(which_dev == 2)
    8000261e:	4789                	li	a5,2
    80002620:	faf919e3          	bne	s2,a5,800025d2 <usertrap+0xb6>
    yield();
    80002624:	fbcff0ef          	jal	ra,80001de0 <yield>
    80002628:	b76d                	j	800025d2 <usertrap+0xb6>

000000008000262a <kerneltrap>:
{
    8000262a:	7179                	addi	sp,sp,-48
    8000262c:	f406                	sd	ra,40(sp)
    8000262e:	f022                	sd	s0,32(sp)
    80002630:	ec26                	sd	s1,24(sp)
    80002632:	e84a                	sd	s2,16(sp)
    80002634:	e44e                	sd	s3,8(sp)
    80002636:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002638:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000263c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002640:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002644:	1004f793          	andi	a5,s1,256
    80002648:	c795                	beqz	a5,80002674 <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000264a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000264e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002650:	eb85                	bnez	a5,80002680 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    80002652:	e5bff0ef          	jal	ra,800024ac <devintr>
    80002656:	c91d                	beqz	a0,8000268c <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0)
    80002658:	4789                	li	a5,2
    8000265a:	04f50a63          	beq	a0,a5,800026ae <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000265e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002662:	10049073          	csrw	sstatus,s1
}
    80002666:	70a2                	ld	ra,40(sp)
    80002668:	7402                	ld	s0,32(sp)
    8000266a:	64e2                	ld	s1,24(sp)
    8000266c:	6942                	ld	s2,16(sp)
    8000266e:	69a2                	ld	s3,8(sp)
    80002670:	6145                	addi	sp,sp,48
    80002672:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002674:	00005517          	auipc	a0,0x5
    80002678:	cbc50513          	addi	a0,a0,-836 # 80007330 <states.0+0xd0>
    8000267c:	90efe0ef          	jal	ra,8000078a <panic>
    panic("kerneltrap: interrupts enabled");
    80002680:	00005517          	auipc	a0,0x5
    80002684:	cd850513          	addi	a0,a0,-808 # 80007358 <states.0+0xf8>
    80002688:	902fe0ef          	jal	ra,8000078a <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000268c:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002690:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    80002694:	85ce                	mv	a1,s3
    80002696:	00005517          	auipc	a0,0x5
    8000269a:	ce250513          	addi	a0,a0,-798 # 80007378 <states.0+0x118>
    8000269e:	e27fd0ef          	jal	ra,800004c4 <printf>
    panic("kerneltrap");
    800026a2:	00005517          	auipc	a0,0x5
    800026a6:	cfe50513          	addi	a0,a0,-770 # 800073a0 <states.0+0x140>
    800026aa:	8e0fe0ef          	jal	ra,8000078a <panic>
  if(which_dev == 2 && myproc() != 0)
    800026ae:	956ff0ef          	jal	ra,80001804 <myproc>
    800026b2:	d555                	beqz	a0,8000265e <kerneltrap+0x34>
    yield();
    800026b4:	f2cff0ef          	jal	ra,80001de0 <yield>
    800026b8:	b75d                	j	8000265e <kerneltrap+0x34>

00000000800026ba <argraw>:
}

// 获取第 n 个系统调用的原始参数（未处理过的原始值）
static uint64
argraw(int n)
{
    800026ba:	1101                	addi	sp,sp,-32
    800026bc:	ec06                	sd	ra,24(sp)
    800026be:	e822                	sd	s0,16(sp)
    800026c0:	e426                	sd	s1,8(sp)
    800026c2:	1000                	addi	s0,sp,32
    800026c4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800026c6:	93eff0ef          	jal	ra,80001804 <myproc>
  switch (n) {
    800026ca:	4795                	li	a5,5
    800026cc:	0497e163          	bltu	a5,s1,8000270e <argraw+0x54>
    800026d0:	048a                	slli	s1,s1,0x2
    800026d2:	00005717          	auipc	a4,0x5
    800026d6:	d0670713          	addi	a4,a4,-762 # 800073d8 <states.0+0x178>
    800026da:	94ba                	add	s1,s1,a4
    800026dc:	409c                	lw	a5,0(s1)
    800026de:	97ba                	add	a5,a5,a4
    800026e0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800026e2:	6d3c                	ld	a5,88(a0)
    800026e4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");  // 如果参数 n 无效，触发 panic
  return -1;
}
    800026e6:	60e2                	ld	ra,24(sp)
    800026e8:	6442                	ld	s0,16(sp)
    800026ea:	64a2                	ld	s1,8(sp)
    800026ec:	6105                	addi	sp,sp,32
    800026ee:	8082                	ret
    return p->trapframe->a1;
    800026f0:	6d3c                	ld	a5,88(a0)
    800026f2:	7fa8                	ld	a0,120(a5)
    800026f4:	bfcd                	j	800026e6 <argraw+0x2c>
    return p->trapframe->a2;
    800026f6:	6d3c                	ld	a5,88(a0)
    800026f8:	63c8                	ld	a0,128(a5)
    800026fa:	b7f5                	j	800026e6 <argraw+0x2c>
    return p->trapframe->a3;
    800026fc:	6d3c                	ld	a5,88(a0)
    800026fe:	67c8                	ld	a0,136(a5)
    80002700:	b7dd                	j	800026e6 <argraw+0x2c>
    return p->trapframe->a4;
    80002702:	6d3c                	ld	a5,88(a0)
    80002704:	6bc8                	ld	a0,144(a5)
    80002706:	b7c5                	j	800026e6 <argraw+0x2c>
    return p->trapframe->a5;
    80002708:	6d3c                	ld	a5,88(a0)
    8000270a:	6fc8                	ld	a0,152(a5)
    8000270c:	bfe9                	j	800026e6 <argraw+0x2c>
  panic("argraw");  // 如果参数 n 无效，触发 panic
    8000270e:	00005517          	auipc	a0,0x5
    80002712:	ca250513          	addi	a0,a0,-862 # 800073b0 <states.0+0x150>
    80002716:	874fe0ef          	jal	ra,8000078a <panic>

000000008000271a <fetchaddr>:
{
    8000271a:	1101                	addi	sp,sp,-32
    8000271c:	ec06                	sd	ra,24(sp)
    8000271e:	e822                	sd	s0,16(sp)
    80002720:	e426                	sd	s1,8(sp)
    80002722:	e04a                	sd	s2,0(sp)
    80002724:	1000                	addi	s0,sp,32
    80002726:	84aa                	mv	s1,a0
    80002728:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000272a:	8daff0ef          	jal	ra,80001804 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // 这两个条件都需要检查，防止溢出
    8000272e:	653c                	ld	a5,72(a0)
    80002730:	02f4f663          	bgeu	s1,a5,8000275c <fetchaddr+0x42>
    80002734:	00848713          	addi	a4,s1,8
    80002738:	02e7e463          	bltu	a5,a4,80002760 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000273c:	46a1                	li	a3,8
    8000273e:	8626                	mv	a2,s1
    80002740:	85ca                	mv	a1,s2
    80002742:	6928                	ld	a0,80(a0)
    80002744:	ed5fe0ef          	jal	ra,80001618 <copyin>
    80002748:	00a03533          	snez	a0,a0
    8000274c:	40a00533          	neg	a0,a0
}
    80002750:	60e2                	ld	ra,24(sp)
    80002752:	6442                	ld	s0,16(sp)
    80002754:	64a2                	ld	s1,8(sp)
    80002756:	6902                	ld	s2,0(sp)
    80002758:	6105                	addi	sp,sp,32
    8000275a:	8082                	ret
    return -1;
    8000275c:	557d                	li	a0,-1
    8000275e:	bfcd                	j	80002750 <fetchaddr+0x36>
    80002760:	557d                	li	a0,-1
    80002762:	b7fd                	j	80002750 <fetchaddr+0x36>

0000000080002764 <fetchstr>:
{
    80002764:	7179                	addi	sp,sp,-48
    80002766:	f406                	sd	ra,40(sp)
    80002768:	f022                	sd	s0,32(sp)
    8000276a:	ec26                	sd	s1,24(sp)
    8000276c:	e84a                	sd	s2,16(sp)
    8000276e:	e44e                	sd	s3,8(sp)
    80002770:	1800                	addi	s0,sp,48
    80002772:	892a                	mv	s2,a0
    80002774:	84ae                	mv	s1,a1
    80002776:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002778:	88cff0ef          	jal	ra,80001804 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    8000277c:	86ce                	mv	a3,s3
    8000277e:	864a                	mv	a2,s2
    80002780:	85a6                	mv	a1,s1
    80002782:	6928                	ld	a0,80(a0)
    80002784:	c8dfe0ef          	jal	ra,80001410 <copyinstr>
    80002788:	00054c63          	bltz	a0,800027a0 <fetchstr+0x3c>
  return strlen(buf);  // 返回字符串长度
    8000278c:	8526                	mv	a0,s1
    8000278e:	e2afe0ef          	jal	ra,80000db8 <strlen>
}
    80002792:	70a2                	ld	ra,40(sp)
    80002794:	7402                	ld	s0,32(sp)
    80002796:	64e2                	ld	s1,24(sp)
    80002798:	6942                	ld	s2,16(sp)
    8000279a:	69a2                	ld	s3,8(sp)
    8000279c:	6145                	addi	sp,sp,48
    8000279e:	8082                	ret
    return -1;
    800027a0:	557d                	li	a0,-1
    800027a2:	bfc5                	j	80002792 <fetchstr+0x2e>

00000000800027a4 <argint>:

// 获取第 n 个 32 位的系统调用参数并将其存入 ip 中
void
argint(int n, int *ip)
{
    800027a4:	1101                	addi	sp,sp,-32
    800027a6:	ec06                	sd	ra,24(sp)
    800027a8:	e822                	sd	s0,16(sp)
    800027aa:	e426                	sd	s1,8(sp)
    800027ac:	1000                	addi	s0,sp,32
    800027ae:	84ae                	mv	s1,a1
  *ip = argraw(n);  // 通过 argraw 获取原始参数并存储
    800027b0:	f0bff0ef          	jal	ra,800026ba <argraw>
    800027b4:	c088                	sw	a0,0(s1)
}
    800027b6:	60e2                	ld	ra,24(sp)
    800027b8:	6442                	ld	s0,16(sp)
    800027ba:	64a2                	ld	s1,8(sp)
    800027bc:	6105                	addi	sp,sp,32
    800027be:	8082                	ret

00000000800027c0 <argaddr>:

// 获取第 n 个参数并将其作为指针返回。
// 不进行合法性检查，因为 copyin 和 copyout 会处理这些检查。
void
argaddr(int n, uint64 *ip)
{
    800027c0:	1101                	addi	sp,sp,-32
    800027c2:	ec06                	sd	ra,24(sp)
    800027c4:	e822                	sd	s0,16(sp)
    800027c6:	e426                	sd	s1,8(sp)
    800027c8:	1000                	addi	s0,sp,32
    800027ca:	84ae                	mv	s1,a1
  *ip = argraw(n);  // 通过 argraw 获取原始参数并存储
    800027cc:	eefff0ef          	jal	ra,800026ba <argraw>
    800027d0:	e088                	sd	a0,0(s1)
}
    800027d2:	60e2                	ld	ra,24(sp)
    800027d4:	6442                	ld	s0,16(sp)
    800027d6:	64a2                	ld	s1,8(sp)
    800027d8:	6105                	addi	sp,sp,32
    800027da:	8082                	ret

00000000800027dc <argstr>:
// 获取第 n 个参数，假设它是一个以 null 结尾的字符串。
// 将该字符串拷贝到 buf 中，最多拷贝 max 个字符。
// 成功时返回字符串长度（包括 null），出错时返回 -1。
int
argstr(int n, char *buf, int max)
{
    800027dc:	7179                	addi	sp,sp,-48
    800027de:	f406                	sd	ra,40(sp)
    800027e0:	f022                	sd	s0,32(sp)
    800027e2:	ec26                	sd	s1,24(sp)
    800027e4:	e84a                	sd	s2,16(sp)
    800027e6:	1800                	addi	s0,sp,48
    800027e8:	84ae                	mv	s1,a1
    800027ea:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);  // 获取第 n 个参数的地址
    800027ec:	fd840593          	addi	a1,s0,-40
    800027f0:	fd1ff0ef          	jal	ra,800027c0 <argaddr>
  return fetchstr(addr, buf, max);  // 使用 fetchstr 获取字符串内容
    800027f4:	864a                	mv	a2,s2
    800027f6:	85a6                	mv	a1,s1
    800027f8:	fd843503          	ld	a0,-40(s0)
    800027fc:	f69ff0ef          	jal	ra,80002764 <fetchstr>
}
    80002800:	70a2                	ld	ra,40(sp)
    80002802:	7402                	ld	s0,32(sp)
    80002804:	64e2                	ld	s1,24(sp)
    80002806:	6942                	ld	s2,16(sp)
    80002808:	6145                	addi	sp,sp,48
    8000280a:	8082                	ret

000000008000280c <syscall>:
};

// 系统调用的入口函数
void
syscall(void)
{
    8000280c:	1101                	addi	sp,sp,-32
    8000280e:	ec06                	sd	ra,24(sp)
    80002810:	e822                	sd	s0,16(sp)
    80002812:	e426                	sd	s1,8(sp)
    80002814:	e04a                	sd	s2,0(sp)
    80002816:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002818:	fedfe0ef          	jal	ra,80001804 <myproc>
    8000281c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;  // 从 trapframe 中获取系统调用号
    8000281e:	05853903          	ld	s2,88(a0)
    80002822:	0a893783          	ld	a5,168(s2)
    80002826:	0007869b          	sext.w	a3,a5
  // 检查系统调用号是否合法，且确保有对应的处理函数
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000282a:	37fd                	addiw	a5,a5,-1
    8000282c:	4755                	li	a4,21
    8000282e:	00f76f63          	bltu	a4,a5,8000284c <syscall+0x40>
    80002832:	00369713          	slli	a4,a3,0x3
    80002836:	00005797          	auipc	a5,0x5
    8000283a:	bba78793          	addi	a5,a5,-1094 # 800073f0 <syscalls>
    8000283e:	97ba                	add	a5,a5,a4
    80002840:	639c                	ld	a5,0(a5)
    80002842:	c789                	beqz	a5,8000284c <syscall+0x40>
    // 根据系统调用号查找对应的系统调用函数并调用
    // 系统调用的返回值会存储在 p->trapframe->a0 中
    p->trapframe->a0 = syscalls[num]();
    80002844:	9782                	jalr	a5
    80002846:	06a93823          	sd	a0,112(s2)
    8000284a:	a829                	j	80002864 <syscall+0x58>
  } else {
    // 如果找不到有效的系统调用，打印错误信息
    printf("%d %s: unknown sys call %d\n",
    8000284c:	15848613          	addi	a2,s1,344
    80002850:	588c                	lw	a1,48(s1)
    80002852:	00005517          	auipc	a0,0x5
    80002856:	b6650513          	addi	a0,a0,-1178 # 800073b8 <states.0+0x158>
    8000285a:	c6bfd0ef          	jal	ra,800004c4 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;  // 设置返回值为 -1 表示错误
    8000285e:	6cbc                	ld	a5,88(s1)
    80002860:	577d                	li	a4,-1
    80002862:	fbb8                	sd	a4,112(a5)
  }
}
    80002864:	60e2                	ld	ra,24(sp)
    80002866:	6442                	ld	s0,16(sp)
    80002868:	64a2                	ld	s1,8(sp)
    8000286a:	6902                	ld	s2,0(sp)
    8000286c:	6105                	addi	sp,sp,32
    8000286e:	8082                	ret

0000000080002870 <sys_exit>:
#include "vm.h"

// 进程退出系统调用
uint64
sys_exit(void)
{
    80002870:	1101                	addi	sp,sp,-32
    80002872:	ec06                	sd	ra,24(sp)
    80002874:	e822                	sd	s0,16(sp)
    80002876:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);  // 获取退出码
    80002878:	fec40593          	addi	a1,s0,-20
    8000287c:	4501                	li	a0,0
    8000287e:	f27ff0ef          	jal	ra,800027a4 <argint>
  kexit(n);       // 调用内核的退出函数
    80002882:	fec42503          	lw	a0,-20(s0)
    80002886:	e92ff0ef          	jal	ra,80001f18 <kexit>
  return 0;       // 不会执行到这里
}
    8000288a:	4501                	li	a0,0
    8000288c:	60e2                	ld	ra,24(sp)
    8000288e:	6442                	ld	s0,16(sp)
    80002890:	6105                	addi	sp,sp,32
    80002892:	8082                	ret

0000000080002894 <sys_getpid>:

// 获取当前进程的进程ID
uint64
sys_getpid(void)
{
    80002894:	1141                	addi	sp,sp,-16
    80002896:	e406                	sd	ra,8(sp)
    80002898:	e022                	sd	s0,0(sp)
    8000289a:	0800                	addi	s0,sp,16
  return myproc()->pid;  // 返回当前进程的 PID
    8000289c:	f69fe0ef          	jal	ra,80001804 <myproc>
}
    800028a0:	5908                	lw	a0,48(a0)
    800028a2:	60a2                	ld	ra,8(sp)
    800028a4:	6402                	ld	s0,0(sp)
    800028a6:	0141                	addi	sp,sp,16
    800028a8:	8082                	ret

00000000800028aa <sys_fork>:

// 创建一个新的子进程
uint64
sys_fork(void)
{
    800028aa:	1141                	addi	sp,sp,-16
    800028ac:	e406                	sd	ra,8(sp)
    800028ae:	e022                	sd	s0,0(sp)
    800028b0:	0800                	addi	s0,sp,16
  return kfork();  // 调用内核的 fork 函数
    800028b2:	ab6ff0ef          	jal	ra,80001b68 <kfork>
}
    800028b6:	60a2                	ld	ra,8(sp)
    800028b8:	6402                	ld	s0,0(sp)
    800028ba:	0141                	addi	sp,sp,16
    800028bc:	8082                	ret

00000000800028be <sys_wait>:

// 等待子进程退出
uint64
sys_wait(void)
{
    800028be:	1101                	addi	sp,sp,-32
    800028c0:	ec06                	sd	ra,24(sp)
    800028c2:	e822                	sd	s0,16(sp)
    800028c4:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);  // 获取等待子进程状态的地址
    800028c6:	fe840593          	addi	a1,s0,-24
    800028ca:	4501                	li	a0,0
    800028cc:	ef5ff0ef          	jal	ra,800027c0 <argaddr>
  return kwait(p);  // 调用内核的 wait 函数
    800028d0:	fe843503          	ld	a0,-24(s0)
    800028d4:	f9aff0ef          	jal	ra,8000206e <kwait>
}
    800028d8:	60e2                	ld	ra,24(sp)
    800028da:	6442                	ld	s0,16(sp)
    800028dc:	6105                	addi	sp,sp,32
    800028de:	8082                	ret

00000000800028e0 <sys_sbrk>:

// 扩展或收缩进程的内存
uint64
sys_sbrk(void)
{
    800028e0:	7179                	addi	sp,sp,-48
    800028e2:	f406                	sd	ra,40(sp)
    800028e4:	f022                	sd	s0,32(sp)
    800028e6:	ec26                	sd	s1,24(sp)
    800028e8:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);  // 获取内存增量
    800028ea:	fd840593          	addi	a1,s0,-40
    800028ee:	4501                	li	a0,0
    800028f0:	eb5ff0ef          	jal	ra,800027a4 <argint>
  argint(1, &t);  // 获取是否懒加载标志
    800028f4:	fdc40593          	addi	a1,s0,-36
    800028f8:	4505                	li	a0,1
    800028fa:	eabff0ef          	jal	ra,800027a4 <argint>
  addr = myproc()->sz;  // 获取当前进程的内存大小
    800028fe:	f07fe0ef          	jal	ra,80001804 <myproc>
    80002902:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {  // 如果是急切分配或要求收缩内存
    80002904:	fdc42703          	lw	a4,-36(s0)
    80002908:	4785                	li	a5,1
    8000290a:	02f70763          	beq	a4,a5,80002938 <sys_sbrk+0x58>
    8000290e:	fd842783          	lw	a5,-40(s0)
    80002912:	0207c363          	bltz	a5,80002938 <sys_sbrk+0x58>
    if(growproc(n) < 0) {  // 调用内核的 growproc 函数调整内存
      return -1;  // 内存分配失败
    }
  } else {  // 如果是懒加载分配
    if(addr + n < addr)  // 防止内存溢出
    80002916:	97a6                	add	a5,a5,s1
    80002918:	0297ee63          	bltu	a5,s1,80002954 <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)  // 限制内存的最大值
    8000291c:	02000737          	lui	a4,0x2000
    80002920:	177d                	addi	a4,a4,-1
    80002922:	0736                	slli	a4,a4,0xd
    80002924:	02f76a63          	bltu	a4,a5,80002958 <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;  // 调整进程的内存大小
    80002928:	eddfe0ef          	jal	ra,80001804 <myproc>
    8000292c:	fd842703          	lw	a4,-40(s0)
    80002930:	653c                	ld	a5,72(a0)
    80002932:	97ba                	add	a5,a5,a4
    80002934:	e53c                	sd	a5,72(a0)
    80002936:	a039                	j	80002944 <sys_sbrk+0x64>
    if(growproc(n) < 0) {  // 调用内核的 growproc 函数调整内存
    80002938:	fd842503          	lw	a0,-40(s0)
    8000293c:	9caff0ef          	jal	ra,80001b06 <growproc>
    80002940:	00054863          	bltz	a0,80002950 <sys_sbrk+0x70>
  }
  return addr;  // 返回原内存地址
}
    80002944:	8526                	mv	a0,s1
    80002946:	70a2                	ld	ra,40(sp)
    80002948:	7402                	ld	s0,32(sp)
    8000294a:	64e2                	ld	s1,24(sp)
    8000294c:	6145                	addi	sp,sp,48
    8000294e:	8082                	ret
      return -1;  // 内存分配失败
    80002950:	54fd                	li	s1,-1
    80002952:	bfcd                	j	80002944 <sys_sbrk+0x64>
      return -1;
    80002954:	54fd                	li	s1,-1
    80002956:	b7fd                	j	80002944 <sys_sbrk+0x64>
      return -1;
    80002958:	54fd                	li	s1,-1
    8000295a:	b7ed                	j	80002944 <sys_sbrk+0x64>

000000008000295c <sys_pause>:

// 让当前进程挂起指定时间
uint64
sys_pause(void)
{
    8000295c:	7139                	addi	sp,sp,-64
    8000295e:	fc06                	sd	ra,56(sp)
    80002960:	f822                	sd	s0,48(sp)
    80002962:	f426                	sd	s1,40(sp)
    80002964:	f04a                	sd	s2,32(sp)
    80002966:	ec4e                	sd	s3,24(sp)
    80002968:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);  // 获取暂停的时长（以时钟滴答为单位）
    8000296a:	fcc40593          	addi	a1,s0,-52
    8000296e:	4501                	li	a0,0
    80002970:	e35ff0ef          	jal	ra,800027a4 <argint>
  if(n < 0)  // 如果给定的时长为负，则设置为 0
    80002974:	fcc42783          	lw	a5,-52(s0)
    80002978:	0607c563          	bltz	a5,800029e2 <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);  // 获取时钟锁
    8000297c:	00013517          	auipc	a0,0x13
    80002980:	e1c50513          	addi	a0,a0,-484 # 80015798 <tickslock>
    80002984:	9e8fe0ef          	jal	ra,80000b6c <acquire>
  ticks0 = ticks;  // 记录当前的时钟滴答数
    80002988:	00005917          	auipc	s2,0x5
    8000298c:	ee092903          	lw	s2,-288(s2) # 80007868 <ticks>
  while(ticks - ticks0 < n){  // 持续等待直到经过了指定的时间
    80002990:	fcc42783          	lw	a5,-52(s0)
    80002994:	cb8d                	beqz	a5,800029c6 <sys_pause+0x6a>
    if(killed(myproc())){  // 如果进程被杀死，退出等待
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);  // 进程进入休眠状态，等待时钟更新
    80002996:	00013997          	auipc	s3,0x13
    8000299a:	e0298993          	addi	s3,s3,-510 # 80015798 <tickslock>
    8000299e:	00005497          	auipc	s1,0x5
    800029a2:	eca48493          	addi	s1,s1,-310 # 80007868 <ticks>
    if(killed(myproc())){  // 如果进程被杀死，退出等待
    800029a6:	e5ffe0ef          	jal	ra,80001804 <myproc>
    800029aa:	e9aff0ef          	jal	ra,80002044 <killed>
    800029ae:	ed0d                	bnez	a0,800029e8 <sys_pause+0x8c>
    sleep(&ticks, &tickslock);  // 进程进入休眠状态，等待时钟更新
    800029b0:	85ce                	mv	a1,s3
    800029b2:	8526                	mv	a0,s1
    800029b4:	c58ff0ef          	jal	ra,80001e0c <sleep>
  while(ticks - ticks0 < n){  // 持续等待直到经过了指定的时间
    800029b8:	409c                	lw	a5,0(s1)
    800029ba:	412787bb          	subw	a5,a5,s2
    800029be:	fcc42703          	lw	a4,-52(s0)
    800029c2:	fee7e2e3          	bltu	a5,a4,800029a6 <sys_pause+0x4a>
  }
  release(&tickslock);  // 释放时钟锁
    800029c6:	00013517          	auipc	a0,0x13
    800029ca:	dd250513          	addi	a0,a0,-558 # 80015798 <tickslock>
    800029ce:	a36fe0ef          	jal	ra,80000c04 <release>
  return 0;  // 返回
    800029d2:	4501                	li	a0,0
}
    800029d4:	70e2                	ld	ra,56(sp)
    800029d6:	7442                	ld	s0,48(sp)
    800029d8:	74a2                	ld	s1,40(sp)
    800029da:	7902                	ld	s2,32(sp)
    800029dc:	69e2                	ld	s3,24(sp)
    800029de:	6121                	addi	sp,sp,64
    800029e0:	8082                	ret
    n = 0;
    800029e2:	fc042623          	sw	zero,-52(s0)
    800029e6:	bf59                	j	8000297c <sys_pause+0x20>
      release(&tickslock);
    800029e8:	00013517          	auipc	a0,0x13
    800029ec:	db050513          	addi	a0,a0,-592 # 80015798 <tickslock>
    800029f0:	a14fe0ef          	jal	ra,80000c04 <release>
      return -1;
    800029f4:	557d                	li	a0,-1
    800029f6:	bff9                	j	800029d4 <sys_pause+0x78>

00000000800029f8 <sys_kill>:

// 终止指定进程
uint64
sys_kill(void)
{
    800029f8:	1101                	addi	sp,sp,-32
    800029fa:	ec06                	sd	ra,24(sp)
    800029fc:	e822                	sd	s0,16(sp)
    800029fe:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);  // 获取进程 ID
    80002a00:	fec40593          	addi	a1,s0,-20
    80002a04:	4501                	li	a0,0
    80002a06:	d9fff0ef          	jal	ra,800027a4 <argint>
  return kkill(pid);  // 调用内核的 kill 函数终止进程
    80002a0a:	fec42503          	lw	a0,-20(s0)
    80002a0e:	dacff0ef          	jal	ra,80001fba <kkill>
}
    80002a12:	60e2                	ld	ra,24(sp)
    80002a14:	6442                	ld	s0,16(sp)
    80002a16:	6105                	addi	sp,sp,32
    80002a18:	8082                	ret

0000000080002a1a <sys_uptime>:

// 返回自系统启动以来经过的时钟滴答数
uint64
sys_uptime(void)
{
    80002a1a:	1101                	addi	sp,sp,-32
    80002a1c:	ec06                	sd	ra,24(sp)
    80002a1e:	e822                	sd	s0,16(sp)
    80002a20:	e426                	sd	s1,8(sp)
    80002a22:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);  // 获取时钟锁
    80002a24:	00013517          	auipc	a0,0x13
    80002a28:	d7450513          	addi	a0,a0,-652 # 80015798 <tickslock>
    80002a2c:	940fe0ef          	jal	ra,80000b6c <acquire>
  xticks = ticks;  // 获取当前的时钟滴答数
    80002a30:	00005497          	auipc	s1,0x5
    80002a34:	e384a483          	lw	s1,-456(s1) # 80007868 <ticks>
  release(&tickslock);  // 释放时钟锁
    80002a38:	00013517          	auipc	a0,0x13
    80002a3c:	d6050513          	addi	a0,a0,-672 # 80015798 <tickslock>
    80002a40:	9c4fe0ef          	jal	ra,80000c04 <release>
  return xticks;  // 返回时钟滴答数
}
    80002a44:	02049513          	slli	a0,s1,0x20
    80002a48:	9101                	srli	a0,a0,0x20
    80002a4a:	60e2                	ld	ra,24(sp)
    80002a4c:	6442                	ld	s0,16(sp)
    80002a4e:	64a2                	ld	s1,8(sp)
    80002a50:	6105                	addi	sp,sp,32
    80002a52:	8082                	ret

0000000080002a54 <binit>:
} bcache;

// 初始化缓冲区缓存
void
binit(void)
{
    80002a54:	7179                	addi	sp,sp,-48
    80002a56:	f406                	sd	ra,40(sp)
    80002a58:	f022                	sd	s0,32(sp)
    80002a5a:	ec26                	sd	s1,24(sp)
    80002a5c:	e84a                	sd	s2,16(sp)
    80002a5e:	e44e                	sd	s3,8(sp)
    80002a60:	e052                	sd	s4,0(sp)
    80002a62:	1800                	addi	s0,sp,48
  struct buf *b;

  // 初始化缓冲区缓存的锁
  initlock(&bcache.lock, "bcache");
    80002a64:	00005597          	auipc	a1,0x5
    80002a68:	a4458593          	addi	a1,a1,-1468 # 800074a8 <syscalls+0xb8>
    80002a6c:	00013517          	auipc	a0,0x13
    80002a70:	d4450513          	addi	a0,a0,-700 # 800157b0 <bcache>
    80002a74:	878fe0ef          	jal	ra,80000aec <initlock>

  // 创建缓冲区链表
  bcache.head.prev = &bcache.head;
    80002a78:	0001b797          	auipc	a5,0x1b
    80002a7c:	d3878793          	addi	a5,a5,-712 # 8001d7b0 <bcache+0x8000>
    80002a80:	0001b717          	auipc	a4,0x1b
    80002a84:	f9870713          	addi	a4,a4,-104 # 8001da18 <bcache+0x8268>
    80002a88:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002a8c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf + NBUF; b++){
    80002a90:	00013497          	auipc	s1,0x13
    80002a94:	d3848493          	addi	s1,s1,-712 # 800157c8 <bcache+0x18>
    b->next = bcache.head.next;
    80002a98:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002a9a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");  // 初始化缓冲区的睡眠锁
    80002a9c:	00005a17          	auipc	s4,0x5
    80002aa0:	a14a0a13          	addi	s4,s4,-1516 # 800074b0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002aa4:	2b893783          	ld	a5,696(s2)
    80002aa8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002aaa:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");  // 初始化缓冲区的睡眠锁
    80002aae:	85d2                	mv	a1,s4
    80002ab0:	01048513          	addi	a0,s1,16
    80002ab4:	2fe010ef          	jal	ra,80003db2 <initsleeplock>
    bcache.head.next->prev = b;
    80002ab8:	2b893783          	ld	a5,696(s2)
    80002abc:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002abe:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf + NBUF; b++){
    80002ac2:	45848493          	addi	s1,s1,1112
    80002ac6:	fd349fe3          	bne	s1,s3,80002aa4 <binit+0x50>
  }
}
    80002aca:	70a2                	ld	ra,40(sp)
    80002acc:	7402                	ld	s0,32(sp)
    80002ace:	64e2                	ld	s1,24(sp)
    80002ad0:	6942                	ld	s2,16(sp)
    80002ad2:	69a2                	ld	s3,8(sp)
    80002ad4:	6a02                	ld	s4,0(sp)
    80002ad6:	6145                	addi	sp,sp,48
    80002ad8:	8082                	ret

0000000080002ada <bread>:
}

// 获取指定磁盘块的缓冲区并返回，内容从磁盘读取
struct buf*
bread(uint dev, uint blockno)
{
    80002ada:	7179                	addi	sp,sp,-48
    80002adc:	f406                	sd	ra,40(sp)
    80002ade:	f022                	sd	s0,32(sp)
    80002ae0:	ec26                	sd	s1,24(sp)
    80002ae2:	e84a                	sd	s2,16(sp)
    80002ae4:	e44e                	sd	s3,8(sp)
    80002ae6:	1800                	addi	s0,sp,48
    80002ae8:	892a                	mv	s2,a0
    80002aea:	89ae                	mv	s3,a1
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002aec:	00013517          	auipc	a0,0x13
    80002af0:	cc450513          	addi	a0,a0,-828 # 800157b0 <bcache>
    80002af4:	878fe0ef          	jal	ra,80000b6c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002af8:	0001b497          	auipc	s1,0x1b
    80002afc:	f704b483          	ld	s1,-144(s1) # 8001da68 <bcache+0x82b8>
    80002b00:	0001b797          	auipc	a5,0x1b
    80002b04:	f1878793          	addi	a5,a5,-232 # 8001da18 <bcache+0x8268>
    80002b08:	02f48b63          	beq	s1,a5,80002b3e <bread+0x64>
    80002b0c:	873e                	mv	a4,a5
    80002b0e:	a021                	j	80002b16 <bread+0x3c>
    80002b10:	68a4                	ld	s1,80(s1)
    80002b12:	02e48663          	beq	s1,a4,80002b3e <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002b16:	449c                	lw	a5,8(s1)
    80002b18:	ff279ce3          	bne	a5,s2,80002b10 <bread+0x36>
    80002b1c:	44dc                	lw	a5,12(s1)
    80002b1e:	ff3799e3          	bne	a5,s3,80002b10 <bread+0x36>
      b->refcnt++;  // 增加引用计数
    80002b22:	40bc                	lw	a5,64(s1)
    80002b24:	2785                	addiw	a5,a5,1
    80002b26:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002b28:	00013517          	auipc	a0,0x13
    80002b2c:	c8850513          	addi	a0,a0,-888 # 800157b0 <bcache>
    80002b30:	8d4fe0ef          	jal	ra,80000c04 <release>
      acquiresleep(&b->lock);  // 获取缓冲区的睡眠锁
    80002b34:	01048513          	addi	a0,s1,16
    80002b38:	2b0010ef          	jal	ra,80003de8 <acquiresleep>
      return b;  // 返回缓冲区
    80002b3c:	a889                	j	80002b8e <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002b3e:	0001b497          	auipc	s1,0x1b
    80002b42:	f224b483          	ld	s1,-222(s1) # 8001da60 <bcache+0x82b0>
    80002b46:	0001b797          	auipc	a5,0x1b
    80002b4a:	ed278793          	addi	a5,a5,-302 # 8001da18 <bcache+0x8268>
    80002b4e:	00f48863          	beq	s1,a5,80002b5e <bread+0x84>
    80002b52:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002b54:	40bc                	lw	a5,64(s1)
    80002b56:	cb91                	beqz	a5,80002b6a <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002b58:	64a4                	ld	s1,72(s1)
    80002b5a:	fee49de3          	bne	s1,a4,80002b54 <bread+0x7a>
  panic("bget: no buffers");  // 如果没有找到可用的缓冲区，发生错误
    80002b5e:	00005517          	auipc	a0,0x5
    80002b62:	95a50513          	addi	a0,a0,-1702 # 800074b8 <syscalls+0xc8>
    80002b66:	c25fd0ef          	jal	ra,8000078a <panic>
      b->dev = dev;  // 设置设备号
    80002b6a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;  // 设置块号
    80002b6e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;  // 设置为无效
    80002b72:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;  // 引用计数设置为 1
    80002b76:	4785                	li	a5,1
    80002b78:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002b7a:	00013517          	auipc	a0,0x13
    80002b7e:	c3650513          	addi	a0,a0,-970 # 800157b0 <bcache>
    80002b82:	882fe0ef          	jal	ra,80000c04 <release>
      acquiresleep(&b->lock);  // 获取缓冲区的睡眠锁
    80002b86:	01048513          	addi	a0,s1,16
    80002b8a:	25e010ef          	jal	ra,80003de8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);  // 获取缓冲区
  if(!b->valid) {
    80002b8e:	409c                	lw	a5,0(s1)
    80002b90:	cb89                	beqz	a5,80002ba2 <bread+0xc8>
    virtio_disk_rw(b, 0);  // 从磁盘读取数据到缓冲区
    b->valid = 1;  // 设置缓冲区为有效
  }
  return b;  // 返回缓冲区
}
    80002b92:	8526                	mv	a0,s1
    80002b94:	70a2                	ld	ra,40(sp)
    80002b96:	7402                	ld	s0,32(sp)
    80002b98:	64e2                	ld	s1,24(sp)
    80002b9a:	6942                	ld	s2,16(sp)
    80002b9c:	69a2                	ld	s3,8(sp)
    80002b9e:	6145                	addi	sp,sp,48
    80002ba0:	8082                	ret
    virtio_disk_rw(b, 0);  // 从磁盘读取数据到缓冲区
    80002ba2:	4581                	li	a1,0
    80002ba4:	8526                	mv	a0,s1
    80002ba6:	1b7020ef          	jal	ra,8000555c <virtio_disk_rw>
    b->valid = 1;  // 设置缓冲区为有效
    80002baa:	4785                	li	a5,1
    80002bac:	c09c                	sw	a5,0(s1)
  return b;  // 返回缓冲区
    80002bae:	b7d5                	j	80002b92 <bread+0xb8>

0000000080002bb0 <bwrite>:

// 将缓冲区 b 的内容写入磁盘，必须先锁定缓冲区
void
bwrite(struct buf *b)
{
    80002bb0:	1101                	addi	sp,sp,-32
    80002bb2:	ec06                	sd	ra,24(sp)
    80002bb4:	e822                	sd	s0,16(sp)
    80002bb6:	e426                	sd	s1,8(sp)
    80002bb8:	1000                	addi	s0,sp,32
    80002bba:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002bbc:	0541                	addi	a0,a0,16
    80002bbe:	2a8010ef          	jal	ra,80003e66 <holdingsleep>
    80002bc2:	c911                	beqz	a0,80002bd6 <bwrite+0x26>
    panic("bwrite");  // 检查是否持有缓冲区的锁
  virtio_disk_rw(b, 1);  // 将缓冲区内容写入磁盘
    80002bc4:	4585                	li	a1,1
    80002bc6:	8526                	mv	a0,s1
    80002bc8:	195020ef          	jal	ra,8000555c <virtio_disk_rw>
}
    80002bcc:	60e2                	ld	ra,24(sp)
    80002bce:	6442                	ld	s0,16(sp)
    80002bd0:	64a2                	ld	s1,8(sp)
    80002bd2:	6105                	addi	sp,sp,32
    80002bd4:	8082                	ret
    panic("bwrite");  // 检查是否持有缓冲区的锁
    80002bd6:	00005517          	auipc	a0,0x5
    80002bda:	8fa50513          	addi	a0,a0,-1798 # 800074d0 <syscalls+0xe0>
    80002bde:	badfd0ef          	jal	ra,8000078a <panic>

0000000080002be2 <brelse>:

// 释放锁定的缓冲区，并将其移到最近使用的位置
void
brelse(struct buf *b)
{
    80002be2:	1101                	addi	sp,sp,-32
    80002be4:	ec06                	sd	ra,24(sp)
    80002be6:	e822                	sd	s0,16(sp)
    80002be8:	e426                	sd	s1,8(sp)
    80002bea:	e04a                	sd	s2,0(sp)
    80002bec:	1000                	addi	s0,sp,32
    80002bee:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002bf0:	01050913          	addi	s2,a0,16
    80002bf4:	854a                	mv	a0,s2
    80002bf6:	270010ef          	jal	ra,80003e66 <holdingsleep>
    80002bfa:	c13d                	beqz	a0,80002c60 <brelse+0x7e>
    panic("brelse");  // 检查是否持有缓冲区的锁

  releasesleep(&b->lock);  // 释放缓冲区的睡眠锁
    80002bfc:	854a                	mv	a0,s2
    80002bfe:	230010ef          	jal	ra,80003e2e <releasesleep>

  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002c02:	00013517          	auipc	a0,0x13
    80002c06:	bae50513          	addi	a0,a0,-1106 # 800157b0 <bcache>
    80002c0a:	f63fd0ef          	jal	ra,80000b6c <acquire>
  b->refcnt--;  // 减少引用计数
    80002c0e:	40bc                	lw	a5,64(s1)
    80002c10:	37fd                	addiw	a5,a5,-1
    80002c12:	0007871b          	sext.w	a4,a5
    80002c16:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002c18:	eb05                	bnez	a4,80002c48 <brelse+0x66>
    // 如果没有其他进程在使用该缓冲区
    // 将缓冲区移到链表头部
    b->next->prev = b->prev;
    80002c1a:	68bc                	ld	a5,80(s1)
    80002c1c:	64b8                	ld	a4,72(s1)
    80002c1e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002c20:	64bc                	ld	a5,72(s1)
    80002c22:	68b8                	ld	a4,80(s1)
    80002c24:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002c26:	0001b797          	auipc	a5,0x1b
    80002c2a:	b8a78793          	addi	a5,a5,-1142 # 8001d7b0 <bcache+0x8000>
    80002c2e:	2b87b703          	ld	a4,696(a5)
    80002c32:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002c34:	0001b717          	auipc	a4,0x1b
    80002c38:	de470713          	addi	a4,a4,-540 # 8001da18 <bcache+0x8268>
    80002c3c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002c3e:	2b87b703          	ld	a4,696(a5)
    80002c42:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002c44:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002c48:	00013517          	auipc	a0,0x13
    80002c4c:	b6850513          	addi	a0,a0,-1176 # 800157b0 <bcache>
    80002c50:	fb5fd0ef          	jal	ra,80000c04 <release>
}
    80002c54:	60e2                	ld	ra,24(sp)
    80002c56:	6442                	ld	s0,16(sp)
    80002c58:	64a2                	ld	s1,8(sp)
    80002c5a:	6902                	ld	s2,0(sp)
    80002c5c:	6105                	addi	sp,sp,32
    80002c5e:	8082                	ret
    panic("brelse");  // 检查是否持有缓冲区的锁
    80002c60:	00005517          	auipc	a0,0x5
    80002c64:	87850513          	addi	a0,a0,-1928 # 800074d8 <syscalls+0xe8>
    80002c68:	b23fd0ef          	jal	ra,8000078a <panic>

0000000080002c6c <bpin>:

// 增加缓冲区 b 的引用计数，用于防止缓冲区被释放
void
bpin(struct buf *b) {
    80002c6c:	1101                	addi	sp,sp,-32
    80002c6e:	ec06                	sd	ra,24(sp)
    80002c70:	e822                	sd	s0,16(sp)
    80002c72:	e426                	sd	s1,8(sp)
    80002c74:	1000                	addi	s0,sp,32
    80002c76:	84aa                	mv	s1,a0
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002c78:	00013517          	auipc	a0,0x13
    80002c7c:	b3850513          	addi	a0,a0,-1224 # 800157b0 <bcache>
    80002c80:	eedfd0ef          	jal	ra,80000b6c <acquire>
  b->refcnt++;  // 增加引用计数
    80002c84:	40bc                	lw	a5,64(s1)
    80002c86:	2785                	addiw	a5,a5,1
    80002c88:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002c8a:	00013517          	auipc	a0,0x13
    80002c8e:	b2650513          	addi	a0,a0,-1242 # 800157b0 <bcache>
    80002c92:	f73fd0ef          	jal	ra,80000c04 <release>
}
    80002c96:	60e2                	ld	ra,24(sp)
    80002c98:	6442                	ld	s0,16(sp)
    80002c9a:	64a2                	ld	s1,8(sp)
    80002c9c:	6105                	addi	sp,sp,32
    80002c9e:	8082                	ret

0000000080002ca0 <bunpin>:

// 减少缓冲区 b 的引用计数，用于缓冲区的释放
void
bunpin(struct buf *b) {
    80002ca0:	1101                	addi	sp,sp,-32
    80002ca2:	ec06                	sd	ra,24(sp)
    80002ca4:	e822                	sd	s0,16(sp)
    80002ca6:	e426                	sd	s1,8(sp)
    80002ca8:	1000                	addi	s0,sp,32
    80002caa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002cac:	00013517          	auipc	a0,0x13
    80002cb0:	b0450513          	addi	a0,a0,-1276 # 800157b0 <bcache>
    80002cb4:	eb9fd0ef          	jal	ra,80000b6c <acquire>
  b->refcnt--;  // 减少引用计数
    80002cb8:	40bc                	lw	a5,64(s1)
    80002cba:	37fd                	addiw	a5,a5,-1
    80002cbc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002cbe:	00013517          	auipc	a0,0x13
    80002cc2:	af250513          	addi	a0,a0,-1294 # 800157b0 <bcache>
    80002cc6:	f3ffd0ef          	jal	ra,80000c04 <release>
}
    80002cca:	60e2                	ld	ra,24(sp)
    80002ccc:	6442                	ld	s0,16(sp)
    80002cce:	64a2                	ld	s1,8(sp)
    80002cd0:	6105                	addi	sp,sp,32
    80002cd2:	8082                	ret

0000000080002cd4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002cd4:	1101                	addi	sp,sp,-32
    80002cd6:	ec06                	sd	ra,24(sp)
    80002cd8:	e822                	sd	s0,16(sp)
    80002cda:	e426                	sd	s1,8(sp)
    80002cdc:	e04a                	sd	s2,0(sp)
    80002cde:	1000                	addi	s0,sp,32
    80002ce0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002ce2:	00d5d59b          	srliw	a1,a1,0xd
    80002ce6:	0001b797          	auipc	a5,0x1b
    80002cea:	1a67a783          	lw	a5,422(a5) # 8001de8c <sb+0x1c>
    80002cee:	9dbd                	addw	a1,a1,a5
    80002cf0:	debff0ef          	jal	ra,80002ada <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002cf4:	0074f713          	andi	a4,s1,7
    80002cf8:	4785                	li	a5,1
    80002cfa:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80002cfe:	14ce                	slli	s1,s1,0x33
    80002d00:	90d9                	srli	s1,s1,0x36
    80002d02:	00950733          	add	a4,a0,s1
    80002d06:	05874703          	lbu	a4,88(a4)
    80002d0a:	00e7f6b3          	and	a3,a5,a4
    80002d0e:	c29d                	beqz	a3,80002d34 <bfree+0x60>
    80002d10:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002d12:	94aa                	add	s1,s1,a0
    80002d14:	fff7c793          	not	a5,a5
    80002d18:	8ff9                	and	a5,a5,a4
    80002d1a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80002d1e:	7d1000ef          	jal	ra,80003cee <log_write>
  brelse(bp);
    80002d22:	854a                	mv	a0,s2
    80002d24:	ebfff0ef          	jal	ra,80002be2 <brelse>
}
    80002d28:	60e2                	ld	ra,24(sp)
    80002d2a:	6442                	ld	s0,16(sp)
    80002d2c:	64a2                	ld	s1,8(sp)
    80002d2e:	6902                	ld	s2,0(sp)
    80002d30:	6105                	addi	sp,sp,32
    80002d32:	8082                	ret
    panic("freeing free block");
    80002d34:	00004517          	auipc	a0,0x4
    80002d38:	7ac50513          	addi	a0,a0,1964 # 800074e0 <syscalls+0xf0>
    80002d3c:	a4ffd0ef          	jal	ra,8000078a <panic>

0000000080002d40 <balloc>:
{
    80002d40:	711d                	addi	sp,sp,-96
    80002d42:	ec86                	sd	ra,88(sp)
    80002d44:	e8a2                	sd	s0,80(sp)
    80002d46:	e4a6                	sd	s1,72(sp)
    80002d48:	e0ca                	sd	s2,64(sp)
    80002d4a:	fc4e                	sd	s3,56(sp)
    80002d4c:	f852                	sd	s4,48(sp)
    80002d4e:	f456                	sd	s5,40(sp)
    80002d50:	f05a                	sd	s6,32(sp)
    80002d52:	ec5e                	sd	s7,24(sp)
    80002d54:	e862                	sd	s8,16(sp)
    80002d56:	e466                	sd	s9,8(sp)
    80002d58:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80002d5a:	0001b797          	auipc	a5,0x1b
    80002d5e:	11a7a783          	lw	a5,282(a5) # 8001de74 <sb+0x4>
    80002d62:	0e078163          	beqz	a5,80002e44 <balloc+0x104>
    80002d66:	8baa                	mv	s7,a0
    80002d68:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80002d6a:	0001bb17          	auipc	s6,0x1b
    80002d6e:	106b0b13          	addi	s6,s6,262 # 8001de70 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002d72:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80002d74:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002d76:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80002d78:	6c89                	lui	s9,0x2
    80002d7a:	a0b5                	j	80002de6 <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    80002d7c:	974a                	add	a4,a4,s2
    80002d7e:	8fd5                	or	a5,a5,a3
    80002d80:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80002d84:	854a                	mv	a0,s2
    80002d86:	769000ef          	jal	ra,80003cee <log_write>
        brelse(bp);
    80002d8a:	854a                	mv	a0,s2
    80002d8c:	e57ff0ef          	jal	ra,80002be2 <brelse>
  bp = bread(dev, bno);
    80002d90:	85a6                	mv	a1,s1
    80002d92:	855e                	mv	a0,s7
    80002d94:	d47ff0ef          	jal	ra,80002ada <bread>
    80002d98:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80002d9a:	40000613          	li	a2,1024
    80002d9e:	4581                	li	a1,0
    80002da0:	05850513          	addi	a0,a0,88
    80002da4:	e9dfd0ef          	jal	ra,80000c40 <memset>
  log_write(bp);
    80002da8:	854a                	mv	a0,s2
    80002daa:	745000ef          	jal	ra,80003cee <log_write>
  brelse(bp);
    80002dae:	854a                	mv	a0,s2
    80002db0:	e33ff0ef          	jal	ra,80002be2 <brelse>
}
    80002db4:	8526                	mv	a0,s1
    80002db6:	60e6                	ld	ra,88(sp)
    80002db8:	6446                	ld	s0,80(sp)
    80002dba:	64a6                	ld	s1,72(sp)
    80002dbc:	6906                	ld	s2,64(sp)
    80002dbe:	79e2                	ld	s3,56(sp)
    80002dc0:	7a42                	ld	s4,48(sp)
    80002dc2:	7aa2                	ld	s5,40(sp)
    80002dc4:	7b02                	ld	s6,32(sp)
    80002dc6:	6be2                	ld	s7,24(sp)
    80002dc8:	6c42                	ld	s8,16(sp)
    80002dca:	6ca2                	ld	s9,8(sp)
    80002dcc:	6125                	addi	sp,sp,96
    80002dce:	8082                	ret
    brelse(bp);
    80002dd0:	854a                	mv	a0,s2
    80002dd2:	e11ff0ef          	jal	ra,80002be2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80002dd6:	015c87bb          	addw	a5,s9,s5
    80002dda:	00078a9b          	sext.w	s5,a5
    80002dde:	004b2703          	lw	a4,4(s6)
    80002de2:	06eaf163          	bgeu	s5,a4,80002e44 <balloc+0x104>
    bp = bread(dev, BBLOCK(b, sb));
    80002de6:	41fad79b          	sraiw	a5,s5,0x1f
    80002dea:	0137d79b          	srliw	a5,a5,0x13
    80002dee:	015787bb          	addw	a5,a5,s5
    80002df2:	40d7d79b          	sraiw	a5,a5,0xd
    80002df6:	01cb2583          	lw	a1,28(s6)
    80002dfa:	9dbd                	addw	a1,a1,a5
    80002dfc:	855e                	mv	a0,s7
    80002dfe:	cddff0ef          	jal	ra,80002ada <bread>
    80002e02:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002e04:	004b2503          	lw	a0,4(s6)
    80002e08:	000a849b          	sext.w	s1,s5
    80002e0c:	8662                	mv	a2,s8
    80002e0e:	fca4f1e3          	bgeu	s1,a0,80002dd0 <balloc+0x90>
      m = 1 << (bi % 8);
    80002e12:	41f6579b          	sraiw	a5,a2,0x1f
    80002e16:	01d7d69b          	srliw	a3,a5,0x1d
    80002e1a:	00c6873b          	addw	a4,a3,a2
    80002e1e:	00777793          	andi	a5,a4,7
    80002e22:	9f95                	subw	a5,a5,a3
    80002e24:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80002e28:	4037571b          	sraiw	a4,a4,0x3
    80002e2c:	00e906b3          	add	a3,s2,a4
    80002e30:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    80002e34:	00d7f5b3          	and	a1,a5,a3
    80002e38:	d1b1                	beqz	a1,80002d7c <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002e3a:	2605                	addiw	a2,a2,1
    80002e3c:	2485                	addiw	s1,s1,1
    80002e3e:	fd4618e3          	bne	a2,s4,80002e0e <balloc+0xce>
    80002e42:	b779                	j	80002dd0 <balloc+0x90>
  printf("balloc: out of blocks\n");
    80002e44:	00004517          	auipc	a0,0x4
    80002e48:	6b450513          	addi	a0,a0,1716 # 800074f8 <syscalls+0x108>
    80002e4c:	e78fd0ef          	jal	ra,800004c4 <printf>
  return 0;
    80002e50:	4481                	li	s1,0
    80002e52:	b78d                	j	80002db4 <balloc+0x74>

0000000080002e54 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80002e54:	7179                	addi	sp,sp,-48
    80002e56:	f406                	sd	ra,40(sp)
    80002e58:	f022                	sd	s0,32(sp)
    80002e5a:	ec26                	sd	s1,24(sp)
    80002e5c:	e84a                	sd	s2,16(sp)
    80002e5e:	e44e                	sd	s3,8(sp)
    80002e60:	e052                	sd	s4,0(sp)
    80002e62:	1800                	addi	s0,sp,48
    80002e64:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80002e66:	47ad                	li	a5,11
    80002e68:	02b7e563          	bltu	a5,a1,80002e92 <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    80002e6c:	02059493          	slli	s1,a1,0x20
    80002e70:	9081                	srli	s1,s1,0x20
    80002e72:	048a                	slli	s1,s1,0x2
    80002e74:	94aa                	add	s1,s1,a0
    80002e76:	0504a903          	lw	s2,80(s1)
    80002e7a:	06091663          	bnez	s2,80002ee6 <bmap+0x92>
      addr = balloc(ip->dev);
    80002e7e:	4108                	lw	a0,0(a0)
    80002e80:	ec1ff0ef          	jal	ra,80002d40 <balloc>
    80002e84:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002e88:	04090f63          	beqz	s2,80002ee6 <bmap+0x92>
        return 0;
      ip->addrs[bn] = addr;
    80002e8c:	0524a823          	sw	s2,80(s1)
    80002e90:	a899                	j	80002ee6 <bmap+0x92>
    }
    return addr;
  }
  bn -= NDIRECT;
    80002e92:	ff45849b          	addiw	s1,a1,-12
    80002e96:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80002e9a:	0ff00793          	li	a5,255
    80002e9e:	06e7eb63          	bltu	a5,a4,80002f14 <bmap+0xc0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80002ea2:	08052903          	lw	s2,128(a0)
    80002ea6:	00091b63          	bnez	s2,80002ebc <bmap+0x68>
      addr = balloc(ip->dev);
    80002eaa:	4108                	lw	a0,0(a0)
    80002eac:	e95ff0ef          	jal	ra,80002d40 <balloc>
    80002eb0:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002eb4:	02090963          	beqz	s2,80002ee6 <bmap+0x92>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80002eb8:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80002ebc:	85ca                	mv	a1,s2
    80002ebe:	0009a503          	lw	a0,0(s3)
    80002ec2:	c19ff0ef          	jal	ra,80002ada <bread>
    80002ec6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80002ec8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80002ecc:	02049593          	slli	a1,s1,0x20
    80002ed0:	9181                	srli	a1,a1,0x20
    80002ed2:	058a                	slli	a1,a1,0x2
    80002ed4:	00b784b3          	add	s1,a5,a1
    80002ed8:	0004a903          	lw	s2,0(s1)
    80002edc:	00090e63          	beqz	s2,80002ef8 <bmap+0xa4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80002ee0:	8552                	mv	a0,s4
    80002ee2:	d01ff0ef          	jal	ra,80002be2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80002ee6:	854a                	mv	a0,s2
    80002ee8:	70a2                	ld	ra,40(sp)
    80002eea:	7402                	ld	s0,32(sp)
    80002eec:	64e2                	ld	s1,24(sp)
    80002eee:	6942                	ld	s2,16(sp)
    80002ef0:	69a2                	ld	s3,8(sp)
    80002ef2:	6a02                	ld	s4,0(sp)
    80002ef4:	6145                	addi	sp,sp,48
    80002ef6:	8082                	ret
      addr = balloc(ip->dev);
    80002ef8:	0009a503          	lw	a0,0(s3)
    80002efc:	e45ff0ef          	jal	ra,80002d40 <balloc>
    80002f00:	0005091b          	sext.w	s2,a0
      if(addr){
    80002f04:	fc090ee3          	beqz	s2,80002ee0 <bmap+0x8c>
        a[bn] = addr;
    80002f08:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80002f0c:	8552                	mv	a0,s4
    80002f0e:	5e1000ef          	jal	ra,80003cee <log_write>
    80002f12:	b7f9                	j	80002ee0 <bmap+0x8c>
  panic("bmap: out of range");
    80002f14:	00004517          	auipc	a0,0x4
    80002f18:	5fc50513          	addi	a0,a0,1532 # 80007510 <syscalls+0x120>
    80002f1c:	86ffd0ef          	jal	ra,8000078a <panic>

0000000080002f20 <iget>:
{
    80002f20:	7179                	addi	sp,sp,-48
    80002f22:	f406                	sd	ra,40(sp)
    80002f24:	f022                	sd	s0,32(sp)
    80002f26:	ec26                	sd	s1,24(sp)
    80002f28:	e84a                	sd	s2,16(sp)
    80002f2a:	e44e                	sd	s3,8(sp)
    80002f2c:	e052                	sd	s4,0(sp)
    80002f2e:	1800                	addi	s0,sp,48
    80002f30:	89aa                	mv	s3,a0
    80002f32:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80002f34:	0001b517          	auipc	a0,0x1b
    80002f38:	f5c50513          	addi	a0,a0,-164 # 8001de90 <itable>
    80002f3c:	c31fd0ef          	jal	ra,80000b6c <acquire>
  empty = 0;
    80002f40:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80002f42:	0001b497          	auipc	s1,0x1b
    80002f46:	f6648493          	addi	s1,s1,-154 # 8001dea8 <itable+0x18>
    80002f4a:	0001d697          	auipc	a3,0x1d
    80002f4e:	9ee68693          	addi	a3,a3,-1554 # 8001f938 <log>
    80002f52:	a039                	j	80002f60 <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80002f54:	02090963          	beqz	s2,80002f86 <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80002f58:	08848493          	addi	s1,s1,136
    80002f5c:	02d48863          	beq	s1,a3,80002f8c <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80002f60:	449c                	lw	a5,8(s1)
    80002f62:	fef059e3          	blez	a5,80002f54 <iget+0x34>
    80002f66:	4098                	lw	a4,0(s1)
    80002f68:	ff3716e3          	bne	a4,s3,80002f54 <iget+0x34>
    80002f6c:	40d8                	lw	a4,4(s1)
    80002f6e:	ff4713e3          	bne	a4,s4,80002f54 <iget+0x34>
      ip->ref++;
    80002f72:	2785                	addiw	a5,a5,1
    80002f74:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80002f76:	0001b517          	auipc	a0,0x1b
    80002f7a:	f1a50513          	addi	a0,a0,-230 # 8001de90 <itable>
    80002f7e:	c87fd0ef          	jal	ra,80000c04 <release>
      return ip;
    80002f82:	8926                	mv	s2,s1
    80002f84:	a02d                	j	80002fae <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80002f86:	fbe9                	bnez	a5,80002f58 <iget+0x38>
    80002f88:	8926                	mv	s2,s1
    80002f8a:	b7f9                	j	80002f58 <iget+0x38>
  if(empty == 0)
    80002f8c:	02090a63          	beqz	s2,80002fc0 <iget+0xa0>
  ip->dev = dev;
    80002f90:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80002f94:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80002f98:	4785                	li	a5,1
    80002f9a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80002f9e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80002fa2:	0001b517          	auipc	a0,0x1b
    80002fa6:	eee50513          	addi	a0,a0,-274 # 8001de90 <itable>
    80002faa:	c5bfd0ef          	jal	ra,80000c04 <release>
}
    80002fae:	854a                	mv	a0,s2
    80002fb0:	70a2                	ld	ra,40(sp)
    80002fb2:	7402                	ld	s0,32(sp)
    80002fb4:	64e2                	ld	s1,24(sp)
    80002fb6:	6942                	ld	s2,16(sp)
    80002fb8:	69a2                	ld	s3,8(sp)
    80002fba:	6a02                	ld	s4,0(sp)
    80002fbc:	6145                	addi	sp,sp,48
    80002fbe:	8082                	ret
    panic("iget: no inodes");
    80002fc0:	00004517          	auipc	a0,0x4
    80002fc4:	56850513          	addi	a0,a0,1384 # 80007528 <syscalls+0x138>
    80002fc8:	fc2fd0ef          	jal	ra,8000078a <panic>

0000000080002fcc <iinit>:
{
    80002fcc:	7179                	addi	sp,sp,-48
    80002fce:	f406                	sd	ra,40(sp)
    80002fd0:	f022                	sd	s0,32(sp)
    80002fd2:	ec26                	sd	s1,24(sp)
    80002fd4:	e84a                	sd	s2,16(sp)
    80002fd6:	e44e                	sd	s3,8(sp)
    80002fd8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80002fda:	00004597          	auipc	a1,0x4
    80002fde:	55e58593          	addi	a1,a1,1374 # 80007538 <syscalls+0x148>
    80002fe2:	0001b517          	auipc	a0,0x1b
    80002fe6:	eae50513          	addi	a0,a0,-338 # 8001de90 <itable>
    80002fea:	b03fd0ef          	jal	ra,80000aec <initlock>
  for(i = 0; i < NINODE; i++) {
    80002fee:	0001b497          	auipc	s1,0x1b
    80002ff2:	eca48493          	addi	s1,s1,-310 # 8001deb8 <itable+0x28>
    80002ff6:	0001d997          	auipc	s3,0x1d
    80002ffa:	95298993          	addi	s3,s3,-1710 # 8001f948 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80002ffe:	00004917          	auipc	s2,0x4
    80003002:	54290913          	addi	s2,s2,1346 # 80007540 <syscalls+0x150>
    80003006:	85ca                	mv	a1,s2
    80003008:	8526                	mv	a0,s1
    8000300a:	5a9000ef          	jal	ra,80003db2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000300e:	08848493          	addi	s1,s1,136
    80003012:	ff349ae3          	bne	s1,s3,80003006 <iinit+0x3a>
}
    80003016:	70a2                	ld	ra,40(sp)
    80003018:	7402                	ld	s0,32(sp)
    8000301a:	64e2                	ld	s1,24(sp)
    8000301c:	6942                	ld	s2,16(sp)
    8000301e:	69a2                	ld	s3,8(sp)
    80003020:	6145                	addi	sp,sp,48
    80003022:	8082                	ret

0000000080003024 <ialloc>:
{
    80003024:	715d                	addi	sp,sp,-80
    80003026:	e486                	sd	ra,72(sp)
    80003028:	e0a2                	sd	s0,64(sp)
    8000302a:	fc26                	sd	s1,56(sp)
    8000302c:	f84a                	sd	s2,48(sp)
    8000302e:	f44e                	sd	s3,40(sp)
    80003030:	f052                	sd	s4,32(sp)
    80003032:	ec56                	sd	s5,24(sp)
    80003034:	e85a                	sd	s6,16(sp)
    80003036:	e45e                	sd	s7,8(sp)
    80003038:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000303a:	0001b717          	auipc	a4,0x1b
    8000303e:	e4272703          	lw	a4,-446(a4) # 8001de7c <sb+0xc>
    80003042:	4785                	li	a5,1
    80003044:	04e7f663          	bgeu	a5,a4,80003090 <ialloc+0x6c>
    80003048:	8aaa                	mv	s5,a0
    8000304a:	8bae                	mv	s7,a1
    8000304c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000304e:	0001ba17          	auipc	s4,0x1b
    80003052:	e22a0a13          	addi	s4,s4,-478 # 8001de70 <sb>
    80003056:	00048b1b          	sext.w	s6,s1
    8000305a:	0044d793          	srli	a5,s1,0x4
    8000305e:	018a2583          	lw	a1,24(s4)
    80003062:	9dbd                	addw	a1,a1,a5
    80003064:	8556                	mv	a0,s5
    80003066:	a75ff0ef          	jal	ra,80002ada <bread>
    8000306a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000306c:	05850993          	addi	s3,a0,88
    80003070:	00f4f793          	andi	a5,s1,15
    80003074:	079a                	slli	a5,a5,0x6
    80003076:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003078:	00099783          	lh	a5,0(s3)
    8000307c:	cf85                	beqz	a5,800030b4 <ialloc+0x90>
    brelse(bp);
    8000307e:	b65ff0ef          	jal	ra,80002be2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003082:	0485                	addi	s1,s1,1
    80003084:	00ca2703          	lw	a4,12(s4)
    80003088:	0004879b          	sext.w	a5,s1
    8000308c:	fce7e5e3          	bltu	a5,a4,80003056 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003090:	00004517          	auipc	a0,0x4
    80003094:	4b850513          	addi	a0,a0,1208 # 80007548 <syscalls+0x158>
    80003098:	c2cfd0ef          	jal	ra,800004c4 <printf>
  return 0;
    8000309c:	4501                	li	a0,0
}
    8000309e:	60a6                	ld	ra,72(sp)
    800030a0:	6406                	ld	s0,64(sp)
    800030a2:	74e2                	ld	s1,56(sp)
    800030a4:	7942                	ld	s2,48(sp)
    800030a6:	79a2                	ld	s3,40(sp)
    800030a8:	7a02                	ld	s4,32(sp)
    800030aa:	6ae2                	ld	s5,24(sp)
    800030ac:	6b42                	ld	s6,16(sp)
    800030ae:	6ba2                	ld	s7,8(sp)
    800030b0:	6161                	addi	sp,sp,80
    800030b2:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800030b4:	04000613          	li	a2,64
    800030b8:	4581                	li	a1,0
    800030ba:	854e                	mv	a0,s3
    800030bc:	b85fd0ef          	jal	ra,80000c40 <memset>
      dip->type = type;
    800030c0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800030c4:	854a                	mv	a0,s2
    800030c6:	429000ef          	jal	ra,80003cee <log_write>
      brelse(bp);
    800030ca:	854a                	mv	a0,s2
    800030cc:	b17ff0ef          	jal	ra,80002be2 <brelse>
      return iget(dev, inum);
    800030d0:	85da                	mv	a1,s6
    800030d2:	8556                	mv	a0,s5
    800030d4:	e4dff0ef          	jal	ra,80002f20 <iget>
    800030d8:	b7d9                	j	8000309e <ialloc+0x7a>

00000000800030da <iupdate>:
{
    800030da:	1101                	addi	sp,sp,-32
    800030dc:	ec06                	sd	ra,24(sp)
    800030de:	e822                	sd	s0,16(sp)
    800030e0:	e426                	sd	s1,8(sp)
    800030e2:	e04a                	sd	s2,0(sp)
    800030e4:	1000                	addi	s0,sp,32
    800030e6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800030e8:	415c                	lw	a5,4(a0)
    800030ea:	0047d79b          	srliw	a5,a5,0x4
    800030ee:	0001b597          	auipc	a1,0x1b
    800030f2:	d9a5a583          	lw	a1,-614(a1) # 8001de88 <sb+0x18>
    800030f6:	9dbd                	addw	a1,a1,a5
    800030f8:	4108                	lw	a0,0(a0)
    800030fa:	9e1ff0ef          	jal	ra,80002ada <bread>
    800030fe:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003100:	05850793          	addi	a5,a0,88
    80003104:	40c8                	lw	a0,4(s1)
    80003106:	893d                	andi	a0,a0,15
    80003108:	051a                	slli	a0,a0,0x6
    8000310a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000310c:	04449703          	lh	a4,68(s1)
    80003110:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003114:	04649703          	lh	a4,70(s1)
    80003118:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000311c:	04849703          	lh	a4,72(s1)
    80003120:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003124:	04a49703          	lh	a4,74(s1)
    80003128:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000312c:	44f8                	lw	a4,76(s1)
    8000312e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003130:	03400613          	li	a2,52
    80003134:	05048593          	addi	a1,s1,80
    80003138:	0531                	addi	a0,a0,12
    8000313a:	b63fd0ef          	jal	ra,80000c9c <memmove>
  log_write(bp);
    8000313e:	854a                	mv	a0,s2
    80003140:	3af000ef          	jal	ra,80003cee <log_write>
  brelse(bp);
    80003144:	854a                	mv	a0,s2
    80003146:	a9dff0ef          	jal	ra,80002be2 <brelse>
}
    8000314a:	60e2                	ld	ra,24(sp)
    8000314c:	6442                	ld	s0,16(sp)
    8000314e:	64a2                	ld	s1,8(sp)
    80003150:	6902                	ld	s2,0(sp)
    80003152:	6105                	addi	sp,sp,32
    80003154:	8082                	ret

0000000080003156 <idup>:
{
    80003156:	1101                	addi	sp,sp,-32
    80003158:	ec06                	sd	ra,24(sp)
    8000315a:	e822                	sd	s0,16(sp)
    8000315c:	e426                	sd	s1,8(sp)
    8000315e:	1000                	addi	s0,sp,32
    80003160:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003162:	0001b517          	auipc	a0,0x1b
    80003166:	d2e50513          	addi	a0,a0,-722 # 8001de90 <itable>
    8000316a:	a03fd0ef          	jal	ra,80000b6c <acquire>
  ip->ref++;
    8000316e:	449c                	lw	a5,8(s1)
    80003170:	2785                	addiw	a5,a5,1
    80003172:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003174:	0001b517          	auipc	a0,0x1b
    80003178:	d1c50513          	addi	a0,a0,-740 # 8001de90 <itable>
    8000317c:	a89fd0ef          	jal	ra,80000c04 <release>
}
    80003180:	8526                	mv	a0,s1
    80003182:	60e2                	ld	ra,24(sp)
    80003184:	6442                	ld	s0,16(sp)
    80003186:	64a2                	ld	s1,8(sp)
    80003188:	6105                	addi	sp,sp,32
    8000318a:	8082                	ret

000000008000318c <ilock>:
{
    8000318c:	1101                	addi	sp,sp,-32
    8000318e:	ec06                	sd	ra,24(sp)
    80003190:	e822                	sd	s0,16(sp)
    80003192:	e426                	sd	s1,8(sp)
    80003194:	e04a                	sd	s2,0(sp)
    80003196:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003198:	c105                	beqz	a0,800031b8 <ilock+0x2c>
    8000319a:	84aa                	mv	s1,a0
    8000319c:	451c                	lw	a5,8(a0)
    8000319e:	00f05d63          	blez	a5,800031b8 <ilock+0x2c>
  acquiresleep(&ip->lock);
    800031a2:	0541                	addi	a0,a0,16
    800031a4:	445000ef          	jal	ra,80003de8 <acquiresleep>
  if(ip->valid == 0){
    800031a8:	40bc                	lw	a5,64(s1)
    800031aa:	cf89                	beqz	a5,800031c4 <ilock+0x38>
}
    800031ac:	60e2                	ld	ra,24(sp)
    800031ae:	6442                	ld	s0,16(sp)
    800031b0:	64a2                	ld	s1,8(sp)
    800031b2:	6902                	ld	s2,0(sp)
    800031b4:	6105                	addi	sp,sp,32
    800031b6:	8082                	ret
    panic("ilock");
    800031b8:	00004517          	auipc	a0,0x4
    800031bc:	3a850513          	addi	a0,a0,936 # 80007560 <syscalls+0x170>
    800031c0:	dcafd0ef          	jal	ra,8000078a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800031c4:	40dc                	lw	a5,4(s1)
    800031c6:	0047d79b          	srliw	a5,a5,0x4
    800031ca:	0001b597          	auipc	a1,0x1b
    800031ce:	cbe5a583          	lw	a1,-834(a1) # 8001de88 <sb+0x18>
    800031d2:	9dbd                	addw	a1,a1,a5
    800031d4:	4088                	lw	a0,0(s1)
    800031d6:	905ff0ef          	jal	ra,80002ada <bread>
    800031da:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800031dc:	05850593          	addi	a1,a0,88
    800031e0:	40dc                	lw	a5,4(s1)
    800031e2:	8bbd                	andi	a5,a5,15
    800031e4:	079a                	slli	a5,a5,0x6
    800031e6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800031e8:	00059783          	lh	a5,0(a1)
    800031ec:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800031f0:	00259783          	lh	a5,2(a1)
    800031f4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800031f8:	00459783          	lh	a5,4(a1)
    800031fc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003200:	00659783          	lh	a5,6(a1)
    80003204:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003208:	459c                	lw	a5,8(a1)
    8000320a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000320c:	03400613          	li	a2,52
    80003210:	05b1                	addi	a1,a1,12
    80003212:	05048513          	addi	a0,s1,80
    80003216:	a87fd0ef          	jal	ra,80000c9c <memmove>
    brelse(bp);
    8000321a:	854a                	mv	a0,s2
    8000321c:	9c7ff0ef          	jal	ra,80002be2 <brelse>
    ip->valid = 1;
    80003220:	4785                	li	a5,1
    80003222:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003224:	04449783          	lh	a5,68(s1)
    80003228:	f3d1                	bnez	a5,800031ac <ilock+0x20>
      panic("ilock: no type");
    8000322a:	00004517          	auipc	a0,0x4
    8000322e:	33e50513          	addi	a0,a0,830 # 80007568 <syscalls+0x178>
    80003232:	d58fd0ef          	jal	ra,8000078a <panic>

0000000080003236 <iunlock>:
{
    80003236:	1101                	addi	sp,sp,-32
    80003238:	ec06                	sd	ra,24(sp)
    8000323a:	e822                	sd	s0,16(sp)
    8000323c:	e426                	sd	s1,8(sp)
    8000323e:	e04a                	sd	s2,0(sp)
    80003240:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003242:	c505                	beqz	a0,8000326a <iunlock+0x34>
    80003244:	84aa                	mv	s1,a0
    80003246:	01050913          	addi	s2,a0,16
    8000324a:	854a                	mv	a0,s2
    8000324c:	41b000ef          	jal	ra,80003e66 <holdingsleep>
    80003250:	cd09                	beqz	a0,8000326a <iunlock+0x34>
    80003252:	449c                	lw	a5,8(s1)
    80003254:	00f05b63          	blez	a5,8000326a <iunlock+0x34>
  releasesleep(&ip->lock);
    80003258:	854a                	mv	a0,s2
    8000325a:	3d5000ef          	jal	ra,80003e2e <releasesleep>
}
    8000325e:	60e2                	ld	ra,24(sp)
    80003260:	6442                	ld	s0,16(sp)
    80003262:	64a2                	ld	s1,8(sp)
    80003264:	6902                	ld	s2,0(sp)
    80003266:	6105                	addi	sp,sp,32
    80003268:	8082                	ret
    panic("iunlock");
    8000326a:	00004517          	auipc	a0,0x4
    8000326e:	30e50513          	addi	a0,a0,782 # 80007578 <syscalls+0x188>
    80003272:	d18fd0ef          	jal	ra,8000078a <panic>

0000000080003276 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003276:	7179                	addi	sp,sp,-48
    80003278:	f406                	sd	ra,40(sp)
    8000327a:	f022                	sd	s0,32(sp)
    8000327c:	ec26                	sd	s1,24(sp)
    8000327e:	e84a                	sd	s2,16(sp)
    80003280:	e44e                	sd	s3,8(sp)
    80003282:	e052                	sd	s4,0(sp)
    80003284:	1800                	addi	s0,sp,48
    80003286:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003288:	05050493          	addi	s1,a0,80
    8000328c:	08050913          	addi	s2,a0,128
    80003290:	a021                	j	80003298 <itrunc+0x22>
    80003292:	0491                	addi	s1,s1,4
    80003294:	01248b63          	beq	s1,s2,800032aa <itrunc+0x34>
    if(ip->addrs[i]){
    80003298:	408c                	lw	a1,0(s1)
    8000329a:	dde5                	beqz	a1,80003292 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000329c:	0009a503          	lw	a0,0(s3)
    800032a0:	a35ff0ef          	jal	ra,80002cd4 <bfree>
      ip->addrs[i] = 0;
    800032a4:	0004a023          	sw	zero,0(s1)
    800032a8:	b7ed                	j	80003292 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800032aa:	0809a583          	lw	a1,128(s3)
    800032ae:	ed91                	bnez	a1,800032ca <itrunc+0x54>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800032b0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800032b4:	854e                	mv	a0,s3
    800032b6:	e25ff0ef          	jal	ra,800030da <iupdate>
}
    800032ba:	70a2                	ld	ra,40(sp)
    800032bc:	7402                	ld	s0,32(sp)
    800032be:	64e2                	ld	s1,24(sp)
    800032c0:	6942                	ld	s2,16(sp)
    800032c2:	69a2                	ld	s3,8(sp)
    800032c4:	6a02                	ld	s4,0(sp)
    800032c6:	6145                	addi	sp,sp,48
    800032c8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800032ca:	0009a503          	lw	a0,0(s3)
    800032ce:	80dff0ef          	jal	ra,80002ada <bread>
    800032d2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800032d4:	05850493          	addi	s1,a0,88
    800032d8:	45850913          	addi	s2,a0,1112
    800032dc:	a021                	j	800032e4 <itrunc+0x6e>
    800032de:	0491                	addi	s1,s1,4
    800032e0:	01248963          	beq	s1,s2,800032f2 <itrunc+0x7c>
      if(a[j])
    800032e4:	408c                	lw	a1,0(s1)
    800032e6:	dde5                	beqz	a1,800032de <itrunc+0x68>
        bfree(ip->dev, a[j]);
    800032e8:	0009a503          	lw	a0,0(s3)
    800032ec:	9e9ff0ef          	jal	ra,80002cd4 <bfree>
    800032f0:	b7fd                	j	800032de <itrunc+0x68>
    brelse(bp);
    800032f2:	8552                	mv	a0,s4
    800032f4:	8efff0ef          	jal	ra,80002be2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800032f8:	0809a583          	lw	a1,128(s3)
    800032fc:	0009a503          	lw	a0,0(s3)
    80003300:	9d5ff0ef          	jal	ra,80002cd4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003304:	0809a023          	sw	zero,128(s3)
    80003308:	b765                	j	800032b0 <itrunc+0x3a>

000000008000330a <iput>:
{
    8000330a:	1101                	addi	sp,sp,-32
    8000330c:	ec06                	sd	ra,24(sp)
    8000330e:	e822                	sd	s0,16(sp)
    80003310:	e426                	sd	s1,8(sp)
    80003312:	e04a                	sd	s2,0(sp)
    80003314:	1000                	addi	s0,sp,32
    80003316:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003318:	0001b517          	auipc	a0,0x1b
    8000331c:	b7850513          	addi	a0,a0,-1160 # 8001de90 <itable>
    80003320:	84dfd0ef          	jal	ra,80000b6c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003324:	4498                	lw	a4,8(s1)
    80003326:	4785                	li	a5,1
    80003328:	02f70163          	beq	a4,a5,8000334a <iput+0x40>
  ip->ref--;
    8000332c:	449c                	lw	a5,8(s1)
    8000332e:	37fd                	addiw	a5,a5,-1
    80003330:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003332:	0001b517          	auipc	a0,0x1b
    80003336:	b5e50513          	addi	a0,a0,-1186 # 8001de90 <itable>
    8000333a:	8cbfd0ef          	jal	ra,80000c04 <release>
}
    8000333e:	60e2                	ld	ra,24(sp)
    80003340:	6442                	ld	s0,16(sp)
    80003342:	64a2                	ld	s1,8(sp)
    80003344:	6902                	ld	s2,0(sp)
    80003346:	6105                	addi	sp,sp,32
    80003348:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000334a:	40bc                	lw	a5,64(s1)
    8000334c:	d3e5                	beqz	a5,8000332c <iput+0x22>
    8000334e:	04a49783          	lh	a5,74(s1)
    80003352:	ffe9                	bnez	a5,8000332c <iput+0x22>
    acquiresleep(&ip->lock);
    80003354:	01048913          	addi	s2,s1,16
    80003358:	854a                	mv	a0,s2
    8000335a:	28f000ef          	jal	ra,80003de8 <acquiresleep>
    release(&itable.lock);
    8000335e:	0001b517          	auipc	a0,0x1b
    80003362:	b3250513          	addi	a0,a0,-1230 # 8001de90 <itable>
    80003366:	89ffd0ef          	jal	ra,80000c04 <release>
    itrunc(ip);
    8000336a:	8526                	mv	a0,s1
    8000336c:	f0bff0ef          	jal	ra,80003276 <itrunc>
    ip->type = 0;
    80003370:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003374:	8526                	mv	a0,s1
    80003376:	d65ff0ef          	jal	ra,800030da <iupdate>
    ip->valid = 0;
    8000337a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000337e:	854a                	mv	a0,s2
    80003380:	2af000ef          	jal	ra,80003e2e <releasesleep>
    acquire(&itable.lock);
    80003384:	0001b517          	auipc	a0,0x1b
    80003388:	b0c50513          	addi	a0,a0,-1268 # 8001de90 <itable>
    8000338c:	fe0fd0ef          	jal	ra,80000b6c <acquire>
    80003390:	bf71                	j	8000332c <iput+0x22>

0000000080003392 <iunlockput>:
{
    80003392:	1101                	addi	sp,sp,-32
    80003394:	ec06                	sd	ra,24(sp)
    80003396:	e822                	sd	s0,16(sp)
    80003398:	e426                	sd	s1,8(sp)
    8000339a:	1000                	addi	s0,sp,32
    8000339c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000339e:	e99ff0ef          	jal	ra,80003236 <iunlock>
  iput(ip);
    800033a2:	8526                	mv	a0,s1
    800033a4:	f67ff0ef          	jal	ra,8000330a <iput>
}
    800033a8:	60e2                	ld	ra,24(sp)
    800033aa:	6442                	ld	s0,16(sp)
    800033ac:	64a2                	ld	s1,8(sp)
    800033ae:	6105                	addi	sp,sp,32
    800033b0:	8082                	ret

00000000800033b2 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800033b2:	0001b717          	auipc	a4,0x1b
    800033b6:	aca72703          	lw	a4,-1334(a4) # 8001de7c <sb+0xc>
    800033ba:	4785                	li	a5,1
    800033bc:	0ae7ff63          	bgeu	a5,a4,8000347a <ireclaim+0xc8>
{
    800033c0:	7139                	addi	sp,sp,-64
    800033c2:	fc06                	sd	ra,56(sp)
    800033c4:	f822                	sd	s0,48(sp)
    800033c6:	f426                	sd	s1,40(sp)
    800033c8:	f04a                	sd	s2,32(sp)
    800033ca:	ec4e                	sd	s3,24(sp)
    800033cc:	e852                	sd	s4,16(sp)
    800033ce:	e456                	sd	s5,8(sp)
    800033d0:	e05a                	sd	s6,0(sp)
    800033d2:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800033d4:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    800033d6:	00050a1b          	sext.w	s4,a0
    800033da:	0001ba97          	auipc	s5,0x1b
    800033de:	a96a8a93          	addi	s5,s5,-1386 # 8001de70 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    800033e2:	00004b17          	auipc	s6,0x4
    800033e6:	19eb0b13          	addi	s6,s6,414 # 80007580 <syscalls+0x190>
    800033ea:	a099                	j	80003430 <ireclaim+0x7e>
    800033ec:	85ce                	mv	a1,s3
    800033ee:	855a                	mv	a0,s6
    800033f0:	8d4fd0ef          	jal	ra,800004c4 <printf>
      ip = iget(dev, inum);
    800033f4:	85ce                	mv	a1,s3
    800033f6:	8552                	mv	a0,s4
    800033f8:	b29ff0ef          	jal	ra,80002f20 <iget>
    800033fc:	89aa                	mv	s3,a0
    brelse(bp);
    800033fe:	854a                	mv	a0,s2
    80003400:	fe2ff0ef          	jal	ra,80002be2 <brelse>
    if (ip) {
    80003404:	00098f63          	beqz	s3,80003422 <ireclaim+0x70>
      begin_op();
    80003408:	762000ef          	jal	ra,80003b6a <begin_op>
      ilock(ip);
    8000340c:	854e                	mv	a0,s3
    8000340e:	d7fff0ef          	jal	ra,8000318c <ilock>
      iunlock(ip);
    80003412:	854e                	mv	a0,s3
    80003414:	e23ff0ef          	jal	ra,80003236 <iunlock>
      iput(ip);
    80003418:	854e                	mv	a0,s3
    8000341a:	ef1ff0ef          	jal	ra,8000330a <iput>
      end_op();
    8000341e:	7bc000ef          	jal	ra,80003bda <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003422:	0485                	addi	s1,s1,1
    80003424:	00caa703          	lw	a4,12(s5)
    80003428:	0004879b          	sext.w	a5,s1
    8000342c:	02e7fd63          	bgeu	a5,a4,80003466 <ireclaim+0xb4>
    80003430:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003434:	0044d793          	srli	a5,s1,0x4
    80003438:	018aa583          	lw	a1,24(s5)
    8000343c:	9dbd                	addw	a1,a1,a5
    8000343e:	8552                	mv	a0,s4
    80003440:	e9aff0ef          	jal	ra,80002ada <bread>
    80003444:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    80003446:	05850793          	addi	a5,a0,88
    8000344a:	00f9f713          	andi	a4,s3,15
    8000344e:	071a                	slli	a4,a4,0x6
    80003450:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    80003452:	00079703          	lh	a4,0(a5)
    80003456:	c701                	beqz	a4,8000345e <ireclaim+0xac>
    80003458:	00679783          	lh	a5,6(a5)
    8000345c:	dbc1                	beqz	a5,800033ec <ireclaim+0x3a>
    brelse(bp);
    8000345e:	854a                	mv	a0,s2
    80003460:	f82ff0ef          	jal	ra,80002be2 <brelse>
    if (ip) {
    80003464:	bf7d                	j	80003422 <ireclaim+0x70>
}
    80003466:	70e2                	ld	ra,56(sp)
    80003468:	7442                	ld	s0,48(sp)
    8000346a:	74a2                	ld	s1,40(sp)
    8000346c:	7902                	ld	s2,32(sp)
    8000346e:	69e2                	ld	s3,24(sp)
    80003470:	6a42                	ld	s4,16(sp)
    80003472:	6aa2                	ld	s5,8(sp)
    80003474:	6b02                	ld	s6,0(sp)
    80003476:	6121                	addi	sp,sp,64
    80003478:	8082                	ret
    8000347a:	8082                	ret

000000008000347c <fsinit>:
fsinit(int dev) {
    8000347c:	7179                	addi	sp,sp,-48
    8000347e:	f406                	sd	ra,40(sp)
    80003480:	f022                	sd	s0,32(sp)
    80003482:	ec26                	sd	s1,24(sp)
    80003484:	e84a                	sd	s2,16(sp)
    80003486:	e44e                	sd	s3,8(sp)
    80003488:	1800                	addi	s0,sp,48
    8000348a:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    8000348c:	4585                	li	a1,1
    8000348e:	e4cff0ef          	jal	ra,80002ada <bread>
    80003492:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003494:	0001b997          	auipc	s3,0x1b
    80003498:	9dc98993          	addi	s3,s3,-1572 # 8001de70 <sb>
    8000349c:	02000613          	li	a2,32
    800034a0:	05850593          	addi	a1,a0,88
    800034a4:	854e                	mv	a0,s3
    800034a6:	ff6fd0ef          	jal	ra,80000c9c <memmove>
  brelse(bp);
    800034aa:	854a                	mv	a0,s2
    800034ac:	f36ff0ef          	jal	ra,80002be2 <brelse>
  if(sb.magic != FSMAGIC)
    800034b0:	0009a703          	lw	a4,0(s3)
    800034b4:	102037b7          	lui	a5,0x10203
    800034b8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034bc:	02f71363          	bne	a4,a5,800034e2 <fsinit+0x66>
  initlog(dev, &sb);
    800034c0:	0001b597          	auipc	a1,0x1b
    800034c4:	9b058593          	addi	a1,a1,-1616 # 8001de70 <sb>
    800034c8:	8526                	mv	a0,s1
    800034ca:	616000ef          	jal	ra,80003ae0 <initlog>
  ireclaim(dev);
    800034ce:	8526                	mv	a0,s1
    800034d0:	ee3ff0ef          	jal	ra,800033b2 <ireclaim>
}
    800034d4:	70a2                	ld	ra,40(sp)
    800034d6:	7402                	ld	s0,32(sp)
    800034d8:	64e2                	ld	s1,24(sp)
    800034da:	6942                	ld	s2,16(sp)
    800034dc:	69a2                	ld	s3,8(sp)
    800034de:	6145                	addi	sp,sp,48
    800034e0:	8082                	ret
    panic("invalid file system");
    800034e2:	00004517          	auipc	a0,0x4
    800034e6:	0be50513          	addi	a0,a0,190 # 800075a0 <syscalls+0x1b0>
    800034ea:	aa0fd0ef          	jal	ra,8000078a <panic>

00000000800034ee <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800034ee:	1141                	addi	sp,sp,-16
    800034f0:	e422                	sd	s0,8(sp)
    800034f2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800034f4:	411c                	lw	a5,0(a0)
    800034f6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800034f8:	415c                	lw	a5,4(a0)
    800034fa:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800034fc:	04451783          	lh	a5,68(a0)
    80003500:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003504:	04a51783          	lh	a5,74(a0)
    80003508:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000350c:	04c56783          	lwu	a5,76(a0)
    80003510:	e99c                	sd	a5,16(a1)
}
    80003512:	6422                	ld	s0,8(sp)
    80003514:	0141                	addi	sp,sp,16
    80003516:	8082                	ret

0000000080003518 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003518:	457c                	lw	a5,76(a0)
    8000351a:	0cd7ef63          	bltu	a5,a3,800035f8 <readi+0xe0>
{
    8000351e:	7159                	addi	sp,sp,-112
    80003520:	f486                	sd	ra,104(sp)
    80003522:	f0a2                	sd	s0,96(sp)
    80003524:	eca6                	sd	s1,88(sp)
    80003526:	e8ca                	sd	s2,80(sp)
    80003528:	e4ce                	sd	s3,72(sp)
    8000352a:	e0d2                	sd	s4,64(sp)
    8000352c:	fc56                	sd	s5,56(sp)
    8000352e:	f85a                	sd	s6,48(sp)
    80003530:	f45e                	sd	s7,40(sp)
    80003532:	f062                	sd	s8,32(sp)
    80003534:	ec66                	sd	s9,24(sp)
    80003536:	e86a                	sd	s10,16(sp)
    80003538:	e46e                	sd	s11,8(sp)
    8000353a:	1880                	addi	s0,sp,112
    8000353c:	8b2a                	mv	s6,a0
    8000353e:	8bae                	mv	s7,a1
    80003540:	8a32                	mv	s4,a2
    80003542:	84b6                	mv	s1,a3
    80003544:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003546:	9f35                	addw	a4,a4,a3
    return 0;
    80003548:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000354a:	08d76663          	bltu	a4,a3,800035d6 <readi+0xbe>
  if(off + n > ip->size)
    8000354e:	00e7f463          	bgeu	a5,a4,80003556 <readi+0x3e>
    n = ip->size - off;
    80003552:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003556:	080a8f63          	beqz	s5,800035f4 <readi+0xdc>
    8000355a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000355c:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003560:	5c7d                	li	s8,-1
    80003562:	a80d                	j	80003594 <readi+0x7c>
    80003564:	020d1d93          	slli	s11,s10,0x20
    80003568:	020ddd93          	srli	s11,s11,0x20
    8000356c:	05890793          	addi	a5,s2,88
    80003570:	86ee                	mv	a3,s11
    80003572:	963e                	add	a2,a2,a5
    80003574:	85d2                	mv	a1,s4
    80003576:	855e                	mv	a0,s7
    80003578:	bf1fe0ef          	jal	ra,80002168 <either_copyout>
    8000357c:	05850763          	beq	a0,s8,800035ca <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003580:	854a                	mv	a0,s2
    80003582:	e60ff0ef          	jal	ra,80002be2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003586:	013d09bb          	addw	s3,s10,s3
    8000358a:	009d04bb          	addw	s1,s10,s1
    8000358e:	9a6e                	add	s4,s4,s11
    80003590:	0559f163          	bgeu	s3,s5,800035d2 <readi+0xba>
    uint addr = bmap(ip, off/BSIZE);
    80003594:	00a4d59b          	srliw	a1,s1,0xa
    80003598:	855a                	mv	a0,s6
    8000359a:	8bbff0ef          	jal	ra,80002e54 <bmap>
    8000359e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800035a2:	c985                	beqz	a1,800035d2 <readi+0xba>
    bp = bread(ip->dev, addr);
    800035a4:	000b2503          	lw	a0,0(s6)
    800035a8:	d32ff0ef          	jal	ra,80002ada <bread>
    800035ac:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800035ae:	3ff4f613          	andi	a2,s1,1023
    800035b2:	40cc87bb          	subw	a5,s9,a2
    800035b6:	413a873b          	subw	a4,s5,s3
    800035ba:	8d3e                	mv	s10,a5
    800035bc:	2781                	sext.w	a5,a5
    800035be:	0007069b          	sext.w	a3,a4
    800035c2:	faf6f1e3          	bgeu	a3,a5,80003564 <readi+0x4c>
    800035c6:	8d3a                	mv	s10,a4
    800035c8:	bf71                	j	80003564 <readi+0x4c>
      brelse(bp);
    800035ca:	854a                	mv	a0,s2
    800035cc:	e16ff0ef          	jal	ra,80002be2 <brelse>
      tot = -1;
    800035d0:	59fd                	li	s3,-1
  }
  return tot;
    800035d2:	0009851b          	sext.w	a0,s3
}
    800035d6:	70a6                	ld	ra,104(sp)
    800035d8:	7406                	ld	s0,96(sp)
    800035da:	64e6                	ld	s1,88(sp)
    800035dc:	6946                	ld	s2,80(sp)
    800035de:	69a6                	ld	s3,72(sp)
    800035e0:	6a06                	ld	s4,64(sp)
    800035e2:	7ae2                	ld	s5,56(sp)
    800035e4:	7b42                	ld	s6,48(sp)
    800035e6:	7ba2                	ld	s7,40(sp)
    800035e8:	7c02                	ld	s8,32(sp)
    800035ea:	6ce2                	ld	s9,24(sp)
    800035ec:	6d42                	ld	s10,16(sp)
    800035ee:	6da2                	ld	s11,8(sp)
    800035f0:	6165                	addi	sp,sp,112
    800035f2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800035f4:	89d6                	mv	s3,s5
    800035f6:	bff1                	j	800035d2 <readi+0xba>
    return 0;
    800035f8:	4501                	li	a0,0
}
    800035fa:	8082                	ret

00000000800035fc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800035fc:	457c                	lw	a5,76(a0)
    800035fe:	0ed7ea63          	bltu	a5,a3,800036f2 <writei+0xf6>
{
    80003602:	7159                	addi	sp,sp,-112
    80003604:	f486                	sd	ra,104(sp)
    80003606:	f0a2                	sd	s0,96(sp)
    80003608:	eca6                	sd	s1,88(sp)
    8000360a:	e8ca                	sd	s2,80(sp)
    8000360c:	e4ce                	sd	s3,72(sp)
    8000360e:	e0d2                	sd	s4,64(sp)
    80003610:	fc56                	sd	s5,56(sp)
    80003612:	f85a                	sd	s6,48(sp)
    80003614:	f45e                	sd	s7,40(sp)
    80003616:	f062                	sd	s8,32(sp)
    80003618:	ec66                	sd	s9,24(sp)
    8000361a:	e86a                	sd	s10,16(sp)
    8000361c:	e46e                	sd	s11,8(sp)
    8000361e:	1880                	addi	s0,sp,112
    80003620:	8aaa                	mv	s5,a0
    80003622:	8bae                	mv	s7,a1
    80003624:	8a32                	mv	s4,a2
    80003626:	8936                	mv	s2,a3
    80003628:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000362a:	00e687bb          	addw	a5,a3,a4
    8000362e:	0cd7e463          	bltu	a5,a3,800036f6 <writei+0xfa>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003632:	00043737          	lui	a4,0x43
    80003636:	0cf76263          	bltu	a4,a5,800036fa <writei+0xfe>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000363a:	0a0b0a63          	beqz	s6,800036ee <writei+0xf2>
    8000363e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003640:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003644:	5c7d                	li	s8,-1
    80003646:	a825                	j	8000367e <writei+0x82>
    80003648:	020d1d93          	slli	s11,s10,0x20
    8000364c:	020ddd93          	srli	s11,s11,0x20
    80003650:	05848793          	addi	a5,s1,88
    80003654:	86ee                	mv	a3,s11
    80003656:	8652                	mv	a2,s4
    80003658:	85de                	mv	a1,s7
    8000365a:	953e                	add	a0,a0,a5
    8000365c:	b57fe0ef          	jal	ra,800021b2 <either_copyin>
    80003660:	05850a63          	beq	a0,s8,800036b4 <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003664:	8526                	mv	a0,s1
    80003666:	688000ef          	jal	ra,80003cee <log_write>
    brelse(bp);
    8000366a:	8526                	mv	a0,s1
    8000366c:	d76ff0ef          	jal	ra,80002be2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003670:	013d09bb          	addw	s3,s10,s3
    80003674:	012d093b          	addw	s2,s10,s2
    80003678:	9a6e                	add	s4,s4,s11
    8000367a:	0569f063          	bgeu	s3,s6,800036ba <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    8000367e:	00a9559b          	srliw	a1,s2,0xa
    80003682:	8556                	mv	a0,s5
    80003684:	fd0ff0ef          	jal	ra,80002e54 <bmap>
    80003688:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000368c:	c59d                	beqz	a1,800036ba <writei+0xbe>
    bp = bread(ip->dev, addr);
    8000368e:	000aa503          	lw	a0,0(s5)
    80003692:	c48ff0ef          	jal	ra,80002ada <bread>
    80003696:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003698:	3ff97513          	andi	a0,s2,1023
    8000369c:	40ac87bb          	subw	a5,s9,a0
    800036a0:	413b073b          	subw	a4,s6,s3
    800036a4:	8d3e                	mv	s10,a5
    800036a6:	2781                	sext.w	a5,a5
    800036a8:	0007069b          	sext.w	a3,a4
    800036ac:	f8f6fee3          	bgeu	a3,a5,80003648 <writei+0x4c>
    800036b0:	8d3a                	mv	s10,a4
    800036b2:	bf59                	j	80003648 <writei+0x4c>
      brelse(bp);
    800036b4:	8526                	mv	a0,s1
    800036b6:	d2cff0ef          	jal	ra,80002be2 <brelse>
  }

  if(off > ip->size)
    800036ba:	04caa783          	lw	a5,76(s5)
    800036be:	0127f463          	bgeu	a5,s2,800036c6 <writei+0xca>
    ip->size = off;
    800036c2:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800036c6:	8556                	mv	a0,s5
    800036c8:	a13ff0ef          	jal	ra,800030da <iupdate>

  return tot;
    800036cc:	0009851b          	sext.w	a0,s3
}
    800036d0:	70a6                	ld	ra,104(sp)
    800036d2:	7406                	ld	s0,96(sp)
    800036d4:	64e6                	ld	s1,88(sp)
    800036d6:	6946                	ld	s2,80(sp)
    800036d8:	69a6                	ld	s3,72(sp)
    800036da:	6a06                	ld	s4,64(sp)
    800036dc:	7ae2                	ld	s5,56(sp)
    800036de:	7b42                	ld	s6,48(sp)
    800036e0:	7ba2                	ld	s7,40(sp)
    800036e2:	7c02                	ld	s8,32(sp)
    800036e4:	6ce2                	ld	s9,24(sp)
    800036e6:	6d42                	ld	s10,16(sp)
    800036e8:	6da2                	ld	s11,8(sp)
    800036ea:	6165                	addi	sp,sp,112
    800036ec:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800036ee:	89da                	mv	s3,s6
    800036f0:	bfd9                	j	800036c6 <writei+0xca>
    return -1;
    800036f2:	557d                	li	a0,-1
}
    800036f4:	8082                	ret
    return -1;
    800036f6:	557d                	li	a0,-1
    800036f8:	bfe1                	j	800036d0 <writei+0xd4>
    return -1;
    800036fa:	557d                	li	a0,-1
    800036fc:	bfd1                	j	800036d0 <writei+0xd4>

00000000800036fe <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800036fe:	1141                	addi	sp,sp,-16
    80003700:	e406                	sd	ra,8(sp)
    80003702:	e022                	sd	s0,0(sp)
    80003704:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003706:	4639                	li	a2,14
    80003708:	e04fd0ef          	jal	ra,80000d0c <strncmp>
}
    8000370c:	60a2                	ld	ra,8(sp)
    8000370e:	6402                	ld	s0,0(sp)
    80003710:	0141                	addi	sp,sp,16
    80003712:	8082                	ret

0000000080003714 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003714:	7139                	addi	sp,sp,-64
    80003716:	fc06                	sd	ra,56(sp)
    80003718:	f822                	sd	s0,48(sp)
    8000371a:	f426                	sd	s1,40(sp)
    8000371c:	f04a                	sd	s2,32(sp)
    8000371e:	ec4e                	sd	s3,24(sp)
    80003720:	e852                	sd	s4,16(sp)
    80003722:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003724:	04451703          	lh	a4,68(a0)
    80003728:	4785                	li	a5,1
    8000372a:	00f71a63          	bne	a4,a5,8000373e <dirlookup+0x2a>
    8000372e:	892a                	mv	s2,a0
    80003730:	89ae                	mv	s3,a1
    80003732:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003734:	457c                	lw	a5,76(a0)
    80003736:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003738:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000373a:	e39d                	bnez	a5,80003760 <dirlookup+0x4c>
    8000373c:	a095                	j	800037a0 <dirlookup+0x8c>
    panic("dirlookup not DIR");
    8000373e:	00004517          	auipc	a0,0x4
    80003742:	e7a50513          	addi	a0,a0,-390 # 800075b8 <syscalls+0x1c8>
    80003746:	844fd0ef          	jal	ra,8000078a <panic>
      panic("dirlookup read");
    8000374a:	00004517          	auipc	a0,0x4
    8000374e:	e8650513          	addi	a0,a0,-378 # 800075d0 <syscalls+0x1e0>
    80003752:	838fd0ef          	jal	ra,8000078a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003756:	24c1                	addiw	s1,s1,16
    80003758:	04c92783          	lw	a5,76(s2)
    8000375c:	04f4f163          	bgeu	s1,a5,8000379e <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003760:	4741                	li	a4,16
    80003762:	86a6                	mv	a3,s1
    80003764:	fc040613          	addi	a2,s0,-64
    80003768:	4581                	li	a1,0
    8000376a:	854a                	mv	a0,s2
    8000376c:	dadff0ef          	jal	ra,80003518 <readi>
    80003770:	47c1                	li	a5,16
    80003772:	fcf51ce3          	bne	a0,a5,8000374a <dirlookup+0x36>
    if(de.inum == 0)
    80003776:	fc045783          	lhu	a5,-64(s0)
    8000377a:	dff1                	beqz	a5,80003756 <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    8000377c:	fc240593          	addi	a1,s0,-62
    80003780:	854e                	mv	a0,s3
    80003782:	f7dff0ef          	jal	ra,800036fe <namecmp>
    80003786:	f961                	bnez	a0,80003756 <dirlookup+0x42>
      if(poff)
    80003788:	000a0463          	beqz	s4,80003790 <dirlookup+0x7c>
        *poff = off;
    8000378c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003790:	fc045583          	lhu	a1,-64(s0)
    80003794:	00092503          	lw	a0,0(s2)
    80003798:	f88ff0ef          	jal	ra,80002f20 <iget>
    8000379c:	a011                	j	800037a0 <dirlookup+0x8c>
  return 0;
    8000379e:	4501                	li	a0,0
}
    800037a0:	70e2                	ld	ra,56(sp)
    800037a2:	7442                	ld	s0,48(sp)
    800037a4:	74a2                	ld	s1,40(sp)
    800037a6:	7902                	ld	s2,32(sp)
    800037a8:	69e2                	ld	s3,24(sp)
    800037aa:	6a42                	ld	s4,16(sp)
    800037ac:	6121                	addi	sp,sp,64
    800037ae:	8082                	ret

00000000800037b0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800037b0:	711d                	addi	sp,sp,-96
    800037b2:	ec86                	sd	ra,88(sp)
    800037b4:	e8a2                	sd	s0,80(sp)
    800037b6:	e4a6                	sd	s1,72(sp)
    800037b8:	e0ca                	sd	s2,64(sp)
    800037ba:	fc4e                	sd	s3,56(sp)
    800037bc:	f852                	sd	s4,48(sp)
    800037be:	f456                	sd	s5,40(sp)
    800037c0:	f05a                	sd	s6,32(sp)
    800037c2:	ec5e                	sd	s7,24(sp)
    800037c4:	e862                	sd	s8,16(sp)
    800037c6:	e466                	sd	s9,8(sp)
    800037c8:	1080                	addi	s0,sp,96
    800037ca:	84aa                	mv	s1,a0
    800037cc:	8aae                	mv	s5,a1
    800037ce:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800037d0:	00054703          	lbu	a4,0(a0)
    800037d4:	02f00793          	li	a5,47
    800037d8:	00f70f63          	beq	a4,a5,800037f6 <namex+0x46>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800037dc:	828fe0ef          	jal	ra,80001804 <myproc>
    800037e0:	15053503          	ld	a0,336(a0)
    800037e4:	973ff0ef          	jal	ra,80003156 <idup>
    800037e8:	89aa                	mv	s3,a0
  while(*path == '/')
    800037ea:	02f00913          	li	s2,47
  len = path - s;
    800037ee:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800037f0:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800037f2:	4b85                	li	s7,1
    800037f4:	a861                	j	8000388c <namex+0xdc>
    ip = iget(ROOTDEV, ROOTINO);
    800037f6:	4585                	li	a1,1
    800037f8:	4505                	li	a0,1
    800037fa:	f26ff0ef          	jal	ra,80002f20 <iget>
    800037fe:	89aa                	mv	s3,a0
    80003800:	b7ed                	j	800037ea <namex+0x3a>
      iunlockput(ip);
    80003802:	854e                	mv	a0,s3
    80003804:	b8fff0ef          	jal	ra,80003392 <iunlockput>
      return 0;
    80003808:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000380a:	854e                	mv	a0,s3
    8000380c:	60e6                	ld	ra,88(sp)
    8000380e:	6446                	ld	s0,80(sp)
    80003810:	64a6                	ld	s1,72(sp)
    80003812:	6906                	ld	s2,64(sp)
    80003814:	79e2                	ld	s3,56(sp)
    80003816:	7a42                	ld	s4,48(sp)
    80003818:	7aa2                	ld	s5,40(sp)
    8000381a:	7b02                	ld	s6,32(sp)
    8000381c:	6be2                	ld	s7,24(sp)
    8000381e:	6c42                	ld	s8,16(sp)
    80003820:	6ca2                	ld	s9,8(sp)
    80003822:	6125                	addi	sp,sp,96
    80003824:	8082                	ret
      iunlock(ip);
    80003826:	854e                	mv	a0,s3
    80003828:	a0fff0ef          	jal	ra,80003236 <iunlock>
      return ip;
    8000382c:	bff9                	j	8000380a <namex+0x5a>
      iunlockput(ip);
    8000382e:	854e                	mv	a0,s3
    80003830:	b63ff0ef          	jal	ra,80003392 <iunlockput>
      return 0;
    80003834:	89e6                	mv	s3,s9
    80003836:	bfd1                	j	8000380a <namex+0x5a>
  len = path - s;
    80003838:	40b48633          	sub	a2,s1,a1
    8000383c:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003840:	079c5c63          	bge	s8,s9,800038b8 <namex+0x108>
    memmove(name, s, DIRSIZ);
    80003844:	4639                	li	a2,14
    80003846:	8552                	mv	a0,s4
    80003848:	c54fd0ef          	jal	ra,80000c9c <memmove>
  while(*path == '/')
    8000384c:	0004c783          	lbu	a5,0(s1)
    80003850:	01279763          	bne	a5,s2,8000385e <namex+0xae>
    path++;
    80003854:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003856:	0004c783          	lbu	a5,0(s1)
    8000385a:	ff278de3          	beq	a5,s2,80003854 <namex+0xa4>
    ilock(ip);
    8000385e:	854e                	mv	a0,s3
    80003860:	92dff0ef          	jal	ra,8000318c <ilock>
    if(ip->type != T_DIR){
    80003864:	04499783          	lh	a5,68(s3)
    80003868:	f9779de3          	bne	a5,s7,80003802 <namex+0x52>
    if(nameiparent && *path == '\0'){
    8000386c:	000a8563          	beqz	s5,80003876 <namex+0xc6>
    80003870:	0004c783          	lbu	a5,0(s1)
    80003874:	dbcd                	beqz	a5,80003826 <namex+0x76>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003876:	865a                	mv	a2,s6
    80003878:	85d2                	mv	a1,s4
    8000387a:	854e                	mv	a0,s3
    8000387c:	e99ff0ef          	jal	ra,80003714 <dirlookup>
    80003880:	8caa                	mv	s9,a0
    80003882:	d555                	beqz	a0,8000382e <namex+0x7e>
    iunlockput(ip);
    80003884:	854e                	mv	a0,s3
    80003886:	b0dff0ef          	jal	ra,80003392 <iunlockput>
    ip = next;
    8000388a:	89e6                	mv	s3,s9
  while(*path == '/')
    8000388c:	0004c783          	lbu	a5,0(s1)
    80003890:	05279363          	bne	a5,s2,800038d6 <namex+0x126>
    path++;
    80003894:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003896:	0004c783          	lbu	a5,0(s1)
    8000389a:	ff278de3          	beq	a5,s2,80003894 <namex+0xe4>
  if(*path == 0)
    8000389e:	c78d                	beqz	a5,800038c8 <namex+0x118>
    path++;
    800038a0:	85a6                	mv	a1,s1
  len = path - s;
    800038a2:	8cda                	mv	s9,s6
    800038a4:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800038a6:	01278963          	beq	a5,s2,800038b8 <namex+0x108>
    800038aa:	d7d9                	beqz	a5,80003838 <namex+0x88>
    path++;
    800038ac:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800038ae:	0004c783          	lbu	a5,0(s1)
    800038b2:	ff279ce3          	bne	a5,s2,800038aa <namex+0xfa>
    800038b6:	b749                	j	80003838 <namex+0x88>
    memmove(name, s, len);
    800038b8:	2601                	sext.w	a2,a2
    800038ba:	8552                	mv	a0,s4
    800038bc:	be0fd0ef          	jal	ra,80000c9c <memmove>
    name[len] = 0;
    800038c0:	9cd2                	add	s9,s9,s4
    800038c2:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800038c6:	b759                	j	8000384c <namex+0x9c>
  if(nameiparent){
    800038c8:	f40a81e3          	beqz	s5,8000380a <namex+0x5a>
    iput(ip);
    800038cc:	854e                	mv	a0,s3
    800038ce:	a3dff0ef          	jal	ra,8000330a <iput>
    return 0;
    800038d2:	4981                	li	s3,0
    800038d4:	bf1d                	j	8000380a <namex+0x5a>
  if(*path == 0)
    800038d6:	dbed                	beqz	a5,800038c8 <namex+0x118>
  while(*path != '/' && *path != 0)
    800038d8:	0004c783          	lbu	a5,0(s1)
    800038dc:	85a6                	mv	a1,s1
    800038de:	b7f1                	j	800038aa <namex+0xfa>

00000000800038e0 <dirlink>:
{
    800038e0:	7139                	addi	sp,sp,-64
    800038e2:	fc06                	sd	ra,56(sp)
    800038e4:	f822                	sd	s0,48(sp)
    800038e6:	f426                	sd	s1,40(sp)
    800038e8:	f04a                	sd	s2,32(sp)
    800038ea:	ec4e                	sd	s3,24(sp)
    800038ec:	e852                	sd	s4,16(sp)
    800038ee:	0080                	addi	s0,sp,64
    800038f0:	892a                	mv	s2,a0
    800038f2:	8a2e                	mv	s4,a1
    800038f4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800038f6:	4601                	li	a2,0
    800038f8:	e1dff0ef          	jal	ra,80003714 <dirlookup>
    800038fc:	e52d                	bnez	a0,80003966 <dirlink+0x86>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800038fe:	04c92483          	lw	s1,76(s2)
    80003902:	c48d                	beqz	s1,8000392c <dirlink+0x4c>
    80003904:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003906:	4741                	li	a4,16
    80003908:	86a6                	mv	a3,s1
    8000390a:	fc040613          	addi	a2,s0,-64
    8000390e:	4581                	li	a1,0
    80003910:	854a                	mv	a0,s2
    80003912:	c07ff0ef          	jal	ra,80003518 <readi>
    80003916:	47c1                	li	a5,16
    80003918:	04f51b63          	bne	a0,a5,8000396e <dirlink+0x8e>
    if(de.inum == 0)
    8000391c:	fc045783          	lhu	a5,-64(s0)
    80003920:	c791                	beqz	a5,8000392c <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003922:	24c1                	addiw	s1,s1,16
    80003924:	04c92783          	lw	a5,76(s2)
    80003928:	fcf4efe3          	bltu	s1,a5,80003906 <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    8000392c:	4639                	li	a2,14
    8000392e:	85d2                	mv	a1,s4
    80003930:	fc240513          	addi	a0,s0,-62
    80003934:	c14fd0ef          	jal	ra,80000d48 <strncpy>
  de.inum = inum;
    80003938:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000393c:	4741                	li	a4,16
    8000393e:	86a6                	mv	a3,s1
    80003940:	fc040613          	addi	a2,s0,-64
    80003944:	4581                	li	a1,0
    80003946:	854a                	mv	a0,s2
    80003948:	cb5ff0ef          	jal	ra,800035fc <writei>
    8000394c:	1541                	addi	a0,a0,-16
    8000394e:	00a03533          	snez	a0,a0
    80003952:	40a00533          	neg	a0,a0
}
    80003956:	70e2                	ld	ra,56(sp)
    80003958:	7442                	ld	s0,48(sp)
    8000395a:	74a2                	ld	s1,40(sp)
    8000395c:	7902                	ld	s2,32(sp)
    8000395e:	69e2                	ld	s3,24(sp)
    80003960:	6a42                	ld	s4,16(sp)
    80003962:	6121                	addi	sp,sp,64
    80003964:	8082                	ret
    iput(ip);
    80003966:	9a5ff0ef          	jal	ra,8000330a <iput>
    return -1;
    8000396a:	557d                	li	a0,-1
    8000396c:	b7ed                	j	80003956 <dirlink+0x76>
      panic("dirlink read");
    8000396e:	00004517          	auipc	a0,0x4
    80003972:	c7250513          	addi	a0,a0,-910 # 800075e0 <syscalls+0x1f0>
    80003976:	e15fc0ef          	jal	ra,8000078a <panic>

000000008000397a <namei>:

struct inode*
namei(char *path)
{
    8000397a:	1101                	addi	sp,sp,-32
    8000397c:	ec06                	sd	ra,24(sp)
    8000397e:	e822                	sd	s0,16(sp)
    80003980:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003982:	fe040613          	addi	a2,s0,-32
    80003986:	4581                	li	a1,0
    80003988:	e29ff0ef          	jal	ra,800037b0 <namex>
}
    8000398c:	60e2                	ld	ra,24(sp)
    8000398e:	6442                	ld	s0,16(sp)
    80003990:	6105                	addi	sp,sp,32
    80003992:	8082                	ret

0000000080003994 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003994:	1141                	addi	sp,sp,-16
    80003996:	e406                	sd	ra,8(sp)
    80003998:	e022                	sd	s0,0(sp)
    8000399a:	0800                	addi	s0,sp,16
    8000399c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000399e:	4585                	li	a1,1
    800039a0:	e11ff0ef          	jal	ra,800037b0 <namex>
}
    800039a4:	60a2                	ld	ra,8(sp)
    800039a6:	6402                	ld	s0,0(sp)
    800039a8:	0141                	addi	sp,sp,16
    800039aa:	8082                	ret

00000000800039ac <write_head>:
  brelse(buf);  // 释放缓冲区
}

// 将内存中的日志头写回磁盘
static void write_head(void)
{
    800039ac:	1101                	addi	sp,sp,-32
    800039ae:	ec06                	sd	ra,24(sp)
    800039b0:	e822                	sd	s0,16(sp)
    800039b2:	e426                	sd	s1,8(sp)
    800039b4:	e04a                	sd	s2,0(sp)
    800039b6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800039b8:	0001c917          	auipc	s2,0x1c
    800039bc:	f8090913          	addi	s2,s2,-128 # 8001f938 <log>
    800039c0:	01892583          	lw	a1,24(s2)
    800039c4:	02492503          	lw	a0,36(s2)
    800039c8:	912ff0ef          	jal	ra,80002ada <bread>
    800039cc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;  // 更新日志中的块数量
    800039ce:	02892683          	lw	a3,40(s2)
    800039d2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800039d4:	02d05763          	blez	a3,80003a02 <write_head+0x56>
    800039d8:	0001c797          	auipc	a5,0x1c
    800039dc:	f8c78793          	addi	a5,a5,-116 # 8001f964 <log+0x2c>
    800039e0:	05c50713          	addi	a4,a0,92
    800039e4:	36fd                	addiw	a3,a3,-1
    800039e6:	1682                	slli	a3,a3,0x20
    800039e8:	9281                	srli	a3,a3,0x20
    800039ea:	068a                	slli	a3,a3,0x2
    800039ec:	0001c617          	auipc	a2,0x1c
    800039f0:	f7c60613          	addi	a2,a2,-132 # 8001f968 <log+0x30>
    800039f4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];  // 更新每个日志块的块号
    800039f6:	4390                	lw	a2,0(a5)
    800039f8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800039fa:	0791                	addi	a5,a5,4
    800039fc:	0711                	addi	a4,a4,4
    800039fe:	fed79ce3          	bne	a5,a3,800039f6 <write_head+0x4a>
  }
  bwrite(buf);  // 写回日志头块
    80003a02:	8526                	mv	a0,s1
    80003a04:	9acff0ef          	jal	ra,80002bb0 <bwrite>
  brelse(buf);  // 释放缓冲区
    80003a08:	8526                	mv	a0,s1
    80003a0a:	9d8ff0ef          	jal	ra,80002be2 <brelse>
}
    80003a0e:	60e2                	ld	ra,24(sp)
    80003a10:	6442                	ld	s0,16(sp)
    80003a12:	64a2                	ld	s1,8(sp)
    80003a14:	6902                	ld	s2,0(sp)
    80003a16:	6105                	addi	sp,sp,32
    80003a18:	8082                	ret

0000000080003a1a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003a1a:	0001c797          	auipc	a5,0x1c
    80003a1e:	f467a783          	lw	a5,-186(a5) # 8001f960 <log+0x28>
    80003a22:	0af05e63          	blez	a5,80003ade <install_trans+0xc4>
{
    80003a26:	715d                	addi	sp,sp,-80
    80003a28:	e486                	sd	ra,72(sp)
    80003a2a:	e0a2                	sd	s0,64(sp)
    80003a2c:	fc26                	sd	s1,56(sp)
    80003a2e:	f84a                	sd	s2,48(sp)
    80003a30:	f44e                	sd	s3,40(sp)
    80003a32:	f052                	sd	s4,32(sp)
    80003a34:	ec56                	sd	s5,24(sp)
    80003a36:	e85a                	sd	s6,16(sp)
    80003a38:	e45e                	sd	s7,8(sp)
    80003a3a:	0880                	addi	s0,sp,80
    80003a3c:	8b2a                	mv	s6,a0
    80003a3e:	0001ca97          	auipc	s5,0x1c
    80003a42:	f26a8a93          	addi	s5,s5,-218 # 8001f964 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003a46:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003a48:	00004b97          	auipc	s7,0x4
    80003a4c:	ba8b8b93          	addi	s7,s7,-1112 # 800075f0 <syscalls+0x200>
    struct buf *lbuf = bread(log.dev, log.start + tail + 1);  // 读取日志块
    80003a50:	0001ca17          	auipc	s4,0x1c
    80003a54:	ee8a0a13          	addi	s4,s4,-280 # 8001f938 <log>
    80003a58:	a025                	j	80003a80 <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003a5a:	000aa603          	lw	a2,0(s5)
    80003a5e:	85ce                	mv	a1,s3
    80003a60:	855e                	mv	a0,s7
    80003a62:	a63fc0ef          	jal	ra,800004c4 <printf>
    80003a66:	a839                	j	80003a84 <install_trans+0x6a>
    brelse(lbuf);  // 释放日志块
    80003a68:	854a                	mv	a0,s2
    80003a6a:	978ff0ef          	jal	ra,80002be2 <brelse>
    brelse(dbuf);  // 释放目标块
    80003a6e:	8526                	mv	a0,s1
    80003a70:	972ff0ef          	jal	ra,80002be2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003a74:	2985                	addiw	s3,s3,1
    80003a76:	0a91                	addi	s5,s5,4
    80003a78:	028a2783          	lw	a5,40(s4)
    80003a7c:	04f9d663          	bge	s3,a5,80003ac8 <install_trans+0xae>
    if(recovering) {
    80003a80:	fc0b1de3          	bnez	s6,80003a5a <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start + tail + 1);  // 读取日志块
    80003a84:	018a2583          	lw	a1,24(s4)
    80003a88:	013585bb          	addw	a1,a1,s3
    80003a8c:	2585                	addiw	a1,a1,1
    80003a8e:	024a2503          	lw	a0,36(s4)
    80003a92:	848ff0ef          	jal	ra,80002ada <bread>
    80003a96:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]);  // 读取目标块
    80003a98:	000aa583          	lw	a1,0(s5)
    80003a9c:	024a2503          	lw	a0,36(s4)
    80003aa0:	83aff0ef          	jal	ra,80002ada <bread>
    80003aa4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);
    80003aa6:	40000613          	li	a2,1024
    80003aaa:	05890593          	addi	a1,s2,88
    80003aae:	05850513          	addi	a0,a0,88
    80003ab2:	9eafd0ef          	jal	ra,80000c9c <memmove>
    bwrite(dbuf);  // 将目标块写回磁盘
    80003ab6:	8526                	mv	a0,s1
    80003ab8:	8f8ff0ef          	jal	ra,80002bb0 <bwrite>
    if(recovering == 0)
    80003abc:	fa0b16e3          	bnez	s6,80003a68 <install_trans+0x4e>
      bunpin(dbuf);  // 提交后解锁目标块
    80003ac0:	8526                	mv	a0,s1
    80003ac2:	9deff0ef          	jal	ra,80002ca0 <bunpin>
    80003ac6:	b74d                	j	80003a68 <install_trans+0x4e>
}
    80003ac8:	60a6                	ld	ra,72(sp)
    80003aca:	6406                	ld	s0,64(sp)
    80003acc:	74e2                	ld	s1,56(sp)
    80003ace:	7942                	ld	s2,48(sp)
    80003ad0:	79a2                	ld	s3,40(sp)
    80003ad2:	7a02                	ld	s4,32(sp)
    80003ad4:	6ae2                	ld	s5,24(sp)
    80003ad6:	6b42                	ld	s6,16(sp)
    80003ad8:	6ba2                	ld	s7,8(sp)
    80003ada:	6161                	addi	sp,sp,80
    80003adc:	8082                	ret
    80003ade:	8082                	ret

0000000080003ae0 <initlog>:
{
    80003ae0:	7179                	addi	sp,sp,-48
    80003ae2:	f406                	sd	ra,40(sp)
    80003ae4:	f022                	sd	s0,32(sp)
    80003ae6:	ec26                	sd	s1,24(sp)
    80003ae8:	e84a                	sd	s2,16(sp)
    80003aea:	e44e                	sd	s3,8(sp)
    80003aec:	1800                	addi	s0,sp,48
    80003aee:	892a                	mv	s2,a0
    80003af0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003af2:	0001c497          	auipc	s1,0x1c
    80003af6:	e4648493          	addi	s1,s1,-442 # 8001f938 <log>
    80003afa:	00004597          	auipc	a1,0x4
    80003afe:	b1658593          	addi	a1,a1,-1258 # 80007610 <syscalls+0x220>
    80003b02:	8526                	mv	a0,s1
    80003b04:	fe9fc0ef          	jal	ra,80000aec <initlock>
  log.start = sb->logstart;  // 设置日志起始位置
    80003b08:	0149a583          	lw	a1,20(s3)
    80003b0c:	cc8c                	sw	a1,24(s1)
  log.dev = dev;  // 设置日志设备
    80003b0e:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003b12:	854a                	mv	a0,s2
    80003b14:	fc7fe0ef          	jal	ra,80002ada <bread>
  log.lh.n = lh->n;  // 读取日志中的块数量
    80003b18:	4d34                	lw	a3,88(a0)
    80003b1a:	d494                	sw	a3,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003b1c:	02d05563          	blez	a3,80003b46 <initlog+0x66>
    80003b20:	05c50793          	addi	a5,a0,92
    80003b24:	0001c717          	auipc	a4,0x1c
    80003b28:	e4070713          	addi	a4,a4,-448 # 8001f964 <log+0x2c>
    80003b2c:	36fd                	addiw	a3,a3,-1
    80003b2e:	1682                	slli	a3,a3,0x20
    80003b30:	9281                	srli	a3,a3,0x20
    80003b32:	068a                	slli	a3,a3,0x2
    80003b34:	06050613          	addi	a2,a0,96
    80003b38:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];  // 读取每个日志块的块号
    80003b3a:	4390                	lw	a2,0(a5)
    80003b3c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003b3e:	0791                	addi	a5,a5,4
    80003b40:	0711                	addi	a4,a4,4
    80003b42:	fed79ce3          	bne	a5,a3,80003b3a <initlog+0x5a>
  brelse(buf);  // 释放缓冲区
    80003b46:	89cff0ef          	jal	ra,80002be2 <brelse>

// 从日志中恢复
static void recover_from_log(void)
{
  read_head();  // 读取日志头
  install_trans(1);  // 如果已提交，从日志复制到磁盘
    80003b4a:	4505                	li	a0,1
    80003b4c:	ecfff0ef          	jal	ra,80003a1a <install_trans>
  log.lh.n = 0;  // 清空日志中的块数量
    80003b50:	0001c797          	auipc	a5,0x1c
    80003b54:	e007a823          	sw	zero,-496(a5) # 8001f960 <log+0x28>
  write_head();  // 清空日志
    80003b58:	e55ff0ef          	jal	ra,800039ac <write_head>
}
    80003b5c:	70a2                	ld	ra,40(sp)
    80003b5e:	7402                	ld	s0,32(sp)
    80003b60:	64e2                	ld	s1,24(sp)
    80003b62:	6942                	ld	s2,16(sp)
    80003b64:	69a2                	ld	s3,8(sp)
    80003b66:	6145                	addi	sp,sp,48
    80003b68:	8082                	ret

0000000080003b6a <begin_op>:
}

// 文件系统调用开始时调用
void begin_op(void)
{
    80003b6a:	1101                	addi	sp,sp,-32
    80003b6c:	ec06                	sd	ra,24(sp)
    80003b6e:	e822                	sd	s0,16(sp)
    80003b70:	e426                	sd	s1,8(sp)
    80003b72:	e04a                	sd	s2,0(sp)
    80003b74:	1000                	addi	s0,sp,32
  acquire(&log.lock);  // 获取日志锁
    80003b76:	0001c517          	auipc	a0,0x1c
    80003b7a:	dc250513          	addi	a0,a0,-574 # 8001f938 <log>
    80003b7e:	feffc0ef          	jal	ra,80000b6c <acquire>
  while(1){
    if(log.committing){
    80003b82:	0001c497          	auipc	s1,0x1c
    80003b86:	db648493          	addi	s1,s1,-586 # 8001f938 <log>
      // 如果日志正在提交，进入睡眠
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGBLOCKS){
    80003b8a:	4979                	li	s2,30
    80003b8c:	a029                	j	80003b96 <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003b8e:	85a6                	mv	a1,s1
    80003b90:	8526                	mv	a0,s1
    80003b92:	a7afe0ef          	jal	ra,80001e0c <sleep>
    if(log.committing){
    80003b96:	509c                	lw	a5,32(s1)
    80003b98:	fbfd                	bnez	a5,80003b8e <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGBLOCKS){
    80003b9a:	4cdc                	lw	a5,28(s1)
    80003b9c:	0017871b          	addiw	a4,a5,1
    80003ba0:	0007069b          	sext.w	a3,a4
    80003ba4:	0027179b          	slliw	a5,a4,0x2
    80003ba8:	9fb9                	addw	a5,a5,a4
    80003baa:	0017979b          	slliw	a5,a5,0x1
    80003bae:	5498                	lw	a4,40(s1)
    80003bb0:	9fb9                	addw	a5,a5,a4
    80003bb2:	00f95763          	bge	s2,a5,80003bc0 <begin_op+0x56>
      // 如果当前操作可能耗尽日志空间，等待提交
      sleep(&log, &log.lock);
    80003bb6:	85a6                	mv	a1,s1
    80003bb8:	8526                	mv	a0,s1
    80003bba:	a52fe0ef          	jal	ra,80001e0c <sleep>
    80003bbe:	bfe1                	j	80003b96 <begin_op+0x2c>
    } else {
      log.outstanding += 1;  // 增加正在进行的操作计数
    80003bc0:	0001c517          	auipc	a0,0x1c
    80003bc4:	d7850513          	addi	a0,a0,-648 # 8001f938 <log>
    80003bc8:	cd54                	sw	a3,28(a0)
      release(&log.lock);  // 释放日志锁
    80003bca:	83afd0ef          	jal	ra,80000c04 <release>
      break;
    }
  }
}
    80003bce:	60e2                	ld	ra,24(sp)
    80003bd0:	6442                	ld	s0,16(sp)
    80003bd2:	64a2                	ld	s1,8(sp)
    80003bd4:	6902                	ld	s2,0(sp)
    80003bd6:	6105                	addi	sp,sp,32
    80003bd8:	8082                	ret

0000000080003bda <end_op>:

// 文件系统调用结束时调用
// 如果这是最后一个待处理的操作，则提交日志
void end_op(void)
{
    80003bda:	7139                	addi	sp,sp,-64
    80003bdc:	fc06                	sd	ra,56(sp)
    80003bde:	f822                	sd	s0,48(sp)
    80003be0:	f426                	sd	s1,40(sp)
    80003be2:	f04a                	sd	s2,32(sp)
    80003be4:	ec4e                	sd	s3,24(sp)
    80003be6:	e852                	sd	s4,16(sp)
    80003be8:	e456                	sd	s5,8(sp)
    80003bea:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);  // 获取日志锁
    80003bec:	0001c497          	auipc	s1,0x1c
    80003bf0:	d4c48493          	addi	s1,s1,-692 # 8001f938 <log>
    80003bf4:	8526                	mv	a0,s1
    80003bf6:	f77fc0ef          	jal	ra,80000b6c <acquire>
  log.outstanding -= 1;  // 减少待处理操作计数
    80003bfa:	4cdc                	lw	a5,28(s1)
    80003bfc:	37fd                	addiw	a5,a5,-1
    80003bfe:	0007891b          	sext.w	s2,a5
    80003c02:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80003c04:	509c                	lw	a5,32(s1)
    80003c06:	ef9d                	bnez	a5,80003c44 <end_op+0x6a>
    panic("log.committing");  // 不允许在提交时结束操作
  if(log.outstanding == 0){
    80003c08:	04091463          	bnez	s2,80003c50 <end_op+0x76>
    do_commit = 1;  // 如果没有待处理的操作，则标记为需要提交
    log.committing = 1;  // 标记日志为正在提交
    80003c0c:	0001c497          	auipc	s1,0x1c
    80003c10:	d2c48493          	addi	s1,s1,-724 # 8001f938 <log>
    80003c14:	4785                	li	a5,1
    80003c16:	d09c                	sw	a5,32(s1)
  } else {
    // 如果正在等待日志空间，唤醒等待的进程
    wakeup(&log);
  }
  release(&log.lock);  // 释放日志锁
    80003c18:	8526                	mv	a0,s1
    80003c1a:	febfc0ef          	jal	ra,80000c04 <release>
}

// 提交事务，将日志中的块写回磁盘并清空日志
static void commit()
{
  if (log.lh.n > 0) {
    80003c1e:	549c                	lw	a5,40(s1)
    80003c20:	04f04b63          	bgtz	a5,80003c76 <end_op+0x9c>
    acquire(&log.lock);
    80003c24:	0001c497          	auipc	s1,0x1c
    80003c28:	d1448493          	addi	s1,s1,-748 # 8001f938 <log>
    80003c2c:	8526                	mv	a0,s1
    80003c2e:	f3ffc0ef          	jal	ra,80000b6c <acquire>
    log.committing = 0;  // 提交完成，恢复日志状态
    80003c32:	0204a023          	sw	zero,32(s1)
    wakeup(&log);  // 唤醒可能在等待提交的进程
    80003c36:	8526                	mv	a0,s1
    80003c38:	a20fe0ef          	jal	ra,80001e58 <wakeup>
    release(&log.lock);  // 释放日志锁
    80003c3c:	8526                	mv	a0,s1
    80003c3e:	fc7fc0ef          	jal	ra,80000c04 <release>
}
    80003c42:	a00d                	j	80003c64 <end_op+0x8a>
    panic("log.committing");  // 不允许在提交时结束操作
    80003c44:	00004517          	auipc	a0,0x4
    80003c48:	9d450513          	addi	a0,a0,-1580 # 80007618 <syscalls+0x228>
    80003c4c:	b3ffc0ef          	jal	ra,8000078a <panic>
    wakeup(&log);
    80003c50:	0001c497          	auipc	s1,0x1c
    80003c54:	ce848493          	addi	s1,s1,-792 # 8001f938 <log>
    80003c58:	8526                	mv	a0,s1
    80003c5a:	9fefe0ef          	jal	ra,80001e58 <wakeup>
  release(&log.lock);  // 释放日志锁
    80003c5e:	8526                	mv	a0,s1
    80003c60:	fa5fc0ef          	jal	ra,80000c04 <release>
}
    80003c64:	70e2                	ld	ra,56(sp)
    80003c66:	7442                	ld	s0,48(sp)
    80003c68:	74a2                	ld	s1,40(sp)
    80003c6a:	7902                	ld	s2,32(sp)
    80003c6c:	69e2                	ld	s3,24(sp)
    80003c6e:	6a42                	ld	s4,16(sp)
    80003c70:	6aa2                	ld	s5,8(sp)
    80003c72:	6121                	addi	sp,sp,64
    80003c74:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80003c76:	0001ca97          	auipc	s5,0x1c
    80003c7a:	ceea8a93          	addi	s5,s5,-786 # 8001f964 <log+0x2c>
    struct buf *to = bread(log.dev, log.start + tail + 1);  // 读取日志块
    80003c7e:	0001ca17          	auipc	s4,0x1c
    80003c82:	cbaa0a13          	addi	s4,s4,-838 # 8001f938 <log>
    80003c86:	018a2583          	lw	a1,24(s4)
    80003c8a:	012585bb          	addw	a1,a1,s2
    80003c8e:	2585                	addiw	a1,a1,1
    80003c90:	024a2503          	lw	a0,36(s4)
    80003c94:	e47fe0ef          	jal	ra,80002ada <bread>
    80003c98:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]);  // 读取缓存块
    80003c9a:	000aa583          	lw	a1,0(s5)
    80003c9e:	024a2503          	lw	a0,36(s4)
    80003ca2:	e39fe0ef          	jal	ra,80002ada <bread>
    80003ca6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);  // 将缓存块的数据复制到日志块
    80003ca8:	40000613          	li	a2,1024
    80003cac:	05850593          	addi	a1,a0,88
    80003cb0:	05848513          	addi	a0,s1,88
    80003cb4:	fe9fc0ef          	jal	ra,80000c9c <memmove>
    bwrite(to);  // 写入日志块
    80003cb8:	8526                	mv	a0,s1
    80003cba:	ef7fe0ef          	jal	ra,80002bb0 <bwrite>
    brelse(from);  // 释放缓存块
    80003cbe:	854e                	mv	a0,s3
    80003cc0:	f23fe0ef          	jal	ra,80002be2 <brelse>
    brelse(to);  // 释放日志块
    80003cc4:	8526                	mv	a0,s1
    80003cc6:	f1dfe0ef          	jal	ra,80002be2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003cca:	2905                	addiw	s2,s2,1
    80003ccc:	0a91                	addi	s5,s5,4
    80003cce:	028a2783          	lw	a5,40(s4)
    80003cd2:	faf94ae3          	blt	s2,a5,80003c86 <end_op+0xac>
    write_log();     // 将已修改的块从缓存写入日志
    write_head();    // 写入日志头到磁盘，真正提交
    80003cd6:	cd7ff0ef          	jal	ra,800039ac <write_head>
    install_trans(0); // 将写入操作应用到实际位置
    80003cda:	4501                	li	a0,0
    80003cdc:	d3fff0ef          	jal	ra,80003a1a <install_trans>
    log.lh.n = 0;    // 清空日志中的块数量
    80003ce0:	0001c797          	auipc	a5,0x1c
    80003ce4:	c807a023          	sw	zero,-896(a5) # 8001f960 <log+0x28>
    write_head();    // 清空日志
    80003ce8:	cc5ff0ef          	jal	ra,800039ac <write_head>
    80003cec:	bf25                	j	80003c24 <end_op+0x4a>

0000000080003cee <log_write>:
//   bp = bread(...)
//   修改 bp->data[]
//   log_write(bp)
//   brelse(bp)
void log_write(struct buf *b)
{
    80003cee:	1101                	addi	sp,sp,-32
    80003cf0:	ec06                	sd	ra,24(sp)
    80003cf2:	e822                	sd	s0,16(sp)
    80003cf4:	e426                	sd	s1,8(sp)
    80003cf6:	e04a                	sd	s2,0(sp)
    80003cf8:	1000                	addi	s0,sp,32
    80003cfa:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);  // 获取日志锁
    80003cfc:	0001c917          	auipc	s2,0x1c
    80003d00:	c3c90913          	addi	s2,s2,-964 # 8001f938 <log>
    80003d04:	854a                	mv	a0,s2
    80003d06:	e67fc0ef          	jal	ra,80000b6c <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80003d0a:	02892603          	lw	a2,40(s2)
    80003d0e:	47f5                	li	a5,29
    80003d10:	04c7cc63          	blt	a5,a2,80003d68 <log_write+0x7a>
    panic("too big a transaction");  // 如果日志块数量超过最大值，出错
  if (log.outstanding < 1)
    80003d14:	0001c797          	auipc	a5,0x1c
    80003d18:	c407a783          	lw	a5,-960(a5) # 8001f954 <log+0x1c>
    80003d1c:	04f05c63          	blez	a5,80003d74 <log_write+0x86>
    panic("log_write outside of trans");  // 如果在没有事务的情况下调用，出错

  for (i = 0; i < log.lh.n; i++) {
    80003d20:	4781                	li	a5,0
    80003d22:	04c05f63          	blez	a2,80003d80 <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // 如果块已经存在于日志中，跳过
    80003d26:	44cc                	lw	a1,12(s1)
    80003d28:	0001c717          	auipc	a4,0x1c
    80003d2c:	c3c70713          	addi	a4,a4,-964 # 8001f964 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80003d30:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // 如果块已经存在于日志中，跳过
    80003d32:	4314                	lw	a3,0(a4)
    80003d34:	04b68663          	beq	a3,a1,80003d80 <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80003d38:	2785                	addiw	a5,a5,1
    80003d3a:	0711                	addi	a4,a4,4
    80003d3c:	fef61be3          	bne	a2,a5,80003d32 <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;  // 将块号记录到日志中
    80003d40:	0621                	addi	a2,a2,8
    80003d42:	060a                	slli	a2,a2,0x2
    80003d44:	0001c797          	auipc	a5,0x1c
    80003d48:	bf478793          	addi	a5,a5,-1036 # 8001f938 <log>
    80003d4c:	963e                	add	a2,a2,a5
    80003d4e:	44dc                	lw	a5,12(s1)
    80003d50:	c65c                	sw	a5,12(a2)
  if (i == log.lh.n) {  // 如果是新块，添加到日志
    bpin(b);  // 锁定块
    80003d52:	8526                	mv	a0,s1
    80003d54:	f19fe0ef          	jal	ra,80002c6c <bpin>
    log.lh.n++;  // 增加日志中的块数量
    80003d58:	0001c717          	auipc	a4,0x1c
    80003d5c:	be070713          	addi	a4,a4,-1056 # 8001f938 <log>
    80003d60:	571c                	lw	a5,40(a4)
    80003d62:	2785                	addiw	a5,a5,1
    80003d64:	d71c                	sw	a5,40(a4)
    80003d66:	a815                	j	80003d9a <log_write+0xac>
    panic("too big a transaction");  // 如果日志块数量超过最大值，出错
    80003d68:	00004517          	auipc	a0,0x4
    80003d6c:	8c050513          	addi	a0,a0,-1856 # 80007628 <syscalls+0x238>
    80003d70:	a1bfc0ef          	jal	ra,8000078a <panic>
    panic("log_write outside of trans");  // 如果在没有事务的情况下调用，出错
    80003d74:	00004517          	auipc	a0,0x4
    80003d78:	8cc50513          	addi	a0,a0,-1844 # 80007640 <syscalls+0x250>
    80003d7c:	a0ffc0ef          	jal	ra,8000078a <panic>
  log.lh.block[i] = b->blockno;  // 将块号记录到日志中
    80003d80:	00878713          	addi	a4,a5,8
    80003d84:	00271693          	slli	a3,a4,0x2
    80003d88:	0001c717          	auipc	a4,0x1c
    80003d8c:	bb070713          	addi	a4,a4,-1104 # 8001f938 <log>
    80003d90:	9736                	add	a4,a4,a3
    80003d92:	44d4                	lw	a3,12(s1)
    80003d94:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // 如果是新块，添加到日志
    80003d96:	faf60ee3          	beq	a2,a5,80003d52 <log_write+0x64>
  }
  release(&log.lock);  // 释放日志锁
    80003d9a:	0001c517          	auipc	a0,0x1c
    80003d9e:	b9e50513          	addi	a0,a0,-1122 # 8001f938 <log>
    80003da2:	e63fc0ef          	jal	ra,80000c04 <release>
}
    80003da6:	60e2                	ld	ra,24(sp)
    80003da8:	6442                	ld	s0,16(sp)
    80003daa:	64a2                	ld	s1,8(sp)
    80003dac:	6902                	ld	s2,0(sp)
    80003dae:	6105                	addi	sp,sp,32
    80003db0:	8082                	ret

0000000080003db2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80003db2:	1101                	addi	sp,sp,-32
    80003db4:	ec06                	sd	ra,24(sp)
    80003db6:	e822                	sd	s0,16(sp)
    80003db8:	e426                	sd	s1,8(sp)
    80003dba:	e04a                	sd	s2,0(sp)
    80003dbc:	1000                	addi	s0,sp,32
    80003dbe:	84aa                	mv	s1,a0
    80003dc0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80003dc2:	00004597          	auipc	a1,0x4
    80003dc6:	89e58593          	addi	a1,a1,-1890 # 80007660 <syscalls+0x270>
    80003dca:	0521                	addi	a0,a0,8
    80003dcc:	d21fc0ef          	jal	ra,80000aec <initlock>
  lk->name = name;
    80003dd0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80003dd4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003dd8:	0204a423          	sw	zero,40(s1)
}
    80003ddc:	60e2                	ld	ra,24(sp)
    80003dde:	6442                	ld	s0,16(sp)
    80003de0:	64a2                	ld	s1,8(sp)
    80003de2:	6902                	ld	s2,0(sp)
    80003de4:	6105                	addi	sp,sp,32
    80003de6:	8082                	ret

0000000080003de8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80003de8:	1101                	addi	sp,sp,-32
    80003dea:	ec06                	sd	ra,24(sp)
    80003dec:	e822                	sd	s0,16(sp)
    80003dee:	e426                	sd	s1,8(sp)
    80003df0:	e04a                	sd	s2,0(sp)
    80003df2:	1000                	addi	s0,sp,32
    80003df4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003df6:	00850913          	addi	s2,a0,8
    80003dfa:	854a                	mv	a0,s2
    80003dfc:	d71fc0ef          	jal	ra,80000b6c <acquire>
  while (lk->locked) {
    80003e00:	409c                	lw	a5,0(s1)
    80003e02:	c799                	beqz	a5,80003e10 <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80003e04:	85ca                	mv	a1,s2
    80003e06:	8526                	mv	a0,s1
    80003e08:	804fe0ef          	jal	ra,80001e0c <sleep>
  while (lk->locked) {
    80003e0c:	409c                	lw	a5,0(s1)
    80003e0e:	fbfd                	bnez	a5,80003e04 <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80003e10:	4785                	li	a5,1
    80003e12:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80003e14:	9f1fd0ef          	jal	ra,80001804 <myproc>
    80003e18:	591c                	lw	a5,48(a0)
    80003e1a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80003e1c:	854a                	mv	a0,s2
    80003e1e:	de7fc0ef          	jal	ra,80000c04 <release>
}
    80003e22:	60e2                	ld	ra,24(sp)
    80003e24:	6442                	ld	s0,16(sp)
    80003e26:	64a2                	ld	s1,8(sp)
    80003e28:	6902                	ld	s2,0(sp)
    80003e2a:	6105                	addi	sp,sp,32
    80003e2c:	8082                	ret

0000000080003e2e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80003e2e:	1101                	addi	sp,sp,-32
    80003e30:	ec06                	sd	ra,24(sp)
    80003e32:	e822                	sd	s0,16(sp)
    80003e34:	e426                	sd	s1,8(sp)
    80003e36:	e04a                	sd	s2,0(sp)
    80003e38:	1000                	addi	s0,sp,32
    80003e3a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003e3c:	00850913          	addi	s2,a0,8
    80003e40:	854a                	mv	a0,s2
    80003e42:	d2bfc0ef          	jal	ra,80000b6c <acquire>
  lk->locked = 0;
    80003e46:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003e4a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80003e4e:	8526                	mv	a0,s1
    80003e50:	808fe0ef          	jal	ra,80001e58 <wakeup>
  release(&lk->lk);
    80003e54:	854a                	mv	a0,s2
    80003e56:	daffc0ef          	jal	ra,80000c04 <release>
}
    80003e5a:	60e2                	ld	ra,24(sp)
    80003e5c:	6442                	ld	s0,16(sp)
    80003e5e:	64a2                	ld	s1,8(sp)
    80003e60:	6902                	ld	s2,0(sp)
    80003e62:	6105                	addi	sp,sp,32
    80003e64:	8082                	ret

0000000080003e66 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80003e66:	7179                	addi	sp,sp,-48
    80003e68:	f406                	sd	ra,40(sp)
    80003e6a:	f022                	sd	s0,32(sp)
    80003e6c:	ec26                	sd	s1,24(sp)
    80003e6e:	e84a                	sd	s2,16(sp)
    80003e70:	e44e                	sd	s3,8(sp)
    80003e72:	1800                	addi	s0,sp,48
    80003e74:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80003e76:	00850913          	addi	s2,a0,8
    80003e7a:	854a                	mv	a0,s2
    80003e7c:	cf1fc0ef          	jal	ra,80000b6c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80003e80:	409c                	lw	a5,0(s1)
    80003e82:	ef89                	bnez	a5,80003e9c <holdingsleep+0x36>
    80003e84:	4481                	li	s1,0
  release(&lk->lk);
    80003e86:	854a                	mv	a0,s2
    80003e88:	d7dfc0ef          	jal	ra,80000c04 <release>
  return r;
}
    80003e8c:	8526                	mv	a0,s1
    80003e8e:	70a2                	ld	ra,40(sp)
    80003e90:	7402                	ld	s0,32(sp)
    80003e92:	64e2                	ld	s1,24(sp)
    80003e94:	6942                	ld	s2,16(sp)
    80003e96:	69a2                	ld	s3,8(sp)
    80003e98:	6145                	addi	sp,sp,48
    80003e9a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80003e9c:	0284a983          	lw	s3,40(s1)
    80003ea0:	965fd0ef          	jal	ra,80001804 <myproc>
    80003ea4:	5904                	lw	s1,48(a0)
    80003ea6:	413484b3          	sub	s1,s1,s3
    80003eaa:	0014b493          	seqz	s1,s1
    80003eae:	bfe1                	j	80003e86 <holdingsleep+0x20>

0000000080003eb0 <fileinit>:
} ftable;

// 文件表初始化
void
fileinit(void)
{
    80003eb0:	1141                	addi	sp,sp,-16
    80003eb2:	e406                	sd	ra,8(sp)
    80003eb4:	e022                	sd	s0,0(sp)
    80003eb6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");  // 初始化文件表的自旋锁
    80003eb8:	00003597          	auipc	a1,0x3
    80003ebc:	7b858593          	addi	a1,a1,1976 # 80007670 <syscalls+0x280>
    80003ec0:	0001c517          	auipc	a0,0x1c
    80003ec4:	bc050513          	addi	a0,a0,-1088 # 8001fa80 <ftable>
    80003ec8:	c25fc0ef          	jal	ra,80000aec <initlock>
}
    80003ecc:	60a2                	ld	ra,8(sp)
    80003ece:	6402                	ld	s0,0(sp)
    80003ed0:	0141                	addi	sp,sp,16
    80003ed2:	8082                	ret

0000000080003ed4 <filealloc>:

// 分配一个新的文件结构体
struct file*
filealloc(void)
{
    80003ed4:	1101                	addi	sp,sp,-32
    80003ed6:	ec06                	sd	ra,24(sp)
    80003ed8:	e822                	sd	s0,16(sp)
    80003eda:	e426                	sd	s1,8(sp)
    80003edc:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);  // 获取文件表锁
    80003ede:	0001c517          	auipc	a0,0x1c
    80003ee2:	ba250513          	addi	a0,a0,-1118 # 8001fa80 <ftable>
    80003ee6:	c87fc0ef          	jal	ra,80000b6c <acquire>
  // 遍历文件表，找到引用计数为 0 的文件结构体
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80003eea:	0001c497          	auipc	s1,0x1c
    80003eee:	bae48493          	addi	s1,s1,-1106 # 8001fa98 <ftable+0x18>
    80003ef2:	0001d717          	auipc	a4,0x1d
    80003ef6:	b4670713          	addi	a4,a4,-1210 # 80020a38 <disk>
    if(f->ref == 0){
    80003efa:	40dc                	lw	a5,4(s1)
    80003efc:	cf89                	beqz	a5,80003f16 <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80003efe:	02848493          	addi	s1,s1,40
    80003f02:	fee49ce3          	bne	s1,a4,80003efa <filealloc+0x26>
      f->ref = 1;  // 设置引用计数为 1
      release(&ftable.lock);  // 释放文件表锁
      return f;  // 返回分配的文件结构体
    }
  }
  release(&ftable.lock);  // 如果没有空闲文件结构体，释放锁
    80003f06:	0001c517          	auipc	a0,0x1c
    80003f0a:	b7a50513          	addi	a0,a0,-1158 # 8001fa80 <ftable>
    80003f0e:	cf7fc0ef          	jal	ra,80000c04 <release>
  return 0;  // 没有可用的文件结构体
    80003f12:	4481                	li	s1,0
    80003f14:	a809                	j	80003f26 <filealloc+0x52>
      f->ref = 1;  // 设置引用计数为 1
    80003f16:	4785                	li	a5,1
    80003f18:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);  // 释放文件表锁
    80003f1a:	0001c517          	auipc	a0,0x1c
    80003f1e:	b6650513          	addi	a0,a0,-1178 # 8001fa80 <ftable>
    80003f22:	ce3fc0ef          	jal	ra,80000c04 <release>
}
    80003f26:	8526                	mv	a0,s1
    80003f28:	60e2                	ld	ra,24(sp)
    80003f2a:	6442                	ld	s0,16(sp)
    80003f2c:	64a2                	ld	s1,8(sp)
    80003f2e:	6105                	addi	sp,sp,32
    80003f30:	8082                	ret

0000000080003f32 <filedup>:

// 增加文件结构体的引用计数
struct file*
filedup(struct file *f)
{
    80003f32:	1101                	addi	sp,sp,-32
    80003f34:	ec06                	sd	ra,24(sp)
    80003f36:	e822                	sd	s0,16(sp)
    80003f38:	e426                	sd	s1,8(sp)
    80003f3a:	1000                	addi	s0,sp,32
    80003f3c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);  // 获取文件表锁
    80003f3e:	0001c517          	auipc	a0,0x1c
    80003f42:	b4250513          	addi	a0,a0,-1214 # 8001fa80 <ftable>
    80003f46:	c27fc0ef          	jal	ra,80000b6c <acquire>
  if(f->ref < 1)  // 如果引用计数小于 1，说明文件结构体无效
    80003f4a:	40dc                	lw	a5,4(s1)
    80003f4c:	02f05063          	blez	a5,80003f6c <filedup+0x3a>
    panic("filedup");
  f->ref++;  // 增加引用计数
    80003f50:	2785                	addiw	a5,a5,1
    80003f52:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);  // 释放文件表锁
    80003f54:	0001c517          	auipc	a0,0x1c
    80003f58:	b2c50513          	addi	a0,a0,-1236 # 8001fa80 <ftable>
    80003f5c:	ca9fc0ef          	jal	ra,80000c04 <release>
  return f;  // 返回文件结构体
}
    80003f60:	8526                	mv	a0,s1
    80003f62:	60e2                	ld	ra,24(sp)
    80003f64:	6442                	ld	s0,16(sp)
    80003f66:	64a2                	ld	s1,8(sp)
    80003f68:	6105                	addi	sp,sp,32
    80003f6a:	8082                	ret
    panic("filedup");
    80003f6c:	00003517          	auipc	a0,0x3
    80003f70:	70c50513          	addi	a0,a0,1804 # 80007678 <syscalls+0x288>
    80003f74:	817fc0ef          	jal	ra,8000078a <panic>

0000000080003f78 <fileclose>:

// 关闭文件结构体 f，减少引用计数，当引用计数为 0 时关闭文件
void
fileclose(struct file *f)
{
    80003f78:	7139                	addi	sp,sp,-64
    80003f7a:	fc06                	sd	ra,56(sp)
    80003f7c:	f822                	sd	s0,48(sp)
    80003f7e:	f426                	sd	s1,40(sp)
    80003f80:	f04a                	sd	s2,32(sp)
    80003f82:	ec4e                	sd	s3,24(sp)
    80003f84:	e852                	sd	s4,16(sp)
    80003f86:	e456                	sd	s5,8(sp)
    80003f88:	0080                	addi	s0,sp,64
    80003f8a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);  // 获取文件表锁
    80003f8c:	0001c517          	auipc	a0,0x1c
    80003f90:	af450513          	addi	a0,a0,-1292 # 8001fa80 <ftable>
    80003f94:	bd9fc0ef          	jal	ra,80000b6c <acquire>
  if(f->ref < 1)  // 如果引用计数小于 1，说明文件结构体无效
    80003f98:	40dc                	lw	a5,4(s1)
    80003f9a:	04f05963          	blez	a5,80003fec <fileclose+0x74>
    panic("fileclose");
  if(--f->ref > 0){  // 如果引用计数大于 0，直接返回
    80003f9e:	37fd                	addiw	a5,a5,-1
    80003fa0:	0007871b          	sext.w	a4,a5
    80003fa4:	c0dc                	sw	a5,4(s1)
    80003fa6:	04e04963          	bgtz	a4,80003ff8 <fileclose+0x80>
    release(&ftable.lock);
    return;
  }
  ff = *f;  // 备份文件结构体
    80003faa:	0004a903          	lw	s2,0(s1)
    80003fae:	0094ca83          	lbu	s5,9(s1)
    80003fb2:	0104ba03          	ld	s4,16(s1)
    80003fb6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;  // 重置引用计数
    80003fba:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;  // 重置文件类型
    80003fbe:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);  // 释放文件表锁
    80003fc2:	0001c517          	auipc	a0,0x1c
    80003fc6:	abe50513          	addi	a0,a0,-1346 # 8001fa80 <ftable>
    80003fca:	c3bfc0ef          	jal	ra,80000c04 <release>

  // 如果文件类型是管道（pipe），则关闭管道
  if(ff.type == FD_PIPE){
    80003fce:	4785                	li	a5,1
    80003fd0:	04f90363          	beq	s2,a5,80004016 <fileclose+0x9e>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80003fd4:	3979                	addiw	s2,s2,-2
    80003fd6:	4785                	li	a5,1
    80003fd8:	0327e663          	bltu	a5,s2,80004004 <fileclose+0x8c>
    begin_op();  // 开始一个文件系统操作
    80003fdc:	b8fff0ef          	jal	ra,80003b6a <begin_op>
    iput(ff.ip);  // 释放 inode
    80003fe0:	854e                	mv	a0,s3
    80003fe2:	b28ff0ef          	jal	ra,8000330a <iput>
    end_op();  // 结束文件系统操作
    80003fe6:	bf5ff0ef          	jal	ra,80003bda <end_op>
    80003fea:	a829                	j	80004004 <fileclose+0x8c>
    panic("fileclose");
    80003fec:	00003517          	auipc	a0,0x3
    80003ff0:	69450513          	addi	a0,a0,1684 # 80007680 <syscalls+0x290>
    80003ff4:	f96fc0ef          	jal	ra,8000078a <panic>
    release(&ftable.lock);
    80003ff8:	0001c517          	auipc	a0,0x1c
    80003ffc:	a8850513          	addi	a0,a0,-1400 # 8001fa80 <ftable>
    80004000:	c05fc0ef          	jal	ra,80000c04 <release>
  }
}
    80004004:	70e2                	ld	ra,56(sp)
    80004006:	7442                	ld	s0,48(sp)
    80004008:	74a2                	ld	s1,40(sp)
    8000400a:	7902                	ld	s2,32(sp)
    8000400c:	69e2                	ld	s3,24(sp)
    8000400e:	6a42                	ld	s4,16(sp)
    80004010:	6aa2                	ld	s5,8(sp)
    80004012:	6121                	addi	sp,sp,64
    80004014:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004016:	85d6                	mv	a1,s5
    80004018:	8552                	mv	a0,s4
    8000401a:	2ec000ef          	jal	ra,80004306 <pipeclose>
    8000401e:	b7dd                	j	80004004 <fileclose+0x8c>

0000000080004020 <filestat>:

// 获取文件 f 的元数据（如文件大小、类型等）
// addr 是一个用户虚拟地址，指向 struct stat 结构
int
filestat(struct file *f, uint64 addr)
{
    80004020:	715d                	addi	sp,sp,-80
    80004022:	e486                	sd	ra,72(sp)
    80004024:	e0a2                	sd	s0,64(sp)
    80004026:	fc26                	sd	s1,56(sp)
    80004028:	f84a                	sd	s2,48(sp)
    8000402a:	f44e                	sd	s3,40(sp)
    8000402c:	0880                	addi	s0,sp,80
    8000402e:	84aa                	mv	s1,a0
    80004030:	89ae                	mv	s3,a1
  struct proc *p = myproc();  // 获取当前进程
    80004032:	fd2fd0ef          	jal	ra,80001804 <myproc>
  struct stat st;
  
  // 如果文件是 inode 类型或设备类型
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004036:	409c                	lw	a5,0(s1)
    80004038:	37f9                	addiw	a5,a5,-2
    8000403a:	4705                	li	a4,1
    8000403c:	02f76f63          	bltu	a4,a5,8000407a <filestat+0x5a>
    80004040:	892a                	mv	s2,a0
    ilock(f->ip);  // 锁定 inode
    80004042:	6c88                	ld	a0,24(s1)
    80004044:	948ff0ef          	jal	ra,8000318c <ilock>
    stati(f->ip, &st);  // 获取 inode 的元数据
    80004048:	fb840593          	addi	a1,s0,-72
    8000404c:	6c88                	ld	a0,24(s1)
    8000404e:	ca0ff0ef          	jal	ra,800034ee <stati>
    iunlock(f->ip);  // 解锁 inode
    80004052:	6c88                	ld	a0,24(s1)
    80004054:	9e2ff0ef          	jal	ra,80003236 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)  // 将元数据复制到用户地址
    80004058:	46e1                	li	a3,24
    8000405a:	fb840613          	addi	a2,s0,-72
    8000405e:	85ce                	mv	a1,s3
    80004060:	05093503          	ld	a0,80(s2)
    80004064:	ceefd0ef          	jal	ra,80001552 <copyout>
    80004068:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;  // 其他类型文件不支持
}
    8000406c:	60a6                	ld	ra,72(sp)
    8000406e:	6406                	ld	s0,64(sp)
    80004070:	74e2                	ld	s1,56(sp)
    80004072:	7942                	ld	s2,48(sp)
    80004074:	79a2                	ld	s3,40(sp)
    80004076:	6161                	addi	sp,sp,80
    80004078:	8082                	ret
  return -1;  // 其他类型文件不支持
    8000407a:	557d                	li	a0,-1
    8000407c:	bfc5                	j	8000406c <filestat+0x4c>

000000008000407e <fileread>:

// 从文件 f 中读取数据。
// addr 是一个用户虚拟地址。
int
fileread(struct file *f, uint64 addr, int n)
{
    8000407e:	7179                	addi	sp,sp,-48
    80004080:	f406                	sd	ra,40(sp)
    80004082:	f022                	sd	s0,32(sp)
    80004084:	ec26                	sd	s1,24(sp)
    80004086:	e84a                	sd	s2,16(sp)
    80004088:	e44e                	sd	s3,8(sp)
    8000408a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)  // 如果文件不可读，返回 -1
    8000408c:	00854783          	lbu	a5,8(a0)
    80004090:	cbc1                	beqz	a5,80004120 <fileread+0xa2>
    80004092:	84aa                	mv	s1,a0
    80004094:	89ae                	mv	s3,a1
    80004096:	8932                	mv	s2,a2
    return -1;

  // 根据文件类型执行不同的读取操作
  if(f->type == FD_PIPE){
    80004098:	411c                	lw	a5,0(a0)
    8000409a:	4705                	li	a4,1
    8000409c:	04e78363          	beq	a5,a4,800040e2 <fileread+0x64>
    r = piperead(f->pipe, addr, n);  // 从管道中读取
  } else if(f->type == FD_DEVICE){
    800040a0:	470d                	li	a4,3
    800040a2:	04e78563          	beq	a5,a4,800040ec <fileread+0x6e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)  // 如果设备不支持读取，返回 -1
      return -1;
    r = devsw[f->major].read(1, addr, n);  // 调用设备的读取函数
  } else if(f->type == FD_INODE){
    800040a6:	4709                	li	a4,2
    800040a8:	06e79663          	bne	a5,a4,80004114 <fileread+0x96>
    ilock(f->ip);  // 锁定 inode
    800040ac:	6d08                	ld	a0,24(a0)
    800040ae:	8deff0ef          	jal	ra,8000318c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)  // 从 inode 中读取数据
    800040b2:	874a                	mv	a4,s2
    800040b4:	5094                	lw	a3,32(s1)
    800040b6:	864e                	mv	a2,s3
    800040b8:	4585                	li	a1,1
    800040ba:	6c88                	ld	a0,24(s1)
    800040bc:	c5cff0ef          	jal	ra,80003518 <readi>
    800040c0:	892a                	mv	s2,a0
    800040c2:	00a05563          	blez	a0,800040cc <fileread+0x4e>
      f->off += r;  // 更新文件偏移量
    800040c6:	509c                	lw	a5,32(s1)
    800040c8:	9fa9                	addw	a5,a5,a0
    800040ca:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);  // 解锁 inode
    800040cc:	6c88                	ld	a0,24(s1)
    800040ce:	968ff0ef          	jal	ra,80003236 <iunlock>
  } else {
    panic("fileread");  // 不支持的文件类型
  }

  return r;  // 返回读取的字节数
}
    800040d2:	854a                	mv	a0,s2
    800040d4:	70a2                	ld	ra,40(sp)
    800040d6:	7402                	ld	s0,32(sp)
    800040d8:	64e2                	ld	s1,24(sp)
    800040da:	6942                	ld	s2,16(sp)
    800040dc:	69a2                	ld	s3,8(sp)
    800040de:	6145                	addi	sp,sp,48
    800040e0:	8082                	ret
    r = piperead(f->pipe, addr, n);  // 从管道中读取
    800040e2:	6908                	ld	a0,16(a0)
    800040e4:	34e000ef          	jal	ra,80004432 <piperead>
    800040e8:	892a                	mv	s2,a0
    800040ea:	b7e5                	j	800040d2 <fileread+0x54>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)  // 如果设备不支持读取，返回 -1
    800040ec:	02451783          	lh	a5,36(a0)
    800040f0:	03079693          	slli	a3,a5,0x30
    800040f4:	92c1                	srli	a3,a3,0x30
    800040f6:	4725                	li	a4,9
    800040f8:	02d76663          	bltu	a4,a3,80004124 <fileread+0xa6>
    800040fc:	0792                	slli	a5,a5,0x4
    800040fe:	0001c717          	auipc	a4,0x1c
    80004102:	8e270713          	addi	a4,a4,-1822 # 8001f9e0 <devsw>
    80004106:	97ba                	add	a5,a5,a4
    80004108:	639c                	ld	a5,0(a5)
    8000410a:	cf99                	beqz	a5,80004128 <fileread+0xaa>
    r = devsw[f->major].read(1, addr, n);  // 调用设备的读取函数
    8000410c:	4505                	li	a0,1
    8000410e:	9782                	jalr	a5
    80004110:	892a                	mv	s2,a0
    80004112:	b7c1                	j	800040d2 <fileread+0x54>
    panic("fileread");  // 不支持的文件类型
    80004114:	00003517          	auipc	a0,0x3
    80004118:	57c50513          	addi	a0,a0,1404 # 80007690 <syscalls+0x2a0>
    8000411c:	e6efc0ef          	jal	ra,8000078a <panic>
    return -1;
    80004120:	597d                	li	s2,-1
    80004122:	bf45                	j	800040d2 <fileread+0x54>
      return -1;
    80004124:	597d                	li	s2,-1
    80004126:	b775                	j	800040d2 <fileread+0x54>
    80004128:	597d                	li	s2,-1
    8000412a:	b765                	j	800040d2 <fileread+0x54>

000000008000412c <filewrite>:

// 向文件 f 中写入数据。
// addr 是一个用户虚拟地址。
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000412c:	715d                	addi	sp,sp,-80
    8000412e:	e486                	sd	ra,72(sp)
    80004130:	e0a2                	sd	s0,64(sp)
    80004132:	fc26                	sd	s1,56(sp)
    80004134:	f84a                	sd	s2,48(sp)
    80004136:	f44e                	sd	s3,40(sp)
    80004138:	f052                	sd	s4,32(sp)
    8000413a:	ec56                	sd	s5,24(sp)
    8000413c:	e85a                	sd	s6,16(sp)
    8000413e:	e45e                	sd	s7,8(sp)
    80004140:	e062                	sd	s8,0(sp)
    80004142:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)  // 如果文件不可写，返回 -1
    80004144:	00954783          	lbu	a5,9(a0)
    80004148:	0e078863          	beqz	a5,80004238 <filewrite+0x10c>
    8000414c:	892a                	mv	s2,a0
    8000414e:	8aae                	mv	s5,a1
    80004150:	8a32                	mv	s4,a2
    return -1;

  // 根据文件类型执行不同的写入操作
  if(f->type == FD_PIPE){
    80004152:	411c                	lw	a5,0(a0)
    80004154:	4705                	li	a4,1
    80004156:	02e78263          	beq	a5,a4,8000417a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);  // 向管道中写入
  } else if(f->type == FD_DEVICE){
    8000415a:	470d                	li	a4,3
    8000415c:	02e78463          	beq	a5,a4,80004184 <filewrite+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)  // 如果设备不支持写入，返回 -1
      return -1;
    ret = devsw[f->major].write(1, addr, n);  // 调用设备的写入函数
  } else if(f->type == FD_INODE){
    80004160:	4709                	li	a4,2
    80004162:	0ce79563          	bne	a5,a4,8000422c <filewrite+0x100>
    // 分多次写入，以避免超过最大日志事务大小，包括 inode、间接块、分配块等
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004166:	0ac05163          	blez	a2,80004208 <filewrite+0xdc>
    int i = 0;
    8000416a:	4981                	li	s3,0
    8000416c:	6b05                	lui	s6,0x1
    8000416e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004172:	6b85                	lui	s7,0x1
    80004174:	c00b8b9b          	addiw	s7,s7,-1024
    80004178:	a041                	j	800041f8 <filewrite+0xcc>
    ret = pipewrite(f->pipe, addr, n);  // 向管道中写入
    8000417a:	6908                	ld	a0,16(a0)
    8000417c:	1e2000ef          	jal	ra,8000435e <pipewrite>
    80004180:	8a2a                	mv	s4,a0
    80004182:	a071                	j	8000420e <filewrite+0xe2>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)  // 如果设备不支持写入，返回 -1
    80004184:	02451783          	lh	a5,36(a0)
    80004188:	03079693          	slli	a3,a5,0x30
    8000418c:	92c1                	srli	a3,a3,0x30
    8000418e:	4725                	li	a4,9
    80004190:	0ad76663          	bltu	a4,a3,8000423c <filewrite+0x110>
    80004194:	0792                	slli	a5,a5,0x4
    80004196:	0001c717          	auipc	a4,0x1c
    8000419a:	84a70713          	addi	a4,a4,-1974 # 8001f9e0 <devsw>
    8000419e:	97ba                	add	a5,a5,a4
    800041a0:	679c                	ld	a5,8(a5)
    800041a2:	cfd9                	beqz	a5,80004240 <filewrite+0x114>
    ret = devsw[f->major].write(1, addr, n);  // 调用设备的写入函数
    800041a4:	4505                	li	a0,1
    800041a6:	9782                	jalr	a5
    800041a8:	8a2a                	mv	s4,a0
    800041aa:	a095                	j	8000420e <filewrite+0xe2>
    800041ac:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)  // 如果写入数据超过最大限制，分批次写入
        n1 = max;

      begin_op();  // 开始一个文件系统操作
    800041b0:	9bbff0ef          	jal	ra,80003b6a <begin_op>
      ilock(f->ip);  // 锁定 inode
    800041b4:	01893503          	ld	a0,24(s2)
    800041b8:	fd5fe0ef          	jal	ra,8000318c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800041bc:	8762                	mv	a4,s8
    800041be:	02092683          	lw	a3,32(s2)
    800041c2:	01598633          	add	a2,s3,s5
    800041c6:	4585                	li	a1,1
    800041c8:	01893503          	ld	a0,24(s2)
    800041cc:	c30ff0ef          	jal	ra,800035fc <writei>
    800041d0:	84aa                	mv	s1,a0
    800041d2:	00a05763          	blez	a0,800041e0 <filewrite+0xb4>
        f->off += r;  // 更新文件偏移量
    800041d6:	02092783          	lw	a5,32(s2)
    800041da:	9fa9                	addw	a5,a5,a0
    800041dc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);  // 解锁 inode
    800041e0:	01893503          	ld	a0,24(s2)
    800041e4:	852ff0ef          	jal	ra,80003236 <iunlock>
      end_op();  // 结束文件系统操作
    800041e8:	9f3ff0ef          	jal	ra,80003bda <end_op>

      if(r != n1){  // 如果写入不完全，退出
    800041ec:	009c1f63          	bne	s8,s1,8000420a <filewrite+0xde>
        break;
      }
      i += r;
    800041f0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800041f4:	0149db63          	bge	s3,s4,8000420a <filewrite+0xde>
      int n1 = n - i;
    800041f8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)  // 如果写入数据超过最大限制，分批次写入
    800041fc:	84be                	mv	s1,a5
    800041fe:	2781                	sext.w	a5,a5
    80004200:	fafb56e3          	bge	s6,a5,800041ac <filewrite+0x80>
    80004204:	84de                	mv	s1,s7
    80004206:	b75d                	j	800041ac <filewrite+0x80>
    int i = 0;
    80004208:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);  // 如果写入完全成功，返回写入字节数，否则返回 -1
    8000420a:	013a1f63          	bne	s4,s3,80004228 <filewrite+0xfc>
  } else {
    panic("filewrite");  // 不支持的文件类型
  }

  return ret;  // 返回写入的字节数
}
    8000420e:	8552                	mv	a0,s4
    80004210:	60a6                	ld	ra,72(sp)
    80004212:	6406                	ld	s0,64(sp)
    80004214:	74e2                	ld	s1,56(sp)
    80004216:	7942                	ld	s2,48(sp)
    80004218:	79a2                	ld	s3,40(sp)
    8000421a:	7a02                	ld	s4,32(sp)
    8000421c:	6ae2                	ld	s5,24(sp)
    8000421e:	6b42                	ld	s6,16(sp)
    80004220:	6ba2                	ld	s7,8(sp)
    80004222:	6c02                	ld	s8,0(sp)
    80004224:	6161                	addi	sp,sp,80
    80004226:	8082                	ret
    ret = (i == n ? n : -1);  // 如果写入完全成功，返回写入字节数，否则返回 -1
    80004228:	5a7d                	li	s4,-1
    8000422a:	b7d5                	j	8000420e <filewrite+0xe2>
    panic("filewrite");  // 不支持的文件类型
    8000422c:	00003517          	auipc	a0,0x3
    80004230:	47450513          	addi	a0,a0,1140 # 800076a0 <syscalls+0x2b0>
    80004234:	d56fc0ef          	jal	ra,8000078a <panic>
    return -1;
    80004238:	5a7d                	li	s4,-1
    8000423a:	bfd1                	j	8000420e <filewrite+0xe2>
      return -1;
    8000423c:	5a7d                	li	s4,-1
    8000423e:	bfc1                	j	8000420e <filewrite+0xe2>
    80004240:	5a7d                	li	s4,-1
    80004242:	b7f1                	j	8000420e <filewrite+0xe2>

0000000080004244 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004244:	7179                	addi	sp,sp,-48
    80004246:	f406                	sd	ra,40(sp)
    80004248:	f022                	sd	s0,32(sp)
    8000424a:	ec26                	sd	s1,24(sp)
    8000424c:	e84a                	sd	s2,16(sp)
    8000424e:	e44e                	sd	s3,8(sp)
    80004250:	e052                	sd	s4,0(sp)
    80004252:	1800                	addi	s0,sp,48
    80004254:	84aa                	mv	s1,a0
    80004256:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004258:	0005b023          	sd	zero,0(a1)
    8000425c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004260:	c75ff0ef          	jal	ra,80003ed4 <filealloc>
    80004264:	e088                	sd	a0,0(s1)
    80004266:	cd35                	beqz	a0,800042e2 <pipealloc+0x9e>
    80004268:	c6dff0ef          	jal	ra,80003ed4 <filealloc>
    8000426c:	00aa3023          	sd	a0,0(s4)
    80004270:	c52d                	beqz	a0,800042da <pipealloc+0x96>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004272:	82bfc0ef          	jal	ra,80000a9c <kalloc>
    80004276:	892a                	mv	s2,a0
    80004278:	cd31                	beqz	a0,800042d4 <pipealloc+0x90>
    goto bad;
  pi->readopen = 1;
    8000427a:	4985                	li	s3,1
    8000427c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004280:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004284:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004288:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000428c:	00003597          	auipc	a1,0x3
    80004290:	42458593          	addi	a1,a1,1060 # 800076b0 <syscalls+0x2c0>
    80004294:	859fc0ef          	jal	ra,80000aec <initlock>
  (*f0)->type = FD_PIPE;
    80004298:	609c                	ld	a5,0(s1)
    8000429a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000429e:	609c                	ld	a5,0(s1)
    800042a0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800042a4:	609c                	ld	a5,0(s1)
    800042a6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800042aa:	609c                	ld	a5,0(s1)
    800042ac:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800042b0:	000a3783          	ld	a5,0(s4)
    800042b4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800042b8:	000a3783          	ld	a5,0(s4)
    800042bc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800042c0:	000a3783          	ld	a5,0(s4)
    800042c4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800042c8:	000a3783          	ld	a5,0(s4)
    800042cc:	0127b823          	sd	s2,16(a5)
  return 0;
    800042d0:	4501                	li	a0,0
    800042d2:	a005                	j	800042f2 <pipealloc+0xae>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800042d4:	6088                	ld	a0,0(s1)
    800042d6:	e501                	bnez	a0,800042de <pipealloc+0x9a>
    800042d8:	a029                	j	800042e2 <pipealloc+0x9e>
    800042da:	6088                	ld	a0,0(s1)
    800042dc:	c11d                	beqz	a0,80004302 <pipealloc+0xbe>
    fileclose(*f0);
    800042de:	c9bff0ef          	jal	ra,80003f78 <fileclose>
  if(*f1)
    800042e2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800042e6:	557d                	li	a0,-1
  if(*f1)
    800042e8:	c789                	beqz	a5,800042f2 <pipealloc+0xae>
    fileclose(*f1);
    800042ea:	853e                	mv	a0,a5
    800042ec:	c8dff0ef          	jal	ra,80003f78 <fileclose>
  return -1;
    800042f0:	557d                	li	a0,-1
}
    800042f2:	70a2                	ld	ra,40(sp)
    800042f4:	7402                	ld	s0,32(sp)
    800042f6:	64e2                	ld	s1,24(sp)
    800042f8:	6942                	ld	s2,16(sp)
    800042fa:	69a2                	ld	s3,8(sp)
    800042fc:	6a02                	ld	s4,0(sp)
    800042fe:	6145                	addi	sp,sp,48
    80004300:	8082                	ret
  return -1;
    80004302:	557d                	li	a0,-1
    80004304:	b7fd                	j	800042f2 <pipealloc+0xae>

0000000080004306 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004306:	1101                	addi	sp,sp,-32
    80004308:	ec06                	sd	ra,24(sp)
    8000430a:	e822                	sd	s0,16(sp)
    8000430c:	e426                	sd	s1,8(sp)
    8000430e:	e04a                	sd	s2,0(sp)
    80004310:	1000                	addi	s0,sp,32
    80004312:	84aa                	mv	s1,a0
    80004314:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004316:	857fc0ef          	jal	ra,80000b6c <acquire>
  if(writable){
    8000431a:	02090763          	beqz	s2,80004348 <pipeclose+0x42>
    pi->writeopen = 0;
    8000431e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004322:	21848513          	addi	a0,s1,536
    80004326:	b33fd0ef          	jal	ra,80001e58 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000432a:	2204b783          	ld	a5,544(s1)
    8000432e:	e785                	bnez	a5,80004356 <pipeclose+0x50>
    release(&pi->lock);
    80004330:	8526                	mv	a0,s1
    80004332:	8d3fc0ef          	jal	ra,80000c04 <release>
    kfree((char*)pi);
    80004336:	8526                	mv	a0,s1
    80004338:	e84fc0ef          	jal	ra,800009bc <kfree>
  } else
    release(&pi->lock);
}
    8000433c:	60e2                	ld	ra,24(sp)
    8000433e:	6442                	ld	s0,16(sp)
    80004340:	64a2                	ld	s1,8(sp)
    80004342:	6902                	ld	s2,0(sp)
    80004344:	6105                	addi	sp,sp,32
    80004346:	8082                	ret
    pi->readopen = 0;
    80004348:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000434c:	21c48513          	addi	a0,s1,540
    80004350:	b09fd0ef          	jal	ra,80001e58 <wakeup>
    80004354:	bfd9                	j	8000432a <pipeclose+0x24>
    release(&pi->lock);
    80004356:	8526                	mv	a0,s1
    80004358:	8adfc0ef          	jal	ra,80000c04 <release>
}
    8000435c:	b7c5                	j	8000433c <pipeclose+0x36>

000000008000435e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000435e:	711d                	addi	sp,sp,-96
    80004360:	ec86                	sd	ra,88(sp)
    80004362:	e8a2                	sd	s0,80(sp)
    80004364:	e4a6                	sd	s1,72(sp)
    80004366:	e0ca                	sd	s2,64(sp)
    80004368:	fc4e                	sd	s3,56(sp)
    8000436a:	f852                	sd	s4,48(sp)
    8000436c:	f456                	sd	s5,40(sp)
    8000436e:	f05a                	sd	s6,32(sp)
    80004370:	ec5e                	sd	s7,24(sp)
    80004372:	e862                	sd	s8,16(sp)
    80004374:	1080                	addi	s0,sp,96
    80004376:	84aa                	mv	s1,a0
    80004378:	8aae                	mv	s5,a1
    8000437a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000437c:	c88fd0ef          	jal	ra,80001804 <myproc>
    80004380:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004382:	8526                	mv	a0,s1
    80004384:	fe8fc0ef          	jal	ra,80000b6c <acquire>
  while(i < n){
    80004388:	09405c63          	blez	s4,80004420 <pipewrite+0xc2>
  int i = 0;
    8000438c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000438e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004390:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004394:	21c48b93          	addi	s7,s1,540
    80004398:	a81d                	j	800043ce <pipewrite+0x70>
      release(&pi->lock);
    8000439a:	8526                	mv	a0,s1
    8000439c:	869fc0ef          	jal	ra,80000c04 <release>
      return -1;
    800043a0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800043a2:	854a                	mv	a0,s2
    800043a4:	60e6                	ld	ra,88(sp)
    800043a6:	6446                	ld	s0,80(sp)
    800043a8:	64a6                	ld	s1,72(sp)
    800043aa:	6906                	ld	s2,64(sp)
    800043ac:	79e2                	ld	s3,56(sp)
    800043ae:	7a42                	ld	s4,48(sp)
    800043b0:	7aa2                	ld	s5,40(sp)
    800043b2:	7b02                	ld	s6,32(sp)
    800043b4:	6be2                	ld	s7,24(sp)
    800043b6:	6c42                	ld	s8,16(sp)
    800043b8:	6125                	addi	sp,sp,96
    800043ba:	8082                	ret
      wakeup(&pi->nread);
    800043bc:	8562                	mv	a0,s8
    800043be:	a9bfd0ef          	jal	ra,80001e58 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800043c2:	85a6                	mv	a1,s1
    800043c4:	855e                	mv	a0,s7
    800043c6:	a47fd0ef          	jal	ra,80001e0c <sleep>
  while(i < n){
    800043ca:	05495c63          	bge	s2,s4,80004422 <pipewrite+0xc4>
    if(pi->readopen == 0 || killed(pr)){
    800043ce:	2204a783          	lw	a5,544(s1)
    800043d2:	d7e1                	beqz	a5,8000439a <pipewrite+0x3c>
    800043d4:	854e                	mv	a0,s3
    800043d6:	c6ffd0ef          	jal	ra,80002044 <killed>
    800043da:	f161                	bnez	a0,8000439a <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800043dc:	2184a783          	lw	a5,536(s1)
    800043e0:	21c4a703          	lw	a4,540(s1)
    800043e4:	2007879b          	addiw	a5,a5,512
    800043e8:	fcf70ae3          	beq	a4,a5,800043bc <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800043ec:	4685                	li	a3,1
    800043ee:	01590633          	add	a2,s2,s5
    800043f2:	faf40593          	addi	a1,s0,-81
    800043f6:	0509b503          	ld	a0,80(s3)
    800043fa:	a1efd0ef          	jal	ra,80001618 <copyin>
    800043fe:	03650263          	beq	a0,s6,80004422 <pipewrite+0xc4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004402:	21c4a783          	lw	a5,540(s1)
    80004406:	0017871b          	addiw	a4,a5,1
    8000440a:	20e4ae23          	sw	a4,540(s1)
    8000440e:	1ff7f793          	andi	a5,a5,511
    80004412:	97a6                	add	a5,a5,s1
    80004414:	faf44703          	lbu	a4,-81(s0)
    80004418:	00e78c23          	sb	a4,24(a5)
      i++;
    8000441c:	2905                	addiw	s2,s2,1
    8000441e:	b775                	j	800043ca <pipewrite+0x6c>
  int i = 0;
    80004420:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004422:	21848513          	addi	a0,s1,536
    80004426:	a33fd0ef          	jal	ra,80001e58 <wakeup>
  release(&pi->lock);
    8000442a:	8526                	mv	a0,s1
    8000442c:	fd8fc0ef          	jal	ra,80000c04 <release>
  return i;
    80004430:	bf8d                	j	800043a2 <pipewrite+0x44>

0000000080004432 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004432:	715d                	addi	sp,sp,-80
    80004434:	e486                	sd	ra,72(sp)
    80004436:	e0a2                	sd	s0,64(sp)
    80004438:	fc26                	sd	s1,56(sp)
    8000443a:	f84a                	sd	s2,48(sp)
    8000443c:	f44e                	sd	s3,40(sp)
    8000443e:	f052                	sd	s4,32(sp)
    80004440:	ec56                	sd	s5,24(sp)
    80004442:	e85a                	sd	s6,16(sp)
    80004444:	0880                	addi	s0,sp,80
    80004446:	84aa                	mv	s1,a0
    80004448:	892e                	mv	s2,a1
    8000444a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000444c:	bb8fd0ef          	jal	ra,80001804 <myproc>
    80004450:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004452:	8526                	mv	a0,s1
    80004454:	f18fc0ef          	jal	ra,80000b6c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004458:	2184a703          	lw	a4,536(s1)
    8000445c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004460:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004464:	02f71363          	bne	a4,a5,8000448a <piperead+0x58>
    80004468:	2244a783          	lw	a5,548(s1)
    8000446c:	cf99                	beqz	a5,8000448a <piperead+0x58>
    if(killed(pr)){
    8000446e:	8552                	mv	a0,s4
    80004470:	bd5fd0ef          	jal	ra,80002044 <killed>
    80004474:	e149                	bnez	a0,800044f6 <piperead+0xc4>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004476:	85a6                	mv	a1,s1
    80004478:	854e                	mv	a0,s3
    8000447a:	993fd0ef          	jal	ra,80001e0c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000447e:	2184a703          	lw	a4,536(s1)
    80004482:	21c4a783          	lw	a5,540(s1)
    80004486:	fef701e3          	beq	a4,a5,80004468 <piperead+0x36>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000448a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    8000448c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000448e:	05505263          	blez	s5,800044d2 <piperead+0xa0>
    if(pi->nread == pi->nwrite)
    80004492:	2184a783          	lw	a5,536(s1)
    80004496:	21c4a703          	lw	a4,540(s1)
    8000449a:	02f70c63          	beq	a4,a5,800044d2 <piperead+0xa0>
    ch = pi->data[pi->nread % PIPESIZE];
    8000449e:	1ff7f793          	andi	a5,a5,511
    800044a2:	97a6                	add	a5,a5,s1
    800044a4:	0187c783          	lbu	a5,24(a5)
    800044a8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800044ac:	4685                	li	a3,1
    800044ae:	fbf40613          	addi	a2,s0,-65
    800044b2:	85ca                	mv	a1,s2
    800044b4:	050a3503          	ld	a0,80(s4)
    800044b8:	89afd0ef          	jal	ra,80001552 <copyout>
    800044bc:	05650263          	beq	a0,s6,80004500 <piperead+0xce>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    800044c0:	2184a783          	lw	a5,536(s1)
    800044c4:	2785                	addiw	a5,a5,1
    800044c6:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800044ca:	2985                	addiw	s3,s3,1
    800044cc:	0905                	addi	s2,s2,1
    800044ce:	fd3a92e3          	bne	s5,s3,80004492 <piperead+0x60>
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800044d2:	21c48513          	addi	a0,s1,540
    800044d6:	983fd0ef          	jal	ra,80001e58 <wakeup>
  release(&pi->lock);
    800044da:	8526                	mv	a0,s1
    800044dc:	f28fc0ef          	jal	ra,80000c04 <release>
  return i;
}
    800044e0:	854e                	mv	a0,s3
    800044e2:	60a6                	ld	ra,72(sp)
    800044e4:	6406                	ld	s0,64(sp)
    800044e6:	74e2                	ld	s1,56(sp)
    800044e8:	7942                	ld	s2,48(sp)
    800044ea:	79a2                	ld	s3,40(sp)
    800044ec:	7a02                	ld	s4,32(sp)
    800044ee:	6ae2                	ld	s5,24(sp)
    800044f0:	6b42                	ld	s6,16(sp)
    800044f2:	6161                	addi	sp,sp,80
    800044f4:	8082                	ret
      release(&pi->lock);
    800044f6:	8526                	mv	a0,s1
    800044f8:	f0cfc0ef          	jal	ra,80000c04 <release>
      return -1;
    800044fc:	59fd                	li	s3,-1
    800044fe:	b7cd                	j	800044e0 <piperead+0xae>
      if(i == 0)
    80004500:	fc0999e3          	bnez	s3,800044d2 <piperead+0xa0>
        i = -1;
    80004504:	89aa                	mv	s3,a0
    80004506:	b7f1                	j	800044d2 <piperead+0xa0>

0000000080004508 <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    80004508:	1141                	addi	sp,sp,-16
    8000450a:	e422                	sd	s0,8(sp)
    8000450c:	0800                	addi	s0,sp,16
    8000450e:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004510:	8905                	andi	a0,a0,1
    80004512:	c111                	beqz	a0,80004516 <flags2perm+0xe>
      perm = PTE_X;
    80004514:	4521                	li	a0,8
    if(flags & 0x2)
    80004516:	8b89                	andi	a5,a5,2
    80004518:	c399                	beqz	a5,8000451e <flags2perm+0x16>
      perm |= PTE_W;
    8000451a:	00456513          	ori	a0,a0,4
    return perm;
}
    8000451e:	6422                	ld	s0,8(sp)
    80004520:	0141                	addi	sp,sp,16
    80004522:	8082                	ret

0000000080004524 <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    80004524:	de010113          	addi	sp,sp,-544
    80004528:	20113c23          	sd	ra,536(sp)
    8000452c:	20813823          	sd	s0,528(sp)
    80004530:	20913423          	sd	s1,520(sp)
    80004534:	21213023          	sd	s2,512(sp)
    80004538:	ffce                	sd	s3,504(sp)
    8000453a:	fbd2                	sd	s4,496(sp)
    8000453c:	f7d6                	sd	s5,488(sp)
    8000453e:	f3da                	sd	s6,480(sp)
    80004540:	efde                	sd	s7,472(sp)
    80004542:	ebe2                	sd	s8,464(sp)
    80004544:	e7e6                	sd	s9,456(sp)
    80004546:	e3ea                	sd	s10,448(sp)
    80004548:	ff6e                	sd	s11,440(sp)
    8000454a:	1400                	addi	s0,sp,544
    8000454c:	892a                	mv	s2,a0
    8000454e:	dea43423          	sd	a0,-536(s0)
    80004552:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004556:	aaefd0ef          	jal	ra,80001804 <myproc>
    8000455a:	84aa                	mv	s1,a0

  begin_op();
    8000455c:	e0eff0ef          	jal	ra,80003b6a <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    80004560:	854a                	mv	a0,s2
    80004562:	c18ff0ef          	jal	ra,8000397a <namei>
    80004566:	c13d                	beqz	a0,800045cc <kexec+0xa8>
    80004568:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000456a:	c23fe0ef          	jal	ra,8000318c <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000456e:	04000713          	li	a4,64
    80004572:	4681                	li	a3,0
    80004574:	e5040613          	addi	a2,s0,-432
    80004578:	4581                	li	a1,0
    8000457a:	8556                	mv	a0,s5
    8000457c:	f9dfe0ef          	jal	ra,80003518 <readi>
    80004580:	04000793          	li	a5,64
    80004584:	00f51a63          	bne	a0,a5,80004598 <kexec+0x74>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    80004588:	e5042703          	lw	a4,-432(s0)
    8000458c:	464c47b7          	lui	a5,0x464c4
    80004590:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004594:	04f70063          	beq	a4,a5,800045d4 <kexec+0xb0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004598:	8556                	mv	a0,s5
    8000459a:	df9fe0ef          	jal	ra,80003392 <iunlockput>
    end_op();
    8000459e:	e3cff0ef          	jal	ra,80003bda <end_op>
  }
  return -1;
    800045a2:	557d                	li	a0,-1
}
    800045a4:	21813083          	ld	ra,536(sp)
    800045a8:	21013403          	ld	s0,528(sp)
    800045ac:	20813483          	ld	s1,520(sp)
    800045b0:	20013903          	ld	s2,512(sp)
    800045b4:	79fe                	ld	s3,504(sp)
    800045b6:	7a5e                	ld	s4,496(sp)
    800045b8:	7abe                	ld	s5,488(sp)
    800045ba:	7b1e                	ld	s6,480(sp)
    800045bc:	6bfe                	ld	s7,472(sp)
    800045be:	6c5e                	ld	s8,464(sp)
    800045c0:	6cbe                	ld	s9,456(sp)
    800045c2:	6d1e                	ld	s10,448(sp)
    800045c4:	7dfa                	ld	s11,440(sp)
    800045c6:	22010113          	addi	sp,sp,544
    800045ca:	8082                	ret
    end_op();
    800045cc:	e0eff0ef          	jal	ra,80003bda <end_op>
    return -1;
    800045d0:	557d                	li	a0,-1
    800045d2:	bfc9                	j	800045a4 <kexec+0x80>
  if((pagetable = proc_pagetable(p)) == 0)
    800045d4:	8526                	mv	a0,s1
    800045d6:	b34fd0ef          	jal	ra,8000190a <proc_pagetable>
    800045da:	8b2a                	mv	s6,a0
    800045dc:	dd55                	beqz	a0,80004598 <kexec+0x74>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800045de:	e7042783          	lw	a5,-400(s0)
    800045e2:	e8845703          	lhu	a4,-376(s0)
    800045e6:	c325                	beqz	a4,80004646 <kexec+0x122>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800045e8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800045ea:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800045ee:	6a05                	lui	s4,0x1
    800045f0:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800045f4:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800045f8:	6d85                	lui	s11,0x1
    800045fa:	7d7d                	lui	s10,0xfffff
    800045fc:	a411                	j	80004800 <kexec+0x2dc>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800045fe:	00003517          	auipc	a0,0x3
    80004602:	0ba50513          	addi	a0,a0,186 # 800076b8 <syscalls+0x2c8>
    80004606:	984fc0ef          	jal	ra,8000078a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000460a:	874a                	mv	a4,s2
    8000460c:	009c86bb          	addw	a3,s9,s1
    80004610:	4581                	li	a1,0
    80004612:	8556                	mv	a0,s5
    80004614:	f05fe0ef          	jal	ra,80003518 <readi>
    80004618:	2501                	sext.w	a0,a0
    8000461a:	18a91263          	bne	s2,a0,8000479e <kexec+0x27a>
  for(i = 0; i < sz; i += PGSIZE){
    8000461e:	009d84bb          	addw	s1,s11,s1
    80004622:	013d09bb          	addw	s3,s10,s3
    80004626:	1b74fd63          	bgeu	s1,s7,800047e0 <kexec+0x2bc>
    pa = walkaddr(pagetable, va + i);
    8000462a:	02049593          	slli	a1,s1,0x20
    8000462e:	9181                	srli	a1,a1,0x20
    80004630:	95e2                	add	a1,a1,s8
    80004632:	855a                	mv	a0,s6
    80004634:	923fc0ef          	jal	ra,80000f56 <walkaddr>
    80004638:	862a                	mv	a2,a0
    if(pa == 0)
    8000463a:	d171                	beqz	a0,800045fe <kexec+0xda>
      n = PGSIZE;
    8000463c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000463e:	fd49f6e3          	bgeu	s3,s4,8000460a <kexec+0xe6>
      n = sz - i;
    80004642:	894e                	mv	s2,s3
    80004644:	b7d9                	j	8000460a <kexec+0xe6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004646:	4901                	li	s2,0
  iunlockput(ip);
    80004648:	8556                	mv	a0,s5
    8000464a:	d49fe0ef          	jal	ra,80003392 <iunlockput>
  end_op();
    8000464e:	d8cff0ef          	jal	ra,80003bda <end_op>
  p = myproc();
    80004652:	9b2fd0ef          	jal	ra,80001804 <myproc>
    80004656:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004658:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000465c:	6785                	lui	a5,0x1
    8000465e:	17fd                	addi	a5,a5,-1
    80004660:	993e                	add	s2,s2,a5
    80004662:	77fd                	lui	a5,0xfffff
    80004664:	00f977b3          	and	a5,s2,a5
    80004668:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    8000466c:	4691                	li	a3,4
    8000466e:	6609                	lui	a2,0x2
    80004670:	963e                	add	a2,a2,a5
    80004672:	85be                	mv	a1,a5
    80004674:	855a                	mv	a0,s6
    80004676:	babfc0ef          	jal	ra,80001220 <uvmalloc>
    8000467a:	8c2a                	mv	s8,a0
  ip = 0;
    8000467c:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    8000467e:	12050063          	beqz	a0,8000479e <kexec+0x27a>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    80004682:	75f9                	lui	a1,0xffffe
    80004684:	95aa                	add	a1,a1,a0
    80004686:	855a                	mv	a0,s6
    80004688:	d5ffc0ef          	jal	ra,800013e6 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    8000468c:	7afd                	lui	s5,0xfffff
    8000468e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004690:	df043783          	ld	a5,-528(s0)
    80004694:	6388                	ld	a0,0(a5)
    80004696:	c135                	beqz	a0,800046fa <kexec+0x1d6>
    80004698:	e9040993          	addi	s3,s0,-368
    8000469c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800046a0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800046a2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800046a4:	f14fc0ef          	jal	ra,80000db8 <strlen>
    800046a8:	0015079b          	addiw	a5,a0,1
    800046ac:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800046b0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800046b4:	11596a63          	bltu	s2,s5,800047c8 <kexec+0x2a4>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800046b8:	df043d83          	ld	s11,-528(s0)
    800046bc:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800046c0:	8552                	mv	a0,s4
    800046c2:	ef6fc0ef          	jal	ra,80000db8 <strlen>
    800046c6:	0015069b          	addiw	a3,a0,1
    800046ca:	8652                	mv	a2,s4
    800046cc:	85ca                	mv	a1,s2
    800046ce:	855a                	mv	a0,s6
    800046d0:	e83fc0ef          	jal	ra,80001552 <copyout>
    800046d4:	0e054e63          	bltz	a0,800047d0 <kexec+0x2ac>
    ustack[argc] = sp;
    800046d8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800046dc:	0485                	addi	s1,s1,1
    800046de:	008d8793          	addi	a5,s11,8
    800046e2:	def43823          	sd	a5,-528(s0)
    800046e6:	008db503          	ld	a0,8(s11)
    800046ea:	c911                	beqz	a0,800046fe <kexec+0x1da>
    if(argc >= MAXARG)
    800046ec:	09a1                	addi	s3,s3,8
    800046ee:	fb3c9be3          	bne	s9,s3,800046a4 <kexec+0x180>
  sz = sz1;
    800046f2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800046f6:	4a81                	li	s5,0
    800046f8:	a05d                	j	8000479e <kexec+0x27a>
  sp = sz;
    800046fa:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800046fc:	4481                	li	s1,0
  ustack[argc] = 0;
    800046fe:	00349793          	slli	a5,s1,0x3
    80004702:	f9040713          	addi	a4,s0,-112
    80004706:	97ba                	add	a5,a5,a4
    80004708:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffde388>
  sp -= (argc+1) * sizeof(uint64);
    8000470c:	00148693          	addi	a3,s1,1
    80004710:	068e                	slli	a3,a3,0x3
    80004712:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004716:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000471a:	01597663          	bgeu	s2,s5,80004726 <kexec+0x202>
  sz = sz1;
    8000471e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004722:	4a81                	li	s5,0
    80004724:	a8ad                	j	8000479e <kexec+0x27a>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004726:	e9040613          	addi	a2,s0,-368
    8000472a:	85ca                	mv	a1,s2
    8000472c:	855a                	mv	a0,s6
    8000472e:	e25fc0ef          	jal	ra,80001552 <copyout>
    80004732:	0a054363          	bltz	a0,800047d8 <kexec+0x2b4>
  p->trapframe->a1 = sp;
    80004736:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    8000473a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000473e:	de843783          	ld	a5,-536(s0)
    80004742:	0007c703          	lbu	a4,0(a5)
    80004746:	cf11                	beqz	a4,80004762 <kexec+0x23e>
    80004748:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000474a:	02f00693          	li	a3,47
    8000474e:	a039                	j	8000475c <kexec+0x238>
      last = s+1;
    80004750:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004754:	0785                	addi	a5,a5,1
    80004756:	fff7c703          	lbu	a4,-1(a5)
    8000475a:	c701                	beqz	a4,80004762 <kexec+0x23e>
    if(*s == '/')
    8000475c:	fed71ce3          	bne	a4,a3,80004754 <kexec+0x230>
    80004760:	bfc5                	j	80004750 <kexec+0x22c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004762:	4641                	li	a2,16
    80004764:	de843583          	ld	a1,-536(s0)
    80004768:	158b8513          	addi	a0,s7,344
    8000476c:	e1afc0ef          	jal	ra,80000d86 <safestrcpy>
  oldpagetable = p->pagetable;
    80004770:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004774:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004778:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    8000477c:	058bb783          	ld	a5,88(s7)
    80004780:	e6843703          	ld	a4,-408(s0)
    80004784:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004786:	058bb783          	ld	a5,88(s7)
    8000478a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000478e:	85ea                	mv	a1,s10
    80004790:	9fefd0ef          	jal	ra,8000198e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004794:	0004851b          	sext.w	a0,s1
    80004798:	b531                	j	800045a4 <kexec+0x80>
    8000479a:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000479e:	df843583          	ld	a1,-520(s0)
    800047a2:	855a                	mv	a0,s6
    800047a4:	9eafd0ef          	jal	ra,8000198e <proc_freepagetable>
  if(ip){
    800047a8:	de0a98e3          	bnez	s5,80004598 <kexec+0x74>
  return -1;
    800047ac:	557d                	li	a0,-1
    800047ae:	bbdd                	j	800045a4 <kexec+0x80>
    800047b0:	df243c23          	sd	s2,-520(s0)
    800047b4:	b7ed                	j	8000479e <kexec+0x27a>
    800047b6:	df243c23          	sd	s2,-520(s0)
    800047ba:	b7d5                	j	8000479e <kexec+0x27a>
    800047bc:	df243c23          	sd	s2,-520(s0)
    800047c0:	bff9                	j	8000479e <kexec+0x27a>
    800047c2:	df243c23          	sd	s2,-520(s0)
    800047c6:	bfe1                	j	8000479e <kexec+0x27a>
  sz = sz1;
    800047c8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800047cc:	4a81                	li	s5,0
    800047ce:	bfc1                	j	8000479e <kexec+0x27a>
  sz = sz1;
    800047d0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800047d4:	4a81                	li	s5,0
    800047d6:	b7e1                	j	8000479e <kexec+0x27a>
  sz = sz1;
    800047d8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800047dc:	4a81                	li	s5,0
    800047de:	b7c1                	j	8000479e <kexec+0x27a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800047e0:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800047e4:	e0843783          	ld	a5,-504(s0)
    800047e8:	0017869b          	addiw	a3,a5,1
    800047ec:	e0d43423          	sd	a3,-504(s0)
    800047f0:	e0043783          	ld	a5,-512(s0)
    800047f4:	0387879b          	addiw	a5,a5,56
    800047f8:	e8845703          	lhu	a4,-376(s0)
    800047fc:	e4e6d6e3          	bge	a3,a4,80004648 <kexec+0x124>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004800:	2781                	sext.w	a5,a5
    80004802:	e0f43023          	sd	a5,-512(s0)
    80004806:	03800713          	li	a4,56
    8000480a:	86be                	mv	a3,a5
    8000480c:	e1840613          	addi	a2,s0,-488
    80004810:	4581                	li	a1,0
    80004812:	8556                	mv	a0,s5
    80004814:	d05fe0ef          	jal	ra,80003518 <readi>
    80004818:	03800793          	li	a5,56
    8000481c:	f6f51fe3          	bne	a0,a5,8000479a <kexec+0x276>
    if(ph.type != ELF_PROG_LOAD)
    80004820:	e1842783          	lw	a5,-488(s0)
    80004824:	4705                	li	a4,1
    80004826:	fae79fe3          	bne	a5,a4,800047e4 <kexec+0x2c0>
    if(ph.memsz < ph.filesz)
    8000482a:	e4043483          	ld	s1,-448(s0)
    8000482e:	e3843783          	ld	a5,-456(s0)
    80004832:	f6f4efe3          	bltu	s1,a5,800047b0 <kexec+0x28c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004836:	e2843783          	ld	a5,-472(s0)
    8000483a:	94be                	add	s1,s1,a5
    8000483c:	f6f4ede3          	bltu	s1,a5,800047b6 <kexec+0x292>
    if(ph.vaddr % PGSIZE != 0)
    80004840:	de043703          	ld	a4,-544(s0)
    80004844:	8ff9                	and	a5,a5,a4
    80004846:	fbbd                	bnez	a5,800047bc <kexec+0x298>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004848:	e1c42503          	lw	a0,-484(s0)
    8000484c:	cbdff0ef          	jal	ra,80004508 <flags2perm>
    80004850:	86aa                	mv	a3,a0
    80004852:	8626                	mv	a2,s1
    80004854:	85ca                	mv	a1,s2
    80004856:	855a                	mv	a0,s6
    80004858:	9c9fc0ef          	jal	ra,80001220 <uvmalloc>
    8000485c:	dea43c23          	sd	a0,-520(s0)
    80004860:	d12d                	beqz	a0,800047c2 <kexec+0x29e>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004862:	e2843c03          	ld	s8,-472(s0)
    80004866:	e2042c83          	lw	s9,-480(s0)
    8000486a:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000486e:	f60b89e3          	beqz	s7,800047e0 <kexec+0x2bc>
    80004872:	89de                	mv	s3,s7
    80004874:	4481                	li	s1,0
    80004876:	bb55                	j	8000462a <kexec+0x106>

0000000080004878 <argfd>:
#include "fcntl.h"

// 获取第n个系统调用参数作为文件描述符，并返回该描述符及对应的文件结构。
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004878:	7179                	addi	sp,sp,-48
    8000487a:	f406                	sd	ra,40(sp)
    8000487c:	f022                	sd	s0,32(sp)
    8000487e:	ec26                	sd	s1,24(sp)
    80004880:	e84a                	sd	s2,16(sp)
    80004882:	1800                	addi	s0,sp,48
    80004884:	892e                	mv	s2,a1
    80004886:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);  // 获取系统调用参数中的文件描述符
    80004888:	fdc40593          	addi	a1,s0,-36
    8000488c:	f19fd0ef          	jal	ra,800027a4 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)  // 检查文件描述符的有效性
    80004890:	fdc42703          	lw	a4,-36(s0)
    80004894:	47bd                	li	a5,15
    80004896:	02e7e963          	bltu	a5,a4,800048c8 <argfd+0x50>
    8000489a:	f6bfc0ef          	jal	ra,80001804 <myproc>
    8000489e:	fdc42703          	lw	a4,-36(s0)
    800048a2:	01a70793          	addi	a5,a4,26
    800048a6:	078e                	slli	a5,a5,0x3
    800048a8:	953e                	add	a0,a0,a5
    800048aa:	611c                	ld	a5,0(a0)
    800048ac:	c385                	beqz	a5,800048cc <argfd+0x54>
    return -1;
  if(pfd)
    800048ae:	00090463          	beqz	s2,800048b6 <argfd+0x3e>
    *pfd = fd;
    800048b2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800048b6:	4501                	li	a0,0
  if(pf)
    800048b8:	c091                	beqz	s1,800048bc <argfd+0x44>
    *pf = f;
    800048ba:	e09c                	sd	a5,0(s1)
}
    800048bc:	70a2                	ld	ra,40(sp)
    800048be:	7402                	ld	s0,32(sp)
    800048c0:	64e2                	ld	s1,24(sp)
    800048c2:	6942                	ld	s2,16(sp)
    800048c4:	6145                	addi	sp,sp,48
    800048c6:	8082                	ret
    return -1;
    800048c8:	557d                	li	a0,-1
    800048ca:	bfcd                	j	800048bc <argfd+0x44>
    800048cc:	557d                	li	a0,-1
    800048ce:	b7fd                	j	800048bc <argfd+0x44>

00000000800048d0 <fdalloc>:

// 为给定文件分配一个文件描述符。
// 成功时接管调用者的文件引用。
static int
fdalloc(struct file *f)
{
    800048d0:	1101                	addi	sp,sp,-32
    800048d2:	ec06                	sd	ra,24(sp)
    800048d4:	e822                	sd	s0,16(sp)
    800048d6:	e426                	sd	s1,8(sp)
    800048d8:	1000                	addi	s0,sp,32
    800048da:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800048dc:	f29fc0ef          	jal	ra,80001804 <myproc>
    800048e0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800048e2:	0d050793          	addi	a5,a0,208
    800048e6:	4501                	li	a0,0
    800048e8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){  // 查找一个未使用的文件描述符
    800048ea:	6398                	ld	a4,0(a5)
    800048ec:	cb19                	beqz	a4,80004902 <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    800048ee:	2505                	addiw	a0,a0,1
    800048f0:	07a1                	addi	a5,a5,8
    800048f2:	fed51ce3          	bne	a0,a3,800048ea <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;  // 没有可用的文件描述符
    800048f6:	557d                	li	a0,-1
}
    800048f8:	60e2                	ld	ra,24(sp)
    800048fa:	6442                	ld	s0,16(sp)
    800048fc:	64a2                	ld	s1,8(sp)
    800048fe:	6105                	addi	sp,sp,32
    80004900:	8082                	ret
      p->ofile[fd] = f;
    80004902:	01a50793          	addi	a5,a0,26
    80004906:	078e                	slli	a5,a5,0x3
    80004908:	963e                	add	a2,a2,a5
    8000490a:	e204                	sd	s1,0(a2)
      return fd;
    8000490c:	b7f5                	j	800048f8 <fdalloc+0x28>

000000008000490e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000490e:	715d                	addi	sp,sp,-80
    80004910:	e486                	sd	ra,72(sp)
    80004912:	e0a2                	sd	s0,64(sp)
    80004914:	fc26                	sd	s1,56(sp)
    80004916:	f84a                	sd	s2,48(sp)
    80004918:	f44e                	sd	s3,40(sp)
    8000491a:	f052                	sd	s4,32(sp)
    8000491c:	ec56                	sd	s5,24(sp)
    8000491e:	e85a                	sd	s6,16(sp)
    80004920:	0880                	addi	s0,sp,80
    80004922:	8b2e                	mv	s6,a1
    80004924:	89b2                	mv	s3,a2
    80004926:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)  // 查找父目录
    80004928:	fb040593          	addi	a1,s0,-80
    8000492c:	868ff0ef          	jal	ra,80003994 <nameiparent>
    80004930:	84aa                	mv	s1,a0
    80004932:	10050b63          	beqz	a0,80004a48 <create+0x13a>
    return 0;

  ilock(dp);
    80004936:	857fe0ef          	jal	ra,8000318c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){  // 检查文件是否已存在
    8000493a:	4601                	li	a2,0
    8000493c:	fb040593          	addi	a1,s0,-80
    80004940:	8526                	mv	a0,s1
    80004942:	dd3fe0ef          	jal	ra,80003714 <dirlookup>
    80004946:	8aaa                	mv	s5,a0
    80004948:	c521                	beqz	a0,80004990 <create+0x82>
    iunlockput(dp);
    8000494a:	8526                	mv	a0,s1
    8000494c:	a47fe0ef          	jal	ra,80003392 <iunlockput>
    ilock(ip);
    80004950:	8556                	mv	a0,s5
    80004952:	83bfe0ef          	jal	ra,8000318c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004956:	000b059b          	sext.w	a1,s6
    8000495a:	4789                	li	a5,2
    8000495c:	02f59563          	bne	a1,a5,80004986 <create+0x78>
    80004960:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffde4cc>
    80004964:	37f9                	addiw	a5,a5,-2
    80004966:	17c2                	slli	a5,a5,0x30
    80004968:	93c1                	srli	a5,a5,0x30
    8000496a:	4705                	li	a4,1
    8000496c:	00f76d63          	bltu	a4,a5,80004986 <create+0x78>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004970:	8556                	mv	a0,s5
    80004972:	60a6                	ld	ra,72(sp)
    80004974:	6406                	ld	s0,64(sp)
    80004976:	74e2                	ld	s1,56(sp)
    80004978:	7942                	ld	s2,48(sp)
    8000497a:	79a2                	ld	s3,40(sp)
    8000497c:	7a02                	ld	s4,32(sp)
    8000497e:	6ae2                	ld	s5,24(sp)
    80004980:	6b42                	ld	s6,16(sp)
    80004982:	6161                	addi	sp,sp,80
    80004984:	8082                	ret
    iunlockput(ip);
    80004986:	8556                	mv	a0,s5
    80004988:	a0bfe0ef          	jal	ra,80003392 <iunlockput>
    return 0;
    8000498c:	4a81                	li	s5,0
    8000498e:	b7cd                	j	80004970 <create+0x62>
  if((ip = ialloc(dp->dev, type)) == 0){  // 分配 inode
    80004990:	85da                	mv	a1,s6
    80004992:	4088                	lw	a0,0(s1)
    80004994:	e90fe0ef          	jal	ra,80003024 <ialloc>
    80004998:	8a2a                	mv	s4,a0
    8000499a:	cd1d                	beqz	a0,800049d8 <create+0xca>
  ilock(ip);
    8000499c:	ff0fe0ef          	jal	ra,8000318c <ilock>
  ip->major = major;
    800049a0:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800049a4:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800049a8:	4905                	li	s2,1
    800049aa:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800049ae:	8552                	mv	a0,s4
    800049b0:	f2afe0ef          	jal	ra,800030da <iupdate>
  if(type == T_DIR){  // 创建 . 和 .. 目录项
    800049b4:	000b059b          	sext.w	a1,s6
    800049b8:	03258563          	beq	a1,s2,800049e2 <create+0xd4>
  if(dirlink(dp, name, ip->inum) < 0)
    800049bc:	004a2603          	lw	a2,4(s4)
    800049c0:	fb040593          	addi	a1,s0,-80
    800049c4:	8526                	mv	a0,s1
    800049c6:	f1bfe0ef          	jal	ra,800038e0 <dirlink>
    800049ca:	06054363          	bltz	a0,80004a30 <create+0x122>
  iunlockput(dp);
    800049ce:	8526                	mv	a0,s1
    800049d0:	9c3fe0ef          	jal	ra,80003392 <iunlockput>
  return ip;
    800049d4:	8ad2                	mv	s5,s4
    800049d6:	bf69                	j	80004970 <create+0x62>
    iunlockput(dp);
    800049d8:	8526                	mv	a0,s1
    800049da:	9b9fe0ef          	jal	ra,80003392 <iunlockput>
    return 0;
    800049de:	8ad2                	mv	s5,s4
    800049e0:	bf41                	j	80004970 <create+0x62>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800049e2:	004a2603          	lw	a2,4(s4)
    800049e6:	00003597          	auipc	a1,0x3
    800049ea:	cf258593          	addi	a1,a1,-782 # 800076d8 <syscalls+0x2e8>
    800049ee:	8552                	mv	a0,s4
    800049f0:	ef1fe0ef          	jal	ra,800038e0 <dirlink>
    800049f4:	02054e63          	bltz	a0,80004a30 <create+0x122>
    800049f8:	40d0                	lw	a2,4(s1)
    800049fa:	00003597          	auipc	a1,0x3
    800049fe:	ce658593          	addi	a1,a1,-794 # 800076e0 <syscalls+0x2f0>
    80004a02:	8552                	mv	a0,s4
    80004a04:	eddfe0ef          	jal	ra,800038e0 <dirlink>
    80004a08:	02054463          	bltz	a0,80004a30 <create+0x122>
  if(dirlink(dp, name, ip->inum) < 0)
    80004a0c:	004a2603          	lw	a2,4(s4)
    80004a10:	fb040593          	addi	a1,s0,-80
    80004a14:	8526                	mv	a0,s1
    80004a16:	ecbfe0ef          	jal	ra,800038e0 <dirlink>
    80004a1a:	00054b63          	bltz	a0,80004a30 <create+0x122>
    dp->nlink++;  // 更新父目录的链接计数
    80004a1e:	04a4d783          	lhu	a5,74(s1)
    80004a22:	2785                	addiw	a5,a5,1
    80004a24:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004a28:	8526                	mv	a0,s1
    80004a2a:	eb0fe0ef          	jal	ra,800030da <iupdate>
    80004a2e:	b745                	j	800049ce <create+0xc0>
  ip->nlink = 0;
    80004a30:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004a34:	8552                	mv	a0,s4
    80004a36:	ea4fe0ef          	jal	ra,800030da <iupdate>
  iunlockput(ip);
    80004a3a:	8552                	mv	a0,s4
    80004a3c:	957fe0ef          	jal	ra,80003392 <iunlockput>
  iunlockput(dp);
    80004a40:	8526                	mv	a0,s1
    80004a42:	951fe0ef          	jal	ra,80003392 <iunlockput>
  return 0;
    80004a46:	b72d                	j	80004970 <create+0x62>
    return 0;
    80004a48:	8aaa                	mv	s5,a0
    80004a4a:	b71d                	j	80004970 <create+0x62>

0000000080004a4c <sys_dup>:
{
    80004a4c:	7179                	addi	sp,sp,-48
    80004a4e:	f406                	sd	ra,40(sp)
    80004a50:	f022                	sd	s0,32(sp)
    80004a52:	ec26                	sd	s1,24(sp)
    80004a54:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004a56:	fd840613          	addi	a2,s0,-40
    80004a5a:	4581                	li	a1,0
    80004a5c:	4501                	li	a0,0
    80004a5e:	e1bff0ef          	jal	ra,80004878 <argfd>
    return -1;
    80004a62:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004a64:	00054f63          	bltz	a0,80004a82 <sys_dup+0x36>
  if((fd=fdalloc(f)) < 0)  // 为文件分配新的文件描述符
    80004a68:	fd843503          	ld	a0,-40(s0)
    80004a6c:	e65ff0ef          	jal	ra,800048d0 <fdalloc>
    80004a70:	84aa                	mv	s1,a0
    return -1;
    80004a72:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)  // 为文件分配新的文件描述符
    80004a74:	00054763          	bltz	a0,80004a82 <sys_dup+0x36>
  filedup(f);  // 增加文件引用计数
    80004a78:	fd843503          	ld	a0,-40(s0)
    80004a7c:	cb6ff0ef          	jal	ra,80003f32 <filedup>
  return fd;
    80004a80:	87a6                	mv	a5,s1
}
    80004a82:	853e                	mv	a0,a5
    80004a84:	70a2                	ld	ra,40(sp)
    80004a86:	7402                	ld	s0,32(sp)
    80004a88:	64e2                	ld	s1,24(sp)
    80004a8a:	6145                	addi	sp,sp,48
    80004a8c:	8082                	ret

0000000080004a8e <sys_read>:
{
    80004a8e:	7179                	addi	sp,sp,-48
    80004a90:	f406                	sd	ra,40(sp)
    80004a92:	f022                	sd	s0,32(sp)
    80004a94:	1800                	addi	s0,sp,48
  argaddr(1, &p);  // 获取读取数据的用户空间地址
    80004a96:	fd840593          	addi	a1,s0,-40
    80004a9a:	4505                	li	a0,1
    80004a9c:	d25fd0ef          	jal	ra,800027c0 <argaddr>
  argint(2, &n);  // 获取读取字节数
    80004aa0:	fe440593          	addi	a1,s0,-28
    80004aa4:	4509                	li	a0,2
    80004aa6:	cfffd0ef          	jal	ra,800027a4 <argint>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004aaa:	fe840613          	addi	a2,s0,-24
    80004aae:	4581                	li	a1,0
    80004ab0:	4501                	li	a0,0
    80004ab2:	dc7ff0ef          	jal	ra,80004878 <argfd>
    80004ab6:	87aa                	mv	a5,a0
    return -1;
    80004ab8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004aba:	0007ca63          	bltz	a5,80004ace <sys_read+0x40>
  return fileread(f, p, n);  // 从文件中读取数据
    80004abe:	fe442603          	lw	a2,-28(s0)
    80004ac2:	fd843583          	ld	a1,-40(s0)
    80004ac6:	fe843503          	ld	a0,-24(s0)
    80004aca:	db4ff0ef          	jal	ra,8000407e <fileread>
}
    80004ace:	70a2                	ld	ra,40(sp)
    80004ad0:	7402                	ld	s0,32(sp)
    80004ad2:	6145                	addi	sp,sp,48
    80004ad4:	8082                	ret

0000000080004ad6 <sys_write>:
{
    80004ad6:	7179                	addi	sp,sp,-48
    80004ad8:	f406                	sd	ra,40(sp)
    80004ada:	f022                	sd	s0,32(sp)
    80004adc:	1800                	addi	s0,sp,48
  argaddr(1, &p);  // 获取写入数据的用户空间地址
    80004ade:	fd840593          	addi	a1,s0,-40
    80004ae2:	4505                	li	a0,1
    80004ae4:	cddfd0ef          	jal	ra,800027c0 <argaddr>
  argint(2, &n);  // 获取写入字节数
    80004ae8:	fe440593          	addi	a1,s0,-28
    80004aec:	4509                	li	a0,2
    80004aee:	cb7fd0ef          	jal	ra,800027a4 <argint>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004af2:	fe840613          	addi	a2,s0,-24
    80004af6:	4581                	li	a1,0
    80004af8:	4501                	li	a0,0
    80004afa:	d7fff0ef          	jal	ra,80004878 <argfd>
    80004afe:	87aa                	mv	a5,a0
    return -1;
    80004b00:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004b02:	0007ca63          	bltz	a5,80004b16 <sys_write+0x40>
  return filewrite(f, p, n);  // 向文件中写入数据
    80004b06:	fe442603          	lw	a2,-28(s0)
    80004b0a:	fd843583          	ld	a1,-40(s0)
    80004b0e:	fe843503          	ld	a0,-24(s0)
    80004b12:	e1aff0ef          	jal	ra,8000412c <filewrite>
}
    80004b16:	70a2                	ld	ra,40(sp)
    80004b18:	7402                	ld	s0,32(sp)
    80004b1a:	6145                	addi	sp,sp,48
    80004b1c:	8082                	ret

0000000080004b1e <sys_close>:
{
    80004b1e:	1101                	addi	sp,sp,-32
    80004b20:	ec06                	sd	ra,24(sp)
    80004b22:	e822                	sd	s0,16(sp)
    80004b24:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)  // 获取文件描述符并返回文件结构
    80004b26:	fe040613          	addi	a2,s0,-32
    80004b2a:	fec40593          	addi	a1,s0,-20
    80004b2e:	4501                	li	a0,0
    80004b30:	d49ff0ef          	jal	ra,80004878 <argfd>
    return -1;
    80004b34:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)  // 获取文件描述符并返回文件结构
    80004b36:	02054063          	bltz	a0,80004b56 <sys_close+0x38>
  myproc()->ofile[fd] = 0;  // 关闭文件描述符
    80004b3a:	ccbfc0ef          	jal	ra,80001804 <myproc>
    80004b3e:	fec42783          	lw	a5,-20(s0)
    80004b42:	07e9                	addi	a5,a5,26
    80004b44:	078e                	slli	a5,a5,0x3
    80004b46:	97aa                	add	a5,a5,a0
    80004b48:	0007b023          	sd	zero,0(a5)
  fileclose(f);  // 关闭文件
    80004b4c:	fe043503          	ld	a0,-32(s0)
    80004b50:	c28ff0ef          	jal	ra,80003f78 <fileclose>
  return 0;
    80004b54:	4781                	li	a5,0
}
    80004b56:	853e                	mv	a0,a5
    80004b58:	60e2                	ld	ra,24(sp)
    80004b5a:	6442                	ld	s0,16(sp)
    80004b5c:	6105                	addi	sp,sp,32
    80004b5e:	8082                	ret

0000000080004b60 <sys_fstat>:
{
    80004b60:	1101                	addi	sp,sp,-32
    80004b62:	ec06                	sd	ra,24(sp)
    80004b64:	e822                	sd	s0,16(sp)
    80004b66:	1000                	addi	s0,sp,32
  argaddr(1, &st);  // 获取 stat 结构体地址
    80004b68:	fe040593          	addi	a1,s0,-32
    80004b6c:	4505                	li	a0,1
    80004b6e:	c53fd0ef          	jal	ra,800027c0 <argaddr>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004b72:	fe840613          	addi	a2,s0,-24
    80004b76:	4581                	li	a1,0
    80004b78:	4501                	li	a0,0
    80004b7a:	cffff0ef          	jal	ra,80004878 <argfd>
    80004b7e:	87aa                	mv	a5,a0
    return -1;
    80004b80:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004b82:	0007c863          	bltz	a5,80004b92 <sys_fstat+0x32>
  return filestat(f, st);  // 获取文件状态信息
    80004b86:	fe043583          	ld	a1,-32(s0)
    80004b8a:	fe843503          	ld	a0,-24(s0)
    80004b8e:	c92ff0ef          	jal	ra,80004020 <filestat>
}
    80004b92:	60e2                	ld	ra,24(sp)
    80004b94:	6442                	ld	s0,16(sp)
    80004b96:	6105                	addi	sp,sp,32
    80004b98:	8082                	ret

0000000080004b9a <sys_link>:
{
    80004b9a:	7169                	addi	sp,sp,-304
    80004b9c:	f606                	sd	ra,296(sp)
    80004b9e:	f222                	sd	s0,288(sp)
    80004ba0:	ee26                	sd	s1,280(sp)
    80004ba2:	ea4a                	sd	s2,272(sp)
    80004ba4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004ba6:	08000613          	li	a2,128
    80004baa:	ed040593          	addi	a1,s0,-304
    80004bae:	4501                	li	a0,0
    80004bb0:	c2dfd0ef          	jal	ra,800027dc <argstr>
    return -1;
    80004bb4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004bb6:	0c054663          	bltz	a0,80004c82 <sys_link+0xe8>
    80004bba:	08000613          	li	a2,128
    80004bbe:	f5040593          	addi	a1,s0,-176
    80004bc2:	4505                	li	a0,1
    80004bc4:	c19fd0ef          	jal	ra,800027dc <argstr>
    return -1;
    80004bc8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004bca:	0a054c63          	bltz	a0,80004c82 <sys_link+0xe8>
  begin_op();
    80004bce:	f9dfe0ef          	jal	ra,80003b6a <begin_op>
  if((ip = namei(old)) == 0){  // 查找 old 路径对应的 inode
    80004bd2:	ed040513          	addi	a0,s0,-304
    80004bd6:	da5fe0ef          	jal	ra,8000397a <namei>
    80004bda:	84aa                	mv	s1,a0
    80004bdc:	c525                	beqz	a0,80004c44 <sys_link+0xaa>
  ilock(ip);
    80004bde:	daefe0ef          	jal	ra,8000318c <ilock>
  if(ip->type == T_DIR){  // 如果是目录，不能创建链接
    80004be2:	04449703          	lh	a4,68(s1)
    80004be6:	4785                	li	a5,1
    80004be8:	06f70263          	beq	a4,a5,80004c4c <sys_link+0xb2>
  ip->nlink++;  // 增加链接计数
    80004bec:	04a4d783          	lhu	a5,74(s1)
    80004bf0:	2785                	addiw	a5,a5,1
    80004bf2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004bf6:	8526                	mv	a0,s1
    80004bf8:	ce2fe0ef          	jal	ra,800030da <iupdate>
  iunlock(ip);
    80004bfc:	8526                	mv	a0,s1
    80004bfe:	e38fe0ef          	jal	ra,80003236 <iunlock>
  if((dp = nameiparent(new, name)) == 0)  // 获取 new 路径的父目录
    80004c02:	fd040593          	addi	a1,s0,-48
    80004c06:	f5040513          	addi	a0,s0,-176
    80004c0a:	d8bfe0ef          	jal	ra,80003994 <nameiparent>
    80004c0e:	892a                	mv	s2,a0
    80004c10:	c921                	beqz	a0,80004c60 <sys_link+0xc6>
  ilock(dp);
    80004c12:	d7afe0ef          	jal	ra,8000318c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){  // 在父目录中创建新链接
    80004c16:	00092703          	lw	a4,0(s2)
    80004c1a:	409c                	lw	a5,0(s1)
    80004c1c:	02f71f63          	bne	a4,a5,80004c5a <sys_link+0xc0>
    80004c20:	40d0                	lw	a2,4(s1)
    80004c22:	fd040593          	addi	a1,s0,-48
    80004c26:	854a                	mv	a0,s2
    80004c28:	cb9fe0ef          	jal	ra,800038e0 <dirlink>
    80004c2c:	02054763          	bltz	a0,80004c5a <sys_link+0xc0>
  iunlockput(dp);
    80004c30:	854a                	mv	a0,s2
    80004c32:	f60fe0ef          	jal	ra,80003392 <iunlockput>
  iput(ip);
    80004c36:	8526                	mv	a0,s1
    80004c38:	ed2fe0ef          	jal	ra,8000330a <iput>
  end_op();
    80004c3c:	f9ffe0ef          	jal	ra,80003bda <end_op>
  return 0;
    80004c40:	4781                	li	a5,0
    80004c42:	a081                	j	80004c82 <sys_link+0xe8>
    end_op();
    80004c44:	f97fe0ef          	jal	ra,80003bda <end_op>
    return -1;
    80004c48:	57fd                	li	a5,-1
    80004c4a:	a825                	j	80004c82 <sys_link+0xe8>
    iunlockput(ip);
    80004c4c:	8526                	mv	a0,s1
    80004c4e:	f44fe0ef          	jal	ra,80003392 <iunlockput>
    end_op();
    80004c52:	f89fe0ef          	jal	ra,80003bda <end_op>
    return -1;
    80004c56:	57fd                	li	a5,-1
    80004c58:	a02d                	j	80004c82 <sys_link+0xe8>
    iunlockput(dp);
    80004c5a:	854a                	mv	a0,s2
    80004c5c:	f36fe0ef          	jal	ra,80003392 <iunlockput>
  ilock(ip);
    80004c60:	8526                	mv	a0,s1
    80004c62:	d2afe0ef          	jal	ra,8000318c <ilock>
  ip->nlink--;  // 发生错误，恢复链接计数
    80004c66:	04a4d783          	lhu	a5,74(s1)
    80004c6a:	37fd                	addiw	a5,a5,-1
    80004c6c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004c70:	8526                	mv	a0,s1
    80004c72:	c68fe0ef          	jal	ra,800030da <iupdate>
  iunlockput(ip);
    80004c76:	8526                	mv	a0,s1
    80004c78:	f1afe0ef          	jal	ra,80003392 <iunlockput>
  end_op();
    80004c7c:	f5ffe0ef          	jal	ra,80003bda <end_op>
  return -1;
    80004c80:	57fd                	li	a5,-1
}
    80004c82:	853e                	mv	a0,a5
    80004c84:	70b2                	ld	ra,296(sp)
    80004c86:	7412                	ld	s0,288(sp)
    80004c88:	64f2                	ld	s1,280(sp)
    80004c8a:	6952                	ld	s2,272(sp)
    80004c8c:	6155                	addi	sp,sp,304
    80004c8e:	8082                	ret

0000000080004c90 <sys_unlink>:
{
    80004c90:	7151                	addi	sp,sp,-240
    80004c92:	f586                	sd	ra,232(sp)
    80004c94:	f1a2                	sd	s0,224(sp)
    80004c96:	eda6                	sd	s1,216(sp)
    80004c98:	e9ca                	sd	s2,208(sp)
    80004c9a:	e5ce                	sd	s3,200(sp)
    80004c9c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)  // 获取路径
    80004c9e:	08000613          	li	a2,128
    80004ca2:	f3040593          	addi	a1,s0,-208
    80004ca6:	4501                	li	a0,0
    80004ca8:	b35fd0ef          	jal	ra,800027dc <argstr>
    80004cac:	12054b63          	bltz	a0,80004de2 <sys_unlink+0x152>
  begin_op();
    80004cb0:	ebbfe0ef          	jal	ra,80003b6a <begin_op>
  if((dp = nameiparent(path, name)) == 0){  // 查找路径的父目录
    80004cb4:	fb040593          	addi	a1,s0,-80
    80004cb8:	f3040513          	addi	a0,s0,-208
    80004cbc:	cd9fe0ef          	jal	ra,80003994 <nameiparent>
    80004cc0:	84aa                	mv	s1,a0
    80004cc2:	c54d                	beqz	a0,80004d6c <sys_unlink+0xdc>
  ilock(dp);
    80004cc4:	cc8fe0ef          	jal	ra,8000318c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004cc8:	00003597          	auipc	a1,0x3
    80004ccc:	a1058593          	addi	a1,a1,-1520 # 800076d8 <syscalls+0x2e8>
    80004cd0:	fb040513          	addi	a0,s0,-80
    80004cd4:	a2bfe0ef          	jal	ra,800036fe <namecmp>
    80004cd8:	10050a63          	beqz	a0,80004dec <sys_unlink+0x15c>
    80004cdc:	00003597          	auipc	a1,0x3
    80004ce0:	a0458593          	addi	a1,a1,-1532 # 800076e0 <syscalls+0x2f0>
    80004ce4:	fb040513          	addi	a0,s0,-80
    80004ce8:	a17fe0ef          	jal	ra,800036fe <namecmp>
    80004cec:	10050063          	beqz	a0,80004dec <sys_unlink+0x15c>
  if((ip = dirlookup(dp, name, &off)) == 0)  // 查找目录项
    80004cf0:	f2c40613          	addi	a2,s0,-212
    80004cf4:	fb040593          	addi	a1,s0,-80
    80004cf8:	8526                	mv	a0,s1
    80004cfa:	a1bfe0ef          	jal	ra,80003714 <dirlookup>
    80004cfe:	892a                	mv	s2,a0
    80004d00:	0e050663          	beqz	a0,80004dec <sys_unlink+0x15c>
  ilock(ip);
    80004d04:	c88fe0ef          	jal	ra,8000318c <ilock>
  if(ip->nlink < 1)
    80004d08:	04a91783          	lh	a5,74(s2)
    80004d0c:	06f05463          	blez	a5,80004d74 <sys_unlink+0xe4>
  if(ip->type == T_DIR && !isdirempty(ip)){  // 如果是非空目录，不能删除
    80004d10:	04491703          	lh	a4,68(s2)
    80004d14:	4785                	li	a5,1
    80004d16:	06f70563          	beq	a4,a5,80004d80 <sys_unlink+0xf0>
  memset(&de, 0, sizeof(de));  // 清空目录项
    80004d1a:	4641                	li	a2,16
    80004d1c:	4581                	li	a1,0
    80004d1e:	fc040513          	addi	a0,s0,-64
    80004d22:	f1ffb0ef          	jal	ra,80000c40 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))  // 删除目录项
    80004d26:	4741                	li	a4,16
    80004d28:	f2c42683          	lw	a3,-212(s0)
    80004d2c:	fc040613          	addi	a2,s0,-64
    80004d30:	4581                	li	a1,0
    80004d32:	8526                	mv	a0,s1
    80004d34:	8c9fe0ef          	jal	ra,800035fc <writei>
    80004d38:	47c1                	li	a5,16
    80004d3a:	08f51563          	bne	a0,a5,80004dc4 <sys_unlink+0x134>
  if(ip->type == T_DIR){
    80004d3e:	04491703          	lh	a4,68(s2)
    80004d42:	4785                	li	a5,1
    80004d44:	08f70663          	beq	a4,a5,80004dd0 <sys_unlink+0x140>
  iunlockput(dp);
    80004d48:	8526                	mv	a0,s1
    80004d4a:	e48fe0ef          	jal	ra,80003392 <iunlockput>
  ip->nlink--;  // 更新目标文件的链接计数
    80004d4e:	04a95783          	lhu	a5,74(s2)
    80004d52:	37fd                	addiw	a5,a5,-1
    80004d54:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80004d58:	854a                	mv	a0,s2
    80004d5a:	b80fe0ef          	jal	ra,800030da <iupdate>
  iunlockput(ip);
    80004d5e:	854a                	mv	a0,s2
    80004d60:	e32fe0ef          	jal	ra,80003392 <iunlockput>
  end_op();
    80004d64:	e77fe0ef          	jal	ra,80003bda <end_op>
  return 0;
    80004d68:	4501                	li	a0,0
    80004d6a:	a079                	j	80004df8 <sys_unlink+0x168>
    end_op();
    80004d6c:	e6ffe0ef          	jal	ra,80003bda <end_op>
    return -1;
    80004d70:	557d                	li	a0,-1
    80004d72:	a059                	j	80004df8 <sys_unlink+0x168>
    panic("unlink: nlink < 1");  // 检查链接计数
    80004d74:	00003517          	auipc	a0,0x3
    80004d78:	97450513          	addi	a0,a0,-1676 # 800076e8 <syscalls+0x2f8>
    80004d7c:	a0ffb0ef          	jal	ra,8000078a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){  // 跳过 "." 和 ".."
    80004d80:	04c92703          	lw	a4,76(s2)
    80004d84:	02000793          	li	a5,32
    80004d88:	f8e7f9e3          	bgeu	a5,a4,80004d1a <sys_unlink+0x8a>
    80004d8c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004d90:	4741                	li	a4,16
    80004d92:	86ce                	mv	a3,s3
    80004d94:	f1840613          	addi	a2,s0,-232
    80004d98:	4581                	li	a1,0
    80004d9a:	854a                	mv	a0,s2
    80004d9c:	f7cfe0ef          	jal	ra,80003518 <readi>
    80004da0:	47c1                	li	a5,16
    80004da2:	00f51b63          	bne	a0,a5,80004db8 <sys_unlink+0x128>
    if(de.inum != 0)  // 如果目录项不为空
    80004da6:	f1845783          	lhu	a5,-232(s0)
    80004daa:	ef95                	bnez	a5,80004de6 <sys_unlink+0x156>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){  // 跳过 "." 和 ".."
    80004dac:	29c1                	addiw	s3,s3,16
    80004dae:	04c92783          	lw	a5,76(s2)
    80004db2:	fcf9efe3          	bltu	s3,a5,80004d90 <sys_unlink+0x100>
    80004db6:	b795                	j	80004d1a <sys_unlink+0x8a>
      panic("isdirempty: readi");
    80004db8:	00003517          	auipc	a0,0x3
    80004dbc:	94850513          	addi	a0,a0,-1720 # 80007700 <syscalls+0x310>
    80004dc0:	9cbfb0ef          	jal	ra,8000078a <panic>
    panic("unlink: writei");
    80004dc4:	00003517          	auipc	a0,0x3
    80004dc8:	95450513          	addi	a0,a0,-1708 # 80007718 <syscalls+0x328>
    80004dcc:	9bffb0ef          	jal	ra,8000078a <panic>
    dp->nlink--;  // 更新父目录的链接计数
    80004dd0:	04a4d783          	lhu	a5,74(s1)
    80004dd4:	37fd                	addiw	a5,a5,-1
    80004dd6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004dda:	8526                	mv	a0,s1
    80004ddc:	afefe0ef          	jal	ra,800030da <iupdate>
    80004de0:	b7a5                	j	80004d48 <sys_unlink+0xb8>
    return -1;
    80004de2:	557d                	li	a0,-1
    80004de4:	a811                	j	80004df8 <sys_unlink+0x168>
    iunlockput(ip);
    80004de6:	854a                	mv	a0,s2
    80004de8:	daafe0ef          	jal	ra,80003392 <iunlockput>
  iunlockput(dp);
    80004dec:	8526                	mv	a0,s1
    80004dee:	da4fe0ef          	jal	ra,80003392 <iunlockput>
  end_op();
    80004df2:	de9fe0ef          	jal	ra,80003bda <end_op>
  return -1;
    80004df6:	557d                	li	a0,-1
}
    80004df8:	70ae                	ld	ra,232(sp)
    80004dfa:	740e                	ld	s0,224(sp)
    80004dfc:	64ee                	ld	s1,216(sp)
    80004dfe:	694e                	ld	s2,208(sp)
    80004e00:	69ae                	ld	s3,200(sp)
    80004e02:	616d                	addi	sp,sp,240
    80004e04:	8082                	ret

0000000080004e06 <sys_open>:

uint64
sys_open(void)
{
    80004e06:	7131                	addi	sp,sp,-192
    80004e08:	fd06                	sd	ra,184(sp)
    80004e0a:	f922                	sd	s0,176(sp)
    80004e0c:	f526                	sd	s1,168(sp)
    80004e0e:	f14a                	sd	s2,160(sp)
    80004e10:	ed4e                	sd	s3,152(sp)
    80004e12:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);  // 获取打开文件的模式
    80004e14:	f4c40593          	addi	a1,s0,-180
    80004e18:	4505                	li	a0,1
    80004e1a:	98bfd0ef          	jal	ra,800027a4 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)  // 获取路径
    80004e1e:	08000613          	li	a2,128
    80004e22:	f5040593          	addi	a1,s0,-176
    80004e26:	4501                	li	a0,0
    80004e28:	9b5fd0ef          	jal	ra,800027dc <argstr>
    80004e2c:	87aa                	mv	a5,a0
    return -1;
    80004e2e:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)  // 获取路径
    80004e30:	0807cd63          	bltz	a5,80004eca <sys_open+0xc4>

  begin_op();
    80004e34:	d37fe0ef          	jal	ra,80003b6a <begin_op>

  if(omode & O_CREATE){  // 如果是创建文件
    80004e38:	f4c42783          	lw	a5,-180(s0)
    80004e3c:	2007f793          	andi	a5,a5,512
    80004e40:	c3c5                	beqz	a5,80004ee0 <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    80004e42:	4681                	li	a3,0
    80004e44:	4601                	li	a2,0
    80004e46:	4589                	li	a1,2
    80004e48:	f5040513          	addi	a0,s0,-176
    80004e4c:	ac3ff0ef          	jal	ra,8000490e <create>
    80004e50:	84aa                	mv	s1,a0
    if(ip == 0){
    80004e52:	c159                	beqz	a0,80004ed8 <sys_open+0xd2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80004e54:	04449703          	lh	a4,68(s1)
    80004e58:	478d                	li	a5,3
    80004e5a:	00f71763          	bne	a4,a5,80004e68 <sys_open+0x62>
    80004e5e:	0464d703          	lhu	a4,70(s1)
    80004e62:	47a5                	li	a5,9
    80004e64:	0ae7e963          	bltu	a5,a4,80004f16 <sys_open+0x110>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){  // 分配文件描述符
    80004e68:	86cff0ef          	jal	ra,80003ed4 <filealloc>
    80004e6c:	89aa                	mv	s3,a0
    80004e6e:	0c050963          	beqz	a0,80004f40 <sys_open+0x13a>
    80004e72:	a5fff0ef          	jal	ra,800048d0 <fdalloc>
    80004e76:	892a                	mv	s2,a0
    80004e78:	0c054163          	bltz	a0,80004f3a <sys_open+0x134>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80004e7c:	04449703          	lh	a4,68(s1)
    80004e80:	478d                	li	a5,3
    80004e82:	0af70163          	beq	a4,a5,80004f24 <sys_open+0x11e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80004e86:	4789                	li	a5,2
    80004e88:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80004e8c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80004e90:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80004e94:	f4c42783          	lw	a5,-180(s0)
    80004e98:	0017c713          	xori	a4,a5,1
    80004e9c:	8b05                	andi	a4,a4,1
    80004e9e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80004ea2:	0037f713          	andi	a4,a5,3
    80004ea6:	00e03733          	snez	a4,a4
    80004eaa:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){  // 如果是 O_TRUNC 模式，截断文件
    80004eae:	4007f793          	andi	a5,a5,1024
    80004eb2:	c791                	beqz	a5,80004ebe <sys_open+0xb8>
    80004eb4:	04449703          	lh	a4,68(s1)
    80004eb8:	4789                	li	a5,2
    80004eba:	06f70c63          	beq	a4,a5,80004f32 <sys_open+0x12c>
    itrunc(ip);
  }

  iunlock(ip);
    80004ebe:	8526                	mv	a0,s1
    80004ec0:	b76fe0ef          	jal	ra,80003236 <iunlock>
  end_op();
    80004ec4:	d17fe0ef          	jal	ra,80003bda <end_op>

  return fd;
    80004ec8:	854a                	mv	a0,s2
}
    80004eca:	70ea                	ld	ra,184(sp)
    80004ecc:	744a                	ld	s0,176(sp)
    80004ece:	74aa                	ld	s1,168(sp)
    80004ed0:	790a                	ld	s2,160(sp)
    80004ed2:	69ea                	ld	s3,152(sp)
    80004ed4:	6129                	addi	sp,sp,192
    80004ed6:	8082                	ret
      end_op();
    80004ed8:	d03fe0ef          	jal	ra,80003bda <end_op>
      return -1;
    80004edc:	557d                	li	a0,-1
    80004ede:	b7f5                	j	80004eca <sys_open+0xc4>
    if((ip = namei(path)) == 0){
    80004ee0:	f5040513          	addi	a0,s0,-176
    80004ee4:	a97fe0ef          	jal	ra,8000397a <namei>
    80004ee8:	84aa                	mv	s1,a0
    80004eea:	c115                	beqz	a0,80004f0e <sys_open+0x108>
    ilock(ip);
    80004eec:	aa0fe0ef          	jal	ra,8000318c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){  // 不能用非读模式打开目录
    80004ef0:	04449703          	lh	a4,68(s1)
    80004ef4:	4785                	li	a5,1
    80004ef6:	f4f71fe3          	bne	a4,a5,80004e54 <sys_open+0x4e>
    80004efa:	f4c42783          	lw	a5,-180(s0)
    80004efe:	d7ad                	beqz	a5,80004e68 <sys_open+0x62>
      iunlockput(ip);
    80004f00:	8526                	mv	a0,s1
    80004f02:	c90fe0ef          	jal	ra,80003392 <iunlockput>
      end_op();
    80004f06:	cd5fe0ef          	jal	ra,80003bda <end_op>
      return -1;
    80004f0a:	557d                	li	a0,-1
    80004f0c:	bf7d                	j	80004eca <sys_open+0xc4>
      end_op();
    80004f0e:	ccdfe0ef          	jal	ra,80003bda <end_op>
      return -1;
    80004f12:	557d                	li	a0,-1
    80004f14:	bf5d                	j	80004eca <sys_open+0xc4>
    iunlockput(ip);
    80004f16:	8526                	mv	a0,s1
    80004f18:	c7afe0ef          	jal	ra,80003392 <iunlockput>
    end_op();
    80004f1c:	cbffe0ef          	jal	ra,80003bda <end_op>
    return -1;
    80004f20:	557d                	li	a0,-1
    80004f22:	b765                	j	80004eca <sys_open+0xc4>
    f->type = FD_DEVICE;
    80004f24:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80004f28:	04649783          	lh	a5,70(s1)
    80004f2c:	02f99223          	sh	a5,36(s3)
    80004f30:	b785                	j	80004e90 <sys_open+0x8a>
    itrunc(ip);
    80004f32:	8526                	mv	a0,s1
    80004f34:	b42fe0ef          	jal	ra,80003276 <itrunc>
    80004f38:	b759                	j	80004ebe <sys_open+0xb8>
      fileclose(f);
    80004f3a:	854e                	mv	a0,s3
    80004f3c:	83cff0ef          	jal	ra,80003f78 <fileclose>
    iunlockput(ip);
    80004f40:	8526                	mv	a0,s1
    80004f42:	c50fe0ef          	jal	ra,80003392 <iunlockput>
    end_op();
    80004f46:	c95fe0ef          	jal	ra,80003bda <end_op>
    return -1;
    80004f4a:	557d                	li	a0,-1
    80004f4c:	bfbd                	j	80004eca <sys_open+0xc4>

0000000080004f4e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80004f4e:	7175                	addi	sp,sp,-144
    80004f50:	e506                	sd	ra,136(sp)
    80004f52:	e122                	sd	s0,128(sp)
    80004f54:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80004f56:	c15fe0ef          	jal	ra,80003b6a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80004f5a:	08000613          	li	a2,128
    80004f5e:	f7040593          	addi	a1,s0,-144
    80004f62:	4501                	li	a0,0
    80004f64:	879fd0ef          	jal	ra,800027dc <argstr>
    80004f68:	02054363          	bltz	a0,80004f8e <sys_mkdir+0x40>
    80004f6c:	4681                	li	a3,0
    80004f6e:	4601                	li	a2,0
    80004f70:	4585                	li	a1,1
    80004f72:	f7040513          	addi	a0,s0,-144
    80004f76:	999ff0ef          	jal	ra,8000490e <create>
    80004f7a:	c911                	beqz	a0,80004f8e <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80004f7c:	c16fe0ef          	jal	ra,80003392 <iunlockput>
  end_op();
    80004f80:	c5bfe0ef          	jal	ra,80003bda <end_op>
  return 0;
    80004f84:	4501                	li	a0,0
}
    80004f86:	60aa                	ld	ra,136(sp)
    80004f88:	640a                	ld	s0,128(sp)
    80004f8a:	6149                	addi	sp,sp,144
    80004f8c:	8082                	ret
    end_op();
    80004f8e:	c4dfe0ef          	jal	ra,80003bda <end_op>
    return -1;
    80004f92:	557d                	li	a0,-1
    80004f94:	bfcd                	j	80004f86 <sys_mkdir+0x38>

0000000080004f96 <sys_mknod>:

uint64
sys_mknod(void)
{
    80004f96:	7135                	addi	sp,sp,-160
    80004f98:	ed06                	sd	ra,152(sp)
    80004f9a:	e922                	sd	s0,144(sp)
    80004f9c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80004f9e:	bcdfe0ef          	jal	ra,80003b6a <begin_op>
  argint(1, &major);
    80004fa2:	f6c40593          	addi	a1,s0,-148
    80004fa6:	4505                	li	a0,1
    80004fa8:	ffcfd0ef          	jal	ra,800027a4 <argint>
  argint(2, &minor);
    80004fac:	f6840593          	addi	a1,s0,-152
    80004fb0:	4509                	li	a0,2
    80004fb2:	ff2fd0ef          	jal	ra,800027a4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80004fb6:	08000613          	li	a2,128
    80004fba:	f7040593          	addi	a1,s0,-144
    80004fbe:	4501                	li	a0,0
    80004fc0:	81dfd0ef          	jal	ra,800027dc <argstr>
    80004fc4:	02054563          	bltz	a0,80004fee <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80004fc8:	f6841683          	lh	a3,-152(s0)
    80004fcc:	f6c41603          	lh	a2,-148(s0)
    80004fd0:	458d                	li	a1,3
    80004fd2:	f7040513          	addi	a0,s0,-144
    80004fd6:	939ff0ef          	jal	ra,8000490e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80004fda:	c911                	beqz	a0,80004fee <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80004fdc:	bb6fe0ef          	jal	ra,80003392 <iunlockput>
  end_op();
    80004fe0:	bfbfe0ef          	jal	ra,80003bda <end_op>
  return 0;
    80004fe4:	4501                	li	a0,0
}
    80004fe6:	60ea                	ld	ra,152(sp)
    80004fe8:	644a                	ld	s0,144(sp)
    80004fea:	610d                	addi	sp,sp,160
    80004fec:	8082                	ret
    end_op();
    80004fee:	bedfe0ef          	jal	ra,80003bda <end_op>
    return -1;
    80004ff2:	557d                	li	a0,-1
    80004ff4:	bfcd                	j	80004fe6 <sys_mknod+0x50>

0000000080004ff6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80004ff6:	7135                	addi	sp,sp,-160
    80004ff8:	ed06                	sd	ra,152(sp)
    80004ffa:	e922                	sd	s0,144(sp)
    80004ffc:	e526                	sd	s1,136(sp)
    80004ffe:	e14a                	sd	s2,128(sp)
    80005000:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005002:	803fc0ef          	jal	ra,80001804 <myproc>
    80005006:	892a                	mv	s2,a0
  
  begin_op();
    80005008:	b63fe0ef          	jal	ra,80003b6a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000500c:	08000613          	li	a2,128
    80005010:	f6040593          	addi	a1,s0,-160
    80005014:	4501                	li	a0,0
    80005016:	fc6fd0ef          	jal	ra,800027dc <argstr>
    8000501a:	04054163          	bltz	a0,8000505c <sys_chdir+0x66>
    8000501e:	f6040513          	addi	a0,s0,-160
    80005022:	959fe0ef          	jal	ra,8000397a <namei>
    80005026:	84aa                	mv	s1,a0
    80005028:	c915                	beqz	a0,8000505c <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    8000502a:	962fe0ef          	jal	ra,8000318c <ilock>
  if(ip->type != T_DIR){  // 必须是目录类型
    8000502e:	04449703          	lh	a4,68(s1)
    80005032:	4785                	li	a5,1
    80005034:	02f71863          	bne	a4,a5,80005064 <sys_chdir+0x6e>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005038:	8526                	mv	a0,s1
    8000503a:	9fcfe0ef          	jal	ra,80003236 <iunlock>
  iput(p->cwd);  // 释放当前工作目录
    8000503e:	15093503          	ld	a0,336(s2)
    80005042:	ac8fe0ef          	jal	ra,8000330a <iput>
  end_op();
    80005046:	b95fe0ef          	jal	ra,80003bda <end_op>
  p->cwd = ip;  // 更新为新的工作目录
    8000504a:	14993823          	sd	s1,336(s2)
  return 0;
    8000504e:	4501                	li	a0,0
}
    80005050:	60ea                	ld	ra,152(sp)
    80005052:	644a                	ld	s0,144(sp)
    80005054:	64aa                	ld	s1,136(sp)
    80005056:	690a                	ld	s2,128(sp)
    80005058:	610d                	addi	sp,sp,160
    8000505a:	8082                	ret
    end_op();
    8000505c:	b7ffe0ef          	jal	ra,80003bda <end_op>
    return -1;
    80005060:	557d                	li	a0,-1
    80005062:	b7fd                	j	80005050 <sys_chdir+0x5a>
    iunlockput(ip);
    80005064:	8526                	mv	a0,s1
    80005066:	b2cfe0ef          	jal	ra,80003392 <iunlockput>
    end_op();
    8000506a:	b71fe0ef          	jal	ra,80003bda <end_op>
    return -1;
    8000506e:	557d                	li	a0,-1
    80005070:	b7c5                	j	80005050 <sys_chdir+0x5a>

0000000080005072 <sys_exec>:

uint64
sys_exec(void)
{
    80005072:	7145                	addi	sp,sp,-464
    80005074:	e786                	sd	ra,456(sp)
    80005076:	e3a2                	sd	s0,448(sp)
    80005078:	ff26                	sd	s1,440(sp)
    8000507a:	fb4a                	sd	s2,432(sp)
    8000507c:	f74e                	sd	s3,424(sp)
    8000507e:	f352                	sd	s4,416(sp)
    80005080:	ef56                	sd	s5,408(sp)
    80005082:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);  // 获取参数地址
    80005084:	e3840593          	addi	a1,s0,-456
    80005088:	4505                	li	a0,1
    8000508a:	f36fd0ef          	jal	ra,800027c0 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {  // 获取程序路径
    8000508e:	08000613          	li	a2,128
    80005092:	f4040593          	addi	a1,s0,-192
    80005096:	4501                	li	a0,0
    80005098:	f44fd0ef          	jal	ra,800027dc <argstr>
    8000509c:	87aa                	mv	a5,a0
    return -1;
    8000509e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {  // 获取程序路径
    800050a0:	0a07c463          	bltz	a5,80005148 <sys_exec+0xd6>
  }
  memset(argv, 0, sizeof(argv));
    800050a4:	10000613          	li	a2,256
    800050a8:	4581                	li	a1,0
    800050aa:	e4040513          	addi	a0,s0,-448
    800050ae:	b93fb0ef          	jal	ra,80000c40 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800050b2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800050b6:	89a6                	mv	s3,s1
    800050b8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800050ba:	02000a13          	li	s4,32
    800050be:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800050c2:	00391793          	slli	a5,s2,0x3
    800050c6:	e3040593          	addi	a1,s0,-464
    800050ca:	e3843503          	ld	a0,-456(s0)
    800050ce:	953e                	add	a0,a0,a5
    800050d0:	e4afd0ef          	jal	ra,8000271a <fetchaddr>
    800050d4:	02054663          	bltz	a0,80005100 <sys_exec+0x8e>
      goto bad;
    }
    if(uarg == 0){
    800050d8:	e3043783          	ld	a5,-464(s0)
    800050dc:	cf8d                	beqz	a5,80005116 <sys_exec+0xa4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800050de:	9bffb0ef          	jal	ra,80000a9c <kalloc>
    800050e2:	85aa                	mv	a1,a0
    800050e4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800050e8:	cd01                	beqz	a0,80005100 <sys_exec+0x8e>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800050ea:	6605                	lui	a2,0x1
    800050ec:	e3043503          	ld	a0,-464(s0)
    800050f0:	e74fd0ef          	jal	ra,80002764 <fetchstr>
    800050f4:	00054663          	bltz	a0,80005100 <sys_exec+0x8e>
    if(i >= NELEM(argv)){
    800050f8:	0905                	addi	s2,s2,1
    800050fa:	09a1                	addi	s3,s3,8
    800050fc:	fd4911e3          	bne	s2,s4,800050be <sys_exec+0x4c>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005100:	10048913          	addi	s2,s1,256
    80005104:	6088                	ld	a0,0(s1)
    80005106:	c121                	beqz	a0,80005146 <sys_exec+0xd4>
    kfree(argv[i]);
    80005108:	8b5fb0ef          	jal	ra,800009bc <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000510c:	04a1                	addi	s1,s1,8
    8000510e:	ff249be3          	bne	s1,s2,80005104 <sys_exec+0x92>
  return -1;
    80005112:	557d                	li	a0,-1
    80005114:	a815                	j	80005148 <sys_exec+0xd6>
      argv[i] = 0;
    80005116:	0a8e                	slli	s5,s5,0x3
    80005118:	fc040793          	addi	a5,s0,-64
    8000511c:	9abe                	add	s5,s5,a5
    8000511e:	e80ab023          	sd	zero,-384(s5)
  int ret = kexec(path, argv);  // 执行程序
    80005122:	e4040593          	addi	a1,s0,-448
    80005126:	f4040513          	addi	a0,s0,-192
    8000512a:	bfaff0ef          	jal	ra,80004524 <kexec>
    8000512e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005130:	10048993          	addi	s3,s1,256
    80005134:	6088                	ld	a0,0(s1)
    80005136:	c511                	beqz	a0,80005142 <sys_exec+0xd0>
    kfree(argv[i]);
    80005138:	885fb0ef          	jal	ra,800009bc <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000513c:	04a1                	addi	s1,s1,8
    8000513e:	ff349be3          	bne	s1,s3,80005134 <sys_exec+0xc2>
  return ret;
    80005142:	854a                	mv	a0,s2
    80005144:	a011                	j	80005148 <sys_exec+0xd6>
  return -1;
    80005146:	557d                	li	a0,-1
}
    80005148:	60be                	ld	ra,456(sp)
    8000514a:	641e                	ld	s0,448(sp)
    8000514c:	74fa                	ld	s1,440(sp)
    8000514e:	795a                	ld	s2,432(sp)
    80005150:	79ba                	ld	s3,424(sp)
    80005152:	7a1a                	ld	s4,416(sp)
    80005154:	6afa                	ld	s5,408(sp)
    80005156:	6179                	addi	sp,sp,464
    80005158:	8082                	ret

000000008000515a <sys_pipe>:

uint64
sys_pipe(void)
{
    8000515a:	7139                	addi	sp,sp,-64
    8000515c:	fc06                	sd	ra,56(sp)
    8000515e:	f822                	sd	s0,48(sp)
    80005160:	f426                	sd	s1,40(sp)
    80005162:	0080                	addi	s0,sp,64
  uint64 fdarray; // 用户指针指向两个整数的数组
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005164:	ea0fc0ef          	jal	ra,80001804 <myproc>
    80005168:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);  // 获取文件描述符数组地址
    8000516a:	fd840593          	addi	a1,s0,-40
    8000516e:	4501                	li	a0,0
    80005170:	e50fd0ef          	jal	ra,800027c0 <argaddr>
  if(pipealloc(&rf, &wf) < 0)  // 分配管道文件
    80005174:	fc840593          	addi	a1,s0,-56
    80005178:	fd040513          	addi	a0,s0,-48
    8000517c:	8c8ff0ef          	jal	ra,80004244 <pipealloc>
    return -1;
    80005180:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)  // 分配管道文件
    80005182:	0a054463          	bltz	a0,8000522a <sys_pipe+0xd0>
  fd0 = -1;
    80005186:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){  // 分配文件描述符
    8000518a:	fd043503          	ld	a0,-48(s0)
    8000518e:	f42ff0ef          	jal	ra,800048d0 <fdalloc>
    80005192:	fca42223          	sw	a0,-60(s0)
    80005196:	08054163          	bltz	a0,80005218 <sys_pipe+0xbe>
    8000519a:	fc843503          	ld	a0,-56(s0)
    8000519e:	f32ff0ef          	jal	ra,800048d0 <fdalloc>
    800051a2:	fca42023          	sw	a0,-64(s0)
    800051a6:	06054063          	bltz	a0,80005206 <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||  // 将文件描述符写入用户空间
    800051aa:	4691                	li	a3,4
    800051ac:	fc440613          	addi	a2,s0,-60
    800051b0:	fd843583          	ld	a1,-40(s0)
    800051b4:	68a8                	ld	a0,80(s1)
    800051b6:	b9cfc0ef          	jal	ra,80001552 <copyout>
    800051ba:	00054e63          	bltz	a0,800051d6 <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800051be:	4691                	li	a3,4
    800051c0:	fc040613          	addi	a2,s0,-64
    800051c4:	fd843583          	ld	a1,-40(s0)
    800051c8:	0591                	addi	a1,a1,4
    800051ca:	68a8                	ld	a0,80(s1)
    800051cc:	b86fc0ef          	jal	ra,80001552 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800051d0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||  // 将文件描述符写入用户空间
    800051d2:	04055c63          	bgez	a0,8000522a <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    800051d6:	fc442783          	lw	a5,-60(s0)
    800051da:	07e9                	addi	a5,a5,26
    800051dc:	078e                	slli	a5,a5,0x3
    800051de:	97a6                	add	a5,a5,s1
    800051e0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800051e4:	fc042503          	lw	a0,-64(s0)
    800051e8:	0569                	addi	a0,a0,26
    800051ea:	050e                	slli	a0,a0,0x3
    800051ec:	94aa                	add	s1,s1,a0
    800051ee:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800051f2:	fd043503          	ld	a0,-48(s0)
    800051f6:	d83fe0ef          	jal	ra,80003f78 <fileclose>
    fileclose(wf);
    800051fa:	fc843503          	ld	a0,-56(s0)
    800051fe:	d7bfe0ef          	jal	ra,80003f78 <fileclose>
    return -1;
    80005202:	57fd                	li	a5,-1
    80005204:	a01d                	j	8000522a <sys_pipe+0xd0>
    if(fd0 >= 0)
    80005206:	fc442783          	lw	a5,-60(s0)
    8000520a:	0007c763          	bltz	a5,80005218 <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    8000520e:	07e9                	addi	a5,a5,26
    80005210:	078e                	slli	a5,a5,0x3
    80005212:	94be                	add	s1,s1,a5
    80005214:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005218:	fd043503          	ld	a0,-48(s0)
    8000521c:	d5dfe0ef          	jal	ra,80003f78 <fileclose>
    fileclose(wf);
    80005220:	fc843503          	ld	a0,-56(s0)
    80005224:	d55fe0ef          	jal	ra,80003f78 <fileclose>
    return -1;
    80005228:	57fd                	li	a5,-1
}
    8000522a:	853e                	mv	a0,a5
    8000522c:	70e2                	ld	ra,56(sp)
    8000522e:	7442                	ld	s0,48(sp)
    80005230:	74a2                	ld	s1,40(sp)
    80005232:	6121                	addi	sp,sp,64
    80005234:	8082                	ret
	...

0000000080005240 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    80005240:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    80005242:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    80005244:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80005246:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80005248:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000524a:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000524c:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    8000524e:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80005250:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80005252:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    80005254:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    80005256:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    80005258:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    8000525a:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    8000525c:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    8000525e:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    80005260:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    80005262:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    80005264:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    80005266:	bc4fd0ef          	jal	ra,8000262a <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    8000526a:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    8000526c:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    8000526e:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    80005270:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    80005272:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    80005274:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    80005276:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    80005278:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    8000527a:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    8000527c:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    8000527e:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    80005280:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    80005282:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    80005284:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    80005286:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80005288:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    8000528a:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    8000528c:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    8000528e:	10200073          	sret
	...

000000008000529e <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000529e:	1141                	addi	sp,sp,-16
    800052a0:	e422                	sd	s0,8(sp)
    800052a2:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800052a4:	0c0007b7          	lui	a5,0xc000
    800052a8:	4705                	li	a4,1
    800052aa:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800052ac:	c3d8                	sw	a4,4(a5)
}
    800052ae:	6422                	ld	s0,8(sp)
    800052b0:	0141                	addi	sp,sp,16
    800052b2:	8082                	ret

00000000800052b4 <plicinithart>:

void
plicinithart(void)
{
    800052b4:	1141                	addi	sp,sp,-16
    800052b6:	e406                	sd	ra,8(sp)
    800052b8:	e022                	sd	s0,0(sp)
    800052ba:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800052bc:	d1cfc0ef          	jal	ra,800017d8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800052c0:	0085171b          	slliw	a4,a0,0x8
    800052c4:	0c0027b7          	lui	a5,0xc002
    800052c8:	97ba                	add	a5,a5,a4
    800052ca:	40200713          	li	a4,1026
    800052ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800052d2:	00d5151b          	slliw	a0,a0,0xd
    800052d6:	0c2017b7          	lui	a5,0xc201
    800052da:	953e                	add	a0,a0,a5
    800052dc:	00052023          	sw	zero,0(a0)
}
    800052e0:	60a2                	ld	ra,8(sp)
    800052e2:	6402                	ld	s0,0(sp)
    800052e4:	0141                	addi	sp,sp,16
    800052e6:	8082                	ret

00000000800052e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800052e8:	1141                	addi	sp,sp,-16
    800052ea:	e406                	sd	ra,8(sp)
    800052ec:	e022                	sd	s0,0(sp)
    800052ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800052f0:	ce8fc0ef          	jal	ra,800017d8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800052f4:	00d5179b          	slliw	a5,a0,0xd
    800052f8:	0c201537          	lui	a0,0xc201
    800052fc:	953e                	add	a0,a0,a5
  return irq;
}
    800052fe:	4148                	lw	a0,4(a0)
    80005300:	60a2                	ld	ra,8(sp)
    80005302:	6402                	ld	s0,0(sp)
    80005304:	0141                	addi	sp,sp,16
    80005306:	8082                	ret

0000000080005308 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005308:	1101                	addi	sp,sp,-32
    8000530a:	ec06                	sd	ra,24(sp)
    8000530c:	e822                	sd	s0,16(sp)
    8000530e:	e426                	sd	s1,8(sp)
    80005310:	1000                	addi	s0,sp,32
    80005312:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005314:	cc4fc0ef          	jal	ra,800017d8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005318:	00d5151b          	slliw	a0,a0,0xd
    8000531c:	0c2017b7          	lui	a5,0xc201
    80005320:	97aa                	add	a5,a5,a0
    80005322:	c3c4                	sw	s1,4(a5)
}
    80005324:	60e2                	ld	ra,24(sp)
    80005326:	6442                	ld	s0,16(sp)
    80005328:	64a2                	ld	s1,8(sp)
    8000532a:	6105                	addi	sp,sp,32
    8000532c:	8082                	ret

000000008000532e <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    8000532e:	1141                	addi	sp,sp,-16
    80005330:	e406                	sd	ra,8(sp)
    80005332:	e022                	sd	s0,0(sp)
    80005334:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005336:	479d                	li	a5,7
    80005338:	04a7ca63          	blt	a5,a0,8000538c <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    8000533c:	0001b797          	auipc	a5,0x1b
    80005340:	6fc78793          	addi	a5,a5,1788 # 80020a38 <disk>
    80005344:	97aa                	add	a5,a5,a0
    80005346:	0187c783          	lbu	a5,24(a5)
    8000534a:	e7b9                	bnez	a5,80005398 <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000534c:	00451613          	slli	a2,a0,0x4
    80005350:	0001b797          	auipc	a5,0x1b
    80005354:	6e878793          	addi	a5,a5,1768 # 80020a38 <disk>
    80005358:	6394                	ld	a3,0(a5)
    8000535a:	96b2                	add	a3,a3,a2
    8000535c:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005360:	6398                	ld	a4,0(a5)
    80005362:	9732                	add	a4,a4,a2
    80005364:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005368:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    8000536c:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005370:	953e                	add	a0,a0,a5
    80005372:	4785                	li	a5,1
    80005374:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005378:	0001b517          	auipc	a0,0x1b
    8000537c:	6d850513          	addi	a0,a0,1752 # 80020a50 <disk+0x18>
    80005380:	ad9fc0ef          	jal	ra,80001e58 <wakeup>
}
    80005384:	60a2                	ld	ra,8(sp)
    80005386:	6402                	ld	s0,0(sp)
    80005388:	0141                	addi	sp,sp,16
    8000538a:	8082                	ret
    panic("free_desc 1");
    8000538c:	00002517          	auipc	a0,0x2
    80005390:	39c50513          	addi	a0,a0,924 # 80007728 <syscalls+0x338>
    80005394:	bf6fb0ef          	jal	ra,8000078a <panic>
    panic("free_desc 2");
    80005398:	00002517          	auipc	a0,0x2
    8000539c:	3a050513          	addi	a0,a0,928 # 80007738 <syscalls+0x348>
    800053a0:	beafb0ef          	jal	ra,8000078a <panic>

00000000800053a4 <virtio_disk_init>:
{
    800053a4:	1101                	addi	sp,sp,-32
    800053a6:	ec06                	sd	ra,24(sp)
    800053a8:	e822                	sd	s0,16(sp)
    800053aa:	e426                	sd	s1,8(sp)
    800053ac:	e04a                	sd	s2,0(sp)
    800053ae:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800053b0:	00002597          	auipc	a1,0x2
    800053b4:	39858593          	addi	a1,a1,920 # 80007748 <syscalls+0x358>
    800053b8:	0001b517          	auipc	a0,0x1b
    800053bc:	7a850513          	addi	a0,a0,1960 # 80020b60 <disk+0x128>
    800053c0:	f2cfb0ef          	jal	ra,80000aec <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800053c4:	100017b7          	lui	a5,0x10001
    800053c8:	4398                	lw	a4,0(a5)
    800053ca:	2701                	sext.w	a4,a4
    800053cc:	747277b7          	lui	a5,0x74727
    800053d0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800053d4:	14f71063          	bne	a4,a5,80005514 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800053d8:	100017b7          	lui	a5,0x10001
    800053dc:	43dc                	lw	a5,4(a5)
    800053de:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800053e0:	4709                	li	a4,2
    800053e2:	12e79963          	bne	a5,a4,80005514 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800053e6:	100017b7          	lui	a5,0x10001
    800053ea:	479c                	lw	a5,8(a5)
    800053ec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800053ee:	12e79363          	bne	a5,a4,80005514 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800053f2:	100017b7          	lui	a5,0x10001
    800053f6:	47d8                	lw	a4,12(a5)
    800053f8:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800053fa:	554d47b7          	lui	a5,0x554d4
    800053fe:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005402:	10f71963          	bne	a4,a5,80005514 <virtio_disk_init+0x170>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005406:	100017b7          	lui	a5,0x10001
    8000540a:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000540e:	4705                	li	a4,1
    80005410:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005412:	470d                	li	a4,3
    80005414:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005416:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005418:	c7ffe737          	lui	a4,0xc7ffe
    8000541c:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fddbe7>
    80005420:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005422:	2701                	sext.w	a4,a4
    80005424:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005426:	472d                	li	a4,11
    80005428:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    8000542a:	5bbc                	lw	a5,112(a5)
    8000542c:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005430:	8ba1                	andi	a5,a5,8
    80005432:	0e078763          	beqz	a5,80005520 <virtio_disk_init+0x17c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005436:	100017b7          	lui	a5,0x10001
    8000543a:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    8000543e:	43fc                	lw	a5,68(a5)
    80005440:	2781                	sext.w	a5,a5
    80005442:	0e079563          	bnez	a5,8000552c <virtio_disk_init+0x188>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005446:	100017b7          	lui	a5,0x10001
    8000544a:	5bdc                	lw	a5,52(a5)
    8000544c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000544e:	0e078563          	beqz	a5,80005538 <virtio_disk_init+0x194>
  if(max < NUM)
    80005452:	471d                	li	a4,7
    80005454:	0ef77863          	bgeu	a4,a5,80005544 <virtio_disk_init+0x1a0>
  disk.desc = kalloc();
    80005458:	e44fb0ef          	jal	ra,80000a9c <kalloc>
    8000545c:	0001b497          	auipc	s1,0x1b
    80005460:	5dc48493          	addi	s1,s1,1500 # 80020a38 <disk>
    80005464:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005466:	e36fb0ef          	jal	ra,80000a9c <kalloc>
    8000546a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000546c:	e30fb0ef          	jal	ra,80000a9c <kalloc>
    80005470:	87aa                	mv	a5,a0
    80005472:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005474:	6088                	ld	a0,0(s1)
    80005476:	cd69                	beqz	a0,80005550 <virtio_disk_init+0x1ac>
    80005478:	0001b717          	auipc	a4,0x1b
    8000547c:	5c873703          	ld	a4,1480(a4) # 80020a40 <disk+0x8>
    80005480:	cb61                	beqz	a4,80005550 <virtio_disk_init+0x1ac>
    80005482:	c7f9                	beqz	a5,80005550 <virtio_disk_init+0x1ac>
  memset(disk.desc, 0, PGSIZE);
    80005484:	6605                	lui	a2,0x1
    80005486:	4581                	li	a1,0
    80005488:	fb8fb0ef          	jal	ra,80000c40 <memset>
  memset(disk.avail, 0, PGSIZE);
    8000548c:	0001b497          	auipc	s1,0x1b
    80005490:	5ac48493          	addi	s1,s1,1452 # 80020a38 <disk>
    80005494:	6605                	lui	a2,0x1
    80005496:	4581                	li	a1,0
    80005498:	6488                	ld	a0,8(s1)
    8000549a:	fa6fb0ef          	jal	ra,80000c40 <memset>
  memset(disk.used, 0, PGSIZE);
    8000549e:	6605                	lui	a2,0x1
    800054a0:	4581                	li	a1,0
    800054a2:	6888                	ld	a0,16(s1)
    800054a4:	f9cfb0ef          	jal	ra,80000c40 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800054a8:	100017b7          	lui	a5,0x10001
    800054ac:	4721                	li	a4,8
    800054ae:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800054b0:	4098                	lw	a4,0(s1)
    800054b2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800054b6:	40d8                	lw	a4,4(s1)
    800054b8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800054bc:	6498                	ld	a4,8(s1)
    800054be:	0007069b          	sext.w	a3,a4
    800054c2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800054c6:	9701                	srai	a4,a4,0x20
    800054c8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800054cc:	6898                	ld	a4,16(s1)
    800054ce:	0007069b          	sext.w	a3,a4
    800054d2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800054d6:	9701                	srai	a4,a4,0x20
    800054d8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800054dc:	4705                	li	a4,1
    800054de:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800054e0:	00e48c23          	sb	a4,24(s1)
    800054e4:	00e48ca3          	sb	a4,25(s1)
    800054e8:	00e48d23          	sb	a4,26(s1)
    800054ec:	00e48da3          	sb	a4,27(s1)
    800054f0:	00e48e23          	sb	a4,28(s1)
    800054f4:	00e48ea3          	sb	a4,29(s1)
    800054f8:	00e48f23          	sb	a4,30(s1)
    800054fc:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005500:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005504:	0727a823          	sw	s2,112(a5)
}
    80005508:	60e2                	ld	ra,24(sp)
    8000550a:	6442                	ld	s0,16(sp)
    8000550c:	64a2                	ld	s1,8(sp)
    8000550e:	6902                	ld	s2,0(sp)
    80005510:	6105                	addi	sp,sp,32
    80005512:	8082                	ret
    panic("could not find virtio disk");
    80005514:	00002517          	auipc	a0,0x2
    80005518:	24450513          	addi	a0,a0,580 # 80007758 <syscalls+0x368>
    8000551c:	a6efb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk FEATURES_OK unset");
    80005520:	00002517          	auipc	a0,0x2
    80005524:	25850513          	addi	a0,a0,600 # 80007778 <syscalls+0x388>
    80005528:	a62fb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk should not be ready");
    8000552c:	00002517          	auipc	a0,0x2
    80005530:	26c50513          	addi	a0,a0,620 # 80007798 <syscalls+0x3a8>
    80005534:	a56fb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk has no queue 0");
    80005538:	00002517          	auipc	a0,0x2
    8000553c:	28050513          	addi	a0,a0,640 # 800077b8 <syscalls+0x3c8>
    80005540:	a4afb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk max queue too short");
    80005544:	00002517          	auipc	a0,0x2
    80005548:	29450513          	addi	a0,a0,660 # 800077d8 <syscalls+0x3e8>
    8000554c:	a3efb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk kalloc");
    80005550:	00002517          	auipc	a0,0x2
    80005554:	2a850513          	addi	a0,a0,680 # 800077f8 <syscalls+0x408>
    80005558:	a32fb0ef          	jal	ra,8000078a <panic>

000000008000555c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000555c:	7119                	addi	sp,sp,-128
    8000555e:	fc86                	sd	ra,120(sp)
    80005560:	f8a2                	sd	s0,112(sp)
    80005562:	f4a6                	sd	s1,104(sp)
    80005564:	f0ca                	sd	s2,96(sp)
    80005566:	ecce                	sd	s3,88(sp)
    80005568:	e8d2                	sd	s4,80(sp)
    8000556a:	e4d6                	sd	s5,72(sp)
    8000556c:	e0da                	sd	s6,64(sp)
    8000556e:	fc5e                	sd	s7,56(sp)
    80005570:	f862                	sd	s8,48(sp)
    80005572:	f466                	sd	s9,40(sp)
    80005574:	f06a                	sd	s10,32(sp)
    80005576:	ec6e                	sd	s11,24(sp)
    80005578:	0100                	addi	s0,sp,128
    8000557a:	8aaa                	mv	s5,a0
    8000557c:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000557e:	00c52d03          	lw	s10,12(a0)
    80005582:	001d1d1b          	slliw	s10,s10,0x1
    80005586:	1d02                	slli	s10,s10,0x20
    80005588:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    8000558c:	0001b517          	auipc	a0,0x1b
    80005590:	5d450513          	addi	a0,a0,1492 # 80020b60 <disk+0x128>
    80005594:	dd8fb0ef          	jal	ra,80000b6c <acquire>
  for(int i = 0; i < 3; i++){
    80005598:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000559a:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000559c:	0001bb97          	auipc	s7,0x1b
    800055a0:	49cb8b93          	addi	s7,s7,1180 # 80020a38 <disk>
  for(int i = 0; i < 3; i++){
    800055a4:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800055a6:	0001bc97          	auipc	s9,0x1b
    800055aa:	5bac8c93          	addi	s9,s9,1466 # 80020b60 <disk+0x128>
    800055ae:	a8a9                	j	80005608 <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    800055b0:	00fb8733          	add	a4,s7,a5
    800055b4:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800055b8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800055ba:	0207c563          	bltz	a5,800055e4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800055be:	2905                	addiw	s2,s2,1
    800055c0:	0611                	addi	a2,a2,4
    800055c2:	05690863          	beq	s2,s6,80005612 <virtio_disk_rw+0xb6>
    idx[i] = alloc_desc();
    800055c6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800055c8:	0001b717          	auipc	a4,0x1b
    800055cc:	47070713          	addi	a4,a4,1136 # 80020a38 <disk>
    800055d0:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800055d2:	01874683          	lbu	a3,24(a4)
    800055d6:	fee9                	bnez	a3,800055b0 <virtio_disk_rw+0x54>
  for(int i = 0; i < NUM; i++){
    800055d8:	2785                	addiw	a5,a5,1
    800055da:	0705                	addi	a4,a4,1
    800055dc:	fe979be3          	bne	a5,s1,800055d2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800055e0:	57fd                	li	a5,-1
    800055e2:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800055e4:	01205b63          	blez	s2,800055fa <virtio_disk_rw+0x9e>
    800055e8:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800055ea:	000a2503          	lw	a0,0(s4)
    800055ee:	d41ff0ef          	jal	ra,8000532e <free_desc>
      for(int j = 0; j < i; j++)
    800055f2:	2d85                	addiw	s11,s11,1
    800055f4:	0a11                	addi	s4,s4,4
    800055f6:	ffb91ae3          	bne	s2,s11,800055ea <virtio_disk_rw+0x8e>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800055fa:	85e6                	mv	a1,s9
    800055fc:	0001b517          	auipc	a0,0x1b
    80005600:	45450513          	addi	a0,a0,1108 # 80020a50 <disk+0x18>
    80005604:	809fc0ef          	jal	ra,80001e0c <sleep>
  for(int i = 0; i < 3; i++){
    80005608:	f8040a13          	addi	s4,s0,-128
{
    8000560c:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000560e:	894e                	mv	s2,s3
    80005610:	bf5d                	j	800055c6 <virtio_disk_rw+0x6a>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005612:	f8042583          	lw	a1,-128(s0)
    80005616:	00a58793          	addi	a5,a1,10
    8000561a:	0792                	slli	a5,a5,0x4

  if(write)
    8000561c:	0001b617          	auipc	a2,0x1b
    80005620:	41c60613          	addi	a2,a2,1052 # 80020a38 <disk>
    80005624:	00f60733          	add	a4,a2,a5
    80005628:	018036b3          	snez	a3,s8
    8000562c:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000562e:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80005632:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005636:	f6078693          	addi	a3,a5,-160
    8000563a:	6218                	ld	a4,0(a2)
    8000563c:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000563e:	00878513          	addi	a0,a5,8
    80005642:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005644:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005646:	6208                	ld	a0,0(a2)
    80005648:	96aa                	add	a3,a3,a0
    8000564a:	4741                	li	a4,16
    8000564c:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000564e:	4705                	li	a4,1
    80005650:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80005654:	f8442703          	lw	a4,-124(s0)
    80005658:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    8000565c:	0712                	slli	a4,a4,0x4
    8000565e:	953a                	add	a0,a0,a4
    80005660:	058a8693          	addi	a3,s5,88
    80005664:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80005666:	6208                	ld	a0,0(a2)
    80005668:	972a                	add	a4,a4,a0
    8000566a:	40000693          	li	a3,1024
    8000566e:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80005670:	001c3c13          	seqz	s8,s8
    80005674:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005676:	001c6c13          	ori	s8,s8,1
    8000567a:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    8000567e:	f8842603          	lw	a2,-120(s0)
    80005682:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005686:	0001b697          	auipc	a3,0x1b
    8000568a:	3b268693          	addi	a3,a3,946 # 80020a38 <disk>
    8000568e:	00258713          	addi	a4,a1,2
    80005692:	0712                	slli	a4,a4,0x4
    80005694:	9736                	add	a4,a4,a3
    80005696:	587d                	li	a6,-1
    80005698:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000569c:	0612                	slli	a2,a2,0x4
    8000569e:	9532                	add	a0,a0,a2
    800056a0:	f9078793          	addi	a5,a5,-112
    800056a4:	97b6                	add	a5,a5,a3
    800056a6:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800056a8:	629c                	ld	a5,0(a3)
    800056aa:	97b2                	add	a5,a5,a2
    800056ac:	4605                	li	a2,1
    800056ae:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800056b0:	4509                	li	a0,2
    800056b2:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800056b6:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800056ba:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800056be:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800056c2:	6698                	ld	a4,8(a3)
    800056c4:	00275783          	lhu	a5,2(a4)
    800056c8:	8b9d                	andi	a5,a5,7
    800056ca:	0786                	slli	a5,a5,0x1
    800056cc:	97ba                	add	a5,a5,a4
    800056ce:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800056d2:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800056d6:	6698                	ld	a4,8(a3)
    800056d8:	00275783          	lhu	a5,2(a4)
    800056dc:	2785                	addiw	a5,a5,1
    800056de:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800056e2:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800056e6:	100017b7          	lui	a5,0x10001
    800056ea:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800056ee:	004aa783          	lw	a5,4(s5)
    800056f2:	00c79f63          	bne	a5,a2,80005710 <virtio_disk_rw+0x1b4>
    sleep(b, &disk.vdisk_lock);
    800056f6:	0001b917          	auipc	s2,0x1b
    800056fa:	46a90913          	addi	s2,s2,1130 # 80020b60 <disk+0x128>
  while(b->disk == 1) {
    800056fe:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005700:	85ca                	mv	a1,s2
    80005702:	8556                	mv	a0,s5
    80005704:	f08fc0ef          	jal	ra,80001e0c <sleep>
  while(b->disk == 1) {
    80005708:	004aa783          	lw	a5,4(s5)
    8000570c:	fe978ae3          	beq	a5,s1,80005700 <virtio_disk_rw+0x1a4>
  }

  disk.info[idx[0]].b = 0;
    80005710:	f8042903          	lw	s2,-128(s0)
    80005714:	00290793          	addi	a5,s2,2
    80005718:	00479713          	slli	a4,a5,0x4
    8000571c:	0001b797          	auipc	a5,0x1b
    80005720:	31c78793          	addi	a5,a5,796 # 80020a38 <disk>
    80005724:	97ba                	add	a5,a5,a4
    80005726:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000572a:	0001b997          	auipc	s3,0x1b
    8000572e:	30e98993          	addi	s3,s3,782 # 80020a38 <disk>
    80005732:	00491713          	slli	a4,s2,0x4
    80005736:	0009b783          	ld	a5,0(s3)
    8000573a:	97ba                	add	a5,a5,a4
    8000573c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005740:	854a                	mv	a0,s2
    80005742:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005746:	be9ff0ef          	jal	ra,8000532e <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000574a:	8885                	andi	s1,s1,1
    8000574c:	f0fd                	bnez	s1,80005732 <virtio_disk_rw+0x1d6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000574e:	0001b517          	auipc	a0,0x1b
    80005752:	41250513          	addi	a0,a0,1042 # 80020b60 <disk+0x128>
    80005756:	caefb0ef          	jal	ra,80000c04 <release>
}
    8000575a:	70e6                	ld	ra,120(sp)
    8000575c:	7446                	ld	s0,112(sp)
    8000575e:	74a6                	ld	s1,104(sp)
    80005760:	7906                	ld	s2,96(sp)
    80005762:	69e6                	ld	s3,88(sp)
    80005764:	6a46                	ld	s4,80(sp)
    80005766:	6aa6                	ld	s5,72(sp)
    80005768:	6b06                	ld	s6,64(sp)
    8000576a:	7be2                	ld	s7,56(sp)
    8000576c:	7c42                	ld	s8,48(sp)
    8000576e:	7ca2                	ld	s9,40(sp)
    80005770:	7d02                	ld	s10,32(sp)
    80005772:	6de2                	ld	s11,24(sp)
    80005774:	6109                	addi	sp,sp,128
    80005776:	8082                	ret

0000000080005778 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80005778:	1101                	addi	sp,sp,-32
    8000577a:	ec06                	sd	ra,24(sp)
    8000577c:	e822                	sd	s0,16(sp)
    8000577e:	e426                	sd	s1,8(sp)
    80005780:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80005782:	0001b497          	auipc	s1,0x1b
    80005786:	2b648493          	addi	s1,s1,694 # 80020a38 <disk>
    8000578a:	0001b517          	auipc	a0,0x1b
    8000578e:	3d650513          	addi	a0,a0,982 # 80020b60 <disk+0x128>
    80005792:	bdafb0ef          	jal	ra,80000b6c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80005796:	10001737          	lui	a4,0x10001
    8000579a:	533c                	lw	a5,96(a4)
    8000579c:	8b8d                	andi	a5,a5,3
    8000579e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800057a0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800057a4:	689c                	ld	a5,16(s1)
    800057a6:	0204d703          	lhu	a4,32(s1)
    800057aa:	0027d783          	lhu	a5,2(a5)
    800057ae:	04f70663          	beq	a4,a5,800057fa <virtio_disk_intr+0x82>
    __sync_synchronize();
    800057b2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800057b6:	6898                	ld	a4,16(s1)
    800057b8:	0204d783          	lhu	a5,32(s1)
    800057bc:	8b9d                	andi	a5,a5,7
    800057be:	078e                	slli	a5,a5,0x3
    800057c0:	97ba                	add	a5,a5,a4
    800057c2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800057c4:	00278713          	addi	a4,a5,2
    800057c8:	0712                	slli	a4,a4,0x4
    800057ca:	9726                	add	a4,a4,s1
    800057cc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800057d0:	e321                	bnez	a4,80005810 <virtio_disk_intr+0x98>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800057d2:	0789                	addi	a5,a5,2
    800057d4:	0792                	slli	a5,a5,0x4
    800057d6:	97a6                	add	a5,a5,s1
    800057d8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800057da:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800057de:	e7afc0ef          	jal	ra,80001e58 <wakeup>

    disk.used_idx += 1;
    800057e2:	0204d783          	lhu	a5,32(s1)
    800057e6:	2785                	addiw	a5,a5,1
    800057e8:	17c2                	slli	a5,a5,0x30
    800057ea:	93c1                	srli	a5,a5,0x30
    800057ec:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800057f0:	6898                	ld	a4,16(s1)
    800057f2:	00275703          	lhu	a4,2(a4)
    800057f6:	faf71ee3          	bne	a4,a5,800057b2 <virtio_disk_intr+0x3a>
  }

  release(&disk.vdisk_lock);
    800057fa:	0001b517          	auipc	a0,0x1b
    800057fe:	36650513          	addi	a0,a0,870 # 80020b60 <disk+0x128>
    80005802:	c02fb0ef          	jal	ra,80000c04 <release>
}
    80005806:	60e2                	ld	ra,24(sp)
    80005808:	6442                	ld	s0,16(sp)
    8000580a:	64a2                	ld	s1,8(sp)
    8000580c:	6105                	addi	sp,sp,32
    8000580e:	8082                	ret
      panic("virtio_disk_intr status");
    80005810:	00002517          	auipc	a0,0x2
    80005814:	00050513          	mv	a0,a0
    80005818:	f73fa0ef          	jal	ra,8000078a <panic>
	...

0000000080006000 <_trampoline>:
        # 用户页表。
        #

        # 将用户的 a0 保存到 sscratch 寄存器中，
        # 以便 a0 可以用于访问 TRAPFRAME。
        csrw sscratch, a0
    80006000:	14051073          	csrw	sscratch,a0

        # 每个进程都有一个独立的 p->trapframe 内存区域，
        # 但是它在每个进程的用户页表中
        # 被映射到相同的虚拟地址（TRAPFRAME）。
        li a0, TRAPFRAME
    80006004:	02000537          	lui	a0,0x2000
    80006008:	357d                	addiw	a0,a0,-1
    8000600a:	0536                	slli	a0,a0,0xd
        
        # 将用户的寄存器保存到 TRAPFRAME 中
        sd ra, 40(a0)  # 保存返回地址
    8000600c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
        sd sp, 48(a0)  # 保存堆栈指针
    80006010:	02253823          	sd	sp,48(a0)
        sd gp, 56(a0)  # 保存全局指针
    80006014:	02353c23          	sd	gp,56(a0)
        sd tp, 64(a0)  # 保存线程指针
    80006018:	04453023          	sd	tp,64(a0)
        sd t0, 72(a0)  # 保存临时寄存器 t0
    8000601c:	04553423          	sd	t0,72(a0)
        sd t1, 80(a0)  # 保存临时寄存器 t1
    80006020:	04653823          	sd	t1,80(a0)
        sd t2, 88(a0)  # 保存临时寄存器 t2
    80006024:	04753c23          	sd	t2,88(a0)
        sd s0, 96(a0)  # 保存保存寄存器 s0
    80006028:	f120                	sd	s0,96(a0)
        sd s1, 104(a0) # 保存保存寄存器 s1
    8000602a:	f524                	sd	s1,104(a0)
        sd a1, 120(a0) # 保存 a1
    8000602c:	fd2c                	sd	a1,120(a0)
        sd a2, 128(a0) # 保存 a2
    8000602e:	e150                	sd	a2,128(a0)
        sd a3, 136(a0) # 保存 a3
    80006030:	e554                	sd	a3,136(a0)
        sd a4, 144(a0) # 保存 a4
    80006032:	e958                	sd	a4,144(a0)
        sd a5, 152(a0) # 保存 a5
    80006034:	ed5c                	sd	a5,152(a0)
        sd a6, 160(a0) # 保存 a6
    80006036:	0b053023          	sd	a6,160(a0)
        sd a7, 168(a0) # 保存 a7
    8000603a:	0b153423          	sd	a7,168(a0)
        sd s2, 176(a0) # 保存 s2
    8000603e:	0b253823          	sd	s2,176(a0)
        sd s3, 184(a0) # 保存 s3
    80006042:	0b353c23          	sd	s3,184(a0)
        sd s4, 192(a0) # 保存 s4
    80006046:	0d453023          	sd	s4,192(a0)
        sd s5, 200(a0) # 保存 s5
    8000604a:	0d553423          	sd	s5,200(a0)
        sd s6, 208(a0) # 保存 s6
    8000604e:	0d653823          	sd	s6,208(a0)
        sd s7, 216(a0) # 保存 s7
    80006052:	0d753c23          	sd	s7,216(a0)
        sd s8, 224(a0) # 保存 s8
    80006056:	0f853023          	sd	s8,224(a0)
        sd s9, 232(a0) # 保存 s9
    8000605a:	0f953423          	sd	s9,232(a0)
        sd s10, 240(a0) # 保存 s10
    8000605e:	0fa53823          	sd	s10,240(a0)
        sd s11, 248(a0) # 保存 s11
    80006062:	0fb53c23          	sd	s11,248(a0)
        sd t3, 256(a0)  # 保存临时寄存器 t3
    80006066:	11c53023          	sd	t3,256(a0)
        sd t4, 264(a0)  # 保存临时寄存器 t4
    8000606a:	11d53423          	sd	t4,264(a0)
        sd t5, 272(a0)  # 保存临时寄存器 t5
    8000606e:	11e53823          	sd	t5,272(a0)
        sd t6, 280(a0)  # 保存临时寄存器 t6
    80006072:	11f53c23          	sd	t6,280(a0)

	# 将用户的 a0 保存到 p->trapframe->a0 中
        csrr t0, sscratch
    80006076:	140022f3          	csrr	t0,sscratch
        sd t0, 112(a0)
    8000607a:	06553823          	sd	t0,112(a0)

        # 初始化内核堆栈指针，从 p->trapframe->kernel_sp 获取
        ld sp, 8(a0)
    8000607e:	00853103          	ld	sp,8(a0)

        # 将线程指针 tp 设置为当前的 hartid，从 p->trapframe->kernel_hartid 获取
        ld tp, 32(a0)
    80006082:	02053203          	ld	tp,32(a0)

        # 加载 usertrap() 的地址，从 p->trapframe->kernel_trap 获取
        ld t0, 16(a0)
    80006086:	01053283          	ld	t0,16(a0)

        # 获取内核页表地址，从 p->trapframe->kernel_satp 获取
        ld t1, 0(a0)
    8000608a:	00053303          	ld	t1,0(a0)

        # 等待所有先前的内存操作完成，以便它们使用用户页表
        sfence.vma zero, zero
    8000608e:	12000073          	sfence.vma

        # 安装内核页表
        csrw satp, t1
    80006092:	18031073          	csrw	satp,t1

        # 刷新现在已经过时的用户条目
        sfence.vma zero, zero
    80006096:	12000073          	sfence.vma

        # 调用 usertrap()
        jalr t0
    8000609a:	9282                	jalr	t0

000000008000609c <userret>:
userret:
        # usertrap() 返回到这里，a0 中包含用户的 satp。
        # 从内核返回到用户。

        # 切换到用户页表
        sfence.vma zero, zero
    8000609c:	12000073          	sfence.vma
        csrw satp, a0
    800060a0:	18051073          	csrw	satp,a0
        sfence.vma zero, zero
    800060a4:	12000073          	sfence.vma

        li a0, TRAPFRAME
    800060a8:	02000537          	lui	a0,0x2000
    800060ac:	357d                	addiw	a0,a0,-1
    800060ae:	0536                	slli	a0,a0,0xd

        # 恢复除了 a0 之外的所有寄存器
        ld ra, 40(a0)
    800060b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
        ld sp, 48(a0)
    800060b4:	03053103          	ld	sp,48(a0)
        ld gp, 56(a0)
    800060b8:	03853183          	ld	gp,56(a0)
        ld tp, 64(a0)
    800060bc:	04053203          	ld	tp,64(a0)
        ld t0, 72(a0)
    800060c0:	04853283          	ld	t0,72(a0)
        ld t1, 80(a0)
    800060c4:	05053303          	ld	t1,80(a0)
        ld t2, 88(a0)
    800060c8:	05853383          	ld	t2,88(a0)
        ld s0, 96(a0)
    800060cc:	7120                	ld	s0,96(a0)
        ld s1, 104(a0)
    800060ce:	7524                	ld	s1,104(a0)
        ld a1, 120(a0)
    800060d0:	7d2c                	ld	a1,120(a0)
        ld a2, 128(a0)
    800060d2:	6150                	ld	a2,128(a0)
        ld a3, 136(a0)
    800060d4:	6554                	ld	a3,136(a0)
        ld a4, 144(a0)
    800060d6:	6958                	ld	a4,144(a0)
        ld a5, 152(a0)
    800060d8:	6d5c                	ld	a5,152(a0)
        ld a6, 160(a0)
    800060da:	0a053803          	ld	a6,160(a0)
        ld a7, 168(a0)
    800060de:	0a853883          	ld	a7,168(a0)
        ld s2, 176(a0)
    800060e2:	0b053903          	ld	s2,176(a0)
        ld s3, 184(a0)
    800060e6:	0b853983          	ld	s3,184(a0)
        ld s4, 192(a0)
    800060ea:	0c053a03          	ld	s4,192(a0)
        ld s5, 200(a0)
    800060ee:	0c853a83          	ld	s5,200(a0)
        ld s6, 208(a0)
    800060f2:	0d053b03          	ld	s6,208(a0)
        ld s7, 216(a0)
    800060f6:	0d853b83          	ld	s7,216(a0)
        ld s8, 224(a0)
    800060fa:	0e053c03          	ld	s8,224(a0)
        ld s9, 232(a0)
    800060fe:	0e853c83          	ld	s9,232(a0)
        ld s10, 240(a0)
    80006102:	0f053d03          	ld	s10,240(a0)
        ld s11, 248(a0)
    80006106:	0f853d83          	ld	s11,248(a0)
        ld t3, 256(a0)
    8000610a:	10053e03          	ld	t3,256(a0)
        ld t4, 264(a0)
    8000610e:	10853e83          	ld	t4,264(a0)
        ld t5, 272(a0)
    80006112:	11053f03          	ld	t5,272(a0)
        ld t6, 280(a0)
    80006116:	11853f83          	ld	t6,280(a0)

	# 恢复用户的 a0
        ld a0, 112(a0)
    8000611a:	7928                	ld	a0,112(a0)
        
        # 返回用户模式和用户程序计数器 (pc)
        # usertrapret() 设置了 sstatus 和 sepc。
        sret
    8000611c:	10200073          	sret
	...
