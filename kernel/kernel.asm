
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
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdda87>
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
    8000010a:	0b2020ef          	jal	ra,800021bc <either_copyin>
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
    800001a8:	6a7010ef          	jal	ra,8000204e <killed>
    800001ac:	e125                	bnez	a0,8000020c <consoleread+0xc0>
      sleep(&cons.r, &cons.lock);
    800001ae:	85a6                	mv	a1,s1
    800001b0:	854a                	mv	a0,s2
    800001b2:	465010ef          	jal	ra,80001e16 <sleep>
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
    800001ea:	789010ef          	jal	ra,80002172 <either_copyout>
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
    800002aa:	75d010ef          	jal	ra,80002206 <procdump>
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
    800003e6:	27d010ef          	jal	ra,80001e62 <wakeup>
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
    80000410:	7d478793          	addi	a5,a5,2004 # 8001fbe0 <devsw>
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
    80000892:	584010ef          	jal	ra,80001e16 <sleep>
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
    800009a0:	4c2010ef          	jal	ra,80001e62 <wakeup>
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
    800009d4:	3a878793          	addi	a5,a5,936 # 80020d78 <end>
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
    80000a8c:	2f050513          	addi	a0,a0,752 # 80020d78 <end>
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
    80000e18:	5b8010ef          	jal	ra,800023d0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000e1c:	4d8040ef          	jal	ra,800052f4 <plicinithart>
  }

  scheduler();        
    80000e20:	65f000ef          	jal	ra,80001c7e <scheduler>
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
    80000e60:	54c010ef          	jal	ra,800023ac <trapinit>
    trapinithart();  // install kernel trap vector
    80000e64:	56c010ef          	jal	ra,800023d0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000e68:	476040ef          	jal	ra,800052de <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000e6c:	488040ef          	jal	ra,800052f4 <plicinithart>
    binit();         // buffer cache
    80000e70:	421010ef          	jal	ra,80002a90 <binit>
    iinit();         // inode table
    80000e74:	194020ef          	jal	ra,80003008 <iinit>
    fileinit();      // file table
    80000e78:	074030ef          	jal	ra,80003eec <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000e7c:	568040ef          	jal	ra,800053e4 <virtio_disk_init>
    userinit();      // first user process
    80000e80:	455000ef          	jal	ra,80001ad4 <userinit>
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
    800016da:	2c2a0a13          	addi	s4,s4,706 # 80015998 <tickslock>
    char *pa = kalloc();
    800016de:	bbeff0ef          	jal	ra,80000a9c <kalloc>
    800016e2:	862a                	mv	a2,a0
    if(pa == 0)
    800016e4:	c121                	beqz	a0,80001724 <proc_mapstacks+0x7e>
    uint64 va = KSTACK((int) (p - proc));
    800016e6:	416485b3          	sub	a1,s1,s6
    800016ea:	8591                	srai	a1,a1,0x4
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
    80001708:	17048493          	addi	s1,s1,368
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
    80001792:	20a98993          	addi	s3,s3,522 # 80015998 <tickslock>
      initlock(&p->lock, "proc");
    80001796:	85da                	mv	a1,s6
    80001798:	8526                	mv	a0,s1
    8000179a:	b52ff0ef          	jal	ra,80000aec <initlock>
      p->state = UNUSED;
    8000179e:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800017a2:	415487b3          	sub	a5,s1,s5
    800017a6:	8791                	srai	a5,a5,0x4
    800017a8:	000a3703          	ld	a4,0(s4)
    800017ac:	02e787b3          	mul	a5,a5,a4
    800017b0:	2785                	addiw	a5,a5,1
    800017b2:	00d7979b          	slliw	a5,a5,0xd
    800017b6:	40f907b3          	sub	a5,s2,a5
    800017ba:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800017bc:	17048493          	addi	s1,s1,368
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
    80001854:	465010ef          	jal	ra,800034b8 <fsinit>

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
    80001878:	4e9020ef          	jal	ra,80004560 <kexec>
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
    8000188a:	35f000ef          	jal	ra,800023e8 <prepare_return>
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
    80001a3c:	f6090913          	addi	s2,s2,-160 # 80015998 <tickslock>
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
    80001a50:	17048493          	addi	s1,s1,368
    80001a54:	ff2496e3          	bne	s1,s2,80001a40 <allocproc+0x1c>
  return 0;
    80001a58:	4481                	li	s1,0
    80001a5a:	a0b1                	j	80001aa6 <allocproc+0x82>
  p->pid = allocpid();
    80001a5c:	e71ff0ef          	jal	ra,800018cc <allocpid>
    80001a60:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001a62:	4785                	li	a5,1
    80001a64:	cc9c                	sw	a5,24(s1)
  p->ticks = 0;
    80001a66:	1604a423          	sw	zero,360(s1)
  p->timeslice =5;
    80001a6a:	4795                	li	a5,5
    80001a6c:	16f4a623          	sw	a5,364(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001a70:	82cff0ef          	jal	ra,80000a9c <kalloc>
    80001a74:	892a                	mv	s2,a0
    80001a76:	eca8                	sd	a0,88(s1)
    80001a78:	cd15                	beqz	a0,80001ab4 <allocproc+0x90>
  p->pagetable = proc_pagetable(p);
    80001a7a:	8526                	mv	a0,s1
    80001a7c:	e8fff0ef          	jal	ra,8000190a <proc_pagetable>
    80001a80:	892a                	mv	s2,a0
    80001a82:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001a84:	c121                	beqz	a0,80001ac4 <allocproc+0xa0>
  memset(&p->context, 0, sizeof(p->context));
    80001a86:	07000613          	li	a2,112
    80001a8a:	4581                	li	a1,0
    80001a8c:	06048513          	addi	a0,s1,96
    80001a90:	9b0ff0ef          	jal	ra,80000c40 <memset>
  p->context.ra = (uint64)forkret;
    80001a94:	00000797          	auipc	a5,0x0
    80001a98:	da078793          	addi	a5,a5,-608 # 80001834 <forkret>
    80001a9c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001a9e:	60bc                	ld	a5,64(s1)
    80001aa0:	6705                	lui	a4,0x1
    80001aa2:	97ba                	add	a5,a5,a4
    80001aa4:	f4bc                	sd	a5,104(s1)
}
    80001aa6:	8526                	mv	a0,s1
    80001aa8:	60e2                	ld	ra,24(sp)
    80001aaa:	6442                	ld	s0,16(sp)
    80001aac:	64a2                	ld	s1,8(sp)
    80001aae:	6902                	ld	s2,0(sp)
    80001ab0:	6105                	addi	sp,sp,32
    80001ab2:	8082                	ret
    freeproc(p);
    80001ab4:	8526                	mv	a0,s1
    80001ab6:	f1fff0ef          	jal	ra,800019d4 <freeproc>
    release(&p->lock);
    80001aba:	8526                	mv	a0,s1
    80001abc:	948ff0ef          	jal	ra,80000c04 <release>
    return 0;
    80001ac0:	84ca                	mv	s1,s2
    80001ac2:	b7d5                	j	80001aa6 <allocproc+0x82>
    freeproc(p);
    80001ac4:	8526                	mv	a0,s1
    80001ac6:	f0fff0ef          	jal	ra,800019d4 <freeproc>
    release(&p->lock);
    80001aca:	8526                	mv	a0,s1
    80001acc:	938ff0ef          	jal	ra,80000c04 <release>
    return 0;
    80001ad0:	84ca                	mv	s1,s2
    80001ad2:	bfd1                	j	80001aa6 <allocproc+0x82>

0000000080001ad4 <userinit>:
{
    80001ad4:	1101                	addi	sp,sp,-32
    80001ad6:	ec06                	sd	ra,24(sp)
    80001ad8:	e822                	sd	s0,16(sp)
    80001ada:	e426                	sd	s1,8(sp)
    80001adc:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ade:	f47ff0ef          	jal	ra,80001a24 <allocproc>
    80001ae2:	84aa                	mv	s1,a0
  initproc = p;
    80001ae4:	00006797          	auipc	a5,0x6
    80001ae8:	d6a7be23          	sd	a0,-644(a5) # 80007860 <initproc>
  p->cwd = namei("/");
    80001aec:	00005517          	auipc	a0,0x5
    80001af0:	6bc50513          	addi	a0,a0,1724 # 800071a8 <digits+0x170>
    80001af4:	6c3010ef          	jal	ra,800039b6 <namei>
    80001af8:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001afc:	478d                	li	a5,3
    80001afe:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001b00:	8526                	mv	a0,s1
    80001b02:	902ff0ef          	jal	ra,80000c04 <release>
}
    80001b06:	60e2                	ld	ra,24(sp)
    80001b08:	6442                	ld	s0,16(sp)
    80001b0a:	64a2                	ld	s1,8(sp)
    80001b0c:	6105                	addi	sp,sp,32
    80001b0e:	8082                	ret

0000000080001b10 <growproc>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001b1e:	ce7ff0ef          	jal	ra,80001804 <myproc>
    80001b22:	892a                	mv	s2,a0
  sz = p->sz;
    80001b24:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001b26:	02905963          	blez	s1,80001b58 <growproc+0x48>
    if(sz + n > TRAPFRAME) {
    80001b2a:	00b48633          	add	a2,s1,a1
    80001b2e:	020007b7          	lui	a5,0x2000
    80001b32:	17fd                	addi	a5,a5,-1
    80001b34:	07b6                	slli	a5,a5,0xd
    80001b36:	02c7ea63          	bltu	a5,a2,80001b6a <growproc+0x5a>
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001b3a:	4691                	li	a3,4
    80001b3c:	6928                	ld	a0,80(a0)
    80001b3e:	ee2ff0ef          	jal	ra,80001220 <uvmalloc>
    80001b42:	85aa                	mv	a1,a0
    80001b44:	c50d                	beqz	a0,80001b6e <growproc+0x5e>
  p->sz = sz;
    80001b46:	04b93423          	sd	a1,72(s2)
  return 0;
    80001b4a:	4501                	li	a0,0
}
    80001b4c:	60e2                	ld	ra,24(sp)
    80001b4e:	6442                	ld	s0,16(sp)
    80001b50:	64a2                	ld	s1,8(sp)
    80001b52:	6902                	ld	s2,0(sp)
    80001b54:	6105                	addi	sp,sp,32
    80001b56:	8082                	ret
  } else if(n < 0){
    80001b58:	fe04d7e3          	bgez	s1,80001b46 <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001b5c:	00b48633          	add	a2,s1,a1
    80001b60:	6928                	ld	a0,80(a0)
    80001b62:	e7aff0ef          	jal	ra,800011dc <uvmdealloc>
    80001b66:	85aa                	mv	a1,a0
    80001b68:	bff9                	j	80001b46 <growproc+0x36>
      return -1;
    80001b6a:	557d                	li	a0,-1
    80001b6c:	b7c5                	j	80001b4c <growproc+0x3c>
      return -1;
    80001b6e:	557d                	li	a0,-1
    80001b70:	bff1                	j	80001b4c <growproc+0x3c>

0000000080001b72 <kfork>:
{
    80001b72:	7139                	addi	sp,sp,-64
    80001b74:	fc06                	sd	ra,56(sp)
    80001b76:	f822                	sd	s0,48(sp)
    80001b78:	f426                	sd	s1,40(sp)
    80001b7a:	f04a                	sd	s2,32(sp)
    80001b7c:	ec4e                	sd	s3,24(sp)
    80001b7e:	e852                	sd	s4,16(sp)
    80001b80:	e456                	sd	s5,8(sp)
    80001b82:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001b84:	c81ff0ef          	jal	ra,80001804 <myproc>
    80001b88:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001b8a:	e9bff0ef          	jal	ra,80001a24 <allocproc>
    80001b8e:	0e050663          	beqz	a0,80001c7a <kfork+0x108>
    80001b92:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001b94:	048ab603          	ld	a2,72(s5)
    80001b98:	692c                	ld	a1,80(a0)
    80001b9a:	050ab503          	ld	a0,80(s5)
    80001b9e:	faaff0ef          	jal	ra,80001348 <uvmcopy>
    80001ba2:	04054863          	bltz	a0,80001bf2 <kfork+0x80>
  np->sz = p->sz;
    80001ba6:	048ab783          	ld	a5,72(s5)
    80001baa:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001bae:	058ab683          	ld	a3,88(s5)
    80001bb2:	87b6                	mv	a5,a3
    80001bb4:	058a3703          	ld	a4,88(s4)
    80001bb8:	12068693          	addi	a3,a3,288
    80001bbc:	0007b803          	ld	a6,0(a5) # 2000000 <_entry-0x7e000000>
    80001bc0:	6788                	ld	a0,8(a5)
    80001bc2:	6b8c                	ld	a1,16(a5)
    80001bc4:	6f90                	ld	a2,24(a5)
    80001bc6:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001bca:	e708                	sd	a0,8(a4)
    80001bcc:	eb0c                	sd	a1,16(a4)
    80001bce:	ef10                	sd	a2,24(a4)
    80001bd0:	02078793          	addi	a5,a5,32
    80001bd4:	02070713          	addi	a4,a4,32
    80001bd8:	fed792e3          	bne	a5,a3,80001bbc <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001bdc:	058a3783          	ld	a5,88(s4)
    80001be0:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001be4:	0d0a8493          	addi	s1,s5,208
    80001be8:	0d0a0913          	addi	s2,s4,208
    80001bec:	150a8993          	addi	s3,s5,336
    80001bf0:	a829                	j	80001c0a <kfork+0x98>
    freeproc(np);
    80001bf2:	8552                	mv	a0,s4
    80001bf4:	de1ff0ef          	jal	ra,800019d4 <freeproc>
    release(&np->lock);
    80001bf8:	8552                	mv	a0,s4
    80001bfa:	80aff0ef          	jal	ra,80000c04 <release>
    return -1;
    80001bfe:	597d                	li	s2,-1
    80001c00:	a09d                	j	80001c66 <kfork+0xf4>
  for(i = 0; i < NOFILE; i++)
    80001c02:	04a1                	addi	s1,s1,8
    80001c04:	0921                	addi	s2,s2,8
    80001c06:	01348963          	beq	s1,s3,80001c18 <kfork+0xa6>
    if(p->ofile[i])
    80001c0a:	6088                	ld	a0,0(s1)
    80001c0c:	d97d                	beqz	a0,80001c02 <kfork+0x90>
      np->ofile[i] = filedup(p->ofile[i]);
    80001c0e:	360020ef          	jal	ra,80003f6e <filedup>
    80001c12:	00a93023          	sd	a0,0(s2)
    80001c16:	b7f5                	j	80001c02 <kfork+0x90>
  np->cwd = idup(p->cwd);
    80001c18:	150ab503          	ld	a0,336(s5)
    80001c1c:	576010ef          	jal	ra,80003192 <idup>
    80001c20:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001c24:	4641                	li	a2,16
    80001c26:	158a8593          	addi	a1,s5,344
    80001c2a:	158a0513          	addi	a0,s4,344
    80001c2e:	958ff0ef          	jal	ra,80000d86 <safestrcpy>
  pid = np->pid;
    80001c32:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001c36:	8552                	mv	a0,s4
    80001c38:	fcdfe0ef          	jal	ra,80000c04 <release>
  acquire(&wait_lock);
    80001c3c:	0000e497          	auipc	s1,0xe
    80001c40:	d4448493          	addi	s1,s1,-700 # 8000f980 <wait_lock>
    80001c44:	8526                	mv	a0,s1
    80001c46:	f27fe0ef          	jal	ra,80000b6c <acquire>
  np->parent = p;
    80001c4a:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001c4e:	8526                	mv	a0,s1
    80001c50:	fb5fe0ef          	jal	ra,80000c04 <release>
  acquire(&np->lock);
    80001c54:	8552                	mv	a0,s4
    80001c56:	f17fe0ef          	jal	ra,80000b6c <acquire>
  np->state = RUNNABLE;
    80001c5a:	478d                	li	a5,3
    80001c5c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001c60:	8552                	mv	a0,s4
    80001c62:	fa3fe0ef          	jal	ra,80000c04 <release>
}
    80001c66:	854a                	mv	a0,s2
    80001c68:	70e2                	ld	ra,56(sp)
    80001c6a:	7442                	ld	s0,48(sp)
    80001c6c:	74a2                	ld	s1,40(sp)
    80001c6e:	7902                	ld	s2,32(sp)
    80001c70:	69e2                	ld	s3,24(sp)
    80001c72:	6a42                	ld	s4,16(sp)
    80001c74:	6aa2                	ld	s5,8(sp)
    80001c76:	6121                	addi	sp,sp,64
    80001c78:	8082                	ret
    return -1;
    80001c7a:	597d                	li	s2,-1
    80001c7c:	b7ed                	j	80001c66 <kfork+0xf4>

0000000080001c7e <scheduler>:
{
    80001c7e:	715d                	addi	sp,sp,-80
    80001c80:	e486                	sd	ra,72(sp)
    80001c82:	e0a2                	sd	s0,64(sp)
    80001c84:	fc26                	sd	s1,56(sp)
    80001c86:	f84a                	sd	s2,48(sp)
    80001c88:	f44e                	sd	s3,40(sp)
    80001c8a:	f052                	sd	s4,32(sp)
    80001c8c:	ec56                	sd	s5,24(sp)
    80001c8e:	e85a                	sd	s6,16(sp)
    80001c90:	e45e                	sd	s7,8(sp)
    80001c92:	e062                	sd	s8,0(sp)
    80001c94:	0880                	addi	s0,sp,80
    80001c96:	8792                	mv	a5,tp
  int id = r_tp();
    80001c98:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001c9a:	00779b13          	slli	s6,a5,0x7
    80001c9e:	0000e717          	auipc	a4,0xe
    80001ca2:	cca70713          	addi	a4,a4,-822 # 8000f968 <pid_lock>
    80001ca6:	975a                	add	a4,a4,s6
    80001ca8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001cac:	0000e717          	auipc	a4,0xe
    80001cb0:	cf470713          	addi	a4,a4,-780 # 8000f9a0 <cpus+0x8>
    80001cb4:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001cb6:	4c11                	li	s8,4
        c->proc = p;
    80001cb8:	079e                	slli	a5,a5,0x7
    80001cba:	0000ea17          	auipc	s4,0xe
    80001cbe:	caea0a13          	addi	s4,s4,-850 # 8000f968 <pid_lock>
    80001cc2:	9a3e                	add	s4,s4,a5
        found = 1;
    80001cc4:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001cc6:	00014997          	auipc	s3,0x14
    80001cca:	cd298993          	addi	s3,s3,-814 # 80015998 <tickslock>
    80001cce:	a83d                	j	80001d0c <scheduler+0x8e>
      release(&p->lock);
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	f33fe0ef          	jal	ra,80000c04 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001cd6:	17048493          	addi	s1,s1,368
    80001cda:	03348563          	beq	s1,s3,80001d04 <scheduler+0x86>
      acquire(&p->lock);
    80001cde:	8526                	mv	a0,s1
    80001ce0:	e8dfe0ef          	jal	ra,80000b6c <acquire>
      if(p->state == RUNNABLE) {
    80001ce4:	4c9c                	lw	a5,24(s1)
    80001ce6:	ff2795e3          	bne	a5,s2,80001cd0 <scheduler+0x52>
        p->state = RUNNING;
    80001cea:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001cee:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001cf2:	06048593          	addi	a1,s1,96
    80001cf6:	855a                	mv	a0,s6
    80001cf8:	64a000ef          	jal	ra,80002342 <swtch>
        c->proc = 0;
    80001cfc:	020a3823          	sd	zero,48(s4)
        found = 1;
    80001d00:	8ade                	mv	s5,s7
    80001d02:	b7f9                	j	80001cd0 <scheduler+0x52>
    if(found == 0) {
    80001d04:	000a9463          	bnez	s5,80001d0c <scheduler+0x8e>
      asm volatile("wfi");
    80001d08:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001d0c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001d10:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001d14:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001d18:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001d1c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001d1e:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001d22:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001d24:	0000e497          	auipc	s1,0xe
    80001d28:	07448493          	addi	s1,s1,116 # 8000fd98 <proc>
      if(p->state == RUNNABLE) {
    80001d2c:	490d                	li	s2,3
    80001d2e:	bf45                	j	80001cde <scheduler+0x60>

0000000080001d30 <sched>:
{
    80001d30:	7179                	addi	sp,sp,-48
    80001d32:	f406                	sd	ra,40(sp)
    80001d34:	f022                	sd	s0,32(sp)
    80001d36:	ec26                	sd	s1,24(sp)
    80001d38:	e84a                	sd	s2,16(sp)
    80001d3a:	e44e                	sd	s3,8(sp)
    80001d3c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d3e:	ac7ff0ef          	jal	ra,80001804 <myproc>
    80001d42:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001d44:	dbffe0ef          	jal	ra,80000b02 <holding>
    80001d48:	c92d                	beqz	a0,80001dba <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d4a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001d4c:	2781                	sext.w	a5,a5
    80001d4e:	079e                	slli	a5,a5,0x7
    80001d50:	0000e717          	auipc	a4,0xe
    80001d54:	c1870713          	addi	a4,a4,-1000 # 8000f968 <pid_lock>
    80001d58:	97ba                	add	a5,a5,a4
    80001d5a:	0a87a703          	lw	a4,168(a5)
    80001d5e:	4785                	li	a5,1
    80001d60:	06f71363          	bne	a4,a5,80001dc6 <sched+0x96>
  if(p->state == RUNNING)
    80001d64:	4c98                	lw	a4,24(s1)
    80001d66:	4791                	li	a5,4
    80001d68:	06f70563          	beq	a4,a5,80001dd2 <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001d6c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001d70:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001d72:	e7b5                	bnez	a5,80001dde <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d74:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001d76:	0000e917          	auipc	s2,0xe
    80001d7a:	bf290913          	addi	s2,s2,-1038 # 8000f968 <pid_lock>
    80001d7e:	2781                	sext.w	a5,a5
    80001d80:	079e                	slli	a5,a5,0x7
    80001d82:	97ca                	add	a5,a5,s2
    80001d84:	0ac7a983          	lw	s3,172(a5)
    80001d88:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001d8a:	2781                	sext.w	a5,a5
    80001d8c:	079e                	slli	a5,a5,0x7
    80001d8e:	0000e597          	auipc	a1,0xe
    80001d92:	c1258593          	addi	a1,a1,-1006 # 8000f9a0 <cpus+0x8>
    80001d96:	95be                	add	a1,a1,a5
    80001d98:	06048513          	addi	a0,s1,96
    80001d9c:	5a6000ef          	jal	ra,80002342 <swtch>
    80001da0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001da2:	2781                	sext.w	a5,a5
    80001da4:	079e                	slli	a5,a5,0x7
    80001da6:	97ca                	add	a5,a5,s2
    80001da8:	0b37a623          	sw	s3,172(a5)
}
    80001dac:	70a2                	ld	ra,40(sp)
    80001dae:	7402                	ld	s0,32(sp)
    80001db0:	64e2                	ld	s1,24(sp)
    80001db2:	6942                	ld	s2,16(sp)
    80001db4:	69a2                	ld	s3,8(sp)
    80001db6:	6145                	addi	sp,sp,48
    80001db8:	8082                	ret
    panic("sched p->lock");
    80001dba:	00005517          	auipc	a0,0x5
    80001dbe:	3f650513          	addi	a0,a0,1014 # 800071b0 <digits+0x178>
    80001dc2:	9c9fe0ef          	jal	ra,8000078a <panic>
    panic("sched locks");
    80001dc6:	00005517          	auipc	a0,0x5
    80001dca:	3fa50513          	addi	a0,a0,1018 # 800071c0 <digits+0x188>
    80001dce:	9bdfe0ef          	jal	ra,8000078a <panic>
    panic("sched RUNNING");
    80001dd2:	00005517          	auipc	a0,0x5
    80001dd6:	3fe50513          	addi	a0,a0,1022 # 800071d0 <digits+0x198>
    80001dda:	9b1fe0ef          	jal	ra,8000078a <panic>
    panic("sched interruptible");
    80001dde:	00005517          	auipc	a0,0x5
    80001de2:	40250513          	addi	a0,a0,1026 # 800071e0 <digits+0x1a8>
    80001de6:	9a5fe0ef          	jal	ra,8000078a <panic>

0000000080001dea <yield>:
{
    80001dea:	1101                	addi	sp,sp,-32
    80001dec:	ec06                	sd	ra,24(sp)
    80001dee:	e822                	sd	s0,16(sp)
    80001df0:	e426                	sd	s1,8(sp)
    80001df2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001df4:	a11ff0ef          	jal	ra,80001804 <myproc>
    80001df8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001dfa:	d73fe0ef          	jal	ra,80000b6c <acquire>
  p->state = RUNNABLE;
    80001dfe:	478d                	li	a5,3
    80001e00:	cc9c                	sw	a5,24(s1)
  sched();
    80001e02:	f2fff0ef          	jal	ra,80001d30 <sched>
  release(&p->lock);
    80001e06:	8526                	mv	a0,s1
    80001e08:	dfdfe0ef          	jal	ra,80000c04 <release>
}
    80001e0c:	60e2                	ld	ra,24(sp)
    80001e0e:	6442                	ld	s0,16(sp)
    80001e10:	64a2                	ld	s1,8(sp)
    80001e12:	6105                	addi	sp,sp,32
    80001e14:	8082                	ret

0000000080001e16 <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001e16:	7179                	addi	sp,sp,-48
    80001e18:	f406                	sd	ra,40(sp)
    80001e1a:	f022                	sd	s0,32(sp)
    80001e1c:	ec26                	sd	s1,24(sp)
    80001e1e:	e84a                	sd	s2,16(sp)
    80001e20:	e44e                	sd	s3,8(sp)
    80001e22:	1800                	addi	s0,sp,48
    80001e24:	89aa                	mv	s3,a0
    80001e26:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001e28:	9ddff0ef          	jal	ra,80001804 <myproc>
    80001e2c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001e2e:	d3ffe0ef          	jal	ra,80000b6c <acquire>
  release(lk);
    80001e32:	854a                	mv	a0,s2
    80001e34:	dd1fe0ef          	jal	ra,80000c04 <release>

  // Go to sleep.
  p->chan = chan;
    80001e38:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001e3c:	4789                	li	a5,2
    80001e3e:	cc9c                	sw	a5,24(s1)

  sched();
    80001e40:	ef1ff0ef          	jal	ra,80001d30 <sched>

  // Tidy up.
  p->chan = 0;
    80001e44:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001e48:	8526                	mv	a0,s1
    80001e4a:	dbbfe0ef          	jal	ra,80000c04 <release>
  acquire(lk);
    80001e4e:	854a                	mv	a0,s2
    80001e50:	d1dfe0ef          	jal	ra,80000b6c <acquire>
}
    80001e54:	70a2                	ld	ra,40(sp)
    80001e56:	7402                	ld	s0,32(sp)
    80001e58:	64e2                	ld	s1,24(sp)
    80001e5a:	6942                	ld	s2,16(sp)
    80001e5c:	69a2                	ld	s3,8(sp)
    80001e5e:	6145                	addi	sp,sp,48
    80001e60:	8082                	ret

0000000080001e62 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    80001e62:	7139                	addi	sp,sp,-64
    80001e64:	fc06                	sd	ra,56(sp)
    80001e66:	f822                	sd	s0,48(sp)
    80001e68:	f426                	sd	s1,40(sp)
    80001e6a:	f04a                	sd	s2,32(sp)
    80001e6c:	ec4e                	sd	s3,24(sp)
    80001e6e:	e852                	sd	s4,16(sp)
    80001e70:	e456                	sd	s5,8(sp)
    80001e72:	0080                	addi	s0,sp,64
    80001e74:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80001e76:	0000e497          	auipc	s1,0xe
    80001e7a:	f2248493          	addi	s1,s1,-222 # 8000fd98 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80001e7e:	4989                	li	s3,2
        p->state = RUNNABLE;
    80001e80:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e82:	00014917          	auipc	s2,0x14
    80001e86:	b1690913          	addi	s2,s2,-1258 # 80015998 <tickslock>
    80001e8a:	a801                	j	80001e9a <wakeup+0x38>
      }
      release(&p->lock);
    80001e8c:	8526                	mv	a0,s1
    80001e8e:	d77fe0ef          	jal	ra,80000c04 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e92:	17048493          	addi	s1,s1,368
    80001e96:	03248263          	beq	s1,s2,80001eba <wakeup+0x58>
    if(p != myproc()){
    80001e9a:	96bff0ef          	jal	ra,80001804 <myproc>
    80001e9e:	fea48ae3          	beq	s1,a0,80001e92 <wakeup+0x30>
      acquire(&p->lock);
    80001ea2:	8526                	mv	a0,s1
    80001ea4:	cc9fe0ef          	jal	ra,80000b6c <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80001ea8:	4c9c                	lw	a5,24(s1)
    80001eaa:	ff3791e3          	bne	a5,s3,80001e8c <wakeup+0x2a>
    80001eae:	709c                	ld	a5,32(s1)
    80001eb0:	fd479ee3          	bne	a5,s4,80001e8c <wakeup+0x2a>
        p->state = RUNNABLE;
    80001eb4:	0154ac23          	sw	s5,24(s1)
    80001eb8:	bfd1                	j	80001e8c <wakeup+0x2a>
    }
  }
}
    80001eba:	70e2                	ld	ra,56(sp)
    80001ebc:	7442                	ld	s0,48(sp)
    80001ebe:	74a2                	ld	s1,40(sp)
    80001ec0:	7902                	ld	s2,32(sp)
    80001ec2:	69e2                	ld	s3,24(sp)
    80001ec4:	6a42                	ld	s4,16(sp)
    80001ec6:	6aa2                	ld	s5,8(sp)
    80001ec8:	6121                	addi	sp,sp,64
    80001eca:	8082                	ret

0000000080001ecc <reparent>:
{
    80001ecc:	7179                	addi	sp,sp,-48
    80001ece:	f406                	sd	ra,40(sp)
    80001ed0:	f022                	sd	s0,32(sp)
    80001ed2:	ec26                	sd	s1,24(sp)
    80001ed4:	e84a                	sd	s2,16(sp)
    80001ed6:	e44e                	sd	s3,8(sp)
    80001ed8:	e052                	sd	s4,0(sp)
    80001eda:	1800                	addi	s0,sp,48
    80001edc:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ede:	0000e497          	auipc	s1,0xe
    80001ee2:	eba48493          	addi	s1,s1,-326 # 8000fd98 <proc>
      pp->parent = initproc;
    80001ee6:	00006a17          	auipc	s4,0x6
    80001eea:	97aa0a13          	addi	s4,s4,-1670 # 80007860 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001eee:	00014997          	auipc	s3,0x14
    80001ef2:	aaa98993          	addi	s3,s3,-1366 # 80015998 <tickslock>
    80001ef6:	a029                	j	80001f00 <reparent+0x34>
    80001ef8:	17048493          	addi	s1,s1,368
    80001efc:	01348b63          	beq	s1,s3,80001f12 <reparent+0x46>
    if(pp->parent == p){
    80001f00:	7c9c                	ld	a5,56(s1)
    80001f02:	ff279be3          	bne	a5,s2,80001ef8 <reparent+0x2c>
      pp->parent = initproc;
    80001f06:	000a3503          	ld	a0,0(s4)
    80001f0a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80001f0c:	f57ff0ef          	jal	ra,80001e62 <wakeup>
    80001f10:	b7e5                	j	80001ef8 <reparent+0x2c>
}
    80001f12:	70a2                	ld	ra,40(sp)
    80001f14:	7402                	ld	s0,32(sp)
    80001f16:	64e2                	ld	s1,24(sp)
    80001f18:	6942                	ld	s2,16(sp)
    80001f1a:	69a2                	ld	s3,8(sp)
    80001f1c:	6a02                	ld	s4,0(sp)
    80001f1e:	6145                	addi	sp,sp,48
    80001f20:	8082                	ret

0000000080001f22 <kexit>:
{
    80001f22:	7179                	addi	sp,sp,-48
    80001f24:	f406                	sd	ra,40(sp)
    80001f26:	f022                	sd	s0,32(sp)
    80001f28:	ec26                	sd	s1,24(sp)
    80001f2a:	e84a                	sd	s2,16(sp)
    80001f2c:	e44e                	sd	s3,8(sp)
    80001f2e:	e052                	sd	s4,0(sp)
    80001f30:	1800                	addi	s0,sp,48
    80001f32:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80001f34:	8d1ff0ef          	jal	ra,80001804 <myproc>
    80001f38:	89aa                	mv	s3,a0
  if(p == initproc)
    80001f3a:	00006797          	auipc	a5,0x6
    80001f3e:	9267b783          	ld	a5,-1754(a5) # 80007860 <initproc>
    80001f42:	0d050493          	addi	s1,a0,208
    80001f46:	15050913          	addi	s2,a0,336
    80001f4a:	00a79f63          	bne	a5,a0,80001f68 <kexit+0x46>
    panic("init exiting");
    80001f4e:	00005517          	auipc	a0,0x5
    80001f52:	2aa50513          	addi	a0,a0,682 # 800071f8 <digits+0x1c0>
    80001f56:	835fe0ef          	jal	ra,8000078a <panic>
      fileclose(f);
    80001f5a:	05a020ef          	jal	ra,80003fb4 <fileclose>
      p->ofile[fd] = 0;
    80001f5e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80001f62:	04a1                	addi	s1,s1,8
    80001f64:	01248563          	beq	s1,s2,80001f6e <kexit+0x4c>
    if(p->ofile[fd]){
    80001f68:	6088                	ld	a0,0(s1)
    80001f6a:	f965                	bnez	a0,80001f5a <kexit+0x38>
    80001f6c:	bfdd                	j	80001f62 <kexit+0x40>
  begin_op();
    80001f6e:	439010ef          	jal	ra,80003ba6 <begin_op>
  iput(p->cwd);
    80001f72:	1509b503          	ld	a0,336(s3)
    80001f76:	3d0010ef          	jal	ra,80003346 <iput>
  end_op();
    80001f7a:	49d010ef          	jal	ra,80003c16 <end_op>
  p->cwd = 0;
    80001f7e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80001f82:	0000e497          	auipc	s1,0xe
    80001f86:	9fe48493          	addi	s1,s1,-1538 # 8000f980 <wait_lock>
    80001f8a:	8526                	mv	a0,s1
    80001f8c:	be1fe0ef          	jal	ra,80000b6c <acquire>
  reparent(p);
    80001f90:	854e                	mv	a0,s3
    80001f92:	f3bff0ef          	jal	ra,80001ecc <reparent>
  wakeup(p->parent);
    80001f96:	0389b503          	ld	a0,56(s3)
    80001f9a:	ec9ff0ef          	jal	ra,80001e62 <wakeup>
  acquire(&p->lock);
    80001f9e:	854e                	mv	a0,s3
    80001fa0:	bcdfe0ef          	jal	ra,80000b6c <acquire>
  p->xstate = status;
    80001fa4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80001fa8:	4795                	li	a5,5
    80001faa:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80001fae:	8526                	mv	a0,s1
    80001fb0:	c55fe0ef          	jal	ra,80000c04 <release>
  sched();
    80001fb4:	d7dff0ef          	jal	ra,80001d30 <sched>
  panic("zombie exit");
    80001fb8:	00005517          	auipc	a0,0x5
    80001fbc:	25050513          	addi	a0,a0,592 # 80007208 <digits+0x1d0>
    80001fc0:	fcafe0ef          	jal	ra,8000078a <panic>

0000000080001fc4 <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    80001fc4:	7179                	addi	sp,sp,-48
    80001fc6:	f406                	sd	ra,40(sp)
    80001fc8:	f022                	sd	s0,32(sp)
    80001fca:	ec26                	sd	s1,24(sp)
    80001fcc:	e84a                	sd	s2,16(sp)
    80001fce:	e44e                	sd	s3,8(sp)
    80001fd0:	1800                	addi	s0,sp,48
    80001fd2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80001fd4:	0000e497          	auipc	s1,0xe
    80001fd8:	dc448493          	addi	s1,s1,-572 # 8000fd98 <proc>
    80001fdc:	00014997          	auipc	s3,0x14
    80001fe0:	9bc98993          	addi	s3,s3,-1604 # 80015998 <tickslock>
    acquire(&p->lock);
    80001fe4:	8526                	mv	a0,s1
    80001fe6:	b87fe0ef          	jal	ra,80000b6c <acquire>
    if(p->pid == pid){
    80001fea:	589c                	lw	a5,48(s1)
    80001fec:	01278b63          	beq	a5,s2,80002002 <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80001ff0:	8526                	mv	a0,s1
    80001ff2:	c13fe0ef          	jal	ra,80000c04 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80001ff6:	17048493          	addi	s1,s1,368
    80001ffa:	ff3495e3          	bne	s1,s3,80001fe4 <kkill+0x20>
  }
  return -1;
    80001ffe:	557d                	li	a0,-1
    80002000:	a819                	j	80002016 <kkill+0x52>
      p->killed = 1;
    80002002:	4785                	li	a5,1
    80002004:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002006:	4c98                	lw	a4,24(s1)
    80002008:	4789                	li	a5,2
    8000200a:	00f70d63          	beq	a4,a5,80002024 <kkill+0x60>
      release(&p->lock);
    8000200e:	8526                	mv	a0,s1
    80002010:	bf5fe0ef          	jal	ra,80000c04 <release>
      return 0;
    80002014:	4501                	li	a0,0
}
    80002016:	70a2                	ld	ra,40(sp)
    80002018:	7402                	ld	s0,32(sp)
    8000201a:	64e2                	ld	s1,24(sp)
    8000201c:	6942                	ld	s2,16(sp)
    8000201e:	69a2                	ld	s3,8(sp)
    80002020:	6145                	addi	sp,sp,48
    80002022:	8082                	ret
        p->state = RUNNABLE;
    80002024:	478d                	li	a5,3
    80002026:	cc9c                	sw	a5,24(s1)
    80002028:	b7dd                	j	8000200e <kkill+0x4a>

000000008000202a <setkilled>:

void
setkilled(struct proc *p)
{
    8000202a:	1101                	addi	sp,sp,-32
    8000202c:	ec06                	sd	ra,24(sp)
    8000202e:	e822                	sd	s0,16(sp)
    80002030:	e426                	sd	s1,8(sp)
    80002032:	1000                	addi	s0,sp,32
    80002034:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002036:	b37fe0ef          	jal	ra,80000b6c <acquire>
  p->killed = 1;
    8000203a:	4785                	li	a5,1
    8000203c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000203e:	8526                	mv	a0,s1
    80002040:	bc5fe0ef          	jal	ra,80000c04 <release>
}
    80002044:	60e2                	ld	ra,24(sp)
    80002046:	6442                	ld	s0,16(sp)
    80002048:	64a2                	ld	s1,8(sp)
    8000204a:	6105                	addi	sp,sp,32
    8000204c:	8082                	ret

000000008000204e <killed>:

int
killed(struct proc *p)
{
    8000204e:	1101                	addi	sp,sp,-32
    80002050:	ec06                	sd	ra,24(sp)
    80002052:	e822                	sd	s0,16(sp)
    80002054:	e426                	sd	s1,8(sp)
    80002056:	e04a                	sd	s2,0(sp)
    80002058:	1000                	addi	s0,sp,32
    8000205a:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000205c:	b11fe0ef          	jal	ra,80000b6c <acquire>
  k = p->killed;
    80002060:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002064:	8526                	mv	a0,s1
    80002066:	b9ffe0ef          	jal	ra,80000c04 <release>
  return k;
}
    8000206a:	854a                	mv	a0,s2
    8000206c:	60e2                	ld	ra,24(sp)
    8000206e:	6442                	ld	s0,16(sp)
    80002070:	64a2                	ld	s1,8(sp)
    80002072:	6902                	ld	s2,0(sp)
    80002074:	6105                	addi	sp,sp,32
    80002076:	8082                	ret

0000000080002078 <kwait>:
{
    80002078:	715d                	addi	sp,sp,-80
    8000207a:	e486                	sd	ra,72(sp)
    8000207c:	e0a2                	sd	s0,64(sp)
    8000207e:	fc26                	sd	s1,56(sp)
    80002080:	f84a                	sd	s2,48(sp)
    80002082:	f44e                	sd	s3,40(sp)
    80002084:	f052                	sd	s4,32(sp)
    80002086:	ec56                	sd	s5,24(sp)
    80002088:	e85a                	sd	s6,16(sp)
    8000208a:	e45e                	sd	s7,8(sp)
    8000208c:	e062                	sd	s8,0(sp)
    8000208e:	0880                	addi	s0,sp,80
    80002090:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002092:	f72ff0ef          	jal	ra,80001804 <myproc>
    80002096:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002098:	0000e517          	auipc	a0,0xe
    8000209c:	8e850513          	addi	a0,a0,-1816 # 8000f980 <wait_lock>
    800020a0:	acdfe0ef          	jal	ra,80000b6c <acquire>
    havekids = 0;
    800020a4:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800020a6:	4a15                	li	s4,5
        havekids = 1;
    800020a8:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800020aa:	00014997          	auipc	s3,0x14
    800020ae:	8ee98993          	addi	s3,s3,-1810 # 80015998 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020b2:	0000ec17          	auipc	s8,0xe
    800020b6:	8cec0c13          	addi	s8,s8,-1842 # 8000f980 <wait_lock>
    havekids = 0;
    800020ba:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800020bc:	0000e497          	auipc	s1,0xe
    800020c0:	cdc48493          	addi	s1,s1,-804 # 8000fd98 <proc>
    800020c4:	a899                	j	8000211a <kwait+0xa2>
          pid = pp->pid;
    800020c6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800020ca:	000b0c63          	beqz	s6,800020e2 <kwait+0x6a>
    800020ce:	4691                	li	a3,4
    800020d0:	02c48613          	addi	a2,s1,44
    800020d4:	85da                	mv	a1,s6
    800020d6:	05093503          	ld	a0,80(s2)
    800020da:	c78ff0ef          	jal	ra,80001552 <copyout>
    800020de:	00054f63          	bltz	a0,800020fc <kwait+0x84>
          freeproc(pp);
    800020e2:	8526                	mv	a0,s1
    800020e4:	8f1ff0ef          	jal	ra,800019d4 <freeproc>
          release(&pp->lock);
    800020e8:	8526                	mv	a0,s1
    800020ea:	b1bfe0ef          	jal	ra,80000c04 <release>
          release(&wait_lock);
    800020ee:	0000e517          	auipc	a0,0xe
    800020f2:	89250513          	addi	a0,a0,-1902 # 8000f980 <wait_lock>
    800020f6:	b0ffe0ef          	jal	ra,80000c04 <release>
          return pid;
    800020fa:	a891                	j	8000214e <kwait+0xd6>
            release(&pp->lock);
    800020fc:	8526                	mv	a0,s1
    800020fe:	b07fe0ef          	jal	ra,80000c04 <release>
            release(&wait_lock);
    80002102:	0000e517          	auipc	a0,0xe
    80002106:	87e50513          	addi	a0,a0,-1922 # 8000f980 <wait_lock>
    8000210a:	afbfe0ef          	jal	ra,80000c04 <release>
            return -1;
    8000210e:	59fd                	li	s3,-1
    80002110:	a83d                	j	8000214e <kwait+0xd6>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002112:	17048493          	addi	s1,s1,368
    80002116:	03348063          	beq	s1,s3,80002136 <kwait+0xbe>
      if(pp->parent == p){
    8000211a:	7c9c                	ld	a5,56(s1)
    8000211c:	ff279be3          	bne	a5,s2,80002112 <kwait+0x9a>
        acquire(&pp->lock);
    80002120:	8526                	mv	a0,s1
    80002122:	a4bfe0ef          	jal	ra,80000b6c <acquire>
        if(pp->state == ZOMBIE){
    80002126:	4c9c                	lw	a5,24(s1)
    80002128:	f9478fe3          	beq	a5,s4,800020c6 <kwait+0x4e>
        release(&pp->lock);
    8000212c:	8526                	mv	a0,s1
    8000212e:	ad7fe0ef          	jal	ra,80000c04 <release>
        havekids = 1;
    80002132:	8756                	mv	a4,s5
    80002134:	bff9                	j	80002112 <kwait+0x9a>
    if(!havekids || killed(p)){
    80002136:	c709                	beqz	a4,80002140 <kwait+0xc8>
    80002138:	854a                	mv	a0,s2
    8000213a:	f15ff0ef          	jal	ra,8000204e <killed>
    8000213e:	c50d                	beqz	a0,80002168 <kwait+0xf0>
      release(&wait_lock);
    80002140:	0000e517          	auipc	a0,0xe
    80002144:	84050513          	addi	a0,a0,-1984 # 8000f980 <wait_lock>
    80002148:	abdfe0ef          	jal	ra,80000c04 <release>
      return -1;
    8000214c:	59fd                	li	s3,-1
}
    8000214e:	854e                	mv	a0,s3
    80002150:	60a6                	ld	ra,72(sp)
    80002152:	6406                	ld	s0,64(sp)
    80002154:	74e2                	ld	s1,56(sp)
    80002156:	7942                	ld	s2,48(sp)
    80002158:	79a2                	ld	s3,40(sp)
    8000215a:	7a02                	ld	s4,32(sp)
    8000215c:	6ae2                	ld	s5,24(sp)
    8000215e:	6b42                	ld	s6,16(sp)
    80002160:	6ba2                	ld	s7,8(sp)
    80002162:	6c02                	ld	s8,0(sp)
    80002164:	6161                	addi	sp,sp,80
    80002166:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002168:	85e2                	mv	a1,s8
    8000216a:	854a                	mv	a0,s2
    8000216c:	cabff0ef          	jal	ra,80001e16 <sleep>
    havekids = 0;
    80002170:	b7a9                	j	800020ba <kwait+0x42>

0000000080002172 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002172:	7179                	addi	sp,sp,-48
    80002174:	f406                	sd	ra,40(sp)
    80002176:	f022                	sd	s0,32(sp)
    80002178:	ec26                	sd	s1,24(sp)
    8000217a:	e84a                	sd	s2,16(sp)
    8000217c:	e44e                	sd	s3,8(sp)
    8000217e:	e052                	sd	s4,0(sp)
    80002180:	1800                	addi	s0,sp,48
    80002182:	84aa                	mv	s1,a0
    80002184:	892e                	mv	s2,a1
    80002186:	89b2                	mv	s3,a2
    80002188:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000218a:	e7aff0ef          	jal	ra,80001804 <myproc>
  if(user_dst){
    8000218e:	cc99                	beqz	s1,800021ac <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    80002190:	86d2                	mv	a3,s4
    80002192:	864e                	mv	a2,s3
    80002194:	85ca                	mv	a1,s2
    80002196:	6928                	ld	a0,80(a0)
    80002198:	bbaff0ef          	jal	ra,80001552 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000219c:	70a2                	ld	ra,40(sp)
    8000219e:	7402                	ld	s0,32(sp)
    800021a0:	64e2                	ld	s1,24(sp)
    800021a2:	6942                	ld	s2,16(sp)
    800021a4:	69a2                	ld	s3,8(sp)
    800021a6:	6a02                	ld	s4,0(sp)
    800021a8:	6145                	addi	sp,sp,48
    800021aa:	8082                	ret
    memmove((char *)dst, src, len);
    800021ac:	000a061b          	sext.w	a2,s4
    800021b0:	85ce                	mv	a1,s3
    800021b2:	854a                	mv	a0,s2
    800021b4:	ae9fe0ef          	jal	ra,80000c9c <memmove>
    return 0;
    800021b8:	8526                	mv	a0,s1
    800021ba:	b7cd                	j	8000219c <either_copyout+0x2a>

00000000800021bc <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800021bc:	7179                	addi	sp,sp,-48
    800021be:	f406                	sd	ra,40(sp)
    800021c0:	f022                	sd	s0,32(sp)
    800021c2:	ec26                	sd	s1,24(sp)
    800021c4:	e84a                	sd	s2,16(sp)
    800021c6:	e44e                	sd	s3,8(sp)
    800021c8:	e052                	sd	s4,0(sp)
    800021ca:	1800                	addi	s0,sp,48
    800021cc:	892a                	mv	s2,a0
    800021ce:	84ae                	mv	s1,a1
    800021d0:	89b2                	mv	s3,a2
    800021d2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800021d4:	e30ff0ef          	jal	ra,80001804 <myproc>
  if(user_src){
    800021d8:	cc99                	beqz	s1,800021f6 <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    800021da:	86d2                	mv	a3,s4
    800021dc:	864e                	mv	a2,s3
    800021de:	85ca                	mv	a1,s2
    800021e0:	6928                	ld	a0,80(a0)
    800021e2:	c36ff0ef          	jal	ra,80001618 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800021e6:	70a2                	ld	ra,40(sp)
    800021e8:	7402                	ld	s0,32(sp)
    800021ea:	64e2                	ld	s1,24(sp)
    800021ec:	6942                	ld	s2,16(sp)
    800021ee:	69a2                	ld	s3,8(sp)
    800021f0:	6a02                	ld	s4,0(sp)
    800021f2:	6145                	addi	sp,sp,48
    800021f4:	8082                	ret
    memmove(dst, (char*)src, len);
    800021f6:	000a061b          	sext.w	a2,s4
    800021fa:	85ce                	mv	a1,s3
    800021fc:	854a                	mv	a0,s2
    800021fe:	a9ffe0ef          	jal	ra,80000c9c <memmove>
    return 0;
    80002202:	8526                	mv	a0,s1
    80002204:	b7cd                	j	800021e6 <either_copyin+0x2a>

0000000080002206 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002206:	715d                	addi	sp,sp,-80
    80002208:	e486                	sd	ra,72(sp)
    8000220a:	e0a2                	sd	s0,64(sp)
    8000220c:	fc26                	sd	s1,56(sp)
    8000220e:	f84a                	sd	s2,48(sp)
    80002210:	f44e                	sd	s3,40(sp)
    80002212:	f052                	sd	s4,32(sp)
    80002214:	ec56                	sd	s5,24(sp)
    80002216:	e85a                	sd	s6,16(sp)
    80002218:	e45e                	sd	s7,8(sp)
    8000221a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000221c:	00005517          	auipc	a0,0x5
    80002220:	ea450513          	addi	a0,a0,-348 # 800070c0 <digits+0x88>
    80002224:	aa0fe0ef          	jal	ra,800004c4 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002228:	0000e497          	auipc	s1,0xe
    8000222c:	cc848493          	addi	s1,s1,-824 # 8000fef0 <proc+0x158>
    80002230:	00014917          	auipc	s2,0x14
    80002234:	8c090913          	addi	s2,s2,-1856 # 80015af0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002238:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000223a:	00005997          	auipc	s3,0x5
    8000223e:	fde98993          	addi	s3,s3,-34 # 80007218 <digits+0x1e0>
    printf("%d %s %s", p->pid, state, p->name);
    80002242:	00005a97          	auipc	s5,0x5
    80002246:	fdea8a93          	addi	s5,s5,-34 # 80007220 <digits+0x1e8>
    printf("\n");
    8000224a:	00005a17          	auipc	s4,0x5
    8000224e:	e76a0a13          	addi	s4,s4,-394 # 800070c0 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002252:	00005b97          	auipc	s7,0x5
    80002256:	00eb8b93          	addi	s7,s7,14 # 80007260 <states.0>
    8000225a:	a829                	j	80002274 <procdump+0x6e>
    printf("%d %s %s", p->pid, state, p->name);
    8000225c:	ed86a583          	lw	a1,-296(a3)
    80002260:	8556                	mv	a0,s5
    80002262:	a62fe0ef          	jal	ra,800004c4 <printf>
    printf("\n");
    80002266:	8552                	mv	a0,s4
    80002268:	a5cfe0ef          	jal	ra,800004c4 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000226c:	17048493          	addi	s1,s1,368
    80002270:	03248163          	beq	s1,s2,80002292 <procdump+0x8c>
    if(p->state == UNUSED)
    80002274:	86a6                	mv	a3,s1
    80002276:	ec04a783          	lw	a5,-320(s1)
    8000227a:	dbed                	beqz	a5,8000226c <procdump+0x66>
      state = "???";
    8000227c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000227e:	fcfb6fe3          	bltu	s6,a5,8000225c <procdump+0x56>
    80002282:	1782                	slli	a5,a5,0x20
    80002284:	9381                	srli	a5,a5,0x20
    80002286:	078e                	slli	a5,a5,0x3
    80002288:	97de                	add	a5,a5,s7
    8000228a:	6390                	ld	a2,0(a5)
    8000228c:	fa61                	bnez	a2,8000225c <procdump+0x56>
      state = "???";
    8000228e:	864e                	mv	a2,s3
    80002290:	b7f1                	j	8000225c <procdump+0x56>
  }
}
    80002292:	60a6                	ld	ra,72(sp)
    80002294:	6406                	ld	s0,64(sp)
    80002296:	74e2                	ld	s1,56(sp)
    80002298:	7942                	ld	s2,48(sp)
    8000229a:	79a2                	ld	s3,40(sp)
    8000229c:	7a02                	ld	s4,32(sp)
    8000229e:	6ae2                	ld	s5,24(sp)
    800022a0:	6b42                	ld	s6,16(sp)
    800022a2:	6ba2                	ld	s7,8(sp)
    800022a4:	6161                	addi	sp,sp,80
    800022a6:	8082                	ret

00000000800022a8 <sys_dump_proc>:

int
sys_dump_proc(void)
{
    800022a8:	711d                	addi	sp,sp,-96
    800022aa:	ec86                	sd	ra,88(sp)
    800022ac:	e8a2                	sd	s0,80(sp)
    800022ae:	e4a6                	sd	s1,72(sp)
    800022b0:	e0ca                	sd	s2,64(sp)
    800022b2:	fc4e                	sd	s3,56(sp)
    800022b4:	1080                	addi	s0,sp,96
    uint64 addr;
    // 获取用户传入的指针地址（第0个参数）
    argaddr(0, &addr);  // 注意：argaddr 是 void，不返回错误
    800022b6:	fc840593          	addi	a1,s0,-56
    800022ba:	4501                	li	a0,0
    800022bc:	540000ef          	jal	ra,800027fc <argaddr>

    if (addr == 0)
    800022c0:	fc843783          	ld	a5,-56(s0)
    800022c4:	cfad                	beqz	a5,8000233e <sys_dump_proc+0x96>
    800022c6:	0000e497          	auipc	s1,0xe
    800022ca:	ad248493          	addi	s1,s1,-1326 # 8000fd98 <proc>
    800022ce:	00013997          	auipc	s3,0x13
    800022d2:	6ca98993          	addi	s3,s3,1738 # 80015998 <tickslock>
    800022d6:	4901                	li	s2,0
        return -1;  // 无效地址

    for (int i = 0; i < NPROC; i++) {
        struct proc *p = &proc[i];  // ← 现在在 proc.c 中，proc[] 可见！
        acquire(&p->lock);
    800022d8:	8526                	mv	a0,s1
    800022da:	893fe0ef          	jal	ra,80000b6c <acquire>
        struct pstat ps;
        ps.inuse = (p->state != UNUSED);
    800022de:	4c9c                	lw	a5,24(s1)
    800022e0:	00f03733          	snez	a4,a5
    800022e4:	fae42423          	sw	a4,-88(s0)
        ps.pid = p->pid;
    800022e8:	5898                	lw	a4,48(s1)
    800022ea:	fae42623          	sw	a4,-84(s0)
        ps.state = p->state;
    800022ee:	fcf42023          	sw	a5,-64(s0)
        safestrcpy(ps.name, p->name, sizeof(ps.name));
    800022f2:	4641                	li	a2,16
    800022f4:	15848593          	addi	a1,s1,344
    800022f8:	fb040513          	addi	a0,s0,-80
    800022fc:	a8bfe0ef          	jal	ra,80000d86 <safestrcpy>
        release(&p->lock);
    80002300:	8526                	mv	a0,s1
    80002302:	903fe0ef          	jal	ra,80000c04 <release>

        // 安全拷贝到用户空间
        if (copyout(myproc()->pagetable, addr + i * sizeof(ps), (char*)&ps, sizeof(ps)) < 0) {
    80002306:	cfeff0ef          	jal	ra,80001804 <myproc>
    8000230a:	46f1                	li	a3,28
    8000230c:	fa840613          	addi	a2,s0,-88
    80002310:	fc843583          	ld	a1,-56(s0)
    80002314:	95ca                	add	a1,a1,s2
    80002316:	6928                	ld	a0,80(a0)
    80002318:	a3aff0ef          	jal	ra,80001552 <copyout>
    8000231c:	00054963          	bltz	a0,8000232e <sys_dump_proc+0x86>
    for (int i = 0; i < NPROC; i++) {
    80002320:	17048493          	addi	s1,s1,368
    80002324:	0971                	addi	s2,s2,28
    80002326:	fb3499e3          	bne	s1,s3,800022d8 <sys_dump_proc+0x30>
            return -1;
        }
    }
    return 0;
    8000232a:	4501                	li	a0,0
    8000232c:	a011                	j	80002330 <sys_dump_proc+0x88>
            return -1;
    8000232e:	557d                	li	a0,-1
}
    80002330:	60e6                	ld	ra,88(sp)
    80002332:	6446                	ld	s0,80(sp)
    80002334:	64a6                	ld	s1,72(sp)
    80002336:	6906                	ld	s2,64(sp)
    80002338:	79e2                	ld	s3,56(sp)
    8000233a:	6125                	addi	sp,sp,96
    8000233c:	8082                	ret
        return -1;  // 无效地址
    8000233e:	557d                	li	a0,-1
    80002340:	bfc5                	j	80002330 <sys_dump_proc+0x88>

0000000080002342 <swtch>:
# 保存当前寄存器到 old，然后从 new 加载寄存器。

.globl swtch
swtch:
        # 保存当前的寄存器到 old 中
        sd ra, 0(a0)   # 保存返回地址寄存器 ra
    80002342:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)   # 保存栈指针寄存器 sp
    80002346:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)  # 保存寄存器 s0
    8000234a:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)  # 保存寄存器 s1
    8000234c:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)  # 保存寄存器 s2
    8000234e:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)  # 保存寄存器 s3
    80002352:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)  # 保存寄存器 s4
    80002356:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)  # 保存寄存器 s5
    8000235a:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)  # 保存寄存器 s6
    8000235e:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)  # 保存寄存器 s7
    80002362:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)  # 保存寄存器 s8
    80002366:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)  # 保存寄存器 s9
    8000236a:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0) # 保存寄存器 s10
    8000236e:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)# 保存寄存器 s11
    80002372:	07b53423          	sd	s11,104(a0)

        # 从 new 加载寄存器
        ld ra, 0(a1)   # 加载返回地址寄存器 ra
    80002376:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)   # 加载栈指针寄存器 sp
    8000237a:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)  # 加载寄存器 s0
    8000237e:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)  # 加载寄存器 s1
    80002380:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)  # 加载寄存器 s2
    80002382:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)  # 加载寄存器 s3
    80002386:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)  # 加载寄存器 s4
    8000238a:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)  # 加载寄存器 s5
    8000238e:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)  # 加载寄存器 s6
    80002392:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)  # 加载寄存器 s7
    80002396:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)  # 加载寄存器 s8
    8000239a:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)  # 加载寄存器 s9
    8000239e:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1) # 加载寄存器 s10
    800023a2:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)# 加载寄存器 s11
    800023a6:	0685bd83          	ld	s11,104(a1)

        ret             # 返回，完成上下文切换
    800023aa:	8082                	ret

00000000800023ac <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800023ac:	1141                	addi	sp,sp,-16
    800023ae:	e406                	sd	ra,8(sp)
    800023b0:	e022                	sd	s0,0(sp)
    800023b2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800023b4:	00005597          	auipc	a1,0x5
    800023b8:	edc58593          	addi	a1,a1,-292 # 80007290 <states.0+0x30>
    800023bc:	00013517          	auipc	a0,0x13
    800023c0:	5dc50513          	addi	a0,a0,1500 # 80015998 <tickslock>
    800023c4:	f28fe0ef          	jal	ra,80000aec <initlock>
}
    800023c8:	60a2                	ld	ra,8(sp)
    800023ca:	6402                	ld	s0,0(sp)
    800023cc:	0141                	addi	sp,sp,16
    800023ce:	8082                	ret

00000000800023d0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800023d0:	1141                	addi	sp,sp,-16
    800023d2:	e422                	sd	s0,8(sp)
    800023d4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800023d6:	00003797          	auipc	a5,0x3
    800023da:	eaa78793          	addi	a5,a5,-342 # 80005280 <kernelvec>
    800023de:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800023e2:	6422                	ld	s0,8(sp)
    800023e4:	0141                	addi	sp,sp,16
    800023e6:	8082                	ret

00000000800023e8 <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    800023e8:	1141                	addi	sp,sp,-16
    800023ea:	e406                	sd	ra,8(sp)
    800023ec:	e022                	sd	s0,0(sp)
    800023ee:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800023f0:	c14ff0ef          	jal	ra,80001804 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023f4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800023f8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800023fa:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800023fe:	04000737          	lui	a4,0x4000
    80002402:	00004797          	auipc	a5,0x4
    80002406:	bfe78793          	addi	a5,a5,-1026 # 80006000 <_trampoline>
    8000240a:	00004697          	auipc	a3,0x4
    8000240e:	bf668693          	addi	a3,a3,-1034 # 80006000 <_trampoline>
    80002412:	8f95                	sub	a5,a5,a3
    80002414:	177d                	addi	a4,a4,-1
    80002416:	0732                	slli	a4,a4,0xc
    80002418:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000241a:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000241e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002420:	18002773          	csrr	a4,satp
    80002424:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002426:	6d38                	ld	a4,88(a0)
    80002428:	613c                	ld	a5,64(a0)
    8000242a:	6685                	lui	a3,0x1
    8000242c:	97b6                	add	a5,a5,a3
    8000242e:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002430:	6d3c                	ld	a5,88(a0)
    80002432:	00000717          	auipc	a4,0x0
    80002436:	0f470713          	addi	a4,a4,244 # 80002526 <usertrap>
    8000243a:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000243c:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000243e:	8712                	mv	a4,tp
    80002440:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002442:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002446:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000244a:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000244e:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002452:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002454:	6f9c                	ld	a5,24(a5)
    80002456:	14179073          	csrw	sepc,a5
}
    8000245a:	60a2                	ld	ra,8(sp)
    8000245c:	6402                	ld	s0,0(sp)
    8000245e:	0141                	addi	sp,sp,16
    80002460:	8082                	ret

0000000080002462 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002462:	1101                	addi	sp,sp,-32
    80002464:	ec06                	sd	ra,24(sp)
    80002466:	e822                	sd	s0,16(sp)
    80002468:	e426                	sd	s1,8(sp)
    8000246a:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    8000246c:	b6cff0ef          	jal	ra,800017d8 <cpuid>
    80002470:	cd19                	beqz	a0,8000248e <clockintr+0x2c>
  asm volatile("csrr %0, time" : "=r" (x) );
    80002472:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    80002476:	000f4737          	lui	a4,0xf4
    8000247a:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    8000247e:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80002480:	14d79073          	csrw	0x14d,a5
}
    80002484:	60e2                	ld	ra,24(sp)
    80002486:	6442                	ld	s0,16(sp)
    80002488:	64a2                	ld	s1,8(sp)
    8000248a:	6105                	addi	sp,sp,32
    8000248c:	8082                	ret
    acquire(&tickslock);
    8000248e:	00013497          	auipc	s1,0x13
    80002492:	50a48493          	addi	s1,s1,1290 # 80015998 <tickslock>
    80002496:	8526                	mv	a0,s1
    80002498:	ed4fe0ef          	jal	ra,80000b6c <acquire>
    ticks++;
    8000249c:	00005517          	auipc	a0,0x5
    800024a0:	3cc50513          	addi	a0,a0,972 # 80007868 <ticks>
    800024a4:	411c                	lw	a5,0(a0)
    800024a6:	2785                	addiw	a5,a5,1
    800024a8:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    800024aa:	9b9ff0ef          	jal	ra,80001e62 <wakeup>
    release(&tickslock);
    800024ae:	8526                	mv	a0,s1
    800024b0:	f54fe0ef          	jal	ra,80000c04 <release>
    800024b4:	bf7d                	j	80002472 <clockintr+0x10>

00000000800024b6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800024b6:	1101                	addi	sp,sp,-32
    800024b8:	ec06                	sd	ra,24(sp)
    800024ba:	e822                	sd	s0,16(sp)
    800024bc:	e426                	sd	s1,8(sp)
    800024be:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800024c0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    800024c4:	57fd                	li	a5,-1
    800024c6:	17fe                	slli	a5,a5,0x3f
    800024c8:	07a5                	addi	a5,a5,9
    800024ca:	00f70d63          	beq	a4,a5,800024e4 <devintr+0x2e>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    800024ce:	57fd                	li	a5,-1
    800024d0:	17fe                	slli	a5,a5,0x3f
    800024d2:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    800024d4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    800024d6:	04f70463          	beq	a4,a5,8000251e <devintr+0x68>
  }
}
    800024da:	60e2                	ld	ra,24(sp)
    800024dc:	6442                	ld	s0,16(sp)
    800024de:	64a2                	ld	s1,8(sp)
    800024e0:	6105                	addi	sp,sp,32
    800024e2:	8082                	ret
    int irq = plic_claim();
    800024e4:	645020ef          	jal	ra,80005328 <plic_claim>
    800024e8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800024ea:	47a9                	li	a5,10
    800024ec:	02f50363          	beq	a0,a5,80002512 <devintr+0x5c>
    } else if(irq == VIRTIO0_IRQ){
    800024f0:	4785                	li	a5,1
    800024f2:	02f50363          	beq	a0,a5,80002518 <devintr+0x62>
    return 1;
    800024f6:	4505                	li	a0,1
    } else if(irq){
    800024f8:	d0ed                	beqz	s1,800024da <devintr+0x24>
      printf("unexpected interrupt irq=%d\n", irq);
    800024fa:	85a6                	mv	a1,s1
    800024fc:	00005517          	auipc	a0,0x5
    80002500:	d9c50513          	addi	a0,a0,-612 # 80007298 <states.0+0x38>
    80002504:	fc1fd0ef          	jal	ra,800004c4 <printf>
      plic_complete(irq);
    80002508:	8526                	mv	a0,s1
    8000250a:	63f020ef          	jal	ra,80005348 <plic_complete>
    return 1;
    8000250e:	4505                	li	a0,1
    80002510:	b7e9                	j	800024da <devintr+0x24>
      uartintr();
    80002512:	c46fe0ef          	jal	ra,80000958 <uartintr>
    80002516:	bfcd                	j	80002508 <devintr+0x52>
      virtio_disk_intr();
    80002518:	2a0030ef          	jal	ra,800057b8 <virtio_disk_intr>
    8000251c:	b7f5                	j	80002508 <devintr+0x52>
    clockintr();
    8000251e:	f45ff0ef          	jal	ra,80002462 <clockintr>
    return 2;
    80002522:	4509                	li	a0,2
    80002524:	bf5d                	j	800024da <devintr+0x24>

0000000080002526 <usertrap>:
{
    80002526:	1101                	addi	sp,sp,-32
    80002528:	ec06                	sd	ra,24(sp)
    8000252a:	e822                	sd	s0,16(sp)
    8000252c:	e426                	sd	s1,8(sp)
    8000252e:	e04a                	sd	s2,0(sp)
    80002530:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002532:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002536:	1007f793          	andi	a5,a5,256
    8000253a:	eba5                	bnez	a5,800025aa <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000253c:	00003797          	auipc	a5,0x3
    80002540:	d4478793          	addi	a5,a5,-700 # 80005280 <kernelvec>
    80002544:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002548:	abcff0ef          	jal	ra,80001804 <myproc>
    8000254c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000254e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002550:	14102773          	csrr	a4,sepc
    80002554:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002556:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000255a:	47a1                	li	a5,8
    8000255c:	04f70d63          	beq	a4,a5,800025b6 <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    80002560:	f57ff0ef          	jal	ra,800024b6 <devintr>
    80002564:	892a                	mv	s2,a0
    80002566:	e945                	bnez	a0,80002616 <usertrap+0xf0>
    80002568:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    8000256c:	47bd                	li	a5,15
    8000256e:	08f70863          	beq	a4,a5,800025fe <usertrap+0xd8>
    80002572:	14202773          	csrr	a4,scause
    80002576:	47b5                	li	a5,13
    80002578:	08f70363          	beq	a4,a5,800025fe <usertrap+0xd8>
    8000257c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    80002580:	5890                	lw	a2,48(s1)
    80002582:	00005517          	auipc	a0,0x5
    80002586:	d5650513          	addi	a0,a0,-682 # 800072d8 <states.0+0x78>
    8000258a:	f3bfd0ef          	jal	ra,800004c4 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000258e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002592:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    80002596:	00005517          	auipc	a0,0x5
    8000259a:	d7250513          	addi	a0,a0,-654 # 80007308 <states.0+0xa8>
    8000259e:	f27fd0ef          	jal	ra,800004c4 <printf>
    setkilled(p);
    800025a2:	8526                	mv	a0,s1
    800025a4:	a87ff0ef          	jal	ra,8000202a <setkilled>
    800025a8:	a035                	j	800025d4 <usertrap+0xae>
    panic("usertrap: not from user mode");
    800025aa:	00005517          	auipc	a0,0x5
    800025ae:	d0e50513          	addi	a0,a0,-754 # 800072b8 <states.0+0x58>
    800025b2:	9d8fe0ef          	jal	ra,8000078a <panic>
    if(killed(p))
    800025b6:	a99ff0ef          	jal	ra,8000204e <killed>
    800025ba:	ed15                	bnez	a0,800025f6 <usertrap+0xd0>
    p->trapframe->epc += 4;
    800025bc:	6cb8                	ld	a4,88(s1)
    800025be:	6f1c                	ld	a5,24(a4)
    800025c0:	0791                	addi	a5,a5,4
    800025c2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025c4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800025c8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025cc:	10079073          	csrw	sstatus,a5
    syscall();
    800025d0:	278000ef          	jal	ra,80002848 <syscall>
  if(killed(p))
    800025d4:	8526                	mv	a0,s1
    800025d6:	a79ff0ef          	jal	ra,8000204e <killed>
    800025da:	e139                	bnez	a0,80002620 <usertrap+0xfa>
  prepare_return();
    800025dc:	e0dff0ef          	jal	ra,800023e8 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800025e0:	68a8                	ld	a0,80(s1)
    800025e2:	8131                	srli	a0,a0,0xc
    800025e4:	57fd                	li	a5,-1
    800025e6:	17fe                	slli	a5,a5,0x3f
    800025e8:	8d5d                	or	a0,a0,a5
}
    800025ea:	60e2                	ld	ra,24(sp)
    800025ec:	6442                	ld	s0,16(sp)
    800025ee:	64a2                	ld	s1,8(sp)
    800025f0:	6902                	ld	s2,0(sp)
    800025f2:	6105                	addi	sp,sp,32
    800025f4:	8082                	ret
      kexit(-1);
    800025f6:	557d                	li	a0,-1
    800025f8:	92bff0ef          	jal	ra,80001f22 <kexit>
    800025fc:	b7c1                	j	800025bc <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    800025fe:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002602:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    80002606:	164d                	addi	a2,a2,-13
    80002608:	00163613          	seqz	a2,a2
    8000260c:	68a8                	ld	a0,80(s1)
    8000260e:	ed3fe0ef          	jal	ra,800014e0 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002612:	f169                	bnez	a0,800025d4 <usertrap+0xae>
    80002614:	b7a5                	j	8000257c <usertrap+0x56>
  if(killed(p))
    80002616:	8526                	mv	a0,s1
    80002618:	a37ff0ef          	jal	ra,8000204e <killed>
    8000261c:	c511                	beqz	a0,80002628 <usertrap+0x102>
    8000261e:	a011                	j	80002622 <usertrap+0xfc>
    80002620:	4901                	li	s2,0
    kexit(-1);
    80002622:	557d                	li	a0,-1
    80002624:	8ffff0ef          	jal	ra,80001f22 <kexit>
  if(which_dev == 2){
    80002628:	4789                	li	a5,2
    8000262a:	faf919e3          	bne	s2,a5,800025dc <usertrap+0xb6>
    yield();
    8000262e:	fbcff0ef          	jal	ra,80001dea <yield>
    80002632:	b76d                	j	800025dc <usertrap+0xb6>

0000000080002634 <kerneltrap>:
{
    80002634:	7179                	addi	sp,sp,-48
    80002636:	f406                	sd	ra,40(sp)
    80002638:	f022                	sd	s0,32(sp)
    8000263a:	ec26                	sd	s1,24(sp)
    8000263c:	e84a                	sd	s2,16(sp)
    8000263e:	e44e                	sd	s3,8(sp)
    80002640:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002642:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002646:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000264a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000264e:	1004f793          	andi	a5,s1,256
    80002652:	c795                	beqz	a5,8000267e <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002654:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002658:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000265a:	eb85                	bnez	a5,8000268a <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    8000265c:	e5bff0ef          	jal	ra,800024b6 <devintr>
    80002660:	c91d                	beqz	a0,80002696 <kerneltrap+0x62>
  if(which_dev == 2&&myproc()!=0) { // timer interrupt
    80002662:	4789                	li	a5,2
    80002664:	04f50a63          	beq	a0,a5,800026b8 <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002668:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000266c:	10049073          	csrw	sstatus,s1
}
    80002670:	70a2                	ld	ra,40(sp)
    80002672:	7402                	ld	s0,32(sp)
    80002674:	64e2                	ld	s1,24(sp)
    80002676:	6942                	ld	s2,16(sp)
    80002678:	69a2                	ld	s3,8(sp)
    8000267a:	6145                	addi	sp,sp,48
    8000267c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000267e:	00005517          	auipc	a0,0x5
    80002682:	cb250513          	addi	a0,a0,-846 # 80007330 <states.0+0xd0>
    80002686:	904fe0ef          	jal	ra,8000078a <panic>
    panic("kerneltrap: interrupts enabled");
    8000268a:	00005517          	auipc	a0,0x5
    8000268e:	cce50513          	addi	a0,a0,-818 # 80007358 <states.0+0xf8>
    80002692:	8f8fe0ef          	jal	ra,8000078a <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002696:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000269a:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    8000269e:	85ce                	mv	a1,s3
    800026a0:	00005517          	auipc	a0,0x5
    800026a4:	cd850513          	addi	a0,a0,-808 # 80007378 <states.0+0x118>
    800026a8:	e1dfd0ef          	jal	ra,800004c4 <printf>
    panic("kerneltrap");
    800026ac:	00005517          	auipc	a0,0x5
    800026b0:	cf450513          	addi	a0,a0,-780 # 800073a0 <states.0+0x140>
    800026b4:	8d6fe0ef          	jal	ra,8000078a <panic>
  if(which_dev == 2&&myproc()!=0) { // timer interrupt
    800026b8:	94cff0ef          	jal	ra,80001804 <myproc>
    800026bc:	d555                	beqz	a0,80002668 <kerneltrap+0x34>
    struct proc *p = myproc();
    800026be:	946ff0ef          	jal	ra,80001804 <myproc>
    800026c2:	89aa                	mv	s3,a0
    acquire(&p->lock);
    800026c4:	ca8fe0ef          	jal	ra,80000b6c <acquire>
    p->ticks++;
    800026c8:	1689a783          	lw	a5,360(s3)
    800026cc:	2785                	addiw	a5,a5,1
    800026ce:	0007871b          	sext.w	a4,a5
    800026d2:	16f9a423          	sw	a5,360(s3)
    if (need_yield) {
    800026d6:	16c9a783          	lw	a5,364(s3)
    800026da:	00f74a63          	blt	a4,a5,800026ee <kerneltrap+0xba>
      p->ticks = 0; // 重置时间片计数器
    800026de:	1609a423          	sw	zero,360(s3)
    release(&p->lock);
    800026e2:	854e                	mv	a0,s3
    800026e4:	d20fe0ef          	jal	ra,80000c04 <release>
      yield(); // 时间片用完，主动让出 CPU
    800026e8:	f02ff0ef          	jal	ra,80001dea <yield>
    800026ec:	bfb5                	j	80002668 <kerneltrap+0x34>
    release(&p->lock);
    800026ee:	854e                	mv	a0,s3
    800026f0:	d14fe0ef          	jal	ra,80000c04 <release>
    if (need_yield) {
    800026f4:	bf95                	j	80002668 <kerneltrap+0x34>

00000000800026f6 <argraw>:
}

// 获取第 n 个系统调用的原始参数（未处理过的原始值）
static uint64
argraw(int n)
{
    800026f6:	1101                	addi	sp,sp,-32
    800026f8:	ec06                	sd	ra,24(sp)
    800026fa:	e822                	sd	s0,16(sp)
    800026fc:	e426                	sd	s1,8(sp)
    800026fe:	1000                	addi	s0,sp,32
    80002700:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002702:	902ff0ef          	jal	ra,80001804 <myproc>
  switch (n) {
    80002706:	4795                	li	a5,5
    80002708:	0497e163          	bltu	a5,s1,8000274a <argraw+0x54>
    8000270c:	048a                	slli	s1,s1,0x2
    8000270e:	00005717          	auipc	a4,0x5
    80002712:	cca70713          	addi	a4,a4,-822 # 800073d8 <states.0+0x178>
    80002716:	94ba                	add	s1,s1,a4
    80002718:	409c                	lw	a5,0(s1)
    8000271a:	97ba                	add	a5,a5,a4
    8000271c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000271e:	6d3c                	ld	a5,88(a0)
    80002720:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");  // 如果参数 n 无效，触发 panic
  return -1;
}
    80002722:	60e2                	ld	ra,24(sp)
    80002724:	6442                	ld	s0,16(sp)
    80002726:	64a2                	ld	s1,8(sp)
    80002728:	6105                	addi	sp,sp,32
    8000272a:	8082                	ret
    return p->trapframe->a1;
    8000272c:	6d3c                	ld	a5,88(a0)
    8000272e:	7fa8                	ld	a0,120(a5)
    80002730:	bfcd                	j	80002722 <argraw+0x2c>
    return p->trapframe->a2;
    80002732:	6d3c                	ld	a5,88(a0)
    80002734:	63c8                	ld	a0,128(a5)
    80002736:	b7f5                	j	80002722 <argraw+0x2c>
    return p->trapframe->a3;
    80002738:	6d3c                	ld	a5,88(a0)
    8000273a:	67c8                	ld	a0,136(a5)
    8000273c:	b7dd                	j	80002722 <argraw+0x2c>
    return p->trapframe->a4;
    8000273e:	6d3c                	ld	a5,88(a0)
    80002740:	6bc8                	ld	a0,144(a5)
    80002742:	b7c5                	j	80002722 <argraw+0x2c>
    return p->trapframe->a5;
    80002744:	6d3c                	ld	a5,88(a0)
    80002746:	6fc8                	ld	a0,152(a5)
    80002748:	bfe9                	j	80002722 <argraw+0x2c>
  panic("argraw");  // 如果参数 n 无效，触发 panic
    8000274a:	00005517          	auipc	a0,0x5
    8000274e:	c6650513          	addi	a0,a0,-922 # 800073b0 <states.0+0x150>
    80002752:	838fe0ef          	jal	ra,8000078a <panic>

0000000080002756 <fetchaddr>:
{
    80002756:	1101                	addi	sp,sp,-32
    80002758:	ec06                	sd	ra,24(sp)
    8000275a:	e822                	sd	s0,16(sp)
    8000275c:	e426                	sd	s1,8(sp)
    8000275e:	e04a                	sd	s2,0(sp)
    80002760:	1000                	addi	s0,sp,32
    80002762:	84aa                	mv	s1,a0
    80002764:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002766:	89eff0ef          	jal	ra,80001804 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // 这两个条件都需要检查，防止溢出
    8000276a:	653c                	ld	a5,72(a0)
    8000276c:	02f4f663          	bgeu	s1,a5,80002798 <fetchaddr+0x42>
    80002770:	00848713          	addi	a4,s1,8
    80002774:	02e7e463          	bltu	a5,a4,8000279c <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002778:	46a1                	li	a3,8
    8000277a:	8626                	mv	a2,s1
    8000277c:	85ca                	mv	a1,s2
    8000277e:	6928                	ld	a0,80(a0)
    80002780:	e99fe0ef          	jal	ra,80001618 <copyin>
    80002784:	00a03533          	snez	a0,a0
    80002788:	40a00533          	neg	a0,a0
}
    8000278c:	60e2                	ld	ra,24(sp)
    8000278e:	6442                	ld	s0,16(sp)
    80002790:	64a2                	ld	s1,8(sp)
    80002792:	6902                	ld	s2,0(sp)
    80002794:	6105                	addi	sp,sp,32
    80002796:	8082                	ret
    return -1;
    80002798:	557d                	li	a0,-1
    8000279a:	bfcd                	j	8000278c <fetchaddr+0x36>
    8000279c:	557d                	li	a0,-1
    8000279e:	b7fd                	j	8000278c <fetchaddr+0x36>

00000000800027a0 <fetchstr>:
{
    800027a0:	7179                	addi	sp,sp,-48
    800027a2:	f406                	sd	ra,40(sp)
    800027a4:	f022                	sd	s0,32(sp)
    800027a6:	ec26                	sd	s1,24(sp)
    800027a8:	e84a                	sd	s2,16(sp)
    800027aa:	e44e                	sd	s3,8(sp)
    800027ac:	1800                	addi	s0,sp,48
    800027ae:	892a                	mv	s2,a0
    800027b0:	84ae                	mv	s1,a1
    800027b2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800027b4:	850ff0ef          	jal	ra,80001804 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800027b8:	86ce                	mv	a3,s3
    800027ba:	864a                	mv	a2,s2
    800027bc:	85a6                	mv	a1,s1
    800027be:	6928                	ld	a0,80(a0)
    800027c0:	c51fe0ef          	jal	ra,80001410 <copyinstr>
    800027c4:	00054c63          	bltz	a0,800027dc <fetchstr+0x3c>
  return strlen(buf);  // 返回字符串长度
    800027c8:	8526                	mv	a0,s1
    800027ca:	deefe0ef          	jal	ra,80000db8 <strlen>
}
    800027ce:	70a2                	ld	ra,40(sp)
    800027d0:	7402                	ld	s0,32(sp)
    800027d2:	64e2                	ld	s1,24(sp)
    800027d4:	6942                	ld	s2,16(sp)
    800027d6:	69a2                	ld	s3,8(sp)
    800027d8:	6145                	addi	sp,sp,48
    800027da:	8082                	ret
    return -1;
    800027dc:	557d                	li	a0,-1
    800027de:	bfc5                	j	800027ce <fetchstr+0x2e>

00000000800027e0 <argint>:

// 获取第 n 个 32 位的系统调用参数并将其存入 ip 中
void
argint(int n, int *ip)
{
    800027e0:	1101                	addi	sp,sp,-32
    800027e2:	ec06                	sd	ra,24(sp)
    800027e4:	e822                	sd	s0,16(sp)
    800027e6:	e426                	sd	s1,8(sp)
    800027e8:	1000                	addi	s0,sp,32
    800027ea:	84ae                	mv	s1,a1
  *ip = argraw(n);  // 通过 argraw 获取原始参数并存储
    800027ec:	f0bff0ef          	jal	ra,800026f6 <argraw>
    800027f0:	c088                	sw	a0,0(s1)
}
    800027f2:	60e2                	ld	ra,24(sp)
    800027f4:	6442                	ld	s0,16(sp)
    800027f6:	64a2                	ld	s1,8(sp)
    800027f8:	6105                	addi	sp,sp,32
    800027fa:	8082                	ret

00000000800027fc <argaddr>:

// 获取第 n 个参数并将其作为指针返回。
// 不进行合法性检查，因为 copyin 和 copyout 会处理这些检查。
void
argaddr(int n, uint64 *ip)
{
    800027fc:	1101                	addi	sp,sp,-32
    800027fe:	ec06                	sd	ra,24(sp)
    80002800:	e822                	sd	s0,16(sp)
    80002802:	e426                	sd	s1,8(sp)
    80002804:	1000                	addi	s0,sp,32
    80002806:	84ae                	mv	s1,a1
  *ip = argraw(n);  // 通过 argraw 获取原始参数并存储
    80002808:	eefff0ef          	jal	ra,800026f6 <argraw>
    8000280c:	e088                	sd	a0,0(s1)
}
    8000280e:	60e2                	ld	ra,24(sp)
    80002810:	6442                	ld	s0,16(sp)
    80002812:	64a2                	ld	s1,8(sp)
    80002814:	6105                	addi	sp,sp,32
    80002816:	8082                	ret

0000000080002818 <argstr>:
// 获取第 n 个参数，假设它是一个以 null 结尾的字符串。
// 将该字符串拷贝到 buf 中，最多拷贝 max 个字符。
// 成功时返回字符串长度（包括 null），出错时返回 -1。
int
argstr(int n, char *buf, int max)
{
    80002818:	7179                	addi	sp,sp,-48
    8000281a:	f406                	sd	ra,40(sp)
    8000281c:	f022                	sd	s0,32(sp)
    8000281e:	ec26                	sd	s1,24(sp)
    80002820:	e84a                	sd	s2,16(sp)
    80002822:	1800                	addi	s0,sp,48
    80002824:	84ae                	mv	s1,a1
    80002826:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);  // 获取第 n 个参数的地址
    80002828:	fd840593          	addi	a1,s0,-40
    8000282c:	fd1ff0ef          	jal	ra,800027fc <argaddr>
  return fetchstr(addr, buf, max);  // 使用 fetchstr 获取字符串内容
    80002830:	864a                	mv	a2,s2
    80002832:	85a6                	mv	a1,s1
    80002834:	fd843503          	ld	a0,-40(s0)
    80002838:	f69ff0ef          	jal	ra,800027a0 <fetchstr>
}
    8000283c:	70a2                	ld	ra,40(sp)
    8000283e:	7402                	ld	s0,32(sp)
    80002840:	64e2                	ld	s1,24(sp)
    80002842:	6942                	ld	s2,16(sp)
    80002844:	6145                	addi	sp,sp,48
    80002846:	8082                	ret

0000000080002848 <syscall>:
};

// 系统调用的入口函数
void
syscall(void)
{
    80002848:	1101                	addi	sp,sp,-32
    8000284a:	ec06                	sd	ra,24(sp)
    8000284c:	e822                	sd	s0,16(sp)
    8000284e:	e426                	sd	s1,8(sp)
    80002850:	e04a                	sd	s2,0(sp)
    80002852:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002854:	fb1fe0ef          	jal	ra,80001804 <myproc>
    80002858:	84aa                	mv	s1,a0

  num = p->trapframe->a7;  // 从 trapframe 中获取系统调用号
    8000285a:	05853903          	ld	s2,88(a0)
    8000285e:	0a893783          	ld	a5,168(s2)
    80002862:	0007869b          	sext.w	a3,a5
  // 检查系统调用号是否合法，且确保有对应的处理函数
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002866:	37fd                	addiw	a5,a5,-1
    80002868:	4755                	li	a4,21
    8000286a:	00f76f63          	bltu	a4,a5,80002888 <syscall+0x40>
    8000286e:	00369713          	slli	a4,a3,0x3
    80002872:	00005797          	auipc	a5,0x5
    80002876:	b7e78793          	addi	a5,a5,-1154 # 800073f0 <syscalls>
    8000287a:	97ba                	add	a5,a5,a4
    8000287c:	639c                	ld	a5,0(a5)
    8000287e:	c789                	beqz	a5,80002888 <syscall+0x40>
    // 根据系统调用号查找对应的系统调用函数并调用
    // 系统调用的返回值会存储在 p->trapframe->a0 中
    p->trapframe->a0 = syscalls[num]();
    80002880:	9782                	jalr	a5
    80002882:	06a93823          	sd	a0,112(s2)
    80002886:	a829                	j	800028a0 <syscall+0x58>
  } else {
    // 如果找不到有效的系统调用，打印错误信息
    printf("%d %s: unknown sys call %d\n",
    80002888:	15848613          	addi	a2,s1,344
    8000288c:	588c                	lw	a1,48(s1)
    8000288e:	00005517          	auipc	a0,0x5
    80002892:	b2a50513          	addi	a0,a0,-1238 # 800073b8 <states.0+0x158>
    80002896:	c2ffd0ef          	jal	ra,800004c4 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;  // 设置返回值为 -1 表示错误
    8000289a:	6cbc                	ld	a5,88(s1)
    8000289c:	577d                	li	a4,-1
    8000289e:	fbb8                	sd	a4,112(a5)
  }
}
    800028a0:	60e2                	ld	ra,24(sp)
    800028a2:	6442                	ld	s0,16(sp)
    800028a4:	64a2                	ld	s1,8(sp)
    800028a6:	6902                	ld	s2,0(sp)
    800028a8:	6105                	addi	sp,sp,32
    800028aa:	8082                	ret

00000000800028ac <sys_exit>:
#include "vm.h"

// 进程退出系统调用
uint64
sys_exit(void)
{
    800028ac:	1101                	addi	sp,sp,-32
    800028ae:	ec06                	sd	ra,24(sp)
    800028b0:	e822                	sd	s0,16(sp)
    800028b2:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);  // 获取退出码
    800028b4:	fec40593          	addi	a1,s0,-20
    800028b8:	4501                	li	a0,0
    800028ba:	f27ff0ef          	jal	ra,800027e0 <argint>
  kexit(n);       // 调用内核的退出函数
    800028be:	fec42503          	lw	a0,-20(s0)
    800028c2:	e60ff0ef          	jal	ra,80001f22 <kexit>
  return 0;       // 不会执行到这里
}
    800028c6:	4501                	li	a0,0
    800028c8:	60e2                	ld	ra,24(sp)
    800028ca:	6442                	ld	s0,16(sp)
    800028cc:	6105                	addi	sp,sp,32
    800028ce:	8082                	ret

00000000800028d0 <sys_getpid>:

// 获取当前进程的进程ID
uint64
sys_getpid(void)
{
    800028d0:	1141                	addi	sp,sp,-16
    800028d2:	e406                	sd	ra,8(sp)
    800028d4:	e022                	sd	s0,0(sp)
    800028d6:	0800                	addi	s0,sp,16
  return myproc()->pid;  // 返回当前进程的 PID
    800028d8:	f2dfe0ef          	jal	ra,80001804 <myproc>
}
    800028dc:	5908                	lw	a0,48(a0)
    800028de:	60a2                	ld	ra,8(sp)
    800028e0:	6402                	ld	s0,0(sp)
    800028e2:	0141                	addi	sp,sp,16
    800028e4:	8082                	ret

00000000800028e6 <sys_fork>:

// 创建一个新的子进程
uint64
sys_fork(void)
{
    800028e6:	1141                	addi	sp,sp,-16
    800028e8:	e406                	sd	ra,8(sp)
    800028ea:	e022                	sd	s0,0(sp)
    800028ec:	0800                	addi	s0,sp,16
  return kfork();  // 调用内核的 fork 函数
    800028ee:	a84ff0ef          	jal	ra,80001b72 <kfork>
}
    800028f2:	60a2                	ld	ra,8(sp)
    800028f4:	6402                	ld	s0,0(sp)
    800028f6:	0141                	addi	sp,sp,16
    800028f8:	8082                	ret

00000000800028fa <sys_wait>:

// 等待子进程退出
uint64
sys_wait(void)
{
    800028fa:	1101                	addi	sp,sp,-32
    800028fc:	ec06                	sd	ra,24(sp)
    800028fe:	e822                	sd	s0,16(sp)
    80002900:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);  // 获取等待子进程状态的地址
    80002902:	fe840593          	addi	a1,s0,-24
    80002906:	4501                	li	a0,0
    80002908:	ef5ff0ef          	jal	ra,800027fc <argaddr>
  return kwait(p);  // 调用内核的 wait 函数
    8000290c:	fe843503          	ld	a0,-24(s0)
    80002910:	f68ff0ef          	jal	ra,80002078 <kwait>
}
    80002914:	60e2                	ld	ra,24(sp)
    80002916:	6442                	ld	s0,16(sp)
    80002918:	6105                	addi	sp,sp,32
    8000291a:	8082                	ret

000000008000291c <sys_sbrk>:

// 扩展或收缩进程的内存
uint64
sys_sbrk(void)
{
    8000291c:	7179                	addi	sp,sp,-48
    8000291e:	f406                	sd	ra,40(sp)
    80002920:	f022                	sd	s0,32(sp)
    80002922:	ec26                	sd	s1,24(sp)
    80002924:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);  // 获取内存增量
    80002926:	fd840593          	addi	a1,s0,-40
    8000292a:	4501                	li	a0,0
    8000292c:	eb5ff0ef          	jal	ra,800027e0 <argint>
  argint(1, &t);  // 获取是否懒加载标志
    80002930:	fdc40593          	addi	a1,s0,-36
    80002934:	4505                	li	a0,1
    80002936:	eabff0ef          	jal	ra,800027e0 <argint>
  addr = myproc()->sz;  // 获取当前进程的内存大小
    8000293a:	ecbfe0ef          	jal	ra,80001804 <myproc>
    8000293e:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {  // 如果是急切分配或要求收缩内存
    80002940:	fdc42703          	lw	a4,-36(s0)
    80002944:	4785                	li	a5,1
    80002946:	02f70763          	beq	a4,a5,80002974 <sys_sbrk+0x58>
    8000294a:	fd842783          	lw	a5,-40(s0)
    8000294e:	0207c363          	bltz	a5,80002974 <sys_sbrk+0x58>
    if(growproc(n) < 0) {  // 调用内核的 growproc 函数调整内存
      return -1;  // 内存分配失败
    }
  } else {  // 如果是懒加载分配
    if(addr + n < addr)  // 防止内存溢出
    80002952:	97a6                	add	a5,a5,s1
    80002954:	0297ee63          	bltu	a5,s1,80002990 <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)  // 限制内存的最大值
    80002958:	02000737          	lui	a4,0x2000
    8000295c:	177d                	addi	a4,a4,-1
    8000295e:	0736                	slli	a4,a4,0xd
    80002960:	02f76a63          	bltu	a4,a5,80002994 <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;  // 调整进程的内存大小
    80002964:	ea1fe0ef          	jal	ra,80001804 <myproc>
    80002968:	fd842703          	lw	a4,-40(s0)
    8000296c:	653c                	ld	a5,72(a0)
    8000296e:	97ba                	add	a5,a5,a4
    80002970:	e53c                	sd	a5,72(a0)
    80002972:	a039                	j	80002980 <sys_sbrk+0x64>
    if(growproc(n) < 0) {  // 调用内核的 growproc 函数调整内存
    80002974:	fd842503          	lw	a0,-40(s0)
    80002978:	998ff0ef          	jal	ra,80001b10 <growproc>
    8000297c:	00054863          	bltz	a0,8000298c <sys_sbrk+0x70>
  }
  return addr;  // 返回原内存地址
}
    80002980:	8526                	mv	a0,s1
    80002982:	70a2                	ld	ra,40(sp)
    80002984:	7402                	ld	s0,32(sp)
    80002986:	64e2                	ld	s1,24(sp)
    80002988:	6145                	addi	sp,sp,48
    8000298a:	8082                	ret
      return -1;  // 内存分配失败
    8000298c:	54fd                	li	s1,-1
    8000298e:	bfcd                	j	80002980 <sys_sbrk+0x64>
      return -1;
    80002990:	54fd                	li	s1,-1
    80002992:	b7fd                	j	80002980 <sys_sbrk+0x64>
      return -1;
    80002994:	54fd                	li	s1,-1
    80002996:	b7ed                	j	80002980 <sys_sbrk+0x64>

0000000080002998 <sys_pause>:

// 让当前进程挂起指定时间
uint64
sys_pause(void)
{
    80002998:	7139                	addi	sp,sp,-64
    8000299a:	fc06                	sd	ra,56(sp)
    8000299c:	f822                	sd	s0,48(sp)
    8000299e:	f426                	sd	s1,40(sp)
    800029a0:	f04a                	sd	s2,32(sp)
    800029a2:	ec4e                	sd	s3,24(sp)
    800029a4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);  // 获取暂停的时长（以时钟滴答为单位）
    800029a6:	fcc40593          	addi	a1,s0,-52
    800029aa:	4501                	li	a0,0
    800029ac:	e35ff0ef          	jal	ra,800027e0 <argint>
  if(n < 0)  // 如果给定的时长为负，则设置为 0
    800029b0:	fcc42783          	lw	a5,-52(s0)
    800029b4:	0607c563          	bltz	a5,80002a1e <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);  // 获取时钟锁
    800029b8:	00013517          	auipc	a0,0x13
    800029bc:	fe050513          	addi	a0,a0,-32 # 80015998 <tickslock>
    800029c0:	9acfe0ef          	jal	ra,80000b6c <acquire>
  ticks0 = ticks;  // 记录当前的时钟滴答数
    800029c4:	00005917          	auipc	s2,0x5
    800029c8:	ea492903          	lw	s2,-348(s2) # 80007868 <ticks>
  while(ticks - ticks0 < n){  // 持续等待直到经过了指定的时间
    800029cc:	fcc42783          	lw	a5,-52(s0)
    800029d0:	cb8d                	beqz	a5,80002a02 <sys_pause+0x6a>
    if(killed(myproc())){  // 如果进程被杀死，退出等待
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);  // 进程进入休眠状态，等待时钟更新
    800029d2:	00013997          	auipc	s3,0x13
    800029d6:	fc698993          	addi	s3,s3,-58 # 80015998 <tickslock>
    800029da:	00005497          	auipc	s1,0x5
    800029de:	e8e48493          	addi	s1,s1,-370 # 80007868 <ticks>
    if(killed(myproc())){  // 如果进程被杀死，退出等待
    800029e2:	e23fe0ef          	jal	ra,80001804 <myproc>
    800029e6:	e68ff0ef          	jal	ra,8000204e <killed>
    800029ea:	ed0d                	bnez	a0,80002a24 <sys_pause+0x8c>
    sleep(&ticks, &tickslock);  // 进程进入休眠状态，等待时钟更新
    800029ec:	85ce                	mv	a1,s3
    800029ee:	8526                	mv	a0,s1
    800029f0:	c26ff0ef          	jal	ra,80001e16 <sleep>
  while(ticks - ticks0 < n){  // 持续等待直到经过了指定的时间
    800029f4:	409c                	lw	a5,0(s1)
    800029f6:	412787bb          	subw	a5,a5,s2
    800029fa:	fcc42703          	lw	a4,-52(s0)
    800029fe:	fee7e2e3          	bltu	a5,a4,800029e2 <sys_pause+0x4a>
  }
  release(&tickslock);  // 释放时钟锁
    80002a02:	00013517          	auipc	a0,0x13
    80002a06:	f9650513          	addi	a0,a0,-106 # 80015998 <tickslock>
    80002a0a:	9fafe0ef          	jal	ra,80000c04 <release>
  return 0;  // 返回
    80002a0e:	4501                	li	a0,0
}
    80002a10:	70e2                	ld	ra,56(sp)
    80002a12:	7442                	ld	s0,48(sp)
    80002a14:	74a2                	ld	s1,40(sp)
    80002a16:	7902                	ld	s2,32(sp)
    80002a18:	69e2                	ld	s3,24(sp)
    80002a1a:	6121                	addi	sp,sp,64
    80002a1c:	8082                	ret
    n = 0;
    80002a1e:	fc042623          	sw	zero,-52(s0)
    80002a22:	bf59                	j	800029b8 <sys_pause+0x20>
      release(&tickslock);
    80002a24:	00013517          	auipc	a0,0x13
    80002a28:	f7450513          	addi	a0,a0,-140 # 80015998 <tickslock>
    80002a2c:	9d8fe0ef          	jal	ra,80000c04 <release>
      return -1;
    80002a30:	557d                	li	a0,-1
    80002a32:	bff9                	j	80002a10 <sys_pause+0x78>

0000000080002a34 <sys_kill>:

// 终止指定进程
uint64
sys_kill(void)
{
    80002a34:	1101                	addi	sp,sp,-32
    80002a36:	ec06                	sd	ra,24(sp)
    80002a38:	e822                	sd	s0,16(sp)
    80002a3a:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);  // 获取进程 ID
    80002a3c:	fec40593          	addi	a1,s0,-20
    80002a40:	4501                	li	a0,0
    80002a42:	d9fff0ef          	jal	ra,800027e0 <argint>
  return kkill(pid);  // 调用内核的 kill 函数终止进程
    80002a46:	fec42503          	lw	a0,-20(s0)
    80002a4a:	d7aff0ef          	jal	ra,80001fc4 <kkill>
}
    80002a4e:	60e2                	ld	ra,24(sp)
    80002a50:	6442                	ld	s0,16(sp)
    80002a52:	6105                	addi	sp,sp,32
    80002a54:	8082                	ret

0000000080002a56 <sys_uptime>:

// 返回自系统启动以来经过的时钟滴答数
uint64
sys_uptime(void)
{
    80002a56:	1101                	addi	sp,sp,-32
    80002a58:	ec06                	sd	ra,24(sp)
    80002a5a:	e822                	sd	s0,16(sp)
    80002a5c:	e426                	sd	s1,8(sp)
    80002a5e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);  // 获取时钟锁
    80002a60:	00013517          	auipc	a0,0x13
    80002a64:	f3850513          	addi	a0,a0,-200 # 80015998 <tickslock>
    80002a68:	904fe0ef          	jal	ra,80000b6c <acquire>
  xticks = ticks;  // 获取当前的时钟滴答数
    80002a6c:	00005497          	auipc	s1,0x5
    80002a70:	dfc4a483          	lw	s1,-516(s1) # 80007868 <ticks>
  release(&tickslock);  // 释放时钟锁
    80002a74:	00013517          	auipc	a0,0x13
    80002a78:	f2450513          	addi	a0,a0,-220 # 80015998 <tickslock>
    80002a7c:	988fe0ef          	jal	ra,80000c04 <release>
  return xticks;  // 返回时钟滴答数
}
    80002a80:	02049513          	slli	a0,s1,0x20
    80002a84:	9101                	srli	a0,a0,0x20
    80002a86:	60e2                	ld	ra,24(sp)
    80002a88:	6442                	ld	s0,16(sp)
    80002a8a:	64a2                	ld	s1,8(sp)
    80002a8c:	6105                	addi	sp,sp,32
    80002a8e:	8082                	ret

0000000080002a90 <binit>:
} bcache;

// 初始化缓冲区缓存
void
binit(void)
{
    80002a90:	7179                	addi	sp,sp,-48
    80002a92:	f406                	sd	ra,40(sp)
    80002a94:	f022                	sd	s0,32(sp)
    80002a96:	ec26                	sd	s1,24(sp)
    80002a98:	e84a                	sd	s2,16(sp)
    80002a9a:	e44e                	sd	s3,8(sp)
    80002a9c:	e052                	sd	s4,0(sp)
    80002a9e:	1800                	addi	s0,sp,48
  struct buf *b;

  // 初始化缓冲区缓存的锁
  initlock(&bcache.lock, "bcache");
    80002aa0:	00005597          	auipc	a1,0x5
    80002aa4:	a0858593          	addi	a1,a1,-1528 # 800074a8 <syscalls+0xb8>
    80002aa8:	00013517          	auipc	a0,0x13
    80002aac:	f0850513          	addi	a0,a0,-248 # 800159b0 <bcache>
    80002ab0:	83cfe0ef          	jal	ra,80000aec <initlock>

  // 创建缓冲区链表
  bcache.head.prev = &bcache.head;
    80002ab4:	0001b797          	auipc	a5,0x1b
    80002ab8:	efc78793          	addi	a5,a5,-260 # 8001d9b0 <bcache+0x8000>
    80002abc:	0001b717          	auipc	a4,0x1b
    80002ac0:	15c70713          	addi	a4,a4,348 # 8001dc18 <bcache+0x8268>
    80002ac4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ac8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf + NBUF; b++){
    80002acc:	00013497          	auipc	s1,0x13
    80002ad0:	efc48493          	addi	s1,s1,-260 # 800159c8 <bcache+0x18>
    b->next = bcache.head.next;
    80002ad4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ad6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");  // 初始化缓冲区的睡眠锁
    80002ad8:	00005a17          	auipc	s4,0x5
    80002adc:	9d8a0a13          	addi	s4,s4,-1576 # 800074b0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002ae0:	2b893783          	ld	a5,696(s2)
    80002ae4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ae6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");  // 初始化缓冲区的睡眠锁
    80002aea:	85d2                	mv	a1,s4
    80002aec:	01048513          	addi	a0,s1,16
    80002af0:	2fe010ef          	jal	ra,80003dee <initsleeplock>
    bcache.head.next->prev = b;
    80002af4:	2b893783          	ld	a5,696(s2)
    80002af8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002afa:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf + NBUF; b++){
    80002afe:	45848493          	addi	s1,s1,1112
    80002b02:	fd349fe3          	bne	s1,s3,80002ae0 <binit+0x50>
  }
}
    80002b06:	70a2                	ld	ra,40(sp)
    80002b08:	7402                	ld	s0,32(sp)
    80002b0a:	64e2                	ld	s1,24(sp)
    80002b0c:	6942                	ld	s2,16(sp)
    80002b0e:	69a2                	ld	s3,8(sp)
    80002b10:	6a02                	ld	s4,0(sp)
    80002b12:	6145                	addi	sp,sp,48
    80002b14:	8082                	ret

0000000080002b16 <bread>:
}

// 获取指定磁盘块的缓冲区并返回，内容从磁盘读取
struct buf*
bread(uint dev, uint blockno)
{
    80002b16:	7179                	addi	sp,sp,-48
    80002b18:	f406                	sd	ra,40(sp)
    80002b1a:	f022                	sd	s0,32(sp)
    80002b1c:	ec26                	sd	s1,24(sp)
    80002b1e:	e84a                	sd	s2,16(sp)
    80002b20:	e44e                	sd	s3,8(sp)
    80002b22:	1800                	addi	s0,sp,48
    80002b24:	892a                	mv	s2,a0
    80002b26:	89ae                	mv	s3,a1
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002b28:	00013517          	auipc	a0,0x13
    80002b2c:	e8850513          	addi	a0,a0,-376 # 800159b0 <bcache>
    80002b30:	83cfe0ef          	jal	ra,80000b6c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002b34:	0001b497          	auipc	s1,0x1b
    80002b38:	1344b483          	ld	s1,308(s1) # 8001dc68 <bcache+0x82b8>
    80002b3c:	0001b797          	auipc	a5,0x1b
    80002b40:	0dc78793          	addi	a5,a5,220 # 8001dc18 <bcache+0x8268>
    80002b44:	02f48b63          	beq	s1,a5,80002b7a <bread+0x64>
    80002b48:	873e                	mv	a4,a5
    80002b4a:	a021                	j	80002b52 <bread+0x3c>
    80002b4c:	68a4                	ld	s1,80(s1)
    80002b4e:	02e48663          	beq	s1,a4,80002b7a <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002b52:	449c                	lw	a5,8(s1)
    80002b54:	ff279ce3          	bne	a5,s2,80002b4c <bread+0x36>
    80002b58:	44dc                	lw	a5,12(s1)
    80002b5a:	ff3799e3          	bne	a5,s3,80002b4c <bread+0x36>
      b->refcnt++;  // 增加引用计数
    80002b5e:	40bc                	lw	a5,64(s1)
    80002b60:	2785                	addiw	a5,a5,1
    80002b62:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002b64:	00013517          	auipc	a0,0x13
    80002b68:	e4c50513          	addi	a0,a0,-436 # 800159b0 <bcache>
    80002b6c:	898fe0ef          	jal	ra,80000c04 <release>
      acquiresleep(&b->lock);  // 获取缓冲区的睡眠锁
    80002b70:	01048513          	addi	a0,s1,16
    80002b74:	2b0010ef          	jal	ra,80003e24 <acquiresleep>
      return b;  // 返回缓冲区
    80002b78:	a889                	j	80002bca <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002b7a:	0001b497          	auipc	s1,0x1b
    80002b7e:	0e64b483          	ld	s1,230(s1) # 8001dc60 <bcache+0x82b0>
    80002b82:	0001b797          	auipc	a5,0x1b
    80002b86:	09678793          	addi	a5,a5,150 # 8001dc18 <bcache+0x8268>
    80002b8a:	00f48863          	beq	s1,a5,80002b9a <bread+0x84>
    80002b8e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002b90:	40bc                	lw	a5,64(s1)
    80002b92:	cb91                	beqz	a5,80002ba6 <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002b94:	64a4                	ld	s1,72(s1)
    80002b96:	fee49de3          	bne	s1,a4,80002b90 <bread+0x7a>
  panic("bget: no buffers");  // 如果没有找到可用的缓冲区，发生错误
    80002b9a:	00005517          	auipc	a0,0x5
    80002b9e:	91e50513          	addi	a0,a0,-1762 # 800074b8 <syscalls+0xc8>
    80002ba2:	be9fd0ef          	jal	ra,8000078a <panic>
      b->dev = dev;  // 设置设备号
    80002ba6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;  // 设置块号
    80002baa:	0134a623          	sw	s3,12(s1)
      b->valid = 0;  // 设置为无效
    80002bae:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;  // 引用计数设置为 1
    80002bb2:	4785                	li	a5,1
    80002bb4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002bb6:	00013517          	auipc	a0,0x13
    80002bba:	dfa50513          	addi	a0,a0,-518 # 800159b0 <bcache>
    80002bbe:	846fe0ef          	jal	ra,80000c04 <release>
      acquiresleep(&b->lock);  // 获取缓冲区的睡眠锁
    80002bc2:	01048513          	addi	a0,s1,16
    80002bc6:	25e010ef          	jal	ra,80003e24 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);  // 获取缓冲区
  if(!b->valid) {
    80002bca:	409c                	lw	a5,0(s1)
    80002bcc:	cb89                	beqz	a5,80002bde <bread+0xc8>
    virtio_disk_rw(b, 0);  // 从磁盘读取数据到缓冲区
    b->valid = 1;  // 设置缓冲区为有效
  }
  return b;  // 返回缓冲区
}
    80002bce:	8526                	mv	a0,s1
    80002bd0:	70a2                	ld	ra,40(sp)
    80002bd2:	7402                	ld	s0,32(sp)
    80002bd4:	64e2                	ld	s1,24(sp)
    80002bd6:	6942                	ld	s2,16(sp)
    80002bd8:	69a2                	ld	s3,8(sp)
    80002bda:	6145                	addi	sp,sp,48
    80002bdc:	8082                	ret
    virtio_disk_rw(b, 0);  // 从磁盘读取数据到缓冲区
    80002bde:	4581                	li	a1,0
    80002be0:	8526                	mv	a0,s1
    80002be2:	1bb020ef          	jal	ra,8000559c <virtio_disk_rw>
    b->valid = 1;  // 设置缓冲区为有效
    80002be6:	4785                	li	a5,1
    80002be8:	c09c                	sw	a5,0(s1)
  return b;  // 返回缓冲区
    80002bea:	b7d5                	j	80002bce <bread+0xb8>

0000000080002bec <bwrite>:

// 将缓冲区 b 的内容写入磁盘，必须先锁定缓冲区
void
bwrite(struct buf *b)
{
    80002bec:	1101                	addi	sp,sp,-32
    80002bee:	ec06                	sd	ra,24(sp)
    80002bf0:	e822                	sd	s0,16(sp)
    80002bf2:	e426                	sd	s1,8(sp)
    80002bf4:	1000                	addi	s0,sp,32
    80002bf6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002bf8:	0541                	addi	a0,a0,16
    80002bfa:	2a8010ef          	jal	ra,80003ea2 <holdingsleep>
    80002bfe:	c911                	beqz	a0,80002c12 <bwrite+0x26>
    panic("bwrite");  // 检查是否持有缓冲区的锁
  virtio_disk_rw(b, 1);  // 将缓冲区内容写入磁盘
    80002c00:	4585                	li	a1,1
    80002c02:	8526                	mv	a0,s1
    80002c04:	199020ef          	jal	ra,8000559c <virtio_disk_rw>
}
    80002c08:	60e2                	ld	ra,24(sp)
    80002c0a:	6442                	ld	s0,16(sp)
    80002c0c:	64a2                	ld	s1,8(sp)
    80002c0e:	6105                	addi	sp,sp,32
    80002c10:	8082                	ret
    panic("bwrite");  // 检查是否持有缓冲区的锁
    80002c12:	00005517          	auipc	a0,0x5
    80002c16:	8be50513          	addi	a0,a0,-1858 # 800074d0 <syscalls+0xe0>
    80002c1a:	b71fd0ef          	jal	ra,8000078a <panic>

0000000080002c1e <brelse>:

// 释放锁定的缓冲区，并将其移到最近使用的位置
void
brelse(struct buf *b)
{
    80002c1e:	1101                	addi	sp,sp,-32
    80002c20:	ec06                	sd	ra,24(sp)
    80002c22:	e822                	sd	s0,16(sp)
    80002c24:	e426                	sd	s1,8(sp)
    80002c26:	e04a                	sd	s2,0(sp)
    80002c28:	1000                	addi	s0,sp,32
    80002c2a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002c2c:	01050913          	addi	s2,a0,16
    80002c30:	854a                	mv	a0,s2
    80002c32:	270010ef          	jal	ra,80003ea2 <holdingsleep>
    80002c36:	c13d                	beqz	a0,80002c9c <brelse+0x7e>
    panic("brelse");  // 检查是否持有缓冲区的锁

  releasesleep(&b->lock);  // 释放缓冲区的睡眠锁
    80002c38:	854a                	mv	a0,s2
    80002c3a:	230010ef          	jal	ra,80003e6a <releasesleep>

  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002c3e:	00013517          	auipc	a0,0x13
    80002c42:	d7250513          	addi	a0,a0,-654 # 800159b0 <bcache>
    80002c46:	f27fd0ef          	jal	ra,80000b6c <acquire>
  b->refcnt--;  // 减少引用计数
    80002c4a:	40bc                	lw	a5,64(s1)
    80002c4c:	37fd                	addiw	a5,a5,-1
    80002c4e:	0007871b          	sext.w	a4,a5
    80002c52:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002c54:	eb05                	bnez	a4,80002c84 <brelse+0x66>
    // 如果没有其他进程在使用该缓冲区
    // 将缓冲区移到链表头部
    b->next->prev = b->prev;
    80002c56:	68bc                	ld	a5,80(s1)
    80002c58:	64b8                	ld	a4,72(s1)
    80002c5a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002c5c:	64bc                	ld	a5,72(s1)
    80002c5e:	68b8                	ld	a4,80(s1)
    80002c60:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002c62:	0001b797          	auipc	a5,0x1b
    80002c66:	d4e78793          	addi	a5,a5,-690 # 8001d9b0 <bcache+0x8000>
    80002c6a:	2b87b703          	ld	a4,696(a5)
    80002c6e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002c70:	0001b717          	auipc	a4,0x1b
    80002c74:	fa870713          	addi	a4,a4,-88 # 8001dc18 <bcache+0x8268>
    80002c78:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002c7a:	2b87b703          	ld	a4,696(a5)
    80002c7e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002c80:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002c84:	00013517          	auipc	a0,0x13
    80002c88:	d2c50513          	addi	a0,a0,-724 # 800159b0 <bcache>
    80002c8c:	f79fd0ef          	jal	ra,80000c04 <release>
}
    80002c90:	60e2                	ld	ra,24(sp)
    80002c92:	6442                	ld	s0,16(sp)
    80002c94:	64a2                	ld	s1,8(sp)
    80002c96:	6902                	ld	s2,0(sp)
    80002c98:	6105                	addi	sp,sp,32
    80002c9a:	8082                	ret
    panic("brelse");  // 检查是否持有缓冲区的锁
    80002c9c:	00005517          	auipc	a0,0x5
    80002ca0:	83c50513          	addi	a0,a0,-1988 # 800074d8 <syscalls+0xe8>
    80002ca4:	ae7fd0ef          	jal	ra,8000078a <panic>

0000000080002ca8 <bpin>:

// 增加缓冲区 b 的引用计数，用于防止缓冲区被释放
void
bpin(struct buf *b) {
    80002ca8:	1101                	addi	sp,sp,-32
    80002caa:	ec06                	sd	ra,24(sp)
    80002cac:	e822                	sd	s0,16(sp)
    80002cae:	e426                	sd	s1,8(sp)
    80002cb0:	1000                	addi	s0,sp,32
    80002cb2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002cb4:	00013517          	auipc	a0,0x13
    80002cb8:	cfc50513          	addi	a0,a0,-772 # 800159b0 <bcache>
    80002cbc:	eb1fd0ef          	jal	ra,80000b6c <acquire>
  b->refcnt++;  // 增加引用计数
    80002cc0:	40bc                	lw	a5,64(s1)
    80002cc2:	2785                	addiw	a5,a5,1
    80002cc4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002cc6:	00013517          	auipc	a0,0x13
    80002cca:	cea50513          	addi	a0,a0,-790 # 800159b0 <bcache>
    80002cce:	f37fd0ef          	jal	ra,80000c04 <release>
}
    80002cd2:	60e2                	ld	ra,24(sp)
    80002cd4:	6442                	ld	s0,16(sp)
    80002cd6:	64a2                	ld	s1,8(sp)
    80002cd8:	6105                	addi	sp,sp,32
    80002cda:	8082                	ret

0000000080002cdc <bunpin>:

// 减少缓冲区 b 的引用计数，用于缓冲区的释放
void
bunpin(struct buf *b) {
    80002cdc:	1101                	addi	sp,sp,-32
    80002cde:	ec06                	sd	ra,24(sp)
    80002ce0:	e822                	sd	s0,16(sp)
    80002ce2:	e426                	sd	s1,8(sp)
    80002ce4:	1000                	addi	s0,sp,32
    80002ce6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);  // 获取缓冲区缓存的锁
    80002ce8:	00013517          	auipc	a0,0x13
    80002cec:	cc850513          	addi	a0,a0,-824 # 800159b0 <bcache>
    80002cf0:	e7dfd0ef          	jal	ra,80000b6c <acquire>
  b->refcnt--;  // 减少引用计数
    80002cf4:	40bc                	lw	a5,64(s1)
    80002cf6:	37fd                	addiw	a5,a5,-1
    80002cf8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);  // 释放缓冲区缓存的锁
    80002cfa:	00013517          	auipc	a0,0x13
    80002cfe:	cb650513          	addi	a0,a0,-842 # 800159b0 <bcache>
    80002d02:	f03fd0ef          	jal	ra,80000c04 <release>
}
    80002d06:	60e2                	ld	ra,24(sp)
    80002d08:	6442                	ld	s0,16(sp)
    80002d0a:	64a2                	ld	s1,8(sp)
    80002d0c:	6105                	addi	sp,sp,32
    80002d0e:	8082                	ret

0000000080002d10 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002d10:	1101                	addi	sp,sp,-32
    80002d12:	ec06                	sd	ra,24(sp)
    80002d14:	e822                	sd	s0,16(sp)
    80002d16:	e426                	sd	s1,8(sp)
    80002d18:	e04a                	sd	s2,0(sp)
    80002d1a:	1000                	addi	s0,sp,32
    80002d1c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002d1e:	00d5d59b          	srliw	a1,a1,0xd
    80002d22:	0001b797          	auipc	a5,0x1b
    80002d26:	36a7a783          	lw	a5,874(a5) # 8001e08c <sb+0x1c>
    80002d2a:	9dbd                	addw	a1,a1,a5
    80002d2c:	debff0ef          	jal	ra,80002b16 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002d30:	0074f713          	andi	a4,s1,7
    80002d34:	4785                	li	a5,1
    80002d36:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80002d3a:	14ce                	slli	s1,s1,0x33
    80002d3c:	90d9                	srli	s1,s1,0x36
    80002d3e:	00950733          	add	a4,a0,s1
    80002d42:	05874703          	lbu	a4,88(a4)
    80002d46:	00e7f6b3          	and	a3,a5,a4
    80002d4a:	c29d                	beqz	a3,80002d70 <bfree+0x60>
    80002d4c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002d4e:	94aa                	add	s1,s1,a0
    80002d50:	fff7c793          	not	a5,a5
    80002d54:	8ff9                	and	a5,a5,a4
    80002d56:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80002d5a:	7d1000ef          	jal	ra,80003d2a <log_write>
  brelse(bp);
    80002d5e:	854a                	mv	a0,s2
    80002d60:	ebfff0ef          	jal	ra,80002c1e <brelse>
}
    80002d64:	60e2                	ld	ra,24(sp)
    80002d66:	6442                	ld	s0,16(sp)
    80002d68:	64a2                	ld	s1,8(sp)
    80002d6a:	6902                	ld	s2,0(sp)
    80002d6c:	6105                	addi	sp,sp,32
    80002d6e:	8082                	ret
    panic("freeing free block");
    80002d70:	00004517          	auipc	a0,0x4
    80002d74:	77050513          	addi	a0,a0,1904 # 800074e0 <syscalls+0xf0>
    80002d78:	a13fd0ef          	jal	ra,8000078a <panic>

0000000080002d7c <balloc>:
{
    80002d7c:	711d                	addi	sp,sp,-96
    80002d7e:	ec86                	sd	ra,88(sp)
    80002d80:	e8a2                	sd	s0,80(sp)
    80002d82:	e4a6                	sd	s1,72(sp)
    80002d84:	e0ca                	sd	s2,64(sp)
    80002d86:	fc4e                	sd	s3,56(sp)
    80002d88:	f852                	sd	s4,48(sp)
    80002d8a:	f456                	sd	s5,40(sp)
    80002d8c:	f05a                	sd	s6,32(sp)
    80002d8e:	ec5e                	sd	s7,24(sp)
    80002d90:	e862                	sd	s8,16(sp)
    80002d92:	e466                	sd	s9,8(sp)
    80002d94:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80002d96:	0001b797          	auipc	a5,0x1b
    80002d9a:	2de7a783          	lw	a5,734(a5) # 8001e074 <sb+0x4>
    80002d9e:	0e078163          	beqz	a5,80002e80 <balloc+0x104>
    80002da2:	8baa                	mv	s7,a0
    80002da4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80002da6:	0001bb17          	auipc	s6,0x1b
    80002daa:	2cab0b13          	addi	s6,s6,714 # 8001e070 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002dae:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80002db0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002db2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80002db4:	6c89                	lui	s9,0x2
    80002db6:	a0b5                	j	80002e22 <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    80002db8:	974a                	add	a4,a4,s2
    80002dba:	8fd5                	or	a5,a5,a3
    80002dbc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80002dc0:	854a                	mv	a0,s2
    80002dc2:	769000ef          	jal	ra,80003d2a <log_write>
        brelse(bp);
    80002dc6:	854a                	mv	a0,s2
    80002dc8:	e57ff0ef          	jal	ra,80002c1e <brelse>
  bp = bread(dev, bno);
    80002dcc:	85a6                	mv	a1,s1
    80002dce:	855e                	mv	a0,s7
    80002dd0:	d47ff0ef          	jal	ra,80002b16 <bread>
    80002dd4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80002dd6:	40000613          	li	a2,1024
    80002dda:	4581                	li	a1,0
    80002ddc:	05850513          	addi	a0,a0,88
    80002de0:	e61fd0ef          	jal	ra,80000c40 <memset>
  log_write(bp);
    80002de4:	854a                	mv	a0,s2
    80002de6:	745000ef          	jal	ra,80003d2a <log_write>
  brelse(bp);
    80002dea:	854a                	mv	a0,s2
    80002dec:	e33ff0ef          	jal	ra,80002c1e <brelse>
}
    80002df0:	8526                	mv	a0,s1
    80002df2:	60e6                	ld	ra,88(sp)
    80002df4:	6446                	ld	s0,80(sp)
    80002df6:	64a6                	ld	s1,72(sp)
    80002df8:	6906                	ld	s2,64(sp)
    80002dfa:	79e2                	ld	s3,56(sp)
    80002dfc:	7a42                	ld	s4,48(sp)
    80002dfe:	7aa2                	ld	s5,40(sp)
    80002e00:	7b02                	ld	s6,32(sp)
    80002e02:	6be2                	ld	s7,24(sp)
    80002e04:	6c42                	ld	s8,16(sp)
    80002e06:	6ca2                	ld	s9,8(sp)
    80002e08:	6125                	addi	sp,sp,96
    80002e0a:	8082                	ret
    brelse(bp);
    80002e0c:	854a                	mv	a0,s2
    80002e0e:	e11ff0ef          	jal	ra,80002c1e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80002e12:	015c87bb          	addw	a5,s9,s5
    80002e16:	00078a9b          	sext.w	s5,a5
    80002e1a:	004b2703          	lw	a4,4(s6)
    80002e1e:	06eaf163          	bgeu	s5,a4,80002e80 <balloc+0x104>
    bp = bread(dev, BBLOCK(b, sb));
    80002e22:	41fad79b          	sraiw	a5,s5,0x1f
    80002e26:	0137d79b          	srliw	a5,a5,0x13
    80002e2a:	015787bb          	addw	a5,a5,s5
    80002e2e:	40d7d79b          	sraiw	a5,a5,0xd
    80002e32:	01cb2583          	lw	a1,28(s6)
    80002e36:	9dbd                	addw	a1,a1,a5
    80002e38:	855e                	mv	a0,s7
    80002e3a:	cddff0ef          	jal	ra,80002b16 <bread>
    80002e3e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002e40:	004b2503          	lw	a0,4(s6)
    80002e44:	000a849b          	sext.w	s1,s5
    80002e48:	8662                	mv	a2,s8
    80002e4a:	fca4f1e3          	bgeu	s1,a0,80002e0c <balloc+0x90>
      m = 1 << (bi % 8);
    80002e4e:	41f6579b          	sraiw	a5,a2,0x1f
    80002e52:	01d7d69b          	srliw	a3,a5,0x1d
    80002e56:	00c6873b          	addw	a4,a3,a2
    80002e5a:	00777793          	andi	a5,a4,7
    80002e5e:	9f95                	subw	a5,a5,a3
    80002e60:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80002e64:	4037571b          	sraiw	a4,a4,0x3
    80002e68:	00e906b3          	add	a3,s2,a4
    80002e6c:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    80002e70:	00d7f5b3          	and	a1,a5,a3
    80002e74:	d1b1                	beqz	a1,80002db8 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002e76:	2605                	addiw	a2,a2,1
    80002e78:	2485                	addiw	s1,s1,1
    80002e7a:	fd4618e3          	bne	a2,s4,80002e4a <balloc+0xce>
    80002e7e:	b779                	j	80002e0c <balloc+0x90>
  printf("balloc: out of blocks\n");
    80002e80:	00004517          	auipc	a0,0x4
    80002e84:	67850513          	addi	a0,a0,1656 # 800074f8 <syscalls+0x108>
    80002e88:	e3cfd0ef          	jal	ra,800004c4 <printf>
  return 0;
    80002e8c:	4481                	li	s1,0
    80002e8e:	b78d                	j	80002df0 <balloc+0x74>

0000000080002e90 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80002e90:	7179                	addi	sp,sp,-48
    80002e92:	f406                	sd	ra,40(sp)
    80002e94:	f022                	sd	s0,32(sp)
    80002e96:	ec26                	sd	s1,24(sp)
    80002e98:	e84a                	sd	s2,16(sp)
    80002e9a:	e44e                	sd	s3,8(sp)
    80002e9c:	e052                	sd	s4,0(sp)
    80002e9e:	1800                	addi	s0,sp,48
    80002ea0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80002ea2:	47ad                	li	a5,11
    80002ea4:	02b7e563          	bltu	a5,a1,80002ece <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    80002ea8:	02059493          	slli	s1,a1,0x20
    80002eac:	9081                	srli	s1,s1,0x20
    80002eae:	048a                	slli	s1,s1,0x2
    80002eb0:	94aa                	add	s1,s1,a0
    80002eb2:	0504a903          	lw	s2,80(s1)
    80002eb6:	06091663          	bnez	s2,80002f22 <bmap+0x92>
      addr = balloc(ip->dev);
    80002eba:	4108                	lw	a0,0(a0)
    80002ebc:	ec1ff0ef          	jal	ra,80002d7c <balloc>
    80002ec0:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002ec4:	04090f63          	beqz	s2,80002f22 <bmap+0x92>
        return 0;
      ip->addrs[bn] = addr;
    80002ec8:	0524a823          	sw	s2,80(s1)
    80002ecc:	a899                	j	80002f22 <bmap+0x92>
    }
    return addr;
  }
  bn -= NDIRECT;
    80002ece:	ff45849b          	addiw	s1,a1,-12
    80002ed2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80002ed6:	0ff00793          	li	a5,255
    80002eda:	06e7eb63          	bltu	a5,a4,80002f50 <bmap+0xc0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80002ede:	08052903          	lw	s2,128(a0)
    80002ee2:	00091b63          	bnez	s2,80002ef8 <bmap+0x68>
      addr = balloc(ip->dev);
    80002ee6:	4108                	lw	a0,0(a0)
    80002ee8:	e95ff0ef          	jal	ra,80002d7c <balloc>
    80002eec:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002ef0:	02090963          	beqz	s2,80002f22 <bmap+0x92>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80002ef4:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80002ef8:	85ca                	mv	a1,s2
    80002efa:	0009a503          	lw	a0,0(s3)
    80002efe:	c19ff0ef          	jal	ra,80002b16 <bread>
    80002f02:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80002f04:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80002f08:	02049593          	slli	a1,s1,0x20
    80002f0c:	9181                	srli	a1,a1,0x20
    80002f0e:	058a                	slli	a1,a1,0x2
    80002f10:	00b784b3          	add	s1,a5,a1
    80002f14:	0004a903          	lw	s2,0(s1)
    80002f18:	00090e63          	beqz	s2,80002f34 <bmap+0xa4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80002f1c:	8552                	mv	a0,s4
    80002f1e:	d01ff0ef          	jal	ra,80002c1e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80002f22:	854a                	mv	a0,s2
    80002f24:	70a2                	ld	ra,40(sp)
    80002f26:	7402                	ld	s0,32(sp)
    80002f28:	64e2                	ld	s1,24(sp)
    80002f2a:	6942                	ld	s2,16(sp)
    80002f2c:	69a2                	ld	s3,8(sp)
    80002f2e:	6a02                	ld	s4,0(sp)
    80002f30:	6145                	addi	sp,sp,48
    80002f32:	8082                	ret
      addr = balloc(ip->dev);
    80002f34:	0009a503          	lw	a0,0(s3)
    80002f38:	e45ff0ef          	jal	ra,80002d7c <balloc>
    80002f3c:	0005091b          	sext.w	s2,a0
      if(addr){
    80002f40:	fc090ee3          	beqz	s2,80002f1c <bmap+0x8c>
        a[bn] = addr;
    80002f44:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80002f48:	8552                	mv	a0,s4
    80002f4a:	5e1000ef          	jal	ra,80003d2a <log_write>
    80002f4e:	b7f9                	j	80002f1c <bmap+0x8c>
  panic("bmap: out of range");
    80002f50:	00004517          	auipc	a0,0x4
    80002f54:	5c050513          	addi	a0,a0,1472 # 80007510 <syscalls+0x120>
    80002f58:	833fd0ef          	jal	ra,8000078a <panic>

0000000080002f5c <iget>:
{
    80002f5c:	7179                	addi	sp,sp,-48
    80002f5e:	f406                	sd	ra,40(sp)
    80002f60:	f022                	sd	s0,32(sp)
    80002f62:	ec26                	sd	s1,24(sp)
    80002f64:	e84a                	sd	s2,16(sp)
    80002f66:	e44e                	sd	s3,8(sp)
    80002f68:	e052                	sd	s4,0(sp)
    80002f6a:	1800                	addi	s0,sp,48
    80002f6c:	89aa                	mv	s3,a0
    80002f6e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80002f70:	0001b517          	auipc	a0,0x1b
    80002f74:	12050513          	addi	a0,a0,288 # 8001e090 <itable>
    80002f78:	bf5fd0ef          	jal	ra,80000b6c <acquire>
  empty = 0;
    80002f7c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80002f7e:	0001b497          	auipc	s1,0x1b
    80002f82:	12a48493          	addi	s1,s1,298 # 8001e0a8 <itable+0x18>
    80002f86:	0001d697          	auipc	a3,0x1d
    80002f8a:	bb268693          	addi	a3,a3,-1102 # 8001fb38 <log>
    80002f8e:	a039                	j	80002f9c <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80002f90:	02090963          	beqz	s2,80002fc2 <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80002f94:	08848493          	addi	s1,s1,136
    80002f98:	02d48863          	beq	s1,a3,80002fc8 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80002f9c:	449c                	lw	a5,8(s1)
    80002f9e:	fef059e3          	blez	a5,80002f90 <iget+0x34>
    80002fa2:	4098                	lw	a4,0(s1)
    80002fa4:	ff3716e3          	bne	a4,s3,80002f90 <iget+0x34>
    80002fa8:	40d8                	lw	a4,4(s1)
    80002faa:	ff4713e3          	bne	a4,s4,80002f90 <iget+0x34>
      ip->ref++;
    80002fae:	2785                	addiw	a5,a5,1
    80002fb0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80002fb2:	0001b517          	auipc	a0,0x1b
    80002fb6:	0de50513          	addi	a0,a0,222 # 8001e090 <itable>
    80002fba:	c4bfd0ef          	jal	ra,80000c04 <release>
      return ip;
    80002fbe:	8926                	mv	s2,s1
    80002fc0:	a02d                	j	80002fea <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80002fc2:	fbe9                	bnez	a5,80002f94 <iget+0x38>
    80002fc4:	8926                	mv	s2,s1
    80002fc6:	b7f9                	j	80002f94 <iget+0x38>
  if(empty == 0)
    80002fc8:	02090a63          	beqz	s2,80002ffc <iget+0xa0>
  ip->dev = dev;
    80002fcc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80002fd0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80002fd4:	4785                	li	a5,1
    80002fd6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80002fda:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80002fde:	0001b517          	auipc	a0,0x1b
    80002fe2:	0b250513          	addi	a0,a0,178 # 8001e090 <itable>
    80002fe6:	c1ffd0ef          	jal	ra,80000c04 <release>
}
    80002fea:	854a                	mv	a0,s2
    80002fec:	70a2                	ld	ra,40(sp)
    80002fee:	7402                	ld	s0,32(sp)
    80002ff0:	64e2                	ld	s1,24(sp)
    80002ff2:	6942                	ld	s2,16(sp)
    80002ff4:	69a2                	ld	s3,8(sp)
    80002ff6:	6a02                	ld	s4,0(sp)
    80002ff8:	6145                	addi	sp,sp,48
    80002ffa:	8082                	ret
    panic("iget: no inodes");
    80002ffc:	00004517          	auipc	a0,0x4
    80003000:	52c50513          	addi	a0,a0,1324 # 80007528 <syscalls+0x138>
    80003004:	f86fd0ef          	jal	ra,8000078a <panic>

0000000080003008 <iinit>:
{
    80003008:	7179                	addi	sp,sp,-48
    8000300a:	f406                	sd	ra,40(sp)
    8000300c:	f022                	sd	s0,32(sp)
    8000300e:	ec26                	sd	s1,24(sp)
    80003010:	e84a                	sd	s2,16(sp)
    80003012:	e44e                	sd	s3,8(sp)
    80003014:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003016:	00004597          	auipc	a1,0x4
    8000301a:	52258593          	addi	a1,a1,1314 # 80007538 <syscalls+0x148>
    8000301e:	0001b517          	auipc	a0,0x1b
    80003022:	07250513          	addi	a0,a0,114 # 8001e090 <itable>
    80003026:	ac7fd0ef          	jal	ra,80000aec <initlock>
  for(i = 0; i < NINODE; i++) {
    8000302a:	0001b497          	auipc	s1,0x1b
    8000302e:	08e48493          	addi	s1,s1,142 # 8001e0b8 <itable+0x28>
    80003032:	0001d997          	auipc	s3,0x1d
    80003036:	b1698993          	addi	s3,s3,-1258 # 8001fb48 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000303a:	00004917          	auipc	s2,0x4
    8000303e:	50690913          	addi	s2,s2,1286 # 80007540 <syscalls+0x150>
    80003042:	85ca                	mv	a1,s2
    80003044:	8526                	mv	a0,s1
    80003046:	5a9000ef          	jal	ra,80003dee <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000304a:	08848493          	addi	s1,s1,136
    8000304e:	ff349ae3          	bne	s1,s3,80003042 <iinit+0x3a>
}
    80003052:	70a2                	ld	ra,40(sp)
    80003054:	7402                	ld	s0,32(sp)
    80003056:	64e2                	ld	s1,24(sp)
    80003058:	6942                	ld	s2,16(sp)
    8000305a:	69a2                	ld	s3,8(sp)
    8000305c:	6145                	addi	sp,sp,48
    8000305e:	8082                	ret

0000000080003060 <ialloc>:
{
    80003060:	715d                	addi	sp,sp,-80
    80003062:	e486                	sd	ra,72(sp)
    80003064:	e0a2                	sd	s0,64(sp)
    80003066:	fc26                	sd	s1,56(sp)
    80003068:	f84a                	sd	s2,48(sp)
    8000306a:	f44e                	sd	s3,40(sp)
    8000306c:	f052                	sd	s4,32(sp)
    8000306e:	ec56                	sd	s5,24(sp)
    80003070:	e85a                	sd	s6,16(sp)
    80003072:	e45e                	sd	s7,8(sp)
    80003074:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003076:	0001b717          	auipc	a4,0x1b
    8000307a:	00672703          	lw	a4,6(a4) # 8001e07c <sb+0xc>
    8000307e:	4785                	li	a5,1
    80003080:	04e7f663          	bgeu	a5,a4,800030cc <ialloc+0x6c>
    80003084:	8aaa                	mv	s5,a0
    80003086:	8bae                	mv	s7,a1
    80003088:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000308a:	0001ba17          	auipc	s4,0x1b
    8000308e:	fe6a0a13          	addi	s4,s4,-26 # 8001e070 <sb>
    80003092:	00048b1b          	sext.w	s6,s1
    80003096:	0044d793          	srli	a5,s1,0x4
    8000309a:	018a2583          	lw	a1,24(s4)
    8000309e:	9dbd                	addw	a1,a1,a5
    800030a0:	8556                	mv	a0,s5
    800030a2:	a75ff0ef          	jal	ra,80002b16 <bread>
    800030a6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800030a8:	05850993          	addi	s3,a0,88
    800030ac:	00f4f793          	andi	a5,s1,15
    800030b0:	079a                	slli	a5,a5,0x6
    800030b2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800030b4:	00099783          	lh	a5,0(s3)
    800030b8:	cf85                	beqz	a5,800030f0 <ialloc+0x90>
    brelse(bp);
    800030ba:	b65ff0ef          	jal	ra,80002c1e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800030be:	0485                	addi	s1,s1,1
    800030c0:	00ca2703          	lw	a4,12(s4)
    800030c4:	0004879b          	sext.w	a5,s1
    800030c8:	fce7e5e3          	bltu	a5,a4,80003092 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800030cc:	00004517          	auipc	a0,0x4
    800030d0:	47c50513          	addi	a0,a0,1148 # 80007548 <syscalls+0x158>
    800030d4:	bf0fd0ef          	jal	ra,800004c4 <printf>
  return 0;
    800030d8:	4501                	li	a0,0
}
    800030da:	60a6                	ld	ra,72(sp)
    800030dc:	6406                	ld	s0,64(sp)
    800030de:	74e2                	ld	s1,56(sp)
    800030e0:	7942                	ld	s2,48(sp)
    800030e2:	79a2                	ld	s3,40(sp)
    800030e4:	7a02                	ld	s4,32(sp)
    800030e6:	6ae2                	ld	s5,24(sp)
    800030e8:	6b42                	ld	s6,16(sp)
    800030ea:	6ba2                	ld	s7,8(sp)
    800030ec:	6161                	addi	sp,sp,80
    800030ee:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800030f0:	04000613          	li	a2,64
    800030f4:	4581                	li	a1,0
    800030f6:	854e                	mv	a0,s3
    800030f8:	b49fd0ef          	jal	ra,80000c40 <memset>
      dip->type = type;
    800030fc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003100:	854a                	mv	a0,s2
    80003102:	429000ef          	jal	ra,80003d2a <log_write>
      brelse(bp);
    80003106:	854a                	mv	a0,s2
    80003108:	b17ff0ef          	jal	ra,80002c1e <brelse>
      return iget(dev, inum);
    8000310c:	85da                	mv	a1,s6
    8000310e:	8556                	mv	a0,s5
    80003110:	e4dff0ef          	jal	ra,80002f5c <iget>
    80003114:	b7d9                	j	800030da <ialloc+0x7a>

0000000080003116 <iupdate>:
{
    80003116:	1101                	addi	sp,sp,-32
    80003118:	ec06                	sd	ra,24(sp)
    8000311a:	e822                	sd	s0,16(sp)
    8000311c:	e426                	sd	s1,8(sp)
    8000311e:	e04a                	sd	s2,0(sp)
    80003120:	1000                	addi	s0,sp,32
    80003122:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003124:	415c                	lw	a5,4(a0)
    80003126:	0047d79b          	srliw	a5,a5,0x4
    8000312a:	0001b597          	auipc	a1,0x1b
    8000312e:	f5e5a583          	lw	a1,-162(a1) # 8001e088 <sb+0x18>
    80003132:	9dbd                	addw	a1,a1,a5
    80003134:	4108                	lw	a0,0(a0)
    80003136:	9e1ff0ef          	jal	ra,80002b16 <bread>
    8000313a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000313c:	05850793          	addi	a5,a0,88
    80003140:	40c8                	lw	a0,4(s1)
    80003142:	893d                	andi	a0,a0,15
    80003144:	051a                	slli	a0,a0,0x6
    80003146:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003148:	04449703          	lh	a4,68(s1)
    8000314c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003150:	04649703          	lh	a4,70(s1)
    80003154:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003158:	04849703          	lh	a4,72(s1)
    8000315c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003160:	04a49703          	lh	a4,74(s1)
    80003164:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003168:	44f8                	lw	a4,76(s1)
    8000316a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000316c:	03400613          	li	a2,52
    80003170:	05048593          	addi	a1,s1,80
    80003174:	0531                	addi	a0,a0,12
    80003176:	b27fd0ef          	jal	ra,80000c9c <memmove>
  log_write(bp);
    8000317a:	854a                	mv	a0,s2
    8000317c:	3af000ef          	jal	ra,80003d2a <log_write>
  brelse(bp);
    80003180:	854a                	mv	a0,s2
    80003182:	a9dff0ef          	jal	ra,80002c1e <brelse>
}
    80003186:	60e2                	ld	ra,24(sp)
    80003188:	6442                	ld	s0,16(sp)
    8000318a:	64a2                	ld	s1,8(sp)
    8000318c:	6902                	ld	s2,0(sp)
    8000318e:	6105                	addi	sp,sp,32
    80003190:	8082                	ret

0000000080003192 <idup>:
{
    80003192:	1101                	addi	sp,sp,-32
    80003194:	ec06                	sd	ra,24(sp)
    80003196:	e822                	sd	s0,16(sp)
    80003198:	e426                	sd	s1,8(sp)
    8000319a:	1000                	addi	s0,sp,32
    8000319c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000319e:	0001b517          	auipc	a0,0x1b
    800031a2:	ef250513          	addi	a0,a0,-270 # 8001e090 <itable>
    800031a6:	9c7fd0ef          	jal	ra,80000b6c <acquire>
  ip->ref++;
    800031aa:	449c                	lw	a5,8(s1)
    800031ac:	2785                	addiw	a5,a5,1
    800031ae:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800031b0:	0001b517          	auipc	a0,0x1b
    800031b4:	ee050513          	addi	a0,a0,-288 # 8001e090 <itable>
    800031b8:	a4dfd0ef          	jal	ra,80000c04 <release>
}
    800031bc:	8526                	mv	a0,s1
    800031be:	60e2                	ld	ra,24(sp)
    800031c0:	6442                	ld	s0,16(sp)
    800031c2:	64a2                	ld	s1,8(sp)
    800031c4:	6105                	addi	sp,sp,32
    800031c6:	8082                	ret

00000000800031c8 <ilock>:
{
    800031c8:	1101                	addi	sp,sp,-32
    800031ca:	ec06                	sd	ra,24(sp)
    800031cc:	e822                	sd	s0,16(sp)
    800031ce:	e426                	sd	s1,8(sp)
    800031d0:	e04a                	sd	s2,0(sp)
    800031d2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800031d4:	c105                	beqz	a0,800031f4 <ilock+0x2c>
    800031d6:	84aa                	mv	s1,a0
    800031d8:	451c                	lw	a5,8(a0)
    800031da:	00f05d63          	blez	a5,800031f4 <ilock+0x2c>
  acquiresleep(&ip->lock);
    800031de:	0541                	addi	a0,a0,16
    800031e0:	445000ef          	jal	ra,80003e24 <acquiresleep>
  if(ip->valid == 0){
    800031e4:	40bc                	lw	a5,64(s1)
    800031e6:	cf89                	beqz	a5,80003200 <ilock+0x38>
}
    800031e8:	60e2                	ld	ra,24(sp)
    800031ea:	6442                	ld	s0,16(sp)
    800031ec:	64a2                	ld	s1,8(sp)
    800031ee:	6902                	ld	s2,0(sp)
    800031f0:	6105                	addi	sp,sp,32
    800031f2:	8082                	ret
    panic("ilock");
    800031f4:	00004517          	auipc	a0,0x4
    800031f8:	36c50513          	addi	a0,a0,876 # 80007560 <syscalls+0x170>
    800031fc:	d8efd0ef          	jal	ra,8000078a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003200:	40dc                	lw	a5,4(s1)
    80003202:	0047d79b          	srliw	a5,a5,0x4
    80003206:	0001b597          	auipc	a1,0x1b
    8000320a:	e825a583          	lw	a1,-382(a1) # 8001e088 <sb+0x18>
    8000320e:	9dbd                	addw	a1,a1,a5
    80003210:	4088                	lw	a0,0(s1)
    80003212:	905ff0ef          	jal	ra,80002b16 <bread>
    80003216:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003218:	05850593          	addi	a1,a0,88
    8000321c:	40dc                	lw	a5,4(s1)
    8000321e:	8bbd                	andi	a5,a5,15
    80003220:	079a                	slli	a5,a5,0x6
    80003222:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003224:	00059783          	lh	a5,0(a1)
    80003228:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000322c:	00259783          	lh	a5,2(a1)
    80003230:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003234:	00459783          	lh	a5,4(a1)
    80003238:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000323c:	00659783          	lh	a5,6(a1)
    80003240:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003244:	459c                	lw	a5,8(a1)
    80003246:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003248:	03400613          	li	a2,52
    8000324c:	05b1                	addi	a1,a1,12
    8000324e:	05048513          	addi	a0,s1,80
    80003252:	a4bfd0ef          	jal	ra,80000c9c <memmove>
    brelse(bp);
    80003256:	854a                	mv	a0,s2
    80003258:	9c7ff0ef          	jal	ra,80002c1e <brelse>
    ip->valid = 1;
    8000325c:	4785                	li	a5,1
    8000325e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003260:	04449783          	lh	a5,68(s1)
    80003264:	f3d1                	bnez	a5,800031e8 <ilock+0x20>
      panic("ilock: no type");
    80003266:	00004517          	auipc	a0,0x4
    8000326a:	30250513          	addi	a0,a0,770 # 80007568 <syscalls+0x178>
    8000326e:	d1cfd0ef          	jal	ra,8000078a <panic>

0000000080003272 <iunlock>:
{
    80003272:	1101                	addi	sp,sp,-32
    80003274:	ec06                	sd	ra,24(sp)
    80003276:	e822                	sd	s0,16(sp)
    80003278:	e426                	sd	s1,8(sp)
    8000327a:	e04a                	sd	s2,0(sp)
    8000327c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000327e:	c505                	beqz	a0,800032a6 <iunlock+0x34>
    80003280:	84aa                	mv	s1,a0
    80003282:	01050913          	addi	s2,a0,16
    80003286:	854a                	mv	a0,s2
    80003288:	41b000ef          	jal	ra,80003ea2 <holdingsleep>
    8000328c:	cd09                	beqz	a0,800032a6 <iunlock+0x34>
    8000328e:	449c                	lw	a5,8(s1)
    80003290:	00f05b63          	blez	a5,800032a6 <iunlock+0x34>
  releasesleep(&ip->lock);
    80003294:	854a                	mv	a0,s2
    80003296:	3d5000ef          	jal	ra,80003e6a <releasesleep>
}
    8000329a:	60e2                	ld	ra,24(sp)
    8000329c:	6442                	ld	s0,16(sp)
    8000329e:	64a2                	ld	s1,8(sp)
    800032a0:	6902                	ld	s2,0(sp)
    800032a2:	6105                	addi	sp,sp,32
    800032a4:	8082                	ret
    panic("iunlock");
    800032a6:	00004517          	auipc	a0,0x4
    800032aa:	2d250513          	addi	a0,a0,722 # 80007578 <syscalls+0x188>
    800032ae:	cdcfd0ef          	jal	ra,8000078a <panic>

00000000800032b2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800032b2:	7179                	addi	sp,sp,-48
    800032b4:	f406                	sd	ra,40(sp)
    800032b6:	f022                	sd	s0,32(sp)
    800032b8:	ec26                	sd	s1,24(sp)
    800032ba:	e84a                	sd	s2,16(sp)
    800032bc:	e44e                	sd	s3,8(sp)
    800032be:	e052                	sd	s4,0(sp)
    800032c0:	1800                	addi	s0,sp,48
    800032c2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800032c4:	05050493          	addi	s1,a0,80
    800032c8:	08050913          	addi	s2,a0,128
    800032cc:	a021                	j	800032d4 <itrunc+0x22>
    800032ce:	0491                	addi	s1,s1,4
    800032d0:	01248b63          	beq	s1,s2,800032e6 <itrunc+0x34>
    if(ip->addrs[i]){
    800032d4:	408c                	lw	a1,0(s1)
    800032d6:	dde5                	beqz	a1,800032ce <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800032d8:	0009a503          	lw	a0,0(s3)
    800032dc:	a35ff0ef          	jal	ra,80002d10 <bfree>
      ip->addrs[i] = 0;
    800032e0:	0004a023          	sw	zero,0(s1)
    800032e4:	b7ed                	j	800032ce <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800032e6:	0809a583          	lw	a1,128(s3)
    800032ea:	ed91                	bnez	a1,80003306 <itrunc+0x54>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800032ec:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800032f0:	854e                	mv	a0,s3
    800032f2:	e25ff0ef          	jal	ra,80003116 <iupdate>
}
    800032f6:	70a2                	ld	ra,40(sp)
    800032f8:	7402                	ld	s0,32(sp)
    800032fa:	64e2                	ld	s1,24(sp)
    800032fc:	6942                	ld	s2,16(sp)
    800032fe:	69a2                	ld	s3,8(sp)
    80003300:	6a02                	ld	s4,0(sp)
    80003302:	6145                	addi	sp,sp,48
    80003304:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003306:	0009a503          	lw	a0,0(s3)
    8000330a:	80dff0ef          	jal	ra,80002b16 <bread>
    8000330e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003310:	05850493          	addi	s1,a0,88
    80003314:	45850913          	addi	s2,a0,1112
    80003318:	a021                	j	80003320 <itrunc+0x6e>
    8000331a:	0491                	addi	s1,s1,4
    8000331c:	01248963          	beq	s1,s2,8000332e <itrunc+0x7c>
      if(a[j])
    80003320:	408c                	lw	a1,0(s1)
    80003322:	dde5                	beqz	a1,8000331a <itrunc+0x68>
        bfree(ip->dev, a[j]);
    80003324:	0009a503          	lw	a0,0(s3)
    80003328:	9e9ff0ef          	jal	ra,80002d10 <bfree>
    8000332c:	b7fd                	j	8000331a <itrunc+0x68>
    brelse(bp);
    8000332e:	8552                	mv	a0,s4
    80003330:	8efff0ef          	jal	ra,80002c1e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003334:	0809a583          	lw	a1,128(s3)
    80003338:	0009a503          	lw	a0,0(s3)
    8000333c:	9d5ff0ef          	jal	ra,80002d10 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003340:	0809a023          	sw	zero,128(s3)
    80003344:	b765                	j	800032ec <itrunc+0x3a>

0000000080003346 <iput>:
{
    80003346:	1101                	addi	sp,sp,-32
    80003348:	ec06                	sd	ra,24(sp)
    8000334a:	e822                	sd	s0,16(sp)
    8000334c:	e426                	sd	s1,8(sp)
    8000334e:	e04a                	sd	s2,0(sp)
    80003350:	1000                	addi	s0,sp,32
    80003352:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003354:	0001b517          	auipc	a0,0x1b
    80003358:	d3c50513          	addi	a0,a0,-708 # 8001e090 <itable>
    8000335c:	811fd0ef          	jal	ra,80000b6c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003360:	4498                	lw	a4,8(s1)
    80003362:	4785                	li	a5,1
    80003364:	02f70163          	beq	a4,a5,80003386 <iput+0x40>
  ip->ref--;
    80003368:	449c                	lw	a5,8(s1)
    8000336a:	37fd                	addiw	a5,a5,-1
    8000336c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000336e:	0001b517          	auipc	a0,0x1b
    80003372:	d2250513          	addi	a0,a0,-734 # 8001e090 <itable>
    80003376:	88ffd0ef          	jal	ra,80000c04 <release>
}
    8000337a:	60e2                	ld	ra,24(sp)
    8000337c:	6442                	ld	s0,16(sp)
    8000337e:	64a2                	ld	s1,8(sp)
    80003380:	6902                	ld	s2,0(sp)
    80003382:	6105                	addi	sp,sp,32
    80003384:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003386:	40bc                	lw	a5,64(s1)
    80003388:	d3e5                	beqz	a5,80003368 <iput+0x22>
    8000338a:	04a49783          	lh	a5,74(s1)
    8000338e:	ffe9                	bnez	a5,80003368 <iput+0x22>
    acquiresleep(&ip->lock);
    80003390:	01048913          	addi	s2,s1,16
    80003394:	854a                	mv	a0,s2
    80003396:	28f000ef          	jal	ra,80003e24 <acquiresleep>
    release(&itable.lock);
    8000339a:	0001b517          	auipc	a0,0x1b
    8000339e:	cf650513          	addi	a0,a0,-778 # 8001e090 <itable>
    800033a2:	863fd0ef          	jal	ra,80000c04 <release>
    itrunc(ip);
    800033a6:	8526                	mv	a0,s1
    800033a8:	f0bff0ef          	jal	ra,800032b2 <itrunc>
    ip->type = 0;
    800033ac:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800033b0:	8526                	mv	a0,s1
    800033b2:	d65ff0ef          	jal	ra,80003116 <iupdate>
    ip->valid = 0;
    800033b6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800033ba:	854a                	mv	a0,s2
    800033bc:	2af000ef          	jal	ra,80003e6a <releasesleep>
    acquire(&itable.lock);
    800033c0:	0001b517          	auipc	a0,0x1b
    800033c4:	cd050513          	addi	a0,a0,-816 # 8001e090 <itable>
    800033c8:	fa4fd0ef          	jal	ra,80000b6c <acquire>
    800033cc:	bf71                	j	80003368 <iput+0x22>

00000000800033ce <iunlockput>:
{
    800033ce:	1101                	addi	sp,sp,-32
    800033d0:	ec06                	sd	ra,24(sp)
    800033d2:	e822                	sd	s0,16(sp)
    800033d4:	e426                	sd	s1,8(sp)
    800033d6:	1000                	addi	s0,sp,32
    800033d8:	84aa                	mv	s1,a0
  iunlock(ip);
    800033da:	e99ff0ef          	jal	ra,80003272 <iunlock>
  iput(ip);
    800033de:	8526                	mv	a0,s1
    800033e0:	f67ff0ef          	jal	ra,80003346 <iput>
}
    800033e4:	60e2                	ld	ra,24(sp)
    800033e6:	6442                	ld	s0,16(sp)
    800033e8:	64a2                	ld	s1,8(sp)
    800033ea:	6105                	addi	sp,sp,32
    800033ec:	8082                	ret

00000000800033ee <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800033ee:	0001b717          	auipc	a4,0x1b
    800033f2:	c8e72703          	lw	a4,-882(a4) # 8001e07c <sb+0xc>
    800033f6:	4785                	li	a5,1
    800033f8:	0ae7ff63          	bgeu	a5,a4,800034b6 <ireclaim+0xc8>
{
    800033fc:	7139                	addi	sp,sp,-64
    800033fe:	fc06                	sd	ra,56(sp)
    80003400:	f822                	sd	s0,48(sp)
    80003402:	f426                	sd	s1,40(sp)
    80003404:	f04a                	sd	s2,32(sp)
    80003406:	ec4e                	sd	s3,24(sp)
    80003408:	e852                	sd	s4,16(sp)
    8000340a:	e456                	sd	s5,8(sp)
    8000340c:	e05a                	sd	s6,0(sp)
    8000340e:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003410:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003412:	00050a1b          	sext.w	s4,a0
    80003416:	0001ba97          	auipc	s5,0x1b
    8000341a:	c5aa8a93          	addi	s5,s5,-934 # 8001e070 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    8000341e:	00004b17          	auipc	s6,0x4
    80003422:	162b0b13          	addi	s6,s6,354 # 80007580 <syscalls+0x190>
    80003426:	a099                	j	8000346c <ireclaim+0x7e>
    80003428:	85ce                	mv	a1,s3
    8000342a:	855a                	mv	a0,s6
    8000342c:	898fd0ef          	jal	ra,800004c4 <printf>
      ip = iget(dev, inum);
    80003430:	85ce                	mv	a1,s3
    80003432:	8552                	mv	a0,s4
    80003434:	b29ff0ef          	jal	ra,80002f5c <iget>
    80003438:	89aa                	mv	s3,a0
    brelse(bp);
    8000343a:	854a                	mv	a0,s2
    8000343c:	fe2ff0ef          	jal	ra,80002c1e <brelse>
    if (ip) {
    80003440:	00098f63          	beqz	s3,8000345e <ireclaim+0x70>
      begin_op();
    80003444:	762000ef          	jal	ra,80003ba6 <begin_op>
      ilock(ip);
    80003448:	854e                	mv	a0,s3
    8000344a:	d7fff0ef          	jal	ra,800031c8 <ilock>
      iunlock(ip);
    8000344e:	854e                	mv	a0,s3
    80003450:	e23ff0ef          	jal	ra,80003272 <iunlock>
      iput(ip);
    80003454:	854e                	mv	a0,s3
    80003456:	ef1ff0ef          	jal	ra,80003346 <iput>
      end_op();
    8000345a:	7bc000ef          	jal	ra,80003c16 <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    8000345e:	0485                	addi	s1,s1,1
    80003460:	00caa703          	lw	a4,12(s5)
    80003464:	0004879b          	sext.w	a5,s1
    80003468:	02e7fd63          	bgeu	a5,a4,800034a2 <ireclaim+0xb4>
    8000346c:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003470:	0044d793          	srli	a5,s1,0x4
    80003474:	018aa583          	lw	a1,24(s5)
    80003478:	9dbd                	addw	a1,a1,a5
    8000347a:	8552                	mv	a0,s4
    8000347c:	e9aff0ef          	jal	ra,80002b16 <bread>
    80003480:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    80003482:	05850793          	addi	a5,a0,88
    80003486:	00f9f713          	andi	a4,s3,15
    8000348a:	071a                	slli	a4,a4,0x6
    8000348c:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    8000348e:	00079703          	lh	a4,0(a5)
    80003492:	c701                	beqz	a4,8000349a <ireclaim+0xac>
    80003494:	00679783          	lh	a5,6(a5)
    80003498:	dbc1                	beqz	a5,80003428 <ireclaim+0x3a>
    brelse(bp);
    8000349a:	854a                	mv	a0,s2
    8000349c:	f82ff0ef          	jal	ra,80002c1e <brelse>
    if (ip) {
    800034a0:	bf7d                	j	8000345e <ireclaim+0x70>
}
    800034a2:	70e2                	ld	ra,56(sp)
    800034a4:	7442                	ld	s0,48(sp)
    800034a6:	74a2                	ld	s1,40(sp)
    800034a8:	7902                	ld	s2,32(sp)
    800034aa:	69e2                	ld	s3,24(sp)
    800034ac:	6a42                	ld	s4,16(sp)
    800034ae:	6aa2                	ld	s5,8(sp)
    800034b0:	6b02                	ld	s6,0(sp)
    800034b2:	6121                	addi	sp,sp,64
    800034b4:	8082                	ret
    800034b6:	8082                	ret

00000000800034b8 <fsinit>:
fsinit(int dev) {
    800034b8:	7179                	addi	sp,sp,-48
    800034ba:	f406                	sd	ra,40(sp)
    800034bc:	f022                	sd	s0,32(sp)
    800034be:	ec26                	sd	s1,24(sp)
    800034c0:	e84a                	sd	s2,16(sp)
    800034c2:	e44e                	sd	s3,8(sp)
    800034c4:	1800                	addi	s0,sp,48
    800034c6:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    800034c8:	4585                	li	a1,1
    800034ca:	e4cff0ef          	jal	ra,80002b16 <bread>
    800034ce:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034d0:	0001b997          	auipc	s3,0x1b
    800034d4:	ba098993          	addi	s3,s3,-1120 # 8001e070 <sb>
    800034d8:	02000613          	li	a2,32
    800034dc:	05850593          	addi	a1,a0,88
    800034e0:	854e                	mv	a0,s3
    800034e2:	fbafd0ef          	jal	ra,80000c9c <memmove>
  brelse(bp);
    800034e6:	854a                	mv	a0,s2
    800034e8:	f36ff0ef          	jal	ra,80002c1e <brelse>
  if(sb.magic != FSMAGIC)
    800034ec:	0009a703          	lw	a4,0(s3)
    800034f0:	102037b7          	lui	a5,0x10203
    800034f4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034f8:	02f71363          	bne	a4,a5,8000351e <fsinit+0x66>
  initlog(dev, &sb);
    800034fc:	0001b597          	auipc	a1,0x1b
    80003500:	b7458593          	addi	a1,a1,-1164 # 8001e070 <sb>
    80003504:	8526                	mv	a0,s1
    80003506:	616000ef          	jal	ra,80003b1c <initlog>
  ireclaim(dev);
    8000350a:	8526                	mv	a0,s1
    8000350c:	ee3ff0ef          	jal	ra,800033ee <ireclaim>
}
    80003510:	70a2                	ld	ra,40(sp)
    80003512:	7402                	ld	s0,32(sp)
    80003514:	64e2                	ld	s1,24(sp)
    80003516:	6942                	ld	s2,16(sp)
    80003518:	69a2                	ld	s3,8(sp)
    8000351a:	6145                	addi	sp,sp,48
    8000351c:	8082                	ret
    panic("invalid file system");
    8000351e:	00004517          	auipc	a0,0x4
    80003522:	08250513          	addi	a0,a0,130 # 800075a0 <syscalls+0x1b0>
    80003526:	a64fd0ef          	jal	ra,8000078a <panic>

000000008000352a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000352a:	1141                	addi	sp,sp,-16
    8000352c:	e422                	sd	s0,8(sp)
    8000352e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003530:	411c                	lw	a5,0(a0)
    80003532:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003534:	415c                	lw	a5,4(a0)
    80003536:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003538:	04451783          	lh	a5,68(a0)
    8000353c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003540:	04a51783          	lh	a5,74(a0)
    80003544:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003548:	04c56783          	lwu	a5,76(a0)
    8000354c:	e99c                	sd	a5,16(a1)
}
    8000354e:	6422                	ld	s0,8(sp)
    80003550:	0141                	addi	sp,sp,16
    80003552:	8082                	ret

0000000080003554 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003554:	457c                	lw	a5,76(a0)
    80003556:	0cd7ef63          	bltu	a5,a3,80003634 <readi+0xe0>
{
    8000355a:	7159                	addi	sp,sp,-112
    8000355c:	f486                	sd	ra,104(sp)
    8000355e:	f0a2                	sd	s0,96(sp)
    80003560:	eca6                	sd	s1,88(sp)
    80003562:	e8ca                	sd	s2,80(sp)
    80003564:	e4ce                	sd	s3,72(sp)
    80003566:	e0d2                	sd	s4,64(sp)
    80003568:	fc56                	sd	s5,56(sp)
    8000356a:	f85a                	sd	s6,48(sp)
    8000356c:	f45e                	sd	s7,40(sp)
    8000356e:	f062                	sd	s8,32(sp)
    80003570:	ec66                	sd	s9,24(sp)
    80003572:	e86a                	sd	s10,16(sp)
    80003574:	e46e                	sd	s11,8(sp)
    80003576:	1880                	addi	s0,sp,112
    80003578:	8b2a                	mv	s6,a0
    8000357a:	8bae                	mv	s7,a1
    8000357c:	8a32                	mv	s4,a2
    8000357e:	84b6                	mv	s1,a3
    80003580:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003582:	9f35                	addw	a4,a4,a3
    return 0;
    80003584:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003586:	08d76663          	bltu	a4,a3,80003612 <readi+0xbe>
  if(off + n > ip->size)
    8000358a:	00e7f463          	bgeu	a5,a4,80003592 <readi+0x3e>
    n = ip->size - off;
    8000358e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003592:	080a8f63          	beqz	s5,80003630 <readi+0xdc>
    80003596:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003598:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000359c:	5c7d                	li	s8,-1
    8000359e:	a80d                	j	800035d0 <readi+0x7c>
    800035a0:	020d1d93          	slli	s11,s10,0x20
    800035a4:	020ddd93          	srli	s11,s11,0x20
    800035a8:	05890793          	addi	a5,s2,88
    800035ac:	86ee                	mv	a3,s11
    800035ae:	963e                	add	a2,a2,a5
    800035b0:	85d2                	mv	a1,s4
    800035b2:	855e                	mv	a0,s7
    800035b4:	bbffe0ef          	jal	ra,80002172 <either_copyout>
    800035b8:	05850763          	beq	a0,s8,80003606 <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800035bc:	854a                	mv	a0,s2
    800035be:	e60ff0ef          	jal	ra,80002c1e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800035c2:	013d09bb          	addw	s3,s10,s3
    800035c6:	009d04bb          	addw	s1,s10,s1
    800035ca:	9a6e                	add	s4,s4,s11
    800035cc:	0559f163          	bgeu	s3,s5,8000360e <readi+0xba>
    uint addr = bmap(ip, off/BSIZE);
    800035d0:	00a4d59b          	srliw	a1,s1,0xa
    800035d4:	855a                	mv	a0,s6
    800035d6:	8bbff0ef          	jal	ra,80002e90 <bmap>
    800035da:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800035de:	c985                	beqz	a1,8000360e <readi+0xba>
    bp = bread(ip->dev, addr);
    800035e0:	000b2503          	lw	a0,0(s6)
    800035e4:	d32ff0ef          	jal	ra,80002b16 <bread>
    800035e8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800035ea:	3ff4f613          	andi	a2,s1,1023
    800035ee:	40cc87bb          	subw	a5,s9,a2
    800035f2:	413a873b          	subw	a4,s5,s3
    800035f6:	8d3e                	mv	s10,a5
    800035f8:	2781                	sext.w	a5,a5
    800035fa:	0007069b          	sext.w	a3,a4
    800035fe:	faf6f1e3          	bgeu	a3,a5,800035a0 <readi+0x4c>
    80003602:	8d3a                	mv	s10,a4
    80003604:	bf71                	j	800035a0 <readi+0x4c>
      brelse(bp);
    80003606:	854a                	mv	a0,s2
    80003608:	e16ff0ef          	jal	ra,80002c1e <brelse>
      tot = -1;
    8000360c:	59fd                	li	s3,-1
  }
  return tot;
    8000360e:	0009851b          	sext.w	a0,s3
}
    80003612:	70a6                	ld	ra,104(sp)
    80003614:	7406                	ld	s0,96(sp)
    80003616:	64e6                	ld	s1,88(sp)
    80003618:	6946                	ld	s2,80(sp)
    8000361a:	69a6                	ld	s3,72(sp)
    8000361c:	6a06                	ld	s4,64(sp)
    8000361e:	7ae2                	ld	s5,56(sp)
    80003620:	7b42                	ld	s6,48(sp)
    80003622:	7ba2                	ld	s7,40(sp)
    80003624:	7c02                	ld	s8,32(sp)
    80003626:	6ce2                	ld	s9,24(sp)
    80003628:	6d42                	ld	s10,16(sp)
    8000362a:	6da2                	ld	s11,8(sp)
    8000362c:	6165                	addi	sp,sp,112
    8000362e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003630:	89d6                	mv	s3,s5
    80003632:	bff1                	j	8000360e <readi+0xba>
    return 0;
    80003634:	4501                	li	a0,0
}
    80003636:	8082                	ret

0000000080003638 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003638:	457c                	lw	a5,76(a0)
    8000363a:	0ed7ea63          	bltu	a5,a3,8000372e <writei+0xf6>
{
    8000363e:	7159                	addi	sp,sp,-112
    80003640:	f486                	sd	ra,104(sp)
    80003642:	f0a2                	sd	s0,96(sp)
    80003644:	eca6                	sd	s1,88(sp)
    80003646:	e8ca                	sd	s2,80(sp)
    80003648:	e4ce                	sd	s3,72(sp)
    8000364a:	e0d2                	sd	s4,64(sp)
    8000364c:	fc56                	sd	s5,56(sp)
    8000364e:	f85a                	sd	s6,48(sp)
    80003650:	f45e                	sd	s7,40(sp)
    80003652:	f062                	sd	s8,32(sp)
    80003654:	ec66                	sd	s9,24(sp)
    80003656:	e86a                	sd	s10,16(sp)
    80003658:	e46e                	sd	s11,8(sp)
    8000365a:	1880                	addi	s0,sp,112
    8000365c:	8aaa                	mv	s5,a0
    8000365e:	8bae                	mv	s7,a1
    80003660:	8a32                	mv	s4,a2
    80003662:	8936                	mv	s2,a3
    80003664:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003666:	00e687bb          	addw	a5,a3,a4
    8000366a:	0cd7e463          	bltu	a5,a3,80003732 <writei+0xfa>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000366e:	00043737          	lui	a4,0x43
    80003672:	0cf76263          	bltu	a4,a5,80003736 <writei+0xfe>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003676:	0a0b0a63          	beqz	s6,8000372a <writei+0xf2>
    8000367a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000367c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003680:	5c7d                	li	s8,-1
    80003682:	a825                	j	800036ba <writei+0x82>
    80003684:	020d1d93          	slli	s11,s10,0x20
    80003688:	020ddd93          	srli	s11,s11,0x20
    8000368c:	05848793          	addi	a5,s1,88
    80003690:	86ee                	mv	a3,s11
    80003692:	8652                	mv	a2,s4
    80003694:	85de                	mv	a1,s7
    80003696:	953e                	add	a0,a0,a5
    80003698:	b25fe0ef          	jal	ra,800021bc <either_copyin>
    8000369c:	05850a63          	beq	a0,s8,800036f0 <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    800036a0:	8526                	mv	a0,s1
    800036a2:	688000ef          	jal	ra,80003d2a <log_write>
    brelse(bp);
    800036a6:	8526                	mv	a0,s1
    800036a8:	d76ff0ef          	jal	ra,80002c1e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800036ac:	013d09bb          	addw	s3,s10,s3
    800036b0:	012d093b          	addw	s2,s10,s2
    800036b4:	9a6e                	add	s4,s4,s11
    800036b6:	0569f063          	bgeu	s3,s6,800036f6 <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    800036ba:	00a9559b          	srliw	a1,s2,0xa
    800036be:	8556                	mv	a0,s5
    800036c0:	fd0ff0ef          	jal	ra,80002e90 <bmap>
    800036c4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800036c8:	c59d                	beqz	a1,800036f6 <writei+0xbe>
    bp = bread(ip->dev, addr);
    800036ca:	000aa503          	lw	a0,0(s5)
    800036ce:	c48ff0ef          	jal	ra,80002b16 <bread>
    800036d2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800036d4:	3ff97513          	andi	a0,s2,1023
    800036d8:	40ac87bb          	subw	a5,s9,a0
    800036dc:	413b073b          	subw	a4,s6,s3
    800036e0:	8d3e                	mv	s10,a5
    800036e2:	2781                	sext.w	a5,a5
    800036e4:	0007069b          	sext.w	a3,a4
    800036e8:	f8f6fee3          	bgeu	a3,a5,80003684 <writei+0x4c>
    800036ec:	8d3a                	mv	s10,a4
    800036ee:	bf59                	j	80003684 <writei+0x4c>
      brelse(bp);
    800036f0:	8526                	mv	a0,s1
    800036f2:	d2cff0ef          	jal	ra,80002c1e <brelse>
  }

  if(off > ip->size)
    800036f6:	04caa783          	lw	a5,76(s5)
    800036fa:	0127f463          	bgeu	a5,s2,80003702 <writei+0xca>
    ip->size = off;
    800036fe:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003702:	8556                	mv	a0,s5
    80003704:	a13ff0ef          	jal	ra,80003116 <iupdate>

  return tot;
    80003708:	0009851b          	sext.w	a0,s3
}
    8000370c:	70a6                	ld	ra,104(sp)
    8000370e:	7406                	ld	s0,96(sp)
    80003710:	64e6                	ld	s1,88(sp)
    80003712:	6946                	ld	s2,80(sp)
    80003714:	69a6                	ld	s3,72(sp)
    80003716:	6a06                	ld	s4,64(sp)
    80003718:	7ae2                	ld	s5,56(sp)
    8000371a:	7b42                	ld	s6,48(sp)
    8000371c:	7ba2                	ld	s7,40(sp)
    8000371e:	7c02                	ld	s8,32(sp)
    80003720:	6ce2                	ld	s9,24(sp)
    80003722:	6d42                	ld	s10,16(sp)
    80003724:	6da2                	ld	s11,8(sp)
    80003726:	6165                	addi	sp,sp,112
    80003728:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000372a:	89da                	mv	s3,s6
    8000372c:	bfd9                	j	80003702 <writei+0xca>
    return -1;
    8000372e:	557d                	li	a0,-1
}
    80003730:	8082                	ret
    return -1;
    80003732:	557d                	li	a0,-1
    80003734:	bfe1                	j	8000370c <writei+0xd4>
    return -1;
    80003736:	557d                	li	a0,-1
    80003738:	bfd1                	j	8000370c <writei+0xd4>

000000008000373a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000373a:	1141                	addi	sp,sp,-16
    8000373c:	e406                	sd	ra,8(sp)
    8000373e:	e022                	sd	s0,0(sp)
    80003740:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003742:	4639                	li	a2,14
    80003744:	dc8fd0ef          	jal	ra,80000d0c <strncmp>
}
    80003748:	60a2                	ld	ra,8(sp)
    8000374a:	6402                	ld	s0,0(sp)
    8000374c:	0141                	addi	sp,sp,16
    8000374e:	8082                	ret

0000000080003750 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003750:	7139                	addi	sp,sp,-64
    80003752:	fc06                	sd	ra,56(sp)
    80003754:	f822                	sd	s0,48(sp)
    80003756:	f426                	sd	s1,40(sp)
    80003758:	f04a                	sd	s2,32(sp)
    8000375a:	ec4e                	sd	s3,24(sp)
    8000375c:	e852                	sd	s4,16(sp)
    8000375e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003760:	04451703          	lh	a4,68(a0)
    80003764:	4785                	li	a5,1
    80003766:	00f71a63          	bne	a4,a5,8000377a <dirlookup+0x2a>
    8000376a:	892a                	mv	s2,a0
    8000376c:	89ae                	mv	s3,a1
    8000376e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003770:	457c                	lw	a5,76(a0)
    80003772:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003774:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003776:	e39d                	bnez	a5,8000379c <dirlookup+0x4c>
    80003778:	a095                	j	800037dc <dirlookup+0x8c>
    panic("dirlookup not DIR");
    8000377a:	00004517          	auipc	a0,0x4
    8000377e:	e3e50513          	addi	a0,a0,-450 # 800075b8 <syscalls+0x1c8>
    80003782:	808fd0ef          	jal	ra,8000078a <panic>
      panic("dirlookup read");
    80003786:	00004517          	auipc	a0,0x4
    8000378a:	e4a50513          	addi	a0,a0,-438 # 800075d0 <syscalls+0x1e0>
    8000378e:	ffdfc0ef          	jal	ra,8000078a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003792:	24c1                	addiw	s1,s1,16
    80003794:	04c92783          	lw	a5,76(s2)
    80003798:	04f4f163          	bgeu	s1,a5,800037da <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000379c:	4741                	li	a4,16
    8000379e:	86a6                	mv	a3,s1
    800037a0:	fc040613          	addi	a2,s0,-64
    800037a4:	4581                	li	a1,0
    800037a6:	854a                	mv	a0,s2
    800037a8:	dadff0ef          	jal	ra,80003554 <readi>
    800037ac:	47c1                	li	a5,16
    800037ae:	fcf51ce3          	bne	a0,a5,80003786 <dirlookup+0x36>
    if(de.inum == 0)
    800037b2:	fc045783          	lhu	a5,-64(s0)
    800037b6:	dff1                	beqz	a5,80003792 <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    800037b8:	fc240593          	addi	a1,s0,-62
    800037bc:	854e                	mv	a0,s3
    800037be:	f7dff0ef          	jal	ra,8000373a <namecmp>
    800037c2:	f961                	bnez	a0,80003792 <dirlookup+0x42>
      if(poff)
    800037c4:	000a0463          	beqz	s4,800037cc <dirlookup+0x7c>
        *poff = off;
    800037c8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800037cc:	fc045583          	lhu	a1,-64(s0)
    800037d0:	00092503          	lw	a0,0(s2)
    800037d4:	f88ff0ef          	jal	ra,80002f5c <iget>
    800037d8:	a011                	j	800037dc <dirlookup+0x8c>
  return 0;
    800037da:	4501                	li	a0,0
}
    800037dc:	70e2                	ld	ra,56(sp)
    800037de:	7442                	ld	s0,48(sp)
    800037e0:	74a2                	ld	s1,40(sp)
    800037e2:	7902                	ld	s2,32(sp)
    800037e4:	69e2                	ld	s3,24(sp)
    800037e6:	6a42                	ld	s4,16(sp)
    800037e8:	6121                	addi	sp,sp,64
    800037ea:	8082                	ret

00000000800037ec <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800037ec:	711d                	addi	sp,sp,-96
    800037ee:	ec86                	sd	ra,88(sp)
    800037f0:	e8a2                	sd	s0,80(sp)
    800037f2:	e4a6                	sd	s1,72(sp)
    800037f4:	e0ca                	sd	s2,64(sp)
    800037f6:	fc4e                	sd	s3,56(sp)
    800037f8:	f852                	sd	s4,48(sp)
    800037fa:	f456                	sd	s5,40(sp)
    800037fc:	f05a                	sd	s6,32(sp)
    800037fe:	ec5e                	sd	s7,24(sp)
    80003800:	e862                	sd	s8,16(sp)
    80003802:	e466                	sd	s9,8(sp)
    80003804:	1080                	addi	s0,sp,96
    80003806:	84aa                	mv	s1,a0
    80003808:	8aae                	mv	s5,a1
    8000380a:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000380c:	00054703          	lbu	a4,0(a0)
    80003810:	02f00793          	li	a5,47
    80003814:	00f70f63          	beq	a4,a5,80003832 <namex+0x46>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003818:	fedfd0ef          	jal	ra,80001804 <myproc>
    8000381c:	15053503          	ld	a0,336(a0)
    80003820:	973ff0ef          	jal	ra,80003192 <idup>
    80003824:	89aa                	mv	s3,a0
  while(*path == '/')
    80003826:	02f00913          	li	s2,47
  len = path - s;
    8000382a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000382c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000382e:	4b85                	li	s7,1
    80003830:	a861                	j	800038c8 <namex+0xdc>
    ip = iget(ROOTDEV, ROOTINO);
    80003832:	4585                	li	a1,1
    80003834:	4505                	li	a0,1
    80003836:	f26ff0ef          	jal	ra,80002f5c <iget>
    8000383a:	89aa                	mv	s3,a0
    8000383c:	b7ed                	j	80003826 <namex+0x3a>
      iunlockput(ip);
    8000383e:	854e                	mv	a0,s3
    80003840:	b8fff0ef          	jal	ra,800033ce <iunlockput>
      return 0;
    80003844:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003846:	854e                	mv	a0,s3
    80003848:	60e6                	ld	ra,88(sp)
    8000384a:	6446                	ld	s0,80(sp)
    8000384c:	64a6                	ld	s1,72(sp)
    8000384e:	6906                	ld	s2,64(sp)
    80003850:	79e2                	ld	s3,56(sp)
    80003852:	7a42                	ld	s4,48(sp)
    80003854:	7aa2                	ld	s5,40(sp)
    80003856:	7b02                	ld	s6,32(sp)
    80003858:	6be2                	ld	s7,24(sp)
    8000385a:	6c42                	ld	s8,16(sp)
    8000385c:	6ca2                	ld	s9,8(sp)
    8000385e:	6125                	addi	sp,sp,96
    80003860:	8082                	ret
      iunlock(ip);
    80003862:	854e                	mv	a0,s3
    80003864:	a0fff0ef          	jal	ra,80003272 <iunlock>
      return ip;
    80003868:	bff9                	j	80003846 <namex+0x5a>
      iunlockput(ip);
    8000386a:	854e                	mv	a0,s3
    8000386c:	b63ff0ef          	jal	ra,800033ce <iunlockput>
      return 0;
    80003870:	89e6                	mv	s3,s9
    80003872:	bfd1                	j	80003846 <namex+0x5a>
  len = path - s;
    80003874:	40b48633          	sub	a2,s1,a1
    80003878:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000387c:	079c5c63          	bge	s8,s9,800038f4 <namex+0x108>
    memmove(name, s, DIRSIZ);
    80003880:	4639                	li	a2,14
    80003882:	8552                	mv	a0,s4
    80003884:	c18fd0ef          	jal	ra,80000c9c <memmove>
  while(*path == '/')
    80003888:	0004c783          	lbu	a5,0(s1)
    8000388c:	01279763          	bne	a5,s2,8000389a <namex+0xae>
    path++;
    80003890:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003892:	0004c783          	lbu	a5,0(s1)
    80003896:	ff278de3          	beq	a5,s2,80003890 <namex+0xa4>
    ilock(ip);
    8000389a:	854e                	mv	a0,s3
    8000389c:	92dff0ef          	jal	ra,800031c8 <ilock>
    if(ip->type != T_DIR){
    800038a0:	04499783          	lh	a5,68(s3)
    800038a4:	f9779de3          	bne	a5,s7,8000383e <namex+0x52>
    if(nameiparent && *path == '\0'){
    800038a8:	000a8563          	beqz	s5,800038b2 <namex+0xc6>
    800038ac:	0004c783          	lbu	a5,0(s1)
    800038b0:	dbcd                	beqz	a5,80003862 <namex+0x76>
    if((next = dirlookup(ip, name, 0)) == 0){
    800038b2:	865a                	mv	a2,s6
    800038b4:	85d2                	mv	a1,s4
    800038b6:	854e                	mv	a0,s3
    800038b8:	e99ff0ef          	jal	ra,80003750 <dirlookup>
    800038bc:	8caa                	mv	s9,a0
    800038be:	d555                	beqz	a0,8000386a <namex+0x7e>
    iunlockput(ip);
    800038c0:	854e                	mv	a0,s3
    800038c2:	b0dff0ef          	jal	ra,800033ce <iunlockput>
    ip = next;
    800038c6:	89e6                	mv	s3,s9
  while(*path == '/')
    800038c8:	0004c783          	lbu	a5,0(s1)
    800038cc:	05279363          	bne	a5,s2,80003912 <namex+0x126>
    path++;
    800038d0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800038d2:	0004c783          	lbu	a5,0(s1)
    800038d6:	ff278de3          	beq	a5,s2,800038d0 <namex+0xe4>
  if(*path == 0)
    800038da:	c78d                	beqz	a5,80003904 <namex+0x118>
    path++;
    800038dc:	85a6                	mv	a1,s1
  len = path - s;
    800038de:	8cda                	mv	s9,s6
    800038e0:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800038e2:	01278963          	beq	a5,s2,800038f4 <namex+0x108>
    800038e6:	d7d9                	beqz	a5,80003874 <namex+0x88>
    path++;
    800038e8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800038ea:	0004c783          	lbu	a5,0(s1)
    800038ee:	ff279ce3          	bne	a5,s2,800038e6 <namex+0xfa>
    800038f2:	b749                	j	80003874 <namex+0x88>
    memmove(name, s, len);
    800038f4:	2601                	sext.w	a2,a2
    800038f6:	8552                	mv	a0,s4
    800038f8:	ba4fd0ef          	jal	ra,80000c9c <memmove>
    name[len] = 0;
    800038fc:	9cd2                	add	s9,s9,s4
    800038fe:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003902:	b759                	j	80003888 <namex+0x9c>
  if(nameiparent){
    80003904:	f40a81e3          	beqz	s5,80003846 <namex+0x5a>
    iput(ip);
    80003908:	854e                	mv	a0,s3
    8000390a:	a3dff0ef          	jal	ra,80003346 <iput>
    return 0;
    8000390e:	4981                	li	s3,0
    80003910:	bf1d                	j	80003846 <namex+0x5a>
  if(*path == 0)
    80003912:	dbed                	beqz	a5,80003904 <namex+0x118>
  while(*path != '/' && *path != 0)
    80003914:	0004c783          	lbu	a5,0(s1)
    80003918:	85a6                	mv	a1,s1
    8000391a:	b7f1                	j	800038e6 <namex+0xfa>

000000008000391c <dirlink>:
{
    8000391c:	7139                	addi	sp,sp,-64
    8000391e:	fc06                	sd	ra,56(sp)
    80003920:	f822                	sd	s0,48(sp)
    80003922:	f426                	sd	s1,40(sp)
    80003924:	f04a                	sd	s2,32(sp)
    80003926:	ec4e                	sd	s3,24(sp)
    80003928:	e852                	sd	s4,16(sp)
    8000392a:	0080                	addi	s0,sp,64
    8000392c:	892a                	mv	s2,a0
    8000392e:	8a2e                	mv	s4,a1
    80003930:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003932:	4601                	li	a2,0
    80003934:	e1dff0ef          	jal	ra,80003750 <dirlookup>
    80003938:	e52d                	bnez	a0,800039a2 <dirlink+0x86>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000393a:	04c92483          	lw	s1,76(s2)
    8000393e:	c48d                	beqz	s1,80003968 <dirlink+0x4c>
    80003940:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003942:	4741                	li	a4,16
    80003944:	86a6                	mv	a3,s1
    80003946:	fc040613          	addi	a2,s0,-64
    8000394a:	4581                	li	a1,0
    8000394c:	854a                	mv	a0,s2
    8000394e:	c07ff0ef          	jal	ra,80003554 <readi>
    80003952:	47c1                	li	a5,16
    80003954:	04f51b63          	bne	a0,a5,800039aa <dirlink+0x8e>
    if(de.inum == 0)
    80003958:	fc045783          	lhu	a5,-64(s0)
    8000395c:	c791                	beqz	a5,80003968 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000395e:	24c1                	addiw	s1,s1,16
    80003960:	04c92783          	lw	a5,76(s2)
    80003964:	fcf4efe3          	bltu	s1,a5,80003942 <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80003968:	4639                	li	a2,14
    8000396a:	85d2                	mv	a1,s4
    8000396c:	fc240513          	addi	a0,s0,-62
    80003970:	bd8fd0ef          	jal	ra,80000d48 <strncpy>
  de.inum = inum;
    80003974:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003978:	4741                	li	a4,16
    8000397a:	86a6                	mv	a3,s1
    8000397c:	fc040613          	addi	a2,s0,-64
    80003980:	4581                	li	a1,0
    80003982:	854a                	mv	a0,s2
    80003984:	cb5ff0ef          	jal	ra,80003638 <writei>
    80003988:	1541                	addi	a0,a0,-16
    8000398a:	00a03533          	snez	a0,a0
    8000398e:	40a00533          	neg	a0,a0
}
    80003992:	70e2                	ld	ra,56(sp)
    80003994:	7442                	ld	s0,48(sp)
    80003996:	74a2                	ld	s1,40(sp)
    80003998:	7902                	ld	s2,32(sp)
    8000399a:	69e2                	ld	s3,24(sp)
    8000399c:	6a42                	ld	s4,16(sp)
    8000399e:	6121                	addi	sp,sp,64
    800039a0:	8082                	ret
    iput(ip);
    800039a2:	9a5ff0ef          	jal	ra,80003346 <iput>
    return -1;
    800039a6:	557d                	li	a0,-1
    800039a8:	b7ed                	j	80003992 <dirlink+0x76>
      panic("dirlink read");
    800039aa:	00004517          	auipc	a0,0x4
    800039ae:	c3650513          	addi	a0,a0,-970 # 800075e0 <syscalls+0x1f0>
    800039b2:	dd9fc0ef          	jal	ra,8000078a <panic>

00000000800039b6 <namei>:

struct inode*
namei(char *path)
{
    800039b6:	1101                	addi	sp,sp,-32
    800039b8:	ec06                	sd	ra,24(sp)
    800039ba:	e822                	sd	s0,16(sp)
    800039bc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800039be:	fe040613          	addi	a2,s0,-32
    800039c2:	4581                	li	a1,0
    800039c4:	e29ff0ef          	jal	ra,800037ec <namex>
}
    800039c8:	60e2                	ld	ra,24(sp)
    800039ca:	6442                	ld	s0,16(sp)
    800039cc:	6105                	addi	sp,sp,32
    800039ce:	8082                	ret

00000000800039d0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800039d0:	1141                	addi	sp,sp,-16
    800039d2:	e406                	sd	ra,8(sp)
    800039d4:	e022                	sd	s0,0(sp)
    800039d6:	0800                	addi	s0,sp,16
    800039d8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800039da:	4585                	li	a1,1
    800039dc:	e11ff0ef          	jal	ra,800037ec <namex>
}
    800039e0:	60a2                	ld	ra,8(sp)
    800039e2:	6402                	ld	s0,0(sp)
    800039e4:	0141                	addi	sp,sp,16
    800039e6:	8082                	ret

00000000800039e8 <write_head>:
  brelse(buf);  // 释放缓冲区
}

// 将内存中的日志头写回磁盘
static void write_head(void)
{
    800039e8:	1101                	addi	sp,sp,-32
    800039ea:	ec06                	sd	ra,24(sp)
    800039ec:	e822                	sd	s0,16(sp)
    800039ee:	e426                	sd	s1,8(sp)
    800039f0:	e04a                	sd	s2,0(sp)
    800039f2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800039f4:	0001c917          	auipc	s2,0x1c
    800039f8:	14490913          	addi	s2,s2,324 # 8001fb38 <log>
    800039fc:	01892583          	lw	a1,24(s2)
    80003a00:	02492503          	lw	a0,36(s2)
    80003a04:	912ff0ef          	jal	ra,80002b16 <bread>
    80003a08:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;  // 更新日志中的块数量
    80003a0a:	02892683          	lw	a3,40(s2)
    80003a0e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003a10:	02d05763          	blez	a3,80003a3e <write_head+0x56>
    80003a14:	0001c797          	auipc	a5,0x1c
    80003a18:	15078793          	addi	a5,a5,336 # 8001fb64 <log+0x2c>
    80003a1c:	05c50713          	addi	a4,a0,92
    80003a20:	36fd                	addiw	a3,a3,-1
    80003a22:	1682                	slli	a3,a3,0x20
    80003a24:	9281                	srli	a3,a3,0x20
    80003a26:	068a                	slli	a3,a3,0x2
    80003a28:	0001c617          	auipc	a2,0x1c
    80003a2c:	14060613          	addi	a2,a2,320 # 8001fb68 <log+0x30>
    80003a30:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];  // 更新每个日志块的块号
    80003a32:	4390                	lw	a2,0(a5)
    80003a34:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003a36:	0791                	addi	a5,a5,4
    80003a38:	0711                	addi	a4,a4,4
    80003a3a:	fed79ce3          	bne	a5,a3,80003a32 <write_head+0x4a>
  }
  bwrite(buf);  // 写回日志头块
    80003a3e:	8526                	mv	a0,s1
    80003a40:	9acff0ef          	jal	ra,80002bec <bwrite>
  brelse(buf);  // 释放缓冲区
    80003a44:	8526                	mv	a0,s1
    80003a46:	9d8ff0ef          	jal	ra,80002c1e <brelse>
}
    80003a4a:	60e2                	ld	ra,24(sp)
    80003a4c:	6442                	ld	s0,16(sp)
    80003a4e:	64a2                	ld	s1,8(sp)
    80003a50:	6902                	ld	s2,0(sp)
    80003a52:	6105                	addi	sp,sp,32
    80003a54:	8082                	ret

0000000080003a56 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003a56:	0001c797          	auipc	a5,0x1c
    80003a5a:	10a7a783          	lw	a5,266(a5) # 8001fb60 <log+0x28>
    80003a5e:	0af05e63          	blez	a5,80003b1a <install_trans+0xc4>
{
    80003a62:	715d                	addi	sp,sp,-80
    80003a64:	e486                	sd	ra,72(sp)
    80003a66:	e0a2                	sd	s0,64(sp)
    80003a68:	fc26                	sd	s1,56(sp)
    80003a6a:	f84a                	sd	s2,48(sp)
    80003a6c:	f44e                	sd	s3,40(sp)
    80003a6e:	f052                	sd	s4,32(sp)
    80003a70:	ec56                	sd	s5,24(sp)
    80003a72:	e85a                	sd	s6,16(sp)
    80003a74:	e45e                	sd	s7,8(sp)
    80003a76:	0880                	addi	s0,sp,80
    80003a78:	8b2a                	mv	s6,a0
    80003a7a:	0001ca97          	auipc	s5,0x1c
    80003a7e:	0eaa8a93          	addi	s5,s5,234 # 8001fb64 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003a82:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003a84:	00004b97          	auipc	s7,0x4
    80003a88:	b6cb8b93          	addi	s7,s7,-1172 # 800075f0 <syscalls+0x200>
    struct buf *lbuf = bread(log.dev, log.start + tail + 1);  // 读取日志块
    80003a8c:	0001ca17          	auipc	s4,0x1c
    80003a90:	0aca0a13          	addi	s4,s4,172 # 8001fb38 <log>
    80003a94:	a025                	j	80003abc <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003a96:	000aa603          	lw	a2,0(s5)
    80003a9a:	85ce                	mv	a1,s3
    80003a9c:	855e                	mv	a0,s7
    80003a9e:	a27fc0ef          	jal	ra,800004c4 <printf>
    80003aa2:	a839                	j	80003ac0 <install_trans+0x6a>
    brelse(lbuf);  // 释放日志块
    80003aa4:	854a                	mv	a0,s2
    80003aa6:	978ff0ef          	jal	ra,80002c1e <brelse>
    brelse(dbuf);  // 释放目标块
    80003aaa:	8526                	mv	a0,s1
    80003aac:	972ff0ef          	jal	ra,80002c1e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ab0:	2985                	addiw	s3,s3,1
    80003ab2:	0a91                	addi	s5,s5,4
    80003ab4:	028a2783          	lw	a5,40(s4)
    80003ab8:	04f9d663          	bge	s3,a5,80003b04 <install_trans+0xae>
    if(recovering) {
    80003abc:	fc0b1de3          	bnez	s6,80003a96 <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start + tail + 1);  // 读取日志块
    80003ac0:	018a2583          	lw	a1,24(s4)
    80003ac4:	013585bb          	addw	a1,a1,s3
    80003ac8:	2585                	addiw	a1,a1,1
    80003aca:	024a2503          	lw	a0,36(s4)
    80003ace:	848ff0ef          	jal	ra,80002b16 <bread>
    80003ad2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]);  // 读取目标块
    80003ad4:	000aa583          	lw	a1,0(s5)
    80003ad8:	024a2503          	lw	a0,36(s4)
    80003adc:	83aff0ef          	jal	ra,80002b16 <bread>
    80003ae0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);
    80003ae2:	40000613          	li	a2,1024
    80003ae6:	05890593          	addi	a1,s2,88
    80003aea:	05850513          	addi	a0,a0,88
    80003aee:	9aefd0ef          	jal	ra,80000c9c <memmove>
    bwrite(dbuf);  // 将目标块写回磁盘
    80003af2:	8526                	mv	a0,s1
    80003af4:	8f8ff0ef          	jal	ra,80002bec <bwrite>
    if(recovering == 0)
    80003af8:	fa0b16e3          	bnez	s6,80003aa4 <install_trans+0x4e>
      bunpin(dbuf);  // 提交后解锁目标块
    80003afc:	8526                	mv	a0,s1
    80003afe:	9deff0ef          	jal	ra,80002cdc <bunpin>
    80003b02:	b74d                	j	80003aa4 <install_trans+0x4e>
}
    80003b04:	60a6                	ld	ra,72(sp)
    80003b06:	6406                	ld	s0,64(sp)
    80003b08:	74e2                	ld	s1,56(sp)
    80003b0a:	7942                	ld	s2,48(sp)
    80003b0c:	79a2                	ld	s3,40(sp)
    80003b0e:	7a02                	ld	s4,32(sp)
    80003b10:	6ae2                	ld	s5,24(sp)
    80003b12:	6b42                	ld	s6,16(sp)
    80003b14:	6ba2                	ld	s7,8(sp)
    80003b16:	6161                	addi	sp,sp,80
    80003b18:	8082                	ret
    80003b1a:	8082                	ret

0000000080003b1c <initlog>:
{
    80003b1c:	7179                	addi	sp,sp,-48
    80003b1e:	f406                	sd	ra,40(sp)
    80003b20:	f022                	sd	s0,32(sp)
    80003b22:	ec26                	sd	s1,24(sp)
    80003b24:	e84a                	sd	s2,16(sp)
    80003b26:	e44e                	sd	s3,8(sp)
    80003b28:	1800                	addi	s0,sp,48
    80003b2a:	892a                	mv	s2,a0
    80003b2c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003b2e:	0001c497          	auipc	s1,0x1c
    80003b32:	00a48493          	addi	s1,s1,10 # 8001fb38 <log>
    80003b36:	00004597          	auipc	a1,0x4
    80003b3a:	ada58593          	addi	a1,a1,-1318 # 80007610 <syscalls+0x220>
    80003b3e:	8526                	mv	a0,s1
    80003b40:	fadfc0ef          	jal	ra,80000aec <initlock>
  log.start = sb->logstart;  // 设置日志起始位置
    80003b44:	0149a583          	lw	a1,20(s3)
    80003b48:	cc8c                	sw	a1,24(s1)
  log.dev = dev;  // 设置日志设备
    80003b4a:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003b4e:	854a                	mv	a0,s2
    80003b50:	fc7fe0ef          	jal	ra,80002b16 <bread>
  log.lh.n = lh->n;  // 读取日志中的块数量
    80003b54:	4d34                	lw	a3,88(a0)
    80003b56:	d494                	sw	a3,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003b58:	02d05563          	blez	a3,80003b82 <initlog+0x66>
    80003b5c:	05c50793          	addi	a5,a0,92
    80003b60:	0001c717          	auipc	a4,0x1c
    80003b64:	00470713          	addi	a4,a4,4 # 8001fb64 <log+0x2c>
    80003b68:	36fd                	addiw	a3,a3,-1
    80003b6a:	1682                	slli	a3,a3,0x20
    80003b6c:	9281                	srli	a3,a3,0x20
    80003b6e:	068a                	slli	a3,a3,0x2
    80003b70:	06050613          	addi	a2,a0,96
    80003b74:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];  // 读取每个日志块的块号
    80003b76:	4390                	lw	a2,0(a5)
    80003b78:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003b7a:	0791                	addi	a5,a5,4
    80003b7c:	0711                	addi	a4,a4,4
    80003b7e:	fed79ce3          	bne	a5,a3,80003b76 <initlog+0x5a>
  brelse(buf);  // 释放缓冲区
    80003b82:	89cff0ef          	jal	ra,80002c1e <brelse>

// 从日志中恢复
static void recover_from_log(void)
{
  read_head();  // 读取日志头
  install_trans(1);  // 如果已提交，从日志复制到磁盘
    80003b86:	4505                	li	a0,1
    80003b88:	ecfff0ef          	jal	ra,80003a56 <install_trans>
  log.lh.n = 0;  // 清空日志中的块数量
    80003b8c:	0001c797          	auipc	a5,0x1c
    80003b90:	fc07aa23          	sw	zero,-44(a5) # 8001fb60 <log+0x28>
  write_head();  // 清空日志
    80003b94:	e55ff0ef          	jal	ra,800039e8 <write_head>
}
    80003b98:	70a2                	ld	ra,40(sp)
    80003b9a:	7402                	ld	s0,32(sp)
    80003b9c:	64e2                	ld	s1,24(sp)
    80003b9e:	6942                	ld	s2,16(sp)
    80003ba0:	69a2                	ld	s3,8(sp)
    80003ba2:	6145                	addi	sp,sp,48
    80003ba4:	8082                	ret

0000000080003ba6 <begin_op>:
}

// 文件系统调用开始时调用
void begin_op(void)
{
    80003ba6:	1101                	addi	sp,sp,-32
    80003ba8:	ec06                	sd	ra,24(sp)
    80003baa:	e822                	sd	s0,16(sp)
    80003bac:	e426                	sd	s1,8(sp)
    80003bae:	e04a                	sd	s2,0(sp)
    80003bb0:	1000                	addi	s0,sp,32
  acquire(&log.lock);  // 获取日志锁
    80003bb2:	0001c517          	auipc	a0,0x1c
    80003bb6:	f8650513          	addi	a0,a0,-122 # 8001fb38 <log>
    80003bba:	fb3fc0ef          	jal	ra,80000b6c <acquire>
  while(1){
    if(log.committing){
    80003bbe:	0001c497          	auipc	s1,0x1c
    80003bc2:	f7a48493          	addi	s1,s1,-134 # 8001fb38 <log>
      // 如果日志正在提交，进入睡眠
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGBLOCKS){
    80003bc6:	4979                	li	s2,30
    80003bc8:	a029                	j	80003bd2 <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003bca:	85a6                	mv	a1,s1
    80003bcc:	8526                	mv	a0,s1
    80003bce:	a48fe0ef          	jal	ra,80001e16 <sleep>
    if(log.committing){
    80003bd2:	509c                	lw	a5,32(s1)
    80003bd4:	fbfd                	bnez	a5,80003bca <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGBLOCKS){
    80003bd6:	4cdc                	lw	a5,28(s1)
    80003bd8:	0017871b          	addiw	a4,a5,1
    80003bdc:	0007069b          	sext.w	a3,a4
    80003be0:	0027179b          	slliw	a5,a4,0x2
    80003be4:	9fb9                	addw	a5,a5,a4
    80003be6:	0017979b          	slliw	a5,a5,0x1
    80003bea:	5498                	lw	a4,40(s1)
    80003bec:	9fb9                	addw	a5,a5,a4
    80003bee:	00f95763          	bge	s2,a5,80003bfc <begin_op+0x56>
      // 如果当前操作可能耗尽日志空间，等待提交
      sleep(&log, &log.lock);
    80003bf2:	85a6                	mv	a1,s1
    80003bf4:	8526                	mv	a0,s1
    80003bf6:	a20fe0ef          	jal	ra,80001e16 <sleep>
    80003bfa:	bfe1                	j	80003bd2 <begin_op+0x2c>
    } else {
      log.outstanding += 1;  // 增加正在进行的操作计数
    80003bfc:	0001c517          	auipc	a0,0x1c
    80003c00:	f3c50513          	addi	a0,a0,-196 # 8001fb38 <log>
    80003c04:	cd54                	sw	a3,28(a0)
      release(&log.lock);  // 释放日志锁
    80003c06:	ffffc0ef          	jal	ra,80000c04 <release>
      break;
    }
  }
}
    80003c0a:	60e2                	ld	ra,24(sp)
    80003c0c:	6442                	ld	s0,16(sp)
    80003c0e:	64a2                	ld	s1,8(sp)
    80003c10:	6902                	ld	s2,0(sp)
    80003c12:	6105                	addi	sp,sp,32
    80003c14:	8082                	ret

0000000080003c16 <end_op>:

// 文件系统调用结束时调用
// 如果这是最后一个待处理的操作，则提交日志
void end_op(void)
{
    80003c16:	7139                	addi	sp,sp,-64
    80003c18:	fc06                	sd	ra,56(sp)
    80003c1a:	f822                	sd	s0,48(sp)
    80003c1c:	f426                	sd	s1,40(sp)
    80003c1e:	f04a                	sd	s2,32(sp)
    80003c20:	ec4e                	sd	s3,24(sp)
    80003c22:	e852                	sd	s4,16(sp)
    80003c24:	e456                	sd	s5,8(sp)
    80003c26:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);  // 获取日志锁
    80003c28:	0001c497          	auipc	s1,0x1c
    80003c2c:	f1048493          	addi	s1,s1,-240 # 8001fb38 <log>
    80003c30:	8526                	mv	a0,s1
    80003c32:	f3bfc0ef          	jal	ra,80000b6c <acquire>
  log.outstanding -= 1;  // 减少待处理操作计数
    80003c36:	4cdc                	lw	a5,28(s1)
    80003c38:	37fd                	addiw	a5,a5,-1
    80003c3a:	0007891b          	sext.w	s2,a5
    80003c3e:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80003c40:	509c                	lw	a5,32(s1)
    80003c42:	ef9d                	bnez	a5,80003c80 <end_op+0x6a>
    panic("log.committing");  // 不允许在提交时结束操作
  if(log.outstanding == 0){
    80003c44:	04091463          	bnez	s2,80003c8c <end_op+0x76>
    do_commit = 1;  // 如果没有待处理的操作，则标记为需要提交
    log.committing = 1;  // 标记日志为正在提交
    80003c48:	0001c497          	auipc	s1,0x1c
    80003c4c:	ef048493          	addi	s1,s1,-272 # 8001fb38 <log>
    80003c50:	4785                	li	a5,1
    80003c52:	d09c                	sw	a5,32(s1)
  } else {
    // 如果正在等待日志空间，唤醒等待的进程
    wakeup(&log);
  }
  release(&log.lock);  // 释放日志锁
    80003c54:	8526                	mv	a0,s1
    80003c56:	faffc0ef          	jal	ra,80000c04 <release>
}

// 提交事务，将日志中的块写回磁盘并清空日志
static void commit()
{
  if (log.lh.n > 0) {
    80003c5a:	549c                	lw	a5,40(s1)
    80003c5c:	04f04b63          	bgtz	a5,80003cb2 <end_op+0x9c>
    acquire(&log.lock);
    80003c60:	0001c497          	auipc	s1,0x1c
    80003c64:	ed848493          	addi	s1,s1,-296 # 8001fb38 <log>
    80003c68:	8526                	mv	a0,s1
    80003c6a:	f03fc0ef          	jal	ra,80000b6c <acquire>
    log.committing = 0;  // 提交完成，恢复日志状态
    80003c6e:	0204a023          	sw	zero,32(s1)
    wakeup(&log);  // 唤醒可能在等待提交的进程
    80003c72:	8526                	mv	a0,s1
    80003c74:	9eefe0ef          	jal	ra,80001e62 <wakeup>
    release(&log.lock);  // 释放日志锁
    80003c78:	8526                	mv	a0,s1
    80003c7a:	f8bfc0ef          	jal	ra,80000c04 <release>
}
    80003c7e:	a00d                	j	80003ca0 <end_op+0x8a>
    panic("log.committing");  // 不允许在提交时结束操作
    80003c80:	00004517          	auipc	a0,0x4
    80003c84:	99850513          	addi	a0,a0,-1640 # 80007618 <syscalls+0x228>
    80003c88:	b03fc0ef          	jal	ra,8000078a <panic>
    wakeup(&log);
    80003c8c:	0001c497          	auipc	s1,0x1c
    80003c90:	eac48493          	addi	s1,s1,-340 # 8001fb38 <log>
    80003c94:	8526                	mv	a0,s1
    80003c96:	9ccfe0ef          	jal	ra,80001e62 <wakeup>
  release(&log.lock);  // 释放日志锁
    80003c9a:	8526                	mv	a0,s1
    80003c9c:	f69fc0ef          	jal	ra,80000c04 <release>
}
    80003ca0:	70e2                	ld	ra,56(sp)
    80003ca2:	7442                	ld	s0,48(sp)
    80003ca4:	74a2                	ld	s1,40(sp)
    80003ca6:	7902                	ld	s2,32(sp)
    80003ca8:	69e2                	ld	s3,24(sp)
    80003caa:	6a42                	ld	s4,16(sp)
    80003cac:	6aa2                	ld	s5,8(sp)
    80003cae:	6121                	addi	sp,sp,64
    80003cb0:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80003cb2:	0001ca97          	auipc	s5,0x1c
    80003cb6:	eb2a8a93          	addi	s5,s5,-334 # 8001fb64 <log+0x2c>
    struct buf *to = bread(log.dev, log.start + tail + 1);  // 读取日志块
    80003cba:	0001ca17          	auipc	s4,0x1c
    80003cbe:	e7ea0a13          	addi	s4,s4,-386 # 8001fb38 <log>
    80003cc2:	018a2583          	lw	a1,24(s4)
    80003cc6:	012585bb          	addw	a1,a1,s2
    80003cca:	2585                	addiw	a1,a1,1
    80003ccc:	024a2503          	lw	a0,36(s4)
    80003cd0:	e47fe0ef          	jal	ra,80002b16 <bread>
    80003cd4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]);  // 读取缓存块
    80003cd6:	000aa583          	lw	a1,0(s5)
    80003cda:	024a2503          	lw	a0,36(s4)
    80003cde:	e39fe0ef          	jal	ra,80002b16 <bread>
    80003ce2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);  // 将缓存块的数据复制到日志块
    80003ce4:	40000613          	li	a2,1024
    80003ce8:	05850593          	addi	a1,a0,88
    80003cec:	05848513          	addi	a0,s1,88
    80003cf0:	fadfc0ef          	jal	ra,80000c9c <memmove>
    bwrite(to);  // 写入日志块
    80003cf4:	8526                	mv	a0,s1
    80003cf6:	ef7fe0ef          	jal	ra,80002bec <bwrite>
    brelse(from);  // 释放缓存块
    80003cfa:	854e                	mv	a0,s3
    80003cfc:	f23fe0ef          	jal	ra,80002c1e <brelse>
    brelse(to);  // 释放日志块
    80003d00:	8526                	mv	a0,s1
    80003d02:	f1dfe0ef          	jal	ra,80002c1e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003d06:	2905                	addiw	s2,s2,1
    80003d08:	0a91                	addi	s5,s5,4
    80003d0a:	028a2783          	lw	a5,40(s4)
    80003d0e:	faf94ae3          	blt	s2,a5,80003cc2 <end_op+0xac>
    write_log();     // 将已修改的块从缓存写入日志
    write_head();    // 写入日志头到磁盘，真正提交
    80003d12:	cd7ff0ef          	jal	ra,800039e8 <write_head>
    install_trans(0); // 将写入操作应用到实际位置
    80003d16:	4501                	li	a0,0
    80003d18:	d3fff0ef          	jal	ra,80003a56 <install_trans>
    log.lh.n = 0;    // 清空日志中的块数量
    80003d1c:	0001c797          	auipc	a5,0x1c
    80003d20:	e407a223          	sw	zero,-444(a5) # 8001fb60 <log+0x28>
    write_head();    // 清空日志
    80003d24:	cc5ff0ef          	jal	ra,800039e8 <write_head>
    80003d28:	bf25                	j	80003c60 <end_op+0x4a>

0000000080003d2a <log_write>:
//   bp = bread(...)
//   修改 bp->data[]
//   log_write(bp)
//   brelse(bp)
void log_write(struct buf *b)
{
    80003d2a:	1101                	addi	sp,sp,-32
    80003d2c:	ec06                	sd	ra,24(sp)
    80003d2e:	e822                	sd	s0,16(sp)
    80003d30:	e426                	sd	s1,8(sp)
    80003d32:	e04a                	sd	s2,0(sp)
    80003d34:	1000                	addi	s0,sp,32
    80003d36:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);  // 获取日志锁
    80003d38:	0001c917          	auipc	s2,0x1c
    80003d3c:	e0090913          	addi	s2,s2,-512 # 8001fb38 <log>
    80003d40:	854a                	mv	a0,s2
    80003d42:	e2bfc0ef          	jal	ra,80000b6c <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80003d46:	02892603          	lw	a2,40(s2)
    80003d4a:	47f5                	li	a5,29
    80003d4c:	04c7cc63          	blt	a5,a2,80003da4 <log_write+0x7a>
    panic("too big a transaction");  // 如果日志块数量超过最大值，出错
  if (log.outstanding < 1)
    80003d50:	0001c797          	auipc	a5,0x1c
    80003d54:	e047a783          	lw	a5,-508(a5) # 8001fb54 <log+0x1c>
    80003d58:	04f05c63          	blez	a5,80003db0 <log_write+0x86>
    panic("log_write outside of trans");  // 如果在没有事务的情况下调用，出错

  for (i = 0; i < log.lh.n; i++) {
    80003d5c:	4781                	li	a5,0
    80003d5e:	04c05f63          	blez	a2,80003dbc <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // 如果块已经存在于日志中，跳过
    80003d62:	44cc                	lw	a1,12(s1)
    80003d64:	0001c717          	auipc	a4,0x1c
    80003d68:	e0070713          	addi	a4,a4,-512 # 8001fb64 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80003d6c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // 如果块已经存在于日志中，跳过
    80003d6e:	4314                	lw	a3,0(a4)
    80003d70:	04b68663          	beq	a3,a1,80003dbc <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80003d74:	2785                	addiw	a5,a5,1
    80003d76:	0711                	addi	a4,a4,4
    80003d78:	fef61be3          	bne	a2,a5,80003d6e <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;  // 将块号记录到日志中
    80003d7c:	0621                	addi	a2,a2,8
    80003d7e:	060a                	slli	a2,a2,0x2
    80003d80:	0001c797          	auipc	a5,0x1c
    80003d84:	db878793          	addi	a5,a5,-584 # 8001fb38 <log>
    80003d88:	963e                	add	a2,a2,a5
    80003d8a:	44dc                	lw	a5,12(s1)
    80003d8c:	c65c                	sw	a5,12(a2)
  if (i == log.lh.n) {  // 如果是新块，添加到日志
    bpin(b);  // 锁定块
    80003d8e:	8526                	mv	a0,s1
    80003d90:	f19fe0ef          	jal	ra,80002ca8 <bpin>
    log.lh.n++;  // 增加日志中的块数量
    80003d94:	0001c717          	auipc	a4,0x1c
    80003d98:	da470713          	addi	a4,a4,-604 # 8001fb38 <log>
    80003d9c:	571c                	lw	a5,40(a4)
    80003d9e:	2785                	addiw	a5,a5,1
    80003da0:	d71c                	sw	a5,40(a4)
    80003da2:	a815                	j	80003dd6 <log_write+0xac>
    panic("too big a transaction");  // 如果日志块数量超过最大值，出错
    80003da4:	00004517          	auipc	a0,0x4
    80003da8:	88450513          	addi	a0,a0,-1916 # 80007628 <syscalls+0x238>
    80003dac:	9dffc0ef          	jal	ra,8000078a <panic>
    panic("log_write outside of trans");  // 如果在没有事务的情况下调用，出错
    80003db0:	00004517          	auipc	a0,0x4
    80003db4:	89050513          	addi	a0,a0,-1904 # 80007640 <syscalls+0x250>
    80003db8:	9d3fc0ef          	jal	ra,8000078a <panic>
  log.lh.block[i] = b->blockno;  // 将块号记录到日志中
    80003dbc:	00878713          	addi	a4,a5,8
    80003dc0:	00271693          	slli	a3,a4,0x2
    80003dc4:	0001c717          	auipc	a4,0x1c
    80003dc8:	d7470713          	addi	a4,a4,-652 # 8001fb38 <log>
    80003dcc:	9736                	add	a4,a4,a3
    80003dce:	44d4                	lw	a3,12(s1)
    80003dd0:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // 如果是新块，添加到日志
    80003dd2:	faf60ee3          	beq	a2,a5,80003d8e <log_write+0x64>
  }
  release(&log.lock);  // 释放日志锁
    80003dd6:	0001c517          	auipc	a0,0x1c
    80003dda:	d6250513          	addi	a0,a0,-670 # 8001fb38 <log>
    80003dde:	e27fc0ef          	jal	ra,80000c04 <release>
}
    80003de2:	60e2                	ld	ra,24(sp)
    80003de4:	6442                	ld	s0,16(sp)
    80003de6:	64a2                	ld	s1,8(sp)
    80003de8:	6902                	ld	s2,0(sp)
    80003dea:	6105                	addi	sp,sp,32
    80003dec:	8082                	ret

0000000080003dee <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80003dee:	1101                	addi	sp,sp,-32
    80003df0:	ec06                	sd	ra,24(sp)
    80003df2:	e822                	sd	s0,16(sp)
    80003df4:	e426                	sd	s1,8(sp)
    80003df6:	e04a                	sd	s2,0(sp)
    80003df8:	1000                	addi	s0,sp,32
    80003dfa:	84aa                	mv	s1,a0
    80003dfc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80003dfe:	00004597          	auipc	a1,0x4
    80003e02:	86258593          	addi	a1,a1,-1950 # 80007660 <syscalls+0x270>
    80003e06:	0521                	addi	a0,a0,8
    80003e08:	ce5fc0ef          	jal	ra,80000aec <initlock>
  lk->name = name;
    80003e0c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80003e10:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003e14:	0204a423          	sw	zero,40(s1)
}
    80003e18:	60e2                	ld	ra,24(sp)
    80003e1a:	6442                	ld	s0,16(sp)
    80003e1c:	64a2                	ld	s1,8(sp)
    80003e1e:	6902                	ld	s2,0(sp)
    80003e20:	6105                	addi	sp,sp,32
    80003e22:	8082                	ret

0000000080003e24 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80003e24:	1101                	addi	sp,sp,-32
    80003e26:	ec06                	sd	ra,24(sp)
    80003e28:	e822                	sd	s0,16(sp)
    80003e2a:	e426                	sd	s1,8(sp)
    80003e2c:	e04a                	sd	s2,0(sp)
    80003e2e:	1000                	addi	s0,sp,32
    80003e30:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003e32:	00850913          	addi	s2,a0,8
    80003e36:	854a                	mv	a0,s2
    80003e38:	d35fc0ef          	jal	ra,80000b6c <acquire>
  while (lk->locked) {
    80003e3c:	409c                	lw	a5,0(s1)
    80003e3e:	c799                	beqz	a5,80003e4c <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80003e40:	85ca                	mv	a1,s2
    80003e42:	8526                	mv	a0,s1
    80003e44:	fd3fd0ef          	jal	ra,80001e16 <sleep>
  while (lk->locked) {
    80003e48:	409c                	lw	a5,0(s1)
    80003e4a:	fbfd                	bnez	a5,80003e40 <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80003e4c:	4785                	li	a5,1
    80003e4e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80003e50:	9b5fd0ef          	jal	ra,80001804 <myproc>
    80003e54:	591c                	lw	a5,48(a0)
    80003e56:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80003e58:	854a                	mv	a0,s2
    80003e5a:	dabfc0ef          	jal	ra,80000c04 <release>
}
    80003e5e:	60e2                	ld	ra,24(sp)
    80003e60:	6442                	ld	s0,16(sp)
    80003e62:	64a2                	ld	s1,8(sp)
    80003e64:	6902                	ld	s2,0(sp)
    80003e66:	6105                	addi	sp,sp,32
    80003e68:	8082                	ret

0000000080003e6a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80003e6a:	1101                	addi	sp,sp,-32
    80003e6c:	ec06                	sd	ra,24(sp)
    80003e6e:	e822                	sd	s0,16(sp)
    80003e70:	e426                	sd	s1,8(sp)
    80003e72:	e04a                	sd	s2,0(sp)
    80003e74:	1000                	addi	s0,sp,32
    80003e76:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003e78:	00850913          	addi	s2,a0,8
    80003e7c:	854a                	mv	a0,s2
    80003e7e:	ceffc0ef          	jal	ra,80000b6c <acquire>
  lk->locked = 0;
    80003e82:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003e86:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80003e8a:	8526                	mv	a0,s1
    80003e8c:	fd7fd0ef          	jal	ra,80001e62 <wakeup>
  release(&lk->lk);
    80003e90:	854a                	mv	a0,s2
    80003e92:	d73fc0ef          	jal	ra,80000c04 <release>
}
    80003e96:	60e2                	ld	ra,24(sp)
    80003e98:	6442                	ld	s0,16(sp)
    80003e9a:	64a2                	ld	s1,8(sp)
    80003e9c:	6902                	ld	s2,0(sp)
    80003e9e:	6105                	addi	sp,sp,32
    80003ea0:	8082                	ret

0000000080003ea2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80003ea2:	7179                	addi	sp,sp,-48
    80003ea4:	f406                	sd	ra,40(sp)
    80003ea6:	f022                	sd	s0,32(sp)
    80003ea8:	ec26                	sd	s1,24(sp)
    80003eaa:	e84a                	sd	s2,16(sp)
    80003eac:	e44e                	sd	s3,8(sp)
    80003eae:	1800                	addi	s0,sp,48
    80003eb0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80003eb2:	00850913          	addi	s2,a0,8
    80003eb6:	854a                	mv	a0,s2
    80003eb8:	cb5fc0ef          	jal	ra,80000b6c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80003ebc:	409c                	lw	a5,0(s1)
    80003ebe:	ef89                	bnez	a5,80003ed8 <holdingsleep+0x36>
    80003ec0:	4481                	li	s1,0
  release(&lk->lk);
    80003ec2:	854a                	mv	a0,s2
    80003ec4:	d41fc0ef          	jal	ra,80000c04 <release>
  return r;
}
    80003ec8:	8526                	mv	a0,s1
    80003eca:	70a2                	ld	ra,40(sp)
    80003ecc:	7402                	ld	s0,32(sp)
    80003ece:	64e2                	ld	s1,24(sp)
    80003ed0:	6942                	ld	s2,16(sp)
    80003ed2:	69a2                	ld	s3,8(sp)
    80003ed4:	6145                	addi	sp,sp,48
    80003ed6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80003ed8:	0284a983          	lw	s3,40(s1)
    80003edc:	929fd0ef          	jal	ra,80001804 <myproc>
    80003ee0:	5904                	lw	s1,48(a0)
    80003ee2:	413484b3          	sub	s1,s1,s3
    80003ee6:	0014b493          	seqz	s1,s1
    80003eea:	bfe1                	j	80003ec2 <holdingsleep+0x20>

0000000080003eec <fileinit>:
} ftable;

// 文件表初始化
void
fileinit(void)
{
    80003eec:	1141                	addi	sp,sp,-16
    80003eee:	e406                	sd	ra,8(sp)
    80003ef0:	e022                	sd	s0,0(sp)
    80003ef2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");  // 初始化文件表的自旋锁
    80003ef4:	00003597          	auipc	a1,0x3
    80003ef8:	77c58593          	addi	a1,a1,1916 # 80007670 <syscalls+0x280>
    80003efc:	0001c517          	auipc	a0,0x1c
    80003f00:	d8450513          	addi	a0,a0,-636 # 8001fc80 <ftable>
    80003f04:	be9fc0ef          	jal	ra,80000aec <initlock>
}
    80003f08:	60a2                	ld	ra,8(sp)
    80003f0a:	6402                	ld	s0,0(sp)
    80003f0c:	0141                	addi	sp,sp,16
    80003f0e:	8082                	ret

0000000080003f10 <filealloc>:

// 分配一个新的文件结构体
struct file*
filealloc(void)
{
    80003f10:	1101                	addi	sp,sp,-32
    80003f12:	ec06                	sd	ra,24(sp)
    80003f14:	e822                	sd	s0,16(sp)
    80003f16:	e426                	sd	s1,8(sp)
    80003f18:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);  // 获取文件表锁
    80003f1a:	0001c517          	auipc	a0,0x1c
    80003f1e:	d6650513          	addi	a0,a0,-666 # 8001fc80 <ftable>
    80003f22:	c4bfc0ef          	jal	ra,80000b6c <acquire>
  // 遍历文件表，找到引用计数为 0 的文件结构体
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80003f26:	0001c497          	auipc	s1,0x1c
    80003f2a:	d7248493          	addi	s1,s1,-654 # 8001fc98 <ftable+0x18>
    80003f2e:	0001d717          	auipc	a4,0x1d
    80003f32:	d0a70713          	addi	a4,a4,-758 # 80020c38 <disk>
    if(f->ref == 0){
    80003f36:	40dc                	lw	a5,4(s1)
    80003f38:	cf89                	beqz	a5,80003f52 <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80003f3a:	02848493          	addi	s1,s1,40
    80003f3e:	fee49ce3          	bne	s1,a4,80003f36 <filealloc+0x26>
      f->ref = 1;  // 设置引用计数为 1
      release(&ftable.lock);  // 释放文件表锁
      return f;  // 返回分配的文件结构体
    }
  }
  release(&ftable.lock);  // 如果没有空闲文件结构体，释放锁
    80003f42:	0001c517          	auipc	a0,0x1c
    80003f46:	d3e50513          	addi	a0,a0,-706 # 8001fc80 <ftable>
    80003f4a:	cbbfc0ef          	jal	ra,80000c04 <release>
  return 0;  // 没有可用的文件结构体
    80003f4e:	4481                	li	s1,0
    80003f50:	a809                	j	80003f62 <filealloc+0x52>
      f->ref = 1;  // 设置引用计数为 1
    80003f52:	4785                	li	a5,1
    80003f54:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);  // 释放文件表锁
    80003f56:	0001c517          	auipc	a0,0x1c
    80003f5a:	d2a50513          	addi	a0,a0,-726 # 8001fc80 <ftable>
    80003f5e:	ca7fc0ef          	jal	ra,80000c04 <release>
}
    80003f62:	8526                	mv	a0,s1
    80003f64:	60e2                	ld	ra,24(sp)
    80003f66:	6442                	ld	s0,16(sp)
    80003f68:	64a2                	ld	s1,8(sp)
    80003f6a:	6105                	addi	sp,sp,32
    80003f6c:	8082                	ret

0000000080003f6e <filedup>:

// 增加文件结构体的引用计数
struct file*
filedup(struct file *f)
{
    80003f6e:	1101                	addi	sp,sp,-32
    80003f70:	ec06                	sd	ra,24(sp)
    80003f72:	e822                	sd	s0,16(sp)
    80003f74:	e426                	sd	s1,8(sp)
    80003f76:	1000                	addi	s0,sp,32
    80003f78:	84aa                	mv	s1,a0
  acquire(&ftable.lock);  // 获取文件表锁
    80003f7a:	0001c517          	auipc	a0,0x1c
    80003f7e:	d0650513          	addi	a0,a0,-762 # 8001fc80 <ftable>
    80003f82:	bebfc0ef          	jal	ra,80000b6c <acquire>
  if(f->ref < 1)  // 如果引用计数小于 1，说明文件结构体无效
    80003f86:	40dc                	lw	a5,4(s1)
    80003f88:	02f05063          	blez	a5,80003fa8 <filedup+0x3a>
    panic("filedup");
  f->ref++;  // 增加引用计数
    80003f8c:	2785                	addiw	a5,a5,1
    80003f8e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);  // 释放文件表锁
    80003f90:	0001c517          	auipc	a0,0x1c
    80003f94:	cf050513          	addi	a0,a0,-784 # 8001fc80 <ftable>
    80003f98:	c6dfc0ef          	jal	ra,80000c04 <release>
  return f;  // 返回文件结构体
}
    80003f9c:	8526                	mv	a0,s1
    80003f9e:	60e2                	ld	ra,24(sp)
    80003fa0:	6442                	ld	s0,16(sp)
    80003fa2:	64a2                	ld	s1,8(sp)
    80003fa4:	6105                	addi	sp,sp,32
    80003fa6:	8082                	ret
    panic("filedup");
    80003fa8:	00003517          	auipc	a0,0x3
    80003fac:	6d050513          	addi	a0,a0,1744 # 80007678 <syscalls+0x288>
    80003fb0:	fdafc0ef          	jal	ra,8000078a <panic>

0000000080003fb4 <fileclose>:

// 关闭文件结构体 f，减少引用计数，当引用计数为 0 时关闭文件
void
fileclose(struct file *f)
{
    80003fb4:	7139                	addi	sp,sp,-64
    80003fb6:	fc06                	sd	ra,56(sp)
    80003fb8:	f822                	sd	s0,48(sp)
    80003fba:	f426                	sd	s1,40(sp)
    80003fbc:	f04a                	sd	s2,32(sp)
    80003fbe:	ec4e                	sd	s3,24(sp)
    80003fc0:	e852                	sd	s4,16(sp)
    80003fc2:	e456                	sd	s5,8(sp)
    80003fc4:	0080                	addi	s0,sp,64
    80003fc6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);  // 获取文件表锁
    80003fc8:	0001c517          	auipc	a0,0x1c
    80003fcc:	cb850513          	addi	a0,a0,-840 # 8001fc80 <ftable>
    80003fd0:	b9dfc0ef          	jal	ra,80000b6c <acquire>
  if(f->ref < 1)  // 如果引用计数小于 1，说明文件结构体无效
    80003fd4:	40dc                	lw	a5,4(s1)
    80003fd6:	04f05963          	blez	a5,80004028 <fileclose+0x74>
    panic("fileclose");
  if(--f->ref > 0){  // 如果引用计数大于 0，直接返回
    80003fda:	37fd                	addiw	a5,a5,-1
    80003fdc:	0007871b          	sext.w	a4,a5
    80003fe0:	c0dc                	sw	a5,4(s1)
    80003fe2:	04e04963          	bgtz	a4,80004034 <fileclose+0x80>
    release(&ftable.lock);
    return;
  }
  ff = *f;  // 备份文件结构体
    80003fe6:	0004a903          	lw	s2,0(s1)
    80003fea:	0094ca83          	lbu	s5,9(s1)
    80003fee:	0104ba03          	ld	s4,16(s1)
    80003ff2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;  // 重置引用计数
    80003ff6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;  // 重置文件类型
    80003ffa:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);  // 释放文件表锁
    80003ffe:	0001c517          	auipc	a0,0x1c
    80004002:	c8250513          	addi	a0,a0,-894 # 8001fc80 <ftable>
    80004006:	bfffc0ef          	jal	ra,80000c04 <release>

  // 如果文件类型是管道（pipe），则关闭管道
  if(ff.type == FD_PIPE){
    8000400a:	4785                	li	a5,1
    8000400c:	04f90363          	beq	s2,a5,80004052 <fileclose+0x9e>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004010:	3979                	addiw	s2,s2,-2
    80004012:	4785                	li	a5,1
    80004014:	0327e663          	bltu	a5,s2,80004040 <fileclose+0x8c>
    begin_op();  // 开始一个文件系统操作
    80004018:	b8fff0ef          	jal	ra,80003ba6 <begin_op>
    iput(ff.ip);  // 释放 inode
    8000401c:	854e                	mv	a0,s3
    8000401e:	b28ff0ef          	jal	ra,80003346 <iput>
    end_op();  // 结束文件系统操作
    80004022:	bf5ff0ef          	jal	ra,80003c16 <end_op>
    80004026:	a829                	j	80004040 <fileclose+0x8c>
    panic("fileclose");
    80004028:	00003517          	auipc	a0,0x3
    8000402c:	65850513          	addi	a0,a0,1624 # 80007680 <syscalls+0x290>
    80004030:	f5afc0ef          	jal	ra,8000078a <panic>
    release(&ftable.lock);
    80004034:	0001c517          	auipc	a0,0x1c
    80004038:	c4c50513          	addi	a0,a0,-948 # 8001fc80 <ftable>
    8000403c:	bc9fc0ef          	jal	ra,80000c04 <release>
  }
}
    80004040:	70e2                	ld	ra,56(sp)
    80004042:	7442                	ld	s0,48(sp)
    80004044:	74a2                	ld	s1,40(sp)
    80004046:	7902                	ld	s2,32(sp)
    80004048:	69e2                	ld	s3,24(sp)
    8000404a:	6a42                	ld	s4,16(sp)
    8000404c:	6aa2                	ld	s5,8(sp)
    8000404e:	6121                	addi	sp,sp,64
    80004050:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004052:	85d6                	mv	a1,s5
    80004054:	8552                	mv	a0,s4
    80004056:	2ec000ef          	jal	ra,80004342 <pipeclose>
    8000405a:	b7dd                	j	80004040 <fileclose+0x8c>

000000008000405c <filestat>:

// 获取文件 f 的元数据（如文件大小、类型等）
// addr 是一个用户虚拟地址，指向 struct stat 结构
int
filestat(struct file *f, uint64 addr)
{
    8000405c:	715d                	addi	sp,sp,-80
    8000405e:	e486                	sd	ra,72(sp)
    80004060:	e0a2                	sd	s0,64(sp)
    80004062:	fc26                	sd	s1,56(sp)
    80004064:	f84a                	sd	s2,48(sp)
    80004066:	f44e                	sd	s3,40(sp)
    80004068:	0880                	addi	s0,sp,80
    8000406a:	84aa                	mv	s1,a0
    8000406c:	89ae                	mv	s3,a1
  struct proc *p = myproc();  // 获取当前进程
    8000406e:	f96fd0ef          	jal	ra,80001804 <myproc>
  struct stat st;
  
  // 如果文件是 inode 类型或设备类型
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004072:	409c                	lw	a5,0(s1)
    80004074:	37f9                	addiw	a5,a5,-2
    80004076:	4705                	li	a4,1
    80004078:	02f76f63          	bltu	a4,a5,800040b6 <filestat+0x5a>
    8000407c:	892a                	mv	s2,a0
    ilock(f->ip);  // 锁定 inode
    8000407e:	6c88                	ld	a0,24(s1)
    80004080:	948ff0ef          	jal	ra,800031c8 <ilock>
    stati(f->ip, &st);  // 获取 inode 的元数据
    80004084:	fb840593          	addi	a1,s0,-72
    80004088:	6c88                	ld	a0,24(s1)
    8000408a:	ca0ff0ef          	jal	ra,8000352a <stati>
    iunlock(f->ip);  // 解锁 inode
    8000408e:	6c88                	ld	a0,24(s1)
    80004090:	9e2ff0ef          	jal	ra,80003272 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)  // 将元数据复制到用户地址
    80004094:	46e1                	li	a3,24
    80004096:	fb840613          	addi	a2,s0,-72
    8000409a:	85ce                	mv	a1,s3
    8000409c:	05093503          	ld	a0,80(s2)
    800040a0:	cb2fd0ef          	jal	ra,80001552 <copyout>
    800040a4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;  // 其他类型文件不支持
}
    800040a8:	60a6                	ld	ra,72(sp)
    800040aa:	6406                	ld	s0,64(sp)
    800040ac:	74e2                	ld	s1,56(sp)
    800040ae:	7942                	ld	s2,48(sp)
    800040b0:	79a2                	ld	s3,40(sp)
    800040b2:	6161                	addi	sp,sp,80
    800040b4:	8082                	ret
  return -1;  // 其他类型文件不支持
    800040b6:	557d                	li	a0,-1
    800040b8:	bfc5                	j	800040a8 <filestat+0x4c>

00000000800040ba <fileread>:

// 从文件 f 中读取数据。
// addr 是一个用户虚拟地址。
int
fileread(struct file *f, uint64 addr, int n)
{
    800040ba:	7179                	addi	sp,sp,-48
    800040bc:	f406                	sd	ra,40(sp)
    800040be:	f022                	sd	s0,32(sp)
    800040c0:	ec26                	sd	s1,24(sp)
    800040c2:	e84a                	sd	s2,16(sp)
    800040c4:	e44e                	sd	s3,8(sp)
    800040c6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)  // 如果文件不可读，返回 -1
    800040c8:	00854783          	lbu	a5,8(a0)
    800040cc:	cbc1                	beqz	a5,8000415c <fileread+0xa2>
    800040ce:	84aa                	mv	s1,a0
    800040d0:	89ae                	mv	s3,a1
    800040d2:	8932                	mv	s2,a2
    return -1;

  // 根据文件类型执行不同的读取操作
  if(f->type == FD_PIPE){
    800040d4:	411c                	lw	a5,0(a0)
    800040d6:	4705                	li	a4,1
    800040d8:	04e78363          	beq	a5,a4,8000411e <fileread+0x64>
    r = piperead(f->pipe, addr, n);  // 从管道中读取
  } else if(f->type == FD_DEVICE){
    800040dc:	470d                	li	a4,3
    800040de:	04e78563          	beq	a5,a4,80004128 <fileread+0x6e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)  // 如果设备不支持读取，返回 -1
      return -1;
    r = devsw[f->major].read(1, addr, n);  // 调用设备的读取函数
  } else if(f->type == FD_INODE){
    800040e2:	4709                	li	a4,2
    800040e4:	06e79663          	bne	a5,a4,80004150 <fileread+0x96>
    ilock(f->ip);  // 锁定 inode
    800040e8:	6d08                	ld	a0,24(a0)
    800040ea:	8deff0ef          	jal	ra,800031c8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)  // 从 inode 中读取数据
    800040ee:	874a                	mv	a4,s2
    800040f0:	5094                	lw	a3,32(s1)
    800040f2:	864e                	mv	a2,s3
    800040f4:	4585                	li	a1,1
    800040f6:	6c88                	ld	a0,24(s1)
    800040f8:	c5cff0ef          	jal	ra,80003554 <readi>
    800040fc:	892a                	mv	s2,a0
    800040fe:	00a05563          	blez	a0,80004108 <fileread+0x4e>
      f->off += r;  // 更新文件偏移量
    80004102:	509c                	lw	a5,32(s1)
    80004104:	9fa9                	addw	a5,a5,a0
    80004106:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);  // 解锁 inode
    80004108:	6c88                	ld	a0,24(s1)
    8000410a:	968ff0ef          	jal	ra,80003272 <iunlock>
  } else {
    panic("fileread");  // 不支持的文件类型
  }

  return r;  // 返回读取的字节数
}
    8000410e:	854a                	mv	a0,s2
    80004110:	70a2                	ld	ra,40(sp)
    80004112:	7402                	ld	s0,32(sp)
    80004114:	64e2                	ld	s1,24(sp)
    80004116:	6942                	ld	s2,16(sp)
    80004118:	69a2                	ld	s3,8(sp)
    8000411a:	6145                	addi	sp,sp,48
    8000411c:	8082                	ret
    r = piperead(f->pipe, addr, n);  // 从管道中读取
    8000411e:	6908                	ld	a0,16(a0)
    80004120:	34e000ef          	jal	ra,8000446e <piperead>
    80004124:	892a                	mv	s2,a0
    80004126:	b7e5                	j	8000410e <fileread+0x54>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)  // 如果设备不支持读取，返回 -1
    80004128:	02451783          	lh	a5,36(a0)
    8000412c:	03079693          	slli	a3,a5,0x30
    80004130:	92c1                	srli	a3,a3,0x30
    80004132:	4725                	li	a4,9
    80004134:	02d76663          	bltu	a4,a3,80004160 <fileread+0xa6>
    80004138:	0792                	slli	a5,a5,0x4
    8000413a:	0001c717          	auipc	a4,0x1c
    8000413e:	aa670713          	addi	a4,a4,-1370 # 8001fbe0 <devsw>
    80004142:	97ba                	add	a5,a5,a4
    80004144:	639c                	ld	a5,0(a5)
    80004146:	cf99                	beqz	a5,80004164 <fileread+0xaa>
    r = devsw[f->major].read(1, addr, n);  // 调用设备的读取函数
    80004148:	4505                	li	a0,1
    8000414a:	9782                	jalr	a5
    8000414c:	892a                	mv	s2,a0
    8000414e:	b7c1                	j	8000410e <fileread+0x54>
    panic("fileread");  // 不支持的文件类型
    80004150:	00003517          	auipc	a0,0x3
    80004154:	54050513          	addi	a0,a0,1344 # 80007690 <syscalls+0x2a0>
    80004158:	e32fc0ef          	jal	ra,8000078a <panic>
    return -1;
    8000415c:	597d                	li	s2,-1
    8000415e:	bf45                	j	8000410e <fileread+0x54>
      return -1;
    80004160:	597d                	li	s2,-1
    80004162:	b775                	j	8000410e <fileread+0x54>
    80004164:	597d                	li	s2,-1
    80004166:	b765                	j	8000410e <fileread+0x54>

0000000080004168 <filewrite>:

// 向文件 f 中写入数据。
// addr 是一个用户虚拟地址。
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004168:	715d                	addi	sp,sp,-80
    8000416a:	e486                	sd	ra,72(sp)
    8000416c:	e0a2                	sd	s0,64(sp)
    8000416e:	fc26                	sd	s1,56(sp)
    80004170:	f84a                	sd	s2,48(sp)
    80004172:	f44e                	sd	s3,40(sp)
    80004174:	f052                	sd	s4,32(sp)
    80004176:	ec56                	sd	s5,24(sp)
    80004178:	e85a                	sd	s6,16(sp)
    8000417a:	e45e                	sd	s7,8(sp)
    8000417c:	e062                	sd	s8,0(sp)
    8000417e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)  // 如果文件不可写，返回 -1
    80004180:	00954783          	lbu	a5,9(a0)
    80004184:	0e078863          	beqz	a5,80004274 <filewrite+0x10c>
    80004188:	892a                	mv	s2,a0
    8000418a:	8aae                	mv	s5,a1
    8000418c:	8a32                	mv	s4,a2
    return -1;

  // 根据文件类型执行不同的写入操作
  if(f->type == FD_PIPE){
    8000418e:	411c                	lw	a5,0(a0)
    80004190:	4705                	li	a4,1
    80004192:	02e78263          	beq	a5,a4,800041b6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);  // 向管道中写入
  } else if(f->type == FD_DEVICE){
    80004196:	470d                	li	a4,3
    80004198:	02e78463          	beq	a5,a4,800041c0 <filewrite+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)  // 如果设备不支持写入，返回 -1
      return -1;
    ret = devsw[f->major].write(1, addr, n);  // 调用设备的写入函数
  } else if(f->type == FD_INODE){
    8000419c:	4709                	li	a4,2
    8000419e:	0ce79563          	bne	a5,a4,80004268 <filewrite+0x100>
    // 分多次写入，以避免超过最大日志事务大小，包括 inode、间接块、分配块等
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800041a2:	0ac05163          	blez	a2,80004244 <filewrite+0xdc>
    int i = 0;
    800041a6:	4981                	li	s3,0
    800041a8:	6b05                	lui	s6,0x1
    800041aa:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800041ae:	6b85                	lui	s7,0x1
    800041b0:	c00b8b9b          	addiw	s7,s7,-1024
    800041b4:	a041                	j	80004234 <filewrite+0xcc>
    ret = pipewrite(f->pipe, addr, n);  // 向管道中写入
    800041b6:	6908                	ld	a0,16(a0)
    800041b8:	1e2000ef          	jal	ra,8000439a <pipewrite>
    800041bc:	8a2a                	mv	s4,a0
    800041be:	a071                	j	8000424a <filewrite+0xe2>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)  // 如果设备不支持写入，返回 -1
    800041c0:	02451783          	lh	a5,36(a0)
    800041c4:	03079693          	slli	a3,a5,0x30
    800041c8:	92c1                	srli	a3,a3,0x30
    800041ca:	4725                	li	a4,9
    800041cc:	0ad76663          	bltu	a4,a3,80004278 <filewrite+0x110>
    800041d0:	0792                	slli	a5,a5,0x4
    800041d2:	0001c717          	auipc	a4,0x1c
    800041d6:	a0e70713          	addi	a4,a4,-1522 # 8001fbe0 <devsw>
    800041da:	97ba                	add	a5,a5,a4
    800041dc:	679c                	ld	a5,8(a5)
    800041de:	cfd9                	beqz	a5,8000427c <filewrite+0x114>
    ret = devsw[f->major].write(1, addr, n);  // 调用设备的写入函数
    800041e0:	4505                	li	a0,1
    800041e2:	9782                	jalr	a5
    800041e4:	8a2a                	mv	s4,a0
    800041e6:	a095                	j	8000424a <filewrite+0xe2>
    800041e8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)  // 如果写入数据超过最大限制，分批次写入
        n1 = max;

      begin_op();  // 开始一个文件系统操作
    800041ec:	9bbff0ef          	jal	ra,80003ba6 <begin_op>
      ilock(f->ip);  // 锁定 inode
    800041f0:	01893503          	ld	a0,24(s2)
    800041f4:	fd5fe0ef          	jal	ra,800031c8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800041f8:	8762                	mv	a4,s8
    800041fa:	02092683          	lw	a3,32(s2)
    800041fe:	01598633          	add	a2,s3,s5
    80004202:	4585                	li	a1,1
    80004204:	01893503          	ld	a0,24(s2)
    80004208:	c30ff0ef          	jal	ra,80003638 <writei>
    8000420c:	84aa                	mv	s1,a0
    8000420e:	00a05763          	blez	a0,8000421c <filewrite+0xb4>
        f->off += r;  // 更新文件偏移量
    80004212:	02092783          	lw	a5,32(s2)
    80004216:	9fa9                	addw	a5,a5,a0
    80004218:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);  // 解锁 inode
    8000421c:	01893503          	ld	a0,24(s2)
    80004220:	852ff0ef          	jal	ra,80003272 <iunlock>
      end_op();  // 结束文件系统操作
    80004224:	9f3ff0ef          	jal	ra,80003c16 <end_op>

      if(r != n1){  // 如果写入不完全，退出
    80004228:	009c1f63          	bne	s8,s1,80004246 <filewrite+0xde>
        break;
      }
      i += r;
    8000422c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004230:	0149db63          	bge	s3,s4,80004246 <filewrite+0xde>
      int n1 = n - i;
    80004234:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)  // 如果写入数据超过最大限制，分批次写入
    80004238:	84be                	mv	s1,a5
    8000423a:	2781                	sext.w	a5,a5
    8000423c:	fafb56e3          	bge	s6,a5,800041e8 <filewrite+0x80>
    80004240:	84de                	mv	s1,s7
    80004242:	b75d                	j	800041e8 <filewrite+0x80>
    int i = 0;
    80004244:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);  // 如果写入完全成功，返回写入字节数，否则返回 -1
    80004246:	013a1f63          	bne	s4,s3,80004264 <filewrite+0xfc>
  } else {
    panic("filewrite");  // 不支持的文件类型
  }

  return ret;  // 返回写入的字节数
}
    8000424a:	8552                	mv	a0,s4
    8000424c:	60a6                	ld	ra,72(sp)
    8000424e:	6406                	ld	s0,64(sp)
    80004250:	74e2                	ld	s1,56(sp)
    80004252:	7942                	ld	s2,48(sp)
    80004254:	79a2                	ld	s3,40(sp)
    80004256:	7a02                	ld	s4,32(sp)
    80004258:	6ae2                	ld	s5,24(sp)
    8000425a:	6b42                	ld	s6,16(sp)
    8000425c:	6ba2                	ld	s7,8(sp)
    8000425e:	6c02                	ld	s8,0(sp)
    80004260:	6161                	addi	sp,sp,80
    80004262:	8082                	ret
    ret = (i == n ? n : -1);  // 如果写入完全成功，返回写入字节数，否则返回 -1
    80004264:	5a7d                	li	s4,-1
    80004266:	b7d5                	j	8000424a <filewrite+0xe2>
    panic("filewrite");  // 不支持的文件类型
    80004268:	00003517          	auipc	a0,0x3
    8000426c:	43850513          	addi	a0,a0,1080 # 800076a0 <syscalls+0x2b0>
    80004270:	d1afc0ef          	jal	ra,8000078a <panic>
    return -1;
    80004274:	5a7d                	li	s4,-1
    80004276:	bfd1                	j	8000424a <filewrite+0xe2>
      return -1;
    80004278:	5a7d                	li	s4,-1
    8000427a:	bfc1                	j	8000424a <filewrite+0xe2>
    8000427c:	5a7d                	li	s4,-1
    8000427e:	b7f1                	j	8000424a <filewrite+0xe2>

0000000080004280 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004280:	7179                	addi	sp,sp,-48
    80004282:	f406                	sd	ra,40(sp)
    80004284:	f022                	sd	s0,32(sp)
    80004286:	ec26                	sd	s1,24(sp)
    80004288:	e84a                	sd	s2,16(sp)
    8000428a:	e44e                	sd	s3,8(sp)
    8000428c:	e052                	sd	s4,0(sp)
    8000428e:	1800                	addi	s0,sp,48
    80004290:	84aa                	mv	s1,a0
    80004292:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004294:	0005b023          	sd	zero,0(a1)
    80004298:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000429c:	c75ff0ef          	jal	ra,80003f10 <filealloc>
    800042a0:	e088                	sd	a0,0(s1)
    800042a2:	cd35                	beqz	a0,8000431e <pipealloc+0x9e>
    800042a4:	c6dff0ef          	jal	ra,80003f10 <filealloc>
    800042a8:	00aa3023          	sd	a0,0(s4)
    800042ac:	c52d                	beqz	a0,80004316 <pipealloc+0x96>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800042ae:	feefc0ef          	jal	ra,80000a9c <kalloc>
    800042b2:	892a                	mv	s2,a0
    800042b4:	cd31                	beqz	a0,80004310 <pipealloc+0x90>
    goto bad;
  pi->readopen = 1;
    800042b6:	4985                	li	s3,1
    800042b8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800042bc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800042c0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800042c4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800042c8:	00003597          	auipc	a1,0x3
    800042cc:	3e858593          	addi	a1,a1,1000 # 800076b0 <syscalls+0x2c0>
    800042d0:	81dfc0ef          	jal	ra,80000aec <initlock>
  (*f0)->type = FD_PIPE;
    800042d4:	609c                	ld	a5,0(s1)
    800042d6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800042da:	609c                	ld	a5,0(s1)
    800042dc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800042e0:	609c                	ld	a5,0(s1)
    800042e2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800042e6:	609c                	ld	a5,0(s1)
    800042e8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800042ec:	000a3783          	ld	a5,0(s4)
    800042f0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800042f4:	000a3783          	ld	a5,0(s4)
    800042f8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800042fc:	000a3783          	ld	a5,0(s4)
    80004300:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004304:	000a3783          	ld	a5,0(s4)
    80004308:	0127b823          	sd	s2,16(a5)
  return 0;
    8000430c:	4501                	li	a0,0
    8000430e:	a005                	j	8000432e <pipealloc+0xae>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004310:	6088                	ld	a0,0(s1)
    80004312:	e501                	bnez	a0,8000431a <pipealloc+0x9a>
    80004314:	a029                	j	8000431e <pipealloc+0x9e>
    80004316:	6088                	ld	a0,0(s1)
    80004318:	c11d                	beqz	a0,8000433e <pipealloc+0xbe>
    fileclose(*f0);
    8000431a:	c9bff0ef          	jal	ra,80003fb4 <fileclose>
  if(*f1)
    8000431e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004322:	557d                	li	a0,-1
  if(*f1)
    80004324:	c789                	beqz	a5,8000432e <pipealloc+0xae>
    fileclose(*f1);
    80004326:	853e                	mv	a0,a5
    80004328:	c8dff0ef          	jal	ra,80003fb4 <fileclose>
  return -1;
    8000432c:	557d                	li	a0,-1
}
    8000432e:	70a2                	ld	ra,40(sp)
    80004330:	7402                	ld	s0,32(sp)
    80004332:	64e2                	ld	s1,24(sp)
    80004334:	6942                	ld	s2,16(sp)
    80004336:	69a2                	ld	s3,8(sp)
    80004338:	6a02                	ld	s4,0(sp)
    8000433a:	6145                	addi	sp,sp,48
    8000433c:	8082                	ret
  return -1;
    8000433e:	557d                	li	a0,-1
    80004340:	b7fd                	j	8000432e <pipealloc+0xae>

0000000080004342 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004342:	1101                	addi	sp,sp,-32
    80004344:	ec06                	sd	ra,24(sp)
    80004346:	e822                	sd	s0,16(sp)
    80004348:	e426                	sd	s1,8(sp)
    8000434a:	e04a                	sd	s2,0(sp)
    8000434c:	1000                	addi	s0,sp,32
    8000434e:	84aa                	mv	s1,a0
    80004350:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004352:	81bfc0ef          	jal	ra,80000b6c <acquire>
  if(writable){
    80004356:	02090763          	beqz	s2,80004384 <pipeclose+0x42>
    pi->writeopen = 0;
    8000435a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000435e:	21848513          	addi	a0,s1,536
    80004362:	b01fd0ef          	jal	ra,80001e62 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004366:	2204b783          	ld	a5,544(s1)
    8000436a:	e785                	bnez	a5,80004392 <pipeclose+0x50>
    release(&pi->lock);
    8000436c:	8526                	mv	a0,s1
    8000436e:	897fc0ef          	jal	ra,80000c04 <release>
    kfree((char*)pi);
    80004372:	8526                	mv	a0,s1
    80004374:	e48fc0ef          	jal	ra,800009bc <kfree>
  } else
    release(&pi->lock);
}
    80004378:	60e2                	ld	ra,24(sp)
    8000437a:	6442                	ld	s0,16(sp)
    8000437c:	64a2                	ld	s1,8(sp)
    8000437e:	6902                	ld	s2,0(sp)
    80004380:	6105                	addi	sp,sp,32
    80004382:	8082                	ret
    pi->readopen = 0;
    80004384:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004388:	21c48513          	addi	a0,s1,540
    8000438c:	ad7fd0ef          	jal	ra,80001e62 <wakeup>
    80004390:	bfd9                	j	80004366 <pipeclose+0x24>
    release(&pi->lock);
    80004392:	8526                	mv	a0,s1
    80004394:	871fc0ef          	jal	ra,80000c04 <release>
}
    80004398:	b7c5                	j	80004378 <pipeclose+0x36>

000000008000439a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000439a:	711d                	addi	sp,sp,-96
    8000439c:	ec86                	sd	ra,88(sp)
    8000439e:	e8a2                	sd	s0,80(sp)
    800043a0:	e4a6                	sd	s1,72(sp)
    800043a2:	e0ca                	sd	s2,64(sp)
    800043a4:	fc4e                	sd	s3,56(sp)
    800043a6:	f852                	sd	s4,48(sp)
    800043a8:	f456                	sd	s5,40(sp)
    800043aa:	f05a                	sd	s6,32(sp)
    800043ac:	ec5e                	sd	s7,24(sp)
    800043ae:	e862                	sd	s8,16(sp)
    800043b0:	1080                	addi	s0,sp,96
    800043b2:	84aa                	mv	s1,a0
    800043b4:	8aae                	mv	s5,a1
    800043b6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800043b8:	c4cfd0ef          	jal	ra,80001804 <myproc>
    800043bc:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800043be:	8526                	mv	a0,s1
    800043c0:	facfc0ef          	jal	ra,80000b6c <acquire>
  while(i < n){
    800043c4:	09405c63          	blez	s4,8000445c <pipewrite+0xc2>
  int i = 0;
    800043c8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800043ca:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800043cc:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800043d0:	21c48b93          	addi	s7,s1,540
    800043d4:	a81d                	j	8000440a <pipewrite+0x70>
      release(&pi->lock);
    800043d6:	8526                	mv	a0,s1
    800043d8:	82dfc0ef          	jal	ra,80000c04 <release>
      return -1;
    800043dc:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800043de:	854a                	mv	a0,s2
    800043e0:	60e6                	ld	ra,88(sp)
    800043e2:	6446                	ld	s0,80(sp)
    800043e4:	64a6                	ld	s1,72(sp)
    800043e6:	6906                	ld	s2,64(sp)
    800043e8:	79e2                	ld	s3,56(sp)
    800043ea:	7a42                	ld	s4,48(sp)
    800043ec:	7aa2                	ld	s5,40(sp)
    800043ee:	7b02                	ld	s6,32(sp)
    800043f0:	6be2                	ld	s7,24(sp)
    800043f2:	6c42                	ld	s8,16(sp)
    800043f4:	6125                	addi	sp,sp,96
    800043f6:	8082                	ret
      wakeup(&pi->nread);
    800043f8:	8562                	mv	a0,s8
    800043fa:	a69fd0ef          	jal	ra,80001e62 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800043fe:	85a6                	mv	a1,s1
    80004400:	855e                	mv	a0,s7
    80004402:	a15fd0ef          	jal	ra,80001e16 <sleep>
  while(i < n){
    80004406:	05495c63          	bge	s2,s4,8000445e <pipewrite+0xc4>
    if(pi->readopen == 0 || killed(pr)){
    8000440a:	2204a783          	lw	a5,544(s1)
    8000440e:	d7e1                	beqz	a5,800043d6 <pipewrite+0x3c>
    80004410:	854e                	mv	a0,s3
    80004412:	c3dfd0ef          	jal	ra,8000204e <killed>
    80004416:	f161                	bnez	a0,800043d6 <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004418:	2184a783          	lw	a5,536(s1)
    8000441c:	21c4a703          	lw	a4,540(s1)
    80004420:	2007879b          	addiw	a5,a5,512
    80004424:	fcf70ae3          	beq	a4,a5,800043f8 <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004428:	4685                	li	a3,1
    8000442a:	01590633          	add	a2,s2,s5
    8000442e:	faf40593          	addi	a1,s0,-81
    80004432:	0509b503          	ld	a0,80(s3)
    80004436:	9e2fd0ef          	jal	ra,80001618 <copyin>
    8000443a:	03650263          	beq	a0,s6,8000445e <pipewrite+0xc4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000443e:	21c4a783          	lw	a5,540(s1)
    80004442:	0017871b          	addiw	a4,a5,1
    80004446:	20e4ae23          	sw	a4,540(s1)
    8000444a:	1ff7f793          	andi	a5,a5,511
    8000444e:	97a6                	add	a5,a5,s1
    80004450:	faf44703          	lbu	a4,-81(s0)
    80004454:	00e78c23          	sb	a4,24(a5)
      i++;
    80004458:	2905                	addiw	s2,s2,1
    8000445a:	b775                	j	80004406 <pipewrite+0x6c>
  int i = 0;
    8000445c:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000445e:	21848513          	addi	a0,s1,536
    80004462:	a01fd0ef          	jal	ra,80001e62 <wakeup>
  release(&pi->lock);
    80004466:	8526                	mv	a0,s1
    80004468:	f9cfc0ef          	jal	ra,80000c04 <release>
  return i;
    8000446c:	bf8d                	j	800043de <pipewrite+0x44>

000000008000446e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
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
    80004480:	0880                	addi	s0,sp,80
    80004482:	84aa                	mv	s1,a0
    80004484:	892e                	mv	s2,a1
    80004486:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004488:	b7cfd0ef          	jal	ra,80001804 <myproc>
    8000448c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000448e:	8526                	mv	a0,s1
    80004490:	edcfc0ef          	jal	ra,80000b6c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004494:	2184a703          	lw	a4,536(s1)
    80004498:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000449c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800044a0:	02f71363          	bne	a4,a5,800044c6 <piperead+0x58>
    800044a4:	2244a783          	lw	a5,548(s1)
    800044a8:	cf99                	beqz	a5,800044c6 <piperead+0x58>
    if(killed(pr)){
    800044aa:	8552                	mv	a0,s4
    800044ac:	ba3fd0ef          	jal	ra,8000204e <killed>
    800044b0:	e149                	bnez	a0,80004532 <piperead+0xc4>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800044b2:	85a6                	mv	a1,s1
    800044b4:	854e                	mv	a0,s3
    800044b6:	961fd0ef          	jal	ra,80001e16 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800044ba:	2184a703          	lw	a4,536(s1)
    800044be:	21c4a783          	lw	a5,540(s1)
    800044c2:	fef701e3          	beq	a4,a5,800044a4 <piperead+0x36>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800044c6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800044c8:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800044ca:	05505263          	blez	s5,8000450e <piperead+0xa0>
    if(pi->nread == pi->nwrite)
    800044ce:	2184a783          	lw	a5,536(s1)
    800044d2:	21c4a703          	lw	a4,540(s1)
    800044d6:	02f70c63          	beq	a4,a5,8000450e <piperead+0xa0>
    ch = pi->data[pi->nread % PIPESIZE];
    800044da:	1ff7f793          	andi	a5,a5,511
    800044de:	97a6                	add	a5,a5,s1
    800044e0:	0187c783          	lbu	a5,24(a5)
    800044e4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800044e8:	4685                	li	a3,1
    800044ea:	fbf40613          	addi	a2,s0,-65
    800044ee:	85ca                	mv	a1,s2
    800044f0:	050a3503          	ld	a0,80(s4)
    800044f4:	85efd0ef          	jal	ra,80001552 <copyout>
    800044f8:	05650263          	beq	a0,s6,8000453c <piperead+0xce>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    800044fc:	2184a783          	lw	a5,536(s1)
    80004500:	2785                	addiw	a5,a5,1
    80004502:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004506:	2985                	addiw	s3,s3,1
    80004508:	0905                	addi	s2,s2,1
    8000450a:	fd3a92e3          	bne	s5,s3,800044ce <piperead+0x60>
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000450e:	21c48513          	addi	a0,s1,540
    80004512:	951fd0ef          	jal	ra,80001e62 <wakeup>
  release(&pi->lock);
    80004516:	8526                	mv	a0,s1
    80004518:	eecfc0ef          	jal	ra,80000c04 <release>
  return i;
}
    8000451c:	854e                	mv	a0,s3
    8000451e:	60a6                	ld	ra,72(sp)
    80004520:	6406                	ld	s0,64(sp)
    80004522:	74e2                	ld	s1,56(sp)
    80004524:	7942                	ld	s2,48(sp)
    80004526:	79a2                	ld	s3,40(sp)
    80004528:	7a02                	ld	s4,32(sp)
    8000452a:	6ae2                	ld	s5,24(sp)
    8000452c:	6b42                	ld	s6,16(sp)
    8000452e:	6161                	addi	sp,sp,80
    80004530:	8082                	ret
      release(&pi->lock);
    80004532:	8526                	mv	a0,s1
    80004534:	ed0fc0ef          	jal	ra,80000c04 <release>
      return -1;
    80004538:	59fd                	li	s3,-1
    8000453a:	b7cd                	j	8000451c <piperead+0xae>
      if(i == 0)
    8000453c:	fc0999e3          	bnez	s3,8000450e <piperead+0xa0>
        i = -1;
    80004540:	89aa                	mv	s3,a0
    80004542:	b7f1                	j	8000450e <piperead+0xa0>

0000000080004544 <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    80004544:	1141                	addi	sp,sp,-16
    80004546:	e422                	sd	s0,8(sp)
    80004548:	0800                	addi	s0,sp,16
    8000454a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000454c:	8905                	andi	a0,a0,1
    8000454e:	c111                	beqz	a0,80004552 <flags2perm+0xe>
      perm = PTE_X;
    80004550:	4521                	li	a0,8
    if(flags & 0x2)
    80004552:	8b89                	andi	a5,a5,2
    80004554:	c399                	beqz	a5,8000455a <flags2perm+0x16>
      perm |= PTE_W;
    80004556:	00456513          	ori	a0,a0,4
    return perm;
}
    8000455a:	6422                	ld	s0,8(sp)
    8000455c:	0141                	addi	sp,sp,16
    8000455e:	8082                	ret

0000000080004560 <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    80004560:	de010113          	addi	sp,sp,-544
    80004564:	20113c23          	sd	ra,536(sp)
    80004568:	20813823          	sd	s0,528(sp)
    8000456c:	20913423          	sd	s1,520(sp)
    80004570:	21213023          	sd	s2,512(sp)
    80004574:	ffce                	sd	s3,504(sp)
    80004576:	fbd2                	sd	s4,496(sp)
    80004578:	f7d6                	sd	s5,488(sp)
    8000457a:	f3da                	sd	s6,480(sp)
    8000457c:	efde                	sd	s7,472(sp)
    8000457e:	ebe2                	sd	s8,464(sp)
    80004580:	e7e6                	sd	s9,456(sp)
    80004582:	e3ea                	sd	s10,448(sp)
    80004584:	ff6e                	sd	s11,440(sp)
    80004586:	1400                	addi	s0,sp,544
    80004588:	892a                	mv	s2,a0
    8000458a:	dea43423          	sd	a0,-536(s0)
    8000458e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004592:	a72fd0ef          	jal	ra,80001804 <myproc>
    80004596:	84aa                	mv	s1,a0

  begin_op();
    80004598:	e0eff0ef          	jal	ra,80003ba6 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    8000459c:	854a                	mv	a0,s2
    8000459e:	c18ff0ef          	jal	ra,800039b6 <namei>
    800045a2:	c13d                	beqz	a0,80004608 <kexec+0xa8>
    800045a4:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800045a6:	c23fe0ef          	jal	ra,800031c8 <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800045aa:	04000713          	li	a4,64
    800045ae:	4681                	li	a3,0
    800045b0:	e5040613          	addi	a2,s0,-432
    800045b4:	4581                	li	a1,0
    800045b6:	8556                	mv	a0,s5
    800045b8:	f9dfe0ef          	jal	ra,80003554 <readi>
    800045bc:	04000793          	li	a5,64
    800045c0:	00f51a63          	bne	a0,a5,800045d4 <kexec+0x74>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    800045c4:	e5042703          	lw	a4,-432(s0)
    800045c8:	464c47b7          	lui	a5,0x464c4
    800045cc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800045d0:	04f70063          	beq	a4,a5,80004610 <kexec+0xb0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800045d4:	8556                	mv	a0,s5
    800045d6:	df9fe0ef          	jal	ra,800033ce <iunlockput>
    end_op();
    800045da:	e3cff0ef          	jal	ra,80003c16 <end_op>
  }
  return -1;
    800045de:	557d                	li	a0,-1
}
    800045e0:	21813083          	ld	ra,536(sp)
    800045e4:	21013403          	ld	s0,528(sp)
    800045e8:	20813483          	ld	s1,520(sp)
    800045ec:	20013903          	ld	s2,512(sp)
    800045f0:	79fe                	ld	s3,504(sp)
    800045f2:	7a5e                	ld	s4,496(sp)
    800045f4:	7abe                	ld	s5,488(sp)
    800045f6:	7b1e                	ld	s6,480(sp)
    800045f8:	6bfe                	ld	s7,472(sp)
    800045fa:	6c5e                	ld	s8,464(sp)
    800045fc:	6cbe                	ld	s9,456(sp)
    800045fe:	6d1e                	ld	s10,448(sp)
    80004600:	7dfa                	ld	s11,440(sp)
    80004602:	22010113          	addi	sp,sp,544
    80004606:	8082                	ret
    end_op();
    80004608:	e0eff0ef          	jal	ra,80003c16 <end_op>
    return -1;
    8000460c:	557d                	li	a0,-1
    8000460e:	bfc9                	j	800045e0 <kexec+0x80>
  if((pagetable = proc_pagetable(p)) == 0)
    80004610:	8526                	mv	a0,s1
    80004612:	af8fd0ef          	jal	ra,8000190a <proc_pagetable>
    80004616:	8b2a                	mv	s6,a0
    80004618:	dd55                	beqz	a0,800045d4 <kexec+0x74>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000461a:	e7042783          	lw	a5,-400(s0)
    8000461e:	e8845703          	lhu	a4,-376(s0)
    80004622:	c325                	beqz	a4,80004682 <kexec+0x122>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004624:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004626:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000462a:	6a05                	lui	s4,0x1
    8000462c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004630:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004634:	6d85                	lui	s11,0x1
    80004636:	7d7d                	lui	s10,0xfffff
    80004638:	a411                	j	8000483c <kexec+0x2dc>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000463a:	00003517          	auipc	a0,0x3
    8000463e:	07e50513          	addi	a0,a0,126 # 800076b8 <syscalls+0x2c8>
    80004642:	948fc0ef          	jal	ra,8000078a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004646:	874a                	mv	a4,s2
    80004648:	009c86bb          	addw	a3,s9,s1
    8000464c:	4581                	li	a1,0
    8000464e:	8556                	mv	a0,s5
    80004650:	f05fe0ef          	jal	ra,80003554 <readi>
    80004654:	2501                	sext.w	a0,a0
    80004656:	18a91263          	bne	s2,a0,800047da <kexec+0x27a>
  for(i = 0; i < sz; i += PGSIZE){
    8000465a:	009d84bb          	addw	s1,s11,s1
    8000465e:	013d09bb          	addw	s3,s10,s3
    80004662:	1b74fd63          	bgeu	s1,s7,8000481c <kexec+0x2bc>
    pa = walkaddr(pagetable, va + i);
    80004666:	02049593          	slli	a1,s1,0x20
    8000466a:	9181                	srli	a1,a1,0x20
    8000466c:	95e2                	add	a1,a1,s8
    8000466e:	855a                	mv	a0,s6
    80004670:	8e7fc0ef          	jal	ra,80000f56 <walkaddr>
    80004674:	862a                	mv	a2,a0
    if(pa == 0)
    80004676:	d171                	beqz	a0,8000463a <kexec+0xda>
      n = PGSIZE;
    80004678:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000467a:	fd49f6e3          	bgeu	s3,s4,80004646 <kexec+0xe6>
      n = sz - i;
    8000467e:	894e                	mv	s2,s3
    80004680:	b7d9                	j	80004646 <kexec+0xe6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004682:	4901                	li	s2,0
  iunlockput(ip);
    80004684:	8556                	mv	a0,s5
    80004686:	d49fe0ef          	jal	ra,800033ce <iunlockput>
  end_op();
    8000468a:	d8cff0ef          	jal	ra,80003c16 <end_op>
  p = myproc();
    8000468e:	976fd0ef          	jal	ra,80001804 <myproc>
    80004692:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004694:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004698:	6785                	lui	a5,0x1
    8000469a:	17fd                	addi	a5,a5,-1
    8000469c:	993e                	add	s2,s2,a5
    8000469e:	77fd                	lui	a5,0xfffff
    800046a0:	00f977b3          	and	a5,s2,a5
    800046a4:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    800046a8:	4691                	li	a3,4
    800046aa:	6609                	lui	a2,0x2
    800046ac:	963e                	add	a2,a2,a5
    800046ae:	85be                	mv	a1,a5
    800046b0:	855a                	mv	a0,s6
    800046b2:	b6ffc0ef          	jal	ra,80001220 <uvmalloc>
    800046b6:	8c2a                	mv	s8,a0
  ip = 0;
    800046b8:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    800046ba:	12050063          	beqz	a0,800047da <kexec+0x27a>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    800046be:	75f9                	lui	a1,0xffffe
    800046c0:	95aa                	add	a1,a1,a0
    800046c2:	855a                	mv	a0,s6
    800046c4:	d23fc0ef          	jal	ra,800013e6 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    800046c8:	7afd                	lui	s5,0xfffff
    800046ca:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800046cc:	df043783          	ld	a5,-528(s0)
    800046d0:	6388                	ld	a0,0(a5)
    800046d2:	c135                	beqz	a0,80004736 <kexec+0x1d6>
    800046d4:	e9040993          	addi	s3,s0,-368
    800046d8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800046dc:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800046de:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800046e0:	ed8fc0ef          	jal	ra,80000db8 <strlen>
    800046e4:	0015079b          	addiw	a5,a0,1
    800046e8:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800046ec:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800046f0:	11596a63          	bltu	s2,s5,80004804 <kexec+0x2a4>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800046f4:	df043d83          	ld	s11,-528(s0)
    800046f8:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800046fc:	8552                	mv	a0,s4
    800046fe:	ebafc0ef          	jal	ra,80000db8 <strlen>
    80004702:	0015069b          	addiw	a3,a0,1
    80004706:	8652                	mv	a2,s4
    80004708:	85ca                	mv	a1,s2
    8000470a:	855a                	mv	a0,s6
    8000470c:	e47fc0ef          	jal	ra,80001552 <copyout>
    80004710:	0e054e63          	bltz	a0,8000480c <kexec+0x2ac>
    ustack[argc] = sp;
    80004714:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004718:	0485                	addi	s1,s1,1
    8000471a:	008d8793          	addi	a5,s11,8
    8000471e:	def43823          	sd	a5,-528(s0)
    80004722:	008db503          	ld	a0,8(s11)
    80004726:	c911                	beqz	a0,8000473a <kexec+0x1da>
    if(argc >= MAXARG)
    80004728:	09a1                	addi	s3,s3,8
    8000472a:	fb3c9be3          	bne	s9,s3,800046e0 <kexec+0x180>
  sz = sz1;
    8000472e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004732:	4a81                	li	s5,0
    80004734:	a05d                	j	800047da <kexec+0x27a>
  sp = sz;
    80004736:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004738:	4481                	li	s1,0
  ustack[argc] = 0;
    8000473a:	00349793          	slli	a5,s1,0x3
    8000473e:	f9040713          	addi	a4,s0,-112
    80004742:	97ba                	add	a5,a5,a4
    80004744:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffde188>
  sp -= (argc+1) * sizeof(uint64);
    80004748:	00148693          	addi	a3,s1,1
    8000474c:	068e                	slli	a3,a3,0x3
    8000474e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004752:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004756:	01597663          	bgeu	s2,s5,80004762 <kexec+0x202>
  sz = sz1;
    8000475a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000475e:	4a81                	li	s5,0
    80004760:	a8ad                	j	800047da <kexec+0x27a>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004762:	e9040613          	addi	a2,s0,-368
    80004766:	85ca                	mv	a1,s2
    80004768:	855a                	mv	a0,s6
    8000476a:	de9fc0ef          	jal	ra,80001552 <copyout>
    8000476e:	0a054363          	bltz	a0,80004814 <kexec+0x2b4>
  p->trapframe->a1 = sp;
    80004772:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004776:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000477a:	de843783          	ld	a5,-536(s0)
    8000477e:	0007c703          	lbu	a4,0(a5)
    80004782:	cf11                	beqz	a4,8000479e <kexec+0x23e>
    80004784:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004786:	02f00693          	li	a3,47
    8000478a:	a039                	j	80004798 <kexec+0x238>
      last = s+1;
    8000478c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004790:	0785                	addi	a5,a5,1
    80004792:	fff7c703          	lbu	a4,-1(a5)
    80004796:	c701                	beqz	a4,8000479e <kexec+0x23e>
    if(*s == '/')
    80004798:	fed71ce3          	bne	a4,a3,80004790 <kexec+0x230>
    8000479c:	bfc5                	j	8000478c <kexec+0x22c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000479e:	4641                	li	a2,16
    800047a0:	de843583          	ld	a1,-536(s0)
    800047a4:	158b8513          	addi	a0,s7,344
    800047a8:	ddefc0ef          	jal	ra,80000d86 <safestrcpy>
  oldpagetable = p->pagetable;
    800047ac:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800047b0:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800047b4:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    800047b8:	058bb783          	ld	a5,88(s7)
    800047bc:	e6843703          	ld	a4,-408(s0)
    800047c0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800047c2:	058bb783          	ld	a5,88(s7)
    800047c6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800047ca:	85ea                	mv	a1,s10
    800047cc:	9c2fd0ef          	jal	ra,8000198e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800047d0:	0004851b          	sext.w	a0,s1
    800047d4:	b531                	j	800045e0 <kexec+0x80>
    800047d6:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800047da:	df843583          	ld	a1,-520(s0)
    800047de:	855a                	mv	a0,s6
    800047e0:	9aefd0ef          	jal	ra,8000198e <proc_freepagetable>
  if(ip){
    800047e4:	de0a98e3          	bnez	s5,800045d4 <kexec+0x74>
  return -1;
    800047e8:	557d                	li	a0,-1
    800047ea:	bbdd                	j	800045e0 <kexec+0x80>
    800047ec:	df243c23          	sd	s2,-520(s0)
    800047f0:	b7ed                	j	800047da <kexec+0x27a>
    800047f2:	df243c23          	sd	s2,-520(s0)
    800047f6:	b7d5                	j	800047da <kexec+0x27a>
    800047f8:	df243c23          	sd	s2,-520(s0)
    800047fc:	bff9                	j	800047da <kexec+0x27a>
    800047fe:	df243c23          	sd	s2,-520(s0)
    80004802:	bfe1                	j	800047da <kexec+0x27a>
  sz = sz1;
    80004804:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004808:	4a81                	li	s5,0
    8000480a:	bfc1                	j	800047da <kexec+0x27a>
  sz = sz1;
    8000480c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004810:	4a81                	li	s5,0
    80004812:	b7e1                	j	800047da <kexec+0x27a>
  sz = sz1;
    80004814:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004818:	4a81                	li	s5,0
    8000481a:	b7c1                	j	800047da <kexec+0x27a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000481c:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004820:	e0843783          	ld	a5,-504(s0)
    80004824:	0017869b          	addiw	a3,a5,1
    80004828:	e0d43423          	sd	a3,-504(s0)
    8000482c:	e0043783          	ld	a5,-512(s0)
    80004830:	0387879b          	addiw	a5,a5,56
    80004834:	e8845703          	lhu	a4,-376(s0)
    80004838:	e4e6d6e3          	bge	a3,a4,80004684 <kexec+0x124>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000483c:	2781                	sext.w	a5,a5
    8000483e:	e0f43023          	sd	a5,-512(s0)
    80004842:	03800713          	li	a4,56
    80004846:	86be                	mv	a3,a5
    80004848:	e1840613          	addi	a2,s0,-488
    8000484c:	4581                	li	a1,0
    8000484e:	8556                	mv	a0,s5
    80004850:	d05fe0ef          	jal	ra,80003554 <readi>
    80004854:	03800793          	li	a5,56
    80004858:	f6f51fe3          	bne	a0,a5,800047d6 <kexec+0x276>
    if(ph.type != ELF_PROG_LOAD)
    8000485c:	e1842783          	lw	a5,-488(s0)
    80004860:	4705                	li	a4,1
    80004862:	fae79fe3          	bne	a5,a4,80004820 <kexec+0x2c0>
    if(ph.memsz < ph.filesz)
    80004866:	e4043483          	ld	s1,-448(s0)
    8000486a:	e3843783          	ld	a5,-456(s0)
    8000486e:	f6f4efe3          	bltu	s1,a5,800047ec <kexec+0x28c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004872:	e2843783          	ld	a5,-472(s0)
    80004876:	94be                	add	s1,s1,a5
    80004878:	f6f4ede3          	bltu	s1,a5,800047f2 <kexec+0x292>
    if(ph.vaddr % PGSIZE != 0)
    8000487c:	de043703          	ld	a4,-544(s0)
    80004880:	8ff9                	and	a5,a5,a4
    80004882:	fbbd                	bnez	a5,800047f8 <kexec+0x298>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004884:	e1c42503          	lw	a0,-484(s0)
    80004888:	cbdff0ef          	jal	ra,80004544 <flags2perm>
    8000488c:	86aa                	mv	a3,a0
    8000488e:	8626                	mv	a2,s1
    80004890:	85ca                	mv	a1,s2
    80004892:	855a                	mv	a0,s6
    80004894:	98dfc0ef          	jal	ra,80001220 <uvmalloc>
    80004898:	dea43c23          	sd	a0,-520(s0)
    8000489c:	d12d                	beqz	a0,800047fe <kexec+0x29e>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000489e:	e2843c03          	ld	s8,-472(s0)
    800048a2:	e2042c83          	lw	s9,-480(s0)
    800048a6:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800048aa:	f60b89e3          	beqz	s7,8000481c <kexec+0x2bc>
    800048ae:	89de                	mv	s3,s7
    800048b0:	4481                	li	s1,0
    800048b2:	bb55                	j	80004666 <kexec+0x106>

00000000800048b4 <argfd>:
#include "fcntl.h"

// 获取第n个系统调用参数作为文件描述符，并返回该描述符及对应的文件结构。
static int
argfd(int n, int *pfd, struct file **pf)
{
    800048b4:	7179                	addi	sp,sp,-48
    800048b6:	f406                	sd	ra,40(sp)
    800048b8:	f022                	sd	s0,32(sp)
    800048ba:	ec26                	sd	s1,24(sp)
    800048bc:	e84a                	sd	s2,16(sp)
    800048be:	1800                	addi	s0,sp,48
    800048c0:	892e                	mv	s2,a1
    800048c2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);  // 获取系统调用参数中的文件描述符
    800048c4:	fdc40593          	addi	a1,s0,-36
    800048c8:	f19fd0ef          	jal	ra,800027e0 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)  // 检查文件描述符的有效性
    800048cc:	fdc42703          	lw	a4,-36(s0)
    800048d0:	47bd                	li	a5,15
    800048d2:	02e7e963          	bltu	a5,a4,80004904 <argfd+0x50>
    800048d6:	f2ffc0ef          	jal	ra,80001804 <myproc>
    800048da:	fdc42703          	lw	a4,-36(s0)
    800048de:	01a70793          	addi	a5,a4,26
    800048e2:	078e                	slli	a5,a5,0x3
    800048e4:	953e                	add	a0,a0,a5
    800048e6:	611c                	ld	a5,0(a0)
    800048e8:	c385                	beqz	a5,80004908 <argfd+0x54>
    return -1;
  if(pfd)
    800048ea:	00090463          	beqz	s2,800048f2 <argfd+0x3e>
    *pfd = fd;
    800048ee:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800048f2:	4501                	li	a0,0
  if(pf)
    800048f4:	c091                	beqz	s1,800048f8 <argfd+0x44>
    *pf = f;
    800048f6:	e09c                	sd	a5,0(s1)
}
    800048f8:	70a2                	ld	ra,40(sp)
    800048fa:	7402                	ld	s0,32(sp)
    800048fc:	64e2                	ld	s1,24(sp)
    800048fe:	6942                	ld	s2,16(sp)
    80004900:	6145                	addi	sp,sp,48
    80004902:	8082                	ret
    return -1;
    80004904:	557d                	li	a0,-1
    80004906:	bfcd                	j	800048f8 <argfd+0x44>
    80004908:	557d                	li	a0,-1
    8000490a:	b7fd                	j	800048f8 <argfd+0x44>

000000008000490c <fdalloc>:

// 为给定文件分配一个文件描述符。
// 成功时接管调用者的文件引用。
static int
fdalloc(struct file *f)
{
    8000490c:	1101                	addi	sp,sp,-32
    8000490e:	ec06                	sd	ra,24(sp)
    80004910:	e822                	sd	s0,16(sp)
    80004912:	e426                	sd	s1,8(sp)
    80004914:	1000                	addi	s0,sp,32
    80004916:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004918:	eedfc0ef          	jal	ra,80001804 <myproc>
    8000491c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000491e:	0d050793          	addi	a5,a0,208
    80004922:	4501                	li	a0,0
    80004924:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){  // 查找一个未使用的文件描述符
    80004926:	6398                	ld	a4,0(a5)
    80004928:	cb19                	beqz	a4,8000493e <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    8000492a:	2505                	addiw	a0,a0,1
    8000492c:	07a1                	addi	a5,a5,8
    8000492e:	fed51ce3          	bne	a0,a3,80004926 <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;  // 没有可用的文件描述符
    80004932:	557d                	li	a0,-1
}
    80004934:	60e2                	ld	ra,24(sp)
    80004936:	6442                	ld	s0,16(sp)
    80004938:	64a2                	ld	s1,8(sp)
    8000493a:	6105                	addi	sp,sp,32
    8000493c:	8082                	ret
      p->ofile[fd] = f;
    8000493e:	01a50793          	addi	a5,a0,26
    80004942:	078e                	slli	a5,a5,0x3
    80004944:	963e                	add	a2,a2,a5
    80004946:	e204                	sd	s1,0(a2)
      return fd;
    80004948:	b7f5                	j	80004934 <fdalloc+0x28>

000000008000494a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000494a:	715d                	addi	sp,sp,-80
    8000494c:	e486                	sd	ra,72(sp)
    8000494e:	e0a2                	sd	s0,64(sp)
    80004950:	fc26                	sd	s1,56(sp)
    80004952:	f84a                	sd	s2,48(sp)
    80004954:	f44e                	sd	s3,40(sp)
    80004956:	f052                	sd	s4,32(sp)
    80004958:	ec56                	sd	s5,24(sp)
    8000495a:	e85a                	sd	s6,16(sp)
    8000495c:	0880                	addi	s0,sp,80
    8000495e:	8b2e                	mv	s6,a1
    80004960:	89b2                	mv	s3,a2
    80004962:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)  // 查找父目录
    80004964:	fb040593          	addi	a1,s0,-80
    80004968:	868ff0ef          	jal	ra,800039d0 <nameiparent>
    8000496c:	84aa                	mv	s1,a0
    8000496e:	10050b63          	beqz	a0,80004a84 <create+0x13a>
    return 0;

  ilock(dp);
    80004972:	857fe0ef          	jal	ra,800031c8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){  // 检查文件是否已存在
    80004976:	4601                	li	a2,0
    80004978:	fb040593          	addi	a1,s0,-80
    8000497c:	8526                	mv	a0,s1
    8000497e:	dd3fe0ef          	jal	ra,80003750 <dirlookup>
    80004982:	8aaa                	mv	s5,a0
    80004984:	c521                	beqz	a0,800049cc <create+0x82>
    iunlockput(dp);
    80004986:	8526                	mv	a0,s1
    80004988:	a47fe0ef          	jal	ra,800033ce <iunlockput>
    ilock(ip);
    8000498c:	8556                	mv	a0,s5
    8000498e:	83bfe0ef          	jal	ra,800031c8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004992:	000b059b          	sext.w	a1,s6
    80004996:	4789                	li	a5,2
    80004998:	02f59563          	bne	a1,a5,800049c2 <create+0x78>
    8000499c:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffde2cc>
    800049a0:	37f9                	addiw	a5,a5,-2
    800049a2:	17c2                	slli	a5,a5,0x30
    800049a4:	93c1                	srli	a5,a5,0x30
    800049a6:	4705                	li	a4,1
    800049a8:	00f76d63          	bltu	a4,a5,800049c2 <create+0x78>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800049ac:	8556                	mv	a0,s5
    800049ae:	60a6                	ld	ra,72(sp)
    800049b0:	6406                	ld	s0,64(sp)
    800049b2:	74e2                	ld	s1,56(sp)
    800049b4:	7942                	ld	s2,48(sp)
    800049b6:	79a2                	ld	s3,40(sp)
    800049b8:	7a02                	ld	s4,32(sp)
    800049ba:	6ae2                	ld	s5,24(sp)
    800049bc:	6b42                	ld	s6,16(sp)
    800049be:	6161                	addi	sp,sp,80
    800049c0:	8082                	ret
    iunlockput(ip);
    800049c2:	8556                	mv	a0,s5
    800049c4:	a0bfe0ef          	jal	ra,800033ce <iunlockput>
    return 0;
    800049c8:	4a81                	li	s5,0
    800049ca:	b7cd                	j	800049ac <create+0x62>
  if((ip = ialloc(dp->dev, type)) == 0){  // 分配 inode
    800049cc:	85da                	mv	a1,s6
    800049ce:	4088                	lw	a0,0(s1)
    800049d0:	e90fe0ef          	jal	ra,80003060 <ialloc>
    800049d4:	8a2a                	mv	s4,a0
    800049d6:	cd1d                	beqz	a0,80004a14 <create+0xca>
  ilock(ip);
    800049d8:	ff0fe0ef          	jal	ra,800031c8 <ilock>
  ip->major = major;
    800049dc:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800049e0:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800049e4:	4905                	li	s2,1
    800049e6:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800049ea:	8552                	mv	a0,s4
    800049ec:	f2afe0ef          	jal	ra,80003116 <iupdate>
  if(type == T_DIR){  // 创建 . 和 .. 目录项
    800049f0:	000b059b          	sext.w	a1,s6
    800049f4:	03258563          	beq	a1,s2,80004a1e <create+0xd4>
  if(dirlink(dp, name, ip->inum) < 0)
    800049f8:	004a2603          	lw	a2,4(s4)
    800049fc:	fb040593          	addi	a1,s0,-80
    80004a00:	8526                	mv	a0,s1
    80004a02:	f1bfe0ef          	jal	ra,8000391c <dirlink>
    80004a06:	06054363          	bltz	a0,80004a6c <create+0x122>
  iunlockput(dp);
    80004a0a:	8526                	mv	a0,s1
    80004a0c:	9c3fe0ef          	jal	ra,800033ce <iunlockput>
  return ip;
    80004a10:	8ad2                	mv	s5,s4
    80004a12:	bf69                	j	800049ac <create+0x62>
    iunlockput(dp);
    80004a14:	8526                	mv	a0,s1
    80004a16:	9b9fe0ef          	jal	ra,800033ce <iunlockput>
    return 0;
    80004a1a:	8ad2                	mv	s5,s4
    80004a1c:	bf41                	j	800049ac <create+0x62>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004a1e:	004a2603          	lw	a2,4(s4)
    80004a22:	00003597          	auipc	a1,0x3
    80004a26:	cb658593          	addi	a1,a1,-842 # 800076d8 <syscalls+0x2e8>
    80004a2a:	8552                	mv	a0,s4
    80004a2c:	ef1fe0ef          	jal	ra,8000391c <dirlink>
    80004a30:	02054e63          	bltz	a0,80004a6c <create+0x122>
    80004a34:	40d0                	lw	a2,4(s1)
    80004a36:	00003597          	auipc	a1,0x3
    80004a3a:	caa58593          	addi	a1,a1,-854 # 800076e0 <syscalls+0x2f0>
    80004a3e:	8552                	mv	a0,s4
    80004a40:	eddfe0ef          	jal	ra,8000391c <dirlink>
    80004a44:	02054463          	bltz	a0,80004a6c <create+0x122>
  if(dirlink(dp, name, ip->inum) < 0)
    80004a48:	004a2603          	lw	a2,4(s4)
    80004a4c:	fb040593          	addi	a1,s0,-80
    80004a50:	8526                	mv	a0,s1
    80004a52:	ecbfe0ef          	jal	ra,8000391c <dirlink>
    80004a56:	00054b63          	bltz	a0,80004a6c <create+0x122>
    dp->nlink++;  // 更新父目录的链接计数
    80004a5a:	04a4d783          	lhu	a5,74(s1)
    80004a5e:	2785                	addiw	a5,a5,1
    80004a60:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004a64:	8526                	mv	a0,s1
    80004a66:	eb0fe0ef          	jal	ra,80003116 <iupdate>
    80004a6a:	b745                	j	80004a0a <create+0xc0>
  ip->nlink = 0;
    80004a6c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004a70:	8552                	mv	a0,s4
    80004a72:	ea4fe0ef          	jal	ra,80003116 <iupdate>
  iunlockput(ip);
    80004a76:	8552                	mv	a0,s4
    80004a78:	957fe0ef          	jal	ra,800033ce <iunlockput>
  iunlockput(dp);
    80004a7c:	8526                	mv	a0,s1
    80004a7e:	951fe0ef          	jal	ra,800033ce <iunlockput>
  return 0;
    80004a82:	b72d                	j	800049ac <create+0x62>
    return 0;
    80004a84:	8aaa                	mv	s5,a0
    80004a86:	b71d                	j	800049ac <create+0x62>

0000000080004a88 <sys_dup>:
{
    80004a88:	7179                	addi	sp,sp,-48
    80004a8a:	f406                	sd	ra,40(sp)
    80004a8c:	f022                	sd	s0,32(sp)
    80004a8e:	ec26                	sd	s1,24(sp)
    80004a90:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004a92:	fd840613          	addi	a2,s0,-40
    80004a96:	4581                	li	a1,0
    80004a98:	4501                	li	a0,0
    80004a9a:	e1bff0ef          	jal	ra,800048b4 <argfd>
    return -1;
    80004a9e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004aa0:	00054f63          	bltz	a0,80004abe <sys_dup+0x36>
  if((fd=fdalloc(f)) < 0)  // 为文件分配新的文件描述符
    80004aa4:	fd843503          	ld	a0,-40(s0)
    80004aa8:	e65ff0ef          	jal	ra,8000490c <fdalloc>
    80004aac:	84aa                	mv	s1,a0
    return -1;
    80004aae:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)  // 为文件分配新的文件描述符
    80004ab0:	00054763          	bltz	a0,80004abe <sys_dup+0x36>
  filedup(f);  // 增加文件引用计数
    80004ab4:	fd843503          	ld	a0,-40(s0)
    80004ab8:	cb6ff0ef          	jal	ra,80003f6e <filedup>
  return fd;
    80004abc:	87a6                	mv	a5,s1
}
    80004abe:	853e                	mv	a0,a5
    80004ac0:	70a2                	ld	ra,40(sp)
    80004ac2:	7402                	ld	s0,32(sp)
    80004ac4:	64e2                	ld	s1,24(sp)
    80004ac6:	6145                	addi	sp,sp,48
    80004ac8:	8082                	ret

0000000080004aca <sys_read>:
{
    80004aca:	7179                	addi	sp,sp,-48
    80004acc:	f406                	sd	ra,40(sp)
    80004ace:	f022                	sd	s0,32(sp)
    80004ad0:	1800                	addi	s0,sp,48
  argaddr(1, &p);  // 获取读取数据的用户空间地址
    80004ad2:	fd840593          	addi	a1,s0,-40
    80004ad6:	4505                	li	a0,1
    80004ad8:	d25fd0ef          	jal	ra,800027fc <argaddr>
  argint(2, &n);  // 获取读取字节数
    80004adc:	fe440593          	addi	a1,s0,-28
    80004ae0:	4509                	li	a0,2
    80004ae2:	cfffd0ef          	jal	ra,800027e0 <argint>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004ae6:	fe840613          	addi	a2,s0,-24
    80004aea:	4581                	li	a1,0
    80004aec:	4501                	li	a0,0
    80004aee:	dc7ff0ef          	jal	ra,800048b4 <argfd>
    80004af2:	87aa                	mv	a5,a0
    return -1;
    80004af4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004af6:	0007ca63          	bltz	a5,80004b0a <sys_read+0x40>
  return fileread(f, p, n);  // 从文件中读取数据
    80004afa:	fe442603          	lw	a2,-28(s0)
    80004afe:	fd843583          	ld	a1,-40(s0)
    80004b02:	fe843503          	ld	a0,-24(s0)
    80004b06:	db4ff0ef          	jal	ra,800040ba <fileread>
}
    80004b0a:	70a2                	ld	ra,40(sp)
    80004b0c:	7402                	ld	s0,32(sp)
    80004b0e:	6145                	addi	sp,sp,48
    80004b10:	8082                	ret

0000000080004b12 <sys_write>:
{
    80004b12:	7179                	addi	sp,sp,-48
    80004b14:	f406                	sd	ra,40(sp)
    80004b16:	f022                	sd	s0,32(sp)
    80004b18:	1800                	addi	s0,sp,48
  argaddr(1, &p);  // 获取写入数据的用户空间地址
    80004b1a:	fd840593          	addi	a1,s0,-40
    80004b1e:	4505                	li	a0,1
    80004b20:	cddfd0ef          	jal	ra,800027fc <argaddr>
  argint(2, &n);  // 获取写入字节数
    80004b24:	fe440593          	addi	a1,s0,-28
    80004b28:	4509                	li	a0,2
    80004b2a:	cb7fd0ef          	jal	ra,800027e0 <argint>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004b2e:	fe840613          	addi	a2,s0,-24
    80004b32:	4581                	li	a1,0
    80004b34:	4501                	li	a0,0
    80004b36:	d7fff0ef          	jal	ra,800048b4 <argfd>
    80004b3a:	87aa                	mv	a5,a0
    return -1;
    80004b3c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004b3e:	0007ca63          	bltz	a5,80004b52 <sys_write+0x40>
  return filewrite(f, p, n);  // 向文件中写入数据
    80004b42:	fe442603          	lw	a2,-28(s0)
    80004b46:	fd843583          	ld	a1,-40(s0)
    80004b4a:	fe843503          	ld	a0,-24(s0)
    80004b4e:	e1aff0ef          	jal	ra,80004168 <filewrite>
}
    80004b52:	70a2                	ld	ra,40(sp)
    80004b54:	7402                	ld	s0,32(sp)
    80004b56:	6145                	addi	sp,sp,48
    80004b58:	8082                	ret

0000000080004b5a <sys_close>:
{
    80004b5a:	1101                	addi	sp,sp,-32
    80004b5c:	ec06                	sd	ra,24(sp)
    80004b5e:	e822                	sd	s0,16(sp)
    80004b60:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)  // 获取文件描述符并返回文件结构
    80004b62:	fe040613          	addi	a2,s0,-32
    80004b66:	fec40593          	addi	a1,s0,-20
    80004b6a:	4501                	li	a0,0
    80004b6c:	d49ff0ef          	jal	ra,800048b4 <argfd>
    return -1;
    80004b70:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)  // 获取文件描述符并返回文件结构
    80004b72:	02054063          	bltz	a0,80004b92 <sys_close+0x38>
  myproc()->ofile[fd] = 0;  // 关闭文件描述符
    80004b76:	c8ffc0ef          	jal	ra,80001804 <myproc>
    80004b7a:	fec42783          	lw	a5,-20(s0)
    80004b7e:	07e9                	addi	a5,a5,26
    80004b80:	078e                	slli	a5,a5,0x3
    80004b82:	97aa                	add	a5,a5,a0
    80004b84:	0007b023          	sd	zero,0(a5)
  fileclose(f);  // 关闭文件
    80004b88:	fe043503          	ld	a0,-32(s0)
    80004b8c:	c28ff0ef          	jal	ra,80003fb4 <fileclose>
  return 0;
    80004b90:	4781                	li	a5,0
}
    80004b92:	853e                	mv	a0,a5
    80004b94:	60e2                	ld	ra,24(sp)
    80004b96:	6442                	ld	s0,16(sp)
    80004b98:	6105                	addi	sp,sp,32
    80004b9a:	8082                	ret

0000000080004b9c <sys_fstat>:
{
    80004b9c:	1101                	addi	sp,sp,-32
    80004b9e:	ec06                	sd	ra,24(sp)
    80004ba0:	e822                	sd	s0,16(sp)
    80004ba2:	1000                	addi	s0,sp,32
  argaddr(1, &st);  // 获取 stat 结构体地址
    80004ba4:	fe040593          	addi	a1,s0,-32
    80004ba8:	4505                	li	a0,1
    80004baa:	c53fd0ef          	jal	ra,800027fc <argaddr>
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004bae:	fe840613          	addi	a2,s0,-24
    80004bb2:	4581                	li	a1,0
    80004bb4:	4501                	li	a0,0
    80004bb6:	cffff0ef          	jal	ra,800048b4 <argfd>
    80004bba:	87aa                	mv	a5,a0
    return -1;
    80004bbc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    80004bbe:	0007c863          	bltz	a5,80004bce <sys_fstat+0x32>
  return filestat(f, st);  // 获取文件状态信息
    80004bc2:	fe043583          	ld	a1,-32(s0)
    80004bc6:	fe843503          	ld	a0,-24(s0)
    80004bca:	c92ff0ef          	jal	ra,8000405c <filestat>
}
    80004bce:	60e2                	ld	ra,24(sp)
    80004bd0:	6442                	ld	s0,16(sp)
    80004bd2:	6105                	addi	sp,sp,32
    80004bd4:	8082                	ret

0000000080004bd6 <sys_link>:
{
    80004bd6:	7169                	addi	sp,sp,-304
    80004bd8:	f606                	sd	ra,296(sp)
    80004bda:	f222                	sd	s0,288(sp)
    80004bdc:	ee26                	sd	s1,280(sp)
    80004bde:	ea4a                	sd	s2,272(sp)
    80004be0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004be2:	08000613          	li	a2,128
    80004be6:	ed040593          	addi	a1,s0,-304
    80004bea:	4501                	li	a0,0
    80004bec:	c2dfd0ef          	jal	ra,80002818 <argstr>
    return -1;
    80004bf0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004bf2:	0c054663          	bltz	a0,80004cbe <sys_link+0xe8>
    80004bf6:	08000613          	li	a2,128
    80004bfa:	f5040593          	addi	a1,s0,-176
    80004bfe:	4505                	li	a0,1
    80004c00:	c19fd0ef          	jal	ra,80002818 <argstr>
    return -1;
    80004c04:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004c06:	0a054c63          	bltz	a0,80004cbe <sys_link+0xe8>
  begin_op();
    80004c0a:	f9dfe0ef          	jal	ra,80003ba6 <begin_op>
  if((ip = namei(old)) == 0){  // 查找 old 路径对应的 inode
    80004c0e:	ed040513          	addi	a0,s0,-304
    80004c12:	da5fe0ef          	jal	ra,800039b6 <namei>
    80004c16:	84aa                	mv	s1,a0
    80004c18:	c525                	beqz	a0,80004c80 <sys_link+0xaa>
  ilock(ip);
    80004c1a:	daefe0ef          	jal	ra,800031c8 <ilock>
  if(ip->type == T_DIR){  // 如果是目录，不能创建链接
    80004c1e:	04449703          	lh	a4,68(s1)
    80004c22:	4785                	li	a5,1
    80004c24:	06f70263          	beq	a4,a5,80004c88 <sys_link+0xb2>
  ip->nlink++;  // 增加链接计数
    80004c28:	04a4d783          	lhu	a5,74(s1)
    80004c2c:	2785                	addiw	a5,a5,1
    80004c2e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004c32:	8526                	mv	a0,s1
    80004c34:	ce2fe0ef          	jal	ra,80003116 <iupdate>
  iunlock(ip);
    80004c38:	8526                	mv	a0,s1
    80004c3a:	e38fe0ef          	jal	ra,80003272 <iunlock>
  if((dp = nameiparent(new, name)) == 0)  // 获取 new 路径的父目录
    80004c3e:	fd040593          	addi	a1,s0,-48
    80004c42:	f5040513          	addi	a0,s0,-176
    80004c46:	d8bfe0ef          	jal	ra,800039d0 <nameiparent>
    80004c4a:	892a                	mv	s2,a0
    80004c4c:	c921                	beqz	a0,80004c9c <sys_link+0xc6>
  ilock(dp);
    80004c4e:	d7afe0ef          	jal	ra,800031c8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){  // 在父目录中创建新链接
    80004c52:	00092703          	lw	a4,0(s2)
    80004c56:	409c                	lw	a5,0(s1)
    80004c58:	02f71f63          	bne	a4,a5,80004c96 <sys_link+0xc0>
    80004c5c:	40d0                	lw	a2,4(s1)
    80004c5e:	fd040593          	addi	a1,s0,-48
    80004c62:	854a                	mv	a0,s2
    80004c64:	cb9fe0ef          	jal	ra,8000391c <dirlink>
    80004c68:	02054763          	bltz	a0,80004c96 <sys_link+0xc0>
  iunlockput(dp);
    80004c6c:	854a                	mv	a0,s2
    80004c6e:	f60fe0ef          	jal	ra,800033ce <iunlockput>
  iput(ip);
    80004c72:	8526                	mv	a0,s1
    80004c74:	ed2fe0ef          	jal	ra,80003346 <iput>
  end_op();
    80004c78:	f9ffe0ef          	jal	ra,80003c16 <end_op>
  return 0;
    80004c7c:	4781                	li	a5,0
    80004c7e:	a081                	j	80004cbe <sys_link+0xe8>
    end_op();
    80004c80:	f97fe0ef          	jal	ra,80003c16 <end_op>
    return -1;
    80004c84:	57fd                	li	a5,-1
    80004c86:	a825                	j	80004cbe <sys_link+0xe8>
    iunlockput(ip);
    80004c88:	8526                	mv	a0,s1
    80004c8a:	f44fe0ef          	jal	ra,800033ce <iunlockput>
    end_op();
    80004c8e:	f89fe0ef          	jal	ra,80003c16 <end_op>
    return -1;
    80004c92:	57fd                	li	a5,-1
    80004c94:	a02d                	j	80004cbe <sys_link+0xe8>
    iunlockput(dp);
    80004c96:	854a                	mv	a0,s2
    80004c98:	f36fe0ef          	jal	ra,800033ce <iunlockput>
  ilock(ip);
    80004c9c:	8526                	mv	a0,s1
    80004c9e:	d2afe0ef          	jal	ra,800031c8 <ilock>
  ip->nlink--;  // 发生错误，恢复链接计数
    80004ca2:	04a4d783          	lhu	a5,74(s1)
    80004ca6:	37fd                	addiw	a5,a5,-1
    80004ca8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004cac:	8526                	mv	a0,s1
    80004cae:	c68fe0ef          	jal	ra,80003116 <iupdate>
  iunlockput(ip);
    80004cb2:	8526                	mv	a0,s1
    80004cb4:	f1afe0ef          	jal	ra,800033ce <iunlockput>
  end_op();
    80004cb8:	f5ffe0ef          	jal	ra,80003c16 <end_op>
  return -1;
    80004cbc:	57fd                	li	a5,-1
}
    80004cbe:	853e                	mv	a0,a5
    80004cc0:	70b2                	ld	ra,296(sp)
    80004cc2:	7412                	ld	s0,288(sp)
    80004cc4:	64f2                	ld	s1,280(sp)
    80004cc6:	6952                	ld	s2,272(sp)
    80004cc8:	6155                	addi	sp,sp,304
    80004cca:	8082                	ret

0000000080004ccc <sys_unlink>:
{
    80004ccc:	7151                	addi	sp,sp,-240
    80004cce:	f586                	sd	ra,232(sp)
    80004cd0:	f1a2                	sd	s0,224(sp)
    80004cd2:	eda6                	sd	s1,216(sp)
    80004cd4:	e9ca                	sd	s2,208(sp)
    80004cd6:	e5ce                	sd	s3,200(sp)
    80004cd8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)  // 获取路径
    80004cda:	08000613          	li	a2,128
    80004cde:	f3040593          	addi	a1,s0,-208
    80004ce2:	4501                	li	a0,0
    80004ce4:	b35fd0ef          	jal	ra,80002818 <argstr>
    80004ce8:	12054b63          	bltz	a0,80004e1e <sys_unlink+0x152>
  begin_op();
    80004cec:	ebbfe0ef          	jal	ra,80003ba6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){  // 查找路径的父目录
    80004cf0:	fb040593          	addi	a1,s0,-80
    80004cf4:	f3040513          	addi	a0,s0,-208
    80004cf8:	cd9fe0ef          	jal	ra,800039d0 <nameiparent>
    80004cfc:	84aa                	mv	s1,a0
    80004cfe:	c54d                	beqz	a0,80004da8 <sys_unlink+0xdc>
  ilock(dp);
    80004d00:	cc8fe0ef          	jal	ra,800031c8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004d04:	00003597          	auipc	a1,0x3
    80004d08:	9d458593          	addi	a1,a1,-1580 # 800076d8 <syscalls+0x2e8>
    80004d0c:	fb040513          	addi	a0,s0,-80
    80004d10:	a2bfe0ef          	jal	ra,8000373a <namecmp>
    80004d14:	10050a63          	beqz	a0,80004e28 <sys_unlink+0x15c>
    80004d18:	00003597          	auipc	a1,0x3
    80004d1c:	9c858593          	addi	a1,a1,-1592 # 800076e0 <syscalls+0x2f0>
    80004d20:	fb040513          	addi	a0,s0,-80
    80004d24:	a17fe0ef          	jal	ra,8000373a <namecmp>
    80004d28:	10050063          	beqz	a0,80004e28 <sys_unlink+0x15c>
  if((ip = dirlookup(dp, name, &off)) == 0)  // 查找目录项
    80004d2c:	f2c40613          	addi	a2,s0,-212
    80004d30:	fb040593          	addi	a1,s0,-80
    80004d34:	8526                	mv	a0,s1
    80004d36:	a1bfe0ef          	jal	ra,80003750 <dirlookup>
    80004d3a:	892a                	mv	s2,a0
    80004d3c:	0e050663          	beqz	a0,80004e28 <sys_unlink+0x15c>
  ilock(ip);
    80004d40:	c88fe0ef          	jal	ra,800031c8 <ilock>
  if(ip->nlink < 1)
    80004d44:	04a91783          	lh	a5,74(s2)
    80004d48:	06f05463          	blez	a5,80004db0 <sys_unlink+0xe4>
  if(ip->type == T_DIR && !isdirempty(ip)){  // 如果是非空目录，不能删除
    80004d4c:	04491703          	lh	a4,68(s2)
    80004d50:	4785                	li	a5,1
    80004d52:	06f70563          	beq	a4,a5,80004dbc <sys_unlink+0xf0>
  memset(&de, 0, sizeof(de));  // 清空目录项
    80004d56:	4641                	li	a2,16
    80004d58:	4581                	li	a1,0
    80004d5a:	fc040513          	addi	a0,s0,-64
    80004d5e:	ee3fb0ef          	jal	ra,80000c40 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))  // 删除目录项
    80004d62:	4741                	li	a4,16
    80004d64:	f2c42683          	lw	a3,-212(s0)
    80004d68:	fc040613          	addi	a2,s0,-64
    80004d6c:	4581                	li	a1,0
    80004d6e:	8526                	mv	a0,s1
    80004d70:	8c9fe0ef          	jal	ra,80003638 <writei>
    80004d74:	47c1                	li	a5,16
    80004d76:	08f51563          	bne	a0,a5,80004e00 <sys_unlink+0x134>
  if(ip->type == T_DIR){
    80004d7a:	04491703          	lh	a4,68(s2)
    80004d7e:	4785                	li	a5,1
    80004d80:	08f70663          	beq	a4,a5,80004e0c <sys_unlink+0x140>
  iunlockput(dp);
    80004d84:	8526                	mv	a0,s1
    80004d86:	e48fe0ef          	jal	ra,800033ce <iunlockput>
  ip->nlink--;  // 更新目标文件的链接计数
    80004d8a:	04a95783          	lhu	a5,74(s2)
    80004d8e:	37fd                	addiw	a5,a5,-1
    80004d90:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80004d94:	854a                	mv	a0,s2
    80004d96:	b80fe0ef          	jal	ra,80003116 <iupdate>
  iunlockput(ip);
    80004d9a:	854a                	mv	a0,s2
    80004d9c:	e32fe0ef          	jal	ra,800033ce <iunlockput>
  end_op();
    80004da0:	e77fe0ef          	jal	ra,80003c16 <end_op>
  return 0;
    80004da4:	4501                	li	a0,0
    80004da6:	a079                	j	80004e34 <sys_unlink+0x168>
    end_op();
    80004da8:	e6ffe0ef          	jal	ra,80003c16 <end_op>
    return -1;
    80004dac:	557d                	li	a0,-1
    80004dae:	a059                	j	80004e34 <sys_unlink+0x168>
    panic("unlink: nlink < 1");  // 检查链接计数
    80004db0:	00003517          	auipc	a0,0x3
    80004db4:	93850513          	addi	a0,a0,-1736 # 800076e8 <syscalls+0x2f8>
    80004db8:	9d3fb0ef          	jal	ra,8000078a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){  // 跳过 "." 和 ".."
    80004dbc:	04c92703          	lw	a4,76(s2)
    80004dc0:	02000793          	li	a5,32
    80004dc4:	f8e7f9e3          	bgeu	a5,a4,80004d56 <sys_unlink+0x8a>
    80004dc8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004dcc:	4741                	li	a4,16
    80004dce:	86ce                	mv	a3,s3
    80004dd0:	f1840613          	addi	a2,s0,-232
    80004dd4:	4581                	li	a1,0
    80004dd6:	854a                	mv	a0,s2
    80004dd8:	f7cfe0ef          	jal	ra,80003554 <readi>
    80004ddc:	47c1                	li	a5,16
    80004dde:	00f51b63          	bne	a0,a5,80004df4 <sys_unlink+0x128>
    if(de.inum != 0)  // 如果目录项不为空
    80004de2:	f1845783          	lhu	a5,-232(s0)
    80004de6:	ef95                	bnez	a5,80004e22 <sys_unlink+0x156>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){  // 跳过 "." 和 ".."
    80004de8:	29c1                	addiw	s3,s3,16
    80004dea:	04c92783          	lw	a5,76(s2)
    80004dee:	fcf9efe3          	bltu	s3,a5,80004dcc <sys_unlink+0x100>
    80004df2:	b795                	j	80004d56 <sys_unlink+0x8a>
      panic("isdirempty: readi");
    80004df4:	00003517          	auipc	a0,0x3
    80004df8:	90c50513          	addi	a0,a0,-1780 # 80007700 <syscalls+0x310>
    80004dfc:	98ffb0ef          	jal	ra,8000078a <panic>
    panic("unlink: writei");
    80004e00:	00003517          	auipc	a0,0x3
    80004e04:	91850513          	addi	a0,a0,-1768 # 80007718 <syscalls+0x328>
    80004e08:	983fb0ef          	jal	ra,8000078a <panic>
    dp->nlink--;  // 更新父目录的链接计数
    80004e0c:	04a4d783          	lhu	a5,74(s1)
    80004e10:	37fd                	addiw	a5,a5,-1
    80004e12:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004e16:	8526                	mv	a0,s1
    80004e18:	afefe0ef          	jal	ra,80003116 <iupdate>
    80004e1c:	b7a5                	j	80004d84 <sys_unlink+0xb8>
    return -1;
    80004e1e:	557d                	li	a0,-1
    80004e20:	a811                	j	80004e34 <sys_unlink+0x168>
    iunlockput(ip);
    80004e22:	854a                	mv	a0,s2
    80004e24:	daafe0ef          	jal	ra,800033ce <iunlockput>
  iunlockput(dp);
    80004e28:	8526                	mv	a0,s1
    80004e2a:	da4fe0ef          	jal	ra,800033ce <iunlockput>
  end_op();
    80004e2e:	de9fe0ef          	jal	ra,80003c16 <end_op>
  return -1;
    80004e32:	557d                	li	a0,-1
}
    80004e34:	70ae                	ld	ra,232(sp)
    80004e36:	740e                	ld	s0,224(sp)
    80004e38:	64ee                	ld	s1,216(sp)
    80004e3a:	694e                	ld	s2,208(sp)
    80004e3c:	69ae                	ld	s3,200(sp)
    80004e3e:	616d                	addi	sp,sp,240
    80004e40:	8082                	ret

0000000080004e42 <sys_open>:

uint64
sys_open(void)
{
    80004e42:	7131                	addi	sp,sp,-192
    80004e44:	fd06                	sd	ra,184(sp)
    80004e46:	f922                	sd	s0,176(sp)
    80004e48:	f526                	sd	s1,168(sp)
    80004e4a:	f14a                	sd	s2,160(sp)
    80004e4c:	ed4e                	sd	s3,152(sp)
    80004e4e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);  // 获取打开文件的模式
    80004e50:	f4c40593          	addi	a1,s0,-180
    80004e54:	4505                	li	a0,1
    80004e56:	98bfd0ef          	jal	ra,800027e0 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)  // 获取路径
    80004e5a:	08000613          	li	a2,128
    80004e5e:	f5040593          	addi	a1,s0,-176
    80004e62:	4501                	li	a0,0
    80004e64:	9b5fd0ef          	jal	ra,80002818 <argstr>
    80004e68:	87aa                	mv	a5,a0
    return -1;
    80004e6a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)  // 获取路径
    80004e6c:	0807cd63          	bltz	a5,80004f06 <sys_open+0xc4>

  begin_op();
    80004e70:	d37fe0ef          	jal	ra,80003ba6 <begin_op>

  if(omode & O_CREATE){  // 如果是创建文件
    80004e74:	f4c42783          	lw	a5,-180(s0)
    80004e78:	2007f793          	andi	a5,a5,512
    80004e7c:	c3c5                	beqz	a5,80004f1c <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    80004e7e:	4681                	li	a3,0
    80004e80:	4601                	li	a2,0
    80004e82:	4589                	li	a1,2
    80004e84:	f5040513          	addi	a0,s0,-176
    80004e88:	ac3ff0ef          	jal	ra,8000494a <create>
    80004e8c:	84aa                	mv	s1,a0
    if(ip == 0){
    80004e8e:	c159                	beqz	a0,80004f14 <sys_open+0xd2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80004e90:	04449703          	lh	a4,68(s1)
    80004e94:	478d                	li	a5,3
    80004e96:	00f71763          	bne	a4,a5,80004ea4 <sys_open+0x62>
    80004e9a:	0464d703          	lhu	a4,70(s1)
    80004e9e:	47a5                	li	a5,9
    80004ea0:	0ae7e963          	bltu	a5,a4,80004f52 <sys_open+0x110>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){  // 分配文件描述符
    80004ea4:	86cff0ef          	jal	ra,80003f10 <filealloc>
    80004ea8:	89aa                	mv	s3,a0
    80004eaa:	0c050963          	beqz	a0,80004f7c <sys_open+0x13a>
    80004eae:	a5fff0ef          	jal	ra,8000490c <fdalloc>
    80004eb2:	892a                	mv	s2,a0
    80004eb4:	0c054163          	bltz	a0,80004f76 <sys_open+0x134>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80004eb8:	04449703          	lh	a4,68(s1)
    80004ebc:	478d                	li	a5,3
    80004ebe:	0af70163          	beq	a4,a5,80004f60 <sys_open+0x11e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80004ec2:	4789                	li	a5,2
    80004ec4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80004ec8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80004ecc:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80004ed0:	f4c42783          	lw	a5,-180(s0)
    80004ed4:	0017c713          	xori	a4,a5,1
    80004ed8:	8b05                	andi	a4,a4,1
    80004eda:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80004ede:	0037f713          	andi	a4,a5,3
    80004ee2:	00e03733          	snez	a4,a4
    80004ee6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){  // 如果是 O_TRUNC 模式，截断文件
    80004eea:	4007f793          	andi	a5,a5,1024
    80004eee:	c791                	beqz	a5,80004efa <sys_open+0xb8>
    80004ef0:	04449703          	lh	a4,68(s1)
    80004ef4:	4789                	li	a5,2
    80004ef6:	06f70c63          	beq	a4,a5,80004f6e <sys_open+0x12c>
    itrunc(ip);
  }

  iunlock(ip);
    80004efa:	8526                	mv	a0,s1
    80004efc:	b76fe0ef          	jal	ra,80003272 <iunlock>
  end_op();
    80004f00:	d17fe0ef          	jal	ra,80003c16 <end_op>

  return fd;
    80004f04:	854a                	mv	a0,s2
}
    80004f06:	70ea                	ld	ra,184(sp)
    80004f08:	744a                	ld	s0,176(sp)
    80004f0a:	74aa                	ld	s1,168(sp)
    80004f0c:	790a                	ld	s2,160(sp)
    80004f0e:	69ea                	ld	s3,152(sp)
    80004f10:	6129                	addi	sp,sp,192
    80004f12:	8082                	ret
      end_op();
    80004f14:	d03fe0ef          	jal	ra,80003c16 <end_op>
      return -1;
    80004f18:	557d                	li	a0,-1
    80004f1a:	b7f5                	j	80004f06 <sys_open+0xc4>
    if((ip = namei(path)) == 0){
    80004f1c:	f5040513          	addi	a0,s0,-176
    80004f20:	a97fe0ef          	jal	ra,800039b6 <namei>
    80004f24:	84aa                	mv	s1,a0
    80004f26:	c115                	beqz	a0,80004f4a <sys_open+0x108>
    ilock(ip);
    80004f28:	aa0fe0ef          	jal	ra,800031c8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){  // 不能用非读模式打开目录
    80004f2c:	04449703          	lh	a4,68(s1)
    80004f30:	4785                	li	a5,1
    80004f32:	f4f71fe3          	bne	a4,a5,80004e90 <sys_open+0x4e>
    80004f36:	f4c42783          	lw	a5,-180(s0)
    80004f3a:	d7ad                	beqz	a5,80004ea4 <sys_open+0x62>
      iunlockput(ip);
    80004f3c:	8526                	mv	a0,s1
    80004f3e:	c90fe0ef          	jal	ra,800033ce <iunlockput>
      end_op();
    80004f42:	cd5fe0ef          	jal	ra,80003c16 <end_op>
      return -1;
    80004f46:	557d                	li	a0,-1
    80004f48:	bf7d                	j	80004f06 <sys_open+0xc4>
      end_op();
    80004f4a:	ccdfe0ef          	jal	ra,80003c16 <end_op>
      return -1;
    80004f4e:	557d                	li	a0,-1
    80004f50:	bf5d                	j	80004f06 <sys_open+0xc4>
    iunlockput(ip);
    80004f52:	8526                	mv	a0,s1
    80004f54:	c7afe0ef          	jal	ra,800033ce <iunlockput>
    end_op();
    80004f58:	cbffe0ef          	jal	ra,80003c16 <end_op>
    return -1;
    80004f5c:	557d                	li	a0,-1
    80004f5e:	b765                	j	80004f06 <sys_open+0xc4>
    f->type = FD_DEVICE;
    80004f60:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80004f64:	04649783          	lh	a5,70(s1)
    80004f68:	02f99223          	sh	a5,36(s3)
    80004f6c:	b785                	j	80004ecc <sys_open+0x8a>
    itrunc(ip);
    80004f6e:	8526                	mv	a0,s1
    80004f70:	b42fe0ef          	jal	ra,800032b2 <itrunc>
    80004f74:	b759                	j	80004efa <sys_open+0xb8>
      fileclose(f);
    80004f76:	854e                	mv	a0,s3
    80004f78:	83cff0ef          	jal	ra,80003fb4 <fileclose>
    iunlockput(ip);
    80004f7c:	8526                	mv	a0,s1
    80004f7e:	c50fe0ef          	jal	ra,800033ce <iunlockput>
    end_op();
    80004f82:	c95fe0ef          	jal	ra,80003c16 <end_op>
    return -1;
    80004f86:	557d                	li	a0,-1
    80004f88:	bfbd                	j	80004f06 <sys_open+0xc4>

0000000080004f8a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80004f8a:	7175                	addi	sp,sp,-144
    80004f8c:	e506                	sd	ra,136(sp)
    80004f8e:	e122                	sd	s0,128(sp)
    80004f90:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80004f92:	c15fe0ef          	jal	ra,80003ba6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80004f96:	08000613          	li	a2,128
    80004f9a:	f7040593          	addi	a1,s0,-144
    80004f9e:	4501                	li	a0,0
    80004fa0:	879fd0ef          	jal	ra,80002818 <argstr>
    80004fa4:	02054363          	bltz	a0,80004fca <sys_mkdir+0x40>
    80004fa8:	4681                	li	a3,0
    80004faa:	4601                	li	a2,0
    80004fac:	4585                	li	a1,1
    80004fae:	f7040513          	addi	a0,s0,-144
    80004fb2:	999ff0ef          	jal	ra,8000494a <create>
    80004fb6:	c911                	beqz	a0,80004fca <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80004fb8:	c16fe0ef          	jal	ra,800033ce <iunlockput>
  end_op();
    80004fbc:	c5bfe0ef          	jal	ra,80003c16 <end_op>
  return 0;
    80004fc0:	4501                	li	a0,0
}
    80004fc2:	60aa                	ld	ra,136(sp)
    80004fc4:	640a                	ld	s0,128(sp)
    80004fc6:	6149                	addi	sp,sp,144
    80004fc8:	8082                	ret
    end_op();
    80004fca:	c4dfe0ef          	jal	ra,80003c16 <end_op>
    return -1;
    80004fce:	557d                	li	a0,-1
    80004fd0:	bfcd                	j	80004fc2 <sys_mkdir+0x38>

0000000080004fd2 <sys_mknod>:

uint64
sys_mknod(void)
{
    80004fd2:	7135                	addi	sp,sp,-160
    80004fd4:	ed06                	sd	ra,152(sp)
    80004fd6:	e922                	sd	s0,144(sp)
    80004fd8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80004fda:	bcdfe0ef          	jal	ra,80003ba6 <begin_op>
  argint(1, &major);
    80004fde:	f6c40593          	addi	a1,s0,-148
    80004fe2:	4505                	li	a0,1
    80004fe4:	ffcfd0ef          	jal	ra,800027e0 <argint>
  argint(2, &minor);
    80004fe8:	f6840593          	addi	a1,s0,-152
    80004fec:	4509                	li	a0,2
    80004fee:	ff2fd0ef          	jal	ra,800027e0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80004ff2:	08000613          	li	a2,128
    80004ff6:	f7040593          	addi	a1,s0,-144
    80004ffa:	4501                	li	a0,0
    80004ffc:	81dfd0ef          	jal	ra,80002818 <argstr>
    80005000:	02054563          	bltz	a0,8000502a <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005004:	f6841683          	lh	a3,-152(s0)
    80005008:	f6c41603          	lh	a2,-148(s0)
    8000500c:	458d                	li	a1,3
    8000500e:	f7040513          	addi	a0,s0,-144
    80005012:	939ff0ef          	jal	ra,8000494a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005016:	c911                	beqz	a0,8000502a <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005018:	bb6fe0ef          	jal	ra,800033ce <iunlockput>
  end_op();
    8000501c:	bfbfe0ef          	jal	ra,80003c16 <end_op>
  return 0;
    80005020:	4501                	li	a0,0
}
    80005022:	60ea                	ld	ra,152(sp)
    80005024:	644a                	ld	s0,144(sp)
    80005026:	610d                	addi	sp,sp,160
    80005028:	8082                	ret
    end_op();
    8000502a:	bedfe0ef          	jal	ra,80003c16 <end_op>
    return -1;
    8000502e:	557d                	li	a0,-1
    80005030:	bfcd                	j	80005022 <sys_mknod+0x50>

0000000080005032 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005032:	7135                	addi	sp,sp,-160
    80005034:	ed06                	sd	ra,152(sp)
    80005036:	e922                	sd	s0,144(sp)
    80005038:	e526                	sd	s1,136(sp)
    8000503a:	e14a                	sd	s2,128(sp)
    8000503c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000503e:	fc6fc0ef          	jal	ra,80001804 <myproc>
    80005042:	892a                	mv	s2,a0
  
  begin_op();
    80005044:	b63fe0ef          	jal	ra,80003ba6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005048:	08000613          	li	a2,128
    8000504c:	f6040593          	addi	a1,s0,-160
    80005050:	4501                	li	a0,0
    80005052:	fc6fd0ef          	jal	ra,80002818 <argstr>
    80005056:	04054163          	bltz	a0,80005098 <sys_chdir+0x66>
    8000505a:	f6040513          	addi	a0,s0,-160
    8000505e:	959fe0ef          	jal	ra,800039b6 <namei>
    80005062:	84aa                	mv	s1,a0
    80005064:	c915                	beqz	a0,80005098 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    80005066:	962fe0ef          	jal	ra,800031c8 <ilock>
  if(ip->type != T_DIR){  // 必须是目录类型
    8000506a:	04449703          	lh	a4,68(s1)
    8000506e:	4785                	li	a5,1
    80005070:	02f71863          	bne	a4,a5,800050a0 <sys_chdir+0x6e>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005074:	8526                	mv	a0,s1
    80005076:	9fcfe0ef          	jal	ra,80003272 <iunlock>
  iput(p->cwd);  // 释放当前工作目录
    8000507a:	15093503          	ld	a0,336(s2)
    8000507e:	ac8fe0ef          	jal	ra,80003346 <iput>
  end_op();
    80005082:	b95fe0ef          	jal	ra,80003c16 <end_op>
  p->cwd = ip;  // 更新为新的工作目录
    80005086:	14993823          	sd	s1,336(s2)
  return 0;
    8000508a:	4501                	li	a0,0
}
    8000508c:	60ea                	ld	ra,152(sp)
    8000508e:	644a                	ld	s0,144(sp)
    80005090:	64aa                	ld	s1,136(sp)
    80005092:	690a                	ld	s2,128(sp)
    80005094:	610d                	addi	sp,sp,160
    80005096:	8082                	ret
    end_op();
    80005098:	b7ffe0ef          	jal	ra,80003c16 <end_op>
    return -1;
    8000509c:	557d                	li	a0,-1
    8000509e:	b7fd                	j	8000508c <sys_chdir+0x5a>
    iunlockput(ip);
    800050a0:	8526                	mv	a0,s1
    800050a2:	b2cfe0ef          	jal	ra,800033ce <iunlockput>
    end_op();
    800050a6:	b71fe0ef          	jal	ra,80003c16 <end_op>
    return -1;
    800050aa:	557d                	li	a0,-1
    800050ac:	b7c5                	j	8000508c <sys_chdir+0x5a>

00000000800050ae <sys_exec>:

uint64
sys_exec(void)
{
    800050ae:	7145                	addi	sp,sp,-464
    800050b0:	e786                	sd	ra,456(sp)
    800050b2:	e3a2                	sd	s0,448(sp)
    800050b4:	ff26                	sd	s1,440(sp)
    800050b6:	fb4a                	sd	s2,432(sp)
    800050b8:	f74e                	sd	s3,424(sp)
    800050ba:	f352                	sd	s4,416(sp)
    800050bc:	ef56                	sd	s5,408(sp)
    800050be:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);  // 获取参数地址
    800050c0:	e3840593          	addi	a1,s0,-456
    800050c4:	4505                	li	a0,1
    800050c6:	f36fd0ef          	jal	ra,800027fc <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {  // 获取程序路径
    800050ca:	08000613          	li	a2,128
    800050ce:	f4040593          	addi	a1,s0,-192
    800050d2:	4501                	li	a0,0
    800050d4:	f44fd0ef          	jal	ra,80002818 <argstr>
    800050d8:	87aa                	mv	a5,a0
    return -1;
    800050da:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {  // 获取程序路径
    800050dc:	0a07c463          	bltz	a5,80005184 <sys_exec+0xd6>
  }
  memset(argv, 0, sizeof(argv));
    800050e0:	10000613          	li	a2,256
    800050e4:	4581                	li	a1,0
    800050e6:	e4040513          	addi	a0,s0,-448
    800050ea:	b57fb0ef          	jal	ra,80000c40 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800050ee:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800050f2:	89a6                	mv	s3,s1
    800050f4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800050f6:	02000a13          	li	s4,32
    800050fa:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800050fe:	00391793          	slli	a5,s2,0x3
    80005102:	e3040593          	addi	a1,s0,-464
    80005106:	e3843503          	ld	a0,-456(s0)
    8000510a:	953e                	add	a0,a0,a5
    8000510c:	e4afd0ef          	jal	ra,80002756 <fetchaddr>
    80005110:	02054663          	bltz	a0,8000513c <sys_exec+0x8e>
      goto bad;
    }
    if(uarg == 0){
    80005114:	e3043783          	ld	a5,-464(s0)
    80005118:	cf8d                	beqz	a5,80005152 <sys_exec+0xa4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000511a:	983fb0ef          	jal	ra,80000a9c <kalloc>
    8000511e:	85aa                	mv	a1,a0
    80005120:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005124:	cd01                	beqz	a0,8000513c <sys_exec+0x8e>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005126:	6605                	lui	a2,0x1
    80005128:	e3043503          	ld	a0,-464(s0)
    8000512c:	e74fd0ef          	jal	ra,800027a0 <fetchstr>
    80005130:	00054663          	bltz	a0,8000513c <sys_exec+0x8e>
    if(i >= NELEM(argv)){
    80005134:	0905                	addi	s2,s2,1
    80005136:	09a1                	addi	s3,s3,8
    80005138:	fd4911e3          	bne	s2,s4,800050fa <sys_exec+0x4c>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000513c:	10048913          	addi	s2,s1,256
    80005140:	6088                	ld	a0,0(s1)
    80005142:	c121                	beqz	a0,80005182 <sys_exec+0xd4>
    kfree(argv[i]);
    80005144:	879fb0ef          	jal	ra,800009bc <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005148:	04a1                	addi	s1,s1,8
    8000514a:	ff249be3          	bne	s1,s2,80005140 <sys_exec+0x92>
  return -1;
    8000514e:	557d                	li	a0,-1
    80005150:	a815                	j	80005184 <sys_exec+0xd6>
      argv[i] = 0;
    80005152:	0a8e                	slli	s5,s5,0x3
    80005154:	fc040793          	addi	a5,s0,-64
    80005158:	9abe                	add	s5,s5,a5
    8000515a:	e80ab023          	sd	zero,-384(s5)
  int ret = kexec(path, argv);  // 执行程序
    8000515e:	e4040593          	addi	a1,s0,-448
    80005162:	f4040513          	addi	a0,s0,-192
    80005166:	bfaff0ef          	jal	ra,80004560 <kexec>
    8000516a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000516c:	10048993          	addi	s3,s1,256
    80005170:	6088                	ld	a0,0(s1)
    80005172:	c511                	beqz	a0,8000517e <sys_exec+0xd0>
    kfree(argv[i]);
    80005174:	849fb0ef          	jal	ra,800009bc <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005178:	04a1                	addi	s1,s1,8
    8000517a:	ff349be3          	bne	s1,s3,80005170 <sys_exec+0xc2>
  return ret;
    8000517e:	854a                	mv	a0,s2
    80005180:	a011                	j	80005184 <sys_exec+0xd6>
  return -1;
    80005182:	557d                	li	a0,-1
}
    80005184:	60be                	ld	ra,456(sp)
    80005186:	641e                	ld	s0,448(sp)
    80005188:	74fa                	ld	s1,440(sp)
    8000518a:	795a                	ld	s2,432(sp)
    8000518c:	79ba                	ld	s3,424(sp)
    8000518e:	7a1a                	ld	s4,416(sp)
    80005190:	6afa                	ld	s5,408(sp)
    80005192:	6179                	addi	sp,sp,464
    80005194:	8082                	ret

0000000080005196 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005196:	7139                	addi	sp,sp,-64
    80005198:	fc06                	sd	ra,56(sp)
    8000519a:	f822                	sd	s0,48(sp)
    8000519c:	f426                	sd	s1,40(sp)
    8000519e:	0080                	addi	s0,sp,64
  uint64 fdarray; // 用户指针指向两个整数的数组
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800051a0:	e64fc0ef          	jal	ra,80001804 <myproc>
    800051a4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);  // 获取文件描述符数组地址
    800051a6:	fd840593          	addi	a1,s0,-40
    800051aa:	4501                	li	a0,0
    800051ac:	e50fd0ef          	jal	ra,800027fc <argaddr>
  if(pipealloc(&rf, &wf) < 0)  // 分配管道文件
    800051b0:	fc840593          	addi	a1,s0,-56
    800051b4:	fd040513          	addi	a0,s0,-48
    800051b8:	8c8ff0ef          	jal	ra,80004280 <pipealloc>
    return -1;
    800051bc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)  // 分配管道文件
    800051be:	0a054463          	bltz	a0,80005266 <sys_pipe+0xd0>
  fd0 = -1;
    800051c2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){  // 分配文件描述符
    800051c6:	fd043503          	ld	a0,-48(s0)
    800051ca:	f42ff0ef          	jal	ra,8000490c <fdalloc>
    800051ce:	fca42223          	sw	a0,-60(s0)
    800051d2:	08054163          	bltz	a0,80005254 <sys_pipe+0xbe>
    800051d6:	fc843503          	ld	a0,-56(s0)
    800051da:	f32ff0ef          	jal	ra,8000490c <fdalloc>
    800051de:	fca42023          	sw	a0,-64(s0)
    800051e2:	06054063          	bltz	a0,80005242 <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||  // 将文件描述符写入用户空间
    800051e6:	4691                	li	a3,4
    800051e8:	fc440613          	addi	a2,s0,-60
    800051ec:	fd843583          	ld	a1,-40(s0)
    800051f0:	68a8                	ld	a0,80(s1)
    800051f2:	b60fc0ef          	jal	ra,80001552 <copyout>
    800051f6:	00054e63          	bltz	a0,80005212 <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800051fa:	4691                	li	a3,4
    800051fc:	fc040613          	addi	a2,s0,-64
    80005200:	fd843583          	ld	a1,-40(s0)
    80005204:	0591                	addi	a1,a1,4
    80005206:	68a8                	ld	a0,80(s1)
    80005208:	b4afc0ef          	jal	ra,80001552 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000520c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||  // 将文件描述符写入用户空间
    8000520e:	04055c63          	bgez	a0,80005266 <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    80005212:	fc442783          	lw	a5,-60(s0)
    80005216:	07e9                	addi	a5,a5,26
    80005218:	078e                	slli	a5,a5,0x3
    8000521a:	97a6                	add	a5,a5,s1
    8000521c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005220:	fc042503          	lw	a0,-64(s0)
    80005224:	0569                	addi	a0,a0,26
    80005226:	050e                	slli	a0,a0,0x3
    80005228:	94aa                	add	s1,s1,a0
    8000522a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000522e:	fd043503          	ld	a0,-48(s0)
    80005232:	d83fe0ef          	jal	ra,80003fb4 <fileclose>
    fileclose(wf);
    80005236:	fc843503          	ld	a0,-56(s0)
    8000523a:	d7bfe0ef          	jal	ra,80003fb4 <fileclose>
    return -1;
    8000523e:	57fd                	li	a5,-1
    80005240:	a01d                	j	80005266 <sys_pipe+0xd0>
    if(fd0 >= 0)
    80005242:	fc442783          	lw	a5,-60(s0)
    80005246:	0007c763          	bltz	a5,80005254 <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    8000524a:	07e9                	addi	a5,a5,26
    8000524c:	078e                	slli	a5,a5,0x3
    8000524e:	94be                	add	s1,s1,a5
    80005250:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005254:	fd043503          	ld	a0,-48(s0)
    80005258:	d5dfe0ef          	jal	ra,80003fb4 <fileclose>
    fileclose(wf);
    8000525c:	fc843503          	ld	a0,-56(s0)
    80005260:	d55fe0ef          	jal	ra,80003fb4 <fileclose>
    return -1;
    80005264:	57fd                	li	a5,-1
}
    80005266:	853e                	mv	a0,a5
    80005268:	70e2                	ld	ra,56(sp)
    8000526a:	7442                	ld	s0,48(sp)
    8000526c:	74a2                	ld	s1,40(sp)
    8000526e:	6121                	addi	sp,sp,64
    80005270:	8082                	ret
	...

0000000080005280 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    80005280:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    80005282:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    80005284:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80005286:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80005288:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000528a:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000528c:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    8000528e:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80005290:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80005292:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    80005294:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    80005296:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    80005298:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    8000529a:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    8000529c:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    8000529e:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    800052a0:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    800052a2:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    800052a4:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    800052a6:	b8efd0ef          	jal	ra,80002634 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    800052aa:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    800052ac:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    800052ae:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800052b0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800052b2:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    800052b4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800052b6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800052b8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800052ba:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800052bc:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800052be:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800052c0:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800052c2:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    800052c4:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    800052c6:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    800052c8:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    800052ca:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    800052cc:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    800052ce:	10200073          	sret
	...

00000000800052de <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800052de:	1141                	addi	sp,sp,-16
    800052e0:	e422                	sd	s0,8(sp)
    800052e2:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800052e4:	0c0007b7          	lui	a5,0xc000
    800052e8:	4705                	li	a4,1
    800052ea:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800052ec:	c3d8                	sw	a4,4(a5)
}
    800052ee:	6422                	ld	s0,8(sp)
    800052f0:	0141                	addi	sp,sp,16
    800052f2:	8082                	ret

00000000800052f4 <plicinithart>:

void
plicinithart(void)
{
    800052f4:	1141                	addi	sp,sp,-16
    800052f6:	e406                	sd	ra,8(sp)
    800052f8:	e022                	sd	s0,0(sp)
    800052fa:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800052fc:	cdcfc0ef          	jal	ra,800017d8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005300:	0085171b          	slliw	a4,a0,0x8
    80005304:	0c0027b7          	lui	a5,0xc002
    80005308:	97ba                	add	a5,a5,a4
    8000530a:	40200713          	li	a4,1026
    8000530e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005312:	00d5151b          	slliw	a0,a0,0xd
    80005316:	0c2017b7          	lui	a5,0xc201
    8000531a:	953e                	add	a0,a0,a5
    8000531c:	00052023          	sw	zero,0(a0)
}
    80005320:	60a2                	ld	ra,8(sp)
    80005322:	6402                	ld	s0,0(sp)
    80005324:	0141                	addi	sp,sp,16
    80005326:	8082                	ret

0000000080005328 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005328:	1141                	addi	sp,sp,-16
    8000532a:	e406                	sd	ra,8(sp)
    8000532c:	e022                	sd	s0,0(sp)
    8000532e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005330:	ca8fc0ef          	jal	ra,800017d8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005334:	00d5179b          	slliw	a5,a0,0xd
    80005338:	0c201537          	lui	a0,0xc201
    8000533c:	953e                	add	a0,a0,a5
  return irq;
}
    8000533e:	4148                	lw	a0,4(a0)
    80005340:	60a2                	ld	ra,8(sp)
    80005342:	6402                	ld	s0,0(sp)
    80005344:	0141                	addi	sp,sp,16
    80005346:	8082                	ret

0000000080005348 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005348:	1101                	addi	sp,sp,-32
    8000534a:	ec06                	sd	ra,24(sp)
    8000534c:	e822                	sd	s0,16(sp)
    8000534e:	e426                	sd	s1,8(sp)
    80005350:	1000                	addi	s0,sp,32
    80005352:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005354:	c84fc0ef          	jal	ra,800017d8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005358:	00d5151b          	slliw	a0,a0,0xd
    8000535c:	0c2017b7          	lui	a5,0xc201
    80005360:	97aa                	add	a5,a5,a0
    80005362:	c3c4                	sw	s1,4(a5)
}
    80005364:	60e2                	ld	ra,24(sp)
    80005366:	6442                	ld	s0,16(sp)
    80005368:	64a2                	ld	s1,8(sp)
    8000536a:	6105                	addi	sp,sp,32
    8000536c:	8082                	ret

000000008000536e <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    8000536e:	1141                	addi	sp,sp,-16
    80005370:	e406                	sd	ra,8(sp)
    80005372:	e022                	sd	s0,0(sp)
    80005374:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005376:	479d                	li	a5,7
    80005378:	04a7ca63          	blt	a5,a0,800053cc <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    8000537c:	0001c797          	auipc	a5,0x1c
    80005380:	8bc78793          	addi	a5,a5,-1860 # 80020c38 <disk>
    80005384:	97aa                	add	a5,a5,a0
    80005386:	0187c783          	lbu	a5,24(a5)
    8000538a:	e7b9                	bnez	a5,800053d8 <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000538c:	00451613          	slli	a2,a0,0x4
    80005390:	0001c797          	auipc	a5,0x1c
    80005394:	8a878793          	addi	a5,a5,-1880 # 80020c38 <disk>
    80005398:	6394                	ld	a3,0(a5)
    8000539a:	96b2                	add	a3,a3,a2
    8000539c:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800053a0:	6398                	ld	a4,0(a5)
    800053a2:	9732                	add	a4,a4,a2
    800053a4:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800053a8:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800053ac:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800053b0:	953e                	add	a0,a0,a5
    800053b2:	4785                	li	a5,1
    800053b4:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800053b8:	0001c517          	auipc	a0,0x1c
    800053bc:	89850513          	addi	a0,a0,-1896 # 80020c50 <disk+0x18>
    800053c0:	aa3fc0ef          	jal	ra,80001e62 <wakeup>
}
    800053c4:	60a2                	ld	ra,8(sp)
    800053c6:	6402                	ld	s0,0(sp)
    800053c8:	0141                	addi	sp,sp,16
    800053ca:	8082                	ret
    panic("free_desc 1");
    800053cc:	00002517          	auipc	a0,0x2
    800053d0:	35c50513          	addi	a0,a0,860 # 80007728 <syscalls+0x338>
    800053d4:	bb6fb0ef          	jal	ra,8000078a <panic>
    panic("free_desc 2");
    800053d8:	00002517          	auipc	a0,0x2
    800053dc:	36050513          	addi	a0,a0,864 # 80007738 <syscalls+0x348>
    800053e0:	baafb0ef          	jal	ra,8000078a <panic>

00000000800053e4 <virtio_disk_init>:
{
    800053e4:	1101                	addi	sp,sp,-32
    800053e6:	ec06                	sd	ra,24(sp)
    800053e8:	e822                	sd	s0,16(sp)
    800053ea:	e426                	sd	s1,8(sp)
    800053ec:	e04a                	sd	s2,0(sp)
    800053ee:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800053f0:	00002597          	auipc	a1,0x2
    800053f4:	35858593          	addi	a1,a1,856 # 80007748 <syscalls+0x358>
    800053f8:	0001c517          	auipc	a0,0x1c
    800053fc:	96850513          	addi	a0,a0,-1688 # 80020d60 <disk+0x128>
    80005400:	eecfb0ef          	jal	ra,80000aec <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005404:	100017b7          	lui	a5,0x10001
    80005408:	4398                	lw	a4,0(a5)
    8000540a:	2701                	sext.w	a4,a4
    8000540c:	747277b7          	lui	a5,0x74727
    80005410:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005414:	14f71063          	bne	a4,a5,80005554 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005418:	100017b7          	lui	a5,0x10001
    8000541c:	43dc                	lw	a5,4(a5)
    8000541e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005420:	4709                	li	a4,2
    80005422:	12e79963          	bne	a5,a4,80005554 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005426:	100017b7          	lui	a5,0x10001
    8000542a:	479c                	lw	a5,8(a5)
    8000542c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000542e:	12e79363          	bne	a5,a4,80005554 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005432:	100017b7          	lui	a5,0x10001
    80005436:	47d8                	lw	a4,12(a5)
    80005438:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000543a:	554d47b7          	lui	a5,0x554d4
    8000543e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005442:	10f71963          	bne	a4,a5,80005554 <virtio_disk_init+0x170>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005446:	100017b7          	lui	a5,0x10001
    8000544a:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000544e:	4705                	li	a4,1
    80005450:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005452:	470d                	li	a4,3
    80005454:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005456:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005458:	c7ffe737          	lui	a4,0xc7ffe
    8000545c:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdd9e7>
    80005460:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005462:	2701                	sext.w	a4,a4
    80005464:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005466:	472d                	li	a4,11
    80005468:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    8000546a:	5bbc                	lw	a5,112(a5)
    8000546c:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005470:	8ba1                	andi	a5,a5,8
    80005472:	0e078763          	beqz	a5,80005560 <virtio_disk_init+0x17c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005476:	100017b7          	lui	a5,0x10001
    8000547a:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    8000547e:	43fc                	lw	a5,68(a5)
    80005480:	2781                	sext.w	a5,a5
    80005482:	0e079563          	bnez	a5,8000556c <virtio_disk_init+0x188>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005486:	100017b7          	lui	a5,0x10001
    8000548a:	5bdc                	lw	a5,52(a5)
    8000548c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000548e:	0e078563          	beqz	a5,80005578 <virtio_disk_init+0x194>
  if(max < NUM)
    80005492:	471d                	li	a4,7
    80005494:	0ef77863          	bgeu	a4,a5,80005584 <virtio_disk_init+0x1a0>
  disk.desc = kalloc();
    80005498:	e04fb0ef          	jal	ra,80000a9c <kalloc>
    8000549c:	0001b497          	auipc	s1,0x1b
    800054a0:	79c48493          	addi	s1,s1,1948 # 80020c38 <disk>
    800054a4:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800054a6:	df6fb0ef          	jal	ra,80000a9c <kalloc>
    800054aa:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800054ac:	df0fb0ef          	jal	ra,80000a9c <kalloc>
    800054b0:	87aa                	mv	a5,a0
    800054b2:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800054b4:	6088                	ld	a0,0(s1)
    800054b6:	cd69                	beqz	a0,80005590 <virtio_disk_init+0x1ac>
    800054b8:	0001b717          	auipc	a4,0x1b
    800054bc:	78873703          	ld	a4,1928(a4) # 80020c40 <disk+0x8>
    800054c0:	cb61                	beqz	a4,80005590 <virtio_disk_init+0x1ac>
    800054c2:	c7f9                	beqz	a5,80005590 <virtio_disk_init+0x1ac>
  memset(disk.desc, 0, PGSIZE);
    800054c4:	6605                	lui	a2,0x1
    800054c6:	4581                	li	a1,0
    800054c8:	f78fb0ef          	jal	ra,80000c40 <memset>
  memset(disk.avail, 0, PGSIZE);
    800054cc:	0001b497          	auipc	s1,0x1b
    800054d0:	76c48493          	addi	s1,s1,1900 # 80020c38 <disk>
    800054d4:	6605                	lui	a2,0x1
    800054d6:	4581                	li	a1,0
    800054d8:	6488                	ld	a0,8(s1)
    800054da:	f66fb0ef          	jal	ra,80000c40 <memset>
  memset(disk.used, 0, PGSIZE);
    800054de:	6605                	lui	a2,0x1
    800054e0:	4581                	li	a1,0
    800054e2:	6888                	ld	a0,16(s1)
    800054e4:	f5cfb0ef          	jal	ra,80000c40 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800054e8:	100017b7          	lui	a5,0x10001
    800054ec:	4721                	li	a4,8
    800054ee:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800054f0:	4098                	lw	a4,0(s1)
    800054f2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800054f6:	40d8                	lw	a4,4(s1)
    800054f8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800054fc:	6498                	ld	a4,8(s1)
    800054fe:	0007069b          	sext.w	a3,a4
    80005502:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005506:	9701                	srai	a4,a4,0x20
    80005508:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000550c:	6898                	ld	a4,16(s1)
    8000550e:	0007069b          	sext.w	a3,a4
    80005512:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005516:	9701                	srai	a4,a4,0x20
    80005518:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000551c:	4705                	li	a4,1
    8000551e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005520:	00e48c23          	sb	a4,24(s1)
    80005524:	00e48ca3          	sb	a4,25(s1)
    80005528:	00e48d23          	sb	a4,26(s1)
    8000552c:	00e48da3          	sb	a4,27(s1)
    80005530:	00e48e23          	sb	a4,28(s1)
    80005534:	00e48ea3          	sb	a4,29(s1)
    80005538:	00e48f23          	sb	a4,30(s1)
    8000553c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005540:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005544:	0727a823          	sw	s2,112(a5)
}
    80005548:	60e2                	ld	ra,24(sp)
    8000554a:	6442                	ld	s0,16(sp)
    8000554c:	64a2                	ld	s1,8(sp)
    8000554e:	6902                	ld	s2,0(sp)
    80005550:	6105                	addi	sp,sp,32
    80005552:	8082                	ret
    panic("could not find virtio disk");
    80005554:	00002517          	auipc	a0,0x2
    80005558:	20450513          	addi	a0,a0,516 # 80007758 <syscalls+0x368>
    8000555c:	a2efb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk FEATURES_OK unset");
    80005560:	00002517          	auipc	a0,0x2
    80005564:	21850513          	addi	a0,a0,536 # 80007778 <syscalls+0x388>
    80005568:	a22fb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk should not be ready");
    8000556c:	00002517          	auipc	a0,0x2
    80005570:	22c50513          	addi	a0,a0,556 # 80007798 <syscalls+0x3a8>
    80005574:	a16fb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk has no queue 0");
    80005578:	00002517          	auipc	a0,0x2
    8000557c:	24050513          	addi	a0,a0,576 # 800077b8 <syscalls+0x3c8>
    80005580:	a0afb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk max queue too short");
    80005584:	00002517          	auipc	a0,0x2
    80005588:	25450513          	addi	a0,a0,596 # 800077d8 <syscalls+0x3e8>
    8000558c:	9fefb0ef          	jal	ra,8000078a <panic>
    panic("virtio disk kalloc");
    80005590:	00002517          	auipc	a0,0x2
    80005594:	26850513          	addi	a0,a0,616 # 800077f8 <syscalls+0x408>
    80005598:	9f2fb0ef          	jal	ra,8000078a <panic>

000000008000559c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000559c:	7119                	addi	sp,sp,-128
    8000559e:	fc86                	sd	ra,120(sp)
    800055a0:	f8a2                	sd	s0,112(sp)
    800055a2:	f4a6                	sd	s1,104(sp)
    800055a4:	f0ca                	sd	s2,96(sp)
    800055a6:	ecce                	sd	s3,88(sp)
    800055a8:	e8d2                	sd	s4,80(sp)
    800055aa:	e4d6                	sd	s5,72(sp)
    800055ac:	e0da                	sd	s6,64(sp)
    800055ae:	fc5e                	sd	s7,56(sp)
    800055b0:	f862                	sd	s8,48(sp)
    800055b2:	f466                	sd	s9,40(sp)
    800055b4:	f06a                	sd	s10,32(sp)
    800055b6:	ec6e                	sd	s11,24(sp)
    800055b8:	0100                	addi	s0,sp,128
    800055ba:	8aaa                	mv	s5,a0
    800055bc:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800055be:	00c52d03          	lw	s10,12(a0)
    800055c2:	001d1d1b          	slliw	s10,s10,0x1
    800055c6:	1d02                	slli	s10,s10,0x20
    800055c8:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800055cc:	0001b517          	auipc	a0,0x1b
    800055d0:	79450513          	addi	a0,a0,1940 # 80020d60 <disk+0x128>
    800055d4:	d98fb0ef          	jal	ra,80000b6c <acquire>
  for(int i = 0; i < 3; i++){
    800055d8:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800055da:	44a1                	li	s1,8
      disk.free[i] = 0;
    800055dc:	0001bb97          	auipc	s7,0x1b
    800055e0:	65cb8b93          	addi	s7,s7,1628 # 80020c38 <disk>
  for(int i = 0; i < 3; i++){
    800055e4:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800055e6:	0001bc97          	auipc	s9,0x1b
    800055ea:	77ac8c93          	addi	s9,s9,1914 # 80020d60 <disk+0x128>
    800055ee:	a8a9                	j	80005648 <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    800055f0:	00fb8733          	add	a4,s7,a5
    800055f4:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800055f8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800055fa:	0207c563          	bltz	a5,80005624 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800055fe:	2905                	addiw	s2,s2,1
    80005600:	0611                	addi	a2,a2,4
    80005602:	05690863          	beq	s2,s6,80005652 <virtio_disk_rw+0xb6>
    idx[i] = alloc_desc();
    80005606:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005608:	0001b717          	auipc	a4,0x1b
    8000560c:	63070713          	addi	a4,a4,1584 # 80020c38 <disk>
    80005610:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005612:	01874683          	lbu	a3,24(a4)
    80005616:	fee9                	bnez	a3,800055f0 <virtio_disk_rw+0x54>
  for(int i = 0; i < NUM; i++){
    80005618:	2785                	addiw	a5,a5,1
    8000561a:	0705                	addi	a4,a4,1
    8000561c:	fe979be3          	bne	a5,s1,80005612 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005620:	57fd                	li	a5,-1
    80005622:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005624:	01205b63          	blez	s2,8000563a <virtio_disk_rw+0x9e>
    80005628:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000562a:	000a2503          	lw	a0,0(s4)
    8000562e:	d41ff0ef          	jal	ra,8000536e <free_desc>
      for(int j = 0; j < i; j++)
    80005632:	2d85                	addiw	s11,s11,1
    80005634:	0a11                	addi	s4,s4,4
    80005636:	ffb91ae3          	bne	s2,s11,8000562a <virtio_disk_rw+0x8e>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000563a:	85e6                	mv	a1,s9
    8000563c:	0001b517          	auipc	a0,0x1b
    80005640:	61450513          	addi	a0,a0,1556 # 80020c50 <disk+0x18>
    80005644:	fd2fc0ef          	jal	ra,80001e16 <sleep>
  for(int i = 0; i < 3; i++){
    80005648:	f8040a13          	addi	s4,s0,-128
{
    8000564c:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000564e:	894e                	mv	s2,s3
    80005650:	bf5d                	j	80005606 <virtio_disk_rw+0x6a>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005652:	f8042583          	lw	a1,-128(s0)
    80005656:	00a58793          	addi	a5,a1,10
    8000565a:	0792                	slli	a5,a5,0x4

  if(write)
    8000565c:	0001b617          	auipc	a2,0x1b
    80005660:	5dc60613          	addi	a2,a2,1500 # 80020c38 <disk>
    80005664:	00f60733          	add	a4,a2,a5
    80005668:	018036b3          	snez	a3,s8
    8000566c:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000566e:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80005672:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005676:	f6078693          	addi	a3,a5,-160
    8000567a:	6218                	ld	a4,0(a2)
    8000567c:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000567e:	00878513          	addi	a0,a5,8
    80005682:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005684:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005686:	6208                	ld	a0,0(a2)
    80005688:	96aa                	add	a3,a3,a0
    8000568a:	4741                	li	a4,16
    8000568c:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000568e:	4705                	li	a4,1
    80005690:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80005694:	f8442703          	lw	a4,-124(s0)
    80005698:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    8000569c:	0712                	slli	a4,a4,0x4
    8000569e:	953a                	add	a0,a0,a4
    800056a0:	058a8693          	addi	a3,s5,88
    800056a4:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800056a6:	6208                	ld	a0,0(a2)
    800056a8:	972a                	add	a4,a4,a0
    800056aa:	40000693          	li	a3,1024
    800056ae:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800056b0:	001c3c13          	seqz	s8,s8
    800056b4:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800056b6:	001c6c13          	ori	s8,s8,1
    800056ba:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800056be:	f8842603          	lw	a2,-120(s0)
    800056c2:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800056c6:	0001b697          	auipc	a3,0x1b
    800056ca:	57268693          	addi	a3,a3,1394 # 80020c38 <disk>
    800056ce:	00258713          	addi	a4,a1,2
    800056d2:	0712                	slli	a4,a4,0x4
    800056d4:	9736                	add	a4,a4,a3
    800056d6:	587d                	li	a6,-1
    800056d8:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800056dc:	0612                	slli	a2,a2,0x4
    800056de:	9532                	add	a0,a0,a2
    800056e0:	f9078793          	addi	a5,a5,-112
    800056e4:	97b6                	add	a5,a5,a3
    800056e6:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800056e8:	629c                	ld	a5,0(a3)
    800056ea:	97b2                	add	a5,a5,a2
    800056ec:	4605                	li	a2,1
    800056ee:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800056f0:	4509                	li	a0,2
    800056f2:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800056f6:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800056fa:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800056fe:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005702:	6698                	ld	a4,8(a3)
    80005704:	00275783          	lhu	a5,2(a4)
    80005708:	8b9d                	andi	a5,a5,7
    8000570a:	0786                	slli	a5,a5,0x1
    8000570c:	97ba                	add	a5,a5,a4
    8000570e:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80005712:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005716:	6698                	ld	a4,8(a3)
    80005718:	00275783          	lhu	a5,2(a4)
    8000571c:	2785                	addiw	a5,a5,1
    8000571e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005722:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005726:	100017b7          	lui	a5,0x10001
    8000572a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000572e:	004aa783          	lw	a5,4(s5)
    80005732:	00c79f63          	bne	a5,a2,80005750 <virtio_disk_rw+0x1b4>
    sleep(b, &disk.vdisk_lock);
    80005736:	0001b917          	auipc	s2,0x1b
    8000573a:	62a90913          	addi	s2,s2,1578 # 80020d60 <disk+0x128>
  while(b->disk == 1) {
    8000573e:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005740:	85ca                	mv	a1,s2
    80005742:	8556                	mv	a0,s5
    80005744:	ed2fc0ef          	jal	ra,80001e16 <sleep>
  while(b->disk == 1) {
    80005748:	004aa783          	lw	a5,4(s5)
    8000574c:	fe978ae3          	beq	a5,s1,80005740 <virtio_disk_rw+0x1a4>
  }

  disk.info[idx[0]].b = 0;
    80005750:	f8042903          	lw	s2,-128(s0)
    80005754:	00290793          	addi	a5,s2,2
    80005758:	00479713          	slli	a4,a5,0x4
    8000575c:	0001b797          	auipc	a5,0x1b
    80005760:	4dc78793          	addi	a5,a5,1244 # 80020c38 <disk>
    80005764:	97ba                	add	a5,a5,a4
    80005766:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000576a:	0001b997          	auipc	s3,0x1b
    8000576e:	4ce98993          	addi	s3,s3,1230 # 80020c38 <disk>
    80005772:	00491713          	slli	a4,s2,0x4
    80005776:	0009b783          	ld	a5,0(s3)
    8000577a:	97ba                	add	a5,a5,a4
    8000577c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005780:	854a                	mv	a0,s2
    80005782:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005786:	be9ff0ef          	jal	ra,8000536e <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000578a:	8885                	andi	s1,s1,1
    8000578c:	f0fd                	bnez	s1,80005772 <virtio_disk_rw+0x1d6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000578e:	0001b517          	auipc	a0,0x1b
    80005792:	5d250513          	addi	a0,a0,1490 # 80020d60 <disk+0x128>
    80005796:	c6efb0ef          	jal	ra,80000c04 <release>
}
    8000579a:	70e6                	ld	ra,120(sp)
    8000579c:	7446                	ld	s0,112(sp)
    8000579e:	74a6                	ld	s1,104(sp)
    800057a0:	7906                	ld	s2,96(sp)
    800057a2:	69e6                	ld	s3,88(sp)
    800057a4:	6a46                	ld	s4,80(sp)
    800057a6:	6aa6                	ld	s5,72(sp)
    800057a8:	6b06                	ld	s6,64(sp)
    800057aa:	7be2                	ld	s7,56(sp)
    800057ac:	7c42                	ld	s8,48(sp)
    800057ae:	7ca2                	ld	s9,40(sp)
    800057b0:	7d02                	ld	s10,32(sp)
    800057b2:	6de2                	ld	s11,24(sp)
    800057b4:	6109                	addi	sp,sp,128
    800057b6:	8082                	ret

00000000800057b8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800057b8:	1101                	addi	sp,sp,-32
    800057ba:	ec06                	sd	ra,24(sp)
    800057bc:	e822                	sd	s0,16(sp)
    800057be:	e426                	sd	s1,8(sp)
    800057c0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800057c2:	0001b497          	auipc	s1,0x1b
    800057c6:	47648493          	addi	s1,s1,1142 # 80020c38 <disk>
    800057ca:	0001b517          	auipc	a0,0x1b
    800057ce:	59650513          	addi	a0,a0,1430 # 80020d60 <disk+0x128>
    800057d2:	b9afb0ef          	jal	ra,80000b6c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800057d6:	10001737          	lui	a4,0x10001
    800057da:	533c                	lw	a5,96(a4)
    800057dc:	8b8d                	andi	a5,a5,3
    800057de:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800057e0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800057e4:	689c                	ld	a5,16(s1)
    800057e6:	0204d703          	lhu	a4,32(s1)
    800057ea:	0027d783          	lhu	a5,2(a5)
    800057ee:	04f70663          	beq	a4,a5,8000583a <virtio_disk_intr+0x82>
    __sync_synchronize();
    800057f2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800057f6:	6898                	ld	a4,16(s1)
    800057f8:	0204d783          	lhu	a5,32(s1)
    800057fc:	8b9d                	andi	a5,a5,7
    800057fe:	078e                	slli	a5,a5,0x3
    80005800:	97ba                	add	a5,a5,a4
    80005802:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005804:	00278713          	addi	a4,a5,2
    80005808:	0712                	slli	a4,a4,0x4
    8000580a:	9726                	add	a4,a4,s1
    8000580c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80005810:	e321                	bnez	a4,80005850 <virtio_disk_intr+0x98>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005812:	0789                	addi	a5,a5,2
    80005814:	0792                	slli	a5,a5,0x4
    80005816:	97a6                	add	a5,a5,s1
    80005818:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000581a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000581e:	e44fc0ef          	jal	ra,80001e62 <wakeup>

    disk.used_idx += 1;
    80005822:	0204d783          	lhu	a5,32(s1)
    80005826:	2785                	addiw	a5,a5,1
    80005828:	17c2                	slli	a5,a5,0x30
    8000582a:	93c1                	srli	a5,a5,0x30
    8000582c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005830:	6898                	ld	a4,16(s1)
    80005832:	00275703          	lhu	a4,2(a4)
    80005836:	faf71ee3          	bne	a4,a5,800057f2 <virtio_disk_intr+0x3a>
  }

  release(&disk.vdisk_lock);
    8000583a:	0001b517          	auipc	a0,0x1b
    8000583e:	52650513          	addi	a0,a0,1318 # 80020d60 <disk+0x128>
    80005842:	bc2fb0ef          	jal	ra,80000c04 <release>
}
    80005846:	60e2                	ld	ra,24(sp)
    80005848:	6442                	ld	s0,16(sp)
    8000584a:	64a2                	ld	s1,8(sp)
    8000584c:	6105                	addi	sp,sp,32
    8000584e:	8082                	ret
      panic("virtio_disk_intr status");
    80005850:	00002517          	auipc	a0,0x2
    80005854:	fc050513          	addi	a0,a0,-64 # 80007810 <syscalls+0x420>
    80005858:	f33fa0ef          	jal	ra,8000078a <panic>
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
