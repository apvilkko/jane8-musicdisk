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
TEMPO_COMMAND = $fb
TYPE_SQU = 2
TYPE_TRI = 3
TYPE_PERC = 4
TYPE_SQU2 = 5
SIZE_OF_CLIP = 8
REPEATS_OFFSET = 4
SUBCLIP_ENABLE_OFFSET = 7
MAX_OFFSET = SIZE_OF_CLIP * 4

CLIP_TYPE_TRACK = 0
CLIP_TYPE_SEGMENT = 1
CLIP_TYPE_CLIP = 2
CLIP_TYPE_SUBCLIP = 3

PERC_F_KICK = %00000001
PERC_F_CLAP = %00000010
PERC_F_HH = %00000100
PERC_F_HO = %00001000
PERC_F_VOL = %10000000

;--------------------------------------------------
; DPCM samples
;--------------------------------------------------

	org $fcc0
dpcmKick1:
	incbin "dpcm/kick3.dmc"
dpcmKick1End:
	db $00

	org $fec0
dpcmHh1:
	incbin "dpcm/hh1.dmc"
dpcmHh1End:
	db $00

; Sample address = %11AAAAAA.AA000000 = $C000 + (A * 64)
DMC_KICK1_ADDR = $f3 ; $fcc0
DMC_HH1_ADDR = $fb ; $fec0

Kick1Size = dpcmKick1End - dpcmKick1 - 1
Hh1Size = dpcmHh1End - dpcmHh1 - 1

;--------------------------------------------------
; Zero page variables
;--------------------------------------------------

vblanked = $7f
counter = $7e
buttons = $7d
temp = $7c
offset = $7b
seqcount = $7a
tempo = $79
tempo4 = $78
temp2 = $08
seqstep = $09
resetFlag = $0a
clipType = $0b
tickRef = $0e
pwm2 = $0f
frq2 = $0d

trackStart = $70
segmentStart = trackStart - SUBCLIP_OFFSET
clipStart = segmentStart - SUBCLIP_OFFSET
subclipStart = clipStart - SUBCLIP_OFFSET

z_l = $00
z_h = $01
z_b = $02
z_c = $03
z_d = $04
z_e = $05
z_bc = z_b
z_lh = z_l
z_de = z_d

	org $c000

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
	store16 sutrack,trackStart
	store16 sutrack,trackStart+2
	rts

ClearZeroPage:
	lda #0
	ldy #$ff
czloop:
	sta $00,y
	dey
	bne czloop
	rts

DoPwm:
	lda pwm2
	beq SkipPwm
	and #%01000000
	beq XorWithOne
	lda #%11000000
	db $2c
XorWithOne:
	lda #%01000000
	eor pwm2
	sta APU_PULSE2_VD
	sta pwm2
SkipPwm:
	rts

DoVibrato:
	lda frq2
	beq SkipVibrato
	eor #%00000010
	sta APU_PULSE2_FRQ
	sta frq2
SkipVibrato:
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
	lda #$ff
	sta seqstep
	sta seqcount

	lda #%00001111
	sta APU_CTL_STATUS

	jsr ResetTrackPtr

InfLoop:
	;jsr ReadJoy

	;lda #%00000001
	;cmp buttons
	;beq Right

	;lda #%00000010
	;cmp buttons
	;beq PlayNextItem

	lda seqcount
	; no clc!
	adc tempo4
	cmp vblanked
	beq SeqTrigger

	lda vblanked
	lsr
	lsr
	lsr
	cmp tickRef
	bne SubTickProcess
	sta tickRef
	jmp InfLoop
SubTickProcess:
	sta tickRef
	jsr DoVibrato

	jmp InfLoop

SeqTrigger:
	inc seqstep
	lda seqstep
	and #1
	beq PerformPwm
	jmp SkipPerformPwm
PerformPwm:
	jsr DoPwm
SkipPerformPwm:
	lda vblanked
	sta seqcount

ProcessFromTrack:
	lda #CLIP_TYPE_TRACK
	sta clipType
	lda #trackStart
	sta z_l
	lda #0
	jsr ProcessClip

ProcessFromSegment:
	lda #CLIP_TYPE_SEGMENT
	sta clipType
	lda #segmentStart
	sta z_l
	lda #0
	jsr ProcessClip

	lda resetFlag
	cmp #1
	beq ProcessFromTrack

	; Process clips
	lda #CLIP_TYPE_CLIP
	sta clipType
	lda #clipStart
	sta z_l
	ldy #3
ProcessClipLoop:
	tya
	pha
		jsr ProcessClip
	pla
	tay
	dey
	bpl ProcessClipLoop

	jsr DoZeroCheck

	lda temp
	bne ProcessSubClips

	lda #segmentStart
	sta z_l
	ldy #SUBCLIP_ENABLE_OFFSET
	lda #0
	sta (z_l),y
	jmp ProcessFromSegment

ProcessSubClips:
	ldy #3
ProcessSubClipLoop:
	lda #CLIP_TYPE_SUBCLIP
	sta clipType
	lda #subclipStart
	sta z_l

	tya
	pha
		jsr ProcessClip
	pla
	tay

	ldx resetFlag
	cpx #1
	bne ContinueSubClipLoop

	; advance the corresponding clip if reset flag was set
	lda #CLIP_TYPE_CLIP
	sta clipType
	lda #clipStart
	sta z_l

	tya
	pha
		jsr ProcessClip
	pla
	tay

	ldx resetFlag
	cpx #2
	beq ProcessSubClipLoop
	; clip activated ref, process the same index subclip once again

	; do zero check
	jsr DoZeroCheck
	lda temp
	beq ProcessFromSegment

ContinueSubClipLoop:
	dey
	bpl ProcessSubClipLoop

	jmp InfLoop

; Input:
; - Clip pointer in z_l
; - Subindex (offset) in A
; - clipType should be 0=track,1=segment,2=clip,3=subclip
; Post-conditions:
; - Clip pointer pointed by z_l is updated
ProcessClip:
	; multiply a (=index) by SIZE_OF_CLIP to get offset
	tax
	sta temp
	pha
		lda z_l
		sec
		sbc #SUBCLIP_OFFSET
		sta temp2 ; temp2 is the subclip zero page offset
	pla
	clc

	ldy #0
	sty resetFlag

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

	; Read subclip enable status
	tya
	clc
	adc #6
	tay
	lda (z_b),y

	; if current pointer is 0 or subclip is enabled => do nothing
	bne DontProcess
	lda z_d
	ora z_e
	beq DontProcess
	jmp ContinueClip
DontProcess:
	rts

ContinueClip:
	ldy #0
	lda (z_d),y
	cmp #REF_COMMAND
	beq ProcessClipSubRef
	cmp #INSTR_TYPE
	beq JmpReadType
	cmp #END_SEGMENT
	beq JmpNewSegmentItem
	cmp #END_STREAM
	beq JmpClipFinished
	cmp #TEMPO_COMMAND
	beq StoreTempo
	jmp PlaySound
JmpReadType:
	jmp ReadType
JmpNewSegmentItem:
	jmp NewSegmentItem
JmpClipFinished:
	jmp ClipFinished
StoreTempo:
	iny
	lda (z_d),y
	sta tempo
	; Trigger by 16th note.
	; Dividing tempo on integer logic results in approximate higher tempos (>120 bpm).
	lsr ; divide by 4
	lsr
	sta tempo4
	incptra z_d,2
	jmp ContinueClip
ProcessClipSubRef:
	lda offset
	clc
	adc temp2
	tax
	iny
	lda (z_d),y ; addr lo
	sta $00,x
	inx
	inx
	sta $00,x
	iny
	lda (z_d),y ; addr hi
	dex
	sta $00,x
	inx
	inx
	sta $00,x
	iny
	lda (z_d),y ; total repeats
	inx
	sta $00,x
	lda #0 ; current repeats
	inx
	sta $00,x

	; set subclip enable (2 + subclip offset)
	txa
	clc
	adc #$22
	tax
	lda #1
	sta $00,x

	incptra z_d,4

	; for segment, increase clip index
	lda clipType
	cmp #CLIP_TYPE_SEGMENT
	beq IncreaseClipIndex

	; set flag to indicate that ref added
	ldy #2
	sty resetFlag

	jmp UpdatePointerAndExit

IncreaseClipIndex:
	; update segment pointer first
	jsr UpdatePointer

	; check if there's following data before increasing
	ldy #0
	lda (z_d),y
	cmp #END_SEGMENT
	beq SkipIncreaseIndex

	lda offset
	clc
	adc #SIZE_OF_CLIP
	cmp #MAX_OFFSET
	beq SetZeroIndex
	db $2c
SetZeroIndex:
	lda #0
	sta offset
SkipIncreaseIndex:
	; for segment we'll continue processing
	jmp ContinueClip

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

NewSegmentItem:
	incptra z_d,1
	jmp UpdatePointerAndExit

PlaySound:
	pha
		lda offset
		clc
		adc #6
		tay
		lda (z_b),y ; read clip instrument
		and #%00000111 ; bottom 3 bits are instrument type
		tax
		lda (z_b),y
		and #%11111000 ; top 5 bits are tempo divisor
		lsr
		lsr
		lsr
		tay
		lda seqstep
		cpy #1
		beq FullNote
		cpy #4
		beq Quarter
		jmp Play16
Quarter:
		and #%00000011 ; modulo 4
		beq Play16
		pla
		jmp ExitWithoutUpdating
FullNote:
		and #%00001111 ; modulo 16
		beq Play16
		pla
		jmp ExitWithoutUpdating
Play16:
	pla
	ldy #0
	cpx #TYPE_TRI
	beq triangle
	cpx #TYPE_SQU
	beq square
	cpx #TYPE_SQU2
	beq square2
	cpx #TYPE_PERC
	beq perc
	jmp noise
triangle:
	cmp #0
	beq EmptyTriangle
	sta APU_TRI_LC
	iny
	lda (z_d),y
	sta APU_TRI_FRQ
	iny
	lda (z_d),y
	sta APU_TRI_LEN
EmptyTriangle:
	incptra z_d,3
	jmp UpdatePointerAndExit
square:
	cmp #0
	beq EmptySquare
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
	jmp EmptySquare
square2:
	cmp #0
	beq EmptySquare
	sta APU_PULSE2_VD
	sta pwm2
	iny
	lda (z_d),y
	sta APU_PULSE2_SWP
	iny
	lda (z_d),y
	sta APU_PULSE2_FRQ
	sta frq2
	iny
	lda (z_d),y
	sta APU_PULSE2_LEN
EmptySquare:
	incptra z_d,4
	jmp UpdatePointerAndExit
perc:
	cmp #0
	beq EmptyNote

	tax
	and #PERC_F_KICK
	beq SkipKick
PlayKick:
	lda #$0f
	sta APU_DMC_FR

	; Sample address = %11AAAAAA.AA000000 = $C000 + (A * 64)
	lda #DMC_KICK1_ADDR
	sta APU_DMC_ADDR

	; DMC LEN should be (sampleLen - 1) / 16
	; hHlL => Hl
	; optimize later: this calculation could be done only once per sample
	lda #<Kick1Size
	lsr
	lsr
	lsr
	lsr
	sta temp
	lda #>Kick1Size
	asl
	asl
	asl
	asl
	ora temp
	sta APU_DMC_LEN

	; trigger dmc with enable bit
	lda #%00011111
	sta APU_CTL_STATUS

SkipKick:
	txa
	and #PERC_F_CLAP
	beq SkipClap
PlayClap:
	txa
	and #PERC_F_VOL
	beq NormalVolume
	lda #$16
	db $2c
NormalVolume:
	lda #$1f
	sta APU_NOISE_VD
	lda #2
	sta APU_NOISE_FRQ
	lda #0
	sta APU_NOISE_LEN

	;lda #%10011111
	;sta APU_PULSE2_VD
	;lda #%10000010
	;sta APU_PULSE2_SWP
	;lda #%11111111
	;sta APU_PULSE2_FRQ
	;lda #%11111000
	;sta APU_PULSE2_LEN
SkipClap:
	txa
	and #PERC_F_HH
	beq SkipHh
PlayHh:
	lda #$0f
	sta APU_DMC_FR

	; Sample address = %11AAAAAA.AA000000 = $C000 + (A * 64)
	lda #DMC_HH1_ADDR
	sta APU_DMC_ADDR

	; DMC LEN should be (sampleLen - 1) / 16
	; hHlL => Hl
	; optimize later: this calculation could be done only once per sample
	lda #<Hh1Size
	lsr
	lsr
	lsr
	lsr
	sta temp
	lda #>Hh1Size
	asl
	asl
	asl
	asl
	ora temp
	sta APU_DMC_LEN

	; trigger dmc with enable bit
	lda #%00011111
	sta APU_CTL_STATUS
SkipHh:
	txa
	and #PERC_F_HO
	beq SkipHo
PlayHo:
	lda #$1c
	sta APU_NOISE_VD
	lda #2
	sta APU_NOISE_FRQ
	lda #0
	sta APU_NOISE_LEN
SkipHo:
EmptyNote:
	incptra z_d,1
	jmp UpdatePointerAndExit
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
	jmp UpdatePointerAndExit

ClipFinished:
	; check for repeat
	lda offset
	clc
	adc #REPEATS_OFFSET
	tay
	lda (z_b),y
	iny

	; for track, loop always
	ldx clipType
	cpx #CLIP_TYPE_TRACK
	beq ResetTrackPointer

	sta temp ;  total repeats
	cmp #0
	beq OkToClearClip
	lda (z_b),y ; current repeats
	; add this round
	clc
	adc #1
	sta (z_b),y ; store the new current repeats
	cmp temp
	beq OkToClearClip

ResetTrackPointer:
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

	; update current pointer position in the loop
	ldy offset
	lda (z_b),y
	sta z_d
	iny
	lda (z_b),y
	sta z_e

	; read more after resetting
	ldy #0
	jmp ContinueClip

OkToClearClip:
	lda offset
	tay
	lda #0
	ldx #2

ClearMore:
	sta (z_b),y
	iny
	dex
	bne ClearMore

	; reset parent subclip enable bit, if case of subclip or segment

	lda clipType
	cmp #CLIP_TYPE_CLIP
	beq SkipResetSubclipFlag
	cmp #CLIP_TYPE_TRACK
	beq SkipResetSubclipFlag

	tya
	clc
	adc #$25 ; 7 + subclip offset - 2
	tay
	lda #0
	sta (z_b),y ; x should be 0

SkipResetSubclipFlag:
	; set flag to indicate that clip ended
	ldy #1
	sty resetFlag

	rts

UpdatePointerAndExit:
	jsr UpdatePointer
ExitWithoutUpdating:
	rts

UpdatePointer:
	; z_de holds now the updated address
	lda clipType
	cmp #CLIP_TYPE_SEGMENT
	bne UseNormalOffset
	ldy #0 ; offset 0 for segment
	db $2c
UseNormalOffset:
	ldy offset
	lda z_d
	sta (z_b),y
	lda z_e
	iny
	sta (z_b),y
	rts

DoZeroCheck:
	; check if all clips are zero => reset segment subclip enable bit
	ldx #3
	lda #clipStart
	sta z_l
	lda #0
	sta temp
ZeroCheckLoop:
	lda temp
	ldy #0
	ora (z_l),y
	iny
	ora (z_l),y
	sta temp
	lda z_l
	clc
	adc #8
	sta z_l
	dex
	bpl ZeroCheckLoop
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
