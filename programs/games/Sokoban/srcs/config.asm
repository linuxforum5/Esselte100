;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Konfigurációs beállítások
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .area LEVEL ( REL )

SPACE_CHR          == 0x20 ; ' '
STONE_CHR          == 0x4F ; 0x24 ; ***
PLACE_CHR          == 0x8A ; 0x0F ;
STONE_ON_PLACE_CHR == 0x30 ; 0x65 ; 0x2A ; ***
WALL_CHR           == 0x69 ; 0x69 ; ***
PLAYER_CHR         == 0x24 ; 0x09 ; 0xA4 ; 0x6A ; 0x0C ; 0x09 ; 0x68 ;
PLAYER2_CHR        == 0x2A ; 0x2B ; 0xFE ; 0x6D ; 0x09 ; 0x68 ;

SOKOBAN_FIRST_LINE_ON_SCREEN   == 0xC000
HELP_LINE_ON_SCREEN            == 0xC3E0
STATTEXT_COUNTERS_ON_SCREEN    == 0xC3C0
STATTEXT_LEVEL_ON_SCREEN       == 0xC0E0
STARTTEXT_FIRST_LINE_ON_SCREEN == 0xC0E0
MAZE_FIRST_ADDR                == 0xC140

MAX_LEVEL_NUM                  == 20 ; A szöveges kiírás nem ebből a kostansból megy sajna
CTRL_REPEAT_SPEED              == 1800; A billentyűismétlés sebessége. Ha nagyobb, akkor lassabb, de 0 a leglassabb (0 = 65536)

AJOY_FIRE_LIMIT                == 4 ; Ha ennél <= az érték, akkor az analog joy tűzgombja meg van nyomva
AJOY_MIN_LIMIT                 == 60 ; Ha ennél <= az érték, akkor az analog joy el van nyomva a kisebb ellenállású irányba
AJOY_MAX_LIMIT                 == 90 ; Ha ennél > az érték, akkor az analog joy el van nyomva a nagyobb ellenállású irányba

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVE_COUNTER_LAST_POSITION == STATTEXT_COUNTERS_ON_SCREEN+9
PUSH_COUNTER_LAST_POSITION == STATTEXT_COUNTERS_ON_SCREEN+20
PLACED_COUNTER_LAST_POSITION == STATTEXT_COUNTERS_ON_SCREEN+31 ; A már eddig helyretolt ládák száma
LEVEL_COUNTER_LAST_POSITION == STATTEXT_LEVEL_ON_SCREEN+12
