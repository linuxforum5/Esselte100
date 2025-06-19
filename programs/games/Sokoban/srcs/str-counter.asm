; http://www.8bit-era.cz/6800.html
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Stringként tárolt decimális számokkal műveletek.
;;; Jellemzően a képernyőn látható számlálók
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .area MAIN ( REL )

CLEAR_COUNTER_LAST_X:: ; Törli, azaz csupa 0-ára állítja a számlálót, egészen a szóközig
    LDAA 0,X
    CMPA #0x20 ; Ez space?
    BEQ END_OF_CLEAR
    LDAA #48   ; A 0 karakter
    STAA 0,X
    DEX
    BRA CLEAR_COUNTER_LAST_X
END_OF_CLEAR:
    RTS

INC_COUNTER_LAST_X::
    LDAA 0,X
    INCA
    CMPA #0x3A ; A 9-es számjegy utáni karakter
    BNE INC_NO_OVERFLOW
    LDAA #48   ; A 0-ás számjegy
    STAA 0,X
    DEX
    BRA INC_COUNTER_LAST_X
INC_NO_OVERFLOW:
    STAA 0,X
    RTS

DEC_COUNTER_LAST_X::
    LDAA 0,X
    DECA
    CMPA #0x2F ; A 0-ás számjegy előtti karakter
    BNE DEC_NO_OVERFLOW
    LDAA #57   ; A 9-es számjegy
    STAA 0,X
    DEX
    BRA DEC_COUNTER_LAST_X
DEC_NO_OVERFLOW:
    STAA 0,X
    RTS
