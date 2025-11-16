
user/_cowtest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <simpletest>:
#include "kernel/types.h"
#include "kernel/memlayout.h"  // 包含 PHYSTOP 等内存布局定义
#include "user/user.h"

// 测试1：分配超过一半物理内存后 fork，验证 COW 能避免内存耗尽
void simpletest() {
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
  // 计算物理内存总大小（PHYSTOP - KERNBASE 是用户可用物理内存上限）
  uint64 phys_size = PHYSTOP - KERNBASE;
  // 分配约 2/3 的物理内存（在非 COW 系统中，fork 会因复制失败而崩溃）
  int sz = (phys_size / 3) * 2;

  printf("simple: ");
   e:	00001517          	auipc	a0,0x1
  12:	c3250513          	addi	a0,a0,-974 # c40 <malloc+0xe4>
  16:	28d000ef          	jal	ra,aa2 <printf>

  // 使用 sbrk 扩展堆，分配 sz 字节内存
  char *p = sbrk(sz);
  1a:	05555537          	lui	a0,0x5555
  1e:	55450513          	addi	a0,a0,1364 # 5555554 <base+0x5550544>
  22:	628000ef          	jal	ra,64a <sbrk>
  if (p == (char*)0xffffffffffffffffL) {
  26:	57fd                	li	a5,-1
  28:	04f50b63          	beq	a0,a5,7e <simpletest+0x7e>
  2c:	84aa                	mv	s1,a0
    printf("sbrk(%d) failed\n", sz);
    exit(-1);
  }

  // 向每一页写入当前进程 ID（确保所有页都被“使用”，防止懒分配绕过测试）
  for (char *q = p; q < p + sz; q += 4096) {
  2e:	05556937          	lui	s2,0x5556
  32:	992a                	add	s2,s2,a0
  34:	6985                	lui	s3,0x1
    *(int*)q = getpid();
  36:	6c8000ef          	jal	ra,6fe <getpid>
  3a:	c088                	sw	a0,0(s1)
  for (char *q = p; q < p + sz; q += 4096) {
  3c:	94ce                	add	s1,s1,s3
  3e:	fe991ce3          	bne	s2,s1,36 <simpletest+0x36>
  }

  // 尝试 fork —— 如果没有 COW，内核会尝试复制所有页，导致内存不足而失败
  int pid = fork();
  42:	634000ef          	jal	ra,676 <fork>
  if (pid < 0) {
  46:	04054963          	bltz	a0,98 <simpletest+0x98>
    printf("fork() failed\n");
    exit(-1);
  }

  if (pid == 0) {
  4a:	c125                	beqz	a0,aa <simpletest+0xaa>
    // 子进程直接退出（不写内存，仅验证 fork 成功）
    exit(0);
  }

  // 父进程等待子进程结束
  wait(0);
  4c:	4501                	li	a0,0
  4e:	638000ef          	jal	ra,686 <wait>

  // 释放之前分配的内存
  if (sbrk(-sz) == (char*)0xffffffffffffffffL) {
  52:	faaab537          	lui	a0,0xfaaab
  56:	aac50513          	addi	a0,a0,-1364 # fffffffffaaaaaac <base+0xfffffffffaaa5a9c>
  5a:	5f0000ef          	jal	ra,64a <sbrk>
  5e:	57fd                	li	a5,-1
  60:	04f50763          	beq	a0,a5,ae <simpletest+0xae>
    printf("sbrk(-%d) failed\n", sz);
    exit(-1);
  }

  printf("ok\n");
  64:	00001517          	auipc	a0,0x1
  68:	c2c50513          	addi	a0,a0,-980 # c90 <malloc+0x134>
  6c:	237000ef          	jal	ra,aa2 <printf>
}
  70:	70a2                	ld	ra,40(sp)
  72:	7402                	ld	s0,32(sp)
  74:	64e2                	ld	s1,24(sp)
  76:	6942                	ld	s2,16(sp)
  78:	69a2                	ld	s3,8(sp)
  7a:	6145                	addi	sp,sp,48
  7c:	8082                	ret
    printf("sbrk(%d) failed\n", sz);
  7e:	055555b7          	lui	a1,0x5555
  82:	55458593          	addi	a1,a1,1364 # 5555554 <base+0x5550544>
  86:	00001517          	auipc	a0,0x1
  8a:	bca50513          	addi	a0,a0,-1078 # c50 <malloc+0xf4>
  8e:	215000ef          	jal	ra,aa2 <printf>
    exit(-1);
  92:	557d                	li	a0,-1
  94:	5ea000ef          	jal	ra,67e <exit>
    printf("fork() failed\n");
  98:	00001517          	auipc	a0,0x1
  9c:	bd050513          	addi	a0,a0,-1072 # c68 <malloc+0x10c>
  a0:	203000ef          	jal	ra,aa2 <printf>
    exit(-1);
  a4:	557d                	li	a0,-1
  a6:	5d8000ef          	jal	ra,67e <exit>
    exit(0);
  aa:	5d4000ef          	jal	ra,67e <exit>
    printf("sbrk(-%d) failed\n", sz);
  ae:	055555b7          	lui	a1,0x5555
  b2:	55458593          	addi	a1,a1,1364 # 5555554 <base+0x5550544>
  b6:	00001517          	auipc	a0,0x1
  ba:	bc250513          	addi	a0,a0,-1086 # c78 <malloc+0x11c>
  be:	1e5000ef          	jal	ra,aa2 <printf>
    exit(-1);
  c2:	557d                	li	a0,-1
  c4:	5ba000ef          	jal	ra,67e <exit>

00000000000000c8 <threetest>:

// 测试2：三个进程并发写同一块 COW 内存区域，
// 验证：1) 写操作隔离；2) 复制的页能被正确释放；3) 不会耗尽内存
void threetest() {
  c8:	7179                	addi	sp,sp,-48
  ca:	f406                	sd	ra,40(sp)
  cc:	f022                	sd	s0,32(sp)
  ce:	ec26                	sd	s1,24(sp)
  d0:	e84a                	sd	s2,16(sp)
  d2:	e44e                	sd	s3,8(sp)
  d4:	e052                	sd	s4,0(sp)
  d6:	1800                	addi	s0,sp,48
  uint64 phys_size = PHYSTOP - KERNBASE;
  int sz = phys_size / 4;  // 分配 1/4 物理内存
  int pid1, pid2;

  printf("three: ");
  d8:	00001517          	auipc	a0,0x1
  dc:	bc050513          	addi	a0,a0,-1088 # c98 <malloc+0x13c>
  e0:	1c3000ef          	jal	ra,aa2 <printf>

  char *p = sbrk(sz);
  e4:	02000537          	lui	a0,0x2000
  e8:	562000ef          	jal	ra,64a <sbrk>
  if (p == (char*)0xffffffffffffffffL) {
  ec:	57fd                	li	a5,-1
  ee:	06f50963          	beq	a0,a5,160 <threetest+0x98>
  f2:	84aa                	mv	s1,a0
    printf("sbrk(%d) failed\n", sz);
    exit(-1);
  }

  // 第一次 fork：创建子进程1
  pid1 = fork();
  f4:	582000ef          	jal	ra,676 <fork>
  if (pid1 < 0) {
  f8:	06054f63          	bltz	a0,176 <threetest+0xae>
    printf("fork failed\n");
    exit(-1);
  }

  if (pid1 == 0) {
  fc:	c551                	beqz	a0,188 <threetest+0xc0>
    }
    exit(0);
  }

  // 父进程：写整个内存区域
  for (char *q = p; q < p + sz; q += 4096) {
  fe:	020009b7          	lui	s3,0x2000
 102:	99a6                	add	s3,s3,s1
 104:	8926                	mv	s2,s1
 106:	6a05                	lui	s4,0x1
    *(int*)q = getpid();
 108:	5f6000ef          	jal	ra,6fe <getpid>
 10c:	00a92023          	sw	a0,0(s2) # 5556000 <base+0x5550ff0>
  for (char *q = p; q < p + sz; q += 4096) {
 110:	9952                	add	s2,s2,s4
 112:	ff391be3          	bne	s2,s3,108 <threetest+0x40>
  }

  // 等待子进程1结束（子进程1 会等待子进程2）
  wait(0);
 116:	4501                	li	a0,0
 118:	56e000ef          	jal	ra,686 <wait>

  // 稍等片刻，让子进程完全退出，释放其占用的物理页
  pause(1);
 11c:	4505                	li	a0,1
 11e:	5f0000ef          	jal	ra,70e <pause>

  // 验证父进程自己的内存内容未被子进程修改
  for (char *q = p; q < p + sz; q += 4096) {
 122:	6a05                	lui	s4,0x1
    if (*(int*)q != getpid()) {
 124:	0004a903          	lw	s2,0(s1)
 128:	5d6000ef          	jal	ra,6fe <getpid>
 12c:	0ca91c63          	bne	s2,a0,204 <threetest+0x13c>
  for (char *q = p; q < p + sz; q += 4096) {
 130:	94d2                	add	s1,s1,s4
 132:	ff3499e3          	bne	s1,s3,124 <threetest+0x5c>
      exit(-1);
    }
  }

  // 释放内存
  if (sbrk(-sz) == (char*)0xffffffffffffffffL) {
 136:	fe000537          	lui	a0,0xfe000
 13a:	510000ef          	jal	ra,64a <sbrk>
 13e:	57fd                	li	a5,-1
 140:	0cf50b63          	beq	a0,a5,216 <threetest+0x14e>
    printf("sbrk(-%d) failed\n", sz);
    exit(-1);
  }

  printf("ok\n");
 144:	00001517          	auipc	a0,0x1
 148:	b4c50513          	addi	a0,a0,-1204 # c90 <malloc+0x134>
 14c:	157000ef          	jal	ra,aa2 <printf>
}
 150:	70a2                	ld	ra,40(sp)
 152:	7402                	ld	s0,32(sp)
 154:	64e2                	ld	s1,24(sp)
 156:	6942                	ld	s2,16(sp)
 158:	69a2                	ld	s3,8(sp)
 15a:	6a02                	ld	s4,0(sp)
 15c:	6145                	addi	sp,sp,48
 15e:	8082                	ret
    printf("sbrk(%d) failed\n", sz);
 160:	020005b7          	lui	a1,0x2000
 164:	00001517          	auipc	a0,0x1
 168:	aec50513          	addi	a0,a0,-1300 # c50 <malloc+0xf4>
 16c:	137000ef          	jal	ra,aa2 <printf>
    exit(-1);
 170:	557d                	li	a0,-1
 172:	50c000ef          	jal	ra,67e <exit>
    printf("fork failed\n");
 176:	00001517          	auipc	a0,0x1
 17a:	b2a50513          	addi	a0,a0,-1238 # ca0 <malloc+0x144>
 17e:	125000ef          	jal	ra,aa2 <printf>
    exit(-1);
 182:	557d                	li	a0,-1
 184:	4fa000ef          	jal	ra,67e <exit>
    pid2 = fork();
 188:	4ee000ef          	jal	ra,676 <fork>
    if (pid2 < 0) {
 18c:	02054c63          	bltz	a0,1c4 <threetest+0xfc>
    if (pid2 == 0) {
 190:	e139                	bnez	a0,1d6 <threetest+0x10e>
      for (char *q = p; q < p + (sz/5)*4; q += 4096) {
 192:	0199a9b7          	lui	s3,0x199a
 196:	99a6                	add	s3,s3,s1
 198:	8926                	mv	s2,s1
 19a:	6a05                	lui	s4,0x1
        *(int*)q = getpid();  // 写入自己的 PID
 19c:	562000ef          	jal	ra,6fe <getpid>
 1a0:	00a92023          	sw	a0,0(s2)
      for (char *q = p; q < p + (sz/5)*4; q += 4096) {
 1a4:	9952                	add	s2,s2,s4
 1a6:	ff299be3          	bne	s3,s2,19c <threetest+0xd4>
      for (char *q = p; q < p + (sz/5)*4; q += 4096) {
 1aa:	6a05                	lui	s4,0x1
        if (*(int*)q != getpid()) {
 1ac:	0004a903          	lw	s2,0(s1)
 1b0:	54e000ef          	jal	ra,6fe <getpid>
 1b4:	02a91f63          	bne	s2,a0,1f2 <threetest+0x12a>
      for (char *q = p; q < p + (sz/5)*4; q += 4096) {
 1b8:	94d2                	add	s1,s1,s4
 1ba:	fe9999e3          	bne	s3,s1,1ac <threetest+0xe4>
      exit(0);  // 注意：这里应为 exit(0)，原代码写的是 exit(-1)，可能是笔误
 1be:	4501                	li	a0,0
 1c0:	4be000ef          	jal	ra,67e <exit>
      printf("fork failed");
 1c4:	00001517          	auipc	a0,0x1
 1c8:	aec50513          	addi	a0,a0,-1300 # cb0 <malloc+0x154>
 1cc:	0d7000ef          	jal	ra,aa2 <printf>
      exit(-1);
 1d0:	557d                	li	a0,-1
 1d2:	4ac000ef          	jal	ra,67e <exit>
    for (char *q = p; q < p + (sz/2); q += 4096) {
 1d6:	01000737          	lui	a4,0x1000
 1da:	9726                	add	a4,a4,s1
      *(int*)q = 9999;
 1dc:	6789                	lui	a5,0x2
 1de:	70f78793          	addi	a5,a5,1807 # 270f <buf+0x6ff>
    for (char *q = p; q < p + (sz/2); q += 4096) {
 1e2:	6685                	lui	a3,0x1
      *(int*)q = 9999;
 1e4:	c09c                	sw	a5,0(s1)
    for (char *q = p; q < p + (sz/2); q += 4096) {
 1e6:	94b6                	add	s1,s1,a3
 1e8:	fee49ee3          	bne	s1,a4,1e4 <threetest+0x11c>
    exit(0);
 1ec:	4501                	li	a0,0
 1ee:	490000ef          	jal	ra,67e <exit>
          printf("wrong content\n");
 1f2:	00001517          	auipc	a0,0x1
 1f6:	ace50513          	addi	a0,a0,-1330 # cc0 <malloc+0x164>
 1fa:	0a9000ef          	jal	ra,aa2 <printf>
          exit(-1);
 1fe:	557d                	li	a0,-1
 200:	47e000ef          	jal	ra,67e <exit>
      printf("wrong content\n");
 204:	00001517          	auipc	a0,0x1
 208:	abc50513          	addi	a0,a0,-1348 # cc0 <malloc+0x164>
 20c:	097000ef          	jal	ra,aa2 <printf>
      exit(-1);
 210:	557d                	li	a0,-1
 212:	46c000ef          	jal	ra,67e <exit>
    printf("sbrk(-%d) failed\n", sz);
 216:	020005b7          	lui	a1,0x2000
 21a:	00001517          	auipc	a0,0x1
 21e:	a5e50513          	addi	a0,a0,-1442 # c78 <malloc+0x11c>
 222:	081000ef          	jal	ra,aa2 <printf>
    exit(-1);
 226:	557d                	li	a0,-1
 228:	456000ef          	jal	ra,67e <exit>

000000000000022c <filetest>:
char buf[4096];   // 关键：这个缓冲区会被子进程通过 read() 修改
char junk3[4096];

// 测试3：验证内核的 copyout() 是否能正确处理 COW
// （例如 read() 系统调用向用户空间写数据时，应触发 COW）
void filetest() {
 22c:	7179                	addi	sp,sp,-48
 22e:	f406                	sd	ra,40(sp)
 230:	f022                	sd	s0,32(sp)
 232:	ec26                	sd	s1,24(sp)
 234:	e84a                	sd	s2,16(sp)
 236:	1800                	addi	s0,sp,48
  printf("file: ");
 238:	00001517          	auipc	a0,0x1
 23c:	a9850513          	addi	a0,a0,-1384 # cd0 <malloc+0x174>
 240:	063000ef          	jal	ra,aa2 <printf>

  // 父进程初始化 buf[0] 为 99
  buf[0] = 99;
 244:	06300793          	li	a5,99
 248:	00002717          	auipc	a4,0x2
 24c:	dcf70423          	sb	a5,-568(a4) # 2010 <buf>

  // 创建 4 个子进程，每个通过 pipe 读取一个不同整数
  for (int i = 0; i < 4; i++) {
 250:	fc042c23          	sw	zero,-40(s0)
    if (pipe(fds) != 0) {
 254:	00001497          	auipc	s1,0x1
 258:	dac48493          	addi	s1,s1,-596 # 1000 <fds>
  for (int i = 0; i < 4; i++) {
 25c:	490d                	li	s2,3
    if (pipe(fds) != 0) {
 25e:	8526                	mv	a0,s1
 260:	42e000ef          	jal	ra,68e <pipe>
 264:	ed3d                	bnez	a0,2e2 <filetest+0xb6>
      printf("pipe() failed\n");
      exit(-1);
    }

    int pid = fork();
 266:	410000ef          	jal	ra,676 <fork>
    if (pid < 0) {
 26a:	08054563          	bltz	a0,2f4 <filetest+0xc8>
      printf("fork failed\n");
      exit(-1);
    }

    if (pid == 0) {
 26e:	cd41                	beqz	a0,306 <filetest+0xda>
      }
      exit(0);
    }

    // 父进程：向 pipe 写入整数 i
    if (write(fds[1], &i, sizeof(i)) != sizeof(i)) {
 270:	4611                	li	a2,4
 272:	fd840593          	addi	a1,s0,-40
 276:	40c8                	lw	a0,4(s1)
 278:	426000ef          	jal	ra,69e <write>
 27c:	4791                	li	a5,4
 27e:	0ef51563          	bne	a0,a5,368 <filetest+0x13c>
      printf("error: write failed\n");
      exit(-1);
    }
    // 关闭 pipe（虽然不影响测试，但好习惯）
    close(fds[0]);
 282:	4088                	lw	a0,0(s1)
 284:	422000ef          	jal	ra,6a6 <close>
    close(fds[1]);
 288:	40c8                	lw	a0,4(s1)
 28a:	41c000ef          	jal	ra,6a6 <close>
  for (int i = 0; i < 4; i++) {
 28e:	fd842783          	lw	a5,-40(s0)
 292:	2785                	addiw	a5,a5,1
 294:	0007871b          	sext.w	a4,a5
 298:	fcf42c23          	sw	a5,-40(s0)
 29c:	fce951e3          	bge	s2,a4,25e <filetest+0x32>
  }

  // 等待所有子进程结束
  int xstatus = 0;
 2a0:	fc042e23          	sw	zero,-36(s0)
 2a4:	4491                	li	s1,4
  for (int i = 0; i < 4; i++) {
    wait(&xstatus);
 2a6:	fdc40513          	addi	a0,s0,-36
 2aa:	3dc000ef          	jal	ra,686 <wait>
    if (xstatus != 0) {
 2ae:	fdc42783          	lw	a5,-36(s0)
 2b2:	0c079463          	bnez	a5,37a <filetest+0x14e>
  for (int i = 0; i < 4; i++) {
 2b6:	34fd                	addiw	s1,s1,-1
 2b8:	f4fd                	bnez	s1,2a6 <filetest+0x7a>
    }
  }

  // 关键检查：父进程的 buf[0] 应仍为 99
  // 如果 COW 未在 copyout() 中处理，子进程的 read() 会直接修改父进程的页！
  if (buf[0] != 99) {
 2ba:	00002717          	auipc	a4,0x2
 2be:	d5674703          	lbu	a4,-682(a4) # 2010 <buf>
 2c2:	06300793          	li	a5,99
 2c6:	0af71d63          	bne	a4,a5,380 <filetest+0x154>
    printf("error: child overwrote parent\n");
    exit(1);
  }

  printf("ok\n");
 2ca:	00001517          	auipc	a0,0x1
 2ce:	9c650513          	addi	a0,a0,-1594 # c90 <malloc+0x134>
 2d2:	7d0000ef          	jal	ra,aa2 <printf>
}
 2d6:	70a2                	ld	ra,40(sp)
 2d8:	7402                	ld	s0,32(sp)
 2da:	64e2                	ld	s1,24(sp)
 2dc:	6942                	ld	s2,16(sp)
 2de:	6145                	addi	sp,sp,48
 2e0:	8082                	ret
      printf("pipe() failed\n");
 2e2:	00001517          	auipc	a0,0x1
 2e6:	9f650513          	addi	a0,a0,-1546 # cd8 <malloc+0x17c>
 2ea:	7b8000ef          	jal	ra,aa2 <printf>
      exit(-1);
 2ee:	557d                	li	a0,-1
 2f0:	38e000ef          	jal	ra,67e <exit>
      printf("fork failed\n");
 2f4:	00001517          	auipc	a0,0x1
 2f8:	9ac50513          	addi	a0,a0,-1620 # ca0 <malloc+0x144>
 2fc:	7a6000ef          	jal	ra,aa2 <printf>
      exit(-1);
 300:	557d                	li	a0,-1
 302:	37c000ef          	jal	ra,67e <exit>
      pause(1);  // 确保父进程先 write
 306:	4505                	li	a0,1
 308:	406000ef          	jal	ra,70e <pause>
      if (read(fds[0], buf, sizeof(i)) != sizeof(i)) {
 30c:	4611                	li	a2,4
 30e:	00002597          	auipc	a1,0x2
 312:	d0258593          	addi	a1,a1,-766 # 2010 <buf>
 316:	00001517          	auipc	a0,0x1
 31a:	cea52503          	lw	a0,-790(a0) # 1000 <fds>
 31e:	378000ef          	jal	ra,696 <read>
 322:	4791                	li	a5,4
 324:	02f51663          	bne	a0,a5,350 <filetest+0x124>
      pause(1);
 328:	4505                	li	a0,1
 32a:	3e4000ef          	jal	ra,70e <pause>
      if (j != i) {
 32e:	fd842703          	lw	a4,-40(s0)
 332:	00002797          	auipc	a5,0x2
 336:	cde7a783          	lw	a5,-802(a5) # 2010 <buf>
 33a:	02f70463          	beq	a4,a5,362 <filetest+0x136>
        printf("error: read the wrong value\n");
 33e:	00001517          	auipc	a0,0x1
 342:	9c250513          	addi	a0,a0,-1598 # d00 <malloc+0x1a4>
 346:	75c000ef          	jal	ra,aa2 <printf>
        exit(1);
 34a:	4505                	li	a0,1
 34c:	332000ef          	jal	ra,67e <exit>
        printf("error: read failed\n");
 350:	00001517          	auipc	a0,0x1
 354:	99850513          	addi	a0,a0,-1640 # ce8 <malloc+0x18c>
 358:	74a000ef          	jal	ra,aa2 <printf>
        exit(1);
 35c:	4505                	li	a0,1
 35e:	320000ef          	jal	ra,67e <exit>
      exit(0);
 362:	4501                	li	a0,0
 364:	31a000ef          	jal	ra,67e <exit>
      printf("error: write failed\n");
 368:	00001517          	auipc	a0,0x1
 36c:	9b850513          	addi	a0,a0,-1608 # d20 <malloc+0x1c4>
 370:	732000ef          	jal	ra,aa2 <printf>
      exit(-1);
 374:	557d                	li	a0,-1
 376:	308000ef          	jal	ra,67e <exit>
      exit(1);
 37a:	4505                	li	a0,1
 37c:	302000ef          	jal	ra,67e <exit>
    printf("error: child overwrote parent\n");
 380:	00001517          	auipc	a0,0x1
 384:	9b850513          	addi	a0,a0,-1608 # d38 <malloc+0x1dc>
 388:	71a000ef          	jal	ra,aa2 <printf>
    exit(1);
 38c:	4505                	li	a0,1
 38e:	2f0000ef          	jal	ra,67e <exit>

0000000000000392 <main>:

// 主函数：按顺序运行所有测试
int main(int argc, char *argv[]) {
 392:	1141                	addi	sp,sp,-16
 394:	e406                	sd	ra,8(sp)
 396:	e022                	sd	s0,0(sp)
 398:	0800                	addi	s0,sp,16
  printf("section 1:\n");
 39a:	00001517          	auipc	a0,0x1
 39e:	9be50513          	addi	a0,a0,-1602 # d58 <malloc+0x1fc>
 3a2:	700000ef          	jal	ra,aa2 <printf>
  simpletest();  // 第一次大内存测试
 3a6:	c5bff0ef          	jal	ra,0 <simpletest>

  printf("section 2:\n");
 3aa:	00001517          	auipc	a0,0x1
 3ae:	9be50513          	addi	a0,a0,-1602 # d68 <malloc+0x20c>
 3b2:	6f0000ef          	jal	ra,aa2 <printf>
  // 再次运行 simpletest，验证第一次测试释放的内存确实被回收了
  // 如果 COW 页未正确释放，第二次可能失败
  simpletest();
 3b6:	c4bff0ef          	jal	ra,0 <simpletest>

  printf("section 3:\n");
 3ba:	00001517          	auipc	a0,0x1
 3be:	9be50513          	addi	a0,a0,-1602 # d78 <malloc+0x21c>
 3c2:	6e0000ef          	jal	ra,aa2 <printf>
  // 连续三次运行 threetest，进一步压力测试内存分配与回收
  threetest();
 3c6:	d03ff0ef          	jal	ra,c8 <threetest>
  threetest();
 3ca:	cffff0ef          	jal	ra,c8 <threetest>
  threetest();
 3ce:	cfbff0ef          	jal	ra,c8 <threetest>

  // 测试系统调用路径下的 COW 行为
  filetest();
 3d2:	e5bff0ef          	jal	ra,22c <filetest>

  printf("ALL COW TESTS PASSED\n");
 3d6:	00001517          	auipc	a0,0x1
 3da:	9b250513          	addi	a0,a0,-1614 # d88 <malloc+0x22c>
 3de:	6c4000ef          	jal	ra,aa2 <printf>
  exit(0);
 3e2:	4501                	li	a0,0
 3e4:	29a000ef          	jal	ra,67e <exit>

00000000000003e8 <start>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
start(int argc, char **argv)
{
 3e8:	1141                	addi	sp,sp,-16
 3ea:	e406                	sd	ra,8(sp)
 3ec:	e022                	sd	s0,0(sp)
 3ee:	0800                	addi	s0,sp,16
  int r;
  extern int main(int argc, char **argv);
  r = main(argc, argv);
 3f0:	fa3ff0ef          	jal	ra,392 <main>
  exit(r);
 3f4:	28a000ef          	jal	ra,67e <exit>

00000000000003f8 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 3f8:	1141                	addi	sp,sp,-16
 3fa:	e422                	sd	s0,8(sp)
 3fc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 3fe:	87aa                	mv	a5,a0
 400:	0585                	addi	a1,a1,1
 402:	0785                	addi	a5,a5,1
 404:	fff5c703          	lbu	a4,-1(a1)
 408:	fee78fa3          	sb	a4,-1(a5)
 40c:	fb75                	bnez	a4,400 <strcpy+0x8>
    ;
  return os;
}
 40e:	6422                	ld	s0,8(sp)
 410:	0141                	addi	sp,sp,16
 412:	8082                	ret

0000000000000414 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 414:	1141                	addi	sp,sp,-16
 416:	e422                	sd	s0,8(sp)
 418:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 41a:	00054783          	lbu	a5,0(a0)
 41e:	cb91                	beqz	a5,432 <strcmp+0x1e>
 420:	0005c703          	lbu	a4,0(a1)
 424:	00f71763          	bne	a4,a5,432 <strcmp+0x1e>
    p++, q++;
 428:	0505                	addi	a0,a0,1
 42a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 42c:	00054783          	lbu	a5,0(a0)
 430:	fbe5                	bnez	a5,420 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 432:	0005c503          	lbu	a0,0(a1)
}
 436:	40a7853b          	subw	a0,a5,a0
 43a:	6422                	ld	s0,8(sp)
 43c:	0141                	addi	sp,sp,16
 43e:	8082                	ret

0000000000000440 <strlen>:

uint
strlen(const char *s)
{
 440:	1141                	addi	sp,sp,-16
 442:	e422                	sd	s0,8(sp)
 444:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 446:	00054783          	lbu	a5,0(a0)
 44a:	cf91                	beqz	a5,466 <strlen+0x26>
 44c:	0505                	addi	a0,a0,1
 44e:	87aa                	mv	a5,a0
 450:	4685                	li	a3,1
 452:	9e89                	subw	a3,a3,a0
 454:	00f6853b          	addw	a0,a3,a5
 458:	0785                	addi	a5,a5,1
 45a:	fff7c703          	lbu	a4,-1(a5)
 45e:	fb7d                	bnez	a4,454 <strlen+0x14>
    ;
  return n;
}
 460:	6422                	ld	s0,8(sp)
 462:	0141                	addi	sp,sp,16
 464:	8082                	ret
  for(n = 0; s[n]; n++)
 466:	4501                	li	a0,0
 468:	bfe5                	j	460 <strlen+0x20>

000000000000046a <memset>:

void*
memset(void *dst, int c, uint n)
{
 46a:	1141                	addi	sp,sp,-16
 46c:	e422                	sd	s0,8(sp)
 46e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 470:	ca19                	beqz	a2,486 <memset+0x1c>
 472:	87aa                	mv	a5,a0
 474:	1602                	slli	a2,a2,0x20
 476:	9201                	srli	a2,a2,0x20
 478:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 47c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 480:	0785                	addi	a5,a5,1
 482:	fee79de3          	bne	a5,a4,47c <memset+0x12>
  }
  return dst;
}
 486:	6422                	ld	s0,8(sp)
 488:	0141                	addi	sp,sp,16
 48a:	8082                	ret

000000000000048c <strchr>:

char*
strchr(const char *s, char c)
{
 48c:	1141                	addi	sp,sp,-16
 48e:	e422                	sd	s0,8(sp)
 490:	0800                	addi	s0,sp,16
  for(; *s; s++)
 492:	00054783          	lbu	a5,0(a0)
 496:	cb99                	beqz	a5,4ac <strchr+0x20>
    if(*s == c)
 498:	00f58763          	beq	a1,a5,4a6 <strchr+0x1a>
  for(; *s; s++)
 49c:	0505                	addi	a0,a0,1
 49e:	00054783          	lbu	a5,0(a0)
 4a2:	fbfd                	bnez	a5,498 <strchr+0xc>
      return (char*)s;
  return 0;
 4a4:	4501                	li	a0,0
}
 4a6:	6422                	ld	s0,8(sp)
 4a8:	0141                	addi	sp,sp,16
 4aa:	8082                	ret
  return 0;
 4ac:	4501                	li	a0,0
 4ae:	bfe5                	j	4a6 <strchr+0x1a>

00000000000004b0 <gets>:

char*
gets(char *buf, int max)
{
 4b0:	711d                	addi	sp,sp,-96
 4b2:	ec86                	sd	ra,88(sp)
 4b4:	e8a2                	sd	s0,80(sp)
 4b6:	e4a6                	sd	s1,72(sp)
 4b8:	e0ca                	sd	s2,64(sp)
 4ba:	fc4e                	sd	s3,56(sp)
 4bc:	f852                	sd	s4,48(sp)
 4be:	f456                	sd	s5,40(sp)
 4c0:	f05a                	sd	s6,32(sp)
 4c2:	ec5e                	sd	s7,24(sp)
 4c4:	1080                	addi	s0,sp,96
 4c6:	8baa                	mv	s7,a0
 4c8:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 4ca:	892a                	mv	s2,a0
 4cc:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 4ce:	4aa9                	li	s5,10
 4d0:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 4d2:	89a6                	mv	s3,s1
 4d4:	2485                	addiw	s1,s1,1
 4d6:	0344d663          	bge	s1,s4,502 <gets+0x52>
    cc = read(0, &c, 1);
 4da:	4605                	li	a2,1
 4dc:	faf40593          	addi	a1,s0,-81
 4e0:	4501                	li	a0,0
 4e2:	1b4000ef          	jal	ra,696 <read>
    if(cc < 1)
 4e6:	00a05e63          	blez	a0,502 <gets+0x52>
    buf[i++] = c;
 4ea:	faf44783          	lbu	a5,-81(s0)
 4ee:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 4f2:	01578763          	beq	a5,s5,500 <gets+0x50>
 4f6:	0905                	addi	s2,s2,1
 4f8:	fd679de3          	bne	a5,s6,4d2 <gets+0x22>
  for(i=0; i+1 < max; ){
 4fc:	89a6                	mv	s3,s1
 4fe:	a011                	j	502 <gets+0x52>
 500:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 502:	99de                	add	s3,s3,s7
 504:	00098023          	sb	zero,0(s3) # 199a000 <base+0x1994ff0>
  return buf;
}
 508:	855e                	mv	a0,s7
 50a:	60e6                	ld	ra,88(sp)
 50c:	6446                	ld	s0,80(sp)
 50e:	64a6                	ld	s1,72(sp)
 510:	6906                	ld	s2,64(sp)
 512:	79e2                	ld	s3,56(sp)
 514:	7a42                	ld	s4,48(sp)
 516:	7aa2                	ld	s5,40(sp)
 518:	7b02                	ld	s6,32(sp)
 51a:	6be2                	ld	s7,24(sp)
 51c:	6125                	addi	sp,sp,96
 51e:	8082                	ret

0000000000000520 <stat>:

int
stat(const char *n, struct stat *st)
{
 520:	1101                	addi	sp,sp,-32
 522:	ec06                	sd	ra,24(sp)
 524:	e822                	sd	s0,16(sp)
 526:	e426                	sd	s1,8(sp)
 528:	e04a                	sd	s2,0(sp)
 52a:	1000                	addi	s0,sp,32
 52c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 52e:	4581                	li	a1,0
 530:	18e000ef          	jal	ra,6be <open>
  if(fd < 0)
 534:	02054163          	bltz	a0,556 <stat+0x36>
 538:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 53a:	85ca                	mv	a1,s2
 53c:	19a000ef          	jal	ra,6d6 <fstat>
 540:	892a                	mv	s2,a0
  close(fd);
 542:	8526                	mv	a0,s1
 544:	162000ef          	jal	ra,6a6 <close>
  return r;
}
 548:	854a                	mv	a0,s2
 54a:	60e2                	ld	ra,24(sp)
 54c:	6442                	ld	s0,16(sp)
 54e:	64a2                	ld	s1,8(sp)
 550:	6902                	ld	s2,0(sp)
 552:	6105                	addi	sp,sp,32
 554:	8082                	ret
    return -1;
 556:	597d                	li	s2,-1
 558:	bfc5                	j	548 <stat+0x28>

000000000000055a <atoi>:

int
atoi(const char *s)
{
 55a:	1141                	addi	sp,sp,-16
 55c:	e422                	sd	s0,8(sp)
 55e:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 560:	00054603          	lbu	a2,0(a0)
 564:	fd06079b          	addiw	a5,a2,-48
 568:	0ff7f793          	andi	a5,a5,255
 56c:	4725                	li	a4,9
 56e:	02f76963          	bltu	a4,a5,5a0 <atoi+0x46>
 572:	86aa                	mv	a3,a0
  n = 0;
 574:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 576:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 578:	0685                	addi	a3,a3,1
 57a:	0025179b          	slliw	a5,a0,0x2
 57e:	9fa9                	addw	a5,a5,a0
 580:	0017979b          	slliw	a5,a5,0x1
 584:	9fb1                	addw	a5,a5,a2
 586:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 58a:	0006c603          	lbu	a2,0(a3) # 1000 <fds>
 58e:	fd06071b          	addiw	a4,a2,-48
 592:	0ff77713          	andi	a4,a4,255
 596:	fee5f1e3          	bgeu	a1,a4,578 <atoi+0x1e>
  return n;
}
 59a:	6422                	ld	s0,8(sp)
 59c:	0141                	addi	sp,sp,16
 59e:	8082                	ret
  n = 0;
 5a0:	4501                	li	a0,0
 5a2:	bfe5                	j	59a <atoi+0x40>

00000000000005a4 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 5a4:	1141                	addi	sp,sp,-16
 5a6:	e422                	sd	s0,8(sp)
 5a8:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 5aa:	02b57463          	bgeu	a0,a1,5d2 <memmove+0x2e>
    while(n-- > 0)
 5ae:	00c05f63          	blez	a2,5cc <memmove+0x28>
 5b2:	1602                	slli	a2,a2,0x20
 5b4:	9201                	srli	a2,a2,0x20
 5b6:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 5ba:	872a                	mv	a4,a0
      *dst++ = *src++;
 5bc:	0585                	addi	a1,a1,1
 5be:	0705                	addi	a4,a4,1
 5c0:	fff5c683          	lbu	a3,-1(a1)
 5c4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 5c8:	fee79ae3          	bne	a5,a4,5bc <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 5cc:	6422                	ld	s0,8(sp)
 5ce:	0141                	addi	sp,sp,16
 5d0:	8082                	ret
    dst += n;
 5d2:	00c50733          	add	a4,a0,a2
    src += n;
 5d6:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 5d8:	fec05ae3          	blez	a2,5cc <memmove+0x28>
 5dc:	fff6079b          	addiw	a5,a2,-1
 5e0:	1782                	slli	a5,a5,0x20
 5e2:	9381                	srli	a5,a5,0x20
 5e4:	fff7c793          	not	a5,a5
 5e8:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 5ea:	15fd                	addi	a1,a1,-1
 5ec:	177d                	addi	a4,a4,-1
 5ee:	0005c683          	lbu	a3,0(a1)
 5f2:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 5f6:	fee79ae3          	bne	a5,a4,5ea <memmove+0x46>
 5fa:	bfc9                	j	5cc <memmove+0x28>

00000000000005fc <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 5fc:	1141                	addi	sp,sp,-16
 5fe:	e422                	sd	s0,8(sp)
 600:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 602:	ca05                	beqz	a2,632 <memcmp+0x36>
 604:	fff6069b          	addiw	a3,a2,-1
 608:	1682                	slli	a3,a3,0x20
 60a:	9281                	srli	a3,a3,0x20
 60c:	0685                	addi	a3,a3,1
 60e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 610:	00054783          	lbu	a5,0(a0)
 614:	0005c703          	lbu	a4,0(a1)
 618:	00e79863          	bne	a5,a4,628 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 61c:	0505                	addi	a0,a0,1
    p2++;
 61e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 620:	fed518e3          	bne	a0,a3,610 <memcmp+0x14>
  }
  return 0;
 624:	4501                	li	a0,0
 626:	a019                	j	62c <memcmp+0x30>
      return *p1 - *p2;
 628:	40e7853b          	subw	a0,a5,a4
}
 62c:	6422                	ld	s0,8(sp)
 62e:	0141                	addi	sp,sp,16
 630:	8082                	ret
  return 0;
 632:	4501                	li	a0,0
 634:	bfe5                	j	62c <memcmp+0x30>

0000000000000636 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 636:	1141                	addi	sp,sp,-16
 638:	e406                	sd	ra,8(sp)
 63a:	e022                	sd	s0,0(sp)
 63c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 63e:	f67ff0ef          	jal	ra,5a4 <memmove>
}
 642:	60a2                	ld	ra,8(sp)
 644:	6402                	ld	s0,0(sp)
 646:	0141                	addi	sp,sp,16
 648:	8082                	ret

000000000000064a <sbrk>:

char *
sbrk(int n) {
 64a:	1141                	addi	sp,sp,-16
 64c:	e406                	sd	ra,8(sp)
 64e:	e022                	sd	s0,0(sp)
 650:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_EAGER);
 652:	4585                	li	a1,1
 654:	0b2000ef          	jal	ra,706 <sys_sbrk>
}
 658:	60a2                	ld	ra,8(sp)
 65a:	6402                	ld	s0,0(sp)
 65c:	0141                	addi	sp,sp,16
 65e:	8082                	ret

0000000000000660 <sbrklazy>:

char *
sbrklazy(int n) {
 660:	1141                	addi	sp,sp,-16
 662:	e406                	sd	ra,8(sp)
 664:	e022                	sd	s0,0(sp)
 666:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_LAZY);
 668:	4589                	li	a1,2
 66a:	09c000ef          	jal	ra,706 <sys_sbrk>
}
 66e:	60a2                	ld	ra,8(sp)
 670:	6402                	ld	s0,0(sp)
 672:	0141                	addi	sp,sp,16
 674:	8082                	ret

0000000000000676 <fork>:
# 由 usys.pl 生成 - 请勿编辑
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 676:	4885                	li	a7,1
 ecall
 678:	00000073          	ecall
 ret
 67c:	8082                	ret

000000000000067e <exit>:
.global exit
exit:
 li a7, SYS_exit
 67e:	4889                	li	a7,2
 ecall
 680:	00000073          	ecall
 ret
 684:	8082                	ret

0000000000000686 <wait>:
.global wait
wait:
 li a7, SYS_wait
 686:	488d                	li	a7,3
 ecall
 688:	00000073          	ecall
 ret
 68c:	8082                	ret

000000000000068e <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 68e:	4891                	li	a7,4
 ecall
 690:	00000073          	ecall
 ret
 694:	8082                	ret

0000000000000696 <read>:
.global read
read:
 li a7, SYS_read
 696:	4895                	li	a7,5
 ecall
 698:	00000073          	ecall
 ret
 69c:	8082                	ret

000000000000069e <write>:
.global write
write:
 li a7, SYS_write
 69e:	48c1                	li	a7,16
 ecall
 6a0:	00000073          	ecall
 ret
 6a4:	8082                	ret

00000000000006a6 <close>:
.global close
close:
 li a7, SYS_close
 6a6:	48d5                	li	a7,21
 ecall
 6a8:	00000073          	ecall
 ret
 6ac:	8082                	ret

00000000000006ae <kill>:
.global kill
kill:
 li a7, SYS_kill
 6ae:	4899                	li	a7,6
 ecall
 6b0:	00000073          	ecall
 ret
 6b4:	8082                	ret

00000000000006b6 <exec>:
.global exec
exec:
 li a7, SYS_exec
 6b6:	489d                	li	a7,7
 ecall
 6b8:	00000073          	ecall
 ret
 6bc:	8082                	ret

00000000000006be <open>:
.global open
open:
 li a7, SYS_open
 6be:	48bd                	li	a7,15
 ecall
 6c0:	00000073          	ecall
 ret
 6c4:	8082                	ret

00000000000006c6 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 6c6:	48c5                	li	a7,17
 ecall
 6c8:	00000073          	ecall
 ret
 6cc:	8082                	ret

00000000000006ce <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 6ce:	48c9                	li	a7,18
 ecall
 6d0:	00000073          	ecall
 ret
 6d4:	8082                	ret

00000000000006d6 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 6d6:	48a1                	li	a7,8
 ecall
 6d8:	00000073          	ecall
 ret
 6dc:	8082                	ret

00000000000006de <link>:
.global link
link:
 li a7, SYS_link
 6de:	48cd                	li	a7,19
 ecall
 6e0:	00000073          	ecall
 ret
 6e4:	8082                	ret

00000000000006e6 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 6e6:	48d1                	li	a7,20
 ecall
 6e8:	00000073          	ecall
 ret
 6ec:	8082                	ret

00000000000006ee <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 6ee:	48a5                	li	a7,9
 ecall
 6f0:	00000073          	ecall
 ret
 6f4:	8082                	ret

00000000000006f6 <dup>:
.global dup
dup:
 li a7, SYS_dup
 6f6:	48a9                	li	a7,10
 ecall
 6f8:	00000073          	ecall
 ret
 6fc:	8082                	ret

00000000000006fe <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 6fe:	48ad                	li	a7,11
 ecall
 700:	00000073          	ecall
 ret
 704:	8082                	ret

0000000000000706 <sys_sbrk>:
.global sys_sbrk
sys_sbrk:
 li a7, SYS_sbrk
 706:	48b1                	li	a7,12
 ecall
 708:	00000073          	ecall
 ret
 70c:	8082                	ret

000000000000070e <pause>:
.global pause
pause:
 li a7, SYS_pause
 70e:	48b5                	li	a7,13
 ecall
 710:	00000073          	ecall
 ret
 714:	8082                	ret

0000000000000716 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 716:	48b9                	li	a7,14
 ecall
 718:	00000073          	ecall
 ret
 71c:	8082                	ret

000000000000071e <dump_proc>:
.global dump_proc
dump_proc:
 li a7, SYS_dump_proc
 71e:	48d9                	li	a7,22
 ecall
 720:	00000073          	ecall
 ret
 724:	8082                	ret

0000000000000726 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 726:	1101                	addi	sp,sp,-32
 728:	ec06                	sd	ra,24(sp)
 72a:	e822                	sd	s0,16(sp)
 72c:	1000                	addi	s0,sp,32
 72e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 732:	4605                	li	a2,1
 734:	fef40593          	addi	a1,s0,-17
 738:	f67ff0ef          	jal	ra,69e <write>
}
 73c:	60e2                	ld	ra,24(sp)
 73e:	6442                	ld	s0,16(sp)
 740:	6105                	addi	sp,sp,32
 742:	8082                	ret

0000000000000744 <printint>:

static void
printint(int fd, long long xx, int base, int sgn)
{
 744:	715d                	addi	sp,sp,-80
 746:	e486                	sd	ra,72(sp)
 748:	e0a2                	sd	s0,64(sp)
 74a:	fc26                	sd	s1,56(sp)
 74c:	f84a                	sd	s2,48(sp)
 74e:	f44e                	sd	s3,40(sp)
 750:	0880                	addi	s0,sp,80
 752:	892a                	mv	s2,a0
  char buf[20];
  int i, neg;
  unsigned long long x;

  neg = 0;
  if(sgn && xx < 0){
 754:	c299                	beqz	a3,75a <printint+0x16>
 756:	0805c163          	bltz	a1,7d8 <printint+0x94>
  neg = 0;
 75a:	4881                	li	a7,0
 75c:	fb840693          	addi	a3,s0,-72
    x = -xx;
  } else {
    x = xx;
  }

  i = 0;
 760:	4781                	li	a5,0
  do{
    buf[i++] = digits[x % base];
 762:	00000517          	auipc	a0,0x0
 766:	64650513          	addi	a0,a0,1606 # da8 <digits>
 76a:	883e                	mv	a6,a5
 76c:	2785                	addiw	a5,a5,1
 76e:	02c5f733          	remu	a4,a1,a2
 772:	972a                	add	a4,a4,a0
 774:	00074703          	lbu	a4,0(a4)
 778:	00e68023          	sb	a4,0(a3)
  }while((x /= base) != 0);
 77c:	872e                	mv	a4,a1
 77e:	02c5d5b3          	divu	a1,a1,a2
 782:	0685                	addi	a3,a3,1
 784:	fec773e3          	bgeu	a4,a2,76a <printint+0x26>
  if(neg)
 788:	00088b63          	beqz	a7,79e <printint+0x5a>
    buf[i++] = '-';
 78c:	fd040713          	addi	a4,s0,-48
 790:	97ba                	add	a5,a5,a4
 792:	02d00713          	li	a4,45
 796:	fee78423          	sb	a4,-24(a5)
 79a:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
 79e:	02f05663          	blez	a5,7ca <printint+0x86>
 7a2:	fb840713          	addi	a4,s0,-72
 7a6:	00f704b3          	add	s1,a4,a5
 7aa:	fff70993          	addi	s3,a4,-1
 7ae:	99be                	add	s3,s3,a5
 7b0:	37fd                	addiw	a5,a5,-1
 7b2:	1782                	slli	a5,a5,0x20
 7b4:	9381                	srli	a5,a5,0x20
 7b6:	40f989b3          	sub	s3,s3,a5
    putc(fd, buf[i]);
 7ba:	fff4c583          	lbu	a1,-1(s1)
 7be:	854a                	mv	a0,s2
 7c0:	f67ff0ef          	jal	ra,726 <putc>
  while(--i >= 0)
 7c4:	14fd                	addi	s1,s1,-1
 7c6:	ff349ae3          	bne	s1,s3,7ba <printint+0x76>
}
 7ca:	60a6                	ld	ra,72(sp)
 7cc:	6406                	ld	s0,64(sp)
 7ce:	74e2                	ld	s1,56(sp)
 7d0:	7942                	ld	s2,48(sp)
 7d2:	79a2                	ld	s3,40(sp)
 7d4:	6161                	addi	sp,sp,80
 7d6:	8082                	ret
    x = -xx;
 7d8:	40b005b3          	neg	a1,a1
    neg = 1;
 7dc:	4885                	li	a7,1
    x = -xx;
 7de:	bfbd                	j	75c <printint+0x18>

00000000000007e0 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %c, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 7e0:	7119                	addi	sp,sp,-128
 7e2:	fc86                	sd	ra,120(sp)
 7e4:	f8a2                	sd	s0,112(sp)
 7e6:	f4a6                	sd	s1,104(sp)
 7e8:	f0ca                	sd	s2,96(sp)
 7ea:	ecce                	sd	s3,88(sp)
 7ec:	e8d2                	sd	s4,80(sp)
 7ee:	e4d6                	sd	s5,72(sp)
 7f0:	e0da                	sd	s6,64(sp)
 7f2:	fc5e                	sd	s7,56(sp)
 7f4:	f862                	sd	s8,48(sp)
 7f6:	f466                	sd	s9,40(sp)
 7f8:	f06a                	sd	s10,32(sp)
 7fa:	ec6e                	sd	s11,24(sp)
 7fc:	0100                	addi	s0,sp,128
  char *s;
  int c0, c1, c2, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 7fe:	0005c903          	lbu	s2,0(a1)
 802:	24090c63          	beqz	s2,a5a <vprintf+0x27a>
 806:	8b2a                	mv	s6,a0
 808:	8a2e                	mv	s4,a1
 80a:	8bb2                	mv	s7,a2
  state = 0;
 80c:	4981                	li	s3,0
  for(i = 0; fmt[i]; i++){
 80e:	4481                	li	s1,0
 810:	4701                	li	a4,0
      if(c0 == '%'){
        state = '%';
      } else {
        putc(fd, c0);
      }
    } else if(state == '%'){
 812:	02500a93          	li	s5,37
      c1 = c2 = 0;
      if(c0) c1 = fmt[i+1] & 0xff;
      if(c1) c2 = fmt[i+2] & 0xff;
      if(c0 == 'd'){
 816:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c0 == 'l' && c1 == 'd'){
 81a:	06c00d13          	li	s10,108
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 2;
      } else if(c0 == 'u'){
 81e:	07500d93          	li	s11,117
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 822:	00000c97          	auipc	s9,0x0
 826:	586c8c93          	addi	s9,s9,1414 # da8 <digits>
 82a:	a005                	j	84a <vprintf+0x6a>
        putc(fd, c0);
 82c:	85ca                	mv	a1,s2
 82e:	855a                	mv	a0,s6
 830:	ef7ff0ef          	jal	ra,726 <putc>
 834:	a019                	j	83a <vprintf+0x5a>
    } else if(state == '%'){
 836:	03598263          	beq	s3,s5,85a <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 83a:	2485                	addiw	s1,s1,1
 83c:	8726                	mv	a4,s1
 83e:	009a07b3          	add	a5,s4,s1
 842:	0007c903          	lbu	s2,0(a5)
 846:	20090a63          	beqz	s2,a5a <vprintf+0x27a>
    c0 = fmt[i] & 0xff;
 84a:	0009079b          	sext.w	a5,s2
    if(state == 0){
 84e:	fe0994e3          	bnez	s3,836 <vprintf+0x56>
      if(c0 == '%'){
 852:	fd579de3          	bne	a5,s5,82c <vprintf+0x4c>
        state = '%';
 856:	89be                	mv	s3,a5
 858:	b7cd                	j	83a <vprintf+0x5a>
      if(c0) c1 = fmt[i+1] & 0xff;
 85a:	c3c1                	beqz	a5,8da <vprintf+0xfa>
 85c:	00ea06b3          	add	a3,s4,a4
 860:	0016c683          	lbu	a3,1(a3)
      c1 = c2 = 0;
 864:	8636                	mv	a2,a3
      if(c1) c2 = fmt[i+2] & 0xff;
 866:	c681                	beqz	a3,86e <vprintf+0x8e>
 868:	9752                	add	a4,a4,s4
 86a:	00274603          	lbu	a2,2(a4)
      if(c0 == 'd'){
 86e:	03878e63          	beq	a5,s8,8aa <vprintf+0xca>
      } else if(c0 == 'l' && c1 == 'd'){
 872:	05a78863          	beq	a5,s10,8c2 <vprintf+0xe2>
      } else if(c0 == 'u'){
 876:	0db78b63          	beq	a5,s11,94c <vprintf+0x16c>
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 2;
      } else if(c0 == 'x'){
 87a:	07800713          	li	a4,120
 87e:	10e78d63          	beq	a5,a4,998 <vprintf+0x1b8>
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 2;
      } else if(c0 == 'p'){
 882:	07000713          	li	a4,112
 886:	14e78263          	beq	a5,a4,9ca <vprintf+0x1ea>
        printptr(fd, va_arg(ap, uint64));
      } else if(c0 == 'c'){
 88a:	06300713          	li	a4,99
 88e:	16e78f63          	beq	a5,a4,a0c <vprintf+0x22c>
        putc(fd, va_arg(ap, uint32));
      } else if(c0 == 's'){
 892:	07300713          	li	a4,115
 896:	18e78563          	beq	a5,a4,a20 <vprintf+0x240>
        if((s = va_arg(ap, char*)) == 0)
          s = "(null)";
        for(; *s; s++)
          putc(fd, *s);
      } else if(c0 == '%'){
 89a:	05579063          	bne	a5,s5,8da <vprintf+0xfa>
        putc(fd, '%');
 89e:	85d6                	mv	a1,s5
 8a0:	855a                	mv	a0,s6
 8a2:	e85ff0ef          	jal	ra,726 <putc>
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c0);
      }

      state = 0;
 8a6:	4981                	li	s3,0
 8a8:	bf49                	j	83a <vprintf+0x5a>
        printint(fd, va_arg(ap, int), 10, 1);
 8aa:	008b8913          	addi	s2,s7,8
 8ae:	4685                	li	a3,1
 8b0:	4629                	li	a2,10
 8b2:	000ba583          	lw	a1,0(s7)
 8b6:	855a                	mv	a0,s6
 8b8:	e8dff0ef          	jal	ra,744 <printint>
 8bc:	8bca                	mv	s7,s2
      state = 0;
 8be:	4981                	li	s3,0
 8c0:	bfad                	j	83a <vprintf+0x5a>
      } else if(c0 == 'l' && c1 == 'd'){
 8c2:	03868663          	beq	a3,s8,8ee <vprintf+0x10e>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 8c6:	05a68163          	beq	a3,s10,908 <vprintf+0x128>
      } else if(c0 == 'l' && c1 == 'u'){
 8ca:	09b68d63          	beq	a3,s11,964 <vprintf+0x184>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 8ce:	03a68f63          	beq	a3,s10,90c <vprintf+0x12c>
      } else if(c0 == 'l' && c1 == 'x'){
 8d2:	07800793          	li	a5,120
 8d6:	0cf68d63          	beq	a3,a5,9b0 <vprintf+0x1d0>
        putc(fd, '%');
 8da:	85d6                	mv	a1,s5
 8dc:	855a                	mv	a0,s6
 8de:	e49ff0ef          	jal	ra,726 <putc>
        putc(fd, c0);
 8e2:	85ca                	mv	a1,s2
 8e4:	855a                	mv	a0,s6
 8e6:	e41ff0ef          	jal	ra,726 <putc>
      state = 0;
 8ea:	4981                	li	s3,0
 8ec:	b7b9                	j	83a <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 8ee:	008b8913          	addi	s2,s7,8
 8f2:	4685                	li	a3,1
 8f4:	4629                	li	a2,10
 8f6:	000bb583          	ld	a1,0(s7)
 8fa:	855a                	mv	a0,s6
 8fc:	e49ff0ef          	jal	ra,744 <printint>
        i += 1;
 900:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 1);
 902:	8bca                	mv	s7,s2
      state = 0;
 904:	4981                	li	s3,0
        i += 1;
 906:	bf15                	j	83a <vprintf+0x5a>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 908:	03860563          	beq	a2,s8,932 <vprintf+0x152>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 90c:	07b60963          	beq	a2,s11,97e <vprintf+0x19e>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
 910:	07800793          	li	a5,120
 914:	fcf613e3          	bne	a2,a5,8da <vprintf+0xfa>
        printint(fd, va_arg(ap, uint64), 16, 0);
 918:	008b8913          	addi	s2,s7,8
 91c:	4681                	li	a3,0
 91e:	4641                	li	a2,16
 920:	000bb583          	ld	a1,0(s7)
 924:	855a                	mv	a0,s6
 926:	e1fff0ef          	jal	ra,744 <printint>
        i += 2;
 92a:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 16, 0);
 92c:	8bca                	mv	s7,s2
      state = 0;
 92e:	4981                	li	s3,0
        i += 2;
 930:	b729                	j	83a <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 932:	008b8913          	addi	s2,s7,8
 936:	4685                	li	a3,1
 938:	4629                	li	a2,10
 93a:	000bb583          	ld	a1,0(s7)
 93e:	855a                	mv	a0,s6
 940:	e05ff0ef          	jal	ra,744 <printint>
        i += 2;
 944:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 1);
 946:	8bca                	mv	s7,s2
      state = 0;
 948:	4981                	li	s3,0
        i += 2;
 94a:	bdc5                	j	83a <vprintf+0x5a>
        printint(fd, va_arg(ap, uint32), 10, 0);
 94c:	008b8913          	addi	s2,s7,8
 950:	4681                	li	a3,0
 952:	4629                	li	a2,10
 954:	000be583          	lwu	a1,0(s7)
 958:	855a                	mv	a0,s6
 95a:	debff0ef          	jal	ra,744 <printint>
 95e:	8bca                	mv	s7,s2
      state = 0;
 960:	4981                	li	s3,0
 962:	bde1                	j	83a <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 964:	008b8913          	addi	s2,s7,8
 968:	4681                	li	a3,0
 96a:	4629                	li	a2,10
 96c:	000bb583          	ld	a1,0(s7)
 970:	855a                	mv	a0,s6
 972:	dd3ff0ef          	jal	ra,744 <printint>
        i += 1;
 976:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 0);
 978:	8bca                	mv	s7,s2
      state = 0;
 97a:	4981                	li	s3,0
        i += 1;
 97c:	bd7d                	j	83a <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 97e:	008b8913          	addi	s2,s7,8
 982:	4681                	li	a3,0
 984:	4629                	li	a2,10
 986:	000bb583          	ld	a1,0(s7)
 98a:	855a                	mv	a0,s6
 98c:	db9ff0ef          	jal	ra,744 <printint>
        i += 2;
 990:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 0);
 992:	8bca                	mv	s7,s2
      state = 0;
 994:	4981                	li	s3,0
        i += 2;
 996:	b555                	j	83a <vprintf+0x5a>
        printint(fd, va_arg(ap, uint32), 16, 0);
 998:	008b8913          	addi	s2,s7,8
 99c:	4681                	li	a3,0
 99e:	4641                	li	a2,16
 9a0:	000be583          	lwu	a1,0(s7)
 9a4:	855a                	mv	a0,s6
 9a6:	d9fff0ef          	jal	ra,744 <printint>
 9aa:	8bca                	mv	s7,s2
      state = 0;
 9ac:	4981                	li	s3,0
 9ae:	b571                	j	83a <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 16, 0);
 9b0:	008b8913          	addi	s2,s7,8
 9b4:	4681                	li	a3,0
 9b6:	4641                	li	a2,16
 9b8:	000bb583          	ld	a1,0(s7)
 9bc:	855a                	mv	a0,s6
 9be:	d87ff0ef          	jal	ra,744 <printint>
        i += 1;
 9c2:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 16, 0);
 9c4:	8bca                	mv	s7,s2
      state = 0;
 9c6:	4981                	li	s3,0
        i += 1;
 9c8:	bd8d                	j	83a <vprintf+0x5a>
        printptr(fd, va_arg(ap, uint64));
 9ca:	008b8793          	addi	a5,s7,8
 9ce:	f8f43423          	sd	a5,-120(s0)
 9d2:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 9d6:	03000593          	li	a1,48
 9da:	855a                	mv	a0,s6
 9dc:	d4bff0ef          	jal	ra,726 <putc>
  putc(fd, 'x');
 9e0:	07800593          	li	a1,120
 9e4:	855a                	mv	a0,s6
 9e6:	d41ff0ef          	jal	ra,726 <putc>
 9ea:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 9ec:	03c9d793          	srli	a5,s3,0x3c
 9f0:	97e6                	add	a5,a5,s9
 9f2:	0007c583          	lbu	a1,0(a5)
 9f6:	855a                	mv	a0,s6
 9f8:	d2fff0ef          	jal	ra,726 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 9fc:	0992                	slli	s3,s3,0x4
 9fe:	397d                	addiw	s2,s2,-1
 a00:	fe0916e3          	bnez	s2,9ec <vprintf+0x20c>
        printptr(fd, va_arg(ap, uint64));
 a04:	f8843b83          	ld	s7,-120(s0)
      state = 0;
 a08:	4981                	li	s3,0
 a0a:	bd05                	j	83a <vprintf+0x5a>
        putc(fd, va_arg(ap, uint32));
 a0c:	008b8913          	addi	s2,s7,8
 a10:	000bc583          	lbu	a1,0(s7)
 a14:	855a                	mv	a0,s6
 a16:	d11ff0ef          	jal	ra,726 <putc>
 a1a:	8bca                	mv	s7,s2
      state = 0;
 a1c:	4981                	li	s3,0
 a1e:	bd31                	j	83a <vprintf+0x5a>
        if((s = va_arg(ap, char*)) == 0)
 a20:	008b8993          	addi	s3,s7,8
 a24:	000bb903          	ld	s2,0(s7)
 a28:	00090f63          	beqz	s2,a46 <vprintf+0x266>
        for(; *s; s++)
 a2c:	00094583          	lbu	a1,0(s2)
 a30:	c195                	beqz	a1,a54 <vprintf+0x274>
          putc(fd, *s);
 a32:	855a                	mv	a0,s6
 a34:	cf3ff0ef          	jal	ra,726 <putc>
        for(; *s; s++)
 a38:	0905                	addi	s2,s2,1
 a3a:	00094583          	lbu	a1,0(s2)
 a3e:	f9f5                	bnez	a1,a32 <vprintf+0x252>
        if((s = va_arg(ap, char*)) == 0)
 a40:	8bce                	mv	s7,s3
      state = 0;
 a42:	4981                	li	s3,0
 a44:	bbdd                	j	83a <vprintf+0x5a>
          s = "(null)";
 a46:	00000917          	auipc	s2,0x0
 a4a:	35a90913          	addi	s2,s2,858 # da0 <malloc+0x244>
        for(; *s; s++)
 a4e:	02800593          	li	a1,40
 a52:	b7c5                	j	a32 <vprintf+0x252>
        if((s = va_arg(ap, char*)) == 0)
 a54:	8bce                	mv	s7,s3
      state = 0;
 a56:	4981                	li	s3,0
 a58:	b3cd                	j	83a <vprintf+0x5a>
    }
  }
}
 a5a:	70e6                	ld	ra,120(sp)
 a5c:	7446                	ld	s0,112(sp)
 a5e:	74a6                	ld	s1,104(sp)
 a60:	7906                	ld	s2,96(sp)
 a62:	69e6                	ld	s3,88(sp)
 a64:	6a46                	ld	s4,80(sp)
 a66:	6aa6                	ld	s5,72(sp)
 a68:	6b06                	ld	s6,64(sp)
 a6a:	7be2                	ld	s7,56(sp)
 a6c:	7c42                	ld	s8,48(sp)
 a6e:	7ca2                	ld	s9,40(sp)
 a70:	7d02                	ld	s10,32(sp)
 a72:	6de2                	ld	s11,24(sp)
 a74:	6109                	addi	sp,sp,128
 a76:	8082                	ret

0000000000000a78 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 a78:	715d                	addi	sp,sp,-80
 a7a:	ec06                	sd	ra,24(sp)
 a7c:	e822                	sd	s0,16(sp)
 a7e:	1000                	addi	s0,sp,32
 a80:	e010                	sd	a2,0(s0)
 a82:	e414                	sd	a3,8(s0)
 a84:	e818                	sd	a4,16(s0)
 a86:	ec1c                	sd	a5,24(s0)
 a88:	03043023          	sd	a6,32(s0)
 a8c:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 a90:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 a94:	8622                	mv	a2,s0
 a96:	d4bff0ef          	jal	ra,7e0 <vprintf>
}
 a9a:	60e2                	ld	ra,24(sp)
 a9c:	6442                	ld	s0,16(sp)
 a9e:	6161                	addi	sp,sp,80
 aa0:	8082                	ret

0000000000000aa2 <printf>:

void
printf(const char *fmt, ...)
{
 aa2:	711d                	addi	sp,sp,-96
 aa4:	ec06                	sd	ra,24(sp)
 aa6:	e822                	sd	s0,16(sp)
 aa8:	1000                	addi	s0,sp,32
 aaa:	e40c                	sd	a1,8(s0)
 aac:	e810                	sd	a2,16(s0)
 aae:	ec14                	sd	a3,24(s0)
 ab0:	f018                	sd	a4,32(s0)
 ab2:	f41c                	sd	a5,40(s0)
 ab4:	03043823          	sd	a6,48(s0)
 ab8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 abc:	00840613          	addi	a2,s0,8
 ac0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 ac4:	85aa                	mv	a1,a0
 ac6:	4505                	li	a0,1
 ac8:	d19ff0ef          	jal	ra,7e0 <vprintf>
}
 acc:	60e2                	ld	ra,24(sp)
 ace:	6442                	ld	s0,16(sp)
 ad0:	6125                	addi	sp,sp,96
 ad2:	8082                	ret

0000000000000ad4 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 ad4:	1141                	addi	sp,sp,-16
 ad6:	e422                	sd	s0,8(sp)
 ad8:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 ada:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 ade:	00000797          	auipc	a5,0x0
 ae2:	52a7b783          	ld	a5,1322(a5) # 1008 <freep>
 ae6:	a805                	j	b16 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 ae8:	4618                	lw	a4,8(a2)
 aea:	9db9                	addw	a1,a1,a4
 aec:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 af0:	6398                	ld	a4,0(a5)
 af2:	6318                	ld	a4,0(a4)
 af4:	fee53823          	sd	a4,-16(a0)
 af8:	a091                	j	b3c <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 afa:	ff852703          	lw	a4,-8(a0)
 afe:	9e39                	addw	a2,a2,a4
 b00:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 b02:	ff053703          	ld	a4,-16(a0)
 b06:	e398                	sd	a4,0(a5)
 b08:	a099                	j	b4e <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b0a:	6398                	ld	a4,0(a5)
 b0c:	00e7e463          	bltu	a5,a4,b14 <free+0x40>
 b10:	00e6ea63          	bltu	a3,a4,b24 <free+0x50>
{
 b14:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 b16:	fed7fae3          	bgeu	a5,a3,b0a <free+0x36>
 b1a:	6398                	ld	a4,0(a5)
 b1c:	00e6e463          	bltu	a3,a4,b24 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b20:	fee7eae3          	bltu	a5,a4,b14 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 b24:	ff852583          	lw	a1,-8(a0)
 b28:	6390                	ld	a2,0(a5)
 b2a:	02059713          	slli	a4,a1,0x20
 b2e:	9301                	srli	a4,a4,0x20
 b30:	0712                	slli	a4,a4,0x4
 b32:	9736                	add	a4,a4,a3
 b34:	fae60ae3          	beq	a2,a4,ae8 <free+0x14>
    bp->s.ptr = p->s.ptr;
 b38:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 b3c:	4790                	lw	a2,8(a5)
 b3e:	02061713          	slli	a4,a2,0x20
 b42:	9301                	srli	a4,a4,0x20
 b44:	0712                	slli	a4,a4,0x4
 b46:	973e                	add	a4,a4,a5
 b48:	fae689e3          	beq	a3,a4,afa <free+0x26>
  } else
    p->s.ptr = bp;
 b4c:	e394                	sd	a3,0(a5)
  freep = p;
 b4e:	00000717          	auipc	a4,0x0
 b52:	4af73d23          	sd	a5,1210(a4) # 1008 <freep>
}
 b56:	6422                	ld	s0,8(sp)
 b58:	0141                	addi	sp,sp,16
 b5a:	8082                	ret

0000000000000b5c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 b5c:	7139                	addi	sp,sp,-64
 b5e:	fc06                	sd	ra,56(sp)
 b60:	f822                	sd	s0,48(sp)
 b62:	f426                	sd	s1,40(sp)
 b64:	f04a                	sd	s2,32(sp)
 b66:	ec4e                	sd	s3,24(sp)
 b68:	e852                	sd	s4,16(sp)
 b6a:	e456                	sd	s5,8(sp)
 b6c:	e05a                	sd	s6,0(sp)
 b6e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 b70:	02051493          	slli	s1,a0,0x20
 b74:	9081                	srli	s1,s1,0x20
 b76:	04bd                	addi	s1,s1,15
 b78:	8091                	srli	s1,s1,0x4
 b7a:	0014899b          	addiw	s3,s1,1
 b7e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 b80:	00000517          	auipc	a0,0x0
 b84:	48853503          	ld	a0,1160(a0) # 1008 <freep>
 b88:	c515                	beqz	a0,bb4 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 b8a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 b8c:	4798                	lw	a4,8(a5)
 b8e:	02977f63          	bgeu	a4,s1,bcc <malloc+0x70>
 b92:	8a4e                	mv	s4,s3
 b94:	0009871b          	sext.w	a4,s3
 b98:	6685                	lui	a3,0x1
 b9a:	00d77363          	bgeu	a4,a3,ba0 <malloc+0x44>
 b9e:	6a05                	lui	s4,0x1
 ba0:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 ba4:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 ba8:	00000917          	auipc	s2,0x0
 bac:	46090913          	addi	s2,s2,1120 # 1008 <freep>
  if(p == SBRK_ERROR)
 bb0:	5afd                	li	s5,-1
 bb2:	a0bd                	j	c20 <malloc+0xc4>
    base.s.ptr = freep = prevp = &base;
 bb4:	00004797          	auipc	a5,0x4
 bb8:	45c78793          	addi	a5,a5,1116 # 5010 <base>
 bbc:	00000717          	auipc	a4,0x0
 bc0:	44f73623          	sd	a5,1100(a4) # 1008 <freep>
 bc4:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 bc6:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 bca:	b7e1                	j	b92 <malloc+0x36>
      if(p->s.size == nunits)
 bcc:	02e48b63          	beq	s1,a4,c02 <malloc+0xa6>
        p->s.size -= nunits;
 bd0:	4137073b          	subw	a4,a4,s3
 bd4:	c798                	sw	a4,8(a5)
        p += p->s.size;
 bd6:	1702                	slli	a4,a4,0x20
 bd8:	9301                	srli	a4,a4,0x20
 bda:	0712                	slli	a4,a4,0x4
 bdc:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 bde:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 be2:	00000717          	auipc	a4,0x0
 be6:	42a73323          	sd	a0,1062(a4) # 1008 <freep>
      return (void*)(p + 1);
 bea:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 bee:	70e2                	ld	ra,56(sp)
 bf0:	7442                	ld	s0,48(sp)
 bf2:	74a2                	ld	s1,40(sp)
 bf4:	7902                	ld	s2,32(sp)
 bf6:	69e2                	ld	s3,24(sp)
 bf8:	6a42                	ld	s4,16(sp)
 bfa:	6aa2                	ld	s5,8(sp)
 bfc:	6b02                	ld	s6,0(sp)
 bfe:	6121                	addi	sp,sp,64
 c00:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 c02:	6398                	ld	a4,0(a5)
 c04:	e118                	sd	a4,0(a0)
 c06:	bff1                	j	be2 <malloc+0x86>
  hp->s.size = nu;
 c08:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 c0c:	0541                	addi	a0,a0,16
 c0e:	ec7ff0ef          	jal	ra,ad4 <free>
  return freep;
 c12:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 c16:	dd61                	beqz	a0,bee <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c18:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c1a:	4798                	lw	a4,8(a5)
 c1c:	fa9778e3          	bgeu	a4,s1,bcc <malloc+0x70>
    if(p == freep)
 c20:	00093703          	ld	a4,0(s2)
 c24:	853e                	mv	a0,a5
 c26:	fef719e3          	bne	a4,a5,c18 <malloc+0xbc>
  p = sbrk(nu * sizeof(Header));
 c2a:	8552                	mv	a0,s4
 c2c:	a1fff0ef          	jal	ra,64a <sbrk>
  if(p == SBRK_ERROR)
 c30:	fd551ce3          	bne	a0,s5,c08 <malloc+0xac>
        return 0;
 c34:	4501                	li	a0,0
 c36:	bf65                	j	bee <malloc+0x92>
