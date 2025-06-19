; http://www.8bit-era.cz/6800.html

    .area LEVEL ( REL )
    .globl ROM_CLS,MAZE1,SHOWKOBAN,UNDER_PLAYER
    .globl INC_COUNTER_LAST_X,CLEAR_COUNTER_LAST_X ; From str-counter
    .globl COPY_TO,COPY_FROM,COPY_FROM_TO_0 ; From copy
    .globl SET_SOUND_SPEED_A
    .globl SHOW_START_SCREEN ; From start
    .globl SHOW_HELP_LINE ; From help
    .globl SPACE_CHR,STONE_CHR,PLACE_CHR,STONE_ON_PLACE_CHR,WALL_CHR,PLAYER_CHR,PLAYER2_CHR,STATTEXT_COUNTERS_ON_SCREEN,STATTEXT_LEVEL_ON_SCREEN,LEVEL_COUNTER_LAST_POSITION,MAX_LEVEL_NUM ; From config
    .globl CURRENT_LEVEL,CURRENT_X,CURRENT_Y,MAX_X,MAX_Y,CURRENT_LEVEL_DATA,NEXT_LEVEL_DATA,SCREENPOS,COUNTER,PLAYER_POS,PLACE_COUNTER,PLACED_COUNTER,LEVEL_FINISHED,MAZE_FIRST_ADDR ; From variables

CHARCODES: .byte SPACE_CHR,STONE_CHR,PLACE_CHR,STONE_ON_PLACE_CHR,WALL_CHR,PLAYER_CHR

GAME_INIT::
    JSR SHOW_START_SCREEN
    JSR ROM_CLS
    JSR SHOWKOBAN
    JSR SHOW_HELP_LINE
    JSR SHOWSTAT
    ;;; Kezdőszint beállítása:
    CLR CURRENT_LEVEL
    LDX #MAZE1
    STX NEXT_LEVEL_DATA
    JSR SHOWLEVEL
    BSR LEVEL_INC
    ;;; Kezdőszint beállítás vége
    LDAA #2 ;
    JSR SET_SOUND_SPEED_A
    RTS

LEVEL_INC::
    LDAA CURRENT_LEVEL
    CMPA #MAX_LEVEL_NUM      ; Ez az utolsó szint?
    BNE 1$                  ; Nem, mehet a növelés
    LDX #LEVEL_COUNTER_LAST_POSITION
    JSR CLEAR_COUNTER_LAST_X
    LDX #MAZE1
    STX NEXT_LEVEL_DATA
    LDAA #0
    STAA CURRENT_LEVEL
1$: LDX NEXT_LEVEL_DATA
    STX CURRENT_LEVEL_DATA
    INC CURRENT_LEVEL
    LDX #LEVEL_COUNTER_LAST_POSITION
    JSR INC_COUNTER_LAST_X
    RTS

LEVEL_INIT::
    LDAA #0
    STAA PLACE_COUNTER
    STAA PLACED_COUNTER
    STAA LEVEL_FINISHED
    LDAA #SPACE_CHR
    STAA UNDER_PLAYER
    RTS

LEVEL_SHOW::
    JSR CLS_MAZE
    JSR SHOWSTAT
    LDAA #0
    STAA CURRENT_X
    STAA CURRENT_Y
    LDX #MAZE_FIRST_ADDR         ; A kezdősor itt megadható, de mindenképp az első oszlopban illik kezdeni
    STX SCREENPOS
    LDX CURRENT_LEVEL_DATA
    STX NEXT_LEVEL_DATA
    LDAA 0,X
    STAA MAX_X
    INX
    LDAB 0,X
    STAB MAX_Y
    INX
SORRAJZ_LOOP:
    BSR SHOW_LINE_X ; Az A karakterben tárolt sordarab megjelenítése. Felső 3 bit a karakter alakja, alsó 5 bit az ismétlődés száma
    LDAA CURRENT_X
    CMPA MAX_X
    BNE SORRAJZ_LOOP
    ;;; Itt elértük a sor végét, új sort kezdünk
    CLR CURRENT_X
    INC CURRENT_Y
    LDAA SCREENPOS+1
    ORAA #31
    STAA SCREENPOS+1
    INC SCREENPOS+1
    BNE SCREENPOS_IS_OK
    INC SCREENPOS
SCREENPOS_IS_OK:
    LDAA MAX_Y
    CMPA CURRENT_Y
    BNE SORRAJZ_LOOP
    RTS

SHOW_LINE_X:
    LDAA 0,X
    ANDA #31 ; Az alsó 5 bit
    STAA COUNTER
    LDAA 0,X
    ;;; Move A. char into CHARCODES
    INX
    STX NEXT_LEVEL_DATA
    LDX #CHARCODES
    LSRA
    LSRA
    LSRA
    LSRA
    LSRA
    ;;; A-ban a karakter typuskódja: [0-5]
LP:
    BEQ X_IS_GOOD
    INX
    DEC A
    BRA LP
X_IS_GOOD:
    LDAA 0,X         ; A-ban a rajzolandó karakter
    ;;; A-ban a megjelenítendő karakter képernyőkódja
    LDX SCREENPOS    ; X-ben az aktuális képernyőcím
    LDAB COUNTER     ; B-ben, hogy hány karaktert kell rajzolni (legalább 1)
    CMPA #PLAYER_CHR ; Játékosból csak egy van, ezt itt is számolhatjuk
    BNE SZAKASZRAJZOLO
    STX PLAYER_POS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Az aktuális szakasz kirajzolása egyforma karakterekből
;;; X - Az általa mutatott címen van a karakter alakja és száma is egy bájtban
;;; A felső 3 bit az alak, az alsó 5 a mennyiség
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SZAKASZRAJZOLO:
    STAA 0,X
    INX
    INC CURRENT_X
CHK_STONE:
    CMPA #STONE_CHR
    BNE CHK_STONE_ON_PLACE
    INC PLACE_COUNTER
    BRA COUNT_FINISH
CHK_STONE_ON_PLACE:
    CMPA #STONE_ON_PLACE_CHR
    BNE COUNT_FINISH
    INC PLACE_COUNTER
    INC PLACED_COUNTER
COUNT_FINISH:
    DECB
    BNE SZAKASZRAJZOLO
    STX SCREENPOS
    LDX NEXT_LEVEL_DATA
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Csak a pálya törlése
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CLS_MAZE: ; 0x20 kódú törlés
    LDAA #0x20
    LDX #MAZE_FIRST_ADDR-64
1$:
    STAA 0,X
    INX
    CPX #0xC3D0
    BNE 1$
    RTS

SHOWSTAT:
    LDX #STATTEXT_COUNTERS
    STX COPY_FROM
    LDX #STATTEXT_COUNTERS_ON_SCREEN     ; Utolsó sor eleje
    STX COPY_TO
    JMP COPY_FROM_TO_0

SHOWLEVEL:
    LDX #STATTEXT_LEVEL
    STX COPY_FROM
    LDX #STATTEXT_LEVEL_ON_SCREEN     ; Utolsó sor eleje
    STX COPY_TO
    JMP COPY_FROM_TO_0

STATTEXT_COUNTERS: .strz "MOVE: 0000 PUSH: 0000 PLACED: 00"
STATTEXT_LEVEL: .strz "WAREHOUSE: 00/20" ; MAXMAZENUMSTR 
