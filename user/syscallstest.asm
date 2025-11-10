
user/_syscallstest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <itoa>:
#include "user.h"
#include "kernel/fcntl.h"

// 手动实现 itoa（用于打印数字）
void itoa(int n, char *buf) {
    if (n == 0) {
   0:	c53d                	beqz	a0,6e <itoa+0x6e>
void itoa(int n, char *buf) {
   2:	1101                	addi	sp,sp,-32
   4:	ec22                	sd	s0,24(sp)
   6:	1000                	addi	s0,sp,32
        buf[1] = '\0';
        return;
    }
    int i = 0;
    char temp[12];
    while (n > 0) {
   8:	fe040693          	addi	a3,s0,-32
    int i = 0;
   c:	4701                	li	a4,0
        temp[i++] = '0' + (n % 10);
   e:	4629                	li	a2,10
    while (n > 0) {
  10:	48a5                	li	a7,9
  12:	04a05863          	blez	a0,62 <itoa+0x62>
        temp[i++] = '0' + (n % 10);
  16:	883a                	mv	a6,a4
  18:	2705                	addiw	a4,a4,1
  1a:	02c567bb          	remw	a5,a0,a2
  1e:	0307879b          	addiw	a5,a5,48
  22:	00f68023          	sb	a5,0(a3)
        n /= 10;
  26:	87aa                	mv	a5,a0
  28:	02c5453b          	divw	a0,a0,a2
    while (n > 0) {
  2c:	0685                	addi	a3,a3,1
  2e:	fef8c4e3          	blt	a7,a5,16 <itoa+0x16>
    }
    temp[i] = '\0';
  32:	ff040793          	addi	a5,s0,-16
  36:	97ba                	add	a5,a5,a4
  38:	fe078823          	sb	zero,-16(a5)
    int len = i;
    for (int j = 0; j < len; j++) {
  3c:	02e05363          	blez	a4,62 <itoa+0x62>
  40:	fe040793          	addi	a5,s0,-32
  44:	010786b3          	add	a3,a5,a6
  48:	87ae                	mv	a5,a1
  4a:	fff5c513          	not	a0,a1
        buf[j] = temp[len - 1 - j];
  4e:	0006c603          	lbu	a2,0(a3)
  52:	00c78023          	sb	a2,0(a5)
    for (int j = 0; j < len; j++) {
  56:	16fd                	addi	a3,a3,-1
  58:	0785                	addi	a5,a5,1
  5a:	00f5063b          	addw	a2,a0,a5
  5e:	ff0648e3          	blt	a2,a6,4e <itoa+0x4e>
    }
    buf[len] = '\0';
  62:	95ba                	add	a1,a1,a4
  64:	00058023          	sb	zero,0(a1)
}
  68:	6462                	ld	s0,24(sp)
  6a:	6105                	addi	sp,sp,32
  6c:	8082                	ret
        buf[0] = '0';
  6e:	03000793          	li	a5,48
  72:	00f58023          	sb	a5,0(a1)
        buf[1] = '\0';
  76:	000580a3          	sb	zero,1(a1)
        return;
  7a:	8082                	ret

000000000000007c <test_basic_syscalls>:

void test_basic_syscalls(void) {
  7c:	1101                	addi	sp,sp,-32
  7e:	ec06                	sd	ra,24(sp)
  80:	e822                	sd	s0,16(sp)
  82:	1000                	addi	s0,sp,32
    printf("\n=== Testing basic system calls ===\n");
  84:	00001517          	auipc	a0,0x1
  88:	a5c50513          	addi	a0,a0,-1444 # ae0 <malloc+0xe4>
  8c:	0b7000ef          	jal	ra,942 <printf>

    int pid = getpid();
  90:	50e000ef          	jal	ra,59e <getpid>
  94:	85aa                	mv	a1,a0
    printf("Current PID: %d\n", pid);
  96:	00001517          	auipc	a0,0x1
  9a:	a7250513          	addi	a0,a0,-1422 # b08 <malloc+0x10c>
  9e:	0a5000ef          	jal	ra,942 <printf>

    int child = fork();
  a2:	474000ef          	jal	ra,516 <fork>
    if (child == 0) {
  a6:	c11d                	beqz	a0,cc <test_basic_syscalls+0x50>
        printf("Child process: PID=%d\n", getpid());
        exit(42);
    } else if (child > 0) {
  a8:	02a05f63          	blez	a0,e6 <test_basic_syscalls+0x6a>
        int status;
        wait(&status);
  ac:	fec40513          	addi	a0,s0,-20
  b0:	476000ef          	jal	ra,526 <wait>
        // xv6: status 是子进程 exit() 的参数
        printf("Child exited with status: %d\n", status);
  b4:	fec42583          	lw	a1,-20(s0)
  b8:	00001517          	auipc	a0,0x1
  bc:	a8050513          	addi	a0,a0,-1408 # b38 <malloc+0x13c>
  c0:	083000ef          	jal	ra,942 <printf>
    } else {
        printf("Fork failed!\n");
    }
}
  c4:	60e2                	ld	ra,24(sp)
  c6:	6442                	ld	s0,16(sp)
  c8:	6105                	addi	sp,sp,32
  ca:	8082                	ret
        printf("Child process: PID=%d\n", getpid());
  cc:	4d2000ef          	jal	ra,59e <getpid>
  d0:	85aa                	mv	a1,a0
  d2:	00001517          	auipc	a0,0x1
  d6:	a4e50513          	addi	a0,a0,-1458 # b20 <malloc+0x124>
  da:	069000ef          	jal	ra,942 <printf>
        exit(42);
  de:	02a00513          	li	a0,42
  e2:	43c000ef          	jal	ra,51e <exit>
        printf("Fork failed!\n");
  e6:	00001517          	auipc	a0,0x1
  ea:	a7250513          	addi	a0,a0,-1422 # b58 <malloc+0x15c>
  ee:	055000ef          	jal	ra,942 <printf>
}
  f2:	bfc9                	j	c4 <test_basic_syscalls+0x48>

00000000000000f4 <test_parameter_passing>:

void test_parameter_passing(void) {
  f4:	7139                	addi	sp,sp,-64
  f6:	fc06                	sd	ra,56(sp)
  f8:	f822                	sd	s0,48(sp)
  fa:	f426                	sd	s1,40(sp)
  fc:	0080                	addi	s0,sp,64
    printf("\n=== Testing parameter passing and edge cases ===\n");
  fe:	00001517          	auipc	a0,0x1
 102:	a6a50513          	addi	a0,a0,-1430 # b68 <malloc+0x16c>
 106:	03d000ef          	jal	ra,942 <printf>

    int fd = open("/dev/console", O_WRONLY);
 10a:	4585                	li	a1,1
 10c:	00001517          	auipc	a0,0x1
 110:	a9450513          	addi	a0,a0,-1388 # ba0 <malloc+0x1a4>
 114:	44a000ef          	jal	ra,55e <open>
    if (fd >= 0) {
 118:	02055c63          	bgez	a0,150 <test_parameter_passing+0x5c>
        int bytes_written = write(fd, msg, sizeof(msg) - 1);
        printf("Wrote %d bytes to console\n", bytes_written);
        close(fd);
    }

    printf("Testing invalid syscalls...\n");
 11c:	00001517          	auipc	a0,0x1
 120:	ab450513          	addi	a0,a0,-1356 # bd0 <malloc+0x1d4>
 124:	01f000ef          	jal	ra,942 <printf>
    // 尝试无效系统调用参数（xv6 通常返回 -1）
    int res = write(-1, "bad", 3);
 128:	460d                	li	a2,3
 12a:	00001597          	auipc	a1,0x1
 12e:	ac658593          	addi	a1,a1,-1338 # bf0 <malloc+0x1f4>
 132:	557d                	li	a0,-1
 134:	40a000ef          	jal	ra,53e <write>
 138:	85aa                	mv	a1,a0
    printf("Write to bad fd returned: %d\n", res); // 应为 -1
 13a:	00001517          	auipc	a0,0x1
 13e:	abe50513          	addi	a0,a0,-1346 # bf8 <malloc+0x1fc>
 142:	001000ef          	jal	ra,942 <printf>
}
 146:	70e2                	ld	ra,56(sp)
 148:	7442                	ld	s0,48(sp)
 14a:	74a2                	ld	s1,40(sp)
 14c:	6121                	addi	sp,sp,64
 14e:	8082                	ret
 150:	84aa                	mv	s1,a0
        char msg[] = "Test write to console\n";
 152:	00001797          	auipc	a5,0x1
 156:	ac678793          	addi	a5,a5,-1338 # c18 <malloc+0x21c>
 15a:	6394                	ld	a3,0(a5)
 15c:	6798                	ld	a4,8(a5)
 15e:	fcd43423          	sd	a3,-56(s0)
 162:	fce43823          	sd	a4,-48(s0)
 166:	4b98                	lw	a4,16(a5)
 168:	fce42c23          	sw	a4,-40(s0)
 16c:	0147d703          	lhu	a4,20(a5)
 170:	fce41e23          	sh	a4,-36(s0)
 174:	0167c783          	lbu	a5,22(a5)
 178:	fcf40f23          	sb	a5,-34(s0)
        int bytes_written = write(fd, msg, sizeof(msg) - 1);
 17c:	4659                	li	a2,22
 17e:	fc840593          	addi	a1,s0,-56
 182:	3bc000ef          	jal	ra,53e <write>
 186:	85aa                	mv	a1,a0
        printf("Wrote %d bytes to console\n", bytes_written);
 188:	00001517          	auipc	a0,0x1
 18c:	a2850513          	addi	a0,a0,-1496 # bb0 <malloc+0x1b4>
 190:	7b2000ef          	jal	ra,942 <printf>
        close(fd);
 194:	8526                	mv	a0,s1
 196:	3b0000ef          	jal	ra,546 <close>
 19a:	b749                	j	11c <test_parameter_passing+0x28>

000000000000019c <test_security>:

void test_security(void) {
 19c:	1141                	addi	sp,sp,-16
 19e:	e406                	sd	ra,8(sp)
 1a0:	e022                	sd	s0,0(sp)
 1a2:	0800                	addi	s0,sp,16
    printf("\n=== Testing security / invalid memory access ===\n");
 1a4:	00001517          	auipc	a0,0x1
 1a8:	a8c50513          	addi	a0,a0,-1396 # c30 <malloc+0x234>
 1ac:	796000ef          	jal	ra,942 <printf>

    // 尝试写入无效地址（应被内核阻止）
    int result = write(1, (void*)0x1, 1);
 1b0:	4605                	li	a2,1
 1b2:	4585                	li	a1,1
 1b4:	4505                	li	a0,1
 1b6:	388000ef          	jal	ra,53e <write>
 1ba:	85aa                	mv	a1,a0
    printf("Write to invalid address returned: %d\n", result); // 应为 -1
 1bc:	00001517          	auipc	a0,0x1
 1c0:	aac50513          	addi	a0,a0,-1364 # c68 <malloc+0x26c>
 1c4:	77e000ef          	jal	ra,942 <printf>

    // 尝试读取无效地址（同样应失败）
    result = read(0, (void*)0x1, 1);
 1c8:	4605                	li	a2,1
 1ca:	4585                	li	a1,1
 1cc:	4501                	li	a0,0
 1ce:	368000ef          	jal	ra,536 <read>
 1d2:	85aa                	mv	a1,a0
    printf("Read to invalid address returned: %d\n", result); // 应为 -1
 1d4:	00001517          	auipc	a0,0x1
 1d8:	abc50513          	addi	a0,a0,-1348 # c90 <malloc+0x294>
 1dc:	766000ef          	jal	ra,942 <printf>
}
 1e0:	60a2                	ld	ra,8(sp)
 1e2:	6402                	ld	s0,0(sp)
 1e4:	0141                	addi	sp,sp,16
 1e6:	8082                	ret

00000000000001e8 <test_syscall_performance>:

void test_syscall_performance(void) {
 1e8:	1101                	addi	sp,sp,-32
 1ea:	ec06                	sd	ra,24(sp)
 1ec:	e822                	sd	s0,16(sp)
 1ee:	e426                	sd	s1,8(sp)
 1f0:	e04a                	sd	s2,0(sp)
 1f2:	1000                	addi	s0,sp,32
    printf("\n=== Testing system call performance ===\n");
 1f4:	00001517          	auipc	a0,0x1
 1f8:	ac450513          	addi	a0,a0,-1340 # cb8 <malloc+0x2bc>
 1fc:	746000ef          	jal	ra,942 <printf>

    const int N = 10000;
    int start = uptime();
 200:	3b6000ef          	jal	ra,5b6 <uptime>
 204:	892a                	mv	s2,a0
 206:	6489                	lui	s1,0x2
 208:	71048493          	addi	s1,s1,1808 # 2710 <base+0x1700>
    for (int i = 0; i < N; i++) {
        getpid(); // 轻量级系统调用
 20c:	392000ef          	jal	ra,59e <getpid>
    for (int i = 0; i < N; i++) {
 210:	34fd                	addiw	s1,s1,-1
 212:	fced                	bnez	s1,20c <test_syscall_performance+0x24>
    }
    int end = uptime();
 214:	3a2000ef          	jal	ra,5b6 <uptime>

    printf("%d getpid() calls took %d ticks\n", N, end - start);
 218:	4125093b          	subw	s2,a0,s2
 21c:	0009061b          	sext.w	a2,s2
 220:	6589                	lui	a1,0x2
 222:	71058593          	addi	a1,a1,1808 # 2710 <base+0x1700>
 226:	00001517          	auipc	a0,0x1
 22a:	ac250513          	addi	a0,a0,-1342 # ce8 <malloc+0x2ec>
 22e:	714000ef          	jal	ra,942 <printf>
    // xv6 tick ≈ 10ms，所以乘以 10 得到近似毫秒（粗略）
    printf("Approximate time: %d ms\n", (end - start) * 10);
 232:	0029159b          	slliw	a1,s2,0x2
 236:	012585bb          	addw	a1,a1,s2
 23a:	0015959b          	slliw	a1,a1,0x1
 23e:	00001517          	auipc	a0,0x1
 242:	ad250513          	addi	a0,a0,-1326 # d10 <malloc+0x314>
 246:	6fc000ef          	jal	ra,942 <printf>
}
 24a:	60e2                	ld	ra,24(sp)
 24c:	6442                	ld	s0,16(sp)
 24e:	64a2                	ld	s1,8(sp)
 250:	6902                	ld	s2,0(sp)
 252:	6105                	addi	sp,sp,32
 254:	8082                	ret

0000000000000256 <main>:

int main(int argc, char *argv[]) {
 256:	1141                	addi	sp,sp,-16
 258:	e406                	sd	ra,8(sp)
 25a:	e022                	sd	s0,0(sp)
 25c:	0800                	addi	s0,sp,16
    printf("=== xv6 System Call Test Suite ===\n");
 25e:	00001517          	auipc	a0,0x1
 262:	ad250513          	addi	a0,a0,-1326 # d30 <malloc+0x334>
 266:	6dc000ef          	jal	ra,942 <printf>

    test_basic_syscalls();
 26a:	e13ff0ef          	jal	ra,7c <test_basic_syscalls>
    test_parameter_passing();
 26e:	e87ff0ef          	jal	ra,f4 <test_parameter_passing>
//    test_security();
    test_syscall_performance();
 272:	f77ff0ef          	jal	ra,1e8 <test_syscall_performance>

    printf("\n=== All syscall tests completed ===\n");
 276:	00001517          	auipc	a0,0x1
 27a:	ae250513          	addi	a0,a0,-1310 # d58 <malloc+0x35c>
 27e:	6c4000ef          	jal	ra,942 <printf>
    exit(0);
 282:	4501                	li	a0,0
 284:	29a000ef          	jal	ra,51e <exit>

0000000000000288 <start>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
start(int argc, char **argv)
{
 288:	1141                	addi	sp,sp,-16
 28a:	e406                	sd	ra,8(sp)
 28c:	e022                	sd	s0,0(sp)
 28e:	0800                	addi	s0,sp,16
  int r;
  extern int main(int argc, char **argv);
  r = main(argc, argv);
 290:	fc7ff0ef          	jal	ra,256 <main>
  exit(r);
 294:	28a000ef          	jal	ra,51e <exit>

0000000000000298 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 298:	1141                	addi	sp,sp,-16
 29a:	e422                	sd	s0,8(sp)
 29c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 29e:	87aa                	mv	a5,a0
 2a0:	0585                	addi	a1,a1,1
 2a2:	0785                	addi	a5,a5,1
 2a4:	fff5c703          	lbu	a4,-1(a1)
 2a8:	fee78fa3          	sb	a4,-1(a5)
 2ac:	fb75                	bnez	a4,2a0 <strcpy+0x8>
    ;
  return os;
}
 2ae:	6422                	ld	s0,8(sp)
 2b0:	0141                	addi	sp,sp,16
 2b2:	8082                	ret

00000000000002b4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2b4:	1141                	addi	sp,sp,-16
 2b6:	e422                	sd	s0,8(sp)
 2b8:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2ba:	00054783          	lbu	a5,0(a0)
 2be:	cb91                	beqz	a5,2d2 <strcmp+0x1e>
 2c0:	0005c703          	lbu	a4,0(a1)
 2c4:	00f71763          	bne	a4,a5,2d2 <strcmp+0x1e>
    p++, q++;
 2c8:	0505                	addi	a0,a0,1
 2ca:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2cc:	00054783          	lbu	a5,0(a0)
 2d0:	fbe5                	bnez	a5,2c0 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2d2:	0005c503          	lbu	a0,0(a1)
}
 2d6:	40a7853b          	subw	a0,a5,a0
 2da:	6422                	ld	s0,8(sp)
 2dc:	0141                	addi	sp,sp,16
 2de:	8082                	ret

00000000000002e0 <strlen>:

uint
strlen(const char *s)
{
 2e0:	1141                	addi	sp,sp,-16
 2e2:	e422                	sd	s0,8(sp)
 2e4:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2e6:	00054783          	lbu	a5,0(a0)
 2ea:	cf91                	beqz	a5,306 <strlen+0x26>
 2ec:	0505                	addi	a0,a0,1
 2ee:	87aa                	mv	a5,a0
 2f0:	4685                	li	a3,1
 2f2:	9e89                	subw	a3,a3,a0
 2f4:	00f6853b          	addw	a0,a3,a5
 2f8:	0785                	addi	a5,a5,1
 2fa:	fff7c703          	lbu	a4,-1(a5)
 2fe:	fb7d                	bnez	a4,2f4 <strlen+0x14>
    ;
  return n;
}
 300:	6422                	ld	s0,8(sp)
 302:	0141                	addi	sp,sp,16
 304:	8082                	ret
  for(n = 0; s[n]; n++)
 306:	4501                	li	a0,0
 308:	bfe5                	j	300 <strlen+0x20>

000000000000030a <memset>:

void*
memset(void *dst, int c, uint n)
{
 30a:	1141                	addi	sp,sp,-16
 30c:	e422                	sd	s0,8(sp)
 30e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 310:	ca19                	beqz	a2,326 <memset+0x1c>
 312:	87aa                	mv	a5,a0
 314:	1602                	slli	a2,a2,0x20
 316:	9201                	srli	a2,a2,0x20
 318:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 31c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 320:	0785                	addi	a5,a5,1
 322:	fee79de3          	bne	a5,a4,31c <memset+0x12>
  }
  return dst;
}
 326:	6422                	ld	s0,8(sp)
 328:	0141                	addi	sp,sp,16
 32a:	8082                	ret

000000000000032c <strchr>:

char*
strchr(const char *s, char c)
{
 32c:	1141                	addi	sp,sp,-16
 32e:	e422                	sd	s0,8(sp)
 330:	0800                	addi	s0,sp,16
  for(; *s; s++)
 332:	00054783          	lbu	a5,0(a0)
 336:	cb99                	beqz	a5,34c <strchr+0x20>
    if(*s == c)
 338:	00f58763          	beq	a1,a5,346 <strchr+0x1a>
  for(; *s; s++)
 33c:	0505                	addi	a0,a0,1
 33e:	00054783          	lbu	a5,0(a0)
 342:	fbfd                	bnez	a5,338 <strchr+0xc>
      return (char*)s;
  return 0;
 344:	4501                	li	a0,0
}
 346:	6422                	ld	s0,8(sp)
 348:	0141                	addi	sp,sp,16
 34a:	8082                	ret
  return 0;
 34c:	4501                	li	a0,0
 34e:	bfe5                	j	346 <strchr+0x1a>

0000000000000350 <gets>:

char*
gets(char *buf, int max)
{
 350:	711d                	addi	sp,sp,-96
 352:	ec86                	sd	ra,88(sp)
 354:	e8a2                	sd	s0,80(sp)
 356:	e4a6                	sd	s1,72(sp)
 358:	e0ca                	sd	s2,64(sp)
 35a:	fc4e                	sd	s3,56(sp)
 35c:	f852                	sd	s4,48(sp)
 35e:	f456                	sd	s5,40(sp)
 360:	f05a                	sd	s6,32(sp)
 362:	ec5e                	sd	s7,24(sp)
 364:	1080                	addi	s0,sp,96
 366:	8baa                	mv	s7,a0
 368:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 36a:	892a                	mv	s2,a0
 36c:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 36e:	4aa9                	li	s5,10
 370:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 372:	89a6                	mv	s3,s1
 374:	2485                	addiw	s1,s1,1
 376:	0344d663          	bge	s1,s4,3a2 <gets+0x52>
    cc = read(0, &c, 1);
 37a:	4605                	li	a2,1
 37c:	faf40593          	addi	a1,s0,-81
 380:	4501                	li	a0,0
 382:	1b4000ef          	jal	ra,536 <read>
    if(cc < 1)
 386:	00a05e63          	blez	a0,3a2 <gets+0x52>
    buf[i++] = c;
 38a:	faf44783          	lbu	a5,-81(s0)
 38e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 392:	01578763          	beq	a5,s5,3a0 <gets+0x50>
 396:	0905                	addi	s2,s2,1
 398:	fd679de3          	bne	a5,s6,372 <gets+0x22>
  for(i=0; i+1 < max; ){
 39c:	89a6                	mv	s3,s1
 39e:	a011                	j	3a2 <gets+0x52>
 3a0:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3a2:	99de                	add	s3,s3,s7
 3a4:	00098023          	sb	zero,0(s3)
  return buf;
}
 3a8:	855e                	mv	a0,s7
 3aa:	60e6                	ld	ra,88(sp)
 3ac:	6446                	ld	s0,80(sp)
 3ae:	64a6                	ld	s1,72(sp)
 3b0:	6906                	ld	s2,64(sp)
 3b2:	79e2                	ld	s3,56(sp)
 3b4:	7a42                	ld	s4,48(sp)
 3b6:	7aa2                	ld	s5,40(sp)
 3b8:	7b02                	ld	s6,32(sp)
 3ba:	6be2                	ld	s7,24(sp)
 3bc:	6125                	addi	sp,sp,96
 3be:	8082                	ret

00000000000003c0 <stat>:

int
stat(const char *n, struct stat *st)
{
 3c0:	1101                	addi	sp,sp,-32
 3c2:	ec06                	sd	ra,24(sp)
 3c4:	e822                	sd	s0,16(sp)
 3c6:	e426                	sd	s1,8(sp)
 3c8:	e04a                	sd	s2,0(sp)
 3ca:	1000                	addi	s0,sp,32
 3cc:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3ce:	4581                	li	a1,0
 3d0:	18e000ef          	jal	ra,55e <open>
  if(fd < 0)
 3d4:	02054163          	bltz	a0,3f6 <stat+0x36>
 3d8:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3da:	85ca                	mv	a1,s2
 3dc:	19a000ef          	jal	ra,576 <fstat>
 3e0:	892a                	mv	s2,a0
  close(fd);
 3e2:	8526                	mv	a0,s1
 3e4:	162000ef          	jal	ra,546 <close>
  return r;
}
 3e8:	854a                	mv	a0,s2
 3ea:	60e2                	ld	ra,24(sp)
 3ec:	6442                	ld	s0,16(sp)
 3ee:	64a2                	ld	s1,8(sp)
 3f0:	6902                	ld	s2,0(sp)
 3f2:	6105                	addi	sp,sp,32
 3f4:	8082                	ret
    return -1;
 3f6:	597d                	li	s2,-1
 3f8:	bfc5                	j	3e8 <stat+0x28>

00000000000003fa <atoi>:

int
atoi(const char *s)
{
 3fa:	1141                	addi	sp,sp,-16
 3fc:	e422                	sd	s0,8(sp)
 3fe:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 400:	00054603          	lbu	a2,0(a0)
 404:	fd06079b          	addiw	a5,a2,-48
 408:	0ff7f793          	andi	a5,a5,255
 40c:	4725                	li	a4,9
 40e:	02f76963          	bltu	a4,a5,440 <atoi+0x46>
 412:	86aa                	mv	a3,a0
  n = 0;
 414:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 416:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 418:	0685                	addi	a3,a3,1
 41a:	0025179b          	slliw	a5,a0,0x2
 41e:	9fa9                	addw	a5,a5,a0
 420:	0017979b          	slliw	a5,a5,0x1
 424:	9fb1                	addw	a5,a5,a2
 426:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 42a:	0006c603          	lbu	a2,0(a3)
 42e:	fd06071b          	addiw	a4,a2,-48
 432:	0ff77713          	andi	a4,a4,255
 436:	fee5f1e3          	bgeu	a1,a4,418 <atoi+0x1e>
  return n;
}
 43a:	6422                	ld	s0,8(sp)
 43c:	0141                	addi	sp,sp,16
 43e:	8082                	ret
  n = 0;
 440:	4501                	li	a0,0
 442:	bfe5                	j	43a <atoi+0x40>

0000000000000444 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 444:	1141                	addi	sp,sp,-16
 446:	e422                	sd	s0,8(sp)
 448:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 44a:	02b57463          	bgeu	a0,a1,472 <memmove+0x2e>
    while(n-- > 0)
 44e:	00c05f63          	blez	a2,46c <memmove+0x28>
 452:	1602                	slli	a2,a2,0x20
 454:	9201                	srli	a2,a2,0x20
 456:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 45a:	872a                	mv	a4,a0
      *dst++ = *src++;
 45c:	0585                	addi	a1,a1,1
 45e:	0705                	addi	a4,a4,1
 460:	fff5c683          	lbu	a3,-1(a1)
 464:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 468:	fee79ae3          	bne	a5,a4,45c <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 46c:	6422                	ld	s0,8(sp)
 46e:	0141                	addi	sp,sp,16
 470:	8082                	ret
    dst += n;
 472:	00c50733          	add	a4,a0,a2
    src += n;
 476:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 478:	fec05ae3          	blez	a2,46c <memmove+0x28>
 47c:	fff6079b          	addiw	a5,a2,-1
 480:	1782                	slli	a5,a5,0x20
 482:	9381                	srli	a5,a5,0x20
 484:	fff7c793          	not	a5,a5
 488:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 48a:	15fd                	addi	a1,a1,-1
 48c:	177d                	addi	a4,a4,-1
 48e:	0005c683          	lbu	a3,0(a1)
 492:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 496:	fee79ae3          	bne	a5,a4,48a <memmove+0x46>
 49a:	bfc9                	j	46c <memmove+0x28>

000000000000049c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 49c:	1141                	addi	sp,sp,-16
 49e:	e422                	sd	s0,8(sp)
 4a0:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4a2:	ca05                	beqz	a2,4d2 <memcmp+0x36>
 4a4:	fff6069b          	addiw	a3,a2,-1
 4a8:	1682                	slli	a3,a3,0x20
 4aa:	9281                	srli	a3,a3,0x20
 4ac:	0685                	addi	a3,a3,1
 4ae:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 4b0:	00054783          	lbu	a5,0(a0)
 4b4:	0005c703          	lbu	a4,0(a1)
 4b8:	00e79863          	bne	a5,a4,4c8 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 4bc:	0505                	addi	a0,a0,1
    p2++;
 4be:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4c0:	fed518e3          	bne	a0,a3,4b0 <memcmp+0x14>
  }
  return 0;
 4c4:	4501                	li	a0,0
 4c6:	a019                	j	4cc <memcmp+0x30>
      return *p1 - *p2;
 4c8:	40e7853b          	subw	a0,a5,a4
}
 4cc:	6422                	ld	s0,8(sp)
 4ce:	0141                	addi	sp,sp,16
 4d0:	8082                	ret
  return 0;
 4d2:	4501                	li	a0,0
 4d4:	bfe5                	j	4cc <memcmp+0x30>

00000000000004d6 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4d6:	1141                	addi	sp,sp,-16
 4d8:	e406                	sd	ra,8(sp)
 4da:	e022                	sd	s0,0(sp)
 4dc:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4de:	f67ff0ef          	jal	ra,444 <memmove>
}
 4e2:	60a2                	ld	ra,8(sp)
 4e4:	6402                	ld	s0,0(sp)
 4e6:	0141                	addi	sp,sp,16
 4e8:	8082                	ret

00000000000004ea <sbrk>:

char *
sbrk(int n) {
 4ea:	1141                	addi	sp,sp,-16
 4ec:	e406                	sd	ra,8(sp)
 4ee:	e022                	sd	s0,0(sp)
 4f0:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_EAGER);
 4f2:	4585                	li	a1,1
 4f4:	0b2000ef          	jal	ra,5a6 <sys_sbrk>
}
 4f8:	60a2                	ld	ra,8(sp)
 4fa:	6402                	ld	s0,0(sp)
 4fc:	0141                	addi	sp,sp,16
 4fe:	8082                	ret

0000000000000500 <sbrklazy>:

char *
sbrklazy(int n) {
 500:	1141                	addi	sp,sp,-16
 502:	e406                	sd	ra,8(sp)
 504:	e022                	sd	s0,0(sp)
 506:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_LAZY);
 508:	4589                	li	a1,2
 50a:	09c000ef          	jal	ra,5a6 <sys_sbrk>
}
 50e:	60a2                	ld	ra,8(sp)
 510:	6402                	ld	s0,0(sp)
 512:	0141                	addi	sp,sp,16
 514:	8082                	ret

0000000000000516 <fork>:
# 由 usys.pl 生成 - 请勿编辑
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 516:	4885                	li	a7,1
 ecall
 518:	00000073          	ecall
 ret
 51c:	8082                	ret

000000000000051e <exit>:
.global exit
exit:
 li a7, SYS_exit
 51e:	4889                	li	a7,2
 ecall
 520:	00000073          	ecall
 ret
 524:	8082                	ret

0000000000000526 <wait>:
.global wait
wait:
 li a7, SYS_wait
 526:	488d                	li	a7,3
 ecall
 528:	00000073          	ecall
 ret
 52c:	8082                	ret

000000000000052e <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 52e:	4891                	li	a7,4
 ecall
 530:	00000073          	ecall
 ret
 534:	8082                	ret

0000000000000536 <read>:
.global read
read:
 li a7, SYS_read
 536:	4895                	li	a7,5
 ecall
 538:	00000073          	ecall
 ret
 53c:	8082                	ret

000000000000053e <write>:
.global write
write:
 li a7, SYS_write
 53e:	48c1                	li	a7,16
 ecall
 540:	00000073          	ecall
 ret
 544:	8082                	ret

0000000000000546 <close>:
.global close
close:
 li a7, SYS_close
 546:	48d5                	li	a7,21
 ecall
 548:	00000073          	ecall
 ret
 54c:	8082                	ret

000000000000054e <kill>:
.global kill
kill:
 li a7, SYS_kill
 54e:	4899                	li	a7,6
 ecall
 550:	00000073          	ecall
 ret
 554:	8082                	ret

0000000000000556 <exec>:
.global exec
exec:
 li a7, SYS_exec
 556:	489d                	li	a7,7
 ecall
 558:	00000073          	ecall
 ret
 55c:	8082                	ret

000000000000055e <open>:
.global open
open:
 li a7, SYS_open
 55e:	48bd                	li	a7,15
 ecall
 560:	00000073          	ecall
 ret
 564:	8082                	ret

0000000000000566 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 566:	48c5                	li	a7,17
 ecall
 568:	00000073          	ecall
 ret
 56c:	8082                	ret

000000000000056e <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 56e:	48c9                	li	a7,18
 ecall
 570:	00000073          	ecall
 ret
 574:	8082                	ret

0000000000000576 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 576:	48a1                	li	a7,8
 ecall
 578:	00000073          	ecall
 ret
 57c:	8082                	ret

000000000000057e <link>:
.global link
link:
 li a7, SYS_link
 57e:	48cd                	li	a7,19
 ecall
 580:	00000073          	ecall
 ret
 584:	8082                	ret

0000000000000586 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 586:	48d1                	li	a7,20
 ecall
 588:	00000073          	ecall
 ret
 58c:	8082                	ret

000000000000058e <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 58e:	48a5                	li	a7,9
 ecall
 590:	00000073          	ecall
 ret
 594:	8082                	ret

0000000000000596 <dup>:
.global dup
dup:
 li a7, SYS_dup
 596:	48a9                	li	a7,10
 ecall
 598:	00000073          	ecall
 ret
 59c:	8082                	ret

000000000000059e <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 59e:	48ad                	li	a7,11
 ecall
 5a0:	00000073          	ecall
 ret
 5a4:	8082                	ret

00000000000005a6 <sys_sbrk>:
.global sys_sbrk
sys_sbrk:
 li a7, SYS_sbrk
 5a6:	48b1                	li	a7,12
 ecall
 5a8:	00000073          	ecall
 ret
 5ac:	8082                	ret

00000000000005ae <pause>:
.global pause
pause:
 li a7, SYS_pause
 5ae:	48b5                	li	a7,13
 ecall
 5b0:	00000073          	ecall
 ret
 5b4:	8082                	ret

00000000000005b6 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5b6:	48b9                	li	a7,14
 ecall
 5b8:	00000073          	ecall
 ret
 5bc:	8082                	ret

00000000000005be <dump_proc>:
.global dump_proc
dump_proc:
 li a7, SYS_dump_proc
 5be:	48d9                	li	a7,22
 ecall
 5c0:	00000073          	ecall
 ret
 5c4:	8082                	ret

00000000000005c6 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 5c6:	1101                	addi	sp,sp,-32
 5c8:	ec06                	sd	ra,24(sp)
 5ca:	e822                	sd	s0,16(sp)
 5cc:	1000                	addi	s0,sp,32
 5ce:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5d2:	4605                	li	a2,1
 5d4:	fef40593          	addi	a1,s0,-17
 5d8:	f67ff0ef          	jal	ra,53e <write>
}
 5dc:	60e2                	ld	ra,24(sp)
 5de:	6442                	ld	s0,16(sp)
 5e0:	6105                	addi	sp,sp,32
 5e2:	8082                	ret

00000000000005e4 <printint>:

static void
printint(int fd, long long xx, int base, int sgn)
{
 5e4:	715d                	addi	sp,sp,-80
 5e6:	e486                	sd	ra,72(sp)
 5e8:	e0a2                	sd	s0,64(sp)
 5ea:	fc26                	sd	s1,56(sp)
 5ec:	f84a                	sd	s2,48(sp)
 5ee:	f44e                	sd	s3,40(sp)
 5f0:	0880                	addi	s0,sp,80
 5f2:	892a                	mv	s2,a0
  char buf[20];
  int i, neg;
  unsigned long long x;

  neg = 0;
  if(sgn && xx < 0){
 5f4:	c299                	beqz	a3,5fa <printint+0x16>
 5f6:	0805c163          	bltz	a1,678 <printint+0x94>
  neg = 0;
 5fa:	4881                	li	a7,0
 5fc:	fb840693          	addi	a3,s0,-72
    x = -xx;
  } else {
    x = xx;
  }

  i = 0;
 600:	4781                	li	a5,0
  do{
    buf[i++] = digits[x % base];
 602:	00000517          	auipc	a0,0x0
 606:	78650513          	addi	a0,a0,1926 # d88 <digits>
 60a:	883e                	mv	a6,a5
 60c:	2785                	addiw	a5,a5,1
 60e:	02c5f733          	remu	a4,a1,a2
 612:	972a                	add	a4,a4,a0
 614:	00074703          	lbu	a4,0(a4)
 618:	00e68023          	sb	a4,0(a3)
  }while((x /= base) != 0);
 61c:	872e                	mv	a4,a1
 61e:	02c5d5b3          	divu	a1,a1,a2
 622:	0685                	addi	a3,a3,1
 624:	fec773e3          	bgeu	a4,a2,60a <printint+0x26>
  if(neg)
 628:	00088b63          	beqz	a7,63e <printint+0x5a>
    buf[i++] = '-';
 62c:	fd040713          	addi	a4,s0,-48
 630:	97ba                	add	a5,a5,a4
 632:	02d00713          	li	a4,45
 636:	fee78423          	sb	a4,-24(a5)
 63a:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
 63e:	02f05663          	blez	a5,66a <printint+0x86>
 642:	fb840713          	addi	a4,s0,-72
 646:	00f704b3          	add	s1,a4,a5
 64a:	fff70993          	addi	s3,a4,-1
 64e:	99be                	add	s3,s3,a5
 650:	37fd                	addiw	a5,a5,-1
 652:	1782                	slli	a5,a5,0x20
 654:	9381                	srli	a5,a5,0x20
 656:	40f989b3          	sub	s3,s3,a5
    putc(fd, buf[i]);
 65a:	fff4c583          	lbu	a1,-1(s1)
 65e:	854a                	mv	a0,s2
 660:	f67ff0ef          	jal	ra,5c6 <putc>
  while(--i >= 0)
 664:	14fd                	addi	s1,s1,-1
 666:	ff349ae3          	bne	s1,s3,65a <printint+0x76>
}
 66a:	60a6                	ld	ra,72(sp)
 66c:	6406                	ld	s0,64(sp)
 66e:	74e2                	ld	s1,56(sp)
 670:	7942                	ld	s2,48(sp)
 672:	79a2                	ld	s3,40(sp)
 674:	6161                	addi	sp,sp,80
 676:	8082                	ret
    x = -xx;
 678:	40b005b3          	neg	a1,a1
    neg = 1;
 67c:	4885                	li	a7,1
    x = -xx;
 67e:	bfbd                	j	5fc <printint+0x18>

0000000000000680 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %c, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 680:	7119                	addi	sp,sp,-128
 682:	fc86                	sd	ra,120(sp)
 684:	f8a2                	sd	s0,112(sp)
 686:	f4a6                	sd	s1,104(sp)
 688:	f0ca                	sd	s2,96(sp)
 68a:	ecce                	sd	s3,88(sp)
 68c:	e8d2                	sd	s4,80(sp)
 68e:	e4d6                	sd	s5,72(sp)
 690:	e0da                	sd	s6,64(sp)
 692:	fc5e                	sd	s7,56(sp)
 694:	f862                	sd	s8,48(sp)
 696:	f466                	sd	s9,40(sp)
 698:	f06a                	sd	s10,32(sp)
 69a:	ec6e                	sd	s11,24(sp)
 69c:	0100                	addi	s0,sp,128
  char *s;
  int c0, c1, c2, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 69e:	0005c903          	lbu	s2,0(a1)
 6a2:	24090c63          	beqz	s2,8fa <vprintf+0x27a>
 6a6:	8b2a                	mv	s6,a0
 6a8:	8a2e                	mv	s4,a1
 6aa:	8bb2                	mv	s7,a2
  state = 0;
 6ac:	4981                	li	s3,0
  for(i = 0; fmt[i]; i++){
 6ae:	4481                	li	s1,0
 6b0:	4701                	li	a4,0
      if(c0 == '%'){
        state = '%';
      } else {
        putc(fd, c0);
      }
    } else if(state == '%'){
 6b2:	02500a93          	li	s5,37
      c1 = c2 = 0;
      if(c0) c1 = fmt[i+1] & 0xff;
      if(c1) c2 = fmt[i+2] & 0xff;
      if(c0 == 'd'){
 6b6:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c0 == 'l' && c1 == 'd'){
 6ba:	06c00d13          	li	s10,108
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 2;
      } else if(c0 == 'u'){
 6be:	07500d93          	li	s11,117
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6c2:	00000c97          	auipc	s9,0x0
 6c6:	6c6c8c93          	addi	s9,s9,1734 # d88 <digits>
 6ca:	a005                	j	6ea <vprintf+0x6a>
        putc(fd, c0);
 6cc:	85ca                	mv	a1,s2
 6ce:	855a                	mv	a0,s6
 6d0:	ef7ff0ef          	jal	ra,5c6 <putc>
 6d4:	a019                	j	6da <vprintf+0x5a>
    } else if(state == '%'){
 6d6:	03598263          	beq	s3,s5,6fa <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 6da:	2485                	addiw	s1,s1,1
 6dc:	8726                	mv	a4,s1
 6de:	009a07b3          	add	a5,s4,s1
 6e2:	0007c903          	lbu	s2,0(a5)
 6e6:	20090a63          	beqz	s2,8fa <vprintf+0x27a>
    c0 = fmt[i] & 0xff;
 6ea:	0009079b          	sext.w	a5,s2
    if(state == 0){
 6ee:	fe0994e3          	bnez	s3,6d6 <vprintf+0x56>
      if(c0 == '%'){
 6f2:	fd579de3          	bne	a5,s5,6cc <vprintf+0x4c>
        state = '%';
 6f6:	89be                	mv	s3,a5
 6f8:	b7cd                	j	6da <vprintf+0x5a>
      if(c0) c1 = fmt[i+1] & 0xff;
 6fa:	c3c1                	beqz	a5,77a <vprintf+0xfa>
 6fc:	00ea06b3          	add	a3,s4,a4
 700:	0016c683          	lbu	a3,1(a3)
      c1 = c2 = 0;
 704:	8636                	mv	a2,a3
      if(c1) c2 = fmt[i+2] & 0xff;
 706:	c681                	beqz	a3,70e <vprintf+0x8e>
 708:	9752                	add	a4,a4,s4
 70a:	00274603          	lbu	a2,2(a4)
      if(c0 == 'd'){
 70e:	03878e63          	beq	a5,s8,74a <vprintf+0xca>
      } else if(c0 == 'l' && c1 == 'd'){
 712:	05a78863          	beq	a5,s10,762 <vprintf+0xe2>
      } else if(c0 == 'u'){
 716:	0db78b63          	beq	a5,s11,7ec <vprintf+0x16c>
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 2;
      } else if(c0 == 'x'){
 71a:	07800713          	li	a4,120
 71e:	10e78d63          	beq	a5,a4,838 <vprintf+0x1b8>
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 2;
      } else if(c0 == 'p'){
 722:	07000713          	li	a4,112
 726:	14e78263          	beq	a5,a4,86a <vprintf+0x1ea>
        printptr(fd, va_arg(ap, uint64));
      } else if(c0 == 'c'){
 72a:	06300713          	li	a4,99
 72e:	16e78f63          	beq	a5,a4,8ac <vprintf+0x22c>
        putc(fd, va_arg(ap, uint32));
      } else if(c0 == 's'){
 732:	07300713          	li	a4,115
 736:	18e78563          	beq	a5,a4,8c0 <vprintf+0x240>
        if((s = va_arg(ap, char*)) == 0)
          s = "(null)";
        for(; *s; s++)
          putc(fd, *s);
      } else if(c0 == '%'){
 73a:	05579063          	bne	a5,s5,77a <vprintf+0xfa>
        putc(fd, '%');
 73e:	85d6                	mv	a1,s5
 740:	855a                	mv	a0,s6
 742:	e85ff0ef          	jal	ra,5c6 <putc>
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c0);
      }

      state = 0;
 746:	4981                	li	s3,0
 748:	bf49                	j	6da <vprintf+0x5a>
        printint(fd, va_arg(ap, int), 10, 1);
 74a:	008b8913          	addi	s2,s7,8
 74e:	4685                	li	a3,1
 750:	4629                	li	a2,10
 752:	000ba583          	lw	a1,0(s7)
 756:	855a                	mv	a0,s6
 758:	e8dff0ef          	jal	ra,5e4 <printint>
 75c:	8bca                	mv	s7,s2
      state = 0;
 75e:	4981                	li	s3,0
 760:	bfad                	j	6da <vprintf+0x5a>
      } else if(c0 == 'l' && c1 == 'd'){
 762:	03868663          	beq	a3,s8,78e <vprintf+0x10e>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 766:	05a68163          	beq	a3,s10,7a8 <vprintf+0x128>
      } else if(c0 == 'l' && c1 == 'u'){
 76a:	09b68d63          	beq	a3,s11,804 <vprintf+0x184>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 76e:	03a68f63          	beq	a3,s10,7ac <vprintf+0x12c>
      } else if(c0 == 'l' && c1 == 'x'){
 772:	07800793          	li	a5,120
 776:	0cf68d63          	beq	a3,a5,850 <vprintf+0x1d0>
        putc(fd, '%');
 77a:	85d6                	mv	a1,s5
 77c:	855a                	mv	a0,s6
 77e:	e49ff0ef          	jal	ra,5c6 <putc>
        putc(fd, c0);
 782:	85ca                	mv	a1,s2
 784:	855a                	mv	a0,s6
 786:	e41ff0ef          	jal	ra,5c6 <putc>
      state = 0;
 78a:	4981                	li	s3,0
 78c:	b7b9                	j	6da <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 78e:	008b8913          	addi	s2,s7,8
 792:	4685                	li	a3,1
 794:	4629                	li	a2,10
 796:	000bb583          	ld	a1,0(s7)
 79a:	855a                	mv	a0,s6
 79c:	e49ff0ef          	jal	ra,5e4 <printint>
        i += 1;
 7a0:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 1);
 7a2:	8bca                	mv	s7,s2
      state = 0;
 7a4:	4981                	li	s3,0
        i += 1;
 7a6:	bf15                	j	6da <vprintf+0x5a>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 7a8:	03860563          	beq	a2,s8,7d2 <vprintf+0x152>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 7ac:	07b60963          	beq	a2,s11,81e <vprintf+0x19e>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
 7b0:	07800793          	li	a5,120
 7b4:	fcf613e3          	bne	a2,a5,77a <vprintf+0xfa>
        printint(fd, va_arg(ap, uint64), 16, 0);
 7b8:	008b8913          	addi	s2,s7,8
 7bc:	4681                	li	a3,0
 7be:	4641                	li	a2,16
 7c0:	000bb583          	ld	a1,0(s7)
 7c4:	855a                	mv	a0,s6
 7c6:	e1fff0ef          	jal	ra,5e4 <printint>
        i += 2;
 7ca:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 16, 0);
 7cc:	8bca                	mv	s7,s2
      state = 0;
 7ce:	4981                	li	s3,0
        i += 2;
 7d0:	b729                	j	6da <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 7d2:	008b8913          	addi	s2,s7,8
 7d6:	4685                	li	a3,1
 7d8:	4629                	li	a2,10
 7da:	000bb583          	ld	a1,0(s7)
 7de:	855a                	mv	a0,s6
 7e0:	e05ff0ef          	jal	ra,5e4 <printint>
        i += 2;
 7e4:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 1);
 7e6:	8bca                	mv	s7,s2
      state = 0;
 7e8:	4981                	li	s3,0
        i += 2;
 7ea:	bdc5                	j	6da <vprintf+0x5a>
        printint(fd, va_arg(ap, uint32), 10, 0);
 7ec:	008b8913          	addi	s2,s7,8
 7f0:	4681                	li	a3,0
 7f2:	4629                	li	a2,10
 7f4:	000be583          	lwu	a1,0(s7)
 7f8:	855a                	mv	a0,s6
 7fa:	debff0ef          	jal	ra,5e4 <printint>
 7fe:	8bca                	mv	s7,s2
      state = 0;
 800:	4981                	li	s3,0
 802:	bde1                	j	6da <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 804:	008b8913          	addi	s2,s7,8
 808:	4681                	li	a3,0
 80a:	4629                	li	a2,10
 80c:	000bb583          	ld	a1,0(s7)
 810:	855a                	mv	a0,s6
 812:	dd3ff0ef          	jal	ra,5e4 <printint>
        i += 1;
 816:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 0);
 818:	8bca                	mv	s7,s2
      state = 0;
 81a:	4981                	li	s3,0
        i += 1;
 81c:	bd7d                	j	6da <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 81e:	008b8913          	addi	s2,s7,8
 822:	4681                	li	a3,0
 824:	4629                	li	a2,10
 826:	000bb583          	ld	a1,0(s7)
 82a:	855a                	mv	a0,s6
 82c:	db9ff0ef          	jal	ra,5e4 <printint>
        i += 2;
 830:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 0);
 832:	8bca                	mv	s7,s2
      state = 0;
 834:	4981                	li	s3,0
        i += 2;
 836:	b555                	j	6da <vprintf+0x5a>
        printint(fd, va_arg(ap, uint32), 16, 0);
 838:	008b8913          	addi	s2,s7,8
 83c:	4681                	li	a3,0
 83e:	4641                	li	a2,16
 840:	000be583          	lwu	a1,0(s7)
 844:	855a                	mv	a0,s6
 846:	d9fff0ef          	jal	ra,5e4 <printint>
 84a:	8bca                	mv	s7,s2
      state = 0;
 84c:	4981                	li	s3,0
 84e:	b571                	j	6da <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 16, 0);
 850:	008b8913          	addi	s2,s7,8
 854:	4681                	li	a3,0
 856:	4641                	li	a2,16
 858:	000bb583          	ld	a1,0(s7)
 85c:	855a                	mv	a0,s6
 85e:	d87ff0ef          	jal	ra,5e4 <printint>
        i += 1;
 862:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 16, 0);
 864:	8bca                	mv	s7,s2
      state = 0;
 866:	4981                	li	s3,0
        i += 1;
 868:	bd8d                	j	6da <vprintf+0x5a>
        printptr(fd, va_arg(ap, uint64));
 86a:	008b8793          	addi	a5,s7,8
 86e:	f8f43423          	sd	a5,-120(s0)
 872:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 876:	03000593          	li	a1,48
 87a:	855a                	mv	a0,s6
 87c:	d4bff0ef          	jal	ra,5c6 <putc>
  putc(fd, 'x');
 880:	07800593          	li	a1,120
 884:	855a                	mv	a0,s6
 886:	d41ff0ef          	jal	ra,5c6 <putc>
 88a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 88c:	03c9d793          	srli	a5,s3,0x3c
 890:	97e6                	add	a5,a5,s9
 892:	0007c583          	lbu	a1,0(a5)
 896:	855a                	mv	a0,s6
 898:	d2fff0ef          	jal	ra,5c6 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 89c:	0992                	slli	s3,s3,0x4
 89e:	397d                	addiw	s2,s2,-1
 8a0:	fe0916e3          	bnez	s2,88c <vprintf+0x20c>
        printptr(fd, va_arg(ap, uint64));
 8a4:	f8843b83          	ld	s7,-120(s0)
      state = 0;
 8a8:	4981                	li	s3,0
 8aa:	bd05                	j	6da <vprintf+0x5a>
        putc(fd, va_arg(ap, uint32));
 8ac:	008b8913          	addi	s2,s7,8
 8b0:	000bc583          	lbu	a1,0(s7)
 8b4:	855a                	mv	a0,s6
 8b6:	d11ff0ef          	jal	ra,5c6 <putc>
 8ba:	8bca                	mv	s7,s2
      state = 0;
 8bc:	4981                	li	s3,0
 8be:	bd31                	j	6da <vprintf+0x5a>
        if((s = va_arg(ap, char*)) == 0)
 8c0:	008b8993          	addi	s3,s7,8
 8c4:	000bb903          	ld	s2,0(s7)
 8c8:	00090f63          	beqz	s2,8e6 <vprintf+0x266>
        for(; *s; s++)
 8cc:	00094583          	lbu	a1,0(s2)
 8d0:	c195                	beqz	a1,8f4 <vprintf+0x274>
          putc(fd, *s);
 8d2:	855a                	mv	a0,s6
 8d4:	cf3ff0ef          	jal	ra,5c6 <putc>
        for(; *s; s++)
 8d8:	0905                	addi	s2,s2,1
 8da:	00094583          	lbu	a1,0(s2)
 8de:	f9f5                	bnez	a1,8d2 <vprintf+0x252>
        if((s = va_arg(ap, char*)) == 0)
 8e0:	8bce                	mv	s7,s3
      state = 0;
 8e2:	4981                	li	s3,0
 8e4:	bbdd                	j	6da <vprintf+0x5a>
          s = "(null)";
 8e6:	00000917          	auipc	s2,0x0
 8ea:	49a90913          	addi	s2,s2,1178 # d80 <malloc+0x384>
        for(; *s; s++)
 8ee:	02800593          	li	a1,40
 8f2:	b7c5                	j	8d2 <vprintf+0x252>
        if((s = va_arg(ap, char*)) == 0)
 8f4:	8bce                	mv	s7,s3
      state = 0;
 8f6:	4981                	li	s3,0
 8f8:	b3cd                	j	6da <vprintf+0x5a>
    }
  }
}
 8fa:	70e6                	ld	ra,120(sp)
 8fc:	7446                	ld	s0,112(sp)
 8fe:	74a6                	ld	s1,104(sp)
 900:	7906                	ld	s2,96(sp)
 902:	69e6                	ld	s3,88(sp)
 904:	6a46                	ld	s4,80(sp)
 906:	6aa6                	ld	s5,72(sp)
 908:	6b06                	ld	s6,64(sp)
 90a:	7be2                	ld	s7,56(sp)
 90c:	7c42                	ld	s8,48(sp)
 90e:	7ca2                	ld	s9,40(sp)
 910:	7d02                	ld	s10,32(sp)
 912:	6de2                	ld	s11,24(sp)
 914:	6109                	addi	sp,sp,128
 916:	8082                	ret

0000000000000918 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 918:	715d                	addi	sp,sp,-80
 91a:	ec06                	sd	ra,24(sp)
 91c:	e822                	sd	s0,16(sp)
 91e:	1000                	addi	s0,sp,32
 920:	e010                	sd	a2,0(s0)
 922:	e414                	sd	a3,8(s0)
 924:	e818                	sd	a4,16(s0)
 926:	ec1c                	sd	a5,24(s0)
 928:	03043023          	sd	a6,32(s0)
 92c:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 930:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 934:	8622                	mv	a2,s0
 936:	d4bff0ef          	jal	ra,680 <vprintf>
}
 93a:	60e2                	ld	ra,24(sp)
 93c:	6442                	ld	s0,16(sp)
 93e:	6161                	addi	sp,sp,80
 940:	8082                	ret

0000000000000942 <printf>:

void
printf(const char *fmt, ...)
{
 942:	711d                	addi	sp,sp,-96
 944:	ec06                	sd	ra,24(sp)
 946:	e822                	sd	s0,16(sp)
 948:	1000                	addi	s0,sp,32
 94a:	e40c                	sd	a1,8(s0)
 94c:	e810                	sd	a2,16(s0)
 94e:	ec14                	sd	a3,24(s0)
 950:	f018                	sd	a4,32(s0)
 952:	f41c                	sd	a5,40(s0)
 954:	03043823          	sd	a6,48(s0)
 958:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 95c:	00840613          	addi	a2,s0,8
 960:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 964:	85aa                	mv	a1,a0
 966:	4505                	li	a0,1
 968:	d19ff0ef          	jal	ra,680 <vprintf>
}
 96c:	60e2                	ld	ra,24(sp)
 96e:	6442                	ld	s0,16(sp)
 970:	6125                	addi	sp,sp,96
 972:	8082                	ret

0000000000000974 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 974:	1141                	addi	sp,sp,-16
 976:	e422                	sd	s0,8(sp)
 978:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 97a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 97e:	00000797          	auipc	a5,0x0
 982:	6827b783          	ld	a5,1666(a5) # 1000 <freep>
 986:	a805                	j	9b6 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 988:	4618                	lw	a4,8(a2)
 98a:	9db9                	addw	a1,a1,a4
 98c:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 990:	6398                	ld	a4,0(a5)
 992:	6318                	ld	a4,0(a4)
 994:	fee53823          	sd	a4,-16(a0)
 998:	a091                	j	9dc <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 99a:	ff852703          	lw	a4,-8(a0)
 99e:	9e39                	addw	a2,a2,a4
 9a0:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 9a2:	ff053703          	ld	a4,-16(a0)
 9a6:	e398                	sd	a4,0(a5)
 9a8:	a099                	j	9ee <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9aa:	6398                	ld	a4,0(a5)
 9ac:	00e7e463          	bltu	a5,a4,9b4 <free+0x40>
 9b0:	00e6ea63          	bltu	a3,a4,9c4 <free+0x50>
{
 9b4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 9b6:	fed7fae3          	bgeu	a5,a3,9aa <free+0x36>
 9ba:	6398                	ld	a4,0(a5)
 9bc:	00e6e463          	bltu	a3,a4,9c4 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9c0:	fee7eae3          	bltu	a5,a4,9b4 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 9c4:	ff852583          	lw	a1,-8(a0)
 9c8:	6390                	ld	a2,0(a5)
 9ca:	02059713          	slli	a4,a1,0x20
 9ce:	9301                	srli	a4,a4,0x20
 9d0:	0712                	slli	a4,a4,0x4
 9d2:	9736                	add	a4,a4,a3
 9d4:	fae60ae3          	beq	a2,a4,988 <free+0x14>
    bp->s.ptr = p->s.ptr;
 9d8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 9dc:	4790                	lw	a2,8(a5)
 9de:	02061713          	slli	a4,a2,0x20
 9e2:	9301                	srli	a4,a4,0x20
 9e4:	0712                	slli	a4,a4,0x4
 9e6:	973e                	add	a4,a4,a5
 9e8:	fae689e3          	beq	a3,a4,99a <free+0x26>
  } else
    p->s.ptr = bp;
 9ec:	e394                	sd	a3,0(a5)
  freep = p;
 9ee:	00000717          	auipc	a4,0x0
 9f2:	60f73923          	sd	a5,1554(a4) # 1000 <freep>
}
 9f6:	6422                	ld	s0,8(sp)
 9f8:	0141                	addi	sp,sp,16
 9fa:	8082                	ret

00000000000009fc <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 9fc:	7139                	addi	sp,sp,-64
 9fe:	fc06                	sd	ra,56(sp)
 a00:	f822                	sd	s0,48(sp)
 a02:	f426                	sd	s1,40(sp)
 a04:	f04a                	sd	s2,32(sp)
 a06:	ec4e                	sd	s3,24(sp)
 a08:	e852                	sd	s4,16(sp)
 a0a:	e456                	sd	s5,8(sp)
 a0c:	e05a                	sd	s6,0(sp)
 a0e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 a10:	02051493          	slli	s1,a0,0x20
 a14:	9081                	srli	s1,s1,0x20
 a16:	04bd                	addi	s1,s1,15
 a18:	8091                	srli	s1,s1,0x4
 a1a:	0014899b          	addiw	s3,s1,1
 a1e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 a20:	00000517          	auipc	a0,0x0
 a24:	5e053503          	ld	a0,1504(a0) # 1000 <freep>
 a28:	c515                	beqz	a0,a54 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a2a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a2c:	4798                	lw	a4,8(a5)
 a2e:	02977f63          	bgeu	a4,s1,a6c <malloc+0x70>
 a32:	8a4e                	mv	s4,s3
 a34:	0009871b          	sext.w	a4,s3
 a38:	6685                	lui	a3,0x1
 a3a:	00d77363          	bgeu	a4,a3,a40 <malloc+0x44>
 a3e:	6a05                	lui	s4,0x1
 a40:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 a44:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 a48:	00000917          	auipc	s2,0x0
 a4c:	5b890913          	addi	s2,s2,1464 # 1000 <freep>
  if(p == SBRK_ERROR)
 a50:	5afd                	li	s5,-1
 a52:	a0bd                	j	ac0 <malloc+0xc4>
    base.s.ptr = freep = prevp = &base;
 a54:	00000797          	auipc	a5,0x0
 a58:	5bc78793          	addi	a5,a5,1468 # 1010 <base>
 a5c:	00000717          	auipc	a4,0x0
 a60:	5af73223          	sd	a5,1444(a4) # 1000 <freep>
 a64:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a66:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a6a:	b7e1                	j	a32 <malloc+0x36>
      if(p->s.size == nunits)
 a6c:	02e48b63          	beq	s1,a4,aa2 <malloc+0xa6>
        p->s.size -= nunits;
 a70:	4137073b          	subw	a4,a4,s3
 a74:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a76:	1702                	slli	a4,a4,0x20
 a78:	9301                	srli	a4,a4,0x20
 a7a:	0712                	slli	a4,a4,0x4
 a7c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a7e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a82:	00000717          	auipc	a4,0x0
 a86:	56a73f23          	sd	a0,1406(a4) # 1000 <freep>
      return (void*)(p + 1);
 a8a:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a8e:	70e2                	ld	ra,56(sp)
 a90:	7442                	ld	s0,48(sp)
 a92:	74a2                	ld	s1,40(sp)
 a94:	7902                	ld	s2,32(sp)
 a96:	69e2                	ld	s3,24(sp)
 a98:	6a42                	ld	s4,16(sp)
 a9a:	6aa2                	ld	s5,8(sp)
 a9c:	6b02                	ld	s6,0(sp)
 a9e:	6121                	addi	sp,sp,64
 aa0:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 aa2:	6398                	ld	a4,0(a5)
 aa4:	e118                	sd	a4,0(a0)
 aa6:	bff1                	j	a82 <malloc+0x86>
  hp->s.size = nu;
 aa8:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 aac:	0541                	addi	a0,a0,16
 aae:	ec7ff0ef          	jal	ra,974 <free>
  return freep;
 ab2:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 ab6:	dd61                	beqz	a0,a8e <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 ab8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 aba:	4798                	lw	a4,8(a5)
 abc:	fa9778e3          	bgeu	a4,s1,a6c <malloc+0x70>
    if(p == freep)
 ac0:	00093703          	ld	a4,0(s2)
 ac4:	853e                	mv	a0,a5
 ac6:	fef719e3          	bne	a4,a5,ab8 <malloc+0xbc>
  p = sbrk(nu * sizeof(Header));
 aca:	8552                	mv	a0,s4
 acc:	a1fff0ef          	jal	ra,4ea <sbrk>
  if(p == SBRK_ERROR)
 ad0:	fd551ce3          	bne	a0,s5,aa8 <malloc+0xac>
        return 0;
 ad4:	4501                	li	a0,0
 ad6:	bf65                	j	a8e <malloc+0x92>
