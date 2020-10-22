	org $bff0

; ROM header
	db "NES",$1a
	db $01 ; PRG ROM
	db $00 ; CHR ROM
	db %00000000 ; Flags 6
	db %00000000 ; Flags 7
	db 0 ; PRG RAM size
	db 0,0,0,0,0,0,0


	include "defs.asm"

Bit0 equ	LookupBits+0
Bit1 equ	LookupBits+1
Bit2 equ	LookupBits+2
Bit3 equ	LookupBits+3
Bit4 equ	LookupBits+4
Bit5 equ	LookupBits+5
Bit6 equ	LookupBits+6
Bit7 equ	LookupBits+7

LookupBits:
	db %00000001,%00000010,%00000100,%00001000,%00010000,%00100000,%01000000,%10000000

z_regs = $20
z_c = z_regs+2
z_b = z_regs+3

vblanked = $7f
counter = $7e

palette:
	db $0f,$0f,$0f,$0f, $0f,$0f,$0f,$0f, $0f,$0f,$0f,$0f, $0f,$0f,$0f,$0f
	db $06,$0f,$0f,$0f, $0f,$0f,$0f,$0f, $0f,$0f,$0f,$0f, $0f,$0f,$0f,$0f

attributes:
	db %00000000, %00000000, %00000000, %01001110, %00000000, %00000000, %00000000, %00000000
	db %11111111, %00011011, %01001110, %01001110, %00000000, %00000000, %00000000, %00000000
	db %00000000, %00000000, %00000000, %01001110, %00000000, %00000000, %00000000, %00000000
	db %00000000, %00000000, %00000000, %01001110, %00000000, %00000000, %00000000, %00000000
	db %00000000, %00000000, %00000000, %01001110, %00000000, %00000000, %00000000, %00000000
	db %00000000, %00000000, %00000000, %01001110, %00000000, %00000000, %00000000, %00000000
	db %00000000, %00000000, %00000000, %01001110, %00000000, %00000000, %00000000, %00000000
	db %00000000, %00000000, %00000000, %01001110, %00000000, %00000000, %00000000, %00000000

ClearPalette:
	lda #>VRAM_PALETTE
	sta PPU_ADDR
	lda #<VRAM_PALETTE
	sta PPU_ADDR
	lda #$0f ; black
	ldx #$20 ; loop 32 times
cploop:
	sta PPU_DATA
	dex
	bne cploop

ClearVRAM:
	lda #>VRAM_NAMETABLE
	sta PPU_ADDR
	lda #<VRAM_NAMETABLE
	sta PPU_ADDR
	ldy #$10 ; loop 16 * 256 times
cvloop:
	sta PPU_DATA
	inx
	bne cvloop
	dey
	bne cvloop

SetPalette:
	lda #>VRAM_PALETTE
	sta PPU_ADDR
	lda #<VRAM_PALETTE
	sta PPU_ADDR
	ldx #$00
	ldy #$20 ; loop 32 times
setpaletteloop:
	lda palette,x
	sta PPU_DATA
	inx
	dey
	bne setpaletteloop
	rts

LoadAttributes:
	lda PPU_STATUS
	lda #>PPU_ATTRIBUTES
	sta PPU_ADDR
	lda #<PPU_ATTRIBUTES
	sta PPU_ADDR
	ldx #$00
laloop:
	lda attributes,x
	sta PPU_DATA
	inx
	cpx #$40
	bne laloop
	rts

DisableScreen:
	lda #%00000000
	sta PPU_MASK
	sta PPU_CTRL
	rts

EnableScreen:
	lda #%00011000
	sta PPU_MASK
	lda #$80
	sta PPU_CTRL
	rts

NmiHandler:
	php
	inc vblanked
	plp
IrqHandler:
	rti

SwapNibbles:		;$AB -> $BA
	asl 		;(shift left - bottom bit zero)
	adc #$80 	;(pop top bit off - add carry)
	rol 		;(shift carry in)
	;2 bits moved
	asl 		;(shift left - bottom bit zero)
	adc #$80 	;(pop top bit off - add carry)
	rol 		;(shift carry in)
	;4 bits moved
	rts


DecBC:
	pha
		lda z_c
		bne DecBC_b
		dec z_c
DecBC_b:
		dec z_c
	pla
	rts



PlaySound:			;%NVPPPPPP	N=Noise  V=Volume  P=Pitch
	pha
		and #%01000000	;Volume bit
		lsr
		lsr
		lsr
		ora #%00110111	;CCLEVVVV - Fixed Volume, Disable Clock
		tax
	pla

	beq PlaySoundSilent

	bit Bit7			;Noise
	bne PlaySoundNoise

	stx APU_PULSE1_VD

	jsr SwapNibbles		;Swap Pitch Bits --FFffff to ffff--FF
	pha
		and #%00000011	;Top 2 bits
		ora #%11111000
		sta APU_PULSE1_LEN
	pla
	and #%11110000
	sta APU_PULSE1_FRQ

	lda #%00000001
PlaySoundSilent:			;A=0 for silent
	sta APU_CTL_STATUS
	rts

PlaySoundNoise:
	stx APU_NOISE_VD
	and #%00111100
	lsr
	lsr
	sta APU_NOISE_FRQ

	lda #%00001000	;DF-54321 - DMC/IRQ/length counter status/channel enable
					;We also use this for setting the bottom 3 bits of the noise H freq.
	sta APU_NOISE_LEN
	jmp PlaySoundSilent


WaitFrame:
	pha
		lda #$00
		sta vblanked
waitloop:
		lda vblanked
		beq waitloop
	pla
	rts

ResetScroll:
	lda #0
	sta PPU_SCROLL
	lda #0-8
	sta PPU_SCROLL
	rts

ClearAPU:
	lda #$00
	ldx #$00
caloop:
	sta APU_PULSE1_VD,x
	inx
	cpx $18
	bne caloop
	rts

Start:
	sei
	cld
	ldx $ff
	txs
	inx
	stx PPU_CTRL
	stx PPU_MASK

	bit PPU_STATUS

Wait1:
	bit PPU_STATUS
	bpl Wait1

	jsr ClearVRAM
	jsr ClearPalette
	jsr ClearAPU

Wait2:
	bit PPU_STATUS
	bpl Wait2

	jsr WaitFrame
	jsr SetPalette
	jsr LoadAttributes
	jsr ResetScroll
	jsr EnableScreen

	lda #$80

	lda #$00
	sta counter
InfLoop:
	;pha
	;	jsr PlaySound
	;	jsr Pause
	;pla
	;sec
	;sbc #1

	pha
		lda #%10011111
		sta APU_PULSE1_VD

		lda #%11111101
		sta APU_PULSE1_FRQ

		lda #%11111000
		sta APU_PULSE1_LEN
  	pla

	jsr WaitFrame
	lda #>VRAM_PALETTE
	sta PPU_ADDR
	lda #<VRAM_PALETTE
	sta PPU_ADDR
	lda counter
	sta PPU_DATA
	inc counter

	jsr Delay
	lda #%00000000
	sta APU_CTL_STATUS
	;jsr Pause
	jmp InfLoop

Delay:
	ldx #$ff
	dex
	bne Delay
	rts

Pause:
	lda #$50
	sta z_b
	lda #00
	sta z_c
DelayAgain2:
	jsr DecBC
	lda z_b
	ora z_c
	bne DelayAgain2
	rts

; Vectors
	org $fffa
	dw NmiHandler
	dw Start
	dw IrqHandler
