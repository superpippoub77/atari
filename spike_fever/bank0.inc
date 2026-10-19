; generato da gen_data.py: non modificare a mano
FrameOfs  .byte 0,12,24,36,48,60,72
ColOfs    .byte 0,0,0,12,0,12,24
NNAT = 10
NatColLo  .byte <[NatCols+0],<[NatCols+36],<[NatCols+72],<[NatCols+108],<[NatCols+144],<[NatCols+180],<[NatCols+216],<[NatCols+252],<[NatCols+288],<[NatCols+324],<[NatCols+360],<[NatCols+396],<[NatCols+432],<[NatCols+468],<[NatCols+504],<[NatCols+540],<[NatCols+576],<[NatCols+612],<[NatCols+648],<[NatCols+684]
NatColHi  .byte >[NatCols+0],>[NatCols+36],>[NatCols+72],>[NatCols+108],>[NatCols+144],>[NatCols+180],>[NatCols+216],>[NatCols+252],>[NatCols+288],>[NatCols+324],>[NatCols+360],>[NatCols+396],>[NatCols+432],>[NatCols+468],>[NatCols+504],>[NatCols+540],>[NatCols+576],>[NatCols+612],>[NatCols+648],>[NatCols+684]
ShirtCol  .byte $84,$82,$0C,$44,$1E,$46,$0E,$42,$02,$40
ArenaPtrs .byte <Bg0,>Bg0,<Pf00,>Pf00,<Pf10,>Pf10,<Pf20,>Pf20,<Pfc0,>Pfc0,<Bg1,>Bg1,<Pf01,>Pf01,<Pf11,>Pf11,<Pf21,>Pf21,<Pfc1,>Pfc1,<Bg2,>Bg2,<Pf02,>Pf02,<Pf12,>Pf12,<Pf22,>Pf22,<Pfc2,>Pfc2,<Bg3,>Bg3,<Pf03,>Pf03,<Pf13,>Pf13,<Pf23,>Pf23,<Pfc3,>Pfc3,<Bg4,>Bg4,<Pf04,>Pf04,<Pf14,>Pf14,<Pf24,>Pf24,<Pfc4,>Pfc4,<Bg5,>Bg5,<Pf05,>Pf05,<Pf15,>Pf15,<Pf25,>Pf25,<Pfc5,>Pfc5
ArenaBeach .byte 0,1,0,1,0,0
NARENA = 6
LevelNat  .byte 7,4,5,8,6,9
LevelArena .byte 0,1,2,3,4,5
NLEVEL = 6
FontLo
        .byte $0E,$0A,$0A,$0A,$0E,$04,$0C,$04,$04,$0E,$0E,$02,$0E,$08,$0E
        .byte $0E,$02,$06,$02,$0E,$0A,$0A,$0E,$02,$02,$0E,$08,$0E,$02,$0E
        .byte $0E,$08,$0E,$0A,$0E,$0E,$02,$04,$04,$04,$0E,$0A,$0E,$0A,$0E
        .byte $0E,$0A,$0E,$02,$0E
S_1P = 0
S_2P = 1
S_SC = 2
S_SEL = 3
S_P1 = 4
S_P2 = 5
S_FIRE = 6
S_ARENA = 7
S_VS = 8
S_OVER = 9
S_CONT = 10
S_CHAMP = 11
S_WIN = 12
S_AI = 13
S_STAGE = 14
S_NAT = 20
S_ARN = 30
JumpZ
        .byte $00,$01,$02,$03,$04,$05,$06,$06,$07,$07,$08,$08,$09,$09,$09,$09
        .byte $09,$09,$09,$09,$08,$08,$08,$07,$06,$06,$05,$04,$03,$02,$01,$00
