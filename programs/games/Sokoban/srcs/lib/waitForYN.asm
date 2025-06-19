; Vezérlési modul, a billentyűzeten a lenyomott irányokat vizsgálja
; CONTROL_A : A regiszterbe bekerül a 4 irány és a tűz
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .area IO  ( REL )
    .globl CHK_KEY_N,CHK_KEY_Y,CONTROL_A,WAIT_FOR_NO_KEY_PRESSED ; From control
    .globl AJOY_A_FIRE ; From variables

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Y/N villogtatása az X memóriacímtől, és várakozás, míg az egyiket le nem üti. Z flag igaz, ha Y
;;; A-ba kerül a Y vagy a N
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WAIT_FOR_YN_X_A::
    JSR WAIT_FOR_NO_KEY_PRESSED
    LDAA AJOY_A_FIRE
    BNE FIRE_EQUAL_Y
WAIT_FOR_YN_X_A_SAFE:
    LDAA #'/ ; '
    STAA 1,X
    LDAA 0,X
    CMPA #'Y ; '
    BNE WAIT_SHOW_Y
WAIT_SHOW_N:
    LDAA #0x20
    LDAB #'N ;'
    STAA 0,X
    STAB 2,X
    JSR CHK_KEY_N
    BNE WAIT_FOR_YN_X_A_SAFE ; Z=0 amíg nincs lenyomva egyik válasz sem    BRA WAIT_SHOW
    LDAA #'N ; '
    RTS
WAIT_SHOW_Y:
    LDAA #'Y ;'
    LDAB #0x20
    STAA 0,X
    STAB 2,X
    JSR CHK_KEY_Y
    BNE WAIT_FOR_YN_X_A_SAFE ; Z=0 amíg nincs lenyomva egyik válasz sem
FIRE_EQUAL_Y:
    LDAA #'Y ; '
    RTS
