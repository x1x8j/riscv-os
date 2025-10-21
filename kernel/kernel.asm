
kernel.elf:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_start>:
    80000000:	00002117          	auipc	sp,0x2
    80000004:	2d010113          	addi	sp,sp,720 # 800022d0 <timer_interrupt_count>
    80000008:	1a0000ef          	jal	ra,800001a8 <start>

000000008000000c <spin>:
    8000000c:	a001                	j	8000000c <spin>
	...

0000000080000010 <kernelvec>:
    80000010:	7111                	addi	sp,sp,-256
    80000012:	100022f3          	csrr	t0,sstatus
    80000016:	e416                	sd	t0,8(sp)
    80000018:	141022f3          	csrr	t0,sepc
    8000001c:	e816                	sd	t0,16(sp)
    8000001e:	e006                	sd	ra,0(sp)
    80000020:	e80e                	sd	gp,16(sp)
    80000022:	ec12                	sd	tp,24(sp)
    80000024:	f016                	sd	t0,32(sp)
    80000026:	f41a                	sd	t1,40(sp)
    80000028:	f81e                	sd	t2,48(sp)
    8000002a:	e4aa                	sd	a0,72(sp)
    8000002c:	e8ae                	sd	a1,80(sp)
    8000002e:	ecb2                	sd	a2,88(sp)
    80000030:	f0b6                	sd	a3,96(sp)
    80000032:	f4ba                	sd	a4,104(sp)
    80000034:	f8be                	sd	a5,112(sp)
    80000036:	fcc2                	sd	a6,120(sp)
    80000038:	e146                	sd	a7,128(sp)
    8000003a:	edf2                	sd	t3,216(sp)
    8000003c:	f1f6                	sd	t4,224(sp)
    8000003e:	f5fa                	sd	t5,232(sp)
    80000040:	f9fe                	sd	t6,240(sp)
    80000042:	244000ef          	jal	ra,80000286 <kerneltrap>
    80000046:	7282                	ld	t0,32(sp)
    80000048:	6082                	ld	ra,0(sp)
    8000004a:	61c2                	ld	gp,16(sp)
    8000004c:	6262                	ld	tp,24(sp)
    8000004e:	7322                	ld	t1,40(sp)
    80000050:	73c2                	ld	t2,48(sp)
    80000052:	6526                	ld	a0,72(sp)
    80000054:	65c6                	ld	a1,80(sp)
    80000056:	6666                	ld	a2,88(sp)
    80000058:	7686                	ld	a3,96(sp)
    8000005a:	7726                	ld	a4,104(sp)
    8000005c:	77c6                	ld	a5,112(sp)
    8000005e:	7866                	ld	a6,120(sp)
    80000060:	688a                	ld	a7,128(sp)
    80000062:	6e6e                	ld	t3,216(sp)
    80000064:	7e8e                	ld	t4,224(sp)
    80000066:	7f2e                	ld	t5,232(sp)
    80000068:	7fce                	ld	t6,240(sp)
    8000006a:	62a2                	ld	t0,8(sp)
    8000006c:	10029073          	csrw	sstatus,t0
    80000070:	62c2                	ld	t0,16(sp)
    80000072:	14129073          	csrw	sepc,t0
    80000076:	6111                	addi	sp,sp,256
    80000078:	10200073          	sret
	...

000000008000007e <test_timer_interrupt>:
    8000007e:	7179                	addi	sp,sp,-48
    80000080:	00001517          	auipc	a0,0x1
    80000084:	fd050513          	addi	a0,a0,-48 # 80001050 <etext+0xa>
    80000088:	f406                	sd	ra,40(sp)
    8000008a:	f022                	sd	s0,32(sp)
    8000008c:	ec26                	sd	s1,24(sp)
    8000008e:	e84a                	sd	s2,16(sp)
    80000090:	328000ef          	jal	ra,800003b8 <printf>
    80000094:	300027f3          	csrr	a5,mstatus
    80000098:	0087e793          	ori	a5,a5,8
    8000009c:	30079073          	csrw	mstatus,a5
    800000a0:	303027f3          	csrr	a5,mideleg
    800000a4:	0207e793          	ori	a5,a5,32
    800000a8:	30379073          	csrw	mideleg,a5
    800000ac:	104027f3          	csrr	a5,sie
    800000b0:	0207e793          	ori	a5,a5,32
    800000b4:	10479073          	csrw	sie,a5
    800000b8:	100027f3          	csrr	a5,sstatus
    800000bc:	0027e793          	ori	a5,a5,2
    800000c0:	10079073          	csrw	sstatus,a5
    800000c4:	c0102973          	rdtime	s2
    800000c8:	000f47b7          	lui	a5,0xf4
    800000cc:	24078793          	addi	a5,a5,576 # f4240 <_start-0x7ff0bdc0>
    800000d0:	97ca                	add	a5,a5,s2
    800000d2:	14d79073          	csrw	0x14d,a5
    800000d6:	00001517          	auipc	a0,0x1
    800000da:	fa250513          	addi	a0,a0,-94 # 80001078 <etext+0x32>
    800000de:	00002797          	auipc	a5,0x2
    800000e2:	1e07a923          	sw	zero,498(a5) # 800022d0 <timer_interrupt_count>
    800000e6:	2d2000ef          	jal	ra,800003b8 <printf>
    800000ea:	00002717          	auipc	a4,0x2
    800000ee:	1e672703          	lw	a4,486(a4) # 800022d0 <timer_interrupt_count>
    800000f2:	4791                	li	a5,4
    800000f4:	00002417          	auipc	s0,0x2
    800000f8:	1dc40413          	addi	s0,s0,476 # 800022d0 <timer_interrupt_count>
    800000fc:	02e7c563          	blt	a5,a4,80000126 <test_timer_interrupt+0xa8>
    80000100:	3e700713          	li	a4,999
    80000104:	4691                	li	a3,4
    80000106:	c602                	sw	zero,12(sp)
    80000108:	47b2                	lw	a5,12(sp)
    8000010a:	2781                	sext.w	a5,a5
    8000010c:	00f74963          	blt	a4,a5,8000011e <test_timer_interrupt+0xa0>
    80000110:	47b2                	lw	a5,12(sp)
    80000112:	2785                	addiw	a5,a5,1
    80000114:	c63e                	sw	a5,12(sp)
    80000116:	47b2                	lw	a5,12(sp)
    80000118:	2781                	sext.w	a5,a5
    8000011a:	fef75be3          	bge	a4,a5,80000110 <test_timer_interrupt+0x92>
    8000011e:	401c                	lw	a5,0(s0)
    80000120:	2781                	sext.w	a5,a5
    80000122:	fef6d2e3          	bge	a3,a5,80000106 <test_timer_interrupt+0x88>
    80000126:	c01024f3          	rdtime	s1
    8000012a:	00001517          	auipc	a0,0x1
    8000012e:	f7650513          	addi	a0,a0,-138 # 800010a0 <etext+0x5a>
    80000132:	286000ef          	jal	ra,800003b8 <printf>
    80000136:	400c                	lw	a1,0(s0)
    80000138:	00001517          	auipc	a0,0x1
    8000013c:	f9050513          	addi	a0,a0,-112 # 800010c8 <etext+0x82>
    80000140:	412484b3          	sub	s1,s1,s2
    80000144:	2581                	sext.w	a1,a1
    80000146:	272000ef          	jal	ra,800003b8 <printf>
    8000014a:	85a6                	mv	a1,s1
    8000014c:	00001517          	auipc	a0,0x1
    80000150:	f9450513          	addi	a0,a0,-108 # 800010e0 <etext+0x9a>
    80000154:	264000ef          	jal	ra,800003b8 <printf>
    80000158:	4595                	li	a1,5
    8000015a:	02b4d5b3          	divu	a1,s1,a1
    8000015e:	00001517          	auipc	a0,0x1
    80000162:	f9a50513          	addi	a0,a0,-102 # 800010f8 <etext+0xb2>
    80000166:	252000ef          	jal	ra,800003b8 <printf>
    8000016a:	7402                	ld	s0,32(sp)
    8000016c:	70a2                	ld	ra,40(sp)
    8000016e:	64e2                	ld	s1,24(sp)
    80000170:	6942                	ld	s2,16(sp)
    80000172:	00001517          	auipc	a0,0x1
    80000176:	fa650513          	addi	a0,a0,-90 # 80001118 <etext+0xd2>
    8000017a:	6145                	addi	sp,sp,48
    8000017c:	ac35                	j	800003b8 <printf>

000000008000017e <main>:
    8000017e:	1141                	addi	sp,sp,-16
    80000180:	e406                	sd	ra,8(sp)
    80000182:	0f6000ef          	jal	ra,80000278 <trapinithart>
    80000186:	ef9ff0ef          	jal	ra,8000007e <test_timer_interrupt>
    8000018a:	00001517          	auipc	a0,0x1
    8000018e:	fae50513          	addi	a0,a0,-82 # 80001138 <etext+0xf2>
    80000192:	226000ef          	jal	ra,800003b8 <printf>
    80000196:	100027f3          	csrr	a5,sstatus
    8000019a:	0027e793          	ori	a5,a5,2
    8000019e:	10079073          	csrw	sstatus,a5
    800001a2:	10500073          	wfi
    800001a6:	bfc5                	j	80000196 <main+0x18>

00000000800001a8 <start>:
    800001a8:	300027f3          	csrr	a5,mstatus
    800001ac:	7779                	lui	a4,0xffffe
    800001ae:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <kernel_pagetable+0xffffffff7fffc51f>
    800001b2:	8ff9                	and	a5,a5,a4
    800001b4:	6705                	lui	a4,0x1
    800001b6:	80070713          	addi	a4,a4,-2048 # 800 <_start-0x7ffff800>
    800001ba:	8fd9                	or	a5,a5,a4
    800001bc:	30079073          	csrw	mstatus,a5
    800001c0:	00000797          	auipc	a5,0x0
    800001c4:	fbe78793          	addi	a5,a5,-66 # 8000017e <main>
    800001c8:	34179073          	csrw	mepc,a5
    800001cc:	4781                	li	a5,0
    800001ce:	18079073          	csrw	satp,a5
    800001d2:	67c1                	lui	a5,0x10
    800001d4:	17fd                	addi	a5,a5,-1
    800001d6:	30279073          	csrw	medeleg,a5
    800001da:	30379073          	csrw	mideleg,a5
    800001de:	104027f3          	csrr	a5,sie
    800001e2:	2207e793          	ori	a5,a5,544
    800001e6:	10479073          	csrw	sie,a5
    800001ea:	57fd                	li	a5,-1
    800001ec:	00a7d713          	srli	a4,a5,0xa
    800001f0:	3b071073          	csrw	pmpaddr0,a4
    800001f4:	473d                	li	a4,15
    800001f6:	3a071073          	csrw	pmpcfg0,a4
    800001fa:	30402773          	csrr	a4,mie
    800001fe:	02076713          	ori	a4,a4,32
    80000202:	30471073          	csrw	mie,a4
    80000206:	30a02773          	csrr	a4,0x30a
    8000020a:	17fe                	slli	a5,a5,0x3f
    8000020c:	8fd9                	or	a5,a5,a4
    8000020e:	30a79073          	csrw	0x30a,a5
    80000212:	306027f3          	csrr	a5,mcounteren
    80000216:	0027e793          	ori	a5,a5,2
    8000021a:	30679073          	csrw	mcounteren,a5
    8000021e:	c01027f3          	rdtime	a5
    80000222:	000f4737          	lui	a4,0xf4
    80000226:	24070713          	addi	a4,a4,576 # f4240 <_start-0x7ff0bdc0>
    8000022a:	97ba                	add	a5,a5,a4
    8000022c:	14d79073          	csrw	0x14d,a5
    80000230:	f14027f3          	csrr	a5,mhartid
    80000234:	2781                	sext.w	a5,a5
    80000236:	823e                	mv	tp,a5
    80000238:	30200073          	mret
    8000023c:	8082                	ret

000000008000023e <timerinit>:
    8000023e:	304027f3          	csrr	a5,mie
    80000242:	0207e793          	ori	a5,a5,32
    80000246:	30479073          	csrw	mie,a5
    8000024a:	30a027f3          	csrr	a5,0x30a
    8000024e:	577d                	li	a4,-1
    80000250:	177e                	slli	a4,a4,0x3f
    80000252:	8fd9                	or	a5,a5,a4
    80000254:	30a79073          	csrw	0x30a,a5
    80000258:	306027f3          	csrr	a5,mcounteren
    8000025c:	0027e793          	ori	a5,a5,2
    80000260:	30679073          	csrw	mcounteren,a5
    80000264:	c01027f3          	rdtime	a5
    80000268:	000f4737          	lui	a4,0xf4
    8000026c:	24070713          	addi	a4,a4,576 # f4240 <_start-0x7ff0bdc0>
    80000270:	97ba                	add	a5,a5,a4
    80000272:	14d79073          	csrw	0x14d,a5
    80000276:	8082                	ret

0000000080000278 <trapinithart>:
    80000278:	00000797          	auipc	a5,0x0
    8000027c:	d9878793          	addi	a5,a5,-616 # 80000010 <kernelvec>
    80000280:	10579073          	csrw	stvec,a5
    80000284:	8082                	ret

0000000080000286 <kerneltrap>:
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	14102673          	csrr	a2,sepc
    8000028e:	10002773          	csrr	a4,sstatus
    80000292:	142025f3          	csrr	a1,scause
    80000296:	10077793          	andi	a5,a4,256
    8000029a:	c3c1                	beqz	a5,8000031a <kerneltrap+0x94>
    8000029c:	100027f3          	csrr	a5,sstatus
    800002a0:	8b89                	andi	a5,a5,2
    800002a2:	e3d1                	bnez	a5,80000326 <kerneltrap+0xa0>
    800002a4:	142026f3          	csrr	a3,scause
    800002a8:	57fd                	li	a5,-1
    800002aa:	17fe                	slli	a5,a5,0x3f
    800002ac:	00978513          	addi	a0,a5,9
    800002b0:	04a68e63          	beq	a3,a0,8000030c <kerneltrap+0x86>
    800002b4:	0795                	addi	a5,a5,5
    800002b6:	02f68263          	beq	a3,a5,800002da <kerneltrap+0x54>
    800002ba:	14102673          	csrr	a2,sepc
    800002be:	143026f3          	csrr	a3,stval
    800002c2:	00001517          	auipc	a0,0x1
    800002c6:	eee50513          	addi	a0,a0,-274 # 800011b0 <etext+0x16a>
    800002ca:	0ee000ef          	jal	ra,800003b8 <printf>
    800002ce:	00001517          	auipc	a0,0x1
    800002d2:	f0a50513          	addi	a0,a0,-246 # 800011d8 <etext+0x192>
    800002d6:	686000ef          	jal	ra,8000095c <panic>
    800002da:	00002597          	auipc	a1,0x2
    800002de:	ffa58593          	addi	a1,a1,-6 # 800022d4 <ticks>
    800002e2:	4194                	lw	a3,0(a1)
    800002e4:	00002797          	auipc	a5,0x2
    800002e8:	fec7a783          	lw	a5,-20(a5) # 800022d0 <timer_interrupt_count>
    800002ec:	2785                	addiw	a5,a5,1
    800002ee:	2685                	addiw	a3,a3,1
    800002f0:	c194                	sw	a3,0(a1)
    800002f2:	00002697          	auipc	a3,0x2
    800002f6:	fcf6af23          	sw	a5,-34(a3) # 800022d0 <timer_interrupt_count>
    800002fa:	c01027f3          	rdtime	a5
    800002fe:	000f46b7          	lui	a3,0xf4
    80000302:	24068693          	addi	a3,a3,576 # f4240 <_start-0x7ff0bdc0>
    80000306:	97b6                	add	a5,a5,a3
    80000308:	14d79073          	csrw	0x14d,a5
    8000030c:	14161073          	csrw	sepc,a2
    80000310:	10071073          	csrw	sstatus,a4
    80000314:	60a2                	ld	ra,8(sp)
    80000316:	0141                	addi	sp,sp,16
    80000318:	8082                	ret
    8000031a:	00001517          	auipc	a0,0x1
    8000031e:	e4e50513          	addi	a0,a0,-434 # 80001168 <etext+0x122>
    80000322:	63a000ef          	jal	ra,8000095c <panic>
    80000326:	00001517          	auipc	a0,0x1
    8000032a:	e6a50513          	addi	a0,a0,-406 # 80001190 <etext+0x14a>
    8000032e:	62e000ef          	jal	ra,8000095c <panic>

0000000080000332 <clockintr>:
    80000332:	00002697          	auipc	a3,0x2
    80000336:	fa268693          	addi	a3,a3,-94 # 800022d4 <ticks>
    8000033a:	4298                	lw	a4,0(a3)
    8000033c:	00002797          	auipc	a5,0x2
    80000340:	f947a783          	lw	a5,-108(a5) # 800022d0 <timer_interrupt_count>
    80000344:	2785                	addiw	a5,a5,1
    80000346:	2705                	addiw	a4,a4,1
    80000348:	c298                	sw	a4,0(a3)
    8000034a:	00002717          	auipc	a4,0x2
    8000034e:	f8f72323          	sw	a5,-122(a4) # 800022d0 <timer_interrupt_count>
    80000352:	c01027f3          	rdtime	a5
    80000356:	000f4737          	lui	a4,0xf4
    8000035a:	24070713          	addi	a4,a4,576 # f4240 <_start-0x7ff0bdc0>
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	14d79073          	csrw	0x14d,a5
    80000364:	8082                	ret

0000000080000366 <devintr>:
    80000366:	14202773          	csrr	a4,scause
    8000036a:	57fd                	li	a5,-1
    8000036c:	17fe                	slli	a5,a5,0x3f
    8000036e:	00978693          	addi	a3,a5,9
    80000372:	4505                	li	a0,1
    80000374:	00d70663          	beq	a4,a3,80000380 <devintr+0x1a>
    80000378:	0795                	addi	a5,a5,5
    8000037a:	4501                	li	a0,0
    8000037c:	00f70363          	beq	a4,a5,80000382 <devintr+0x1c>
    80000380:	8082                	ret
    80000382:	00002697          	auipc	a3,0x2
    80000386:	f5268693          	addi	a3,a3,-174 # 800022d4 <ticks>
    8000038a:	4298                	lw	a4,0(a3)
    8000038c:	00002797          	auipc	a5,0x2
    80000390:	f447a783          	lw	a5,-188(a5) # 800022d0 <timer_interrupt_count>
    80000394:	2785                	addiw	a5,a5,1
    80000396:	2705                	addiw	a4,a4,1
    80000398:	c298                	sw	a4,0(a3)
    8000039a:	00002717          	auipc	a4,0x2
    8000039e:	f2f72b23          	sw	a5,-202(a4) # 800022d0 <timer_interrupt_count>
    800003a2:	c01027f3          	rdtime	a5
    800003a6:	000f4737          	lui	a4,0xf4
    800003aa:	24070713          	addi	a4,a4,576 # f4240 <_start-0x7ff0bdc0>
    800003ae:	97ba                	add	a5,a5,a4
    800003b0:	14d79073          	csrw	0x14d,a5
    800003b4:	4509                	li	a0,2
    800003b6:	8082                	ret

00000000800003b8 <printf>:
    800003b8:	7115                	addi	sp,sp,-224
    800003ba:	e14a                	sd	s2,128(sp)
    800003bc:	ed06                	sd	ra,152(sp)
    800003be:	e922                	sd	s0,144(sp)
    800003c0:	e526                	sd	s1,136(sp)
    800003c2:	fcce                	sd	s3,120(sp)
    800003c4:	f8d2                	sd	s4,112(sp)
    800003c6:	f4d6                	sd	s5,104(sp)
    800003c8:	f0da                	sd	s6,96(sp)
    800003ca:	ecde                	sd	s7,88(sp)
    800003cc:	e8e2                	sd	s8,80(sp)
    800003ce:	e4e6                	sd	s9,72(sp)
    800003d0:	e0ea                	sd	s10,64(sp)
    800003d2:	fc6e                	sd	s11,56(sp)
    800003d4:	892a                	mv	s2,a0
    800003d6:	00054503          	lbu	a0,0(a0)
    800003da:	e5be                	sd	a5,200(sp)
    800003dc:	113c                	addi	a5,sp,168
    800003de:	f52e                	sd	a1,168(sp)
    800003e0:	f932                	sd	a2,176(sp)
    800003e2:	fd36                	sd	a3,184(sp)
    800003e4:	e1ba                	sd	a4,192(sp)
    800003e6:	e9c2                	sd	a6,208(sp)
    800003e8:	edc6                	sd	a7,216(sp)
    800003ea:	e43e                	sd	a5,8(sp)
    800003ec:	c535                	beqz	a0,80000458 <printf+0xa0>
    800003ee:	4401                	li	s0,0
    800003f0:	02500993          	li	s3,37
    800003f4:	07800b93          	li	s7,120
    800003f8:	06200c93          	li	s9,98
    800003fc:	4c55                	li	s8,21
    800003fe:	00001b17          	auipc	s6,0x1
    80000402:	e0ab0b13          	addi	s6,s6,-502 # 80001208 <etext+0x1c2>
    80000406:	00001497          	auipc	s1,0x1
    8000040a:	e5a48493          	addi	s1,s1,-422 # 80001260 <digits>
    8000040e:	00140a9b          	addiw	s5,s0,1
    80000412:	01590a33          	add	s4,s2,s5
    80000416:	8752                	mv	a4,s4
    80000418:	25351a63          	bne	a0,s3,8000066c <printf+0x2b4>
    8000041c:	000a4a03          	lbu	s4,0(s4)
    80000420:	014bef63          	bltu	s7,s4,8000043e <printf+0x86>
    80000424:	214cf163          	bgeu	s9,s4,80000626 <printf+0x26e>
    80000428:	f9da079b          	addiw	a5,s4,-99
    8000042c:	0ff7f793          	andi	a5,a5,255
    80000430:	00fc6763          	bltu	s8,a5,8000043e <printf+0x86>
    80000434:	078a                	slli	a5,a5,0x2
    80000436:	97da                	add	a5,a5,s6
    80000438:	439c                	lw	a5,0(a5)
    8000043a:	97da                	add	a5,a5,s6
    8000043c:	8782                	jr	a5
    8000043e:	02500513          	li	a0,37
    80000442:	52e000ef          	jal	ra,80000970 <console_putc>
    80000446:	8552                	mv	a0,s4
    80000448:	2409                	addiw	s0,s0,2
    8000044a:	526000ef          	jal	ra,80000970 <console_putc>
    8000044e:	00890a33          	add	s4,s2,s0
    80000452:	000a4503          	lbu	a0,0(s4)
    80000456:	fd45                	bnez	a0,8000040e <printf+0x56>
    80000458:	60ea                	ld	ra,152(sp)
    8000045a:	644a                	ld	s0,144(sp)
    8000045c:	64aa                	ld	s1,136(sp)
    8000045e:	690a                	ld	s2,128(sp)
    80000460:	79e6                	ld	s3,120(sp)
    80000462:	7a46                	ld	s4,112(sp)
    80000464:	7aa6                	ld	s5,104(sp)
    80000466:	7b06                	ld	s6,96(sp)
    80000468:	6be6                	ld	s7,88(sp)
    8000046a:	6c46                	ld	s8,80(sp)
    8000046c:	6ca6                	ld	s9,72(sp)
    8000046e:	6d06                	ld	s10,64(sp)
    80000470:	7de2                	ld	s11,56(sp)
    80000472:	4501                	li	a0,0
    80000474:	612d                	addi	sp,sp,224
    80000476:	8082                	ret
    80000478:	6722                	ld	a4,8(sp)
    8000047a:	0810                	addi	a2,sp,16
    8000047c:	4681                	li	a3,0
    8000047e:	431c                	lw	a5,0(a4)
    80000480:	0721                	addi	a4,a4,8
    80000482:	e43a                	sd	a4,8(sp)
    80000484:	45bd                	li	a1,15
    80000486:	00f7f713          	andi	a4,a5,15
    8000048a:	9726                	add	a4,a4,s1
    8000048c:	00074503          	lbu	a0,0(a4)
    80000490:	0007871b          	sext.w	a4,a5
    80000494:	8a36                	mv	s4,a3
    80000496:	00a60023          	sb	a0,0(a2)
    8000049a:	2685                	addiw	a3,a3,1
    8000049c:	0047d79b          	srliw	a5,a5,0x4
    800004a0:	0605                	addi	a2,a2,1
    800004a2:	fee5e2e3          	bltu	a1,a4,80000486 <printf+0xce>
    800004a6:	081c                	addi	a5,sp,16
    800004a8:	9a3e                	add	s4,s4,a5
    800004aa:	8abe                	mv	s5,a5
    800004ac:	a021                	j	800004b4 <printf+0xfc>
    800004ae:	fffa4503          	lbu	a0,-1(s4)
    800004b2:	1a7d                	addi	s4,s4,-1
    800004b4:	4bc000ef          	jal	ra,80000970 <console_putc>
    800004b8:	ff5a1be3          	bne	s4,s5,800004ae <printf+0xf6>
    800004bc:	2409                	addiw	s0,s0,2
    800004be:	00890a33          	add	s4,s2,s0
    800004c2:	bf41                	j	80000452 <printf+0x9a>
    800004c4:	67a2                	ld	a5,8(sp)
    800004c6:	0810                	addi	a2,sp,16
    800004c8:	4681                	li	a3,0
    800004ca:	4398                	lw	a4,0(a5)
    800004cc:	07a1                	addi	a5,a5,8
    800004ce:	e43e                	sd	a5,8(sp)
    800004d0:	45a9                	li	a1,10
    800004d2:	48a5                	li	a7,9
    800004d4:	02b777bb          	remuw	a5,a4,a1
    800004d8:	0605                	addi	a2,a2,1
    800004da:	0007081b          	sext.w	a6,a4
    800004de:	8a36                	mv	s4,a3
    800004e0:	2685                	addiw	a3,a3,1
    800004e2:	1782                	slli	a5,a5,0x20
    800004e4:	9381                	srli	a5,a5,0x20
    800004e6:	97a6                	add	a5,a5,s1
    800004e8:	0007c503          	lbu	a0,0(a5)
    800004ec:	02b7573b          	divuw	a4,a4,a1
    800004f0:	fea60fa3          	sb	a0,-1(a2)
    800004f4:	ff08e0e3          	bltu	a7,a6,800004d4 <printf+0x11c>
    800004f8:	081c                	addi	a5,sp,16
    800004fa:	9a3e                	add	s4,s4,a5
    800004fc:	8abe                	mv	s5,a5
    800004fe:	a021                	j	80000506 <printf+0x14e>
    80000500:	fffa4503          	lbu	a0,-1(s4)
    80000504:	1a7d                	addi	s4,s4,-1
    80000506:	46a000ef          	jal	ra,80000970 <console_putc>
    8000050a:	ff5a1be3          	bne	s4,s5,80000500 <printf+0x148>
    8000050e:	2409                	addiw	s0,s0,2
    80000510:	00890a33          	add	s4,s2,s0
    80000514:	bf3d                	j	80000452 <printf+0x9a>
    80000516:	67a2                	ld	a5,8(sp)
    80000518:	2409                	addiw	s0,s0,2
    8000051a:	00890a33          	add	s4,s2,s0
    8000051e:	0007ba83          	ld	s5,0(a5)
    80000522:	07a1                	addi	a5,a5,8
    80000524:	e43e                	sd	a5,8(sp)
    80000526:	000a9b63          	bnez	s5,8000053c <printf+0x184>
    8000052a:	00001a97          	auipc	s5,0x1
    8000052e:	cbea8a93          	addi	s5,s5,-834 # 800011e8 <etext+0x1a2>
    80000532:	02800513          	li	a0,40
    80000536:	0a85                	addi	s5,s5,1
    80000538:	438000ef          	jal	ra,80000970 <console_putc>
    8000053c:	000ac503          	lbu	a0,0(s5)
    80000540:	f97d                	bnez	a0,80000536 <printf+0x17e>
    80000542:	bf01                	j	80000452 <printf+0x9a>
    80000544:	67a2                	ld	a5,8(sp)
    80000546:	00001517          	auipc	a0,0x1
    8000054a:	caa50513          	addi	a0,a0,-854 # 800011f0 <etext+0x1aa>
    8000054e:	03c00d93          	li	s11,60
    80000552:	00878713          	addi	a4,a5,8
    80000556:	0007ba83          	ld	s5,0(a5)
    8000055a:	e43a                	sd	a4,8(sp)
    8000055c:	5a71                	li	s4,-4
    8000055e:	414000ef          	jal	ra,80000972 <console_puts>
    80000562:	01bad7b3          	srl	a5,s5,s11
    80000566:	8bbd                	andi	a5,a5,15
    80000568:	97a6                	add	a5,a5,s1
    8000056a:	0007c503          	lbu	a0,0(a5)
    8000056e:	3df1                	addiw	s11,s11,-4
    80000570:	400000ef          	jal	ra,80000970 <console_putc>
    80000574:	ff4d97e3          	bne	s11,s4,80000562 <printf+0x1aa>
    80000578:	2409                	addiw	s0,s0,2
    8000057a:	00890a33          	add	s4,s2,s0
    8000057e:	bdd1                	j	80000452 <printf+0x9a>
    80000580:	00174783          	lbu	a5,1(a4)
    80000584:	06400713          	li	a4,100
    80000588:	16e78c63          	beq	a5,a4,80000700 <printf+0x348>
    8000058c:	23778763          	beq	a5,s7,800007ba <printf+0x402>
    80000590:	07500713          	li	a4,117
    80000594:	1ce78d63          	beq	a5,a4,8000076e <printf+0x3b6>
    80000598:	02500513          	li	a0,37
    8000059c:	3d4000ef          	jal	ra,80000970 <console_putc>
    800005a0:	06c00513          	li	a0,108
    800005a4:	2409                	addiw	s0,s0,2
    800005a6:	3ca000ef          	jal	ra,80000970 <console_putc>
    800005aa:	00890a33          	add	s4,s2,s0
    800005ae:	b555                	j	80000452 <printf+0x9a>
    800005b0:	67a2                	ld	a5,8(sp)
    800005b2:	0007a303          	lw	t1,0(a5)
    800005b6:	07a1                	addi	a5,a5,8
    800005b8:	e43e                	sd	a5,8(sp)
    800005ba:	0003071b          	sext.w	a4,t1
    800005be:	0c034d63          	bltz	t1,80000698 <printf+0x2e0>
    800005c2:	0814                	addi	a3,sp,16
    800005c4:	4601                	li	a2,0
    800005c6:	45a9                	li	a1,10
    800005c8:	48a5                	li	a7,9
    800005ca:	02b777bb          	remuw	a5,a4,a1
    800005ce:	0685                	addi	a3,a3,1
    800005d0:	0007081b          	sext.w	a6,a4
    800005d4:	8a32                	mv	s4,a2
    800005d6:	2605                	addiw	a2,a2,1
    800005d8:	1782                	slli	a5,a5,0x20
    800005da:	9381                	srli	a5,a5,0x20
    800005dc:	97a6                	add	a5,a5,s1
    800005de:	0007c503          	lbu	a0,0(a5)
    800005e2:	02b7573b          	divuw	a4,a4,a1
    800005e6:	fea68fa3          	sb	a0,-1(a3)
    800005ea:	ff08e0e3          	bltu	a7,a6,800005ca <printf+0x212>
    800005ee:	08034b63          	bltz	t1,80000684 <printf+0x2cc>
    800005f2:	081c                	addi	a5,sp,16
    800005f4:	9a3e                	add	s4,s4,a5
    800005f6:	8abe                	mv	s5,a5
    800005f8:	a021                	j	80000600 <printf+0x248>
    800005fa:	fffa4503          	lbu	a0,-1(s4)
    800005fe:	1a7d                	addi	s4,s4,-1
    80000600:	370000ef          	jal	ra,80000970 <console_putc>
    80000604:	ff4a9be3          	bne	s5,s4,800005fa <printf+0x242>
    80000608:	2409                	addiw	s0,s0,2
    8000060a:	00890a33          	add	s4,s2,s0
    8000060e:	b591                	j	80000452 <printf+0x9a>
    80000610:	67a2                	ld	a5,8(sp)
    80000612:	2409                	addiw	s0,s0,2
    80000614:	00890a33          	add	s4,s2,s0
    80000618:	0007c503          	lbu	a0,0(a5)
    8000061c:	07a1                	addi	a5,a5,8
    8000061e:	e43e                	sd	a5,8(sp)
    80000620:	350000ef          	jal	ra,80000970 <console_putc>
    80000624:	b53d                	j	80000452 <printf+0x9a>
    80000626:	053a0763          	beq	s4,s3,80000674 <printf+0x2bc>
    8000062a:	02a00793          	li	a5,42
    8000062e:	e0fa18e3          	bne	s4,a5,8000043e <printf+0x86>
    80000632:	67a2                	ld	a5,8(sp)
    80000634:	00240a9b          	addiw	s5,s0,2
    80000638:	9aca                	add	s5,s5,s2
    8000063a:	000ac683          	lbu	a3,0(s5)
    8000063e:	00878713          	addi	a4,a5,8
    80000642:	240d                	addiw	s0,s0,3
    80000644:	e43a                	sd	a4,8(sp)
    80000646:	07300713          	li	a4,115
    8000064a:	00890a33          	add	s4,s2,s0
    8000064e:	04e68863          	beq	a3,a4,8000069e <printf+0x2e6>
    80000652:	02500513          	li	a0,37
    80000656:	31a000ef          	jal	ra,80000970 <console_putc>
    8000065a:	02a00513          	li	a0,42
    8000065e:	312000ef          	jal	ra,80000970 <console_putc>
    80000662:	000ac503          	lbu	a0,0(s5)
    80000666:	30a000ef          	jal	ra,80000970 <console_putc>
    8000066a:	b3e5                	j	80000452 <printf+0x9a>
    8000066c:	304000ef          	jal	ra,80000970 <console_putc>
    80000670:	8456                	mv	s0,s5
    80000672:	b3c5                	j	80000452 <printf+0x9a>
    80000674:	02500513          	li	a0,37
    80000678:	2409                	addiw	s0,s0,2
    8000067a:	2f6000ef          	jal	ra,80000970 <console_putc>
    8000067e:	00890a33          	add	s4,s2,s0
    80000682:	bbc1                	j	80000452 <printf+0x9a>
    80000684:	181c                	addi	a5,sp,48
    80000686:	97b2                	add	a5,a5,a2
    80000688:	02d00713          	li	a4,45
    8000068c:	fee78023          	sb	a4,-32(a5)
    80000690:	8a32                	mv	s4,a2
    80000692:	02d00513          	li	a0,45
    80000696:	bfb1                	j	800005f2 <printf+0x23a>
    80000698:	4060073b          	negw	a4,t1
    8000069c:	b71d                	j	800005c2 <printf+0x20a>
    8000069e:	0087ba83          	ld	s5,8(a5)
    800006a2:	01078713          	addi	a4,a5,16
    800006a6:	e43a                	sd	a4,8(sp)
    800006a8:	0007ad83          	lw	s11,0(a5)
    800006ac:	140a8b63          	beqz	s5,80000802 <printf+0x44a>
    800006b0:	000ac783          	lbu	a5,0(s5)
    800006b4:	14078e63          	beqz	a5,80000810 <printf+0x458>
    800006b8:	001ac703          	lbu	a4,1(s5)
    800006bc:	4685                	li	a3,1
    800006be:	87d6                	mv	a5,s5
    800006c0:	415686bb          	subw	a3,a3,s5
    800006c4:	a019                	j	800006ca <printf+0x312>
    800006c6:	0017c703          	lbu	a4,1(a5)
    800006ca:	00f6863b          	addw	a2,a3,a5
    800006ce:	0785                	addi	a5,a5,1
    800006d0:	fb7d                	bnez	a4,800006c6 <printf+0x30e>
    800006d2:	40cd8dbb          	subw	s11,s11,a2
    800006d6:	13b05363          	blez	s11,800007fc <printf+0x444>
    800006da:	4d01                	li	s10,0
    800006dc:	2d05                	addiw	s10,s10,1
    800006de:	02000513          	li	a0,32
    800006e2:	28e000ef          	jal	ra,80000970 <console_putc>
    800006e6:	ffbd4be3          	blt	s10,s11,800006dc <printf+0x324>
    800006ea:	000ac503          	lbu	a0,0(s5)
    800006ee:	d60502e3          	beqz	a0,80000452 <printf+0x9a>
    800006f2:	0a85                	addi	s5,s5,1
    800006f4:	27c000ef          	jal	ra,80000970 <console_putc>
    800006f8:	000ac503          	lbu	a0,0(s5)
    800006fc:	f97d                	bnez	a0,800006f2 <printf+0x33a>
    800006fe:	bb91                	j	80000452 <printf+0x9a>
    80000700:	67a2                	ld	a5,8(sp)
    80000702:	0814                	addi	a3,sp,16
    80000704:	4601                	li	a2,0
    80000706:	0007b303          	ld	t1,0(a5)
    8000070a:	07a1                	addi	a5,a5,8
    8000070c:	e43e                	sd	a5,8(sp)
    8000070e:	43f35713          	srai	a4,t1,0x3f
    80000712:	006747b3          	xor	a5,a4,t1
    80000716:	8f99                	sub	a5,a5,a4
    80000718:	45a9                	li	a1,10
    8000071a:	48a5                	li	a7,9
    8000071c:	02b7f733          	remu	a4,a5,a1
    80000720:	0685                	addi	a3,a3,1
    80000722:	883e                	mv	a6,a5
    80000724:	8a32                	mv	s4,a2
    80000726:	2605                	addiw	a2,a2,1
    80000728:	9726                	add	a4,a4,s1
    8000072a:	00074503          	lbu	a0,0(a4)
    8000072e:	02b7d7b3          	divu	a5,a5,a1
    80000732:	fea68fa3          	sb	a0,-1(a3)
    80000736:	ff08e3e3          	bltu	a7,a6,8000071c <printf+0x364>
    8000073a:	00035b63          	bgez	t1,80000750 <printf+0x398>
    8000073e:	181c                	addi	a5,sp,48
    80000740:	97b2                	add	a5,a5,a2
    80000742:	02d00713          	li	a4,45
    80000746:	fee78023          	sb	a4,-32(a5)
    8000074a:	8a32                	mv	s4,a2
    8000074c:	02d00513          	li	a0,45
    80000750:	081c                	addi	a5,sp,16
    80000752:	9a3e                	add	s4,s4,a5
    80000754:	8abe                	mv	s5,a5
    80000756:	a021                	j	8000075e <printf+0x3a6>
    80000758:	fffa4503          	lbu	a0,-1(s4)
    8000075c:	1a7d                	addi	s4,s4,-1
    8000075e:	212000ef          	jal	ra,80000970 <console_putc>
    80000762:	ff5a1be3          	bne	s4,s5,80000758 <printf+0x3a0>
    80000766:	240d                	addiw	s0,s0,3
    80000768:	00890a33          	add	s4,s2,s0
    8000076c:	b1dd                	j	80000452 <printf+0x9a>
    8000076e:	6722                	ld	a4,8(sp)
    80000770:	0810                	addi	a2,sp,16
    80000772:	4681                	li	a3,0
    80000774:	631c                	ld	a5,0(a4)
    80000776:	0721                	addi	a4,a4,8
    80000778:	e43a                	sd	a4,8(sp)
    8000077a:	45a9                	li	a1,10
    8000077c:	48a5                	li	a7,9
    8000077e:	02b7f733          	remu	a4,a5,a1
    80000782:	0605                	addi	a2,a2,1
    80000784:	883e                	mv	a6,a5
    80000786:	8a36                	mv	s4,a3
    80000788:	2685                	addiw	a3,a3,1
    8000078a:	9726                	add	a4,a4,s1
    8000078c:	00074503          	lbu	a0,0(a4)
    80000790:	02b7d7b3          	divu	a5,a5,a1
    80000794:	fea60fa3          	sb	a0,-1(a2)
    80000798:	ff08e3e3          	bltu	a7,a6,8000077e <printf+0x3c6>
    8000079c:	081c                	addi	a5,sp,16
    8000079e:	9a3e                	add	s4,s4,a5
    800007a0:	8abe                	mv	s5,a5
    800007a2:	a021                	j	800007aa <printf+0x3f2>
    800007a4:	fffa4503          	lbu	a0,-1(s4)
    800007a8:	1a7d                	addi	s4,s4,-1
    800007aa:	1c6000ef          	jal	ra,80000970 <console_putc>
    800007ae:	ff4a9be3          	bne	s5,s4,800007a4 <printf+0x3ec>
    800007b2:	240d                	addiw	s0,s0,3
    800007b4:	00890a33          	add	s4,s2,s0
    800007b8:	b969                	j	80000452 <printf+0x9a>
    800007ba:	6722                	ld	a4,8(sp)
    800007bc:	0810                	addi	a2,sp,16
    800007be:	4681                	li	a3,0
    800007c0:	631c                	ld	a5,0(a4)
    800007c2:	0721                	addi	a4,a4,8
    800007c4:	e43a                	sd	a4,8(sp)
    800007c6:	45bd                	li	a1,15
    800007c8:	00f7f713          	andi	a4,a5,15
    800007cc:	9726                	add	a4,a4,s1
    800007ce:	00074503          	lbu	a0,0(a4)
    800007d2:	873e                	mv	a4,a5
    800007d4:	8a36                	mv	s4,a3
    800007d6:	00a60023          	sb	a0,0(a2)
    800007da:	2685                	addiw	a3,a3,1
    800007dc:	8391                	srli	a5,a5,0x4
    800007de:	0605                	addi	a2,a2,1
    800007e0:	fee5e4e3          	bltu	a1,a4,800007c8 <printf+0x410>
    800007e4:	081c                	addi	a5,sp,16
    800007e6:	9a3e                	add	s4,s4,a5
    800007e8:	8abe                	mv	s5,a5
    800007ea:	a021                	j	800007f2 <printf+0x43a>
    800007ec:	fffa4503          	lbu	a0,-1(s4)
    800007f0:	1a7d                	addi	s4,s4,-1
    800007f2:	17e000ef          	jal	ra,80000970 <console_putc>
    800007f6:	ff5a1be3          	bne	s4,s5,800007ec <printf+0x434>
    800007fa:	b7b5                	j	80000766 <printf+0x3ae>
    800007fc:	000ac503          	lbu	a0,0(s5)
    80000800:	bdcd                	j	800006f2 <printf+0x33a>
    80000802:	06e00713          	li	a4,110
    80000806:	00001a97          	auipc	s5,0x1
    8000080a:	9e2a8a93          	addi	s5,s5,-1566 # 800011e8 <etext+0x1a2>
    8000080e:	b57d                	j	800006bc <printf+0x304>
    80000810:	edb045e3          	bgtz	s11,800006da <printf+0x322>
    80000814:	b93d                	j	80000452 <printf+0x9a>

0000000080000816 <sprintf>:
    80000816:	7159                	addi	sp,sp,-112
    80000818:	0005c303          	lbu	t1,0(a1)
    8000081c:	ecbe                	sd	a5,88(sp)
    8000081e:	009c                	addi	a5,sp,64
    80000820:	e03e                	sd	a5,0(sp)
    80000822:	fc22                	sd	s0,56(sp)
    80000824:	f826                	sd	s1,48(sp)
    80000826:	f44a                	sd	s2,40(sp)
    80000828:	f04e                	sd	s3,32(sp)
    8000082a:	e0b2                	sd	a2,64(sp)
    8000082c:	e4b6                	sd	a3,72(sp)
    8000082e:	e8ba                	sd	a4,80(sp)
    80000830:	f0c2                	sd	a6,96(sp)
    80000832:	f4c6                	sd	a7,104(sp)
    80000834:	87aa                	mv	a5,a0
    80000836:	10030a63          	beqz	t1,8000094a <sprintf+0x134>
    8000083a:	4e81                	li	t4,0
    8000083c:	02500393          	li	t2,37
    80000840:	06400493          	li	s1,100
    80000844:	00001297          	auipc	t0,0x1
    80000848:	a1c28293          	addi	t0,t0,-1508 # 80001260 <digits>
    8000084c:	4e29                	li	t3,10
    8000084e:	4fa5                	li	t6,9
    80000850:	02d00913          	li	s2,45
    80000854:	07300413          	li	s0,115
    80000858:	a809                	j	8000086a <sprintf+0x54>
    8000085a:	00678023          	sb	t1,0(a5)
    8000085e:	8eba                	mv	t4,a4
    80000860:	0785                	addi	a5,a5,1
    80000862:	000f4303          	lbu	t1,0(t5)
    80000866:	02030a63          	beqz	t1,8000089a <sprintf+0x84>
    8000086a:	001e871b          	addiw	a4,t4,1
    8000086e:	00e58f33          	add	t5,a1,a4
    80000872:	fe7314e3          	bne	t1,t2,8000085a <sprintf+0x44>
    80000876:	000f4703          	lbu	a4,0(t5)
    8000087a:	2e89                	addiw	t4,t4,2
    8000087c:	01d58f33          	add	t5,a1,t4
    80000880:	02970763          	beq	a4,s1,800008ae <sprintf+0x98>
    80000884:	08870c63          	beq	a4,s0,8000091c <sprintf+0x106>
    80000888:	00778023          	sb	t2,0(a5)
    8000088c:	00e780a3          	sb	a4,1(a5)
    80000890:	000f4303          	lbu	t1,0(t5)
    80000894:	0789                	addi	a5,a5,2
    80000896:	fc031ae3          	bnez	t1,8000086a <sprintf+0x54>
    8000089a:	00078023          	sb	zero,0(a5)
    8000089e:	7462                	ld	s0,56(sp)
    800008a0:	74c2                	ld	s1,48(sp)
    800008a2:	7922                	ld	s2,40(sp)
    800008a4:	7982                	ld	s3,32(sp)
    800008a6:	40a7853b          	subw	a0,a5,a0
    800008aa:	6165                	addi	sp,sp,112
    800008ac:	8082                	ret
    800008ae:	6702                	ld	a4,0(sp)
    800008b0:	00810813          	addi	a6,sp,8
    800008b4:	4881                	li	a7,0
    800008b6:	00072983          	lw	s3,0(a4)
    800008ba:	0721                	addi	a4,a4,8
    800008bc:	e03a                	sd	a4,0(sp)
    800008be:	41f9d71b          	sraiw	a4,s3,0x1f
    800008c2:	00e9c6b3          	xor	a3,s3,a4
    800008c6:	9e99                	subw	a3,a3,a4
    800008c8:	1682                	slli	a3,a3,0x20
    800008ca:	9281                	srli	a3,a3,0x20
    800008cc:	03c6f633          	remu	a2,a3,t3
    800008d0:	0805                	addi	a6,a6,1
    800008d2:	8336                	mv	t1,a3
    800008d4:	8746                	mv	a4,a7
    800008d6:	2885                	addiw	a7,a7,1
    800008d8:	9616                	add	a2,a2,t0
    800008da:	00064603          	lbu	a2,0(a2)
    800008de:	03c6d6b3          	divu	a3,a3,t3
    800008e2:	fec80fa3          	sb	a2,-1(a6)
    800008e6:	fe6fe3e3          	bltu	t6,t1,800008cc <sprintf+0xb6>
    800008ea:	0009d963          	bgez	s3,800008fc <sprintf+0xe6>
    800008ee:	1018                	addi	a4,sp,32
    800008f0:	9746                	add	a4,a4,a7
    800008f2:	ff270423          	sb	s2,-24(a4)
    800008f6:	02d00613          	li	a2,45
    800008fa:	8746                	mv	a4,a7
    800008fc:	0017069b          	addiw	a3,a4,1
    80000900:	00810813          	addi	a6,sp,8
    80000904:	9742                	add	a4,a4,a6
    80000906:	96be                	add	a3,a3,a5
    80000908:	a019                	j	8000090e <sprintf+0xf8>
    8000090a:	00074603          	lbu	a2,0(a4)
    8000090e:	0785                	addi	a5,a5,1
    80000910:	fec78fa3          	sb	a2,-1(a5)
    80000914:	177d                	addi	a4,a4,-1
    80000916:	fef69ae3          	bne	a3,a5,8000090a <sprintf+0xf4>
    8000091a:	b7a1                	j	80000862 <sprintf+0x4c>
    8000091c:	6682                	ld	a3,0(sp)
    8000091e:	6298                	ld	a4,0(a3)
    80000920:	06a1                	addi	a3,a3,8
    80000922:	e036                	sd	a3,0(sp)
    80000924:	cf01                	beqz	a4,8000093c <sprintf+0x126>
    80000926:	00074683          	lbu	a3,0(a4)
    8000092a:	de85                	beqz	a3,80000862 <sprintf+0x4c>
    8000092c:	00d78023          	sb	a3,0(a5)
    80000930:	00174683          	lbu	a3,1(a4)
    80000934:	0705                	addi	a4,a4,1
    80000936:	0785                	addi	a5,a5,1
    80000938:	faf5                	bnez	a3,8000092c <sprintf+0x116>
    8000093a:	b725                	j	80000862 <sprintf+0x4c>
    8000093c:	00001717          	auipc	a4,0x1
    80000940:	8ac70713          	addi	a4,a4,-1876 # 800011e8 <etext+0x1a2>
    80000944:	02800693          	li	a3,40
    80000948:	b7d5                	j	8000092c <sprintf+0x116>
    8000094a:	00078023          	sb	zero,0(a5)
    8000094e:	7462                	ld	s0,56(sp)
    80000950:	74c2                	ld	s1,48(sp)
    80000952:	7922                	ld	s2,40(sp)
    80000954:	7982                	ld	s3,32(sp)
    80000956:	4501                	li	a0,0
    80000958:	6165                	addi	sp,sp,112
    8000095a:	8082                	ret

000000008000095c <panic>:
    8000095c:	1141                	addi	sp,sp,-16
    8000095e:	85aa                	mv	a1,a0
    80000960:	00001517          	auipc	a0,0x1
    80000964:	89850513          	addi	a0,a0,-1896 # 800011f8 <etext+0x1b2>
    80000968:	e406                	sd	ra,8(sp)
    8000096a:	a4fff0ef          	jal	ra,800003b8 <printf>
    8000096e:	a001                	j	8000096e <panic+0x12>

0000000080000970 <console_putc>:
    80000970:	aa25                	j	80000aa8 <uart_putc>

0000000080000972 <console_puts>:
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e022                	sd	s0,0(sp)
    80000976:	e406                	sd	ra,8(sp)
    80000978:	842a                	mv	s0,a0
    8000097a:	00054503          	lbu	a0,0(a0)
    8000097e:	c519                	beqz	a0,8000098c <console_puts+0x1a>
    80000980:	0405                	addi	s0,s0,1
    80000982:	126000ef          	jal	ra,80000aa8 <uart_putc>
    80000986:	00044503          	lbu	a0,0(s0)
    8000098a:	f97d                	bnez	a0,80000980 <console_puts+0xe>
    8000098c:	60a2                	ld	ra,8(sp)
    8000098e:	6402                	ld	s0,0(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret

0000000080000994 <console_init>:
    80000994:	8082                	ret

0000000080000996 <clear_screen>:
    80000996:	00001517          	auipc	a0,0x1
    8000099a:	8e250513          	addi	a0,a0,-1822 # 80001278 <digits+0x18>
    8000099e:	aa39                	j	80000abc <uart_puts>

00000000800009a0 <clear_line>:
    800009a0:	00001517          	auipc	a0,0x1
    800009a4:	8e050513          	addi	a0,a0,-1824 # 80001280 <digits+0x20>
    800009a8:	aa11                	j	80000abc <uart_puts>

00000000800009aa <goto_xy>:
    800009aa:	1101                	addi	sp,sp,-32
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	842a                	mv	s0,a0
    800009b0:	456d                	li	a0,27
    800009b2:	ec06                	sd	ra,24(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	e04a                	sd	s2,0(sp)
    800009b8:	84ae                	mv	s1,a1
    800009ba:	0ee000ef          	jal	ra,80000aa8 <uart_putc>
    800009be:	05b00513          	li	a0,91
    800009c2:	0e6000ef          	jal	ra,80000aa8 <uart_putc>
    800009c6:	47a5                	li	a5,9
    800009c8:	0497c363          	blt	a5,s1,80000a0e <goto_xy+0x64>
    800009cc:	4929                	li	s2,10
    800009ce:	0324e53b          	remw	a0,s1,s2
    800009d2:	0305051b          	addiw	a0,a0,48
    800009d6:	0ff57513          	andi	a0,a0,255
    800009da:	0ce000ef          	jal	ra,80000aa8 <uart_putc>
    800009de:	03b00513          	li	a0,59
    800009e2:	0c6000ef          	jal	ra,80000aa8 <uart_putc>
    800009e6:	47a5                	li	a5,9
    800009e8:	0287cd63          	blt	a5,s0,80000a22 <goto_xy+0x78>
    800009ec:	4529                	li	a0,10
    800009ee:	02a4653b          	remw	a0,s0,a0
    800009f2:	0305051b          	addiw	a0,a0,48
    800009f6:	0ff57513          	andi	a0,a0,255
    800009fa:	0ae000ef          	jal	ra,80000aa8 <uart_putc>
    800009fe:	6442                	ld	s0,16(sp)
    80000a00:	60e2                	ld	ra,24(sp)
    80000a02:	64a2                	ld	s1,8(sp)
    80000a04:	6902                	ld	s2,0(sp)
    80000a06:	04800513          	li	a0,72
    80000a0a:	6105                	addi	sp,sp,32
    80000a0c:	a871                	j	80000aa8 <uart_putc>
    80000a0e:	4529                	li	a0,10
    80000a10:	02a4c53b          	divw	a0,s1,a0
    80000a14:	0305051b          	addiw	a0,a0,48
    80000a18:	0ff57513          	andi	a0,a0,255
    80000a1c:	08c000ef          	jal	ra,80000aa8 <uart_putc>
    80000a20:	b775                	j	800009cc <goto_xy+0x22>
    80000a22:	0324453b          	divw	a0,s0,s2
    80000a26:	0305051b          	addiw	a0,a0,48
    80000a2a:	0ff57513          	andi	a0,a0,255
    80000a2e:	07a000ef          	jal	ra,80000aa8 <uart_putc>
    80000a32:	bf6d                	j	800009ec <goto_xy+0x42>

0000000080000a34 <printf_color>:
    80000a34:	1101                	addi	sp,sp,-32
    80000a36:	e426                	sd	s1,8(sp)
    80000a38:	84aa                	mv	s1,a0
    80000a3a:	456d                	li	a0,27
    80000a3c:	ec06                	sd	ra,24(sp)
    80000a3e:	e822                	sd	s0,16(sp)
    80000a40:	842e                	mv	s0,a1
    80000a42:	066000ef          	jal	ra,80000aa8 <uart_putc>
    80000a46:	05b00513          	li	a0,91
    80000a4a:	05e000ef          	jal	ra,80000aa8 <uart_putc>
    80000a4e:	47a5                	li	a5,9
    80000a50:	0497c263          	blt	a5,s1,80000a94 <printf_color+0x60>
    80000a54:	4529                	li	a0,10
    80000a56:	02a4e53b          	remw	a0,s1,a0
    80000a5a:	0305051b          	addiw	a0,a0,48
    80000a5e:	0ff57513          	andi	a0,a0,255
    80000a62:	046000ef          	jal	ra,80000aa8 <uart_putc>
    80000a66:	06d00513          	li	a0,109
    80000a6a:	03e000ef          	jal	ra,80000aa8 <uart_putc>
    80000a6e:	00044503          	lbu	a0,0(s0)
    80000a72:	c901                	beqz	a0,80000a82 <printf_color+0x4e>
    80000a74:	0405                	addi	s0,s0,1
    80000a76:	0405                	addi	s0,s0,1
    80000a78:	030000ef          	jal	ra,80000aa8 <uart_putc>
    80000a7c:	fff44503          	lbu	a0,-1(s0)
    80000a80:	f97d                	bnez	a0,80000a76 <printf_color+0x42>
    80000a82:	6442                	ld	s0,16(sp)
    80000a84:	60e2                	ld	ra,24(sp)
    80000a86:	64a2                	ld	s1,8(sp)
    80000a88:	00001517          	auipc	a0,0x1
    80000a8c:	80050513          	addi	a0,a0,-2048 # 80001288 <digits+0x28>
    80000a90:	6105                	addi	sp,sp,32
    80000a92:	a02d                	j	80000abc <uart_puts>
    80000a94:	4529                	li	a0,10
    80000a96:	02a4c53b          	divw	a0,s1,a0
    80000a9a:	0305051b          	addiw	a0,a0,48
    80000a9e:	0ff57513          	andi	a0,a0,255
    80000aa2:	006000ef          	jal	ra,80000aa8 <uart_putc>
    80000aa6:	b77d                	j	80000a54 <printf_color+0x20>

0000000080000aa8 <uart_putc>:
    80000aa8:	10000737          	lui	a4,0x10000
    80000aac:	00574783          	lbu	a5,5(a4) # 10000005 <_start-0x6ffffffb>
    80000ab0:	0207f793          	andi	a5,a5,32
    80000ab4:	dfe5                	beqz	a5,80000aac <uart_putc+0x4>
    80000ab6:	00a70023          	sb	a0,0(a4)
    80000aba:	8082                	ret

0000000080000abc <uart_puts>:
    80000abc:	00054603          	lbu	a2,0(a0)
    80000ac0:	c205                	beqz	a2,80000ae0 <uart_puts+0x24>
    80000ac2:	00150693          	addi	a3,a0,1
    80000ac6:	10000737          	lui	a4,0x10000
    80000aca:	00574783          	lbu	a5,5(a4) # 10000005 <_start-0x6ffffffb>
    80000ace:	0207f793          	andi	a5,a5,32
    80000ad2:	dfe5                	beqz	a5,80000aca <uart_puts+0xe>
    80000ad4:	00c70023          	sb	a2,0(a4)
    80000ad8:	0006c603          	lbu	a2,0(a3)
    80000adc:	0685                	addi	a3,a3,1
    80000ade:	f675                	bnez	a2,80000aca <uart_puts+0xe>
    80000ae0:	8082                	ret

0000000080000ae2 <kfree>:
    80000ae2:	1141                	addi	sp,sp,-16
    80000ae4:	e406                	sd	ra,8(sp)
    80000ae6:	e022                	sd	s0,0(sp)
    80000ae8:	03451793          	slli	a5,a0,0x34
    80000aec:	eb9d                	bnez	a5,80000b22 <kfree+0x40>
    80000aee:	00001797          	auipc	a5,0x1
    80000af2:	7e278793          	addi	a5,a5,2018 # 800022d0 <timer_interrupt_count>
    80000af6:	842a                	mv	s0,a0
    80000af8:	02f56563          	bltu	a0,a5,80000b22 <kfree+0x40>
    80000afc:	47c5                	li	a5,17
    80000afe:	07ee                	slli	a5,a5,0x1b
    80000b00:	02f57163          	bgeu	a0,a5,80000b22 <kfree+0x40>
    80000b04:	6605                	lui	a2,0x1
    80000b06:	4585                	li	a1,1
    80000b08:	3fe000ef          	jal	ra,80000f06 <memset>
    80000b0c:	00001797          	auipc	a5,0x1
    80000b10:	7cc78793          	addi	a5,a5,1996 # 800022d8 <freelist>
    80000b14:	6398                	ld	a4,0(a5)
    80000b16:	60a2                	ld	ra,8(sp)
    80000b18:	e380                	sd	s0,0(a5)
    80000b1a:	e018                	sd	a4,0(s0)
    80000b1c:	6402                	ld	s0,0(sp)
    80000b1e:	0141                	addi	sp,sp,16
    80000b20:	8082                	ret
    80000b22:	00000517          	auipc	a0,0x0
    80000b26:	76e50513          	addi	a0,a0,1902 # 80001290 <digits+0x30>
    80000b2a:	e33ff0ef          	jal	ra,8000095c <panic>

0000000080000b2e <kalloc>:
    80000b2e:	1141                	addi	sp,sp,-16
    80000b30:	00001797          	auipc	a5,0x1
    80000b34:	7a878793          	addi	a5,a5,1960 # 800022d8 <freelist>
    80000b38:	e022                	sd	s0,0(sp)
    80000b3a:	6380                	ld	s0,0(a5)
    80000b3c:	e406                	sd	ra,8(sp)
    80000b3e:	c801                	beqz	s0,80000b4e <kalloc+0x20>
    80000b40:	6018                	ld	a4,0(s0)
    80000b42:	6605                	lui	a2,0x1
    80000b44:	4595                	li	a1,5
    80000b46:	8522                	mv	a0,s0
    80000b48:	e398                	sd	a4,0(a5)
    80000b4a:	3bc000ef          	jal	ra,80000f06 <memset>
    80000b4e:	60a2                	ld	ra,8(sp)
    80000b50:	8522                	mv	a0,s0
    80000b52:	6402                	ld	s0,0(sp)
    80000b54:	0141                	addi	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <kinit>:
    80000b58:	7179                	addi	sp,sp,-48
    80000b5a:	77fd                	lui	a5,0xfffff
    80000b5c:	f022                	sd	s0,32(sp)
    80000b5e:	00002417          	auipc	s0,0x2
    80000b62:	77140413          	addi	s0,s0,1905 # 800032cf <kernel_pagetable+0xfef>
    80000b66:	8c7d                	and	s0,s0,a5
    80000b68:	e84a                	sd	s2,16(sp)
    80000b6a:	6785                	lui	a5,0x1
    80000b6c:	4945                	li	s2,17
    80000b6e:	f406                	sd	ra,40(sp)
    80000b70:	ec26                	sd	s1,24(sp)
    80000b72:	e44e                	sd	s3,8(sp)
    80000b74:	e052                	sd	s4,0(sp)
    80000b76:	97a2                	add	a5,a5,s0
    80000b78:	096e                	slli	s2,s2,0x1b
    80000b7a:	04f96363          	bltu	s2,a5,80000bc0 <kinit+0x68>
    80000b7e:	00001a17          	auipc	s4,0x1
    80000b82:	752a0a13          	addi	s4,s4,1874 # 800022d0 <timer_interrupt_count>
    80000b86:	05446563          	bltu	s0,s4,80000bd0 <kinit+0x78>
    80000b8a:	05247363          	bgeu	s0,s2,80000bd0 <kinit+0x78>
    80000b8e:	000889b7          	lui	s3,0x88
    80000b92:	19fd                	addi	s3,s3,-1
    80000b94:	00001497          	auipc	s1,0x1
    80000b98:	74448493          	addi	s1,s1,1860 # 800022d8 <freelist>
    80000b9c:	09b2                	slli	s3,s3,0xc
    80000b9e:	a039                	j	80000bac <kinit+0x54>
    80000ba0:	6785                	lui	a5,0x1
    80000ba2:	943e                	add	s0,s0,a5
    80000ba4:	03446663          	bltu	s0,s4,80000bd0 <kinit+0x78>
    80000ba8:	03247463          	bgeu	s0,s2,80000bd0 <kinit+0x78>
    80000bac:	6605                	lui	a2,0x1
    80000bae:	4585                	li	a1,1
    80000bb0:	8522                	mv	a0,s0
    80000bb2:	354000ef          	jal	ra,80000f06 <memset>
    80000bb6:	609c                	ld	a5,0(s1)
    80000bb8:	e080                	sd	s0,0(s1)
    80000bba:	e01c                	sd	a5,0(s0)
    80000bbc:	ff3412e3          	bne	s0,s3,80000ba0 <kinit+0x48>
    80000bc0:	70a2                	ld	ra,40(sp)
    80000bc2:	7402                	ld	s0,32(sp)
    80000bc4:	64e2                	ld	s1,24(sp)
    80000bc6:	6942                	ld	s2,16(sp)
    80000bc8:	69a2                	ld	s3,8(sp)
    80000bca:	6a02                	ld	s4,0(sp)
    80000bcc:	6145                	addi	sp,sp,48
    80000bce:	8082                	ret
    80000bd0:	00000517          	auipc	a0,0x0
    80000bd4:	6c050513          	addi	a0,a0,1728 # 80001290 <digits+0x30>
    80000bd8:	d85ff0ef          	jal	ra,8000095c <panic>

0000000080000bdc <walk.part.0>:
    80000bdc:	7139                	addi	sp,sp,-64
    80000bde:	f426                	sd	s1,40(sp)
    80000be0:	f04a                	sd	s2,32(sp)
    80000be2:	ec4e                	sd	s3,24(sp)
    80000be4:	e852                	sd	s4,16(sp)
    80000be6:	e456                	sd	s5,8(sp)
    80000be8:	fc06                	sd	ra,56(sp)
    80000bea:	f822                	sd	s0,48(sp)
    80000bec:	84aa                	mv	s1,a0
    80000bee:	8a2e                	mv	s4,a1
    80000bf0:	8932                	mv	s2,a2
    80000bf2:	4a89                	li	s5,2
    80000bf4:	4789                	li	a5,2
    80000bf6:	4985                	li	s3,1
    80000bf8:	0037941b          	slliw	s0,a5,0x3
    80000bfc:	9c3d                	addw	s0,s0,a5
    80000bfe:	2431                	addiw	s0,s0,12
    80000c00:	008a5433          	srl	s0,s4,s0
    80000c04:	1ff47413          	andi	s0,s0,511
    80000c08:	040e                	slli	s0,s0,0x3
    80000c0a:	9426                	add	s0,s0,s1
    80000c0c:	6004                	ld	s1,0(s0)
    80000c0e:	0014f793          	andi	a5,s1,1
    80000c12:	80a9                	srli	s1,s1,0xa
    80000c14:	04b2                	slli	s1,s1,0xc
    80000c16:	e38d                	bnez	a5,80000c38 <walk.part.0+0x5c>
    80000c18:	04090463          	beqz	s2,80000c60 <walk.part.0+0x84>
    80000c1c:	f13ff0ef          	jal	ra,80000b2e <kalloc>
    80000c20:	6605                	lui	a2,0x1
    80000c22:	4581                	li	a1,0
    80000c24:	84aa                	mv	s1,a0
    80000c26:	cd0d                	beqz	a0,80000c60 <walk.part.0+0x84>
    80000c28:	2de000ef          	jal	ra,80000f06 <memset>
    80000c2c:	00c4d793          	srli	a5,s1,0xc
    80000c30:	07aa                	slli	a5,a5,0xa
    80000c32:	0017e793          	ori	a5,a5,1
    80000c36:	e01c                	sd	a5,0(s0)
    80000c38:	4785                	li	a5,1
    80000c3a:	033a9163          	bne	s5,s3,80000c5c <walk.part.0+0x80>
    80000c3e:	00ca5513          	srli	a0,s4,0xc
    80000c42:	1ff57513          	andi	a0,a0,511
    80000c46:	050e                	slli	a0,a0,0x3
    80000c48:	9526                	add	a0,a0,s1
    80000c4a:	70e2                	ld	ra,56(sp)
    80000c4c:	7442                	ld	s0,48(sp)
    80000c4e:	74a2                	ld	s1,40(sp)
    80000c50:	7902                	ld	s2,32(sp)
    80000c52:	69e2                	ld	s3,24(sp)
    80000c54:	6a42                	ld	s4,16(sp)
    80000c56:	6aa2                	ld	s5,8(sp)
    80000c58:	6121                	addi	sp,sp,64
    80000c5a:	8082                	ret
    80000c5c:	4a85                	li	s5,1
    80000c5e:	bf69                	j	80000bf8 <walk.part.0+0x1c>
    80000c60:	4501                	li	a0,0
    80000c62:	b7e5                	j	80000c4a <walk.part.0+0x6e>

0000000080000c64 <walk>:
    80000c64:	57fd                	li	a5,-1
    80000c66:	83e5                	srli	a5,a5,0x19
    80000c68:	00b7e363          	bltu	a5,a1,80000c6e <walk+0xa>
    80000c6c:	bf85                	j	80000bdc <walk.part.0>
    80000c6e:	4501                	li	a0,0
    80000c70:	8082                	ret

0000000080000c72 <mappages>:
    80000c72:	7139                	addi	sp,sp,-64
    80000c74:	f426                	sd	s1,40(sp)
    80000c76:	f04a                	sd	s2,32(sp)
    80000c78:	74fd                	lui	s1,0xfffff
    80000c7a:	16fd                	addi	a3,a3,-1
    80000c7c:	597d                	li	s2,-1
    80000c7e:	f822                	sd	s0,48(sp)
    80000c80:	96ae                	add	a3,a3,a1
    80000c82:	0095f433          	and	s0,a1,s1
    80000c86:	fc06                	sd	ra,56(sp)
    80000c88:	ec4e                	sd	s3,24(sp)
    80000c8a:	e852                	sd	s4,16(sp)
    80000c8c:	e456                	sd	s5,8(sp)
    80000c8e:	e05a                	sd	s6,0(sp)
    80000c90:	01995913          	srli	s2,s2,0x19
    80000c94:	8cf5                	and	s1,s1,a3
    80000c96:	02896e63          	bltu	s2,s0,80000cd2 <mappages+0x60>
    80000c9a:	8a2a                	mv	s4,a0
    80000c9c:	8aba                	mv	s5,a4
    80000c9e:	408609b3          	sub	s3,a2,s0
    80000ca2:	6b05                	lui	s6,0x1
    80000ca4:	85a2                	mv	a1,s0
    80000ca6:	4605                	li	a2,1
    80000ca8:	8552                	mv	a0,s4
    80000caa:	f33ff0ef          	jal	ra,80000bdc <walk.part.0>
    80000cae:	008987b3          	add	a5,s3,s0
    80000cb2:	83b1                	srli	a5,a5,0xc
    80000cb4:	07aa                	slli	a5,a5,0xa
    80000cb6:	0157e7b3          	or	a5,a5,s5
    80000cba:	0017e793          	ori	a5,a5,1
    80000cbe:	c911                	beqz	a0,80000cd2 <mappages+0x60>
    80000cc0:	6118                	ld	a4,0(a0)
    80000cc2:	8b05                	andi	a4,a4,1
    80000cc4:	e719                	bnez	a4,80000cd2 <mappages+0x60>
    80000cc6:	e11c                	sd	a5,0(a0)
    80000cc8:	02848063          	beq	s1,s0,80000ce8 <mappages+0x76>
    80000ccc:	945a                	add	s0,s0,s6
    80000cce:	fc897be3          	bgeu	s2,s0,80000ca4 <mappages+0x32>
    80000cd2:	557d                	li	a0,-1
    80000cd4:	70e2                	ld	ra,56(sp)
    80000cd6:	7442                	ld	s0,48(sp)
    80000cd8:	74a2                	ld	s1,40(sp)
    80000cda:	7902                	ld	s2,32(sp)
    80000cdc:	69e2                	ld	s3,24(sp)
    80000cde:	6a42                	ld	s4,16(sp)
    80000ce0:	6aa2                	ld	s5,8(sp)
    80000ce2:	6b02                	ld	s6,0(sp)
    80000ce4:	6121                	addi	sp,sp,64
    80000ce6:	8082                	ret
    80000ce8:	4501                	li	a0,0
    80000cea:	b7ed                	j	80000cd4 <mappages+0x62>

0000000080000cec <dump_pagetable>:
    80000cec:	711d                	addi	sp,sp,-96
    80000cee:	e862                	sd	s8,16(sp)
    80000cf0:	4c05                	li	s8,1
    80000cf2:	e4a6                	sd	s1,72(sp)
    80000cf4:	e0ca                	sd	s2,64(sp)
    80000cf6:	f852                	sd	s4,48(sp)
    80000cf8:	f456                	sd	s5,40(sp)
    80000cfa:	f05a                	sd	s6,32(sp)
    80000cfc:	ec5e                	sd	s7,24(sp)
    80000cfe:	e466                	sd	s9,8(sp)
    80000d00:	ec86                	sd	ra,88(sp)
    80000d02:	e8a2                	sd	s0,80(sp)
    80000d04:	fc4e                	sd	s3,56(sp)
    80000d06:	00159a1b          	slliw	s4,a1,0x1
    80000d0a:	892a                	mv	s2,a0
    80000d0c:	4481                	li	s1,0
    80000d0e:	00000b17          	auipc	s6,0x0
    80000d12:	59ab0b13          	addi	s6,s6,1434 # 800012a8 <digits+0x48>
    80000d16:	00000a97          	auipc	s5,0x0
    80000d1a:	59aa8a93          	addi	s5,s5,1434 # 800012b0 <digits+0x50>
    80000d1e:	00158b9b          	addiw	s7,a1,1
    80000d22:	0c7e                	slli	s8,s8,0x1f
    80000d24:	20000c93          	li	s9,512
    80000d28:	a021                	j	80000d30 <dump_pagetable+0x44>
    80000d2a:	2485                	addiw	s1,s1,1
    80000d2c:	03948d63          	beq	s1,s9,80000d66 <dump_pagetable+0x7a>
    80000d30:	00093403          	ld	s0,0(s2)
    80000d34:	0921                	addi	s2,s2,8
    80000d36:	00147793          	andi	a5,s0,1
    80000d3a:	dbe5                	beqz	a5,80000d2a <dump_pagetable+0x3e>
    80000d3c:	00a45993          	srli	s3,s0,0xa
    80000d40:	09b2                	slli	s3,s3,0xc
    80000d42:	8722                	mv	a4,s0
    80000d44:	86a6                	mv	a3,s1
    80000d46:	87ce                	mv	a5,s3
    80000d48:	865a                	mv	a2,s6
    80000d4a:	85d2                	mv	a1,s4
    80000d4c:	8556                	mv	a0,s5
    80000d4e:	8839                	andi	s0,s0,14
    80000d50:	e68ff0ef          	jal	ra,800003b8 <printf>
    80000d54:	f879                	bnez	s0,80000d2a <dump_pagetable+0x3e>
    80000d56:	85de                	mv	a1,s7
    80000d58:	01898533          	add	a0,s3,s8
    80000d5c:	2485                	addiw	s1,s1,1
    80000d5e:	f8fff0ef          	jal	ra,80000cec <dump_pagetable>
    80000d62:	fd9497e3          	bne	s1,s9,80000d30 <dump_pagetable+0x44>
    80000d66:	60e6                	ld	ra,88(sp)
    80000d68:	6446                	ld	s0,80(sp)
    80000d6a:	64a6                	ld	s1,72(sp)
    80000d6c:	6906                	ld	s2,64(sp)
    80000d6e:	79e2                	ld	s3,56(sp)
    80000d70:	7a42                	ld	s4,48(sp)
    80000d72:	7aa2                	ld	s5,40(sp)
    80000d74:	7b02                	ld	s6,32(sp)
    80000d76:	6be2                	ld	s7,24(sp)
    80000d78:	6c42                	ld	s8,16(sp)
    80000d7a:	6ca2                	ld	s9,8(sp)
    80000d7c:	6125                	addi	sp,sp,96
    80000d7e:	8082                	ret

0000000080000d80 <create_pagetable>:
    80000d80:	1141                	addi	sp,sp,-16
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	e406                	sd	ra,8(sp)
    80000d86:	da9ff0ef          	jal	ra,80000b2e <kalloc>
    80000d8a:	842a                	mv	s0,a0
    80000d8c:	c509                	beqz	a0,80000d96 <create_pagetable+0x16>
    80000d8e:	6605                	lui	a2,0x1
    80000d90:	4581                	li	a1,0
    80000d92:	174000ef          	jal	ra,80000f06 <memset>
    80000d96:	60a2                	ld	ra,8(sp)
    80000d98:	8522                	mv	a0,s0
    80000d9a:	6402                	ld	s0,0(sp)
    80000d9c:	0141                	addi	sp,sp,16
    80000d9e:	8082                	ret

0000000080000da0 <map_page>:
    80000da0:	8736                	mv	a4,a3
    80000da2:	6685                	lui	a3,0x1
    80000da4:	b5f9                	j	80000c72 <mappages>

0000000080000da6 <destroy_pagetable>:
    80000da6:	c529                	beqz	a0,80000df0 <destroy_pagetable+0x4a>
    80000da8:	1101                	addi	sp,sp,-32
    80000daa:	e426                	sd	s1,8(sp)
    80000dac:	6485                	lui	s1,0x1
    80000dae:	e822                	sd	s0,16(sp)
    80000db0:	e04a                	sd	s2,0(sp)
    80000db2:	ec06                	sd	ra,24(sp)
    80000db4:	892a                	mv	s2,a0
    80000db6:	842a                	mv	s0,a0
    80000db8:	94aa                	add	s1,s1,a0
    80000dba:	a031                	j	80000dc6 <destroy_pagetable+0x20>
    80000dbc:	febff0ef          	jal	ra,80000da6 <destroy_pagetable>
    80000dc0:	0421                	addi	s0,s0,8
    80000dc2:	02940063          	beq	s0,s1,80000de2 <destroy_pagetable+0x3c>
    80000dc6:	601c                	ld	a5,0(s0)
    80000dc8:	0017f713          	andi	a4,a5,1
    80000dcc:	00a7d513          	srli	a0,a5,0xa
    80000dd0:	8bb9                	andi	a5,a5,14
    80000dd2:	d77d                	beqz	a4,80000dc0 <destroy_pagetable+0x1a>
    80000dd4:	0532                	slli	a0,a0,0xc
    80000dd6:	d3fd                	beqz	a5,80000dbc <destroy_pagetable+0x16>
    80000dd8:	0421                	addi	s0,s0,8
    80000dda:	d09ff0ef          	jal	ra,80000ae2 <kfree>
    80000dde:	fe9414e3          	bne	s0,s1,80000dc6 <destroy_pagetable+0x20>
    80000de2:	6442                	ld	s0,16(sp)
    80000de4:	60e2                	ld	ra,24(sp)
    80000de6:	64a2                	ld	s1,8(sp)
    80000de8:	854a                	mv	a0,s2
    80000dea:	6902                	ld	s2,0(sp)
    80000dec:	6105                	addi	sp,sp,32
    80000dee:	b9d5                	j	80000ae2 <kfree>
    80000df0:	8082                	ret

0000000080000df2 <walk_create>:
    80000df2:	57fd                	li	a5,-1
    80000df4:	83e5                	srli	a5,a5,0x19
    80000df6:	00b7e463          	bltu	a5,a1,80000dfe <walk_create+0xc>
    80000dfa:	4605                	li	a2,1
    80000dfc:	b3c5                	j	80000bdc <walk.part.0>
    80000dfe:	4501                	li	a0,0
    80000e00:	8082                	ret

0000000080000e02 <walk_lookup>:
    80000e02:	57fd                	li	a5,-1
    80000e04:	83e5                	srli	a5,a5,0x19
    80000e06:	04b7e063          	bltu	a5,a1,80000e46 <walk_lookup+0x44>
    80000e0a:	01e5d793          	srli	a5,a1,0x1e
    80000e0e:	078e                	slli	a5,a5,0x3
    80000e10:	953e                	add	a0,a0,a5
    80000e12:	6118                	ld	a4,0(a0)
    80000e14:	4501                	li	a0,0
    80000e16:	00177793          	andi	a5,a4,1
    80000e1a:	c79d                	beqz	a5,80000e48 <walk_lookup+0x46>
    80000e1c:	0155d793          	srli	a5,a1,0x15
    80000e20:	8329                	srli	a4,a4,0xa
    80000e22:	1ff7f793          	andi	a5,a5,511
    80000e26:	0732                	slli	a4,a4,0xc
    80000e28:	078e                	slli	a5,a5,0x3
    80000e2a:	97ba                	add	a5,a5,a4
    80000e2c:	639c                	ld	a5,0(a5)
    80000e2e:	0017f713          	andi	a4,a5,1
    80000e32:	cb19                	beqz	a4,80000e48 <walk_lookup+0x46>
    80000e34:	00c5d513          	srli	a0,a1,0xc
    80000e38:	83a9                	srli	a5,a5,0xa
    80000e3a:	1ff57513          	andi	a0,a0,511
    80000e3e:	07b2                	slli	a5,a5,0xc
    80000e40:	050e                	slli	a0,a0,0x3
    80000e42:	953e                	add	a0,a0,a5
    80000e44:	8082                	ret
    80000e46:	4501                	li	a0,0
    80000e48:	8082                	ret

0000000080000e4a <kvminit>:
    80000e4a:	1101                	addi	sp,sp,-32
    80000e4c:	ec06                	sd	ra,24(sp)
    80000e4e:	e822                	sd	s0,16(sp)
    80000e50:	e426                	sd	s1,8(sp)
    80000e52:	cddff0ef          	jal	ra,80000b2e <kalloc>
    80000e56:	00001417          	auipc	s0,0x1
    80000e5a:	48a40413          	addi	s0,s0,1162 # 800022e0 <kernel_pagetable>
    80000e5e:	6605                	lui	a2,0x1
    80000e60:	4581                	li	a1,0
    80000e62:	e008                	sd	a0,0(s0)
    80000e64:	0a2000ef          	jal	ra,80000f06 <memset>
    80000e68:	4485                	li	s1,1
    80000e6a:	6008                	ld	a0,0(s0)
    80000e6c:	01f49613          	slli	a2,s1,0x1f
    80000e70:	85b2                	mv	a1,a2
    80000e72:	4729                	li	a4,10
    80000e74:	80000697          	auipc	a3,0x80000
    80000e78:	1d268693          	addi	a3,a3,466 # 1046 <_start-0x7fffefba>
    80000e7c:	df7ff0ef          	jal	ra,80000c72 <mappages>
    80000e80:	6008                	ld	a0,0(s0)
    80000e82:	46c5                	li	a3,17
    80000e84:	00000617          	auipc	a2,0x0
    80000e88:	1c260613          	addi	a2,a2,450 # 80001046 <etext>
    80000e8c:	01f49593          	slli	a1,s1,0x1f
    80000e90:	06ee                	slli	a3,a3,0x1b
    80000e92:	8e91                	sub	a3,a3,a2
    80000e94:	95b2                	add	a1,a1,a2
    80000e96:	4719                	li	a4,6
    80000e98:	ddbff0ef          	jal	ra,80000c72 <mappages>
    80000e9c:	6008                	ld	a0,0(s0)
    80000e9e:	4719                	li	a4,6
    80000ea0:	6685                	lui	a3,0x1
    80000ea2:	10000637          	lui	a2,0x10000
    80000ea6:	100005b7          	lui	a1,0x10000
    80000eaa:	dc9ff0ef          	jal	ra,80000c72 <mappages>
    80000eae:	6008                	ld	a0,0(s0)
    80000eb0:	4719                	li	a4,6
    80000eb2:	6685                	lui	a3,0x1
    80000eb4:	10001637          	lui	a2,0x10001
    80000eb8:	100015b7          	lui	a1,0x10001
    80000ebc:	db7ff0ef          	jal	ra,80000c72 <mappages>
    80000ec0:	6008                	ld	a0,0(s0)
    80000ec2:	4719                	li	a4,6
    80000ec4:	66c1                	lui	a3,0x10
    80000ec6:	02000637          	lui	a2,0x2000
    80000eca:	020005b7          	lui	a1,0x2000
    80000ece:	da5ff0ef          	jal	ra,80000c72 <mappages>
    80000ed2:	6008                	ld	a0,0(s0)
    80000ed4:	6442                	ld	s0,16(sp)
    80000ed6:	60e2                	ld	ra,24(sp)
    80000ed8:	64a2                	ld	s1,8(sp)
    80000eda:	4719                	li	a4,6
    80000edc:	004006b7          	lui	a3,0x400
    80000ee0:	0c000637          	lui	a2,0xc000
    80000ee4:	0c0005b7          	lui	a1,0xc000
    80000ee8:	6105                	addi	sp,sp,32
    80000eea:	b361                	j	80000c72 <mappages>

0000000080000eec <kvminithart>:
    80000eec:	00001797          	auipc	a5,0x1
    80000ef0:	3f47b783          	ld	a5,1012(a5) # 800022e0 <kernel_pagetable>
    80000ef4:	577d                	li	a4,-1
    80000ef6:	177e                	slli	a4,a4,0x3f
    80000ef8:	83b1                	srli	a5,a5,0xc
    80000efa:	8fd9                	or	a5,a5,a4
    80000efc:	18079073          	csrw	satp,a5
    80000f00:	12000073          	sfence.vma
    80000f04:	8082                	ret

0000000080000f06 <memset>:
    80000f06:	ce09                	beqz	a2,80000f20 <memset+0x1a>
    80000f08:	1602                	slli	a2,a2,0x20
    80000f0a:	9201                	srli	a2,a2,0x20
    80000f0c:	0ff5f593          	andi	a1,a1,255
    80000f10:	87aa                	mv	a5,a0
    80000f12:	00a60733          	add	a4,a2,a0
    80000f16:	00b78023          	sb	a1,0(a5)
    80000f1a:	0785                	addi	a5,a5,1
    80000f1c:	fee79de3          	bne	a5,a4,80000f16 <memset+0x10>
    80000f20:	8082                	ret

0000000080000f22 <memcmp>:
    80000f22:	c21d                	beqz	a2,80000f48 <memcmp+0x26>
    80000f24:	1602                	slli	a2,a2,0x20
    80000f26:	9201                	srli	a2,a2,0x20
    80000f28:	00c586b3          	add	a3,a1,a2
    80000f2c:	a019                	j	80000f32 <memcmp+0x10>
    80000f2e:	00b68d63          	beq	a3,a1,80000f48 <memcmp+0x26>
    80000f32:	00054783          	lbu	a5,0(a0)
    80000f36:	0005c703          	lbu	a4,0(a1) # c000000 <_start-0x74000000>
    80000f3a:	0505                	addi	a0,a0,1
    80000f3c:	0585                	addi	a1,a1,1
    80000f3e:	fee788e3          	beq	a5,a4,80000f2e <memcmp+0xc>
    80000f42:	40e7853b          	subw	a0,a5,a4
    80000f46:	8082                	ret
    80000f48:	4501                	li	a0,0
    80000f4a:	8082                	ret

0000000080000f4c <memmove>:
    80000f4c:	c629                	beqz	a2,80000f96 <memmove+0x4a>
    80000f4e:	02061793          	slli	a5,a2,0x20
    80000f52:	fff6069b          	addiw	a3,a2,-1
    80000f56:	9381                	srli	a5,a5,0x20
    80000f58:	00a5ed63          	bltu	a1,a0,80000f72 <memmove+0x26>
    80000f5c:	97ae                	add	a5,a5,a1
    80000f5e:	872a                	mv	a4,a0
    80000f60:	0005c683          	lbu	a3,0(a1)
    80000f64:	0585                	addi	a1,a1,1
    80000f66:	0705                	addi	a4,a4,1
    80000f68:	fed70fa3          	sb	a3,-1(a4)
    80000f6c:	fef59ae3          	bne	a1,a5,80000f60 <memmove+0x14>
    80000f70:	8082                	ret
    80000f72:	00f58733          	add	a4,a1,a5
    80000f76:	fee573e3          	bgeu	a0,a4,80000f5c <memmove+0x10>
    80000f7a:	1682                	slli	a3,a3,0x20
    80000f7c:	9281                	srli	a3,a3,0x20
    80000f7e:	fff6c693          	not	a3,a3
    80000f82:	97aa                	add	a5,a5,a0
    80000f84:	96ba                	add	a3,a3,a4
    80000f86:	fff74603          	lbu	a2,-1(a4)
    80000f8a:	177d                	addi	a4,a4,-1
    80000f8c:	17fd                	addi	a5,a5,-1
    80000f8e:	00c78023          	sb	a2,0(a5)
    80000f92:	fee69ae3          	bne	a3,a4,80000f86 <memmove+0x3a>
    80000f96:	8082                	ret

0000000080000f98 <memcpy>:
    80000f98:	bf55                	j	80000f4c <memmove>

0000000080000f9a <strncmp>:
    80000f9a:	c605                	beqz	a2,80000fc2 <strncmp+0x28>
    80000f9c:	1602                	slli	a2,a2,0x20
    80000f9e:	9201                	srli	a2,a2,0x20
    80000fa0:	00c586b3          	add	a3,a1,a2
    80000fa4:	a031                	j	80000fb0 <strncmp+0x16>
    80000fa6:	0505                	addi	a0,a0,1
    80000fa8:	00e79a63          	bne	a5,a4,80000fbc <strncmp+0x22>
    80000fac:	00b68b63          	beq	a3,a1,80000fc2 <strncmp+0x28>
    80000fb0:	00054783          	lbu	a5,0(a0)
    80000fb4:	0585                	addi	a1,a1,1
    80000fb6:	fff5c703          	lbu	a4,-1(a1)
    80000fba:	f7f5                	bnez	a5,80000fa6 <strncmp+0xc>
    80000fbc:	40e7853b          	subw	a0,a5,a4
    80000fc0:	8082                	ret
    80000fc2:	4501                	li	a0,0
    80000fc4:	8082                	ret

0000000080000fc6 <strncpy>:
    80000fc6:	872a                	mv	a4,a0
    80000fc8:	a801                	j	80000fd8 <strncpy+0x12>
    80000fca:	0005c783          	lbu	a5,0(a1)
    80000fce:	0705                	addi	a4,a4,1
    80000fd0:	0585                	addi	a1,a1,1
    80000fd2:	fef70fa3          	sb	a5,-1(a4)
    80000fd6:	c789                	beqz	a5,80000fe0 <strncpy+0x1a>
    80000fd8:	8832                	mv	a6,a2
    80000fda:	367d                	addiw	a2,a2,-1
    80000fdc:	ff0047e3          	bgtz	a6,80000fca <strncpy+0x4>
    80000fe0:	86ba                	mv	a3,a4
    80000fe2:	00c05d63          	blez	a2,80000ffc <strncpy+0x36>
    80000fe6:	0685                	addi	a3,a3,1
    80000fe8:	fff6c793          	not	a5,a3
    80000fec:	9fb9                	addw	a5,a5,a4
    80000fee:	010787bb          	addw	a5,a5,a6
    80000ff2:	fe068fa3          	sb	zero,-1(a3) # 3fffff <_start-0x7fc00001>
    80000ff6:	fef048e3          	bgtz	a5,80000fe6 <strncpy+0x20>
    80000ffa:	8082                	ret
    80000ffc:	8082                	ret

0000000080000ffe <safestrcpy>:
    80000ffe:	02c05363          	blez	a2,80001024 <safestrcpy+0x26>
    80001002:	fff6069b          	addiw	a3,a2,-1
    80001006:	1682                	slli	a3,a3,0x20
    80001008:	9281                	srli	a3,a3,0x20
    8000100a:	96ae                	add	a3,a3,a1
    8000100c:	87aa                	mv	a5,a0
    8000100e:	00d58963          	beq	a1,a3,80001020 <safestrcpy+0x22>
    80001012:	0005c703          	lbu	a4,0(a1)
    80001016:	0785                	addi	a5,a5,1
    80001018:	0585                	addi	a1,a1,1
    8000101a:	fee78fa3          	sb	a4,-1(a5)
    8000101e:	fb65                	bnez	a4,8000100e <safestrcpy+0x10>
    80001020:	00078023          	sb	zero,0(a5)
    80001024:	8082                	ret

0000000080001026 <strlen>:
    80001026:	00054783          	lbu	a5,0(a0)
    8000102a:	cf81                	beqz	a5,80001042 <strlen+0x1c>
    8000102c:	00150793          	addi	a5,a0,1
    80001030:	40a006bb          	negw	a3,a0
    80001034:	0007c703          	lbu	a4,0(a5)
    80001038:	00f6853b          	addw	a0,a3,a5
    8000103c:	0785                	addi	a5,a5,1
    8000103e:	fb7d                	bnez	a4,80001034 <strlen+0xe>
    80001040:	8082                	ret
    80001042:	4501                	li	a0,0
    80001044:	8082                	ret
