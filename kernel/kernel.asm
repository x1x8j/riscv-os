
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
    80000004:	86010113          	addi	sp,sp,-1952 # 80007860 <stack0>
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
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffddc97>
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
    80000176:	6ee50513          	addi	a0,a0,1774 # 8000f860 <cons>
    8000017a:	1f3000ef          	jal	ra,80000b6c <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000017e:	0000f497          	auipc	s1,0xf
    80000182:	6e248493          	addi	s1,s1,1762 # 8000f860 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000186:	0000f917          	auipc	s2,0xf
    8000018a:	77290913          	addi	s2,s2,1906 # 8000f8f8 <cons+0x98>
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
    800001fe:	66650513          	addi	a0,a0,1638 # 8000f860 <cons>
    80000202:	203000ef          	jal	ra,80000c04 <release>

  return target - n;
    80000206:	413b053b          	subw	a0,s6,s3
    8000020a:	a801                	j	8000021a <consoleread+0xce>
        release(&cons.lock);
    8000020c:	0000f517          	auipc	a0,0xf
    80000210:	65450513          	addi	a0,a0,1620 # 8000f860 <cons>
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
    80000242:	6af72d23          	sw	a5,1722(a4) # 8000f8f8 <cons+0x98>
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
    8000028c:	5d850513          	addi	a0,a0,1496 # 8000f860 <cons>
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
    800002b2:	5b250513          	addi	a0,a0,1458 # 8000f860 <cons>
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
    800002d2:	59270713          	addi	a4,a4,1426 # 8000f860 <cons>
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
    800002f8:	56c78793          	addi	a5,a5,1388 # 8000f860 <cons>
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
    80000326:	5d67a783          	lw	a5,1494(a5) # 8000f8f8 <cons+0x98>
    8000032a:	9f1d                	subw	a4,a4,a5
    8000032c:	08000793          	li	a5,128
    80000330:	f6f71fe3          	bne	a4,a5,800002ae <consoleintr+0x34>
    80000334:	a04d                	j	800003d6 <consoleintr+0x15c>
    while(cons.e != cons.w &&
    80000336:	0000f717          	auipc	a4,0xf
    8000033a:	52a70713          	addi	a4,a4,1322 # 8000f860 <cons>
    8000033e:	0a072783          	lw	a5,160(a4)
    80000342:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000346:	0000f497          	auipc	s1,0xf
    8000034a:	51a48493          	addi	s1,s1,1306 # 8000f860 <cons>
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
    80000382:	4e270713          	addi	a4,a4,1250 # 8000f860 <cons>
    80000386:	0a072783          	lw	a5,160(a4)
    8000038a:	09c72703          	lw	a4,156(a4)
    8000038e:	f2f700e3          	beq	a4,a5,800002ae <consoleintr+0x34>
      cons.e--;
    80000392:	37fd                	addiw	a5,a5,-1
    80000394:	0000f717          	auipc	a4,0xf
    80000398:	56f72623          	sw	a5,1388(a4) # 8000f900 <cons+0xa0>
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
    800003b6:	4ae78793          	addi	a5,a5,1198 # 8000f860 <cons>
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
    800003da:	52c7a323          	sw	a2,1318(a5) # 8000f8fc <cons+0x9c>
        wakeup(&cons.r);
    800003de:	0000f517          	auipc	a0,0xf
    800003e2:	51a50513          	addi	a0,a0,1306 # 8000f8f8 <cons+0x98>
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
    80000400:	46450513          	addi	a0,a0,1124 # 8000f860 <cons>
    80000404:	6e8000ef          	jal	ra,80000aec <initlock>

  uartinit();
    80000408:	3e2000ef          	jal	ra,800007ea <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000040c:	0001f797          	auipc	a5,0x1f
    80000410:	5c478793          	addi	a5,a5,1476 # 8001f9d0 <devsw>
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
    800004fa:	33e7a783          	lw	a5,830(a5) # 80007834 <panicking>
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
    80000538:	3d450513          	addi	a0,a0,980 # 8000f908 <pr>
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
    80000756:	0e27a783          	lw	a5,226(a5) # 80007834 <panicking>
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
    80000780:	18c50513          	addi	a0,a0,396 # 8000f908 <pr>
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
    8000079e:	0927ad23          	sw	s2,154(a5) # 80007834 <panicking>
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
    800007c0:	0727aa23          	sw	s2,116(a5) # 80007830 <panicked>
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
    800007da:	13250513          	addi	a0,a0,306 # 8000f908 <pr>
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
    80000826:	0fe50513          	addi	a0,a0,254 # 8000f920 <tx_lock>
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
    80000854:	0d050513          	addi	a0,a0,208 # 8000f920 <tx_lock>
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
    80000872:	fce48493          	addi	s1,s1,-50 # 8000783c <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    80000876:	0000f997          	auipc	s3,0xf
    8000087a:	0aa98993          	addi	s3,s3,170 # 8000f920 <tx_lock>
    8000087e:	00007917          	auipc	s2,0x7
    80000882:	fba90913          	addi	s2,s2,-70 # 80007838 <tx_chan>
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
    800008b6:	06e50513          	addi	a0,a0,110 # 8000f920 <tx_lock>
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
    800008e4:	f547a783          	lw	a5,-172(a5) # 80007834 <panicking>
    800008e8:	cb89                	beqz	a5,800008fa <uartputc_sync+0x26>
    push_off();

  if(panicked){
    800008ea:	00007797          	auipc	a5,0x7
    800008ee:	f467a783          	lw	a5,-186(a5) # 80007830 <panicked>
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
    8000091a:	f1e7a783          	lw	a5,-226(a5) # 80007834 <panicking>
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
    8000096e:	fb650513          	addi	a0,a0,-74 # 8000f920 <tx_lock>
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
    80000984:	fa050513          	addi	a0,a0,-96 # 8000f920 <tx_lock>
    80000988:	27c000ef          	jal	ra,80000c04 <release>

  // read and process incoming characters, if any.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000098c:	54fd                	li	s1,-1
    8000098e:	a831                	j	800009aa <uartintr+0x52>
    tx_busy = 0;
    80000990:	00007797          	auipc	a5,0x7
    80000994:	ea07a623          	sw	zero,-340(a5) # 8000783c <tx_busy>
    wakeup(&tx_chan);
    80000998:	00007517          	auipc	a0,0x7
    8000099c:	ea050513          	addi	a0,a0,-352 # 80007838 <tx_chan>
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
    800009d4:	19878793          	addi	a5,a5,408 # 80020b68 <end>
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
    800009f0:	f4c90913          	addi	s2,s2,-180 # 8000f938 <kmem>
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
    80000a7c:	ec050513          	addi	a0,a0,-320 # 8000f938 <kmem>
    80000a80:	06c000ef          	jal	ra,80000aec <initlock>
  freerange(end, (void*)PHYSTOP);
    80000a84:	45c5                	li	a1,17
    80000a86:	05ee                	slli	a1,a1,0x1b
    80000a88:	00020517          	auipc	a0,0x20
    80000a8c:	0e050513          	addi	a0,a0,224 # 80020b68 <end>
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
    80000aaa:	e9248493          	addi	s1,s1,-366 # 8000f938 <kmem>
    80000aae:	8526                	mv	a0,s1
    80000ab0:	0bc000ef          	jal	ra,80000b6c <acquire>
  r = kmem.freelist;
    80000ab4:	6c84                	ld	s1,24(s1)
  if(r)
    80000ab6:	c485                	beqz	s1,80000ade <kalloc+0x42>
    kmem.freelist = r->next;
    80000ab8:	609c                	ld	a5,0(s1)
    80000aba:	0000f517          	auipc	a0,0xf
    80000abe:	e7e50513          	addi	a0,a0,-386 # 8000f938 <kmem>
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
    80000ae2:	e5a50513          	addi	a0,a0,-422 # 8000f938 <kmem>
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
    80000df2:	a5270713          	addi	a4,a4,-1454 # 80007840 <started>
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
    80000e18:	514010ef          	jal	ra,8000232c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000e1c:	3f8040ef          	jal	ra,80005214 <plicinithart>
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
    80000e60:	4a8010ef          	jal	ra,80002308 <trapinit>
    trapinithart();  // install kernel trap vector
    80000e64:	4c8010ef          	jal	ra,8000232c <trapinithart>
    plicinit();      // set up interrupt controller
    80000e68:	396040ef          	jal	ra,800051fe <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000e6c:	3a8040ef          	jal	ra,80005214 <plicinithart>
    binit();         // buffer cache
    80000e70:	34b010ef          	jal	ra,800029ba <binit>
    iinit();         // inode table
    80000e74:	0be020ef          	jal	ra,80002f32 <iinit>
    fileinit();      // file table
    80000e78:	79f020ef          	jal	ra,80003e16 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000e7c:	488040ef          	jal	ra,80005304 <virtio_disk_init>
    userinit();      // first user process
    80000e80:	44b000ef          	jal	ra,80001aca <userinit>
    __sync_synchronize();
    80000e84:	0ff0000f          	fence
    started = 1;
    80000e88:	4785                	li	a5,1
    80000e8a:	00007717          	auipc	a4,0x7
    80000e8e:	9af72b23          	sw	a5,-1610(a4) # 80007840 <started>
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
    80000ea2:	9aa7b783          	ld	a5,-1622(a5) # 80007848 <kernel_pagetable>
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
    8000112e:	70a7bf23          	sd	a0,1822(a5) # 80007848 <kernel_pagetable>
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
    800016c0:	6cc48493          	addi	s1,s1,1740 # 8000fd88 <proc>
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
    800016da:	0b2a0a13          	addi	s4,s4,178 # 80015788 <tickslock>
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
    80001750:	20c50513          	addi	a0,a0,524 # 8000f958 <pid_lock>
    80001754:	b98ff0ef          	jal	ra,80000aec <initlock>
  initlock(&wait_lock, "wait_lock");
    80001758:	00006597          	auipc	a1,0x6
    8000175c:	a2858593          	addi	a1,a1,-1496 # 80007180 <digits+0x148>
    80001760:	0000e517          	auipc	a0,0xe
    80001764:	21050513          	addi	a0,a0,528 # 8000f970 <wait_lock>
    80001768:	b84ff0ef          	jal	ra,80000aec <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000176c:	0000e497          	auipc	s1,0xe
    80001770:	61c48493          	addi	s1,s1,1564 # 8000fd88 <proc>
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
    80001792:	ffa98993          	addi	s3,s3,-6 # 80015788 <tickslock>
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
    800017f8:	19450513          	addi	a0,a0,404 # 8000f988 <cpus>
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
    8000181c:	14070713          	addi	a4,a4,320 # 8000f958 <pid_lock>
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
    8000184c:	fd87a783          	lw	a5,-40(a5) # 80007820 <first.1>
    80001850:	cf8d                	beqz	a5,8000188a <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    80001852:	4505                	li	a0,1
    80001854:	38f010ef          	jal	ra,800033e2 <fsinit>

    first = 0;
    80001858:	00006797          	auipc	a5,0x6
    8000185c:	fc07a423          	sw	zero,-56(a5) # 80007820 <first.1>
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
    80001878:	413020ef          	jal	ra,8000448a <kexec>
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
    8000188a:	2bb000ef          	jal	ra,80002344 <prepare_return>
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
    800018dc:	08090913          	addi	s2,s2,128 # 8000f958 <pid_lock>
    800018e0:	854a                	mv	a0,s2
    800018e2:	a8aff0ef          	jal	ra,80000b6c <acquire>
  pid = nextpid;
    800018e6:	00006797          	auipc	a5,0x6
    800018ea:	f3e78793          	addi	a5,a5,-194 # 80007824 <nextpid>
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
    80001a34:	35848493          	addi	s1,s1,856 # 8000fd88 <proc>
    80001a38:	00014917          	auipc	s2,0x14
    80001a3c:	d5090913          	addi	s2,s2,-688 # 80015788 <tickslock>
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
    80001ade:	d6a7bb23          	sd	a0,-650(a5) # 80007850 <initproc>
  p->cwd = namei("/");
    80001ae2:	00005517          	auipc	a0,0x5
    80001ae6:	6c650513          	addi	a0,a0,1734 # 800071a8 <digits+0x170>
    80001aea:	5f7010ef          	jal	ra,800038e0 <namei>
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
    80001c04:	294020ef          	jal	ra,80003e98 <filedup>
    80001c08:	00a93023          	sd	a0,0(s2)
    80001c0c:	b7f5                	j	80001bf8 <kfork+0x90>
  np->cwd = idup(p->cwd);
    80001c0e:	150ab503          	ld	a0,336(s5)
    80001c12:	4aa010ef          	jal	ra,800030bc <idup>
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
    80001c36:	d3e48493          	addi	s1,s1,-706 # 8000f970 <wait_lock>
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
    80001c98:	cc470713          	addi	a4,a4,-828 # 8000f958 <pid_lock>
    80001c9c:	975a                	add	a4,a4,s6
    80001c9e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ca2:	0000e717          	auipc	a4,0xe
    80001ca6:	cee70713          	addi	a4,a4,-786 # 8000f990 <cpus+0x8>
    80001caa:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001cac:	4c11                	li	s8,4
        c->proc = p;
    80001cae:	079e                	slli	a5,a5,0x7
    80001cb0:	0000ea17          	auipc	s4,0xe
    80001cb4:	ca8a0a13          	addi	s4,s4,-856 # 8000f958 <pid_lock>
    80001cb8:	9a3e                	add	s4,s4,a5
        found = 1;
    80001cba:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001cbc:	00014997          	auipc	s3,0x14
    80001cc0:	acc98993          	addi	s3,s3,-1332 # 80015788 <tickslock>
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
    80001cee:	5b0000ef          	jal	ra,8000229e <swtch>
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
    80001d1e:	06e48493          	addi	s1,s1,110 # 8000fd88 <proc>
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
    80001d4a:	c1270713          	addi	a4,a4,-1006 # 8000f958 <pid_lock>
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
    80001d70:	bec90913          	addi	s2,s2,-1044 # 8000f958 <pid_lock>
    80001d74:	2781                	sext.w	a5,a5
    80001d76:	079e                	slli	a5,a5,0x7
    80001d78:	97ca                	add	a5,a5,s2
    80001d7a:	0ac7a983          	lw	s3,172(a5)
    80001d7e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001d80:	2781                	sext.w	a5,a5
    80001d82:	079e                	slli	a5,a5,0x7
    80001d84:	0000e597          	auipc	a1,0xe
    80001d88:	c0c58593          	addi	a1,a1,-1012 # 8000f990 <cpus+0x8>
    80001d8c:	95be                	add	a1,a1,a5
    80001d8e:	06048513          	addi	a0,s1,96
    80001d92:	50c000ef          	jal	ra,8000229e <swtch>
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
    80001e70:	f1c48493          	addi	s1,s1,-228 # 8000fd88 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80001e74:	4989                	li	s3,2
        p->state = RUNNABLE;
    80001e76:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e78:	00014917          	auipc	s2,0x14
    80001e7c:	91090913          	addi	s2,s2,-1776 # 80015788 <tickslock>
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
    80001ed8:	eb448493          	addi	s1,s1,-332 # 8000fd88 <proc>
      pp->parent = initproc;
    80001edc:	00006a17          	auipc	s4,0x6
    80001ee0:	974a0a13          	addi	s4,s4,-1676 # 80007850 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ee4:	00014997          	auipc	s3,0x14
    80001ee8:	8a498993          	addi	s3,s3,-1884 # 80015788 <tickslock>
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
    80001f34:	9207b783          	ld	a5,-1760(a5) # 80007850 <initproc>
    80001f38:	0d050493          	addi	s1,a0,208
    80001f3c:	15050913          	addi	s2,a0,336
    80001f40:	00a79f63          	bne	a5,a0,80001f5e <kexit+0x46>
    panic("init exiting");
    80001f44:	00005517          	auipc	a0,0x5
    80001f48:	2b450513          	addi	a0,a0,692 # 800071f8 <digits+0x1c0>
    80001f4c:	83ffe0ef          	jal	ra,8000078a <panic>
      fileclose(f);
    80001f50:	78f010ef          	jal	ra,80003ede <fileclose>
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
    80001f64:	36d010ef          	jal	ra,80003ad0 <begin_op>
  iput(p->cwd);
    80001f68:	1509b503          	ld	a0,336(s3)
    80001f6c:	304010ef          	jal	ra,80003270 <iput>
  end_op();
    80001f70:	3d1010ef          	jal	ra,80003b40 <end_op>
  p->cwd = 0;
    80001f74:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80001f78:	0000e497          	auipc	s1,0xe
    80001f7c:	9f848493          	addi	s1,s1,-1544 # 8000f970 <wait_lock>
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
    80001fce:	dbe48493          	addi	s1,s1,-578 # 8000fd88 <proc>
    80001fd2:	00013997          	auipc	s3,0x13
    80001fd6:	7b698993          	addi	s3,s3,1974 # 80015788 <tickslock>
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
    80002092:	8e250513          	addi	a0,a0,-1822 # 8000f970 <wait_lock>
    80002096:	ad7fe0ef          	jal	ra,80000b6c <acquire>
    havekids = 0;
    8000209a:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000209c:	4a15                	li	s4,5
        havekids = 1;
    8000209e:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800020a0:	00013997          	auipc	s3,0x13
    800020a4:	6e898993          	addi	s3,s3,1768 # 80015788 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020a8:	0000ec17          	auipc	s8,0xe
    800020ac:	8c8c0c13          	addi	s8,s8,-1848 # 8000f970 <wait_lock>
    havekids = 0;
    800020b0:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800020b2:	0000e497          	auipc	s1,0xe
    800020b6:	cd648493          	addi	s1,s1,-810 # 8000fd88 <proc>
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
    800020e8:	88c50513          	addi	a0,a0,-1908 # 8000f970 <wait_lock>
    800020ec:	b19fe0ef          	jal	ra,80000c04 <release>
          return pid;
    800020f0:	a891                	j	80002144 <kwait+0xd6>
            release(&pp->lock);
    800020f2:	8526                	mv	a0,s1
    800020f4:	b11fe0ef          	jal	ra,80000c04 <release>
            release(&wait_lock);
    800020f8:	0000e517          	auipc	a0,0xe
    800020fc:	87850513          	addi	a0,a0,-1928 # 8000f970 <wait_lock>
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
    8000213a:	83a50513          	addi	a0,a0,-1990 # 8000f970 <wait_lock>
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
    80002222:	cc248493          	addi	s1,s1,-830 # 8000fee0 <proc+0x158>
    80002226:	00013917          	auipc	s2,0x13
    8000222a:	6ba90913          	addi	s2,s2,1722 # 800158e0 <bcache+0x140>
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

000000008000229e <swtch>:
# 保存当前寄存器到 old，然后从 new 加载寄存器。

.globl swtch
swtch:
        # 保存当前的寄存器到 old 中
        sd ra, 0(a0)   # 保存返回地址寄存器 ra
    8000229e:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)   # 保存栈指针寄存器 sp
    800022a2:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)  # 保存寄存器 s0
    800022a6:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)  # 保存寄存器 s1
    800022a8:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)  # 保存寄存器 s2
    800022aa:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)  # 保存寄存器 s3
    800022ae:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)  # 保存寄存器 s4
    800022b2:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)  # 保存寄存器 s5
    800022b6:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)  # 保存寄存器 s6
    800022ba:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)  # 保存寄存器 s7
    800022be:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)  # 保存寄存器 s8
    800022c2:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)  # 保存寄存器 s9
    800022c6:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0) # 保存寄存器 s10
    800022ca:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)# 保存寄存器 s11
    800022ce:	07b53423          	sd	s11,104(a0)

        # 从 new 加载寄存器
        ld ra, 0(a1)   # 加载返回地址寄存器 ra
    800022d2:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)   # 加载栈指针寄存器 sp
    800022d6:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)  # 加载寄存器 s0
    800022da:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)  # 加载寄存器 s1
    800022dc:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)  # 加载寄存器 s2
    800022de:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)  # 加载寄存器 s3
    800022e2:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)  # 加载寄存器 s4
    800022e6:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)  # 加载寄存器 s5
    800022ea:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)  # 加载寄存器 s6
    800022ee:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)  # 加载寄存器 s7
    800022f2:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)  # 加载寄存器 s8
    800022f6:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)  # 加载寄存器 s9
    800022fa:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1) # 加载寄存器 s10
    800022fe:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)# 加载寄存器 s11
    80002302:	0685bd83          	ld	s11,104(a1)

        ret             # 返回，完成上下文切换
    80002306:	8082                	ret

0000000080002308 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002308:	1141                	addi	sp,sp,-16
    8000230a:	e406                	sd	ra,8(sp)
    8000230c:	e022                	sd	s0,0(sp)
    8000230e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002310:	00005597          	auipc	a1,0x5
    80002314:	f8058593          	addi	a1,a1,-128 # 80007290 <states.0+0x30>
    80002318:	00013517          	auipc	a0,0x13
    8000231c:	47050513          	addi	a0,a0,1136 # 80015788 <tickslock>
    80002320:	fccfe0ef          	jal	ra,80000aec <initlock>
}
    80002324:	60a2                	ld	ra,8(sp)
    80002326:	6402                	ld	s0,0(sp)
    80002328:	0141                	addi	sp,sp,16
    8000232a:	8082                	ret

000000008000232c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000232c:	1141                	addi	sp,sp,-16
    8000232e:	e422                	sd	s0,8(sp)
    80002330:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002332:	00003797          	auipc	a5,0x3
    80002336:	e6e78793          	addi	a5,a5,-402 # 800051a0 <kernelvec>
    8000233a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000233e:	6422                	ld	s0,8(sp)
    80002340:	0141                	addi	sp,sp,16
    80002342:	8082                	ret

0000000080002344 <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    80002344:	1141                	addi	sp,sp,-16
    80002346:	e406                	sd	ra,8(sp)
    80002348:	e022                	sd	s0,0(sp)
    8000234a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000234c:	cb8ff0ef          	jal	ra,80001804 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002350:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002354:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002356:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000235a:	04000737          	lui	a4,0x4000
    8000235e:	00004797          	auipc	a5,0x4
    80002362:	ca278793          	addi	a5,a5,-862 # 80006000 <_trampoline>
    80002366:	00004697          	auipc	a3,0x4
    8000236a:	c9a68693          	addi	a3,a3,-870 # 80006000 <_trampoline>
    8000236e:	8f95                	sub	a5,a5,a3
    80002370:	177d                	addi	a4,a4,-1
    80002372:	0732                	slli	a4,a4,0xc
    80002374:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002376:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000237a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000237c:	18002773          	csrr	a4,satp
    80002380:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002382:	6d38                	ld	a4,88(a0)
    80002384:	613c                	ld	a5,64(a0)
    80002386:	6685                	lui	a3,0x1
    80002388:	97b6                	add	a5,a5,a3
    8000238a:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000238c:	6d3c                	ld	a5,88(a0)
    8000238e:	00000717          	auipc	a4,0x0
    80002392:	0f470713          	addi	a4,a4,244 # 80002482 <usertrap>
    80002396:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002398:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000239a:	8712                	mv	a4,tp
    8000239c:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000239e:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800023a2:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800023a6:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800023aa:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800023ae:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800023b0:	6f9c                	ld	a5,24(a5)
    800023b2:	14179073          	csrw	sepc,a5
}
    800023b6:	60a2                	ld	ra,8(sp)
    800023b8:	6402                	ld	s0,0(sp)
    800023ba:	0141                	addi	sp,sp,16
    800023bc:	8082                	ret

00000000800023be <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800023be:	1101                	addi	sp,sp,-32
    800023c0:	ec06                	sd	ra,24(sp)
    800023c2:	e822                	sd	s0,16(sp)
    800023c4:	e426                	sd	s1,8(sp)
    800023c6:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    800023c8:	c10ff0ef          	jal	ra,800017d8 <cpuid>
    800023cc:	cd19                	beqz	a0,800023ea <clockintr+0x2c>
  asm volatile("csrr %0, time" : "=r" (x) );
    800023ce:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    800023d2:	000f4737          	lui	a4,0xf4
    800023d6:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    800023da:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    800023dc:	14d79073          	csrw	0x14d,a5
}
    800023e0:	60e2                	ld	ra,24(sp)
    800023e2:	6442                	ld	s0,16(sp)
    800023e4:	64a2                	ld	s1,8(sp)
    800023e6:	6105                	addi	sp,sp,32
    800023e8:	8082                	ret
    acquire(&tickslock);
    800023ea:	00013497          	auipc	s1,0x13
    800023ee:	39e48493          	addi	s1,s1,926 # 80015788 <tickslock>
    800023f2:	8526                	mv	a0,s1
    800023f4:	f78fe0ef          	jal	ra,80000b6c <acquire>
    ticks++;
    800023f8:	00005517          	auipc	a0,0x5
    800023fc:	46050513          	addi	a0,a0,1120 # 80007858 <ticks>
    80002400:	411c                	lw	a5,0(a0)
    80002402:	2785                	addiw	a5,a5,1
    80002404:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    80002406:	a53ff0ef          	jal	ra,80001e58 <wakeup>
    release(&tickslock);
    8000240a:	8526                	mv	a0,s1
    8000240c:	ff8fe0ef          	jal	ra,80000c04 <release>
    80002410:	bf7d                	j	800023ce <clockintr+0x10>

0000000080002412 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002412:	1101                	addi	sp,sp,-32
    80002414:	ec06                	sd	ra,24(sp)
    80002416:	e822                	sd	s0,16(sp)
    80002418:	e426                	sd	s1,8(sp)
    8000241a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000241c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    80002420:	57fd                	li	a5,-1
    80002422:	17fe                	slli	a5,a5,0x3f
    80002424:	07a5                	addi	a5,a5,9
    80002426:	00f70d63          	beq	a4,a5,80002440 <devintr+0x2e>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    8000242a:	57fd                	li	a5,-1
    8000242c:	17fe                	slli	a5,a5,0x3f
    8000242e:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    80002430:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    80002432:	04f70463          	beq	a4,a5,8000247a <devintr+0x68>
  }
}
    80002436:	60e2                	ld	ra,24(sp)
    80002438:	6442                	ld	s0,16(sp)
    8000243a:	64a2                	ld	s1,8(sp)
    8000243c:	6105                	addi	sp,sp,32
    8000243e:	8082                	ret
    int irq = plic_claim();
    80002440:	609020ef          	jal	ra,80005248 <plic_claim>
    80002444:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002446:	47a9                	li	a5,10
    80002448:	02f50363          	beq	a0,a5,8000246e <devintr+0x5c>
    } else if(irq == VIRTIO0_IRQ){
    8000244c:	4785                	li	a5,1
    8000244e:	02f50363          	beq	a0,a5,80002474 <devintr+0x62>
    return 1;
    80002452:	4505                	li	a0,1
    } else if(irq){
    80002454:	d0ed                	beqz	s1,80002436 <devintr+0x24>
      printf("unexpected interrupt irq=%d\n", irq);
    80002456:	85a6                	mv	a1,s1
    80002458:	00005517          	auipc	a0,0x5
    8000245c:	e4050513          	addi	a0,a0,-448 # 80007298 <states.0+0x38>
    80002460:	864fe0ef          	jal	ra,800004c4 <printf>
      plic_complete(irq);
    80002464:	8526                	mv	a0,s1
    80002466:	603020ef          	jal	ra,80005268 <plic_complete>
    return 1;
    8000246a:	4505                	li	a0,1
    8000246c:	b7e9                	j	80002436 <devintr+0x24>
      uartintr();
    8000246e:	ceafe0ef          	jal	ra,80000958 <uartintr>
    80002472:	bfcd                	j	80002464 <devintr+0x52>
      virtio_disk_intr();
    80002474:	264030ef          	jal	ra,800056d8 <virtio_disk_intr>
    80002478:	b7f5                	j	80002464 <devintr+0x52>
    clockintr();
    8000247a:	f45ff0ef          	jal	ra,800023be <clockintr>
    return 2;
    8000247e:	4509                	li	a0,2
    80002480:	bf5d                	j	80002436 <devintr+0x24>

0000000080002482 <usertrap>:
{
    80002482:	1101                	addi	sp,sp,-32
    80002484:	ec06                	sd	ra,24(sp)
    80002486:	e822                	sd	s0,16(sp)
    80002488:	e426                	sd	s1,8(sp)
    8000248a:	e04a                	sd	s2,0(sp)
    8000248c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000248e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002492:	1007f793          	andi	a5,a5,256
    80002496:	eba5                	bnez	a5,80002506 <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002498:	00003797          	auipc	a5,0x3
    8000249c:	d0878793          	addi	a5,a5,-760 # 800051a0 <kernelvec>
    800024a0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800024a4:	b60ff0ef          	jal	ra,80001804 <myproc>
    800024a8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800024aa:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800024ac:	14102773          	csrr	a4,sepc
    800024b0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800024b2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800024b6:	47a1                	li	a5,8
    800024b8:	04f70d63          	beq	a4,a5,80002512 <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    800024bc:	f57ff0ef          	jal	ra,80002412 <devintr>
    800024c0:	892a                	mv	s2,a0
    800024c2:	e945                	bnez	a0,80002572 <usertrap+0xf0>
    800024c4:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    800024c8:	47bd                	li	a5,15
    800024ca:	08f70863          	beq	a4,a5,8000255a <usertrap+0xd8>
    800024ce:	14202773          	csrr	a4,scause
    800024d2:	47b5                	li	a5,13
    800024d4:	08f70363          	beq	a4,a5,8000255a <usertrap+0xd8>
    800024d8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    800024dc:	5890                	lw	a2,48(s1)
    800024de:	00005517          	auipc	a0,0x5
    800024e2:	dfa50513          	addi	a0,a0,-518 # 800072d8 <states.0+0x78>
    800024e6:	fdffd0ef          	jal	ra,800004c4 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800024ea:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800024ee:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    800024f2:	00005517          	auipc	a0,0x5
    800024f6:	e1650513          	addi	a0,a0,-490 # 80007308 <states.0+0xa8>
    800024fa:	fcbfd0ef          	jal	ra,800004c4 <printf>
    setkilled(p);
    800024fe:	8526                	mv	a0,s1
    80002500:	b21ff0ef          	jal	ra,80002020 <setkilled>
    80002504:	a035                	j	80002530 <usertrap+0xae>
    panic("usertrap: not from user mode");
    80002506:	00005517          	auipc	a0,0x5
    8000250a:	db250513          	addi	a0,a0,-590 # 800072b8 <states.0+0x58>
    8000250e:	a7cfe0ef          	jal	ra,8000078a <panic>
    if(killed(p))
    80002512:	b33ff0ef          	jal	ra,80002044 <killed>
    80002516:	ed15                	bnez	a0,80002552 <usertrap+0xd0>
    p->trapframe->epc += 4;
    80002518:	6cb8                	ld	a4,88(s1)
    8000251a:	6f1c                	ld	a5,24(a4)
    8000251c:	0791                	addi	a5,a5,4
    8000251e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002520:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002524:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002528:	10079073          	csrw	sstatus,a5
    syscall();
    8000252c:	246000ef          	jal	ra,80002772 <syscall>
  if(killed(p))
    80002530:	8526                	mv	a0,s1
    80002532:	b13ff0ef          	jal	ra,80002044 <killed>
    80002536:	e139                	bnez	a0,8000257c <usertrap+0xfa>
  prepare_return();
    80002538:	e0dff0ef          	jal	ra,80002344 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    8000253c:	68a8                	ld	a0,80(s1)
    8000253e:	8131                	srli	a0,a0,0xc
    80002540:	57fd                	li	a5,-1
    80002542:	17fe                	slli	a5,a5,0x3f
    80002544:	8d5d                	or	a0,a0,a5
}
    80002546:	60e2                	ld	ra,24(sp)
    80002548:	6442                	ld	s0,16(sp)
    8000254a:	64a2                	ld	s1,8(sp)
    8000254c:	6902                	ld	s2,0(sp)
    8000254e:	6105                	addi	sp,sp,32
    80002550:	8082                	ret
      kexit(-1);
    80002552:	557d                	li	a0,-1
    80002554:	9c5ff0ef          	jal	ra,80001f18 <kexit>
    80002558:	b7c1                	j	80002518 <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000255a:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000255e:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    80002562:	164d                	addi	a2,a2,-13
    80002564:	00163613          	seqz	a2,a2
    80002568:	68a8                	ld	a0,80(s1)
    8000256a:	f77fe0ef          	jal	ra,800014e0 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    8000256e:	f169                	bnez	a0,80002530 <usertrap+0xae>
    80002570:	b7a5                	j	800024d8 <usertrap+0x56>
  if(killed(p))
    80002572:	8526                	mv	a0,s1
    80002574:	ad1ff0ef          	jal	ra,80002044 <killed>
    80002578:	c511                	beqz	a0,80002584 <usertrap+0x102>
    8000257a:	a011                	j	8000257e <usertrap+0xfc>
    8000257c:	4901                	li	s2,0
    kexit(-1);
    8000257e:	557d                	li	a0,-1
    80002580:	999ff0ef          	jal	ra,80001f18 <kexit>
  if(which_dev == 2)
    80002584:	4789                	li	a5,2
    80002586:	faf919e3          	bne	s2,a5,80002538 <usertrap+0xb6>
    yield();
    8000258a:	857ff0ef          	jal	ra,80001de0 <yield>
    8000258e:	b76d                	j	80002538 <usertrap+0xb6>

0000000080002590 <kerneltrap>:
{
    80002590:	7179                	addi	sp,sp,-48
    80002592:	f406                	sd	ra,40(sp)
    80002594:	f022                	sd	s0,32(sp)
    80002596:	ec26                	sd	s1,24(sp)
    80002598:	e84a                	sd	s2,16(sp)
    8000259a:	e44e                	sd	s3,8(sp)
    8000259c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000259e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025a2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800025a6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800025aa:	1004f793          	andi	a5,s1,256
    800025ae:	c795                	beqz	a5,800025da <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025b0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800025b4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800025b6:	eb85                	bnez	a5,800025e6 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    800025b8:	e5bff0ef          	jal	ra,80002412 <devintr>
    800025bc:	c91d                	beqz	a0,800025f2 <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0)
    800025be:	4789                	li	a5,2
    800025c0:	04f50a63          	beq	a0,a5,80002614 <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800025c4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025c8:	10049073          	csrw	sstatus,s1
}
    800025cc:	70a2                	ld	ra,40(sp)
    800025ce:	7402                	ld	s0,32(sp)
    800025d0:	64e2                	ld	s1,24(sp)
    800025d2:	6942                	ld	s2,16(sp)
    800025d4:	69a2                	ld	s3,8(sp)
    800025d6:	6145                	addi	sp,sp,48
    800025d8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800025da:	00005517          	auipc	a0,0x5
    800025de:	d5650513          	addi	a0,a0,-682 # 80007330 <states.0+0xd0>
    800025e2:	9a8fe0ef          	jal	ra,8000078a <panic>
    panic("kerneltrap: interrupts enabled");
    800025e6:	00005517          	auipc	a0,0x5
    800025ea:	d7250513          	addi	a0,a0,-654 # 80007358 <states.0+0xf8>
    800025ee:	99cfe0ef          	jal	ra,8000078a <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800025f2:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800025f6:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    800025fa:	85ce                	mv	a1,s3
    800025fc:	00005517          	auipc	a0,0x5
    80002600:	d7c50513          	addi	a0,a0,-644 # 80007378 <states.0+0x118>
    80002604:	ec1fd0ef          	jal	ra,800004c4 <printf>
    panic("kerneltrap");
    80002608:	00005517          	auipc	a0,0x5
    8000260c:	d9850513          	addi	a0,a0,-616 # 800073a0 <states.0+0x140>
    80002610:	97afe0ef          	jal	ra,8000078a <panic>
  if(which_dev == 2 && myproc() != 0)
    80002614:	9f0ff0ef          	jal	ra,80001804 <myproc>
    80002618:	d555                	beqz	a0,800025c4 <kerneltrap+0x34>
    yield();
    8000261a:	fc6ff0ef          	jal	ra,80001de0 <yield>
    8000261e:	b75d                	j	800025c4 <kerneltrap+0x34>

0000000080002620 <argraw>:
}

// 获取第 n 个系统调用的原始参数（未处理过的原始值）
static uint64
argraw(int n)
{
    80002620:	1101                	addi	sp,sp,-32
    80002622:	ec06                	sd	ra,24(sp)
    80002624:	e822                	sd	s0,16(sp)
    80002626:	e426                	sd	s1,8(sp)
    80002628:	1000                	addi	s0,sp,32
    8000262a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000262c:	9d8ff0ef          	jal	ra,80001804 <myproc>
  switch (n) {
    80002630:	4795                	li	a5,5
    80002632:	0497e163          	bltu	a5,s1,80002674 <argraw+0x54>
    80002636:	048a                	slli	s1,s1,0x2
    80002638:	00005717          	auipc	a4,0x5
    8000263c:	da070713          	addi	a4,a4,-608 # 800073d8 <states.0+0x178>
    80002640:	94ba                	add	s1,s1,a4
    80002642:	409c                	lw	a5,0(s1)
    80002644:	97ba                	add	a5,a5,a4
    80002646:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002648:	6d3c                	ld	a5,88(a0)
    8000264a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");  // 如果参数 n 无效，触发 panic
  return -1;
}
    8000264c:	60e2                	ld	ra,24(sp)
    8000264e:	6442                	ld	s0,16(sp)
    80002650:	64a2                	ld	s1,8(sp)
    80002652:	6105                	addi	sp,sp,32
    80002654:	8082                	ret
    return p->trapframe->a1;
    80002656:	6d3c                	ld	a5,88(a0)
    80002658:	7fa8                	ld	a0,120(a5)
    8000265a:	bfcd                	j	8000264c <argraw+0x2c>
    return p->trapframe->a2;
    8000265c:	6d3c                	ld	a5,88(a0)
    8000265e:	63c8                	ld	a0,128(a5)
    80002660:	b7f5                	j	8000264c <argraw+0x2c>
    return p->trapframe->a3;
    80002662:	6d3c                	ld	a5,88(a0)
    80002664:	67c8                	ld	a0,136(a5)
    80002666:	b7dd                	j	8000264c <argraw+0x2c>
    return p->trapframe->a4;
    80002668:	6d3c                	ld	a5,88(a0)
    8000266a:	6bc8                	ld	a0,144(a5)
    8000266c:	b7c5                	j	8000264c <argraw+0x2c>
    return p->trapframe->a5;
    8000266e:	6d3c                	ld	a5,88(a0)
    80002670:	6fc8                	ld	a0,152(a5)
    80002672:	bfe9                	j	8000264c <argraw+0x2c>
  panic("argraw");  // 如果参数 n 无效，触发 panic
    80002674:	00005517          	auipc	a0,0x5
    80002678:	d3c50513          	addi	a0,a0,-708 # 800073b0 <states.0+0x150>
    8000267c:	90efe0ef          	jal	ra,8000078a <panic>

0000000080002680 <fetchaddr>:
{
    80002680:	1101                	addi	sp,sp,-32
    80002682:	ec06                	sd	ra,24(sp)
    80002684:	e822                	sd	s0,16(sp)
    80002686:	e426                	sd	s1,8(sp)
    80002688:	e04a                	sd	s2,0(sp)
    8000268a:	1000                	addi	s0,sp,32
    8000268c:	84aa                	mv	s1,a0
    8000268e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002690:	974ff0ef          	jal	ra,80001804 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // 这两个条件都需要检查，防止溢出
    80002694:	653c                	ld	a5,72(a0)
    80002696:	02f4f663          	bgeu	s1,a5,800026c2 <fetchaddr+0x42>
    8000269a:	00848713          	addi	a4,s1,8
    8000269e:	02e7e463          	bltu	a5,a4,800026c6 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800026a2:	46a1                	li	a3,8
    800026a4:	8626                	mv	a2,s1
    800026a6:	85ca                	mv	a1,s2
    800026a8:	6928                	ld	a0,80(a0)
    800026aa:	f6ffe0ef          	jal	ra,80001618 <copyin>
    800026ae:	00a03533          	snez	a0,a0
    800026b2:	40a00533          	neg	a0,a0
}
    800026b6:	60e2                	ld	ra,24(sp)
    800026b8:	6442                	ld	s0,16(sp)
    800026ba:	64a2                	ld	s1,8(sp)
    800026bc:	6902                	ld	s2,0(sp)
    800026be:	6105                	addi	sp,sp,32
    800026c0:	8082                	ret
    return -1;
    800026c2:	557d                	li	a0,-1
    800026c4:	bfcd                	j	800026b6 <fetchaddr+0x36>
    800026c6:	557d                	li	a0,-1
    800026c8:	b7fd                	j	800026b6 <fetchaddr+0x36>

00000000800026ca <fetchstr>:
{
    800026ca:	7179                	addi	sp,sp,-48
    800026cc:	f406                	sd	ra,40(sp)
    800026ce:	f022                	sd	s0,32(sp)
    800026d0:	ec26                	sd	s1,24(sp)
    800026d2:	e84a                	sd	s2,16(sp)
    800026d4:	e44e                	sd	s3,8(sp)
    800026d6:	1800                	addi	s0,sp,48
    800026d8:	892a                	mv	s2,a0
    800026da:	84ae                	mv	s1,a1
    800026dc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800026de:	926ff0ef          	jal	ra,80001804 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800026e2:	86ce                	mv	a3,s3
    800026e4:	864a                	mv	a2,s2
    800026e6:	85a6                	mv	a1,s1
    800026e8:	6928                	ld	a0,80(a0)
    800026ea:	d27fe0ef          	jal	ra,80001410 <copyinstr>
    800026ee:	00054c63          	bltz	a0,80002706 <fetchstr+0x3c>
  return strlen(buf);  // 返回字符串长度
    800026f2:	8526                	mv	a0,s1
    800026f4:	ec4fe0ef          	jal	ra,80000db8 <strlen>
}
    800026f8:	70a2                	ld	ra,40(sp)
    800026fa:	7402                	ld	s0,32(sp)
    800026fc:	64e2                	ld	s1,24(sp)
    800026fe:	6942                	ld	s2,16(sp)
    80002700:	69a2                	ld	s3,8(sp)
    80002702:	6145                	addi	sp,sp,48
    80002704:	8082                	ret
    return -1;
    80002706:	557d                	li	a0,-1
    80002708:	bfc5                	j	800026f8 <fetchstr+0x2e>

000000008000270a <argint>:

// 获取第 n 个 32 位的系统调用参数并将其存入 ip 中
void
argint(int n, int *ip)
{
    8000270a:	1101                	addi	sp,sp,-32
    8000270c:	ec06                	sd	ra,24(sp)
    8000270e:	e822                	sd	s0,16(sp)
    80002710:	e426                	sd	s1,8(sp)
    80002712:	1000                	addi	s0,sp,32
    80002714:	84ae                	mv	s1,a1
  *ip = argraw(n);  // 通过 argraw 获取原始参数并存储
    80002716:	f0bff0ef          	jal	ra,80002620 <argraw>
    8000271a:	c088                	sw	a0,0(s1)
}
    8000271c:	60e2                	ld	ra,24(sp)
    8000271e:	6442                	ld	s0,16(sp)
    80002720:	64a2                	ld	s1,8(sp)
    80002722:	6105                	addi	sp,sp,32
    80002724:	8082                	ret

0000000080002726 <argaddr>:

// 获取第 n 个参数并将其作为指针返回。
// 不进行合法性检查，因为 copyin 和 copyout 会处理这些检查。
void
argaddr(int n, uint64 *ip)
{
    80002726:	1101                	addi	sp,sp,-32
    80002728:	ec06                	sd	ra,24(sp)
    8000272a:	e822                	sd	s0,16(sp)
    8000272c:	e426                	sd	s1,8(sp)
    8000272e:	1000                	addi	s0,sp,32
    80002730:	84ae                	mv	s1,a1
  *ip = argraw(n);  // 通过 argraw 获取原始参数并存储
    80002732:	eefff0ef          	jal	ra,80002620 <argraw>
    80002736:	e088                	sd	a0,0(s1)
}
    80002738:	60e2                	ld	ra,24(sp)
    8000273a:	6442                	ld	s0,16(sp)
    8000273c:	64a2                	ld	s1,8(sp)
    8000273e:	6105                	addi	sp,sp,32
    80002740:	8082                	ret

0000000080002742 <argstr>:
// 获取第 n 个参数，假设它是一个以 null 结尾的字符串。
// 将该字符串拷贝到 buf 中，最多拷贝 max 个字符。
// 成功时返回字符串长度（包括 null），出错时返回 -1。
int
argstr(int n, char *buf, int max)
{
    80002742:	7179                	addi	sp,sp,-48
    80002744:	f406                	sd	ra,40(sp)
    80002746:	f022                	sd	s0,32(sp)
    80002748:	ec26                	sd	s1,24(sp)
    8000274a:	e84a                	sd	s2,16(sp)
    8000274c:	1800                	addi	s0,sp,48
    8000274e:	84ae                	mv	s1,a1
    80002750:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);  // 获取第 n 个参数的地址
    80002752:	fd840593          	addi	a1,s0,-40
    80002756:	fd1ff0ef          	jal	ra,80002726 <argaddr>
  return fetchstr(addr, buf, max);  // 使用 fetchstr 获取字符串内容
    8000275a:	864a                	mv	a2,s2
    8000275c:	85a6                	mv	a1,s1
    8000275e:	fd843503          	ld	a0,-40(s0)
    80002762:	f69ff0ef          	jal	ra,800026ca <fetchstr>
}
    80002766:	70a2                	ld	ra,40(sp)
    80002768:	7402                	ld	s0,32(sp)
    8000276a:	64e2                	ld	s1,24(sp)
    8000276c:	6942                	ld	s2,16(sp)
    8000276e:	6145                	addi	sp,sp,48
    80002770:	8082                	ret

0000000080002772 <syscall>:
};

// 系统调用的入口函数
void
syscall(void)
{
    80002772:	1101                	addi	sp,sp,-32
    80002774:	ec06                	sd	ra,24(sp)
    80002776:	e822                	sd	s0,16(sp)
    80002778:	e426                	sd	s1,8(sp)
    8000277a:	e04a                	sd	s2,0(sp)
    8000277c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000277e:	886ff0ef          	jal	ra,80001804 <myproc>
    80002782:	84aa                	mv	s1,a0

  num = p->trapframe->a7;  // 从 trapframe 中获取系统调用号
    80002784:	05853903          	ld	s2,88(a0)
    80002788:	0a893783          	ld	a5,168(s2)
    8000278c:	0007869b          	sext.w	a3,a5
  // 检查系统调用号是否合法，且确保有对应的处理函数
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002790:	37fd                	addiw	a5,a5,-1
    80002792:	4751                	li	a4,20
    80002794:	00f76f63          	bltu	a4,a5,800027b2 <syscall+0x40>
    80002798:	00369713          	slli	a4,a3,0x3
    8000279c:	00005797          	auipc	a5,0x5
    800027a0:	c5478793          	addi	a5,a5,-940 # 800073f0 <syscalls>
    800027a4:	97ba                	add	a5,a5,a4
    800027a6:	639c                	ld	a5,0(a5)
    800027a8:	c789                	beqz	a5,800027b2 <syscall+0x40>
    // 根据系统调用号查找对应的系统调用函数并调用
    // 系统调用的返回值会存储在 p->trapframe->a0 中
    p->trapframe->a0 = syscalls[num]();
    800027aa:	9782                	jalr	a5
    800027ac:	06a93823          	sd	a0,112(s2)
    800027b0:	a829                	j	800027ca <syscall+0x58>
  } else {
    // 如果找不到有效的系统调用，打印错误信息
    printf("%d %s: unknown sys call %d\n",
    800027b2:	15848613          	addi	a2,s1,344
    800027b6:	588c                	lw	a1,48(s1)
    800027b8:	00005517          	auipc	a0,0x5
    800027bc:	c0050513          	addi	a0,a0,-1024 # 800073b8 <states.0+0x158>
    800027c0:	d05fd0ef          	jal	ra,800004c4 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;  // 设置返回值为 -1 表示错误
    800027c4:	6cbc                	ld	a5,88(s1)
    800027c6:	577d                	li	a4,-1
    800027c8:	fbb8                	sd	a4,112(a5)
  }
}
    800027ca:	60e2                	ld	ra,24(sp)
    800027cc:	6442                	ld	s0,16(sp)
    800027ce:	64a2                	ld	s1,8(sp)
    800027d0:	6902                	ld	s2,0(sp)
    800027d2:	6105                	addi	sp,sp,32
    800027d4:	8082                	ret

00000000800027d6 <sys_exit>:
#include "vm.h"

// 进程退出系统调用
uint64
sys_exit(void)
{
    800027d6:	1101                	addi	sp,sp,-32
    800027d8:	ec06                	sd	ra,24(sp)
    800027da:	e822                	sd	s0,16(sp)
    800027dc:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);  // 获取退出码
    800027de:	fec40593          	addi	a1,s0,-20
    800027e2:	4501                	li	a0,0
    800027e4:	f27ff0ef          	jal	ra,8000270a <argint>
  kexit(n);       // 调用内核的退出函数
    800027e8:	fec42503          	lw	a0,-20(s0)
    800027ec:	f2cff0ef          	jal	ra,80001f18 <kexit>
  return 0;       // 不会执行到这里
}
    800027f0:	4501                	li	a0,0
    800027f2:	60e2                	ld	ra,24(sp)
    800027f4:	6442                	ld	s0,16(sp)
    800027f6:	6105                	addi	sp,sp,32
    800027f8:	8082                	ret

00000000800027fa <sys_getpid>:

// 获取当前进程的进程ID
uint64
sys_getpid(void)
{
    800027fa:	1141                	addi	sp,sp,-16
    800027fc:	e406                	sd	ra,8(sp)
    800027fe:	e022                	sd	s0,0(sp)
    80002800:	0800                	addi	s0,sp,16
  return myproc()->pid;  // 返回当前进程的 PID
    80002802:	802ff0ef          	jal	ra,80001804 <myproc>
}
    80002806:	5908                	lw	a0,48(a0)
    80002808:	60a2                	ld	ra,8(sp)
    8000280a:	6402                	ld	s0,0(sp)
    8000280c:	0141                	addi	sp,sp,16
    8000280e:	8082                	ret

0000000080002810 <sys_fork>:

// 创建一个新的子进程
uint64
sys_fork(void)
{
    80002810:	1141                	addi	sp,sp,-16
    80002812:	e406                	sd	ra,8(sp)
    80002814:	e022                	sd	s0,0(sp)
    80002816:	0800                	addi	s0,sp,16
  return kfork();  // 调用内核的 fork 函数
    80002818:	b50ff0ef          	jal	ra,80001b68 <kfork>
}
    8000281c:	60a2                	ld	ra,8(sp)
    8000281e:	6402                	ld	s0,0(sp)
    80002820:	0141                	addi	sp,sp,16
    80002822:	8082                	ret

0000000080002824 <sys_wait>:

// 等待子进程退出
uint64
sys_wait(void)
{
    80002824:	1101                	addi	sp,sp,-32
    80002826:	ec06                	sd	ra,24(sp)
    80002828:	e822                	sd	s0,16(sp)
    8000282a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);  // 获取等待子进程状态的地址
    8000282c:	fe840593          	addi	a1,s0,-24
    80002830:	4501                	li	a0,0
    80002832:	ef5ff0ef          	jal	ra,80002726 <argaddr>
  return kwait(p);  // 调用内核的 wait 函数
    80002836:	fe843503          	ld	a0,-24(s0)
    8000283a:	835ff0ef          	jal	ra,8000206e <kwait>
}
    8000283e:	60e2                	ld	ra,24(sp)
    80002840:	6442                	ld	s0,16(sp)
    80002842:	6105                	addi	sp,sp,32
    80002844:	8082                	ret

0000000080002846 <sys_sbrk>:

// 扩展或收缩进程的内存
uint64
sys_sbrk(void)
{
    80002846:	7179                	addi	sp,sp,-48
    80002848:	f406                	sd	ra,40(sp)
    8000284a:	f022                	sd	s0,32(sp)
    8000284c:	ec26                	sd	s1,24(sp)
    8000284e:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);  // 获取内存增量
    80002850:	fd840593          	addi	a1,s0,-40
    80002854:	4501                	li	a0,0
    80002856:	eb5ff0ef          	jal	ra,8000270a <argint>
  argint(1, &t);  // 获取是否懒加载标志
    8000285a:	fdc40593          	addi	a1,s0,-36
    8000285e:	4505                	li	a0,1
    80002860:	eabff0ef          	jal	ra,8000270a <argint>
  addr = myproc()->sz;  // 获取当前进程的内存大小
    80002864:	fa1fe0ef          	jal	ra,80001804 <myproc>
    80002868:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {  // 如果是急切分配或要求收缩内存
    8000286a:	fdc42703          	lw	a4,-36(s0)
    8000286e:	4785                	li	a5,1
    80002870:	02f70763          	beq	a4,a5,8000289e <sys_sbrk+0x58>
    80002874:	fd842783          	lw	a5,-40(s0)
    80002878:	0207c363          	bltz	a5,8000289e <sys_sbrk+0x58>
    if(growproc(n) < 0) {  // 调用内核的 growproc 函数调整内存
      return -1;  // 内存分配失败
    }
  } else {  // 如果是懒加载分配
    if(addr + n < addr)  // 防止内存溢出
    8000287c:	97a6                	add	a5,a5,s1
    8000287e:	0297ee63          	bltu	a5,s1,800028ba <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)  // 限制内存的最大值
    80002882:	02000737          	lui	a4,0x2000
    80002886:	177d                	addi	a4,a4,-1
    80002888:	0736                	slli	a4,a4,0xd
    8000288a:	02f76a63          	bltu	a4,a5,800028be <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;  // 调整进程的内存大小
    8000288e:	f77fe0ef          	jal	ra,80001804 <myproc>
    80002892:	fd842703          	lw	a4,-40(s0)
    80002896:	653c                	ld	a5,72(a0)
    80002898:	97ba                	add	a5,a5,a4
    8000289a:	e53c                	sd	a5,72(a0)
    8000289c:	a039                	j	800028aa <sys_sbrk+0x64>
    if(growproc(n) < 0) {  // 调用内核的 growproc 函数调整内存
    8000289e:	fd842503          	lw	a0,-40(s0)
    800028a2:	a64ff0ef          	jal	ra,80001b06 <growproc>
    800028a6:	00054863          	bltz	a0,800028b6 <sys_sbrk+0x70>
  }
  return addr;  // 返回原内存地址
}
    800028aa:	8526                	mv	a0,s1
    800028ac:	70a2                	ld	ra,40(sp)
    800028ae:	7402                	ld	s0,32(sp)
    800028b0:	64e2                	ld	s1,24(sp)
    800028b2:	6145                	addi	sp,sp,48
    800028b4:	8082                	ret
      return -1;  // 内存分配失败
    800028b6:	54fd                	li	s1,-1
    800028b8:	bfcd                	j	800028aa <sys_sbrk+0x64>
      return -1;
    800028ba:	54fd                	li	s1,-1
    800028bc:	b7fd                	j	800028aa <sys_sbrk+0x64>
      return -1;
    800028be:	54fd                	li	s1,-1
    800028c0:	b7ed                	j	800028aa <sys_sbrk+0x64>

00000000800028c2 <sys_pause>:

// 让当前进程挂起指定时间
uint64
sys_pause(void)
{
    800028c2:	7139                	addi	sp,sp,-64
    800028c4:	fc06                	sd	ra,56(sp)
    800028c6:	f822                	sd	s0,48(sp)
    800028c8:	f426                	sd	s1,40(sp)
    800028ca:	f04a                	sd	s2,32(sp)
    800028cc:	ec4e                	sd	s3,24(sp)
    800028ce:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);  // 获取暂停的时长（以时钟滴答为单位）
    800028d0:	fcc40593          	addi	a1,s0,-52
    800028d4:	4501                	li	a0,0
    800028d6:	e35ff0ef          	jal	ra,8000270a <argint>
  if(n < 0)  // 如果给定的时长为负，则设置为 0
    800028da:	fcc42783          	lw	a5,-52(s0)
    800028de:	0607c563          	bltz	a5,80002948 <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);  // 获取时钟锁
    800028e2:	00013517          	auipc	a0,0x13
    800028e6:	ea650513          	addi	a0,a0,-346 # 80015788 <tickslock>
    800028ea:	a82fe0ef          	jal	ra,80000b6c <acquire>
  ticks0 = ticks;  // 记录当前的时钟滴答数
    800028ee:	00005917          	auipc	s2,0x5
    800028f2:	f6a92903          	lw	s2,-150(s2) # 80007858 <ticks>
  while(ticks - ticks0 < n){  // 持续等待直到经过了指定的时间
    800028f6:	fcc42783          	lw	a5,-52(s0)
    800028fa:	cb8d                	beqz	a5,8000292c <sys_pause+0x6a>
    if(killed(myproc())){  // 如果进程被杀死，退出等待
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);  // 进程进入休眠状态，等待时钟更新
    800028fc:	00013997          	auipc	s3,0x13
    80002900:	e8c98993          	addi	s3,s3,-372 # 80015788 <tickslock>
    80002904:	00005497          	auipc	s1,0x5
    80002908:	f5448493          	addi	s1,s1,-172 # 80007858 <ticks>
    if(killed(myproc())){  // 如果进程被杀死，退出等待
    8000290c:	ef9fe0ef          	jal	ra,80001804 <myproc>
    80002910:	f34ff0ef          	jal	ra,80002044 <killed>
    80002914:	ed0d                	bnez	a0,8000294e <sys_pause+0x8c>
    sleep(&ticks, &tickslock);  // 进程进入休眠状态，等待时钟更新
    80002916:	85ce                	mv	a1,s3
    80002918:	8526                	mv	a0,s1
    8000291a:	cf2ff0ef          	jal	ra,80001e0c <sleep>
  while(ticks - ticks0 < n){  // 持续等待直到经过了指定的时间
    8000291e:	409c                	lw	a5,0(s1)
    80002920:	412787bb          	subw	a5,a5,s2
    80002924:	fcc42703          	lw	a4,-52(s0)
    80002928:	fee7e2e3          	bltu	a5,a4,8000290c <sys_pause+0x4a>
  }
  release(&tickslock);  // 释放时钟锁
    8000292c:	00013517          	auipc	a0,0x13
    80002930:	e5c50513          	addi	a0,a0,-420 # 80015788 <tickslock>
    80002934:	ad0fe0ef          	jal	ra,80000c04 <release>
  return 0;  // 返回
    80002938:	4501                	li	a0,0
}
    8000293a:	70e2                	ld	ra,56(sp)
    8000293c:	7442                	ld	s0,48(sp)
    8000293e:	74a2                	ld	s1,40(sp)
    80002940:	7902                	ld	s2,32(sp)
    80002942:	69e2                	ld	s3,24(sp)
    80002944:	6121                	addi	sp,sp,64
    80002946:	8082                	ret
    n = 0;
    80002948:	fc042623          	sw	zero,-52(s0)
    8000294c:	bf59                	j	800028e2 <sys_pause+0x20>
      release(&tickslock);
    8000294e:	00013517          	auipc	a0,0x13
    80002952:	e3a50513          	addi	a0,a0,-454 # 80015788 <tickslock>
    80002956:	aaefe0ef          	jal	ra,80000c04 <release>
      return -1;
    8000295a:	557d                	li	a0,-1
    8000295c:	bff9                	j	8000293a <sys_pause+0x78>

000000008000295e <sys_kill>:

// 终止指定进程
uint64
sys_kill(void)
{
    8000295e:	1101                	addi	sp,sp,-32
    80002960:	ec06                	sd	ra,24(sp)
    80002962:	e822                	sd	s0,16(sp)
    80002964:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);  // 获取进程 ID
    80002966:	fec40593          	addi	a1,s0,-20
    8000296a:	4501                	li	a0,0
    8000296c:	d9fff0ef          	jal	ra,8000270a <argint>
  return kkill(pid);  // 调用内核的 kill 函数终止进程
    80002970:	fec42503          	lw	a0,-20(s0)
    80002974:	e46ff0ef          	jal	ra,80001fba <kkill>
}
    80002978:	60e2                	ld	ra,24(sp)
    8000297a:	6442                	ld	s0,16(sp)
    8000297c:	6105                	addi	sp,sp,32
    8000297e:	8082                	ret

0000000080002980 <sys_uptime>:

// 返回自系统启动以来经过的时钟滴答数
uint64
sys_uptime(void)
{
    80002980:	1101                	addi	sp,sp,-32
    80002982:	ec06                	sd	ra,24(sp)
    80002984:	e822                	sd	s0,16(sp)
    80002986:	e426                	sd	s1,8(sp)
    80002988:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);  // 获取时钟锁
    8000298a:	00013517          	auipc	a0,0x13
    8000298e:	dfe50513          	addi	a0,a0,-514 # 80015788 <tickslock>
    80002992:	9dafe0ef          	jal	ra,80000b6c <acquire>
  xticks = ticks;  // 获取当前的时钟滴答数
    80002996:	00005497          	auipc	s1,0x5
    8000299a:	ec24a483          	lw	s1,-318(s1) # 80007858 <ticks>
  release(&tickslock);  // 释放时钟锁
    8000299e:	00013517          	auipc	a0,0x13
    800029a2:	dea50513          	addi	a0,a0,-534 # 80015788 <tickslock>
    800029a6:	a5efe0ef          	jal	ra,80000c04 <release>
  return xticks;  // 返回时钟滴答数
}
    800029aa:	02049513          	slli	a0,s1,0x20
    800029ae:	9101                	srli	a0,a0,0x20
    800029b0:	60e2                	ld	ra,24(sp)
    800029b2:	6442                	ld	s0,16(sp)
    800029b4:	64a2                	ld	s1,8(sp)
    800029b6:	6105                	addi	sp,sp,32
    800029b8:	8082                	ret

00000000800029ba <binit>:
} bcache;

// 初始化缓冲区缓存
void
binit(void)
{
    800029ba:	7179                	addi	sp,sp,-48
    800029bc:	f406                	sd	ra,40(sp)
    800029be:	f022                	sd	s0,32(sp)
    800029c0:	ec26                	sd	s1,24(sp)
    800029c2:	e84a                	sd	s2,16(sp)
    800029c4:	e44e                	sd	s3,8(sp)
    800029c6:	e052                	sd	s4,0(sp)
    800029c8:	1800                	addi	s0,sp,48
  struct buf *b;

  // 初始化缓冲区缓存的锁
  initlock(&bcache.lock, "bcache");
    800029ca:	00005597          	auipc	a1,0x5
    800029ce:	ad658593          	addi	a1,a1,-1322 # 800074a0 <syscalls+0xb0>
    800029d2:	00013517          	auipc	a0,0x13
    800029d6:	dce50513          	addi	a0,a0,-562 # 800157a0 <bcache>
    800029da:	912fe0ef          	jal	ra,80000aec <initlock>

  // 创建缓冲区链表
  bcache.head.prev = &bcache.head;
    800029de:	0001b797          	auipc	a5,0x1b
    800029e2:	dc278793          	addi	a5,a5,-574 # 8001d7a0 <bcache+0x8000>
    800029e6:	0001b717          	auipc	a4,0x1b
    800029ea:	02270713          	addi	a4,a4,34 # 8001da08 <bcache+0x8268>
    800029ee:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800029f2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf + NBUF; b++){
    800029f6:	00013497          	auipc	s1,0x13
    800029fa:	dc248493          	addi	s1,s1,-574 # 800157b8 <bcache+0x18>
    b->next = bcache.head.next;
    800029fe:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002a00:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");  // 初始化缓冲区的睡眠锁
    80002a02:	00005a17          	auipc	s4,0x5
    80002a06:	aa6a0a13          	addi	s4,s4,-1370 # 800074a8 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002a0a:	2b893783          	ld	a5,696(s2)
    80002a0e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002a10:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");  // 初始化缓冲区的睡眠锁
    80002a14:	85d2                	mv	a1,s4
    80002a16:	01048513          	addi	a0,s1,16
    80002a1a:	2fe010ef          	jal	ra,80003d18 <initsleeplock>
    bcache.head.next->prev = b;
    80002a1e:	2b893783          	ld	a5,696(s2)
    80002a22:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002a24:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf + NBUF; b++){
    80002a28:	45848493          	addi	s1,s1,1112
    80002a2c:	fd349fe3          	bne	s1,s3,80002a0a <binit+0x50>
  }
}
    80002a30:	70a2                	ld	ra,40(sp)
    80002a32:	7402                	ld	s0,32(sp)
    80002a34:	64e2                	ld	s1,24(sp)
    80002a36:	6942                	ld	s2,16(sp)
    80002a38:	69a2                	ld	s3,8(sp)
    80002a3a:	6a02                	ld	s4,0(sp)
    80002a3c:	6145                	addi	sp,sp,48
    80002a3e:	8082                	ret

0000000080002a40 <bread>:
}

// 获取指定磁盘块的缓冲区并返回，内容从磁盘读取
struct buf*
bread(uint dev, uint blockno)
{
    80002a40:	7179                	addi	sp,sp,-48
    80002a42:	f406                	sd	ra,40(sp)
    80002a44:	f022                	sd	s0,32(sp)
    80002a46:	ec26                	sd	s1,24(sp)
    80002a48:	e84a                	sd	s2,16(sp)
    80002a4a:	e44e                	sd	s3,8(sp)
    80002a4c:	1800                	addi	s0,sp,48
    80002a4e:	892a                	mv	s2,a0
    80002a50:	89ae                	mv	s3,a1
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002a52:	00013517          	auipc	a0,0x13
    80002a56:	d4e50513          	addi	a0,a0,-690 # 800157a0 <bcache>
    80002a5a:	912fe0ef          	jal	ra,80000b6c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002a5e:	0001b497          	auipc	s1,0x1b
    80002a62:	ffa4b483          	ld	s1,-6(s1) # 8001da58 <bcache+0x82b8>
    80002a66:	0001b797          	auipc	a5,0x1b
    80002a6a:	fa278793          	addi	a5,a5,-94 # 8001da08 <bcache+0x8268>
    80002a6e:	02f48b63          	beq	s1,a5,80002aa4 <bread+0x64>
    80002a72:	873e                	mv	a4,a5
    80002a74:	a021                	j	80002a7c <bread+0x3c>
    80002a76:	68a4                	ld	s1,80(s1)
    80002a78:	02e48663          	beq	s1,a4,80002aa4 <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002a7c:	449c                	lw	a5,8(s1)
    80002a7e:	ff279ce3          	bne	a5,s2,80002a76 <bread+0x36>
    80002a82:	44dc                	lw	a5,12(s1)
    80002a84:	ff3799e3          	bne	a5,s3,80002a76 <bread+0x36>
      b->refcnt++;  // 增加引用计数
    80002a88:	40bc                	lw	a5,64(s1)
    80002a8a:	2785                	addiw	a5,a5,1
    80002a8c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002a8e:	00013517          	auipc	a0,0x13
    80002a92:	d1250513          	addi	a0,a0,-750 # 800157a0 <bcache>
    80002a96:	96efe0ef          	jal	ra,80000c04 <release>
      acquiresleep(&b->lock);  // 获取缓冲区的睡眠锁
    80002a9a:	01048513          	addi	a0,s1,16
    80002a9e:	2b0010ef          	jal	ra,80003d4e <acquiresleep>
      return b;  // 返回缓冲区
    80002aa2:	a889                	j	80002af4 <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002aa4:	0001b497          	auipc	s1,0x1b
    80002aa8:	fac4b483          	ld	s1,-84(s1) # 8001da50 <bcache+0x82b0>
    80002aac:	0001b797          	auipc	a5,0x1b
    80002ab0:	f5c78793          	addi	a5,a5,-164 # 8001da08 <bcache+0x8268>
    80002ab4:	00f48863          	beq	s1,a5,80002ac4 <bread+0x84>
    80002ab8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002aba:	40bc                	lw	a5,64(s1)
    80002abc:	cb91                	beqz	a5,80002ad0 <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002abe:	64a4                	ld	s1,72(s1)
    80002ac0:	fee49de3          	bne	s1,a4,80002aba <bread+0x7a>
  panic("bget: no buffers");  // 如果没有找到可用的缓冲区，发生错误
    80002ac4:	00005517          	auipc	a0,0x5
    80002ac8:	9ec50513          	addi	a0,a0,-1556 # 800074b0 <syscalls+0xc0>
    80002acc:	cbffd0ef          	jal	ra,8000078a <panic>
      b->dev = dev;  // 设置设备号
    80002ad0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;  // 设置块号
    80002ad4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;  // 设置为无效
    80002ad8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;  // 引用计数设置为 1
    80002adc:	4785                	li	a5,1
    80002ade:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002ae0:	00013517          	auipc	a0,0x13
    80002ae4:	cc050513          	addi	a0,a0,-832 # 800157a0 <bcache>
    80002ae8:	91cfe0ef          	jal	ra,80000c04 <release>
      acquiresleep(&b->lock);  // 获取缓冲区的睡眠锁
    80002aec:	01048513          	addi	a0,s1,16
    80002af0:	25e010ef          	jal	ra,80003d4e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);  // 获取缓冲区
  if(!b->valid) {
    80002af4:	409c                	lw	a5,0(s1)
    80002af6:	cb89                	beqz	a5,80002b08 <bread+0xc8>
    virtio_disk_rw(b, 0);  // 从磁盘读取数据到缓冲区
    b->valid = 1;  // 设置缓冲区为有效
  }
  return b;  // 返回缓冲区
}
    80002af8:	8526                	mv	a0,s1
    80002afa:	70a2                	ld	ra,40(sp)
    80002afc:	7402                	ld	s0,32(sp)
    80002afe:	64e2                	ld	s1,24(sp)
    80002b00:	6942                	ld	s2,16(sp)
    80002b02:	69a2                	ld	s3,8(sp)
    80002b04:	6145                	addi	sp,sp,48
    80002b06:	8082                	ret
    virtio_disk_rw(b, 0);  // 从磁盘读取数据到缓冲区
    80002b08:	4581                	li	a1,0
    80002b0a:	8526                	mv	a0,s1
    80002b0c:	1b1020ef          	jal	ra,800054bc <virtio_disk_rw>
    b->valid = 1;  // 设置缓冲区为有效
    80002b10:	4785                	li	a5,1
    80002b12:	c09c                	sw	a5,0(s1)
  return b;  // 返回缓冲区
    80002b14:	b7d5                	j	80002af8 <bread+0xb8>

0000000080002b16 <bwrite>:

// 将缓冲区 b 的内容写入磁盘，必须先锁定缓冲区
void
bwrite(struct buf *b)
{
    80002b16:	1101                	addi	sp,sp,-32
    80002b18:	ec06                	sd	ra,24(sp)
    80002b1a:	e822                	sd	s0,16(sp)
    80002b1c:	e426                	sd	s1,8(sp)
    80002b1e:	1000                	addi	s0,sp,32
    80002b20:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002b22:	0541                	addi	a0,a0,16
    80002b24:	2a8010ef          	jal	ra,80003dcc <holdingsleep>
    80002b28:	c911                	beqz	a0,80002b3c <bwrite+0x26>
    panic("bwrite");  // 检查是否持有缓冲区的锁
  virtio_disk_rw(b, 1);  // 将缓冲区内容写入磁盘
    80002b2a:	4585                	li	a1,1
    80002b2c:	8526                	mv	a0,s1
    80002b2e:	18f020ef          	jal	ra,800054bc <virtio_disk_rw>
}
    80002b32:	60e2                	ld	ra,24(sp)
    80002b34:	6442                	ld	s0,16(sp)
    80002b36:	64a2                	ld	s1,8(sp)
    80002b38:	6105                	addi	sp,sp,32
    80002b3a:	8082                	ret
    panic("bwrite");  // 检查是否持有缓冲区的锁
    80002b3c:	00005517          	auipc	a0,0x5
    80002b40:	98c50513          	addi	a0,a0,-1652 # 800074c8 <syscalls+0xd8>
    80002b44:	c47fd0ef          	jal	ra,8000078a <panic>

0000000080002b48 <brelse>:

// 释放锁定的缓冲区，并将其移到最近使用的位置
void
brelse(struct buf *b)
{
    80002b48:	1101                	addi	sp,sp,-32
    80002b4a:	ec06                	sd	ra,24(sp)
    80002b4c:	e822                	sd	s0,16(sp)
    80002b4e:	e426                	sd	s1,8(sp)
    80002b50:	e04a                	sd	s2,0(sp)
    80002b52:	1000                	addi	s0,sp,32
    80002b54:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002b56:	01050913          	addi	s2,a0,16
    80002b5a:	854a                	mv	a0,s2
    80002b5c:	270010ef          	jal	ra,80003dcc <holdingsleep>
    80002b60:	c13d                	beqz	a0,80002bc6 <brelse+0x7e>
    panic("brelse");  // 检查是否持有缓冲区的锁

  releasesleep(&b->lock);  // 释放缓冲区的睡眠锁
    80002b62:	854a                	mv	a0,s2
    80002b64:	230010ef          	jal	ra,80003d94 <releasesleep>

  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002b68:	00013517          	auipc	a0,0x13
    80002b6c:	c3850513          	addi	a0,a0,-968 # 800157a0 <bcache>
    80002b70:	ffdfd0ef          	jal	ra,80000b6c <acquire>
  b->refcnt--;  // 减少引用计数
    80002b74:	40bc                	lw	a5,64(s1)
    80002b76:	37fd                	addiw	a5,a5,-1
    80002b78:	0007871b          	sext.w	a4,a5
    80002b7c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002b7e:	eb05                	bnez	a4,80002bae <brelse+0x66>
    // 如果没有其他进程在使用该缓冲区
    // 将缓冲区移到链表头部
    b->next->prev = b->prev;
    80002b80:	68bc                	ld	a5,80(s1)
    80002b82:	64b8                	ld	a4,72(s1)
    80002b84:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002b86:	64bc                	ld	a5,72(s1)
    80002b88:	68b8                	ld	a4,80(s1)
    80002b8a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002b8c:	0001b797          	auipc	a5,0x1b
    80002b90:	c1478793          	addi	a5,a5,-1004 # 8001d7a0 <bcache+0x8000>
    80002b94:	2b87b703          	ld	a4,696(a5)
    80002b98:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002b9a:	0001b717          	auipc	a4,0x1b
    80002b9e:	e6e70713          	addi	a4,a4,-402 # 8001da08 <bcache+0x8268>
    80002ba2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002ba4:	2b87b703          	ld	a4,696(a5)
    80002ba8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002baa:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002bae:	00013517          	auipc	a0,0x13
    80002bb2:	bf250513          	addi	a0,a0,-1038 # 800157a0 <bcache>
    80002bb6:	84efe0ef          	jal	ra,80000c04 <release>
}
    80002bba:	60e2                	ld	ra,24(sp)
    80002bbc:	6442                	ld	s0,16(sp)
    80002bbe:	64a2                	ld	s1,8(sp)
    80002bc0:	6902                	ld	s2,0(sp)
    80002bc2:	6105                	addi	sp,sp,32
    80002bc4:	8082                	ret
    panic("brelse");  // 检查是否持有缓冲区的锁
    80002bc6:	00005517          	auipc	a0,0x5
    80002bca:	90a50513          	addi	a0,a0,-1782 # 800074d0 <syscalls+0xe0>
    80002bce:	bbdfd0ef          	jal	ra,8000078a <panic>

0000000080002bd2 <bpin>:

// 增加缓冲区 b 的引用计数，用于防止缓冲区被释放
void
bpin(struct buf *b) {
    80002bd2:	1101                	addi	sp,sp,-32
    80002bd4:	ec06                	sd	ra,24(sp)
    80002bd6:	e822                	sd	s0,16(sp)
    80002bd8:	e426                	sd	s1,8(sp)
    80002bda:	1000                	addi	s0,sp,32
    80002bdc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002bde:	00013517          	auipc	a0,0x13
    80002be2:	bc250513          	addi	a0,a0,-1086 # 800157a0 <bcache>
    80002be6:	f87fd0ef          	jal	ra,80000b6c <acquire>
  b->refcnt++;  // 增加引用计数
    80002bea:	40bc                	lw	a5,64(s1)
    80002bec:	2785                	addiw	a5,a5,1
    80002bee:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002bf0:	00013517          	auipc	a0,0x13
    80002bf4:	bb050513          	addi	a0,a0,-1104 # 800157a0 <bcache>
    80002bf8:	80cfe0ef          	jal	ra,80000c04 <release>
}
    80002bfc:	60e2                	ld	ra,24(sp)
    80002bfe:	6442                	ld	s0,16(sp)
    80002c00:	64a2                	ld	s1,8(sp)
    80002c02:	6105                	addi	sp,sp,32
    80002c04:	8082                	ret

0000000080002c06 <bunpin>:

// 减少缓冲区 b 的引用计数，用于缓冲区的释放
void
bunpin(struct buf *b) {
    80002c06:	1101                	addi	sp,sp,-32
    80002c08:	ec06                	sd	ra,24(sp)
    80002c0a:	e822                	sd	s0,16(sp)
    80002c0c:	e426                	sd	s1,8(sp)
    80002c0e:	1000                	addi	s0,sp,32
    80002c10:	84aa                	mv	s1,a0
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002c12:	00013517          	auipc	a0,0x13
    80002c16:	b8e50513          	addi	a0,a0,-1138 # 800157a0 <bcache>
    80002c1a:	f53fd0ef          	jal	ra,80000b6c <acquire>
  b->refcnt--;  // 减少引用计数
    80002c1e:	40bc                	lw	a5,64(s1)
    80002c20:	37fd                	addiw	a5,a5,-1
    80002c22:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002c24:	00013517          	auipc	a0,0x13
    80002c28:	b7c50513          	addi	a0,a0,-1156 # 800157a0 <bcache>
    80002c2c:	fd9fd0ef          	jal	ra,80000c04 <release>
}
    80002c30:	60e2                	ld	ra,24(sp)
    80002c32:	6442                	ld	s0,16(sp)
    80002c34:	64a2                	ld	s1,8(sp)
    80002c36:	6105                	addi	sp,sp,32
    80002c38:	8082                	ret

0000000080002c3a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002c3a:	1101                	addi	sp,sp,-32
    80002c3c:	ec06                	sd	ra,24(sp)
    80002c3e:	e822                	sd	s0,16(sp)
    80002c40:	e426                	sd	s1,8(sp)
    80002c42:	e04a                	sd	s2,0(sp)
    80002c44:	1000                	addi	s0,sp,32
    80002c46:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002c48:	00d5d59b          	srliw	a1,a1,0xd
    80002c4c:	0001b797          	auipc	a5,0x1b
    80002c50:	2307a783          	lw	a5,560(a5) # 8001de7c <sb+0x1c>
    80002c54:	9dbd                	addw	a1,a1,a5
    80002c56:	debff0ef          	jal	ra,80002a40 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002c5a:	0074f713          	andi	a4,s1,7
    80002c5e:	4785                	li	a5,1
    80002c60:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80002c64:	14ce                	slli	s1,s1,0x33
    80002c66:	90d9                	srli	s1,s1,0x36
    80002c68:	00950733          	add	a4,a0,s1
    80002c6c:	05874703          	lbu	a4,88(a4)
    80002c70:	00e7f6b3          	and	a3,a5,a4
    80002c74:	c29d                	beqz	a3,80002c9a <bfree+0x60>
    80002c76:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002c78:	94aa                	add	s1,s1,a0
    80002c7a:	fff7c793          	not	a5,a5
    80002c7e:	8ff9                	and	a5,a5,a4
    80002c80:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80002c84:	7d1000ef          	jal	ra,80003c54 <log_write>
  brelse(bp);
    80002c88:	854a                	mv	a0,s2
    80002c8a:	ebfff0ef          	jal	ra,80002b48 <brelse>
}
    80002c8e:	60e2                	ld	ra,24(sp)
    80002c90:	6442                	ld	s0,16(sp)
    80002c92:	64a2                	ld	s1,8(sp)
    80002c94:	6902                	ld	s2,0(sp)
    80002c96:	6105                	addi	sp,sp,32
    80002c98:	8082                	ret
    panic("freeing free block");
    80002c9a:	00005517          	auipc	a0,0x5
    80002c9e:	83e50513          	addi	a0,a0,-1986 # 800074d8 <syscalls+0xe8>
    80002ca2:	ae9fd0ef          	jal	ra,8000078a <panic>

0000000080002ca6 <balloc>:
{
    80002ca6:	711d                	addi	sp,sp,-96
    80002ca8:	ec86                	sd	ra,88(sp)
    80002caa:	e8a2                	sd	s0,80(sp)
    80002cac:	e4a6                	sd	s1,72(sp)
    80002cae:	e0ca                	sd	s2,64(sp)
    80002cb0:	fc4e                	sd	s3,56(sp)
    80002cb2:	f852                	sd	s4,48(sp)
    80002cb4:	f456                	sd	s5,40(sp)
    80002cb6:	f05a                	sd	s6,32(sp)
    80002cb8:	ec5e                	sd	s7,24(sp)
    80002cba:	e862                	sd	s8,16(sp)
    80002cbc:	e466                	sd	s9,8(sp)
    80002cbe:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80002cc0:	0001b797          	auipc	a5,0x1b
    80002cc4:	1a47a783          	lw	a5,420(a5) # 8001de64 <sb+0x4>
    80002cc8:	0e078163          	beqz	a5,80002daa <balloc+0x104>
    80002ccc:	8baa                	mv	s7,a0
    80002cce:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80002cd0:	0001bb17          	auipc	s6,0x1b
    80002cd4:	190b0b13          	addi	s6,s6,400 # 8001de60 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002cd8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80002cda:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002cdc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80002cde:	6c89                	lui	s9,0x2
    80002ce0:	a0b5                	j	80002d4c <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    80002ce2:	974a                	add	a4,a4,s2
    80002ce4:	8fd5                	or	a5,a5,a3
    80002ce6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80002cea:	854a                	mv	a0,s2
    80002cec:	769000ef          	jal	ra,80003c54 <log_write>
        brelse(bp);
    80002cf0:	854a                	mv	a0,s2
    80002cf2:	e57ff0ef          	jal	ra,80002b48 <brelse>
  bp = bread(dev, bno);
    80002cf6:	85a6                	mv	a1,s1
    80002cf8:	855e                	mv	a0,s7
    80002cfa:	d47ff0ef          	jal	ra,80002a40 <bread>
    80002cfe:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80002d00:	40000613          	li	a2,1024
    80002d04:	4581                	li	a1,0
    80002d06:	05850513          	addi	a0,a0,88
    80002d0a:	f37fd0ef          	jal	ra,80000c40 <memset>
  log_write(bp);
    80002d0e:	854a                	mv	a0,s2
    80002d10:	745000ef          	jal	ra,80003c54 <log_write>
  brelse(bp);
    80002d14:	854a                	mv	a0,s2
    80002d16:	e33ff0ef          	jal	ra,80002b48 <brelse>
}
    80002d1a:	8526                	mv	a0,s1
    80002d1c:	60e6                	ld	ra,88(sp)
    80002d1e:	6446                	ld	s0,80(sp)
    80002d20:	64a6                	ld	s1,72(sp)
    80002d22:	6906                	ld	s2,64(sp)
    80002d24:	79e2                	ld	s3,56(sp)
    80002d26:	7a42                	ld	s4,48(sp)
    80002d28:	7aa2                	ld	s5,40(sp)
    80002d2a:	7b02                	ld	s6,32(sp)
    80002d2c:	6be2                	ld	s7,24(sp)
    80002d2e:	6c42                	ld	s8,16(sp)
    80002d30:	6ca2                	ld	s9,8(sp)
    80002d32:	6125                	addi	sp,sp,96
    80002d34:	8082                	ret
    brelse(bp);
    80002d36:	854a                	mv	a0,s2
    80002d38:	e11ff0ef          	jal	ra,80002b48 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80002d3c:	015c87bb          	addw	a5,s9,s5
    80002d40:	00078a9b          	sext.w	s5,a5
    80002d44:	004b2703          	lw	a4,4(s6)
    80002d48:	06eaf163          	bgeu	s5,a4,80002daa <balloc+0x104>
    bp = bread(dev, BBLOCK(b, sb));
    80002d4c:	41fad79b          	sraiw	a5,s5,0x1f
    80002d50:	0137d79b          	srliw	a5,a5,0x13
    80002d54:	015787bb          	addw	a5,a5,s5
    80002d58:	40d7d79b          	sraiw	a5,a5,0xd
    80002d5c:	01cb2583          	lw	a1,28(s6)
    80002d60:	9dbd                	addw	a1,a1,a5
    80002d62:	855e                	mv	a0,s7
    80002d64:	cddff0ef          	jal	ra,80002a40 <bread>
    80002d68:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002d6a:	004b2503          	lw	a0,4(s6)
    80002d6e:	000a849b          	sext.w	s1,s5
    80002d72:	8662                	mv	a2,s8
    80002d74:	fca4f1e3          	bgeu	s1,a0,80002d36 <balloc+0x90>
      m = 1 << (bi % 8);
    80002d78:	41f6579b          	sraiw	a5,a2,0x1f
    80002d7c:	01d7d69b          	srliw	a3,a5,0x1d
    80002d80:	00c6873b          	addw	a4,a3,a2
    80002d84:	00777793          	andi	a5,a4,7
    80002d88:	9f95                	subw	a5,a5,a3
    80002d8a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80002d8e:	4037571b          	sraiw	a4,a4,0x3
    80002d92:	00e906b3          	add	a3,s2,a4
    80002d96:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    80002d9a:	00d7f5b3          	and	a1,a5,a3
    80002d9e:	d1b1                	beqz	a1,80002ce2 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002da0:	2605                	addiw	a2,a2,1
    80002da2:	2485                	addiw	s1,s1,1
    80002da4:	fd4618e3          	bne	a2,s4,80002d74 <balloc+0xce>
    80002da8:	b779                	j	80002d36 <balloc+0x90>
  printf("balloc: out of blocks\n");
    80002daa:	00004517          	auipc	a0,0x4
    80002dae:	74650513          	addi	a0,a0,1862 # 800074f0 <syscalls+0x100>
    80002db2:	f12fd0ef          	jal	ra,800004c4 <printf>
  return 0;
    80002db6:	4481                	li	s1,0
    80002db8:	b78d                	j	80002d1a <balloc+0x74>

0000000080002dba <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80002dba:	7179                	addi	sp,sp,-48
    80002dbc:	f406                	sd	ra,40(sp)
    80002dbe:	f022                	sd	s0,32(sp)
    80002dc0:	ec26                	sd	s1,24(sp)
    80002dc2:	e84a                	sd	s2,16(sp)
    80002dc4:	e44e                	sd	s3,8(sp)
    80002dc6:	e052                	sd	s4,0(sp)
    80002dc8:	1800                	addi	s0,sp,48
    80002dca:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80002dcc:	47ad                	li	a5,11
    80002dce:	02b7e563          	bltu	a5,a1,80002df8 <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    80002dd2:	02059493          	slli	s1,a1,0x20
    80002dd6:	9081                	srli	s1,s1,0x20
    80002dd8:	048a                	slli	s1,s1,0x2
    80002dda:	94aa                	add	s1,s1,a0
    80002ddc:	0504a903          	lw	s2,80(s1)
    80002de0:	06091663          	bnez	s2,80002e4c <bmap+0x92>
      addr = balloc(ip->dev);
    80002de4:	4108                	lw	a0,0(a0)
    80002de6:	ec1ff0ef          	jal	ra,80002ca6 <balloc>
    80002dea:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002dee:	04090f63          	beqz	s2,80002e4c <bmap+0x92>
        return 0;
      ip->addrs[bn] = addr;
    80002df2:	0524a823          	sw	s2,80(s1)
    80002df6:	a899                	j	80002e4c <bmap+0x92>
    }
    return addr;
  }
  bn -= NDIRECT;
    80002df8:	ff45849b          	addiw	s1,a1,-12
    80002dfc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80002e00:	0ff00793          	li	a5,255
    80002e04:	06e7eb63          	bltu	a5,a4,80002e7a <bmap+0xc0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80002e08:	08052903          	lw	s2,128(a0)
    80002e0c:	00091b63          	bnez	s2,80002e22 <bmap+0x68>
      addr = balloc(ip->dev);
    80002e10:	4108                	lw	a0,0(a0)
    80002e12:	e95ff0ef          	jal	ra,80002ca6 <balloc>
    80002e16:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002e1a:	02090963          	beqz	s2,80002e4c <bmap+0x92>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80002e1e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80002e22:	85ca                	mv	a1,s2
    80002e24:	0009a503          	lw	a0,0(s3)
    80002e28:	c19ff0ef          	jal	ra,80002a40 <bread>
    80002e2c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80002e2e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80002e32:	02049593          	slli	a1,s1,0x20
    80002e36:	9181                	srli	a1,a1,0x20
    80002e38:	058a                	slli	a1,a1,0x2
    80002e3a:	00b784b3          	add	s1,a5,a1
    80002e3e:	0004a903          	lw	s2,0(s1)
    80002e42:	00090e63          	beqz	s2,80002e5e <bmap+0xa4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80002e46:	8552                	mv	a0,s4
    80002e48:	d01ff0ef          	jal	ra,80002b48 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80002e4c:	854a                	mv	a0,s2
    80002e4e:	70a2                	ld	ra,40(sp)
    80002e50:	7402                	ld	s0,32(sp)
    80002e52:	64e2                	ld	s1,24(sp)
    80002e54:	6942                	ld	s2,16(sp)
    80002e56:	69a2                	ld	s3,8(sp)
    80002e58:	6a02                	ld	s4,0(sp)
    80002e5a:	6145                	addi	sp,sp,48
    80002e5c:	8082                	ret
      addr = balloc(ip->dev);
    80002e5e:	0009a503          	lw	a0,0(s3)
    80002e62:	e45ff0ef          	jal	ra,80002ca6 <balloc>
    80002e66:	0005091b          	sext.w	s2,a0
      if(addr){
    80002e6a:	fc090ee3          	beqz	s2,80002e46 <bmap+0x8c>
        a[bn] = addr;
    80002e6e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80002e72:	8552                	mv	a0,s4
    80002e74:	5e1000ef          	jal	ra,80003c54 <log_write>
    80002e78:	b7f9                	j	80002e46 <bmap+0x8c>
  panic("bmap: out of range");
    80002e7a:	00004517          	auipc	a0,0x4
    80002e7e:	68e50513          	addi	a0,a0,1678 # 80007508 <syscalls+0x118>
    80002e82:	909fd0ef          	jal	ra,8000078a <panic>

0000000080002e86 <iget>:
{
    80002e86:	7179                	addi	sp,sp,-48
    80002e88:	f406                	sd	ra,40(sp)
    80002e8a:	f022                	sd	s0,32(sp)
    80002e8c:	ec26                	sd	s1,24(sp)
    80002e8e:	e84a                	sd	s2,16(sp)
    80002e90:	e44e                	sd	s3,8(sp)
    80002e92:	e052                	sd	s4,0(sp)
    80002e94:	1800                	addi	s0,sp,48
    80002e96:	89aa                	mv	s3,a0
    80002e98:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80002e9a:	0001b517          	auipc	a0,0x1b
    80002e9e:	fe650513          	addi	a0,a0,-26 # 8001de80 <itable>
    80002ea2:	ccbfd0ef          	jal	ra,80000b6c <acquire>
  empty = 0;
    80002ea6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80002ea8:	0001b497          	auipc	s1,0x1b
    80002eac:	ff048493          	addi	s1,s1,-16 # 8001de98 <itable+0x18>
    80002eb0:	0001d697          	auipc	a3,0x1d
    80002eb4:	a7868693          	addi	a3,a3,-1416 # 8001f928 <log>
    80002eb8:	a039                	j	80002ec6 <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80002eba:	02090963          	beqz	s2,80002eec <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80002ebe:	08848493          	addi	s1,s1,136
    80002ec2:	02d48863          	beq	s1,a3,80002ef2 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80002ec6:	449c                	lw	a5,8(s1)
    80002ec8:	fef059e3          	blez	a5,80002eba <iget+0x34>
    80002ecc:	4098                	lw	a4,0(s1)
    80002ece:	ff3716e3          	bne	a4,s3,80002eba <iget+0x34>
    80002ed2:	40d8                	lw	a4,4(s1)
    80002ed4:	ff4713e3          	bne	a4,s4,80002eba <iget+0x34>
      ip->ref++;
    80002ed8:	2785                	addiw	a5,a5,1
    80002eda:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80002edc:	0001b517          	auipc	a0,0x1b
    80002ee0:	fa450513          	addi	a0,a0,-92 # 8001de80 <itable>
    80002ee4:	d21fd0ef          	jal	ra,80000c04 <release>
      return ip;
    80002ee8:	8926                	mv	s2,s1
    80002eea:	a02d                	j	80002f14 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80002eec:	fbe9                	bnez	a5,80002ebe <iget+0x38>
    80002eee:	8926                	mv	s2,s1
    80002ef0:	b7f9                	j	80002ebe <iget+0x38>
  if(empty == 0)
    80002ef2:	02090a63          	beqz	s2,80002f26 <iget+0xa0>
  ip->dev = dev;
    80002ef6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80002efa:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80002efe:	4785                	li	a5,1
    80002f00:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80002f04:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80002f08:	0001b517          	auipc	a0,0x1b
    80002f0c:	f7850513          	addi	a0,a0,-136 # 8001de80 <itable>
    80002f10:	cf5fd0ef          	jal	ra,80000c04 <release>
}
    80002f14:	854a                	mv	a0,s2
    80002f16:	70a2                	ld	ra,40(sp)
    80002f18:	7402                	ld	s0,32(sp)
    80002f1a:	64e2                	ld	s1,24(sp)
    80002f1c:	6942                	ld	s2,16(sp)
    80002f1e:	69a2                	ld	s3,8(sp)
    80002f20:	6a02                	ld	s4,0(sp)
    80002f22:	6145                	addi	sp,sp,48
    80002f24:	8082                	ret
    panic("iget: no inodes");
    80002f26:	00004517          	auipc	a0,0x4
    80002f2a:	5fa50513          	addi	a0,a0,1530 # 80007520 <syscalls+0x130>
    80002f2e:	85dfd0ef          	jal	ra,8000078a <panic>

0000000080002f32 <iinit>:
{
    80002f32:	7179                	addi	sp,sp,-48
    80002f34:	f406                	sd	ra,40(sp)
    80002f36:	f022                	sd	s0,32(sp)
    80002f38:	ec26                	sd	s1,24(sp)
    80002f3a:	e84a                	sd	s2,16(sp)
    80002f3c:	e44e                	sd	s3,8(sp)
    80002f3e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80002f40:	00004597          	auipc	a1,0x4
    80002f44:	5f058593          	addi	a1,a1,1520 # 80007530 <syscalls+0x140>
    80002f48:	0001b517          	auipc	a0,0x1b
    80002f4c:	f3850513          	addi	a0,a0,-200 # 8001de80 <itable>
    80002f50:	b9dfd0ef          	jal	ra,80000aec <initlock>
  for(i = 0; i < NINODE; i++) {
    80002f54:	0001b497          	auipc	s1,0x1b
    80002f58:	f5448493          	addi	s1,s1,-172 # 8001dea8 <itable+0x28>
    80002f5c:	0001d997          	auipc	s3,0x1d
    80002f60:	9dc98993          	addi	s3,s3,-1572 # 8001f938 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80002f64:	00004917          	auipc	s2,0x4
    80002f68:	5d490913          	addi	s2,s2,1492 # 80007538 <syscalls+0x148>
    80002f6c:	85ca                	mv	a1,s2
    80002f6e:	8526                	mv	a0,s1
    80002f70:	5a9000ef          	jal	ra,80003d18 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80002f74:	08848493          	addi	s1,s1,136
    80002f78:	ff349ae3          	bne	s1,s3,80002f6c <iinit+0x3a>
}
    80002f7c:	70a2                	ld	ra,40(sp)
    80002f7e:	7402                	ld	s0,32(sp)
    80002f80:	64e2                	ld	s1,24(sp)
    80002f82:	6942                	ld	s2,16(sp)
    80002f84:	69a2                	ld	s3,8(sp)
    80002f86:	6145                	addi	sp,sp,48
    80002f88:	8082                	ret

0000000080002f8a <ialloc>:
{
    80002f8a:	715d                	addi	sp,sp,-80
    80002f8c:	e486                	sd	ra,72(sp)
    80002f8e:	e0a2                	sd	s0,64(sp)
    80002f90:	fc26                	sd	s1,56(sp)
    80002f92:	f84a                	sd	s2,48(sp)
    80002f94:	f44e                	sd	s3,40(sp)
    80002f96:	f052                	sd	s4,32(sp)
    80002f98:	ec56                	sd	s5,24(sp)
    80002f9a:	e85a                	sd	s6,16(sp)
    80002f9c:	e45e                	sd	s7,8(sp)
    80002f9e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80002fa0:	0001b717          	auipc	a4,0x1b
    80002fa4:	ecc72703          	lw	a4,-308(a4) # 8001de6c <sb+0xc>
    80002fa8:	4785                	li	a5,1
    80002faa:	04e7f663          	bgeu	a5,a4,80002ff6 <ialloc+0x6c>
    80002fae:	8aaa                	mv	s5,a0
    80002fb0:	8bae                	mv	s7,a1
    80002fb2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80002fb4:	0001ba17          	auipc	s4,0x1b
    80002fb8:	eaca0a13          	addi	s4,s4,-340 # 8001de60 <sb>
    80002fbc:	00048b1b          	sext.w	s6,s1
    80002fc0:	0044d793          	srli	a5,s1,0x4
    80002fc4:	018a2583          	lw	a1,24(s4)
    80002fc8:	9dbd                	addw	a1,a1,a5
    80002fca:	8556                	mv	a0,s5
    80002fcc:	a75ff0ef          	jal	ra,80002a40 <bread>
    80002fd0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80002fd2:	05850993          	addi	s3,a0,88
    80002fd6:	00f4f793          	andi	a5,s1,15
    80002fda:	079a                	slli	a5,a5,0x6
    80002fdc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80002fde:	00099783          	lh	a5,0(s3)
    80002fe2:	cf85                	beqz	a5,8000301a <ialloc+0x90>
    brelse(bp);
    80002fe4:	b65ff0ef          	jal	ra,80002b48 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80002fe8:	0485                	addi	s1,s1,1
    80002fea:	00ca2703          	lw	a4,12(s4)
    80002fee:	0004879b          	sext.w	a5,s1
    80002ff2:	fce7e5e3          	bltu	a5,a4,80002fbc <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80002ff6:	00004517          	auipc	a0,0x4
    80002ffa:	54a50513          	addi	a0,a0,1354 # 80007540 <syscalls+0x150>
    80002ffe:	cc6fd0ef          	jal	ra,800004c4 <printf>
  return 0;
    80003002:	4501                	li	a0,0
}
    80003004:	60a6                	ld	ra,72(sp)
    80003006:	6406                	ld	s0,64(sp)
    80003008:	74e2                	ld	s1,56(sp)
    8000300a:	7942                	ld	s2,48(sp)
    8000300c:	79a2                	ld	s3,40(sp)
    8000300e:	7a02                	ld	s4,32(sp)
    80003010:	6ae2                	ld	s5,24(sp)
    80003012:	6b42                	ld	s6,16(sp)
    80003014:	6ba2                	ld	s7,8(sp)
    80003016:	6161                	addi	sp,sp,80
    80003018:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000301a:	04000613          	li	a2,64
    8000301e:	4581                	li	a1,0
    80003020:	854e                	mv	a0,s3
    80003022:	c1ffd0ef          	jal	ra,80000c40 <memset>
      dip->type = type;
    80003026:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000302a:	854a                	mv	a0,s2
    8000302c:	429000ef          	jal	ra,80003c54 <log_write>
      brelse(bp);
    80003030:	854a                	mv	a0,s2
    80003032:	b17ff0ef          	jal	ra,80002b48 <brelse>
      return iget(dev, inum);
    80003036:	85da                	mv	a1,s6
    80003038:	8556                	mv	a0,s5
    8000303a:	e4dff0ef          	jal	ra,80002e86 <iget>
    8000303e:	b7d9                	j	80003004 <ialloc+0x7a>

0000000080003040 <iupdate>:
{
    80003040:	1101                	addi	sp,sp,-32
    80003042:	ec06                	sd	ra,24(sp)
    80003044:	e822                	sd	s0,16(sp)
    80003046:	e426                	sd	s1,8(sp)
    80003048:	e04a                	sd	s2,0(sp)
    8000304a:	1000                	addi	s0,sp,32
    8000304c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000304e:	415c                	lw	a5,4(a0)
    80003050:	0047d79b          	srliw	a5,a5,0x4
    80003054:	0001b597          	auipc	a1,0x1b
    80003058:	e245a583          	lw	a1,-476(a1) # 8001de78 <sb+0x18>
    8000305c:	9dbd                	addw	a1,a1,a5
    8000305e:	4108                	lw	a0,0(a0)
    80003060:	9e1ff0ef          	jal	ra,80002a40 <bread>
    80003064:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003066:	05850793          	addi	a5,a0,88
    8000306a:	40c8                	lw	a0,4(s1)
    8000306c:	893d                	andi	a0,a0,15
    8000306e:	051a                	slli	a0,a0,0x6
    80003070:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003072:	04449703          	lh	a4,68(s1)
    80003076:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000307a:	04649703          	lh	a4,70(s1)
    8000307e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003082:	04849703          	lh	a4,72(s1)
    80003086:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000308a:	04a49703          	lh	a4,74(s1)
    8000308e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003092:	44f8                	lw	a4,76(s1)
    80003094:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003096:	03400613          	li	a2,52
    8000309a:	05048593          	addi	a1,s1,80
    8000309e:	0531                	addi	a0,a0,12
    800030a0:	bfdfd0ef          	jal	ra,80000c9c <memmove>
  log_write(bp);
    800030a4:	854a                	mv	a0,s2
    800030a6:	3af000ef          	jal	ra,80003c54 <log_write>
  brelse(bp);
    800030aa:	854a                	mv	a0,s2
    800030ac:	a9dff0ef          	jal	ra,80002b48 <brelse>
}
    800030b0:	60e2                	ld	ra,24(sp)
    800030b2:	6442                	ld	s0,16(sp)
    800030b4:	64a2                	ld	s1,8(sp)
    800030b6:	6902                	ld	s2,0(sp)
    800030b8:	6105                	addi	sp,sp,32
    800030ba:	8082                	ret

00000000800030bc <idup>:
{
    800030bc:	1101                	addi	sp,sp,-32
    800030be:	ec06                	sd	ra,24(sp)
    800030c0:	e822                	sd	s0,16(sp)
    800030c2:	e426                	sd	s1,8(sp)
    800030c4:	1000                	addi	s0,sp,32
    800030c6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800030c8:	0001b517          	auipc	a0,0x1b
    800030cc:	db850513          	addi	a0,a0,-584 # 8001de80 <itable>
    800030d0:	a9dfd0ef          	jal	ra,80000b6c <acquire>
  ip->ref++;
    800030d4:	449c                	lw	a5,8(s1)
    800030d6:	2785                	addiw	a5,a5,1
    800030d8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800030da:	0001b517          	auipc	a0,0x1b
    800030de:	da650513          	addi	a0,a0,-602 # 8001de80 <itable>
    800030e2:	b23fd0ef          	jal	ra,80000c04 <release>
}
    800030e6:	8526                	mv	a0,s1
    800030e8:	60e2                	ld	ra,24(sp)
    800030ea:	6442                	ld	s0,16(sp)
    800030ec:	64a2                	ld	s1,8(sp)
    800030ee:	6105                	addi	sp,sp,32
    800030f0:	8082                	ret

00000000800030f2 <ilock>:
{
    800030f2:	1101                	addi	sp,sp,-32
    800030f4:	ec06                	sd	ra,24(sp)
    800030f6:	e822                	sd	s0,16(sp)
    800030f8:	e426                	sd	s1,8(sp)
    800030fa:	e04a                	sd	s2,0(sp)
    800030fc:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800030fe:	c105                	beqz	a0,8000311e <ilock+0x2c>
    80003100:	84aa                	mv	s1,a0
    80003102:	451c                	lw	a5,8(a0)
    80003104:	00f05d63          	blez	a5,8000311e <ilock+0x2c>
  acquiresleep(&ip->lock);
    80003108:	0541                	addi	a0,a0,16
    8000310a:	445000ef          	jal	ra,80003d4e <acquiresleep>
  if(ip->valid == 0){
    8000310e:	40bc                	lw	a5,64(s1)
    80003110:	cf89                	beqz	a5,8000312a <ilock+0x38>
}
    80003112:	60e2                	ld	ra,24(sp)
    80003114:	6442                	ld	s0,16(sp)
    80003116:	64a2                	ld	s1,8(sp)
    80003118:	6902                	ld	s2,0(sp)
    8000311a:	6105                	addi	sp,sp,32
    8000311c:	8082                	ret
    panic("ilock");
    8000311e:	00004517          	auipc	a0,0x4
    80003122:	43a50513          	addi	a0,a0,1082 # 80007558 <syscalls+0x168>
    80003126:	e64fd0ef          	jal	ra,8000078a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000312a:	40dc                	lw	a5,4(s1)
    8000312c:	0047d79b          	srliw	a5,a5,0x4
    80003130:	0001b597          	auipc	a1,0x1b
    80003134:	d485a583          	lw	a1,-696(a1) # 8001de78 <sb+0x18>
    80003138:	9dbd                	addw	a1,a1,a5
    8000313a:	4088                	lw	a0,0(s1)
    8000313c:	905ff0ef          	jal	ra,80002a40 <bread>
    80003140:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003142:	05850593          	addi	a1,a0,88
    80003146:	40dc                	lw	a5,4(s1)
    80003148:	8bbd                	andi	a5,a5,15
    8000314a:	079a                	slli	a5,a5,0x6
    8000314c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000314e:	00059783          	lh	a5,0(a1)
    80003152:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003156:	00259783          	lh	a5,2(a1)
    8000315a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000315e:	00459783          	lh	a5,4(a1)
    80003162:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003166:	00659783          	lh	a5,6(a1)
    8000316a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000316e:	459c                	lw	a5,8(a1)
    80003170:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003172:	03400613          	li	a2,52
    80003176:	05b1                	addi	a1,a1,12
    80003178:	05048513          	addi	a0,s1,80
    8000317c:	b21fd0ef          	jal	ra,80000c9c <memmove>
    brelse(bp);
    80003180:	854a                	mv	a0,s2
    80003182:	9c7ff0ef          	jal	ra,80002b48 <brelse>
    ip->valid = 1;
    80003186:	4785                	li	a5,1
    80003188:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000318a:	04449783          	lh	a5,68(s1)
    8000318e:	f3d1                	bnez	a5,80003112 <ilock+0x20>
      panic("ilock: no type");
    80003190:	00004517          	auipc	a0,0x4
    80003194:	3d050513          	addi	a0,a0,976 # 80007560 <syscalls+0x170>
    80003198:	df2fd0ef          	jal	ra,8000078a <panic>

000000008000319c <iunlock>:
{
    8000319c:	1101                	addi	sp,sp,-32
    8000319e:	ec06                	sd	ra,24(sp)
    800031a0:	e822                	sd	s0,16(sp)
    800031a2:	e426                	sd	s1,8(sp)
    800031a4:	e04a                	sd	s2,0(sp)
    800031a6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800031a8:	c505                	beqz	a0,800031d0 <iunlock+0x34>
    800031aa:	84aa                	mv	s1,a0
    800031ac:	01050913          	addi	s2,a0,16
    800031b0:	854a                	mv	a0,s2
    800031b2:	41b000ef          	jal	ra,80003dcc <holdingsleep>
    800031b6:	cd09                	beqz	a0,800031d0 <iunlock+0x34>
    800031b8:	449c                	lw	a5,8(s1)
    800031ba:	00f05b63          	blez	a5,800031d0 <iunlock+0x34>
  releasesleep(&ip->lock);
    800031be:	854a                	mv	a0,s2
    800031c0:	3d5000ef          	jal	ra,80003d94 <releasesleep>
}
    800031c4:	60e2                	ld	ra,24(sp)
    800031c6:	6442                	ld	s0,16(sp)
    800031c8:	64a2                	ld	s1,8(sp)
    800031ca:	6902                	ld	s2,0(sp)
    800031cc:	6105                	addi	sp,sp,32
    800031ce:	8082                	ret
    panic("iunlock");
    800031d0:	00004517          	auipc	a0,0x4
    800031d4:	3a050513          	addi	a0,a0,928 # 80007570 <syscalls+0x180>
    800031d8:	db2fd0ef          	jal	ra,8000078a <panic>

00000000800031dc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800031dc:	7179                	addi	sp,sp,-48
    800031de:	f406                	sd	ra,40(sp)
    800031e0:	f022                	sd	s0,32(sp)
    800031e2:	ec26                	sd	s1,24(sp)
    800031e4:	e84a                	sd	s2,16(sp)
    800031e6:	e44e                	sd	s3,8(sp)
    800031e8:	e052                	sd	s4,0(sp)
    800031ea:	1800                	addi	s0,sp,48
    800031ec:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800031ee:	05050493          	addi	s1,a0,80
    800031f2:	08050913          	addi	s2,a0,128
    800031f6:	a021                	j	800031fe <itrunc+0x22>
    800031f8:	0491                	addi	s1,s1,4
    800031fa:	01248b63          	beq	s1,s2,80003210 <itrunc+0x34>
    if(ip->addrs[i]){
    800031fe:	408c                	lw	a1,0(s1)
    80003200:	dde5                	beqz	a1,800031f8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003202:	0009a503          	lw	a0,0(s3)
    80003206:	a35ff0ef          	jal	ra,80002c3a <bfree>
      ip->addrs[i] = 0;
    8000320a:	0004a023          	sw	zero,0(s1)
    8000320e:	b7ed                	j	800031f8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003210:	0809a583          	lw	a1,128(s3)
    80003214:	ed91                	bnez	a1,80003230 <itrunc+0x54>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003216:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000321a:	854e                	mv	a0,s3
    8000321c:	e25ff0ef          	jal	ra,80003040 <iupdate>
}
    80003220:	70a2                	ld	ra,40(sp)
    80003222:	7402                	ld	s0,32(sp)
    80003224:	64e2                	ld	s1,24(sp)
    80003226:	6942                	ld	s2,16(sp)
    80003228:	69a2                	ld	s3,8(sp)
    8000322a:	6a02                	ld	s4,0(sp)
    8000322c:	6145                	addi	sp,sp,48
    8000322e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003230:	0009a503          	lw	a0,0(s3)
    80003234:	80dff0ef          	jal	ra,80002a40 <bread>
    80003238:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000323a:	05850493          	addi	s1,a0,88
    8000323e:	45850913          	addi	s2,a0,1112
    80003242:	a021                	j	8000324a <itrunc+0x6e>
    80003244:	0491                	addi	s1,s1,4
    80003246:	01248963          	beq	s1,s2,80003258 <itrunc+0x7c>
      if(a[j])
    8000324a:	408c                	lw	a1,0(s1)
    8000324c:	dde5                	beqz	a1,80003244 <itrunc+0x68>
        bfree(ip->dev, a[j]);
    8000324e:	0009a503          	lw	a0,0(s3)
    80003252:	9e9ff0ef          	jal	ra,80002c3a <bfree>
    80003256:	b7fd                	j	80003244 <itrunc+0x68>
    brelse(bp);
    80003258:	8552                	mv	a0,s4
    8000325a:	8efff0ef          	jal	ra,80002b48 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000325e:	0809a583          	lw	a1,128(s3)
    80003262:	0009a503          	lw	a0,0(s3)
    80003266:	9d5ff0ef          	jal	ra,80002c3a <bfree>
    ip->addrs[NDIRECT] = 0;
    8000326a:	0809a023          	sw	zero,128(s3)
    8000326e:	b765                	j	80003216 <itrunc+0x3a>

0000000080003270 <iput>:
{
    80003270:	1101                	addi	sp,sp,-32
    80003272:	ec06                	sd	ra,24(sp)
    80003274:	e822                	sd	s0,16(sp)
    80003276:	e426                	sd	s1,8(sp)
    80003278:	e04a                	sd	s2,0(sp)
    8000327a:	1000                	addi	s0,sp,32
    8000327c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000327e:	0001b517          	auipc	a0,0x1b
    80003282:	c0250513          	addi	a0,a0,-1022 # 8001de80 <itable>
    80003286:	8e7fd0ef          	jal	ra,80000b6c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000328a:	4498                	lw	a4,8(s1)
    8000328c:	4785                	li	a5,1
    8000328e:	02f70163          	beq	a4,a5,800032b0 <iput+0x40>
  ip->ref--;
    80003292:	449c                	lw	a5,8(s1)
    80003294:	37fd                	addiw	a5,a5,-1
    80003296:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003298:	0001b517          	auipc	a0,0x1b
    8000329c:	be850513          	addi	a0,a0,-1048 # 8001de80 <itable>
    800032a0:	965fd0ef          	jal	ra,80000c04 <release>
}
    800032a4:	60e2                	ld	ra,24(sp)
    800032a6:	6442                	ld	s0,16(sp)
    800032a8:	64a2                	ld	s1,8(sp)
    800032aa:	6902                	ld	s2,0(sp)
    800032ac:	6105                	addi	sp,sp,32
    800032ae:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800032b0:	40bc                	lw	a5,64(s1)
    800032b2:	d3e5                	beqz	a5,80003292 <iput+0x22>
    800032b4:	04a49783          	lh	a5,74(s1)
    800032b8:	ffe9                	bnez	a5,80003292 <iput+0x22>
    acquiresleep(&ip->lock);
    800032ba:	01048913          	addi	s2,s1,16
    800032be:	854a                	mv	a0,s2
    800032c0:	28f000ef          	jal	ra,80003d4e <acquiresleep>
    release(&itable.lock);
    800032c4:	0001b517          	auipc	a0,0x1b
    800032c8:	bbc50513          	addi	a0,a0,-1092 # 8001de80 <itable>
    800032cc:	939fd0ef          	jal	ra,80000c04 <release>
    itrunc(ip);
    800032d0:	8526                	mv	a0,s1
    800032d2:	f0bff0ef          	jal	ra,800031dc <itrunc>
    ip->type = 0;
    800032d6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800032da:	8526                	mv	a0,s1
    800032dc:	d65ff0ef          	jal	ra,80003040 <iupdate>
    ip->valid = 0;
    800032e0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800032e4:	854a                	mv	a0,s2
    800032e6:	2af000ef          	jal	ra,80003d94 <releasesleep>
    acquire(&itable.lock);
    800032ea:	0001b517          	auipc	a0,0x1b
    800032ee:	b9650513          	addi	a0,a0,-1130 # 8001de80 <itable>
    800032f2:	87bfd0ef          	jal	ra,80000b6c <acquire>
    800032f6:	bf71                	j	80003292 <iput+0x22>

00000000800032f8 <iunlockput>:
{
    800032f8:	1101                	addi	sp,sp,-32
    800032fa:	ec06                	sd	ra,24(sp)
    800032fc:	e822                	sd	s0,16(sp)
    800032fe:	e426                	sd	s1,8(sp)
    80003300:	1000                	addi	s0,sp,32
    80003302:	84aa                	mv	s1,a0
  iunlock(ip);
    80003304:	e99ff0ef          	jal	ra,8000319c <iunlock>
  iput(ip);
    80003308:	8526                	mv	a0,s1
    8000330a:	f67ff0ef          	jal	ra,80003270 <iput>
}
    8000330e:	60e2                	ld	ra,24(sp)
    80003310:	6442                	ld	s0,16(sp)
    80003312:	64a2                	ld	s1,8(sp)
    80003314:	6105                	addi	sp,sp,32
    80003316:	8082                	ret

0000000080003318 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003318:	0001b717          	auipc	a4,0x1b
    8000331c:	b5472703          	lw	a4,-1196(a4) # 8001de6c <sb+0xc>
    80003320:	4785                	li	a5,1
    80003322:	0ae7ff63          	bgeu	a5,a4,800033e0 <ireclaim+0xc8>
{
    80003326:	7139                	addi	sp,sp,-64
    80003328:	fc06                	sd	ra,56(sp)
    8000332a:	f822                	sd	s0,48(sp)
    8000332c:	f426                	sd	s1,40(sp)
    8000332e:	f04a                	sd	s2,32(sp)
    80003330:	ec4e                	sd	s3,24(sp)
    80003332:	e852                	sd	s4,16(sp)
    80003334:	e456                	sd	s5,8(sp)
    80003336:	e05a                	sd	s6,0(sp)
    80003338:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    8000333a:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    8000333c:	00050a1b          	sext.w	s4,a0
    80003340:	0001ba97          	auipc	s5,0x1b
    80003344:	b20a8a93          	addi	s5,s5,-1248 # 8001de60 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    80003348:	00004b17          	auipc	s6,0x4
    8000334c:	230b0b13          	addi	s6,s6,560 # 80007578 <syscalls+0x188>
    80003350:	a099                	j	80003396 <ireclaim+0x7e>
    80003352:	85ce                	mv	a1,s3
    80003354:	855a                	mv	a0,s6
    80003356:	96efd0ef          	jal	ra,800004c4 <printf>
      ip = iget(dev, inum);
    8000335a:	85ce                	mv	a1,s3
    8000335c:	8552                	mv	a0,s4
    8000335e:	b29ff0ef          	jal	ra,80002e86 <iget>
    80003362:	89aa                	mv	s3,a0
    brelse(bp);
    80003364:	854a                	mv	a0,s2
    80003366:	fe2ff0ef          	jal	ra,80002b48 <brelse>
    if (ip) {
    8000336a:	00098f63          	beqz	s3,80003388 <ireclaim+0x70>
      begin_op();
    8000336e:	762000ef          	jal	ra,80003ad0 <begin_op>
      ilock(ip);
    80003372:	854e                	mv	a0,s3
    80003374:	d7fff0ef          	jal	ra,800030f2 <ilock>
      iunlock(ip);
    80003378:	854e                	mv	a0,s3
    8000337a:	e23ff0ef          	jal	ra,8000319c <iunlock>
      iput(ip);
    8000337e:	854e                	mv	a0,s3
    80003380:	ef1ff0ef          	jal	ra,80003270 <iput>
      end_op();
    80003384:	7bc000ef          	jal	ra,80003b40 <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003388:	0485                	addi	s1,s1,1
    8000338a:	00caa703          	lw	a4,12(s5)
    8000338e:	0004879b          	sext.w	a5,s1
    80003392:	02e7fd63          	bgeu	a5,a4,800033cc <ireclaim+0xb4>
    80003396:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    8000339a:	0044d793          	srli	a5,s1,0x4
    8000339e:	018aa583          	lw	a1,24(s5)
    800033a2:	9dbd                	addw	a1,a1,a5
    800033a4:	8552                	mv	a0,s4
    800033a6:	e9aff0ef          	jal	ra,80002a40 <bread>
    800033aa:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    800033ac:	05850793          	addi	a5,a0,88
    800033b0:	00f9f713          	andi	a4,s3,15
    800033b4:	071a                	slli	a4,a4,0x6
    800033b6:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    800033b8:	00079703          	lh	a4,0(a5)
    800033bc:	c701                	beqz	a4,800033c4 <ireclaim+0xac>
    800033be:	00679783          	lh	a5,6(a5)
    800033c2:	dbc1                	beqz	a5,80003352 <ireclaim+0x3a>
    brelse(bp);
    800033c4:	854a                	mv	a0,s2
    800033c6:	f82ff0ef          	jal	ra,80002b48 <brelse>
    if (ip) {
    800033ca:	bf7d                	j	80003388 <ireclaim+0x70>
}
    800033cc:	70e2                	ld	ra,56(sp)
    800033ce:	7442                	ld	s0,48(sp)
    800033d0:	74a2                	ld	s1,40(sp)
    800033d2:	7902                	ld	s2,32(sp)
    800033d4:	69e2                	ld	s3,24(sp)
    800033d6:	6a42                	ld	s4,16(sp)
    800033d8:	6aa2                	ld	s5,8(sp)
    800033da:	6b02                	ld	s6,0(sp)
    800033dc:	6121                	addi	sp,sp,64
    800033de:	8082                	ret
    800033e0:	8082                	ret

00000000800033e2 <fsinit>:
fsinit(int dev) {
    800033e2:	7179                	addi	sp,sp,-48
    800033e4:	f406                	sd	ra,40(sp)
    800033e6:	f022                	sd	s0,32(sp)
    800033e8:	ec26                	sd	s1,24(sp)
    800033ea:	e84a                	sd	s2,16(sp)
    800033ec:	e44e                	sd	s3,8(sp)
    800033ee:	1800                	addi	s0,sp,48
    800033f0:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    800033f2:	4585                	li	a1,1
    800033f4:	e4cff0ef          	jal	ra,80002a40 <bread>
    800033f8:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033fa:	0001b997          	auipc	s3,0x1b
    800033fe:	a6698993          	addi	s3,s3,-1434 # 8001de60 <sb>
    80003402:	02000613          	li	a2,32
    80003406:	05850593          	addi	a1,a0,88
    8000340a:	854e                	mv	a0,s3
    8000340c:	891fd0ef          	jal	ra,80000c9c <memmove>
  brelse(bp);
    80003410:	854a                	mv	a0,s2
    80003412:	f36ff0ef          	jal	ra,80002b48 <brelse>
  if(sb.magic != FSMAGIC)
    80003416:	0009a703          	lw	a4,0(s3)
    8000341a:	102037b7          	lui	a5,0x10203
    8000341e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003422:	02f71363          	bne	a4,a5,80003448 <fsinit+0x66>
  initlog(dev, &sb);
    80003426:	0001b597          	auipc	a1,0x1b
    8000342a:	a3a58593          	addi	a1,a1,-1478 # 8001de60 <sb>
    8000342e:	8526                	mv	a0,s1
    80003430:	616000ef          	jal	ra,80003a46 <initlog>
  ireclaim(dev);
    80003434:	8526                	mv	a0,s1
    80003436:	ee3ff0ef          	jal	ra,80003318 <ireclaim>
}
    8000343a:	70a2                	ld	ra,40(sp)
    8000343c:	7402                	ld	s0,32(sp)
    8000343e:	64e2                	ld	s1,24(sp)
    80003440:	6942                	ld	s2,16(sp)
    80003442:	69a2                	ld	s3,8(sp)
    80003444:	6145                	addi	sp,sp,48
    80003446:	8082                	ret
    panic("invalid file system");
    80003448:	00004517          	auipc	a0,0x4
    8000344c:	15050513          	addi	a0,a0,336 # 80007598 <syscalls+0x1a8>
    80003450:	b3afd0ef          	jal	ra,8000078a <panic>

0000000080003454 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003454:	1141                	addi	sp,sp,-16
    80003456:	e422                	sd	s0,8(sp)
    80003458:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000345a:	411c                	lw	a5,0(a0)
    8000345c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000345e:	415c                	lw	a5,4(a0)
    80003460:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003462:	04451783          	lh	a5,68(a0)
    80003466:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000346a:	04a51783          	lh	a5,74(a0)
    8000346e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003472:	04c56783          	lwu	a5,76(a0)
    80003476:	e99c                	sd	a5,16(a1)
}
    80003478:	6422                	ld	s0,8(sp)
    8000347a:	0141                	addi	sp,sp,16
    8000347c:	8082                	ret

000000008000347e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000347e:	457c                	lw	a5,76(a0)
    80003480:	0cd7ef63          	bltu	a5,a3,8000355e <readi+0xe0>
{
    80003484:	7159                	addi	sp,sp,-112
    80003486:	f486                	sd	ra,104(sp)
    80003488:	f0a2                	sd	s0,96(sp)
    8000348a:	eca6                	sd	s1,88(sp)
    8000348c:	e8ca                	sd	s2,80(sp)
    8000348e:	e4ce                	sd	s3,72(sp)
    80003490:	e0d2                	sd	s4,64(sp)
    80003492:	fc56                	sd	s5,56(sp)
    80003494:	f85a                	sd	s6,48(sp)
    80003496:	f45e                	sd	s7,40(sp)
    80003498:	f062                	sd	s8,32(sp)
    8000349a:	ec66                	sd	s9,24(sp)
    8000349c:	e86a                	sd	s10,16(sp)
    8000349e:	e46e                	sd	s11,8(sp)
    800034a0:	1880                	addi	s0,sp,112
    800034a2:	8b2a                	mv	s6,a0
    800034a4:	8bae                	mv	s7,a1
    800034a6:	8a32                	mv	s4,a2
    800034a8:	84b6                	mv	s1,a3
    800034aa:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800034ac:	9f35                	addw	a4,a4,a3
    return 0;
    800034ae:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800034b0:	08d76663          	bltu	a4,a3,8000353c <readi+0xbe>
  if(off + n > ip->size)
    800034b4:	00e7f463          	bgeu	a5,a4,800034bc <readi+0x3e>
    n = ip->size - off;
    800034b8:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800034bc:	080a8f63          	beqz	s5,8000355a <readi+0xdc>
    800034c0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800034c2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800034c6:	5c7d                	li	s8,-1
    800034c8:	a80d                	j	800034fa <readi+0x7c>
    800034ca:	020d1d93          	slli	s11,s10,0x20
    800034ce:	020ddd93          	srli	s11,s11,0x20
    800034d2:	05890793          	addi	a5,s2,88
    800034d6:	86ee                	mv	a3,s11
    800034d8:	963e                	add	a2,a2,a5
    800034da:	85d2                	mv	a1,s4
    800034dc:	855e                	mv	a0,s7
    800034de:	c8bfe0ef          	jal	ra,80002168 <either_copyout>
    800034e2:	05850763          	beq	a0,s8,80003530 <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800034e6:	854a                	mv	a0,s2
    800034e8:	e60ff0ef          	jal	ra,80002b48 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800034ec:	013d09bb          	addw	s3,s10,s3
    800034f0:	009d04bb          	addw	s1,s10,s1
    800034f4:	9a6e                	add	s4,s4,s11
    800034f6:	0559f163          	bgeu	s3,s5,80003538 <readi+0xba>
    uint addr = bmap(ip, off/BSIZE);
    800034fa:	00a4d59b          	srliw	a1,s1,0xa
    800034fe:	855a                	mv	a0,s6
    80003500:	8bbff0ef          	jal	ra,80002dba <bmap>
    80003504:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003508:	c985                	beqz	a1,80003538 <readi+0xba>
    bp = bread(ip->dev, addr);
    8000350a:	000b2503          	lw	a0,0(s6)
    8000350e:	d32ff0ef          	jal	ra,80002a40 <bread>
    80003512:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003514:	3ff4f613          	andi	a2,s1,1023
    80003518:	40cc87bb          	subw	a5,s9,a2
    8000351c:	413a873b          	subw	a4,s5,s3
    80003520:	8d3e                	mv	s10,a5
    80003522:	2781                	sext.w	a5,a5
    80003524:	0007069b          	sext.w	a3,a4
    80003528:	faf6f1e3          	bgeu	a3,a5,800034ca <readi+0x4c>
    8000352c:	8d3a                	mv	s10,a4
    8000352e:	bf71                	j	800034ca <readi+0x4c>
      brelse(bp);
    80003530:	854a                	mv	a0,s2
    80003532:	e16ff0ef          	jal	ra,80002b48 <brelse>
      tot = -1;
    80003536:	59fd                	li	s3,-1
  }
  return tot;
    80003538:	0009851b          	sext.w	a0,s3
}
    8000353c:	70a6                	ld	ra,104(sp)
    8000353e:	7406                	ld	s0,96(sp)
    80003540:	64e6                	ld	s1,88(sp)
    80003542:	6946                	ld	s2,80(sp)
    80003544:	69a6                	ld	s3,72(sp)
    80003546:	6a06                	ld	s4,64(sp)
    80003548:	7ae2                	ld	s5,56(sp)
    8000354a:	7b42                	ld	s6,48(sp)
    8000354c:	7ba2                	ld	s7,40(sp)
    8000354e:	7c02                	ld	s8,32(sp)
    80003550:	6ce2                	ld	s9,24(sp)
    80003552:	6d42                	ld	s10,16(sp)
    80003554:	6da2                	ld	s11,8(sp)
    80003556:	6165                	addi	sp,sp,112
    80003558:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000355a:	89d6                	mv	s3,s5
    8000355c:	bff1                	j	80003538 <readi+0xba>
    return 0;
    8000355e:	4501                	li	a0,0
}
    80003560:	8082                	ret

0000000080003562 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003562:	457c                	lw	a5,76(a0)
    80003564:	0ed7ea63          	bltu	a5,a3,80003658 <writei+0xf6>
{
    80003568:	7159                	addi	sp,sp,-112
    8000356a:	f486                	sd	ra,104(sp)
    8000356c:	f0a2                	sd	s0,96(sp)
    8000356e:	eca6                	sd	s1,88(sp)
    80003570:	e8ca                	sd	s2,80(sp)
    80003572:	e4ce                	sd	s3,72(sp)
    80003574:	e0d2                	sd	s4,64(sp)
    80003576:	fc56                	sd	s5,56(sp)
    80003578:	f85a                	sd	s6,48(sp)
    8000357a:	f45e                	sd	s7,40(sp)
    8000357c:	f062                	sd	s8,32(sp)
    8000357e:	ec66                	sd	s9,24(sp)
    80003580:	e86a                	sd	s10,16(sp)
    80003582:	e46e                	sd	s11,8(sp)
    80003584:	1880                	addi	s0,sp,112
    80003586:	8aaa                	mv	s5,a0
    80003588:	8bae                	mv	s7,a1
    8000358a:	8a32                	mv	s4,a2
    8000358c:	8936                	mv	s2,a3
    8000358e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003590:	00e687bb          	addw	a5,a3,a4
    80003594:	0cd7e463          	bltu	a5,a3,8000365c <writei+0xfa>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003598:	00043737          	lui	a4,0x43
    8000359c:	0cf76263          	bltu	a4,a5,80003660 <writei+0xfe>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800035a0:	0a0b0a63          	beqz	s6,80003654 <writei+0xf2>
    800035a4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800035a6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800035aa:	5c7d                	li	s8,-1
    800035ac:	a825                	j	800035e4 <writei+0x82>
    800035ae:	020d1d93          	slli	s11,s10,0x20
    800035b2:	020ddd93          	srli	s11,s11,0x20
    800035b6:	05848793          	addi	a5,s1,88
    800035ba:	86ee                	mv	a3,s11
    800035bc:	8652                	mv	a2,s4
    800035be:	85de                	mv	a1,s7
    800035c0:	953e                	add	a0,a0,a5
    800035c2:	bf1fe0ef          	jal	ra,800021b2 <either_copyin>
    800035c6:	05850a63          	beq	a0,s8,8000361a <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    800035ca:	8526                	mv	a0,s1
    800035cc:	688000ef          	jal	ra,80003c54 <log_write>
    brelse(bp);
    800035d0:	8526                	mv	a0,s1
    800035d2:	d76ff0ef          	jal	ra,80002b48 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800035d6:	013d09bb          	addw	s3,s10,s3
    800035da:	012d093b          	addw	s2,s10,s2
    800035de:	9a6e                	add	s4,s4,s11
    800035e0:	0569f063          	bgeu	s3,s6,80003620 <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    800035e4:	00a9559b          	srliw	a1,s2,0xa
    800035e8:	8556                	mv	a0,s5
    800035ea:	fd0ff0ef          	jal	ra,80002dba <bmap>
    800035ee:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800035f2:	c59d                	beqz	a1,80003620 <writei+0xbe>
    bp = bread(ip->dev, addr);
    800035f4:	000aa503          	lw	a0,0(s5)
    800035f8:	c48ff0ef          	jal	ra,80002a40 <bread>
    800035fc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800035fe:	3ff97513          	andi	a0,s2,1023
    80003602:	40ac87bb          	subw	a5,s9,a0
    80003606:	413b073b          	subw	a4,s6,s3
    8000360a:	8d3e                	mv	s10,a5
    8000360c:	2781                	sext.w	a5,a5
    8000360e:	0007069b          	sext.w	a3,a4
    80003612:	f8f6fee3          	bgeu	a3,a5,800035ae <writei+0x4c>
    80003616:	8d3a                	mv	s10,a4
    80003618:	bf59                	j	800035ae <writei+0x4c>
      brelse(bp);
    8000361a:	8526                	mv	a0,s1
    8000361c:	d2cff0ef          	jal	ra,80002b48 <brelse>
  }

  if(off > ip->size)
    80003620:	04caa783          	lw	a5,76(s5)
    80003624:	0127f463          	bgeu	a5,s2,8000362c <writei+0xca>
    ip->size = off;
    80003628:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000362c:	8556                	mv	a0,s5
    8000362e:	a13ff0ef          	jal	ra,80003040 <iupdate>

  return tot;
    80003632:	0009851b          	sext.w	a0,s3
}
    80003636:	70a6                	ld	ra,104(sp)
    80003638:	7406                	ld	s0,96(sp)
    8000363a:	64e6                	ld	s1,88(sp)
    8000363c:	6946                	ld	s2,80(sp)
    8000363e:	69a6                	ld	s3,72(sp)
    80003640:	6a06                	ld	s4,64(sp)
    80003642:	7ae2                	ld	s5,56(sp)
    80003644:	7b42                	ld	s6,48(sp)
    80003646:	7ba2                	ld	s7,40(sp)
    80003648:	7c02                	ld	s8,32(sp)
    8000364a:	6ce2                	ld	s9,24(sp)
    8000364c:	6d42                	ld	s10,16(sp)
    8000364e:	6da2                	ld	s11,8(sp)
    80003650:	6165                	addi	sp,sp,112
    80003652:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003654:	89da                	mv	s3,s6
    80003656:	bfd9                	j	8000362c <writei+0xca>
    return -1;
    80003658:	557d                	li	a0,-1
}
    8000365a:	8082                	ret
    return -1;
    8000365c:	557d                	li	a0,-1
    8000365e:	bfe1                	j	80003636 <writei+0xd4>
    return -1;
    80003660:	557d                	li	a0,-1
    80003662:	bfd1                	j	80003636 <writei+0xd4>

0000000080003664 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003664:	1141                	addi	sp,sp,-16
    80003666:	e406                	sd	ra,8(sp)
    80003668:	e022                	sd	s0,0(sp)
    8000366a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000366c:	4639                	li	a2,14
    8000366e:	e9efd0ef          	jal	ra,80000d0c <strncmp>
}
    80003672:	60a2                	ld	ra,8(sp)
    80003674:	6402                	ld	s0,0(sp)
    80003676:	0141                	addi	sp,sp,16
    80003678:	8082                	ret

000000008000367a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000367a:	7139                	addi	sp,sp,-64
    8000367c:	fc06                	sd	ra,56(sp)
    8000367e:	f822                	sd	s0,48(sp)
    80003680:	f426                	sd	s1,40(sp)
    80003682:	f04a                	sd	s2,32(sp)
    80003684:	ec4e                	sd	s3,24(sp)
    80003686:	e852                	sd	s4,16(sp)
    80003688:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000368a:	04451703          	lh	a4,68(a0)
    8000368e:	4785                	li	a5,1
    80003690:	00f71a63          	bne	a4,a5,800036a4 <dirlookup+0x2a>
    80003694:	892a                	mv	s2,a0
    80003696:	89ae                	mv	s3,a1
    80003698:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000369a:	457c                	lw	a5,76(a0)
    8000369c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000369e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800036a0:	e39d                	bnez	a5,800036c6 <dirlookup+0x4c>
    800036a2:	a095                	j	80003706 <dirlookup+0x8c>
    panic("dirlookup not DIR");
    800036a4:	00004517          	auipc	a0,0x4
    800036a8:	f0c50513          	addi	a0,a0,-244 # 800075b0 <syscalls+0x1c0>
    800036ac:	8defd0ef          	jal	ra,8000078a <panic>
      panic("dirlookup read");
    800036b0:	00004517          	auipc	a0,0x4
    800036b4:	f1850513          	addi	a0,a0,-232 # 800075c8 <syscalls+0x1d8>
    800036b8:	8d2fd0ef          	jal	ra,8000078a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800036bc:	24c1                	addiw	s1,s1,16
    800036be:	04c92783          	lw	a5,76(s2)
    800036c2:	04f4f163          	bgeu	s1,a5,80003704 <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800036c6:	4741                	li	a4,16
    800036c8:	86a6                	mv	a3,s1
    800036ca:	fc040613          	addi	a2,s0,-64
    800036ce:	4581                	li	a1,0
    800036d0:	854a                	mv	a0,s2
    800036d2:	dadff0ef          	jal	ra,8000347e <readi>
    800036d6:	47c1                	li	a5,16
    800036d8:	fcf51ce3          	bne	a0,a5,800036b0 <dirlookup+0x36>
    if(de.inum == 0)
    800036dc:	fc045783          	lhu	a5,-64(s0)
    800036e0:	dff1                	beqz	a5,800036bc <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    800036e2:	fc240593          	addi	a1,s0,-62
    800036e6:	854e                	mv	a0,s3
    800036e8:	f7dff0ef          	jal	ra,80003664 <namecmp>
    800036ec:	f961                	bnez	a0,800036bc <dirlookup+0x42>
      if(poff)
    800036ee:	000a0463          	beqz	s4,800036f6 <dirlookup+0x7c>
        *poff = off;
    800036f2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800036f6:	fc045583          	lhu	a1,-64(s0)
    800036fa:	00092503          	lw	a0,0(s2)
    800036fe:	f88ff0ef          	jal	ra,80002e86 <iget>
    80003702:	a011                	j	80003706 <dirlookup+0x8c>
  return 0;
    80003704:	4501                	li	a0,0
}
    80003706:	70e2                	ld	ra,56(sp)
    80003708:	7442                	ld	s0,48(sp)
    8000370a:	74a2                	ld	s1,40(sp)
    8000370c:	7902                	ld	s2,32(sp)
    8000370e:	69e2                	ld	s3,24(sp)
    80003710:	6a42                	ld	s4,16(sp)
    80003712:	6121                	addi	sp,sp,64
    80003714:	8082                	ret

0000000080003716 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003716:	711d                	addi	sp,sp,-96
    80003718:	ec86                	sd	ra,88(sp)
    8000371a:	e8a2                	sd	s0,80(sp)
    8000371c:	e4a6                	sd	s1,72(sp)
    8000371e:	e0ca                	sd	s2,64(sp)
    80003720:	fc4e                	sd	s3,56(sp)
    80003722:	f852                	sd	s4,48(sp)
    80003724:	f456                	sd	s5,40(sp)
    80003726:	f05a                	sd	s6,32(sp)
    80003728:	ec5e                	sd	s7,24(sp)
    8000372a:	e862                	sd	s8,16(sp)
    8000372c:	e466                	sd	s9,8(sp)
    8000372e:	1080                	addi	s0,sp,96
    80003730:	84aa                	mv	s1,a0
    80003732:	8aae                	mv	s5,a1
    80003734:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003736:	00054703          	lbu	a4,0(a0)
    8000373a:	02f00793          	li	a5,47
    8000373e:	00f70f63          	beq	a4,a5,8000375c <namex+0x46>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003742:	8c2fe0ef          	jal	ra,80001804 <myproc>
    80003746:	15053503          	ld	a0,336(a0)
    8000374a:	973ff0ef          	jal	ra,800030bc <idup>
    8000374e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003750:	02f00913          	li	s2,47
  len = path - s;
    80003754:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003756:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003758:	4b85                	li	s7,1
    8000375a:	a861                	j	800037f2 <namex+0xdc>
    ip = iget(ROOTDEV, ROOTINO);
    8000375c:	4585                	li	a1,1
    8000375e:	4505                	li	a0,1
    80003760:	f26ff0ef          	jal	ra,80002e86 <iget>
    80003764:	89aa                	mv	s3,a0
    80003766:	b7ed                	j	80003750 <namex+0x3a>
      iunlockput(ip);
    80003768:	854e                	mv	a0,s3
    8000376a:	b8fff0ef          	jal	ra,800032f8 <iunlockput>
      return 0;
    8000376e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003770:	854e                	mv	a0,s3
    80003772:	60e6                	ld	ra,88(sp)
    80003774:	6446                	ld	s0,80(sp)
    80003776:	64a6                	ld	s1,72(sp)
    80003778:	6906                	ld	s2,64(sp)
    8000377a:	79e2                	ld	s3,56(sp)
    8000377c:	7a42                	ld	s4,48(sp)
    8000377e:	7aa2                	ld	s5,40(sp)
    80003780:	7b02                	ld	s6,32(sp)
    80003782:	6be2                	ld	s7,24(sp)
    80003784:	6c42                	ld	s8,16(sp)
    80003786:	6ca2                	ld	s9,8(sp)
    80003788:	6125                	addi	sp,sp,96
    8000378a:	8082                	ret
      iunlock(ip);
    8000378c:	854e                	mv	a0,s3
    8000378e:	a0fff0ef          	jal	ra,8000319c <iunlock>
      return ip;
    80003792:	bff9                	j	80003770 <namex+0x5a>
      iunlockput(ip);
    80003794:	854e                	mv	a0,s3
    80003796:	b63ff0ef          	jal	ra,800032f8 <iunlockput>
      return 0;
    8000379a:	89e6                	mv	s3,s9
    8000379c:	bfd1                	j	80003770 <namex+0x5a>
  len = path - s;
    8000379e:	40b48633          	sub	a2,s1,a1
    800037a2:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800037a6:	079c5c63          	bge	s8,s9,8000381e <namex+0x108>
    memmove(name, s, DIRSIZ);
    800037aa:	4639                	li	a2,14
    800037ac:	8552                	mv	a0,s4
    800037ae:	ceefd0ef          	jal	ra,80000c9c <memmove>
  while(*path == '/')
    800037b2:	0004c783          	lbu	a5,0(s1)
    800037b6:	01279763          	bne	a5,s2,800037c4 <namex+0xae>
    path++;
    800037ba:	0485                	addi	s1,s1,1
  while(*path == '/')
    800037bc:	0004c783          	lbu	a5,0(s1)
    800037c0:	ff278de3          	beq	a5,s2,800037ba <namex+0xa4>
    ilock(ip);
    800037c4:	854e                	mv	a0,s3
    800037c6:	92dff0ef          	jal	ra,800030f2 <ilock>
    if(ip->type != T_DIR){
    800037ca:	04499783          	lh	a5,68(s3)
    800037ce:	f9779de3          	bne	a5,s7,80003768 <namex+0x52>
    if(nameiparent && *path == '\0'){
    800037d2:	000a8563          	beqz	s5,800037dc <namex+0xc6>
    800037d6:	0004c783          	lbu	a5,0(s1)
    800037da:	dbcd                	beqz	a5,8000378c <namex+0x76>
    if((next = dirlookup(ip, name, 0)) == 0){
    800037dc:	865a                	mv	a2,s6
    800037de:	85d2                	mv	a1,s4
    800037e0:	854e                	mv	a0,s3
    800037e2:	e99ff0ef          	jal	ra,8000367a <dirlookup>
    800037e6:	8caa                	mv	s9,a0
    800037e8:	d555                	beqz	a0,80003794 <namex+0x7e>
    iunlockput(ip);
    800037ea:	854e                	mv	a0,s3
    800037ec:	b0dff0ef          	jal	ra,800032f8 <iunlockput>
    ip = next;
    800037f0:	89e6                	mv	s3,s9
  while(*path == '/')
    800037f2:	0004c783          	lbu	a5,0(s1)
    800037f6:	05279363          	bne	a5,s2,8000383c <namex+0x126>
    path++;
    800037fa:	0485                	addi	s1,s1,1
  while(*path == '/')
    800037fc:	0004c783          	lbu	a5,0(s1)
    80003800:	ff278de3          	beq	a5,s2,800037fa <namex+0xe4>
  if(*path == 0)
    80003804:	c78d                	beqz	a5,8000382e <namex+0x118>
    path++;
    80003806:	85a6                	mv	a1,s1
  len = path - s;
    80003808:	8cda                	mv	s9,s6
    8000380a:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000380c:	01278963          	beq	a5,s2,8000381e <namex+0x108>
    80003810:	d7d9                	beqz	a5,8000379e <namex+0x88>
    path++;
    80003812:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003814:	0004c783          	lbu	a5,0(s1)
    80003818:	ff279ce3          	bne	a5,s2,80003810 <namex+0xfa>
    8000381c:	b749                	j	8000379e <namex+0x88>
    memmove(name, s, len);
    8000381e:	2601                	sext.w	a2,a2
    80003820:	8552                	mv	a0,s4
    80003822:	c7afd0ef          	jal	ra,80000c9c <memmove>
    name[len] = 0;
    80003826:	9cd2                	add	s9,s9,s4
    80003828:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000382c:	b759                	j	800037b2 <namex+0x9c>
  if(nameiparent){
    8000382e:	f40a81e3          	beqz	s5,80003770 <namex+0x5a>
    iput(ip);
    80003832:	854e                	mv	a0,s3
    80003834:	a3dff0ef          	jal	ra,80003270 <iput>
    return 0;
    80003838:	4981                	li	s3,0
    8000383a:	bf1d                	j	80003770 <namex+0x5a>
  if(*path == 0)
    8000383c:	dbed                	beqz	a5,8000382e <namex+0x118>
  while(*path != '/' && *path != 0)
    8000383e:	0004c783          	lbu	a5,0(s1)
    80003842:	85a6                	mv	a1,s1
    80003844:	b7f1                	j	80003810 <namex+0xfa>

0000000080003846 <dirlink>:
{
    80003846:	7139                	addi	sp,sp,-64
    80003848:	fc06                	sd	ra,56(sp)
    8000384a:	f822                	sd	s0,48(sp)
    8000384c:	f426                	sd	s1,40(sp)
    8000384e:	f04a                	sd	s2,32(sp)
    80003850:	ec4e                	sd	s3,24(sp)
    80003852:	e852                	sd	s4,16(sp)
    80003854:	0080                	addi	s0,sp,64
    80003856:	892a                	mv	s2,a0
    80003858:	8a2e                	mv	s4,a1
    8000385a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000385c:	4601                	li	a2,0
    8000385e:	e1dff0ef          	jal	ra,8000367a <dirlookup>
    80003862:	e52d                	bnez	a0,800038cc <dirlink+0x86>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003864:	04c92483          	lw	s1,76(s2)
    80003868:	c48d                	beqz	s1,80003892 <dirlink+0x4c>
    8000386a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000386c:	4741                	li	a4,16
    8000386e:	86a6                	mv	a3,s1
    80003870:	fc040613          	addi	a2,s0,-64
    80003874:	4581                	li	a1,0
    80003876:	854a                	mv	a0,s2
    80003878:	c07ff0ef          	jal	ra,8000347e <readi>
    8000387c:	47c1                	li	a5,16
    8000387e:	04f51b63          	bne	a0,a5,800038d4 <dirlink+0x8e>
    if(de.inum == 0)
    80003882:	fc045783          	lhu	a5,-64(s0)
    80003886:	c791                	beqz	a5,80003892 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003888:	24c1                	addiw	s1,s1,16
    8000388a:	04c92783          	lw	a5,76(s2)
    8000388e:	fcf4efe3          	bltu	s1,a5,8000386c <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80003892:	4639                	li	a2,14
    80003894:	85d2                	mv	a1,s4
    80003896:	fc240513          	addi	a0,s0,-62
    8000389a:	caefd0ef          	jal	ra,80000d48 <strncpy>
  de.inum = inum;
    8000389e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800038a2:	4741                	li	a4,16
    800038a4:	86a6                	mv	a3,s1
    800038a6:	fc040613          	addi	a2,s0,-64
    800038aa:	4581                	li	a1,0
    800038ac:	854a                	mv	a0,s2
    800038ae:	cb5ff0ef          	jal	ra,80003562 <writei>
    800038b2:	1541                	addi	a0,a0,-16
    800038b4:	00a03533          	snez	a0,a0
    800038b8:	40a00533          	neg	a0,a0
}
    800038bc:	70e2                	ld	ra,56(sp)
    800038be:	7442                	ld	s0,48(sp)
    800038c0:	74a2                	ld	s1,40(sp)
    800038c2:	7902                	ld	s2,32(sp)
    800038c4:	69e2                	ld	s3,24(sp)
    800038c6:	6a42                	ld	s4,16(sp)
    800038c8:	6121                	addi	sp,sp,64
    800038ca:	8082                	ret
    iput(ip);
    800038cc:	9a5ff0ef          	jal	ra,80003270 <iput>
    return -1;
    800038d0:	557d                	li	a0,-1
    800038d2:	b7ed                	j	800038bc <dirlink+0x76>
      panic("dirlink read");
    800038d4:	00004517          	auipc	a0,0x4
    800038d8:	d0450513          	addi	a0,a0,-764 # 800075d8 <syscalls+0x1e8>
    800038dc:	eaffc0ef          	jal	ra,8000078a <panic>

00000000800038e0 <namei>:

struct inode*
namei(char *path)
{
    800038e0:	1101                	addi	sp,sp,-32
    800038e2:	ec06                	sd	ra,24(sp)
    800038e4:	e822                	sd	s0,16(sp)
    800038e6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800038e8:	fe040613          	addi	a2,s0,-32
    800038ec:	4581                	li	a1,0
    800038ee:	e29ff0ef          	jal	ra,80003716 <namex>
}
    800038f2:	60e2                	ld	ra,24(sp)
    800038f4:	6442                	ld	s0,16(sp)
    800038f6:	6105                	addi	sp,sp,32
    800038f8:	8082                	ret

00000000800038fa <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800038fa:	1141                	addi	sp,sp,-16
    800038fc:	e406                	sd	ra,8(sp)
    800038fe:	e022                	sd	s0,0(sp)
    80003900:	0800                	addi	s0,sp,16
    80003902:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003904:	4585                	li	a1,1
    80003906:	e11ff0ef          	jal	ra,80003716 <namex>
}
    8000390a:	60a2                	ld	ra,8(sp)
    8000390c:	6402                	ld	s0,0(sp)
    8000390e:	0141                	addi	sp,sp,16
    80003910:	8082                	ret

0000000080003912 <write_head>:
  brelse(buf);  // 释放缓冲区
}

// 将内存中的日志头写回磁盘
static void write_head(void)
{
    80003912:	1101                	addi	sp,sp,-32
    80003914:	ec06                	sd	ra,24(sp)
    80003916:	e822                	sd	s0,16(sp)
    80003918:	e426                	sd	s1,8(sp)
    8000391a:	e04a                	sd	s2,0(sp)
    8000391c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000391e:	0001c917          	auipc	s2,0x1c
    80003922:	00a90913          	addi	s2,s2,10 # 8001f928 <log>
    80003926:	01892583          	lw	a1,24(s2)
    8000392a:	02492503          	lw	a0,36(s2)
    8000392e:	912ff0ef          	jal	ra,80002a40 <bread>
    80003932:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;  // 更新日志中的块数量
    80003934:	02892683          	lw	a3,40(s2)
    80003938:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000393a:	02d05763          	blez	a3,80003968 <write_head+0x56>
    8000393e:	0001c797          	auipc	a5,0x1c
    80003942:	01678793          	addi	a5,a5,22 # 8001f954 <log+0x2c>
    80003946:	05c50713          	addi	a4,a0,92
    8000394a:	36fd                	addiw	a3,a3,-1
    8000394c:	1682                	slli	a3,a3,0x20
    8000394e:	9281                	srli	a3,a3,0x20
    80003950:	068a                	slli	a3,a3,0x2
    80003952:	0001c617          	auipc	a2,0x1c
    80003956:	00660613          	addi	a2,a2,6 # 8001f958 <log+0x30>
    8000395a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];  // 更新每个日志块的块号
    8000395c:	4390                	lw	a2,0(a5)
    8000395e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003960:	0791                	addi	a5,a5,4
    80003962:	0711                	addi	a4,a4,4
    80003964:	fed79ce3          	bne	a5,a3,8000395c <write_head+0x4a>
  }
  bwrite(buf);  // 写回日志头块
    80003968:	8526                	mv	a0,s1
    8000396a:	9acff0ef          	jal	ra,80002b16 <bwrite>
  brelse(buf);  // 释放缓冲区
    8000396e:	8526                	mv	a0,s1
    80003970:	9d8ff0ef          	jal	ra,80002b48 <brelse>
}
    80003974:	60e2                	ld	ra,24(sp)
    80003976:	6442                	ld	s0,16(sp)
    80003978:	64a2                	ld	s1,8(sp)
    8000397a:	6902                	ld	s2,0(sp)
    8000397c:	6105                	addi	sp,sp,32
    8000397e:	8082                	ret

0000000080003980 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003980:	0001c797          	auipc	a5,0x1c
    80003984:	fd07a783          	lw	a5,-48(a5) # 8001f950 <log+0x28>
    80003988:	0af05e63          	blez	a5,80003a44 <install_trans+0xc4>
{
    8000398c:	715d                	addi	sp,sp,-80
    8000398e:	e486                	sd	ra,72(sp)
    80003990:	e0a2                	sd	s0,64(sp)
    80003992:	fc26                	sd	s1,56(sp)
    80003994:	f84a                	sd	s2,48(sp)
    80003996:	f44e                	sd	s3,40(sp)
    80003998:	f052                	sd	s4,32(sp)
    8000399a:	ec56                	sd	s5,24(sp)
    8000399c:	e85a                	sd	s6,16(sp)
    8000399e:	e45e                	sd	s7,8(sp)
    800039a0:	0880                	addi	s0,sp,80
    800039a2:	8b2a                	mv	s6,a0
    800039a4:	0001ca97          	auipc	s5,0x1c
    800039a8:	fb0a8a93          	addi	s5,s5,-80 # 8001f954 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800039ac:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    800039ae:	00004b97          	auipc	s7,0x4
    800039b2:	c3ab8b93          	addi	s7,s7,-966 # 800075e8 <syscalls+0x1f8>
    struct buf *lbuf = bread(log.dev, log.start + tail + 1);  // 读取日志块
    800039b6:	0001ca17          	auipc	s4,0x1c
    800039ba:	f72a0a13          	addi	s4,s4,-142 # 8001f928 <log>
    800039be:	a025                	j	800039e6 <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    800039c0:	000aa603          	lw	a2,0(s5)
    800039c4:	85ce                	mv	a1,s3
    800039c6:	855e                	mv	a0,s7
    800039c8:	afdfc0ef          	jal	ra,800004c4 <printf>
    800039cc:	a839                	j	800039ea <install_trans+0x6a>
    brelse(lbuf);  // 释放日志块
    800039ce:	854a                	mv	a0,s2
    800039d0:	978ff0ef          	jal	ra,80002b48 <brelse>
    brelse(dbuf);  // 释放目标块
    800039d4:	8526                	mv	a0,s1
    800039d6:	972ff0ef          	jal	ra,80002b48 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800039da:	2985                	addiw	s3,s3,1
    800039dc:	0a91                	addi	s5,s5,4
    800039de:	028a2783          	lw	a5,40(s4)
    800039e2:	04f9d663          	bge	s3,a5,80003a2e <install_trans+0xae>
    if(recovering) {
    800039e6:	fc0b1de3          	bnez	s6,800039c0 <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start + tail + 1);  // 读取日志块
    800039ea:	018a2583          	lw	a1,24(s4)
    800039ee:	013585bb          	addw	a1,a1,s3
    800039f2:	2585                	addiw	a1,a1,1
    800039f4:	024a2503          	lw	a0,36(s4)
    800039f8:	848ff0ef          	jal	ra,80002a40 <bread>
    800039fc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]);  // 读取目标块
    800039fe:	000aa583          	lw	a1,0(s5)
    80003a02:	024a2503          	lw	a0,36(s4)
    80003a06:	83aff0ef          	jal	ra,80002a40 <bread>
    80003a0a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);
    80003a0c:	40000613          	li	a2,1024
    80003a10:	05890593          	addi	a1,s2,88
    80003a14:	05850513          	addi	a0,a0,88
    80003a18:	a84fd0ef          	jal	ra,80000c9c <memmove>
    bwrite(dbuf);  // 将目标块写回磁盘
    80003a1c:	8526                	mv	a0,s1
    80003a1e:	8f8ff0ef          	jal	ra,80002b16 <bwrite>
    if(recovering == 0)
    80003a22:	fa0b16e3          	bnez	s6,800039ce <install_trans+0x4e>
      bunpin(dbuf);  // 提交后解锁目标块
    80003a26:	8526                	mv	a0,s1
    80003a28:	9deff0ef          	jal	ra,80002c06 <bunpin>
    80003a2c:	b74d                	j	800039ce <install_trans+0x4e>
}
    80003a2e:	60a6                	ld	ra,72(sp)
    80003a30:	6406                	ld	s0,64(sp)
    80003a32:	74e2                	ld	s1,56(sp)
    80003a34:	7942                	ld	s2,48(sp)
    80003a36:	79a2                	ld	s3,40(sp)
    80003a38:	7a02                	ld	s4,32(sp)
    80003a3a:	6ae2                	ld	s5,24(sp)
    80003a3c:	6b42                	ld	s6,16(sp)
    80003a3e:	6ba2                	ld	s7,8(sp)
    80003a40:	6161                	addi	sp,sp,80
    80003a42:	8082                	ret
    80003a44:	8082                	ret

0000000080003a46 <initlog>:
{
    80003a46:	7179                	addi	sp,sp,-48
    80003a48:	f406                	sd	ra,40(sp)
    80003a4a:	f022                	sd	s0,32(sp)
    80003a4c:	ec26                	sd	s1,24(sp)
    80003a4e:	e84a                	sd	s2,16(sp)
    80003a50:	e44e                	sd	s3,8(sp)
    80003a52:	1800                	addi	s0,sp,48
    80003a54:	892a                	mv	s2,a0
    80003a56:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003a58:	0001c497          	auipc	s1,0x1c
    80003a5c:	ed048493          	addi	s1,s1,-304 # 8001f928 <log>
    80003a60:	00004597          	auipc	a1,0x4
    80003a64:	ba858593          	addi	a1,a1,-1112 # 80007608 <syscalls+0x218>
    80003a68:	8526                	mv	a0,s1
    80003a6a:	882fd0ef          	jal	ra,80000aec <initlock>
  log.start = sb->logstart;  // 设置日志起始位置
    80003a6e:	0149a583          	lw	a1,20(s3)
    80003a72:	cc8c                	sw	a1,24(s1)
  log.dev = dev;  // 设置日志设备
    80003a74:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003a78:	854a                	mv	a0,s2
    80003a7a:	fc7fe0ef          	jal	ra,80002a40 <bread>
  log.lh.n = lh->n;  // 读取日志中的块数量
    80003a7e:	4d34                	lw	a3,88(a0)
    80003a80:	d494                	sw	a3,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003a82:	02d05563          	blez	a3,80003aac <initlog+0x66>
    80003a86:	05c50793          	addi	a5,a0,92
    80003a8a:	0001c717          	auipc	a4,0x1c
    80003a8e:	eca70713          	addi	a4,a4,-310 # 8001f954 <log+0x2c>
    80003a92:	36fd                	addiw	a3,a3,-1
    80003a94:	1682                	slli	a3,a3,0x20
    80003a96:	9281                	srli	a3,a3,0x20
    80003a98:	068a                	slli	a3,a3,0x2
    80003a9a:	06050613          	addi	a2,a0,96
    80003a9e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];  // 读取每个日志块的块号
    80003aa0:	4390                	lw	a2,0(a5)
    80003aa2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003aa4:	0791                	addi	a5,a5,4
    80003aa6:	0711                	addi	a4,a4,4
    80003aa8:	fed79ce3          	bne	a5,a3,80003aa0 <initlog+0x5a>
  brelse(buf);  // 释放缓冲区
    80003aac:	89cff0ef          	jal	ra,80002b48 <brelse>

// 从日志中恢复
static void recover_from_log(void)
{
  read_head();  // 读取日志头
  install_trans(1);  // 如果已提交，从日志复制到磁盘
    80003ab0:	4505                	li	a0,1
    80003ab2:	ecfff0ef          	jal	ra,80003980 <install_trans>
  log.lh.n = 0;  // 清空日志中的块数量
    80003ab6:	0001c797          	auipc	a5,0x1c
    80003aba:	e807ad23          	sw	zero,-358(a5) # 8001f950 <log+0x28>
  write_head();  // 清空日志
    80003abe:	e55ff0ef          	jal	ra,80003912 <write_head>
}
    80003ac2:	70a2                	ld	ra,40(sp)
    80003ac4:	7402                	ld	s0,32(sp)
    80003ac6:	64e2                	ld	s1,24(sp)
    80003ac8:	6942                	ld	s2,16(sp)
    80003aca:	69a2                	ld	s3,8(sp)
    80003acc:	6145                	addi	sp,sp,48
    80003ace:	8082                	ret

0000000080003ad0 <begin_op>:
}

// 文件系统调用开始时调用
void begin_op(void)
{
    80003ad0:	1101                	addi	sp,sp,-32
    80003ad2:	ec06                	sd	ra,24(sp)
    80003ad4:	e822                	sd	s0,16(sp)
    80003ad6:	e426                	sd	s1,8(sp)
    80003ad8:	e04a                	sd	s2,0(sp)
    80003ada:	1000                	addi	s0,sp,32
  acquire(&log.lock);  // 获取日志锁
    80003adc:	0001c517          	auipc	a0,0x1c
    80003ae0:	e4c50513          	addi	a0,a0,-436 # 8001f928 <log>
    80003ae4:	888fd0ef          	jal	ra,80000b6c <acquire>
  while(1){
    if(log.committing){
    80003ae8:	0001c497          	auipc	s1,0x1c
    80003aec:	e4048493          	addi	s1,s1,-448 # 8001f928 <log>
      // 如果日志正在提交，进入睡眠
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGBLOCKS){
    80003af0:	4979                	li	s2,30
    80003af2:	a029                	j	80003afc <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003af4:	85a6                	mv	a1,s1
    80003af6:	8526                	mv	a0,s1
    80003af8:	b14fe0ef          	jal	ra,80001e0c <sleep>
    if(log.committing){
    80003afc:	509c                	lw	a5,32(s1)
    80003afe:	fbfd                	bnez	a5,80003af4 <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGBLOCKS){
    80003b00:	4cdc                	lw	a5,28(s1)
    80003b02:	0017871b          	addiw	a4,a5,1
    80003b06:	0007069b          	sext.w	a3,a4
    80003b0a:	0027179b          	slliw	a5,a4,0x2
    80003b0e:	9fb9                	addw	a5,a5,a4
    80003b10:	0017979b          	slliw	a5,a5,0x1
    80003b14:	5498                	lw	a4,40(s1)
    80003b16:	9fb9                	addw	a5,a5,a4
    80003b18:	00f95763          	bge	s2,a5,80003b26 <begin_op+0x56>
      // 如果当前操作可能耗尽日志空间，等待提交
      sleep(&log, &log.lock);
    80003b1c:	85a6                	mv	a1,s1
    80003b1e:	8526                	mv	a0,s1
    80003b20:	aecfe0ef          	jal	ra,80001e0c <sleep>
    80003b24:	bfe1                	j	80003afc <begin_op+0x2c>
    } else {
      log.outstanding += 1;  // 增加正在进行的操作计数
    80003b26:	0001c517          	auipc	a0,0x1c
    80003b2a:	e0250513          	addi	a0,a0,-510 # 8001f928 <log>
    80003b2e:	cd54                	sw	a3,28(a0)
      release(&log.lock);  // 释放日志锁
    80003b30:	8d4fd0ef          	jal	ra,80000c04 <release>
      break;
    }
  }
}
    80003b34:	60e2                	ld	ra,24(sp)
    80003b36:	6442                	ld	s0,16(sp)
    80003b38:	64a2                	ld	s1,8(sp)
    80003b3a:	6902                	ld	s2,0(sp)
    80003b3c:	6105                	addi	sp,sp,32
    80003b3e:	8082                	ret

0000000080003b40 <end_op>:

// 文件系统调用结束时调用
// 如果这是最后一个待处理的操作，则提交日志
void end_op(void)
{
    80003b40:	7139                	addi	sp,sp,-64
    80003b42:	fc06                	sd	ra,56(sp)
    80003b44:	f822                	sd	s0,48(sp)
    80003b46:	f426                	sd	s1,40(sp)
    80003b48:	f04a                	sd	s2,32(sp)
    80003b4a:	ec4e                	sd	s3,24(sp)
    80003b4c:	e852                	sd	s4,16(sp)
    80003b4e:	e456                	sd	s5,8(sp)
    80003b50:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);  // 获取日志锁
    80003b52:	0001c497          	auipc	s1,0x1c
    80003b56:	dd648493          	addi	s1,s1,-554 # 8001f928 <log>
    80003b5a:	8526                	mv	a0,s1
    80003b5c:	810fd0ef          	jal	ra,80000b6c <acquire>
  log.outstanding -= 1;  // 减少待处理操作计数
    80003b60:	4cdc                	lw	a5,28(s1)
    80003b62:	37fd                	addiw	a5,a5,-1
    80003b64:	0007891b          	sext.w	s2,a5
    80003b68:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80003b6a:	509c                	lw	a5,32(s1)
    80003b6c:	ef9d                	bnez	a5,80003baa <end_op+0x6a>
    panic("log.committing");  // 不允许在提交时结束操作
  if(log.outstanding == 0){
    80003b6e:	04091463          	bnez	s2,80003bb6 <end_op+0x76>
    do_commit = 1;  // 如果没有待处理的操作，则标记为需要提交
    log.committing = 1;  // 标记日志为正在提交
    80003b72:	0001c497          	auipc	s1,0x1c
    80003b76:	db648493          	addi	s1,s1,-586 # 8001f928 <log>
    80003b7a:	4785                	li	a5,1
    80003b7c:	d09c                	sw	a5,32(s1)
  } else {
    // 如果正在等待日志空间，唤醒等待的进程
    wakeup(&log);
  }
  release(&log.lock);  // 释放日志锁
    80003b7e:	8526                	mv	a0,s1
    80003b80:	884fd0ef          	jal	ra,80000c04 <release>
}

// 提交事务，将日志中的块写回磁盘并清空日志
static void commit()
{
  if (log.lh.n > 0) {
    80003b84:	549c                	lw	a5,40(s1)
    80003b86:	04f04b63          	bgtz	a5,80003bdc <end_op+0x9c>
    acquire(&log.lock);
    80003b8a:	0001c497          	auipc	s1,0x1c
    80003b8e:	d9e48493          	addi	s1,s1,-610 # 8001f928 <log>
    80003b92:	8526                	mv	a0,s1
    80003b94:	fd9fc0ef          	jal	ra,80000b6c <acquire>
    log.committing = 0;  // 提交完成，恢复日志状态
    80003b98:	0204a023          	sw	zero,32(s1)
    wakeup(&log);  // 唤醒可能在等待提交的进程
    80003b9c:	8526                	mv	a0,s1
    80003b9e:	abafe0ef          	jal	ra,80001e58 <wakeup>
    release(&log.lock);  // 释放日志锁
    80003ba2:	8526                	mv	a0,s1
    80003ba4:	860fd0ef          	jal	ra,80000c04 <release>
}
    80003ba8:	a00d                	j	80003bca <end_op+0x8a>
    panic("log.committing");  // 不允许在提交时结束操作
    80003baa:	00004517          	auipc	a0,0x4
    80003bae:	a6650513          	addi	a0,a0,-1434 # 80007610 <syscalls+0x220>
    80003bb2:	bd9fc0ef          	jal	ra,8000078a <panic>
    wakeup(&log);
    80003bb6:	0001c497          	auipc	s1,0x1c
    80003bba:	d7248493          	addi	s1,s1,-654 # 8001f928 <log>
    80003bbe:	8526                	mv	a0,s1
    80003bc0:	a98fe0ef          	jal	ra,80001e58 <wakeup>
  release(&log.lock);  // 释放日志锁
    80003bc4:	8526                	mv	a0,s1
    80003bc6:	83efd0ef          	jal	ra,80000c04 <release>
}
    80003bca:	70e2                	ld	ra,56(sp)
    80003bcc:	7442                	ld	s0,48(sp)
    80003bce:	74a2                	ld	s1,40(sp)
    80003bd0:	7902                	ld	s2,32(sp)
    80003bd2:	69e2                	ld	s3,24(sp)
    80003bd4:	6a42                	ld	s4,16(sp)
    80003bd6:	6aa2                	ld	s5,8(sp)
    80003bd8:	6121                	addi	sp,sp,64
    80003bda:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80003bdc:	0001ca97          	auipc	s5,0x1c
    80003be0:	d78a8a93          	addi	s5,s5,-648 # 8001f954 <log+0x2c>
    struct buf *to = bread(log.dev, log.start + tail + 1);  // 读取日志块
    80003be4:	0001ca17          	auipc	s4,0x1c
    80003be8:	d44a0a13          	addi	s4,s4,-700 # 8001f928 <log>
    80003bec:	018a2583          	lw	a1,24(s4)
    80003bf0:	012585bb          	addw	a1,a1,s2
    80003bf4:	2585                	addiw	a1,a1,1
    80003bf6:	024a2503          	lw	a0,36(s4)
    80003bfa:	e47fe0ef          	jal	ra,80002a40 <bread>
    80003bfe:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]);  // 读取缓存块
    80003c00:	000aa583          	lw	a1,0(s5)
    80003c04:	024a2503          	lw	a0,36(s4)
    80003c08:	e39fe0ef          	jal	ra,80002a40 <bread>
    80003c0c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);  // 将缓存块的数据复制到日志块
    80003c0e:	40000613          	li	a2,1024
    80003c12:	05850593          	addi	a1,a0,88
    80003c16:	05848513          	addi	a0,s1,88
    80003c1a:	882fd0ef          	jal	ra,80000c9c <memmove>
    bwrite(to);  // 写入日志块
    80003c1e:	8526                	mv	a0,s1
    80003c20:	ef7fe0ef          	jal	ra,80002b16 <bwrite>
    brelse(from);  // 释放缓存块
    80003c24:	854e                	mv	a0,s3
    80003c26:	f23fe0ef          	jal	ra,80002b48 <brelse>
    brelse(to);  // 释放日志块
    80003c2a:	8526                	mv	a0,s1
    80003c2c:	f1dfe0ef          	jal	ra,80002b48 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003c30:	2905                	addiw	s2,s2,1
    80003c32:	0a91                	addi	s5,s5,4
    80003c34:	028a2783          	lw	a5,40(s4)
    80003c38:	faf94ae3          	blt	s2,a5,80003bec <end_op+0xac>
    write_log();     // 将已修改的块从缓存写入日志
    write_head();    // 写入日志头到磁盘，真正提交
    80003c3c:	cd7ff0ef          	jal	ra,80003912 <write_head>
    install_trans(0); // 将写入操作应用到实际位置
    80003c40:	4501                	li	a0,0
    80003c42:	d3fff0ef          	jal	ra,80003980 <install_trans>
    log.lh.n = 0;    // 清空日志中的块数量
    80003c46:	0001c797          	auipc	a5,0x1c
    80003c4a:	d007a523          	sw	zero,-758(a5) # 8001f950 <log+0x28>
    write_head();    // 清空日志
    80003c4e:	cc5ff0ef          	jal	ra,80003912 <write_head>
    80003c52:	bf25                	j	80003b8a <end_op+0x4a>

0000000080003c54 <log_write>:
//   bp = bread(...)
//   修改 bp->data[]
//   log_write(bp)
//   brelse(bp)
void log_write(struct buf *b)
{
    80003c54:	1101                	addi	sp,sp,-32
    80003c56:	ec06                	sd	ra,24(sp)
    80003c58:	e822                	sd	s0,16(sp)
    80003c5a:	e426                	sd	s1,8(sp)
    80003c5c:	e04a                	sd	s2,0(sp)
    80003c5e:	1000                	addi	s0,sp,32
    80003c60:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);  // 获取日志锁
    80003c62:	0001c917          	auipc	s2,0x1c
    80003c66:	cc690913          	addi	s2,s2,-826 # 8001f928 <log>
    80003c6a:	854a                	mv	a0,s2
    80003c6c:	f01fc0ef          	jal	ra,80000b6c <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80003c70:	02892603          	lw	a2,40(s2)
    80003c74:	47f5                	li	a5,29
    80003c76:	04c7cc63          	blt	a5,a2,80003cce <log_write+0x7a>
    panic("too big a transaction");  // 如果日志块数量超过最大值，出错
  if (log.outstanding < 1)
    80003c7a:	0001c797          	auipc	a5,0x1c
    80003c7e:	cca7a783          	lw	a5,-822(a5) # 8001f944 <log+0x1c>
    80003c82:	04f05c63          	blez	a5,80003cda <log_write+0x86>
    panic("log_write outside of trans");  // 如果在没有事务的情况下调用，出错

  for (i = 0; i < log.lh.n; i++) {
    80003c86:	4781                	li	a5,0
    80003c88:	04c05f63          	blez	a2,80003ce6 <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // 如果块已经存在于日志中，跳过
    80003c8c:	44cc                	lw	a1,12(s1)
    80003c8e:	0001c717          	auipc	a4,0x1c
    80003c92:	cc670713          	addi	a4,a4,-826 # 8001f954 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80003c96:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // 如果块已经存在于日志中，跳过
    80003c98:	4314                	lw	a3,0(a4)
    80003c9a:	04b68663          	beq	a3,a1,80003ce6 <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80003c9e:	2785                	addiw	a5,a5,1
    80003ca0:	0711                	addi	a4,a4,4
    80003ca2:	fef61be3          	bne	a2,a5,80003c98 <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;  // 将块号记录到日志中
    80003ca6:	0621                	addi	a2,a2,8
    80003ca8:	060a                	slli	a2,a2,0x2
    80003caa:	0001c797          	auipc	a5,0x1c
    80003cae:	c7e78793          	addi	a5,a5,-898 # 8001f928 <log>
    80003cb2:	963e                	add	a2,a2,a5
    80003cb4:	44dc                	lw	a5,12(s1)
    80003cb6:	c65c                	sw	a5,12(a2)
  if (i == log.lh.n) {  // 如果是新块，添加到日志
    bpin(b);  // 锁定块
    80003cb8:	8526                	mv	a0,s1
    80003cba:	f19fe0ef          	jal	ra,80002bd2 <bpin>
    log.lh.n++;  // 增加日志中的块数量
    80003cbe:	0001c717          	auipc	a4,0x1c
    80003cc2:	c6a70713          	addi	a4,a4,-918 # 8001f928 <log>
    80003cc6:	571c                	lw	a5,40(a4)
    80003cc8:	2785                	addiw	a5,a5,1
    80003cca:	d71c                	sw	a5,40(a4)
    80003ccc:	a815                	j	80003d00 <log_write+0xac>
    panic("too big a transaction");  // 如果日志块数量超过最大值，出错
    80003cce:	00004517          	auipc	a0,0x4
    80003cd2:	95250513          	addi	a0,a0,-1710 # 80007620 <syscalls+0x230>
    80003cd6:	ab5fc0ef          	jal	ra,8000078a <panic>
    panic("log_write outside of trans");  // 如果在没有事务的情况下调用，出错
    80003cda:	00004517          	auipc	a0,0x4
    80003cde:	95e50513          	addi	a0,a0,-1698 # 80007638 <syscalls+0x248>
    80003ce2:	aa9fc0ef          	jal	ra,8000078a <panic>
  log.lh.block[i] = b->blockno;  // 将块号记录到日志中
    80003ce6:	00878713          	addi	a4,a5,8
    80003cea:	00271693          	slli	a3,a4,0x2
    80003cee:	0001c717          	auipc	a4,0x1c
    80003cf2:	c3a70713          	addi	a4,a4,-966 # 8001f928 <log>
    80003cf6:	9736                	add	a4,a4,a3
    80003cf8:	44d4                	lw	a3,12(s1)
    80003cfa:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // 如果是新块，添加到日志
    80003cfc:	faf60ee3          	beq	a2,a5,80003cb8 <log_write+0x64>
  }
  release(&log.lock);  // 释放日志锁
    80003d00:	0001c517          	auipc	a0,0x1c
    80003d04:	c2850513          	addi	a0,a0,-984 # 8001f928 <log>
    80003d08:	efdfc0ef          	jal	ra,80000c04 <release>
}
    80003d0c:	60e2                	ld	ra,24(sp)
    80003d0e:	6442                	ld	s0,16(sp)
    80003d10:	64a2                	ld	s1,8(sp)
    80003d12:	6902                	ld	s2,0(sp)
    80003d14:	6105                	addi	sp,sp,32
    80003d16:	8082                	ret

0000000080003d18 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80003d18:	1101                	addi	sp,sp,-32
    80003d1a:	ec06                	sd	ra,24(sp)
    80003d1c:	e822                	sd	s0,16(sp)
    80003d1e:	e426                	sd	s1,8(sp)
    80003d20:	e04a                	sd	s2,0(sp)
    80003d22:	1000                	addi	s0,sp,32
    80003d24:	84aa                	mv	s1,a0
    80003d26:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80003d28:	00004597          	auipc	a1,0x4
    80003d2c:	93058593          	addi	a1,a1,-1744 # 80007658 <syscalls+0x268>
    80003d30:	0521                	addi	a0,a0,8
    80003d32:	dbbfc0ef          	jal	ra,80000aec <initlock>
  lk->name = name;
    80003d36:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80003d3a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003d3e:	0204a423          	sw	zero,40(s1)
}
    80003d42:	60e2                	ld	ra,24(sp)
    80003d44:	6442                	ld	s0,16(sp)
    80003d46:	64a2                	ld	s1,8(sp)
    80003d48:	6902                	ld	s2,0(sp)
    80003d4a:	6105                	addi	sp,sp,32
    80003d4c:	8082                	ret

0000000080003d4e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80003d4e:	1101                	addi	sp,sp,-32
    80003d50:	ec06                	sd	ra,24(sp)
    80003d52:	e822                	sd	s0,16(sp)
    80003d54:	e426                	sd	s1,8(sp)
    80003d56:	e04a                	sd	s2,0(sp)
    80003d58:	1000                	addi	s0,sp,32
    80003d5a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003d5c:	00850913          	addi	s2,a0,8
    80003d60:	854a                	mv	a0,s2
    80003d62:	e0bfc0ef          	jal	ra,80000b6c <acquire>
  while (lk->locked) {
    80003d66:	409c                	lw	a5,0(s1)
    80003d68:	c799                	beqz	a5,80003d76 <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80003d6a:	85ca                	mv	a1,s2
    80003d6c:	8526                	mv	a0,s1
    80003d6e:	89efe0ef          	jal	ra,80001e0c <sleep>
  while (lk->locked) {
    80003d72:	409c                	lw	a5,0(s1)
    80003d74:	fbfd                	bnez	a5,80003d6a <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80003d76:	4785                	li	a5,1
    80003d78:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80003d7a:	a8bfd0ef          	jal	ra,80001804 <myproc>
    80003d7e:	591c                	lw	a5,48(a0)
    80003d80:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80003d82:	854a                	mv	a0,s2
    80003d84:	e81fc0ef          	jal	ra,80000c04 <release>
}
    80003d88:	60e2                	ld	ra,24(sp)
    80003d8a:	6442                	ld	s0,16(sp)
    80003d8c:	64a2                	ld	s1,8(sp)
    80003d8e:	6902                	ld	s2,0(sp)
    80003d90:	6105                	addi	sp,sp,32
    80003d92:	8082                	ret

0000000080003d94 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80003d94:	1101                	addi	sp,sp,-32
    80003d96:	ec06                	sd	ra,24(sp)
    80003d98:	e822                	sd	s0,16(sp)
    80003d9a:	e426                	sd	s1,8(sp)
    80003d9c:	e04a                	sd	s2,0(sp)
    80003d9e:	1000                	addi	s0,sp,32
    80003da0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003da2:	00850913          	addi	s2,a0,8
    80003da6:	854a                	mv	a0,s2
    80003da8:	dc5fc0ef          	jal	ra,80000b6c <acquire>
  lk->locked = 0;
    80003dac:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003db0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80003db4:	8526                	mv	a0,s1
    80003db6:	8a2fe0ef          	jal	ra,80001e58 <wakeup>
  release(&lk->lk);
    80003dba:	854a                	mv	a0,s2
    80003dbc:	e49fc0ef          	jal	ra,80000c04 <release>
}
    80003dc0:	60e2                	ld	ra,24(sp)
    80003dc2:	6442                	ld	s0,16(sp)
    80003dc4:	64a2                	ld	s1,8(sp)
    80003dc6:	6902                	ld	s2,0(sp)
    80003dc8:	6105                	addi	sp,sp,32
    80003dca:	8082                	ret

0000000080003dcc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80003dcc:	7179                	addi	sp,sp,-48
    80003dce:	f406                	sd	ra,40(sp)
    80003dd0:	f022                	sd	s0,32(sp)
    80003dd2:	ec26                	sd	s1,24(sp)
    80003dd4:	e84a                	sd	s2,16(sp)
    80003dd6:	e44e                	sd	s3,8(sp)
    80003dd8:	1800                	addi	s0,sp,48
    80003dda:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80003ddc:	00850913          	addi	s2,a0,8
    80003de0:	854a                	mv	a0,s2
    80003de2:	d8bfc0ef          	jal	ra,80000b6c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80003de6:	409c                	lw	a5,0(s1)
    80003de8:	ef89                	bnez	a5,80003e02 <holdingsleep+0x36>
    80003dea:	4481                	li	s1,0
  release(&lk->lk);
    80003dec:	854a                	mv	a0,s2
    80003dee:	e17fc0ef          	jal	ra,80000c04 <release>
  return r;
}
    80003df2:	8526                	mv	a0,s1
    80003df4:	70a2                	ld	ra,40(sp)
    80003df6:	7402                	ld	s0,32(sp)
    80003df8:	64e2                	ld	s1,24(sp)
    80003dfa:	6942                	ld	s2,16(sp)
    80003dfc:	69a2                	ld	s3,8(sp)
    80003dfe:	6145                	addi	sp,sp,48
    80003e00:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80003e02:	0284a983          	lw	s3,40(s1)
    80003e06:	9fffd0ef          	jal	ra,80001804 <myproc>
    80003e0a:	5904                	lw	s1,48(a0)
    80003e0c:	413484b3          	sub	s1,s1,s3
    80003e10:	0014b493          	seqz	s1,s1
    80003e14:	bfe1                	j	80003dec <holdingsleep+0x20>

0000000080003e16 <fileinit>:
} ftable;

// 文件表初始化
void
fileinit(void)
{
    80003e16:	1141                	addi	sp,sp,-16
    80003e18:	e406                	sd	ra,8(sp)
    80003e1a:	e022                	sd	s0,0(sp)
    80003e1c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");  // 初始化文件表的自旋锁
    80003e1e:	00004597          	auipc	a1,0x4
    80003e22:	84a58593          	addi	a1,a1,-1974 # 80007668 <syscalls+0x278>
    80003e26:	0001c517          	auipc	a0,0x1c
    80003e2a:	c4a50513          	addi	a0,a0,-950 # 8001fa70 <ftable>
    80003e2e:	cbffc0ef          	jal	ra,80000aec <initlock>
}
    80003e32:	60a2                	ld	ra,8(sp)
    80003e34:	6402                	ld	s0,0(sp)
    80003e36:	0141                	addi	sp,sp,16
    80003e38:	8082                	ret

0000000080003e3a <filealloc>:

// 分配一个新的文件结构体
struct file*
filealloc(void)
{
    80003e3a:	1101                	addi	sp,sp,-32
    80003e3c:	ec06                	sd	ra,24(sp)
    80003e3e:	e822                	sd	s0,16(sp)
    80003e40:	e426                	sd	s1,8(sp)
    80003e42:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);  // 获取文件表锁
    80003e44:	0001c517          	auipc	a0,0x1c
    80003e48:	c2c50513          	addi	a0,a0,-980 # 8001fa70 <ftable>
    80003e4c:	d21fc0ef          	jal	ra,80000b6c <acquire>
  // 遍历文件表，找到引用计数为 0 的文件结构体
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80003e50:	0001c497          	auipc	s1,0x1c
    80003e54:	c3848493          	addi	s1,s1,-968 # 8001fa88 <ftable+0x18>
    80003e58:	0001d717          	auipc	a4,0x1d
    80003e5c:	bd070713          	addi	a4,a4,-1072 # 80020a28 <disk>
    if(f->ref == 0){
    80003e60:	40dc                	lw	a5,4(s1)
    80003e62:	cf89                	beqz	a5,80003e7c <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80003e64:	02848493          	addi	s1,s1,40
    80003e68:	fee49ce3          	bne	s1,a4,80003e60 <filealloc+0x26>
      f->ref = 1;  // 设置引用计数为 1
      release(&ftable.lock);  // 释放文件表锁
      return f;  // 返回分配的文件结构体
    }
  }
  release(&ftable.lock);  // 如果没有空闲文件结构体，释放锁
    80003e6c:	0001c517          	auipc	a0,0x1c
    80003e70:	c0450513          	addi	a0,a0,-1020 # 8001fa70 <ftable>
    80003e74:	d91fc0ef          	jal	ra,80000c04 <release>
  return 0;  // 没有可用的文件结构体
    80003e78:	4481                	li	s1,0
    80003e7a:	a809                	j	80003e8c <filealloc+0x52>
      f->ref = 1;  // 设置引用计数为 1
    80003e7c:	4785                	li	a5,1
    80003e7e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);  // 释放文件表锁
    80003e80:	0001c517          	auipc	a0,0x1c
    80003e84:	bf050513          	addi	a0,a0,-1040 # 8001fa70 <ftable>
    80003e88:	d7dfc0ef          	jal	ra,80000c04 <release>
}
    80003e8c:	8526                	mv	a0,s1
    80003e8e:	60e2                	ld	ra,24(sp)
    80003e90:	6442                	ld	s0,16(sp)
    80003e92:	64a2                	ld	s1,8(sp)
    80003e94:	6105                	addi	sp,sp,32
    80003e96:	8082                	ret

0000000080003e98 <filedup>:

// 增加文件结构体的引用计数
struct file*
filedup(struct file *f)
{
    80003e98:	1101                	addi	sp,sp,-32
    80003e9a:	ec06                	sd	ra,24(sp)
    80003e9c:	e822                	sd	s0,16(sp)
    80003e9e:	e426                	sd	s1,8(sp)
    80003ea0:	1000                	addi	s0,sp,32
    80003ea2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);  // 获取文件表锁
    80003ea4:	0001c517          	auipc	a0,0x1c
    80003ea8:	bcc50513          	addi	a0,a0,-1076 # 8001fa70 <ftable>
    80003eac:	cc1fc0ef          	jal	ra,80000b6c <acquire>
  if(f->ref < 1)  // 如果引用计数小于 1，说明文件结构体无效
    80003eb0:	40dc                	lw	a5,4(s1)
    80003eb2:	02f05063          	blez	a5,80003ed2 <filedup+0x3a>
    panic("filedup");
  f->ref++;  // 增加引用计数
    80003eb6:	2785                	addiw	a5,a5,1
    80003eb8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);  // 释放文件表锁
    80003eba:	0001c517          	auipc	a0,0x1c
    80003ebe:	bb650513          	addi	a0,a0,-1098 # 8001fa70 <ftable>
    80003ec2:	d43fc0ef          	jal	ra,80000c04 <release>
  return f;  // 返回文件结构体
}
    80003ec6:	8526                	mv	a0,s1
    80003ec8:	60e2                	ld	ra,24(sp)
    80003eca:	6442                	ld	s0,16(sp)
    80003ecc:	64a2                	ld	s1,8(sp)
    80003ece:	6105                	addi	sp,sp,32
    80003ed0:	8082                	ret
    panic("filedup");
    80003ed2:	00003517          	auipc	a0,0x3
    80003ed6:	79e50513          	addi	a0,a0,1950 # 80007670 <syscalls+0x280>
    80003eda:	8b1fc0ef          	jal	ra,8000078a <panic>

0000000080003ede <fileclose>:

// 关闭文件结构体 f，减少引用计数，当引用计数为 0 时关闭文件
void
fileclose(struct file *f)
{
    80003ede:	7139                	addi	sp,sp,-64
    80003ee0:	fc06                	sd	ra,56(sp)
    80003ee2:	f822                	sd	s0,48(sp)
    80003ee4:	f426                	sd	s1,40(sp)
    80003ee6:	f04a                	sd	s2,32(sp)
    80003ee8:	ec4e                	sd	s3,24(sp)
    80003eea:	e852                	sd	s4,16(sp)
    80003eec:	e456                	sd	s5,8(sp)
    80003eee:	0080                	addi	s0,sp,64
    80003ef0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);  // 获取文件表锁
    80003ef2:	0001c517          	auipc	a0,0x1c
    80003ef6:	b7e50513          	addi	a0,a0,-1154 # 8001fa70 <ftable>
    80003efa:	c73fc0ef          	jal	ra,80000b6c <acquire>
  if(f->ref < 1)  // 如果引用计数小于 1，说明文件结构体无效
    80003efe:	40dc                	lw	a5,4(s1)
    80003f00:	04f05963          	blez	a5,80003f52 <fileclose+0x74>
    panic("fileclose");
  if(--f->ref > 0){  // 如果引用计数大于 0，直接返回
    80003f04:	37fd                	addiw	a5,a5,-1
    80003f06:	0007871b          	sext.w	a4,a5
    80003f0a:	c0dc                	sw	a5,4(s1)
    80003f0c:	04e04963          	bgtz	a4,80003f5e <fileclose+0x80>
    release(&ftable.lock);
    return;
  }
  ff = *f;  // 备份文件结构体
    80003f10:	0004a903          	lw	s2,0(s1)
    80003f14:	0094ca83          	lbu	s5,9(s1)
    80003f18:	0104ba03          	ld	s4,16(s1)
    80003f1c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;  // 重置引用计数
    80003f20:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;  // 重置文件类型
    80003f24:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);  // 释放文件表锁
    80003f28:	0001c517          	auipc	a0,0x1c
    80003f2c:	b4850513          	addi	a0,a0,-1208 # 8001fa70 <ftable>
    80003f30:	cd5fc0ef          	jal	ra,80000c04 <release>

  // 如果文件类型是管道（pipe），则关闭管道
  if(ff.type == FD_PIPE){
    80003f34:	4785                	li	a5,1
    80003f36:	04f90363          	beq	s2,a5,80003f7c <fileclose+0x9e>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80003f3a:	3979                	addiw	s2,s2,-2
    80003f3c:	4785                	li	a5,1
    80003f3e:	0327e663          	bltu	a5,s2,80003f6a <fileclose+0x8c>
    begin_op();  // 开始一个文件系统操作
    80003f42:	b8fff0ef          	jal	ra,80003ad0 <begin_op>
    iput(ff.ip);  // 释放 inode
    80003f46:	854e                	mv	a0,s3
    80003f48:	b28ff0ef          	jal	ra,80003270 <iput>
    end_op();  // 结束文件系统操作
    80003f4c:	bf5ff0ef          	jal	ra,80003b40 <end_op>
    80003f50:	a829                	j	80003f6a <fileclose+0x8c>
    panic("fileclose");
    80003f52:	00003517          	auipc	a0,0x3
    80003f56:	72650513          	addi	a0,a0,1830 # 80007678 <syscalls+0x288>
    80003f5a:	831fc0ef          	jal	ra,8000078a <panic>
    release(&ftable.lock);
    80003f5e:	0001c517          	auipc	a0,0x1c
    80003f62:	b1250513          	addi	a0,a0,-1262 # 8001fa70 <ftable>
    80003f66:	c9ffc0ef          	jal	ra,80000c04 <release>
  }
}
    80003f6a:	70e2                	ld	ra,56(sp)
    80003f6c:	7442                	ld	s0,48(sp)
    80003f6e:	74a2                	ld	s1,40(sp)
    80003f70:	7902                	ld	s2,32(sp)
    80003f72:	69e2                	ld	s3,24(sp)
    80003f74:	6a42                	ld	s4,16(sp)
    80003f76:	6aa2                	ld	s5,8(sp)
    80003f78:	6121                	addi	sp,sp,64
    80003f7a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80003f7c:	85d6                	mv	a1,s5
    80003f7e:	8552                	mv	a0,s4
    80003f80:	2ec000ef          	jal	ra,8000426c <pipeclose>
    80003f84:	b7dd                	j	80003f6a <fileclose+0x8c>

0000000080003f86 <filestat>:

// 获取文件 f 的元数据（如文件大小、类型等）
// addr 是一个用户虚拟地址，指向 struct stat 结构
int
filestat(struct file *f, uint64 addr)
{
    80003f86:	715d                	addi	sp,sp,-80
    80003f88:	e486                	sd	ra,72(sp)
    80003f8a:	e0a2                	sd	s0,64(sp)
    80003f8c:	fc26                	sd	s1,56(sp)
    80003f8e:	f84a                	sd	s2,48(sp)
    80003f90:	f44e                	sd	s3,40(sp)
    80003f92:	0880                	addi	s0,sp,80
    80003f94:	84aa                	mv	s1,a0
    80003f96:	89ae                	mv	s3,a1
  struct proc *p = myproc();  // 获取当前进程
    80003f98:	86dfd0ef          	jal	ra,80001804 <myproc>
  struct stat st;
  
  // 如果文件是 inode 类型或设备类型
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80003f9c:	409c                	lw	a5,0(s1)
    80003f9e:	37f9                	addiw	a5,a5,-2
    80003fa0:	4705                	li	a4,1
    80003fa2:	02f76f63          	bltu	a4,a5,80003fe0 <filestat+0x5a>
    80003fa6:	892a                	mv	s2,a0
    ilock(f->ip);  // 锁定 inode
    80003fa8:	6c88                	ld	a0,24(s1)
    80003faa:	948ff0ef          	jal	ra,800030f2 <ilock>
    stati(f->ip, &st);  // 获取 inode 的元数据
    80003fae:	fb840593          	addi	a1,s0,-72
    80003fb2:	6c88                	ld	a0,24(s1)
    80003fb4:	ca0ff0ef          	jal	ra,80003454 <stati>
    iunlock(f->ip);  // 解锁 inode
    80003fb8:	6c88                	ld	a0,24(s1)
    80003fba:	9e2ff0ef          	jal	ra,8000319c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)  // 将元数据复制到用户地址
    80003fbe:	46e1                	li	a3,24
    80003fc0:	fb840613          	addi	a2,s0,-72
    80003fc4:	85ce                	mv	a1,s3
    80003fc6:	05093503          	ld	a0,80(s2)
    80003fca:	d88fd0ef          	jal	ra,80001552 <copyout>
    80003fce:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;  // 其他类型文件不支持
}
    80003fd2:	60a6                	ld	ra,72(sp)
    80003fd4:	6406                	ld	s0,64(sp)
    80003fd6:	74e2                	ld	s1,56(sp)
    80003fd8:	7942                	ld	s2,48(sp)
    80003fda:	79a2                	ld	s3,40(sp)
    80003fdc:	6161                	addi	sp,sp,80
    80003fde:	8082                	ret
  return -1;  // 其他类型文件不支持
    80003fe0:	557d                	li	a0,-1
    80003fe2:	bfc5                	j	80003fd2 <filestat+0x4c>

0000000080003fe4 <fileread>:

// 从文件 f 中读取数据。
// addr 是一个用户虚拟地址。
int
fileread(struct file *f, uint64 addr, int n)
{
    80003fe4:	7179                	addi	sp,sp,-48
    80003fe6:	f406                	sd	ra,40(sp)
    80003fe8:	f022                	sd	s0,32(sp)
    80003fea:	ec26                	sd	s1,24(sp)
    80003fec:	e84a                	sd	s2,16(sp)
    80003fee:	e44e                	sd	s3,8(sp)
    80003ff0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)  // 如果文件不可读，返回 -1
    80003ff2:	00854783          	lbu	a5,8(a0)
    80003ff6:	cbc1                	beqz	a5,80004086 <fileread+0xa2>
    80003ff8:	84aa                	mv	s1,a0
    80003ffa:	89ae                	mv	s3,a1
    80003ffc:	8932                	mv	s2,a2
    return -1;

  // 根据文件类型执行不同的读取操作
  if(f->type == FD_PIPE){
    80003ffe:	411c                	lw	a5,0(a0)
    80004000:	4705                	li	a4,1
    80004002:	04e78363          	beq	a5,a4,80004048 <fileread+0x64>
    r = piperead(f->pipe, addr, n);  // 从管道中读取
  } else if(f->type == FD_DEVICE){
    80004006:	470d                	li	a4,3
    80004008:	04e78563          	beq	a5,a4,80004052 <fileread+0x6e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)  // 如果设备不支持读取，返回 -1
      return -1;
    r = devsw[f->major].read(1, addr, n);  // 调用设备的读取函数
  } else if(f->type == FD_INODE){
    8000400c:	4709                	li	a4,2
    8000400e:	06e79663          	bne	a5,a4,8000407a <fileread+0x96>
    ilock(f->ip);  // 锁定 inode
    80004012:	6d08                	ld	a0,24(a0)
    80004014:	8deff0ef          	jal	ra,800030f2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)  // 从 inode 中读取数据
    80004018:	874a                	mv	a4,s2
    8000401a:	5094                	lw	a3,32(s1)
    8000401c:	864e                	mv	a2,s3
    8000401e:	4585                	li	a1,1
    80004020:	6c88                	ld	a0,24(s1)
    80004022:	c5cff0ef          	jal	ra,8000347e <readi>
    80004026:	892a                	mv	s2,a0
    80004028:	00a05563          	blez	a0,80004032 <fileread+0x4e>
      f->off += r;  // 更新文件偏移量
    8000402c:	509c                	lw	a5,32(s1)
    8000402e:	9fa9                	addw	a5,a5,a0
    80004030:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);  // 解锁 inode
    80004032:	6c88                	ld	a0,24(s1)
    80004034:	968ff0ef          	jal	ra,8000319c <iunlock>
  } else {
    panic("fileread");  // 不支持的文件类型
  }

  return r;  // 返回读取的字节数
}
    80004038:	854a                	mv	a0,s2
    8000403a:	70a2                	ld	ra,40(sp)
    8000403c:	7402                	ld	s0,32(sp)
    8000403e:	64e2                	ld	s1,24(sp)
    80004040:	6942                	ld	s2,16(sp)
    80004042:	69a2                	ld	s3,8(sp)
    80004044:	6145                	addi	sp,sp,48
    80004046:	8082                	ret
    r = piperead(f->pipe, addr, n);  // 从管道中读取
    80004048:	6908                	ld	a0,16(a0)
    8000404a:	34e000ef          	jal	ra,80004398 <piperead>
    8000404e:	892a                	mv	s2,a0
    80004050:	b7e5                	j	80004038 <fileread+0x54>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)  // 如果设备不支持读取，返回 -1
    80004052:	02451783          	lh	a5,36(a0)
    80004056:	03079693          	slli	a3,a5,0x30
    8000405a:	92c1                	srli	a3,a3,0x30
    8000405c:	4725                	li	a4,9
    8000405e:	02d76663          	bltu	a4,a3,8000408a <fileread+0xa6>
    80004062:	0792                	slli	a5,a5,0x4
    80004064:	0001c717          	auipc	a4,0x1c
    80004068:	96c70713          	addi	a4,a4,-1684 # 8001f9d0 <devsw>
    8000406c:	97ba                	add	a5,a5,a4
    8000406e:	639c                	ld	a5,0(a5)
    80004070:	cf99                	beqz	a5,8000408e <fileread+0xaa>
    r = devsw[f->major].read(1, addr, n);  // 调用设备的读取函数
    80004072:	4505                	li	a0,1
    80004074:	9782                	jalr	a5
    80004076:	892a                	mv	s2,a0
    80004078:	b7c1                	j	80004038 <fileread+0x54>
    panic("fileread");  // 不支持的文件类型
    8000407a:	00003517          	auipc	a0,0x3
    8000407e:	60e50513          	addi	a0,a0,1550 # 80007688 <syscalls+0x298>
    80004082:	f08fc0ef          	jal	ra,8000078a <panic>
    return -1;
    80004086:	597d                	li	s2,-1
    80004088:	bf45                	j	80004038 <fileread+0x54>
      return -1;
    8000408a:	597d                	li	s2,-1
    8000408c:	b775                	j	80004038 <fileread+0x54>
    8000408e:	597d                	li	s2,-1
    80004090:	b765                	j	80004038 <fileread+0x54>

0000000080004092 <filewrite>:

// 向文件 f 中写入数据。
// addr 是一个用户虚拟地址。
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004092:	715d                	addi	sp,sp,-80
    80004094:	e486                	sd	ra,72(sp)
    80004096:	e0a2                	sd	s0,64(sp)
    80004098:	fc26                	sd	s1,56(sp)
    8000409a:	f84a                	sd	s2,48(sp)
    8000409c:	f44e                	sd	s3,40(sp)
    8000409e:	f052                	sd	s4,32(sp)
    800040a0:	ec56                	sd	s5,24(sp)
    800040a2:	e85a                	sd	s6,16(sp)
    800040a4:	e45e                	sd	s7,8(sp)
    800040a6:	e062                	sd	s8,0(sp)
    800040a8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)  // 如果文件不可写，返回 -1
    800040aa:	00954783          	lbu	a5,9(a0)
    800040ae:	0e078863          	beqz	a5,8000419e <filewrite+0x10c>
    800040b2:	892a                	mv	s2,a0
    800040b4:	8aae                	mv	s5,a1
    800040b6:	8a32                	mv	s4,a2
    return -1;

  // 根据文件类型执行不同的写入操作
  if(f->type == FD_PIPE){
    800040b8:	411c                	lw	a5,0(a0)
    800040ba:	4705                	li	a4,1
    800040bc:	02e78263          	beq	a5,a4,800040e0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);  // 向管道中写入
  } else if(f->type == FD_DEVICE){
    800040c0:	470d                	li	a4,3
    800040c2:	02e78463          	beq	a5,a4,800040ea <filewrite+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)  // 如果设备不支持写入，返回 -1
      return -1;
    ret = devsw[f->major].write(1, addr, n);  // 调用设备的写入函数
  } else if(f->type == FD_INODE){
    800040c6:	4709                	li	a4,2
    800040c8:	0ce79563          	bne	a5,a4,80004192 <filewrite+0x100>
    // 分多次写入，以避免超过最大日志事务大小，包括 inode、间接块、分配块等
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800040cc:	0ac05163          	blez	a2,8000416e <filewrite+0xdc>
    int i = 0;
    800040d0:	4981                	li	s3,0
    800040d2:	6b05                	lui	s6,0x1
    800040d4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800040d8:	6b85                	lui	s7,0x1
    800040da:	c00b8b9b          	addiw	s7,s7,-1024
    800040de:	a041                	j	8000415e <filewrite+0xcc>
    ret = pipewrite(f->pipe, addr, n);  // 向管道中写入
    800040e0:	6908                	ld	a0,16(a0)
    800040e2:	1e2000ef          	jal	ra,800042c4 <pipewrite>
    800040e6:	8a2a                	mv	s4,a0
    800040e8:	a071                	j	80004174 <filewrite+0xe2>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)  // 如果设备不支持写入，返回 -1
    800040ea:	02451783          	lh	a5,36(a0)
    800040ee:	03079693          	slli	a3,a5,0x30
    800040f2:	92c1                	srli	a3,a3,0x30
    800040f4:	4725                	li	a4,9
    800040f6:	0ad76663          	bltu	a4,a3,800041a2 <filewrite+0x110>
    800040fa:	0792                	slli	a5,a5,0x4
    800040fc:	0001c717          	auipc	a4,0x1c
    80004100:	8d470713          	addi	a4,a4,-1836 # 8001f9d0 <devsw>
    80004104:	97ba                	add	a5,a5,a4
    80004106:	679c                	ld	a5,8(a5)
    80004108:	cfd9                	beqz	a5,800041a6 <filewrite+0x114>
    ret = devsw[f->major].write(1, addr, n);  // 调用设备的写入函数
    8000410a:	4505                	li	a0,1
    8000410c:	9782                	jalr	a5
    8000410e:	8a2a                	mv	s4,a0
    80004110:	a095                	j	80004174 <filewrite+0xe2>
    80004112:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)  // 如果写入数据超过最大限制，分批次写入
        n1 = max;

      begin_op();  // 开始一个文件系统操作
    80004116:	9bbff0ef          	jal	ra,80003ad0 <begin_op>
      ilock(f->ip);  // 锁定 inode
    8000411a:	01893503          	ld	a0,24(s2)
    8000411e:	fd5fe0ef          	jal	ra,800030f2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004122:	8762                	mv	a4,s8
    80004124:	02092683          	lw	a3,32(s2)
    80004128:	01598633          	add	a2,s3,s5
    8000412c:	4585                	li	a1,1
    8000412e:	01893503          	ld	a0,24(s2)
    80004132:	c30ff0ef          	jal	ra,80003562 <writei>
    80004136:	84aa                	mv	s1,a0
    80004138:	00a05763          	blez	a0,80004146 <filewrite+0xb4>
        f->off += r;  // 更新文件偏移量
    8000413c:	02092783          	lw	a5,32(s2)
    80004140:	9fa9                	addw	a5,a5,a0
    80004142:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);  // 解锁 inode
    80004146:	01893503          	ld	a0,24(s2)
    8000414a:	852ff0ef          	jal	ra,8000319c <iunlock>
      end_op();  // 结束文件系统操作
    8000414e:	9f3ff0ef          	jal	ra,80003b40 <end_op>

      if(r != n1){  // 如果写入不完全，退出
    80004152:	009c1f63          	bne	s8,s1,80004170 <filewrite+0xde>
        break;
      }
      i += r;
    80004156:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000415a:	0149db63          	bge	s3,s4,80004170 <filewrite+0xde>
      int n1 = n - i;
    8000415e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)  // 如果写入数据超过最大限制，分批次写入
    80004162:	84be                	mv	s1,a5
    80004164:	2781                	sext.w	a5,a5
    80004166:	fafb56e3          	bge	s6,a5,80004112 <filewrite+0x80>
    8000416a:	84de                	mv	s1,s7
    8000416c:	b75d                	j	80004112 <filewrite+0x80>
    int i = 0;
    8000416e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);  // 如果写入完全成功，返回写入字节数，否则返回 -1
    80004170:	013a1f63          	bne	s4,s3,8000418e <filewrite+0xfc>
  } else {
    panic("filewrite");  // 不支持的文件类型
  }

  return ret;  // 返回写入的字节数
}
    80004174:	8552                	mv	a0,s4
    80004176:	60a6                	ld	ra,72(sp)
    80004178:	6406                	ld	s0,64(sp)
    8000417a:	74e2                	ld	s1,56(sp)
    8000417c:	7942                	ld	s2,48(sp)
    8000417e:	79a2                	ld	s3,40(sp)
    80004180:	7a02                	ld	s4,32(sp)
    80004182:	6ae2                	ld	s5,24(sp)
    80004184:	6b42                	ld	s6,16(sp)
    80004186:	6ba2                	ld	s7,8(sp)
    80004188:	6c02                	ld	s8,0(sp)
    8000418a:	6161                	addi	sp,sp,80
    8000418c:	8082                	ret
    ret = (i == n ? n : -1);  // 如果写入完全成功，返回写入字节数，否则返回 -1
    8000418e:	5a7d                	li	s4,-1
    80004190:	b7d5                	j	80004174 <filewrite+0xe2>
    panic("filewrite");  // 不支持的文件类型
    80004192:	00003517          	auipc	a0,0x3
    80004196:	50650513          	addi	a0,a0,1286 # 80007698 <syscalls+0x2a8>
    8000419a:	df0fc0ef          	jal	ra,8000078a <panic>
    return -1;
    8000419e:	5a7d                	li	s4,-1
    800041a0:	bfd1                	j	80004174 <filewrite+0xe2>
      return -1;
    800041a2:	5a7d                	li	s4,-1
    800041a4:	bfc1                	j	80004174 <filewrite+0xe2>
    800041a6:	5a7d                	li	s4,-1
    800041a8:	b7f1                	j	80004174 <filewrite+0xe2>

00000000800041aa <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800041aa:	7179                	addi	sp,sp,-48
    800041ac:	f406                	sd	ra,40(sp)
    800041ae:	f022                	sd	s0,32(sp)
    800041b0:	ec26                	sd	s1,24(sp)
    800041b2:	e84a                	sd	s2,16(sp)
    800041b4:	e44e                	sd	s3,8(sp)
    800041b6:	e052                	sd	s4,0(sp)
    800041b8:	1800                	addi	s0,sp,48
    800041ba:	84aa                	mv	s1,a0
    800041bc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800041be:	0005b023          	sd	zero,0(a1)
    800041c2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800041c6:	c75ff0ef          	jal	ra,80003e3a <filealloc>
    800041ca:	e088                	sd	a0,0(s1)
    800041cc:	cd35                	beqz	a0,80004248 <pipealloc+0x9e>
    800041ce:	c6dff0ef          	jal	ra,80003e3a <filealloc>
    800041d2:	00aa3023          	sd	a0,0(s4)
    800041d6:	c52d                	beqz	a0,80004240 <pipealloc+0x96>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800041d8:	8c5fc0ef          	jal	ra,80000a9c <kalloc>
    800041dc:	892a                	mv	s2,a0
    800041de:	cd31                	beqz	a0,8000423a <pipealloc+0x90>
    goto bad;
  pi->readopen = 1;
    800041e0:	4985                	li	s3,1
    800041e2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800041e6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800041ea:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800041ee:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800041f2:	00003597          	auipc	a1,0x3
    800041f6:	4b658593          	addi	a1,a1,1206 # 800076a8 <syscalls+0x2b8>
    800041fa:	8f3fc0ef          	jal	ra,80000aec <initlock>
  (*f0)->type = FD_PIPE;
    800041fe:	609c                	ld	a5,0(s1)
    80004200:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004204:	609c                	ld	a5,0(s1)
    80004206:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000420a:	609c                	ld	a5,0(s1)
    8000420c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004210:	609c                	ld	a5,0(s1)
    80004212:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004216:	000a3783          	ld	a5,0(s4)
    8000421a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000421e:	000a3783          	ld	a5,0(s4)
    80004222:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004226:	000a3783          	ld	a5,0(s4)
    8000422a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000422e:	000a3783          	ld	a5,0(s4)
    80004232:	0127b823          	sd	s2,16(a5)
  return 0;
    80004236:	4501                	li	a0,0
    80004238:	a005                	j	80004258 <pipealloc+0xae>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000423a:	6088                	ld	a0,0(s1)
    8000423c:	e501                	bnez	a0,80004244 <pipealloc+0x9a>
    8000423e:	a029                	j	80004248 <pipealloc+0x9e>
    80004240:	6088                	ld	a0,0(s1)
    80004242:	c11d                	beqz	a0,80004268 <pipealloc+0xbe>
    fileclose(*f0);
    80004244:	c9bff0ef          	jal	ra,80003ede <fileclose>
  if(*f1)
    80004248:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000424c:	557d                	li	a0,-1
  if(*f1)
    8000424e:	c789                	beqz	a5,80004258 <pipealloc+0xae>
    fileclose(*f1);
    80004250:	853e                	mv	a0,a5
    80004252:	c8dff0ef          	jal	ra,80003ede <fileclose>
  return -1;
    80004256:	557d                	li	a0,-1
}
    80004258:	70a2                	ld	ra,40(sp)
    8000425a:	7402                	ld	s0,32(sp)
    8000425c:	64e2                	ld	s1,24(sp)
    8000425e:	6942                	ld	s2,16(sp)
    80004260:	69a2                	ld	s3,8(sp)
    80004262:	6a02                	ld	s4,0(sp)
    80004264:	6145                	addi	sp,sp,48
    80004266:	8082                	ret
  return -1;
    80004268:	557d                	li	a0,-1
    8000426a:	b7fd                	j	80004258 <pipealloc+0xae>

000000008000426c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000426c:	1101                	addi	sp,sp,-32
    8000426e:	ec06                	sd	ra,24(sp)
    80004270:	e822                	sd	s0,16(sp)
    80004272:	e426                	sd	s1,8(sp)
    80004274:	e04a                	sd	s2,0(sp)
    80004276:	1000                	addi	s0,sp,32
    80004278:	84aa                	mv	s1,a0
    8000427a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000427c:	8f1fc0ef          	jal	ra,80000b6c <acquire>
  if(writable){
    80004280:	02090763          	beqz	s2,800042ae <pipeclose+0x42>
    pi->writeopen = 0;
    80004284:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004288:	21848513          	addi	a0,s1,536
    8000428c:	bcdfd0ef          	jal	ra,80001e58 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004290:	2204b783          	ld	a5,544(s1)
    80004294:	e785                	bnez	a5,800042bc <pipeclose+0x50>
    release(&pi->lock);
    80004296:	8526                	mv	a0,s1
    80004298:	96dfc0ef          	jal	ra,80000c04 <release>
    kfree((char*)pi);
    8000429c:	8526                	mv	a0,s1
    8000429e:	f1efc0ef          	jal	ra,800009bc <kfree>
  } else
    release(&pi->lock);
}
    800042a2:	60e2                	ld	ra,24(sp)
    800042a4:	6442                	ld	s0,16(sp)
    800042a6:	64a2                	ld	s1,8(sp)
    800042a8:	6902                	ld	s2,0(sp)
    800042aa:	6105                	addi	sp,sp,32
    800042ac:	8082                	ret
    pi->readopen = 0;
    800042ae:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800042b2:	21c48513          	addi	a0,s1,540
    800042b6:	ba3fd0ef          	jal	ra,80001e58 <wakeup>
    800042ba:	bfd9                	j	80004290 <pipeclose+0x24>
    release(&pi->lock);
    800042bc:	8526                	mv	a0,s1
    800042be:	947fc0ef          	jal	ra,80000c04 <release>
}
    800042c2:	b7c5                	j	800042a2 <pipeclose+0x36>

00000000800042c4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800042c4:	711d                	addi	sp,sp,-96
    800042c6:	ec86                	sd	ra,88(sp)
    800042c8:	e8a2                	sd	s0,80(sp)
    800042ca:	e4a6                	sd	s1,72(sp)
    800042cc:	e0ca                	sd	s2,64(sp)
    800042ce:	fc4e                	sd	s3,56(sp)
    800042d0:	f852                	sd	s4,48(sp)
    800042d2:	f456                	sd	s5,40(sp)
    800042d4:	f05a                	sd	s6,32(sp)
    800042d6:	ec5e                	sd	s7,24(sp)
    800042d8:	e862                	sd	s8,16(sp)
    800042da:	1080                	addi	s0,sp,96
    800042dc:	84aa                	mv	s1,a0
    800042de:	8aae                	mv	s5,a1
    800042e0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800042e2:	d22fd0ef          	jal	ra,80001804 <myproc>
    800042e6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800042e8:	8526                	mv	a0,s1
    800042ea:	883fc0ef          	jal	ra,80000b6c <acquire>
  while(i < n){
    800042ee:	09405c63          	blez	s4,80004386 <pipewrite+0xc2>
  int i = 0;
    800042f2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800042f4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800042f6:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800042fa:	21c48b93          	addi	s7,s1,540
    800042fe:	a81d                	j	80004334 <pipewrite+0x70>
      release(&pi->lock);
    80004300:	8526                	mv	a0,s1
    80004302:	903fc0ef          	jal	ra,80000c04 <release>
      return -1;
    80004306:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004308:	854a                	mv	a0,s2
    8000430a:	60e6                	ld	ra,88(sp)
    8000430c:	6446                	ld	s0,80(sp)
    8000430e:	64a6                	ld	s1,72(sp)
    80004310:	6906                	ld	s2,64(sp)
    80004312:	79e2                	ld	s3,56(sp)
    80004314:	7a42                	ld	s4,48(sp)
    80004316:	7aa2                	ld	s5,40(sp)
    80004318:	7b02                	ld	s6,32(sp)
    8000431a:	6be2                	ld	s7,24(sp)
    8000431c:	6c42                	ld	s8,16(sp)
    8000431e:	6125                	addi	sp,sp,96
    80004320:	8082                	ret
      wakeup(&pi->nread);
    80004322:	8562                	mv	a0,s8
    80004324:	b35fd0ef          	jal	ra,80001e58 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004328:	85a6                	mv	a1,s1
    8000432a:	855e                	mv	a0,s7
    8000432c:	ae1fd0ef          	jal	ra,80001e0c <sleep>
  while(i < n){
    80004330:	05495c63          	bge	s2,s4,80004388 <pipewrite+0xc4>
    if(pi->readopen == 0 || killed(pr)){
    80004334:	2204a783          	lw	a5,544(s1)
    80004338:	d7e1                	beqz	a5,80004300 <pipewrite+0x3c>
    8000433a:	854e                	mv	a0,s3
    8000433c:	d09fd0ef          	jal	ra,80002044 <killed>
    80004340:	f161                	bnez	a0,80004300 <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004342:	2184a783          	lw	a5,536(s1)
    80004346:	21c4a703          	lw	a4,540(s1)
    8000434a:	2007879b          	addiw	a5,a5,512
    8000434e:	fcf70ae3          	beq	a4,a5,80004322 <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004352:	4685                	li	a3,1
    80004354:	01590633          	add	a2,s2,s5
    80004358:	faf40593          	addi	a1,s0,-81
    8000435c:	0509b503          	ld	a0,80(s3)
    80004360:	ab8fd0ef          	jal	ra,80001618 <copyin>
    80004364:	03650263          	beq	a0,s6,80004388 <pipewrite+0xc4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004368:	21c4a783          	lw	a5,540(s1)
    8000436c:	0017871b          	addiw	a4,a5,1
    80004370:	20e4ae23          	sw	a4,540(s1)
    80004374:	1ff7f793          	andi	a5,a5,511
    80004378:	97a6                	add	a5,a5,s1
    8000437a:	faf44703          	lbu	a4,-81(s0)
    8000437e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004382:	2905                	addiw	s2,s2,1
    80004384:	b775                	j	80004330 <pipewrite+0x6c>
  int i = 0;
    80004386:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004388:	21848513          	addi	a0,s1,536
    8000438c:	acdfd0ef          	jal	ra,80001e58 <wakeup>
  release(&pi->lock);
    80004390:	8526                	mv	a0,s1
    80004392:	873fc0ef          	jal	ra,80000c04 <release>
  return i;
    80004396:	bf8d                	j	80004308 <pipewrite+0x44>

0000000080004398 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004398:	715d                	addi	sp,sp,-80
    8000439a:	e486                	sd	ra,72(sp)
    8000439c:	e0a2                	sd	s0,64(sp)
    8000439e:	fc26                	sd	s1,56(sp)
    800043a0:	f84a                	sd	s2,48(sp)
    800043a2:	f44e                	sd	s3,40(sp)
    800043a4:	f052                	sd	s4,32(sp)
    800043a6:	ec56                	sd	s5,24(sp)
    800043a8:	e85a                	sd	s6,16(sp)
    800043aa:	0880                	addi	s0,sp,80
    800043ac:	84aa                	mv	s1,a0
    800043ae:	892e                	mv	s2,a1
    800043b0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800043b2:	c52fd0ef          	jal	ra,80001804 <myproc>
    800043b6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800043b8:	8526                	mv	a0,s1
    800043ba:	fb2fc0ef          	jal	ra,80000b6c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800043be:	2184a703          	lw	a4,536(s1)
    800043c2:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800043c6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800043ca:	02f71363          	bne	a4,a5,800043f0 <piperead+0x58>
    800043ce:	2244a783          	lw	a5,548(s1)
    800043d2:	cf99                	beqz	a5,800043f0 <piperead+0x58>
    if(killed(pr)){
    800043d4:	8552                	mv	a0,s4
    800043d6:	c6ffd0ef          	jal	ra,80002044 <killed>
    800043da:	e149                	bnez	a0,8000445c <piperead+0xc4>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800043dc:	85a6                	mv	a1,s1
    800043de:	854e                	mv	a0,s3
    800043e0:	a2dfd0ef          	jal	ra,80001e0c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800043e4:	2184a703          	lw	a4,536(s1)
    800043e8:	21c4a783          	lw	a5,540(s1)
    800043ec:	fef701e3          	beq	a4,a5,800043ce <piperead+0x36>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800043f0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800043f2:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800043f4:	05505263          	blez	s5,80004438 <piperead+0xa0>
    if(pi->nread == pi->nwrite)
    800043f8:	2184a783          	lw	a5,536(s1)
    800043fc:	21c4a703          	lw	a4,540(s1)
    80004400:	02f70c63          	beq	a4,a5,80004438 <piperead+0xa0>
    ch = pi->data[pi->nread % PIPESIZE];
    80004404:	1ff7f793          	andi	a5,a5,511
    80004408:	97a6                	add	a5,a5,s1
    8000440a:	0187c783          	lbu	a5,24(a5)
    8000440e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    80004412:	4685                	li	a3,1
    80004414:	fbf40613          	addi	a2,s0,-65
    80004418:	85ca                	mv	a1,s2
    8000441a:	050a3503          	ld	a0,80(s4)
    8000441e:	934fd0ef          	jal	ra,80001552 <copyout>
    80004422:	05650263          	beq	a0,s6,80004466 <piperead+0xce>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    80004426:	2184a783          	lw	a5,536(s1)
    8000442a:	2785                	addiw	a5,a5,1
    8000442c:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004430:	2985                	addiw	s3,s3,1
    80004432:	0905                	addi	s2,s2,1
    80004434:	fd3a92e3          	bne	s5,s3,800043f8 <piperead+0x60>
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004438:	21c48513          	addi	a0,s1,540
    8000443c:	a1dfd0ef          	jal	ra,80001e58 <wakeup>
  release(&pi->lock);
    80004440:	8526                	mv	a0,s1
    80004442:	fc2fc0ef          	jal	ra,80000c04 <release>
  return i;
}
    80004446:	854e                	mv	a0,s3
    80004448:	60a6                	ld	ra,72(sp)
    8000444a:	6406                	ld	s0,64(sp)
    8000444c:	74e2                	ld	s1,56(sp)
    8000444e:	7942                	ld	s2,48(sp)
    80004450:	79a2                	ld	s3,40(sp)
    80004452:	7a02                	ld	s4,32(sp)
    80004454:	6ae2                	ld	s5,24(sp)
    80004456:	6b42                	ld	s6,16(sp)
    80004458:	6161                	addi	sp,sp,80
    8000445a:	8082                	ret
      release(&pi->lock);
    8000445c:	8526                	mv	a0,s1
    8000445e:	fa6fc0ef          	jal	ra,80000c04 <release>
      return -1;
    80004462:	59fd                	li	s3,-1
    80004464:	b7cd                	j	80004446 <piperead+0xae>
      if(i == 0)
    80004466:	fc0999e3          	bnez	s3,80004438 <piperead+0xa0>
        i = -1;
    8000446a:	89aa                	mv	s3,a0
    8000446c:	b7f1                	j	80004438 <piperead+0xa0>

000000008000446e <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    8000446e:	1141                	addi	sp,sp,-16
    80004470:	e422                	sd	s0,8(sp)
    80004472:	0800                	addi	s0,sp,16
    80004474:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004476:	8905                	andi	a0,a0,1
    80004478:	c111                	beqz	a0,8000447c <flags2perm+0xe>
      perm = PTE_X;
    8000447a:	4521                	li	a0,8
    if(flags & 0x2)
    8000447c:	8b89                	andi	a5,a5,2
    8000447e:	c399                	beqz	a5,80004484 <flags2perm+0x16>
      perm |= PTE_W;
    80004480:	00456513          	ori	a0,a0,4
    return perm;
}
    80004484:	6422                	ld	s0,8(sp)
    80004486:	0141                	addi	sp,sp,16
    80004488:	8082                	ret

000000008000448a <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    8000448a:	de010113          	addi	sp,sp,-544
    8000448e:	20113c23          	sd	ra,536(sp)
    80004492:	20813823          	sd	s0,528(sp)
    80004496:	20913423          	sd	s1,520(sp)
    8000449a:	21213023          	sd	s2,512(sp)
    8000449e:	ffce                	sd	s3,504(sp)
    800044a0:	fbd2                	sd	s4,496(sp)
    800044a2:	f7d6                	sd	s5,488(sp)
    800044a4:	f3da                	sd	s6,480(sp)
    800044a6:	efde                	sd	s7,472(sp)
    800044a8:	ebe2                	sd	s8,464(sp)
    800044aa:	e7e6                	sd	s9,456(sp)
    800044ac:	e3ea                	sd	s10,448(sp)
    800044ae:	ff6e                	sd	s11,440(sp)
    800044b0:	1400                	addi	s0,sp,544
    800044b2:	892a                	mv	s2,a0
    800044b4:	dea43423          	sd	a0,-536(s0)
    800044b8:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800044bc:	b48fd0ef          	jal	ra,80001804 <myproc>
    800044c0:	84aa                	mv	s1,a0

  begin_op();
    800044c2:	e0eff0ef          	jal	ra,80003ad0 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    800044c6:	854a                	mv	a0,s2
    800044c8:	c18ff0ef          	jal	ra,800038e0 <namei>
    800044cc:	c13d                	beqz	a0,80004532 <kexec+0xa8>
    800044ce:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800044d0:	c23fe0ef          	jal	ra,800030f2 <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800044d4:	04000713          	li	a4,64
    800044d8:	4681                	li	a3,0
    800044da:	e5040613          	addi	a2,s0,-432
    800044de:	4581                	li	a1,0
    800044e0:	8556                	mv	a0,s5
    800044e2:	f9dfe0ef          	jal	ra,8000347e <readi>
    800044e6:	04000793          	li	a5,64
    800044ea:	00f51a63          	bne	a0,a5,800044fe <kexec+0x74>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    800044ee:	e5042703          	lw	a4,-432(s0)
    800044f2:	464c47b7          	lui	a5,0x464c4
    800044f6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800044fa:	04f70063          	beq	a4,a5,8000453a <kexec+0xb0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800044fe:	8556                	mv	a0,s5
    80004500:	df9fe0ef          	jal	ra,800032f8 <iunlockput>
    end_op();
    80004504:	e3cff0ef          	jal	ra,80003b40 <end_op>
  }
  return -1;
    80004508:	557d                	li	a0,-1
}
    8000450a:	21813083          	ld	ra,536(sp)
    8000450e:	21013403          	ld	s0,528(sp)
    80004512:	20813483          	ld	s1,520(sp)
    80004516:	20013903          	ld	s2,512(sp)
    8000451a:	79fe                	ld	s3,504(sp)
    8000451c:	7a5e                	ld	s4,496(sp)
    8000451e:	7abe                	ld	s5,488(sp)
    80004520:	7b1e                	ld	s6,480(sp)
    80004522:	6bfe                	ld	s7,472(sp)
    80004524:	6c5e                	ld	s8,464(sp)
    80004526:	6cbe                	ld	s9,456(sp)
    80004528:	6d1e                	ld	s10,448(sp)
    8000452a:	7dfa                	ld	s11,440(sp)
    8000452c:	22010113          	addi	sp,sp,544
    80004530:	8082                	ret
    end_op();
    80004532:	e0eff0ef          	jal	ra,80003b40 <end_op>
    return -1;
    80004536:	557d                	li	a0,-1
    80004538:	bfc9                	j	8000450a <kexec+0x80>
  if((pagetable = proc_pagetable(p)) == 0)
    8000453a:	8526                	mv	a0,s1
    8000453c:	bcefd0ef          	jal	ra,8000190a <proc_pagetable>
    80004540:	8b2a                	mv	s6,a0
    80004542:	dd55                	beqz	a0,800044fe <kexec+0x74>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004544:	e7042783          	lw	a5,-400(s0)
    80004548:	e8845703          	lhu	a4,-376(s0)
    8000454c:	c325                	beqz	a4,800045ac <kexec+0x122>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000454e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004550:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004554:	6a05                	lui	s4,0x1
    80004556:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000455a:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000455e:	6d85                	lui	s11,0x1
    80004560:	7d7d                	lui	s10,0xfffff
    80004562:	a411                	j	80004766 <kexec+0x2dc>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004564:	00003517          	auipc	a0,0x3
    80004568:	14c50513          	addi	a0,a0,332 # 800076b0 <syscalls+0x2c0>
    8000456c:	a1efc0ef          	jal	ra,8000078a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004570:	874a                	mv	a4,s2
    80004572:	009c86bb          	addw	a3,s9,s1
    80004576:	4581                	li	a1,0
    80004578:	8556                	mv	a0,s5
    8000457a:	f05fe0ef          	jal	ra,8000347e <readi>
    8000457e:	2501                	sext.w	a0,a0
    80004580:	18a91263          	bne	s2,a0,80004704 <kexec+0x27a>
  for(i = 0; i < sz; i += PGSIZE){
    80004584:	009d84bb          	addw	s1,s11,s1
    80004588:	013d09bb          	addw	s3,s10,s3
    8000458c:	1b74fd63          	bgeu	s1,s7,80004746 <kexec+0x2bc>
    pa = walkaddr(pagetable, va + i);
    80004590:	02049593          	slli	a1,s1,0x20
    80004594:	9181                	srli	a1,a1,0x20
    80004596:	95e2                	add	a1,a1,s8
    80004598:	855a                	mv	a0,s6
    8000459a:	9bdfc0ef          	jal	ra,80000f56 <walkaddr>
    8000459e:	862a                	mv	a2,a0
    if(pa == 0)
    800045a0:	d171                	beqz	a0,80004564 <kexec+0xda>
      n = PGSIZE;
    800045a2:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800045a4:	fd49f6e3          	bgeu	s3,s4,80004570 <kexec+0xe6>
      n = sz - i;
    800045a8:	894e                	mv	s2,s3
    800045aa:	b7d9                	j	80004570 <kexec+0xe6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800045ac:	4901                	li	s2,0
  iunlockput(ip);
    800045ae:	8556                	mv	a0,s5
    800045b0:	d49fe0ef          	jal	ra,800032f8 <iunlockput>
  end_op();
    800045b4:	d8cff0ef          	jal	ra,80003b40 <end_op>
  p = myproc();
    800045b8:	a4cfd0ef          	jal	ra,80001804 <myproc>
    800045bc:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800045be:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800045c2:	6785                	lui	a5,0x1
    800045c4:	17fd                	addi	a5,a5,-1
    800045c6:	993e                	add	s2,s2,a5
    800045c8:	77fd                	lui	a5,0xfffff
    800045ca:	00f977b3          	and	a5,s2,a5
    800045ce:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    800045d2:	4691                	li	a3,4
    800045d4:	6609                	lui	a2,0x2
    800045d6:	963e                	add	a2,a2,a5
    800045d8:	85be                	mv	a1,a5
    800045da:	855a                	mv	a0,s6
    800045dc:	c45fc0ef          	jal	ra,80001220 <uvmalloc>
    800045e0:	8c2a                	mv	s8,a0
  ip = 0;
    800045e2:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    800045e4:	12050063          	beqz	a0,80004704 <kexec+0x27a>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    800045e8:	75f9                	lui	a1,0xffffe
    800045ea:	95aa                	add	a1,a1,a0
    800045ec:	855a                	mv	a0,s6
    800045ee:	df9fc0ef          	jal	ra,800013e6 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    800045f2:	7afd                	lui	s5,0xfffff
    800045f4:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800045f6:	df043783          	ld	a5,-528(s0)
    800045fa:	6388                	ld	a0,0(a5)
    800045fc:	c135                	beqz	a0,80004660 <kexec+0x1d6>
    800045fe:	e9040993          	addi	s3,s0,-368
    80004602:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004606:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004608:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000460a:	faefc0ef          	jal	ra,80000db8 <strlen>
    8000460e:	0015079b          	addiw	a5,a0,1
    80004612:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004616:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000461a:	11596a63          	bltu	s2,s5,8000472e <kexec+0x2a4>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000461e:	df043d83          	ld	s11,-528(s0)
    80004622:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004626:	8552                	mv	a0,s4
    80004628:	f90fc0ef          	jal	ra,80000db8 <strlen>
    8000462c:	0015069b          	addiw	a3,a0,1
    80004630:	8652                	mv	a2,s4
    80004632:	85ca                	mv	a1,s2
    80004634:	855a                	mv	a0,s6
    80004636:	f1dfc0ef          	jal	ra,80001552 <copyout>
    8000463a:	0e054e63          	bltz	a0,80004736 <kexec+0x2ac>
    ustack[argc] = sp;
    8000463e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004642:	0485                	addi	s1,s1,1
    80004644:	008d8793          	addi	a5,s11,8
    80004648:	def43823          	sd	a5,-528(s0)
    8000464c:	008db503          	ld	a0,8(s11)
    80004650:	c911                	beqz	a0,80004664 <kexec+0x1da>
    if(argc >= MAXARG)
    80004652:	09a1                	addi	s3,s3,8
    80004654:	fb3c9be3          	bne	s9,s3,8000460a <kexec+0x180>
  sz = sz1;
    80004658:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000465c:	4a81                	li	s5,0
    8000465e:	a05d                	j	80004704 <kexec+0x27a>
  sp = sz;
    80004660:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004662:	4481                	li	s1,0
  ustack[argc] = 0;
    80004664:	00349793          	slli	a5,s1,0x3
    80004668:	f9040713          	addi	a4,s0,-112
    8000466c:	97ba                	add	a5,a5,a4
    8000466e:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffde398>
  sp -= (argc+1) * sizeof(uint64);
    80004672:	00148693          	addi	a3,s1,1
    80004676:	068e                	slli	a3,a3,0x3
    80004678:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000467c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004680:	01597663          	bgeu	s2,s5,8000468c <kexec+0x202>
  sz = sz1;
    80004684:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004688:	4a81                	li	s5,0
    8000468a:	a8ad                	j	80004704 <kexec+0x27a>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000468c:	e9040613          	addi	a2,s0,-368
    80004690:	85ca                	mv	a1,s2
    80004692:	855a                	mv	a0,s6
    80004694:	ebffc0ef          	jal	ra,80001552 <copyout>
    80004698:	0a054363          	bltz	a0,8000473e <kexec+0x2b4>
  p->trapframe->a1 = sp;
    8000469c:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800046a0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800046a4:	de843783          	ld	a5,-536(s0)
    800046a8:	0007c703          	lbu	a4,0(a5)
    800046ac:	cf11                	beqz	a4,800046c8 <kexec+0x23e>
    800046ae:	0785                	addi	a5,a5,1
    if(*s == '/')
    800046b0:	02f00693          	li	a3,47
    800046b4:	a039                	j	800046c2 <kexec+0x238>
      last = s+1;
    800046b6:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800046ba:	0785                	addi	a5,a5,1
    800046bc:	fff7c703          	lbu	a4,-1(a5)
    800046c0:	c701                	beqz	a4,800046c8 <kexec+0x23e>
    if(*s == '/')
    800046c2:	fed71ce3          	bne	a4,a3,800046ba <kexec+0x230>
    800046c6:	bfc5                	j	800046b6 <kexec+0x22c>
  safestrcpy(p->name, last, sizeof(p->name));
    800046c8:	4641                	li	a2,16
    800046ca:	de843583          	ld	a1,-536(s0)
    800046ce:	158b8513          	addi	a0,s7,344
    800046d2:	eb4fc0ef          	jal	ra,80000d86 <safestrcpy>
  oldpagetable = p->pagetable;
    800046d6:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800046da:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800046de:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    800046e2:	058bb783          	ld	a5,88(s7)
    800046e6:	e6843703          	ld	a4,-408(s0)
    800046ea:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800046ec:	058bb783          	ld	a5,88(s7)
    800046f0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800046f4:	85ea                	mv	a1,s10
    800046f6:	a98fd0ef          	jal	ra,8000198e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800046fa:	0004851b          	sext.w	a0,s1
    800046fe:	b531                	j	8000450a <kexec+0x80>
    80004700:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004704:	df843583          	ld	a1,-520(s0)
    80004708:	855a                	mv	a0,s6
    8000470a:	a84fd0ef          	jal	ra,8000198e <proc_freepagetable>
  if(ip){
    8000470e:	de0a98e3          	bnez	s5,800044fe <kexec+0x74>
  return -1;
    80004712:	557d                	li	a0,-1
    80004714:	bbdd                	j	8000450a <kexec+0x80>
    80004716:	df243c23          	sd	s2,-520(s0)
    8000471a:	b7ed                	j	80004704 <kexec+0x27a>
    8000471c:	df243c23          	sd	s2,-520(s0)
    80004720:	b7d5                	j	80004704 <kexec+0x27a>
    80004722:	df243c23          	sd	s2,-520(s0)
    80004726:	bff9                	j	80004704 <kexec+0x27a>
    80004728:	df243c23          	sd	s2,-520(s0)
    8000472c:	bfe1                	j	80004704 <kexec+0x27a>
  sz = sz1;
    8000472e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004732:	4a81                	li	s5,0
    80004734:	bfc1                	j	80004704 <kexec+0x27a>
  sz = sz1;
    80004736:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000473a:	4a81                	li	s5,0
    8000473c:	b7e1                	j	80004704 <kexec+0x27a>
  sz = sz1;
    8000473e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004742:	4a81                	li	s5,0
    80004744:	b7c1                	j	80004704 <kexec+0x27a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004746:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000474a:	e0843783          	ld	a5,-504(s0)
    8000474e:	0017869b          	addiw	a3,a5,1
    80004752:	e0d43423          	sd	a3,-504(s0)
    80004756:	e0043783          	ld	a5,-512(s0)
    8000475a:	0387879b          	addiw	a5,a5,56
    8000475e:	e8845703          	lhu	a4,-376(s0)
    80004762:	e4e6d6e3          	bge	a3,a4,800045ae <kexec+0x124>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004766:	2781                	sext.w	a5,a5
    80004768:	e0f43023          	sd	a5,-512(s0)
    8000476c:	03800713          	li	a4,56
    80004770:	86be                	mv	a3,a5
    80004772:	e1840613          	addi	a2,s0,-488
    80004776:	4581                	li	a1,0
    80004778:	8556                	mv	a0,s5
    8000477a:	d05fe0ef          	jal	ra,8000347e <readi>
    8000477e:	03800793          	li	a5,56
    80004782:	f6f51fe3          	bne	a0,a5,80004700 <kexec+0x276>
    if(ph.type != ELF_PROG_LOAD)
    80004786:	e1842783          	lw	a5,-488(s0)
    8000478a:	4705                	li	a4,1
    8000478c:	fae79fe3          	bne	a5,a4,8000474a <kexec+0x2c0>
    if(ph.memsz < ph.filesz)
    80004790:	e4043483          	ld	s1,-448(s0)
    80004794:	e3843783          	ld	a5,-456(s0)
    80004798:	f6f4efe3          	bltu	s1,a5,80004716 <kexec+0x28c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000479c:	e2843783          	ld	a5,-472(s0)
    800047a0:	94be                	add	s1,s1,a5
    800047a2:	f6f4ede3          	bltu	s1,a5,8000471c <kexec+0x292>
    if(ph.vaddr % PGSIZE != 0)
    800047a6:	de043703          	ld	a4,-544(s0)
    800047aa:	8ff9                	and	a5,a5,a4
    800047ac:	fbbd                	bnez	a5,80004722 <kexec+0x298>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800047ae:	e1c42503          	lw	a0,-484(s0)
    800047b2:	cbdff0ef          	jal	ra,8000446e <flags2perm>
    800047b6:	86aa                	mv	a3,a0
    800047b8:	8626                	mv	a2,s1
    800047ba:	85ca                	mv	a1,s2
    800047bc:	855a                	mv	a0,s6
    800047be:	a63fc0ef          	jal	ra,80001220 <uvmalloc>
    800047c2:	dea43c23          	sd	a0,-520(s0)
    800047c6:	d12d                	beqz	a0,80004728 <kexec+0x29e>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800047c8:	e2843c03          	ld	s8,-472(s0)
    800047cc:	e2042c83          	lw	s9,-480(s0)
    800047d0:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800047d4:	f60b89e3          	beqz	s7,80004746 <kexec+0x2bc>
    800047d8:	89de                	mv	s3,s7
    800047da:	4481                	li	s1,0
    800047dc:	bb55                	j	80004590 <kexec+0x106>

00000000800047de <argfd>:
#include "fcntl.h"

// 获取第n个系统调用参数作为文件描述符，并返回该描述符及对应的文件结构。
static int
argfd(int n, int *pfd, struct file **pf)
{
    800047de:	7179                	addi	sp,sp,-48
    800047e0:	f406                	sd	ra,40(sp)
    800047e2:	f022                	sd	s0,32(sp)
    800047e4:	ec26                	sd	s1,24(sp)
    800047e6:	e84a                	sd	s2,16(sp)
    800047e8:	1800                	addi	s0,sp,48
    800047ea:	892e                	mv	s2,a1
    800047ec:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);  // 获取系统调用参数中的文件描述符
    800047ee:	fdc40593          	addi	a1,s0,-36
    800047f2:	f19fd0ef          	jal	ra,8000270a <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)  // 检查文件描述符的有效性
    800047f6:	fdc42703          	lw	a4,-36(s0)
    800047fa:	47bd                	li	a5,15
    800047fc:	02e7e963          	bltu	a5,a4,8000482e <argfd+0x50>
    80004800:	804fd0ef          	jal	ra,80001804 <myproc>
    80004804:	fdc42703          	lw	a4,-36(s0)
    80004808:	01a70793          	addi	a5,a4,26
    8000480c:	078e                	slli	a5,a5,0x3
    8000480e:	953e                	add	a0,a0,a5
    80004810:	611c                	ld	a5,0(a0)
    80004812:	c385                	beqz	a5,80004832 <argfd+0x54>
    return -1;
  if(pfd)
    80004814:	00090463          	beqz	s2,8000481c <argfd+0x3e>
    *pfd = fd;
    80004818:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000481c:	4501                	li	a0,0
  if(pf)
    8000481e:	c091                	beqz	s1,80004822 <argfd+0x44>
    *pf = f;
    80004820:	e09c                	sd	a5,0(s1)
}
    80004822:	70a2                	ld	ra,40(sp)
    80004824:	7402                	ld	s0,32(sp)
    80004826:	64e2                	ld	s1,24(sp)
    80004828:	6942                	ld	s2,16(sp)
    8000482a:	6145                	addi	sp,sp,48
    8000482c:	8082                	ret
    return -1;
    8000482e:	557d                	li	a0,-1
    80004830:	bfcd                	j	80004822 <argfd+0x44>
    80004832:	557d                	li	a0,-1
    80004834:	b7fd                	j	80004822 <argfd+0x44>

0000000080004836 <fdalloc>:

// 为给定文件分配一个文件描述符。
// 成功时接管调用者的文件引用。
static int
fdalloc(struct file *f)
{
    80004836:	1101                	addi	sp,sp,-32
    80004838:	ec06                	sd	ra,24(sp)
    8000483a:	e822                	sd	s0,16(sp)
    8000483c:	e426                	sd	s1,8(sp)
    8000483e:	1000                	addi	s0,sp,32
    80004840:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004842:	fc3fc0ef          	jal	ra,80001804 <myproc>
    80004846:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004848:	0d050793          	addi	a5,a0,208
    8000484c:	4501                	li	a0,0
    8000484e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){  // 查找一个未使用的文件描述符
    80004850:	6398                	ld	a4,0(a5)
    80004852:	cb19                	beqz	a4,80004868 <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004854:	2505                	addiw	a0,a0,1
    80004856:	07a1                	addi	a5,a5,8
    80004858:	fed51ce3          	bne	a0,a3,80004850 <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;  // 没有可用的文件描述符
    8000485c:	557d                	li	a0,-1
}
    8000485e:	60e2                	ld	ra,24(sp)
    80004860:	6442                	ld	s0,16(sp)
    80004862:	64a2                	ld	s1,8(sp)
    80004864:	6105                	addi	sp,sp,32
    80004866:	8082                	ret
      p->ofile[fd] = f;
    80004868:	01a50793          	addi	a5,a0,26
    8000486c:	078e                	slli	a5,a5,0x3
    8000486e:	963e                	add	a2,a2,a5
    80004870:	e204                	sd	s1,0(a2)
      return fd;
    80004872:	b7f5                	j	8000485e <fdalloc+0x28>

0000000080004874 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004874:	715d                	addi	sp,sp,-80
    80004876:	e486                	sd	ra,72(sp)
    80004878:	e0a2                	sd	s0,64(sp)
    8000487a:	fc26                	sd	s1,56(sp)
    8000487c:	f84a                	sd	s2,48(sp)
    8000487e:	f44e                	sd	s3,40(sp)
    80004880:	f052                	sd	s4,32(sp)
    80004882:	ec56                	sd	s5,24(sp)
    80004884:	e85a                	sd	s6,16(sp)
    80004886:	0880                	addi	s0,sp,80
    80004888:	8b2e                	mv	s6,a1
    8000488a:	89b2                	mv	s3,a2
    8000488c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)  // 查找父目录
    8000488e:	fb040593          	addi	a1,s0,-80
    80004892:	868ff0ef          	jal	ra,800038fa <nameiparent>
    80004896:	84aa                	mv	s1,a0
    80004898:	10050b63          	beqz	a0,800049ae <create+0x13a>
    return 0;

  ilock(dp);
    8000489c:	857fe0ef          	jal	ra,800030f2 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){  // 检查文件是否已存在
    800048a0:	4601                	li	a2,0
    800048a2:	fb040593          	addi	a1,s0,-80
    800048a6:	8526                	mv	a0,s1
    800048a8:	dd3fe0ef          	jal	ra,8000367a <dirlookup>
    800048ac:	8aaa                	mv	s5,a0
    800048ae:	c521                	beqz	a0,800048f6 <create+0x82>
    iunlockput(dp);
    800048b0:	8526                	mv	a0,s1
    800048b2:	a47fe0ef          	jal	ra,800032f8 <iunlockput>
    ilock(ip);
    800048b6:	8556                	mv	a0,s5
    800048b8:	83bfe0ef          	jal	ra,800030f2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800048bc:	000b059b          	sext.w	a1,s6
    800048c0:	4789                	li	a5,2
    800048c2:	02f59563          	bne	a1,a5,800048ec <create+0x78>
    800048c6:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffde4dc>
    800048ca:	37f9                	addiw	a5,a5,-2
    800048cc:	17c2                	slli	a5,a5,0x30
    800048ce:	93c1                	srli	a5,a5,0x30
    800048d0:	4705                	li	a4,1
    800048d2:	00f76d63          	bltu	a4,a5,800048ec <create+0x78>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800048d6:	8556                	mv	a0,s5
    800048d8:	60a6                	ld	ra,72(sp)
    800048da:	6406                	ld	s0,64(sp)
    800048dc:	74e2                	ld	s1,56(sp)
    800048de:	7942                	ld	s2,48(sp)
    800048e0:	79a2                	ld	s3,40(sp)
    800048e2:	7a02                	ld	s4,32(sp)
    800048e4:	6ae2                	ld	s5,24(sp)
    800048e6:	6b42                	ld	s6,16(sp)
    800048e8:	6161                	addi	sp,sp,80
    800048ea:	8082                	ret
    iunlockput(ip);
    800048ec:	8556                	mv	a0,s5
    800048ee:	a0bfe0ef          	jal	ra,800032f8 <iunlockput>
    return 0;
    800048f2:	4a81                	li	s5,0
    800048f4:	b7cd                	j	800048d6 <create+0x62>
  if((ip = ialloc(dp->dev, type)) == 0){  // 分配 inode
    800048f6:	85da                	mv	a1,s6
    800048f8:	4088                	lw	a0,0(s1)
    800048fa:	e90fe0ef          	jal	ra,80002f8a <ialloc>
    800048fe:	8a2a                	mv	s4,a0
    80004900:	cd1d                	beqz	a0,8000493e <create+0xca>
  ilock(ip);
    80004902:	ff0fe0ef          	jal	ra,800030f2 <ilock>
  ip->major = major;
    80004906:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000490a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000490e:	4905                	li	s2,1
    80004910:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004914:	8552                	mv	a0,s4
    80004916:	f2afe0ef          	jal	ra,80003040 <iupdate>
  if(type == T_DIR){  // 创建 . 和 .. 目录项
    8000491a:	000b059b          	sext.w	a1,s6
    8000491e:	03258563          	beq	a1,s2,80004948 <create+0xd4>
  if(dirlink(dp, name, ip->inum) < 0)
    80004922:	004a2603          	lw	a2,4(s4)
    80004926:	fb040593          	addi	a1,s0,-80
    8000492a:	8526                	mv	a0,s1
    8000492c:	f1bfe0ef          	jal	ra,80003846 <dirlink>
    80004930:	06054363          	bltz	a0,80004996 <create+0x122>
  iunlockput(dp);
    80004934:	8526                	mv	a0,s1
    80004936:	9c3fe0ef          	jal	ra,800032f8 <iunlockput>
  return ip;
    8000493a:	8ad2                	mv	s5,s4
    8000493c:	bf69                	j	800048d6 <create+0x62>
    iunlockput(dp);
    8000493e:	8526                	mv	a0,s1
    80004940:	9b9fe0ef          	jal	ra,800032f8 <iunlockput>
    return 0;
    80004944:	8ad2                	mv	s5,s4
    80004946:	bf41                	j	800048d6 <create+0x62>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004948:	004a2603          	lw	a2,4(s4)
    8000494c:	00003597          	auipc	a1,0x3
    80004950:	d8458593          	addi	a1,a1,-636 # 800076d0 <syscalls+0x2e0>
    80004954:	8552                	mv	a0,s4
    80004956:	ef1fe0ef          	jal	ra,80003846 <dirlink>
    8000495a:	02054e63          	bltz	a0,80004996 <create+0x122>
    8000495e:	40d0                	lw	a2,4(s1)
    80004960:	00003597          	auipc	a1,0x3
    80004964:	d7858593          	addi	a1,a1,-648 # 800076d8 <syscalls+0x2e8>
    80004968:	8552                	mv	a0,s4
    8000496a:	eddfe0ef          	jal	ra,80003846 <dirlink>
    8000496e:	02054463          	bltz	a0,80004996 <create+0x122>
  if(dirlink(dp, name, ip->inum) < 0)
    80004972:	004a2603          	lw	a2,4(s4)
    80004976:	fb040593          	addi	a1,s0,-80
    8000497a:	8526                	mv	a0,s1
    8000497c:	ecbfe0ef          	jal	ra,80003846 <dirlink>
    80004980:	00054b63          	bltz	a0,80004996 <create+0x122>
    dp->nlink++;  // 更新父目录的链接计数
    80004984:	04a4d783          	lhu	a5,74(s1)
    80004988:	2785                	addiw	a5,a5,1
    8000498a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000498e:	8526                	mv	a0,s1
    80004990:	eb0fe0ef          	jal	ra,80003040 <iupdate>
    80004994:	b745                	j	80004934 <create+0xc0>
  ip->nlink = 0;
    80004996:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000499a:	8552                	mv	a0,s4
    8000499c:	ea4fe0ef          	jal	ra,80003040 <iupdate>
  iunlockput(ip);
    800049a0:	8552                	mv	a0,s4
    800049a2:	957fe0ef          	jal	ra,800032f8 <iunlockput>
  iunlockput(dp);
    800049a6:	8526                	mv	a0,s1
    800049a8:	951fe0ef          	jal	ra,800032f8 <iunlockput>
  return 0;
    800049ac:	b72d                	j	800048d6 <create+0x62>
    return 0;
    800049ae:	8aaa                	mv	s5,a0
    800049b0:	b71d                	j	800048d6 <create+0x62>

00000000800049b2 <sys_dup>:
{
    800049b2:	7179                	addi	sp,sp,-48
    800049b4:	f406                	sd	ra,40(sp)
    800049b6:	f022                	sd	s0,32(sp)
    800049b8:	ec26                	sd	s1,24(sp)
    800049ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    800049bc:	fd840613          	addi	a2,s0,-40
    800049c0:	4581                	li	a1,0
    800049c2:	4501                	li	a0,0
    800049c4:	e1bff0ef          	jal	ra,800047de <argfd>
    return -1;
    800049c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    800049ca:	00054f63          	bltz	a0,800049e8 <sys_dup+0x36>
  if((fd=fdalloc(f)) < 0)  // 为文件分配新的文件描述符
    800049ce:	fd843503          	ld	a0,-40(s0)
    800049d2:	e65ff0ef          	jal	ra,80004836 <fdalloc>
    800049d6:	84aa                	mv	s1,a0
    return -1;
    800049d8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)  // 为文件分配新的文件描述符
    800049da:	00054763          	bltz	a0,800049e8 <sys_dup+0x36>
  filedup(f);  // 增加文件引用计数
    800049de:	fd843503          	ld	a0,-40(s0)
    800049e2:	cb6ff0ef          	jal	ra,80003e98 <filedup>
  return fd;
    800049e6:	87a6                	mv	a5,s1
}
    800049e8:	853e                	mv	a0,a5
    800049ea:	70a2                	ld	ra,40(sp)
    800049ec:	7402                	ld	s0,32(sp)
    800049ee:	64e2                	ld	s1,24(sp)
    800049f0:	6145                	addi	sp,sp,48
    800049f2:	8082                	ret

00000000800049f4 <sys_read>:
{
    800049f4:	7179                	addi	sp,sp,-48
    800049f6:	f406                	sd	ra,40(sp)
    800049f8:	f022                	sd	s0,32(sp)
    800049fa:	1800                	addi	s0,sp,48
  argaddr(1, &p);  // 获取读取数据的用户空间地址
    800049fc:	fd840593          	addi	a1,s0,-40
    80004a00:	4505                	li	a0,1
    80004a02:	d25fd0ef          	jal	ra,80002726 <argaddr>
  argint(2, &n);  // 获取读取字节数
    80004a06:	fe440593          	addi	a1,s0,-28
    80004a0a:	4509                	li	a0,2
    80004a0c:	cfffd0ef          	jal	ra,8000270a <argint>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004a10:	fe840613          	addi	a2,s0,-24
    80004a14:	4581                	li	a1,0
    80004a16:	4501                	li	a0,0
    80004a18:	dc7ff0ef          	jal	ra,800047de <argfd>
    80004a1c:	87aa                	mv	a5,a0
    return -1;
    80004a1e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004a20:	0007ca63          	bltz	a5,80004a34 <sys_read+0x40>
  return fileread(f, p, n);  // 从文件中读取数据
    80004a24:	fe442603          	lw	a2,-28(s0)
    80004a28:	fd843583          	ld	a1,-40(s0)
    80004a2c:	fe843503          	ld	a0,-24(s0)
    80004a30:	db4ff0ef          	jal	ra,80003fe4 <fileread>
}
    80004a34:	70a2                	ld	ra,40(sp)
    80004a36:	7402                	ld	s0,32(sp)
    80004a38:	6145                	addi	sp,sp,48
    80004a3a:	8082                	ret

0000000080004a3c <sys_write>:
{
    80004a3c:	7179                	addi	sp,sp,-48
    80004a3e:	f406                	sd	ra,40(sp)
    80004a40:	f022                	sd	s0,32(sp)
    80004a42:	1800                	addi	s0,sp,48
  argaddr(1, &p);  // 获取写入数据的用户空间地址
    80004a44:	fd840593          	addi	a1,s0,-40
    80004a48:	4505                	li	a0,1
    80004a4a:	cddfd0ef          	jal	ra,80002726 <argaddr>
  argint(2, &n);  // 获取写入字节数
    80004a4e:	fe440593          	addi	a1,s0,-28
    80004a52:	4509                	li	a0,2
    80004a54:	cb7fd0ef          	jal	ra,8000270a <argint>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004a58:	fe840613          	addi	a2,s0,-24
    80004a5c:	4581                	li	a1,0
    80004a5e:	4501                	li	a0,0
    80004a60:	d7fff0ef          	jal	ra,800047de <argfd>
    80004a64:	87aa                	mv	a5,a0
    return -1;
    80004a66:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004a68:	0007ca63          	bltz	a5,80004a7c <sys_write+0x40>
  return filewrite(f, p, n);  // 向文件中写入数据
    80004a6c:	fe442603          	lw	a2,-28(s0)
    80004a70:	fd843583          	ld	a1,-40(s0)
    80004a74:	fe843503          	ld	a0,-24(s0)
    80004a78:	e1aff0ef          	jal	ra,80004092 <filewrite>
}
    80004a7c:	70a2                	ld	ra,40(sp)
    80004a7e:	7402                	ld	s0,32(sp)
    80004a80:	6145                	addi	sp,sp,48
    80004a82:	8082                	ret

0000000080004a84 <sys_close>:
{
    80004a84:	1101                	addi	sp,sp,-32
    80004a86:	ec06                	sd	ra,24(sp)
    80004a88:	e822                	sd	s0,16(sp)
    80004a8a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)  // 获取文件描述符并返回文件结构
    80004a8c:	fe040613          	addi	a2,s0,-32
    80004a90:	fec40593          	addi	a1,s0,-20
    80004a94:	4501                	li	a0,0
    80004a96:	d49ff0ef          	jal	ra,800047de <argfd>
    return -1;
    80004a9a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)  // 获取文件描述符并返回文件结构
    80004a9c:	02054063          	bltz	a0,80004abc <sys_close+0x38>
  myproc()->ofile[fd] = 0;  // 关闭文件描述符
    80004aa0:	d65fc0ef          	jal	ra,80001804 <myproc>
    80004aa4:	fec42783          	lw	a5,-20(s0)
    80004aa8:	07e9                	addi	a5,a5,26
    80004aaa:	078e                	slli	a5,a5,0x3
    80004aac:	97aa                	add	a5,a5,a0
    80004aae:	0007b023          	sd	zero,0(a5)
  fileclose(f);  // 关闭文件
    80004ab2:	fe043503          	ld	a0,-32(s0)
    80004ab6:	c28ff0ef          	jal	ra,80003ede <fileclose>
  return 0;
    80004aba:	4781                	li	a5,0
}
    80004abc:	853e                	mv	a0,a5
    80004abe:	60e2                	ld	ra,24(sp)
    80004ac0:	6442                	ld	s0,16(sp)
    80004ac2:	6105                	addi	sp,sp,32
    80004ac4:	8082                	ret

0000000080004ac6 <sys_fstat>:
{
    80004ac6:	1101                	addi	sp,sp,-32
    80004ac8:	ec06                	sd	ra,24(sp)
    80004aca:	e822                	sd	s0,16(sp)
    80004acc:	1000                	addi	s0,sp,32
  argaddr(1, &st);  // 获取 stat 结构体地址
    80004ace:	fe040593          	addi	a1,s0,-32
    80004ad2:	4505                	li	a0,1
    80004ad4:	c53fd0ef          	jal	ra,80002726 <argaddr>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004ad8:	fe840613          	addi	a2,s0,-24
    80004adc:	4581                	li	a1,0
    80004ade:	4501                	li	a0,0
    80004ae0:	cffff0ef          	jal	ra,800047de <argfd>
    80004ae4:	87aa                	mv	a5,a0
    return -1;
    80004ae6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004ae8:	0007c863          	bltz	a5,80004af8 <sys_fstat+0x32>
  return filestat(f, st);  // 获取文件状态信息
    80004aec:	fe043583          	ld	a1,-32(s0)
    80004af0:	fe843503          	ld	a0,-24(s0)
    80004af4:	c92ff0ef          	jal	ra,80003f86 <filestat>
}
    80004af8:	60e2                	ld	ra,24(sp)
    80004afa:	6442                	ld	s0,16(sp)
    80004afc:	6105                	addi	sp,sp,32
    80004afe:	8082                	ret

0000000080004b00 <sys_link>:
{
    80004b00:	7169                	addi	sp,sp,-304
    80004b02:	f606                	sd	ra,296(sp)
    80004b04:	f222                	sd	s0,288(sp)
    80004b06:	ee26                	sd	s1,280(sp)
    80004b08:	ea4a                	sd	s2,272(sp)
    80004b0a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004b0c:	08000613          	li	a2,128
    80004b10:	ed040593          	addi	a1,s0,-304
    80004b14:	4501                	li	a0,0
    80004b16:	c2dfd0ef          	jal	ra,80002742 <argstr>
    return -1;
    80004b1a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004b1c:	0c054663          	bltz	a0,80004be8 <sys_link+0xe8>
    80004b20:	08000613          	li	a2,128
    80004b24:	f5040593          	addi	a1,s0,-176
    80004b28:	4505                	li	a0,1
    80004b2a:	c19fd0ef          	jal	ra,80002742 <argstr>
    return -1;
    80004b2e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004b30:	0a054c63          	bltz	a0,80004be8 <sys_link+0xe8>
  begin_op();
    80004b34:	f9dfe0ef          	jal	ra,80003ad0 <begin_op>
  if((ip = namei(old)) == 0){  // 查找 old 路径对应的 inode
    80004b38:	ed040513          	addi	a0,s0,-304
    80004b3c:	da5fe0ef          	jal	ra,800038e0 <namei>
    80004b40:	84aa                	mv	s1,a0
    80004b42:	c525                	beqz	a0,80004baa <sys_link+0xaa>
  ilock(ip);
    80004b44:	daefe0ef          	jal	ra,800030f2 <ilock>
  if(ip->type == T_DIR){  // 如果是目录，不能创建链接
    80004b48:	04449703          	lh	a4,68(s1)
    80004b4c:	4785                	li	a5,1
    80004b4e:	06f70263          	beq	a4,a5,80004bb2 <sys_link+0xb2>
  ip->nlink++;  // 增加链接计数
    80004b52:	04a4d783          	lhu	a5,74(s1)
    80004b56:	2785                	addiw	a5,a5,1
    80004b58:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004b5c:	8526                	mv	a0,s1
    80004b5e:	ce2fe0ef          	jal	ra,80003040 <iupdate>
  iunlock(ip);
    80004b62:	8526                	mv	a0,s1
    80004b64:	e38fe0ef          	jal	ra,8000319c <iunlock>
  if((dp = nameiparent(new, name)) == 0)  // 获取 new 路径的父目录
    80004b68:	fd040593          	addi	a1,s0,-48
    80004b6c:	f5040513          	addi	a0,s0,-176
    80004b70:	d8bfe0ef          	jal	ra,800038fa <nameiparent>
    80004b74:	892a                	mv	s2,a0
    80004b76:	c921                	beqz	a0,80004bc6 <sys_link+0xc6>
  ilock(dp);
    80004b78:	d7afe0ef          	jal	ra,800030f2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){  // 在父目录中创建新链接
    80004b7c:	00092703          	lw	a4,0(s2)
    80004b80:	409c                	lw	a5,0(s1)
    80004b82:	02f71f63          	bne	a4,a5,80004bc0 <sys_link+0xc0>
    80004b86:	40d0                	lw	a2,4(s1)
    80004b88:	fd040593          	addi	a1,s0,-48
    80004b8c:	854a                	mv	a0,s2
    80004b8e:	cb9fe0ef          	jal	ra,80003846 <dirlink>
    80004b92:	02054763          	bltz	a0,80004bc0 <sys_link+0xc0>
  iunlockput(dp);
    80004b96:	854a                	mv	a0,s2
    80004b98:	f60fe0ef          	jal	ra,800032f8 <iunlockput>
  iput(ip);
    80004b9c:	8526                	mv	a0,s1
    80004b9e:	ed2fe0ef          	jal	ra,80003270 <iput>
  end_op();
    80004ba2:	f9ffe0ef          	jal	ra,80003b40 <end_op>
  return 0;
    80004ba6:	4781                	li	a5,0
    80004ba8:	a081                	j	80004be8 <sys_link+0xe8>
    end_op();
    80004baa:	f97fe0ef          	jal	ra,80003b40 <end_op>
    return -1;
    80004bae:	57fd                	li	a5,-1
    80004bb0:	a825                	j	80004be8 <sys_link+0xe8>
    iunlockput(ip);
    80004bb2:	8526                	mv	a0,s1
    80004bb4:	f44fe0ef          	jal	ra,800032f8 <iunlockput>
    end_op();
    80004bb8:	f89fe0ef          	jal	ra,80003b40 <end_op>
    return -1;
    80004bbc:	57fd                	li	a5,-1
    80004bbe:	a02d                	j	80004be8 <sys_link+0xe8>
    iunlockput(dp);
    80004bc0:	854a                	mv	a0,s2
    80004bc2:	f36fe0ef          	jal	ra,800032f8 <iunlockput>
  ilock(ip);
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	d2afe0ef          	jal	ra,800030f2 <ilock>
  ip->nlink--;  // 发生错误，恢复链接计数
    80004bcc:	04a4d783          	lhu	a5,74(s1)
    80004bd0:	37fd                	addiw	a5,a5,-1
    80004bd2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004bd6:	8526                	mv	a0,s1
    80004bd8:	c68fe0ef          	jal	ra,80003040 <iupdate>
  iunlockput(ip);
    80004bdc:	8526                	mv	a0,s1
    80004bde:	f1afe0ef          	jal	ra,800032f8 <iunlockput>
  end_op();
    80004be2:	f5ffe0ef          	jal	ra,80003b40 <end_op>
  return -1;
    80004be6:	57fd                	li	a5,-1
}
    80004be8:	853e                	mv	a0,a5
    80004bea:	70b2                	ld	ra,296(sp)
    80004bec:	7412                	ld	s0,288(sp)
    80004bee:	64f2                	ld	s1,280(sp)
    80004bf0:	6952                	ld	s2,272(sp)
    80004bf2:	6155                	addi	sp,sp,304
    80004bf4:	8082                	ret

0000000080004bf6 <sys_unlink>:
{
    80004bf6:	7151                	addi	sp,sp,-240
    80004bf8:	f586                	sd	ra,232(sp)
    80004bfa:	f1a2                	sd	s0,224(sp)
    80004bfc:	eda6                	sd	s1,216(sp)
    80004bfe:	e9ca                	sd	s2,208(sp)
    80004c00:	e5ce                	sd	s3,200(sp)
    80004c02:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)  // 获取路径
    80004c04:	08000613          	li	a2,128
    80004c08:	f3040593          	addi	a1,s0,-208
    80004c0c:	4501                	li	a0,0
    80004c0e:	b35fd0ef          	jal	ra,80002742 <argstr>
    80004c12:	12054b63          	bltz	a0,80004d48 <sys_unlink+0x152>
  begin_op();
    80004c16:	ebbfe0ef          	jal	ra,80003ad0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){  // 查找路径的父目录
    80004c1a:	fb040593          	addi	a1,s0,-80
    80004c1e:	f3040513          	addi	a0,s0,-208
    80004c22:	cd9fe0ef          	jal	ra,800038fa <nameiparent>
    80004c26:	84aa                	mv	s1,a0
    80004c28:	c54d                	beqz	a0,80004cd2 <sys_unlink+0xdc>
  ilock(dp);
    80004c2a:	cc8fe0ef          	jal	ra,800030f2 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004c2e:	00003597          	auipc	a1,0x3
    80004c32:	aa258593          	addi	a1,a1,-1374 # 800076d0 <syscalls+0x2e0>
    80004c36:	fb040513          	addi	a0,s0,-80
    80004c3a:	a2bfe0ef          	jal	ra,80003664 <namecmp>
    80004c3e:	10050a63          	beqz	a0,80004d52 <sys_unlink+0x15c>
    80004c42:	00003597          	auipc	a1,0x3
    80004c46:	a9658593          	addi	a1,a1,-1386 # 800076d8 <syscalls+0x2e8>
    80004c4a:	fb040513          	addi	a0,s0,-80
    80004c4e:	a17fe0ef          	jal	ra,80003664 <namecmp>
    80004c52:	10050063          	beqz	a0,80004d52 <sys_unlink+0x15c>
  if((ip = dirlookup(dp, name, &off)) == 0)  // 查找目录项
    80004c56:	f2c40613          	addi	a2,s0,-212
    80004c5a:	fb040593          	addi	a1,s0,-80
    80004c5e:	8526                	mv	a0,s1
    80004c60:	a1bfe0ef          	jal	ra,8000367a <dirlookup>
    80004c64:	892a                	mv	s2,a0
    80004c66:	0e050663          	beqz	a0,80004d52 <sys_unlink+0x15c>
  ilock(ip);
    80004c6a:	c88fe0ef          	jal	ra,800030f2 <ilock>
  if(ip->nlink < 1)
    80004c6e:	04a91783          	lh	a5,74(s2)
    80004c72:	06f05463          	blez	a5,80004cda <sys_unlink+0xe4>
  if(ip->type == T_DIR && !isdirempty(ip)){  // 如果是非空目录，不能删除
    80004c76:	04491703          	lh	a4,68(s2)
    80004c7a:	4785                	li	a5,1
    80004c7c:	06f70563          	beq	a4,a5,80004ce6 <sys_unlink+0xf0>
  memset(&de, 0, sizeof(de));  // 清空目录项
    80004c80:	4641                	li	a2,16
    80004c82:	4581                	li	a1,0
    80004c84:	fc040513          	addi	a0,s0,-64
    80004c88:	fb9fb0ef          	jal	ra,80000c40 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))  // 删除目录项
    80004c8c:	4741                	li	a4,16
    80004c8e:	f2c42683          	lw	a3,-212(s0)
    80004c92:	fc040613          	addi	a2,s0,-64
    80004c96:	4581                	li	a1,0
    80004c98:	8526                	mv	a0,s1
    80004c9a:	8c9fe0ef          	jal	ra,80003562 <writei>
    80004c9e:	47c1                	li	a5,16
    80004ca0:	08f51563          	bne	a0,a5,80004d2a <sys_unlink+0x134>
  if(ip->type == T_DIR){
    80004ca4:	04491703          	lh	a4,68(s2)
    80004ca8:	4785                	li	a5,1
    80004caa:	08f70663          	beq	a4,a5,80004d36 <sys_unlink+0x140>
  iunlockput(dp);
    80004cae:	8526                	mv	a0,s1
    80004cb0:	e48fe0ef          	jal	ra,800032f8 <iunlockput>
  ip->nlink--;  // 更新目标文件的链接计数
    80004cb4:	04a95783          	lhu	a5,74(s2)
    80004cb8:	37fd                	addiw	a5,a5,-1
    80004cba:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80004cbe:	854a                	mv	a0,s2
    80004cc0:	b80fe0ef          	jal	ra,80003040 <iupdate>
  iunlockput(ip);
    80004cc4:	854a                	mv	a0,s2
    80004cc6:	e32fe0ef          	jal	ra,800032f8 <iunlockput>
  end_op();
    80004cca:	e77fe0ef          	jal	ra,80003b40 <end_op>
  return 0;
    80004cce:	4501                	li	a0,0
    80004cd0:	a079                	j	80004d5e <sys_unlink+0x168>
    end_op();
    80004cd2:	e6ffe0ef          	jal	ra,80003b40 <end_op>
    return -1;
    80004cd6:	557d                	li	a0,-1
    80004cd8:	a059                	j	80004d5e <sys_unlink+0x168>
    panic("unlink: nlink < 1");  // 检查链接计数
    80004cda:	00003517          	auipc	a0,0x3
    80004cde:	a0650513          	addi	a0,a0,-1530 # 800076e0 <syscalls+0x2f0>
    80004ce2:	aa9fb0ef          	jal	ra,8000078a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){  // 跳过 "." 和 ".."
    80004ce6:	04c92703          	lw	a4,76(s2)
    80004cea:	02000793          	li	a5,32
    80004cee:	f8e7f9e3          	bgeu	a5,a4,80004c80 <sys_unlink+0x8a>
    80004cf2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004cf6:	4741                	li	a4,16
    80004cf8:	86ce                	mv	a3,s3
    80004cfa:	f1840613          	addi	a2,s0,-232
    80004cfe:	4581                	li	a1,0
    80004d00:	854a                	mv	a0,s2
    80004d02:	f7cfe0ef          	jal	ra,8000347e <readi>
    80004d06:	47c1                	li	a5,16
    80004d08:	00f51b63          	bne	a0,a5,80004d1e <sys_unlink+0x128>
    if(de.inum != 0)  // 如果目录项不为空
    80004d0c:	f1845783          	lhu	a5,-232(s0)
    80004d10:	ef95                	bnez	a5,80004d4c <sys_unlink+0x156>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){  // 跳过 "." 和 ".."
    80004d12:	29c1                	addiw	s3,s3,16
    80004d14:	04c92783          	lw	a5,76(s2)
    80004d18:	fcf9efe3          	bltu	s3,a5,80004cf6 <sys_unlink+0x100>
    80004d1c:	b795                	j	80004c80 <sys_unlink+0x8a>
      panic("isdirempty: readi");
    80004d1e:	00003517          	auipc	a0,0x3
    80004d22:	9da50513          	addi	a0,a0,-1574 # 800076f8 <syscalls+0x308>
    80004d26:	a65fb0ef          	jal	ra,8000078a <panic>
    panic("unlink: writei");
    80004d2a:	00003517          	auipc	a0,0x3
    80004d2e:	9e650513          	addi	a0,a0,-1562 # 80007710 <syscalls+0x320>
    80004d32:	a59fb0ef          	jal	ra,8000078a <panic>
    dp->nlink--;  // 更新父目录的链接计数
    80004d36:	04a4d783          	lhu	a5,74(s1)
    80004d3a:	37fd                	addiw	a5,a5,-1
    80004d3c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004d40:	8526                	mv	a0,s1
    80004d42:	afefe0ef          	jal	ra,80003040 <iupdate>
    80004d46:	b7a5                	j	80004cae <sys_unlink+0xb8>
    return -1;
    80004d48:	557d                	li	a0,-1
    80004d4a:	a811                	j	80004d5e <sys_unlink+0x168>
    iunlockput(ip);
    80004d4c:	854a                	mv	a0,s2
    80004d4e:	daafe0ef          	jal	ra,800032f8 <iunlockput>
  iunlockput(dp);
    80004d52:	8526                	mv	a0,s1
    80004d54:	da4fe0ef          	jal	ra,800032f8 <iunlockput>
  end_op();
    80004d58:	de9fe0ef          	jal	ra,80003b40 <end_op>
  return -1;
    80004d5c:	557d                	li	a0,-1
}
    80004d5e:	70ae                	ld	ra,232(sp)
    80004d60:	740e                	ld	s0,224(sp)
    80004d62:	64ee                	ld	s1,216(sp)
    80004d64:	694e                	ld	s2,208(sp)
    80004d66:	69ae                	ld	s3,200(sp)
    80004d68:	616d                	addi	sp,sp,240
    80004d6a:	8082                	ret

0000000080004d6c <sys_open>:

uint64
sys_open(void)
{
    80004d6c:	7131                	addi	sp,sp,-192
    80004d6e:	fd06                	sd	ra,184(sp)
    80004d70:	f922                	sd	s0,176(sp)
    80004d72:	f526                	sd	s1,168(sp)
    80004d74:	f14a                	sd	s2,160(sp)
    80004d76:	ed4e                	sd	s3,152(sp)
    80004d78:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);  // 获取打开文件的模式
    80004d7a:	f4c40593          	addi	a1,s0,-180
    80004d7e:	4505                	li	a0,1
    80004d80:	98bfd0ef          	jal	ra,8000270a <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)  // 获取路径
    80004d84:	08000613          	li	a2,128
    80004d88:	f5040593          	addi	a1,s0,-176
    80004d8c:	4501                	li	a0,0
    80004d8e:	9b5fd0ef          	jal	ra,80002742 <argstr>
    80004d92:	87aa                	mv	a5,a0
    return -1;
    80004d94:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)  // 获取路径
    80004d96:	0807cd63          	bltz	a5,80004e30 <sys_open+0xc4>

  begin_op();
    80004d9a:	d37fe0ef          	jal	ra,80003ad0 <begin_op>

  if(omode & O_CREATE){  // 如果是创建文件
    80004d9e:	f4c42783          	lw	a5,-180(s0)
    80004da2:	2007f793          	andi	a5,a5,512
    80004da6:	c3c5                	beqz	a5,80004e46 <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    80004da8:	4681                	li	a3,0
    80004daa:	4601                	li	a2,0
    80004dac:	4589                	li	a1,2
    80004dae:	f5040513          	addi	a0,s0,-176
    80004db2:	ac3ff0ef          	jal	ra,80004874 <create>
    80004db6:	84aa                	mv	s1,a0
    if(ip == 0){
    80004db8:	c159                	beqz	a0,80004e3e <sys_open+0xd2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80004dba:	04449703          	lh	a4,68(s1)
    80004dbe:	478d                	li	a5,3
    80004dc0:	00f71763          	bne	a4,a5,80004dce <sys_open+0x62>
    80004dc4:	0464d703          	lhu	a4,70(s1)
    80004dc8:	47a5                	li	a5,9
    80004dca:	0ae7e963          	bltu	a5,a4,80004e7c <sys_open+0x110>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){  // 分配文件描述符
    80004dce:	86cff0ef          	jal	ra,80003e3a <filealloc>
    80004dd2:	89aa                	mv	s3,a0
    80004dd4:	0c050963          	beqz	a0,80004ea6 <sys_open+0x13a>
    80004dd8:	a5fff0ef          	jal	ra,80004836 <fdalloc>
    80004ddc:	892a                	mv	s2,a0
    80004dde:	0c054163          	bltz	a0,80004ea0 <sys_open+0x134>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80004de2:	04449703          	lh	a4,68(s1)
    80004de6:	478d                	li	a5,3
    80004de8:	0af70163          	beq	a4,a5,80004e8a <sys_open+0x11e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80004dec:	4789                	li	a5,2
    80004dee:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80004df2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80004df6:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80004dfa:	f4c42783          	lw	a5,-180(s0)
    80004dfe:	0017c713          	xori	a4,a5,1
    80004e02:	8b05                	andi	a4,a4,1
    80004e04:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80004e08:	0037f713          	andi	a4,a5,3
    80004e0c:	00e03733          	snez	a4,a4
    80004e10:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){  // 如果是 O_TRUNC 模式，截断文件
    80004e14:	4007f793          	andi	a5,a5,1024
    80004e18:	c791                	beqz	a5,80004e24 <sys_open+0xb8>
    80004e1a:	04449703          	lh	a4,68(s1)
    80004e1e:	4789                	li	a5,2
    80004e20:	06f70c63          	beq	a4,a5,80004e98 <sys_open+0x12c>
    itrunc(ip);
  }

  iunlock(ip);
    80004e24:	8526                	mv	a0,s1
    80004e26:	b76fe0ef          	jal	ra,8000319c <iunlock>
  end_op();
    80004e2a:	d17fe0ef          	jal	ra,80003b40 <end_op>

  return fd;
    80004e2e:	854a                	mv	a0,s2
}
    80004e30:	70ea                	ld	ra,184(sp)
    80004e32:	744a                	ld	s0,176(sp)
    80004e34:	74aa                	ld	s1,168(sp)
    80004e36:	790a                	ld	s2,160(sp)
    80004e38:	69ea                	ld	s3,152(sp)
    80004e3a:	6129                	addi	sp,sp,192
    80004e3c:	8082                	ret
      end_op();
    80004e3e:	d03fe0ef          	jal	ra,80003b40 <end_op>
      return -1;
    80004e42:	557d                	li	a0,-1
    80004e44:	b7f5                	j	80004e30 <sys_open+0xc4>
    if((ip = namei(path)) == 0){
    80004e46:	f5040513          	addi	a0,s0,-176
    80004e4a:	a97fe0ef          	jal	ra,800038e0 <namei>
    80004e4e:	84aa                	mv	s1,a0
    80004e50:	c115                	beqz	a0,80004e74 <sys_open+0x108>
    ilock(ip);
    80004e52:	aa0fe0ef          	jal	ra,800030f2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){  // 不能用非读模式打开目录
    80004e56:	04449703          	lh	a4,68(s1)
    80004e5a:	4785                	li	a5,1
    80004e5c:	f4f71fe3          	bne	a4,a5,80004dba <sys_open+0x4e>
    80004e60:	f4c42783          	lw	a5,-180(s0)
    80004e64:	d7ad                	beqz	a5,80004dce <sys_open+0x62>
      iunlockput(ip);
    80004e66:	8526                	mv	a0,s1
    80004e68:	c90fe0ef          	jal	ra,800032f8 <iunlockput>
      end_op();
    80004e6c:	cd5fe0ef          	jal	ra,80003b40 <end_op>
      return -1;
    80004e70:	557d                	li	a0,-1
    80004e72:	bf7d                	j	80004e30 <sys_open+0xc4>
      end_op();
    80004e74:	ccdfe0ef          	jal	ra,80003b40 <end_op>
      return -1;
    80004e78:	557d                	li	a0,-1
    80004e7a:	bf5d                	j	80004e30 <sys_open+0xc4>
    iunlockput(ip);
    80004e7c:	8526                	mv	a0,s1
    80004e7e:	c7afe0ef          	jal	ra,800032f8 <iunlockput>
    end_op();
    80004e82:	cbffe0ef          	jal	ra,80003b40 <end_op>
    return -1;
    80004e86:	557d                	li	a0,-1
    80004e88:	b765                	j	80004e30 <sys_open+0xc4>
    f->type = FD_DEVICE;
    80004e8a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80004e8e:	04649783          	lh	a5,70(s1)
    80004e92:	02f99223          	sh	a5,36(s3)
    80004e96:	b785                	j	80004df6 <sys_open+0x8a>
    itrunc(ip);
    80004e98:	8526                	mv	a0,s1
    80004e9a:	b42fe0ef          	jal	ra,800031dc <itrunc>
    80004e9e:	b759                	j	80004e24 <sys_open+0xb8>
      fileclose(f);
    80004ea0:	854e                	mv	a0,s3
    80004ea2:	83cff0ef          	jal	ra,80003ede <fileclose>
    iunlockput(ip);
    80004ea6:	8526                	mv	a0,s1
    80004ea8:	c50fe0ef          	jal	ra,800032f8 <iunlockput>
    end_op();
    80004eac:	c95fe0ef          	jal	ra,80003b40 <end_op>
    return -1;
    80004eb0:	557d                	li	a0,-1
    80004eb2:	bfbd                	j	80004e30 <sys_open+0xc4>

0000000080004eb4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80004eb4:	7175                	addi	sp,sp,-144
    80004eb6:	e506                	sd	ra,136(sp)
    80004eb8:	e122                	sd	s0,128(sp)
    80004eba:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80004ebc:	c15fe0ef          	jal	ra,80003ad0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80004ec0:	08000613          	li	a2,128
    80004ec4:	f7040593          	addi	a1,s0,-144
    80004ec8:	4501                	li	a0,0
    80004eca:	879fd0ef          	jal	ra,80002742 <argstr>
    80004ece:	02054363          	bltz	a0,80004ef4 <sys_mkdir+0x40>
    80004ed2:	4681                	li	a3,0
    80004ed4:	4601                	li	a2,0
    80004ed6:	4585                	li	a1,1
    80004ed8:	f7040513          	addi	a0,s0,-144
    80004edc:	999ff0ef          	jal	ra,80004874 <create>
    80004ee0:	c911                	beqz	a0,80004ef4 <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80004ee2:	c16fe0ef          	jal	ra,800032f8 <iunlockput>
  end_op();
    80004ee6:	c5bfe0ef          	jal	ra,80003b40 <end_op>
  return 0;
    80004eea:	4501                	li	a0,0
}
    80004eec:	60aa                	ld	ra,136(sp)
    80004eee:	640a                	ld	s0,128(sp)
    80004ef0:	6149                	addi	sp,sp,144
    80004ef2:	8082                	ret
    end_op();
    80004ef4:	c4dfe0ef          	jal	ra,80003b40 <end_op>
    return -1;
    80004ef8:	557d                	li	a0,-1
    80004efa:	bfcd                	j	80004eec <sys_mkdir+0x38>

0000000080004efc <sys_mknod>:

uint64
sys_mknod(void)
{
    80004efc:	7135                	addi	sp,sp,-160
    80004efe:	ed06                	sd	ra,152(sp)
    80004f00:	e922                	sd	s0,144(sp)
    80004f02:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80004f04:	bcdfe0ef          	jal	ra,80003ad0 <begin_op>
  argint(1, &major);
    80004f08:	f6c40593          	addi	a1,s0,-148
    80004f0c:	4505                	li	a0,1
    80004f0e:	ffcfd0ef          	jal	ra,8000270a <argint>
  argint(2, &minor);
    80004f12:	f6840593          	addi	a1,s0,-152
    80004f16:	4509                	li	a0,2
    80004f18:	ff2fd0ef          	jal	ra,8000270a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80004f1c:	08000613          	li	a2,128
    80004f20:	f7040593          	addi	a1,s0,-144
    80004f24:	4501                	li	a0,0
    80004f26:	81dfd0ef          	jal	ra,80002742 <argstr>
    80004f2a:	02054563          	bltz	a0,80004f54 <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80004f2e:	f6841683          	lh	a3,-152(s0)
    80004f32:	f6c41603          	lh	a2,-148(s0)
    80004f36:	458d                	li	a1,3
    80004f38:	f7040513          	addi	a0,s0,-144
    80004f3c:	939ff0ef          	jal	ra,80004874 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80004f40:	c911                	beqz	a0,80004f54 <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80004f42:	bb6fe0ef          	jal	ra,800032f8 <iunlockput>
  end_op();
    80004f46:	bfbfe0ef          	jal	ra,80003b40 <end_op>
  return 0;
    80004f4a:	4501                	li	a0,0
}
    80004f4c:	60ea                	ld	ra,152(sp)
    80004f4e:	644a                	ld	s0,144(sp)
    80004f50:	610d                	addi	sp,sp,160
    80004f52:	8082                	ret
    end_op();
    80004f54:	bedfe0ef          	jal	ra,80003b40 <end_op>
    return -1;
    80004f58:	557d                	li	a0,-1
    80004f5a:	bfcd                	j	80004f4c <sys_mknod+0x50>

0000000080004f5c <sys_chdir>:

uint64
sys_chdir(void)
{
    80004f5c:	7135                	addi	sp,sp,-160
    80004f5e:	ed06                	sd	ra,152(sp)
    80004f60:	e922                	sd	s0,144(sp)
    80004f62:	e526                	sd	s1,136(sp)
    80004f64:	e14a                	sd	s2,128(sp)
    80004f66:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80004f68:	89dfc0ef          	jal	ra,80001804 <myproc>
    80004f6c:	892a                	mv	s2,a0
  
  begin_op();
    80004f6e:	b63fe0ef          	jal	ra,80003ad0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80004f72:	08000613          	li	a2,128
    80004f76:	f6040593          	addi	a1,s0,-160
    80004f7a:	4501                	li	a0,0
    80004f7c:	fc6fd0ef          	jal	ra,80002742 <argstr>
    80004f80:	04054163          	bltz	a0,80004fc2 <sys_chdir+0x66>
    80004f84:	f6040513          	addi	a0,s0,-160
    80004f88:	959fe0ef          	jal	ra,800038e0 <namei>
    80004f8c:	84aa                	mv	s1,a0
    80004f8e:	c915                	beqz	a0,80004fc2 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    80004f90:	962fe0ef          	jal	ra,800030f2 <ilock>
  if(ip->type != T_DIR){  // 必须是目录类型
    80004f94:	04449703          	lh	a4,68(s1)
    80004f98:	4785                	li	a5,1
    80004f9a:	02f71863          	bne	a4,a5,80004fca <sys_chdir+0x6e>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80004f9e:	8526                	mv	a0,s1
    80004fa0:	9fcfe0ef          	jal	ra,8000319c <iunlock>
  iput(p->cwd);  // 释放当前工作目录
    80004fa4:	15093503          	ld	a0,336(s2)
    80004fa8:	ac8fe0ef          	jal	ra,80003270 <iput>
  end_op();
    80004fac:	b95fe0ef          	jal	ra,80003b40 <end_op>
  p->cwd = ip;  // 更新为新的工作目录
    80004fb0:	14993823          	sd	s1,336(s2)
  return 0;
    80004fb4:	4501                	li	a0,0
}
    80004fb6:	60ea                	ld	ra,152(sp)
    80004fb8:	644a                	ld	s0,144(sp)
    80004fba:	64aa                	ld	s1,136(sp)
    80004fbc:	690a                	ld	s2,128(sp)
    80004fbe:	610d                	addi	sp,sp,160
    80004fc0:	8082                	ret
    end_op();
    80004fc2:	b7ffe0ef          	jal	ra,80003b40 <end_op>
    return -1;
    80004fc6:	557d                	li	a0,-1
    80004fc8:	b7fd                	j	80004fb6 <sys_chdir+0x5a>
    iunlockput(ip);
    80004fca:	8526                	mv	a0,s1
    80004fcc:	b2cfe0ef          	jal	ra,800032f8 <iunlockput>
    end_op();
    80004fd0:	b71fe0ef          	jal	ra,80003b40 <end_op>
    return -1;
    80004fd4:	557d                	li	a0,-1
    80004fd6:	b7c5                	j	80004fb6 <sys_chdir+0x5a>

0000000080004fd8 <sys_exec>:

uint64
sys_exec(void)
{
    80004fd8:	7145                	addi	sp,sp,-464
    80004fda:	e786                	sd	ra,456(sp)
    80004fdc:	e3a2                	sd	s0,448(sp)
    80004fde:	ff26                	sd	s1,440(sp)
    80004fe0:	fb4a                	sd	s2,432(sp)
    80004fe2:	f74e                	sd	s3,424(sp)
    80004fe4:	f352                	sd	s4,416(sp)
    80004fe6:	ef56                	sd	s5,408(sp)
    80004fe8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);  // 获取参数地址
    80004fea:	e3840593          	addi	a1,s0,-456
    80004fee:	4505                	li	a0,1
    80004ff0:	f36fd0ef          	jal	ra,80002726 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {  // 获取程序路径
    80004ff4:	08000613          	li	a2,128
    80004ff8:	f4040593          	addi	a1,s0,-192
    80004ffc:	4501                	li	a0,0
    80004ffe:	f44fd0ef          	jal	ra,80002742 <argstr>
    80005002:	87aa                	mv	a5,a0
    return -1;
    80005004:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {  // 获取程序路径
    80005006:	0a07c463          	bltz	a5,800050ae <sys_exec+0xd6>
  }
  memset(argv, 0, sizeof(argv));
    8000500a:	10000613          	li	a2,256
    8000500e:	4581                	li	a1,0
    80005010:	e4040513          	addi	a0,s0,-448
    80005014:	c2dfb0ef          	jal	ra,80000c40 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005018:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000501c:	89a6                	mv	s3,s1
    8000501e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005020:	02000a13          	li	s4,32
    80005024:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005028:	00391793          	slli	a5,s2,0x3
    8000502c:	e3040593          	addi	a1,s0,-464
    80005030:	e3843503          	ld	a0,-456(s0)
    80005034:	953e                	add	a0,a0,a5
    80005036:	e4afd0ef          	jal	ra,80002680 <fetchaddr>
    8000503a:	02054663          	bltz	a0,80005066 <sys_exec+0x8e>
      goto bad;
    }
    if(uarg == 0){
    8000503e:	e3043783          	ld	a5,-464(s0)
    80005042:	cf8d                	beqz	a5,8000507c <sys_exec+0xa4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005044:	a59fb0ef          	jal	ra,80000a9c <kalloc>
    80005048:	85aa                	mv	a1,a0
    8000504a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000504e:	cd01                	beqz	a0,80005066 <sys_exec+0x8e>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005050:	6605                	lui	a2,0x1
    80005052:	e3043503          	ld	a0,-464(s0)
    80005056:	e74fd0ef          	jal	ra,800026ca <fetchstr>
    8000505a:	00054663          	bltz	a0,80005066 <sys_exec+0x8e>
    if(i >= NELEM(argv)){
    8000505e:	0905                	addi	s2,s2,1
    80005060:	09a1                	addi	s3,s3,8
    80005062:	fd4911e3          	bne	s2,s4,80005024 <sys_exec+0x4c>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005066:	10048913          	addi	s2,s1,256
    8000506a:	6088                	ld	a0,0(s1)
    8000506c:	c121                	beqz	a0,800050ac <sys_exec+0xd4>
    kfree(argv[i]);
    8000506e:	94ffb0ef          	jal	ra,800009bc <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005072:	04a1                	addi	s1,s1,8
    80005074:	ff249be3          	bne	s1,s2,8000506a <sys_exec+0x92>
  return -1;
    80005078:	557d                	li	a0,-1
    8000507a:	a815                	j	800050ae <sys_exec+0xd6>
      argv[i] = 0;
    8000507c:	0a8e                	slli	s5,s5,0x3
    8000507e:	fc040793          	addi	a5,s0,-64
    80005082:	9abe                	add	s5,s5,a5
    80005084:	e80ab023          	sd	zero,-384(s5)
  int ret = kexec(path, argv);  // 执行程序
    80005088:	e4040593          	addi	a1,s0,-448
    8000508c:	f4040513          	addi	a0,s0,-192
    80005090:	bfaff0ef          	jal	ra,8000448a <kexec>
    80005094:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005096:	10048993          	addi	s3,s1,256
    8000509a:	6088                	ld	a0,0(s1)
    8000509c:	c511                	beqz	a0,800050a8 <sys_exec+0xd0>
    kfree(argv[i]);
    8000509e:	91ffb0ef          	jal	ra,800009bc <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800050a2:	04a1                	addi	s1,s1,8
    800050a4:	ff349be3          	bne	s1,s3,8000509a <sys_exec+0xc2>
  return ret;
    800050a8:	854a                	mv	a0,s2
    800050aa:	a011                	j	800050ae <sys_exec+0xd6>
  return -1;
    800050ac:	557d                	li	a0,-1
}
    800050ae:	60be                	ld	ra,456(sp)
    800050b0:	641e                	ld	s0,448(sp)
    800050b2:	74fa                	ld	s1,440(sp)
    800050b4:	795a                	ld	s2,432(sp)
    800050b6:	79ba                	ld	s3,424(sp)
    800050b8:	7a1a                	ld	s4,416(sp)
    800050ba:	6afa                	ld	s5,408(sp)
    800050bc:	6179                	addi	sp,sp,464
    800050be:	8082                	ret

00000000800050c0 <sys_pipe>:

uint64
sys_pipe(void)
{
    800050c0:	7139                	addi	sp,sp,-64
    800050c2:	fc06                	sd	ra,56(sp)
    800050c4:	f822                	sd	s0,48(sp)
    800050c6:	f426                	sd	s1,40(sp)
    800050c8:	0080                	addi	s0,sp,64
  uint64 fdarray; // 用户指针指向两个整数的数组
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800050ca:	f3afc0ef          	jal	ra,80001804 <myproc>
    800050ce:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);  // 获取文件描述符数组地址
    800050d0:	fd840593          	addi	a1,s0,-40
    800050d4:	4501                	li	a0,0
    800050d6:	e50fd0ef          	jal	ra,80002726 <argaddr>
  if(pipealloc(&rf, &wf) < 0)  // 分配管道文件
    800050da:	fc840593          	addi	a1,s0,-56
    800050de:	fd040513          	addi	a0,s0,-48
    800050e2:	8c8ff0ef          	jal	ra,800041aa <pipealloc>
    return -1;
    800050e6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)  // 分配管道文件
    800050e8:	0a054463          	bltz	a0,80005190 <sys_pipe+0xd0>
  fd0 = -1;
    800050ec:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){  // 分配文件描述符
    800050f0:	fd043503          	ld	a0,-48(s0)
    800050f4:	f42ff0ef          	jal	ra,80004836 <fdalloc>
    800050f8:	fca42223          	sw	a0,-60(s0)
    800050fc:	08054163          	bltz	a0,8000517e <sys_pipe+0xbe>
    80005100:	fc843503          	ld	a0,-56(s0)
    80005104:	f32ff0ef          	jal	ra,80004836 <fdalloc>
    80005108:	fca42023          	sw	a0,-64(s0)
    8000510c:	06054063          	bltz	a0,8000516c <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||  // 将文件描述符写入用户空间
    80005110:	4691                	li	a3,4
    80005112:	fc440613          	addi	a2,s0,-60
    80005116:	fd843583          	ld	a1,-40(s0)
    8000511a:	68a8                	ld	a0,80(s1)
    8000511c:	c36fc0ef          	jal	ra,80001552 <copyout>
    80005120:	00054e63          	bltz	a0,8000513c <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005124:	4691                	li	a3,4
    80005126:	fc040613          	addi	a2,s0,-64
    8000512a:	fd843583          	ld	a1,-40(s0)
    8000512e:	0591                	addi	a1,a1,4
    80005130:	68a8                	ld	a0,80(s1)
    80005132:	c20fc0ef          	jal	ra,80001552 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005136:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||  // 将文件描述符写入用户空间
    80005138:	04055c63          	bgez	a0,80005190 <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    8000513c:	fc442783          	lw	a5,-60(s0)
    80005140:	07e9                	addi	a5,a5,26
    80005142:	078e                	slli	a5,a5,0x3
    80005144:	97a6                	add	a5,a5,s1
    80005146:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000514a:	fc042503          	lw	a0,-64(s0)
    8000514e:	0569                	addi	a0,a0,26
    80005150:	050e                	slli	a0,a0,0x3
    80005152:	94aa                	add	s1,s1,a0
    80005154:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005158:	fd043503          	ld	a0,-48(s0)
    8000515c:	d83fe0ef          	jal	ra,80003ede <fileclose>
    fileclose(wf);
    80005160:	fc843503          	ld	a0,-56(s0)
    80005164:	d7bfe0ef          	jal	ra,80003ede <fileclose>
    return -1;
    80005168:	57fd                	li	a5,-1
    8000516a:	a01d                	j	80005190 <sys_pipe+0xd0>
    if(fd0 >= 0)
    8000516c:	fc442783          	lw	a5,-60(s0)
    80005170:	0007c763          	bltz	a5,8000517e <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    80005174:	07e9                	addi	a5,a5,26
    80005176:	078e                	slli	a5,a5,0x3
    80005178:	94be                	add	s1,s1,a5
    8000517a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000517e:	fd043503          	ld	a0,-48(s0)
    80005182:	d5dfe0ef          	jal	ra,80003ede <fileclose>
    fileclose(wf);
    80005186:	fc843503          	ld	a0,-56(s0)
    8000518a:	d55fe0ef          	jal	ra,80003ede <fileclose>
    return -1;
    8000518e:	57fd                	li	a5,-1
}
    80005190:	853e                	mv	a0,a5
    80005192:	70e2                	ld	ra,56(sp)
    80005194:	7442                	ld	s0,48(sp)
    80005196:	74a2                	ld	s1,40(sp)
    80005198:	6121                	addi	sp,sp,64
    8000519a:	8082                	ret
    8000519c:	0000                	unimp
	...

00000000800051a0 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    800051a0:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    800051a2:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    800051a4:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    800051a6:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    800051a8:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    800051aa:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    800051ac:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    800051ae:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    800051b0:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    800051b2:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    800051b4:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    800051b6:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    800051b8:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    800051ba:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    800051bc:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    800051be:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    800051c0:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    800051c2:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    800051c4:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    800051c6:	bcafd0ef          	jal	ra,80002590 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    800051ca:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    800051cc:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    800051ce:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800051d0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800051d2:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    800051d4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800051d6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800051d8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800051da:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800051dc:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800051de:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800051e0:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800051e2:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    800051e4:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    800051e6:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    800051e8:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    800051ea:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    800051ec:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    800051ee:	10200073          	sret
	...

00000000800051fe <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800051fe:	1141                	addi	sp,sp,-16
    80005200:	e422                	sd	s0,8(sp)
    80005202:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005204:	0c0007b7          	lui	a5,0xc000
    80005208:	4705                	li	a4,1
    8000520a:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    8000520c:	c3d8                	sw	a4,4(a5)
}
    8000520e:	6422                	ld	s0,8(sp)
    80005210:	0141                	addi	sp,sp,16
    80005212:	8082                	ret

0000000080005214 <plicinithart>:

void
plicinithart(void)
{
    80005214:	1141                	addi	sp,sp,-16
    80005216:	e406                	sd	ra,8(sp)
    80005218:	e022                	sd	s0,0(sp)
    8000521a:	0800                	addi	s0,sp,16
  int hart = cpuid();
    8000521c:	dbcfc0ef          	jal	ra,800017d8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005220:	0085171b          	slliw	a4,a0,0x8
    80005224:	0c0027b7          	lui	a5,0xc002
    80005228:	97ba                	add	a5,a5,a4
    8000522a:	40200713          	li	a4,1026
    8000522e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005232:	00d5151b          	slliw	a0,a0,0xd
    80005236:	0c2017b7          	lui	a5,0xc201
    8000523a:	953e                	add	a0,a0,a5
    8000523c:	00052023          	sw	zero,0(a0)
}
    80005240:	60a2                	ld	ra,8(sp)
    80005242:	6402                	ld	s0,0(sp)
    80005244:	0141                	addi	sp,sp,16
    80005246:	8082                	ret

0000000080005248 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005248:	1141                	addi	sp,sp,-16
    8000524a:	e406                	sd	ra,8(sp)
    8000524c:	e022                	sd	s0,0(sp)
    8000524e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005250:	d88fc0ef          	jal	ra,800017d8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005254:	00d5179b          	slliw	a5,a0,0xd
    80005258:	0c201537          	lui	a0,0xc201
    8000525c:	953e                	add	a0,a0,a5
  return irq;
}
    8000525e:	4148                	lw	a0,4(a0)
    80005260:	60a2                	ld	ra,8(sp)
    80005262:	6402                	ld	s0,0(sp)
    80005264:	0141                	addi	sp,sp,16
    80005266:	8082                	ret

0000000080005268 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005268:	1101                	addi	sp,sp,-32
    8000526a:	ec06                	sd	ra,24(sp)
    8000526c:	e822                	sd	s0,16(sp)
    8000526e:	e426                	sd	s1,8(sp)
    80005270:	1000                	addi	s0,sp,32
    80005272:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005274:	d64fc0ef          	jal	ra,800017d8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005278:	00d5151b          	slliw	a0,a0,0xd
    8000527c:	0c2017b7          	lui	a5,0xc201
    80005280:	97aa                	add	a5,a5,a0
    80005282:	c3c4                	sw	s1,4(a5)
}
    80005284:	60e2                	ld	ra,24(sp)
    80005286:	6442                	ld	s0,16(sp)
    80005288:	64a2                	ld	s1,8(sp)
    8000528a:	6105                	addi	sp,sp,32
    8000528c:	8082                	ret

000000008000528e <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    8000528e:	1141                	addi	sp,sp,-16
    80005290:	e406                	sd	ra,8(sp)
    80005292:	e022                	sd	s0,0(sp)
    80005294:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005296:	479d                	li	a5,7
    80005298:	04a7ca63          	blt	a5,a0,800052ec <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    8000529c:	0001b797          	auipc	a5,0x1b
    800052a0:	78c78793          	addi	a5,a5,1932 # 80020a28 <disk>
    800052a4:	97aa                	add	a5,a5,a0
    800052a6:	0187c783          	lbu	a5,24(a5)
    800052aa:	e7b9                	bnez	a5,800052f8 <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800052ac:	00451613          	slli	a2,a0,0x4
    800052b0:	0001b797          	auipc	a5,0x1b
    800052b4:	77878793          	addi	a5,a5,1912 # 80020a28 <disk>
    800052b8:	6394                	ld	a3,0(a5)
    800052ba:	96b2                	add	a3,a3,a2
    800052bc:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800052c0:	6398                	ld	a4,0(a5)
    800052c2:	9732                	add	a4,a4,a2
    800052c4:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800052c8:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800052cc:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800052d0:	953e                	add	a0,a0,a5
    800052d2:	4785                	li	a5,1
    800052d4:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800052d8:	0001b517          	auipc	a0,0x1b
    800052dc:	76850513          	addi	a0,a0,1896 # 80020a40 <disk+0x18>
    800052e0:	b79fc0ef          	jal	ra,80001e58 <wakeup>
}
    800052e4:	60a2                	ld	ra,8(sp)
    800052e6:	6402                	ld	s0,0(sp)
    800052e8:	0141                	addi	sp,sp,16
    800052ea:	8082                	ret
    panic("free_desc 1");
    800052ec:	00002517          	auipc	a0,0x2
    800052f0:	43450513          	addi	a0,a0,1076 # 80007720 <syscalls+0x330>
    800052f4:	c96fb0ef          	jal	ra,8000078a <panic>
    panic("free_desc 2");
    800052f8:	00002517          	auipc	a0,0x2
    800052fc:	43850513          	addi	a0,a0,1080 # 80007730 <syscalls+0x340>
    80005300:	c8afb0ef          	jal	ra,8000078a <panic>

0000000080005304 <virtio_disk_init>:
{
    80005304:	1101                	addi	sp,sp,-32
    80005306:	ec06                	sd	ra,24(sp)
    80005308:	e822                	sd	s0,16(sp)
    8000530a:	e426                	sd	s1,8(sp)
    8000530c:	e04a                	sd	s2,0(sp)
    8000530e:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005310:	00002597          	auipc	a1,0x2
    80005314:	43058593          	addi	a1,a1,1072 # 80007740 <syscalls+0x350>
    80005318:	0001c517          	auipc	a0,0x1c
    8000531c:	83850513          	addi	a0,a0,-1992 # 80020b50 <disk+0x128>
    80005320:	fccfb0ef          	jal	ra,80000aec <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005324:	100017b7          	lui	a5,0x10001
    80005328:	4398                	lw	a4,0(a5)
    8000532a:	2701                	sext.w	a4,a4
    8000532c:	747277b7          	lui	a5,0x74727
    80005330:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005334:	14f71063          	bne	a4,a5,80005474 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005338:	100017b7          	lui	a5,0x10001
    8000533c:	43dc                	lw	a5,4(a5)
    8000533e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005340:	4709                	li	a4,2
    80005342:	12e79963          	bne	a5,a4,80005474 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005346:	100017b7          	lui	a5,0x10001
    8000534a:	479c                	lw	a5,8(a5)
    8000534c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000534e:	12e79363          	bne	a5,a4,80005474 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005352:	100017b7          	lui	a5,0x10001
    80005356:	47d8                	lw	a4,12(a5)
    80005358:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000535a:	554d47b7          	lui	a5,0x554d4
    8000535e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005362:	10f71963          	bne	a4,a5,80005474 <virtio_disk_init+0x170>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005366:	100017b7          	lui	a5,0x10001
    8000536a:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000536e:	4705                	li	a4,1
    80005370:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005372:	470d                	li	a4,3
    80005374:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005376:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005378:	c7ffe737          	lui	a4,0xc7ffe
    8000537c:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fddbf7>
    80005380:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005382:	2701                	sext.w	a4,a4
    80005384:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005386:	472d                	li	a4,11
    80005388:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    8000538a:	5bbc                	lw	a5,112(a5)
    8000538c:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005390:	8ba1                	andi	a5,a5,8
    80005392:	0e078763          	beqz	a5,80005480 <virtio_disk_init+0x17c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005396:	100017b7          	lui	a5,0x10001
    8000539a:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    8000539e:	43fc                	lw	a5,68(a5)
    800053a0:	2781                	sext.w	a5,a5
    800053a2:	0e079563          	bnez	a5,8000548c <virtio_disk_init+0x188>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800053a6:	100017b7          	lui	a5,0x10001
    800053aa:	5bdc                	lw	a5,52(a5)
    800053ac:	2781                	sext.w	a5,a5
  if(max == 0)
    800053ae:	0e078563          	beqz	a5,80005498 <virtio_disk_init+0x194>
  if(max < NUM)
    800053b2:	471d                	li	a4,7
    800053b4:	0ef77863          	bgeu	a4,a5,800054a4 <virtio_disk_init+0x1a0>
  disk.desc = kalloc();
    800053b8:	ee4fb0ef          	jal	ra,80000a9c <kalloc>
    800053bc:	0001b497          	auipc	s1,0x1b
    800053c0:	66c48493          	addi	s1,s1,1644 # 80020a28 <disk>
    800053c4:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800053c6:	ed6fb0ef          	jal	ra,80000a9c <kalloc>
    800053ca:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800053cc:	ed0fb0ef          	jal	ra,80000a9c <kalloc>
    800053d0:	87aa                	mv	a5,a0
    800053d2:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800053d4:	6088                	ld	a0,0(s1)
    800053d6:	cd69                	beqz	a0,800054b0 <virtio_disk_init+0x1ac>
    800053d8:	0001b717          	auipc	a4,0x1b
    800053dc:	65873703          	ld	a4,1624(a4) # 80020a30 <disk+0x8>
    800053e0:	cb61                	beqz	a4,800054b0 <virtio_disk_init+0x1ac>
    800053e2:	c7f9                	beqz	a5,800054b0 <virtio_disk_init+0x1ac>
  memset(disk.desc, 0, PGSIZE);
    800053e4:	6605                	lui	a2,0x1
    800053e6:	4581                	li	a1,0
    800053e8:	859fb0ef          	jal	ra,80000c40 <memset>
  memset(disk.avail, 0, PGSIZE);
    800053ec:	0001b497          	auipc	s1,0x1b
    800053f0:	63c48493          	addi	s1,s1,1596 # 80020a28 <disk>
    800053f4:	6605                	lui	a2,0x1
    800053f6:	4581                	li	a1,0
    800053f8:	6488                	ld	a0,8(s1)
    800053fa:	847fb0ef          	jal	ra,80000c40 <memset>
  memset(disk.used, 0, PGSIZE);
    800053fe:	6605                	lui	a2,0x1
    80005400:	4581                	li	a1,0
    80005402:	6888                	ld	a0,16(s1)
    80005404:	83dfb0ef          	jal	ra,80000c40 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005408:	100017b7          	lui	a5,0x10001
    8000540c:	4721                	li	a4,8
    8000540e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005410:	4098                	lw	a4,0(s1)
    80005412:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005416:	40d8                	lw	a4,4(s1)
    80005418:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000541c:	6498                	ld	a4,8(s1)
    8000541e:	0007069b          	sext.w	a3,a4
    80005422:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005426:	9701                	srai	a4,a4,0x20
    80005428:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000542c:	6898                	ld	a4,16(s1)
    8000542e:	0007069b          	sext.w	a3,a4
    80005432:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005436:	9701                	srai	a4,a4,0x20
    80005438:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000543c:	4705                	li	a4,1
    8000543e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005440:	00e48c23          	sb	a4,24(s1)
    80005444:	00e48ca3          	sb	a4,25(s1)
    80005448:	00e48d23          	sb	a4,26(s1)
    8000544c:	00e48da3          	sb	a4,27(s1)
    80005450:	00e48e23          	sb	a4,28(s1)
    80005454:	00e48ea3          	sb	a4,29(s1)
    80005458:	00e48f23          	sb	a4,30(s1)
    8000545c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005460:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005464:	0727a823          	sw	s2,112(a5)
}
    80005468:	60e2                	ld	ra,24(sp)
    8000546a:	6442                	ld	s0,16(sp)
    8000546c:	64a2                	ld	s1,8(sp)
    8000546e:	6902                	ld	s2,0(sp)
    80005470:	6105                	addi	sp,sp,32
    80005472:	8082                	ret
    panic("could not find virtio disk");
    80005474:	00002517          	auipc	a0,0x2
    80005478:	2dc50513          	addi	a0,a0,732 # 80007750 <syscalls+0x360>
    8000547c:	b0efb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk FEATURES_OK unset");
    80005480:	00002517          	auipc	a0,0x2
    80005484:	2f050513          	addi	a0,a0,752 # 80007770 <syscalls+0x380>
    80005488:	b02fb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk should not be ready");
    8000548c:	00002517          	auipc	a0,0x2
    80005490:	30450513          	addi	a0,a0,772 # 80007790 <syscalls+0x3a0>
    80005494:	af6fb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk has no queue 0");
    80005498:	00002517          	auipc	a0,0x2
    8000549c:	31850513          	addi	a0,a0,792 # 800077b0 <syscalls+0x3c0>
    800054a0:	aeafb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk max queue too short");
    800054a4:	00002517          	auipc	a0,0x2
    800054a8:	32c50513          	addi	a0,a0,812 # 800077d0 <syscalls+0x3e0>
    800054ac:	adefb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk kalloc");
    800054b0:	00002517          	auipc	a0,0x2
    800054b4:	34050513          	addi	a0,a0,832 # 800077f0 <syscalls+0x400>
    800054b8:	ad2fb0ef          	jal	ra,8000078a <panic>

00000000800054bc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800054bc:	7119                	addi	sp,sp,-128
    800054be:	fc86                	sd	ra,120(sp)
    800054c0:	f8a2                	sd	s0,112(sp)
    800054c2:	f4a6                	sd	s1,104(sp)
    800054c4:	f0ca                	sd	s2,96(sp)
    800054c6:	ecce                	sd	s3,88(sp)
    800054c8:	e8d2                	sd	s4,80(sp)
    800054ca:	e4d6                	sd	s5,72(sp)
    800054cc:	e0da                	sd	s6,64(sp)
    800054ce:	fc5e                	sd	s7,56(sp)
    800054d0:	f862                	sd	s8,48(sp)
    800054d2:	f466                	sd	s9,40(sp)
    800054d4:	f06a                	sd	s10,32(sp)
    800054d6:	ec6e                	sd	s11,24(sp)
    800054d8:	0100                	addi	s0,sp,128
    800054da:	8aaa                	mv	s5,a0
    800054dc:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800054de:	00c52d03          	lw	s10,12(a0)
    800054e2:	001d1d1b          	slliw	s10,s10,0x1
    800054e6:	1d02                	slli	s10,s10,0x20
    800054e8:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800054ec:	0001b517          	auipc	a0,0x1b
    800054f0:	66450513          	addi	a0,a0,1636 # 80020b50 <disk+0x128>
    800054f4:	e78fb0ef          	jal	ra,80000b6c <acquire>
  for(int i = 0; i < 3; i++){
    800054f8:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800054fa:	44a1                	li	s1,8
      disk.free[i] = 0;
    800054fc:	0001bb97          	auipc	s7,0x1b
    80005500:	52cb8b93          	addi	s7,s7,1324 # 80020a28 <disk>
  for(int i = 0; i < 3; i++){
    80005504:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005506:	0001bc97          	auipc	s9,0x1b
    8000550a:	64ac8c93          	addi	s9,s9,1610 # 80020b50 <disk+0x128>
    8000550e:	a8a9                	j	80005568 <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    80005510:	00fb8733          	add	a4,s7,a5
    80005514:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005518:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000551a:	0207c563          	bltz	a5,80005544 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000551e:	2905                	addiw	s2,s2,1
    80005520:	0611                	addi	a2,a2,4
    80005522:	05690863          	beq	s2,s6,80005572 <virtio_disk_rw+0xb6>
    idx[i] = alloc_desc();
    80005526:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005528:	0001b717          	auipc	a4,0x1b
    8000552c:	50070713          	addi	a4,a4,1280 # 80020a28 <disk>
    80005530:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005532:	01874683          	lbu	a3,24(a4)
    80005536:	fee9                	bnez	a3,80005510 <virtio_disk_rw+0x54>
  for(int i = 0; i < NUM; i++){
    80005538:	2785                	addiw	a5,a5,1
    8000553a:	0705                	addi	a4,a4,1
    8000553c:	fe979be3          	bne	a5,s1,80005532 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005540:	57fd                	li	a5,-1
    80005542:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005544:	01205b63          	blez	s2,8000555a <virtio_disk_rw+0x9e>
    80005548:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000554a:	000a2503          	lw	a0,0(s4)
    8000554e:	d41ff0ef          	jal	ra,8000528e <free_desc>
      for(int j = 0; j < i; j++)
    80005552:	2d85                	addiw	s11,s11,1
    80005554:	0a11                	addi	s4,s4,4
    80005556:	ffb91ae3          	bne	s2,s11,8000554a <virtio_disk_rw+0x8e>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000555a:	85e6                	mv	a1,s9
    8000555c:	0001b517          	auipc	a0,0x1b
    80005560:	4e450513          	addi	a0,a0,1252 # 80020a40 <disk+0x18>
    80005564:	8a9fc0ef          	jal	ra,80001e0c <sleep>
  for(int i = 0; i < 3; i++){
    80005568:	f8040a13          	addi	s4,s0,-128
{
    8000556c:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000556e:	894e                	mv	s2,s3
    80005570:	bf5d                	j	80005526 <virtio_disk_rw+0x6a>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005572:	f8042583          	lw	a1,-128(s0)
    80005576:	00a58793          	addi	a5,a1,10
    8000557a:	0792                	slli	a5,a5,0x4

  if(write)
    8000557c:	0001b617          	auipc	a2,0x1b
    80005580:	4ac60613          	addi	a2,a2,1196 # 80020a28 <disk>
    80005584:	00f60733          	add	a4,a2,a5
    80005588:	018036b3          	snez	a3,s8
    8000558c:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000558e:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80005592:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005596:	f6078693          	addi	a3,a5,-160
    8000559a:	6218                	ld	a4,0(a2)
    8000559c:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000559e:	00878513          	addi	a0,a5,8
    800055a2:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800055a4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800055a6:	6208                	ld	a0,0(a2)
    800055a8:	96aa                	add	a3,a3,a0
    800055aa:	4741                	li	a4,16
    800055ac:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800055ae:	4705                	li	a4,1
    800055b0:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800055b4:	f8442703          	lw	a4,-124(s0)
    800055b8:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800055bc:	0712                	slli	a4,a4,0x4
    800055be:	953a                	add	a0,a0,a4
    800055c0:	058a8693          	addi	a3,s5,88
    800055c4:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800055c6:	6208                	ld	a0,0(a2)
    800055c8:	972a                	add	a4,a4,a0
    800055ca:	40000693          	li	a3,1024
    800055ce:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800055d0:	001c3c13          	seqz	s8,s8
    800055d4:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800055d6:	001c6c13          	ori	s8,s8,1
    800055da:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800055de:	f8842603          	lw	a2,-120(s0)
    800055e2:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800055e6:	0001b697          	auipc	a3,0x1b
    800055ea:	44268693          	addi	a3,a3,1090 # 80020a28 <disk>
    800055ee:	00258713          	addi	a4,a1,2
    800055f2:	0712                	slli	a4,a4,0x4
    800055f4:	9736                	add	a4,a4,a3
    800055f6:	587d                	li	a6,-1
    800055f8:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800055fc:	0612                	slli	a2,a2,0x4
    800055fe:	9532                	add	a0,a0,a2
    80005600:	f9078793          	addi	a5,a5,-112
    80005604:	97b6                	add	a5,a5,a3
    80005606:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    80005608:	629c                	ld	a5,0(a3)
    8000560a:	97b2                	add	a5,a5,a2
    8000560c:	4605                	li	a2,1
    8000560e:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005610:	4509                	li	a0,2
    80005612:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    80005616:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000561a:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000561e:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005622:	6698                	ld	a4,8(a3)
    80005624:	00275783          	lhu	a5,2(a4)
    80005628:	8b9d                	andi	a5,a5,7
    8000562a:	0786                	slli	a5,a5,0x1
    8000562c:	97ba                	add	a5,a5,a4
    8000562e:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80005632:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005636:	6698                	ld	a4,8(a3)
    80005638:	00275783          	lhu	a5,2(a4)
    8000563c:	2785                	addiw	a5,a5,1
    8000563e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005642:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005646:	100017b7          	lui	a5,0x10001
    8000564a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000564e:	004aa783          	lw	a5,4(s5)
    80005652:	00c79f63          	bne	a5,a2,80005670 <virtio_disk_rw+0x1b4>
    sleep(b, &disk.vdisk_lock);
    80005656:	0001b917          	auipc	s2,0x1b
    8000565a:	4fa90913          	addi	s2,s2,1274 # 80020b50 <disk+0x128>
  while(b->disk == 1) {
    8000565e:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005660:	85ca                	mv	a1,s2
    80005662:	8556                	mv	a0,s5
    80005664:	fa8fc0ef          	jal	ra,80001e0c <sleep>
  while(b->disk == 1) {
    80005668:	004aa783          	lw	a5,4(s5)
    8000566c:	fe978ae3          	beq	a5,s1,80005660 <virtio_disk_rw+0x1a4>
  }

  disk.info[idx[0]].b = 0;
    80005670:	f8042903          	lw	s2,-128(s0)
    80005674:	00290793          	addi	a5,s2,2
    80005678:	00479713          	slli	a4,a5,0x4
    8000567c:	0001b797          	auipc	a5,0x1b
    80005680:	3ac78793          	addi	a5,a5,940 # 80020a28 <disk>
    80005684:	97ba                	add	a5,a5,a4
    80005686:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000568a:	0001b997          	auipc	s3,0x1b
    8000568e:	39e98993          	addi	s3,s3,926 # 80020a28 <disk>
    80005692:	00491713          	slli	a4,s2,0x4
    80005696:	0009b783          	ld	a5,0(s3)
    8000569a:	97ba                	add	a5,a5,a4
    8000569c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800056a0:	854a                	mv	a0,s2
    800056a2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800056a6:	be9ff0ef          	jal	ra,8000528e <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800056aa:	8885                	andi	s1,s1,1
    800056ac:	f0fd                	bnez	s1,80005692 <virtio_disk_rw+0x1d6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800056ae:	0001b517          	auipc	a0,0x1b
    800056b2:	4a250513          	addi	a0,a0,1186 # 80020b50 <disk+0x128>
    800056b6:	d4efb0ef          	jal	ra,80000c04 <release>
}
    800056ba:	70e6                	ld	ra,120(sp)
    800056bc:	7446                	ld	s0,112(sp)
    800056be:	74a6                	ld	s1,104(sp)
    800056c0:	7906                	ld	s2,96(sp)
    800056c2:	69e6                	ld	s3,88(sp)
    800056c4:	6a46                	ld	s4,80(sp)
    800056c6:	6aa6                	ld	s5,72(sp)
    800056c8:	6b06                	ld	s6,64(sp)
    800056ca:	7be2                	ld	s7,56(sp)
    800056cc:	7c42                	ld	s8,48(sp)
    800056ce:	7ca2                	ld	s9,40(sp)
    800056d0:	7d02                	ld	s10,32(sp)
    800056d2:	6de2                	ld	s11,24(sp)
    800056d4:	6109                	addi	sp,sp,128
    800056d6:	8082                	ret

00000000800056d8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800056d8:	1101                	addi	sp,sp,-32
    800056da:	ec06                	sd	ra,24(sp)
    800056dc:	e822                	sd	s0,16(sp)
    800056de:	e426                	sd	s1,8(sp)
    800056e0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800056e2:	0001b497          	auipc	s1,0x1b
    800056e6:	34648493          	addi	s1,s1,838 # 80020a28 <disk>
    800056ea:	0001b517          	auipc	a0,0x1b
    800056ee:	46650513          	addi	a0,a0,1126 # 80020b50 <disk+0x128>
    800056f2:	c7afb0ef          	jal	ra,80000b6c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800056f6:	10001737          	lui	a4,0x10001
    800056fa:	533c                	lw	a5,96(a4)
    800056fc:	8b8d                	andi	a5,a5,3
    800056fe:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80005700:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80005704:	689c                	ld	a5,16(s1)
    80005706:	0204d703          	lhu	a4,32(s1)
    8000570a:	0027d783          	lhu	a5,2(a5)
    8000570e:	04f70663          	beq	a4,a5,8000575a <virtio_disk_intr+0x82>
    __sync_synchronize();
    80005712:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80005716:	6898                	ld	a4,16(s1)
    80005718:	0204d783          	lhu	a5,32(s1)
    8000571c:	8b9d                	andi	a5,a5,7
    8000571e:	078e                	slli	a5,a5,0x3
    80005720:	97ba                	add	a5,a5,a4
    80005722:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005724:	00278713          	addi	a4,a5,2
    80005728:	0712                	slli	a4,a4,0x4
    8000572a:	9726                	add	a4,a4,s1
    8000572c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80005730:	e321                	bnez	a4,80005770 <virtio_disk_intr+0x98>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005732:	0789                	addi	a5,a5,2
    80005734:	0792                	slli	a5,a5,0x4
    80005736:	97a6                	add	a5,a5,s1
    80005738:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000573a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000573e:	f1afc0ef          	jal	ra,80001e58 <wakeup>

    disk.used_idx += 1;
    80005742:	0204d783          	lhu	a5,32(s1)
    80005746:	2785                	addiw	a5,a5,1
    80005748:	17c2                	slli	a5,a5,0x30
    8000574a:	93c1                	srli	a5,a5,0x30
    8000574c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005750:	6898                	ld	a4,16(s1)
    80005752:	00275703          	lhu	a4,2(a4)
    80005756:	faf71ee3          	bne	a4,a5,80005712 <virtio_disk_intr+0x3a>
  }

  release(&disk.vdisk_lock);
    8000575a:	0001b517          	auipc	a0,0x1b
    8000575e:	3f650513          	addi	a0,a0,1014 # 80020b50 <disk+0x128>
    80005762:	ca2fb0ef          	jal	ra,80000c04 <release>
}
    80005766:	60e2                	ld	ra,24(sp)
    80005768:	6442                	ld	s0,16(sp)
    8000576a:	64a2                	ld	s1,8(sp)
    8000576c:	6105                	addi	sp,sp,32
    8000576e:	8082                	ret
      panic("virtio_disk_intr status");
    80005770:	00002517          	auipc	a0,0x2
    80005774:	09850513          	addi	a0,a0,152 # 80007808 <syscalls+0x418>
    80005778:	812fb0ef          	jal	ra,8000078a <panic>
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
