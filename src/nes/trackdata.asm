cytempo:
	db $69
cybass11:
	db $fc,$03,$7f,$bf,$83,$7f,$df,$81,$7f,$bf,$83,$7f,$bf,$83,$7f,$bf,$83,$7f,$df,$81,$7f,$bf,$83,$7f,$bf,$83,$7f,$df,$81,$7f,$bf,$83,$7f,$df,$81,$7f,$bf,$83,$7f,$df,$81,$7f,$df,$81,$7f,$bf,$83,$7f,$ef,$80,$ff
cybass12:
	db $fc,$03,$7f,$bf,$83,$7f,$df,$81,$7f,$bf,$83,$7f,$bf,$83,$7f,$bf,$83,$7f,$df,$81,$7f,$bf,$83,$7f,$bf,$83,$7f,$1a,$82,$7f,$bf,$83,$7f,$1a,$82,$7f,$bf,$83,$7f,$93,$81,$7f,$93,$81,$7f,$bf,$83,$7f,$ef,$80,$ff
cybass1:
	db $fc,$03,$f0,<cybass11,>cybass11,$07,$f0,<cybass12,>cybass12,$01,$ff
cylead1:
	db $fc,$02,$9f,$00,$df,$81,$00,$00,$00,$00,$9f,$00,$0c,$81,$94,$00,$df,$81,$9f,$00,$3f,$81,$94,$00,$0c,$81,$9f,$00,$c9,$80,$9f,$00,$d5,$80,$92,$00,$3f,$81,$9f,$00,$0c,$81,$9f,$00,$ef,$80,$92,$00,$d5,$80,$94,$00,$0c,$81,$92,$00,$0c,$81,$9f,$00,$3f,$81,$00,$00,$00,$00,$00,$00,$00,$00,$94,$00,$3f,$81,$92,$00,$3f,$81,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$ff
cystring1:
	db $fc,$02,$4f,$00,$3f,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$96,$00,$3f,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$d4,$00,$3f,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$13,$00,$3f,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$4f,$00,$d5,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$96,$00,$d5,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$d4,$00,$d5,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$13,$00,$d5,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$4f,$00,$0c,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$96,$00,$0c,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$d4,$00,$0c,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$13,$00,$0c,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$4f,$00,$ef,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$96,$00,$ef,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$d4,$00,$ef,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$13,$00,$ef,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$4f,$00,$3f,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$96,$00,$3f,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$d4,$00,$3f,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$13,$00,$3f,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$4f,$00,$ef,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$96,$00,$ef,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$d4,$00,$ef,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$13,$00,$ef,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$4f,$00,$9f,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$96,$00,$9f,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$d4,$00,$9f,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$13,$00,$9f,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$4f,$00,$d5,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$96,$00,$d5,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$d4,$00,$d5,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$13,$00,$d5,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$ff
cybd1:
	db $fc,$04,$86,$00,$00,$00,$86,$00,$00,$00,$86,$00,$00,$00,$86,$00,$00,$00,$ff
cybd2:
	db $fc,$04,$f0,<cybd1,>cybd1,$07,$86,$00,$00,$00,$86,$00,$00,$00,$86,$00,$00,$00,$86,$86,$86,$00,$ff
cyclap:
	db $fc,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$1a,$05,$00,$00,$00,$00,$00,$00,$00,$14,$05,$00,$ff
cyintro:
	db $f0,<cybass1,>cybass1,$01,$f0,<cybd2,>cybd2,$01,$fe,$ff
cyintro2:
	db $f0,<cybass1,>cybass1,$01,$f0,<cybd2,>cybd2,$01,$f0,<cystring1,>cystring1,$01,$fe,$ff
cymel1:
	db $f0,<cybass1,>cybass1,$01,$f0,<cybd2,>cybd2,$01,$f0,<cyclap,>cyclap,$10,$f0,<cylead1,>cylead1,$04,$fe,$ff
cytrack:
	db $f0,<cyintro,>cyintro,$01,$f0,<cyintro2,>cyintro2,$01,$f0,<cymel1,>cymel1,$01,$ff
