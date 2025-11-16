
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
    8000010a:	2b2020ef          	jal	ra,800023bc <either_copyin>
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
    800001a4:	061010ef          	jal	ra,80001a04 <myproc>
    800001a8:	0a6020ef          	jal	ra,8000224e <killed>
    800001ac:	e125                	bnez	a0,8000020c <consoleread+0xc0>
      sleep(&cons.r, &cons.lock);
    800001ae:	85a6                	mv	a1,s1
    800001b0:	854a                	mv	a0,s2
    800001b2:	665010ef          	jal	ra,80002016 <sleep>
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
    800001ea:	188020ef          	jal	ra,80002372 <either_copyout>
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
    800002aa:	15c020ef          	jal	ra,80002406 <procdump>
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
    800003e6:	47d010ef          	jal	ra,80002062 <wakeup>
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
    80000892:	784010ef          	jal	ra,80002016 <sleep>
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
    800009a0:	6c2010ef          	jal	ra,80002062 <wakeup>
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
    80000c98:	551000ef          	jal	ra,800019e8 <mycpu>
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
    80000cc6:	523000ef          	jal	ra,800019e8 <mycpu>
    80000cca:	5d3c                	lw	a5,120(a0)
    80000ccc:	cb99                	beqz	a5,80000ce2 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cce:	51b000ef          	jal	ra,800019e8 <mycpu>
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
    80000ce2:	507000ef          	jal	ra,800019e8 <mycpu>
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
    80000d16:	4d3000ef          	jal	ra,800019e8 <mycpu>
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
    80000d3a:	4af000ef          	jal	ra,800019e8 <mycpu>
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
    80000f6c:	26d000ef          	jal	ra,800019d8 <cpuid>
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
    80000f84:	255000ef          	jal	ra,800019d8 <cpuid>
    80000f88:	85aa                	mv	a1,a0
    80000f8a:	00006517          	auipc	a0,0x6
    80000f8e:	14650513          	addi	a0,a0,326 # 800070d0 <digits+0x98>
    80000f92:	d32ff0ef          	jal	ra,800004c4 <printf>
    kvminithart();    // turn on paging
    80000f96:	080000ef          	jal	ra,80001016 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f9a:	636010ef          	jal	ra,800025d0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f9e:	646040ef          	jal	ra,800055e4 <plicinithart>
  }

  scheduler();        
    80000fa2:	6dd000ef          	jal	ra,80001e7e <scheduler>
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
    80000fde:	153000ef          	jal	ra,80001930 <procinit>
    trapinit();      // trap vectors
    80000fe2:	5ca010ef          	jal	ra,800025ac <trapinit>
    trapinithart();  // install kernel trap vector
    80000fe6:	5ea010ef          	jal	ra,800025d0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fea:	5e4040ef          	jal	ra,800055ce <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fee:	5f6040ef          	jal	ra,800055e4 <plicinithart>
    binit();         // buffer cache
    80000ff2:	58f010ef          	jal	ra,80002d80 <binit>
    iinit();         // inode table
    80000ff6:	302020ef          	jal	ra,800032f8 <iinit>
    fileinit();      // file table
    80000ffa:	1e2030ef          	jal	ra,800041dc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ffe:	6d6040ef          	jal	ra,800056d4 <virtio_disk_init>
    userinit();      // first user process
    80001002:	4d3000ef          	jal	ra,80001cd4 <userinit>
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
    80001294:	612000ef          	jal	ra,800018a6 <proc_mapstacks>
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

00000000800015ba <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;
  pte_t *pte;
  while(len > 0){
    800015ba:	0e068a63          	beqz	a3,800016ae <copyout+0xf4>
{
    800015be:	711d                	addi	sp,sp,-96
    800015c0:	ec86                	sd	ra,88(sp)
    800015c2:	e8a2                	sd	s0,80(sp)
    800015c4:	e4a6                	sd	s1,72(sp)
    800015c6:	e0ca                	sd	s2,64(sp)
    800015c8:	fc4e                	sd	s3,56(sp)
    800015ca:	f852                	sd	s4,48(sp)
    800015cc:	f456                	sd	s5,40(sp)
    800015ce:	f05a                	sd	s6,32(sp)
    800015d0:	ec5e                	sd	s7,24(sp)
    800015d2:	e862                	sd	s8,16(sp)
    800015d4:	e466                	sd	s9,8(sp)
    800015d6:	1080                	addi	s0,sp,96
    800015d8:	8baa                	mv	s7,a0
    800015da:	8aae                	mv	s5,a1
    800015dc:	8b32                	mv	s6,a2
    800015de:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    800015e0:	74fd                	lui	s1,0xfffff
    800015e2:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA){
    800015e4:	57fd                	li	a5,-1
    800015e6:	83e9                	srli	a5,a5,0x1a
    800015e8:	0c97e563          	bltu	a5,s1,800016b2 <copyout+0xf8>
    800015ec:	8c3e                	mv	s8,a5
    800015ee:	a889                	j	80001640 <copyout+0x86>
    if(*pte & PTE_COW){
      //printf("copyout(): got page COW faults at %p\n", va0);
      char *mem;
      if((mem = kalloc()) == 0)
      {
        printf("copyout(): memery alloc fault\n");
    800015f0:	00006517          	auipc	a0,0x6
    800015f4:	c1050513          	addi	a0,a0,-1008 # 80007200 <digits+0x1c8>
    800015f8:	ecdfe0ef          	jal	ra,800004c4 <printf>
        return -1;
    800015fc:	557d                	li	a0,-1
    800015fe:	a87d                	j	800016bc <copyout+0x102>
        if(mappages(pagetable, va0, PGSIZE, (uint64)mem, perm) != 0){
          printf("copyout(): can not map page\n");
          kfree(mem); 
          return -1;
        }
        kfree((void*) pa);
    80001600:	8566                	mv	a0,s9
    80001602:	ca6ff0ef          	jal	ra,80000aa8 <kfree>
      }
    }
    pa0 = walkaddr(pagetable, va0);
    80001606:	85a6                	mv	a1,s1
    80001608:	855e                	mv	a0,s7
    8000160a:	acfff0ef          	jal	ra,800010d8 <walkaddr>
    if(pa0 == 0)
    8000160e:	c555                	beqz	a0,800016ba <copyout+0x100>
      return -1;
    n = PGSIZE - (dstva - va0);
    80001610:	6905                	lui	s2,0x1
    80001612:	9926                	add	s2,s2,s1
    80001614:	415909b3          	sub	s3,s2,s5
    if(n > len)
    80001618:	013a7363          	bgeu	s4,s3,8000161e <copyout+0x64>
    8000161c:	89d2                	mv	s3,s4
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000161e:	409a84b3          	sub	s1,s5,s1
    80001622:	0009861b          	sext.w	a2,s3
    80001626:	85da                	mv	a1,s6
    80001628:	9526                	add	a0,a0,s1
    8000162a:	ff4ff0ef          	jal	ra,80000e1e <memmove>

    len -= n;
    8000162e:	413a0a33          	sub	s4,s4,s3
    src += n;
    80001632:	9b4e                	add	s6,s6,s3
  while(len > 0){
    80001634:	060a0b63          	beqz	s4,800016aa <copyout+0xf0>
    if(va0 >= MAXVA){
    80001638:	072c6f63          	bltu	s8,s2,800016b6 <copyout+0xfc>
    va0 = PGROUNDDOWN(dstva);
    8000163c:	84ca                	mv	s1,s2
    dstva = va0 + PGSIZE;
    8000163e:	8aca                	mv	s5,s2
    pte = walk(pagetable, va0, 0);
    80001640:	4601                	li	a2,0
    80001642:	85a6                	mv	a1,s1
    80001644:	855e                	mv	a0,s7
    80001646:	9f9ff0ef          	jal	ra,8000103e <walk>
    8000164a:	892a                	mv	s2,a0
    if(*pte & PTE_COW){
    8000164c:	611c                	ld	a5,0(a0)
    8000164e:	1007f793          	andi	a5,a5,256
    80001652:	dbd5                	beqz	a5,80001606 <copyout+0x4c>
      if((mem = kalloc()) == 0)
    80001654:	d9aff0ef          	jal	ra,80000bee <kalloc>
    80001658:	89aa                	mv	s3,a0
    8000165a:	d959                	beqz	a0,800015f0 <copyout+0x36>
      memset(mem, 0, sizeof(mem));
    8000165c:	4621                	li	a2,8
    8000165e:	4581                	li	a1,0
    80001660:	f62ff0ef          	jal	ra,80000dc2 <memset>
      uint64 pa = walkaddr(pagetable, va0);
    80001664:	85a6                	mv	a1,s1
    80001666:	855e                	mv	a0,s7
    80001668:	a71ff0ef          	jal	ra,800010d8 <walkaddr>
    8000166c:	8caa                	mv	s9,a0
      if(pa){
    8000166e:	dd41                	beqz	a0,80001606 <copyout+0x4c>
        memmove(mem, (char*)pa, PGSIZE);
    80001670:	6605                	lui	a2,0x1
    80001672:	85aa                	mv	a1,a0
    80001674:	854e                	mv	a0,s3
    80001676:	fa8ff0ef          	jal	ra,80000e1e <memmove>
        int perm = PTE_FLAGS(*pte);
    8000167a:	00093703          	ld	a4,0(s2) # 1000 <_entry-0x7ffff000>
        perm &= ~PTE_COW;
    8000167e:	2ff77713          	andi	a4,a4,767
        if(mappages(pagetable, va0, PGSIZE, (uint64)mem, perm) != 0){
    80001682:	00476713          	ori	a4,a4,4
    80001686:	86ce                	mv	a3,s3
    80001688:	6605                	lui	a2,0x1
    8000168a:	85a6                	mv	a1,s1
    8000168c:	855e                	mv	a0,s7
    8000168e:	a89ff0ef          	jal	ra,80001116 <mappages>
    80001692:	d53d                	beqz	a0,80001600 <copyout+0x46>
          printf("copyout(): can not map page\n");
    80001694:	00006517          	auipc	a0,0x6
    80001698:	b8c50513          	addi	a0,a0,-1140 # 80007220 <digits+0x1e8>
    8000169c:	e29fe0ef          	jal	ra,800004c4 <printf>
          kfree(mem); 
    800016a0:	854e                	mv	a0,s3
    800016a2:	c06ff0ef          	jal	ra,80000aa8 <kfree>
          return -1;
    800016a6:	557d                	li	a0,-1
    800016a8:	a811                	j	800016bc <copyout+0x102>
  }
  return 0;
    800016aa:	4501                	li	a0,0
    800016ac:	a801                	j	800016bc <copyout+0x102>
    800016ae:	4501                	li	a0,0
}
    800016b0:	8082                	ret
      return -1;
    800016b2:	557d                	li	a0,-1
    800016b4:	a021                	j	800016bc <copyout+0x102>
    800016b6:	557d                	li	a0,-1
    800016b8:	a011                	j	800016bc <copyout+0x102>
      return -1;
    800016ba:	557d                	li	a0,-1
}
    800016bc:	60e6                	ld	ra,88(sp)
    800016be:	6446                	ld	s0,80(sp)
    800016c0:	64a6                	ld	s1,72(sp)
    800016c2:	6906                	ld	s2,64(sp)
    800016c4:	79e2                	ld	s3,56(sp)
    800016c6:	7a42                	ld	s4,48(sp)
    800016c8:	7aa2                	ld	s5,40(sp)
    800016ca:	7b02                	ld	s6,32(sp)
    800016cc:	6be2                	ld	s7,24(sp)
    800016ce:	6c42                	ld	s8,16(sp)
    800016d0:	6ca2                	ld	s9,8(sp)
    800016d2:	6125                	addi	sp,sp,96
    800016d4:	8082                	ret

00000000800016d6 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800016d6:	c2d5                	beqz	a3,8000177a <copyinstr+0xa4>
{
    800016d8:	715d                	addi	sp,sp,-80
    800016da:	e486                	sd	ra,72(sp)
    800016dc:	e0a2                	sd	s0,64(sp)
    800016de:	fc26                	sd	s1,56(sp)
    800016e0:	f84a                	sd	s2,48(sp)
    800016e2:	f44e                	sd	s3,40(sp)
    800016e4:	f052                	sd	s4,32(sp)
    800016e6:	ec56                	sd	s5,24(sp)
    800016e8:	e85a                	sd	s6,16(sp)
    800016ea:	e45e                	sd	s7,8(sp)
    800016ec:	0880                	addi	s0,sp,80
    800016ee:	8a2a                	mv	s4,a0
    800016f0:	8b2e                	mv	s6,a1
    800016f2:	8bb2                	mv	s7,a2
    800016f4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800016f6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016f8:	6985                	lui	s3,0x1
    800016fa:	a035                	j	80001726 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800016fc:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001700:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001702:	0017b793          	seqz	a5,a5
    80001706:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000170a:	60a6                	ld	ra,72(sp)
    8000170c:	6406                	ld	s0,64(sp)
    8000170e:	74e2                	ld	s1,56(sp)
    80001710:	7942                	ld	s2,48(sp)
    80001712:	79a2                	ld	s3,40(sp)
    80001714:	7a02                	ld	s4,32(sp)
    80001716:	6ae2                	ld	s5,24(sp)
    80001718:	6b42                	ld	s6,16(sp)
    8000171a:	6ba2                	ld	s7,8(sp)
    8000171c:	6161                	addi	sp,sp,80
    8000171e:	8082                	ret
    srcva = va0 + PGSIZE;
    80001720:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001724:	c4b9                	beqz	s1,80001772 <copyinstr+0x9c>
    va0 = PGROUNDDOWN(srcva);
    80001726:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000172a:	85ca                	mv	a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	9abff0ef          	jal	ra,800010d8 <walkaddr>
    if(pa0 == 0)
    80001732:	c131                	beqz	a0,80001776 <copyinstr+0xa0>
    n = PGSIZE - (srcva - va0);
    80001734:	41790833          	sub	a6,s2,s7
    80001738:	984e                	add	a6,a6,s3
    if(n > max)
    8000173a:	0104f363          	bgeu	s1,a6,80001740 <copyinstr+0x6a>
    8000173e:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001740:	955e                	add	a0,a0,s7
    80001742:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001746:	fc080de3          	beqz	a6,80001720 <copyinstr+0x4a>
    8000174a:	985a                	add	a6,a6,s6
    8000174c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000174e:	41650633          	sub	a2,a0,s6
    80001752:	14fd                	addi	s1,s1,-1
    80001754:	9b26                	add	s6,s6,s1
    80001756:	00f60733          	add	a4,a2,a5
    8000175a:	00074703          	lbu	a4,0(a4)
    8000175e:	df59                	beqz	a4,800016fc <copyinstr+0x26>
        *dst = *p;
    80001760:	00e78023          	sb	a4,0(a5)
      --max;
    80001764:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001768:	0785                	addi	a5,a5,1
    while(n > 0){
    8000176a:	ff0796e3          	bne	a5,a6,80001756 <copyinstr+0x80>
      dst++;
    8000176e:	8b42                	mv	s6,a6
    80001770:	bf45                	j	80001720 <copyinstr+0x4a>
    80001772:	4781                	li	a5,0
    80001774:	b779                	j	80001702 <copyinstr+0x2c>
      return -1;
    80001776:	557d                	li	a0,-1
    80001778:	bf49                	j	8000170a <copyinstr+0x34>
  int got_null = 0;
    8000177a:	4781                	li	a5,0
  if(got_null){
    8000177c:	0017b793          	seqz	a5,a5
    80001780:	40f00533          	neg	a0,a5
}
    80001784:	8082                	ret

0000000080001786 <ismapped>:
  return mem;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
    80001786:	1141                	addi	sp,sp,-16
    80001788:	e406                	sd	ra,8(sp)
    8000178a:	e022                	sd	s0,0(sp)
    8000178c:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    8000178e:	4601                	li	a2,0
    80001790:	8afff0ef          	jal	ra,8000103e <walk>
  if (pte == 0) {
    80001794:	c519                	beqz	a0,800017a2 <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    80001796:	6108                	ld	a0,0(a0)
    return 0;
    80001798:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    8000179a:	60a2                	ld	ra,8(sp)
    8000179c:	6402                	ld	s0,0(sp)
    8000179e:	0141                	addi	sp,sp,16
    800017a0:	8082                	ret
    return 0;
    800017a2:	4501                	li	a0,0
    800017a4:	bfdd                	j	8000179a <ismapped+0x14>

00000000800017a6 <vmfault>:
{
    800017a6:	7179                	addi	sp,sp,-48
    800017a8:	f406                	sd	ra,40(sp)
    800017aa:	f022                	sd	s0,32(sp)
    800017ac:	ec26                	sd	s1,24(sp)
    800017ae:	e84a                	sd	s2,16(sp)
    800017b0:	e44e                	sd	s3,8(sp)
    800017b2:	e052                	sd	s4,0(sp)
    800017b4:	1800                	addi	s0,sp,48
    800017b6:	89aa                	mv	s3,a0
    800017b8:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    800017ba:	24a000ef          	jal	ra,80001a04 <myproc>
  if (va >= p->sz)
    800017be:	653c                	ld	a5,72(a0)
    800017c0:	00f4ec63          	bltu	s1,a5,800017d8 <vmfault+0x32>
    return 0;
    800017c4:	4981                	li	s3,0
}
    800017c6:	854e                	mv	a0,s3
    800017c8:	70a2                	ld	ra,40(sp)
    800017ca:	7402                	ld	s0,32(sp)
    800017cc:	64e2                	ld	s1,24(sp)
    800017ce:	6942                	ld	s2,16(sp)
    800017d0:	69a2                	ld	s3,8(sp)
    800017d2:	6a02                	ld	s4,0(sp)
    800017d4:	6145                	addi	sp,sp,48
    800017d6:	8082                	ret
    800017d8:	892a                	mv	s2,a0
  va = PGROUNDDOWN(va);
    800017da:	75fd                	lui	a1,0xfffff
    800017dc:	8ced                	and	s1,s1,a1
  if(ismapped(pagetable, va)) {
    800017de:	85a6                	mv	a1,s1
    800017e0:	854e                	mv	a0,s3
    800017e2:	fa5ff0ef          	jal	ra,80001786 <ismapped>
    return 0;
    800017e6:	4981                	li	s3,0
  if(ismapped(pagetable, va)) {
    800017e8:	fd79                	bnez	a0,800017c6 <vmfault+0x20>
  mem = (uint64) kalloc();
    800017ea:	c04ff0ef          	jal	ra,80000bee <kalloc>
    800017ee:	8a2a                	mv	s4,a0
  if(mem == 0)
    800017f0:	d979                	beqz	a0,800017c6 <vmfault+0x20>
  mem = (uint64) kalloc();
    800017f2:	89aa                	mv	s3,a0
  memset((void *) mem, 0, PGSIZE);
    800017f4:	6605                	lui	a2,0x1
    800017f6:	4581                	li	a1,0
    800017f8:	dcaff0ef          	jal	ra,80000dc2 <memset>
  if (mappages(p->pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    800017fc:	4759                	li	a4,22
    800017fe:	86d2                	mv	a3,s4
    80001800:	6605                	lui	a2,0x1
    80001802:	85a6                	mv	a1,s1
    80001804:	05093503          	ld	a0,80(s2)
    80001808:	90fff0ef          	jal	ra,80001116 <mappages>
    8000180c:	dd4d                	beqz	a0,800017c6 <vmfault+0x20>
    kfree((void *)mem);
    8000180e:	8552                	mv	a0,s4
    80001810:	a98ff0ef          	jal	ra,80000aa8 <kfree>
    return 0;
    80001814:	4981                	li	s3,0
    80001816:	bf45                	j	800017c6 <vmfault+0x20>

0000000080001818 <copyin>:
  while(len > 0){
    80001818:	c6c9                	beqz	a3,800018a2 <copyin+0x8a>
{
    8000181a:	715d                	addi	sp,sp,-80
    8000181c:	e486                	sd	ra,72(sp)
    8000181e:	e0a2                	sd	s0,64(sp)
    80001820:	fc26                	sd	s1,56(sp)
    80001822:	f84a                	sd	s2,48(sp)
    80001824:	f44e                	sd	s3,40(sp)
    80001826:	f052                	sd	s4,32(sp)
    80001828:	ec56                	sd	s5,24(sp)
    8000182a:	e85a                	sd	s6,16(sp)
    8000182c:	e45e                	sd	s7,8(sp)
    8000182e:	e062                	sd	s8,0(sp)
    80001830:	0880                	addi	s0,sp,80
    80001832:	8baa                	mv	s7,a0
    80001834:	8aae                	mv	s5,a1
    80001836:	8932                	mv	s2,a2
    80001838:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    8000183a:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    8000183c:	6b05                	lui	s6,0x1
    8000183e:	a035                	j	8000186a <copyin+0x52>
    80001840:	412984b3          	sub	s1,s3,s2
    80001844:	94da                	add	s1,s1,s6
    if(n > len)
    80001846:	009a7363          	bgeu	s4,s1,8000184c <copyin+0x34>
    8000184a:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000184c:	413905b3          	sub	a1,s2,s3
    80001850:	0004861b          	sext.w	a2,s1
    80001854:	95aa                	add	a1,a1,a0
    80001856:	8556                	mv	a0,s5
    80001858:	dc6ff0ef          	jal	ra,80000e1e <memmove>
    len -= n;
    8000185c:	409a0a33          	sub	s4,s4,s1
    dst += n;
    80001860:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001862:	01698933          	add	s2,s3,s6
  while(len > 0){
    80001866:	020a0163          	beqz	s4,80001888 <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    8000186a:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    8000186e:	85ce                	mv	a1,s3
    80001870:	855e                	mv	a0,s7
    80001872:	867ff0ef          	jal	ra,800010d8 <walkaddr>
    if(pa0 == 0) {
    80001876:	f569                	bnez	a0,80001840 <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001878:	4601                	li	a2,0
    8000187a:	85ce                	mv	a1,s3
    8000187c:	855e                	mv	a0,s7
    8000187e:	f29ff0ef          	jal	ra,800017a6 <vmfault>
    80001882:	fd5d                	bnez	a0,80001840 <copyin+0x28>
        return -1;
    80001884:	557d                	li	a0,-1
    80001886:	a011                	j	8000188a <copyin+0x72>
  return 0;
    80001888:	4501                	li	a0,0
}
    8000188a:	60a6                	ld	ra,72(sp)
    8000188c:	6406                	ld	s0,64(sp)
    8000188e:	74e2                	ld	s1,56(sp)
    80001890:	7942                	ld	s2,48(sp)
    80001892:	79a2                	ld	s3,40(sp)
    80001894:	7a02                	ld	s4,32(sp)
    80001896:	6ae2                	ld	s5,24(sp)
    80001898:	6b42                	ld	s6,16(sp)
    8000189a:	6ba2                	ld	s7,8(sp)
    8000189c:	6c02                	ld	s8,0(sp)
    8000189e:	6161                	addi	sp,sp,80
    800018a0:	8082                	ret
  return 0;
    800018a2:	4501                	li	a0,0
}
    800018a4:	8082                	ret

00000000800018a6 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    800018a6:	7139                	addi	sp,sp,-64
    800018a8:	fc06                	sd	ra,56(sp)
    800018aa:	f822                	sd	s0,48(sp)
    800018ac:	f426                	sd	s1,40(sp)
    800018ae:	f04a                	sd	s2,32(sp)
    800018b0:	ec4e                	sd	s3,24(sp)
    800018b2:	e852                	sd	s4,16(sp)
    800018b4:	e456                	sd	s5,8(sp)
    800018b6:	e05a                	sd	s6,0(sp)
    800018b8:	0080                	addi	s0,sp,64
    800018ba:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018bc:	00016497          	auipc	s1,0x16
    800018c0:	66448493          	addi	s1,s1,1636 # 80017f20 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018c4:	8b26                	mv	s6,s1
    800018c6:	00005a97          	auipc	s5,0x5
    800018ca:	73aa8a93          	addi	s5,s5,1850 # 80007000 <etext>
    800018ce:	04000937          	lui	s2,0x4000
    800018d2:	197d                	addi	s2,s2,-1
    800018d4:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018d6:	0001ca17          	auipc	s4,0x1c
    800018da:	24aa0a13          	addi	s4,s4,586 # 8001db20 <tickslock>
    char *pa = kalloc();
    800018de:	b10ff0ef          	jal	ra,80000bee <kalloc>
    800018e2:	862a                	mv	a2,a0
    if(pa == 0)
    800018e4:	c121                	beqz	a0,80001924 <proc_mapstacks+0x7e>
    uint64 va = KSTACK((int) (p - proc));
    800018e6:	416485b3          	sub	a1,s1,s6
    800018ea:	8591                	srai	a1,a1,0x4
    800018ec:	000ab783          	ld	a5,0(s5)
    800018f0:	02f585b3          	mul	a1,a1,a5
    800018f4:	2585                	addiw	a1,a1,1
    800018f6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018fa:	4719                	li	a4,6
    800018fc:	6685                	lui	a3,0x1
    800018fe:	40b905b3          	sub	a1,s2,a1
    80001902:	854e                	mv	a0,s3
    80001904:	8c9ff0ef          	jal	ra,800011cc <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001908:	17048493          	addi	s1,s1,368
    8000190c:	fd4499e3          	bne	s1,s4,800018de <proc_mapstacks+0x38>
  }
}
    80001910:	70e2                	ld	ra,56(sp)
    80001912:	7442                	ld	s0,48(sp)
    80001914:	74a2                	ld	s1,40(sp)
    80001916:	7902                	ld	s2,32(sp)
    80001918:	69e2                	ld	s3,24(sp)
    8000191a:	6a42                	ld	s4,16(sp)
    8000191c:	6aa2                	ld	s5,8(sp)
    8000191e:	6b02                	ld	s6,0(sp)
    80001920:	6121                	addi	sp,sp,64
    80001922:	8082                	ret
      panic("kalloc");
    80001924:	00006517          	auipc	a0,0x6
    80001928:	91c50513          	addi	a0,a0,-1764 # 80007240 <digits+0x208>
    8000192c:	e5ffe0ef          	jal	ra,8000078a <panic>

0000000080001930 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001930:	7139                	addi	sp,sp,-64
    80001932:	fc06                	sd	ra,56(sp)
    80001934:	f822                	sd	s0,48(sp)
    80001936:	f426                	sd	s1,40(sp)
    80001938:	f04a                	sd	s2,32(sp)
    8000193a:	ec4e                	sd	s3,24(sp)
    8000193c:	e852                	sd	s4,16(sp)
    8000193e:	e456                	sd	s5,8(sp)
    80001940:	e05a                	sd	s6,0(sp)
    80001942:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001944:	00006597          	auipc	a1,0x6
    80001948:	90458593          	addi	a1,a1,-1788 # 80007248 <digits+0x210>
    8000194c:	00016517          	auipc	a0,0x16
    80001950:	1a450513          	addi	a0,a0,420 # 80017af0 <pid_lock>
    80001954:	b1aff0ef          	jal	ra,80000c6e <initlock>
  initlock(&wait_lock, "wait_lock");
    80001958:	00006597          	auipc	a1,0x6
    8000195c:	8f858593          	addi	a1,a1,-1800 # 80007250 <digits+0x218>
    80001960:	00016517          	auipc	a0,0x16
    80001964:	1a850513          	addi	a0,a0,424 # 80017b08 <wait_lock>
    80001968:	b06ff0ef          	jal	ra,80000c6e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196c:	00016497          	auipc	s1,0x16
    80001970:	5b448493          	addi	s1,s1,1460 # 80017f20 <proc>
      initlock(&p->lock, "proc");
    80001974:	00006b17          	auipc	s6,0x6
    80001978:	8ecb0b13          	addi	s6,s6,-1812 # 80007260 <digits+0x228>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000197c:	8aa6                	mv	s5,s1
    8000197e:	00005a17          	auipc	s4,0x5
    80001982:	682a0a13          	addi	s4,s4,1666 # 80007000 <etext>
    80001986:	04000937          	lui	s2,0x4000
    8000198a:	197d                	addi	s2,s2,-1
    8000198c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000198e:	0001c997          	auipc	s3,0x1c
    80001992:	19298993          	addi	s3,s3,402 # 8001db20 <tickslock>
      initlock(&p->lock, "proc");
    80001996:	85da                	mv	a1,s6
    80001998:	8526                	mv	a0,s1
    8000199a:	ad4ff0ef          	jal	ra,80000c6e <initlock>
      p->state = UNUSED;
    8000199e:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800019a2:	415487b3          	sub	a5,s1,s5
    800019a6:	8791                	srai	a5,a5,0x4
    800019a8:	000a3703          	ld	a4,0(s4)
    800019ac:	02e787b3          	mul	a5,a5,a4
    800019b0:	2785                	addiw	a5,a5,1
    800019b2:	00d7979b          	slliw	a5,a5,0xd
    800019b6:	40f907b3          	sub	a5,s2,a5
    800019ba:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019bc:	17048493          	addi	s1,s1,368
    800019c0:	fd349be3          	bne	s1,s3,80001996 <procinit+0x66>
  }
}
    800019c4:	70e2                	ld	ra,56(sp)
    800019c6:	7442                	ld	s0,48(sp)
    800019c8:	74a2                	ld	s1,40(sp)
    800019ca:	7902                	ld	s2,32(sp)
    800019cc:	69e2                	ld	s3,24(sp)
    800019ce:	6a42                	ld	s4,16(sp)
    800019d0:	6aa2                	ld	s5,8(sp)
    800019d2:	6b02                	ld	s6,0(sp)
    800019d4:	6121                	addi	sp,sp,64
    800019d6:	8082                	ret

00000000800019d8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019d8:	1141                	addi	sp,sp,-16
    800019da:	e422                	sd	s0,8(sp)
    800019dc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019de:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019e0:	2501                	sext.w	a0,a0
    800019e2:	6422                	ld	s0,8(sp)
    800019e4:	0141                	addi	sp,sp,16
    800019e6:	8082                	ret

00000000800019e8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e422                	sd	s0,8(sp)
    800019ec:	0800                	addi	s0,sp,16
    800019ee:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019f0:	2781                	sext.w	a5,a5
    800019f2:	079e                	slli	a5,a5,0x7
  return c;
}
    800019f4:	00016517          	auipc	a0,0x16
    800019f8:	12c50513          	addi	a0,a0,300 # 80017b20 <cpus>
    800019fc:	953e                	add	a0,a0,a5
    800019fe:	6422                	ld	s0,8(sp)
    80001a00:	0141                	addi	sp,sp,16
    80001a02:	8082                	ret

0000000080001a04 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001a04:	1101                	addi	sp,sp,-32
    80001a06:	ec06                	sd	ra,24(sp)
    80001a08:	e822                	sd	s0,16(sp)
    80001a0a:	e426                	sd	s1,8(sp)
    80001a0c:	1000                	addi	s0,sp,32
  push_off();
    80001a0e:	aa0ff0ef          	jal	ra,80000cae <push_off>
    80001a12:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a14:	2781                	sext.w	a5,a5
    80001a16:	079e                	slli	a5,a5,0x7
    80001a18:	00016717          	auipc	a4,0x16
    80001a1c:	0d870713          	addi	a4,a4,216 # 80017af0 <pid_lock>
    80001a20:	97ba                	add	a5,a5,a4
    80001a22:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a24:	b0eff0ef          	jal	ra,80000d32 <pop_off>
  return p;
}
    80001a28:	8526                	mv	a0,s1
    80001a2a:	60e2                	ld	ra,24(sp)
    80001a2c:	6442                	ld	s0,16(sp)
    80001a2e:	64a2                	ld	s1,8(sp)
    80001a30:	6105                	addi	sp,sp,32
    80001a32:	8082                	ret

0000000080001a34 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a34:	7179                	addi	sp,sp,-48
    80001a36:	f406                	sd	ra,40(sp)
    80001a38:	f022                	sd	s0,32(sp)
    80001a3a:	ec26                	sd	s1,24(sp)
    80001a3c:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    80001a3e:	fc7ff0ef          	jal	ra,80001a04 <myproc>
    80001a42:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    80001a44:	b42ff0ef          	jal	ra,80000d86 <release>

  if (first) {
    80001a48:	00006797          	auipc	a5,0x6
    80001a4c:	f987a783          	lw	a5,-104(a5) # 800079e0 <first.1>
    80001a50:	cf8d                	beqz	a5,80001a8a <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    80001a52:	4505                	li	a0,1
    80001a54:	555010ef          	jal	ra,800037a8 <fsinit>

    first = 0;
    80001a58:	00006797          	auipc	a5,0x6
    80001a5c:	f807a423          	sw	zero,-120(a5) # 800079e0 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    80001a60:	0ff0000f          	fence

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    80001a64:	00006517          	auipc	a0,0x6
    80001a68:	80450513          	addi	a0,a0,-2044 # 80007268 <digits+0x230>
    80001a6c:	fca43823          	sd	a0,-48(s0)
    80001a70:	fc043c23          	sd	zero,-40(s0)
    80001a74:	fd040593          	addi	a1,s0,-48
    80001a78:	5d9020ef          	jal	ra,80004850 <kexec>
    80001a7c:	6cbc                	ld	a5,88(s1)
    80001a7e:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    80001a80:	6cbc                	ld	a5,88(s1)
    80001a82:	7bb8                	ld	a4,112(a5)
    80001a84:	57fd                	li	a5,-1
    80001a86:	02f70d63          	beq	a4,a5,80001ac0 <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    80001a8a:	35f000ef          	jal	ra,800025e8 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80001a8e:	68a8                	ld	a0,80(s1)
    80001a90:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80001a92:	04000737          	lui	a4,0x4000
    80001a96:	00004797          	auipc	a5,0x4
    80001a9a:	60678793          	addi	a5,a5,1542 # 8000609c <userret>
    80001a9e:	00004697          	auipc	a3,0x4
    80001aa2:	56268693          	addi	a3,a3,1378 # 80006000 <_trampoline>
    80001aa6:	8f95                	sub	a5,a5,a3
    80001aa8:	177d                	addi	a4,a4,-1
    80001aaa:	0732                	slli	a4,a4,0xc
    80001aac:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80001aae:	577d                	li	a4,-1
    80001ab0:	177e                	slli	a4,a4,0x3f
    80001ab2:	8d59                	or	a0,a0,a4
    80001ab4:	9782                	jalr	a5
}
    80001ab6:	70a2                	ld	ra,40(sp)
    80001ab8:	7402                	ld	s0,32(sp)
    80001aba:	64e2                	ld	s1,24(sp)
    80001abc:	6145                	addi	sp,sp,48
    80001abe:	8082                	ret
      panic("exec");
    80001ac0:	00005517          	auipc	a0,0x5
    80001ac4:	7b050513          	addi	a0,a0,1968 # 80007270 <digits+0x238>
    80001ac8:	cc3fe0ef          	jal	ra,8000078a <panic>

0000000080001acc <allocpid>:
{
    80001acc:	1101                	addi	sp,sp,-32
    80001ace:	ec06                	sd	ra,24(sp)
    80001ad0:	e822                	sd	s0,16(sp)
    80001ad2:	e426                	sd	s1,8(sp)
    80001ad4:	e04a                	sd	s2,0(sp)
    80001ad6:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ad8:	00016917          	auipc	s2,0x16
    80001adc:	01890913          	addi	s2,s2,24 # 80017af0 <pid_lock>
    80001ae0:	854a                	mv	a0,s2
    80001ae2:	a0cff0ef          	jal	ra,80000cee <acquire>
  pid = nextpid;
    80001ae6:	00006797          	auipc	a5,0x6
    80001aea:	efe78793          	addi	a5,a5,-258 # 800079e4 <nextpid>
    80001aee:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001af0:	0014871b          	addiw	a4,s1,1
    80001af4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001af6:	854a                	mv	a0,s2
    80001af8:	a8eff0ef          	jal	ra,80000d86 <release>
}
    80001afc:	8526                	mv	a0,s1
    80001afe:	60e2                	ld	ra,24(sp)
    80001b00:	6442                	ld	s0,16(sp)
    80001b02:	64a2                	ld	s1,8(sp)
    80001b04:	6902                	ld	s2,0(sp)
    80001b06:	6105                	addi	sp,sp,32
    80001b08:	8082                	ret

0000000080001b0a <proc_pagetable>:
{
    80001b0a:	1101                	addi	sp,sp,-32
    80001b0c:	ec06                	sd	ra,24(sp)
    80001b0e:	e822                	sd	s0,16(sp)
    80001b10:	e426                	sd	s1,8(sp)
    80001b12:	e04a                	sd	s2,0(sp)
    80001b14:	1000                	addi	s0,sp,32
    80001b16:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b18:	faaff0ef          	jal	ra,800012c2 <uvmcreate>
    80001b1c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b1e:	cd05                	beqz	a0,80001b56 <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b20:	4729                	li	a4,10
    80001b22:	00004697          	auipc	a3,0x4
    80001b26:	4de68693          	addi	a3,a3,1246 # 80006000 <_trampoline>
    80001b2a:	6605                	lui	a2,0x1
    80001b2c:	040005b7          	lui	a1,0x4000
    80001b30:	15fd                	addi	a1,a1,-1
    80001b32:	05b2                	slli	a1,a1,0xc
    80001b34:	de2ff0ef          	jal	ra,80001116 <mappages>
    80001b38:	02054663          	bltz	a0,80001b64 <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b3c:	4719                	li	a4,6
    80001b3e:	05893683          	ld	a3,88(s2)
    80001b42:	6605                	lui	a2,0x1
    80001b44:	020005b7          	lui	a1,0x2000
    80001b48:	15fd                	addi	a1,a1,-1
    80001b4a:	05b6                	slli	a1,a1,0xd
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	dc8ff0ef          	jal	ra,80001116 <mappages>
    80001b52:	00054f63          	bltz	a0,80001b70 <proc_pagetable+0x66>
}
    80001b56:	8526                	mv	a0,s1
    80001b58:	60e2                	ld	ra,24(sp)
    80001b5a:	6442                	ld	s0,16(sp)
    80001b5c:	64a2                	ld	s1,8(sp)
    80001b5e:	6902                	ld	s2,0(sp)
    80001b60:	6105                	addi	sp,sp,32
    80001b62:	8082                	ret
    uvmfree(pagetable, 0);
    80001b64:	4581                	li	a1,0
    80001b66:	8526                	mv	a0,s1
    80001b68:	939ff0ef          	jal	ra,800014a0 <uvmfree>
    return 0;
    80001b6c:	4481                	li	s1,0
    80001b6e:	b7e5                	j	80001b56 <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b70:	4681                	li	a3,0
    80001b72:	4605                	li	a2,1
    80001b74:	040005b7          	lui	a1,0x4000
    80001b78:	15fd                	addi	a1,a1,-1
    80001b7a:	05b2                	slli	a1,a1,0xc
    80001b7c:	8526                	mv	a0,s1
    80001b7e:	f6aff0ef          	jal	ra,800012e8 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b82:	4581                	li	a1,0
    80001b84:	8526                	mv	a0,s1
    80001b86:	91bff0ef          	jal	ra,800014a0 <uvmfree>
    return 0;
    80001b8a:	4481                	li	s1,0
    80001b8c:	b7e9                	j	80001b56 <proc_pagetable+0x4c>

0000000080001b8e <proc_freepagetable>:
{
    80001b8e:	1101                	addi	sp,sp,-32
    80001b90:	ec06                	sd	ra,24(sp)
    80001b92:	e822                	sd	s0,16(sp)
    80001b94:	e426                	sd	s1,8(sp)
    80001b96:	e04a                	sd	s2,0(sp)
    80001b98:	1000                	addi	s0,sp,32
    80001b9a:	84aa                	mv	s1,a0
    80001b9c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b9e:	4681                	li	a3,0
    80001ba0:	4605                	li	a2,1
    80001ba2:	040005b7          	lui	a1,0x4000
    80001ba6:	15fd                	addi	a1,a1,-1
    80001ba8:	05b2                	slli	a1,a1,0xc
    80001baa:	f3eff0ef          	jal	ra,800012e8 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bae:	4681                	li	a3,0
    80001bb0:	4605                	li	a2,1
    80001bb2:	020005b7          	lui	a1,0x2000
    80001bb6:	15fd                	addi	a1,a1,-1
    80001bb8:	05b6                	slli	a1,a1,0xd
    80001bba:	8526                	mv	a0,s1
    80001bbc:	f2cff0ef          	jal	ra,800012e8 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bc0:	85ca                	mv	a1,s2
    80001bc2:	8526                	mv	a0,s1
    80001bc4:	8ddff0ef          	jal	ra,800014a0 <uvmfree>
}
    80001bc8:	60e2                	ld	ra,24(sp)
    80001bca:	6442                	ld	s0,16(sp)
    80001bcc:	64a2                	ld	s1,8(sp)
    80001bce:	6902                	ld	s2,0(sp)
    80001bd0:	6105                	addi	sp,sp,32
    80001bd2:	8082                	ret

0000000080001bd4 <freeproc>:
{
    80001bd4:	1101                	addi	sp,sp,-32
    80001bd6:	ec06                	sd	ra,24(sp)
    80001bd8:	e822                	sd	s0,16(sp)
    80001bda:	e426                	sd	s1,8(sp)
    80001bdc:	1000                	addi	s0,sp,32
    80001bde:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001be0:	6d28                	ld	a0,88(a0)
    80001be2:	c119                	beqz	a0,80001be8 <freeproc+0x14>
    kfree((void*)p->trapframe);
    80001be4:	ec5fe0ef          	jal	ra,80000aa8 <kfree>
  p->trapframe = 0;
    80001be8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bec:	68a8                	ld	a0,80(s1)
    80001bee:	c501                	beqz	a0,80001bf6 <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001bf0:	64ac                	ld	a1,72(s1)
    80001bf2:	f9dff0ef          	jal	ra,80001b8e <proc_freepagetable>
  p->pagetable = 0;
    80001bf6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bfa:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bfe:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c02:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c06:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c0a:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c0e:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c12:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c16:	0004ac23          	sw	zero,24(s1)
}
    80001c1a:	60e2                	ld	ra,24(sp)
    80001c1c:	6442                	ld	s0,16(sp)
    80001c1e:	64a2                	ld	s1,8(sp)
    80001c20:	6105                	addi	sp,sp,32
    80001c22:	8082                	ret

0000000080001c24 <allocproc>:
{
    80001c24:	1101                	addi	sp,sp,-32
    80001c26:	ec06                	sd	ra,24(sp)
    80001c28:	e822                	sd	s0,16(sp)
    80001c2a:	e426                	sd	s1,8(sp)
    80001c2c:	e04a                	sd	s2,0(sp)
    80001c2e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c30:	00016497          	auipc	s1,0x16
    80001c34:	2f048493          	addi	s1,s1,752 # 80017f20 <proc>
    80001c38:	0001c917          	auipc	s2,0x1c
    80001c3c:	ee890913          	addi	s2,s2,-280 # 8001db20 <tickslock>
    acquire(&p->lock);
    80001c40:	8526                	mv	a0,s1
    80001c42:	8acff0ef          	jal	ra,80000cee <acquire>
    if(p->state == UNUSED) {
    80001c46:	4c9c                	lw	a5,24(s1)
    80001c48:	cb91                	beqz	a5,80001c5c <allocproc+0x38>
      release(&p->lock);
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	93aff0ef          	jal	ra,80000d86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c50:	17048493          	addi	s1,s1,368
    80001c54:	ff2496e3          	bne	s1,s2,80001c40 <allocproc+0x1c>
  return 0;
    80001c58:	4481                	li	s1,0
    80001c5a:	a0b1                	j	80001ca6 <allocproc+0x82>
  p->pid = allocpid();
    80001c5c:	e71ff0ef          	jal	ra,80001acc <allocpid>
    80001c60:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c62:	4785                	li	a5,1
    80001c64:	cc9c                	sw	a5,24(s1)
  p->ticks = 0;
    80001c66:	1604a423          	sw	zero,360(s1)
  p->timeslice =5;
    80001c6a:	4795                	li	a5,5
    80001c6c:	16f4a623          	sw	a5,364(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c70:	f7ffe0ef          	jal	ra,80000bee <kalloc>
    80001c74:	892a                	mv	s2,a0
    80001c76:	eca8                	sd	a0,88(s1)
    80001c78:	cd15                	beqz	a0,80001cb4 <allocproc+0x90>
  p->pagetable = proc_pagetable(p);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	e8fff0ef          	jal	ra,80001b0a <proc_pagetable>
    80001c80:	892a                	mv	s2,a0
    80001c82:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c84:	c121                	beqz	a0,80001cc4 <allocproc+0xa0>
  memset(&p->context, 0, sizeof(p->context));
    80001c86:	07000613          	li	a2,112
    80001c8a:	4581                	li	a1,0
    80001c8c:	06048513          	addi	a0,s1,96
    80001c90:	932ff0ef          	jal	ra,80000dc2 <memset>
  p->context.ra = (uint64)forkret;
    80001c94:	00000797          	auipc	a5,0x0
    80001c98:	da078793          	addi	a5,a5,-608 # 80001a34 <forkret>
    80001c9c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c9e:	60bc                	ld	a5,64(s1)
    80001ca0:	6705                	lui	a4,0x1
    80001ca2:	97ba                	add	a5,a5,a4
    80001ca4:	f4bc                	sd	a5,104(s1)
}
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	60e2                	ld	ra,24(sp)
    80001caa:	6442                	ld	s0,16(sp)
    80001cac:	64a2                	ld	s1,8(sp)
    80001cae:	6902                	ld	s2,0(sp)
    80001cb0:	6105                	addi	sp,sp,32
    80001cb2:	8082                	ret
    freeproc(p);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	f1fff0ef          	jal	ra,80001bd4 <freeproc>
    release(&p->lock);
    80001cba:	8526                	mv	a0,s1
    80001cbc:	8caff0ef          	jal	ra,80000d86 <release>
    return 0;
    80001cc0:	84ca                	mv	s1,s2
    80001cc2:	b7d5                	j	80001ca6 <allocproc+0x82>
    freeproc(p);
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	f0fff0ef          	jal	ra,80001bd4 <freeproc>
    release(&p->lock);
    80001cca:	8526                	mv	a0,s1
    80001ccc:	8baff0ef          	jal	ra,80000d86 <release>
    return 0;
    80001cd0:	84ca                	mv	s1,s2
    80001cd2:	bfd1                	j	80001ca6 <allocproc+0x82>

0000000080001cd4 <userinit>:
{
    80001cd4:	1101                	addi	sp,sp,-32
    80001cd6:	ec06                	sd	ra,24(sp)
    80001cd8:	e822                	sd	s0,16(sp)
    80001cda:	e426                	sd	s1,8(sp)
    80001cdc:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cde:	f47ff0ef          	jal	ra,80001c24 <allocproc>
    80001ce2:	84aa                	mv	s1,a0
  initproc = p;
    80001ce4:	00006797          	auipc	a5,0x6
    80001ce8:	d2a7b623          	sd	a0,-724(a5) # 80007a10 <initproc>
  p->cwd = namei("/");
    80001cec:	00005517          	auipc	a0,0x5
    80001cf0:	58c50513          	addi	a0,a0,1420 # 80007278 <digits+0x240>
    80001cf4:	7b3010ef          	jal	ra,80003ca6 <namei>
    80001cf8:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cfc:	478d                	li	a5,3
    80001cfe:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d00:	8526                	mv	a0,s1
    80001d02:	884ff0ef          	jal	ra,80000d86 <release>
}
    80001d06:	60e2                	ld	ra,24(sp)
    80001d08:	6442                	ld	s0,16(sp)
    80001d0a:	64a2                	ld	s1,8(sp)
    80001d0c:	6105                	addi	sp,sp,32
    80001d0e:	8082                	ret

0000000080001d10 <growproc>:
{
    80001d10:	1101                	addi	sp,sp,-32
    80001d12:	ec06                	sd	ra,24(sp)
    80001d14:	e822                	sd	s0,16(sp)
    80001d16:	e426                	sd	s1,8(sp)
    80001d18:	e04a                	sd	s2,0(sp)
    80001d1a:	1000                	addi	s0,sp,32
    80001d1c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d1e:	ce7ff0ef          	jal	ra,80001a04 <myproc>
    80001d22:	892a                	mv	s2,a0
  sz = p->sz;
    80001d24:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d26:	02905963          	blez	s1,80001d58 <growproc+0x48>
    if(sz + n > TRAPFRAME) {
    80001d2a:	00b48633          	add	a2,s1,a1
    80001d2e:	020007b7          	lui	a5,0x2000
    80001d32:	17fd                	addi	a5,a5,-1
    80001d34:	07b6                	slli	a5,a5,0xd
    80001d36:	02c7ea63          	bltu	a5,a2,80001d6a <growproc+0x5a>
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d3a:	4691                	li	a3,4
    80001d3c:	6928                	ld	a0,80(a0)
    80001d3e:	e6aff0ef          	jal	ra,800013a8 <uvmalloc>
    80001d42:	85aa                	mv	a1,a0
    80001d44:	c50d                	beqz	a0,80001d6e <growproc+0x5e>
  p->sz = sz;
    80001d46:	04b93423          	sd	a1,72(s2)
  return 0;
    80001d4a:	4501                	li	a0,0
}
    80001d4c:	60e2                	ld	ra,24(sp)
    80001d4e:	6442                	ld	s0,16(sp)
    80001d50:	64a2                	ld	s1,8(sp)
    80001d52:	6902                	ld	s2,0(sp)
    80001d54:	6105                	addi	sp,sp,32
    80001d56:	8082                	ret
  } else if(n < 0){
    80001d58:	fe04d7e3          	bgez	s1,80001d46 <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d5c:	00b48633          	add	a2,s1,a1
    80001d60:	6928                	ld	a0,80(a0)
    80001d62:	e02ff0ef          	jal	ra,80001364 <uvmdealloc>
    80001d66:	85aa                	mv	a1,a0
    80001d68:	bff9                	j	80001d46 <growproc+0x36>
      return -1;
    80001d6a:	557d                	li	a0,-1
    80001d6c:	b7c5                	j	80001d4c <growproc+0x3c>
      return -1;
    80001d6e:	557d                	li	a0,-1
    80001d70:	bff1                	j	80001d4c <growproc+0x3c>

0000000080001d72 <kfork>:
{
    80001d72:	7139                	addi	sp,sp,-64
    80001d74:	fc06                	sd	ra,56(sp)
    80001d76:	f822                	sd	s0,48(sp)
    80001d78:	f426                	sd	s1,40(sp)
    80001d7a:	f04a                	sd	s2,32(sp)
    80001d7c:	ec4e                	sd	s3,24(sp)
    80001d7e:	e852                	sd	s4,16(sp)
    80001d80:	e456                	sd	s5,8(sp)
    80001d82:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d84:	c81ff0ef          	jal	ra,80001a04 <myproc>
    80001d88:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d8a:	e9bff0ef          	jal	ra,80001c24 <allocproc>
    80001d8e:	0e050663          	beqz	a0,80001e7a <kfork+0x108>
    80001d92:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d94:	048ab603          	ld	a2,72(s5)
    80001d98:	692c                	ld	a1,80(a0)
    80001d9a:	050ab503          	ld	a0,80(s5)
    80001d9e:	f32ff0ef          	jal	ra,800014d0 <uvmcopy>
    80001da2:	04054863          	bltz	a0,80001df2 <kfork+0x80>
  np->sz = p->sz;
    80001da6:	048ab783          	ld	a5,72(s5)
    80001daa:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dae:	058ab683          	ld	a3,88(s5)
    80001db2:	87b6                	mv	a5,a3
    80001db4:	058a3703          	ld	a4,88(s4)
    80001db8:	12068693          	addi	a3,a3,288
    80001dbc:	0007b803          	ld	a6,0(a5) # 2000000 <_entry-0x7e000000>
    80001dc0:	6788                	ld	a0,8(a5)
    80001dc2:	6b8c                	ld	a1,16(a5)
    80001dc4:	6f90                	ld	a2,24(a5)
    80001dc6:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001dca:	e708                	sd	a0,8(a4)
    80001dcc:	eb0c                	sd	a1,16(a4)
    80001dce:	ef10                	sd	a2,24(a4)
    80001dd0:	02078793          	addi	a5,a5,32
    80001dd4:	02070713          	addi	a4,a4,32
    80001dd8:	fed792e3          	bne	a5,a3,80001dbc <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001ddc:	058a3783          	ld	a5,88(s4)
    80001de0:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de4:	0d0a8493          	addi	s1,s5,208
    80001de8:	0d0a0913          	addi	s2,s4,208
    80001dec:	150a8993          	addi	s3,s5,336
    80001df0:	a829                	j	80001e0a <kfork+0x98>
    freeproc(np);
    80001df2:	8552                	mv	a0,s4
    80001df4:	de1ff0ef          	jal	ra,80001bd4 <freeproc>
    release(&np->lock);
    80001df8:	8552                	mv	a0,s4
    80001dfa:	f8dfe0ef          	jal	ra,80000d86 <release>
    return -1;
    80001dfe:	597d                	li	s2,-1
    80001e00:	a09d                	j	80001e66 <kfork+0xf4>
  for(i = 0; i < NOFILE; i++)
    80001e02:	04a1                	addi	s1,s1,8
    80001e04:	0921                	addi	s2,s2,8
    80001e06:	01348963          	beq	s1,s3,80001e18 <kfork+0xa6>
    if(p->ofile[i])
    80001e0a:	6088                	ld	a0,0(s1)
    80001e0c:	d97d                	beqz	a0,80001e02 <kfork+0x90>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e0e:	450020ef          	jal	ra,8000425e <filedup>
    80001e12:	00a93023          	sd	a0,0(s2)
    80001e16:	b7f5                	j	80001e02 <kfork+0x90>
  np->cwd = idup(p->cwd);
    80001e18:	150ab503          	ld	a0,336(s5)
    80001e1c:	666010ef          	jal	ra,80003482 <idup>
    80001e20:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e24:	4641                	li	a2,16
    80001e26:	158a8593          	addi	a1,s5,344
    80001e2a:	158a0513          	addi	a0,s4,344
    80001e2e:	8daff0ef          	jal	ra,80000f08 <safestrcpy>
  pid = np->pid;
    80001e32:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e36:	8552                	mv	a0,s4
    80001e38:	f4ffe0ef          	jal	ra,80000d86 <release>
  acquire(&wait_lock);
    80001e3c:	00016497          	auipc	s1,0x16
    80001e40:	ccc48493          	addi	s1,s1,-820 # 80017b08 <wait_lock>
    80001e44:	8526                	mv	a0,s1
    80001e46:	ea9fe0ef          	jal	ra,80000cee <acquire>
  np->parent = p;
    80001e4a:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e4e:	8526                	mv	a0,s1
    80001e50:	f37fe0ef          	jal	ra,80000d86 <release>
  acquire(&np->lock);
    80001e54:	8552                	mv	a0,s4
    80001e56:	e99fe0ef          	jal	ra,80000cee <acquire>
  np->state = RUNNABLE;
    80001e5a:	478d                	li	a5,3
    80001e5c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e60:	8552                	mv	a0,s4
    80001e62:	f25fe0ef          	jal	ra,80000d86 <release>
}
    80001e66:	854a                	mv	a0,s2
    80001e68:	70e2                	ld	ra,56(sp)
    80001e6a:	7442                	ld	s0,48(sp)
    80001e6c:	74a2                	ld	s1,40(sp)
    80001e6e:	7902                	ld	s2,32(sp)
    80001e70:	69e2                	ld	s3,24(sp)
    80001e72:	6a42                	ld	s4,16(sp)
    80001e74:	6aa2                	ld	s5,8(sp)
    80001e76:	6121                	addi	sp,sp,64
    80001e78:	8082                	ret
    return -1;
    80001e7a:	597d                	li	s2,-1
    80001e7c:	b7ed                	j	80001e66 <kfork+0xf4>

0000000080001e7e <scheduler>:
{
    80001e7e:	715d                	addi	sp,sp,-80
    80001e80:	e486                	sd	ra,72(sp)
    80001e82:	e0a2                	sd	s0,64(sp)
    80001e84:	fc26                	sd	s1,56(sp)
    80001e86:	f84a                	sd	s2,48(sp)
    80001e88:	f44e                	sd	s3,40(sp)
    80001e8a:	f052                	sd	s4,32(sp)
    80001e8c:	ec56                	sd	s5,24(sp)
    80001e8e:	e85a                	sd	s6,16(sp)
    80001e90:	e45e                	sd	s7,8(sp)
    80001e92:	e062                	sd	s8,0(sp)
    80001e94:	0880                	addi	s0,sp,80
    80001e96:	8792                	mv	a5,tp
  int id = r_tp();
    80001e98:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001e9a:	00779b13          	slli	s6,a5,0x7
    80001e9e:	00016717          	auipc	a4,0x16
    80001ea2:	c5270713          	addi	a4,a4,-942 # 80017af0 <pid_lock>
    80001ea6:	975a                	add	a4,a4,s6
    80001ea8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001eac:	00016717          	auipc	a4,0x16
    80001eb0:	c7c70713          	addi	a4,a4,-900 # 80017b28 <cpus+0x8>
    80001eb4:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001eb6:	4c11                	li	s8,4
        c->proc = p;
    80001eb8:	079e                	slli	a5,a5,0x7
    80001eba:	00016a17          	auipc	s4,0x16
    80001ebe:	c36a0a13          	addi	s4,s4,-970 # 80017af0 <pid_lock>
    80001ec2:	9a3e                	add	s4,s4,a5
        found = 1;
    80001ec4:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ec6:	0001c997          	auipc	s3,0x1c
    80001eca:	c5a98993          	addi	s3,s3,-934 # 8001db20 <tickslock>
    80001ece:	a83d                	j	80001f0c <scheduler+0x8e>
      release(&p->lock);
    80001ed0:	8526                	mv	a0,s1
    80001ed2:	eb5fe0ef          	jal	ra,80000d86 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ed6:	17048493          	addi	s1,s1,368
    80001eda:	03348563          	beq	s1,s3,80001f04 <scheduler+0x86>
      acquire(&p->lock);
    80001ede:	8526                	mv	a0,s1
    80001ee0:	e0ffe0ef          	jal	ra,80000cee <acquire>
      if(p->state == RUNNABLE) {
    80001ee4:	4c9c                	lw	a5,24(s1)
    80001ee6:	ff2795e3          	bne	a5,s2,80001ed0 <scheduler+0x52>
        p->state = RUNNING;
    80001eea:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001eee:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001ef2:	06048593          	addi	a1,s1,96
    80001ef6:	855a                	mv	a0,s6
    80001ef8:	64a000ef          	jal	ra,80002542 <swtch>
        c->proc = 0;
    80001efc:	020a3823          	sd	zero,48(s4)
        found = 1;
    80001f00:	8ade                	mv	s5,s7
    80001f02:	b7f9                	j	80001ed0 <scheduler+0x52>
    if(found == 0) {
    80001f04:	000a9463          	bnez	s5,80001f0c <scheduler+0x8e>
      asm volatile("wfi");
    80001f08:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f0c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f10:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f14:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f18:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001f1c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f1e:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001f22:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f24:	00016497          	auipc	s1,0x16
    80001f28:	ffc48493          	addi	s1,s1,-4 # 80017f20 <proc>
      if(p->state == RUNNABLE) {
    80001f2c:	490d                	li	s2,3
    80001f2e:	bf45                	j	80001ede <scheduler+0x60>

0000000080001f30 <sched>:
{
    80001f30:	7179                	addi	sp,sp,-48
    80001f32:	f406                	sd	ra,40(sp)
    80001f34:	f022                	sd	s0,32(sp)
    80001f36:	ec26                	sd	s1,24(sp)
    80001f38:	e84a                	sd	s2,16(sp)
    80001f3a:	e44e                	sd	s3,8(sp)
    80001f3c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f3e:	ac7ff0ef          	jal	ra,80001a04 <myproc>
    80001f42:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f44:	d41fe0ef          	jal	ra,80000c84 <holding>
    80001f48:	c92d                	beqz	a0,80001fba <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f4a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f4c:	2781                	sext.w	a5,a5
    80001f4e:	079e                	slli	a5,a5,0x7
    80001f50:	00016717          	auipc	a4,0x16
    80001f54:	ba070713          	addi	a4,a4,-1120 # 80017af0 <pid_lock>
    80001f58:	97ba                	add	a5,a5,a4
    80001f5a:	0a87a703          	lw	a4,168(a5)
    80001f5e:	4785                	li	a5,1
    80001f60:	06f71363          	bne	a4,a5,80001fc6 <sched+0x96>
  if(p->state == RUNNING)
    80001f64:	4c98                	lw	a4,24(s1)
    80001f66:	4791                	li	a5,4
    80001f68:	06f70563          	beq	a4,a5,80001fd2 <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f6c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f70:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f72:	e7b5                	bnez	a5,80001fde <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f74:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f76:	00016917          	auipc	s2,0x16
    80001f7a:	b7a90913          	addi	s2,s2,-1158 # 80017af0 <pid_lock>
    80001f7e:	2781                	sext.w	a5,a5
    80001f80:	079e                	slli	a5,a5,0x7
    80001f82:	97ca                	add	a5,a5,s2
    80001f84:	0ac7a983          	lw	s3,172(a5)
    80001f88:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f8a:	2781                	sext.w	a5,a5
    80001f8c:	079e                	slli	a5,a5,0x7
    80001f8e:	00016597          	auipc	a1,0x16
    80001f92:	b9a58593          	addi	a1,a1,-1126 # 80017b28 <cpus+0x8>
    80001f96:	95be                	add	a1,a1,a5
    80001f98:	06048513          	addi	a0,s1,96
    80001f9c:	5a6000ef          	jal	ra,80002542 <swtch>
    80001fa0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fa2:	2781                	sext.w	a5,a5
    80001fa4:	079e                	slli	a5,a5,0x7
    80001fa6:	97ca                	add	a5,a5,s2
    80001fa8:	0b37a623          	sw	s3,172(a5)
}
    80001fac:	70a2                	ld	ra,40(sp)
    80001fae:	7402                	ld	s0,32(sp)
    80001fb0:	64e2                	ld	s1,24(sp)
    80001fb2:	6942                	ld	s2,16(sp)
    80001fb4:	69a2                	ld	s3,8(sp)
    80001fb6:	6145                	addi	sp,sp,48
    80001fb8:	8082                	ret
    panic("sched p->lock");
    80001fba:	00005517          	auipc	a0,0x5
    80001fbe:	2c650513          	addi	a0,a0,710 # 80007280 <digits+0x248>
    80001fc2:	fc8fe0ef          	jal	ra,8000078a <panic>
    panic("sched locks");
    80001fc6:	00005517          	auipc	a0,0x5
    80001fca:	2ca50513          	addi	a0,a0,714 # 80007290 <digits+0x258>
    80001fce:	fbcfe0ef          	jal	ra,8000078a <panic>
    panic("sched RUNNING");
    80001fd2:	00005517          	auipc	a0,0x5
    80001fd6:	2ce50513          	addi	a0,a0,718 # 800072a0 <digits+0x268>
    80001fda:	fb0fe0ef          	jal	ra,8000078a <panic>
    panic("sched interruptible");
    80001fde:	00005517          	auipc	a0,0x5
    80001fe2:	2d250513          	addi	a0,a0,722 # 800072b0 <digits+0x278>
    80001fe6:	fa4fe0ef          	jal	ra,8000078a <panic>

0000000080001fea <yield>:
{
    80001fea:	1101                	addi	sp,sp,-32
    80001fec:	ec06                	sd	ra,24(sp)
    80001fee:	e822                	sd	s0,16(sp)
    80001ff0:	e426                	sd	s1,8(sp)
    80001ff2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001ff4:	a11ff0ef          	jal	ra,80001a04 <myproc>
    80001ff8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001ffa:	cf5fe0ef          	jal	ra,80000cee <acquire>
  p->state = RUNNABLE;
    80001ffe:	478d                	li	a5,3
    80002000:	cc9c                	sw	a5,24(s1)
  sched();
    80002002:	f2fff0ef          	jal	ra,80001f30 <sched>
  release(&p->lock);
    80002006:	8526                	mv	a0,s1
    80002008:	d7ffe0ef          	jal	ra,80000d86 <release>
}
    8000200c:	60e2                	ld	ra,24(sp)
    8000200e:	6442                	ld	s0,16(sp)
    80002010:	64a2                	ld	s1,8(sp)
    80002012:	6105                	addi	sp,sp,32
    80002014:	8082                	ret

0000000080002016 <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002016:	7179                	addi	sp,sp,-48
    80002018:	f406                	sd	ra,40(sp)
    8000201a:	f022                	sd	s0,32(sp)
    8000201c:	ec26                	sd	s1,24(sp)
    8000201e:	e84a                	sd	s2,16(sp)
    80002020:	e44e                	sd	s3,8(sp)
    80002022:	1800                	addi	s0,sp,48
    80002024:	89aa                	mv	s3,a0
    80002026:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002028:	9ddff0ef          	jal	ra,80001a04 <myproc>
    8000202c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000202e:	cc1fe0ef          	jal	ra,80000cee <acquire>
  release(lk);
    80002032:	854a                	mv	a0,s2
    80002034:	d53fe0ef          	jal	ra,80000d86 <release>

  // Go to sleep.
  p->chan = chan;
    80002038:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000203c:	4789                	li	a5,2
    8000203e:	cc9c                	sw	a5,24(s1)

  sched();
    80002040:	ef1ff0ef          	jal	ra,80001f30 <sched>

  // Tidy up.
  p->chan = 0;
    80002044:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002048:	8526                	mv	a0,s1
    8000204a:	d3dfe0ef          	jal	ra,80000d86 <release>
  acquire(lk);
    8000204e:	854a                	mv	a0,s2
    80002050:	c9ffe0ef          	jal	ra,80000cee <acquire>
}
    80002054:	70a2                	ld	ra,40(sp)
    80002056:	7402                	ld	s0,32(sp)
    80002058:	64e2                	ld	s1,24(sp)
    8000205a:	6942                	ld	s2,16(sp)
    8000205c:	69a2                	ld	s3,8(sp)
    8000205e:	6145                	addi	sp,sp,48
    80002060:	8082                	ret

0000000080002062 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    80002062:	7139                	addi	sp,sp,-64
    80002064:	fc06                	sd	ra,56(sp)
    80002066:	f822                	sd	s0,48(sp)
    80002068:	f426                	sd	s1,40(sp)
    8000206a:	f04a                	sd	s2,32(sp)
    8000206c:	ec4e                	sd	s3,24(sp)
    8000206e:	e852                	sd	s4,16(sp)
    80002070:	e456                	sd	s5,8(sp)
    80002072:	0080                	addi	s0,sp,64
    80002074:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002076:	00016497          	auipc	s1,0x16
    8000207a:	eaa48493          	addi	s1,s1,-342 # 80017f20 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000207e:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002080:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002082:	0001c917          	auipc	s2,0x1c
    80002086:	a9e90913          	addi	s2,s2,-1378 # 8001db20 <tickslock>
    8000208a:	a801                	j	8000209a <wakeup+0x38>
      }
      release(&p->lock);
    8000208c:	8526                	mv	a0,s1
    8000208e:	cf9fe0ef          	jal	ra,80000d86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002092:	17048493          	addi	s1,s1,368
    80002096:	03248263          	beq	s1,s2,800020ba <wakeup+0x58>
    if(p != myproc()){
    8000209a:	96bff0ef          	jal	ra,80001a04 <myproc>
    8000209e:	fea48ae3          	beq	s1,a0,80002092 <wakeup+0x30>
      acquire(&p->lock);
    800020a2:	8526                	mv	a0,s1
    800020a4:	c4bfe0ef          	jal	ra,80000cee <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800020a8:	4c9c                	lw	a5,24(s1)
    800020aa:	ff3791e3          	bne	a5,s3,8000208c <wakeup+0x2a>
    800020ae:	709c                	ld	a5,32(s1)
    800020b0:	fd479ee3          	bne	a5,s4,8000208c <wakeup+0x2a>
        p->state = RUNNABLE;
    800020b4:	0154ac23          	sw	s5,24(s1)
    800020b8:	bfd1                	j	8000208c <wakeup+0x2a>
    }
  }
}
    800020ba:	70e2                	ld	ra,56(sp)
    800020bc:	7442                	ld	s0,48(sp)
    800020be:	74a2                	ld	s1,40(sp)
    800020c0:	7902                	ld	s2,32(sp)
    800020c2:	69e2                	ld	s3,24(sp)
    800020c4:	6a42                	ld	s4,16(sp)
    800020c6:	6aa2                	ld	s5,8(sp)
    800020c8:	6121                	addi	sp,sp,64
    800020ca:	8082                	ret

00000000800020cc <reparent>:
{
    800020cc:	7179                	addi	sp,sp,-48
    800020ce:	f406                	sd	ra,40(sp)
    800020d0:	f022                	sd	s0,32(sp)
    800020d2:	ec26                	sd	s1,24(sp)
    800020d4:	e84a                	sd	s2,16(sp)
    800020d6:	e44e                	sd	s3,8(sp)
    800020d8:	e052                	sd	s4,0(sp)
    800020da:	1800                	addi	s0,sp,48
    800020dc:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800020de:	00016497          	auipc	s1,0x16
    800020e2:	e4248493          	addi	s1,s1,-446 # 80017f20 <proc>
      pp->parent = initproc;
    800020e6:	00006a17          	auipc	s4,0x6
    800020ea:	92aa0a13          	addi	s4,s4,-1750 # 80007a10 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800020ee:	0001c997          	auipc	s3,0x1c
    800020f2:	a3298993          	addi	s3,s3,-1486 # 8001db20 <tickslock>
    800020f6:	a029                	j	80002100 <reparent+0x34>
    800020f8:	17048493          	addi	s1,s1,368
    800020fc:	01348b63          	beq	s1,s3,80002112 <reparent+0x46>
    if(pp->parent == p){
    80002100:	7c9c                	ld	a5,56(s1)
    80002102:	ff279be3          	bne	a5,s2,800020f8 <reparent+0x2c>
      pp->parent = initproc;
    80002106:	000a3503          	ld	a0,0(s4)
    8000210a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000210c:	f57ff0ef          	jal	ra,80002062 <wakeup>
    80002110:	b7e5                	j	800020f8 <reparent+0x2c>
}
    80002112:	70a2                	ld	ra,40(sp)
    80002114:	7402                	ld	s0,32(sp)
    80002116:	64e2                	ld	s1,24(sp)
    80002118:	6942                	ld	s2,16(sp)
    8000211a:	69a2                	ld	s3,8(sp)
    8000211c:	6a02                	ld	s4,0(sp)
    8000211e:	6145                	addi	sp,sp,48
    80002120:	8082                	ret

0000000080002122 <kexit>:
{
    80002122:	7179                	addi	sp,sp,-48
    80002124:	f406                	sd	ra,40(sp)
    80002126:	f022                	sd	s0,32(sp)
    80002128:	ec26                	sd	s1,24(sp)
    8000212a:	e84a                	sd	s2,16(sp)
    8000212c:	e44e                	sd	s3,8(sp)
    8000212e:	e052                	sd	s4,0(sp)
    80002130:	1800                	addi	s0,sp,48
    80002132:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002134:	8d1ff0ef          	jal	ra,80001a04 <myproc>
    80002138:	89aa                	mv	s3,a0
  if(p == initproc)
    8000213a:	00006797          	auipc	a5,0x6
    8000213e:	8d67b783          	ld	a5,-1834(a5) # 80007a10 <initproc>
    80002142:	0d050493          	addi	s1,a0,208
    80002146:	15050913          	addi	s2,a0,336
    8000214a:	00a79f63          	bne	a5,a0,80002168 <kexit+0x46>
    panic("init exiting");
    8000214e:	00005517          	auipc	a0,0x5
    80002152:	17a50513          	addi	a0,a0,378 # 800072c8 <digits+0x290>
    80002156:	e34fe0ef          	jal	ra,8000078a <panic>
      fileclose(f);
    8000215a:	14a020ef          	jal	ra,800042a4 <fileclose>
      p->ofile[fd] = 0;
    8000215e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002162:	04a1                	addi	s1,s1,8
    80002164:	01248563          	beq	s1,s2,8000216e <kexit+0x4c>
    if(p->ofile[fd]){
    80002168:	6088                	ld	a0,0(s1)
    8000216a:	f965                	bnez	a0,8000215a <kexit+0x38>
    8000216c:	bfdd                	j	80002162 <kexit+0x40>
  begin_op();
    8000216e:	529010ef          	jal	ra,80003e96 <begin_op>
  iput(p->cwd);
    80002172:	1509b503          	ld	a0,336(s3)
    80002176:	4c0010ef          	jal	ra,80003636 <iput>
  end_op();
    8000217a:	58d010ef          	jal	ra,80003f06 <end_op>
  p->cwd = 0;
    8000217e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002182:	00016497          	auipc	s1,0x16
    80002186:	98648493          	addi	s1,s1,-1658 # 80017b08 <wait_lock>
    8000218a:	8526                	mv	a0,s1
    8000218c:	b63fe0ef          	jal	ra,80000cee <acquire>
  reparent(p);
    80002190:	854e                	mv	a0,s3
    80002192:	f3bff0ef          	jal	ra,800020cc <reparent>
  wakeup(p->parent);
    80002196:	0389b503          	ld	a0,56(s3)
    8000219a:	ec9ff0ef          	jal	ra,80002062 <wakeup>
  acquire(&p->lock);
    8000219e:	854e                	mv	a0,s3
    800021a0:	b4ffe0ef          	jal	ra,80000cee <acquire>
  p->xstate = status;
    800021a4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800021a8:	4795                	li	a5,5
    800021aa:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800021ae:	8526                	mv	a0,s1
    800021b0:	bd7fe0ef          	jal	ra,80000d86 <release>
  sched();
    800021b4:	d7dff0ef          	jal	ra,80001f30 <sched>
  panic("zombie exit");
    800021b8:	00005517          	auipc	a0,0x5
    800021bc:	12050513          	addi	a0,a0,288 # 800072d8 <digits+0x2a0>
    800021c0:	dcafe0ef          	jal	ra,8000078a <panic>

00000000800021c4 <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    800021c4:	7179                	addi	sp,sp,-48
    800021c6:	f406                	sd	ra,40(sp)
    800021c8:	f022                	sd	s0,32(sp)
    800021ca:	ec26                	sd	s1,24(sp)
    800021cc:	e84a                	sd	s2,16(sp)
    800021ce:	e44e                	sd	s3,8(sp)
    800021d0:	1800                	addi	s0,sp,48
    800021d2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800021d4:	00016497          	auipc	s1,0x16
    800021d8:	d4c48493          	addi	s1,s1,-692 # 80017f20 <proc>
    800021dc:	0001c997          	auipc	s3,0x1c
    800021e0:	94498993          	addi	s3,s3,-1724 # 8001db20 <tickslock>
    acquire(&p->lock);
    800021e4:	8526                	mv	a0,s1
    800021e6:	b09fe0ef          	jal	ra,80000cee <acquire>
    if(p->pid == pid){
    800021ea:	589c                	lw	a5,48(s1)
    800021ec:	01278b63          	beq	a5,s2,80002202 <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800021f0:	8526                	mv	a0,s1
    800021f2:	b95fe0ef          	jal	ra,80000d86 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800021f6:	17048493          	addi	s1,s1,368
    800021fa:	ff3495e3          	bne	s1,s3,800021e4 <kkill+0x20>
  }
  return -1;
    800021fe:	557d                	li	a0,-1
    80002200:	a819                	j	80002216 <kkill+0x52>
      p->killed = 1;
    80002202:	4785                	li	a5,1
    80002204:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002206:	4c98                	lw	a4,24(s1)
    80002208:	4789                	li	a5,2
    8000220a:	00f70d63          	beq	a4,a5,80002224 <kkill+0x60>
      release(&p->lock);
    8000220e:	8526                	mv	a0,s1
    80002210:	b77fe0ef          	jal	ra,80000d86 <release>
      return 0;
    80002214:	4501                	li	a0,0
}
    80002216:	70a2                	ld	ra,40(sp)
    80002218:	7402                	ld	s0,32(sp)
    8000221a:	64e2                	ld	s1,24(sp)
    8000221c:	6942                	ld	s2,16(sp)
    8000221e:	69a2                	ld	s3,8(sp)
    80002220:	6145                	addi	sp,sp,48
    80002222:	8082                	ret
        p->state = RUNNABLE;
    80002224:	478d                	li	a5,3
    80002226:	cc9c                	sw	a5,24(s1)
    80002228:	b7dd                	j	8000220e <kkill+0x4a>

000000008000222a <setkilled>:

void
setkilled(struct proc *p)
{
    8000222a:	1101                	addi	sp,sp,-32
    8000222c:	ec06                	sd	ra,24(sp)
    8000222e:	e822                	sd	s0,16(sp)
    80002230:	e426                	sd	s1,8(sp)
    80002232:	1000                	addi	s0,sp,32
    80002234:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002236:	ab9fe0ef          	jal	ra,80000cee <acquire>
  p->killed = 1;
    8000223a:	4785                	li	a5,1
    8000223c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	b47fe0ef          	jal	ra,80000d86 <release>
}
    80002244:	60e2                	ld	ra,24(sp)
    80002246:	6442                	ld	s0,16(sp)
    80002248:	64a2                	ld	s1,8(sp)
    8000224a:	6105                	addi	sp,sp,32
    8000224c:	8082                	ret

000000008000224e <killed>:

int
killed(struct proc *p)
{
    8000224e:	1101                	addi	sp,sp,-32
    80002250:	ec06                	sd	ra,24(sp)
    80002252:	e822                	sd	s0,16(sp)
    80002254:	e426                	sd	s1,8(sp)
    80002256:	e04a                	sd	s2,0(sp)
    80002258:	1000                	addi	s0,sp,32
    8000225a:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000225c:	a93fe0ef          	jal	ra,80000cee <acquire>
  k = p->killed;
    80002260:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002264:	8526                	mv	a0,s1
    80002266:	b21fe0ef          	jal	ra,80000d86 <release>
  return k;
}
    8000226a:	854a                	mv	a0,s2
    8000226c:	60e2                	ld	ra,24(sp)
    8000226e:	6442                	ld	s0,16(sp)
    80002270:	64a2                	ld	s1,8(sp)
    80002272:	6902                	ld	s2,0(sp)
    80002274:	6105                	addi	sp,sp,32
    80002276:	8082                	ret

0000000080002278 <kwait>:
{
    80002278:	715d                	addi	sp,sp,-80
    8000227a:	e486                	sd	ra,72(sp)
    8000227c:	e0a2                	sd	s0,64(sp)
    8000227e:	fc26                	sd	s1,56(sp)
    80002280:	f84a                	sd	s2,48(sp)
    80002282:	f44e                	sd	s3,40(sp)
    80002284:	f052                	sd	s4,32(sp)
    80002286:	ec56                	sd	s5,24(sp)
    80002288:	e85a                	sd	s6,16(sp)
    8000228a:	e45e                	sd	s7,8(sp)
    8000228c:	e062                	sd	s8,0(sp)
    8000228e:	0880                	addi	s0,sp,80
    80002290:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002292:	f72ff0ef          	jal	ra,80001a04 <myproc>
    80002296:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002298:	00016517          	auipc	a0,0x16
    8000229c:	87050513          	addi	a0,a0,-1936 # 80017b08 <wait_lock>
    800022a0:	a4ffe0ef          	jal	ra,80000cee <acquire>
    havekids = 0;
    800022a4:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800022a6:	4a15                	li	s4,5
        havekids = 1;
    800022a8:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800022aa:	0001c997          	auipc	s3,0x1c
    800022ae:	87698993          	addi	s3,s3,-1930 # 8001db20 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022b2:	00016c17          	auipc	s8,0x16
    800022b6:	856c0c13          	addi	s8,s8,-1962 # 80017b08 <wait_lock>
    havekids = 0;
    800022ba:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800022bc:	00016497          	auipc	s1,0x16
    800022c0:	c6448493          	addi	s1,s1,-924 # 80017f20 <proc>
    800022c4:	a899                	j	8000231a <kwait+0xa2>
          pid = pp->pid;
    800022c6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800022ca:	000b0c63          	beqz	s6,800022e2 <kwait+0x6a>
    800022ce:	4691                	li	a3,4
    800022d0:	02c48613          	addi	a2,s1,44
    800022d4:	85da                	mv	a1,s6
    800022d6:	05093503          	ld	a0,80(s2)
    800022da:	ae0ff0ef          	jal	ra,800015ba <copyout>
    800022de:	00054f63          	bltz	a0,800022fc <kwait+0x84>
          freeproc(pp);
    800022e2:	8526                	mv	a0,s1
    800022e4:	8f1ff0ef          	jal	ra,80001bd4 <freeproc>
          release(&pp->lock);
    800022e8:	8526                	mv	a0,s1
    800022ea:	a9dfe0ef          	jal	ra,80000d86 <release>
          release(&wait_lock);
    800022ee:	00016517          	auipc	a0,0x16
    800022f2:	81a50513          	addi	a0,a0,-2022 # 80017b08 <wait_lock>
    800022f6:	a91fe0ef          	jal	ra,80000d86 <release>
          return pid;
    800022fa:	a891                	j	8000234e <kwait+0xd6>
            release(&pp->lock);
    800022fc:	8526                	mv	a0,s1
    800022fe:	a89fe0ef          	jal	ra,80000d86 <release>
            release(&wait_lock);
    80002302:	00016517          	auipc	a0,0x16
    80002306:	80650513          	addi	a0,a0,-2042 # 80017b08 <wait_lock>
    8000230a:	a7dfe0ef          	jal	ra,80000d86 <release>
            return -1;
    8000230e:	59fd                	li	s3,-1
    80002310:	a83d                	j	8000234e <kwait+0xd6>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002312:	17048493          	addi	s1,s1,368
    80002316:	03348063          	beq	s1,s3,80002336 <kwait+0xbe>
      if(pp->parent == p){
    8000231a:	7c9c                	ld	a5,56(s1)
    8000231c:	ff279be3          	bne	a5,s2,80002312 <kwait+0x9a>
        acquire(&pp->lock);
    80002320:	8526                	mv	a0,s1
    80002322:	9cdfe0ef          	jal	ra,80000cee <acquire>
        if(pp->state == ZOMBIE){
    80002326:	4c9c                	lw	a5,24(s1)
    80002328:	f9478fe3          	beq	a5,s4,800022c6 <kwait+0x4e>
        release(&pp->lock);
    8000232c:	8526                	mv	a0,s1
    8000232e:	a59fe0ef          	jal	ra,80000d86 <release>
        havekids = 1;
    80002332:	8756                	mv	a4,s5
    80002334:	bff9                	j	80002312 <kwait+0x9a>
    if(!havekids || killed(p)){
    80002336:	c709                	beqz	a4,80002340 <kwait+0xc8>
    80002338:	854a                	mv	a0,s2
    8000233a:	f15ff0ef          	jal	ra,8000224e <killed>
    8000233e:	c50d                	beqz	a0,80002368 <kwait+0xf0>
      release(&wait_lock);
    80002340:	00015517          	auipc	a0,0x15
    80002344:	7c850513          	addi	a0,a0,1992 # 80017b08 <wait_lock>
    80002348:	a3ffe0ef          	jal	ra,80000d86 <release>
      return -1;
    8000234c:	59fd                	li	s3,-1
}
    8000234e:	854e                	mv	a0,s3
    80002350:	60a6                	ld	ra,72(sp)
    80002352:	6406                	ld	s0,64(sp)
    80002354:	74e2                	ld	s1,56(sp)
    80002356:	7942                	ld	s2,48(sp)
    80002358:	79a2                	ld	s3,40(sp)
    8000235a:	7a02                	ld	s4,32(sp)
    8000235c:	6ae2                	ld	s5,24(sp)
    8000235e:	6b42                	ld	s6,16(sp)
    80002360:	6ba2                	ld	s7,8(sp)
    80002362:	6c02                	ld	s8,0(sp)
    80002364:	6161                	addi	sp,sp,80
    80002366:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002368:	85e2                	mv	a1,s8
    8000236a:	854a                	mv	a0,s2
    8000236c:	cabff0ef          	jal	ra,80002016 <sleep>
    havekids = 0;
    80002370:	b7a9                	j	800022ba <kwait+0x42>

0000000080002372 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002372:	7179                	addi	sp,sp,-48
    80002374:	f406                	sd	ra,40(sp)
    80002376:	f022                	sd	s0,32(sp)
    80002378:	ec26                	sd	s1,24(sp)
    8000237a:	e84a                	sd	s2,16(sp)
    8000237c:	e44e                	sd	s3,8(sp)
    8000237e:	e052                	sd	s4,0(sp)
    80002380:	1800                	addi	s0,sp,48
    80002382:	84aa                	mv	s1,a0
    80002384:	892e                	mv	s2,a1
    80002386:	89b2                	mv	s3,a2
    80002388:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000238a:	e7aff0ef          	jal	ra,80001a04 <myproc>
  if(user_dst){
    8000238e:	cc99                	beqz	s1,800023ac <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    80002390:	86d2                	mv	a3,s4
    80002392:	864e                	mv	a2,s3
    80002394:	85ca                	mv	a1,s2
    80002396:	6928                	ld	a0,80(a0)
    80002398:	a22ff0ef          	jal	ra,800015ba <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000239c:	70a2                	ld	ra,40(sp)
    8000239e:	7402                	ld	s0,32(sp)
    800023a0:	64e2                	ld	s1,24(sp)
    800023a2:	6942                	ld	s2,16(sp)
    800023a4:	69a2                	ld	s3,8(sp)
    800023a6:	6a02                	ld	s4,0(sp)
    800023a8:	6145                	addi	sp,sp,48
    800023aa:	8082                	ret
    memmove((char *)dst, src, len);
    800023ac:	000a061b          	sext.w	a2,s4
    800023b0:	85ce                	mv	a1,s3
    800023b2:	854a                	mv	a0,s2
    800023b4:	a6bfe0ef          	jal	ra,80000e1e <memmove>
    return 0;
    800023b8:	8526                	mv	a0,s1
    800023ba:	b7cd                	j	8000239c <either_copyout+0x2a>

00000000800023bc <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800023bc:	7179                	addi	sp,sp,-48
    800023be:	f406                	sd	ra,40(sp)
    800023c0:	f022                	sd	s0,32(sp)
    800023c2:	ec26                	sd	s1,24(sp)
    800023c4:	e84a                	sd	s2,16(sp)
    800023c6:	e44e                	sd	s3,8(sp)
    800023c8:	e052                	sd	s4,0(sp)
    800023ca:	1800                	addi	s0,sp,48
    800023cc:	892a                	mv	s2,a0
    800023ce:	84ae                	mv	s1,a1
    800023d0:	89b2                	mv	s3,a2
    800023d2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800023d4:	e30ff0ef          	jal	ra,80001a04 <myproc>
  if(user_src){
    800023d8:	cc99                	beqz	s1,800023f6 <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    800023da:	86d2                	mv	a3,s4
    800023dc:	864e                	mv	a2,s3
    800023de:	85ca                	mv	a1,s2
    800023e0:	6928                	ld	a0,80(a0)
    800023e2:	c36ff0ef          	jal	ra,80001818 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800023e6:	70a2                	ld	ra,40(sp)
    800023e8:	7402                	ld	s0,32(sp)
    800023ea:	64e2                	ld	s1,24(sp)
    800023ec:	6942                	ld	s2,16(sp)
    800023ee:	69a2                	ld	s3,8(sp)
    800023f0:	6a02                	ld	s4,0(sp)
    800023f2:	6145                	addi	sp,sp,48
    800023f4:	8082                	ret
    memmove(dst, (char*)src, len);
    800023f6:	000a061b          	sext.w	a2,s4
    800023fa:	85ce                	mv	a1,s3
    800023fc:	854a                	mv	a0,s2
    800023fe:	a21fe0ef          	jal	ra,80000e1e <memmove>
    return 0;
    80002402:	8526                	mv	a0,s1
    80002404:	b7cd                	j	800023e6 <either_copyin+0x2a>

0000000080002406 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002406:	715d                	addi	sp,sp,-80
    80002408:	e486                	sd	ra,72(sp)
    8000240a:	e0a2                	sd	s0,64(sp)
    8000240c:	fc26                	sd	s1,56(sp)
    8000240e:	f84a                	sd	s2,48(sp)
    80002410:	f44e                	sd	s3,40(sp)
    80002412:	f052                	sd	s4,32(sp)
    80002414:	ec56                	sd	s5,24(sp)
    80002416:	e85a                	sd	s6,16(sp)
    80002418:	e45e                	sd	s7,8(sp)
    8000241a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000241c:	00005517          	auipc	a0,0x5
    80002420:	05450513          	addi	a0,a0,84 # 80007470 <states.0+0x140>
    80002424:	8a0fe0ef          	jal	ra,800004c4 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002428:	00016497          	auipc	s1,0x16
    8000242c:	c5048493          	addi	s1,s1,-944 # 80018078 <proc+0x158>
    80002430:	0001c917          	auipc	s2,0x1c
    80002434:	84890913          	addi	s2,s2,-1976 # 8001dc78 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002438:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000243a:	00005997          	auipc	s3,0x5
    8000243e:	eae98993          	addi	s3,s3,-338 # 800072e8 <digits+0x2b0>
    printf("%d %s %s", p->pid, state, p->name);
    80002442:	00005a97          	auipc	s5,0x5
    80002446:	eaea8a93          	addi	s5,s5,-338 # 800072f0 <digits+0x2b8>
    printf("\n");
    8000244a:	00005a17          	auipc	s4,0x5
    8000244e:	026a0a13          	addi	s4,s4,38 # 80007470 <states.0+0x140>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002452:	00005b97          	auipc	s7,0x5
    80002456:	edeb8b93          	addi	s7,s7,-290 # 80007330 <states.0>
    8000245a:	a829                	j	80002474 <procdump+0x6e>
    printf("%d %s %s", p->pid, state, p->name);
    8000245c:	ed86a583          	lw	a1,-296(a3)
    80002460:	8556                	mv	a0,s5
    80002462:	862fe0ef          	jal	ra,800004c4 <printf>
    printf("\n");
    80002466:	8552                	mv	a0,s4
    80002468:	85cfe0ef          	jal	ra,800004c4 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000246c:	17048493          	addi	s1,s1,368
    80002470:	03248163          	beq	s1,s2,80002492 <procdump+0x8c>
    if(p->state == UNUSED)
    80002474:	86a6                	mv	a3,s1
    80002476:	ec04a783          	lw	a5,-320(s1)
    8000247a:	dbed                	beqz	a5,8000246c <procdump+0x66>
      state = "???";
    8000247c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000247e:	fcfb6fe3          	bltu	s6,a5,8000245c <procdump+0x56>
    80002482:	1782                	slli	a5,a5,0x20
    80002484:	9381                	srli	a5,a5,0x20
    80002486:	078e                	slli	a5,a5,0x3
    80002488:	97de                	add	a5,a5,s7
    8000248a:	6390                	ld	a2,0(a5)
    8000248c:	fa61                	bnez	a2,8000245c <procdump+0x56>
      state = "???";
    8000248e:	864e                	mv	a2,s3
    80002490:	b7f1                	j	8000245c <procdump+0x56>
  }
}
    80002492:	60a6                	ld	ra,72(sp)
    80002494:	6406                	ld	s0,64(sp)
    80002496:	74e2                	ld	s1,56(sp)
    80002498:	7942                	ld	s2,48(sp)
    8000249a:	79a2                	ld	s3,40(sp)
    8000249c:	7a02                	ld	s4,32(sp)
    8000249e:	6ae2                	ld	s5,24(sp)
    800024a0:	6b42                	ld	s6,16(sp)
    800024a2:	6ba2                	ld	s7,8(sp)
    800024a4:	6161                	addi	sp,sp,80
    800024a6:	8082                	ret

00000000800024a8 <sys_dump_proc>:

int
sys_dump_proc(void)
{
    800024a8:	711d                	addi	sp,sp,-96
    800024aa:	ec86                	sd	ra,88(sp)
    800024ac:	e8a2                	sd	s0,80(sp)
    800024ae:	e4a6                	sd	s1,72(sp)
    800024b0:	e0ca                	sd	s2,64(sp)
    800024b2:	fc4e                	sd	s3,56(sp)
    800024b4:	1080                	addi	s0,sp,96
    uint64 addr;
    // 获取用户传入的指针地址（第0个参数）
    argaddr(0, &addr);  // 注意：argaddr 是 void，不返回错误
    800024b6:	fc840593          	addi	a1,s0,-56
    800024ba:	4501                	li	a0,0
    800024bc:	630000ef          	jal	ra,80002aec <argaddr>

    if (addr == 0)
    800024c0:	fc843783          	ld	a5,-56(s0)
    800024c4:	cfad                	beqz	a5,8000253e <sys_dump_proc+0x96>
    800024c6:	00016497          	auipc	s1,0x16
    800024ca:	a5a48493          	addi	s1,s1,-1446 # 80017f20 <proc>
    800024ce:	0001b997          	auipc	s3,0x1b
    800024d2:	65298993          	addi	s3,s3,1618 # 8001db20 <tickslock>
    800024d6:	4901                	li	s2,0
        return -1;  // 无效地址

    for (int i = 0; i < NPROC; i++) {
        struct proc *p = &proc[i];  // ← 现在在 proc.c 中，proc[] 可见！
        acquire(&p->lock);
    800024d8:	8526                	mv	a0,s1
    800024da:	815fe0ef          	jal	ra,80000cee <acquire>
        struct pstat ps;
        ps.inuse = (p->state != UNUSED);
    800024de:	4c9c                	lw	a5,24(s1)
    800024e0:	00f03733          	snez	a4,a5
    800024e4:	fae42423          	sw	a4,-88(s0)
        ps.pid = p->pid;
    800024e8:	5898                	lw	a4,48(s1)
    800024ea:	fae42623          	sw	a4,-84(s0)
        ps.state = p->state;
    800024ee:	fcf42023          	sw	a5,-64(s0)
        safestrcpy(ps.name, p->name, sizeof(ps.name));
    800024f2:	4641                	li	a2,16
    800024f4:	15848593          	addi	a1,s1,344
    800024f8:	fb040513          	addi	a0,s0,-80
    800024fc:	a0dfe0ef          	jal	ra,80000f08 <safestrcpy>
        release(&p->lock);
    80002500:	8526                	mv	a0,s1
    80002502:	885fe0ef          	jal	ra,80000d86 <release>

        // 安全拷贝到用户空间
        if (copyout(myproc()->pagetable, addr + i * sizeof(ps), (char*)&ps, sizeof(ps)) < 0) {
    80002506:	cfeff0ef          	jal	ra,80001a04 <myproc>
    8000250a:	46f1                	li	a3,28
    8000250c:	fa840613          	addi	a2,s0,-88
    80002510:	fc843583          	ld	a1,-56(s0)
    80002514:	95ca                	add	a1,a1,s2
    80002516:	6928                	ld	a0,80(a0)
    80002518:	8a2ff0ef          	jal	ra,800015ba <copyout>
    8000251c:	00054963          	bltz	a0,8000252e <sys_dump_proc+0x86>
    for (int i = 0; i < NPROC; i++) {
    80002520:	17048493          	addi	s1,s1,368
    80002524:	0971                	addi	s2,s2,28
    80002526:	fb3499e3          	bne	s1,s3,800024d8 <sys_dump_proc+0x30>
            return -1;
        }
    }
    return 0;
    8000252a:	4501                	li	a0,0
    8000252c:	a011                	j	80002530 <sys_dump_proc+0x88>
            return -1;
    8000252e:	557d                	li	a0,-1
}
    80002530:	60e6                	ld	ra,88(sp)
    80002532:	6446                	ld	s0,80(sp)
    80002534:	64a6                	ld	s1,72(sp)
    80002536:	6906                	ld	s2,64(sp)
    80002538:	79e2                	ld	s3,56(sp)
    8000253a:	6125                	addi	sp,sp,96
    8000253c:	8082                	ret
        return -1;  // 无效地址
    8000253e:	557d                	li	a0,-1
    80002540:	bfc5                	j	80002530 <sys_dump_proc+0x88>

0000000080002542 <swtch>:
# 保存当前寄存器到 old，然后从 new 加载寄存器。

.globl swtch
swtch:
        # 保存当前的寄存器到 old 中
        sd ra, 0(a0)   # 保存返回地址寄存器 ra
    80002542:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)   # 保存栈指针寄存器 sp
    80002546:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)  # 保存寄存器 s0
    8000254a:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)  # 保存寄存器 s1
    8000254c:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)  # 保存寄存器 s2
    8000254e:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)  # 保存寄存器 s3
    80002552:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)  # 保存寄存器 s4
    80002556:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)  # 保存寄存器 s5
    8000255a:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)  # 保存寄存器 s6
    8000255e:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)  # 保存寄存器 s7
    80002562:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)  # 保存寄存器 s8
    80002566:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)  # 保存寄存器 s9
    8000256a:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0) # 保存寄存器 s10
    8000256e:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)# 保存寄存器 s11
    80002572:	07b53423          	sd	s11,104(a0)

        # 从 new 加载寄存器
        ld ra, 0(a1)   # 加载返回地址寄存器 ra
    80002576:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)   # 加载栈指针寄存器 sp
    8000257a:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)  # 加载寄存器 s0
    8000257e:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)  # 加载寄存器 s1
    80002580:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)  # 加载寄存器 s2
    80002582:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)  # 加载寄存器 s3
    80002586:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)  # 加载寄存器 s4
    8000258a:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)  # 加载寄存器 s5
    8000258e:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)  # 加载寄存器 s6
    80002592:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)  # 加载寄存器 s7
    80002596:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)  # 加载寄存器 s8
    8000259a:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)  # 加载寄存器 s9
    8000259e:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1) # 加载寄存器 s10
    800025a2:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)# 加载寄存器 s11
    800025a6:	0685bd83          	ld	s11,104(a1)

        ret             # 返回，完成上下文切换
    800025aa:	8082                	ret

00000000800025ac <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025ac:	1141                	addi	sp,sp,-16
    800025ae:	e406                	sd	ra,8(sp)
    800025b0:	e022                	sd	s0,0(sp)
    800025b2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025b4:	00005597          	auipc	a1,0x5
    800025b8:	dac58593          	addi	a1,a1,-596 # 80007360 <states.0+0x30>
    800025bc:	0001b517          	auipc	a0,0x1b
    800025c0:	56450513          	addi	a0,a0,1380 # 8001db20 <tickslock>
    800025c4:	eaafe0ef          	jal	ra,80000c6e <initlock>
}
    800025c8:	60a2                	ld	ra,8(sp)
    800025ca:	6402                	ld	s0,0(sp)
    800025cc:	0141                	addi	sp,sp,16
    800025ce:	8082                	ret

00000000800025d0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800025d0:	1141                	addi	sp,sp,-16
    800025d2:	e422                	sd	s0,8(sp)
    800025d4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025d6:	00003797          	auipc	a5,0x3
    800025da:	f9a78793          	addi	a5,a5,-102 # 80005570 <kernelvec>
    800025de:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800025e2:	6422                	ld	s0,8(sp)
    800025e4:	0141                	addi	sp,sp,16
    800025e6:	8082                	ret

00000000800025e8 <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    800025e8:	1141                	addi	sp,sp,-16
    800025ea:	e406                	sd	ra,8(sp)
    800025ec:	e022                	sd	s0,0(sp)
    800025ee:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800025f0:	c14ff0ef          	jal	ra,80001a04 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025f4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800025f8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025fa:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800025fe:	04000737          	lui	a4,0x4000
    80002602:	00004797          	auipc	a5,0x4
    80002606:	9fe78793          	addi	a5,a5,-1538 # 80006000 <_trampoline>
    8000260a:	00004697          	auipc	a3,0x4
    8000260e:	9f668693          	addi	a3,a3,-1546 # 80006000 <_trampoline>
    80002612:	8f95                	sub	a5,a5,a3
    80002614:	177d                	addi	a4,a4,-1
    80002616:	0732                	slli	a4,a4,0xc
    80002618:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000261a:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000261e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002620:	18002773          	csrr	a4,satp
    80002624:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002626:	6d38                	ld	a4,88(a0)
    80002628:	613c                	ld	a5,64(a0)
    8000262a:	6685                	lui	a3,0x1
    8000262c:	97b6                	add	a5,a5,a3
    8000262e:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002630:	6d3c                	ld	a5,88(a0)
    80002632:	00000717          	auipc	a4,0x0
    80002636:	0f470713          	addi	a4,a4,244 # 80002726 <usertrap>
    8000263a:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000263c:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000263e:	8712                	mv	a4,tp
    80002640:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002642:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002646:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000264a:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000264e:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002652:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002654:	6f9c                	ld	a5,24(a5)
    80002656:	14179073          	csrw	sepc,a5
}
    8000265a:	60a2                	ld	ra,8(sp)
    8000265c:	6402                	ld	s0,0(sp)
    8000265e:	0141                	addi	sp,sp,16
    80002660:	8082                	ret

0000000080002662 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002662:	1101                	addi	sp,sp,-32
    80002664:	ec06                	sd	ra,24(sp)
    80002666:	e822                	sd	s0,16(sp)
    80002668:	e426                	sd	s1,8(sp)
    8000266a:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    8000266c:	b6cff0ef          	jal	ra,800019d8 <cpuid>
    80002670:	cd19                	beqz	a0,8000268e <clockintr+0x2c>
  asm volatile("csrr %0, time" : "=r" (x) );
    80002672:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    80002676:	000f4737          	lui	a4,0xf4
    8000267a:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    8000267e:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80002680:	14d79073          	csrw	0x14d,a5
}
    80002684:	60e2                	ld	ra,24(sp)
    80002686:	6442                	ld	s0,16(sp)
    80002688:	64a2                	ld	s1,8(sp)
    8000268a:	6105                	addi	sp,sp,32
    8000268c:	8082                	ret
    acquire(&tickslock);
    8000268e:	0001b497          	auipc	s1,0x1b
    80002692:	49248493          	addi	s1,s1,1170 # 8001db20 <tickslock>
    80002696:	8526                	mv	a0,s1
    80002698:	e56fe0ef          	jal	ra,80000cee <acquire>
    ticks++;
    8000269c:	00005517          	auipc	a0,0x5
    800026a0:	37c50513          	addi	a0,a0,892 # 80007a18 <ticks>
    800026a4:	411c                	lw	a5,0(a0)
    800026a6:	2785                	addiw	a5,a5,1
    800026a8:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    800026aa:	9b9ff0ef          	jal	ra,80002062 <wakeup>
    release(&tickslock);
    800026ae:	8526                	mv	a0,s1
    800026b0:	ed6fe0ef          	jal	ra,80000d86 <release>
    800026b4:	bf7d                	j	80002672 <clockintr+0x10>

00000000800026b6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800026b6:	1101                	addi	sp,sp,-32
    800026b8:	ec06                	sd	ra,24(sp)
    800026ba:	e822                	sd	s0,16(sp)
    800026bc:	e426                	sd	s1,8(sp)
    800026be:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026c0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    800026c4:	57fd                	li	a5,-1
    800026c6:	17fe                	slli	a5,a5,0x3f
    800026c8:	07a5                	addi	a5,a5,9
    800026ca:	00f70d63          	beq	a4,a5,800026e4 <devintr+0x2e>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    800026ce:	57fd                	li	a5,-1
    800026d0:	17fe                	slli	a5,a5,0x3f
    800026d2:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    800026d4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    800026d6:	04f70463          	beq	a4,a5,8000271e <devintr+0x68>
  }
}
    800026da:	60e2                	ld	ra,24(sp)
    800026dc:	6442                	ld	s0,16(sp)
    800026de:	64a2                	ld	s1,8(sp)
    800026e0:	6105                	addi	sp,sp,32
    800026e2:	8082                	ret
    int irq = plic_claim();
    800026e4:	735020ef          	jal	ra,80005618 <plic_claim>
    800026e8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800026ea:	47a9                	li	a5,10
    800026ec:	02f50363          	beq	a0,a5,80002712 <devintr+0x5c>
    } else if(irq == VIRTIO0_IRQ){
    800026f0:	4785                	li	a5,1
    800026f2:	02f50363          	beq	a0,a5,80002718 <devintr+0x62>
    return 1;
    800026f6:	4505                	li	a0,1
    } else if(irq){
    800026f8:	d0ed                	beqz	s1,800026da <devintr+0x24>
      printf("unexpected interrupt irq=%d\n", irq);
    800026fa:	85a6                	mv	a1,s1
    800026fc:	00005517          	auipc	a0,0x5
    80002700:	c6c50513          	addi	a0,a0,-916 # 80007368 <states.0+0x38>
    80002704:	dc1fd0ef          	jal	ra,800004c4 <printf>
      plic_complete(irq);
    80002708:	8526                	mv	a0,s1
    8000270a:	72f020ef          	jal	ra,80005638 <plic_complete>
    return 1;
    8000270e:	4505                	li	a0,1
    80002710:	b7e9                	j	800026da <devintr+0x24>
      uartintr();
    80002712:	a46fe0ef          	jal	ra,80000958 <uartintr>
    80002716:	bfcd                	j	80002708 <devintr+0x52>
      virtio_disk_intr();
    80002718:	390030ef          	jal	ra,80005aa8 <virtio_disk_intr>
    8000271c:	b7f5                	j	80002708 <devintr+0x52>
    clockintr();
    8000271e:	f45ff0ef          	jal	ra,80002662 <clockintr>
    return 2;
    80002722:	4509                	li	a0,2
    80002724:	bf5d                	j	800026da <devintr+0x24>

0000000080002726 <usertrap>:
{
    80002726:	7139                	addi	sp,sp,-64
    80002728:	fc06                	sd	ra,56(sp)
    8000272a:	f822                	sd	s0,48(sp)
    8000272c:	f426                	sd	s1,40(sp)
    8000272e:	f04a                	sd	s2,32(sp)
    80002730:	ec4e                	sd	s3,24(sp)
    80002732:	e852                	sd	s4,16(sp)
    80002734:	e456                	sd	s5,8(sp)
    80002736:	e05a                	sd	s6,0(sp)
    80002738:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000273a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000273e:	1007f793          	andi	a5,a5,256
    80002742:	e3c1                	bnez	a5,800027c2 <usertrap+0x9c>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002744:	00003797          	auipc	a5,0x3
    80002748:	e2c78793          	addi	a5,a5,-468 # 80005570 <kernelvec>
    8000274c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002750:	ab4ff0ef          	jal	ra,80001a04 <myproc>
    80002754:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002756:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002758:	14102773          	csrr	a4,sepc
    8000275c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000275e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002762:	47a1                	li	a5,8
    80002764:	06f70563          	beq	a4,a5,800027ce <usertrap+0xa8>
  } else if((which_dev = devintr()) != 0){
    80002768:	f4fff0ef          	jal	ra,800026b6 <devintr>
    8000276c:	892a                	mv	s2,a0
    8000276e:	1a051563          	bnez	a0,80002918 <usertrap+0x1f2>
    80002772:	14202773          	csrr	a4,scause
    } else if (r_scause() == 15) {
    80002776:	47bd                	li	a5,15
    80002778:	14f71463          	bne	a4,a5,800028c0 <usertrap+0x19a>
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000277c:	143029f3          	csrr	s3,stval
    uint64 va = PGROUNDDOWN(r_stval());
    80002780:	77fd                	lui	a5,0xfffff
    80002782:	00f9f9b3          	and	s3,s3,a5
    if (va >= MAXVA){
    80002786:	57fd                	li	a5,-1
    80002788:	83e9                	srli	a5,a5,0x1a
    8000278a:	0737ea63          	bltu	a5,s3,800027fe <usertrap+0xd8>
    if (va > p->sz){
    8000278e:	64bc                	ld	a5,72(s1)
    80002790:	0937e063          	bltu	a5,s3,80002810 <usertrap+0xea>
    pte = walk(p->pagetable, va, 0);
    80002794:	4601                	li	a2,0
    80002796:	85ce                	mv	a1,s3
    80002798:	68a8                	ld	a0,80(s1)
    8000279a:	8a5fe0ef          	jal	ra,8000103e <walk>
    8000279e:	8a2a                	mv	s4,a0
    if(pte == 0 || ((*pte) & PTE_COW) == 0 || ((*pte) & PTE_V) == 0 || ((*pte) & PTE_U)==0){
    800027a0:	c901                	beqz	a0,800027b0 <usertrap+0x8a>
    800027a2:	611c                	ld	a5,0(a0)
    800027a4:	1117f693          	andi	a3,a5,273
    800027a8:	11100713          	li	a4,273
    800027ac:	06e68b63          	beq	a3,a4,80002822 <usertrap+0xfc>
      printf("usertrap: pte not exist or it's not cow page\n");
    800027b0:	00005517          	auipc	a0,0x5
    800027b4:	c3050513          	addi	a0,a0,-976 # 800073e0 <states.0+0xb0>
    800027b8:	d0dfd0ef          	jal	ra,800004c4 <printf>
      p->killed=1;
    800027bc:	4785                	li	a5,1
    800027be:	d49c                	sw	a5,40(s1)
      goto end;
    800027c0:	a22d                	j	800028ea <usertrap+0x1c4>
    panic("usertrap: not from user mode");
    800027c2:	00005517          	auipc	a0,0x5
    800027c6:	bc650513          	addi	a0,a0,-1082 # 80007388 <states.0+0x58>
    800027ca:	fc1fd0ef          	jal	ra,8000078a <panic>
    if(killed(p))
    800027ce:	a81ff0ef          	jal	ra,8000224e <killed>
    800027d2:	e115                	bnez	a0,800027f6 <usertrap+0xd0>
    p->trapframe->epc += 4;
    800027d4:	6cb8                	ld	a4,88(s1)
    800027d6:	6f1c                	ld	a5,24(a4)
    800027d8:	0791                	addi	a5,a5,4
    800027da:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027dc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027e0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027e4:	10079073          	csrw	sstatus,a5
    syscall();
    800027e8:	350000ef          	jal	ra,80002b38 <syscall>
  if(p->killed)
    800027ec:	549c                	lw	a5,40(s1)
    800027ee:	10078463          	beqz	a5,800028f6 <usertrap+0x1d0>
    800027f2:	4901                	li	s2,0
    800027f4:	a8dd                	j	800028ea <usertrap+0x1c4>
      kexit(-1);
    800027f6:	557d                	li	a0,-1
    800027f8:	92bff0ef          	jal	ra,80002122 <kexit>
    800027fc:	bfe1                	j	800027d4 <usertrap+0xae>
      printf("va is larger than MAXVA!\n");
    800027fe:	00005517          	auipc	a0,0x5
    80002802:	baa50513          	addi	a0,a0,-1110 # 800073a8 <states.0+0x78>
    80002806:	cbffd0ef          	jal	ra,800004c4 <printf>
      p->killed = 1;
    8000280a:	4785                	li	a5,1
    8000280c:	d49c                	sw	a5,40(s1)
      goto end;
    8000280e:	a8f1                	j	800028ea <usertrap+0x1c4>
      printf("va is larger than sz!\n");
    80002810:	00005517          	auipc	a0,0x5
    80002814:	bb850513          	addi	a0,a0,-1096 # 800073c8 <states.0+0x98>
    80002818:	cadfd0ef          	jal	ra,800004c4 <printf>
      p->killed = 1;
    8000281c:	4785                	li	a5,1
    8000281e:	d49c                	sw	a5,40(s1)
      goto end;
    80002820:	a0e9                	j	800028ea <usertrap+0x1c4>
    if(*pte & PTE_COW){
    80002822:	1007f793          	andi	a5,a5,256
    80002826:	c7c1                	beqz	a5,800028ae <usertrap+0x188>
      if((mem = kalloc()) == 0)
    80002828:	bc6fe0ef          	jal	ra,80000bee <kalloc>
    8000282c:	8aaa                	mv	s5,a0
    8000282e:	c129                	beqz	a0,80002870 <usertrap+0x14a>
      memset(mem, 0, PGSIZE);
    80002830:	6605                	lui	a2,0x1
    80002832:	4581                	li	a1,0
    80002834:	d8efe0ef          	jal	ra,80000dc2 <memset>
      uint64 pa = walkaddr(p->pagetable, va);
    80002838:	85ce                	mv	a1,s3
    8000283a:	68a8                	ld	a0,80(s1)
    8000283c:	89dfe0ef          	jal	ra,800010d8 <walkaddr>
    80002840:	8b2a                	mv	s6,a0
      if(pa){
    80002842:	cd21                	beqz	a0,8000289a <usertrap+0x174>
        memmove(mem, (char*)pa, PGSIZE);
    80002844:	6605                	lui	a2,0x1
    80002846:	85aa                	mv	a1,a0
    80002848:	8556                	mv	a0,s5
    8000284a:	dd4fe0ef          	jal	ra,80000e1e <memmove>
        int perm = PTE_FLAGS(*pte);
    8000284e:	000a3703          	ld	a4,0(s4)
        perm &= ~PTE_COW;
    80002852:	2ff77713          	andi	a4,a4,767
        if(mappages(p->pagetable, va, PGSIZE, (uint64)mem, perm) != 0){
    80002856:	00476713          	ori	a4,a4,4
    8000285a:	86d6                	mv	a3,s5
    8000285c:	6605                	lui	a2,0x1
    8000285e:	85ce                	mv	a1,s3
    80002860:	68a8                	ld	a0,80(s1)
    80002862:	8b5fe0ef          	jal	ra,80001116 <mappages>
    80002866:	ed11                	bnez	a0,80002882 <usertrap+0x15c>
        kfree((void*) pa);
    80002868:	855a                	mv	a0,s6
    8000286a:	a3efe0ef          	jal	ra,80000aa8 <kfree>
    8000286e:	bfbd                	j	800027ec <usertrap+0xc6>
        printf("usertrap(): memery alloc fault\n");
    80002870:	00005517          	auipc	a0,0x5
    80002874:	ba050513          	addi	a0,a0,-1120 # 80007410 <states.0+0xe0>
    80002878:	c4dfd0ef          	jal	ra,800004c4 <printf>
        p->killed = 1;
    8000287c:	4785                	li	a5,1
    8000287e:	d49c                	sw	a5,40(s1)
        goto end;
    80002880:	a0ad                	j	800028ea <usertrap+0x1c4>
          printf("usertrap(): can not map page\n");
    80002882:	00005517          	auipc	a0,0x5
    80002886:	bae50513          	addi	a0,a0,-1106 # 80007430 <states.0+0x100>
    8000288a:	c3bfd0ef          	jal	ra,800004c4 <printf>
          kfree(mem); 
    8000288e:	8556                	mv	a0,s5
    80002890:	a18fe0ef          	jal	ra,80000aa8 <kfree>
          p->killed = 1;
    80002894:	4785                	li	a5,1
    80002896:	d49c                	sw	a5,40(s1)
          goto end;
    80002898:	a889                	j	800028ea <usertrap+0x1c4>
        printf("usertrap(): can not map va: %lx \n", va);
    8000289a:	85ce                	mv	a1,s3
    8000289c:	00005517          	auipc	a0,0x5
    800028a0:	bb450513          	addi	a0,a0,-1100 # 80007450 <states.0+0x120>
    800028a4:	c21fd0ef          	jal	ra,800004c4 <printf>
        p->killed = 1;
    800028a8:	4785                	li	a5,1
    800028aa:	d49c                	sw	a5,40(s1)
        goto end;
    800028ac:	a83d                	j	800028ea <usertrap+0x1c4>
      printf("usertrap(): not caused by cow \n");
    800028ae:	00005517          	auipc	a0,0x5
    800028b2:	bca50513          	addi	a0,a0,-1078 # 80007478 <states.0+0x148>
    800028b6:	c0ffd0ef          	jal	ra,800004c4 <printf>
      p->killed = 1;
    800028ba:	4785                	li	a5,1
    800028bc:	d49c                	sw	a5,40(s1)
      goto end;
    800028be:	a035                	j	800028ea <usertrap+0x1c4>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %lx pid=%d\n", r_scause(), p->pid);
    800028c4:	5890                	lw	a2,48(s1)
    800028c6:	00005517          	auipc	a0,0x5
    800028ca:	bd250513          	addi	a0,a0,-1070 # 80007498 <states.0+0x168>
    800028ce:	bf7fd0ef          	jal	ra,800004c4 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028d2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028d6:	14302673          	csrr	a2,stval
    printf("            sepc=%lx stval=%lx\n", r_sepc(), r_stval()); 
    800028da:	00005517          	auipc	a0,0x5
    800028de:	bee50513          	addi	a0,a0,-1042 # 800074c8 <states.0+0x198>
    800028e2:	be3fd0ef          	jal	ra,800004c4 <printf>
    p->killed = 1;
    800028e6:	4785                	li	a5,1
    800028e8:	d49c                	sw	a5,40(s1)
    kexit(-1);
    800028ea:	557d                	li	a0,-1
    800028ec:	837ff0ef          	jal	ra,80002122 <kexit>
  if(which_dev == 2){
    800028f0:	4789                	li	a5,2
    800028f2:	02f90663          	beq	s2,a5,8000291e <usertrap+0x1f8>
  prepare_return();
    800028f6:	cf3ff0ef          	jal	ra,800025e8 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800028fa:	68a8                	ld	a0,80(s1)
    800028fc:	8131                	srli	a0,a0,0xc
    800028fe:	57fd                	li	a5,-1
    80002900:	17fe                	slli	a5,a5,0x3f
    80002902:	8d5d                	or	a0,a0,a5
}
    80002904:	70e2                	ld	ra,56(sp)
    80002906:	7442                	ld	s0,48(sp)
    80002908:	74a2                	ld	s1,40(sp)
    8000290a:	7902                	ld	s2,32(sp)
    8000290c:	69e2                	ld	s3,24(sp)
    8000290e:	6a42                	ld	s4,16(sp)
    80002910:	6aa2                	ld	s5,8(sp)
    80002912:	6b02                	ld	s6,0(sp)
    80002914:	6121                	addi	sp,sp,64
    80002916:	8082                	ret
  if(p->killed)
    80002918:	549c                	lw	a5,40(s1)
    8000291a:	dbf9                	beqz	a5,800028f0 <usertrap+0x1ca>
    8000291c:	b7f9                	j	800028ea <usertrap+0x1c4>
    yield();
    8000291e:	eccff0ef          	jal	ra,80001fea <yield>
    80002922:	bfd1                	j	800028f6 <usertrap+0x1d0>

0000000080002924 <kerneltrap>:
{
    80002924:	7179                	addi	sp,sp,-48
    80002926:	f406                	sd	ra,40(sp)
    80002928:	f022                	sd	s0,32(sp)
    8000292a:	ec26                	sd	s1,24(sp)
    8000292c:	e84a                	sd	s2,16(sp)
    8000292e:	e44e                	sd	s3,8(sp)
    80002930:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002932:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002936:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000293a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000293e:	1004f793          	andi	a5,s1,256
    80002942:	c795                	beqz	a5,8000296e <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002944:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002948:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000294a:	eb85                	bnez	a5,8000297a <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    8000294c:	d6bff0ef          	jal	ra,800026b6 <devintr>
    80002950:	c91d                	beqz	a0,80002986 <kerneltrap+0x62>
  if(which_dev == 2&&myproc()!=0) { // timer interrupt
    80002952:	4789                	li	a5,2
    80002954:	04f50a63          	beq	a0,a5,800029a8 <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002958:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000295c:	10049073          	csrw	sstatus,s1
}
    80002960:	70a2                	ld	ra,40(sp)
    80002962:	7402                	ld	s0,32(sp)
    80002964:	64e2                	ld	s1,24(sp)
    80002966:	6942                	ld	s2,16(sp)
    80002968:	69a2                	ld	s3,8(sp)
    8000296a:	6145                	addi	sp,sp,48
    8000296c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000296e:	00005517          	auipc	a0,0x5
    80002972:	b7a50513          	addi	a0,a0,-1158 # 800074e8 <states.0+0x1b8>
    80002976:	e15fd0ef          	jal	ra,8000078a <panic>
    panic("kerneltrap: interrupts enabled");
    8000297a:	00005517          	auipc	a0,0x5
    8000297e:	b9650513          	addi	a0,a0,-1130 # 80007510 <states.0+0x1e0>
    80002982:	e09fd0ef          	jal	ra,8000078a <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002986:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000298a:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    8000298e:	85ce                	mv	a1,s3
    80002990:	00005517          	auipc	a0,0x5
    80002994:	ba050513          	addi	a0,a0,-1120 # 80007530 <states.0+0x200>
    80002998:	b2dfd0ef          	jal	ra,800004c4 <printf>
    panic("kerneltrap");
    8000299c:	00005517          	auipc	a0,0x5
    800029a0:	bbc50513          	addi	a0,a0,-1092 # 80007558 <states.0+0x228>
    800029a4:	de7fd0ef          	jal	ra,8000078a <panic>
  if(which_dev == 2&&myproc()!=0) { // timer interrupt
    800029a8:	85cff0ef          	jal	ra,80001a04 <myproc>
    800029ac:	d555                	beqz	a0,80002958 <kerneltrap+0x34>
    struct proc *p = myproc();
    800029ae:	856ff0ef          	jal	ra,80001a04 <myproc>
    800029b2:	89aa                	mv	s3,a0
    acquire(&p->lock);
    800029b4:	b3afe0ef          	jal	ra,80000cee <acquire>
    p->ticks++;
    800029b8:	1689a783          	lw	a5,360(s3)
    800029bc:	2785                	addiw	a5,a5,1
    800029be:	0007871b          	sext.w	a4,a5
    800029c2:	16f9a423          	sw	a5,360(s3)
    if (need_yield) {
    800029c6:	16c9a783          	lw	a5,364(s3)
    800029ca:	00f74a63          	blt	a4,a5,800029de <kerneltrap+0xba>
      p->ticks = 0; // 重置时间片计数器
    800029ce:	1609a423          	sw	zero,360(s3)
    release(&p->lock);
    800029d2:	854e                	mv	a0,s3
    800029d4:	bb2fe0ef          	jal	ra,80000d86 <release>
      yield(); // 时间片用完，主动让出 CPU
    800029d8:	e12ff0ef          	jal	ra,80001fea <yield>
    800029dc:	bfb5                	j	80002958 <kerneltrap+0x34>
    release(&p->lock);
    800029de:	854e                	mv	a0,s3
    800029e0:	ba6fe0ef          	jal	ra,80000d86 <release>
    if (need_yield) {
    800029e4:	bf95                	j	80002958 <kerneltrap+0x34>

00000000800029e6 <argraw>:
}

// 获取第 n 个系统调用的原始参数（未处理过的原始值）
static uint64
argraw(int n)
{
    800029e6:	1101                	addi	sp,sp,-32
    800029e8:	ec06                	sd	ra,24(sp)
    800029ea:	e822                	sd	s0,16(sp)
    800029ec:	e426                	sd	s1,8(sp)
    800029ee:	1000                	addi	s0,sp,32
    800029f0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029f2:	812ff0ef          	jal	ra,80001a04 <myproc>
  switch (n) {
    800029f6:	4795                	li	a5,5
    800029f8:	0497e163          	bltu	a5,s1,80002a3a <argraw+0x54>
    800029fc:	048a                	slli	s1,s1,0x2
    800029fe:	00005717          	auipc	a4,0x5
    80002a02:	b9270713          	addi	a4,a4,-1134 # 80007590 <states.0+0x260>
    80002a06:	94ba                	add	s1,s1,a4
    80002a08:	409c                	lw	a5,0(s1)
    80002a0a:	97ba                	add	a5,a5,a4
    80002a0c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a0e:	6d3c                	ld	a5,88(a0)
    80002a10:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");  // 如果参数 n 无效，触发 panic
  return -1;
}
    80002a12:	60e2                	ld	ra,24(sp)
    80002a14:	6442                	ld	s0,16(sp)
    80002a16:	64a2                	ld	s1,8(sp)
    80002a18:	6105                	addi	sp,sp,32
    80002a1a:	8082                	ret
    return p->trapframe->a1;
    80002a1c:	6d3c                	ld	a5,88(a0)
    80002a1e:	7fa8                	ld	a0,120(a5)
    80002a20:	bfcd                	j	80002a12 <argraw+0x2c>
    return p->trapframe->a2;
    80002a22:	6d3c                	ld	a5,88(a0)
    80002a24:	63c8                	ld	a0,128(a5)
    80002a26:	b7f5                	j	80002a12 <argraw+0x2c>
    return p->trapframe->a3;
    80002a28:	6d3c                	ld	a5,88(a0)
    80002a2a:	67c8                	ld	a0,136(a5)
    80002a2c:	b7dd                	j	80002a12 <argraw+0x2c>
    return p->trapframe->a4;
    80002a2e:	6d3c                	ld	a5,88(a0)
    80002a30:	6bc8                	ld	a0,144(a5)
    80002a32:	b7c5                	j	80002a12 <argraw+0x2c>
    return p->trapframe->a5;
    80002a34:	6d3c                	ld	a5,88(a0)
    80002a36:	6fc8                	ld	a0,152(a5)
    80002a38:	bfe9                	j	80002a12 <argraw+0x2c>
  panic("argraw");  // 如果参数 n 无效，触发 panic
    80002a3a:	00005517          	auipc	a0,0x5
    80002a3e:	b2e50513          	addi	a0,a0,-1234 # 80007568 <states.0+0x238>
    80002a42:	d49fd0ef          	jal	ra,8000078a <panic>

0000000080002a46 <fetchaddr>:
{
    80002a46:	1101                	addi	sp,sp,-32
    80002a48:	ec06                	sd	ra,24(sp)
    80002a4a:	e822                	sd	s0,16(sp)
    80002a4c:	e426                	sd	s1,8(sp)
    80002a4e:	e04a                	sd	s2,0(sp)
    80002a50:	1000                	addi	s0,sp,32
    80002a52:	84aa                	mv	s1,a0
    80002a54:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a56:	faffe0ef          	jal	ra,80001a04 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // 这两个条件都需要检查，防止溢出
    80002a5a:	653c                	ld	a5,72(a0)
    80002a5c:	02f4f663          	bgeu	s1,a5,80002a88 <fetchaddr+0x42>
    80002a60:	00848713          	addi	a4,s1,8
    80002a64:	02e7e463          	bltu	a5,a4,80002a8c <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a68:	46a1                	li	a3,8
    80002a6a:	8626                	mv	a2,s1
    80002a6c:	85ca                	mv	a1,s2
    80002a6e:	6928                	ld	a0,80(a0)
    80002a70:	da9fe0ef          	jal	ra,80001818 <copyin>
    80002a74:	00a03533          	snez	a0,a0
    80002a78:	40a00533          	neg	a0,a0
}
    80002a7c:	60e2                	ld	ra,24(sp)
    80002a7e:	6442                	ld	s0,16(sp)
    80002a80:	64a2                	ld	s1,8(sp)
    80002a82:	6902                	ld	s2,0(sp)
    80002a84:	6105                	addi	sp,sp,32
    80002a86:	8082                	ret
    return -1;
    80002a88:	557d                	li	a0,-1
    80002a8a:	bfcd                	j	80002a7c <fetchaddr+0x36>
    80002a8c:	557d                	li	a0,-1
    80002a8e:	b7fd                	j	80002a7c <fetchaddr+0x36>

0000000080002a90 <fetchstr>:
{
    80002a90:	7179                	addi	sp,sp,-48
    80002a92:	f406                	sd	ra,40(sp)
    80002a94:	f022                	sd	s0,32(sp)
    80002a96:	ec26                	sd	s1,24(sp)
    80002a98:	e84a                	sd	s2,16(sp)
    80002a9a:	e44e                	sd	s3,8(sp)
    80002a9c:	1800                	addi	s0,sp,48
    80002a9e:	892a                	mv	s2,a0
    80002aa0:	84ae                	mv	s1,a1
    80002aa2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002aa4:	f61fe0ef          	jal	ra,80001a04 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002aa8:	86ce                	mv	a3,s3
    80002aaa:	864a                	mv	a2,s2
    80002aac:	85a6                	mv	a1,s1
    80002aae:	6928                	ld	a0,80(a0)
    80002ab0:	c27fe0ef          	jal	ra,800016d6 <copyinstr>
    80002ab4:	00054c63          	bltz	a0,80002acc <fetchstr+0x3c>
  return strlen(buf);  // 返回字符串长度
    80002ab8:	8526                	mv	a0,s1
    80002aba:	c80fe0ef          	jal	ra,80000f3a <strlen>
}
    80002abe:	70a2                	ld	ra,40(sp)
    80002ac0:	7402                	ld	s0,32(sp)
    80002ac2:	64e2                	ld	s1,24(sp)
    80002ac4:	6942                	ld	s2,16(sp)
    80002ac6:	69a2                	ld	s3,8(sp)
    80002ac8:	6145                	addi	sp,sp,48
    80002aca:	8082                	ret
    return -1;
    80002acc:	557d                	li	a0,-1
    80002ace:	bfc5                	j	80002abe <fetchstr+0x2e>

0000000080002ad0 <argint>:

// 获取第 n 个 32 位的系统调用参数并将其存入 ip 中
void
argint(int n, int *ip)
{
    80002ad0:	1101                	addi	sp,sp,-32
    80002ad2:	ec06                	sd	ra,24(sp)
    80002ad4:	e822                	sd	s0,16(sp)
    80002ad6:	e426                	sd	s1,8(sp)
    80002ad8:	1000                	addi	s0,sp,32
    80002ada:	84ae                	mv	s1,a1
  *ip = argraw(n);  // 通过 argraw 获取原始参数并存储
    80002adc:	f0bff0ef          	jal	ra,800029e6 <argraw>
    80002ae0:	c088                	sw	a0,0(s1)
}
    80002ae2:	60e2                	ld	ra,24(sp)
    80002ae4:	6442                	ld	s0,16(sp)
    80002ae6:	64a2                	ld	s1,8(sp)
    80002ae8:	6105                	addi	sp,sp,32
    80002aea:	8082                	ret

0000000080002aec <argaddr>:

// 获取第 n 个参数并将其作为指针返回。
// 不进行合法性检查，因为 copyin 和 copyout 会处理这些检查。
void
argaddr(int n, uint64 *ip)
{
    80002aec:	1101                	addi	sp,sp,-32
    80002aee:	ec06                	sd	ra,24(sp)
    80002af0:	e822                	sd	s0,16(sp)
    80002af2:	e426                	sd	s1,8(sp)
    80002af4:	1000                	addi	s0,sp,32
    80002af6:	84ae                	mv	s1,a1
  *ip = argraw(n);  // 通过 argraw 获取原始参数并存储
    80002af8:	eefff0ef          	jal	ra,800029e6 <argraw>
    80002afc:	e088                	sd	a0,0(s1)
}
    80002afe:	60e2                	ld	ra,24(sp)
    80002b00:	6442                	ld	s0,16(sp)
    80002b02:	64a2                	ld	s1,8(sp)
    80002b04:	6105                	addi	sp,sp,32
    80002b06:	8082                	ret

0000000080002b08 <argstr>:
// 获取第 n 个参数，假设它是一个以 null 结尾的字符串。
// 将该字符串拷贝到 buf 中，最多拷贝 max 个字符。
// 成功时返回字符串长度（包括 null），出错时返回 -1。
int
argstr(int n, char *buf, int max)
{
    80002b08:	7179                	addi	sp,sp,-48
    80002b0a:	f406                	sd	ra,40(sp)
    80002b0c:	f022                	sd	s0,32(sp)
    80002b0e:	ec26                	sd	s1,24(sp)
    80002b10:	e84a                	sd	s2,16(sp)
    80002b12:	1800                	addi	s0,sp,48
    80002b14:	84ae                	mv	s1,a1
    80002b16:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);  // 获取第 n 个参数的地址
    80002b18:	fd840593          	addi	a1,s0,-40
    80002b1c:	fd1ff0ef          	jal	ra,80002aec <argaddr>
  return fetchstr(addr, buf, max);  // 使用 fetchstr 获取字符串内容
    80002b20:	864a                	mv	a2,s2
    80002b22:	85a6                	mv	a1,s1
    80002b24:	fd843503          	ld	a0,-40(s0)
    80002b28:	f69ff0ef          	jal	ra,80002a90 <fetchstr>
}
    80002b2c:	70a2                	ld	ra,40(sp)
    80002b2e:	7402                	ld	s0,32(sp)
    80002b30:	64e2                	ld	s1,24(sp)
    80002b32:	6942                	ld	s2,16(sp)
    80002b34:	6145                	addi	sp,sp,48
    80002b36:	8082                	ret

0000000080002b38 <syscall>:
};

// 系统调用的入口函数
void
syscall(void)
{
    80002b38:	1101                	addi	sp,sp,-32
    80002b3a:	ec06                	sd	ra,24(sp)
    80002b3c:	e822                	sd	s0,16(sp)
    80002b3e:	e426                	sd	s1,8(sp)
    80002b40:	e04a                	sd	s2,0(sp)
    80002b42:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b44:	ec1fe0ef          	jal	ra,80001a04 <myproc>
    80002b48:	84aa                	mv	s1,a0

  num = p->trapframe->a7;  // 从 trapframe 中获取系统调用号
    80002b4a:	05853903          	ld	s2,88(a0)
    80002b4e:	0a893783          	ld	a5,168(s2)
    80002b52:	0007869b          	sext.w	a3,a5
  // 检查系统调用号是否合法，且确保有对应的处理函数
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b56:	37fd                	addiw	a5,a5,-1
    80002b58:	4755                	li	a4,21
    80002b5a:	00f76f63          	bltu	a4,a5,80002b78 <syscall+0x40>
    80002b5e:	00369713          	slli	a4,a3,0x3
    80002b62:	00005797          	auipc	a5,0x5
    80002b66:	a4678793          	addi	a5,a5,-1466 # 800075a8 <syscalls>
    80002b6a:	97ba                	add	a5,a5,a4
    80002b6c:	639c                	ld	a5,0(a5)
    80002b6e:	c789                	beqz	a5,80002b78 <syscall+0x40>
    // 根据系统调用号查找对应的系统调用函数并调用
    // 系统调用的返回值会存储在 p->trapframe->a0 中
    p->trapframe->a0 = syscalls[num]();
    80002b70:	9782                	jalr	a5
    80002b72:	06a93823          	sd	a0,112(s2)
    80002b76:	a829                	j	80002b90 <syscall+0x58>
  } else {
    // 如果找不到有效的系统调用，打印错误信息
    printf("%d %s: unknown sys call %d\n",
    80002b78:	15848613          	addi	a2,s1,344
    80002b7c:	588c                	lw	a1,48(s1)
    80002b7e:	00005517          	auipc	a0,0x5
    80002b82:	9f250513          	addi	a0,a0,-1550 # 80007570 <states.0+0x240>
    80002b86:	93ffd0ef          	jal	ra,800004c4 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;  // 设置返回值为 -1 表示错误
    80002b8a:	6cbc                	ld	a5,88(s1)
    80002b8c:	577d                	li	a4,-1
    80002b8e:	fbb8                	sd	a4,112(a5)
  }
}
    80002b90:	60e2                	ld	ra,24(sp)
    80002b92:	6442                	ld	s0,16(sp)
    80002b94:	64a2                	ld	s1,8(sp)
    80002b96:	6902                	ld	s2,0(sp)
    80002b98:	6105                	addi	sp,sp,32
    80002b9a:	8082                	ret

0000000080002b9c <sys_exit>:
#include "vm.h"

// 进程退出系统调用
uint64
sys_exit(void)
{
    80002b9c:	1101                	addi	sp,sp,-32
    80002b9e:	ec06                	sd	ra,24(sp)
    80002ba0:	e822                	sd	s0,16(sp)
    80002ba2:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);  // 获取退出码
    80002ba4:	fec40593          	addi	a1,s0,-20
    80002ba8:	4501                	li	a0,0
    80002baa:	f27ff0ef          	jal	ra,80002ad0 <argint>
  kexit(n);       // 调用内核的退出函数
    80002bae:	fec42503          	lw	a0,-20(s0)
    80002bb2:	d70ff0ef          	jal	ra,80002122 <kexit>
  return 0;       // 不会执行到这里
}
    80002bb6:	4501                	li	a0,0
    80002bb8:	60e2                	ld	ra,24(sp)
    80002bba:	6442                	ld	s0,16(sp)
    80002bbc:	6105                	addi	sp,sp,32
    80002bbe:	8082                	ret

0000000080002bc0 <sys_getpid>:

// 获取当前进程的进程ID
uint64
sys_getpid(void)
{
    80002bc0:	1141                	addi	sp,sp,-16
    80002bc2:	e406                	sd	ra,8(sp)
    80002bc4:	e022                	sd	s0,0(sp)
    80002bc6:	0800                	addi	s0,sp,16
  return myproc()->pid;  // 返回当前进程的 PID
    80002bc8:	e3dfe0ef          	jal	ra,80001a04 <myproc>
}
    80002bcc:	5908                	lw	a0,48(a0)
    80002bce:	60a2                	ld	ra,8(sp)
    80002bd0:	6402                	ld	s0,0(sp)
    80002bd2:	0141                	addi	sp,sp,16
    80002bd4:	8082                	ret

0000000080002bd6 <sys_fork>:

// 创建一个新的子进程
uint64
sys_fork(void)
{
    80002bd6:	1141                	addi	sp,sp,-16
    80002bd8:	e406                	sd	ra,8(sp)
    80002bda:	e022                	sd	s0,0(sp)
    80002bdc:	0800                	addi	s0,sp,16
  return kfork();  // 调用内核的 fork 函数
    80002bde:	994ff0ef          	jal	ra,80001d72 <kfork>
}
    80002be2:	60a2                	ld	ra,8(sp)
    80002be4:	6402                	ld	s0,0(sp)
    80002be6:	0141                	addi	sp,sp,16
    80002be8:	8082                	ret

0000000080002bea <sys_wait>:

// 等待子进程退出
uint64
sys_wait(void)
{
    80002bea:	1101                	addi	sp,sp,-32
    80002bec:	ec06                	sd	ra,24(sp)
    80002bee:	e822                	sd	s0,16(sp)
    80002bf0:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);  // 获取等待子进程状态的地址
    80002bf2:	fe840593          	addi	a1,s0,-24
    80002bf6:	4501                	li	a0,0
    80002bf8:	ef5ff0ef          	jal	ra,80002aec <argaddr>
  return kwait(p);  // 调用内核的 wait 函数
    80002bfc:	fe843503          	ld	a0,-24(s0)
    80002c00:	e78ff0ef          	jal	ra,80002278 <kwait>
}
    80002c04:	60e2                	ld	ra,24(sp)
    80002c06:	6442                	ld	s0,16(sp)
    80002c08:	6105                	addi	sp,sp,32
    80002c0a:	8082                	ret

0000000080002c0c <sys_sbrk>:

// 扩展或收缩进程的内存
uint64
sys_sbrk(void)
{
    80002c0c:	7179                	addi	sp,sp,-48
    80002c0e:	f406                	sd	ra,40(sp)
    80002c10:	f022                	sd	s0,32(sp)
    80002c12:	ec26                	sd	s1,24(sp)
    80002c14:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);  // 获取内存增量
    80002c16:	fd840593          	addi	a1,s0,-40
    80002c1a:	4501                	li	a0,0
    80002c1c:	eb5ff0ef          	jal	ra,80002ad0 <argint>
  argint(1, &t);  // 获取是否懒加载标志
    80002c20:	fdc40593          	addi	a1,s0,-36
    80002c24:	4505                	li	a0,1
    80002c26:	eabff0ef          	jal	ra,80002ad0 <argint>
  addr = myproc()->sz;  // 获取当前进程的内存大小
    80002c2a:	ddbfe0ef          	jal	ra,80001a04 <myproc>
    80002c2e:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {  // 如果是急切分配或要求收缩内存
    80002c30:	fdc42703          	lw	a4,-36(s0)
    80002c34:	4785                	li	a5,1
    80002c36:	02f70763          	beq	a4,a5,80002c64 <sys_sbrk+0x58>
    80002c3a:	fd842783          	lw	a5,-40(s0)
    80002c3e:	0207c363          	bltz	a5,80002c64 <sys_sbrk+0x58>
    if(growproc(n) < 0) {  // 调用内核的 growproc 函数调整内存
      return -1;  // 内存分配失败
    }
  } else {  // 如果是懒加载分配
    if(addr + n < addr)  // 防止内存溢出
    80002c42:	97a6                	add	a5,a5,s1
    80002c44:	0297ee63          	bltu	a5,s1,80002c80 <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)  // 限制内存的最大值
    80002c48:	02000737          	lui	a4,0x2000
    80002c4c:	177d                	addi	a4,a4,-1
    80002c4e:	0736                	slli	a4,a4,0xd
    80002c50:	02f76a63          	bltu	a4,a5,80002c84 <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;  // 调整进程的内存大小
    80002c54:	db1fe0ef          	jal	ra,80001a04 <myproc>
    80002c58:	fd842703          	lw	a4,-40(s0)
    80002c5c:	653c                	ld	a5,72(a0)
    80002c5e:	97ba                	add	a5,a5,a4
    80002c60:	e53c                	sd	a5,72(a0)
    80002c62:	a039                	j	80002c70 <sys_sbrk+0x64>
    if(growproc(n) < 0) {  // 调用内核的 growproc 函数调整内存
    80002c64:	fd842503          	lw	a0,-40(s0)
    80002c68:	8a8ff0ef          	jal	ra,80001d10 <growproc>
    80002c6c:	00054863          	bltz	a0,80002c7c <sys_sbrk+0x70>
  }
  return addr;  // 返回原内存地址
}
    80002c70:	8526                	mv	a0,s1
    80002c72:	70a2                	ld	ra,40(sp)
    80002c74:	7402                	ld	s0,32(sp)
    80002c76:	64e2                	ld	s1,24(sp)
    80002c78:	6145                	addi	sp,sp,48
    80002c7a:	8082                	ret
      return -1;  // 内存分配失败
    80002c7c:	54fd                	li	s1,-1
    80002c7e:	bfcd                	j	80002c70 <sys_sbrk+0x64>
      return -1;
    80002c80:	54fd                	li	s1,-1
    80002c82:	b7fd                	j	80002c70 <sys_sbrk+0x64>
      return -1;
    80002c84:	54fd                	li	s1,-1
    80002c86:	b7ed                	j	80002c70 <sys_sbrk+0x64>

0000000080002c88 <sys_pause>:

// 让当前进程挂起指定时间
uint64
sys_pause(void)
{
    80002c88:	7139                	addi	sp,sp,-64
    80002c8a:	fc06                	sd	ra,56(sp)
    80002c8c:	f822                	sd	s0,48(sp)
    80002c8e:	f426                	sd	s1,40(sp)
    80002c90:	f04a                	sd	s2,32(sp)
    80002c92:	ec4e                	sd	s3,24(sp)
    80002c94:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);  // 获取暂停的时长（以时钟滴答为单位）
    80002c96:	fcc40593          	addi	a1,s0,-52
    80002c9a:	4501                	li	a0,0
    80002c9c:	e35ff0ef          	jal	ra,80002ad0 <argint>
  if(n < 0)  // 如果给定的时长为负，则设置为 0
    80002ca0:	fcc42783          	lw	a5,-52(s0)
    80002ca4:	0607c563          	bltz	a5,80002d0e <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);  // 获取时钟锁
    80002ca8:	0001b517          	auipc	a0,0x1b
    80002cac:	e7850513          	addi	a0,a0,-392 # 8001db20 <tickslock>
    80002cb0:	83efe0ef          	jal	ra,80000cee <acquire>
  ticks0 = ticks;  // 记录当前的时钟滴答数
    80002cb4:	00005917          	auipc	s2,0x5
    80002cb8:	d6492903          	lw	s2,-668(s2) # 80007a18 <ticks>
  while(ticks - ticks0 < n){  // 持续等待直到经过了指定的时间
    80002cbc:	fcc42783          	lw	a5,-52(s0)
    80002cc0:	cb8d                	beqz	a5,80002cf2 <sys_pause+0x6a>
    if(killed(myproc())){  // 如果进程被杀死，退出等待
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);  // 进程进入休眠状态，等待时钟更新
    80002cc2:	0001b997          	auipc	s3,0x1b
    80002cc6:	e5e98993          	addi	s3,s3,-418 # 8001db20 <tickslock>
    80002cca:	00005497          	auipc	s1,0x5
    80002cce:	d4e48493          	addi	s1,s1,-690 # 80007a18 <ticks>
    if(killed(myproc())){  // 如果进程被杀死，退出等待
    80002cd2:	d33fe0ef          	jal	ra,80001a04 <myproc>
    80002cd6:	d78ff0ef          	jal	ra,8000224e <killed>
    80002cda:	ed0d                	bnez	a0,80002d14 <sys_pause+0x8c>
    sleep(&ticks, &tickslock);  // 进程进入休眠状态，等待时钟更新
    80002cdc:	85ce                	mv	a1,s3
    80002cde:	8526                	mv	a0,s1
    80002ce0:	b36ff0ef          	jal	ra,80002016 <sleep>
  while(ticks - ticks0 < n){  // 持续等待直到经过了指定的时间
    80002ce4:	409c                	lw	a5,0(s1)
    80002ce6:	412787bb          	subw	a5,a5,s2
    80002cea:	fcc42703          	lw	a4,-52(s0)
    80002cee:	fee7e2e3          	bltu	a5,a4,80002cd2 <sys_pause+0x4a>
  }
  release(&tickslock);  // 释放时钟锁
    80002cf2:	0001b517          	auipc	a0,0x1b
    80002cf6:	e2e50513          	addi	a0,a0,-466 # 8001db20 <tickslock>
    80002cfa:	88cfe0ef          	jal	ra,80000d86 <release>
  return 0;  // 返回
    80002cfe:	4501                	li	a0,0
}
    80002d00:	70e2                	ld	ra,56(sp)
    80002d02:	7442                	ld	s0,48(sp)
    80002d04:	74a2                	ld	s1,40(sp)
    80002d06:	7902                	ld	s2,32(sp)
    80002d08:	69e2                	ld	s3,24(sp)
    80002d0a:	6121                	addi	sp,sp,64
    80002d0c:	8082                	ret
    n = 0;
    80002d0e:	fc042623          	sw	zero,-52(s0)
    80002d12:	bf59                	j	80002ca8 <sys_pause+0x20>
      release(&tickslock);
    80002d14:	0001b517          	auipc	a0,0x1b
    80002d18:	e0c50513          	addi	a0,a0,-500 # 8001db20 <tickslock>
    80002d1c:	86afe0ef          	jal	ra,80000d86 <release>
      return -1;
    80002d20:	557d                	li	a0,-1
    80002d22:	bff9                	j	80002d00 <sys_pause+0x78>

0000000080002d24 <sys_kill>:

// 终止指定进程
uint64
sys_kill(void)
{
    80002d24:	1101                	addi	sp,sp,-32
    80002d26:	ec06                	sd	ra,24(sp)
    80002d28:	e822                	sd	s0,16(sp)
    80002d2a:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);  // 获取进程 ID
    80002d2c:	fec40593          	addi	a1,s0,-20
    80002d30:	4501                	li	a0,0
    80002d32:	d9fff0ef          	jal	ra,80002ad0 <argint>
  return kkill(pid);  // 调用内核的 kill 函数终止进程
    80002d36:	fec42503          	lw	a0,-20(s0)
    80002d3a:	c8aff0ef          	jal	ra,800021c4 <kkill>
}
    80002d3e:	60e2                	ld	ra,24(sp)
    80002d40:	6442                	ld	s0,16(sp)
    80002d42:	6105                	addi	sp,sp,32
    80002d44:	8082                	ret

0000000080002d46 <sys_uptime>:

// 返回自系统启动以来经过的时钟滴答数
uint64
sys_uptime(void)
{
    80002d46:	1101                	addi	sp,sp,-32
    80002d48:	ec06                	sd	ra,24(sp)
    80002d4a:	e822                	sd	s0,16(sp)
    80002d4c:	e426                	sd	s1,8(sp)
    80002d4e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);  // 获取时钟锁
    80002d50:	0001b517          	auipc	a0,0x1b
    80002d54:	dd050513          	addi	a0,a0,-560 # 8001db20 <tickslock>
    80002d58:	f97fd0ef          	jal	ra,80000cee <acquire>
  xticks = ticks;  // 获取当前的时钟滴答数
    80002d5c:	00005497          	auipc	s1,0x5
    80002d60:	cbc4a483          	lw	s1,-836(s1) # 80007a18 <ticks>
  release(&tickslock);  // 释放时钟锁
    80002d64:	0001b517          	auipc	a0,0x1b
    80002d68:	dbc50513          	addi	a0,a0,-580 # 8001db20 <tickslock>
    80002d6c:	81afe0ef          	jal	ra,80000d86 <release>
  return xticks;  // 返回时钟滴答数
}
    80002d70:	02049513          	slli	a0,s1,0x20
    80002d74:	9101                	srli	a0,a0,0x20
    80002d76:	60e2                	ld	ra,24(sp)
    80002d78:	6442                	ld	s0,16(sp)
    80002d7a:	64a2                	ld	s1,8(sp)
    80002d7c:	6105                	addi	sp,sp,32
    80002d7e:	8082                	ret

0000000080002d80 <binit>:
} bcache;

// 初始化缓冲区缓存
void
binit(void)
{
    80002d80:	7179                	addi	sp,sp,-48
    80002d82:	f406                	sd	ra,40(sp)
    80002d84:	f022                	sd	s0,32(sp)
    80002d86:	ec26                	sd	s1,24(sp)
    80002d88:	e84a                	sd	s2,16(sp)
    80002d8a:	e44e                	sd	s3,8(sp)
    80002d8c:	e052                	sd	s4,0(sp)
    80002d8e:	1800                	addi	s0,sp,48
  struct buf *b;

  // 初始化缓冲区缓存的锁
  initlock(&bcache.lock, "bcache");
    80002d90:	00005597          	auipc	a1,0x5
    80002d94:	8d058593          	addi	a1,a1,-1840 # 80007660 <syscalls+0xb8>
    80002d98:	0001b517          	auipc	a0,0x1b
    80002d9c:	da050513          	addi	a0,a0,-608 # 8001db38 <bcache>
    80002da0:	ecffd0ef          	jal	ra,80000c6e <initlock>

  // 创建缓冲区链表
  bcache.head.prev = &bcache.head;
    80002da4:	00023797          	auipc	a5,0x23
    80002da8:	d9478793          	addi	a5,a5,-620 # 80025b38 <bcache+0x8000>
    80002dac:	00023717          	auipc	a4,0x23
    80002db0:	ff470713          	addi	a4,a4,-12 # 80025da0 <bcache+0x8268>
    80002db4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002db8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf + NBUF; b++){
    80002dbc:	0001b497          	auipc	s1,0x1b
    80002dc0:	d9448493          	addi	s1,s1,-620 # 8001db50 <bcache+0x18>
    b->next = bcache.head.next;
    80002dc4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002dc6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");  // 初始化缓冲区的睡眠锁
    80002dc8:	00005a17          	auipc	s4,0x5
    80002dcc:	8a0a0a13          	addi	s4,s4,-1888 # 80007668 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002dd0:	2b893783          	ld	a5,696(s2)
    80002dd4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002dd6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");  // 初始化缓冲区的睡眠锁
    80002dda:	85d2                	mv	a1,s4
    80002ddc:	01048513          	addi	a0,s1,16
    80002de0:	2fe010ef          	jal	ra,800040de <initsleeplock>
    bcache.head.next->prev = b;
    80002de4:	2b893783          	ld	a5,696(s2)
    80002de8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002dea:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf + NBUF; b++){
    80002dee:	45848493          	addi	s1,s1,1112
    80002df2:	fd349fe3          	bne	s1,s3,80002dd0 <binit+0x50>
  }
}
    80002df6:	70a2                	ld	ra,40(sp)
    80002df8:	7402                	ld	s0,32(sp)
    80002dfa:	64e2                	ld	s1,24(sp)
    80002dfc:	6942                	ld	s2,16(sp)
    80002dfe:	69a2                	ld	s3,8(sp)
    80002e00:	6a02                	ld	s4,0(sp)
    80002e02:	6145                	addi	sp,sp,48
    80002e04:	8082                	ret

0000000080002e06 <bread>:
}

// 获取指定磁盘块的缓冲区并返回，内容从磁盘读取
struct buf*
bread(uint dev, uint blockno)
{
    80002e06:	7179                	addi	sp,sp,-48
    80002e08:	f406                	sd	ra,40(sp)
    80002e0a:	f022                	sd	s0,32(sp)
    80002e0c:	ec26                	sd	s1,24(sp)
    80002e0e:	e84a                	sd	s2,16(sp)
    80002e10:	e44e                	sd	s3,8(sp)
    80002e12:	1800                	addi	s0,sp,48
    80002e14:	892a                	mv	s2,a0
    80002e16:	89ae                	mv	s3,a1
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002e18:	0001b517          	auipc	a0,0x1b
    80002e1c:	d2050513          	addi	a0,a0,-736 # 8001db38 <bcache>
    80002e20:	ecffd0ef          	jal	ra,80000cee <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e24:	00023497          	auipc	s1,0x23
    80002e28:	fcc4b483          	ld	s1,-52(s1) # 80025df0 <bcache+0x82b8>
    80002e2c:	00023797          	auipc	a5,0x23
    80002e30:	f7478793          	addi	a5,a5,-140 # 80025da0 <bcache+0x8268>
    80002e34:	02f48b63          	beq	s1,a5,80002e6a <bread+0x64>
    80002e38:	873e                	mv	a4,a5
    80002e3a:	a021                	j	80002e42 <bread+0x3c>
    80002e3c:	68a4                	ld	s1,80(s1)
    80002e3e:	02e48663          	beq	s1,a4,80002e6a <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002e42:	449c                	lw	a5,8(s1)
    80002e44:	ff279ce3          	bne	a5,s2,80002e3c <bread+0x36>
    80002e48:	44dc                	lw	a5,12(s1)
    80002e4a:	ff3799e3          	bne	a5,s3,80002e3c <bread+0x36>
      b->refcnt++;  // 增加引用计数
    80002e4e:	40bc                	lw	a5,64(s1)
    80002e50:	2785                	addiw	a5,a5,1
    80002e52:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002e54:	0001b517          	auipc	a0,0x1b
    80002e58:	ce450513          	addi	a0,a0,-796 # 8001db38 <bcache>
    80002e5c:	f2bfd0ef          	jal	ra,80000d86 <release>
      acquiresleep(&b->lock);  // 获取缓冲区的睡眠锁
    80002e60:	01048513          	addi	a0,s1,16
    80002e64:	2b0010ef          	jal	ra,80004114 <acquiresleep>
      return b;  // 返回缓冲区
    80002e68:	a889                	j	80002eba <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e6a:	00023497          	auipc	s1,0x23
    80002e6e:	f7e4b483          	ld	s1,-130(s1) # 80025de8 <bcache+0x82b0>
    80002e72:	00023797          	auipc	a5,0x23
    80002e76:	f2e78793          	addi	a5,a5,-210 # 80025da0 <bcache+0x8268>
    80002e7a:	00f48863          	beq	s1,a5,80002e8a <bread+0x84>
    80002e7e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e80:	40bc                	lw	a5,64(s1)
    80002e82:	cb91                	beqz	a5,80002e96 <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e84:	64a4                	ld	s1,72(s1)
    80002e86:	fee49de3          	bne	s1,a4,80002e80 <bread+0x7a>
  panic("bget: no buffers");  // 如果没有找到可用的缓冲区，发生错误
    80002e8a:	00004517          	auipc	a0,0x4
    80002e8e:	7e650513          	addi	a0,a0,2022 # 80007670 <syscalls+0xc8>
    80002e92:	8f9fd0ef          	jal	ra,8000078a <panic>
      b->dev = dev;  // 设置设备号
    80002e96:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;  // 设置块号
    80002e9a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;  // 设置为无效
    80002e9e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;  // 引用计数设置为 1
    80002ea2:	4785                	li	a5,1
    80002ea4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002ea6:	0001b517          	auipc	a0,0x1b
    80002eaa:	c9250513          	addi	a0,a0,-878 # 8001db38 <bcache>
    80002eae:	ed9fd0ef          	jal	ra,80000d86 <release>
      acquiresleep(&b->lock);  // 获取缓冲区的睡眠锁
    80002eb2:	01048513          	addi	a0,s1,16
    80002eb6:	25e010ef          	jal	ra,80004114 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);  // 获取缓冲区
  if(!b->valid) {
    80002eba:	409c                	lw	a5,0(s1)
    80002ebc:	cb89                	beqz	a5,80002ece <bread+0xc8>
    virtio_disk_rw(b, 0);  // 从磁盘读取数据到缓冲区
    b->valid = 1;  // 设置缓冲区为有效
  }
  return b;  // 返回缓冲区
}
    80002ebe:	8526                	mv	a0,s1
    80002ec0:	70a2                	ld	ra,40(sp)
    80002ec2:	7402                	ld	s0,32(sp)
    80002ec4:	64e2                	ld	s1,24(sp)
    80002ec6:	6942                	ld	s2,16(sp)
    80002ec8:	69a2                	ld	s3,8(sp)
    80002eca:	6145                	addi	sp,sp,48
    80002ecc:	8082                	ret
    virtio_disk_rw(b, 0);  // 从磁盘读取数据到缓冲区
    80002ece:	4581                	li	a1,0
    80002ed0:	8526                	mv	a0,s1
    80002ed2:	1bb020ef          	jal	ra,8000588c <virtio_disk_rw>
    b->valid = 1;  // 设置缓冲区为有效
    80002ed6:	4785                	li	a5,1
    80002ed8:	c09c                	sw	a5,0(s1)
  return b;  // 返回缓冲区
    80002eda:	b7d5                	j	80002ebe <bread+0xb8>

0000000080002edc <bwrite>:

// 将缓冲区 b 的内容写入磁盘，必须先锁定缓冲区
void
bwrite(struct buf *b)
{
    80002edc:	1101                	addi	sp,sp,-32
    80002ede:	ec06                	sd	ra,24(sp)
    80002ee0:	e822                	sd	s0,16(sp)
    80002ee2:	e426                	sd	s1,8(sp)
    80002ee4:	1000                	addi	s0,sp,32
    80002ee6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ee8:	0541                	addi	a0,a0,16
    80002eea:	2a8010ef          	jal	ra,80004192 <holdingsleep>
    80002eee:	c911                	beqz	a0,80002f02 <bwrite+0x26>
    panic("bwrite");  // 检查是否持有缓冲区的锁
  virtio_disk_rw(b, 1);  // 将缓冲区内容写入磁盘
    80002ef0:	4585                	li	a1,1
    80002ef2:	8526                	mv	a0,s1
    80002ef4:	199020ef          	jal	ra,8000588c <virtio_disk_rw>
}
    80002ef8:	60e2                	ld	ra,24(sp)
    80002efa:	6442                	ld	s0,16(sp)
    80002efc:	64a2                	ld	s1,8(sp)
    80002efe:	6105                	addi	sp,sp,32
    80002f00:	8082                	ret
    panic("bwrite");  // 检查是否持有缓冲区的锁
    80002f02:	00004517          	auipc	a0,0x4
    80002f06:	78650513          	addi	a0,a0,1926 # 80007688 <syscalls+0xe0>
    80002f0a:	881fd0ef          	jal	ra,8000078a <panic>

0000000080002f0e <brelse>:

// 释放锁定的缓冲区，并将其移到最近使用的位置
void
brelse(struct buf *b)
{
    80002f0e:	1101                	addi	sp,sp,-32
    80002f10:	ec06                	sd	ra,24(sp)
    80002f12:	e822                	sd	s0,16(sp)
    80002f14:	e426                	sd	s1,8(sp)
    80002f16:	e04a                	sd	s2,0(sp)
    80002f18:	1000                	addi	s0,sp,32
    80002f1a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f1c:	01050913          	addi	s2,a0,16
    80002f20:	854a                	mv	a0,s2
    80002f22:	270010ef          	jal	ra,80004192 <holdingsleep>
    80002f26:	c13d                	beqz	a0,80002f8c <brelse+0x7e>
    panic("brelse");  // 检查是否持有缓冲区的锁

  releasesleep(&b->lock);  // 释放缓冲区的睡眠锁
    80002f28:	854a                	mv	a0,s2
    80002f2a:	230010ef          	jal	ra,8000415a <releasesleep>

  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002f2e:	0001b517          	auipc	a0,0x1b
    80002f32:	c0a50513          	addi	a0,a0,-1014 # 8001db38 <bcache>
    80002f36:	db9fd0ef          	jal	ra,80000cee <acquire>
  b->refcnt--;  // 减少引用计数
    80002f3a:	40bc                	lw	a5,64(s1)
    80002f3c:	37fd                	addiw	a5,a5,-1
    80002f3e:	0007871b          	sext.w	a4,a5
    80002f42:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f44:	eb05                	bnez	a4,80002f74 <brelse+0x66>
    // 如果没有其他进程在使用该缓冲区
    // 将缓冲区移到链表头部
    b->next->prev = b->prev;
    80002f46:	68bc                	ld	a5,80(s1)
    80002f48:	64b8                	ld	a4,72(s1)
    80002f4a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f4c:	64bc                	ld	a5,72(s1)
    80002f4e:	68b8                	ld	a4,80(s1)
    80002f50:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f52:	00023797          	auipc	a5,0x23
    80002f56:	be678793          	addi	a5,a5,-1050 # 80025b38 <bcache+0x8000>
    80002f5a:	2b87b703          	ld	a4,696(a5)
    80002f5e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f60:	00023717          	auipc	a4,0x23
    80002f64:	e4070713          	addi	a4,a4,-448 # 80025da0 <bcache+0x8268>
    80002f68:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f6a:	2b87b703          	ld	a4,696(a5)
    80002f6e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f70:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002f74:	0001b517          	auipc	a0,0x1b
    80002f78:	bc450513          	addi	a0,a0,-1084 # 8001db38 <bcache>
    80002f7c:	e0bfd0ef          	jal	ra,80000d86 <release>
}
    80002f80:	60e2                	ld	ra,24(sp)
    80002f82:	6442                	ld	s0,16(sp)
    80002f84:	64a2                	ld	s1,8(sp)
    80002f86:	6902                	ld	s2,0(sp)
    80002f88:	6105                	addi	sp,sp,32
    80002f8a:	8082                	ret
    panic("brelse");  // 检查是否持有缓冲区的锁
    80002f8c:	00004517          	auipc	a0,0x4
    80002f90:	70450513          	addi	a0,a0,1796 # 80007690 <syscalls+0xe8>
    80002f94:	ff6fd0ef          	jal	ra,8000078a <panic>

0000000080002f98 <bpin>:

// 增加缓冲区 b 的引用计数，用于防止缓冲区被释放
void
bpin(struct buf *b) {
    80002f98:	1101                	addi	sp,sp,-32
    80002f9a:	ec06                	sd	ra,24(sp)
    80002f9c:	e822                	sd	s0,16(sp)
    80002f9e:	e426                	sd	s1,8(sp)
    80002fa0:	1000                	addi	s0,sp,32
    80002fa2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002fa4:	0001b517          	auipc	a0,0x1b
    80002fa8:	b9450513          	addi	a0,a0,-1132 # 8001db38 <bcache>
    80002fac:	d43fd0ef          	jal	ra,80000cee <acquire>
  b->refcnt++;  // 增加引用计数
    80002fb0:	40bc                	lw	a5,64(s1)
    80002fb2:	2785                	addiw	a5,a5,1
    80002fb4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002fb6:	0001b517          	auipc	a0,0x1b
    80002fba:	b8250513          	addi	a0,a0,-1150 # 8001db38 <bcache>
    80002fbe:	dc9fd0ef          	jal	ra,80000d86 <release>
}
    80002fc2:	60e2                	ld	ra,24(sp)
    80002fc4:	6442                	ld	s0,16(sp)
    80002fc6:	64a2                	ld	s1,8(sp)
    80002fc8:	6105                	addi	sp,sp,32
    80002fca:	8082                	ret

0000000080002fcc <bunpin>:

// 减少缓冲区 b 的引用计数，用于缓冲区的释放
void
bunpin(struct buf *b) {
    80002fcc:	1101                	addi	sp,sp,-32
    80002fce:	ec06                	sd	ra,24(sp)
    80002fd0:	e822                	sd	s0,16(sp)
    80002fd2:	e426                	sd	s1,8(sp)
    80002fd4:	1000                	addi	s0,sp,32
    80002fd6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002fd8:	0001b517          	auipc	a0,0x1b
    80002fdc:	b6050513          	addi	a0,a0,-1184 # 8001db38 <bcache>
    80002fe0:	d0ffd0ef          	jal	ra,80000cee <acquire>
  b->refcnt--;  // 减少引用计数
    80002fe4:	40bc                	lw	a5,64(s1)
    80002fe6:	37fd                	addiw	a5,a5,-1
    80002fe8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002fea:	0001b517          	auipc	a0,0x1b
    80002fee:	b4e50513          	addi	a0,a0,-1202 # 8001db38 <bcache>
    80002ff2:	d95fd0ef          	jal	ra,80000d86 <release>
}
    80002ff6:	60e2                	ld	ra,24(sp)
    80002ff8:	6442                	ld	s0,16(sp)
    80002ffa:	64a2                	ld	s1,8(sp)
    80002ffc:	6105                	addi	sp,sp,32
    80002ffe:	8082                	ret

0000000080003000 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003000:	1101                	addi	sp,sp,-32
    80003002:	ec06                	sd	ra,24(sp)
    80003004:	e822                	sd	s0,16(sp)
    80003006:	e426                	sd	s1,8(sp)
    80003008:	e04a                	sd	s2,0(sp)
    8000300a:	1000                	addi	s0,sp,32
    8000300c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000300e:	00d5d59b          	srliw	a1,a1,0xd
    80003012:	00023797          	auipc	a5,0x23
    80003016:	2027a783          	lw	a5,514(a5) # 80026214 <sb+0x1c>
    8000301a:	9dbd                	addw	a1,a1,a5
    8000301c:	debff0ef          	jal	ra,80002e06 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003020:	0074f713          	andi	a4,s1,7
    80003024:	4785                	li	a5,1
    80003026:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000302a:	14ce                	slli	s1,s1,0x33
    8000302c:	90d9                	srli	s1,s1,0x36
    8000302e:	00950733          	add	a4,a0,s1
    80003032:	05874703          	lbu	a4,88(a4)
    80003036:	00e7f6b3          	and	a3,a5,a4
    8000303a:	c29d                	beqz	a3,80003060 <bfree+0x60>
    8000303c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000303e:	94aa                	add	s1,s1,a0
    80003040:	fff7c793          	not	a5,a5
    80003044:	8ff9                	and	a5,a5,a4
    80003046:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000304a:	7d1000ef          	jal	ra,8000401a <log_write>
  brelse(bp);
    8000304e:	854a                	mv	a0,s2
    80003050:	ebfff0ef          	jal	ra,80002f0e <brelse>
}
    80003054:	60e2                	ld	ra,24(sp)
    80003056:	6442                	ld	s0,16(sp)
    80003058:	64a2                	ld	s1,8(sp)
    8000305a:	6902                	ld	s2,0(sp)
    8000305c:	6105                	addi	sp,sp,32
    8000305e:	8082                	ret
    panic("freeing free block");
    80003060:	00004517          	auipc	a0,0x4
    80003064:	63850513          	addi	a0,a0,1592 # 80007698 <syscalls+0xf0>
    80003068:	f22fd0ef          	jal	ra,8000078a <panic>

000000008000306c <balloc>:
{
    8000306c:	711d                	addi	sp,sp,-96
    8000306e:	ec86                	sd	ra,88(sp)
    80003070:	e8a2                	sd	s0,80(sp)
    80003072:	e4a6                	sd	s1,72(sp)
    80003074:	e0ca                	sd	s2,64(sp)
    80003076:	fc4e                	sd	s3,56(sp)
    80003078:	f852                	sd	s4,48(sp)
    8000307a:	f456                	sd	s5,40(sp)
    8000307c:	f05a                	sd	s6,32(sp)
    8000307e:	ec5e                	sd	s7,24(sp)
    80003080:	e862                	sd	s8,16(sp)
    80003082:	e466                	sd	s9,8(sp)
    80003084:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003086:	00023797          	auipc	a5,0x23
    8000308a:	1767a783          	lw	a5,374(a5) # 800261fc <sb+0x4>
    8000308e:	0e078163          	beqz	a5,80003170 <balloc+0x104>
    80003092:	8baa                	mv	s7,a0
    80003094:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003096:	00023b17          	auipc	s6,0x23
    8000309a:	162b0b13          	addi	s6,s6,354 # 800261f8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000309e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030a0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030a2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030a4:	6c89                	lui	s9,0x2
    800030a6:	a0b5                	j	80003112 <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    800030a8:	974a                	add	a4,a4,s2
    800030aa:	8fd5                	or	a5,a5,a3
    800030ac:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800030b0:	854a                	mv	a0,s2
    800030b2:	769000ef          	jal	ra,8000401a <log_write>
        brelse(bp);
    800030b6:	854a                	mv	a0,s2
    800030b8:	e57ff0ef          	jal	ra,80002f0e <brelse>
  bp = bread(dev, bno);
    800030bc:	85a6                	mv	a1,s1
    800030be:	855e                	mv	a0,s7
    800030c0:	d47ff0ef          	jal	ra,80002e06 <bread>
    800030c4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800030c6:	40000613          	li	a2,1024
    800030ca:	4581                	li	a1,0
    800030cc:	05850513          	addi	a0,a0,88
    800030d0:	cf3fd0ef          	jal	ra,80000dc2 <memset>
  log_write(bp);
    800030d4:	854a                	mv	a0,s2
    800030d6:	745000ef          	jal	ra,8000401a <log_write>
  brelse(bp);
    800030da:	854a                	mv	a0,s2
    800030dc:	e33ff0ef          	jal	ra,80002f0e <brelse>
}
    800030e0:	8526                	mv	a0,s1
    800030e2:	60e6                	ld	ra,88(sp)
    800030e4:	6446                	ld	s0,80(sp)
    800030e6:	64a6                	ld	s1,72(sp)
    800030e8:	6906                	ld	s2,64(sp)
    800030ea:	79e2                	ld	s3,56(sp)
    800030ec:	7a42                	ld	s4,48(sp)
    800030ee:	7aa2                	ld	s5,40(sp)
    800030f0:	7b02                	ld	s6,32(sp)
    800030f2:	6be2                	ld	s7,24(sp)
    800030f4:	6c42                	ld	s8,16(sp)
    800030f6:	6ca2                	ld	s9,8(sp)
    800030f8:	6125                	addi	sp,sp,96
    800030fa:	8082                	ret
    brelse(bp);
    800030fc:	854a                	mv	a0,s2
    800030fe:	e11ff0ef          	jal	ra,80002f0e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003102:	015c87bb          	addw	a5,s9,s5
    80003106:	00078a9b          	sext.w	s5,a5
    8000310a:	004b2703          	lw	a4,4(s6)
    8000310e:	06eaf163          	bgeu	s5,a4,80003170 <balloc+0x104>
    bp = bread(dev, BBLOCK(b, sb));
    80003112:	41fad79b          	sraiw	a5,s5,0x1f
    80003116:	0137d79b          	srliw	a5,a5,0x13
    8000311a:	015787bb          	addw	a5,a5,s5
    8000311e:	40d7d79b          	sraiw	a5,a5,0xd
    80003122:	01cb2583          	lw	a1,28(s6)
    80003126:	9dbd                	addw	a1,a1,a5
    80003128:	855e                	mv	a0,s7
    8000312a:	cddff0ef          	jal	ra,80002e06 <bread>
    8000312e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003130:	004b2503          	lw	a0,4(s6)
    80003134:	000a849b          	sext.w	s1,s5
    80003138:	8662                	mv	a2,s8
    8000313a:	fca4f1e3          	bgeu	s1,a0,800030fc <balloc+0x90>
      m = 1 << (bi % 8);
    8000313e:	41f6579b          	sraiw	a5,a2,0x1f
    80003142:	01d7d69b          	srliw	a3,a5,0x1d
    80003146:	00c6873b          	addw	a4,a3,a2
    8000314a:	00777793          	andi	a5,a4,7
    8000314e:	9f95                	subw	a5,a5,a3
    80003150:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003154:	4037571b          	sraiw	a4,a4,0x3
    80003158:	00e906b3          	add	a3,s2,a4
    8000315c:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    80003160:	00d7f5b3          	and	a1,a5,a3
    80003164:	d1b1                	beqz	a1,800030a8 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003166:	2605                	addiw	a2,a2,1
    80003168:	2485                	addiw	s1,s1,1
    8000316a:	fd4618e3          	bne	a2,s4,8000313a <balloc+0xce>
    8000316e:	b779                	j	800030fc <balloc+0x90>
  printf("balloc: out of blocks\n");
    80003170:	00004517          	auipc	a0,0x4
    80003174:	54050513          	addi	a0,a0,1344 # 800076b0 <syscalls+0x108>
    80003178:	b4cfd0ef          	jal	ra,800004c4 <printf>
  return 0;
    8000317c:	4481                	li	s1,0
    8000317e:	b78d                	j	800030e0 <balloc+0x74>

0000000080003180 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003180:	7179                	addi	sp,sp,-48
    80003182:	f406                	sd	ra,40(sp)
    80003184:	f022                	sd	s0,32(sp)
    80003186:	ec26                	sd	s1,24(sp)
    80003188:	e84a                	sd	s2,16(sp)
    8000318a:	e44e                	sd	s3,8(sp)
    8000318c:	e052                	sd	s4,0(sp)
    8000318e:	1800                	addi	s0,sp,48
    80003190:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003192:	47ad                	li	a5,11
    80003194:	02b7e563          	bltu	a5,a1,800031be <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    80003198:	02059493          	slli	s1,a1,0x20
    8000319c:	9081                	srli	s1,s1,0x20
    8000319e:	048a                	slli	s1,s1,0x2
    800031a0:	94aa                	add	s1,s1,a0
    800031a2:	0504a903          	lw	s2,80(s1)
    800031a6:	06091663          	bnez	s2,80003212 <bmap+0x92>
      addr = balloc(ip->dev);
    800031aa:	4108                	lw	a0,0(a0)
    800031ac:	ec1ff0ef          	jal	ra,8000306c <balloc>
    800031b0:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800031b4:	04090f63          	beqz	s2,80003212 <bmap+0x92>
        return 0;
      ip->addrs[bn] = addr;
    800031b8:	0524a823          	sw	s2,80(s1)
    800031bc:	a899                	j	80003212 <bmap+0x92>
    }
    return addr;
  }
  bn -= NDIRECT;
    800031be:	ff45849b          	addiw	s1,a1,-12
    800031c2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800031c6:	0ff00793          	li	a5,255
    800031ca:	06e7eb63          	bltu	a5,a4,80003240 <bmap+0xc0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800031ce:	08052903          	lw	s2,128(a0)
    800031d2:	00091b63          	bnez	s2,800031e8 <bmap+0x68>
      addr = balloc(ip->dev);
    800031d6:	4108                	lw	a0,0(a0)
    800031d8:	e95ff0ef          	jal	ra,8000306c <balloc>
    800031dc:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800031e0:	02090963          	beqz	s2,80003212 <bmap+0x92>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800031e4:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800031e8:	85ca                	mv	a1,s2
    800031ea:	0009a503          	lw	a0,0(s3)
    800031ee:	c19ff0ef          	jal	ra,80002e06 <bread>
    800031f2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800031f4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800031f8:	02049593          	slli	a1,s1,0x20
    800031fc:	9181                	srli	a1,a1,0x20
    800031fe:	058a                	slli	a1,a1,0x2
    80003200:	00b784b3          	add	s1,a5,a1
    80003204:	0004a903          	lw	s2,0(s1)
    80003208:	00090e63          	beqz	s2,80003224 <bmap+0xa4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000320c:	8552                	mv	a0,s4
    8000320e:	d01ff0ef          	jal	ra,80002f0e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003212:	854a                	mv	a0,s2
    80003214:	70a2                	ld	ra,40(sp)
    80003216:	7402                	ld	s0,32(sp)
    80003218:	64e2                	ld	s1,24(sp)
    8000321a:	6942                	ld	s2,16(sp)
    8000321c:	69a2                	ld	s3,8(sp)
    8000321e:	6a02                	ld	s4,0(sp)
    80003220:	6145                	addi	sp,sp,48
    80003222:	8082                	ret
      addr = balloc(ip->dev);
    80003224:	0009a503          	lw	a0,0(s3)
    80003228:	e45ff0ef          	jal	ra,8000306c <balloc>
    8000322c:	0005091b          	sext.w	s2,a0
      if(addr){
    80003230:	fc090ee3          	beqz	s2,8000320c <bmap+0x8c>
        a[bn] = addr;
    80003234:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003238:	8552                	mv	a0,s4
    8000323a:	5e1000ef          	jal	ra,8000401a <log_write>
    8000323e:	b7f9                	j	8000320c <bmap+0x8c>
  panic("bmap: out of range");
    80003240:	00004517          	auipc	a0,0x4
    80003244:	48850513          	addi	a0,a0,1160 # 800076c8 <syscalls+0x120>
    80003248:	d42fd0ef          	jal	ra,8000078a <panic>

000000008000324c <iget>:
{
    8000324c:	7179                	addi	sp,sp,-48
    8000324e:	f406                	sd	ra,40(sp)
    80003250:	f022                	sd	s0,32(sp)
    80003252:	ec26                	sd	s1,24(sp)
    80003254:	e84a                	sd	s2,16(sp)
    80003256:	e44e                	sd	s3,8(sp)
    80003258:	e052                	sd	s4,0(sp)
    8000325a:	1800                	addi	s0,sp,48
    8000325c:	89aa                	mv	s3,a0
    8000325e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003260:	00023517          	auipc	a0,0x23
    80003264:	fb850513          	addi	a0,a0,-72 # 80026218 <itable>
    80003268:	a87fd0ef          	jal	ra,80000cee <acquire>
  empty = 0;
    8000326c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000326e:	00023497          	auipc	s1,0x23
    80003272:	fc248493          	addi	s1,s1,-62 # 80026230 <itable+0x18>
    80003276:	00025697          	auipc	a3,0x25
    8000327a:	a4a68693          	addi	a3,a3,-1462 # 80027cc0 <log>
    8000327e:	a039                	j	8000328c <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003280:	02090963          	beqz	s2,800032b2 <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003284:	08848493          	addi	s1,s1,136
    80003288:	02d48863          	beq	s1,a3,800032b8 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000328c:	449c                	lw	a5,8(s1)
    8000328e:	fef059e3          	blez	a5,80003280 <iget+0x34>
    80003292:	4098                	lw	a4,0(s1)
    80003294:	ff3716e3          	bne	a4,s3,80003280 <iget+0x34>
    80003298:	40d8                	lw	a4,4(s1)
    8000329a:	ff4713e3          	bne	a4,s4,80003280 <iget+0x34>
      ip->ref++;
    8000329e:	2785                	addiw	a5,a5,1
    800032a0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800032a2:	00023517          	auipc	a0,0x23
    800032a6:	f7650513          	addi	a0,a0,-138 # 80026218 <itable>
    800032aa:	addfd0ef          	jal	ra,80000d86 <release>
      return ip;
    800032ae:	8926                	mv	s2,s1
    800032b0:	a02d                	j	800032da <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800032b2:	fbe9                	bnez	a5,80003284 <iget+0x38>
    800032b4:	8926                	mv	s2,s1
    800032b6:	b7f9                	j	80003284 <iget+0x38>
  if(empty == 0)
    800032b8:	02090a63          	beqz	s2,800032ec <iget+0xa0>
  ip->dev = dev;
    800032bc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800032c0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800032c4:	4785                	li	a5,1
    800032c6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800032ca:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800032ce:	00023517          	auipc	a0,0x23
    800032d2:	f4a50513          	addi	a0,a0,-182 # 80026218 <itable>
    800032d6:	ab1fd0ef          	jal	ra,80000d86 <release>
}
    800032da:	854a                	mv	a0,s2
    800032dc:	70a2                	ld	ra,40(sp)
    800032de:	7402                	ld	s0,32(sp)
    800032e0:	64e2                	ld	s1,24(sp)
    800032e2:	6942                	ld	s2,16(sp)
    800032e4:	69a2                	ld	s3,8(sp)
    800032e6:	6a02                	ld	s4,0(sp)
    800032e8:	6145                	addi	sp,sp,48
    800032ea:	8082                	ret
    panic("iget: no inodes");
    800032ec:	00004517          	auipc	a0,0x4
    800032f0:	3f450513          	addi	a0,a0,1012 # 800076e0 <syscalls+0x138>
    800032f4:	c96fd0ef          	jal	ra,8000078a <panic>

00000000800032f8 <iinit>:
{
    800032f8:	7179                	addi	sp,sp,-48
    800032fa:	f406                	sd	ra,40(sp)
    800032fc:	f022                	sd	s0,32(sp)
    800032fe:	ec26                	sd	s1,24(sp)
    80003300:	e84a                	sd	s2,16(sp)
    80003302:	e44e                	sd	s3,8(sp)
    80003304:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003306:	00004597          	auipc	a1,0x4
    8000330a:	3ea58593          	addi	a1,a1,1002 # 800076f0 <syscalls+0x148>
    8000330e:	00023517          	auipc	a0,0x23
    80003312:	f0a50513          	addi	a0,a0,-246 # 80026218 <itable>
    80003316:	959fd0ef          	jal	ra,80000c6e <initlock>
  for(i = 0; i < NINODE; i++) {
    8000331a:	00023497          	auipc	s1,0x23
    8000331e:	f2648493          	addi	s1,s1,-218 # 80026240 <itable+0x28>
    80003322:	00025997          	auipc	s3,0x25
    80003326:	9ae98993          	addi	s3,s3,-1618 # 80027cd0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000332a:	00004917          	auipc	s2,0x4
    8000332e:	3ce90913          	addi	s2,s2,974 # 800076f8 <syscalls+0x150>
    80003332:	85ca                	mv	a1,s2
    80003334:	8526                	mv	a0,s1
    80003336:	5a9000ef          	jal	ra,800040de <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000333a:	08848493          	addi	s1,s1,136
    8000333e:	ff349ae3          	bne	s1,s3,80003332 <iinit+0x3a>
}
    80003342:	70a2                	ld	ra,40(sp)
    80003344:	7402                	ld	s0,32(sp)
    80003346:	64e2                	ld	s1,24(sp)
    80003348:	6942                	ld	s2,16(sp)
    8000334a:	69a2                	ld	s3,8(sp)
    8000334c:	6145                	addi	sp,sp,48
    8000334e:	8082                	ret

0000000080003350 <ialloc>:
{
    80003350:	715d                	addi	sp,sp,-80
    80003352:	e486                	sd	ra,72(sp)
    80003354:	e0a2                	sd	s0,64(sp)
    80003356:	fc26                	sd	s1,56(sp)
    80003358:	f84a                	sd	s2,48(sp)
    8000335a:	f44e                	sd	s3,40(sp)
    8000335c:	f052                	sd	s4,32(sp)
    8000335e:	ec56                	sd	s5,24(sp)
    80003360:	e85a                	sd	s6,16(sp)
    80003362:	e45e                	sd	s7,8(sp)
    80003364:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003366:	00023717          	auipc	a4,0x23
    8000336a:	e9e72703          	lw	a4,-354(a4) # 80026204 <sb+0xc>
    8000336e:	4785                	li	a5,1
    80003370:	04e7f663          	bgeu	a5,a4,800033bc <ialloc+0x6c>
    80003374:	8aaa                	mv	s5,a0
    80003376:	8bae                	mv	s7,a1
    80003378:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000337a:	00023a17          	auipc	s4,0x23
    8000337e:	e7ea0a13          	addi	s4,s4,-386 # 800261f8 <sb>
    80003382:	00048b1b          	sext.w	s6,s1
    80003386:	0044d793          	srli	a5,s1,0x4
    8000338a:	018a2583          	lw	a1,24(s4)
    8000338e:	9dbd                	addw	a1,a1,a5
    80003390:	8556                	mv	a0,s5
    80003392:	a75ff0ef          	jal	ra,80002e06 <bread>
    80003396:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003398:	05850993          	addi	s3,a0,88
    8000339c:	00f4f793          	andi	a5,s1,15
    800033a0:	079a                	slli	a5,a5,0x6
    800033a2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800033a4:	00099783          	lh	a5,0(s3)
    800033a8:	cf85                	beqz	a5,800033e0 <ialloc+0x90>
    brelse(bp);
    800033aa:	b65ff0ef          	jal	ra,80002f0e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800033ae:	0485                	addi	s1,s1,1
    800033b0:	00ca2703          	lw	a4,12(s4)
    800033b4:	0004879b          	sext.w	a5,s1
    800033b8:	fce7e5e3          	bltu	a5,a4,80003382 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800033bc:	00004517          	auipc	a0,0x4
    800033c0:	34450513          	addi	a0,a0,836 # 80007700 <syscalls+0x158>
    800033c4:	900fd0ef          	jal	ra,800004c4 <printf>
  return 0;
    800033c8:	4501                	li	a0,0
}
    800033ca:	60a6                	ld	ra,72(sp)
    800033cc:	6406                	ld	s0,64(sp)
    800033ce:	74e2                	ld	s1,56(sp)
    800033d0:	7942                	ld	s2,48(sp)
    800033d2:	79a2                	ld	s3,40(sp)
    800033d4:	7a02                	ld	s4,32(sp)
    800033d6:	6ae2                	ld	s5,24(sp)
    800033d8:	6b42                	ld	s6,16(sp)
    800033da:	6ba2                	ld	s7,8(sp)
    800033dc:	6161                	addi	sp,sp,80
    800033de:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800033e0:	04000613          	li	a2,64
    800033e4:	4581                	li	a1,0
    800033e6:	854e                	mv	a0,s3
    800033e8:	9dbfd0ef          	jal	ra,80000dc2 <memset>
      dip->type = type;
    800033ec:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800033f0:	854a                	mv	a0,s2
    800033f2:	429000ef          	jal	ra,8000401a <log_write>
      brelse(bp);
    800033f6:	854a                	mv	a0,s2
    800033f8:	b17ff0ef          	jal	ra,80002f0e <brelse>
      return iget(dev, inum);
    800033fc:	85da                	mv	a1,s6
    800033fe:	8556                	mv	a0,s5
    80003400:	e4dff0ef          	jal	ra,8000324c <iget>
    80003404:	b7d9                	j	800033ca <ialloc+0x7a>

0000000080003406 <iupdate>:
{
    80003406:	1101                	addi	sp,sp,-32
    80003408:	ec06                	sd	ra,24(sp)
    8000340a:	e822                	sd	s0,16(sp)
    8000340c:	e426                	sd	s1,8(sp)
    8000340e:	e04a                	sd	s2,0(sp)
    80003410:	1000                	addi	s0,sp,32
    80003412:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003414:	415c                	lw	a5,4(a0)
    80003416:	0047d79b          	srliw	a5,a5,0x4
    8000341a:	00023597          	auipc	a1,0x23
    8000341e:	df65a583          	lw	a1,-522(a1) # 80026210 <sb+0x18>
    80003422:	9dbd                	addw	a1,a1,a5
    80003424:	4108                	lw	a0,0(a0)
    80003426:	9e1ff0ef          	jal	ra,80002e06 <bread>
    8000342a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000342c:	05850793          	addi	a5,a0,88
    80003430:	40c8                	lw	a0,4(s1)
    80003432:	893d                	andi	a0,a0,15
    80003434:	051a                	slli	a0,a0,0x6
    80003436:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003438:	04449703          	lh	a4,68(s1)
    8000343c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003440:	04649703          	lh	a4,70(s1)
    80003444:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003448:	04849703          	lh	a4,72(s1)
    8000344c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003450:	04a49703          	lh	a4,74(s1)
    80003454:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003458:	44f8                	lw	a4,76(s1)
    8000345a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000345c:	03400613          	li	a2,52
    80003460:	05048593          	addi	a1,s1,80
    80003464:	0531                	addi	a0,a0,12
    80003466:	9b9fd0ef          	jal	ra,80000e1e <memmove>
  log_write(bp);
    8000346a:	854a                	mv	a0,s2
    8000346c:	3af000ef          	jal	ra,8000401a <log_write>
  brelse(bp);
    80003470:	854a                	mv	a0,s2
    80003472:	a9dff0ef          	jal	ra,80002f0e <brelse>
}
    80003476:	60e2                	ld	ra,24(sp)
    80003478:	6442                	ld	s0,16(sp)
    8000347a:	64a2                	ld	s1,8(sp)
    8000347c:	6902                	ld	s2,0(sp)
    8000347e:	6105                	addi	sp,sp,32
    80003480:	8082                	ret

0000000080003482 <idup>:
{
    80003482:	1101                	addi	sp,sp,-32
    80003484:	ec06                	sd	ra,24(sp)
    80003486:	e822                	sd	s0,16(sp)
    80003488:	e426                	sd	s1,8(sp)
    8000348a:	1000                	addi	s0,sp,32
    8000348c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000348e:	00023517          	auipc	a0,0x23
    80003492:	d8a50513          	addi	a0,a0,-630 # 80026218 <itable>
    80003496:	859fd0ef          	jal	ra,80000cee <acquire>
  ip->ref++;
    8000349a:	449c                	lw	a5,8(s1)
    8000349c:	2785                	addiw	a5,a5,1
    8000349e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800034a0:	00023517          	auipc	a0,0x23
    800034a4:	d7850513          	addi	a0,a0,-648 # 80026218 <itable>
    800034a8:	8dffd0ef          	jal	ra,80000d86 <release>
}
    800034ac:	8526                	mv	a0,s1
    800034ae:	60e2                	ld	ra,24(sp)
    800034b0:	6442                	ld	s0,16(sp)
    800034b2:	64a2                	ld	s1,8(sp)
    800034b4:	6105                	addi	sp,sp,32
    800034b6:	8082                	ret

00000000800034b8 <ilock>:
{
    800034b8:	1101                	addi	sp,sp,-32
    800034ba:	ec06                	sd	ra,24(sp)
    800034bc:	e822                	sd	s0,16(sp)
    800034be:	e426                	sd	s1,8(sp)
    800034c0:	e04a                	sd	s2,0(sp)
    800034c2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800034c4:	c105                	beqz	a0,800034e4 <ilock+0x2c>
    800034c6:	84aa                	mv	s1,a0
    800034c8:	451c                	lw	a5,8(a0)
    800034ca:	00f05d63          	blez	a5,800034e4 <ilock+0x2c>
  acquiresleep(&ip->lock);
    800034ce:	0541                	addi	a0,a0,16
    800034d0:	445000ef          	jal	ra,80004114 <acquiresleep>
  if(ip->valid == 0){
    800034d4:	40bc                	lw	a5,64(s1)
    800034d6:	cf89                	beqz	a5,800034f0 <ilock+0x38>
}
    800034d8:	60e2                	ld	ra,24(sp)
    800034da:	6442                	ld	s0,16(sp)
    800034dc:	64a2                	ld	s1,8(sp)
    800034de:	6902                	ld	s2,0(sp)
    800034e0:	6105                	addi	sp,sp,32
    800034e2:	8082                	ret
    panic("ilock");
    800034e4:	00004517          	auipc	a0,0x4
    800034e8:	23450513          	addi	a0,a0,564 # 80007718 <syscalls+0x170>
    800034ec:	a9efd0ef          	jal	ra,8000078a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800034f0:	40dc                	lw	a5,4(s1)
    800034f2:	0047d79b          	srliw	a5,a5,0x4
    800034f6:	00023597          	auipc	a1,0x23
    800034fa:	d1a5a583          	lw	a1,-742(a1) # 80026210 <sb+0x18>
    800034fe:	9dbd                	addw	a1,a1,a5
    80003500:	4088                	lw	a0,0(s1)
    80003502:	905ff0ef          	jal	ra,80002e06 <bread>
    80003506:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003508:	05850593          	addi	a1,a0,88
    8000350c:	40dc                	lw	a5,4(s1)
    8000350e:	8bbd                	andi	a5,a5,15
    80003510:	079a                	slli	a5,a5,0x6
    80003512:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003514:	00059783          	lh	a5,0(a1)
    80003518:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000351c:	00259783          	lh	a5,2(a1)
    80003520:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003524:	00459783          	lh	a5,4(a1)
    80003528:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000352c:	00659783          	lh	a5,6(a1)
    80003530:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003534:	459c                	lw	a5,8(a1)
    80003536:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003538:	03400613          	li	a2,52
    8000353c:	05b1                	addi	a1,a1,12
    8000353e:	05048513          	addi	a0,s1,80
    80003542:	8ddfd0ef          	jal	ra,80000e1e <memmove>
    brelse(bp);
    80003546:	854a                	mv	a0,s2
    80003548:	9c7ff0ef          	jal	ra,80002f0e <brelse>
    ip->valid = 1;
    8000354c:	4785                	li	a5,1
    8000354e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003550:	04449783          	lh	a5,68(s1)
    80003554:	f3d1                	bnez	a5,800034d8 <ilock+0x20>
      panic("ilock: no type");
    80003556:	00004517          	auipc	a0,0x4
    8000355a:	1ca50513          	addi	a0,a0,458 # 80007720 <syscalls+0x178>
    8000355e:	a2cfd0ef          	jal	ra,8000078a <panic>

0000000080003562 <iunlock>:
{
    80003562:	1101                	addi	sp,sp,-32
    80003564:	ec06                	sd	ra,24(sp)
    80003566:	e822                	sd	s0,16(sp)
    80003568:	e426                	sd	s1,8(sp)
    8000356a:	e04a                	sd	s2,0(sp)
    8000356c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000356e:	c505                	beqz	a0,80003596 <iunlock+0x34>
    80003570:	84aa                	mv	s1,a0
    80003572:	01050913          	addi	s2,a0,16
    80003576:	854a                	mv	a0,s2
    80003578:	41b000ef          	jal	ra,80004192 <holdingsleep>
    8000357c:	cd09                	beqz	a0,80003596 <iunlock+0x34>
    8000357e:	449c                	lw	a5,8(s1)
    80003580:	00f05b63          	blez	a5,80003596 <iunlock+0x34>
  releasesleep(&ip->lock);
    80003584:	854a                	mv	a0,s2
    80003586:	3d5000ef          	jal	ra,8000415a <releasesleep>
}
    8000358a:	60e2                	ld	ra,24(sp)
    8000358c:	6442                	ld	s0,16(sp)
    8000358e:	64a2                	ld	s1,8(sp)
    80003590:	6902                	ld	s2,0(sp)
    80003592:	6105                	addi	sp,sp,32
    80003594:	8082                	ret
    panic("iunlock");
    80003596:	00004517          	auipc	a0,0x4
    8000359a:	19a50513          	addi	a0,a0,410 # 80007730 <syscalls+0x188>
    8000359e:	9ecfd0ef          	jal	ra,8000078a <panic>

00000000800035a2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800035a2:	7179                	addi	sp,sp,-48
    800035a4:	f406                	sd	ra,40(sp)
    800035a6:	f022                	sd	s0,32(sp)
    800035a8:	ec26                	sd	s1,24(sp)
    800035aa:	e84a                	sd	s2,16(sp)
    800035ac:	e44e                	sd	s3,8(sp)
    800035ae:	e052                	sd	s4,0(sp)
    800035b0:	1800                	addi	s0,sp,48
    800035b2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800035b4:	05050493          	addi	s1,a0,80
    800035b8:	08050913          	addi	s2,a0,128
    800035bc:	a021                	j	800035c4 <itrunc+0x22>
    800035be:	0491                	addi	s1,s1,4
    800035c0:	01248b63          	beq	s1,s2,800035d6 <itrunc+0x34>
    if(ip->addrs[i]){
    800035c4:	408c                	lw	a1,0(s1)
    800035c6:	dde5                	beqz	a1,800035be <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800035c8:	0009a503          	lw	a0,0(s3)
    800035cc:	a35ff0ef          	jal	ra,80003000 <bfree>
      ip->addrs[i] = 0;
    800035d0:	0004a023          	sw	zero,0(s1)
    800035d4:	b7ed                	j	800035be <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800035d6:	0809a583          	lw	a1,128(s3)
    800035da:	ed91                	bnez	a1,800035f6 <itrunc+0x54>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800035dc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800035e0:	854e                	mv	a0,s3
    800035e2:	e25ff0ef          	jal	ra,80003406 <iupdate>
}
    800035e6:	70a2                	ld	ra,40(sp)
    800035e8:	7402                	ld	s0,32(sp)
    800035ea:	64e2                	ld	s1,24(sp)
    800035ec:	6942                	ld	s2,16(sp)
    800035ee:	69a2                	ld	s3,8(sp)
    800035f0:	6a02                	ld	s4,0(sp)
    800035f2:	6145                	addi	sp,sp,48
    800035f4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800035f6:	0009a503          	lw	a0,0(s3)
    800035fa:	80dff0ef          	jal	ra,80002e06 <bread>
    800035fe:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003600:	05850493          	addi	s1,a0,88
    80003604:	45850913          	addi	s2,a0,1112
    80003608:	a021                	j	80003610 <itrunc+0x6e>
    8000360a:	0491                	addi	s1,s1,4
    8000360c:	01248963          	beq	s1,s2,8000361e <itrunc+0x7c>
      if(a[j])
    80003610:	408c                	lw	a1,0(s1)
    80003612:	dde5                	beqz	a1,8000360a <itrunc+0x68>
        bfree(ip->dev, a[j]);
    80003614:	0009a503          	lw	a0,0(s3)
    80003618:	9e9ff0ef          	jal	ra,80003000 <bfree>
    8000361c:	b7fd                	j	8000360a <itrunc+0x68>
    brelse(bp);
    8000361e:	8552                	mv	a0,s4
    80003620:	8efff0ef          	jal	ra,80002f0e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003624:	0809a583          	lw	a1,128(s3)
    80003628:	0009a503          	lw	a0,0(s3)
    8000362c:	9d5ff0ef          	jal	ra,80003000 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003630:	0809a023          	sw	zero,128(s3)
    80003634:	b765                	j	800035dc <itrunc+0x3a>

0000000080003636 <iput>:
{
    80003636:	1101                	addi	sp,sp,-32
    80003638:	ec06                	sd	ra,24(sp)
    8000363a:	e822                	sd	s0,16(sp)
    8000363c:	e426                	sd	s1,8(sp)
    8000363e:	e04a                	sd	s2,0(sp)
    80003640:	1000                	addi	s0,sp,32
    80003642:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003644:	00023517          	auipc	a0,0x23
    80003648:	bd450513          	addi	a0,a0,-1068 # 80026218 <itable>
    8000364c:	ea2fd0ef          	jal	ra,80000cee <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003650:	4498                	lw	a4,8(s1)
    80003652:	4785                	li	a5,1
    80003654:	02f70163          	beq	a4,a5,80003676 <iput+0x40>
  ip->ref--;
    80003658:	449c                	lw	a5,8(s1)
    8000365a:	37fd                	addiw	a5,a5,-1
    8000365c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000365e:	00023517          	auipc	a0,0x23
    80003662:	bba50513          	addi	a0,a0,-1094 # 80026218 <itable>
    80003666:	f20fd0ef          	jal	ra,80000d86 <release>
}
    8000366a:	60e2                	ld	ra,24(sp)
    8000366c:	6442                	ld	s0,16(sp)
    8000366e:	64a2                	ld	s1,8(sp)
    80003670:	6902                	ld	s2,0(sp)
    80003672:	6105                	addi	sp,sp,32
    80003674:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003676:	40bc                	lw	a5,64(s1)
    80003678:	d3e5                	beqz	a5,80003658 <iput+0x22>
    8000367a:	04a49783          	lh	a5,74(s1)
    8000367e:	ffe9                	bnez	a5,80003658 <iput+0x22>
    acquiresleep(&ip->lock);
    80003680:	01048913          	addi	s2,s1,16
    80003684:	854a                	mv	a0,s2
    80003686:	28f000ef          	jal	ra,80004114 <acquiresleep>
    release(&itable.lock);
    8000368a:	00023517          	auipc	a0,0x23
    8000368e:	b8e50513          	addi	a0,a0,-1138 # 80026218 <itable>
    80003692:	ef4fd0ef          	jal	ra,80000d86 <release>
    itrunc(ip);
    80003696:	8526                	mv	a0,s1
    80003698:	f0bff0ef          	jal	ra,800035a2 <itrunc>
    ip->type = 0;
    8000369c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800036a0:	8526                	mv	a0,s1
    800036a2:	d65ff0ef          	jal	ra,80003406 <iupdate>
    ip->valid = 0;
    800036a6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800036aa:	854a                	mv	a0,s2
    800036ac:	2af000ef          	jal	ra,8000415a <releasesleep>
    acquire(&itable.lock);
    800036b0:	00023517          	auipc	a0,0x23
    800036b4:	b6850513          	addi	a0,a0,-1176 # 80026218 <itable>
    800036b8:	e36fd0ef          	jal	ra,80000cee <acquire>
    800036bc:	bf71                	j	80003658 <iput+0x22>

00000000800036be <iunlockput>:
{
    800036be:	1101                	addi	sp,sp,-32
    800036c0:	ec06                	sd	ra,24(sp)
    800036c2:	e822                	sd	s0,16(sp)
    800036c4:	e426                	sd	s1,8(sp)
    800036c6:	1000                	addi	s0,sp,32
    800036c8:	84aa                	mv	s1,a0
  iunlock(ip);
    800036ca:	e99ff0ef          	jal	ra,80003562 <iunlock>
  iput(ip);
    800036ce:	8526                	mv	a0,s1
    800036d0:	f67ff0ef          	jal	ra,80003636 <iput>
}
    800036d4:	60e2                	ld	ra,24(sp)
    800036d6:	6442                	ld	s0,16(sp)
    800036d8:	64a2                	ld	s1,8(sp)
    800036da:	6105                	addi	sp,sp,32
    800036dc:	8082                	ret

00000000800036de <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800036de:	00023717          	auipc	a4,0x23
    800036e2:	b2672703          	lw	a4,-1242(a4) # 80026204 <sb+0xc>
    800036e6:	4785                	li	a5,1
    800036e8:	0ae7ff63          	bgeu	a5,a4,800037a6 <ireclaim+0xc8>
{
    800036ec:	7139                	addi	sp,sp,-64
    800036ee:	fc06                	sd	ra,56(sp)
    800036f0:	f822                	sd	s0,48(sp)
    800036f2:	f426                	sd	s1,40(sp)
    800036f4:	f04a                	sd	s2,32(sp)
    800036f6:	ec4e                	sd	s3,24(sp)
    800036f8:	e852                	sd	s4,16(sp)
    800036fa:	e456                	sd	s5,8(sp)
    800036fc:	e05a                	sd	s6,0(sp)
    800036fe:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003700:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003702:	00050a1b          	sext.w	s4,a0
    80003706:	00023a97          	auipc	s5,0x23
    8000370a:	af2a8a93          	addi	s5,s5,-1294 # 800261f8 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    8000370e:	00004b17          	auipc	s6,0x4
    80003712:	02ab0b13          	addi	s6,s6,42 # 80007738 <syscalls+0x190>
    80003716:	a099                	j	8000375c <ireclaim+0x7e>
    80003718:	85ce                	mv	a1,s3
    8000371a:	855a                	mv	a0,s6
    8000371c:	da9fc0ef          	jal	ra,800004c4 <printf>
      ip = iget(dev, inum);
    80003720:	85ce                	mv	a1,s3
    80003722:	8552                	mv	a0,s4
    80003724:	b29ff0ef          	jal	ra,8000324c <iget>
    80003728:	89aa                	mv	s3,a0
    brelse(bp);
    8000372a:	854a                	mv	a0,s2
    8000372c:	fe2ff0ef          	jal	ra,80002f0e <brelse>
    if (ip) {
    80003730:	00098f63          	beqz	s3,8000374e <ireclaim+0x70>
      begin_op();
    80003734:	762000ef          	jal	ra,80003e96 <begin_op>
      ilock(ip);
    80003738:	854e                	mv	a0,s3
    8000373a:	d7fff0ef          	jal	ra,800034b8 <ilock>
      iunlock(ip);
    8000373e:	854e                	mv	a0,s3
    80003740:	e23ff0ef          	jal	ra,80003562 <iunlock>
      iput(ip);
    80003744:	854e                	mv	a0,s3
    80003746:	ef1ff0ef          	jal	ra,80003636 <iput>
      end_op();
    8000374a:	7bc000ef          	jal	ra,80003f06 <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    8000374e:	0485                	addi	s1,s1,1
    80003750:	00caa703          	lw	a4,12(s5)
    80003754:	0004879b          	sext.w	a5,s1
    80003758:	02e7fd63          	bgeu	a5,a4,80003792 <ireclaim+0xb4>
    8000375c:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003760:	0044d793          	srli	a5,s1,0x4
    80003764:	018aa583          	lw	a1,24(s5)
    80003768:	9dbd                	addw	a1,a1,a5
    8000376a:	8552                	mv	a0,s4
    8000376c:	e9aff0ef          	jal	ra,80002e06 <bread>
    80003770:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    80003772:	05850793          	addi	a5,a0,88
    80003776:	00f9f713          	andi	a4,s3,15
    8000377a:	071a                	slli	a4,a4,0x6
    8000377c:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    8000377e:	00079703          	lh	a4,0(a5)
    80003782:	c701                	beqz	a4,8000378a <ireclaim+0xac>
    80003784:	00679783          	lh	a5,6(a5)
    80003788:	dbc1                	beqz	a5,80003718 <ireclaim+0x3a>
    brelse(bp);
    8000378a:	854a                	mv	a0,s2
    8000378c:	f82ff0ef          	jal	ra,80002f0e <brelse>
    if (ip) {
    80003790:	bf7d                	j	8000374e <ireclaim+0x70>
}
    80003792:	70e2                	ld	ra,56(sp)
    80003794:	7442                	ld	s0,48(sp)
    80003796:	74a2                	ld	s1,40(sp)
    80003798:	7902                	ld	s2,32(sp)
    8000379a:	69e2                	ld	s3,24(sp)
    8000379c:	6a42                	ld	s4,16(sp)
    8000379e:	6aa2                	ld	s5,8(sp)
    800037a0:	6b02                	ld	s6,0(sp)
    800037a2:	6121                	addi	sp,sp,64
    800037a4:	8082                	ret
    800037a6:	8082                	ret

00000000800037a8 <fsinit>:
fsinit(int dev) {
    800037a8:	7179                	addi	sp,sp,-48
    800037aa:	f406                	sd	ra,40(sp)
    800037ac:	f022                	sd	s0,32(sp)
    800037ae:	ec26                	sd	s1,24(sp)
    800037b0:	e84a                	sd	s2,16(sp)
    800037b2:	e44e                	sd	s3,8(sp)
    800037b4:	1800                	addi	s0,sp,48
    800037b6:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    800037b8:	4585                	li	a1,1
    800037ba:	e4cff0ef          	jal	ra,80002e06 <bread>
    800037be:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037c0:	00023997          	auipc	s3,0x23
    800037c4:	a3898993          	addi	s3,s3,-1480 # 800261f8 <sb>
    800037c8:	02000613          	li	a2,32
    800037cc:	05850593          	addi	a1,a0,88
    800037d0:	854e                	mv	a0,s3
    800037d2:	e4cfd0ef          	jal	ra,80000e1e <memmove>
  brelse(bp);
    800037d6:	854a                	mv	a0,s2
    800037d8:	f36ff0ef          	jal	ra,80002f0e <brelse>
  if(sb.magic != FSMAGIC)
    800037dc:	0009a703          	lw	a4,0(s3)
    800037e0:	102037b7          	lui	a5,0x10203
    800037e4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037e8:	02f71363          	bne	a4,a5,8000380e <fsinit+0x66>
  initlog(dev, &sb);
    800037ec:	00023597          	auipc	a1,0x23
    800037f0:	a0c58593          	addi	a1,a1,-1524 # 800261f8 <sb>
    800037f4:	8526                	mv	a0,s1
    800037f6:	616000ef          	jal	ra,80003e0c <initlog>
  ireclaim(dev);
    800037fa:	8526                	mv	a0,s1
    800037fc:	ee3ff0ef          	jal	ra,800036de <ireclaim>
}
    80003800:	70a2                	ld	ra,40(sp)
    80003802:	7402                	ld	s0,32(sp)
    80003804:	64e2                	ld	s1,24(sp)
    80003806:	6942                	ld	s2,16(sp)
    80003808:	69a2                	ld	s3,8(sp)
    8000380a:	6145                	addi	sp,sp,48
    8000380c:	8082                	ret
    panic("invalid file system");
    8000380e:	00004517          	auipc	a0,0x4
    80003812:	f4a50513          	addi	a0,a0,-182 # 80007758 <syscalls+0x1b0>
    80003816:	f75fc0ef          	jal	ra,8000078a <panic>

000000008000381a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000381a:	1141                	addi	sp,sp,-16
    8000381c:	e422                	sd	s0,8(sp)
    8000381e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003820:	411c                	lw	a5,0(a0)
    80003822:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003824:	415c                	lw	a5,4(a0)
    80003826:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003828:	04451783          	lh	a5,68(a0)
    8000382c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003830:	04a51783          	lh	a5,74(a0)
    80003834:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003838:	04c56783          	lwu	a5,76(a0)
    8000383c:	e99c                	sd	a5,16(a1)
}
    8000383e:	6422                	ld	s0,8(sp)
    80003840:	0141                	addi	sp,sp,16
    80003842:	8082                	ret

0000000080003844 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003844:	457c                	lw	a5,76(a0)
    80003846:	0cd7ef63          	bltu	a5,a3,80003924 <readi+0xe0>
{
    8000384a:	7159                	addi	sp,sp,-112
    8000384c:	f486                	sd	ra,104(sp)
    8000384e:	f0a2                	sd	s0,96(sp)
    80003850:	eca6                	sd	s1,88(sp)
    80003852:	e8ca                	sd	s2,80(sp)
    80003854:	e4ce                	sd	s3,72(sp)
    80003856:	e0d2                	sd	s4,64(sp)
    80003858:	fc56                	sd	s5,56(sp)
    8000385a:	f85a                	sd	s6,48(sp)
    8000385c:	f45e                	sd	s7,40(sp)
    8000385e:	f062                	sd	s8,32(sp)
    80003860:	ec66                	sd	s9,24(sp)
    80003862:	e86a                	sd	s10,16(sp)
    80003864:	e46e                	sd	s11,8(sp)
    80003866:	1880                	addi	s0,sp,112
    80003868:	8b2a                	mv	s6,a0
    8000386a:	8bae                	mv	s7,a1
    8000386c:	8a32                	mv	s4,a2
    8000386e:	84b6                	mv	s1,a3
    80003870:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003872:	9f35                	addw	a4,a4,a3
    return 0;
    80003874:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003876:	08d76663          	bltu	a4,a3,80003902 <readi+0xbe>
  if(off + n > ip->size)
    8000387a:	00e7f463          	bgeu	a5,a4,80003882 <readi+0x3e>
    n = ip->size - off;
    8000387e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003882:	080a8f63          	beqz	s5,80003920 <readi+0xdc>
    80003886:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003888:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000388c:	5c7d                	li	s8,-1
    8000388e:	a80d                	j	800038c0 <readi+0x7c>
    80003890:	020d1d93          	slli	s11,s10,0x20
    80003894:	020ddd93          	srli	s11,s11,0x20
    80003898:	05890793          	addi	a5,s2,88
    8000389c:	86ee                	mv	a3,s11
    8000389e:	963e                	add	a2,a2,a5
    800038a0:	85d2                	mv	a1,s4
    800038a2:	855e                	mv	a0,s7
    800038a4:	acffe0ef          	jal	ra,80002372 <either_copyout>
    800038a8:	05850763          	beq	a0,s8,800038f6 <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800038ac:	854a                	mv	a0,s2
    800038ae:	e60ff0ef          	jal	ra,80002f0e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800038b2:	013d09bb          	addw	s3,s10,s3
    800038b6:	009d04bb          	addw	s1,s10,s1
    800038ba:	9a6e                	add	s4,s4,s11
    800038bc:	0559f163          	bgeu	s3,s5,800038fe <readi+0xba>
    uint addr = bmap(ip, off/BSIZE);
    800038c0:	00a4d59b          	srliw	a1,s1,0xa
    800038c4:	855a                	mv	a0,s6
    800038c6:	8bbff0ef          	jal	ra,80003180 <bmap>
    800038ca:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800038ce:	c985                	beqz	a1,800038fe <readi+0xba>
    bp = bread(ip->dev, addr);
    800038d0:	000b2503          	lw	a0,0(s6)
    800038d4:	d32ff0ef          	jal	ra,80002e06 <bread>
    800038d8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800038da:	3ff4f613          	andi	a2,s1,1023
    800038de:	40cc87bb          	subw	a5,s9,a2
    800038e2:	413a873b          	subw	a4,s5,s3
    800038e6:	8d3e                	mv	s10,a5
    800038e8:	2781                	sext.w	a5,a5
    800038ea:	0007069b          	sext.w	a3,a4
    800038ee:	faf6f1e3          	bgeu	a3,a5,80003890 <readi+0x4c>
    800038f2:	8d3a                	mv	s10,a4
    800038f4:	bf71                	j	80003890 <readi+0x4c>
      brelse(bp);
    800038f6:	854a                	mv	a0,s2
    800038f8:	e16ff0ef          	jal	ra,80002f0e <brelse>
      tot = -1;
    800038fc:	59fd                	li	s3,-1
  }
  return tot;
    800038fe:	0009851b          	sext.w	a0,s3
}
    80003902:	70a6                	ld	ra,104(sp)
    80003904:	7406                	ld	s0,96(sp)
    80003906:	64e6                	ld	s1,88(sp)
    80003908:	6946                	ld	s2,80(sp)
    8000390a:	69a6                	ld	s3,72(sp)
    8000390c:	6a06                	ld	s4,64(sp)
    8000390e:	7ae2                	ld	s5,56(sp)
    80003910:	7b42                	ld	s6,48(sp)
    80003912:	7ba2                	ld	s7,40(sp)
    80003914:	7c02                	ld	s8,32(sp)
    80003916:	6ce2                	ld	s9,24(sp)
    80003918:	6d42                	ld	s10,16(sp)
    8000391a:	6da2                	ld	s11,8(sp)
    8000391c:	6165                	addi	sp,sp,112
    8000391e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003920:	89d6                	mv	s3,s5
    80003922:	bff1                	j	800038fe <readi+0xba>
    return 0;
    80003924:	4501                	li	a0,0
}
    80003926:	8082                	ret

0000000080003928 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003928:	457c                	lw	a5,76(a0)
    8000392a:	0ed7ea63          	bltu	a5,a3,80003a1e <writei+0xf6>
{
    8000392e:	7159                	addi	sp,sp,-112
    80003930:	f486                	sd	ra,104(sp)
    80003932:	f0a2                	sd	s0,96(sp)
    80003934:	eca6                	sd	s1,88(sp)
    80003936:	e8ca                	sd	s2,80(sp)
    80003938:	e4ce                	sd	s3,72(sp)
    8000393a:	e0d2                	sd	s4,64(sp)
    8000393c:	fc56                	sd	s5,56(sp)
    8000393e:	f85a                	sd	s6,48(sp)
    80003940:	f45e                	sd	s7,40(sp)
    80003942:	f062                	sd	s8,32(sp)
    80003944:	ec66                	sd	s9,24(sp)
    80003946:	e86a                	sd	s10,16(sp)
    80003948:	e46e                	sd	s11,8(sp)
    8000394a:	1880                	addi	s0,sp,112
    8000394c:	8aaa                	mv	s5,a0
    8000394e:	8bae                	mv	s7,a1
    80003950:	8a32                	mv	s4,a2
    80003952:	8936                	mv	s2,a3
    80003954:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003956:	00e687bb          	addw	a5,a3,a4
    8000395a:	0cd7e463          	bltu	a5,a3,80003a22 <writei+0xfa>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000395e:	00043737          	lui	a4,0x43
    80003962:	0cf76263          	bltu	a4,a5,80003a26 <writei+0xfe>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003966:	0a0b0a63          	beqz	s6,80003a1a <writei+0xf2>
    8000396a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000396c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003970:	5c7d                	li	s8,-1
    80003972:	a825                	j	800039aa <writei+0x82>
    80003974:	020d1d93          	slli	s11,s10,0x20
    80003978:	020ddd93          	srli	s11,s11,0x20
    8000397c:	05848793          	addi	a5,s1,88
    80003980:	86ee                	mv	a3,s11
    80003982:	8652                	mv	a2,s4
    80003984:	85de                	mv	a1,s7
    80003986:	953e                	add	a0,a0,a5
    80003988:	a35fe0ef          	jal	ra,800023bc <either_copyin>
    8000398c:	05850a63          	beq	a0,s8,800039e0 <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003990:	8526                	mv	a0,s1
    80003992:	688000ef          	jal	ra,8000401a <log_write>
    brelse(bp);
    80003996:	8526                	mv	a0,s1
    80003998:	d76ff0ef          	jal	ra,80002f0e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000399c:	013d09bb          	addw	s3,s10,s3
    800039a0:	012d093b          	addw	s2,s10,s2
    800039a4:	9a6e                	add	s4,s4,s11
    800039a6:	0569f063          	bgeu	s3,s6,800039e6 <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    800039aa:	00a9559b          	srliw	a1,s2,0xa
    800039ae:	8556                	mv	a0,s5
    800039b0:	fd0ff0ef          	jal	ra,80003180 <bmap>
    800039b4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800039b8:	c59d                	beqz	a1,800039e6 <writei+0xbe>
    bp = bread(ip->dev, addr);
    800039ba:	000aa503          	lw	a0,0(s5)
    800039be:	c48ff0ef          	jal	ra,80002e06 <bread>
    800039c2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039c4:	3ff97513          	andi	a0,s2,1023
    800039c8:	40ac87bb          	subw	a5,s9,a0
    800039cc:	413b073b          	subw	a4,s6,s3
    800039d0:	8d3e                	mv	s10,a5
    800039d2:	2781                	sext.w	a5,a5
    800039d4:	0007069b          	sext.w	a3,a4
    800039d8:	f8f6fee3          	bgeu	a3,a5,80003974 <writei+0x4c>
    800039dc:	8d3a                	mv	s10,a4
    800039de:	bf59                	j	80003974 <writei+0x4c>
      brelse(bp);
    800039e0:	8526                	mv	a0,s1
    800039e2:	d2cff0ef          	jal	ra,80002f0e <brelse>
  }

  if(off > ip->size)
    800039e6:	04caa783          	lw	a5,76(s5)
    800039ea:	0127f463          	bgeu	a5,s2,800039f2 <writei+0xca>
    ip->size = off;
    800039ee:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800039f2:	8556                	mv	a0,s5
    800039f4:	a13ff0ef          	jal	ra,80003406 <iupdate>

  return tot;
    800039f8:	0009851b          	sext.w	a0,s3
}
    800039fc:	70a6                	ld	ra,104(sp)
    800039fe:	7406                	ld	s0,96(sp)
    80003a00:	64e6                	ld	s1,88(sp)
    80003a02:	6946                	ld	s2,80(sp)
    80003a04:	69a6                	ld	s3,72(sp)
    80003a06:	6a06                	ld	s4,64(sp)
    80003a08:	7ae2                	ld	s5,56(sp)
    80003a0a:	7b42                	ld	s6,48(sp)
    80003a0c:	7ba2                	ld	s7,40(sp)
    80003a0e:	7c02                	ld	s8,32(sp)
    80003a10:	6ce2                	ld	s9,24(sp)
    80003a12:	6d42                	ld	s10,16(sp)
    80003a14:	6da2                	ld	s11,8(sp)
    80003a16:	6165                	addi	sp,sp,112
    80003a18:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a1a:	89da                	mv	s3,s6
    80003a1c:	bfd9                	j	800039f2 <writei+0xca>
    return -1;
    80003a1e:	557d                	li	a0,-1
}
    80003a20:	8082                	ret
    return -1;
    80003a22:	557d                	li	a0,-1
    80003a24:	bfe1                	j	800039fc <writei+0xd4>
    return -1;
    80003a26:	557d                	li	a0,-1
    80003a28:	bfd1                	j	800039fc <writei+0xd4>

0000000080003a2a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003a2a:	1141                	addi	sp,sp,-16
    80003a2c:	e406                	sd	ra,8(sp)
    80003a2e:	e022                	sd	s0,0(sp)
    80003a30:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003a32:	4639                	li	a2,14
    80003a34:	c5afd0ef          	jal	ra,80000e8e <strncmp>
}
    80003a38:	60a2                	ld	ra,8(sp)
    80003a3a:	6402                	ld	s0,0(sp)
    80003a3c:	0141                	addi	sp,sp,16
    80003a3e:	8082                	ret

0000000080003a40 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003a40:	7139                	addi	sp,sp,-64
    80003a42:	fc06                	sd	ra,56(sp)
    80003a44:	f822                	sd	s0,48(sp)
    80003a46:	f426                	sd	s1,40(sp)
    80003a48:	f04a                	sd	s2,32(sp)
    80003a4a:	ec4e                	sd	s3,24(sp)
    80003a4c:	e852                	sd	s4,16(sp)
    80003a4e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003a50:	04451703          	lh	a4,68(a0)
    80003a54:	4785                	li	a5,1
    80003a56:	00f71a63          	bne	a4,a5,80003a6a <dirlookup+0x2a>
    80003a5a:	892a                	mv	s2,a0
    80003a5c:	89ae                	mv	s3,a1
    80003a5e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003a60:	457c                	lw	a5,76(a0)
    80003a62:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003a64:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003a66:	e39d                	bnez	a5,80003a8c <dirlookup+0x4c>
    80003a68:	a095                	j	80003acc <dirlookup+0x8c>
    panic("dirlookup not DIR");
    80003a6a:	00004517          	auipc	a0,0x4
    80003a6e:	d0650513          	addi	a0,a0,-762 # 80007770 <syscalls+0x1c8>
    80003a72:	d19fc0ef          	jal	ra,8000078a <panic>
      panic("dirlookup read");
    80003a76:	00004517          	auipc	a0,0x4
    80003a7a:	d1250513          	addi	a0,a0,-750 # 80007788 <syscalls+0x1e0>
    80003a7e:	d0dfc0ef          	jal	ra,8000078a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003a82:	24c1                	addiw	s1,s1,16
    80003a84:	04c92783          	lw	a5,76(s2)
    80003a88:	04f4f163          	bgeu	s1,a5,80003aca <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003a8c:	4741                	li	a4,16
    80003a8e:	86a6                	mv	a3,s1
    80003a90:	fc040613          	addi	a2,s0,-64
    80003a94:	4581                	li	a1,0
    80003a96:	854a                	mv	a0,s2
    80003a98:	dadff0ef          	jal	ra,80003844 <readi>
    80003a9c:	47c1                	li	a5,16
    80003a9e:	fcf51ce3          	bne	a0,a5,80003a76 <dirlookup+0x36>
    if(de.inum == 0)
    80003aa2:	fc045783          	lhu	a5,-64(s0)
    80003aa6:	dff1                	beqz	a5,80003a82 <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    80003aa8:	fc240593          	addi	a1,s0,-62
    80003aac:	854e                	mv	a0,s3
    80003aae:	f7dff0ef          	jal	ra,80003a2a <namecmp>
    80003ab2:	f961                	bnez	a0,80003a82 <dirlookup+0x42>
      if(poff)
    80003ab4:	000a0463          	beqz	s4,80003abc <dirlookup+0x7c>
        *poff = off;
    80003ab8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003abc:	fc045583          	lhu	a1,-64(s0)
    80003ac0:	00092503          	lw	a0,0(s2)
    80003ac4:	f88ff0ef          	jal	ra,8000324c <iget>
    80003ac8:	a011                	j	80003acc <dirlookup+0x8c>
  return 0;
    80003aca:	4501                	li	a0,0
}
    80003acc:	70e2                	ld	ra,56(sp)
    80003ace:	7442                	ld	s0,48(sp)
    80003ad0:	74a2                	ld	s1,40(sp)
    80003ad2:	7902                	ld	s2,32(sp)
    80003ad4:	69e2                	ld	s3,24(sp)
    80003ad6:	6a42                	ld	s4,16(sp)
    80003ad8:	6121                	addi	sp,sp,64
    80003ada:	8082                	ret

0000000080003adc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003adc:	711d                	addi	sp,sp,-96
    80003ade:	ec86                	sd	ra,88(sp)
    80003ae0:	e8a2                	sd	s0,80(sp)
    80003ae2:	e4a6                	sd	s1,72(sp)
    80003ae4:	e0ca                	sd	s2,64(sp)
    80003ae6:	fc4e                	sd	s3,56(sp)
    80003ae8:	f852                	sd	s4,48(sp)
    80003aea:	f456                	sd	s5,40(sp)
    80003aec:	f05a                	sd	s6,32(sp)
    80003aee:	ec5e                	sd	s7,24(sp)
    80003af0:	e862                	sd	s8,16(sp)
    80003af2:	e466                	sd	s9,8(sp)
    80003af4:	1080                	addi	s0,sp,96
    80003af6:	84aa                	mv	s1,a0
    80003af8:	8aae                	mv	s5,a1
    80003afa:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003afc:	00054703          	lbu	a4,0(a0)
    80003b00:	02f00793          	li	a5,47
    80003b04:	00f70f63          	beq	a4,a5,80003b22 <namex+0x46>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003b08:	efdfd0ef          	jal	ra,80001a04 <myproc>
    80003b0c:	15053503          	ld	a0,336(a0)
    80003b10:	973ff0ef          	jal	ra,80003482 <idup>
    80003b14:	89aa                	mv	s3,a0
  while(*path == '/')
    80003b16:	02f00913          	li	s2,47
  len = path - s;
    80003b1a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003b1c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003b1e:	4b85                	li	s7,1
    80003b20:	a861                	j	80003bb8 <namex+0xdc>
    ip = iget(ROOTDEV, ROOTINO);
    80003b22:	4585                	li	a1,1
    80003b24:	4505                	li	a0,1
    80003b26:	f26ff0ef          	jal	ra,8000324c <iget>
    80003b2a:	89aa                	mv	s3,a0
    80003b2c:	b7ed                	j	80003b16 <namex+0x3a>
      iunlockput(ip);
    80003b2e:	854e                	mv	a0,s3
    80003b30:	b8fff0ef          	jal	ra,800036be <iunlockput>
      return 0;
    80003b34:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003b36:	854e                	mv	a0,s3
    80003b38:	60e6                	ld	ra,88(sp)
    80003b3a:	6446                	ld	s0,80(sp)
    80003b3c:	64a6                	ld	s1,72(sp)
    80003b3e:	6906                	ld	s2,64(sp)
    80003b40:	79e2                	ld	s3,56(sp)
    80003b42:	7a42                	ld	s4,48(sp)
    80003b44:	7aa2                	ld	s5,40(sp)
    80003b46:	7b02                	ld	s6,32(sp)
    80003b48:	6be2                	ld	s7,24(sp)
    80003b4a:	6c42                	ld	s8,16(sp)
    80003b4c:	6ca2                	ld	s9,8(sp)
    80003b4e:	6125                	addi	sp,sp,96
    80003b50:	8082                	ret
      iunlock(ip);
    80003b52:	854e                	mv	a0,s3
    80003b54:	a0fff0ef          	jal	ra,80003562 <iunlock>
      return ip;
    80003b58:	bff9                	j	80003b36 <namex+0x5a>
      iunlockput(ip);
    80003b5a:	854e                	mv	a0,s3
    80003b5c:	b63ff0ef          	jal	ra,800036be <iunlockput>
      return 0;
    80003b60:	89e6                	mv	s3,s9
    80003b62:	bfd1                	j	80003b36 <namex+0x5a>
  len = path - s;
    80003b64:	40b48633          	sub	a2,s1,a1
    80003b68:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003b6c:	079c5c63          	bge	s8,s9,80003be4 <namex+0x108>
    memmove(name, s, DIRSIZ);
    80003b70:	4639                	li	a2,14
    80003b72:	8552                	mv	a0,s4
    80003b74:	aaafd0ef          	jal	ra,80000e1e <memmove>
  while(*path == '/')
    80003b78:	0004c783          	lbu	a5,0(s1)
    80003b7c:	01279763          	bne	a5,s2,80003b8a <namex+0xae>
    path++;
    80003b80:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003b82:	0004c783          	lbu	a5,0(s1)
    80003b86:	ff278de3          	beq	a5,s2,80003b80 <namex+0xa4>
    ilock(ip);
    80003b8a:	854e                	mv	a0,s3
    80003b8c:	92dff0ef          	jal	ra,800034b8 <ilock>
    if(ip->type != T_DIR){
    80003b90:	04499783          	lh	a5,68(s3)
    80003b94:	f9779de3          	bne	a5,s7,80003b2e <namex+0x52>
    if(nameiparent && *path == '\0'){
    80003b98:	000a8563          	beqz	s5,80003ba2 <namex+0xc6>
    80003b9c:	0004c783          	lbu	a5,0(s1)
    80003ba0:	dbcd                	beqz	a5,80003b52 <namex+0x76>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ba2:	865a                	mv	a2,s6
    80003ba4:	85d2                	mv	a1,s4
    80003ba6:	854e                	mv	a0,s3
    80003ba8:	e99ff0ef          	jal	ra,80003a40 <dirlookup>
    80003bac:	8caa                	mv	s9,a0
    80003bae:	d555                	beqz	a0,80003b5a <namex+0x7e>
    iunlockput(ip);
    80003bb0:	854e                	mv	a0,s3
    80003bb2:	b0dff0ef          	jal	ra,800036be <iunlockput>
    ip = next;
    80003bb6:	89e6                	mv	s3,s9
  while(*path == '/')
    80003bb8:	0004c783          	lbu	a5,0(s1)
    80003bbc:	05279363          	bne	a5,s2,80003c02 <namex+0x126>
    path++;
    80003bc0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003bc2:	0004c783          	lbu	a5,0(s1)
    80003bc6:	ff278de3          	beq	a5,s2,80003bc0 <namex+0xe4>
  if(*path == 0)
    80003bca:	c78d                	beqz	a5,80003bf4 <namex+0x118>
    path++;
    80003bcc:	85a6                	mv	a1,s1
  len = path - s;
    80003bce:	8cda                	mv	s9,s6
    80003bd0:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003bd2:	01278963          	beq	a5,s2,80003be4 <namex+0x108>
    80003bd6:	d7d9                	beqz	a5,80003b64 <namex+0x88>
    path++;
    80003bd8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003bda:	0004c783          	lbu	a5,0(s1)
    80003bde:	ff279ce3          	bne	a5,s2,80003bd6 <namex+0xfa>
    80003be2:	b749                	j	80003b64 <namex+0x88>
    memmove(name, s, len);
    80003be4:	2601                	sext.w	a2,a2
    80003be6:	8552                	mv	a0,s4
    80003be8:	a36fd0ef          	jal	ra,80000e1e <memmove>
    name[len] = 0;
    80003bec:	9cd2                	add	s9,s9,s4
    80003bee:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003bf2:	b759                	j	80003b78 <namex+0x9c>
  if(nameiparent){
    80003bf4:	f40a81e3          	beqz	s5,80003b36 <namex+0x5a>
    iput(ip);
    80003bf8:	854e                	mv	a0,s3
    80003bfa:	a3dff0ef          	jal	ra,80003636 <iput>
    return 0;
    80003bfe:	4981                	li	s3,0
    80003c00:	bf1d                	j	80003b36 <namex+0x5a>
  if(*path == 0)
    80003c02:	dbed                	beqz	a5,80003bf4 <namex+0x118>
  while(*path != '/' && *path != 0)
    80003c04:	0004c783          	lbu	a5,0(s1)
    80003c08:	85a6                	mv	a1,s1
    80003c0a:	b7f1                	j	80003bd6 <namex+0xfa>

0000000080003c0c <dirlink>:
{
    80003c0c:	7139                	addi	sp,sp,-64
    80003c0e:	fc06                	sd	ra,56(sp)
    80003c10:	f822                	sd	s0,48(sp)
    80003c12:	f426                	sd	s1,40(sp)
    80003c14:	f04a                	sd	s2,32(sp)
    80003c16:	ec4e                	sd	s3,24(sp)
    80003c18:	e852                	sd	s4,16(sp)
    80003c1a:	0080                	addi	s0,sp,64
    80003c1c:	892a                	mv	s2,a0
    80003c1e:	8a2e                	mv	s4,a1
    80003c20:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003c22:	4601                	li	a2,0
    80003c24:	e1dff0ef          	jal	ra,80003a40 <dirlookup>
    80003c28:	e52d                	bnez	a0,80003c92 <dirlink+0x86>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c2a:	04c92483          	lw	s1,76(s2)
    80003c2e:	c48d                	beqz	s1,80003c58 <dirlink+0x4c>
    80003c30:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c32:	4741                	li	a4,16
    80003c34:	86a6                	mv	a3,s1
    80003c36:	fc040613          	addi	a2,s0,-64
    80003c3a:	4581                	li	a1,0
    80003c3c:	854a                	mv	a0,s2
    80003c3e:	c07ff0ef          	jal	ra,80003844 <readi>
    80003c42:	47c1                	li	a5,16
    80003c44:	04f51b63          	bne	a0,a5,80003c9a <dirlink+0x8e>
    if(de.inum == 0)
    80003c48:	fc045783          	lhu	a5,-64(s0)
    80003c4c:	c791                	beqz	a5,80003c58 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c4e:	24c1                	addiw	s1,s1,16
    80003c50:	04c92783          	lw	a5,76(s2)
    80003c54:	fcf4efe3          	bltu	s1,a5,80003c32 <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80003c58:	4639                	li	a2,14
    80003c5a:	85d2                	mv	a1,s4
    80003c5c:	fc240513          	addi	a0,s0,-62
    80003c60:	a6afd0ef          	jal	ra,80000eca <strncpy>
  de.inum = inum;
    80003c64:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c68:	4741                	li	a4,16
    80003c6a:	86a6                	mv	a3,s1
    80003c6c:	fc040613          	addi	a2,s0,-64
    80003c70:	4581                	li	a1,0
    80003c72:	854a                	mv	a0,s2
    80003c74:	cb5ff0ef          	jal	ra,80003928 <writei>
    80003c78:	1541                	addi	a0,a0,-16
    80003c7a:	00a03533          	snez	a0,a0
    80003c7e:	40a00533          	neg	a0,a0
}
    80003c82:	70e2                	ld	ra,56(sp)
    80003c84:	7442                	ld	s0,48(sp)
    80003c86:	74a2                	ld	s1,40(sp)
    80003c88:	7902                	ld	s2,32(sp)
    80003c8a:	69e2                	ld	s3,24(sp)
    80003c8c:	6a42                	ld	s4,16(sp)
    80003c8e:	6121                	addi	sp,sp,64
    80003c90:	8082                	ret
    iput(ip);
    80003c92:	9a5ff0ef          	jal	ra,80003636 <iput>
    return -1;
    80003c96:	557d                	li	a0,-1
    80003c98:	b7ed                	j	80003c82 <dirlink+0x76>
      panic("dirlink read");
    80003c9a:	00004517          	auipc	a0,0x4
    80003c9e:	afe50513          	addi	a0,a0,-1282 # 80007798 <syscalls+0x1f0>
    80003ca2:	ae9fc0ef          	jal	ra,8000078a <panic>

0000000080003ca6 <namei>:

struct inode*
namei(char *path)
{
    80003ca6:	1101                	addi	sp,sp,-32
    80003ca8:	ec06                	sd	ra,24(sp)
    80003caa:	e822                	sd	s0,16(sp)
    80003cac:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003cae:	fe040613          	addi	a2,s0,-32
    80003cb2:	4581                	li	a1,0
    80003cb4:	e29ff0ef          	jal	ra,80003adc <namex>
}
    80003cb8:	60e2                	ld	ra,24(sp)
    80003cba:	6442                	ld	s0,16(sp)
    80003cbc:	6105                	addi	sp,sp,32
    80003cbe:	8082                	ret

0000000080003cc0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003cc0:	1141                	addi	sp,sp,-16
    80003cc2:	e406                	sd	ra,8(sp)
    80003cc4:	e022                	sd	s0,0(sp)
    80003cc6:	0800                	addi	s0,sp,16
    80003cc8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003cca:	4585                	li	a1,1
    80003ccc:	e11ff0ef          	jal	ra,80003adc <namex>
}
    80003cd0:	60a2                	ld	ra,8(sp)
    80003cd2:	6402                	ld	s0,0(sp)
    80003cd4:	0141                	addi	sp,sp,16
    80003cd6:	8082                	ret

0000000080003cd8 <write_head>:
  brelse(buf);  // 释放缓冲区
}

// 将内存中的日志头写回磁盘
static void write_head(void)
{
    80003cd8:	1101                	addi	sp,sp,-32
    80003cda:	ec06                	sd	ra,24(sp)
    80003cdc:	e822                	sd	s0,16(sp)
    80003cde:	e426                	sd	s1,8(sp)
    80003ce0:	e04a                	sd	s2,0(sp)
    80003ce2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ce4:	00024917          	auipc	s2,0x24
    80003ce8:	fdc90913          	addi	s2,s2,-36 # 80027cc0 <log>
    80003cec:	01892583          	lw	a1,24(s2)
    80003cf0:	02492503          	lw	a0,36(s2)
    80003cf4:	912ff0ef          	jal	ra,80002e06 <bread>
    80003cf8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;  // 更新日志中的块数量
    80003cfa:	02892683          	lw	a3,40(s2)
    80003cfe:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003d00:	02d05763          	blez	a3,80003d2e <write_head+0x56>
    80003d04:	00024797          	auipc	a5,0x24
    80003d08:	fe878793          	addi	a5,a5,-24 # 80027cec <log+0x2c>
    80003d0c:	05c50713          	addi	a4,a0,92
    80003d10:	36fd                	addiw	a3,a3,-1
    80003d12:	1682                	slli	a3,a3,0x20
    80003d14:	9281                	srli	a3,a3,0x20
    80003d16:	068a                	slli	a3,a3,0x2
    80003d18:	00024617          	auipc	a2,0x24
    80003d1c:	fd860613          	addi	a2,a2,-40 # 80027cf0 <log+0x30>
    80003d20:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];  // 更新每个日志块的块号
    80003d22:	4390                	lw	a2,0(a5)
    80003d24:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003d26:	0791                	addi	a5,a5,4
    80003d28:	0711                	addi	a4,a4,4
    80003d2a:	fed79ce3          	bne	a5,a3,80003d22 <write_head+0x4a>
  }
  bwrite(buf);  // 写回日志头块
    80003d2e:	8526                	mv	a0,s1
    80003d30:	9acff0ef          	jal	ra,80002edc <bwrite>
  brelse(buf);  // 释放缓冲区
    80003d34:	8526                	mv	a0,s1
    80003d36:	9d8ff0ef          	jal	ra,80002f0e <brelse>
}
    80003d3a:	60e2                	ld	ra,24(sp)
    80003d3c:	6442                	ld	s0,16(sp)
    80003d3e:	64a2                	ld	s1,8(sp)
    80003d40:	6902                	ld	s2,0(sp)
    80003d42:	6105                	addi	sp,sp,32
    80003d44:	8082                	ret

0000000080003d46 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003d46:	00024797          	auipc	a5,0x24
    80003d4a:	fa27a783          	lw	a5,-94(a5) # 80027ce8 <log+0x28>
    80003d4e:	0af05e63          	blez	a5,80003e0a <install_trans+0xc4>
{
    80003d52:	715d                	addi	sp,sp,-80
    80003d54:	e486                	sd	ra,72(sp)
    80003d56:	e0a2                	sd	s0,64(sp)
    80003d58:	fc26                	sd	s1,56(sp)
    80003d5a:	f84a                	sd	s2,48(sp)
    80003d5c:	f44e                	sd	s3,40(sp)
    80003d5e:	f052                	sd	s4,32(sp)
    80003d60:	ec56                	sd	s5,24(sp)
    80003d62:	e85a                	sd	s6,16(sp)
    80003d64:	e45e                	sd	s7,8(sp)
    80003d66:	0880                	addi	s0,sp,80
    80003d68:	8b2a                	mv	s6,a0
    80003d6a:	00024a97          	auipc	s5,0x24
    80003d6e:	f82a8a93          	addi	s5,s5,-126 # 80027cec <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003d72:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003d74:	00004b97          	auipc	s7,0x4
    80003d78:	a34b8b93          	addi	s7,s7,-1484 # 800077a8 <syscalls+0x200>
    struct buf *lbuf = bread(log.dev, log.start + tail + 1);  // 读取日志块
    80003d7c:	00024a17          	auipc	s4,0x24
    80003d80:	f44a0a13          	addi	s4,s4,-188 # 80027cc0 <log>
    80003d84:	a025                	j	80003dac <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003d86:	000aa603          	lw	a2,0(s5)
    80003d8a:	85ce                	mv	a1,s3
    80003d8c:	855e                	mv	a0,s7
    80003d8e:	f36fc0ef          	jal	ra,800004c4 <printf>
    80003d92:	a839                	j	80003db0 <install_trans+0x6a>
    brelse(lbuf);  // 释放日志块
    80003d94:	854a                	mv	a0,s2
    80003d96:	978ff0ef          	jal	ra,80002f0e <brelse>
    brelse(dbuf);  // 释放目标块
    80003d9a:	8526                	mv	a0,s1
    80003d9c:	972ff0ef          	jal	ra,80002f0e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003da0:	2985                	addiw	s3,s3,1
    80003da2:	0a91                	addi	s5,s5,4
    80003da4:	028a2783          	lw	a5,40(s4)
    80003da8:	04f9d663          	bge	s3,a5,80003df4 <install_trans+0xae>
    if(recovering) {
    80003dac:	fc0b1de3          	bnez	s6,80003d86 <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start + tail + 1);  // 读取日志块
    80003db0:	018a2583          	lw	a1,24(s4)
    80003db4:	013585bb          	addw	a1,a1,s3
    80003db8:	2585                	addiw	a1,a1,1
    80003dba:	024a2503          	lw	a0,36(s4)
    80003dbe:	848ff0ef          	jal	ra,80002e06 <bread>
    80003dc2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]);  // 读取目标块
    80003dc4:	000aa583          	lw	a1,0(s5)
    80003dc8:	024a2503          	lw	a0,36(s4)
    80003dcc:	83aff0ef          	jal	ra,80002e06 <bread>
    80003dd0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);
    80003dd2:	40000613          	li	a2,1024
    80003dd6:	05890593          	addi	a1,s2,88
    80003dda:	05850513          	addi	a0,a0,88
    80003dde:	840fd0ef          	jal	ra,80000e1e <memmove>
    bwrite(dbuf);  // 将目标块写回磁盘
    80003de2:	8526                	mv	a0,s1
    80003de4:	8f8ff0ef          	jal	ra,80002edc <bwrite>
    if(recovering == 0)
    80003de8:	fa0b16e3          	bnez	s6,80003d94 <install_trans+0x4e>
      bunpin(dbuf);  // 提交后解锁目标块
    80003dec:	8526                	mv	a0,s1
    80003dee:	9deff0ef          	jal	ra,80002fcc <bunpin>
    80003df2:	b74d                	j	80003d94 <install_trans+0x4e>
}
    80003df4:	60a6                	ld	ra,72(sp)
    80003df6:	6406                	ld	s0,64(sp)
    80003df8:	74e2                	ld	s1,56(sp)
    80003dfa:	7942                	ld	s2,48(sp)
    80003dfc:	79a2                	ld	s3,40(sp)
    80003dfe:	7a02                	ld	s4,32(sp)
    80003e00:	6ae2                	ld	s5,24(sp)
    80003e02:	6b42                	ld	s6,16(sp)
    80003e04:	6ba2                	ld	s7,8(sp)
    80003e06:	6161                	addi	sp,sp,80
    80003e08:	8082                	ret
    80003e0a:	8082                	ret

0000000080003e0c <initlog>:
{
    80003e0c:	7179                	addi	sp,sp,-48
    80003e0e:	f406                	sd	ra,40(sp)
    80003e10:	f022                	sd	s0,32(sp)
    80003e12:	ec26                	sd	s1,24(sp)
    80003e14:	e84a                	sd	s2,16(sp)
    80003e16:	e44e                	sd	s3,8(sp)
    80003e18:	1800                	addi	s0,sp,48
    80003e1a:	892a                	mv	s2,a0
    80003e1c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003e1e:	00024497          	auipc	s1,0x24
    80003e22:	ea248493          	addi	s1,s1,-350 # 80027cc0 <log>
    80003e26:	00004597          	auipc	a1,0x4
    80003e2a:	9a258593          	addi	a1,a1,-1630 # 800077c8 <syscalls+0x220>
    80003e2e:	8526                	mv	a0,s1
    80003e30:	e3ffc0ef          	jal	ra,80000c6e <initlock>
  log.start = sb->logstart;  // 设置日志起始位置
    80003e34:	0149a583          	lw	a1,20(s3)
    80003e38:	cc8c                	sw	a1,24(s1)
  log.dev = dev;  // 设置日志设备
    80003e3a:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003e3e:	854a                	mv	a0,s2
    80003e40:	fc7fe0ef          	jal	ra,80002e06 <bread>
  log.lh.n = lh->n;  // 读取日志中的块数量
    80003e44:	4d34                	lw	a3,88(a0)
    80003e46:	d494                	sw	a3,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003e48:	02d05563          	blez	a3,80003e72 <initlog+0x66>
    80003e4c:	05c50793          	addi	a5,a0,92
    80003e50:	00024717          	auipc	a4,0x24
    80003e54:	e9c70713          	addi	a4,a4,-356 # 80027cec <log+0x2c>
    80003e58:	36fd                	addiw	a3,a3,-1
    80003e5a:	1682                	slli	a3,a3,0x20
    80003e5c:	9281                	srli	a3,a3,0x20
    80003e5e:	068a                	slli	a3,a3,0x2
    80003e60:	06050613          	addi	a2,a0,96
    80003e64:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];  // 读取每个日志块的块号
    80003e66:	4390                	lw	a2,0(a5)
    80003e68:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e6a:	0791                	addi	a5,a5,4
    80003e6c:	0711                	addi	a4,a4,4
    80003e6e:	fed79ce3          	bne	a5,a3,80003e66 <initlog+0x5a>
  brelse(buf);  // 释放缓冲区
    80003e72:	89cff0ef          	jal	ra,80002f0e <brelse>

// 从日志中恢复
static void recover_from_log(void)
{
  read_head();  // 读取日志头
  install_trans(1);  // 如果已提交，从日志复制到磁盘
    80003e76:	4505                	li	a0,1
    80003e78:	ecfff0ef          	jal	ra,80003d46 <install_trans>
  log.lh.n = 0;  // 清空日志中的块数量
    80003e7c:	00024797          	auipc	a5,0x24
    80003e80:	e607a623          	sw	zero,-404(a5) # 80027ce8 <log+0x28>
  write_head();  // 清空日志
    80003e84:	e55ff0ef          	jal	ra,80003cd8 <write_head>
}
    80003e88:	70a2                	ld	ra,40(sp)
    80003e8a:	7402                	ld	s0,32(sp)
    80003e8c:	64e2                	ld	s1,24(sp)
    80003e8e:	6942                	ld	s2,16(sp)
    80003e90:	69a2                	ld	s3,8(sp)
    80003e92:	6145                	addi	sp,sp,48
    80003e94:	8082                	ret

0000000080003e96 <begin_op>:
}

// 文件系统调用开始时调用
void begin_op(void)
{
    80003e96:	1101                	addi	sp,sp,-32
    80003e98:	ec06                	sd	ra,24(sp)
    80003e9a:	e822                	sd	s0,16(sp)
    80003e9c:	e426                	sd	s1,8(sp)
    80003e9e:	e04a                	sd	s2,0(sp)
    80003ea0:	1000                	addi	s0,sp,32
  acquire(&log.lock);  // 获取日志锁
    80003ea2:	00024517          	auipc	a0,0x24
    80003ea6:	e1e50513          	addi	a0,a0,-482 # 80027cc0 <log>
    80003eaa:	e45fc0ef          	jal	ra,80000cee <acquire>
  while(1){
    if(log.committing){
    80003eae:	00024497          	auipc	s1,0x24
    80003eb2:	e1248493          	addi	s1,s1,-494 # 80027cc0 <log>
      // 如果日志正在提交，进入睡眠
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGBLOCKS){
    80003eb6:	4979                	li	s2,30
    80003eb8:	a029                	j	80003ec2 <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003eba:	85a6                	mv	a1,s1
    80003ebc:	8526                	mv	a0,s1
    80003ebe:	958fe0ef          	jal	ra,80002016 <sleep>
    if(log.committing){
    80003ec2:	509c                	lw	a5,32(s1)
    80003ec4:	fbfd                	bnez	a5,80003eba <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGBLOCKS){
    80003ec6:	4cdc                	lw	a5,28(s1)
    80003ec8:	0017871b          	addiw	a4,a5,1
    80003ecc:	0007069b          	sext.w	a3,a4
    80003ed0:	0027179b          	slliw	a5,a4,0x2
    80003ed4:	9fb9                	addw	a5,a5,a4
    80003ed6:	0017979b          	slliw	a5,a5,0x1
    80003eda:	5498                	lw	a4,40(s1)
    80003edc:	9fb9                	addw	a5,a5,a4
    80003ede:	00f95763          	bge	s2,a5,80003eec <begin_op+0x56>
      // 如果当前操作可能耗尽日志空间，等待提交
      sleep(&log, &log.lock);
    80003ee2:	85a6                	mv	a1,s1
    80003ee4:	8526                	mv	a0,s1
    80003ee6:	930fe0ef          	jal	ra,80002016 <sleep>
    80003eea:	bfe1                	j	80003ec2 <begin_op+0x2c>
    } else {
      log.outstanding += 1;  // 增加正在进行的操作计数
    80003eec:	00024517          	auipc	a0,0x24
    80003ef0:	dd450513          	addi	a0,a0,-556 # 80027cc0 <log>
    80003ef4:	cd54                	sw	a3,28(a0)
      release(&log.lock);  // 释放日志锁
    80003ef6:	e91fc0ef          	jal	ra,80000d86 <release>
      break;
    }
  }
}
    80003efa:	60e2                	ld	ra,24(sp)
    80003efc:	6442                	ld	s0,16(sp)
    80003efe:	64a2                	ld	s1,8(sp)
    80003f00:	6902                	ld	s2,0(sp)
    80003f02:	6105                	addi	sp,sp,32
    80003f04:	8082                	ret

0000000080003f06 <end_op>:

// 文件系统调用结束时调用
// 如果这是最后一个待处理的操作，则提交日志
void end_op(void)
{
    80003f06:	7139                	addi	sp,sp,-64
    80003f08:	fc06                	sd	ra,56(sp)
    80003f0a:	f822                	sd	s0,48(sp)
    80003f0c:	f426                	sd	s1,40(sp)
    80003f0e:	f04a                	sd	s2,32(sp)
    80003f10:	ec4e                	sd	s3,24(sp)
    80003f12:	e852                	sd	s4,16(sp)
    80003f14:	e456                	sd	s5,8(sp)
    80003f16:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);  // 获取日志锁
    80003f18:	00024497          	auipc	s1,0x24
    80003f1c:	da848493          	addi	s1,s1,-600 # 80027cc0 <log>
    80003f20:	8526                	mv	a0,s1
    80003f22:	dcdfc0ef          	jal	ra,80000cee <acquire>
  log.outstanding -= 1;  // 减少待处理操作计数
    80003f26:	4cdc                	lw	a5,28(s1)
    80003f28:	37fd                	addiw	a5,a5,-1
    80003f2a:	0007891b          	sext.w	s2,a5
    80003f2e:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80003f30:	509c                	lw	a5,32(s1)
    80003f32:	ef9d                	bnez	a5,80003f70 <end_op+0x6a>
    panic("log.committing");  // 不允许在提交时结束操作
  if(log.outstanding == 0){
    80003f34:	04091463          	bnez	s2,80003f7c <end_op+0x76>
    do_commit = 1;  // 如果没有待处理的操作，则标记为需要提交
    log.committing = 1;  // 标记日志为正在提交
    80003f38:	00024497          	auipc	s1,0x24
    80003f3c:	d8848493          	addi	s1,s1,-632 # 80027cc0 <log>
    80003f40:	4785                	li	a5,1
    80003f42:	d09c                	sw	a5,32(s1)
  } else {
    // 如果正在等待日志空间，唤醒等待的进程
    wakeup(&log);
  }
  release(&log.lock);  // 释放日志锁
    80003f44:	8526                	mv	a0,s1
    80003f46:	e41fc0ef          	jal	ra,80000d86 <release>
}

// 提交事务，将日志中的块写回磁盘并清空日志
static void commit()
{
  if (log.lh.n > 0) {
    80003f4a:	549c                	lw	a5,40(s1)
    80003f4c:	04f04b63          	bgtz	a5,80003fa2 <end_op+0x9c>
    acquire(&log.lock);
    80003f50:	00024497          	auipc	s1,0x24
    80003f54:	d7048493          	addi	s1,s1,-656 # 80027cc0 <log>
    80003f58:	8526                	mv	a0,s1
    80003f5a:	d95fc0ef          	jal	ra,80000cee <acquire>
    log.committing = 0;  // 提交完成，恢复日志状态
    80003f5e:	0204a023          	sw	zero,32(s1)
    wakeup(&log);  // 唤醒可能在等待提交的进程
    80003f62:	8526                	mv	a0,s1
    80003f64:	8fefe0ef          	jal	ra,80002062 <wakeup>
    release(&log.lock);  // 释放日志锁
    80003f68:	8526                	mv	a0,s1
    80003f6a:	e1dfc0ef          	jal	ra,80000d86 <release>
}
    80003f6e:	a00d                	j	80003f90 <end_op+0x8a>
    panic("log.committing");  // 不允许在提交时结束操作
    80003f70:	00004517          	auipc	a0,0x4
    80003f74:	86050513          	addi	a0,a0,-1952 # 800077d0 <syscalls+0x228>
    80003f78:	813fc0ef          	jal	ra,8000078a <panic>
    wakeup(&log);
    80003f7c:	00024497          	auipc	s1,0x24
    80003f80:	d4448493          	addi	s1,s1,-700 # 80027cc0 <log>
    80003f84:	8526                	mv	a0,s1
    80003f86:	8dcfe0ef          	jal	ra,80002062 <wakeup>
  release(&log.lock);  // 释放日志锁
    80003f8a:	8526                	mv	a0,s1
    80003f8c:	dfbfc0ef          	jal	ra,80000d86 <release>
}
    80003f90:	70e2                	ld	ra,56(sp)
    80003f92:	7442                	ld	s0,48(sp)
    80003f94:	74a2                	ld	s1,40(sp)
    80003f96:	7902                	ld	s2,32(sp)
    80003f98:	69e2                	ld	s3,24(sp)
    80003f9a:	6a42                	ld	s4,16(sp)
    80003f9c:	6aa2                	ld	s5,8(sp)
    80003f9e:	6121                	addi	sp,sp,64
    80003fa0:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fa2:	00024a97          	auipc	s5,0x24
    80003fa6:	d4aa8a93          	addi	s5,s5,-694 # 80027cec <log+0x2c>
    struct buf *to = bread(log.dev, log.start + tail + 1);  // 读取日志块
    80003faa:	00024a17          	auipc	s4,0x24
    80003fae:	d16a0a13          	addi	s4,s4,-746 # 80027cc0 <log>
    80003fb2:	018a2583          	lw	a1,24(s4)
    80003fb6:	012585bb          	addw	a1,a1,s2
    80003fba:	2585                	addiw	a1,a1,1
    80003fbc:	024a2503          	lw	a0,36(s4)
    80003fc0:	e47fe0ef          	jal	ra,80002e06 <bread>
    80003fc4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]);  // 读取缓存块
    80003fc6:	000aa583          	lw	a1,0(s5)
    80003fca:	024a2503          	lw	a0,36(s4)
    80003fce:	e39fe0ef          	jal	ra,80002e06 <bread>
    80003fd2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);  // 将缓存块的数据复制到日志块
    80003fd4:	40000613          	li	a2,1024
    80003fd8:	05850593          	addi	a1,a0,88
    80003fdc:	05848513          	addi	a0,s1,88
    80003fe0:	e3ffc0ef          	jal	ra,80000e1e <memmove>
    bwrite(to);  // 写入日志块
    80003fe4:	8526                	mv	a0,s1
    80003fe6:	ef7fe0ef          	jal	ra,80002edc <bwrite>
    brelse(from);  // 释放缓存块
    80003fea:	854e                	mv	a0,s3
    80003fec:	f23fe0ef          	jal	ra,80002f0e <brelse>
    brelse(to);  // 释放日志块
    80003ff0:	8526                	mv	a0,s1
    80003ff2:	f1dfe0ef          	jal	ra,80002f0e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ff6:	2905                	addiw	s2,s2,1
    80003ff8:	0a91                	addi	s5,s5,4
    80003ffa:	028a2783          	lw	a5,40(s4)
    80003ffe:	faf94ae3          	blt	s2,a5,80003fb2 <end_op+0xac>
    write_log();     // 将已修改的块从缓存写入日志
    write_head();    // 写入日志头到磁盘，真正提交
    80004002:	cd7ff0ef          	jal	ra,80003cd8 <write_head>
    install_trans(0); // 将写入操作应用到实际位置
    80004006:	4501                	li	a0,0
    80004008:	d3fff0ef          	jal	ra,80003d46 <install_trans>
    log.lh.n = 0;    // 清空日志中的块数量
    8000400c:	00024797          	auipc	a5,0x24
    80004010:	cc07ae23          	sw	zero,-804(a5) # 80027ce8 <log+0x28>
    write_head();    // 清空日志
    80004014:	cc5ff0ef          	jal	ra,80003cd8 <write_head>
    80004018:	bf25                	j	80003f50 <end_op+0x4a>

000000008000401a <log_write>:
//   bp = bread(...)
//   修改 bp->data[]
//   log_write(bp)
//   brelse(bp)
void log_write(struct buf *b)
{
    8000401a:	1101                	addi	sp,sp,-32
    8000401c:	ec06                	sd	ra,24(sp)
    8000401e:	e822                	sd	s0,16(sp)
    80004020:	e426                	sd	s1,8(sp)
    80004022:	e04a                	sd	s2,0(sp)
    80004024:	1000                	addi	s0,sp,32
    80004026:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);  // 获取日志锁
    80004028:	00024917          	auipc	s2,0x24
    8000402c:	c9890913          	addi	s2,s2,-872 # 80027cc0 <log>
    80004030:	854a                	mv	a0,s2
    80004032:	cbdfc0ef          	jal	ra,80000cee <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80004036:	02892603          	lw	a2,40(s2)
    8000403a:	47f5                	li	a5,29
    8000403c:	04c7cc63          	blt	a5,a2,80004094 <log_write+0x7a>
    panic("too big a transaction");  // 如果日志块数量超过最大值，出错
  if (log.outstanding < 1)
    80004040:	00024797          	auipc	a5,0x24
    80004044:	c9c7a783          	lw	a5,-868(a5) # 80027cdc <log+0x1c>
    80004048:	04f05c63          	blez	a5,800040a0 <log_write+0x86>
    panic("log_write outside of trans");  // 如果在没有事务的情况下调用，出错

  for (i = 0; i < log.lh.n; i++) {
    8000404c:	4781                	li	a5,0
    8000404e:	04c05f63          	blez	a2,800040ac <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // 如果块已经存在于日志中，跳过
    80004052:	44cc                	lw	a1,12(s1)
    80004054:	00024717          	auipc	a4,0x24
    80004058:	c9870713          	addi	a4,a4,-872 # 80027cec <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    8000405c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // 如果块已经存在于日志中，跳过
    8000405e:	4314                	lw	a3,0(a4)
    80004060:	04b68663          	beq	a3,a1,800040ac <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80004064:	2785                	addiw	a5,a5,1
    80004066:	0711                	addi	a4,a4,4
    80004068:	fef61be3          	bne	a2,a5,8000405e <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;  // 将块号记录到日志中
    8000406c:	0621                	addi	a2,a2,8
    8000406e:	060a                	slli	a2,a2,0x2
    80004070:	00024797          	auipc	a5,0x24
    80004074:	c5078793          	addi	a5,a5,-944 # 80027cc0 <log>
    80004078:	963e                	add	a2,a2,a5
    8000407a:	44dc                	lw	a5,12(s1)
    8000407c:	c65c                	sw	a5,12(a2)
  if (i == log.lh.n) {  // 如果是新块，添加到日志
    bpin(b);  // 锁定块
    8000407e:	8526                	mv	a0,s1
    80004080:	f19fe0ef          	jal	ra,80002f98 <bpin>
    log.lh.n++;  // 增加日志中的块数量
    80004084:	00024717          	auipc	a4,0x24
    80004088:	c3c70713          	addi	a4,a4,-964 # 80027cc0 <log>
    8000408c:	571c                	lw	a5,40(a4)
    8000408e:	2785                	addiw	a5,a5,1
    80004090:	d71c                	sw	a5,40(a4)
    80004092:	a815                	j	800040c6 <log_write+0xac>
    panic("too big a transaction");  // 如果日志块数量超过最大值，出错
    80004094:	00003517          	auipc	a0,0x3
    80004098:	74c50513          	addi	a0,a0,1868 # 800077e0 <syscalls+0x238>
    8000409c:	eeefc0ef          	jal	ra,8000078a <panic>
    panic("log_write outside of trans");  // 如果在没有事务的情况下调用，出错
    800040a0:	00003517          	auipc	a0,0x3
    800040a4:	75850513          	addi	a0,a0,1880 # 800077f8 <syscalls+0x250>
    800040a8:	ee2fc0ef          	jal	ra,8000078a <panic>
  log.lh.block[i] = b->blockno;  // 将块号记录到日志中
    800040ac:	00878713          	addi	a4,a5,8
    800040b0:	00271693          	slli	a3,a4,0x2
    800040b4:	00024717          	auipc	a4,0x24
    800040b8:	c0c70713          	addi	a4,a4,-1012 # 80027cc0 <log>
    800040bc:	9736                	add	a4,a4,a3
    800040be:	44d4                	lw	a3,12(s1)
    800040c0:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // 如果是新块，添加到日志
    800040c2:	faf60ee3          	beq	a2,a5,8000407e <log_write+0x64>
  }
  release(&log.lock);  // 释放日志锁
    800040c6:	00024517          	auipc	a0,0x24
    800040ca:	bfa50513          	addi	a0,a0,-1030 # 80027cc0 <log>
    800040ce:	cb9fc0ef          	jal	ra,80000d86 <release>
}
    800040d2:	60e2                	ld	ra,24(sp)
    800040d4:	6442                	ld	s0,16(sp)
    800040d6:	64a2                	ld	s1,8(sp)
    800040d8:	6902                	ld	s2,0(sp)
    800040da:	6105                	addi	sp,sp,32
    800040dc:	8082                	ret

00000000800040de <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800040de:	1101                	addi	sp,sp,-32
    800040e0:	ec06                	sd	ra,24(sp)
    800040e2:	e822                	sd	s0,16(sp)
    800040e4:	e426                	sd	s1,8(sp)
    800040e6:	e04a                	sd	s2,0(sp)
    800040e8:	1000                	addi	s0,sp,32
    800040ea:	84aa                	mv	s1,a0
    800040ec:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800040ee:	00003597          	auipc	a1,0x3
    800040f2:	72a58593          	addi	a1,a1,1834 # 80007818 <syscalls+0x270>
    800040f6:	0521                	addi	a0,a0,8
    800040f8:	b77fc0ef          	jal	ra,80000c6e <initlock>
  lk->name = name;
    800040fc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004100:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004104:	0204a423          	sw	zero,40(s1)
}
    80004108:	60e2                	ld	ra,24(sp)
    8000410a:	6442                	ld	s0,16(sp)
    8000410c:	64a2                	ld	s1,8(sp)
    8000410e:	6902                	ld	s2,0(sp)
    80004110:	6105                	addi	sp,sp,32
    80004112:	8082                	ret

0000000080004114 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004114:	1101                	addi	sp,sp,-32
    80004116:	ec06                	sd	ra,24(sp)
    80004118:	e822                	sd	s0,16(sp)
    8000411a:	e426                	sd	s1,8(sp)
    8000411c:	e04a                	sd	s2,0(sp)
    8000411e:	1000                	addi	s0,sp,32
    80004120:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004122:	00850913          	addi	s2,a0,8
    80004126:	854a                	mv	a0,s2
    80004128:	bc7fc0ef          	jal	ra,80000cee <acquire>
  while (lk->locked) {
    8000412c:	409c                	lw	a5,0(s1)
    8000412e:	c799                	beqz	a5,8000413c <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80004130:	85ca                	mv	a1,s2
    80004132:	8526                	mv	a0,s1
    80004134:	ee3fd0ef          	jal	ra,80002016 <sleep>
  while (lk->locked) {
    80004138:	409c                	lw	a5,0(s1)
    8000413a:	fbfd                	bnez	a5,80004130 <acquiresleep+0x1c>
  }
  lk->locked = 1;
    8000413c:	4785                	li	a5,1
    8000413e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004140:	8c5fd0ef          	jal	ra,80001a04 <myproc>
    80004144:	591c                	lw	a5,48(a0)
    80004146:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004148:	854a                	mv	a0,s2
    8000414a:	c3dfc0ef          	jal	ra,80000d86 <release>
}
    8000414e:	60e2                	ld	ra,24(sp)
    80004150:	6442                	ld	s0,16(sp)
    80004152:	64a2                	ld	s1,8(sp)
    80004154:	6902                	ld	s2,0(sp)
    80004156:	6105                	addi	sp,sp,32
    80004158:	8082                	ret

000000008000415a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000415a:	1101                	addi	sp,sp,-32
    8000415c:	ec06                	sd	ra,24(sp)
    8000415e:	e822                	sd	s0,16(sp)
    80004160:	e426                	sd	s1,8(sp)
    80004162:	e04a                	sd	s2,0(sp)
    80004164:	1000                	addi	s0,sp,32
    80004166:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004168:	00850913          	addi	s2,a0,8
    8000416c:	854a                	mv	a0,s2
    8000416e:	b81fc0ef          	jal	ra,80000cee <acquire>
  lk->locked = 0;
    80004172:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004176:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000417a:	8526                	mv	a0,s1
    8000417c:	ee7fd0ef          	jal	ra,80002062 <wakeup>
  release(&lk->lk);
    80004180:	854a                	mv	a0,s2
    80004182:	c05fc0ef          	jal	ra,80000d86 <release>
}
    80004186:	60e2                	ld	ra,24(sp)
    80004188:	6442                	ld	s0,16(sp)
    8000418a:	64a2                	ld	s1,8(sp)
    8000418c:	6902                	ld	s2,0(sp)
    8000418e:	6105                	addi	sp,sp,32
    80004190:	8082                	ret

0000000080004192 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004192:	7179                	addi	sp,sp,-48
    80004194:	f406                	sd	ra,40(sp)
    80004196:	f022                	sd	s0,32(sp)
    80004198:	ec26                	sd	s1,24(sp)
    8000419a:	e84a                	sd	s2,16(sp)
    8000419c:	e44e                	sd	s3,8(sp)
    8000419e:	1800                	addi	s0,sp,48
    800041a0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800041a2:	00850913          	addi	s2,a0,8
    800041a6:	854a                	mv	a0,s2
    800041a8:	b47fc0ef          	jal	ra,80000cee <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800041ac:	409c                	lw	a5,0(s1)
    800041ae:	ef89                	bnez	a5,800041c8 <holdingsleep+0x36>
    800041b0:	4481                	li	s1,0
  release(&lk->lk);
    800041b2:	854a                	mv	a0,s2
    800041b4:	bd3fc0ef          	jal	ra,80000d86 <release>
  return r;
}
    800041b8:	8526                	mv	a0,s1
    800041ba:	70a2                	ld	ra,40(sp)
    800041bc:	7402                	ld	s0,32(sp)
    800041be:	64e2                	ld	s1,24(sp)
    800041c0:	6942                	ld	s2,16(sp)
    800041c2:	69a2                	ld	s3,8(sp)
    800041c4:	6145                	addi	sp,sp,48
    800041c6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800041c8:	0284a983          	lw	s3,40(s1)
    800041cc:	839fd0ef          	jal	ra,80001a04 <myproc>
    800041d0:	5904                	lw	s1,48(a0)
    800041d2:	413484b3          	sub	s1,s1,s3
    800041d6:	0014b493          	seqz	s1,s1
    800041da:	bfe1                	j	800041b2 <holdingsleep+0x20>

00000000800041dc <fileinit>:
} ftable;

// 文件表初始化
void
fileinit(void)
{
    800041dc:	1141                	addi	sp,sp,-16
    800041de:	e406                	sd	ra,8(sp)
    800041e0:	e022                	sd	s0,0(sp)
    800041e2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");  // 初始化文件表的自旋锁
    800041e4:	00003597          	auipc	a1,0x3
    800041e8:	64458593          	addi	a1,a1,1604 # 80007828 <syscalls+0x280>
    800041ec:	00024517          	auipc	a0,0x24
    800041f0:	c1c50513          	addi	a0,a0,-996 # 80027e08 <ftable>
    800041f4:	a7bfc0ef          	jal	ra,80000c6e <initlock>
}
    800041f8:	60a2                	ld	ra,8(sp)
    800041fa:	6402                	ld	s0,0(sp)
    800041fc:	0141                	addi	sp,sp,16
    800041fe:	8082                	ret

0000000080004200 <filealloc>:

// 分配一个新的文件结构体
struct file*
filealloc(void)
{
    80004200:	1101                	addi	sp,sp,-32
    80004202:	ec06                	sd	ra,24(sp)
    80004204:	e822                	sd	s0,16(sp)
    80004206:	e426                	sd	s1,8(sp)
    80004208:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);  // 获取文件表锁
    8000420a:	00024517          	auipc	a0,0x24
    8000420e:	bfe50513          	addi	a0,a0,-1026 # 80027e08 <ftable>
    80004212:	addfc0ef          	jal	ra,80000cee <acquire>
  // 遍历文件表，找到引用计数为 0 的文件结构体
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004216:	00024497          	auipc	s1,0x24
    8000421a:	c0a48493          	addi	s1,s1,-1014 # 80027e20 <ftable+0x18>
    8000421e:	00025717          	auipc	a4,0x25
    80004222:	ba270713          	addi	a4,a4,-1118 # 80028dc0 <disk>
    if(f->ref == 0){
    80004226:	40dc                	lw	a5,4(s1)
    80004228:	cf89                	beqz	a5,80004242 <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000422a:	02848493          	addi	s1,s1,40
    8000422e:	fee49ce3          	bne	s1,a4,80004226 <filealloc+0x26>
      f->ref = 1;  // 设置引用计数为 1
      release(&ftable.lock);  // 释放文件表锁
      return f;  // 返回分配的文件结构体
    }
  }
  release(&ftable.lock);  // 如果没有空闲文件结构体，释放锁
    80004232:	00024517          	auipc	a0,0x24
    80004236:	bd650513          	addi	a0,a0,-1066 # 80027e08 <ftable>
    8000423a:	b4dfc0ef          	jal	ra,80000d86 <release>
  return 0;  // 没有可用的文件结构体
    8000423e:	4481                	li	s1,0
    80004240:	a809                	j	80004252 <filealloc+0x52>
      f->ref = 1;  // 设置引用计数为 1
    80004242:	4785                	li	a5,1
    80004244:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);  // 释放文件表锁
    80004246:	00024517          	auipc	a0,0x24
    8000424a:	bc250513          	addi	a0,a0,-1086 # 80027e08 <ftable>
    8000424e:	b39fc0ef          	jal	ra,80000d86 <release>
}
    80004252:	8526                	mv	a0,s1
    80004254:	60e2                	ld	ra,24(sp)
    80004256:	6442                	ld	s0,16(sp)
    80004258:	64a2                	ld	s1,8(sp)
    8000425a:	6105                	addi	sp,sp,32
    8000425c:	8082                	ret

000000008000425e <filedup>:

// 增加文件结构体的引用计数
struct file*
filedup(struct file *f)
{
    8000425e:	1101                	addi	sp,sp,-32
    80004260:	ec06                	sd	ra,24(sp)
    80004262:	e822                	sd	s0,16(sp)
    80004264:	e426                	sd	s1,8(sp)
    80004266:	1000                	addi	s0,sp,32
    80004268:	84aa                	mv	s1,a0
  acquire(&ftable.lock);  // 获取文件表锁
    8000426a:	00024517          	auipc	a0,0x24
    8000426e:	b9e50513          	addi	a0,a0,-1122 # 80027e08 <ftable>
    80004272:	a7dfc0ef          	jal	ra,80000cee <acquire>
  if(f->ref < 1)  // 如果引用计数小于 1，说明文件结构体无效
    80004276:	40dc                	lw	a5,4(s1)
    80004278:	02f05063          	blez	a5,80004298 <filedup+0x3a>
    panic("filedup");
  f->ref++;  // 增加引用计数
    8000427c:	2785                	addiw	a5,a5,1
    8000427e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);  // 释放文件表锁
    80004280:	00024517          	auipc	a0,0x24
    80004284:	b8850513          	addi	a0,a0,-1144 # 80027e08 <ftable>
    80004288:	afffc0ef          	jal	ra,80000d86 <release>
  return f;  // 返回文件结构体
}
    8000428c:	8526                	mv	a0,s1
    8000428e:	60e2                	ld	ra,24(sp)
    80004290:	6442                	ld	s0,16(sp)
    80004292:	64a2                	ld	s1,8(sp)
    80004294:	6105                	addi	sp,sp,32
    80004296:	8082                	ret
    panic("filedup");
    80004298:	00003517          	auipc	a0,0x3
    8000429c:	59850513          	addi	a0,a0,1432 # 80007830 <syscalls+0x288>
    800042a0:	ceafc0ef          	jal	ra,8000078a <panic>

00000000800042a4 <fileclose>:

// 关闭文件结构体 f，减少引用计数，当引用计数为 0 时关闭文件
void
fileclose(struct file *f)
{
    800042a4:	7139                	addi	sp,sp,-64
    800042a6:	fc06                	sd	ra,56(sp)
    800042a8:	f822                	sd	s0,48(sp)
    800042aa:	f426                	sd	s1,40(sp)
    800042ac:	f04a                	sd	s2,32(sp)
    800042ae:	ec4e                	sd	s3,24(sp)
    800042b0:	e852                	sd	s4,16(sp)
    800042b2:	e456                	sd	s5,8(sp)
    800042b4:	0080                	addi	s0,sp,64
    800042b6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);  // 获取文件表锁
    800042b8:	00024517          	auipc	a0,0x24
    800042bc:	b5050513          	addi	a0,a0,-1200 # 80027e08 <ftable>
    800042c0:	a2ffc0ef          	jal	ra,80000cee <acquire>
  if(f->ref < 1)  // 如果引用计数小于 1，说明文件结构体无效
    800042c4:	40dc                	lw	a5,4(s1)
    800042c6:	04f05963          	blez	a5,80004318 <fileclose+0x74>
    panic("fileclose");
  if(--f->ref > 0){  // 如果引用计数大于 0，直接返回
    800042ca:	37fd                	addiw	a5,a5,-1
    800042cc:	0007871b          	sext.w	a4,a5
    800042d0:	c0dc                	sw	a5,4(s1)
    800042d2:	04e04963          	bgtz	a4,80004324 <fileclose+0x80>
    release(&ftable.lock);
    return;
  }
  ff = *f;  // 备份文件结构体
    800042d6:	0004a903          	lw	s2,0(s1)
    800042da:	0094ca83          	lbu	s5,9(s1)
    800042de:	0104ba03          	ld	s4,16(s1)
    800042e2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;  // 重置引用计数
    800042e6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;  // 重置文件类型
    800042ea:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);  // 释放文件表锁
    800042ee:	00024517          	auipc	a0,0x24
    800042f2:	b1a50513          	addi	a0,a0,-1254 # 80027e08 <ftable>
    800042f6:	a91fc0ef          	jal	ra,80000d86 <release>

  // 如果文件类型是管道（pipe），则关闭管道
  if(ff.type == FD_PIPE){
    800042fa:	4785                	li	a5,1
    800042fc:	04f90363          	beq	s2,a5,80004342 <fileclose+0x9e>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004300:	3979                	addiw	s2,s2,-2
    80004302:	4785                	li	a5,1
    80004304:	0327e663          	bltu	a5,s2,80004330 <fileclose+0x8c>
    begin_op();  // 开始一个文件系统操作
    80004308:	b8fff0ef          	jal	ra,80003e96 <begin_op>
    iput(ff.ip);  // 释放 inode
    8000430c:	854e                	mv	a0,s3
    8000430e:	b28ff0ef          	jal	ra,80003636 <iput>
    end_op();  // 结束文件系统操作
    80004312:	bf5ff0ef          	jal	ra,80003f06 <end_op>
    80004316:	a829                	j	80004330 <fileclose+0x8c>
    panic("fileclose");
    80004318:	00003517          	auipc	a0,0x3
    8000431c:	52050513          	addi	a0,a0,1312 # 80007838 <syscalls+0x290>
    80004320:	c6afc0ef          	jal	ra,8000078a <panic>
    release(&ftable.lock);
    80004324:	00024517          	auipc	a0,0x24
    80004328:	ae450513          	addi	a0,a0,-1308 # 80027e08 <ftable>
    8000432c:	a5bfc0ef          	jal	ra,80000d86 <release>
  }
}
    80004330:	70e2                	ld	ra,56(sp)
    80004332:	7442                	ld	s0,48(sp)
    80004334:	74a2                	ld	s1,40(sp)
    80004336:	7902                	ld	s2,32(sp)
    80004338:	69e2                	ld	s3,24(sp)
    8000433a:	6a42                	ld	s4,16(sp)
    8000433c:	6aa2                	ld	s5,8(sp)
    8000433e:	6121                	addi	sp,sp,64
    80004340:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004342:	85d6                	mv	a1,s5
    80004344:	8552                	mv	a0,s4
    80004346:	2ec000ef          	jal	ra,80004632 <pipeclose>
    8000434a:	b7dd                	j	80004330 <fileclose+0x8c>

000000008000434c <filestat>:

// 获取文件 f 的元数据（如文件大小、类型等）
// addr 是一个用户虚拟地址，指向 struct stat 结构
int
filestat(struct file *f, uint64 addr)
{
    8000434c:	715d                	addi	sp,sp,-80
    8000434e:	e486                	sd	ra,72(sp)
    80004350:	e0a2                	sd	s0,64(sp)
    80004352:	fc26                	sd	s1,56(sp)
    80004354:	f84a                	sd	s2,48(sp)
    80004356:	f44e                	sd	s3,40(sp)
    80004358:	0880                	addi	s0,sp,80
    8000435a:	84aa                	mv	s1,a0
    8000435c:	89ae                	mv	s3,a1
  struct proc *p = myproc();  // 获取当前进程
    8000435e:	ea6fd0ef          	jal	ra,80001a04 <myproc>
  struct stat st;
  
  // 如果文件是 inode 类型或设备类型
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004362:	409c                	lw	a5,0(s1)
    80004364:	37f9                	addiw	a5,a5,-2
    80004366:	4705                	li	a4,1
    80004368:	02f76f63          	bltu	a4,a5,800043a6 <filestat+0x5a>
    8000436c:	892a                	mv	s2,a0
    ilock(f->ip);  // 锁定 inode
    8000436e:	6c88                	ld	a0,24(s1)
    80004370:	948ff0ef          	jal	ra,800034b8 <ilock>
    stati(f->ip, &st);  // 获取 inode 的元数据
    80004374:	fb840593          	addi	a1,s0,-72
    80004378:	6c88                	ld	a0,24(s1)
    8000437a:	ca0ff0ef          	jal	ra,8000381a <stati>
    iunlock(f->ip);  // 解锁 inode
    8000437e:	6c88                	ld	a0,24(s1)
    80004380:	9e2ff0ef          	jal	ra,80003562 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)  // 将元数据复制到用户地址
    80004384:	46e1                	li	a3,24
    80004386:	fb840613          	addi	a2,s0,-72
    8000438a:	85ce                	mv	a1,s3
    8000438c:	05093503          	ld	a0,80(s2)
    80004390:	a2afd0ef          	jal	ra,800015ba <copyout>
    80004394:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;  // 其他类型文件不支持
}
    80004398:	60a6                	ld	ra,72(sp)
    8000439a:	6406                	ld	s0,64(sp)
    8000439c:	74e2                	ld	s1,56(sp)
    8000439e:	7942                	ld	s2,48(sp)
    800043a0:	79a2                	ld	s3,40(sp)
    800043a2:	6161                	addi	sp,sp,80
    800043a4:	8082                	ret
  return -1;  // 其他类型文件不支持
    800043a6:	557d                	li	a0,-1
    800043a8:	bfc5                	j	80004398 <filestat+0x4c>

00000000800043aa <fileread>:

// 从文件 f 中读取数据。
// addr 是一个用户虚拟地址。
int
fileread(struct file *f, uint64 addr, int n)
{
    800043aa:	7179                	addi	sp,sp,-48
    800043ac:	f406                	sd	ra,40(sp)
    800043ae:	f022                	sd	s0,32(sp)
    800043b0:	ec26                	sd	s1,24(sp)
    800043b2:	e84a                	sd	s2,16(sp)
    800043b4:	e44e                	sd	s3,8(sp)
    800043b6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)  // 如果文件不可读，返回 -1
    800043b8:	00854783          	lbu	a5,8(a0)
    800043bc:	cbc1                	beqz	a5,8000444c <fileread+0xa2>
    800043be:	84aa                	mv	s1,a0
    800043c0:	89ae                	mv	s3,a1
    800043c2:	8932                	mv	s2,a2
    return -1;

  // 根据文件类型执行不同的读取操作
  if(f->type == FD_PIPE){
    800043c4:	411c                	lw	a5,0(a0)
    800043c6:	4705                	li	a4,1
    800043c8:	04e78363          	beq	a5,a4,8000440e <fileread+0x64>
    r = piperead(f->pipe, addr, n);  // 从管道中读取
  } else if(f->type == FD_DEVICE){
    800043cc:	470d                	li	a4,3
    800043ce:	04e78563          	beq	a5,a4,80004418 <fileread+0x6e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)  // 如果设备不支持读取，返回 -1
      return -1;
    r = devsw[f->major].read(1, addr, n);  // 调用设备的读取函数
  } else if(f->type == FD_INODE){
    800043d2:	4709                	li	a4,2
    800043d4:	06e79663          	bne	a5,a4,80004440 <fileread+0x96>
    ilock(f->ip);  // 锁定 inode
    800043d8:	6d08                	ld	a0,24(a0)
    800043da:	8deff0ef          	jal	ra,800034b8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)  // 从 inode 中读取数据
    800043de:	874a                	mv	a4,s2
    800043e0:	5094                	lw	a3,32(s1)
    800043e2:	864e                	mv	a2,s3
    800043e4:	4585                	li	a1,1
    800043e6:	6c88                	ld	a0,24(s1)
    800043e8:	c5cff0ef          	jal	ra,80003844 <readi>
    800043ec:	892a                	mv	s2,a0
    800043ee:	00a05563          	blez	a0,800043f8 <fileread+0x4e>
      f->off += r;  // 更新文件偏移量
    800043f2:	509c                	lw	a5,32(s1)
    800043f4:	9fa9                	addw	a5,a5,a0
    800043f6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);  // 解锁 inode
    800043f8:	6c88                	ld	a0,24(s1)
    800043fa:	968ff0ef          	jal	ra,80003562 <iunlock>
  } else {
    panic("fileread");  // 不支持的文件类型
  }

  return r;  // 返回读取的字节数
}
    800043fe:	854a                	mv	a0,s2
    80004400:	70a2                	ld	ra,40(sp)
    80004402:	7402                	ld	s0,32(sp)
    80004404:	64e2                	ld	s1,24(sp)
    80004406:	6942                	ld	s2,16(sp)
    80004408:	69a2                	ld	s3,8(sp)
    8000440a:	6145                	addi	sp,sp,48
    8000440c:	8082                	ret
    r = piperead(f->pipe, addr, n);  // 从管道中读取
    8000440e:	6908                	ld	a0,16(a0)
    80004410:	34e000ef          	jal	ra,8000475e <piperead>
    80004414:	892a                	mv	s2,a0
    80004416:	b7e5                	j	800043fe <fileread+0x54>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)  // 如果设备不支持读取，返回 -1
    80004418:	02451783          	lh	a5,36(a0)
    8000441c:	03079693          	slli	a3,a5,0x30
    80004420:	92c1                	srli	a3,a3,0x30
    80004422:	4725                	li	a4,9
    80004424:	02d76663          	bltu	a4,a3,80004450 <fileread+0xa6>
    80004428:	0792                	slli	a5,a5,0x4
    8000442a:	00024717          	auipc	a4,0x24
    8000442e:	93e70713          	addi	a4,a4,-1730 # 80027d68 <devsw>
    80004432:	97ba                	add	a5,a5,a4
    80004434:	639c                	ld	a5,0(a5)
    80004436:	cf99                	beqz	a5,80004454 <fileread+0xaa>
    r = devsw[f->major].read(1, addr, n);  // 调用设备的读取函数
    80004438:	4505                	li	a0,1
    8000443a:	9782                	jalr	a5
    8000443c:	892a                	mv	s2,a0
    8000443e:	b7c1                	j	800043fe <fileread+0x54>
    panic("fileread");  // 不支持的文件类型
    80004440:	00003517          	auipc	a0,0x3
    80004444:	40850513          	addi	a0,a0,1032 # 80007848 <syscalls+0x2a0>
    80004448:	b42fc0ef          	jal	ra,8000078a <panic>
    return -1;
    8000444c:	597d                	li	s2,-1
    8000444e:	bf45                	j	800043fe <fileread+0x54>
      return -1;
    80004450:	597d                	li	s2,-1
    80004452:	b775                	j	800043fe <fileread+0x54>
    80004454:	597d                	li	s2,-1
    80004456:	b765                	j	800043fe <fileread+0x54>

0000000080004458 <filewrite>:

// 向文件 f 中写入数据。
// addr 是一个用户虚拟地址。
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004458:	715d                	addi	sp,sp,-80
    8000445a:	e486                	sd	ra,72(sp)
    8000445c:	e0a2                	sd	s0,64(sp)
    8000445e:	fc26                	sd	s1,56(sp)
    80004460:	f84a                	sd	s2,48(sp)
    80004462:	f44e                	sd	s3,40(sp)
    80004464:	f052                	sd	s4,32(sp)
    80004466:	ec56                	sd	s5,24(sp)
    80004468:	e85a                	sd	s6,16(sp)
    8000446a:	e45e                	sd	s7,8(sp)
    8000446c:	e062                	sd	s8,0(sp)
    8000446e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)  // 如果文件不可写，返回 -1
    80004470:	00954783          	lbu	a5,9(a0)
    80004474:	0e078863          	beqz	a5,80004564 <filewrite+0x10c>
    80004478:	892a                	mv	s2,a0
    8000447a:	8aae                	mv	s5,a1
    8000447c:	8a32                	mv	s4,a2
    return -1;

  // 根据文件类型执行不同的写入操作
  if(f->type == FD_PIPE){
    8000447e:	411c                	lw	a5,0(a0)
    80004480:	4705                	li	a4,1
    80004482:	02e78263          	beq	a5,a4,800044a6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);  // 向管道中写入
  } else if(f->type == FD_DEVICE){
    80004486:	470d                	li	a4,3
    80004488:	02e78463          	beq	a5,a4,800044b0 <filewrite+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)  // 如果设备不支持写入，返回 -1
      return -1;
    ret = devsw[f->major].write(1, addr, n);  // 调用设备的写入函数
  } else if(f->type == FD_INODE){
    8000448c:	4709                	li	a4,2
    8000448e:	0ce79563          	bne	a5,a4,80004558 <filewrite+0x100>
    // 分多次写入，以避免超过最大日志事务大小，包括 inode、间接块、分配块等
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004492:	0ac05163          	blez	a2,80004534 <filewrite+0xdc>
    int i = 0;
    80004496:	4981                	li	s3,0
    80004498:	6b05                	lui	s6,0x1
    8000449a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000449e:	6b85                	lui	s7,0x1
    800044a0:	c00b8b9b          	addiw	s7,s7,-1024
    800044a4:	a041                	j	80004524 <filewrite+0xcc>
    ret = pipewrite(f->pipe, addr, n);  // 向管道中写入
    800044a6:	6908                	ld	a0,16(a0)
    800044a8:	1e2000ef          	jal	ra,8000468a <pipewrite>
    800044ac:	8a2a                	mv	s4,a0
    800044ae:	a071                	j	8000453a <filewrite+0xe2>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)  // 如果设备不支持写入，返回 -1
    800044b0:	02451783          	lh	a5,36(a0)
    800044b4:	03079693          	slli	a3,a5,0x30
    800044b8:	92c1                	srli	a3,a3,0x30
    800044ba:	4725                	li	a4,9
    800044bc:	0ad76663          	bltu	a4,a3,80004568 <filewrite+0x110>
    800044c0:	0792                	slli	a5,a5,0x4
    800044c2:	00024717          	auipc	a4,0x24
    800044c6:	8a670713          	addi	a4,a4,-1882 # 80027d68 <devsw>
    800044ca:	97ba                	add	a5,a5,a4
    800044cc:	679c                	ld	a5,8(a5)
    800044ce:	cfd9                	beqz	a5,8000456c <filewrite+0x114>
    ret = devsw[f->major].write(1, addr, n);  // 调用设备的写入函数
    800044d0:	4505                	li	a0,1
    800044d2:	9782                	jalr	a5
    800044d4:	8a2a                	mv	s4,a0
    800044d6:	a095                	j	8000453a <filewrite+0xe2>
    800044d8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)  // 如果写入数据超过最大限制，分批次写入
        n1 = max;

      begin_op();  // 开始一个文件系统操作
    800044dc:	9bbff0ef          	jal	ra,80003e96 <begin_op>
      ilock(f->ip);  // 锁定 inode
    800044e0:	01893503          	ld	a0,24(s2)
    800044e4:	fd5fe0ef          	jal	ra,800034b8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800044e8:	8762                	mv	a4,s8
    800044ea:	02092683          	lw	a3,32(s2)
    800044ee:	01598633          	add	a2,s3,s5
    800044f2:	4585                	li	a1,1
    800044f4:	01893503          	ld	a0,24(s2)
    800044f8:	c30ff0ef          	jal	ra,80003928 <writei>
    800044fc:	84aa                	mv	s1,a0
    800044fe:	00a05763          	blez	a0,8000450c <filewrite+0xb4>
        f->off += r;  // 更新文件偏移量
    80004502:	02092783          	lw	a5,32(s2)
    80004506:	9fa9                	addw	a5,a5,a0
    80004508:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);  // 解锁 inode
    8000450c:	01893503          	ld	a0,24(s2)
    80004510:	852ff0ef          	jal	ra,80003562 <iunlock>
      end_op();  // 结束文件系统操作
    80004514:	9f3ff0ef          	jal	ra,80003f06 <end_op>

      if(r != n1){  // 如果写入不完全，退出
    80004518:	009c1f63          	bne	s8,s1,80004536 <filewrite+0xde>
        break;
      }
      i += r;
    8000451c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004520:	0149db63          	bge	s3,s4,80004536 <filewrite+0xde>
      int n1 = n - i;
    80004524:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)  // 如果写入数据超过最大限制，分批次写入
    80004528:	84be                	mv	s1,a5
    8000452a:	2781                	sext.w	a5,a5
    8000452c:	fafb56e3          	bge	s6,a5,800044d8 <filewrite+0x80>
    80004530:	84de                	mv	s1,s7
    80004532:	b75d                	j	800044d8 <filewrite+0x80>
    int i = 0;
    80004534:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);  // 如果写入完全成功，返回写入字节数，否则返回 -1
    80004536:	013a1f63          	bne	s4,s3,80004554 <filewrite+0xfc>
  } else {
    panic("filewrite");  // 不支持的文件类型
  }

  return ret;  // 返回写入的字节数
}
    8000453a:	8552                	mv	a0,s4
    8000453c:	60a6                	ld	ra,72(sp)
    8000453e:	6406                	ld	s0,64(sp)
    80004540:	74e2                	ld	s1,56(sp)
    80004542:	7942                	ld	s2,48(sp)
    80004544:	79a2                	ld	s3,40(sp)
    80004546:	7a02                	ld	s4,32(sp)
    80004548:	6ae2                	ld	s5,24(sp)
    8000454a:	6b42                	ld	s6,16(sp)
    8000454c:	6ba2                	ld	s7,8(sp)
    8000454e:	6c02                	ld	s8,0(sp)
    80004550:	6161                	addi	sp,sp,80
    80004552:	8082                	ret
    ret = (i == n ? n : -1);  // 如果写入完全成功，返回写入字节数，否则返回 -1
    80004554:	5a7d                	li	s4,-1
    80004556:	b7d5                	j	8000453a <filewrite+0xe2>
    panic("filewrite");  // 不支持的文件类型
    80004558:	00003517          	auipc	a0,0x3
    8000455c:	30050513          	addi	a0,a0,768 # 80007858 <syscalls+0x2b0>
    80004560:	a2afc0ef          	jal	ra,8000078a <panic>
    return -1;
    80004564:	5a7d                	li	s4,-1
    80004566:	bfd1                	j	8000453a <filewrite+0xe2>
      return -1;
    80004568:	5a7d                	li	s4,-1
    8000456a:	bfc1                	j	8000453a <filewrite+0xe2>
    8000456c:	5a7d                	li	s4,-1
    8000456e:	b7f1                	j	8000453a <filewrite+0xe2>

0000000080004570 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004570:	7179                	addi	sp,sp,-48
    80004572:	f406                	sd	ra,40(sp)
    80004574:	f022                	sd	s0,32(sp)
    80004576:	ec26                	sd	s1,24(sp)
    80004578:	e84a                	sd	s2,16(sp)
    8000457a:	e44e                	sd	s3,8(sp)
    8000457c:	e052                	sd	s4,0(sp)
    8000457e:	1800                	addi	s0,sp,48
    80004580:	84aa                	mv	s1,a0
    80004582:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004584:	0005b023          	sd	zero,0(a1)
    80004588:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000458c:	c75ff0ef          	jal	ra,80004200 <filealloc>
    80004590:	e088                	sd	a0,0(s1)
    80004592:	cd35                	beqz	a0,8000460e <pipealloc+0x9e>
    80004594:	c6dff0ef          	jal	ra,80004200 <filealloc>
    80004598:	00aa3023          	sd	a0,0(s4)
    8000459c:	c52d                	beqz	a0,80004606 <pipealloc+0x96>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000459e:	e50fc0ef          	jal	ra,80000bee <kalloc>
    800045a2:	892a                	mv	s2,a0
    800045a4:	cd31                	beqz	a0,80004600 <pipealloc+0x90>
    goto bad;
  pi->readopen = 1;
    800045a6:	4985                	li	s3,1
    800045a8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800045ac:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800045b0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800045b4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800045b8:	00003597          	auipc	a1,0x3
    800045bc:	2b058593          	addi	a1,a1,688 # 80007868 <syscalls+0x2c0>
    800045c0:	eaefc0ef          	jal	ra,80000c6e <initlock>
  (*f0)->type = FD_PIPE;
    800045c4:	609c                	ld	a5,0(s1)
    800045c6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800045ca:	609c                	ld	a5,0(s1)
    800045cc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800045d0:	609c                	ld	a5,0(s1)
    800045d2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800045d6:	609c                	ld	a5,0(s1)
    800045d8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800045dc:	000a3783          	ld	a5,0(s4)
    800045e0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800045e4:	000a3783          	ld	a5,0(s4)
    800045e8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800045ec:	000a3783          	ld	a5,0(s4)
    800045f0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800045f4:	000a3783          	ld	a5,0(s4)
    800045f8:	0127b823          	sd	s2,16(a5)
  return 0;
    800045fc:	4501                	li	a0,0
    800045fe:	a005                	j	8000461e <pipealloc+0xae>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004600:	6088                	ld	a0,0(s1)
    80004602:	e501                	bnez	a0,8000460a <pipealloc+0x9a>
    80004604:	a029                	j	8000460e <pipealloc+0x9e>
    80004606:	6088                	ld	a0,0(s1)
    80004608:	c11d                	beqz	a0,8000462e <pipealloc+0xbe>
    fileclose(*f0);
    8000460a:	c9bff0ef          	jal	ra,800042a4 <fileclose>
  if(*f1)
    8000460e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004612:	557d                	li	a0,-1
  if(*f1)
    80004614:	c789                	beqz	a5,8000461e <pipealloc+0xae>
    fileclose(*f1);
    80004616:	853e                	mv	a0,a5
    80004618:	c8dff0ef          	jal	ra,800042a4 <fileclose>
  return -1;
    8000461c:	557d                	li	a0,-1
}
    8000461e:	70a2                	ld	ra,40(sp)
    80004620:	7402                	ld	s0,32(sp)
    80004622:	64e2                	ld	s1,24(sp)
    80004624:	6942                	ld	s2,16(sp)
    80004626:	69a2                	ld	s3,8(sp)
    80004628:	6a02                	ld	s4,0(sp)
    8000462a:	6145                	addi	sp,sp,48
    8000462c:	8082                	ret
  return -1;
    8000462e:	557d                	li	a0,-1
    80004630:	b7fd                	j	8000461e <pipealloc+0xae>

0000000080004632 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004632:	1101                	addi	sp,sp,-32
    80004634:	ec06                	sd	ra,24(sp)
    80004636:	e822                	sd	s0,16(sp)
    80004638:	e426                	sd	s1,8(sp)
    8000463a:	e04a                	sd	s2,0(sp)
    8000463c:	1000                	addi	s0,sp,32
    8000463e:	84aa                	mv	s1,a0
    80004640:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004642:	eacfc0ef          	jal	ra,80000cee <acquire>
  if(writable){
    80004646:	02090763          	beqz	s2,80004674 <pipeclose+0x42>
    pi->writeopen = 0;
    8000464a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000464e:	21848513          	addi	a0,s1,536
    80004652:	a11fd0ef          	jal	ra,80002062 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004656:	2204b783          	ld	a5,544(s1)
    8000465a:	e785                	bnez	a5,80004682 <pipeclose+0x50>
    release(&pi->lock);
    8000465c:	8526                	mv	a0,s1
    8000465e:	f28fc0ef          	jal	ra,80000d86 <release>
    kfree((char*)pi);
    80004662:	8526                	mv	a0,s1
    80004664:	c44fc0ef          	jal	ra,80000aa8 <kfree>
  } else
    release(&pi->lock);
}
    80004668:	60e2                	ld	ra,24(sp)
    8000466a:	6442                	ld	s0,16(sp)
    8000466c:	64a2                	ld	s1,8(sp)
    8000466e:	6902                	ld	s2,0(sp)
    80004670:	6105                	addi	sp,sp,32
    80004672:	8082                	ret
    pi->readopen = 0;
    80004674:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004678:	21c48513          	addi	a0,s1,540
    8000467c:	9e7fd0ef          	jal	ra,80002062 <wakeup>
    80004680:	bfd9                	j	80004656 <pipeclose+0x24>
    release(&pi->lock);
    80004682:	8526                	mv	a0,s1
    80004684:	f02fc0ef          	jal	ra,80000d86 <release>
}
    80004688:	b7c5                	j	80004668 <pipeclose+0x36>

000000008000468a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000468a:	711d                	addi	sp,sp,-96
    8000468c:	ec86                	sd	ra,88(sp)
    8000468e:	e8a2                	sd	s0,80(sp)
    80004690:	e4a6                	sd	s1,72(sp)
    80004692:	e0ca                	sd	s2,64(sp)
    80004694:	fc4e                	sd	s3,56(sp)
    80004696:	f852                	sd	s4,48(sp)
    80004698:	f456                	sd	s5,40(sp)
    8000469a:	f05a                	sd	s6,32(sp)
    8000469c:	ec5e                	sd	s7,24(sp)
    8000469e:	e862                	sd	s8,16(sp)
    800046a0:	1080                	addi	s0,sp,96
    800046a2:	84aa                	mv	s1,a0
    800046a4:	8aae                	mv	s5,a1
    800046a6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800046a8:	b5cfd0ef          	jal	ra,80001a04 <myproc>
    800046ac:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800046ae:	8526                	mv	a0,s1
    800046b0:	e3efc0ef          	jal	ra,80000cee <acquire>
  while(i < n){
    800046b4:	09405c63          	blez	s4,8000474c <pipewrite+0xc2>
  int i = 0;
    800046b8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800046ba:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800046bc:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800046c0:	21c48b93          	addi	s7,s1,540
    800046c4:	a81d                	j	800046fa <pipewrite+0x70>
      release(&pi->lock);
    800046c6:	8526                	mv	a0,s1
    800046c8:	ebefc0ef          	jal	ra,80000d86 <release>
      return -1;
    800046cc:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800046ce:	854a                	mv	a0,s2
    800046d0:	60e6                	ld	ra,88(sp)
    800046d2:	6446                	ld	s0,80(sp)
    800046d4:	64a6                	ld	s1,72(sp)
    800046d6:	6906                	ld	s2,64(sp)
    800046d8:	79e2                	ld	s3,56(sp)
    800046da:	7a42                	ld	s4,48(sp)
    800046dc:	7aa2                	ld	s5,40(sp)
    800046de:	7b02                	ld	s6,32(sp)
    800046e0:	6be2                	ld	s7,24(sp)
    800046e2:	6c42                	ld	s8,16(sp)
    800046e4:	6125                	addi	sp,sp,96
    800046e6:	8082                	ret
      wakeup(&pi->nread);
    800046e8:	8562                	mv	a0,s8
    800046ea:	979fd0ef          	jal	ra,80002062 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800046ee:	85a6                	mv	a1,s1
    800046f0:	855e                	mv	a0,s7
    800046f2:	925fd0ef          	jal	ra,80002016 <sleep>
  while(i < n){
    800046f6:	05495c63          	bge	s2,s4,8000474e <pipewrite+0xc4>
    if(pi->readopen == 0 || killed(pr)){
    800046fa:	2204a783          	lw	a5,544(s1)
    800046fe:	d7e1                	beqz	a5,800046c6 <pipewrite+0x3c>
    80004700:	854e                	mv	a0,s3
    80004702:	b4dfd0ef          	jal	ra,8000224e <killed>
    80004706:	f161                	bnez	a0,800046c6 <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004708:	2184a783          	lw	a5,536(s1)
    8000470c:	21c4a703          	lw	a4,540(s1)
    80004710:	2007879b          	addiw	a5,a5,512
    80004714:	fcf70ae3          	beq	a4,a5,800046e8 <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004718:	4685                	li	a3,1
    8000471a:	01590633          	add	a2,s2,s5
    8000471e:	faf40593          	addi	a1,s0,-81
    80004722:	0509b503          	ld	a0,80(s3)
    80004726:	8f2fd0ef          	jal	ra,80001818 <copyin>
    8000472a:	03650263          	beq	a0,s6,8000474e <pipewrite+0xc4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000472e:	21c4a783          	lw	a5,540(s1)
    80004732:	0017871b          	addiw	a4,a5,1
    80004736:	20e4ae23          	sw	a4,540(s1)
    8000473a:	1ff7f793          	andi	a5,a5,511
    8000473e:	97a6                	add	a5,a5,s1
    80004740:	faf44703          	lbu	a4,-81(s0)
    80004744:	00e78c23          	sb	a4,24(a5)
      i++;
    80004748:	2905                	addiw	s2,s2,1
    8000474a:	b775                	j	800046f6 <pipewrite+0x6c>
  int i = 0;
    8000474c:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000474e:	21848513          	addi	a0,s1,536
    80004752:	911fd0ef          	jal	ra,80002062 <wakeup>
  release(&pi->lock);
    80004756:	8526                	mv	a0,s1
    80004758:	e2efc0ef          	jal	ra,80000d86 <release>
  return i;
    8000475c:	bf8d                	j	800046ce <pipewrite+0x44>

000000008000475e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000475e:	715d                	addi	sp,sp,-80
    80004760:	e486                	sd	ra,72(sp)
    80004762:	e0a2                	sd	s0,64(sp)
    80004764:	fc26                	sd	s1,56(sp)
    80004766:	f84a                	sd	s2,48(sp)
    80004768:	f44e                	sd	s3,40(sp)
    8000476a:	f052                	sd	s4,32(sp)
    8000476c:	ec56                	sd	s5,24(sp)
    8000476e:	e85a                	sd	s6,16(sp)
    80004770:	0880                	addi	s0,sp,80
    80004772:	84aa                	mv	s1,a0
    80004774:	892e                	mv	s2,a1
    80004776:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004778:	a8cfd0ef          	jal	ra,80001a04 <myproc>
    8000477c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000477e:	8526                	mv	a0,s1
    80004780:	d6efc0ef          	jal	ra,80000cee <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004784:	2184a703          	lw	a4,536(s1)
    80004788:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000478c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004790:	02f71363          	bne	a4,a5,800047b6 <piperead+0x58>
    80004794:	2244a783          	lw	a5,548(s1)
    80004798:	cf99                	beqz	a5,800047b6 <piperead+0x58>
    if(killed(pr)){
    8000479a:	8552                	mv	a0,s4
    8000479c:	ab3fd0ef          	jal	ra,8000224e <killed>
    800047a0:	e149                	bnez	a0,80004822 <piperead+0xc4>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800047a2:	85a6                	mv	a1,s1
    800047a4:	854e                	mv	a0,s3
    800047a6:	871fd0ef          	jal	ra,80002016 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800047aa:	2184a703          	lw	a4,536(s1)
    800047ae:	21c4a783          	lw	a5,540(s1)
    800047b2:	fef701e3          	beq	a4,a5,80004794 <piperead+0x36>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800047b6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800047b8:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800047ba:	05505263          	blez	s5,800047fe <piperead+0xa0>
    if(pi->nread == pi->nwrite)
    800047be:	2184a783          	lw	a5,536(s1)
    800047c2:	21c4a703          	lw	a4,540(s1)
    800047c6:	02f70c63          	beq	a4,a5,800047fe <piperead+0xa0>
    ch = pi->data[pi->nread % PIPESIZE];
    800047ca:	1ff7f793          	andi	a5,a5,511
    800047ce:	97a6                	add	a5,a5,s1
    800047d0:	0187c783          	lbu	a5,24(a5)
    800047d4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800047d8:	4685                	li	a3,1
    800047da:	fbf40613          	addi	a2,s0,-65
    800047de:	85ca                	mv	a1,s2
    800047e0:	050a3503          	ld	a0,80(s4)
    800047e4:	dd7fc0ef          	jal	ra,800015ba <copyout>
    800047e8:	05650263          	beq	a0,s6,8000482c <piperead+0xce>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    800047ec:	2184a783          	lw	a5,536(s1)
    800047f0:	2785                	addiw	a5,a5,1
    800047f2:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800047f6:	2985                	addiw	s3,s3,1
    800047f8:	0905                	addi	s2,s2,1
    800047fa:	fd3a92e3          	bne	s5,s3,800047be <piperead+0x60>
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800047fe:	21c48513          	addi	a0,s1,540
    80004802:	861fd0ef          	jal	ra,80002062 <wakeup>
  release(&pi->lock);
    80004806:	8526                	mv	a0,s1
    80004808:	d7efc0ef          	jal	ra,80000d86 <release>
  return i;
}
    8000480c:	854e                	mv	a0,s3
    8000480e:	60a6                	ld	ra,72(sp)
    80004810:	6406                	ld	s0,64(sp)
    80004812:	74e2                	ld	s1,56(sp)
    80004814:	7942                	ld	s2,48(sp)
    80004816:	79a2                	ld	s3,40(sp)
    80004818:	7a02                	ld	s4,32(sp)
    8000481a:	6ae2                	ld	s5,24(sp)
    8000481c:	6b42                	ld	s6,16(sp)
    8000481e:	6161                	addi	sp,sp,80
    80004820:	8082                	ret
      release(&pi->lock);
    80004822:	8526                	mv	a0,s1
    80004824:	d62fc0ef          	jal	ra,80000d86 <release>
      return -1;
    80004828:	59fd                	li	s3,-1
    8000482a:	b7cd                	j	8000480c <piperead+0xae>
      if(i == 0)
    8000482c:	fc0999e3          	bnez	s3,800047fe <piperead+0xa0>
        i = -1;
    80004830:	89aa                	mv	s3,a0
    80004832:	b7f1                	j	800047fe <piperead+0xa0>

0000000080004834 <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    80004834:	1141                	addi	sp,sp,-16
    80004836:	e422                	sd	s0,8(sp)
    80004838:	0800                	addi	s0,sp,16
    8000483a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000483c:	8905                	andi	a0,a0,1
    8000483e:	c111                	beqz	a0,80004842 <flags2perm+0xe>
      perm = PTE_X;
    80004840:	4521                	li	a0,8
    if(flags & 0x2)
    80004842:	8b89                	andi	a5,a5,2
    80004844:	c399                	beqz	a5,8000484a <flags2perm+0x16>
      perm |= PTE_W;
    80004846:	00456513          	ori	a0,a0,4
    return perm;
}
    8000484a:	6422                	ld	s0,8(sp)
    8000484c:	0141                	addi	sp,sp,16
    8000484e:	8082                	ret

0000000080004850 <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    80004850:	de010113          	addi	sp,sp,-544
    80004854:	20113c23          	sd	ra,536(sp)
    80004858:	20813823          	sd	s0,528(sp)
    8000485c:	20913423          	sd	s1,520(sp)
    80004860:	21213023          	sd	s2,512(sp)
    80004864:	ffce                	sd	s3,504(sp)
    80004866:	fbd2                	sd	s4,496(sp)
    80004868:	f7d6                	sd	s5,488(sp)
    8000486a:	f3da                	sd	s6,480(sp)
    8000486c:	efde                	sd	s7,472(sp)
    8000486e:	ebe2                	sd	s8,464(sp)
    80004870:	e7e6                	sd	s9,456(sp)
    80004872:	e3ea                	sd	s10,448(sp)
    80004874:	ff6e                	sd	s11,440(sp)
    80004876:	1400                	addi	s0,sp,544
    80004878:	892a                	mv	s2,a0
    8000487a:	dea43423          	sd	a0,-536(s0)
    8000487e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004882:	982fd0ef          	jal	ra,80001a04 <myproc>
    80004886:	84aa                	mv	s1,a0

  begin_op();
    80004888:	e0eff0ef          	jal	ra,80003e96 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    8000488c:	854a                	mv	a0,s2
    8000488e:	c18ff0ef          	jal	ra,80003ca6 <namei>
    80004892:	c13d                	beqz	a0,800048f8 <kexec+0xa8>
    80004894:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004896:	c23fe0ef          	jal	ra,800034b8 <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000489a:	04000713          	li	a4,64
    8000489e:	4681                	li	a3,0
    800048a0:	e5040613          	addi	a2,s0,-432
    800048a4:	4581                	li	a1,0
    800048a6:	8556                	mv	a0,s5
    800048a8:	f9dfe0ef          	jal	ra,80003844 <readi>
    800048ac:	04000793          	li	a5,64
    800048b0:	00f51a63          	bne	a0,a5,800048c4 <kexec+0x74>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    800048b4:	e5042703          	lw	a4,-432(s0)
    800048b8:	464c47b7          	lui	a5,0x464c4
    800048bc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800048c0:	04f70063          	beq	a4,a5,80004900 <kexec+0xb0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800048c4:	8556                	mv	a0,s5
    800048c6:	df9fe0ef          	jal	ra,800036be <iunlockput>
    end_op();
    800048ca:	e3cff0ef          	jal	ra,80003f06 <end_op>
  }
  return -1;
    800048ce:	557d                	li	a0,-1
}
    800048d0:	21813083          	ld	ra,536(sp)
    800048d4:	21013403          	ld	s0,528(sp)
    800048d8:	20813483          	ld	s1,520(sp)
    800048dc:	20013903          	ld	s2,512(sp)
    800048e0:	79fe                	ld	s3,504(sp)
    800048e2:	7a5e                	ld	s4,496(sp)
    800048e4:	7abe                	ld	s5,488(sp)
    800048e6:	7b1e                	ld	s6,480(sp)
    800048e8:	6bfe                	ld	s7,472(sp)
    800048ea:	6c5e                	ld	s8,464(sp)
    800048ec:	6cbe                	ld	s9,456(sp)
    800048ee:	6d1e                	ld	s10,448(sp)
    800048f0:	7dfa                	ld	s11,440(sp)
    800048f2:	22010113          	addi	sp,sp,544
    800048f6:	8082                	ret
    end_op();
    800048f8:	e0eff0ef          	jal	ra,80003f06 <end_op>
    return -1;
    800048fc:	557d                	li	a0,-1
    800048fe:	bfc9                	j	800048d0 <kexec+0x80>
  if((pagetable = proc_pagetable(p)) == 0)
    80004900:	8526                	mv	a0,s1
    80004902:	a08fd0ef          	jal	ra,80001b0a <proc_pagetable>
    80004906:	8b2a                	mv	s6,a0
    80004908:	dd55                	beqz	a0,800048c4 <kexec+0x74>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000490a:	e7042783          	lw	a5,-400(s0)
    8000490e:	e8845703          	lhu	a4,-376(s0)
    80004912:	c325                	beqz	a4,80004972 <kexec+0x122>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004914:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004916:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000491a:	6a05                	lui	s4,0x1
    8000491c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004920:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004924:	6d85                	lui	s11,0x1
    80004926:	7d7d                	lui	s10,0xfffff
    80004928:	a411                	j	80004b2c <kexec+0x2dc>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000492a:	00003517          	auipc	a0,0x3
    8000492e:	f4650513          	addi	a0,a0,-186 # 80007870 <syscalls+0x2c8>
    80004932:	e59fb0ef          	jal	ra,8000078a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004936:	874a                	mv	a4,s2
    80004938:	009c86bb          	addw	a3,s9,s1
    8000493c:	4581                	li	a1,0
    8000493e:	8556                	mv	a0,s5
    80004940:	f05fe0ef          	jal	ra,80003844 <readi>
    80004944:	2501                	sext.w	a0,a0
    80004946:	18a91263          	bne	s2,a0,80004aca <kexec+0x27a>
  for(i = 0; i < sz; i += PGSIZE){
    8000494a:	009d84bb          	addw	s1,s11,s1
    8000494e:	013d09bb          	addw	s3,s10,s3
    80004952:	1b74fd63          	bgeu	s1,s7,80004b0c <kexec+0x2bc>
    pa = walkaddr(pagetable, va + i);
    80004956:	02049593          	slli	a1,s1,0x20
    8000495a:	9181                	srli	a1,a1,0x20
    8000495c:	95e2                	add	a1,a1,s8
    8000495e:	855a                	mv	a0,s6
    80004960:	f78fc0ef          	jal	ra,800010d8 <walkaddr>
    80004964:	862a                	mv	a2,a0
    if(pa == 0)
    80004966:	d171                	beqz	a0,8000492a <kexec+0xda>
      n = PGSIZE;
    80004968:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000496a:	fd49f6e3          	bgeu	s3,s4,80004936 <kexec+0xe6>
      n = sz - i;
    8000496e:	894e                	mv	s2,s3
    80004970:	b7d9                	j	80004936 <kexec+0xe6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004972:	4901                	li	s2,0
  iunlockput(ip);
    80004974:	8556                	mv	a0,s5
    80004976:	d49fe0ef          	jal	ra,800036be <iunlockput>
  end_op();
    8000497a:	d8cff0ef          	jal	ra,80003f06 <end_op>
  p = myproc();
    8000497e:	886fd0ef          	jal	ra,80001a04 <myproc>
    80004982:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004984:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004988:	6785                	lui	a5,0x1
    8000498a:	17fd                	addi	a5,a5,-1
    8000498c:	993e                	add	s2,s2,a5
    8000498e:	77fd                	lui	a5,0xfffff
    80004990:	00f977b3          	and	a5,s2,a5
    80004994:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    80004998:	4691                	li	a3,4
    8000499a:	6609                	lui	a2,0x2
    8000499c:	963e                	add	a2,a2,a5
    8000499e:	85be                	mv	a1,a5
    800049a0:	855a                	mv	a0,s6
    800049a2:	a07fc0ef          	jal	ra,800013a8 <uvmalloc>
    800049a6:	8c2a                	mv	s8,a0
  ip = 0;
    800049a8:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    800049aa:	12050063          	beqz	a0,80004aca <kexec+0x27a>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    800049ae:	75f9                	lui	a1,0xffffe
    800049b0:	95aa                	add	a1,a1,a0
    800049b2:	855a                	mv	a0,s6
    800049b4:	bddfc0ef          	jal	ra,80001590 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    800049b8:	7afd                	lui	s5,0xfffff
    800049ba:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800049bc:	df043783          	ld	a5,-528(s0)
    800049c0:	6388                	ld	a0,0(a5)
    800049c2:	c135                	beqz	a0,80004a26 <kexec+0x1d6>
    800049c4:	e9040993          	addi	s3,s0,-368
    800049c8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800049cc:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800049ce:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800049d0:	d6afc0ef          	jal	ra,80000f3a <strlen>
    800049d4:	0015079b          	addiw	a5,a0,1
    800049d8:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800049dc:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800049e0:	11596a63          	bltu	s2,s5,80004af4 <kexec+0x2a4>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800049e4:	df043d83          	ld	s11,-528(s0)
    800049e8:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800049ec:	8552                	mv	a0,s4
    800049ee:	d4cfc0ef          	jal	ra,80000f3a <strlen>
    800049f2:	0015069b          	addiw	a3,a0,1
    800049f6:	8652                	mv	a2,s4
    800049f8:	85ca                	mv	a1,s2
    800049fa:	855a                	mv	a0,s6
    800049fc:	bbffc0ef          	jal	ra,800015ba <copyout>
    80004a00:	0e054e63          	bltz	a0,80004afc <kexec+0x2ac>
    ustack[argc] = sp;
    80004a04:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004a08:	0485                	addi	s1,s1,1
    80004a0a:	008d8793          	addi	a5,s11,8
    80004a0e:	def43823          	sd	a5,-528(s0)
    80004a12:	008db503          	ld	a0,8(s11)
    80004a16:	c911                	beqz	a0,80004a2a <kexec+0x1da>
    if(argc >= MAXARG)
    80004a18:	09a1                	addi	s3,s3,8
    80004a1a:	fb3c9be3          	bne	s9,s3,800049d0 <kexec+0x180>
  sz = sz1;
    80004a1e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004a22:	4a81                	li	s5,0
    80004a24:	a05d                	j	80004aca <kexec+0x27a>
  sp = sz;
    80004a26:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004a28:	4481                	li	s1,0
  ustack[argc] = 0;
    80004a2a:	00349793          	slli	a5,s1,0x3
    80004a2e:	f9040713          	addi	a4,s0,-112
    80004a32:	97ba                	add	a5,a5,a4
    80004a34:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd6000>
  sp -= (argc+1) * sizeof(uint64);
    80004a38:	00148693          	addi	a3,s1,1
    80004a3c:	068e                	slli	a3,a3,0x3
    80004a3e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004a42:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004a46:	01597663          	bgeu	s2,s5,80004a52 <kexec+0x202>
  sz = sz1;
    80004a4a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004a4e:	4a81                	li	s5,0
    80004a50:	a8ad                	j	80004aca <kexec+0x27a>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004a52:	e9040613          	addi	a2,s0,-368
    80004a56:	85ca                	mv	a1,s2
    80004a58:	855a                	mv	a0,s6
    80004a5a:	b61fc0ef          	jal	ra,800015ba <copyout>
    80004a5e:	0a054363          	bltz	a0,80004b04 <kexec+0x2b4>
  p->trapframe->a1 = sp;
    80004a62:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004a66:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004a6a:	de843783          	ld	a5,-536(s0)
    80004a6e:	0007c703          	lbu	a4,0(a5)
    80004a72:	cf11                	beqz	a4,80004a8e <kexec+0x23e>
    80004a74:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004a76:	02f00693          	li	a3,47
    80004a7a:	a039                	j	80004a88 <kexec+0x238>
      last = s+1;
    80004a7c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004a80:	0785                	addi	a5,a5,1
    80004a82:	fff7c703          	lbu	a4,-1(a5)
    80004a86:	c701                	beqz	a4,80004a8e <kexec+0x23e>
    if(*s == '/')
    80004a88:	fed71ce3          	bne	a4,a3,80004a80 <kexec+0x230>
    80004a8c:	bfc5                	j	80004a7c <kexec+0x22c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004a8e:	4641                	li	a2,16
    80004a90:	de843583          	ld	a1,-536(s0)
    80004a94:	158b8513          	addi	a0,s7,344
    80004a98:	c70fc0ef          	jal	ra,80000f08 <safestrcpy>
  oldpagetable = p->pagetable;
    80004a9c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004aa0:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004aa4:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    80004aa8:	058bb783          	ld	a5,88(s7)
    80004aac:	e6843703          	ld	a4,-408(s0)
    80004ab0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ab2:	058bb783          	ld	a5,88(s7)
    80004ab6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004aba:	85ea                	mv	a1,s10
    80004abc:	8d2fd0ef          	jal	ra,80001b8e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ac0:	0004851b          	sext.w	a0,s1
    80004ac4:	b531                	j	800048d0 <kexec+0x80>
    80004ac6:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004aca:	df843583          	ld	a1,-520(s0)
    80004ace:	855a                	mv	a0,s6
    80004ad0:	8befd0ef          	jal	ra,80001b8e <proc_freepagetable>
  if(ip){
    80004ad4:	de0a98e3          	bnez	s5,800048c4 <kexec+0x74>
  return -1;
    80004ad8:	557d                	li	a0,-1
    80004ada:	bbdd                	j	800048d0 <kexec+0x80>
    80004adc:	df243c23          	sd	s2,-520(s0)
    80004ae0:	b7ed                	j	80004aca <kexec+0x27a>
    80004ae2:	df243c23          	sd	s2,-520(s0)
    80004ae6:	b7d5                	j	80004aca <kexec+0x27a>
    80004ae8:	df243c23          	sd	s2,-520(s0)
    80004aec:	bff9                	j	80004aca <kexec+0x27a>
    80004aee:	df243c23          	sd	s2,-520(s0)
    80004af2:	bfe1                	j	80004aca <kexec+0x27a>
  sz = sz1;
    80004af4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004af8:	4a81                	li	s5,0
    80004afa:	bfc1                	j	80004aca <kexec+0x27a>
  sz = sz1;
    80004afc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004b00:	4a81                	li	s5,0
    80004b02:	b7e1                	j	80004aca <kexec+0x27a>
  sz = sz1;
    80004b04:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004b08:	4a81                	li	s5,0
    80004b0a:	b7c1                	j	80004aca <kexec+0x27a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004b0c:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004b10:	e0843783          	ld	a5,-504(s0)
    80004b14:	0017869b          	addiw	a3,a5,1
    80004b18:	e0d43423          	sd	a3,-504(s0)
    80004b1c:	e0043783          	ld	a5,-512(s0)
    80004b20:	0387879b          	addiw	a5,a5,56
    80004b24:	e8845703          	lhu	a4,-376(s0)
    80004b28:	e4e6d6e3          	bge	a3,a4,80004974 <kexec+0x124>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004b2c:	2781                	sext.w	a5,a5
    80004b2e:	e0f43023          	sd	a5,-512(s0)
    80004b32:	03800713          	li	a4,56
    80004b36:	86be                	mv	a3,a5
    80004b38:	e1840613          	addi	a2,s0,-488
    80004b3c:	4581                	li	a1,0
    80004b3e:	8556                	mv	a0,s5
    80004b40:	d05fe0ef          	jal	ra,80003844 <readi>
    80004b44:	03800793          	li	a5,56
    80004b48:	f6f51fe3          	bne	a0,a5,80004ac6 <kexec+0x276>
    if(ph.type != ELF_PROG_LOAD)
    80004b4c:	e1842783          	lw	a5,-488(s0)
    80004b50:	4705                	li	a4,1
    80004b52:	fae79fe3          	bne	a5,a4,80004b10 <kexec+0x2c0>
    if(ph.memsz < ph.filesz)
    80004b56:	e4043483          	ld	s1,-448(s0)
    80004b5a:	e3843783          	ld	a5,-456(s0)
    80004b5e:	f6f4efe3          	bltu	s1,a5,80004adc <kexec+0x28c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004b62:	e2843783          	ld	a5,-472(s0)
    80004b66:	94be                	add	s1,s1,a5
    80004b68:	f6f4ede3          	bltu	s1,a5,80004ae2 <kexec+0x292>
    if(ph.vaddr % PGSIZE != 0)
    80004b6c:	de043703          	ld	a4,-544(s0)
    80004b70:	8ff9                	and	a5,a5,a4
    80004b72:	fbbd                	bnez	a5,80004ae8 <kexec+0x298>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004b74:	e1c42503          	lw	a0,-484(s0)
    80004b78:	cbdff0ef          	jal	ra,80004834 <flags2perm>
    80004b7c:	86aa                	mv	a3,a0
    80004b7e:	8626                	mv	a2,s1
    80004b80:	85ca                	mv	a1,s2
    80004b82:	855a                	mv	a0,s6
    80004b84:	825fc0ef          	jal	ra,800013a8 <uvmalloc>
    80004b88:	dea43c23          	sd	a0,-520(s0)
    80004b8c:	d12d                	beqz	a0,80004aee <kexec+0x29e>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004b8e:	e2843c03          	ld	s8,-472(s0)
    80004b92:	e2042c83          	lw	s9,-480(s0)
    80004b96:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004b9a:	f60b89e3          	beqz	s7,80004b0c <kexec+0x2bc>
    80004b9e:	89de                	mv	s3,s7
    80004ba0:	4481                	li	s1,0
    80004ba2:	bb55                	j	80004956 <kexec+0x106>

0000000080004ba4 <argfd>:
#include "fcntl.h"

// 获取第n个系统调用参数作为文件描述符，并返回该描述符及对应的文件结构。
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ba4:	7179                	addi	sp,sp,-48
    80004ba6:	f406                	sd	ra,40(sp)
    80004ba8:	f022                	sd	s0,32(sp)
    80004baa:	ec26                	sd	s1,24(sp)
    80004bac:	e84a                	sd	s2,16(sp)
    80004bae:	1800                	addi	s0,sp,48
    80004bb0:	892e                	mv	s2,a1
    80004bb2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);  // 获取系统调用参数中的文件描述符
    80004bb4:	fdc40593          	addi	a1,s0,-36
    80004bb8:	f19fd0ef          	jal	ra,80002ad0 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)  // 检查文件描述符的有效性
    80004bbc:	fdc42703          	lw	a4,-36(s0)
    80004bc0:	47bd                	li	a5,15
    80004bc2:	02e7e963          	bltu	a5,a4,80004bf4 <argfd+0x50>
    80004bc6:	e3ffc0ef          	jal	ra,80001a04 <myproc>
    80004bca:	fdc42703          	lw	a4,-36(s0)
    80004bce:	01a70793          	addi	a5,a4,26
    80004bd2:	078e                	slli	a5,a5,0x3
    80004bd4:	953e                	add	a0,a0,a5
    80004bd6:	611c                	ld	a5,0(a0)
    80004bd8:	c385                	beqz	a5,80004bf8 <argfd+0x54>
    return -1;
  if(pfd)
    80004bda:	00090463          	beqz	s2,80004be2 <argfd+0x3e>
    *pfd = fd;
    80004bde:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004be2:	4501                	li	a0,0
  if(pf)
    80004be4:	c091                	beqz	s1,80004be8 <argfd+0x44>
    *pf = f;
    80004be6:	e09c                	sd	a5,0(s1)
}
    80004be8:	70a2                	ld	ra,40(sp)
    80004bea:	7402                	ld	s0,32(sp)
    80004bec:	64e2                	ld	s1,24(sp)
    80004bee:	6942                	ld	s2,16(sp)
    80004bf0:	6145                	addi	sp,sp,48
    80004bf2:	8082                	ret
    return -1;
    80004bf4:	557d                	li	a0,-1
    80004bf6:	bfcd                	j	80004be8 <argfd+0x44>
    80004bf8:	557d                	li	a0,-1
    80004bfa:	b7fd                	j	80004be8 <argfd+0x44>

0000000080004bfc <fdalloc>:

// 为给定文件分配一个文件描述符。
// 成功时接管调用者的文件引用。
static int
fdalloc(struct file *f)
{
    80004bfc:	1101                	addi	sp,sp,-32
    80004bfe:	ec06                	sd	ra,24(sp)
    80004c00:	e822                	sd	s0,16(sp)
    80004c02:	e426                	sd	s1,8(sp)
    80004c04:	1000                	addi	s0,sp,32
    80004c06:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004c08:	dfdfc0ef          	jal	ra,80001a04 <myproc>
    80004c0c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004c0e:	0d050793          	addi	a5,a0,208
    80004c12:	4501                	li	a0,0
    80004c14:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){  // 查找一个未使用的文件描述符
    80004c16:	6398                	ld	a4,0(a5)
    80004c18:	cb19                	beqz	a4,80004c2e <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004c1a:	2505                	addiw	a0,a0,1
    80004c1c:	07a1                	addi	a5,a5,8
    80004c1e:	fed51ce3          	bne	a0,a3,80004c16 <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;  // 没有可用的文件描述符
    80004c22:	557d                	li	a0,-1
}
    80004c24:	60e2                	ld	ra,24(sp)
    80004c26:	6442                	ld	s0,16(sp)
    80004c28:	64a2                	ld	s1,8(sp)
    80004c2a:	6105                	addi	sp,sp,32
    80004c2c:	8082                	ret
      p->ofile[fd] = f;
    80004c2e:	01a50793          	addi	a5,a0,26
    80004c32:	078e                	slli	a5,a5,0x3
    80004c34:	963e                	add	a2,a2,a5
    80004c36:	e204                	sd	s1,0(a2)
      return fd;
    80004c38:	b7f5                	j	80004c24 <fdalloc+0x28>

0000000080004c3a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004c3a:	715d                	addi	sp,sp,-80
    80004c3c:	e486                	sd	ra,72(sp)
    80004c3e:	e0a2                	sd	s0,64(sp)
    80004c40:	fc26                	sd	s1,56(sp)
    80004c42:	f84a                	sd	s2,48(sp)
    80004c44:	f44e                	sd	s3,40(sp)
    80004c46:	f052                	sd	s4,32(sp)
    80004c48:	ec56                	sd	s5,24(sp)
    80004c4a:	e85a                	sd	s6,16(sp)
    80004c4c:	0880                	addi	s0,sp,80
    80004c4e:	8b2e                	mv	s6,a1
    80004c50:	89b2                	mv	s3,a2
    80004c52:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)  // 查找父目录
    80004c54:	fb040593          	addi	a1,s0,-80
    80004c58:	868ff0ef          	jal	ra,80003cc0 <nameiparent>
    80004c5c:	84aa                	mv	s1,a0
    80004c5e:	10050b63          	beqz	a0,80004d74 <create+0x13a>
    return 0;

  ilock(dp);
    80004c62:	857fe0ef          	jal	ra,800034b8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){  // 检查文件是否已存在
    80004c66:	4601                	li	a2,0
    80004c68:	fb040593          	addi	a1,s0,-80
    80004c6c:	8526                	mv	a0,s1
    80004c6e:	dd3fe0ef          	jal	ra,80003a40 <dirlookup>
    80004c72:	8aaa                	mv	s5,a0
    80004c74:	c521                	beqz	a0,80004cbc <create+0x82>
    iunlockput(dp);
    80004c76:	8526                	mv	a0,s1
    80004c78:	a47fe0ef          	jal	ra,800036be <iunlockput>
    ilock(ip);
    80004c7c:	8556                	mv	a0,s5
    80004c7e:	83bfe0ef          	jal	ra,800034b8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004c82:	000b059b          	sext.w	a1,s6
    80004c86:	4789                	li	a5,2
    80004c88:	02f59563          	bne	a1,a5,80004cb2 <create+0x78>
    80004c8c:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd6144>
    80004c90:	37f9                	addiw	a5,a5,-2
    80004c92:	17c2                	slli	a5,a5,0x30
    80004c94:	93c1                	srli	a5,a5,0x30
    80004c96:	4705                	li	a4,1
    80004c98:	00f76d63          	bltu	a4,a5,80004cb2 <create+0x78>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004c9c:	8556                	mv	a0,s5
    80004c9e:	60a6                	ld	ra,72(sp)
    80004ca0:	6406                	ld	s0,64(sp)
    80004ca2:	74e2                	ld	s1,56(sp)
    80004ca4:	7942                	ld	s2,48(sp)
    80004ca6:	79a2                	ld	s3,40(sp)
    80004ca8:	7a02                	ld	s4,32(sp)
    80004caa:	6ae2                	ld	s5,24(sp)
    80004cac:	6b42                	ld	s6,16(sp)
    80004cae:	6161                	addi	sp,sp,80
    80004cb0:	8082                	ret
    iunlockput(ip);
    80004cb2:	8556                	mv	a0,s5
    80004cb4:	a0bfe0ef          	jal	ra,800036be <iunlockput>
    return 0;
    80004cb8:	4a81                	li	s5,0
    80004cba:	b7cd                	j	80004c9c <create+0x62>
  if((ip = ialloc(dp->dev, type)) == 0){  // 分配 inode
    80004cbc:	85da                	mv	a1,s6
    80004cbe:	4088                	lw	a0,0(s1)
    80004cc0:	e90fe0ef          	jal	ra,80003350 <ialloc>
    80004cc4:	8a2a                	mv	s4,a0
    80004cc6:	cd1d                	beqz	a0,80004d04 <create+0xca>
  ilock(ip);
    80004cc8:	ff0fe0ef          	jal	ra,800034b8 <ilock>
  ip->major = major;
    80004ccc:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004cd0:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004cd4:	4905                	li	s2,1
    80004cd6:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004cda:	8552                	mv	a0,s4
    80004cdc:	f2afe0ef          	jal	ra,80003406 <iupdate>
  if(type == T_DIR){  // 创建 . 和 .. 目录项
    80004ce0:	000b059b          	sext.w	a1,s6
    80004ce4:	03258563          	beq	a1,s2,80004d0e <create+0xd4>
  if(dirlink(dp, name, ip->inum) < 0)
    80004ce8:	004a2603          	lw	a2,4(s4)
    80004cec:	fb040593          	addi	a1,s0,-80
    80004cf0:	8526                	mv	a0,s1
    80004cf2:	f1bfe0ef          	jal	ra,80003c0c <dirlink>
    80004cf6:	06054363          	bltz	a0,80004d5c <create+0x122>
  iunlockput(dp);
    80004cfa:	8526                	mv	a0,s1
    80004cfc:	9c3fe0ef          	jal	ra,800036be <iunlockput>
  return ip;
    80004d00:	8ad2                	mv	s5,s4
    80004d02:	bf69                	j	80004c9c <create+0x62>
    iunlockput(dp);
    80004d04:	8526                	mv	a0,s1
    80004d06:	9b9fe0ef          	jal	ra,800036be <iunlockput>
    return 0;
    80004d0a:	8ad2                	mv	s5,s4
    80004d0c:	bf41                	j	80004c9c <create+0x62>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004d0e:	004a2603          	lw	a2,4(s4)
    80004d12:	00003597          	auipc	a1,0x3
    80004d16:	b7e58593          	addi	a1,a1,-1154 # 80007890 <syscalls+0x2e8>
    80004d1a:	8552                	mv	a0,s4
    80004d1c:	ef1fe0ef          	jal	ra,80003c0c <dirlink>
    80004d20:	02054e63          	bltz	a0,80004d5c <create+0x122>
    80004d24:	40d0                	lw	a2,4(s1)
    80004d26:	00003597          	auipc	a1,0x3
    80004d2a:	b7258593          	addi	a1,a1,-1166 # 80007898 <syscalls+0x2f0>
    80004d2e:	8552                	mv	a0,s4
    80004d30:	eddfe0ef          	jal	ra,80003c0c <dirlink>
    80004d34:	02054463          	bltz	a0,80004d5c <create+0x122>
  if(dirlink(dp, name, ip->inum) < 0)
    80004d38:	004a2603          	lw	a2,4(s4)
    80004d3c:	fb040593          	addi	a1,s0,-80
    80004d40:	8526                	mv	a0,s1
    80004d42:	ecbfe0ef          	jal	ra,80003c0c <dirlink>
    80004d46:	00054b63          	bltz	a0,80004d5c <create+0x122>
    dp->nlink++;  // 更新父目录的链接计数
    80004d4a:	04a4d783          	lhu	a5,74(s1)
    80004d4e:	2785                	addiw	a5,a5,1
    80004d50:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004d54:	8526                	mv	a0,s1
    80004d56:	eb0fe0ef          	jal	ra,80003406 <iupdate>
    80004d5a:	b745                	j	80004cfa <create+0xc0>
  ip->nlink = 0;
    80004d5c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004d60:	8552                	mv	a0,s4
    80004d62:	ea4fe0ef          	jal	ra,80003406 <iupdate>
  iunlockput(ip);
    80004d66:	8552                	mv	a0,s4
    80004d68:	957fe0ef          	jal	ra,800036be <iunlockput>
  iunlockput(dp);
    80004d6c:	8526                	mv	a0,s1
    80004d6e:	951fe0ef          	jal	ra,800036be <iunlockput>
  return 0;
    80004d72:	b72d                	j	80004c9c <create+0x62>
    return 0;
    80004d74:	8aaa                	mv	s5,a0
    80004d76:	b71d                	j	80004c9c <create+0x62>

0000000080004d78 <sys_dup>:
{
    80004d78:	7179                	addi	sp,sp,-48
    80004d7a:	f406                	sd	ra,40(sp)
    80004d7c:	f022                	sd	s0,32(sp)
    80004d7e:	ec26                	sd	s1,24(sp)
    80004d80:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004d82:	fd840613          	addi	a2,s0,-40
    80004d86:	4581                	li	a1,0
    80004d88:	4501                	li	a0,0
    80004d8a:	e1bff0ef          	jal	ra,80004ba4 <argfd>
    return -1;
    80004d8e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004d90:	00054f63          	bltz	a0,80004dae <sys_dup+0x36>
  if((fd=fdalloc(f)) < 0)  // 为文件分配新的文件描述符
    80004d94:	fd843503          	ld	a0,-40(s0)
    80004d98:	e65ff0ef          	jal	ra,80004bfc <fdalloc>
    80004d9c:	84aa                	mv	s1,a0
    return -1;
    80004d9e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)  // 为文件分配新的文件描述符
    80004da0:	00054763          	bltz	a0,80004dae <sys_dup+0x36>
  filedup(f);  // 增加文件引用计数
    80004da4:	fd843503          	ld	a0,-40(s0)
    80004da8:	cb6ff0ef          	jal	ra,8000425e <filedup>
  return fd;
    80004dac:	87a6                	mv	a5,s1
}
    80004dae:	853e                	mv	a0,a5
    80004db0:	70a2                	ld	ra,40(sp)
    80004db2:	7402                	ld	s0,32(sp)
    80004db4:	64e2                	ld	s1,24(sp)
    80004db6:	6145                	addi	sp,sp,48
    80004db8:	8082                	ret

0000000080004dba <sys_read>:
{
    80004dba:	7179                	addi	sp,sp,-48
    80004dbc:	f406                	sd	ra,40(sp)
    80004dbe:	f022                	sd	s0,32(sp)
    80004dc0:	1800                	addi	s0,sp,48
  argaddr(1, &p);  // 获取读取数据的用户空间地址
    80004dc2:	fd840593          	addi	a1,s0,-40
    80004dc6:	4505                	li	a0,1
    80004dc8:	d25fd0ef          	jal	ra,80002aec <argaddr>
  argint(2, &n);  // 获取读取字节数
    80004dcc:	fe440593          	addi	a1,s0,-28
    80004dd0:	4509                	li	a0,2
    80004dd2:	cfffd0ef          	jal	ra,80002ad0 <argint>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004dd6:	fe840613          	addi	a2,s0,-24
    80004dda:	4581                	li	a1,0
    80004ddc:	4501                	li	a0,0
    80004dde:	dc7ff0ef          	jal	ra,80004ba4 <argfd>
    80004de2:	87aa                	mv	a5,a0
    return -1;
    80004de4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004de6:	0007ca63          	bltz	a5,80004dfa <sys_read+0x40>
  return fileread(f, p, n);  // 从文件中读取数据
    80004dea:	fe442603          	lw	a2,-28(s0)
    80004dee:	fd843583          	ld	a1,-40(s0)
    80004df2:	fe843503          	ld	a0,-24(s0)
    80004df6:	db4ff0ef          	jal	ra,800043aa <fileread>
}
    80004dfa:	70a2                	ld	ra,40(sp)
    80004dfc:	7402                	ld	s0,32(sp)
    80004dfe:	6145                	addi	sp,sp,48
    80004e00:	8082                	ret

0000000080004e02 <sys_write>:
{
    80004e02:	7179                	addi	sp,sp,-48
    80004e04:	f406                	sd	ra,40(sp)
    80004e06:	f022                	sd	s0,32(sp)
    80004e08:	1800                	addi	s0,sp,48
  argaddr(1, &p);  // 获取写入数据的用户空间地址
    80004e0a:	fd840593          	addi	a1,s0,-40
    80004e0e:	4505                	li	a0,1
    80004e10:	cddfd0ef          	jal	ra,80002aec <argaddr>
  argint(2, &n);  // 获取写入字节数
    80004e14:	fe440593          	addi	a1,s0,-28
    80004e18:	4509                	li	a0,2
    80004e1a:	cb7fd0ef          	jal	ra,80002ad0 <argint>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004e1e:	fe840613          	addi	a2,s0,-24
    80004e22:	4581                	li	a1,0
    80004e24:	4501                	li	a0,0
    80004e26:	d7fff0ef          	jal	ra,80004ba4 <argfd>
    80004e2a:	87aa                	mv	a5,a0
    return -1;
    80004e2c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004e2e:	0007ca63          	bltz	a5,80004e42 <sys_write+0x40>
  return filewrite(f, p, n);  // 向文件中写入数据
    80004e32:	fe442603          	lw	a2,-28(s0)
    80004e36:	fd843583          	ld	a1,-40(s0)
    80004e3a:	fe843503          	ld	a0,-24(s0)
    80004e3e:	e1aff0ef          	jal	ra,80004458 <filewrite>
}
    80004e42:	70a2                	ld	ra,40(sp)
    80004e44:	7402                	ld	s0,32(sp)
    80004e46:	6145                	addi	sp,sp,48
    80004e48:	8082                	ret

0000000080004e4a <sys_close>:
{
    80004e4a:	1101                	addi	sp,sp,-32
    80004e4c:	ec06                	sd	ra,24(sp)
    80004e4e:	e822                	sd	s0,16(sp)
    80004e50:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)  // 获取文件描述符并返回文件结构
    80004e52:	fe040613          	addi	a2,s0,-32
    80004e56:	fec40593          	addi	a1,s0,-20
    80004e5a:	4501                	li	a0,0
    80004e5c:	d49ff0ef          	jal	ra,80004ba4 <argfd>
    return -1;
    80004e60:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)  // 获取文件描述符并返回文件结构
    80004e62:	02054063          	bltz	a0,80004e82 <sys_close+0x38>
  myproc()->ofile[fd] = 0;  // 关闭文件描述符
    80004e66:	b9ffc0ef          	jal	ra,80001a04 <myproc>
    80004e6a:	fec42783          	lw	a5,-20(s0)
    80004e6e:	07e9                	addi	a5,a5,26
    80004e70:	078e                	slli	a5,a5,0x3
    80004e72:	97aa                	add	a5,a5,a0
    80004e74:	0007b023          	sd	zero,0(a5)
  fileclose(f);  // 关闭文件
    80004e78:	fe043503          	ld	a0,-32(s0)
    80004e7c:	c28ff0ef          	jal	ra,800042a4 <fileclose>
  return 0;
    80004e80:	4781                	li	a5,0
}
    80004e82:	853e                	mv	a0,a5
    80004e84:	60e2                	ld	ra,24(sp)
    80004e86:	6442                	ld	s0,16(sp)
    80004e88:	6105                	addi	sp,sp,32
    80004e8a:	8082                	ret

0000000080004e8c <sys_fstat>:
{
    80004e8c:	1101                	addi	sp,sp,-32
    80004e8e:	ec06                	sd	ra,24(sp)
    80004e90:	e822                	sd	s0,16(sp)
    80004e92:	1000                	addi	s0,sp,32
  argaddr(1, &st);  // 获取 stat 结构体地址
    80004e94:	fe040593          	addi	a1,s0,-32
    80004e98:	4505                	li	a0,1
    80004e9a:	c53fd0ef          	jal	ra,80002aec <argaddr>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004e9e:	fe840613          	addi	a2,s0,-24
    80004ea2:	4581                	li	a1,0
    80004ea4:	4501                	li	a0,0
    80004ea6:	cffff0ef          	jal	ra,80004ba4 <argfd>
    80004eaa:	87aa                	mv	a5,a0
    return -1;
    80004eac:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004eae:	0007c863          	bltz	a5,80004ebe <sys_fstat+0x32>
  return filestat(f, st);  // 获取文件状态信息
    80004eb2:	fe043583          	ld	a1,-32(s0)
    80004eb6:	fe843503          	ld	a0,-24(s0)
    80004eba:	c92ff0ef          	jal	ra,8000434c <filestat>
}
    80004ebe:	60e2                	ld	ra,24(sp)
    80004ec0:	6442                	ld	s0,16(sp)
    80004ec2:	6105                	addi	sp,sp,32
    80004ec4:	8082                	ret

0000000080004ec6 <sys_link>:
{
    80004ec6:	7169                	addi	sp,sp,-304
    80004ec8:	f606                	sd	ra,296(sp)
    80004eca:	f222                	sd	s0,288(sp)
    80004ecc:	ee26                	sd	s1,280(sp)
    80004ece:	ea4a                	sd	s2,272(sp)
    80004ed0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004ed2:	08000613          	li	a2,128
    80004ed6:	ed040593          	addi	a1,s0,-304
    80004eda:	4501                	li	a0,0
    80004edc:	c2dfd0ef          	jal	ra,80002b08 <argstr>
    return -1;
    80004ee0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004ee2:	0c054663          	bltz	a0,80004fae <sys_link+0xe8>
    80004ee6:	08000613          	li	a2,128
    80004eea:	f5040593          	addi	a1,s0,-176
    80004eee:	4505                	li	a0,1
    80004ef0:	c19fd0ef          	jal	ra,80002b08 <argstr>
    return -1;
    80004ef4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004ef6:	0a054c63          	bltz	a0,80004fae <sys_link+0xe8>
  begin_op();
    80004efa:	f9dfe0ef          	jal	ra,80003e96 <begin_op>
  if((ip = namei(old)) == 0){  // 查找 old 路径对应的 inode
    80004efe:	ed040513          	addi	a0,s0,-304
    80004f02:	da5fe0ef          	jal	ra,80003ca6 <namei>
    80004f06:	84aa                	mv	s1,a0
    80004f08:	c525                	beqz	a0,80004f70 <sys_link+0xaa>
  ilock(ip);
    80004f0a:	daefe0ef          	jal	ra,800034b8 <ilock>
  if(ip->type == T_DIR){  // 如果是目录，不能创建链接
    80004f0e:	04449703          	lh	a4,68(s1)
    80004f12:	4785                	li	a5,1
    80004f14:	06f70263          	beq	a4,a5,80004f78 <sys_link+0xb2>
  ip->nlink++;  // 增加链接计数
    80004f18:	04a4d783          	lhu	a5,74(s1)
    80004f1c:	2785                	addiw	a5,a5,1
    80004f1e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004f22:	8526                	mv	a0,s1
    80004f24:	ce2fe0ef          	jal	ra,80003406 <iupdate>
  iunlock(ip);
    80004f28:	8526                	mv	a0,s1
    80004f2a:	e38fe0ef          	jal	ra,80003562 <iunlock>
  if((dp = nameiparent(new, name)) == 0)  // 获取 new 路径的父目录
    80004f2e:	fd040593          	addi	a1,s0,-48
    80004f32:	f5040513          	addi	a0,s0,-176
    80004f36:	d8bfe0ef          	jal	ra,80003cc0 <nameiparent>
    80004f3a:	892a                	mv	s2,a0
    80004f3c:	c921                	beqz	a0,80004f8c <sys_link+0xc6>
  ilock(dp);
    80004f3e:	d7afe0ef          	jal	ra,800034b8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){  // 在父目录中创建新链接
    80004f42:	00092703          	lw	a4,0(s2)
    80004f46:	409c                	lw	a5,0(s1)
    80004f48:	02f71f63          	bne	a4,a5,80004f86 <sys_link+0xc0>
    80004f4c:	40d0                	lw	a2,4(s1)
    80004f4e:	fd040593          	addi	a1,s0,-48
    80004f52:	854a                	mv	a0,s2
    80004f54:	cb9fe0ef          	jal	ra,80003c0c <dirlink>
    80004f58:	02054763          	bltz	a0,80004f86 <sys_link+0xc0>
  iunlockput(dp);
    80004f5c:	854a                	mv	a0,s2
    80004f5e:	f60fe0ef          	jal	ra,800036be <iunlockput>
  iput(ip);
    80004f62:	8526                	mv	a0,s1
    80004f64:	ed2fe0ef          	jal	ra,80003636 <iput>
  end_op();
    80004f68:	f9ffe0ef          	jal	ra,80003f06 <end_op>
  return 0;
    80004f6c:	4781                	li	a5,0
    80004f6e:	a081                	j	80004fae <sys_link+0xe8>
    end_op();
    80004f70:	f97fe0ef          	jal	ra,80003f06 <end_op>
    return -1;
    80004f74:	57fd                	li	a5,-1
    80004f76:	a825                	j	80004fae <sys_link+0xe8>
    iunlockput(ip);
    80004f78:	8526                	mv	a0,s1
    80004f7a:	f44fe0ef          	jal	ra,800036be <iunlockput>
    end_op();
    80004f7e:	f89fe0ef          	jal	ra,80003f06 <end_op>
    return -1;
    80004f82:	57fd                	li	a5,-1
    80004f84:	a02d                	j	80004fae <sys_link+0xe8>
    iunlockput(dp);
    80004f86:	854a                	mv	a0,s2
    80004f88:	f36fe0ef          	jal	ra,800036be <iunlockput>
  ilock(ip);
    80004f8c:	8526                	mv	a0,s1
    80004f8e:	d2afe0ef          	jal	ra,800034b8 <ilock>
  ip->nlink--;  // 发生错误，恢复链接计数
    80004f92:	04a4d783          	lhu	a5,74(s1)
    80004f96:	37fd                	addiw	a5,a5,-1
    80004f98:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004f9c:	8526                	mv	a0,s1
    80004f9e:	c68fe0ef          	jal	ra,80003406 <iupdate>
  iunlockput(ip);
    80004fa2:	8526                	mv	a0,s1
    80004fa4:	f1afe0ef          	jal	ra,800036be <iunlockput>
  end_op();
    80004fa8:	f5ffe0ef          	jal	ra,80003f06 <end_op>
  return -1;
    80004fac:	57fd                	li	a5,-1
}
    80004fae:	853e                	mv	a0,a5
    80004fb0:	70b2                	ld	ra,296(sp)
    80004fb2:	7412                	ld	s0,288(sp)
    80004fb4:	64f2                	ld	s1,280(sp)
    80004fb6:	6952                	ld	s2,272(sp)
    80004fb8:	6155                	addi	sp,sp,304
    80004fba:	8082                	ret

0000000080004fbc <sys_unlink>:
{
    80004fbc:	7151                	addi	sp,sp,-240
    80004fbe:	f586                	sd	ra,232(sp)
    80004fc0:	f1a2                	sd	s0,224(sp)
    80004fc2:	eda6                	sd	s1,216(sp)
    80004fc4:	e9ca                	sd	s2,208(sp)
    80004fc6:	e5ce                	sd	s3,200(sp)
    80004fc8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)  // 获取路径
    80004fca:	08000613          	li	a2,128
    80004fce:	f3040593          	addi	a1,s0,-208
    80004fd2:	4501                	li	a0,0
    80004fd4:	b35fd0ef          	jal	ra,80002b08 <argstr>
    80004fd8:	12054b63          	bltz	a0,8000510e <sys_unlink+0x152>
  begin_op();
    80004fdc:	ebbfe0ef          	jal	ra,80003e96 <begin_op>
  if((dp = nameiparent(path, name)) == 0){  // 查找路径的父目录
    80004fe0:	fb040593          	addi	a1,s0,-80
    80004fe4:	f3040513          	addi	a0,s0,-208
    80004fe8:	cd9fe0ef          	jal	ra,80003cc0 <nameiparent>
    80004fec:	84aa                	mv	s1,a0
    80004fee:	c54d                	beqz	a0,80005098 <sys_unlink+0xdc>
  ilock(dp);
    80004ff0:	cc8fe0ef          	jal	ra,800034b8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004ff4:	00003597          	auipc	a1,0x3
    80004ff8:	89c58593          	addi	a1,a1,-1892 # 80007890 <syscalls+0x2e8>
    80004ffc:	fb040513          	addi	a0,s0,-80
    80005000:	a2bfe0ef          	jal	ra,80003a2a <namecmp>
    80005004:	10050a63          	beqz	a0,80005118 <sys_unlink+0x15c>
    80005008:	00003597          	auipc	a1,0x3
    8000500c:	89058593          	addi	a1,a1,-1904 # 80007898 <syscalls+0x2f0>
    80005010:	fb040513          	addi	a0,s0,-80
    80005014:	a17fe0ef          	jal	ra,80003a2a <namecmp>
    80005018:	10050063          	beqz	a0,80005118 <sys_unlink+0x15c>
  if((ip = dirlookup(dp, name, &off)) == 0)  // 查找目录项
    8000501c:	f2c40613          	addi	a2,s0,-212
    80005020:	fb040593          	addi	a1,s0,-80
    80005024:	8526                	mv	a0,s1
    80005026:	a1bfe0ef          	jal	ra,80003a40 <dirlookup>
    8000502a:	892a                	mv	s2,a0
    8000502c:	0e050663          	beqz	a0,80005118 <sys_unlink+0x15c>
  ilock(ip);
    80005030:	c88fe0ef          	jal	ra,800034b8 <ilock>
  if(ip->nlink < 1)
    80005034:	04a91783          	lh	a5,74(s2)
    80005038:	06f05463          	blez	a5,800050a0 <sys_unlink+0xe4>
  if(ip->type == T_DIR && !isdirempty(ip)){  // 如果是非空目录，不能删除
    8000503c:	04491703          	lh	a4,68(s2)
    80005040:	4785                	li	a5,1
    80005042:	06f70563          	beq	a4,a5,800050ac <sys_unlink+0xf0>
  memset(&de, 0, sizeof(de));  // 清空目录项
    80005046:	4641                	li	a2,16
    80005048:	4581                	li	a1,0
    8000504a:	fc040513          	addi	a0,s0,-64
    8000504e:	d75fb0ef          	jal	ra,80000dc2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))  // 删除目录项
    80005052:	4741                	li	a4,16
    80005054:	f2c42683          	lw	a3,-212(s0)
    80005058:	fc040613          	addi	a2,s0,-64
    8000505c:	4581                	li	a1,0
    8000505e:	8526                	mv	a0,s1
    80005060:	8c9fe0ef          	jal	ra,80003928 <writei>
    80005064:	47c1                	li	a5,16
    80005066:	08f51563          	bne	a0,a5,800050f0 <sys_unlink+0x134>
  if(ip->type == T_DIR){
    8000506a:	04491703          	lh	a4,68(s2)
    8000506e:	4785                	li	a5,1
    80005070:	08f70663          	beq	a4,a5,800050fc <sys_unlink+0x140>
  iunlockput(dp);
    80005074:	8526                	mv	a0,s1
    80005076:	e48fe0ef          	jal	ra,800036be <iunlockput>
  ip->nlink--;  // 更新目标文件的链接计数
    8000507a:	04a95783          	lhu	a5,74(s2)
    8000507e:	37fd                	addiw	a5,a5,-1
    80005080:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005084:	854a                	mv	a0,s2
    80005086:	b80fe0ef          	jal	ra,80003406 <iupdate>
  iunlockput(ip);
    8000508a:	854a                	mv	a0,s2
    8000508c:	e32fe0ef          	jal	ra,800036be <iunlockput>
  end_op();
    80005090:	e77fe0ef          	jal	ra,80003f06 <end_op>
  return 0;
    80005094:	4501                	li	a0,0
    80005096:	a079                	j	80005124 <sys_unlink+0x168>
    end_op();
    80005098:	e6ffe0ef          	jal	ra,80003f06 <end_op>
    return -1;
    8000509c:	557d                	li	a0,-1
    8000509e:	a059                	j	80005124 <sys_unlink+0x168>
    panic("unlink: nlink < 1");  // 检查链接计数
    800050a0:	00003517          	auipc	a0,0x3
    800050a4:	80050513          	addi	a0,a0,-2048 # 800078a0 <syscalls+0x2f8>
    800050a8:	ee2fb0ef          	jal	ra,8000078a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){  // 跳过 "." 和 ".."
    800050ac:	04c92703          	lw	a4,76(s2)
    800050b0:	02000793          	li	a5,32
    800050b4:	f8e7f9e3          	bgeu	a5,a4,80005046 <sys_unlink+0x8a>
    800050b8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800050bc:	4741                	li	a4,16
    800050be:	86ce                	mv	a3,s3
    800050c0:	f1840613          	addi	a2,s0,-232
    800050c4:	4581                	li	a1,0
    800050c6:	854a                	mv	a0,s2
    800050c8:	f7cfe0ef          	jal	ra,80003844 <readi>
    800050cc:	47c1                	li	a5,16
    800050ce:	00f51b63          	bne	a0,a5,800050e4 <sys_unlink+0x128>
    if(de.inum != 0)  // 如果目录项不为空
    800050d2:	f1845783          	lhu	a5,-232(s0)
    800050d6:	ef95                	bnez	a5,80005112 <sys_unlink+0x156>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){  // 跳过 "." 和 ".."
    800050d8:	29c1                	addiw	s3,s3,16
    800050da:	04c92783          	lw	a5,76(s2)
    800050de:	fcf9efe3          	bltu	s3,a5,800050bc <sys_unlink+0x100>
    800050e2:	b795                	j	80005046 <sys_unlink+0x8a>
      panic("isdirempty: readi");
    800050e4:	00002517          	auipc	a0,0x2
    800050e8:	7d450513          	addi	a0,a0,2004 # 800078b8 <syscalls+0x310>
    800050ec:	e9efb0ef          	jal	ra,8000078a <panic>
    panic("unlink: writei");
    800050f0:	00002517          	auipc	a0,0x2
    800050f4:	7e050513          	addi	a0,a0,2016 # 800078d0 <syscalls+0x328>
    800050f8:	e92fb0ef          	jal	ra,8000078a <panic>
    dp->nlink--;  // 更新父目录的链接计数
    800050fc:	04a4d783          	lhu	a5,74(s1)
    80005100:	37fd                	addiw	a5,a5,-1
    80005102:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005106:	8526                	mv	a0,s1
    80005108:	afefe0ef          	jal	ra,80003406 <iupdate>
    8000510c:	b7a5                	j	80005074 <sys_unlink+0xb8>
    return -1;
    8000510e:	557d                	li	a0,-1
    80005110:	a811                	j	80005124 <sys_unlink+0x168>
    iunlockput(ip);
    80005112:	854a                	mv	a0,s2
    80005114:	daafe0ef          	jal	ra,800036be <iunlockput>
  iunlockput(dp);
    80005118:	8526                	mv	a0,s1
    8000511a:	da4fe0ef          	jal	ra,800036be <iunlockput>
  end_op();
    8000511e:	de9fe0ef          	jal	ra,80003f06 <end_op>
  return -1;
    80005122:	557d                	li	a0,-1
}
    80005124:	70ae                	ld	ra,232(sp)
    80005126:	740e                	ld	s0,224(sp)
    80005128:	64ee                	ld	s1,216(sp)
    8000512a:	694e                	ld	s2,208(sp)
    8000512c:	69ae                	ld	s3,200(sp)
    8000512e:	616d                	addi	sp,sp,240
    80005130:	8082                	ret

0000000080005132 <sys_open>:

uint64
sys_open(void)
{
    80005132:	7131                	addi	sp,sp,-192
    80005134:	fd06                	sd	ra,184(sp)
    80005136:	f922                	sd	s0,176(sp)
    80005138:	f526                	sd	s1,168(sp)
    8000513a:	f14a                	sd	s2,160(sp)
    8000513c:	ed4e                	sd	s3,152(sp)
    8000513e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);  // 获取打开文件的模式
    80005140:	f4c40593          	addi	a1,s0,-180
    80005144:	4505                	li	a0,1
    80005146:	98bfd0ef          	jal	ra,80002ad0 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)  // 获取路径
    8000514a:	08000613          	li	a2,128
    8000514e:	f5040593          	addi	a1,s0,-176
    80005152:	4501                	li	a0,0
    80005154:	9b5fd0ef          	jal	ra,80002b08 <argstr>
    80005158:	87aa                	mv	a5,a0
    return -1;
    8000515a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)  // 获取路径
    8000515c:	0807cd63          	bltz	a5,800051f6 <sys_open+0xc4>

  begin_op();
    80005160:	d37fe0ef          	jal	ra,80003e96 <begin_op>

  if(omode & O_CREATE){  // 如果是创建文件
    80005164:	f4c42783          	lw	a5,-180(s0)
    80005168:	2007f793          	andi	a5,a5,512
    8000516c:	c3c5                	beqz	a5,8000520c <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    8000516e:	4681                	li	a3,0
    80005170:	4601                	li	a2,0
    80005172:	4589                	li	a1,2
    80005174:	f5040513          	addi	a0,s0,-176
    80005178:	ac3ff0ef          	jal	ra,80004c3a <create>
    8000517c:	84aa                	mv	s1,a0
    if(ip == 0){
    8000517e:	c159                	beqz	a0,80005204 <sys_open+0xd2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005180:	04449703          	lh	a4,68(s1)
    80005184:	478d                	li	a5,3
    80005186:	00f71763          	bne	a4,a5,80005194 <sys_open+0x62>
    8000518a:	0464d703          	lhu	a4,70(s1)
    8000518e:	47a5                	li	a5,9
    80005190:	0ae7e963          	bltu	a5,a4,80005242 <sys_open+0x110>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){  // 分配文件描述符
    80005194:	86cff0ef          	jal	ra,80004200 <filealloc>
    80005198:	89aa                	mv	s3,a0
    8000519a:	0c050963          	beqz	a0,8000526c <sys_open+0x13a>
    8000519e:	a5fff0ef          	jal	ra,80004bfc <fdalloc>
    800051a2:	892a                	mv	s2,a0
    800051a4:	0c054163          	bltz	a0,80005266 <sys_open+0x134>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800051a8:	04449703          	lh	a4,68(s1)
    800051ac:	478d                	li	a5,3
    800051ae:	0af70163          	beq	a4,a5,80005250 <sys_open+0x11e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800051b2:	4789                	li	a5,2
    800051b4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800051b8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800051bc:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800051c0:	f4c42783          	lw	a5,-180(s0)
    800051c4:	0017c713          	xori	a4,a5,1
    800051c8:	8b05                	andi	a4,a4,1
    800051ca:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800051ce:	0037f713          	andi	a4,a5,3
    800051d2:	00e03733          	snez	a4,a4
    800051d6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){  // 如果是 O_TRUNC 模式，截断文件
    800051da:	4007f793          	andi	a5,a5,1024
    800051de:	c791                	beqz	a5,800051ea <sys_open+0xb8>
    800051e0:	04449703          	lh	a4,68(s1)
    800051e4:	4789                	li	a5,2
    800051e6:	06f70c63          	beq	a4,a5,8000525e <sys_open+0x12c>
    itrunc(ip);
  }

  iunlock(ip);
    800051ea:	8526                	mv	a0,s1
    800051ec:	b76fe0ef          	jal	ra,80003562 <iunlock>
  end_op();
    800051f0:	d17fe0ef          	jal	ra,80003f06 <end_op>

  return fd;
    800051f4:	854a                	mv	a0,s2
}
    800051f6:	70ea                	ld	ra,184(sp)
    800051f8:	744a                	ld	s0,176(sp)
    800051fa:	74aa                	ld	s1,168(sp)
    800051fc:	790a                	ld	s2,160(sp)
    800051fe:	69ea                	ld	s3,152(sp)
    80005200:	6129                	addi	sp,sp,192
    80005202:	8082                	ret
      end_op();
    80005204:	d03fe0ef          	jal	ra,80003f06 <end_op>
      return -1;
    80005208:	557d                	li	a0,-1
    8000520a:	b7f5                	j	800051f6 <sys_open+0xc4>
    if((ip = namei(path)) == 0){
    8000520c:	f5040513          	addi	a0,s0,-176
    80005210:	a97fe0ef          	jal	ra,80003ca6 <namei>
    80005214:	84aa                	mv	s1,a0
    80005216:	c115                	beqz	a0,8000523a <sys_open+0x108>
    ilock(ip);
    80005218:	aa0fe0ef          	jal	ra,800034b8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){  // 不能用非读模式打开目录
    8000521c:	04449703          	lh	a4,68(s1)
    80005220:	4785                	li	a5,1
    80005222:	f4f71fe3          	bne	a4,a5,80005180 <sys_open+0x4e>
    80005226:	f4c42783          	lw	a5,-180(s0)
    8000522a:	d7ad                	beqz	a5,80005194 <sys_open+0x62>
      iunlockput(ip);
    8000522c:	8526                	mv	a0,s1
    8000522e:	c90fe0ef          	jal	ra,800036be <iunlockput>
      end_op();
    80005232:	cd5fe0ef          	jal	ra,80003f06 <end_op>
      return -1;
    80005236:	557d                	li	a0,-1
    80005238:	bf7d                	j	800051f6 <sys_open+0xc4>
      end_op();
    8000523a:	ccdfe0ef          	jal	ra,80003f06 <end_op>
      return -1;
    8000523e:	557d                	li	a0,-1
    80005240:	bf5d                	j	800051f6 <sys_open+0xc4>
    iunlockput(ip);
    80005242:	8526                	mv	a0,s1
    80005244:	c7afe0ef          	jal	ra,800036be <iunlockput>
    end_op();
    80005248:	cbffe0ef          	jal	ra,80003f06 <end_op>
    return -1;
    8000524c:	557d                	li	a0,-1
    8000524e:	b765                	j	800051f6 <sys_open+0xc4>
    f->type = FD_DEVICE;
    80005250:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005254:	04649783          	lh	a5,70(s1)
    80005258:	02f99223          	sh	a5,36(s3)
    8000525c:	b785                	j	800051bc <sys_open+0x8a>
    itrunc(ip);
    8000525e:	8526                	mv	a0,s1
    80005260:	b42fe0ef          	jal	ra,800035a2 <itrunc>
    80005264:	b759                	j	800051ea <sys_open+0xb8>
      fileclose(f);
    80005266:	854e                	mv	a0,s3
    80005268:	83cff0ef          	jal	ra,800042a4 <fileclose>
    iunlockput(ip);
    8000526c:	8526                	mv	a0,s1
    8000526e:	c50fe0ef          	jal	ra,800036be <iunlockput>
    end_op();
    80005272:	c95fe0ef          	jal	ra,80003f06 <end_op>
    return -1;
    80005276:	557d                	li	a0,-1
    80005278:	bfbd                	j	800051f6 <sys_open+0xc4>

000000008000527a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000527a:	7175                	addi	sp,sp,-144
    8000527c:	e506                	sd	ra,136(sp)
    8000527e:	e122                	sd	s0,128(sp)
    80005280:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005282:	c15fe0ef          	jal	ra,80003e96 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005286:	08000613          	li	a2,128
    8000528a:	f7040593          	addi	a1,s0,-144
    8000528e:	4501                	li	a0,0
    80005290:	879fd0ef          	jal	ra,80002b08 <argstr>
    80005294:	02054363          	bltz	a0,800052ba <sys_mkdir+0x40>
    80005298:	4681                	li	a3,0
    8000529a:	4601                	li	a2,0
    8000529c:	4585                	li	a1,1
    8000529e:	f7040513          	addi	a0,s0,-144
    800052a2:	999ff0ef          	jal	ra,80004c3a <create>
    800052a6:	c911                	beqz	a0,800052ba <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800052a8:	c16fe0ef          	jal	ra,800036be <iunlockput>
  end_op();
    800052ac:	c5bfe0ef          	jal	ra,80003f06 <end_op>
  return 0;
    800052b0:	4501                	li	a0,0
}
    800052b2:	60aa                	ld	ra,136(sp)
    800052b4:	640a                	ld	s0,128(sp)
    800052b6:	6149                	addi	sp,sp,144
    800052b8:	8082                	ret
    end_op();
    800052ba:	c4dfe0ef          	jal	ra,80003f06 <end_op>
    return -1;
    800052be:	557d                	li	a0,-1
    800052c0:	bfcd                	j	800052b2 <sys_mkdir+0x38>

00000000800052c2 <sys_mknod>:

uint64
sys_mknod(void)
{
    800052c2:	7135                	addi	sp,sp,-160
    800052c4:	ed06                	sd	ra,152(sp)
    800052c6:	e922                	sd	s0,144(sp)
    800052c8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800052ca:	bcdfe0ef          	jal	ra,80003e96 <begin_op>
  argint(1, &major);
    800052ce:	f6c40593          	addi	a1,s0,-148
    800052d2:	4505                	li	a0,1
    800052d4:	ffcfd0ef          	jal	ra,80002ad0 <argint>
  argint(2, &minor);
    800052d8:	f6840593          	addi	a1,s0,-152
    800052dc:	4509                	li	a0,2
    800052de:	ff2fd0ef          	jal	ra,80002ad0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800052e2:	08000613          	li	a2,128
    800052e6:	f7040593          	addi	a1,s0,-144
    800052ea:	4501                	li	a0,0
    800052ec:	81dfd0ef          	jal	ra,80002b08 <argstr>
    800052f0:	02054563          	bltz	a0,8000531a <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800052f4:	f6841683          	lh	a3,-152(s0)
    800052f8:	f6c41603          	lh	a2,-148(s0)
    800052fc:	458d                	li	a1,3
    800052fe:	f7040513          	addi	a0,s0,-144
    80005302:	939ff0ef          	jal	ra,80004c3a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005306:	c911                	beqz	a0,8000531a <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005308:	bb6fe0ef          	jal	ra,800036be <iunlockput>
  end_op();
    8000530c:	bfbfe0ef          	jal	ra,80003f06 <end_op>
  return 0;
    80005310:	4501                	li	a0,0
}
    80005312:	60ea                	ld	ra,152(sp)
    80005314:	644a                	ld	s0,144(sp)
    80005316:	610d                	addi	sp,sp,160
    80005318:	8082                	ret
    end_op();
    8000531a:	bedfe0ef          	jal	ra,80003f06 <end_op>
    return -1;
    8000531e:	557d                	li	a0,-1
    80005320:	bfcd                	j	80005312 <sys_mknod+0x50>

0000000080005322 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005322:	7135                	addi	sp,sp,-160
    80005324:	ed06                	sd	ra,152(sp)
    80005326:	e922                	sd	s0,144(sp)
    80005328:	e526                	sd	s1,136(sp)
    8000532a:	e14a                	sd	s2,128(sp)
    8000532c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000532e:	ed6fc0ef          	jal	ra,80001a04 <myproc>
    80005332:	892a                	mv	s2,a0
  
  begin_op();
    80005334:	b63fe0ef          	jal	ra,80003e96 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005338:	08000613          	li	a2,128
    8000533c:	f6040593          	addi	a1,s0,-160
    80005340:	4501                	li	a0,0
    80005342:	fc6fd0ef          	jal	ra,80002b08 <argstr>
    80005346:	04054163          	bltz	a0,80005388 <sys_chdir+0x66>
    8000534a:	f6040513          	addi	a0,s0,-160
    8000534e:	959fe0ef          	jal	ra,80003ca6 <namei>
    80005352:	84aa                	mv	s1,a0
    80005354:	c915                	beqz	a0,80005388 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    80005356:	962fe0ef          	jal	ra,800034b8 <ilock>
  if(ip->type != T_DIR){  // 必须是目录类型
    8000535a:	04449703          	lh	a4,68(s1)
    8000535e:	4785                	li	a5,1
    80005360:	02f71863          	bne	a4,a5,80005390 <sys_chdir+0x6e>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005364:	8526                	mv	a0,s1
    80005366:	9fcfe0ef          	jal	ra,80003562 <iunlock>
  iput(p->cwd);  // 释放当前工作目录
    8000536a:	15093503          	ld	a0,336(s2)
    8000536e:	ac8fe0ef          	jal	ra,80003636 <iput>
  end_op();
    80005372:	b95fe0ef          	jal	ra,80003f06 <end_op>
  p->cwd = ip;  // 更新为新的工作目录
    80005376:	14993823          	sd	s1,336(s2)
  return 0;
    8000537a:	4501                	li	a0,0
}
    8000537c:	60ea                	ld	ra,152(sp)
    8000537e:	644a                	ld	s0,144(sp)
    80005380:	64aa                	ld	s1,136(sp)
    80005382:	690a                	ld	s2,128(sp)
    80005384:	610d                	addi	sp,sp,160
    80005386:	8082                	ret
    end_op();
    80005388:	b7ffe0ef          	jal	ra,80003f06 <end_op>
    return -1;
    8000538c:	557d                	li	a0,-1
    8000538e:	b7fd                	j	8000537c <sys_chdir+0x5a>
    iunlockput(ip);
    80005390:	8526                	mv	a0,s1
    80005392:	b2cfe0ef          	jal	ra,800036be <iunlockput>
    end_op();
    80005396:	b71fe0ef          	jal	ra,80003f06 <end_op>
    return -1;
    8000539a:	557d                	li	a0,-1
    8000539c:	b7c5                	j	8000537c <sys_chdir+0x5a>

000000008000539e <sys_exec>:

uint64
sys_exec(void)
{
    8000539e:	7145                	addi	sp,sp,-464
    800053a0:	e786                	sd	ra,456(sp)
    800053a2:	e3a2                	sd	s0,448(sp)
    800053a4:	ff26                	sd	s1,440(sp)
    800053a6:	fb4a                	sd	s2,432(sp)
    800053a8:	f74e                	sd	s3,424(sp)
    800053aa:	f352                	sd	s4,416(sp)
    800053ac:	ef56                	sd	s5,408(sp)
    800053ae:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);  // 获取参数地址
    800053b0:	e3840593          	addi	a1,s0,-456
    800053b4:	4505                	li	a0,1
    800053b6:	f36fd0ef          	jal	ra,80002aec <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {  // 获取程序路径
    800053ba:	08000613          	li	a2,128
    800053be:	f4040593          	addi	a1,s0,-192
    800053c2:	4501                	li	a0,0
    800053c4:	f44fd0ef          	jal	ra,80002b08 <argstr>
    800053c8:	87aa                	mv	a5,a0
    return -1;
    800053ca:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {  // 获取程序路径
    800053cc:	0a07c463          	bltz	a5,80005474 <sys_exec+0xd6>
  }
  memset(argv, 0, sizeof(argv));
    800053d0:	10000613          	li	a2,256
    800053d4:	4581                	li	a1,0
    800053d6:	e4040513          	addi	a0,s0,-448
    800053da:	9e9fb0ef          	jal	ra,80000dc2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800053de:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800053e2:	89a6                	mv	s3,s1
    800053e4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800053e6:	02000a13          	li	s4,32
    800053ea:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800053ee:	00391793          	slli	a5,s2,0x3
    800053f2:	e3040593          	addi	a1,s0,-464
    800053f6:	e3843503          	ld	a0,-456(s0)
    800053fa:	953e                	add	a0,a0,a5
    800053fc:	e4afd0ef          	jal	ra,80002a46 <fetchaddr>
    80005400:	02054663          	bltz	a0,8000542c <sys_exec+0x8e>
      goto bad;
    }
    if(uarg == 0){
    80005404:	e3043783          	ld	a5,-464(s0)
    80005408:	cf8d                	beqz	a5,80005442 <sys_exec+0xa4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000540a:	fe4fb0ef          	jal	ra,80000bee <kalloc>
    8000540e:	85aa                	mv	a1,a0
    80005410:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005414:	cd01                	beqz	a0,8000542c <sys_exec+0x8e>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005416:	6605                	lui	a2,0x1
    80005418:	e3043503          	ld	a0,-464(s0)
    8000541c:	e74fd0ef          	jal	ra,80002a90 <fetchstr>
    80005420:	00054663          	bltz	a0,8000542c <sys_exec+0x8e>
    if(i >= NELEM(argv)){
    80005424:	0905                	addi	s2,s2,1
    80005426:	09a1                	addi	s3,s3,8
    80005428:	fd4911e3          	bne	s2,s4,800053ea <sys_exec+0x4c>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000542c:	10048913          	addi	s2,s1,256
    80005430:	6088                	ld	a0,0(s1)
    80005432:	c121                	beqz	a0,80005472 <sys_exec+0xd4>
    kfree(argv[i]);
    80005434:	e74fb0ef          	jal	ra,80000aa8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005438:	04a1                	addi	s1,s1,8
    8000543a:	ff249be3          	bne	s1,s2,80005430 <sys_exec+0x92>
  return -1;
    8000543e:	557d                	li	a0,-1
    80005440:	a815                	j	80005474 <sys_exec+0xd6>
      argv[i] = 0;
    80005442:	0a8e                	slli	s5,s5,0x3
    80005444:	fc040793          	addi	a5,s0,-64
    80005448:	9abe                	add	s5,s5,a5
    8000544a:	e80ab023          	sd	zero,-384(s5)
  int ret = kexec(path, argv);  // 执行程序
    8000544e:	e4040593          	addi	a1,s0,-448
    80005452:	f4040513          	addi	a0,s0,-192
    80005456:	bfaff0ef          	jal	ra,80004850 <kexec>
    8000545a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000545c:	10048993          	addi	s3,s1,256
    80005460:	6088                	ld	a0,0(s1)
    80005462:	c511                	beqz	a0,8000546e <sys_exec+0xd0>
    kfree(argv[i]);
    80005464:	e44fb0ef          	jal	ra,80000aa8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005468:	04a1                	addi	s1,s1,8
    8000546a:	ff349be3          	bne	s1,s3,80005460 <sys_exec+0xc2>
  return ret;
    8000546e:	854a                	mv	a0,s2
    80005470:	a011                	j	80005474 <sys_exec+0xd6>
  return -1;
    80005472:	557d                	li	a0,-1
}
    80005474:	60be                	ld	ra,456(sp)
    80005476:	641e                	ld	s0,448(sp)
    80005478:	74fa                	ld	s1,440(sp)
    8000547a:	795a                	ld	s2,432(sp)
    8000547c:	79ba                	ld	s3,424(sp)
    8000547e:	7a1a                	ld	s4,416(sp)
    80005480:	6afa                	ld	s5,408(sp)
    80005482:	6179                	addi	sp,sp,464
    80005484:	8082                	ret

0000000080005486 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005486:	7139                	addi	sp,sp,-64
    80005488:	fc06                	sd	ra,56(sp)
    8000548a:	f822                	sd	s0,48(sp)
    8000548c:	f426                	sd	s1,40(sp)
    8000548e:	0080                	addi	s0,sp,64
  uint64 fdarray; // 用户指针指向两个整数的数组
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005490:	d74fc0ef          	jal	ra,80001a04 <myproc>
    80005494:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);  // 获取文件描述符数组地址
    80005496:	fd840593          	addi	a1,s0,-40
    8000549a:	4501                	li	a0,0
    8000549c:	e50fd0ef          	jal	ra,80002aec <argaddr>
  if(pipealloc(&rf, &wf) < 0)  // 分配管道文件
    800054a0:	fc840593          	addi	a1,s0,-56
    800054a4:	fd040513          	addi	a0,s0,-48
    800054a8:	8c8ff0ef          	jal	ra,80004570 <pipealloc>
    return -1;
    800054ac:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)  // 分配管道文件
    800054ae:	0a054463          	bltz	a0,80005556 <sys_pipe+0xd0>
  fd0 = -1;
    800054b2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){  // 分配文件描述符
    800054b6:	fd043503          	ld	a0,-48(s0)
    800054ba:	f42ff0ef          	jal	ra,80004bfc <fdalloc>
    800054be:	fca42223          	sw	a0,-60(s0)
    800054c2:	08054163          	bltz	a0,80005544 <sys_pipe+0xbe>
    800054c6:	fc843503          	ld	a0,-56(s0)
    800054ca:	f32ff0ef          	jal	ra,80004bfc <fdalloc>
    800054ce:	fca42023          	sw	a0,-64(s0)
    800054d2:	06054063          	bltz	a0,80005532 <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||  // 将文件描述符写入用户空间
    800054d6:	4691                	li	a3,4
    800054d8:	fc440613          	addi	a2,s0,-60
    800054dc:	fd843583          	ld	a1,-40(s0)
    800054e0:	68a8                	ld	a0,80(s1)
    800054e2:	8d8fc0ef          	jal	ra,800015ba <copyout>
    800054e6:	00054e63          	bltz	a0,80005502 <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800054ea:	4691                	li	a3,4
    800054ec:	fc040613          	addi	a2,s0,-64
    800054f0:	fd843583          	ld	a1,-40(s0)
    800054f4:	0591                	addi	a1,a1,4
    800054f6:	68a8                	ld	a0,80(s1)
    800054f8:	8c2fc0ef          	jal	ra,800015ba <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800054fc:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||  // 将文件描述符写入用户空间
    800054fe:	04055c63          	bgez	a0,80005556 <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    80005502:	fc442783          	lw	a5,-60(s0)
    80005506:	07e9                	addi	a5,a5,26
    80005508:	078e                	slli	a5,a5,0x3
    8000550a:	97a6                	add	a5,a5,s1
    8000550c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005510:	fc042503          	lw	a0,-64(s0)
    80005514:	0569                	addi	a0,a0,26
    80005516:	050e                	slli	a0,a0,0x3
    80005518:	94aa                	add	s1,s1,a0
    8000551a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000551e:	fd043503          	ld	a0,-48(s0)
    80005522:	d83fe0ef          	jal	ra,800042a4 <fileclose>
    fileclose(wf);
    80005526:	fc843503          	ld	a0,-56(s0)
    8000552a:	d7bfe0ef          	jal	ra,800042a4 <fileclose>
    return -1;
    8000552e:	57fd                	li	a5,-1
    80005530:	a01d                	j	80005556 <sys_pipe+0xd0>
    if(fd0 >= 0)
    80005532:	fc442783          	lw	a5,-60(s0)
    80005536:	0007c763          	bltz	a5,80005544 <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    8000553a:	07e9                	addi	a5,a5,26
    8000553c:	078e                	slli	a5,a5,0x3
    8000553e:	94be                	add	s1,s1,a5
    80005540:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005544:	fd043503          	ld	a0,-48(s0)
    80005548:	d5dfe0ef          	jal	ra,800042a4 <fileclose>
    fileclose(wf);
    8000554c:	fc843503          	ld	a0,-56(s0)
    80005550:	d55fe0ef          	jal	ra,800042a4 <fileclose>
    return -1;
    80005554:	57fd                	li	a5,-1
}
    80005556:	853e                	mv	a0,a5
    80005558:	70e2                	ld	ra,56(sp)
    8000555a:	7442                	ld	s0,48(sp)
    8000555c:	74a2                	ld	s1,40(sp)
    8000555e:	6121                	addi	sp,sp,64
    80005560:	8082                	ret
	...

0000000080005570 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    80005570:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    80005572:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    80005574:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80005576:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80005578:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000557a:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000557c:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    8000557e:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80005580:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80005582:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    80005584:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    80005586:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    80005588:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    8000558a:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    8000558c:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    8000558e:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    80005590:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    80005592:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    80005594:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    80005596:	b8efd0ef          	jal	ra,80002924 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    8000559a:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    8000559c:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    8000559e:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800055a0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800055a2:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    800055a4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800055a6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800055a8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800055aa:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800055ac:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800055ae:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800055b0:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800055b2:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    800055b4:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    800055b6:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    800055b8:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    800055ba:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    800055bc:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    800055be:	10200073          	sret
	...

00000000800055ce <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800055ce:	1141                	addi	sp,sp,-16
    800055d0:	e422                	sd	s0,8(sp)
    800055d2:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800055d4:	0c0007b7          	lui	a5,0xc000
    800055d8:	4705                	li	a4,1
    800055da:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800055dc:	c3d8                	sw	a4,4(a5)
}
    800055de:	6422                	ld	s0,8(sp)
    800055e0:	0141                	addi	sp,sp,16
    800055e2:	8082                	ret

00000000800055e4 <plicinithart>:

void
plicinithart(void)
{
    800055e4:	1141                	addi	sp,sp,-16
    800055e6:	e406                	sd	ra,8(sp)
    800055e8:	e022                	sd	s0,0(sp)
    800055ea:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800055ec:	becfc0ef          	jal	ra,800019d8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800055f0:	0085171b          	slliw	a4,a0,0x8
    800055f4:	0c0027b7          	lui	a5,0xc002
    800055f8:	97ba                	add	a5,a5,a4
    800055fa:	40200713          	li	a4,1026
    800055fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005602:	00d5151b          	slliw	a0,a0,0xd
    80005606:	0c2017b7          	lui	a5,0xc201
    8000560a:	953e                	add	a0,a0,a5
    8000560c:	00052023          	sw	zero,0(a0)
}
    80005610:	60a2                	ld	ra,8(sp)
    80005612:	6402                	ld	s0,0(sp)
    80005614:	0141                	addi	sp,sp,16
    80005616:	8082                	ret

0000000080005618 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005618:	1141                	addi	sp,sp,-16
    8000561a:	e406                	sd	ra,8(sp)
    8000561c:	e022                	sd	s0,0(sp)
    8000561e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005620:	bb8fc0ef          	jal	ra,800019d8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005624:	00d5179b          	slliw	a5,a0,0xd
    80005628:	0c201537          	lui	a0,0xc201
    8000562c:	953e                	add	a0,a0,a5
  return irq;
}
    8000562e:	4148                	lw	a0,4(a0)
    80005630:	60a2                	ld	ra,8(sp)
    80005632:	6402                	ld	s0,0(sp)
    80005634:	0141                	addi	sp,sp,16
    80005636:	8082                	ret

0000000080005638 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005638:	1101                	addi	sp,sp,-32
    8000563a:	ec06                	sd	ra,24(sp)
    8000563c:	e822                	sd	s0,16(sp)
    8000563e:	e426                	sd	s1,8(sp)
    80005640:	1000                	addi	s0,sp,32
    80005642:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005644:	b94fc0ef          	jal	ra,800019d8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005648:	00d5151b          	slliw	a0,a0,0xd
    8000564c:	0c2017b7          	lui	a5,0xc201
    80005650:	97aa                	add	a5,a5,a0
    80005652:	c3c4                	sw	s1,4(a5)
}
    80005654:	60e2                	ld	ra,24(sp)
    80005656:	6442                	ld	s0,16(sp)
    80005658:	64a2                	ld	s1,8(sp)
    8000565a:	6105                	addi	sp,sp,32
    8000565c:	8082                	ret

000000008000565e <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    8000565e:	1141                	addi	sp,sp,-16
    80005660:	e406                	sd	ra,8(sp)
    80005662:	e022                	sd	s0,0(sp)
    80005664:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005666:	479d                	li	a5,7
    80005668:	04a7ca63          	blt	a5,a0,800056bc <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    8000566c:	00023797          	auipc	a5,0x23
    80005670:	75478793          	addi	a5,a5,1876 # 80028dc0 <disk>
    80005674:	97aa                	add	a5,a5,a0
    80005676:	0187c783          	lbu	a5,24(a5)
    8000567a:	e7b9                	bnez	a5,800056c8 <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000567c:	00451613          	slli	a2,a0,0x4
    80005680:	00023797          	auipc	a5,0x23
    80005684:	74078793          	addi	a5,a5,1856 # 80028dc0 <disk>
    80005688:	6394                	ld	a3,0(a5)
    8000568a:	96b2                	add	a3,a3,a2
    8000568c:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005690:	6398                	ld	a4,0(a5)
    80005692:	9732                	add	a4,a4,a2
    80005694:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005698:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    8000569c:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800056a0:	953e                	add	a0,a0,a5
    800056a2:	4785                	li	a5,1
    800056a4:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800056a8:	00023517          	auipc	a0,0x23
    800056ac:	73050513          	addi	a0,a0,1840 # 80028dd8 <disk+0x18>
    800056b0:	9b3fc0ef          	jal	ra,80002062 <wakeup>
}
    800056b4:	60a2                	ld	ra,8(sp)
    800056b6:	6402                	ld	s0,0(sp)
    800056b8:	0141                	addi	sp,sp,16
    800056ba:	8082                	ret
    panic("free_desc 1");
    800056bc:	00002517          	auipc	a0,0x2
    800056c0:	22450513          	addi	a0,a0,548 # 800078e0 <syscalls+0x338>
    800056c4:	8c6fb0ef          	jal	ra,8000078a <panic>
    panic("free_desc 2");
    800056c8:	00002517          	auipc	a0,0x2
    800056cc:	22850513          	addi	a0,a0,552 # 800078f0 <syscalls+0x348>
    800056d0:	8bafb0ef          	jal	ra,8000078a <panic>

00000000800056d4 <virtio_disk_init>:
{
    800056d4:	1101                	addi	sp,sp,-32
    800056d6:	ec06                	sd	ra,24(sp)
    800056d8:	e822                	sd	s0,16(sp)
    800056da:	e426                	sd	s1,8(sp)
    800056dc:	e04a                	sd	s2,0(sp)
    800056de:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800056e0:	00002597          	auipc	a1,0x2
    800056e4:	22058593          	addi	a1,a1,544 # 80007900 <syscalls+0x358>
    800056e8:	00024517          	auipc	a0,0x24
    800056ec:	80050513          	addi	a0,a0,-2048 # 80028ee8 <disk+0x128>
    800056f0:	d7efb0ef          	jal	ra,80000c6e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800056f4:	100017b7          	lui	a5,0x10001
    800056f8:	4398                	lw	a4,0(a5)
    800056fa:	2701                	sext.w	a4,a4
    800056fc:	747277b7          	lui	a5,0x74727
    80005700:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005704:	14f71063          	bne	a4,a5,80005844 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005708:	100017b7          	lui	a5,0x10001
    8000570c:	43dc                	lw	a5,4(a5)
    8000570e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005710:	4709                	li	a4,2
    80005712:	12e79963          	bne	a5,a4,80005844 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005716:	100017b7          	lui	a5,0x10001
    8000571a:	479c                	lw	a5,8(a5)
    8000571c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000571e:	12e79363          	bne	a5,a4,80005844 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005722:	100017b7          	lui	a5,0x10001
    80005726:	47d8                	lw	a4,12(a5)
    80005728:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000572a:	554d47b7          	lui	a5,0x554d4
    8000572e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005732:	10f71963          	bne	a4,a5,80005844 <virtio_disk_init+0x170>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005736:	100017b7          	lui	a5,0x10001
    8000573a:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000573e:	4705                	li	a4,1
    80005740:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005742:	470d                	li	a4,3
    80005744:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005746:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005748:	c7ffe737          	lui	a4,0xc7ffe
    8000574c:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd585f>
    80005750:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005752:	2701                	sext.w	a4,a4
    80005754:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005756:	472d                	li	a4,11
    80005758:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    8000575a:	5bbc                	lw	a5,112(a5)
    8000575c:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005760:	8ba1                	andi	a5,a5,8
    80005762:	0e078763          	beqz	a5,80005850 <virtio_disk_init+0x17c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005766:	100017b7          	lui	a5,0x10001
    8000576a:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    8000576e:	43fc                	lw	a5,68(a5)
    80005770:	2781                	sext.w	a5,a5
    80005772:	0e079563          	bnez	a5,8000585c <virtio_disk_init+0x188>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005776:	100017b7          	lui	a5,0x10001
    8000577a:	5bdc                	lw	a5,52(a5)
    8000577c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000577e:	0e078563          	beqz	a5,80005868 <virtio_disk_init+0x194>
  if(max < NUM)
    80005782:	471d                	li	a4,7
    80005784:	0ef77863          	bgeu	a4,a5,80005874 <virtio_disk_init+0x1a0>
  disk.desc = kalloc();
    80005788:	c66fb0ef          	jal	ra,80000bee <kalloc>
    8000578c:	00023497          	auipc	s1,0x23
    80005790:	63448493          	addi	s1,s1,1588 # 80028dc0 <disk>
    80005794:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005796:	c58fb0ef          	jal	ra,80000bee <kalloc>
    8000579a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000579c:	c52fb0ef          	jal	ra,80000bee <kalloc>
    800057a0:	87aa                	mv	a5,a0
    800057a2:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800057a4:	6088                	ld	a0,0(s1)
    800057a6:	cd69                	beqz	a0,80005880 <virtio_disk_init+0x1ac>
    800057a8:	00023717          	auipc	a4,0x23
    800057ac:	62073703          	ld	a4,1568(a4) # 80028dc8 <disk+0x8>
    800057b0:	cb61                	beqz	a4,80005880 <virtio_disk_init+0x1ac>
    800057b2:	c7f9                	beqz	a5,80005880 <virtio_disk_init+0x1ac>
  memset(disk.desc, 0, PGSIZE);
    800057b4:	6605                	lui	a2,0x1
    800057b6:	4581                	li	a1,0
    800057b8:	e0afb0ef          	jal	ra,80000dc2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800057bc:	00023497          	auipc	s1,0x23
    800057c0:	60448493          	addi	s1,s1,1540 # 80028dc0 <disk>
    800057c4:	6605                	lui	a2,0x1
    800057c6:	4581                	li	a1,0
    800057c8:	6488                	ld	a0,8(s1)
    800057ca:	df8fb0ef          	jal	ra,80000dc2 <memset>
  memset(disk.used, 0, PGSIZE);
    800057ce:	6605                	lui	a2,0x1
    800057d0:	4581                	li	a1,0
    800057d2:	6888                	ld	a0,16(s1)
    800057d4:	deefb0ef          	jal	ra,80000dc2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800057d8:	100017b7          	lui	a5,0x10001
    800057dc:	4721                	li	a4,8
    800057de:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800057e0:	4098                	lw	a4,0(s1)
    800057e2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800057e6:	40d8                	lw	a4,4(s1)
    800057e8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800057ec:	6498                	ld	a4,8(s1)
    800057ee:	0007069b          	sext.w	a3,a4
    800057f2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800057f6:	9701                	srai	a4,a4,0x20
    800057f8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800057fc:	6898                	ld	a4,16(s1)
    800057fe:	0007069b          	sext.w	a3,a4
    80005802:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005806:	9701                	srai	a4,a4,0x20
    80005808:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000580c:	4705                	li	a4,1
    8000580e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005810:	00e48c23          	sb	a4,24(s1)
    80005814:	00e48ca3          	sb	a4,25(s1)
    80005818:	00e48d23          	sb	a4,26(s1)
    8000581c:	00e48da3          	sb	a4,27(s1)
    80005820:	00e48e23          	sb	a4,28(s1)
    80005824:	00e48ea3          	sb	a4,29(s1)
    80005828:	00e48f23          	sb	a4,30(s1)
    8000582c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005830:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005834:	0727a823          	sw	s2,112(a5)
}
    80005838:	60e2                	ld	ra,24(sp)
    8000583a:	6442                	ld	s0,16(sp)
    8000583c:	64a2                	ld	s1,8(sp)
    8000583e:	6902                	ld	s2,0(sp)
    80005840:	6105                	addi	sp,sp,32
    80005842:	8082                	ret
    panic("could not find virtio disk");
    80005844:	00002517          	auipc	a0,0x2
    80005848:	0cc50513          	addi	a0,a0,204 # 80007910 <syscalls+0x368>
    8000584c:	f3ffa0ef          	jal	ra,8000078a <panic>
    panic("virtio disk FEATURES_OK unset");
    80005850:	00002517          	auipc	a0,0x2
    80005854:	0e050513          	addi	a0,a0,224 # 80007930 <syscalls+0x388>
    80005858:	f33fa0ef          	jal	ra,8000078a <panic>
    panic("virtio disk should not be ready");
    8000585c:	00002517          	auipc	a0,0x2
    80005860:	0f450513          	addi	a0,a0,244 # 80007950 <syscalls+0x3a8>
    80005864:	f27fa0ef          	jal	ra,8000078a <panic>
    panic("virtio disk has no queue 0");
    80005868:	00002517          	auipc	a0,0x2
    8000586c:	10850513          	addi	a0,a0,264 # 80007970 <syscalls+0x3c8>
    80005870:	f1bfa0ef          	jal	ra,8000078a <panic>
    panic("virtio disk max queue too short");
    80005874:	00002517          	auipc	a0,0x2
    80005878:	11c50513          	addi	a0,a0,284 # 80007990 <syscalls+0x3e8>
    8000587c:	f0ffa0ef          	jal	ra,8000078a <panic>
    panic("virtio disk kalloc");
    80005880:	00002517          	auipc	a0,0x2
    80005884:	13050513          	addi	a0,a0,304 # 800079b0 <syscalls+0x408>
    80005888:	f03fa0ef          	jal	ra,8000078a <panic>

000000008000588c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000588c:	7119                	addi	sp,sp,-128
    8000588e:	fc86                	sd	ra,120(sp)
    80005890:	f8a2                	sd	s0,112(sp)
    80005892:	f4a6                	sd	s1,104(sp)
    80005894:	f0ca                	sd	s2,96(sp)
    80005896:	ecce                	sd	s3,88(sp)
    80005898:	e8d2                	sd	s4,80(sp)
    8000589a:	e4d6                	sd	s5,72(sp)
    8000589c:	e0da                	sd	s6,64(sp)
    8000589e:	fc5e                	sd	s7,56(sp)
    800058a0:	f862                	sd	s8,48(sp)
    800058a2:	f466                	sd	s9,40(sp)
    800058a4:	f06a                	sd	s10,32(sp)
    800058a6:	ec6e                	sd	s11,24(sp)
    800058a8:	0100                	addi	s0,sp,128
    800058aa:	8aaa                	mv	s5,a0
    800058ac:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800058ae:	00c52d03          	lw	s10,12(a0)
    800058b2:	001d1d1b          	slliw	s10,s10,0x1
    800058b6:	1d02                	slli	s10,s10,0x20
    800058b8:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800058bc:	00023517          	auipc	a0,0x23
    800058c0:	62c50513          	addi	a0,a0,1580 # 80028ee8 <disk+0x128>
    800058c4:	c2afb0ef          	jal	ra,80000cee <acquire>
  for(int i = 0; i < 3; i++){
    800058c8:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800058ca:	44a1                	li	s1,8
      disk.free[i] = 0;
    800058cc:	00023b97          	auipc	s7,0x23
    800058d0:	4f4b8b93          	addi	s7,s7,1268 # 80028dc0 <disk>
  for(int i = 0; i < 3; i++){
    800058d4:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800058d6:	00023c97          	auipc	s9,0x23
    800058da:	612c8c93          	addi	s9,s9,1554 # 80028ee8 <disk+0x128>
    800058de:	a8a9                	j	80005938 <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    800058e0:	00fb8733          	add	a4,s7,a5
    800058e4:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800058e8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800058ea:	0207c563          	bltz	a5,80005914 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800058ee:	2905                	addiw	s2,s2,1
    800058f0:	0611                	addi	a2,a2,4
    800058f2:	05690863          	beq	s2,s6,80005942 <virtio_disk_rw+0xb6>
    idx[i] = alloc_desc();
    800058f6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800058f8:	00023717          	auipc	a4,0x23
    800058fc:	4c870713          	addi	a4,a4,1224 # 80028dc0 <disk>
    80005900:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005902:	01874683          	lbu	a3,24(a4)
    80005906:	fee9                	bnez	a3,800058e0 <virtio_disk_rw+0x54>
  for(int i = 0; i < NUM; i++){
    80005908:	2785                	addiw	a5,a5,1
    8000590a:	0705                	addi	a4,a4,1
    8000590c:	fe979be3          	bne	a5,s1,80005902 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005910:	57fd                	li	a5,-1
    80005912:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005914:	01205b63          	blez	s2,8000592a <virtio_disk_rw+0x9e>
    80005918:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000591a:	000a2503          	lw	a0,0(s4)
    8000591e:	d41ff0ef          	jal	ra,8000565e <free_desc>
      for(int j = 0; j < i; j++)
    80005922:	2d85                	addiw	s11,s11,1
    80005924:	0a11                	addi	s4,s4,4
    80005926:	ffb91ae3          	bne	s2,s11,8000591a <virtio_disk_rw+0x8e>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000592a:	85e6                	mv	a1,s9
    8000592c:	00023517          	auipc	a0,0x23
    80005930:	4ac50513          	addi	a0,a0,1196 # 80028dd8 <disk+0x18>
    80005934:	ee2fc0ef          	jal	ra,80002016 <sleep>
  for(int i = 0; i < 3; i++){
    80005938:	f8040a13          	addi	s4,s0,-128
{
    8000593c:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000593e:	894e                	mv	s2,s3
    80005940:	bf5d                	j	800058f6 <virtio_disk_rw+0x6a>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005942:	f8042583          	lw	a1,-128(s0)
    80005946:	00a58793          	addi	a5,a1,10
    8000594a:	0792                	slli	a5,a5,0x4

  if(write)
    8000594c:	00023617          	auipc	a2,0x23
    80005950:	47460613          	addi	a2,a2,1140 # 80028dc0 <disk>
    80005954:	00f60733          	add	a4,a2,a5
    80005958:	018036b3          	snez	a3,s8
    8000595c:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000595e:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80005962:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005966:	f6078693          	addi	a3,a5,-160
    8000596a:	6218                	ld	a4,0(a2)
    8000596c:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000596e:	00878513          	addi	a0,a5,8
    80005972:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005974:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005976:	6208                	ld	a0,0(a2)
    80005978:	96aa                	add	a3,a3,a0
    8000597a:	4741                	li	a4,16
    8000597c:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000597e:	4705                	li	a4,1
    80005980:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80005984:	f8442703          	lw	a4,-124(s0)
    80005988:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    8000598c:	0712                	slli	a4,a4,0x4
    8000598e:	953a                	add	a0,a0,a4
    80005990:	058a8693          	addi	a3,s5,88
    80005994:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80005996:	6208                	ld	a0,0(a2)
    80005998:	972a                	add	a4,a4,a0
    8000599a:	40000693          	li	a3,1024
    8000599e:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800059a0:	001c3c13          	seqz	s8,s8
    800059a4:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800059a6:	001c6c13          	ori	s8,s8,1
    800059aa:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800059ae:	f8842603          	lw	a2,-120(s0)
    800059b2:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800059b6:	00023697          	auipc	a3,0x23
    800059ba:	40a68693          	addi	a3,a3,1034 # 80028dc0 <disk>
    800059be:	00258713          	addi	a4,a1,2
    800059c2:	0712                	slli	a4,a4,0x4
    800059c4:	9736                	add	a4,a4,a3
    800059c6:	587d                	li	a6,-1
    800059c8:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800059cc:	0612                	slli	a2,a2,0x4
    800059ce:	9532                	add	a0,a0,a2
    800059d0:	f9078793          	addi	a5,a5,-112
    800059d4:	97b6                	add	a5,a5,a3
    800059d6:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800059d8:	629c                	ld	a5,0(a3)
    800059da:	97b2                	add	a5,a5,a2
    800059dc:	4605                	li	a2,1
    800059de:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800059e0:	4509                	li	a0,2
    800059e2:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800059e6:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800059ea:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800059ee:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800059f2:	6698                	ld	a4,8(a3)
    800059f4:	00275783          	lhu	a5,2(a4)
    800059f8:	8b9d                	andi	a5,a5,7
    800059fa:	0786                	slli	a5,a5,0x1
    800059fc:	97ba                	add	a5,a5,a4
    800059fe:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80005a02:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005a06:	6698                	ld	a4,8(a3)
    80005a08:	00275783          	lhu	a5,2(a4)
    80005a0c:	2785                	addiw	a5,a5,1
    80005a0e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005a12:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005a16:	100017b7          	lui	a5,0x10001
    80005a1a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005a1e:	004aa783          	lw	a5,4(s5)
    80005a22:	00c79f63          	bne	a5,a2,80005a40 <virtio_disk_rw+0x1b4>
    sleep(b, &disk.vdisk_lock);
    80005a26:	00023917          	auipc	s2,0x23
    80005a2a:	4c290913          	addi	s2,s2,1218 # 80028ee8 <disk+0x128>
  while(b->disk == 1) {
    80005a2e:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005a30:	85ca                	mv	a1,s2
    80005a32:	8556                	mv	a0,s5
    80005a34:	de2fc0ef          	jal	ra,80002016 <sleep>
  while(b->disk == 1) {
    80005a38:	004aa783          	lw	a5,4(s5)
    80005a3c:	fe978ae3          	beq	a5,s1,80005a30 <virtio_disk_rw+0x1a4>
  }

  disk.info[idx[0]].b = 0;
    80005a40:	f8042903          	lw	s2,-128(s0)
    80005a44:	00290793          	addi	a5,s2,2
    80005a48:	00479713          	slli	a4,a5,0x4
    80005a4c:	00023797          	auipc	a5,0x23
    80005a50:	37478793          	addi	a5,a5,884 # 80028dc0 <disk>
    80005a54:	97ba                	add	a5,a5,a4
    80005a56:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80005a5a:	00023997          	auipc	s3,0x23
    80005a5e:	36698993          	addi	s3,s3,870 # 80028dc0 <disk>
    80005a62:	00491713          	slli	a4,s2,0x4
    80005a66:	0009b783          	ld	a5,0(s3)
    80005a6a:	97ba                	add	a5,a5,a4
    80005a6c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005a70:	854a                	mv	a0,s2
    80005a72:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005a76:	be9ff0ef          	jal	ra,8000565e <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80005a7a:	8885                	andi	s1,s1,1
    80005a7c:	f0fd                	bnez	s1,80005a62 <virtio_disk_rw+0x1d6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005a7e:	00023517          	auipc	a0,0x23
    80005a82:	46a50513          	addi	a0,a0,1130 # 80028ee8 <disk+0x128>
    80005a86:	b00fb0ef          	jal	ra,80000d86 <release>
}
    80005a8a:	70e6                	ld	ra,120(sp)
    80005a8c:	7446                	ld	s0,112(sp)
    80005a8e:	74a6                	ld	s1,104(sp)
    80005a90:	7906                	ld	s2,96(sp)
    80005a92:	69e6                	ld	s3,88(sp)
    80005a94:	6a46                	ld	s4,80(sp)
    80005a96:	6aa6                	ld	s5,72(sp)
    80005a98:	6b06                	ld	s6,64(sp)
    80005a9a:	7be2                	ld	s7,56(sp)
    80005a9c:	7c42                	ld	s8,48(sp)
    80005a9e:	7ca2                	ld	s9,40(sp)
    80005aa0:	7d02                	ld	s10,32(sp)
    80005aa2:	6de2                	ld	s11,24(sp)
    80005aa4:	6109                	addi	sp,sp,128
    80005aa6:	8082                	ret

0000000080005aa8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80005aa8:	1101                	addi	sp,sp,-32
    80005aaa:	ec06                	sd	ra,24(sp)
    80005aac:	e822                	sd	s0,16(sp)
    80005aae:	e426                	sd	s1,8(sp)
    80005ab0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80005ab2:	00023497          	auipc	s1,0x23
    80005ab6:	30e48493          	addi	s1,s1,782 # 80028dc0 <disk>
    80005aba:	00023517          	auipc	a0,0x23
    80005abe:	42e50513          	addi	a0,a0,1070 # 80028ee8 <disk+0x128>
    80005ac2:	a2cfb0ef          	jal	ra,80000cee <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80005ac6:	10001737          	lui	a4,0x10001
    80005aca:	533c                	lw	a5,96(a4)
    80005acc:	8b8d                	andi	a5,a5,3
    80005ace:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80005ad0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80005ad4:	689c                	ld	a5,16(s1)
    80005ad6:	0204d703          	lhu	a4,32(s1)
    80005ada:	0027d783          	lhu	a5,2(a5)
    80005ade:	04f70663          	beq	a4,a5,80005b2a <virtio_disk_intr+0x82>
    __sync_synchronize();
    80005ae2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80005ae6:	6898                	ld	a4,16(s1)
    80005ae8:	0204d783          	lhu	a5,32(s1)
    80005aec:	8b9d                	andi	a5,a5,7
    80005aee:	078e                	slli	a5,a5,0x3
    80005af0:	97ba                	add	a5,a5,a4
    80005af2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005af4:	00278713          	addi	a4,a5,2
    80005af8:	0712                	slli	a4,a4,0x4
    80005afa:	9726                	add	a4,a4,s1
    80005afc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80005b00:	e321                	bnez	a4,80005b40 <virtio_disk_intr+0x98>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005b02:	0789                	addi	a5,a5,2
    80005b04:	0792                	slli	a5,a5,0x4
    80005b06:	97a6                	add	a5,a5,s1
    80005b08:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80005b0a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80005b0e:	d54fc0ef          	jal	ra,80002062 <wakeup>

    disk.used_idx += 1;
    80005b12:	0204d783          	lhu	a5,32(s1)
    80005b16:	2785                	addiw	a5,a5,1
    80005b18:	17c2                	slli	a5,a5,0x30
    80005b1a:	93c1                	srli	a5,a5,0x30
    80005b1c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005b20:	6898                	ld	a4,16(s1)
    80005b22:	00275703          	lhu	a4,2(a4)
    80005b26:	faf71ee3          	bne	a4,a5,80005ae2 <virtio_disk_intr+0x3a>
  }

  release(&disk.vdisk_lock);
    80005b2a:	00023517          	auipc	a0,0x23
    80005b2e:	3be50513          	addi	a0,a0,958 # 80028ee8 <disk+0x128>
    80005b32:	a54fb0ef          	jal	ra,80000d86 <release>
}
    80005b36:	60e2                	ld	ra,24(sp)
    80005b38:	6442                	ld	s0,16(sp)
    80005b3a:	64a2                	ld	s1,8(sp)
    80005b3c:	6105                	addi	sp,sp,32
    80005b3e:	8082                	ret
      panic("virtio_disk_intr status");
    80005b40:	00002517          	auipc	a0,0x2
    80005b44:	e8850513          	addi	a0,a0,-376 # 800079c8 <syscalls+0x420>
    80005b48:	c43fa0ef          	jal	ra,8000078a <panic>
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
