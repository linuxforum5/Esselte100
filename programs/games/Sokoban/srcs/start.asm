; http://www.8bit-era.cz/6800.html

    .area START ( REL )
    .globl ROM_CLS ; From io
    .globl SHOWKOBAN ; From toptext
    .globl STARTTEXT_FIRST_LINE_ON_SCREEN ; From config
    .globl WAIT_FOR_NO_KEY_PRESSED,CHECK_KEY_S_OR_FIRE_B_Z ; From control
    .globl COPY_FROM,COPY_TO,COPY_FROM_TO_0 ; From copy
    .globl ROM_RESET ; From ROM
    .globl AJOY_A_MEASURE_AB ; From ajoy

SHOW_START_SCREEN::
    JSR ROM_CLS
    JSR SHOWKOBAN
    ;;; COPYRIGHT
    LDX #COPYRIGHT
    STX COPY_FROM
    LDX #0xC3E3
    STX COPY_TO
    JSR COPY_FROM_TO_0
    ;;;
    LDX #MEMO
    STX COPY_FROM
    LDX #0xC3A0-64
    STX COPY_TO
    JSR COPY_FROM_TO_0

    LDX #START_SCR
    STX COPY_FROM
    LDX #STARTTEXT_FIRST_LINE_ON_SCREEN
    STX COPY_TO
    JSR COPY_FROM_TO_0

    ; Start szöveg kiírása
    LDX #STARTTEXT_FIRST_LINE_ON_SCREEN + 622-32 - 14 - 31 ; 590 ; 782 - 96 - 96 
    STX COPY_TO
    JSR COPY_FROM_TO_0

DETECT_JOY:
    LDX #STARTTEXT_FIRST_LINE_ON_SCREEN + 396
    STX COPY_TO
    JSR AJOY_A_MEASURE_AB
    LDX #JOY_NOT_FOUND_MSG
    CMPB #0
    BEQ WRITE_JOY_MSG                 ; Ha nem találunk joy-t akkor már írhatjuk is ki, hogy nincs
    ; Joy found
    LDX #JOY_FOUND_MSG                ; Különben módosítjuk arra a szöveget, hogy van
WRITE_JOY_MSG:
    STX COPY_FROM
    JSR COPY_FROM_TO_0
    JSR CHECK_KEY_S_OR_FIRE_B_Z
    BNE DETECT_JOY
    RTS

START_SCR:
	.str 'YOU HAVE TAKEN A PART-TIME JOB A'
	.str 'LARGE STORAGE COMPANY! YOUR TASK'
	.str 'IS TO ORGANISE 20 WAREHOUSES.   ' ;     MAXMAZENUMSTR 
	.str 'PLEASE ORGANISE THEM NEATLY. HO-'
	.str 'WEVER AS THE PACKAGES ARE LARGE,'
	.str 'YOU CAN ONLY PUSH ONE A TIME. IF'
	.str "YOU MESS, UP YOU WON'T BE ABLE  "
	.str 'TO MOVE THE PACKAGES!           '
	.str 'PLEASE BE CAREFUL.              '
	.str '                                '
	.str ' <J>'                           ; Left
	.byte 12,5,6,20
	.str '    <U>'                        ; Undo
	.byte 21,14,4,15,32,12,1,19,20,32,13,15,22,5
	.str '   '
	.str ' <L>'                           ; Right
	.byte 18,9,7,8,20
	.str '   <R>'                         ; Restart level
	.byte 18,5,19,20,1,18,20,32,12,5,22,5,12,32
	.str '   '
	.str ' <I>'                           ; Up
	.byte 21,16

;	.str '      <T>'
;	.byte 20,5,19,20,32,10,15,25,19,20,9,3,11 ; test joystick
;	.str '    '
	.str '                          '

	.str ' <K>'                           ; Down
	.byte 4,15,23,14
	.str '    S'
	.byte 15,21,14,4,32,15,14,32,20,1,16,5,32,15,21,20,16,21,20 ; Sound on the tape output
	.str '                                '
        .str 'PLEASE ORGANIZE THE BOXES TO THE'
        .strz 'OPEN SPACES WITH A DOT.'
	.byte    0xB7,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0xBE,0x87,' 
	.byte ' ,0xFE,16,18,5,19,19,' ,'<,'S,'>,' ,15,18,' ,'<,'F,'I,'R,'E,'>,' ,20,15,' ,'S,20,1,18,20,0xFE,' ; Press <S> or <FIRE> to Start
	.byte ' ,0xDF,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0xDD,0x97,0
;	.strz '< PRESS A KEY OR FIRE TO START >'

MEMO:	.str 'IN MEMORIAN H'
	.byte 9,18,15,25,21,11,9
	.str ' I'
	.byte 13,1,2,1,25,1,19,8,9
	.strz ' AND THE NEC PC 8800 (1981)'

COPYRIGHT: .byte 67,18,5,1,20,5,4,32,2,25,32,80,18,9,14,3,26,32,76,29,19,26,12,15,32,50,48,50,53,0 ; Created by Princz László 2025

JOY_NOT_FOUND_MSG:   .byte 'J,15,25,19,20,9,3,11,32,14,15,20,32,6,15,21,14,4,0 ; Joystick not found'
JOY_FOUND_MSG:       .strz 'JOYSTICK FOUND :) '
