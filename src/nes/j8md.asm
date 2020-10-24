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

; Zero page variables
vblanked = $7f
counter = $7e
buttons = $7d
dataptr = $7b
seqcount = $7a
tempo = $79
tempo4 = $78
temp = $77
offset = $76
offset2 = $75
trackPtr = $70
segmentStart = $60
clipStart = $40
subclipStart = $20

; constants
END_STREAM = $ff
END_SEGMENT = $fe
REF_COMMAND = $f0
INSTR_TYPE = $fc
TYPE_SQU = 2
TYPE_TRI = 3

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

trackstart = cytrack
datastart = cylead1

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

	macro incptr, ptr
		clc
		adc \1
		sta \1
		lda \1+1
		adc #0
		sta \1+1
	endmacro

	macro incptra, ptr, amount
		lda #\2
		incptr \1
	endmacro

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

	macro store16, src, dest
		lda #<\1
		sta \2
		lda #>\1
		sta \2+1
	endmacro

ResetTrackPtr:
	store16 trackstart,trackPtr
	rts

ResetDataPtr:
;	store16 datastart,dataptr
;CheckType:
;	ldy #0
;	lda (dataptr),y
	;cmp #$fc
	;beq ReadType
	;rts
;ReadType:
	;iny
	;lda (dataptr),y
	;sta tracktype
	;lda #2
	;jsr IncPtr
	rts

	include "sound.asm"

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

	lda #%00001111
	sta APU_CTL_STATUS

	jsr ResetTrackPtr
	;jsr ResetDataPtr

	; TODO read tempo
	lda #34
	sta tempo

	; Trigger by 16th note.
	; Dividing tempo on integer logic results in approximate higher tempos (>120 bpm).
	lsr ; divide by 4
	lsr
	sta tempo4

InfLoop:
	;jsr ReadJoy

	;lda #%00000001
	;cmp buttons
	;beq Right

	;lda #%00000010
	;cmp buttons
	;beq PlayNextItem

	lda seqcount
	adc tempo4
	cmp vblanked
	beq SeqTrigger

	jmp InfLoop

SeqTrigger:
	lda vblanked
	sta seqcount
AdvanceTrack:
	lda #0
	jsr ProcessClip
	lda #1
	jsr ProcessClip
	lda #2
	jsr ProcessClip
	lda #3
	jsr ProcessClip
	ldy #0
	jsr ProcessSegment
	lda (trackPtr),y
	cmp #REF_COMMAND
	beq ProcessRef
	cmp #END_STREAM
	beq ResetTrack
	jmp ResetTrack
ProcessRef:
	iny
	lda (trackPtr),y
	sta segmentStart
	iny
	lda (trackPtr),y
	sta segmentStart+1
	iny
	lda (trackPtr),y
	sta segmentStart+2
	lda #0
	sta segmentStart+3
	incptra trackPtr,4
	jsr ProcessSegment
	jmp AdvanceTrack
ResetTrack:
	jsr ResetTrackPtr
TrackFinished:
	jmp InfLoop

ProcessSegment:
	lda segmentStart
	clc
	adc segmentStart+1
	bne CheckOk
	jmp SegmentFinished
CheckOk:
	lda #0
	sta offset
ContinueSegment:
	ldy #0
	lda (segmentStart),y
	cmp #REF_COMMAND
	beq ProcessClipRef
	cmp #END_SEGMENT
	beq NewSegmentItem
	;cmp #END_STREAM
	;beq SegmentFinished
	jmp SegmentFinished
NewSegmentItem:
	incptra segmentStart,1
	jmp ContinueSegment
ProcessClipRef:
	iny
	lda (segmentStart),y
	ldx offset
	sta clipStart,x
	iny
	lda (segmentStart),y
	inx
	sta clipStart,x
	iny
	lda (segmentStart),y
	inx
	sta clipStart,x
	lda #0
	inx
	sta clipStart,x
	incptra segmentStart,4
	lda offset
	clc
	adc #5
	sta offset
	jmp ContinueSegment
SegmentFinished:
	lda #0
	sta segmentStart
	sta segmentStart+1
	rts

ProcessClip:
	; multiply a (=index) by 5 to get offset
	tax
	clc
	sta temp
	adc temp
	adc temp
	adc temp
	adc temp
	sta offset
	ldy offset
	lda clipStart
	clc
	adc clipStart+1
	bne ContinueClip
	jmp ClipFinished
ContinueClip:
	ldy offset
	lda (clipStart),y
	cmp #REF_COMMAND
	beq ProcessClipSubRef
	cmp #INSTR_TYPE
	beq ReadType
	cmp #END_STREAM
	beq ClipFinished
	jmp PlaySound
ProcessClipSubRef:
	iny
	lda (clipStart),y
	ldx offset2
	sta subclipStart,x
	iny
	lda (clipStart),y
	inx
	sta subclipStart,x
	iny
	lda (clipStart),y
	inx
	sta subclipStart,x
	lda #0
	inx
	sta subclipStart,x
	incptra clipStart,4
	jmp ContinueClip
ReadType:
	iny
	lda offset
	clc
	adc #4
	tax
	lda (clipStart),y
	sta clipStart,x
	incptra clipStart,2
	ldy #0
	jmp ContinueClip
PlaySound:
	iny
	iny
	iny
	iny
	ldx clipStart,y
	cpx #TYPE_TRI
	beq triangle
	cpx #TYPE_SQU
	beq square
	jmp noise
triangle:
	ldy offset
	jsr PlayTriangle
	ldy #0
	jmp played
square:
	ldy offset
	jsr PlaySquare
	ldy #0
	jmp played
noise:
	ldy offset
	jsr PlayNoise
	ldy #0
	jmp played
played:
	jmp InfLoop
ClipFinished:
	lda #0
	sta clipStart,y
	iny
	sta clipStart,y
	rts

PlayNextItem:
	ldy #0
	lda (dataptr),y

	cmp #END_STREAM
	beq resetdata1
	jmp PlaySound1
resetdata1:
	jsr ResetDataPtr
	jmp PlayNextItem
PlaySound1:
	;ldx tracktype
	cpx #TYPE_TRI
	beq triangle1
	cpx #TYPE_SQU
	beq square1
	jmp noise1
triangle1:
	jsr PlayTriangle
	jmp AfterPlay
square1:
	jsr PlaySquare
	jmp AfterPlay
noise1:
	jsr PlayNoise
AfterPlay:

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
	;lda #%00000000
	;sta APU_PULSE1_FRQ
	;sta APU_TRI_FRQ

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
