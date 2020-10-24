ClearAPU:
	lda #$00
	ldx #$00
caloop:
	sta APU_PULSE1_VD,x
	inx
	cpx $18
	bne caloop
	rts

PlayTriangle:
	sta APU_TRI_LC
	iny
	lda (clipStart),y
	sta APU_TRI_FRQ
	iny
	lda (clipStart),y
	sta APU_TRI_LEN
	incptra clipStart,3

PlaySquare:
	sta APU_PULSE1_VD
	iny
	lda (clipStart),y
	sta APU_PULSE1_SWP
	iny
	lda (clipStart),y
	sta APU_PULSE1_FRQ
	iny
	lda (clipStart),y
	sta APU_PULSE1_LEN
	incptra clipStart,4

PlayNoise:
	sta APU_NOISE_VD
	iny
	lda (clipStart),y
	sta APU_NOISE_FRQ
	iny
	lda (clipStart),y
	sta APU_NOISE_LEN
	incptra clipStart,3
	rts
