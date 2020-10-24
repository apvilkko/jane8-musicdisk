cytempo:
	db $69
cybass1:
	db $bf,$0b,$df,$09,$bf,$0b,$bf,$0b,$bf,$0b,$df,$09,$bf,$0b,$bf,$0b,$df,$09,$bf,$0b,$df,$09,$bf,$0b,$df,$09,$df,$09,$bf,$0b,$ef,$08,$ff
cybd1:
	db $ad,$0e,$00,$00,$00,$00,$00,$00,$ad,$0e,$00,$00,$00,$00,$00,$00,$ad,$0e,$00,$00,$00,$00,$00,$00,$ad,$0e,$00,$00,$00,$00,$00,$00,$ff
cybd2:
	db $f0,<cybd1,>cybd1,$03,$ad,$0e,$00,$00,$00,$00,$00,$00,$ad,$0e,$00,$00,$00,$00,$00,$00,$ad,$0e,$00,$00,$00,$00,$00,$00,$ad,$0e,$ad,$0e,$ad,$0e,$00,$00,$ff
cyintro:
	db $f0,<cybass1,>cybass1,$04,$f0,<cybd2,>cybd2,$01,$fe,$ff
cytrack:
	db $f0,<cyintro,>cyintro,$01,$ff
