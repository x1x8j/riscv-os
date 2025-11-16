
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
    80000004:	a2010113          	addi	sp,sp,-1504 # 80007a20 <stack0>
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
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd58ff>
    80000072:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000074:	6705                	lui	a4,0x1
    80000076:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000007a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007c:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000080:	00001797          	auipc	a5,0x1
    80000084:	ee478793          	addi	a5,a5,-284 # 80000f64 <main>
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
    8000010a:	2c8020ef          	jal	ra,800023d2 <either_copyin>
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
    80000172:	00010517          	auipc	a0,0x10
    80000176:	8ae50513          	addi	a0,a0,-1874 # 8000fa20 <cons>
    8000017a:	375000ef          	jal	ra,80000cee <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000017e:	00010497          	auipc	s1,0x10
    80000182:	8a248493          	addi	s1,s1,-1886 # 8000fa20 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000186:	00010917          	auipc	s2,0x10
    8000018a:	93290913          	addi	s2,s2,-1742 # 8000fab8 <cons+0x98>
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
    800001a4:	077010ef          	jal	ra,80001a1a <myproc>
    800001a8:	0bc020ef          	jal	ra,80002264 <killed>
    800001ac:	e125                	bnez	a0,8000020c <consoleread+0xc0>
      sleep(&cons.r, &cons.lock);
    800001ae:	85a6                	mv	a1,s1
    800001b0:	854a                	mv	a0,s2
    800001b2:	67b010ef          	jal	ra,8000202c <sleep>
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
    800001ea:	19e020ef          	jal	ra,80002388 <either_copyout>
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
    800001fa:	00010517          	auipc	a0,0x10
    800001fe:	82650513          	addi	a0,a0,-2010 # 8000fa20 <cons>
    80000202:	385000ef          	jal	ra,80000d86 <release>

  return target - n;
    80000206:	413b053b          	subw	a0,s6,s3
    8000020a:	a801                	j	8000021a <consoleread+0xce>
        release(&cons.lock);
    8000020c:	00010517          	auipc	a0,0x10
    80000210:	81450513          	addi	a0,a0,-2028 # 8000fa20 <cons>
    80000214:	373000ef          	jal	ra,80000d86 <release>
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
    8000023e:	00010717          	auipc	a4,0x10
    80000242:	86f72d23          	sw	a5,-1926(a4) # 8000fab8 <cons+0x98>
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
    8000028c:	79850513          	addi	a0,a0,1944 # 8000fa20 <cons>
    80000290:	25f000ef          	jal	ra,80000cee <acquire>

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
    800002aa:	172020ef          	jal	ra,8000241c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002ae:	0000f517          	auipc	a0,0xf
    800002b2:	77250513          	addi	a0,a0,1906 # 8000fa20 <cons>
    800002b6:	2d1000ef          	jal	ra,80000d86 <release>
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
    800002d2:	75270713          	addi	a4,a4,1874 # 8000fa20 <cons>
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
    800002f8:	72c78793          	addi	a5,a5,1836 # 8000fa20 <cons>
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
    80000326:	7967a783          	lw	a5,1942(a5) # 8000fab8 <cons+0x98>
    8000032a:	9f1d                	subw	a4,a4,a5
    8000032c:	08000793          	li	a5,128
    80000330:	f6f71fe3          	bne	a4,a5,800002ae <consoleintr+0x34>
    80000334:	a04d                	j	800003d6 <consoleintr+0x15c>
    while(cons.e != cons.w &&
    80000336:	0000f717          	auipc	a4,0xf
    8000033a:	6ea70713          	addi	a4,a4,1770 # 8000fa20 <cons>
    8000033e:	0a072783          	lw	a5,160(a4)
    80000342:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000346:	0000f497          	auipc	s1,0xf
    8000034a:	6da48493          	addi	s1,s1,1754 # 8000fa20 <cons>
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
    80000382:	6a270713          	addi	a4,a4,1698 # 8000fa20 <cons>
    80000386:	0a072783          	lw	a5,160(a4)
    8000038a:	09c72703          	lw	a4,156(a4)
    8000038e:	f2f700e3          	beq	a4,a5,800002ae <consoleintr+0x34>
      cons.e--;
    80000392:	37fd                	addiw	a5,a5,-1
    80000394:	0000f717          	auipc	a4,0xf
    80000398:	72f72623          	sw	a5,1836(a4) # 8000fac0 <cons+0xa0>
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
    800003b6:	66e78793          	addi	a5,a5,1646 # 8000fa20 <cons>
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
    800003da:	6ec7a323          	sw	a2,1766(a5) # 8000fabc <cons+0x9c>
        wakeup(&cons.r);
    800003de:	0000f517          	auipc	a0,0xf
    800003e2:	6da50513          	addi	a0,a0,1754 # 8000fab8 <cons+0x98>
    800003e6:	493010ef          	jal	ra,80002078 <wakeup>
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
    80000400:	62450513          	addi	a0,a0,1572 # 8000fa20 <cons>
    80000404:	06b000ef          	jal	ra,80000c6e <initlock>

  uartinit();
    80000408:	3e2000ef          	jal	ra,800007ea <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000040c:	00028797          	auipc	a5,0x28
    80000410:	95c78793          	addi	a5,a5,-1700 # 80027d68 <devsw>
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
    800004fa:	4fe7a783          	lw	a5,1278(a5) # 800079f4 <panicking>
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
    80000538:	59450513          	addi	a0,a0,1428 # 8000fac8 <pr>
    8000053c:	7b2000ef          	jal	ra,80000cee <acquire>
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
    80000756:	2a27a783          	lw	a5,674(a5) # 800079f4 <panicking>
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
    80000780:	34c50513          	addi	a0,a0,844 # 8000fac8 <pr>
    80000784:	602000ef          	jal	ra,80000d86 <release>
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
    8000079e:	2527ad23          	sw	s2,602(a5) # 800079f4 <panicking>
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
    800007c0:	2327aa23          	sw	s2,564(a5) # 800079f0 <panicked>
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
    800007da:	2f250513          	addi	a0,a0,754 # 8000fac8 <pr>
    800007de:	490000ef          	jal	ra,80000c6e <initlock>
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
    80000826:	2be50513          	addi	a0,a0,702 # 8000fae0 <tx_lock>
    8000082a:	444000ef          	jal	ra,80000c6e <initlock>
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
    80000854:	29050513          	addi	a0,a0,656 # 8000fae0 <tx_lock>
    80000858:	496000ef          	jal	ra,80000cee <acquire>

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
    80000872:	18e48493          	addi	s1,s1,398 # 800079fc <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    80000876:	0000f997          	auipc	s3,0xf
    8000087a:	26a98993          	addi	s3,s3,618 # 8000fae0 <tx_lock>
    8000087e:	00007917          	auipc	s2,0x7
    80000882:	17a90913          	addi	s2,s2,378 # 800079f8 <tx_chan>
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
    80000892:	79a010ef          	jal	ra,8000202c <sleep>
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
    800008b6:	22e50513          	addi	a0,a0,558 # 8000fae0 <tx_lock>
    800008ba:	4cc000ef          	jal	ra,80000d86 <release>
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
    800008e4:	1147a783          	lw	a5,276(a5) # 800079f4 <panicking>
    800008e8:	cb89                	beqz	a5,800008fa <uartputc_sync+0x26>
    push_off();

  if(panicked){
    800008ea:	00007797          	auipc	a5,0x7
    800008ee:	1067a783          	lw	a5,262(a5) # 800079f0 <panicked>
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
    800008fa:	3b4000ef          	jal	ra,80000cae <push_off>
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
    8000091a:	0de7a783          	lw	a5,222(a5) # 800079f4 <panicking>
    8000091e:	c791                	beqz	a5,8000092a <uartputc_sync+0x56>
    pop_off();
}
    80000920:	60e2                	ld	ra,24(sp)
    80000922:	6442                	ld	s0,16(sp)
    80000924:	64a2                	ld	s1,8(sp)
    80000926:	6105                	addi	sp,sp,32
    80000928:	8082                	ret
    pop_off();
    8000092a:	408000ef          	jal	ra,80000d32 <pop_off>
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
    8000096e:	17650513          	addi	a0,a0,374 # 8000fae0 <tx_lock>
    80000972:	37c000ef          	jal	ra,80000cee <acquire>
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
    80000984:	16050513          	addi	a0,a0,352 # 8000fae0 <tx_lock>
    80000988:	3fe000ef          	jal	ra,80000d86 <release>

  // read and process incoming characters, if any.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000098c:	54fd                	li	s1,-1
    8000098e:	a831                	j	800009aa <uartintr+0x52>
    tx_busy = 0;
    80000990:	00007797          	auipc	a5,0x7
    80000994:	0607a623          	sw	zero,108(a5) # 800079fc <tx_busy>
    wakeup(&tx_chan);
    80000998:	00007517          	auipc	a0,0x7
    8000099c:	06050513          	addi	a0,a0,96 # 800079f8 <tx_chan>
    800009a0:	6d8010ef          	jal	ra,80002078 <wakeup>
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

00000000800009bc <getrefindex>:
  struct run *freelist;
} kmem;


int
getrefindex(void *pa){
    800009bc:	1141                	addi	sp,sp,-16
    800009be:	e422                	sd	s0,8(sp)
    800009c0:	0800                	addi	s0,sp,16
  int index = ((char*)pa - (char*)PGROUNDUP((uint64)end)) / PGSIZE;
    800009c2:	00029797          	auipc	a5,0x29
    800009c6:	53d78793          	addi	a5,a5,1341 # 80029eff <end+0xfff>
    800009ca:	777d                	lui	a4,0xfffff
    800009cc:	8ff9                	and	a5,a5,a4
    800009ce:	40f507b3          	sub	a5,a0,a5
    800009d2:	43f7d513          	srai	a0,a5,0x3f
    800009d6:	6705                	lui	a4,0x1
    800009d8:	177d                	addi	a4,a4,-1
    800009da:	8d79                	and	a0,a0,a4
    800009dc:	953e                	add	a0,a0,a5
    800009de:	8531                	srai	a0,a0,0xc
  return index;
}
    800009e0:	2501                	sext.w	a0,a0
    800009e2:	6422                	ld	s0,8(sp)
    800009e4:	0141                	addi	sp,sp,16
    800009e6:	8082                	ret

00000000800009e8 <getref>:

int
getref(void *pa){
    800009e8:	1141                	addi	sp,sp,-16
    800009ea:	e422                	sd	s0,8(sp)
    800009ec:	0800                	addi	s0,sp,16
  int index = ((char*)pa - (char*)PGROUNDUP((uint64)end)) / PGSIZE;
    800009ee:	00029797          	auipc	a5,0x29
    800009f2:	51178793          	addi	a5,a5,1297 # 80029eff <end+0xfff>
    800009f6:	777d                	lui	a4,0xfffff
    800009f8:	8ff9                	and	a5,a5,a4
    800009fa:	8d1d                	sub	a0,a0,a5
    800009fc:	43f55793          	srai	a5,a0,0x3f
    80000a00:	6705                	lui	a4,0x1
    80000a02:	177d                	addi	a4,a4,-1
    80000a04:	8ff9                	and	a5,a5,a4
    80000a06:	97aa                	add	a5,a5,a0
    80000a08:	87b1                	srai	a5,a5,0xc
  return reference[getrefindex(pa)];
    80000a0a:	2781                	sext.w	a5,a5
    80000a0c:	0000f717          	auipc	a4,0xf
    80000a10:	10c70713          	addi	a4,a4,268 # 8000fb18 <reference>
    80000a14:	97ba                	add	a5,a5,a4
}
    80000a16:	0007c503          	lbu	a0,0(a5)
    80000a1a:	6422                	ld	s0,8(sp)
    80000a1c:	0141                	addi	sp,sp,16
    80000a1e:	8082                	ret

0000000080000a20 <addref>:


void
addref(char *tip, void *pa){
    80000a20:	1141                	addi	sp,sp,-16
    80000a22:	e422                	sd	s0,8(sp)
    80000a24:	0800                	addi	s0,sp,16
  int index = ((char*)pa - (char*)PGROUNDUP((uint64)end)) / PGSIZE;
    80000a26:	00029797          	auipc	a5,0x29
    80000a2a:	4d978793          	addi	a5,a5,1241 # 80029eff <end+0xfff>
    80000a2e:	777d                	lui	a4,0xfffff
    80000a30:	8ff9                	and	a5,a5,a4
    80000a32:	8d9d                	sub	a1,a1,a5
    80000a34:	43f5d793          	srai	a5,a1,0x3f
    80000a38:	6705                	lui	a4,0x1
    80000a3a:	177d                	addi	a4,a4,-1
    80000a3c:	8ff9                	and	a5,a5,a4
    80000a3e:	97ae                	add	a5,a5,a1
    80000a40:	87b1                	srai	a5,a5,0xc
    80000a42:	2781                	sext.w	a5,a5
  
  reference[getrefindex(pa)]++;
    80000a44:	0000f717          	auipc	a4,0xf
    80000a48:	0d470713          	addi	a4,a4,212 # 8000fb18 <reference>
    80000a4c:	97ba                	add	a5,a5,a4
    80000a4e:	0007c703          	lbu	a4,0(a5)
    80000a52:	2705                	addiw	a4,a4,1
    80000a54:	00e78023          	sb	a4,0(a5)
  // printf("%s: addref: %d, pa: %p \n",tip,  reference[index], pa); 
  //((struct run*)pa)->ref_count++;
  //printf("%s: addref: %d, pa: %p \n", tip, ((struct run*)pa)->ref_count, pa);
}
    80000a58:	6422                	ld	s0,8(sp)
    80000a5a:	0141                	addi	sp,sp,16
    80000a5c:	8082                	ret

0000000080000a5e <subref>:

void
subref(char *tip,void *pa){
    80000a5e:	1141                	addi	sp,sp,-16
    80000a60:	e422                	sd	s0,8(sp)
    80000a62:	0800                	addi	s0,sp,16
  int index = ((char*)pa - (char*)PGROUNDUP((uint64)end)) / PGSIZE;
    80000a64:	00029797          	auipc	a5,0x29
    80000a68:	49b78793          	addi	a5,a5,1179 # 80029eff <end+0xfff>
    80000a6c:	777d                	lui	a4,0xfffff
    80000a6e:	8ff9                	and	a5,a5,a4
    80000a70:	8d9d                	sub	a1,a1,a5
    80000a72:	43f5d793          	srai	a5,a1,0x3f
    80000a76:	6705                	lui	a4,0x1
    80000a78:	177d                	addi	a4,a4,-1
    80000a7a:	8ff9                	and	a5,a5,a4
    80000a7c:	97ae                	add	a5,a5,a1
    80000a7e:	87b1                	srai	a5,a5,0xc
    80000a80:	2781                	sext.w	a5,a5
  int index = getrefindex(pa);
  if(reference[index] == 0)
    80000a82:	0000f717          	auipc	a4,0xf
    80000a86:	09670713          	addi	a4,a4,150 # 8000fb18 <reference>
    80000a8a:	973e                	add	a4,a4,a5
    80000a8c:	00074703          	lbu	a4,0(a4)
    80000a90:	cb09                	beqz	a4,80000aa2 <subref+0x44>
    return;
  reference[index]--;
    80000a92:	0000f697          	auipc	a3,0xf
    80000a96:	08668693          	addi	a3,a3,134 # 8000fb18 <reference>
    80000a9a:	97b6                	add	a5,a5,a3
    80000a9c:	377d                	addiw	a4,a4,-1
    80000a9e:	00e78023          	sb	a4,0(a5)
  /* if(((struct run*)pa)->ref_count == 0){
    return;
  }
  ((struct run*)pa)->ref_count--;
  printf("%s: subref: %d, pa: %p \n",tip, ((struct run*)pa)->ref_count,pa); */
}
    80000aa2:	6422                	ld	s0,8(sp)
    80000aa4:	0141                	addi	sp,sp,16
    80000aa6:	8082                	ret

0000000080000aa8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000aa8:	1101                	addi	sp,sp,-32
    80000aaa:	ec06                	sd	ra,24(sp)
    80000aac:	e822                	sd	s0,16(sp)
    80000aae:	e426                	sd	s1,8(sp)
    80000ab0:	e04a                	sd	s2,0(sp)
    80000ab2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000ab4:	03451793          	slli	a5,a0,0x34
    80000ab8:	ef8d                	bnez	a5,80000af2 <kfree+0x4a>
    80000aba:	84aa                	mv	s1,a0
    80000abc:	00028797          	auipc	a5,0x28
    80000ac0:	44478793          	addi	a5,a5,1092 # 80028f00 <end>
    80000ac4:	02f56763          	bltu	a0,a5,80000af2 <kfree+0x4a>
    80000ac8:	47c5                	li	a5,17
    80000aca:	07ee                	slli	a5,a5,0x1b
    80000acc:	02f57363          	bgeu	a0,a5,80000af2 <kfree+0x4a>
  /** 
   * 
   * 大坑：一定要在kfree中减，因为其他很多程序也会调用kfree，如此一来，那些程序就无法kfree掉
   * 鸣谢：刘俊杰同学
   * */
  subref("kfree()", (void *) pa);
    80000ad0:	85aa                	mv	a1,a0
    80000ad2:	00006517          	auipc	a0,0x6
    80000ad6:	58e50513          	addi	a0,a0,1422 # 80007060 <digits+0x28>
    80000ada:	f85ff0ef          	jal	ra,80000a5e <subref>
  int ref_count = getref(pa);
    80000ade:	8526                	mv	a0,s1
    80000ae0:	f09ff0ef          	jal	ra,800009e8 <getref>
  if(ref_count == 0){
    80000ae4:	cd09                	beqz	a0,80000afe <kfree+0x56>
  // r->ref_count = 0;
  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock); */
}
    80000ae6:	60e2                	ld	ra,24(sp)
    80000ae8:	6442                	ld	s0,16(sp)
    80000aea:	64a2                	ld	s1,8(sp)
    80000aec:	6902                	ld	s2,0(sp)
    80000aee:	6105                	addi	sp,sp,32
    80000af0:	8082                	ret
    panic("kfree");
    80000af2:	00006517          	auipc	a0,0x6
    80000af6:	56650513          	addi	a0,a0,1382 # 80007058 <digits+0x20>
    80000afa:	c91ff0ef          	jal	ra,8000078a <panic>
    memset(pa, 1, PGSIZE);
    80000afe:	6605                	lui	a2,0x1
    80000b00:	4585                	li	a1,1
    80000b02:	8526                	mv	a0,s1
    80000b04:	2be000ef          	jal	ra,80000dc2 <memset>
    acquire(&kmem.lock);
    80000b08:	0000f917          	auipc	s2,0xf
    80000b0c:	ff090913          	addi	s2,s2,-16 # 8000faf8 <kmem>
    80000b10:	854a                	mv	a0,s2
    80000b12:	1dc000ef          	jal	ra,80000cee <acquire>
    r->next = kmem.freelist;
    80000b16:	01893783          	ld	a5,24(s2)
    80000b1a:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000b1c:	00993c23          	sd	s1,24(s2)
    release(&kmem.lock);
    80000b20:	854a                	mv	a0,s2
    80000b22:	264000ef          	jal	ra,80000d86 <release>
}
    80000b26:	b7c1                	j	80000ae6 <kfree+0x3e>

0000000080000b28 <freerange>:
{
    80000b28:	715d                	addi	sp,sp,-80
    80000b2a:	e486                	sd	ra,72(sp)
    80000b2c:	e0a2                	sd	s0,64(sp)
    80000b2e:	fc26                	sd	s1,56(sp)
    80000b30:	f84a                	sd	s2,48(sp)
    80000b32:	f44e                	sd	s3,40(sp)
    80000b34:	f052                	sd	s4,32(sp)
    80000b36:	ec56                	sd	s5,24(sp)
    80000b38:	e85a                	sd	s6,16(sp)
    80000b3a:	e45e                	sd	s7,8(sp)
    80000b3c:	0880                	addi	s0,sp,80
    80000b3e:	892e                	mv	s2,a1
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b40:	6985                	lui	s3,0x1
    80000b42:	fff98493          	addi	s1,s3,-1 # fff <_entry-0x7ffff001>
    80000b46:	94aa                	add	s1,s1,a0
    80000b48:	757d                	lui	a0,0xfffff
    80000b4a:	8ce9                	and	s1,s1,a0
  printf("start ~ end:%p ~ %p\n", p, pa_end);
    80000b4c:	862e                	mv	a2,a1
    80000b4e:	85a6                	mv	a1,s1
    80000b50:	00006517          	auipc	a0,0x6
    80000b54:	51850513          	addi	a0,a0,1304 # 80007068 <digits+0x30>
    80000b58:	96dff0ef          	jal	ra,800004c4 <printf>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000b5c:	94ce                	add	s1,s1,s3
    80000b5e:	04996363          	bltu	s2,s1,80000ba4 <freerange+0x7c>
    80000b62:	7a7d                	lui	s4,0xfffff
    reference[getrefindex(p)] = 0;
    80000b64:	0000fb97          	auipc	s7,0xf
    80000b68:	fb4b8b93          	addi	s7,s7,-76 # 8000fb18 <reference>
  int index = ((char*)pa - (char*)PGROUNDUP((uint64)end)) / PGSIZE;
    80000b6c:	6a85                	lui	s5,0x1
    80000b6e:	fffa8b13          	addi	s6,s5,-1 # fff <_entry-0x7ffff001>
    80000b72:	00029997          	auipc	s3,0x29
    80000b76:	38d98993          	addi	s3,s3,909 # 80029eff <end+0xfff>
    80000b7a:	0149f9b3          	and	s3,s3,s4
    80000b7e:	01448533          	add	a0,s1,s4
    80000b82:	41350733          	sub	a4,a0,s3
    80000b86:	43f75793          	srai	a5,a4,0x3f
    80000b8a:	0167f7b3          	and	a5,a5,s6
    80000b8e:	97ba                	add	a5,a5,a4
    80000b90:	87b1                	srai	a5,a5,0xc
    reference[getrefindex(p)] = 0;
    80000b92:	2781                	sext.w	a5,a5
    80000b94:	97de                	add	a5,a5,s7
    80000b96:	00078023          	sb	zero,0(a5)
    kfree(p);
    80000b9a:	f0fff0ef          	jal	ra,80000aa8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000b9e:	94d6                	add	s1,s1,s5
    80000ba0:	fc997fe3          	bgeu	s2,s1,80000b7e <freerange+0x56>
}
    80000ba4:	60a6                	ld	ra,72(sp)
    80000ba6:	6406                	ld	s0,64(sp)
    80000ba8:	74e2                	ld	s1,56(sp)
    80000baa:	7942                	ld	s2,48(sp)
    80000bac:	79a2                	ld	s3,40(sp)
    80000bae:	7a02                	ld	s4,32(sp)
    80000bb0:	6ae2                	ld	s5,24(sp)
    80000bb2:	6b42                	ld	s6,16(sp)
    80000bb4:	6ba2                	ld	s7,8(sp)
    80000bb6:	6161                	addi	sp,sp,80
    80000bb8:	8082                	ret

0000000080000bba <kinit>:
{
    80000bba:	1141                	addi	sp,sp,-16
    80000bbc:	e406                	sd	ra,8(sp)
    80000bbe:	e022                	sd	s0,0(sp)
    80000bc0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000bc2:	00006597          	auipc	a1,0x6
    80000bc6:	4be58593          	addi	a1,a1,1214 # 80007080 <digits+0x48>
    80000bca:	0000f517          	auipc	a0,0xf
    80000bce:	f2e50513          	addi	a0,a0,-210 # 8000faf8 <kmem>
    80000bd2:	09c000ef          	jal	ra,80000c6e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000bd6:	45c5                	li	a1,17
    80000bd8:	05ee                	slli	a1,a1,0x1b
    80000bda:	00028517          	auipc	a0,0x28
    80000bde:	32650513          	addi	a0,a0,806 # 80028f00 <end>
    80000be2:	f47ff0ef          	jal	ra,80000b28 <freerange>
}
    80000be6:	60a2                	ld	ra,8(sp)
    80000be8:	6402                	ld	s0,0(sp)
    80000bea:	0141                	addi	sp,sp,16
    80000bec:	8082                	ret

0000000080000bee <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000bee:	1101                	addi	sp,sp,-32
    80000bf0:	ec06                	sd	ra,24(sp)
    80000bf2:	e822                	sd	s0,16(sp)
    80000bf4:	e426                	sd	s1,8(sp)
    80000bf6:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000bf8:	0000f497          	auipc	s1,0xf
    80000bfc:	f0048493          	addi	s1,s1,-256 # 8000faf8 <kmem>
    80000c00:	8526                	mv	a0,s1
    80000c02:	0ec000ef          	jal	ra,80000cee <acquire>
  r = kmem.freelist;
    80000c06:	6c84                	ld	s1,24(s1)
  if(r)
    80000c08:	cca1                	beqz	s1,80000c60 <kalloc+0x72>
    kmem.freelist = r->next;
    80000c0a:	609c                	ld	a5,0(s1)
    80000c0c:	0000f517          	auipc	a0,0xf
    80000c10:	eec50513          	addi	a0,a0,-276 # 8000faf8 <kmem>
    80000c14:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000c16:	170000ef          	jal	ra,80000d86 <release>
  /** implementation of ref count  */
  /** r is the start of physical page  */
  if(r){
    //int ref_count = r->ref_count;
    //printf("r->ref_count: %d\n",ref_count);
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000c1a:	6605                	lui	a2,0x1
    80000c1c:	4595                	li	a1,5
    80000c1e:	8526                	mv	a0,s1
    80000c20:	1a2000ef          	jal	ra,80000dc2 <memset>
  int index = ((char*)pa - (char*)PGROUNDUP((uint64)end)) / PGSIZE;
    80000c24:	00029797          	auipc	a5,0x29
    80000c28:	2db78793          	addi	a5,a5,731 # 80029eff <end+0xfff>
    80000c2c:	777d                	lui	a4,0xfffff
    80000c2e:	8ff9                	and	a5,a5,a4
    80000c30:	40f48733          	sub	a4,s1,a5
    80000c34:	43f75793          	srai	a5,a4,0x3f
    80000c38:	6685                	lui	a3,0x1
    80000c3a:	16fd                	addi	a3,a3,-1
    80000c3c:	8ff5                	and	a5,a5,a3
    80000c3e:	97ba                	add	a5,a5,a4
    80000c40:	87b1                	srai	a5,a5,0xc
    int index = getrefindex((void *)r);
    reference[index] = 1;
    80000c42:	2781                	sext.w	a5,a5
    80000c44:	0000f717          	auipc	a4,0xf
    80000c48:	ed470713          	addi	a4,a4,-300 # 8000fb18 <reference>
    80000c4c:	97ba                	add	a5,a5,a4
    80000c4e:	4705                	li	a4,1
    80000c50:	00e78023          	sb	a4,0(a5)
    //r->ref_count = ref_count + 1; 
    //printf("r->ref_count: %d\n",ref_count);  
  }
  /** r出去后会被修改 */
  return (void*)r;
}
    80000c54:	8526                	mv	a0,s1
    80000c56:	60e2                	ld	ra,24(sp)
    80000c58:	6442                	ld	s0,16(sp)
    80000c5a:	64a2                	ld	s1,8(sp)
    80000c5c:	6105                	addi	sp,sp,32
    80000c5e:	8082                	ret
  release(&kmem.lock);
    80000c60:	0000f517          	auipc	a0,0xf
    80000c64:	e9850513          	addi	a0,a0,-360 # 8000faf8 <kmem>
    80000c68:	11e000ef          	jal	ra,80000d86 <release>
  if(r){
    80000c6c:	b7e5                	j	80000c54 <kalloc+0x66>

0000000080000c6e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c6e:	1141                	addi	sp,sp,-16
    80000c70:	e422                	sd	s0,8(sp)
    80000c72:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c74:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c76:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c7a:	00053823          	sd	zero,16(a0)
}
    80000c7e:	6422                	ld	s0,8(sp)
    80000c80:	0141                	addi	sp,sp,16
    80000c82:	8082                	ret

0000000080000c84 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c84:	411c                	lw	a5,0(a0)
    80000c86:	e399                	bnez	a5,80000c8c <holding+0x8>
    80000c88:	4501                	li	a0,0
  return r;
}
    80000c8a:	8082                	ret
{
    80000c8c:	1101                	addi	sp,sp,-32
    80000c8e:	ec06                	sd	ra,24(sp)
    80000c90:	e822                	sd	s0,16(sp)
    80000c92:	e426                	sd	s1,8(sp)
    80000c94:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c96:	6904                	ld	s1,16(a0)
    80000c98:	567000ef          	jal	ra,800019fe <mycpu>
    80000c9c:	40a48533          	sub	a0,s1,a0
    80000ca0:	00153513          	seqz	a0,a0
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret

0000000080000cae <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000cae:	1101                	addi	sp,sp,-32
    80000cb0:	ec06                	sd	ra,24(sp)
    80000cb2:	e822                	sd	s0,16(sp)
    80000cb4:	e426                	sd	s1,8(sp)
    80000cb6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb8:	100024f3          	csrr	s1,sstatus
    80000cbc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cc0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cc2:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80000cc6:	539000ef          	jal	ra,800019fe <mycpu>
    80000cca:	5d3c                	lw	a5,120(a0)
    80000ccc:	cb99                	beqz	a5,80000ce2 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cce:	531000ef          	jal	ra,800019fe <mycpu>
    80000cd2:	5d3c                	lw	a5,120(a0)
    80000cd4:	2785                	addiw	a5,a5,1
    80000cd6:	dd3c                	sw	a5,120(a0)
}
    80000cd8:	60e2                	ld	ra,24(sp)
    80000cda:	6442                	ld	s0,16(sp)
    80000cdc:	64a2                	ld	s1,8(sp)
    80000cde:	6105                	addi	sp,sp,32
    80000ce0:	8082                	ret
    mycpu()->intena = old;
    80000ce2:	51d000ef          	jal	ra,800019fe <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000ce6:	8085                	srli	s1,s1,0x1
    80000ce8:	8885                	andi	s1,s1,1
    80000cea:	dd64                	sw	s1,124(a0)
    80000cec:	b7cd                	j	80000cce <push_off+0x20>

0000000080000cee <acquire>:
{
    80000cee:	1101                	addi	sp,sp,-32
    80000cf0:	ec06                	sd	ra,24(sp)
    80000cf2:	e822                	sd	s0,16(sp)
    80000cf4:	e426                	sd	s1,8(sp)
    80000cf6:	1000                	addi	s0,sp,32
    80000cf8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cfa:	fb5ff0ef          	jal	ra,80000cae <push_off>
  if(holding(lk))
    80000cfe:	8526                	mv	a0,s1
    80000d00:	f85ff0ef          	jal	ra,80000c84 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d04:	4705                	li	a4,1
  if(holding(lk))
    80000d06:	e105                	bnez	a0,80000d26 <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d08:	87ba                	mv	a5,a4
    80000d0a:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d0e:	2781                	sext.w	a5,a5
    80000d10:	ffe5                	bnez	a5,80000d08 <acquire+0x1a>
  __sync_synchronize();
    80000d12:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d16:	4e9000ef          	jal	ra,800019fe <mycpu>
    80000d1a:	e888                	sd	a0,16(s1)
}
    80000d1c:	60e2                	ld	ra,24(sp)
    80000d1e:	6442                	ld	s0,16(sp)
    80000d20:	64a2                	ld	s1,8(sp)
    80000d22:	6105                	addi	sp,sp,32
    80000d24:	8082                	ret
    panic("acquire");
    80000d26:	00006517          	auipc	a0,0x6
    80000d2a:	36250513          	addi	a0,a0,866 # 80007088 <digits+0x50>
    80000d2e:	a5dff0ef          	jal	ra,8000078a <panic>

0000000080000d32 <pop_off>:

void
pop_off(void)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e406                	sd	ra,8(sp)
    80000d36:	e022                	sd	s0,0(sp)
    80000d38:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d3a:	4c5000ef          	jal	ra,800019fe <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d3e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d42:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d44:	e78d                	bnez	a5,80000d6e <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d46:	5d3c                	lw	a5,120(a0)
    80000d48:	02f05963          	blez	a5,80000d7a <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    80000d4c:	37fd                	addiw	a5,a5,-1
    80000d4e:	0007871b          	sext.w	a4,a5
    80000d52:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d54:	eb09                	bnez	a4,80000d66 <pop_off+0x34>
    80000d56:	5d7c                	lw	a5,124(a0)
    80000d58:	c799                	beqz	a5,80000d66 <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d5a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d5e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d62:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d66:	60a2                	ld	ra,8(sp)
    80000d68:	6402                	ld	s0,0(sp)
    80000d6a:	0141                	addi	sp,sp,16
    80000d6c:	8082                	ret
    panic("pop_off - interruptible");
    80000d6e:	00006517          	auipc	a0,0x6
    80000d72:	32250513          	addi	a0,a0,802 # 80007090 <digits+0x58>
    80000d76:	a15ff0ef          	jal	ra,8000078a <panic>
    panic("pop_off");
    80000d7a:	00006517          	auipc	a0,0x6
    80000d7e:	32e50513          	addi	a0,a0,814 # 800070a8 <digits+0x70>
    80000d82:	a09ff0ef          	jal	ra,8000078a <panic>

0000000080000d86 <release>:
{
    80000d86:	1101                	addi	sp,sp,-32
    80000d88:	ec06                	sd	ra,24(sp)
    80000d8a:	e822                	sd	s0,16(sp)
    80000d8c:	e426                	sd	s1,8(sp)
    80000d8e:	1000                	addi	s0,sp,32
    80000d90:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d92:	ef3ff0ef          	jal	ra,80000c84 <holding>
    80000d96:	c105                	beqz	a0,80000db6 <release+0x30>
  lk->cpu = 0;
    80000d98:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d9c:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000da0:	0f50000f          	fence	iorw,ow
    80000da4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000da8:	f8bff0ef          	jal	ra,80000d32 <pop_off>
}
    80000dac:	60e2                	ld	ra,24(sp)
    80000dae:	6442                	ld	s0,16(sp)
    80000db0:	64a2                	ld	s1,8(sp)
    80000db2:	6105                	addi	sp,sp,32
    80000db4:	8082                	ret
    panic("release");
    80000db6:	00006517          	auipc	a0,0x6
    80000dba:	2fa50513          	addi	a0,a0,762 # 800070b0 <digits+0x78>
    80000dbe:	9cdff0ef          	jal	ra,8000078a <panic>

0000000080000dc2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000dc2:	1141                	addi	sp,sp,-16
    80000dc4:	e422                	sd	s0,8(sp)
    80000dc6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000dc8:	ca19                	beqz	a2,80000dde <memset+0x1c>
    80000dca:	87aa                	mv	a5,a0
    80000dcc:	1602                	slli	a2,a2,0x20
    80000dce:	9201                	srli	a2,a2,0x20
    80000dd0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000dd4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000dd8:	0785                	addi	a5,a5,1
    80000dda:	fee79de3          	bne	a5,a4,80000dd4 <memset+0x12>
  }
  return dst;
}
    80000dde:	6422                	ld	s0,8(sp)
    80000de0:	0141                	addi	sp,sp,16
    80000de2:	8082                	ret

0000000080000de4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000de4:	1141                	addi	sp,sp,-16
    80000de6:	e422                	sd	s0,8(sp)
    80000de8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dea:	ca05                	beqz	a2,80000e1a <memcmp+0x36>
    80000dec:	fff6069b          	addiw	a3,a2,-1
    80000df0:	1682                	slli	a3,a3,0x20
    80000df2:	9281                	srli	a3,a3,0x20
    80000df4:	0685                	addi	a3,a3,1
    80000df6:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000df8:	00054783          	lbu	a5,0(a0)
    80000dfc:	0005c703          	lbu	a4,0(a1)
    80000e00:	00e79863          	bne	a5,a4,80000e10 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e04:	0505                	addi	a0,a0,1
    80000e06:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e08:	fed518e3          	bne	a0,a3,80000df8 <memcmp+0x14>
  }

  return 0;
    80000e0c:	4501                	li	a0,0
    80000e0e:	a019                	j	80000e14 <memcmp+0x30>
      return *s1 - *s2;
    80000e10:	40e7853b          	subw	a0,a5,a4
}
    80000e14:	6422                	ld	s0,8(sp)
    80000e16:	0141                	addi	sp,sp,16
    80000e18:	8082                	ret
  return 0;
    80000e1a:	4501                	li	a0,0
    80000e1c:	bfe5                	j	80000e14 <memcmp+0x30>

0000000080000e1e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e1e:	1141                	addi	sp,sp,-16
    80000e20:	e422                	sd	s0,8(sp)
    80000e22:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e24:	c205                	beqz	a2,80000e44 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e26:	02a5e263          	bltu	a1,a0,80000e4a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e2a:	1602                	slli	a2,a2,0x20
    80000e2c:	9201                	srli	a2,a2,0x20
    80000e2e:	00c587b3          	add	a5,a1,a2
{
    80000e32:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e34:	0585                	addi	a1,a1,1
    80000e36:	0705                	addi	a4,a4,1
    80000e38:	fff5c683          	lbu	a3,-1(a1)
    80000e3c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e40:	fef59ae3          	bne	a1,a5,80000e34 <memmove+0x16>

  return dst;
}
    80000e44:	6422                	ld	s0,8(sp)
    80000e46:	0141                	addi	sp,sp,16
    80000e48:	8082                	ret
  if(s < d && s + n > d){
    80000e4a:	02061693          	slli	a3,a2,0x20
    80000e4e:	9281                	srli	a3,a3,0x20
    80000e50:	00d58733          	add	a4,a1,a3
    80000e54:	fce57be3          	bgeu	a0,a4,80000e2a <memmove+0xc>
    d += n;
    80000e58:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e5a:	fff6079b          	addiw	a5,a2,-1
    80000e5e:	1782                	slli	a5,a5,0x20
    80000e60:	9381                	srli	a5,a5,0x20
    80000e62:	fff7c793          	not	a5,a5
    80000e66:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e68:	177d                	addi	a4,a4,-1
    80000e6a:	16fd                	addi	a3,a3,-1
    80000e6c:	00074603          	lbu	a2,0(a4)
    80000e70:	00c68023          	sb	a2,0(a3) # 1000 <_entry-0x7ffff000>
    while(n-- > 0)
    80000e74:	fee79ae3          	bne	a5,a4,80000e68 <memmove+0x4a>
    80000e78:	b7f1                	j	80000e44 <memmove+0x26>

0000000080000e7a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e7a:	1141                	addi	sp,sp,-16
    80000e7c:	e406                	sd	ra,8(sp)
    80000e7e:	e022                	sd	s0,0(sp)
    80000e80:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e82:	f9dff0ef          	jal	ra,80000e1e <memmove>
}
    80000e86:	60a2                	ld	ra,8(sp)
    80000e88:	6402                	ld	s0,0(sp)
    80000e8a:	0141                	addi	sp,sp,16
    80000e8c:	8082                	ret

0000000080000e8e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e422                	sd	s0,8(sp)
    80000e92:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e94:	ce11                	beqz	a2,80000eb0 <strncmp+0x22>
    80000e96:	00054783          	lbu	a5,0(a0)
    80000e9a:	cf89                	beqz	a5,80000eb4 <strncmp+0x26>
    80000e9c:	0005c703          	lbu	a4,0(a1)
    80000ea0:	00f71a63          	bne	a4,a5,80000eb4 <strncmp+0x26>
    n--, p++, q++;
    80000ea4:	367d                	addiw	a2,a2,-1
    80000ea6:	0505                	addi	a0,a0,1
    80000ea8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000eaa:	f675                	bnez	a2,80000e96 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000eac:	4501                	li	a0,0
    80000eae:	a809                	j	80000ec0 <strncmp+0x32>
    80000eb0:	4501                	li	a0,0
    80000eb2:	a039                	j	80000ec0 <strncmp+0x32>
  if(n == 0)
    80000eb4:	ca09                	beqz	a2,80000ec6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000eb6:	00054503          	lbu	a0,0(a0)
    80000eba:	0005c783          	lbu	a5,0(a1)
    80000ebe:	9d1d                	subw	a0,a0,a5
}
    80000ec0:	6422                	ld	s0,8(sp)
    80000ec2:	0141                	addi	sp,sp,16
    80000ec4:	8082                	ret
    return 0;
    80000ec6:	4501                	li	a0,0
    80000ec8:	bfe5                	j	80000ec0 <strncmp+0x32>

0000000080000eca <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000eca:	1141                	addi	sp,sp,-16
    80000ecc:	e422                	sd	s0,8(sp)
    80000ece:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ed0:	872a                	mv	a4,a0
    80000ed2:	8832                	mv	a6,a2
    80000ed4:	367d                	addiw	a2,a2,-1
    80000ed6:	01005963          	blez	a6,80000ee8 <strncpy+0x1e>
    80000eda:	0705                	addi	a4,a4,1
    80000edc:	0005c783          	lbu	a5,0(a1)
    80000ee0:	fef70fa3          	sb	a5,-1(a4)
    80000ee4:	0585                	addi	a1,a1,1
    80000ee6:	f7f5                	bnez	a5,80000ed2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ee8:	86ba                	mv	a3,a4
    80000eea:	00c05c63          	blez	a2,80000f02 <strncpy+0x38>
    *s++ = 0;
    80000eee:	0685                	addi	a3,a3,1
    80000ef0:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000ef4:	fff6c793          	not	a5,a3
    80000ef8:	9fb9                	addw	a5,a5,a4
    80000efa:	010787bb          	addw	a5,a5,a6
    80000efe:	fef048e3          	bgtz	a5,80000eee <strncpy+0x24>
  return os;
}
    80000f02:	6422                	ld	s0,8(sp)
    80000f04:	0141                	addi	sp,sp,16
    80000f06:	8082                	ret

0000000080000f08 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f08:	1141                	addi	sp,sp,-16
    80000f0a:	e422                	sd	s0,8(sp)
    80000f0c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f0e:	02c05363          	blez	a2,80000f34 <safestrcpy+0x2c>
    80000f12:	fff6069b          	addiw	a3,a2,-1
    80000f16:	1682                	slli	a3,a3,0x20
    80000f18:	9281                	srli	a3,a3,0x20
    80000f1a:	96ae                	add	a3,a3,a1
    80000f1c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f1e:	00d58963          	beq	a1,a3,80000f30 <safestrcpy+0x28>
    80000f22:	0585                	addi	a1,a1,1
    80000f24:	0785                	addi	a5,a5,1
    80000f26:	fff5c703          	lbu	a4,-1(a1)
    80000f2a:	fee78fa3          	sb	a4,-1(a5)
    80000f2e:	fb65                	bnez	a4,80000f1e <safestrcpy+0x16>
    ;
  *s = 0;
    80000f30:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f34:	6422                	ld	s0,8(sp)
    80000f36:	0141                	addi	sp,sp,16
    80000f38:	8082                	ret

0000000080000f3a <strlen>:

int
strlen(const char *s)
{
    80000f3a:	1141                	addi	sp,sp,-16
    80000f3c:	e422                	sd	s0,8(sp)
    80000f3e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f40:	00054783          	lbu	a5,0(a0)
    80000f44:	cf91                	beqz	a5,80000f60 <strlen+0x26>
    80000f46:	0505                	addi	a0,a0,1
    80000f48:	87aa                	mv	a5,a0
    80000f4a:	4685                	li	a3,1
    80000f4c:	9e89                	subw	a3,a3,a0
    80000f4e:	00f6853b          	addw	a0,a3,a5
    80000f52:	0785                	addi	a5,a5,1
    80000f54:	fff7c703          	lbu	a4,-1(a5)
    80000f58:	fb7d                	bnez	a4,80000f4e <strlen+0x14>
    ;
  return n;
}
    80000f5a:	6422                	ld	s0,8(sp)
    80000f5c:	0141                	addi	sp,sp,16
    80000f5e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f60:	4501                	li	a0,0
    80000f62:	bfe5                	j	80000f5a <strlen+0x20>

0000000080000f64 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f64:	1141                	addi	sp,sp,-16
    80000f66:	e406                	sd	ra,8(sp)
    80000f68:	e022                	sd	s0,0(sp)
    80000f6a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f6c:	283000ef          	jal	ra,800019ee <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f70:	00007717          	auipc	a4,0x7
    80000f74:	a9070713          	addi	a4,a4,-1392 # 80007a00 <started>
  if(cpuid() == 0){
    80000f78:	c51d                	beqz	a0,80000fa6 <main+0x42>
    while(started == 0)
    80000f7a:	431c                	lw	a5,0(a4)
    80000f7c:	2781                	sext.w	a5,a5
    80000f7e:	dff5                	beqz	a5,80000f7a <main+0x16>
      ;
    __sync_synchronize();
    80000f80:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f84:	26b000ef          	jal	ra,800019ee <cpuid>
    80000f88:	85aa                	mv	a1,a0
    80000f8a:	00006517          	auipc	a0,0x6
    80000f8e:	14650513          	addi	a0,a0,326 # 800070d0 <digits+0x98>
    80000f92:	d32ff0ef          	jal	ra,800004c4 <printf>
    kvminithart();    // turn on paging
    80000f96:	080000ef          	jal	ra,80001016 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f9a:	64c010ef          	jal	ra,800025e6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f9e:	656040ef          	jal	ra,800055f4 <plicinithart>
  }

  scheduler();        
    80000fa2:	6f3000ef          	jal	ra,80001e94 <scheduler>
    consoleinit();
    80000fa6:	c46ff0ef          	jal	ra,800003ec <consoleinit>
    printfinit();
    80000faa:	81dff0ef          	jal	ra,800007c6 <printfinit>
    printf("\n");
    80000fae:	00006517          	auipc	a0,0x6
    80000fb2:	4c250513          	addi	a0,a0,1218 # 80007470 <states.0+0x140>
    80000fb6:	d0eff0ef          	jal	ra,800004c4 <printf>
    printf("xv6 kernel is booting\n");
    80000fba:	00006517          	auipc	a0,0x6
    80000fbe:	0fe50513          	addi	a0,a0,254 # 800070b8 <digits+0x80>
    80000fc2:	d02ff0ef          	jal	ra,800004c4 <printf>
    printf("\n");
    80000fc6:	00006517          	auipc	a0,0x6
    80000fca:	4aa50513          	addi	a0,a0,1194 # 80007470 <states.0+0x140>
    80000fce:	cf6ff0ef          	jal	ra,800004c4 <printf>
    kinit();         // physical page allocator
    80000fd2:	be9ff0ef          	jal	ra,80000bba <kinit>
    kvminit();       // create kernel page table
    80000fd6:	2d0000ef          	jal	ra,800012a6 <kvminit>
    kvminithart();   // turn on paging
    80000fda:	03c000ef          	jal	ra,80001016 <kvminithart>
    procinit();      // process table
    80000fde:	169000ef          	jal	ra,80001946 <procinit>
    trapinit();      // trap vectors
    80000fe2:	5e0010ef          	jal	ra,800025c2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fe6:	600010ef          	jal	ra,800025e6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fea:	5f4040ef          	jal	ra,800055de <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fee:	606040ef          	jal	ra,800055f4 <plicinithart>
    binit();         // buffer cache
    80000ff2:	5a5010ef          	jal	ra,80002d96 <binit>
    iinit();         // inode table
    80000ff6:	318020ef          	jal	ra,8000330e <iinit>
    fileinit();      // file table
    80000ffa:	1f8030ef          	jal	ra,800041f2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ffe:	6e6040ef          	jal	ra,800056e4 <virtio_disk_init>
    userinit();      // first user process
    80001002:	4e9000ef          	jal	ra,80001cea <userinit>
    __sync_synchronize();
    80001006:	0ff0000f          	fence
    started = 1;
    8000100a:	4785                	li	a5,1
    8000100c:	00007717          	auipc	a4,0x7
    80001010:	9ef72a23          	sw	a5,-1548(a4) # 80007a00 <started>
    80001014:	b779                	j	80000fa2 <main+0x3e>

0000000080001016 <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80001016:	1141                	addi	sp,sp,-16
    80001018:	e422                	sd	s0,8(sp)
    8000101a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000101c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001020:	00007797          	auipc	a5,0x7
    80001024:	9e87b783          	ld	a5,-1560(a5) # 80007a08 <kernel_pagetable>
    80001028:	83b1                	srli	a5,a5,0xc
    8000102a:	577d                	li	a4,-1
    8000102c:	177e                	slli	a4,a4,0x3f
    8000102e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001030:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001034:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001038:	6422                	ld	s0,8(sp)
    8000103a:	0141                	addi	sp,sp,16
    8000103c:	8082                	ret

000000008000103e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000103e:	7139                	addi	sp,sp,-64
    80001040:	fc06                	sd	ra,56(sp)
    80001042:	f822                	sd	s0,48(sp)
    80001044:	f426                	sd	s1,40(sp)
    80001046:	f04a                	sd	s2,32(sp)
    80001048:	ec4e                	sd	s3,24(sp)
    8000104a:	e852                	sd	s4,16(sp)
    8000104c:	e456                	sd	s5,8(sp)
    8000104e:	e05a                	sd	s6,0(sp)
    80001050:	0080                	addi	s0,sp,64
    80001052:	84aa                	mv	s1,a0
    80001054:	89ae                	mv	s3,a1
    80001056:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001058:	57fd                	li	a5,-1
    8000105a:	83e9                	srli	a5,a5,0x1a
    8000105c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000105e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001060:	02b7fc63          	bgeu	a5,a1,80001098 <walk+0x5a>
    panic("walk");
    80001064:	00006517          	auipc	a0,0x6
    80001068:	08450513          	addi	a0,a0,132 # 800070e8 <digits+0xb0>
    8000106c:	f1eff0ef          	jal	ra,8000078a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001070:	060a8263          	beqz	s5,800010d4 <walk+0x96>
    80001074:	b7bff0ef          	jal	ra,80000bee <kalloc>
    80001078:	84aa                	mv	s1,a0
    8000107a:	c139                	beqz	a0,800010c0 <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000107c:	6605                	lui	a2,0x1
    8000107e:	4581                	li	a1,0
    80001080:	d43ff0ef          	jal	ra,80000dc2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001084:	00c4d793          	srli	a5,s1,0xc
    80001088:	07aa                	slli	a5,a5,0xa
    8000108a:	0017e793          	ori	a5,a5,1
    8000108e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001092:	3a5d                	addiw	s4,s4,-9
    80001094:	036a0063          	beq	s4,s6,800010b4 <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    80001098:	0149d933          	srl	s2,s3,s4
    8000109c:	1ff97913          	andi	s2,s2,511
    800010a0:	090e                	slli	s2,s2,0x3
    800010a2:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010a4:	00093483          	ld	s1,0(s2)
    800010a8:	0014f793          	andi	a5,s1,1
    800010ac:	d3f1                	beqz	a5,80001070 <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010ae:	80a9                	srli	s1,s1,0xa
    800010b0:	04b2                	slli	s1,s1,0xc
    800010b2:	b7c5                	j	80001092 <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    800010b4:	00c9d513          	srli	a0,s3,0xc
    800010b8:	1ff57513          	andi	a0,a0,511
    800010bc:	050e                	slli	a0,a0,0x3
    800010be:	9526                	add	a0,a0,s1
}
    800010c0:	70e2                	ld	ra,56(sp)
    800010c2:	7442                	ld	s0,48(sp)
    800010c4:	74a2                	ld	s1,40(sp)
    800010c6:	7902                	ld	s2,32(sp)
    800010c8:	69e2                	ld	s3,24(sp)
    800010ca:	6a42                	ld	s4,16(sp)
    800010cc:	6aa2                	ld	s5,8(sp)
    800010ce:	6b02                	ld	s6,0(sp)
    800010d0:	6121                	addi	sp,sp,64
    800010d2:	8082                	ret
        return 0;
    800010d4:	4501                	li	a0,0
    800010d6:	b7ed                	j	800010c0 <walk+0x82>

00000000800010d8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010d8:	57fd                	li	a5,-1
    800010da:	83e9                	srli	a5,a5,0x1a
    800010dc:	00b7f463          	bgeu	a5,a1,800010e4 <walkaddr+0xc>
    return 0;
    800010e0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010e2:	8082                	ret
{
    800010e4:	1141                	addi	sp,sp,-16
    800010e6:	e406                	sd	ra,8(sp)
    800010e8:	e022                	sd	s0,0(sp)
    800010ea:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ec:	4601                	li	a2,0
    800010ee:	f51ff0ef          	jal	ra,8000103e <walk>
  if(pte == 0)
    800010f2:	c105                	beqz	a0,80001112 <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    800010f4:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010f6:	0117f693          	andi	a3,a5,17
    800010fa:	4745                	li	a4,17
    return 0;
    800010fc:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010fe:	00e68663          	beq	a3,a4,8000110a <walkaddr+0x32>
}
    80001102:	60a2                	ld	ra,8(sp)
    80001104:	6402                	ld	s0,0(sp)
    80001106:	0141                	addi	sp,sp,16
    80001108:	8082                	ret
  pa = PTE2PA(*pte);
    8000110a:	00a7d513          	srli	a0,a5,0xa
    8000110e:	0532                	slli	a0,a0,0xc
  return pa;
    80001110:	bfcd                	j	80001102 <walkaddr+0x2a>
    return 0;
    80001112:	4501                	li	a0,0
    80001114:	b7fd                	j	80001102 <walkaddr+0x2a>

0000000080001116 <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001116:	715d                	addi	sp,sp,-80
    80001118:	e486                	sd	ra,72(sp)
    8000111a:	e0a2                	sd	s0,64(sp)
    8000111c:	fc26                	sd	s1,56(sp)
    8000111e:	f84a                	sd	s2,48(sp)
    80001120:	f44e                	sd	s3,40(sp)
    80001122:	f052                	sd	s4,32(sp)
    80001124:	ec56                	sd	s5,24(sp)
    80001126:	e85a                	sd	s6,16(sp)
    80001128:	e45e                	sd	s7,8(sp)
    8000112a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000112c:	03459793          	slli	a5,a1,0x34
    80001130:	eba1                	bnez	a5,80001180 <mappages+0x6a>
    80001132:	8aaa                	mv	s5,a0
    80001134:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    80001136:	03461793          	slli	a5,a2,0x34
    8000113a:	eba9                	bnez	a5,8000118c <mappages+0x76>
    panic("mappages: size not aligned");

  if(size == 0)
    8000113c:	ce31                	beqz	a2,80001198 <mappages+0x82>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    8000113e:	79fd                	lui	s3,0xfffff
    80001140:	964e                	add	a2,a2,s3
    80001142:	00b609b3          	add	s3,a2,a1
  a = va;
    80001146:	892e                	mv	s2,a1
    80001148:	40b68a33          	sub	s4,a3,a1
    if((*pte & PTE_COW) == 0 &&  *pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000114c:	6b85                	lui	s7,0x1
    8000114e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001152:	4605                	li	a2,1
    80001154:	85ca                	mv	a1,s2
    80001156:	8556                	mv	a0,s5
    80001158:	ee7ff0ef          	jal	ra,8000103e <walk>
    8000115c:	c931                	beqz	a0,800011b0 <mappages+0x9a>
    if((*pte & PTE_COW) == 0 &&  *pte & PTE_V)
    8000115e:	611c                	ld	a5,0(a0)
    80001160:	1017f793          	andi	a5,a5,257
    80001164:	4705                	li	a4,1
    80001166:	02e78f63          	beq	a5,a4,800011a4 <mappages+0x8e>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000116a:	80b1                	srli	s1,s1,0xc
    8000116c:	04aa                	slli	s1,s1,0xa
    8000116e:	0164e4b3          	or	s1,s1,s6
    80001172:	0014e493          	ori	s1,s1,1
    80001176:	e104                	sd	s1,0(a0)
    if(a == last)
    80001178:	05390863          	beq	s2,s3,800011c8 <mappages+0xb2>
    a += PGSIZE;
    8000117c:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000117e:	bfc1                	j	8000114e <mappages+0x38>
    panic("mappages: va not aligned");
    80001180:	00006517          	auipc	a0,0x6
    80001184:	f7050513          	addi	a0,a0,-144 # 800070f0 <digits+0xb8>
    80001188:	e02ff0ef          	jal	ra,8000078a <panic>
    panic("mappages: size not aligned");
    8000118c:	00006517          	auipc	a0,0x6
    80001190:	f8450513          	addi	a0,a0,-124 # 80007110 <digits+0xd8>
    80001194:	df6ff0ef          	jal	ra,8000078a <panic>
    panic("mappages: size");
    80001198:	00006517          	auipc	a0,0x6
    8000119c:	f9850513          	addi	a0,a0,-104 # 80007130 <digits+0xf8>
    800011a0:	deaff0ef          	jal	ra,8000078a <panic>
      panic("mappages: remap");
    800011a4:	00006517          	auipc	a0,0x6
    800011a8:	f9c50513          	addi	a0,a0,-100 # 80007140 <digits+0x108>
    800011ac:	ddeff0ef          	jal	ra,8000078a <panic>
      return -1;
    800011b0:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011b2:	60a6                	ld	ra,72(sp)
    800011b4:	6406                	ld	s0,64(sp)
    800011b6:	74e2                	ld	s1,56(sp)
    800011b8:	7942                	ld	s2,48(sp)
    800011ba:	79a2                	ld	s3,40(sp)
    800011bc:	7a02                	ld	s4,32(sp)
    800011be:	6ae2                	ld	s5,24(sp)
    800011c0:	6b42                	ld	s6,16(sp)
    800011c2:	6ba2                	ld	s7,8(sp)
    800011c4:	6161                	addi	sp,sp,80
    800011c6:	8082                	ret
  return 0;
    800011c8:	4501                	li	a0,0
    800011ca:	b7e5                	j	800011b2 <mappages+0x9c>

00000000800011cc <kvmmap>:
{
    800011cc:	1141                	addi	sp,sp,-16
    800011ce:	e406                	sd	ra,8(sp)
    800011d0:	e022                	sd	s0,0(sp)
    800011d2:	0800                	addi	s0,sp,16
    800011d4:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011d6:	86b2                	mv	a3,a2
    800011d8:	863e                	mv	a2,a5
    800011da:	f3dff0ef          	jal	ra,80001116 <mappages>
    800011de:	e509                	bnez	a0,800011e8 <kvmmap+0x1c>
}
    800011e0:	60a2                	ld	ra,8(sp)
    800011e2:	6402                	ld	s0,0(sp)
    800011e4:	0141                	addi	sp,sp,16
    800011e6:	8082                	ret
    panic("kvmmap");
    800011e8:	00006517          	auipc	a0,0x6
    800011ec:	f6850513          	addi	a0,a0,-152 # 80007150 <digits+0x118>
    800011f0:	d9aff0ef          	jal	ra,8000078a <panic>

00000000800011f4 <kvmmake>:
{
    800011f4:	1101                	addi	sp,sp,-32
    800011f6:	ec06                	sd	ra,24(sp)
    800011f8:	e822                	sd	s0,16(sp)
    800011fa:	e426                	sd	s1,8(sp)
    800011fc:	e04a                	sd	s2,0(sp)
    800011fe:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001200:	9efff0ef          	jal	ra,80000bee <kalloc>
    80001204:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001206:	6605                	lui	a2,0x1
    80001208:	4581                	li	a1,0
    8000120a:	bb9ff0ef          	jal	ra,80000dc2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000120e:	4719                	li	a4,6
    80001210:	6685                	lui	a3,0x1
    80001212:	10000637          	lui	a2,0x10000
    80001216:	100005b7          	lui	a1,0x10000
    8000121a:	8526                	mv	a0,s1
    8000121c:	fb1ff0ef          	jal	ra,800011cc <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001220:	4719                	li	a4,6
    80001222:	6685                	lui	a3,0x1
    80001224:	10001637          	lui	a2,0x10001
    80001228:	100015b7          	lui	a1,0x10001
    8000122c:	8526                	mv	a0,s1
    8000122e:	f9fff0ef          	jal	ra,800011cc <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    80001232:	4719                	li	a4,6
    80001234:	040006b7          	lui	a3,0x4000
    80001238:	0c000637          	lui	a2,0xc000
    8000123c:	0c0005b7          	lui	a1,0xc000
    80001240:	8526                	mv	a0,s1
    80001242:	f8bff0ef          	jal	ra,800011cc <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001246:	00006917          	auipc	s2,0x6
    8000124a:	dba90913          	addi	s2,s2,-582 # 80007000 <etext>
    8000124e:	4729                	li	a4,10
    80001250:	80006697          	auipc	a3,0x80006
    80001254:	db068693          	addi	a3,a3,-592 # 7000 <_entry-0x7fff9000>
    80001258:	4605                	li	a2,1
    8000125a:	067e                	slli	a2,a2,0x1f
    8000125c:	85b2                	mv	a1,a2
    8000125e:	8526                	mv	a0,s1
    80001260:	f6dff0ef          	jal	ra,800011cc <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001264:	4719                	li	a4,6
    80001266:	46c5                	li	a3,17
    80001268:	06ee                	slli	a3,a3,0x1b
    8000126a:	412686b3          	sub	a3,a3,s2
    8000126e:	864a                	mv	a2,s2
    80001270:	85ca                	mv	a1,s2
    80001272:	8526                	mv	a0,s1
    80001274:	f59ff0ef          	jal	ra,800011cc <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001278:	4729                	li	a4,10
    8000127a:	6685                	lui	a3,0x1
    8000127c:	00005617          	auipc	a2,0x5
    80001280:	d8460613          	addi	a2,a2,-636 # 80006000 <_trampoline>
    80001284:	040005b7          	lui	a1,0x4000
    80001288:	15fd                	addi	a1,a1,-1
    8000128a:	05b2                	slli	a1,a1,0xc
    8000128c:	8526                	mv	a0,s1
    8000128e:	f3fff0ef          	jal	ra,800011cc <kvmmap>
  proc_mapstacks(kpgtbl);
    80001292:	8526                	mv	a0,s1
    80001294:	628000ef          	jal	ra,800018bc <proc_mapstacks>
}
    80001298:	8526                	mv	a0,s1
    8000129a:	60e2                	ld	ra,24(sp)
    8000129c:	6442                	ld	s0,16(sp)
    8000129e:	64a2                	ld	s1,8(sp)
    800012a0:	6902                	ld	s2,0(sp)
    800012a2:	6105                	addi	sp,sp,32
    800012a4:	8082                	ret

00000000800012a6 <kvminit>:
{
    800012a6:	1141                	addi	sp,sp,-16
    800012a8:	e406                	sd	ra,8(sp)
    800012aa:	e022                	sd	s0,0(sp)
    800012ac:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012ae:	f47ff0ef          	jal	ra,800011f4 <kvmmake>
    800012b2:	00006797          	auipc	a5,0x6
    800012b6:	74a7bb23          	sd	a0,1878(a5) # 80007a08 <kernel_pagetable>
}
    800012ba:	60a2                	ld	ra,8(sp)
    800012bc:	6402                	ld	s0,0(sp)
    800012be:	0141                	addi	sp,sp,16
    800012c0:	8082                	ret

00000000800012c2 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800012c2:	1101                	addi	sp,sp,-32
    800012c4:	ec06                	sd	ra,24(sp)
    800012c6:	e822                	sd	s0,16(sp)
    800012c8:	e426                	sd	s1,8(sp)
    800012ca:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800012cc:	923ff0ef          	jal	ra,80000bee <kalloc>
    800012d0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800012d2:	c509                	beqz	a0,800012dc <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800012d4:	6605                	lui	a2,0x1
    800012d6:	4581                	li	a1,0
    800012d8:	aebff0ef          	jal	ra,80000dc2 <memset>
  return pagetable;
}
    800012dc:	8526                	mv	a0,s1
    800012de:	60e2                	ld	ra,24(sp)
    800012e0:	6442                	ld	s0,16(sp)
    800012e2:	64a2                	ld	s1,8(sp)
    800012e4:	6105                	addi	sp,sp,32
    800012e6:	8082                	ret

00000000800012e8 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012e8:	7139                	addi	sp,sp,-64
    800012ea:	fc06                	sd	ra,56(sp)
    800012ec:	f822                	sd	s0,48(sp)
    800012ee:	f426                	sd	s1,40(sp)
    800012f0:	f04a                	sd	s2,32(sp)
    800012f2:	ec4e                	sd	s3,24(sp)
    800012f4:	e852                	sd	s4,16(sp)
    800012f6:	e456                	sd	s5,8(sp)
    800012f8:	e05a                	sd	s6,0(sp)
    800012fa:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012fc:	03459793          	slli	a5,a1,0x34
    80001300:	e785                	bnez	a5,80001328 <uvmunmap+0x40>
    80001302:	8a2a                	mv	s4,a0
    80001304:	892e                	mv	s2,a1
    80001306:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001308:	0632                	slli	a2,a2,0xc
    8000130a:	00b609b3          	add	s3,a2,a1
    8000130e:	6b05                	lui	s6,0x1
    80001310:	0335e763          	bltu	a1,s3,8000133e <uvmunmap+0x56>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001314:	70e2                	ld	ra,56(sp)
    80001316:	7442                	ld	s0,48(sp)
    80001318:	74a2                	ld	s1,40(sp)
    8000131a:	7902                	ld	s2,32(sp)
    8000131c:	69e2                	ld	s3,24(sp)
    8000131e:	6a42                	ld	s4,16(sp)
    80001320:	6aa2                	ld	s5,8(sp)
    80001322:	6b02                	ld	s6,0(sp)
    80001324:	6121                	addi	sp,sp,64
    80001326:	8082                	ret
    panic("uvmunmap: not aligned");
    80001328:	00006517          	auipc	a0,0x6
    8000132c:	e3050513          	addi	a0,a0,-464 # 80007158 <digits+0x120>
    80001330:	c5aff0ef          	jal	ra,8000078a <panic>
    *pte = 0;
    80001334:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001338:	995a                	add	s2,s2,s6
    8000133a:	fd397de3          	bgeu	s2,s3,80001314 <uvmunmap+0x2c>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    8000133e:	4601                	li	a2,0
    80001340:	85ca                	mv	a1,s2
    80001342:	8552                	mv	a0,s4
    80001344:	cfbff0ef          	jal	ra,8000103e <walk>
    80001348:	84aa                	mv	s1,a0
    8000134a:	d57d                	beqz	a0,80001338 <uvmunmap+0x50>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    8000134c:	611c                	ld	a5,0(a0)
    8000134e:	0017f713          	andi	a4,a5,1
    80001352:	d37d                	beqz	a4,80001338 <uvmunmap+0x50>
    if(do_free){
    80001354:	fe0a80e3          	beqz	s5,80001334 <uvmunmap+0x4c>
      uint64 pa = PTE2PA(*pte);
    80001358:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    8000135a:	00c79513          	slli	a0,a5,0xc
    8000135e:	f4aff0ef          	jal	ra,80000aa8 <kfree>
    80001362:	bfc9                	j	80001334 <uvmunmap+0x4c>

0000000080001364 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001364:	1101                	addi	sp,sp,-32
    80001366:	ec06                	sd	ra,24(sp)
    80001368:	e822                	sd	s0,16(sp)
    8000136a:	e426                	sd	s1,8(sp)
    8000136c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000136e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001370:	00b67d63          	bgeu	a2,a1,8000138a <uvmdealloc+0x26>
    80001374:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001376:	6785                	lui	a5,0x1
    80001378:	17fd                	addi	a5,a5,-1
    8000137a:	00f60733          	add	a4,a2,a5
    8000137e:	767d                	lui	a2,0xfffff
    80001380:	8f71                	and	a4,a4,a2
    80001382:	97ae                	add	a5,a5,a1
    80001384:	8ff1                	and	a5,a5,a2
    80001386:	00f76863          	bltu	a4,a5,80001396 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000138a:	8526                	mv	a0,s1
    8000138c:	60e2                	ld	ra,24(sp)
    8000138e:	6442                	ld	s0,16(sp)
    80001390:	64a2                	ld	s1,8(sp)
    80001392:	6105                	addi	sp,sp,32
    80001394:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001396:	8f99                	sub	a5,a5,a4
    80001398:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000139a:	4685                	li	a3,1
    8000139c:	0007861b          	sext.w	a2,a5
    800013a0:	85ba                	mv	a1,a4
    800013a2:	f47ff0ef          	jal	ra,800012e8 <uvmunmap>
    800013a6:	b7d5                	j	8000138a <uvmdealloc+0x26>

00000000800013a8 <uvmalloc>:
  if(newsz < oldsz)
    800013a8:	08b66963          	bltu	a2,a1,8000143a <uvmalloc+0x92>
{
    800013ac:	7139                	addi	sp,sp,-64
    800013ae:	fc06                	sd	ra,56(sp)
    800013b0:	f822                	sd	s0,48(sp)
    800013b2:	f426                	sd	s1,40(sp)
    800013b4:	f04a                	sd	s2,32(sp)
    800013b6:	ec4e                	sd	s3,24(sp)
    800013b8:	e852                	sd	s4,16(sp)
    800013ba:	e456                	sd	s5,8(sp)
    800013bc:	e05a                	sd	s6,0(sp)
    800013be:	0080                	addi	s0,sp,64
    800013c0:	8aaa                	mv	s5,a0
    800013c2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800013c4:	6985                	lui	s3,0x1
    800013c6:	19fd                	addi	s3,s3,-1
    800013c8:	95ce                	add	a1,a1,s3
    800013ca:	79fd                	lui	s3,0xfffff
    800013cc:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800013d0:	06c9f763          	bgeu	s3,a2,8000143e <uvmalloc+0x96>
    800013d4:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800013d6:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800013da:	815ff0ef          	jal	ra,80000bee <kalloc>
    800013de:	84aa                	mv	s1,a0
    if(mem == 0){
    800013e0:	c11d                	beqz	a0,80001406 <uvmalloc+0x5e>
    memset(mem, 0, PGSIZE);
    800013e2:	6605                	lui	a2,0x1
    800013e4:	4581                	li	a1,0
    800013e6:	9ddff0ef          	jal	ra,80000dc2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800013ea:	875a                	mv	a4,s6
    800013ec:	86a6                	mv	a3,s1
    800013ee:	6605                	lui	a2,0x1
    800013f0:	85ca                	mv	a1,s2
    800013f2:	8556                	mv	a0,s5
    800013f4:	d23ff0ef          	jal	ra,80001116 <mappages>
    800013f8:	e51d                	bnez	a0,80001426 <uvmalloc+0x7e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800013fa:	6785                	lui	a5,0x1
    800013fc:	993e                	add	s2,s2,a5
    800013fe:	fd496ee3          	bltu	s2,s4,800013da <uvmalloc+0x32>
  return newsz;
    80001402:	8552                	mv	a0,s4
    80001404:	a039                	j	80001412 <uvmalloc+0x6a>
      uvmdealloc(pagetable, a, oldsz);
    80001406:	864e                	mv	a2,s3
    80001408:	85ca                	mv	a1,s2
    8000140a:	8556                	mv	a0,s5
    8000140c:	f59ff0ef          	jal	ra,80001364 <uvmdealloc>
      return 0;
    80001410:	4501                	li	a0,0
}
    80001412:	70e2                	ld	ra,56(sp)
    80001414:	7442                	ld	s0,48(sp)
    80001416:	74a2                	ld	s1,40(sp)
    80001418:	7902                	ld	s2,32(sp)
    8000141a:	69e2                	ld	s3,24(sp)
    8000141c:	6a42                	ld	s4,16(sp)
    8000141e:	6aa2                	ld	s5,8(sp)
    80001420:	6b02                	ld	s6,0(sp)
    80001422:	6121                	addi	sp,sp,64
    80001424:	8082                	ret
      kfree(mem);
    80001426:	8526                	mv	a0,s1
    80001428:	e80ff0ef          	jal	ra,80000aa8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000142c:	864e                	mv	a2,s3
    8000142e:	85ca                	mv	a1,s2
    80001430:	8556                	mv	a0,s5
    80001432:	f33ff0ef          	jal	ra,80001364 <uvmdealloc>
      return 0;
    80001436:	4501                	li	a0,0
    80001438:	bfe9                	j	80001412 <uvmalloc+0x6a>
    return oldsz;
    8000143a:	852e                	mv	a0,a1
}
    8000143c:	8082                	ret
  return newsz;
    8000143e:	8532                	mv	a0,a2
    80001440:	bfc9                	j	80001412 <uvmalloc+0x6a>

0000000080001442 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001442:	7179                	addi	sp,sp,-48
    80001444:	f406                	sd	ra,40(sp)
    80001446:	f022                	sd	s0,32(sp)
    80001448:	ec26                	sd	s1,24(sp)
    8000144a:	e84a                	sd	s2,16(sp)
    8000144c:	e44e                	sd	s3,8(sp)
    8000144e:	e052                	sd	s4,0(sp)
    80001450:	1800                	addi	s0,sp,48
    80001452:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001454:	84aa                	mv	s1,a0
    80001456:	6905                	lui	s2,0x1
    80001458:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000145a:	4985                	li	s3,1
    8000145c:	a811                	j	80001470 <freewalk+0x2e>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000145e:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001460:	0532                	slli	a0,a0,0xc
    80001462:	fe1ff0ef          	jal	ra,80001442 <freewalk>
      pagetable[i] = 0;
    80001466:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000146a:	04a1                	addi	s1,s1,8
    8000146c:	01248f63          	beq	s1,s2,8000148a <freewalk+0x48>
    pte_t pte = pagetable[i];
    80001470:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001472:	00f57793          	andi	a5,a0,15
    80001476:	ff3784e3          	beq	a5,s3,8000145e <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000147a:	8905                	andi	a0,a0,1
    8000147c:	d57d                	beqz	a0,8000146a <freewalk+0x28>
      panic("freewalk: leaf");
    8000147e:	00006517          	auipc	a0,0x6
    80001482:	cf250513          	addi	a0,a0,-782 # 80007170 <digits+0x138>
    80001486:	b04ff0ef          	jal	ra,8000078a <panic>
    }
  }
  kfree((void*)pagetable);
    8000148a:	8552                	mv	a0,s4
    8000148c:	e1cff0ef          	jal	ra,80000aa8 <kfree>
}
    80001490:	70a2                	ld	ra,40(sp)
    80001492:	7402                	ld	s0,32(sp)
    80001494:	64e2                	ld	s1,24(sp)
    80001496:	6942                	ld	s2,16(sp)
    80001498:	69a2                	ld	s3,8(sp)
    8000149a:	6a02                	ld	s4,0(sp)
    8000149c:	6145                	addi	sp,sp,48
    8000149e:	8082                	ret

00000000800014a0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800014a0:	1101                	addi	sp,sp,-32
    800014a2:	ec06                	sd	ra,24(sp)
    800014a4:	e822                	sd	s0,16(sp)
    800014a6:	e426                	sd	s1,8(sp)
    800014a8:	1000                	addi	s0,sp,32
    800014aa:	84aa                	mv	s1,a0
  if(sz > 0)
    800014ac:	e989                	bnez	a1,800014be <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800014ae:	8526                	mv	a0,s1
    800014b0:	f93ff0ef          	jal	ra,80001442 <freewalk>
}
    800014b4:	60e2                	ld	ra,24(sp)
    800014b6:	6442                	ld	s0,16(sp)
    800014b8:	64a2                	ld	s1,8(sp)
    800014ba:	6105                	addi	sp,sp,32
    800014bc:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800014be:	6605                	lui	a2,0x1
    800014c0:	167d                	addi	a2,a2,-1
    800014c2:	962e                	add	a2,a2,a1
    800014c4:	4685                	li	a3,1
    800014c6:	8231                	srli	a2,a2,0xc
    800014c8:	4581                	li	a1,0
    800014ca:	e1fff0ef          	jal	ra,800012e8 <uvmunmap>
    800014ce:	b7c5                	j	800014ae <uvmfree+0xe>

00000000800014d0 <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    800014d0:	715d                	addi	sp,sp,-80
    800014d2:	e486                	sd	ra,72(sp)
    800014d4:	e0a2                	sd	s0,64(sp)
    800014d6:	fc26                	sd	s1,56(sp)
    800014d8:	f84a                	sd	s2,48(sp)
    800014da:	f44e                	sd	s3,40(sp)
    800014dc:	f052                	sd	s4,32(sp)
    800014de:	ec56                	sd	s5,24(sp)
    800014e0:	e85a                	sd	s6,16(sp)
    800014e2:	e45e                	sd	s7,8(sp)
    800014e4:	0880                	addi	s0,sp,80
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  /** char *mem; */

  for(i = 0; i < sz; i += PGSIZE){
    800014e6:	c25d                	beqz	a2,8000158c <uvmcopy+0xbc>
    800014e8:	8aaa                	mv	s5,a0
    800014ea:	8a2e                	mv	s4,a1
    800014ec:	89b2                	mv	s3,a2
    800014ee:	4481                	li	s1,0
    if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
      /** kfree(mem); */
      printf("uvmcopy():can not map page\n");
      goto err;
    }
    addref("uvmcopy()",(void*)pa);
    800014f0:	00006b17          	auipc	s6,0x6
    800014f4:	cf0b0b13          	addi	s6,s6,-784 # 800071e0 <digits+0x1a8>
    if((pte = walk(old, i, 0)) == 0)
    800014f8:	4601                	li	a2,0
    800014fa:	85a6                	mv	a1,s1
    800014fc:	8556                	mv	a0,s5
    800014fe:	b41ff0ef          	jal	ra,8000103e <walk>
    80001502:	c121                	beqz	a0,80001542 <uvmcopy+0x72>
    if((*pte & PTE_V) == 0)
    80001504:	6118                	ld	a4,0(a0)
    80001506:	00177793          	andi	a5,a4,1
    8000150a:	c3b1                	beqz	a5,8000154e <uvmcopy+0x7e>
    pa = PTE2PA(*pte);
    8000150c:	00a75913          	srli	s2,a4,0xa
    80001510:	0932                	slli	s2,s2,0xc
    *pte = (*pte & ~PTE_W) | PTE_COW;
    80001512:	efb77713          	andi	a4,a4,-261
    80001516:	10076713          	ori	a4,a4,256
    8000151a:	e118                	sd	a4,0(a0)
    if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
    8000151c:	3fb77713          	andi	a4,a4,1019
    80001520:	86ca                	mv	a3,s2
    80001522:	6605                	lui	a2,0x1
    80001524:	85a6                	mv	a1,s1
    80001526:	8552                	mv	a0,s4
    80001528:	befff0ef          	jal	ra,80001116 <mappages>
    8000152c:	8baa                	mv	s7,a0
    8000152e:	e515                	bnez	a0,8000155a <uvmcopy+0x8a>
    addref("uvmcopy()",(void*)pa);
    80001530:	85ca                	mv	a1,s2
    80001532:	855a                	mv	a0,s6
    80001534:	cecff0ef          	jal	ra,80000a20 <addref>
  for(i = 0; i < sz; i += PGSIZE){
    80001538:	6785                	lui	a5,0x1
    8000153a:	94be                	add	s1,s1,a5
    8000153c:	fb34eee3          	bltu	s1,s3,800014f8 <uvmcopy+0x28>
    80001540:	a815                	j	80001574 <uvmcopy+0xa4>
      panic("uvmcopy: pte should exist");
    80001542:	00006517          	auipc	a0,0x6
    80001546:	c3e50513          	addi	a0,a0,-962 # 80007180 <digits+0x148>
    8000154a:	a40ff0ef          	jal	ra,8000078a <panic>
      panic("uvmcopy: page not present");
    8000154e:	00006517          	auipc	a0,0x6
    80001552:	c5250513          	addi	a0,a0,-942 # 800071a0 <digits+0x168>
    80001556:	a34ff0ef          	jal	ra,8000078a <panic>
      printf("uvmcopy():can not map page\n");
    8000155a:	00006517          	auipc	a0,0x6
    8000155e:	c6650513          	addi	a0,a0,-922 # 800071c0 <digits+0x188>
    80001562:	f63fe0ef          	jal	ra,800004c4 <printf>
    printf("origin perm & PTE_COW: %d, new perm & PTE_COW %d \n", PTE_FLAGS(*walk(old,i,0)) & PTE_COW, PTE_FLAGS(*walk(new,i,0)) & PTE_COW); */
  }
  return 0;

 err:
  uvmunmap(new, 0, i, 1);
    80001566:	4685                	li	a3,1
    80001568:	8626                	mv	a2,s1
    8000156a:	4581                	li	a1,0
    8000156c:	8552                	mv	a0,s4
    8000156e:	d7bff0ef          	jal	ra,800012e8 <uvmunmap>
  return -1;
    80001572:	5bfd                	li	s7,-1
}
    80001574:	855e                	mv	a0,s7
    80001576:	60a6                	ld	ra,72(sp)
    80001578:	6406                	ld	s0,64(sp)
    8000157a:	74e2                	ld	s1,56(sp)
    8000157c:	7942                	ld	s2,48(sp)
    8000157e:	79a2                	ld	s3,40(sp)
    80001580:	7a02                	ld	s4,32(sp)
    80001582:	6ae2                	ld	s5,24(sp)
    80001584:	6b42                	ld	s6,16(sp)
    80001586:	6ba2                	ld	s7,8(sp)
    80001588:	6161                	addi	sp,sp,80
    8000158a:	8082                	ret
  return 0;
    8000158c:	4b81                	li	s7,0
    8000158e:	b7dd                	j	80001574 <uvmcopy+0xa4>

0000000080001590 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001590:	1141                	addi	sp,sp,-16
    80001592:	e406                	sd	ra,8(sp)
    80001594:	e022                	sd	s0,0(sp)
    80001596:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001598:	4601                	li	a2,0
    8000159a:	aa5ff0ef          	jal	ra,8000103e <walk>
  if(pte == 0)
    8000159e:	c901                	beqz	a0,800015ae <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800015a0:	611c                	ld	a5,0(a0)
    800015a2:	9bbd                	andi	a5,a5,-17
    800015a4:	e11c                	sd	a5,0(a0)
}
    800015a6:	60a2                	ld	ra,8(sp)
    800015a8:	6402                	ld	s0,0(sp)
    800015aa:	0141                	addi	sp,sp,16
    800015ac:	8082                	ret
    panic("uvmclear");
    800015ae:	00006517          	auipc	a0,0x6
    800015b2:	c4250513          	addi	a0,a0,-958 # 800071f0 <digits+0x1b8>
    800015b6:	9d4ff0ef          	jal	ra,8000078a <panic>

00000000800015ba <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800015ba:	c2d5                	beqz	a3,8000165e <copyinstr+0xa4>
{
    800015bc:	715d                	addi	sp,sp,-80
    800015be:	e486                	sd	ra,72(sp)
    800015c0:	e0a2                	sd	s0,64(sp)
    800015c2:	fc26                	sd	s1,56(sp)
    800015c4:	f84a                	sd	s2,48(sp)
    800015c6:	f44e                	sd	s3,40(sp)
    800015c8:	f052                	sd	s4,32(sp)
    800015ca:	ec56                	sd	s5,24(sp)
    800015cc:	e85a                	sd	s6,16(sp)
    800015ce:	e45e                	sd	s7,8(sp)
    800015d0:	0880                	addi	s0,sp,80
    800015d2:	8a2a                	mv	s4,a0
    800015d4:	8b2e                	mv	s6,a1
    800015d6:	8bb2                	mv	s7,a2
    800015d8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800015da:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800015dc:	6985                	lui	s3,0x1
    800015de:	a035                	j	8000160a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800015e0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800015e4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800015e6:	0017b793          	seqz	a5,a5
    800015ea:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800015ee:	60a6                	ld	ra,72(sp)
    800015f0:	6406                	ld	s0,64(sp)
    800015f2:	74e2                	ld	s1,56(sp)
    800015f4:	7942                	ld	s2,48(sp)
    800015f6:	79a2                	ld	s3,40(sp)
    800015f8:	7a02                	ld	s4,32(sp)
    800015fa:	6ae2                	ld	s5,24(sp)
    800015fc:	6b42                	ld	s6,16(sp)
    800015fe:	6ba2                	ld	s7,8(sp)
    80001600:	6161                	addi	sp,sp,80
    80001602:	8082                	ret
    srcva = va0 + PGSIZE;
    80001604:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001608:	c4b9                	beqz	s1,80001656 <copyinstr+0x9c>
    va0 = PGROUNDDOWN(srcva);
    8000160a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000160e:	85ca                	mv	a1,s2
    80001610:	8552                	mv	a0,s4
    80001612:	ac7ff0ef          	jal	ra,800010d8 <walkaddr>
    if(pa0 == 0)
    80001616:	c131                	beqz	a0,8000165a <copyinstr+0xa0>
    n = PGSIZE - (srcva - va0);
    80001618:	41790833          	sub	a6,s2,s7
    8000161c:	984e                	add	a6,a6,s3
    if(n > max)
    8000161e:	0104f363          	bgeu	s1,a6,80001624 <copyinstr+0x6a>
    80001622:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001624:	955e                	add	a0,a0,s7
    80001626:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000162a:	fc080de3          	beqz	a6,80001604 <copyinstr+0x4a>
    8000162e:	985a                	add	a6,a6,s6
    80001630:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001632:	41650633          	sub	a2,a0,s6
    80001636:	14fd                	addi	s1,s1,-1
    80001638:	9b26                	add	s6,s6,s1
    8000163a:	00f60733          	add	a4,a2,a5
    8000163e:	00074703          	lbu	a4,0(a4)
    80001642:	df59                	beqz	a4,800015e0 <copyinstr+0x26>
        *dst = *p;
    80001644:	00e78023          	sb	a4,0(a5)
      --max;
    80001648:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000164c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000164e:	ff0796e3          	bne	a5,a6,8000163a <copyinstr+0x80>
      dst++;
    80001652:	8b42                	mv	s6,a6
    80001654:	bf45                	j	80001604 <copyinstr+0x4a>
    80001656:	4781                	li	a5,0
    80001658:	b779                	j	800015e6 <copyinstr+0x2c>
      return -1;
    8000165a:	557d                	li	a0,-1
    8000165c:	bf49                	j	800015ee <copyinstr+0x34>
  int got_null = 0;
    8000165e:	4781                	li	a5,0
  if(got_null){
    80001660:	0017b793          	seqz	a5,a5
    80001664:	40f00533          	neg	a0,a5
}
    80001668:	8082                	ret

000000008000166a <ismapped>:
  return mem;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
    8000166a:	1141                	addi	sp,sp,-16
    8000166c:	e406                	sd	ra,8(sp)
    8000166e:	e022                	sd	s0,0(sp)
    80001670:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    80001672:	4601                	li	a2,0
    80001674:	9cbff0ef          	jal	ra,8000103e <walk>
  if (pte == 0) {
    80001678:	c519                	beqz	a0,80001686 <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    8000167a:	6108                	ld	a0,0(a0)
    return 0;
    8000167c:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    8000167e:	60a2                	ld	ra,8(sp)
    80001680:	6402                	ld	s0,0(sp)
    80001682:	0141                	addi	sp,sp,16
    80001684:	8082                	ret
    return 0;
    80001686:	4501                	li	a0,0
    80001688:	bfdd                	j	8000167e <ismapped+0x14>

000000008000168a <vmfault>:
{
    8000168a:	7179                	addi	sp,sp,-48
    8000168c:	f406                	sd	ra,40(sp)
    8000168e:	f022                	sd	s0,32(sp)
    80001690:	ec26                	sd	s1,24(sp)
    80001692:	e84a                	sd	s2,16(sp)
    80001694:	e44e                	sd	s3,8(sp)
    80001696:	e052                	sd	s4,0(sp)
    80001698:	1800                	addi	s0,sp,48
    8000169a:	89aa                	mv	s3,a0
    8000169c:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    8000169e:	37c000ef          	jal	ra,80001a1a <myproc>
  if (va >= p->sz)
    800016a2:	653c                	ld	a5,72(a0)
    800016a4:	00f4ec63          	bltu	s1,a5,800016bc <vmfault+0x32>
    return 0;
    800016a8:	4981                	li	s3,0
}
    800016aa:	854e                	mv	a0,s3
    800016ac:	70a2                	ld	ra,40(sp)
    800016ae:	7402                	ld	s0,32(sp)
    800016b0:	64e2                	ld	s1,24(sp)
    800016b2:	6942                	ld	s2,16(sp)
    800016b4:	69a2                	ld	s3,8(sp)
    800016b6:	6a02                	ld	s4,0(sp)
    800016b8:	6145                	addi	sp,sp,48
    800016ba:	8082                	ret
    800016bc:	892a                	mv	s2,a0
  va = PGROUNDDOWN(va);
    800016be:	75fd                	lui	a1,0xfffff
    800016c0:	8ced                	and	s1,s1,a1
  if(ismapped(pagetable, va)) {
    800016c2:	85a6                	mv	a1,s1
    800016c4:	854e                	mv	a0,s3
    800016c6:	fa5ff0ef          	jal	ra,8000166a <ismapped>
    return 0;
    800016ca:	4981                	li	s3,0
  if(ismapped(pagetable, va)) {
    800016cc:	fd79                	bnez	a0,800016aa <vmfault+0x20>
  mem = (uint64) kalloc();
    800016ce:	d20ff0ef          	jal	ra,80000bee <kalloc>
    800016d2:	8a2a                	mv	s4,a0
  if(mem == 0)
    800016d4:	d979                	beqz	a0,800016aa <vmfault+0x20>
  mem = (uint64) kalloc();
    800016d6:	89aa                	mv	s3,a0
  memset((void *) mem, 0, PGSIZE);
    800016d8:	6605                	lui	a2,0x1
    800016da:	4581                	li	a1,0
    800016dc:	ee6ff0ef          	jal	ra,80000dc2 <memset>
  if (mappages(p->pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    800016e0:	4759                	li	a4,22
    800016e2:	86d2                	mv	a3,s4
    800016e4:	6605                	lui	a2,0x1
    800016e6:	85a6                	mv	a1,s1
    800016e8:	05093503          	ld	a0,80(s2) # 1050 <_entry-0x7fffefb0>
    800016ec:	a2bff0ef          	jal	ra,80001116 <mappages>
    800016f0:	dd4d                	beqz	a0,800016aa <vmfault+0x20>
    kfree((void *)mem);
    800016f2:	8552                	mv	a0,s4
    800016f4:	bb4ff0ef          	jal	ra,80000aa8 <kfree>
    return 0;
    800016f8:	4981                	li	s3,0
    800016fa:	bf45                	j	800016aa <vmfault+0x20>

00000000800016fc <copyout>:
  while(len > 0){
    800016fc:	12068163          	beqz	a3,8000181e <copyout+0x122>
{
    80001700:	711d                	addi	sp,sp,-96
    80001702:	ec86                	sd	ra,88(sp)
    80001704:	e8a2                	sd	s0,80(sp)
    80001706:	e4a6                	sd	s1,72(sp)
    80001708:	e0ca                	sd	s2,64(sp)
    8000170a:	fc4e                	sd	s3,56(sp)
    8000170c:	f852                	sd	s4,48(sp)
    8000170e:	f456                	sd	s5,40(sp)
    80001710:	f05a                	sd	s6,32(sp)
    80001712:	ec5e                	sd	s7,24(sp)
    80001714:	e862                	sd	s8,16(sp)
    80001716:	e466                	sd	s9,8(sp)
    80001718:	e06a                	sd	s10,0(sp)
    8000171a:	1080                	addi	s0,sp,96
    8000171c:	8b2a                	mv	s6,a0
    8000171e:	8bae                	mv	s7,a1
    80001720:	8c32                	mv	s8,a2
    80001722:	8ab6                	mv	s5,a3
    va0 = PGROUNDDOWN(dstva);
    80001724:	74fd                	lui	s1,0xfffff
    80001726:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA)
    80001728:	57fd                	li	a5,-1
    8000172a:	83e9                	srli	a5,a5,0x1a
    8000172c:	0e97eb63          	bltu	a5,s1,80001822 <copyout+0x126>
    80001730:	8cbe                	mv	s9,a5
    80001732:	a8a1                	j	8000178a <copyout+0x8e>
        printf("copyout(): memery alloc fault\n");
    80001734:	00006517          	auipc	a0,0x6
    80001738:	acc50513          	addi	a0,a0,-1332 # 80007200 <digits+0x1c8>
    8000173c:	d89fe0ef          	jal	ra,800004c4 <printf>
        return -1;
    80001740:	557d                	li	a0,-1
    80001742:	a0c1                	j	80001802 <copyout+0x106>
          printf("copyout(): can not map page\n");
    80001744:	00006517          	auipc	a0,0x6
    80001748:	adc50513          	addi	a0,a0,-1316 # 80007220 <digits+0x1e8>
    8000174c:	d79fe0ef          	jal	ra,800004c4 <printf>
          kfree(mem); 
    80001750:	8552                	mv	a0,s4
    80001752:	b56ff0ef          	jal	ra,80000aa8 <kfree>
          return -1;
    80001756:	557d                	li	a0,-1
    80001758:	a06d                	j	80001802 <copyout+0x106>
    n = PGSIZE - (dstva - va0);
    8000175a:	6985                	lui	s3,0x1
    8000175c:	99a6                	add	s3,s3,s1
    8000175e:	41798a33          	sub	s4,s3,s7
    if(n > len)
    80001762:	014af363          	bgeu	s5,s4,80001768 <copyout+0x6c>
    80001766:	8a56                	mv	s4,s5
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001768:	409b8533          	sub	a0,s7,s1
    8000176c:	000a061b          	sext.w	a2,s4
    80001770:	85e2                	mv	a1,s8
    80001772:	954a                	add	a0,a0,s2
    80001774:	eaaff0ef          	jal	ra,80000e1e <memmove>
    len -= n;
    80001778:	414a8ab3          	sub	s5,s5,s4
    src += n;
    8000177c:	9c52                	add	s8,s8,s4
  while(len > 0){
    8000177e:	080a8163          	beqz	s5,80001800 <copyout+0x104>
    if(va0 >= MAXVA)
    80001782:	0b3ce263          	bltu	s9,s3,80001826 <copyout+0x12a>
    va0 = PGROUNDDOWN(dstva);
    80001786:	84ce                	mv	s1,s3
    dstva = va0 + PGSIZE;
    80001788:	8bce                	mv	s7,s3
    pa0 = walkaddr(pagetable, va0);
    8000178a:	85a6                	mv	a1,s1
    8000178c:	855a                	mv	a0,s6
    8000178e:	94bff0ef          	jal	ra,800010d8 <walkaddr>
    80001792:	892a                	mv	s2,a0
    if(pa0 == 0) {
    80001794:	e901                	bnez	a0,800017a4 <copyout+0xa8>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001796:	4601                	li	a2,0
    80001798:	85a6                	mv	a1,s1
    8000179a:	855a                	mv	a0,s6
    8000179c:	eefff0ef          	jal	ra,8000168a <vmfault>
    800017a0:	892a                	mv	s2,a0
    800017a2:	c541                	beqz	a0,8000182a <copyout+0x12e>
    pte = walk(pagetable, va0, 0);
    800017a4:	4601                	li	a2,0
    800017a6:	85a6                	mv	a1,s1
    800017a8:	855a                	mv	a0,s6
    800017aa:	895ff0ef          	jal	ra,8000103e <walk>
    800017ae:	89aa                	mv	s3,a0
    if(*pte & PTE_COW){
    800017b0:	611c                	ld	a5,0(a0)
    800017b2:	1007f793          	andi	a5,a5,256
    800017b6:	d3d5                	beqz	a5,8000175a <copyout+0x5e>
      if((mem = kalloc()) == 0)
    800017b8:	c36ff0ef          	jal	ra,80000bee <kalloc>
    800017bc:	8a2a                	mv	s4,a0
    800017be:	d93d                	beqz	a0,80001734 <copyout+0x38>
      memset(mem, 0, sizeof(mem));
    800017c0:	4621                	li	a2,8
    800017c2:	4581                	li	a1,0
    800017c4:	dfeff0ef          	jal	ra,80000dc2 <memset>
      uint64 pa = walkaddr(pagetable, va0);
    800017c8:	85a6                	mv	a1,s1
    800017ca:	855a                	mv	a0,s6
    800017cc:	90dff0ef          	jal	ra,800010d8 <walkaddr>
    800017d0:	8d2a                	mv	s10,a0
      if(pa){
    800017d2:	d541                	beqz	a0,8000175a <copyout+0x5e>
        memmove(mem, (char*)pa, PGSIZE);
    800017d4:	6605                	lui	a2,0x1
    800017d6:	85aa                	mv	a1,a0
    800017d8:	8552                	mv	a0,s4
    800017da:	e44ff0ef          	jal	ra,80000e1e <memmove>
        int perm = PTE_FLAGS(*pte);
    800017de:	0009b703          	ld	a4,0(s3) # 1000 <_entry-0x7ffff000>
        perm &= ~PTE_COW;
    800017e2:	2ff77713          	andi	a4,a4,767
        if(mappages(pagetable, va0, PGSIZE, (uint64)mem, perm) != 0){
    800017e6:	00476713          	ori	a4,a4,4
    800017ea:	86d2                	mv	a3,s4
    800017ec:	6605                	lui	a2,0x1
    800017ee:	85a6                	mv	a1,s1
    800017f0:	855a                	mv	a0,s6
    800017f2:	925ff0ef          	jal	ra,80001116 <mappages>
    800017f6:	f539                	bnez	a0,80001744 <copyout+0x48>
        kfree((void*) pa);
    800017f8:	856a                	mv	a0,s10
    800017fa:	aaeff0ef          	jal	ra,80000aa8 <kfree>
    800017fe:	bfb1                	j	8000175a <copyout+0x5e>
  return 0;
    80001800:	4501                	li	a0,0
}
    80001802:	60e6                	ld	ra,88(sp)
    80001804:	6446                	ld	s0,80(sp)
    80001806:	64a6                	ld	s1,72(sp)
    80001808:	6906                	ld	s2,64(sp)
    8000180a:	79e2                	ld	s3,56(sp)
    8000180c:	7a42                	ld	s4,48(sp)
    8000180e:	7aa2                	ld	s5,40(sp)
    80001810:	7b02                	ld	s6,32(sp)
    80001812:	6be2                	ld	s7,24(sp)
    80001814:	6c42                	ld	s8,16(sp)
    80001816:	6ca2                	ld	s9,8(sp)
    80001818:	6d02                	ld	s10,0(sp)
    8000181a:	6125                	addi	sp,sp,96
    8000181c:	8082                	ret
  return 0;
    8000181e:	4501                	li	a0,0
}
    80001820:	8082                	ret
      return -1;
    80001822:	557d                	li	a0,-1
    80001824:	bff9                	j	80001802 <copyout+0x106>
    80001826:	557d                	li	a0,-1
    80001828:	bfe9                	j	80001802 <copyout+0x106>
        return -1;
    8000182a:	557d                	li	a0,-1
    8000182c:	bfd9                	j	80001802 <copyout+0x106>

000000008000182e <copyin>:
  while(len > 0){
    8000182e:	c6c9                	beqz	a3,800018b8 <copyin+0x8a>
{
    80001830:	715d                	addi	sp,sp,-80
    80001832:	e486                	sd	ra,72(sp)
    80001834:	e0a2                	sd	s0,64(sp)
    80001836:	fc26                	sd	s1,56(sp)
    80001838:	f84a                	sd	s2,48(sp)
    8000183a:	f44e                	sd	s3,40(sp)
    8000183c:	f052                	sd	s4,32(sp)
    8000183e:	ec56                	sd	s5,24(sp)
    80001840:	e85a                	sd	s6,16(sp)
    80001842:	e45e                	sd	s7,8(sp)
    80001844:	e062                	sd	s8,0(sp)
    80001846:	0880                	addi	s0,sp,80
    80001848:	8baa                	mv	s7,a0
    8000184a:	8aae                	mv	s5,a1
    8000184c:	8932                	mv	s2,a2
    8000184e:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    80001850:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    80001852:	6b05                	lui	s6,0x1
    80001854:	a035                	j	80001880 <copyin+0x52>
    80001856:	412984b3          	sub	s1,s3,s2
    8000185a:	94da                	add	s1,s1,s6
    if(n > len)
    8000185c:	009a7363          	bgeu	s4,s1,80001862 <copyin+0x34>
    80001860:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001862:	413905b3          	sub	a1,s2,s3
    80001866:	0004861b          	sext.w	a2,s1
    8000186a:	95aa                	add	a1,a1,a0
    8000186c:	8556                	mv	a0,s5
    8000186e:	db0ff0ef          	jal	ra,80000e1e <memmove>
    len -= n;
    80001872:	409a0a33          	sub	s4,s4,s1
    dst += n;
    80001876:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001878:	01698933          	add	s2,s3,s6
  while(len > 0){
    8000187c:	020a0163          	beqz	s4,8000189e <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    80001880:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    80001884:	85ce                	mv	a1,s3
    80001886:	855e                	mv	a0,s7
    80001888:	851ff0ef          	jal	ra,800010d8 <walkaddr>
    if(pa0 == 0) {
    8000188c:	f569                	bnez	a0,80001856 <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    8000188e:	4601                	li	a2,0
    80001890:	85ce                	mv	a1,s3
    80001892:	855e                	mv	a0,s7
    80001894:	df7ff0ef          	jal	ra,8000168a <vmfault>
    80001898:	fd5d                	bnez	a0,80001856 <copyin+0x28>
        return -1;
    8000189a:	557d                	li	a0,-1
    8000189c:	a011                	j	800018a0 <copyin+0x72>
  return 0;
    8000189e:	4501                	li	a0,0
}
    800018a0:	60a6                	ld	ra,72(sp)
    800018a2:	6406                	ld	s0,64(sp)
    800018a4:	74e2                	ld	s1,56(sp)
    800018a6:	7942                	ld	s2,48(sp)
    800018a8:	79a2                	ld	s3,40(sp)
    800018aa:	7a02                	ld	s4,32(sp)
    800018ac:	6ae2                	ld	s5,24(sp)
    800018ae:	6b42                	ld	s6,16(sp)
    800018b0:	6ba2                	ld	s7,8(sp)
    800018b2:	6c02                	ld	s8,0(sp)
    800018b4:	6161                	addi	sp,sp,80
    800018b6:	8082                	ret
  return 0;
    800018b8:	4501                	li	a0,0
}
    800018ba:	8082                	ret

00000000800018bc <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    800018bc:	7139                	addi	sp,sp,-64
    800018be:	fc06                	sd	ra,56(sp)
    800018c0:	f822                	sd	s0,48(sp)
    800018c2:	f426                	sd	s1,40(sp)
    800018c4:	f04a                	sd	s2,32(sp)
    800018c6:	ec4e                	sd	s3,24(sp)
    800018c8:	e852                	sd	s4,16(sp)
    800018ca:	e456                	sd	s5,8(sp)
    800018cc:	e05a                	sd	s6,0(sp)
    800018ce:	0080                	addi	s0,sp,64
    800018d0:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018d2:	00016497          	auipc	s1,0x16
    800018d6:	64e48493          	addi	s1,s1,1614 # 80017f20 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018da:	8b26                	mv	s6,s1
    800018dc:	00005a97          	auipc	s5,0x5
    800018e0:	724a8a93          	addi	s5,s5,1828 # 80007000 <etext>
    800018e4:	04000937          	lui	s2,0x4000
    800018e8:	197d                	addi	s2,s2,-1
    800018ea:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ec:	0001ca17          	auipc	s4,0x1c
    800018f0:	234a0a13          	addi	s4,s4,564 # 8001db20 <tickslock>
    char *pa = kalloc();
    800018f4:	afaff0ef          	jal	ra,80000bee <kalloc>
    800018f8:	862a                	mv	a2,a0
    if(pa == 0)
    800018fa:	c121                	beqz	a0,8000193a <proc_mapstacks+0x7e>
    uint64 va = KSTACK((int) (p - proc));
    800018fc:	416485b3          	sub	a1,s1,s6
    80001900:	8591                	srai	a1,a1,0x4
    80001902:	000ab783          	ld	a5,0(s5)
    80001906:	02f585b3          	mul	a1,a1,a5
    8000190a:	2585                	addiw	a1,a1,1
    8000190c:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001910:	4719                	li	a4,6
    80001912:	6685                	lui	a3,0x1
    80001914:	40b905b3          	sub	a1,s2,a1
    80001918:	854e                	mv	a0,s3
    8000191a:	8b3ff0ef          	jal	ra,800011cc <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000191e:	17048493          	addi	s1,s1,368
    80001922:	fd4499e3          	bne	s1,s4,800018f4 <proc_mapstacks+0x38>
  }
}
    80001926:	70e2                	ld	ra,56(sp)
    80001928:	7442                	ld	s0,48(sp)
    8000192a:	74a2                	ld	s1,40(sp)
    8000192c:	7902                	ld	s2,32(sp)
    8000192e:	69e2                	ld	s3,24(sp)
    80001930:	6a42                	ld	s4,16(sp)
    80001932:	6aa2                	ld	s5,8(sp)
    80001934:	6b02                	ld	s6,0(sp)
    80001936:	6121                	addi	sp,sp,64
    80001938:	8082                	ret
      panic("kalloc");
    8000193a:	00006517          	auipc	a0,0x6
    8000193e:	90650513          	addi	a0,a0,-1786 # 80007240 <digits+0x208>
    80001942:	e49fe0ef          	jal	ra,8000078a <panic>

0000000080001946 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001946:	7139                	addi	sp,sp,-64
    80001948:	fc06                	sd	ra,56(sp)
    8000194a:	f822                	sd	s0,48(sp)
    8000194c:	f426                	sd	s1,40(sp)
    8000194e:	f04a                	sd	s2,32(sp)
    80001950:	ec4e                	sd	s3,24(sp)
    80001952:	e852                	sd	s4,16(sp)
    80001954:	e456                	sd	s5,8(sp)
    80001956:	e05a                	sd	s6,0(sp)
    80001958:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000195a:	00006597          	auipc	a1,0x6
    8000195e:	8ee58593          	addi	a1,a1,-1810 # 80007248 <digits+0x210>
    80001962:	00016517          	auipc	a0,0x16
    80001966:	18e50513          	addi	a0,a0,398 # 80017af0 <pid_lock>
    8000196a:	b04ff0ef          	jal	ra,80000c6e <initlock>
  initlock(&wait_lock, "wait_lock");
    8000196e:	00006597          	auipc	a1,0x6
    80001972:	8e258593          	addi	a1,a1,-1822 # 80007250 <digits+0x218>
    80001976:	00016517          	auipc	a0,0x16
    8000197a:	19250513          	addi	a0,a0,402 # 80017b08 <wait_lock>
    8000197e:	af0ff0ef          	jal	ra,80000c6e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001982:	00016497          	auipc	s1,0x16
    80001986:	59e48493          	addi	s1,s1,1438 # 80017f20 <proc>
      initlock(&p->lock, "proc");
    8000198a:	00006b17          	auipc	s6,0x6
    8000198e:	8d6b0b13          	addi	s6,s6,-1834 # 80007260 <digits+0x228>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001992:	8aa6                	mv	s5,s1
    80001994:	00005a17          	auipc	s4,0x5
    80001998:	66ca0a13          	addi	s4,s4,1644 # 80007000 <etext>
    8000199c:	04000937          	lui	s2,0x4000
    800019a0:	197d                	addi	s2,s2,-1
    800019a2:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a4:	0001c997          	auipc	s3,0x1c
    800019a8:	17c98993          	addi	s3,s3,380 # 8001db20 <tickslock>
      initlock(&p->lock, "proc");
    800019ac:	85da                	mv	a1,s6
    800019ae:	8526                	mv	a0,s1
    800019b0:	abeff0ef          	jal	ra,80000c6e <initlock>
      p->state = UNUSED;
    800019b4:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800019b8:	415487b3          	sub	a5,s1,s5
    800019bc:	8791                	srai	a5,a5,0x4
    800019be:	000a3703          	ld	a4,0(s4)
    800019c2:	02e787b3          	mul	a5,a5,a4
    800019c6:	2785                	addiw	a5,a5,1
    800019c8:	00d7979b          	slliw	a5,a5,0xd
    800019cc:	40f907b3          	sub	a5,s2,a5
    800019d0:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019d2:	17048493          	addi	s1,s1,368
    800019d6:	fd349be3          	bne	s1,s3,800019ac <procinit+0x66>
  }
}
    800019da:	70e2                	ld	ra,56(sp)
    800019dc:	7442                	ld	s0,48(sp)
    800019de:	74a2                	ld	s1,40(sp)
    800019e0:	7902                	ld	s2,32(sp)
    800019e2:	69e2                	ld	s3,24(sp)
    800019e4:	6a42                	ld	s4,16(sp)
    800019e6:	6aa2                	ld	s5,8(sp)
    800019e8:	6b02                	ld	s6,0(sp)
    800019ea:	6121                	addi	sp,sp,64
    800019ec:	8082                	ret

00000000800019ee <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019ee:	1141                	addi	sp,sp,-16
    800019f0:	e422                	sd	s0,8(sp)
    800019f2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019f4:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019f6:	2501                	sext.w	a0,a0
    800019f8:	6422                	ld	s0,8(sp)
    800019fa:	0141                	addi	sp,sp,16
    800019fc:	8082                	ret

00000000800019fe <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e422                	sd	s0,8(sp)
    80001a02:	0800                	addi	s0,sp,16
    80001a04:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a06:	2781                	sext.w	a5,a5
    80001a08:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a0a:	00016517          	auipc	a0,0x16
    80001a0e:	11650513          	addi	a0,a0,278 # 80017b20 <cpus>
    80001a12:	953e                	add	a0,a0,a5
    80001a14:	6422                	ld	s0,8(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret

0000000080001a1a <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001a1a:	1101                	addi	sp,sp,-32
    80001a1c:	ec06                	sd	ra,24(sp)
    80001a1e:	e822                	sd	s0,16(sp)
    80001a20:	e426                	sd	s1,8(sp)
    80001a22:	1000                	addi	s0,sp,32
  push_off();
    80001a24:	a8aff0ef          	jal	ra,80000cae <push_off>
    80001a28:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a2a:	2781                	sext.w	a5,a5
    80001a2c:	079e                	slli	a5,a5,0x7
    80001a2e:	00016717          	auipc	a4,0x16
    80001a32:	0c270713          	addi	a4,a4,194 # 80017af0 <pid_lock>
    80001a36:	97ba                	add	a5,a5,a4
    80001a38:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a3a:	af8ff0ef          	jal	ra,80000d32 <pop_off>
  return p;
}
    80001a3e:	8526                	mv	a0,s1
    80001a40:	60e2                	ld	ra,24(sp)
    80001a42:	6442                	ld	s0,16(sp)
    80001a44:	64a2                	ld	s1,8(sp)
    80001a46:	6105                	addi	sp,sp,32
    80001a48:	8082                	ret

0000000080001a4a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a4a:	7179                	addi	sp,sp,-48
    80001a4c:	f406                	sd	ra,40(sp)
    80001a4e:	f022                	sd	s0,32(sp)
    80001a50:	ec26                	sd	s1,24(sp)
    80001a52:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    80001a54:	fc7ff0ef          	jal	ra,80001a1a <myproc>
    80001a58:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    80001a5a:	b2cff0ef          	jal	ra,80000d86 <release>

  if (first) {
    80001a5e:	00006797          	auipc	a5,0x6
    80001a62:	f827a783          	lw	a5,-126(a5) # 800079e0 <first.1>
    80001a66:	cf8d                	beqz	a5,80001aa0 <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    80001a68:	4505                	li	a0,1
    80001a6a:	555010ef          	jal	ra,800037be <fsinit>

    first = 0;
    80001a6e:	00006797          	auipc	a5,0x6
    80001a72:	f607a923          	sw	zero,-142(a5) # 800079e0 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    80001a76:	0ff0000f          	fence

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    80001a7a:	00005517          	auipc	a0,0x5
    80001a7e:	7ee50513          	addi	a0,a0,2030 # 80007268 <digits+0x230>
    80001a82:	fca43823          	sd	a0,-48(s0)
    80001a86:	fc043c23          	sd	zero,-40(s0)
    80001a8a:	fd040593          	addi	a1,s0,-48
    80001a8e:	5d9020ef          	jal	ra,80004866 <kexec>
    80001a92:	6cbc                	ld	a5,88(s1)
    80001a94:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    80001a96:	6cbc                	ld	a5,88(s1)
    80001a98:	7bb8                	ld	a4,112(a5)
    80001a9a:	57fd                	li	a5,-1
    80001a9c:	02f70d63          	beq	a4,a5,80001ad6 <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    80001aa0:	35f000ef          	jal	ra,800025fe <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80001aa4:	68a8                	ld	a0,80(s1)
    80001aa6:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80001aa8:	04000737          	lui	a4,0x4000
    80001aac:	00004797          	auipc	a5,0x4
    80001ab0:	5f078793          	addi	a5,a5,1520 # 8000609c <userret>
    80001ab4:	00004697          	auipc	a3,0x4
    80001ab8:	54c68693          	addi	a3,a3,1356 # 80006000 <_trampoline>
    80001abc:	8f95                	sub	a5,a5,a3
    80001abe:	177d                	addi	a4,a4,-1
    80001ac0:	0732                	slli	a4,a4,0xc
    80001ac2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80001ac4:	577d                	li	a4,-1
    80001ac6:	177e                	slli	a4,a4,0x3f
    80001ac8:	8d59                	or	a0,a0,a4
    80001aca:	9782                	jalr	a5
}
    80001acc:	70a2                	ld	ra,40(sp)
    80001ace:	7402                	ld	s0,32(sp)
    80001ad0:	64e2                	ld	s1,24(sp)
    80001ad2:	6145                	addi	sp,sp,48
    80001ad4:	8082                	ret
      panic("exec");
    80001ad6:	00005517          	auipc	a0,0x5
    80001ada:	79a50513          	addi	a0,a0,1946 # 80007270 <digits+0x238>
    80001ade:	cadfe0ef          	jal	ra,8000078a <panic>

0000000080001ae2 <allocpid>:
{
    80001ae2:	1101                	addi	sp,sp,-32
    80001ae4:	ec06                	sd	ra,24(sp)
    80001ae6:	e822                	sd	s0,16(sp)
    80001ae8:	e426                	sd	s1,8(sp)
    80001aea:	e04a                	sd	s2,0(sp)
    80001aec:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aee:	00016917          	auipc	s2,0x16
    80001af2:	00290913          	addi	s2,s2,2 # 80017af0 <pid_lock>
    80001af6:	854a                	mv	a0,s2
    80001af8:	9f6ff0ef          	jal	ra,80000cee <acquire>
  pid = nextpid;
    80001afc:	00006797          	auipc	a5,0x6
    80001b00:	ee878793          	addi	a5,a5,-280 # 800079e4 <nextpid>
    80001b04:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b06:	0014871b          	addiw	a4,s1,1
    80001b0a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b0c:	854a                	mv	a0,s2
    80001b0e:	a78ff0ef          	jal	ra,80000d86 <release>
}
    80001b12:	8526                	mv	a0,s1
    80001b14:	60e2                	ld	ra,24(sp)
    80001b16:	6442                	ld	s0,16(sp)
    80001b18:	64a2                	ld	s1,8(sp)
    80001b1a:	6902                	ld	s2,0(sp)
    80001b1c:	6105                	addi	sp,sp,32
    80001b1e:	8082                	ret

0000000080001b20 <proc_pagetable>:
{
    80001b20:	1101                	addi	sp,sp,-32
    80001b22:	ec06                	sd	ra,24(sp)
    80001b24:	e822                	sd	s0,16(sp)
    80001b26:	e426                	sd	s1,8(sp)
    80001b28:	e04a                	sd	s2,0(sp)
    80001b2a:	1000                	addi	s0,sp,32
    80001b2c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b2e:	f94ff0ef          	jal	ra,800012c2 <uvmcreate>
    80001b32:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b34:	cd05                	beqz	a0,80001b6c <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b36:	4729                	li	a4,10
    80001b38:	00004697          	auipc	a3,0x4
    80001b3c:	4c868693          	addi	a3,a3,1224 # 80006000 <_trampoline>
    80001b40:	6605                	lui	a2,0x1
    80001b42:	040005b7          	lui	a1,0x4000
    80001b46:	15fd                	addi	a1,a1,-1
    80001b48:	05b2                	slli	a1,a1,0xc
    80001b4a:	dccff0ef          	jal	ra,80001116 <mappages>
    80001b4e:	02054663          	bltz	a0,80001b7a <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b52:	4719                	li	a4,6
    80001b54:	05893683          	ld	a3,88(s2)
    80001b58:	6605                	lui	a2,0x1
    80001b5a:	020005b7          	lui	a1,0x2000
    80001b5e:	15fd                	addi	a1,a1,-1
    80001b60:	05b6                	slli	a1,a1,0xd
    80001b62:	8526                	mv	a0,s1
    80001b64:	db2ff0ef          	jal	ra,80001116 <mappages>
    80001b68:	00054f63          	bltz	a0,80001b86 <proc_pagetable+0x66>
}
    80001b6c:	8526                	mv	a0,s1
    80001b6e:	60e2                	ld	ra,24(sp)
    80001b70:	6442                	ld	s0,16(sp)
    80001b72:	64a2                	ld	s1,8(sp)
    80001b74:	6902                	ld	s2,0(sp)
    80001b76:	6105                	addi	sp,sp,32
    80001b78:	8082                	ret
    uvmfree(pagetable, 0);
    80001b7a:	4581                	li	a1,0
    80001b7c:	8526                	mv	a0,s1
    80001b7e:	923ff0ef          	jal	ra,800014a0 <uvmfree>
    return 0;
    80001b82:	4481                	li	s1,0
    80001b84:	b7e5                	j	80001b6c <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b86:	4681                	li	a3,0
    80001b88:	4605                	li	a2,1
    80001b8a:	040005b7          	lui	a1,0x4000
    80001b8e:	15fd                	addi	a1,a1,-1
    80001b90:	05b2                	slli	a1,a1,0xc
    80001b92:	8526                	mv	a0,s1
    80001b94:	f54ff0ef          	jal	ra,800012e8 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b98:	4581                	li	a1,0
    80001b9a:	8526                	mv	a0,s1
    80001b9c:	905ff0ef          	jal	ra,800014a0 <uvmfree>
    return 0;
    80001ba0:	4481                	li	s1,0
    80001ba2:	b7e9                	j	80001b6c <proc_pagetable+0x4c>

0000000080001ba4 <proc_freepagetable>:
{
    80001ba4:	1101                	addi	sp,sp,-32
    80001ba6:	ec06                	sd	ra,24(sp)
    80001ba8:	e822                	sd	s0,16(sp)
    80001baa:	e426                	sd	s1,8(sp)
    80001bac:	e04a                	sd	s2,0(sp)
    80001bae:	1000                	addi	s0,sp,32
    80001bb0:	84aa                	mv	s1,a0
    80001bb2:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bb4:	4681                	li	a3,0
    80001bb6:	4605                	li	a2,1
    80001bb8:	040005b7          	lui	a1,0x4000
    80001bbc:	15fd                	addi	a1,a1,-1
    80001bbe:	05b2                	slli	a1,a1,0xc
    80001bc0:	f28ff0ef          	jal	ra,800012e8 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bc4:	4681                	li	a3,0
    80001bc6:	4605                	li	a2,1
    80001bc8:	020005b7          	lui	a1,0x2000
    80001bcc:	15fd                	addi	a1,a1,-1
    80001bce:	05b6                	slli	a1,a1,0xd
    80001bd0:	8526                	mv	a0,s1
    80001bd2:	f16ff0ef          	jal	ra,800012e8 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bd6:	85ca                	mv	a1,s2
    80001bd8:	8526                	mv	a0,s1
    80001bda:	8c7ff0ef          	jal	ra,800014a0 <uvmfree>
}
    80001bde:	60e2                	ld	ra,24(sp)
    80001be0:	6442                	ld	s0,16(sp)
    80001be2:	64a2                	ld	s1,8(sp)
    80001be4:	6902                	ld	s2,0(sp)
    80001be6:	6105                	addi	sp,sp,32
    80001be8:	8082                	ret

0000000080001bea <freeproc>:
{
    80001bea:	1101                	addi	sp,sp,-32
    80001bec:	ec06                	sd	ra,24(sp)
    80001bee:	e822                	sd	s0,16(sp)
    80001bf0:	e426                	sd	s1,8(sp)
    80001bf2:	1000                	addi	s0,sp,32
    80001bf4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bf6:	6d28                	ld	a0,88(a0)
    80001bf8:	c119                	beqz	a0,80001bfe <freeproc+0x14>
    kfree((void*)p->trapframe);
    80001bfa:	eaffe0ef          	jal	ra,80000aa8 <kfree>
  p->trapframe = 0;
    80001bfe:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c02:	68a8                	ld	a0,80(s1)
    80001c04:	c501                	beqz	a0,80001c0c <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001c06:	64ac                	ld	a1,72(s1)
    80001c08:	f9dff0ef          	jal	ra,80001ba4 <proc_freepagetable>
  p->pagetable = 0;
    80001c0c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c10:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c14:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c18:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c1c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c20:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c24:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c28:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c2c:	0004ac23          	sw	zero,24(s1)
}
    80001c30:	60e2                	ld	ra,24(sp)
    80001c32:	6442                	ld	s0,16(sp)
    80001c34:	64a2                	ld	s1,8(sp)
    80001c36:	6105                	addi	sp,sp,32
    80001c38:	8082                	ret

0000000080001c3a <allocproc>:
{
    80001c3a:	1101                	addi	sp,sp,-32
    80001c3c:	ec06                	sd	ra,24(sp)
    80001c3e:	e822                	sd	s0,16(sp)
    80001c40:	e426                	sd	s1,8(sp)
    80001c42:	e04a                	sd	s2,0(sp)
    80001c44:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c46:	00016497          	auipc	s1,0x16
    80001c4a:	2da48493          	addi	s1,s1,730 # 80017f20 <proc>
    80001c4e:	0001c917          	auipc	s2,0x1c
    80001c52:	ed290913          	addi	s2,s2,-302 # 8001db20 <tickslock>
    acquire(&p->lock);
    80001c56:	8526                	mv	a0,s1
    80001c58:	896ff0ef          	jal	ra,80000cee <acquire>
    if(p->state == UNUSED) {
    80001c5c:	4c9c                	lw	a5,24(s1)
    80001c5e:	cb91                	beqz	a5,80001c72 <allocproc+0x38>
      release(&p->lock);
    80001c60:	8526                	mv	a0,s1
    80001c62:	924ff0ef          	jal	ra,80000d86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c66:	17048493          	addi	s1,s1,368
    80001c6a:	ff2496e3          	bne	s1,s2,80001c56 <allocproc+0x1c>
  return 0;
    80001c6e:	4481                	li	s1,0
    80001c70:	a0b1                	j	80001cbc <allocproc+0x82>
  p->pid = allocpid();
    80001c72:	e71ff0ef          	jal	ra,80001ae2 <allocpid>
    80001c76:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c78:	4785                	li	a5,1
    80001c7a:	cc9c                	sw	a5,24(s1)
  p->ticks = 0;
    80001c7c:	1604a423          	sw	zero,360(s1)
  p->timeslice =5;
    80001c80:	4795                	li	a5,5
    80001c82:	16f4a623          	sw	a5,364(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c86:	f69fe0ef          	jal	ra,80000bee <kalloc>
    80001c8a:	892a                	mv	s2,a0
    80001c8c:	eca8                	sd	a0,88(s1)
    80001c8e:	cd15                	beqz	a0,80001cca <allocproc+0x90>
  p->pagetable = proc_pagetable(p);
    80001c90:	8526                	mv	a0,s1
    80001c92:	e8fff0ef          	jal	ra,80001b20 <proc_pagetable>
    80001c96:	892a                	mv	s2,a0
    80001c98:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c9a:	c121                	beqz	a0,80001cda <allocproc+0xa0>
  memset(&p->context, 0, sizeof(p->context));
    80001c9c:	07000613          	li	a2,112
    80001ca0:	4581                	li	a1,0
    80001ca2:	06048513          	addi	a0,s1,96
    80001ca6:	91cff0ef          	jal	ra,80000dc2 <memset>
  p->context.ra = (uint64)forkret;
    80001caa:	00000797          	auipc	a5,0x0
    80001cae:	da078793          	addi	a5,a5,-608 # 80001a4a <forkret>
    80001cb2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cb4:	60bc                	ld	a5,64(s1)
    80001cb6:	6705                	lui	a4,0x1
    80001cb8:	97ba                	add	a5,a5,a4
    80001cba:	f4bc                	sd	a5,104(s1)
}
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	60e2                	ld	ra,24(sp)
    80001cc0:	6442                	ld	s0,16(sp)
    80001cc2:	64a2                	ld	s1,8(sp)
    80001cc4:	6902                	ld	s2,0(sp)
    80001cc6:	6105                	addi	sp,sp,32
    80001cc8:	8082                	ret
    freeproc(p);
    80001cca:	8526                	mv	a0,s1
    80001ccc:	f1fff0ef          	jal	ra,80001bea <freeproc>
    release(&p->lock);
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	8b4ff0ef          	jal	ra,80000d86 <release>
    return 0;
    80001cd6:	84ca                	mv	s1,s2
    80001cd8:	b7d5                	j	80001cbc <allocproc+0x82>
    freeproc(p);
    80001cda:	8526                	mv	a0,s1
    80001cdc:	f0fff0ef          	jal	ra,80001bea <freeproc>
    release(&p->lock);
    80001ce0:	8526                	mv	a0,s1
    80001ce2:	8a4ff0ef          	jal	ra,80000d86 <release>
    return 0;
    80001ce6:	84ca                	mv	s1,s2
    80001ce8:	bfd1                	j	80001cbc <allocproc+0x82>

0000000080001cea <userinit>:
{
    80001cea:	1101                	addi	sp,sp,-32
    80001cec:	ec06                	sd	ra,24(sp)
    80001cee:	e822                	sd	s0,16(sp)
    80001cf0:	e426                	sd	s1,8(sp)
    80001cf2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cf4:	f47ff0ef          	jal	ra,80001c3a <allocproc>
    80001cf8:	84aa                	mv	s1,a0
  initproc = p;
    80001cfa:	00006797          	auipc	a5,0x6
    80001cfe:	d0a7bb23          	sd	a0,-746(a5) # 80007a10 <initproc>
  p->cwd = namei("/");
    80001d02:	00005517          	auipc	a0,0x5
    80001d06:	57650513          	addi	a0,a0,1398 # 80007278 <digits+0x240>
    80001d0a:	7b3010ef          	jal	ra,80003cbc <namei>
    80001d0e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d12:	478d                	li	a5,3
    80001d14:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d16:	8526                	mv	a0,s1
    80001d18:	86eff0ef          	jal	ra,80000d86 <release>
}
    80001d1c:	60e2                	ld	ra,24(sp)
    80001d1e:	6442                	ld	s0,16(sp)
    80001d20:	64a2                	ld	s1,8(sp)
    80001d22:	6105                	addi	sp,sp,32
    80001d24:	8082                	ret

0000000080001d26 <growproc>:
{
    80001d26:	1101                	addi	sp,sp,-32
    80001d28:	ec06                	sd	ra,24(sp)
    80001d2a:	e822                	sd	s0,16(sp)
    80001d2c:	e426                	sd	s1,8(sp)
    80001d2e:	e04a                	sd	s2,0(sp)
    80001d30:	1000                	addi	s0,sp,32
    80001d32:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d34:	ce7ff0ef          	jal	ra,80001a1a <myproc>
    80001d38:	892a                	mv	s2,a0
  sz = p->sz;
    80001d3a:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d3c:	02905963          	blez	s1,80001d6e <growproc+0x48>
    if(sz + n > TRAPFRAME) {
    80001d40:	00b48633          	add	a2,s1,a1
    80001d44:	020007b7          	lui	a5,0x2000
    80001d48:	17fd                	addi	a5,a5,-1
    80001d4a:	07b6                	slli	a5,a5,0xd
    80001d4c:	02c7ea63          	bltu	a5,a2,80001d80 <growproc+0x5a>
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d50:	4691                	li	a3,4
    80001d52:	6928                	ld	a0,80(a0)
    80001d54:	e54ff0ef          	jal	ra,800013a8 <uvmalloc>
    80001d58:	85aa                	mv	a1,a0
    80001d5a:	c50d                	beqz	a0,80001d84 <growproc+0x5e>
  p->sz = sz;
    80001d5c:	04b93423          	sd	a1,72(s2)
  return 0;
    80001d60:	4501                	li	a0,0
}
    80001d62:	60e2                	ld	ra,24(sp)
    80001d64:	6442                	ld	s0,16(sp)
    80001d66:	64a2                	ld	s1,8(sp)
    80001d68:	6902                	ld	s2,0(sp)
    80001d6a:	6105                	addi	sp,sp,32
    80001d6c:	8082                	ret
  } else if(n < 0){
    80001d6e:	fe04d7e3          	bgez	s1,80001d5c <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d72:	00b48633          	add	a2,s1,a1
    80001d76:	6928                	ld	a0,80(a0)
    80001d78:	decff0ef          	jal	ra,80001364 <uvmdealloc>
    80001d7c:	85aa                	mv	a1,a0
    80001d7e:	bff9                	j	80001d5c <growproc+0x36>
      return -1;
    80001d80:	557d                	li	a0,-1
    80001d82:	b7c5                	j	80001d62 <growproc+0x3c>
      return -1;
    80001d84:	557d                	li	a0,-1
    80001d86:	bff1                	j	80001d62 <growproc+0x3c>

0000000080001d88 <kfork>:
{
    80001d88:	7139                	addi	sp,sp,-64
    80001d8a:	fc06                	sd	ra,56(sp)
    80001d8c:	f822                	sd	s0,48(sp)
    80001d8e:	f426                	sd	s1,40(sp)
    80001d90:	f04a                	sd	s2,32(sp)
    80001d92:	ec4e                	sd	s3,24(sp)
    80001d94:	e852                	sd	s4,16(sp)
    80001d96:	e456                	sd	s5,8(sp)
    80001d98:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d9a:	c81ff0ef          	jal	ra,80001a1a <myproc>
    80001d9e:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001da0:	e9bff0ef          	jal	ra,80001c3a <allocproc>
    80001da4:	0e050663          	beqz	a0,80001e90 <kfork+0x108>
    80001da8:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001daa:	048ab603          	ld	a2,72(s5)
    80001dae:	692c                	ld	a1,80(a0)
    80001db0:	050ab503          	ld	a0,80(s5)
    80001db4:	f1cff0ef          	jal	ra,800014d0 <uvmcopy>
    80001db8:	04054863          	bltz	a0,80001e08 <kfork+0x80>
  np->sz = p->sz;
    80001dbc:	048ab783          	ld	a5,72(s5)
    80001dc0:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dc4:	058ab683          	ld	a3,88(s5)
    80001dc8:	87b6                	mv	a5,a3
    80001dca:	058a3703          	ld	a4,88(s4)
    80001dce:	12068693          	addi	a3,a3,288
    80001dd2:	0007b803          	ld	a6,0(a5) # 2000000 <_entry-0x7e000000>
    80001dd6:	6788                	ld	a0,8(a5)
    80001dd8:	6b8c                	ld	a1,16(a5)
    80001dda:	6f90                	ld	a2,24(a5)
    80001ddc:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001de0:	e708                	sd	a0,8(a4)
    80001de2:	eb0c                	sd	a1,16(a4)
    80001de4:	ef10                	sd	a2,24(a4)
    80001de6:	02078793          	addi	a5,a5,32
    80001dea:	02070713          	addi	a4,a4,32
    80001dee:	fed792e3          	bne	a5,a3,80001dd2 <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001df2:	058a3783          	ld	a5,88(s4)
    80001df6:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dfa:	0d0a8493          	addi	s1,s5,208
    80001dfe:	0d0a0913          	addi	s2,s4,208
    80001e02:	150a8993          	addi	s3,s5,336
    80001e06:	a829                	j	80001e20 <kfork+0x98>
    freeproc(np);
    80001e08:	8552                	mv	a0,s4
    80001e0a:	de1ff0ef          	jal	ra,80001bea <freeproc>
    release(&np->lock);
    80001e0e:	8552                	mv	a0,s4
    80001e10:	f77fe0ef          	jal	ra,80000d86 <release>
    return -1;
    80001e14:	597d                	li	s2,-1
    80001e16:	a09d                	j	80001e7c <kfork+0xf4>
  for(i = 0; i < NOFILE; i++)
    80001e18:	04a1                	addi	s1,s1,8
    80001e1a:	0921                	addi	s2,s2,8
    80001e1c:	01348963          	beq	s1,s3,80001e2e <kfork+0xa6>
    if(p->ofile[i])
    80001e20:	6088                	ld	a0,0(s1)
    80001e22:	d97d                	beqz	a0,80001e18 <kfork+0x90>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e24:	450020ef          	jal	ra,80004274 <filedup>
    80001e28:	00a93023          	sd	a0,0(s2)
    80001e2c:	b7f5                	j	80001e18 <kfork+0x90>
  np->cwd = idup(p->cwd);
    80001e2e:	150ab503          	ld	a0,336(s5)
    80001e32:	666010ef          	jal	ra,80003498 <idup>
    80001e36:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e3a:	4641                	li	a2,16
    80001e3c:	158a8593          	addi	a1,s5,344
    80001e40:	158a0513          	addi	a0,s4,344
    80001e44:	8c4ff0ef          	jal	ra,80000f08 <safestrcpy>
  pid = np->pid;
    80001e48:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e4c:	8552                	mv	a0,s4
    80001e4e:	f39fe0ef          	jal	ra,80000d86 <release>
  acquire(&wait_lock);
    80001e52:	00016497          	auipc	s1,0x16
    80001e56:	cb648493          	addi	s1,s1,-842 # 80017b08 <wait_lock>
    80001e5a:	8526                	mv	a0,s1
    80001e5c:	e93fe0ef          	jal	ra,80000cee <acquire>
  np->parent = p;
    80001e60:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e64:	8526                	mv	a0,s1
    80001e66:	f21fe0ef          	jal	ra,80000d86 <release>
  acquire(&np->lock);
    80001e6a:	8552                	mv	a0,s4
    80001e6c:	e83fe0ef          	jal	ra,80000cee <acquire>
  np->state = RUNNABLE;
    80001e70:	478d                	li	a5,3
    80001e72:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e76:	8552                	mv	a0,s4
    80001e78:	f0ffe0ef          	jal	ra,80000d86 <release>
}
    80001e7c:	854a                	mv	a0,s2
    80001e7e:	70e2                	ld	ra,56(sp)
    80001e80:	7442                	ld	s0,48(sp)
    80001e82:	74a2                	ld	s1,40(sp)
    80001e84:	7902                	ld	s2,32(sp)
    80001e86:	69e2                	ld	s3,24(sp)
    80001e88:	6a42                	ld	s4,16(sp)
    80001e8a:	6aa2                	ld	s5,8(sp)
    80001e8c:	6121                	addi	sp,sp,64
    80001e8e:	8082                	ret
    return -1;
    80001e90:	597d                	li	s2,-1
    80001e92:	b7ed                	j	80001e7c <kfork+0xf4>

0000000080001e94 <scheduler>:
{
    80001e94:	715d                	addi	sp,sp,-80
    80001e96:	e486                	sd	ra,72(sp)
    80001e98:	e0a2                	sd	s0,64(sp)
    80001e9a:	fc26                	sd	s1,56(sp)
    80001e9c:	f84a                	sd	s2,48(sp)
    80001e9e:	f44e                	sd	s3,40(sp)
    80001ea0:	f052                	sd	s4,32(sp)
    80001ea2:	ec56                	sd	s5,24(sp)
    80001ea4:	e85a                	sd	s6,16(sp)
    80001ea6:	e45e                	sd	s7,8(sp)
    80001ea8:	e062                	sd	s8,0(sp)
    80001eaa:	0880                	addi	s0,sp,80
    80001eac:	8792                	mv	a5,tp
  int id = r_tp();
    80001eae:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eb0:	00779b13          	slli	s6,a5,0x7
    80001eb4:	00016717          	auipc	a4,0x16
    80001eb8:	c3c70713          	addi	a4,a4,-964 # 80017af0 <pid_lock>
    80001ebc:	975a                	add	a4,a4,s6
    80001ebe:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ec2:	00016717          	auipc	a4,0x16
    80001ec6:	c6670713          	addi	a4,a4,-922 # 80017b28 <cpus+0x8>
    80001eca:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001ecc:	4c11                	li	s8,4
        c->proc = p;
    80001ece:	079e                	slli	a5,a5,0x7
    80001ed0:	00016a17          	auipc	s4,0x16
    80001ed4:	c20a0a13          	addi	s4,s4,-992 # 80017af0 <pid_lock>
    80001ed8:	9a3e                	add	s4,s4,a5
        found = 1;
    80001eda:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001edc:	0001c997          	auipc	s3,0x1c
    80001ee0:	c4498993          	addi	s3,s3,-956 # 8001db20 <tickslock>
    80001ee4:	a83d                	j	80001f22 <scheduler+0x8e>
      release(&p->lock);
    80001ee6:	8526                	mv	a0,s1
    80001ee8:	e9ffe0ef          	jal	ra,80000d86 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001eec:	17048493          	addi	s1,s1,368
    80001ef0:	03348563          	beq	s1,s3,80001f1a <scheduler+0x86>
      acquire(&p->lock);
    80001ef4:	8526                	mv	a0,s1
    80001ef6:	df9fe0ef          	jal	ra,80000cee <acquire>
      if(p->state == RUNNABLE) {
    80001efa:	4c9c                	lw	a5,24(s1)
    80001efc:	ff2795e3          	bne	a5,s2,80001ee6 <scheduler+0x52>
        p->state = RUNNING;
    80001f00:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001f04:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f08:	06048593          	addi	a1,s1,96
    80001f0c:	855a                	mv	a0,s6
    80001f0e:	64a000ef          	jal	ra,80002558 <swtch>
        c->proc = 0;
    80001f12:	020a3823          	sd	zero,48(s4)
        found = 1;
    80001f16:	8ade                	mv	s5,s7
    80001f18:	b7f9                	j	80001ee6 <scheduler+0x52>
    if(found == 0) {
    80001f1a:	000a9463          	bnez	s5,80001f22 <scheduler+0x8e>
      asm volatile("wfi");
    80001f1e:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f22:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f26:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f2a:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f2e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001f32:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f34:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001f38:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f3a:	00016497          	auipc	s1,0x16
    80001f3e:	fe648493          	addi	s1,s1,-26 # 80017f20 <proc>
      if(p->state == RUNNABLE) {
    80001f42:	490d                	li	s2,3
    80001f44:	bf45                	j	80001ef4 <scheduler+0x60>

0000000080001f46 <sched>:
{
    80001f46:	7179                	addi	sp,sp,-48
    80001f48:	f406                	sd	ra,40(sp)
    80001f4a:	f022                	sd	s0,32(sp)
    80001f4c:	ec26                	sd	s1,24(sp)
    80001f4e:	e84a                	sd	s2,16(sp)
    80001f50:	e44e                	sd	s3,8(sp)
    80001f52:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f54:	ac7ff0ef          	jal	ra,80001a1a <myproc>
    80001f58:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f5a:	d2bfe0ef          	jal	ra,80000c84 <holding>
    80001f5e:	c92d                	beqz	a0,80001fd0 <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f60:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f62:	2781                	sext.w	a5,a5
    80001f64:	079e                	slli	a5,a5,0x7
    80001f66:	00016717          	auipc	a4,0x16
    80001f6a:	b8a70713          	addi	a4,a4,-1142 # 80017af0 <pid_lock>
    80001f6e:	97ba                	add	a5,a5,a4
    80001f70:	0a87a703          	lw	a4,168(a5)
    80001f74:	4785                	li	a5,1
    80001f76:	06f71363          	bne	a4,a5,80001fdc <sched+0x96>
  if(p->state == RUNNING)
    80001f7a:	4c98                	lw	a4,24(s1)
    80001f7c:	4791                	li	a5,4
    80001f7e:	06f70563          	beq	a4,a5,80001fe8 <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f82:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f86:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f88:	e7b5                	bnez	a5,80001ff4 <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f8c:	00016917          	auipc	s2,0x16
    80001f90:	b6490913          	addi	s2,s2,-1180 # 80017af0 <pid_lock>
    80001f94:	2781                	sext.w	a5,a5
    80001f96:	079e                	slli	a5,a5,0x7
    80001f98:	97ca                	add	a5,a5,s2
    80001f9a:	0ac7a983          	lw	s3,172(a5)
    80001f9e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa0:	2781                	sext.w	a5,a5
    80001fa2:	079e                	slli	a5,a5,0x7
    80001fa4:	00016597          	auipc	a1,0x16
    80001fa8:	b8458593          	addi	a1,a1,-1148 # 80017b28 <cpus+0x8>
    80001fac:	95be                	add	a1,a1,a5
    80001fae:	06048513          	addi	a0,s1,96
    80001fb2:	5a6000ef          	jal	ra,80002558 <swtch>
    80001fb6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fb8:	2781                	sext.w	a5,a5
    80001fba:	079e                	slli	a5,a5,0x7
    80001fbc:	97ca                	add	a5,a5,s2
    80001fbe:	0b37a623          	sw	s3,172(a5)
}
    80001fc2:	70a2                	ld	ra,40(sp)
    80001fc4:	7402                	ld	s0,32(sp)
    80001fc6:	64e2                	ld	s1,24(sp)
    80001fc8:	6942                	ld	s2,16(sp)
    80001fca:	69a2                	ld	s3,8(sp)
    80001fcc:	6145                	addi	sp,sp,48
    80001fce:	8082                	ret
    panic("sched p->lock");
    80001fd0:	00005517          	auipc	a0,0x5
    80001fd4:	2b050513          	addi	a0,a0,688 # 80007280 <digits+0x248>
    80001fd8:	fb2fe0ef          	jal	ra,8000078a <panic>
    panic("sched locks");
    80001fdc:	00005517          	auipc	a0,0x5
    80001fe0:	2b450513          	addi	a0,a0,692 # 80007290 <digits+0x258>
    80001fe4:	fa6fe0ef          	jal	ra,8000078a <panic>
    panic("sched RUNNING");
    80001fe8:	00005517          	auipc	a0,0x5
    80001fec:	2b850513          	addi	a0,a0,696 # 800072a0 <digits+0x268>
    80001ff0:	f9afe0ef          	jal	ra,8000078a <panic>
    panic("sched interruptible");
    80001ff4:	00005517          	auipc	a0,0x5
    80001ff8:	2bc50513          	addi	a0,a0,700 # 800072b0 <digits+0x278>
    80001ffc:	f8efe0ef          	jal	ra,8000078a <panic>

0000000080002000 <yield>:
{
    80002000:	1101                	addi	sp,sp,-32
    80002002:	ec06                	sd	ra,24(sp)
    80002004:	e822                	sd	s0,16(sp)
    80002006:	e426                	sd	s1,8(sp)
    80002008:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000200a:	a11ff0ef          	jal	ra,80001a1a <myproc>
    8000200e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002010:	cdffe0ef          	jal	ra,80000cee <acquire>
  p->state = RUNNABLE;
    80002014:	478d                	li	a5,3
    80002016:	cc9c                	sw	a5,24(s1)
  sched();
    80002018:	f2fff0ef          	jal	ra,80001f46 <sched>
  release(&p->lock);
    8000201c:	8526                	mv	a0,s1
    8000201e:	d69fe0ef          	jal	ra,80000d86 <release>
}
    80002022:	60e2                	ld	ra,24(sp)
    80002024:	6442                	ld	s0,16(sp)
    80002026:	64a2                	ld	s1,8(sp)
    80002028:	6105                	addi	sp,sp,32
    8000202a:	8082                	ret

000000008000202c <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000202c:	7179                	addi	sp,sp,-48
    8000202e:	f406                	sd	ra,40(sp)
    80002030:	f022                	sd	s0,32(sp)
    80002032:	ec26                	sd	s1,24(sp)
    80002034:	e84a                	sd	s2,16(sp)
    80002036:	e44e                	sd	s3,8(sp)
    80002038:	1800                	addi	s0,sp,48
    8000203a:	89aa                	mv	s3,a0
    8000203c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000203e:	9ddff0ef          	jal	ra,80001a1a <myproc>
    80002042:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002044:	cabfe0ef          	jal	ra,80000cee <acquire>
  release(lk);
    80002048:	854a                	mv	a0,s2
    8000204a:	d3dfe0ef          	jal	ra,80000d86 <release>

  // Go to sleep.
  p->chan = chan;
    8000204e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002052:	4789                	li	a5,2
    80002054:	cc9c                	sw	a5,24(s1)

  sched();
    80002056:	ef1ff0ef          	jal	ra,80001f46 <sched>

  // Tidy up.
  p->chan = 0;
    8000205a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000205e:	8526                	mv	a0,s1
    80002060:	d27fe0ef          	jal	ra,80000d86 <release>
  acquire(lk);
    80002064:	854a                	mv	a0,s2
    80002066:	c89fe0ef          	jal	ra,80000cee <acquire>
}
    8000206a:	70a2                	ld	ra,40(sp)
    8000206c:	7402                	ld	s0,32(sp)
    8000206e:	64e2                	ld	s1,24(sp)
    80002070:	6942                	ld	s2,16(sp)
    80002072:	69a2                	ld	s3,8(sp)
    80002074:	6145                	addi	sp,sp,48
    80002076:	8082                	ret

0000000080002078 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    80002078:	7139                	addi	sp,sp,-64
    8000207a:	fc06                	sd	ra,56(sp)
    8000207c:	f822                	sd	s0,48(sp)
    8000207e:	f426                	sd	s1,40(sp)
    80002080:	f04a                	sd	s2,32(sp)
    80002082:	ec4e                	sd	s3,24(sp)
    80002084:	e852                	sd	s4,16(sp)
    80002086:	e456                	sd	s5,8(sp)
    80002088:	0080                	addi	s0,sp,64
    8000208a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000208c:	00016497          	auipc	s1,0x16
    80002090:	e9448493          	addi	s1,s1,-364 # 80017f20 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002094:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002096:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002098:	0001c917          	auipc	s2,0x1c
    8000209c:	a8890913          	addi	s2,s2,-1400 # 8001db20 <tickslock>
    800020a0:	a801                	j	800020b0 <wakeup+0x38>
      }
      release(&p->lock);
    800020a2:	8526                	mv	a0,s1
    800020a4:	ce3fe0ef          	jal	ra,80000d86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020a8:	17048493          	addi	s1,s1,368
    800020ac:	03248263          	beq	s1,s2,800020d0 <wakeup+0x58>
    if(p != myproc()){
    800020b0:	96bff0ef          	jal	ra,80001a1a <myproc>
    800020b4:	fea48ae3          	beq	s1,a0,800020a8 <wakeup+0x30>
      acquire(&p->lock);
    800020b8:	8526                	mv	a0,s1
    800020ba:	c35fe0ef          	jal	ra,80000cee <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800020be:	4c9c                	lw	a5,24(s1)
    800020c0:	ff3791e3          	bne	a5,s3,800020a2 <wakeup+0x2a>
    800020c4:	709c                	ld	a5,32(s1)
    800020c6:	fd479ee3          	bne	a5,s4,800020a2 <wakeup+0x2a>
        p->state = RUNNABLE;
    800020ca:	0154ac23          	sw	s5,24(s1)
    800020ce:	bfd1                	j	800020a2 <wakeup+0x2a>
    }
  }
}
    800020d0:	70e2                	ld	ra,56(sp)
    800020d2:	7442                	ld	s0,48(sp)
    800020d4:	74a2                	ld	s1,40(sp)
    800020d6:	7902                	ld	s2,32(sp)
    800020d8:	69e2                	ld	s3,24(sp)
    800020da:	6a42                	ld	s4,16(sp)
    800020dc:	6aa2                	ld	s5,8(sp)
    800020de:	6121                	addi	sp,sp,64
    800020e0:	8082                	ret

00000000800020e2 <reparent>:
{
    800020e2:	7179                	addi	sp,sp,-48
    800020e4:	f406                	sd	ra,40(sp)
    800020e6:	f022                	sd	s0,32(sp)
    800020e8:	ec26                	sd	s1,24(sp)
    800020ea:	e84a                	sd	s2,16(sp)
    800020ec:	e44e                	sd	s3,8(sp)
    800020ee:	e052                	sd	s4,0(sp)
    800020f0:	1800                	addi	s0,sp,48
    800020f2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800020f4:	00016497          	auipc	s1,0x16
    800020f8:	e2c48493          	addi	s1,s1,-468 # 80017f20 <proc>
      pp->parent = initproc;
    800020fc:	00006a17          	auipc	s4,0x6
    80002100:	914a0a13          	addi	s4,s4,-1772 # 80007a10 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002104:	0001c997          	auipc	s3,0x1c
    80002108:	a1c98993          	addi	s3,s3,-1508 # 8001db20 <tickslock>
    8000210c:	a029                	j	80002116 <reparent+0x34>
    8000210e:	17048493          	addi	s1,s1,368
    80002112:	01348b63          	beq	s1,s3,80002128 <reparent+0x46>
    if(pp->parent == p){
    80002116:	7c9c                	ld	a5,56(s1)
    80002118:	ff279be3          	bne	a5,s2,8000210e <reparent+0x2c>
      pp->parent = initproc;
    8000211c:	000a3503          	ld	a0,0(s4)
    80002120:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002122:	f57ff0ef          	jal	ra,80002078 <wakeup>
    80002126:	b7e5                	j	8000210e <reparent+0x2c>
}
    80002128:	70a2                	ld	ra,40(sp)
    8000212a:	7402                	ld	s0,32(sp)
    8000212c:	64e2                	ld	s1,24(sp)
    8000212e:	6942                	ld	s2,16(sp)
    80002130:	69a2                	ld	s3,8(sp)
    80002132:	6a02                	ld	s4,0(sp)
    80002134:	6145                	addi	sp,sp,48
    80002136:	8082                	ret

0000000080002138 <kexit>:
{
    80002138:	7179                	addi	sp,sp,-48
    8000213a:	f406                	sd	ra,40(sp)
    8000213c:	f022                	sd	s0,32(sp)
    8000213e:	ec26                	sd	s1,24(sp)
    80002140:	e84a                	sd	s2,16(sp)
    80002142:	e44e                	sd	s3,8(sp)
    80002144:	e052                	sd	s4,0(sp)
    80002146:	1800                	addi	s0,sp,48
    80002148:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000214a:	8d1ff0ef          	jal	ra,80001a1a <myproc>
    8000214e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002150:	00006797          	auipc	a5,0x6
    80002154:	8c07b783          	ld	a5,-1856(a5) # 80007a10 <initproc>
    80002158:	0d050493          	addi	s1,a0,208
    8000215c:	15050913          	addi	s2,a0,336
    80002160:	00a79f63          	bne	a5,a0,8000217e <kexit+0x46>
    panic("init exiting");
    80002164:	00005517          	auipc	a0,0x5
    80002168:	16450513          	addi	a0,a0,356 # 800072c8 <digits+0x290>
    8000216c:	e1efe0ef          	jal	ra,8000078a <panic>
      fileclose(f);
    80002170:	14a020ef          	jal	ra,800042ba <fileclose>
      p->ofile[fd] = 0;
    80002174:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002178:	04a1                	addi	s1,s1,8
    8000217a:	01248563          	beq	s1,s2,80002184 <kexit+0x4c>
    if(p->ofile[fd]){
    8000217e:	6088                	ld	a0,0(s1)
    80002180:	f965                	bnez	a0,80002170 <kexit+0x38>
    80002182:	bfdd                	j	80002178 <kexit+0x40>
  begin_op();
    80002184:	529010ef          	jal	ra,80003eac <begin_op>
  iput(p->cwd);
    80002188:	1509b503          	ld	a0,336(s3)
    8000218c:	4c0010ef          	jal	ra,8000364c <iput>
  end_op();
    80002190:	58d010ef          	jal	ra,80003f1c <end_op>
  p->cwd = 0;
    80002194:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002198:	00016497          	auipc	s1,0x16
    8000219c:	97048493          	addi	s1,s1,-1680 # 80017b08 <wait_lock>
    800021a0:	8526                	mv	a0,s1
    800021a2:	b4dfe0ef          	jal	ra,80000cee <acquire>
  reparent(p);
    800021a6:	854e                	mv	a0,s3
    800021a8:	f3bff0ef          	jal	ra,800020e2 <reparent>
  wakeup(p->parent);
    800021ac:	0389b503          	ld	a0,56(s3)
    800021b0:	ec9ff0ef          	jal	ra,80002078 <wakeup>
  acquire(&p->lock);
    800021b4:	854e                	mv	a0,s3
    800021b6:	b39fe0ef          	jal	ra,80000cee <acquire>
  p->xstate = status;
    800021ba:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800021be:	4795                	li	a5,5
    800021c0:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800021c4:	8526                	mv	a0,s1
    800021c6:	bc1fe0ef          	jal	ra,80000d86 <release>
  sched();
    800021ca:	d7dff0ef          	jal	ra,80001f46 <sched>
  panic("zombie exit");
    800021ce:	00005517          	auipc	a0,0x5
    800021d2:	10a50513          	addi	a0,a0,266 # 800072d8 <digits+0x2a0>
    800021d6:	db4fe0ef          	jal	ra,8000078a <panic>

00000000800021da <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    800021da:	7179                	addi	sp,sp,-48
    800021dc:	f406                	sd	ra,40(sp)
    800021de:	f022                	sd	s0,32(sp)
    800021e0:	ec26                	sd	s1,24(sp)
    800021e2:	e84a                	sd	s2,16(sp)
    800021e4:	e44e                	sd	s3,8(sp)
    800021e6:	1800                	addi	s0,sp,48
    800021e8:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800021ea:	00016497          	auipc	s1,0x16
    800021ee:	d3648493          	addi	s1,s1,-714 # 80017f20 <proc>
    800021f2:	0001c997          	auipc	s3,0x1c
    800021f6:	92e98993          	addi	s3,s3,-1746 # 8001db20 <tickslock>
    acquire(&p->lock);
    800021fa:	8526                	mv	a0,s1
    800021fc:	af3fe0ef          	jal	ra,80000cee <acquire>
    if(p->pid == pid){
    80002200:	589c                	lw	a5,48(s1)
    80002202:	01278b63          	beq	a5,s2,80002218 <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002206:	8526                	mv	a0,s1
    80002208:	b7ffe0ef          	jal	ra,80000d86 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000220c:	17048493          	addi	s1,s1,368
    80002210:	ff3495e3          	bne	s1,s3,800021fa <kkill+0x20>
  }
  return -1;
    80002214:	557d                	li	a0,-1
    80002216:	a819                	j	8000222c <kkill+0x52>
      p->killed = 1;
    80002218:	4785                	li	a5,1
    8000221a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000221c:	4c98                	lw	a4,24(s1)
    8000221e:	4789                	li	a5,2
    80002220:	00f70d63          	beq	a4,a5,8000223a <kkill+0x60>
      release(&p->lock);
    80002224:	8526                	mv	a0,s1
    80002226:	b61fe0ef          	jal	ra,80000d86 <release>
      return 0;
    8000222a:	4501                	li	a0,0
}
    8000222c:	70a2                	ld	ra,40(sp)
    8000222e:	7402                	ld	s0,32(sp)
    80002230:	64e2                	ld	s1,24(sp)
    80002232:	6942                	ld	s2,16(sp)
    80002234:	69a2                	ld	s3,8(sp)
    80002236:	6145                	addi	sp,sp,48
    80002238:	8082                	ret
        p->state = RUNNABLE;
    8000223a:	478d                	li	a5,3
    8000223c:	cc9c                	sw	a5,24(s1)
    8000223e:	b7dd                	j	80002224 <kkill+0x4a>

0000000080002240 <setkilled>:

void
setkilled(struct proc *p)
{
    80002240:	1101                	addi	sp,sp,-32
    80002242:	ec06                	sd	ra,24(sp)
    80002244:	e822                	sd	s0,16(sp)
    80002246:	e426                	sd	s1,8(sp)
    80002248:	1000                	addi	s0,sp,32
    8000224a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000224c:	aa3fe0ef          	jal	ra,80000cee <acquire>
  p->killed = 1;
    80002250:	4785                	li	a5,1
    80002252:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002254:	8526                	mv	a0,s1
    80002256:	b31fe0ef          	jal	ra,80000d86 <release>
}
    8000225a:	60e2                	ld	ra,24(sp)
    8000225c:	6442                	ld	s0,16(sp)
    8000225e:	64a2                	ld	s1,8(sp)
    80002260:	6105                	addi	sp,sp,32
    80002262:	8082                	ret

0000000080002264 <killed>:

int
killed(struct proc *p)
{
    80002264:	1101                	addi	sp,sp,-32
    80002266:	ec06                	sd	ra,24(sp)
    80002268:	e822                	sd	s0,16(sp)
    8000226a:	e426                	sd	s1,8(sp)
    8000226c:	e04a                	sd	s2,0(sp)
    8000226e:	1000                	addi	s0,sp,32
    80002270:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002272:	a7dfe0ef          	jal	ra,80000cee <acquire>
  k = p->killed;
    80002276:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000227a:	8526                	mv	a0,s1
    8000227c:	b0bfe0ef          	jal	ra,80000d86 <release>
  return k;
}
    80002280:	854a                	mv	a0,s2
    80002282:	60e2                	ld	ra,24(sp)
    80002284:	6442                	ld	s0,16(sp)
    80002286:	64a2                	ld	s1,8(sp)
    80002288:	6902                	ld	s2,0(sp)
    8000228a:	6105                	addi	sp,sp,32
    8000228c:	8082                	ret

000000008000228e <kwait>:
{
    8000228e:	715d                	addi	sp,sp,-80
    80002290:	e486                	sd	ra,72(sp)
    80002292:	e0a2                	sd	s0,64(sp)
    80002294:	fc26                	sd	s1,56(sp)
    80002296:	f84a                	sd	s2,48(sp)
    80002298:	f44e                	sd	s3,40(sp)
    8000229a:	f052                	sd	s4,32(sp)
    8000229c:	ec56                	sd	s5,24(sp)
    8000229e:	e85a                	sd	s6,16(sp)
    800022a0:	e45e                	sd	s7,8(sp)
    800022a2:	e062                	sd	s8,0(sp)
    800022a4:	0880                	addi	s0,sp,80
    800022a6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022a8:	f72ff0ef          	jal	ra,80001a1a <myproc>
    800022ac:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022ae:	00016517          	auipc	a0,0x16
    800022b2:	85a50513          	addi	a0,a0,-1958 # 80017b08 <wait_lock>
    800022b6:	a39fe0ef          	jal	ra,80000cee <acquire>
    havekids = 0;
    800022ba:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800022bc:	4a15                	li	s4,5
        havekids = 1;
    800022be:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800022c0:	0001c997          	auipc	s3,0x1c
    800022c4:	86098993          	addi	s3,s3,-1952 # 8001db20 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022c8:	00016c17          	auipc	s8,0x16
    800022cc:	840c0c13          	addi	s8,s8,-1984 # 80017b08 <wait_lock>
    havekids = 0;
    800022d0:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800022d2:	00016497          	auipc	s1,0x16
    800022d6:	c4e48493          	addi	s1,s1,-946 # 80017f20 <proc>
    800022da:	a899                	j	80002330 <kwait+0xa2>
          pid = pp->pid;
    800022dc:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800022e0:	000b0c63          	beqz	s6,800022f8 <kwait+0x6a>
    800022e4:	4691                	li	a3,4
    800022e6:	02c48613          	addi	a2,s1,44
    800022ea:	85da                	mv	a1,s6
    800022ec:	05093503          	ld	a0,80(s2)
    800022f0:	c0cff0ef          	jal	ra,800016fc <copyout>
    800022f4:	00054f63          	bltz	a0,80002312 <kwait+0x84>
          freeproc(pp);
    800022f8:	8526                	mv	a0,s1
    800022fa:	8f1ff0ef          	jal	ra,80001bea <freeproc>
          release(&pp->lock);
    800022fe:	8526                	mv	a0,s1
    80002300:	a87fe0ef          	jal	ra,80000d86 <release>
          release(&wait_lock);
    80002304:	00016517          	auipc	a0,0x16
    80002308:	80450513          	addi	a0,a0,-2044 # 80017b08 <wait_lock>
    8000230c:	a7bfe0ef          	jal	ra,80000d86 <release>
          return pid;
    80002310:	a891                	j	80002364 <kwait+0xd6>
            release(&pp->lock);
    80002312:	8526                	mv	a0,s1
    80002314:	a73fe0ef          	jal	ra,80000d86 <release>
            release(&wait_lock);
    80002318:	00015517          	auipc	a0,0x15
    8000231c:	7f050513          	addi	a0,a0,2032 # 80017b08 <wait_lock>
    80002320:	a67fe0ef          	jal	ra,80000d86 <release>
            return -1;
    80002324:	59fd                	li	s3,-1
    80002326:	a83d                	j	80002364 <kwait+0xd6>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002328:	17048493          	addi	s1,s1,368
    8000232c:	03348063          	beq	s1,s3,8000234c <kwait+0xbe>
      if(pp->parent == p){
    80002330:	7c9c                	ld	a5,56(s1)
    80002332:	ff279be3          	bne	a5,s2,80002328 <kwait+0x9a>
        acquire(&pp->lock);
    80002336:	8526                	mv	a0,s1
    80002338:	9b7fe0ef          	jal	ra,80000cee <acquire>
        if(pp->state == ZOMBIE){
    8000233c:	4c9c                	lw	a5,24(s1)
    8000233e:	f9478fe3          	beq	a5,s4,800022dc <kwait+0x4e>
        release(&pp->lock);
    80002342:	8526                	mv	a0,s1
    80002344:	a43fe0ef          	jal	ra,80000d86 <release>
        havekids = 1;
    80002348:	8756                	mv	a4,s5
    8000234a:	bff9                	j	80002328 <kwait+0x9a>
    if(!havekids || killed(p)){
    8000234c:	c709                	beqz	a4,80002356 <kwait+0xc8>
    8000234e:	854a                	mv	a0,s2
    80002350:	f15ff0ef          	jal	ra,80002264 <killed>
    80002354:	c50d                	beqz	a0,8000237e <kwait+0xf0>
      release(&wait_lock);
    80002356:	00015517          	auipc	a0,0x15
    8000235a:	7b250513          	addi	a0,a0,1970 # 80017b08 <wait_lock>
    8000235e:	a29fe0ef          	jal	ra,80000d86 <release>
      return -1;
    80002362:	59fd                	li	s3,-1
}
    80002364:	854e                	mv	a0,s3
    80002366:	60a6                	ld	ra,72(sp)
    80002368:	6406                	ld	s0,64(sp)
    8000236a:	74e2                	ld	s1,56(sp)
    8000236c:	7942                	ld	s2,48(sp)
    8000236e:	79a2                	ld	s3,40(sp)
    80002370:	7a02                	ld	s4,32(sp)
    80002372:	6ae2                	ld	s5,24(sp)
    80002374:	6b42                	ld	s6,16(sp)
    80002376:	6ba2                	ld	s7,8(sp)
    80002378:	6c02                	ld	s8,0(sp)
    8000237a:	6161                	addi	sp,sp,80
    8000237c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000237e:	85e2                	mv	a1,s8
    80002380:	854a                	mv	a0,s2
    80002382:	cabff0ef          	jal	ra,8000202c <sleep>
    havekids = 0;
    80002386:	b7a9                	j	800022d0 <kwait+0x42>

0000000080002388 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002388:	7179                	addi	sp,sp,-48
    8000238a:	f406                	sd	ra,40(sp)
    8000238c:	f022                	sd	s0,32(sp)
    8000238e:	ec26                	sd	s1,24(sp)
    80002390:	e84a                	sd	s2,16(sp)
    80002392:	e44e                	sd	s3,8(sp)
    80002394:	e052                	sd	s4,0(sp)
    80002396:	1800                	addi	s0,sp,48
    80002398:	84aa                	mv	s1,a0
    8000239a:	892e                	mv	s2,a1
    8000239c:	89b2                	mv	s3,a2
    8000239e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800023a0:	e7aff0ef          	jal	ra,80001a1a <myproc>
  if(user_dst){
    800023a4:	cc99                	beqz	s1,800023c2 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    800023a6:	86d2                	mv	a3,s4
    800023a8:	864e                	mv	a2,s3
    800023aa:	85ca                	mv	a1,s2
    800023ac:	6928                	ld	a0,80(a0)
    800023ae:	b4eff0ef          	jal	ra,800016fc <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800023b2:	70a2                	ld	ra,40(sp)
    800023b4:	7402                	ld	s0,32(sp)
    800023b6:	64e2                	ld	s1,24(sp)
    800023b8:	6942                	ld	s2,16(sp)
    800023ba:	69a2                	ld	s3,8(sp)
    800023bc:	6a02                	ld	s4,0(sp)
    800023be:	6145                	addi	sp,sp,48
    800023c0:	8082                	ret
    memmove((char *)dst, src, len);
    800023c2:	000a061b          	sext.w	a2,s4
    800023c6:	85ce                	mv	a1,s3
    800023c8:	854a                	mv	a0,s2
    800023ca:	a55fe0ef          	jal	ra,80000e1e <memmove>
    return 0;
    800023ce:	8526                	mv	a0,s1
    800023d0:	b7cd                	j	800023b2 <either_copyout+0x2a>

00000000800023d2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800023d2:	7179                	addi	sp,sp,-48
    800023d4:	f406                	sd	ra,40(sp)
    800023d6:	f022                	sd	s0,32(sp)
    800023d8:	ec26                	sd	s1,24(sp)
    800023da:	e84a                	sd	s2,16(sp)
    800023dc:	e44e                	sd	s3,8(sp)
    800023de:	e052                	sd	s4,0(sp)
    800023e0:	1800                	addi	s0,sp,48
    800023e2:	892a                	mv	s2,a0
    800023e4:	84ae                	mv	s1,a1
    800023e6:	89b2                	mv	s3,a2
    800023e8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800023ea:	e30ff0ef          	jal	ra,80001a1a <myproc>
  if(user_src){
    800023ee:	cc99                	beqz	s1,8000240c <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    800023f0:	86d2                	mv	a3,s4
    800023f2:	864e                	mv	a2,s3
    800023f4:	85ca                	mv	a1,s2
    800023f6:	6928                	ld	a0,80(a0)
    800023f8:	c36ff0ef          	jal	ra,8000182e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800023fc:	70a2                	ld	ra,40(sp)
    800023fe:	7402                	ld	s0,32(sp)
    80002400:	64e2                	ld	s1,24(sp)
    80002402:	6942                	ld	s2,16(sp)
    80002404:	69a2                	ld	s3,8(sp)
    80002406:	6a02                	ld	s4,0(sp)
    80002408:	6145                	addi	sp,sp,48
    8000240a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000240c:	000a061b          	sext.w	a2,s4
    80002410:	85ce                	mv	a1,s3
    80002412:	854a                	mv	a0,s2
    80002414:	a0bfe0ef          	jal	ra,80000e1e <memmove>
    return 0;
    80002418:	8526                	mv	a0,s1
    8000241a:	b7cd                	j	800023fc <either_copyin+0x2a>

000000008000241c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000241c:	715d                	addi	sp,sp,-80
    8000241e:	e486                	sd	ra,72(sp)
    80002420:	e0a2                	sd	s0,64(sp)
    80002422:	fc26                	sd	s1,56(sp)
    80002424:	f84a                	sd	s2,48(sp)
    80002426:	f44e                	sd	s3,40(sp)
    80002428:	f052                	sd	s4,32(sp)
    8000242a:	ec56                	sd	s5,24(sp)
    8000242c:	e85a                	sd	s6,16(sp)
    8000242e:	e45e                	sd	s7,8(sp)
    80002430:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002432:	00005517          	auipc	a0,0x5
    80002436:	03e50513          	addi	a0,a0,62 # 80007470 <states.0+0x140>
    8000243a:	88afe0ef          	jal	ra,800004c4 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000243e:	00016497          	auipc	s1,0x16
    80002442:	c3a48493          	addi	s1,s1,-966 # 80018078 <proc+0x158>
    80002446:	0001c917          	auipc	s2,0x1c
    8000244a:	83290913          	addi	s2,s2,-1998 # 8001dc78 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000244e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002450:	00005997          	auipc	s3,0x5
    80002454:	e9898993          	addi	s3,s3,-360 # 800072e8 <digits+0x2b0>
    printf("%d %s %s", p->pid, state, p->name);
    80002458:	00005a97          	auipc	s5,0x5
    8000245c:	e98a8a93          	addi	s5,s5,-360 # 800072f0 <digits+0x2b8>
    printf("\n");
    80002460:	00005a17          	auipc	s4,0x5
    80002464:	010a0a13          	addi	s4,s4,16 # 80007470 <states.0+0x140>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002468:	00005b97          	auipc	s7,0x5
    8000246c:	ec8b8b93          	addi	s7,s7,-312 # 80007330 <states.0>
    80002470:	a829                	j	8000248a <procdump+0x6e>
    printf("%d %s %s", p->pid, state, p->name);
    80002472:	ed86a583          	lw	a1,-296(a3)
    80002476:	8556                	mv	a0,s5
    80002478:	84cfe0ef          	jal	ra,800004c4 <printf>
    printf("\n");
    8000247c:	8552                	mv	a0,s4
    8000247e:	846fe0ef          	jal	ra,800004c4 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002482:	17048493          	addi	s1,s1,368
    80002486:	03248163          	beq	s1,s2,800024a8 <procdump+0x8c>
    if(p->state == UNUSED)
    8000248a:	86a6                	mv	a3,s1
    8000248c:	ec04a783          	lw	a5,-320(s1)
    80002490:	dbed                	beqz	a5,80002482 <procdump+0x66>
      state = "???";
    80002492:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002494:	fcfb6fe3          	bltu	s6,a5,80002472 <procdump+0x56>
    80002498:	1782                	slli	a5,a5,0x20
    8000249a:	9381                	srli	a5,a5,0x20
    8000249c:	078e                	slli	a5,a5,0x3
    8000249e:	97de                	add	a5,a5,s7
    800024a0:	6390                	ld	a2,0(a5)
    800024a2:	fa61                	bnez	a2,80002472 <procdump+0x56>
      state = "???";
    800024a4:	864e                	mv	a2,s3
    800024a6:	b7f1                	j	80002472 <procdump+0x56>
  }
}
    800024a8:	60a6                	ld	ra,72(sp)
    800024aa:	6406                	ld	s0,64(sp)
    800024ac:	74e2                	ld	s1,56(sp)
    800024ae:	7942                	ld	s2,48(sp)
    800024b0:	79a2                	ld	s3,40(sp)
    800024b2:	7a02                	ld	s4,32(sp)
    800024b4:	6ae2                	ld	s5,24(sp)
    800024b6:	6b42                	ld	s6,16(sp)
    800024b8:	6ba2                	ld	s7,8(sp)
    800024ba:	6161                	addi	sp,sp,80
    800024bc:	8082                	ret

00000000800024be <sys_dump_proc>:

int
sys_dump_proc(void)
{
    800024be:	711d                	addi	sp,sp,-96
    800024c0:	ec86                	sd	ra,88(sp)
    800024c2:	e8a2                	sd	s0,80(sp)
    800024c4:	e4a6                	sd	s1,72(sp)
    800024c6:	e0ca                	sd	s2,64(sp)
    800024c8:	fc4e                	sd	s3,56(sp)
    800024ca:	1080                	addi	s0,sp,96
    uint64 addr;
    // 获取用户传入的指针地址（第0个参数）
    argaddr(0, &addr);  // 注意：argaddr 是 void，不返回错误
    800024cc:	fc840593          	addi	a1,s0,-56
    800024d0:	4501                	li	a0,0
    800024d2:	630000ef          	jal	ra,80002b02 <argaddr>

    if (addr == 0)
    800024d6:	fc843783          	ld	a5,-56(s0)
    800024da:	cfad                	beqz	a5,80002554 <sys_dump_proc+0x96>
    800024dc:	00016497          	auipc	s1,0x16
    800024e0:	a4448493          	addi	s1,s1,-1468 # 80017f20 <proc>
    800024e4:	0001b997          	auipc	s3,0x1b
    800024e8:	63c98993          	addi	s3,s3,1596 # 8001db20 <tickslock>
    800024ec:	4901                	li	s2,0
        return -1;  // 无效地址

    for (int i = 0; i < NPROC; i++) {
        struct proc *p = &proc[i];  // ← 现在在 proc.c 中，proc[] 可见！
        acquire(&p->lock);
    800024ee:	8526                	mv	a0,s1
    800024f0:	ffefe0ef          	jal	ra,80000cee <acquire>
        struct pstat ps;
        ps.inuse = (p->state != UNUSED);
    800024f4:	4c9c                	lw	a5,24(s1)
    800024f6:	00f03733          	snez	a4,a5
    800024fa:	fae42423          	sw	a4,-88(s0)
        ps.pid = p->pid;
    800024fe:	5898                	lw	a4,48(s1)
    80002500:	fae42623          	sw	a4,-84(s0)
        ps.state = p->state;
    80002504:	fcf42023          	sw	a5,-64(s0)
        safestrcpy(ps.name, p->name, sizeof(ps.name));
    80002508:	4641                	li	a2,16
    8000250a:	15848593          	addi	a1,s1,344
    8000250e:	fb040513          	addi	a0,s0,-80
    80002512:	9f7fe0ef          	jal	ra,80000f08 <safestrcpy>
        release(&p->lock);
    80002516:	8526                	mv	a0,s1
    80002518:	86ffe0ef          	jal	ra,80000d86 <release>

        // 安全拷贝到用户空间
        if (copyout(myproc()->pagetable, addr + i * sizeof(ps), (char*)&ps, sizeof(ps)) < 0) {
    8000251c:	cfeff0ef          	jal	ra,80001a1a <myproc>
    80002520:	46f1                	li	a3,28
    80002522:	fa840613          	addi	a2,s0,-88
    80002526:	fc843583          	ld	a1,-56(s0)
    8000252a:	95ca                	add	a1,a1,s2
    8000252c:	6928                	ld	a0,80(a0)
    8000252e:	9ceff0ef          	jal	ra,800016fc <copyout>
    80002532:	00054963          	bltz	a0,80002544 <sys_dump_proc+0x86>
    for (int i = 0; i < NPROC; i++) {
    80002536:	17048493          	addi	s1,s1,368
    8000253a:	0971                	addi	s2,s2,28
    8000253c:	fb3499e3          	bne	s1,s3,800024ee <sys_dump_proc+0x30>
            return -1;
        }
    }
    return 0;
    80002540:	4501                	li	a0,0
    80002542:	a011                	j	80002546 <sys_dump_proc+0x88>
            return -1;
    80002544:	557d                	li	a0,-1
}
    80002546:	60e6                	ld	ra,88(sp)
    80002548:	6446                	ld	s0,80(sp)
    8000254a:	64a6                	ld	s1,72(sp)
    8000254c:	6906                	ld	s2,64(sp)
    8000254e:	79e2                	ld	s3,56(sp)
    80002550:	6125                	addi	sp,sp,96
    80002552:	8082                	ret
        return -1;  // 无效地址
    80002554:	557d                	li	a0,-1
    80002556:	bfc5                	j	80002546 <sys_dump_proc+0x88>

0000000080002558 <swtch>:
# 保存当前寄存器到 old，然后从 new 加载寄存器。

.globl swtch
swtch:
        # 保存当前的寄存器到 old 中
        sd ra, 0(a0)   # 保存返回地址寄存器 ra
    80002558:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)   # 保存栈指针寄存器 sp
    8000255c:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)  # 保存寄存器 s0
    80002560:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)  # 保存寄存器 s1
    80002562:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)  # 保存寄存器 s2
    80002564:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)  # 保存寄存器 s3
    80002568:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)  # 保存寄存器 s4
    8000256c:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)  # 保存寄存器 s5
    80002570:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)  # 保存寄存器 s6
    80002574:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)  # 保存寄存器 s7
    80002578:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)  # 保存寄存器 s8
    8000257c:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)  # 保存寄存器 s9
    80002580:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0) # 保存寄存器 s10
    80002584:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)# 保存寄存器 s11
    80002588:	07b53423          	sd	s11,104(a0)

        # 从 new 加载寄存器
        ld ra, 0(a1)   # 加载返回地址寄存器 ra
    8000258c:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)   # 加载栈指针寄存器 sp
    80002590:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)  # 加载寄存器 s0
    80002594:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)  # 加载寄存器 s1
    80002596:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)  # 加载寄存器 s2
    80002598:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)  # 加载寄存器 s3
    8000259c:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)  # 加载寄存器 s4
    800025a0:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)  # 加载寄存器 s5
    800025a4:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)  # 加载寄存器 s6
    800025a8:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)  # 加载寄存器 s7
    800025ac:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)  # 加载寄存器 s8
    800025b0:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)  # 加载寄存器 s9
    800025b4:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1) # 加载寄存器 s10
    800025b8:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)# 加载寄存器 s11
    800025bc:	0685bd83          	ld	s11,104(a1)

        ret             # 返回，完成上下文切换
    800025c0:	8082                	ret

00000000800025c2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025c2:	1141                	addi	sp,sp,-16
    800025c4:	e406                	sd	ra,8(sp)
    800025c6:	e022                	sd	s0,0(sp)
    800025c8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025ca:	00005597          	auipc	a1,0x5
    800025ce:	d9658593          	addi	a1,a1,-618 # 80007360 <states.0+0x30>
    800025d2:	0001b517          	auipc	a0,0x1b
    800025d6:	54e50513          	addi	a0,a0,1358 # 8001db20 <tickslock>
    800025da:	e94fe0ef          	jal	ra,80000c6e <initlock>
}
    800025de:	60a2                	ld	ra,8(sp)
    800025e0:	6402                	ld	s0,0(sp)
    800025e2:	0141                	addi	sp,sp,16
    800025e4:	8082                	ret

00000000800025e6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800025e6:	1141                	addi	sp,sp,-16
    800025e8:	e422                	sd	s0,8(sp)
    800025ea:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025ec:	00003797          	auipc	a5,0x3
    800025f0:	f9478793          	addi	a5,a5,-108 # 80005580 <kernelvec>
    800025f4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800025f8:	6422                	ld	s0,8(sp)
    800025fa:	0141                	addi	sp,sp,16
    800025fc:	8082                	ret

00000000800025fe <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    800025fe:	1141                	addi	sp,sp,-16
    80002600:	e406                	sd	ra,8(sp)
    80002602:	e022                	sd	s0,0(sp)
    80002604:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002606:	c14ff0ef          	jal	ra,80001a1a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000260a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000260e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002610:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002614:	04000737          	lui	a4,0x4000
    80002618:	00004797          	auipc	a5,0x4
    8000261c:	9e878793          	addi	a5,a5,-1560 # 80006000 <_trampoline>
    80002620:	00004697          	auipc	a3,0x4
    80002624:	9e068693          	addi	a3,a3,-1568 # 80006000 <_trampoline>
    80002628:	8f95                	sub	a5,a5,a3
    8000262a:	177d                	addi	a4,a4,-1
    8000262c:	0732                	slli	a4,a4,0xc
    8000262e:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002630:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002634:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002636:	18002773          	csrr	a4,satp
    8000263a:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000263c:	6d38                	ld	a4,88(a0)
    8000263e:	613c                	ld	a5,64(a0)
    80002640:	6685                	lui	a3,0x1
    80002642:	97b6                	add	a5,a5,a3
    80002644:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002646:	6d3c                	ld	a5,88(a0)
    80002648:	00000717          	auipc	a4,0x0
    8000264c:	0f470713          	addi	a4,a4,244 # 8000273c <usertrap>
    80002650:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002652:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002654:	8712                	mv	a4,tp
    80002656:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002658:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000265c:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002660:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002664:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002668:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000266a:	6f9c                	ld	a5,24(a5)
    8000266c:	14179073          	csrw	sepc,a5
}
    80002670:	60a2                	ld	ra,8(sp)
    80002672:	6402                	ld	s0,0(sp)
    80002674:	0141                	addi	sp,sp,16
    80002676:	8082                	ret

0000000080002678 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002678:	1101                	addi	sp,sp,-32
    8000267a:	ec06                	sd	ra,24(sp)
    8000267c:	e822                	sd	s0,16(sp)
    8000267e:	e426                	sd	s1,8(sp)
    80002680:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    80002682:	b6cff0ef          	jal	ra,800019ee <cpuid>
    80002686:	cd19                	beqz	a0,800026a4 <clockintr+0x2c>
  asm volatile("csrr %0, time" : "=r" (x) );
    80002688:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    8000268c:	000f4737          	lui	a4,0xf4
    80002690:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80002694:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80002696:	14d79073          	csrw	0x14d,a5
}
    8000269a:	60e2                	ld	ra,24(sp)
    8000269c:	6442                	ld	s0,16(sp)
    8000269e:	64a2                	ld	s1,8(sp)
    800026a0:	6105                	addi	sp,sp,32
    800026a2:	8082                	ret
    acquire(&tickslock);
    800026a4:	0001b497          	auipc	s1,0x1b
    800026a8:	47c48493          	addi	s1,s1,1148 # 8001db20 <tickslock>
    800026ac:	8526                	mv	a0,s1
    800026ae:	e40fe0ef          	jal	ra,80000cee <acquire>
    ticks++;
    800026b2:	00005517          	auipc	a0,0x5
    800026b6:	36650513          	addi	a0,a0,870 # 80007a18 <ticks>
    800026ba:	411c                	lw	a5,0(a0)
    800026bc:	2785                	addiw	a5,a5,1
    800026be:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    800026c0:	9b9ff0ef          	jal	ra,80002078 <wakeup>
    release(&tickslock);
    800026c4:	8526                	mv	a0,s1
    800026c6:	ec0fe0ef          	jal	ra,80000d86 <release>
    800026ca:	bf7d                	j	80002688 <clockintr+0x10>

00000000800026cc <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800026cc:	1101                	addi	sp,sp,-32
    800026ce:	ec06                	sd	ra,24(sp)
    800026d0:	e822                	sd	s0,16(sp)
    800026d2:	e426                	sd	s1,8(sp)
    800026d4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026d6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    800026da:	57fd                	li	a5,-1
    800026dc:	17fe                	slli	a5,a5,0x3f
    800026de:	07a5                	addi	a5,a5,9
    800026e0:	00f70d63          	beq	a4,a5,800026fa <devintr+0x2e>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    800026e4:	57fd                	li	a5,-1
    800026e6:	17fe                	slli	a5,a5,0x3f
    800026e8:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    800026ea:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    800026ec:	04f70463          	beq	a4,a5,80002734 <devintr+0x68>
  }
}
    800026f0:	60e2                	ld	ra,24(sp)
    800026f2:	6442                	ld	s0,16(sp)
    800026f4:	64a2                	ld	s1,8(sp)
    800026f6:	6105                	addi	sp,sp,32
    800026f8:	8082                	ret
    int irq = plic_claim();
    800026fa:	72f020ef          	jal	ra,80005628 <plic_claim>
    800026fe:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002700:	47a9                	li	a5,10
    80002702:	02f50363          	beq	a0,a5,80002728 <devintr+0x5c>
    } else if(irq == VIRTIO0_IRQ){
    80002706:	4785                	li	a5,1
    80002708:	02f50363          	beq	a0,a5,8000272e <devintr+0x62>
    return 1;
    8000270c:	4505                	li	a0,1
    } else if(irq){
    8000270e:	d0ed                	beqz	s1,800026f0 <devintr+0x24>
      printf("unexpected interrupt irq=%d\n", irq);
    80002710:	85a6                	mv	a1,s1
    80002712:	00005517          	auipc	a0,0x5
    80002716:	c5650513          	addi	a0,a0,-938 # 80007368 <states.0+0x38>
    8000271a:	dabfd0ef          	jal	ra,800004c4 <printf>
      plic_complete(irq);
    8000271e:	8526                	mv	a0,s1
    80002720:	729020ef          	jal	ra,80005648 <plic_complete>
    return 1;
    80002724:	4505                	li	a0,1
    80002726:	b7e9                	j	800026f0 <devintr+0x24>
      uartintr();
    80002728:	a30fe0ef          	jal	ra,80000958 <uartintr>
    8000272c:	bfcd                	j	8000271e <devintr+0x52>
      virtio_disk_intr();
    8000272e:	38a030ef          	jal	ra,80005ab8 <virtio_disk_intr>
    80002732:	b7f5                	j	8000271e <devintr+0x52>
    clockintr();
    80002734:	f45ff0ef          	jal	ra,80002678 <clockintr>
    return 2;
    80002738:	4509                	li	a0,2
    8000273a:	bf5d                	j	800026f0 <devintr+0x24>

000000008000273c <usertrap>:
{
    8000273c:	7139                	addi	sp,sp,-64
    8000273e:	fc06                	sd	ra,56(sp)
    80002740:	f822                	sd	s0,48(sp)
    80002742:	f426                	sd	s1,40(sp)
    80002744:	f04a                	sd	s2,32(sp)
    80002746:	ec4e                	sd	s3,24(sp)
    80002748:	e852                	sd	s4,16(sp)
    8000274a:	e456                	sd	s5,8(sp)
    8000274c:	e05a                	sd	s6,0(sp)
    8000274e:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002750:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002754:	1007f793          	andi	a5,a5,256
    80002758:	e3c1                	bnez	a5,800027d8 <usertrap+0x9c>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000275a:	00003797          	auipc	a5,0x3
    8000275e:	e2678793          	addi	a5,a5,-474 # 80005580 <kernelvec>
    80002762:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002766:	ab4ff0ef          	jal	ra,80001a1a <myproc>
    8000276a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000276c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000276e:	14102773          	csrr	a4,sepc
    80002772:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002774:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002778:	47a1                	li	a5,8
    8000277a:	06f70563          	beq	a4,a5,800027e4 <usertrap+0xa8>
  } else if((which_dev = devintr()) != 0){
    8000277e:	f4fff0ef          	jal	ra,800026cc <devintr>
    80002782:	892a                	mv	s2,a0
    80002784:	1a051563          	bnez	a0,8000292e <usertrap+0x1f2>
    80002788:	14202773          	csrr	a4,scause
    } else if (r_scause() == 15) {
    8000278c:	47bd                	li	a5,15
    8000278e:	14f71463          	bne	a4,a5,800028d6 <usertrap+0x19a>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002792:	143029f3          	csrr	s3,stval
    uint64 va = PGROUNDDOWN(r_stval());
    80002796:	77fd                	lui	a5,0xfffff
    80002798:	00f9f9b3          	and	s3,s3,a5
    if (va >= MAXVA){
    8000279c:	57fd                	li	a5,-1
    8000279e:	83e9                	srli	a5,a5,0x1a
    800027a0:	0737ea63          	bltu	a5,s3,80002814 <usertrap+0xd8>
    if (va > p->sz){
    800027a4:	64bc                	ld	a5,72(s1)
    800027a6:	0937e063          	bltu	a5,s3,80002826 <usertrap+0xea>
    pte = walk(p->pagetable, va, 0);
    800027aa:	4601                	li	a2,0
    800027ac:	85ce                	mv	a1,s3
    800027ae:	68a8                	ld	a0,80(s1)
    800027b0:	88ffe0ef          	jal	ra,8000103e <walk>
    800027b4:	8a2a                	mv	s4,a0
    if(pte == 0 || ((*pte) & PTE_COW) == 0 || ((*pte) & PTE_V) == 0 || ((*pte) & PTE_U)==0){
    800027b6:	c901                	beqz	a0,800027c6 <usertrap+0x8a>
    800027b8:	611c                	ld	a5,0(a0)
    800027ba:	1117f693          	andi	a3,a5,273
    800027be:	11100713          	li	a4,273
    800027c2:	06e68b63          	beq	a3,a4,80002838 <usertrap+0xfc>
      printf("usertrap: pte not exist or it's not cow page\n");
    800027c6:	00005517          	auipc	a0,0x5
    800027ca:	c1a50513          	addi	a0,a0,-998 # 800073e0 <states.0+0xb0>
    800027ce:	cf7fd0ef          	jal	ra,800004c4 <printf>
      p->killed=1;
    800027d2:	4785                	li	a5,1
    800027d4:	d49c                	sw	a5,40(s1)
      goto end;
    800027d6:	a22d                	j	80002900 <usertrap+0x1c4>
    panic("usertrap: not from user mode");
    800027d8:	00005517          	auipc	a0,0x5
    800027dc:	bb050513          	addi	a0,a0,-1104 # 80007388 <states.0+0x58>
    800027e0:	fabfd0ef          	jal	ra,8000078a <panic>
    if(killed(p))
    800027e4:	a81ff0ef          	jal	ra,80002264 <killed>
    800027e8:	e115                	bnez	a0,8000280c <usertrap+0xd0>
    p->trapframe->epc += 4;
    800027ea:	6cb8                	ld	a4,88(s1)
    800027ec:	6f1c                	ld	a5,24(a4)
    800027ee:	0791                	addi	a5,a5,4
    800027f0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027f2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027f6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027fa:	10079073          	csrw	sstatus,a5
    syscall();
    800027fe:	350000ef          	jal	ra,80002b4e <syscall>
  if(p->killed)
    80002802:	549c                	lw	a5,40(s1)
    80002804:	10078463          	beqz	a5,8000290c <usertrap+0x1d0>
    80002808:	4901                	li	s2,0
    8000280a:	a8dd                	j	80002900 <usertrap+0x1c4>
      kexit(-1);
    8000280c:	557d                	li	a0,-1
    8000280e:	92bff0ef          	jal	ra,80002138 <kexit>
    80002812:	bfe1                	j	800027ea <usertrap+0xae>
      printf("va is larger than MAXVA!\n");
    80002814:	00005517          	auipc	a0,0x5
    80002818:	b9450513          	addi	a0,a0,-1132 # 800073a8 <states.0+0x78>
    8000281c:	ca9fd0ef          	jal	ra,800004c4 <printf>
      p->killed = 1;
    80002820:	4785                	li	a5,1
    80002822:	d49c                	sw	a5,40(s1)
      goto end;
    80002824:	a8f1                	j	80002900 <usertrap+0x1c4>
      printf("va is larger than sz!\n");
    80002826:	00005517          	auipc	a0,0x5
    8000282a:	ba250513          	addi	a0,a0,-1118 # 800073c8 <states.0+0x98>
    8000282e:	c97fd0ef          	jal	ra,800004c4 <printf>
      p->killed = 1;
    80002832:	4785                	li	a5,1
    80002834:	d49c                	sw	a5,40(s1)
      goto end;
    80002836:	a0e9                	j	80002900 <usertrap+0x1c4>
    if(*pte & PTE_COW){
    80002838:	1007f793          	andi	a5,a5,256
    8000283c:	c7c1                	beqz	a5,800028c4 <usertrap+0x188>
      if((mem = kalloc()) == 0)
    8000283e:	bb0fe0ef          	jal	ra,80000bee <kalloc>
    80002842:	8aaa                	mv	s5,a0
    80002844:	c129                	beqz	a0,80002886 <usertrap+0x14a>
      memset(mem, 0, PGSIZE);
    80002846:	6605                	lui	a2,0x1
    80002848:	4581                	li	a1,0
    8000284a:	d78fe0ef          	jal	ra,80000dc2 <memset>
      uint64 pa = walkaddr(p->pagetable, va);
    8000284e:	85ce                	mv	a1,s3
    80002850:	68a8                	ld	a0,80(s1)
    80002852:	887fe0ef          	jal	ra,800010d8 <walkaddr>
    80002856:	8b2a                	mv	s6,a0
      if(pa){
    80002858:	cd21                	beqz	a0,800028b0 <usertrap+0x174>
        memmove(mem, (char*)pa, PGSIZE);
    8000285a:	6605                	lui	a2,0x1
    8000285c:	85aa                	mv	a1,a0
    8000285e:	8556                	mv	a0,s5
    80002860:	dbefe0ef          	jal	ra,80000e1e <memmove>
        int perm = PTE_FLAGS(*pte);
    80002864:	000a3703          	ld	a4,0(s4)
        perm &= ~PTE_COW;
    80002868:	2ff77713          	andi	a4,a4,767
        if(mappages(p->pagetable, va, PGSIZE, (uint64)mem, perm) != 0){
    8000286c:	00476713          	ori	a4,a4,4
    80002870:	86d6                	mv	a3,s5
    80002872:	6605                	lui	a2,0x1
    80002874:	85ce                	mv	a1,s3
    80002876:	68a8                	ld	a0,80(s1)
    80002878:	89ffe0ef          	jal	ra,80001116 <mappages>
    8000287c:	ed11                	bnez	a0,80002898 <usertrap+0x15c>
        kfree((void*) pa);
    8000287e:	855a                	mv	a0,s6
    80002880:	a28fe0ef          	jal	ra,80000aa8 <kfree>
    80002884:	bfbd                	j	80002802 <usertrap+0xc6>
        printf("usertrap(): memery alloc fault\n");
    80002886:	00005517          	auipc	a0,0x5
    8000288a:	b8a50513          	addi	a0,a0,-1142 # 80007410 <states.0+0xe0>
    8000288e:	c37fd0ef          	jal	ra,800004c4 <printf>
        p->killed = 1;
    80002892:	4785                	li	a5,1
    80002894:	d49c                	sw	a5,40(s1)
        goto end;
    80002896:	a0ad                	j	80002900 <usertrap+0x1c4>
          printf("usertrap(): can not map page\n");
    80002898:	00005517          	auipc	a0,0x5
    8000289c:	b9850513          	addi	a0,a0,-1128 # 80007430 <states.0+0x100>
    800028a0:	c25fd0ef          	jal	ra,800004c4 <printf>
          kfree(mem); 
    800028a4:	8556                	mv	a0,s5
    800028a6:	a02fe0ef          	jal	ra,80000aa8 <kfree>
          p->killed = 1;
    800028aa:	4785                	li	a5,1
    800028ac:	d49c                	sw	a5,40(s1)
          goto end;
    800028ae:	a889                	j	80002900 <usertrap+0x1c4>
        printf("usertrap(): can not map va: %lx \n", va);
    800028b0:	85ce                	mv	a1,s3
    800028b2:	00005517          	auipc	a0,0x5
    800028b6:	b9e50513          	addi	a0,a0,-1122 # 80007450 <states.0+0x120>
    800028ba:	c0bfd0ef          	jal	ra,800004c4 <printf>
        p->killed = 1;
    800028be:	4785                	li	a5,1
    800028c0:	d49c                	sw	a5,40(s1)
        goto end;
    800028c2:	a83d                	j	80002900 <usertrap+0x1c4>
      printf("usertrap(): not caused by cow \n");
    800028c4:	00005517          	auipc	a0,0x5
    800028c8:	bb450513          	addi	a0,a0,-1100 # 80007478 <states.0+0x148>
    800028cc:	bf9fd0ef          	jal	ra,800004c4 <printf>
      p->killed = 1;
    800028d0:	4785                	li	a5,1
    800028d2:	d49c                	sw	a5,40(s1)
      goto end;
    800028d4:	a035                	j	80002900 <usertrap+0x1c4>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028d6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %lx pid=%d\n", r_scause(), p->pid);
    800028da:	5890                	lw	a2,48(s1)
    800028dc:	00005517          	auipc	a0,0x5
    800028e0:	bbc50513          	addi	a0,a0,-1092 # 80007498 <states.0+0x168>
    800028e4:	be1fd0ef          	jal	ra,800004c4 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028ec:	14302673          	csrr	a2,stval
    printf("            sepc=%lx stval=%lx\n", r_sepc(), r_stval()); 
    800028f0:	00005517          	auipc	a0,0x5
    800028f4:	bd850513          	addi	a0,a0,-1064 # 800074c8 <states.0+0x198>
    800028f8:	bcdfd0ef          	jal	ra,800004c4 <printf>
    p->killed = 1;
    800028fc:	4785                	li	a5,1
    800028fe:	d49c                	sw	a5,40(s1)
    kexit(-1);
    80002900:	557d                	li	a0,-1
    80002902:	837ff0ef          	jal	ra,80002138 <kexit>
  if(which_dev == 2){
    80002906:	4789                	li	a5,2
    80002908:	02f90663          	beq	s2,a5,80002934 <usertrap+0x1f8>
  prepare_return();
    8000290c:	cf3ff0ef          	jal	ra,800025fe <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80002910:	68a8                	ld	a0,80(s1)
    80002912:	8131                	srli	a0,a0,0xc
    80002914:	57fd                	li	a5,-1
    80002916:	17fe                	slli	a5,a5,0x3f
    80002918:	8d5d                	or	a0,a0,a5
}
    8000291a:	70e2                	ld	ra,56(sp)
    8000291c:	7442                	ld	s0,48(sp)
    8000291e:	74a2                	ld	s1,40(sp)
    80002920:	7902                	ld	s2,32(sp)
    80002922:	69e2                	ld	s3,24(sp)
    80002924:	6a42                	ld	s4,16(sp)
    80002926:	6aa2                	ld	s5,8(sp)
    80002928:	6b02                	ld	s6,0(sp)
    8000292a:	6121                	addi	sp,sp,64
    8000292c:	8082                	ret
  if(p->killed)
    8000292e:	549c                	lw	a5,40(s1)
    80002930:	dbf9                	beqz	a5,80002906 <usertrap+0x1ca>
    80002932:	b7f9                	j	80002900 <usertrap+0x1c4>
    yield();
    80002934:	eccff0ef          	jal	ra,80002000 <yield>
    80002938:	bfd1                	j	8000290c <usertrap+0x1d0>

000000008000293a <kerneltrap>:
{
    8000293a:	7179                	addi	sp,sp,-48
    8000293c:	f406                	sd	ra,40(sp)
    8000293e:	f022                	sd	s0,32(sp)
    80002940:	ec26                	sd	s1,24(sp)
    80002942:	e84a                	sd	s2,16(sp)
    80002944:	e44e                	sd	s3,8(sp)
    80002946:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002948:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000294c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002950:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002954:	1004f793          	andi	a5,s1,256
    80002958:	c795                	beqz	a5,80002984 <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000295a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000295e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002960:	eb85                	bnez	a5,80002990 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    80002962:	d6bff0ef          	jal	ra,800026cc <devintr>
    80002966:	c91d                	beqz	a0,8000299c <kerneltrap+0x62>
  if(which_dev == 2&&myproc()!=0) { // timer interrupt
    80002968:	4789                	li	a5,2
    8000296a:	04f50a63          	beq	a0,a5,800029be <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000296e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002972:	10049073          	csrw	sstatus,s1
}
    80002976:	70a2                	ld	ra,40(sp)
    80002978:	7402                	ld	s0,32(sp)
    8000297a:	64e2                	ld	s1,24(sp)
    8000297c:	6942                	ld	s2,16(sp)
    8000297e:	69a2                	ld	s3,8(sp)
    80002980:	6145                	addi	sp,sp,48
    80002982:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002984:	00005517          	auipc	a0,0x5
    80002988:	b6450513          	addi	a0,a0,-1180 # 800074e8 <states.0+0x1b8>
    8000298c:	dfffd0ef          	jal	ra,8000078a <panic>
    panic("kerneltrap: interrupts enabled");
    80002990:	00005517          	auipc	a0,0x5
    80002994:	b8050513          	addi	a0,a0,-1152 # 80007510 <states.0+0x1e0>
    80002998:	df3fd0ef          	jal	ra,8000078a <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000299c:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029a0:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    800029a4:	85ce                	mv	a1,s3
    800029a6:	00005517          	auipc	a0,0x5
    800029aa:	b8a50513          	addi	a0,a0,-1142 # 80007530 <states.0+0x200>
    800029ae:	b17fd0ef          	jal	ra,800004c4 <printf>
    panic("kerneltrap");
    800029b2:	00005517          	auipc	a0,0x5
    800029b6:	ba650513          	addi	a0,a0,-1114 # 80007558 <states.0+0x228>
    800029ba:	dd1fd0ef          	jal	ra,8000078a <panic>
  if(which_dev == 2&&myproc()!=0) { // timer interrupt
    800029be:	85cff0ef          	jal	ra,80001a1a <myproc>
    800029c2:	d555                	beqz	a0,8000296e <kerneltrap+0x34>
    struct proc *p = myproc();
    800029c4:	856ff0ef          	jal	ra,80001a1a <myproc>
    800029c8:	89aa                	mv	s3,a0
    acquire(&p->lock);
    800029ca:	b24fe0ef          	jal	ra,80000cee <acquire>
    p->ticks++;
    800029ce:	1689a783          	lw	a5,360(s3)
    800029d2:	2785                	addiw	a5,a5,1
    800029d4:	0007871b          	sext.w	a4,a5
    800029d8:	16f9a423          	sw	a5,360(s3)
    if (need_yield) {
    800029dc:	16c9a783          	lw	a5,364(s3)
    800029e0:	00f74a63          	blt	a4,a5,800029f4 <kerneltrap+0xba>
      p->ticks = 0; // 重置时间片计数器
    800029e4:	1609a423          	sw	zero,360(s3)
    release(&p->lock);
    800029e8:	854e                	mv	a0,s3
    800029ea:	b9cfe0ef          	jal	ra,80000d86 <release>
      yield(); // 时间片用完，主动让出 CPU
    800029ee:	e12ff0ef          	jal	ra,80002000 <yield>
    800029f2:	bfb5                	j	8000296e <kerneltrap+0x34>
    release(&p->lock);
    800029f4:	854e                	mv	a0,s3
    800029f6:	b90fe0ef          	jal	ra,80000d86 <release>
    if (need_yield) {
    800029fa:	bf95                	j	8000296e <kerneltrap+0x34>

00000000800029fc <argraw>:
}

// 获取第 n 个系统调用的原始参数（未处理过的原始值）
static uint64
argraw(int n)
{
    800029fc:	1101                	addi	sp,sp,-32
    800029fe:	ec06                	sd	ra,24(sp)
    80002a00:	e822                	sd	s0,16(sp)
    80002a02:	e426                	sd	s1,8(sp)
    80002a04:	1000                	addi	s0,sp,32
    80002a06:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a08:	812ff0ef          	jal	ra,80001a1a <myproc>
  switch (n) {
    80002a0c:	4795                	li	a5,5
    80002a0e:	0497e163          	bltu	a5,s1,80002a50 <argraw+0x54>
    80002a12:	048a                	slli	s1,s1,0x2
    80002a14:	00005717          	auipc	a4,0x5
    80002a18:	b7c70713          	addi	a4,a4,-1156 # 80007590 <states.0+0x260>
    80002a1c:	94ba                	add	s1,s1,a4
    80002a1e:	409c                	lw	a5,0(s1)
    80002a20:	97ba                	add	a5,a5,a4
    80002a22:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a24:	6d3c                	ld	a5,88(a0)
    80002a26:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");  // 如果参数 n 无效，触发 panic
  return -1;
}
    80002a28:	60e2                	ld	ra,24(sp)
    80002a2a:	6442                	ld	s0,16(sp)
    80002a2c:	64a2                	ld	s1,8(sp)
    80002a2e:	6105                	addi	sp,sp,32
    80002a30:	8082                	ret
    return p->trapframe->a1;
    80002a32:	6d3c                	ld	a5,88(a0)
    80002a34:	7fa8                	ld	a0,120(a5)
    80002a36:	bfcd                	j	80002a28 <argraw+0x2c>
    return p->trapframe->a2;
    80002a38:	6d3c                	ld	a5,88(a0)
    80002a3a:	63c8                	ld	a0,128(a5)
    80002a3c:	b7f5                	j	80002a28 <argraw+0x2c>
    return p->trapframe->a3;
    80002a3e:	6d3c                	ld	a5,88(a0)
    80002a40:	67c8                	ld	a0,136(a5)
    80002a42:	b7dd                	j	80002a28 <argraw+0x2c>
    return p->trapframe->a4;
    80002a44:	6d3c                	ld	a5,88(a0)
    80002a46:	6bc8                	ld	a0,144(a5)
    80002a48:	b7c5                	j	80002a28 <argraw+0x2c>
    return p->trapframe->a5;
    80002a4a:	6d3c                	ld	a5,88(a0)
    80002a4c:	6fc8                	ld	a0,152(a5)
    80002a4e:	bfe9                	j	80002a28 <argraw+0x2c>
  panic("argraw");  // 如果参数 n 无效，触发 panic
    80002a50:	00005517          	auipc	a0,0x5
    80002a54:	b1850513          	addi	a0,a0,-1256 # 80007568 <states.0+0x238>
    80002a58:	d33fd0ef          	jal	ra,8000078a <panic>

0000000080002a5c <fetchaddr>:
{
    80002a5c:	1101                	addi	sp,sp,-32
    80002a5e:	ec06                	sd	ra,24(sp)
    80002a60:	e822                	sd	s0,16(sp)
    80002a62:	e426                	sd	s1,8(sp)
    80002a64:	e04a                	sd	s2,0(sp)
    80002a66:	1000                	addi	s0,sp,32
    80002a68:	84aa                	mv	s1,a0
    80002a6a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a6c:	faffe0ef          	jal	ra,80001a1a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // 这两个条件都需要检查，防止溢出
    80002a70:	653c                	ld	a5,72(a0)
    80002a72:	02f4f663          	bgeu	s1,a5,80002a9e <fetchaddr+0x42>
    80002a76:	00848713          	addi	a4,s1,8
    80002a7a:	02e7e463          	bltu	a5,a4,80002aa2 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a7e:	46a1                	li	a3,8
    80002a80:	8626                	mv	a2,s1
    80002a82:	85ca                	mv	a1,s2
    80002a84:	6928                	ld	a0,80(a0)
    80002a86:	da9fe0ef          	jal	ra,8000182e <copyin>
    80002a8a:	00a03533          	snez	a0,a0
    80002a8e:	40a00533          	neg	a0,a0
}
    80002a92:	60e2                	ld	ra,24(sp)
    80002a94:	6442                	ld	s0,16(sp)
    80002a96:	64a2                	ld	s1,8(sp)
    80002a98:	6902                	ld	s2,0(sp)
    80002a9a:	6105                	addi	sp,sp,32
    80002a9c:	8082                	ret
    return -1;
    80002a9e:	557d                	li	a0,-1
    80002aa0:	bfcd                	j	80002a92 <fetchaddr+0x36>
    80002aa2:	557d                	li	a0,-1
    80002aa4:	b7fd                	j	80002a92 <fetchaddr+0x36>

0000000080002aa6 <fetchstr>:
{
    80002aa6:	7179                	addi	sp,sp,-48
    80002aa8:	f406                	sd	ra,40(sp)
    80002aaa:	f022                	sd	s0,32(sp)
    80002aac:	ec26                	sd	s1,24(sp)
    80002aae:	e84a                	sd	s2,16(sp)
    80002ab0:	e44e                	sd	s3,8(sp)
    80002ab2:	1800                	addi	s0,sp,48
    80002ab4:	892a                	mv	s2,a0
    80002ab6:	84ae                	mv	s1,a1
    80002ab8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002aba:	f61fe0ef          	jal	ra,80001a1a <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002abe:	86ce                	mv	a3,s3
    80002ac0:	864a                	mv	a2,s2
    80002ac2:	85a6                	mv	a1,s1
    80002ac4:	6928                	ld	a0,80(a0)
    80002ac6:	af5fe0ef          	jal	ra,800015ba <copyinstr>
    80002aca:	00054c63          	bltz	a0,80002ae2 <fetchstr+0x3c>
  return strlen(buf);  // 返回字符串长度
    80002ace:	8526                	mv	a0,s1
    80002ad0:	c6afe0ef          	jal	ra,80000f3a <strlen>
}
    80002ad4:	70a2                	ld	ra,40(sp)
    80002ad6:	7402                	ld	s0,32(sp)
    80002ad8:	64e2                	ld	s1,24(sp)
    80002ada:	6942                	ld	s2,16(sp)
    80002adc:	69a2                	ld	s3,8(sp)
    80002ade:	6145                	addi	sp,sp,48
    80002ae0:	8082                	ret
    return -1;
    80002ae2:	557d                	li	a0,-1
    80002ae4:	bfc5                	j	80002ad4 <fetchstr+0x2e>

0000000080002ae6 <argint>:

// 获取第 n 个 32 位的系统调用参数并将其存入 ip 中
void
argint(int n, int *ip)
{
    80002ae6:	1101                	addi	sp,sp,-32
    80002ae8:	ec06                	sd	ra,24(sp)
    80002aea:	e822                	sd	s0,16(sp)
    80002aec:	e426                	sd	s1,8(sp)
    80002aee:	1000                	addi	s0,sp,32
    80002af0:	84ae                	mv	s1,a1
  *ip = argraw(n);  // 通过 argraw 获取原始参数并存储
    80002af2:	f0bff0ef          	jal	ra,800029fc <argraw>
    80002af6:	c088                	sw	a0,0(s1)
}
    80002af8:	60e2                	ld	ra,24(sp)
    80002afa:	6442                	ld	s0,16(sp)
    80002afc:	64a2                	ld	s1,8(sp)
    80002afe:	6105                	addi	sp,sp,32
    80002b00:	8082                	ret

0000000080002b02 <argaddr>:

// 获取第 n 个参数并将其作为指针返回。
// 不进行合法性检查，因为 copyin 和 copyout 会处理这些检查。
void
argaddr(int n, uint64 *ip)
{
    80002b02:	1101                	addi	sp,sp,-32
    80002b04:	ec06                	sd	ra,24(sp)
    80002b06:	e822                	sd	s0,16(sp)
    80002b08:	e426                	sd	s1,8(sp)
    80002b0a:	1000                	addi	s0,sp,32
    80002b0c:	84ae                	mv	s1,a1
  *ip = argraw(n);  // 通过 argraw 获取原始参数并存储
    80002b0e:	eefff0ef          	jal	ra,800029fc <argraw>
    80002b12:	e088                	sd	a0,0(s1)
}
    80002b14:	60e2                	ld	ra,24(sp)
    80002b16:	6442                	ld	s0,16(sp)
    80002b18:	64a2                	ld	s1,8(sp)
    80002b1a:	6105                	addi	sp,sp,32
    80002b1c:	8082                	ret

0000000080002b1e <argstr>:
// 获取第 n 个参数，假设它是一个以 null 结尾的字符串。
// 将该字符串拷贝到 buf 中，最多拷贝 max 个字符。
// 成功时返回字符串长度（包括 null），出错时返回 -1。
int
argstr(int n, char *buf, int max)
{
    80002b1e:	7179                	addi	sp,sp,-48
    80002b20:	f406                	sd	ra,40(sp)
    80002b22:	f022                	sd	s0,32(sp)
    80002b24:	ec26                	sd	s1,24(sp)
    80002b26:	e84a                	sd	s2,16(sp)
    80002b28:	1800                	addi	s0,sp,48
    80002b2a:	84ae                	mv	s1,a1
    80002b2c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);  // 获取第 n 个参数的地址
    80002b2e:	fd840593          	addi	a1,s0,-40
    80002b32:	fd1ff0ef          	jal	ra,80002b02 <argaddr>
  return fetchstr(addr, buf, max);  // 使用 fetchstr 获取字符串内容
    80002b36:	864a                	mv	a2,s2
    80002b38:	85a6                	mv	a1,s1
    80002b3a:	fd843503          	ld	a0,-40(s0)
    80002b3e:	f69ff0ef          	jal	ra,80002aa6 <fetchstr>
}
    80002b42:	70a2                	ld	ra,40(sp)
    80002b44:	7402                	ld	s0,32(sp)
    80002b46:	64e2                	ld	s1,24(sp)
    80002b48:	6942                	ld	s2,16(sp)
    80002b4a:	6145                	addi	sp,sp,48
    80002b4c:	8082                	ret

0000000080002b4e <syscall>:
};

// 系统调用的入口函数
void
syscall(void)
{
    80002b4e:	1101                	addi	sp,sp,-32
    80002b50:	ec06                	sd	ra,24(sp)
    80002b52:	e822                	sd	s0,16(sp)
    80002b54:	e426                	sd	s1,8(sp)
    80002b56:	e04a                	sd	s2,0(sp)
    80002b58:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b5a:	ec1fe0ef          	jal	ra,80001a1a <myproc>
    80002b5e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;  // 从 trapframe 中获取系统调用号
    80002b60:	05853903          	ld	s2,88(a0)
    80002b64:	0a893783          	ld	a5,168(s2)
    80002b68:	0007869b          	sext.w	a3,a5
  // 检查系统调用号是否合法，且确保有对应的处理函数
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b6c:	37fd                	addiw	a5,a5,-1
    80002b6e:	4755                	li	a4,21
    80002b70:	00f76f63          	bltu	a4,a5,80002b8e <syscall+0x40>
    80002b74:	00369713          	slli	a4,a3,0x3
    80002b78:	00005797          	auipc	a5,0x5
    80002b7c:	a3078793          	addi	a5,a5,-1488 # 800075a8 <syscalls>
    80002b80:	97ba                	add	a5,a5,a4
    80002b82:	639c                	ld	a5,0(a5)
    80002b84:	c789                	beqz	a5,80002b8e <syscall+0x40>
    // 根据系统调用号查找对应的系统调用函数并调用
    // 系统调用的返回值会存储在 p->trapframe->a0 中
    p->trapframe->a0 = syscalls[num]();
    80002b86:	9782                	jalr	a5
    80002b88:	06a93823          	sd	a0,112(s2)
    80002b8c:	a829                	j	80002ba6 <syscall+0x58>
  } else {
    // 如果找不到有效的系统调用，打印错误信息
    printf("%d %s: unknown sys call %d\n",
    80002b8e:	15848613          	addi	a2,s1,344
    80002b92:	588c                	lw	a1,48(s1)
    80002b94:	00005517          	auipc	a0,0x5
    80002b98:	9dc50513          	addi	a0,a0,-1572 # 80007570 <states.0+0x240>
    80002b9c:	929fd0ef          	jal	ra,800004c4 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;  // 设置返回值为 -1 表示错误
    80002ba0:	6cbc                	ld	a5,88(s1)
    80002ba2:	577d                	li	a4,-1
    80002ba4:	fbb8                	sd	a4,112(a5)
  }
}
    80002ba6:	60e2                	ld	ra,24(sp)
    80002ba8:	6442                	ld	s0,16(sp)
    80002baa:	64a2                	ld	s1,8(sp)
    80002bac:	6902                	ld	s2,0(sp)
    80002bae:	6105                	addi	sp,sp,32
    80002bb0:	8082                	ret

0000000080002bb2 <sys_exit>:
#include "vm.h"

// 进程退出系统调用
uint64
sys_exit(void)
{
    80002bb2:	1101                	addi	sp,sp,-32
    80002bb4:	ec06                	sd	ra,24(sp)
    80002bb6:	e822                	sd	s0,16(sp)
    80002bb8:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);  // 获取退出码
    80002bba:	fec40593          	addi	a1,s0,-20
    80002bbe:	4501                	li	a0,0
    80002bc0:	f27ff0ef          	jal	ra,80002ae6 <argint>
  kexit(n);       // 调用内核的退出函数
    80002bc4:	fec42503          	lw	a0,-20(s0)
    80002bc8:	d70ff0ef          	jal	ra,80002138 <kexit>
  return 0;       // 不会执行到这里
}
    80002bcc:	4501                	li	a0,0
    80002bce:	60e2                	ld	ra,24(sp)
    80002bd0:	6442                	ld	s0,16(sp)
    80002bd2:	6105                	addi	sp,sp,32
    80002bd4:	8082                	ret

0000000080002bd6 <sys_getpid>:

// 获取当前进程的进程ID
uint64
sys_getpid(void)
{
    80002bd6:	1141                	addi	sp,sp,-16
    80002bd8:	e406                	sd	ra,8(sp)
    80002bda:	e022                	sd	s0,0(sp)
    80002bdc:	0800                	addi	s0,sp,16
  return myproc()->pid;  // 返回当前进程的 PID
    80002bde:	e3dfe0ef          	jal	ra,80001a1a <myproc>
}
    80002be2:	5908                	lw	a0,48(a0)
    80002be4:	60a2                	ld	ra,8(sp)
    80002be6:	6402                	ld	s0,0(sp)
    80002be8:	0141                	addi	sp,sp,16
    80002bea:	8082                	ret

0000000080002bec <sys_fork>:

// 创建一个新的子进程
uint64
sys_fork(void)
{
    80002bec:	1141                	addi	sp,sp,-16
    80002bee:	e406                	sd	ra,8(sp)
    80002bf0:	e022                	sd	s0,0(sp)
    80002bf2:	0800                	addi	s0,sp,16
  return kfork();  // 调用内核的 fork 函数
    80002bf4:	994ff0ef          	jal	ra,80001d88 <kfork>
}
    80002bf8:	60a2                	ld	ra,8(sp)
    80002bfa:	6402                	ld	s0,0(sp)
    80002bfc:	0141                	addi	sp,sp,16
    80002bfe:	8082                	ret

0000000080002c00 <sys_wait>:

// 等待子进程退出
uint64
sys_wait(void)
{
    80002c00:	1101                	addi	sp,sp,-32
    80002c02:	ec06                	sd	ra,24(sp)
    80002c04:	e822                	sd	s0,16(sp)
    80002c06:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);  // 获取等待子进程状态的地址
    80002c08:	fe840593          	addi	a1,s0,-24
    80002c0c:	4501                	li	a0,0
    80002c0e:	ef5ff0ef          	jal	ra,80002b02 <argaddr>
  return kwait(p);  // 调用内核的 wait 函数
    80002c12:	fe843503          	ld	a0,-24(s0)
    80002c16:	e78ff0ef          	jal	ra,8000228e <kwait>
}
    80002c1a:	60e2                	ld	ra,24(sp)
    80002c1c:	6442                	ld	s0,16(sp)
    80002c1e:	6105                	addi	sp,sp,32
    80002c20:	8082                	ret

0000000080002c22 <sys_sbrk>:

// 扩展或收缩进程的内存
uint64
sys_sbrk(void)
{
    80002c22:	7179                	addi	sp,sp,-48
    80002c24:	f406                	sd	ra,40(sp)
    80002c26:	f022                	sd	s0,32(sp)
    80002c28:	ec26                	sd	s1,24(sp)
    80002c2a:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);  // 获取内存增量
    80002c2c:	fd840593          	addi	a1,s0,-40
    80002c30:	4501                	li	a0,0
    80002c32:	eb5ff0ef          	jal	ra,80002ae6 <argint>
  argint(1, &t);  // 获取是否懒加载标志
    80002c36:	fdc40593          	addi	a1,s0,-36
    80002c3a:	4505                	li	a0,1
    80002c3c:	eabff0ef          	jal	ra,80002ae6 <argint>
  addr = myproc()->sz;  // 获取当前进程的内存大小
    80002c40:	ddbfe0ef          	jal	ra,80001a1a <myproc>
    80002c44:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {  // 如果是急切分配或要求收缩内存
    80002c46:	fdc42703          	lw	a4,-36(s0)
    80002c4a:	4785                	li	a5,1
    80002c4c:	02f70763          	beq	a4,a5,80002c7a <sys_sbrk+0x58>
    80002c50:	fd842783          	lw	a5,-40(s0)
    80002c54:	0207c363          	bltz	a5,80002c7a <sys_sbrk+0x58>
    if(growproc(n) < 0) {  // 调用内核的 growproc 函数调整内存
      return -1;  // 内存分配失败
    }
  } else {  // 如果是懒加载分配
    if(addr + n < addr)  // 防止内存溢出
    80002c58:	97a6                	add	a5,a5,s1
    80002c5a:	0297ee63          	bltu	a5,s1,80002c96 <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)  // 限制内存的最大值
    80002c5e:	02000737          	lui	a4,0x2000
    80002c62:	177d                	addi	a4,a4,-1
    80002c64:	0736                	slli	a4,a4,0xd
    80002c66:	02f76a63          	bltu	a4,a5,80002c9a <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;  // 调整进程的内存大小
    80002c6a:	db1fe0ef          	jal	ra,80001a1a <myproc>
    80002c6e:	fd842703          	lw	a4,-40(s0)
    80002c72:	653c                	ld	a5,72(a0)
    80002c74:	97ba                	add	a5,a5,a4
    80002c76:	e53c                	sd	a5,72(a0)
    80002c78:	a039                	j	80002c86 <sys_sbrk+0x64>
    if(growproc(n) < 0) {  // 调用内核的 growproc 函数调整内存
    80002c7a:	fd842503          	lw	a0,-40(s0)
    80002c7e:	8a8ff0ef          	jal	ra,80001d26 <growproc>
    80002c82:	00054863          	bltz	a0,80002c92 <sys_sbrk+0x70>
  }
  return addr;  // 返回原内存地址
}
    80002c86:	8526                	mv	a0,s1
    80002c88:	70a2                	ld	ra,40(sp)
    80002c8a:	7402                	ld	s0,32(sp)
    80002c8c:	64e2                	ld	s1,24(sp)
    80002c8e:	6145                	addi	sp,sp,48
    80002c90:	8082                	ret
      return -1;  // 内存分配失败
    80002c92:	54fd                	li	s1,-1
    80002c94:	bfcd                	j	80002c86 <sys_sbrk+0x64>
      return -1;
    80002c96:	54fd                	li	s1,-1
    80002c98:	b7fd                	j	80002c86 <sys_sbrk+0x64>
      return -1;
    80002c9a:	54fd                	li	s1,-1
    80002c9c:	b7ed                	j	80002c86 <sys_sbrk+0x64>

0000000080002c9e <sys_pause>:

// 让当前进程挂起指定时间
uint64
sys_pause(void)
{
    80002c9e:	7139                	addi	sp,sp,-64
    80002ca0:	fc06                	sd	ra,56(sp)
    80002ca2:	f822                	sd	s0,48(sp)
    80002ca4:	f426                	sd	s1,40(sp)
    80002ca6:	f04a                	sd	s2,32(sp)
    80002ca8:	ec4e                	sd	s3,24(sp)
    80002caa:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);  // 获取暂停的时长（以时钟滴答为单位）
    80002cac:	fcc40593          	addi	a1,s0,-52
    80002cb0:	4501                	li	a0,0
    80002cb2:	e35ff0ef          	jal	ra,80002ae6 <argint>
  if(n < 0)  // 如果给定的时长为负，则设置为 0
    80002cb6:	fcc42783          	lw	a5,-52(s0)
    80002cba:	0607c563          	bltz	a5,80002d24 <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);  // 获取时钟锁
    80002cbe:	0001b517          	auipc	a0,0x1b
    80002cc2:	e6250513          	addi	a0,a0,-414 # 8001db20 <tickslock>
    80002cc6:	828fe0ef          	jal	ra,80000cee <acquire>
  ticks0 = ticks;  // 记录当前的时钟滴答数
    80002cca:	00005917          	auipc	s2,0x5
    80002cce:	d4e92903          	lw	s2,-690(s2) # 80007a18 <ticks>
  while(ticks - ticks0 < n){  // 持续等待直到经过了指定的时间
    80002cd2:	fcc42783          	lw	a5,-52(s0)
    80002cd6:	cb8d                	beqz	a5,80002d08 <sys_pause+0x6a>
    if(killed(myproc())){  // 如果进程被杀死，退出等待
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);  // 进程进入休眠状态，等待时钟更新
    80002cd8:	0001b997          	auipc	s3,0x1b
    80002cdc:	e4898993          	addi	s3,s3,-440 # 8001db20 <tickslock>
    80002ce0:	00005497          	auipc	s1,0x5
    80002ce4:	d3848493          	addi	s1,s1,-712 # 80007a18 <ticks>
    if(killed(myproc())){  // 如果进程被杀死，退出等待
    80002ce8:	d33fe0ef          	jal	ra,80001a1a <myproc>
    80002cec:	d78ff0ef          	jal	ra,80002264 <killed>
    80002cf0:	ed0d                	bnez	a0,80002d2a <sys_pause+0x8c>
    sleep(&ticks, &tickslock);  // 进程进入休眠状态，等待时钟更新
    80002cf2:	85ce                	mv	a1,s3
    80002cf4:	8526                	mv	a0,s1
    80002cf6:	b36ff0ef          	jal	ra,8000202c <sleep>
  while(ticks - ticks0 < n){  // 持续等待直到经过了指定的时间
    80002cfa:	409c                	lw	a5,0(s1)
    80002cfc:	412787bb          	subw	a5,a5,s2
    80002d00:	fcc42703          	lw	a4,-52(s0)
    80002d04:	fee7e2e3          	bltu	a5,a4,80002ce8 <sys_pause+0x4a>
  }
  release(&tickslock);  // 释放时钟锁
    80002d08:	0001b517          	auipc	a0,0x1b
    80002d0c:	e1850513          	addi	a0,a0,-488 # 8001db20 <tickslock>
    80002d10:	876fe0ef          	jal	ra,80000d86 <release>
  return 0;  // 返回
    80002d14:	4501                	li	a0,0
}
    80002d16:	70e2                	ld	ra,56(sp)
    80002d18:	7442                	ld	s0,48(sp)
    80002d1a:	74a2                	ld	s1,40(sp)
    80002d1c:	7902                	ld	s2,32(sp)
    80002d1e:	69e2                	ld	s3,24(sp)
    80002d20:	6121                	addi	sp,sp,64
    80002d22:	8082                	ret
    n = 0;
    80002d24:	fc042623          	sw	zero,-52(s0)
    80002d28:	bf59                	j	80002cbe <sys_pause+0x20>
      release(&tickslock);
    80002d2a:	0001b517          	auipc	a0,0x1b
    80002d2e:	df650513          	addi	a0,a0,-522 # 8001db20 <tickslock>
    80002d32:	854fe0ef          	jal	ra,80000d86 <release>
      return -1;
    80002d36:	557d                	li	a0,-1
    80002d38:	bff9                	j	80002d16 <sys_pause+0x78>

0000000080002d3a <sys_kill>:

// 终止指定进程
uint64
sys_kill(void)
{
    80002d3a:	1101                	addi	sp,sp,-32
    80002d3c:	ec06                	sd	ra,24(sp)
    80002d3e:	e822                	sd	s0,16(sp)
    80002d40:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);  // 获取进程 ID
    80002d42:	fec40593          	addi	a1,s0,-20
    80002d46:	4501                	li	a0,0
    80002d48:	d9fff0ef          	jal	ra,80002ae6 <argint>
  return kkill(pid);  // 调用内核的 kill 函数终止进程
    80002d4c:	fec42503          	lw	a0,-20(s0)
    80002d50:	c8aff0ef          	jal	ra,800021da <kkill>
}
    80002d54:	60e2                	ld	ra,24(sp)
    80002d56:	6442                	ld	s0,16(sp)
    80002d58:	6105                	addi	sp,sp,32
    80002d5a:	8082                	ret

0000000080002d5c <sys_uptime>:

// 返回自系统启动以来经过的时钟滴答数
uint64
sys_uptime(void)
{
    80002d5c:	1101                	addi	sp,sp,-32
    80002d5e:	ec06                	sd	ra,24(sp)
    80002d60:	e822                	sd	s0,16(sp)
    80002d62:	e426                	sd	s1,8(sp)
    80002d64:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);  // 获取时钟锁
    80002d66:	0001b517          	auipc	a0,0x1b
    80002d6a:	dba50513          	addi	a0,a0,-582 # 8001db20 <tickslock>
    80002d6e:	f81fd0ef          	jal	ra,80000cee <acquire>
  xticks = ticks;  // 获取当前的时钟滴答数
    80002d72:	00005497          	auipc	s1,0x5
    80002d76:	ca64a483          	lw	s1,-858(s1) # 80007a18 <ticks>
  release(&tickslock);  // 释放时钟锁
    80002d7a:	0001b517          	auipc	a0,0x1b
    80002d7e:	da650513          	addi	a0,a0,-602 # 8001db20 <tickslock>
    80002d82:	804fe0ef          	jal	ra,80000d86 <release>
  return xticks;  // 返回时钟滴答数
}
    80002d86:	02049513          	slli	a0,s1,0x20
    80002d8a:	9101                	srli	a0,a0,0x20
    80002d8c:	60e2                	ld	ra,24(sp)
    80002d8e:	6442                	ld	s0,16(sp)
    80002d90:	64a2                	ld	s1,8(sp)
    80002d92:	6105                	addi	sp,sp,32
    80002d94:	8082                	ret

0000000080002d96 <binit>:
} bcache;

// 初始化缓冲区缓存
void
binit(void)
{
    80002d96:	7179                	addi	sp,sp,-48
    80002d98:	f406                	sd	ra,40(sp)
    80002d9a:	f022                	sd	s0,32(sp)
    80002d9c:	ec26                	sd	s1,24(sp)
    80002d9e:	e84a                	sd	s2,16(sp)
    80002da0:	e44e                	sd	s3,8(sp)
    80002da2:	e052                	sd	s4,0(sp)
    80002da4:	1800                	addi	s0,sp,48
  struct buf *b;

  // 初始化缓冲区缓存的锁
  initlock(&bcache.lock, "bcache");
    80002da6:	00005597          	auipc	a1,0x5
    80002daa:	8ba58593          	addi	a1,a1,-1862 # 80007660 <syscalls+0xb8>
    80002dae:	0001b517          	auipc	a0,0x1b
    80002db2:	d8a50513          	addi	a0,a0,-630 # 8001db38 <bcache>
    80002db6:	eb9fd0ef          	jal	ra,80000c6e <initlock>

  // 创建缓冲区链表
  bcache.head.prev = &bcache.head;
    80002dba:	00023797          	auipc	a5,0x23
    80002dbe:	d7e78793          	addi	a5,a5,-642 # 80025b38 <bcache+0x8000>
    80002dc2:	00023717          	auipc	a4,0x23
    80002dc6:	fde70713          	addi	a4,a4,-34 # 80025da0 <bcache+0x8268>
    80002dca:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002dce:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf + NBUF; b++){
    80002dd2:	0001b497          	auipc	s1,0x1b
    80002dd6:	d7e48493          	addi	s1,s1,-642 # 8001db50 <bcache+0x18>
    b->next = bcache.head.next;
    80002dda:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ddc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");  // 初始化缓冲区的睡眠锁
    80002dde:	00005a17          	auipc	s4,0x5
    80002de2:	88aa0a13          	addi	s4,s4,-1910 # 80007668 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002de6:	2b893783          	ld	a5,696(s2)
    80002dea:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002dec:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");  // 初始化缓冲区的睡眠锁
    80002df0:	85d2                	mv	a1,s4
    80002df2:	01048513          	addi	a0,s1,16
    80002df6:	2fe010ef          	jal	ra,800040f4 <initsleeplock>
    bcache.head.next->prev = b;
    80002dfa:	2b893783          	ld	a5,696(s2)
    80002dfe:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e00:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf + NBUF; b++){
    80002e04:	45848493          	addi	s1,s1,1112
    80002e08:	fd349fe3          	bne	s1,s3,80002de6 <binit+0x50>
  }
}
    80002e0c:	70a2                	ld	ra,40(sp)
    80002e0e:	7402                	ld	s0,32(sp)
    80002e10:	64e2                	ld	s1,24(sp)
    80002e12:	6942                	ld	s2,16(sp)
    80002e14:	69a2                	ld	s3,8(sp)
    80002e16:	6a02                	ld	s4,0(sp)
    80002e18:	6145                	addi	sp,sp,48
    80002e1a:	8082                	ret

0000000080002e1c <bread>:
}

// 获取指定磁盘块的缓冲区并返回，内容从磁盘读取
struct buf*
bread(uint dev, uint blockno)
{
    80002e1c:	7179                	addi	sp,sp,-48
    80002e1e:	f406                	sd	ra,40(sp)
    80002e20:	f022                	sd	s0,32(sp)
    80002e22:	ec26                	sd	s1,24(sp)
    80002e24:	e84a                	sd	s2,16(sp)
    80002e26:	e44e                	sd	s3,8(sp)
    80002e28:	1800                	addi	s0,sp,48
    80002e2a:	892a                	mv	s2,a0
    80002e2c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002e2e:	0001b517          	auipc	a0,0x1b
    80002e32:	d0a50513          	addi	a0,a0,-758 # 8001db38 <bcache>
    80002e36:	eb9fd0ef          	jal	ra,80000cee <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e3a:	00023497          	auipc	s1,0x23
    80002e3e:	fb64b483          	ld	s1,-74(s1) # 80025df0 <bcache+0x82b8>
    80002e42:	00023797          	auipc	a5,0x23
    80002e46:	f5e78793          	addi	a5,a5,-162 # 80025da0 <bcache+0x8268>
    80002e4a:	02f48b63          	beq	s1,a5,80002e80 <bread+0x64>
    80002e4e:	873e                	mv	a4,a5
    80002e50:	a021                	j	80002e58 <bread+0x3c>
    80002e52:	68a4                	ld	s1,80(s1)
    80002e54:	02e48663          	beq	s1,a4,80002e80 <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002e58:	449c                	lw	a5,8(s1)
    80002e5a:	ff279ce3          	bne	a5,s2,80002e52 <bread+0x36>
    80002e5e:	44dc                	lw	a5,12(s1)
    80002e60:	ff3799e3          	bne	a5,s3,80002e52 <bread+0x36>
      b->refcnt++;  // 增加引用计数
    80002e64:	40bc                	lw	a5,64(s1)
    80002e66:	2785                	addiw	a5,a5,1
    80002e68:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002e6a:	0001b517          	auipc	a0,0x1b
    80002e6e:	cce50513          	addi	a0,a0,-818 # 8001db38 <bcache>
    80002e72:	f15fd0ef          	jal	ra,80000d86 <release>
      acquiresleep(&b->lock);  // 获取缓冲区的睡眠锁
    80002e76:	01048513          	addi	a0,s1,16
    80002e7a:	2b0010ef          	jal	ra,8000412a <acquiresleep>
      return b;  // 返回缓冲区
    80002e7e:	a889                	j	80002ed0 <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e80:	00023497          	auipc	s1,0x23
    80002e84:	f684b483          	ld	s1,-152(s1) # 80025de8 <bcache+0x82b0>
    80002e88:	00023797          	auipc	a5,0x23
    80002e8c:	f1878793          	addi	a5,a5,-232 # 80025da0 <bcache+0x8268>
    80002e90:	00f48863          	beq	s1,a5,80002ea0 <bread+0x84>
    80002e94:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e96:	40bc                	lw	a5,64(s1)
    80002e98:	cb91                	beqz	a5,80002eac <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e9a:	64a4                	ld	s1,72(s1)
    80002e9c:	fee49de3          	bne	s1,a4,80002e96 <bread+0x7a>
  panic("bget: no buffers");  // 如果没有找到可用的缓冲区，发生错误
    80002ea0:	00004517          	auipc	a0,0x4
    80002ea4:	7d050513          	addi	a0,a0,2000 # 80007670 <syscalls+0xc8>
    80002ea8:	8e3fd0ef          	jal	ra,8000078a <panic>
      b->dev = dev;  // 设置设备号
    80002eac:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;  // 设置块号
    80002eb0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;  // 设置为无效
    80002eb4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;  // 引用计数设置为 1
    80002eb8:	4785                	li	a5,1
    80002eba:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002ebc:	0001b517          	auipc	a0,0x1b
    80002ec0:	c7c50513          	addi	a0,a0,-900 # 8001db38 <bcache>
    80002ec4:	ec3fd0ef          	jal	ra,80000d86 <release>
      acquiresleep(&b->lock);  // 获取缓冲区的睡眠锁
    80002ec8:	01048513          	addi	a0,s1,16
    80002ecc:	25e010ef          	jal	ra,8000412a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);  // 获取缓冲区
  if(!b->valid) {
    80002ed0:	409c                	lw	a5,0(s1)
    80002ed2:	cb89                	beqz	a5,80002ee4 <bread+0xc8>
    virtio_disk_rw(b, 0);  // 从磁盘读取数据到缓冲区
    b->valid = 1;  // 设置缓冲区为有效
  }
  return b;  // 返回缓冲区
}
    80002ed4:	8526                	mv	a0,s1
    80002ed6:	70a2                	ld	ra,40(sp)
    80002ed8:	7402                	ld	s0,32(sp)
    80002eda:	64e2                	ld	s1,24(sp)
    80002edc:	6942                	ld	s2,16(sp)
    80002ede:	69a2                	ld	s3,8(sp)
    80002ee0:	6145                	addi	sp,sp,48
    80002ee2:	8082                	ret
    virtio_disk_rw(b, 0);  // 从磁盘读取数据到缓冲区
    80002ee4:	4581                	li	a1,0
    80002ee6:	8526                	mv	a0,s1
    80002ee8:	1b5020ef          	jal	ra,8000589c <virtio_disk_rw>
    b->valid = 1;  // 设置缓冲区为有效
    80002eec:	4785                	li	a5,1
    80002eee:	c09c                	sw	a5,0(s1)
  return b;  // 返回缓冲区
    80002ef0:	b7d5                	j	80002ed4 <bread+0xb8>

0000000080002ef2 <bwrite>:

// 将缓冲区 b 的内容写入磁盘，必须先锁定缓冲区
void
bwrite(struct buf *b)
{
    80002ef2:	1101                	addi	sp,sp,-32
    80002ef4:	ec06                	sd	ra,24(sp)
    80002ef6:	e822                	sd	s0,16(sp)
    80002ef8:	e426                	sd	s1,8(sp)
    80002efa:	1000                	addi	s0,sp,32
    80002efc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002efe:	0541                	addi	a0,a0,16
    80002f00:	2a8010ef          	jal	ra,800041a8 <holdingsleep>
    80002f04:	c911                	beqz	a0,80002f18 <bwrite+0x26>
    panic("bwrite");  // 检查是否持有缓冲区的锁
  virtio_disk_rw(b, 1);  // 将缓冲区内容写入磁盘
    80002f06:	4585                	li	a1,1
    80002f08:	8526                	mv	a0,s1
    80002f0a:	193020ef          	jal	ra,8000589c <virtio_disk_rw>
}
    80002f0e:	60e2                	ld	ra,24(sp)
    80002f10:	6442                	ld	s0,16(sp)
    80002f12:	64a2                	ld	s1,8(sp)
    80002f14:	6105                	addi	sp,sp,32
    80002f16:	8082                	ret
    panic("bwrite");  // 检查是否持有缓冲区的锁
    80002f18:	00004517          	auipc	a0,0x4
    80002f1c:	77050513          	addi	a0,a0,1904 # 80007688 <syscalls+0xe0>
    80002f20:	86bfd0ef          	jal	ra,8000078a <panic>

0000000080002f24 <brelse>:

// 释放锁定的缓冲区，并将其移到最近使用的位置
void
brelse(struct buf *b)
{
    80002f24:	1101                	addi	sp,sp,-32
    80002f26:	ec06                	sd	ra,24(sp)
    80002f28:	e822                	sd	s0,16(sp)
    80002f2a:	e426                	sd	s1,8(sp)
    80002f2c:	e04a                	sd	s2,0(sp)
    80002f2e:	1000                	addi	s0,sp,32
    80002f30:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f32:	01050913          	addi	s2,a0,16
    80002f36:	854a                	mv	a0,s2
    80002f38:	270010ef          	jal	ra,800041a8 <holdingsleep>
    80002f3c:	c13d                	beqz	a0,80002fa2 <brelse+0x7e>
    panic("brelse");  // 检查是否持有缓冲区的锁

  releasesleep(&b->lock);  // 释放缓冲区的睡眠锁
    80002f3e:	854a                	mv	a0,s2
    80002f40:	230010ef          	jal	ra,80004170 <releasesleep>

  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002f44:	0001b517          	auipc	a0,0x1b
    80002f48:	bf450513          	addi	a0,a0,-1036 # 8001db38 <bcache>
    80002f4c:	da3fd0ef          	jal	ra,80000cee <acquire>
  b->refcnt--;  // 减少引用计数
    80002f50:	40bc                	lw	a5,64(s1)
    80002f52:	37fd                	addiw	a5,a5,-1
    80002f54:	0007871b          	sext.w	a4,a5
    80002f58:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f5a:	eb05                	bnez	a4,80002f8a <brelse+0x66>
    // 如果没有其他进程在使用该缓冲区
    // 将缓冲区移到链表头部
    b->next->prev = b->prev;
    80002f5c:	68bc                	ld	a5,80(s1)
    80002f5e:	64b8                	ld	a4,72(s1)
    80002f60:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f62:	64bc                	ld	a5,72(s1)
    80002f64:	68b8                	ld	a4,80(s1)
    80002f66:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f68:	00023797          	auipc	a5,0x23
    80002f6c:	bd078793          	addi	a5,a5,-1072 # 80025b38 <bcache+0x8000>
    80002f70:	2b87b703          	ld	a4,696(a5)
    80002f74:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f76:	00023717          	auipc	a4,0x23
    80002f7a:	e2a70713          	addi	a4,a4,-470 # 80025da0 <bcache+0x8268>
    80002f7e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f80:	2b87b703          	ld	a4,696(a5)
    80002f84:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f86:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002f8a:	0001b517          	auipc	a0,0x1b
    80002f8e:	bae50513          	addi	a0,a0,-1106 # 8001db38 <bcache>
    80002f92:	df5fd0ef          	jal	ra,80000d86 <release>
}
    80002f96:	60e2                	ld	ra,24(sp)
    80002f98:	6442                	ld	s0,16(sp)
    80002f9a:	64a2                	ld	s1,8(sp)
    80002f9c:	6902                	ld	s2,0(sp)
    80002f9e:	6105                	addi	sp,sp,32
    80002fa0:	8082                	ret
    panic("brelse");  // 检查是否持有缓冲区的锁
    80002fa2:	00004517          	auipc	a0,0x4
    80002fa6:	6ee50513          	addi	a0,a0,1774 # 80007690 <syscalls+0xe8>
    80002faa:	fe0fd0ef          	jal	ra,8000078a <panic>

0000000080002fae <bpin>:

// 增加缓冲区 b 的引用计数，用于防止缓冲区被释放
void
bpin(struct buf *b) {
    80002fae:	1101                	addi	sp,sp,-32
    80002fb0:	ec06                	sd	ra,24(sp)
    80002fb2:	e822                	sd	s0,16(sp)
    80002fb4:	e426                	sd	s1,8(sp)
    80002fb6:	1000                	addi	s0,sp,32
    80002fb8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002fba:	0001b517          	auipc	a0,0x1b
    80002fbe:	b7e50513          	addi	a0,a0,-1154 # 8001db38 <bcache>
    80002fc2:	d2dfd0ef          	jal	ra,80000cee <acquire>
  b->refcnt++;  // 增加引用计数
    80002fc6:	40bc                	lw	a5,64(s1)
    80002fc8:	2785                	addiw	a5,a5,1
    80002fca:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002fcc:	0001b517          	auipc	a0,0x1b
    80002fd0:	b6c50513          	addi	a0,a0,-1172 # 8001db38 <bcache>
    80002fd4:	db3fd0ef          	jal	ra,80000d86 <release>
}
    80002fd8:	60e2                	ld	ra,24(sp)
    80002fda:	6442                	ld	s0,16(sp)
    80002fdc:	64a2                	ld	s1,8(sp)
    80002fde:	6105                	addi	sp,sp,32
    80002fe0:	8082                	ret

0000000080002fe2 <bunpin>:

// 减少缓冲区 b 的引用计数，用于缓冲区的释放
void
bunpin(struct buf *b) {
    80002fe2:	1101                	addi	sp,sp,-32
    80002fe4:	ec06                	sd	ra,24(sp)
    80002fe6:	e822                	sd	s0,16(sp)
    80002fe8:	e426                	sd	s1,8(sp)
    80002fea:	1000                	addi	s0,sp,32
    80002fec:	84aa                	mv	s1,a0
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002fee:	0001b517          	auipc	a0,0x1b
    80002ff2:	b4a50513          	addi	a0,a0,-1206 # 8001db38 <bcache>
    80002ff6:	cf9fd0ef          	jal	ra,80000cee <acquire>
  b->refcnt--;  // 减少引用计数
    80002ffa:	40bc                	lw	a5,64(s1)
    80002ffc:	37fd                	addiw	a5,a5,-1
    80002ffe:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80003000:	0001b517          	auipc	a0,0x1b
    80003004:	b3850513          	addi	a0,a0,-1224 # 8001db38 <bcache>
    80003008:	d7ffd0ef          	jal	ra,80000d86 <release>
}
    8000300c:	60e2                	ld	ra,24(sp)
    8000300e:	6442                	ld	s0,16(sp)
    80003010:	64a2                	ld	s1,8(sp)
    80003012:	6105                	addi	sp,sp,32
    80003014:	8082                	ret

0000000080003016 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003016:	1101                	addi	sp,sp,-32
    80003018:	ec06                	sd	ra,24(sp)
    8000301a:	e822                	sd	s0,16(sp)
    8000301c:	e426                	sd	s1,8(sp)
    8000301e:	e04a                	sd	s2,0(sp)
    80003020:	1000                	addi	s0,sp,32
    80003022:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003024:	00d5d59b          	srliw	a1,a1,0xd
    80003028:	00023797          	auipc	a5,0x23
    8000302c:	1ec7a783          	lw	a5,492(a5) # 80026214 <sb+0x1c>
    80003030:	9dbd                	addw	a1,a1,a5
    80003032:	debff0ef          	jal	ra,80002e1c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003036:	0074f713          	andi	a4,s1,7
    8000303a:	4785                	li	a5,1
    8000303c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003040:	14ce                	slli	s1,s1,0x33
    80003042:	90d9                	srli	s1,s1,0x36
    80003044:	00950733          	add	a4,a0,s1
    80003048:	05874703          	lbu	a4,88(a4)
    8000304c:	00e7f6b3          	and	a3,a5,a4
    80003050:	c29d                	beqz	a3,80003076 <bfree+0x60>
    80003052:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003054:	94aa                	add	s1,s1,a0
    80003056:	fff7c793          	not	a5,a5
    8000305a:	8ff9                	and	a5,a5,a4
    8000305c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003060:	7d1000ef          	jal	ra,80004030 <log_write>
  brelse(bp);
    80003064:	854a                	mv	a0,s2
    80003066:	ebfff0ef          	jal	ra,80002f24 <brelse>
}
    8000306a:	60e2                	ld	ra,24(sp)
    8000306c:	6442                	ld	s0,16(sp)
    8000306e:	64a2                	ld	s1,8(sp)
    80003070:	6902                	ld	s2,0(sp)
    80003072:	6105                	addi	sp,sp,32
    80003074:	8082                	ret
    panic("freeing free block");
    80003076:	00004517          	auipc	a0,0x4
    8000307a:	62250513          	addi	a0,a0,1570 # 80007698 <syscalls+0xf0>
    8000307e:	f0cfd0ef          	jal	ra,8000078a <panic>

0000000080003082 <balloc>:
{
    80003082:	711d                	addi	sp,sp,-96
    80003084:	ec86                	sd	ra,88(sp)
    80003086:	e8a2                	sd	s0,80(sp)
    80003088:	e4a6                	sd	s1,72(sp)
    8000308a:	e0ca                	sd	s2,64(sp)
    8000308c:	fc4e                	sd	s3,56(sp)
    8000308e:	f852                	sd	s4,48(sp)
    80003090:	f456                	sd	s5,40(sp)
    80003092:	f05a                	sd	s6,32(sp)
    80003094:	ec5e                	sd	s7,24(sp)
    80003096:	e862                	sd	s8,16(sp)
    80003098:	e466                	sd	s9,8(sp)
    8000309a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000309c:	00023797          	auipc	a5,0x23
    800030a0:	1607a783          	lw	a5,352(a5) # 800261fc <sb+0x4>
    800030a4:	0e078163          	beqz	a5,80003186 <balloc+0x104>
    800030a8:	8baa                	mv	s7,a0
    800030aa:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030ac:	00023b17          	auipc	s6,0x23
    800030b0:	14cb0b13          	addi	s6,s6,332 # 800261f8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030b4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030b6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030b8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030ba:	6c89                	lui	s9,0x2
    800030bc:	a0b5                	j	80003128 <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    800030be:	974a                	add	a4,a4,s2
    800030c0:	8fd5                	or	a5,a5,a3
    800030c2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800030c6:	854a                	mv	a0,s2
    800030c8:	769000ef          	jal	ra,80004030 <log_write>
        brelse(bp);
    800030cc:	854a                	mv	a0,s2
    800030ce:	e57ff0ef          	jal	ra,80002f24 <brelse>
  bp = bread(dev, bno);
    800030d2:	85a6                	mv	a1,s1
    800030d4:	855e                	mv	a0,s7
    800030d6:	d47ff0ef          	jal	ra,80002e1c <bread>
    800030da:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800030dc:	40000613          	li	a2,1024
    800030e0:	4581                	li	a1,0
    800030e2:	05850513          	addi	a0,a0,88
    800030e6:	cddfd0ef          	jal	ra,80000dc2 <memset>
  log_write(bp);
    800030ea:	854a                	mv	a0,s2
    800030ec:	745000ef          	jal	ra,80004030 <log_write>
  brelse(bp);
    800030f0:	854a                	mv	a0,s2
    800030f2:	e33ff0ef          	jal	ra,80002f24 <brelse>
}
    800030f6:	8526                	mv	a0,s1
    800030f8:	60e6                	ld	ra,88(sp)
    800030fa:	6446                	ld	s0,80(sp)
    800030fc:	64a6                	ld	s1,72(sp)
    800030fe:	6906                	ld	s2,64(sp)
    80003100:	79e2                	ld	s3,56(sp)
    80003102:	7a42                	ld	s4,48(sp)
    80003104:	7aa2                	ld	s5,40(sp)
    80003106:	7b02                	ld	s6,32(sp)
    80003108:	6be2                	ld	s7,24(sp)
    8000310a:	6c42                	ld	s8,16(sp)
    8000310c:	6ca2                	ld	s9,8(sp)
    8000310e:	6125                	addi	sp,sp,96
    80003110:	8082                	ret
    brelse(bp);
    80003112:	854a                	mv	a0,s2
    80003114:	e11ff0ef          	jal	ra,80002f24 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003118:	015c87bb          	addw	a5,s9,s5
    8000311c:	00078a9b          	sext.w	s5,a5
    80003120:	004b2703          	lw	a4,4(s6)
    80003124:	06eaf163          	bgeu	s5,a4,80003186 <balloc+0x104>
    bp = bread(dev, BBLOCK(b, sb));
    80003128:	41fad79b          	sraiw	a5,s5,0x1f
    8000312c:	0137d79b          	srliw	a5,a5,0x13
    80003130:	015787bb          	addw	a5,a5,s5
    80003134:	40d7d79b          	sraiw	a5,a5,0xd
    80003138:	01cb2583          	lw	a1,28(s6)
    8000313c:	9dbd                	addw	a1,a1,a5
    8000313e:	855e                	mv	a0,s7
    80003140:	cddff0ef          	jal	ra,80002e1c <bread>
    80003144:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003146:	004b2503          	lw	a0,4(s6)
    8000314a:	000a849b          	sext.w	s1,s5
    8000314e:	8662                	mv	a2,s8
    80003150:	fca4f1e3          	bgeu	s1,a0,80003112 <balloc+0x90>
      m = 1 << (bi % 8);
    80003154:	41f6579b          	sraiw	a5,a2,0x1f
    80003158:	01d7d69b          	srliw	a3,a5,0x1d
    8000315c:	00c6873b          	addw	a4,a3,a2
    80003160:	00777793          	andi	a5,a4,7
    80003164:	9f95                	subw	a5,a5,a3
    80003166:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000316a:	4037571b          	sraiw	a4,a4,0x3
    8000316e:	00e906b3          	add	a3,s2,a4
    80003172:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    80003176:	00d7f5b3          	and	a1,a5,a3
    8000317a:	d1b1                	beqz	a1,800030be <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000317c:	2605                	addiw	a2,a2,1
    8000317e:	2485                	addiw	s1,s1,1
    80003180:	fd4618e3          	bne	a2,s4,80003150 <balloc+0xce>
    80003184:	b779                	j	80003112 <balloc+0x90>
  printf("balloc: out of blocks\n");
    80003186:	00004517          	auipc	a0,0x4
    8000318a:	52a50513          	addi	a0,a0,1322 # 800076b0 <syscalls+0x108>
    8000318e:	b36fd0ef          	jal	ra,800004c4 <printf>
  return 0;
    80003192:	4481                	li	s1,0
    80003194:	b78d                	j	800030f6 <balloc+0x74>

0000000080003196 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003196:	7179                	addi	sp,sp,-48
    80003198:	f406                	sd	ra,40(sp)
    8000319a:	f022                	sd	s0,32(sp)
    8000319c:	ec26                	sd	s1,24(sp)
    8000319e:	e84a                	sd	s2,16(sp)
    800031a0:	e44e                	sd	s3,8(sp)
    800031a2:	e052                	sd	s4,0(sp)
    800031a4:	1800                	addi	s0,sp,48
    800031a6:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800031a8:	47ad                	li	a5,11
    800031aa:	02b7e563          	bltu	a5,a1,800031d4 <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    800031ae:	02059493          	slli	s1,a1,0x20
    800031b2:	9081                	srli	s1,s1,0x20
    800031b4:	048a                	slli	s1,s1,0x2
    800031b6:	94aa                	add	s1,s1,a0
    800031b8:	0504a903          	lw	s2,80(s1)
    800031bc:	06091663          	bnez	s2,80003228 <bmap+0x92>
      addr = balloc(ip->dev);
    800031c0:	4108                	lw	a0,0(a0)
    800031c2:	ec1ff0ef          	jal	ra,80003082 <balloc>
    800031c6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800031ca:	04090f63          	beqz	s2,80003228 <bmap+0x92>
        return 0;
      ip->addrs[bn] = addr;
    800031ce:	0524a823          	sw	s2,80(s1)
    800031d2:	a899                	j	80003228 <bmap+0x92>
    }
    return addr;
  }
  bn -= NDIRECT;
    800031d4:	ff45849b          	addiw	s1,a1,-12
    800031d8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800031dc:	0ff00793          	li	a5,255
    800031e0:	06e7eb63          	bltu	a5,a4,80003256 <bmap+0xc0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800031e4:	08052903          	lw	s2,128(a0)
    800031e8:	00091b63          	bnez	s2,800031fe <bmap+0x68>
      addr = balloc(ip->dev);
    800031ec:	4108                	lw	a0,0(a0)
    800031ee:	e95ff0ef          	jal	ra,80003082 <balloc>
    800031f2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800031f6:	02090963          	beqz	s2,80003228 <bmap+0x92>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800031fa:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800031fe:	85ca                	mv	a1,s2
    80003200:	0009a503          	lw	a0,0(s3)
    80003204:	c19ff0ef          	jal	ra,80002e1c <bread>
    80003208:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000320a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000320e:	02049593          	slli	a1,s1,0x20
    80003212:	9181                	srli	a1,a1,0x20
    80003214:	058a                	slli	a1,a1,0x2
    80003216:	00b784b3          	add	s1,a5,a1
    8000321a:	0004a903          	lw	s2,0(s1)
    8000321e:	00090e63          	beqz	s2,8000323a <bmap+0xa4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003222:	8552                	mv	a0,s4
    80003224:	d01ff0ef          	jal	ra,80002f24 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003228:	854a                	mv	a0,s2
    8000322a:	70a2                	ld	ra,40(sp)
    8000322c:	7402                	ld	s0,32(sp)
    8000322e:	64e2                	ld	s1,24(sp)
    80003230:	6942                	ld	s2,16(sp)
    80003232:	69a2                	ld	s3,8(sp)
    80003234:	6a02                	ld	s4,0(sp)
    80003236:	6145                	addi	sp,sp,48
    80003238:	8082                	ret
      addr = balloc(ip->dev);
    8000323a:	0009a503          	lw	a0,0(s3)
    8000323e:	e45ff0ef          	jal	ra,80003082 <balloc>
    80003242:	0005091b          	sext.w	s2,a0
      if(addr){
    80003246:	fc090ee3          	beqz	s2,80003222 <bmap+0x8c>
        a[bn] = addr;
    8000324a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000324e:	8552                	mv	a0,s4
    80003250:	5e1000ef          	jal	ra,80004030 <log_write>
    80003254:	b7f9                	j	80003222 <bmap+0x8c>
  panic("bmap: out of range");
    80003256:	00004517          	auipc	a0,0x4
    8000325a:	47250513          	addi	a0,a0,1138 # 800076c8 <syscalls+0x120>
    8000325e:	d2cfd0ef          	jal	ra,8000078a <panic>

0000000080003262 <iget>:
{
    80003262:	7179                	addi	sp,sp,-48
    80003264:	f406                	sd	ra,40(sp)
    80003266:	f022                	sd	s0,32(sp)
    80003268:	ec26                	sd	s1,24(sp)
    8000326a:	e84a                	sd	s2,16(sp)
    8000326c:	e44e                	sd	s3,8(sp)
    8000326e:	e052                	sd	s4,0(sp)
    80003270:	1800                	addi	s0,sp,48
    80003272:	89aa                	mv	s3,a0
    80003274:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003276:	00023517          	auipc	a0,0x23
    8000327a:	fa250513          	addi	a0,a0,-94 # 80026218 <itable>
    8000327e:	a71fd0ef          	jal	ra,80000cee <acquire>
  empty = 0;
    80003282:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003284:	00023497          	auipc	s1,0x23
    80003288:	fac48493          	addi	s1,s1,-84 # 80026230 <itable+0x18>
    8000328c:	00025697          	auipc	a3,0x25
    80003290:	a3468693          	addi	a3,a3,-1484 # 80027cc0 <log>
    80003294:	a039                	j	800032a2 <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003296:	02090963          	beqz	s2,800032c8 <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000329a:	08848493          	addi	s1,s1,136
    8000329e:	02d48863          	beq	s1,a3,800032ce <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800032a2:	449c                	lw	a5,8(s1)
    800032a4:	fef059e3          	blez	a5,80003296 <iget+0x34>
    800032a8:	4098                	lw	a4,0(s1)
    800032aa:	ff3716e3          	bne	a4,s3,80003296 <iget+0x34>
    800032ae:	40d8                	lw	a4,4(s1)
    800032b0:	ff4713e3          	bne	a4,s4,80003296 <iget+0x34>
      ip->ref++;
    800032b4:	2785                	addiw	a5,a5,1
    800032b6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800032b8:	00023517          	auipc	a0,0x23
    800032bc:	f6050513          	addi	a0,a0,-160 # 80026218 <itable>
    800032c0:	ac7fd0ef          	jal	ra,80000d86 <release>
      return ip;
    800032c4:	8926                	mv	s2,s1
    800032c6:	a02d                	j	800032f0 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800032c8:	fbe9                	bnez	a5,8000329a <iget+0x38>
    800032ca:	8926                	mv	s2,s1
    800032cc:	b7f9                	j	8000329a <iget+0x38>
  if(empty == 0)
    800032ce:	02090a63          	beqz	s2,80003302 <iget+0xa0>
  ip->dev = dev;
    800032d2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800032d6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800032da:	4785                	li	a5,1
    800032dc:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800032e0:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800032e4:	00023517          	auipc	a0,0x23
    800032e8:	f3450513          	addi	a0,a0,-204 # 80026218 <itable>
    800032ec:	a9bfd0ef          	jal	ra,80000d86 <release>
}
    800032f0:	854a                	mv	a0,s2
    800032f2:	70a2                	ld	ra,40(sp)
    800032f4:	7402                	ld	s0,32(sp)
    800032f6:	64e2                	ld	s1,24(sp)
    800032f8:	6942                	ld	s2,16(sp)
    800032fa:	69a2                	ld	s3,8(sp)
    800032fc:	6a02                	ld	s4,0(sp)
    800032fe:	6145                	addi	sp,sp,48
    80003300:	8082                	ret
    panic("iget: no inodes");
    80003302:	00004517          	auipc	a0,0x4
    80003306:	3de50513          	addi	a0,a0,990 # 800076e0 <syscalls+0x138>
    8000330a:	c80fd0ef          	jal	ra,8000078a <panic>

000000008000330e <iinit>:
{
    8000330e:	7179                	addi	sp,sp,-48
    80003310:	f406                	sd	ra,40(sp)
    80003312:	f022                	sd	s0,32(sp)
    80003314:	ec26                	sd	s1,24(sp)
    80003316:	e84a                	sd	s2,16(sp)
    80003318:	e44e                	sd	s3,8(sp)
    8000331a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000331c:	00004597          	auipc	a1,0x4
    80003320:	3d458593          	addi	a1,a1,980 # 800076f0 <syscalls+0x148>
    80003324:	00023517          	auipc	a0,0x23
    80003328:	ef450513          	addi	a0,a0,-268 # 80026218 <itable>
    8000332c:	943fd0ef          	jal	ra,80000c6e <initlock>
  for(i = 0; i < NINODE; i++) {
    80003330:	00023497          	auipc	s1,0x23
    80003334:	f1048493          	addi	s1,s1,-240 # 80026240 <itable+0x28>
    80003338:	00025997          	auipc	s3,0x25
    8000333c:	99898993          	addi	s3,s3,-1640 # 80027cd0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003340:	00004917          	auipc	s2,0x4
    80003344:	3b890913          	addi	s2,s2,952 # 800076f8 <syscalls+0x150>
    80003348:	85ca                	mv	a1,s2
    8000334a:	8526                	mv	a0,s1
    8000334c:	5a9000ef          	jal	ra,800040f4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003350:	08848493          	addi	s1,s1,136
    80003354:	ff349ae3          	bne	s1,s3,80003348 <iinit+0x3a>
}
    80003358:	70a2                	ld	ra,40(sp)
    8000335a:	7402                	ld	s0,32(sp)
    8000335c:	64e2                	ld	s1,24(sp)
    8000335e:	6942                	ld	s2,16(sp)
    80003360:	69a2                	ld	s3,8(sp)
    80003362:	6145                	addi	sp,sp,48
    80003364:	8082                	ret

0000000080003366 <ialloc>:
{
    80003366:	715d                	addi	sp,sp,-80
    80003368:	e486                	sd	ra,72(sp)
    8000336a:	e0a2                	sd	s0,64(sp)
    8000336c:	fc26                	sd	s1,56(sp)
    8000336e:	f84a                	sd	s2,48(sp)
    80003370:	f44e                	sd	s3,40(sp)
    80003372:	f052                	sd	s4,32(sp)
    80003374:	ec56                	sd	s5,24(sp)
    80003376:	e85a                	sd	s6,16(sp)
    80003378:	e45e                	sd	s7,8(sp)
    8000337a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000337c:	00023717          	auipc	a4,0x23
    80003380:	e8872703          	lw	a4,-376(a4) # 80026204 <sb+0xc>
    80003384:	4785                	li	a5,1
    80003386:	04e7f663          	bgeu	a5,a4,800033d2 <ialloc+0x6c>
    8000338a:	8aaa                	mv	s5,a0
    8000338c:	8bae                	mv	s7,a1
    8000338e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003390:	00023a17          	auipc	s4,0x23
    80003394:	e68a0a13          	addi	s4,s4,-408 # 800261f8 <sb>
    80003398:	00048b1b          	sext.w	s6,s1
    8000339c:	0044d793          	srli	a5,s1,0x4
    800033a0:	018a2583          	lw	a1,24(s4)
    800033a4:	9dbd                	addw	a1,a1,a5
    800033a6:	8556                	mv	a0,s5
    800033a8:	a75ff0ef          	jal	ra,80002e1c <bread>
    800033ac:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800033ae:	05850993          	addi	s3,a0,88
    800033b2:	00f4f793          	andi	a5,s1,15
    800033b6:	079a                	slli	a5,a5,0x6
    800033b8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800033ba:	00099783          	lh	a5,0(s3)
    800033be:	cf85                	beqz	a5,800033f6 <ialloc+0x90>
    brelse(bp);
    800033c0:	b65ff0ef          	jal	ra,80002f24 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800033c4:	0485                	addi	s1,s1,1
    800033c6:	00ca2703          	lw	a4,12(s4)
    800033ca:	0004879b          	sext.w	a5,s1
    800033ce:	fce7e5e3          	bltu	a5,a4,80003398 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800033d2:	00004517          	auipc	a0,0x4
    800033d6:	32e50513          	addi	a0,a0,814 # 80007700 <syscalls+0x158>
    800033da:	8eafd0ef          	jal	ra,800004c4 <printf>
  return 0;
    800033de:	4501                	li	a0,0
}
    800033e0:	60a6                	ld	ra,72(sp)
    800033e2:	6406                	ld	s0,64(sp)
    800033e4:	74e2                	ld	s1,56(sp)
    800033e6:	7942                	ld	s2,48(sp)
    800033e8:	79a2                	ld	s3,40(sp)
    800033ea:	7a02                	ld	s4,32(sp)
    800033ec:	6ae2                	ld	s5,24(sp)
    800033ee:	6b42                	ld	s6,16(sp)
    800033f0:	6ba2                	ld	s7,8(sp)
    800033f2:	6161                	addi	sp,sp,80
    800033f4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800033f6:	04000613          	li	a2,64
    800033fa:	4581                	li	a1,0
    800033fc:	854e                	mv	a0,s3
    800033fe:	9c5fd0ef          	jal	ra,80000dc2 <memset>
      dip->type = type;
    80003402:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003406:	854a                	mv	a0,s2
    80003408:	429000ef          	jal	ra,80004030 <log_write>
      brelse(bp);
    8000340c:	854a                	mv	a0,s2
    8000340e:	b17ff0ef          	jal	ra,80002f24 <brelse>
      return iget(dev, inum);
    80003412:	85da                	mv	a1,s6
    80003414:	8556                	mv	a0,s5
    80003416:	e4dff0ef          	jal	ra,80003262 <iget>
    8000341a:	b7d9                	j	800033e0 <ialloc+0x7a>

000000008000341c <iupdate>:
{
    8000341c:	1101                	addi	sp,sp,-32
    8000341e:	ec06                	sd	ra,24(sp)
    80003420:	e822                	sd	s0,16(sp)
    80003422:	e426                	sd	s1,8(sp)
    80003424:	e04a                	sd	s2,0(sp)
    80003426:	1000                	addi	s0,sp,32
    80003428:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000342a:	415c                	lw	a5,4(a0)
    8000342c:	0047d79b          	srliw	a5,a5,0x4
    80003430:	00023597          	auipc	a1,0x23
    80003434:	de05a583          	lw	a1,-544(a1) # 80026210 <sb+0x18>
    80003438:	9dbd                	addw	a1,a1,a5
    8000343a:	4108                	lw	a0,0(a0)
    8000343c:	9e1ff0ef          	jal	ra,80002e1c <bread>
    80003440:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003442:	05850793          	addi	a5,a0,88
    80003446:	40c8                	lw	a0,4(s1)
    80003448:	893d                	andi	a0,a0,15
    8000344a:	051a                	slli	a0,a0,0x6
    8000344c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000344e:	04449703          	lh	a4,68(s1)
    80003452:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003456:	04649703          	lh	a4,70(s1)
    8000345a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000345e:	04849703          	lh	a4,72(s1)
    80003462:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003466:	04a49703          	lh	a4,74(s1)
    8000346a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000346e:	44f8                	lw	a4,76(s1)
    80003470:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003472:	03400613          	li	a2,52
    80003476:	05048593          	addi	a1,s1,80
    8000347a:	0531                	addi	a0,a0,12
    8000347c:	9a3fd0ef          	jal	ra,80000e1e <memmove>
  log_write(bp);
    80003480:	854a                	mv	a0,s2
    80003482:	3af000ef          	jal	ra,80004030 <log_write>
  brelse(bp);
    80003486:	854a                	mv	a0,s2
    80003488:	a9dff0ef          	jal	ra,80002f24 <brelse>
}
    8000348c:	60e2                	ld	ra,24(sp)
    8000348e:	6442                	ld	s0,16(sp)
    80003490:	64a2                	ld	s1,8(sp)
    80003492:	6902                	ld	s2,0(sp)
    80003494:	6105                	addi	sp,sp,32
    80003496:	8082                	ret

0000000080003498 <idup>:
{
    80003498:	1101                	addi	sp,sp,-32
    8000349a:	ec06                	sd	ra,24(sp)
    8000349c:	e822                	sd	s0,16(sp)
    8000349e:	e426                	sd	s1,8(sp)
    800034a0:	1000                	addi	s0,sp,32
    800034a2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800034a4:	00023517          	auipc	a0,0x23
    800034a8:	d7450513          	addi	a0,a0,-652 # 80026218 <itable>
    800034ac:	843fd0ef          	jal	ra,80000cee <acquire>
  ip->ref++;
    800034b0:	449c                	lw	a5,8(s1)
    800034b2:	2785                	addiw	a5,a5,1
    800034b4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800034b6:	00023517          	auipc	a0,0x23
    800034ba:	d6250513          	addi	a0,a0,-670 # 80026218 <itable>
    800034be:	8c9fd0ef          	jal	ra,80000d86 <release>
}
    800034c2:	8526                	mv	a0,s1
    800034c4:	60e2                	ld	ra,24(sp)
    800034c6:	6442                	ld	s0,16(sp)
    800034c8:	64a2                	ld	s1,8(sp)
    800034ca:	6105                	addi	sp,sp,32
    800034cc:	8082                	ret

00000000800034ce <ilock>:
{
    800034ce:	1101                	addi	sp,sp,-32
    800034d0:	ec06                	sd	ra,24(sp)
    800034d2:	e822                	sd	s0,16(sp)
    800034d4:	e426                	sd	s1,8(sp)
    800034d6:	e04a                	sd	s2,0(sp)
    800034d8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800034da:	c105                	beqz	a0,800034fa <ilock+0x2c>
    800034dc:	84aa                	mv	s1,a0
    800034de:	451c                	lw	a5,8(a0)
    800034e0:	00f05d63          	blez	a5,800034fa <ilock+0x2c>
  acquiresleep(&ip->lock);
    800034e4:	0541                	addi	a0,a0,16
    800034e6:	445000ef          	jal	ra,8000412a <acquiresleep>
  if(ip->valid == 0){
    800034ea:	40bc                	lw	a5,64(s1)
    800034ec:	cf89                	beqz	a5,80003506 <ilock+0x38>
}
    800034ee:	60e2                	ld	ra,24(sp)
    800034f0:	6442                	ld	s0,16(sp)
    800034f2:	64a2                	ld	s1,8(sp)
    800034f4:	6902                	ld	s2,0(sp)
    800034f6:	6105                	addi	sp,sp,32
    800034f8:	8082                	ret
    panic("ilock");
    800034fa:	00004517          	auipc	a0,0x4
    800034fe:	21e50513          	addi	a0,a0,542 # 80007718 <syscalls+0x170>
    80003502:	a88fd0ef          	jal	ra,8000078a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003506:	40dc                	lw	a5,4(s1)
    80003508:	0047d79b          	srliw	a5,a5,0x4
    8000350c:	00023597          	auipc	a1,0x23
    80003510:	d045a583          	lw	a1,-764(a1) # 80026210 <sb+0x18>
    80003514:	9dbd                	addw	a1,a1,a5
    80003516:	4088                	lw	a0,0(s1)
    80003518:	905ff0ef          	jal	ra,80002e1c <bread>
    8000351c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000351e:	05850593          	addi	a1,a0,88
    80003522:	40dc                	lw	a5,4(s1)
    80003524:	8bbd                	andi	a5,a5,15
    80003526:	079a                	slli	a5,a5,0x6
    80003528:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000352a:	00059783          	lh	a5,0(a1)
    8000352e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003532:	00259783          	lh	a5,2(a1)
    80003536:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000353a:	00459783          	lh	a5,4(a1)
    8000353e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003542:	00659783          	lh	a5,6(a1)
    80003546:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000354a:	459c                	lw	a5,8(a1)
    8000354c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000354e:	03400613          	li	a2,52
    80003552:	05b1                	addi	a1,a1,12
    80003554:	05048513          	addi	a0,s1,80
    80003558:	8c7fd0ef          	jal	ra,80000e1e <memmove>
    brelse(bp);
    8000355c:	854a                	mv	a0,s2
    8000355e:	9c7ff0ef          	jal	ra,80002f24 <brelse>
    ip->valid = 1;
    80003562:	4785                	li	a5,1
    80003564:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003566:	04449783          	lh	a5,68(s1)
    8000356a:	f3d1                	bnez	a5,800034ee <ilock+0x20>
      panic("ilock: no type");
    8000356c:	00004517          	auipc	a0,0x4
    80003570:	1b450513          	addi	a0,a0,436 # 80007720 <syscalls+0x178>
    80003574:	a16fd0ef          	jal	ra,8000078a <panic>

0000000080003578 <iunlock>:
{
    80003578:	1101                	addi	sp,sp,-32
    8000357a:	ec06                	sd	ra,24(sp)
    8000357c:	e822                	sd	s0,16(sp)
    8000357e:	e426                	sd	s1,8(sp)
    80003580:	e04a                	sd	s2,0(sp)
    80003582:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003584:	c505                	beqz	a0,800035ac <iunlock+0x34>
    80003586:	84aa                	mv	s1,a0
    80003588:	01050913          	addi	s2,a0,16
    8000358c:	854a                	mv	a0,s2
    8000358e:	41b000ef          	jal	ra,800041a8 <holdingsleep>
    80003592:	cd09                	beqz	a0,800035ac <iunlock+0x34>
    80003594:	449c                	lw	a5,8(s1)
    80003596:	00f05b63          	blez	a5,800035ac <iunlock+0x34>
  releasesleep(&ip->lock);
    8000359a:	854a                	mv	a0,s2
    8000359c:	3d5000ef          	jal	ra,80004170 <releasesleep>
}
    800035a0:	60e2                	ld	ra,24(sp)
    800035a2:	6442                	ld	s0,16(sp)
    800035a4:	64a2                	ld	s1,8(sp)
    800035a6:	6902                	ld	s2,0(sp)
    800035a8:	6105                	addi	sp,sp,32
    800035aa:	8082                	ret
    panic("iunlock");
    800035ac:	00004517          	auipc	a0,0x4
    800035b0:	18450513          	addi	a0,a0,388 # 80007730 <syscalls+0x188>
    800035b4:	9d6fd0ef          	jal	ra,8000078a <panic>

00000000800035b8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800035b8:	7179                	addi	sp,sp,-48
    800035ba:	f406                	sd	ra,40(sp)
    800035bc:	f022                	sd	s0,32(sp)
    800035be:	ec26                	sd	s1,24(sp)
    800035c0:	e84a                	sd	s2,16(sp)
    800035c2:	e44e                	sd	s3,8(sp)
    800035c4:	e052                	sd	s4,0(sp)
    800035c6:	1800                	addi	s0,sp,48
    800035c8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800035ca:	05050493          	addi	s1,a0,80
    800035ce:	08050913          	addi	s2,a0,128
    800035d2:	a021                	j	800035da <itrunc+0x22>
    800035d4:	0491                	addi	s1,s1,4
    800035d6:	01248b63          	beq	s1,s2,800035ec <itrunc+0x34>
    if(ip->addrs[i]){
    800035da:	408c                	lw	a1,0(s1)
    800035dc:	dde5                	beqz	a1,800035d4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800035de:	0009a503          	lw	a0,0(s3)
    800035e2:	a35ff0ef          	jal	ra,80003016 <bfree>
      ip->addrs[i] = 0;
    800035e6:	0004a023          	sw	zero,0(s1)
    800035ea:	b7ed                	j	800035d4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800035ec:	0809a583          	lw	a1,128(s3)
    800035f0:	ed91                	bnez	a1,8000360c <itrunc+0x54>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800035f2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800035f6:	854e                	mv	a0,s3
    800035f8:	e25ff0ef          	jal	ra,8000341c <iupdate>
}
    800035fc:	70a2                	ld	ra,40(sp)
    800035fe:	7402                	ld	s0,32(sp)
    80003600:	64e2                	ld	s1,24(sp)
    80003602:	6942                	ld	s2,16(sp)
    80003604:	69a2                	ld	s3,8(sp)
    80003606:	6a02                	ld	s4,0(sp)
    80003608:	6145                	addi	sp,sp,48
    8000360a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000360c:	0009a503          	lw	a0,0(s3)
    80003610:	80dff0ef          	jal	ra,80002e1c <bread>
    80003614:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003616:	05850493          	addi	s1,a0,88
    8000361a:	45850913          	addi	s2,a0,1112
    8000361e:	a021                	j	80003626 <itrunc+0x6e>
    80003620:	0491                	addi	s1,s1,4
    80003622:	01248963          	beq	s1,s2,80003634 <itrunc+0x7c>
      if(a[j])
    80003626:	408c                	lw	a1,0(s1)
    80003628:	dde5                	beqz	a1,80003620 <itrunc+0x68>
        bfree(ip->dev, a[j]);
    8000362a:	0009a503          	lw	a0,0(s3)
    8000362e:	9e9ff0ef          	jal	ra,80003016 <bfree>
    80003632:	b7fd                	j	80003620 <itrunc+0x68>
    brelse(bp);
    80003634:	8552                	mv	a0,s4
    80003636:	8efff0ef          	jal	ra,80002f24 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000363a:	0809a583          	lw	a1,128(s3)
    8000363e:	0009a503          	lw	a0,0(s3)
    80003642:	9d5ff0ef          	jal	ra,80003016 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003646:	0809a023          	sw	zero,128(s3)
    8000364a:	b765                	j	800035f2 <itrunc+0x3a>

000000008000364c <iput>:
{
    8000364c:	1101                	addi	sp,sp,-32
    8000364e:	ec06                	sd	ra,24(sp)
    80003650:	e822                	sd	s0,16(sp)
    80003652:	e426                	sd	s1,8(sp)
    80003654:	e04a                	sd	s2,0(sp)
    80003656:	1000                	addi	s0,sp,32
    80003658:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000365a:	00023517          	auipc	a0,0x23
    8000365e:	bbe50513          	addi	a0,a0,-1090 # 80026218 <itable>
    80003662:	e8cfd0ef          	jal	ra,80000cee <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003666:	4498                	lw	a4,8(s1)
    80003668:	4785                	li	a5,1
    8000366a:	02f70163          	beq	a4,a5,8000368c <iput+0x40>
  ip->ref--;
    8000366e:	449c                	lw	a5,8(s1)
    80003670:	37fd                	addiw	a5,a5,-1
    80003672:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003674:	00023517          	auipc	a0,0x23
    80003678:	ba450513          	addi	a0,a0,-1116 # 80026218 <itable>
    8000367c:	f0afd0ef          	jal	ra,80000d86 <release>
}
    80003680:	60e2                	ld	ra,24(sp)
    80003682:	6442                	ld	s0,16(sp)
    80003684:	64a2                	ld	s1,8(sp)
    80003686:	6902                	ld	s2,0(sp)
    80003688:	6105                	addi	sp,sp,32
    8000368a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000368c:	40bc                	lw	a5,64(s1)
    8000368e:	d3e5                	beqz	a5,8000366e <iput+0x22>
    80003690:	04a49783          	lh	a5,74(s1)
    80003694:	ffe9                	bnez	a5,8000366e <iput+0x22>
    acquiresleep(&ip->lock);
    80003696:	01048913          	addi	s2,s1,16
    8000369a:	854a                	mv	a0,s2
    8000369c:	28f000ef          	jal	ra,8000412a <acquiresleep>
    release(&itable.lock);
    800036a0:	00023517          	auipc	a0,0x23
    800036a4:	b7850513          	addi	a0,a0,-1160 # 80026218 <itable>
    800036a8:	edefd0ef          	jal	ra,80000d86 <release>
    itrunc(ip);
    800036ac:	8526                	mv	a0,s1
    800036ae:	f0bff0ef          	jal	ra,800035b8 <itrunc>
    ip->type = 0;
    800036b2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800036b6:	8526                	mv	a0,s1
    800036b8:	d65ff0ef          	jal	ra,8000341c <iupdate>
    ip->valid = 0;
    800036bc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800036c0:	854a                	mv	a0,s2
    800036c2:	2af000ef          	jal	ra,80004170 <releasesleep>
    acquire(&itable.lock);
    800036c6:	00023517          	auipc	a0,0x23
    800036ca:	b5250513          	addi	a0,a0,-1198 # 80026218 <itable>
    800036ce:	e20fd0ef          	jal	ra,80000cee <acquire>
    800036d2:	bf71                	j	8000366e <iput+0x22>

00000000800036d4 <iunlockput>:
{
    800036d4:	1101                	addi	sp,sp,-32
    800036d6:	ec06                	sd	ra,24(sp)
    800036d8:	e822                	sd	s0,16(sp)
    800036da:	e426                	sd	s1,8(sp)
    800036dc:	1000                	addi	s0,sp,32
    800036de:	84aa                	mv	s1,a0
  iunlock(ip);
    800036e0:	e99ff0ef          	jal	ra,80003578 <iunlock>
  iput(ip);
    800036e4:	8526                	mv	a0,s1
    800036e6:	f67ff0ef          	jal	ra,8000364c <iput>
}
    800036ea:	60e2                	ld	ra,24(sp)
    800036ec:	6442                	ld	s0,16(sp)
    800036ee:	64a2                	ld	s1,8(sp)
    800036f0:	6105                	addi	sp,sp,32
    800036f2:	8082                	ret

00000000800036f4 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800036f4:	00023717          	auipc	a4,0x23
    800036f8:	b1072703          	lw	a4,-1264(a4) # 80026204 <sb+0xc>
    800036fc:	4785                	li	a5,1
    800036fe:	0ae7ff63          	bgeu	a5,a4,800037bc <ireclaim+0xc8>
{
    80003702:	7139                	addi	sp,sp,-64
    80003704:	fc06                	sd	ra,56(sp)
    80003706:	f822                	sd	s0,48(sp)
    80003708:	f426                	sd	s1,40(sp)
    8000370a:	f04a                	sd	s2,32(sp)
    8000370c:	ec4e                	sd	s3,24(sp)
    8000370e:	e852                	sd	s4,16(sp)
    80003710:	e456                	sd	s5,8(sp)
    80003712:	e05a                	sd	s6,0(sp)
    80003714:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003716:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003718:	00050a1b          	sext.w	s4,a0
    8000371c:	00023a97          	auipc	s5,0x23
    80003720:	adca8a93          	addi	s5,s5,-1316 # 800261f8 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    80003724:	00004b17          	auipc	s6,0x4
    80003728:	014b0b13          	addi	s6,s6,20 # 80007738 <syscalls+0x190>
    8000372c:	a099                	j	80003772 <ireclaim+0x7e>
    8000372e:	85ce                	mv	a1,s3
    80003730:	855a                	mv	a0,s6
    80003732:	d93fc0ef          	jal	ra,800004c4 <printf>
      ip = iget(dev, inum);
    80003736:	85ce                	mv	a1,s3
    80003738:	8552                	mv	a0,s4
    8000373a:	b29ff0ef          	jal	ra,80003262 <iget>
    8000373e:	89aa                	mv	s3,a0
    brelse(bp);
    80003740:	854a                	mv	a0,s2
    80003742:	fe2ff0ef          	jal	ra,80002f24 <brelse>
    if (ip) {
    80003746:	00098f63          	beqz	s3,80003764 <ireclaim+0x70>
      begin_op();
    8000374a:	762000ef          	jal	ra,80003eac <begin_op>
      ilock(ip);
    8000374e:	854e                	mv	a0,s3
    80003750:	d7fff0ef          	jal	ra,800034ce <ilock>
      iunlock(ip);
    80003754:	854e                	mv	a0,s3
    80003756:	e23ff0ef          	jal	ra,80003578 <iunlock>
      iput(ip);
    8000375a:	854e                	mv	a0,s3
    8000375c:	ef1ff0ef          	jal	ra,8000364c <iput>
      end_op();
    80003760:	7bc000ef          	jal	ra,80003f1c <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003764:	0485                	addi	s1,s1,1
    80003766:	00caa703          	lw	a4,12(s5)
    8000376a:	0004879b          	sext.w	a5,s1
    8000376e:	02e7fd63          	bgeu	a5,a4,800037a8 <ireclaim+0xb4>
    80003772:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003776:	0044d793          	srli	a5,s1,0x4
    8000377a:	018aa583          	lw	a1,24(s5)
    8000377e:	9dbd                	addw	a1,a1,a5
    80003780:	8552                	mv	a0,s4
    80003782:	e9aff0ef          	jal	ra,80002e1c <bread>
    80003786:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    80003788:	05850793          	addi	a5,a0,88
    8000378c:	00f9f713          	andi	a4,s3,15
    80003790:	071a                	slli	a4,a4,0x6
    80003792:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    80003794:	00079703          	lh	a4,0(a5)
    80003798:	c701                	beqz	a4,800037a0 <ireclaim+0xac>
    8000379a:	00679783          	lh	a5,6(a5)
    8000379e:	dbc1                	beqz	a5,8000372e <ireclaim+0x3a>
    brelse(bp);
    800037a0:	854a                	mv	a0,s2
    800037a2:	f82ff0ef          	jal	ra,80002f24 <brelse>
    if (ip) {
    800037a6:	bf7d                	j	80003764 <ireclaim+0x70>
}
    800037a8:	70e2                	ld	ra,56(sp)
    800037aa:	7442                	ld	s0,48(sp)
    800037ac:	74a2                	ld	s1,40(sp)
    800037ae:	7902                	ld	s2,32(sp)
    800037b0:	69e2                	ld	s3,24(sp)
    800037b2:	6a42                	ld	s4,16(sp)
    800037b4:	6aa2                	ld	s5,8(sp)
    800037b6:	6b02                	ld	s6,0(sp)
    800037b8:	6121                	addi	sp,sp,64
    800037ba:	8082                	ret
    800037bc:	8082                	ret

00000000800037be <fsinit>:
fsinit(int dev) {
    800037be:	7179                	addi	sp,sp,-48
    800037c0:	f406                	sd	ra,40(sp)
    800037c2:	f022                	sd	s0,32(sp)
    800037c4:	ec26                	sd	s1,24(sp)
    800037c6:	e84a                	sd	s2,16(sp)
    800037c8:	e44e                	sd	s3,8(sp)
    800037ca:	1800                	addi	s0,sp,48
    800037cc:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    800037ce:	4585                	li	a1,1
    800037d0:	e4cff0ef          	jal	ra,80002e1c <bread>
    800037d4:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037d6:	00023997          	auipc	s3,0x23
    800037da:	a2298993          	addi	s3,s3,-1502 # 800261f8 <sb>
    800037de:	02000613          	li	a2,32
    800037e2:	05850593          	addi	a1,a0,88
    800037e6:	854e                	mv	a0,s3
    800037e8:	e36fd0ef          	jal	ra,80000e1e <memmove>
  brelse(bp);
    800037ec:	854a                	mv	a0,s2
    800037ee:	f36ff0ef          	jal	ra,80002f24 <brelse>
  if(sb.magic != FSMAGIC)
    800037f2:	0009a703          	lw	a4,0(s3)
    800037f6:	102037b7          	lui	a5,0x10203
    800037fa:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037fe:	02f71363          	bne	a4,a5,80003824 <fsinit+0x66>
  initlog(dev, &sb);
    80003802:	00023597          	auipc	a1,0x23
    80003806:	9f658593          	addi	a1,a1,-1546 # 800261f8 <sb>
    8000380a:	8526                	mv	a0,s1
    8000380c:	616000ef          	jal	ra,80003e22 <initlog>
  ireclaim(dev);
    80003810:	8526                	mv	a0,s1
    80003812:	ee3ff0ef          	jal	ra,800036f4 <ireclaim>
}
    80003816:	70a2                	ld	ra,40(sp)
    80003818:	7402                	ld	s0,32(sp)
    8000381a:	64e2                	ld	s1,24(sp)
    8000381c:	6942                	ld	s2,16(sp)
    8000381e:	69a2                	ld	s3,8(sp)
    80003820:	6145                	addi	sp,sp,48
    80003822:	8082                	ret
    panic("invalid file system");
    80003824:	00004517          	auipc	a0,0x4
    80003828:	f3450513          	addi	a0,a0,-204 # 80007758 <syscalls+0x1b0>
    8000382c:	f5ffc0ef          	jal	ra,8000078a <panic>

0000000080003830 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003830:	1141                	addi	sp,sp,-16
    80003832:	e422                	sd	s0,8(sp)
    80003834:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003836:	411c                	lw	a5,0(a0)
    80003838:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000383a:	415c                	lw	a5,4(a0)
    8000383c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000383e:	04451783          	lh	a5,68(a0)
    80003842:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003846:	04a51783          	lh	a5,74(a0)
    8000384a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000384e:	04c56783          	lwu	a5,76(a0)
    80003852:	e99c                	sd	a5,16(a1)
}
    80003854:	6422                	ld	s0,8(sp)
    80003856:	0141                	addi	sp,sp,16
    80003858:	8082                	ret

000000008000385a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000385a:	457c                	lw	a5,76(a0)
    8000385c:	0cd7ef63          	bltu	a5,a3,8000393a <readi+0xe0>
{
    80003860:	7159                	addi	sp,sp,-112
    80003862:	f486                	sd	ra,104(sp)
    80003864:	f0a2                	sd	s0,96(sp)
    80003866:	eca6                	sd	s1,88(sp)
    80003868:	e8ca                	sd	s2,80(sp)
    8000386a:	e4ce                	sd	s3,72(sp)
    8000386c:	e0d2                	sd	s4,64(sp)
    8000386e:	fc56                	sd	s5,56(sp)
    80003870:	f85a                	sd	s6,48(sp)
    80003872:	f45e                	sd	s7,40(sp)
    80003874:	f062                	sd	s8,32(sp)
    80003876:	ec66                	sd	s9,24(sp)
    80003878:	e86a                	sd	s10,16(sp)
    8000387a:	e46e                	sd	s11,8(sp)
    8000387c:	1880                	addi	s0,sp,112
    8000387e:	8b2a                	mv	s6,a0
    80003880:	8bae                	mv	s7,a1
    80003882:	8a32                	mv	s4,a2
    80003884:	84b6                	mv	s1,a3
    80003886:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003888:	9f35                	addw	a4,a4,a3
    return 0;
    8000388a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000388c:	08d76663          	bltu	a4,a3,80003918 <readi+0xbe>
  if(off + n > ip->size)
    80003890:	00e7f463          	bgeu	a5,a4,80003898 <readi+0x3e>
    n = ip->size - off;
    80003894:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003898:	080a8f63          	beqz	s5,80003936 <readi+0xdc>
    8000389c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000389e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800038a2:	5c7d                	li	s8,-1
    800038a4:	a80d                	j	800038d6 <readi+0x7c>
    800038a6:	020d1d93          	slli	s11,s10,0x20
    800038aa:	020ddd93          	srli	s11,s11,0x20
    800038ae:	05890793          	addi	a5,s2,88
    800038b2:	86ee                	mv	a3,s11
    800038b4:	963e                	add	a2,a2,a5
    800038b6:	85d2                	mv	a1,s4
    800038b8:	855e                	mv	a0,s7
    800038ba:	acffe0ef          	jal	ra,80002388 <either_copyout>
    800038be:	05850763          	beq	a0,s8,8000390c <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800038c2:	854a                	mv	a0,s2
    800038c4:	e60ff0ef          	jal	ra,80002f24 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800038c8:	013d09bb          	addw	s3,s10,s3
    800038cc:	009d04bb          	addw	s1,s10,s1
    800038d0:	9a6e                	add	s4,s4,s11
    800038d2:	0559f163          	bgeu	s3,s5,80003914 <readi+0xba>
    uint addr = bmap(ip, off/BSIZE);
    800038d6:	00a4d59b          	srliw	a1,s1,0xa
    800038da:	855a                	mv	a0,s6
    800038dc:	8bbff0ef          	jal	ra,80003196 <bmap>
    800038e0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800038e4:	c985                	beqz	a1,80003914 <readi+0xba>
    bp = bread(ip->dev, addr);
    800038e6:	000b2503          	lw	a0,0(s6)
    800038ea:	d32ff0ef          	jal	ra,80002e1c <bread>
    800038ee:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800038f0:	3ff4f613          	andi	a2,s1,1023
    800038f4:	40cc87bb          	subw	a5,s9,a2
    800038f8:	413a873b          	subw	a4,s5,s3
    800038fc:	8d3e                	mv	s10,a5
    800038fe:	2781                	sext.w	a5,a5
    80003900:	0007069b          	sext.w	a3,a4
    80003904:	faf6f1e3          	bgeu	a3,a5,800038a6 <readi+0x4c>
    80003908:	8d3a                	mv	s10,a4
    8000390a:	bf71                	j	800038a6 <readi+0x4c>
      brelse(bp);
    8000390c:	854a                	mv	a0,s2
    8000390e:	e16ff0ef          	jal	ra,80002f24 <brelse>
      tot = -1;
    80003912:	59fd                	li	s3,-1
  }
  return tot;
    80003914:	0009851b          	sext.w	a0,s3
}
    80003918:	70a6                	ld	ra,104(sp)
    8000391a:	7406                	ld	s0,96(sp)
    8000391c:	64e6                	ld	s1,88(sp)
    8000391e:	6946                	ld	s2,80(sp)
    80003920:	69a6                	ld	s3,72(sp)
    80003922:	6a06                	ld	s4,64(sp)
    80003924:	7ae2                	ld	s5,56(sp)
    80003926:	7b42                	ld	s6,48(sp)
    80003928:	7ba2                	ld	s7,40(sp)
    8000392a:	7c02                	ld	s8,32(sp)
    8000392c:	6ce2                	ld	s9,24(sp)
    8000392e:	6d42                	ld	s10,16(sp)
    80003930:	6da2                	ld	s11,8(sp)
    80003932:	6165                	addi	sp,sp,112
    80003934:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003936:	89d6                	mv	s3,s5
    80003938:	bff1                	j	80003914 <readi+0xba>
    return 0;
    8000393a:	4501                	li	a0,0
}
    8000393c:	8082                	ret

000000008000393e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000393e:	457c                	lw	a5,76(a0)
    80003940:	0ed7ea63          	bltu	a5,a3,80003a34 <writei+0xf6>
{
    80003944:	7159                	addi	sp,sp,-112
    80003946:	f486                	sd	ra,104(sp)
    80003948:	f0a2                	sd	s0,96(sp)
    8000394a:	eca6                	sd	s1,88(sp)
    8000394c:	e8ca                	sd	s2,80(sp)
    8000394e:	e4ce                	sd	s3,72(sp)
    80003950:	e0d2                	sd	s4,64(sp)
    80003952:	fc56                	sd	s5,56(sp)
    80003954:	f85a                	sd	s6,48(sp)
    80003956:	f45e                	sd	s7,40(sp)
    80003958:	f062                	sd	s8,32(sp)
    8000395a:	ec66                	sd	s9,24(sp)
    8000395c:	e86a                	sd	s10,16(sp)
    8000395e:	e46e                	sd	s11,8(sp)
    80003960:	1880                	addi	s0,sp,112
    80003962:	8aaa                	mv	s5,a0
    80003964:	8bae                	mv	s7,a1
    80003966:	8a32                	mv	s4,a2
    80003968:	8936                	mv	s2,a3
    8000396a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000396c:	00e687bb          	addw	a5,a3,a4
    80003970:	0cd7e463          	bltu	a5,a3,80003a38 <writei+0xfa>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003974:	00043737          	lui	a4,0x43
    80003978:	0cf76263          	bltu	a4,a5,80003a3c <writei+0xfe>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000397c:	0a0b0a63          	beqz	s6,80003a30 <writei+0xf2>
    80003980:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003982:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003986:	5c7d                	li	s8,-1
    80003988:	a825                	j	800039c0 <writei+0x82>
    8000398a:	020d1d93          	slli	s11,s10,0x20
    8000398e:	020ddd93          	srli	s11,s11,0x20
    80003992:	05848793          	addi	a5,s1,88
    80003996:	86ee                	mv	a3,s11
    80003998:	8652                	mv	a2,s4
    8000399a:	85de                	mv	a1,s7
    8000399c:	953e                	add	a0,a0,a5
    8000399e:	a35fe0ef          	jal	ra,800023d2 <either_copyin>
    800039a2:	05850a63          	beq	a0,s8,800039f6 <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    800039a6:	8526                	mv	a0,s1
    800039a8:	688000ef          	jal	ra,80004030 <log_write>
    brelse(bp);
    800039ac:	8526                	mv	a0,s1
    800039ae:	d76ff0ef          	jal	ra,80002f24 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039b2:	013d09bb          	addw	s3,s10,s3
    800039b6:	012d093b          	addw	s2,s10,s2
    800039ba:	9a6e                	add	s4,s4,s11
    800039bc:	0569f063          	bgeu	s3,s6,800039fc <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    800039c0:	00a9559b          	srliw	a1,s2,0xa
    800039c4:	8556                	mv	a0,s5
    800039c6:	fd0ff0ef          	jal	ra,80003196 <bmap>
    800039ca:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800039ce:	c59d                	beqz	a1,800039fc <writei+0xbe>
    bp = bread(ip->dev, addr);
    800039d0:	000aa503          	lw	a0,0(s5)
    800039d4:	c48ff0ef          	jal	ra,80002e1c <bread>
    800039d8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039da:	3ff97513          	andi	a0,s2,1023
    800039de:	40ac87bb          	subw	a5,s9,a0
    800039e2:	413b073b          	subw	a4,s6,s3
    800039e6:	8d3e                	mv	s10,a5
    800039e8:	2781                	sext.w	a5,a5
    800039ea:	0007069b          	sext.w	a3,a4
    800039ee:	f8f6fee3          	bgeu	a3,a5,8000398a <writei+0x4c>
    800039f2:	8d3a                	mv	s10,a4
    800039f4:	bf59                	j	8000398a <writei+0x4c>
      brelse(bp);
    800039f6:	8526                	mv	a0,s1
    800039f8:	d2cff0ef          	jal	ra,80002f24 <brelse>
  }

  if(off > ip->size)
    800039fc:	04caa783          	lw	a5,76(s5)
    80003a00:	0127f463          	bgeu	a5,s2,80003a08 <writei+0xca>
    ip->size = off;
    80003a04:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003a08:	8556                	mv	a0,s5
    80003a0a:	a13ff0ef          	jal	ra,8000341c <iupdate>

  return tot;
    80003a0e:	0009851b          	sext.w	a0,s3
}
    80003a12:	70a6                	ld	ra,104(sp)
    80003a14:	7406                	ld	s0,96(sp)
    80003a16:	64e6                	ld	s1,88(sp)
    80003a18:	6946                	ld	s2,80(sp)
    80003a1a:	69a6                	ld	s3,72(sp)
    80003a1c:	6a06                	ld	s4,64(sp)
    80003a1e:	7ae2                	ld	s5,56(sp)
    80003a20:	7b42                	ld	s6,48(sp)
    80003a22:	7ba2                	ld	s7,40(sp)
    80003a24:	7c02                	ld	s8,32(sp)
    80003a26:	6ce2                	ld	s9,24(sp)
    80003a28:	6d42                	ld	s10,16(sp)
    80003a2a:	6da2                	ld	s11,8(sp)
    80003a2c:	6165                	addi	sp,sp,112
    80003a2e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a30:	89da                	mv	s3,s6
    80003a32:	bfd9                	j	80003a08 <writei+0xca>
    return -1;
    80003a34:	557d                	li	a0,-1
}
    80003a36:	8082                	ret
    return -1;
    80003a38:	557d                	li	a0,-1
    80003a3a:	bfe1                	j	80003a12 <writei+0xd4>
    return -1;
    80003a3c:	557d                	li	a0,-1
    80003a3e:	bfd1                	j	80003a12 <writei+0xd4>

0000000080003a40 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003a40:	1141                	addi	sp,sp,-16
    80003a42:	e406                	sd	ra,8(sp)
    80003a44:	e022                	sd	s0,0(sp)
    80003a46:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003a48:	4639                	li	a2,14
    80003a4a:	c44fd0ef          	jal	ra,80000e8e <strncmp>
}
    80003a4e:	60a2                	ld	ra,8(sp)
    80003a50:	6402                	ld	s0,0(sp)
    80003a52:	0141                	addi	sp,sp,16
    80003a54:	8082                	ret

0000000080003a56 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003a56:	7139                	addi	sp,sp,-64
    80003a58:	fc06                	sd	ra,56(sp)
    80003a5a:	f822                	sd	s0,48(sp)
    80003a5c:	f426                	sd	s1,40(sp)
    80003a5e:	f04a                	sd	s2,32(sp)
    80003a60:	ec4e                	sd	s3,24(sp)
    80003a62:	e852                	sd	s4,16(sp)
    80003a64:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003a66:	04451703          	lh	a4,68(a0)
    80003a6a:	4785                	li	a5,1
    80003a6c:	00f71a63          	bne	a4,a5,80003a80 <dirlookup+0x2a>
    80003a70:	892a                	mv	s2,a0
    80003a72:	89ae                	mv	s3,a1
    80003a74:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003a76:	457c                	lw	a5,76(a0)
    80003a78:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003a7a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003a7c:	e39d                	bnez	a5,80003aa2 <dirlookup+0x4c>
    80003a7e:	a095                	j	80003ae2 <dirlookup+0x8c>
    panic("dirlookup not DIR");
    80003a80:	00004517          	auipc	a0,0x4
    80003a84:	cf050513          	addi	a0,a0,-784 # 80007770 <syscalls+0x1c8>
    80003a88:	d03fc0ef          	jal	ra,8000078a <panic>
      panic("dirlookup read");
    80003a8c:	00004517          	auipc	a0,0x4
    80003a90:	cfc50513          	addi	a0,a0,-772 # 80007788 <syscalls+0x1e0>
    80003a94:	cf7fc0ef          	jal	ra,8000078a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003a98:	24c1                	addiw	s1,s1,16
    80003a9a:	04c92783          	lw	a5,76(s2)
    80003a9e:	04f4f163          	bgeu	s1,a5,80003ae0 <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003aa2:	4741                	li	a4,16
    80003aa4:	86a6                	mv	a3,s1
    80003aa6:	fc040613          	addi	a2,s0,-64
    80003aaa:	4581                	li	a1,0
    80003aac:	854a                	mv	a0,s2
    80003aae:	dadff0ef          	jal	ra,8000385a <readi>
    80003ab2:	47c1                	li	a5,16
    80003ab4:	fcf51ce3          	bne	a0,a5,80003a8c <dirlookup+0x36>
    if(de.inum == 0)
    80003ab8:	fc045783          	lhu	a5,-64(s0)
    80003abc:	dff1                	beqz	a5,80003a98 <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    80003abe:	fc240593          	addi	a1,s0,-62
    80003ac2:	854e                	mv	a0,s3
    80003ac4:	f7dff0ef          	jal	ra,80003a40 <namecmp>
    80003ac8:	f961                	bnez	a0,80003a98 <dirlookup+0x42>
      if(poff)
    80003aca:	000a0463          	beqz	s4,80003ad2 <dirlookup+0x7c>
        *poff = off;
    80003ace:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ad2:	fc045583          	lhu	a1,-64(s0)
    80003ad6:	00092503          	lw	a0,0(s2)
    80003ada:	f88ff0ef          	jal	ra,80003262 <iget>
    80003ade:	a011                	j	80003ae2 <dirlookup+0x8c>
  return 0;
    80003ae0:	4501                	li	a0,0
}
    80003ae2:	70e2                	ld	ra,56(sp)
    80003ae4:	7442                	ld	s0,48(sp)
    80003ae6:	74a2                	ld	s1,40(sp)
    80003ae8:	7902                	ld	s2,32(sp)
    80003aea:	69e2                	ld	s3,24(sp)
    80003aec:	6a42                	ld	s4,16(sp)
    80003aee:	6121                	addi	sp,sp,64
    80003af0:	8082                	ret

0000000080003af2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003af2:	711d                	addi	sp,sp,-96
    80003af4:	ec86                	sd	ra,88(sp)
    80003af6:	e8a2                	sd	s0,80(sp)
    80003af8:	e4a6                	sd	s1,72(sp)
    80003afa:	e0ca                	sd	s2,64(sp)
    80003afc:	fc4e                	sd	s3,56(sp)
    80003afe:	f852                	sd	s4,48(sp)
    80003b00:	f456                	sd	s5,40(sp)
    80003b02:	f05a                	sd	s6,32(sp)
    80003b04:	ec5e                	sd	s7,24(sp)
    80003b06:	e862                	sd	s8,16(sp)
    80003b08:	e466                	sd	s9,8(sp)
    80003b0a:	1080                	addi	s0,sp,96
    80003b0c:	84aa                	mv	s1,a0
    80003b0e:	8aae                	mv	s5,a1
    80003b10:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003b12:	00054703          	lbu	a4,0(a0)
    80003b16:	02f00793          	li	a5,47
    80003b1a:	00f70f63          	beq	a4,a5,80003b38 <namex+0x46>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003b1e:	efdfd0ef          	jal	ra,80001a1a <myproc>
    80003b22:	15053503          	ld	a0,336(a0)
    80003b26:	973ff0ef          	jal	ra,80003498 <idup>
    80003b2a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003b2c:	02f00913          	li	s2,47
  len = path - s;
    80003b30:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003b32:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003b34:	4b85                	li	s7,1
    80003b36:	a861                	j	80003bce <namex+0xdc>
    ip = iget(ROOTDEV, ROOTINO);
    80003b38:	4585                	li	a1,1
    80003b3a:	4505                	li	a0,1
    80003b3c:	f26ff0ef          	jal	ra,80003262 <iget>
    80003b40:	89aa                	mv	s3,a0
    80003b42:	b7ed                	j	80003b2c <namex+0x3a>
      iunlockput(ip);
    80003b44:	854e                	mv	a0,s3
    80003b46:	b8fff0ef          	jal	ra,800036d4 <iunlockput>
      return 0;
    80003b4a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003b4c:	854e                	mv	a0,s3
    80003b4e:	60e6                	ld	ra,88(sp)
    80003b50:	6446                	ld	s0,80(sp)
    80003b52:	64a6                	ld	s1,72(sp)
    80003b54:	6906                	ld	s2,64(sp)
    80003b56:	79e2                	ld	s3,56(sp)
    80003b58:	7a42                	ld	s4,48(sp)
    80003b5a:	7aa2                	ld	s5,40(sp)
    80003b5c:	7b02                	ld	s6,32(sp)
    80003b5e:	6be2                	ld	s7,24(sp)
    80003b60:	6c42                	ld	s8,16(sp)
    80003b62:	6ca2                	ld	s9,8(sp)
    80003b64:	6125                	addi	sp,sp,96
    80003b66:	8082                	ret
      iunlock(ip);
    80003b68:	854e                	mv	a0,s3
    80003b6a:	a0fff0ef          	jal	ra,80003578 <iunlock>
      return ip;
    80003b6e:	bff9                	j	80003b4c <namex+0x5a>
      iunlockput(ip);
    80003b70:	854e                	mv	a0,s3
    80003b72:	b63ff0ef          	jal	ra,800036d4 <iunlockput>
      return 0;
    80003b76:	89e6                	mv	s3,s9
    80003b78:	bfd1                	j	80003b4c <namex+0x5a>
  len = path - s;
    80003b7a:	40b48633          	sub	a2,s1,a1
    80003b7e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003b82:	079c5c63          	bge	s8,s9,80003bfa <namex+0x108>
    memmove(name, s, DIRSIZ);
    80003b86:	4639                	li	a2,14
    80003b88:	8552                	mv	a0,s4
    80003b8a:	a94fd0ef          	jal	ra,80000e1e <memmove>
  while(*path == '/')
    80003b8e:	0004c783          	lbu	a5,0(s1)
    80003b92:	01279763          	bne	a5,s2,80003ba0 <namex+0xae>
    path++;
    80003b96:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003b98:	0004c783          	lbu	a5,0(s1)
    80003b9c:	ff278de3          	beq	a5,s2,80003b96 <namex+0xa4>
    ilock(ip);
    80003ba0:	854e                	mv	a0,s3
    80003ba2:	92dff0ef          	jal	ra,800034ce <ilock>
    if(ip->type != T_DIR){
    80003ba6:	04499783          	lh	a5,68(s3)
    80003baa:	f9779de3          	bne	a5,s7,80003b44 <namex+0x52>
    if(nameiparent && *path == '\0'){
    80003bae:	000a8563          	beqz	s5,80003bb8 <namex+0xc6>
    80003bb2:	0004c783          	lbu	a5,0(s1)
    80003bb6:	dbcd                	beqz	a5,80003b68 <namex+0x76>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003bb8:	865a                	mv	a2,s6
    80003bba:	85d2                	mv	a1,s4
    80003bbc:	854e                	mv	a0,s3
    80003bbe:	e99ff0ef          	jal	ra,80003a56 <dirlookup>
    80003bc2:	8caa                	mv	s9,a0
    80003bc4:	d555                	beqz	a0,80003b70 <namex+0x7e>
    iunlockput(ip);
    80003bc6:	854e                	mv	a0,s3
    80003bc8:	b0dff0ef          	jal	ra,800036d4 <iunlockput>
    ip = next;
    80003bcc:	89e6                	mv	s3,s9
  while(*path == '/')
    80003bce:	0004c783          	lbu	a5,0(s1)
    80003bd2:	05279363          	bne	a5,s2,80003c18 <namex+0x126>
    path++;
    80003bd6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003bd8:	0004c783          	lbu	a5,0(s1)
    80003bdc:	ff278de3          	beq	a5,s2,80003bd6 <namex+0xe4>
  if(*path == 0)
    80003be0:	c78d                	beqz	a5,80003c0a <namex+0x118>
    path++;
    80003be2:	85a6                	mv	a1,s1
  len = path - s;
    80003be4:	8cda                	mv	s9,s6
    80003be6:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003be8:	01278963          	beq	a5,s2,80003bfa <namex+0x108>
    80003bec:	d7d9                	beqz	a5,80003b7a <namex+0x88>
    path++;
    80003bee:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003bf0:	0004c783          	lbu	a5,0(s1)
    80003bf4:	ff279ce3          	bne	a5,s2,80003bec <namex+0xfa>
    80003bf8:	b749                	j	80003b7a <namex+0x88>
    memmove(name, s, len);
    80003bfa:	2601                	sext.w	a2,a2
    80003bfc:	8552                	mv	a0,s4
    80003bfe:	a20fd0ef          	jal	ra,80000e1e <memmove>
    name[len] = 0;
    80003c02:	9cd2                	add	s9,s9,s4
    80003c04:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003c08:	b759                	j	80003b8e <namex+0x9c>
  if(nameiparent){
    80003c0a:	f40a81e3          	beqz	s5,80003b4c <namex+0x5a>
    iput(ip);
    80003c0e:	854e                	mv	a0,s3
    80003c10:	a3dff0ef          	jal	ra,8000364c <iput>
    return 0;
    80003c14:	4981                	li	s3,0
    80003c16:	bf1d                	j	80003b4c <namex+0x5a>
  if(*path == 0)
    80003c18:	dbed                	beqz	a5,80003c0a <namex+0x118>
  while(*path != '/' && *path != 0)
    80003c1a:	0004c783          	lbu	a5,0(s1)
    80003c1e:	85a6                	mv	a1,s1
    80003c20:	b7f1                	j	80003bec <namex+0xfa>

0000000080003c22 <dirlink>:
{
    80003c22:	7139                	addi	sp,sp,-64
    80003c24:	fc06                	sd	ra,56(sp)
    80003c26:	f822                	sd	s0,48(sp)
    80003c28:	f426                	sd	s1,40(sp)
    80003c2a:	f04a                	sd	s2,32(sp)
    80003c2c:	ec4e                	sd	s3,24(sp)
    80003c2e:	e852                	sd	s4,16(sp)
    80003c30:	0080                	addi	s0,sp,64
    80003c32:	892a                	mv	s2,a0
    80003c34:	8a2e                	mv	s4,a1
    80003c36:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003c38:	4601                	li	a2,0
    80003c3a:	e1dff0ef          	jal	ra,80003a56 <dirlookup>
    80003c3e:	e52d                	bnez	a0,80003ca8 <dirlink+0x86>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c40:	04c92483          	lw	s1,76(s2)
    80003c44:	c48d                	beqz	s1,80003c6e <dirlink+0x4c>
    80003c46:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c48:	4741                	li	a4,16
    80003c4a:	86a6                	mv	a3,s1
    80003c4c:	fc040613          	addi	a2,s0,-64
    80003c50:	4581                	li	a1,0
    80003c52:	854a                	mv	a0,s2
    80003c54:	c07ff0ef          	jal	ra,8000385a <readi>
    80003c58:	47c1                	li	a5,16
    80003c5a:	04f51b63          	bne	a0,a5,80003cb0 <dirlink+0x8e>
    if(de.inum == 0)
    80003c5e:	fc045783          	lhu	a5,-64(s0)
    80003c62:	c791                	beqz	a5,80003c6e <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c64:	24c1                	addiw	s1,s1,16
    80003c66:	04c92783          	lw	a5,76(s2)
    80003c6a:	fcf4efe3          	bltu	s1,a5,80003c48 <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80003c6e:	4639                	li	a2,14
    80003c70:	85d2                	mv	a1,s4
    80003c72:	fc240513          	addi	a0,s0,-62
    80003c76:	a54fd0ef          	jal	ra,80000eca <strncpy>
  de.inum = inum;
    80003c7a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c7e:	4741                	li	a4,16
    80003c80:	86a6                	mv	a3,s1
    80003c82:	fc040613          	addi	a2,s0,-64
    80003c86:	4581                	li	a1,0
    80003c88:	854a                	mv	a0,s2
    80003c8a:	cb5ff0ef          	jal	ra,8000393e <writei>
    80003c8e:	1541                	addi	a0,a0,-16
    80003c90:	00a03533          	snez	a0,a0
    80003c94:	40a00533          	neg	a0,a0
}
    80003c98:	70e2                	ld	ra,56(sp)
    80003c9a:	7442                	ld	s0,48(sp)
    80003c9c:	74a2                	ld	s1,40(sp)
    80003c9e:	7902                	ld	s2,32(sp)
    80003ca0:	69e2                	ld	s3,24(sp)
    80003ca2:	6a42                	ld	s4,16(sp)
    80003ca4:	6121                	addi	sp,sp,64
    80003ca6:	8082                	ret
    iput(ip);
    80003ca8:	9a5ff0ef          	jal	ra,8000364c <iput>
    return -1;
    80003cac:	557d                	li	a0,-1
    80003cae:	b7ed                	j	80003c98 <dirlink+0x76>
      panic("dirlink read");
    80003cb0:	00004517          	auipc	a0,0x4
    80003cb4:	ae850513          	addi	a0,a0,-1304 # 80007798 <syscalls+0x1f0>
    80003cb8:	ad3fc0ef          	jal	ra,8000078a <panic>

0000000080003cbc <namei>:

struct inode*
namei(char *path)
{
    80003cbc:	1101                	addi	sp,sp,-32
    80003cbe:	ec06                	sd	ra,24(sp)
    80003cc0:	e822                	sd	s0,16(sp)
    80003cc2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003cc4:	fe040613          	addi	a2,s0,-32
    80003cc8:	4581                	li	a1,0
    80003cca:	e29ff0ef          	jal	ra,80003af2 <namex>
}
    80003cce:	60e2                	ld	ra,24(sp)
    80003cd0:	6442                	ld	s0,16(sp)
    80003cd2:	6105                	addi	sp,sp,32
    80003cd4:	8082                	ret

0000000080003cd6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003cd6:	1141                	addi	sp,sp,-16
    80003cd8:	e406                	sd	ra,8(sp)
    80003cda:	e022                	sd	s0,0(sp)
    80003cdc:	0800                	addi	s0,sp,16
    80003cde:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ce0:	4585                	li	a1,1
    80003ce2:	e11ff0ef          	jal	ra,80003af2 <namex>
}
    80003ce6:	60a2                	ld	ra,8(sp)
    80003ce8:	6402                	ld	s0,0(sp)
    80003cea:	0141                	addi	sp,sp,16
    80003cec:	8082                	ret

0000000080003cee <write_head>:
  brelse(buf);  // 释放缓冲区
}

// 将内存中的日志头写回磁盘
static void write_head(void)
{
    80003cee:	1101                	addi	sp,sp,-32
    80003cf0:	ec06                	sd	ra,24(sp)
    80003cf2:	e822                	sd	s0,16(sp)
    80003cf4:	e426                	sd	s1,8(sp)
    80003cf6:	e04a                	sd	s2,0(sp)
    80003cf8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003cfa:	00024917          	auipc	s2,0x24
    80003cfe:	fc690913          	addi	s2,s2,-58 # 80027cc0 <log>
    80003d02:	01892583          	lw	a1,24(s2)
    80003d06:	02492503          	lw	a0,36(s2)
    80003d0a:	912ff0ef          	jal	ra,80002e1c <bread>
    80003d0e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;  // 更新日志中的块数量
    80003d10:	02892683          	lw	a3,40(s2)
    80003d14:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003d16:	02d05763          	blez	a3,80003d44 <write_head+0x56>
    80003d1a:	00024797          	auipc	a5,0x24
    80003d1e:	fd278793          	addi	a5,a5,-46 # 80027cec <log+0x2c>
    80003d22:	05c50713          	addi	a4,a0,92
    80003d26:	36fd                	addiw	a3,a3,-1
    80003d28:	1682                	slli	a3,a3,0x20
    80003d2a:	9281                	srli	a3,a3,0x20
    80003d2c:	068a                	slli	a3,a3,0x2
    80003d2e:	00024617          	auipc	a2,0x24
    80003d32:	fc260613          	addi	a2,a2,-62 # 80027cf0 <log+0x30>
    80003d36:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];  // 更新每个日志块的块号
    80003d38:	4390                	lw	a2,0(a5)
    80003d3a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003d3c:	0791                	addi	a5,a5,4
    80003d3e:	0711                	addi	a4,a4,4
    80003d40:	fed79ce3          	bne	a5,a3,80003d38 <write_head+0x4a>
  }
  bwrite(buf);  // 写回日志头块
    80003d44:	8526                	mv	a0,s1
    80003d46:	9acff0ef          	jal	ra,80002ef2 <bwrite>
  brelse(buf);  // 释放缓冲区
    80003d4a:	8526                	mv	a0,s1
    80003d4c:	9d8ff0ef          	jal	ra,80002f24 <brelse>
}
    80003d50:	60e2                	ld	ra,24(sp)
    80003d52:	6442                	ld	s0,16(sp)
    80003d54:	64a2                	ld	s1,8(sp)
    80003d56:	6902                	ld	s2,0(sp)
    80003d58:	6105                	addi	sp,sp,32
    80003d5a:	8082                	ret

0000000080003d5c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003d5c:	00024797          	auipc	a5,0x24
    80003d60:	f8c7a783          	lw	a5,-116(a5) # 80027ce8 <log+0x28>
    80003d64:	0af05e63          	blez	a5,80003e20 <install_trans+0xc4>
{
    80003d68:	715d                	addi	sp,sp,-80
    80003d6a:	e486                	sd	ra,72(sp)
    80003d6c:	e0a2                	sd	s0,64(sp)
    80003d6e:	fc26                	sd	s1,56(sp)
    80003d70:	f84a                	sd	s2,48(sp)
    80003d72:	f44e                	sd	s3,40(sp)
    80003d74:	f052                	sd	s4,32(sp)
    80003d76:	ec56                	sd	s5,24(sp)
    80003d78:	e85a                	sd	s6,16(sp)
    80003d7a:	e45e                	sd	s7,8(sp)
    80003d7c:	0880                	addi	s0,sp,80
    80003d7e:	8b2a                	mv	s6,a0
    80003d80:	00024a97          	auipc	s5,0x24
    80003d84:	f6ca8a93          	addi	s5,s5,-148 # 80027cec <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003d88:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003d8a:	00004b97          	auipc	s7,0x4
    80003d8e:	a1eb8b93          	addi	s7,s7,-1506 # 800077a8 <syscalls+0x200>
    struct buf *lbuf = bread(log.dev, log.start + tail + 1);  // 读取日志块
    80003d92:	00024a17          	auipc	s4,0x24
    80003d96:	f2ea0a13          	addi	s4,s4,-210 # 80027cc0 <log>
    80003d9a:	a025                	j	80003dc2 <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003d9c:	000aa603          	lw	a2,0(s5)
    80003da0:	85ce                	mv	a1,s3
    80003da2:	855e                	mv	a0,s7
    80003da4:	f20fc0ef          	jal	ra,800004c4 <printf>
    80003da8:	a839                	j	80003dc6 <install_trans+0x6a>
    brelse(lbuf);  // 释放日志块
    80003daa:	854a                	mv	a0,s2
    80003dac:	978ff0ef          	jal	ra,80002f24 <brelse>
    brelse(dbuf);  // 释放目标块
    80003db0:	8526                	mv	a0,s1
    80003db2:	972ff0ef          	jal	ra,80002f24 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003db6:	2985                	addiw	s3,s3,1
    80003db8:	0a91                	addi	s5,s5,4
    80003dba:	028a2783          	lw	a5,40(s4)
    80003dbe:	04f9d663          	bge	s3,a5,80003e0a <install_trans+0xae>
    if(recovering) {
    80003dc2:	fc0b1de3          	bnez	s6,80003d9c <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start + tail + 1);  // 读取日志块
    80003dc6:	018a2583          	lw	a1,24(s4)
    80003dca:	013585bb          	addw	a1,a1,s3
    80003dce:	2585                	addiw	a1,a1,1
    80003dd0:	024a2503          	lw	a0,36(s4)
    80003dd4:	848ff0ef          	jal	ra,80002e1c <bread>
    80003dd8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]);  // 读取目标块
    80003dda:	000aa583          	lw	a1,0(s5)
    80003dde:	024a2503          	lw	a0,36(s4)
    80003de2:	83aff0ef          	jal	ra,80002e1c <bread>
    80003de6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);
    80003de8:	40000613          	li	a2,1024
    80003dec:	05890593          	addi	a1,s2,88
    80003df0:	05850513          	addi	a0,a0,88
    80003df4:	82afd0ef          	jal	ra,80000e1e <memmove>
    bwrite(dbuf);  // 将目标块写回磁盘
    80003df8:	8526                	mv	a0,s1
    80003dfa:	8f8ff0ef          	jal	ra,80002ef2 <bwrite>
    if(recovering == 0)
    80003dfe:	fa0b16e3          	bnez	s6,80003daa <install_trans+0x4e>
      bunpin(dbuf);  // 提交后解锁目标块
    80003e02:	8526                	mv	a0,s1
    80003e04:	9deff0ef          	jal	ra,80002fe2 <bunpin>
    80003e08:	b74d                	j	80003daa <install_trans+0x4e>
}
    80003e0a:	60a6                	ld	ra,72(sp)
    80003e0c:	6406                	ld	s0,64(sp)
    80003e0e:	74e2                	ld	s1,56(sp)
    80003e10:	7942                	ld	s2,48(sp)
    80003e12:	79a2                	ld	s3,40(sp)
    80003e14:	7a02                	ld	s4,32(sp)
    80003e16:	6ae2                	ld	s5,24(sp)
    80003e18:	6b42                	ld	s6,16(sp)
    80003e1a:	6ba2                	ld	s7,8(sp)
    80003e1c:	6161                	addi	sp,sp,80
    80003e1e:	8082                	ret
    80003e20:	8082                	ret

0000000080003e22 <initlog>:
{
    80003e22:	7179                	addi	sp,sp,-48
    80003e24:	f406                	sd	ra,40(sp)
    80003e26:	f022                	sd	s0,32(sp)
    80003e28:	ec26                	sd	s1,24(sp)
    80003e2a:	e84a                	sd	s2,16(sp)
    80003e2c:	e44e                	sd	s3,8(sp)
    80003e2e:	1800                	addi	s0,sp,48
    80003e30:	892a                	mv	s2,a0
    80003e32:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003e34:	00024497          	auipc	s1,0x24
    80003e38:	e8c48493          	addi	s1,s1,-372 # 80027cc0 <log>
    80003e3c:	00004597          	auipc	a1,0x4
    80003e40:	98c58593          	addi	a1,a1,-1652 # 800077c8 <syscalls+0x220>
    80003e44:	8526                	mv	a0,s1
    80003e46:	e29fc0ef          	jal	ra,80000c6e <initlock>
  log.start = sb->logstart;  // 设置日志起始位置
    80003e4a:	0149a583          	lw	a1,20(s3)
    80003e4e:	cc8c                	sw	a1,24(s1)
  log.dev = dev;  // 设置日志设备
    80003e50:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003e54:	854a                	mv	a0,s2
    80003e56:	fc7fe0ef          	jal	ra,80002e1c <bread>
  log.lh.n = lh->n;  // 读取日志中的块数量
    80003e5a:	4d34                	lw	a3,88(a0)
    80003e5c:	d494                	sw	a3,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003e5e:	02d05563          	blez	a3,80003e88 <initlog+0x66>
    80003e62:	05c50793          	addi	a5,a0,92
    80003e66:	00024717          	auipc	a4,0x24
    80003e6a:	e8670713          	addi	a4,a4,-378 # 80027cec <log+0x2c>
    80003e6e:	36fd                	addiw	a3,a3,-1
    80003e70:	1682                	slli	a3,a3,0x20
    80003e72:	9281                	srli	a3,a3,0x20
    80003e74:	068a                	slli	a3,a3,0x2
    80003e76:	06050613          	addi	a2,a0,96
    80003e7a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];  // 读取每个日志块的块号
    80003e7c:	4390                	lw	a2,0(a5)
    80003e7e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e80:	0791                	addi	a5,a5,4
    80003e82:	0711                	addi	a4,a4,4
    80003e84:	fed79ce3          	bne	a5,a3,80003e7c <initlog+0x5a>
  brelse(buf);  // 释放缓冲区
    80003e88:	89cff0ef          	jal	ra,80002f24 <brelse>

// 从日志中恢复
static void recover_from_log(void)
{
  read_head();  // 读取日志头
  install_trans(1);  // 如果已提交，从日志复制到磁盘
    80003e8c:	4505                	li	a0,1
    80003e8e:	ecfff0ef          	jal	ra,80003d5c <install_trans>
  log.lh.n = 0;  // 清空日志中的块数量
    80003e92:	00024797          	auipc	a5,0x24
    80003e96:	e407ab23          	sw	zero,-426(a5) # 80027ce8 <log+0x28>
  write_head();  // 清空日志
    80003e9a:	e55ff0ef          	jal	ra,80003cee <write_head>
}
    80003e9e:	70a2                	ld	ra,40(sp)
    80003ea0:	7402                	ld	s0,32(sp)
    80003ea2:	64e2                	ld	s1,24(sp)
    80003ea4:	6942                	ld	s2,16(sp)
    80003ea6:	69a2                	ld	s3,8(sp)
    80003ea8:	6145                	addi	sp,sp,48
    80003eaa:	8082                	ret

0000000080003eac <begin_op>:
}

// 文件系统调用开始时调用
void begin_op(void)
{
    80003eac:	1101                	addi	sp,sp,-32
    80003eae:	ec06                	sd	ra,24(sp)
    80003eb0:	e822                	sd	s0,16(sp)
    80003eb2:	e426                	sd	s1,8(sp)
    80003eb4:	e04a                	sd	s2,0(sp)
    80003eb6:	1000                	addi	s0,sp,32
  acquire(&log.lock);  // 获取日志锁
    80003eb8:	00024517          	auipc	a0,0x24
    80003ebc:	e0850513          	addi	a0,a0,-504 # 80027cc0 <log>
    80003ec0:	e2ffc0ef          	jal	ra,80000cee <acquire>
  while(1){
    if(log.committing){
    80003ec4:	00024497          	auipc	s1,0x24
    80003ec8:	dfc48493          	addi	s1,s1,-516 # 80027cc0 <log>
      // 如果日志正在提交，进入睡眠
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGBLOCKS){
    80003ecc:	4979                	li	s2,30
    80003ece:	a029                	j	80003ed8 <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003ed0:	85a6                	mv	a1,s1
    80003ed2:	8526                	mv	a0,s1
    80003ed4:	958fe0ef          	jal	ra,8000202c <sleep>
    if(log.committing){
    80003ed8:	509c                	lw	a5,32(s1)
    80003eda:	fbfd                	bnez	a5,80003ed0 <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGBLOCKS){
    80003edc:	4cdc                	lw	a5,28(s1)
    80003ede:	0017871b          	addiw	a4,a5,1
    80003ee2:	0007069b          	sext.w	a3,a4
    80003ee6:	0027179b          	slliw	a5,a4,0x2
    80003eea:	9fb9                	addw	a5,a5,a4
    80003eec:	0017979b          	slliw	a5,a5,0x1
    80003ef0:	5498                	lw	a4,40(s1)
    80003ef2:	9fb9                	addw	a5,a5,a4
    80003ef4:	00f95763          	bge	s2,a5,80003f02 <begin_op+0x56>
      // 如果当前操作可能耗尽日志空间，等待提交
      sleep(&log, &log.lock);
    80003ef8:	85a6                	mv	a1,s1
    80003efa:	8526                	mv	a0,s1
    80003efc:	930fe0ef          	jal	ra,8000202c <sleep>
    80003f00:	bfe1                	j	80003ed8 <begin_op+0x2c>
    } else {
      log.outstanding += 1;  // 增加正在进行的操作计数
    80003f02:	00024517          	auipc	a0,0x24
    80003f06:	dbe50513          	addi	a0,a0,-578 # 80027cc0 <log>
    80003f0a:	cd54                	sw	a3,28(a0)
      release(&log.lock);  // 释放日志锁
    80003f0c:	e7bfc0ef          	jal	ra,80000d86 <release>
      break;
    }
  }
}
    80003f10:	60e2                	ld	ra,24(sp)
    80003f12:	6442                	ld	s0,16(sp)
    80003f14:	64a2                	ld	s1,8(sp)
    80003f16:	6902                	ld	s2,0(sp)
    80003f18:	6105                	addi	sp,sp,32
    80003f1a:	8082                	ret

0000000080003f1c <end_op>:

// 文件系统调用结束时调用
// 如果这是最后一个待处理的操作，则提交日志
void end_op(void)
{
    80003f1c:	7139                	addi	sp,sp,-64
    80003f1e:	fc06                	sd	ra,56(sp)
    80003f20:	f822                	sd	s0,48(sp)
    80003f22:	f426                	sd	s1,40(sp)
    80003f24:	f04a                	sd	s2,32(sp)
    80003f26:	ec4e                	sd	s3,24(sp)
    80003f28:	e852                	sd	s4,16(sp)
    80003f2a:	e456                	sd	s5,8(sp)
    80003f2c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);  // 获取日志锁
    80003f2e:	00024497          	auipc	s1,0x24
    80003f32:	d9248493          	addi	s1,s1,-622 # 80027cc0 <log>
    80003f36:	8526                	mv	a0,s1
    80003f38:	db7fc0ef          	jal	ra,80000cee <acquire>
  log.outstanding -= 1;  // 减少待处理操作计数
    80003f3c:	4cdc                	lw	a5,28(s1)
    80003f3e:	37fd                	addiw	a5,a5,-1
    80003f40:	0007891b          	sext.w	s2,a5
    80003f44:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80003f46:	509c                	lw	a5,32(s1)
    80003f48:	ef9d                	bnez	a5,80003f86 <end_op+0x6a>
    panic("log.committing");  // 不允许在提交时结束操作
  if(log.outstanding == 0){
    80003f4a:	04091463          	bnez	s2,80003f92 <end_op+0x76>
    do_commit = 1;  // 如果没有待处理的操作，则标记为需要提交
    log.committing = 1;  // 标记日志为正在提交
    80003f4e:	00024497          	auipc	s1,0x24
    80003f52:	d7248493          	addi	s1,s1,-654 # 80027cc0 <log>
    80003f56:	4785                	li	a5,1
    80003f58:	d09c                	sw	a5,32(s1)
  } else {
    // 如果正在等待日志空间，唤醒等待的进程
    wakeup(&log);
  }
  release(&log.lock);  // 释放日志锁
    80003f5a:	8526                	mv	a0,s1
    80003f5c:	e2bfc0ef          	jal	ra,80000d86 <release>
}

// 提交事务，将日志中的块写回磁盘并清空日志
static void commit()
{
  if (log.lh.n > 0) {
    80003f60:	549c                	lw	a5,40(s1)
    80003f62:	04f04b63          	bgtz	a5,80003fb8 <end_op+0x9c>
    acquire(&log.lock);
    80003f66:	00024497          	auipc	s1,0x24
    80003f6a:	d5a48493          	addi	s1,s1,-678 # 80027cc0 <log>
    80003f6e:	8526                	mv	a0,s1
    80003f70:	d7ffc0ef          	jal	ra,80000cee <acquire>
    log.committing = 0;  // 提交完成，恢复日志状态
    80003f74:	0204a023          	sw	zero,32(s1)
    wakeup(&log);  // 唤醒可能在等待提交的进程
    80003f78:	8526                	mv	a0,s1
    80003f7a:	8fefe0ef          	jal	ra,80002078 <wakeup>
    release(&log.lock);  // 释放日志锁
    80003f7e:	8526                	mv	a0,s1
    80003f80:	e07fc0ef          	jal	ra,80000d86 <release>
}
    80003f84:	a00d                	j	80003fa6 <end_op+0x8a>
    panic("log.committing");  // 不允许在提交时结束操作
    80003f86:	00004517          	auipc	a0,0x4
    80003f8a:	84a50513          	addi	a0,a0,-1974 # 800077d0 <syscalls+0x228>
    80003f8e:	ffcfc0ef          	jal	ra,8000078a <panic>
    wakeup(&log);
    80003f92:	00024497          	auipc	s1,0x24
    80003f96:	d2e48493          	addi	s1,s1,-722 # 80027cc0 <log>
    80003f9a:	8526                	mv	a0,s1
    80003f9c:	8dcfe0ef          	jal	ra,80002078 <wakeup>
  release(&log.lock);  // 释放日志锁
    80003fa0:	8526                	mv	a0,s1
    80003fa2:	de5fc0ef          	jal	ra,80000d86 <release>
}
    80003fa6:	70e2                	ld	ra,56(sp)
    80003fa8:	7442                	ld	s0,48(sp)
    80003faa:	74a2                	ld	s1,40(sp)
    80003fac:	7902                	ld	s2,32(sp)
    80003fae:	69e2                	ld	s3,24(sp)
    80003fb0:	6a42                	ld	s4,16(sp)
    80003fb2:	6aa2                	ld	s5,8(sp)
    80003fb4:	6121                	addi	sp,sp,64
    80003fb6:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fb8:	00024a97          	auipc	s5,0x24
    80003fbc:	d34a8a93          	addi	s5,s5,-716 # 80027cec <log+0x2c>
    struct buf *to = bread(log.dev, log.start + tail + 1);  // 读取日志块
    80003fc0:	00024a17          	auipc	s4,0x24
    80003fc4:	d00a0a13          	addi	s4,s4,-768 # 80027cc0 <log>
    80003fc8:	018a2583          	lw	a1,24(s4)
    80003fcc:	012585bb          	addw	a1,a1,s2
    80003fd0:	2585                	addiw	a1,a1,1
    80003fd2:	024a2503          	lw	a0,36(s4)
    80003fd6:	e47fe0ef          	jal	ra,80002e1c <bread>
    80003fda:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]);  // 读取缓存块
    80003fdc:	000aa583          	lw	a1,0(s5)
    80003fe0:	024a2503          	lw	a0,36(s4)
    80003fe4:	e39fe0ef          	jal	ra,80002e1c <bread>
    80003fe8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);  // 将缓存块的数据复制到日志块
    80003fea:	40000613          	li	a2,1024
    80003fee:	05850593          	addi	a1,a0,88
    80003ff2:	05848513          	addi	a0,s1,88
    80003ff6:	e29fc0ef          	jal	ra,80000e1e <memmove>
    bwrite(to);  // 写入日志块
    80003ffa:	8526                	mv	a0,s1
    80003ffc:	ef7fe0ef          	jal	ra,80002ef2 <bwrite>
    brelse(from);  // 释放缓存块
    80004000:	854e                	mv	a0,s3
    80004002:	f23fe0ef          	jal	ra,80002f24 <brelse>
    brelse(to);  // 释放日志块
    80004006:	8526                	mv	a0,s1
    80004008:	f1dfe0ef          	jal	ra,80002f24 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000400c:	2905                	addiw	s2,s2,1
    8000400e:	0a91                	addi	s5,s5,4
    80004010:	028a2783          	lw	a5,40(s4)
    80004014:	faf94ae3          	blt	s2,a5,80003fc8 <end_op+0xac>
    write_log();     // 将已修改的块从缓存写入日志
    write_head();    // 写入日志头到磁盘，真正提交
    80004018:	cd7ff0ef          	jal	ra,80003cee <write_head>
    install_trans(0); // 将写入操作应用到实际位置
    8000401c:	4501                	li	a0,0
    8000401e:	d3fff0ef          	jal	ra,80003d5c <install_trans>
    log.lh.n = 0;    // 清空日志中的块数量
    80004022:	00024797          	auipc	a5,0x24
    80004026:	cc07a323          	sw	zero,-826(a5) # 80027ce8 <log+0x28>
    write_head();    // 清空日志
    8000402a:	cc5ff0ef          	jal	ra,80003cee <write_head>
    8000402e:	bf25                	j	80003f66 <end_op+0x4a>

0000000080004030 <log_write>:
//   bp = bread(...)
//   修改 bp->data[]
//   log_write(bp)
//   brelse(bp)
void log_write(struct buf *b)
{
    80004030:	1101                	addi	sp,sp,-32
    80004032:	ec06                	sd	ra,24(sp)
    80004034:	e822                	sd	s0,16(sp)
    80004036:	e426                	sd	s1,8(sp)
    80004038:	e04a                	sd	s2,0(sp)
    8000403a:	1000                	addi	s0,sp,32
    8000403c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);  // 获取日志锁
    8000403e:	00024917          	auipc	s2,0x24
    80004042:	c8290913          	addi	s2,s2,-894 # 80027cc0 <log>
    80004046:	854a                	mv	a0,s2
    80004048:	ca7fc0ef          	jal	ra,80000cee <acquire>
  if (log.lh.n >= LOGBLOCKS)
    8000404c:	02892603          	lw	a2,40(s2)
    80004050:	47f5                	li	a5,29
    80004052:	04c7cc63          	blt	a5,a2,800040aa <log_write+0x7a>
    panic("too big a transaction");  // 如果日志块数量超过最大值，出错
  if (log.outstanding < 1)
    80004056:	00024797          	auipc	a5,0x24
    8000405a:	c867a783          	lw	a5,-890(a5) # 80027cdc <log+0x1c>
    8000405e:	04f05c63          	blez	a5,800040b6 <log_write+0x86>
    panic("log_write outside of trans");  // 如果在没有事务的情况下调用，出错

  for (i = 0; i < log.lh.n; i++) {
    80004062:	4781                	li	a5,0
    80004064:	04c05f63          	blez	a2,800040c2 <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // 如果块已经存在于日志中，跳过
    80004068:	44cc                	lw	a1,12(s1)
    8000406a:	00024717          	auipc	a4,0x24
    8000406e:	c8270713          	addi	a4,a4,-894 # 80027cec <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80004072:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // 如果块已经存在于日志中，跳过
    80004074:	4314                	lw	a3,0(a4)
    80004076:	04b68663          	beq	a3,a1,800040c2 <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    8000407a:	2785                	addiw	a5,a5,1
    8000407c:	0711                	addi	a4,a4,4
    8000407e:	fef61be3          	bne	a2,a5,80004074 <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;  // 将块号记录到日志中
    80004082:	0621                	addi	a2,a2,8
    80004084:	060a                	slli	a2,a2,0x2
    80004086:	00024797          	auipc	a5,0x24
    8000408a:	c3a78793          	addi	a5,a5,-966 # 80027cc0 <log>
    8000408e:	963e                	add	a2,a2,a5
    80004090:	44dc                	lw	a5,12(s1)
    80004092:	c65c                	sw	a5,12(a2)
  if (i == log.lh.n) {  // 如果是新块，添加到日志
    bpin(b);  // 锁定块
    80004094:	8526                	mv	a0,s1
    80004096:	f19fe0ef          	jal	ra,80002fae <bpin>
    log.lh.n++;  // 增加日志中的块数量
    8000409a:	00024717          	auipc	a4,0x24
    8000409e:	c2670713          	addi	a4,a4,-986 # 80027cc0 <log>
    800040a2:	571c                	lw	a5,40(a4)
    800040a4:	2785                	addiw	a5,a5,1
    800040a6:	d71c                	sw	a5,40(a4)
    800040a8:	a815                	j	800040dc <log_write+0xac>
    panic("too big a transaction");  // 如果日志块数量超过最大值，出错
    800040aa:	00003517          	auipc	a0,0x3
    800040ae:	73650513          	addi	a0,a0,1846 # 800077e0 <syscalls+0x238>
    800040b2:	ed8fc0ef          	jal	ra,8000078a <panic>
    panic("log_write outside of trans");  // 如果在没有事务的情况下调用，出错
    800040b6:	00003517          	auipc	a0,0x3
    800040ba:	74250513          	addi	a0,a0,1858 # 800077f8 <syscalls+0x250>
    800040be:	eccfc0ef          	jal	ra,8000078a <panic>
  log.lh.block[i] = b->blockno;  // 将块号记录到日志中
    800040c2:	00878713          	addi	a4,a5,8
    800040c6:	00271693          	slli	a3,a4,0x2
    800040ca:	00024717          	auipc	a4,0x24
    800040ce:	bf670713          	addi	a4,a4,-1034 # 80027cc0 <log>
    800040d2:	9736                	add	a4,a4,a3
    800040d4:	44d4                	lw	a3,12(s1)
    800040d6:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // 如果是新块，添加到日志
    800040d8:	faf60ee3          	beq	a2,a5,80004094 <log_write+0x64>
  }
  release(&log.lock);  // 释放日志锁
    800040dc:	00024517          	auipc	a0,0x24
    800040e0:	be450513          	addi	a0,a0,-1052 # 80027cc0 <log>
    800040e4:	ca3fc0ef          	jal	ra,80000d86 <release>
}
    800040e8:	60e2                	ld	ra,24(sp)
    800040ea:	6442                	ld	s0,16(sp)
    800040ec:	64a2                	ld	s1,8(sp)
    800040ee:	6902                	ld	s2,0(sp)
    800040f0:	6105                	addi	sp,sp,32
    800040f2:	8082                	ret

00000000800040f4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800040f4:	1101                	addi	sp,sp,-32
    800040f6:	ec06                	sd	ra,24(sp)
    800040f8:	e822                	sd	s0,16(sp)
    800040fa:	e426                	sd	s1,8(sp)
    800040fc:	e04a                	sd	s2,0(sp)
    800040fe:	1000                	addi	s0,sp,32
    80004100:	84aa                	mv	s1,a0
    80004102:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004104:	00003597          	auipc	a1,0x3
    80004108:	71458593          	addi	a1,a1,1812 # 80007818 <syscalls+0x270>
    8000410c:	0521                	addi	a0,a0,8
    8000410e:	b61fc0ef          	jal	ra,80000c6e <initlock>
  lk->name = name;
    80004112:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004116:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000411a:	0204a423          	sw	zero,40(s1)
}
    8000411e:	60e2                	ld	ra,24(sp)
    80004120:	6442                	ld	s0,16(sp)
    80004122:	64a2                	ld	s1,8(sp)
    80004124:	6902                	ld	s2,0(sp)
    80004126:	6105                	addi	sp,sp,32
    80004128:	8082                	ret

000000008000412a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000412a:	1101                	addi	sp,sp,-32
    8000412c:	ec06                	sd	ra,24(sp)
    8000412e:	e822                	sd	s0,16(sp)
    80004130:	e426                	sd	s1,8(sp)
    80004132:	e04a                	sd	s2,0(sp)
    80004134:	1000                	addi	s0,sp,32
    80004136:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004138:	00850913          	addi	s2,a0,8
    8000413c:	854a                	mv	a0,s2
    8000413e:	bb1fc0ef          	jal	ra,80000cee <acquire>
  while (lk->locked) {
    80004142:	409c                	lw	a5,0(s1)
    80004144:	c799                	beqz	a5,80004152 <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80004146:	85ca                	mv	a1,s2
    80004148:	8526                	mv	a0,s1
    8000414a:	ee3fd0ef          	jal	ra,8000202c <sleep>
  while (lk->locked) {
    8000414e:	409c                	lw	a5,0(s1)
    80004150:	fbfd                	bnez	a5,80004146 <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80004152:	4785                	li	a5,1
    80004154:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004156:	8c5fd0ef          	jal	ra,80001a1a <myproc>
    8000415a:	591c                	lw	a5,48(a0)
    8000415c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000415e:	854a                	mv	a0,s2
    80004160:	c27fc0ef          	jal	ra,80000d86 <release>
}
    80004164:	60e2                	ld	ra,24(sp)
    80004166:	6442                	ld	s0,16(sp)
    80004168:	64a2                	ld	s1,8(sp)
    8000416a:	6902                	ld	s2,0(sp)
    8000416c:	6105                	addi	sp,sp,32
    8000416e:	8082                	ret

0000000080004170 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004170:	1101                	addi	sp,sp,-32
    80004172:	ec06                	sd	ra,24(sp)
    80004174:	e822                	sd	s0,16(sp)
    80004176:	e426                	sd	s1,8(sp)
    80004178:	e04a                	sd	s2,0(sp)
    8000417a:	1000                	addi	s0,sp,32
    8000417c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000417e:	00850913          	addi	s2,a0,8
    80004182:	854a                	mv	a0,s2
    80004184:	b6bfc0ef          	jal	ra,80000cee <acquire>
  lk->locked = 0;
    80004188:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000418c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004190:	8526                	mv	a0,s1
    80004192:	ee7fd0ef          	jal	ra,80002078 <wakeup>
  release(&lk->lk);
    80004196:	854a                	mv	a0,s2
    80004198:	beffc0ef          	jal	ra,80000d86 <release>
}
    8000419c:	60e2                	ld	ra,24(sp)
    8000419e:	6442                	ld	s0,16(sp)
    800041a0:	64a2                	ld	s1,8(sp)
    800041a2:	6902                	ld	s2,0(sp)
    800041a4:	6105                	addi	sp,sp,32
    800041a6:	8082                	ret

00000000800041a8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800041a8:	7179                	addi	sp,sp,-48
    800041aa:	f406                	sd	ra,40(sp)
    800041ac:	f022                	sd	s0,32(sp)
    800041ae:	ec26                	sd	s1,24(sp)
    800041b0:	e84a                	sd	s2,16(sp)
    800041b2:	e44e                	sd	s3,8(sp)
    800041b4:	1800                	addi	s0,sp,48
    800041b6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800041b8:	00850913          	addi	s2,a0,8
    800041bc:	854a                	mv	a0,s2
    800041be:	b31fc0ef          	jal	ra,80000cee <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800041c2:	409c                	lw	a5,0(s1)
    800041c4:	ef89                	bnez	a5,800041de <holdingsleep+0x36>
    800041c6:	4481                	li	s1,0
  release(&lk->lk);
    800041c8:	854a                	mv	a0,s2
    800041ca:	bbdfc0ef          	jal	ra,80000d86 <release>
  return r;
}
    800041ce:	8526                	mv	a0,s1
    800041d0:	70a2                	ld	ra,40(sp)
    800041d2:	7402                	ld	s0,32(sp)
    800041d4:	64e2                	ld	s1,24(sp)
    800041d6:	6942                	ld	s2,16(sp)
    800041d8:	69a2                	ld	s3,8(sp)
    800041da:	6145                	addi	sp,sp,48
    800041dc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800041de:	0284a983          	lw	s3,40(s1)
    800041e2:	839fd0ef          	jal	ra,80001a1a <myproc>
    800041e6:	5904                	lw	s1,48(a0)
    800041e8:	413484b3          	sub	s1,s1,s3
    800041ec:	0014b493          	seqz	s1,s1
    800041f0:	bfe1                	j	800041c8 <holdingsleep+0x20>

00000000800041f2 <fileinit>:
} ftable;

// 文件表初始化
void
fileinit(void)
{
    800041f2:	1141                	addi	sp,sp,-16
    800041f4:	e406                	sd	ra,8(sp)
    800041f6:	e022                	sd	s0,0(sp)
    800041f8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");  // 初始化文件表的自旋锁
    800041fa:	00003597          	auipc	a1,0x3
    800041fe:	62e58593          	addi	a1,a1,1582 # 80007828 <syscalls+0x280>
    80004202:	00024517          	auipc	a0,0x24
    80004206:	c0650513          	addi	a0,a0,-1018 # 80027e08 <ftable>
    8000420a:	a65fc0ef          	jal	ra,80000c6e <initlock>
}
    8000420e:	60a2                	ld	ra,8(sp)
    80004210:	6402                	ld	s0,0(sp)
    80004212:	0141                	addi	sp,sp,16
    80004214:	8082                	ret

0000000080004216 <filealloc>:

// 分配一个新的文件结构体
struct file*
filealloc(void)
{
    80004216:	1101                	addi	sp,sp,-32
    80004218:	ec06                	sd	ra,24(sp)
    8000421a:	e822                	sd	s0,16(sp)
    8000421c:	e426                	sd	s1,8(sp)
    8000421e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);  // 获取文件表锁
    80004220:	00024517          	auipc	a0,0x24
    80004224:	be850513          	addi	a0,a0,-1048 # 80027e08 <ftable>
    80004228:	ac7fc0ef          	jal	ra,80000cee <acquire>
  // 遍历文件表，找到引用计数为 0 的文件结构体
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000422c:	00024497          	auipc	s1,0x24
    80004230:	bf448493          	addi	s1,s1,-1036 # 80027e20 <ftable+0x18>
    80004234:	00025717          	auipc	a4,0x25
    80004238:	b8c70713          	addi	a4,a4,-1140 # 80028dc0 <disk>
    if(f->ref == 0){
    8000423c:	40dc                	lw	a5,4(s1)
    8000423e:	cf89                	beqz	a5,80004258 <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004240:	02848493          	addi	s1,s1,40
    80004244:	fee49ce3          	bne	s1,a4,8000423c <filealloc+0x26>
      f->ref = 1;  // 设置引用计数为 1
      release(&ftable.lock);  // 释放文件表锁
      return f;  // 返回分配的文件结构体
    }
  }
  release(&ftable.lock);  // 如果没有空闲文件结构体，释放锁
    80004248:	00024517          	auipc	a0,0x24
    8000424c:	bc050513          	addi	a0,a0,-1088 # 80027e08 <ftable>
    80004250:	b37fc0ef          	jal	ra,80000d86 <release>
  return 0;  // 没有可用的文件结构体
    80004254:	4481                	li	s1,0
    80004256:	a809                	j	80004268 <filealloc+0x52>
      f->ref = 1;  // 设置引用计数为 1
    80004258:	4785                	li	a5,1
    8000425a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);  // 释放文件表锁
    8000425c:	00024517          	auipc	a0,0x24
    80004260:	bac50513          	addi	a0,a0,-1108 # 80027e08 <ftable>
    80004264:	b23fc0ef          	jal	ra,80000d86 <release>
}
    80004268:	8526                	mv	a0,s1
    8000426a:	60e2                	ld	ra,24(sp)
    8000426c:	6442                	ld	s0,16(sp)
    8000426e:	64a2                	ld	s1,8(sp)
    80004270:	6105                	addi	sp,sp,32
    80004272:	8082                	ret

0000000080004274 <filedup>:

// 增加文件结构体的引用计数
struct file*
filedup(struct file *f)
{
    80004274:	1101                	addi	sp,sp,-32
    80004276:	ec06                	sd	ra,24(sp)
    80004278:	e822                	sd	s0,16(sp)
    8000427a:	e426                	sd	s1,8(sp)
    8000427c:	1000                	addi	s0,sp,32
    8000427e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);  // 获取文件表锁
    80004280:	00024517          	auipc	a0,0x24
    80004284:	b8850513          	addi	a0,a0,-1144 # 80027e08 <ftable>
    80004288:	a67fc0ef          	jal	ra,80000cee <acquire>
  if(f->ref < 1)  // 如果引用计数小于 1，说明文件结构体无效
    8000428c:	40dc                	lw	a5,4(s1)
    8000428e:	02f05063          	blez	a5,800042ae <filedup+0x3a>
    panic("filedup");
  f->ref++;  // 增加引用计数
    80004292:	2785                	addiw	a5,a5,1
    80004294:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);  // 释放文件表锁
    80004296:	00024517          	auipc	a0,0x24
    8000429a:	b7250513          	addi	a0,a0,-1166 # 80027e08 <ftable>
    8000429e:	ae9fc0ef          	jal	ra,80000d86 <release>
  return f;  // 返回文件结构体
}
    800042a2:	8526                	mv	a0,s1
    800042a4:	60e2                	ld	ra,24(sp)
    800042a6:	6442                	ld	s0,16(sp)
    800042a8:	64a2                	ld	s1,8(sp)
    800042aa:	6105                	addi	sp,sp,32
    800042ac:	8082                	ret
    panic("filedup");
    800042ae:	00003517          	auipc	a0,0x3
    800042b2:	58250513          	addi	a0,a0,1410 # 80007830 <syscalls+0x288>
    800042b6:	cd4fc0ef          	jal	ra,8000078a <panic>

00000000800042ba <fileclose>:

// 关闭文件结构体 f，减少引用计数，当引用计数为 0 时关闭文件
void
fileclose(struct file *f)
{
    800042ba:	7139                	addi	sp,sp,-64
    800042bc:	fc06                	sd	ra,56(sp)
    800042be:	f822                	sd	s0,48(sp)
    800042c0:	f426                	sd	s1,40(sp)
    800042c2:	f04a                	sd	s2,32(sp)
    800042c4:	ec4e                	sd	s3,24(sp)
    800042c6:	e852                	sd	s4,16(sp)
    800042c8:	e456                	sd	s5,8(sp)
    800042ca:	0080                	addi	s0,sp,64
    800042cc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);  // 获取文件表锁
    800042ce:	00024517          	auipc	a0,0x24
    800042d2:	b3a50513          	addi	a0,a0,-1222 # 80027e08 <ftable>
    800042d6:	a19fc0ef          	jal	ra,80000cee <acquire>
  if(f->ref < 1)  // 如果引用计数小于 1，说明文件结构体无效
    800042da:	40dc                	lw	a5,4(s1)
    800042dc:	04f05963          	blez	a5,8000432e <fileclose+0x74>
    panic("fileclose");
  if(--f->ref > 0){  // 如果引用计数大于 0，直接返回
    800042e0:	37fd                	addiw	a5,a5,-1
    800042e2:	0007871b          	sext.w	a4,a5
    800042e6:	c0dc                	sw	a5,4(s1)
    800042e8:	04e04963          	bgtz	a4,8000433a <fileclose+0x80>
    release(&ftable.lock);
    return;
  }
  ff = *f;  // 备份文件结构体
    800042ec:	0004a903          	lw	s2,0(s1)
    800042f0:	0094ca83          	lbu	s5,9(s1)
    800042f4:	0104ba03          	ld	s4,16(s1)
    800042f8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;  // 重置引用计数
    800042fc:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;  // 重置文件类型
    80004300:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);  // 释放文件表锁
    80004304:	00024517          	auipc	a0,0x24
    80004308:	b0450513          	addi	a0,a0,-1276 # 80027e08 <ftable>
    8000430c:	a7bfc0ef          	jal	ra,80000d86 <release>

  // 如果文件类型是管道（pipe），则关闭管道
  if(ff.type == FD_PIPE){
    80004310:	4785                	li	a5,1
    80004312:	04f90363          	beq	s2,a5,80004358 <fileclose+0x9e>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004316:	3979                	addiw	s2,s2,-2
    80004318:	4785                	li	a5,1
    8000431a:	0327e663          	bltu	a5,s2,80004346 <fileclose+0x8c>
    begin_op();  // 开始一个文件系统操作
    8000431e:	b8fff0ef          	jal	ra,80003eac <begin_op>
    iput(ff.ip);  // 释放 inode
    80004322:	854e                	mv	a0,s3
    80004324:	b28ff0ef          	jal	ra,8000364c <iput>
    end_op();  // 结束文件系统操作
    80004328:	bf5ff0ef          	jal	ra,80003f1c <end_op>
    8000432c:	a829                	j	80004346 <fileclose+0x8c>
    panic("fileclose");
    8000432e:	00003517          	auipc	a0,0x3
    80004332:	50a50513          	addi	a0,a0,1290 # 80007838 <syscalls+0x290>
    80004336:	c54fc0ef          	jal	ra,8000078a <panic>
    release(&ftable.lock);
    8000433a:	00024517          	auipc	a0,0x24
    8000433e:	ace50513          	addi	a0,a0,-1330 # 80027e08 <ftable>
    80004342:	a45fc0ef          	jal	ra,80000d86 <release>
  }
}
    80004346:	70e2                	ld	ra,56(sp)
    80004348:	7442                	ld	s0,48(sp)
    8000434a:	74a2                	ld	s1,40(sp)
    8000434c:	7902                	ld	s2,32(sp)
    8000434e:	69e2                	ld	s3,24(sp)
    80004350:	6a42                	ld	s4,16(sp)
    80004352:	6aa2                	ld	s5,8(sp)
    80004354:	6121                	addi	sp,sp,64
    80004356:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004358:	85d6                	mv	a1,s5
    8000435a:	8552                	mv	a0,s4
    8000435c:	2ec000ef          	jal	ra,80004648 <pipeclose>
    80004360:	b7dd                	j	80004346 <fileclose+0x8c>

0000000080004362 <filestat>:

// 获取文件 f 的元数据（如文件大小、类型等）
// addr 是一个用户虚拟地址，指向 struct stat 结构
int
filestat(struct file *f, uint64 addr)
{
    80004362:	715d                	addi	sp,sp,-80
    80004364:	e486                	sd	ra,72(sp)
    80004366:	e0a2                	sd	s0,64(sp)
    80004368:	fc26                	sd	s1,56(sp)
    8000436a:	f84a                	sd	s2,48(sp)
    8000436c:	f44e                	sd	s3,40(sp)
    8000436e:	0880                	addi	s0,sp,80
    80004370:	84aa                	mv	s1,a0
    80004372:	89ae                	mv	s3,a1
  struct proc *p = myproc();  // 获取当前进程
    80004374:	ea6fd0ef          	jal	ra,80001a1a <myproc>
  struct stat st;
  
  // 如果文件是 inode 类型或设备类型
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004378:	409c                	lw	a5,0(s1)
    8000437a:	37f9                	addiw	a5,a5,-2
    8000437c:	4705                	li	a4,1
    8000437e:	02f76f63          	bltu	a4,a5,800043bc <filestat+0x5a>
    80004382:	892a                	mv	s2,a0
    ilock(f->ip);  // 锁定 inode
    80004384:	6c88                	ld	a0,24(s1)
    80004386:	948ff0ef          	jal	ra,800034ce <ilock>
    stati(f->ip, &st);  // 获取 inode 的元数据
    8000438a:	fb840593          	addi	a1,s0,-72
    8000438e:	6c88                	ld	a0,24(s1)
    80004390:	ca0ff0ef          	jal	ra,80003830 <stati>
    iunlock(f->ip);  // 解锁 inode
    80004394:	6c88                	ld	a0,24(s1)
    80004396:	9e2ff0ef          	jal	ra,80003578 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)  // 将元数据复制到用户地址
    8000439a:	46e1                	li	a3,24
    8000439c:	fb840613          	addi	a2,s0,-72
    800043a0:	85ce                	mv	a1,s3
    800043a2:	05093503          	ld	a0,80(s2)
    800043a6:	b56fd0ef          	jal	ra,800016fc <copyout>
    800043aa:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;  // 其他类型文件不支持
}
    800043ae:	60a6                	ld	ra,72(sp)
    800043b0:	6406                	ld	s0,64(sp)
    800043b2:	74e2                	ld	s1,56(sp)
    800043b4:	7942                	ld	s2,48(sp)
    800043b6:	79a2                	ld	s3,40(sp)
    800043b8:	6161                	addi	sp,sp,80
    800043ba:	8082                	ret
  return -1;  // 其他类型文件不支持
    800043bc:	557d                	li	a0,-1
    800043be:	bfc5                	j	800043ae <filestat+0x4c>

00000000800043c0 <fileread>:

// 从文件 f 中读取数据。
// addr 是一个用户虚拟地址。
int
fileread(struct file *f, uint64 addr, int n)
{
    800043c0:	7179                	addi	sp,sp,-48
    800043c2:	f406                	sd	ra,40(sp)
    800043c4:	f022                	sd	s0,32(sp)
    800043c6:	ec26                	sd	s1,24(sp)
    800043c8:	e84a                	sd	s2,16(sp)
    800043ca:	e44e                	sd	s3,8(sp)
    800043cc:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)  // 如果文件不可读，返回 -1
    800043ce:	00854783          	lbu	a5,8(a0)
    800043d2:	cbc1                	beqz	a5,80004462 <fileread+0xa2>
    800043d4:	84aa                	mv	s1,a0
    800043d6:	89ae                	mv	s3,a1
    800043d8:	8932                	mv	s2,a2
    return -1;

  // 根据文件类型执行不同的读取操作
  if(f->type == FD_PIPE){
    800043da:	411c                	lw	a5,0(a0)
    800043dc:	4705                	li	a4,1
    800043de:	04e78363          	beq	a5,a4,80004424 <fileread+0x64>
    r = piperead(f->pipe, addr, n);  // 从管道中读取
  } else if(f->type == FD_DEVICE){
    800043e2:	470d                	li	a4,3
    800043e4:	04e78563          	beq	a5,a4,8000442e <fileread+0x6e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)  // 如果设备不支持读取，返回 -1
      return -1;
    r = devsw[f->major].read(1, addr, n);  // 调用设备的读取函数
  } else if(f->type == FD_INODE){
    800043e8:	4709                	li	a4,2
    800043ea:	06e79663          	bne	a5,a4,80004456 <fileread+0x96>
    ilock(f->ip);  // 锁定 inode
    800043ee:	6d08                	ld	a0,24(a0)
    800043f0:	8deff0ef          	jal	ra,800034ce <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)  // 从 inode 中读取数据
    800043f4:	874a                	mv	a4,s2
    800043f6:	5094                	lw	a3,32(s1)
    800043f8:	864e                	mv	a2,s3
    800043fa:	4585                	li	a1,1
    800043fc:	6c88                	ld	a0,24(s1)
    800043fe:	c5cff0ef          	jal	ra,8000385a <readi>
    80004402:	892a                	mv	s2,a0
    80004404:	00a05563          	blez	a0,8000440e <fileread+0x4e>
      f->off += r;  // 更新文件偏移量
    80004408:	509c                	lw	a5,32(s1)
    8000440a:	9fa9                	addw	a5,a5,a0
    8000440c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);  // 解锁 inode
    8000440e:	6c88                	ld	a0,24(s1)
    80004410:	968ff0ef          	jal	ra,80003578 <iunlock>
  } else {
    panic("fileread");  // 不支持的文件类型
  }

  return r;  // 返回读取的字节数
}
    80004414:	854a                	mv	a0,s2
    80004416:	70a2                	ld	ra,40(sp)
    80004418:	7402                	ld	s0,32(sp)
    8000441a:	64e2                	ld	s1,24(sp)
    8000441c:	6942                	ld	s2,16(sp)
    8000441e:	69a2                	ld	s3,8(sp)
    80004420:	6145                	addi	sp,sp,48
    80004422:	8082                	ret
    r = piperead(f->pipe, addr, n);  // 从管道中读取
    80004424:	6908                	ld	a0,16(a0)
    80004426:	34e000ef          	jal	ra,80004774 <piperead>
    8000442a:	892a                	mv	s2,a0
    8000442c:	b7e5                	j	80004414 <fileread+0x54>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)  // 如果设备不支持读取，返回 -1
    8000442e:	02451783          	lh	a5,36(a0)
    80004432:	03079693          	slli	a3,a5,0x30
    80004436:	92c1                	srli	a3,a3,0x30
    80004438:	4725                	li	a4,9
    8000443a:	02d76663          	bltu	a4,a3,80004466 <fileread+0xa6>
    8000443e:	0792                	slli	a5,a5,0x4
    80004440:	00024717          	auipc	a4,0x24
    80004444:	92870713          	addi	a4,a4,-1752 # 80027d68 <devsw>
    80004448:	97ba                	add	a5,a5,a4
    8000444a:	639c                	ld	a5,0(a5)
    8000444c:	cf99                	beqz	a5,8000446a <fileread+0xaa>
    r = devsw[f->major].read(1, addr, n);  // 调用设备的读取函数
    8000444e:	4505                	li	a0,1
    80004450:	9782                	jalr	a5
    80004452:	892a                	mv	s2,a0
    80004454:	b7c1                	j	80004414 <fileread+0x54>
    panic("fileread");  // 不支持的文件类型
    80004456:	00003517          	auipc	a0,0x3
    8000445a:	3f250513          	addi	a0,a0,1010 # 80007848 <syscalls+0x2a0>
    8000445e:	b2cfc0ef          	jal	ra,8000078a <panic>
    return -1;
    80004462:	597d                	li	s2,-1
    80004464:	bf45                	j	80004414 <fileread+0x54>
      return -1;
    80004466:	597d                	li	s2,-1
    80004468:	b775                	j	80004414 <fileread+0x54>
    8000446a:	597d                	li	s2,-1
    8000446c:	b765                	j	80004414 <fileread+0x54>

000000008000446e <filewrite>:

// 向文件 f 中写入数据。
// addr 是一个用户虚拟地址。
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000446e:	715d                	addi	sp,sp,-80
    80004470:	e486                	sd	ra,72(sp)
    80004472:	e0a2                	sd	s0,64(sp)
    80004474:	fc26                	sd	s1,56(sp)
    80004476:	f84a                	sd	s2,48(sp)
    80004478:	f44e                	sd	s3,40(sp)
    8000447a:	f052                	sd	s4,32(sp)
    8000447c:	ec56                	sd	s5,24(sp)
    8000447e:	e85a                	sd	s6,16(sp)
    80004480:	e45e                	sd	s7,8(sp)
    80004482:	e062                	sd	s8,0(sp)
    80004484:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)  // 如果文件不可写，返回 -1
    80004486:	00954783          	lbu	a5,9(a0)
    8000448a:	0e078863          	beqz	a5,8000457a <filewrite+0x10c>
    8000448e:	892a                	mv	s2,a0
    80004490:	8aae                	mv	s5,a1
    80004492:	8a32                	mv	s4,a2
    return -1;

  // 根据文件类型执行不同的写入操作
  if(f->type == FD_PIPE){
    80004494:	411c                	lw	a5,0(a0)
    80004496:	4705                	li	a4,1
    80004498:	02e78263          	beq	a5,a4,800044bc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);  // 向管道中写入
  } else if(f->type == FD_DEVICE){
    8000449c:	470d                	li	a4,3
    8000449e:	02e78463          	beq	a5,a4,800044c6 <filewrite+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)  // 如果设备不支持写入，返回 -1
      return -1;
    ret = devsw[f->major].write(1, addr, n);  // 调用设备的写入函数
  } else if(f->type == FD_INODE){
    800044a2:	4709                	li	a4,2
    800044a4:	0ce79563          	bne	a5,a4,8000456e <filewrite+0x100>
    // 分多次写入，以避免超过最大日志事务大小，包括 inode、间接块、分配块等
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800044a8:	0ac05163          	blez	a2,8000454a <filewrite+0xdc>
    int i = 0;
    800044ac:	4981                	li	s3,0
    800044ae:	6b05                	lui	s6,0x1
    800044b0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800044b4:	6b85                	lui	s7,0x1
    800044b6:	c00b8b9b          	addiw	s7,s7,-1024
    800044ba:	a041                	j	8000453a <filewrite+0xcc>
    ret = pipewrite(f->pipe, addr, n);  // 向管道中写入
    800044bc:	6908                	ld	a0,16(a0)
    800044be:	1e2000ef          	jal	ra,800046a0 <pipewrite>
    800044c2:	8a2a                	mv	s4,a0
    800044c4:	a071                	j	80004550 <filewrite+0xe2>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)  // 如果设备不支持写入，返回 -1
    800044c6:	02451783          	lh	a5,36(a0)
    800044ca:	03079693          	slli	a3,a5,0x30
    800044ce:	92c1                	srli	a3,a3,0x30
    800044d0:	4725                	li	a4,9
    800044d2:	0ad76663          	bltu	a4,a3,8000457e <filewrite+0x110>
    800044d6:	0792                	slli	a5,a5,0x4
    800044d8:	00024717          	auipc	a4,0x24
    800044dc:	89070713          	addi	a4,a4,-1904 # 80027d68 <devsw>
    800044e0:	97ba                	add	a5,a5,a4
    800044e2:	679c                	ld	a5,8(a5)
    800044e4:	cfd9                	beqz	a5,80004582 <filewrite+0x114>
    ret = devsw[f->major].write(1, addr, n);  // 调用设备的写入函数
    800044e6:	4505                	li	a0,1
    800044e8:	9782                	jalr	a5
    800044ea:	8a2a                	mv	s4,a0
    800044ec:	a095                	j	80004550 <filewrite+0xe2>
    800044ee:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)  // 如果写入数据超过最大限制，分批次写入
        n1 = max;

      begin_op();  // 开始一个文件系统操作
    800044f2:	9bbff0ef          	jal	ra,80003eac <begin_op>
      ilock(f->ip);  // 锁定 inode
    800044f6:	01893503          	ld	a0,24(s2)
    800044fa:	fd5fe0ef          	jal	ra,800034ce <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800044fe:	8762                	mv	a4,s8
    80004500:	02092683          	lw	a3,32(s2)
    80004504:	01598633          	add	a2,s3,s5
    80004508:	4585                	li	a1,1
    8000450a:	01893503          	ld	a0,24(s2)
    8000450e:	c30ff0ef          	jal	ra,8000393e <writei>
    80004512:	84aa                	mv	s1,a0
    80004514:	00a05763          	blez	a0,80004522 <filewrite+0xb4>
        f->off += r;  // 更新文件偏移量
    80004518:	02092783          	lw	a5,32(s2)
    8000451c:	9fa9                	addw	a5,a5,a0
    8000451e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);  // 解锁 inode
    80004522:	01893503          	ld	a0,24(s2)
    80004526:	852ff0ef          	jal	ra,80003578 <iunlock>
      end_op();  // 结束文件系统操作
    8000452a:	9f3ff0ef          	jal	ra,80003f1c <end_op>

      if(r != n1){  // 如果写入不完全，退出
    8000452e:	009c1f63          	bne	s8,s1,8000454c <filewrite+0xde>
        break;
      }
      i += r;
    80004532:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004536:	0149db63          	bge	s3,s4,8000454c <filewrite+0xde>
      int n1 = n - i;
    8000453a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)  // 如果写入数据超过最大限制，分批次写入
    8000453e:	84be                	mv	s1,a5
    80004540:	2781                	sext.w	a5,a5
    80004542:	fafb56e3          	bge	s6,a5,800044ee <filewrite+0x80>
    80004546:	84de                	mv	s1,s7
    80004548:	b75d                	j	800044ee <filewrite+0x80>
    int i = 0;
    8000454a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);  // 如果写入完全成功，返回写入字节数，否则返回 -1
    8000454c:	013a1f63          	bne	s4,s3,8000456a <filewrite+0xfc>
  } else {
    panic("filewrite");  // 不支持的文件类型
  }

  return ret;  // 返回写入的字节数
}
    80004550:	8552                	mv	a0,s4
    80004552:	60a6                	ld	ra,72(sp)
    80004554:	6406                	ld	s0,64(sp)
    80004556:	74e2                	ld	s1,56(sp)
    80004558:	7942                	ld	s2,48(sp)
    8000455a:	79a2                	ld	s3,40(sp)
    8000455c:	7a02                	ld	s4,32(sp)
    8000455e:	6ae2                	ld	s5,24(sp)
    80004560:	6b42                	ld	s6,16(sp)
    80004562:	6ba2                	ld	s7,8(sp)
    80004564:	6c02                	ld	s8,0(sp)
    80004566:	6161                	addi	sp,sp,80
    80004568:	8082                	ret
    ret = (i == n ? n : -1);  // 如果写入完全成功，返回写入字节数，否则返回 -1
    8000456a:	5a7d                	li	s4,-1
    8000456c:	b7d5                	j	80004550 <filewrite+0xe2>
    panic("filewrite");  // 不支持的文件类型
    8000456e:	00003517          	auipc	a0,0x3
    80004572:	2ea50513          	addi	a0,a0,746 # 80007858 <syscalls+0x2b0>
    80004576:	a14fc0ef          	jal	ra,8000078a <panic>
    return -1;
    8000457a:	5a7d                	li	s4,-1
    8000457c:	bfd1                	j	80004550 <filewrite+0xe2>
      return -1;
    8000457e:	5a7d                	li	s4,-1
    80004580:	bfc1                	j	80004550 <filewrite+0xe2>
    80004582:	5a7d                	li	s4,-1
    80004584:	b7f1                	j	80004550 <filewrite+0xe2>

0000000080004586 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004586:	7179                	addi	sp,sp,-48
    80004588:	f406                	sd	ra,40(sp)
    8000458a:	f022                	sd	s0,32(sp)
    8000458c:	ec26                	sd	s1,24(sp)
    8000458e:	e84a                	sd	s2,16(sp)
    80004590:	e44e                	sd	s3,8(sp)
    80004592:	e052                	sd	s4,0(sp)
    80004594:	1800                	addi	s0,sp,48
    80004596:	84aa                	mv	s1,a0
    80004598:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000459a:	0005b023          	sd	zero,0(a1)
    8000459e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800045a2:	c75ff0ef          	jal	ra,80004216 <filealloc>
    800045a6:	e088                	sd	a0,0(s1)
    800045a8:	cd35                	beqz	a0,80004624 <pipealloc+0x9e>
    800045aa:	c6dff0ef          	jal	ra,80004216 <filealloc>
    800045ae:	00aa3023          	sd	a0,0(s4)
    800045b2:	c52d                	beqz	a0,8000461c <pipealloc+0x96>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800045b4:	e3afc0ef          	jal	ra,80000bee <kalloc>
    800045b8:	892a                	mv	s2,a0
    800045ba:	cd31                	beqz	a0,80004616 <pipealloc+0x90>
    goto bad;
  pi->readopen = 1;
    800045bc:	4985                	li	s3,1
    800045be:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800045c2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800045c6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800045ca:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800045ce:	00003597          	auipc	a1,0x3
    800045d2:	29a58593          	addi	a1,a1,666 # 80007868 <syscalls+0x2c0>
    800045d6:	e98fc0ef          	jal	ra,80000c6e <initlock>
  (*f0)->type = FD_PIPE;
    800045da:	609c                	ld	a5,0(s1)
    800045dc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800045e0:	609c                	ld	a5,0(s1)
    800045e2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800045e6:	609c                	ld	a5,0(s1)
    800045e8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800045ec:	609c                	ld	a5,0(s1)
    800045ee:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800045f2:	000a3783          	ld	a5,0(s4)
    800045f6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800045fa:	000a3783          	ld	a5,0(s4)
    800045fe:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004602:	000a3783          	ld	a5,0(s4)
    80004606:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000460a:	000a3783          	ld	a5,0(s4)
    8000460e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004612:	4501                	li	a0,0
    80004614:	a005                	j	80004634 <pipealloc+0xae>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004616:	6088                	ld	a0,0(s1)
    80004618:	e501                	bnez	a0,80004620 <pipealloc+0x9a>
    8000461a:	a029                	j	80004624 <pipealloc+0x9e>
    8000461c:	6088                	ld	a0,0(s1)
    8000461e:	c11d                	beqz	a0,80004644 <pipealloc+0xbe>
    fileclose(*f0);
    80004620:	c9bff0ef          	jal	ra,800042ba <fileclose>
  if(*f1)
    80004624:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004628:	557d                	li	a0,-1
  if(*f1)
    8000462a:	c789                	beqz	a5,80004634 <pipealloc+0xae>
    fileclose(*f1);
    8000462c:	853e                	mv	a0,a5
    8000462e:	c8dff0ef          	jal	ra,800042ba <fileclose>
  return -1;
    80004632:	557d                	li	a0,-1
}
    80004634:	70a2                	ld	ra,40(sp)
    80004636:	7402                	ld	s0,32(sp)
    80004638:	64e2                	ld	s1,24(sp)
    8000463a:	6942                	ld	s2,16(sp)
    8000463c:	69a2                	ld	s3,8(sp)
    8000463e:	6a02                	ld	s4,0(sp)
    80004640:	6145                	addi	sp,sp,48
    80004642:	8082                	ret
  return -1;
    80004644:	557d                	li	a0,-1
    80004646:	b7fd                	j	80004634 <pipealloc+0xae>

0000000080004648 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004648:	1101                	addi	sp,sp,-32
    8000464a:	ec06                	sd	ra,24(sp)
    8000464c:	e822                	sd	s0,16(sp)
    8000464e:	e426                	sd	s1,8(sp)
    80004650:	e04a                	sd	s2,0(sp)
    80004652:	1000                	addi	s0,sp,32
    80004654:	84aa                	mv	s1,a0
    80004656:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004658:	e96fc0ef          	jal	ra,80000cee <acquire>
  if(writable){
    8000465c:	02090763          	beqz	s2,8000468a <pipeclose+0x42>
    pi->writeopen = 0;
    80004660:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004664:	21848513          	addi	a0,s1,536
    80004668:	a11fd0ef          	jal	ra,80002078 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000466c:	2204b783          	ld	a5,544(s1)
    80004670:	e785                	bnez	a5,80004698 <pipeclose+0x50>
    release(&pi->lock);
    80004672:	8526                	mv	a0,s1
    80004674:	f12fc0ef          	jal	ra,80000d86 <release>
    kfree((char*)pi);
    80004678:	8526                	mv	a0,s1
    8000467a:	c2efc0ef          	jal	ra,80000aa8 <kfree>
  } else
    release(&pi->lock);
}
    8000467e:	60e2                	ld	ra,24(sp)
    80004680:	6442                	ld	s0,16(sp)
    80004682:	64a2                	ld	s1,8(sp)
    80004684:	6902                	ld	s2,0(sp)
    80004686:	6105                	addi	sp,sp,32
    80004688:	8082                	ret
    pi->readopen = 0;
    8000468a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000468e:	21c48513          	addi	a0,s1,540
    80004692:	9e7fd0ef          	jal	ra,80002078 <wakeup>
    80004696:	bfd9                	j	8000466c <pipeclose+0x24>
    release(&pi->lock);
    80004698:	8526                	mv	a0,s1
    8000469a:	eecfc0ef          	jal	ra,80000d86 <release>
}
    8000469e:	b7c5                	j	8000467e <pipeclose+0x36>

00000000800046a0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800046a0:	711d                	addi	sp,sp,-96
    800046a2:	ec86                	sd	ra,88(sp)
    800046a4:	e8a2                	sd	s0,80(sp)
    800046a6:	e4a6                	sd	s1,72(sp)
    800046a8:	e0ca                	sd	s2,64(sp)
    800046aa:	fc4e                	sd	s3,56(sp)
    800046ac:	f852                	sd	s4,48(sp)
    800046ae:	f456                	sd	s5,40(sp)
    800046b0:	f05a                	sd	s6,32(sp)
    800046b2:	ec5e                	sd	s7,24(sp)
    800046b4:	e862                	sd	s8,16(sp)
    800046b6:	1080                	addi	s0,sp,96
    800046b8:	84aa                	mv	s1,a0
    800046ba:	8aae                	mv	s5,a1
    800046bc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800046be:	b5cfd0ef          	jal	ra,80001a1a <myproc>
    800046c2:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800046c4:	8526                	mv	a0,s1
    800046c6:	e28fc0ef          	jal	ra,80000cee <acquire>
  while(i < n){
    800046ca:	09405c63          	blez	s4,80004762 <pipewrite+0xc2>
  int i = 0;
    800046ce:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800046d0:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800046d2:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800046d6:	21c48b93          	addi	s7,s1,540
    800046da:	a81d                	j	80004710 <pipewrite+0x70>
      release(&pi->lock);
    800046dc:	8526                	mv	a0,s1
    800046de:	ea8fc0ef          	jal	ra,80000d86 <release>
      return -1;
    800046e2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800046e4:	854a                	mv	a0,s2
    800046e6:	60e6                	ld	ra,88(sp)
    800046e8:	6446                	ld	s0,80(sp)
    800046ea:	64a6                	ld	s1,72(sp)
    800046ec:	6906                	ld	s2,64(sp)
    800046ee:	79e2                	ld	s3,56(sp)
    800046f0:	7a42                	ld	s4,48(sp)
    800046f2:	7aa2                	ld	s5,40(sp)
    800046f4:	7b02                	ld	s6,32(sp)
    800046f6:	6be2                	ld	s7,24(sp)
    800046f8:	6c42                	ld	s8,16(sp)
    800046fa:	6125                	addi	sp,sp,96
    800046fc:	8082                	ret
      wakeup(&pi->nread);
    800046fe:	8562                	mv	a0,s8
    80004700:	979fd0ef          	jal	ra,80002078 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004704:	85a6                	mv	a1,s1
    80004706:	855e                	mv	a0,s7
    80004708:	925fd0ef          	jal	ra,8000202c <sleep>
  while(i < n){
    8000470c:	05495c63          	bge	s2,s4,80004764 <pipewrite+0xc4>
    if(pi->readopen == 0 || killed(pr)){
    80004710:	2204a783          	lw	a5,544(s1)
    80004714:	d7e1                	beqz	a5,800046dc <pipewrite+0x3c>
    80004716:	854e                	mv	a0,s3
    80004718:	b4dfd0ef          	jal	ra,80002264 <killed>
    8000471c:	f161                	bnez	a0,800046dc <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000471e:	2184a783          	lw	a5,536(s1)
    80004722:	21c4a703          	lw	a4,540(s1)
    80004726:	2007879b          	addiw	a5,a5,512
    8000472a:	fcf70ae3          	beq	a4,a5,800046fe <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000472e:	4685                	li	a3,1
    80004730:	01590633          	add	a2,s2,s5
    80004734:	faf40593          	addi	a1,s0,-81
    80004738:	0509b503          	ld	a0,80(s3)
    8000473c:	8f2fd0ef          	jal	ra,8000182e <copyin>
    80004740:	03650263          	beq	a0,s6,80004764 <pipewrite+0xc4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004744:	21c4a783          	lw	a5,540(s1)
    80004748:	0017871b          	addiw	a4,a5,1
    8000474c:	20e4ae23          	sw	a4,540(s1)
    80004750:	1ff7f793          	andi	a5,a5,511
    80004754:	97a6                	add	a5,a5,s1
    80004756:	faf44703          	lbu	a4,-81(s0)
    8000475a:	00e78c23          	sb	a4,24(a5)
      i++;
    8000475e:	2905                	addiw	s2,s2,1
    80004760:	b775                	j	8000470c <pipewrite+0x6c>
  int i = 0;
    80004762:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004764:	21848513          	addi	a0,s1,536
    80004768:	911fd0ef          	jal	ra,80002078 <wakeup>
  release(&pi->lock);
    8000476c:	8526                	mv	a0,s1
    8000476e:	e18fc0ef          	jal	ra,80000d86 <release>
  return i;
    80004772:	bf8d                	j	800046e4 <pipewrite+0x44>

0000000080004774 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004774:	715d                	addi	sp,sp,-80
    80004776:	e486                	sd	ra,72(sp)
    80004778:	e0a2                	sd	s0,64(sp)
    8000477a:	fc26                	sd	s1,56(sp)
    8000477c:	f84a                	sd	s2,48(sp)
    8000477e:	f44e                	sd	s3,40(sp)
    80004780:	f052                	sd	s4,32(sp)
    80004782:	ec56                	sd	s5,24(sp)
    80004784:	e85a                	sd	s6,16(sp)
    80004786:	0880                	addi	s0,sp,80
    80004788:	84aa                	mv	s1,a0
    8000478a:	892e                	mv	s2,a1
    8000478c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000478e:	a8cfd0ef          	jal	ra,80001a1a <myproc>
    80004792:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004794:	8526                	mv	a0,s1
    80004796:	d58fc0ef          	jal	ra,80000cee <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000479a:	2184a703          	lw	a4,536(s1)
    8000479e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800047a2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800047a6:	02f71363          	bne	a4,a5,800047cc <piperead+0x58>
    800047aa:	2244a783          	lw	a5,548(s1)
    800047ae:	cf99                	beqz	a5,800047cc <piperead+0x58>
    if(killed(pr)){
    800047b0:	8552                	mv	a0,s4
    800047b2:	ab3fd0ef          	jal	ra,80002264 <killed>
    800047b6:	e149                	bnez	a0,80004838 <piperead+0xc4>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800047b8:	85a6                	mv	a1,s1
    800047ba:	854e                	mv	a0,s3
    800047bc:	871fd0ef          	jal	ra,8000202c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800047c0:	2184a703          	lw	a4,536(s1)
    800047c4:	21c4a783          	lw	a5,540(s1)
    800047c8:	fef701e3          	beq	a4,a5,800047aa <piperead+0x36>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800047cc:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800047ce:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800047d0:	05505263          	blez	s5,80004814 <piperead+0xa0>
    if(pi->nread == pi->nwrite)
    800047d4:	2184a783          	lw	a5,536(s1)
    800047d8:	21c4a703          	lw	a4,540(s1)
    800047dc:	02f70c63          	beq	a4,a5,80004814 <piperead+0xa0>
    ch = pi->data[pi->nread % PIPESIZE];
    800047e0:	1ff7f793          	andi	a5,a5,511
    800047e4:	97a6                	add	a5,a5,s1
    800047e6:	0187c783          	lbu	a5,24(a5)
    800047ea:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800047ee:	4685                	li	a3,1
    800047f0:	fbf40613          	addi	a2,s0,-65
    800047f4:	85ca                	mv	a1,s2
    800047f6:	050a3503          	ld	a0,80(s4)
    800047fa:	f03fc0ef          	jal	ra,800016fc <copyout>
    800047fe:	05650263          	beq	a0,s6,80004842 <piperead+0xce>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    80004802:	2184a783          	lw	a5,536(s1)
    80004806:	2785                	addiw	a5,a5,1
    80004808:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000480c:	2985                	addiw	s3,s3,1
    8000480e:	0905                	addi	s2,s2,1
    80004810:	fd3a92e3          	bne	s5,s3,800047d4 <piperead+0x60>
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004814:	21c48513          	addi	a0,s1,540
    80004818:	861fd0ef          	jal	ra,80002078 <wakeup>
  release(&pi->lock);
    8000481c:	8526                	mv	a0,s1
    8000481e:	d68fc0ef          	jal	ra,80000d86 <release>
  return i;
}
    80004822:	854e                	mv	a0,s3
    80004824:	60a6                	ld	ra,72(sp)
    80004826:	6406                	ld	s0,64(sp)
    80004828:	74e2                	ld	s1,56(sp)
    8000482a:	7942                	ld	s2,48(sp)
    8000482c:	79a2                	ld	s3,40(sp)
    8000482e:	7a02                	ld	s4,32(sp)
    80004830:	6ae2                	ld	s5,24(sp)
    80004832:	6b42                	ld	s6,16(sp)
    80004834:	6161                	addi	sp,sp,80
    80004836:	8082                	ret
      release(&pi->lock);
    80004838:	8526                	mv	a0,s1
    8000483a:	d4cfc0ef          	jal	ra,80000d86 <release>
      return -1;
    8000483e:	59fd                	li	s3,-1
    80004840:	b7cd                	j	80004822 <piperead+0xae>
      if(i == 0)
    80004842:	fc0999e3          	bnez	s3,80004814 <piperead+0xa0>
        i = -1;
    80004846:	89aa                	mv	s3,a0
    80004848:	b7f1                	j	80004814 <piperead+0xa0>

000000008000484a <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    8000484a:	1141                	addi	sp,sp,-16
    8000484c:	e422                	sd	s0,8(sp)
    8000484e:	0800                	addi	s0,sp,16
    80004850:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004852:	8905                	andi	a0,a0,1
    80004854:	c111                	beqz	a0,80004858 <flags2perm+0xe>
      perm = PTE_X;
    80004856:	4521                	li	a0,8
    if(flags & 0x2)
    80004858:	8b89                	andi	a5,a5,2
    8000485a:	c399                	beqz	a5,80004860 <flags2perm+0x16>
      perm |= PTE_W;
    8000485c:	00456513          	ori	a0,a0,4
    return perm;
}
    80004860:	6422                	ld	s0,8(sp)
    80004862:	0141                	addi	sp,sp,16
    80004864:	8082                	ret

0000000080004866 <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    80004866:	de010113          	addi	sp,sp,-544
    8000486a:	20113c23          	sd	ra,536(sp)
    8000486e:	20813823          	sd	s0,528(sp)
    80004872:	20913423          	sd	s1,520(sp)
    80004876:	21213023          	sd	s2,512(sp)
    8000487a:	ffce                	sd	s3,504(sp)
    8000487c:	fbd2                	sd	s4,496(sp)
    8000487e:	f7d6                	sd	s5,488(sp)
    80004880:	f3da                	sd	s6,480(sp)
    80004882:	efde                	sd	s7,472(sp)
    80004884:	ebe2                	sd	s8,464(sp)
    80004886:	e7e6                	sd	s9,456(sp)
    80004888:	e3ea                	sd	s10,448(sp)
    8000488a:	ff6e                	sd	s11,440(sp)
    8000488c:	1400                	addi	s0,sp,544
    8000488e:	892a                	mv	s2,a0
    80004890:	dea43423          	sd	a0,-536(s0)
    80004894:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004898:	982fd0ef          	jal	ra,80001a1a <myproc>
    8000489c:	84aa                	mv	s1,a0

  begin_op();
    8000489e:	e0eff0ef          	jal	ra,80003eac <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    800048a2:	854a                	mv	a0,s2
    800048a4:	c18ff0ef          	jal	ra,80003cbc <namei>
    800048a8:	c13d                	beqz	a0,8000490e <kexec+0xa8>
    800048aa:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800048ac:	c23fe0ef          	jal	ra,800034ce <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800048b0:	04000713          	li	a4,64
    800048b4:	4681                	li	a3,0
    800048b6:	e5040613          	addi	a2,s0,-432
    800048ba:	4581                	li	a1,0
    800048bc:	8556                	mv	a0,s5
    800048be:	f9dfe0ef          	jal	ra,8000385a <readi>
    800048c2:	04000793          	li	a5,64
    800048c6:	00f51a63          	bne	a0,a5,800048da <kexec+0x74>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    800048ca:	e5042703          	lw	a4,-432(s0)
    800048ce:	464c47b7          	lui	a5,0x464c4
    800048d2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800048d6:	04f70063          	beq	a4,a5,80004916 <kexec+0xb0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800048da:	8556                	mv	a0,s5
    800048dc:	df9fe0ef          	jal	ra,800036d4 <iunlockput>
    end_op();
    800048e0:	e3cff0ef          	jal	ra,80003f1c <end_op>
  }
  return -1;
    800048e4:	557d                	li	a0,-1
}
    800048e6:	21813083          	ld	ra,536(sp)
    800048ea:	21013403          	ld	s0,528(sp)
    800048ee:	20813483          	ld	s1,520(sp)
    800048f2:	20013903          	ld	s2,512(sp)
    800048f6:	79fe                	ld	s3,504(sp)
    800048f8:	7a5e                	ld	s4,496(sp)
    800048fa:	7abe                	ld	s5,488(sp)
    800048fc:	7b1e                	ld	s6,480(sp)
    800048fe:	6bfe                	ld	s7,472(sp)
    80004900:	6c5e                	ld	s8,464(sp)
    80004902:	6cbe                	ld	s9,456(sp)
    80004904:	6d1e                	ld	s10,448(sp)
    80004906:	7dfa                	ld	s11,440(sp)
    80004908:	22010113          	addi	sp,sp,544
    8000490c:	8082                	ret
    end_op();
    8000490e:	e0eff0ef          	jal	ra,80003f1c <end_op>
    return -1;
    80004912:	557d                	li	a0,-1
    80004914:	bfc9                	j	800048e6 <kexec+0x80>
  if((pagetable = proc_pagetable(p)) == 0)
    80004916:	8526                	mv	a0,s1
    80004918:	a08fd0ef          	jal	ra,80001b20 <proc_pagetable>
    8000491c:	8b2a                	mv	s6,a0
    8000491e:	dd55                	beqz	a0,800048da <kexec+0x74>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004920:	e7042783          	lw	a5,-400(s0)
    80004924:	e8845703          	lhu	a4,-376(s0)
    80004928:	c325                	beqz	a4,80004988 <kexec+0x122>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000492a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000492c:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004930:	6a05                	lui	s4,0x1
    80004932:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004936:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000493a:	6d85                	lui	s11,0x1
    8000493c:	7d7d                	lui	s10,0xfffff
    8000493e:	a411                	j	80004b42 <kexec+0x2dc>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004940:	00003517          	auipc	a0,0x3
    80004944:	f3050513          	addi	a0,a0,-208 # 80007870 <syscalls+0x2c8>
    80004948:	e43fb0ef          	jal	ra,8000078a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000494c:	874a                	mv	a4,s2
    8000494e:	009c86bb          	addw	a3,s9,s1
    80004952:	4581                	li	a1,0
    80004954:	8556                	mv	a0,s5
    80004956:	f05fe0ef          	jal	ra,8000385a <readi>
    8000495a:	2501                	sext.w	a0,a0
    8000495c:	18a91263          	bne	s2,a0,80004ae0 <kexec+0x27a>
  for(i = 0; i < sz; i += PGSIZE){
    80004960:	009d84bb          	addw	s1,s11,s1
    80004964:	013d09bb          	addw	s3,s10,s3
    80004968:	1b74fd63          	bgeu	s1,s7,80004b22 <kexec+0x2bc>
    pa = walkaddr(pagetable, va + i);
    8000496c:	02049593          	slli	a1,s1,0x20
    80004970:	9181                	srli	a1,a1,0x20
    80004972:	95e2                	add	a1,a1,s8
    80004974:	855a                	mv	a0,s6
    80004976:	f62fc0ef          	jal	ra,800010d8 <walkaddr>
    8000497a:	862a                	mv	a2,a0
    if(pa == 0)
    8000497c:	d171                	beqz	a0,80004940 <kexec+0xda>
      n = PGSIZE;
    8000497e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004980:	fd49f6e3          	bgeu	s3,s4,8000494c <kexec+0xe6>
      n = sz - i;
    80004984:	894e                	mv	s2,s3
    80004986:	b7d9                	j	8000494c <kexec+0xe6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004988:	4901                	li	s2,0
  iunlockput(ip);
    8000498a:	8556                	mv	a0,s5
    8000498c:	d49fe0ef          	jal	ra,800036d4 <iunlockput>
  end_op();
    80004990:	d8cff0ef          	jal	ra,80003f1c <end_op>
  p = myproc();
    80004994:	886fd0ef          	jal	ra,80001a1a <myproc>
    80004998:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000499a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000499e:	6785                	lui	a5,0x1
    800049a0:	17fd                	addi	a5,a5,-1
    800049a2:	993e                	add	s2,s2,a5
    800049a4:	77fd                	lui	a5,0xfffff
    800049a6:	00f977b3          	and	a5,s2,a5
    800049aa:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    800049ae:	4691                	li	a3,4
    800049b0:	6609                	lui	a2,0x2
    800049b2:	963e                	add	a2,a2,a5
    800049b4:	85be                	mv	a1,a5
    800049b6:	855a                	mv	a0,s6
    800049b8:	9f1fc0ef          	jal	ra,800013a8 <uvmalloc>
    800049bc:	8c2a                	mv	s8,a0
  ip = 0;
    800049be:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    800049c0:	12050063          	beqz	a0,80004ae0 <kexec+0x27a>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    800049c4:	75f9                	lui	a1,0xffffe
    800049c6:	95aa                	add	a1,a1,a0
    800049c8:	855a                	mv	a0,s6
    800049ca:	bc7fc0ef          	jal	ra,80001590 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    800049ce:	7afd                	lui	s5,0xfffff
    800049d0:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800049d2:	df043783          	ld	a5,-528(s0)
    800049d6:	6388                	ld	a0,0(a5)
    800049d8:	c135                	beqz	a0,80004a3c <kexec+0x1d6>
    800049da:	e9040993          	addi	s3,s0,-368
    800049de:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800049e2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800049e4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800049e6:	d54fc0ef          	jal	ra,80000f3a <strlen>
    800049ea:	0015079b          	addiw	a5,a0,1
    800049ee:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800049f2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800049f6:	11596a63          	bltu	s2,s5,80004b0a <kexec+0x2a4>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800049fa:	df043d83          	ld	s11,-528(s0)
    800049fe:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004a02:	8552                	mv	a0,s4
    80004a04:	d36fc0ef          	jal	ra,80000f3a <strlen>
    80004a08:	0015069b          	addiw	a3,a0,1
    80004a0c:	8652                	mv	a2,s4
    80004a0e:	85ca                	mv	a1,s2
    80004a10:	855a                	mv	a0,s6
    80004a12:	cebfc0ef          	jal	ra,800016fc <copyout>
    80004a16:	0e054e63          	bltz	a0,80004b12 <kexec+0x2ac>
    ustack[argc] = sp;
    80004a1a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004a1e:	0485                	addi	s1,s1,1
    80004a20:	008d8793          	addi	a5,s11,8
    80004a24:	def43823          	sd	a5,-528(s0)
    80004a28:	008db503          	ld	a0,8(s11)
    80004a2c:	c911                	beqz	a0,80004a40 <kexec+0x1da>
    if(argc >= MAXARG)
    80004a2e:	09a1                	addi	s3,s3,8
    80004a30:	fb3c9be3          	bne	s9,s3,800049e6 <kexec+0x180>
  sz = sz1;
    80004a34:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004a38:	4a81                	li	s5,0
    80004a3a:	a05d                	j	80004ae0 <kexec+0x27a>
  sp = sz;
    80004a3c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004a3e:	4481                	li	s1,0
  ustack[argc] = 0;
    80004a40:	00349793          	slli	a5,s1,0x3
    80004a44:	f9040713          	addi	a4,s0,-112
    80004a48:	97ba                	add	a5,a5,a4
    80004a4a:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd6000>
  sp -= (argc+1) * sizeof(uint64);
    80004a4e:	00148693          	addi	a3,s1,1
    80004a52:	068e                	slli	a3,a3,0x3
    80004a54:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004a58:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004a5c:	01597663          	bgeu	s2,s5,80004a68 <kexec+0x202>
  sz = sz1;
    80004a60:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004a64:	4a81                	li	s5,0
    80004a66:	a8ad                	j	80004ae0 <kexec+0x27a>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004a68:	e9040613          	addi	a2,s0,-368
    80004a6c:	85ca                	mv	a1,s2
    80004a6e:	855a                	mv	a0,s6
    80004a70:	c8dfc0ef          	jal	ra,800016fc <copyout>
    80004a74:	0a054363          	bltz	a0,80004b1a <kexec+0x2b4>
  p->trapframe->a1 = sp;
    80004a78:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004a7c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004a80:	de843783          	ld	a5,-536(s0)
    80004a84:	0007c703          	lbu	a4,0(a5)
    80004a88:	cf11                	beqz	a4,80004aa4 <kexec+0x23e>
    80004a8a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004a8c:	02f00693          	li	a3,47
    80004a90:	a039                	j	80004a9e <kexec+0x238>
      last = s+1;
    80004a92:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004a96:	0785                	addi	a5,a5,1
    80004a98:	fff7c703          	lbu	a4,-1(a5)
    80004a9c:	c701                	beqz	a4,80004aa4 <kexec+0x23e>
    if(*s == '/')
    80004a9e:	fed71ce3          	bne	a4,a3,80004a96 <kexec+0x230>
    80004aa2:	bfc5                	j	80004a92 <kexec+0x22c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004aa4:	4641                	li	a2,16
    80004aa6:	de843583          	ld	a1,-536(s0)
    80004aaa:	158b8513          	addi	a0,s7,344
    80004aae:	c5afc0ef          	jal	ra,80000f08 <safestrcpy>
  oldpagetable = p->pagetable;
    80004ab2:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004ab6:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004aba:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    80004abe:	058bb783          	ld	a5,88(s7)
    80004ac2:	e6843703          	ld	a4,-408(s0)
    80004ac6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ac8:	058bb783          	ld	a5,88(s7)
    80004acc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ad0:	85ea                	mv	a1,s10
    80004ad2:	8d2fd0ef          	jal	ra,80001ba4 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ad6:	0004851b          	sext.w	a0,s1
    80004ada:	b531                	j	800048e6 <kexec+0x80>
    80004adc:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004ae0:	df843583          	ld	a1,-520(s0)
    80004ae4:	855a                	mv	a0,s6
    80004ae6:	8befd0ef          	jal	ra,80001ba4 <proc_freepagetable>
  if(ip){
    80004aea:	de0a98e3          	bnez	s5,800048da <kexec+0x74>
  return -1;
    80004aee:	557d                	li	a0,-1
    80004af0:	bbdd                	j	800048e6 <kexec+0x80>
    80004af2:	df243c23          	sd	s2,-520(s0)
    80004af6:	b7ed                	j	80004ae0 <kexec+0x27a>
    80004af8:	df243c23          	sd	s2,-520(s0)
    80004afc:	b7d5                	j	80004ae0 <kexec+0x27a>
    80004afe:	df243c23          	sd	s2,-520(s0)
    80004b02:	bff9                	j	80004ae0 <kexec+0x27a>
    80004b04:	df243c23          	sd	s2,-520(s0)
    80004b08:	bfe1                	j	80004ae0 <kexec+0x27a>
  sz = sz1;
    80004b0a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004b0e:	4a81                	li	s5,0
    80004b10:	bfc1                	j	80004ae0 <kexec+0x27a>
  sz = sz1;
    80004b12:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004b16:	4a81                	li	s5,0
    80004b18:	b7e1                	j	80004ae0 <kexec+0x27a>
  sz = sz1;
    80004b1a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004b1e:	4a81                	li	s5,0
    80004b20:	b7c1                	j	80004ae0 <kexec+0x27a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004b22:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004b26:	e0843783          	ld	a5,-504(s0)
    80004b2a:	0017869b          	addiw	a3,a5,1
    80004b2e:	e0d43423          	sd	a3,-504(s0)
    80004b32:	e0043783          	ld	a5,-512(s0)
    80004b36:	0387879b          	addiw	a5,a5,56
    80004b3a:	e8845703          	lhu	a4,-376(s0)
    80004b3e:	e4e6d6e3          	bge	a3,a4,8000498a <kexec+0x124>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004b42:	2781                	sext.w	a5,a5
    80004b44:	e0f43023          	sd	a5,-512(s0)
    80004b48:	03800713          	li	a4,56
    80004b4c:	86be                	mv	a3,a5
    80004b4e:	e1840613          	addi	a2,s0,-488
    80004b52:	4581                	li	a1,0
    80004b54:	8556                	mv	a0,s5
    80004b56:	d05fe0ef          	jal	ra,8000385a <readi>
    80004b5a:	03800793          	li	a5,56
    80004b5e:	f6f51fe3          	bne	a0,a5,80004adc <kexec+0x276>
    if(ph.type != ELF_PROG_LOAD)
    80004b62:	e1842783          	lw	a5,-488(s0)
    80004b66:	4705                	li	a4,1
    80004b68:	fae79fe3          	bne	a5,a4,80004b26 <kexec+0x2c0>
    if(ph.memsz < ph.filesz)
    80004b6c:	e4043483          	ld	s1,-448(s0)
    80004b70:	e3843783          	ld	a5,-456(s0)
    80004b74:	f6f4efe3          	bltu	s1,a5,80004af2 <kexec+0x28c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004b78:	e2843783          	ld	a5,-472(s0)
    80004b7c:	94be                	add	s1,s1,a5
    80004b7e:	f6f4ede3          	bltu	s1,a5,80004af8 <kexec+0x292>
    if(ph.vaddr % PGSIZE != 0)
    80004b82:	de043703          	ld	a4,-544(s0)
    80004b86:	8ff9                	and	a5,a5,a4
    80004b88:	fbbd                	bnez	a5,80004afe <kexec+0x298>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004b8a:	e1c42503          	lw	a0,-484(s0)
    80004b8e:	cbdff0ef          	jal	ra,8000484a <flags2perm>
    80004b92:	86aa                	mv	a3,a0
    80004b94:	8626                	mv	a2,s1
    80004b96:	85ca                	mv	a1,s2
    80004b98:	855a                	mv	a0,s6
    80004b9a:	80ffc0ef          	jal	ra,800013a8 <uvmalloc>
    80004b9e:	dea43c23          	sd	a0,-520(s0)
    80004ba2:	d12d                	beqz	a0,80004b04 <kexec+0x29e>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ba4:	e2843c03          	ld	s8,-472(s0)
    80004ba8:	e2042c83          	lw	s9,-480(s0)
    80004bac:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004bb0:	f60b89e3          	beqz	s7,80004b22 <kexec+0x2bc>
    80004bb4:	89de                	mv	s3,s7
    80004bb6:	4481                	li	s1,0
    80004bb8:	bb55                	j	8000496c <kexec+0x106>

0000000080004bba <argfd>:
#include "fcntl.h"

// 获取第n个系统调用参数作为文件描述符，并返回该描述符及对应的文件结构。
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004bba:	7179                	addi	sp,sp,-48
    80004bbc:	f406                	sd	ra,40(sp)
    80004bbe:	f022                	sd	s0,32(sp)
    80004bc0:	ec26                	sd	s1,24(sp)
    80004bc2:	e84a                	sd	s2,16(sp)
    80004bc4:	1800                	addi	s0,sp,48
    80004bc6:	892e                	mv	s2,a1
    80004bc8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);  // 获取系统调用参数中的文件描述符
    80004bca:	fdc40593          	addi	a1,s0,-36
    80004bce:	f19fd0ef          	jal	ra,80002ae6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)  // 检查文件描述符的有效性
    80004bd2:	fdc42703          	lw	a4,-36(s0)
    80004bd6:	47bd                	li	a5,15
    80004bd8:	02e7e963          	bltu	a5,a4,80004c0a <argfd+0x50>
    80004bdc:	e3ffc0ef          	jal	ra,80001a1a <myproc>
    80004be0:	fdc42703          	lw	a4,-36(s0)
    80004be4:	01a70793          	addi	a5,a4,26
    80004be8:	078e                	slli	a5,a5,0x3
    80004bea:	953e                	add	a0,a0,a5
    80004bec:	611c                	ld	a5,0(a0)
    80004bee:	c385                	beqz	a5,80004c0e <argfd+0x54>
    return -1;
  if(pfd)
    80004bf0:	00090463          	beqz	s2,80004bf8 <argfd+0x3e>
    *pfd = fd;
    80004bf4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004bf8:	4501                	li	a0,0
  if(pf)
    80004bfa:	c091                	beqz	s1,80004bfe <argfd+0x44>
    *pf = f;
    80004bfc:	e09c                	sd	a5,0(s1)
}
    80004bfe:	70a2                	ld	ra,40(sp)
    80004c00:	7402                	ld	s0,32(sp)
    80004c02:	64e2                	ld	s1,24(sp)
    80004c04:	6942                	ld	s2,16(sp)
    80004c06:	6145                	addi	sp,sp,48
    80004c08:	8082                	ret
    return -1;
    80004c0a:	557d                	li	a0,-1
    80004c0c:	bfcd                	j	80004bfe <argfd+0x44>
    80004c0e:	557d                	li	a0,-1
    80004c10:	b7fd                	j	80004bfe <argfd+0x44>

0000000080004c12 <fdalloc>:

// 为给定文件分配一个文件描述符。
// 成功时接管调用者的文件引用。
static int
fdalloc(struct file *f)
{
    80004c12:	1101                	addi	sp,sp,-32
    80004c14:	ec06                	sd	ra,24(sp)
    80004c16:	e822                	sd	s0,16(sp)
    80004c18:	e426                	sd	s1,8(sp)
    80004c1a:	1000                	addi	s0,sp,32
    80004c1c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004c1e:	dfdfc0ef          	jal	ra,80001a1a <myproc>
    80004c22:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004c24:	0d050793          	addi	a5,a0,208
    80004c28:	4501                	li	a0,0
    80004c2a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){  // 查找一个未使用的文件描述符
    80004c2c:	6398                	ld	a4,0(a5)
    80004c2e:	cb19                	beqz	a4,80004c44 <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004c30:	2505                	addiw	a0,a0,1
    80004c32:	07a1                	addi	a5,a5,8
    80004c34:	fed51ce3          	bne	a0,a3,80004c2c <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;  // 没有可用的文件描述符
    80004c38:	557d                	li	a0,-1
}
    80004c3a:	60e2                	ld	ra,24(sp)
    80004c3c:	6442                	ld	s0,16(sp)
    80004c3e:	64a2                	ld	s1,8(sp)
    80004c40:	6105                	addi	sp,sp,32
    80004c42:	8082                	ret
      p->ofile[fd] = f;
    80004c44:	01a50793          	addi	a5,a0,26
    80004c48:	078e                	slli	a5,a5,0x3
    80004c4a:	963e                	add	a2,a2,a5
    80004c4c:	e204                	sd	s1,0(a2)
      return fd;
    80004c4e:	b7f5                	j	80004c3a <fdalloc+0x28>

0000000080004c50 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004c50:	715d                	addi	sp,sp,-80
    80004c52:	e486                	sd	ra,72(sp)
    80004c54:	e0a2                	sd	s0,64(sp)
    80004c56:	fc26                	sd	s1,56(sp)
    80004c58:	f84a                	sd	s2,48(sp)
    80004c5a:	f44e                	sd	s3,40(sp)
    80004c5c:	f052                	sd	s4,32(sp)
    80004c5e:	ec56                	sd	s5,24(sp)
    80004c60:	e85a                	sd	s6,16(sp)
    80004c62:	0880                	addi	s0,sp,80
    80004c64:	8b2e                	mv	s6,a1
    80004c66:	89b2                	mv	s3,a2
    80004c68:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)  // 查找父目录
    80004c6a:	fb040593          	addi	a1,s0,-80
    80004c6e:	868ff0ef          	jal	ra,80003cd6 <nameiparent>
    80004c72:	84aa                	mv	s1,a0
    80004c74:	10050b63          	beqz	a0,80004d8a <create+0x13a>
    return 0;

  ilock(dp);
    80004c78:	857fe0ef          	jal	ra,800034ce <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){  // 检查文件是否已存在
    80004c7c:	4601                	li	a2,0
    80004c7e:	fb040593          	addi	a1,s0,-80
    80004c82:	8526                	mv	a0,s1
    80004c84:	dd3fe0ef          	jal	ra,80003a56 <dirlookup>
    80004c88:	8aaa                	mv	s5,a0
    80004c8a:	c521                	beqz	a0,80004cd2 <create+0x82>
    iunlockput(dp);
    80004c8c:	8526                	mv	a0,s1
    80004c8e:	a47fe0ef          	jal	ra,800036d4 <iunlockput>
    ilock(ip);
    80004c92:	8556                	mv	a0,s5
    80004c94:	83bfe0ef          	jal	ra,800034ce <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004c98:	000b059b          	sext.w	a1,s6
    80004c9c:	4789                	li	a5,2
    80004c9e:	02f59563          	bne	a1,a5,80004cc8 <create+0x78>
    80004ca2:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd6144>
    80004ca6:	37f9                	addiw	a5,a5,-2
    80004ca8:	17c2                	slli	a5,a5,0x30
    80004caa:	93c1                	srli	a5,a5,0x30
    80004cac:	4705                	li	a4,1
    80004cae:	00f76d63          	bltu	a4,a5,80004cc8 <create+0x78>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004cb2:	8556                	mv	a0,s5
    80004cb4:	60a6                	ld	ra,72(sp)
    80004cb6:	6406                	ld	s0,64(sp)
    80004cb8:	74e2                	ld	s1,56(sp)
    80004cba:	7942                	ld	s2,48(sp)
    80004cbc:	79a2                	ld	s3,40(sp)
    80004cbe:	7a02                	ld	s4,32(sp)
    80004cc0:	6ae2                	ld	s5,24(sp)
    80004cc2:	6b42                	ld	s6,16(sp)
    80004cc4:	6161                	addi	sp,sp,80
    80004cc6:	8082                	ret
    iunlockput(ip);
    80004cc8:	8556                	mv	a0,s5
    80004cca:	a0bfe0ef          	jal	ra,800036d4 <iunlockput>
    return 0;
    80004cce:	4a81                	li	s5,0
    80004cd0:	b7cd                	j	80004cb2 <create+0x62>
  if((ip = ialloc(dp->dev, type)) == 0){  // 分配 inode
    80004cd2:	85da                	mv	a1,s6
    80004cd4:	4088                	lw	a0,0(s1)
    80004cd6:	e90fe0ef          	jal	ra,80003366 <ialloc>
    80004cda:	8a2a                	mv	s4,a0
    80004cdc:	cd1d                	beqz	a0,80004d1a <create+0xca>
  ilock(ip);
    80004cde:	ff0fe0ef          	jal	ra,800034ce <ilock>
  ip->major = major;
    80004ce2:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004ce6:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004cea:	4905                	li	s2,1
    80004cec:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004cf0:	8552                	mv	a0,s4
    80004cf2:	f2afe0ef          	jal	ra,8000341c <iupdate>
  if(type == T_DIR){  // 创建 . 和 .. 目录项
    80004cf6:	000b059b          	sext.w	a1,s6
    80004cfa:	03258563          	beq	a1,s2,80004d24 <create+0xd4>
  if(dirlink(dp, name, ip->inum) < 0)
    80004cfe:	004a2603          	lw	a2,4(s4)
    80004d02:	fb040593          	addi	a1,s0,-80
    80004d06:	8526                	mv	a0,s1
    80004d08:	f1bfe0ef          	jal	ra,80003c22 <dirlink>
    80004d0c:	06054363          	bltz	a0,80004d72 <create+0x122>
  iunlockput(dp);
    80004d10:	8526                	mv	a0,s1
    80004d12:	9c3fe0ef          	jal	ra,800036d4 <iunlockput>
  return ip;
    80004d16:	8ad2                	mv	s5,s4
    80004d18:	bf69                	j	80004cb2 <create+0x62>
    iunlockput(dp);
    80004d1a:	8526                	mv	a0,s1
    80004d1c:	9b9fe0ef          	jal	ra,800036d4 <iunlockput>
    return 0;
    80004d20:	8ad2                	mv	s5,s4
    80004d22:	bf41                	j	80004cb2 <create+0x62>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004d24:	004a2603          	lw	a2,4(s4)
    80004d28:	00003597          	auipc	a1,0x3
    80004d2c:	b6858593          	addi	a1,a1,-1176 # 80007890 <syscalls+0x2e8>
    80004d30:	8552                	mv	a0,s4
    80004d32:	ef1fe0ef          	jal	ra,80003c22 <dirlink>
    80004d36:	02054e63          	bltz	a0,80004d72 <create+0x122>
    80004d3a:	40d0                	lw	a2,4(s1)
    80004d3c:	00003597          	auipc	a1,0x3
    80004d40:	b5c58593          	addi	a1,a1,-1188 # 80007898 <syscalls+0x2f0>
    80004d44:	8552                	mv	a0,s4
    80004d46:	eddfe0ef          	jal	ra,80003c22 <dirlink>
    80004d4a:	02054463          	bltz	a0,80004d72 <create+0x122>
  if(dirlink(dp, name, ip->inum) < 0)
    80004d4e:	004a2603          	lw	a2,4(s4)
    80004d52:	fb040593          	addi	a1,s0,-80
    80004d56:	8526                	mv	a0,s1
    80004d58:	ecbfe0ef          	jal	ra,80003c22 <dirlink>
    80004d5c:	00054b63          	bltz	a0,80004d72 <create+0x122>
    dp->nlink++;  // 更新父目录的链接计数
    80004d60:	04a4d783          	lhu	a5,74(s1)
    80004d64:	2785                	addiw	a5,a5,1
    80004d66:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004d6a:	8526                	mv	a0,s1
    80004d6c:	eb0fe0ef          	jal	ra,8000341c <iupdate>
    80004d70:	b745                	j	80004d10 <create+0xc0>
  ip->nlink = 0;
    80004d72:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004d76:	8552                	mv	a0,s4
    80004d78:	ea4fe0ef          	jal	ra,8000341c <iupdate>
  iunlockput(ip);
    80004d7c:	8552                	mv	a0,s4
    80004d7e:	957fe0ef          	jal	ra,800036d4 <iunlockput>
  iunlockput(dp);
    80004d82:	8526                	mv	a0,s1
    80004d84:	951fe0ef          	jal	ra,800036d4 <iunlockput>
  return 0;
    80004d88:	b72d                	j	80004cb2 <create+0x62>
    return 0;
    80004d8a:	8aaa                	mv	s5,a0
    80004d8c:	b71d                	j	80004cb2 <create+0x62>

0000000080004d8e <sys_dup>:
{
    80004d8e:	7179                	addi	sp,sp,-48
    80004d90:	f406                	sd	ra,40(sp)
    80004d92:	f022                	sd	s0,32(sp)
    80004d94:	ec26                	sd	s1,24(sp)
    80004d96:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004d98:	fd840613          	addi	a2,s0,-40
    80004d9c:	4581                	li	a1,0
    80004d9e:	4501                	li	a0,0
    80004da0:	e1bff0ef          	jal	ra,80004bba <argfd>
    return -1;
    80004da4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004da6:	00054f63          	bltz	a0,80004dc4 <sys_dup+0x36>
  if((fd=fdalloc(f)) < 0)  // 为文件分配新的文件描述符
    80004daa:	fd843503          	ld	a0,-40(s0)
    80004dae:	e65ff0ef          	jal	ra,80004c12 <fdalloc>
    80004db2:	84aa                	mv	s1,a0
    return -1;
    80004db4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)  // 为文件分配新的文件描述符
    80004db6:	00054763          	bltz	a0,80004dc4 <sys_dup+0x36>
  filedup(f);  // 增加文件引用计数
    80004dba:	fd843503          	ld	a0,-40(s0)
    80004dbe:	cb6ff0ef          	jal	ra,80004274 <filedup>
  return fd;
    80004dc2:	87a6                	mv	a5,s1
}
    80004dc4:	853e                	mv	a0,a5
    80004dc6:	70a2                	ld	ra,40(sp)
    80004dc8:	7402                	ld	s0,32(sp)
    80004dca:	64e2                	ld	s1,24(sp)
    80004dcc:	6145                	addi	sp,sp,48
    80004dce:	8082                	ret

0000000080004dd0 <sys_read>:
{
    80004dd0:	7179                	addi	sp,sp,-48
    80004dd2:	f406                	sd	ra,40(sp)
    80004dd4:	f022                	sd	s0,32(sp)
    80004dd6:	1800                	addi	s0,sp,48
  argaddr(1, &p);  // 获取读取数据的用户空间地址
    80004dd8:	fd840593          	addi	a1,s0,-40
    80004ddc:	4505                	li	a0,1
    80004dde:	d25fd0ef          	jal	ra,80002b02 <argaddr>
  argint(2, &n);  // 获取读取字节数
    80004de2:	fe440593          	addi	a1,s0,-28
    80004de6:	4509                	li	a0,2
    80004de8:	cfffd0ef          	jal	ra,80002ae6 <argint>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004dec:	fe840613          	addi	a2,s0,-24
    80004df0:	4581                	li	a1,0
    80004df2:	4501                	li	a0,0
    80004df4:	dc7ff0ef          	jal	ra,80004bba <argfd>
    80004df8:	87aa                	mv	a5,a0
    return -1;
    80004dfa:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004dfc:	0007ca63          	bltz	a5,80004e10 <sys_read+0x40>
  return fileread(f, p, n);  // 从文件中读取数据
    80004e00:	fe442603          	lw	a2,-28(s0)
    80004e04:	fd843583          	ld	a1,-40(s0)
    80004e08:	fe843503          	ld	a0,-24(s0)
    80004e0c:	db4ff0ef          	jal	ra,800043c0 <fileread>
}
    80004e10:	70a2                	ld	ra,40(sp)
    80004e12:	7402                	ld	s0,32(sp)
    80004e14:	6145                	addi	sp,sp,48
    80004e16:	8082                	ret

0000000080004e18 <sys_write>:
{
    80004e18:	7179                	addi	sp,sp,-48
    80004e1a:	f406                	sd	ra,40(sp)
    80004e1c:	f022                	sd	s0,32(sp)
    80004e1e:	1800                	addi	s0,sp,48
  argaddr(1, &p);  // 获取写入数据的用户空间地址
    80004e20:	fd840593          	addi	a1,s0,-40
    80004e24:	4505                	li	a0,1
    80004e26:	cddfd0ef          	jal	ra,80002b02 <argaddr>
  argint(2, &n);  // 获取写入字节数
    80004e2a:	fe440593          	addi	a1,s0,-28
    80004e2e:	4509                	li	a0,2
    80004e30:	cb7fd0ef          	jal	ra,80002ae6 <argint>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004e34:	fe840613          	addi	a2,s0,-24
    80004e38:	4581                	li	a1,0
    80004e3a:	4501                	li	a0,0
    80004e3c:	d7fff0ef          	jal	ra,80004bba <argfd>
    80004e40:	87aa                	mv	a5,a0
    return -1;
    80004e42:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004e44:	0007ca63          	bltz	a5,80004e58 <sys_write+0x40>
  return filewrite(f, p, n);  // 向文件中写入数据
    80004e48:	fe442603          	lw	a2,-28(s0)
    80004e4c:	fd843583          	ld	a1,-40(s0)
    80004e50:	fe843503          	ld	a0,-24(s0)
    80004e54:	e1aff0ef          	jal	ra,8000446e <filewrite>
}
    80004e58:	70a2                	ld	ra,40(sp)
    80004e5a:	7402                	ld	s0,32(sp)
    80004e5c:	6145                	addi	sp,sp,48
    80004e5e:	8082                	ret

0000000080004e60 <sys_close>:
{
    80004e60:	1101                	addi	sp,sp,-32
    80004e62:	ec06                	sd	ra,24(sp)
    80004e64:	e822                	sd	s0,16(sp)
    80004e66:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)  // 获取文件描述符并返回文件结构
    80004e68:	fe040613          	addi	a2,s0,-32
    80004e6c:	fec40593          	addi	a1,s0,-20
    80004e70:	4501                	li	a0,0
    80004e72:	d49ff0ef          	jal	ra,80004bba <argfd>
    return -1;
    80004e76:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)  // 获取文件描述符并返回文件结构
    80004e78:	02054063          	bltz	a0,80004e98 <sys_close+0x38>
  myproc()->ofile[fd] = 0;  // 关闭文件描述符
    80004e7c:	b9ffc0ef          	jal	ra,80001a1a <myproc>
    80004e80:	fec42783          	lw	a5,-20(s0)
    80004e84:	07e9                	addi	a5,a5,26
    80004e86:	078e                	slli	a5,a5,0x3
    80004e88:	97aa                	add	a5,a5,a0
    80004e8a:	0007b023          	sd	zero,0(a5)
  fileclose(f);  // 关闭文件
    80004e8e:	fe043503          	ld	a0,-32(s0)
    80004e92:	c28ff0ef          	jal	ra,800042ba <fileclose>
  return 0;
    80004e96:	4781                	li	a5,0
}
    80004e98:	853e                	mv	a0,a5
    80004e9a:	60e2                	ld	ra,24(sp)
    80004e9c:	6442                	ld	s0,16(sp)
    80004e9e:	6105                	addi	sp,sp,32
    80004ea0:	8082                	ret

0000000080004ea2 <sys_fstat>:
{
    80004ea2:	1101                	addi	sp,sp,-32
    80004ea4:	ec06                	sd	ra,24(sp)
    80004ea6:	e822                	sd	s0,16(sp)
    80004ea8:	1000                	addi	s0,sp,32
  argaddr(1, &st);  // 获取 stat 结构体地址
    80004eaa:	fe040593          	addi	a1,s0,-32
    80004eae:	4505                	li	a0,1
    80004eb0:	c53fd0ef          	jal	ra,80002b02 <argaddr>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004eb4:	fe840613          	addi	a2,s0,-24
    80004eb8:	4581                	li	a1,0
    80004eba:	4501                	li	a0,0
    80004ebc:	cffff0ef          	jal	ra,80004bba <argfd>
    80004ec0:	87aa                	mv	a5,a0
    return -1;
    80004ec2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004ec4:	0007c863          	bltz	a5,80004ed4 <sys_fstat+0x32>
  return filestat(f, st);  // 获取文件状态信息
    80004ec8:	fe043583          	ld	a1,-32(s0)
    80004ecc:	fe843503          	ld	a0,-24(s0)
    80004ed0:	c92ff0ef          	jal	ra,80004362 <filestat>
}
    80004ed4:	60e2                	ld	ra,24(sp)
    80004ed6:	6442                	ld	s0,16(sp)
    80004ed8:	6105                	addi	sp,sp,32
    80004eda:	8082                	ret

0000000080004edc <sys_link>:
{
    80004edc:	7169                	addi	sp,sp,-304
    80004ede:	f606                	sd	ra,296(sp)
    80004ee0:	f222                	sd	s0,288(sp)
    80004ee2:	ee26                	sd	s1,280(sp)
    80004ee4:	ea4a                	sd	s2,272(sp)
    80004ee6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004ee8:	08000613          	li	a2,128
    80004eec:	ed040593          	addi	a1,s0,-304
    80004ef0:	4501                	li	a0,0
    80004ef2:	c2dfd0ef          	jal	ra,80002b1e <argstr>
    return -1;
    80004ef6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004ef8:	0c054663          	bltz	a0,80004fc4 <sys_link+0xe8>
    80004efc:	08000613          	li	a2,128
    80004f00:	f5040593          	addi	a1,s0,-176
    80004f04:	4505                	li	a0,1
    80004f06:	c19fd0ef          	jal	ra,80002b1e <argstr>
    return -1;
    80004f0a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004f0c:	0a054c63          	bltz	a0,80004fc4 <sys_link+0xe8>
  begin_op();
    80004f10:	f9dfe0ef          	jal	ra,80003eac <begin_op>
  if((ip = namei(old)) == 0){  // 查找 old 路径对应的 inode
    80004f14:	ed040513          	addi	a0,s0,-304
    80004f18:	da5fe0ef          	jal	ra,80003cbc <namei>
    80004f1c:	84aa                	mv	s1,a0
    80004f1e:	c525                	beqz	a0,80004f86 <sys_link+0xaa>
  ilock(ip);
    80004f20:	daefe0ef          	jal	ra,800034ce <ilock>
  if(ip->type == T_DIR){  // 如果是目录，不能创建链接
    80004f24:	04449703          	lh	a4,68(s1)
    80004f28:	4785                	li	a5,1
    80004f2a:	06f70263          	beq	a4,a5,80004f8e <sys_link+0xb2>
  ip->nlink++;  // 增加链接计数
    80004f2e:	04a4d783          	lhu	a5,74(s1)
    80004f32:	2785                	addiw	a5,a5,1
    80004f34:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004f38:	8526                	mv	a0,s1
    80004f3a:	ce2fe0ef          	jal	ra,8000341c <iupdate>
  iunlock(ip);
    80004f3e:	8526                	mv	a0,s1
    80004f40:	e38fe0ef          	jal	ra,80003578 <iunlock>
  if((dp = nameiparent(new, name)) == 0)  // 获取 new 路径的父目录
    80004f44:	fd040593          	addi	a1,s0,-48
    80004f48:	f5040513          	addi	a0,s0,-176
    80004f4c:	d8bfe0ef          	jal	ra,80003cd6 <nameiparent>
    80004f50:	892a                	mv	s2,a0
    80004f52:	c921                	beqz	a0,80004fa2 <sys_link+0xc6>
  ilock(dp);
    80004f54:	d7afe0ef          	jal	ra,800034ce <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){  // 在父目录中创建新链接
    80004f58:	00092703          	lw	a4,0(s2)
    80004f5c:	409c                	lw	a5,0(s1)
    80004f5e:	02f71f63          	bne	a4,a5,80004f9c <sys_link+0xc0>
    80004f62:	40d0                	lw	a2,4(s1)
    80004f64:	fd040593          	addi	a1,s0,-48
    80004f68:	854a                	mv	a0,s2
    80004f6a:	cb9fe0ef          	jal	ra,80003c22 <dirlink>
    80004f6e:	02054763          	bltz	a0,80004f9c <sys_link+0xc0>
  iunlockput(dp);
    80004f72:	854a                	mv	a0,s2
    80004f74:	f60fe0ef          	jal	ra,800036d4 <iunlockput>
  iput(ip);
    80004f78:	8526                	mv	a0,s1
    80004f7a:	ed2fe0ef          	jal	ra,8000364c <iput>
  end_op();
    80004f7e:	f9ffe0ef          	jal	ra,80003f1c <end_op>
  return 0;
    80004f82:	4781                	li	a5,0
    80004f84:	a081                	j	80004fc4 <sys_link+0xe8>
    end_op();
    80004f86:	f97fe0ef          	jal	ra,80003f1c <end_op>
    return -1;
    80004f8a:	57fd                	li	a5,-1
    80004f8c:	a825                	j	80004fc4 <sys_link+0xe8>
    iunlockput(ip);
    80004f8e:	8526                	mv	a0,s1
    80004f90:	f44fe0ef          	jal	ra,800036d4 <iunlockput>
    end_op();
    80004f94:	f89fe0ef          	jal	ra,80003f1c <end_op>
    return -1;
    80004f98:	57fd                	li	a5,-1
    80004f9a:	a02d                	j	80004fc4 <sys_link+0xe8>
    iunlockput(dp);
    80004f9c:	854a                	mv	a0,s2
    80004f9e:	f36fe0ef          	jal	ra,800036d4 <iunlockput>
  ilock(ip);
    80004fa2:	8526                	mv	a0,s1
    80004fa4:	d2afe0ef          	jal	ra,800034ce <ilock>
  ip->nlink--;  // 发生错误，恢复链接计数
    80004fa8:	04a4d783          	lhu	a5,74(s1)
    80004fac:	37fd                	addiw	a5,a5,-1
    80004fae:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004fb2:	8526                	mv	a0,s1
    80004fb4:	c68fe0ef          	jal	ra,8000341c <iupdate>
  iunlockput(ip);
    80004fb8:	8526                	mv	a0,s1
    80004fba:	f1afe0ef          	jal	ra,800036d4 <iunlockput>
  end_op();
    80004fbe:	f5ffe0ef          	jal	ra,80003f1c <end_op>
  return -1;
    80004fc2:	57fd                	li	a5,-1
}
    80004fc4:	853e                	mv	a0,a5
    80004fc6:	70b2                	ld	ra,296(sp)
    80004fc8:	7412                	ld	s0,288(sp)
    80004fca:	64f2                	ld	s1,280(sp)
    80004fcc:	6952                	ld	s2,272(sp)
    80004fce:	6155                	addi	sp,sp,304
    80004fd0:	8082                	ret

0000000080004fd2 <sys_unlink>:
{
    80004fd2:	7151                	addi	sp,sp,-240
    80004fd4:	f586                	sd	ra,232(sp)
    80004fd6:	f1a2                	sd	s0,224(sp)
    80004fd8:	eda6                	sd	s1,216(sp)
    80004fda:	e9ca                	sd	s2,208(sp)
    80004fdc:	e5ce                	sd	s3,200(sp)
    80004fde:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)  // 获取路径
    80004fe0:	08000613          	li	a2,128
    80004fe4:	f3040593          	addi	a1,s0,-208
    80004fe8:	4501                	li	a0,0
    80004fea:	b35fd0ef          	jal	ra,80002b1e <argstr>
    80004fee:	12054b63          	bltz	a0,80005124 <sys_unlink+0x152>
  begin_op();
    80004ff2:	ebbfe0ef          	jal	ra,80003eac <begin_op>
  if((dp = nameiparent(path, name)) == 0){  // 查找路径的父目录
    80004ff6:	fb040593          	addi	a1,s0,-80
    80004ffa:	f3040513          	addi	a0,s0,-208
    80004ffe:	cd9fe0ef          	jal	ra,80003cd6 <nameiparent>
    80005002:	84aa                	mv	s1,a0
    80005004:	c54d                	beqz	a0,800050ae <sys_unlink+0xdc>
  ilock(dp);
    80005006:	cc8fe0ef          	jal	ra,800034ce <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000500a:	00003597          	auipc	a1,0x3
    8000500e:	88658593          	addi	a1,a1,-1914 # 80007890 <syscalls+0x2e8>
    80005012:	fb040513          	addi	a0,s0,-80
    80005016:	a2bfe0ef          	jal	ra,80003a40 <namecmp>
    8000501a:	10050a63          	beqz	a0,8000512e <sys_unlink+0x15c>
    8000501e:	00003597          	auipc	a1,0x3
    80005022:	87a58593          	addi	a1,a1,-1926 # 80007898 <syscalls+0x2f0>
    80005026:	fb040513          	addi	a0,s0,-80
    8000502a:	a17fe0ef          	jal	ra,80003a40 <namecmp>
    8000502e:	10050063          	beqz	a0,8000512e <sys_unlink+0x15c>
  if((ip = dirlookup(dp, name, &off)) == 0)  // 查找目录项
    80005032:	f2c40613          	addi	a2,s0,-212
    80005036:	fb040593          	addi	a1,s0,-80
    8000503a:	8526                	mv	a0,s1
    8000503c:	a1bfe0ef          	jal	ra,80003a56 <dirlookup>
    80005040:	892a                	mv	s2,a0
    80005042:	0e050663          	beqz	a0,8000512e <sys_unlink+0x15c>
  ilock(ip);
    80005046:	c88fe0ef          	jal	ra,800034ce <ilock>
  if(ip->nlink < 1)
    8000504a:	04a91783          	lh	a5,74(s2)
    8000504e:	06f05463          	blez	a5,800050b6 <sys_unlink+0xe4>
  if(ip->type == T_DIR && !isdirempty(ip)){  // 如果是非空目录，不能删除
    80005052:	04491703          	lh	a4,68(s2)
    80005056:	4785                	li	a5,1
    80005058:	06f70563          	beq	a4,a5,800050c2 <sys_unlink+0xf0>
  memset(&de, 0, sizeof(de));  // 清空目录项
    8000505c:	4641                	li	a2,16
    8000505e:	4581                	li	a1,0
    80005060:	fc040513          	addi	a0,s0,-64
    80005064:	d5ffb0ef          	jal	ra,80000dc2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))  // 删除目录项
    80005068:	4741                	li	a4,16
    8000506a:	f2c42683          	lw	a3,-212(s0)
    8000506e:	fc040613          	addi	a2,s0,-64
    80005072:	4581                	li	a1,0
    80005074:	8526                	mv	a0,s1
    80005076:	8c9fe0ef          	jal	ra,8000393e <writei>
    8000507a:	47c1                	li	a5,16
    8000507c:	08f51563          	bne	a0,a5,80005106 <sys_unlink+0x134>
  if(ip->type == T_DIR){
    80005080:	04491703          	lh	a4,68(s2)
    80005084:	4785                	li	a5,1
    80005086:	08f70663          	beq	a4,a5,80005112 <sys_unlink+0x140>
  iunlockput(dp);
    8000508a:	8526                	mv	a0,s1
    8000508c:	e48fe0ef          	jal	ra,800036d4 <iunlockput>
  ip->nlink--;  // 更新目标文件的链接计数
    80005090:	04a95783          	lhu	a5,74(s2)
    80005094:	37fd                	addiw	a5,a5,-1
    80005096:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000509a:	854a                	mv	a0,s2
    8000509c:	b80fe0ef          	jal	ra,8000341c <iupdate>
  iunlockput(ip);
    800050a0:	854a                	mv	a0,s2
    800050a2:	e32fe0ef          	jal	ra,800036d4 <iunlockput>
  end_op();
    800050a6:	e77fe0ef          	jal	ra,80003f1c <end_op>
  return 0;
    800050aa:	4501                	li	a0,0
    800050ac:	a079                	j	8000513a <sys_unlink+0x168>
    end_op();
    800050ae:	e6ffe0ef          	jal	ra,80003f1c <end_op>
    return -1;
    800050b2:	557d                	li	a0,-1
    800050b4:	a059                	j	8000513a <sys_unlink+0x168>
    panic("unlink: nlink < 1");  // 检查链接计数
    800050b6:	00002517          	auipc	a0,0x2
    800050ba:	7ea50513          	addi	a0,a0,2026 # 800078a0 <syscalls+0x2f8>
    800050be:	eccfb0ef          	jal	ra,8000078a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){  // 跳过 "." 和 ".."
    800050c2:	04c92703          	lw	a4,76(s2)
    800050c6:	02000793          	li	a5,32
    800050ca:	f8e7f9e3          	bgeu	a5,a4,8000505c <sys_unlink+0x8a>
    800050ce:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800050d2:	4741                	li	a4,16
    800050d4:	86ce                	mv	a3,s3
    800050d6:	f1840613          	addi	a2,s0,-232
    800050da:	4581                	li	a1,0
    800050dc:	854a                	mv	a0,s2
    800050de:	f7cfe0ef          	jal	ra,8000385a <readi>
    800050e2:	47c1                	li	a5,16
    800050e4:	00f51b63          	bne	a0,a5,800050fa <sys_unlink+0x128>
    if(de.inum != 0)  // 如果目录项不为空
    800050e8:	f1845783          	lhu	a5,-232(s0)
    800050ec:	ef95                	bnez	a5,80005128 <sys_unlink+0x156>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){  // 跳过 "." 和 ".."
    800050ee:	29c1                	addiw	s3,s3,16
    800050f0:	04c92783          	lw	a5,76(s2)
    800050f4:	fcf9efe3          	bltu	s3,a5,800050d2 <sys_unlink+0x100>
    800050f8:	b795                	j	8000505c <sys_unlink+0x8a>
      panic("isdirempty: readi");
    800050fa:	00002517          	auipc	a0,0x2
    800050fe:	7be50513          	addi	a0,a0,1982 # 800078b8 <syscalls+0x310>
    80005102:	e88fb0ef          	jal	ra,8000078a <panic>
    panic("unlink: writei");
    80005106:	00002517          	auipc	a0,0x2
    8000510a:	7ca50513          	addi	a0,a0,1994 # 800078d0 <syscalls+0x328>
    8000510e:	e7cfb0ef          	jal	ra,8000078a <panic>
    dp->nlink--;  // 更新父目录的链接计数
    80005112:	04a4d783          	lhu	a5,74(s1)
    80005116:	37fd                	addiw	a5,a5,-1
    80005118:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000511c:	8526                	mv	a0,s1
    8000511e:	afefe0ef          	jal	ra,8000341c <iupdate>
    80005122:	b7a5                	j	8000508a <sys_unlink+0xb8>
    return -1;
    80005124:	557d                	li	a0,-1
    80005126:	a811                	j	8000513a <sys_unlink+0x168>
    iunlockput(ip);
    80005128:	854a                	mv	a0,s2
    8000512a:	daafe0ef          	jal	ra,800036d4 <iunlockput>
  iunlockput(dp);
    8000512e:	8526                	mv	a0,s1
    80005130:	da4fe0ef          	jal	ra,800036d4 <iunlockput>
  end_op();
    80005134:	de9fe0ef          	jal	ra,80003f1c <end_op>
  return -1;
    80005138:	557d                	li	a0,-1
}
    8000513a:	70ae                	ld	ra,232(sp)
    8000513c:	740e                	ld	s0,224(sp)
    8000513e:	64ee                	ld	s1,216(sp)
    80005140:	694e                	ld	s2,208(sp)
    80005142:	69ae                	ld	s3,200(sp)
    80005144:	616d                	addi	sp,sp,240
    80005146:	8082                	ret

0000000080005148 <sys_open>:

uint64
sys_open(void)
{
    80005148:	7131                	addi	sp,sp,-192
    8000514a:	fd06                	sd	ra,184(sp)
    8000514c:	f922                	sd	s0,176(sp)
    8000514e:	f526                	sd	s1,168(sp)
    80005150:	f14a                	sd	s2,160(sp)
    80005152:	ed4e                	sd	s3,152(sp)
    80005154:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);  // 获取打开文件的模式
    80005156:	f4c40593          	addi	a1,s0,-180
    8000515a:	4505                	li	a0,1
    8000515c:	98bfd0ef          	jal	ra,80002ae6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)  // 获取路径
    80005160:	08000613          	li	a2,128
    80005164:	f5040593          	addi	a1,s0,-176
    80005168:	4501                	li	a0,0
    8000516a:	9b5fd0ef          	jal	ra,80002b1e <argstr>
    8000516e:	87aa                	mv	a5,a0
    return -1;
    80005170:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)  // 获取路径
    80005172:	0807cd63          	bltz	a5,8000520c <sys_open+0xc4>

  begin_op();
    80005176:	d37fe0ef          	jal	ra,80003eac <begin_op>

  if(omode & O_CREATE){  // 如果是创建文件
    8000517a:	f4c42783          	lw	a5,-180(s0)
    8000517e:	2007f793          	andi	a5,a5,512
    80005182:	c3c5                	beqz	a5,80005222 <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    80005184:	4681                	li	a3,0
    80005186:	4601                	li	a2,0
    80005188:	4589                	li	a1,2
    8000518a:	f5040513          	addi	a0,s0,-176
    8000518e:	ac3ff0ef          	jal	ra,80004c50 <create>
    80005192:	84aa                	mv	s1,a0
    if(ip == 0){
    80005194:	c159                	beqz	a0,8000521a <sys_open+0xd2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005196:	04449703          	lh	a4,68(s1)
    8000519a:	478d                	li	a5,3
    8000519c:	00f71763          	bne	a4,a5,800051aa <sys_open+0x62>
    800051a0:	0464d703          	lhu	a4,70(s1)
    800051a4:	47a5                	li	a5,9
    800051a6:	0ae7e963          	bltu	a5,a4,80005258 <sys_open+0x110>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){  // 分配文件描述符
    800051aa:	86cff0ef          	jal	ra,80004216 <filealloc>
    800051ae:	89aa                	mv	s3,a0
    800051b0:	0c050963          	beqz	a0,80005282 <sys_open+0x13a>
    800051b4:	a5fff0ef          	jal	ra,80004c12 <fdalloc>
    800051b8:	892a                	mv	s2,a0
    800051ba:	0c054163          	bltz	a0,8000527c <sys_open+0x134>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800051be:	04449703          	lh	a4,68(s1)
    800051c2:	478d                	li	a5,3
    800051c4:	0af70163          	beq	a4,a5,80005266 <sys_open+0x11e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800051c8:	4789                	li	a5,2
    800051ca:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800051ce:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800051d2:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800051d6:	f4c42783          	lw	a5,-180(s0)
    800051da:	0017c713          	xori	a4,a5,1
    800051de:	8b05                	andi	a4,a4,1
    800051e0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800051e4:	0037f713          	andi	a4,a5,3
    800051e8:	00e03733          	snez	a4,a4
    800051ec:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){  // 如果是 O_TRUNC 模式，截断文件
    800051f0:	4007f793          	andi	a5,a5,1024
    800051f4:	c791                	beqz	a5,80005200 <sys_open+0xb8>
    800051f6:	04449703          	lh	a4,68(s1)
    800051fa:	4789                	li	a5,2
    800051fc:	06f70c63          	beq	a4,a5,80005274 <sys_open+0x12c>
    itrunc(ip);
  }

  iunlock(ip);
    80005200:	8526                	mv	a0,s1
    80005202:	b76fe0ef          	jal	ra,80003578 <iunlock>
  end_op();
    80005206:	d17fe0ef          	jal	ra,80003f1c <end_op>

  return fd;
    8000520a:	854a                	mv	a0,s2
}
    8000520c:	70ea                	ld	ra,184(sp)
    8000520e:	744a                	ld	s0,176(sp)
    80005210:	74aa                	ld	s1,168(sp)
    80005212:	790a                	ld	s2,160(sp)
    80005214:	69ea                	ld	s3,152(sp)
    80005216:	6129                	addi	sp,sp,192
    80005218:	8082                	ret
      end_op();
    8000521a:	d03fe0ef          	jal	ra,80003f1c <end_op>
      return -1;
    8000521e:	557d                	li	a0,-1
    80005220:	b7f5                	j	8000520c <sys_open+0xc4>
    if((ip = namei(path)) == 0){
    80005222:	f5040513          	addi	a0,s0,-176
    80005226:	a97fe0ef          	jal	ra,80003cbc <namei>
    8000522a:	84aa                	mv	s1,a0
    8000522c:	c115                	beqz	a0,80005250 <sys_open+0x108>
    ilock(ip);
    8000522e:	aa0fe0ef          	jal	ra,800034ce <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){  // 不能用非读模式打开目录
    80005232:	04449703          	lh	a4,68(s1)
    80005236:	4785                	li	a5,1
    80005238:	f4f71fe3          	bne	a4,a5,80005196 <sys_open+0x4e>
    8000523c:	f4c42783          	lw	a5,-180(s0)
    80005240:	d7ad                	beqz	a5,800051aa <sys_open+0x62>
      iunlockput(ip);
    80005242:	8526                	mv	a0,s1
    80005244:	c90fe0ef          	jal	ra,800036d4 <iunlockput>
      end_op();
    80005248:	cd5fe0ef          	jal	ra,80003f1c <end_op>
      return -1;
    8000524c:	557d                	li	a0,-1
    8000524e:	bf7d                	j	8000520c <sys_open+0xc4>
      end_op();
    80005250:	ccdfe0ef          	jal	ra,80003f1c <end_op>
      return -1;
    80005254:	557d                	li	a0,-1
    80005256:	bf5d                	j	8000520c <sys_open+0xc4>
    iunlockput(ip);
    80005258:	8526                	mv	a0,s1
    8000525a:	c7afe0ef          	jal	ra,800036d4 <iunlockput>
    end_op();
    8000525e:	cbffe0ef          	jal	ra,80003f1c <end_op>
    return -1;
    80005262:	557d                	li	a0,-1
    80005264:	b765                	j	8000520c <sys_open+0xc4>
    f->type = FD_DEVICE;
    80005266:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000526a:	04649783          	lh	a5,70(s1)
    8000526e:	02f99223          	sh	a5,36(s3)
    80005272:	b785                	j	800051d2 <sys_open+0x8a>
    itrunc(ip);
    80005274:	8526                	mv	a0,s1
    80005276:	b42fe0ef          	jal	ra,800035b8 <itrunc>
    8000527a:	b759                	j	80005200 <sys_open+0xb8>
      fileclose(f);
    8000527c:	854e                	mv	a0,s3
    8000527e:	83cff0ef          	jal	ra,800042ba <fileclose>
    iunlockput(ip);
    80005282:	8526                	mv	a0,s1
    80005284:	c50fe0ef          	jal	ra,800036d4 <iunlockput>
    end_op();
    80005288:	c95fe0ef          	jal	ra,80003f1c <end_op>
    return -1;
    8000528c:	557d                	li	a0,-1
    8000528e:	bfbd                	j	8000520c <sys_open+0xc4>

0000000080005290 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005290:	7175                	addi	sp,sp,-144
    80005292:	e506                	sd	ra,136(sp)
    80005294:	e122                	sd	s0,128(sp)
    80005296:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005298:	c15fe0ef          	jal	ra,80003eac <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000529c:	08000613          	li	a2,128
    800052a0:	f7040593          	addi	a1,s0,-144
    800052a4:	4501                	li	a0,0
    800052a6:	879fd0ef          	jal	ra,80002b1e <argstr>
    800052aa:	02054363          	bltz	a0,800052d0 <sys_mkdir+0x40>
    800052ae:	4681                	li	a3,0
    800052b0:	4601                	li	a2,0
    800052b2:	4585                	li	a1,1
    800052b4:	f7040513          	addi	a0,s0,-144
    800052b8:	999ff0ef          	jal	ra,80004c50 <create>
    800052bc:	c911                	beqz	a0,800052d0 <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800052be:	c16fe0ef          	jal	ra,800036d4 <iunlockput>
  end_op();
    800052c2:	c5bfe0ef          	jal	ra,80003f1c <end_op>
  return 0;
    800052c6:	4501                	li	a0,0
}
    800052c8:	60aa                	ld	ra,136(sp)
    800052ca:	640a                	ld	s0,128(sp)
    800052cc:	6149                	addi	sp,sp,144
    800052ce:	8082                	ret
    end_op();
    800052d0:	c4dfe0ef          	jal	ra,80003f1c <end_op>
    return -1;
    800052d4:	557d                	li	a0,-1
    800052d6:	bfcd                	j	800052c8 <sys_mkdir+0x38>

00000000800052d8 <sys_mknod>:

uint64
sys_mknod(void)
{
    800052d8:	7135                	addi	sp,sp,-160
    800052da:	ed06                	sd	ra,152(sp)
    800052dc:	e922                	sd	s0,144(sp)
    800052de:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800052e0:	bcdfe0ef          	jal	ra,80003eac <begin_op>
  argint(1, &major);
    800052e4:	f6c40593          	addi	a1,s0,-148
    800052e8:	4505                	li	a0,1
    800052ea:	ffcfd0ef          	jal	ra,80002ae6 <argint>
  argint(2, &minor);
    800052ee:	f6840593          	addi	a1,s0,-152
    800052f2:	4509                	li	a0,2
    800052f4:	ff2fd0ef          	jal	ra,80002ae6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800052f8:	08000613          	li	a2,128
    800052fc:	f7040593          	addi	a1,s0,-144
    80005300:	4501                	li	a0,0
    80005302:	81dfd0ef          	jal	ra,80002b1e <argstr>
    80005306:	02054563          	bltz	a0,80005330 <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000530a:	f6841683          	lh	a3,-152(s0)
    8000530e:	f6c41603          	lh	a2,-148(s0)
    80005312:	458d                	li	a1,3
    80005314:	f7040513          	addi	a0,s0,-144
    80005318:	939ff0ef          	jal	ra,80004c50 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000531c:	c911                	beqz	a0,80005330 <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000531e:	bb6fe0ef          	jal	ra,800036d4 <iunlockput>
  end_op();
    80005322:	bfbfe0ef          	jal	ra,80003f1c <end_op>
  return 0;
    80005326:	4501                	li	a0,0
}
    80005328:	60ea                	ld	ra,152(sp)
    8000532a:	644a                	ld	s0,144(sp)
    8000532c:	610d                	addi	sp,sp,160
    8000532e:	8082                	ret
    end_op();
    80005330:	bedfe0ef          	jal	ra,80003f1c <end_op>
    return -1;
    80005334:	557d                	li	a0,-1
    80005336:	bfcd                	j	80005328 <sys_mknod+0x50>

0000000080005338 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005338:	7135                	addi	sp,sp,-160
    8000533a:	ed06                	sd	ra,152(sp)
    8000533c:	e922                	sd	s0,144(sp)
    8000533e:	e526                	sd	s1,136(sp)
    80005340:	e14a                	sd	s2,128(sp)
    80005342:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005344:	ed6fc0ef          	jal	ra,80001a1a <myproc>
    80005348:	892a                	mv	s2,a0
  
  begin_op();
    8000534a:	b63fe0ef          	jal	ra,80003eac <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000534e:	08000613          	li	a2,128
    80005352:	f6040593          	addi	a1,s0,-160
    80005356:	4501                	li	a0,0
    80005358:	fc6fd0ef          	jal	ra,80002b1e <argstr>
    8000535c:	04054163          	bltz	a0,8000539e <sys_chdir+0x66>
    80005360:	f6040513          	addi	a0,s0,-160
    80005364:	959fe0ef          	jal	ra,80003cbc <namei>
    80005368:	84aa                	mv	s1,a0
    8000536a:	c915                	beqz	a0,8000539e <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    8000536c:	962fe0ef          	jal	ra,800034ce <ilock>
  if(ip->type != T_DIR){  // 必须是目录类型
    80005370:	04449703          	lh	a4,68(s1)
    80005374:	4785                	li	a5,1
    80005376:	02f71863          	bne	a4,a5,800053a6 <sys_chdir+0x6e>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000537a:	8526                	mv	a0,s1
    8000537c:	9fcfe0ef          	jal	ra,80003578 <iunlock>
  iput(p->cwd);  // 释放当前工作目录
    80005380:	15093503          	ld	a0,336(s2)
    80005384:	ac8fe0ef          	jal	ra,8000364c <iput>
  end_op();
    80005388:	b95fe0ef          	jal	ra,80003f1c <end_op>
  p->cwd = ip;  // 更新为新的工作目录
    8000538c:	14993823          	sd	s1,336(s2)
  return 0;
    80005390:	4501                	li	a0,0
}
    80005392:	60ea                	ld	ra,152(sp)
    80005394:	644a                	ld	s0,144(sp)
    80005396:	64aa                	ld	s1,136(sp)
    80005398:	690a                	ld	s2,128(sp)
    8000539a:	610d                	addi	sp,sp,160
    8000539c:	8082                	ret
    end_op();
    8000539e:	b7ffe0ef          	jal	ra,80003f1c <end_op>
    return -1;
    800053a2:	557d                	li	a0,-1
    800053a4:	b7fd                	j	80005392 <sys_chdir+0x5a>
    iunlockput(ip);
    800053a6:	8526                	mv	a0,s1
    800053a8:	b2cfe0ef          	jal	ra,800036d4 <iunlockput>
    end_op();
    800053ac:	b71fe0ef          	jal	ra,80003f1c <end_op>
    return -1;
    800053b0:	557d                	li	a0,-1
    800053b2:	b7c5                	j	80005392 <sys_chdir+0x5a>

00000000800053b4 <sys_exec>:

uint64
sys_exec(void)
{
    800053b4:	7145                	addi	sp,sp,-464
    800053b6:	e786                	sd	ra,456(sp)
    800053b8:	e3a2                	sd	s0,448(sp)
    800053ba:	ff26                	sd	s1,440(sp)
    800053bc:	fb4a                	sd	s2,432(sp)
    800053be:	f74e                	sd	s3,424(sp)
    800053c0:	f352                	sd	s4,416(sp)
    800053c2:	ef56                	sd	s5,408(sp)
    800053c4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);  // 获取参数地址
    800053c6:	e3840593          	addi	a1,s0,-456
    800053ca:	4505                	li	a0,1
    800053cc:	f36fd0ef          	jal	ra,80002b02 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {  // 获取程序路径
    800053d0:	08000613          	li	a2,128
    800053d4:	f4040593          	addi	a1,s0,-192
    800053d8:	4501                	li	a0,0
    800053da:	f44fd0ef          	jal	ra,80002b1e <argstr>
    800053de:	87aa                	mv	a5,a0
    return -1;
    800053e0:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {  // 获取程序路径
    800053e2:	0a07c463          	bltz	a5,8000548a <sys_exec+0xd6>
  }
  memset(argv, 0, sizeof(argv));
    800053e6:	10000613          	li	a2,256
    800053ea:	4581                	li	a1,0
    800053ec:	e4040513          	addi	a0,s0,-448
    800053f0:	9d3fb0ef          	jal	ra,80000dc2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800053f4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800053f8:	89a6                	mv	s3,s1
    800053fa:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800053fc:	02000a13          	li	s4,32
    80005400:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005404:	00391793          	slli	a5,s2,0x3
    80005408:	e3040593          	addi	a1,s0,-464
    8000540c:	e3843503          	ld	a0,-456(s0)
    80005410:	953e                	add	a0,a0,a5
    80005412:	e4afd0ef          	jal	ra,80002a5c <fetchaddr>
    80005416:	02054663          	bltz	a0,80005442 <sys_exec+0x8e>
      goto bad;
    }
    if(uarg == 0){
    8000541a:	e3043783          	ld	a5,-464(s0)
    8000541e:	cf8d                	beqz	a5,80005458 <sys_exec+0xa4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005420:	fcefb0ef          	jal	ra,80000bee <kalloc>
    80005424:	85aa                	mv	a1,a0
    80005426:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000542a:	cd01                	beqz	a0,80005442 <sys_exec+0x8e>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000542c:	6605                	lui	a2,0x1
    8000542e:	e3043503          	ld	a0,-464(s0)
    80005432:	e74fd0ef          	jal	ra,80002aa6 <fetchstr>
    80005436:	00054663          	bltz	a0,80005442 <sys_exec+0x8e>
    if(i >= NELEM(argv)){
    8000543a:	0905                	addi	s2,s2,1
    8000543c:	09a1                	addi	s3,s3,8
    8000543e:	fd4911e3          	bne	s2,s4,80005400 <sys_exec+0x4c>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005442:	10048913          	addi	s2,s1,256
    80005446:	6088                	ld	a0,0(s1)
    80005448:	c121                	beqz	a0,80005488 <sys_exec+0xd4>
    kfree(argv[i]);
    8000544a:	e5efb0ef          	jal	ra,80000aa8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000544e:	04a1                	addi	s1,s1,8
    80005450:	ff249be3          	bne	s1,s2,80005446 <sys_exec+0x92>
  return -1;
    80005454:	557d                	li	a0,-1
    80005456:	a815                	j	8000548a <sys_exec+0xd6>
      argv[i] = 0;
    80005458:	0a8e                	slli	s5,s5,0x3
    8000545a:	fc040793          	addi	a5,s0,-64
    8000545e:	9abe                	add	s5,s5,a5
    80005460:	e80ab023          	sd	zero,-384(s5)
  int ret = kexec(path, argv);  // 执行程序
    80005464:	e4040593          	addi	a1,s0,-448
    80005468:	f4040513          	addi	a0,s0,-192
    8000546c:	bfaff0ef          	jal	ra,80004866 <kexec>
    80005470:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005472:	10048993          	addi	s3,s1,256
    80005476:	6088                	ld	a0,0(s1)
    80005478:	c511                	beqz	a0,80005484 <sys_exec+0xd0>
    kfree(argv[i]);
    8000547a:	e2efb0ef          	jal	ra,80000aa8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000547e:	04a1                	addi	s1,s1,8
    80005480:	ff349be3          	bne	s1,s3,80005476 <sys_exec+0xc2>
  return ret;
    80005484:	854a                	mv	a0,s2
    80005486:	a011                	j	8000548a <sys_exec+0xd6>
  return -1;
    80005488:	557d                	li	a0,-1
}
    8000548a:	60be                	ld	ra,456(sp)
    8000548c:	641e                	ld	s0,448(sp)
    8000548e:	74fa                	ld	s1,440(sp)
    80005490:	795a                	ld	s2,432(sp)
    80005492:	79ba                	ld	s3,424(sp)
    80005494:	7a1a                	ld	s4,416(sp)
    80005496:	6afa                	ld	s5,408(sp)
    80005498:	6179                	addi	sp,sp,464
    8000549a:	8082                	ret

000000008000549c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000549c:	7139                	addi	sp,sp,-64
    8000549e:	fc06                	sd	ra,56(sp)
    800054a0:	f822                	sd	s0,48(sp)
    800054a2:	f426                	sd	s1,40(sp)
    800054a4:	0080                	addi	s0,sp,64
  uint64 fdarray; // 用户指针指向两个整数的数组
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800054a6:	d74fc0ef          	jal	ra,80001a1a <myproc>
    800054aa:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);  // 获取文件描述符数组地址
    800054ac:	fd840593          	addi	a1,s0,-40
    800054b0:	4501                	li	a0,0
    800054b2:	e50fd0ef          	jal	ra,80002b02 <argaddr>
  if(pipealloc(&rf, &wf) < 0)  // 分配管道文件
    800054b6:	fc840593          	addi	a1,s0,-56
    800054ba:	fd040513          	addi	a0,s0,-48
    800054be:	8c8ff0ef          	jal	ra,80004586 <pipealloc>
    return -1;
    800054c2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)  // 分配管道文件
    800054c4:	0a054463          	bltz	a0,8000556c <sys_pipe+0xd0>
  fd0 = -1;
    800054c8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){  // 分配文件描述符
    800054cc:	fd043503          	ld	a0,-48(s0)
    800054d0:	f42ff0ef          	jal	ra,80004c12 <fdalloc>
    800054d4:	fca42223          	sw	a0,-60(s0)
    800054d8:	08054163          	bltz	a0,8000555a <sys_pipe+0xbe>
    800054dc:	fc843503          	ld	a0,-56(s0)
    800054e0:	f32ff0ef          	jal	ra,80004c12 <fdalloc>
    800054e4:	fca42023          	sw	a0,-64(s0)
    800054e8:	06054063          	bltz	a0,80005548 <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||  // 将文件描述符写入用户空间
    800054ec:	4691                	li	a3,4
    800054ee:	fc440613          	addi	a2,s0,-60
    800054f2:	fd843583          	ld	a1,-40(s0)
    800054f6:	68a8                	ld	a0,80(s1)
    800054f8:	a04fc0ef          	jal	ra,800016fc <copyout>
    800054fc:	00054e63          	bltz	a0,80005518 <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005500:	4691                	li	a3,4
    80005502:	fc040613          	addi	a2,s0,-64
    80005506:	fd843583          	ld	a1,-40(s0)
    8000550a:	0591                	addi	a1,a1,4
    8000550c:	68a8                	ld	a0,80(s1)
    8000550e:	9eefc0ef          	jal	ra,800016fc <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005512:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||  // 将文件描述符写入用户空间
    80005514:	04055c63          	bgez	a0,8000556c <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    80005518:	fc442783          	lw	a5,-60(s0)
    8000551c:	07e9                	addi	a5,a5,26
    8000551e:	078e                	slli	a5,a5,0x3
    80005520:	97a6                	add	a5,a5,s1
    80005522:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005526:	fc042503          	lw	a0,-64(s0)
    8000552a:	0569                	addi	a0,a0,26
    8000552c:	050e                	slli	a0,a0,0x3
    8000552e:	94aa                	add	s1,s1,a0
    80005530:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005534:	fd043503          	ld	a0,-48(s0)
    80005538:	d83fe0ef          	jal	ra,800042ba <fileclose>
    fileclose(wf);
    8000553c:	fc843503          	ld	a0,-56(s0)
    80005540:	d7bfe0ef          	jal	ra,800042ba <fileclose>
    return -1;
    80005544:	57fd                	li	a5,-1
    80005546:	a01d                	j	8000556c <sys_pipe+0xd0>
    if(fd0 >= 0)
    80005548:	fc442783          	lw	a5,-60(s0)
    8000554c:	0007c763          	bltz	a5,8000555a <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    80005550:	07e9                	addi	a5,a5,26
    80005552:	078e                	slli	a5,a5,0x3
    80005554:	94be                	add	s1,s1,a5
    80005556:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000555a:	fd043503          	ld	a0,-48(s0)
    8000555e:	d5dfe0ef          	jal	ra,800042ba <fileclose>
    fileclose(wf);
    80005562:	fc843503          	ld	a0,-56(s0)
    80005566:	d55fe0ef          	jal	ra,800042ba <fileclose>
    return -1;
    8000556a:	57fd                	li	a5,-1
}
    8000556c:	853e                	mv	a0,a5
    8000556e:	70e2                	ld	ra,56(sp)
    80005570:	7442                	ld	s0,48(sp)
    80005572:	74a2                	ld	s1,40(sp)
    80005574:	6121                	addi	sp,sp,64
    80005576:	8082                	ret
	...

0000000080005580 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    80005580:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    80005582:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    80005584:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80005586:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80005588:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000558a:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000558c:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    8000558e:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80005590:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80005592:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    80005594:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    80005596:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    80005598:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    8000559a:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    8000559c:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    8000559e:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    800055a0:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    800055a2:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    800055a4:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    800055a6:	b94fd0ef          	jal	ra,8000293a <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    800055aa:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    800055ac:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    800055ae:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800055b0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800055b2:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    800055b4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800055b6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800055b8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800055ba:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800055bc:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800055be:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800055c0:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800055c2:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    800055c4:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    800055c6:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    800055c8:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    800055ca:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    800055cc:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    800055ce:	10200073          	sret
	...

00000000800055de <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800055de:	1141                	addi	sp,sp,-16
    800055e0:	e422                	sd	s0,8(sp)
    800055e2:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800055e4:	0c0007b7          	lui	a5,0xc000
    800055e8:	4705                	li	a4,1
    800055ea:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800055ec:	c3d8                	sw	a4,4(a5)
}
    800055ee:	6422                	ld	s0,8(sp)
    800055f0:	0141                	addi	sp,sp,16
    800055f2:	8082                	ret

00000000800055f4 <plicinithart>:

void
plicinithart(void)
{
    800055f4:	1141                	addi	sp,sp,-16
    800055f6:	e406                	sd	ra,8(sp)
    800055f8:	e022                	sd	s0,0(sp)
    800055fa:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800055fc:	bf2fc0ef          	jal	ra,800019ee <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005600:	0085171b          	slliw	a4,a0,0x8
    80005604:	0c0027b7          	lui	a5,0xc002
    80005608:	97ba                	add	a5,a5,a4
    8000560a:	40200713          	li	a4,1026
    8000560e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005612:	00d5151b          	slliw	a0,a0,0xd
    80005616:	0c2017b7          	lui	a5,0xc201
    8000561a:	953e                	add	a0,a0,a5
    8000561c:	00052023          	sw	zero,0(a0)
}
    80005620:	60a2                	ld	ra,8(sp)
    80005622:	6402                	ld	s0,0(sp)
    80005624:	0141                	addi	sp,sp,16
    80005626:	8082                	ret

0000000080005628 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005628:	1141                	addi	sp,sp,-16
    8000562a:	e406                	sd	ra,8(sp)
    8000562c:	e022                	sd	s0,0(sp)
    8000562e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005630:	bbefc0ef          	jal	ra,800019ee <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005634:	00d5179b          	slliw	a5,a0,0xd
    80005638:	0c201537          	lui	a0,0xc201
    8000563c:	953e                	add	a0,a0,a5
  return irq;
}
    8000563e:	4148                	lw	a0,4(a0)
    80005640:	60a2                	ld	ra,8(sp)
    80005642:	6402                	ld	s0,0(sp)
    80005644:	0141                	addi	sp,sp,16
    80005646:	8082                	ret

0000000080005648 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005648:	1101                	addi	sp,sp,-32
    8000564a:	ec06                	sd	ra,24(sp)
    8000564c:	e822                	sd	s0,16(sp)
    8000564e:	e426                	sd	s1,8(sp)
    80005650:	1000                	addi	s0,sp,32
    80005652:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005654:	b9afc0ef          	jal	ra,800019ee <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005658:	00d5151b          	slliw	a0,a0,0xd
    8000565c:	0c2017b7          	lui	a5,0xc201
    80005660:	97aa                	add	a5,a5,a0
    80005662:	c3c4                	sw	s1,4(a5)
}
    80005664:	60e2                	ld	ra,24(sp)
    80005666:	6442                	ld	s0,16(sp)
    80005668:	64a2                	ld	s1,8(sp)
    8000566a:	6105                	addi	sp,sp,32
    8000566c:	8082                	ret

000000008000566e <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    8000566e:	1141                	addi	sp,sp,-16
    80005670:	e406                	sd	ra,8(sp)
    80005672:	e022                	sd	s0,0(sp)
    80005674:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005676:	479d                	li	a5,7
    80005678:	04a7ca63          	blt	a5,a0,800056cc <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    8000567c:	00023797          	auipc	a5,0x23
    80005680:	74478793          	addi	a5,a5,1860 # 80028dc0 <disk>
    80005684:	97aa                	add	a5,a5,a0
    80005686:	0187c783          	lbu	a5,24(a5)
    8000568a:	e7b9                	bnez	a5,800056d8 <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000568c:	00451613          	slli	a2,a0,0x4
    80005690:	00023797          	auipc	a5,0x23
    80005694:	73078793          	addi	a5,a5,1840 # 80028dc0 <disk>
    80005698:	6394                	ld	a3,0(a5)
    8000569a:	96b2                	add	a3,a3,a2
    8000569c:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800056a0:	6398                	ld	a4,0(a5)
    800056a2:	9732                	add	a4,a4,a2
    800056a4:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800056a8:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800056ac:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800056b0:	953e                	add	a0,a0,a5
    800056b2:	4785                	li	a5,1
    800056b4:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800056b8:	00023517          	auipc	a0,0x23
    800056bc:	72050513          	addi	a0,a0,1824 # 80028dd8 <disk+0x18>
    800056c0:	9b9fc0ef          	jal	ra,80002078 <wakeup>
}
    800056c4:	60a2                	ld	ra,8(sp)
    800056c6:	6402                	ld	s0,0(sp)
    800056c8:	0141                	addi	sp,sp,16
    800056ca:	8082                	ret
    panic("free_desc 1");
    800056cc:	00002517          	auipc	a0,0x2
    800056d0:	21450513          	addi	a0,a0,532 # 800078e0 <syscalls+0x338>
    800056d4:	8b6fb0ef          	jal	ra,8000078a <panic>
    panic("free_desc 2");
    800056d8:	00002517          	auipc	a0,0x2
    800056dc:	21850513          	addi	a0,a0,536 # 800078f0 <syscalls+0x348>
    800056e0:	8aafb0ef          	jal	ra,8000078a <panic>

00000000800056e4 <virtio_disk_init>:
{
    800056e4:	1101                	addi	sp,sp,-32
    800056e6:	ec06                	sd	ra,24(sp)
    800056e8:	e822                	sd	s0,16(sp)
    800056ea:	e426                	sd	s1,8(sp)
    800056ec:	e04a                	sd	s2,0(sp)
    800056ee:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800056f0:	00002597          	auipc	a1,0x2
    800056f4:	21058593          	addi	a1,a1,528 # 80007900 <syscalls+0x358>
    800056f8:	00023517          	auipc	a0,0x23
    800056fc:	7f050513          	addi	a0,a0,2032 # 80028ee8 <disk+0x128>
    80005700:	d6efb0ef          	jal	ra,80000c6e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005704:	100017b7          	lui	a5,0x10001
    80005708:	4398                	lw	a4,0(a5)
    8000570a:	2701                	sext.w	a4,a4
    8000570c:	747277b7          	lui	a5,0x74727
    80005710:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005714:	14f71063          	bne	a4,a5,80005854 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005718:	100017b7          	lui	a5,0x10001
    8000571c:	43dc                	lw	a5,4(a5)
    8000571e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005720:	4709                	li	a4,2
    80005722:	12e79963          	bne	a5,a4,80005854 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005726:	100017b7          	lui	a5,0x10001
    8000572a:	479c                	lw	a5,8(a5)
    8000572c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000572e:	12e79363          	bne	a5,a4,80005854 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005732:	100017b7          	lui	a5,0x10001
    80005736:	47d8                	lw	a4,12(a5)
    80005738:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000573a:	554d47b7          	lui	a5,0x554d4
    8000573e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005742:	10f71963          	bne	a4,a5,80005854 <virtio_disk_init+0x170>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005746:	100017b7          	lui	a5,0x10001
    8000574a:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000574e:	4705                	li	a4,1
    80005750:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005752:	470d                	li	a4,3
    80005754:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005756:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005758:	c7ffe737          	lui	a4,0xc7ffe
    8000575c:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd585f>
    80005760:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005762:	2701                	sext.w	a4,a4
    80005764:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005766:	472d                	li	a4,11
    80005768:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    8000576a:	5bbc                	lw	a5,112(a5)
    8000576c:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005770:	8ba1                	andi	a5,a5,8
    80005772:	0e078763          	beqz	a5,80005860 <virtio_disk_init+0x17c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005776:	100017b7          	lui	a5,0x10001
    8000577a:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    8000577e:	43fc                	lw	a5,68(a5)
    80005780:	2781                	sext.w	a5,a5
    80005782:	0e079563          	bnez	a5,8000586c <virtio_disk_init+0x188>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005786:	100017b7          	lui	a5,0x10001
    8000578a:	5bdc                	lw	a5,52(a5)
    8000578c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000578e:	0e078563          	beqz	a5,80005878 <virtio_disk_init+0x194>
  if(max < NUM)
    80005792:	471d                	li	a4,7
    80005794:	0ef77863          	bgeu	a4,a5,80005884 <virtio_disk_init+0x1a0>
  disk.desc = kalloc();
    80005798:	c56fb0ef          	jal	ra,80000bee <kalloc>
    8000579c:	00023497          	auipc	s1,0x23
    800057a0:	62448493          	addi	s1,s1,1572 # 80028dc0 <disk>
    800057a4:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800057a6:	c48fb0ef          	jal	ra,80000bee <kalloc>
    800057aa:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800057ac:	c42fb0ef          	jal	ra,80000bee <kalloc>
    800057b0:	87aa                	mv	a5,a0
    800057b2:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800057b4:	6088                	ld	a0,0(s1)
    800057b6:	cd69                	beqz	a0,80005890 <virtio_disk_init+0x1ac>
    800057b8:	00023717          	auipc	a4,0x23
    800057bc:	61073703          	ld	a4,1552(a4) # 80028dc8 <disk+0x8>
    800057c0:	cb61                	beqz	a4,80005890 <virtio_disk_init+0x1ac>
    800057c2:	c7f9                	beqz	a5,80005890 <virtio_disk_init+0x1ac>
  memset(disk.desc, 0, PGSIZE);
    800057c4:	6605                	lui	a2,0x1
    800057c6:	4581                	li	a1,0
    800057c8:	dfafb0ef          	jal	ra,80000dc2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800057cc:	00023497          	auipc	s1,0x23
    800057d0:	5f448493          	addi	s1,s1,1524 # 80028dc0 <disk>
    800057d4:	6605                	lui	a2,0x1
    800057d6:	4581                	li	a1,0
    800057d8:	6488                	ld	a0,8(s1)
    800057da:	de8fb0ef          	jal	ra,80000dc2 <memset>
  memset(disk.used, 0, PGSIZE);
    800057de:	6605                	lui	a2,0x1
    800057e0:	4581                	li	a1,0
    800057e2:	6888                	ld	a0,16(s1)
    800057e4:	ddefb0ef          	jal	ra,80000dc2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800057e8:	100017b7          	lui	a5,0x10001
    800057ec:	4721                	li	a4,8
    800057ee:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800057f0:	4098                	lw	a4,0(s1)
    800057f2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800057f6:	40d8                	lw	a4,4(s1)
    800057f8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800057fc:	6498                	ld	a4,8(s1)
    800057fe:	0007069b          	sext.w	a3,a4
    80005802:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005806:	9701                	srai	a4,a4,0x20
    80005808:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000580c:	6898                	ld	a4,16(s1)
    8000580e:	0007069b          	sext.w	a3,a4
    80005812:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005816:	9701                	srai	a4,a4,0x20
    80005818:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000581c:	4705                	li	a4,1
    8000581e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005820:	00e48c23          	sb	a4,24(s1)
    80005824:	00e48ca3          	sb	a4,25(s1)
    80005828:	00e48d23          	sb	a4,26(s1)
    8000582c:	00e48da3          	sb	a4,27(s1)
    80005830:	00e48e23          	sb	a4,28(s1)
    80005834:	00e48ea3          	sb	a4,29(s1)
    80005838:	00e48f23          	sb	a4,30(s1)
    8000583c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005840:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005844:	0727a823          	sw	s2,112(a5)
}
    80005848:	60e2                	ld	ra,24(sp)
    8000584a:	6442                	ld	s0,16(sp)
    8000584c:	64a2                	ld	s1,8(sp)
    8000584e:	6902                	ld	s2,0(sp)
    80005850:	6105                	addi	sp,sp,32
    80005852:	8082                	ret
    panic("could not find virtio disk");
    80005854:	00002517          	auipc	a0,0x2
    80005858:	0bc50513          	addi	a0,a0,188 # 80007910 <syscalls+0x368>
    8000585c:	f2ffa0ef          	jal	ra,8000078a <panic>
    panic("virtio disk FEATURES_OK unset");
    80005860:	00002517          	auipc	a0,0x2
    80005864:	0d050513          	addi	a0,a0,208 # 80007930 <syscalls+0x388>
    80005868:	f23fa0ef          	jal	ra,8000078a <panic>
    panic("virtio disk should not be ready");
    8000586c:	00002517          	auipc	a0,0x2
    80005870:	0e450513          	addi	a0,a0,228 # 80007950 <syscalls+0x3a8>
    80005874:	f17fa0ef          	jal	ra,8000078a <panic>
    panic("virtio disk has no queue 0");
    80005878:	00002517          	auipc	a0,0x2
    8000587c:	0f850513          	addi	a0,a0,248 # 80007970 <syscalls+0x3c8>
    80005880:	f0bfa0ef          	jal	ra,8000078a <panic>
    panic("virtio disk max queue too short");
    80005884:	00002517          	auipc	a0,0x2
    80005888:	10c50513          	addi	a0,a0,268 # 80007990 <syscalls+0x3e8>
    8000588c:	efffa0ef          	jal	ra,8000078a <panic>
    panic("virtio disk kalloc");
    80005890:	00002517          	auipc	a0,0x2
    80005894:	12050513          	addi	a0,a0,288 # 800079b0 <syscalls+0x408>
    80005898:	ef3fa0ef          	jal	ra,8000078a <panic>

000000008000589c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000589c:	7119                	addi	sp,sp,-128
    8000589e:	fc86                	sd	ra,120(sp)
    800058a0:	f8a2                	sd	s0,112(sp)
    800058a2:	f4a6                	sd	s1,104(sp)
    800058a4:	f0ca                	sd	s2,96(sp)
    800058a6:	ecce                	sd	s3,88(sp)
    800058a8:	e8d2                	sd	s4,80(sp)
    800058aa:	e4d6                	sd	s5,72(sp)
    800058ac:	e0da                	sd	s6,64(sp)
    800058ae:	fc5e                	sd	s7,56(sp)
    800058b0:	f862                	sd	s8,48(sp)
    800058b2:	f466                	sd	s9,40(sp)
    800058b4:	f06a                	sd	s10,32(sp)
    800058b6:	ec6e                	sd	s11,24(sp)
    800058b8:	0100                	addi	s0,sp,128
    800058ba:	8aaa                	mv	s5,a0
    800058bc:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800058be:	00c52d03          	lw	s10,12(a0)
    800058c2:	001d1d1b          	slliw	s10,s10,0x1
    800058c6:	1d02                	slli	s10,s10,0x20
    800058c8:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800058cc:	00023517          	auipc	a0,0x23
    800058d0:	61c50513          	addi	a0,a0,1564 # 80028ee8 <disk+0x128>
    800058d4:	c1afb0ef          	jal	ra,80000cee <acquire>
  for(int i = 0; i < 3; i++){
    800058d8:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800058da:	44a1                	li	s1,8
      disk.free[i] = 0;
    800058dc:	00023b97          	auipc	s7,0x23
    800058e0:	4e4b8b93          	addi	s7,s7,1252 # 80028dc0 <disk>
  for(int i = 0; i < 3; i++){
    800058e4:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800058e6:	00023c97          	auipc	s9,0x23
    800058ea:	602c8c93          	addi	s9,s9,1538 # 80028ee8 <disk+0x128>
    800058ee:	a8a9                	j	80005948 <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    800058f0:	00fb8733          	add	a4,s7,a5
    800058f4:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800058f8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800058fa:	0207c563          	bltz	a5,80005924 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800058fe:	2905                	addiw	s2,s2,1
    80005900:	0611                	addi	a2,a2,4
    80005902:	05690863          	beq	s2,s6,80005952 <virtio_disk_rw+0xb6>
    idx[i] = alloc_desc();
    80005906:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005908:	00023717          	auipc	a4,0x23
    8000590c:	4b870713          	addi	a4,a4,1208 # 80028dc0 <disk>
    80005910:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005912:	01874683          	lbu	a3,24(a4)
    80005916:	fee9                	bnez	a3,800058f0 <virtio_disk_rw+0x54>
  for(int i = 0; i < NUM; i++){
    80005918:	2785                	addiw	a5,a5,1
    8000591a:	0705                	addi	a4,a4,1
    8000591c:	fe979be3          	bne	a5,s1,80005912 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005920:	57fd                	li	a5,-1
    80005922:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005924:	01205b63          	blez	s2,8000593a <virtio_disk_rw+0x9e>
    80005928:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000592a:	000a2503          	lw	a0,0(s4)
    8000592e:	d41ff0ef          	jal	ra,8000566e <free_desc>
      for(int j = 0; j < i; j++)
    80005932:	2d85                	addiw	s11,s11,1
    80005934:	0a11                	addi	s4,s4,4
    80005936:	ffb91ae3          	bne	s2,s11,8000592a <virtio_disk_rw+0x8e>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000593a:	85e6                	mv	a1,s9
    8000593c:	00023517          	auipc	a0,0x23
    80005940:	49c50513          	addi	a0,a0,1180 # 80028dd8 <disk+0x18>
    80005944:	ee8fc0ef          	jal	ra,8000202c <sleep>
  for(int i = 0; i < 3; i++){
    80005948:	f8040a13          	addi	s4,s0,-128
{
    8000594c:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000594e:	894e                	mv	s2,s3
    80005950:	bf5d                	j	80005906 <virtio_disk_rw+0x6a>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005952:	f8042583          	lw	a1,-128(s0)
    80005956:	00a58793          	addi	a5,a1,10
    8000595a:	0792                	slli	a5,a5,0x4

  if(write)
    8000595c:	00023617          	auipc	a2,0x23
    80005960:	46460613          	addi	a2,a2,1124 # 80028dc0 <disk>
    80005964:	00f60733          	add	a4,a2,a5
    80005968:	018036b3          	snez	a3,s8
    8000596c:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000596e:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80005972:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005976:	f6078693          	addi	a3,a5,-160
    8000597a:	6218                	ld	a4,0(a2)
    8000597c:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000597e:	00878513          	addi	a0,a5,8
    80005982:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005984:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005986:	6208                	ld	a0,0(a2)
    80005988:	96aa                	add	a3,a3,a0
    8000598a:	4741                	li	a4,16
    8000598c:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000598e:	4705                	li	a4,1
    80005990:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80005994:	f8442703          	lw	a4,-124(s0)
    80005998:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    8000599c:	0712                	slli	a4,a4,0x4
    8000599e:	953a                	add	a0,a0,a4
    800059a0:	058a8693          	addi	a3,s5,88
    800059a4:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800059a6:	6208                	ld	a0,0(a2)
    800059a8:	972a                	add	a4,a4,a0
    800059aa:	40000693          	li	a3,1024
    800059ae:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800059b0:	001c3c13          	seqz	s8,s8
    800059b4:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800059b6:	001c6c13          	ori	s8,s8,1
    800059ba:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800059be:	f8842603          	lw	a2,-120(s0)
    800059c2:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800059c6:	00023697          	auipc	a3,0x23
    800059ca:	3fa68693          	addi	a3,a3,1018 # 80028dc0 <disk>
    800059ce:	00258713          	addi	a4,a1,2
    800059d2:	0712                	slli	a4,a4,0x4
    800059d4:	9736                	add	a4,a4,a3
    800059d6:	587d                	li	a6,-1
    800059d8:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800059dc:	0612                	slli	a2,a2,0x4
    800059de:	9532                	add	a0,a0,a2
    800059e0:	f9078793          	addi	a5,a5,-112
    800059e4:	97b6                	add	a5,a5,a3
    800059e6:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800059e8:	629c                	ld	a5,0(a3)
    800059ea:	97b2                	add	a5,a5,a2
    800059ec:	4605                	li	a2,1
    800059ee:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800059f0:	4509                	li	a0,2
    800059f2:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800059f6:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800059fa:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800059fe:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005a02:	6698                	ld	a4,8(a3)
    80005a04:	00275783          	lhu	a5,2(a4)
    80005a08:	8b9d                	andi	a5,a5,7
    80005a0a:	0786                	slli	a5,a5,0x1
    80005a0c:	97ba                	add	a5,a5,a4
    80005a0e:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80005a12:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005a16:	6698                	ld	a4,8(a3)
    80005a18:	00275783          	lhu	a5,2(a4)
    80005a1c:	2785                	addiw	a5,a5,1
    80005a1e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005a22:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005a26:	100017b7          	lui	a5,0x10001
    80005a2a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005a2e:	004aa783          	lw	a5,4(s5)
    80005a32:	00c79f63          	bne	a5,a2,80005a50 <virtio_disk_rw+0x1b4>
    sleep(b, &disk.vdisk_lock);
    80005a36:	00023917          	auipc	s2,0x23
    80005a3a:	4b290913          	addi	s2,s2,1202 # 80028ee8 <disk+0x128>
  while(b->disk == 1) {
    80005a3e:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005a40:	85ca                	mv	a1,s2
    80005a42:	8556                	mv	a0,s5
    80005a44:	de8fc0ef          	jal	ra,8000202c <sleep>
  while(b->disk == 1) {
    80005a48:	004aa783          	lw	a5,4(s5)
    80005a4c:	fe978ae3          	beq	a5,s1,80005a40 <virtio_disk_rw+0x1a4>
  }

  disk.info[idx[0]].b = 0;
    80005a50:	f8042903          	lw	s2,-128(s0)
    80005a54:	00290793          	addi	a5,s2,2
    80005a58:	00479713          	slli	a4,a5,0x4
    80005a5c:	00023797          	auipc	a5,0x23
    80005a60:	36478793          	addi	a5,a5,868 # 80028dc0 <disk>
    80005a64:	97ba                	add	a5,a5,a4
    80005a66:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80005a6a:	00023997          	auipc	s3,0x23
    80005a6e:	35698993          	addi	s3,s3,854 # 80028dc0 <disk>
    80005a72:	00491713          	slli	a4,s2,0x4
    80005a76:	0009b783          	ld	a5,0(s3)
    80005a7a:	97ba                	add	a5,a5,a4
    80005a7c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005a80:	854a                	mv	a0,s2
    80005a82:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005a86:	be9ff0ef          	jal	ra,8000566e <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80005a8a:	8885                	andi	s1,s1,1
    80005a8c:	f0fd                	bnez	s1,80005a72 <virtio_disk_rw+0x1d6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005a8e:	00023517          	auipc	a0,0x23
    80005a92:	45a50513          	addi	a0,a0,1114 # 80028ee8 <disk+0x128>
    80005a96:	af0fb0ef          	jal	ra,80000d86 <release>
}
    80005a9a:	70e6                	ld	ra,120(sp)
    80005a9c:	7446                	ld	s0,112(sp)
    80005a9e:	74a6                	ld	s1,104(sp)
    80005aa0:	7906                	ld	s2,96(sp)
    80005aa2:	69e6                	ld	s3,88(sp)
    80005aa4:	6a46                	ld	s4,80(sp)
    80005aa6:	6aa6                	ld	s5,72(sp)
    80005aa8:	6b06                	ld	s6,64(sp)
    80005aaa:	7be2                	ld	s7,56(sp)
    80005aac:	7c42                	ld	s8,48(sp)
    80005aae:	7ca2                	ld	s9,40(sp)
    80005ab0:	7d02                	ld	s10,32(sp)
    80005ab2:	6de2                	ld	s11,24(sp)
    80005ab4:	6109                	addi	sp,sp,128
    80005ab6:	8082                	ret

0000000080005ab8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80005ab8:	1101                	addi	sp,sp,-32
    80005aba:	ec06                	sd	ra,24(sp)
    80005abc:	e822                	sd	s0,16(sp)
    80005abe:	e426                	sd	s1,8(sp)
    80005ac0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80005ac2:	00023497          	auipc	s1,0x23
    80005ac6:	2fe48493          	addi	s1,s1,766 # 80028dc0 <disk>
    80005aca:	00023517          	auipc	a0,0x23
    80005ace:	41e50513          	addi	a0,a0,1054 # 80028ee8 <disk+0x128>
    80005ad2:	a1cfb0ef          	jal	ra,80000cee <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80005ad6:	10001737          	lui	a4,0x10001
    80005ada:	533c                	lw	a5,96(a4)
    80005adc:	8b8d                	andi	a5,a5,3
    80005ade:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80005ae0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80005ae4:	689c                	ld	a5,16(s1)
    80005ae6:	0204d703          	lhu	a4,32(s1)
    80005aea:	0027d783          	lhu	a5,2(a5)
    80005aee:	04f70663          	beq	a4,a5,80005b3a <virtio_disk_intr+0x82>
    __sync_synchronize();
    80005af2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80005af6:	6898                	ld	a4,16(s1)
    80005af8:	0204d783          	lhu	a5,32(s1)
    80005afc:	8b9d                	andi	a5,a5,7
    80005afe:	078e                	slli	a5,a5,0x3
    80005b00:	97ba                	add	a5,a5,a4
    80005b02:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005b04:	00278713          	addi	a4,a5,2
    80005b08:	0712                	slli	a4,a4,0x4
    80005b0a:	9726                	add	a4,a4,s1
    80005b0c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80005b10:	e321                	bnez	a4,80005b50 <virtio_disk_intr+0x98>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005b12:	0789                	addi	a5,a5,2
    80005b14:	0792                	slli	a5,a5,0x4
    80005b16:	97a6                	add	a5,a5,s1
    80005b18:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80005b1a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80005b1e:	d5afc0ef          	jal	ra,80002078 <wakeup>

    disk.used_idx += 1;
    80005b22:	0204d783          	lhu	a5,32(s1)
    80005b26:	2785                	addiw	a5,a5,1
    80005b28:	17c2                	slli	a5,a5,0x30
    80005b2a:	93c1                	srli	a5,a5,0x30
    80005b2c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005b30:	6898                	ld	a4,16(s1)
    80005b32:	00275703          	lhu	a4,2(a4)
    80005b36:	faf71ee3          	bne	a4,a5,80005af2 <virtio_disk_intr+0x3a>
  }

  release(&disk.vdisk_lock);
    80005b3a:	00023517          	auipc	a0,0x23
    80005b3e:	3ae50513          	addi	a0,a0,942 # 80028ee8 <disk+0x128>
    80005b42:	a44fb0ef          	jal	ra,80000d86 <release>
}
    80005b46:	60e2                	ld	ra,24(sp)
    80005b48:	6442                	ld	s0,16(sp)
    80005b4a:	64a2                	ld	s1,8(sp)
    80005b4c:	6105                	addi	sp,sp,32
    80005b4e:	8082                	ret
      panic("virtio_disk_intr status");
    80005b50:	00002517          	auipc	a0,0x2
    80005b54:	e7850513          	addi	a0,a0,-392 # 800079c8 <syscalls+0x420>
    80005b58:	c33fa0ef          	jal	ra,8000078a <panic>
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
