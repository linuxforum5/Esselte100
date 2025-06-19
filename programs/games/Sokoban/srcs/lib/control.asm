; minimális IO rutinok
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .area CONTROL  ( REL )
    .globl ROM_KEYRC_AB
    .globl CTRL_REPEAT_COUNTER,AJOY_A_X,AJOY_A_Y,AJOY_A_FIRE ; From variables
    .globl CTRL_REPEAT_SPEED ; From config
    .globl AJOY_A_FIRE,AJOY_A_MEASURE_AB,AJOY_INIT ; From ajoy
    .globl AJOY_MIN_LIMIT,AJOY_MAX_LIMIT,AJOY_FIRE_LIMIT ; From Config

CTRL_NOTHING	== 0
CTRL_UP		== 1   ; Q
CTRL_DOWN	== 2   ; A
CTRL_LEFT	== 4   ; I
CTRL_RIGHT	== 8   ; O
;CTRL_FIRE	== 16  ; Return
CTRL_RESTART	== 32  ; R
CTRL_EXIT	== 64  ; E
CTRL_N		== 16  ; N
CTRL_U		== 128 ; U

;LEFT_KEY_A  .equ 16 ; I=(16,4)
;LEFT_KEY_B  .equ 4  ;
;RIGHT_KEY_A .equ 16 ; O=(16,3)
;RIGHT_KEY_B .equ 3  ;
;UP_KEY_A    .equ 16 ; Q=(16,1)
;UP_KEY_B    .equ 4  ;
;DOWN_KEY_A  .equ 8  ; A=(8,1)
;DOWN_KEY_B  .equ 1  ;

;LEFT_KEY_A  .equ 8  ; [1]=(8,7)
;LEFT_KEY_B  .equ 7  ;
;RIGHT_KEY_A .equ 8  ; [3]=(8,9)
;RIGHT_KEY_B .equ 9  ;
;UP_KEY_A    .equ 16 ; [5]=(16,8)
;UP_KEY_B    .equ 8  ;
;DOWN_KEY_A  .equ 8  ; [2]=(8,8)
;DOWN_KEY_B  .equ 8  ;

LEFT_KEY_A  .equ 8  ; J=(8,5)
LEFT_KEY_B  .equ 5  ;
RIGHT_KEY_A .equ 8  ; L=(8,3)
RIGHT_KEY_B .equ 3  ;
UP_KEY_A    .equ 16 ; I=(16,4)
UP_KEY_B    .equ 4  ;
DOWN_KEY_A  .equ 8  ; K=(8,4)
DOWN_KEY_B  .equ 4  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Billentyűzet olvasása | O,P,Q,A,Enter : (16,3),(64,3),(16,1),(8,1),(64,6) | J,K,L,I,Enter
;;; Az eredmény A-ba, mint bitek
;;;                                                         a  b  i  h  g  f  e  d  c | c  d   e  f      g   h   i   b
;;; B|A 001 002 004 008 016 032 064 128 A                   1  2  9  8  7  6  5  4  3 | 3  4   5  6      7   8   9   2
;;; 1            Z   A   Q   1                   032  ! ->  1  2  3  4  5  6  7  8  9 | 0  +  Pi  <     [7] [8] [9] [*]    <-  . 128
;;; 2   [+] [-]  X   S   W   2  [/] [*]          016 pq ->  Q  W  E  R  T  Y  U  I  O | P  Å   ^ RTN    [4] [5] [6] [/]    <- πA 064
;;; 3    Ö       .   L   O   9   P   0           008 hi ->  A  S  D  F  G  H  J  K  L | Ö  Ä  '  <--    [1] [2] [3] [+]    <-    001
;;; 4    Ä   -   ,   K   I   8   Å   +           004 de ->  Z  X  C  V  B  N  M  ,  .      -     -->    [0] [.] [E] [-]    <-    002
;;; 5    '       M   J   U   7   ^  Pi 
;;; 6   <-- -->  N   H   Y   6  RET  < 
;;; 7   [1] [0]  B   G   T   5  [4] [7]
;;; 8   [2] [.]  V   F   R   4  [5] [8]
;;; 9   [3] [E]  C   D   E   3  [6] [9]  
;;; B
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WAIT_FOR_NO_KEY_PRESSED::
    JSR ROM_KEYRC_AB         ; Beolvassuk a lenyomott sor és oszlopértékeket
    CMPA #0
    BNE WAIT_FOR_NO_KEY_PRESSED
    RTS

;WAIT_FOR_KEY_OR_FIRE_PRESSED::
;    JSR AJOY_A_MEASURE_AB
;    LDAA AJOY_A_FIRE
;    BNE FIRE_PRESSED
;    JSR ROM_KEYRC_AB         ; Beolvassuk a lenyomott sor és oszlopértékeket
;    CMPA #0
;    BEQ WAIT_FOR_KEY_OR_FIRE_PRESSED
;FIRE_PRESSED:
;    RTS

CONTROL_JOY_DIRECTIONS:      ; Nézzük, a joy el van-e nyomva valamerre
    LDAA AJOY_A_X
    CMPA #AJOY_MAX_LIMIT
    BHI KEY_LEFT_PRESSED     ; Ugrás, ha A > AJOY_MAX_LIMIT
    CMPA #AJOY_FIRE_LIMIT
    BLS KEY_UNDO_PRESSED     ; Ugrás, ha A <= AJOY_FIRE_LIMIT
    CMPA #AJOY_MIN_LIMIT
    BLS KEY_RIGHT_PRESSED    ; Ugrás, ha A <= AJOY_MIN_LIMIT
    LDAA AJOY_A_Y
    CMPA #AJOY_MAX_LIMIT
    BHI KEY_UP_PRESSED       ; Ugrás, ha A > AJOY_MAX_LIMIT
    CMPA #AJOY_MIN_LIMIT
    BLS KEY_DOWN_PRESSED     ; Ugrás, ha A <= AJOY_MIN_LIMIT
    BRA CHECK_KEYS

CONTROL_INIT::
    LDX #CTRL_REPEAT_SPEED
    STX CTRL_REPEAT_COUNTER  ; Számláló visszaállítása
    RTS

CONTROL_A::
    LDX CTRL_REPEAT_COUNTER
    DEX                      ; Csökkentjük a billentyűismétlési számot, és csak 0 esetén vizsgáljuk az irányítást
    STX CTRL_REPEAT_COUNTER  ; Számláló mentése
    BEQ START_CONTROL
    LDAA CTRL_NOTHING        ; Ha 0, akkor beállítjuk a visszatérési értéket
    RTS
START_CONTROL:
    LDX #CTRL_REPEAT_SPEED
    STX CTRL_REPEAT_COUNTER  ; Számláló visszaállítása
;    JSR AJOY_INIT
    JSR AJOY_A_MEASURE_AB      ; Először nézzünk rá a joy-ra
    CMPB #0
    BNE CONTROL_JOY_DIRECTIONS ; Ha van joy, akkor az irányokat onnan kezdjük el vizsgálni
CHECK_KEYS:
    JSR ROM_KEYRC_AB         ; Beolvassuk a lenyomott sor és oszlopértékeket
    CMPA #0
    BNE CHK_ACCA             ; Ha nem 0, akkor elkezdjük elemezni
    LDAA CTRL_NOTHING        ; Ha 0, akkor beállítjuk a visszatérési értéket
;    STAA CTRL_LAST_AB        ; Valamint az utoljára lenyomott gombot is erre állítjuk
    RTS                      ; Vége
CHK_ACCA:                    ; Le van nyomva valami, a lenyomott kód A és B regiszterekben, ezért
;    PSHA                     ; Elmentjük A értékét
;    PSHB                     ; Elmentjük B értékét
;    STAB CTRL_CURR_AB        ; 
;    EORA CTRL_CURR_AB
;    STAA CTRL_CURR_AB        ; Elmentjük A | B értékét, a billentyűismétlés elkerüléséhez

;    LDX CTRL_REPEAT_COUNTER
;    DEX                      ; Csökkentjük a billentyűismétlési számot. Ha 0 lesz, akkor mindegy, mi volt előzőleg lenyomva, akkor is érzékeljük
;    BEQ CHK_ACCA2
;    STX CTRL_REPEAT_COUNTER
;    CMPA CTRL_LAST_AB
;    BNE CHK_ACCA2
;    PULB
;    PULA
;    LDAA CTRL_NOTHING
;    RTS
;CHK_ACCA2:
;    STX CTRL_REPEAT_COUNTER
;    STAA CTRL_LAST_AB
;    LDX #CTRL_REPEAT_SPEED
;    STX CTRL_REPEAT_COUNTER
;    PULB
;    PULA
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHK_KEY1:                    ; Left
    CMPB #LEFT_KEY_B         ; Check B
    BNE CHK_KEY2             ;
    CMPA #LEFT_KEY_A         ;
    BNE CHK_KEY2             ;
KEY_LEFT_PRESSED:
    LDAA #CTRL_LEFT          ; Key 1 le volt nyomva
    RTS
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHK_KEY2:                    ;Right
    CMPB #RIGHT_KEY_B        ; Check B
    BNE CHK_KEY3             ;
    CMPA #RIGHT_KEY_A        ;
    BNE CHK_KEY3             ;
KEY_RIGHT_PRESSED:
    LDAA #CTRL_RIGHT         ; Key 2 le volt nyomva
    RTS
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHK_KEY3:                    ; Up
    CMPB #UP_KEY_B           ; Check B
    BNE CHK_KEY4             ;
    CMPA #UP_KEY_A           ;
    BNE CHK_KEY4             ;
KEY_UP_PRESSED:
    LDAA #CTRL_UP            ; Key 3 le volt nyomva
    RTS
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHK_KEY4:                    ; Down
    CMPB #DOWN_KEY_B         ; Check B
    BNE CHK_KEY5             ;
    CMPA #DOWN_KEY_A         ;
    BNE CHK_KEY5             ;
KEY_DOWN_PRESSED:
    LDAA #CTRL_DOWN          ; Key 4 le volt nyomva
    RTS
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHK_KEY5:                    ; U (16,5)
    CMPB #5                  ; Check U
    BNE CHK_KEY6             ;
    CMPA #16                 ;
    BNE CHK_KEY6             ;
KEY_UNDO_PRESSED:
    LDAA #CTRL_U             ; Key 9 le volt nyomva
    RTS
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CHK_KEY5:                    ; Enter (64,6)
;    CMPB #6                  ; Check B
;    BNE CHK_KEY6             ;
;    CMPA #64                 ;
;    BNE CHK_KEY6             ;
;    LDAA #CTRL_FIRE          ; Key 5 le volt nyomva
;    RTS
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHK_KEY6:                    ; R (16,8)
    CMPB #8                  ; Check R
    BNE CHK_KEY7             ;
    CMPA #16                 ;
    BNE CHK_KEY7             ;
    LDAA #CTRL_RESTART       ; Key 6 le volt nyomva
    RTS
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHK_KEY7:                    ; E (16,9)
    CMPB #9                  ; Check E
    BNE CHK_KEY8             ;
    CMPA #16                 ;
    BNE CHK_KEY8             ;
    LDAA #CTRL_EXIT          ; Key 7 le volt nyomva
    RTS
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHK_KEY8:                    ; N (4,6)
    CMPB #6                  ; Check N
    BNE NOTHING              ;
    CMPA #4                  ;
    BNE NOTHING              ;
    LDAA #CTRL_N             ; Key 8 le volt nyomva
    RTS
NOTHING:
    LDX #1                   ; Ha semit sem nyomtunk, akkor a számlálót lehet 1-re állítani, így a következő körben is ellenőriz => gyorsabb reakció
    STX CTRL_REPEAT_COUNTER
    LDAA #CTRL_NOTHING
    RTS

CHK_KEY_Y:: ; Z=1, ha le van nyomva épp
    JSR ROM_KEYRC_AB         ; Beolvassuk a lenyomott sor és oszlopértékeket
    CMPB #6                  ; Check Y (16,6)
    BNE KEY_NOT_PRESSED      ;
    CMPA #16                 ;
KEY_NOT_PRESSED:
    RTS

CHK_KEY_N:: ; Z=1, ha le van nyomva épp
    JSR ROM_KEYRC_AB         ; Beolvassuk a lenyomott sor és oszlopértékeket
    CMPB #6                  ; Check N (4,6)
    BNE KEY_NOT_PRESSED      ;
    CMPA #4                  ;
    RTS

CHECK_KEY_S_OR_FIRE_B_Z::    ; Z=1, ha S vagy a tűz le van nyomva. Tüzet csak B!=0 esetén nézi
    CMPB #0
    BEQ SKIP_TEST_FIRE
    JSR AJOY_A_MEASURE_AB    ; Különben Test fire
    LDAA AJOY_A_FIRE
    CMPA #1
    BEQ KEY_S_CHECK_END      ; Ha le volt nyomva, az olyan, mintha S-et nyomtunk volna
SKIP_TEST_FIRE:
    JSR ROM_KEYRC_AB         ; Beolvassuk a lenyomott sor és oszlopértékeket
    CMPB #2                  ; Check S (8,2)
    BNE KEY_S_CHECK_END      ;
    CMPA #8                  ;
KEY_S_CHECK_END:
    RTS
