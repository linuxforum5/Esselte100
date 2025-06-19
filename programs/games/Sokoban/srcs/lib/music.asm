; http://bigdogi.gportal.hu/gindex.php?pg=1307681
; Manók tánca:
; e'8 e'8 f'8 | g'8 a'8 a'8 | a'4. |
; a'8 g'8 f'8 | g'8 a'8 a'8 | a'4. |
; a'8 g'8 f'8 | e'8 e'8 d'8 | c'8 d'8 e'8 | e'4. ||
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Zenelejátszó modul
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .area MUSIC  ( REL )

    .globl T_SOUND_AB

PLAY_MUSIC_X::
1$:
    LDAA 0,X
    BEQ 2$
    INX
    LDAB 0,X
    INX
    ;STX 12
    JSR T_SOUND_AB
    ;LDX 12
    BRA 1$
2$:
    RTS

;REPED:
;    NOP
;    BRA REPED
