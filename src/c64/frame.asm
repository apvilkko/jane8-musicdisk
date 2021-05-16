; do the fast per-frame processing for sound
AdvanceFrame:
	jsr DoPwm
	ldy #0
LoopDrumVariant:
	sty drum_variant
	tya
	asl ; *4
	asl
	tax
	lda kick_ch,x
	bmi SkipDoWork
	jsr DoWork
SkipDoWork:
	iny
	cpy #3
	bne LoopDrumVariant
	rts

sid_offset = temp3

; A: drum channel
; X: offset to drum variant data
DoWork:
	stx temp2

	;cpy #0
	;beq DoResetDrum
	;cpy #2
	;beq DoResetDrum
	;jmp SetSidOffset

;DoResetDrum:
	;jmp ResetDrum

SetSidOffset:
	; set SID regs offset (*7)
	tax
	lda #-7
AddOffset:
	clc
	adc #7
	dex
	bpl AddOffset

	tax
	stx sid_offset
	ldx temp2
	lda kick_pos,x
	beq DrumStart
	cmp #1
	beq DrumTail
	jmp WorkDrum

DrumStart:
	ldx sid_offset
	lda #$00
	sta SID_V1_CTL,x
	lda #244
	sta SID_V1_FREQ_1,x
	lda #3
	sta SID_V1_FREQ_2,x
	sta SID_V1_PW_1,x
	sta SID_V1_PW_2,x
	lda #$0f
	sta SID_V1_AD,x
	lda #$00
	sta SID_V1_SR,x
	lda drum_variant
	cmp #0
	beq KickStart
	cmp #2
	beq HihatStart
	jmp SnareStart
HihatStart:
KickStart:
	lda #%10000001 ; noise
	db $2c
SnareStart:
	lda #%00100001 ; saw
	sta SID_V1_CTL,x
	jmp IncDrumPos

DrumTail:
	lda drum_variant
	cmp #0
	beq KickTail
	cmp #2
	beq HihatTail
	jmp SnareTail
KickTail:
	lda #48
	sta kick_f_lo,x
	ldx sid_offset
	sta SID_V1_FREQ_1,x
	lda #4
	ldx temp2
	sta kick_f_hi,x
	ldx sid_offset
	sta SID_V1_FREQ_2,x
	lda #$06
	sta SID_V1_AD,x
	lda #$06
	sta SID_V1_SR,x
	lda #%01000001 ; pulse
	jmp TriggerTail
HihatTail:
	lda #100
	sta kick_f_lo,x
	ldx sid_offset
	sta SID_V1_FREQ_1,x
	lda #100
	ldx temp2
	sta kick_f_hi,x
	ldx sid_offset
	sta SID_V1_FREQ_2,x
	lda #$03
	sta SID_V1_AD,x
	lda #$03
	sta SID_V1_SR,x
	lda #%10000001 ; noise
	jmp TriggerTail
SnareTail:
	lda #15
	sta kick_f_lo,x
	ldx sid_offset
	sta SID_V1_FREQ_1,x
	lda #67
	ldx temp2
	sta kick_f_hi,x
	ldx sid_offset
	sta SID_V1_FREQ_2,x
	lda #$06
	sta SID_V1_AD,x
	lda #$06
	sta SID_V1_SR,x
	lda #%10000001 ; noise
TriggerTail:
	sta SID_V1_CTL,x
	jmp IncDrumPos

WorkDrum:
	lda drum_variant
	cmp #0
	beq KickFreqDelta
	cmp #2
	beq HihatFreqDelta
	jmp SnareFreqDelta
KickFreqDelta:
	lda #8
	db $2c
HihatFreqDelta:
	lda #1
	db $2c
SnareFreqDelta:
	lda #4
	sta temp4
	lda kick_f_lo,x
	sec
	sbc temp4
	bmi LoMinus
	jmp SetLo
LoMinus:
	lda #0
SetLo:
	sta kick_f_lo,x
	ldx sid_offset
	sta SID_V1_FREQ_1,x

	ldx temp2
	lda kick_f_hi,x
	sec
	sbc temp4
	bmi HiMinus
	jmp SetHi
HiMinus:
	lda #0
SetHi:
	sta kick_f_hi,x
	ldx sid_offset
	sta SID_V1_FREQ_2,x

IncDrumPos:
	ldx temp2
	inc kick_pos,x
	lda kick_pos,x
	cmp #12
	bne ExitDoWork

ResetDrum:
	ldx temp2
	lda #$ff
	sta kick_ch,x
	sta kick_pos,x
ExitDoWork:
	rts


DoPwm:
	ldx #2
PwmLoop
	jsr DoPwmChannel
	dex
	bpl PwmLoop
	rts

; X: channel offset (0-2)
DoPwmChannel:
	pushall
	stx temp4
	lda #-7
AddMoreOffset:
	clc
	adc #7
	dex
	bpl AddMoreOffset

	tax
	stx sid_offset

	lda temp4
	asl ; *2
	tax

	inc pwm1,x
	beq IncPwmHi
	jmp SetPwmValues
IncPwmHi:
	inx
	inc pwm1,x
	lda pwm1,x
	and #%00010000
	beq SetPwmValues
	lda #0
	sta pwm1,x
	dex
	sta pwm1,x
	inx
SetPwmValues:
	ldx temp4
	lda pwm1,x
	ldx sid_offset
	sta SID_V1_PW_1,x
	ldx temp4
	inx
	inx
	lda pwm1,x
	ldx sid_offset
	sta SID_V1_PW_2,x
	pullall
	rts
