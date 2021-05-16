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
