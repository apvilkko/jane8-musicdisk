	org $bff0

;--------------------------------------------------
; ROM header
;--------------------------------------------------
	db "NES",$1a
	db $01 ; PRG ROM
	db $00 ; CHR ROM
	db %00000000 ; Flags 6
	db %00000000 ; Flags 7
	db 0 ; PRG RAM size
	db 0,0,0,0,0,0,0

;--------------------------------------------------
; Constants
;--------------------------------------------------
SUBCLIP_OFFSET = $20
END_STREAM = $ff
END_SEGMENT = $fe
REF_COMMAND = $f0
INSTR_TYPE = $fc
TYPE_SQU = 2
TYPE_TRI = 3
TYPE_BD = 4
SIZE_OF_CLIP = 8
REPEATS_OFFSET = 4

;--------------------------------------------------
; Zero page variables
;--------------------------------------------------
vblanked = $7f
counter = $7e
buttons = $7d
dataptr = $7b
seqcount = $7a
tempo = $79
tempo4 = $78
temp = $77
tempIndex = $80
offset = $76
flags = $75
flags2 = $74
temp2 = $73
seqstep = $72
trackPtr = $70
clipFlags = $6f
segmentStart = $60
clipStart = $40
subclipStart = clipStart - SUBCLIP_OFFSET
z_l = $10
z_h = $11
z_b = $12
z_c = $13
z_d = $14
z_e = $15
z_bc = z_b
z_lh = z_l
z_de = z_d

;--------------------------------------------------
; NES registers etc.
;--------------------------------------------------
	include "defs.asm"

;--------------------------------------------------
; Palette etc.
;--------------------------------------------------
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

;--------------------------------------------------
; Music track data
;--------------------------------------------------
	include "trackdata.asm"

trackstart = cytrack

;--------------------------------------------------
; Includes
;--------------------------------------------------

	include "macros.asm"
	include "video.asm"
	include "sound.asm"
	include "input.asm"

;--------------------------------------------------
; Interrupt handlers
;--------------------------------------------------

NmiHandler:
	php
		inc vblanked
	plp
IrqHandler:
	rti

;--------------------------------------------------
; Subroutines
;--------------------------------------------------

ResetTrackPtr:
	store16 trackstart,trackPtr
	rts

ClearZeroPage:
	lda #0
	ldy #$ff
	sta temp
czloop:
	sta (temp),y
	dey
	bne czloop
	rts

;--------------------------------------------------
; Program start
;--------------------------------------------------

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
	jsr ClearZeroPage

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
	sta seqstep

	lda #%00001111
	sta APU_CTL_STATUS

	jsr ResetTrackPtr

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
	ldy seqstep
	iny
	sty seqstep
	lda vblanked
	sta seqcount

AdvanceTrack:
	lda #0
	sta flags
	sta flags2

	; Process subclips
	lda #subclipStart
	sta z_l

	ldy #0

SubClipLoop:
	tya
	pha
		jsr ProcessClip
	pla
	tay
	lda flags
	rol
	sta flags
	iny
	cpy #4
	bne SubClipLoop

	;flags should now contain 00001234 where 1 tells if first subclip played anything etc

	; Process clips
	lda #clipStart
	sta z_l

	; Loop clips from highest to lowest
	; clip 3 0001 subclip flag
	;      2 0010
	;      1 0100
	;      0 1000

	ldy #3
ClipLoop:
	tya
	sta tempIndex
	tax
	inx
	lda #%00010000
ShiftMore:
	lsr
	dex
	bne ShiftMore
	and flags
	bne SkipClip
	sty tempIndex
	tya
	pha
		jsr ProcessClip
	pla
	tay

	jmp StoreClipFlags
SkipClip:
	clc
StoreClipFlags:
	lda flags2
	rol
	sta flags2

	ldy clipFlags
	cpy #1
	bne ContinueClipLoop

	; clip triggered a subclip, start advancing it immediately
	ldy tempIndex
	lda #subclipStart
	sta z_l
	jsr ProcessClip
	lda #clipStart
	sta z_l

ContinueClipLoop:
	ldy tempIndex
	dey
	bpl ClipLoop

	ldy #0
	; advance segment if clips did not play
	lda flags2
	bne ContinueTrack
	jsr ProcessSegment

ContinueTrack:
	; if there's an active segment, don't advance
	lda segmentStart
	clc
	adc segmentStart+1
	beq NoActiveSegment
	jmp InfLoop
NoActiveSegment:
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
	jmp InfLoop
ResetTrack:
	jsr ResetTrackPtr
TrackFinished:
	jmp InfLoop

ProcessSegment:
	lda segmentStart
	clc
	adc segmentStart+1
	bne SegmentExists
	jmp SegmentFinished
SegmentExists:
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
	jmp ReturnFromSegment
ProcessClipRef:
	iny
	lda (segmentStart),y ; addr lo
	ldx offset
	sta clipStart,x
	inx
	inx
	sta clipStart,x ; copy at +2
	dex
	dex
	iny
	lda (segmentStart),y ; addr hi
	inx
	sta clipStart,x
	inx
	inx
	sta clipStart,x ; copy at +2
	iny
	lda (segmentStart),y ; total repeats
	inx
	sta clipStart,x
	lda #0 ; current repeats
	inx
	sta clipStart,x
	incptra segmentStart,4
IncreaseClipIndex:
	lda offset
	clc
	adc #SIZE_OF_CLIP
	sta offset
	jmp ContinueSegment
SegmentFinished:
	lda #0
	sta segmentStart
	sta segmentStart+1
ReturnFromSegment:
	rts

; Input:
; - Clip pointer in z_l
; - Subindex (offset) in A
; Post-conditions:
; - Clip pointer pointed by z_l is updated
; - Carry is set if clip advanced (played something)
ProcessClip:
	; multiply a (=index) by SIZE_OF_CLIP to get offset
	tax
	clc
	sta temp

	ldy #0
	sty clipFlags

	ldy #SIZE_OF_CLIP-1
AddMore:
	adc temp
	dey
	bne AddMore
	sta offset ; offset points to the clip data (of current index) position in zero page

	lda z_l
	sta z_b ; z_b is the original pointer (points to zero page where the address is)
	ldy offset
	lda (z_b),y
	sta z_d	; z_de is the pointer we advance (points to actual data)
	iny
	lda (z_b),y
	sta z_e
	dey


	; Check if current pointer is 0 => then do nothing
	lda z_d
	clc
	adc z_e
	bne ContinueClip
	jmp SkipRepeatCheck

ContinueClip:
	ldy #0
	lda (z_d),y
	cmp #REF_COMMAND
	beq ProcessClipSubRef
	cmp #INSTR_TYPE
	beq ReadType
	cmp #END_STREAM
	bne PlaySound
	jmp ClipFinished
ProcessClipSubRef:
	ldx offset
	iny
	lda (z_d),y ; addr lo
	sta subclipStart,x
	inx
	inx
	sta subclipStart,x
	iny
	lda (z_d),y ; addr hi
	dex
	sta subclipStart,x
	inx
	inx
	sta subclipStart,x
	iny
	lda (z_d),y ; total repeats
	inx
	sta subclipStart,x
	lda #0 ; current repeats
	inx
	sta subclipStart,x
	incptra z_d,4

	lda #1
	sta clipFlags

	jmp SubClipFinished
ReadType:
	iny
	lda (z_d),y
	sta temp ; instr data to temp

	; calculate the position of instr type data position, to y
	lda offset
	clc
	adc #6
	tay

	lda temp
	sta (z_b),y ; store clip instrument
	incptra z_d,2
	ldy #0
	jmp ContinueClip
PlaySound:
	pha
		lda offset
		clc
		adc #6
		tay
		lda (z_b),y ; read clip instrument
		tax
	pla
	ldy #0
	cpx #TYPE_TRI
	beq triangle
	cpx #TYPE_SQU
	beq square
	cpx #TYPE_BD
	beq kickdrum
	jmp noise
triangle:
	sta APU_TRI_LC
	iny
	lda (z_d),y
	sta APU_TRI_FRQ
	iny
	lda (z_d),y
	sta APU_TRI_LEN
	incptra z_d,3
	jmp PlayedSomething
square:
	sta APU_PULSE1_VD
	iny
	lda (z_d),y
	sta APU_PULSE1_SWP
	iny
	lda (z_d),y
	sta APU_PULSE1_FRQ
	iny
	lda (z_d),y
	sta APU_PULSE1_LEN
	incptra z_d,4
	jmp PlayedSomething
kickdrum:
	cmp #0
	beq EmptyNote
	lda #%10011111
	sta APU_PULSE2_VD
	lda #%10000010
	sta APU_PULSE2_SWP
	lda #%11111111
	sta APU_PULSE2_FRQ
	lda #%11111000
	sta APU_PULSE2_LEN
EmptyNote:
	incptra z_d,1
	jmp PlayedSomething
noise:
	cmp #0
	beq EmptyNoise
	sta APU_NOISE_VD
	iny
	lda (z_d),y
	sta APU_NOISE_FRQ
	iny
	lda (z_d),y
	sta APU_NOISE_LEN
EmptyNoise:
	incptra z_d,3
	jmp PlayedSomething
ClipFinished:
	sty temp2

	; check for repeat
	lda offset
	clc
	adc #REPEATS_OFFSET
	tay
	lda (z_b),y
	sta temp ;  total repeats
	cmp #0
	beq SkipRepeatCheck
	iny
	lda (z_b),y ; current repeats
	; add this round
	clc
	adc #1
	sta (z_b),y ; store the new current repeats
	cmp temp
	beq OkToClearClip
	; reset clip ptr
	dey
	dey
	lda (z_b),y ; orig addr hi
	dey
	dey ; to addr hi
	sta (z_b),y
	iny
	lda (z_b),y ; orig addr lo
	dey
	dey ; to addr lo
	sta (z_b),y

	ldx #0
	jmp SetPlayedFlag

SkipRepeatCheck:
	ldx #0
	jmp RestorePointer

OkToClearClip:
	ldy temp2

	ldx #2
	lda #0
ClearMore:
	sta z_d,y
	iny
	dex
	bne ClearMore
	; x should be 0
	jmp RestorePointer
PlayedSomething:
	ldx #1
	; check for stream end
	ldy #0
	lda (z_d),y
	cmp #END_STREAM
	bne RestorePointer
	jmp ClipFinished
SubClipFinished:
	ldx #0
RestorePointer:
	; z_de holds now the updated address
	ldy offset
	lda z_d
	sta (z_b),y
	lda z_e
	iny
	sta (z_b),y
SetPlayedFlag:
	cpx #0
	bne WasNotFinished
	jmp WasFinished
WasNotFinished:
	sec
	jmp ReturnFromClip
WasFinished:
	clc
ReturnFromClip:
	rts

SwitchColor:
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

;--------------------------------------------------
; Vectors
;--------------------------------------------------
	org $fffa
	dw NmiHandler
	dw Start
	dw IrqHandler
