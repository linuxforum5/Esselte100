	.area LEVEL (REL)

	.globl COPY_FROM,COPY_TO,COPY_FROM_TO_0
	.globl HELP_LINE_ON_SCREEN ; From config

HELP:	.str '<JKLI>  '
	; .byte 13,15,22,5 ; move
	.str ' <R>'
	.byte 5,19,20,1,18,20 ; Restart
	.str ' <N>'
	.byte 5,24,20 ; Next
	.str ' <U>'
	.byte 14,4,15 ; Undo
	.byte 0 ; End of string

SHOW_HELP_LINE::
    LDX #HELP
    STX COPY_FROM
    LDX #HELP_LINE_ON_SCREEN
    STX COPY_TO
    JMP COPY_FROM_TO_0

