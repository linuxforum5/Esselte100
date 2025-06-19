
    .area MUSIC ( REL )

    .globl TSA_B3,TSB_B3,TSA_PAUSE,TSB_PAUSE
    .globl TSA_C4,TSB_C4,TSA_C_4,TSB_C_4,TSA_D4,TSB_D4,TSA_D_4,TSB_D_4,TSA_E4,TSB_E4,TSA_F4,TSB_F4,TSA_F_4,TSB_F_4,TSA_G4,TSB_G4,TSA_G_4,TSB_G_4,TSA_A4,TSB_A4,TSA_A_4,TSB_A_4,TSA_B4,TSB_B4
    .globl TSA_C5,TSB_C5,TSA_C_5,TSB_C_5,TSA_D5,TSB_D5,TSA_D_5,TSB_D_5,TSA_E5,TSB_E5,TSA_F5,TSB_F5,TSA_F_5,TSB_F_5,TSA_G5,TSB_G5,TSA_G_5,TSB_G_5,TSA_A5,TSB_A5,TSA_A_5,TSB_A_5,TSA_B5,TSB_B5

; c d e G e G
END_MUSIC_DATA::
	.db TSA_C4,TSB_C4        ; c
	.db TSA_D4,TSB_D4        ; d
	.db TSA_E4,TSB_E4        ; e
	.db TSA_G4,TSB_G4        ; g
	.db TSA_G4,TSB_G4        ; g
	.db TSA_E4,TSB_E4        ; e
	.db TSA_G4,TSB_G4        ; g
	.db TSA_G4,TSB_G4        ; g
	.db TSA_G4,TSB_G4        ; g
	.db TSA_G4,TSB_G4        ; g
	.db 0
