
user/_proctest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <delay>:

#define SCHED_WORKERS 4      // 明确指定调度器测试的 worker 数量
#define MAX_TEST_PROC 8      // 进程创建测试的最大尝试数

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
   e:	76e000ef          	jal	ra,77c <uptime>
  12:	84aa                	mv	s1,a0
    while (uptime() - start < ticks)
  14:	768000ef          	jal	ra,77c <uptime>
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
  b2:	bf250513          	addi	a0,a0,-1038 # ca0 <malloc+0xe6>
  b6:	24b000ef          	jal	ra,b00 <printf>
    exit(0);
  ba:	4501                	li	a0,0
  bc:	628000ef          	jal	ra,6e4 <exit>

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
  d2:	12068693          	addi	a3,a3,288 # 7a120 <base+0x79110>
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
  ee:	24078793          	addi	a5,a5,576 # f4240 <base+0xf3230>
  f2:	02f5e5b3          	rem	a1,a1,a5
  f6:	00001517          	auipc	a0,0x1
  fa:	bc250513          	addi	a0,a0,-1086 # cb8 <malloc+0xfe>
  fe:	203000ef          	jal	ra,b00 <printf>
    exit(0);
 102:	4501                	li	a0,0
 104:	5e0000ef          	jal	ra,6e4 <exit>

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
 11e:	bbe90913          	addi	s2,s2,-1090 # cd8 <malloc+0x11e>
        write(write_fd, &i, sizeof(i));
 122:	4611                	li	a2,4
 124:	fdc40593          	addi	a1,s0,-36
 128:	8526                	mv	a0,s1
 12a:	5da000ef          	jal	ra,704 <write>
        printf("Produced: %d\n", i);
 12e:	fdc42583          	lw	a1,-36(s0)
 132:	854a                	mv	a0,s2
 134:	1cd000ef          	jal	ra,b00 <printf>
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
 154:	5b8000ef          	jal	ra,70c <close>
    exit(0);
 158:	4501                	li	a0,0
 15a:	58a000ef          	jal	ra,6e4 <exit>

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
 170:	b7c90913          	addi	s2,s2,-1156 # ce8 <malloc+0x12e>
    while (read(read_fd, &val, sizeof(val)) == sizeof(val)) {
 174:	a809                	j	186 <consumer_task+0x28>
        printf("Consumed: %d\n", val);
 176:	fdc42583          	lw	a1,-36(s0)
 17a:	854a                	mv	a0,s2
 17c:	185000ef          	jal	ra,b00 <printf>
        delay(5); // 础保输出不被吞掉
 180:	4515                	li	a0,5
 182:	e7fff0ef          	jal	ra,0 <delay>
    while (read(read_fd, &val, sizeof(val)) == sizeof(val)) {
 186:	4611                	li	a2,4
 188:	fdc40593          	addi	a1,s0,-36
 18c:	8526                	mv	a0,s1
 18e:	56e000ef          	jal	ra,6fc <read>
 192:	4791                	li	a5,4
 194:	fef501e3          	beq	a0,a5,176 <consumer_task+0x18>
    }
    close(read_fd);
 198:	8526                	mv	a0,s1
 19a:	572000ef          	jal	ra,70c <close>
    exit(0);
 19e:	4501                	li	a0,0
 1a0:	544000ef          	jal	ra,6e4 <exit>

00000000000001a4 <debug_proc_table>:
}

// ==========================
// 5. 调试进程表（模拟输出）
// ==========================
void debug_proc_table(void) {
 1a4:	1141                	addi	sp,sp,-16
 1a6:	e406                	sd	ra,8(sp)
 1a8:	e022                	sd	s0,0(sp)
 1aa:	0800                	addi	s0,sp,16
    printf("=== Process Table Debug (simulated) ===\n");
 1ac:	00001517          	auipc	a0,0x1
 1b0:	b4c50513          	addi	a0,a0,-1204 # cf8 <malloc+0x13e>
 1b4:	14d000ef          	jal	ra,b00 <printf>
    printf("PID | State | Name\n");
 1b8:	00001517          	auipc	a0,0x1
 1bc:	b7050513          	addi	a0,a0,-1168 # d28 <malloc+0x16e>
 1c0:	141000ef          	jal	ra,b00 <printf>
    printf("1   | RUN   | init\n");
 1c4:	00001517          	auipc	a0,0x1
 1c8:	b7c50513          	addi	a0,a0,-1156 # d40 <malloc+0x186>
 1cc:	135000ef          	jal	ra,b00 <printf>
    printf("2   | SLEEP | sh\n");
 1d0:	00001517          	auipc	a0,0x1
 1d4:	b8850513          	addi	a0,a0,-1144 # d58 <malloc+0x19e>
 1d8:	129000ef          	jal	ra,b00 <printf>
    printf("... (actual table not accessible from user space)\n");
 1dc:	00001517          	auipc	a0,0x1
 1e0:	b9450513          	addi	a0,a0,-1132 # d70 <malloc+0x1b6>
 1e4:	11d000ef          	jal	ra,b00 <printf>
}
 1e8:	60a2                	ld	ra,8(sp)
 1ea:	6402                	ld	s0,0(sp)
 1ec:	0141                	addi	sp,sp,16
 1ee:	8082                	ret

00000000000001f0 <test_process_creation>:

// ==========================
// 6. 测试进程创建
// ==========================
void test_process_creation(void) {
 1f0:	1101                	addi	sp,sp,-32
 1f2:	ec06                	sd	ra,24(sp)
 1f4:	e822                	sd	s0,16(sp)
 1f6:	e426                	sd	s1,8(sp)
 1f8:	e04a                	sd	s2,0(sp)
 1fa:	1000                	addi	s0,sp,32
    printf("Testing process creation...\n");
 1fc:	00001517          	auipc	a0,0x1
 200:	bac50513          	addi	a0,a0,-1108 # da8 <malloc+0x1ee>
 204:	0fd000ef          	jal	ra,b00 <printf>

    int total_created = 0;

    // 第一个子进程：用于打印消息
    int pid = fork();
 208:	4d4000ef          	jal	ra,6dc <fork>
    if (pid < 0) {
 20c:	04054663          	bltz	a0,258 <test_process_creation+0x68>
        printf("fork failed!\n");
    } else if (pid == 0) {
 210:	cd21                	beqz	a0,268 <test_process_creation+0x78>
        printf("Child process running\n");
        exit(0);
    } else {
        total_created++;
        wait((int *)0);
 212:	4501                	li	a0,0
 214:	4d8000ef          	jal	ra,6ec <wait>
        total_created++;
 218:	4485                	li	s1,1
    }

    // 批量创建 MAX_TEST_PROC 个子进程
    for (int i = 0; i < MAX_TEST_PROC; i++) {
 21a:	0084891b          	addiw	s2,s1,8
        pid = fork();
 21e:	4be000ef          	jal	ra,6dc <fork>
        if (pid < 0) {
 222:	04054c63          	bltz	a0,27a <test_process_creation+0x8a>
            // fork 失败，停止创建
            break;
        }
        if (pid == 0) {
 226:	c52d                	beqz	a0,290 <test_process_creation+0xa0>
            // 子进程什么都不做，直接退出
            exit(0);
        }
        total_created++;
 228:	2485                	addiw	s1,s1,1
    for (int i = 0; i < MAX_TEST_PROC; i++) {
 22a:	fe991ae3          	bne	s2,s1,21e <test_process_creation+0x2e>
    }

    printf("Created %d processes\n", total_created);
 22e:	85a6                	mv	a1,s1
 230:	00001517          	auipc	a0,0x1
 234:	bc050513          	addi	a0,a0,-1088 # df0 <malloc+0x236>
 238:	0c9000ef          	jal	ra,b00 <printf>

    // 等待剩余子进程（第一个已 wait，这里等剩下的）
    for (int i = 0; i < total_created - 1; i++) {
 23c:	34fd                	addiw	s1,s1,-1
 23e:	4901                	li	s2,0
        wait((int *)0);
 240:	4501                	li	a0,0
 242:	4aa000ef          	jal	ra,6ec <wait>
    for (int i = 0; i < total_created - 1; i++) {
 246:	2905                	addiw	s2,s2,1
 248:	fe991ce3          	bne	s2,s1,240 <test_process_creation+0x50>
    }
}
 24c:	60e2                	ld	ra,24(sp)
 24e:	6442                	ld	s0,16(sp)
 250:	64a2                	ld	s1,8(sp)
 252:	6902                	ld	s2,0(sp)
 254:	6105                	addi	sp,sp,32
 256:	8082                	ret
        printf("fork failed!\n");
 258:	00001517          	auipc	a0,0x1
 25c:	b7050513          	addi	a0,a0,-1168 # dc8 <malloc+0x20e>
 260:	0a1000ef          	jal	ra,b00 <printf>
    int total_created = 0;
 264:	4481                	li	s1,0
 266:	bf55                	j	21a <test_process_creation+0x2a>
        printf("Child process running\n");
 268:	00001517          	auipc	a0,0x1
 26c:	b7050513          	addi	a0,a0,-1168 # dd8 <malloc+0x21e>
 270:	091000ef          	jal	ra,b00 <printf>
        exit(0);
 274:	4501                	li	a0,0
 276:	46e000ef          	jal	ra,6e4 <exit>
    printf("Created %d processes\n", total_created);
 27a:	85a6                	mv	a1,s1
 27c:	00001517          	auipc	a0,0x1
 280:	b7450513          	addi	a0,a0,-1164 # df0 <malloc+0x236>
 284:	07d000ef          	jal	ra,b00 <printf>
    for (int i = 0; i < total_created - 1; i++) {
 288:	4785                	li	a5,1
 28a:	fa97c9e3          	blt	a5,s1,23c <test_process_creation+0x4c>
 28e:	bf7d                	j	24c <test_process_creation+0x5c>
            exit(0);
 290:	454000ef          	jal	ra,6e4 <exit>

0000000000000294 <test_scheduler>:

// ==========================
// 7. 测试调度器（时间片轮转）
// ==========================
void test_scheduler(void) {
 294:	7139                	addi	sp,sp,-64
 296:	fc06                	sd	ra,56(sp)
 298:	f822                	sd	s0,48(sp)
 29a:	f426                	sd	s1,40(sp)
 29c:	f04a                	sd	s2,32(sp)
 29e:	ec4e                	sd	s3,24(sp)
 2a0:	0080                	addi	s0,sp,64
    printf("Testing scheduler with %d workers...\n", SCHED_WORKERS);
 2a2:	4591                	li	a1,4
 2a4:	00001517          	auipc	a0,0x1
 2a8:	b6450513          	addi	a0,a0,-1180 # e08 <malloc+0x24e>
 2ac:	055000ef          	jal	ra,b00 <printf>

    int start_time = uptime();
 2b0:	4cc000ef          	jal	ra,77c <uptime>
 2b4:	89aa                	mv	s3,a0
    int created = 0;
 2b6:	4901                	li	s2,0

    for (int i = 0; i < SCHED_WORKERS; i++) {
 2b8:	4491                	li	s1,4
        int pid = fork();
 2ba:	422000ef          	jal	ra,6dc <fork>
        if (pid < 0) {
 2be:	02054e63          	bltz	a0,2fa <test_scheduler+0x66>
            printf("fork failed at worker %d\n", i);
            break;
        }
        if (pid == 0) {
 2c2:	c531                	beqz	a0,30e <test_scheduler+0x7a>
                x += j;
            }
            printf("Worker %d finished\n", i);
            exit(0);
        }
        created++;
 2c4:	2905                	addiw	s2,s2,1
    for (int i = 0; i < SCHED_WORKERS; i++) {
 2c6:	fe991ae3          	bne	s2,s1,2ba <test_scheduler+0x26>
            for (long j = 0; j < 200000; j++) {
 2ca:	4481                	li	s1,0
    }

    // 等待所有成功创建的子进程
    for (int i = 0; i < created; i++) {
        wait((int *)0);
 2cc:	4501                	li	a0,0
 2ce:	41e000ef          	jal	ra,6ec <wait>
    for (int i = 0; i < created; i++) {
 2d2:	2485                	addiw	s1,s1,1
 2d4:	fe991ce3          	bne	s2,s1,2cc <test_scheduler+0x38>
    }

    int end_time = uptime();
 2d8:	4a4000ef          	jal	ra,77c <uptime>
    printf("Scheduler test completed in %d ticks\n", end_time - start_time);
 2dc:	413505bb          	subw	a1,a0,s3
 2e0:	00001517          	auipc	a0,0x1
 2e4:	b8850513          	addi	a0,a0,-1144 # e68 <malloc+0x2ae>
 2e8:	019000ef          	jal	ra,b00 <printf>
}
 2ec:	70e2                	ld	ra,56(sp)
 2ee:	7442                	ld	s0,48(sp)
 2f0:	74a2                	ld	s1,40(sp)
 2f2:	7902                	ld	s2,32(sp)
 2f4:	69e2                	ld	s3,24(sp)
 2f6:	6121                	addi	sp,sp,64
 2f8:	8082                	ret
            printf("fork failed at worker %d\n", i);
 2fa:	85ca                	mv	a1,s2
 2fc:	00001517          	auipc	a0,0x1
 300:	b3450513          	addi	a0,a0,-1228 # e30 <malloc+0x276>
 304:	7fc000ef          	jal	ra,b00 <printf>
    for (int i = 0; i < created; i++) {
 308:	fd2041e3          	bgtz	s2,2ca <test_scheduler+0x36>
 30c:	b7f1                	j	2d8 <test_scheduler+0x44>
            volatile long x = 0;
 30e:	fc043423          	sd	zero,-56(s0)
            for (long j = 0; j < 200000; j++) {
 312:	4781                	li	a5,0
 314:	000316b7          	lui	a3,0x31
 318:	d4068693          	addi	a3,a3,-704 # 30d40 <base+0x2fd30>
                x += j;
 31c:	fc843703          	ld	a4,-56(s0)
 320:	973e                	add	a4,a4,a5
 322:	fce43423          	sd	a4,-56(s0)
            for (long j = 0; j < 200000; j++) {
 326:	0785                	addi	a5,a5,1
 328:	fed79ae3          	bne	a5,a3,31c <test_scheduler+0x88>
            printf("Worker %d finished\n", i);
 32c:	85ca                	mv	a1,s2
 32e:	00001517          	auipc	a0,0x1
 332:	b2250513          	addi	a0,a0,-1246 # e50 <malloc+0x296>
 336:	7ca000ef          	jal	ra,b00 <printf>
            exit(0);
 33a:	4501                	li	a0,0
 33c:	3a8000ef          	jal	ra,6e4 <exit>

0000000000000340 <test_synchronization>:

// ==========================
// 8. 测试同步（pipe 实现生产者-消费者）
// ==========================
void test_synchronization(void) {
 340:	1101                	addi	sp,sp,-32
 342:	ec06                	sd	ra,24(sp)
 344:	e822                	sd	s0,16(sp)
 346:	1000                	addi	s0,sp,32
    printf("Testing synchronization (basic producer-consumer)...\n");
 348:	00001517          	auipc	a0,0x1
 34c:	b4850513          	addi	a0,a0,-1208 # e90 <malloc+0x2d6>
 350:	7b0000ef          	jal	ra,b00 <printf>

    int pipefd[2];
    if (pipe(pipefd) != 0) {
 354:	fe840513          	addi	a0,s0,-24
 358:	39c000ef          	jal	ra,6f4 <pipe>
 35c:	e139                	bnez	a0,3a2 <test_synchronization+0x62>
        printf("pipe failed!\n");
        exit(1);
    }

    int pid1 = fork();
 35e:	37e000ef          	jal	ra,6dc <fork>
    if (pid1 < 0) {
 362:	04054963          	bltz	a0,3b4 <test_synchronization+0x74>
        printf("fork producer failed\n");
        exit(1);
    }
    if (pid1 == 0) {
 366:	c125                	beqz	a0,3c6 <test_synchronization+0x86>
        close(pipefd[0]);
        producer_task(pipefd[1]);
    }

    int pid2 = fork();
 368:	374000ef          	jal	ra,6dc <fork>
    if (pid2 < 0) {
 36c:	06054563          	bltz	a0,3d6 <test_synchronization+0x96>
        printf("fork consumer failed\n");
        exit(1);
    }
    if (pid2 == 0) {
 370:	cd25                	beqz	a0,3e8 <test_synchronization+0xa8>
        close(pipefd[1]);
        consumer_task(pipefd[0]);
    }

    // 父进程关闭 pipe 并等待
    close(pipefd[0]);
 372:	fe842503          	lw	a0,-24(s0)
 376:	396000ef          	jal	ra,70c <close>
    close(pipefd[1]);
 37a:	fec42503          	lw	a0,-20(s0)
 37e:	38e000ef          	jal	ra,70c <close>

    wait((int *)0); // 等待任意一个子进程
 382:	4501                	li	a0,0
 384:	368000ef          	jal	ra,6ec <wait>
    wait((int *)0); // 等待另一个
 388:	4501                	li	a0,0
 38a:	362000ef          	jal	ra,6ec <wait>

    printf("Synchronization test completed\n");
 38e:	00001517          	auipc	a0,0x1
 392:	b7a50513          	addi	a0,a0,-1158 # f08 <malloc+0x34e>
 396:	76a000ef          	jal	ra,b00 <printf>
}
 39a:	60e2                	ld	ra,24(sp)
 39c:	6442                	ld	s0,16(sp)
 39e:	6105                	addi	sp,sp,32
 3a0:	8082                	ret
        printf("pipe failed!\n");
 3a2:	00001517          	auipc	a0,0x1
 3a6:	b2650513          	addi	a0,a0,-1242 # ec8 <malloc+0x30e>
 3aa:	756000ef          	jal	ra,b00 <printf>
        exit(1);
 3ae:	4505                	li	a0,1
 3b0:	334000ef          	jal	ra,6e4 <exit>
        printf("fork producer failed\n");
 3b4:	00001517          	auipc	a0,0x1
 3b8:	b2450513          	addi	a0,a0,-1244 # ed8 <malloc+0x31e>
 3bc:	744000ef          	jal	ra,b00 <printf>
        exit(1);
 3c0:	4505                	li	a0,1
 3c2:	322000ef          	jal	ra,6e4 <exit>
        close(pipefd[0]);
 3c6:	fe842503          	lw	a0,-24(s0)
 3ca:	342000ef          	jal	ra,70c <close>
        producer_task(pipefd[1]);
 3ce:	fec42503          	lw	a0,-20(s0)
 3d2:	d37ff0ef          	jal	ra,108 <producer_task>
        printf("fork consumer failed\n");
 3d6:	00001517          	auipc	a0,0x1
 3da:	b1a50513          	addi	a0,a0,-1254 # ef0 <malloc+0x336>
 3de:	722000ef          	jal	ra,b00 <printf>
        exit(1);
 3e2:	4505                	li	a0,1
 3e4:	300000ef          	jal	ra,6e4 <exit>
        close(pipefd[1]);
 3e8:	fec42503          	lw	a0,-20(s0)
 3ec:	320000ef          	jal	ra,70c <close>
        consumer_task(pipefd[0]);
 3f0:	fe842503          	lw	a0,-24(s0)
 3f4:	d6bff0ef          	jal	ra,15e <consumer_task>

00000000000003f8 <main>:

// ==========================
// 主函数
// ==========================
int main(int argc, char *argv[]) {
 3f8:	1141                	addi	sp,sp,-16
 3fa:	e406                	sd	ra,8(sp)
 3fc:	e022                	sd	s0,0(sp)
 3fe:	0800                	addi	s0,sp,16
    printf("=== Starting xv6 Comprehensive Test Suite ===\n");
 400:	00001517          	auipc	a0,0x1
 404:	b2850513          	addi	a0,a0,-1240 # f28 <malloc+0x36e>
 408:	6f8000ef          	jal	ra,b00 <printf>

    debug_proc_table();
 40c:	d99ff0ef          	jal	ra,1a4 <debug_proc_table>
    test_process_creation();
 410:	de1ff0ef          	jal	ra,1f0 <test_process_creation>
    test_scheduler();
 414:	e81ff0ef          	jal	ra,294 <test_scheduler>
    test_synchronization();
 418:	f29ff0ef          	jal	ra,340 <test_synchronization>

    // 单独测试简单任务
    if (fork() == 0) {
 41c:	2c0000ef          	jal	ra,6dc <fork>
 420:	e119                	bnez	a0,426 <main+0x2e>
        simple_task();
 422:	c85ff0ef          	jal	ra,a6 <simple_task>
    }
    wait((int *)0);
 426:	4501                	li	a0,0
 428:	2c4000ef          	jal	ra,6ec <wait>

    if (fork() == 0) {
 42c:	2b0000ef          	jal	ra,6dc <fork>
 430:	e119                	bnez	a0,436 <main+0x3e>
        cpu_intensive_task();
 432:	c8fff0ef          	jal	ra,c0 <cpu_intensive_task>
    }
    wait((int *)0);
 436:	4501                	li	a0,0
 438:	2b4000ef          	jal	ra,6ec <wait>

    printf("=== All tests completed ===\n");
 43c:	00001517          	auipc	a0,0x1
 440:	b1c50513          	addi	a0,a0,-1252 # f58 <malloc+0x39e>
 444:	6bc000ef          	jal	ra,b00 <printf>
    exit(0);
 448:	4501                	li	a0,0
 44a:	29a000ef          	jal	ra,6e4 <exit>

000000000000044e <start>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
start(int argc, char **argv)
{
 44e:	1141                	addi	sp,sp,-16
 450:	e406                	sd	ra,8(sp)
 452:	e022                	sd	s0,0(sp)
 454:	0800                	addi	s0,sp,16
  int r;
  extern int main(int argc, char **argv);
  r = main(argc, argv);
 456:	fa3ff0ef          	jal	ra,3f8 <main>
  exit(r);
 45a:	28a000ef          	jal	ra,6e4 <exit>

000000000000045e <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 45e:	1141                	addi	sp,sp,-16
 460:	e422                	sd	s0,8(sp)
 462:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 464:	87aa                	mv	a5,a0
 466:	0585                	addi	a1,a1,1
 468:	0785                	addi	a5,a5,1
 46a:	fff5c703          	lbu	a4,-1(a1)
 46e:	fee78fa3          	sb	a4,-1(a5)
 472:	fb75                	bnez	a4,466 <strcpy+0x8>
    ;
  return os;
}
 474:	6422                	ld	s0,8(sp)
 476:	0141                	addi	sp,sp,16
 478:	8082                	ret

000000000000047a <strcmp>:

int
strcmp(const char *p, const char *q)
{
 47a:	1141                	addi	sp,sp,-16
 47c:	e422                	sd	s0,8(sp)
 47e:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 480:	00054783          	lbu	a5,0(a0)
 484:	cb91                	beqz	a5,498 <strcmp+0x1e>
 486:	0005c703          	lbu	a4,0(a1)
 48a:	00f71763          	bne	a4,a5,498 <strcmp+0x1e>
    p++, q++;
 48e:	0505                	addi	a0,a0,1
 490:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 492:	00054783          	lbu	a5,0(a0)
 496:	fbe5                	bnez	a5,486 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 498:	0005c503          	lbu	a0,0(a1)
}
 49c:	40a7853b          	subw	a0,a5,a0
 4a0:	6422                	ld	s0,8(sp)
 4a2:	0141                	addi	sp,sp,16
 4a4:	8082                	ret

00000000000004a6 <strlen>:

uint
strlen(const char *s)
{
 4a6:	1141                	addi	sp,sp,-16
 4a8:	e422                	sd	s0,8(sp)
 4aa:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 4ac:	00054783          	lbu	a5,0(a0)
 4b0:	cf91                	beqz	a5,4cc <strlen+0x26>
 4b2:	0505                	addi	a0,a0,1
 4b4:	87aa                	mv	a5,a0
 4b6:	4685                	li	a3,1
 4b8:	9e89                	subw	a3,a3,a0
 4ba:	00f6853b          	addw	a0,a3,a5
 4be:	0785                	addi	a5,a5,1
 4c0:	fff7c703          	lbu	a4,-1(a5)
 4c4:	fb7d                	bnez	a4,4ba <strlen+0x14>
    ;
  return n;
}
 4c6:	6422                	ld	s0,8(sp)
 4c8:	0141                	addi	sp,sp,16
 4ca:	8082                	ret
  for(n = 0; s[n]; n++)
 4cc:	4501                	li	a0,0
 4ce:	bfe5                	j	4c6 <strlen+0x20>

00000000000004d0 <memset>:

void*
memset(void *dst, int c, uint n)
{
 4d0:	1141                	addi	sp,sp,-16
 4d2:	e422                	sd	s0,8(sp)
 4d4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 4d6:	ca19                	beqz	a2,4ec <memset+0x1c>
 4d8:	87aa                	mv	a5,a0
 4da:	1602                	slli	a2,a2,0x20
 4dc:	9201                	srli	a2,a2,0x20
 4de:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 4e2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 4e6:	0785                	addi	a5,a5,1
 4e8:	fee79de3          	bne	a5,a4,4e2 <memset+0x12>
  }
  return dst;
}
 4ec:	6422                	ld	s0,8(sp)
 4ee:	0141                	addi	sp,sp,16
 4f0:	8082                	ret

00000000000004f2 <strchr>:

char*
strchr(const char *s, char c)
{
 4f2:	1141                	addi	sp,sp,-16
 4f4:	e422                	sd	s0,8(sp)
 4f6:	0800                	addi	s0,sp,16
  for(; *s; s++)
 4f8:	00054783          	lbu	a5,0(a0)
 4fc:	cb99                	beqz	a5,512 <strchr+0x20>
    if(*s == c)
 4fe:	00f58763          	beq	a1,a5,50c <strchr+0x1a>
  for(; *s; s++)
 502:	0505                	addi	a0,a0,1
 504:	00054783          	lbu	a5,0(a0)
 508:	fbfd                	bnez	a5,4fe <strchr+0xc>
      return (char*)s;
  return 0;
 50a:	4501                	li	a0,0
}
 50c:	6422                	ld	s0,8(sp)
 50e:	0141                	addi	sp,sp,16
 510:	8082                	ret
  return 0;
 512:	4501                	li	a0,0
 514:	bfe5                	j	50c <strchr+0x1a>

0000000000000516 <gets>:

char*
gets(char *buf, int max)
{
 516:	711d                	addi	sp,sp,-96
 518:	ec86                	sd	ra,88(sp)
 51a:	e8a2                	sd	s0,80(sp)
 51c:	e4a6                	sd	s1,72(sp)
 51e:	e0ca                	sd	s2,64(sp)
 520:	fc4e                	sd	s3,56(sp)
 522:	f852                	sd	s4,48(sp)
 524:	f456                	sd	s5,40(sp)
 526:	f05a                	sd	s6,32(sp)
 528:	ec5e                	sd	s7,24(sp)
 52a:	1080                	addi	s0,sp,96
 52c:	8baa                	mv	s7,a0
 52e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 530:	892a                	mv	s2,a0
 532:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 534:	4aa9                	li	s5,10
 536:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 538:	89a6                	mv	s3,s1
 53a:	2485                	addiw	s1,s1,1
 53c:	0344d663          	bge	s1,s4,568 <gets+0x52>
    cc = read(0, &c, 1);
 540:	4605                	li	a2,1
 542:	faf40593          	addi	a1,s0,-81
 546:	4501                	li	a0,0
 548:	1b4000ef          	jal	ra,6fc <read>
    if(cc < 1)
 54c:	00a05e63          	blez	a0,568 <gets+0x52>
    buf[i++] = c;
 550:	faf44783          	lbu	a5,-81(s0)
 554:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 558:	01578763          	beq	a5,s5,566 <gets+0x50>
 55c:	0905                	addi	s2,s2,1
 55e:	fd679de3          	bne	a5,s6,538 <gets+0x22>
  for(i=0; i+1 < max; ){
 562:	89a6                	mv	s3,s1
 564:	a011                	j	568 <gets+0x52>
 566:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 568:	99de                	add	s3,s3,s7
 56a:	00098023          	sb	zero,0(s3)
  return buf;
}
 56e:	855e                	mv	a0,s7
 570:	60e6                	ld	ra,88(sp)
 572:	6446                	ld	s0,80(sp)
 574:	64a6                	ld	s1,72(sp)
 576:	6906                	ld	s2,64(sp)
 578:	79e2                	ld	s3,56(sp)
 57a:	7a42                	ld	s4,48(sp)
 57c:	7aa2                	ld	s5,40(sp)
 57e:	7b02                	ld	s6,32(sp)
 580:	6be2                	ld	s7,24(sp)
 582:	6125                	addi	sp,sp,96
 584:	8082                	ret

0000000000000586 <stat>:

int
stat(const char *n, struct stat *st)
{
 586:	1101                	addi	sp,sp,-32
 588:	ec06                	sd	ra,24(sp)
 58a:	e822                	sd	s0,16(sp)
 58c:	e426                	sd	s1,8(sp)
 58e:	e04a                	sd	s2,0(sp)
 590:	1000                	addi	s0,sp,32
 592:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 594:	4581                	li	a1,0
 596:	18e000ef          	jal	ra,724 <open>
  if(fd < 0)
 59a:	02054163          	bltz	a0,5bc <stat+0x36>
 59e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 5a0:	85ca                	mv	a1,s2
 5a2:	19a000ef          	jal	ra,73c <fstat>
 5a6:	892a                	mv	s2,a0
  close(fd);
 5a8:	8526                	mv	a0,s1
 5aa:	162000ef          	jal	ra,70c <close>
  return r;
}
 5ae:	854a                	mv	a0,s2
 5b0:	60e2                	ld	ra,24(sp)
 5b2:	6442                	ld	s0,16(sp)
 5b4:	64a2                	ld	s1,8(sp)
 5b6:	6902                	ld	s2,0(sp)
 5b8:	6105                	addi	sp,sp,32
 5ba:	8082                	ret
    return -1;
 5bc:	597d                	li	s2,-1
 5be:	bfc5                	j	5ae <stat+0x28>

00000000000005c0 <atoi>:

int
atoi(const char *s)
{
 5c0:	1141                	addi	sp,sp,-16
 5c2:	e422                	sd	s0,8(sp)
 5c4:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 5c6:	00054603          	lbu	a2,0(a0)
 5ca:	fd06079b          	addiw	a5,a2,-48
 5ce:	0ff7f793          	andi	a5,a5,255
 5d2:	4725                	li	a4,9
 5d4:	02f76963          	bltu	a4,a5,606 <atoi+0x46>
 5d8:	86aa                	mv	a3,a0
  n = 0;
 5da:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 5dc:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 5de:	0685                	addi	a3,a3,1
 5e0:	0025179b          	slliw	a5,a0,0x2
 5e4:	9fa9                	addw	a5,a5,a0
 5e6:	0017979b          	slliw	a5,a5,0x1
 5ea:	9fb1                	addw	a5,a5,a2
 5ec:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 5f0:	0006c603          	lbu	a2,0(a3)
 5f4:	fd06071b          	addiw	a4,a2,-48
 5f8:	0ff77713          	andi	a4,a4,255
 5fc:	fee5f1e3          	bgeu	a1,a4,5de <atoi+0x1e>
  return n;
}
 600:	6422                	ld	s0,8(sp)
 602:	0141                	addi	sp,sp,16
 604:	8082                	ret
  n = 0;
 606:	4501                	li	a0,0
 608:	bfe5                	j	600 <atoi+0x40>

000000000000060a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 60a:	1141                	addi	sp,sp,-16
 60c:	e422                	sd	s0,8(sp)
 60e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 610:	02b57463          	bgeu	a0,a1,638 <memmove+0x2e>
    while(n-- > 0)
 614:	00c05f63          	blez	a2,632 <memmove+0x28>
 618:	1602                	slli	a2,a2,0x20
 61a:	9201                	srli	a2,a2,0x20
 61c:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 620:	872a                	mv	a4,a0
      *dst++ = *src++;
 622:	0585                	addi	a1,a1,1
 624:	0705                	addi	a4,a4,1
 626:	fff5c683          	lbu	a3,-1(a1)
 62a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 62e:	fee79ae3          	bne	a5,a4,622 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 632:	6422                	ld	s0,8(sp)
 634:	0141                	addi	sp,sp,16
 636:	8082                	ret
    dst += n;
 638:	00c50733          	add	a4,a0,a2
    src += n;
 63c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 63e:	fec05ae3          	blez	a2,632 <memmove+0x28>
 642:	fff6079b          	addiw	a5,a2,-1
 646:	1782                	slli	a5,a5,0x20
 648:	9381                	srli	a5,a5,0x20
 64a:	fff7c793          	not	a5,a5
 64e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 650:	15fd                	addi	a1,a1,-1
 652:	177d                	addi	a4,a4,-1
 654:	0005c683          	lbu	a3,0(a1)
 658:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 65c:	fee79ae3          	bne	a5,a4,650 <memmove+0x46>
 660:	bfc9                	j	632 <memmove+0x28>

0000000000000662 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 662:	1141                	addi	sp,sp,-16
 664:	e422                	sd	s0,8(sp)
 666:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 668:	ca05                	beqz	a2,698 <memcmp+0x36>
 66a:	fff6069b          	addiw	a3,a2,-1
 66e:	1682                	slli	a3,a3,0x20
 670:	9281                	srli	a3,a3,0x20
 672:	0685                	addi	a3,a3,1
 674:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 676:	00054783          	lbu	a5,0(a0)
 67a:	0005c703          	lbu	a4,0(a1)
 67e:	00e79863          	bne	a5,a4,68e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 682:	0505                	addi	a0,a0,1
    p2++;
 684:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 686:	fed518e3          	bne	a0,a3,676 <memcmp+0x14>
  }
  return 0;
 68a:	4501                	li	a0,0
 68c:	a019                	j	692 <memcmp+0x30>
      return *p1 - *p2;
 68e:	40e7853b          	subw	a0,a5,a4
}
 692:	6422                	ld	s0,8(sp)
 694:	0141                	addi	sp,sp,16
 696:	8082                	ret
  return 0;
 698:	4501                	li	a0,0
 69a:	bfe5                	j	692 <memcmp+0x30>

000000000000069c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 69c:	1141                	addi	sp,sp,-16
 69e:	e406                	sd	ra,8(sp)
 6a0:	e022                	sd	s0,0(sp)
 6a2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 6a4:	f67ff0ef          	jal	ra,60a <memmove>
}
 6a8:	60a2                	ld	ra,8(sp)
 6aa:	6402                	ld	s0,0(sp)
 6ac:	0141                	addi	sp,sp,16
 6ae:	8082                	ret

00000000000006b0 <sbrk>:

char *
sbrk(int n) {
 6b0:	1141                	addi	sp,sp,-16
 6b2:	e406                	sd	ra,8(sp)
 6b4:	e022                	sd	s0,0(sp)
 6b6:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_EAGER);
 6b8:	4585                	li	a1,1
 6ba:	0b2000ef          	jal	ra,76c <sys_sbrk>
}
 6be:	60a2                	ld	ra,8(sp)
 6c0:	6402                	ld	s0,0(sp)
 6c2:	0141                	addi	sp,sp,16
 6c4:	8082                	ret

00000000000006c6 <sbrklazy>:

char *
sbrklazy(int n) {
 6c6:	1141                	addi	sp,sp,-16
 6c8:	e406                	sd	ra,8(sp)
 6ca:	e022                	sd	s0,0(sp)
 6cc:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_LAZY);
 6ce:	4589                	li	a1,2
 6d0:	09c000ef          	jal	ra,76c <sys_sbrk>
}
 6d4:	60a2                	ld	ra,8(sp)
 6d6:	6402                	ld	s0,0(sp)
 6d8:	0141                	addi	sp,sp,16
 6da:	8082                	ret

00000000000006dc <fork>:
# 由 usys.pl 生成 - 请勿编辑
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 6dc:	4885                	li	a7,1
 ecall
 6de:	00000073          	ecall
 ret
 6e2:	8082                	ret

00000000000006e4 <exit>:
.global exit
exit:
 li a7, SYS_exit
 6e4:	4889                	li	a7,2
 ecall
 6e6:	00000073          	ecall
 ret
 6ea:	8082                	ret

00000000000006ec <wait>:
.global wait
wait:
 li a7, SYS_wait
 6ec:	488d                	li	a7,3
 ecall
 6ee:	00000073          	ecall
 ret
 6f2:	8082                	ret

00000000000006f4 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 6f4:	4891                	li	a7,4
 ecall
 6f6:	00000073          	ecall
 ret
 6fa:	8082                	ret

00000000000006fc <read>:
.global read
read:
 li a7, SYS_read
 6fc:	4895                	li	a7,5
 ecall
 6fe:	00000073          	ecall
 ret
 702:	8082                	ret

0000000000000704 <write>:
.global write
write:
 li a7, SYS_write
 704:	48c1                	li	a7,16
 ecall
 706:	00000073          	ecall
 ret
 70a:	8082                	ret

000000000000070c <close>:
.global close
close:
 li a7, SYS_close
 70c:	48d5                	li	a7,21
 ecall
 70e:	00000073          	ecall
 ret
 712:	8082                	ret

0000000000000714 <kill>:
.global kill
kill:
 li a7, SYS_kill
 714:	4899                	li	a7,6
 ecall
 716:	00000073          	ecall
 ret
 71a:	8082                	ret

000000000000071c <exec>:
.global exec
exec:
 li a7, SYS_exec
 71c:	489d                	li	a7,7
 ecall
 71e:	00000073          	ecall
 ret
 722:	8082                	ret

0000000000000724 <open>:
.global open
open:
 li a7, SYS_open
 724:	48bd                	li	a7,15
 ecall
 726:	00000073          	ecall
 ret
 72a:	8082                	ret

000000000000072c <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 72c:	48c5                	li	a7,17
 ecall
 72e:	00000073          	ecall
 ret
 732:	8082                	ret

0000000000000734 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 734:	48c9                	li	a7,18
 ecall
 736:	00000073          	ecall
 ret
 73a:	8082                	ret

000000000000073c <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 73c:	48a1                	li	a7,8
 ecall
 73e:	00000073          	ecall
 ret
 742:	8082                	ret

0000000000000744 <link>:
.global link
link:
 li a7, SYS_link
 744:	48cd                	li	a7,19
 ecall
 746:	00000073          	ecall
 ret
 74a:	8082                	ret

000000000000074c <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 74c:	48d1                	li	a7,20
 ecall
 74e:	00000073          	ecall
 ret
 752:	8082                	ret

0000000000000754 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 754:	48a5                	li	a7,9
 ecall
 756:	00000073          	ecall
 ret
 75a:	8082                	ret

000000000000075c <dup>:
.global dup
dup:
 li a7, SYS_dup
 75c:	48a9                	li	a7,10
 ecall
 75e:	00000073          	ecall
 ret
 762:	8082                	ret

0000000000000764 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 764:	48ad                	li	a7,11
 ecall
 766:	00000073          	ecall
 ret
 76a:	8082                	ret

000000000000076c <sys_sbrk>:
.global sys_sbrk
sys_sbrk:
 li a7, SYS_sbrk
 76c:	48b1                	li	a7,12
 ecall
 76e:	00000073          	ecall
 ret
 772:	8082                	ret

0000000000000774 <pause>:
.global pause
pause:
 li a7, SYS_pause
 774:	48b5                	li	a7,13
 ecall
 776:	00000073          	ecall
 ret
 77a:	8082                	ret

000000000000077c <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 77c:	48b9                	li	a7,14
 ecall
 77e:	00000073          	ecall
 ret
 782:	8082                	ret

0000000000000784 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 784:	1101                	addi	sp,sp,-32
 786:	ec06                	sd	ra,24(sp)
 788:	e822                	sd	s0,16(sp)
 78a:	1000                	addi	s0,sp,32
 78c:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 790:	4605                	li	a2,1
 792:	fef40593          	addi	a1,s0,-17
 796:	f6fff0ef          	jal	ra,704 <write>
}
 79a:	60e2                	ld	ra,24(sp)
 79c:	6442                	ld	s0,16(sp)
 79e:	6105                	addi	sp,sp,32
 7a0:	8082                	ret

00000000000007a2 <printint>:

static void
printint(int fd, long long xx, int base, int sgn)
{
 7a2:	715d                	addi	sp,sp,-80
 7a4:	e486                	sd	ra,72(sp)
 7a6:	e0a2                	sd	s0,64(sp)
 7a8:	fc26                	sd	s1,56(sp)
 7aa:	f84a                	sd	s2,48(sp)
 7ac:	f44e                	sd	s3,40(sp)
 7ae:	0880                	addi	s0,sp,80
 7b0:	892a                	mv	s2,a0
  char buf[20];
  int i, neg;
  unsigned long long x;

  neg = 0;
  if(sgn && xx < 0){
 7b2:	c299                	beqz	a3,7b8 <printint+0x16>
 7b4:	0805c163          	bltz	a1,836 <printint+0x94>
  neg = 0;
 7b8:	4881                	li	a7,0
 7ba:	fb840693          	addi	a3,s0,-72
    x = -xx;
  } else {
    x = xx;
  }

  i = 0;
 7be:	4781                	li	a5,0
  do{
    buf[i++] = digits[x % base];
 7c0:	00000517          	auipc	a0,0x0
 7c4:	7c050513          	addi	a0,a0,1984 # f80 <digits>
 7c8:	883e                	mv	a6,a5
 7ca:	2785                	addiw	a5,a5,1
 7cc:	02c5f733          	remu	a4,a1,a2
 7d0:	972a                	add	a4,a4,a0
 7d2:	00074703          	lbu	a4,0(a4)
 7d6:	00e68023          	sb	a4,0(a3)
  }while((x /= base) != 0);
 7da:	872e                	mv	a4,a1
 7dc:	02c5d5b3          	divu	a1,a1,a2
 7e0:	0685                	addi	a3,a3,1
 7e2:	fec773e3          	bgeu	a4,a2,7c8 <printint+0x26>
  if(neg)
 7e6:	00088b63          	beqz	a7,7fc <printint+0x5a>
    buf[i++] = '-';
 7ea:	fd040713          	addi	a4,s0,-48
 7ee:	97ba                	add	a5,a5,a4
 7f0:	02d00713          	li	a4,45
 7f4:	fee78423          	sb	a4,-24(a5)
 7f8:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
 7fc:	02f05663          	blez	a5,828 <printint+0x86>
 800:	fb840713          	addi	a4,s0,-72
 804:	00f704b3          	add	s1,a4,a5
 808:	fff70993          	addi	s3,a4,-1
 80c:	99be                	add	s3,s3,a5
 80e:	37fd                	addiw	a5,a5,-1
 810:	1782                	slli	a5,a5,0x20
 812:	9381                	srli	a5,a5,0x20
 814:	40f989b3          	sub	s3,s3,a5
    putc(fd, buf[i]);
 818:	fff4c583          	lbu	a1,-1(s1)
 81c:	854a                	mv	a0,s2
 81e:	f67ff0ef          	jal	ra,784 <putc>
  while(--i >= 0)
 822:	14fd                	addi	s1,s1,-1
 824:	ff349ae3          	bne	s1,s3,818 <printint+0x76>
}
 828:	60a6                	ld	ra,72(sp)
 82a:	6406                	ld	s0,64(sp)
 82c:	74e2                	ld	s1,56(sp)
 82e:	7942                	ld	s2,48(sp)
 830:	79a2                	ld	s3,40(sp)
 832:	6161                	addi	sp,sp,80
 834:	8082                	ret
    x = -xx;
 836:	40b005b3          	neg	a1,a1
    neg = 1;
 83a:	4885                	li	a7,1
    x = -xx;
 83c:	bfbd                	j	7ba <printint+0x18>

000000000000083e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %c, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 83e:	7119                	addi	sp,sp,-128
 840:	fc86                	sd	ra,120(sp)
 842:	f8a2                	sd	s0,112(sp)
 844:	f4a6                	sd	s1,104(sp)
 846:	f0ca                	sd	s2,96(sp)
 848:	ecce                	sd	s3,88(sp)
 84a:	e8d2                	sd	s4,80(sp)
 84c:	e4d6                	sd	s5,72(sp)
 84e:	e0da                	sd	s6,64(sp)
 850:	fc5e                	sd	s7,56(sp)
 852:	f862                	sd	s8,48(sp)
 854:	f466                	sd	s9,40(sp)
 856:	f06a                	sd	s10,32(sp)
 858:	ec6e                	sd	s11,24(sp)
 85a:	0100                	addi	s0,sp,128
  char *s;
  int c0, c1, c2, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 85c:	0005c903          	lbu	s2,0(a1)
 860:	24090c63          	beqz	s2,ab8 <vprintf+0x27a>
 864:	8b2a                	mv	s6,a0
 866:	8a2e                	mv	s4,a1
 868:	8bb2                	mv	s7,a2
  state = 0;
 86a:	4981                	li	s3,0
  for(i = 0; fmt[i]; i++){
 86c:	4481                	li	s1,0
 86e:	4701                	li	a4,0
      if(c0 == '%'){
        state = '%';
      } else {
        putc(fd, c0);
      }
    } else if(state == '%'){
 870:	02500a93          	li	s5,37
      c1 = c2 = 0;
      if(c0) c1 = fmt[i+1] & 0xff;
      if(c1) c2 = fmt[i+2] & 0xff;
      if(c0 == 'd'){
 874:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c0 == 'l' && c1 == 'd'){
 878:	06c00d13          	li	s10,108
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 2;
      } else if(c0 == 'u'){
 87c:	07500d93          	li	s11,117
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 880:	00000c97          	auipc	s9,0x0
 884:	700c8c93          	addi	s9,s9,1792 # f80 <digits>
 888:	a005                	j	8a8 <vprintf+0x6a>
        putc(fd, c0);
 88a:	85ca                	mv	a1,s2
 88c:	855a                	mv	a0,s6
 88e:	ef7ff0ef          	jal	ra,784 <putc>
 892:	a019                	j	898 <vprintf+0x5a>
    } else if(state == '%'){
 894:	03598263          	beq	s3,s5,8b8 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 898:	2485                	addiw	s1,s1,1
 89a:	8726                	mv	a4,s1
 89c:	009a07b3          	add	a5,s4,s1
 8a0:	0007c903          	lbu	s2,0(a5)
 8a4:	20090a63          	beqz	s2,ab8 <vprintf+0x27a>
    c0 = fmt[i] & 0xff;
 8a8:	0009079b          	sext.w	a5,s2
    if(state == 0){
 8ac:	fe0994e3          	bnez	s3,894 <vprintf+0x56>
      if(c0 == '%'){
 8b0:	fd579de3          	bne	a5,s5,88a <vprintf+0x4c>
        state = '%';
 8b4:	89be                	mv	s3,a5
 8b6:	b7cd                	j	898 <vprintf+0x5a>
      if(c0) c1 = fmt[i+1] & 0xff;
 8b8:	c3c1                	beqz	a5,938 <vprintf+0xfa>
 8ba:	00ea06b3          	add	a3,s4,a4
 8be:	0016c683          	lbu	a3,1(a3)
      c1 = c2 = 0;
 8c2:	8636                	mv	a2,a3
      if(c1) c2 = fmt[i+2] & 0xff;
 8c4:	c681                	beqz	a3,8cc <vprintf+0x8e>
 8c6:	9752                	add	a4,a4,s4
 8c8:	00274603          	lbu	a2,2(a4)
      if(c0 == 'd'){
 8cc:	03878e63          	beq	a5,s8,908 <vprintf+0xca>
      } else if(c0 == 'l' && c1 == 'd'){
 8d0:	05a78863          	beq	a5,s10,920 <vprintf+0xe2>
      } else if(c0 == 'u'){
 8d4:	0db78b63          	beq	a5,s11,9aa <vprintf+0x16c>
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 2;
      } else if(c0 == 'x'){
 8d8:	07800713          	li	a4,120
 8dc:	10e78d63          	beq	a5,a4,9f6 <vprintf+0x1b8>
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 2;
      } else if(c0 == 'p'){
 8e0:	07000713          	li	a4,112
 8e4:	14e78263          	beq	a5,a4,a28 <vprintf+0x1ea>
        printptr(fd, va_arg(ap, uint64));
      } else if(c0 == 'c'){
 8e8:	06300713          	li	a4,99
 8ec:	16e78f63          	beq	a5,a4,a6a <vprintf+0x22c>
        putc(fd, va_arg(ap, uint32));
      } else if(c0 == 's'){
 8f0:	07300713          	li	a4,115
 8f4:	18e78563          	beq	a5,a4,a7e <vprintf+0x240>
        if((s = va_arg(ap, char*)) == 0)
          s = "(null)";
        for(; *s; s++)
          putc(fd, *s);
      } else if(c0 == '%'){
 8f8:	05579063          	bne	a5,s5,938 <vprintf+0xfa>
        putc(fd, '%');
 8fc:	85d6                	mv	a1,s5
 8fe:	855a                	mv	a0,s6
 900:	e85ff0ef          	jal	ra,784 <putc>
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c0);
      }

      state = 0;
 904:	4981                	li	s3,0
 906:	bf49                	j	898 <vprintf+0x5a>
        printint(fd, va_arg(ap, int), 10, 1);
 908:	008b8913          	addi	s2,s7,8
 90c:	4685                	li	a3,1
 90e:	4629                	li	a2,10
 910:	000ba583          	lw	a1,0(s7)
 914:	855a                	mv	a0,s6
 916:	e8dff0ef          	jal	ra,7a2 <printint>
 91a:	8bca                	mv	s7,s2
      state = 0;
 91c:	4981                	li	s3,0
 91e:	bfad                	j	898 <vprintf+0x5a>
      } else if(c0 == 'l' && c1 == 'd'){
 920:	03868663          	beq	a3,s8,94c <vprintf+0x10e>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 924:	05a68163          	beq	a3,s10,966 <vprintf+0x128>
      } else if(c0 == 'l' && c1 == 'u'){
 928:	09b68d63          	beq	a3,s11,9c2 <vprintf+0x184>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 92c:	03a68f63          	beq	a3,s10,96a <vprintf+0x12c>
      } else if(c0 == 'l' && c1 == 'x'){
 930:	07800793          	li	a5,120
 934:	0cf68d63          	beq	a3,a5,a0e <vprintf+0x1d0>
        putc(fd, '%');
 938:	85d6                	mv	a1,s5
 93a:	855a                	mv	a0,s6
 93c:	e49ff0ef          	jal	ra,784 <putc>
        putc(fd, c0);
 940:	85ca                	mv	a1,s2
 942:	855a                	mv	a0,s6
 944:	e41ff0ef          	jal	ra,784 <putc>
      state = 0;
 948:	4981                	li	s3,0
 94a:	b7b9                	j	898 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 94c:	008b8913          	addi	s2,s7,8
 950:	4685                	li	a3,1
 952:	4629                	li	a2,10
 954:	000bb583          	ld	a1,0(s7)
 958:	855a                	mv	a0,s6
 95a:	e49ff0ef          	jal	ra,7a2 <printint>
        i += 1;
 95e:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 1);
 960:	8bca                	mv	s7,s2
      state = 0;
 962:	4981                	li	s3,0
        i += 1;
 964:	bf15                	j	898 <vprintf+0x5a>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 966:	03860563          	beq	a2,s8,990 <vprintf+0x152>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 96a:	07b60963          	beq	a2,s11,9dc <vprintf+0x19e>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
 96e:	07800793          	li	a5,120
 972:	fcf613e3          	bne	a2,a5,938 <vprintf+0xfa>
        printint(fd, va_arg(ap, uint64), 16, 0);
 976:	008b8913          	addi	s2,s7,8
 97a:	4681                	li	a3,0
 97c:	4641                	li	a2,16
 97e:	000bb583          	ld	a1,0(s7)
 982:	855a                	mv	a0,s6
 984:	e1fff0ef          	jal	ra,7a2 <printint>
        i += 2;
 988:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 16, 0);
 98a:	8bca                	mv	s7,s2
      state = 0;
 98c:	4981                	li	s3,0
        i += 2;
 98e:	b729                	j	898 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 990:	008b8913          	addi	s2,s7,8
 994:	4685                	li	a3,1
 996:	4629                	li	a2,10
 998:	000bb583          	ld	a1,0(s7)
 99c:	855a                	mv	a0,s6
 99e:	e05ff0ef          	jal	ra,7a2 <printint>
        i += 2;
 9a2:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 1);
 9a4:	8bca                	mv	s7,s2
      state = 0;
 9a6:	4981                	li	s3,0
        i += 2;
 9a8:	bdc5                	j	898 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint32), 10, 0);
 9aa:	008b8913          	addi	s2,s7,8
 9ae:	4681                	li	a3,0
 9b0:	4629                	li	a2,10
 9b2:	000be583          	lwu	a1,0(s7)
 9b6:	855a                	mv	a0,s6
 9b8:	debff0ef          	jal	ra,7a2 <printint>
 9bc:	8bca                	mv	s7,s2
      state = 0;
 9be:	4981                	li	s3,0
 9c0:	bde1                	j	898 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 9c2:	008b8913          	addi	s2,s7,8
 9c6:	4681                	li	a3,0
 9c8:	4629                	li	a2,10
 9ca:	000bb583          	ld	a1,0(s7)
 9ce:	855a                	mv	a0,s6
 9d0:	dd3ff0ef          	jal	ra,7a2 <printint>
        i += 1;
 9d4:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 0);
 9d6:	8bca                	mv	s7,s2
      state = 0;
 9d8:	4981                	li	s3,0
        i += 1;
 9da:	bd7d                	j	898 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 9dc:	008b8913          	addi	s2,s7,8
 9e0:	4681                	li	a3,0
 9e2:	4629                	li	a2,10
 9e4:	000bb583          	ld	a1,0(s7)
 9e8:	855a                	mv	a0,s6
 9ea:	db9ff0ef          	jal	ra,7a2 <printint>
        i += 2;
 9ee:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 0);
 9f0:	8bca                	mv	s7,s2
      state = 0;
 9f2:	4981                	li	s3,0
        i += 2;
 9f4:	b555                	j	898 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint32), 16, 0);
 9f6:	008b8913          	addi	s2,s7,8
 9fa:	4681                	li	a3,0
 9fc:	4641                	li	a2,16
 9fe:	000be583          	lwu	a1,0(s7)
 a02:	855a                	mv	a0,s6
 a04:	d9fff0ef          	jal	ra,7a2 <printint>
 a08:	8bca                	mv	s7,s2
      state = 0;
 a0a:	4981                	li	s3,0
 a0c:	b571                	j	898 <vprintf+0x5a>
        printint(fd, va_arg(ap, uint64), 16, 0);
 a0e:	008b8913          	addi	s2,s7,8
 a12:	4681                	li	a3,0
 a14:	4641                	li	a2,16
 a16:	000bb583          	ld	a1,0(s7)
 a1a:	855a                	mv	a0,s6
 a1c:	d87ff0ef          	jal	ra,7a2 <printint>
        i += 1;
 a20:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 16, 0);
 a22:	8bca                	mv	s7,s2
      state = 0;
 a24:	4981                	li	s3,0
        i += 1;
 a26:	bd8d                	j	898 <vprintf+0x5a>
        printptr(fd, va_arg(ap, uint64));
 a28:	008b8793          	addi	a5,s7,8
 a2c:	f8f43423          	sd	a5,-120(s0)
 a30:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 a34:	03000593          	li	a1,48
 a38:	855a                	mv	a0,s6
 a3a:	d4bff0ef          	jal	ra,784 <putc>
  putc(fd, 'x');
 a3e:	07800593          	li	a1,120
 a42:	855a                	mv	a0,s6
 a44:	d41ff0ef          	jal	ra,784 <putc>
 a48:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 a4a:	03c9d793          	srli	a5,s3,0x3c
 a4e:	97e6                	add	a5,a5,s9
 a50:	0007c583          	lbu	a1,0(a5)
 a54:	855a                	mv	a0,s6
 a56:	d2fff0ef          	jal	ra,784 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 a5a:	0992                	slli	s3,s3,0x4
 a5c:	397d                	addiw	s2,s2,-1
 a5e:	fe0916e3          	bnez	s2,a4a <vprintf+0x20c>
        printptr(fd, va_arg(ap, uint64));
 a62:	f8843b83          	ld	s7,-120(s0)
      state = 0;
 a66:	4981                	li	s3,0
 a68:	bd05                	j	898 <vprintf+0x5a>
        putc(fd, va_arg(ap, uint32));
 a6a:	008b8913          	addi	s2,s7,8
 a6e:	000bc583          	lbu	a1,0(s7)
 a72:	855a                	mv	a0,s6
 a74:	d11ff0ef          	jal	ra,784 <putc>
 a78:	8bca                	mv	s7,s2
      state = 0;
 a7a:	4981                	li	s3,0
 a7c:	bd31                	j	898 <vprintf+0x5a>
        if((s = va_arg(ap, char*)) == 0)
 a7e:	008b8993          	addi	s3,s7,8
 a82:	000bb903          	ld	s2,0(s7)
 a86:	00090f63          	beqz	s2,aa4 <vprintf+0x266>
        for(; *s; s++)
 a8a:	00094583          	lbu	a1,0(s2)
 a8e:	c195                	beqz	a1,ab2 <vprintf+0x274>
          putc(fd, *s);
 a90:	855a                	mv	a0,s6
 a92:	cf3ff0ef          	jal	ra,784 <putc>
        for(; *s; s++)
 a96:	0905                	addi	s2,s2,1
 a98:	00094583          	lbu	a1,0(s2)
 a9c:	f9f5                	bnez	a1,a90 <vprintf+0x252>
        if((s = va_arg(ap, char*)) == 0)
 a9e:	8bce                	mv	s7,s3
      state = 0;
 aa0:	4981                	li	s3,0
 aa2:	bbdd                	j	898 <vprintf+0x5a>
          s = "(null)";
 aa4:	00000917          	auipc	s2,0x0
 aa8:	4d490913          	addi	s2,s2,1236 # f78 <malloc+0x3be>
        for(; *s; s++)
 aac:	02800593          	li	a1,40
 ab0:	b7c5                	j	a90 <vprintf+0x252>
        if((s = va_arg(ap, char*)) == 0)
 ab2:	8bce                	mv	s7,s3
      state = 0;
 ab4:	4981                	li	s3,0
 ab6:	b3cd                	j	898 <vprintf+0x5a>
    }
  }
}
 ab8:	70e6                	ld	ra,120(sp)
 aba:	7446                	ld	s0,112(sp)
 abc:	74a6                	ld	s1,104(sp)
 abe:	7906                	ld	s2,96(sp)
 ac0:	69e6                	ld	s3,88(sp)
 ac2:	6a46                	ld	s4,80(sp)
 ac4:	6aa6                	ld	s5,72(sp)
 ac6:	6b06                	ld	s6,64(sp)
 ac8:	7be2                	ld	s7,56(sp)
 aca:	7c42                	ld	s8,48(sp)
 acc:	7ca2                	ld	s9,40(sp)
 ace:	7d02                	ld	s10,32(sp)
 ad0:	6de2                	ld	s11,24(sp)
 ad2:	6109                	addi	sp,sp,128
 ad4:	8082                	ret

0000000000000ad6 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 ad6:	715d                	addi	sp,sp,-80
 ad8:	ec06                	sd	ra,24(sp)
 ada:	e822                	sd	s0,16(sp)
 adc:	1000                	addi	s0,sp,32
 ade:	e010                	sd	a2,0(s0)
 ae0:	e414                	sd	a3,8(s0)
 ae2:	e818                	sd	a4,16(s0)
 ae4:	ec1c                	sd	a5,24(s0)
 ae6:	03043023          	sd	a6,32(s0)
 aea:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 aee:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 af2:	8622                	mv	a2,s0
 af4:	d4bff0ef          	jal	ra,83e <vprintf>
}
 af8:	60e2                	ld	ra,24(sp)
 afa:	6442                	ld	s0,16(sp)
 afc:	6161                	addi	sp,sp,80
 afe:	8082                	ret

0000000000000b00 <printf>:

void
printf(const char *fmt, ...)
{
 b00:	711d                	addi	sp,sp,-96
 b02:	ec06                	sd	ra,24(sp)
 b04:	e822                	sd	s0,16(sp)
 b06:	1000                	addi	s0,sp,32
 b08:	e40c                	sd	a1,8(s0)
 b0a:	e810                	sd	a2,16(s0)
 b0c:	ec14                	sd	a3,24(s0)
 b0e:	f018                	sd	a4,32(s0)
 b10:	f41c                	sd	a5,40(s0)
 b12:	03043823          	sd	a6,48(s0)
 b16:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 b1a:	00840613          	addi	a2,s0,8
 b1e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 b22:	85aa                	mv	a1,a0
 b24:	4505                	li	a0,1
 b26:	d19ff0ef          	jal	ra,83e <vprintf>
}
 b2a:	60e2                	ld	ra,24(sp)
 b2c:	6442                	ld	s0,16(sp)
 b2e:	6125                	addi	sp,sp,96
 b30:	8082                	ret

0000000000000b32 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 b32:	1141                	addi	sp,sp,-16
 b34:	e422                	sd	s0,8(sp)
 b36:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 b38:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 b3c:	00000797          	auipc	a5,0x0
 b40:	4c47b783          	ld	a5,1220(a5) # 1000 <freep>
 b44:	a805                	j	b74 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 b46:	4618                	lw	a4,8(a2)
 b48:	9db9                	addw	a1,a1,a4
 b4a:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 b4e:	6398                	ld	a4,0(a5)
 b50:	6318                	ld	a4,0(a4)
 b52:	fee53823          	sd	a4,-16(a0)
 b56:	a091                	j	b9a <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 b58:	ff852703          	lw	a4,-8(a0)
 b5c:	9e39                	addw	a2,a2,a4
 b5e:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 b60:	ff053703          	ld	a4,-16(a0)
 b64:	e398                	sd	a4,0(a5)
 b66:	a099                	j	bac <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b68:	6398                	ld	a4,0(a5)
 b6a:	00e7e463          	bltu	a5,a4,b72 <free+0x40>
 b6e:	00e6ea63          	bltu	a3,a4,b82 <free+0x50>
{
 b72:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 b74:	fed7fae3          	bgeu	a5,a3,b68 <free+0x36>
 b78:	6398                	ld	a4,0(a5)
 b7a:	00e6e463          	bltu	a3,a4,b82 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b7e:	fee7eae3          	bltu	a5,a4,b72 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 b82:	ff852583          	lw	a1,-8(a0)
 b86:	6390                	ld	a2,0(a5)
 b88:	02059713          	slli	a4,a1,0x20
 b8c:	9301                	srli	a4,a4,0x20
 b8e:	0712                	slli	a4,a4,0x4
 b90:	9736                	add	a4,a4,a3
 b92:	fae60ae3          	beq	a2,a4,b46 <free+0x14>
    bp->s.ptr = p->s.ptr;
 b96:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 b9a:	4790                	lw	a2,8(a5)
 b9c:	02061713          	slli	a4,a2,0x20
 ba0:	9301                	srli	a4,a4,0x20
 ba2:	0712                	slli	a4,a4,0x4
 ba4:	973e                	add	a4,a4,a5
 ba6:	fae689e3          	beq	a3,a4,b58 <free+0x26>
  } else
    p->s.ptr = bp;
 baa:	e394                	sd	a3,0(a5)
  freep = p;
 bac:	00000717          	auipc	a4,0x0
 bb0:	44f73a23          	sd	a5,1108(a4) # 1000 <freep>
}
 bb4:	6422                	ld	s0,8(sp)
 bb6:	0141                	addi	sp,sp,16
 bb8:	8082                	ret

0000000000000bba <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 bba:	7139                	addi	sp,sp,-64
 bbc:	fc06                	sd	ra,56(sp)
 bbe:	f822                	sd	s0,48(sp)
 bc0:	f426                	sd	s1,40(sp)
 bc2:	f04a                	sd	s2,32(sp)
 bc4:	ec4e                	sd	s3,24(sp)
 bc6:	e852                	sd	s4,16(sp)
 bc8:	e456                	sd	s5,8(sp)
 bca:	e05a                	sd	s6,0(sp)
 bcc:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 bce:	02051493          	slli	s1,a0,0x20
 bd2:	9081                	srli	s1,s1,0x20
 bd4:	04bd                	addi	s1,s1,15
 bd6:	8091                	srli	s1,s1,0x4
 bd8:	0014899b          	addiw	s3,s1,1
 bdc:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 bde:	00000517          	auipc	a0,0x0
 be2:	42253503          	ld	a0,1058(a0) # 1000 <freep>
 be6:	c515                	beqz	a0,c12 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 be8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 bea:	4798                	lw	a4,8(a5)
 bec:	02977f63          	bgeu	a4,s1,c2a <malloc+0x70>
 bf0:	8a4e                	mv	s4,s3
 bf2:	0009871b          	sext.w	a4,s3
 bf6:	6685                	lui	a3,0x1
 bf8:	00d77363          	bgeu	a4,a3,bfe <malloc+0x44>
 bfc:	6a05                	lui	s4,0x1
 bfe:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 c02:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 c06:	00000917          	auipc	s2,0x0
 c0a:	3fa90913          	addi	s2,s2,1018 # 1000 <freep>
  if(p == SBRK_ERROR)
 c0e:	5afd                	li	s5,-1
 c10:	a0bd                	j	c7e <malloc+0xc4>
    base.s.ptr = freep = prevp = &base;
 c12:	00000797          	auipc	a5,0x0
 c16:	3fe78793          	addi	a5,a5,1022 # 1010 <base>
 c1a:	00000717          	auipc	a4,0x0
 c1e:	3ef73323          	sd	a5,998(a4) # 1000 <freep>
 c22:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 c24:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 c28:	b7e1                	j	bf0 <malloc+0x36>
      if(p->s.size == nunits)
 c2a:	02e48b63          	beq	s1,a4,c60 <malloc+0xa6>
        p->s.size -= nunits;
 c2e:	4137073b          	subw	a4,a4,s3
 c32:	c798                	sw	a4,8(a5)
        p += p->s.size;
 c34:	1702                	slli	a4,a4,0x20
 c36:	9301                	srli	a4,a4,0x20
 c38:	0712                	slli	a4,a4,0x4
 c3a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 c3c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 c40:	00000717          	auipc	a4,0x0
 c44:	3ca73023          	sd	a0,960(a4) # 1000 <freep>
      return (void*)(p + 1);
 c48:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 c4c:	70e2                	ld	ra,56(sp)
 c4e:	7442                	ld	s0,48(sp)
 c50:	74a2                	ld	s1,40(sp)
 c52:	7902                	ld	s2,32(sp)
 c54:	69e2                	ld	s3,24(sp)
 c56:	6a42                	ld	s4,16(sp)
 c58:	6aa2                	ld	s5,8(sp)
 c5a:	6b02                	ld	s6,0(sp)
 c5c:	6121                	addi	sp,sp,64
 c5e:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 c60:	6398                	ld	a4,0(a5)
 c62:	e118                	sd	a4,0(a0)
 c64:	bff1                	j	c40 <malloc+0x86>
  hp->s.size = nu;
 c66:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 c6a:	0541                	addi	a0,a0,16
 c6c:	ec7ff0ef          	jal	ra,b32 <free>
  return freep;
 c70:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 c74:	dd61                	beqz	a0,c4c <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c76:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c78:	4798                	lw	a4,8(a5)
 c7a:	fa9778e3          	bgeu	a4,s1,c2a <malloc+0x70>
    if(p == freep)
 c7e:	00093703          	ld	a4,0(s2)
 c82:	853e                	mv	a0,a5
 c84:	fef719e3          	bne	a4,a5,c76 <malloc+0xbc>
  p = sbrk(nu * sizeof(Header));
 c88:	8552                	mv	a0,s4
 c8a:	a27ff0ef          	jal	ra,6b0 <sbrk>
  if(p == SBRK_ERROR)
 c8e:	fd551ce3          	bne	a0,s5,c66 <malloc+0xac>
        return 0;
 c92:	4501                	li	a0,0
 c94:	bf65                	j	c4c <malloc+0x92>
