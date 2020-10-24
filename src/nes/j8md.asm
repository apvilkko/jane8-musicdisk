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
dataptr = $7b
seqcount = $7a
tempo = $79
temp = $78

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

	include "trackdata.asm"

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

ResetDataPtr:
	lda #<cybass1
	sta dataptr
	lda #>cybass1
	sta dataptr+1
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

	jsr SetPalette
	jsr LoadAttributes
	jsr ResetScroll
	jsr EnableScreen

	lda #$00
	sta counter
	sta seqcount

	; TODO read tempo
	lda #34
	sta tempo

	lda #%00000111
	sta APU_CTL_STATUS

	jsr ResetDataPtr

InfLoop:
	jsr ReadJoy

	lda #%00000001
	cmp buttons
	beq Right

	lda #%00000010
	cmp buttons
	beq Left


	; Trigger by 16th note.
	; Dividing tempo on integer logic results in approximate higher tempos (>120 bpm).
	lda tempo
	lsr ; divide by 4
	lsr
	sta temp
	lda seqcount
	adc temp
	cmp vblanked
	beq SeqTrigger

	jmp InfLoop

SeqTrigger:
	lda vblanked
	sta seqcount
Left:
	;lda #%10011111
	;sta APU_PULSE1_VD
	;lda #%11111101
	;sta APU_PULSE1_FRQ
	;lda #%11111000
	;sta APU_PULSE1_LEN

	lda #%01000000
	sta APU_TRI_LC
	ldy #0
	lda (dataptr),y
	cmp #$ff
	beq resetdata1
	jmp skipreset1
resetdata1:
	jsr ResetDataPtr
	ldy #0
	lda (dataptr),y
skipreset1:
	sta APU_TRI_FRQ
	iny
	lda (dataptr),y
	sta APU_TRI_LEN
	iny

	inc dataptr
	inc dataptr

	jmp skipreset

resetdata:
	jsr ResetDataPtr
skipreset:

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
	;sta APU_PULSE1_FRQ
	sta APU_TRI_FRQ

	;lda #%00000000
	;sta APU_CTL_STATUS

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

; Vectors
	org $fffa
	dw NmiHandler
	dw Start
	dw IrqHandler
