
user/_cowtest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <test_simple_cow>:
// user/cowtest.c
#include "kernel/types.h"
#include "user/user.h"

// 测试1：父子进程写同一地址应互不影响
void test_simple_cow() {
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
  int x = 100;
  int pid = fork();
   8:	358000ef          	jal	ra,360 <fork>
  if (pid == 0) {
   c:	cd11                	beqz	a0,28 <test_simple_cow+0x28>
    x = 200;
    exit(0);
  } else {
    wait(0);
   e:	4501                	li	a0,0
  10:	360000ef          	jal	ra,370 <wait>
    if (x != 100) {
      printf("COW test1 failed: parent value changed\n");
      exit(1);
    }
    printf("COW test1 passed\n");
  14:	00001517          	auipc	a0,0x1
  18:	91c50513          	addi	a0,a0,-1764 # 930 <malloc+0xea>
  1c:	770000ef          	jal	ra,78c <printf>
  }
}
  20:	60a2                	ld	ra,8(sp)
  22:	6402                	ld	s0,0(sp)
  24:	0141                	addi	sp,sp,16
  26:	8082                	ret
    exit(0);
  28:	340000ef          	jal	ra,368 <exit>

000000000000002c <test_multi_fork>:

// 测试2：多层 fork 共享
void test_multi_fork() {
  2c:	1141                	addi	sp,sp,-16
  2e:	e406                	sd	ra,8(sp)
  30:	e022                	sd	s0,0(sp)
  32:	0800                	addi	s0,sp,16
  int val = 42;
  int p1 = fork();
  34:	32c000ef          	jal	ra,360 <fork>
  if (p1 == 0) {
  38:	ed01                	bnez	a0,50 <test_multi_fork+0x24>
    val = 1;
    int p2 = fork();
  3a:	326000ef          	jal	ra,360 <fork>
    if (p2 == 0) {
  3e:	e119                	bnez	a0,44 <test_multi_fork+0x18>
      val = 2;
      exit(0);
  40:	328000ef          	jal	ra,368 <exit>
    }
    wait(0);
  44:	4501                	li	a0,0
  46:	32a000ef          	jal	ra,370 <wait>
    if (val != 1) {
      printf("COW test2 child failed\n");
      exit(1);
    }
    exit(0);
  4a:	4501                	li	a0,0
  4c:	31c000ef          	jal	ra,368 <exit>
  }
  wait(0);
  50:	4501                	li	a0,0
  52:	31e000ef          	jal	ra,370 <wait>
  if (val != 42) {
    printf("COW test2 parent failed\n");
    exit(1);
  }
  printf("COW test2 passed\n");
  56:	00001517          	auipc	a0,0x1
  5a:	8f250513          	addi	a0,a0,-1806 # 948 <malloc+0x102>
  5e:	72e000ef          	jal	ra,78c <printf>
}
  62:	60a2                	ld	ra,8(sp)
  64:	6402                	ld	s0,0(sp)
  66:	0141                	addi	sp,sp,16
  68:	8082                	ret

000000000000006a <test_memory_leak>:

// 测试3：写后释放，内存应正确回收
void test_memory_leak() {
  6a:	1101                	addi	sp,sp,-32
  6c:	ec06                	sd	ra,24(sp)
  6e:	e822                	sd	s0,16(sp)
  70:	e426                	sd	s1,8(sp)
  72:	e04a                	sd	s2,0(sp)
  74:	1000                	addi	s0,sp,32
  // 简单验证：多次 fork + write 不应 panic
  for(int i = 0; i < 10; i++){
  76:	4481                	li	s1,0
  78:	4929                	li	s2,10
    int pid = fork();
  7a:	2e6000ef          	jal	ra,360 <fork>
    if(pid == 0){
  7e:	c11d                	beqz	a0,a4 <test_memory_leak+0x3a>
      volatile int *p = (int*)0x1000; // 已映射的用户页
      *p = i;
      exit(0);
    }
    wait(0);
  80:	4501                	li	a0,0
  82:	2ee000ef          	jal	ra,370 <wait>
  for(int i = 0; i < 10; i++){
  86:	2485                	addiw	s1,s1,1
  88:	ff2499e3          	bne	s1,s2,7a <test_memory_leak+0x10>
  }
  printf("COW test3 (no panic) passed\n");
  8c:	00001517          	auipc	a0,0x1
  90:	8d450513          	addi	a0,a0,-1836 # 960 <malloc+0x11a>
  94:	6f8000ef          	jal	ra,78c <printf>
}
  98:	60e2                	ld	ra,24(sp)
  9a:	6442                	ld	s0,16(sp)
  9c:	64a2                	ld	s1,8(sp)
  9e:	6902                	ld	s2,0(sp)
  a0:	6105                	addi	sp,sp,32
  a2:	8082                	ret
      *p = i;
  a4:	6785                	lui	a5,0x1
  a6:	c384                	sw	s1,0(a5)
      exit(0);
  a8:	2c0000ef          	jal	ra,368 <exit>

00000000000000ac <main>:

int main(void) {
  ac:	1141                	addi	sp,sp,-16
  ae:	e406                	sd	ra,8(sp)
  b0:	e022                	sd	s0,0(sp)
  b2:	0800                	addi	s0,sp,16
  test_simple_cow();
  b4:	f4dff0ef          	jal	ra,0 <test_simple_cow>
  test_multi_fork();
  b8:	f75ff0ef          	jal	ra,2c <test_multi_fork>
  test_memory_leak();
  bc:	fafff0ef          	jal	ra,6a <test_memory_leak>
  printf("All COW tests passed!\n");
  c0:	00001517          	auipc	a0,0x1
  c4:	8c050513          	addi	a0,a0,-1856 # 980 <malloc+0x13a>
  c8:	6c4000ef          	jal	ra,78c <printf>
  exit(0);
  cc:	4501                	li	a0,0
  ce:	29a000ef          	jal	ra,368 <exit>

00000000000000d2 <start>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
start(int argc, char **argv)
{
  d2:	1141                	addi	sp,sp,-16
  d4:	e406                	sd	ra,8(sp)
  d6:	e022                	sd	s0,0(sp)
  d8:	0800                	addi	s0,sp,16
  int r;
  extern int main(int argc, char **argv);
  r = main(argc, argv);
  da:	fd3ff0ef          	jal	ra,ac <main>
  exit(r);
  de:	28a000ef          	jal	ra,368 <exit>

00000000000000e2 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  e2:	1141                	addi	sp,sp,-16
  e4:	e422                	sd	s0,8(sp)
  e6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  e8:	87aa                	mv	a5,a0
  ea:	0585                	addi	a1,a1,1
  ec:	0785                	addi	a5,a5,1
  ee:	fff5c703          	lbu	a4,-1(a1)
  f2:	fee78fa3          	sb	a4,-1(a5) # fff <digits+0x65f>
  f6:	fb75                	bnez	a4,ea <strcpy+0x8>
    ;
  return os;
}
  f8:	6422                	ld	s0,8(sp)
  fa:	0141                	addi	sp,sp,16
  fc:	8082                	ret

00000000000000fe <strcmp>:

int
strcmp(const char *p, const char *q)
{
  fe:	1141                	addi	sp,sp,-16
 100:	e422                	sd	s0,8(sp)
 102:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 104:	00054783          	lbu	a5,0(a0)
 108:	cb91                	beqz	a5,11c <strcmp+0x1e>
 10a:	0005c703          	lbu	a4,0(a1)
 10e:	00f71763          	bne	a4,a5,11c <strcmp+0x1e>
    p++, q++;
 112:	0505                	addi	a0,a0,1
 114:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 116:	00054783          	lbu	a5,0(a0)
 11a:	fbe5                	bnez	a5,10a <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 11c:	0005c503          	lbu	a0,0(a1)
}
 120:	40a7853b          	subw	a0,a5,a0
 124:	6422                	ld	s0,8(sp)
 126:	0141                	addi	sp,sp,16
 128:	8082                	ret

000000000000012a <strlen>:

uint
strlen(const char *s)
{
 12a:	1141                	addi	sp,sp,-16
 12c:	e422                	sd	s0,8(sp)
 12e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 130:	00054783          	lbu	a5,0(a0)
 134:	cf91                	beqz	a5,150 <strlen+0x26>
 136:	0505                	addi	a0,a0,1
 138:	87aa                	mv	a5,a0
 13a:	4685                	li	a3,1
 13c:	9e89                	subw	a3,a3,a0
 13e:	00f6853b          	addw	a0,a3,a5
 142:	0785                	addi	a5,a5,1
 144:	fff7c703          	lbu	a4,-1(a5)
 148:	fb7d                	bnez	a4,13e <strlen+0x14>
    ;
  return n;
}
 14a:	6422                	ld	s0,8(sp)
 14c:	0141                	addi	sp,sp,16
 14e:	8082                	ret
  for(n = 0; s[n]; n++)
 150:	4501                	li	a0,0
 152:	bfe5                	j	14a <strlen+0x20>

0000000000000154 <memset>:

void*
memset(void *dst, int c, uint n)
{
 154:	1141                	addi	sp,sp,-16
 156:	e422                	sd	s0,8(sp)
 158:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 15a:	ca19                	beqz	a2,170 <memset+0x1c>
 15c:	87aa                	mv	a5,a0
 15e:	1602                	slli	a2,a2,0x20
 160:	9201                	srli	a2,a2,0x20
 162:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 166:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 16a:	0785                	addi	a5,a5,1
 16c:	fee79de3          	bne	a5,a4,166 <memset+0x12>
  }
  return dst;
}
 170:	6422                	ld	s0,8(sp)
 172:	0141                	addi	sp,sp,16
 174:	8082                	ret

0000000000000176 <strchr>:

char*
strchr(const char *s, char c)
{
 176:	1141                	addi	sp,sp,-16
 178:	e422                	sd	s0,8(sp)
 17a:	0800                	addi	s0,sp,16
  for(; *s; s++)
 17c:	00054783          	lbu	a5,0(a0)
 180:	cb99                	beqz	a5,196 <strchr+0x20>
    if(*s == c)
 182:	00f58763          	beq	a1,a5,190 <strchr+0x1a>
  for(; *s; s++)
 186:	0505                	addi	a0,a0,1
 188:	00054783          	lbu	a5,0(a0)
 18c:	fbfd                	bnez	a5,182 <strchr+0xc>
      return (char*)s;
  return 0;
 18e:	4501                	li	a0,0
}
 190:	6422                	ld	s0,8(sp)
 192:	0141                	addi	sp,sp,16
 194:	8082                	ret
  return 0;
 196:	4501                	li	a0,0
 198:	bfe5                	j	190 <strchr+0x1a>

000000000000019a <gets>:

char*
gets(char *buf, int max)
{
 19a:	711d                	addi	sp,sp,-96
 19c:	ec86                	sd	ra,88(sp)
 19e:	e8a2                	sd	s0,80(sp)
 1a0:	e4a6                	sd	s1,72(sp)
 1a2:	e0ca                	sd	s2,64(sp)
 1a4:	fc4e                	sd	s3,56(sp)
 1a6:	f852                	sd	s4,48(sp)
 1a8:	f456                	sd	s5,40(sp)
 1aa:	f05a                	sd	s6,32(sp)
 1ac:	ec5e                	sd	s7,24(sp)
 1ae:	1080                	addi	s0,sp,96
 1b0:	8baa                	mv	s7,a0
 1b2:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1b4:	892a                	mv	s2,a0
 1b6:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1b8:	4aa9                	li	s5,10
 1ba:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1bc:	89a6                	mv	s3,s1
 1be:	2485                	addiw	s1,s1,1
 1c0:	0344d663          	bge	s1,s4,1ec <gets+0x52>
    cc = read(0, &c, 1);
 1c4:	4605                	li	a2,1
 1c6:	faf40593          	addi	a1,s0,-81
 1ca:	4501                	li	a0,0
 1cc:	1b4000ef          	jal	ra,380 <read>
    if(cc < 1)
 1d0:	00a05e63          	blez	a0,1ec <gets+0x52>
    buf[i++] = c;
 1d4:	faf44783          	lbu	a5,-81(s0)
 1d8:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1dc:	01578763          	beq	a5,s5,1ea <gets+0x50>
 1e0:	0905                	addi	s2,s2,1
 1e2:	fd679de3          	bne	a5,s6,1bc <gets+0x22>
  for(i=0; i+1 < max; ){
 1e6:	89a6                	mv	s3,s1
 1e8:	a011                	j	1ec <gets+0x52>
 1ea:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1ec:	99de                	add	s3,s3,s7
 1ee:	00098023          	sb	zero,0(s3)
  return buf;
}
 1f2:	855e                	mv	a0,s7
 1f4:	60e6                	ld	ra,88(sp)
 1f6:	6446                	ld	s0,80(sp)
 1f8:	64a6                	ld	s1,72(sp)
 1fa:	6906                	ld	s2,64(sp)
 1fc:	79e2                	ld	s3,56(sp)
 1fe:	7a42                	ld	s4,48(sp)
 200:	7aa2                	ld	s5,40(sp)
 202:	7b02                	ld	s6,32(sp)
 204:	6be2                	ld	s7,24(sp)
 206:	6125                	addi	sp,sp,96
 208:	8082                	ret

000000000000020a <stat>:

int
stat(const char *n, struct stat *st)
{
 20a:	1101                	addi	sp,sp,-32
 20c:	ec06                	sd	ra,24(sp)
 20e:	e822                	sd	s0,16(sp)
 210:	e426                	sd	s1,8(sp)
 212:	e04a                	sd	s2,0(sp)
 214:	1000                	addi	s0,sp,32
 216:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 218:	4581                	li	a1,0
 21a:	18e000ef          	jal	ra,3a8 <open>
  if(fd < 0)
 21e:	02054163          	bltz	a0,240 <stat+0x36>
 222:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 224:	85ca                	mv	a1,s2
 226:	19a000ef          	jal	ra,3c0 <fstat>
 22a:	892a                	mv	s2,a0
  close(fd);
 22c:	8526                	mv	a0,s1
 22e:	162000ef          	jal	ra,390 <close>
  return r;
}
 232:	854a                	mv	a0,s2
 234:	60e2                	ld	ra,24(sp)
 236:	6442                	ld	s0,16(sp)
 238:	64a2                	ld	s1,8(sp)
 23a:	6902                	ld	s2,0(sp)
 23c:	6105                	addi	sp,sp,32
 23e:	8082                	ret
    return -1;
 240:	597d                	li	s2,-1
 242:	bfc5                	j	232 <stat+0x28>

0000000000000244 <atoi>:

int
atoi(const char *s)
{
 244:	1141                	addi	sp,sp,-16
 246:	e422                	sd	s0,8(sp)
 248:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 24a:	00054603          	lbu	a2,0(a0)
 24e:	fd06079b          	addiw	a5,a2,-48
 252:	0ff7f793          	andi	a5,a5,255
 256:	4725                	li	a4,9
 258:	02f76963          	bltu	a4,a5,28a <atoi+0x46>
 25c:	86aa                	mv	a3,a0
  n = 0;
 25e:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 260:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 262:	0685                	addi	a3,a3,1
 264:	0025179b          	slliw	a5,a0,0x2
 268:	9fa9                	addw	a5,a5,a0
 26a:	0017979b          	slliw	a5,a5,0x1
 26e:	9fb1                	addw	a5,a5,a2
 270:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 274:	0006c603          	lbu	a2,0(a3)
 278:	fd06071b          	addiw	a4,a2,-48
 27c:	0ff77713          	andi	a4,a4,255
 280:	fee5f1e3          	bgeu	a1,a4,262 <atoi+0x1e>
  return n;
}
 284:	6422                	ld	s0,8(sp)
 286:	0141                	addi	sp,sp,16
 288:	8082                	ret
  n = 0;
 28a:	4501                	li	a0,0
 28c:	bfe5                	j	284 <atoi+0x40>

000000000000028e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 28e:	1141                	addi	sp,sp,-16
 290:	e422                	sd	s0,8(sp)
 292:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 294:	02b57463          	bgeu	a0,a1,2bc <memmove+0x2e>
    while(n-- > 0)
 298:	00c05f63          	blez	a2,2b6 <memmove+0x28>
 29c:	1602                	slli	a2,a2,0x20
 29e:	9201                	srli	a2,a2,0x20
 2a0:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 2a4:	872a                	mv	a4,a0
      *dst++ = *src++;
 2a6:	0585                	addi	a1,a1,1
 2a8:	0705                	addi	a4,a4,1
 2aa:	fff5c683          	lbu	a3,-1(a1)
 2ae:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2b2:	fee79ae3          	bne	a5,a4,2a6 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2b6:	6422                	ld	s0,8(sp)
 2b8:	0141                	addi	sp,sp,16
 2ba:	8082                	ret
    dst += n;
 2bc:	00c50733          	add	a4,a0,a2
    src += n;
 2c0:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2c2:	fec05ae3          	blez	a2,2b6 <memmove+0x28>
 2c6:	fff6079b          	addiw	a5,a2,-1
 2ca:	1782                	slli	a5,a5,0x20
 2cc:	9381                	srli	a5,a5,0x20
 2ce:	fff7c793          	not	a5,a5
 2d2:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2d4:	15fd                	addi	a1,a1,-1
 2d6:	177d                	addi	a4,a4,-1
 2d8:	0005c683          	lbu	a3,0(a1)
 2dc:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2e0:	fee79ae3          	bne	a5,a4,2d4 <memmove+0x46>
 2e4:	bfc9                	j	2b6 <memmove+0x28>

00000000000002e6 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2e6:	1141                	addi	sp,sp,-16
 2e8:	e422                	sd	s0,8(sp)
 2ea:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2ec:	ca05                	beqz	a2,31c <memcmp+0x36>
 2ee:	fff6069b          	addiw	a3,a2,-1
 2f2:	1682                	slli	a3,a3,0x20
 2f4:	9281                	srli	a3,a3,0x20
 2f6:	0685                	addi	a3,a3,1
 2f8:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2fa:	00054783          	lbu	a5,0(a0)
 2fe:	0005c703          	lbu	a4,0(a1)
 302:	00e79863          	bne	a5,a4,312 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 306:	0505                	addi	a0,a0,1
    p2++;
 308:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 30a:	fed518e3          	bne	a0,a3,2fa <memcmp+0x14>
  }
  return 0;
 30e:	4501                	li	a0,0
 310:	a019                	j	316 <memcmp+0x30>
      return *p1 - *p2;
 312:	40e7853b          	subw	a0,a5,a4
}
 316:	6422                	ld	s0,8(sp)
 318:	0141                	addi	sp,sp,16
 31a:	8082                	ret
  return 0;
 31c:	4501                	li	a0,0
 31e:	bfe5                	j	316 <memcmp+0x30>

0000000000000320 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 320:	1141                	addi	sp,sp,-16
 322:	e406                	sd	ra,8(sp)
 324:	e022                	sd	s0,0(sp)
 326:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 328:	f67ff0ef          	jal	ra,28e <memmove>
}
 32c:	60a2                	ld	ra,8(sp)
 32e:	6402                	ld	s0,0(sp)
 330:	0141                	addi	sp,sp,16
 332:	8082                	ret

0000000000000334 <sbrk>:

char *
sbrk(int n) {
 334:	1141                	addi	sp,sp,-16
 336:	e406                	sd	ra,8(sp)
 338:	e022                	sd	s0,0(sp)
 33a:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_EAGER);
 33c:	4585                	li	a1,1
 33e:	0b2000ef          	jal	ra,3f0 <sys_sbrk>
}
 342:	60a2                	ld	ra,8(sp)
 344:	6402                	ld	s0,0(sp)
 346:	0141                	addi	sp,sp,16
 348:	8082                	ret

000000000000034a <sbrklazy>:

char *
sbrklazy(int n) {
 34a:	1141                	addi	sp,sp,-16
 34c:	e406                	sd	ra,8(sp)
 34e:	e022                	sd	s0,0(sp)
 350:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_LAZY);
 352:	4589                	li	a1,2
 354:	09c000ef          	jal	ra,3f0 <sys_sbrk>
}
 358:	60a2                	ld	ra,8(sp)
 35a:	6402                	ld	s0,0(sp)
 35c:	0141                	addi	sp,sp,16
 35e:	8082                	ret

0000000000000360 <fork>:
# 由 usys.pl 生成 - 请勿编辑
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 360:	4885                	li	a7,1
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <exit>:
.global exit
exit:
 li a7, SYS_exit
 368:	4889                	li	a7,2
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <wait>:
.global wait
wait:
 li a7, SYS_wait
 370:	488d                	li	a7,3
 ecall
 372:	00000073          	ecall
 ret
 376:	8082                	ret

0000000000000378 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 378:	4891                	li	a7,4
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <read>:
.global read
read:
 li a7, SYS_read
 380:	4895                	li	a7,5
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <write>:
.global write
write:
 li a7, SYS_write
 388:	48c1                	li	a7,16
 ecall
 38a:	00000073          	ecall
 ret
 38e:	8082                	ret

0000000000000390 <close>:
.global close
close:
 li a7, SYS_close
 390:	48d5                	li	a7,21
 ecall
 392:	00000073          	ecall
 ret
 396:	8082                	ret

0000000000000398 <kill>:
.global kill
kill:
 li a7, SYS_kill
 398:	4899                	li	a7,6
 ecall
 39a:	00000073          	ecall
 ret
 39e:	8082                	ret

00000000000003a0 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3a0:	489d                	li	a7,7
 ecall
 3a2:	00000073          	ecall
 ret
 3a6:	8082                	ret

00000000000003a8 <open>:
.global open
open:
 li a7, SYS_open
 3a8:	48bd                	li	a7,15
 ecall
 3aa:	00000073          	ecall
 ret
 3ae:	8082                	ret

00000000000003b0 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3b0:	48c5                	li	a7,17
 ecall
 3b2:	00000073          	ecall
 ret
 3b6:	8082                	ret

00000000000003b8 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3b8:	48c9                	li	a7,18
 ecall
 3ba:	00000073          	ecall
 ret
 3be:	8082                	ret

00000000000003c0 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3c0:	48a1                	li	a7,8
 ecall
 3c2:	00000073          	ecall
 ret
 3c6:	8082                	ret

00000000000003c8 <link>:
.global link
link:
 li a7, SYS_link
 3c8:	48cd                	li	a7,19
 ecall
 3ca:	00000073          	ecall
 ret
 3ce:	8082                	ret

00000000000003d0 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3d0:	48d1                	li	a7,20
 ecall
 3d2:	00000073          	ecall
 ret
 3d6:	8082                	ret

00000000000003d8 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3d8:	48a5                	li	a7,9
 ecall
 3da:	00000073          	ecall
 ret
 3de:	8082                	ret

00000000000003e0 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3e0:	48a9                	li	a7,10
 ecall
 3e2:	00000073          	ecall
 ret
 3e6:	8082                	ret

00000000000003e8 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3e8:	48ad                	li	a7,11
 ecall
 3ea:	00000073          	ecall
 ret
 3ee:	8082                	ret

00000000000003f0 <sys_sbrk>:
.global sys_sbrk
sys_sbrk:
 li a7, SYS_sbrk
 3f0:	48b1                	li	a7,12
 ecall
 3f2:	00000073          	ecall
 ret
 3f6:	8082                	ret

00000000000003f8 <pause>:
.global pause
pause:
 li a7, SYS_pause
 3f8:	48b5                	li	a7,13
 ecall
 3fa:	00000073          	ecall
 ret
 3fe:	8082                	ret

0000000000000400 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 400:	48b9                	li	a7,14
 ecall
 402:	00000073          	ecall
 ret
 406:	8082                	ret

0000000000000408 <dump_proc>:
.global dump_proc
dump_proc:
 li a7, SYS_dump_proc
 408:	48d9                	li	a7,22
 ecall
 40a:	00000073          	ecall
 ret
 40e:	8082                	ret

0000000000000410 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 410:	1101                	addi	sp,sp,-32
 412:	ec06                	sd	ra,24(sp)
 414:	e822                	sd	s0,16(sp)
 416:	1000                	addi	s0,sp,32
 418:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 41c:	4605                	li	a2,1
 41e:	fef40593          	addi	a1,s0,-17
 422:	f67ff0ef          	jal	ra,388 <write>
}
 426:	60e2                	ld	ra,24(sp)
 428:	6442                	ld	s0,16(sp)
 42a:	6105                	addi	sp,sp,32
 42c:	8082                	ret

000000000000042e <printint>:

static void
printint(int fd, long long xx, int base, int sgn)
{
 42e:	715d                	addi	sp,sp,-80
 430:	e486                	sd	ra,72(sp)
 432:	e0a2                	sd	s0,64(sp)
 434:	fc26                	sd	s1,56(sp)
 436:	f84a                	sd	s2,48(sp)
 438:	f44e                	sd	s3,40(sp)
 43a:	0880                	addi	s0,sp,80
 43c:	892a                	mv	s2,a0
  char buf[20];
  int i, neg;
  unsigned long long x;

  neg = 0;
  if(sgn && xx < 0){
 43e:	c299                	beqz	a3,444 <printint+0x16>
 440:	0805c163          	bltz	a1,4c2 <printint+0x94>
  neg = 0;
 444:	4881                	li	a7,0
 446:	fb840693          	addi	a3,s0,-72
    x = -xx;
  } else {
    x = xx;
  }

  i = 0;
 44a:	4781                	li	a5,0
  do{
    buf[i++] = digits[x % base];
 44c:	00000517          	auipc	a0,0x0
 450:	55450513          	addi	a0,a0,1364 # 9a0 <digits>
 454:	883e                	mv	a6,a5
 456:	2785                	addiw	a5,a5,1
 458:	02c5f733          	remu	a4,a1,a2
 45c:	972a                	add	a4,a4,a0
 45e:	00074703          	lbu	a4,0(a4)
 462:	00e68023          	sb	a4,0(a3)
  }while((x /= base) != 0);
 466:	872e                	mv	a4,a1
 468:	02c5d5b3          	divu	a1,a1,a2
 46c:	0685                	addi	a3,a3,1
 46e:	fec773e3          	bgeu	a4,a2,454 <printint+0x26>
  if(neg)
 472:	00088b63          	beqz	a7,488 <printint+0x5a>
    buf[i++] = '-';
 476:	fd040713          	addi	a4,s0,-48
 47a:	97ba                	add	a5,a5,a4
 47c:	02d00713          	li	a4,45
 480:	fee78423          	sb	a4,-24(a5)
 484:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
 488:	02f05663          	blez	a5,4b4 <printint+0x86>
 48c:	fb840713          	addi	a4,s0,-72
 490:	00f704b3          	add	s1,a4,a5
 494:	fff70993          	addi	s3,a4,-1
 498:	99be                	add	s3,s3,a5
 49a:	37fd                	addiw	a5,a5,-1
 49c:	1782                	slli	a5,a5,0x20
 49e:	9381                	srli	a5,a5,0x20
 4a0:	40f989b3          	sub	s3,s3,a5
    putc(fd, buf[i]);
 4a4:	fff4c583          	lbu	a1,-1(s1)
 4a8:	854a                	mv	a0,s2
 4aa:	f67ff0ef          	jal	ra,410 <putc>
  while(--i >= 0)
 4ae:	14fd                	addi	s1,s1,-1
 4b0:	ff349ae3          	bne	s1,s3,4a4 <printint+0x76>
}
 4b4:	60a6                	ld	ra,72(sp)
 4b6:	6406                	ld	s0,64(sp)
 4b8:	74e2                	ld	s1,56(sp)
 4ba:	7942                	ld	s2,48(sp)
 4bc:	79a2                	ld	s3,40(sp)
 4be:	6161                	addi	sp,sp,80
 4c0:	8082                	ret
    x = -xx;
 4c2:	40b005b3          	neg	a1,a1
    neg = 1;
 4c6:	4885                	li	a7,1
    x = -xx;
 4c8:	bfbd                	j	446 <printint+0x18>

00000000000004ca <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %c, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4ca:	7119                	addi	sp,sp,-128
 4cc:	fc86                	sd	ra,120(sp)
 4ce:	f8a2                	sd	s0,112(sp)
 4d0:	f4a6                	sd	s1,104(sp)
 4d2:	f0ca                	sd	s2,96(sp)
 4d4:	ecce                	sd	s3,88(sp)
 4d6:	e8d2                	sd	s4,80(sp)
 4d8:	e4d6                	sd	s5,72(sp)
 4da:	e0da                	sd	s6,64(sp)
 4dc:	fc5e                	sd	s7,56(sp)
 4de:	f862                	sd	s8,48(sp)
 4e0:	f466                	sd	s9,40(sp)
 4e2:	f06a                	sd	s10,32(sp)
 4e4:	ec6e                	sd	s11,24(sp)
 4e6:	0100                	addi	s0,sp,128
  char *s;
  int c0, c1, c2, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4e8:	0005c903          	lbu	s2,0(a1)
 4ec:	24090c63          	beqz	s2,744 <vprintf+0x27a>
 4f0:	8b2a                	mv	s6,a0
 4f2:	8a2e                	mv	s4,a1
 4f4:	8bb2                	mv	s7,a2
  state = 0;
 4f6:	4981                	li	s3,0
  for(i = 0; fmt[i]; i++){
 4f8:	4481                	li	s1,0
 4fa:	4701                	li	a4,0
      if(c0 == '%'){
        state = '%';
      } else {
        putc(fd, c0);
      }
    } else if(state == '%'){
 4fc:	02500a93          	li	s5,37
      c1 = c2 = 0;
      if(c0) c1 = fmt[i+1] & 0xff;
      if(c1) c2 = fmt[i+2] & 0xff;
      if(c0 == 'd'){
 500:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c0 == 'l' && c1 == 'd'){
 504:	06c00d13          	li	s10,108
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 2;
      } else if(c0 == 'u'){
 508:	07500d93          	li	s11,117
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 50c:	00000c97          	auipc	s9,0x0
 510:	494c8c93          	addi	s9,s9,1172 # 9a0 <digits>
 514:	a005                	j	534 <vprintf+0x6a>
        putc(fd, c0);
 516:	85ca                	mv	a1,s2
 518:	855a                	mv	a0,s6
 51a:	ef7ff0ef          	jal	ra,410 <putc>
 51e:	a019                	j	524 <vprintf+0x5a>
    } else if(state == '%'){
 520:	03598263          	beq	s3,s5,544 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 524:	2485                	addiw	s1,s1,1
 526:	8726                	mv	a4,s1
 528:	009a07b3          	add	a5,s4,s1
 52c:	0007c903          	lbu	s2,0(a5)
 530:	20090a63          	beqz	s2,744 <vprintf+0x27a>
    c0 = fmt[i] & 0xff;
 534:	0009079b          	sext.w	a5,s2
    if(state == 0){
 538:	fe0994e3          	bnez	s3,520 <vprintf+0x56>
      if(c0 == '%'){
 53c:	fd579de3          	bne	a5,s5,516 <vprintf+0x4c>
        state = '%';
 540:	89be                	mv	s3,a5
 542:	b7cd                	j	524 <vprintf+0x5a>
      if(c0) c1 = fmt[i+1] & 0xff;
 544:	c3c1                	beqz	a5,5c4 <vprintf+0xfa>
 546:	00ea06b3          	add	a3,s4,a4
 54a:	0016c683          	lbu	a3,1(a3)
      c1 = c2 = 0;
 54e:	8636                	mv	a2,a3
      if(c1) c2 = fmt[i+2] & 0xff;
 550:	c681                	beqz	a3,558 <vprintf+0x8e>
 552:	9752                	add	a4,a4,s4
 554:	00274603          	lbu	a2,2(a4)
      if(c0 == 'd'){
 558:	03878e63          	beq	a5,s8,594 <vprintf+0xca>
      } else if(c0 == 'l' && c1 == 'd'){
 55c:	05a78863          	beq	a5,s10,5ac <vprintf+0xe2>
      } else if(c0 == 'u'){
 560:	0db78b63          	beq	a5,s11,636 <vprintf+0x16c>
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 2;
      } else if(c0 == 'x'){
 564:	07800713          	li	a4,120
 568:	10e78d63          	beq	a5,a4,682 <vprintf+0x1b8>
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 2;
      } else if(c0 == 'p'){
 56c:	07000713          	li	a4,112
 570:	14e78263          	beq	a5,a4,6b4 <vprintf+0x1ea>
        printptr(fd, va_arg(ap, uint64));
      } else if(c0 == 'c'){
 574:	06300713          	li	a4,99
 578:	16e78f63          	beq	a5,a4,6f6 <vprintf+0x22c>
        putc(fd, va_arg(ap, uint32));
      } else if(c0 == 's'){
 57c:	07300713          	li	a4,115
 580:	18e78563          	beq	a5,a4,70a <vprintf+0x240>
        if((s = va_arg(ap, char*)) == 0)
          s = "(null)";
        for(; *s; s++)
          putc(fd, *s);
      } else if(c0 == '%'){
 584:	05579063          	bne	a5,s5,5c4 <vprintf+0xfa>
        putc(fd, '%');
 588:	85d6                	mv	a1,s5
 58a:	855a                	mv	a0,s6
 58c:	e85ff0ef          	jal	ra,410 <putc>
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c0);
      }

      state = 0;
 590:	4981                	li	s3,0
 592:	bf49                	j	524 <vprintf+0x5a>
        printint(fd, va_arg(ap, int), 10, 1);
 594:	008b8913          	addi	s2,s7,8
 598:	4685                	li	a3,1
 59a:	4629                	li	a2,10
 59c:	000ba583          	lw	a1,0(s7)
 5a0:	855a                	mv	a0,s6
 5a2:	e8dff0ef          	jal	ra,42e <printint>
 5a6:	8bca                	mv	s7,s2
      state = 0;
 5a8:	4981                	li	s3,0
 5aa:	bfad                	j	524 <vprintf+0x5a>
      } else if(c0 == 'l' && c1 == 'd'){
 5ac:	03868663          	beq	a3,s8,5d8 <vprintf+0x10e>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 5b0:	05a68163          	beq	a3,s10,5f2 <vprintf+0x128>
      } else if(c0 == 'l' && c1 == 'u'){
 5b4:	09b68d63          	beq	a3,s11,64e <vprintf+0x184>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 5b8:	03a68f63          	beq	a3,s10,5f6 <vprintf+0x12c>
      } else if(c0 == 'l' && c1 == 'x'){
 5bc:	07800793          	li	a5,120
 5c0:	0cf68d63          	beq	a3,a5,69a <vprintf+0x1d0>
        putc(fd, '%');
 5c4:	85d6                	mv	a1,s5
 5c6:	855a                	mv	a0,s6
 5c8:	e49ff0ef          	jal	ra,410 <putc>
        putc(fd, c0);
 5cc:	85ca                	mv	a1,s2
 5ce:	855a                	mv	a0,s6
 5d0:	e41ff0ef          	jal	ra,410 <putc>
      state = 0;
 5d4:	4981                	li	s3,0
 5d6:	b7b9                	j	524 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 5d8:	008b8913          	addi	s2,s7,8
 5dc:	4685                	li	a3,1
 5de:	4629                	li	a2,10
 5e0:	000bb583          	ld	a1,0(s7)
 5e4:	855a                	mv	a0,s6
 5e6:	e49ff0ef          	jal	ra,42e <printint>
        i += 1;
 5ea:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 1);
 5ec:	8bca                	mv	s7,s2
      state = 0;
 5ee:	4981                	li	s3,0
        i += 1;
 5f0:	bf15                	j	524 <vprintf+0x5a>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 5f2:	03860563          	beq	a2,s8,61c <vprintf+0x152>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 5f6:	07b60963          	beq	a2,s11,668 <vprintf+0x19e>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
 5fa:	07800793          	li	a5,120
 5fe:	fcf613e3          	bne	a2,a5,5c4 <vprintf+0xfa>
        printint(fd, va_arg(ap, uint64), 16, 0);
 602:	008b8913          	addi	s2,s7,8
 606:	4681                	li	a3,0
 608:	4641                	li	a2,16
 60a:	000bb583          	ld	a1,0(s7)
 60e:	855a                	mv	a0,s6
 610:	e1fff0ef          	jal	ra,42e <printint>
        i += 2;
 614:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 16, 0);
 616:	8bca                	mv	s7,s2
      state = 0;
 618:	4981                	li	s3,0
        i += 2;
 61a:	b729                	j	524 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 61c:	008b8913          	addi	s2,s7,8
 620:	4685                	li	a3,1
 622:	4629                	li	a2,10
 624:	000bb583          	ld	a1,0(s7)
 628:	855a                	mv	a0,s6
 62a:	e05ff0ef          	jal	ra,42e <printint>
        i += 2;
 62e:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 1);
 630:	8bca                	mv	s7,s2
      state = 0;
 632:	4981                	li	s3,0
        i += 2;
 634:	bdc5                	j	524 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint32), 10, 0);
 636:	008b8913          	addi	s2,s7,8
 63a:	4681                	li	a3,0
 63c:	4629                	li	a2,10
 63e:	000be583          	lwu	a1,0(s7)
 642:	855a                	mv	a0,s6
 644:	debff0ef          	jal	ra,42e <printint>
 648:	8bca                	mv	s7,s2
      state = 0;
 64a:	4981                	li	s3,0
 64c:	bde1                	j	524 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 64e:	008b8913          	addi	s2,s7,8
 652:	4681                	li	a3,0
 654:	4629                	li	a2,10
 656:	000bb583          	ld	a1,0(s7)
 65a:	855a                	mv	a0,s6
 65c:	dd3ff0ef          	jal	ra,42e <printint>
        i += 1;
 660:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 0);
 662:	8bca                	mv	s7,s2
      state = 0;
 664:	4981                	li	s3,0
        i += 1;
 666:	bd7d                	j	524 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 668:	008b8913          	addi	s2,s7,8
 66c:	4681                	li	a3,0
 66e:	4629                	li	a2,10
 670:	000bb583          	ld	a1,0(s7)
 674:	855a                	mv	a0,s6
 676:	db9ff0ef          	jal	ra,42e <printint>
        i += 2;
 67a:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 0);
 67c:	8bca                	mv	s7,s2
      state = 0;
 67e:	4981                	li	s3,0
        i += 2;
 680:	b555                	j	524 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint32), 16, 0);
 682:	008b8913          	addi	s2,s7,8
 686:	4681                	li	a3,0
 688:	4641                	li	a2,16
 68a:	000be583          	lwu	a1,0(s7)
 68e:	855a                	mv	a0,s6
 690:	d9fff0ef          	jal	ra,42e <printint>
 694:	8bca                	mv	s7,s2
      state = 0;
 696:	4981                	li	s3,0
 698:	b571                	j	524 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 16, 0);
 69a:	008b8913          	addi	s2,s7,8
 69e:	4681                	li	a3,0
 6a0:	4641                	li	a2,16
 6a2:	000bb583          	ld	a1,0(s7)
 6a6:	855a                	mv	a0,s6
 6a8:	d87ff0ef          	jal	ra,42e <printint>
        i += 1;
 6ac:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 16, 0);
 6ae:	8bca                	mv	s7,s2
      state = 0;
 6b0:	4981                	li	s3,0
        i += 1;
 6b2:	bd8d                	j	524 <vprintf+0x5a>
        printptr(fd, va_arg(ap, uint64));
 6b4:	008b8793          	addi	a5,s7,8
 6b8:	f8f43423          	sd	a5,-120(s0)
 6bc:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 6c0:	03000593          	li	a1,48
 6c4:	855a                	mv	a0,s6
 6c6:	d4bff0ef          	jal	ra,410 <putc>
  putc(fd, 'x');
 6ca:	07800593          	li	a1,120
 6ce:	855a                	mv	a0,s6
 6d0:	d41ff0ef          	jal	ra,410 <putc>
 6d4:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6d6:	03c9d793          	srli	a5,s3,0x3c
 6da:	97e6                	add	a5,a5,s9
 6dc:	0007c583          	lbu	a1,0(a5)
 6e0:	855a                	mv	a0,s6
 6e2:	d2fff0ef          	jal	ra,410 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6e6:	0992                	slli	s3,s3,0x4
 6e8:	397d                	addiw	s2,s2,-1
 6ea:	fe0916e3          	bnez	s2,6d6 <vprintf+0x20c>
        printptr(fd, va_arg(ap, uint64));
 6ee:	f8843b83          	ld	s7,-120(s0)
      state = 0;
 6f2:	4981                	li	s3,0
 6f4:	bd05                	j	524 <vprintf+0x5a>
        putc(fd, va_arg(ap, uint32));
 6f6:	008b8913          	addi	s2,s7,8
 6fa:	000bc583          	lbu	a1,0(s7)
 6fe:	855a                	mv	a0,s6
 700:	d11ff0ef          	jal	ra,410 <putc>
 704:	8bca                	mv	s7,s2
      state = 0;
 706:	4981                	li	s3,0
 708:	bd31                	j	524 <vprintf+0x5a>
        if((s = va_arg(ap, char*)) == 0)
 70a:	008b8993          	addi	s3,s7,8
 70e:	000bb903          	ld	s2,0(s7)
 712:	00090f63          	beqz	s2,730 <vprintf+0x266>
        for(; *s; s++)
 716:	00094583          	lbu	a1,0(s2)
 71a:	c195                	beqz	a1,73e <vprintf+0x274>
          putc(fd, *s);
 71c:	855a                	mv	a0,s6
 71e:	cf3ff0ef          	jal	ra,410 <putc>
        for(; *s; s++)
 722:	0905                	addi	s2,s2,1
 724:	00094583          	lbu	a1,0(s2)
 728:	f9f5                	bnez	a1,71c <vprintf+0x252>
        if((s = va_arg(ap, char*)) == 0)
 72a:	8bce                	mv	s7,s3
      state = 0;
 72c:	4981                	li	s3,0
 72e:	bbdd                	j	524 <vprintf+0x5a>
          s = "(null)";
 730:	00000917          	auipc	s2,0x0
 734:	26890913          	addi	s2,s2,616 # 998 <malloc+0x152>
        for(; *s; s++)
 738:	02800593          	li	a1,40
 73c:	b7c5                	j	71c <vprintf+0x252>
        if((s = va_arg(ap, char*)) == 0)
 73e:	8bce                	mv	s7,s3
      state = 0;
 740:	4981                	li	s3,0
 742:	b3cd                	j	524 <vprintf+0x5a>
    }
  }
}
 744:	70e6                	ld	ra,120(sp)
 746:	7446                	ld	s0,112(sp)
 748:	74a6                	ld	s1,104(sp)
 74a:	7906                	ld	s2,96(sp)
 74c:	69e6                	ld	s3,88(sp)
 74e:	6a46                	ld	s4,80(sp)
 750:	6aa6                	ld	s5,72(sp)
 752:	6b06                	ld	s6,64(sp)
 754:	7be2                	ld	s7,56(sp)
 756:	7c42                	ld	s8,48(sp)
 758:	7ca2                	ld	s9,40(sp)
 75a:	7d02                	ld	s10,32(sp)
 75c:	6de2                	ld	s11,24(sp)
 75e:	6109                	addi	sp,sp,128
 760:	8082                	ret

0000000000000762 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 762:	715d                	addi	sp,sp,-80
 764:	ec06                	sd	ra,24(sp)
 766:	e822                	sd	s0,16(sp)
 768:	1000                	addi	s0,sp,32
 76a:	e010                	sd	a2,0(s0)
 76c:	e414                	sd	a3,8(s0)
 76e:	e818                	sd	a4,16(s0)
 770:	ec1c                	sd	a5,24(s0)
 772:	03043023          	sd	a6,32(s0)
 776:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 77a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 77e:	8622                	mv	a2,s0
 780:	d4bff0ef          	jal	ra,4ca <vprintf>
}
 784:	60e2                	ld	ra,24(sp)
 786:	6442                	ld	s0,16(sp)
 788:	6161                	addi	sp,sp,80
 78a:	8082                	ret

000000000000078c <printf>:

void
printf(const char *fmt, ...)
{
 78c:	711d                	addi	sp,sp,-96
 78e:	ec06                	sd	ra,24(sp)
 790:	e822                	sd	s0,16(sp)
 792:	1000                	addi	s0,sp,32
 794:	e40c                	sd	a1,8(s0)
 796:	e810                	sd	a2,16(s0)
 798:	ec14                	sd	a3,24(s0)
 79a:	f018                	sd	a4,32(s0)
 79c:	f41c                	sd	a5,40(s0)
 79e:	03043823          	sd	a6,48(s0)
 7a2:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7a6:	00840613          	addi	a2,s0,8
 7aa:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7ae:	85aa                	mv	a1,a0
 7b0:	4505                	li	a0,1
 7b2:	d19ff0ef          	jal	ra,4ca <vprintf>
}
 7b6:	60e2                	ld	ra,24(sp)
 7b8:	6442                	ld	s0,16(sp)
 7ba:	6125                	addi	sp,sp,96
 7bc:	8082                	ret

00000000000007be <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7be:	1141                	addi	sp,sp,-16
 7c0:	e422                	sd	s0,8(sp)
 7c2:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7c4:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7c8:	00001797          	auipc	a5,0x1
 7cc:	8387b783          	ld	a5,-1992(a5) # 1000 <freep>
 7d0:	a805                	j	800 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7d2:	4618                	lw	a4,8(a2)
 7d4:	9db9                	addw	a1,a1,a4
 7d6:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7da:	6398                	ld	a4,0(a5)
 7dc:	6318                	ld	a4,0(a4)
 7de:	fee53823          	sd	a4,-16(a0)
 7e2:	a091                	j	826 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7e4:	ff852703          	lw	a4,-8(a0)
 7e8:	9e39                	addw	a2,a2,a4
 7ea:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 7ec:	ff053703          	ld	a4,-16(a0)
 7f0:	e398                	sd	a4,0(a5)
 7f2:	a099                	j	838 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7f4:	6398                	ld	a4,0(a5)
 7f6:	00e7e463          	bltu	a5,a4,7fe <free+0x40>
 7fa:	00e6ea63          	bltu	a3,a4,80e <free+0x50>
{
 7fe:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 800:	fed7fae3          	bgeu	a5,a3,7f4 <free+0x36>
 804:	6398                	ld	a4,0(a5)
 806:	00e6e463          	bltu	a3,a4,80e <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 80a:	fee7eae3          	bltu	a5,a4,7fe <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 80e:	ff852583          	lw	a1,-8(a0)
 812:	6390                	ld	a2,0(a5)
 814:	02059713          	slli	a4,a1,0x20
 818:	9301                	srli	a4,a4,0x20
 81a:	0712                	slli	a4,a4,0x4
 81c:	9736                	add	a4,a4,a3
 81e:	fae60ae3          	beq	a2,a4,7d2 <free+0x14>
    bp->s.ptr = p->s.ptr;
 822:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 826:	4790                	lw	a2,8(a5)
 828:	02061713          	slli	a4,a2,0x20
 82c:	9301                	srli	a4,a4,0x20
 82e:	0712                	slli	a4,a4,0x4
 830:	973e                	add	a4,a4,a5
 832:	fae689e3          	beq	a3,a4,7e4 <free+0x26>
  } else
    p->s.ptr = bp;
 836:	e394                	sd	a3,0(a5)
  freep = p;
 838:	00000717          	auipc	a4,0x0
 83c:	7cf73423          	sd	a5,1992(a4) # 1000 <freep>
}
 840:	6422                	ld	s0,8(sp)
 842:	0141                	addi	sp,sp,16
 844:	8082                	ret

0000000000000846 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 846:	7139                	addi	sp,sp,-64
 848:	fc06                	sd	ra,56(sp)
 84a:	f822                	sd	s0,48(sp)
 84c:	f426                	sd	s1,40(sp)
 84e:	f04a                	sd	s2,32(sp)
 850:	ec4e                	sd	s3,24(sp)
 852:	e852                	sd	s4,16(sp)
 854:	e456                	sd	s5,8(sp)
 856:	e05a                	sd	s6,0(sp)
 858:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 85a:	02051493          	slli	s1,a0,0x20
 85e:	9081                	srli	s1,s1,0x20
 860:	04bd                	addi	s1,s1,15
 862:	8091                	srli	s1,s1,0x4
 864:	0014899b          	addiw	s3,s1,1
 868:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 86a:	00000517          	auipc	a0,0x0
 86e:	79653503          	ld	a0,1942(a0) # 1000 <freep>
 872:	c515                	beqz	a0,89e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 874:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 876:	4798                	lw	a4,8(a5)
 878:	02977f63          	bgeu	a4,s1,8b6 <malloc+0x70>
 87c:	8a4e                	mv	s4,s3
 87e:	0009871b          	sext.w	a4,s3
 882:	6685                	lui	a3,0x1
 884:	00d77363          	bgeu	a4,a3,88a <malloc+0x44>
 888:	6a05                	lui	s4,0x1
 88a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 88e:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 892:	00000917          	auipc	s2,0x0
 896:	76e90913          	addi	s2,s2,1902 # 1000 <freep>
  if(p == SBRK_ERROR)
 89a:	5afd                	li	s5,-1
 89c:	a0bd                	j	90a <malloc+0xc4>
    base.s.ptr = freep = prevp = &base;
 89e:	00000797          	auipc	a5,0x0
 8a2:	77278793          	addi	a5,a5,1906 # 1010 <base>
 8a6:	00000717          	auipc	a4,0x0
 8aa:	74f73d23          	sd	a5,1882(a4) # 1000 <freep>
 8ae:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8b0:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8b4:	b7e1                	j	87c <malloc+0x36>
      if(p->s.size == nunits)
 8b6:	02e48b63          	beq	s1,a4,8ec <malloc+0xa6>
        p->s.size -= nunits;
 8ba:	4137073b          	subw	a4,a4,s3
 8be:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8c0:	1702                	slli	a4,a4,0x20
 8c2:	9301                	srli	a4,a4,0x20
 8c4:	0712                	slli	a4,a4,0x4
 8c6:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8c8:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8cc:	00000717          	auipc	a4,0x0
 8d0:	72a73a23          	sd	a0,1844(a4) # 1000 <freep>
      return (void*)(p + 1);
 8d4:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8d8:	70e2                	ld	ra,56(sp)
 8da:	7442                	ld	s0,48(sp)
 8dc:	74a2                	ld	s1,40(sp)
 8de:	7902                	ld	s2,32(sp)
 8e0:	69e2                	ld	s3,24(sp)
 8e2:	6a42                	ld	s4,16(sp)
 8e4:	6aa2                	ld	s5,8(sp)
 8e6:	6b02                	ld	s6,0(sp)
 8e8:	6121                	addi	sp,sp,64
 8ea:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8ec:	6398                	ld	a4,0(a5)
 8ee:	e118                	sd	a4,0(a0)
 8f0:	bff1                	j	8cc <malloc+0x86>
  hp->s.size = nu;
 8f2:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8f6:	0541                	addi	a0,a0,16
 8f8:	ec7ff0ef          	jal	ra,7be <free>
  return freep;
 8fc:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 900:	dd61                	beqz	a0,8d8 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 902:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 904:	4798                	lw	a4,8(a5)
 906:	fa9778e3          	bgeu	a4,s1,8b6 <malloc+0x70>
    if(p == freep)
 90a:	00093703          	ld	a4,0(s2)
 90e:	853e                	mv	a0,a5
 910:	fef719e3          	bne	a4,a5,902 <malloc+0xbc>
  p = sbrk(nu * sizeof(Header));
 914:	8552                	mv	a0,s4
 916:	a1fff0ef          	jal	ra,334 <sbrk>
  if(p == SBRK_ERROR)
 91a:	fd551ce3          	bne	a0,s5,8f2 <malloc+0xac>
        return 0;
 91e:	4501                	li	a0,0
 920:	bf65                	j	8d8 <malloc+0x92>
