
user/_fstest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <test_filesystem_integrity>:
#include "kernel/types.h"
#include "user.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"

void test_filesystem_integrity(void) {
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	1800                	addi	s0,sp,48
    printf("\n=== Testing filesystem integrity ===\n");
   a:	00001517          	auipc	a0,0x1
   e:	dc650513          	addi	a0,a0,-570 # dd0 <malloc+0x1aa>
  12:	35b000ef          	jal	ra,b6c <printf>

    int fd = open("testfile", O_CREATE | O_RDWR);
  16:	20200593          	li	a1,514
  1a:	00001517          	auipc	a0,0x1
  1e:	dde50513          	addi	a0,a0,-546 # df8 <malloc+0x1d2>
  22:	76e000ef          	jal	ra,790 <open>
    if (fd < 0) exit(1);
  26:	06054c63          	bltz	a0,9e <test_filesystem_integrity+0x9e>
  2a:	84aa                	mv	s1,a0
    write(fd, "OK", 2);
  2c:	4609                	li	a2,2
  2e:	00001597          	auipc	a1,0x1
  32:	dda58593          	addi	a1,a1,-550 # e08 <malloc+0x1e2>
  36:	73a000ef          	jal	ra,770 <write>
    close(fd);
  3a:	8526                	mv	a0,s1
  3c:	73c000ef          	jal	ra,778 <close>

    fd = open("testfile", O_RDONLY);
  40:	4581                	li	a1,0
  42:	00001517          	auipc	a0,0x1
  46:	db650513          	addi	a0,a0,-586 # df8 <malloc+0x1d2>
  4a:	746000ef          	jal	ra,790 <open>
  4e:	84aa                	mv	s1,a0
    if (fd < 0) exit(1);
  50:	04054a63          	bltz	a0,a4 <test_filesystem_integrity+0xa4>
    char buf[4];
    read(fd, buf, 2);
  54:	4609                	li	a2,2
  56:	fd840593          	addi	a1,s0,-40
  5a:	70e000ef          	jal	ra,768 <read>
    close(fd);
  5e:	8526                	mv	a0,s1
  60:	718000ef          	jal	ra,778 <close>
    unlink("testfile");
  64:	00001517          	auipc	a0,0x1
  68:	d9450513          	addi	a0,a0,-620 # df8 <malloc+0x1d2>
  6c:	734000ef          	jal	ra,7a0 <unlink>

    if (buf[0] != 'O' || buf[1] != 'K') exit(1);
  70:	fd844703          	lbu	a4,-40(s0)
  74:	04f00793          	li	a5,79
  78:	02f71963          	bne	a4,a5,aa <test_filesystem_integrity+0xaa>
  7c:	fd944703          	lbu	a4,-39(s0)
  80:	04b00793          	li	a5,75
  84:	02f71363          	bne	a4,a5,aa <test_filesystem_integrity+0xaa>
    printf("Filesystem integrity test passed\n");
  88:	00001517          	auipc	a0,0x1
  8c:	d8850513          	addi	a0,a0,-632 # e10 <malloc+0x1ea>
  90:	2dd000ef          	jal	ra,b6c <printf>
}
  94:	70a2                	ld	ra,40(sp)
  96:	7402                	ld	s0,32(sp)
  98:	64e2                	ld	s1,24(sp)
  9a:	6145                	addi	sp,sp,48
  9c:	8082                	ret
    if (fd < 0) exit(1);
  9e:	4505                	li	a0,1
  a0:	6b0000ef          	jal	ra,750 <exit>
    if (fd < 0) exit(1);
  a4:	4505                	li	a0,1
  a6:	6aa000ef          	jal	ra,750 <exit>
    if (buf[0] != 'O' || buf[1] != 'K') exit(1);
  aa:	4505                	li	a0,1
  ac:	6a4000ef          	jal	ra,750 <exit>

00000000000000b0 <test_concurrent_access>:

void test_concurrent_access(void) {
  b0:	711d                	addi	sp,sp,-96
  b2:	ec86                	sd	ra,88(sp)
  b4:	e8a2                	sd	s0,80(sp)
  b6:	e4a6                	sd	s1,72(sp)
  b8:	e0ca                	sd	s2,64(sp)
  ba:	fc4e                	sd	s3,56(sp)
  bc:	f852                	sd	s4,48(sp)
  be:	1080                	addi	s0,sp,96
    printf("\n=== Testing concurrent file access ===\n");
  c0:	00001517          	auipc	a0,0x1
  c4:	d7850513          	addi	a0,a0,-648 # e38 <malloc+0x212>
  c8:	2a5000ef          	jal	ra,b6c <printf>

    // 创建 4 个不同名字的文件：f0, f1, f2, f3
    for (int i = 0; i < 4; i++) {
  cc:	4481                	li	s1,0
  ce:	4911                	li	s2,4
        if (fork() == 0) {
  d0:	678000ef          	jal	ra,748 <fork>
  d4:	cd15                	beqz	a0,110 <test_concurrent_access+0x60>
    for (int i = 0; i < 4; i++) {
  d6:	2485                	addiw	s1,s1,1
  d8:	ff249ce3          	bne	s1,s2,d0 <test_concurrent_access+0x20>
            exit(0);
        }
    }

    for (int i = 0; i < 4; i++)
        wait((int *)0);
  dc:	4501                	li	a0,0
  de:	67a000ef          	jal	ra,758 <wait>
  e2:	4501                	li	a0,0
  e4:	674000ef          	jal	ra,758 <wait>
  e8:	4501                	li	a0,0
  ea:	66e000ef          	jal	ra,758 <wait>
  ee:	4501                	li	a0,0
  f0:	668000ef          	jal	ra,758 <wait>

    printf("Concurrent access test completed\n");
  f4:	00001517          	auipc	a0,0x1
  f8:	d7450513          	addi	a0,a0,-652 # e68 <malloc+0x242>
  fc:	271000ef          	jal	ra,b6c <printf>
}
 100:	60e6                	ld	ra,88(sp)
 102:	6446                	ld	s0,80(sp)
 104:	64a6                	ld	s1,72(sp)
 106:	6906                	ld	s2,64(sp)
 108:	79e2                	ld	s3,56(sp)
 10a:	7a42                	ld	s4,48(sp)
 10c:	6125                	addi	sp,sp,96
 10e:	8082                	ret
            const char* names[] = {"f0", "f1", "f2", "f3"};
 110:	00001797          	auipc	a5,0x1
 114:	c0078793          	addi	a5,a5,-1024 # d10 <malloc+0xea>
 118:	faf43823          	sd	a5,-80(s0)
 11c:	00001797          	auipc	a5,0x1
 120:	bfc78793          	addi	a5,a5,-1028 # d18 <malloc+0xf2>
 124:	faf43c23          	sd	a5,-72(s0)
 128:	00001797          	auipc	a5,0x1
 12c:	bf878793          	addi	a5,a5,-1032 # d20 <malloc+0xfa>
 130:	fcf43023          	sd	a5,-64(s0)
 134:	00001797          	auipc	a5,0x1
 138:	bf478793          	addi	a5,a5,-1036 # d28 <malloc+0x102>
 13c:	fcf43423          	sd	a5,-56(s0)
            for (int j = 0; j < 30; j++) {
 140:	fa042623          	sw	zero,-84(s0)
                int fd = open(names[i], O_CREATE | O_RDWR);
 144:	048e                	slli	s1,s1,0x3
 146:	fd040793          	addi	a5,s0,-48
 14a:	94be                	add	s1,s1,a5
            for (int j = 0; j < 30; j++) {
 14c:	4a75                	li	s4,29
 14e:	a811                	j	162 <test_concurrent_access+0xb2>
 150:	fac42783          	lw	a5,-84(s0)
 154:	2785                	addiw	a5,a5,1
 156:	0007871b          	sext.w	a4,a5
 15a:	faf42623          	sw	a5,-84(s0)
 15e:	02ea4863          	blt	s4,a4,18e <test_concurrent_access+0xde>
                int fd = open(names[i], O_CREATE | O_RDWR);
 162:	fe04b983          	ld	s3,-32(s1)
 166:	20200593          	li	a1,514
 16a:	854e                	mv	a0,s3
 16c:	624000ef          	jal	ra,790 <open>
 170:	892a                	mv	s2,a0
                if (fd >= 0) {
 172:	fc054fe3          	bltz	a0,150 <test_concurrent_access+0xa0>
                    write(fd, &j, sizeof(j));
 176:	4611                	li	a2,4
 178:	fac40593          	addi	a1,s0,-84
 17c:	5f4000ef          	jal	ra,770 <write>
                    close(fd);
 180:	854a                	mv	a0,s2
 182:	5f6000ef          	jal	ra,778 <close>
                    unlink(names[i]);
 186:	854e                	mv	a0,s3
 188:	618000ef          	jal	ra,7a0 <unlink>
 18c:	b7d1                	j	150 <test_concurrent_access+0xa0>
            exit(0);
 18e:	4501                	li	a0,0
 190:	5c0000ef          	jal	ra,750 <exit>

0000000000000194 <test_crash_recovery>:

void test_crash_recovery(void) {
 194:	7119                	addi	sp,sp,-128
 196:	fc86                	sd	ra,120(sp)
 198:	f8a2                	sd	s0,112(sp)
 19a:	f4a6                	sd	s1,104(sp)
 19c:	f0ca                	sd	s2,96(sp)
 19e:	ecce                	sd	s3,88(sp)
 1a0:	e8d2                	sd	s4,80(sp)
 1a2:	0100                	addi	s0,sp,128
    printf("\n=== Testing crash recovery (simulated) ===\n");
 1a4:	00001517          	auipc	a0,0x1
 1a8:	cec50513          	addi	a0,a0,-788 # e90 <malloc+0x26a>
 1ac:	1c1000ef          	jal	ra,b6c <printf>

    // 创建 partial_0 到 partial_9 → 改为创建 p0, p1, ..., p9
    const char* parts[] = {
 1b0:	00001797          	auipc	a5,0x1
 1b4:	e9078793          	addi	a5,a5,-368 # 1040 <malloc+0x41a>
 1b8:	0007be03          	ld	t3,0(a5)
 1bc:	0087b303          	ld	t1,8(a5)
 1c0:	0107b883          	ld	a7,16(a5)
 1c4:	0187b803          	ld	a6,24(a5)
 1c8:	7388                	ld	a0,32(a5)
 1ca:	778c                	ld	a1,40(a5)
 1cc:	7b90                	ld	a2,48(a5)
 1ce:	7f94                	ld	a3,56(a5)
 1d0:	63b8                	ld	a4,64(a5)
 1d2:	67bc                	ld	a5,72(a5)
 1d4:	f9c43023          	sd	t3,-128(s0)
 1d8:	f8643423          	sd	t1,-120(s0)
 1dc:	f9143823          	sd	a7,-112(s0)
 1e0:	f9043c23          	sd	a6,-104(s0)
 1e4:	faa43023          	sd	a0,-96(s0)
 1e8:	fab43423          	sd	a1,-88(s0)
 1ec:	fac43823          	sd	a2,-80(s0)
 1f0:	fad43c23          	sd	a3,-72(s0)
 1f4:	fce43023          	sd	a4,-64(s0)
 1f8:	fcf43423          	sd	a5,-56(s0)
        "p0", "p1", "p2", "p3", "p4",
        "p5", "p6", "p7", "p8", "p9"
    };

    for (int i = 0; i < 10; i++) {
 1fc:	f8040913          	addi	s2,s0,-128
 200:	fd040993          	addi	s3,s0,-48
        int fd = open(parts[i], O_CREATE | O_RDWR);
        if (fd >= 0) {
            write(fd, "x", 1);
 204:	00001a17          	auipc	s4,0x1
 208:	cbca0a13          	addi	s4,s4,-836 # ec0 <malloc+0x29a>
 20c:	a021                	j	214 <test_crash_recovery+0x80>
    for (int i = 0; i < 10; i++) {
 20e:	0921                	addi	s2,s2,8
 210:	03390363          	beq	s2,s3,236 <test_crash_recovery+0xa2>
        int fd = open(parts[i], O_CREATE | O_RDWR);
 214:	20200593          	li	a1,514
 218:	00093503          	ld	a0,0(s2)
 21c:	574000ef          	jal	ra,790 <open>
 220:	84aa                	mv	s1,a0
        if (fd >= 0) {
 222:	fe0546e3          	bltz	a0,20e <test_crash_recovery+0x7a>
            write(fd, "x", 1);
 226:	4605                	li	a2,1
 228:	85d2                	mv	a1,s4
 22a:	546000ef          	jal	ra,770 <write>
            close(fd);
 22e:	8526                	mv	a0,s1
 230:	548000ef          	jal	ra,778 <close>
 234:	bfe9                	j	20e <test_crash_recovery+0x7a>
            // 不 unlink，模拟崩溃残留
        }
    }

    printf("Crash recovery test setup complete. Check for p0-p9 files.\n");
 236:	00001517          	auipc	a0,0x1
 23a:	c9250513          	addi	a0,a0,-878 # ec8 <malloc+0x2a2>
 23e:	12f000ef          	jal	ra,b6c <printf>
    printf("Reboot to test recovery behavior.\n");
 242:	00001517          	auipc	a0,0x1
 246:	cc650513          	addi	a0,a0,-826 # f08 <malloc+0x2e2>
 24a:	123000ef          	jal	ra,b6c <printf>
}
 24e:	70e6                	ld	ra,120(sp)
 250:	7446                	ld	s0,112(sp)
 252:	74a6                	ld	s1,104(sp)
 254:	7906                	ld	s2,96(sp)
 256:	69e6                	ld	s3,88(sp)
 258:	6a46                	ld	s4,80(sp)
 25a:	6109                	addi	sp,sp,128
 25c:	8082                	ret

000000000000025e <test_filesystem_performance>:

void test_filesystem_performance(void) {
 25e:	d3010113          	addi	sp,sp,-720
 262:	2c113423          	sd	ra,712(sp)
 266:	2c813023          	sd	s0,704(sp)
 26a:	2a913c23          	sd	s1,696(sp)
 26e:	2b213823          	sd	s2,688(sp)
 272:	2b313423          	sd	s3,680(sp)
 276:	2b413023          	sd	s4,672(sp)
 27a:	29513c23          	sd	s5,664(sp)
 27e:	29613823          	sd	s6,656(sp)
 282:	29713423          	sd	s7,648(sp)
 286:	29813023          	sd	s8,640(sp)
 28a:	27913c23          	sd	s9,632(sp)
 28e:	27a13823          	sd	s10,624(sp)
 292:	27b13423          	sd	s11,616(sp)
 296:	0d80                	addi	s0,sp,720
    printf("\n=== Testing filesystem performance ===\n");
 298:	00001517          	auipc	a0,0x1
 29c:	c9850513          	addi	a0,a0,-872 # f30 <malloc+0x30a>
 2a0:	0cd000ef          	jal	ra,b6c <printf>

    int start = uptime();
 2a4:	544000ef          	jal	ra,7e8 <uptime>
 2a8:	8baa                	mv	s7,a0
    const char* smalls[] = {
 2aa:	00001797          	auipc	a5,0x1
 2ae:	d9678793          	addi	a5,a5,-618 # 1040 <malloc+0x41a>
 2b2:	0507be03          	ld	t3,80(a5)
 2b6:	0587b303          	ld	t1,88(a5)
 2ba:	0607b883          	ld	a7,96(a5)
 2be:	0687b803          	ld	a6,104(a5)
 2c2:	7ba8                	ld	a0,112(a5)
 2c4:	7fac                	ld	a1,120(a5)
 2c6:	63d0                	ld	a2,128(a5)
 2c8:	67d4                	ld	a3,136(a5)
 2ca:	6bd8                	ld	a4,144(a5)
 2cc:	6fdc                	ld	a5,152(a5)
 2ce:	f5c43023          	sd	t3,-192(s0)
 2d2:	f4643423          	sd	t1,-184(s0)
 2d6:	f5143823          	sd	a7,-176(s0)
 2da:	f5043c23          	sd	a6,-168(s0)
 2de:	f6a43023          	sd	a0,-160(s0)
 2e2:	f6b43423          	sd	a1,-152(s0)
 2e6:	f6c43823          	sd	a2,-144(s0)
 2ea:	f6d43c23          	sd	a3,-136(s0)
 2ee:	f8e43023          	sd	a4,-128(s0)
 2f2:	f8f43423          	sd	a5,-120(s0)
 2f6:	4b29                	li	s6,10
 2f8:	f9040993          	addi	s3,s0,-112
    // 创建 100 个小文件（循环 10 次，每次 10 个）
    for (int round = 0; round < 10; round++) {
        for (int i = 0; i < 10; i++) {
            int fd = open(smalls[i], O_CREATE | O_RDWR);
            if (fd >= 0) {
                write(fd, ".", 1);
 2fc:	00001a97          	auipc	s5,0x1
 300:	c64a8a93          	addi	s5,s5,-924 # f60 <malloc+0x33a>
 304:	a805                	j	334 <test_filesystem_performance+0xd6>
        for (int i = 0; i < 10; i++) {
 306:	0921                	addi	s2,s2,8
 308:	03390363          	beq	s2,s3,32e <test_filesystem_performance+0xd0>
            int fd = open(smalls[i], O_CREATE | O_RDWR);
 30c:	20200593          	li	a1,514
 310:	00093503          	ld	a0,0(s2)
 314:	47c000ef          	jal	ra,790 <open>
 318:	84aa                	mv	s1,a0
            if (fd >= 0) {
 31a:	fe0546e3          	bltz	a0,306 <test_filesystem_performance+0xa8>
                write(fd, ".", 1);
 31e:	4605                	li	a2,1
 320:	85d6                	mv	a1,s5
 322:	44e000ef          	jal	ra,770 <write>
                close(fd);
 326:	8526                	mv	a0,s1
 328:	450000ef          	jal	ra,778 <close>
 32c:	bfe9                	j	306 <test_filesystem_performance+0xa8>
    for (int round = 0; round < 10; round++) {
 32e:	3b7d                	addiw	s6,s6,-1
 330:	000b0663          	beqz	s6,33c <test_filesystem_performance+0xde>
        for (int i = 0; i < 10; i++) {
 334:	f4040a13          	addi	s4,s0,-192
void test_filesystem_performance(void) {
 338:	8952                	mv	s2,s4
 33a:	bfc9                	j	30c <test_filesystem_performance+0xae>
            }
        }
    }
    int time_small = uptime() - start;
 33c:	4ac000ef          	jal	ra,7e8 <uptime>
 340:	41750bbb          	subw	s7,a0,s7

    start = uptime();
 344:	4a4000ef          	jal	ra,7e8 <uptime>
 348:	8b2a                	mv	s6,a0
    int fd = open("big", O_CREATE | O_RDWR);
 34a:	20200593          	li	a1,514
 34e:	00001517          	auipc	a0,0x1
 352:	c1a50513          	addi	a0,a0,-998 # f68 <malloc+0x342>
 356:	43a000ef          	jal	ra,790 <open>
 35a:	892a                	mv	s2,a0
    if (fd >= 0) {
 35c:	02054963          	bltz	a0,38e <test_filesystem_performance+0x130>
        char b[512] = {0};
 360:	d4043023          	sd	zero,-704(s0)
 364:	1f800613          	li	a2,504
 368:	4581                	li	a1,0
 36a:	d4840513          	addi	a0,s0,-696
 36e:	1ce000ef          	jal	ra,53c <memset>
 372:	0c800493          	li	s1,200
        for (int i = 0; i < 200; i++) // ~100KB
            write(fd, b, sizeof(b));
 376:	20000613          	li	a2,512
 37a:	d4040593          	addi	a1,s0,-704
 37e:	854a                	mv	a0,s2
 380:	3f0000ef          	jal	ra,770 <write>
        for (int i = 0; i < 200; i++) // ~100KB
 384:	34fd                	addiw	s1,s1,-1
 386:	f8e5                	bnez	s1,376 <test_filesystem_performance+0x118>
        close(fd);
 388:	854a                	mv	a0,s2
 38a:	3ee000ef          	jal	ra,778 <close>
    }
    int time_big = uptime() - start;
 38e:	45a000ef          	jal	ra,7e8 <uptime>
 392:	41650b3b          	subw	s6,a0,s6

    printf("100 small files: %d ticks\n", time_small);
 396:	85de                	mv	a1,s7
 398:	00001517          	auipc	a0,0x1
 39c:	bd850513          	addi	a0,a0,-1064 # f70 <malloc+0x34a>
 3a0:	7cc000ef          	jal	ra,b6c <printf>
    printf("Big file (~100KB): %d ticks\n", time_big);
 3a4:	85da                	mv	a1,s6
 3a6:	00001517          	auipc	a0,0x1
 3aa:	bea50513          	addi	a0,a0,-1046 # f90 <malloc+0x36a>
 3ae:	7be000ef          	jal	ra,b6c <printf>

    // 清理
    for (int i = 0; i < 10; i++) unlink(smalls[i]);
 3b2:	000a3503          	ld	a0,0(s4)
 3b6:	3ea000ef          	jal	ra,7a0 <unlink>
 3ba:	0a21                	addi	s4,s4,8
 3bc:	ff3a1be3          	bne	s4,s3,3b2 <test_filesystem_performance+0x154>
    unlink("big");
 3c0:	00001517          	auipc	a0,0x1
 3c4:	ba850513          	addi	a0,a0,-1112 # f68 <malloc+0x342>
 3c8:	3d8000ef          	jal	ra,7a0 <unlink>
    for (int i = 0; i < 10; i++) {
 3cc:	d4040493          	addi	s1,s0,-704
 3d0:	d9040d93          	addi	s11,s0,-624
        const char* pfiles[] = {"p0","p1","p2","p3","p4","p5","p6","p7","p8","p9"};
 3d4:	00001797          	auipc	a5,0x1
 3d8:	c6c78793          	addi	a5,a5,-916 # 1040 <malloc+0x41a>
 3dc:	0007bd03          	ld	s10,0(a5)
 3e0:	0087bc83          	ld	s9,8(a5)
 3e4:	0107bc03          	ld	s8,16(a5)
 3e8:	0187bb83          	ld	s7,24(a5)
 3ec:	0207bb03          	ld	s6,32(a5)
 3f0:	0287ba83          	ld	s5,40(a5)
 3f4:	0307ba03          	ld	s4,48(a5)
 3f8:	0387b983          	ld	s3,56(a5)
 3fc:	0407b903          	ld	s2,64(a5)
 400:	67bc                	ld	a5,72(a5)
 402:	d2f43c23          	sd	a5,-712(s0)
 406:	d5a43023          	sd	s10,-704(s0)
 40a:	d5943423          	sd	s9,-696(s0)
 40e:	d5843823          	sd	s8,-688(s0)
 412:	d5743c23          	sd	s7,-680(s0)
 416:	d7643023          	sd	s6,-672(s0)
 41a:	d7543423          	sd	s5,-664(s0)
 41e:	d7443823          	sd	s4,-656(s0)
 422:	d7343c23          	sd	s3,-648(s0)
 426:	d9243023          	sd	s2,-640(s0)
 42a:	d3843783          	ld	a5,-712(s0)
 42e:	d8f43423          	sd	a5,-632(s0)
        unlink(pfiles[i]);
 432:	6088                	ld	a0,0(s1)
 434:	36c000ef          	jal	ra,7a0 <unlink>
    for (int i = 0; i < 10; i++) {
 438:	04a1                	addi	s1,s1,8
 43a:	fc9d96e3          	bne	s11,s1,406 <test_filesystem_performance+0x1a8>
    }

    printf("Performance test cleanup done\n");
 43e:	00001517          	auipc	a0,0x1
 442:	b7250513          	addi	a0,a0,-1166 # fb0 <malloc+0x38a>
 446:	726000ef          	jal	ra,b6c <printf>
}
 44a:	2c813083          	ld	ra,712(sp)
 44e:	2c013403          	ld	s0,704(sp)
 452:	2b813483          	ld	s1,696(sp)
 456:	2b013903          	ld	s2,688(sp)
 45a:	2a813983          	ld	s3,680(sp)
 45e:	2a013a03          	ld	s4,672(sp)
 462:	29813a83          	ld	s5,664(sp)
 466:	29013b03          	ld	s6,656(sp)
 46a:	28813b83          	ld	s7,648(sp)
 46e:	28013c03          	ld	s8,640(sp)
 472:	27813c83          	ld	s9,632(sp)
 476:	27013d03          	ld	s10,624(sp)
 47a:	26813d83          	ld	s11,616(sp)
 47e:	2d010113          	addi	sp,sp,720
 482:	8082                	ret

0000000000000484 <main>:

int main(void) {
 484:	1141                	addi	sp,sp,-16
 486:	e406                	sd	ra,8(sp)
 488:	e022                	sd	s0,0(sp)
 48a:	0800                	addi	s0,sp,16
    printf("=== xv6 Filesystem Test Suite (Minimal Safe Version) ===\n");
 48c:	00001517          	auipc	a0,0x1
 490:	b4450513          	addi	a0,a0,-1212 # fd0 <malloc+0x3aa>
 494:	6d8000ef          	jal	ra,b6c <printf>

    test_filesystem_integrity();
 498:	b69ff0ef          	jal	ra,0 <test_filesystem_integrity>
    test_concurrent_access();
 49c:	c15ff0ef          	jal	ra,b0 <test_concurrent_access>
    test_crash_recovery();
 4a0:	cf5ff0ef          	jal	ra,194 <test_crash_recovery>
    test_filesystem_performance();
 4a4:	dbbff0ef          	jal	ra,25e <test_filesystem_performance>

    printf("\n=== All tests completed successfully ===\n");
 4a8:	00001517          	auipc	a0,0x1
 4ac:	b6850513          	addi	a0,a0,-1176 # 1010 <malloc+0x3ea>
 4b0:	6bc000ef          	jal	ra,b6c <printf>
    exit(0);
 4b4:	4501                	li	a0,0
 4b6:	29a000ef          	jal	ra,750 <exit>

00000000000004ba <start>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
start(int argc, char **argv)
{
 4ba:	1141                	addi	sp,sp,-16
 4bc:	e406                	sd	ra,8(sp)
 4be:	e022                	sd	s0,0(sp)
 4c0:	0800                	addi	s0,sp,16
  int r;
  extern int main(int argc, char **argv);
  r = main(argc, argv);
 4c2:	fc3ff0ef          	jal	ra,484 <main>
  exit(r);
 4c6:	28a000ef          	jal	ra,750 <exit>

00000000000004ca <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 4ca:	1141                	addi	sp,sp,-16
 4cc:	e422                	sd	s0,8(sp)
 4ce:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 4d0:	87aa                	mv	a5,a0
 4d2:	0585                	addi	a1,a1,1
 4d4:	0785                	addi	a5,a5,1
 4d6:	fff5c703          	lbu	a4,-1(a1)
 4da:	fee78fa3          	sb	a4,-1(a5)
 4de:	fb75                	bnez	a4,4d2 <strcpy+0x8>
    ;
  return os;
}
 4e0:	6422                	ld	s0,8(sp)
 4e2:	0141                	addi	sp,sp,16
 4e4:	8082                	ret

00000000000004e6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 4e6:	1141                	addi	sp,sp,-16
 4e8:	e422                	sd	s0,8(sp)
 4ea:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 4ec:	00054783          	lbu	a5,0(a0)
 4f0:	cb91                	beqz	a5,504 <strcmp+0x1e>
 4f2:	0005c703          	lbu	a4,0(a1)
 4f6:	00f71763          	bne	a4,a5,504 <strcmp+0x1e>
    p++, q++;
 4fa:	0505                	addi	a0,a0,1
 4fc:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 4fe:	00054783          	lbu	a5,0(a0)
 502:	fbe5                	bnez	a5,4f2 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 504:	0005c503          	lbu	a0,0(a1)
}
 508:	40a7853b          	subw	a0,a5,a0
 50c:	6422                	ld	s0,8(sp)
 50e:	0141                	addi	sp,sp,16
 510:	8082                	ret

0000000000000512 <strlen>:

uint
strlen(const char *s)
{
 512:	1141                	addi	sp,sp,-16
 514:	e422                	sd	s0,8(sp)
 516:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 518:	00054783          	lbu	a5,0(a0)
 51c:	cf91                	beqz	a5,538 <strlen+0x26>
 51e:	0505                	addi	a0,a0,1
 520:	87aa                	mv	a5,a0
 522:	4685                	li	a3,1
 524:	9e89                	subw	a3,a3,a0
 526:	00f6853b          	addw	a0,a3,a5
 52a:	0785                	addi	a5,a5,1
 52c:	fff7c703          	lbu	a4,-1(a5)
 530:	fb7d                	bnez	a4,526 <strlen+0x14>
    ;
  return n;
}
 532:	6422                	ld	s0,8(sp)
 534:	0141                	addi	sp,sp,16
 536:	8082                	ret
  for(n = 0; s[n]; n++)
 538:	4501                	li	a0,0
 53a:	bfe5                	j	532 <strlen+0x20>

000000000000053c <memset>:

void*
memset(void *dst, int c, uint n)
{
 53c:	1141                	addi	sp,sp,-16
 53e:	e422                	sd	s0,8(sp)
 540:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 542:	ca19                	beqz	a2,558 <memset+0x1c>
 544:	87aa                	mv	a5,a0
 546:	1602                	slli	a2,a2,0x20
 548:	9201                	srli	a2,a2,0x20
 54a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 54e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 552:	0785                	addi	a5,a5,1
 554:	fee79de3          	bne	a5,a4,54e <memset+0x12>
  }
  return dst;
}
 558:	6422                	ld	s0,8(sp)
 55a:	0141                	addi	sp,sp,16
 55c:	8082                	ret

000000000000055e <strchr>:

char*
strchr(const char *s, char c)
{
 55e:	1141                	addi	sp,sp,-16
 560:	e422                	sd	s0,8(sp)
 562:	0800                	addi	s0,sp,16
  for(; *s; s++)
 564:	00054783          	lbu	a5,0(a0)
 568:	cb99                	beqz	a5,57e <strchr+0x20>
    if(*s == c)
 56a:	00f58763          	beq	a1,a5,578 <strchr+0x1a>
  for(; *s; s++)
 56e:	0505                	addi	a0,a0,1
 570:	00054783          	lbu	a5,0(a0)
 574:	fbfd                	bnez	a5,56a <strchr+0xc>
      return (char*)s;
  return 0;
 576:	4501                	li	a0,0
}
 578:	6422                	ld	s0,8(sp)
 57a:	0141                	addi	sp,sp,16
 57c:	8082                	ret
  return 0;
 57e:	4501                	li	a0,0
 580:	bfe5                	j	578 <strchr+0x1a>

0000000000000582 <gets>:

char*
gets(char *buf, int max)
{
 582:	711d                	addi	sp,sp,-96
 584:	ec86                	sd	ra,88(sp)
 586:	e8a2                	sd	s0,80(sp)
 588:	e4a6                	sd	s1,72(sp)
 58a:	e0ca                	sd	s2,64(sp)
 58c:	fc4e                	sd	s3,56(sp)
 58e:	f852                	sd	s4,48(sp)
 590:	f456                	sd	s5,40(sp)
 592:	f05a                	sd	s6,32(sp)
 594:	ec5e                	sd	s7,24(sp)
 596:	1080                	addi	s0,sp,96
 598:	8baa                	mv	s7,a0
 59a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 59c:	892a                	mv	s2,a0
 59e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 5a0:	4aa9                	li	s5,10
 5a2:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 5a4:	89a6                	mv	s3,s1
 5a6:	2485                	addiw	s1,s1,1
 5a8:	0344d663          	bge	s1,s4,5d4 <gets+0x52>
    cc = read(0, &c, 1);
 5ac:	4605                	li	a2,1
 5ae:	faf40593          	addi	a1,s0,-81
 5b2:	4501                	li	a0,0
 5b4:	1b4000ef          	jal	ra,768 <read>
    if(cc < 1)
 5b8:	00a05e63          	blez	a0,5d4 <gets+0x52>
    buf[i++] = c;
 5bc:	faf44783          	lbu	a5,-81(s0)
 5c0:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 5c4:	01578763          	beq	a5,s5,5d2 <gets+0x50>
 5c8:	0905                	addi	s2,s2,1
 5ca:	fd679de3          	bne	a5,s6,5a4 <gets+0x22>
  for(i=0; i+1 < max; ){
 5ce:	89a6                	mv	s3,s1
 5d0:	a011                	j	5d4 <gets+0x52>
 5d2:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 5d4:	99de                	add	s3,s3,s7
 5d6:	00098023          	sb	zero,0(s3)
  return buf;
}
 5da:	855e                	mv	a0,s7
 5dc:	60e6                	ld	ra,88(sp)
 5de:	6446                	ld	s0,80(sp)
 5e0:	64a6                	ld	s1,72(sp)
 5e2:	6906                	ld	s2,64(sp)
 5e4:	79e2                	ld	s3,56(sp)
 5e6:	7a42                	ld	s4,48(sp)
 5e8:	7aa2                	ld	s5,40(sp)
 5ea:	7b02                	ld	s6,32(sp)
 5ec:	6be2                	ld	s7,24(sp)
 5ee:	6125                	addi	sp,sp,96
 5f0:	8082                	ret

00000000000005f2 <stat>:

int
stat(const char *n, struct stat *st)
{
 5f2:	1101                	addi	sp,sp,-32
 5f4:	ec06                	sd	ra,24(sp)
 5f6:	e822                	sd	s0,16(sp)
 5f8:	e426                	sd	s1,8(sp)
 5fa:	e04a                	sd	s2,0(sp)
 5fc:	1000                	addi	s0,sp,32
 5fe:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 600:	4581                	li	a1,0
 602:	18e000ef          	jal	ra,790 <open>
  if(fd < 0)
 606:	02054163          	bltz	a0,628 <stat+0x36>
 60a:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 60c:	85ca                	mv	a1,s2
 60e:	19a000ef          	jal	ra,7a8 <fstat>
 612:	892a                	mv	s2,a0
  close(fd);
 614:	8526                	mv	a0,s1
 616:	162000ef          	jal	ra,778 <close>
  return r;
}
 61a:	854a                	mv	a0,s2
 61c:	60e2                	ld	ra,24(sp)
 61e:	6442                	ld	s0,16(sp)
 620:	64a2                	ld	s1,8(sp)
 622:	6902                	ld	s2,0(sp)
 624:	6105                	addi	sp,sp,32
 626:	8082                	ret
    return -1;
 628:	597d                	li	s2,-1
 62a:	bfc5                	j	61a <stat+0x28>

000000000000062c <atoi>:

int
atoi(const char *s)
{
 62c:	1141                	addi	sp,sp,-16
 62e:	e422                	sd	s0,8(sp)
 630:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 632:	00054603          	lbu	a2,0(a0)
 636:	fd06079b          	addiw	a5,a2,-48
 63a:	0ff7f793          	andi	a5,a5,255
 63e:	4725                	li	a4,9
 640:	02f76963          	bltu	a4,a5,672 <atoi+0x46>
 644:	86aa                	mv	a3,a0
  n = 0;
 646:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 648:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 64a:	0685                	addi	a3,a3,1
 64c:	0025179b          	slliw	a5,a0,0x2
 650:	9fa9                	addw	a5,a5,a0
 652:	0017979b          	slliw	a5,a5,0x1
 656:	9fb1                	addw	a5,a5,a2
 658:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 65c:	0006c603          	lbu	a2,0(a3)
 660:	fd06071b          	addiw	a4,a2,-48
 664:	0ff77713          	andi	a4,a4,255
 668:	fee5f1e3          	bgeu	a1,a4,64a <atoi+0x1e>
  return n;
}
 66c:	6422                	ld	s0,8(sp)
 66e:	0141                	addi	sp,sp,16
 670:	8082                	ret
  n = 0;
 672:	4501                	li	a0,0
 674:	bfe5                	j	66c <atoi+0x40>

0000000000000676 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 676:	1141                	addi	sp,sp,-16
 678:	e422                	sd	s0,8(sp)
 67a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 67c:	02b57463          	bgeu	a0,a1,6a4 <memmove+0x2e>
    while(n-- > 0)
 680:	00c05f63          	blez	a2,69e <memmove+0x28>
 684:	1602                	slli	a2,a2,0x20
 686:	9201                	srli	a2,a2,0x20
 688:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 68c:	872a                	mv	a4,a0
      *dst++ = *src++;
 68e:	0585                	addi	a1,a1,1
 690:	0705                	addi	a4,a4,1
 692:	fff5c683          	lbu	a3,-1(a1)
 696:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 69a:	fee79ae3          	bne	a5,a4,68e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 69e:	6422                	ld	s0,8(sp)
 6a0:	0141                	addi	sp,sp,16
 6a2:	8082                	ret
    dst += n;
 6a4:	00c50733          	add	a4,a0,a2
    src += n;
 6a8:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 6aa:	fec05ae3          	blez	a2,69e <memmove+0x28>
 6ae:	fff6079b          	addiw	a5,a2,-1
 6b2:	1782                	slli	a5,a5,0x20
 6b4:	9381                	srli	a5,a5,0x20
 6b6:	fff7c793          	not	a5,a5
 6ba:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 6bc:	15fd                	addi	a1,a1,-1
 6be:	177d                	addi	a4,a4,-1
 6c0:	0005c683          	lbu	a3,0(a1)
 6c4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 6c8:	fee79ae3          	bne	a5,a4,6bc <memmove+0x46>
 6cc:	bfc9                	j	69e <memmove+0x28>

00000000000006ce <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 6ce:	1141                	addi	sp,sp,-16
 6d0:	e422                	sd	s0,8(sp)
 6d2:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 6d4:	ca05                	beqz	a2,704 <memcmp+0x36>
 6d6:	fff6069b          	addiw	a3,a2,-1
 6da:	1682                	slli	a3,a3,0x20
 6dc:	9281                	srli	a3,a3,0x20
 6de:	0685                	addi	a3,a3,1
 6e0:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 6e2:	00054783          	lbu	a5,0(a0)
 6e6:	0005c703          	lbu	a4,0(a1)
 6ea:	00e79863          	bne	a5,a4,6fa <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 6ee:	0505                	addi	a0,a0,1
    p2++;
 6f0:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 6f2:	fed518e3          	bne	a0,a3,6e2 <memcmp+0x14>
  }
  return 0;
 6f6:	4501                	li	a0,0
 6f8:	a019                	j	6fe <memcmp+0x30>
      return *p1 - *p2;
 6fa:	40e7853b          	subw	a0,a5,a4
}
 6fe:	6422                	ld	s0,8(sp)
 700:	0141                	addi	sp,sp,16
 702:	8082                	ret
  return 0;
 704:	4501                	li	a0,0
 706:	bfe5                	j	6fe <memcmp+0x30>

0000000000000708 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 708:	1141                	addi	sp,sp,-16
 70a:	e406                	sd	ra,8(sp)
 70c:	e022                	sd	s0,0(sp)
 70e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 710:	f67ff0ef          	jal	ra,676 <memmove>
}
 714:	60a2                	ld	ra,8(sp)
 716:	6402                	ld	s0,0(sp)
 718:	0141                	addi	sp,sp,16
 71a:	8082                	ret

000000000000071c <sbrk>:

char *
sbrk(int n) {
 71c:	1141                	addi	sp,sp,-16
 71e:	e406                	sd	ra,8(sp)
 720:	e022                	sd	s0,0(sp)
 722:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_EAGER);
 724:	4585                	li	a1,1
 726:	0b2000ef          	jal	ra,7d8 <sys_sbrk>
}
 72a:	60a2                	ld	ra,8(sp)
 72c:	6402                	ld	s0,0(sp)
 72e:	0141                	addi	sp,sp,16
 730:	8082                	ret

0000000000000732 <sbrklazy>:

char *
sbrklazy(int n) {
 732:	1141                	addi	sp,sp,-16
 734:	e406                	sd	ra,8(sp)
 736:	e022                	sd	s0,0(sp)
 738:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_LAZY);
 73a:	4589                	li	a1,2
 73c:	09c000ef          	jal	ra,7d8 <sys_sbrk>
}
 740:	60a2                	ld	ra,8(sp)
 742:	6402                	ld	s0,0(sp)
 744:	0141                	addi	sp,sp,16
 746:	8082                	ret

0000000000000748 <fork>:
# 由 usys.pl 生成 - 请勿编辑
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 748:	4885                	li	a7,1
 ecall
 74a:	00000073          	ecall
 ret
 74e:	8082                	ret

0000000000000750 <exit>:
.global exit
exit:
 li a7, SYS_exit
 750:	4889                	li	a7,2
 ecall
 752:	00000073          	ecall
 ret
 756:	8082                	ret

0000000000000758 <wait>:
.global wait
wait:
 li a7, SYS_wait
 758:	488d                	li	a7,3
 ecall
 75a:	00000073          	ecall
 ret
 75e:	8082                	ret

0000000000000760 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 760:	4891                	li	a7,4
 ecall
 762:	00000073          	ecall
 ret
 766:	8082                	ret

0000000000000768 <read>:
.global read
read:
 li a7, SYS_read
 768:	4895                	li	a7,5
 ecall
 76a:	00000073          	ecall
 ret
 76e:	8082                	ret

0000000000000770 <write>:
.global write
write:
 li a7, SYS_write
 770:	48c1                	li	a7,16
 ecall
 772:	00000073          	ecall
 ret
 776:	8082                	ret

0000000000000778 <close>:
.global close
close:
 li a7, SYS_close
 778:	48d5                	li	a7,21
 ecall
 77a:	00000073          	ecall
 ret
 77e:	8082                	ret

0000000000000780 <kill>:
.global kill
kill:
 li a7, SYS_kill
 780:	4899                	li	a7,6
 ecall
 782:	00000073          	ecall
 ret
 786:	8082                	ret

0000000000000788 <exec>:
.global exec
exec:
 li a7, SYS_exec
 788:	489d                	li	a7,7
 ecall
 78a:	00000073          	ecall
 ret
 78e:	8082                	ret

0000000000000790 <open>:
.global open
open:
 li a7, SYS_open
 790:	48bd                	li	a7,15
 ecall
 792:	00000073          	ecall
 ret
 796:	8082                	ret

0000000000000798 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 798:	48c5                	li	a7,17
 ecall
 79a:	00000073          	ecall
 ret
 79e:	8082                	ret

00000000000007a0 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 7a0:	48c9                	li	a7,18
 ecall
 7a2:	00000073          	ecall
 ret
 7a6:	8082                	ret

00000000000007a8 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 7a8:	48a1                	li	a7,8
 ecall
 7aa:	00000073          	ecall
 ret
 7ae:	8082                	ret

00000000000007b0 <link>:
.global link
link:
 li a7, SYS_link
 7b0:	48cd                	li	a7,19
 ecall
 7b2:	00000073          	ecall
 ret
 7b6:	8082                	ret

00000000000007b8 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 7b8:	48d1                	li	a7,20
 ecall
 7ba:	00000073          	ecall
 ret
 7be:	8082                	ret

00000000000007c0 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 7c0:	48a5                	li	a7,9
 ecall
 7c2:	00000073          	ecall
 ret
 7c6:	8082                	ret

00000000000007c8 <dup>:
.global dup
dup:
 li a7, SYS_dup
 7c8:	48a9                	li	a7,10
 ecall
 7ca:	00000073          	ecall
 ret
 7ce:	8082                	ret

00000000000007d0 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 7d0:	48ad                	li	a7,11
 ecall
 7d2:	00000073          	ecall
 ret
 7d6:	8082                	ret

00000000000007d8 <sys_sbrk>:
.global sys_sbrk
sys_sbrk:
 li a7, SYS_sbrk
 7d8:	48b1                	li	a7,12
 ecall
 7da:	00000073          	ecall
 ret
 7de:	8082                	ret

00000000000007e0 <pause>:
.global pause
pause:
 li a7, SYS_pause
 7e0:	48b5                	li	a7,13
 ecall
 7e2:	00000073          	ecall
 ret
 7e6:	8082                	ret

00000000000007e8 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 7e8:	48b9                	li	a7,14
 ecall
 7ea:	00000073          	ecall
 ret
 7ee:	8082                	ret

00000000000007f0 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 7f0:	1101                	addi	sp,sp,-32
 7f2:	ec06                	sd	ra,24(sp)
 7f4:	e822                	sd	s0,16(sp)
 7f6:	1000                	addi	s0,sp,32
 7f8:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 7fc:	4605                	li	a2,1
 7fe:	fef40593          	addi	a1,s0,-17
 802:	f6fff0ef          	jal	ra,770 <write>
}
 806:	60e2                	ld	ra,24(sp)
 808:	6442                	ld	s0,16(sp)
 80a:	6105                	addi	sp,sp,32
 80c:	8082                	ret

000000000000080e <printint>:

static void
printint(int fd, long long xx, int base, int sgn)
{
 80e:	715d                	addi	sp,sp,-80
 810:	e486                	sd	ra,72(sp)
 812:	e0a2                	sd	s0,64(sp)
 814:	fc26                	sd	s1,56(sp)
 816:	f84a                	sd	s2,48(sp)
 818:	f44e                	sd	s3,40(sp)
 81a:	0880                	addi	s0,sp,80
 81c:	892a                	mv	s2,a0
  char buf[20];
  int i, neg;
  unsigned long long x;

  neg = 0;
  if(sgn && xx < 0){
 81e:	c299                	beqz	a3,824 <printint+0x16>
 820:	0805c163          	bltz	a1,8a2 <printint+0x94>
  neg = 0;
 824:	4881                	li	a7,0
 826:	fb840693          	addi	a3,s0,-72
    x = -xx;
  } else {
    x = xx;
  }

  i = 0;
 82a:	4781                	li	a5,0
  do{
    buf[i++] = digits[x % base];
 82c:	00001517          	auipc	a0,0x1
 830:	8bc50513          	addi	a0,a0,-1860 # 10e8 <digits>
 834:	883e                	mv	a6,a5
 836:	2785                	addiw	a5,a5,1
 838:	02c5f733          	remu	a4,a1,a2
 83c:	972a                	add	a4,a4,a0
 83e:	00074703          	lbu	a4,0(a4)
 842:	00e68023          	sb	a4,0(a3)
  }while((x /= base) != 0);
 846:	872e                	mv	a4,a1
 848:	02c5d5b3          	divu	a1,a1,a2
 84c:	0685                	addi	a3,a3,1
 84e:	fec773e3          	bgeu	a4,a2,834 <printint+0x26>
  if(neg)
 852:	00088b63          	beqz	a7,868 <printint+0x5a>
    buf[i++] = '-';
 856:	fd040713          	addi	a4,s0,-48
 85a:	97ba                	add	a5,a5,a4
 85c:	02d00713          	li	a4,45
 860:	fee78423          	sb	a4,-24(a5)
 864:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
 868:	02f05663          	blez	a5,894 <printint+0x86>
 86c:	fb840713          	addi	a4,s0,-72
 870:	00f704b3          	add	s1,a4,a5
 874:	fff70993          	addi	s3,a4,-1
 878:	99be                	add	s3,s3,a5
 87a:	37fd                	addiw	a5,a5,-1
 87c:	1782                	slli	a5,a5,0x20
 87e:	9381                	srli	a5,a5,0x20
 880:	40f989b3          	sub	s3,s3,a5
    putc(fd, buf[i]);
 884:	fff4c583          	lbu	a1,-1(s1)
 888:	854a                	mv	a0,s2
 88a:	f67ff0ef          	jal	ra,7f0 <putc>
  while(--i >= 0)
 88e:	14fd                	addi	s1,s1,-1
 890:	ff349ae3          	bne	s1,s3,884 <printint+0x76>
}
 894:	60a6                	ld	ra,72(sp)
 896:	6406                	ld	s0,64(sp)
 898:	74e2                	ld	s1,56(sp)
 89a:	7942                	ld	s2,48(sp)
 89c:	79a2                	ld	s3,40(sp)
 89e:	6161                	addi	sp,sp,80
 8a0:	8082                	ret
    x = -xx;
 8a2:	40b005b3          	neg	a1,a1
    neg = 1;
 8a6:	4885                	li	a7,1
    x = -xx;
 8a8:	bfbd                	j	826 <printint+0x18>

00000000000008aa <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %c, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 8aa:	7119                	addi	sp,sp,-128
 8ac:	fc86                	sd	ra,120(sp)
 8ae:	f8a2                	sd	s0,112(sp)
 8b0:	f4a6                	sd	s1,104(sp)
 8b2:	f0ca                	sd	s2,96(sp)
 8b4:	ecce                	sd	s3,88(sp)
 8b6:	e8d2                	sd	s4,80(sp)
 8b8:	e4d6                	sd	s5,72(sp)
 8ba:	e0da                	sd	s6,64(sp)
 8bc:	fc5e                	sd	s7,56(sp)
 8be:	f862                	sd	s8,48(sp)
 8c0:	f466                	sd	s9,40(sp)
 8c2:	f06a                	sd	s10,32(sp)
 8c4:	ec6e                	sd	s11,24(sp)
 8c6:	0100                	addi	s0,sp,128
  char *s;
  int c0, c1, c2, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 8c8:	0005c903          	lbu	s2,0(a1)
 8cc:	24090c63          	beqz	s2,b24 <vprintf+0x27a>
 8d0:	8b2a                	mv	s6,a0
 8d2:	8a2e                	mv	s4,a1
 8d4:	8bb2                	mv	s7,a2
  state = 0;
 8d6:	4981                	li	s3,0
  for(i = 0; fmt[i]; i++){
 8d8:	4481                	li	s1,0
 8da:	4701                	li	a4,0
      if(c0 == '%'){
        state = '%';
      } else {
        putc(fd, c0);
      }
    } else if(state == '%'){
 8dc:	02500a93          	li	s5,37
      c1 = c2 = 0;
      if(c0) c1 = fmt[i+1] & 0xff;
      if(c1) c2 = fmt[i+2] & 0xff;
      if(c0 == 'd'){
 8e0:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c0 == 'l' && c1 == 'd'){
 8e4:	06c00d13          	li	s10,108
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 2;
      } else if(c0 == 'u'){
 8e8:	07500d93          	li	s11,117
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 8ec:	00000c97          	auipc	s9,0x0
 8f0:	7fcc8c93          	addi	s9,s9,2044 # 10e8 <digits>
 8f4:	a005                	j	914 <vprintf+0x6a>
        putc(fd, c0);
 8f6:	85ca                	mv	a1,s2
 8f8:	855a                	mv	a0,s6
 8fa:	ef7ff0ef          	jal	ra,7f0 <putc>
 8fe:	a019                	j	904 <vprintf+0x5a>
    } else if(state == '%'){
 900:	03598263          	beq	s3,s5,924 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 904:	2485                	addiw	s1,s1,1
 906:	8726                	mv	a4,s1
 908:	009a07b3          	add	a5,s4,s1
 90c:	0007c903          	lbu	s2,0(a5)
 910:	20090a63          	beqz	s2,b24 <vprintf+0x27a>
    c0 = fmt[i] & 0xff;
 914:	0009079b          	sext.w	a5,s2
    if(state == 0){
 918:	fe0994e3          	bnez	s3,900 <vprintf+0x56>
      if(c0 == '%'){
 91c:	fd579de3          	bne	a5,s5,8f6 <vprintf+0x4c>
        state = '%';
 920:	89be                	mv	s3,a5
 922:	b7cd                	j	904 <vprintf+0x5a>
      if(c0) c1 = fmt[i+1] & 0xff;
 924:	c3c1                	beqz	a5,9a4 <vprintf+0xfa>
 926:	00ea06b3          	add	a3,s4,a4
 92a:	0016c683          	lbu	a3,1(a3)
      c1 = c2 = 0;
 92e:	8636                	mv	a2,a3
      if(c1) c2 = fmt[i+2] & 0xff;
 930:	c681                	beqz	a3,938 <vprintf+0x8e>
 932:	9752                	add	a4,a4,s4
 934:	00274603          	lbu	a2,2(a4)
      if(c0 == 'd'){
 938:	03878e63          	beq	a5,s8,974 <vprintf+0xca>
      } else if(c0 == 'l' && c1 == 'd'){
 93c:	05a78863          	beq	a5,s10,98c <vprintf+0xe2>
      } else if(c0 == 'u'){
 940:	0db78b63          	beq	a5,s11,a16 <vprintf+0x16c>
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 2;
      } else if(c0 == 'x'){
 944:	07800713          	li	a4,120
 948:	10e78d63          	beq	a5,a4,a62 <vprintf+0x1b8>
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 2;
      } else if(c0 == 'p'){
 94c:	07000713          	li	a4,112
 950:	14e78263          	beq	a5,a4,a94 <vprintf+0x1ea>
        printptr(fd, va_arg(ap, uint64));
      } else if(c0 == 'c'){
 954:	06300713          	li	a4,99
 958:	16e78f63          	beq	a5,a4,ad6 <vprintf+0x22c>
        putc(fd, va_arg(ap, uint32));
      } else if(c0 == 's'){
 95c:	07300713          	li	a4,115
 960:	18e78563          	beq	a5,a4,aea <vprintf+0x240>
        if((s = va_arg(ap, char*)) == 0)
          s = "(null)";
        for(; *s; s++)
          putc(fd, *s);
      } else if(c0 == '%'){
 964:	05579063          	bne	a5,s5,9a4 <vprintf+0xfa>
        putc(fd, '%');
 968:	85d6                	mv	a1,s5
 96a:	855a                	mv	a0,s6
 96c:	e85ff0ef          	jal	ra,7f0 <putc>
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c0);
      }

      state = 0;
 970:	4981                	li	s3,0
 972:	bf49                	j	904 <vprintf+0x5a>
        printint(fd, va_arg(ap, int), 10, 1);
 974:	008b8913          	addi	s2,s7,8
 978:	4685                	li	a3,1
 97a:	4629                	li	a2,10
 97c:	000ba583          	lw	a1,0(s7)
 980:	855a                	mv	a0,s6
 982:	e8dff0ef          	jal	ra,80e <printint>
 986:	8bca                	mv	s7,s2
      state = 0;
 988:	4981                	li	s3,0
 98a:	bfad                	j	904 <vprintf+0x5a>
      } else if(c0 == 'l' && c1 == 'd'){
 98c:	03868663          	beq	a3,s8,9b8 <vprintf+0x10e>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 990:	05a68163          	beq	a3,s10,9d2 <vprintf+0x128>
      } else if(c0 == 'l' && c1 == 'u'){
 994:	09b68d63          	beq	a3,s11,a2e <vprintf+0x184>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 998:	03a68f63          	beq	a3,s10,9d6 <vprintf+0x12c>
      } else if(c0 == 'l' && c1 == 'x'){
 99c:	07800793          	li	a5,120
 9a0:	0cf68d63          	beq	a3,a5,a7a <vprintf+0x1d0>
        putc(fd, '%');
 9a4:	85d6                	mv	a1,s5
 9a6:	855a                	mv	a0,s6
 9a8:	e49ff0ef          	jal	ra,7f0 <putc>
        putc(fd, c0);
 9ac:	85ca                	mv	a1,s2
 9ae:	855a                	mv	a0,s6
 9b0:	e41ff0ef          	jal	ra,7f0 <putc>
      state = 0;
 9b4:	4981                	li	s3,0
 9b6:	b7b9                	j	904 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 9b8:	008b8913          	addi	s2,s7,8
 9bc:	4685                	li	a3,1
 9be:	4629                	li	a2,10
 9c0:	000bb583          	ld	a1,0(s7)
 9c4:	855a                	mv	a0,s6
 9c6:	e49ff0ef          	jal	ra,80e <printint>
        i += 1;
 9ca:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 1);
 9cc:	8bca                	mv	s7,s2
      state = 0;
 9ce:	4981                	li	s3,0
        i += 1;
 9d0:	bf15                	j	904 <vprintf+0x5a>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 9d2:	03860563          	beq	a2,s8,9fc <vprintf+0x152>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 9d6:	07b60963          	beq	a2,s11,a48 <vprintf+0x19e>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
 9da:	07800793          	li	a5,120
 9de:	fcf613e3          	bne	a2,a5,9a4 <vprintf+0xfa>
        printint(fd, va_arg(ap, uint64), 16, 0);
 9e2:	008b8913          	addi	s2,s7,8
 9e6:	4681                	li	a3,0
 9e8:	4641                	li	a2,16
 9ea:	000bb583          	ld	a1,0(s7)
 9ee:	855a                	mv	a0,s6
 9f0:	e1fff0ef          	jal	ra,80e <printint>
        i += 2;
 9f4:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 16, 0);
 9f6:	8bca                	mv	s7,s2
      state = 0;
 9f8:	4981                	li	s3,0
        i += 2;
 9fa:	b729                	j	904 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 9fc:	008b8913          	addi	s2,s7,8
 a00:	4685                	li	a3,1
 a02:	4629                	li	a2,10
 a04:	000bb583          	ld	a1,0(s7)
 a08:	855a                	mv	a0,s6
 a0a:	e05ff0ef          	jal	ra,80e <printint>
        i += 2;
 a0e:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 1);
 a10:	8bca                	mv	s7,s2
      state = 0;
 a12:	4981                	li	s3,0
        i += 2;
 a14:	bdc5                	j	904 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint32), 10, 0);
 a16:	008b8913          	addi	s2,s7,8
 a1a:	4681                	li	a3,0
 a1c:	4629                	li	a2,10
 a1e:	000be583          	lwu	a1,0(s7)
 a22:	855a                	mv	a0,s6
 a24:	debff0ef          	jal	ra,80e <printint>
 a28:	8bca                	mv	s7,s2
      state = 0;
 a2a:	4981                	li	s3,0
 a2c:	bde1                	j	904 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 a2e:	008b8913          	addi	s2,s7,8
 a32:	4681                	li	a3,0
 a34:	4629                	li	a2,10
 a36:	000bb583          	ld	a1,0(s7)
 a3a:	855a                	mv	a0,s6
 a3c:	dd3ff0ef          	jal	ra,80e <printint>
        i += 1;
 a40:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 0);
 a42:	8bca                	mv	s7,s2
      state = 0;
 a44:	4981                	li	s3,0
        i += 1;
 a46:	bd7d                	j	904 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 a48:	008b8913          	addi	s2,s7,8
 a4c:	4681                	li	a3,0
 a4e:	4629                	li	a2,10
 a50:	000bb583          	ld	a1,0(s7)
 a54:	855a                	mv	a0,s6
 a56:	db9ff0ef          	jal	ra,80e <printint>
        i += 2;
 a5a:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 0);
 a5c:	8bca                	mv	s7,s2
      state = 0;
 a5e:	4981                	li	s3,0
        i += 2;
 a60:	b555                	j	904 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint32), 16, 0);
 a62:	008b8913          	addi	s2,s7,8
 a66:	4681                	li	a3,0
 a68:	4641                	li	a2,16
 a6a:	000be583          	lwu	a1,0(s7)
 a6e:	855a                	mv	a0,s6
 a70:	d9fff0ef          	jal	ra,80e <printint>
 a74:	8bca                	mv	s7,s2
      state = 0;
 a76:	4981                	li	s3,0
 a78:	b571                	j	904 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 16, 0);
 a7a:	008b8913          	addi	s2,s7,8
 a7e:	4681                	li	a3,0
 a80:	4641                	li	a2,16
 a82:	000bb583          	ld	a1,0(s7)
 a86:	855a                	mv	a0,s6
 a88:	d87ff0ef          	jal	ra,80e <printint>
        i += 1;
 a8c:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 16, 0);
 a8e:	8bca                	mv	s7,s2
      state = 0;
 a90:	4981                	li	s3,0
        i += 1;
 a92:	bd8d                	j	904 <vprintf+0x5a>
        printptr(fd, va_arg(ap, uint64));
 a94:	008b8793          	addi	a5,s7,8
 a98:	f8f43423          	sd	a5,-120(s0)
 a9c:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 aa0:	03000593          	li	a1,48
 aa4:	855a                	mv	a0,s6
 aa6:	d4bff0ef          	jal	ra,7f0 <putc>
  putc(fd, 'x');
 aaa:	07800593          	li	a1,120
 aae:	855a                	mv	a0,s6
 ab0:	d41ff0ef          	jal	ra,7f0 <putc>
 ab4:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 ab6:	03c9d793          	srli	a5,s3,0x3c
 aba:	97e6                	add	a5,a5,s9
 abc:	0007c583          	lbu	a1,0(a5)
 ac0:	855a                	mv	a0,s6
 ac2:	d2fff0ef          	jal	ra,7f0 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 ac6:	0992                	slli	s3,s3,0x4
 ac8:	397d                	addiw	s2,s2,-1
 aca:	fe0916e3          	bnez	s2,ab6 <vprintf+0x20c>
        printptr(fd, va_arg(ap, uint64));
 ace:	f8843b83          	ld	s7,-120(s0)
      state = 0;
 ad2:	4981                	li	s3,0
 ad4:	bd05                	j	904 <vprintf+0x5a>
        putc(fd, va_arg(ap, uint32));
 ad6:	008b8913          	addi	s2,s7,8
 ada:	000bc583          	lbu	a1,0(s7)
 ade:	855a                	mv	a0,s6
 ae0:	d11ff0ef          	jal	ra,7f0 <putc>
 ae4:	8bca                	mv	s7,s2
      state = 0;
 ae6:	4981                	li	s3,0
 ae8:	bd31                	j	904 <vprintf+0x5a>
        if((s = va_arg(ap, char*)) == 0)
 aea:	008b8993          	addi	s3,s7,8
 aee:	000bb903          	ld	s2,0(s7)
 af2:	00090f63          	beqz	s2,b10 <vprintf+0x266>
        for(; *s; s++)
 af6:	00094583          	lbu	a1,0(s2)
 afa:	c195                	beqz	a1,b1e <vprintf+0x274>
          putc(fd, *s);
 afc:	855a                	mv	a0,s6
 afe:	cf3ff0ef          	jal	ra,7f0 <putc>
        for(; *s; s++)
 b02:	0905                	addi	s2,s2,1
 b04:	00094583          	lbu	a1,0(s2)
 b08:	f9f5                	bnez	a1,afc <vprintf+0x252>
        if((s = va_arg(ap, char*)) == 0)
 b0a:	8bce                	mv	s7,s3
      state = 0;
 b0c:	4981                	li	s3,0
 b0e:	bbdd                	j	904 <vprintf+0x5a>
          s = "(null)";
 b10:	00000917          	auipc	s2,0x0
 b14:	5d090913          	addi	s2,s2,1488 # 10e0 <malloc+0x4ba>
        for(; *s; s++)
 b18:	02800593          	li	a1,40
 b1c:	b7c5                	j	afc <vprintf+0x252>
        if((s = va_arg(ap, char*)) == 0)
 b1e:	8bce                	mv	s7,s3
      state = 0;
 b20:	4981                	li	s3,0
 b22:	b3cd                	j	904 <vprintf+0x5a>
    }
  }
}
 b24:	70e6                	ld	ra,120(sp)
 b26:	7446                	ld	s0,112(sp)
 b28:	74a6                	ld	s1,104(sp)
 b2a:	7906                	ld	s2,96(sp)
 b2c:	69e6                	ld	s3,88(sp)
 b2e:	6a46                	ld	s4,80(sp)
 b30:	6aa6                	ld	s5,72(sp)
 b32:	6b06                	ld	s6,64(sp)
 b34:	7be2                	ld	s7,56(sp)
 b36:	7c42                	ld	s8,48(sp)
 b38:	7ca2                	ld	s9,40(sp)
 b3a:	7d02                	ld	s10,32(sp)
 b3c:	6de2                	ld	s11,24(sp)
 b3e:	6109                	addi	sp,sp,128
 b40:	8082                	ret

0000000000000b42 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 b42:	715d                	addi	sp,sp,-80
 b44:	ec06                	sd	ra,24(sp)
 b46:	e822                	sd	s0,16(sp)
 b48:	1000                	addi	s0,sp,32
 b4a:	e010                	sd	a2,0(s0)
 b4c:	e414                	sd	a3,8(s0)
 b4e:	e818                	sd	a4,16(s0)
 b50:	ec1c                	sd	a5,24(s0)
 b52:	03043023          	sd	a6,32(s0)
 b56:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 b5a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 b5e:	8622                	mv	a2,s0
 b60:	d4bff0ef          	jal	ra,8aa <vprintf>
}
 b64:	60e2                	ld	ra,24(sp)
 b66:	6442                	ld	s0,16(sp)
 b68:	6161                	addi	sp,sp,80
 b6a:	8082                	ret

0000000000000b6c <printf>:

void
printf(const char *fmt, ...)
{
 b6c:	711d                	addi	sp,sp,-96
 b6e:	ec06                	sd	ra,24(sp)
 b70:	e822                	sd	s0,16(sp)
 b72:	1000                	addi	s0,sp,32
 b74:	e40c                	sd	a1,8(s0)
 b76:	e810                	sd	a2,16(s0)
 b78:	ec14                	sd	a3,24(s0)
 b7a:	f018                	sd	a4,32(s0)
 b7c:	f41c                	sd	a5,40(s0)
 b7e:	03043823          	sd	a6,48(s0)
 b82:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 b86:	00840613          	addi	a2,s0,8
 b8a:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 b8e:	85aa                	mv	a1,a0
 b90:	4505                	li	a0,1
 b92:	d19ff0ef          	jal	ra,8aa <vprintf>
}
 b96:	60e2                	ld	ra,24(sp)
 b98:	6442                	ld	s0,16(sp)
 b9a:	6125                	addi	sp,sp,96
 b9c:	8082                	ret

0000000000000b9e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 b9e:	1141                	addi	sp,sp,-16
 ba0:	e422                	sd	s0,8(sp)
 ba2:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 ba4:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 ba8:	00001797          	auipc	a5,0x1
 bac:	4587b783          	ld	a5,1112(a5) # 2000 <freep>
 bb0:	a805                	j	be0 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 bb2:	4618                	lw	a4,8(a2)
 bb4:	9db9                	addw	a1,a1,a4
 bb6:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 bba:	6398                	ld	a4,0(a5)
 bbc:	6318                	ld	a4,0(a4)
 bbe:	fee53823          	sd	a4,-16(a0)
 bc2:	a091                	j	c06 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 bc4:	ff852703          	lw	a4,-8(a0)
 bc8:	9e39                	addw	a2,a2,a4
 bca:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 bcc:	ff053703          	ld	a4,-16(a0)
 bd0:	e398                	sd	a4,0(a5)
 bd2:	a099                	j	c18 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 bd4:	6398                	ld	a4,0(a5)
 bd6:	00e7e463          	bltu	a5,a4,bde <free+0x40>
 bda:	00e6ea63          	bltu	a3,a4,bee <free+0x50>
{
 bde:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 be0:	fed7fae3          	bgeu	a5,a3,bd4 <free+0x36>
 be4:	6398                	ld	a4,0(a5)
 be6:	00e6e463          	bltu	a3,a4,bee <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 bea:	fee7eae3          	bltu	a5,a4,bde <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 bee:	ff852583          	lw	a1,-8(a0)
 bf2:	6390                	ld	a2,0(a5)
 bf4:	02059713          	slli	a4,a1,0x20
 bf8:	9301                	srli	a4,a4,0x20
 bfa:	0712                	slli	a4,a4,0x4
 bfc:	9736                	add	a4,a4,a3
 bfe:	fae60ae3          	beq	a2,a4,bb2 <free+0x14>
    bp->s.ptr = p->s.ptr;
 c02:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 c06:	4790                	lw	a2,8(a5)
 c08:	02061713          	slli	a4,a2,0x20
 c0c:	9301                	srli	a4,a4,0x20
 c0e:	0712                	slli	a4,a4,0x4
 c10:	973e                	add	a4,a4,a5
 c12:	fae689e3          	beq	a3,a4,bc4 <free+0x26>
  } else
    p->s.ptr = bp;
 c16:	e394                	sd	a3,0(a5)
  freep = p;
 c18:	00001717          	auipc	a4,0x1
 c1c:	3ef73423          	sd	a5,1000(a4) # 2000 <freep>
}
 c20:	6422                	ld	s0,8(sp)
 c22:	0141                	addi	sp,sp,16
 c24:	8082                	ret

0000000000000c26 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 c26:	7139                	addi	sp,sp,-64
 c28:	fc06                	sd	ra,56(sp)
 c2a:	f822                	sd	s0,48(sp)
 c2c:	f426                	sd	s1,40(sp)
 c2e:	f04a                	sd	s2,32(sp)
 c30:	ec4e                	sd	s3,24(sp)
 c32:	e852                	sd	s4,16(sp)
 c34:	e456                	sd	s5,8(sp)
 c36:	e05a                	sd	s6,0(sp)
 c38:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 c3a:	02051493          	slli	s1,a0,0x20
 c3e:	9081                	srli	s1,s1,0x20
 c40:	04bd                	addi	s1,s1,15
 c42:	8091                	srli	s1,s1,0x4
 c44:	0014899b          	addiw	s3,s1,1
 c48:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 c4a:	00001517          	auipc	a0,0x1
 c4e:	3b653503          	ld	a0,950(a0) # 2000 <freep>
 c52:	c515                	beqz	a0,c7e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c54:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c56:	4798                	lw	a4,8(a5)
 c58:	02977f63          	bgeu	a4,s1,c96 <malloc+0x70>
 c5c:	8a4e                	mv	s4,s3
 c5e:	0009871b          	sext.w	a4,s3
 c62:	6685                	lui	a3,0x1
 c64:	00d77363          	bgeu	a4,a3,c6a <malloc+0x44>
 c68:	6a05                	lui	s4,0x1
 c6a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 c6e:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 c72:	00001917          	auipc	s2,0x1
 c76:	38e90913          	addi	s2,s2,910 # 2000 <freep>
  if(p == SBRK_ERROR)
 c7a:	5afd                	li	s5,-1
 c7c:	a0bd                	j	cea <malloc+0xc4>
    base.s.ptr = freep = prevp = &base;
 c7e:	00001797          	auipc	a5,0x1
 c82:	39278793          	addi	a5,a5,914 # 2010 <base>
 c86:	00001717          	auipc	a4,0x1
 c8a:	36f73d23          	sd	a5,890(a4) # 2000 <freep>
 c8e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 c90:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 c94:	b7e1                	j	c5c <malloc+0x36>
      if(p->s.size == nunits)
 c96:	02e48b63          	beq	s1,a4,ccc <malloc+0xa6>
        p->s.size -= nunits;
 c9a:	4137073b          	subw	a4,a4,s3
 c9e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 ca0:	1702                	slli	a4,a4,0x20
 ca2:	9301                	srli	a4,a4,0x20
 ca4:	0712                	slli	a4,a4,0x4
 ca6:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 ca8:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 cac:	00001717          	auipc	a4,0x1
 cb0:	34a73a23          	sd	a0,852(a4) # 2000 <freep>
      return (void*)(p + 1);
 cb4:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 cb8:	70e2                	ld	ra,56(sp)
 cba:	7442                	ld	s0,48(sp)
 cbc:	74a2                	ld	s1,40(sp)
 cbe:	7902                	ld	s2,32(sp)
 cc0:	69e2                	ld	s3,24(sp)
 cc2:	6a42                	ld	s4,16(sp)
 cc4:	6aa2                	ld	s5,8(sp)
 cc6:	6b02                	ld	s6,0(sp)
 cc8:	6121                	addi	sp,sp,64
 cca:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 ccc:	6398                	ld	a4,0(a5)
 cce:	e118                	sd	a4,0(a0)
 cd0:	bff1                	j	cac <malloc+0x86>
  hp->s.size = nu;
 cd2:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 cd6:	0541                	addi	a0,a0,16
 cd8:	ec7ff0ef          	jal	ra,b9e <free>
  return freep;
 cdc:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 ce0:	dd61                	beqz	a0,cb8 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 ce2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 ce4:	4798                	lw	a4,8(a5)
 ce6:	fa9778e3          	bgeu	a4,s1,c96 <malloc+0x70>
    if(p == freep)
 cea:	00093703          	ld	a4,0(s2)
 cee:	853e                	mv	a0,a5
 cf0:	fef719e3          	bne	a4,a5,ce2 <malloc+0xbc>
  p = sbrk(nu * sizeof(Header));
 cf4:	8552                	mv	a0,s4
 cf6:	a27ff0ef          	jal	ra,71c <sbrk>
  if(p == SBRK_ERROR)
 cfa:	fd551ce3          	bne	a0,s5,cd2 <malloc+0xac>
        return 0;
 cfe:	4501                	li	a0,0
 d00:	bf65                	j	cb8 <malloc+0x92>
