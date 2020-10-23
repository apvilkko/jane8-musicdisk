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

vblanked = $7f
counter = $7e
buttons = $7d

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

SwapNibbles:
	asl
	adc #$80
	rol
	asl
	adc #$80
	rol
	rts

WaitFrame:
	pha
		lda vblanked
waitloop:
		cmp vblanked
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

	;jsr WaitFrame
	jsr SetPalette
	jsr LoadAttributes
	jsr ResetScroll
	jsr EnableScreen

	lda #$00
	sta counter
InfLoop:
	jsr ReadJoy

	lda #%00000001
	cmp buttons
	beq Right

	lda #%00000010
	cmp buttons
	beq Left

	lda vblanked
	and #$1f
	cmp #8
	beq Left

	jmp InfLoop

Left:
	lda #%10011111
	sta APU_PULSE1_VD

	lda #%11111101
	sta APU_PULSE1_FRQ

	lda #%11111000
	sta APU_PULSE1_LEN

	lda #%00000001
	sta APU_CTL_STATUS

	jsr WaitFrame
	jsr DisableScreen
	lda #>VRAM_PALETTE
	sta PPU_ADDR
	lda #<VRAM_PALETTE
	sta PPU_ADDR
	lda counter
	sta PPU_DATA
	inc counter
	jsr EnableScreen

	jmp InfLoop

Right:
	lda #%00000000
	sta APU_PULSE1_FRQ

	lda #%00000000
	sta APU_CTL_STATUS

	jmp InfLoop

ReadJoy:
    lda #$01
    sta JOY1
    sta buttons
    lsr a
    sta JOY1
joyloop:
    lda JOY1
    lsr a
    rol buttons
    bcc joyloop
    rts

Delay:
	ldx #$ff
delloop:
	dex
	bne delloop
	rts

; Vectors
	org $fffa
	dw NmiHandler
	dw Start
	dw IrqHandler
