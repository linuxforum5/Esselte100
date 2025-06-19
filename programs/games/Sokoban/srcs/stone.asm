; http://www.8bit-era.cz/6800.html

    .area MAIN ( REL )
    .globl SPACE_CHR,STONE_CHR,PLACE_CHR,STONE_ON_PLACE_CHR,PUSH_COUNTER_LAST_POSITION,PLACED_COUNTER_LAST_POSITION,PLACED_COUNTER,PLACE_COUNTER
    .globl LEVEL_FINISHED
    .globl STONE_TO_PLACE_EFFECT, STONE_FROM_PLACE_EFFECT ; From sound-effects
    .globl INC_COUNTER_LAST_X,DEC_COUNTER_LAST_X ; From str-counter
    .globl UNDER_STONE,TMP,STONE_NEXT_POS,STONE_LAST_CHR ; From variables

STONE_LEFT_X_A_B::    ; X a kő címe, B ami a kő alatt van
    STAB UNDER_STONE  ; Ez van a kő alatt
    DEX             ; MOVE LEFT
    LDAA 0,X
    STAA STONE_LAST_CHR ; Elmentjük az undo számára ;;; undo
    STX STONE_NEXT_POS  ; Elmentjük az undo számára ;;; undo
    LDAB #STONE_CHR  ; Ez lesz az új kő
    CMPA #SPACE_CHR ; IS SPACE?
    BEQ L2          ; Mehet
    LDAB #STONE_ON_PLACE_CHR  ; Ez lesz az új kő
    CMPA #PLACE_CHR ; Kőhely
    BEQ L2          ; Mehet
    INX
    RTS
L2: STAB 0,X
    INX
    LDAA UNDER_STONE
    STAA 0,X
    JMP CHANGE_PUSH_COUNTER_IF_NEED_A_B   ; B-ben az új kő, A-ban a kő alatti karakter
    ; RTS

STONE_RIGHT_X_A_B::   ; X+1 a kő címe, B ami a kő alatt van: SPACE_CHR vagy PLACE_CHR
    STAB UNDER_STONE  ; Ez van a kő alatt
    INX             ; MOVE RIGHT
    INX
    STX STONE_NEXT_POS  ; Elmentjük az undo számára ;;; undo
    DEX
    LDAA 1,X            ; A-ban a kő új helye alatti kód
    STAA STONE_LAST_CHR ; Elmentjük az undo számára ;;; undo
    LDAB #STONE_CHR  ; Ez lesz az új kő
    CMPA #SPACE_CHR ; IS SPACE?
    BEQ 1$          ; Mehet
    LDAB #STONE_ON_PLACE_CHR  ; Ez lesz az új kő
    CMPA #PLACE_CHR ; IS PLACE?
    BEQ 1$          ; Mehet
    DEX
    RTS
1$: STAB 1,X           ; B-ben az új kő karaakter
    DEX
    LDAA UNDER_STONE   ; A-ban a régi kő karakter
    STAA 1,X
    BRA CHANGE_PUSH_COUNTER_IF_NEED_A_B   ; B-ben az új kő, A-ban a kő alatti karakter
    ; RTS


STONE_UP_X_A_B::      ; X a kő címe, B ami eredetileg a kő alatt van SPACE os PLACE
    STAB UNDER_STONE  ; Ez van a kő alatt
    STX TMP
    LDAB #32
1$: DEX
    DECB
    BNE 1$          ; MOVE UP
    LDAA 0,X            ; A-ban a kő új helye alatti kód
    STAA STONE_LAST_CHR ; Elmentjük az undo számára ;;; undo
    STX STONE_NEXT_POS  ; Elmentjük az undo számára ;;; undo
    LDAB #STONE_CHR  ; Ez lesz az új kő
    CMPA #SPACE_CHR ; IS SPACE?
    BEQ 2$          ; Mehet
    LDAB #STONE_ON_PLACE_CHR  ; Ez lesz az új kő
    CMPA #PLACE_CHR ; IS PLACE?
    BEQ 2$          ; Mehet
    LDX TMP
    RTS
2$: STAB 0,X
    LDX TMP
    LDAA UNDER_STONE
    STAA 0,X
    BRA CHANGE_PUSH_COUNTER_IF_NEED_A_B   ; B-ben az új kő, A-ban a kő alatti karakter
    ; RTS

STONE_DOWN_X_A_B::      ; X+32 a kő címe, B ami a kő alatt van
    STAB UNDER_STONE  ; Ez van a kő alatt
    STX TMP
    LDAB #32
1$: INX
    INX
    DECB
    BNE 1$          ; +64
    STX STONE_NEXT_POS  ; Elmentjük az undo számára ;;; undo
    LDAB #32
3$: DEX
    DECB
    BNE 3$          ; -32
    LDAA 32,X           ; A-ban a kő új helye alatti kód ;;; undo
    STAA STONE_LAST_CHR ; Elmentjük az undo számára
    LDAB #STONE_CHR  ; Ez lesz az új kő
    CMPA #SPACE_CHR ; IS SPACE?
    BEQ 2$          ; Mehet
    LDAB #STONE_ON_PLACE_CHR  ; Ez lesz az új kő
    CMPA #PLACE_CHR ; IS PLACE?
    BEQ 2$          ; Mehet
    LDX TMP
    RTS
2$: STAB 32,X
    LDX TMP
    LDAA UNDER_STONE
    STAA 32,X
    BRA CHANGE_PUSH_COUNTER_IF_NEED_A_B   ; B-ben az új kő, A-ban a kő alatti karakter
    ; RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; A-ban és (UNDER_STONE)-ban az eltolás előtti kő alatti karakter: SPACE_CHR vagy PLACE_CHR
;;; B-ben az új kő : STONE_CHR vagy STONE_ON_PLACE_CHR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHANGE_PUSH_COUNTER_IF_NEED_A_B: ; PUSH szánmláló növelése, X és A megtartásával.
    PSHA
    STX TMP
    ;;; Ellenőrizzük, hogy helyére került-e a kő, lekerült-e a helyéről, vagy nem változott
    LDX #PLACED_COUNTER_LAST_POSITION
    CMPA #SPACE_CHR ; Ha egyezik, akkor eredetileg nem volt a helyén
    BNE HELYEN_VOLT ; Ha nem egyenlő, akkor eredetileg a helyén volt
NEM_VOLT_A_HELYEN: ; A kő eredetileg nem volt a kő helyén
    CMPB #STONE_CHR           ; Ha egyezik, akkor most sincs a helyén
    BEQ VALTOZASKEZELES_VEGE  ;
    JSR INC_COUNTER_LAST_X    ; Ha nem egyezik, akkor helyére került, vagyis a PLACE countert is megnöveljük
    JSR STONE_TO_PLACE_EFFECT ; Jöhet a hang
    INC PLACED_COUNTER        ; Megnöveljük a számlálóját is
    ;;; Most ellenőrizzük, hogy ez volt-e az utolsó láda
    LDAA PLACED_COUNTER       ;
    CMPA PLACE_COUNTER        ; Ez a maximum
    BNE VALTOZASKEZELES_VEGE  ; Nem ez volt, mehetünk tovább
    ;;; Különben END OF LEVEL ;
    INC LEVEL_FINISHED        ; Beállítjuk a szint teljesítve jelzőt, és majd a főkör átlép az új szintre
    BRA VALTOZASKEZELES_VEGE
HELYEN_VOLT:
    CMPB #STONE_CHR ; Ha egyezik, akkor most sincs a helyén
    BNE VALTOZASKEZELES_VEGE
    JSR DEC_COUNTER_LAST_X
    DEC PLACED_COUNTER
    JSR STONE_FROM_PLACE_EFFECT
    ;BRA VALTOZASKEZELES_VEGE
    ;;; Helyszámlálás vége
VALTOZASKEZELES_VEGE:
    LDX #PUSH_COUNTER_LAST_POSITION
    JSR INC_COUNTER_LAST_X
    LDX TMP
    PULA
    RTS
