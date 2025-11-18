
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
    80000004:	89010113          	addi	sp,sp,-1904 # 80007890 <stack0>
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
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdd5c7>
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
    8000010a:	673010ef          	jal	ra,80001f7c <either_copyin>
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
    80000176:	71e50513          	addi	a0,a0,1822 # 8000f890 <cons>
    8000017a:	1f3000ef          	jal	ra,80000b6c <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000017e:	0000f497          	auipc	s1,0xf
    80000182:	71248493          	addi	s1,s1,1810 # 8000f890 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000186:	0000f917          	auipc	s2,0xf
    8000018a:	7a290913          	addi	s2,s2,1954 # 8000f928 <cons+0x98>
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
    800001a4:	690010ef          	jal	ra,80001834 <myproc>
    800001a8:	467010ef          	jal	ra,80001e0e <killed>
    800001ac:	e125                	bnez	a0,8000020c <consoleread+0xc0>
      sleep(&cons.r, &cons.lock);
    800001ae:	85a6                	mv	a1,s1
    800001b0:	854a                	mv	a0,s2
    800001b2:	383010ef          	jal	ra,80001d34 <sleep>
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
    800001ea:	549010ef          	jal	ra,80001f32 <either_copyout>
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
    800001fe:	69650513          	addi	a0,a0,1686 # 8000f890 <cons>
    80000202:	203000ef          	jal	ra,80000c04 <release>

  return target - n;
    80000206:	413b053b          	subw	a0,s6,s3
    8000020a:	a801                	j	8000021a <consoleread+0xce>
        release(&cons.lock);
    8000020c:	0000f517          	auipc	a0,0xf
    80000210:	68450513          	addi	a0,a0,1668 # 8000f890 <cons>
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
    80000242:	6ef72523          	sw	a5,1770(a4) # 8000f928 <cons+0x98>
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
    8000028c:	60850513          	addi	a0,a0,1544 # 8000f890 <cons>
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
    800002aa:	51d010ef          	jal	ra,80001fc6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002ae:	0000f517          	auipc	a0,0xf
    800002b2:	5e250513          	addi	a0,a0,1506 # 8000f890 <cons>
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
    800002d2:	5c270713          	addi	a4,a4,1474 # 8000f890 <cons>
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
    800002f8:	59c78793          	addi	a5,a5,1436 # 8000f890 <cons>
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
    80000326:	6067a783          	lw	a5,1542(a5) # 8000f928 <cons+0x98>
    8000032a:	9f1d                	subw	a4,a4,a5
    8000032c:	08000793          	li	a5,128
    80000330:	f6f71fe3          	bne	a4,a5,800002ae <consoleintr+0x34>
    80000334:	a04d                	j	800003d6 <consoleintr+0x15c>
    while(cons.e != cons.w &&
    80000336:	0000f717          	auipc	a4,0xf
    8000033a:	55a70713          	addi	a4,a4,1370 # 8000f890 <cons>
    8000033e:	0a072783          	lw	a5,160(a4)
    80000342:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000346:	0000f497          	auipc	s1,0xf
    8000034a:	54a48493          	addi	s1,s1,1354 # 8000f890 <cons>
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
    80000382:	51270713          	addi	a4,a4,1298 # 8000f890 <cons>
    80000386:	0a072783          	lw	a5,160(a4)
    8000038a:	09c72703          	lw	a4,156(a4)
    8000038e:	f2f700e3          	beq	a4,a5,800002ae <consoleintr+0x34>
      cons.e--;
    80000392:	37fd                	addiw	a5,a5,-1
    80000394:	0000f717          	auipc	a4,0xf
    80000398:	58f72e23          	sw	a5,1436(a4) # 8000f930 <cons+0xa0>
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
    800003b6:	4de78793          	addi	a5,a5,1246 # 8000f890 <cons>
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
    800003da:	54c7ab23          	sw	a2,1366(a5) # 8000f92c <cons+0x9c>
        wakeup(&cons.r);
    800003de:	0000f517          	auipc	a0,0xf
    800003e2:	54a50513          	addi	a0,a0,1354 # 8000f928 <cons+0x98>
    800003e6:	5ff010ef          	jal	ra,800021e4 <wakeup>
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
    80000400:	49450513          	addi	a0,a0,1172 # 8000f890 <cons>
    80000404:	6e8000ef          	jal	ra,80000aec <initlock>

  uartinit();
    80000408:	3e2000ef          	jal	ra,800007ea <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000040c:	00020797          	auipc	a5,0x20
    80000410:	c9478793          	addi	a5,a5,-876 # 800200a0 <devsw>
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
    800004fa:	35e7a783          	lw	a5,862(a5) # 80007854 <panicking>
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
    80000538:	40450513          	addi	a0,a0,1028 # 8000f938 <pr>
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
    80000756:	1027a783          	lw	a5,258(a5) # 80007854 <panicking>
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
    80000780:	1bc50513          	addi	a0,a0,444 # 8000f938 <pr>
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
    8000079e:	0b27ad23          	sw	s2,186(a5) # 80007854 <panicking>
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
    800007c0:	0927aa23          	sw	s2,148(a5) # 80007850 <panicked>
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
    800007da:	16250513          	addi	a0,a0,354 # 8000f938 <pr>
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
    80000826:	12e50513          	addi	a0,a0,302 # 8000f950 <tx_lock>
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
    80000854:	10050513          	addi	a0,a0,256 # 8000f950 <tx_lock>
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
    80000872:	fee48493          	addi	s1,s1,-18 # 8000785c <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    80000876:	0000f997          	auipc	s3,0xf
    8000087a:	0da98993          	addi	s3,s3,218 # 8000f950 <tx_lock>
    8000087e:	00007917          	auipc	s2,0x7
    80000882:	fda90913          	addi	s2,s2,-38 # 80007858 <tx_chan>
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
    80000892:	4a2010ef          	jal	ra,80001d34 <sleep>
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
    800008b6:	09e50513          	addi	a0,a0,158 # 8000f950 <tx_lock>
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
    800008e4:	f747a783          	lw	a5,-140(a5) # 80007854 <panicking>
    800008e8:	cb89                	beqz	a5,800008fa <uartputc_sync+0x26>
    push_off();

  if(panicked){
    800008ea:	00007797          	auipc	a5,0x7
    800008ee:	f667a783          	lw	a5,-154(a5) # 80007850 <panicked>
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
    8000091a:	f3e7a783          	lw	a5,-194(a5) # 80007854 <panicking>
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
    8000096e:	fe650513          	addi	a0,a0,-26 # 8000f950 <tx_lock>
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
    80000984:	fd050513          	addi	a0,a0,-48 # 8000f950 <tx_lock>
    80000988:	27c000ef          	jal	ra,80000c04 <release>

  // read and process incoming characters, if any.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000098c:	54fd                	li	s1,-1
    8000098e:	a831                	j	800009aa <uartintr+0x52>
    tx_busy = 0;
    80000990:	00007797          	auipc	a5,0x7
    80000994:	ec07a623          	sw	zero,-308(a5) # 8000785c <tx_busy>
    wakeup(&tx_chan);
    80000998:	00007517          	auipc	a0,0x7
    8000099c:	ec050513          	addi	a0,a0,-320 # 80007858 <tx_chan>
    800009a0:	045010ef          	jal	ra,800021e4 <wakeup>
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
    800009d0:	00021797          	auipc	a5,0x21
    800009d4:	86878793          	addi	a5,a5,-1944 # 80021238 <end>
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
    800009f0:	f7c90913          	addi	s2,s2,-132 # 8000f968 <kmem>
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
    80000a7c:	ef050513          	addi	a0,a0,-272 # 8000f968 <kmem>
    80000a80:	06c000ef          	jal	ra,80000aec <initlock>
  freerange(end, (void*)PHYSTOP);
    80000a84:	45c5                	li	a1,17
    80000a86:	05ee                	slli	a1,a1,0x1b
    80000a88:	00020517          	auipc	a0,0x20
    80000a8c:	7b050513          	addi	a0,a0,1968 # 80021238 <end>
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
    80000aaa:	ec248493          	addi	s1,s1,-318 # 8000f968 <kmem>
    80000aae:	8526                	mv	a0,s1
    80000ab0:	0bc000ef          	jal	ra,80000b6c <acquire>
  r = kmem.freelist;
    80000ab4:	6c84                	ld	s1,24(s1)
  if(r)
    80000ab6:	c485                	beqz	s1,80000ade <kalloc+0x42>
    kmem.freelist = r->next;
    80000ab8:	609c                	ld	a5,0(s1)
    80000aba:	0000f517          	auipc	a0,0xf
    80000abe:	eae50513          	addi	a0,a0,-338 # 8000f968 <kmem>
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
    80000ae2:	e8a50513          	addi	a0,a0,-374 # 8000f968 <kmem>
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
    80000b16:	503000ef          	jal	ra,80001818 <mycpu>
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
    80000b44:	4d5000ef          	jal	ra,80001818 <mycpu>
    80000b48:	5d3c                	lw	a5,120(a0)
    80000b4a:	cb99                	beqz	a5,80000b60 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b4c:	4cd000ef          	jal	ra,80001818 <mycpu>
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
    80000b60:	4b9000ef          	jal	ra,80001818 <mycpu>
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
    80000b94:	485000ef          	jal	ra,80001818 <mycpu>
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
    80000bb8:	461000ef          	jal	ra,80001818 <mycpu>
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
    80000dea:	21f000ef          	jal	ra,80001808 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000dee:	00007717          	auipc	a4,0x7
    80000df2:	a7270713          	addi	a4,a4,-1422 # 80007860 <started>
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
    80000e02:	207000ef          	jal	ra,80001808 <cpuid>
    80000e06:	85aa                	mv	a1,a0
    80000e08:	00006517          	auipc	a0,0x6
    80000e0c:	2a850513          	addi	a0,a0,680 # 800070b0 <digits+0x78>
    80000e10:	eb4ff0ef          	jal	ra,800004c4 <printf>
    kvminithart();    // turn on paging
    80000e14:	080000ef          	jal	ra,80000e94 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000e18:	71c010ef          	jal	ra,80002534 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000e1c:	6b8040ef          	jal	ra,800054d4 <plicinithart>
  }

  scheduler();        
    80000e20:	586010ef          	jal	ra,800023a6 <scheduler>
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
    80000e60:	6b0010ef          	jal	ra,80002510 <trapinit>
    trapinithart();  // install kernel trap vector
    80000e64:	6d0010ef          	jal	ra,80002534 <trapinithart>
    plicinit();      // set up interrupt controller
    80000e68:	656040ef          	jal	ra,800054be <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000e6c:	668040ef          	jal	ra,800054d4 <plicinithart>
    binit();         // buffer cache
    80000e70:	609010ef          	jal	ra,80002c78 <binit>
    iinit();         // inode table
    80000e74:	37c020ef          	jal	ra,800031f0 <iinit>
    fileinit();      // file table
    80000e78:	25c030ef          	jal	ra,800040d4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000e7c:	748040ef          	jal	ra,800055c4 <virtio_disk_init>
    userinit();      // first user process
    80000e80:	2ec010ef          	jal	ra,8000216c <userinit>
    __sync_synchronize();
    80000e84:	0ff0000f          	fence
    started = 1;
    80000e88:	4785                	li	a5,1
    80000e8a:	00007717          	auipc	a4,0x7
    80000e8e:	9cf72b23          	sw	a5,-1578(a4) # 80007860 <started>
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
    80000ea2:	9ca7b783          	ld	a5,-1590(a5) # 80007868 <kernel_pagetable>
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
    8000112e:	72a7bf23          	sd	a0,1854(a5) # 80007868 <kernel_pagetable>
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
    800014f4:	340000ef          	jal	ra,80001834 <myproc>
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
    800016c0:	79c48493          	addi	s1,s1,1948 # 8000fe58 <proc>
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
    800016da:	782a0a13          	addi	s4,s4,1922 # 80015e58 <tickslock>
    char *pa = kalloc();
    800016de:	bbeff0ef          	jal	ra,80000a9c <kalloc>
    800016e2:	862a                	mv	a2,a0
    if(pa == 0)
    800016e4:	c121                	beqz	a0,80001724 <proc_mapstacks+0x7e>
    uint64 va = KSTACK((int) (p - proc));
    800016e6:	416485b3          	sub	a1,s1,s6
    800016ea:	859d                	srai	a1,a1,0x7
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
    80001708:	18048493          	addi	s1,s1,384
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
 
  // 初始化多级队列
  for (int i = 0; i < NQUEUES; i++) {
    80001744:	0000e497          	auipc	s1,0xe
    80001748:	24448493          	addi	s1,s1,580 # 8000f988 <run_queues>
    8000174c:	0000e997          	auipc	s3,0xe
    80001750:	2dc98993          	addi	s3,s3,732 # 8000fa28 <pid_lock>
    initlock(&run_queues[i].lock, "runqueue");
    80001754:	00006917          	auipc	s2,0x6
    80001758:	a2490913          	addi	s2,s2,-1500 # 80007178 <digits+0x140>
    8000175c:	85ca                	mv	a1,s2
    8000175e:	8526                	mv	a0,s1
    80001760:	b8cff0ef          	jal	ra,80000aec <initlock>
    run_queues[i].head = 0;
    80001764:	0004bc23          	sd	zero,24(s1)
    run_queues[i].tail = 0;
    80001768:	0204b023          	sd	zero,32(s1)
  for (int i = 0; i < NQUEUES; i++) {
    8000176c:	02848493          	addi	s1,s1,40
    80001770:	ff3496e3          	bne	s1,s3,8000175c <procinit+0x2c>
  }
  
  initlock(&pid_lock, "nextpid");
    80001774:	00006597          	auipc	a1,0x6
    80001778:	a1458593          	addi	a1,a1,-1516 # 80007188 <digits+0x150>
    8000177c:	0000e517          	auipc	a0,0xe
    80001780:	2ac50513          	addi	a0,a0,684 # 8000fa28 <pid_lock>
    80001784:	b68ff0ef          	jal	ra,80000aec <initlock>
  initlock(&wait_lock, "wait_lock");
    80001788:	00006597          	auipc	a1,0x6
    8000178c:	a0858593          	addi	a1,a1,-1528 # 80007190 <digits+0x158>
    80001790:	0000e517          	auipc	a0,0xe
    80001794:	2b050513          	addi	a0,a0,688 # 8000fa40 <wait_lock>
    80001798:	b54ff0ef          	jal	ra,80000aec <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000179c:	0000e497          	auipc	s1,0xe
    800017a0:	6bc48493          	addi	s1,s1,1724 # 8000fe58 <proc>
      initlock(&p->lock, "proc");
    800017a4:	00006b17          	auipc	s6,0x6
    800017a8:	9fcb0b13          	addi	s6,s6,-1540 # 800071a0 <digits+0x168>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    800017ac:	8aa6                	mv	s5,s1
    800017ae:	00006a17          	auipc	s4,0x6
    800017b2:	852a0a13          	addi	s4,s4,-1966 # 80007000 <etext>
    800017b6:	04000937          	lui	s2,0x4000
    800017ba:	197d                	addi	s2,s2,-1
    800017bc:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800017be:	00014997          	auipc	s3,0x14
    800017c2:	69a98993          	addi	s3,s3,1690 # 80015e58 <tickslock>
      initlock(&p->lock, "proc");
    800017c6:	85da                	mv	a1,s6
    800017c8:	8526                	mv	a0,s1
    800017ca:	b22ff0ef          	jal	ra,80000aec <initlock>
      p->state = UNUSED;
    800017ce:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800017d2:	415487b3          	sub	a5,s1,s5
    800017d6:	879d                	srai	a5,a5,0x7
    800017d8:	000a3703          	ld	a4,0(s4)
    800017dc:	02e787b3          	mul	a5,a5,a4
    800017e0:	2785                	addiw	a5,a5,1
    800017e2:	00d7979b          	slliw	a5,a5,0xd
    800017e6:	40f907b3          	sub	a5,s2,a5
    800017ea:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800017ec:	18048493          	addi	s1,s1,384
    800017f0:	fd349be3          	bne	s1,s3,800017c6 <procinit+0x96>
  }
}
    800017f4:	70e2                	ld	ra,56(sp)
    800017f6:	7442                	ld	s0,48(sp)
    800017f8:	74a2                	ld	s1,40(sp)
    800017fa:	7902                	ld	s2,32(sp)
    800017fc:	69e2                	ld	s3,24(sp)
    800017fe:	6a42                	ld	s4,16(sp)
    80001800:	6aa2                	ld	s5,8(sp)
    80001802:	6b02                	ld	s6,0(sp)
    80001804:	6121                	addi	sp,sp,64
    80001806:	8082                	ret

0000000080001808 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001808:	1141                	addi	sp,sp,-16
    8000180a:	e422                	sd	s0,8(sp)
    8000180c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000180e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001810:	2501                	sext.w	a0,a0
    80001812:	6422                	ld	s0,8(sp)
    80001814:	0141                	addi	sp,sp,16
    80001816:	8082                	ret

0000000080001818 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001818:	1141                	addi	sp,sp,-16
    8000181a:	e422                	sd	s0,8(sp)
    8000181c:	0800                	addi	s0,sp,16
    8000181e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001820:	2781                	sext.w	a5,a5
    80001822:	079e                	slli	a5,a5,0x7
  return c;
}
    80001824:	0000e517          	auipc	a0,0xe
    80001828:	23450513          	addi	a0,a0,564 # 8000fa58 <cpus>
    8000182c:	953e                	add	a0,a0,a5
    8000182e:	6422                	ld	s0,8(sp)
    80001830:	0141                	addi	sp,sp,16
    80001832:	8082                	ret

0000000080001834 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001834:	1101                	addi	sp,sp,-32
    80001836:	ec06                	sd	ra,24(sp)
    80001838:	e822                	sd	s0,16(sp)
    8000183a:	e426                	sd	s1,8(sp)
    8000183c:	1000                	addi	s0,sp,32
  push_off();
    8000183e:	aeeff0ef          	jal	ra,80000b2c <push_off>
    80001842:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001844:	2781                	sext.w	a5,a5
    80001846:	079e                	slli	a5,a5,0x7
    80001848:	0000e717          	auipc	a4,0xe
    8000184c:	14070713          	addi	a4,a4,320 # 8000f988 <run_queues>
    80001850:	97ba                	add	a5,a5,a4
    80001852:	6be4                	ld	s1,208(a5)
  pop_off();
    80001854:	b5cff0ef          	jal	ra,80000bb0 <pop_off>
  return p;
}
    80001858:	8526                	mv	a0,s1
    8000185a:	60e2                	ld	ra,24(sp)
    8000185c:	6442                	ld	s0,16(sp)
    8000185e:	64a2                	ld	s1,8(sp)
    80001860:	6105                	addi	sp,sp,32
    80001862:	8082                	ret

0000000080001864 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001864:	7179                	addi	sp,sp,-48
    80001866:	f406                	sd	ra,40(sp)
    80001868:	f022                	sd	s0,32(sp)
    8000186a:	ec26                	sd	s1,24(sp)
    8000186c:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    8000186e:	fc7ff0ef          	jal	ra,80001834 <myproc>
    80001872:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    80001874:	b90ff0ef          	jal	ra,80000c04 <release>

  if (first) {
    80001878:	00006797          	auipc	a5,0x6
    8000187c:	fc87a783          	lw	a5,-56(a5) # 80007840 <first.1>
    80001880:	cf8d                	beqz	a5,800018ba <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    80001882:	4505                	li	a0,1
    80001884:	61d010ef          	jal	ra,800036a0 <fsinit>

    first = 0;
    80001888:	00006797          	auipc	a5,0x6
    8000188c:	fa07ac23          	sw	zero,-72(a5) # 80007840 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    80001890:	0ff0000f          	fence

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    80001894:	00006517          	auipc	a0,0x6
    80001898:	91450513          	addi	a0,a0,-1772 # 800071a8 <digits+0x170>
    8000189c:	fca43823          	sd	a0,-48(s0)
    800018a0:	fc043c23          	sd	zero,-40(s0)
    800018a4:	fd040593          	addi	a1,s0,-48
    800018a8:	6a1020ef          	jal	ra,80004748 <kexec>
    800018ac:	6cbc                	ld	a5,88(s1)
    800018ae:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    800018b0:	6cbc                	ld	a5,88(s1)
    800018b2:	7bb8                	ld	a4,112(a5)
    800018b4:	57fd                	li	a5,-1
    800018b6:	02f70d63          	beq	a4,a5,800018f0 <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    800018ba:	493000ef          	jal	ra,8000254c <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800018be:	68a8                	ld	a0,80(s1)
    800018c0:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800018c2:	04000737          	lui	a4,0x4000
    800018c6:	00004797          	auipc	a5,0x4
    800018ca:	7d678793          	addi	a5,a5,2006 # 8000609c <userret>
    800018ce:	00004697          	auipc	a3,0x4
    800018d2:	73268693          	addi	a3,a3,1842 # 80006000 <_trampoline>
    800018d6:	8f95                	sub	a5,a5,a3
    800018d8:	177d                	addi	a4,a4,-1
    800018da:	0732                	slli	a4,a4,0xc
    800018dc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800018de:	577d                	li	a4,-1
    800018e0:	177e                	slli	a4,a4,0x3f
    800018e2:	8d59                	or	a0,a0,a4
    800018e4:	9782                	jalr	a5
}
    800018e6:	70a2                	ld	ra,40(sp)
    800018e8:	7402                	ld	s0,32(sp)
    800018ea:	64e2                	ld	s1,24(sp)
    800018ec:	6145                	addi	sp,sp,48
    800018ee:	8082                	ret
      panic("exec");
    800018f0:	00006517          	auipc	a0,0x6
    800018f4:	8c050513          	addi	a0,a0,-1856 # 800071b0 <digits+0x178>
    800018f8:	e93fe0ef          	jal	ra,8000078a <panic>

00000000800018fc <allocpid>:
{
    800018fc:	1101                	addi	sp,sp,-32
    800018fe:	ec06                	sd	ra,24(sp)
    80001900:	e822                	sd	s0,16(sp)
    80001902:	e426                	sd	s1,8(sp)
    80001904:	e04a                	sd	s2,0(sp)
    80001906:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001908:	0000e917          	auipc	s2,0xe
    8000190c:	12090913          	addi	s2,s2,288 # 8000fa28 <pid_lock>
    80001910:	854a                	mv	a0,s2
    80001912:	a5aff0ef          	jal	ra,80000b6c <acquire>
  pid = nextpid;
    80001916:	00006797          	auipc	a5,0x6
    8000191a:	f2e78793          	addi	a5,a5,-210 # 80007844 <nextpid>
    8000191e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001920:	0014871b          	addiw	a4,s1,1
    80001924:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001926:	854a                	mv	a0,s2
    80001928:	adcff0ef          	jal	ra,80000c04 <release>
}
    8000192c:	8526                	mv	a0,s1
    8000192e:	60e2                	ld	ra,24(sp)
    80001930:	6442                	ld	s0,16(sp)
    80001932:	64a2                	ld	s1,8(sp)
    80001934:	6902                	ld	s2,0(sp)
    80001936:	6105                	addi	sp,sp,32
    80001938:	8082                	ret

000000008000193a <proc_pagetable>:
{
    8000193a:	1101                	addi	sp,sp,-32
    8000193c:	ec06                	sd	ra,24(sp)
    8000193e:	e822                	sd	s0,16(sp)
    80001940:	e426                	sd	s1,8(sp)
    80001942:	e04a                	sd	s2,0(sp)
    80001944:	1000                	addi	s0,sp,32
    80001946:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001948:	ff2ff0ef          	jal	ra,8000113a <uvmcreate>
    8000194c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000194e:	cd05                	beqz	a0,80001986 <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001950:	4729                	li	a4,10
    80001952:	00004697          	auipc	a3,0x4
    80001956:	6ae68693          	addi	a3,a3,1710 # 80006000 <_trampoline>
    8000195a:	6605                	lui	a2,0x1
    8000195c:	040005b7          	lui	a1,0x4000
    80001960:	15fd                	addi	a1,a1,-1
    80001962:	05b2                	slli	a1,a1,0xc
    80001964:	e30ff0ef          	jal	ra,80000f94 <mappages>
    80001968:	02054663          	bltz	a0,80001994 <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    8000196c:	4719                	li	a4,6
    8000196e:	05893683          	ld	a3,88(s2)
    80001972:	6605                	lui	a2,0x1
    80001974:	020005b7          	lui	a1,0x2000
    80001978:	15fd                	addi	a1,a1,-1
    8000197a:	05b6                	slli	a1,a1,0xd
    8000197c:	8526                	mv	a0,s1
    8000197e:	e16ff0ef          	jal	ra,80000f94 <mappages>
    80001982:	00054f63          	bltz	a0,800019a0 <proc_pagetable+0x66>
}
    80001986:	8526                	mv	a0,s1
    80001988:	60e2                	ld	ra,24(sp)
    8000198a:	6442                	ld	s0,16(sp)
    8000198c:	64a2                	ld	s1,8(sp)
    8000198e:	6902                	ld	s2,0(sp)
    80001990:	6105                	addi	sp,sp,32
    80001992:	8082                	ret
    uvmfree(pagetable, 0);
    80001994:	4581                	li	a1,0
    80001996:	8526                	mv	a0,s1
    80001998:	981ff0ef          	jal	ra,80001318 <uvmfree>
    return 0;
    8000199c:	4481                	li	s1,0
    8000199e:	b7e5                	j	80001986 <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    800019a0:	4681                	li	a3,0
    800019a2:	4605                	li	a2,1
    800019a4:	040005b7          	lui	a1,0x4000
    800019a8:	15fd                	addi	a1,a1,-1
    800019aa:	05b2                	slli	a1,a1,0xc
    800019ac:	8526                	mv	a0,s1
    800019ae:	fb2ff0ef          	jal	ra,80001160 <uvmunmap>
    uvmfree(pagetable, 0);
    800019b2:	4581                	li	a1,0
    800019b4:	8526                	mv	a0,s1
    800019b6:	963ff0ef          	jal	ra,80001318 <uvmfree>
    return 0;
    800019ba:	4481                	li	s1,0
    800019bc:	b7e9                	j	80001986 <proc_pagetable+0x4c>

00000000800019be <proc_freepagetable>:
{
    800019be:	1101                	addi	sp,sp,-32
    800019c0:	ec06                	sd	ra,24(sp)
    800019c2:	e822                	sd	s0,16(sp)
    800019c4:	e426                	sd	s1,8(sp)
    800019c6:	e04a                	sd	s2,0(sp)
    800019c8:	1000                	addi	s0,sp,32
    800019ca:	84aa                	mv	s1,a0
    800019cc:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    800019ce:	4681                	li	a3,0
    800019d0:	4605                	li	a2,1
    800019d2:	040005b7          	lui	a1,0x4000
    800019d6:	15fd                	addi	a1,a1,-1
    800019d8:	05b2                	slli	a1,a1,0xc
    800019da:	f86ff0ef          	jal	ra,80001160 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    800019de:	4681                	li	a3,0
    800019e0:	4605                	li	a2,1
    800019e2:	020005b7          	lui	a1,0x2000
    800019e6:	15fd                	addi	a1,a1,-1
    800019e8:	05b6                	slli	a1,a1,0xd
    800019ea:	8526                	mv	a0,s1
    800019ec:	f74ff0ef          	jal	ra,80001160 <uvmunmap>
  uvmfree(pagetable, sz);
    800019f0:	85ca                	mv	a1,s2
    800019f2:	8526                	mv	a0,s1
    800019f4:	925ff0ef          	jal	ra,80001318 <uvmfree>
}
    800019f8:	60e2                	ld	ra,24(sp)
    800019fa:	6442                	ld	s0,16(sp)
    800019fc:	64a2                	ld	s1,8(sp)
    800019fe:	6902                	ld	s2,0(sp)
    80001a00:	6105                	addi	sp,sp,32
    80001a02:	8082                	ret

0000000080001a04 <freeproc>:
{
    80001a04:	1101                	addi	sp,sp,-32
    80001a06:	ec06                	sd	ra,24(sp)
    80001a08:	e822                	sd	s0,16(sp)
    80001a0a:	e426                	sd	s1,8(sp)
    80001a0c:	1000                	addi	s0,sp,32
    80001a0e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001a10:	6d28                	ld	a0,88(a0)
    80001a12:	c119                	beqz	a0,80001a18 <freeproc+0x14>
    kfree((void*)p->trapframe);
    80001a14:	fa9fe0ef          	jal	ra,800009bc <kfree>
  p->trapframe = 0;
    80001a18:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001a1c:	68a8                	ld	a0,80(s1)
    80001a1e:	c501                	beqz	a0,80001a26 <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001a20:	64ac                	ld	a1,72(s1)
    80001a22:	f9dff0ef          	jal	ra,800019be <proc_freepagetable>
  p->pagetable = 0;
    80001a26:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001a2a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001a2e:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001a32:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001a36:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001a3a:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001a3e:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001a42:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001a46:	0004ac23          	sw	zero,24(s1)
}
    80001a4a:	60e2                	ld	ra,24(sp)
    80001a4c:	6442                	ld	s0,16(sp)
    80001a4e:	64a2                	ld	s1,8(sp)
    80001a50:	6105                	addi	sp,sp,32
    80001a52:	8082                	ret

0000000080001a54 <allocproc>:
{
    80001a54:	1101                	addi	sp,sp,-32
    80001a56:	ec06                	sd	ra,24(sp)
    80001a58:	e822                	sd	s0,16(sp)
    80001a5a:	e426                	sd	s1,8(sp)
    80001a5c:	e04a                	sd	s2,0(sp)
    80001a5e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a60:	0000e497          	auipc	s1,0xe
    80001a64:	3f848493          	addi	s1,s1,1016 # 8000fe58 <proc>
    80001a68:	00014917          	auipc	s2,0x14
    80001a6c:	3f090913          	addi	s2,s2,1008 # 80015e58 <tickslock>
    acquire(&p->lock);
    80001a70:	8526                	mv	a0,s1
    80001a72:	8faff0ef          	jal	ra,80000b6c <acquire>
    if(p->state == UNUSED) {
    80001a76:	4c9c                	lw	a5,24(s1)
    80001a78:	cb91                	beqz	a5,80001a8c <allocproc+0x38>
      release(&p->lock);
    80001a7a:	8526                	mv	a0,s1
    80001a7c:	988ff0ef          	jal	ra,80000c04 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a80:	18048493          	addi	s1,s1,384
    80001a84:	ff2496e3          	bne	s1,s2,80001a70 <allocproc+0x1c>
  return 0;
    80001a88:	4481                	li	s1,0
    80001a8a:	a891                	j	80001ade <allocproc+0x8a>
  p->pid = allocpid();
    80001a8c:	e71ff0ef          	jal	ra,800018fc <allocpid>
    80001a90:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001a92:	4785                	li	a5,1
    80001a94:	cc9c                	sw	a5,24(s1)
  p->ticks = 0;
    80001a96:	1604a423          	sw	zero,360(s1)
  p->timeslice =5;
    80001a9a:	4795                	li	a5,5
    80001a9c:	16f4a623          	sw	a5,364(s1)
  p->priority = 0;         // 新进程从最高优先级开始
    80001aa0:	1604a823          	sw	zero,368(s1)
  p->ticks_in_queue = 0;
    80001aa4:	1604aa23          	sw	zero,372(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001aa8:	ff5fe0ef          	jal	ra,80000a9c <kalloc>
    80001aac:	892a                	mv	s2,a0
    80001aae:	eca8                	sd	a0,88(s1)
    80001ab0:	cd15                	beqz	a0,80001aec <allocproc+0x98>
  p->pagetable = proc_pagetable(p);
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	e87ff0ef          	jal	ra,8000193a <proc_pagetable>
    80001ab8:	892a                	mv	s2,a0
    80001aba:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001abc:	c121                	beqz	a0,80001afc <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001abe:	07000613          	li	a2,112
    80001ac2:	4581                	li	a1,0
    80001ac4:	06048513          	addi	a0,s1,96
    80001ac8:	978ff0ef          	jal	ra,80000c40 <memset>
  p->context.ra = (uint64)forkret;
    80001acc:	00000797          	auipc	a5,0x0
    80001ad0:	d9878793          	addi	a5,a5,-616 # 80001864 <forkret>
    80001ad4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ad6:	60bc                	ld	a5,64(s1)
    80001ad8:	6705                	lui	a4,0x1
    80001ada:	97ba                	add	a5,a5,a4
    80001adc:	f4bc                	sd	a5,104(s1)
}
    80001ade:	8526                	mv	a0,s1
    80001ae0:	60e2                	ld	ra,24(sp)
    80001ae2:	6442                	ld	s0,16(sp)
    80001ae4:	64a2                	ld	s1,8(sp)
    80001ae6:	6902                	ld	s2,0(sp)
    80001ae8:	6105                	addi	sp,sp,32
    80001aea:	8082                	ret
    freeproc(p);
    80001aec:	8526                	mv	a0,s1
    80001aee:	f17ff0ef          	jal	ra,80001a04 <freeproc>
    release(&p->lock);
    80001af2:	8526                	mv	a0,s1
    80001af4:	910ff0ef          	jal	ra,80000c04 <release>
    return 0;
    80001af8:	84ca                	mv	s1,s2
    80001afa:	b7d5                	j	80001ade <allocproc+0x8a>
    freeproc(p);
    80001afc:	8526                	mv	a0,s1
    80001afe:	f07ff0ef          	jal	ra,80001a04 <freeproc>
    release(&p->lock);
    80001b02:	8526                	mv	a0,s1
    80001b04:	900ff0ef          	jal	ra,80000c04 <release>
    return 0;
    80001b08:	84ca                	mv	s1,s2
    80001b0a:	bfd1                	j	80001ade <allocproc+0x8a>

0000000080001b0c <growproc>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001b1a:	d1bff0ef          	jal	ra,80001834 <myproc>
    80001b1e:	892a                	mv	s2,a0
  sz = p->sz;
    80001b20:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001b22:	02905963          	blez	s1,80001b54 <growproc+0x48>
    if(sz + n > TRAPFRAME) {
    80001b26:	00b48633          	add	a2,s1,a1
    80001b2a:	020007b7          	lui	a5,0x2000
    80001b2e:	17fd                	addi	a5,a5,-1
    80001b30:	07b6                	slli	a5,a5,0xd
    80001b32:	02c7ea63          	bltu	a5,a2,80001b66 <growproc+0x5a>
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001b36:	4691                	li	a3,4
    80001b38:	6928                	ld	a0,80(a0)
    80001b3a:	ee6ff0ef          	jal	ra,80001220 <uvmalloc>
    80001b3e:	85aa                	mv	a1,a0
    80001b40:	c50d                	beqz	a0,80001b6a <growproc+0x5e>
  p->sz = sz;
    80001b42:	04b93423          	sd	a1,72(s2)
  return 0;
    80001b46:	4501                	li	a0,0
}
    80001b48:	60e2                	ld	ra,24(sp)
    80001b4a:	6442                	ld	s0,16(sp)
    80001b4c:	64a2                	ld	s1,8(sp)
    80001b4e:	6902                	ld	s2,0(sp)
    80001b50:	6105                	addi	sp,sp,32
    80001b52:	8082                	ret
  } else if(n < 0){
    80001b54:	fe04d7e3          	bgez	s1,80001b42 <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001b58:	00b48633          	add	a2,s1,a1
    80001b5c:	6928                	ld	a0,80(a0)
    80001b5e:	e7eff0ef          	jal	ra,800011dc <uvmdealloc>
    80001b62:	85aa                	mv	a1,a0
    80001b64:	bff9                	j	80001b42 <growproc+0x36>
      return -1;
    80001b66:	557d                	li	a0,-1
    80001b68:	b7c5                	j	80001b48 <growproc+0x3c>
      return -1;
    80001b6a:	557d                	li	a0,-1
    80001b6c:	bff1                	j	80001b48 <growproc+0x3c>

0000000080001b6e <kfork>:
{
    80001b6e:	7139                	addi	sp,sp,-64
    80001b70:	fc06                	sd	ra,56(sp)
    80001b72:	f822                	sd	s0,48(sp)
    80001b74:	f426                	sd	s1,40(sp)
    80001b76:	f04a                	sd	s2,32(sp)
    80001b78:	ec4e                	sd	s3,24(sp)
    80001b7a:	e852                	sd	s4,16(sp)
    80001b7c:	e456                	sd	s5,8(sp)
    80001b7e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001b80:	cb5ff0ef          	jal	ra,80001834 <myproc>
    80001b84:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001b86:	ecfff0ef          	jal	ra,80001a54 <allocproc>
    80001b8a:	0e050663          	beqz	a0,80001c76 <kfork+0x108>
    80001b8e:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001b90:	048ab603          	ld	a2,72(s5)
    80001b94:	692c                	ld	a1,80(a0)
    80001b96:	050ab503          	ld	a0,80(s5)
    80001b9a:	faeff0ef          	jal	ra,80001348 <uvmcopy>
    80001b9e:	04054863          	bltz	a0,80001bee <kfork+0x80>
  np->sz = p->sz;
    80001ba2:	048ab783          	ld	a5,72(s5)
    80001ba6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001baa:	058ab683          	ld	a3,88(s5)
    80001bae:	87b6                	mv	a5,a3
    80001bb0:	058a3703          	ld	a4,88(s4)
    80001bb4:	12068693          	addi	a3,a3,288
    80001bb8:	0007b803          	ld	a6,0(a5) # 2000000 <_entry-0x7e000000>
    80001bbc:	6788                	ld	a0,8(a5)
    80001bbe:	6b8c                	ld	a1,16(a5)
    80001bc0:	6f90                	ld	a2,24(a5)
    80001bc2:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001bc6:	e708                	sd	a0,8(a4)
    80001bc8:	eb0c                	sd	a1,16(a4)
    80001bca:	ef10                	sd	a2,24(a4)
    80001bcc:	02078793          	addi	a5,a5,32
    80001bd0:	02070713          	addi	a4,a4,32
    80001bd4:	fed792e3          	bne	a5,a3,80001bb8 <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001bd8:	058a3783          	ld	a5,88(s4)
    80001bdc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001be0:	0d0a8493          	addi	s1,s5,208
    80001be4:	0d0a0913          	addi	s2,s4,208
    80001be8:	150a8993          	addi	s3,s5,336
    80001bec:	a829                	j	80001c06 <kfork+0x98>
    freeproc(np);
    80001bee:	8552                	mv	a0,s4
    80001bf0:	e15ff0ef          	jal	ra,80001a04 <freeproc>
    release(&np->lock);
    80001bf4:	8552                	mv	a0,s4
    80001bf6:	80eff0ef          	jal	ra,80000c04 <release>
    return -1;
    80001bfa:	597d                	li	s2,-1
    80001bfc:	a09d                	j	80001c62 <kfork+0xf4>
  for(i = 0; i < NOFILE; i++)
    80001bfe:	04a1                	addi	s1,s1,8
    80001c00:	0921                	addi	s2,s2,8
    80001c02:	01348963          	beq	s1,s3,80001c14 <kfork+0xa6>
    if(p->ofile[i])
    80001c06:	6088                	ld	a0,0(s1)
    80001c08:	d97d                	beqz	a0,80001bfe <kfork+0x90>
      np->ofile[i] = filedup(p->ofile[i]);
    80001c0a:	54c020ef          	jal	ra,80004156 <filedup>
    80001c0e:	00a93023          	sd	a0,0(s2)
    80001c12:	b7f5                	j	80001bfe <kfork+0x90>
  np->cwd = idup(p->cwd);
    80001c14:	150ab503          	ld	a0,336(s5)
    80001c18:	762010ef          	jal	ra,8000337a <idup>
    80001c1c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001c20:	4641                	li	a2,16
    80001c22:	158a8593          	addi	a1,s5,344
    80001c26:	158a0513          	addi	a0,s4,344
    80001c2a:	95cff0ef          	jal	ra,80000d86 <safestrcpy>
  pid = np->pid;
    80001c2e:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001c32:	8552                	mv	a0,s4
    80001c34:	fd1fe0ef          	jal	ra,80000c04 <release>
  acquire(&wait_lock);
    80001c38:	0000e497          	auipc	s1,0xe
    80001c3c:	e0848493          	addi	s1,s1,-504 # 8000fa40 <wait_lock>
    80001c40:	8526                	mv	a0,s1
    80001c42:	f2bfe0ef          	jal	ra,80000b6c <acquire>
  np->parent = p;
    80001c46:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	fb9fe0ef          	jal	ra,80000c04 <release>
  acquire(&np->lock);
    80001c50:	8552                	mv	a0,s4
    80001c52:	f1bfe0ef          	jal	ra,80000b6c <acquire>
  np->state = RUNNABLE;
    80001c56:	478d                	li	a5,3
    80001c58:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001c5c:	8552                	mv	a0,s4
    80001c5e:	fa7fe0ef          	jal	ra,80000c04 <release>
}
    80001c62:	854a                	mv	a0,s2
    80001c64:	70e2                	ld	ra,56(sp)
    80001c66:	7442                	ld	s0,48(sp)
    80001c68:	74a2                	ld	s1,40(sp)
    80001c6a:	7902                	ld	s2,32(sp)
    80001c6c:	69e2                	ld	s3,24(sp)
    80001c6e:	6a42                	ld	s4,16(sp)
    80001c70:	6aa2                	ld	s5,8(sp)
    80001c72:	6121                	addi	sp,sp,64
    80001c74:	8082                	ret
    return -1;
    80001c76:	597d                	li	s2,-1
    80001c78:	b7ed                	j	80001c62 <kfork+0xf4>

0000000080001c7a <sched>:
{
    80001c7a:	7179                	addi	sp,sp,-48
    80001c7c:	f406                	sd	ra,40(sp)
    80001c7e:	f022                	sd	s0,32(sp)
    80001c80:	ec26                	sd	s1,24(sp)
    80001c82:	e84a                	sd	s2,16(sp)
    80001c84:	e44e                	sd	s3,8(sp)
    80001c86:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001c88:	badff0ef          	jal	ra,80001834 <myproc>
    80001c8c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001c8e:	e75fe0ef          	jal	ra,80000b02 <holding>
    80001c92:	c92d                	beqz	a0,80001d04 <sched+0x8a>
    80001c94:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001c96:	2781                	sext.w	a5,a5
    80001c98:	079e                	slli	a5,a5,0x7
    80001c9a:	0000e717          	auipc	a4,0xe
    80001c9e:	cee70713          	addi	a4,a4,-786 # 8000f988 <run_queues>
    80001ca2:	97ba                	add	a5,a5,a4
    80001ca4:	1487a703          	lw	a4,328(a5)
    80001ca8:	4785                	li	a5,1
    80001caa:	06f71363          	bne	a4,a5,80001d10 <sched+0x96>
  if(p->state == RUNNING)
    80001cae:	4c98                	lw	a4,24(s1)
    80001cb0:	4791                	li	a5,4
    80001cb2:	06f70563          	beq	a4,a5,80001d1c <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001cb6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001cba:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001cbc:	e7b5                	bnez	a5,80001d28 <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001cbe:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001cc0:	0000e917          	auipc	s2,0xe
    80001cc4:	cc890913          	addi	s2,s2,-824 # 8000f988 <run_queues>
    80001cc8:	2781                	sext.w	a5,a5
    80001cca:	079e                	slli	a5,a5,0x7
    80001ccc:	97ca                	add	a5,a5,s2
    80001cce:	14c7a983          	lw	s3,332(a5)
    80001cd2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001cd4:	2781                	sext.w	a5,a5
    80001cd6:	079e                	slli	a5,a5,0x7
    80001cd8:	0000e597          	auipc	a1,0xe
    80001cdc:	d8858593          	addi	a1,a1,-632 # 8000fa60 <cpus+0x8>
    80001ce0:	95be                	add	a1,a1,a5
    80001ce2:	06048513          	addi	a0,s1,96
    80001ce6:	7c0000ef          	jal	ra,800024a6 <swtch>
    80001cea:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001cec:	2781                	sext.w	a5,a5
    80001cee:	079e                	slli	a5,a5,0x7
    80001cf0:	97ca                	add	a5,a5,s2
    80001cf2:	1537a623          	sw	s3,332(a5)
}
    80001cf6:	70a2                	ld	ra,40(sp)
    80001cf8:	7402                	ld	s0,32(sp)
    80001cfa:	64e2                	ld	s1,24(sp)
    80001cfc:	6942                	ld	s2,16(sp)
    80001cfe:	69a2                	ld	s3,8(sp)
    80001d00:	6145                	addi	sp,sp,48
    80001d02:	8082                	ret
    panic("sched p->lock");
    80001d04:	00005517          	auipc	a0,0x5
    80001d08:	4b450513          	addi	a0,a0,1204 # 800071b8 <digits+0x180>
    80001d0c:	a7ffe0ef          	jal	ra,8000078a <panic>
    panic("sched locks");
    80001d10:	00005517          	auipc	a0,0x5
    80001d14:	4b850513          	addi	a0,a0,1208 # 800071c8 <digits+0x190>
    80001d18:	a73fe0ef          	jal	ra,8000078a <panic>
    panic("sched RUNNING");
    80001d1c:	00005517          	auipc	a0,0x5
    80001d20:	4bc50513          	addi	a0,a0,1212 # 800071d8 <digits+0x1a0>
    80001d24:	a67fe0ef          	jal	ra,8000078a <panic>
    panic("sched interruptible");
    80001d28:	00005517          	auipc	a0,0x5
    80001d2c:	4c050513          	addi	a0,a0,1216 # 800071e8 <digits+0x1b0>
    80001d30:	a5bfe0ef          	jal	ra,8000078a <panic>

0000000080001d34 <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001d34:	7179                	addi	sp,sp,-48
    80001d36:	f406                	sd	ra,40(sp)
    80001d38:	f022                	sd	s0,32(sp)
    80001d3a:	ec26                	sd	s1,24(sp)
    80001d3c:	e84a                	sd	s2,16(sp)
    80001d3e:	e44e                	sd	s3,8(sp)
    80001d40:	1800                	addi	s0,sp,48
    80001d42:	89aa                	mv	s3,a0
    80001d44:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001d46:	aefff0ef          	jal	ra,80001834 <myproc>
    80001d4a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001d4c:	e21fe0ef          	jal	ra,80000b6c <acquire>
  release(lk);
    80001d50:	854a                	mv	a0,s2
    80001d52:	eb3fe0ef          	jal	ra,80000c04 <release>

  // Go to sleep.
  p->chan = chan;
    80001d56:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001d5a:	4789                	li	a5,2
    80001d5c:	cc9c                	sw	a5,24(s1)

  p->ticks_in_queue = 0;
    80001d5e:	1604aa23          	sw	zero,372(s1)
  sched();
    80001d62:	f19ff0ef          	jal	ra,80001c7a <sched>

  // Tidy up.
  p->chan = 0;
    80001d66:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001d6a:	8526                	mv	a0,s1
    80001d6c:	e99fe0ef          	jal	ra,80000c04 <release>
  acquire(lk);
    80001d70:	854a                	mv	a0,s2
    80001d72:	dfbfe0ef          	jal	ra,80000b6c <acquire>
}
    80001d76:	70a2                	ld	ra,40(sp)
    80001d78:	7402                	ld	s0,32(sp)
    80001d7a:	64e2                	ld	s1,24(sp)
    80001d7c:	6942                	ld	s2,16(sp)
    80001d7e:	69a2                	ld	s3,8(sp)
    80001d80:	6145                	addi	sp,sp,48
    80001d82:	8082                	ret

0000000080001d84 <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    80001d84:	7179                	addi	sp,sp,-48
    80001d86:	f406                	sd	ra,40(sp)
    80001d88:	f022                	sd	s0,32(sp)
    80001d8a:	ec26                	sd	s1,24(sp)
    80001d8c:	e84a                	sd	s2,16(sp)
    80001d8e:	e44e                	sd	s3,8(sp)
    80001d90:	1800                	addi	s0,sp,48
    80001d92:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80001d94:	0000e497          	auipc	s1,0xe
    80001d98:	0c448493          	addi	s1,s1,196 # 8000fe58 <proc>
    80001d9c:	00014997          	auipc	s3,0x14
    80001da0:	0bc98993          	addi	s3,s3,188 # 80015e58 <tickslock>
    acquire(&p->lock);
    80001da4:	8526                	mv	a0,s1
    80001da6:	dc7fe0ef          	jal	ra,80000b6c <acquire>
    if(p->pid == pid){
    80001daa:	589c                	lw	a5,48(s1)
    80001dac:	01278b63          	beq	a5,s2,80001dc2 <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80001db0:	8526                	mv	a0,s1
    80001db2:	e53fe0ef          	jal	ra,80000c04 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80001db6:	18048493          	addi	s1,s1,384
    80001dba:	ff3495e3          	bne	s1,s3,80001da4 <kkill+0x20>
  }
  return -1;
    80001dbe:	557d                	li	a0,-1
    80001dc0:	a819                	j	80001dd6 <kkill+0x52>
      p->killed = 1;
    80001dc2:	4785                	li	a5,1
    80001dc4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80001dc6:	4c98                	lw	a4,24(s1)
    80001dc8:	4789                	li	a5,2
    80001dca:	00f70d63          	beq	a4,a5,80001de4 <kkill+0x60>
      release(&p->lock);
    80001dce:	8526                	mv	a0,s1
    80001dd0:	e35fe0ef          	jal	ra,80000c04 <release>
      return 0;
    80001dd4:	4501                	li	a0,0
}
    80001dd6:	70a2                	ld	ra,40(sp)
    80001dd8:	7402                	ld	s0,32(sp)
    80001dda:	64e2                	ld	s1,24(sp)
    80001ddc:	6942                	ld	s2,16(sp)
    80001dde:	69a2                	ld	s3,8(sp)
    80001de0:	6145                	addi	sp,sp,48
    80001de2:	8082                	ret
        p->state = RUNNABLE;
    80001de4:	478d                	li	a5,3
    80001de6:	cc9c                	sw	a5,24(s1)
    80001de8:	b7dd                	j	80001dce <kkill+0x4a>

0000000080001dea <setkilled>:

void
setkilled(struct proc *p)
{
    80001dea:	1101                	addi	sp,sp,-32
    80001dec:	ec06                	sd	ra,24(sp)
    80001dee:	e822                	sd	s0,16(sp)
    80001df0:	e426                	sd	s1,8(sp)
    80001df2:	1000                	addi	s0,sp,32
    80001df4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001df6:	d77fe0ef          	jal	ra,80000b6c <acquire>
  p->killed = 1;
    80001dfa:	4785                	li	a5,1
    80001dfc:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80001dfe:	8526                	mv	a0,s1
    80001e00:	e05fe0ef          	jal	ra,80000c04 <release>
}
    80001e04:	60e2                	ld	ra,24(sp)
    80001e06:	6442                	ld	s0,16(sp)
    80001e08:	64a2                	ld	s1,8(sp)
    80001e0a:	6105                	addi	sp,sp,32
    80001e0c:	8082                	ret

0000000080001e0e <killed>:

int
killed(struct proc *p)
{
    80001e0e:	1101                	addi	sp,sp,-32
    80001e10:	ec06                	sd	ra,24(sp)
    80001e12:	e822                	sd	s0,16(sp)
    80001e14:	e426                	sd	s1,8(sp)
    80001e16:	e04a                	sd	s2,0(sp)
    80001e18:	1000                	addi	s0,sp,32
    80001e1a:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80001e1c:	d51fe0ef          	jal	ra,80000b6c <acquire>
  k = p->killed;
    80001e20:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80001e24:	8526                	mv	a0,s1
    80001e26:	ddffe0ef          	jal	ra,80000c04 <release>
  return k;
}
    80001e2a:	854a                	mv	a0,s2
    80001e2c:	60e2                	ld	ra,24(sp)
    80001e2e:	6442                	ld	s0,16(sp)
    80001e30:	64a2                	ld	s1,8(sp)
    80001e32:	6902                	ld	s2,0(sp)
    80001e34:	6105                	addi	sp,sp,32
    80001e36:	8082                	ret

0000000080001e38 <kwait>:
{
    80001e38:	715d                	addi	sp,sp,-80
    80001e3a:	e486                	sd	ra,72(sp)
    80001e3c:	e0a2                	sd	s0,64(sp)
    80001e3e:	fc26                	sd	s1,56(sp)
    80001e40:	f84a                	sd	s2,48(sp)
    80001e42:	f44e                	sd	s3,40(sp)
    80001e44:	f052                	sd	s4,32(sp)
    80001e46:	ec56                	sd	s5,24(sp)
    80001e48:	e85a                	sd	s6,16(sp)
    80001e4a:	e45e                	sd	s7,8(sp)
    80001e4c:	e062                	sd	s8,0(sp)
    80001e4e:	0880                	addi	s0,sp,80
    80001e50:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80001e52:	9e3ff0ef          	jal	ra,80001834 <myproc>
    80001e56:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80001e58:	0000e517          	auipc	a0,0xe
    80001e5c:	be850513          	addi	a0,a0,-1048 # 8000fa40 <wait_lock>
    80001e60:	d0dfe0ef          	jal	ra,80000b6c <acquire>
    havekids = 0;
    80001e64:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80001e66:	4a15                	li	s4,5
        havekids = 1;
    80001e68:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80001e6a:	00014997          	auipc	s3,0x14
    80001e6e:	fee98993          	addi	s3,s3,-18 # 80015e58 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80001e72:	0000ec17          	auipc	s8,0xe
    80001e76:	bcec0c13          	addi	s8,s8,-1074 # 8000fa40 <wait_lock>
    havekids = 0;
    80001e7a:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80001e7c:	0000e497          	auipc	s1,0xe
    80001e80:	fdc48493          	addi	s1,s1,-36 # 8000fe58 <proc>
    80001e84:	a899                	j	80001eda <kwait+0xa2>
          pid = pp->pid;
    80001e86:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80001e8a:	000b0c63          	beqz	s6,80001ea2 <kwait+0x6a>
    80001e8e:	4691                	li	a3,4
    80001e90:	02c48613          	addi	a2,s1,44
    80001e94:	85da                	mv	a1,s6
    80001e96:	05093503          	ld	a0,80(s2)
    80001e9a:	eb8ff0ef          	jal	ra,80001552 <copyout>
    80001e9e:	00054f63          	bltz	a0,80001ebc <kwait+0x84>
          freeproc(pp);
    80001ea2:	8526                	mv	a0,s1
    80001ea4:	b61ff0ef          	jal	ra,80001a04 <freeproc>
          release(&pp->lock);
    80001ea8:	8526                	mv	a0,s1
    80001eaa:	d5bfe0ef          	jal	ra,80000c04 <release>
          release(&wait_lock);
    80001eae:	0000e517          	auipc	a0,0xe
    80001eb2:	b9250513          	addi	a0,a0,-1134 # 8000fa40 <wait_lock>
    80001eb6:	d4ffe0ef          	jal	ra,80000c04 <release>
          return pid;
    80001eba:	a891                	j	80001f0e <kwait+0xd6>
            release(&pp->lock);
    80001ebc:	8526                	mv	a0,s1
    80001ebe:	d47fe0ef          	jal	ra,80000c04 <release>
            release(&wait_lock);
    80001ec2:	0000e517          	auipc	a0,0xe
    80001ec6:	b7e50513          	addi	a0,a0,-1154 # 8000fa40 <wait_lock>
    80001eca:	d3bfe0ef          	jal	ra,80000c04 <release>
            return -1;
    80001ece:	59fd                	li	s3,-1
    80001ed0:	a83d                	j	80001f0e <kwait+0xd6>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ed2:	18048493          	addi	s1,s1,384
    80001ed6:	03348063          	beq	s1,s3,80001ef6 <kwait+0xbe>
      if(pp->parent == p){
    80001eda:	7c9c                	ld	a5,56(s1)
    80001edc:	ff279be3          	bne	a5,s2,80001ed2 <kwait+0x9a>
        acquire(&pp->lock);
    80001ee0:	8526                	mv	a0,s1
    80001ee2:	c8bfe0ef          	jal	ra,80000b6c <acquire>
        if(pp->state == ZOMBIE){
    80001ee6:	4c9c                	lw	a5,24(s1)
    80001ee8:	f9478fe3          	beq	a5,s4,80001e86 <kwait+0x4e>
        release(&pp->lock);
    80001eec:	8526                	mv	a0,s1
    80001eee:	d17fe0ef          	jal	ra,80000c04 <release>
        havekids = 1;
    80001ef2:	8756                	mv	a4,s5
    80001ef4:	bff9                	j	80001ed2 <kwait+0x9a>
    if(!havekids || killed(p)){
    80001ef6:	c709                	beqz	a4,80001f00 <kwait+0xc8>
    80001ef8:	854a                	mv	a0,s2
    80001efa:	f15ff0ef          	jal	ra,80001e0e <killed>
    80001efe:	c50d                	beqz	a0,80001f28 <kwait+0xf0>
      release(&wait_lock);
    80001f00:	0000e517          	auipc	a0,0xe
    80001f04:	b4050513          	addi	a0,a0,-1216 # 8000fa40 <wait_lock>
    80001f08:	cfdfe0ef          	jal	ra,80000c04 <release>
      return -1;
    80001f0c:	59fd                	li	s3,-1
}
    80001f0e:	854e                	mv	a0,s3
    80001f10:	60a6                	ld	ra,72(sp)
    80001f12:	6406                	ld	s0,64(sp)
    80001f14:	74e2                	ld	s1,56(sp)
    80001f16:	7942                	ld	s2,48(sp)
    80001f18:	79a2                	ld	s3,40(sp)
    80001f1a:	7a02                	ld	s4,32(sp)
    80001f1c:	6ae2                	ld	s5,24(sp)
    80001f1e:	6b42                	ld	s6,16(sp)
    80001f20:	6ba2                	ld	s7,8(sp)
    80001f22:	6c02                	ld	s8,0(sp)
    80001f24:	6161                	addi	sp,sp,80
    80001f26:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80001f28:	85e2                	mv	a1,s8
    80001f2a:	854a                	mv	a0,s2
    80001f2c:	e09ff0ef          	jal	ra,80001d34 <sleep>
    havekids = 0;
    80001f30:	b7a9                	j	80001e7a <kwait+0x42>

0000000080001f32 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80001f32:	7179                	addi	sp,sp,-48
    80001f34:	f406                	sd	ra,40(sp)
    80001f36:	f022                	sd	s0,32(sp)
    80001f38:	ec26                	sd	s1,24(sp)
    80001f3a:	e84a                	sd	s2,16(sp)
    80001f3c:	e44e                	sd	s3,8(sp)
    80001f3e:	e052                	sd	s4,0(sp)
    80001f40:	1800                	addi	s0,sp,48
    80001f42:	84aa                	mv	s1,a0
    80001f44:	892e                	mv	s2,a1
    80001f46:	89b2                	mv	s3,a2
    80001f48:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80001f4a:	8ebff0ef          	jal	ra,80001834 <myproc>
  if(user_dst){
    80001f4e:	cc99                	beqz	s1,80001f6c <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    80001f50:	86d2                	mv	a3,s4
    80001f52:	864e                	mv	a2,s3
    80001f54:	85ca                	mv	a1,s2
    80001f56:	6928                	ld	a0,80(a0)
    80001f58:	dfaff0ef          	jal	ra,80001552 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80001f5c:	70a2                	ld	ra,40(sp)
    80001f5e:	7402                	ld	s0,32(sp)
    80001f60:	64e2                	ld	s1,24(sp)
    80001f62:	6942                	ld	s2,16(sp)
    80001f64:	69a2                	ld	s3,8(sp)
    80001f66:	6a02                	ld	s4,0(sp)
    80001f68:	6145                	addi	sp,sp,48
    80001f6a:	8082                	ret
    memmove((char *)dst, src, len);
    80001f6c:	000a061b          	sext.w	a2,s4
    80001f70:	85ce                	mv	a1,s3
    80001f72:	854a                	mv	a0,s2
    80001f74:	d29fe0ef          	jal	ra,80000c9c <memmove>
    return 0;
    80001f78:	8526                	mv	a0,s1
    80001f7a:	b7cd                	j	80001f5c <either_copyout+0x2a>

0000000080001f7c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80001f7c:	7179                	addi	sp,sp,-48
    80001f7e:	f406                	sd	ra,40(sp)
    80001f80:	f022                	sd	s0,32(sp)
    80001f82:	ec26                	sd	s1,24(sp)
    80001f84:	e84a                	sd	s2,16(sp)
    80001f86:	e44e                	sd	s3,8(sp)
    80001f88:	e052                	sd	s4,0(sp)
    80001f8a:	1800                	addi	s0,sp,48
    80001f8c:	892a                	mv	s2,a0
    80001f8e:	84ae                	mv	s1,a1
    80001f90:	89b2                	mv	s3,a2
    80001f92:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80001f94:	8a1ff0ef          	jal	ra,80001834 <myproc>
  if(user_src){
    80001f98:	cc99                	beqz	s1,80001fb6 <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    80001f9a:	86d2                	mv	a3,s4
    80001f9c:	864e                	mv	a2,s3
    80001f9e:	85ca                	mv	a1,s2
    80001fa0:	6928                	ld	a0,80(a0)
    80001fa2:	e76ff0ef          	jal	ra,80001618 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80001fa6:	70a2                	ld	ra,40(sp)
    80001fa8:	7402                	ld	s0,32(sp)
    80001faa:	64e2                	ld	s1,24(sp)
    80001fac:	6942                	ld	s2,16(sp)
    80001fae:	69a2                	ld	s3,8(sp)
    80001fb0:	6a02                	ld	s4,0(sp)
    80001fb2:	6145                	addi	sp,sp,48
    80001fb4:	8082                	ret
    memmove(dst, (char*)src, len);
    80001fb6:	000a061b          	sext.w	a2,s4
    80001fba:	85ce                	mv	a1,s3
    80001fbc:	854a                	mv	a0,s2
    80001fbe:	cdffe0ef          	jal	ra,80000c9c <memmove>
    return 0;
    80001fc2:	8526                	mv	a0,s1
    80001fc4:	b7cd                	j	80001fa6 <either_copyin+0x2a>

0000000080001fc6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80001fc6:	715d                	addi	sp,sp,-80
    80001fc8:	e486                	sd	ra,72(sp)
    80001fca:	e0a2                	sd	s0,64(sp)
    80001fcc:	fc26                	sd	s1,56(sp)
    80001fce:	f84a                	sd	s2,48(sp)
    80001fd0:	f44e                	sd	s3,40(sp)
    80001fd2:	f052                	sd	s4,32(sp)
    80001fd4:	ec56                	sd	s5,24(sp)
    80001fd6:	e85a                	sd	s6,16(sp)
    80001fd8:	e45e                	sd	s7,8(sp)
    80001fda:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80001fdc:	00005517          	auipc	a0,0x5
    80001fe0:	0e450513          	addi	a0,a0,228 # 800070c0 <digits+0x88>
    80001fe4:	ce0fe0ef          	jal	ra,800004c4 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80001fe8:	0000e497          	auipc	s1,0xe
    80001fec:	fc848493          	addi	s1,s1,-56 # 8000ffb0 <proc+0x158>
    80001ff0:	00014917          	auipc	s2,0x14
    80001ff4:	fc090913          	addi	s2,s2,-64 # 80015fb0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001ff8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80001ffa:	00005997          	auipc	s3,0x5
    80001ffe:	20698993          	addi	s3,s3,518 # 80007200 <digits+0x1c8>
    printf("%d %s %s", p->pid, state, p->name);
    80002002:	00005a97          	auipc	s5,0x5
    80002006:	206a8a93          	addi	s5,s5,518 # 80007208 <digits+0x1d0>
    printf("\n");
    8000200a:	00005a17          	auipc	s4,0x5
    8000200e:	0b6a0a13          	addi	s4,s4,182 # 800070c0 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002012:	00005b97          	auipc	s7,0x5
    80002016:	25eb8b93          	addi	s7,s7,606 # 80007270 <states.0>
    8000201a:	a829                	j	80002034 <procdump+0x6e>
    printf("%d %s %s", p->pid, state, p->name);
    8000201c:	ed86a583          	lw	a1,-296(a3)
    80002020:	8556                	mv	a0,s5
    80002022:	ca2fe0ef          	jal	ra,800004c4 <printf>
    printf("\n");
    80002026:	8552                	mv	a0,s4
    80002028:	c9cfe0ef          	jal	ra,800004c4 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000202c:	18048493          	addi	s1,s1,384
    80002030:	03248163          	beq	s1,s2,80002052 <procdump+0x8c>
    if(p->state == UNUSED)
    80002034:	86a6                	mv	a3,s1
    80002036:	ec04a783          	lw	a5,-320(s1)
    8000203a:	dbed                	beqz	a5,8000202c <procdump+0x66>
      state = "???";
    8000203c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000203e:	fcfb6fe3          	bltu	s6,a5,8000201c <procdump+0x56>
    80002042:	1782                	slli	a5,a5,0x20
    80002044:	9381                	srli	a5,a5,0x20
    80002046:	078e                	slli	a5,a5,0x3
    80002048:	97de                	add	a5,a5,s7
    8000204a:	6390                	ld	a2,0(a5)
    8000204c:	fa61                	bnez	a2,8000201c <procdump+0x56>
      state = "???";
    8000204e:	864e                	mv	a2,s3
    80002050:	b7f1                	j	8000201c <procdump+0x56>
  }
}
    80002052:	60a6                	ld	ra,72(sp)
    80002054:	6406                	ld	s0,64(sp)
    80002056:	74e2                	ld	s1,56(sp)
    80002058:	7942                	ld	s2,48(sp)
    8000205a:	79a2                	ld	s3,40(sp)
    8000205c:	7a02                	ld	s4,32(sp)
    8000205e:	6ae2                	ld	s5,24(sp)
    80002060:	6b42                	ld	s6,16(sp)
    80002062:	6ba2                	ld	s7,8(sp)
    80002064:	6161                	addi	sp,sp,80
    80002066:	8082                	ret

0000000080002068 <sys_dump_proc>:

int
sys_dump_proc(void)
{
    80002068:	711d                	addi	sp,sp,-96
    8000206a:	ec86                	sd	ra,88(sp)
    8000206c:	e8a2                	sd	s0,80(sp)
    8000206e:	e4a6                	sd	s1,72(sp)
    80002070:	e0ca                	sd	s2,64(sp)
    80002072:	fc4e                	sd	s3,56(sp)
    80002074:	1080                	addi	s0,sp,96
    uint64 addr;
    // 获取用户传入的指针地址（第0个参数）
    argaddr(0, &addr);  // 注意：argaddr 是 void，不返回错误
    80002076:	fc840593          	addi	a1,s0,-56
    8000207a:	4501                	li	a0,0
    8000207c:	169000ef          	jal	ra,800029e4 <argaddr>

    if (addr == 0)
    80002080:	fc843783          	ld	a5,-56(s0)
    80002084:	cfad                	beqz	a5,800020fe <sys_dump_proc+0x96>
    80002086:	0000e497          	auipc	s1,0xe
    8000208a:	dd248493          	addi	s1,s1,-558 # 8000fe58 <proc>
    8000208e:	00014997          	auipc	s3,0x14
    80002092:	dca98993          	addi	s3,s3,-566 # 80015e58 <tickslock>
    80002096:	4901                	li	s2,0
        return -1;  // 无效地址

    for (int i = 0; i < NPROC; i++) {
        struct proc *p = &proc[i];  // ← 现在在 proc.c 中，proc[] 可见！
        acquire(&p->lock);
    80002098:	8526                	mv	a0,s1
    8000209a:	ad3fe0ef          	jal	ra,80000b6c <acquire>
        struct pstat ps;
        ps.inuse = (p->state != UNUSED);
    8000209e:	4c9c                	lw	a5,24(s1)
    800020a0:	00f03733          	snez	a4,a5
    800020a4:	fae42423          	sw	a4,-88(s0)
        ps.pid = p->pid;
    800020a8:	5898                	lw	a4,48(s1)
    800020aa:	fae42623          	sw	a4,-84(s0)
        ps.state = p->state;
    800020ae:	fcf42023          	sw	a5,-64(s0)
        safestrcpy(ps.name, p->name, sizeof(ps.name));
    800020b2:	4641                	li	a2,16
    800020b4:	15848593          	addi	a1,s1,344
    800020b8:	fb040513          	addi	a0,s0,-80
    800020bc:	ccbfe0ef          	jal	ra,80000d86 <safestrcpy>
        release(&p->lock);
    800020c0:	8526                	mv	a0,s1
    800020c2:	b43fe0ef          	jal	ra,80000c04 <release>

        // 安全拷贝到用户空间
        if (copyout(myproc()->pagetable, addr + i * sizeof(ps), (char*)&ps, sizeof(ps)) < 0) {
    800020c6:	f6eff0ef          	jal	ra,80001834 <myproc>
    800020ca:	46f1                	li	a3,28
    800020cc:	fa840613          	addi	a2,s0,-88
    800020d0:	fc843583          	ld	a1,-56(s0)
    800020d4:	95ca                	add	a1,a1,s2
    800020d6:	6928                	ld	a0,80(a0)
    800020d8:	c7aff0ef          	jal	ra,80001552 <copyout>
    800020dc:	00054963          	bltz	a0,800020ee <sys_dump_proc+0x86>
    for (int i = 0; i < NPROC; i++) {
    800020e0:	18048493          	addi	s1,s1,384
    800020e4:	0971                	addi	s2,s2,28
    800020e6:	fb3499e3          	bne	s1,s3,80002098 <sys_dump_proc+0x30>
            return -1;
        }
    }
    return 0;
    800020ea:	4501                	li	a0,0
    800020ec:	a011                	j	800020f0 <sys_dump_proc+0x88>
            return -1;
    800020ee:	557d                	li	a0,-1
}
    800020f0:	60e6                	ld	ra,88(sp)
    800020f2:	6446                	ld	s0,80(sp)
    800020f4:	64a6                	ld	s1,72(sp)
    800020f6:	6906                	ld	s2,64(sp)
    800020f8:	79e2                	ld	s3,56(sp)
    800020fa:	6125                	addi	sp,sp,96
    800020fc:	8082                	ret
        return -1;  // 无效地址
    800020fe:	557d                	li	a0,-1
    80002100:	bfc5                	j	800020f0 <sys_dump_proc+0x88>

0000000080002102 <enqueue>:


// 将进程 p 加入其当前 priority 对应的 runnable 队列
void
enqueue(struct proc *p)
{
    80002102:	7179                	addi	sp,sp,-48
    80002104:	f406                	sd	ra,40(sp)
    80002106:	f022                	sd	s0,32(sp)
    80002108:	ec26                	sd	s1,24(sp)
    8000210a:	e84a                	sd	s2,16(sp)
    8000210c:	e44e                	sd	s3,8(sp)
    8000210e:	1800                	addi	s0,sp,48
    80002110:	84aa                	mv	s1,a0
  int prio = p->priority;
    80002112:	17052983          	lw	s3,368(a0)
  acquire(&run_queues[prio].lock);
    80002116:	00299913          	slli	s2,s3,0x2
    8000211a:	994e                	add	s2,s2,s3
    8000211c:	00391793          	slli	a5,s2,0x3
    80002120:	0000e917          	auipc	s2,0xe
    80002124:	86890913          	addi	s2,s2,-1944 # 8000f988 <run_queues>
    80002128:	993e                	add	s2,s2,a5
    8000212a:	854a                	mv	a0,s2
    8000212c:	a41fe0ef          	jal	ra,80000b6c <acquire>
  p->next = 0;
    80002130:	1604bc23          	sd	zero,376(s1)
  if (run_queues[prio].tail == 0) {
    80002134:	02093783          	ld	a5,32(s2)
    80002138:	c79d                	beqz	a5,80002166 <enqueue+0x64>
    run_queues[prio].head = p;
  } else {
    run_queues[prio].tail->next = p;
    8000213a:	1697bc23          	sd	s1,376(a5)
  }
  run_queues[prio].tail = p;
    8000213e:	00299793          	slli	a5,s3,0x2
    80002142:	97ce                	add	a5,a5,s3
    80002144:	078e                	slli	a5,a5,0x3
    80002146:	0000e717          	auipc	a4,0xe
    8000214a:	84270713          	addi	a4,a4,-1982 # 8000f988 <run_queues>
    8000214e:	97ba                	add	a5,a5,a4
    80002150:	f384                	sd	s1,32(a5)
  release(&run_queues[prio].lock);
    80002152:	854a                	mv	a0,s2
    80002154:	ab1fe0ef          	jal	ra,80000c04 <release>
}
    80002158:	70a2                	ld	ra,40(sp)
    8000215a:	7402                	ld	s0,32(sp)
    8000215c:	64e2                	ld	s1,24(sp)
    8000215e:	6942                	ld	s2,16(sp)
    80002160:	69a2                	ld	s3,8(sp)
    80002162:	6145                	addi	sp,sp,48
    80002164:	8082                	ret
    run_queues[prio].head = p;
    80002166:	00993c23          	sd	s1,24(s2)
    8000216a:	bfd1                	j	8000213e <enqueue+0x3c>

000000008000216c <userinit>:
{
    8000216c:	1101                	addi	sp,sp,-32
    8000216e:	ec06                	sd	ra,24(sp)
    80002170:	e822                	sd	s0,16(sp)
    80002172:	e426                	sd	s1,8(sp)
    80002174:	1000                	addi	s0,sp,32
  p = allocproc();
    80002176:	8dfff0ef          	jal	ra,80001a54 <allocproc>
    8000217a:	84aa                	mv	s1,a0
  initproc = p;
    8000217c:	00005797          	auipc	a5,0x5
    80002180:	6ea7be23          	sd	a0,1788(a5) # 80007878 <initproc>
  p->cwd = namei("/");
    80002184:	00005517          	auipc	a0,0x5
    80002188:	09450513          	addi	a0,a0,148 # 80007218 <digits+0x1e0>
    8000218c:	213010ef          	jal	ra,80003b9e <namei>
    80002190:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80002194:	478d                	li	a5,3
    80002196:	cc9c                	sw	a5,24(s1)
  enqueue(p);
    80002198:	8526                	mv	a0,s1
    8000219a:	f69ff0ef          	jal	ra,80002102 <enqueue>
  release(&p->lock);
    8000219e:	8526                	mv	a0,s1
    800021a0:	a65fe0ef          	jal	ra,80000c04 <release>
}
    800021a4:	60e2                	ld	ra,24(sp)
    800021a6:	6442                	ld	s0,16(sp)
    800021a8:	64a2                	ld	s1,8(sp)
    800021aa:	6105                	addi	sp,sp,32
    800021ac:	8082                	ret

00000000800021ae <yield>:
{
    800021ae:	1101                	addi	sp,sp,-32
    800021b0:	ec06                	sd	ra,24(sp)
    800021b2:	e822                	sd	s0,16(sp)
    800021b4:	e426                	sd	s1,8(sp)
    800021b6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021b8:	e7cff0ef          	jal	ra,80001834 <myproc>
    800021bc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021be:	9affe0ef          	jal	ra,80000b6c <acquire>
  p->state = RUNNABLE;
    800021c2:	478d                	li	a5,3
    800021c4:	cc9c                	sw	a5,24(s1)
  p->ticks_in_queue = 0;
    800021c6:	1604aa23          	sw	zero,372(s1)
  enqueue(p);  // 加入当前 priority 队列
    800021ca:	8526                	mv	a0,s1
    800021cc:	f37ff0ef          	jal	ra,80002102 <enqueue>
  sched();
    800021d0:	aabff0ef          	jal	ra,80001c7a <sched>
  release(&p->lock);
    800021d4:	8526                	mv	a0,s1
    800021d6:	a2ffe0ef          	jal	ra,80000c04 <release>
}
    800021da:	60e2                	ld	ra,24(sp)
    800021dc:	6442                	ld	s0,16(sp)
    800021de:	64a2                	ld	s1,8(sp)
    800021e0:	6105                	addi	sp,sp,32
    800021e2:	8082                	ret

00000000800021e4 <wakeup>:
{
    800021e4:	7139                	addi	sp,sp,-64
    800021e6:	fc06                	sd	ra,56(sp)
    800021e8:	f822                	sd	s0,48(sp)
    800021ea:	f426                	sd	s1,40(sp)
    800021ec:	f04a                	sd	s2,32(sp)
    800021ee:	ec4e                	sd	s3,24(sp)
    800021f0:	e852                	sd	s4,16(sp)
    800021f2:	e456                	sd	s5,8(sp)
    800021f4:	0080                	addi	s0,sp,64
    800021f6:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800021f8:	0000e497          	auipc	s1,0xe
    800021fc:	c6048493          	addi	s1,s1,-928 # 8000fe58 <proc>
      if(p->state == SLEEPING && p->chan == chan) {
    80002200:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002202:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002204:	00014917          	auipc	s2,0x14
    80002208:	c5490913          	addi	s2,s2,-940 # 80015e58 <tickslock>
    8000220c:	a801                	j	8000221c <wakeup+0x38>
      release(&p->lock);
    8000220e:	8526                	mv	a0,s1
    80002210:	9f5fe0ef          	jal	ra,80000c04 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002214:	18048493          	addi	s1,s1,384
    80002218:	03248563          	beq	s1,s2,80002242 <wakeup+0x5e>
    if(p != myproc()){
    8000221c:	e18ff0ef          	jal	ra,80001834 <myproc>
    80002220:	fea48ae3          	beq	s1,a0,80002214 <wakeup+0x30>
      acquire(&p->lock);
    80002224:	8526                	mv	a0,s1
    80002226:	947fe0ef          	jal	ra,80000b6c <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000222a:	4c9c                	lw	a5,24(s1)
    8000222c:	ff3791e3          	bne	a5,s3,8000220e <wakeup+0x2a>
    80002230:	709c                	ld	a5,32(s1)
    80002232:	fd479ee3          	bne	a5,s4,8000220e <wakeup+0x2a>
        p->state = RUNNABLE;
    80002236:	0154ac23          	sw	s5,24(s1)
	enqueue(p);
    8000223a:	8526                	mv	a0,s1
    8000223c:	ec7ff0ef          	jal	ra,80002102 <enqueue>
    80002240:	b7f9                	j	8000220e <wakeup+0x2a>
}
    80002242:	70e2                	ld	ra,56(sp)
    80002244:	7442                	ld	s0,48(sp)
    80002246:	74a2                	ld	s1,40(sp)
    80002248:	7902                	ld	s2,32(sp)
    8000224a:	69e2                	ld	s3,24(sp)
    8000224c:	6a42                	ld	s4,16(sp)
    8000224e:	6aa2                	ld	s5,8(sp)
    80002250:	6121                	addi	sp,sp,64
    80002252:	8082                	ret

0000000080002254 <reparent>:
{
    80002254:	7179                	addi	sp,sp,-48
    80002256:	f406                	sd	ra,40(sp)
    80002258:	f022                	sd	s0,32(sp)
    8000225a:	ec26                	sd	s1,24(sp)
    8000225c:	e84a                	sd	s2,16(sp)
    8000225e:	e44e                	sd	s3,8(sp)
    80002260:	e052                	sd	s4,0(sp)
    80002262:	1800                	addi	s0,sp,48
    80002264:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002266:	0000e497          	auipc	s1,0xe
    8000226a:	bf248493          	addi	s1,s1,-1038 # 8000fe58 <proc>
      pp->parent = initproc;
    8000226e:	00005a17          	auipc	s4,0x5
    80002272:	60aa0a13          	addi	s4,s4,1546 # 80007878 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002276:	00014997          	auipc	s3,0x14
    8000227a:	be298993          	addi	s3,s3,-1054 # 80015e58 <tickslock>
    8000227e:	a029                	j	80002288 <reparent+0x34>
    80002280:	18048493          	addi	s1,s1,384
    80002284:	01348b63          	beq	s1,s3,8000229a <reparent+0x46>
    if(pp->parent == p){
    80002288:	7c9c                	ld	a5,56(s1)
    8000228a:	ff279be3          	bne	a5,s2,80002280 <reparent+0x2c>
      pp->parent = initproc;
    8000228e:	000a3503          	ld	a0,0(s4)
    80002292:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002294:	f51ff0ef          	jal	ra,800021e4 <wakeup>
    80002298:	b7e5                	j	80002280 <reparent+0x2c>
}
    8000229a:	70a2                	ld	ra,40(sp)
    8000229c:	7402                	ld	s0,32(sp)
    8000229e:	64e2                	ld	s1,24(sp)
    800022a0:	6942                	ld	s2,16(sp)
    800022a2:	69a2                	ld	s3,8(sp)
    800022a4:	6a02                	ld	s4,0(sp)
    800022a6:	6145                	addi	sp,sp,48
    800022a8:	8082                	ret

00000000800022aa <kexit>:
{
    800022aa:	7179                	addi	sp,sp,-48
    800022ac:	f406                	sd	ra,40(sp)
    800022ae:	f022                	sd	s0,32(sp)
    800022b0:	ec26                	sd	s1,24(sp)
    800022b2:	e84a                	sd	s2,16(sp)
    800022b4:	e44e                	sd	s3,8(sp)
    800022b6:	e052                	sd	s4,0(sp)
    800022b8:	1800                	addi	s0,sp,48
    800022ba:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022bc:	d78ff0ef          	jal	ra,80001834 <myproc>
    800022c0:	89aa                	mv	s3,a0
  if(p == initproc)
    800022c2:	00005797          	auipc	a5,0x5
    800022c6:	5b67b783          	ld	a5,1462(a5) # 80007878 <initproc>
    800022ca:	0d050493          	addi	s1,a0,208
    800022ce:	15050913          	addi	s2,a0,336
    800022d2:	00a79f63          	bne	a5,a0,800022f0 <kexit+0x46>
    panic("init exiting");
    800022d6:	00005517          	auipc	a0,0x5
    800022da:	f4a50513          	addi	a0,a0,-182 # 80007220 <digits+0x1e8>
    800022de:	cacfe0ef          	jal	ra,8000078a <panic>
      fileclose(f);
    800022e2:	6bb010ef          	jal	ra,8000419c <fileclose>
      p->ofile[fd] = 0;
    800022e6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022ea:	04a1                	addi	s1,s1,8
    800022ec:	01248563          	beq	s1,s2,800022f6 <kexit+0x4c>
    if(p->ofile[fd]){
    800022f0:	6088                	ld	a0,0(s1)
    800022f2:	f965                	bnez	a0,800022e2 <kexit+0x38>
    800022f4:	bfdd                	j	800022ea <kexit+0x40>
  begin_op();
    800022f6:	299010ef          	jal	ra,80003d8e <begin_op>
  iput(p->cwd);
    800022fa:	1509b503          	ld	a0,336(s3)
    800022fe:	230010ef          	jal	ra,8000352e <iput>
  end_op();
    80002302:	2fd010ef          	jal	ra,80003dfe <end_op>
  p->cwd = 0;
    80002306:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000230a:	0000d497          	auipc	s1,0xd
    8000230e:	73648493          	addi	s1,s1,1846 # 8000fa40 <wait_lock>
    80002312:	8526                	mv	a0,s1
    80002314:	859fe0ef          	jal	ra,80000b6c <acquire>
  reparent(p);
    80002318:	854e                	mv	a0,s3
    8000231a:	f3bff0ef          	jal	ra,80002254 <reparent>
  wakeup(p->parent);
    8000231e:	0389b503          	ld	a0,56(s3)
    80002322:	ec3ff0ef          	jal	ra,800021e4 <wakeup>
  acquire(&p->lock);
    80002326:	854e                	mv	a0,s3
    80002328:	845fe0ef          	jal	ra,80000b6c <acquire>
  p->xstate = status;
    8000232c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002330:	4795                	li	a5,5
    80002332:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002336:	8526                	mv	a0,s1
    80002338:	8cdfe0ef          	jal	ra,80000c04 <release>
  sched();
    8000233c:	93fff0ef          	jal	ra,80001c7a <sched>
  panic("zombie exit");
    80002340:	00005517          	auipc	a0,0x5
    80002344:	ef050513          	addi	a0,a0,-272 # 80007230 <digits+0x1f8>
    80002348:	c42fe0ef          	jal	ra,8000078a <panic>

000000008000234c <dequeue>:

// 从指定优先级队列头取出一个进程
struct proc*
dequeue(int prio)
{
    8000234c:	7179                	addi	sp,sp,-48
    8000234e:	f406                	sd	ra,40(sp)
    80002350:	f022                	sd	s0,32(sp)
    80002352:	ec26                	sd	s1,24(sp)
    80002354:	e84a                	sd	s2,16(sp)
    80002356:	e44e                	sd	s3,8(sp)
    80002358:	1800                	addi	s0,sp,48
  acquire(&run_queues[prio].lock);
    8000235a:	00251913          	slli	s2,a0,0x2
    8000235e:	992a                	add	s2,s2,a0
    80002360:	00391793          	slli	a5,s2,0x3
    80002364:	0000d917          	auipc	s2,0xd
    80002368:	62490913          	addi	s2,s2,1572 # 8000f988 <run_queues>
    8000236c:	993e                	add	s2,s2,a5
    8000236e:	854a                	mv	a0,s2
    80002370:	ffcfe0ef          	jal	ra,80000b6c <acquire>
  struct proc *p = run_queues[prio].head;
    80002374:	01893983          	ld	s3,24(s2)
  if (p) {
    80002378:	00098963          	beqz	s3,8000238a <dequeue+0x3e>
    run_queues[prio].head = p->next;
    8000237c:	1789b683          	ld	a3,376(s3)
    80002380:	00d93c23          	sd	a3,24(s2)
    if (run_queues[prio].head == 0)
    80002384:	ce91                	beqz	a3,800023a0 <dequeue+0x54>
      run_queues[prio].tail = 0;
    p->next = 0;
    80002386:	1609bc23          	sd	zero,376(s3)
  }
  release(&run_queues[prio].lock);
    8000238a:	854a                	mv	a0,s2
    8000238c:	879fe0ef          	jal	ra,80000c04 <release>
  return p;
}
    80002390:	854e                	mv	a0,s3
    80002392:	70a2                	ld	ra,40(sp)
    80002394:	7402                	ld	s0,32(sp)
    80002396:	64e2                	ld	s1,24(sp)
    80002398:	6942                	ld	s2,16(sp)
    8000239a:	69a2                	ld	s3,8(sp)
    8000239c:	6145                	addi	sp,sp,48
    8000239e:	8082                	ret
      run_queues[prio].tail = 0;
    800023a0:	02093023          	sd	zero,32(s2)
    800023a4:	b7cd                	j	80002386 <dequeue+0x3a>

00000000800023a6 <scheduler>:
{
    800023a6:	715d                	addi	sp,sp,-80
    800023a8:	e486                	sd	ra,72(sp)
    800023aa:	e0a2                	sd	s0,64(sp)
    800023ac:	fc26                	sd	s1,56(sp)
    800023ae:	f84a                	sd	s2,48(sp)
    800023b0:	f44e                	sd	s3,40(sp)
    800023b2:	f052                	sd	s4,32(sp)
    800023b4:	ec56                	sd	s5,24(sp)
    800023b6:	e85a                	sd	s6,16(sp)
    800023b8:	e45e                	sd	s7,8(sp)
    800023ba:	0880                	addi	s0,sp,80
    800023bc:	8792                	mv	a5,tp
  int id = r_tp();
    800023be:	2781                	sext.w	a5,a5
  c->proc = 0;
    800023c0:	00779b93          	slli	s7,a5,0x7
    800023c4:	0000d717          	auipc	a4,0xd
    800023c8:	5c470713          	addi	a4,a4,1476 # 8000f988 <run_queues>
    800023cc:	975e                	add	a4,a4,s7
    800023ce:	0c073823          	sd	zero,208(a4)
      swtch(&c->context, &p->context);
    800023d2:	0000d717          	auipc	a4,0xd
    800023d6:	68e70713          	addi	a4,a4,1678 # 8000fa60 <cpus+0x8>
    800023da:	9bba                	add	s7,s7,a4
    for (int i = 0; i < NQUEUES; i++) {
    800023dc:	4a01                	li	s4,0
    800023de:	4991                	li	s3,4
      if (p->state != RUNNABLE) {
    800023e0:	4a8d                	li	s5,3
      c->proc = p;
    800023e2:	079e                	slli	a5,a5,0x7
    800023e4:	0000db17          	auipc	s6,0xd
    800023e8:	5a4b0b13          	addi	s6,s6,1444 # 8000f988 <run_queues>
    800023ec:	9b3e                	add	s6,s6,a5
    800023ee:	a835                	j	8000242a <scheduler+0x84>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023f0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800023f4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800023f6:	10079073          	csrw	sstatus,a5
      p->state = RUNNING;
    800023fa:	01392c23          	sw	s3,24(s2)
      c->proc = p;
    800023fe:	0d2b3823          	sd	s2,208(s6)
      swtch(&c->context, &p->context);
    80002402:	06090593          	addi	a1,s2,96
    80002406:	855e                	mv	a0,s7
    80002408:	09e000ef          	jal	ra,800024a6 <swtch>
      c->proc = 0;
    8000240c:	0c0b3823          	sd	zero,208(s6)
      release(&p->lock);
    80002410:	854a                	mv	a0,s2
    80002412:	ff2fe0ef          	jal	ra,80000c04 <release>
    80002416:	a811                	j	8000242a <scheduler+0x84>
      acquire(&p->lock);
    80002418:	f54fe0ef          	jal	ra,80000b6c <acquire>
      if (p->state != RUNNABLE) {
    8000241c:	01892783          	lw	a5,24(s2)
    80002420:	fd5788e3          	beq	a5,s5,800023f0 <scheduler+0x4a>
        release(&p->lock);
    80002424:	854a                	mv	a0,s2
    80002426:	fdefe0ef          	jal	ra,80000c04 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000242a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000242e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002432:	10079073          	csrw	sstatus,a5
    for (int i = 0; i < NQUEUES; i++) {
    80002436:	84d2                	mv	s1,s4
      p = dequeue(i);
    80002438:	8526                	mv	a0,s1
    8000243a:	f13ff0ef          	jal	ra,8000234c <dequeue>
    8000243e:	892a                	mv	s2,a0
      if (p) break;
    80002440:	fd61                	bnez	a0,80002418 <scheduler+0x72>
    for (int i = 0; i < NQUEUES; i++) {
    80002442:	2485                	addiw	s1,s1,1
    80002444:	ff349ae3          	bne	s1,s3,80002438 <scheduler+0x92>
    80002448:	b7cd                	j	8000242a <scheduler+0x84>

000000008000244a <boost_all>:

// 将所有进程提升到最高优先级（防止饥饿）
void
boost_all(void)
{
    8000244a:	7179                	addi	sp,sp,-48
    8000244c:	f406                	sd	ra,40(sp)
    8000244e:	f022                	sd	s0,32(sp)
    80002450:	ec26                	sd	s1,24(sp)
    80002452:	e84a                	sd	s2,16(sp)
    80002454:	e44e                	sd	s3,8(sp)
    80002456:	1800                	addi	s0,sp,48
  for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    80002458:	0000e497          	auipc	s1,0xe
    8000245c:	a0048493          	addi	s1,s1,-1536 # 8000fe58 <proc>
    acquire(&p->lock);
    if (p->state != UNUSED) {
      p->priority = 0;
      p->ticks_in_queue = 0;
      if (p->state == RUNNABLE) {
    80002460:	498d                	li	s3,3
  for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    80002462:	00014917          	auipc	s2,0x14
    80002466:	9f690913          	addi	s2,s2,-1546 # 80015e58 <tickslock>
    8000246a:	a801                	j	8000247a <boost_all+0x30>
        // 重新入队到最高优先级
        enqueue(p);
      }
    }
    release(&p->lock);
    8000246c:	8526                	mv	a0,s1
    8000246e:	f96fe0ef          	jal	ra,80000c04 <release>
  for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    80002472:	18048493          	addi	s1,s1,384
    80002476:	03248163          	beq	s1,s2,80002498 <boost_all+0x4e>
    acquire(&p->lock);
    8000247a:	8526                	mv	a0,s1
    8000247c:	ef0fe0ef          	jal	ra,80000b6c <acquire>
    if (p->state != UNUSED) {
    80002480:	4c9c                	lw	a5,24(s1)
    80002482:	d7ed                	beqz	a5,8000246c <boost_all+0x22>
      p->priority = 0;
    80002484:	1604a823          	sw	zero,368(s1)
      p->ticks_in_queue = 0;
    80002488:	1604aa23          	sw	zero,372(s1)
      if (p->state == RUNNABLE) {
    8000248c:	ff3790e3          	bne	a5,s3,8000246c <boost_all+0x22>
        enqueue(p);
    80002490:	8526                	mv	a0,s1
    80002492:	c71ff0ef          	jal	ra,80002102 <enqueue>
    80002496:	bfd9                	j	8000246c <boost_all+0x22>
  }
}
    80002498:	70a2                	ld	ra,40(sp)
    8000249a:	7402                	ld	s0,32(sp)
    8000249c:	64e2                	ld	s1,24(sp)
    8000249e:	6942                	ld	s2,16(sp)
    800024a0:	69a2                	ld	s3,8(sp)
    800024a2:	6145                	addi	sp,sp,48
    800024a4:	8082                	ret

00000000800024a6 <swtch>:
# 保存当前寄存器到 old，然后从 new 加载寄存器。

.globl swtch
swtch:
        # 保存当前的寄存器到 old 中
        sd ra, 0(a0)   # 保存返回地址寄存器 ra
    800024a6:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)   # 保存栈指针寄存器 sp
    800024aa:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)  # 保存寄存器 s0
    800024ae:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)  # 保存寄存器 s1
    800024b0:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)  # 保存寄存器 s2
    800024b2:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)  # 保存寄存器 s3
    800024b6:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)  # 保存寄存器 s4
    800024ba:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)  # 保存寄存器 s5
    800024be:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)  # 保存寄存器 s6
    800024c2:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)  # 保存寄存器 s7
    800024c6:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)  # 保存寄存器 s8
    800024ca:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)  # 保存寄存器 s9
    800024ce:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0) # 保存寄存器 s10
    800024d2:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)# 保存寄存器 s11
    800024d6:	07b53423          	sd	s11,104(a0)

        # 从 new 加载寄存器
        ld ra, 0(a1)   # 加载返回地址寄存器 ra
    800024da:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)   # 加载栈指针寄存器 sp
    800024de:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)  # 加载寄存器 s0
    800024e2:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)  # 加载寄存器 s1
    800024e4:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)  # 加载寄存器 s2
    800024e6:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)  # 加载寄存器 s3
    800024ea:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)  # 加载寄存器 s4
    800024ee:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)  # 加载寄存器 s5
    800024f2:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)  # 加载寄存器 s6
    800024f6:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)  # 加载寄存器 s7
    800024fa:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)  # 加载寄存器 s8
    800024fe:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)  # 加载寄存器 s9
    80002502:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1) # 加载寄存器 s10
    80002506:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)# 加载寄存器 s11
    8000250a:	0685bd83          	ld	s11,104(a1)

        ret             # 返回，完成上下文切换
    8000250e:	8082                	ret

0000000080002510 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002510:	1141                	addi	sp,sp,-16
    80002512:	e406                	sd	ra,8(sp)
    80002514:	e022                	sd	s0,0(sp)
    80002516:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002518:	00005597          	auipc	a1,0x5
    8000251c:	d8858593          	addi	a1,a1,-632 # 800072a0 <states.0+0x30>
    80002520:	00014517          	auipc	a0,0x14
    80002524:	93850513          	addi	a0,a0,-1736 # 80015e58 <tickslock>
    80002528:	dc4fe0ef          	jal	ra,80000aec <initlock>
}
    8000252c:	60a2                	ld	ra,8(sp)
    8000252e:	6402                	ld	s0,0(sp)
    80002530:	0141                	addi	sp,sp,16
    80002532:	8082                	ret

0000000080002534 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002534:	1141                	addi	sp,sp,-16
    80002536:	e422                	sd	s0,8(sp)
    80002538:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000253a:	00003797          	auipc	a5,0x3
    8000253e:	f2678793          	addi	a5,a5,-218 # 80005460 <kernelvec>
    80002542:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002546:	6422                	ld	s0,8(sp)
    80002548:	0141                	addi	sp,sp,16
    8000254a:	8082                	ret

000000008000254c <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    8000254c:	1141                	addi	sp,sp,-16
    8000254e:	e406                	sd	ra,8(sp)
    80002550:	e022                	sd	s0,0(sp)
    80002552:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002554:	ae0ff0ef          	jal	ra,80001834 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002558:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000255c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000255e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002562:	04000737          	lui	a4,0x4000
    80002566:	00004797          	auipc	a5,0x4
    8000256a:	a9a78793          	addi	a5,a5,-1382 # 80006000 <_trampoline>
    8000256e:	00004697          	auipc	a3,0x4
    80002572:	a9268693          	addi	a3,a3,-1390 # 80006000 <_trampoline>
    80002576:	8f95                	sub	a5,a5,a3
    80002578:	177d                	addi	a4,a4,-1
    8000257a:	0732                	slli	a4,a4,0xc
    8000257c:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000257e:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002582:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002584:	18002773          	csrr	a4,satp
    80002588:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000258a:	6d38                	ld	a4,88(a0)
    8000258c:	613c                	ld	a5,64(a0)
    8000258e:	6685                	lui	a3,0x1
    80002590:	97b6                	add	a5,a5,a3
    80002592:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002594:	6d3c                	ld	a5,88(a0)
    80002596:	00000717          	auipc	a4,0x0
    8000259a:	0f470713          	addi	a4,a4,244 # 8000268a <usertrap>
    8000259e:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800025a0:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800025a2:	8712                	mv	a4,tp
    800025a4:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025a6:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800025aa:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800025ae:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025b2:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800025b6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800025b8:	6f9c                	ld	a5,24(a5)
    800025ba:	14179073          	csrw	sepc,a5
}
    800025be:	60a2                	ld	ra,8(sp)
    800025c0:	6402                	ld	s0,0(sp)
    800025c2:	0141                	addi	sp,sp,16
    800025c4:	8082                	ret

00000000800025c6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800025c6:	1101                	addi	sp,sp,-32
    800025c8:	ec06                	sd	ra,24(sp)
    800025ca:	e822                	sd	s0,16(sp)
    800025cc:	e426                	sd	s1,8(sp)
    800025ce:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    800025d0:	a38ff0ef          	jal	ra,80001808 <cpuid>
    800025d4:	cd19                	beqz	a0,800025f2 <clockintr+0x2c>
  asm volatile("csrr %0, time" : "=r" (x) );
    800025d6:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    800025da:	000f4737          	lui	a4,0xf4
    800025de:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    800025e2:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    800025e4:	14d79073          	csrw	0x14d,a5
}
    800025e8:	60e2                	ld	ra,24(sp)
    800025ea:	6442                	ld	s0,16(sp)
    800025ec:	64a2                	ld	s1,8(sp)
    800025ee:	6105                	addi	sp,sp,32
    800025f0:	8082                	ret
    acquire(&tickslock);
    800025f2:	00014497          	auipc	s1,0x14
    800025f6:	86648493          	addi	s1,s1,-1946 # 80015e58 <tickslock>
    800025fa:	8526                	mv	a0,s1
    800025fc:	d70fe0ef          	jal	ra,80000b6c <acquire>
    ticks++;
    80002600:	00005517          	auipc	a0,0x5
    80002604:	28050513          	addi	a0,a0,640 # 80007880 <ticks>
    80002608:	411c                	lw	a5,0(a0)
    8000260a:	2785                	addiw	a5,a5,1
    8000260c:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    8000260e:	bd7ff0ef          	jal	ra,800021e4 <wakeup>
    release(&tickslock);
    80002612:	8526                	mv	a0,s1
    80002614:	df0fe0ef          	jal	ra,80000c04 <release>
    80002618:	bf7d                	j	800025d6 <clockintr+0x10>

000000008000261a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000261a:	1101                	addi	sp,sp,-32
    8000261c:	ec06                	sd	ra,24(sp)
    8000261e:	e822                	sd	s0,16(sp)
    80002620:	e426                	sd	s1,8(sp)
    80002622:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002624:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    80002628:	57fd                	li	a5,-1
    8000262a:	17fe                	slli	a5,a5,0x3f
    8000262c:	07a5                	addi	a5,a5,9
    8000262e:	00f70d63          	beq	a4,a5,80002648 <devintr+0x2e>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    80002632:	57fd                	li	a5,-1
    80002634:	17fe                	slli	a5,a5,0x3f
    80002636:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    80002638:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    8000263a:	04f70463          	beq	a4,a5,80002682 <devintr+0x68>
  }
}
    8000263e:	60e2                	ld	ra,24(sp)
    80002640:	6442                	ld	s0,16(sp)
    80002642:	64a2                	ld	s1,8(sp)
    80002644:	6105                	addi	sp,sp,32
    80002646:	8082                	ret
    int irq = plic_claim();
    80002648:	6c1020ef          	jal	ra,80005508 <plic_claim>
    8000264c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000264e:	47a9                	li	a5,10
    80002650:	02f50363          	beq	a0,a5,80002676 <devintr+0x5c>
    } else if(irq == VIRTIO0_IRQ){
    80002654:	4785                	li	a5,1
    80002656:	02f50363          	beq	a0,a5,8000267c <devintr+0x62>
    return 1;
    8000265a:	4505                	li	a0,1
    } else if(irq){
    8000265c:	d0ed                	beqz	s1,8000263e <devintr+0x24>
      printf("unexpected interrupt irq=%d\n", irq);
    8000265e:	85a6                	mv	a1,s1
    80002660:	00005517          	auipc	a0,0x5
    80002664:	c4850513          	addi	a0,a0,-952 # 800072a8 <states.0+0x38>
    80002668:	e5dfd0ef          	jal	ra,800004c4 <printf>
      plic_complete(irq);
    8000266c:	8526                	mv	a0,s1
    8000266e:	6bb020ef          	jal	ra,80005528 <plic_complete>
    return 1;
    80002672:	4505                	li	a0,1
    80002674:	b7e9                	j	8000263e <devintr+0x24>
      uartintr();
    80002676:	ae2fe0ef          	jal	ra,80000958 <uartintr>
    8000267a:	bfcd                	j	8000266c <devintr+0x52>
      virtio_disk_intr();
    8000267c:	31c030ef          	jal	ra,80005998 <virtio_disk_intr>
    80002680:	b7f5                	j	8000266c <devintr+0x52>
    clockintr();
    80002682:	f45ff0ef          	jal	ra,800025c6 <clockintr>
    return 2;
    80002686:	4509                	li	a0,2
    80002688:	bf5d                	j	8000263e <devintr+0x24>

000000008000268a <usertrap>:
{
    8000268a:	1101                	addi	sp,sp,-32
    8000268c:	ec06                	sd	ra,24(sp)
    8000268e:	e822                	sd	s0,16(sp)
    80002690:	e426                	sd	s1,8(sp)
    80002692:	e04a                	sd	s2,0(sp)
    80002694:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002696:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000269a:	1007f793          	andi	a5,a5,256
    8000269e:	eba5                	bnez	a5,8000270e <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026a0:	00003797          	auipc	a5,0x3
    800026a4:	dc078793          	addi	a5,a5,-576 # 80005460 <kernelvec>
    800026a8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800026ac:	988ff0ef          	jal	ra,80001834 <myproc>
    800026b0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800026b2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800026b4:	14102773          	csrr	a4,sepc
    800026b8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026ba:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800026be:	47a1                	li	a5,8
    800026c0:	04f70d63          	beq	a4,a5,8000271a <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    800026c4:	f57ff0ef          	jal	ra,8000261a <devintr>
    800026c8:	892a                	mv	s2,a0
    800026ca:	e945                	bnez	a0,8000277a <usertrap+0xf0>
    800026cc:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    800026d0:	47bd                	li	a5,15
    800026d2:	08f70863          	beq	a4,a5,80002762 <usertrap+0xd8>
    800026d6:	14202773          	csrr	a4,scause
    800026da:	47b5                	li	a5,13
    800026dc:	08f70363          	beq	a4,a5,80002762 <usertrap+0xd8>
    800026e0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    800026e4:	5890                	lw	a2,48(s1)
    800026e6:	00005517          	auipc	a0,0x5
    800026ea:	c0250513          	addi	a0,a0,-1022 # 800072e8 <states.0+0x78>
    800026ee:	dd7fd0ef          	jal	ra,800004c4 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800026f2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800026f6:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    800026fa:	00005517          	auipc	a0,0x5
    800026fe:	c1e50513          	addi	a0,a0,-994 # 80007318 <states.0+0xa8>
    80002702:	dc3fd0ef          	jal	ra,800004c4 <printf>
    setkilled(p);
    80002706:	8526                	mv	a0,s1
    80002708:	ee2ff0ef          	jal	ra,80001dea <setkilled>
    8000270c:	a035                	j	80002738 <usertrap+0xae>
    panic("usertrap: not from user mode");
    8000270e:	00005517          	auipc	a0,0x5
    80002712:	bba50513          	addi	a0,a0,-1094 # 800072c8 <states.0+0x58>
    80002716:	874fe0ef          	jal	ra,8000078a <panic>
    if(killed(p))
    8000271a:	ef4ff0ef          	jal	ra,80001e0e <killed>
    8000271e:	ed15                	bnez	a0,8000275a <usertrap+0xd0>
    p->trapframe->epc += 4;
    80002720:	6cb8                	ld	a4,88(s1)
    80002722:	6f1c                	ld	a5,24(a4)
    80002724:	0791                	addi	a5,a5,4
    80002726:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002728:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000272c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002730:	10079073          	csrw	sstatus,a5
    syscall();
    80002734:	2fc000ef          	jal	ra,80002a30 <syscall>
  if(killed(p))
    80002738:	8526                	mv	a0,s1
    8000273a:	ed4ff0ef          	jal	ra,80001e0e <killed>
    8000273e:	e139                	bnez	a0,80002784 <usertrap+0xfa>
  prepare_return();
    80002740:	e0dff0ef          	jal	ra,8000254c <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80002744:	68a8                	ld	a0,80(s1)
    80002746:	8131                	srli	a0,a0,0xc
    80002748:	57fd                	li	a5,-1
    8000274a:	17fe                	slli	a5,a5,0x3f
    8000274c:	8d5d                	or	a0,a0,a5
}
    8000274e:	60e2                	ld	ra,24(sp)
    80002750:	6442                	ld	s0,16(sp)
    80002752:	64a2                	ld	s1,8(sp)
    80002754:	6902                	ld	s2,0(sp)
    80002756:	6105                	addi	sp,sp,32
    80002758:	8082                	ret
      kexit(-1);
    8000275a:	557d                	li	a0,-1
    8000275c:	b4fff0ef          	jal	ra,800022aa <kexit>
    80002760:	b7c1                	j	80002720 <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002762:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002766:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    8000276a:	164d                	addi	a2,a2,-13
    8000276c:	00163613          	seqz	a2,a2
    80002770:	68a8                	ld	a0,80(s1)
    80002772:	d6ffe0ef          	jal	ra,800014e0 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002776:	f169                	bnez	a0,80002738 <usertrap+0xae>
    80002778:	b7a5                	j	800026e0 <usertrap+0x56>
  if(killed(p))
    8000277a:	8526                	mv	a0,s1
    8000277c:	e92ff0ef          	jal	ra,80001e0e <killed>
    80002780:	c511                	beqz	a0,8000278c <usertrap+0x102>
    80002782:	a011                	j	80002786 <usertrap+0xfc>
    80002784:	4901                	li	s2,0
    kexit(-1);
    80002786:	557d                	li	a0,-1
    80002788:	b23ff0ef          	jal	ra,800022aa <kexit>
  if (which_dev == 2) {
    8000278c:	4789                	li	a5,2
    8000278e:	faf919e3          	bne	s2,a5,80002740 <usertrap+0xb6>
  global_ticks++;
    80002792:	00005717          	auipc	a4,0x5
    80002796:	0de70713          	addi	a4,a4,222 # 80007870 <global_ticks>
    8000279a:	431c                	lw	a5,0(a4)
    8000279c:	2785                	addiw	a5,a5,1
    8000279e:	c31c                	sw	a5,0(a4)
  struct proc *p = myproc();
    800027a0:	894ff0ef          	jal	ra,80001834 <myproc>
  if (p) {
    800027a4:	cd15                	beqz	a0,800027e0 <usertrap+0x156>
    p->ticks_in_queue++; 
    800027a6:	17452783          	lw	a5,372(a0)
    800027aa:	2785                	addiw	a5,a5,1
    800027ac:	0007871b          	sext.w	a4,a5
    800027b0:	16f52a23          	sw	a5,372(a0)
    if (p->ticks_in_queue >= 4 && p->priority < NQUEUES - 1) {
    800027b4:	478d                	li	a5,3
    800027b6:	00e7da63          	bge	a5,a4,800027ca <usertrap+0x140>
    800027ba:	17052783          	lw	a5,368(a0)
    800027be:	4709                	li	a4,2
    800027c0:	00f74563          	blt	a4,a5,800027ca <usertrap+0x140>
      p->priority++;
    800027c4:	2785                	addiw	a5,a5,1
    800027c6:	16f52823          	sw	a5,368(a0)
    if (global_ticks % 100 == 0) {
    800027ca:	00005797          	auipc	a5,0x5
    800027ce:	0a67a783          	lw	a5,166(a5) # 80007870 <global_ticks>
    800027d2:	06400713          	li	a4,100
    800027d6:	02e7e7bb          	remw	a5,a5,a4
    800027da:	cb91                	beqz	a5,800027ee <usertrap+0x164>
    yield(); // 抢占
    800027dc:	9d3ff0ef          	jal	ra,800021ae <yield>
  wakeup(&ticks);
    800027e0:	00005517          	auipc	a0,0x5
    800027e4:	0a050513          	addi	a0,a0,160 # 80007880 <ticks>
    800027e8:	9fdff0ef          	jal	ra,800021e4 <wakeup>
    800027ec:	bf91                	j	80002740 <usertrap+0xb6>
      boost_all();
    800027ee:	c5dff0ef          	jal	ra,8000244a <boost_all>
    800027f2:	b7ed                	j	800027dc <usertrap+0x152>

00000000800027f4 <kerneltrap>:
{
    800027f4:	7179                	addi	sp,sp,-48
    800027f6:	f406                	sd	ra,40(sp)
    800027f8:	f022                	sd	s0,32(sp)
    800027fa:	ec26                	sd	s1,24(sp)
    800027fc:	e84a                	sd	s2,16(sp)
    800027fe:	e44e                	sd	s3,8(sp)
    80002800:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002802:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002806:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000280a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000280e:	1004f793          	andi	a5,s1,256
    80002812:	c795                	beqz	a5,8000283e <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002814:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002818:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000281a:	eb85                	bnez	a5,8000284a <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    8000281c:	dffff0ef          	jal	ra,8000261a <devintr>
    80002820:	c91d                	beqz	a0,80002856 <kerneltrap+0x62>
  if (which_dev == 2) {
    80002822:	4789                	li	a5,2
    80002824:	04f50a63          	beq	a0,a5,80002878 <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002828:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000282c:	10049073          	csrw	sstatus,s1
}
    80002830:	70a2                	ld	ra,40(sp)
    80002832:	7402                	ld	s0,32(sp)
    80002834:	64e2                	ld	s1,24(sp)
    80002836:	6942                	ld	s2,16(sp)
    80002838:	69a2                	ld	s3,8(sp)
    8000283a:	6145                	addi	sp,sp,48
    8000283c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000283e:	00005517          	auipc	a0,0x5
    80002842:	b0250513          	addi	a0,a0,-1278 # 80007340 <states.0+0xd0>
    80002846:	f45fd0ef          	jal	ra,8000078a <panic>
    panic("kerneltrap: interrupts enabled");
    8000284a:	00005517          	auipc	a0,0x5
    8000284e:	b1e50513          	addi	a0,a0,-1250 # 80007368 <states.0+0xf8>
    80002852:	f39fd0ef          	jal	ra,8000078a <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002856:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000285a:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    8000285e:	85ce                	mv	a1,s3
    80002860:	00005517          	auipc	a0,0x5
    80002864:	b2850513          	addi	a0,a0,-1240 # 80007388 <states.0+0x118>
    80002868:	c5dfd0ef          	jal	ra,800004c4 <printf>
    panic("kerneltrap");
    8000286c:	00005517          	auipc	a0,0x5
    80002870:	b4450513          	addi	a0,a0,-1212 # 800073b0 <states.0+0x140>
    80002874:	f17fd0ef          	jal	ra,8000078a <panic>
    global_ticks++;
    80002878:	00005717          	auipc	a4,0x5
    8000287c:	ff870713          	addi	a4,a4,-8 # 80007870 <global_ticks>
    80002880:	431c                	lw	a5,0(a4)
    80002882:	2785                	addiw	a5,a5,1
    80002884:	c31c                	sw	a5,0(a4)
    struct proc *p = myproc();
    80002886:	faffe0ef          	jal	ra,80001834 <myproc>
    if (p) {
    8000288a:	c121                	beqz	a0,800028ca <kerneltrap+0xd6>
      p->ticks_in_queue++;
    8000288c:	17452783          	lw	a5,372(a0)
    80002890:	2785                	addiw	a5,a5,1
    80002892:	0007871b          	sext.w	a4,a5
    80002896:	16f52a23          	sw	a5,372(a0)
      if (p->ticks_in_queue >= 4 && p->priority < NQUEUES - 1) {
    8000289a:	478d                	li	a5,3
    8000289c:	00e7dc63          	bge	a5,a4,800028b4 <kerneltrap+0xc0>
    800028a0:	17052783          	lw	a5,368(a0)
    800028a4:	4709                	li	a4,2
    800028a6:	00f74763          	blt	a4,a5,800028b4 <kerneltrap+0xc0>
        p->priority++;
    800028aa:	2785                	addiw	a5,a5,1
    800028ac:	16f52823          	sw	a5,368(a0)
        p->ticks_in_queue = 0;
    800028b0:	16052a23          	sw	zero,372(a0)
      if (global_ticks % BOOST_INTERVAL == 0) {
    800028b4:	00005797          	auipc	a5,0x5
    800028b8:	fbc7a783          	lw	a5,-68(a5) # 80007870 <global_ticks>
    800028bc:	06400713          	li	a4,100
    800028c0:	02e7e7bb          	remw	a5,a5,a4
    800028c4:	cb91                	beqz	a5,800028d8 <kerneltrap+0xe4>
      yield();  // ← 小心！可能不安全，但 xv6 单核常这么干
    800028c6:	8e9ff0ef          	jal	ra,800021ae <yield>
    wakeup(&ticks);
    800028ca:	00005517          	auipc	a0,0x5
    800028ce:	fb650513          	addi	a0,a0,-74 # 80007880 <ticks>
    800028d2:	913ff0ef          	jal	ra,800021e4 <wakeup>
    800028d6:	bf89                	j	80002828 <kerneltrap+0x34>
        boost_all();
    800028d8:	b73ff0ef          	jal	ra,8000244a <boost_all>
    800028dc:	b7ed                	j	800028c6 <kerneltrap+0xd2>

00000000800028de <argraw>:
}

// 获取第 n 个系统调用的原始参数（未处理过的原始值）
static uint64
argraw(int n)
{
    800028de:	1101                	addi	sp,sp,-32
    800028e0:	ec06                	sd	ra,24(sp)
    800028e2:	e822                	sd	s0,16(sp)
    800028e4:	e426                	sd	s1,8(sp)
    800028e6:	1000                	addi	s0,sp,32
    800028e8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800028ea:	f4bfe0ef          	jal	ra,80001834 <myproc>
  switch (n) {
    800028ee:	4795                	li	a5,5
    800028f0:	0497e163          	bltu	a5,s1,80002932 <argraw+0x54>
    800028f4:	048a                	slli	s1,s1,0x2
    800028f6:	00005717          	auipc	a4,0x5
    800028fa:	af270713          	addi	a4,a4,-1294 # 800073e8 <states.0+0x178>
    800028fe:	94ba                	add	s1,s1,a4
    80002900:	409c                	lw	a5,0(s1)
    80002902:	97ba                	add	a5,a5,a4
    80002904:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002906:	6d3c                	ld	a5,88(a0)
    80002908:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");  // 如果参数 n 无效，触发 panic
  return -1;
}
    8000290a:	60e2                	ld	ra,24(sp)
    8000290c:	6442                	ld	s0,16(sp)
    8000290e:	64a2                	ld	s1,8(sp)
    80002910:	6105                	addi	sp,sp,32
    80002912:	8082                	ret
    return p->trapframe->a1;
    80002914:	6d3c                	ld	a5,88(a0)
    80002916:	7fa8                	ld	a0,120(a5)
    80002918:	bfcd                	j	8000290a <argraw+0x2c>
    return p->trapframe->a2;
    8000291a:	6d3c                	ld	a5,88(a0)
    8000291c:	63c8                	ld	a0,128(a5)
    8000291e:	b7f5                	j	8000290a <argraw+0x2c>
    return p->trapframe->a3;
    80002920:	6d3c                	ld	a5,88(a0)
    80002922:	67c8                	ld	a0,136(a5)
    80002924:	b7dd                	j	8000290a <argraw+0x2c>
    return p->trapframe->a4;
    80002926:	6d3c                	ld	a5,88(a0)
    80002928:	6bc8                	ld	a0,144(a5)
    8000292a:	b7c5                	j	8000290a <argraw+0x2c>
    return p->trapframe->a5;
    8000292c:	6d3c                	ld	a5,88(a0)
    8000292e:	6fc8                	ld	a0,152(a5)
    80002930:	bfe9                	j	8000290a <argraw+0x2c>
  panic("argraw");  // 如果参数 n 无效，触发 panic
    80002932:	00005517          	auipc	a0,0x5
    80002936:	a8e50513          	addi	a0,a0,-1394 # 800073c0 <states.0+0x150>
    8000293a:	e51fd0ef          	jal	ra,8000078a <panic>

000000008000293e <fetchaddr>:
{
    8000293e:	1101                	addi	sp,sp,-32
    80002940:	ec06                	sd	ra,24(sp)
    80002942:	e822                	sd	s0,16(sp)
    80002944:	e426                	sd	s1,8(sp)
    80002946:	e04a                	sd	s2,0(sp)
    80002948:	1000                	addi	s0,sp,32
    8000294a:	84aa                	mv	s1,a0
    8000294c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000294e:	ee7fe0ef          	jal	ra,80001834 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // 这两个条件都需要检查，防止溢出
    80002952:	653c                	ld	a5,72(a0)
    80002954:	02f4f663          	bgeu	s1,a5,80002980 <fetchaddr+0x42>
    80002958:	00848713          	addi	a4,s1,8
    8000295c:	02e7e463          	bltu	a5,a4,80002984 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002960:	46a1                	li	a3,8
    80002962:	8626                	mv	a2,s1
    80002964:	85ca                	mv	a1,s2
    80002966:	6928                	ld	a0,80(a0)
    80002968:	cb1fe0ef          	jal	ra,80001618 <copyin>
    8000296c:	00a03533          	snez	a0,a0
    80002970:	40a00533          	neg	a0,a0
}
    80002974:	60e2                	ld	ra,24(sp)
    80002976:	6442                	ld	s0,16(sp)
    80002978:	64a2                	ld	s1,8(sp)
    8000297a:	6902                	ld	s2,0(sp)
    8000297c:	6105                	addi	sp,sp,32
    8000297e:	8082                	ret
    return -1;
    80002980:	557d                	li	a0,-1
    80002982:	bfcd                	j	80002974 <fetchaddr+0x36>
    80002984:	557d                	li	a0,-1
    80002986:	b7fd                	j	80002974 <fetchaddr+0x36>

0000000080002988 <fetchstr>:
{
    80002988:	7179                	addi	sp,sp,-48
    8000298a:	f406                	sd	ra,40(sp)
    8000298c:	f022                	sd	s0,32(sp)
    8000298e:	ec26                	sd	s1,24(sp)
    80002990:	e84a                	sd	s2,16(sp)
    80002992:	e44e                	sd	s3,8(sp)
    80002994:	1800                	addi	s0,sp,48
    80002996:	892a                	mv	s2,a0
    80002998:	84ae                	mv	s1,a1
    8000299a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000299c:	e99fe0ef          	jal	ra,80001834 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800029a0:	86ce                	mv	a3,s3
    800029a2:	864a                	mv	a2,s2
    800029a4:	85a6                	mv	a1,s1
    800029a6:	6928                	ld	a0,80(a0)
    800029a8:	a69fe0ef          	jal	ra,80001410 <copyinstr>
    800029ac:	00054c63          	bltz	a0,800029c4 <fetchstr+0x3c>
  return strlen(buf);  // 返回字符串长度
    800029b0:	8526                	mv	a0,s1
    800029b2:	c06fe0ef          	jal	ra,80000db8 <strlen>
}
    800029b6:	70a2                	ld	ra,40(sp)
    800029b8:	7402                	ld	s0,32(sp)
    800029ba:	64e2                	ld	s1,24(sp)
    800029bc:	6942                	ld	s2,16(sp)
    800029be:	69a2                	ld	s3,8(sp)
    800029c0:	6145                	addi	sp,sp,48
    800029c2:	8082                	ret
    return -1;
    800029c4:	557d                	li	a0,-1
    800029c6:	bfc5                	j	800029b6 <fetchstr+0x2e>

00000000800029c8 <argint>:

// 获取第 n 个 32 位的系统调用参数并将其存入 ip 中
void
argint(int n, int *ip)
{
    800029c8:	1101                	addi	sp,sp,-32
    800029ca:	ec06                	sd	ra,24(sp)
    800029cc:	e822                	sd	s0,16(sp)
    800029ce:	e426                	sd	s1,8(sp)
    800029d0:	1000                	addi	s0,sp,32
    800029d2:	84ae                	mv	s1,a1
  *ip = argraw(n);  // 通过 argraw 获取原始参数并存储
    800029d4:	f0bff0ef          	jal	ra,800028de <argraw>
    800029d8:	c088                	sw	a0,0(s1)
}
    800029da:	60e2                	ld	ra,24(sp)
    800029dc:	6442                	ld	s0,16(sp)
    800029de:	64a2                	ld	s1,8(sp)
    800029e0:	6105                	addi	sp,sp,32
    800029e2:	8082                	ret

00000000800029e4 <argaddr>:

// 获取第 n 个参数并将其作为指针返回。
// 不进行合法性检查，因为 copyin 和 copyout 会处理这些检查。
void
argaddr(int n, uint64 *ip)
{
    800029e4:	1101                	addi	sp,sp,-32
    800029e6:	ec06                	sd	ra,24(sp)
    800029e8:	e822                	sd	s0,16(sp)
    800029ea:	e426                	sd	s1,8(sp)
    800029ec:	1000                	addi	s0,sp,32
    800029ee:	84ae                	mv	s1,a1
  *ip = argraw(n);  // 通过 argraw 获取原始参数并存储
    800029f0:	eefff0ef          	jal	ra,800028de <argraw>
    800029f4:	e088                	sd	a0,0(s1)
}
    800029f6:	60e2                	ld	ra,24(sp)
    800029f8:	6442                	ld	s0,16(sp)
    800029fa:	64a2                	ld	s1,8(sp)
    800029fc:	6105                	addi	sp,sp,32
    800029fe:	8082                	ret

0000000080002a00 <argstr>:
// 获取第 n 个参数，假设它是一个以 null 结尾的字符串。
// 将该字符串拷贝到 buf 中，最多拷贝 max 个字符。
// 成功时返回字符串长度（包括 null），出错时返回 -1。
int
argstr(int n, char *buf, int max)
{
    80002a00:	7179                	addi	sp,sp,-48
    80002a02:	f406                	sd	ra,40(sp)
    80002a04:	f022                	sd	s0,32(sp)
    80002a06:	ec26                	sd	s1,24(sp)
    80002a08:	e84a                	sd	s2,16(sp)
    80002a0a:	1800                	addi	s0,sp,48
    80002a0c:	84ae                	mv	s1,a1
    80002a0e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);  // 获取第 n 个参数的地址
    80002a10:	fd840593          	addi	a1,s0,-40
    80002a14:	fd1ff0ef          	jal	ra,800029e4 <argaddr>
  return fetchstr(addr, buf, max);  // 使用 fetchstr 获取字符串内容
    80002a18:	864a                	mv	a2,s2
    80002a1a:	85a6                	mv	a1,s1
    80002a1c:	fd843503          	ld	a0,-40(s0)
    80002a20:	f69ff0ef          	jal	ra,80002988 <fetchstr>
}
    80002a24:	70a2                	ld	ra,40(sp)
    80002a26:	7402                	ld	s0,32(sp)
    80002a28:	64e2                	ld	s1,24(sp)
    80002a2a:	6942                	ld	s2,16(sp)
    80002a2c:	6145                	addi	sp,sp,48
    80002a2e:	8082                	ret

0000000080002a30 <syscall>:
};

// 系统调用的入口函数
void
syscall(void)
{
    80002a30:	1101                	addi	sp,sp,-32
    80002a32:	ec06                	sd	ra,24(sp)
    80002a34:	e822                	sd	s0,16(sp)
    80002a36:	e426                	sd	s1,8(sp)
    80002a38:	e04a                	sd	s2,0(sp)
    80002a3a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002a3c:	df9fe0ef          	jal	ra,80001834 <myproc>
    80002a40:	84aa                	mv	s1,a0

  num = p->trapframe->a7;  // 从 trapframe 中获取系统调用号
    80002a42:	05853903          	ld	s2,88(a0)
    80002a46:	0a893783          	ld	a5,168(s2)
    80002a4a:	0007869b          	sext.w	a3,a5
  // 检查系统调用号是否合法，且确保有对应的处理函数
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002a4e:	37fd                	addiw	a5,a5,-1
    80002a50:	4755                	li	a4,21
    80002a52:	00f76f63          	bltu	a4,a5,80002a70 <syscall+0x40>
    80002a56:	00369713          	slli	a4,a3,0x3
    80002a5a:	00005797          	auipc	a5,0x5
    80002a5e:	9a678793          	addi	a5,a5,-1626 # 80007400 <syscalls>
    80002a62:	97ba                	add	a5,a5,a4
    80002a64:	639c                	ld	a5,0(a5)
    80002a66:	c789                	beqz	a5,80002a70 <syscall+0x40>
    // 根据系统调用号查找对应的系统调用函数并调用
    // 系统调用的返回值会存储在 p->trapframe->a0 中
    p->trapframe->a0 = syscalls[num]();
    80002a68:	9782                	jalr	a5
    80002a6a:	06a93823          	sd	a0,112(s2)
    80002a6e:	a829                	j	80002a88 <syscall+0x58>
  } else {
    // 如果找不到有效的系统调用，打印错误信息
    printf("%d %s: unknown sys call %d\n",
    80002a70:	15848613          	addi	a2,s1,344
    80002a74:	588c                	lw	a1,48(s1)
    80002a76:	00005517          	auipc	a0,0x5
    80002a7a:	95250513          	addi	a0,a0,-1710 # 800073c8 <states.0+0x158>
    80002a7e:	a47fd0ef          	jal	ra,800004c4 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;  // 设置返回值为 -1 表示错误
    80002a82:	6cbc                	ld	a5,88(s1)
    80002a84:	577d                	li	a4,-1
    80002a86:	fbb8                	sd	a4,112(a5)
  }
}
    80002a88:	60e2                	ld	ra,24(sp)
    80002a8a:	6442                	ld	s0,16(sp)
    80002a8c:	64a2                	ld	s1,8(sp)
    80002a8e:	6902                	ld	s2,0(sp)
    80002a90:	6105                	addi	sp,sp,32
    80002a92:	8082                	ret

0000000080002a94 <sys_exit>:
#include "vm.h"

// 进程退出系统调用
uint64
sys_exit(void)
{
    80002a94:	1101                	addi	sp,sp,-32
    80002a96:	ec06                	sd	ra,24(sp)
    80002a98:	e822                	sd	s0,16(sp)
    80002a9a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);  // 获取退出码
    80002a9c:	fec40593          	addi	a1,s0,-20
    80002aa0:	4501                	li	a0,0
    80002aa2:	f27ff0ef          	jal	ra,800029c8 <argint>
  kexit(n);       // 调用内核的退出函数
    80002aa6:	fec42503          	lw	a0,-20(s0)
    80002aaa:	801ff0ef          	jal	ra,800022aa <kexit>
  return 0;       // 不会执行到这里
}
    80002aae:	4501                	li	a0,0
    80002ab0:	60e2                	ld	ra,24(sp)
    80002ab2:	6442                	ld	s0,16(sp)
    80002ab4:	6105                	addi	sp,sp,32
    80002ab6:	8082                	ret

0000000080002ab8 <sys_getpid>:

// 获取当前进程的进程ID
uint64
sys_getpid(void)
{
    80002ab8:	1141                	addi	sp,sp,-16
    80002aba:	e406                	sd	ra,8(sp)
    80002abc:	e022                	sd	s0,0(sp)
    80002abe:	0800                	addi	s0,sp,16
  return myproc()->pid;  // 返回当前进程的 PID
    80002ac0:	d75fe0ef          	jal	ra,80001834 <myproc>
}
    80002ac4:	5908                	lw	a0,48(a0)
    80002ac6:	60a2                	ld	ra,8(sp)
    80002ac8:	6402                	ld	s0,0(sp)
    80002aca:	0141                	addi	sp,sp,16
    80002acc:	8082                	ret

0000000080002ace <sys_fork>:

// 创建一个新的子进程
uint64
sys_fork(void)
{
    80002ace:	1141                	addi	sp,sp,-16
    80002ad0:	e406                	sd	ra,8(sp)
    80002ad2:	e022                	sd	s0,0(sp)
    80002ad4:	0800                	addi	s0,sp,16
  return kfork();  // 调用内核的 fork 函数
    80002ad6:	898ff0ef          	jal	ra,80001b6e <kfork>
}
    80002ada:	60a2                	ld	ra,8(sp)
    80002adc:	6402                	ld	s0,0(sp)
    80002ade:	0141                	addi	sp,sp,16
    80002ae0:	8082                	ret

0000000080002ae2 <sys_wait>:

// 等待子进程退出
uint64
sys_wait(void)
{
    80002ae2:	1101                	addi	sp,sp,-32
    80002ae4:	ec06                	sd	ra,24(sp)
    80002ae6:	e822                	sd	s0,16(sp)
    80002ae8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);  // 获取等待子进程状态的地址
    80002aea:	fe840593          	addi	a1,s0,-24
    80002aee:	4501                	li	a0,0
    80002af0:	ef5ff0ef          	jal	ra,800029e4 <argaddr>
  return kwait(p);  // 调用内核的 wait 函数
    80002af4:	fe843503          	ld	a0,-24(s0)
    80002af8:	b40ff0ef          	jal	ra,80001e38 <kwait>
}
    80002afc:	60e2                	ld	ra,24(sp)
    80002afe:	6442                	ld	s0,16(sp)
    80002b00:	6105                	addi	sp,sp,32
    80002b02:	8082                	ret

0000000080002b04 <sys_sbrk>:

// 扩展或收缩进程的内存
uint64
sys_sbrk(void)
{
    80002b04:	7179                	addi	sp,sp,-48
    80002b06:	f406                	sd	ra,40(sp)
    80002b08:	f022                	sd	s0,32(sp)
    80002b0a:	ec26                	sd	s1,24(sp)
    80002b0c:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);  // 获取内存增量
    80002b0e:	fd840593          	addi	a1,s0,-40
    80002b12:	4501                	li	a0,0
    80002b14:	eb5ff0ef          	jal	ra,800029c8 <argint>
  argint(1, &t);  // 获取是否懒加载标志
    80002b18:	fdc40593          	addi	a1,s0,-36
    80002b1c:	4505                	li	a0,1
    80002b1e:	eabff0ef          	jal	ra,800029c8 <argint>
  addr = myproc()->sz;  // 获取当前进程的内存大小
    80002b22:	d13fe0ef          	jal	ra,80001834 <myproc>
    80002b26:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {  // 如果是急切分配或要求收缩内存
    80002b28:	fdc42703          	lw	a4,-36(s0)
    80002b2c:	4785                	li	a5,1
    80002b2e:	02f70763          	beq	a4,a5,80002b5c <sys_sbrk+0x58>
    80002b32:	fd842783          	lw	a5,-40(s0)
    80002b36:	0207c363          	bltz	a5,80002b5c <sys_sbrk+0x58>
    if(growproc(n) < 0) {  // 调用内核的 growproc 函数调整内存
      return -1;  // 内存分配失败
    }
  } else {  // 如果是懒加载分配
    if(addr + n < addr)  // 防止内存溢出
    80002b3a:	97a6                	add	a5,a5,s1
    80002b3c:	0297ee63          	bltu	a5,s1,80002b78 <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)  // 限制内存的最大值
    80002b40:	02000737          	lui	a4,0x2000
    80002b44:	177d                	addi	a4,a4,-1
    80002b46:	0736                	slli	a4,a4,0xd
    80002b48:	02f76a63          	bltu	a4,a5,80002b7c <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;  // 调整进程的内存大小
    80002b4c:	ce9fe0ef          	jal	ra,80001834 <myproc>
    80002b50:	fd842703          	lw	a4,-40(s0)
    80002b54:	653c                	ld	a5,72(a0)
    80002b56:	97ba                	add	a5,a5,a4
    80002b58:	e53c                	sd	a5,72(a0)
    80002b5a:	a039                	j	80002b68 <sys_sbrk+0x64>
    if(growproc(n) < 0) {  // 调用内核的 growproc 函数调整内存
    80002b5c:	fd842503          	lw	a0,-40(s0)
    80002b60:	fadfe0ef          	jal	ra,80001b0c <growproc>
    80002b64:	00054863          	bltz	a0,80002b74 <sys_sbrk+0x70>
  }
  return addr;  // 返回原内存地址
}
    80002b68:	8526                	mv	a0,s1
    80002b6a:	70a2                	ld	ra,40(sp)
    80002b6c:	7402                	ld	s0,32(sp)
    80002b6e:	64e2                	ld	s1,24(sp)
    80002b70:	6145                	addi	sp,sp,48
    80002b72:	8082                	ret
      return -1;  // 内存分配失败
    80002b74:	54fd                	li	s1,-1
    80002b76:	bfcd                	j	80002b68 <sys_sbrk+0x64>
      return -1;
    80002b78:	54fd                	li	s1,-1
    80002b7a:	b7fd                	j	80002b68 <sys_sbrk+0x64>
      return -1;
    80002b7c:	54fd                	li	s1,-1
    80002b7e:	b7ed                	j	80002b68 <sys_sbrk+0x64>

0000000080002b80 <sys_pause>:

// 让当前进程挂起指定时间
uint64
sys_pause(void)
{
    80002b80:	7139                	addi	sp,sp,-64
    80002b82:	fc06                	sd	ra,56(sp)
    80002b84:	f822                	sd	s0,48(sp)
    80002b86:	f426                	sd	s1,40(sp)
    80002b88:	f04a                	sd	s2,32(sp)
    80002b8a:	ec4e                	sd	s3,24(sp)
    80002b8c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);  // 获取暂停的时长（以时钟滴答为单位）
    80002b8e:	fcc40593          	addi	a1,s0,-52
    80002b92:	4501                	li	a0,0
    80002b94:	e35ff0ef          	jal	ra,800029c8 <argint>
  if(n < 0)  // 如果给定的时长为负，则设置为 0
    80002b98:	fcc42783          	lw	a5,-52(s0)
    80002b9c:	0607c563          	bltz	a5,80002c06 <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);  // 获取时钟锁
    80002ba0:	00013517          	auipc	a0,0x13
    80002ba4:	2b850513          	addi	a0,a0,696 # 80015e58 <tickslock>
    80002ba8:	fc5fd0ef          	jal	ra,80000b6c <acquire>
  ticks0 = ticks;  // 记录当前的时钟滴答数
    80002bac:	00005917          	auipc	s2,0x5
    80002bb0:	cd492903          	lw	s2,-812(s2) # 80007880 <ticks>
  while(ticks - ticks0 < n){  // 持续等待直到经过了指定的时间
    80002bb4:	fcc42783          	lw	a5,-52(s0)
    80002bb8:	cb8d                	beqz	a5,80002bea <sys_pause+0x6a>
    if(killed(myproc())){  // 如果进程被杀死，退出等待
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);  // 进程进入休眠状态，等待时钟更新
    80002bba:	00013997          	auipc	s3,0x13
    80002bbe:	29e98993          	addi	s3,s3,670 # 80015e58 <tickslock>
    80002bc2:	00005497          	auipc	s1,0x5
    80002bc6:	cbe48493          	addi	s1,s1,-834 # 80007880 <ticks>
    if(killed(myproc())){  // 如果进程被杀死，退出等待
    80002bca:	c6bfe0ef          	jal	ra,80001834 <myproc>
    80002bce:	a40ff0ef          	jal	ra,80001e0e <killed>
    80002bd2:	ed0d                	bnez	a0,80002c0c <sys_pause+0x8c>
    sleep(&ticks, &tickslock);  // 进程进入休眠状态，等待时钟更新
    80002bd4:	85ce                	mv	a1,s3
    80002bd6:	8526                	mv	a0,s1
    80002bd8:	95cff0ef          	jal	ra,80001d34 <sleep>
  while(ticks - ticks0 < n){  // 持续等待直到经过了指定的时间
    80002bdc:	409c                	lw	a5,0(s1)
    80002bde:	412787bb          	subw	a5,a5,s2
    80002be2:	fcc42703          	lw	a4,-52(s0)
    80002be6:	fee7e2e3          	bltu	a5,a4,80002bca <sys_pause+0x4a>
  }
  release(&tickslock);  // 释放时钟锁
    80002bea:	00013517          	auipc	a0,0x13
    80002bee:	26e50513          	addi	a0,a0,622 # 80015e58 <tickslock>
    80002bf2:	812fe0ef          	jal	ra,80000c04 <release>
  return 0;  // 返回
    80002bf6:	4501                	li	a0,0
}
    80002bf8:	70e2                	ld	ra,56(sp)
    80002bfa:	7442                	ld	s0,48(sp)
    80002bfc:	74a2                	ld	s1,40(sp)
    80002bfe:	7902                	ld	s2,32(sp)
    80002c00:	69e2                	ld	s3,24(sp)
    80002c02:	6121                	addi	sp,sp,64
    80002c04:	8082                	ret
    n = 0;
    80002c06:	fc042623          	sw	zero,-52(s0)
    80002c0a:	bf59                	j	80002ba0 <sys_pause+0x20>
      release(&tickslock);
    80002c0c:	00013517          	auipc	a0,0x13
    80002c10:	24c50513          	addi	a0,a0,588 # 80015e58 <tickslock>
    80002c14:	ff1fd0ef          	jal	ra,80000c04 <release>
      return -1;
    80002c18:	557d                	li	a0,-1
    80002c1a:	bff9                	j	80002bf8 <sys_pause+0x78>

0000000080002c1c <sys_kill>:

// 终止指定进程
uint64
sys_kill(void)
{
    80002c1c:	1101                	addi	sp,sp,-32
    80002c1e:	ec06                	sd	ra,24(sp)
    80002c20:	e822                	sd	s0,16(sp)
    80002c22:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);  // 获取进程 ID
    80002c24:	fec40593          	addi	a1,s0,-20
    80002c28:	4501                	li	a0,0
    80002c2a:	d9fff0ef          	jal	ra,800029c8 <argint>
  return kkill(pid);  // 调用内核的 kill 函数终止进程
    80002c2e:	fec42503          	lw	a0,-20(s0)
    80002c32:	952ff0ef          	jal	ra,80001d84 <kkill>
}
    80002c36:	60e2                	ld	ra,24(sp)
    80002c38:	6442                	ld	s0,16(sp)
    80002c3a:	6105                	addi	sp,sp,32
    80002c3c:	8082                	ret

0000000080002c3e <sys_uptime>:

// 返回自系统启动以来经过的时钟滴答数
uint64
sys_uptime(void)
{
    80002c3e:	1101                	addi	sp,sp,-32
    80002c40:	ec06                	sd	ra,24(sp)
    80002c42:	e822                	sd	s0,16(sp)
    80002c44:	e426                	sd	s1,8(sp)
    80002c46:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);  // 获取时钟锁
    80002c48:	00013517          	auipc	a0,0x13
    80002c4c:	21050513          	addi	a0,a0,528 # 80015e58 <tickslock>
    80002c50:	f1dfd0ef          	jal	ra,80000b6c <acquire>
  xticks = ticks;  // 获取当前的时钟滴答数
    80002c54:	00005497          	auipc	s1,0x5
    80002c58:	c2c4a483          	lw	s1,-980(s1) # 80007880 <ticks>
  release(&tickslock);  // 释放时钟锁
    80002c5c:	00013517          	auipc	a0,0x13
    80002c60:	1fc50513          	addi	a0,a0,508 # 80015e58 <tickslock>
    80002c64:	fa1fd0ef          	jal	ra,80000c04 <release>
  return xticks;  // 返回时钟滴答数
}
    80002c68:	02049513          	slli	a0,s1,0x20
    80002c6c:	9101                	srli	a0,a0,0x20
    80002c6e:	60e2                	ld	ra,24(sp)
    80002c70:	6442                	ld	s0,16(sp)
    80002c72:	64a2                	ld	s1,8(sp)
    80002c74:	6105                	addi	sp,sp,32
    80002c76:	8082                	ret

0000000080002c78 <binit>:
} bcache;

// 初始化缓冲区缓存
void
binit(void)
{
    80002c78:	7179                	addi	sp,sp,-48
    80002c7a:	f406                	sd	ra,40(sp)
    80002c7c:	f022                	sd	s0,32(sp)
    80002c7e:	ec26                	sd	s1,24(sp)
    80002c80:	e84a                	sd	s2,16(sp)
    80002c82:	e44e                	sd	s3,8(sp)
    80002c84:	e052                	sd	s4,0(sp)
    80002c86:	1800                	addi	s0,sp,48
  struct buf *b;

  // 初始化缓冲区缓存的锁
  initlock(&bcache.lock, "bcache");
    80002c88:	00005597          	auipc	a1,0x5
    80002c8c:	83058593          	addi	a1,a1,-2000 # 800074b8 <syscalls+0xb8>
    80002c90:	00013517          	auipc	a0,0x13
    80002c94:	1e050513          	addi	a0,a0,480 # 80015e70 <bcache>
    80002c98:	e55fd0ef          	jal	ra,80000aec <initlock>

  // 创建缓冲区链表
  bcache.head.prev = &bcache.head;
    80002c9c:	0001b797          	auipc	a5,0x1b
    80002ca0:	1d478793          	addi	a5,a5,468 # 8001de70 <bcache+0x8000>
    80002ca4:	0001b717          	auipc	a4,0x1b
    80002ca8:	43470713          	addi	a4,a4,1076 # 8001e0d8 <bcache+0x8268>
    80002cac:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002cb0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf + NBUF; b++){
    80002cb4:	00013497          	auipc	s1,0x13
    80002cb8:	1d448493          	addi	s1,s1,468 # 80015e88 <bcache+0x18>
    b->next = bcache.head.next;
    80002cbc:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002cbe:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");  // 初始化缓冲区的睡眠锁
    80002cc0:	00005a17          	auipc	s4,0x5
    80002cc4:	800a0a13          	addi	s4,s4,-2048 # 800074c0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002cc8:	2b893783          	ld	a5,696(s2)
    80002ccc:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002cce:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");  // 初始化缓冲区的睡眠锁
    80002cd2:	85d2                	mv	a1,s4
    80002cd4:	01048513          	addi	a0,s1,16
    80002cd8:	2fe010ef          	jal	ra,80003fd6 <initsleeplock>
    bcache.head.next->prev = b;
    80002cdc:	2b893783          	ld	a5,696(s2)
    80002ce0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ce2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf + NBUF; b++){
    80002ce6:	45848493          	addi	s1,s1,1112
    80002cea:	fd349fe3          	bne	s1,s3,80002cc8 <binit+0x50>
  }
}
    80002cee:	70a2                	ld	ra,40(sp)
    80002cf0:	7402                	ld	s0,32(sp)
    80002cf2:	64e2                	ld	s1,24(sp)
    80002cf4:	6942                	ld	s2,16(sp)
    80002cf6:	69a2                	ld	s3,8(sp)
    80002cf8:	6a02                	ld	s4,0(sp)
    80002cfa:	6145                	addi	sp,sp,48
    80002cfc:	8082                	ret

0000000080002cfe <bread>:
}

// 获取指定磁盘块的缓冲区并返回，内容从磁盘读取
struct buf*
bread(uint dev, uint blockno)
{
    80002cfe:	7179                	addi	sp,sp,-48
    80002d00:	f406                	sd	ra,40(sp)
    80002d02:	f022                	sd	s0,32(sp)
    80002d04:	ec26                	sd	s1,24(sp)
    80002d06:	e84a                	sd	s2,16(sp)
    80002d08:	e44e                	sd	s3,8(sp)
    80002d0a:	1800                	addi	s0,sp,48
    80002d0c:	892a                	mv	s2,a0
    80002d0e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002d10:	00013517          	auipc	a0,0x13
    80002d14:	16050513          	addi	a0,a0,352 # 80015e70 <bcache>
    80002d18:	e55fd0ef          	jal	ra,80000b6c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002d1c:	0001b497          	auipc	s1,0x1b
    80002d20:	40c4b483          	ld	s1,1036(s1) # 8001e128 <bcache+0x82b8>
    80002d24:	0001b797          	auipc	a5,0x1b
    80002d28:	3b478793          	addi	a5,a5,948 # 8001e0d8 <bcache+0x8268>
    80002d2c:	02f48b63          	beq	s1,a5,80002d62 <bread+0x64>
    80002d30:	873e                	mv	a4,a5
    80002d32:	a021                	j	80002d3a <bread+0x3c>
    80002d34:	68a4                	ld	s1,80(s1)
    80002d36:	02e48663          	beq	s1,a4,80002d62 <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002d3a:	449c                	lw	a5,8(s1)
    80002d3c:	ff279ce3          	bne	a5,s2,80002d34 <bread+0x36>
    80002d40:	44dc                	lw	a5,12(s1)
    80002d42:	ff3799e3          	bne	a5,s3,80002d34 <bread+0x36>
      b->refcnt++;  // 增加引用计数
    80002d46:	40bc                	lw	a5,64(s1)
    80002d48:	2785                	addiw	a5,a5,1
    80002d4a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002d4c:	00013517          	auipc	a0,0x13
    80002d50:	12450513          	addi	a0,a0,292 # 80015e70 <bcache>
    80002d54:	eb1fd0ef          	jal	ra,80000c04 <release>
      acquiresleep(&b->lock);  // 获取缓冲区的睡眠锁
    80002d58:	01048513          	addi	a0,s1,16
    80002d5c:	2b0010ef          	jal	ra,8000400c <acquiresleep>
      return b;  // 返回缓冲区
    80002d60:	a889                	j	80002db2 <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002d62:	0001b497          	auipc	s1,0x1b
    80002d66:	3be4b483          	ld	s1,958(s1) # 8001e120 <bcache+0x82b0>
    80002d6a:	0001b797          	auipc	a5,0x1b
    80002d6e:	36e78793          	addi	a5,a5,878 # 8001e0d8 <bcache+0x8268>
    80002d72:	00f48863          	beq	s1,a5,80002d82 <bread+0x84>
    80002d76:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002d78:	40bc                	lw	a5,64(s1)
    80002d7a:	cb91                	beqz	a5,80002d8e <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002d7c:	64a4                	ld	s1,72(s1)
    80002d7e:	fee49de3          	bne	s1,a4,80002d78 <bread+0x7a>
  panic("bget: no buffers");  // 如果没有找到可用的缓冲区，发生错误
    80002d82:	00004517          	auipc	a0,0x4
    80002d86:	74650513          	addi	a0,a0,1862 # 800074c8 <syscalls+0xc8>
    80002d8a:	a01fd0ef          	jal	ra,8000078a <panic>
      b->dev = dev;  // 设置设备号
    80002d8e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;  // 设置块号
    80002d92:	0134a623          	sw	s3,12(s1)
      b->valid = 0;  // 设置为无效
    80002d96:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;  // 引用计数设置为 1
    80002d9a:	4785                	li	a5,1
    80002d9c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002d9e:	00013517          	auipc	a0,0x13
    80002da2:	0d250513          	addi	a0,a0,210 # 80015e70 <bcache>
    80002da6:	e5ffd0ef          	jal	ra,80000c04 <release>
      acquiresleep(&b->lock);  // 获取缓冲区的睡眠锁
    80002daa:	01048513          	addi	a0,s1,16
    80002dae:	25e010ef          	jal	ra,8000400c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);  // 获取缓冲区
  if(!b->valid) {
    80002db2:	409c                	lw	a5,0(s1)
    80002db4:	cb89                	beqz	a5,80002dc6 <bread+0xc8>
    virtio_disk_rw(b, 0);  // 从磁盘读取数据到缓冲区
    b->valid = 1;  // 设置缓冲区为有效
  }
  return b;  // 返回缓冲区
}
    80002db6:	8526                	mv	a0,s1
    80002db8:	70a2                	ld	ra,40(sp)
    80002dba:	7402                	ld	s0,32(sp)
    80002dbc:	64e2                	ld	s1,24(sp)
    80002dbe:	6942                	ld	s2,16(sp)
    80002dc0:	69a2                	ld	s3,8(sp)
    80002dc2:	6145                	addi	sp,sp,48
    80002dc4:	8082                	ret
    virtio_disk_rw(b, 0);  // 从磁盘读取数据到缓冲区
    80002dc6:	4581                	li	a1,0
    80002dc8:	8526                	mv	a0,s1
    80002dca:	1b3020ef          	jal	ra,8000577c <virtio_disk_rw>
    b->valid = 1;  // 设置缓冲区为有效
    80002dce:	4785                	li	a5,1
    80002dd0:	c09c                	sw	a5,0(s1)
  return b;  // 返回缓冲区
    80002dd2:	b7d5                	j	80002db6 <bread+0xb8>

0000000080002dd4 <bwrite>:

// 将缓冲区 b 的内容写入磁盘，必须先锁定缓冲区
void
bwrite(struct buf *b)
{
    80002dd4:	1101                	addi	sp,sp,-32
    80002dd6:	ec06                	sd	ra,24(sp)
    80002dd8:	e822                	sd	s0,16(sp)
    80002dda:	e426                	sd	s1,8(sp)
    80002ddc:	1000                	addi	s0,sp,32
    80002dde:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002de0:	0541                	addi	a0,a0,16
    80002de2:	2a8010ef          	jal	ra,8000408a <holdingsleep>
    80002de6:	c911                	beqz	a0,80002dfa <bwrite+0x26>
    panic("bwrite");  // 检查是否持有缓冲区的锁
  virtio_disk_rw(b, 1);  // 将缓冲区内容写入磁盘
    80002de8:	4585                	li	a1,1
    80002dea:	8526                	mv	a0,s1
    80002dec:	191020ef          	jal	ra,8000577c <virtio_disk_rw>
}
    80002df0:	60e2                	ld	ra,24(sp)
    80002df2:	6442                	ld	s0,16(sp)
    80002df4:	64a2                	ld	s1,8(sp)
    80002df6:	6105                	addi	sp,sp,32
    80002df8:	8082                	ret
    panic("bwrite");  // 检查是否持有缓冲区的锁
    80002dfa:	00004517          	auipc	a0,0x4
    80002dfe:	6e650513          	addi	a0,a0,1766 # 800074e0 <syscalls+0xe0>
    80002e02:	989fd0ef          	jal	ra,8000078a <panic>

0000000080002e06 <brelse>:

// 释放锁定的缓冲区，并将其移到最近使用的位置
void
brelse(struct buf *b)
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	e426                	sd	s1,8(sp)
    80002e0e:	e04a                	sd	s2,0(sp)
    80002e10:	1000                	addi	s0,sp,32
    80002e12:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002e14:	01050913          	addi	s2,a0,16
    80002e18:	854a                	mv	a0,s2
    80002e1a:	270010ef          	jal	ra,8000408a <holdingsleep>
    80002e1e:	c13d                	beqz	a0,80002e84 <brelse+0x7e>
    panic("brelse");  // 检查是否持有缓冲区的锁

  releasesleep(&b->lock);  // 释放缓冲区的睡眠锁
    80002e20:	854a                	mv	a0,s2
    80002e22:	230010ef          	jal	ra,80004052 <releasesleep>

  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002e26:	00013517          	auipc	a0,0x13
    80002e2a:	04a50513          	addi	a0,a0,74 # 80015e70 <bcache>
    80002e2e:	d3ffd0ef          	jal	ra,80000b6c <acquire>
  b->refcnt--;  // 减少引用计数
    80002e32:	40bc                	lw	a5,64(s1)
    80002e34:	37fd                	addiw	a5,a5,-1
    80002e36:	0007871b          	sext.w	a4,a5
    80002e3a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002e3c:	eb05                	bnez	a4,80002e6c <brelse+0x66>
    // 如果没有其他进程在使用该缓冲区
    // 将缓冲区移到链表头部
    b->next->prev = b->prev;
    80002e3e:	68bc                	ld	a5,80(s1)
    80002e40:	64b8                	ld	a4,72(s1)
    80002e42:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002e44:	64bc                	ld	a5,72(s1)
    80002e46:	68b8                	ld	a4,80(s1)
    80002e48:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002e4a:	0001b797          	auipc	a5,0x1b
    80002e4e:	02678793          	addi	a5,a5,38 # 8001de70 <bcache+0x8000>
    80002e52:	2b87b703          	ld	a4,696(a5)
    80002e56:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002e58:	0001b717          	auipc	a4,0x1b
    80002e5c:	28070713          	addi	a4,a4,640 # 8001e0d8 <bcache+0x8268>
    80002e60:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002e62:	2b87b703          	ld	a4,696(a5)
    80002e66:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002e68:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002e6c:	00013517          	auipc	a0,0x13
    80002e70:	00450513          	addi	a0,a0,4 # 80015e70 <bcache>
    80002e74:	d91fd0ef          	jal	ra,80000c04 <release>
}
    80002e78:	60e2                	ld	ra,24(sp)
    80002e7a:	6442                	ld	s0,16(sp)
    80002e7c:	64a2                	ld	s1,8(sp)
    80002e7e:	6902                	ld	s2,0(sp)
    80002e80:	6105                	addi	sp,sp,32
    80002e82:	8082                	ret
    panic("brelse");  // 检查是否持有缓冲区的锁
    80002e84:	00004517          	auipc	a0,0x4
    80002e88:	66450513          	addi	a0,a0,1636 # 800074e8 <syscalls+0xe8>
    80002e8c:	8fffd0ef          	jal	ra,8000078a <panic>

0000000080002e90 <bpin>:

// 增加缓冲区 b 的引用计数，用于防止缓冲区被释放
void
bpin(struct buf *b) {
    80002e90:	1101                	addi	sp,sp,-32
    80002e92:	ec06                	sd	ra,24(sp)
    80002e94:	e822                	sd	s0,16(sp)
    80002e96:	e426                	sd	s1,8(sp)
    80002e98:	1000                	addi	s0,sp,32
    80002e9a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002e9c:	00013517          	auipc	a0,0x13
    80002ea0:	fd450513          	addi	a0,a0,-44 # 80015e70 <bcache>
    80002ea4:	cc9fd0ef          	jal	ra,80000b6c <acquire>
  b->refcnt++;  // 增加引用计数
    80002ea8:	40bc                	lw	a5,64(s1)
    80002eaa:	2785                	addiw	a5,a5,1
    80002eac:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002eae:	00013517          	auipc	a0,0x13
    80002eb2:	fc250513          	addi	a0,a0,-62 # 80015e70 <bcache>
    80002eb6:	d4ffd0ef          	jal	ra,80000c04 <release>
}
    80002eba:	60e2                	ld	ra,24(sp)
    80002ebc:	6442                	ld	s0,16(sp)
    80002ebe:	64a2                	ld	s1,8(sp)
    80002ec0:	6105                	addi	sp,sp,32
    80002ec2:	8082                	ret

0000000080002ec4 <bunpin>:

// 减少缓冲区 b 的引用计数，用于缓冲区的释放
void
bunpin(struct buf *b) {
    80002ec4:	1101                	addi	sp,sp,-32
    80002ec6:	ec06                	sd	ra,24(sp)
    80002ec8:	e822                	sd	s0,16(sp)
    80002eca:	e426                	sd	s1,8(sp)
    80002ecc:	1000                	addi	s0,sp,32
    80002ece:	84aa                	mv	s1,a0
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002ed0:	00013517          	auipc	a0,0x13
    80002ed4:	fa050513          	addi	a0,a0,-96 # 80015e70 <bcache>
    80002ed8:	c95fd0ef          	jal	ra,80000b6c <acquire>
  b->refcnt--;  // 减少引用计数
    80002edc:	40bc                	lw	a5,64(s1)
    80002ede:	37fd                	addiw	a5,a5,-1
    80002ee0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002ee2:	00013517          	auipc	a0,0x13
    80002ee6:	f8e50513          	addi	a0,a0,-114 # 80015e70 <bcache>
    80002eea:	d1bfd0ef          	jal	ra,80000c04 <release>
}
    80002eee:	60e2                	ld	ra,24(sp)
    80002ef0:	6442                	ld	s0,16(sp)
    80002ef2:	64a2                	ld	s1,8(sp)
    80002ef4:	6105                	addi	sp,sp,32
    80002ef6:	8082                	ret

0000000080002ef8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002ef8:	1101                	addi	sp,sp,-32
    80002efa:	ec06                	sd	ra,24(sp)
    80002efc:	e822                	sd	s0,16(sp)
    80002efe:	e426                	sd	s1,8(sp)
    80002f00:	e04a                	sd	s2,0(sp)
    80002f02:	1000                	addi	s0,sp,32
    80002f04:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002f06:	00d5d59b          	srliw	a1,a1,0xd
    80002f0a:	0001b797          	auipc	a5,0x1b
    80002f0e:	6427a783          	lw	a5,1602(a5) # 8001e54c <sb+0x1c>
    80002f12:	9dbd                	addw	a1,a1,a5
    80002f14:	debff0ef          	jal	ra,80002cfe <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002f18:	0074f713          	andi	a4,s1,7
    80002f1c:	4785                	li	a5,1
    80002f1e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80002f22:	14ce                	slli	s1,s1,0x33
    80002f24:	90d9                	srli	s1,s1,0x36
    80002f26:	00950733          	add	a4,a0,s1
    80002f2a:	05874703          	lbu	a4,88(a4)
    80002f2e:	00e7f6b3          	and	a3,a5,a4
    80002f32:	c29d                	beqz	a3,80002f58 <bfree+0x60>
    80002f34:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002f36:	94aa                	add	s1,s1,a0
    80002f38:	fff7c793          	not	a5,a5
    80002f3c:	8ff9                	and	a5,a5,a4
    80002f3e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80002f42:	7d1000ef          	jal	ra,80003f12 <log_write>
  brelse(bp);
    80002f46:	854a                	mv	a0,s2
    80002f48:	ebfff0ef          	jal	ra,80002e06 <brelse>
}
    80002f4c:	60e2                	ld	ra,24(sp)
    80002f4e:	6442                	ld	s0,16(sp)
    80002f50:	64a2                	ld	s1,8(sp)
    80002f52:	6902                	ld	s2,0(sp)
    80002f54:	6105                	addi	sp,sp,32
    80002f56:	8082                	ret
    panic("freeing free block");
    80002f58:	00004517          	auipc	a0,0x4
    80002f5c:	59850513          	addi	a0,a0,1432 # 800074f0 <syscalls+0xf0>
    80002f60:	82bfd0ef          	jal	ra,8000078a <panic>

0000000080002f64 <balloc>:
{
    80002f64:	711d                	addi	sp,sp,-96
    80002f66:	ec86                	sd	ra,88(sp)
    80002f68:	e8a2                	sd	s0,80(sp)
    80002f6a:	e4a6                	sd	s1,72(sp)
    80002f6c:	e0ca                	sd	s2,64(sp)
    80002f6e:	fc4e                	sd	s3,56(sp)
    80002f70:	f852                	sd	s4,48(sp)
    80002f72:	f456                	sd	s5,40(sp)
    80002f74:	f05a                	sd	s6,32(sp)
    80002f76:	ec5e                	sd	s7,24(sp)
    80002f78:	e862                	sd	s8,16(sp)
    80002f7a:	e466                	sd	s9,8(sp)
    80002f7c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80002f7e:	0001b797          	auipc	a5,0x1b
    80002f82:	5b67a783          	lw	a5,1462(a5) # 8001e534 <sb+0x4>
    80002f86:	0e078163          	beqz	a5,80003068 <balloc+0x104>
    80002f8a:	8baa                	mv	s7,a0
    80002f8c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80002f8e:	0001bb17          	auipc	s6,0x1b
    80002f92:	5a2b0b13          	addi	s6,s6,1442 # 8001e530 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002f96:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80002f98:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002f9a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80002f9c:	6c89                	lui	s9,0x2
    80002f9e:	a0b5                	j	8000300a <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    80002fa0:	974a                	add	a4,a4,s2
    80002fa2:	8fd5                	or	a5,a5,a3
    80002fa4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80002fa8:	854a                	mv	a0,s2
    80002faa:	769000ef          	jal	ra,80003f12 <log_write>
        brelse(bp);
    80002fae:	854a                	mv	a0,s2
    80002fb0:	e57ff0ef          	jal	ra,80002e06 <brelse>
  bp = bread(dev, bno);
    80002fb4:	85a6                	mv	a1,s1
    80002fb6:	855e                	mv	a0,s7
    80002fb8:	d47ff0ef          	jal	ra,80002cfe <bread>
    80002fbc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80002fbe:	40000613          	li	a2,1024
    80002fc2:	4581                	li	a1,0
    80002fc4:	05850513          	addi	a0,a0,88
    80002fc8:	c79fd0ef          	jal	ra,80000c40 <memset>
  log_write(bp);
    80002fcc:	854a                	mv	a0,s2
    80002fce:	745000ef          	jal	ra,80003f12 <log_write>
  brelse(bp);
    80002fd2:	854a                	mv	a0,s2
    80002fd4:	e33ff0ef          	jal	ra,80002e06 <brelse>
}
    80002fd8:	8526                	mv	a0,s1
    80002fda:	60e6                	ld	ra,88(sp)
    80002fdc:	6446                	ld	s0,80(sp)
    80002fde:	64a6                	ld	s1,72(sp)
    80002fe0:	6906                	ld	s2,64(sp)
    80002fe2:	79e2                	ld	s3,56(sp)
    80002fe4:	7a42                	ld	s4,48(sp)
    80002fe6:	7aa2                	ld	s5,40(sp)
    80002fe8:	7b02                	ld	s6,32(sp)
    80002fea:	6be2                	ld	s7,24(sp)
    80002fec:	6c42                	ld	s8,16(sp)
    80002fee:	6ca2                	ld	s9,8(sp)
    80002ff0:	6125                	addi	sp,sp,96
    80002ff2:	8082                	ret
    brelse(bp);
    80002ff4:	854a                	mv	a0,s2
    80002ff6:	e11ff0ef          	jal	ra,80002e06 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80002ffa:	015c87bb          	addw	a5,s9,s5
    80002ffe:	00078a9b          	sext.w	s5,a5
    80003002:	004b2703          	lw	a4,4(s6)
    80003006:	06eaf163          	bgeu	s5,a4,80003068 <balloc+0x104>
    bp = bread(dev, BBLOCK(b, sb));
    8000300a:	41fad79b          	sraiw	a5,s5,0x1f
    8000300e:	0137d79b          	srliw	a5,a5,0x13
    80003012:	015787bb          	addw	a5,a5,s5
    80003016:	40d7d79b          	sraiw	a5,a5,0xd
    8000301a:	01cb2583          	lw	a1,28(s6)
    8000301e:	9dbd                	addw	a1,a1,a5
    80003020:	855e                	mv	a0,s7
    80003022:	cddff0ef          	jal	ra,80002cfe <bread>
    80003026:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003028:	004b2503          	lw	a0,4(s6)
    8000302c:	000a849b          	sext.w	s1,s5
    80003030:	8662                	mv	a2,s8
    80003032:	fca4f1e3          	bgeu	s1,a0,80002ff4 <balloc+0x90>
      m = 1 << (bi % 8);
    80003036:	41f6579b          	sraiw	a5,a2,0x1f
    8000303a:	01d7d69b          	srliw	a3,a5,0x1d
    8000303e:	00c6873b          	addw	a4,a3,a2
    80003042:	00777793          	andi	a5,a4,7
    80003046:	9f95                	subw	a5,a5,a3
    80003048:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000304c:	4037571b          	sraiw	a4,a4,0x3
    80003050:	00e906b3          	add	a3,s2,a4
    80003054:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    80003058:	00d7f5b3          	and	a1,a5,a3
    8000305c:	d1b1                	beqz	a1,80002fa0 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000305e:	2605                	addiw	a2,a2,1
    80003060:	2485                	addiw	s1,s1,1
    80003062:	fd4618e3          	bne	a2,s4,80003032 <balloc+0xce>
    80003066:	b779                	j	80002ff4 <balloc+0x90>
  printf("balloc: out of blocks\n");
    80003068:	00004517          	auipc	a0,0x4
    8000306c:	4a050513          	addi	a0,a0,1184 # 80007508 <syscalls+0x108>
    80003070:	c54fd0ef          	jal	ra,800004c4 <printf>
  return 0;
    80003074:	4481                	li	s1,0
    80003076:	b78d                	j	80002fd8 <balloc+0x74>

0000000080003078 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003078:	7179                	addi	sp,sp,-48
    8000307a:	f406                	sd	ra,40(sp)
    8000307c:	f022                	sd	s0,32(sp)
    8000307e:	ec26                	sd	s1,24(sp)
    80003080:	e84a                	sd	s2,16(sp)
    80003082:	e44e                	sd	s3,8(sp)
    80003084:	e052                	sd	s4,0(sp)
    80003086:	1800                	addi	s0,sp,48
    80003088:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000308a:	47ad                	li	a5,11
    8000308c:	02b7e563          	bltu	a5,a1,800030b6 <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    80003090:	02059493          	slli	s1,a1,0x20
    80003094:	9081                	srli	s1,s1,0x20
    80003096:	048a                	slli	s1,s1,0x2
    80003098:	94aa                	add	s1,s1,a0
    8000309a:	0504a903          	lw	s2,80(s1)
    8000309e:	06091663          	bnez	s2,8000310a <bmap+0x92>
      addr = balloc(ip->dev);
    800030a2:	4108                	lw	a0,0(a0)
    800030a4:	ec1ff0ef          	jal	ra,80002f64 <balloc>
    800030a8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800030ac:	04090f63          	beqz	s2,8000310a <bmap+0x92>
        return 0;
      ip->addrs[bn] = addr;
    800030b0:	0524a823          	sw	s2,80(s1)
    800030b4:	a899                	j	8000310a <bmap+0x92>
    }
    return addr;
  }
  bn -= NDIRECT;
    800030b6:	ff45849b          	addiw	s1,a1,-12
    800030ba:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800030be:	0ff00793          	li	a5,255
    800030c2:	06e7eb63          	bltu	a5,a4,80003138 <bmap+0xc0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800030c6:	08052903          	lw	s2,128(a0)
    800030ca:	00091b63          	bnez	s2,800030e0 <bmap+0x68>
      addr = balloc(ip->dev);
    800030ce:	4108                	lw	a0,0(a0)
    800030d0:	e95ff0ef          	jal	ra,80002f64 <balloc>
    800030d4:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800030d8:	02090963          	beqz	s2,8000310a <bmap+0x92>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800030dc:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800030e0:	85ca                	mv	a1,s2
    800030e2:	0009a503          	lw	a0,0(s3)
    800030e6:	c19ff0ef          	jal	ra,80002cfe <bread>
    800030ea:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800030ec:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800030f0:	02049593          	slli	a1,s1,0x20
    800030f4:	9181                	srli	a1,a1,0x20
    800030f6:	058a                	slli	a1,a1,0x2
    800030f8:	00b784b3          	add	s1,a5,a1
    800030fc:	0004a903          	lw	s2,0(s1)
    80003100:	00090e63          	beqz	s2,8000311c <bmap+0xa4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003104:	8552                	mv	a0,s4
    80003106:	d01ff0ef          	jal	ra,80002e06 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000310a:	854a                	mv	a0,s2
    8000310c:	70a2                	ld	ra,40(sp)
    8000310e:	7402                	ld	s0,32(sp)
    80003110:	64e2                	ld	s1,24(sp)
    80003112:	6942                	ld	s2,16(sp)
    80003114:	69a2                	ld	s3,8(sp)
    80003116:	6a02                	ld	s4,0(sp)
    80003118:	6145                	addi	sp,sp,48
    8000311a:	8082                	ret
      addr = balloc(ip->dev);
    8000311c:	0009a503          	lw	a0,0(s3)
    80003120:	e45ff0ef          	jal	ra,80002f64 <balloc>
    80003124:	0005091b          	sext.w	s2,a0
      if(addr){
    80003128:	fc090ee3          	beqz	s2,80003104 <bmap+0x8c>
        a[bn] = addr;
    8000312c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003130:	8552                	mv	a0,s4
    80003132:	5e1000ef          	jal	ra,80003f12 <log_write>
    80003136:	b7f9                	j	80003104 <bmap+0x8c>
  panic("bmap: out of range");
    80003138:	00004517          	auipc	a0,0x4
    8000313c:	3e850513          	addi	a0,a0,1000 # 80007520 <syscalls+0x120>
    80003140:	e4afd0ef          	jal	ra,8000078a <panic>

0000000080003144 <iget>:
{
    80003144:	7179                	addi	sp,sp,-48
    80003146:	f406                	sd	ra,40(sp)
    80003148:	f022                	sd	s0,32(sp)
    8000314a:	ec26                	sd	s1,24(sp)
    8000314c:	e84a                	sd	s2,16(sp)
    8000314e:	e44e                	sd	s3,8(sp)
    80003150:	e052                	sd	s4,0(sp)
    80003152:	1800                	addi	s0,sp,48
    80003154:	89aa                	mv	s3,a0
    80003156:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003158:	0001b517          	auipc	a0,0x1b
    8000315c:	3f850513          	addi	a0,a0,1016 # 8001e550 <itable>
    80003160:	a0dfd0ef          	jal	ra,80000b6c <acquire>
  empty = 0;
    80003164:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003166:	0001b497          	auipc	s1,0x1b
    8000316a:	40248493          	addi	s1,s1,1026 # 8001e568 <itable+0x18>
    8000316e:	0001d697          	auipc	a3,0x1d
    80003172:	e8a68693          	addi	a3,a3,-374 # 8001fff8 <log>
    80003176:	a039                	j	80003184 <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003178:	02090963          	beqz	s2,800031aa <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000317c:	08848493          	addi	s1,s1,136
    80003180:	02d48863          	beq	s1,a3,800031b0 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003184:	449c                	lw	a5,8(s1)
    80003186:	fef059e3          	blez	a5,80003178 <iget+0x34>
    8000318a:	4098                	lw	a4,0(s1)
    8000318c:	ff3716e3          	bne	a4,s3,80003178 <iget+0x34>
    80003190:	40d8                	lw	a4,4(s1)
    80003192:	ff4713e3          	bne	a4,s4,80003178 <iget+0x34>
      ip->ref++;
    80003196:	2785                	addiw	a5,a5,1
    80003198:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000319a:	0001b517          	auipc	a0,0x1b
    8000319e:	3b650513          	addi	a0,a0,950 # 8001e550 <itable>
    800031a2:	a63fd0ef          	jal	ra,80000c04 <release>
      return ip;
    800031a6:	8926                	mv	s2,s1
    800031a8:	a02d                	j	800031d2 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800031aa:	fbe9                	bnez	a5,8000317c <iget+0x38>
    800031ac:	8926                	mv	s2,s1
    800031ae:	b7f9                	j	8000317c <iget+0x38>
  if(empty == 0)
    800031b0:	02090a63          	beqz	s2,800031e4 <iget+0xa0>
  ip->dev = dev;
    800031b4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800031b8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800031bc:	4785                	li	a5,1
    800031be:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800031c2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800031c6:	0001b517          	auipc	a0,0x1b
    800031ca:	38a50513          	addi	a0,a0,906 # 8001e550 <itable>
    800031ce:	a37fd0ef          	jal	ra,80000c04 <release>
}
    800031d2:	854a                	mv	a0,s2
    800031d4:	70a2                	ld	ra,40(sp)
    800031d6:	7402                	ld	s0,32(sp)
    800031d8:	64e2                	ld	s1,24(sp)
    800031da:	6942                	ld	s2,16(sp)
    800031dc:	69a2                	ld	s3,8(sp)
    800031de:	6a02                	ld	s4,0(sp)
    800031e0:	6145                	addi	sp,sp,48
    800031e2:	8082                	ret
    panic("iget: no inodes");
    800031e4:	00004517          	auipc	a0,0x4
    800031e8:	35450513          	addi	a0,a0,852 # 80007538 <syscalls+0x138>
    800031ec:	d9efd0ef          	jal	ra,8000078a <panic>

00000000800031f0 <iinit>:
{
    800031f0:	7179                	addi	sp,sp,-48
    800031f2:	f406                	sd	ra,40(sp)
    800031f4:	f022                	sd	s0,32(sp)
    800031f6:	ec26                	sd	s1,24(sp)
    800031f8:	e84a                	sd	s2,16(sp)
    800031fa:	e44e                	sd	s3,8(sp)
    800031fc:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800031fe:	00004597          	auipc	a1,0x4
    80003202:	34a58593          	addi	a1,a1,842 # 80007548 <syscalls+0x148>
    80003206:	0001b517          	auipc	a0,0x1b
    8000320a:	34a50513          	addi	a0,a0,842 # 8001e550 <itable>
    8000320e:	8dffd0ef          	jal	ra,80000aec <initlock>
  for(i = 0; i < NINODE; i++) {
    80003212:	0001b497          	auipc	s1,0x1b
    80003216:	36648493          	addi	s1,s1,870 # 8001e578 <itable+0x28>
    8000321a:	0001d997          	auipc	s3,0x1d
    8000321e:	dee98993          	addi	s3,s3,-530 # 80020008 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003222:	00004917          	auipc	s2,0x4
    80003226:	32e90913          	addi	s2,s2,814 # 80007550 <syscalls+0x150>
    8000322a:	85ca                	mv	a1,s2
    8000322c:	8526                	mv	a0,s1
    8000322e:	5a9000ef          	jal	ra,80003fd6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003232:	08848493          	addi	s1,s1,136
    80003236:	ff349ae3          	bne	s1,s3,8000322a <iinit+0x3a>
}
    8000323a:	70a2                	ld	ra,40(sp)
    8000323c:	7402                	ld	s0,32(sp)
    8000323e:	64e2                	ld	s1,24(sp)
    80003240:	6942                	ld	s2,16(sp)
    80003242:	69a2                	ld	s3,8(sp)
    80003244:	6145                	addi	sp,sp,48
    80003246:	8082                	ret

0000000080003248 <ialloc>:
{
    80003248:	715d                	addi	sp,sp,-80
    8000324a:	e486                	sd	ra,72(sp)
    8000324c:	e0a2                	sd	s0,64(sp)
    8000324e:	fc26                	sd	s1,56(sp)
    80003250:	f84a                	sd	s2,48(sp)
    80003252:	f44e                	sd	s3,40(sp)
    80003254:	f052                	sd	s4,32(sp)
    80003256:	ec56                	sd	s5,24(sp)
    80003258:	e85a                	sd	s6,16(sp)
    8000325a:	e45e                	sd	s7,8(sp)
    8000325c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000325e:	0001b717          	auipc	a4,0x1b
    80003262:	2de72703          	lw	a4,734(a4) # 8001e53c <sb+0xc>
    80003266:	4785                	li	a5,1
    80003268:	04e7f663          	bgeu	a5,a4,800032b4 <ialloc+0x6c>
    8000326c:	8aaa                	mv	s5,a0
    8000326e:	8bae                	mv	s7,a1
    80003270:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003272:	0001ba17          	auipc	s4,0x1b
    80003276:	2bea0a13          	addi	s4,s4,702 # 8001e530 <sb>
    8000327a:	00048b1b          	sext.w	s6,s1
    8000327e:	0044d793          	srli	a5,s1,0x4
    80003282:	018a2583          	lw	a1,24(s4)
    80003286:	9dbd                	addw	a1,a1,a5
    80003288:	8556                	mv	a0,s5
    8000328a:	a75ff0ef          	jal	ra,80002cfe <bread>
    8000328e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003290:	05850993          	addi	s3,a0,88
    80003294:	00f4f793          	andi	a5,s1,15
    80003298:	079a                	slli	a5,a5,0x6
    8000329a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000329c:	00099783          	lh	a5,0(s3)
    800032a0:	cf85                	beqz	a5,800032d8 <ialloc+0x90>
    brelse(bp);
    800032a2:	b65ff0ef          	jal	ra,80002e06 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800032a6:	0485                	addi	s1,s1,1
    800032a8:	00ca2703          	lw	a4,12(s4)
    800032ac:	0004879b          	sext.w	a5,s1
    800032b0:	fce7e5e3          	bltu	a5,a4,8000327a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800032b4:	00004517          	auipc	a0,0x4
    800032b8:	2a450513          	addi	a0,a0,676 # 80007558 <syscalls+0x158>
    800032bc:	a08fd0ef          	jal	ra,800004c4 <printf>
  return 0;
    800032c0:	4501                	li	a0,0
}
    800032c2:	60a6                	ld	ra,72(sp)
    800032c4:	6406                	ld	s0,64(sp)
    800032c6:	74e2                	ld	s1,56(sp)
    800032c8:	7942                	ld	s2,48(sp)
    800032ca:	79a2                	ld	s3,40(sp)
    800032cc:	7a02                	ld	s4,32(sp)
    800032ce:	6ae2                	ld	s5,24(sp)
    800032d0:	6b42                	ld	s6,16(sp)
    800032d2:	6ba2                	ld	s7,8(sp)
    800032d4:	6161                	addi	sp,sp,80
    800032d6:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800032d8:	04000613          	li	a2,64
    800032dc:	4581                	li	a1,0
    800032de:	854e                	mv	a0,s3
    800032e0:	961fd0ef          	jal	ra,80000c40 <memset>
      dip->type = type;
    800032e4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800032e8:	854a                	mv	a0,s2
    800032ea:	429000ef          	jal	ra,80003f12 <log_write>
      brelse(bp);
    800032ee:	854a                	mv	a0,s2
    800032f0:	b17ff0ef          	jal	ra,80002e06 <brelse>
      return iget(dev, inum);
    800032f4:	85da                	mv	a1,s6
    800032f6:	8556                	mv	a0,s5
    800032f8:	e4dff0ef          	jal	ra,80003144 <iget>
    800032fc:	b7d9                	j	800032c2 <ialloc+0x7a>

00000000800032fe <iupdate>:
{
    800032fe:	1101                	addi	sp,sp,-32
    80003300:	ec06                	sd	ra,24(sp)
    80003302:	e822                	sd	s0,16(sp)
    80003304:	e426                	sd	s1,8(sp)
    80003306:	e04a                	sd	s2,0(sp)
    80003308:	1000                	addi	s0,sp,32
    8000330a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000330c:	415c                	lw	a5,4(a0)
    8000330e:	0047d79b          	srliw	a5,a5,0x4
    80003312:	0001b597          	auipc	a1,0x1b
    80003316:	2365a583          	lw	a1,566(a1) # 8001e548 <sb+0x18>
    8000331a:	9dbd                	addw	a1,a1,a5
    8000331c:	4108                	lw	a0,0(a0)
    8000331e:	9e1ff0ef          	jal	ra,80002cfe <bread>
    80003322:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003324:	05850793          	addi	a5,a0,88
    80003328:	40c8                	lw	a0,4(s1)
    8000332a:	893d                	andi	a0,a0,15
    8000332c:	051a                	slli	a0,a0,0x6
    8000332e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003330:	04449703          	lh	a4,68(s1)
    80003334:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003338:	04649703          	lh	a4,70(s1)
    8000333c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003340:	04849703          	lh	a4,72(s1)
    80003344:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003348:	04a49703          	lh	a4,74(s1)
    8000334c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003350:	44f8                	lw	a4,76(s1)
    80003352:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003354:	03400613          	li	a2,52
    80003358:	05048593          	addi	a1,s1,80
    8000335c:	0531                	addi	a0,a0,12
    8000335e:	93ffd0ef          	jal	ra,80000c9c <memmove>
  log_write(bp);
    80003362:	854a                	mv	a0,s2
    80003364:	3af000ef          	jal	ra,80003f12 <log_write>
  brelse(bp);
    80003368:	854a                	mv	a0,s2
    8000336a:	a9dff0ef          	jal	ra,80002e06 <brelse>
}
    8000336e:	60e2                	ld	ra,24(sp)
    80003370:	6442                	ld	s0,16(sp)
    80003372:	64a2                	ld	s1,8(sp)
    80003374:	6902                	ld	s2,0(sp)
    80003376:	6105                	addi	sp,sp,32
    80003378:	8082                	ret

000000008000337a <idup>:
{
    8000337a:	1101                	addi	sp,sp,-32
    8000337c:	ec06                	sd	ra,24(sp)
    8000337e:	e822                	sd	s0,16(sp)
    80003380:	e426                	sd	s1,8(sp)
    80003382:	1000                	addi	s0,sp,32
    80003384:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003386:	0001b517          	auipc	a0,0x1b
    8000338a:	1ca50513          	addi	a0,a0,458 # 8001e550 <itable>
    8000338e:	fdefd0ef          	jal	ra,80000b6c <acquire>
  ip->ref++;
    80003392:	449c                	lw	a5,8(s1)
    80003394:	2785                	addiw	a5,a5,1
    80003396:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003398:	0001b517          	auipc	a0,0x1b
    8000339c:	1b850513          	addi	a0,a0,440 # 8001e550 <itable>
    800033a0:	865fd0ef          	jal	ra,80000c04 <release>
}
    800033a4:	8526                	mv	a0,s1
    800033a6:	60e2                	ld	ra,24(sp)
    800033a8:	6442                	ld	s0,16(sp)
    800033aa:	64a2                	ld	s1,8(sp)
    800033ac:	6105                	addi	sp,sp,32
    800033ae:	8082                	ret

00000000800033b0 <ilock>:
{
    800033b0:	1101                	addi	sp,sp,-32
    800033b2:	ec06                	sd	ra,24(sp)
    800033b4:	e822                	sd	s0,16(sp)
    800033b6:	e426                	sd	s1,8(sp)
    800033b8:	e04a                	sd	s2,0(sp)
    800033ba:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800033bc:	c105                	beqz	a0,800033dc <ilock+0x2c>
    800033be:	84aa                	mv	s1,a0
    800033c0:	451c                	lw	a5,8(a0)
    800033c2:	00f05d63          	blez	a5,800033dc <ilock+0x2c>
  acquiresleep(&ip->lock);
    800033c6:	0541                	addi	a0,a0,16
    800033c8:	445000ef          	jal	ra,8000400c <acquiresleep>
  if(ip->valid == 0){
    800033cc:	40bc                	lw	a5,64(s1)
    800033ce:	cf89                	beqz	a5,800033e8 <ilock+0x38>
}
    800033d0:	60e2                	ld	ra,24(sp)
    800033d2:	6442                	ld	s0,16(sp)
    800033d4:	64a2                	ld	s1,8(sp)
    800033d6:	6902                	ld	s2,0(sp)
    800033d8:	6105                	addi	sp,sp,32
    800033da:	8082                	ret
    panic("ilock");
    800033dc:	00004517          	auipc	a0,0x4
    800033e0:	19450513          	addi	a0,a0,404 # 80007570 <syscalls+0x170>
    800033e4:	ba6fd0ef          	jal	ra,8000078a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800033e8:	40dc                	lw	a5,4(s1)
    800033ea:	0047d79b          	srliw	a5,a5,0x4
    800033ee:	0001b597          	auipc	a1,0x1b
    800033f2:	15a5a583          	lw	a1,346(a1) # 8001e548 <sb+0x18>
    800033f6:	9dbd                	addw	a1,a1,a5
    800033f8:	4088                	lw	a0,0(s1)
    800033fa:	905ff0ef          	jal	ra,80002cfe <bread>
    800033fe:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003400:	05850593          	addi	a1,a0,88
    80003404:	40dc                	lw	a5,4(s1)
    80003406:	8bbd                	andi	a5,a5,15
    80003408:	079a                	slli	a5,a5,0x6
    8000340a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000340c:	00059783          	lh	a5,0(a1)
    80003410:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003414:	00259783          	lh	a5,2(a1)
    80003418:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000341c:	00459783          	lh	a5,4(a1)
    80003420:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003424:	00659783          	lh	a5,6(a1)
    80003428:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000342c:	459c                	lw	a5,8(a1)
    8000342e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003430:	03400613          	li	a2,52
    80003434:	05b1                	addi	a1,a1,12
    80003436:	05048513          	addi	a0,s1,80
    8000343a:	863fd0ef          	jal	ra,80000c9c <memmove>
    brelse(bp);
    8000343e:	854a                	mv	a0,s2
    80003440:	9c7ff0ef          	jal	ra,80002e06 <brelse>
    ip->valid = 1;
    80003444:	4785                	li	a5,1
    80003446:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003448:	04449783          	lh	a5,68(s1)
    8000344c:	f3d1                	bnez	a5,800033d0 <ilock+0x20>
      panic("ilock: no type");
    8000344e:	00004517          	auipc	a0,0x4
    80003452:	12a50513          	addi	a0,a0,298 # 80007578 <syscalls+0x178>
    80003456:	b34fd0ef          	jal	ra,8000078a <panic>

000000008000345a <iunlock>:
{
    8000345a:	1101                	addi	sp,sp,-32
    8000345c:	ec06                	sd	ra,24(sp)
    8000345e:	e822                	sd	s0,16(sp)
    80003460:	e426                	sd	s1,8(sp)
    80003462:	e04a                	sd	s2,0(sp)
    80003464:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003466:	c505                	beqz	a0,8000348e <iunlock+0x34>
    80003468:	84aa                	mv	s1,a0
    8000346a:	01050913          	addi	s2,a0,16
    8000346e:	854a                	mv	a0,s2
    80003470:	41b000ef          	jal	ra,8000408a <holdingsleep>
    80003474:	cd09                	beqz	a0,8000348e <iunlock+0x34>
    80003476:	449c                	lw	a5,8(s1)
    80003478:	00f05b63          	blez	a5,8000348e <iunlock+0x34>
  releasesleep(&ip->lock);
    8000347c:	854a                	mv	a0,s2
    8000347e:	3d5000ef          	jal	ra,80004052 <releasesleep>
}
    80003482:	60e2                	ld	ra,24(sp)
    80003484:	6442                	ld	s0,16(sp)
    80003486:	64a2                	ld	s1,8(sp)
    80003488:	6902                	ld	s2,0(sp)
    8000348a:	6105                	addi	sp,sp,32
    8000348c:	8082                	ret
    panic("iunlock");
    8000348e:	00004517          	auipc	a0,0x4
    80003492:	0fa50513          	addi	a0,a0,250 # 80007588 <syscalls+0x188>
    80003496:	af4fd0ef          	jal	ra,8000078a <panic>

000000008000349a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000349a:	7179                	addi	sp,sp,-48
    8000349c:	f406                	sd	ra,40(sp)
    8000349e:	f022                	sd	s0,32(sp)
    800034a0:	ec26                	sd	s1,24(sp)
    800034a2:	e84a                	sd	s2,16(sp)
    800034a4:	e44e                	sd	s3,8(sp)
    800034a6:	e052                	sd	s4,0(sp)
    800034a8:	1800                	addi	s0,sp,48
    800034aa:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800034ac:	05050493          	addi	s1,a0,80
    800034b0:	08050913          	addi	s2,a0,128
    800034b4:	a021                	j	800034bc <itrunc+0x22>
    800034b6:	0491                	addi	s1,s1,4
    800034b8:	01248b63          	beq	s1,s2,800034ce <itrunc+0x34>
    if(ip->addrs[i]){
    800034bc:	408c                	lw	a1,0(s1)
    800034be:	dde5                	beqz	a1,800034b6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800034c0:	0009a503          	lw	a0,0(s3)
    800034c4:	a35ff0ef          	jal	ra,80002ef8 <bfree>
      ip->addrs[i] = 0;
    800034c8:	0004a023          	sw	zero,0(s1)
    800034cc:	b7ed                	j	800034b6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800034ce:	0809a583          	lw	a1,128(s3)
    800034d2:	ed91                	bnez	a1,800034ee <itrunc+0x54>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800034d4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800034d8:	854e                	mv	a0,s3
    800034da:	e25ff0ef          	jal	ra,800032fe <iupdate>
}
    800034de:	70a2                	ld	ra,40(sp)
    800034e0:	7402                	ld	s0,32(sp)
    800034e2:	64e2                	ld	s1,24(sp)
    800034e4:	6942                	ld	s2,16(sp)
    800034e6:	69a2                	ld	s3,8(sp)
    800034e8:	6a02                	ld	s4,0(sp)
    800034ea:	6145                	addi	sp,sp,48
    800034ec:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800034ee:	0009a503          	lw	a0,0(s3)
    800034f2:	80dff0ef          	jal	ra,80002cfe <bread>
    800034f6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800034f8:	05850493          	addi	s1,a0,88
    800034fc:	45850913          	addi	s2,a0,1112
    80003500:	a021                	j	80003508 <itrunc+0x6e>
    80003502:	0491                	addi	s1,s1,4
    80003504:	01248963          	beq	s1,s2,80003516 <itrunc+0x7c>
      if(a[j])
    80003508:	408c                	lw	a1,0(s1)
    8000350a:	dde5                	beqz	a1,80003502 <itrunc+0x68>
        bfree(ip->dev, a[j]);
    8000350c:	0009a503          	lw	a0,0(s3)
    80003510:	9e9ff0ef          	jal	ra,80002ef8 <bfree>
    80003514:	b7fd                	j	80003502 <itrunc+0x68>
    brelse(bp);
    80003516:	8552                	mv	a0,s4
    80003518:	8efff0ef          	jal	ra,80002e06 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000351c:	0809a583          	lw	a1,128(s3)
    80003520:	0009a503          	lw	a0,0(s3)
    80003524:	9d5ff0ef          	jal	ra,80002ef8 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003528:	0809a023          	sw	zero,128(s3)
    8000352c:	b765                	j	800034d4 <itrunc+0x3a>

000000008000352e <iput>:
{
    8000352e:	1101                	addi	sp,sp,-32
    80003530:	ec06                	sd	ra,24(sp)
    80003532:	e822                	sd	s0,16(sp)
    80003534:	e426                	sd	s1,8(sp)
    80003536:	e04a                	sd	s2,0(sp)
    80003538:	1000                	addi	s0,sp,32
    8000353a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000353c:	0001b517          	auipc	a0,0x1b
    80003540:	01450513          	addi	a0,a0,20 # 8001e550 <itable>
    80003544:	e28fd0ef          	jal	ra,80000b6c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003548:	4498                	lw	a4,8(s1)
    8000354a:	4785                	li	a5,1
    8000354c:	02f70163          	beq	a4,a5,8000356e <iput+0x40>
  ip->ref--;
    80003550:	449c                	lw	a5,8(s1)
    80003552:	37fd                	addiw	a5,a5,-1
    80003554:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003556:	0001b517          	auipc	a0,0x1b
    8000355a:	ffa50513          	addi	a0,a0,-6 # 8001e550 <itable>
    8000355e:	ea6fd0ef          	jal	ra,80000c04 <release>
}
    80003562:	60e2                	ld	ra,24(sp)
    80003564:	6442                	ld	s0,16(sp)
    80003566:	64a2                	ld	s1,8(sp)
    80003568:	6902                	ld	s2,0(sp)
    8000356a:	6105                	addi	sp,sp,32
    8000356c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000356e:	40bc                	lw	a5,64(s1)
    80003570:	d3e5                	beqz	a5,80003550 <iput+0x22>
    80003572:	04a49783          	lh	a5,74(s1)
    80003576:	ffe9                	bnez	a5,80003550 <iput+0x22>
    acquiresleep(&ip->lock);
    80003578:	01048913          	addi	s2,s1,16
    8000357c:	854a                	mv	a0,s2
    8000357e:	28f000ef          	jal	ra,8000400c <acquiresleep>
    release(&itable.lock);
    80003582:	0001b517          	auipc	a0,0x1b
    80003586:	fce50513          	addi	a0,a0,-50 # 8001e550 <itable>
    8000358a:	e7afd0ef          	jal	ra,80000c04 <release>
    itrunc(ip);
    8000358e:	8526                	mv	a0,s1
    80003590:	f0bff0ef          	jal	ra,8000349a <itrunc>
    ip->type = 0;
    80003594:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003598:	8526                	mv	a0,s1
    8000359a:	d65ff0ef          	jal	ra,800032fe <iupdate>
    ip->valid = 0;
    8000359e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800035a2:	854a                	mv	a0,s2
    800035a4:	2af000ef          	jal	ra,80004052 <releasesleep>
    acquire(&itable.lock);
    800035a8:	0001b517          	auipc	a0,0x1b
    800035ac:	fa850513          	addi	a0,a0,-88 # 8001e550 <itable>
    800035b0:	dbcfd0ef          	jal	ra,80000b6c <acquire>
    800035b4:	bf71                	j	80003550 <iput+0x22>

00000000800035b6 <iunlockput>:
{
    800035b6:	1101                	addi	sp,sp,-32
    800035b8:	ec06                	sd	ra,24(sp)
    800035ba:	e822                	sd	s0,16(sp)
    800035bc:	e426                	sd	s1,8(sp)
    800035be:	1000                	addi	s0,sp,32
    800035c0:	84aa                	mv	s1,a0
  iunlock(ip);
    800035c2:	e99ff0ef          	jal	ra,8000345a <iunlock>
  iput(ip);
    800035c6:	8526                	mv	a0,s1
    800035c8:	f67ff0ef          	jal	ra,8000352e <iput>
}
    800035cc:	60e2                	ld	ra,24(sp)
    800035ce:	6442                	ld	s0,16(sp)
    800035d0:	64a2                	ld	s1,8(sp)
    800035d2:	6105                	addi	sp,sp,32
    800035d4:	8082                	ret

00000000800035d6 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800035d6:	0001b717          	auipc	a4,0x1b
    800035da:	f6672703          	lw	a4,-154(a4) # 8001e53c <sb+0xc>
    800035de:	4785                	li	a5,1
    800035e0:	0ae7ff63          	bgeu	a5,a4,8000369e <ireclaim+0xc8>
{
    800035e4:	7139                	addi	sp,sp,-64
    800035e6:	fc06                	sd	ra,56(sp)
    800035e8:	f822                	sd	s0,48(sp)
    800035ea:	f426                	sd	s1,40(sp)
    800035ec:	f04a                	sd	s2,32(sp)
    800035ee:	ec4e                	sd	s3,24(sp)
    800035f0:	e852                	sd	s4,16(sp)
    800035f2:	e456                	sd	s5,8(sp)
    800035f4:	e05a                	sd	s6,0(sp)
    800035f6:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800035f8:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    800035fa:	00050a1b          	sext.w	s4,a0
    800035fe:	0001ba97          	auipc	s5,0x1b
    80003602:	f32a8a93          	addi	s5,s5,-206 # 8001e530 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    80003606:	00004b17          	auipc	s6,0x4
    8000360a:	f8ab0b13          	addi	s6,s6,-118 # 80007590 <syscalls+0x190>
    8000360e:	a099                	j	80003654 <ireclaim+0x7e>
    80003610:	85ce                	mv	a1,s3
    80003612:	855a                	mv	a0,s6
    80003614:	eb1fc0ef          	jal	ra,800004c4 <printf>
      ip = iget(dev, inum);
    80003618:	85ce                	mv	a1,s3
    8000361a:	8552                	mv	a0,s4
    8000361c:	b29ff0ef          	jal	ra,80003144 <iget>
    80003620:	89aa                	mv	s3,a0
    brelse(bp);
    80003622:	854a                	mv	a0,s2
    80003624:	fe2ff0ef          	jal	ra,80002e06 <brelse>
    if (ip) {
    80003628:	00098f63          	beqz	s3,80003646 <ireclaim+0x70>
      begin_op();
    8000362c:	762000ef          	jal	ra,80003d8e <begin_op>
      ilock(ip);
    80003630:	854e                	mv	a0,s3
    80003632:	d7fff0ef          	jal	ra,800033b0 <ilock>
      iunlock(ip);
    80003636:	854e                	mv	a0,s3
    80003638:	e23ff0ef          	jal	ra,8000345a <iunlock>
      iput(ip);
    8000363c:	854e                	mv	a0,s3
    8000363e:	ef1ff0ef          	jal	ra,8000352e <iput>
      end_op();
    80003642:	7bc000ef          	jal	ra,80003dfe <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003646:	0485                	addi	s1,s1,1
    80003648:	00caa703          	lw	a4,12(s5)
    8000364c:	0004879b          	sext.w	a5,s1
    80003650:	02e7fd63          	bgeu	a5,a4,8000368a <ireclaim+0xb4>
    80003654:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003658:	0044d793          	srli	a5,s1,0x4
    8000365c:	018aa583          	lw	a1,24(s5)
    80003660:	9dbd                	addw	a1,a1,a5
    80003662:	8552                	mv	a0,s4
    80003664:	e9aff0ef          	jal	ra,80002cfe <bread>
    80003668:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    8000366a:	05850793          	addi	a5,a0,88
    8000366e:	00f9f713          	andi	a4,s3,15
    80003672:	071a                	slli	a4,a4,0x6
    80003674:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    80003676:	00079703          	lh	a4,0(a5)
    8000367a:	c701                	beqz	a4,80003682 <ireclaim+0xac>
    8000367c:	00679783          	lh	a5,6(a5)
    80003680:	dbc1                	beqz	a5,80003610 <ireclaim+0x3a>
    brelse(bp);
    80003682:	854a                	mv	a0,s2
    80003684:	f82ff0ef          	jal	ra,80002e06 <brelse>
    if (ip) {
    80003688:	bf7d                	j	80003646 <ireclaim+0x70>
}
    8000368a:	70e2                	ld	ra,56(sp)
    8000368c:	7442                	ld	s0,48(sp)
    8000368e:	74a2                	ld	s1,40(sp)
    80003690:	7902                	ld	s2,32(sp)
    80003692:	69e2                	ld	s3,24(sp)
    80003694:	6a42                	ld	s4,16(sp)
    80003696:	6aa2                	ld	s5,8(sp)
    80003698:	6b02                	ld	s6,0(sp)
    8000369a:	6121                	addi	sp,sp,64
    8000369c:	8082                	ret
    8000369e:	8082                	ret

00000000800036a0 <fsinit>:
fsinit(int dev) {
    800036a0:	7179                	addi	sp,sp,-48
    800036a2:	f406                	sd	ra,40(sp)
    800036a4:	f022                	sd	s0,32(sp)
    800036a6:	ec26                	sd	s1,24(sp)
    800036a8:	e84a                	sd	s2,16(sp)
    800036aa:	e44e                	sd	s3,8(sp)
    800036ac:	1800                	addi	s0,sp,48
    800036ae:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    800036b0:	4585                	li	a1,1
    800036b2:	e4cff0ef          	jal	ra,80002cfe <bread>
    800036b6:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036b8:	0001b997          	auipc	s3,0x1b
    800036bc:	e7898993          	addi	s3,s3,-392 # 8001e530 <sb>
    800036c0:	02000613          	li	a2,32
    800036c4:	05850593          	addi	a1,a0,88
    800036c8:	854e                	mv	a0,s3
    800036ca:	dd2fd0ef          	jal	ra,80000c9c <memmove>
  brelse(bp);
    800036ce:	854a                	mv	a0,s2
    800036d0:	f36ff0ef          	jal	ra,80002e06 <brelse>
  if(sb.magic != FSMAGIC)
    800036d4:	0009a703          	lw	a4,0(s3)
    800036d8:	102037b7          	lui	a5,0x10203
    800036dc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036e0:	02f71363          	bne	a4,a5,80003706 <fsinit+0x66>
  initlog(dev, &sb);
    800036e4:	0001b597          	auipc	a1,0x1b
    800036e8:	e4c58593          	addi	a1,a1,-436 # 8001e530 <sb>
    800036ec:	8526                	mv	a0,s1
    800036ee:	616000ef          	jal	ra,80003d04 <initlog>
  ireclaim(dev);
    800036f2:	8526                	mv	a0,s1
    800036f4:	ee3ff0ef          	jal	ra,800035d6 <ireclaim>
}
    800036f8:	70a2                	ld	ra,40(sp)
    800036fa:	7402                	ld	s0,32(sp)
    800036fc:	64e2                	ld	s1,24(sp)
    800036fe:	6942                	ld	s2,16(sp)
    80003700:	69a2                	ld	s3,8(sp)
    80003702:	6145                	addi	sp,sp,48
    80003704:	8082                	ret
    panic("invalid file system");
    80003706:	00004517          	auipc	a0,0x4
    8000370a:	eaa50513          	addi	a0,a0,-342 # 800075b0 <syscalls+0x1b0>
    8000370e:	87cfd0ef          	jal	ra,8000078a <panic>

0000000080003712 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003712:	1141                	addi	sp,sp,-16
    80003714:	e422                	sd	s0,8(sp)
    80003716:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003718:	411c                	lw	a5,0(a0)
    8000371a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000371c:	415c                	lw	a5,4(a0)
    8000371e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003720:	04451783          	lh	a5,68(a0)
    80003724:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003728:	04a51783          	lh	a5,74(a0)
    8000372c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003730:	04c56783          	lwu	a5,76(a0)
    80003734:	e99c                	sd	a5,16(a1)
}
    80003736:	6422                	ld	s0,8(sp)
    80003738:	0141                	addi	sp,sp,16
    8000373a:	8082                	ret

000000008000373c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000373c:	457c                	lw	a5,76(a0)
    8000373e:	0cd7ef63          	bltu	a5,a3,8000381c <readi+0xe0>
{
    80003742:	7159                	addi	sp,sp,-112
    80003744:	f486                	sd	ra,104(sp)
    80003746:	f0a2                	sd	s0,96(sp)
    80003748:	eca6                	sd	s1,88(sp)
    8000374a:	e8ca                	sd	s2,80(sp)
    8000374c:	e4ce                	sd	s3,72(sp)
    8000374e:	e0d2                	sd	s4,64(sp)
    80003750:	fc56                	sd	s5,56(sp)
    80003752:	f85a                	sd	s6,48(sp)
    80003754:	f45e                	sd	s7,40(sp)
    80003756:	f062                	sd	s8,32(sp)
    80003758:	ec66                	sd	s9,24(sp)
    8000375a:	e86a                	sd	s10,16(sp)
    8000375c:	e46e                	sd	s11,8(sp)
    8000375e:	1880                	addi	s0,sp,112
    80003760:	8b2a                	mv	s6,a0
    80003762:	8bae                	mv	s7,a1
    80003764:	8a32                	mv	s4,a2
    80003766:	84b6                	mv	s1,a3
    80003768:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000376a:	9f35                	addw	a4,a4,a3
    return 0;
    8000376c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000376e:	08d76663          	bltu	a4,a3,800037fa <readi+0xbe>
  if(off + n > ip->size)
    80003772:	00e7f463          	bgeu	a5,a4,8000377a <readi+0x3e>
    n = ip->size - off;
    80003776:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000377a:	080a8f63          	beqz	s5,80003818 <readi+0xdc>
    8000377e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003780:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003784:	5c7d                	li	s8,-1
    80003786:	a80d                	j	800037b8 <readi+0x7c>
    80003788:	020d1d93          	slli	s11,s10,0x20
    8000378c:	020ddd93          	srli	s11,s11,0x20
    80003790:	05890793          	addi	a5,s2,88
    80003794:	86ee                	mv	a3,s11
    80003796:	963e                	add	a2,a2,a5
    80003798:	85d2                	mv	a1,s4
    8000379a:	855e                	mv	a0,s7
    8000379c:	f96fe0ef          	jal	ra,80001f32 <either_copyout>
    800037a0:	05850763          	beq	a0,s8,800037ee <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800037a4:	854a                	mv	a0,s2
    800037a6:	e60ff0ef          	jal	ra,80002e06 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800037aa:	013d09bb          	addw	s3,s10,s3
    800037ae:	009d04bb          	addw	s1,s10,s1
    800037b2:	9a6e                	add	s4,s4,s11
    800037b4:	0559f163          	bgeu	s3,s5,800037f6 <readi+0xba>
    uint addr = bmap(ip, off/BSIZE);
    800037b8:	00a4d59b          	srliw	a1,s1,0xa
    800037bc:	855a                	mv	a0,s6
    800037be:	8bbff0ef          	jal	ra,80003078 <bmap>
    800037c2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800037c6:	c985                	beqz	a1,800037f6 <readi+0xba>
    bp = bread(ip->dev, addr);
    800037c8:	000b2503          	lw	a0,0(s6)
    800037cc:	d32ff0ef          	jal	ra,80002cfe <bread>
    800037d0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800037d2:	3ff4f613          	andi	a2,s1,1023
    800037d6:	40cc87bb          	subw	a5,s9,a2
    800037da:	413a873b          	subw	a4,s5,s3
    800037de:	8d3e                	mv	s10,a5
    800037e0:	2781                	sext.w	a5,a5
    800037e2:	0007069b          	sext.w	a3,a4
    800037e6:	faf6f1e3          	bgeu	a3,a5,80003788 <readi+0x4c>
    800037ea:	8d3a                	mv	s10,a4
    800037ec:	bf71                	j	80003788 <readi+0x4c>
      brelse(bp);
    800037ee:	854a                	mv	a0,s2
    800037f0:	e16ff0ef          	jal	ra,80002e06 <brelse>
      tot = -1;
    800037f4:	59fd                	li	s3,-1
  }
  return tot;
    800037f6:	0009851b          	sext.w	a0,s3
}
    800037fa:	70a6                	ld	ra,104(sp)
    800037fc:	7406                	ld	s0,96(sp)
    800037fe:	64e6                	ld	s1,88(sp)
    80003800:	6946                	ld	s2,80(sp)
    80003802:	69a6                	ld	s3,72(sp)
    80003804:	6a06                	ld	s4,64(sp)
    80003806:	7ae2                	ld	s5,56(sp)
    80003808:	7b42                	ld	s6,48(sp)
    8000380a:	7ba2                	ld	s7,40(sp)
    8000380c:	7c02                	ld	s8,32(sp)
    8000380e:	6ce2                	ld	s9,24(sp)
    80003810:	6d42                	ld	s10,16(sp)
    80003812:	6da2                	ld	s11,8(sp)
    80003814:	6165                	addi	sp,sp,112
    80003816:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003818:	89d6                	mv	s3,s5
    8000381a:	bff1                	j	800037f6 <readi+0xba>
    return 0;
    8000381c:	4501                	li	a0,0
}
    8000381e:	8082                	ret

0000000080003820 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003820:	457c                	lw	a5,76(a0)
    80003822:	0ed7ea63          	bltu	a5,a3,80003916 <writei+0xf6>
{
    80003826:	7159                	addi	sp,sp,-112
    80003828:	f486                	sd	ra,104(sp)
    8000382a:	f0a2                	sd	s0,96(sp)
    8000382c:	eca6                	sd	s1,88(sp)
    8000382e:	e8ca                	sd	s2,80(sp)
    80003830:	e4ce                	sd	s3,72(sp)
    80003832:	e0d2                	sd	s4,64(sp)
    80003834:	fc56                	sd	s5,56(sp)
    80003836:	f85a                	sd	s6,48(sp)
    80003838:	f45e                	sd	s7,40(sp)
    8000383a:	f062                	sd	s8,32(sp)
    8000383c:	ec66                	sd	s9,24(sp)
    8000383e:	e86a                	sd	s10,16(sp)
    80003840:	e46e                	sd	s11,8(sp)
    80003842:	1880                	addi	s0,sp,112
    80003844:	8aaa                	mv	s5,a0
    80003846:	8bae                	mv	s7,a1
    80003848:	8a32                	mv	s4,a2
    8000384a:	8936                	mv	s2,a3
    8000384c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000384e:	00e687bb          	addw	a5,a3,a4
    80003852:	0cd7e463          	bltu	a5,a3,8000391a <writei+0xfa>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003856:	00043737          	lui	a4,0x43
    8000385a:	0cf76263          	bltu	a4,a5,8000391e <writei+0xfe>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000385e:	0a0b0a63          	beqz	s6,80003912 <writei+0xf2>
    80003862:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003864:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003868:	5c7d                	li	s8,-1
    8000386a:	a825                	j	800038a2 <writei+0x82>
    8000386c:	020d1d93          	slli	s11,s10,0x20
    80003870:	020ddd93          	srli	s11,s11,0x20
    80003874:	05848793          	addi	a5,s1,88
    80003878:	86ee                	mv	a3,s11
    8000387a:	8652                	mv	a2,s4
    8000387c:	85de                	mv	a1,s7
    8000387e:	953e                	add	a0,a0,a5
    80003880:	efcfe0ef          	jal	ra,80001f7c <either_copyin>
    80003884:	05850a63          	beq	a0,s8,800038d8 <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003888:	8526                	mv	a0,s1
    8000388a:	688000ef          	jal	ra,80003f12 <log_write>
    brelse(bp);
    8000388e:	8526                	mv	a0,s1
    80003890:	d76ff0ef          	jal	ra,80002e06 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003894:	013d09bb          	addw	s3,s10,s3
    80003898:	012d093b          	addw	s2,s10,s2
    8000389c:	9a6e                	add	s4,s4,s11
    8000389e:	0569f063          	bgeu	s3,s6,800038de <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    800038a2:	00a9559b          	srliw	a1,s2,0xa
    800038a6:	8556                	mv	a0,s5
    800038a8:	fd0ff0ef          	jal	ra,80003078 <bmap>
    800038ac:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800038b0:	c59d                	beqz	a1,800038de <writei+0xbe>
    bp = bread(ip->dev, addr);
    800038b2:	000aa503          	lw	a0,0(s5)
    800038b6:	c48ff0ef          	jal	ra,80002cfe <bread>
    800038ba:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800038bc:	3ff97513          	andi	a0,s2,1023
    800038c0:	40ac87bb          	subw	a5,s9,a0
    800038c4:	413b073b          	subw	a4,s6,s3
    800038c8:	8d3e                	mv	s10,a5
    800038ca:	2781                	sext.w	a5,a5
    800038cc:	0007069b          	sext.w	a3,a4
    800038d0:	f8f6fee3          	bgeu	a3,a5,8000386c <writei+0x4c>
    800038d4:	8d3a                	mv	s10,a4
    800038d6:	bf59                	j	8000386c <writei+0x4c>
      brelse(bp);
    800038d8:	8526                	mv	a0,s1
    800038da:	d2cff0ef          	jal	ra,80002e06 <brelse>
  }

  if(off > ip->size)
    800038de:	04caa783          	lw	a5,76(s5)
    800038e2:	0127f463          	bgeu	a5,s2,800038ea <writei+0xca>
    ip->size = off;
    800038e6:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800038ea:	8556                	mv	a0,s5
    800038ec:	a13ff0ef          	jal	ra,800032fe <iupdate>

  return tot;
    800038f0:	0009851b          	sext.w	a0,s3
}
    800038f4:	70a6                	ld	ra,104(sp)
    800038f6:	7406                	ld	s0,96(sp)
    800038f8:	64e6                	ld	s1,88(sp)
    800038fa:	6946                	ld	s2,80(sp)
    800038fc:	69a6                	ld	s3,72(sp)
    800038fe:	6a06                	ld	s4,64(sp)
    80003900:	7ae2                	ld	s5,56(sp)
    80003902:	7b42                	ld	s6,48(sp)
    80003904:	7ba2                	ld	s7,40(sp)
    80003906:	7c02                	ld	s8,32(sp)
    80003908:	6ce2                	ld	s9,24(sp)
    8000390a:	6d42                	ld	s10,16(sp)
    8000390c:	6da2                	ld	s11,8(sp)
    8000390e:	6165                	addi	sp,sp,112
    80003910:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003912:	89da                	mv	s3,s6
    80003914:	bfd9                	j	800038ea <writei+0xca>
    return -1;
    80003916:	557d                	li	a0,-1
}
    80003918:	8082                	ret
    return -1;
    8000391a:	557d                	li	a0,-1
    8000391c:	bfe1                	j	800038f4 <writei+0xd4>
    return -1;
    8000391e:	557d                	li	a0,-1
    80003920:	bfd1                	j	800038f4 <writei+0xd4>

0000000080003922 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003922:	1141                	addi	sp,sp,-16
    80003924:	e406                	sd	ra,8(sp)
    80003926:	e022                	sd	s0,0(sp)
    80003928:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000392a:	4639                	li	a2,14
    8000392c:	be0fd0ef          	jal	ra,80000d0c <strncmp>
}
    80003930:	60a2                	ld	ra,8(sp)
    80003932:	6402                	ld	s0,0(sp)
    80003934:	0141                	addi	sp,sp,16
    80003936:	8082                	ret

0000000080003938 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003938:	7139                	addi	sp,sp,-64
    8000393a:	fc06                	sd	ra,56(sp)
    8000393c:	f822                	sd	s0,48(sp)
    8000393e:	f426                	sd	s1,40(sp)
    80003940:	f04a                	sd	s2,32(sp)
    80003942:	ec4e                	sd	s3,24(sp)
    80003944:	e852                	sd	s4,16(sp)
    80003946:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003948:	04451703          	lh	a4,68(a0)
    8000394c:	4785                	li	a5,1
    8000394e:	00f71a63          	bne	a4,a5,80003962 <dirlookup+0x2a>
    80003952:	892a                	mv	s2,a0
    80003954:	89ae                	mv	s3,a1
    80003956:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003958:	457c                	lw	a5,76(a0)
    8000395a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000395c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000395e:	e39d                	bnez	a5,80003984 <dirlookup+0x4c>
    80003960:	a095                	j	800039c4 <dirlookup+0x8c>
    panic("dirlookup not DIR");
    80003962:	00004517          	auipc	a0,0x4
    80003966:	c6650513          	addi	a0,a0,-922 # 800075c8 <syscalls+0x1c8>
    8000396a:	e21fc0ef          	jal	ra,8000078a <panic>
      panic("dirlookup read");
    8000396e:	00004517          	auipc	a0,0x4
    80003972:	c7250513          	addi	a0,a0,-910 # 800075e0 <syscalls+0x1e0>
    80003976:	e15fc0ef          	jal	ra,8000078a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000397a:	24c1                	addiw	s1,s1,16
    8000397c:	04c92783          	lw	a5,76(s2)
    80003980:	04f4f163          	bgeu	s1,a5,800039c2 <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003984:	4741                	li	a4,16
    80003986:	86a6                	mv	a3,s1
    80003988:	fc040613          	addi	a2,s0,-64
    8000398c:	4581                	li	a1,0
    8000398e:	854a                	mv	a0,s2
    80003990:	dadff0ef          	jal	ra,8000373c <readi>
    80003994:	47c1                	li	a5,16
    80003996:	fcf51ce3          	bne	a0,a5,8000396e <dirlookup+0x36>
    if(de.inum == 0)
    8000399a:	fc045783          	lhu	a5,-64(s0)
    8000399e:	dff1                	beqz	a5,8000397a <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    800039a0:	fc240593          	addi	a1,s0,-62
    800039a4:	854e                	mv	a0,s3
    800039a6:	f7dff0ef          	jal	ra,80003922 <namecmp>
    800039aa:	f961                	bnez	a0,8000397a <dirlookup+0x42>
      if(poff)
    800039ac:	000a0463          	beqz	s4,800039b4 <dirlookup+0x7c>
        *poff = off;
    800039b0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800039b4:	fc045583          	lhu	a1,-64(s0)
    800039b8:	00092503          	lw	a0,0(s2)
    800039bc:	f88ff0ef          	jal	ra,80003144 <iget>
    800039c0:	a011                	j	800039c4 <dirlookup+0x8c>
  return 0;
    800039c2:	4501                	li	a0,0
}
    800039c4:	70e2                	ld	ra,56(sp)
    800039c6:	7442                	ld	s0,48(sp)
    800039c8:	74a2                	ld	s1,40(sp)
    800039ca:	7902                	ld	s2,32(sp)
    800039cc:	69e2                	ld	s3,24(sp)
    800039ce:	6a42                	ld	s4,16(sp)
    800039d0:	6121                	addi	sp,sp,64
    800039d2:	8082                	ret

00000000800039d4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800039d4:	711d                	addi	sp,sp,-96
    800039d6:	ec86                	sd	ra,88(sp)
    800039d8:	e8a2                	sd	s0,80(sp)
    800039da:	e4a6                	sd	s1,72(sp)
    800039dc:	e0ca                	sd	s2,64(sp)
    800039de:	fc4e                	sd	s3,56(sp)
    800039e0:	f852                	sd	s4,48(sp)
    800039e2:	f456                	sd	s5,40(sp)
    800039e4:	f05a                	sd	s6,32(sp)
    800039e6:	ec5e                	sd	s7,24(sp)
    800039e8:	e862                	sd	s8,16(sp)
    800039ea:	e466                	sd	s9,8(sp)
    800039ec:	1080                	addi	s0,sp,96
    800039ee:	84aa                	mv	s1,a0
    800039f0:	8aae                	mv	s5,a1
    800039f2:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800039f4:	00054703          	lbu	a4,0(a0)
    800039f8:	02f00793          	li	a5,47
    800039fc:	00f70f63          	beq	a4,a5,80003a1a <namex+0x46>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003a00:	e35fd0ef          	jal	ra,80001834 <myproc>
    80003a04:	15053503          	ld	a0,336(a0)
    80003a08:	973ff0ef          	jal	ra,8000337a <idup>
    80003a0c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003a0e:	02f00913          	li	s2,47
  len = path - s;
    80003a12:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003a14:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003a16:	4b85                	li	s7,1
    80003a18:	a861                	j	80003ab0 <namex+0xdc>
    ip = iget(ROOTDEV, ROOTINO);
    80003a1a:	4585                	li	a1,1
    80003a1c:	4505                	li	a0,1
    80003a1e:	f26ff0ef          	jal	ra,80003144 <iget>
    80003a22:	89aa                	mv	s3,a0
    80003a24:	b7ed                	j	80003a0e <namex+0x3a>
      iunlockput(ip);
    80003a26:	854e                	mv	a0,s3
    80003a28:	b8fff0ef          	jal	ra,800035b6 <iunlockput>
      return 0;
    80003a2c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003a2e:	854e                	mv	a0,s3
    80003a30:	60e6                	ld	ra,88(sp)
    80003a32:	6446                	ld	s0,80(sp)
    80003a34:	64a6                	ld	s1,72(sp)
    80003a36:	6906                	ld	s2,64(sp)
    80003a38:	79e2                	ld	s3,56(sp)
    80003a3a:	7a42                	ld	s4,48(sp)
    80003a3c:	7aa2                	ld	s5,40(sp)
    80003a3e:	7b02                	ld	s6,32(sp)
    80003a40:	6be2                	ld	s7,24(sp)
    80003a42:	6c42                	ld	s8,16(sp)
    80003a44:	6ca2                	ld	s9,8(sp)
    80003a46:	6125                	addi	sp,sp,96
    80003a48:	8082                	ret
      iunlock(ip);
    80003a4a:	854e                	mv	a0,s3
    80003a4c:	a0fff0ef          	jal	ra,8000345a <iunlock>
      return ip;
    80003a50:	bff9                	j	80003a2e <namex+0x5a>
      iunlockput(ip);
    80003a52:	854e                	mv	a0,s3
    80003a54:	b63ff0ef          	jal	ra,800035b6 <iunlockput>
      return 0;
    80003a58:	89e6                	mv	s3,s9
    80003a5a:	bfd1                	j	80003a2e <namex+0x5a>
  len = path - s;
    80003a5c:	40b48633          	sub	a2,s1,a1
    80003a60:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003a64:	079c5c63          	bge	s8,s9,80003adc <namex+0x108>
    memmove(name, s, DIRSIZ);
    80003a68:	4639                	li	a2,14
    80003a6a:	8552                	mv	a0,s4
    80003a6c:	a30fd0ef          	jal	ra,80000c9c <memmove>
  while(*path == '/')
    80003a70:	0004c783          	lbu	a5,0(s1)
    80003a74:	01279763          	bne	a5,s2,80003a82 <namex+0xae>
    path++;
    80003a78:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003a7a:	0004c783          	lbu	a5,0(s1)
    80003a7e:	ff278de3          	beq	a5,s2,80003a78 <namex+0xa4>
    ilock(ip);
    80003a82:	854e                	mv	a0,s3
    80003a84:	92dff0ef          	jal	ra,800033b0 <ilock>
    if(ip->type != T_DIR){
    80003a88:	04499783          	lh	a5,68(s3)
    80003a8c:	f9779de3          	bne	a5,s7,80003a26 <namex+0x52>
    if(nameiparent && *path == '\0'){
    80003a90:	000a8563          	beqz	s5,80003a9a <namex+0xc6>
    80003a94:	0004c783          	lbu	a5,0(s1)
    80003a98:	dbcd                	beqz	a5,80003a4a <namex+0x76>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003a9a:	865a                	mv	a2,s6
    80003a9c:	85d2                	mv	a1,s4
    80003a9e:	854e                	mv	a0,s3
    80003aa0:	e99ff0ef          	jal	ra,80003938 <dirlookup>
    80003aa4:	8caa                	mv	s9,a0
    80003aa6:	d555                	beqz	a0,80003a52 <namex+0x7e>
    iunlockput(ip);
    80003aa8:	854e                	mv	a0,s3
    80003aaa:	b0dff0ef          	jal	ra,800035b6 <iunlockput>
    ip = next;
    80003aae:	89e6                	mv	s3,s9
  while(*path == '/')
    80003ab0:	0004c783          	lbu	a5,0(s1)
    80003ab4:	05279363          	bne	a5,s2,80003afa <namex+0x126>
    path++;
    80003ab8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003aba:	0004c783          	lbu	a5,0(s1)
    80003abe:	ff278de3          	beq	a5,s2,80003ab8 <namex+0xe4>
  if(*path == 0)
    80003ac2:	c78d                	beqz	a5,80003aec <namex+0x118>
    path++;
    80003ac4:	85a6                	mv	a1,s1
  len = path - s;
    80003ac6:	8cda                	mv	s9,s6
    80003ac8:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003aca:	01278963          	beq	a5,s2,80003adc <namex+0x108>
    80003ace:	d7d9                	beqz	a5,80003a5c <namex+0x88>
    path++;
    80003ad0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ad2:	0004c783          	lbu	a5,0(s1)
    80003ad6:	ff279ce3          	bne	a5,s2,80003ace <namex+0xfa>
    80003ada:	b749                	j	80003a5c <namex+0x88>
    memmove(name, s, len);
    80003adc:	2601                	sext.w	a2,a2
    80003ade:	8552                	mv	a0,s4
    80003ae0:	9bcfd0ef          	jal	ra,80000c9c <memmove>
    name[len] = 0;
    80003ae4:	9cd2                	add	s9,s9,s4
    80003ae6:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003aea:	b759                	j	80003a70 <namex+0x9c>
  if(nameiparent){
    80003aec:	f40a81e3          	beqz	s5,80003a2e <namex+0x5a>
    iput(ip);
    80003af0:	854e                	mv	a0,s3
    80003af2:	a3dff0ef          	jal	ra,8000352e <iput>
    return 0;
    80003af6:	4981                	li	s3,0
    80003af8:	bf1d                	j	80003a2e <namex+0x5a>
  if(*path == 0)
    80003afa:	dbed                	beqz	a5,80003aec <namex+0x118>
  while(*path != '/' && *path != 0)
    80003afc:	0004c783          	lbu	a5,0(s1)
    80003b00:	85a6                	mv	a1,s1
    80003b02:	b7f1                	j	80003ace <namex+0xfa>

0000000080003b04 <dirlink>:
{
    80003b04:	7139                	addi	sp,sp,-64
    80003b06:	fc06                	sd	ra,56(sp)
    80003b08:	f822                	sd	s0,48(sp)
    80003b0a:	f426                	sd	s1,40(sp)
    80003b0c:	f04a                	sd	s2,32(sp)
    80003b0e:	ec4e                	sd	s3,24(sp)
    80003b10:	e852                	sd	s4,16(sp)
    80003b12:	0080                	addi	s0,sp,64
    80003b14:	892a                	mv	s2,a0
    80003b16:	8a2e                	mv	s4,a1
    80003b18:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003b1a:	4601                	li	a2,0
    80003b1c:	e1dff0ef          	jal	ra,80003938 <dirlookup>
    80003b20:	e52d                	bnez	a0,80003b8a <dirlink+0x86>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b22:	04c92483          	lw	s1,76(s2)
    80003b26:	c48d                	beqz	s1,80003b50 <dirlink+0x4c>
    80003b28:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b2a:	4741                	li	a4,16
    80003b2c:	86a6                	mv	a3,s1
    80003b2e:	fc040613          	addi	a2,s0,-64
    80003b32:	4581                	li	a1,0
    80003b34:	854a                	mv	a0,s2
    80003b36:	c07ff0ef          	jal	ra,8000373c <readi>
    80003b3a:	47c1                	li	a5,16
    80003b3c:	04f51b63          	bne	a0,a5,80003b92 <dirlink+0x8e>
    if(de.inum == 0)
    80003b40:	fc045783          	lhu	a5,-64(s0)
    80003b44:	c791                	beqz	a5,80003b50 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b46:	24c1                	addiw	s1,s1,16
    80003b48:	04c92783          	lw	a5,76(s2)
    80003b4c:	fcf4efe3          	bltu	s1,a5,80003b2a <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80003b50:	4639                	li	a2,14
    80003b52:	85d2                	mv	a1,s4
    80003b54:	fc240513          	addi	a0,s0,-62
    80003b58:	9f0fd0ef          	jal	ra,80000d48 <strncpy>
  de.inum = inum;
    80003b5c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b60:	4741                	li	a4,16
    80003b62:	86a6                	mv	a3,s1
    80003b64:	fc040613          	addi	a2,s0,-64
    80003b68:	4581                	li	a1,0
    80003b6a:	854a                	mv	a0,s2
    80003b6c:	cb5ff0ef          	jal	ra,80003820 <writei>
    80003b70:	1541                	addi	a0,a0,-16
    80003b72:	00a03533          	snez	a0,a0
    80003b76:	40a00533          	neg	a0,a0
}
    80003b7a:	70e2                	ld	ra,56(sp)
    80003b7c:	7442                	ld	s0,48(sp)
    80003b7e:	74a2                	ld	s1,40(sp)
    80003b80:	7902                	ld	s2,32(sp)
    80003b82:	69e2                	ld	s3,24(sp)
    80003b84:	6a42                	ld	s4,16(sp)
    80003b86:	6121                	addi	sp,sp,64
    80003b88:	8082                	ret
    iput(ip);
    80003b8a:	9a5ff0ef          	jal	ra,8000352e <iput>
    return -1;
    80003b8e:	557d                	li	a0,-1
    80003b90:	b7ed                	j	80003b7a <dirlink+0x76>
      panic("dirlink read");
    80003b92:	00004517          	auipc	a0,0x4
    80003b96:	a5e50513          	addi	a0,a0,-1442 # 800075f0 <syscalls+0x1f0>
    80003b9a:	bf1fc0ef          	jal	ra,8000078a <panic>

0000000080003b9e <namei>:

struct inode*
namei(char *path)
{
    80003b9e:	1101                	addi	sp,sp,-32
    80003ba0:	ec06                	sd	ra,24(sp)
    80003ba2:	e822                	sd	s0,16(sp)
    80003ba4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ba6:	fe040613          	addi	a2,s0,-32
    80003baa:	4581                	li	a1,0
    80003bac:	e29ff0ef          	jal	ra,800039d4 <namex>
}
    80003bb0:	60e2                	ld	ra,24(sp)
    80003bb2:	6442                	ld	s0,16(sp)
    80003bb4:	6105                	addi	sp,sp,32
    80003bb6:	8082                	ret

0000000080003bb8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003bb8:	1141                	addi	sp,sp,-16
    80003bba:	e406                	sd	ra,8(sp)
    80003bbc:	e022                	sd	s0,0(sp)
    80003bbe:	0800                	addi	s0,sp,16
    80003bc0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003bc2:	4585                	li	a1,1
    80003bc4:	e11ff0ef          	jal	ra,800039d4 <namex>
}
    80003bc8:	60a2                	ld	ra,8(sp)
    80003bca:	6402                	ld	s0,0(sp)
    80003bcc:	0141                	addi	sp,sp,16
    80003bce:	8082                	ret

0000000080003bd0 <write_head>:
  brelse(buf);  // 释放缓冲区
}

// 将内存中的日志头写回磁盘
static void write_head(void)
{
    80003bd0:	1101                	addi	sp,sp,-32
    80003bd2:	ec06                	sd	ra,24(sp)
    80003bd4:	e822                	sd	s0,16(sp)
    80003bd6:	e426                	sd	s1,8(sp)
    80003bd8:	e04a                	sd	s2,0(sp)
    80003bda:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003bdc:	0001c917          	auipc	s2,0x1c
    80003be0:	41c90913          	addi	s2,s2,1052 # 8001fff8 <log>
    80003be4:	01892583          	lw	a1,24(s2)
    80003be8:	02492503          	lw	a0,36(s2)
    80003bec:	912ff0ef          	jal	ra,80002cfe <bread>
    80003bf0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;  // 更新日志中的块数量
    80003bf2:	02892683          	lw	a3,40(s2)
    80003bf6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003bf8:	02d05763          	blez	a3,80003c26 <write_head+0x56>
    80003bfc:	0001c797          	auipc	a5,0x1c
    80003c00:	42878793          	addi	a5,a5,1064 # 80020024 <log+0x2c>
    80003c04:	05c50713          	addi	a4,a0,92
    80003c08:	36fd                	addiw	a3,a3,-1
    80003c0a:	1682                	slli	a3,a3,0x20
    80003c0c:	9281                	srli	a3,a3,0x20
    80003c0e:	068a                	slli	a3,a3,0x2
    80003c10:	0001c617          	auipc	a2,0x1c
    80003c14:	41860613          	addi	a2,a2,1048 # 80020028 <log+0x30>
    80003c18:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];  // 更新每个日志块的块号
    80003c1a:	4390                	lw	a2,0(a5)
    80003c1c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003c1e:	0791                	addi	a5,a5,4
    80003c20:	0711                	addi	a4,a4,4
    80003c22:	fed79ce3          	bne	a5,a3,80003c1a <write_head+0x4a>
  }
  bwrite(buf);  // 写回日志头块
    80003c26:	8526                	mv	a0,s1
    80003c28:	9acff0ef          	jal	ra,80002dd4 <bwrite>
  brelse(buf);  // 释放缓冲区
    80003c2c:	8526                	mv	a0,s1
    80003c2e:	9d8ff0ef          	jal	ra,80002e06 <brelse>
}
    80003c32:	60e2                	ld	ra,24(sp)
    80003c34:	6442                	ld	s0,16(sp)
    80003c36:	64a2                	ld	s1,8(sp)
    80003c38:	6902                	ld	s2,0(sp)
    80003c3a:	6105                	addi	sp,sp,32
    80003c3c:	8082                	ret

0000000080003c3e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003c3e:	0001c797          	auipc	a5,0x1c
    80003c42:	3e27a783          	lw	a5,994(a5) # 80020020 <log+0x28>
    80003c46:	0af05e63          	blez	a5,80003d02 <install_trans+0xc4>
{
    80003c4a:	715d                	addi	sp,sp,-80
    80003c4c:	e486                	sd	ra,72(sp)
    80003c4e:	e0a2                	sd	s0,64(sp)
    80003c50:	fc26                	sd	s1,56(sp)
    80003c52:	f84a                	sd	s2,48(sp)
    80003c54:	f44e                	sd	s3,40(sp)
    80003c56:	f052                	sd	s4,32(sp)
    80003c58:	ec56                	sd	s5,24(sp)
    80003c5a:	e85a                	sd	s6,16(sp)
    80003c5c:	e45e                	sd	s7,8(sp)
    80003c5e:	0880                	addi	s0,sp,80
    80003c60:	8b2a                	mv	s6,a0
    80003c62:	0001ca97          	auipc	s5,0x1c
    80003c66:	3c2a8a93          	addi	s5,s5,962 # 80020024 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003c6a:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003c6c:	00004b97          	auipc	s7,0x4
    80003c70:	994b8b93          	addi	s7,s7,-1644 # 80007600 <syscalls+0x200>
    struct buf *lbuf = bread(log.dev, log.start + tail + 1);  // 读取日志块
    80003c74:	0001ca17          	auipc	s4,0x1c
    80003c78:	384a0a13          	addi	s4,s4,900 # 8001fff8 <log>
    80003c7c:	a025                	j	80003ca4 <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003c7e:	000aa603          	lw	a2,0(s5)
    80003c82:	85ce                	mv	a1,s3
    80003c84:	855e                	mv	a0,s7
    80003c86:	83ffc0ef          	jal	ra,800004c4 <printf>
    80003c8a:	a839                	j	80003ca8 <install_trans+0x6a>
    brelse(lbuf);  // 释放日志块
    80003c8c:	854a                	mv	a0,s2
    80003c8e:	978ff0ef          	jal	ra,80002e06 <brelse>
    brelse(dbuf);  // 释放目标块
    80003c92:	8526                	mv	a0,s1
    80003c94:	972ff0ef          	jal	ra,80002e06 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003c98:	2985                	addiw	s3,s3,1
    80003c9a:	0a91                	addi	s5,s5,4
    80003c9c:	028a2783          	lw	a5,40(s4)
    80003ca0:	04f9d663          	bge	s3,a5,80003cec <install_trans+0xae>
    if(recovering) {
    80003ca4:	fc0b1de3          	bnez	s6,80003c7e <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start + tail + 1);  // 读取日志块
    80003ca8:	018a2583          	lw	a1,24(s4)
    80003cac:	013585bb          	addw	a1,a1,s3
    80003cb0:	2585                	addiw	a1,a1,1
    80003cb2:	024a2503          	lw	a0,36(s4)
    80003cb6:	848ff0ef          	jal	ra,80002cfe <bread>
    80003cba:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]);  // 读取目标块
    80003cbc:	000aa583          	lw	a1,0(s5)
    80003cc0:	024a2503          	lw	a0,36(s4)
    80003cc4:	83aff0ef          	jal	ra,80002cfe <bread>
    80003cc8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);
    80003cca:	40000613          	li	a2,1024
    80003cce:	05890593          	addi	a1,s2,88
    80003cd2:	05850513          	addi	a0,a0,88
    80003cd6:	fc7fc0ef          	jal	ra,80000c9c <memmove>
    bwrite(dbuf);  // 将目标块写回磁盘
    80003cda:	8526                	mv	a0,s1
    80003cdc:	8f8ff0ef          	jal	ra,80002dd4 <bwrite>
    if(recovering == 0)
    80003ce0:	fa0b16e3          	bnez	s6,80003c8c <install_trans+0x4e>
      bunpin(dbuf);  // 提交后解锁目标块
    80003ce4:	8526                	mv	a0,s1
    80003ce6:	9deff0ef          	jal	ra,80002ec4 <bunpin>
    80003cea:	b74d                	j	80003c8c <install_trans+0x4e>
}
    80003cec:	60a6                	ld	ra,72(sp)
    80003cee:	6406                	ld	s0,64(sp)
    80003cf0:	74e2                	ld	s1,56(sp)
    80003cf2:	7942                	ld	s2,48(sp)
    80003cf4:	79a2                	ld	s3,40(sp)
    80003cf6:	7a02                	ld	s4,32(sp)
    80003cf8:	6ae2                	ld	s5,24(sp)
    80003cfa:	6b42                	ld	s6,16(sp)
    80003cfc:	6ba2                	ld	s7,8(sp)
    80003cfe:	6161                	addi	sp,sp,80
    80003d00:	8082                	ret
    80003d02:	8082                	ret

0000000080003d04 <initlog>:
{
    80003d04:	7179                	addi	sp,sp,-48
    80003d06:	f406                	sd	ra,40(sp)
    80003d08:	f022                	sd	s0,32(sp)
    80003d0a:	ec26                	sd	s1,24(sp)
    80003d0c:	e84a                	sd	s2,16(sp)
    80003d0e:	e44e                	sd	s3,8(sp)
    80003d10:	1800                	addi	s0,sp,48
    80003d12:	892a                	mv	s2,a0
    80003d14:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003d16:	0001c497          	auipc	s1,0x1c
    80003d1a:	2e248493          	addi	s1,s1,738 # 8001fff8 <log>
    80003d1e:	00004597          	auipc	a1,0x4
    80003d22:	90258593          	addi	a1,a1,-1790 # 80007620 <syscalls+0x220>
    80003d26:	8526                	mv	a0,s1
    80003d28:	dc5fc0ef          	jal	ra,80000aec <initlock>
  log.start = sb->logstart;  // 设置日志起始位置
    80003d2c:	0149a583          	lw	a1,20(s3)
    80003d30:	cc8c                	sw	a1,24(s1)
  log.dev = dev;  // 设置日志设备
    80003d32:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003d36:	854a                	mv	a0,s2
    80003d38:	fc7fe0ef          	jal	ra,80002cfe <bread>
  log.lh.n = lh->n;  // 读取日志中的块数量
    80003d3c:	4d34                	lw	a3,88(a0)
    80003d3e:	d494                	sw	a3,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003d40:	02d05563          	blez	a3,80003d6a <initlog+0x66>
    80003d44:	05c50793          	addi	a5,a0,92
    80003d48:	0001c717          	auipc	a4,0x1c
    80003d4c:	2dc70713          	addi	a4,a4,732 # 80020024 <log+0x2c>
    80003d50:	36fd                	addiw	a3,a3,-1
    80003d52:	1682                	slli	a3,a3,0x20
    80003d54:	9281                	srli	a3,a3,0x20
    80003d56:	068a                	slli	a3,a3,0x2
    80003d58:	06050613          	addi	a2,a0,96
    80003d5c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];  // 读取每个日志块的块号
    80003d5e:	4390                	lw	a2,0(a5)
    80003d60:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003d62:	0791                	addi	a5,a5,4
    80003d64:	0711                	addi	a4,a4,4
    80003d66:	fed79ce3          	bne	a5,a3,80003d5e <initlog+0x5a>
  brelse(buf);  // 释放缓冲区
    80003d6a:	89cff0ef          	jal	ra,80002e06 <brelse>

// 从日志中恢复
static void recover_from_log(void)
{
  read_head();  // 读取日志头
  install_trans(1);  // 如果已提交，从日志复制到磁盘
    80003d6e:	4505                	li	a0,1
    80003d70:	ecfff0ef          	jal	ra,80003c3e <install_trans>
  log.lh.n = 0;  // 清空日志中的块数量
    80003d74:	0001c797          	auipc	a5,0x1c
    80003d78:	2a07a623          	sw	zero,684(a5) # 80020020 <log+0x28>
  write_head();  // 清空日志
    80003d7c:	e55ff0ef          	jal	ra,80003bd0 <write_head>
}
    80003d80:	70a2                	ld	ra,40(sp)
    80003d82:	7402                	ld	s0,32(sp)
    80003d84:	64e2                	ld	s1,24(sp)
    80003d86:	6942                	ld	s2,16(sp)
    80003d88:	69a2                	ld	s3,8(sp)
    80003d8a:	6145                	addi	sp,sp,48
    80003d8c:	8082                	ret

0000000080003d8e <begin_op>:
}

// 文件系统调用开始时调用
void begin_op(void)
{
    80003d8e:	1101                	addi	sp,sp,-32
    80003d90:	ec06                	sd	ra,24(sp)
    80003d92:	e822                	sd	s0,16(sp)
    80003d94:	e426                	sd	s1,8(sp)
    80003d96:	e04a                	sd	s2,0(sp)
    80003d98:	1000                	addi	s0,sp,32
  acquire(&log.lock);  // 获取日志锁
    80003d9a:	0001c517          	auipc	a0,0x1c
    80003d9e:	25e50513          	addi	a0,a0,606 # 8001fff8 <log>
    80003da2:	dcbfc0ef          	jal	ra,80000b6c <acquire>
  while(1){
    if(log.committing){
    80003da6:	0001c497          	auipc	s1,0x1c
    80003daa:	25248493          	addi	s1,s1,594 # 8001fff8 <log>
      // 如果日志正在提交，进入睡眠
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGBLOCKS){
    80003dae:	4979                	li	s2,30
    80003db0:	a029                	j	80003dba <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003db2:	85a6                	mv	a1,s1
    80003db4:	8526                	mv	a0,s1
    80003db6:	f7ffd0ef          	jal	ra,80001d34 <sleep>
    if(log.committing){
    80003dba:	509c                	lw	a5,32(s1)
    80003dbc:	fbfd                	bnez	a5,80003db2 <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGBLOCKS){
    80003dbe:	4cdc                	lw	a5,28(s1)
    80003dc0:	0017871b          	addiw	a4,a5,1
    80003dc4:	0007069b          	sext.w	a3,a4
    80003dc8:	0027179b          	slliw	a5,a4,0x2
    80003dcc:	9fb9                	addw	a5,a5,a4
    80003dce:	0017979b          	slliw	a5,a5,0x1
    80003dd2:	5498                	lw	a4,40(s1)
    80003dd4:	9fb9                	addw	a5,a5,a4
    80003dd6:	00f95763          	bge	s2,a5,80003de4 <begin_op+0x56>
      // 如果当前操作可能耗尽日志空间，等待提交
      sleep(&log, &log.lock);
    80003dda:	85a6                	mv	a1,s1
    80003ddc:	8526                	mv	a0,s1
    80003dde:	f57fd0ef          	jal	ra,80001d34 <sleep>
    80003de2:	bfe1                	j	80003dba <begin_op+0x2c>
    } else {
      log.outstanding += 1;  // 增加正在进行的操作计数
    80003de4:	0001c517          	auipc	a0,0x1c
    80003de8:	21450513          	addi	a0,a0,532 # 8001fff8 <log>
    80003dec:	cd54                	sw	a3,28(a0)
      release(&log.lock);  // 释放日志锁
    80003dee:	e17fc0ef          	jal	ra,80000c04 <release>
      break;
    }
  }
}
    80003df2:	60e2                	ld	ra,24(sp)
    80003df4:	6442                	ld	s0,16(sp)
    80003df6:	64a2                	ld	s1,8(sp)
    80003df8:	6902                	ld	s2,0(sp)
    80003dfa:	6105                	addi	sp,sp,32
    80003dfc:	8082                	ret

0000000080003dfe <end_op>:

// 文件系统调用结束时调用
// 如果这是最后一个待处理的操作，则提交日志
void end_op(void)
{
    80003dfe:	7139                	addi	sp,sp,-64
    80003e00:	fc06                	sd	ra,56(sp)
    80003e02:	f822                	sd	s0,48(sp)
    80003e04:	f426                	sd	s1,40(sp)
    80003e06:	f04a                	sd	s2,32(sp)
    80003e08:	ec4e                	sd	s3,24(sp)
    80003e0a:	e852                	sd	s4,16(sp)
    80003e0c:	e456                	sd	s5,8(sp)
    80003e0e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);  // 获取日志锁
    80003e10:	0001c497          	auipc	s1,0x1c
    80003e14:	1e848493          	addi	s1,s1,488 # 8001fff8 <log>
    80003e18:	8526                	mv	a0,s1
    80003e1a:	d53fc0ef          	jal	ra,80000b6c <acquire>
  log.outstanding -= 1;  // 减少待处理操作计数
    80003e1e:	4cdc                	lw	a5,28(s1)
    80003e20:	37fd                	addiw	a5,a5,-1
    80003e22:	0007891b          	sext.w	s2,a5
    80003e26:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80003e28:	509c                	lw	a5,32(s1)
    80003e2a:	ef9d                	bnez	a5,80003e68 <end_op+0x6a>
    panic("log.committing");  // 不允许在提交时结束操作
  if(log.outstanding == 0){
    80003e2c:	04091463          	bnez	s2,80003e74 <end_op+0x76>
    do_commit = 1;  // 如果没有待处理的操作，则标记为需要提交
    log.committing = 1;  // 标记日志为正在提交
    80003e30:	0001c497          	auipc	s1,0x1c
    80003e34:	1c848493          	addi	s1,s1,456 # 8001fff8 <log>
    80003e38:	4785                	li	a5,1
    80003e3a:	d09c                	sw	a5,32(s1)
  } else {
    // 如果正在等待日志空间，唤醒等待的进程
    wakeup(&log);
  }
  release(&log.lock);  // 释放日志锁
    80003e3c:	8526                	mv	a0,s1
    80003e3e:	dc7fc0ef          	jal	ra,80000c04 <release>
}

// 提交事务，将日志中的块写回磁盘并清空日志
static void commit()
{
  if (log.lh.n > 0) {
    80003e42:	549c                	lw	a5,40(s1)
    80003e44:	04f04b63          	bgtz	a5,80003e9a <end_op+0x9c>
    acquire(&log.lock);
    80003e48:	0001c497          	auipc	s1,0x1c
    80003e4c:	1b048493          	addi	s1,s1,432 # 8001fff8 <log>
    80003e50:	8526                	mv	a0,s1
    80003e52:	d1bfc0ef          	jal	ra,80000b6c <acquire>
    log.committing = 0;  // 提交完成，恢复日志状态
    80003e56:	0204a023          	sw	zero,32(s1)
    wakeup(&log);  // 唤醒可能在等待提交的进程
    80003e5a:	8526                	mv	a0,s1
    80003e5c:	b88fe0ef          	jal	ra,800021e4 <wakeup>
    release(&log.lock);  // 释放日志锁
    80003e60:	8526                	mv	a0,s1
    80003e62:	da3fc0ef          	jal	ra,80000c04 <release>
}
    80003e66:	a00d                	j	80003e88 <end_op+0x8a>
    panic("log.committing");  // 不允许在提交时结束操作
    80003e68:	00003517          	auipc	a0,0x3
    80003e6c:	7c050513          	addi	a0,a0,1984 # 80007628 <syscalls+0x228>
    80003e70:	91bfc0ef          	jal	ra,8000078a <panic>
    wakeup(&log);
    80003e74:	0001c497          	auipc	s1,0x1c
    80003e78:	18448493          	addi	s1,s1,388 # 8001fff8 <log>
    80003e7c:	8526                	mv	a0,s1
    80003e7e:	b66fe0ef          	jal	ra,800021e4 <wakeup>
  release(&log.lock);  // 释放日志锁
    80003e82:	8526                	mv	a0,s1
    80003e84:	d81fc0ef          	jal	ra,80000c04 <release>
}
    80003e88:	70e2                	ld	ra,56(sp)
    80003e8a:	7442                	ld	s0,48(sp)
    80003e8c:	74a2                	ld	s1,40(sp)
    80003e8e:	7902                	ld	s2,32(sp)
    80003e90:	69e2                	ld	s3,24(sp)
    80003e92:	6a42                	ld	s4,16(sp)
    80003e94:	6aa2                	ld	s5,8(sp)
    80003e96:	6121                	addi	sp,sp,64
    80003e98:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e9a:	0001ca97          	auipc	s5,0x1c
    80003e9e:	18aa8a93          	addi	s5,s5,394 # 80020024 <log+0x2c>
    struct buf *to = bread(log.dev, log.start + tail + 1);  // 读取日志块
    80003ea2:	0001ca17          	auipc	s4,0x1c
    80003ea6:	156a0a13          	addi	s4,s4,342 # 8001fff8 <log>
    80003eaa:	018a2583          	lw	a1,24(s4)
    80003eae:	012585bb          	addw	a1,a1,s2
    80003eb2:	2585                	addiw	a1,a1,1
    80003eb4:	024a2503          	lw	a0,36(s4)
    80003eb8:	e47fe0ef          	jal	ra,80002cfe <bread>
    80003ebc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]);  // 读取缓存块
    80003ebe:	000aa583          	lw	a1,0(s5)
    80003ec2:	024a2503          	lw	a0,36(s4)
    80003ec6:	e39fe0ef          	jal	ra,80002cfe <bread>
    80003eca:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);  // 将缓存块的数据复制到日志块
    80003ecc:	40000613          	li	a2,1024
    80003ed0:	05850593          	addi	a1,a0,88
    80003ed4:	05848513          	addi	a0,s1,88
    80003ed8:	dc5fc0ef          	jal	ra,80000c9c <memmove>
    bwrite(to);  // 写入日志块
    80003edc:	8526                	mv	a0,s1
    80003ede:	ef7fe0ef          	jal	ra,80002dd4 <bwrite>
    brelse(from);  // 释放缓存块
    80003ee2:	854e                	mv	a0,s3
    80003ee4:	f23fe0ef          	jal	ra,80002e06 <brelse>
    brelse(to);  // 释放日志块
    80003ee8:	8526                	mv	a0,s1
    80003eea:	f1dfe0ef          	jal	ra,80002e06 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eee:	2905                	addiw	s2,s2,1
    80003ef0:	0a91                	addi	s5,s5,4
    80003ef2:	028a2783          	lw	a5,40(s4)
    80003ef6:	faf94ae3          	blt	s2,a5,80003eaa <end_op+0xac>
    write_log();     // 将已修改的块从缓存写入日志
    write_head();    // 写入日志头到磁盘，真正提交
    80003efa:	cd7ff0ef          	jal	ra,80003bd0 <write_head>
    install_trans(0); // 将写入操作应用到实际位置
    80003efe:	4501                	li	a0,0
    80003f00:	d3fff0ef          	jal	ra,80003c3e <install_trans>
    log.lh.n = 0;    // 清空日志中的块数量
    80003f04:	0001c797          	auipc	a5,0x1c
    80003f08:	1007ae23          	sw	zero,284(a5) # 80020020 <log+0x28>
    write_head();    // 清空日志
    80003f0c:	cc5ff0ef          	jal	ra,80003bd0 <write_head>
    80003f10:	bf25                	j	80003e48 <end_op+0x4a>

0000000080003f12 <log_write>:
//   bp = bread(...)
//   修改 bp->data[]
//   log_write(bp)
//   brelse(bp)
void log_write(struct buf *b)
{
    80003f12:	1101                	addi	sp,sp,-32
    80003f14:	ec06                	sd	ra,24(sp)
    80003f16:	e822                	sd	s0,16(sp)
    80003f18:	e426                	sd	s1,8(sp)
    80003f1a:	e04a                	sd	s2,0(sp)
    80003f1c:	1000                	addi	s0,sp,32
    80003f1e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);  // 获取日志锁
    80003f20:	0001c917          	auipc	s2,0x1c
    80003f24:	0d890913          	addi	s2,s2,216 # 8001fff8 <log>
    80003f28:	854a                	mv	a0,s2
    80003f2a:	c43fc0ef          	jal	ra,80000b6c <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80003f2e:	02892603          	lw	a2,40(s2)
    80003f32:	47f5                	li	a5,29
    80003f34:	04c7cc63          	blt	a5,a2,80003f8c <log_write+0x7a>
    panic("too big a transaction");  // 如果日志块数量超过最大值，出错
  if (log.outstanding < 1)
    80003f38:	0001c797          	auipc	a5,0x1c
    80003f3c:	0dc7a783          	lw	a5,220(a5) # 80020014 <log+0x1c>
    80003f40:	04f05c63          	blez	a5,80003f98 <log_write+0x86>
    panic("log_write outside of trans");  // 如果在没有事务的情况下调用，出错

  for (i = 0; i < log.lh.n; i++) {
    80003f44:	4781                	li	a5,0
    80003f46:	04c05f63          	blez	a2,80003fa4 <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // 如果块已经存在于日志中，跳过
    80003f4a:	44cc                	lw	a1,12(s1)
    80003f4c:	0001c717          	auipc	a4,0x1c
    80003f50:	0d870713          	addi	a4,a4,216 # 80020024 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80003f54:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // 如果块已经存在于日志中，跳过
    80003f56:	4314                	lw	a3,0(a4)
    80003f58:	04b68663          	beq	a3,a1,80003fa4 <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80003f5c:	2785                	addiw	a5,a5,1
    80003f5e:	0711                	addi	a4,a4,4
    80003f60:	fef61be3          	bne	a2,a5,80003f56 <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;  // 将块号记录到日志中
    80003f64:	0621                	addi	a2,a2,8
    80003f66:	060a                	slli	a2,a2,0x2
    80003f68:	0001c797          	auipc	a5,0x1c
    80003f6c:	09078793          	addi	a5,a5,144 # 8001fff8 <log>
    80003f70:	963e                	add	a2,a2,a5
    80003f72:	44dc                	lw	a5,12(s1)
    80003f74:	c65c                	sw	a5,12(a2)
  if (i == log.lh.n) {  // 如果是新块，添加到日志
    bpin(b);  // 锁定块
    80003f76:	8526                	mv	a0,s1
    80003f78:	f19fe0ef          	jal	ra,80002e90 <bpin>
    log.lh.n++;  // 增加日志中的块数量
    80003f7c:	0001c717          	auipc	a4,0x1c
    80003f80:	07c70713          	addi	a4,a4,124 # 8001fff8 <log>
    80003f84:	571c                	lw	a5,40(a4)
    80003f86:	2785                	addiw	a5,a5,1
    80003f88:	d71c                	sw	a5,40(a4)
    80003f8a:	a815                	j	80003fbe <log_write+0xac>
    panic("too big a transaction");  // 如果日志块数量超过最大值，出错
    80003f8c:	00003517          	auipc	a0,0x3
    80003f90:	6ac50513          	addi	a0,a0,1708 # 80007638 <syscalls+0x238>
    80003f94:	ff6fc0ef          	jal	ra,8000078a <panic>
    panic("log_write outside of trans");  // 如果在没有事务的情况下调用，出错
    80003f98:	00003517          	auipc	a0,0x3
    80003f9c:	6b850513          	addi	a0,a0,1720 # 80007650 <syscalls+0x250>
    80003fa0:	feafc0ef          	jal	ra,8000078a <panic>
  log.lh.block[i] = b->blockno;  // 将块号记录到日志中
    80003fa4:	00878713          	addi	a4,a5,8
    80003fa8:	00271693          	slli	a3,a4,0x2
    80003fac:	0001c717          	auipc	a4,0x1c
    80003fb0:	04c70713          	addi	a4,a4,76 # 8001fff8 <log>
    80003fb4:	9736                	add	a4,a4,a3
    80003fb6:	44d4                	lw	a3,12(s1)
    80003fb8:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // 如果是新块，添加到日志
    80003fba:	faf60ee3          	beq	a2,a5,80003f76 <log_write+0x64>
  }
  release(&log.lock);  // 释放日志锁
    80003fbe:	0001c517          	auipc	a0,0x1c
    80003fc2:	03a50513          	addi	a0,a0,58 # 8001fff8 <log>
    80003fc6:	c3ffc0ef          	jal	ra,80000c04 <release>
}
    80003fca:	60e2                	ld	ra,24(sp)
    80003fcc:	6442                	ld	s0,16(sp)
    80003fce:	64a2                	ld	s1,8(sp)
    80003fd0:	6902                	ld	s2,0(sp)
    80003fd2:	6105                	addi	sp,sp,32
    80003fd4:	8082                	ret

0000000080003fd6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80003fd6:	1101                	addi	sp,sp,-32
    80003fd8:	ec06                	sd	ra,24(sp)
    80003fda:	e822                	sd	s0,16(sp)
    80003fdc:	e426                	sd	s1,8(sp)
    80003fde:	e04a                	sd	s2,0(sp)
    80003fe0:	1000                	addi	s0,sp,32
    80003fe2:	84aa                	mv	s1,a0
    80003fe4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80003fe6:	00003597          	auipc	a1,0x3
    80003fea:	68a58593          	addi	a1,a1,1674 # 80007670 <syscalls+0x270>
    80003fee:	0521                	addi	a0,a0,8
    80003ff0:	afdfc0ef          	jal	ra,80000aec <initlock>
  lk->name = name;
    80003ff4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80003ff8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003ffc:	0204a423          	sw	zero,40(s1)
}
    80004000:	60e2                	ld	ra,24(sp)
    80004002:	6442                	ld	s0,16(sp)
    80004004:	64a2                	ld	s1,8(sp)
    80004006:	6902                	ld	s2,0(sp)
    80004008:	6105                	addi	sp,sp,32
    8000400a:	8082                	ret

000000008000400c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000400c:	1101                	addi	sp,sp,-32
    8000400e:	ec06                	sd	ra,24(sp)
    80004010:	e822                	sd	s0,16(sp)
    80004012:	e426                	sd	s1,8(sp)
    80004014:	e04a                	sd	s2,0(sp)
    80004016:	1000                	addi	s0,sp,32
    80004018:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000401a:	00850913          	addi	s2,a0,8
    8000401e:	854a                	mv	a0,s2
    80004020:	b4dfc0ef          	jal	ra,80000b6c <acquire>
  while (lk->locked) {
    80004024:	409c                	lw	a5,0(s1)
    80004026:	c799                	beqz	a5,80004034 <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80004028:	85ca                	mv	a1,s2
    8000402a:	8526                	mv	a0,s1
    8000402c:	d09fd0ef          	jal	ra,80001d34 <sleep>
  while (lk->locked) {
    80004030:	409c                	lw	a5,0(s1)
    80004032:	fbfd                	bnez	a5,80004028 <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80004034:	4785                	li	a5,1
    80004036:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004038:	ffcfd0ef          	jal	ra,80001834 <myproc>
    8000403c:	591c                	lw	a5,48(a0)
    8000403e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004040:	854a                	mv	a0,s2
    80004042:	bc3fc0ef          	jal	ra,80000c04 <release>
}
    80004046:	60e2                	ld	ra,24(sp)
    80004048:	6442                	ld	s0,16(sp)
    8000404a:	64a2                	ld	s1,8(sp)
    8000404c:	6902                	ld	s2,0(sp)
    8000404e:	6105                	addi	sp,sp,32
    80004050:	8082                	ret

0000000080004052 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004052:	1101                	addi	sp,sp,-32
    80004054:	ec06                	sd	ra,24(sp)
    80004056:	e822                	sd	s0,16(sp)
    80004058:	e426                	sd	s1,8(sp)
    8000405a:	e04a                	sd	s2,0(sp)
    8000405c:	1000                	addi	s0,sp,32
    8000405e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004060:	00850913          	addi	s2,a0,8
    80004064:	854a                	mv	a0,s2
    80004066:	b07fc0ef          	jal	ra,80000b6c <acquire>
  lk->locked = 0;
    8000406a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000406e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004072:	8526                	mv	a0,s1
    80004074:	970fe0ef          	jal	ra,800021e4 <wakeup>
  release(&lk->lk);
    80004078:	854a                	mv	a0,s2
    8000407a:	b8bfc0ef          	jal	ra,80000c04 <release>
}
    8000407e:	60e2                	ld	ra,24(sp)
    80004080:	6442                	ld	s0,16(sp)
    80004082:	64a2                	ld	s1,8(sp)
    80004084:	6902                	ld	s2,0(sp)
    80004086:	6105                	addi	sp,sp,32
    80004088:	8082                	ret

000000008000408a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000408a:	7179                	addi	sp,sp,-48
    8000408c:	f406                	sd	ra,40(sp)
    8000408e:	f022                	sd	s0,32(sp)
    80004090:	ec26                	sd	s1,24(sp)
    80004092:	e84a                	sd	s2,16(sp)
    80004094:	e44e                	sd	s3,8(sp)
    80004096:	1800                	addi	s0,sp,48
    80004098:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000409a:	00850913          	addi	s2,a0,8
    8000409e:	854a                	mv	a0,s2
    800040a0:	acdfc0ef          	jal	ra,80000b6c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800040a4:	409c                	lw	a5,0(s1)
    800040a6:	ef89                	bnez	a5,800040c0 <holdingsleep+0x36>
    800040a8:	4481                	li	s1,0
  release(&lk->lk);
    800040aa:	854a                	mv	a0,s2
    800040ac:	b59fc0ef          	jal	ra,80000c04 <release>
  return r;
}
    800040b0:	8526                	mv	a0,s1
    800040b2:	70a2                	ld	ra,40(sp)
    800040b4:	7402                	ld	s0,32(sp)
    800040b6:	64e2                	ld	s1,24(sp)
    800040b8:	6942                	ld	s2,16(sp)
    800040ba:	69a2                	ld	s3,8(sp)
    800040bc:	6145                	addi	sp,sp,48
    800040be:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800040c0:	0284a983          	lw	s3,40(s1)
    800040c4:	f70fd0ef          	jal	ra,80001834 <myproc>
    800040c8:	5904                	lw	s1,48(a0)
    800040ca:	413484b3          	sub	s1,s1,s3
    800040ce:	0014b493          	seqz	s1,s1
    800040d2:	bfe1                	j	800040aa <holdingsleep+0x20>

00000000800040d4 <fileinit>:
} ftable;

// 文件表初始化
void
fileinit(void)
{
    800040d4:	1141                	addi	sp,sp,-16
    800040d6:	e406                	sd	ra,8(sp)
    800040d8:	e022                	sd	s0,0(sp)
    800040da:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");  // 初始化文件表的自旋锁
    800040dc:	00003597          	auipc	a1,0x3
    800040e0:	5a458593          	addi	a1,a1,1444 # 80007680 <syscalls+0x280>
    800040e4:	0001c517          	auipc	a0,0x1c
    800040e8:	05c50513          	addi	a0,a0,92 # 80020140 <ftable>
    800040ec:	a01fc0ef          	jal	ra,80000aec <initlock>
}
    800040f0:	60a2                	ld	ra,8(sp)
    800040f2:	6402                	ld	s0,0(sp)
    800040f4:	0141                	addi	sp,sp,16
    800040f6:	8082                	ret

00000000800040f8 <filealloc>:

// 分配一个新的文件结构体
struct file*
filealloc(void)
{
    800040f8:	1101                	addi	sp,sp,-32
    800040fa:	ec06                	sd	ra,24(sp)
    800040fc:	e822                	sd	s0,16(sp)
    800040fe:	e426                	sd	s1,8(sp)
    80004100:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);  // 获取文件表锁
    80004102:	0001c517          	auipc	a0,0x1c
    80004106:	03e50513          	addi	a0,a0,62 # 80020140 <ftable>
    8000410a:	a63fc0ef          	jal	ra,80000b6c <acquire>
  // 遍历文件表，找到引用计数为 0 的文件结构体
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000410e:	0001c497          	auipc	s1,0x1c
    80004112:	04a48493          	addi	s1,s1,74 # 80020158 <ftable+0x18>
    80004116:	0001d717          	auipc	a4,0x1d
    8000411a:	fe270713          	addi	a4,a4,-30 # 800210f8 <disk>
    if(f->ref == 0){
    8000411e:	40dc                	lw	a5,4(s1)
    80004120:	cf89                	beqz	a5,8000413a <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004122:	02848493          	addi	s1,s1,40
    80004126:	fee49ce3          	bne	s1,a4,8000411e <filealloc+0x26>
      f->ref = 1;  // 设置引用计数为 1
      release(&ftable.lock);  // 释放文件表锁
      return f;  // 返回分配的文件结构体
    }
  }
  release(&ftable.lock);  // 如果没有空闲文件结构体，释放锁
    8000412a:	0001c517          	auipc	a0,0x1c
    8000412e:	01650513          	addi	a0,a0,22 # 80020140 <ftable>
    80004132:	ad3fc0ef          	jal	ra,80000c04 <release>
  return 0;  // 没有可用的文件结构体
    80004136:	4481                	li	s1,0
    80004138:	a809                	j	8000414a <filealloc+0x52>
      f->ref = 1;  // 设置引用计数为 1
    8000413a:	4785                	li	a5,1
    8000413c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);  // 释放文件表锁
    8000413e:	0001c517          	auipc	a0,0x1c
    80004142:	00250513          	addi	a0,a0,2 # 80020140 <ftable>
    80004146:	abffc0ef          	jal	ra,80000c04 <release>
}
    8000414a:	8526                	mv	a0,s1
    8000414c:	60e2                	ld	ra,24(sp)
    8000414e:	6442                	ld	s0,16(sp)
    80004150:	64a2                	ld	s1,8(sp)
    80004152:	6105                	addi	sp,sp,32
    80004154:	8082                	ret

0000000080004156 <filedup>:

// 增加文件结构体的引用计数
struct file*
filedup(struct file *f)
{
    80004156:	1101                	addi	sp,sp,-32
    80004158:	ec06                	sd	ra,24(sp)
    8000415a:	e822                	sd	s0,16(sp)
    8000415c:	e426                	sd	s1,8(sp)
    8000415e:	1000                	addi	s0,sp,32
    80004160:	84aa                	mv	s1,a0
  acquire(&ftable.lock);  // 获取文件表锁
    80004162:	0001c517          	auipc	a0,0x1c
    80004166:	fde50513          	addi	a0,a0,-34 # 80020140 <ftable>
    8000416a:	a03fc0ef          	jal	ra,80000b6c <acquire>
  if(f->ref < 1)  // 如果引用计数小于 1，说明文件结构体无效
    8000416e:	40dc                	lw	a5,4(s1)
    80004170:	02f05063          	blez	a5,80004190 <filedup+0x3a>
    panic("filedup");
  f->ref++;  // 增加引用计数
    80004174:	2785                	addiw	a5,a5,1
    80004176:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);  // 释放文件表锁
    80004178:	0001c517          	auipc	a0,0x1c
    8000417c:	fc850513          	addi	a0,a0,-56 # 80020140 <ftable>
    80004180:	a85fc0ef          	jal	ra,80000c04 <release>
  return f;  // 返回文件结构体
}
    80004184:	8526                	mv	a0,s1
    80004186:	60e2                	ld	ra,24(sp)
    80004188:	6442                	ld	s0,16(sp)
    8000418a:	64a2                	ld	s1,8(sp)
    8000418c:	6105                	addi	sp,sp,32
    8000418e:	8082                	ret
    panic("filedup");
    80004190:	00003517          	auipc	a0,0x3
    80004194:	4f850513          	addi	a0,a0,1272 # 80007688 <syscalls+0x288>
    80004198:	df2fc0ef          	jal	ra,8000078a <panic>

000000008000419c <fileclose>:

// 关闭文件结构体 f，减少引用计数，当引用计数为 0 时关闭文件
void
fileclose(struct file *f)
{
    8000419c:	7139                	addi	sp,sp,-64
    8000419e:	fc06                	sd	ra,56(sp)
    800041a0:	f822                	sd	s0,48(sp)
    800041a2:	f426                	sd	s1,40(sp)
    800041a4:	f04a                	sd	s2,32(sp)
    800041a6:	ec4e                	sd	s3,24(sp)
    800041a8:	e852                	sd	s4,16(sp)
    800041aa:	e456                	sd	s5,8(sp)
    800041ac:	0080                	addi	s0,sp,64
    800041ae:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);  // 获取文件表锁
    800041b0:	0001c517          	auipc	a0,0x1c
    800041b4:	f9050513          	addi	a0,a0,-112 # 80020140 <ftable>
    800041b8:	9b5fc0ef          	jal	ra,80000b6c <acquire>
  if(f->ref < 1)  // 如果引用计数小于 1，说明文件结构体无效
    800041bc:	40dc                	lw	a5,4(s1)
    800041be:	04f05963          	blez	a5,80004210 <fileclose+0x74>
    panic("fileclose");
  if(--f->ref > 0){  // 如果引用计数大于 0，直接返回
    800041c2:	37fd                	addiw	a5,a5,-1
    800041c4:	0007871b          	sext.w	a4,a5
    800041c8:	c0dc                	sw	a5,4(s1)
    800041ca:	04e04963          	bgtz	a4,8000421c <fileclose+0x80>
    release(&ftable.lock);
    return;
  }
  ff = *f;  // 备份文件结构体
    800041ce:	0004a903          	lw	s2,0(s1)
    800041d2:	0094ca83          	lbu	s5,9(s1)
    800041d6:	0104ba03          	ld	s4,16(s1)
    800041da:	0184b983          	ld	s3,24(s1)
  f->ref = 0;  // 重置引用计数
    800041de:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;  // 重置文件类型
    800041e2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);  // 释放文件表锁
    800041e6:	0001c517          	auipc	a0,0x1c
    800041ea:	f5a50513          	addi	a0,a0,-166 # 80020140 <ftable>
    800041ee:	a17fc0ef          	jal	ra,80000c04 <release>

  // 如果文件类型是管道（pipe），则关闭管道
  if(ff.type == FD_PIPE){
    800041f2:	4785                	li	a5,1
    800041f4:	04f90363          	beq	s2,a5,8000423a <fileclose+0x9e>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800041f8:	3979                	addiw	s2,s2,-2
    800041fa:	4785                	li	a5,1
    800041fc:	0327e663          	bltu	a5,s2,80004228 <fileclose+0x8c>
    begin_op();  // 开始一个文件系统操作
    80004200:	b8fff0ef          	jal	ra,80003d8e <begin_op>
    iput(ff.ip);  // 释放 inode
    80004204:	854e                	mv	a0,s3
    80004206:	b28ff0ef          	jal	ra,8000352e <iput>
    end_op();  // 结束文件系统操作
    8000420a:	bf5ff0ef          	jal	ra,80003dfe <end_op>
    8000420e:	a829                	j	80004228 <fileclose+0x8c>
    panic("fileclose");
    80004210:	00003517          	auipc	a0,0x3
    80004214:	48050513          	addi	a0,a0,1152 # 80007690 <syscalls+0x290>
    80004218:	d72fc0ef          	jal	ra,8000078a <panic>
    release(&ftable.lock);
    8000421c:	0001c517          	auipc	a0,0x1c
    80004220:	f2450513          	addi	a0,a0,-220 # 80020140 <ftable>
    80004224:	9e1fc0ef          	jal	ra,80000c04 <release>
  }
}
    80004228:	70e2                	ld	ra,56(sp)
    8000422a:	7442                	ld	s0,48(sp)
    8000422c:	74a2                	ld	s1,40(sp)
    8000422e:	7902                	ld	s2,32(sp)
    80004230:	69e2                	ld	s3,24(sp)
    80004232:	6a42                	ld	s4,16(sp)
    80004234:	6aa2                	ld	s5,8(sp)
    80004236:	6121                	addi	sp,sp,64
    80004238:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000423a:	85d6                	mv	a1,s5
    8000423c:	8552                	mv	a0,s4
    8000423e:	2ec000ef          	jal	ra,8000452a <pipeclose>
    80004242:	b7dd                	j	80004228 <fileclose+0x8c>

0000000080004244 <filestat>:

// 获取文件 f 的元数据（如文件大小、类型等）
// addr 是一个用户虚拟地址，指向 struct stat 结构
int
filestat(struct file *f, uint64 addr)
{
    80004244:	715d                	addi	sp,sp,-80
    80004246:	e486                	sd	ra,72(sp)
    80004248:	e0a2                	sd	s0,64(sp)
    8000424a:	fc26                	sd	s1,56(sp)
    8000424c:	f84a                	sd	s2,48(sp)
    8000424e:	f44e                	sd	s3,40(sp)
    80004250:	0880                	addi	s0,sp,80
    80004252:	84aa                	mv	s1,a0
    80004254:	89ae                	mv	s3,a1
  struct proc *p = myproc();  // 获取当前进程
    80004256:	ddefd0ef          	jal	ra,80001834 <myproc>
  struct stat st;
  
  // 如果文件是 inode 类型或设备类型
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000425a:	409c                	lw	a5,0(s1)
    8000425c:	37f9                	addiw	a5,a5,-2
    8000425e:	4705                	li	a4,1
    80004260:	02f76f63          	bltu	a4,a5,8000429e <filestat+0x5a>
    80004264:	892a                	mv	s2,a0
    ilock(f->ip);  // 锁定 inode
    80004266:	6c88                	ld	a0,24(s1)
    80004268:	948ff0ef          	jal	ra,800033b0 <ilock>
    stati(f->ip, &st);  // 获取 inode 的元数据
    8000426c:	fb840593          	addi	a1,s0,-72
    80004270:	6c88                	ld	a0,24(s1)
    80004272:	ca0ff0ef          	jal	ra,80003712 <stati>
    iunlock(f->ip);  // 解锁 inode
    80004276:	6c88                	ld	a0,24(s1)
    80004278:	9e2ff0ef          	jal	ra,8000345a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)  // 将元数据复制到用户地址
    8000427c:	46e1                	li	a3,24
    8000427e:	fb840613          	addi	a2,s0,-72
    80004282:	85ce                	mv	a1,s3
    80004284:	05093503          	ld	a0,80(s2)
    80004288:	acafd0ef          	jal	ra,80001552 <copyout>
    8000428c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;  // 其他类型文件不支持
}
    80004290:	60a6                	ld	ra,72(sp)
    80004292:	6406                	ld	s0,64(sp)
    80004294:	74e2                	ld	s1,56(sp)
    80004296:	7942                	ld	s2,48(sp)
    80004298:	79a2                	ld	s3,40(sp)
    8000429a:	6161                	addi	sp,sp,80
    8000429c:	8082                	ret
  return -1;  // 其他类型文件不支持
    8000429e:	557d                	li	a0,-1
    800042a0:	bfc5                	j	80004290 <filestat+0x4c>

00000000800042a2 <fileread>:

// 从文件 f 中读取数据。
// addr 是一个用户虚拟地址。
int
fileread(struct file *f, uint64 addr, int n)
{
    800042a2:	7179                	addi	sp,sp,-48
    800042a4:	f406                	sd	ra,40(sp)
    800042a6:	f022                	sd	s0,32(sp)
    800042a8:	ec26                	sd	s1,24(sp)
    800042aa:	e84a                	sd	s2,16(sp)
    800042ac:	e44e                	sd	s3,8(sp)
    800042ae:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)  // 如果文件不可读，返回 -1
    800042b0:	00854783          	lbu	a5,8(a0)
    800042b4:	cbc1                	beqz	a5,80004344 <fileread+0xa2>
    800042b6:	84aa                	mv	s1,a0
    800042b8:	89ae                	mv	s3,a1
    800042ba:	8932                	mv	s2,a2
    return -1;

  // 根据文件类型执行不同的读取操作
  if(f->type == FD_PIPE){
    800042bc:	411c                	lw	a5,0(a0)
    800042be:	4705                	li	a4,1
    800042c0:	04e78363          	beq	a5,a4,80004306 <fileread+0x64>
    r = piperead(f->pipe, addr, n);  // 从管道中读取
  } else if(f->type == FD_DEVICE){
    800042c4:	470d                	li	a4,3
    800042c6:	04e78563          	beq	a5,a4,80004310 <fileread+0x6e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)  // 如果设备不支持读取，返回 -1
      return -1;
    r = devsw[f->major].read(1, addr, n);  // 调用设备的读取函数
  } else if(f->type == FD_INODE){
    800042ca:	4709                	li	a4,2
    800042cc:	06e79663          	bne	a5,a4,80004338 <fileread+0x96>
    ilock(f->ip);  // 锁定 inode
    800042d0:	6d08                	ld	a0,24(a0)
    800042d2:	8deff0ef          	jal	ra,800033b0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)  // 从 inode 中读取数据
    800042d6:	874a                	mv	a4,s2
    800042d8:	5094                	lw	a3,32(s1)
    800042da:	864e                	mv	a2,s3
    800042dc:	4585                	li	a1,1
    800042de:	6c88                	ld	a0,24(s1)
    800042e0:	c5cff0ef          	jal	ra,8000373c <readi>
    800042e4:	892a                	mv	s2,a0
    800042e6:	00a05563          	blez	a0,800042f0 <fileread+0x4e>
      f->off += r;  // 更新文件偏移量
    800042ea:	509c                	lw	a5,32(s1)
    800042ec:	9fa9                	addw	a5,a5,a0
    800042ee:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);  // 解锁 inode
    800042f0:	6c88                	ld	a0,24(s1)
    800042f2:	968ff0ef          	jal	ra,8000345a <iunlock>
  } else {
    panic("fileread");  // 不支持的文件类型
  }

  return r;  // 返回读取的字节数
}
    800042f6:	854a                	mv	a0,s2
    800042f8:	70a2                	ld	ra,40(sp)
    800042fa:	7402                	ld	s0,32(sp)
    800042fc:	64e2                	ld	s1,24(sp)
    800042fe:	6942                	ld	s2,16(sp)
    80004300:	69a2                	ld	s3,8(sp)
    80004302:	6145                	addi	sp,sp,48
    80004304:	8082                	ret
    r = piperead(f->pipe, addr, n);  // 从管道中读取
    80004306:	6908                	ld	a0,16(a0)
    80004308:	34e000ef          	jal	ra,80004656 <piperead>
    8000430c:	892a                	mv	s2,a0
    8000430e:	b7e5                	j	800042f6 <fileread+0x54>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)  // 如果设备不支持读取，返回 -1
    80004310:	02451783          	lh	a5,36(a0)
    80004314:	03079693          	slli	a3,a5,0x30
    80004318:	92c1                	srli	a3,a3,0x30
    8000431a:	4725                	li	a4,9
    8000431c:	02d76663          	bltu	a4,a3,80004348 <fileread+0xa6>
    80004320:	0792                	slli	a5,a5,0x4
    80004322:	0001c717          	auipc	a4,0x1c
    80004326:	d7e70713          	addi	a4,a4,-642 # 800200a0 <devsw>
    8000432a:	97ba                	add	a5,a5,a4
    8000432c:	639c                	ld	a5,0(a5)
    8000432e:	cf99                	beqz	a5,8000434c <fileread+0xaa>
    r = devsw[f->major].read(1, addr, n);  // 调用设备的读取函数
    80004330:	4505                	li	a0,1
    80004332:	9782                	jalr	a5
    80004334:	892a                	mv	s2,a0
    80004336:	b7c1                	j	800042f6 <fileread+0x54>
    panic("fileread");  // 不支持的文件类型
    80004338:	00003517          	auipc	a0,0x3
    8000433c:	36850513          	addi	a0,a0,872 # 800076a0 <syscalls+0x2a0>
    80004340:	c4afc0ef          	jal	ra,8000078a <panic>
    return -1;
    80004344:	597d                	li	s2,-1
    80004346:	bf45                	j	800042f6 <fileread+0x54>
      return -1;
    80004348:	597d                	li	s2,-1
    8000434a:	b775                	j	800042f6 <fileread+0x54>
    8000434c:	597d                	li	s2,-1
    8000434e:	b765                	j	800042f6 <fileread+0x54>

0000000080004350 <filewrite>:

// 向文件 f 中写入数据。
// addr 是一个用户虚拟地址。
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004350:	715d                	addi	sp,sp,-80
    80004352:	e486                	sd	ra,72(sp)
    80004354:	e0a2                	sd	s0,64(sp)
    80004356:	fc26                	sd	s1,56(sp)
    80004358:	f84a                	sd	s2,48(sp)
    8000435a:	f44e                	sd	s3,40(sp)
    8000435c:	f052                	sd	s4,32(sp)
    8000435e:	ec56                	sd	s5,24(sp)
    80004360:	e85a                	sd	s6,16(sp)
    80004362:	e45e                	sd	s7,8(sp)
    80004364:	e062                	sd	s8,0(sp)
    80004366:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)  // 如果文件不可写，返回 -1
    80004368:	00954783          	lbu	a5,9(a0)
    8000436c:	0e078863          	beqz	a5,8000445c <filewrite+0x10c>
    80004370:	892a                	mv	s2,a0
    80004372:	8aae                	mv	s5,a1
    80004374:	8a32                	mv	s4,a2
    return -1;

  // 根据文件类型执行不同的写入操作
  if(f->type == FD_PIPE){
    80004376:	411c                	lw	a5,0(a0)
    80004378:	4705                	li	a4,1
    8000437a:	02e78263          	beq	a5,a4,8000439e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);  // 向管道中写入
  } else if(f->type == FD_DEVICE){
    8000437e:	470d                	li	a4,3
    80004380:	02e78463          	beq	a5,a4,800043a8 <filewrite+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)  // 如果设备不支持写入，返回 -1
      return -1;
    ret = devsw[f->major].write(1, addr, n);  // 调用设备的写入函数
  } else if(f->type == FD_INODE){
    80004384:	4709                	li	a4,2
    80004386:	0ce79563          	bne	a5,a4,80004450 <filewrite+0x100>
    // 分多次写入，以避免超过最大日志事务大小，包括 inode、间接块、分配块等
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000438a:	0ac05163          	blez	a2,8000442c <filewrite+0xdc>
    int i = 0;
    8000438e:	4981                	li	s3,0
    80004390:	6b05                	lui	s6,0x1
    80004392:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004396:	6b85                	lui	s7,0x1
    80004398:	c00b8b9b          	addiw	s7,s7,-1024
    8000439c:	a041                	j	8000441c <filewrite+0xcc>
    ret = pipewrite(f->pipe, addr, n);  // 向管道中写入
    8000439e:	6908                	ld	a0,16(a0)
    800043a0:	1e2000ef          	jal	ra,80004582 <pipewrite>
    800043a4:	8a2a                	mv	s4,a0
    800043a6:	a071                	j	80004432 <filewrite+0xe2>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)  // 如果设备不支持写入，返回 -1
    800043a8:	02451783          	lh	a5,36(a0)
    800043ac:	03079693          	slli	a3,a5,0x30
    800043b0:	92c1                	srli	a3,a3,0x30
    800043b2:	4725                	li	a4,9
    800043b4:	0ad76663          	bltu	a4,a3,80004460 <filewrite+0x110>
    800043b8:	0792                	slli	a5,a5,0x4
    800043ba:	0001c717          	auipc	a4,0x1c
    800043be:	ce670713          	addi	a4,a4,-794 # 800200a0 <devsw>
    800043c2:	97ba                	add	a5,a5,a4
    800043c4:	679c                	ld	a5,8(a5)
    800043c6:	cfd9                	beqz	a5,80004464 <filewrite+0x114>
    ret = devsw[f->major].write(1, addr, n);  // 调用设备的写入函数
    800043c8:	4505                	li	a0,1
    800043ca:	9782                	jalr	a5
    800043cc:	8a2a                	mv	s4,a0
    800043ce:	a095                	j	80004432 <filewrite+0xe2>
    800043d0:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)  // 如果写入数据超过最大限制，分批次写入
        n1 = max;

      begin_op();  // 开始一个文件系统操作
    800043d4:	9bbff0ef          	jal	ra,80003d8e <begin_op>
      ilock(f->ip);  // 锁定 inode
    800043d8:	01893503          	ld	a0,24(s2)
    800043dc:	fd5fe0ef          	jal	ra,800033b0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800043e0:	8762                	mv	a4,s8
    800043e2:	02092683          	lw	a3,32(s2)
    800043e6:	01598633          	add	a2,s3,s5
    800043ea:	4585                	li	a1,1
    800043ec:	01893503          	ld	a0,24(s2)
    800043f0:	c30ff0ef          	jal	ra,80003820 <writei>
    800043f4:	84aa                	mv	s1,a0
    800043f6:	00a05763          	blez	a0,80004404 <filewrite+0xb4>
        f->off += r;  // 更新文件偏移量
    800043fa:	02092783          	lw	a5,32(s2)
    800043fe:	9fa9                	addw	a5,a5,a0
    80004400:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);  // 解锁 inode
    80004404:	01893503          	ld	a0,24(s2)
    80004408:	852ff0ef          	jal	ra,8000345a <iunlock>
      end_op();  // 结束文件系统操作
    8000440c:	9f3ff0ef          	jal	ra,80003dfe <end_op>

      if(r != n1){  // 如果写入不完全，退出
    80004410:	009c1f63          	bne	s8,s1,8000442e <filewrite+0xde>
        break;
      }
      i += r;
    80004414:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004418:	0149db63          	bge	s3,s4,8000442e <filewrite+0xde>
      int n1 = n - i;
    8000441c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)  // 如果写入数据超过最大限制，分批次写入
    80004420:	84be                	mv	s1,a5
    80004422:	2781                	sext.w	a5,a5
    80004424:	fafb56e3          	bge	s6,a5,800043d0 <filewrite+0x80>
    80004428:	84de                	mv	s1,s7
    8000442a:	b75d                	j	800043d0 <filewrite+0x80>
    int i = 0;
    8000442c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);  // 如果写入完全成功，返回写入字节数，否则返回 -1
    8000442e:	013a1f63          	bne	s4,s3,8000444c <filewrite+0xfc>
  } else {
    panic("filewrite");  // 不支持的文件类型
  }

  return ret;  // 返回写入的字节数
}
    80004432:	8552                	mv	a0,s4
    80004434:	60a6                	ld	ra,72(sp)
    80004436:	6406                	ld	s0,64(sp)
    80004438:	74e2                	ld	s1,56(sp)
    8000443a:	7942                	ld	s2,48(sp)
    8000443c:	79a2                	ld	s3,40(sp)
    8000443e:	7a02                	ld	s4,32(sp)
    80004440:	6ae2                	ld	s5,24(sp)
    80004442:	6b42                	ld	s6,16(sp)
    80004444:	6ba2                	ld	s7,8(sp)
    80004446:	6c02                	ld	s8,0(sp)
    80004448:	6161                	addi	sp,sp,80
    8000444a:	8082                	ret
    ret = (i == n ? n : -1);  // 如果写入完全成功，返回写入字节数，否则返回 -1
    8000444c:	5a7d                	li	s4,-1
    8000444e:	b7d5                	j	80004432 <filewrite+0xe2>
    panic("filewrite");  // 不支持的文件类型
    80004450:	00003517          	auipc	a0,0x3
    80004454:	26050513          	addi	a0,a0,608 # 800076b0 <syscalls+0x2b0>
    80004458:	b32fc0ef          	jal	ra,8000078a <panic>
    return -1;
    8000445c:	5a7d                	li	s4,-1
    8000445e:	bfd1                	j	80004432 <filewrite+0xe2>
      return -1;
    80004460:	5a7d                	li	s4,-1
    80004462:	bfc1                	j	80004432 <filewrite+0xe2>
    80004464:	5a7d                	li	s4,-1
    80004466:	b7f1                	j	80004432 <filewrite+0xe2>

0000000080004468 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004468:	7179                	addi	sp,sp,-48
    8000446a:	f406                	sd	ra,40(sp)
    8000446c:	f022                	sd	s0,32(sp)
    8000446e:	ec26                	sd	s1,24(sp)
    80004470:	e84a                	sd	s2,16(sp)
    80004472:	e44e                	sd	s3,8(sp)
    80004474:	e052                	sd	s4,0(sp)
    80004476:	1800                	addi	s0,sp,48
    80004478:	84aa                	mv	s1,a0
    8000447a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000447c:	0005b023          	sd	zero,0(a1)
    80004480:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004484:	c75ff0ef          	jal	ra,800040f8 <filealloc>
    80004488:	e088                	sd	a0,0(s1)
    8000448a:	cd35                	beqz	a0,80004506 <pipealloc+0x9e>
    8000448c:	c6dff0ef          	jal	ra,800040f8 <filealloc>
    80004490:	00aa3023          	sd	a0,0(s4)
    80004494:	c52d                	beqz	a0,800044fe <pipealloc+0x96>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004496:	e06fc0ef          	jal	ra,80000a9c <kalloc>
    8000449a:	892a                	mv	s2,a0
    8000449c:	cd31                	beqz	a0,800044f8 <pipealloc+0x90>
    goto bad;
  pi->readopen = 1;
    8000449e:	4985                	li	s3,1
    800044a0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800044a4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800044a8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800044ac:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800044b0:	00003597          	auipc	a1,0x3
    800044b4:	21058593          	addi	a1,a1,528 # 800076c0 <syscalls+0x2c0>
    800044b8:	e34fc0ef          	jal	ra,80000aec <initlock>
  (*f0)->type = FD_PIPE;
    800044bc:	609c                	ld	a5,0(s1)
    800044be:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800044c2:	609c                	ld	a5,0(s1)
    800044c4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800044c8:	609c                	ld	a5,0(s1)
    800044ca:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800044ce:	609c                	ld	a5,0(s1)
    800044d0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800044d4:	000a3783          	ld	a5,0(s4)
    800044d8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800044dc:	000a3783          	ld	a5,0(s4)
    800044e0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800044e4:	000a3783          	ld	a5,0(s4)
    800044e8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800044ec:	000a3783          	ld	a5,0(s4)
    800044f0:	0127b823          	sd	s2,16(a5)
  return 0;
    800044f4:	4501                	li	a0,0
    800044f6:	a005                	j	80004516 <pipealloc+0xae>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800044f8:	6088                	ld	a0,0(s1)
    800044fa:	e501                	bnez	a0,80004502 <pipealloc+0x9a>
    800044fc:	a029                	j	80004506 <pipealloc+0x9e>
    800044fe:	6088                	ld	a0,0(s1)
    80004500:	c11d                	beqz	a0,80004526 <pipealloc+0xbe>
    fileclose(*f0);
    80004502:	c9bff0ef          	jal	ra,8000419c <fileclose>
  if(*f1)
    80004506:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000450a:	557d                	li	a0,-1
  if(*f1)
    8000450c:	c789                	beqz	a5,80004516 <pipealloc+0xae>
    fileclose(*f1);
    8000450e:	853e                	mv	a0,a5
    80004510:	c8dff0ef          	jal	ra,8000419c <fileclose>
  return -1;
    80004514:	557d                	li	a0,-1
}
    80004516:	70a2                	ld	ra,40(sp)
    80004518:	7402                	ld	s0,32(sp)
    8000451a:	64e2                	ld	s1,24(sp)
    8000451c:	6942                	ld	s2,16(sp)
    8000451e:	69a2                	ld	s3,8(sp)
    80004520:	6a02                	ld	s4,0(sp)
    80004522:	6145                	addi	sp,sp,48
    80004524:	8082                	ret
  return -1;
    80004526:	557d                	li	a0,-1
    80004528:	b7fd                	j	80004516 <pipealloc+0xae>

000000008000452a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000452a:	1101                	addi	sp,sp,-32
    8000452c:	ec06                	sd	ra,24(sp)
    8000452e:	e822                	sd	s0,16(sp)
    80004530:	e426                	sd	s1,8(sp)
    80004532:	e04a                	sd	s2,0(sp)
    80004534:	1000                	addi	s0,sp,32
    80004536:	84aa                	mv	s1,a0
    80004538:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000453a:	e32fc0ef          	jal	ra,80000b6c <acquire>
  if(writable){
    8000453e:	02090763          	beqz	s2,8000456c <pipeclose+0x42>
    pi->writeopen = 0;
    80004542:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004546:	21848513          	addi	a0,s1,536
    8000454a:	c9bfd0ef          	jal	ra,800021e4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000454e:	2204b783          	ld	a5,544(s1)
    80004552:	e785                	bnez	a5,8000457a <pipeclose+0x50>
    release(&pi->lock);
    80004554:	8526                	mv	a0,s1
    80004556:	eaefc0ef          	jal	ra,80000c04 <release>
    kfree((char*)pi);
    8000455a:	8526                	mv	a0,s1
    8000455c:	c60fc0ef          	jal	ra,800009bc <kfree>
  } else
    release(&pi->lock);
}
    80004560:	60e2                	ld	ra,24(sp)
    80004562:	6442                	ld	s0,16(sp)
    80004564:	64a2                	ld	s1,8(sp)
    80004566:	6902                	ld	s2,0(sp)
    80004568:	6105                	addi	sp,sp,32
    8000456a:	8082                	ret
    pi->readopen = 0;
    8000456c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004570:	21c48513          	addi	a0,s1,540
    80004574:	c71fd0ef          	jal	ra,800021e4 <wakeup>
    80004578:	bfd9                	j	8000454e <pipeclose+0x24>
    release(&pi->lock);
    8000457a:	8526                	mv	a0,s1
    8000457c:	e88fc0ef          	jal	ra,80000c04 <release>
}
    80004580:	b7c5                	j	80004560 <pipeclose+0x36>

0000000080004582 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004582:	711d                	addi	sp,sp,-96
    80004584:	ec86                	sd	ra,88(sp)
    80004586:	e8a2                	sd	s0,80(sp)
    80004588:	e4a6                	sd	s1,72(sp)
    8000458a:	e0ca                	sd	s2,64(sp)
    8000458c:	fc4e                	sd	s3,56(sp)
    8000458e:	f852                	sd	s4,48(sp)
    80004590:	f456                	sd	s5,40(sp)
    80004592:	f05a                	sd	s6,32(sp)
    80004594:	ec5e                	sd	s7,24(sp)
    80004596:	e862                	sd	s8,16(sp)
    80004598:	1080                	addi	s0,sp,96
    8000459a:	84aa                	mv	s1,a0
    8000459c:	8aae                	mv	s5,a1
    8000459e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800045a0:	a94fd0ef          	jal	ra,80001834 <myproc>
    800045a4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800045a6:	8526                	mv	a0,s1
    800045a8:	dc4fc0ef          	jal	ra,80000b6c <acquire>
  while(i < n){
    800045ac:	09405c63          	blez	s4,80004644 <pipewrite+0xc2>
  int i = 0;
    800045b0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800045b2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800045b4:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800045b8:	21c48b93          	addi	s7,s1,540
    800045bc:	a81d                	j	800045f2 <pipewrite+0x70>
      release(&pi->lock);
    800045be:	8526                	mv	a0,s1
    800045c0:	e44fc0ef          	jal	ra,80000c04 <release>
      return -1;
    800045c4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800045c6:	854a                	mv	a0,s2
    800045c8:	60e6                	ld	ra,88(sp)
    800045ca:	6446                	ld	s0,80(sp)
    800045cc:	64a6                	ld	s1,72(sp)
    800045ce:	6906                	ld	s2,64(sp)
    800045d0:	79e2                	ld	s3,56(sp)
    800045d2:	7a42                	ld	s4,48(sp)
    800045d4:	7aa2                	ld	s5,40(sp)
    800045d6:	7b02                	ld	s6,32(sp)
    800045d8:	6be2                	ld	s7,24(sp)
    800045da:	6c42                	ld	s8,16(sp)
    800045dc:	6125                	addi	sp,sp,96
    800045de:	8082                	ret
      wakeup(&pi->nread);
    800045e0:	8562                	mv	a0,s8
    800045e2:	c03fd0ef          	jal	ra,800021e4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800045e6:	85a6                	mv	a1,s1
    800045e8:	855e                	mv	a0,s7
    800045ea:	f4afd0ef          	jal	ra,80001d34 <sleep>
  while(i < n){
    800045ee:	05495c63          	bge	s2,s4,80004646 <pipewrite+0xc4>
    if(pi->readopen == 0 || killed(pr)){
    800045f2:	2204a783          	lw	a5,544(s1)
    800045f6:	d7e1                	beqz	a5,800045be <pipewrite+0x3c>
    800045f8:	854e                	mv	a0,s3
    800045fa:	815fd0ef          	jal	ra,80001e0e <killed>
    800045fe:	f161                	bnez	a0,800045be <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004600:	2184a783          	lw	a5,536(s1)
    80004604:	21c4a703          	lw	a4,540(s1)
    80004608:	2007879b          	addiw	a5,a5,512
    8000460c:	fcf70ae3          	beq	a4,a5,800045e0 <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004610:	4685                	li	a3,1
    80004612:	01590633          	add	a2,s2,s5
    80004616:	faf40593          	addi	a1,s0,-81
    8000461a:	0509b503          	ld	a0,80(s3)
    8000461e:	ffbfc0ef          	jal	ra,80001618 <copyin>
    80004622:	03650263          	beq	a0,s6,80004646 <pipewrite+0xc4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004626:	21c4a783          	lw	a5,540(s1)
    8000462a:	0017871b          	addiw	a4,a5,1
    8000462e:	20e4ae23          	sw	a4,540(s1)
    80004632:	1ff7f793          	andi	a5,a5,511
    80004636:	97a6                	add	a5,a5,s1
    80004638:	faf44703          	lbu	a4,-81(s0)
    8000463c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004640:	2905                	addiw	s2,s2,1
    80004642:	b775                	j	800045ee <pipewrite+0x6c>
  int i = 0;
    80004644:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004646:	21848513          	addi	a0,s1,536
    8000464a:	b9bfd0ef          	jal	ra,800021e4 <wakeup>
  release(&pi->lock);
    8000464e:	8526                	mv	a0,s1
    80004650:	db4fc0ef          	jal	ra,80000c04 <release>
  return i;
    80004654:	bf8d                	j	800045c6 <pipewrite+0x44>

0000000080004656 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004656:	715d                	addi	sp,sp,-80
    80004658:	e486                	sd	ra,72(sp)
    8000465a:	e0a2                	sd	s0,64(sp)
    8000465c:	fc26                	sd	s1,56(sp)
    8000465e:	f84a                	sd	s2,48(sp)
    80004660:	f44e                	sd	s3,40(sp)
    80004662:	f052                	sd	s4,32(sp)
    80004664:	ec56                	sd	s5,24(sp)
    80004666:	e85a                	sd	s6,16(sp)
    80004668:	0880                	addi	s0,sp,80
    8000466a:	84aa                	mv	s1,a0
    8000466c:	892e                	mv	s2,a1
    8000466e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004670:	9c4fd0ef          	jal	ra,80001834 <myproc>
    80004674:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004676:	8526                	mv	a0,s1
    80004678:	cf4fc0ef          	jal	ra,80000b6c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000467c:	2184a703          	lw	a4,536(s1)
    80004680:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004684:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004688:	02f71363          	bne	a4,a5,800046ae <piperead+0x58>
    8000468c:	2244a783          	lw	a5,548(s1)
    80004690:	cf99                	beqz	a5,800046ae <piperead+0x58>
    if(killed(pr)){
    80004692:	8552                	mv	a0,s4
    80004694:	f7afd0ef          	jal	ra,80001e0e <killed>
    80004698:	e149                	bnez	a0,8000471a <piperead+0xc4>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000469a:	85a6                	mv	a1,s1
    8000469c:	854e                	mv	a0,s3
    8000469e:	e96fd0ef          	jal	ra,80001d34 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800046a2:	2184a703          	lw	a4,536(s1)
    800046a6:	21c4a783          	lw	a5,540(s1)
    800046aa:	fef701e3          	beq	a4,a5,8000468c <piperead+0x36>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800046ae:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800046b0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800046b2:	05505263          	blez	s5,800046f6 <piperead+0xa0>
    if(pi->nread == pi->nwrite)
    800046b6:	2184a783          	lw	a5,536(s1)
    800046ba:	21c4a703          	lw	a4,540(s1)
    800046be:	02f70c63          	beq	a4,a5,800046f6 <piperead+0xa0>
    ch = pi->data[pi->nread % PIPESIZE];
    800046c2:	1ff7f793          	andi	a5,a5,511
    800046c6:	97a6                	add	a5,a5,s1
    800046c8:	0187c783          	lbu	a5,24(a5)
    800046cc:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800046d0:	4685                	li	a3,1
    800046d2:	fbf40613          	addi	a2,s0,-65
    800046d6:	85ca                	mv	a1,s2
    800046d8:	050a3503          	ld	a0,80(s4)
    800046dc:	e77fc0ef          	jal	ra,80001552 <copyout>
    800046e0:	05650263          	beq	a0,s6,80004724 <piperead+0xce>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    800046e4:	2184a783          	lw	a5,536(s1)
    800046e8:	2785                	addiw	a5,a5,1
    800046ea:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800046ee:	2985                	addiw	s3,s3,1
    800046f0:	0905                	addi	s2,s2,1
    800046f2:	fd3a92e3          	bne	s5,s3,800046b6 <piperead+0x60>
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800046f6:	21c48513          	addi	a0,s1,540
    800046fa:	aebfd0ef          	jal	ra,800021e4 <wakeup>
  release(&pi->lock);
    800046fe:	8526                	mv	a0,s1
    80004700:	d04fc0ef          	jal	ra,80000c04 <release>
  return i;
}
    80004704:	854e                	mv	a0,s3
    80004706:	60a6                	ld	ra,72(sp)
    80004708:	6406                	ld	s0,64(sp)
    8000470a:	74e2                	ld	s1,56(sp)
    8000470c:	7942                	ld	s2,48(sp)
    8000470e:	79a2                	ld	s3,40(sp)
    80004710:	7a02                	ld	s4,32(sp)
    80004712:	6ae2                	ld	s5,24(sp)
    80004714:	6b42                	ld	s6,16(sp)
    80004716:	6161                	addi	sp,sp,80
    80004718:	8082                	ret
      release(&pi->lock);
    8000471a:	8526                	mv	a0,s1
    8000471c:	ce8fc0ef          	jal	ra,80000c04 <release>
      return -1;
    80004720:	59fd                	li	s3,-1
    80004722:	b7cd                	j	80004704 <piperead+0xae>
      if(i == 0)
    80004724:	fc0999e3          	bnez	s3,800046f6 <piperead+0xa0>
        i = -1;
    80004728:	89aa                	mv	s3,a0
    8000472a:	b7f1                	j	800046f6 <piperead+0xa0>

000000008000472c <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    8000472c:	1141                	addi	sp,sp,-16
    8000472e:	e422                	sd	s0,8(sp)
    80004730:	0800                	addi	s0,sp,16
    80004732:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004734:	8905                	andi	a0,a0,1
    80004736:	c111                	beqz	a0,8000473a <flags2perm+0xe>
      perm = PTE_X;
    80004738:	4521                	li	a0,8
    if(flags & 0x2)
    8000473a:	8b89                	andi	a5,a5,2
    8000473c:	c399                	beqz	a5,80004742 <flags2perm+0x16>
      perm |= PTE_W;
    8000473e:	00456513          	ori	a0,a0,4
    return perm;
}
    80004742:	6422                	ld	s0,8(sp)
    80004744:	0141                	addi	sp,sp,16
    80004746:	8082                	ret

0000000080004748 <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    80004748:	de010113          	addi	sp,sp,-544
    8000474c:	20113c23          	sd	ra,536(sp)
    80004750:	20813823          	sd	s0,528(sp)
    80004754:	20913423          	sd	s1,520(sp)
    80004758:	21213023          	sd	s2,512(sp)
    8000475c:	ffce                	sd	s3,504(sp)
    8000475e:	fbd2                	sd	s4,496(sp)
    80004760:	f7d6                	sd	s5,488(sp)
    80004762:	f3da                	sd	s6,480(sp)
    80004764:	efde                	sd	s7,472(sp)
    80004766:	ebe2                	sd	s8,464(sp)
    80004768:	e7e6                	sd	s9,456(sp)
    8000476a:	e3ea                	sd	s10,448(sp)
    8000476c:	ff6e                	sd	s11,440(sp)
    8000476e:	1400                	addi	s0,sp,544
    80004770:	892a                	mv	s2,a0
    80004772:	dea43423          	sd	a0,-536(s0)
    80004776:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000477a:	8bafd0ef          	jal	ra,80001834 <myproc>
    8000477e:	84aa                	mv	s1,a0

  begin_op();
    80004780:	e0eff0ef          	jal	ra,80003d8e <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    80004784:	854a                	mv	a0,s2
    80004786:	c18ff0ef          	jal	ra,80003b9e <namei>
    8000478a:	c13d                	beqz	a0,800047f0 <kexec+0xa8>
    8000478c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000478e:	c23fe0ef          	jal	ra,800033b0 <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004792:	04000713          	li	a4,64
    80004796:	4681                	li	a3,0
    80004798:	e5040613          	addi	a2,s0,-432
    8000479c:	4581                	li	a1,0
    8000479e:	8556                	mv	a0,s5
    800047a0:	f9dfe0ef          	jal	ra,8000373c <readi>
    800047a4:	04000793          	li	a5,64
    800047a8:	00f51a63          	bne	a0,a5,800047bc <kexec+0x74>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    800047ac:	e5042703          	lw	a4,-432(s0)
    800047b0:	464c47b7          	lui	a5,0x464c4
    800047b4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800047b8:	04f70063          	beq	a4,a5,800047f8 <kexec+0xb0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800047bc:	8556                	mv	a0,s5
    800047be:	df9fe0ef          	jal	ra,800035b6 <iunlockput>
    end_op();
    800047c2:	e3cff0ef          	jal	ra,80003dfe <end_op>
  }
  return -1;
    800047c6:	557d                	li	a0,-1
}
    800047c8:	21813083          	ld	ra,536(sp)
    800047cc:	21013403          	ld	s0,528(sp)
    800047d0:	20813483          	ld	s1,520(sp)
    800047d4:	20013903          	ld	s2,512(sp)
    800047d8:	79fe                	ld	s3,504(sp)
    800047da:	7a5e                	ld	s4,496(sp)
    800047dc:	7abe                	ld	s5,488(sp)
    800047de:	7b1e                	ld	s6,480(sp)
    800047e0:	6bfe                	ld	s7,472(sp)
    800047e2:	6c5e                	ld	s8,464(sp)
    800047e4:	6cbe                	ld	s9,456(sp)
    800047e6:	6d1e                	ld	s10,448(sp)
    800047e8:	7dfa                	ld	s11,440(sp)
    800047ea:	22010113          	addi	sp,sp,544
    800047ee:	8082                	ret
    end_op();
    800047f0:	e0eff0ef          	jal	ra,80003dfe <end_op>
    return -1;
    800047f4:	557d                	li	a0,-1
    800047f6:	bfc9                	j	800047c8 <kexec+0x80>
  if((pagetable = proc_pagetable(p)) == 0)
    800047f8:	8526                	mv	a0,s1
    800047fa:	940fd0ef          	jal	ra,8000193a <proc_pagetable>
    800047fe:	8b2a                	mv	s6,a0
    80004800:	dd55                	beqz	a0,800047bc <kexec+0x74>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004802:	e7042783          	lw	a5,-400(s0)
    80004806:	e8845703          	lhu	a4,-376(s0)
    8000480a:	c325                	beqz	a4,8000486a <kexec+0x122>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000480c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000480e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004812:	6a05                	lui	s4,0x1
    80004814:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004818:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000481c:	6d85                	lui	s11,0x1
    8000481e:	7d7d                	lui	s10,0xfffff
    80004820:	a411                	j	80004a24 <kexec+0x2dc>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004822:	00003517          	auipc	a0,0x3
    80004826:	ea650513          	addi	a0,a0,-346 # 800076c8 <syscalls+0x2c8>
    8000482a:	f61fb0ef          	jal	ra,8000078a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000482e:	874a                	mv	a4,s2
    80004830:	009c86bb          	addw	a3,s9,s1
    80004834:	4581                	li	a1,0
    80004836:	8556                	mv	a0,s5
    80004838:	f05fe0ef          	jal	ra,8000373c <readi>
    8000483c:	2501                	sext.w	a0,a0
    8000483e:	18a91263          	bne	s2,a0,800049c2 <kexec+0x27a>
  for(i = 0; i < sz; i += PGSIZE){
    80004842:	009d84bb          	addw	s1,s11,s1
    80004846:	013d09bb          	addw	s3,s10,s3
    8000484a:	1b74fd63          	bgeu	s1,s7,80004a04 <kexec+0x2bc>
    pa = walkaddr(pagetable, va + i);
    8000484e:	02049593          	slli	a1,s1,0x20
    80004852:	9181                	srli	a1,a1,0x20
    80004854:	95e2                	add	a1,a1,s8
    80004856:	855a                	mv	a0,s6
    80004858:	efefc0ef          	jal	ra,80000f56 <walkaddr>
    8000485c:	862a                	mv	a2,a0
    if(pa == 0)
    8000485e:	d171                	beqz	a0,80004822 <kexec+0xda>
      n = PGSIZE;
    80004860:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004862:	fd49f6e3          	bgeu	s3,s4,8000482e <kexec+0xe6>
      n = sz - i;
    80004866:	894e                	mv	s2,s3
    80004868:	b7d9                	j	8000482e <kexec+0xe6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000486a:	4901                	li	s2,0
  iunlockput(ip);
    8000486c:	8556                	mv	a0,s5
    8000486e:	d49fe0ef          	jal	ra,800035b6 <iunlockput>
  end_op();
    80004872:	d8cff0ef          	jal	ra,80003dfe <end_op>
  p = myproc();
    80004876:	fbffc0ef          	jal	ra,80001834 <myproc>
    8000487a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000487c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004880:	6785                	lui	a5,0x1
    80004882:	17fd                	addi	a5,a5,-1
    80004884:	993e                	add	s2,s2,a5
    80004886:	77fd                	lui	a5,0xfffff
    80004888:	00f977b3          	and	a5,s2,a5
    8000488c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    80004890:	4691                	li	a3,4
    80004892:	6609                	lui	a2,0x2
    80004894:	963e                	add	a2,a2,a5
    80004896:	85be                	mv	a1,a5
    80004898:	855a                	mv	a0,s6
    8000489a:	987fc0ef          	jal	ra,80001220 <uvmalloc>
    8000489e:	8c2a                	mv	s8,a0
  ip = 0;
    800048a0:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    800048a2:	12050063          	beqz	a0,800049c2 <kexec+0x27a>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    800048a6:	75f9                	lui	a1,0xffffe
    800048a8:	95aa                	add	a1,a1,a0
    800048aa:	855a                	mv	a0,s6
    800048ac:	b3bfc0ef          	jal	ra,800013e6 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    800048b0:	7afd                	lui	s5,0xfffff
    800048b2:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800048b4:	df043783          	ld	a5,-528(s0)
    800048b8:	6388                	ld	a0,0(a5)
    800048ba:	c135                	beqz	a0,8000491e <kexec+0x1d6>
    800048bc:	e9040993          	addi	s3,s0,-368
    800048c0:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800048c4:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800048c6:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800048c8:	cf0fc0ef          	jal	ra,80000db8 <strlen>
    800048cc:	0015079b          	addiw	a5,a0,1
    800048d0:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800048d4:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800048d8:	11596a63          	bltu	s2,s5,800049ec <kexec+0x2a4>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800048dc:	df043d83          	ld	s11,-528(s0)
    800048e0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800048e4:	8552                	mv	a0,s4
    800048e6:	cd2fc0ef          	jal	ra,80000db8 <strlen>
    800048ea:	0015069b          	addiw	a3,a0,1
    800048ee:	8652                	mv	a2,s4
    800048f0:	85ca                	mv	a1,s2
    800048f2:	855a                	mv	a0,s6
    800048f4:	c5ffc0ef          	jal	ra,80001552 <copyout>
    800048f8:	0e054e63          	bltz	a0,800049f4 <kexec+0x2ac>
    ustack[argc] = sp;
    800048fc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004900:	0485                	addi	s1,s1,1
    80004902:	008d8793          	addi	a5,s11,8
    80004906:	def43823          	sd	a5,-528(s0)
    8000490a:	008db503          	ld	a0,8(s11)
    8000490e:	c911                	beqz	a0,80004922 <kexec+0x1da>
    if(argc >= MAXARG)
    80004910:	09a1                	addi	s3,s3,8
    80004912:	fb3c9be3          	bne	s9,s3,800048c8 <kexec+0x180>
  sz = sz1;
    80004916:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000491a:	4a81                	li	s5,0
    8000491c:	a05d                	j	800049c2 <kexec+0x27a>
  sp = sz;
    8000491e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004920:	4481                	li	s1,0
  ustack[argc] = 0;
    80004922:	00349793          	slli	a5,s1,0x3
    80004926:	f9040713          	addi	a4,s0,-112
    8000492a:	97ba                	add	a5,a5,a4
    8000492c:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffddcc8>
  sp -= (argc+1) * sizeof(uint64);
    80004930:	00148693          	addi	a3,s1,1
    80004934:	068e                	slli	a3,a3,0x3
    80004936:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000493a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000493e:	01597663          	bgeu	s2,s5,8000494a <kexec+0x202>
  sz = sz1;
    80004942:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004946:	4a81                	li	s5,0
    80004948:	a8ad                	j	800049c2 <kexec+0x27a>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000494a:	e9040613          	addi	a2,s0,-368
    8000494e:	85ca                	mv	a1,s2
    80004950:	855a                	mv	a0,s6
    80004952:	c01fc0ef          	jal	ra,80001552 <copyout>
    80004956:	0a054363          	bltz	a0,800049fc <kexec+0x2b4>
  p->trapframe->a1 = sp;
    8000495a:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    8000495e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004962:	de843783          	ld	a5,-536(s0)
    80004966:	0007c703          	lbu	a4,0(a5)
    8000496a:	cf11                	beqz	a4,80004986 <kexec+0x23e>
    8000496c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000496e:	02f00693          	li	a3,47
    80004972:	a039                	j	80004980 <kexec+0x238>
      last = s+1;
    80004974:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004978:	0785                	addi	a5,a5,1
    8000497a:	fff7c703          	lbu	a4,-1(a5)
    8000497e:	c701                	beqz	a4,80004986 <kexec+0x23e>
    if(*s == '/')
    80004980:	fed71ce3          	bne	a4,a3,80004978 <kexec+0x230>
    80004984:	bfc5                	j	80004974 <kexec+0x22c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004986:	4641                	li	a2,16
    80004988:	de843583          	ld	a1,-536(s0)
    8000498c:	158b8513          	addi	a0,s7,344
    80004990:	bf6fc0ef          	jal	ra,80000d86 <safestrcpy>
  oldpagetable = p->pagetable;
    80004994:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004998:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000499c:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    800049a0:	058bb783          	ld	a5,88(s7)
    800049a4:	e6843703          	ld	a4,-408(s0)
    800049a8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800049aa:	058bb783          	ld	a5,88(s7)
    800049ae:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800049b2:	85ea                	mv	a1,s10
    800049b4:	80afd0ef          	jal	ra,800019be <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800049b8:	0004851b          	sext.w	a0,s1
    800049bc:	b531                	j	800047c8 <kexec+0x80>
    800049be:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800049c2:	df843583          	ld	a1,-520(s0)
    800049c6:	855a                	mv	a0,s6
    800049c8:	ff7fc0ef          	jal	ra,800019be <proc_freepagetable>
  if(ip){
    800049cc:	de0a98e3          	bnez	s5,800047bc <kexec+0x74>
  return -1;
    800049d0:	557d                	li	a0,-1
    800049d2:	bbdd                	j	800047c8 <kexec+0x80>
    800049d4:	df243c23          	sd	s2,-520(s0)
    800049d8:	b7ed                	j	800049c2 <kexec+0x27a>
    800049da:	df243c23          	sd	s2,-520(s0)
    800049de:	b7d5                	j	800049c2 <kexec+0x27a>
    800049e0:	df243c23          	sd	s2,-520(s0)
    800049e4:	bff9                	j	800049c2 <kexec+0x27a>
    800049e6:	df243c23          	sd	s2,-520(s0)
    800049ea:	bfe1                	j	800049c2 <kexec+0x27a>
  sz = sz1;
    800049ec:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800049f0:	4a81                	li	s5,0
    800049f2:	bfc1                	j	800049c2 <kexec+0x27a>
  sz = sz1;
    800049f4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800049f8:	4a81                	li	s5,0
    800049fa:	b7e1                	j	800049c2 <kexec+0x27a>
  sz = sz1;
    800049fc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004a00:	4a81                	li	s5,0
    80004a02:	b7c1                	j	800049c2 <kexec+0x27a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004a04:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004a08:	e0843783          	ld	a5,-504(s0)
    80004a0c:	0017869b          	addiw	a3,a5,1
    80004a10:	e0d43423          	sd	a3,-504(s0)
    80004a14:	e0043783          	ld	a5,-512(s0)
    80004a18:	0387879b          	addiw	a5,a5,56
    80004a1c:	e8845703          	lhu	a4,-376(s0)
    80004a20:	e4e6d6e3          	bge	a3,a4,8000486c <kexec+0x124>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004a24:	2781                	sext.w	a5,a5
    80004a26:	e0f43023          	sd	a5,-512(s0)
    80004a2a:	03800713          	li	a4,56
    80004a2e:	86be                	mv	a3,a5
    80004a30:	e1840613          	addi	a2,s0,-488
    80004a34:	4581                	li	a1,0
    80004a36:	8556                	mv	a0,s5
    80004a38:	d05fe0ef          	jal	ra,8000373c <readi>
    80004a3c:	03800793          	li	a5,56
    80004a40:	f6f51fe3          	bne	a0,a5,800049be <kexec+0x276>
    if(ph.type != ELF_PROG_LOAD)
    80004a44:	e1842783          	lw	a5,-488(s0)
    80004a48:	4705                	li	a4,1
    80004a4a:	fae79fe3          	bne	a5,a4,80004a08 <kexec+0x2c0>
    if(ph.memsz < ph.filesz)
    80004a4e:	e4043483          	ld	s1,-448(s0)
    80004a52:	e3843783          	ld	a5,-456(s0)
    80004a56:	f6f4efe3          	bltu	s1,a5,800049d4 <kexec+0x28c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004a5a:	e2843783          	ld	a5,-472(s0)
    80004a5e:	94be                	add	s1,s1,a5
    80004a60:	f6f4ede3          	bltu	s1,a5,800049da <kexec+0x292>
    if(ph.vaddr % PGSIZE != 0)
    80004a64:	de043703          	ld	a4,-544(s0)
    80004a68:	8ff9                	and	a5,a5,a4
    80004a6a:	fbbd                	bnez	a5,800049e0 <kexec+0x298>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004a6c:	e1c42503          	lw	a0,-484(s0)
    80004a70:	cbdff0ef          	jal	ra,8000472c <flags2perm>
    80004a74:	86aa                	mv	a3,a0
    80004a76:	8626                	mv	a2,s1
    80004a78:	85ca                	mv	a1,s2
    80004a7a:	855a                	mv	a0,s6
    80004a7c:	fa4fc0ef          	jal	ra,80001220 <uvmalloc>
    80004a80:	dea43c23          	sd	a0,-520(s0)
    80004a84:	d12d                	beqz	a0,800049e6 <kexec+0x29e>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004a86:	e2843c03          	ld	s8,-472(s0)
    80004a8a:	e2042c83          	lw	s9,-480(s0)
    80004a8e:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004a92:	f60b89e3          	beqz	s7,80004a04 <kexec+0x2bc>
    80004a96:	89de                	mv	s3,s7
    80004a98:	4481                	li	s1,0
    80004a9a:	bb55                	j	8000484e <kexec+0x106>

0000000080004a9c <argfd>:
#include "fcntl.h"

// 获取第n个系统调用参数作为文件描述符，并返回该描述符及对应的文件结构。
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004a9c:	7179                	addi	sp,sp,-48
    80004a9e:	f406                	sd	ra,40(sp)
    80004aa0:	f022                	sd	s0,32(sp)
    80004aa2:	ec26                	sd	s1,24(sp)
    80004aa4:	e84a                	sd	s2,16(sp)
    80004aa6:	1800                	addi	s0,sp,48
    80004aa8:	892e                	mv	s2,a1
    80004aaa:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);  // 获取系统调用参数中的文件描述符
    80004aac:	fdc40593          	addi	a1,s0,-36
    80004ab0:	f19fd0ef          	jal	ra,800029c8 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)  // 检查文件描述符的有效性
    80004ab4:	fdc42703          	lw	a4,-36(s0)
    80004ab8:	47bd                	li	a5,15
    80004aba:	02e7e963          	bltu	a5,a4,80004aec <argfd+0x50>
    80004abe:	d77fc0ef          	jal	ra,80001834 <myproc>
    80004ac2:	fdc42703          	lw	a4,-36(s0)
    80004ac6:	01a70793          	addi	a5,a4,26
    80004aca:	078e                	slli	a5,a5,0x3
    80004acc:	953e                	add	a0,a0,a5
    80004ace:	611c                	ld	a5,0(a0)
    80004ad0:	c385                	beqz	a5,80004af0 <argfd+0x54>
    return -1;
  if(pfd)
    80004ad2:	00090463          	beqz	s2,80004ada <argfd+0x3e>
    *pfd = fd;
    80004ad6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ada:	4501                	li	a0,0
  if(pf)
    80004adc:	c091                	beqz	s1,80004ae0 <argfd+0x44>
    *pf = f;
    80004ade:	e09c                	sd	a5,0(s1)
}
    80004ae0:	70a2                	ld	ra,40(sp)
    80004ae2:	7402                	ld	s0,32(sp)
    80004ae4:	64e2                	ld	s1,24(sp)
    80004ae6:	6942                	ld	s2,16(sp)
    80004ae8:	6145                	addi	sp,sp,48
    80004aea:	8082                	ret
    return -1;
    80004aec:	557d                	li	a0,-1
    80004aee:	bfcd                	j	80004ae0 <argfd+0x44>
    80004af0:	557d                	li	a0,-1
    80004af2:	b7fd                	j	80004ae0 <argfd+0x44>

0000000080004af4 <fdalloc>:

// 为给定文件分配一个文件描述符。
// 成功时接管调用者的文件引用。
static int
fdalloc(struct file *f)
{
    80004af4:	1101                	addi	sp,sp,-32
    80004af6:	ec06                	sd	ra,24(sp)
    80004af8:	e822                	sd	s0,16(sp)
    80004afa:	e426                	sd	s1,8(sp)
    80004afc:	1000                	addi	s0,sp,32
    80004afe:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004b00:	d35fc0ef          	jal	ra,80001834 <myproc>
    80004b04:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004b06:	0d050793          	addi	a5,a0,208
    80004b0a:	4501                	li	a0,0
    80004b0c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){  // 查找一个未使用的文件描述符
    80004b0e:	6398                	ld	a4,0(a5)
    80004b10:	cb19                	beqz	a4,80004b26 <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004b12:	2505                	addiw	a0,a0,1
    80004b14:	07a1                	addi	a5,a5,8
    80004b16:	fed51ce3          	bne	a0,a3,80004b0e <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;  // 没有可用的文件描述符
    80004b1a:	557d                	li	a0,-1
}
    80004b1c:	60e2                	ld	ra,24(sp)
    80004b1e:	6442                	ld	s0,16(sp)
    80004b20:	64a2                	ld	s1,8(sp)
    80004b22:	6105                	addi	sp,sp,32
    80004b24:	8082                	ret
      p->ofile[fd] = f;
    80004b26:	01a50793          	addi	a5,a0,26
    80004b2a:	078e                	slli	a5,a5,0x3
    80004b2c:	963e                	add	a2,a2,a5
    80004b2e:	e204                	sd	s1,0(a2)
      return fd;
    80004b30:	b7f5                	j	80004b1c <fdalloc+0x28>

0000000080004b32 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004b32:	715d                	addi	sp,sp,-80
    80004b34:	e486                	sd	ra,72(sp)
    80004b36:	e0a2                	sd	s0,64(sp)
    80004b38:	fc26                	sd	s1,56(sp)
    80004b3a:	f84a                	sd	s2,48(sp)
    80004b3c:	f44e                	sd	s3,40(sp)
    80004b3e:	f052                	sd	s4,32(sp)
    80004b40:	ec56                	sd	s5,24(sp)
    80004b42:	e85a                	sd	s6,16(sp)
    80004b44:	0880                	addi	s0,sp,80
    80004b46:	8b2e                	mv	s6,a1
    80004b48:	89b2                	mv	s3,a2
    80004b4a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)  // 查找父目录
    80004b4c:	fb040593          	addi	a1,s0,-80
    80004b50:	868ff0ef          	jal	ra,80003bb8 <nameiparent>
    80004b54:	84aa                	mv	s1,a0
    80004b56:	10050b63          	beqz	a0,80004c6c <create+0x13a>
    return 0;

  ilock(dp);
    80004b5a:	857fe0ef          	jal	ra,800033b0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){  // 检查文件是否已存在
    80004b5e:	4601                	li	a2,0
    80004b60:	fb040593          	addi	a1,s0,-80
    80004b64:	8526                	mv	a0,s1
    80004b66:	dd3fe0ef          	jal	ra,80003938 <dirlookup>
    80004b6a:	8aaa                	mv	s5,a0
    80004b6c:	c521                	beqz	a0,80004bb4 <create+0x82>
    iunlockput(dp);
    80004b6e:	8526                	mv	a0,s1
    80004b70:	a47fe0ef          	jal	ra,800035b6 <iunlockput>
    ilock(ip);
    80004b74:	8556                	mv	a0,s5
    80004b76:	83bfe0ef          	jal	ra,800033b0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004b7a:	000b059b          	sext.w	a1,s6
    80004b7e:	4789                	li	a5,2
    80004b80:	02f59563          	bne	a1,a5,80004baa <create+0x78>
    80004b84:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdde0c>
    80004b88:	37f9                	addiw	a5,a5,-2
    80004b8a:	17c2                	slli	a5,a5,0x30
    80004b8c:	93c1                	srli	a5,a5,0x30
    80004b8e:	4705                	li	a4,1
    80004b90:	00f76d63          	bltu	a4,a5,80004baa <create+0x78>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004b94:	8556                	mv	a0,s5
    80004b96:	60a6                	ld	ra,72(sp)
    80004b98:	6406                	ld	s0,64(sp)
    80004b9a:	74e2                	ld	s1,56(sp)
    80004b9c:	7942                	ld	s2,48(sp)
    80004b9e:	79a2                	ld	s3,40(sp)
    80004ba0:	7a02                	ld	s4,32(sp)
    80004ba2:	6ae2                	ld	s5,24(sp)
    80004ba4:	6b42                	ld	s6,16(sp)
    80004ba6:	6161                	addi	sp,sp,80
    80004ba8:	8082                	ret
    iunlockput(ip);
    80004baa:	8556                	mv	a0,s5
    80004bac:	a0bfe0ef          	jal	ra,800035b6 <iunlockput>
    return 0;
    80004bb0:	4a81                	li	s5,0
    80004bb2:	b7cd                	j	80004b94 <create+0x62>
  if((ip = ialloc(dp->dev, type)) == 0){  // 分配 inode
    80004bb4:	85da                	mv	a1,s6
    80004bb6:	4088                	lw	a0,0(s1)
    80004bb8:	e90fe0ef          	jal	ra,80003248 <ialloc>
    80004bbc:	8a2a                	mv	s4,a0
    80004bbe:	cd1d                	beqz	a0,80004bfc <create+0xca>
  ilock(ip);
    80004bc0:	ff0fe0ef          	jal	ra,800033b0 <ilock>
  ip->major = major;
    80004bc4:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004bc8:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004bcc:	4905                	li	s2,1
    80004bce:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004bd2:	8552                	mv	a0,s4
    80004bd4:	f2afe0ef          	jal	ra,800032fe <iupdate>
  if(type == T_DIR){  // 创建 . 和 .. 目录项
    80004bd8:	000b059b          	sext.w	a1,s6
    80004bdc:	03258563          	beq	a1,s2,80004c06 <create+0xd4>
  if(dirlink(dp, name, ip->inum) < 0)
    80004be0:	004a2603          	lw	a2,4(s4)
    80004be4:	fb040593          	addi	a1,s0,-80
    80004be8:	8526                	mv	a0,s1
    80004bea:	f1bfe0ef          	jal	ra,80003b04 <dirlink>
    80004bee:	06054363          	bltz	a0,80004c54 <create+0x122>
  iunlockput(dp);
    80004bf2:	8526                	mv	a0,s1
    80004bf4:	9c3fe0ef          	jal	ra,800035b6 <iunlockput>
  return ip;
    80004bf8:	8ad2                	mv	s5,s4
    80004bfa:	bf69                	j	80004b94 <create+0x62>
    iunlockput(dp);
    80004bfc:	8526                	mv	a0,s1
    80004bfe:	9b9fe0ef          	jal	ra,800035b6 <iunlockput>
    return 0;
    80004c02:	8ad2                	mv	s5,s4
    80004c04:	bf41                	j	80004b94 <create+0x62>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004c06:	004a2603          	lw	a2,4(s4)
    80004c0a:	00003597          	auipc	a1,0x3
    80004c0e:	ade58593          	addi	a1,a1,-1314 # 800076e8 <syscalls+0x2e8>
    80004c12:	8552                	mv	a0,s4
    80004c14:	ef1fe0ef          	jal	ra,80003b04 <dirlink>
    80004c18:	02054e63          	bltz	a0,80004c54 <create+0x122>
    80004c1c:	40d0                	lw	a2,4(s1)
    80004c1e:	00003597          	auipc	a1,0x3
    80004c22:	ad258593          	addi	a1,a1,-1326 # 800076f0 <syscalls+0x2f0>
    80004c26:	8552                	mv	a0,s4
    80004c28:	eddfe0ef          	jal	ra,80003b04 <dirlink>
    80004c2c:	02054463          	bltz	a0,80004c54 <create+0x122>
  if(dirlink(dp, name, ip->inum) < 0)
    80004c30:	004a2603          	lw	a2,4(s4)
    80004c34:	fb040593          	addi	a1,s0,-80
    80004c38:	8526                	mv	a0,s1
    80004c3a:	ecbfe0ef          	jal	ra,80003b04 <dirlink>
    80004c3e:	00054b63          	bltz	a0,80004c54 <create+0x122>
    dp->nlink++;  // 更新父目录的链接计数
    80004c42:	04a4d783          	lhu	a5,74(s1)
    80004c46:	2785                	addiw	a5,a5,1
    80004c48:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004c4c:	8526                	mv	a0,s1
    80004c4e:	eb0fe0ef          	jal	ra,800032fe <iupdate>
    80004c52:	b745                	j	80004bf2 <create+0xc0>
  ip->nlink = 0;
    80004c54:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004c58:	8552                	mv	a0,s4
    80004c5a:	ea4fe0ef          	jal	ra,800032fe <iupdate>
  iunlockput(ip);
    80004c5e:	8552                	mv	a0,s4
    80004c60:	957fe0ef          	jal	ra,800035b6 <iunlockput>
  iunlockput(dp);
    80004c64:	8526                	mv	a0,s1
    80004c66:	951fe0ef          	jal	ra,800035b6 <iunlockput>
  return 0;
    80004c6a:	b72d                	j	80004b94 <create+0x62>
    return 0;
    80004c6c:	8aaa                	mv	s5,a0
    80004c6e:	b71d                	j	80004b94 <create+0x62>

0000000080004c70 <sys_dup>:
{
    80004c70:	7179                	addi	sp,sp,-48
    80004c72:	f406                	sd	ra,40(sp)
    80004c74:	f022                	sd	s0,32(sp)
    80004c76:	ec26                	sd	s1,24(sp)
    80004c78:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004c7a:	fd840613          	addi	a2,s0,-40
    80004c7e:	4581                	li	a1,0
    80004c80:	4501                	li	a0,0
    80004c82:	e1bff0ef          	jal	ra,80004a9c <argfd>
    return -1;
    80004c86:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004c88:	00054f63          	bltz	a0,80004ca6 <sys_dup+0x36>
  if((fd=fdalloc(f)) < 0)  // 为文件分配新的文件描述符
    80004c8c:	fd843503          	ld	a0,-40(s0)
    80004c90:	e65ff0ef          	jal	ra,80004af4 <fdalloc>
    80004c94:	84aa                	mv	s1,a0
    return -1;
    80004c96:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)  // 为文件分配新的文件描述符
    80004c98:	00054763          	bltz	a0,80004ca6 <sys_dup+0x36>
  filedup(f);  // 增加文件引用计数
    80004c9c:	fd843503          	ld	a0,-40(s0)
    80004ca0:	cb6ff0ef          	jal	ra,80004156 <filedup>
  return fd;
    80004ca4:	87a6                	mv	a5,s1
}
    80004ca6:	853e                	mv	a0,a5
    80004ca8:	70a2                	ld	ra,40(sp)
    80004caa:	7402                	ld	s0,32(sp)
    80004cac:	64e2                	ld	s1,24(sp)
    80004cae:	6145                	addi	sp,sp,48
    80004cb0:	8082                	ret

0000000080004cb2 <sys_read>:
{
    80004cb2:	7179                	addi	sp,sp,-48
    80004cb4:	f406                	sd	ra,40(sp)
    80004cb6:	f022                	sd	s0,32(sp)
    80004cb8:	1800                	addi	s0,sp,48
  argaddr(1, &p);  // 获取读取数据的用户空间地址
    80004cba:	fd840593          	addi	a1,s0,-40
    80004cbe:	4505                	li	a0,1
    80004cc0:	d25fd0ef          	jal	ra,800029e4 <argaddr>
  argint(2, &n);  // 获取读取字节数
    80004cc4:	fe440593          	addi	a1,s0,-28
    80004cc8:	4509                	li	a0,2
    80004cca:	cfffd0ef          	jal	ra,800029c8 <argint>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004cce:	fe840613          	addi	a2,s0,-24
    80004cd2:	4581                	li	a1,0
    80004cd4:	4501                	li	a0,0
    80004cd6:	dc7ff0ef          	jal	ra,80004a9c <argfd>
    80004cda:	87aa                	mv	a5,a0
    return -1;
    80004cdc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004cde:	0007ca63          	bltz	a5,80004cf2 <sys_read+0x40>
  return fileread(f, p, n);  // 从文件中读取数据
    80004ce2:	fe442603          	lw	a2,-28(s0)
    80004ce6:	fd843583          	ld	a1,-40(s0)
    80004cea:	fe843503          	ld	a0,-24(s0)
    80004cee:	db4ff0ef          	jal	ra,800042a2 <fileread>
}
    80004cf2:	70a2                	ld	ra,40(sp)
    80004cf4:	7402                	ld	s0,32(sp)
    80004cf6:	6145                	addi	sp,sp,48
    80004cf8:	8082                	ret

0000000080004cfa <sys_write>:
{
    80004cfa:	7179                	addi	sp,sp,-48
    80004cfc:	f406                	sd	ra,40(sp)
    80004cfe:	f022                	sd	s0,32(sp)
    80004d00:	1800                	addi	s0,sp,48
  argaddr(1, &p);  // 获取写入数据的用户空间地址
    80004d02:	fd840593          	addi	a1,s0,-40
    80004d06:	4505                	li	a0,1
    80004d08:	cddfd0ef          	jal	ra,800029e4 <argaddr>
  argint(2, &n);  // 获取写入字节数
    80004d0c:	fe440593          	addi	a1,s0,-28
    80004d10:	4509                	li	a0,2
    80004d12:	cb7fd0ef          	jal	ra,800029c8 <argint>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004d16:	fe840613          	addi	a2,s0,-24
    80004d1a:	4581                	li	a1,0
    80004d1c:	4501                	li	a0,0
    80004d1e:	d7fff0ef          	jal	ra,80004a9c <argfd>
    80004d22:	87aa                	mv	a5,a0
    return -1;
    80004d24:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004d26:	0007ca63          	bltz	a5,80004d3a <sys_write+0x40>
  return filewrite(f, p, n);  // 向文件中写入数据
    80004d2a:	fe442603          	lw	a2,-28(s0)
    80004d2e:	fd843583          	ld	a1,-40(s0)
    80004d32:	fe843503          	ld	a0,-24(s0)
    80004d36:	e1aff0ef          	jal	ra,80004350 <filewrite>
}
    80004d3a:	70a2                	ld	ra,40(sp)
    80004d3c:	7402                	ld	s0,32(sp)
    80004d3e:	6145                	addi	sp,sp,48
    80004d40:	8082                	ret

0000000080004d42 <sys_close>:
{
    80004d42:	1101                	addi	sp,sp,-32
    80004d44:	ec06                	sd	ra,24(sp)
    80004d46:	e822                	sd	s0,16(sp)
    80004d48:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)  // 获取文件描述符并返回文件结构
    80004d4a:	fe040613          	addi	a2,s0,-32
    80004d4e:	fec40593          	addi	a1,s0,-20
    80004d52:	4501                	li	a0,0
    80004d54:	d49ff0ef          	jal	ra,80004a9c <argfd>
    return -1;
    80004d58:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)  // 获取文件描述符并返回文件结构
    80004d5a:	02054063          	bltz	a0,80004d7a <sys_close+0x38>
  myproc()->ofile[fd] = 0;  // 关闭文件描述符
    80004d5e:	ad7fc0ef          	jal	ra,80001834 <myproc>
    80004d62:	fec42783          	lw	a5,-20(s0)
    80004d66:	07e9                	addi	a5,a5,26
    80004d68:	078e                	slli	a5,a5,0x3
    80004d6a:	97aa                	add	a5,a5,a0
    80004d6c:	0007b023          	sd	zero,0(a5)
  fileclose(f);  // 关闭文件
    80004d70:	fe043503          	ld	a0,-32(s0)
    80004d74:	c28ff0ef          	jal	ra,8000419c <fileclose>
  return 0;
    80004d78:	4781                	li	a5,0
}
    80004d7a:	853e                	mv	a0,a5
    80004d7c:	60e2                	ld	ra,24(sp)
    80004d7e:	6442                	ld	s0,16(sp)
    80004d80:	6105                	addi	sp,sp,32
    80004d82:	8082                	ret

0000000080004d84 <sys_fstat>:
{
    80004d84:	1101                	addi	sp,sp,-32
    80004d86:	ec06                	sd	ra,24(sp)
    80004d88:	e822                	sd	s0,16(sp)
    80004d8a:	1000                	addi	s0,sp,32
  argaddr(1, &st);  // 获取 stat 结构体地址
    80004d8c:	fe040593          	addi	a1,s0,-32
    80004d90:	4505                	li	a0,1
    80004d92:	c53fd0ef          	jal	ra,800029e4 <argaddr>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004d96:	fe840613          	addi	a2,s0,-24
    80004d9a:	4581                	li	a1,0
    80004d9c:	4501                	li	a0,0
    80004d9e:	cffff0ef          	jal	ra,80004a9c <argfd>
    80004da2:	87aa                	mv	a5,a0
    return -1;
    80004da4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004da6:	0007c863          	bltz	a5,80004db6 <sys_fstat+0x32>
  return filestat(f, st);  // 获取文件状态信息
    80004daa:	fe043583          	ld	a1,-32(s0)
    80004dae:	fe843503          	ld	a0,-24(s0)
    80004db2:	c92ff0ef          	jal	ra,80004244 <filestat>
}
    80004db6:	60e2                	ld	ra,24(sp)
    80004db8:	6442                	ld	s0,16(sp)
    80004dba:	6105                	addi	sp,sp,32
    80004dbc:	8082                	ret

0000000080004dbe <sys_link>:
{
    80004dbe:	7169                	addi	sp,sp,-304
    80004dc0:	f606                	sd	ra,296(sp)
    80004dc2:	f222                	sd	s0,288(sp)
    80004dc4:	ee26                	sd	s1,280(sp)
    80004dc6:	ea4a                	sd	s2,272(sp)
    80004dc8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004dca:	08000613          	li	a2,128
    80004dce:	ed040593          	addi	a1,s0,-304
    80004dd2:	4501                	li	a0,0
    80004dd4:	c2dfd0ef          	jal	ra,80002a00 <argstr>
    return -1;
    80004dd8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004dda:	0c054663          	bltz	a0,80004ea6 <sys_link+0xe8>
    80004dde:	08000613          	li	a2,128
    80004de2:	f5040593          	addi	a1,s0,-176
    80004de6:	4505                	li	a0,1
    80004de8:	c19fd0ef          	jal	ra,80002a00 <argstr>
    return -1;
    80004dec:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004dee:	0a054c63          	bltz	a0,80004ea6 <sys_link+0xe8>
  begin_op();
    80004df2:	f9dfe0ef          	jal	ra,80003d8e <begin_op>
  if((ip = namei(old)) == 0){  // 查找 old 路径对应的 inode
    80004df6:	ed040513          	addi	a0,s0,-304
    80004dfa:	da5fe0ef          	jal	ra,80003b9e <namei>
    80004dfe:	84aa                	mv	s1,a0
    80004e00:	c525                	beqz	a0,80004e68 <sys_link+0xaa>
  ilock(ip);
    80004e02:	daefe0ef          	jal	ra,800033b0 <ilock>
  if(ip->type == T_DIR){  // 如果是目录，不能创建链接
    80004e06:	04449703          	lh	a4,68(s1)
    80004e0a:	4785                	li	a5,1
    80004e0c:	06f70263          	beq	a4,a5,80004e70 <sys_link+0xb2>
  ip->nlink++;  // 增加链接计数
    80004e10:	04a4d783          	lhu	a5,74(s1)
    80004e14:	2785                	addiw	a5,a5,1
    80004e16:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004e1a:	8526                	mv	a0,s1
    80004e1c:	ce2fe0ef          	jal	ra,800032fe <iupdate>
  iunlock(ip);
    80004e20:	8526                	mv	a0,s1
    80004e22:	e38fe0ef          	jal	ra,8000345a <iunlock>
  if((dp = nameiparent(new, name)) == 0)  // 获取 new 路径的父目录
    80004e26:	fd040593          	addi	a1,s0,-48
    80004e2a:	f5040513          	addi	a0,s0,-176
    80004e2e:	d8bfe0ef          	jal	ra,80003bb8 <nameiparent>
    80004e32:	892a                	mv	s2,a0
    80004e34:	c921                	beqz	a0,80004e84 <sys_link+0xc6>
  ilock(dp);
    80004e36:	d7afe0ef          	jal	ra,800033b0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){  // 在父目录中创建新链接
    80004e3a:	00092703          	lw	a4,0(s2)
    80004e3e:	409c                	lw	a5,0(s1)
    80004e40:	02f71f63          	bne	a4,a5,80004e7e <sys_link+0xc0>
    80004e44:	40d0                	lw	a2,4(s1)
    80004e46:	fd040593          	addi	a1,s0,-48
    80004e4a:	854a                	mv	a0,s2
    80004e4c:	cb9fe0ef          	jal	ra,80003b04 <dirlink>
    80004e50:	02054763          	bltz	a0,80004e7e <sys_link+0xc0>
  iunlockput(dp);
    80004e54:	854a                	mv	a0,s2
    80004e56:	f60fe0ef          	jal	ra,800035b6 <iunlockput>
  iput(ip);
    80004e5a:	8526                	mv	a0,s1
    80004e5c:	ed2fe0ef          	jal	ra,8000352e <iput>
  end_op();
    80004e60:	f9ffe0ef          	jal	ra,80003dfe <end_op>
  return 0;
    80004e64:	4781                	li	a5,0
    80004e66:	a081                	j	80004ea6 <sys_link+0xe8>
    end_op();
    80004e68:	f97fe0ef          	jal	ra,80003dfe <end_op>
    return -1;
    80004e6c:	57fd                	li	a5,-1
    80004e6e:	a825                	j	80004ea6 <sys_link+0xe8>
    iunlockput(ip);
    80004e70:	8526                	mv	a0,s1
    80004e72:	f44fe0ef          	jal	ra,800035b6 <iunlockput>
    end_op();
    80004e76:	f89fe0ef          	jal	ra,80003dfe <end_op>
    return -1;
    80004e7a:	57fd                	li	a5,-1
    80004e7c:	a02d                	j	80004ea6 <sys_link+0xe8>
    iunlockput(dp);
    80004e7e:	854a                	mv	a0,s2
    80004e80:	f36fe0ef          	jal	ra,800035b6 <iunlockput>
  ilock(ip);
    80004e84:	8526                	mv	a0,s1
    80004e86:	d2afe0ef          	jal	ra,800033b0 <ilock>
  ip->nlink--;  // 发生错误，恢复链接计数
    80004e8a:	04a4d783          	lhu	a5,74(s1)
    80004e8e:	37fd                	addiw	a5,a5,-1
    80004e90:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004e94:	8526                	mv	a0,s1
    80004e96:	c68fe0ef          	jal	ra,800032fe <iupdate>
  iunlockput(ip);
    80004e9a:	8526                	mv	a0,s1
    80004e9c:	f1afe0ef          	jal	ra,800035b6 <iunlockput>
  end_op();
    80004ea0:	f5ffe0ef          	jal	ra,80003dfe <end_op>
  return -1;
    80004ea4:	57fd                	li	a5,-1
}
    80004ea6:	853e                	mv	a0,a5
    80004ea8:	70b2                	ld	ra,296(sp)
    80004eaa:	7412                	ld	s0,288(sp)
    80004eac:	64f2                	ld	s1,280(sp)
    80004eae:	6952                	ld	s2,272(sp)
    80004eb0:	6155                	addi	sp,sp,304
    80004eb2:	8082                	ret

0000000080004eb4 <sys_unlink>:
{
    80004eb4:	7151                	addi	sp,sp,-240
    80004eb6:	f586                	sd	ra,232(sp)
    80004eb8:	f1a2                	sd	s0,224(sp)
    80004eba:	eda6                	sd	s1,216(sp)
    80004ebc:	e9ca                	sd	s2,208(sp)
    80004ebe:	e5ce                	sd	s3,200(sp)
    80004ec0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)  // 获取路径
    80004ec2:	08000613          	li	a2,128
    80004ec6:	f3040593          	addi	a1,s0,-208
    80004eca:	4501                	li	a0,0
    80004ecc:	b35fd0ef          	jal	ra,80002a00 <argstr>
    80004ed0:	12054b63          	bltz	a0,80005006 <sys_unlink+0x152>
  begin_op();
    80004ed4:	ebbfe0ef          	jal	ra,80003d8e <begin_op>
  if((dp = nameiparent(path, name)) == 0){  // 查找路径的父目录
    80004ed8:	fb040593          	addi	a1,s0,-80
    80004edc:	f3040513          	addi	a0,s0,-208
    80004ee0:	cd9fe0ef          	jal	ra,80003bb8 <nameiparent>
    80004ee4:	84aa                	mv	s1,a0
    80004ee6:	c54d                	beqz	a0,80004f90 <sys_unlink+0xdc>
  ilock(dp);
    80004ee8:	cc8fe0ef          	jal	ra,800033b0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004eec:	00002597          	auipc	a1,0x2
    80004ef0:	7fc58593          	addi	a1,a1,2044 # 800076e8 <syscalls+0x2e8>
    80004ef4:	fb040513          	addi	a0,s0,-80
    80004ef8:	a2bfe0ef          	jal	ra,80003922 <namecmp>
    80004efc:	10050a63          	beqz	a0,80005010 <sys_unlink+0x15c>
    80004f00:	00002597          	auipc	a1,0x2
    80004f04:	7f058593          	addi	a1,a1,2032 # 800076f0 <syscalls+0x2f0>
    80004f08:	fb040513          	addi	a0,s0,-80
    80004f0c:	a17fe0ef          	jal	ra,80003922 <namecmp>
    80004f10:	10050063          	beqz	a0,80005010 <sys_unlink+0x15c>
  if((ip = dirlookup(dp, name, &off)) == 0)  // 查找目录项
    80004f14:	f2c40613          	addi	a2,s0,-212
    80004f18:	fb040593          	addi	a1,s0,-80
    80004f1c:	8526                	mv	a0,s1
    80004f1e:	a1bfe0ef          	jal	ra,80003938 <dirlookup>
    80004f22:	892a                	mv	s2,a0
    80004f24:	0e050663          	beqz	a0,80005010 <sys_unlink+0x15c>
  ilock(ip);
    80004f28:	c88fe0ef          	jal	ra,800033b0 <ilock>
  if(ip->nlink < 1)
    80004f2c:	04a91783          	lh	a5,74(s2)
    80004f30:	06f05463          	blez	a5,80004f98 <sys_unlink+0xe4>
  if(ip->type == T_DIR && !isdirempty(ip)){  // 如果是非空目录，不能删除
    80004f34:	04491703          	lh	a4,68(s2)
    80004f38:	4785                	li	a5,1
    80004f3a:	06f70563          	beq	a4,a5,80004fa4 <sys_unlink+0xf0>
  memset(&de, 0, sizeof(de));  // 清空目录项
    80004f3e:	4641                	li	a2,16
    80004f40:	4581                	li	a1,0
    80004f42:	fc040513          	addi	a0,s0,-64
    80004f46:	cfbfb0ef          	jal	ra,80000c40 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))  // 删除目录项
    80004f4a:	4741                	li	a4,16
    80004f4c:	f2c42683          	lw	a3,-212(s0)
    80004f50:	fc040613          	addi	a2,s0,-64
    80004f54:	4581                	li	a1,0
    80004f56:	8526                	mv	a0,s1
    80004f58:	8c9fe0ef          	jal	ra,80003820 <writei>
    80004f5c:	47c1                	li	a5,16
    80004f5e:	08f51563          	bne	a0,a5,80004fe8 <sys_unlink+0x134>
  if(ip->type == T_DIR){
    80004f62:	04491703          	lh	a4,68(s2)
    80004f66:	4785                	li	a5,1
    80004f68:	08f70663          	beq	a4,a5,80004ff4 <sys_unlink+0x140>
  iunlockput(dp);
    80004f6c:	8526                	mv	a0,s1
    80004f6e:	e48fe0ef          	jal	ra,800035b6 <iunlockput>
  ip->nlink--;  // 更新目标文件的链接计数
    80004f72:	04a95783          	lhu	a5,74(s2)
    80004f76:	37fd                	addiw	a5,a5,-1
    80004f78:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80004f7c:	854a                	mv	a0,s2
    80004f7e:	b80fe0ef          	jal	ra,800032fe <iupdate>
  iunlockput(ip);
    80004f82:	854a                	mv	a0,s2
    80004f84:	e32fe0ef          	jal	ra,800035b6 <iunlockput>
  end_op();
    80004f88:	e77fe0ef          	jal	ra,80003dfe <end_op>
  return 0;
    80004f8c:	4501                	li	a0,0
    80004f8e:	a079                	j	8000501c <sys_unlink+0x168>
    end_op();
    80004f90:	e6ffe0ef          	jal	ra,80003dfe <end_op>
    return -1;
    80004f94:	557d                	li	a0,-1
    80004f96:	a059                	j	8000501c <sys_unlink+0x168>
    panic("unlink: nlink < 1");  // 检查链接计数
    80004f98:	00002517          	auipc	a0,0x2
    80004f9c:	76050513          	addi	a0,a0,1888 # 800076f8 <syscalls+0x2f8>
    80004fa0:	feafb0ef          	jal	ra,8000078a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){  // 跳过 "." 和 ".."
    80004fa4:	04c92703          	lw	a4,76(s2)
    80004fa8:	02000793          	li	a5,32
    80004fac:	f8e7f9e3          	bgeu	a5,a4,80004f3e <sys_unlink+0x8a>
    80004fb0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004fb4:	4741                	li	a4,16
    80004fb6:	86ce                	mv	a3,s3
    80004fb8:	f1840613          	addi	a2,s0,-232
    80004fbc:	4581                	li	a1,0
    80004fbe:	854a                	mv	a0,s2
    80004fc0:	f7cfe0ef          	jal	ra,8000373c <readi>
    80004fc4:	47c1                	li	a5,16
    80004fc6:	00f51b63          	bne	a0,a5,80004fdc <sys_unlink+0x128>
    if(de.inum != 0)  // 如果目录项不为空
    80004fca:	f1845783          	lhu	a5,-232(s0)
    80004fce:	ef95                	bnez	a5,8000500a <sys_unlink+0x156>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){  // 跳过 "." 和 ".."
    80004fd0:	29c1                	addiw	s3,s3,16
    80004fd2:	04c92783          	lw	a5,76(s2)
    80004fd6:	fcf9efe3          	bltu	s3,a5,80004fb4 <sys_unlink+0x100>
    80004fda:	b795                	j	80004f3e <sys_unlink+0x8a>
      panic("isdirempty: readi");
    80004fdc:	00002517          	auipc	a0,0x2
    80004fe0:	73450513          	addi	a0,a0,1844 # 80007710 <syscalls+0x310>
    80004fe4:	fa6fb0ef          	jal	ra,8000078a <panic>
    panic("unlink: writei");
    80004fe8:	00002517          	auipc	a0,0x2
    80004fec:	74050513          	addi	a0,a0,1856 # 80007728 <syscalls+0x328>
    80004ff0:	f9afb0ef          	jal	ra,8000078a <panic>
    dp->nlink--;  // 更新父目录的链接计数
    80004ff4:	04a4d783          	lhu	a5,74(s1)
    80004ff8:	37fd                	addiw	a5,a5,-1
    80004ffa:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004ffe:	8526                	mv	a0,s1
    80005000:	afefe0ef          	jal	ra,800032fe <iupdate>
    80005004:	b7a5                	j	80004f6c <sys_unlink+0xb8>
    return -1;
    80005006:	557d                	li	a0,-1
    80005008:	a811                	j	8000501c <sys_unlink+0x168>
    iunlockput(ip);
    8000500a:	854a                	mv	a0,s2
    8000500c:	daafe0ef          	jal	ra,800035b6 <iunlockput>
  iunlockput(dp);
    80005010:	8526                	mv	a0,s1
    80005012:	da4fe0ef          	jal	ra,800035b6 <iunlockput>
  end_op();
    80005016:	de9fe0ef          	jal	ra,80003dfe <end_op>
  return -1;
    8000501a:	557d                	li	a0,-1
}
    8000501c:	70ae                	ld	ra,232(sp)
    8000501e:	740e                	ld	s0,224(sp)
    80005020:	64ee                	ld	s1,216(sp)
    80005022:	694e                	ld	s2,208(sp)
    80005024:	69ae                	ld	s3,200(sp)
    80005026:	616d                	addi	sp,sp,240
    80005028:	8082                	ret

000000008000502a <sys_open>:

uint64
sys_open(void)
{
    8000502a:	7131                	addi	sp,sp,-192
    8000502c:	fd06                	sd	ra,184(sp)
    8000502e:	f922                	sd	s0,176(sp)
    80005030:	f526                	sd	s1,168(sp)
    80005032:	f14a                	sd	s2,160(sp)
    80005034:	ed4e                	sd	s3,152(sp)
    80005036:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);  // 获取打开文件的模式
    80005038:	f4c40593          	addi	a1,s0,-180
    8000503c:	4505                	li	a0,1
    8000503e:	98bfd0ef          	jal	ra,800029c8 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)  // 获取路径
    80005042:	08000613          	li	a2,128
    80005046:	f5040593          	addi	a1,s0,-176
    8000504a:	4501                	li	a0,0
    8000504c:	9b5fd0ef          	jal	ra,80002a00 <argstr>
    80005050:	87aa                	mv	a5,a0
    return -1;
    80005052:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)  // 获取路径
    80005054:	0807cd63          	bltz	a5,800050ee <sys_open+0xc4>

  begin_op();
    80005058:	d37fe0ef          	jal	ra,80003d8e <begin_op>

  if(omode & O_CREATE){  // 如果是创建文件
    8000505c:	f4c42783          	lw	a5,-180(s0)
    80005060:	2007f793          	andi	a5,a5,512
    80005064:	c3c5                	beqz	a5,80005104 <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    80005066:	4681                	li	a3,0
    80005068:	4601                	li	a2,0
    8000506a:	4589                	li	a1,2
    8000506c:	f5040513          	addi	a0,s0,-176
    80005070:	ac3ff0ef          	jal	ra,80004b32 <create>
    80005074:	84aa                	mv	s1,a0
    if(ip == 0){
    80005076:	c159                	beqz	a0,800050fc <sys_open+0xd2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005078:	04449703          	lh	a4,68(s1)
    8000507c:	478d                	li	a5,3
    8000507e:	00f71763          	bne	a4,a5,8000508c <sys_open+0x62>
    80005082:	0464d703          	lhu	a4,70(s1)
    80005086:	47a5                	li	a5,9
    80005088:	0ae7e963          	bltu	a5,a4,8000513a <sys_open+0x110>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){  // 分配文件描述符
    8000508c:	86cff0ef          	jal	ra,800040f8 <filealloc>
    80005090:	89aa                	mv	s3,a0
    80005092:	0c050963          	beqz	a0,80005164 <sys_open+0x13a>
    80005096:	a5fff0ef          	jal	ra,80004af4 <fdalloc>
    8000509a:	892a                	mv	s2,a0
    8000509c:	0c054163          	bltz	a0,8000515e <sys_open+0x134>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800050a0:	04449703          	lh	a4,68(s1)
    800050a4:	478d                	li	a5,3
    800050a6:	0af70163          	beq	a4,a5,80005148 <sys_open+0x11e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800050aa:	4789                	li	a5,2
    800050ac:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800050b0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800050b4:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800050b8:	f4c42783          	lw	a5,-180(s0)
    800050bc:	0017c713          	xori	a4,a5,1
    800050c0:	8b05                	andi	a4,a4,1
    800050c2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800050c6:	0037f713          	andi	a4,a5,3
    800050ca:	00e03733          	snez	a4,a4
    800050ce:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){  // 如果是 O_TRUNC 模式，截断文件
    800050d2:	4007f793          	andi	a5,a5,1024
    800050d6:	c791                	beqz	a5,800050e2 <sys_open+0xb8>
    800050d8:	04449703          	lh	a4,68(s1)
    800050dc:	4789                	li	a5,2
    800050de:	06f70c63          	beq	a4,a5,80005156 <sys_open+0x12c>
    itrunc(ip);
  }

  iunlock(ip);
    800050e2:	8526                	mv	a0,s1
    800050e4:	b76fe0ef          	jal	ra,8000345a <iunlock>
  end_op();
    800050e8:	d17fe0ef          	jal	ra,80003dfe <end_op>

  return fd;
    800050ec:	854a                	mv	a0,s2
}
    800050ee:	70ea                	ld	ra,184(sp)
    800050f0:	744a                	ld	s0,176(sp)
    800050f2:	74aa                	ld	s1,168(sp)
    800050f4:	790a                	ld	s2,160(sp)
    800050f6:	69ea                	ld	s3,152(sp)
    800050f8:	6129                	addi	sp,sp,192
    800050fa:	8082                	ret
      end_op();
    800050fc:	d03fe0ef          	jal	ra,80003dfe <end_op>
      return -1;
    80005100:	557d                	li	a0,-1
    80005102:	b7f5                	j	800050ee <sys_open+0xc4>
    if((ip = namei(path)) == 0){
    80005104:	f5040513          	addi	a0,s0,-176
    80005108:	a97fe0ef          	jal	ra,80003b9e <namei>
    8000510c:	84aa                	mv	s1,a0
    8000510e:	c115                	beqz	a0,80005132 <sys_open+0x108>
    ilock(ip);
    80005110:	aa0fe0ef          	jal	ra,800033b0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){  // 不能用非读模式打开目录
    80005114:	04449703          	lh	a4,68(s1)
    80005118:	4785                	li	a5,1
    8000511a:	f4f71fe3          	bne	a4,a5,80005078 <sys_open+0x4e>
    8000511e:	f4c42783          	lw	a5,-180(s0)
    80005122:	d7ad                	beqz	a5,8000508c <sys_open+0x62>
      iunlockput(ip);
    80005124:	8526                	mv	a0,s1
    80005126:	c90fe0ef          	jal	ra,800035b6 <iunlockput>
      end_op();
    8000512a:	cd5fe0ef          	jal	ra,80003dfe <end_op>
      return -1;
    8000512e:	557d                	li	a0,-1
    80005130:	bf7d                	j	800050ee <sys_open+0xc4>
      end_op();
    80005132:	ccdfe0ef          	jal	ra,80003dfe <end_op>
      return -1;
    80005136:	557d                	li	a0,-1
    80005138:	bf5d                	j	800050ee <sys_open+0xc4>
    iunlockput(ip);
    8000513a:	8526                	mv	a0,s1
    8000513c:	c7afe0ef          	jal	ra,800035b6 <iunlockput>
    end_op();
    80005140:	cbffe0ef          	jal	ra,80003dfe <end_op>
    return -1;
    80005144:	557d                	li	a0,-1
    80005146:	b765                	j	800050ee <sys_open+0xc4>
    f->type = FD_DEVICE;
    80005148:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000514c:	04649783          	lh	a5,70(s1)
    80005150:	02f99223          	sh	a5,36(s3)
    80005154:	b785                	j	800050b4 <sys_open+0x8a>
    itrunc(ip);
    80005156:	8526                	mv	a0,s1
    80005158:	b42fe0ef          	jal	ra,8000349a <itrunc>
    8000515c:	b759                	j	800050e2 <sys_open+0xb8>
      fileclose(f);
    8000515e:	854e                	mv	a0,s3
    80005160:	83cff0ef          	jal	ra,8000419c <fileclose>
    iunlockput(ip);
    80005164:	8526                	mv	a0,s1
    80005166:	c50fe0ef          	jal	ra,800035b6 <iunlockput>
    end_op();
    8000516a:	c95fe0ef          	jal	ra,80003dfe <end_op>
    return -1;
    8000516e:	557d                	li	a0,-1
    80005170:	bfbd                	j	800050ee <sys_open+0xc4>

0000000080005172 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005172:	7175                	addi	sp,sp,-144
    80005174:	e506                	sd	ra,136(sp)
    80005176:	e122                	sd	s0,128(sp)
    80005178:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000517a:	c15fe0ef          	jal	ra,80003d8e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000517e:	08000613          	li	a2,128
    80005182:	f7040593          	addi	a1,s0,-144
    80005186:	4501                	li	a0,0
    80005188:	879fd0ef          	jal	ra,80002a00 <argstr>
    8000518c:	02054363          	bltz	a0,800051b2 <sys_mkdir+0x40>
    80005190:	4681                	li	a3,0
    80005192:	4601                	li	a2,0
    80005194:	4585                	li	a1,1
    80005196:	f7040513          	addi	a0,s0,-144
    8000519a:	999ff0ef          	jal	ra,80004b32 <create>
    8000519e:	c911                	beqz	a0,800051b2 <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800051a0:	c16fe0ef          	jal	ra,800035b6 <iunlockput>
  end_op();
    800051a4:	c5bfe0ef          	jal	ra,80003dfe <end_op>
  return 0;
    800051a8:	4501                	li	a0,0
}
    800051aa:	60aa                	ld	ra,136(sp)
    800051ac:	640a                	ld	s0,128(sp)
    800051ae:	6149                	addi	sp,sp,144
    800051b0:	8082                	ret
    end_op();
    800051b2:	c4dfe0ef          	jal	ra,80003dfe <end_op>
    return -1;
    800051b6:	557d                	li	a0,-1
    800051b8:	bfcd                	j	800051aa <sys_mkdir+0x38>

00000000800051ba <sys_mknod>:

uint64
sys_mknod(void)
{
    800051ba:	7135                	addi	sp,sp,-160
    800051bc:	ed06                	sd	ra,152(sp)
    800051be:	e922                	sd	s0,144(sp)
    800051c0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800051c2:	bcdfe0ef          	jal	ra,80003d8e <begin_op>
  argint(1, &major);
    800051c6:	f6c40593          	addi	a1,s0,-148
    800051ca:	4505                	li	a0,1
    800051cc:	ffcfd0ef          	jal	ra,800029c8 <argint>
  argint(2, &minor);
    800051d0:	f6840593          	addi	a1,s0,-152
    800051d4:	4509                	li	a0,2
    800051d6:	ff2fd0ef          	jal	ra,800029c8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800051da:	08000613          	li	a2,128
    800051de:	f7040593          	addi	a1,s0,-144
    800051e2:	4501                	li	a0,0
    800051e4:	81dfd0ef          	jal	ra,80002a00 <argstr>
    800051e8:	02054563          	bltz	a0,80005212 <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800051ec:	f6841683          	lh	a3,-152(s0)
    800051f0:	f6c41603          	lh	a2,-148(s0)
    800051f4:	458d                	li	a1,3
    800051f6:	f7040513          	addi	a0,s0,-144
    800051fa:	939ff0ef          	jal	ra,80004b32 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800051fe:	c911                	beqz	a0,80005212 <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005200:	bb6fe0ef          	jal	ra,800035b6 <iunlockput>
  end_op();
    80005204:	bfbfe0ef          	jal	ra,80003dfe <end_op>
  return 0;
    80005208:	4501                	li	a0,0
}
    8000520a:	60ea                	ld	ra,152(sp)
    8000520c:	644a                	ld	s0,144(sp)
    8000520e:	610d                	addi	sp,sp,160
    80005210:	8082                	ret
    end_op();
    80005212:	bedfe0ef          	jal	ra,80003dfe <end_op>
    return -1;
    80005216:	557d                	li	a0,-1
    80005218:	bfcd                	j	8000520a <sys_mknod+0x50>

000000008000521a <sys_chdir>:

uint64
sys_chdir(void)
{
    8000521a:	7135                	addi	sp,sp,-160
    8000521c:	ed06                	sd	ra,152(sp)
    8000521e:	e922                	sd	s0,144(sp)
    80005220:	e526                	sd	s1,136(sp)
    80005222:	e14a                	sd	s2,128(sp)
    80005224:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005226:	e0efc0ef          	jal	ra,80001834 <myproc>
    8000522a:	892a                	mv	s2,a0
  
  begin_op();
    8000522c:	b63fe0ef          	jal	ra,80003d8e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005230:	08000613          	li	a2,128
    80005234:	f6040593          	addi	a1,s0,-160
    80005238:	4501                	li	a0,0
    8000523a:	fc6fd0ef          	jal	ra,80002a00 <argstr>
    8000523e:	04054163          	bltz	a0,80005280 <sys_chdir+0x66>
    80005242:	f6040513          	addi	a0,s0,-160
    80005246:	959fe0ef          	jal	ra,80003b9e <namei>
    8000524a:	84aa                	mv	s1,a0
    8000524c:	c915                	beqz	a0,80005280 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    8000524e:	962fe0ef          	jal	ra,800033b0 <ilock>
  if(ip->type != T_DIR){  // 必须是目录类型
    80005252:	04449703          	lh	a4,68(s1)
    80005256:	4785                	li	a5,1
    80005258:	02f71863          	bne	a4,a5,80005288 <sys_chdir+0x6e>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000525c:	8526                	mv	a0,s1
    8000525e:	9fcfe0ef          	jal	ra,8000345a <iunlock>
  iput(p->cwd);  // 释放当前工作目录
    80005262:	15093503          	ld	a0,336(s2)
    80005266:	ac8fe0ef          	jal	ra,8000352e <iput>
  end_op();
    8000526a:	b95fe0ef          	jal	ra,80003dfe <end_op>
  p->cwd = ip;  // 更新为新的工作目录
    8000526e:	14993823          	sd	s1,336(s2)
  return 0;
    80005272:	4501                	li	a0,0
}
    80005274:	60ea                	ld	ra,152(sp)
    80005276:	644a                	ld	s0,144(sp)
    80005278:	64aa                	ld	s1,136(sp)
    8000527a:	690a                	ld	s2,128(sp)
    8000527c:	610d                	addi	sp,sp,160
    8000527e:	8082                	ret
    end_op();
    80005280:	b7ffe0ef          	jal	ra,80003dfe <end_op>
    return -1;
    80005284:	557d                	li	a0,-1
    80005286:	b7fd                	j	80005274 <sys_chdir+0x5a>
    iunlockput(ip);
    80005288:	8526                	mv	a0,s1
    8000528a:	b2cfe0ef          	jal	ra,800035b6 <iunlockput>
    end_op();
    8000528e:	b71fe0ef          	jal	ra,80003dfe <end_op>
    return -1;
    80005292:	557d                	li	a0,-1
    80005294:	b7c5                	j	80005274 <sys_chdir+0x5a>

0000000080005296 <sys_exec>:

uint64
sys_exec(void)
{
    80005296:	7145                	addi	sp,sp,-464
    80005298:	e786                	sd	ra,456(sp)
    8000529a:	e3a2                	sd	s0,448(sp)
    8000529c:	ff26                	sd	s1,440(sp)
    8000529e:	fb4a                	sd	s2,432(sp)
    800052a0:	f74e                	sd	s3,424(sp)
    800052a2:	f352                	sd	s4,416(sp)
    800052a4:	ef56                	sd	s5,408(sp)
    800052a6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);  // 获取参数地址
    800052a8:	e3840593          	addi	a1,s0,-456
    800052ac:	4505                	li	a0,1
    800052ae:	f36fd0ef          	jal	ra,800029e4 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {  // 获取程序路径
    800052b2:	08000613          	li	a2,128
    800052b6:	f4040593          	addi	a1,s0,-192
    800052ba:	4501                	li	a0,0
    800052bc:	f44fd0ef          	jal	ra,80002a00 <argstr>
    800052c0:	87aa                	mv	a5,a0
    return -1;
    800052c2:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {  // 获取程序路径
    800052c4:	0a07c463          	bltz	a5,8000536c <sys_exec+0xd6>
  }
  memset(argv, 0, sizeof(argv));
    800052c8:	10000613          	li	a2,256
    800052cc:	4581                	li	a1,0
    800052ce:	e4040513          	addi	a0,s0,-448
    800052d2:	96ffb0ef          	jal	ra,80000c40 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800052d6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800052da:	89a6                	mv	s3,s1
    800052dc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800052de:	02000a13          	li	s4,32
    800052e2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800052e6:	00391793          	slli	a5,s2,0x3
    800052ea:	e3040593          	addi	a1,s0,-464
    800052ee:	e3843503          	ld	a0,-456(s0)
    800052f2:	953e                	add	a0,a0,a5
    800052f4:	e4afd0ef          	jal	ra,8000293e <fetchaddr>
    800052f8:	02054663          	bltz	a0,80005324 <sys_exec+0x8e>
      goto bad;
    }
    if(uarg == 0){
    800052fc:	e3043783          	ld	a5,-464(s0)
    80005300:	cf8d                	beqz	a5,8000533a <sys_exec+0xa4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005302:	f9afb0ef          	jal	ra,80000a9c <kalloc>
    80005306:	85aa                	mv	a1,a0
    80005308:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000530c:	cd01                	beqz	a0,80005324 <sys_exec+0x8e>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000530e:	6605                	lui	a2,0x1
    80005310:	e3043503          	ld	a0,-464(s0)
    80005314:	e74fd0ef          	jal	ra,80002988 <fetchstr>
    80005318:	00054663          	bltz	a0,80005324 <sys_exec+0x8e>
    if(i >= NELEM(argv)){
    8000531c:	0905                	addi	s2,s2,1
    8000531e:	09a1                	addi	s3,s3,8
    80005320:	fd4911e3          	bne	s2,s4,800052e2 <sys_exec+0x4c>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005324:	10048913          	addi	s2,s1,256
    80005328:	6088                	ld	a0,0(s1)
    8000532a:	c121                	beqz	a0,8000536a <sys_exec+0xd4>
    kfree(argv[i]);
    8000532c:	e90fb0ef          	jal	ra,800009bc <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005330:	04a1                	addi	s1,s1,8
    80005332:	ff249be3          	bne	s1,s2,80005328 <sys_exec+0x92>
  return -1;
    80005336:	557d                	li	a0,-1
    80005338:	a815                	j	8000536c <sys_exec+0xd6>
      argv[i] = 0;
    8000533a:	0a8e                	slli	s5,s5,0x3
    8000533c:	fc040793          	addi	a5,s0,-64
    80005340:	9abe                	add	s5,s5,a5
    80005342:	e80ab023          	sd	zero,-384(s5)
  int ret = kexec(path, argv);  // 执行程序
    80005346:	e4040593          	addi	a1,s0,-448
    8000534a:	f4040513          	addi	a0,s0,-192
    8000534e:	bfaff0ef          	jal	ra,80004748 <kexec>
    80005352:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005354:	10048993          	addi	s3,s1,256
    80005358:	6088                	ld	a0,0(s1)
    8000535a:	c511                	beqz	a0,80005366 <sys_exec+0xd0>
    kfree(argv[i]);
    8000535c:	e60fb0ef          	jal	ra,800009bc <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005360:	04a1                	addi	s1,s1,8
    80005362:	ff349be3          	bne	s1,s3,80005358 <sys_exec+0xc2>
  return ret;
    80005366:	854a                	mv	a0,s2
    80005368:	a011                	j	8000536c <sys_exec+0xd6>
  return -1;
    8000536a:	557d                	li	a0,-1
}
    8000536c:	60be                	ld	ra,456(sp)
    8000536e:	641e                	ld	s0,448(sp)
    80005370:	74fa                	ld	s1,440(sp)
    80005372:	795a                	ld	s2,432(sp)
    80005374:	79ba                	ld	s3,424(sp)
    80005376:	7a1a                	ld	s4,416(sp)
    80005378:	6afa                	ld	s5,408(sp)
    8000537a:	6179                	addi	sp,sp,464
    8000537c:	8082                	ret

000000008000537e <sys_pipe>:

uint64
sys_pipe(void)
{
    8000537e:	7139                	addi	sp,sp,-64
    80005380:	fc06                	sd	ra,56(sp)
    80005382:	f822                	sd	s0,48(sp)
    80005384:	f426                	sd	s1,40(sp)
    80005386:	0080                	addi	s0,sp,64
  uint64 fdarray; // 用户指针指向两个整数的数组
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005388:	cacfc0ef          	jal	ra,80001834 <myproc>
    8000538c:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);  // 获取文件描述符数组地址
    8000538e:	fd840593          	addi	a1,s0,-40
    80005392:	4501                	li	a0,0
    80005394:	e50fd0ef          	jal	ra,800029e4 <argaddr>
  if(pipealloc(&rf, &wf) < 0)  // 分配管道文件
    80005398:	fc840593          	addi	a1,s0,-56
    8000539c:	fd040513          	addi	a0,s0,-48
    800053a0:	8c8ff0ef          	jal	ra,80004468 <pipealloc>
    return -1;
    800053a4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)  // 分配管道文件
    800053a6:	0a054463          	bltz	a0,8000544e <sys_pipe+0xd0>
  fd0 = -1;
    800053aa:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){  // 分配文件描述符
    800053ae:	fd043503          	ld	a0,-48(s0)
    800053b2:	f42ff0ef          	jal	ra,80004af4 <fdalloc>
    800053b6:	fca42223          	sw	a0,-60(s0)
    800053ba:	08054163          	bltz	a0,8000543c <sys_pipe+0xbe>
    800053be:	fc843503          	ld	a0,-56(s0)
    800053c2:	f32ff0ef          	jal	ra,80004af4 <fdalloc>
    800053c6:	fca42023          	sw	a0,-64(s0)
    800053ca:	06054063          	bltz	a0,8000542a <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||  // 将文件描述符写入用户空间
    800053ce:	4691                	li	a3,4
    800053d0:	fc440613          	addi	a2,s0,-60
    800053d4:	fd843583          	ld	a1,-40(s0)
    800053d8:	68a8                	ld	a0,80(s1)
    800053da:	978fc0ef          	jal	ra,80001552 <copyout>
    800053de:	00054e63          	bltz	a0,800053fa <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800053e2:	4691                	li	a3,4
    800053e4:	fc040613          	addi	a2,s0,-64
    800053e8:	fd843583          	ld	a1,-40(s0)
    800053ec:	0591                	addi	a1,a1,4
    800053ee:	68a8                	ld	a0,80(s1)
    800053f0:	962fc0ef          	jal	ra,80001552 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800053f4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||  // 将文件描述符写入用户空间
    800053f6:	04055c63          	bgez	a0,8000544e <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    800053fa:	fc442783          	lw	a5,-60(s0)
    800053fe:	07e9                	addi	a5,a5,26
    80005400:	078e                	slli	a5,a5,0x3
    80005402:	97a6                	add	a5,a5,s1
    80005404:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005408:	fc042503          	lw	a0,-64(s0)
    8000540c:	0569                	addi	a0,a0,26
    8000540e:	050e                	slli	a0,a0,0x3
    80005410:	94aa                	add	s1,s1,a0
    80005412:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005416:	fd043503          	ld	a0,-48(s0)
    8000541a:	d83fe0ef          	jal	ra,8000419c <fileclose>
    fileclose(wf);
    8000541e:	fc843503          	ld	a0,-56(s0)
    80005422:	d7bfe0ef          	jal	ra,8000419c <fileclose>
    return -1;
    80005426:	57fd                	li	a5,-1
    80005428:	a01d                	j	8000544e <sys_pipe+0xd0>
    if(fd0 >= 0)
    8000542a:	fc442783          	lw	a5,-60(s0)
    8000542e:	0007c763          	bltz	a5,8000543c <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    80005432:	07e9                	addi	a5,a5,26
    80005434:	078e                	slli	a5,a5,0x3
    80005436:	94be                	add	s1,s1,a5
    80005438:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000543c:	fd043503          	ld	a0,-48(s0)
    80005440:	d5dfe0ef          	jal	ra,8000419c <fileclose>
    fileclose(wf);
    80005444:	fc843503          	ld	a0,-56(s0)
    80005448:	d55fe0ef          	jal	ra,8000419c <fileclose>
    return -1;
    8000544c:	57fd                	li	a5,-1
}
    8000544e:	853e                	mv	a0,a5
    80005450:	70e2                	ld	ra,56(sp)
    80005452:	7442                	ld	s0,48(sp)
    80005454:	74a2                	ld	s1,40(sp)
    80005456:	6121                	addi	sp,sp,64
    80005458:	8082                	ret
    8000545a:	0000                	unimp
    8000545c:	0000                	unimp
	...

0000000080005460 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    80005460:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    80005462:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    80005464:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80005466:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80005468:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000546a:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000546c:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    8000546e:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80005470:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80005472:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    80005474:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    80005476:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    80005478:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    8000547a:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    8000547c:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    8000547e:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    80005480:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    80005482:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    80005484:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    80005486:	b6efd0ef          	jal	ra,800027f4 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    8000548a:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    8000548c:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    8000548e:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    80005490:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    80005492:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    80005494:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    80005496:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    80005498:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    8000549a:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    8000549c:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    8000549e:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800054a0:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800054a2:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    800054a4:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    800054a6:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    800054a8:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    800054aa:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    800054ac:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    800054ae:	10200073          	sret
	...

00000000800054be <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800054be:	1141                	addi	sp,sp,-16
    800054c0:	e422                	sd	s0,8(sp)
    800054c2:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800054c4:	0c0007b7          	lui	a5,0xc000
    800054c8:	4705                	li	a4,1
    800054ca:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800054cc:	c3d8                	sw	a4,4(a5)
}
    800054ce:	6422                	ld	s0,8(sp)
    800054d0:	0141                	addi	sp,sp,16
    800054d2:	8082                	ret

00000000800054d4 <plicinithart>:

void
plicinithart(void)
{
    800054d4:	1141                	addi	sp,sp,-16
    800054d6:	e406                	sd	ra,8(sp)
    800054d8:	e022                	sd	s0,0(sp)
    800054da:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800054dc:	b2cfc0ef          	jal	ra,80001808 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800054e0:	0085171b          	slliw	a4,a0,0x8
    800054e4:	0c0027b7          	lui	a5,0xc002
    800054e8:	97ba                	add	a5,a5,a4
    800054ea:	40200713          	li	a4,1026
    800054ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800054f2:	00d5151b          	slliw	a0,a0,0xd
    800054f6:	0c2017b7          	lui	a5,0xc201
    800054fa:	953e                	add	a0,a0,a5
    800054fc:	00052023          	sw	zero,0(a0)
}
    80005500:	60a2                	ld	ra,8(sp)
    80005502:	6402                	ld	s0,0(sp)
    80005504:	0141                	addi	sp,sp,16
    80005506:	8082                	ret

0000000080005508 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005508:	1141                	addi	sp,sp,-16
    8000550a:	e406                	sd	ra,8(sp)
    8000550c:	e022                	sd	s0,0(sp)
    8000550e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005510:	af8fc0ef          	jal	ra,80001808 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005514:	00d5179b          	slliw	a5,a0,0xd
    80005518:	0c201537          	lui	a0,0xc201
    8000551c:	953e                	add	a0,a0,a5
  return irq;
}
    8000551e:	4148                	lw	a0,4(a0)
    80005520:	60a2                	ld	ra,8(sp)
    80005522:	6402                	ld	s0,0(sp)
    80005524:	0141                	addi	sp,sp,16
    80005526:	8082                	ret

0000000080005528 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005528:	1101                	addi	sp,sp,-32
    8000552a:	ec06                	sd	ra,24(sp)
    8000552c:	e822                	sd	s0,16(sp)
    8000552e:	e426                	sd	s1,8(sp)
    80005530:	1000                	addi	s0,sp,32
    80005532:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005534:	ad4fc0ef          	jal	ra,80001808 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005538:	00d5151b          	slliw	a0,a0,0xd
    8000553c:	0c2017b7          	lui	a5,0xc201
    80005540:	97aa                	add	a5,a5,a0
    80005542:	c3c4                	sw	s1,4(a5)
}
    80005544:	60e2                	ld	ra,24(sp)
    80005546:	6442                	ld	s0,16(sp)
    80005548:	64a2                	ld	s1,8(sp)
    8000554a:	6105                	addi	sp,sp,32
    8000554c:	8082                	ret

000000008000554e <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    8000554e:	1141                	addi	sp,sp,-16
    80005550:	e406                	sd	ra,8(sp)
    80005552:	e022                	sd	s0,0(sp)
    80005554:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005556:	479d                	li	a5,7
    80005558:	04a7ca63          	blt	a5,a0,800055ac <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    8000555c:	0001c797          	auipc	a5,0x1c
    80005560:	b9c78793          	addi	a5,a5,-1124 # 800210f8 <disk>
    80005564:	97aa                	add	a5,a5,a0
    80005566:	0187c783          	lbu	a5,24(a5)
    8000556a:	e7b9                	bnez	a5,800055b8 <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000556c:	00451613          	slli	a2,a0,0x4
    80005570:	0001c797          	auipc	a5,0x1c
    80005574:	b8878793          	addi	a5,a5,-1144 # 800210f8 <disk>
    80005578:	6394                	ld	a3,0(a5)
    8000557a:	96b2                	add	a3,a3,a2
    8000557c:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005580:	6398                	ld	a4,0(a5)
    80005582:	9732                	add	a4,a4,a2
    80005584:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005588:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    8000558c:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005590:	953e                	add	a0,a0,a5
    80005592:	4785                	li	a5,1
    80005594:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005598:	0001c517          	auipc	a0,0x1c
    8000559c:	b7850513          	addi	a0,a0,-1160 # 80021110 <disk+0x18>
    800055a0:	c45fc0ef          	jal	ra,800021e4 <wakeup>
}
    800055a4:	60a2                	ld	ra,8(sp)
    800055a6:	6402                	ld	s0,0(sp)
    800055a8:	0141                	addi	sp,sp,16
    800055aa:	8082                	ret
    panic("free_desc 1");
    800055ac:	00002517          	auipc	a0,0x2
    800055b0:	18c50513          	addi	a0,a0,396 # 80007738 <syscalls+0x338>
    800055b4:	9d6fb0ef          	jal	ra,8000078a <panic>
    panic("free_desc 2");
    800055b8:	00002517          	auipc	a0,0x2
    800055bc:	19050513          	addi	a0,a0,400 # 80007748 <syscalls+0x348>
    800055c0:	9cafb0ef          	jal	ra,8000078a <panic>

00000000800055c4 <virtio_disk_init>:
{
    800055c4:	1101                	addi	sp,sp,-32
    800055c6:	ec06                	sd	ra,24(sp)
    800055c8:	e822                	sd	s0,16(sp)
    800055ca:	e426                	sd	s1,8(sp)
    800055cc:	e04a                	sd	s2,0(sp)
    800055ce:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800055d0:	00002597          	auipc	a1,0x2
    800055d4:	18858593          	addi	a1,a1,392 # 80007758 <syscalls+0x358>
    800055d8:	0001c517          	auipc	a0,0x1c
    800055dc:	c4850513          	addi	a0,a0,-952 # 80021220 <disk+0x128>
    800055e0:	d0cfb0ef          	jal	ra,80000aec <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800055e4:	100017b7          	lui	a5,0x10001
    800055e8:	4398                	lw	a4,0(a5)
    800055ea:	2701                	sext.w	a4,a4
    800055ec:	747277b7          	lui	a5,0x74727
    800055f0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800055f4:	14f71063          	bne	a4,a5,80005734 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800055f8:	100017b7          	lui	a5,0x10001
    800055fc:	43dc                	lw	a5,4(a5)
    800055fe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005600:	4709                	li	a4,2
    80005602:	12e79963          	bne	a5,a4,80005734 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005606:	100017b7          	lui	a5,0x10001
    8000560a:	479c                	lw	a5,8(a5)
    8000560c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000560e:	12e79363          	bne	a5,a4,80005734 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005612:	100017b7          	lui	a5,0x10001
    80005616:	47d8                	lw	a4,12(a5)
    80005618:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000561a:	554d47b7          	lui	a5,0x554d4
    8000561e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005622:	10f71963          	bne	a4,a5,80005734 <virtio_disk_init+0x170>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005626:	100017b7          	lui	a5,0x10001
    8000562a:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000562e:	4705                	li	a4,1
    80005630:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005632:	470d                	li	a4,3
    80005634:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005636:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005638:	c7ffe737          	lui	a4,0xc7ffe
    8000563c:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdd527>
    80005640:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005642:	2701                	sext.w	a4,a4
    80005644:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005646:	472d                	li	a4,11
    80005648:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    8000564a:	5bbc                	lw	a5,112(a5)
    8000564c:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005650:	8ba1                	andi	a5,a5,8
    80005652:	0e078763          	beqz	a5,80005740 <virtio_disk_init+0x17c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005656:	100017b7          	lui	a5,0x10001
    8000565a:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    8000565e:	43fc                	lw	a5,68(a5)
    80005660:	2781                	sext.w	a5,a5
    80005662:	0e079563          	bnez	a5,8000574c <virtio_disk_init+0x188>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005666:	100017b7          	lui	a5,0x10001
    8000566a:	5bdc                	lw	a5,52(a5)
    8000566c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000566e:	0e078563          	beqz	a5,80005758 <virtio_disk_init+0x194>
  if(max < NUM)
    80005672:	471d                	li	a4,7
    80005674:	0ef77863          	bgeu	a4,a5,80005764 <virtio_disk_init+0x1a0>
  disk.desc = kalloc();
    80005678:	c24fb0ef          	jal	ra,80000a9c <kalloc>
    8000567c:	0001c497          	auipc	s1,0x1c
    80005680:	a7c48493          	addi	s1,s1,-1412 # 800210f8 <disk>
    80005684:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005686:	c16fb0ef          	jal	ra,80000a9c <kalloc>
    8000568a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000568c:	c10fb0ef          	jal	ra,80000a9c <kalloc>
    80005690:	87aa                	mv	a5,a0
    80005692:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005694:	6088                	ld	a0,0(s1)
    80005696:	cd69                	beqz	a0,80005770 <virtio_disk_init+0x1ac>
    80005698:	0001c717          	auipc	a4,0x1c
    8000569c:	a6873703          	ld	a4,-1432(a4) # 80021100 <disk+0x8>
    800056a0:	cb61                	beqz	a4,80005770 <virtio_disk_init+0x1ac>
    800056a2:	c7f9                	beqz	a5,80005770 <virtio_disk_init+0x1ac>
  memset(disk.desc, 0, PGSIZE);
    800056a4:	6605                	lui	a2,0x1
    800056a6:	4581                	li	a1,0
    800056a8:	d98fb0ef          	jal	ra,80000c40 <memset>
  memset(disk.avail, 0, PGSIZE);
    800056ac:	0001c497          	auipc	s1,0x1c
    800056b0:	a4c48493          	addi	s1,s1,-1460 # 800210f8 <disk>
    800056b4:	6605                	lui	a2,0x1
    800056b6:	4581                	li	a1,0
    800056b8:	6488                	ld	a0,8(s1)
    800056ba:	d86fb0ef          	jal	ra,80000c40 <memset>
  memset(disk.used, 0, PGSIZE);
    800056be:	6605                	lui	a2,0x1
    800056c0:	4581                	li	a1,0
    800056c2:	6888                	ld	a0,16(s1)
    800056c4:	d7cfb0ef          	jal	ra,80000c40 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800056c8:	100017b7          	lui	a5,0x10001
    800056cc:	4721                	li	a4,8
    800056ce:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800056d0:	4098                	lw	a4,0(s1)
    800056d2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800056d6:	40d8                	lw	a4,4(s1)
    800056d8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800056dc:	6498                	ld	a4,8(s1)
    800056de:	0007069b          	sext.w	a3,a4
    800056e2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800056e6:	9701                	srai	a4,a4,0x20
    800056e8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800056ec:	6898                	ld	a4,16(s1)
    800056ee:	0007069b          	sext.w	a3,a4
    800056f2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800056f6:	9701                	srai	a4,a4,0x20
    800056f8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800056fc:	4705                	li	a4,1
    800056fe:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005700:	00e48c23          	sb	a4,24(s1)
    80005704:	00e48ca3          	sb	a4,25(s1)
    80005708:	00e48d23          	sb	a4,26(s1)
    8000570c:	00e48da3          	sb	a4,27(s1)
    80005710:	00e48e23          	sb	a4,28(s1)
    80005714:	00e48ea3          	sb	a4,29(s1)
    80005718:	00e48f23          	sb	a4,30(s1)
    8000571c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005720:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005724:	0727a823          	sw	s2,112(a5)
}
    80005728:	60e2                	ld	ra,24(sp)
    8000572a:	6442                	ld	s0,16(sp)
    8000572c:	64a2                	ld	s1,8(sp)
    8000572e:	6902                	ld	s2,0(sp)
    80005730:	6105                	addi	sp,sp,32
    80005732:	8082                	ret
    panic("could not find virtio disk");
    80005734:	00002517          	auipc	a0,0x2
    80005738:	03450513          	addi	a0,a0,52 # 80007768 <syscalls+0x368>
    8000573c:	84efb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk FEATURES_OK unset");
    80005740:	00002517          	auipc	a0,0x2
    80005744:	04850513          	addi	a0,a0,72 # 80007788 <syscalls+0x388>
    80005748:	842fb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk should not be ready");
    8000574c:	00002517          	auipc	a0,0x2
    80005750:	05c50513          	addi	a0,a0,92 # 800077a8 <syscalls+0x3a8>
    80005754:	836fb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk has no queue 0");
    80005758:	00002517          	auipc	a0,0x2
    8000575c:	07050513          	addi	a0,a0,112 # 800077c8 <syscalls+0x3c8>
    80005760:	82afb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk max queue too short");
    80005764:	00002517          	auipc	a0,0x2
    80005768:	08450513          	addi	a0,a0,132 # 800077e8 <syscalls+0x3e8>
    8000576c:	81efb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk kalloc");
    80005770:	00002517          	auipc	a0,0x2
    80005774:	09850513          	addi	a0,a0,152 # 80007808 <syscalls+0x408>
    80005778:	812fb0ef          	jal	ra,8000078a <panic>

000000008000577c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000577c:	7119                	addi	sp,sp,-128
    8000577e:	fc86                	sd	ra,120(sp)
    80005780:	f8a2                	sd	s0,112(sp)
    80005782:	f4a6                	sd	s1,104(sp)
    80005784:	f0ca                	sd	s2,96(sp)
    80005786:	ecce                	sd	s3,88(sp)
    80005788:	e8d2                	sd	s4,80(sp)
    8000578a:	e4d6                	sd	s5,72(sp)
    8000578c:	e0da                	sd	s6,64(sp)
    8000578e:	fc5e                	sd	s7,56(sp)
    80005790:	f862                	sd	s8,48(sp)
    80005792:	f466                	sd	s9,40(sp)
    80005794:	f06a                	sd	s10,32(sp)
    80005796:	ec6e                	sd	s11,24(sp)
    80005798:	0100                	addi	s0,sp,128
    8000579a:	8aaa                	mv	s5,a0
    8000579c:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000579e:	00c52d03          	lw	s10,12(a0)
    800057a2:	001d1d1b          	slliw	s10,s10,0x1
    800057a6:	1d02                	slli	s10,s10,0x20
    800057a8:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800057ac:	0001c517          	auipc	a0,0x1c
    800057b0:	a7450513          	addi	a0,a0,-1420 # 80021220 <disk+0x128>
    800057b4:	bb8fb0ef          	jal	ra,80000b6c <acquire>
  for(int i = 0; i < 3; i++){
    800057b8:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800057ba:	44a1                	li	s1,8
      disk.free[i] = 0;
    800057bc:	0001cb97          	auipc	s7,0x1c
    800057c0:	93cb8b93          	addi	s7,s7,-1732 # 800210f8 <disk>
  for(int i = 0; i < 3; i++){
    800057c4:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800057c6:	0001cc97          	auipc	s9,0x1c
    800057ca:	a5ac8c93          	addi	s9,s9,-1446 # 80021220 <disk+0x128>
    800057ce:	a8a9                	j	80005828 <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    800057d0:	00fb8733          	add	a4,s7,a5
    800057d4:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800057d8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800057da:	0207c563          	bltz	a5,80005804 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800057de:	2905                	addiw	s2,s2,1
    800057e0:	0611                	addi	a2,a2,4
    800057e2:	05690863          	beq	s2,s6,80005832 <virtio_disk_rw+0xb6>
    idx[i] = alloc_desc();
    800057e6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800057e8:	0001c717          	auipc	a4,0x1c
    800057ec:	91070713          	addi	a4,a4,-1776 # 800210f8 <disk>
    800057f0:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800057f2:	01874683          	lbu	a3,24(a4)
    800057f6:	fee9                	bnez	a3,800057d0 <virtio_disk_rw+0x54>
  for(int i = 0; i < NUM; i++){
    800057f8:	2785                	addiw	a5,a5,1
    800057fa:	0705                	addi	a4,a4,1
    800057fc:	fe979be3          	bne	a5,s1,800057f2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005800:	57fd                	li	a5,-1
    80005802:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005804:	01205b63          	blez	s2,8000581a <virtio_disk_rw+0x9e>
    80005808:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000580a:	000a2503          	lw	a0,0(s4)
    8000580e:	d41ff0ef          	jal	ra,8000554e <free_desc>
      for(int j = 0; j < i; j++)
    80005812:	2d85                	addiw	s11,s11,1
    80005814:	0a11                	addi	s4,s4,4
    80005816:	ffb91ae3          	bne	s2,s11,8000580a <virtio_disk_rw+0x8e>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000581a:	85e6                	mv	a1,s9
    8000581c:	0001c517          	auipc	a0,0x1c
    80005820:	8f450513          	addi	a0,a0,-1804 # 80021110 <disk+0x18>
    80005824:	d10fc0ef          	jal	ra,80001d34 <sleep>
  for(int i = 0; i < 3; i++){
    80005828:	f8040a13          	addi	s4,s0,-128
{
    8000582c:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000582e:	894e                	mv	s2,s3
    80005830:	bf5d                	j	800057e6 <virtio_disk_rw+0x6a>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005832:	f8042583          	lw	a1,-128(s0)
    80005836:	00a58793          	addi	a5,a1,10
    8000583a:	0792                	slli	a5,a5,0x4

  if(write)
    8000583c:	0001c617          	auipc	a2,0x1c
    80005840:	8bc60613          	addi	a2,a2,-1860 # 800210f8 <disk>
    80005844:	00f60733          	add	a4,a2,a5
    80005848:	018036b3          	snez	a3,s8
    8000584c:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000584e:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80005852:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005856:	f6078693          	addi	a3,a5,-160
    8000585a:	6218                	ld	a4,0(a2)
    8000585c:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000585e:	00878513          	addi	a0,a5,8
    80005862:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005864:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005866:	6208                	ld	a0,0(a2)
    80005868:	96aa                	add	a3,a3,a0
    8000586a:	4741                	li	a4,16
    8000586c:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000586e:	4705                	li	a4,1
    80005870:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80005874:	f8442703          	lw	a4,-124(s0)
    80005878:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    8000587c:	0712                	slli	a4,a4,0x4
    8000587e:	953a                	add	a0,a0,a4
    80005880:	058a8693          	addi	a3,s5,88
    80005884:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80005886:	6208                	ld	a0,0(a2)
    80005888:	972a                	add	a4,a4,a0
    8000588a:	40000693          	li	a3,1024
    8000588e:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80005890:	001c3c13          	seqz	s8,s8
    80005894:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005896:	001c6c13          	ori	s8,s8,1
    8000589a:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    8000589e:	f8842603          	lw	a2,-120(s0)
    800058a2:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800058a6:	0001c697          	auipc	a3,0x1c
    800058aa:	85268693          	addi	a3,a3,-1966 # 800210f8 <disk>
    800058ae:	00258713          	addi	a4,a1,2
    800058b2:	0712                	slli	a4,a4,0x4
    800058b4:	9736                	add	a4,a4,a3
    800058b6:	587d                	li	a6,-1
    800058b8:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800058bc:	0612                	slli	a2,a2,0x4
    800058be:	9532                	add	a0,a0,a2
    800058c0:	f9078793          	addi	a5,a5,-112
    800058c4:	97b6                	add	a5,a5,a3
    800058c6:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800058c8:	629c                	ld	a5,0(a3)
    800058ca:	97b2                	add	a5,a5,a2
    800058cc:	4605                	li	a2,1
    800058ce:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800058d0:	4509                	li	a0,2
    800058d2:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800058d6:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800058da:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800058de:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800058e2:	6698                	ld	a4,8(a3)
    800058e4:	00275783          	lhu	a5,2(a4)
    800058e8:	8b9d                	andi	a5,a5,7
    800058ea:	0786                	slli	a5,a5,0x1
    800058ec:	97ba                	add	a5,a5,a4
    800058ee:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800058f2:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800058f6:	6698                	ld	a4,8(a3)
    800058f8:	00275783          	lhu	a5,2(a4)
    800058fc:	2785                	addiw	a5,a5,1
    800058fe:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005902:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005906:	100017b7          	lui	a5,0x10001
    8000590a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000590e:	004aa783          	lw	a5,4(s5)
    80005912:	00c79f63          	bne	a5,a2,80005930 <virtio_disk_rw+0x1b4>
    sleep(b, &disk.vdisk_lock);
    80005916:	0001c917          	auipc	s2,0x1c
    8000591a:	90a90913          	addi	s2,s2,-1782 # 80021220 <disk+0x128>
  while(b->disk == 1) {
    8000591e:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005920:	85ca                	mv	a1,s2
    80005922:	8556                	mv	a0,s5
    80005924:	c10fc0ef          	jal	ra,80001d34 <sleep>
  while(b->disk == 1) {
    80005928:	004aa783          	lw	a5,4(s5)
    8000592c:	fe978ae3          	beq	a5,s1,80005920 <virtio_disk_rw+0x1a4>
  }

  disk.info[idx[0]].b = 0;
    80005930:	f8042903          	lw	s2,-128(s0)
    80005934:	00290793          	addi	a5,s2,2
    80005938:	00479713          	slli	a4,a5,0x4
    8000593c:	0001b797          	auipc	a5,0x1b
    80005940:	7bc78793          	addi	a5,a5,1980 # 800210f8 <disk>
    80005944:	97ba                	add	a5,a5,a4
    80005946:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000594a:	0001b997          	auipc	s3,0x1b
    8000594e:	7ae98993          	addi	s3,s3,1966 # 800210f8 <disk>
    80005952:	00491713          	slli	a4,s2,0x4
    80005956:	0009b783          	ld	a5,0(s3)
    8000595a:	97ba                	add	a5,a5,a4
    8000595c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005960:	854a                	mv	a0,s2
    80005962:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005966:	be9ff0ef          	jal	ra,8000554e <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000596a:	8885                	andi	s1,s1,1
    8000596c:	f0fd                	bnez	s1,80005952 <virtio_disk_rw+0x1d6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000596e:	0001c517          	auipc	a0,0x1c
    80005972:	8b250513          	addi	a0,a0,-1870 # 80021220 <disk+0x128>
    80005976:	a8efb0ef          	jal	ra,80000c04 <release>
}
    8000597a:	70e6                	ld	ra,120(sp)
    8000597c:	7446                	ld	s0,112(sp)
    8000597e:	74a6                	ld	s1,104(sp)
    80005980:	7906                	ld	s2,96(sp)
    80005982:	69e6                	ld	s3,88(sp)
    80005984:	6a46                	ld	s4,80(sp)
    80005986:	6aa6                	ld	s5,72(sp)
    80005988:	6b06                	ld	s6,64(sp)
    8000598a:	7be2                	ld	s7,56(sp)
    8000598c:	7c42                	ld	s8,48(sp)
    8000598e:	7ca2                	ld	s9,40(sp)
    80005990:	7d02                	ld	s10,32(sp)
    80005992:	6de2                	ld	s11,24(sp)
    80005994:	6109                	addi	sp,sp,128
    80005996:	8082                	ret

0000000080005998 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80005998:	1101                	addi	sp,sp,-32
    8000599a:	ec06                	sd	ra,24(sp)
    8000599c:	e822                	sd	s0,16(sp)
    8000599e:	e426                	sd	s1,8(sp)
    800059a0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800059a2:	0001b497          	auipc	s1,0x1b
    800059a6:	75648493          	addi	s1,s1,1878 # 800210f8 <disk>
    800059aa:	0001c517          	auipc	a0,0x1c
    800059ae:	87650513          	addi	a0,a0,-1930 # 80021220 <disk+0x128>
    800059b2:	9bafb0ef          	jal	ra,80000b6c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800059b6:	10001737          	lui	a4,0x10001
    800059ba:	533c                	lw	a5,96(a4)
    800059bc:	8b8d                	andi	a5,a5,3
    800059be:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800059c0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800059c4:	689c                	ld	a5,16(s1)
    800059c6:	0204d703          	lhu	a4,32(s1)
    800059ca:	0027d783          	lhu	a5,2(a5)
    800059ce:	04f70663          	beq	a4,a5,80005a1a <virtio_disk_intr+0x82>
    __sync_synchronize();
    800059d2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800059d6:	6898                	ld	a4,16(s1)
    800059d8:	0204d783          	lhu	a5,32(s1)
    800059dc:	8b9d                	andi	a5,a5,7
    800059de:	078e                	slli	a5,a5,0x3
    800059e0:	97ba                	add	a5,a5,a4
    800059e2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800059e4:	00278713          	addi	a4,a5,2
    800059e8:	0712                	slli	a4,a4,0x4
    800059ea:	9726                	add	a4,a4,s1
    800059ec:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800059f0:	e321                	bnez	a4,80005a30 <virtio_disk_intr+0x98>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800059f2:	0789                	addi	a5,a5,2
    800059f4:	0792                	slli	a5,a5,0x4
    800059f6:	97a6                	add	a5,a5,s1
    800059f8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800059fa:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800059fe:	fe6fc0ef          	jal	ra,800021e4 <wakeup>

    disk.used_idx += 1;
    80005a02:	0204d783          	lhu	a5,32(s1)
    80005a06:	2785                	addiw	a5,a5,1
    80005a08:	17c2                	slli	a5,a5,0x30
    80005a0a:	93c1                	srli	a5,a5,0x30
    80005a0c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005a10:	6898                	ld	a4,16(s1)
    80005a12:	00275703          	lhu	a4,2(a4)
    80005a16:	faf71ee3          	bne	a4,a5,800059d2 <virtio_disk_intr+0x3a>
  }

  release(&disk.vdisk_lock);
    80005a1a:	0001c517          	auipc	a0,0x1c
    80005a1e:	80650513          	addi	a0,a0,-2042 # 80021220 <disk+0x128>
    80005a22:	9e2fb0ef          	jal	ra,80000c04 <release>
}
    80005a26:	60e2                	ld	ra,24(sp)
    80005a28:	6442                	ld	s0,16(sp)
    80005a2a:	64a2                	ld	s1,8(sp)
    80005a2c:	6105                	addi	sp,sp,32
    80005a2e:	8082                	ret
      panic("virtio_disk_intr status");
    80005a30:	00002517          	auipc	a0,0x2
    80005a34:	df050513          	addi	a0,a0,-528 # 80007820 <syscalls+0x420>
    80005a38:	d53fa0ef          	jal	ra,8000078a <panic>
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
