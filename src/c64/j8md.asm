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
ad = $0a
sr = $0b
channel = $0c
drum_variant = $0d
temp2 = $0e
temp3 = $0f

kick_ch = $10
kick_pos = $11
kick_f_lo = $12
kick_f_hi = $13
snare_ch = $14
snare_pos = $15
sn_f_lo = $16
sn_f_hi = $17
hh_ch = $18
hh_pos = $19
reserved1 = $1a
reserved2 = $1b

temp4 = $1c
pwm1 = $1d ; -1e
pwm2 = $1f ; -20
pwm3 = $21 ; -22

noteCache = $f7

KICK = 1
SNARE = 5
HHC = 6
HHO = 7

	include "macros.asm"

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

	lda #$ff
	sta kick_ch
	sta kick_pos
	sta snare_ch
	sta snare_pos
	sta hh_ch
	sta hh_pos

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

;================================
; INTERRUPT
;================================

Isr:
	inc irqCount
	inc tickCount
	lda tickCount
	cmp #$08
	bne skipResetTick
	lda #$00
	sta tickCount
skipResetTick:
	;print irqCount, 0
	;print tickCount, 4
	print pwm1, 0
	print pwm1+1, 4

	jsr SoundDriver

	asl INT_STATUS	; acknowledge the interrupt by clearing the VIC's interrupt flag
	jmp $EA81

;================================

	include "frame.asm"
	include "driver.asm"
	include "data.asm"
