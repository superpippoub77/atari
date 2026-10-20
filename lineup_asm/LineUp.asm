; ============================================================================
;  LineUp! 2600 (prototype) - Atari 2600, 4K ROM, PAL
;  6502 assembly + TIA kernel base
; ============================================================================
        processor 6502
        include "vcs.h"
        include "macro.h"

STATE_TITLE = 0
STATE_PLAY  = 1
STATE_OVER  = 2

; -----------------------------------------------------------------------------
; RAM
; -----------------------------------------------------------------------------
        SEG.U vars
        ORG $80

State       ds 1
Level       ds 1
Lives       ds 1
Timer       ds 1
SecTick     ds 1
Cursor      ds 1
SelA        ds 1
SelB        ds 1
PairsFound  ds 1
TargetPairs ds 1
ColorMode   ds 1
Flags       ds 1        ; bit0 firePrev, bit1 upPrev, bit2 downPrev, bit3 added, bit4 shuffled
RandSeed    ds 1
BgColor     ds 1
Flash       ds 1
Tmp         ds 1
Tmp2        ds 1
Tmp3        ds 1
TmpMask     ds 1
TmpColor    ds 1
TmpRow      ds 1
ScoreLo     ds 1
ScoreHi     ds 1

RowLen      ds 8
RowTag      ds 8

; -----------------------------------------------------------------------------
; ROM
; -----------------------------------------------------------------------------
        SEG code
        ORG $F000

Reset:
        CLEAN_START
        lda #$A7
        sta RandSeed
        lda #1
        sta ColorMode
        jsr InitTitle

MainLoop:
        ; --- VSYNC ---
        lda #2
        sta WSYNC
        sta VSYNC
        sta WSYNC
        sta WSYNC
        lda #0
        sta VSYNC

        ; --- VBLANK ---
        lda #2
        sta VBLANK
        lda #43
        sta TIM64T

.vbwait
        lda INTIM
        bne .vbwait

        jsr UpdateLogic

        lda #0
        sta VBLANK

        ; --- visible 192 lines ---
        jsr DrawFrame

        ; --- overscan ---
        lda #2
        sta VBLANK
        lda #35
        sta TIM64T
.ovwait
        lda INTIM
        bne .ovwait

        jmp MainLoop

; -----------------------------------------------------------------------------
; LOGIC
; -----------------------------------------------------------------------------
UpdateLogic:
        ; background pulse
        inc BgColor
        lda BgColor
        and #$1F
        ora #$20
        sta COLUBK

        ; read up/down/fire (edge triggered)
        lda SWCHA
        and #$10
        bne .up_not
        lda Flags
        and #$02
        bne .up_done
        lda Flags
        ora #$02
        sta Flags
        jsr OnUpEdge
        jmp .up_done
.up_not
        lda Flags
        and #$FD
        sta Flags
.up_done

        lda SWCHA
        and #$20
        bne .down_not
        lda Flags
        and #$04
        bne .down_done
        lda Flags
        ora #$04
        sta Flags
        jsr OnDownEdge
        jmp .down_done
.down_not
        lda Flags
        and #$FB
        sta Flags
.down_done

        lda INPT4
        bmi .fire_not
        lda Flags
        and #$01
        bne .fire_done
        lda Flags
        ora #$01
        sta Flags
        jsr OnFireEdge
        jmp .fire_done
.fire_not
        lda Flags
        and #$FE
        sta Flags
.fire_done

        lda State
        cmp #STATE_PLAY
        bne .not_play

        ; 1 second tick (PAL 50hz)
        inc SecTick
        lda SecTick
        cmp #50
        bcc .no_sec
        lda #0
        sta SecTick
        lda Timer
        beq .timer_end
        dec Timer
        jmp .no_sec
.timer_end
        jsr LoseLife
.no_sec

        ; add distractor / shuffle thresholds
        lda Flags
        and #$08
        bne .chk_shuffle
        lda Timer
        cmp #70
        bcs .chk_shuffle
        jsr AddDistractor
        lda Flags
        ora #$08
        sta Flags

.chk_shuffle
        lda Flags
        and #$10
        bne .check_win
        lda Timer
        cmp #45
        bcs .check_win
        jsr ShuffleRows
        lda Flags
        ora #$10
        sta Flags

.check_win
        lda PairsFound
        cmp TargetPairs
        bcc .not_play
        jsr NextLevel
.not_play
        rts

OnUpEdge:
        lda State
        cmp #STATE_PLAY
        bne OnUpEdge_ret
        lda Cursor
        bne OnUpEdge_dec
        lda #7
        sta Cursor
        rts
OnUpEdge_dec
        dec Cursor
OnUpEdge_ret
        rts

OnDownEdge:
        lda State
        cmp #STATE_PLAY
        bne OnDownEdge_ret
        lda Cursor
        cmp #7
        bcc OnDownEdge_inc
        lda #0
        sta Cursor
        rts
OnDownEdge_inc
        inc Cursor
OnDownEdge_ret
        rts

OnFireEdge:
        lda State
        cmp #STATE_TITLE
        beq .start_game
        cmp #STATE_OVER
        beq .go_title
        ; gameplay select
        jsr HandleSelection
        rts
.start_game
        jsr StartGame
        rts
.go_title
        jsr InitTitle
        rts

StartGame:
        lda #STATE_PLAY
        sta State
        lda #0
        sta ScoreLo
        sta ScoreHi
        lda #1
        sta Level
        lda #3
        sta Lives
        jsr SeedLevel
        rts

InitTitle:
        lda #STATE_TITLE
        sta State
        lda #0
        sta Flash
        lda #$28
        sta BgColor
        lda #0
        sta RowTag+0
        sta RowTag+1
        sta RowTag+2
        sta RowTag+3
        sta RowTag+4
        sta RowTag+5
        sta RowTag+6
        sta RowTag+7
        lda #2
        sta RowLen+0
        lda #3
        sta RowLen+1
        lda #4
        sta RowLen+2
        lda #5
        sta RowLen+3
        lda #6
        sta RowLen+4
        lda #5
        sta RowLen+5
        lda #4
        sta RowLen+6
        lda #3
        sta RowLen+7
        rts

NextLevel:
        inc Level
        lda Level
        cmp #101
        bcc .ok
        lda #100
        sta Level
.ok
        ; +1 vita ogni 5 livelli, cap a 3
        lda Level
        and #$04
        beq .seed
        lda Lives
        cmp #3
        bcs .seed
        inc Lives
.seed
        jsr SeedLevel
        rts

LoseLife:
        lda Lives
        beq .to_over
        dec Lives
        lda Lives
        beq .to_over
        jsr SeedLevel
        rts
.to_over
        lda #STATE_OVER
        sta State
        lda #20
        sta Flash
        rts

SeedLevel:
        lda #0
        sta PairsFound
        sta SecTick
        sta Flags
        lda #255
        sta SelA
        sta SelB
        lda #0
        sta Cursor

        lda #2
        sta TargetPairs
        lda Level
        cmp #26
        bcc .tp_ok1
        lda #3
        sta TargetPairs
.tp_ok1
        lda Level
        cmp #61
        bcc .tp_ok2
        lda #4
        sta TargetPairs
.tp_ok2

        lda #120
        sec
        sbc Level
        sbc Level
        bcs .tm_ok
        lda #30
.tm_ok
        cmp #30
        bcs .tm_set
        lda #30
.tm_set
        sta Timer

        ; pair 1
        jsr NextRand
        and #7
        clc
        adc #2
        sta RowLen+0
        sta RowLen+1
        lda #1
        sta RowTag+0
        sta RowTag+1

        ; pair 2
        jsr NextRand
        and #7
        clc
        adc #2
        sta RowLen+2
        sta RowLen+3
        lda #2
        sta RowTag+2
        sta RowTag+3

        lda TargetPairs
        cmp #3
        bcc .dist_45
        jsr NextRand
        and #7
        clc
        adc #2
        sta RowLen+4
        sta RowLen+5
        lda #3
        sta RowTag+4
        sta RowTag+5
        jmp .check_67
.dist_45
        jsr NextRand
        and #7
        clc
        adc #2
        sta RowLen+4
        lda #0
        sta RowTag+4
        jsr NextRand
        and #7
        clc
        adc #2
        sta RowLen+5
        lda #0
        sta RowTag+5

.check_67
        lda TargetPairs
        cmp #4
        bcc .dist_67
        jsr NextRand
        and #7
        clc
        adc #2
        sta RowLen+6
        sta RowLen+7
        lda #4
        sta RowTag+6
        sta RowTag+7
        rts
.dist_67
        jsr NextRand
        and #7
        clc
        adc #2
        sta RowLen+6
        lda #0
        sta RowTag+6
        jsr NextRand
        and #7
        clc
        adc #2
        sta RowLen+7
        lda #0
        sta RowTag+7
        rts

AddDistractor:
        ldx #4
.loop
        lda RowTag,x
        bne .next
        lda RowLen,x
        beq .next
        cmp #8
        bcs .next
        inc RowLen,x
        rts
.next
        inx
        cpx #8
        bne .loop
        rts

ShuffleRows:
        ; swap 0<->4, 1<->5, 2<->6, 3<->7
        ldx #0
.swlp
        lda RowLen,x
        sta Tmp
        txa
        clc
        adc #4
        tay
        lda RowLen,y
        sta RowLen,x
        lda Tmp
        sta RowLen,y

        lda RowTag,x
        sta Tmp
        lda RowTag,y
        sta RowTag,x
        lda Tmp
        sta RowTag,y

        inx
        cpx #4
        bne .swlp
        rts

HandleSelection:
        ldx Cursor
        lda RowLen,x
        beq HandleSelection_ret

        lda SelA
        cmp #255
        bne HandleSelection_have_a
        stx SelA
        rts
HandleSelection_have_a
        cpx SelA
        bne HandleSelection_set_b
        lda #255
        sta SelA
        rts
HandleSelection_set_b
        stx SelB
        jsr CheckPair
        lda #255
        sta SelA
        sta SelB
HandleSelection_ret
        rts

CheckPair:
        ldx SelA
        ldy SelB

        lda RowLen,x
        sta Tmp
        lda RowLen,y
        cmp Tmp
        bne .wrong

        lda RowTag,x
        beq .wrong
        sta Tmp2
        lda RowTag,y
        beq .wrong
        cmp Tmp2
        bne .wrong

        ; color mode check (row/2 modulo ColorMode)
        jsr RowColorA
        sta Tmp
        jsr RowColorB
        cmp Tmp
        bne .wrong

        lda #0
        sta RowLen,x
        sta RowTag,x
        lda #0
        sta RowLen,y
        sta RowTag,y
        inc PairsFound

        ; score += timer
        clc
        lda ScoreLo
        adc Timer
        sta ScoreLo
        bcc .okflash
        inc ScoreHi
.okflash
        lda #8
        sta Flash
        rts

.wrong
        lda #16
        sta Flash
        jsr LoseLife
        rts

RowColorA:
        ldx SelA
        txa
        lsr
        jmp RowColorMod

RowColorB:
        ldx SelB
        txa
        lsr
        ; fallthrough
RowColorMod:
        ldx ColorMode
        cpx #1
        beq RowColorMod_ret0
RowColorMod_loop
        cmp ColorMode
        bcc RowColorMod_ret
        sec
        sbc ColorMode
        jmp RowColorMod_loop
RowColorMod_ret0
        lda #0
RowColorMod_ret
        rts

NextRand:
        lda RandSeed
        asl
        bcc .no_xor
        eor #$1D
.no_xor
        sta RandSeed
        rts

; -----------------------------------------------------------------------------
; DRAW
; -----------------------------------------------------------------------------
DrawFrame:
        ; top blank area (24 lines)
        lda #0
        sta PF1
        sta PF2
        sta COLUPF
        ldx #24
.top
        sta WSYNC
        dex
        bne .top

        ; rows: 8 * 18 lines = 144
        ldx #0
.row_loop
        stx TmpRow
        lda RowLen,x
        tay
        lda LenMask,y
        sta TmpMask

        lda RowColors,x
        sta TmpColor

        lda State
        cmp #STATE_PLAY
        bne .row_color_done
        ldx TmpRow
        cpx Cursor
        bne .chk_sel_a
        lda #$0E
        sta TmpColor
        jmp .row_color_done
.chk_sel_a
        cpx SelA
        beq .sel_color
        cpx SelB
        bne .row_color_done
.sel_color
        lda #$1E
        sta TmpColor
.row_color_done

        ldy #18
.row_scan
        sta WSYNC
        lda TmpColor
        sta COLUPF
        lda TmpMask
        sta PF1
        lda #0
        sta PF2
        dey
        bne .row_scan

        ldx TmpRow
        inx
        cpx #8
        bne .row_loop

        ; bottom blank area (24 lines)
        lda #0
        sta PF1
        sta PF2
        ldx #24
.bot
        sta WSYNC
        dex
        bne .bot

        ; flash feedback on background
        lda Flash
        beq .done_flash
        dec Flash
        lda State
        cmp #STATE_OVER
        bne .not_over_flash
        lda #$46
        sta COLUBK
        rts
.not_over_flash
        lda Flash
        and #1
        bne .flash_red
        lda #$2A
        sta COLUBK
        rts
.flash_red
        lda #$44
        sta COLUBK
        rts
.done_flash
        lda BgColor
        and #$1F
        ora #$20
        sta COLUBK
        rts

; -----------------------------------------------------------------------------
; tables
; -----------------------------------------------------------------------------
LenMask:
        .byte $00,$80,$C0,$E0,$F0,$F8,$FC,$FE,$FF

RowColors:
        .byte $1E,$1E,$3C,$3C,$5A,$5A,$98,$98

; -----------------------------------------------------------------------------
; vectors
; -----------------------------------------------------------------------------
        ORG $FFFC
        .word Reset
        .word Reset
