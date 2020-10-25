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
