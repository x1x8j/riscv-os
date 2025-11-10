
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
   e:	dc650513          	addi	a0,a0,-570 # dd0 <malloc+0x1a2>
  12:	363000ef          	jal	ra,b74 <printf>

    int fd = open("testfile", O_CREATE | O_RDWR);
  16:	20200593          	li	a1,514
  1a:	00001517          	auipc	a0,0x1
  1e:	dde50513          	addi	a0,a0,-546 # df8 <malloc+0x1ca>
  22:	76e000ef          	jal	ra,790 <open>
    if (fd < 0) exit(1);
  26:	06054c63          	bltz	a0,9e <test_filesystem_integrity+0x9e>
  2a:	84aa                	mv	s1,a0
    write(fd, "OK", 2);
  2c:	4609                	li	a2,2
  2e:	00001597          	auipc	a1,0x1
  32:	dda58593          	addi	a1,a1,-550 # e08 <malloc+0x1da>
  36:	73a000ef          	jal	ra,770 <write>
    close(fd);
  3a:	8526                	mv	a0,s1
  3c:	73c000ef          	jal	ra,778 <close>

    fd = open("testfile", O_RDONLY);
  40:	4581                	li	a1,0
  42:	00001517          	auipc	a0,0x1
  46:	db650513          	addi	a0,a0,-586 # df8 <malloc+0x1ca>
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
  68:	d9450513          	addi	a0,a0,-620 # df8 <malloc+0x1ca>
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
  8c:	d8850513          	addi	a0,a0,-632 # e10 <malloc+0x1e2>
  90:	2e5000ef          	jal	ra,b74 <printf>
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
  c4:	d7850513          	addi	a0,a0,-648 # e38 <malloc+0x20a>
  c8:	2ad000ef          	jal	ra,b74 <printf>

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
  f8:	d7450513          	addi	a0,a0,-652 # e68 <malloc+0x23a>
  fc:	279000ef          	jal	ra,b74 <printf>
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
 114:	c0078793          	addi	a5,a5,-1024 # d10 <malloc+0xe2>
 118:	faf43823          	sd	a5,-80(s0)
 11c:	00001797          	auipc	a5,0x1
 120:	bfc78793          	addi	a5,a5,-1028 # d18 <malloc+0xea>
 124:	faf43c23          	sd	a5,-72(s0)
 128:	00001797          	auipc	a5,0x1
 12c:	bf878793          	addi	a5,a5,-1032 # d20 <malloc+0xf2>
 130:	fcf43023          	sd	a5,-64(s0)
 134:	00001797          	auipc	a5,0x1
 138:	bf478793          	addi	a5,a5,-1036 # d28 <malloc+0xfa>
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
 1a8:	cec50513          	addi	a0,a0,-788 # e90 <malloc+0x262>
 1ac:	1c9000ef          	jal	ra,b74 <printf>

    // 创建 partial_0 到 partial_9 → 改为创建 p0, p1, ..., p9
    const char* parts[] = {
 1b0:	00001797          	auipc	a5,0x1
 1b4:	e9078793          	addi	a5,a5,-368 # 1040 <malloc+0x412>
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
 208:	cbca0a13          	addi	s4,s4,-836 # ec0 <malloc+0x292>
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
 23a:	c9250513          	addi	a0,a0,-878 # ec8 <malloc+0x29a>
 23e:	137000ef          	jal	ra,b74 <printf>
    printf("Reboot to test recovery behavior.\n");
 242:	00001517          	auipc	a0,0x1
 246:	cc650513          	addi	a0,a0,-826 # f08 <malloc+0x2da>
 24a:	12b000ef          	jal	ra,b74 <printf>
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
 29c:	c9850513          	addi	a0,a0,-872 # f30 <malloc+0x302>
 2a0:	0d5000ef          	jal	ra,b74 <printf>

    int start = uptime();
 2a4:	544000ef          	jal	ra,7e8 <uptime>
 2a8:	8baa                	mv	s7,a0
    const char* smalls[] = {
 2aa:	00001797          	auipc	a5,0x1
 2ae:	d9678793          	addi	a5,a5,-618 # 1040 <malloc+0x412>
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
 300:	c64a8a93          	addi	s5,s5,-924 # f60 <malloc+0x332>
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
 352:	c1a50513          	addi	a0,a0,-998 # f68 <malloc+0x33a>
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
 39c:	bd850513          	addi	a0,a0,-1064 # f70 <malloc+0x342>
 3a0:	7d4000ef          	jal	ra,b74 <printf>
    printf("Big file (~100KB): %d ticks\n", time_big);
 3a4:	85da                	mv	a1,s6
 3a6:	00001517          	auipc	a0,0x1
 3aa:	bea50513          	addi	a0,a0,-1046 # f90 <malloc+0x362>
 3ae:	7c6000ef          	jal	ra,b74 <printf>

    // 清理
    for (int i = 0; i < 10; i++) unlink(smalls[i]);
 3b2:	000a3503          	ld	a0,0(s4)
 3b6:	3ea000ef          	jal	ra,7a0 <unlink>
 3ba:	0a21                	addi	s4,s4,8
 3bc:	ff3a1be3          	bne	s4,s3,3b2 <test_filesystem_performance+0x154>
    unlink("big");
 3c0:	00001517          	auipc	a0,0x1
 3c4:	ba850513          	addi	a0,a0,-1112 # f68 <malloc+0x33a>
 3c8:	3d8000ef          	jal	ra,7a0 <unlink>
    for (int i = 0; i < 10; i++) {
 3cc:	d4040493          	addi	s1,s0,-704
 3d0:	d9040d93          	addi	s11,s0,-624
        const char* pfiles[] = {"p0","p1","p2","p3","p4","p5","p6","p7","p8","p9"};
 3d4:	00001797          	auipc	a5,0x1
 3d8:	c6c78793          	addi	a5,a5,-916 # 1040 <malloc+0x412>
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
 442:	b7250513          	addi	a0,a0,-1166 # fb0 <malloc+0x382>
 446:	72e000ef          	jal	ra,b74 <printf>
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
 490:	b4450513          	addi	a0,a0,-1212 # fd0 <malloc+0x3a2>
 494:	6e0000ef          	jal	ra,b74 <printf>

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
 4ac:	b6850513          	addi	a0,a0,-1176 # 1010 <malloc+0x3e2>
 4b0:	6c4000ef          	jal	ra,b74 <printf>
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

00000000000007f0 <dump_proc>:
.global dump_proc
dump_proc:
 li a7, SYS_dump_proc
 7f0:	48d9                	li	a7,22
 ecall
 7f2:	00000073          	ecall
 ret
 7f6:	8082                	ret

00000000000007f8 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 7f8:	1101                	addi	sp,sp,-32
 7fa:	ec06                	sd	ra,24(sp)
 7fc:	e822                	sd	s0,16(sp)
 7fe:	1000                	addi	s0,sp,32
 800:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 804:	4605                	li	a2,1
 806:	fef40593          	addi	a1,s0,-17
 80a:	f67ff0ef          	jal	ra,770 <write>
}
 80e:	60e2                	ld	ra,24(sp)
 810:	6442                	ld	s0,16(sp)
 812:	6105                	addi	sp,sp,32
 814:	8082                	ret

0000000000000816 <printint>:

static void
printint(int fd, long long xx, int base, int sgn)
{
 816:	715d                	addi	sp,sp,-80
 818:	e486                	sd	ra,72(sp)
 81a:	e0a2                	sd	s0,64(sp)
 81c:	fc26                	sd	s1,56(sp)
 81e:	f84a                	sd	s2,48(sp)
 820:	f44e                	sd	s3,40(sp)
 822:	0880                	addi	s0,sp,80
 824:	892a                	mv	s2,a0
  char buf[20];
  int i, neg;
  unsigned long long x;

  neg = 0;
  if(sgn && xx < 0){
 826:	c299                	beqz	a3,82c <printint+0x16>
 828:	0805c163          	bltz	a1,8aa <printint+0x94>
  neg = 0;
 82c:	4881                	li	a7,0
 82e:	fb840693          	addi	a3,s0,-72
    x = -xx;
  } else {
    x = xx;
  }

  i = 0;
 832:	4781                	li	a5,0
  do{
    buf[i++] = digits[x % base];
 834:	00001517          	auipc	a0,0x1
 838:	8b450513          	addi	a0,a0,-1868 # 10e8 <digits>
 83c:	883e                	mv	a6,a5
 83e:	2785                	addiw	a5,a5,1
 840:	02c5f733          	remu	a4,a1,a2
 844:	972a                	add	a4,a4,a0
 846:	00074703          	lbu	a4,0(a4)
 84a:	00e68023          	sb	a4,0(a3)
  }while((x /= base) != 0);
 84e:	872e                	mv	a4,a1
 850:	02c5d5b3          	divu	a1,a1,a2
 854:	0685                	addi	a3,a3,1
 856:	fec773e3          	bgeu	a4,a2,83c <printint+0x26>
  if(neg)
 85a:	00088b63          	beqz	a7,870 <printint+0x5a>
    buf[i++] = '-';
 85e:	fd040713          	addi	a4,s0,-48
 862:	97ba                	add	a5,a5,a4
 864:	02d00713          	li	a4,45
 868:	fee78423          	sb	a4,-24(a5)
 86c:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
 870:	02f05663          	blez	a5,89c <printint+0x86>
 874:	fb840713          	addi	a4,s0,-72
 878:	00f704b3          	add	s1,a4,a5
 87c:	fff70993          	addi	s3,a4,-1
 880:	99be                	add	s3,s3,a5
 882:	37fd                	addiw	a5,a5,-1
 884:	1782                	slli	a5,a5,0x20
 886:	9381                	srli	a5,a5,0x20
 888:	40f989b3          	sub	s3,s3,a5
    putc(fd, buf[i]);
 88c:	fff4c583          	lbu	a1,-1(s1)
 890:	854a                	mv	a0,s2
 892:	f67ff0ef          	jal	ra,7f8 <putc>
  while(--i >= 0)
 896:	14fd                	addi	s1,s1,-1
 898:	ff349ae3          	bne	s1,s3,88c <printint+0x76>
}
 89c:	60a6                	ld	ra,72(sp)
 89e:	6406                	ld	s0,64(sp)
 8a0:	74e2                	ld	s1,56(sp)
 8a2:	7942                	ld	s2,48(sp)
 8a4:	79a2                	ld	s3,40(sp)
 8a6:	6161                	addi	sp,sp,80
 8a8:	8082                	ret
    x = -xx;
 8aa:	40b005b3          	neg	a1,a1
    neg = 1;
 8ae:	4885                	li	a7,1
    x = -xx;
 8b0:	bfbd                	j	82e <printint+0x18>

00000000000008b2 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %c, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 8b2:	7119                	addi	sp,sp,-128
 8b4:	fc86                	sd	ra,120(sp)
 8b6:	f8a2                	sd	s0,112(sp)
 8b8:	f4a6                	sd	s1,104(sp)
 8ba:	f0ca                	sd	s2,96(sp)
 8bc:	ecce                	sd	s3,88(sp)
 8be:	e8d2                	sd	s4,80(sp)
 8c0:	e4d6                	sd	s5,72(sp)
 8c2:	e0da                	sd	s6,64(sp)
 8c4:	fc5e                	sd	s7,56(sp)
 8c6:	f862                	sd	s8,48(sp)
 8c8:	f466                	sd	s9,40(sp)
 8ca:	f06a                	sd	s10,32(sp)
 8cc:	ec6e                	sd	s11,24(sp)
 8ce:	0100                	addi	s0,sp,128
  char *s;
  int c0, c1, c2, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 8d0:	0005c903          	lbu	s2,0(a1)
 8d4:	24090c63          	beqz	s2,b2c <vprintf+0x27a>
 8d8:	8b2a                	mv	s6,a0
 8da:	8a2e                	mv	s4,a1
 8dc:	8bb2                	mv	s7,a2
  state = 0;
 8de:	4981                	li	s3,0
  for(i = 0; fmt[i]; i++){
 8e0:	4481                	li	s1,0
 8e2:	4701                	li	a4,0
      if(c0 == '%'){
        state = '%';
      } else {
        putc(fd, c0);
      }
    } else if(state == '%'){
 8e4:	02500a93          	li	s5,37
      c1 = c2 = 0;
      if(c0) c1 = fmt[i+1] & 0xff;
      if(c1) c2 = fmt[i+2] & 0xff;
      if(c0 == 'd'){
 8e8:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c0 == 'l' && c1 == 'd'){
 8ec:	06c00d13          	li	s10,108
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 2;
      } else if(c0 == 'u'){
 8f0:	07500d93          	li	s11,117
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 8f4:	00000c97          	auipc	s9,0x0
 8f8:	7f4c8c93          	addi	s9,s9,2036 # 10e8 <digits>
 8fc:	a005                	j	91c <vprintf+0x6a>
        putc(fd, c0);
 8fe:	85ca                	mv	a1,s2
 900:	855a                	mv	a0,s6
 902:	ef7ff0ef          	jal	ra,7f8 <putc>
 906:	a019                	j	90c <vprintf+0x5a>
    } else if(state == '%'){
 908:	03598263          	beq	s3,s5,92c <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 90c:	2485                	addiw	s1,s1,1
 90e:	8726                	mv	a4,s1
 910:	009a07b3          	add	a5,s4,s1
 914:	0007c903          	lbu	s2,0(a5)
 918:	20090a63          	beqz	s2,b2c <vprintf+0x27a>
    c0 = fmt[i] & 0xff;
 91c:	0009079b          	sext.w	a5,s2
    if(state == 0){
 920:	fe0994e3          	bnez	s3,908 <vprintf+0x56>
      if(c0 == '%'){
 924:	fd579de3          	bne	a5,s5,8fe <vprintf+0x4c>
        state = '%';
 928:	89be                	mv	s3,a5
 92a:	b7cd                	j	90c <vprintf+0x5a>
      if(c0) c1 = fmt[i+1] & 0xff;
 92c:	c3c1                	beqz	a5,9ac <vprintf+0xfa>
 92e:	00ea06b3          	add	a3,s4,a4
 932:	0016c683          	lbu	a3,1(a3)
      c1 = c2 = 0;
 936:	8636                	mv	a2,a3
      if(c1) c2 = fmt[i+2] & 0xff;
 938:	c681                	beqz	a3,940 <vprintf+0x8e>
 93a:	9752                	add	a4,a4,s4
 93c:	00274603          	lbu	a2,2(a4)
      if(c0 == 'd'){
 940:	03878e63          	beq	a5,s8,97c <vprintf+0xca>
      } else if(c0 == 'l' && c1 == 'd'){
 944:	05a78863          	beq	a5,s10,994 <vprintf+0xe2>
      } else if(c0 == 'u'){
 948:	0db78b63          	beq	a5,s11,a1e <vprintf+0x16c>
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 2;
      } else if(c0 == 'x'){
 94c:	07800713          	li	a4,120
 950:	10e78d63          	beq	a5,a4,a6a <vprintf+0x1b8>
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 2;
      } else if(c0 == 'p'){
 954:	07000713          	li	a4,112
 958:	14e78263          	beq	a5,a4,a9c <vprintf+0x1ea>
        printptr(fd, va_arg(ap, uint64));
      } else if(c0 == 'c'){
 95c:	06300713          	li	a4,99
 960:	16e78f63          	beq	a5,a4,ade <vprintf+0x22c>
        putc(fd, va_arg(ap, uint32));
      } else if(c0 == 's'){
 964:	07300713          	li	a4,115
 968:	18e78563          	beq	a5,a4,af2 <vprintf+0x240>
        if((s = va_arg(ap, char*)) == 0)
          s = "(null)";
        for(; *s; s++)
          putc(fd, *s);
      } else if(c0 == '%'){
 96c:	05579063          	bne	a5,s5,9ac <vprintf+0xfa>
        putc(fd, '%');
 970:	85d6                	mv	a1,s5
 972:	855a                	mv	a0,s6
 974:	e85ff0ef          	jal	ra,7f8 <putc>
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c0);
      }

      state = 0;
 978:	4981                	li	s3,0
 97a:	bf49                	j	90c <vprintf+0x5a>
        printint(fd, va_arg(ap, int), 10, 1);
 97c:	008b8913          	addi	s2,s7,8
 980:	4685                	li	a3,1
 982:	4629                	li	a2,10
 984:	000ba583          	lw	a1,0(s7)
 988:	855a                	mv	a0,s6
 98a:	e8dff0ef          	jal	ra,816 <printint>
 98e:	8bca                	mv	s7,s2
      state = 0;
 990:	4981                	li	s3,0
 992:	bfad                	j	90c <vprintf+0x5a>
      } else if(c0 == 'l' && c1 == 'd'){
 994:	03868663          	beq	a3,s8,9c0 <vprintf+0x10e>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 998:	05a68163          	beq	a3,s10,9da <vprintf+0x128>
      } else if(c0 == 'l' && c1 == 'u'){
 99c:	09b68d63          	beq	a3,s11,a36 <vprintf+0x184>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 9a0:	03a68f63          	beq	a3,s10,9de <vprintf+0x12c>
      } else if(c0 == 'l' && c1 == 'x'){
 9a4:	07800793          	li	a5,120
 9a8:	0cf68d63          	beq	a3,a5,a82 <vprintf+0x1d0>
        putc(fd, '%');
 9ac:	85d6                	mv	a1,s5
 9ae:	855a                	mv	a0,s6
 9b0:	e49ff0ef          	jal	ra,7f8 <putc>
        putc(fd, c0);
 9b4:	85ca                	mv	a1,s2
 9b6:	855a                	mv	a0,s6
 9b8:	e41ff0ef          	jal	ra,7f8 <putc>
      state = 0;
 9bc:	4981                	li	s3,0
 9be:	b7b9                	j	90c <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 9c0:	008b8913          	addi	s2,s7,8
 9c4:	4685                	li	a3,1
 9c6:	4629                	li	a2,10
 9c8:	000bb583          	ld	a1,0(s7)
 9cc:	855a                	mv	a0,s6
 9ce:	e49ff0ef          	jal	ra,816 <printint>
        i += 1;
 9d2:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 1);
 9d4:	8bca                	mv	s7,s2
      state = 0;
 9d6:	4981                	li	s3,0
        i += 1;
 9d8:	bf15                	j	90c <vprintf+0x5a>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 9da:	03860563          	beq	a2,s8,a04 <vprintf+0x152>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 9de:	07b60963          	beq	a2,s11,a50 <vprintf+0x19e>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
 9e2:	07800793          	li	a5,120
 9e6:	fcf613e3          	bne	a2,a5,9ac <vprintf+0xfa>
        printint(fd, va_arg(ap, uint64), 16, 0);
 9ea:	008b8913          	addi	s2,s7,8
 9ee:	4681                	li	a3,0
 9f0:	4641                	li	a2,16
 9f2:	000bb583          	ld	a1,0(s7)
 9f6:	855a                	mv	a0,s6
 9f8:	e1fff0ef          	jal	ra,816 <printint>
        i += 2;
 9fc:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 16, 0);
 9fe:	8bca                	mv	s7,s2
      state = 0;
 a00:	4981                	li	s3,0
        i += 2;
 a02:	b729                	j	90c <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 a04:	008b8913          	addi	s2,s7,8
 a08:	4685                	li	a3,1
 a0a:	4629                	li	a2,10
 a0c:	000bb583          	ld	a1,0(s7)
 a10:	855a                	mv	a0,s6
 a12:	e05ff0ef          	jal	ra,816 <printint>
        i += 2;
 a16:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 1);
 a18:	8bca                	mv	s7,s2
      state = 0;
 a1a:	4981                	li	s3,0
        i += 2;
 a1c:	bdc5                	j	90c <vprintf+0x5a>
        printint(fd, va_arg(ap, uint32), 10, 0);
 a1e:	008b8913          	addi	s2,s7,8
 a22:	4681                	li	a3,0
 a24:	4629                	li	a2,10
 a26:	000be583          	lwu	a1,0(s7)
 a2a:	855a                	mv	a0,s6
 a2c:	debff0ef          	jal	ra,816 <printint>
 a30:	8bca                	mv	s7,s2
      state = 0;
 a32:	4981                	li	s3,0
 a34:	bde1                	j	90c <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 a36:	008b8913          	addi	s2,s7,8
 a3a:	4681                	li	a3,0
 a3c:	4629                	li	a2,10
 a3e:	000bb583          	ld	a1,0(s7)
 a42:	855a                	mv	a0,s6
 a44:	dd3ff0ef          	jal	ra,816 <printint>
        i += 1;
 a48:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 0);
 a4a:	8bca                	mv	s7,s2
      state = 0;
 a4c:	4981                	li	s3,0
        i += 1;
 a4e:	bd7d                	j	90c <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 a50:	008b8913          	addi	s2,s7,8
 a54:	4681                	li	a3,0
 a56:	4629                	li	a2,10
 a58:	000bb583          	ld	a1,0(s7)
 a5c:	855a                	mv	a0,s6
 a5e:	db9ff0ef          	jal	ra,816 <printint>
        i += 2;
 a62:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 0);
 a64:	8bca                	mv	s7,s2
      state = 0;
 a66:	4981                	li	s3,0
        i += 2;
 a68:	b555                	j	90c <vprintf+0x5a>
        printint(fd, va_arg(ap, uint32), 16, 0);
 a6a:	008b8913          	addi	s2,s7,8
 a6e:	4681                	li	a3,0
 a70:	4641                	li	a2,16
 a72:	000be583          	lwu	a1,0(s7)
 a76:	855a                	mv	a0,s6
 a78:	d9fff0ef          	jal	ra,816 <printint>
 a7c:	8bca                	mv	s7,s2
      state = 0;
 a7e:	4981                	li	s3,0
 a80:	b571                	j	90c <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 16, 0);
 a82:	008b8913          	addi	s2,s7,8
 a86:	4681                	li	a3,0
 a88:	4641                	li	a2,16
 a8a:	000bb583          	ld	a1,0(s7)
 a8e:	855a                	mv	a0,s6
 a90:	d87ff0ef          	jal	ra,816 <printint>
        i += 1;
 a94:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 16, 0);
 a96:	8bca                	mv	s7,s2
      state = 0;
 a98:	4981                	li	s3,0
        i += 1;
 a9a:	bd8d                	j	90c <vprintf+0x5a>
        printptr(fd, va_arg(ap, uint64));
 a9c:	008b8793          	addi	a5,s7,8
 aa0:	f8f43423          	sd	a5,-120(s0)
 aa4:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 aa8:	03000593          	li	a1,48
 aac:	855a                	mv	a0,s6
 aae:	d4bff0ef          	jal	ra,7f8 <putc>
  putc(fd, 'x');
 ab2:	07800593          	li	a1,120
 ab6:	855a                	mv	a0,s6
 ab8:	d41ff0ef          	jal	ra,7f8 <putc>
 abc:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 abe:	03c9d793          	srli	a5,s3,0x3c
 ac2:	97e6                	add	a5,a5,s9
 ac4:	0007c583          	lbu	a1,0(a5)
 ac8:	855a                	mv	a0,s6
 aca:	d2fff0ef          	jal	ra,7f8 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 ace:	0992                	slli	s3,s3,0x4
 ad0:	397d                	addiw	s2,s2,-1
 ad2:	fe0916e3          	bnez	s2,abe <vprintf+0x20c>
        printptr(fd, va_arg(ap, uint64));
 ad6:	f8843b83          	ld	s7,-120(s0)
      state = 0;
 ada:	4981                	li	s3,0
 adc:	bd05                	j	90c <vprintf+0x5a>
        putc(fd, va_arg(ap, uint32));
 ade:	008b8913          	addi	s2,s7,8
 ae2:	000bc583          	lbu	a1,0(s7)
 ae6:	855a                	mv	a0,s6
 ae8:	d11ff0ef          	jal	ra,7f8 <putc>
 aec:	8bca                	mv	s7,s2
      state = 0;
 aee:	4981                	li	s3,0
 af0:	bd31                	j	90c <vprintf+0x5a>
        if((s = va_arg(ap, char*)) == 0)
 af2:	008b8993          	addi	s3,s7,8
 af6:	000bb903          	ld	s2,0(s7)
 afa:	00090f63          	beqz	s2,b18 <vprintf+0x266>
        for(; *s; s++)
 afe:	00094583          	lbu	a1,0(s2)
 b02:	c195                	beqz	a1,b26 <vprintf+0x274>
          putc(fd, *s);
 b04:	855a                	mv	a0,s6
 b06:	cf3ff0ef          	jal	ra,7f8 <putc>
        for(; *s; s++)
 b0a:	0905                	addi	s2,s2,1
 b0c:	00094583          	lbu	a1,0(s2)
 b10:	f9f5                	bnez	a1,b04 <vprintf+0x252>
        if((s = va_arg(ap, char*)) == 0)
 b12:	8bce                	mv	s7,s3
      state = 0;
 b14:	4981                	li	s3,0
 b16:	bbdd                	j	90c <vprintf+0x5a>
          s = "(null)";
 b18:	00000917          	auipc	s2,0x0
 b1c:	5c890913          	addi	s2,s2,1480 # 10e0 <malloc+0x4b2>
        for(; *s; s++)
 b20:	02800593          	li	a1,40
 b24:	b7c5                	j	b04 <vprintf+0x252>
        if((s = va_arg(ap, char*)) == 0)
 b26:	8bce                	mv	s7,s3
      state = 0;
 b28:	4981                	li	s3,0
 b2a:	b3cd                	j	90c <vprintf+0x5a>
    }
  }
}
 b2c:	70e6                	ld	ra,120(sp)
 b2e:	7446                	ld	s0,112(sp)
 b30:	74a6                	ld	s1,104(sp)
 b32:	7906                	ld	s2,96(sp)
 b34:	69e6                	ld	s3,88(sp)
 b36:	6a46                	ld	s4,80(sp)
 b38:	6aa6                	ld	s5,72(sp)
 b3a:	6b06                	ld	s6,64(sp)
 b3c:	7be2                	ld	s7,56(sp)
 b3e:	7c42                	ld	s8,48(sp)
 b40:	7ca2                	ld	s9,40(sp)
 b42:	7d02                	ld	s10,32(sp)
 b44:	6de2                	ld	s11,24(sp)
 b46:	6109                	addi	sp,sp,128
 b48:	8082                	ret

0000000000000b4a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 b4a:	715d                	addi	sp,sp,-80
 b4c:	ec06                	sd	ra,24(sp)
 b4e:	e822                	sd	s0,16(sp)
 b50:	1000                	addi	s0,sp,32
 b52:	e010                	sd	a2,0(s0)
 b54:	e414                	sd	a3,8(s0)
 b56:	e818                	sd	a4,16(s0)
 b58:	ec1c                	sd	a5,24(s0)
 b5a:	03043023          	sd	a6,32(s0)
 b5e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 b62:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 b66:	8622                	mv	a2,s0
 b68:	d4bff0ef          	jal	ra,8b2 <vprintf>
}
 b6c:	60e2                	ld	ra,24(sp)
 b6e:	6442                	ld	s0,16(sp)
 b70:	6161                	addi	sp,sp,80
 b72:	8082                	ret

0000000000000b74 <printf>:

void
printf(const char *fmt, ...)
{
 b74:	711d                	addi	sp,sp,-96
 b76:	ec06                	sd	ra,24(sp)
 b78:	e822                	sd	s0,16(sp)
 b7a:	1000                	addi	s0,sp,32
 b7c:	e40c                	sd	a1,8(s0)
 b7e:	e810                	sd	a2,16(s0)
 b80:	ec14                	sd	a3,24(s0)
 b82:	f018                	sd	a4,32(s0)
 b84:	f41c                	sd	a5,40(s0)
 b86:	03043823          	sd	a6,48(s0)
 b8a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 b8e:	00840613          	addi	a2,s0,8
 b92:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 b96:	85aa                	mv	a1,a0
 b98:	4505                	li	a0,1
 b9a:	d19ff0ef          	jal	ra,8b2 <vprintf>
}
 b9e:	60e2                	ld	ra,24(sp)
 ba0:	6442                	ld	s0,16(sp)
 ba2:	6125                	addi	sp,sp,96
 ba4:	8082                	ret

0000000000000ba6 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 ba6:	1141                	addi	sp,sp,-16
 ba8:	e422                	sd	s0,8(sp)
 baa:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 bac:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 bb0:	00001797          	auipc	a5,0x1
 bb4:	4507b783          	ld	a5,1104(a5) # 2000 <freep>
 bb8:	a805                	j	be8 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 bba:	4618                	lw	a4,8(a2)
 bbc:	9db9                	addw	a1,a1,a4
 bbe:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 bc2:	6398                	ld	a4,0(a5)
 bc4:	6318                	ld	a4,0(a4)
 bc6:	fee53823          	sd	a4,-16(a0)
 bca:	a091                	j	c0e <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 bcc:	ff852703          	lw	a4,-8(a0)
 bd0:	9e39                	addw	a2,a2,a4
 bd2:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 bd4:	ff053703          	ld	a4,-16(a0)
 bd8:	e398                	sd	a4,0(a5)
 bda:	a099                	j	c20 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 bdc:	6398                	ld	a4,0(a5)
 bde:	00e7e463          	bltu	a5,a4,be6 <free+0x40>
 be2:	00e6ea63          	bltu	a3,a4,bf6 <free+0x50>
{
 be6:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 be8:	fed7fae3          	bgeu	a5,a3,bdc <free+0x36>
 bec:	6398                	ld	a4,0(a5)
 bee:	00e6e463          	bltu	a3,a4,bf6 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 bf2:	fee7eae3          	bltu	a5,a4,be6 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 bf6:	ff852583          	lw	a1,-8(a0)
 bfa:	6390                	ld	a2,0(a5)
 bfc:	02059713          	slli	a4,a1,0x20
 c00:	9301                	srli	a4,a4,0x20
 c02:	0712                	slli	a4,a4,0x4
 c04:	9736                	add	a4,a4,a3
 c06:	fae60ae3          	beq	a2,a4,bba <free+0x14>
    bp->s.ptr = p->s.ptr;
 c0a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 c0e:	4790                	lw	a2,8(a5)
 c10:	02061713          	slli	a4,a2,0x20
 c14:	9301                	srli	a4,a4,0x20
 c16:	0712                	slli	a4,a4,0x4
 c18:	973e                	add	a4,a4,a5
 c1a:	fae689e3          	beq	a3,a4,bcc <free+0x26>
  } else
    p->s.ptr = bp;
 c1e:	e394                	sd	a3,0(a5)
  freep = p;
 c20:	00001717          	auipc	a4,0x1
 c24:	3ef73023          	sd	a5,992(a4) # 2000 <freep>
}
 c28:	6422                	ld	s0,8(sp)
 c2a:	0141                	addi	sp,sp,16
 c2c:	8082                	ret

0000000000000c2e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 c2e:	7139                	addi	sp,sp,-64
 c30:	fc06                	sd	ra,56(sp)
 c32:	f822                	sd	s0,48(sp)
 c34:	f426                	sd	s1,40(sp)
 c36:	f04a                	sd	s2,32(sp)
 c38:	ec4e                	sd	s3,24(sp)
 c3a:	e852                	sd	s4,16(sp)
 c3c:	e456                	sd	s5,8(sp)
 c3e:	e05a                	sd	s6,0(sp)
 c40:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 c42:	02051493          	slli	s1,a0,0x20
 c46:	9081                	srli	s1,s1,0x20
 c48:	04bd                	addi	s1,s1,15
 c4a:	8091                	srli	s1,s1,0x4
 c4c:	0014899b          	addiw	s3,s1,1
 c50:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 c52:	00001517          	auipc	a0,0x1
 c56:	3ae53503          	ld	a0,942(a0) # 2000 <freep>
 c5a:	c515                	beqz	a0,c86 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c5c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c5e:	4798                	lw	a4,8(a5)
 c60:	02977f63          	bgeu	a4,s1,c9e <malloc+0x70>
 c64:	8a4e                	mv	s4,s3
 c66:	0009871b          	sext.w	a4,s3
 c6a:	6685                	lui	a3,0x1
 c6c:	00d77363          	bgeu	a4,a3,c72 <malloc+0x44>
 c70:	6a05                	lui	s4,0x1
 c72:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 c76:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 c7a:	00001917          	auipc	s2,0x1
 c7e:	38690913          	addi	s2,s2,902 # 2000 <freep>
  if(p == SBRK_ERROR)
 c82:	5afd                	li	s5,-1
 c84:	a0bd                	j	cf2 <malloc+0xc4>
    base.s.ptr = freep = prevp = &base;
 c86:	00001797          	auipc	a5,0x1
 c8a:	38a78793          	addi	a5,a5,906 # 2010 <base>
 c8e:	00001717          	auipc	a4,0x1
 c92:	36f73923          	sd	a5,882(a4) # 2000 <freep>
 c96:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 c98:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 c9c:	b7e1                	j	c64 <malloc+0x36>
      if(p->s.size == nunits)
 c9e:	02e48b63          	beq	s1,a4,cd4 <malloc+0xa6>
        p->s.size -= nunits;
 ca2:	4137073b          	subw	a4,a4,s3
 ca6:	c798                	sw	a4,8(a5)
        p += p->s.size;
 ca8:	1702                	slli	a4,a4,0x20
 caa:	9301                	srli	a4,a4,0x20
 cac:	0712                	slli	a4,a4,0x4
 cae:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 cb0:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 cb4:	00001717          	auipc	a4,0x1
 cb8:	34a73623          	sd	a0,844(a4) # 2000 <freep>
      return (void*)(p + 1);
 cbc:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 cc0:	70e2                	ld	ra,56(sp)
 cc2:	7442                	ld	s0,48(sp)
 cc4:	74a2                	ld	s1,40(sp)
 cc6:	7902                	ld	s2,32(sp)
 cc8:	69e2                	ld	s3,24(sp)
 cca:	6a42                	ld	s4,16(sp)
 ccc:	6aa2                	ld	s5,8(sp)
 cce:	6b02                	ld	s6,0(sp)
 cd0:	6121                	addi	sp,sp,64
 cd2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 cd4:	6398                	ld	a4,0(a5)
 cd6:	e118                	sd	a4,0(a0)
 cd8:	bff1                	j	cb4 <malloc+0x86>
  hp->s.size = nu;
 cda:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 cde:	0541                	addi	a0,a0,16
 ce0:	ec7ff0ef          	jal	ra,ba6 <free>
  return freep;
 ce4:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 ce8:	dd61                	beqz	a0,cc0 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 cea:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 cec:	4798                	lw	a4,8(a5)
 cee:	fa9778e3          	bgeu	a4,s1,c9e <malloc+0x70>
    if(p == freep)
 cf2:	00093703          	ld	a4,0(s2)
 cf6:	853e                	mv	a0,a5
 cf8:	fef719e3          	bne	a4,a5,cea <malloc+0xbc>
  p = sbrk(nu * sizeof(Header));
 cfc:	8552                	mv	a0,s4
 cfe:	a1fff0ef          	jal	ra,71c <sbrk>
  if(p == SBRK_ERROR)
 d02:	fd551ce3          	bne	a0,s5,cda <malloc+0xac>
        return 0;
 d06:	4501                	li	a0,0
 d08:	bf65                	j	cc0 <malloc+0x92>
