SoundDriver:
	jsr AdvanceFrame
	lda tickCount
	beq continueSound
	jmp ExitSoundDriver
continueSound:
	ldx #$00
	stx channel
	stx offset
loopChannels:

	; Read next data
	ldy #$00
	lda (dataPosLo),y
	cmp #$ff
	bne skipResetPointer
resetPointer:
	lda #<MusicDataStart
	sta dataPosLo
	lda #>MusicDataStart
	sta dataPosHi
skipResetPointer:
	sta temp
	;print offset,8
	;print dataPosLo,12
	and #%10000000 ; Rest
	bne skipItem

	lda temp
	and #%01000000 ; Same
	beq readNote
readCached:
	ldy offset
	lda noteCache,y
	sta temp
	jsr SetPitch
	lda noteCache+1,y
	sta inst
	jsr SetInstrument
	jmp playNote

readNote:
	lda temp
	sta noteCache,y

	jsr SetPitch

	; read instrument
	inc16 dataPosLo, skip1
	ldy #$00
	lda (dataPosLo),y
	ldy offset
	sta noteCache+1,y
	sta inst
	jsr SetInstrument

playNote:
	lda ctl
	beq skipItem

	; gate off
	lda #$00
	ldy offset
	sta SID_V1_CTL,y

	; play note
	lda ad
  	sta SID_V1_AD,y

	lda sr
  	sta SID_V1_SR,y

	lda ctl
	ora #1
  	sta SID_V1_CTL,y

skipItem:
	inc16 dataPosLo, skip2
	lda offset
	clc
	adc #7
	sta offset
	inx
	cpx #$03
	beq ExitSoundDriver
	stx channel
	jmp loopChannels

ExitSoundDriver:
	rts

SetPitch:
	pushall
	ldx temp
	ldy offset
	lda PitchTableLo,x
	sta SID_V1_FREQ_1,y
	lda PitchTableHi,x
	sta SID_V1_FREQ_2,y
	pullall
	rts

; input:
; - inst is instrument ref (1 based)
; - offset is current SID regs offset
SetInstrument:
	pushall

	lda inst
	cmp #SNARE
	beq TriggerSnare
	cmp #KICK
	beq TriggerKick
	cmp #HHC
	beq TriggerHihat
	cmp #HHO
	beq TriggerHihat
	jmp NotDrum

TriggerKick:
	lda #0
	db $2c
TriggerSnare:
	lda #1
	db $2c
TriggerHihat:
	lda #2
	sta drum_variant
	asl ; align drum data index (*4)
	asl
	tax
	lda channel
	sta kick_ch,x
	lda #0
	sta kick_pos,x
	sta ctl
	jmp ExitSetInstrument

NotDrum:
	; instrument index to zero-based and aligned to instrument data (4 bytes)
	dec inst
	asl inst
	asl inst
	ldx inst

	; set osc
	lda InstDataStart,x
	and #%11110000
	sta ctl
	; amplitude envelope ref
	lda InstDataStart,x
	and #%00001111
	; a env data is 2 bytes per entry
	asl
	tay
	lda AEnvDataStart,y
	sta ad
	iny
	lda AEnvDataStart,y
	sta sr

	inx
	lda InstDataStart,x
	inx
	lda InstDataStart,x
	inx
	lda InstDataStart,x
ExitSetInstrument:
	pullall
	rts
