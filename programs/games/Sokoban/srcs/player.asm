; http://www.8bit-era.cz/6800.html

    .area MAIN ( REL )
    .globl PLAYER_POS,SPACE_CHR,PLAYER_CHR,PLAYER2_CHR,PLACE_CHR,STONE_CHR,STONE_ON_PLACE_CHR,MAIN_LOOP,STONE_LEFT_X_A_B,STONE_RIGHT_X_A_B,STONE_UP_X_A_B,STONE_DOWN_X_A_B
    .globl PLACED_COUNTER ; From level
    .globl MOVE_COUNTER_LAST_POSITION,PUSH_COUNTER_LAST_POSITION,PLACED_COUNTER_LAST_POSITION ; From config
    .globl PLAYER_MOVE_SOUND ; From sound-effects
    .globl INC_COUNTER_LAST_X,DEC_COUNTER_LAST_X ; From str-counter
    .globl UNDER_PLAYER,MOVE_COUNTER,PLAYER_LAST_POS,PLAYER_LAST_CHR,OLD_PUSH_LAST_CHR,PLACED_LAST_COUNTER,STONE_LAST_CHR,STONE_NEXT_POS ; From variables

PLAYER_INIT::
    LDX #0
    STX MOVE_COUNTER
    RTS

PLAYER_ANIM::
    LDX PLAYER_POS
    LDAA 0,X
    LDAB #PLAYER2_CHR
    CMPA #PLAYER_CHR
    BEQ 1$
    LDAB #PLAYER_CHR
1$: STAB 0,X
    RTS

MOVE_LEFT::
    JSR SAVE_DATA_PACK1_FOR_MOVE
    LDX PLAYER_POS
    DEX
    LDAA 0,X ;
    STAA PLAYER_LAST_CHR     ; PLAYER_LAST_CHR mentése az undo műveltehez
    ;;; Kőkezelés kezdete
    LDAB #SPACE_CHR    ; Ez van a kő alatt
    CMPA #STONE_CHR
    BNE 1$
    JSR STONE_LEFT_X_A_B ; Eltolja a kövat balra, ha lehet. Ha lehetett, akkor A-ban #SPACE_CHR van, különben nem. X a kő címe a képernyőn
1$: LDAB #PLACE_CHR    ; Ez van a kő alatt
    CMPA #STONE_ON_PLACE_CHR
    BNE 2$
    JSR STONE_LEFT_X_A_B ; Eltolja a kövat balra, ha lehet. Ha lehetett, akkor A-ban #SPACE_CHR van, különben nem. X a kő címe a képernyőn
    ;;; Kőkezelés vége
2$: CMPA #SPACE_CHR
    BEQ 3$
    CMPA #PLACE_CHR
    BEQ 3$
    JMP MAIN_LOOP
3$: LDAB UNDER_PLAYER
    STAB 1,X
    STAA UNDER_PLAYER
    LDAA #PLAYER_CHR
    STAA 0,X
    STX PLAYER_POS
    JMP PLAYER_MOVE_ANYWHERE

MOVE_RIGHT::
    JSR SAVE_DATA_PACK1_FOR_MOVE
    LDX PLAYER_POS
    LDAA 1,X
    STAA PLAYER_LAST_CHR     ; PLAYER_LAST_CHR mentése az undo műveltehez
    ;;; Kőkezelés kezdete
    LDAB #SPACE_CHR    ; Ez van a kő alatt
    CMPA #STONE_CHR
    BNE 1$
    JSR STONE_RIGHT_X_A_B ; Eltolja a kövat jobbra, ha lehet. Ha lehetett, akkor A-ban #SPACE_CHR van, különben nem. X+1 a kő címe a képernyőn
1$: LDAB #PLACE_CHR    ; Ez van a kő alatt
    CMPA #STONE_ON_PLACE_CHR
    BNE 2$
    JSR STONE_RIGHT_X_A_B ; Eltolja a kövat jobbra, ha lehet. Ha lehetett, akkor A-ban #SPACE_CHR van, különben nem. X+1 a kő címe a képernyőn
    ;;; Kőkezelés vége
2$: CMPA #SPACE_CHR
    BEQ 3$
    CMPA #PLACE_CHR
    BEQ 3$
    JMP MAIN_LOOP
3$: LDAB UNDER_PLAYER
    STAB 0,X
    STAA UNDER_PLAYER
    INX
    STX PLAYER_POS
    LDAA #PLAYER_CHR
    STAA 0,X
    JMP PLAYER_MOVE_ANYWHERE

MOVE_UP::
    JSR SAVE_DATA_PACK1_FOR_MOVE
    LDX PLAYER_POS
    LDAB #32
4$:
    DEX
    DECB
    BNE 4$        ; MOVE UP
    LDAA 0,X ;
    STAA PLAYER_LAST_CHR     ; PLAYER_LAST_CHR mentése az undo műveltehez
    ;;; Kőkezelés kezdete
    LDAB #SPACE_CHR    ; Ez van a kő alatt
    CMPA #STONE_CHR
    BNE 1$
    JSR STONE_UP_X_A_B ; Eltolja a kövat jobbra, ha lehet. Ha lehetett, akkor A-ban #SPACE_CHR van, különben nem. X a kő címe a képernyőn
1$: LDAB #PLACE_CHR    ; Ez van a kő alatt
    CMPA #STONE_ON_PLACE_CHR
    BNE 2$
    JSR STONE_UP_X_A_B ; Eltolja a kövat jobbra, ha lehet. Ha lehetett, akkor A-ban #SPACE_CHR van, különben nem. X a kő címe a képernyőn
    ;;; Kőkezelés vége
2$: CMPA #SPACE_CHR
    BEQ 3$
    CMPA #PLACE_CHR
    BEQ 3$
    JMP MAIN_LOOP
3$: LDAB UNDER_PLAYER
    STAB 32,X
    STAA UNDER_PLAYER
    LDAA #PLAYER_CHR
    STAA 0,X
    STX PLAYER_POS
    JMP PLAYER_MOVE_ANYWHERE

MOVE_DOWN::
    JSR SAVE_DATA_PACK1_FOR_MOVE
    LDX PLAYER_POS           ; Load player position
    LDAA 32,X                ; A the next position content
    STAA PLAYER_LAST_CHR     ; PLAYER_LAST_CHR mentése az undo műveltehez
    ;;; Kőkezelés kezdete
CHK_STONE:
    LDAB #SPACE_CHR          ; Ez van a kő alatt
    CMPA #STONE_CHR          ; A következő karakter egy kő, ami SPACE felett áll?
    BNE CHK_STONE_ON_PLACE   ; Ha nem akkor vizsgáljuk tovább: STONE_ON_PLACE?
    ;;; A kő alatt SPACE van
    JSR STONE_DOWN_X_A_B     ; Eltolja a követ lefelé, ha lehet. Ha lehetett, akkor A-ban #SPACE_CHR van, különben nem. X+32 a kő címe a képernyőn
CHK_STONE_ON_PLACE:
    LDAB #PLACE_CHR          ; Ez van a kő alatt
    CMPA #STONE_ON_PLACE_CHR ; A kő PLACE felett állt?
    BNE CHK_SPACE_OR_PLACE   ; Ha nem akkor vizsgáljuk tovább: SPACE vagy PLACE?
    JSR STONE_DOWN_X_A_B ; Eltolja a követ lefelé, ha lehet. Ha lehetett, akkor A-ban #SPACE_CHR van, különben nem. X+32 a kő címe a képernyőn
    ;;; Kőkezelés vége
CHK_SPACE_OR_PLACE:
    CMPA #SPACE_CHR
    BEQ 3$
    CMPA #PLACE_CHR
    BEQ 3$
    JMP MAIN_LOOP             ; Egyiksem, végeztünk
3$: LDAB UNDER_PLAYER         ;
    STAB 0,X                  ; X-ben a játékos eredeti pozíciója van. Ide betöltjük azt, ami a játékos alatt van éppen
    STAA UNDER_PLAYER         ; A-ban a játékos új pozíciója alatti karakter, ezt elmentjük
    LDAB #32                  ; Előkészítjük X megnövelését 32-vel
4$: INX
    DECB
    BNE 4$
    LDAA #PLAYER_CHR
    STAA 0,X
    STX PLAYER_POS
    JMP PLAYER_MOVE_ANYWHERE

PLAYER_MOVE_ANYWHERE:
    ;;; A lépésszámláló növelése minden lépésirány esetén
    LDX #MOVE_COUNTER_LAST_POSITION
    JSR INC_COUNTER_LAST_X
    ;;; Hang kiadása
    JSR PLAYER_MOVE_SOUND
    JMP MAIN_LOOP

SAVE_DATA_PACK1_FOR_MOVE: ; Minden lépés elején rendelkezésre álló adatok elmentése az undo művelethez. De vannak még további mentendő adatok
    LDX PLAYER_POS
    STX PLAYER_LAST_POS      ; PLAYER_LAST_POS mentve
;    LDAA 0,X
;    STAA PLAYER_LAST_CHR     ; PLAYER_LAST_CHR mentve
    LDX #PUSH_COUNTER_LAST_POSITION
    LDAA 0,X
    STAA OLD_PUSH_LAST_CHR   ; OLD_PUSH_LAST_CHR mentve
    LDAA PLACED_COUNTER
    STAA PLACED_LAST_COUNTER ; PLACED_LAST_COUNTER mentve
    RTS

SAVE_DATA_PACK2_FOR_MOVE: ; Az undo művelthez még szükséges adatok mentése ( STONE_LAST_CHR, STONE_NEXT_POS )
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Mentendő adatok:
;;; - PLAYER_LAST_POS     : A játékos előző pozíciója (16 bit)
;;; - PLAYER_LAST_CHR     : A játékos mostani pozícióján az előtte ott lévő karakter
;;; - OLD_PUSH_LAST_CHR   : A PUSH_COUNTER utolsó számjegye a tolás előtt
;;; - PLACED_LAST_COUNTER : A PLACED_COUNTER előző értéke
;;; - STONE_LAST_CHR      : Ha volt eltolt kő az alatta levő előző karakter
;;; - STONE_NEXT_POS      : A lépés irányában a következő pozícióban a lépés előtt tartózkodó karakter. Ez vagy SPACE_CHR vagy PLACE_CHR lehet
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVE_UNDO::
    LDX MOVE_COUNTER
    BEQ NO_UNDO
    LDX #PUSH_COUNTER_LAST_POSITION
    LDAA 0,X
    CMPA OLD_PUSH_LAST_CHR
    BNE NEED_UNDO ; Ha van eltérés az eltolások utolsó számjegyében, akkor az utolsó lépés tolás volt, tehát lehet undo
NO_UNDO:
    JMP MAIN_LOOP ; Nem tolás volt, nincs undo
;    RTS ; Nem tolás volt, nincs undo
NEED_UNDO:
    ;;; Játékost vissza az előző pozícióra
    LDAA PLAYER_LAST_CHR
    LDX PLAYER_POS
    STAA 0,X
    ;;; Az előtte ott lévő karaktert vissza
    LDX PLAYER_LAST_POS
    STX PLAYER_POS
    LDAA #PLAYER_CHR
    STAA 0,X
    ;;; Ha eltolás volt, akkor az eltolás előtti karakter azon a helyen
    LDX STONE_NEXT_POS
    LDAA STONE_LAST_CHR
    STAA 0,X
    ;;; A lépésszámláló visszacsökkentése
    LDX #MOVE_COUNTER_LAST_POSITION
    JSR DEC_COUNTER_LAST_X
    ;;; Tolásszámláló visszacsökkentése
    LDX #PUSH_COUNTER_LAST_POSITION
    JSR DEC_COUNTER_LAST_X
    ;;; A helyére tolt kövek számlálójának csökkentése, ha kell
    LDAA PLACED_COUNTER
    CMPA PLACED_LAST_COUNTER
    BEQ 1$ ; Ha azonos, akkor már nincs más teendőnk.
    ;;; Ha nem, akkor ezt is csökkentjük
    DEC PLACED_COUNTER
    LDX #PLACED_COUNTER_LAST_POSITION
    JSR DEC_COUNTER_LAST_X
1$:
    JMP MAIN_LOOP
; RTS
