
user/_proctest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <delay>:
#define MAX_TEST_PROC 8      // 进程创建测试的最大尝试数

void debug_proc_table(void);

// 忙等待模拟 sleep（单位：时钟滴答）
void delay(int ticks) {
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
   c:	892a                	mv	s2,a0
    int start = uptime();
   e:	051000ef          	jal	ra,85e <uptime>
  12:	84aa                	mv	s1,a0
    while (uptime() - start < ticks)
  14:	04b000ef          	jal	ra,85e <uptime>
  18:	9d05                	subw	a0,a0,s1
  1a:	ff254de3          	blt	a0,s2,14 <delay+0x14>
        ;
}
  1e:	60e2                	ld	ra,24(sp)
  20:	6442                	ld	s0,16(sp)
  22:	64a2                	ld	s1,8(sp)
  24:	6902                	ld	s2,0(sp)
  26:	6105                	addi	sp,sp,32
  28:	8082                	ret

000000000000002a <itoa>:

// 手动将非负整数转为字符串（buf 至少 12 字节）
void itoa(int n, char *buf) {
    if (n == 0) {
  2a:	c53d                	beqz	a0,98 <itoa+0x6e>
void itoa(int n, char *buf) {
  2c:	1101                	addi	sp,sp,-32
  2e:	ec22                	sd	s0,24(sp)
  30:	1000                	addi	s0,sp,32
        buf[1] = '\0';
        return;
    }
    int i = 0;
    char temp[12];
    while (n > 0) {
  32:	fe040693          	addi	a3,s0,-32
    int i = 0;
  36:	4701                	li	a4,0
        temp[i++] = '0' + (n % 10);
  38:	4629                	li	a2,10
    while (n > 0) {
  3a:	48a5                	li	a7,9
  3c:	04a05863          	blez	a0,8c <itoa+0x62>
        temp[i++] = '0' + (n % 10);
  40:	883a                	mv	a6,a4
  42:	2705                	addiw	a4,a4,1
  44:	02c567bb          	remw	a5,a0,a2
  48:	0307879b          	addiw	a5,a5,48
  4c:	00f68023          	sb	a5,0(a3)
        n /= 10;
  50:	87aa                	mv	a5,a0
  52:	02c5453b          	divw	a0,a0,a2
    while (n > 0) {
  56:	0685                	addi	a3,a3,1
  58:	fef8c4e3          	blt	a7,a5,40 <itoa+0x16>
    }
    temp[i] = '\0';
  5c:	ff040793          	addi	a5,s0,-16
  60:	97ba                	add	a5,a5,a4
  62:	fe078823          	sb	zero,-16(a5)

    // 反转
    int len = i;
    for (int j = 0; j < len; j++) {
  66:	02e05363          	blez	a4,8c <itoa+0x62>
  6a:	fe040793          	addi	a5,s0,-32
  6e:	010786b3          	add	a3,a5,a6
  72:	87ae                	mv	a5,a1
  74:	fff5c513          	not	a0,a1
        buf[j] = temp[len - 1 - j];
  78:	0006c603          	lbu	a2,0(a3)
  7c:	00c78023          	sb	a2,0(a5)
    for (int j = 0; j < len; j++) {
  80:	16fd                	addi	a3,a3,-1
  82:	0785                	addi	a5,a5,1
  84:	00f5063b          	addw	a2,a0,a5
  88:	ff0648e3          	blt	a2,a6,78 <itoa+0x4e>
    }
    buf[len] = '\0';
  8c:	95ba                	add	a1,a1,a4
  8e:	00058023          	sb	zero,0(a1)
}
  92:	6462                	ld	s0,24(sp)
  94:	6105                	addi	sp,sp,32
  96:	8082                	ret
        buf[0] = '0';
  98:	03000793          	li	a5,48
  9c:	00f58023          	sb	a5,0(a1)
        buf[1] = '\0';
  a0:	000580a3          	sb	zero,1(a1)
        return;
  a4:	8082                	ret

00000000000000a6 <simple_task>:

// ==========================
// 1. 简单任务
// ==========================
void simple_task(void) {
  a6:	1141                	addi	sp,sp,-16
  a8:	e406                	sd	ra,8(sp)
  aa:	e022                	sd	s0,0(sp)
  ac:	0800                	addi	s0,sp,16
    printf("Simple task running\n");
  ae:	00001517          	auipc	a0,0x1
  b2:	cd250513          	addi	a0,a0,-814 # d80 <malloc+0xdc>
  b6:	335000ef          	jal	ra,bea <printf>
//    debug_proc_table();
    exit(0);
  ba:	4501                	li	a0,0
  bc:	70a000ef          	jal	ra,7c6 <exit>

00000000000000c0 <cpu_intensive_task>:
}

// ==========================
// 2. CPU 密集型任务（忙循环）
// ==========================
void cpu_intensive_task(void) {
  c0:	1101                	addi	sp,sp,-32
  c2:	ec06                	sd	ra,24(sp)
  c4:	e822                	sd	s0,16(sp)
  c6:	1000                	addi	s0,sp,32
    volatile long sum = 0;
  c8:	fe043423          	sd	zero,-24(s0)
    for (long i = 0; i < 500000; i++) {
  cc:	4781                	li	a5,0
  ce:	0007a6b7          	lui	a3,0x7a
  d2:	12068693          	addi	a3,a3,288 # 7a120 <base+0x78110>
        sum += i;
  d6:	fe843703          	ld	a4,-24(s0)
  da:	973e                	add	a4,a4,a5
  dc:	fee43423          	sd	a4,-24(s0)
    for (long i = 0; i < 500000; i++) {
  e0:	0785                	addi	a5,a5,1
  e2:	fed79ae3          	bne	a5,a3,d6 <cpu_intensive_task+0x16>
    }
    printf("CPU task computed sum = %d\n", (int)(sum % 1000000));
  e6:	fe843583          	ld	a1,-24(s0)
  ea:	000f47b7          	lui	a5,0xf4
  ee:	24078793          	addi	a5,a5,576 # f4240 <base+0xf2230>
  f2:	02f5e5b3          	rem	a1,a1,a5
  f6:	00001517          	auipc	a0,0x1
  fa:	ca250513          	addi	a0,a0,-862 # d98 <malloc+0xf4>
  fe:	2ed000ef          	jal	ra,bea <printf>
    exit(0);
 102:	4501                	li	a0,0
 104:	6c2000ef          	jal	ra,7c6 <exit>

0000000000000108 <producer_task>:
}

// ==========================
// 3. 生产者任务（通过 pipe）
// ==========================
void producer_task(int write_fd) {
 108:	7179                	addi	sp,sp,-48
 10a:	f406                	sd	ra,40(sp)
 10c:	f022                	sd	s0,32(sp)
 10e:	ec26                	sd	s1,24(sp)
 110:	e84a                	sd	s2,16(sp)
 112:	1800                	addi	s0,sp,48
 114:	84aa                	mv	s1,a0
    for (int i = 0; i < 5; i++) {
 116:	fc042e23          	sw	zero,-36(s0)
        write(write_fd, &i, sizeof(i));
        printf("Produced: %d\n", i);
 11a:	00001917          	auipc	s2,0x1
 11e:	c9e90913          	addi	s2,s2,-866 # db8 <malloc+0x114>
        write(write_fd, &i, sizeof(i));
 122:	4611                	li	a2,4
 124:	fdc40593          	addi	a1,s0,-36
 128:	8526                	mv	a0,s1
 12a:	6bc000ef          	jal	ra,7e6 <write>
        printf("Produced: %d\n", i);
 12e:	fdc42583          	lw	a1,-36(s0)
 132:	854a                	mv	a0,s2
 134:	2b7000ef          	jal	ra,bea <printf>
        delay(20); // 模拟工作间隔
 138:	4551                	li	a0,20
 13a:	ec7ff0ef          	jal	ra,0 <delay>
    for (int i = 0; i < 5; i++) {
 13e:	fdc42783          	lw	a5,-36(s0)
 142:	2785                	addiw	a5,a5,1
 144:	0007871b          	sext.w	a4,a5
 148:	fcf42e23          	sw	a5,-36(s0)
 14c:	4791                	li	a5,4
 14e:	fce7dae3          	bge	a5,a4,122 <producer_task+0x1a>
    }
    close(write_fd);
 152:	8526                	mv	a0,s1
 154:	69a000ef          	jal	ra,7ee <close>
    exit(0);
 158:	4501                	li	a0,0
 15a:	66c000ef          	jal	ra,7c6 <exit>

000000000000015e <consumer_task>:
}

// ==========================
// 4. 消费者任务（通过 pipe）
// ==========================
void consumer_task(int read_fd) {
 15e:	7179                	addi	sp,sp,-48
 160:	f406                	sd	ra,40(sp)
 162:	f022                	sd	s0,32(sp)
 164:	ec26                	sd	s1,24(sp)
 166:	e84a                	sd	s2,16(sp)
 168:	1800                	addi	s0,sp,48
 16a:	84aa                	mv	s1,a0
    int val;
    while (read(read_fd, &val, sizeof(val)) == sizeof(val)) {
        printf("Consumed: %d\n", val);
 16c:	00001917          	auipc	s2,0x1
 170:	c5c90913          	addi	s2,s2,-932 # dc8 <malloc+0x124>
    while (read(read_fd, &val, sizeof(val)) == sizeof(val)) {
 174:	a809                	j	186 <consumer_task+0x28>
        printf("Consumed: %d\n", val);
 176:	fdc42583          	lw	a1,-36(s0)
 17a:	854a                	mv	a0,s2
 17c:	26f000ef          	jal	ra,bea <printf>
        delay(5); // 础保输出不被吞掉
 180:	4515                	li	a0,5
 182:	e7fff0ef          	jal	ra,0 <delay>
    while (read(read_fd, &val, sizeof(val)) == sizeof(val)) {
 186:	4611                	li	a2,4
 188:	fdc40593          	addi	a1,s0,-36
 18c:	8526                	mv	a0,s1
 18e:	650000ef          	jal	ra,7de <read>
 192:	4791                	li	a5,4
 194:	fef501e3          	beq	a0,a5,176 <consumer_task+0x18>
    }
    close(read_fd);
 198:	8526                	mv	a0,s1
 19a:	654000ef          	jal	ra,7ee <close>
    exit(0);
 19e:	4501                	li	a0,0
 1a0:	626000ef          	jal	ra,7c6 <exit>

00000000000001a4 <debug_proc_table>:

// ==========================
// 5. 调试进程表（模拟输出）
// ==========================

void debug_proc_table(void) {
 1a4:	8a010113          	addi	sp,sp,-1888
 1a8:	74113c23          	sd	ra,1880(sp)
 1ac:	74813823          	sd	s0,1872(sp)
 1b0:	74913423          	sd	s1,1864(sp)
 1b4:	75213023          	sd	s2,1856(sp)
 1b8:	73313c23          	sd	s3,1848(sp)
 1bc:	73413823          	sd	s4,1840(sp)
 1c0:	73513423          	sd	s5,1832(sp)
 1c4:	73613023          	sd	s6,1824(sp)
 1c8:	71713c23          	sd	s7,1816(sp)
 1cc:	71813823          	sd	s8,1808(sp)
 1d0:	71913423          	sd	s9,1800(sp)
 1d4:	71a13023          	sd	s10,1792(sp)
 1d8:	76010413          	addi	s0,sp,1888
    printf("\n=== Real Process Table ===\n");
 1dc:	00001517          	auipc	a0,0x1
 1e0:	c3c50513          	addi	a0,a0,-964 # e18 <malloc+0x174>
 1e4:	207000ef          	jal	ra,bea <printf>
    printf("PID\tSTATE\tNAME\n");
 1e8:	00001517          	auipc	a0,0x1
 1ec:	c5050513          	addi	a0,a0,-944 # e38 <malloc+0x194>
 1f0:	1fb000ef          	jal	ra,bea <printf>

    struct pstat stats[NPROC];
    if (dump_proc(stats) < 0) {
 1f4:	8a040513          	addi	a0,s0,-1888
 1f8:	66e000ef          	jal	ra,866 <dump_proc>
 1fc:	04054463          	bltz	a0,244 <debug_proc_table+0xa0>
 200:	8a840493          	addi	s1,s0,-1880
 204:	fa840913          	addi	s2,s0,-88
 208:	4a15                	li	s4,5
        return;
    }

    for (int i = 0; i < NPROC; i++) {
        if (stats[i].inuse) {
            char *state_str = "???";
 20a:	00001d17          	auipc	s10,0x1
 20e:	bd6d0d13          	addi	s10,s10,-1066 # de0 <malloc+0x13c>
 212:	00001997          	auipc	s3,0x1
 216:	e3698993          	addi	s3,s3,-458 # 1048 <malloc+0x3a4>
            switch (stats[i].state) {
                case 0: state_str = "UNUSED"; break;
                case 2: state_str = "SLEEPING"; break;
                case 3: state_str = "RUNNABLE"; break;
                case 4: state_str = "RUNNING"; break;
                case 5: state_str = "ZOMBIE"; break;
 21a:	00001c97          	auipc	s9,0x1
 21e:	bbec8c93          	addi	s9,s9,-1090 # dd8 <malloc+0x134>
                case 4: state_str = "RUNNING"; break;
 222:	00001c17          	auipc	s8,0x1
 226:	be6c0c13          	addi	s8,s8,-1050 # e08 <malloc+0x164>
                case 3: state_str = "RUNNABLE"; break;
 22a:	00001b97          	auipc	s7,0x1
 22e:	bceb8b93          	addi	s7,s7,-1074 # df8 <malloc+0x154>
                case 2: state_str = "SLEEPING"; break;
 232:	00001b17          	auipc	s6,0x1
 236:	bb6b0b13          	addi	s6,s6,-1098 # de8 <malloc+0x144>
            switch (stats[i].state) {
 23a:	00001a97          	auipc	s5,0x1
 23e:	bd6a8a93          	addi	s5,s5,-1066 # e10 <malloc+0x16c>
 242:	a8b1                	j	29e <debug_proc_table+0xfa>
        printf("Failed to get process table\n");
 244:	00001517          	auipc	a0,0x1
 248:	c0450513          	addi	a0,a0,-1020 # e48 <malloc+0x1a4>
 24c:	19f000ef          	jal	ra,bea <printf>
            }
            printf("%d\t%s\t%s\n", stats[i].pid, state_str, stats[i].name);
        }
    }
}
 250:	75813083          	ld	ra,1880(sp)
 254:	75013403          	ld	s0,1872(sp)
 258:	74813483          	ld	s1,1864(sp)
 25c:	74013903          	ld	s2,1856(sp)
 260:	73813983          	ld	s3,1848(sp)
 264:	73013a03          	ld	s4,1840(sp)
 268:	72813a83          	ld	s5,1832(sp)
 26c:	72013b03          	ld	s6,1824(sp)
 270:	71813b83          	ld	s7,1816(sp)
 274:	71013c03          	ld	s8,1808(sp)
 278:	70813c83          	ld	s9,1800(sp)
 27c:	70013d03          	ld	s10,1792(sp)
 280:	76010113          	addi	sp,sp,1888
 284:	8082                	ret
            switch (stats[i].state) {
 286:	8656                	mv	a2,s5
            printf("%d\t%s\t%s\n", stats[i].pid, state_str, stats[i].name);
 288:	ffc6a583          	lw	a1,-4(a3)
 28c:	00001517          	auipc	a0,0x1
 290:	bdc50513          	addi	a0,a0,-1060 # e68 <malloc+0x1c4>
 294:	157000ef          	jal	ra,bea <printf>
    for (int i = 0; i < NPROC; i++) {
 298:	04f1                	addi	s1,s1,28
 29a:	fb248be3          	beq	s1,s2,250 <debug_proc_table+0xac>
        if (stats[i].inuse) {
 29e:	86a6                	mv	a3,s1
 2a0:	ff84a783          	lw	a5,-8(s1)
 2a4:	dbf5                	beqz	a5,298 <debug_proc_table+0xf4>
            switch (stats[i].state) {
 2a6:	489c                	lw	a5,16(s1)
 2a8:	02fa6163          	bltu	s4,a5,2ca <debug_proc_table+0x126>
 2ac:	0104e783          	lwu	a5,16(s1)
 2b0:	078a                	slli	a5,a5,0x2
 2b2:	97ce                	add	a5,a5,s3
 2b4:	439c                	lw	a5,0(a5)
 2b6:	97ce                	add	a5,a5,s3
 2b8:	8782                	jr	a5
                case 2: state_str = "SLEEPING"; break;
 2ba:	865a                	mv	a2,s6
 2bc:	b7f1                	j	288 <debug_proc_table+0xe4>
                case 3: state_str = "RUNNABLE"; break;
 2be:	865e                	mv	a2,s7
 2c0:	b7e1                	j	288 <debug_proc_table+0xe4>
                case 4: state_str = "RUNNING"; break;
 2c2:	8662                	mv	a2,s8
 2c4:	b7d1                	j	288 <debug_proc_table+0xe4>
                case 5: state_str = "ZOMBIE"; break;
 2c6:	8666                	mv	a2,s9
 2c8:	b7c1                	j	288 <debug_proc_table+0xe4>
            char *state_str = "???";
 2ca:	866a                	mv	a2,s10
 2cc:	bf75                	j	288 <debug_proc_table+0xe4>

00000000000002ce <test_process_creation>:

// ==========================
// 6. 测试进程创建
// ==========================
void test_process_creation(void) {
 2ce:	1101                	addi	sp,sp,-32
 2d0:	ec06                	sd	ra,24(sp)
 2d2:	e822                	sd	s0,16(sp)
 2d4:	e426                	sd	s1,8(sp)
 2d6:	e04a                	sd	s2,0(sp)
 2d8:	1000                	addi	s0,sp,32
    printf("Testing process creation...\n");
 2da:	00001517          	auipc	a0,0x1
 2de:	b9e50513          	addi	a0,a0,-1122 # e78 <malloc+0x1d4>
 2e2:	109000ef          	jal	ra,bea <printf>

    int total_created = 0;

    // 第一个子进程：用于打印消息
    int pid = fork();
 2e6:	4d8000ef          	jal	ra,7be <fork>
    if (pid < 0) {
 2ea:	04054663          	bltz	a0,336 <test_process_creation+0x68>
        printf("fork failed!\n");
    } else if (pid == 0) {
 2ee:	cd21                	beqz	a0,346 <test_process_creation+0x78>
        printf("Child process running\n");
        exit(0);
    } else {
        total_created++;
        wait((int *)0);
 2f0:	4501                	li	a0,0
 2f2:	4dc000ef          	jal	ra,7ce <wait>
        total_created++;
 2f6:	4485                	li	s1,1
    }

    // 批量创建 MAX_TEST_PROC 个子进程
    for (int i = 0; i < MAX_TEST_PROC; i++) {
 2f8:	0084891b          	addiw	s2,s1,8
        pid = fork();
 2fc:	4c2000ef          	jal	ra,7be <fork>
        if (pid < 0) {
 300:	04054c63          	bltz	a0,358 <test_process_creation+0x8a>
            // fork 失败，停止创建
            break;
        }
        if (pid == 0) {
 304:	c52d                	beqz	a0,36e <test_process_creation+0xa0>
            // 子进程什么都不做，直接退出
            exit(0);
        }
        total_created++;
 306:	2485                	addiw	s1,s1,1
    for (int i = 0; i < MAX_TEST_PROC; i++) {
 308:	fe991ae3          	bne	s2,s1,2fc <test_process_creation+0x2e>
    }

    printf("Created %d processes\n", total_created);
 30c:	85a6                	mv	a1,s1
 30e:	00001517          	auipc	a0,0x1
 312:	bb250513          	addi	a0,a0,-1102 # ec0 <malloc+0x21c>
 316:	0d5000ef          	jal	ra,bea <printf>

    // 等待剩余子进程（第一个已 wait，这里等剩下的）
    for (int i = 0; i < total_created - 1; i++) {
 31a:	34fd                	addiw	s1,s1,-1
 31c:	4901                	li	s2,0
        wait((int *)0);
 31e:	4501                	li	a0,0
 320:	4ae000ef          	jal	ra,7ce <wait>
    for (int i = 0; i < total_created - 1; i++) {
 324:	2905                	addiw	s2,s2,1
 326:	fe991ce3          	bne	s2,s1,31e <test_process_creation+0x50>
    }
}
 32a:	60e2                	ld	ra,24(sp)
 32c:	6442                	ld	s0,16(sp)
 32e:	64a2                	ld	s1,8(sp)
 330:	6902                	ld	s2,0(sp)
 332:	6105                	addi	sp,sp,32
 334:	8082                	ret
        printf("fork failed!\n");
 336:	00001517          	auipc	a0,0x1
 33a:	b6250513          	addi	a0,a0,-1182 # e98 <malloc+0x1f4>
 33e:	0ad000ef          	jal	ra,bea <printf>
    int total_created = 0;
 342:	4481                	li	s1,0
 344:	bf55                	j	2f8 <test_process_creation+0x2a>
        printf("Child process running\n");
 346:	00001517          	auipc	a0,0x1
 34a:	b6250513          	addi	a0,a0,-1182 # ea8 <malloc+0x204>
 34e:	09d000ef          	jal	ra,bea <printf>
        exit(0);
 352:	4501                	li	a0,0
 354:	472000ef          	jal	ra,7c6 <exit>
    printf("Created %d processes\n", total_created);
 358:	85a6                	mv	a1,s1
 35a:	00001517          	auipc	a0,0x1
 35e:	b6650513          	addi	a0,a0,-1178 # ec0 <malloc+0x21c>
 362:	089000ef          	jal	ra,bea <printf>
    for (int i = 0; i < total_created - 1; i++) {
 366:	4785                	li	a5,1
 368:	fa97c9e3          	blt	a5,s1,31a <test_process_creation+0x4c>
 36c:	bf7d                	j	32a <test_process_creation+0x5c>
            exit(0);
 36e:	458000ef          	jal	ra,7c6 <exit>

0000000000000372 <test_scheduler>:

// ==========================
// 7. 测试调度器（时间片轮转）
// ==========================
void test_scheduler(void) {
 372:	7139                	addi	sp,sp,-64
 374:	fc06                	sd	ra,56(sp)
 376:	f822                	sd	s0,48(sp)
 378:	f426                	sd	s1,40(sp)
 37a:	f04a                	sd	s2,32(sp)
 37c:	ec4e                	sd	s3,24(sp)
 37e:	0080                	addi	s0,sp,64
    printf("Testing scheduler with %d workers...\n", SCHED_WORKERS);
 380:	4591                	li	a1,4
 382:	00001517          	auipc	a0,0x1
 386:	b5650513          	addi	a0,a0,-1194 # ed8 <malloc+0x234>
 38a:	061000ef          	jal	ra,bea <printf>

    int start_time = uptime();
 38e:	4d0000ef          	jal	ra,85e <uptime>
 392:	89aa                	mv	s3,a0
    int created = 0;
 394:	4901                	li	s2,0

    for (int i = 0; i < SCHED_WORKERS; i++) {
 396:	4491                	li	s1,4
        int pid = fork();
 398:	426000ef          	jal	ra,7be <fork>
        if (pid < 0) {
 39c:	02054e63          	bltz	a0,3d8 <test_scheduler+0x66>
            printf("fork failed at worker %d\n", i);
            break;
        }
        if (pid == 0) {
 3a0:	c531                	beqz	a0,3ec <test_scheduler+0x7a>
                x += j;
            }
            printf("Worker %d finished\n", i);
            exit(0);
        }
        created++;
 3a2:	2905                	addiw	s2,s2,1
    for (int i = 0; i < SCHED_WORKERS; i++) {
 3a4:	fe991ae3          	bne	s2,s1,398 <test_scheduler+0x26>
            for (long j = 0; j < 200000; j++) {
 3a8:	4481                	li	s1,0
    }

    // 等待所有成功创建的子进程
    for (int i = 0; i < created; i++) {
        wait((int *)0);
 3aa:	4501                	li	a0,0
 3ac:	422000ef          	jal	ra,7ce <wait>
    for (int i = 0; i < created; i++) {
 3b0:	2485                	addiw	s1,s1,1
 3b2:	fe991ce3          	bne	s2,s1,3aa <test_scheduler+0x38>
    }

    int end_time = uptime();
 3b6:	4a8000ef          	jal	ra,85e <uptime>
    printf("Scheduler test completed in %d ticks\n", end_time - start_time);
 3ba:	413505bb          	subw	a1,a0,s3
 3be:	00001517          	auipc	a0,0x1
 3c2:	b7a50513          	addi	a0,a0,-1158 # f38 <malloc+0x294>
 3c6:	025000ef          	jal	ra,bea <printf>
}
 3ca:	70e2                	ld	ra,56(sp)
 3cc:	7442                	ld	s0,48(sp)
 3ce:	74a2                	ld	s1,40(sp)
 3d0:	7902                	ld	s2,32(sp)
 3d2:	69e2                	ld	s3,24(sp)
 3d4:	6121                	addi	sp,sp,64
 3d6:	8082                	ret
            printf("fork failed at worker %d\n", i);
 3d8:	85ca                	mv	a1,s2
 3da:	00001517          	auipc	a0,0x1
 3de:	b2650513          	addi	a0,a0,-1242 # f00 <malloc+0x25c>
 3e2:	009000ef          	jal	ra,bea <printf>
    for (int i = 0; i < created; i++) {
 3e6:	fd2041e3          	bgtz	s2,3a8 <test_scheduler+0x36>
 3ea:	b7f1                	j	3b6 <test_scheduler+0x44>
            volatile long x = 0;
 3ec:	fc043423          	sd	zero,-56(s0)
            for (long j = 0; j < 200000; j++) {
 3f0:	4781                	li	a5,0
 3f2:	000316b7          	lui	a3,0x31
 3f6:	d4068693          	addi	a3,a3,-704 # 30d40 <base+0x2ed30>
                x += j;
 3fa:	fc843703          	ld	a4,-56(s0)
 3fe:	973e                	add	a4,a4,a5
 400:	fce43423          	sd	a4,-56(s0)
            for (long j = 0; j < 200000; j++) {
 404:	0785                	addi	a5,a5,1
 406:	fed79ae3          	bne	a5,a3,3fa <test_scheduler+0x88>
            printf("Worker %d finished\n", i);
 40a:	85ca                	mv	a1,s2
 40c:	00001517          	auipc	a0,0x1
 410:	b1450513          	addi	a0,a0,-1260 # f20 <malloc+0x27c>
 414:	7d6000ef          	jal	ra,bea <printf>
            exit(0);
 418:	4501                	li	a0,0
 41a:	3ac000ef          	jal	ra,7c6 <exit>

000000000000041e <test_synchronization>:

// ==========================
// 8. 测试同步（pipe 实现生产者-消费者）
// ==========================
void test_synchronization(void) {
 41e:	1101                	addi	sp,sp,-32
 420:	ec06                	sd	ra,24(sp)
 422:	e822                	sd	s0,16(sp)
 424:	1000                	addi	s0,sp,32
    printf("Testing synchronization (basic producer-consumer)...\n");
 426:	00001517          	auipc	a0,0x1
 42a:	b3a50513          	addi	a0,a0,-1222 # f60 <malloc+0x2bc>
 42e:	7bc000ef          	jal	ra,bea <printf>

    int pipefd[2];
    if (pipe(pipefd) != 0) {
 432:	fe840513          	addi	a0,s0,-24
 436:	3a0000ef          	jal	ra,7d6 <pipe>
 43a:	e139                	bnez	a0,480 <test_synchronization+0x62>
        printf("pipe failed!\n");
        exit(1);
    }

    int pid1 = fork();
 43c:	382000ef          	jal	ra,7be <fork>
    if (pid1 < 0) {
 440:	04054963          	bltz	a0,492 <test_synchronization+0x74>
        printf("fork producer failed\n");
        exit(1);
    }
    if (pid1 == 0) {
 444:	c125                	beqz	a0,4a4 <test_synchronization+0x86>
        close(pipefd[0]);
        producer_task(pipefd[1]);
    }

    int pid2 = fork();
 446:	378000ef          	jal	ra,7be <fork>
    if (pid2 < 0) {
 44a:	06054563          	bltz	a0,4b4 <test_synchronization+0x96>
        printf("fork consumer failed\n");
        exit(1);
    }
    if (pid2 == 0) {
 44e:	cd25                	beqz	a0,4c6 <test_synchronization+0xa8>
        close(pipefd[1]);
        consumer_task(pipefd[0]);
    }

    // 父进程关闭 pipe 并等待
    close(pipefd[0]);
 450:	fe842503          	lw	a0,-24(s0)
 454:	39a000ef          	jal	ra,7ee <close>
    close(pipefd[1]);
 458:	fec42503          	lw	a0,-20(s0)
 45c:	392000ef          	jal	ra,7ee <close>

    wait((int *)0); // 等待任意一个子进程
 460:	4501                	li	a0,0
 462:	36c000ef          	jal	ra,7ce <wait>
    wait((int *)0); // 等待另一个
 466:	4501                	li	a0,0
 468:	366000ef          	jal	ra,7ce <wait>

    printf("Synchronization test completed\n");
 46c:	00001517          	auipc	a0,0x1
 470:	b6c50513          	addi	a0,a0,-1172 # fd8 <malloc+0x334>
 474:	776000ef          	jal	ra,bea <printf>
}
 478:	60e2                	ld	ra,24(sp)
 47a:	6442                	ld	s0,16(sp)
 47c:	6105                	addi	sp,sp,32
 47e:	8082                	ret
        printf("pipe failed!\n");
 480:	00001517          	auipc	a0,0x1
 484:	b1850513          	addi	a0,a0,-1256 # f98 <malloc+0x2f4>
 488:	762000ef          	jal	ra,bea <printf>
        exit(1);
 48c:	4505                	li	a0,1
 48e:	338000ef          	jal	ra,7c6 <exit>
        printf("fork producer failed\n");
 492:	00001517          	auipc	a0,0x1
 496:	b1650513          	addi	a0,a0,-1258 # fa8 <malloc+0x304>
 49a:	750000ef          	jal	ra,bea <printf>
        exit(1);
 49e:	4505                	li	a0,1
 4a0:	326000ef          	jal	ra,7c6 <exit>
        close(pipefd[0]);
 4a4:	fe842503          	lw	a0,-24(s0)
 4a8:	346000ef          	jal	ra,7ee <close>
        producer_task(pipefd[1]);
 4ac:	fec42503          	lw	a0,-20(s0)
 4b0:	c59ff0ef          	jal	ra,108 <producer_task>
        printf("fork consumer failed\n");
 4b4:	00001517          	auipc	a0,0x1
 4b8:	b0c50513          	addi	a0,a0,-1268 # fc0 <malloc+0x31c>
 4bc:	72e000ef          	jal	ra,bea <printf>
        exit(1);
 4c0:	4505                	li	a0,1
 4c2:	304000ef          	jal	ra,7c6 <exit>
        close(pipefd[1]);
 4c6:	fec42503          	lw	a0,-20(s0)
 4ca:	324000ef          	jal	ra,7ee <close>
        consumer_task(pipefd[0]);
 4ce:	fe842503          	lw	a0,-24(s0)
 4d2:	c8dff0ef          	jal	ra,15e <consumer_task>

00000000000004d6 <main>:

// ==========================
// 主函数
// ==========================
int main(int argc, char *argv[]) {
 4d6:	1141                	addi	sp,sp,-16
 4d8:	e406                	sd	ra,8(sp)
 4da:	e022                	sd	s0,0(sp)
 4dc:	0800                	addi	s0,sp,16
    printf("=== Starting xv6 Comprehensive Test Suite ===\n");
 4de:	00001517          	auipc	a0,0x1
 4e2:	b1a50513          	addi	a0,a0,-1254 # ff8 <malloc+0x354>
 4e6:	704000ef          	jal	ra,bea <printf>

//    debug_proc_table();
    test_process_creation();
 4ea:	de5ff0ef          	jal	ra,2ce <test_process_creation>
    test_scheduler();
 4ee:	e85ff0ef          	jal	ra,372 <test_scheduler>
    test_synchronization();
 4f2:	f2dff0ef          	jal	ra,41e <test_synchronization>

    // 单独测试简单任务
    if (fork() == 0) {
 4f6:	2c8000ef          	jal	ra,7be <fork>
 4fa:	e509                	bnez	a0,504 <main+0x2e>
        debug_proc_table();
 4fc:	ca9ff0ef          	jal	ra,1a4 <debug_proc_table>
        simple_task();
 500:	ba7ff0ef          	jal	ra,a6 <simple_task>
//	printf("Simple task running (my PID = %d)\n", getpid());
    }
    wait((int *)0);
 504:	4501                	li	a0,0
 506:	2c8000ef          	jal	ra,7ce <wait>

    if (fork() == 0) {
 50a:	2b4000ef          	jal	ra,7be <fork>
 50e:	e119                	bnez	a0,514 <main+0x3e>
        cpu_intensive_task();
 510:	bb1ff0ef          	jal	ra,c0 <cpu_intensive_task>
    }
    wait((int *)0);
 514:	4501                	li	a0,0
 516:	2b8000ef          	jal	ra,7ce <wait>


    debug_proc_table();
 51a:	c8bff0ef          	jal	ra,1a4 <debug_proc_table>


    printf("=== All tests completed ===\n");
 51e:	00001517          	auipc	a0,0x1
 522:	b0a50513          	addi	a0,a0,-1270 # 1028 <malloc+0x384>
 526:	6c4000ef          	jal	ra,bea <printf>
    exit(0);
 52a:	4501                	li	a0,0
 52c:	29a000ef          	jal	ra,7c6 <exit>

0000000000000530 <start>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
start(int argc, char **argv)
{
 530:	1141                	addi	sp,sp,-16
 532:	e406                	sd	ra,8(sp)
 534:	e022                	sd	s0,0(sp)
 536:	0800                	addi	s0,sp,16
  int r;
  extern int main(int argc, char **argv);
  r = main(argc, argv);
 538:	f9fff0ef          	jal	ra,4d6 <main>
  exit(r);
 53c:	28a000ef          	jal	ra,7c6 <exit>

0000000000000540 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 540:	1141                	addi	sp,sp,-16
 542:	e422                	sd	s0,8(sp)
 544:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 546:	87aa                	mv	a5,a0
 548:	0585                	addi	a1,a1,1
 54a:	0785                	addi	a5,a5,1
 54c:	fff5c703          	lbu	a4,-1(a1)
 550:	fee78fa3          	sb	a4,-1(a5)
 554:	fb75                	bnez	a4,548 <strcpy+0x8>
    ;
  return os;
}
 556:	6422                	ld	s0,8(sp)
 558:	0141                	addi	sp,sp,16
 55a:	8082                	ret

000000000000055c <strcmp>:

int
strcmp(const char *p, const char *q)
{
 55c:	1141                	addi	sp,sp,-16
 55e:	e422                	sd	s0,8(sp)
 560:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 562:	00054783          	lbu	a5,0(a0)
 566:	cb91                	beqz	a5,57a <strcmp+0x1e>
 568:	0005c703          	lbu	a4,0(a1)
 56c:	00f71763          	bne	a4,a5,57a <strcmp+0x1e>
    p++, q++;
 570:	0505                	addi	a0,a0,1
 572:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 574:	00054783          	lbu	a5,0(a0)
 578:	fbe5                	bnez	a5,568 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 57a:	0005c503          	lbu	a0,0(a1)
}
 57e:	40a7853b          	subw	a0,a5,a0
 582:	6422                	ld	s0,8(sp)
 584:	0141                	addi	sp,sp,16
 586:	8082                	ret

0000000000000588 <strlen>:

uint
strlen(const char *s)
{
 588:	1141                	addi	sp,sp,-16
 58a:	e422                	sd	s0,8(sp)
 58c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 58e:	00054783          	lbu	a5,0(a0)
 592:	cf91                	beqz	a5,5ae <strlen+0x26>
 594:	0505                	addi	a0,a0,1
 596:	87aa                	mv	a5,a0
 598:	4685                	li	a3,1
 59a:	9e89                	subw	a3,a3,a0
 59c:	00f6853b          	addw	a0,a3,a5
 5a0:	0785                	addi	a5,a5,1
 5a2:	fff7c703          	lbu	a4,-1(a5)
 5a6:	fb7d                	bnez	a4,59c <strlen+0x14>
    ;
  return n;
}
 5a8:	6422                	ld	s0,8(sp)
 5aa:	0141                	addi	sp,sp,16
 5ac:	8082                	ret
  for(n = 0; s[n]; n++)
 5ae:	4501                	li	a0,0
 5b0:	bfe5                	j	5a8 <strlen+0x20>

00000000000005b2 <memset>:

void*
memset(void *dst, int c, uint n)
{
 5b2:	1141                	addi	sp,sp,-16
 5b4:	e422                	sd	s0,8(sp)
 5b6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 5b8:	ca19                	beqz	a2,5ce <memset+0x1c>
 5ba:	87aa                	mv	a5,a0
 5bc:	1602                	slli	a2,a2,0x20
 5be:	9201                	srli	a2,a2,0x20
 5c0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 5c4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 5c8:	0785                	addi	a5,a5,1
 5ca:	fee79de3          	bne	a5,a4,5c4 <memset+0x12>
  }
  return dst;
}
 5ce:	6422                	ld	s0,8(sp)
 5d0:	0141                	addi	sp,sp,16
 5d2:	8082                	ret

00000000000005d4 <strchr>:

char*
strchr(const char *s, char c)
{
 5d4:	1141                	addi	sp,sp,-16
 5d6:	e422                	sd	s0,8(sp)
 5d8:	0800                	addi	s0,sp,16
  for(; *s; s++)
 5da:	00054783          	lbu	a5,0(a0)
 5de:	cb99                	beqz	a5,5f4 <strchr+0x20>
    if(*s == c)
 5e0:	00f58763          	beq	a1,a5,5ee <strchr+0x1a>
  for(; *s; s++)
 5e4:	0505                	addi	a0,a0,1
 5e6:	00054783          	lbu	a5,0(a0)
 5ea:	fbfd                	bnez	a5,5e0 <strchr+0xc>
      return (char*)s;
  return 0;
 5ec:	4501                	li	a0,0
}
 5ee:	6422                	ld	s0,8(sp)
 5f0:	0141                	addi	sp,sp,16
 5f2:	8082                	ret
  return 0;
 5f4:	4501                	li	a0,0
 5f6:	bfe5                	j	5ee <strchr+0x1a>

00000000000005f8 <gets>:

char*
gets(char *buf, int max)
{
 5f8:	711d                	addi	sp,sp,-96
 5fa:	ec86                	sd	ra,88(sp)
 5fc:	e8a2                	sd	s0,80(sp)
 5fe:	e4a6                	sd	s1,72(sp)
 600:	e0ca                	sd	s2,64(sp)
 602:	fc4e                	sd	s3,56(sp)
 604:	f852                	sd	s4,48(sp)
 606:	f456                	sd	s5,40(sp)
 608:	f05a                	sd	s6,32(sp)
 60a:	ec5e                	sd	s7,24(sp)
 60c:	1080                	addi	s0,sp,96
 60e:	8baa                	mv	s7,a0
 610:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 612:	892a                	mv	s2,a0
 614:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 616:	4aa9                	li	s5,10
 618:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 61a:	89a6                	mv	s3,s1
 61c:	2485                	addiw	s1,s1,1
 61e:	0344d663          	bge	s1,s4,64a <gets+0x52>
    cc = read(0, &c, 1);
 622:	4605                	li	a2,1
 624:	faf40593          	addi	a1,s0,-81
 628:	4501                	li	a0,0
 62a:	1b4000ef          	jal	ra,7de <read>
    if(cc < 1)
 62e:	00a05e63          	blez	a0,64a <gets+0x52>
    buf[i++] = c;
 632:	faf44783          	lbu	a5,-81(s0)
 636:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 63a:	01578763          	beq	a5,s5,648 <gets+0x50>
 63e:	0905                	addi	s2,s2,1
 640:	fd679de3          	bne	a5,s6,61a <gets+0x22>
  for(i=0; i+1 < max; ){
 644:	89a6                	mv	s3,s1
 646:	a011                	j	64a <gets+0x52>
 648:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 64a:	99de                	add	s3,s3,s7
 64c:	00098023          	sb	zero,0(s3)
  return buf;
}
 650:	855e                	mv	a0,s7
 652:	60e6                	ld	ra,88(sp)
 654:	6446                	ld	s0,80(sp)
 656:	64a6                	ld	s1,72(sp)
 658:	6906                	ld	s2,64(sp)
 65a:	79e2                	ld	s3,56(sp)
 65c:	7a42                	ld	s4,48(sp)
 65e:	7aa2                	ld	s5,40(sp)
 660:	7b02                	ld	s6,32(sp)
 662:	6be2                	ld	s7,24(sp)
 664:	6125                	addi	sp,sp,96
 666:	8082                	ret

0000000000000668 <stat>:

int
stat(const char *n, struct stat *st)
{
 668:	1101                	addi	sp,sp,-32
 66a:	ec06                	sd	ra,24(sp)
 66c:	e822                	sd	s0,16(sp)
 66e:	e426                	sd	s1,8(sp)
 670:	e04a                	sd	s2,0(sp)
 672:	1000                	addi	s0,sp,32
 674:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 676:	4581                	li	a1,0
 678:	18e000ef          	jal	ra,806 <open>
  if(fd < 0)
 67c:	02054163          	bltz	a0,69e <stat+0x36>
 680:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 682:	85ca                	mv	a1,s2
 684:	19a000ef          	jal	ra,81e <fstat>
 688:	892a                	mv	s2,a0
  close(fd);
 68a:	8526                	mv	a0,s1
 68c:	162000ef          	jal	ra,7ee <close>
  return r;
}
 690:	854a                	mv	a0,s2
 692:	60e2                	ld	ra,24(sp)
 694:	6442                	ld	s0,16(sp)
 696:	64a2                	ld	s1,8(sp)
 698:	6902                	ld	s2,0(sp)
 69a:	6105                	addi	sp,sp,32
 69c:	8082                	ret
    return -1;
 69e:	597d                	li	s2,-1
 6a0:	bfc5                	j	690 <stat+0x28>

00000000000006a2 <atoi>:

int
atoi(const char *s)
{
 6a2:	1141                	addi	sp,sp,-16
 6a4:	e422                	sd	s0,8(sp)
 6a6:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 6a8:	00054603          	lbu	a2,0(a0)
 6ac:	fd06079b          	addiw	a5,a2,-48
 6b0:	0ff7f793          	andi	a5,a5,255
 6b4:	4725                	li	a4,9
 6b6:	02f76963          	bltu	a4,a5,6e8 <atoi+0x46>
 6ba:	86aa                	mv	a3,a0
  n = 0;
 6bc:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 6be:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 6c0:	0685                	addi	a3,a3,1
 6c2:	0025179b          	slliw	a5,a0,0x2
 6c6:	9fa9                	addw	a5,a5,a0
 6c8:	0017979b          	slliw	a5,a5,0x1
 6cc:	9fb1                	addw	a5,a5,a2
 6ce:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 6d2:	0006c603          	lbu	a2,0(a3)
 6d6:	fd06071b          	addiw	a4,a2,-48
 6da:	0ff77713          	andi	a4,a4,255
 6de:	fee5f1e3          	bgeu	a1,a4,6c0 <atoi+0x1e>
  return n;
}
 6e2:	6422                	ld	s0,8(sp)
 6e4:	0141                	addi	sp,sp,16
 6e6:	8082                	ret
  n = 0;
 6e8:	4501                	li	a0,0
 6ea:	bfe5                	j	6e2 <atoi+0x40>

00000000000006ec <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 6ec:	1141                	addi	sp,sp,-16
 6ee:	e422                	sd	s0,8(sp)
 6f0:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 6f2:	02b57463          	bgeu	a0,a1,71a <memmove+0x2e>
    while(n-- > 0)
 6f6:	00c05f63          	blez	a2,714 <memmove+0x28>
 6fa:	1602                	slli	a2,a2,0x20
 6fc:	9201                	srli	a2,a2,0x20
 6fe:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 702:	872a                	mv	a4,a0
      *dst++ = *src++;
 704:	0585                	addi	a1,a1,1
 706:	0705                	addi	a4,a4,1
 708:	fff5c683          	lbu	a3,-1(a1)
 70c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 710:	fee79ae3          	bne	a5,a4,704 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 714:	6422                	ld	s0,8(sp)
 716:	0141                	addi	sp,sp,16
 718:	8082                	ret
    dst += n;
 71a:	00c50733          	add	a4,a0,a2
    src += n;
 71e:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 720:	fec05ae3          	blez	a2,714 <memmove+0x28>
 724:	fff6079b          	addiw	a5,a2,-1
 728:	1782                	slli	a5,a5,0x20
 72a:	9381                	srli	a5,a5,0x20
 72c:	fff7c793          	not	a5,a5
 730:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 732:	15fd                	addi	a1,a1,-1
 734:	177d                	addi	a4,a4,-1
 736:	0005c683          	lbu	a3,0(a1)
 73a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 73e:	fee79ae3          	bne	a5,a4,732 <memmove+0x46>
 742:	bfc9                	j	714 <memmove+0x28>

0000000000000744 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 744:	1141                	addi	sp,sp,-16
 746:	e422                	sd	s0,8(sp)
 748:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 74a:	ca05                	beqz	a2,77a <memcmp+0x36>
 74c:	fff6069b          	addiw	a3,a2,-1
 750:	1682                	slli	a3,a3,0x20
 752:	9281                	srli	a3,a3,0x20
 754:	0685                	addi	a3,a3,1
 756:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 758:	00054783          	lbu	a5,0(a0)
 75c:	0005c703          	lbu	a4,0(a1)
 760:	00e79863          	bne	a5,a4,770 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 764:	0505                	addi	a0,a0,1
    p2++;
 766:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 768:	fed518e3          	bne	a0,a3,758 <memcmp+0x14>
  }
  return 0;
 76c:	4501                	li	a0,0
 76e:	a019                	j	774 <memcmp+0x30>
      return *p1 - *p2;
 770:	40e7853b          	subw	a0,a5,a4
}
 774:	6422                	ld	s0,8(sp)
 776:	0141                	addi	sp,sp,16
 778:	8082                	ret
  return 0;
 77a:	4501                	li	a0,0
 77c:	bfe5                	j	774 <memcmp+0x30>

000000000000077e <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 77e:	1141                	addi	sp,sp,-16
 780:	e406                	sd	ra,8(sp)
 782:	e022                	sd	s0,0(sp)
 784:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 786:	f67ff0ef          	jal	ra,6ec <memmove>
}
 78a:	60a2                	ld	ra,8(sp)
 78c:	6402                	ld	s0,0(sp)
 78e:	0141                	addi	sp,sp,16
 790:	8082                	ret

0000000000000792 <sbrk>:

char *
sbrk(int n) {
 792:	1141                	addi	sp,sp,-16
 794:	e406                	sd	ra,8(sp)
 796:	e022                	sd	s0,0(sp)
 798:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_EAGER);
 79a:	4585                	li	a1,1
 79c:	0b2000ef          	jal	ra,84e <sys_sbrk>
}
 7a0:	60a2                	ld	ra,8(sp)
 7a2:	6402                	ld	s0,0(sp)
 7a4:	0141                	addi	sp,sp,16
 7a6:	8082                	ret

00000000000007a8 <sbrklazy>:

char *
sbrklazy(int n) {
 7a8:	1141                	addi	sp,sp,-16
 7aa:	e406                	sd	ra,8(sp)
 7ac:	e022                	sd	s0,0(sp)
 7ae:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_LAZY);
 7b0:	4589                	li	a1,2
 7b2:	09c000ef          	jal	ra,84e <sys_sbrk>
}
 7b6:	60a2                	ld	ra,8(sp)
 7b8:	6402                	ld	s0,0(sp)
 7ba:	0141                	addi	sp,sp,16
 7bc:	8082                	ret

00000000000007be <fork>:
# 由 usys.pl 生成 - 请勿编辑
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 7be:	4885                	li	a7,1
 ecall
 7c0:	00000073          	ecall
 ret
 7c4:	8082                	ret

00000000000007c6 <exit>:
.global exit
exit:
 li a7, SYS_exit
 7c6:	4889                	li	a7,2
 ecall
 7c8:	00000073          	ecall
 ret
 7cc:	8082                	ret

00000000000007ce <wait>:
.global wait
wait:
 li a7, SYS_wait
 7ce:	488d                	li	a7,3
 ecall
 7d0:	00000073          	ecall
 ret
 7d4:	8082                	ret

00000000000007d6 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 7d6:	4891                	li	a7,4
 ecall
 7d8:	00000073          	ecall
 ret
 7dc:	8082                	ret

00000000000007de <read>:
.global read
read:
 li a7, SYS_read
 7de:	4895                	li	a7,5
 ecall
 7e0:	00000073          	ecall
 ret
 7e4:	8082                	ret

00000000000007e6 <write>:
.global write
write:
 li a7, SYS_write
 7e6:	48c1                	li	a7,16
 ecall
 7e8:	00000073          	ecall
 ret
 7ec:	8082                	ret

00000000000007ee <close>:
.global close
close:
 li a7, SYS_close
 7ee:	48d5                	li	a7,21
 ecall
 7f0:	00000073          	ecall
 ret
 7f4:	8082                	ret

00000000000007f6 <kill>:
.global kill
kill:
 li a7, SYS_kill
 7f6:	4899                	li	a7,6
 ecall
 7f8:	00000073          	ecall
 ret
 7fc:	8082                	ret

00000000000007fe <exec>:
.global exec
exec:
 li a7, SYS_exec
 7fe:	489d                	li	a7,7
 ecall
 800:	00000073          	ecall
 ret
 804:	8082                	ret

0000000000000806 <open>:
.global open
open:
 li a7, SYS_open
 806:	48bd                	li	a7,15
 ecall
 808:	00000073          	ecall
 ret
 80c:	8082                	ret

000000000000080e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 80e:	48c5                	li	a7,17
 ecall
 810:	00000073          	ecall
 ret
 814:	8082                	ret

0000000000000816 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 816:	48c9                	li	a7,18
 ecall
 818:	00000073          	ecall
 ret
 81c:	8082                	ret

000000000000081e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 81e:	48a1                	li	a7,8
 ecall
 820:	00000073          	ecall
 ret
 824:	8082                	ret

0000000000000826 <link>:
.global link
link:
 li a7, SYS_link
 826:	48cd                	li	a7,19
 ecall
 828:	00000073          	ecall
 ret
 82c:	8082                	ret

000000000000082e <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 82e:	48d1                	li	a7,20
 ecall
 830:	00000073          	ecall
 ret
 834:	8082                	ret

0000000000000836 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 836:	48a5                	li	a7,9
 ecall
 838:	00000073          	ecall
 ret
 83c:	8082                	ret

000000000000083e <dup>:
.global dup
dup:
 li a7, SYS_dup
 83e:	48a9                	li	a7,10
 ecall
 840:	00000073          	ecall
 ret
 844:	8082                	ret

0000000000000846 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 846:	48ad                	li	a7,11
 ecall
 848:	00000073          	ecall
 ret
 84c:	8082                	ret

000000000000084e <sys_sbrk>:
.global sys_sbrk
sys_sbrk:
 li a7, SYS_sbrk
 84e:	48b1                	li	a7,12
 ecall
 850:	00000073          	ecall
 ret
 854:	8082                	ret

0000000000000856 <pause>:
.global pause
pause:
 li a7, SYS_pause
 856:	48b5                	li	a7,13
 ecall
 858:	00000073          	ecall
 ret
 85c:	8082                	ret

000000000000085e <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 85e:	48b9                	li	a7,14
 ecall
 860:	00000073          	ecall
 ret
 864:	8082                	ret

0000000000000866 <dump_proc>:
.global dump_proc
dump_proc:
 li a7, SYS_dump_proc
 866:	48d9                	li	a7,22
 ecall
 868:	00000073          	ecall
 ret
 86c:	8082                	ret

000000000000086e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 86e:	1101                	addi	sp,sp,-32
 870:	ec06                	sd	ra,24(sp)
 872:	e822                	sd	s0,16(sp)
 874:	1000                	addi	s0,sp,32
 876:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 87a:	4605                	li	a2,1
 87c:	fef40593          	addi	a1,s0,-17
 880:	f67ff0ef          	jal	ra,7e6 <write>
}
 884:	60e2                	ld	ra,24(sp)
 886:	6442                	ld	s0,16(sp)
 888:	6105                	addi	sp,sp,32
 88a:	8082                	ret

000000000000088c <printint>:

static void
printint(int fd, long long xx, int base, int sgn)
{
 88c:	715d                	addi	sp,sp,-80
 88e:	e486                	sd	ra,72(sp)
 890:	e0a2                	sd	s0,64(sp)
 892:	fc26                	sd	s1,56(sp)
 894:	f84a                	sd	s2,48(sp)
 896:	f44e                	sd	s3,40(sp)
 898:	0880                	addi	s0,sp,80
 89a:	892a                	mv	s2,a0
  char buf[20];
  int i, neg;
  unsigned long long x;

  neg = 0;
  if(sgn && xx < 0){
 89c:	c299                	beqz	a3,8a2 <printint+0x16>
 89e:	0805c163          	bltz	a1,920 <printint+0x94>
  neg = 0;
 8a2:	4881                	li	a7,0
 8a4:	fb840693          	addi	a3,s0,-72
    x = -xx;
  } else {
    x = xx;
  }

  i = 0;
 8a8:	4781                	li	a5,0
  do{
    buf[i++] = digits[x % base];
 8aa:	00000517          	auipc	a0,0x0
 8ae:	7be50513          	addi	a0,a0,1982 # 1068 <digits>
 8b2:	883e                	mv	a6,a5
 8b4:	2785                	addiw	a5,a5,1
 8b6:	02c5f733          	remu	a4,a1,a2
 8ba:	972a                	add	a4,a4,a0
 8bc:	00074703          	lbu	a4,0(a4)
 8c0:	00e68023          	sb	a4,0(a3)
  }while((x /= base) != 0);
 8c4:	872e                	mv	a4,a1
 8c6:	02c5d5b3          	divu	a1,a1,a2
 8ca:	0685                	addi	a3,a3,1
 8cc:	fec773e3          	bgeu	a4,a2,8b2 <printint+0x26>
  if(neg)
 8d0:	00088b63          	beqz	a7,8e6 <printint+0x5a>
    buf[i++] = '-';
 8d4:	fd040713          	addi	a4,s0,-48
 8d8:	97ba                	add	a5,a5,a4
 8da:	02d00713          	li	a4,45
 8de:	fee78423          	sb	a4,-24(a5)
 8e2:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
 8e6:	02f05663          	blez	a5,912 <printint+0x86>
 8ea:	fb840713          	addi	a4,s0,-72
 8ee:	00f704b3          	add	s1,a4,a5
 8f2:	fff70993          	addi	s3,a4,-1
 8f6:	99be                	add	s3,s3,a5
 8f8:	37fd                	addiw	a5,a5,-1
 8fa:	1782                	slli	a5,a5,0x20
 8fc:	9381                	srli	a5,a5,0x20
 8fe:	40f989b3          	sub	s3,s3,a5
    putc(fd, buf[i]);
 902:	fff4c583          	lbu	a1,-1(s1)
 906:	854a                	mv	a0,s2
 908:	f67ff0ef          	jal	ra,86e <putc>
  while(--i >= 0)
 90c:	14fd                	addi	s1,s1,-1
 90e:	ff349ae3          	bne	s1,s3,902 <printint+0x76>
}
 912:	60a6                	ld	ra,72(sp)
 914:	6406                	ld	s0,64(sp)
 916:	74e2                	ld	s1,56(sp)
 918:	7942                	ld	s2,48(sp)
 91a:	79a2                	ld	s3,40(sp)
 91c:	6161                	addi	sp,sp,80
 91e:	8082                	ret
    x = -xx;
 920:	40b005b3          	neg	a1,a1
    neg = 1;
 924:	4885                	li	a7,1
    x = -xx;
 926:	bfbd                	j	8a4 <printint+0x18>

0000000000000928 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %c, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 928:	7119                	addi	sp,sp,-128
 92a:	fc86                	sd	ra,120(sp)
 92c:	f8a2                	sd	s0,112(sp)
 92e:	f4a6                	sd	s1,104(sp)
 930:	f0ca                	sd	s2,96(sp)
 932:	ecce                	sd	s3,88(sp)
 934:	e8d2                	sd	s4,80(sp)
 936:	e4d6                	sd	s5,72(sp)
 938:	e0da                	sd	s6,64(sp)
 93a:	fc5e                	sd	s7,56(sp)
 93c:	f862                	sd	s8,48(sp)
 93e:	f466                	sd	s9,40(sp)
 940:	f06a                	sd	s10,32(sp)
 942:	ec6e                	sd	s11,24(sp)
 944:	0100                	addi	s0,sp,128
  char *s;
  int c0, c1, c2, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 946:	0005c903          	lbu	s2,0(a1)
 94a:	24090c63          	beqz	s2,ba2 <vprintf+0x27a>
 94e:	8b2a                	mv	s6,a0
 950:	8a2e                	mv	s4,a1
 952:	8bb2                	mv	s7,a2
  state = 0;
 954:	4981                	li	s3,0
  for(i = 0; fmt[i]; i++){
 956:	4481                	li	s1,0
 958:	4701                	li	a4,0
      if(c0 == '%'){
        state = '%';
      } else {
        putc(fd, c0);
      }
    } else if(state == '%'){
 95a:	02500a93          	li	s5,37
      c1 = c2 = 0;
      if(c0) c1 = fmt[i+1] & 0xff;
      if(c1) c2 = fmt[i+2] & 0xff;
      if(c0 == 'd'){
 95e:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c0 == 'l' && c1 == 'd'){
 962:	06c00d13          	li	s10,108
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 2;
      } else if(c0 == 'u'){
 966:	07500d93          	li	s11,117
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 96a:	00000c97          	auipc	s9,0x0
 96e:	6fec8c93          	addi	s9,s9,1790 # 1068 <digits>
 972:	a005                	j	992 <vprintf+0x6a>
        putc(fd, c0);
 974:	85ca                	mv	a1,s2
 976:	855a                	mv	a0,s6
 978:	ef7ff0ef          	jal	ra,86e <putc>
 97c:	a019                	j	982 <vprintf+0x5a>
    } else if(state == '%'){
 97e:	03598263          	beq	s3,s5,9a2 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 982:	2485                	addiw	s1,s1,1
 984:	8726                	mv	a4,s1
 986:	009a07b3          	add	a5,s4,s1
 98a:	0007c903          	lbu	s2,0(a5)
 98e:	20090a63          	beqz	s2,ba2 <vprintf+0x27a>
    c0 = fmt[i] & 0xff;
 992:	0009079b          	sext.w	a5,s2
    if(state == 0){
 996:	fe0994e3          	bnez	s3,97e <vprintf+0x56>
      if(c0 == '%'){
 99a:	fd579de3          	bne	a5,s5,974 <vprintf+0x4c>
        state = '%';
 99e:	89be                	mv	s3,a5
 9a0:	b7cd                	j	982 <vprintf+0x5a>
      if(c0) c1 = fmt[i+1] & 0xff;
 9a2:	c3c1                	beqz	a5,a22 <vprintf+0xfa>
 9a4:	00ea06b3          	add	a3,s4,a4
 9a8:	0016c683          	lbu	a3,1(a3)
      c1 = c2 = 0;
 9ac:	8636                	mv	a2,a3
      if(c1) c2 = fmt[i+2] & 0xff;
 9ae:	c681                	beqz	a3,9b6 <vprintf+0x8e>
 9b0:	9752                	add	a4,a4,s4
 9b2:	00274603          	lbu	a2,2(a4)
      if(c0 == 'd'){
 9b6:	03878e63          	beq	a5,s8,9f2 <vprintf+0xca>
      } else if(c0 == 'l' && c1 == 'd'){
 9ba:	05a78863          	beq	a5,s10,a0a <vprintf+0xe2>
      } else if(c0 == 'u'){
 9be:	0db78b63          	beq	a5,s11,a94 <vprintf+0x16c>
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 2;
      } else if(c0 == 'x'){
 9c2:	07800713          	li	a4,120
 9c6:	10e78d63          	beq	a5,a4,ae0 <vprintf+0x1b8>
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 2;
      } else if(c0 == 'p'){
 9ca:	07000713          	li	a4,112
 9ce:	14e78263          	beq	a5,a4,b12 <vprintf+0x1ea>
        printptr(fd, va_arg(ap, uint64));
      } else if(c0 == 'c'){
 9d2:	06300713          	li	a4,99
 9d6:	16e78f63          	beq	a5,a4,b54 <vprintf+0x22c>
        putc(fd, va_arg(ap, uint32));
      } else if(c0 == 's'){
 9da:	07300713          	li	a4,115
 9de:	18e78563          	beq	a5,a4,b68 <vprintf+0x240>
        if((s = va_arg(ap, char*)) == 0)
          s = "(null)";
        for(; *s; s++)
          putc(fd, *s);
      } else if(c0 == '%'){
 9e2:	05579063          	bne	a5,s5,a22 <vprintf+0xfa>
        putc(fd, '%');
 9e6:	85d6                	mv	a1,s5
 9e8:	855a                	mv	a0,s6
 9ea:	e85ff0ef          	jal	ra,86e <putc>
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c0);
      }

      state = 0;
 9ee:	4981                	li	s3,0
 9f0:	bf49                	j	982 <vprintf+0x5a>
        printint(fd, va_arg(ap, int), 10, 1);
 9f2:	008b8913          	addi	s2,s7,8
 9f6:	4685                	li	a3,1
 9f8:	4629                	li	a2,10
 9fa:	000ba583          	lw	a1,0(s7)
 9fe:	855a                	mv	a0,s6
 a00:	e8dff0ef          	jal	ra,88c <printint>
 a04:	8bca                	mv	s7,s2
      state = 0;
 a06:	4981                	li	s3,0
 a08:	bfad                	j	982 <vprintf+0x5a>
      } else if(c0 == 'l' && c1 == 'd'){
 a0a:	03868663          	beq	a3,s8,a36 <vprintf+0x10e>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 a0e:	05a68163          	beq	a3,s10,a50 <vprintf+0x128>
      } else if(c0 == 'l' && c1 == 'u'){
 a12:	09b68d63          	beq	a3,s11,aac <vprintf+0x184>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 a16:	03a68f63          	beq	a3,s10,a54 <vprintf+0x12c>
      } else if(c0 == 'l' && c1 == 'x'){
 a1a:	07800793          	li	a5,120
 a1e:	0cf68d63          	beq	a3,a5,af8 <vprintf+0x1d0>
        putc(fd, '%');
 a22:	85d6                	mv	a1,s5
 a24:	855a                	mv	a0,s6
 a26:	e49ff0ef          	jal	ra,86e <putc>
        putc(fd, c0);
 a2a:	85ca                	mv	a1,s2
 a2c:	855a                	mv	a0,s6
 a2e:	e41ff0ef          	jal	ra,86e <putc>
      state = 0;
 a32:	4981                	li	s3,0
 a34:	b7b9                	j	982 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 a36:	008b8913          	addi	s2,s7,8
 a3a:	4685                	li	a3,1
 a3c:	4629                	li	a2,10
 a3e:	000bb583          	ld	a1,0(s7)
 a42:	855a                	mv	a0,s6
 a44:	e49ff0ef          	jal	ra,88c <printint>
        i += 1;
 a48:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 1);
 a4a:	8bca                	mv	s7,s2
      state = 0;
 a4c:	4981                	li	s3,0
        i += 1;
 a4e:	bf15                	j	982 <vprintf+0x5a>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 a50:	03860563          	beq	a2,s8,a7a <vprintf+0x152>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 a54:	07b60963          	beq	a2,s11,ac6 <vprintf+0x19e>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
 a58:	07800793          	li	a5,120
 a5c:	fcf613e3          	bne	a2,a5,a22 <vprintf+0xfa>
        printint(fd, va_arg(ap, uint64), 16, 0);
 a60:	008b8913          	addi	s2,s7,8
 a64:	4681                	li	a3,0
 a66:	4641                	li	a2,16
 a68:	000bb583          	ld	a1,0(s7)
 a6c:	855a                	mv	a0,s6
 a6e:	e1fff0ef          	jal	ra,88c <printint>
        i += 2;
 a72:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 16, 0);
 a74:	8bca                	mv	s7,s2
      state = 0;
 a76:	4981                	li	s3,0
        i += 2;
 a78:	b729                	j	982 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 a7a:	008b8913          	addi	s2,s7,8
 a7e:	4685                	li	a3,1
 a80:	4629                	li	a2,10
 a82:	000bb583          	ld	a1,0(s7)
 a86:	855a                	mv	a0,s6
 a88:	e05ff0ef          	jal	ra,88c <printint>
        i += 2;
 a8c:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 1);
 a8e:	8bca                	mv	s7,s2
      state = 0;
 a90:	4981                	li	s3,0
        i += 2;
 a92:	bdc5                	j	982 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint32), 10, 0);
 a94:	008b8913          	addi	s2,s7,8
 a98:	4681                	li	a3,0
 a9a:	4629                	li	a2,10
 a9c:	000be583          	lwu	a1,0(s7)
 aa0:	855a                	mv	a0,s6
 aa2:	debff0ef          	jal	ra,88c <printint>
 aa6:	8bca                	mv	s7,s2
      state = 0;
 aa8:	4981                	li	s3,0
 aaa:	bde1                	j	982 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 aac:	008b8913          	addi	s2,s7,8
 ab0:	4681                	li	a3,0
 ab2:	4629                	li	a2,10
 ab4:	000bb583          	ld	a1,0(s7)
 ab8:	855a                	mv	a0,s6
 aba:	dd3ff0ef          	jal	ra,88c <printint>
        i += 1;
 abe:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 0);
 ac0:	8bca                	mv	s7,s2
      state = 0;
 ac2:	4981                	li	s3,0
        i += 1;
 ac4:	bd7d                	j	982 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 ac6:	008b8913          	addi	s2,s7,8
 aca:	4681                	li	a3,0
 acc:	4629                	li	a2,10
 ace:	000bb583          	ld	a1,0(s7)
 ad2:	855a                	mv	a0,s6
 ad4:	db9ff0ef          	jal	ra,88c <printint>
        i += 2;
 ad8:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 0);
 ada:	8bca                	mv	s7,s2
      state = 0;
 adc:	4981                	li	s3,0
        i += 2;
 ade:	b555                	j	982 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint32), 16, 0);
 ae0:	008b8913          	addi	s2,s7,8
 ae4:	4681                	li	a3,0
 ae6:	4641                	li	a2,16
 ae8:	000be583          	lwu	a1,0(s7)
 aec:	855a                	mv	a0,s6
 aee:	d9fff0ef          	jal	ra,88c <printint>
 af2:	8bca                	mv	s7,s2
      state = 0;
 af4:	4981                	li	s3,0
 af6:	b571                	j	982 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 16, 0);
 af8:	008b8913          	addi	s2,s7,8
 afc:	4681                	li	a3,0
 afe:	4641                	li	a2,16
 b00:	000bb583          	ld	a1,0(s7)
 b04:	855a                	mv	a0,s6
 b06:	d87ff0ef          	jal	ra,88c <printint>
        i += 1;
 b0a:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 16, 0);
 b0c:	8bca                	mv	s7,s2
      state = 0;
 b0e:	4981                	li	s3,0
        i += 1;
 b10:	bd8d                	j	982 <vprintf+0x5a>
        printptr(fd, va_arg(ap, uint64));
 b12:	008b8793          	addi	a5,s7,8
 b16:	f8f43423          	sd	a5,-120(s0)
 b1a:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 b1e:	03000593          	li	a1,48
 b22:	855a                	mv	a0,s6
 b24:	d4bff0ef          	jal	ra,86e <putc>
  putc(fd, 'x');
 b28:	07800593          	li	a1,120
 b2c:	855a                	mv	a0,s6
 b2e:	d41ff0ef          	jal	ra,86e <putc>
 b32:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 b34:	03c9d793          	srli	a5,s3,0x3c
 b38:	97e6                	add	a5,a5,s9
 b3a:	0007c583          	lbu	a1,0(a5)
 b3e:	855a                	mv	a0,s6
 b40:	d2fff0ef          	jal	ra,86e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 b44:	0992                	slli	s3,s3,0x4
 b46:	397d                	addiw	s2,s2,-1
 b48:	fe0916e3          	bnez	s2,b34 <vprintf+0x20c>
        printptr(fd, va_arg(ap, uint64));
 b4c:	f8843b83          	ld	s7,-120(s0)
      state = 0;
 b50:	4981                	li	s3,0
 b52:	bd05                	j	982 <vprintf+0x5a>
        putc(fd, va_arg(ap, uint32));
 b54:	008b8913          	addi	s2,s7,8
 b58:	000bc583          	lbu	a1,0(s7)
 b5c:	855a                	mv	a0,s6
 b5e:	d11ff0ef          	jal	ra,86e <putc>
 b62:	8bca                	mv	s7,s2
      state = 0;
 b64:	4981                	li	s3,0
 b66:	bd31                	j	982 <vprintf+0x5a>
        if((s = va_arg(ap, char*)) == 0)
 b68:	008b8993          	addi	s3,s7,8
 b6c:	000bb903          	ld	s2,0(s7)
 b70:	00090f63          	beqz	s2,b8e <vprintf+0x266>
        for(; *s; s++)
 b74:	00094583          	lbu	a1,0(s2)
 b78:	c195                	beqz	a1,b9c <vprintf+0x274>
          putc(fd, *s);
 b7a:	855a                	mv	a0,s6
 b7c:	cf3ff0ef          	jal	ra,86e <putc>
        for(; *s; s++)
 b80:	0905                	addi	s2,s2,1
 b82:	00094583          	lbu	a1,0(s2)
 b86:	f9f5                	bnez	a1,b7a <vprintf+0x252>
        if((s = va_arg(ap, char*)) == 0)
 b88:	8bce                	mv	s7,s3
      state = 0;
 b8a:	4981                	li	s3,0
 b8c:	bbdd                	j	982 <vprintf+0x5a>
          s = "(null)";
 b8e:	00000917          	auipc	s2,0x0
 b92:	4d290913          	addi	s2,s2,1234 # 1060 <malloc+0x3bc>
        for(; *s; s++)
 b96:	02800593          	li	a1,40
 b9a:	b7c5                	j	b7a <vprintf+0x252>
        if((s = va_arg(ap, char*)) == 0)
 b9c:	8bce                	mv	s7,s3
      state = 0;
 b9e:	4981                	li	s3,0
 ba0:	b3cd                	j	982 <vprintf+0x5a>
    }
  }
}
 ba2:	70e6                	ld	ra,120(sp)
 ba4:	7446                	ld	s0,112(sp)
 ba6:	74a6                	ld	s1,104(sp)
 ba8:	7906                	ld	s2,96(sp)
 baa:	69e6                	ld	s3,88(sp)
 bac:	6a46                	ld	s4,80(sp)
 bae:	6aa6                	ld	s5,72(sp)
 bb0:	6b06                	ld	s6,64(sp)
 bb2:	7be2                	ld	s7,56(sp)
 bb4:	7c42                	ld	s8,48(sp)
 bb6:	7ca2                	ld	s9,40(sp)
 bb8:	7d02                	ld	s10,32(sp)
 bba:	6de2                	ld	s11,24(sp)
 bbc:	6109                	addi	sp,sp,128
 bbe:	8082                	ret

0000000000000bc0 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 bc0:	715d                	addi	sp,sp,-80
 bc2:	ec06                	sd	ra,24(sp)
 bc4:	e822                	sd	s0,16(sp)
 bc6:	1000                	addi	s0,sp,32
 bc8:	e010                	sd	a2,0(s0)
 bca:	e414                	sd	a3,8(s0)
 bcc:	e818                	sd	a4,16(s0)
 bce:	ec1c                	sd	a5,24(s0)
 bd0:	03043023          	sd	a6,32(s0)
 bd4:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 bd8:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 bdc:	8622                	mv	a2,s0
 bde:	d4bff0ef          	jal	ra,928 <vprintf>
}
 be2:	60e2                	ld	ra,24(sp)
 be4:	6442                	ld	s0,16(sp)
 be6:	6161                	addi	sp,sp,80
 be8:	8082                	ret

0000000000000bea <printf>:

void
printf(const char *fmt, ...)
{
 bea:	711d                	addi	sp,sp,-96
 bec:	ec06                	sd	ra,24(sp)
 bee:	e822                	sd	s0,16(sp)
 bf0:	1000                	addi	s0,sp,32
 bf2:	e40c                	sd	a1,8(s0)
 bf4:	e810                	sd	a2,16(s0)
 bf6:	ec14                	sd	a3,24(s0)
 bf8:	f018                	sd	a4,32(s0)
 bfa:	f41c                	sd	a5,40(s0)
 bfc:	03043823          	sd	a6,48(s0)
 c00:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 c04:	00840613          	addi	a2,s0,8
 c08:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 c0c:	85aa                	mv	a1,a0
 c0e:	4505                	li	a0,1
 c10:	d19ff0ef          	jal	ra,928 <vprintf>
}
 c14:	60e2                	ld	ra,24(sp)
 c16:	6442                	ld	s0,16(sp)
 c18:	6125                	addi	sp,sp,96
 c1a:	8082                	ret

0000000000000c1c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 c1c:	1141                	addi	sp,sp,-16
 c1e:	e422                	sd	s0,8(sp)
 c20:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 c22:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 c26:	00001797          	auipc	a5,0x1
 c2a:	3da7b783          	ld	a5,986(a5) # 2000 <freep>
 c2e:	a805                	j	c5e <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 c30:	4618                	lw	a4,8(a2)
 c32:	9db9                	addw	a1,a1,a4
 c34:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 c38:	6398                	ld	a4,0(a5)
 c3a:	6318                	ld	a4,0(a4)
 c3c:	fee53823          	sd	a4,-16(a0)
 c40:	a091                	j	c84 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 c42:	ff852703          	lw	a4,-8(a0)
 c46:	9e39                	addw	a2,a2,a4
 c48:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 c4a:	ff053703          	ld	a4,-16(a0)
 c4e:	e398                	sd	a4,0(a5)
 c50:	a099                	j	c96 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 c52:	6398                	ld	a4,0(a5)
 c54:	00e7e463          	bltu	a5,a4,c5c <free+0x40>
 c58:	00e6ea63          	bltu	a3,a4,c6c <free+0x50>
{
 c5c:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 c5e:	fed7fae3          	bgeu	a5,a3,c52 <free+0x36>
 c62:	6398                	ld	a4,0(a5)
 c64:	00e6e463          	bltu	a3,a4,c6c <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 c68:	fee7eae3          	bltu	a5,a4,c5c <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 c6c:	ff852583          	lw	a1,-8(a0)
 c70:	6390                	ld	a2,0(a5)
 c72:	02059713          	slli	a4,a1,0x20
 c76:	9301                	srli	a4,a4,0x20
 c78:	0712                	slli	a4,a4,0x4
 c7a:	9736                	add	a4,a4,a3
 c7c:	fae60ae3          	beq	a2,a4,c30 <free+0x14>
    bp->s.ptr = p->s.ptr;
 c80:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 c84:	4790                	lw	a2,8(a5)
 c86:	02061713          	slli	a4,a2,0x20
 c8a:	9301                	srli	a4,a4,0x20
 c8c:	0712                	slli	a4,a4,0x4
 c8e:	973e                	add	a4,a4,a5
 c90:	fae689e3          	beq	a3,a4,c42 <free+0x26>
  } else
    p->s.ptr = bp;
 c94:	e394                	sd	a3,0(a5)
  freep = p;
 c96:	00001717          	auipc	a4,0x1
 c9a:	36f73523          	sd	a5,874(a4) # 2000 <freep>
}
 c9e:	6422                	ld	s0,8(sp)
 ca0:	0141                	addi	sp,sp,16
 ca2:	8082                	ret

0000000000000ca4 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 ca4:	7139                	addi	sp,sp,-64
 ca6:	fc06                	sd	ra,56(sp)
 ca8:	f822                	sd	s0,48(sp)
 caa:	f426                	sd	s1,40(sp)
 cac:	f04a                	sd	s2,32(sp)
 cae:	ec4e                	sd	s3,24(sp)
 cb0:	e852                	sd	s4,16(sp)
 cb2:	e456                	sd	s5,8(sp)
 cb4:	e05a                	sd	s6,0(sp)
 cb6:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 cb8:	02051493          	slli	s1,a0,0x20
 cbc:	9081                	srli	s1,s1,0x20
 cbe:	04bd                	addi	s1,s1,15
 cc0:	8091                	srli	s1,s1,0x4
 cc2:	0014899b          	addiw	s3,s1,1
 cc6:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 cc8:	00001517          	auipc	a0,0x1
 ccc:	33853503          	ld	a0,824(a0) # 2000 <freep>
 cd0:	c515                	beqz	a0,cfc <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 cd2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 cd4:	4798                	lw	a4,8(a5)
 cd6:	02977f63          	bgeu	a4,s1,d14 <malloc+0x70>
 cda:	8a4e                	mv	s4,s3
 cdc:	0009871b          	sext.w	a4,s3
 ce0:	6685                	lui	a3,0x1
 ce2:	00d77363          	bgeu	a4,a3,ce8 <malloc+0x44>
 ce6:	6a05                	lui	s4,0x1
 ce8:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 cec:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 cf0:	00001917          	auipc	s2,0x1
 cf4:	31090913          	addi	s2,s2,784 # 2000 <freep>
  if(p == SBRK_ERROR)
 cf8:	5afd                	li	s5,-1
 cfa:	a0bd                	j	d68 <malloc+0xc4>
    base.s.ptr = freep = prevp = &base;
 cfc:	00001797          	auipc	a5,0x1
 d00:	31478793          	addi	a5,a5,788 # 2010 <base>
 d04:	00001717          	auipc	a4,0x1
 d08:	2ef73e23          	sd	a5,764(a4) # 2000 <freep>
 d0c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 d0e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 d12:	b7e1                	j	cda <malloc+0x36>
      if(p->s.size == nunits)
 d14:	02e48b63          	beq	s1,a4,d4a <malloc+0xa6>
        p->s.size -= nunits;
 d18:	4137073b          	subw	a4,a4,s3
 d1c:	c798                	sw	a4,8(a5)
        p += p->s.size;
 d1e:	1702                	slli	a4,a4,0x20
 d20:	9301                	srli	a4,a4,0x20
 d22:	0712                	slli	a4,a4,0x4
 d24:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 d26:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 d2a:	00001717          	auipc	a4,0x1
 d2e:	2ca73b23          	sd	a0,726(a4) # 2000 <freep>
      return (void*)(p + 1);
 d32:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 d36:	70e2                	ld	ra,56(sp)
 d38:	7442                	ld	s0,48(sp)
 d3a:	74a2                	ld	s1,40(sp)
 d3c:	7902                	ld	s2,32(sp)
 d3e:	69e2                	ld	s3,24(sp)
 d40:	6a42                	ld	s4,16(sp)
 d42:	6aa2                	ld	s5,8(sp)
 d44:	6b02                	ld	s6,0(sp)
 d46:	6121                	addi	sp,sp,64
 d48:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 d4a:	6398                	ld	a4,0(a5)
 d4c:	e118                	sd	a4,0(a0)
 d4e:	bff1                	j	d2a <malloc+0x86>
  hp->s.size = nu;
 d50:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 d54:	0541                	addi	a0,a0,16
 d56:	ec7ff0ef          	jal	ra,c1c <free>
  return freep;
 d5a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 d5e:	dd61                	beqz	a0,d36 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 d60:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 d62:	4798                	lw	a4,8(a5)
 d64:	fa9778e3          	bgeu	a4,s1,d14 <malloc+0x70>
    if(p == freep)
 d68:	00093703          	ld	a4,0(s2)
 d6c:	853e                	mv	a0,a5
 d6e:	fef719e3          	bne	a4,a5,d60 <malloc+0xbc>
  p = sbrk(nu * sizeof(Header));
 d72:	8552                	mv	a0,s4
 d74:	a1fff0ef          	jal	ra,792 <sbrk>
  if(p == SBRK_ERROR)
 d78:	fd551ce3          	bne	a0,s5,d50 <malloc+0xac>
        return 0;
 d7c:	4501                	li	a0,0
 d7e:	bf65                	j	d36 <malloc+0x92>
