; http://www.8bit-era.cz/6800.html
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Hangeffektek összegyűjtve
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .area SEFFECTS ( REL )
    .globl INC_COUNTER_LAST_X ; From str-counter
    .globl TSB_REPEAT,T_SOUND_AB,TSA_C4,TSB_C4,TSA_E4,TSB_E4,TSA_C5,TSB_C5,TSA_C6,TSB_C6,T_SOUND_NOISE_B ; From tape_sound
    .globl END_MUSIC_DATA ; From music-data
    .globl PLAY_MUSIC_X ; From music

END_OF_LEVEL_EFFECT::
    ;LDAB TSB_REPEAT
    ;LDAA #8 ;
    ;STAA TSB_REPEAT
    LDX #END_MUSIC_DATA
    JSR PLAY_MUSIC_X
    ;STAB TSB_REPEAT
    RTS

SET_SOUND_SPEED_A:: ; Default 8
    STAA TSB_REPEAT
    RTS

STONE_TO_PLACE_EFFECT::
    LDAA #TSA_C5
    LDAB #TSB_C5
    JSR T_SOUND_AB
    LDAA #TSA_C6
    LDAB #TSB_C6
    JSR T_SOUND_AB
    RTS

STONE_FROM_PLACE_EFFECT::
    LDAA #TSA_C6
    LDAB #TSB_C6
    JSR T_SOUND_AB
    LDAA #TSA_C5
    LDAB #TSB_C5
    JSR T_SOUND_AB
    RTS

PLAYER_MOVE_SOUND::
    LDAB #5
    JSR T_SOUND_NOISE_B
    RTS
