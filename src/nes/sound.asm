ClearAPU:
	lda #$00
	ldx #$00
caloop:
	sta APU_PULSE1_VD,x
	inx
	cpx $18
	bne caloop
	rts
