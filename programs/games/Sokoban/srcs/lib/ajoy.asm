;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Analóg joystick kezelő modul.
;;; Az ESSELTE 100-hoz két Joy kapcsolható. Az egyik az A, a másik a B porton.
;;; Ez a modul az A joystickot kezeli, minimális funkciókkal, azaz 4 irány és tűz, ami alatt az irányérzékelés nem aktív.
;;; 
;;; A joy az IN A bemenetre van kötve, azaz a PB4 és CA1
;;; A joy állapotát a PB4 láb olvasásával tudjuk kiértékelni. + élhossz=X, - élhossz=Y
;;; PIA2
;;; Címtartomány 0xC800-0xC80F
;;; A3=1
;;; A2=*
;;; A3 A2 A1 A0    Cím Megcímezve
;;; 1  *  0   0 0xC808   PA
;;; 1  *  0   1 0xC809   CRA/DDRA
;;; 1  *  1   0 0xC80A   PB         ; 0. 1.:Tape load in 2. 3. 4. 5. 6.:Tape sound out 7.
;;; 1  *  1   1 0xC80B   CRB/DDRB
;;; PB port bitjei:
;;; 0. -> Keyboard col bit 0
;;; 1. -> Keyboard col bit 1
;;; 2. -> Keyboard col bit 2
;;; 3. -> Keyboard col bit 3
;;; 4. <- Serial port A input
;;; 5. <- Serial port B input
;;; 6. -> Tape save / sound 
;;; 7. <- Tape load
;;; http://www.8bit-era.cz/6800.html
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .area PIA ( REL )

    .globl AJOY_A_X, AJOY_A_Y,AJOY_A_FIRE ; variables
    .globl AJOY_FIRE_LIMIT ; From config

PIA2_DDRA       .EQU 0xC809   ; DDR
PIA2_CRA        .EQU PIA2_DDRA
PIA2_PA         .EQU 0xC808   ; PA port

PIA2_DDRB       .EQU 0xC80B   ; DDR
PIA2_PB         .EQU 0xC80A   ; PB port

AJOY_INIT::  ; -- Inicializálás --
    LDAA #0
;    STAA AJOY_A_X
;    STAA AJOY_A_Y
;    STAA AJOY_A_FIRE
    STAA PIA2_PB
	LDAA    PIA2_DDRB       ; DDRB beolvasása
	ANDA    #0b11101111     ; PB4 bemenetre (bit 4 = 0)
	STAA    PIA2_DDRB       ; DDRB visszaírása
;
;	LDAA    #%00000110      ; CA1 megszakítás engedélyezve, automatikus törlés BE
;	STAA    PIA2_CRA        ; CRA

	SEI
;	LDX AJOY_A_MEASURE_IRQ_HANDLER
;	STX 0xFFF8
;	CLI                     ; Megszakítások engedélyezése
	RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Az analóg joy mérése
;;; Visszatérő értékeke:
;;; - AJOY_A_X : Az X irányú eltolás: Középen=[70-80], Balra=[80-220], Jobbra=[10-70], Tűz=[0-5]
;;; - AJOY_A_Y : Az X irányú eltolás: Középen=[70-80], Balra=[80-220], Jobbra=[10-70], Tűz=[0-5]
;;; - AJOY_A_FIRE : 0=nincs tűz nyomva, 1=X vagy Y irányú tűz nyomva. 2=X és Y irányú tűz is nyomva
;;; - B regiszter : 0=nincs csatlakoztatva joy, különben van az AJOY_A_Y értéke
;;; Különben A értéke X ellenállásértéke, B pedig Y ellenállásrétéke.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
AJOY_A_MEASURE_AB::
	SEI
;;; A mérés azzal kezdődik, hogy megvárjuk a LOW jel végét
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Bevezető HIGH szint átugrása. Ha LOW szint van éppen, ez átugrásra kerül.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDAB #0
PREWAIT_HIGH:
	LDAA PIA2_PB              ; Port B olvasás (PB4)
	ANDA    #0b00010000       ; Maszkoljuk PB4-et
	BEQ     START_PRE_LOW     ; Ha 0, akkor vége a bevezető HIGH szintnek, biztos LOW-ban vagyunk
	INCB                      ; Számolunk egy "időegységet"
	BNE     PREWAIT_HIGH      ; Vissza újra olvasni
	RTS                       ; B=0: Ha fixen 1 volt 256 mérésen keresztül, akkor nincs joy hozzákötve
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Bevezető LOW szint átugrása
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START_PRE_LOW:                    ; Itt már biztos LOW szinzen vagyunk, de lehet, hogy nem a legelején
	LDAB #0
PREWAIT_LOW:
	LDAA PIA2_PB              ; Port B olvasás (PB4)
	ANDA    #0b00010000       ; Maszkoljuk PB4-et
	BNE     START_HIGH        ; Ha nem 0, akkoe vége a bevezető LOW szintnek
	INCB                      ; Számolunk egy "időegységet"
	BNE     PREWAIT_LOW       ; Vissza újra olvasni
	RTS                       ; B=0: Ha fixen 0 volt 256 mérésen keresztül, akkor nincs joy hozzákötve
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; HIGH szint mérése : Y
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START_HIGH:                       ; Itt már biztos HIGH és a legelején vagyunk
	LDAB #0
WAIT_HIGH:
	LDAA PIA2_PB              ; Port B olvasás (PB4)
	ANDA    #0b00010000       ; Maszkoljuk PB4-et
	BEQ     STORE_HIGH        ; Ha 0, akkor vége a HIGH szintnek
	INCB                      ; Számolunk egy "időegységet"
	BNE     WAIT_HIGH         ; Vissza újra olvasni, míg túl nem csordul
	RTS                       ; Ha itt lépünk ki, akkor nics joy vagy túl hosszú az impulzus
STORE_HIGH:
;	BSR CVX
;	LDAB TMP2+1
	STAB AJOY_A_Y              ; Elmentjük a mért értéket. A magas hossza az Y
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LOW szint mérése : X
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDAB #0
WAIT_LOW:
	LDAA PIA2_PB              ; Port B olvasás (PB4)
	ANDA    #0b00010000       ; Maszkoljuk PB4-et
	BNE     STORE_LOW         ; Ha nem 0, akkor vége a LOW szintnek
	INCB                      ; Számolunk egy "időegységet"
	BNE     WAIT_LOW          ; Vissza újra olvasni
STORE_LOW:
;	BSR CVX
;	LDAA TMP2+1
	STAB AJOY_A_X              ; Elmentjük a mért értéket
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Mérés befejezve
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	LDAA PIA2_PA              ; Port A olvasás → CA1 megszakítás flag törlése

	LDAA #0
	STAA AJOY_A_FIRE          ; CLR AJOY_A_FIRE ?
	LDAA AJOY_A_X
	CMPA #AJOY_FIRE_LIMIT
	BHI NOFIRE1      ; A > (AJOY_FIRE_LIMIT)
	INC AJOY_A_FIRE
NOFIRE1:
	LDAA AJOY_A_Y
	CMPA #AJOY_FIRE_LIMIT
	BHI NOFIRE2
	INC AJOY_A_FIRE
NOFIRE2:
	RTS	; Teszt idejére egyelőre csak szubrutin
