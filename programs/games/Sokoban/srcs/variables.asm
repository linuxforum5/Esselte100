;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Munkaváltozók. Ezeket a területeket nem kell betölteni, csak működés közben kerülnek felhasználásra
; http://www.8bit-era.cz/6800.html
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .area MAIN ( REL )

;;; Ideiglenes változók memóriacímei:
;PITCH_A          .equ 0 ;         tape_sound  Itt tároljuk a hang A-ban megadott magasságát
;SOUND_LENGTH_B   .equ 1 ;         tape_sound  Itt tároljuk a hang B-ben megadott hosszát
;REPEAT_COUNTER   .equ 2 ;         tape_sound  Itt tároljuk az ismétlődések aktuélis számát, ez ideiglenes változó, a hang alatt csökken
TMP                 == 3 ; [3-4]   stone  Ideiglenes tároló egy cím számára (CHANGE_PUSH_COUNTER_IF_NEED_A_B)
UNDER_STONE         == 5 ; [5]     stone  Az aktuálisan eltolt kő alatti karakter SPACE_CHR vagy PLACE_CHR
UNDER_PLAYER        == 6 ; [6]     player
MOVE_COUNTER        == 7 ; [7-8]   player
PLAYER_LAST_POS     == 9 ; [9-10]   player.undo A játékos előző pozíciója (16 bit)
PLAYER_LAST_CHR     == 11; [11]     player.undo A játékos mostani pozícióján az előtte ott lévő karakter
OLD_PUSH_LAST_CHR   == 12; [12]     player.undo A PUSH_COUNTER utolsó számjegye a tolás előtt
PLACED_LAST_COUNTER == 13; [13]    player.undo A PLACED_COUNTER előző értéke
STONE_LAST_CHR      == 14; [14]    player.undo Ha volt eltolt kő az alatta levő előző karakter
STONE_NEXT_POS      == 15; [15-16] player.undo A lépés irányában a következő pozícióban a lépés előtt tartózkodó karakter. Ez vagy SPACE_CHR vagy PLACE_CHR lehet
CURRENT_LEVEL       == 17; [17]    level
CURRENT_X           == 18; [18]    level
CURRENT_Y           == 19; [19]    level
MAX_X               == 20; [20]    level
MAX_Y               == 21; [21]    level
CURRENT_LEVEL_DATA  == 22; [22-23] level
NEXT_LEVEL_DATA     == 24; [24-25] level
SCREENPOS           == 26; [26-27] level
COUNTER             == 28; [28]    level
PLAYER_POS          == 29; [29-30] level
PLACE_COUNTER       == 31; [31]    level
PLACED_COUNTER      == 32; [32]    level
LEVEL_FINISHED      == 33; [33]    level
COPY_FROM           == 34; [34-35] copy Másolandó adatok forráscíme
COPY_TO             == 36; [36-37] copy Másolandó adatok célcíme
CTRL_REPEAT_COUNTER == 38; [38-39] control Az automatikus billentyűismétléshez a számláló
;;; AJOY ;;;
AJOY_A_X            == 40; [40]    ajoy Az utoljára mért X érték
AJOY_A_Y            == 41; [41]    ajoy Az utoljára mért Y érték
AJOY_A_FIRE         == 42; [42]    ajoy 1, ha FIRE1 vagy FIRE2 be volt nyomva, különben 0. Lehet 2 is, ha mindkettő le volt nyomva
