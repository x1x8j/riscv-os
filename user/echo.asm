
user/_echo:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	e052                	sd	s4,0(sp)
   e:	1800                	addi	s0,sp,48
  int i;

  for(i = 1; i < argc; i++){
  10:	4785                	li	a5,1
  12:	04a7dc63          	bge	a5,a0,6a <main+0x6a>
  16:	00858493          	addi	s1,a1,8
  1a:	ffe5099b          	addiw	s3,a0,-2
  1e:	1982                	slli	s3,s3,0x20
  20:	0209d993          	srli	s3,s3,0x20
  24:	098e                	slli	s3,s3,0x3
  26:	05c1                	addi	a1,a1,16
  28:	99ae                	add	s3,s3,a1
    write(1, argv[i], strlen(argv[i]));
    if(i + 1 < argc){
      write(1, " ", 1);
  2a:	00001a17          	auipc	s4,0x1
  2e:	896a0a13          	addi	s4,s4,-1898 # 8c0 <malloc+0xdc>
    write(1, argv[i], strlen(argv[i]));
  32:	0004b903          	ld	s2,0(s1)
  36:	854a                	mv	a0,s2
  38:	090000ef          	jal	ra,c8 <strlen>
  3c:	0005061b          	sext.w	a2,a0
  40:	85ca                	mv	a1,s2
  42:	4505                	li	a0,1
  44:	2e2000ef          	jal	ra,326 <write>
    if(i + 1 < argc){
  48:	04a1                	addi	s1,s1,8
  4a:	01348863          	beq	s1,s3,5a <main+0x5a>
      write(1, " ", 1);
  4e:	4605                	li	a2,1
  50:	85d2                	mv	a1,s4
  52:	4505                	li	a0,1
  54:	2d2000ef          	jal	ra,326 <write>
  for(i = 1; i < argc; i++){
  58:	bfe9                	j	32 <main+0x32>
    } else {
      write(1, "\n", 1);
  5a:	4605                	li	a2,1
  5c:	00001597          	auipc	a1,0x1
  60:	86c58593          	addi	a1,a1,-1940 # 8c8 <malloc+0xe4>
  64:	4505                	li	a0,1
  66:	2c0000ef          	jal	ra,326 <write>
    }
  }
  exit(0);
  6a:	4501                	li	a0,0
  6c:	29a000ef          	jal	ra,306 <exit>

0000000000000070 <start>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
start(int argc, char **argv)
{
  70:	1141                	addi	sp,sp,-16
  72:	e406                	sd	ra,8(sp)
  74:	e022                	sd	s0,0(sp)
  76:	0800                	addi	s0,sp,16
  int r;
  extern int main(int argc, char **argv);
  r = main(argc, argv);
  78:	f89ff0ef          	jal	ra,0 <main>
  exit(r);
  7c:	28a000ef          	jal	ra,306 <exit>

0000000000000080 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  80:	1141                	addi	sp,sp,-16
  82:	e422                	sd	s0,8(sp)
  84:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  86:	87aa                	mv	a5,a0
  88:	0585                	addi	a1,a1,1
  8a:	0785                	addi	a5,a5,1
  8c:	fff5c703          	lbu	a4,-1(a1)
  90:	fee78fa3          	sb	a4,-1(a5)
  94:	fb75                	bnez	a4,88 <strcpy+0x8>
    ;
  return os;
}
  96:	6422                	ld	s0,8(sp)
  98:	0141                	addi	sp,sp,16
  9a:	8082                	ret

000000000000009c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  9c:	1141                	addi	sp,sp,-16
  9e:	e422                	sd	s0,8(sp)
  a0:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  a2:	00054783          	lbu	a5,0(a0)
  a6:	cb91                	beqz	a5,ba <strcmp+0x1e>
  a8:	0005c703          	lbu	a4,0(a1)
  ac:	00f71763          	bne	a4,a5,ba <strcmp+0x1e>
    p++, q++;
  b0:	0505                	addi	a0,a0,1
  b2:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  b4:	00054783          	lbu	a5,0(a0)
  b8:	fbe5                	bnez	a5,a8 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  ba:	0005c503          	lbu	a0,0(a1)
}
  be:	40a7853b          	subw	a0,a5,a0
  c2:	6422                	ld	s0,8(sp)
  c4:	0141                	addi	sp,sp,16
  c6:	8082                	ret

00000000000000c8 <strlen>:

uint
strlen(const char *s)
{
  c8:	1141                	addi	sp,sp,-16
  ca:	e422                	sd	s0,8(sp)
  cc:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  ce:	00054783          	lbu	a5,0(a0)
  d2:	cf91                	beqz	a5,ee <strlen+0x26>
  d4:	0505                	addi	a0,a0,1
  d6:	87aa                	mv	a5,a0
  d8:	4685                	li	a3,1
  da:	9e89                	subw	a3,a3,a0
  dc:	00f6853b          	addw	a0,a3,a5
  e0:	0785                	addi	a5,a5,1
  e2:	fff7c703          	lbu	a4,-1(a5)
  e6:	fb7d                	bnez	a4,dc <strlen+0x14>
    ;
  return n;
}
  e8:	6422                	ld	s0,8(sp)
  ea:	0141                	addi	sp,sp,16
  ec:	8082                	ret
  for(n = 0; s[n]; n++)
  ee:	4501                	li	a0,0
  f0:	bfe5                	j	e8 <strlen+0x20>

00000000000000f2 <memset>:

void*
memset(void *dst, int c, uint n)
{
  f2:	1141                	addi	sp,sp,-16
  f4:	e422                	sd	s0,8(sp)
  f6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  f8:	ca19                	beqz	a2,10e <memset+0x1c>
  fa:	87aa                	mv	a5,a0
  fc:	1602                	slli	a2,a2,0x20
  fe:	9201                	srli	a2,a2,0x20
 100:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 104:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 108:	0785                	addi	a5,a5,1
 10a:	fee79de3          	bne	a5,a4,104 <memset+0x12>
  }
  return dst;
}
 10e:	6422                	ld	s0,8(sp)
 110:	0141                	addi	sp,sp,16
 112:	8082                	ret

0000000000000114 <strchr>:

char*
strchr(const char *s, char c)
{
 114:	1141                	addi	sp,sp,-16
 116:	e422                	sd	s0,8(sp)
 118:	0800                	addi	s0,sp,16
  for(; *s; s++)
 11a:	00054783          	lbu	a5,0(a0)
 11e:	cb99                	beqz	a5,134 <strchr+0x20>
    if(*s == c)
 120:	00f58763          	beq	a1,a5,12e <strchr+0x1a>
  for(; *s; s++)
 124:	0505                	addi	a0,a0,1
 126:	00054783          	lbu	a5,0(a0)
 12a:	fbfd                	bnez	a5,120 <strchr+0xc>
      return (char*)s;
  return 0;
 12c:	4501                	li	a0,0
}
 12e:	6422                	ld	s0,8(sp)
 130:	0141                	addi	sp,sp,16
 132:	8082                	ret
  return 0;
 134:	4501                	li	a0,0
 136:	bfe5                	j	12e <strchr+0x1a>

0000000000000138 <gets>:

char*
gets(char *buf, int max)
{
 138:	711d                	addi	sp,sp,-96
 13a:	ec86                	sd	ra,88(sp)
 13c:	e8a2                	sd	s0,80(sp)
 13e:	e4a6                	sd	s1,72(sp)
 140:	e0ca                	sd	s2,64(sp)
 142:	fc4e                	sd	s3,56(sp)
 144:	f852                	sd	s4,48(sp)
 146:	f456                	sd	s5,40(sp)
 148:	f05a                	sd	s6,32(sp)
 14a:	ec5e                	sd	s7,24(sp)
 14c:	1080                	addi	s0,sp,96
 14e:	8baa                	mv	s7,a0
 150:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 152:	892a                	mv	s2,a0
 154:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 156:	4aa9                	li	s5,10
 158:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 15a:	89a6                	mv	s3,s1
 15c:	2485                	addiw	s1,s1,1
 15e:	0344d663          	bge	s1,s4,18a <gets+0x52>
    cc = read(0, &c, 1);
 162:	4605                	li	a2,1
 164:	faf40593          	addi	a1,s0,-81
 168:	4501                	li	a0,0
 16a:	1b4000ef          	jal	ra,31e <read>
    if(cc < 1)
 16e:	00a05e63          	blez	a0,18a <gets+0x52>
    buf[i++] = c;
 172:	faf44783          	lbu	a5,-81(s0)
 176:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 17a:	01578763          	beq	a5,s5,188 <gets+0x50>
 17e:	0905                	addi	s2,s2,1
 180:	fd679de3          	bne	a5,s6,15a <gets+0x22>
  for(i=0; i+1 < max; ){
 184:	89a6                	mv	s3,s1
 186:	a011                	j	18a <gets+0x52>
 188:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 18a:	99de                	add	s3,s3,s7
 18c:	00098023          	sb	zero,0(s3)
  return buf;
}
 190:	855e                	mv	a0,s7
 192:	60e6                	ld	ra,88(sp)
 194:	6446                	ld	s0,80(sp)
 196:	64a6                	ld	s1,72(sp)
 198:	6906                	ld	s2,64(sp)
 19a:	79e2                	ld	s3,56(sp)
 19c:	7a42                	ld	s4,48(sp)
 19e:	7aa2                	ld	s5,40(sp)
 1a0:	7b02                	ld	s6,32(sp)
 1a2:	6be2                	ld	s7,24(sp)
 1a4:	6125                	addi	sp,sp,96
 1a6:	8082                	ret

00000000000001a8 <stat>:

int
stat(const char *n, struct stat *st)
{
 1a8:	1101                	addi	sp,sp,-32
 1aa:	ec06                	sd	ra,24(sp)
 1ac:	e822                	sd	s0,16(sp)
 1ae:	e426                	sd	s1,8(sp)
 1b0:	e04a                	sd	s2,0(sp)
 1b2:	1000                	addi	s0,sp,32
 1b4:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1b6:	4581                	li	a1,0
 1b8:	18e000ef          	jal	ra,346 <open>
  if(fd < 0)
 1bc:	02054163          	bltz	a0,1de <stat+0x36>
 1c0:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1c2:	85ca                	mv	a1,s2
 1c4:	19a000ef          	jal	ra,35e <fstat>
 1c8:	892a                	mv	s2,a0
  close(fd);
 1ca:	8526                	mv	a0,s1
 1cc:	162000ef          	jal	ra,32e <close>
  return r;
}
 1d0:	854a                	mv	a0,s2
 1d2:	60e2                	ld	ra,24(sp)
 1d4:	6442                	ld	s0,16(sp)
 1d6:	64a2                	ld	s1,8(sp)
 1d8:	6902                	ld	s2,0(sp)
 1da:	6105                	addi	sp,sp,32
 1dc:	8082                	ret
    return -1;
 1de:	597d                	li	s2,-1
 1e0:	bfc5                	j	1d0 <stat+0x28>

00000000000001e2 <atoi>:

int
atoi(const char *s)
{
 1e2:	1141                	addi	sp,sp,-16
 1e4:	e422                	sd	s0,8(sp)
 1e6:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1e8:	00054603          	lbu	a2,0(a0)
 1ec:	fd06079b          	addiw	a5,a2,-48
 1f0:	0ff7f793          	andi	a5,a5,255
 1f4:	4725                	li	a4,9
 1f6:	02f76963          	bltu	a4,a5,228 <atoi+0x46>
 1fa:	86aa                	mv	a3,a0
  n = 0;
 1fc:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 1fe:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 200:	0685                	addi	a3,a3,1
 202:	0025179b          	slliw	a5,a0,0x2
 206:	9fa9                	addw	a5,a5,a0
 208:	0017979b          	slliw	a5,a5,0x1
 20c:	9fb1                	addw	a5,a5,a2
 20e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 212:	0006c603          	lbu	a2,0(a3)
 216:	fd06071b          	addiw	a4,a2,-48
 21a:	0ff77713          	andi	a4,a4,255
 21e:	fee5f1e3          	bgeu	a1,a4,200 <atoi+0x1e>
  return n;
}
 222:	6422                	ld	s0,8(sp)
 224:	0141                	addi	sp,sp,16
 226:	8082                	ret
  n = 0;
 228:	4501                	li	a0,0
 22a:	bfe5                	j	222 <atoi+0x40>

000000000000022c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 22c:	1141                	addi	sp,sp,-16
 22e:	e422                	sd	s0,8(sp)
 230:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 232:	02b57463          	bgeu	a0,a1,25a <memmove+0x2e>
    while(n-- > 0)
 236:	00c05f63          	blez	a2,254 <memmove+0x28>
 23a:	1602                	slli	a2,a2,0x20
 23c:	9201                	srli	a2,a2,0x20
 23e:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 242:	872a                	mv	a4,a0
      *dst++ = *src++;
 244:	0585                	addi	a1,a1,1
 246:	0705                	addi	a4,a4,1
 248:	fff5c683          	lbu	a3,-1(a1)
 24c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 250:	fee79ae3          	bne	a5,a4,244 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 254:	6422                	ld	s0,8(sp)
 256:	0141                	addi	sp,sp,16
 258:	8082                	ret
    dst += n;
 25a:	00c50733          	add	a4,a0,a2
    src += n;
 25e:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 260:	fec05ae3          	blez	a2,254 <memmove+0x28>
 264:	fff6079b          	addiw	a5,a2,-1
 268:	1782                	slli	a5,a5,0x20
 26a:	9381                	srli	a5,a5,0x20
 26c:	fff7c793          	not	a5,a5
 270:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 272:	15fd                	addi	a1,a1,-1
 274:	177d                	addi	a4,a4,-1
 276:	0005c683          	lbu	a3,0(a1)
 27a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 27e:	fee79ae3          	bne	a5,a4,272 <memmove+0x46>
 282:	bfc9                	j	254 <memmove+0x28>

0000000000000284 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 284:	1141                	addi	sp,sp,-16
 286:	e422                	sd	s0,8(sp)
 288:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 28a:	ca05                	beqz	a2,2ba <memcmp+0x36>
 28c:	fff6069b          	addiw	a3,a2,-1
 290:	1682                	slli	a3,a3,0x20
 292:	9281                	srli	a3,a3,0x20
 294:	0685                	addi	a3,a3,1
 296:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 298:	00054783          	lbu	a5,0(a0)
 29c:	0005c703          	lbu	a4,0(a1)
 2a0:	00e79863          	bne	a5,a4,2b0 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2a4:	0505                	addi	a0,a0,1
    p2++;
 2a6:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2a8:	fed518e3          	bne	a0,a3,298 <memcmp+0x14>
  }
  return 0;
 2ac:	4501                	li	a0,0
 2ae:	a019                	j	2b4 <memcmp+0x30>
      return *p1 - *p2;
 2b0:	40e7853b          	subw	a0,a5,a4
}
 2b4:	6422                	ld	s0,8(sp)
 2b6:	0141                	addi	sp,sp,16
 2b8:	8082                	ret
  return 0;
 2ba:	4501                	li	a0,0
 2bc:	bfe5                	j	2b4 <memcmp+0x30>

00000000000002be <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2be:	1141                	addi	sp,sp,-16
 2c0:	e406                	sd	ra,8(sp)
 2c2:	e022                	sd	s0,0(sp)
 2c4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2c6:	f67ff0ef          	jal	ra,22c <memmove>
}
 2ca:	60a2                	ld	ra,8(sp)
 2cc:	6402                	ld	s0,0(sp)
 2ce:	0141                	addi	sp,sp,16
 2d0:	8082                	ret

00000000000002d2 <sbrk>:

char *
sbrk(int n) {
 2d2:	1141                	addi	sp,sp,-16
 2d4:	e406                	sd	ra,8(sp)
 2d6:	e022                	sd	s0,0(sp)
 2d8:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_EAGER);
 2da:	4585                	li	a1,1
 2dc:	0b2000ef          	jal	ra,38e <sys_sbrk>
}
 2e0:	60a2                	ld	ra,8(sp)
 2e2:	6402                	ld	s0,0(sp)
 2e4:	0141                	addi	sp,sp,16
 2e6:	8082                	ret

00000000000002e8 <sbrklazy>:

char *
sbrklazy(int n) {
 2e8:	1141                	addi	sp,sp,-16
 2ea:	e406                	sd	ra,8(sp)
 2ec:	e022                	sd	s0,0(sp)
 2ee:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_LAZY);
 2f0:	4589                	li	a1,2
 2f2:	09c000ef          	jal	ra,38e <sys_sbrk>
}
 2f6:	60a2                	ld	ra,8(sp)
 2f8:	6402                	ld	s0,0(sp)
 2fa:	0141                	addi	sp,sp,16
 2fc:	8082                	ret

00000000000002fe <fork>:
# 由 usys.pl 生成 - 请勿编辑
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2fe:	4885                	li	a7,1
 ecall
 300:	00000073          	ecall
 ret
 304:	8082                	ret

0000000000000306 <exit>:
.global exit
exit:
 li a7, SYS_exit
 306:	4889                	li	a7,2
 ecall
 308:	00000073          	ecall
 ret
 30c:	8082                	ret

000000000000030e <wait>:
.global wait
wait:
 li a7, SYS_wait
 30e:	488d                	li	a7,3
 ecall
 310:	00000073          	ecall
 ret
 314:	8082                	ret

0000000000000316 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 316:	4891                	li	a7,4
 ecall
 318:	00000073          	ecall
 ret
 31c:	8082                	ret

000000000000031e <read>:
.global read
read:
 li a7, SYS_read
 31e:	4895                	li	a7,5
 ecall
 320:	00000073          	ecall
 ret
 324:	8082                	ret

0000000000000326 <write>:
.global write
write:
 li a7, SYS_write
 326:	48c1                	li	a7,16
 ecall
 328:	00000073          	ecall
 ret
 32c:	8082                	ret

000000000000032e <close>:
.global close
close:
 li a7, SYS_close
 32e:	48d5                	li	a7,21
 ecall
 330:	00000073          	ecall
 ret
 334:	8082                	ret

0000000000000336 <kill>:
.global kill
kill:
 li a7, SYS_kill
 336:	4899                	li	a7,6
 ecall
 338:	00000073          	ecall
 ret
 33c:	8082                	ret

000000000000033e <exec>:
.global exec
exec:
 li a7, SYS_exec
 33e:	489d                	li	a7,7
 ecall
 340:	00000073          	ecall
 ret
 344:	8082                	ret

0000000000000346 <open>:
.global open
open:
 li a7, SYS_open
 346:	48bd                	li	a7,15
 ecall
 348:	00000073          	ecall
 ret
 34c:	8082                	ret

000000000000034e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 34e:	48c5                	li	a7,17
 ecall
 350:	00000073          	ecall
 ret
 354:	8082                	ret

0000000000000356 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 356:	48c9                	li	a7,18
 ecall
 358:	00000073          	ecall
 ret
 35c:	8082                	ret

000000000000035e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 35e:	48a1                	li	a7,8
 ecall
 360:	00000073          	ecall
 ret
 364:	8082                	ret

0000000000000366 <link>:
.global link
link:
 li a7, SYS_link
 366:	48cd                	li	a7,19
 ecall
 368:	00000073          	ecall
 ret
 36c:	8082                	ret

000000000000036e <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 36e:	48d1                	li	a7,20
 ecall
 370:	00000073          	ecall
 ret
 374:	8082                	ret

0000000000000376 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 376:	48a5                	li	a7,9
 ecall
 378:	00000073          	ecall
 ret
 37c:	8082                	ret

000000000000037e <dup>:
.global dup
dup:
 li a7, SYS_dup
 37e:	48a9                	li	a7,10
 ecall
 380:	00000073          	ecall
 ret
 384:	8082                	ret

0000000000000386 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 386:	48ad                	li	a7,11
 ecall
 388:	00000073          	ecall
 ret
 38c:	8082                	ret

000000000000038e <sys_sbrk>:
.global sys_sbrk
sys_sbrk:
 li a7, SYS_sbrk
 38e:	48b1                	li	a7,12
 ecall
 390:	00000073          	ecall
 ret
 394:	8082                	ret

0000000000000396 <pause>:
.global pause
pause:
 li a7, SYS_pause
 396:	48b5                	li	a7,13
 ecall
 398:	00000073          	ecall
 ret
 39c:	8082                	ret

000000000000039e <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 39e:	48b9                	li	a7,14
 ecall
 3a0:	00000073          	ecall
 ret
 3a4:	8082                	ret

00000000000003a6 <dump_proc>:
.global dump_proc
dump_proc:
 li a7, SYS_dump_proc
 3a6:	48d9                	li	a7,22
 ecall
 3a8:	00000073          	ecall
 ret
 3ac:	8082                	ret

00000000000003ae <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3ae:	1101                	addi	sp,sp,-32
 3b0:	ec06                	sd	ra,24(sp)
 3b2:	e822                	sd	s0,16(sp)
 3b4:	1000                	addi	s0,sp,32
 3b6:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3ba:	4605                	li	a2,1
 3bc:	fef40593          	addi	a1,s0,-17
 3c0:	f67ff0ef          	jal	ra,326 <write>
}
 3c4:	60e2                	ld	ra,24(sp)
 3c6:	6442                	ld	s0,16(sp)
 3c8:	6105                	addi	sp,sp,32
 3ca:	8082                	ret

00000000000003cc <printint>:

static void
printint(int fd, long long xx, int base, int sgn)
{
 3cc:	715d                	addi	sp,sp,-80
 3ce:	e486                	sd	ra,72(sp)
 3d0:	e0a2                	sd	s0,64(sp)
 3d2:	fc26                	sd	s1,56(sp)
 3d4:	f84a                	sd	s2,48(sp)
 3d6:	f44e                	sd	s3,40(sp)
 3d8:	0880                	addi	s0,sp,80
 3da:	892a                	mv	s2,a0
  char buf[20];
  int i, neg;
  unsigned long long x;

  neg = 0;
  if(sgn && xx < 0){
 3dc:	c299                	beqz	a3,3e2 <printint+0x16>
 3de:	0805c163          	bltz	a1,460 <printint+0x94>
  neg = 0;
 3e2:	4881                	li	a7,0
 3e4:	fb840693          	addi	a3,s0,-72
    x = -xx;
  } else {
    x = xx;
  }

  i = 0;
 3e8:	4781                	li	a5,0
  do{
    buf[i++] = digits[x % base];
 3ea:	00000517          	auipc	a0,0x0
 3ee:	4ee50513          	addi	a0,a0,1262 # 8d8 <digits>
 3f2:	883e                	mv	a6,a5
 3f4:	2785                	addiw	a5,a5,1
 3f6:	02c5f733          	remu	a4,a1,a2
 3fa:	972a                	add	a4,a4,a0
 3fc:	00074703          	lbu	a4,0(a4)
 400:	00e68023          	sb	a4,0(a3)
  }while((x /= base) != 0);
 404:	872e                	mv	a4,a1
 406:	02c5d5b3          	divu	a1,a1,a2
 40a:	0685                	addi	a3,a3,1
 40c:	fec773e3          	bgeu	a4,a2,3f2 <printint+0x26>
  if(neg)
 410:	00088b63          	beqz	a7,426 <printint+0x5a>
    buf[i++] = '-';
 414:	fd040713          	addi	a4,s0,-48
 418:	97ba                	add	a5,a5,a4
 41a:	02d00713          	li	a4,45
 41e:	fee78423          	sb	a4,-24(a5)
 422:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
 426:	02f05663          	blez	a5,452 <printint+0x86>
 42a:	fb840713          	addi	a4,s0,-72
 42e:	00f704b3          	add	s1,a4,a5
 432:	fff70993          	addi	s3,a4,-1
 436:	99be                	add	s3,s3,a5
 438:	37fd                	addiw	a5,a5,-1
 43a:	1782                	slli	a5,a5,0x20
 43c:	9381                	srli	a5,a5,0x20
 43e:	40f989b3          	sub	s3,s3,a5
    putc(fd, buf[i]);
 442:	fff4c583          	lbu	a1,-1(s1)
 446:	854a                	mv	a0,s2
 448:	f67ff0ef          	jal	ra,3ae <putc>
  while(--i >= 0)
 44c:	14fd                	addi	s1,s1,-1
 44e:	ff349ae3          	bne	s1,s3,442 <printint+0x76>
}
 452:	60a6                	ld	ra,72(sp)
 454:	6406                	ld	s0,64(sp)
 456:	74e2                	ld	s1,56(sp)
 458:	7942                	ld	s2,48(sp)
 45a:	79a2                	ld	s3,40(sp)
 45c:	6161                	addi	sp,sp,80
 45e:	8082                	ret
    x = -xx;
 460:	40b005b3          	neg	a1,a1
    neg = 1;
 464:	4885                	li	a7,1
    x = -xx;
 466:	bfbd                	j	3e4 <printint+0x18>

0000000000000468 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %c, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 468:	7119                	addi	sp,sp,-128
 46a:	fc86                	sd	ra,120(sp)
 46c:	f8a2                	sd	s0,112(sp)
 46e:	f4a6                	sd	s1,104(sp)
 470:	f0ca                	sd	s2,96(sp)
 472:	ecce                	sd	s3,88(sp)
 474:	e8d2                	sd	s4,80(sp)
 476:	e4d6                	sd	s5,72(sp)
 478:	e0da                	sd	s6,64(sp)
 47a:	fc5e                	sd	s7,56(sp)
 47c:	f862                	sd	s8,48(sp)
 47e:	f466                	sd	s9,40(sp)
 480:	f06a                	sd	s10,32(sp)
 482:	ec6e                	sd	s11,24(sp)
 484:	0100                	addi	s0,sp,128
  char *s;
  int c0, c1, c2, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 486:	0005c903          	lbu	s2,0(a1)
 48a:	24090c63          	beqz	s2,6e2 <vprintf+0x27a>
 48e:	8b2a                	mv	s6,a0
 490:	8a2e                	mv	s4,a1
 492:	8bb2                	mv	s7,a2
  state = 0;
 494:	4981                	li	s3,0
  for(i = 0; fmt[i]; i++){
 496:	4481                	li	s1,0
 498:	4701                	li	a4,0
      if(c0 == '%'){
        state = '%';
      } else {
        putc(fd, c0);
      }
    } else if(state == '%'){
 49a:	02500a93          	li	s5,37
      c1 = c2 = 0;
      if(c0) c1 = fmt[i+1] & 0xff;
      if(c1) c2 = fmt[i+2] & 0xff;
      if(c0 == 'd'){
 49e:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c0 == 'l' && c1 == 'd'){
 4a2:	06c00d13          	li	s10,108
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 2;
      } else if(c0 == 'u'){
 4a6:	07500d93          	li	s11,117
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4aa:	00000c97          	auipc	s9,0x0
 4ae:	42ec8c93          	addi	s9,s9,1070 # 8d8 <digits>
 4b2:	a005                	j	4d2 <vprintf+0x6a>
        putc(fd, c0);
 4b4:	85ca                	mv	a1,s2
 4b6:	855a                	mv	a0,s6
 4b8:	ef7ff0ef          	jal	ra,3ae <putc>
 4bc:	a019                	j	4c2 <vprintf+0x5a>
    } else if(state == '%'){
 4be:	03598263          	beq	s3,s5,4e2 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 4c2:	2485                	addiw	s1,s1,1
 4c4:	8726                	mv	a4,s1
 4c6:	009a07b3          	add	a5,s4,s1
 4ca:	0007c903          	lbu	s2,0(a5)
 4ce:	20090a63          	beqz	s2,6e2 <vprintf+0x27a>
    c0 = fmt[i] & 0xff;
 4d2:	0009079b          	sext.w	a5,s2
    if(state == 0){
 4d6:	fe0994e3          	bnez	s3,4be <vprintf+0x56>
      if(c0 == '%'){
 4da:	fd579de3          	bne	a5,s5,4b4 <vprintf+0x4c>
        state = '%';
 4de:	89be                	mv	s3,a5
 4e0:	b7cd                	j	4c2 <vprintf+0x5a>
      if(c0) c1 = fmt[i+1] & 0xff;
 4e2:	c3c1                	beqz	a5,562 <vprintf+0xfa>
 4e4:	00ea06b3          	add	a3,s4,a4
 4e8:	0016c683          	lbu	a3,1(a3)
      c1 = c2 = 0;
 4ec:	8636                	mv	a2,a3
      if(c1) c2 = fmt[i+2] & 0xff;
 4ee:	c681                	beqz	a3,4f6 <vprintf+0x8e>
 4f0:	9752                	add	a4,a4,s4
 4f2:	00274603          	lbu	a2,2(a4)
      if(c0 == 'd'){
 4f6:	03878e63          	beq	a5,s8,532 <vprintf+0xca>
      } else if(c0 == 'l' && c1 == 'd'){
 4fa:	05a78863          	beq	a5,s10,54a <vprintf+0xe2>
      } else if(c0 == 'u'){
 4fe:	0db78b63          	beq	a5,s11,5d4 <vprintf+0x16c>
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 2;
      } else if(c0 == 'x'){
 502:	07800713          	li	a4,120
 506:	10e78d63          	beq	a5,a4,620 <vprintf+0x1b8>
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 2;
      } else if(c0 == 'p'){
 50a:	07000713          	li	a4,112
 50e:	14e78263          	beq	a5,a4,652 <vprintf+0x1ea>
        printptr(fd, va_arg(ap, uint64));
      } else if(c0 == 'c'){
 512:	06300713          	li	a4,99
 516:	16e78f63          	beq	a5,a4,694 <vprintf+0x22c>
        putc(fd, va_arg(ap, uint32));
      } else if(c0 == 's'){
 51a:	07300713          	li	a4,115
 51e:	18e78563          	beq	a5,a4,6a8 <vprintf+0x240>
        if((s = va_arg(ap, char*)) == 0)
          s = "(null)";
        for(; *s; s++)
          putc(fd, *s);
      } else if(c0 == '%'){
 522:	05579063          	bne	a5,s5,562 <vprintf+0xfa>
        putc(fd, '%');
 526:	85d6                	mv	a1,s5
 528:	855a                	mv	a0,s6
 52a:	e85ff0ef          	jal	ra,3ae <putc>
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c0);
      }

      state = 0;
 52e:	4981                	li	s3,0
 530:	bf49                	j	4c2 <vprintf+0x5a>
        printint(fd, va_arg(ap, int), 10, 1);
 532:	008b8913          	addi	s2,s7,8
 536:	4685                	li	a3,1
 538:	4629                	li	a2,10
 53a:	000ba583          	lw	a1,0(s7)
 53e:	855a                	mv	a0,s6
 540:	e8dff0ef          	jal	ra,3cc <printint>
 544:	8bca                	mv	s7,s2
      state = 0;
 546:	4981                	li	s3,0
 548:	bfad                	j	4c2 <vprintf+0x5a>
      } else if(c0 == 'l' && c1 == 'd'){
 54a:	03868663          	beq	a3,s8,576 <vprintf+0x10e>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 54e:	05a68163          	beq	a3,s10,590 <vprintf+0x128>
      } else if(c0 == 'l' && c1 == 'u'){
 552:	09b68d63          	beq	a3,s11,5ec <vprintf+0x184>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 556:	03a68f63          	beq	a3,s10,594 <vprintf+0x12c>
      } else if(c0 == 'l' && c1 == 'x'){
 55a:	07800793          	li	a5,120
 55e:	0cf68d63          	beq	a3,a5,638 <vprintf+0x1d0>
        putc(fd, '%');
 562:	85d6                	mv	a1,s5
 564:	855a                	mv	a0,s6
 566:	e49ff0ef          	jal	ra,3ae <putc>
        putc(fd, c0);
 56a:	85ca                	mv	a1,s2
 56c:	855a                	mv	a0,s6
 56e:	e41ff0ef          	jal	ra,3ae <putc>
      state = 0;
 572:	4981                	li	s3,0
 574:	b7b9                	j	4c2 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 576:	008b8913          	addi	s2,s7,8
 57a:	4685                	li	a3,1
 57c:	4629                	li	a2,10
 57e:	000bb583          	ld	a1,0(s7)
 582:	855a                	mv	a0,s6
 584:	e49ff0ef          	jal	ra,3cc <printint>
        i += 1;
 588:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 1);
 58a:	8bca                	mv	s7,s2
      state = 0;
 58c:	4981                	li	s3,0
        i += 1;
 58e:	bf15                	j	4c2 <vprintf+0x5a>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 590:	03860563          	beq	a2,s8,5ba <vprintf+0x152>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 594:	07b60963          	beq	a2,s11,606 <vprintf+0x19e>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
 598:	07800793          	li	a5,120
 59c:	fcf613e3          	bne	a2,a5,562 <vprintf+0xfa>
        printint(fd, va_arg(ap, uint64), 16, 0);
 5a0:	008b8913          	addi	s2,s7,8
 5a4:	4681                	li	a3,0
 5a6:	4641                	li	a2,16
 5a8:	000bb583          	ld	a1,0(s7)
 5ac:	855a                	mv	a0,s6
 5ae:	e1fff0ef          	jal	ra,3cc <printint>
        i += 2;
 5b2:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 16, 0);
 5b4:	8bca                	mv	s7,s2
      state = 0;
 5b6:	4981                	li	s3,0
        i += 2;
 5b8:	b729                	j	4c2 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 5ba:	008b8913          	addi	s2,s7,8
 5be:	4685                	li	a3,1
 5c0:	4629                	li	a2,10
 5c2:	000bb583          	ld	a1,0(s7)
 5c6:	855a                	mv	a0,s6
 5c8:	e05ff0ef          	jal	ra,3cc <printint>
        i += 2;
 5cc:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 1);
 5ce:	8bca                	mv	s7,s2
      state = 0;
 5d0:	4981                	li	s3,0
        i += 2;
 5d2:	bdc5                	j	4c2 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint32), 10, 0);
 5d4:	008b8913          	addi	s2,s7,8
 5d8:	4681                	li	a3,0
 5da:	4629                	li	a2,10
 5dc:	000be583          	lwu	a1,0(s7)
 5e0:	855a                	mv	a0,s6
 5e2:	debff0ef          	jal	ra,3cc <printint>
 5e6:	8bca                	mv	s7,s2
      state = 0;
 5e8:	4981                	li	s3,0
 5ea:	bde1                	j	4c2 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5ec:	008b8913          	addi	s2,s7,8
 5f0:	4681                	li	a3,0
 5f2:	4629                	li	a2,10
 5f4:	000bb583          	ld	a1,0(s7)
 5f8:	855a                	mv	a0,s6
 5fa:	dd3ff0ef          	jal	ra,3cc <printint>
        i += 1;
 5fe:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 0);
 600:	8bca                	mv	s7,s2
      state = 0;
 602:	4981                	li	s3,0
        i += 1;
 604:	bd7d                	j	4c2 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 606:	008b8913          	addi	s2,s7,8
 60a:	4681                	li	a3,0
 60c:	4629                	li	a2,10
 60e:	000bb583          	ld	a1,0(s7)
 612:	855a                	mv	a0,s6
 614:	db9ff0ef          	jal	ra,3cc <printint>
        i += 2;
 618:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 0);
 61a:	8bca                	mv	s7,s2
      state = 0;
 61c:	4981                	li	s3,0
        i += 2;
 61e:	b555                	j	4c2 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint32), 16, 0);
 620:	008b8913          	addi	s2,s7,8
 624:	4681                	li	a3,0
 626:	4641                	li	a2,16
 628:	000be583          	lwu	a1,0(s7)
 62c:	855a                	mv	a0,s6
 62e:	d9fff0ef          	jal	ra,3cc <printint>
 632:	8bca                	mv	s7,s2
      state = 0;
 634:	4981                	li	s3,0
 636:	b571                	j	4c2 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 16, 0);
 638:	008b8913          	addi	s2,s7,8
 63c:	4681                	li	a3,0
 63e:	4641                	li	a2,16
 640:	000bb583          	ld	a1,0(s7)
 644:	855a                	mv	a0,s6
 646:	d87ff0ef          	jal	ra,3cc <printint>
        i += 1;
 64a:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 16, 0);
 64c:	8bca                	mv	s7,s2
      state = 0;
 64e:	4981                	li	s3,0
        i += 1;
 650:	bd8d                	j	4c2 <vprintf+0x5a>
        printptr(fd, va_arg(ap, uint64));
 652:	008b8793          	addi	a5,s7,8
 656:	f8f43423          	sd	a5,-120(s0)
 65a:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 65e:	03000593          	li	a1,48
 662:	855a                	mv	a0,s6
 664:	d4bff0ef          	jal	ra,3ae <putc>
  putc(fd, 'x');
 668:	07800593          	li	a1,120
 66c:	855a                	mv	a0,s6
 66e:	d41ff0ef          	jal	ra,3ae <putc>
 672:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 674:	03c9d793          	srli	a5,s3,0x3c
 678:	97e6                	add	a5,a5,s9
 67a:	0007c583          	lbu	a1,0(a5)
 67e:	855a                	mv	a0,s6
 680:	d2fff0ef          	jal	ra,3ae <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 684:	0992                	slli	s3,s3,0x4
 686:	397d                	addiw	s2,s2,-1
 688:	fe0916e3          	bnez	s2,674 <vprintf+0x20c>
        printptr(fd, va_arg(ap, uint64));
 68c:	f8843b83          	ld	s7,-120(s0)
      state = 0;
 690:	4981                	li	s3,0
 692:	bd05                	j	4c2 <vprintf+0x5a>
        putc(fd, va_arg(ap, uint32));
 694:	008b8913          	addi	s2,s7,8
 698:	000bc583          	lbu	a1,0(s7)
 69c:	855a                	mv	a0,s6
 69e:	d11ff0ef          	jal	ra,3ae <putc>
 6a2:	8bca                	mv	s7,s2
      state = 0;
 6a4:	4981                	li	s3,0
 6a6:	bd31                	j	4c2 <vprintf+0x5a>
        if((s = va_arg(ap, char*)) == 0)
 6a8:	008b8993          	addi	s3,s7,8
 6ac:	000bb903          	ld	s2,0(s7)
 6b0:	00090f63          	beqz	s2,6ce <vprintf+0x266>
        for(; *s; s++)
 6b4:	00094583          	lbu	a1,0(s2)
 6b8:	c195                	beqz	a1,6dc <vprintf+0x274>
          putc(fd, *s);
 6ba:	855a                	mv	a0,s6
 6bc:	cf3ff0ef          	jal	ra,3ae <putc>
        for(; *s; s++)
 6c0:	0905                	addi	s2,s2,1
 6c2:	00094583          	lbu	a1,0(s2)
 6c6:	f9f5                	bnez	a1,6ba <vprintf+0x252>
        if((s = va_arg(ap, char*)) == 0)
 6c8:	8bce                	mv	s7,s3
      state = 0;
 6ca:	4981                	li	s3,0
 6cc:	bbdd                	j	4c2 <vprintf+0x5a>
          s = "(null)";
 6ce:	00000917          	auipc	s2,0x0
 6d2:	20290913          	addi	s2,s2,514 # 8d0 <malloc+0xec>
        for(; *s; s++)
 6d6:	02800593          	li	a1,40
 6da:	b7c5                	j	6ba <vprintf+0x252>
        if((s = va_arg(ap, char*)) == 0)
 6dc:	8bce                	mv	s7,s3
      state = 0;
 6de:	4981                	li	s3,0
 6e0:	b3cd                	j	4c2 <vprintf+0x5a>
    }
  }
}
 6e2:	70e6                	ld	ra,120(sp)
 6e4:	7446                	ld	s0,112(sp)
 6e6:	74a6                	ld	s1,104(sp)
 6e8:	7906                	ld	s2,96(sp)
 6ea:	69e6                	ld	s3,88(sp)
 6ec:	6a46                	ld	s4,80(sp)
 6ee:	6aa6                	ld	s5,72(sp)
 6f0:	6b06                	ld	s6,64(sp)
 6f2:	7be2                	ld	s7,56(sp)
 6f4:	7c42                	ld	s8,48(sp)
 6f6:	7ca2                	ld	s9,40(sp)
 6f8:	7d02                	ld	s10,32(sp)
 6fa:	6de2                	ld	s11,24(sp)
 6fc:	6109                	addi	sp,sp,128
 6fe:	8082                	ret

0000000000000700 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 700:	715d                	addi	sp,sp,-80
 702:	ec06                	sd	ra,24(sp)
 704:	e822                	sd	s0,16(sp)
 706:	1000                	addi	s0,sp,32
 708:	e010                	sd	a2,0(s0)
 70a:	e414                	sd	a3,8(s0)
 70c:	e818                	sd	a4,16(s0)
 70e:	ec1c                	sd	a5,24(s0)
 710:	03043023          	sd	a6,32(s0)
 714:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 718:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 71c:	8622                	mv	a2,s0
 71e:	d4bff0ef          	jal	ra,468 <vprintf>
}
 722:	60e2                	ld	ra,24(sp)
 724:	6442                	ld	s0,16(sp)
 726:	6161                	addi	sp,sp,80
 728:	8082                	ret

000000000000072a <printf>:

void
printf(const char *fmt, ...)
{
 72a:	711d                	addi	sp,sp,-96
 72c:	ec06                	sd	ra,24(sp)
 72e:	e822                	sd	s0,16(sp)
 730:	1000                	addi	s0,sp,32
 732:	e40c                	sd	a1,8(s0)
 734:	e810                	sd	a2,16(s0)
 736:	ec14                	sd	a3,24(s0)
 738:	f018                	sd	a4,32(s0)
 73a:	f41c                	sd	a5,40(s0)
 73c:	03043823          	sd	a6,48(s0)
 740:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 744:	00840613          	addi	a2,s0,8
 748:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 74c:	85aa                	mv	a1,a0
 74e:	4505                	li	a0,1
 750:	d19ff0ef          	jal	ra,468 <vprintf>
}
 754:	60e2                	ld	ra,24(sp)
 756:	6442                	ld	s0,16(sp)
 758:	6125                	addi	sp,sp,96
 75a:	8082                	ret

000000000000075c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 75c:	1141                	addi	sp,sp,-16
 75e:	e422                	sd	s0,8(sp)
 760:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 762:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 766:	00001797          	auipc	a5,0x1
 76a:	89a7b783          	ld	a5,-1894(a5) # 1000 <freep>
 76e:	a805                	j	79e <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 770:	4618                	lw	a4,8(a2)
 772:	9db9                	addw	a1,a1,a4
 774:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 778:	6398                	ld	a4,0(a5)
 77a:	6318                	ld	a4,0(a4)
 77c:	fee53823          	sd	a4,-16(a0)
 780:	a091                	j	7c4 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 782:	ff852703          	lw	a4,-8(a0)
 786:	9e39                	addw	a2,a2,a4
 788:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 78a:	ff053703          	ld	a4,-16(a0)
 78e:	e398                	sd	a4,0(a5)
 790:	a099                	j	7d6 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 792:	6398                	ld	a4,0(a5)
 794:	00e7e463          	bltu	a5,a4,79c <free+0x40>
 798:	00e6ea63          	bltu	a3,a4,7ac <free+0x50>
{
 79c:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 79e:	fed7fae3          	bgeu	a5,a3,792 <free+0x36>
 7a2:	6398                	ld	a4,0(a5)
 7a4:	00e6e463          	bltu	a3,a4,7ac <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7a8:	fee7eae3          	bltu	a5,a4,79c <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 7ac:	ff852583          	lw	a1,-8(a0)
 7b0:	6390                	ld	a2,0(a5)
 7b2:	02059713          	slli	a4,a1,0x20
 7b6:	9301                	srli	a4,a4,0x20
 7b8:	0712                	slli	a4,a4,0x4
 7ba:	9736                	add	a4,a4,a3
 7bc:	fae60ae3          	beq	a2,a4,770 <free+0x14>
    bp->s.ptr = p->s.ptr;
 7c0:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7c4:	4790                	lw	a2,8(a5)
 7c6:	02061713          	slli	a4,a2,0x20
 7ca:	9301                	srli	a4,a4,0x20
 7cc:	0712                	slli	a4,a4,0x4
 7ce:	973e                	add	a4,a4,a5
 7d0:	fae689e3          	beq	a3,a4,782 <free+0x26>
  } else
    p->s.ptr = bp;
 7d4:	e394                	sd	a3,0(a5)
  freep = p;
 7d6:	00001717          	auipc	a4,0x1
 7da:	82f73523          	sd	a5,-2006(a4) # 1000 <freep>
}
 7de:	6422                	ld	s0,8(sp)
 7e0:	0141                	addi	sp,sp,16
 7e2:	8082                	ret

00000000000007e4 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7e4:	7139                	addi	sp,sp,-64
 7e6:	fc06                	sd	ra,56(sp)
 7e8:	f822                	sd	s0,48(sp)
 7ea:	f426                	sd	s1,40(sp)
 7ec:	f04a                	sd	s2,32(sp)
 7ee:	ec4e                	sd	s3,24(sp)
 7f0:	e852                	sd	s4,16(sp)
 7f2:	e456                	sd	s5,8(sp)
 7f4:	e05a                	sd	s6,0(sp)
 7f6:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7f8:	02051493          	slli	s1,a0,0x20
 7fc:	9081                	srli	s1,s1,0x20
 7fe:	04bd                	addi	s1,s1,15
 800:	8091                	srli	s1,s1,0x4
 802:	0014899b          	addiw	s3,s1,1
 806:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 808:	00000517          	auipc	a0,0x0
 80c:	7f853503          	ld	a0,2040(a0) # 1000 <freep>
 810:	c515                	beqz	a0,83c <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 812:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 814:	4798                	lw	a4,8(a5)
 816:	02977f63          	bgeu	a4,s1,854 <malloc+0x70>
 81a:	8a4e                	mv	s4,s3
 81c:	0009871b          	sext.w	a4,s3
 820:	6685                	lui	a3,0x1
 822:	00d77363          	bgeu	a4,a3,828 <malloc+0x44>
 826:	6a05                	lui	s4,0x1
 828:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 82c:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 830:	00000917          	auipc	s2,0x0
 834:	7d090913          	addi	s2,s2,2000 # 1000 <freep>
  if(p == SBRK_ERROR)
 838:	5afd                	li	s5,-1
 83a:	a0bd                	j	8a8 <malloc+0xc4>
    base.s.ptr = freep = prevp = &base;
 83c:	00000797          	auipc	a5,0x0
 840:	7d478793          	addi	a5,a5,2004 # 1010 <base>
 844:	00000717          	auipc	a4,0x0
 848:	7af73e23          	sd	a5,1980(a4) # 1000 <freep>
 84c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 84e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 852:	b7e1                	j	81a <malloc+0x36>
      if(p->s.size == nunits)
 854:	02e48b63          	beq	s1,a4,88a <malloc+0xa6>
        p->s.size -= nunits;
 858:	4137073b          	subw	a4,a4,s3
 85c:	c798                	sw	a4,8(a5)
        p += p->s.size;
 85e:	1702                	slli	a4,a4,0x20
 860:	9301                	srli	a4,a4,0x20
 862:	0712                	slli	a4,a4,0x4
 864:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 866:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 86a:	00000717          	auipc	a4,0x0
 86e:	78a73b23          	sd	a0,1942(a4) # 1000 <freep>
      return (void*)(p + 1);
 872:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 876:	70e2                	ld	ra,56(sp)
 878:	7442                	ld	s0,48(sp)
 87a:	74a2                	ld	s1,40(sp)
 87c:	7902                	ld	s2,32(sp)
 87e:	69e2                	ld	s3,24(sp)
 880:	6a42                	ld	s4,16(sp)
 882:	6aa2                	ld	s5,8(sp)
 884:	6b02                	ld	s6,0(sp)
 886:	6121                	addi	sp,sp,64
 888:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 88a:	6398                	ld	a4,0(a5)
 88c:	e118                	sd	a4,0(a0)
 88e:	bff1                	j	86a <malloc+0x86>
  hp->s.size = nu;
 890:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 894:	0541                	addi	a0,a0,16
 896:	ec7ff0ef          	jal	ra,75c <free>
  return freep;
 89a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 89e:	dd61                	beqz	a0,876 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8a0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8a2:	4798                	lw	a4,8(a5)
 8a4:	fa9778e3          	bgeu	a4,s1,854 <malloc+0x70>
    if(p == freep)
 8a8:	00093703          	ld	a4,0(s2)
 8ac:	853e                	mv	a0,a5
 8ae:	fef719e3          	bne	a4,a5,8a0 <malloc+0xbc>
  p = sbrk(nu * sizeof(Header));
 8b2:	8552                	mv	a0,s4
 8b4:	a1fff0ef          	jal	ra,2d2 <sbrk>
  if(p == SBRK_ERROR)
 8b8:	fd551ce3          	bne	a0,s5,890 <malloc+0xac>
        return 0;
 8bc:	4501                	li	a0,0
 8be:	bf65                	j	876 <malloc+0x92>
