; ============================================================================ BANCO 0: titolo
;  Logo grande SPIKE / FEVER (playfield asimmetrico sfumato, come la versione 16K), quadro animato
;  (lo schiacciatore rincorre, salta e schiaccia; il muro salta contro di lui), menu con le scritte
;  della modalita' scelta con GAME SELECT, PUSH FIRE che lampeggia.
;  Pulsante o GAME RESET: partita. Dopo una decina di secondi senza tasti: dimostrazione.
;  Usa la RAM della partita (che si riazzera quando parte): puntatori delle scritte in ScoreGfx..temp2,
;  puntatori del quadro in P0Ptr..P1Col, P0D/P1D/BlD.
; ============================================================================
        ORG $0000
        RORG $F000

T0P     = ScoreGfx              ; 6 puntatori alle colonne della scritta (12 byte contigui)
TCP     = BgPtr                 ; puntatore ai colori della scritta
tRows   = Pf0Ptr
tLines  = Pf0Ptr+1
PICP    = 32                    ; coppie di righe del quadro
PFLOOR  = 4                     ; coppia dei piedi nel quadro

ColdStart:
        CLEAN_START
        lda #$A7
        sta rand
TitleEntry:
        ldx #$FF
        txs
        lda mode                ; nel titolo il campionato riparte dal livello 1
        and #7
        sta mode
        lda #0
        sta AUDV0
        sta AUDV1
        sta idle
        sta frame
        sta REFP0
        sta sndT0
        sta fireOld             ; (A = 0) il pulsante deve essere rilasciato prima di partire
        lda #2
        sta selOld

TitleLoop:
        lda #2
        sta WSYNC
        sta VSYNC
        sta WSYNC
        sta WSYNC
        lda #43
        sta TIM64T
        sta WSYNC
        lda #0
        sta VSYNC
        jsr TitleLogic
        jsr PicSetup
.vb     lda INTIM
        bne .vb
        sta WSYNC
        sta VBLANK
        lda #228                ; 192 righe visibili (si aspetta il timer alla fine)
        sta TIM64T

        lda #1
        jsr Blank
        lda #0                  ; SPIKE
        ldy #0
        jsr SetLogo
        lda #1                  ; FEVER
        ldy #1
        jsr SetLogo
        jsr Stripe

; quadro: 32 coppie di righe
        lda #1
        sta CTRLPF              ; playfield riflesso: la rete al centro
        ldy #PICP-1
.pl     sta WSYNC               ; --- riga A: fondo, rete, giocatore sinistro
        lda PicBg,y
        sta COLUBK
        lda PicPf2,y
        sta PF2
        lda PicPfc,y
        sta COLUPF
        lda #PH-1
        dcp P0D
        bcs .a
        lda #0
        sta GRP0
        beq .b
.a      lda (P0Ptr),y
        sta GRP0
        lda (P0Col),y
        sta COLUP0
.b      sta WSYNC               ; --- riga B: giocatore destro e palla
        lda #PH-1
        dcp P1D
        bcs .c
        lda #0
        sta GRP1
        lda #WHITE
        sta COLUP1
        bne .d
.c      lda (P1Ptr),y
        sta GRP1
        lda (P1Col),y
        sta COLUP1
.d      lda #0
        cpy BlD
        bne .e
        lda #2
.e      sta ENAM1
        dey
        bpl .pl
        sta WSYNC
        lda #0
        sta GRP0
        sta GRP1
        sta ENAM1
        sta PF2
        sta COLUBK
        sta CTRLPF
        jsr Stripe

; menu: modalita' scelta con GAME SELECT
        lda mode
        and #2
        lsr
        ldy #0                  ; 1 PLAYER / 2 PLAYERS, bianco
        jsr Text
        lda #1
        jsr Blank
        lda mode
        and #4
        lsr
        lsr
        clc
        adc #2
        ldy #1                  ; 4 VS 4 / 2 VS 2, giallo
        jsr Text
        lda #1
        jsr Blank
        lda mode                ; 1 PLAYER al palazzetto: WORLD CUP (campionato), se no INDOOR / BEACH, azzurro
        and #3
        beq .wc
        lda mode
        and #1
        clc
        adc #4
        .byte $2C               ; (salta lda #7)
.wc     lda #7
        ldy #3
        jsr Text
        lda #2
        jsr Blank
        lda frame
        and #32
        beq .nofire
        lda #6                  ; PUSH FIRE (lampeggia)
        ldy #2
        jsr Text
.nofire
.vis    lda INTIM
        bne .vis
        sta WSYNC
        lda #2
        sta VBLANK
        lda #35
        sta TIM64T
.os     lda INTIM
        bne .os
        jmp TitleLoop

; ---------------------------------------------------------------- ingresso dal banco 1
B0Entry:
        ldx #$FF
        txs
        lda req
        bne NewGame0
        jmp TitleEntry
; nuova partita: punteggi e posizioni, poi la partita nel banco 1
NewGame0:
        ldx #$FF
        txs
        lda #8
        sta REFP1               ; la squadra destra guarda a sinistra
        lda #0
        sta score
        sta score+1
        sta server
        sta AUDV0
        sta AUDV1
        sta msg
        lda #$FF
        sta winner
        ; campionato: arena del livello e scritta LEVEL n (poi VS squadra)
        jsr Champ0
        bcc .nc
        tax
        lda mode
        and #$FA                ; spiaggia: sempre 2 contro 2 (bit 0 e 2), se no 4 contro 4
        ora LevBeach,x
        sta mode
        txa
        adc #MSG_LEVEL-1        ; (C = 1)
        sta msg
        lda #100
        sta showT
.nc     ldx #3
.pos    lda HomeX0,x
        sta px,x
        dex
        bpl .pos
        jsr StartServe
        jmp ToBank1b

; ---------------------------------------------------------------- logica del titolo
TitleLogic  SUBROUTINE
        inc frame
        lda rand
        lsr
        bcc .ne
        eor #$B4
.ne     sta rand
        lda frame
        and #63
        bne .ni
        inc idle
.ni     ; GAME SELECT (quando viene premuto): modalita' successiva
        lda SWCHB
        and #2                  ; 0 = premuto
        tax
        cmp selOld
        stx selOld
        beq .nsel
        txa
        bne .nsel
        lda mode                ; modalita' successiva (in spiaggia sempre 2 contro 2)
        and #7
        tax
        lda NextMode0,x
        sta mode
        lda #0
        sta idle
.nsel   ; pulsante (quando viene premuto, dopo un rilascio) o GAME RESET: partita
        lda INPT4
        and #$80                ; 0 = premuto
        tax
        cmp fireOld
        stx fireOld
        beq .nf
        txa
        beq .go
.nf     lda SWCHB
        lsr
        bcs .nr
.go     lda #0
        sta demo
        lda mode                ; 1 PLAYER al palazzetto: campionato (bit 3)
        and #3
        bne .nw
        lda #8
        sta mode
.nw     jmp NewGame0
.nr     ; dimostrazione dopo ~10 secondi
        lda idle
        cmp #10
        bcc .snd
        lda #1
        sta demo
        jmp NewGame0
.snd    ; suoni del quadro: schiacciata e palla a terra
        lda sndT0
        beq .s0
        dec sndT0
        rts
.s0     sta AUDV0
        rts

; ---------------------------------------------------------------- quadro animato (ciclo di 128 fotogrammi)
PicSetup  SUBROUTINE
        lda frame
        and #127
        sta temp4               ; t
        ; schiacciatore: rincorsa (0-31), salto (32-59), poi fermo
        cmp #32
        bcs .j0
        clc
        adc #20
        sta temp3               ; x
        lda temp4
        lsr
        lsr
        and #3
        clc
        adc #PIC_RUN
        tay
        lda #0
        beq .p0
.j0     lda #52
        sta temp3
        lda temp4
        cmp #60
        bcs .st0
        sec
        sbc #32
        tax
        lda JumpH,x
        pha
        ldy #PIC_JUMP
        cpx #12
        bcc .h0
        ldy #PIC_SPIKE
        cpx #18
        bcc .h0
        ldy #PIC_FALL
.h0     pla
        jmp .p0
.st0    ldy #PIC_STAND
        lda #0
.p0     ; A = altezza, Y = posa, temp3 = x
        clc
        adc #PFLOOR
        sta temp                ; coppia piu' bassa
        lda #PICP
        sec
        sbc temp
        sta P0D
        lda TFrame,y
        clc
        adc #<TGfx
        sta temp2
        lda #>TGfx
        adc #0
        pha
        lda temp2
        sec
        sbc temp
        sta P0Ptr
        pla
        sbc #0
        sta P0Ptr+1
        lda TUp,y
        clc
        adc #<TCols0
        sta temp2
        lda #>TCols0
        adc #0
        pha
        lda temp2
        sec
        sbc temp
        sta P0Col
        pla
        sbc #0
        sta P0Col+1
        lda temp3
        ldx #0
        jsr PosObj
        ; muro: salta (36-63), se no fermo
        lda temp4
        cmp #36
        bcc .st1
        cmp #64
        bcs .st1
        sbc #35                 ; (carry 0: -36)
        tax
        lda JumpH,x
        ldy #PIC_BLOCK
        bne .p1
.st1    lda #0
        ldy #PIC_STAND
.p1     clc
        adc #PFLOOR
        sta temp
        lda #PICP
        sec
        sbc temp
        sta P1D
        lda TFrame,y
        clc
        adc #<TGfx
        sta temp2
        lda #>TGfx
        adc #0
        pha
        lda temp2
        sec
        sbc temp
        sta P1Ptr
        pla
        sbc #0
        sta P1Ptr+1
        lda TUp,y
        clc
        adc #<TCols1
        sta temp2
        lda #>TCols1
        adc #0
        pha
        lda temp2
        sec
        sbc temp
        sta P1Col
        pla
        sbc #0
        sta P1Col+1
        lda #8
        sta REFP1               ; il muro guarda a sinistra
        lda #$10
        sta NUSIZ1              ; palla (missile 1) larga 2
        lda #0
        sta NUSIZ0
        lda #90
        ldx #1
        jsr PosObj
        ; palla: alzata fino alla mano (0-43), schiacciata (44-55), rotola (56-79), poi sparisce
        lda temp4
        cmp #44
        bcs .b1
        lsr
        lsr
        sta temp
        lda temp4
        sec
        sbc temp                ; x = 28 + 3/4 t
        clc
        adc #28
        sta temp3
        lda temp4
        lsr
        clc
        adc #8
        sta BlD                 ; coppia
        jmp .bpos
.b1     cmp #56
        bcs .b2
        cmp #44
        bne .b1s
        ldx #0                  ; colpo della schiacciata
        jsr Snd
        lda temp4
.b1s    sec
        sbc #44
        sta temp
        asl
        asl
        clc
        adc temp                ; 5 * (t-44)
        adc #61
        sta temp3
        lda temp
        asl
        sta temp
        lda #30
        sec
        sbc temp
        sta BlD
        jmp .bpos
.b2     cmp #80
        bcs .bhide
        cmp #56
        bne .b2n
        ldx #1                  ; palla a terra
        jsr Snd
        lda temp4
.b2n    clc
        adc #65                 ; rotola verso destra
        sta temp3
        lda #PFLOOR
        sta BlD
        jmp .bpos
.bhide  lda #255
        sta BlD
        lda #0
        sta temp3
.bpos   lda temp3
        ldx #3
        jsr PosObj
        sta WSYNC
        sta HMOVE
        rts

; suono X: 0 schiacciata, 1 palla a terra
Snd     lda SndC0,x
        sta AUDC0
        lda SndF0,x
        sta AUDF0
        lda #10
        sta AUDV0
        lda #6
        sta sndT0
        rts
SndC0   .byte $08, $0C
SndF0   .byte $06, $14

; posizione orizzontale: A = x, X = oggetto (0 P0, 1 P1, 2 M0, 3 M1, 4 palla)
PosObj  SUBROUTINE
        sta WSYNC
        sec
.d      sbc #15
        bcs .d
        eor #7
        asl
        asl
        asl
        asl
        sta HMP0,x
        sta RESP0,x
        rts

; ---------------------------------------------------------------- scritte (playfield asimmetrico)
; A righe vuote
Blank   SUBROUTINE
        tax
.b      sta WSYNC
        dex
        bne .b
        rts

Stripe  SUBROUTINE
        sta WSYNC
        lda #$2A                ; filetto arancio
        sta COLUBK
        sta WSYNC
        lda #0
        sta COLUBK
        sta WSYNC
        rts

; scritta A, colore Y, righe alte 2 linee (chiamata appena dopo un WSYNC: prepara in ~1,3 righe)
Text    SUBROUTINE
        tax
        lda #2
        sta tLines
        lda #5
        sta tRows
        lda ColTabLo,y
        sta TCP
        lda ColTabHi,y
        sta TCP+1
        lda StrHi,x
        sta T0P+1
        lda StrLo,x
        ldx #5
        bne SetCols

; logo A (0 SPIKE, 1 FEVER), sfumatura Y
SetLogo SUBROUTINE
        tax
        lda #3
        sta tLines
        lda #9
        sta tRows
        lda LogoCLo,y
        sta TCP
        lda LogoCHi,y
        sta TCP+1
        lda LogoHi,x
        sta T0P+1
        lda LogoLo,x
        ldx #9
; puntatori delle 6 colonne: A = inizio, X = passo (le tabelle non attraversano pagine: alto fisso)
SetCols SUBROUTINE
        stx temp3
        sta T0P
        clc
        adc temp3
        sta T0P+2
        adc temp3
        sta T0P+4
        adc temp3
        sta T0P+6
        adc temp3
        sta T0P+8
        adc temp3
        sta T0P+10
        lda T0P+1
        sta T0P+3
        sta T0P+5
        sta T0P+7
        sta T0P+9
        sta T0P+11
; righe della scritta (tRows righe da tLines linee); colore all'inizio di ogni linea
DrawRows  SUBROUTINE
        ldy #0
.row    ldx tLines
.line   sta WSYNC               ; 0
        lda (TCP),y             ; 5
        sta COLUPF              ; 8
        lda (T0P),y             ; 13
        sta PF0                 ; 16
        lda (T0P+2),y           ; 21
        sta PF1                 ; 24
        lda (T0P+4),y           ; 29
        sta PF2                 ; 32
        lda (T0P+6),y           ; 37
        sta PF0                 ; 40  (28..49)
        lda (T0P+8),y           ; 45
        sta PF1                 ; 48  (39..54)
        lda (T0P+10),y          ; 53
        sta PF2                 ; 56  (50..65)
        dex                     ; 58
        bne .line               ; 61
        iny                     ; 62
        cpy tRows               ; 65
        bne .row                ; 68 -> ldx 71, WSYNC 74
        sta WSYNC
        lda #0
        sta PF0
        sta PF1
        sta PF2
        rts

LogoLo  .byte <LogoA, <LogoB
LogoHi  .byte >LogoA, >LogoB
LogoCLo .byte <LogoCol, <LogoCol2
LogoCHi .byte >LogoCol, >LogoCol2
HomeX0  .byte 28, 12, 84, 140
; GAME SELECT: WORLD CUP (0), 1 PLAYER in spiaggia (5), 2 PLAYERS 4c4 (2), 2c2 (6), in spiaggia (7)
NextMode0 .byte 5, 5, 6, 6, 5, 2, 7, 0

        include "title.inc"
        include "logic.asm"

        ORG $0FD3
        RORG $FFD3
        jsr Logic               ; chiamata dal banco 1 (FarLogic)
        lda $FFF9               ; -> banco 1, $FFD9: rts
        ORG $0FE0
        RORG $FFE0
ToBank0b lda $FFF8              ; (stessi indirizzi del banco 1)
        jmp B0Entry             ; $FFE3: arrivo dal banco 1
ToBank1b lda $FFF9              ; -> banco 1, $FFE9: jmp GameEntry
        nop
        nop
        nop
Start0  lda $FFF8               ; accensione
        jmp ColdStart           ; $FFEF
        ORG $0FFC
        RORG $FFFC
        .word Start0
        .word Start0
