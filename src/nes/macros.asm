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

	macro store16, src, dest
		lda #<\1
		sta \2
		lda #>\1
		sta \2+1
	endmacro

	; load (a) => z_lh
	macro load16
		sta z_b
		ldx #0
		lda (z_b,x)
		sta z_l
		inx
		lda (z_b,x)
		sta z_h
	endmacro
