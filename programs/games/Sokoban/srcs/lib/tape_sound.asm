;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Hangkeltés a magnókimenettel. 1 bites beeper
;;; T_SOUND_AB      : A-magasság, B-hossz
;;; T_SOUND_NOISE_B : B-hossz
;;; T_SOUND_PAUSE_1 : (1)-hossz
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .area TSND ( REL )
DPORT          .EQU 0xC80A
PAUSEA         .EQU 250
TSB_REPEAT::   .byte 8   ; Ennyiszer megy végig a hang idejének leszámolása, azaz a hang ideje ennyivel szórzódik (lehet így hosszabb, mint 8 bit, mivel kölön kör)
;;; Ideiglenes változók memóriacímei:
PITCH_A        .equ 0 ; Itt tároljuk a hang A-ban megadott magasságát
SOUND_LENGTH_B .equ 1 ; Itt tároljuk a hang B-ben megadott hosszát
REPEAT_COUNTER .equ 2 ; Itt tároljuk az ismétlődések aktuélis számát, ez ideiglenes változó, a hang alatt csökken
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; A paraméter konstansai:
TSA_B3  == 248 ; B3           246.94
TSA_C4  == 233 ; C4           261.63
TSA_C_4 == 220 ; C#4 / Db4    277.18
TSA_D4  == 207 ; D4           293.66
TSA_D_4 == 196 ; D#4 / Eb4    311.13
TSA_E4  == 184 ; E4           329.63
TSA_F4  == 174 ; F4           349.23
TSA_F_4 == 164 ; F#4 / Gb4    369.99
TSA_G4  == 154 ; G4           392.0
TSA_G_4 == 145 ; G#4 / Ab4    415.3
TSA_A4  == 137 ; A4           440.0
TSA_A_4 == 129 ; A#4 / Bb4    466.16
TSA_B4  == 121 ; B4           493.88
TSA_C5  == 114 ; C5           523.25
TSA_C_5 == 108 ; C#5 / Db5    554.37
TSA_D5  == 101 ; D5           587.33
TSA_D_5 == 95 ; D#5 / Eb5     622.25
TSA_E5  == 90 ; E5            659.26
TSA_F5  == 84 ; F5            698.46
TSA_F_5 == 79 ; F#5 / Gb5     739.99
TSA_G5  == 75 ; G5            783.99
TSA_G_5 == 70 ; G#5 / Ab5     830.61
TSA_A5  == 66 ; A5            880.0
TSA_A_5 == 62 ; A#5 / Bb5     932.33
TSA_B5  == 58 ; B5            987.77
TSA_C6  == 54 ; C6            1046.5
TSA_C_6 == 51 ; C#6 / Db6     1108.73
TSA_D6  == 48 ; D6            1174.66
TSA_D_6 == 45 ; D#6 / Eb6     1244.51
TSA_E6  == 42 ; E6            1318.51
TSA_F6  == 39 ; F6            1396.91
TSA_F_6 == 37 ; F#6 / Gb6     1479.98
TSA_G6  == 35 ; G6            1567.98
TSA_G_6 == 32 ; G#6 / Ab6     1661.22
TSA_A6  == 30 ; A6            1760.0
TSA_A_6 == 28 ; A#6 / Bb6     1864.66
TSA_B6  == 26 ; B6            1975.53
TSA_PAUSE == 1 ; Szünet
;;; B paraméter konstansai 0.125s:
TSB_B3  == 31 ; B3            246.94
TSB_C4  == 33 ; C4            261.63
TSB_C_4 == 35 ; C#4 / Db4     277.18
TSB_D4  == 37 ; D4            293.66
TSB_D_4 == 39 ; D#4 / Eb4     311.13
TSB_E4  == 41 ; E4            329.63
TSB_F4  == 44 ; F4            349.23
TSB_F_4 == 46 ; F#4 / Gb4     369.99
TSB_G4  == 49 ; G4            392.0
TSB_G_4 == 52 ; G#4 / Ab4     415.3
TSB_A4  == 55 ; A4            440.0
TSB_A_4 == 58 ; A#4 / Bb4     466.16
TSB_B4  == 62 ; B4            493.88
TSB_C5  == 65 ; C5            523.25
TSB_C_5 == 69 ; C#5 / Db5     554.37
TSB_D5  == 73 ; D5            587.33
TSB_D_5 == 78 ; D#5 / Eb5     622.25
TSB_E5  == 82 ; E5            659.26
TSB_F5  == 87 ; F5            698.46
TSB_F_5 == 92 ; F#5 / Gb5     739.99
TSB_G5  == 98 ; G5            783.99
TSB_G_5 == 104 ; G#5 / Ab5    830.61
TSB_A5  == 110 ; A5           880.0
TSB_A_5 == 117 ; A#5 / Bb5    932.33
TSB_B5  == 123 ; B5           987.77
TSB_C6  == 131 ; C6           1046.5
TSB_C_6 == 139 ; C#6 / Db6    1108.73
TSB_D6  == 147 ; D6           1174.66
TSB_D_6 == 156 ; D#6 / Eb6    1244.51
TSB_E6  == 165 ; E6           1318.51
TSB_F6  == 175 ; F6           1396.91
TSB_F_6 == 185 ; F#6 / Gb6    1479.98
TSB_G6  == 196 ; G6           1567.98
TSB_G_6 == 208 ; G#6 / Ab6    1661.22
TSB_A6  == 220 ; A6           1760.0
TSB_A_6 == 233 ; A#6 / Bb6    1864.66
TSB_B6  == 247 ; B6           1975.53
TSB_PAUSE == 31 ; 250-hez (PAUSEA) 31
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; A - A hang magassága. 1 gépi ciklus 1us
;;;     C = 42+A*8 A félciklus hossza | NOP nélkül 42+A*6
;;;     f = 500 000us/C
;;;    A hang frekvenciája
;;;   A | C us |  f Hz | C2 us | f2 Hz
;;;   1 |   50 | 10000 |    48 | 10416
;;;   2 |   58 |  8621 |    54 |  9259
;;;   3 |   66 |  7576 |    60 |  8333
;;;   4 |   74 |  6756 |    66 |  7576
;;; 255 | 2082 |   240 |  1572 |   318
;;;   0 | 2090 |   239 |  1578 |   317
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Egyéb konstansok:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NOISE_START_ADDR .equ 0xD000 ; A zajgenerátor innen veszi az adatokat a zajhoz

T_SOUND_AB::                     ; =B*(42+A*8)+9 A magasságú B hosszúságú hang
    STAB SOUND_LENGTH_B       ; (SOUND_LENGTH_B):=B
    LDAB TSB_REPEAT
    STAB REPEAT_COUNTER       ; (REPEAT_COUNTER):=TSB_REPEAT
    CMPA #TSA_PAUSE           ; Hangmagasság ellenőrzése, hogy nem a PAUSE értéket kértük-e
    BEQ T_SOUND_PAUSE_1B
    STAA PITCH_A        ; 4
T_SOUND_REPEAT:
        LDAB SOUND_LENGTH_B
T_SOUND_AB_LOOP:                ; Egy kör hossza = 42+A*8 ciklus
            BSR T_SOUND_HALF_WAV_A      ; 8+(A*8+20)    ; Csak A regiszter módosul
            LDAA PITCH_A                ; 3
            DECB                        ; 2
        BNE T_SOUND_AB_LOOP         ; 4
        DEC REPEAT_COUNTER       ; (REPEAT_COUNTER)--
    BNE T_SOUND_REPEAT              ; 4
    RTS                             ; 5

T_SOUND_PAUSE_1B: ; Ebben az esetben B csak egy hosszt határoz meg, amennyi ideig várakozni kell, és az (1)-ben van már tárolva
T_SOUND_PAUSE_REPEAT:
        LDAB SOUND_LENGTH_B
        LDAA #PAUSEA
T_SOUND_PAUSE_B_LOOP:                ; Egy kör hossza = 42+A*8 ciklus
        BSR T_SOUND_HALF_PAUSEA      ; 8+(PAUSEA*8+20)
        DECB                         ; 2
        BNE T_SOUND_PAUSE_B_LOOP     ; 4
        DEC REPEAT_COUNTER        ; (REPEAT_COUNTER)--
    BNE T_SOUND_PAUSE_REPEAT         ; 4
    RTS

T_SOUND_HALF_WAV_A:             ; =A*8+20     A hosszúságú félhullám    ; Csak A regiszter módosul
    NOP                         ; 2
    DECA                        ; 2
    BNE T_SOUND_HALF_WAV_A      ; 4
    BRA TOGGLE_SOUND_BIT        ; 4+16    ; Csak A regiszter módosul

T_SOUND_HALF_PAUSEA:            ; =PAUSEA*8+5 A hosszúságú félhullám
    NOP                         ; 2
    DECA                        ; 2
    BNE T_SOUND_HALF_PAUSEA     ; 4
    RTS                         ; 5

; A hanghoz a PB6 lábat kell írnunk
; 0 : AND 10111111 ( 0xBF, 191 )
; 1 :  OR 01000000 ( 0x40,  64 )

T_SOUND_NOISE_B::                ;
        STAB SOUND_LENGTH_B
        LDX #NOISE_START_ADDR
T_SOUND_NOISE_REPEAT:
        LDAB SOUND_LENGTH_B
T_SOUND_NOISE_B_LOOP:           ;
        INX
        LDAA 0,X
        ANDA #4
        BNE SKIP_TOGGLE
        BSR TOGGLE_SOUND_BIT         ;
SKIP_TOGGLE:
        DECB                         ; 2
        BNE T_SOUND_NOISE_B_LOOP     ; 4
        DEC REPEAT_COUNTER        ; (REPEAT_COUNTER)--
    BNE T_SOUND_NOISE_REPEAT         ; 4
    RTS

;SET_SOUND_BIT_HIGH:
;    LDAA DPORT   ; Beolvassuk a PB[0-7] értékét
;    ORAA #0x40   ; PB6 set 
;    STAA DPORT   ; Visszaírjuk
;    RTS
;
;SET_SOUND_BIT_LOW:
;    LDAA DPORT   ; Beolvassuk a PB[0-7] értékét
;    ANDA #0xBF   ; PB6 clear 
;    STAA DPORT   ; Visszaírjuk
;    RTS

TOGGLE_SOUND_BIT: ; = 16       ; Csak A regiszter módosul
    LDAA DPORT    ; 4 Beolvassuk a PB[0-7] értékét
    EORA #0x40    ; 2 PB6 toggle 
    STAA DPORT    ; 5 Visszaírjuk
    RTS           ; 5
