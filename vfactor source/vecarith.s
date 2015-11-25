#/*************************************************************************************#*#* vecarith.s#*#* Assembly routines for AltiVec-based giant arithmetic.#*#* Updates:#*	31 Mar 99   (proj) Delivery to A. Sazegari, Apple/Cupertino#* 	1  Feb 99   JAK - creation.#*#* This package is part of ongoing research in the#* Advanced Computation Group, Apple Computer.#* #* c. 1999 Apple Computer, Inc.#* All Rights Reserved.#*#************************************************************************************/#//----------------------------------------------------------	MACRO	MakeFunction &fnName		EXPORT &fnName[DS]		EXPORT .&fnName[PR]				TC &fnName[TC], &fnName[DS]					CSECT &fnName[DS]		DC.L .&fnName[PR]		DC.L TOC[tc0]				CSECT .&fnName[PR]		;FUNCTION .&fnName[PR]				ENDM#//----------------------------------------------------------# /*# addvecs# arguments:	# r3 = vector unsigned long *pvec1# r4 = unsigned long len1# r5 = vector unsigned long *pvec2# r6 = unsigned long len2# r7 = vector unsigned long *presults# */	MakeFunction	addvecs	cmpl	cr0, r4, r6	# compare lengths	bng	cr0,.len2shorter		mr	r11, r3	# len1 is shorter	mr	r9, r4		mr	r4, r6		mr	r3, r5		b	.lenCompareDone	.len2shorter:	mr	r9, r6	# len2 is shorter	mr	r11, r5		.lenCompareDone:	addic	r8, 0, 0	# r8 = 0, clear carry	cmpli	cr0, r4, 0	addi	r8, 0, 0		addi	r12, 0, 0		bng	cr0,.addvecs_startcarry	# short length is zero		addi	r11, r11, -16		addi	r10, r3, -16		mtspr	CTR, r4		addi	r12, r7, -4	.addvecs_looptop:	lwz	r0, 28(r10)	# load long digit 1	lwz	r3, 28(r11)	# load long digit 2	adde	r6, r0, r3	# add with carry	stwu	r6, 16(r12)	# store result	lwz	r7, 24(r10)		lwz	r0, 24(r11)		adde	r0, r7, r0		stw	r0, -4(r12)		lwz	r0, 20(r10)		lwz	r7, 20(r11)		adde	r0, r0, r7		stw	r0, -8(r12)		lwzu	r0, 16(r10)		lwzu	r7, 16(r11)		adde	r0, r0, r7		stw	r0, -12(r12)		bdnz	.addvecs_looptop	# loop through short count	addi	r7, r12, 4		addi	r11, r11, 16		mr	r12, r4	.addvecs_startcarry:	cmpl	cr0, r12, r9		addi	r10, 0, 1		bnl	cr0,.addvecs_done		addi	r11, r11, -16		subf	r0, r12, r9		addi	r12, r7, -4		mtspr	CTR, r0	.addvecs_carrylooptop:	lwz	r3, 28(r11)		addze	r3, r3		stwu	r3, 16(r12)		lwz	r5, 24(r11)		addze	r5, r5		stw	r5, -4(r12)		lwz	r6, 20(r11)		addze	r6, r6		stw	r6, -8(r12)		lwzu	r7, 16(r11)		addze	r7, r7		stw	r7, -12(r12)		bdnz	.addvecs_carrylooptop		addi	r7, r12, 4	.addvecs_done:	addze	r3, r8	# add carry bit to zero for top digit	stw	r8, 0(r7)		stw	r8, 8(r7)		stw	r3, 12(r7)		stw	r8, 4(r7)		blr	#//---------------------------------------------------------------------------------# /*# subvecs# arguments:	# r3 = vector unsigned long *pvec1# r4 = unsigned long len1# r5 = vector unsigned long *pvec2# r6 = unsigned long len2# r7 = vector unsigned long *presults## subtracts p1 from p2, stores in presults# NOTE, assumes len1 <= len2# */	MakeFunction	subvecs	cmpli	cr0, r4, 0		addi	r9, 0, 0		addi	r12, 0, 0		subfic	r9, r9, 0		bng	cr0,.subvecs_carrystart		addi	r10, r3, -16		addi	r11, r5, -16		mtspr	CTR, r4		addi	r12, r7, -4	.subvecs_looptop:	lwz	r0, 28(r11)		lwz	r3, 28(r10)		subfe	r7, r3, r0		stwu	r7, 16(r12)		lwz	r8, 24(r11)		lwz	r0, 24(r10)		subfe	r0, r0, r8		stw	r0, -4(r12)		lwz	r0, 20(r11)		lwz	r8, 20(r10)		subfe	r0, r8, r0		stw	r0, -8(r12)		lwzu	r0, 16(r11)		lwzu	r8, 16(r10)		subfe	r0, r8, r0		stw	r0, -12(r12)		bdnz	.subvecs_looptop		addi	r7, r12, 4		addi	r5, r11, 16		mr	r12, r4	.subvecs_carrystart:	cmpl	cr0, r12, r6		bnl	cr0,.subvecs_done		addi	r11, r5, -16		subf	r0, r12, r6		addi	r12, r7, -4		mtspr	CTR, r0	.subvecs_carrylooptop:	lwz	r3, 28(r11)		subfe	r3, r9, r3 		stwu	r3, 16(r12)		lwz	r5, 24(r11)		subfe	r5, r9, r5 		stw	r5, -4(r12)		lwz	r6, 20(r11)		subfe	r6, r9, r6		stw	r6, -8(r12)		lwzu	r7, 16(r11)		subfe	r7, r9, r7		stw	r7, -12(r12)		bdnz	.subvecs_carrylooptop		addi	r7, r12, 4	.subvecs_done:	blr	#//---------------------------------------------------------------------------------	#// MultVecsByULong#// arguments :	pointer to vectors (r3)#// 	number of vectors (r4)#//	multiplier (r5)	MakeFunction	MultVecsByULong		li         r6,0		# clear carry digit		mtctr      r4		# r4 -> counter	.MVBL_looptop:	lwz        r4,12(r3)	# lowest long in vector->r4	mullw      r0,r5,r4	# multiplier*long -> r0 (low result)	mulhwu     r4,r5,r4	# multiplier*long -> r4 (high result)	addc       r0,r0,r6	# add carry to low result, and maybe set carry bit	addze      r6,r4		# add any carry bit to high result, move to carry digit	stw        r0,12(r3)	# save low multiplier	# same as above for long #2 in vector	lwz        r4,8(r3)			mullw      r0,r5,r4	mulhwu     r4,r5,r4	addc       r0,r0,r6	addze      r6,r4	stw        r0,8(r3)	# same as above for long #3 in vector	lwz        r4,4(r3)	mullw      r0,r5,r4	mulhwu     r4,r5,r4	addc       r0,r0,r6	addze      r6,r4	stw        r0,4(r3)	# same as above for long #4 in vector	lwz        r4,0(r3)	mullw      r0,r5,r4	mulhwu     r4,r5,r4	addc       r0,r0,r6	addze      r6,r4	stw        r0,0(r3)		# move on to next vector				addi       r3,r3,16		bdnz       .MVBL_looptop	mr         r3,r6		# return last carry 	blr#//---------------------------------------------------------------------------------#// AddULongToVecs#// arguments :	pointer to vectors (r3)#// 	number of vectors (r4)#//	ulong to add (r5)	MakeFunction	AddULongToVecs	addi       r6, 0, 0	# r6 = 0	lwz        r0,12(r3)	# r0 = lsd	addc       r0,r0,r5	# add in ulong	stw        r0,12(r3)	# store back		# propagate carry through next 3 longs	lwz        r5,8(r3)		addze       r0,r5	stw        r0,8(r3)	lwz        r5,4(r3)	addze       r0,r5	stw        r0,4(r3)	lwz        r5,0(r3)	addze       r0,r5	stw        r0,0(r3)	subi       r0,r4,1		# propagate carry through all vectors 		mtctr      r0	cmplwi     r4,$0001	ble        .AULTV_exit	.AULTV_looptop:		lwz        r4,28(r3)	addze      r0,r4	stw        r0,28(r3)	lwz        r4,24(r3)	addze      r0,r4	stw        r0,24(r3)	lwz        r4,20(r3)	addze      r0,r4	stw        r0,20(r3)	lwz        r4,16(r3)	addze      r0,r4	stwu       r0,16(r3)	# store top long and update r3 ptr		bdnz       .AULTV_looptop.AULTV_exit:		addze      r3, r6		# return last carry	blr	