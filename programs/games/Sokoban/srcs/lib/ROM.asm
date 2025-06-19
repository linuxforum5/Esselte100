;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Esselte 100 ROM rutinok ( http://www.8bit-era.cz/6800.html )
;;; _ kezdetű címek erősen kérdésesek
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_ROM_PRINTA	== 0xF806    ; A értékét a képernyőre írja
_ROM_CURMOVE_BA	== 0xF863    ; A kurzor mozgatása B sor A oszlopba
ROM_KEY		== 0xF86C    ; Beolvassa a billentyűt, az ASCII kódját visszaadja A regiszterben, és ki is írja a képernyőre. Shift, SPACE, CTRL-t nem
ROM_KEYRC_AB	== 0xFE37    ; Beolvassa A-ba a lenyomott gomb sorát, B-be az oszlopát. Több gombot is észlel egyszerre.
ROM_FKBDTST	== 0x0830    ; Carry=1, ha le van nyomva kontroll billentyű, és A-ba a lenyomott kód. SPACE is kontroll, és az első SPACE-t ki is írja.
ROM_WAIT	== 0xF860    ; Vár (256*A+B)ms ideig
ROM_JRCL	== 0xF869    ; A veremből másol a képernyőre
ROM_JCLR	== 0xF86F    ; Töröl minden olyan karaktert a képernyőn, amelynek ASCIl kódja a következő értékek között van A és B között van.

ROM_BASIC	== 0xD000    ; Hideg BASIC restart
ROM_BASIC_WARM	== 0xD003    ; Meleg BASIC restart
ROM_RESET	== 0xF878    ; 
ROM_OUT		== 0xF857    ; ???

ROM_HEXASC	== 0xF149    ; Konvertálás ASCII-ből HEX-be. A-ban a bemenet és a kimenet
ROM_ASCHEX	== 0xF153    ; Konvertálás HEX-ből ASCII-be. A-ban a bemenet és a kimenet
_ROM_P2HEX_A	== 0xF13F    ; A értékének kiírása HEx-ként 2 karakterrel
ROM_PDATA	== 0xF132    ; A IX által jelzett karakterlánc írása egyig (04) : Skriv en strang so pekas ut av IX t o m ett (04)
ROM_PULSA	== 0xFBE6    ; ACCA st ACCB ms hosszú impulzusokat bocsát ki az A kimeneten
ROM_PULSB	== 0xFC0E    ; ACCA st ACCB ms hosszú impulzusokat bocsát ki a B kimeneten
ROM_SERIN	== 0xFC68    ; Soros karakter betöltése start bit beállítása nélkül
ROM_HEXBCD	== 0xFB9C    ; Egy 2 bájtos bináris számot lebegőpontos számmá konvertál pl. a következő kontextusban. USER, a bináris számnak [58,59] címeken kell lennie.

ROM_CLS			== 0xFDBB    ; Képernyőtörlés: kitöltés 0x20 kóddal, X és B elromlik 0x37 és 0x46 beállítása
ROM_PRINT_SPEC		== 0xFD4F    ; Speciális karakterkódok kiiratása (<32)
ROM_SCROLL_X		== 0xFD0E    ; Képernyőgorgetés X-től végig
ROM_SCROLL		== 0xFD03    ; Képernyőgörgetés, ha engedélyezve van, különben elejéreugrás
ROM_DIRECT_PRINT_A	== 0xFD26    ; A tartalmát a kurzorpozícióra ($46) írja, elemzés nélkül, kurzorpozíciót növel, de nem ellenőriz
ROM_PRINT_A		== 0xFCE3    ; A kiírása a képernyőre a környezeti beállítások szerint, kurzor nélkül
ROM_PRINT_A_CUR		== 0xFCBF    ; A kiírása a képernyőre a környezeti beállítások szerint, kurzorkezeléssel

; Memóriacímek

ROM_SCREEN_START	== 0x0047    ; A képernyőmemória kezdőcíme. Scroll esetén innentől scrolloz
ROM_CUR_POS		== 0x0046    ; A kurzor pozíciója
ROM_STATUS43		== 0x0043    ; Státuszbájt. 0.bit=1 esetén átlátszó képernyő, azaz speciális karakterek figyelmenkívülhagyása, 1.bit=Shift Lock eltávolítva, 4. bit=kurzor kikapcsolása
ROM_STATUS44		== 0x0044    ; Státuszbájt. 1.bit=Az APLUS és a BPLUS időalapjának módosítása
ROM_STATUS45		== 0x0045    ; Státuszbájt. Bitek jelentése: 7. Ha 0, akkor van screen scroll, ha 1, akkor nincs
