; Bájtmásoló module
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .area COPY  ( REL )

    .globl COPY_FROM, COPY_TO ; From variables

COPY_FROM_TO_0::
    LDX COPY_FROM
    LDAA 0,X
    BEQ 9$
    INX
    STX COPY_FROM
    LDX COPY_TO
    STAA 0,X
    INX
    STX COPY_TO
    BRA COPY_FROM_TO_0
9$: LDX COPY_FROM
    INX
    STX COPY_FROM
    LDX COPY_TO
    RTS
