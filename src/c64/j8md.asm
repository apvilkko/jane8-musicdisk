;================================
; LOADER
;================================

	org $07ff
	db $01,$08 ; prg header (BASIC program memory start $0801)

; BASIC loader
	db $0c,$08 ; pointer to next BASIC line
	db $0a,$00 ; line number (10)
	db $9e ; SYS token
	text "11904" ; program start in decimal
	db $00 ; end of basic line
	db $00,$00 ; end of program

	org $2e80

;================================
; DEFINITIONS
;================================

	include "defs.asm"

irqCount = $02
tickCount = $03
dataPosLo = $04
dataPosHi = $05
offset = $06
temp = $07
inst = $08
ctl = $09
noteCache = $f7

	macro print,val,pos
		pha
		lda \1
		and #%11110000
		lsr
		lsr
		lsr
		lsr
		clc
		adc #$30
		sta $0400+\2
		lda \1
		and #%00001111
		clc
		adc #$30
		sta $0401+\2
		pla
	endmacro

	macro inc16,val,label
		inc \1
		bne \2
		inc \1+1
	    \2:
	endmacro

	macro pushall
		pha
		txa
		pha
		tya
		pha
	endmacro

	macro pullall
		pla
		tay
		pla
		tax
		pla
	endmacro

;================================
; PROGRAM START
;================================

Start:
	jsr Init
	jsr ClearSid
	jmp Loop

Init:
	sei
	cld

	lda #%01111111
	sta INT_CTL_STA		; switch off interrupt signals from CIA-1

    and SCREEN_CTL_1	; clear most significant bit of VIC's raster register
    sta SCREEN_CTL_1

	lda INT_CTL_STA		; acknowledge pending interrupts
    lda INT_CTL_STA2

	lda #$20
	sta RASTER_LINE

	lda #<Isr		; set ISR vector
	sta ISR_LO
	lda #>Isr
	sta ISR_HI

    lda #$01
	sta INT_CTL		; enable raster interrupt

	lda #$00
	sta tickCount
	sta irqCount

	lda #<MusicDataStart
	sta dataPosLo
	lda #>MusicDataStart
	sta dataPosHi

	cli
	rts

ClearSid:
	ldx #$1d
	lda #$00
clearsidloop:
	sta SID_REGS
	dex
  	bne clearsidloop

	lda #%00001111 ; volume to max
  	sta SID_FLT_VM
	rts

Loop:
	jmp Loop

Isr:
	inc irqCount
	inc tickCount
	lda tickCount
	cmp #$08
	bne skipResetTick
	lda #$00
	sta tickCount
skipResetTick:

	print irqCount, 0
	print tickCount, 4

	jsr SoundDriver

	asl INT_STATUS	; acknowledge the interrupt by clearing the VIC's interrupt flag
	jmp $EA81

SoundDriver:
	lda tickCount
	beq continueSound
	jmp ExitSoundDriver
continueSound:
	ldx #$00
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
	; gate off
	lda #$00
	ldy offset
	sta SID_V1_CTL,y

	; set pulse width
	lda #$00
	sta SID_V1_PW_1,y
	lda #$04
	sta SID_V1_PW_2,y

	; play note
	lda #$06
  	sta SID_V1_AD,y

	lda #$00
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
	; instrument index to zero-based and aligned to instrument data (4 bytes)
	dec inst
	asl inst
	asl inst
	ldx inst

	; set osc
	lda InstDataStart,x
	sta ctl

	inx
	lda InstDataStart,x
	inx
	lda InstDataStart,x
	inx
	lda InstDataStart,x
	pullall
	rts

MusicDataStart:
	incbin "../../intermediate/0002.bin"
	db $ff

InstDataStart:
	incbin "../../intermediate/0002.inst.bin"
	db $ff

PitchTableLo:
	db 24,56,90,125,163,204,246,35,83,134,187,244
	db 48,112,180,251,71,152,237,71,167,12,119,233
	db 97,225,104,247,143,48,218,143,78,24,239,210
	db 195,195,209,239,31,96,181,30,156,49,223,165
	db 135,134,162,223,62,193,107,60,57,99,190,75
	db 15,12,69,191,125,131,214,121,115,199,124,151

PitchTableHi:
	db 2,2,2,2,2,2,2,3,3,3,3,3
	db 4,4,4,4,5,5,5,6,6,7,7,7
	db 8,8,9,9,10,11,11,12,13,14,14,15
	db 16,17,18,19,21,22,23,25,26,28,29,31
	db 33,35,37,39,42,44,47,50,53,56,59,63
	db 67,71,75,79,84,89,94,100,106,112,119,126
