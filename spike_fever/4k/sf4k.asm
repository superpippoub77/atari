; ============================================================================
;  SPIKE FEVER 2600 4K - pallavolo 4 contro 4 in stile POWER SPIKES per Atari 2600 (VCS), cartuccia da 4K
;  by SpikeCode AI
;
;  4 contro 4 come in Power Spikes: in prima linea CENTRALE, ALZATORE e SCHIACCIATORE (lo stesso sprite ripetuto
;  3 volte dal TIA, copie NUSIZ a 16 pixel), dietro il DIFENSORE (disegnato da solo). Le due linee si alternano a 30 Hz.
;    - BATTUTA (difensore): pulsante = lancio, di nuovo quando la palla diventa ROSSA = colpo
;               (joystick verso la rete = corta, verso il fondo = lunga);
;    - RICEZIONE: muovi il difensore sul segno giallo a terra, il bagher è automatico;
;    - ALZATA: GIÙ = primo tempo del centrale, VERSO IL FONDO = seconda linea del difensore, niente = palla alta;
;    - ATTACCO: premi quando la palla è ROSSA (verso la rete = corta, verso il fondo = lunga, su = pallonetto);
;    - MURO A TRE: quando attaccano gli avversari premi il pulsante.
;  GAME SELECT: 1 o 2 persone (cifra a sinistra), 4 o 2 giocatori per squadra (cifra a destra),
;               palazzetto (set a 15) o spiaggia (set a 21). GAME RESET: nuova partita.
;  2 contro 2: in prima linea solo l'alzatore; il difensore riceve e attacca a rete.
;  Levette di difficoltà: 4 livelli del computer (B B = 1, sinistra A = 2, destra A = 3, A A = 4).
;
;  KERNEL (area di gioco a 2 righe, 168 righe):
;    riga A: colore di fondo, PF0, PF1, giocatore sinistro (grafica e colore riga per riga), palla
;    riga B: PF2, colore del playfield, segno di caduta (missile 0), giocatore destro
;  In alto: titolo SPIKEFEVER in playfield asimmetrico oppure punteggio nei colori delle squadre.
;  La palla è il missile dello sprite che nel fotogramma mostra un giocatore solo; il segno di caduta è l'oggetto ball.
;  La palla è il missile 1 (colore ballCol: bianca, ROSSA quando bisogna colpire).
;  Compilazione: python3 gen_data.py > data.inc ; node build.js  -> spikefever2600.bin
; ============================================================================
        processor 6502
        include "vcs.h"
        include "macro.h"

PH      = 12            ; altezza dei giocatori (coppie di righe)
BH      = 2             ; altezza della palla
PAIRS   = 84            ; coppie di righe dell'area di gioco
FLOOR   = 8             ; coppia dei piedi
NETTOP  = 22            ; fascia alta della rete
HAND    = FLOOR+PH+1    ; altezza delle mani (palla in battuta, alzata)
HITH    = FLOOR+PH+9    ; altezza di colpo della schiacciata (in cima al salto)
DIGH    = FLOOR+5       ; altezza del bagher
GRAV    = $0D           ; gravità della palla (8.8 coppie/fotogramma²)
PGRAV   = $13           ; gravità dei giocatori
MARKROW = 5             ; coppia del segno di caduta
MARKCOL = $1E           ; giallo
WHITE   = $0E
RED     = $44

ST_SERVE = 0
ST_TOSS  = 1
ST_RALLY = 2
ST_POINT = 3
ST_OVER  = 4

NX_RECV = 0             ; prossimo tocco: bagher della squadra "team"
NX_SET  = 1             ;                 alzata
NX_HIT  = 2             ;                 attacco
NX_NONE = 3             ;                 nessuno (la palla cade)

; ---------------------------------------------------------------- RAM
        SEG.U vars
        ORG $80
frame   ds 1
rand    ds 1
mode    ds 1            ; bit0 = spiaggia, bit1 = due persone, bit2 = due contro due
demo    ds 1            ; 1 = dimostrazione (computer contro computer, titolo in alto)
state   ds 1
stateT  ds 1
score   ds 2
server  ds 1            ; squadra al servizio
winner  ds 1
next    ds 1
team    ds 1            ; squadra del prossimo tocco
fT      ds 1            ; fotogrammi dall'ultimo colpo
lastSide ds 1
tx      ds 1            ; bersaglio della traiettoria (x della palla)
th      ds 1            ; altezza d'arrivo
blockPend ds 1
aiErr   ds 1
setType ds 1            ; alzata: 0 palla alta (schiacciatore), 1 primo tempo (centrale), 2 seconda linea (difensore)
tHit    ds 1            ; fotogramma del colpo d'attacco
; giocatori: 0 alzatore sinistro, 1 attaccante sinistro, 2 alzatore destro, 3 attaccante destro
px      ds 4
pz      ds 4
pzf     ds 4
pvz     ds 4
pvzf    ds 4
animT   ds 4
pose    ds 4
anim    ds 4
moved   ds 4
tgt     ds 4
joy     ds 2            ; joystick per squadra: $80 destra, $40 sinistra, $20 giù, $10 su
press   ds 2            ; $80 = pulsante appena premuto
fireOld ds 2
bxl     ds 1
bxh     ds 1
byl     ds 1
byh     ds 1
bvxl    ds 1
bvxh    ds 1
bvyl    ds 1
bvyh    ds 1
ballCol ds 1
markX   ds 1
selOld  ds 1
showT   ds 1
sndT0   ds 1
sndT1   ds 1
P0Ptr   ds 2            ; puntatori del kernel (P0Ptr, P0Col, P1Ptr, P1Col in quest'ordine)
P0Col   ds 2
P1Ptr   ds 2
P1Col   ds 2
P0D     ds 1
P1D     ds 1
BlD     ds 1
MkD     ds 1
BgPtr   ds 2
Pf0Ptr  ds 2
Pf1Ptr  ds 2
Pf2Ptr  ds 2
PfcPtr  ds 2
ScoreGfx ds 10
temp    ds 1
temp2   ds 1
temp3   ds 1
temp4   ds 1
par     ds 1            ; parità del fotogramma (frame & 1)
m4      ds 1            ; mode & 4: 4 = due contro due
RAMEND

; ---------------------------------------------------------------- ROM
        SEG code
        ORG $F000

Reset:
        CLEAN_START
        lda #$A7
        sta rand
        lda #1
        sta demo
        lda #8
        sta REFP1               ; la squadra destra guarda a sinistra
        jsr NewGame

; ================================================================ ciclo principale
MainLoop:
        lda #2
        sta WSYNC
        sta VSYNC
        sta WSYNC
        sta WSYNC
        lda #45
        sta TIM64T
        sta WSYNC
        lda #0
        sta VSYNC

        jsr Setup

.vblank lda INTIM
        bne .vblank
        sta WSYNC
        sta VBLANK

; ---------------------------------------------------------------- parte alta: titolo o punteggio (24 righe)
        lda #$80
        sta COLUBK
        lda #0
        sta GRP0
        sta GRP1
        sta ENAM0
        sta ENAM1
        sta PF0
        sta PF1
        sta PF2
        sta WSYNC               ; riga 1 (la riga 2 resta vuota: la chiude il primo WSYNC del ciclo)
        lda demo
        beq .score
        lda showT
        bne .score
        lda #0
        sta CTRLPF
; titolo SPIKEFEVER: playfield asimmetrico, 5 righe di lettere alte 4 righe
        ldx #0
.trow   ldy #4
.tline  sta WSYNC               ; 0
        lda TCol,x              ; 4
        sta COLUPF              ; 7
        lda TL0,x               ; 11
        sta PF0                 ; 14
        lda TL1,x               ; 18
        sta PF1                 ; 21
        lda TL2,x               ; 25
        sta PF2                 ; 28
        lda TR0,x               ; 32
        sta PF0                 ; 35  (tra 28 e 49)
        lda TR1,x               ; 39
        sta PF1                 ; 42  (tra 39 e 54)
        nop                     ; 44
        lda TR2,x               ; 48
        sta PF2                 ; 51  (tra 50 e 65)
        dey
        bne .tline
        inx
        cpx #5
        bne .trow
        jmp .topDone

; punteggio: modo SCORE, metà sinistra col colore della squadra sinistra e viceversa
.score  lda #2
        sta CTRLPF
        ldx #0
.srow   ldy #4
.sline  sta WSYNC               ; 0
        lda ScoreGfx,x          ; 4
        sta PF1                 ; 7
        SLEEP 30                ; 37
        lda ScoreGfx+5,x        ; 41
        sta PF1                 ; 44  (metà destra)
        dey
        bne .sline
        inx
        cpx #5
        bne .srow

.topDone
        sta WSYNC               ; riga 23
        lda #0
        sta PF0
        sta PF1
        sta PF2
        lda #$31                ; playfield riflesso, oggetto "ball" largo 8 (segno di caduta)
        sta CTRLPF
        lda par                 ; la palla è il missile dello sprite che in questo fotogramma disegna un giocatore solo
        eor #1
        tax                     ; X = 1 (missile 1) nei fotogrammi pari, 0 (missile 0) nei dispari
        sta WSYNC               ; riga 24

; ---------------------------------------------------------------- area di gioco: 84 coppie di righe
        ldy #PAIRS-1
GameLoop:
        sta WSYNC               ; --- riga A
        lda (BgPtr),y           ; 5
        sta COLUBK              ; 8
        lda (Pf0Ptr),y          ; 13
        sta PF0                 ; 16
        lda (Pf1Ptr),y          ; 21
        sta PF1                 ; 24
        lda #PH-1               ; 26
        dcp P0D                 ; 31
        bcs .draw0              ; 33
        lda #0                  ; 35
        sta GRP0                ; 38
        lda ballCol             ; 41  (fuori dal giocatore: colore della palla)
        sta COLUP0              ; 44
        jmp .p0done             ; 46
.draw0  lda (P0Ptr),y           ; 39
        sta GRP0                ; 42
        lda (P0Col),y           ; 47
        sta COLUP0              ; 50
.p0done lda #BH-1               ; 52
        dcp BlD                 ; 57
        lda #0                  ; 59
        rol                     ; 61
        rol                     ; 63
        sta ENAM0,x             ; 67  palla (missile 0 o 1)
        sta WSYNC               ; --- riga B
        lda (Pf2Ptr),y          ; 5
        sta PF2                 ; 8
        lda (PfcPtr),y          ; 13
        sta COLUPF              ; 16
        lda #0                  ; 18
        dcp MkD                 ; 23
        lda #0                  ; 25
        rol                     ; 27
        rol                     ; 29
        sta ENABL               ; 32  segno di caduta (colore del playfield della coppia 5)
        lda #PH-1               ; 34
        dcp P1D                 ; 39
        bcs .draw1              ; 41
        lda #0                  ; 43
        sta GRP1                ; 46
        lda ballCol             ; 49
        sta COLUP1              ; 52
        dey                     ; 54
        bpl GameLoop            ; 57
        jmp .gameEnd
.draw1  lda (P1Ptr),y           ; 47
        sta GRP1                ; 50
        lda (P1Col),y           ; 55
        sta COLUP1              ; 58
        dey                     ; 60
        bpl GameLoop            ; 63
.gameEnd

; ---------------------------------------------------------------- fine immagine
        sta WSYNC
        lda #2
        sta VBLANK
        lda #0
        sta GRP0
        sta GRP1
        sta ENAM0
        sta ENAM1
        sta ENABL
        sta PF0
        sta PF1
        sta PF2
        lda #35
        sta TIM64T
        jsr Logic
.over   lda INTIM
        bne .over
        jmp MainLoop

; ================================================================ preparazione del fotogramma (VBLANK)
Setup  SUBROUTINE
        jsr Players
        ; scenario: 5 puntatori (fondo, PF0, PF1, PF2, colore PF) del palazzetto o della spiaggia
        lda mode
        and #1
        beq .ar
        lda #10
.ar     tay
        ldx #0
.arena  lda ArenaPtrs,y
        sta BgPtr,x
        iny
        inx
        cpx #10
        bne .arena
        ; 4 giocatori per squadra: la prima linea (centrale, alzatore, schiacciatore) è uno sprite ripetuto 3 volte
        ; dall'hardware (copie a 16 pixel), il difensore è disegnato da solo. Si alternano a ogni fotogramma:
        ; pari: P0 = prima linea sinistra, P1 = difensore destro; dispari: P0 = difensore sinistro, P1 = prima linea destra.
        ldx par
        ldy #0
        jsr SetupPlayer
        lda par
        eor #3
        tax
        ldy #1
        jsr SetupPlayer
        lda m4                  ; 2 contro 2: la prima linea è un giocatore solo (tabelle +2)
        lsr
        ora par
        tax
        lda Nusiz0,x
        sta NUSIZ0
        lda Nusiz1,x
        sta NUSIZ1
        ; palla
        lda #PAIRS
        sec
        sbc byh
        sta BlD
        ; punteggio: una squadra per fotogramma (si aggiorna in 2 fotogrammi, metà del tempo)
        ldx par
        jsr ScoreDigits
        lda mode
        and #1
        asl
        tay
        lda ShirtCol,y
        sta COLUP0
        lda ShirtCol+1,y
        sta COLUP1
        lda state
        cmp #ST_OVER
        bne .noBlink
        lda frame
        and #16
        beq .noBlink
        ldx winner
        lda #WHITE
        sta COLUP0,x
.noBlink
        ; posizioni orizzontali: P0, P1, segno (M0), palla (M1)
        ldx par
        lda px,x
        ldx #0
        jsr PosObject
        lda par
        eor #1
        tax
        lda px+2,x
        ldx #1
        jsr PosObject
        lda markX
        ldx #4
        jsr PosObject
        lda par
        eor #3                  ; palla: missile 1 nei fotogrammi pari, missile 0 nei dispari
        tax
        lda bxh
        jsr PosObject
        sta WSYNC
        sta HMOVE
        rts

; puntatori di grafica e colori: X = giocatore (0-3), Y = sprite (0 = P0, 1 = P1)
SetupPlayer  SUBROUTINE
        tya
        asl
        asl
        sta temp3               ; 0 per P0, 4 per P1
        lda pz,x
        clc
        adc #FLOOR
        sta temp                ; coppia più bassa
        lda #PAIRS
        sec
        sbc temp
        sta P0D,y
        lda anim,x
        tax
        lda ColOfs,x            ; tabella dei colori (pose normali o braccia in alto)
        pha
        lda FrameOfs,x
        sta temp2
        lda #<Gfx
        clc
        adc temp2
        sta temp4
        lda #>Gfx
        adc #0
        pha
        lda temp4
        sec
        sbc temp
        ldx temp3
        sta P0Ptr,x
        pla
        sbc #0
        sta P0Ptr+1,x
        pla
        sta temp2
        ; colori: arena*2 + squadra
        lda mode
        and #1
        asl
        sta temp4
        tya
        ora temp4
        tax
        lda ColSetLo,x
        clc
        adc temp2
        sta temp4
        lda ColSetHi,x
        adc #0
        pha
        lda temp4
        sec
        sbc temp
        ldx temp3
        sta P0Col,x
        pla
        sbc #0
        sta P0Col+1,x
        rts

; righe del punteggio della squadra X (decine nel nibble alto, zero iniziale nascosto)
ScoreDigits  SUBROUTINE
        lda score,x
        ldy showT
        beq .val
        cpx #0                  ; SELECT: a sinistra le persone (1/2), a destra i giocatori per squadra (4/2)
        bne .tgt
        lda mode
        and #2
        lsr
        adc #1                  ; (C = 0 dopo lsr di 0 o 2)
        bne .val
.tgt    lda m4
        eor #4
        lsr
        adc #2
.val    ldy #0
.div10  cmp #10
        bcc .gotD
        sbc #10
        iny
        bne .div10
.gotD   sta temp
        sty temp2
        txa
        beq .s0
        lda #5
.s0     sta temp3
        lda temp
        asl
        asl
        adc temp
        sta temp
        lda temp2
        asl
        asl
        adc temp2
        sta temp2
        lda #5
        sta temp4
.drow   ldy temp2
        beq .noT
        lda FontLo,y            ; decina: stessa cifra spostata nel nibble alto
        asl
        asl
        asl
        asl
        .byte $2C               ; (salta lda #0)
.noT    lda #0
        ldy temp
        ora FontLo,y
        ldy temp3
        sta ScoreGfx,y
        inc temp
        lda temp2
        beq .t0
        inc temp2
.t0     inc temp3
        dec temp4
        bne .drow
        rts

; posizionamento orizzontale: A = x, X = oggetto (0 P0, 1 P1, 2 M0, 3 M1, 4 palla)
PosObject  SUBROUTINE
        sec
        sta WSYNC
.divide sbc #15
        bcs .divide
        eor #7
        asl
        asl
        asl
        asl
        sta.wx HMP0,x
        sta RESP0,x
        rts

; ================================================================ logica (overscan)
Logic  SUBROUTINE
        inc frame
        lda frame
        and #1
        sta par
        lda rand
        lsr
        bcc .noEor
        eor #$B4
.noEor  sta rand
        jsr Console
        lda showT
        beq .nst
        dec showT
.nst    jsr ReadInput
        inc fT
        lda state
        cmp #ST_SERVE
        bne .n0
        jsr ServeState
        jmp .play
.n0     cmp #ST_TOSS
        bne .n1
        jsr TossState
        jmp .play
.n1     cmp #ST_RALLY
        bne .n2
        jsr RallyState
        jmp .play
.n2     inc stateT
        cmp #ST_POINT
        bne .n3
        lda stateT
        cmp #90
        bcc .play
        jsr AfterPoint
        jmp .play
.n3     lda stateT              ; fine partita: dopo qualche secondo torna la dimostrazione
        cmp #250
        bcc .play
        lda #1
        sta demo
        jsr NewGame
.play   jsr BallLook        ; (i giocatori si muovono nel VBLANK, dove c'è più tempo: vedi Setup)
        ; suoni
        lda sndT0
        beq .s0off
        dec sndT0
        bne .s1
.s0off  lda #0
        sta AUDV0
.s1     lda sndT1
        beq .s1off
        dec sndT1
        lda frame
        and #2
        lsr
        adc #3
        sta AUDF1
        rts
.s1off  lda #0
        sta AUDV1
        rts

; joystick e pulsanti delle due squadre (la squadra destra usa il secondo joystick)
ReadInput  SUBROUTINE
        lda SWCHA
        eor #$FF
        and #$F0
        sta joy
        lda SWCHA
        asl
        asl
        asl
        asl
        eor #$FF
        and #$F0
        sta joy+1
        ldx #1
.btn    lda INPT4,x
        eor #$80
        and #$80                ; $80 = premuto
        tay
        eor fireOld,x
        and #$80
        sta temp
        tya
        sta fireOld,x
        and temp
        sta press,x             ; $80 = appena premuto
        dex
        bpl .btn
        rts

; la squadra A è comandata da una persona? (Z = 0 sì)  usa temp4
Human  SUBROUTINE
        sta temp4
        lda demo
        bne .cpu
        lda temp4
        beq .yes
        lda mode
        and #2
        rts
.yes    lda #1
        rts
.cpu    lda #0
        rts

; GAME RESET e GAME SELECT
Console  SUBROUTINE
        lda SWCHB
        lsr
        bcs .noReset
        lda #0
        sta demo
        jmp NewGame
.noReset
        lsr
        lda #0
        rol
        eor #1
        tax
        cpx selOld
        stx selOld
        beq .cdone
        cpx #1
        bne .cdone
        inc mode
        lda mode
        and #7
        sta mode
        and #4
        sta m4
        lda #150
        sta showT
        lda #1
        sta demo
        jmp NewGame
.cdone  rts

NewGame  SUBROUTINE
        lda #0
        sta score
        sta score+1
        sta server
        lda #$FF
        sta winner
        ldx #3
.pos    lda HomeX,x
        sta px,x
        dex
        bpl .pos
StartServe
        lda #ST_SERVE
        jsr Halt
        sta fT
        lda server
        sta lastSide
        rts

; nuovo stato A, palla ferma, nessun tocco atteso (esce con A = 0)
Halt    sta state
        lda #NX_NONE
        sta next
        lda #0
        sta stateT
        sta blockPend
        sta bvxl
        sta bvxh
        sta bvyl
        sta bvyh
        rts

; dopo la pausa del punto: fine set o nuova battuta
AfterPoint  SUBROUTINE
        lda mode
        and #1
        tay
        ldx server
        lda score,x
        cmp TargetPts,y
        bcc .goOn
        txa
        eor #1
        tay
        lda score,x
        sec
        sbc score,y
        cmp #2
        bcc .goOn
        stx winner
        lda #ST_OVER
        jmp Halt
.goOn   jmp StartServe

; punto alla squadra A (rally point: batte chi fa il punto)
Point  SUBROUTINE
        tax
        inc score,x
        stx server
        lda #ST_POINT
        jsr Halt
        lda demo
        bne .quiet
        lda #4
        sta AUDC1
        lda #10
        sta AUDV1
        lda #45
        sta sndT1
.quiet  rts

; suono sul canale 0: Y = 0 bagher e alzata, 1 schiacciata e muro, 2 rete/terra, 3 battuta e lancio
Sound  SUBROUTINE
        lda demo
        bne .nos
        lda SndC,y
        sta AUDC0
        lda SndF,y
        sta AUDF0
        lda SndV,y
        sta AUDV0
        lda SndT,y
        sta sndT0
.nos    rts

; traiettoria verso (tx, th) in un tempo fisso: Y = 0 (64 fotogrammi), 1 (32), 2 (16).
; vx = dx * 256/T, vy = dh * 256/T + g*(T-1)/2: la palla arriva esattamente dopo T fotogrammi.
Launch  SUBROUTINE
        lda #0
        sta bxl
        sta byl
        sta fT
        lda tx
        sec
        sbc bxh
        sta bvxl
        lda #0
        sbc #0
        sta bvxh
        lda th
        sec
        sbc byh
        sta bvyl
        lda #0
        sbc #0
        sta bvyh
        ldx LShift,y
.sh     asl bvxl
        rol bvxh
        asl bvyl
        rol bvyh
        dex
        bne .sh
        lda bvyl
        clc
        adc GcLo,y
        sta bvyl
        lda bvyh
        adc GcHi,y
        sta bvyh
        rts

; movimento della palla: gravità, rete, terra, fuori
MoveBall  SUBROUTINE
        lda bxl
        clc
        adc bvxl
        sta bxl
        lda bxh
        adc bvxh
        sta bxh
        lda byl
        clc
        adc bvyl
        sta byl
        lda byh
        adc bvyh
        sta byh
        lda bvyl
        sec
        sbc #GRAV
        sta bvyl
        lda bvyh
        sbc #0
        sta bvyh
        lda byh
        cmp #PAIRS-2
        bcc .noTop
        cmp #200
        bcs .noTop
        lda #PAIRS-2
        sta byh
.noTop  ; fuori dallo schermo: fuori
        lda bxh
        cmp #156
        bcc .inX
.outP   lda lastSide
        eor #1
        jmp Point
.inX    ; a terra
        lda byh
        cmp #FLOOR
        bcc .land
        cmp #200
        bcc .air
.land   ldy #2
        jsr Sound
        lda bxh
        cmp #3
        bcc .outP               ; oltre la linea di fondo
        cmp #153
        bcs .outP
        clc
        adc #2
        cmp #80
        lda #0
        rol
        eor #1
        jmp Point
.air    ; rete: la palla tocca il nastro e cade
        lda byh
        cmp #NETTOP+1
        bcs .noNet
        lda bxh
        cmp #74                 ; la palla (4 pixel) tocca la rete (pixel 76-83): zona simmetrica 74..81
        bcc .noNet
        cmp #82
        bcs .noNet
        lda bvxh
        bmi .fromR
        lda #73
        sta bxh
        lda #$FF                ; rimbalzo debole all'indietro
        sta bvxh
        lda #$C0
        sta bvxl
        bne .netDone
.fromR  lda #83
        sta bxh
        lda #0
        sta bvxh
        lda #$40
        sta bvxl
.netDone
        lda #NX_NONE
        sta next
        lda #0
        sta blockPend
        ldy #2
        jmp Sound
.noNet  rts

; ---------------------------------------------------------------- battuta
ServeState  SUBROUTINE
        inc stateT
        jsr HoldBall
        lda server
        jsr Human
        beq .ai
        ldx server
        lda press,x
        bne Toss
        rts
.ai     lda stateT
        cmp #60
        bcs Toss
        rts
Toss    lda #ST_TOSS
        sta state
        lda #1
        sta bvyh
        lda #$10
        sta bvyl
        lda #0
        sta bvxl
        sta bvxh
        sta stateT
        ldy #3
        jmp Sound

HoldBall  SUBROUTINE
        lda server
        asl
        ora #1
        tax
        lda px,x
        ldy server
        clc
        adc HoldOfs,y
        sta bxh
        lda #HAND
        sta byh
        lda #0
        sta bxl
        sta byl
        rts

TossState  SUBROUTINE
        jsr MoveBall
        lda state
        cmp #ST_TOSS
        bne .done
        lda byh
        cmp #HAND-2
        bcs .up
        lda server              ; la palla è ricaduta: fallo di battuta
        eor #1
        jmp Point
.up     lda bvyh
        bpl .done               ; sta ancora salendo
        lda server
        jsr Human
        beq .ai
        ldx server
        lda press,x
        beq .done
        ; colpo: la finestra giusta è quando la palla è rossa (HAND+3..HAND+9)
        lda byh
        cmp #HAND+3
        bcc .bad
        cmp #HAND+10
        bcs .bad
        lda #0
        beq Serve
.bad    lda rand
        and #1                  ; fuori tempo: una volta su due va in rete
        beq Serve
        lda #2
        bne Serve
.ai     lda byh
        cmp #HAND+6
        bcs .done
        lda rand
        cmp #12                 ; il computer sbaglia ogni tanto
        lda #0
        bcs Serve
        lda #2
        bne Serve
.done   rts

; battuta: A = 0 buona, 2 in rete. Direzione dal joystick (verso la rete = corta, verso il fondo = lunga)
Serve   sta temp3
        ldx server
        lda #1                  ; media
        sta temp2
        lda joy,x
        cpx #0
        beq .j0
        asl                     ; squadra destra: la rete è a sinistra (bit 6 -> bit 7)
.j0     bpl .notNet
        lda #0                  ; corta
        sta temp2
        beq .dirOk
.notNet lda joy,x
        cpx #0
        bne .j1
        asl
.j1     bpl .dirOk
        lda #2                  ; lunga
        sta temp2
.dirOk  lda server
        asl
        asl
        clc
        adc temp2
        tay
        lda ServeTX,y
        ldy temp3
        beq .ok
        lda NetTX,x             ; in rete
.ok     sta tx
        lda #FLOOR
        sta th
        ldy #0
        jsr Launch
        lda #ST_RALLY
        sta state
        lda server
        sta lastSide
        eor #1
        sta team
        lda #NX_RECV
        sta next
        jsr AiError
        lda server
        asl
        ora #1
        tax
        lda #5
        jsr SetPose
        ldy #3
        jmp Sound

; livello del computer dalle levette di difficoltà: Y = 0 (B B), 1 (sinistra A), 2 (destra A), 3 (A A)
Diff    lda SWCHB
        asl
        rol
        rol
        and #3
        tay
        rts

; errore di piazzamento del computer in ricezione: +-16 pixel, dimezzato a ogni livello
AiError  SUBROUTINE
        jsr Diff
        lda rand
        and #31
        sec
        sbc #16
.sh     dey
        bmi .keep
        cmp #$80
        ror
        jmp .sh
.keep   sta aiErr
        rts

; posa del giocatore X per qualche fotogramma: A = fotogramma (3 braccia su, 4 bagher, 5 schiacciata)
SetPose  SUBROUTINE
        sta pose,x
        lda #12
        sta animT,x
        rts

; ---------------------------------------------------------------- scambio: bagher, alzata, attacco, muro
RallyState  SUBROUTINE
        jsr MoveBall
        lda state
        cmp #ST_RALLY
        bne .done
        ; muro deciso al momento della schiacciata: la palla torna indietro quando arriva alla rete
        lda blockPend
        beq .noBlk
        lda bxh
        sec
        sbc #70
        cmp #13
        bcs .noBlk
        jmp Block
.noBlk  lda next
        cmp #NX_RECV
        bne .nr
        jmp Recv
.nr     cmp #NX_SET
        bne .ns
        jmp SetBall
.ns     cmp #NX_HIT
        bne .done
        jmp Attack
.done   rts

; bagher del ricevitore della squadra "team" quando la palla scende vicino a lui
Recv    SUBROUTINE
        lda byh
        cmp #DIGH+1
        bcs .no
        lda bvyh
        bpl .no
        lda team
        asl
        ora #1
        tax
        lda pz,x
        bne .no
        lda bxh
        sec
        sbc px,x
        sec
        sbc #2                  ; dx = centro palla - centro giocatore
        clc
        adc #9
        cmp #19
        bcs .no
        sec
        sbc #9                  ; dx con segno
        bpl .pos
        eor #$FF
        clc
        adc #1
.pos    sta temp                ; |dx|
        lda #4
        jsr SetPose
        ldy team
        lda SetBallX,y
        sta tx
        lda temp
        sec
        sbc #3
        bcc .exact              ; vicino: palla precisa all'alzatore
        asl
        asl
        sta temp
        lda rand
        bmi .minus
        lda tx
        clc
        adc temp
        jmp .clamp
.minus  lda tx
        sec
        sbc temp
.clamp  ldy team                ; resta nella propria metà campo
        cmp SideMin,y
        bcs .c1
        lda SideMin,y
.c1     cmp SideMax,y
        bcc .c2
        lda SideMax,y
.c2     sta tx
.exact  lda #HAND
        sta th
        ldy #0
        jsr Launch
        lda team
        sta lastSide
        lda #NX_SET
        sta next
        ldy #0
        jmp Sound
.no     rts

; alzata: dopo 64 fotogrammi la palla è sulle mani dell'alzatore, che la alza all'attaccante
SetBall SUBROUTINE
        lda fT
        cmp #64
        bne .no
        lda team
        asl
        tax                     ; la prima linea: l'alzatore palleggia
        lda #3
        jsr SetPose
        lda m4                  ; 2 contro 2: alza sempre al difensore, che attacca a rete
        beq .four
        lda #3
        bne .typ
.four   ; tipo di alzata: persona = joystick (giù primo tempo, verso il fondo seconda linea), computer a caso
        lda team
        jsr Human
        beq .ai
        ldy team
        lda joy,y
        and #$20
        bne .quick
        lda joy,y
        cpy #0
        bne .b1
        asl
.b1     bmi .back
        lda #0
        beq .typ
.ai     lda rand
        cmp #60
        bcc .quick
        cmp #110
        bcc .back
        lda #0
        beq .typ
.quick  jsr Jump                ; primo tempo: la prima linea stacca subito
        lda #1
        bne .typ
.back   lda #2
.typ    sta setType
        tay
        lda SetHitT,y
        sta tHit
        lda SetLT,y
        pha
        tya
        ldy team
        beq .t0
        clc
        adc #4
.t0     tay
        lda SetTX,y
        sta tx
        lda #HITH
        sta th
        pla
        tay
        jsr Launch
        lda #NX_HIT
        sta next
        lda #0
        sta blockPend
        ldy #0
        jmp Sound
.no     rts

; attacco: l'attaccante salta da solo a fT = 48; si colpisce con il pulsante quando la palla è rossa
Attack  SUBROUTINE
        jsr Attacker            ; X = chi attacca (prima linea o difensore in seconda linea)
        lda tHit
        sec
        sbc #16
        cmp fT
        bne .nj
        jsr Jump                ; stacco: in cima al salto quando arriva la palla
.nj     ; muro: l'alzatore avversario salta col pulsante (persona) o da solo (computer)
        lda team
        eor #1
        jsr Human
        beq .aiBlk
        lda team
        eor #1
        tay
        lda press,y
        beq .blkDone
        lda tHit
        sec
        sbc #28
        cmp fT
        bcs .blkDone
        tya
        asl
        tax
        jsr Jump
        jmp .blkDone
.aiBlk  lda tHit
        sec
        sbc #14
        cmp fT
        bne .blkDone
        lda rand
        cmp #110
        bcs .blkDone
        lda team
        eor #1
        asl
        tax
        jsr Jump
.blkDone
        ; colpo
        lda team
        jsr Human
        beq .ai
        ldy team
        lda press,y
        beq .late
        lda fT
        sec
        sbc tHit
        clc
        adc #8
        cmp #15
        bcs .late
        sec
        sbc #8
        bpl .pp
        eor #$FF
        clc
        adc #1
.pp     cmp #5
        bcs .soft               ; fuori tempo di poco: palla piazzata lenta
        ldy team                ; direzione dal joystick
        lda joy,y
        and #$10
        bne .dink
        lda joy,y
        cpy #0
        beq .j0
        asl
.j0     bmi .short
        lda joy,y
        cpy #0
        bne .j1
        asl
.j1     bmi .long
        lda #1
        bne .spike
.short  lda #0
        beq .spike
.long   lda #2
        bne .spike
.late   lda tHit
        clc
        adc #8
        cmp fT
        bcc .free               ; non ha colpito: palla facile di là
        rts
.ai     lda fT
        cmp tHit
        bne .done
        lda rand
        cmp #12
        bcc .free
        cmp #40
        bcc .dink
        and #3
        cmp #3
        bne .spike
        lda #1
        bne .spike
.done   rts
.free   ldy team
        lda FreeTX,y
        sta tx
        ldy #0
        lda #3
        bne .launch
.soft   lda #1                  ; fuori tempo di poco: palla piazzata lenta (32 fotogrammi)
        sta temp
        ldy #1
        bne .sp2
.dink   ldy team
        lda DinkTX,y
        sta tx
        ldy #1
        lda #3
        bne .launch
; schiacciata: A = 0 corta, 1 media, 2 lunga
.spike  sta temp
        ldy setType             ; primo tempo veloce (16 fotogrammi), palla alta e seconda linea 32
        lda SpikeLT,y
        tay
.sp2    lda team
        asl
        asl
        clc
        adc temp
        tax
        lda SpikeTX,x
        sta tx
        lda #5
.launch sta temp2               ; posa
        lda #FLOOR
        sta th
        jsr Launch
        jsr Attacker
        lda temp2
        jsr SetPose
        ; muro: l'alzatore avversario è in aria abbastanza in alto?
        lda temp2
        cmp #5                  ; solo le schiacciate si murano
        bne .noBlock
        lda team
        eor #1
        asl
        tax
        lda pz,x
        cmp #4
        bcc .noBlock
        lda team
        eor #1
        jsr Human
        beq .aiChance
        lda rand
        cmp #130
        bcs .noBlock
        bcc .yesBlock
.aiChance
        jsr Diff                ; muro del computer: più probabile ai livelli alti
        lda rand
        cmp BlkCh,y
        bcs .noBlock
        lda setType             ; il primo tempo si mura una volta su due
        cmp #1
        bne .yesBlock
        lda rand
        bmi .noBlock
.yesBlock
        lda #1
        sta blockPend
.noBlock
        lda team
        sta lastSide
        eor #1
        sta team
        lda #NX_RECV
        sta next
        jsr AiError
        ldy #1
        lda temp2
        cmp #5
        beq .snd
        ldy #0
.snd    jmp Sound

; X = chi attacca: la prima linea della squadra (palla alta, primo tempo) o il difensore (seconda linea)
Attacker
        lda team
        asl
        ldy setType
        cpy #2
        bcc .a
        ora #1
.a      tax
        rts

; muro: la palla rimbalza nel campo di chi ha attaccato (che può ancora difenderla)
Block   SUBROUTINE
        lda #0
        sta blockPend
        lda team                ; "team" adesso è la squadra che mura
        sta lastSide
        eor #1
        sta team
        tay
        lda BlockTX,y
        sta tx
        lda #FLOOR
        sta th
        ldy #2
        jsr Launch
        lda #NX_RECV
        sta next
        lda team
        eor #1
        asl
        tax
        lda #3
        jsr SetPose
        ldy #1
        jmp Sound

; ---------------------------------------------------------------- giocatori: obiettivi, movimento, salto, animazione
Players  SUBROUTINE
        ldx #3
.loop   stx temp3
        jsr Target              ; A = x obiettivo
        ldx temp3
        sta tgt,x
        lda #0
        sta moved,x
        ; persona: il ricevitore della squadra che deve ricevere si muove col joystick
        lda state
        cmp #ST_RALLY
        bne .auto
        lda next
        cmp #NX_RECV
        bne .auto
        txa
        and #1
        beq .auto
        txa
        lsr
        cmp team
        bne .auto
        jsr Human
        beq .auto
        ldx temp3
        txa
        lsr
        tay
        lda joy,y
        bpl .nr
        jsr StepRight
.nr     ldx temp3
        txa
        lsr
        tay
        lda joy,y
        and #$40
        beq .phys
        jsr StepLeft
        jmp .phys
.auto   ldx temp3
        lda px,x
        cmp tgt,x
        beq .phys
        bcs .gl
        jsr StepRight
        ldx temp3
        txa
        and #1
        bne .phys               ; gli alzatori sono più rapidi
        lda px,x
        cmp tgt,x
        bcs .phys
        jsr StepRight
        jmp .phys
.gl     jsr StepLeft
        ldx temp3
        txa
        and #1
        bne .phys
        lda px,x
        cmp tgt,x
        beq .phys
        bcc .phys
        jsr StepLeft
.phys   ldx temp3
        jsr Physics
        ldx temp3
        dex
        bmi .end
        jmp .loop
.end    rts

; un passo: 1 o 2 pixel a fotogrammi alterni (1,5 pixel/fotogramma)
StepRight
        lda par
        sec
        adc px,x
        jmp ClampX
StepLeft
        lda par
        eor #$FF
        clc
        adc px,x
ClampX  SUBROUTINE
        cpx #2
        bcs .cr
        cmp #2
        bcs .c1
        lda #2
.c1     cmp #67
        bcc .cd
        lda #66
        bne .cd
.cr     cmp #86
        bcs .c2
        lda #86
.c2     cmp #152
        bcc .cd
        lda #151
.cd     cmp px,x
        beq .nm
        inc moved,x
.nm     sta px,x
        rts

; obiettivo del giocatore temp3 secondo la fase di gioco (A = x)
Target  SUBROUTINE
        ldx temp3
        lda state
        cmp #ST_RALLY
        beq .rally
        cmp #ST_TOSS
        beq .serve
        cmp #ST_SERVE
        bne .stay
.serve  txa                     ; battitore dietro la linea di fondo, gli altri a casa
        lsr
        cmp server
        bne .home
        txa
        and #1
        beq .home
        ldy server
        lda ServeX,y
        rts
.stay   lda px,x
        rts
.home   txa
        ora m4
        tay
        lda HomeX,y
        rts
.rally  txa
        and #1
        beq .home               ; la prima linea resta al suo posto (salta a muro e in attacco)
        txa
        lsr
        cmp team
        bne .home               ; difensore della squadra senza palla: in difesa
        lda next
        cmp #NX_RECV
        bne .notR
        lda tx                  ; sotto la palla (con l'errore del computer)
        sec
        sbc #2
        clc
        adc aiErr
        cmp #200
        bcc .okR
        lda #2
.okR    rts
.notR   cmp #NX_HIT
        bne .home
        lda setType
        cmp #2
        bcc .home               ; attacca solo nella seconda linea (2) o, nel 2 contro 2, a rete (3)
        beq .b2
        inx
        inx
        inx
.b2     lda fT
        cmp #24
        bcs .run
        lda BackApp-1,x
        rts
.run    lda BackTake-1,x
        rts

; salto del giocatore X (se è a terra)
Jump    SUBROUTINE
        lda pz,x
        bne .no
        lda #1
        sta pvz,x
        lda #$28
        sta pvzf,x
        lda #0
        sta pzf,x
.no     rts

; fisica del salto e fotogramma dell'animazione del giocatore X
Physics SUBROUTINE
        lda pz,x
        ora pvz,x
        ora pvzf,x
        beq .ground
        lda pzf,x
        clc
        adc pvzf,x
        sta pzf,x
        lda pz,x
        adc pvz,x
        sta pz,x
        lda pvzf,x
        sec
        sbc #PGRAV
        sta pvzf,x
        lda pvz,x
        sbc #0
        sta pvz,x
        lda pz,x
        bpl .ground
        lda #0
        sta pz,x
        sta pzf,x
        sta pvz,x
        sta pvzf,x
.ground lda animT,x
        beq .nt
        dec animT,x
        lda pose,x
        bne .set
.nt     ; battitore con la palla in mano: braccia su
        lda state
        cmp #ST_TOSS+1
        bcs .nsv
        txa
        and #1
        beq .nsv
        txa
        lsr
        cmp server
        bne .nsv
        lda #3
        bne .set
.nsv    lda state               ; fine partita: chi ha vinto esulta
        cmp #ST_OVER
        bne .nov
        txa
        lsr
        cmp winner
        bne .nov
        lda rand
        and #3
        bne .nov
        jsr Jump
.nov    lda pz,x
        ora pvz,x
        ora pvzf,x
        beq .onG
        lda #3
        bne .set
.onG    lda moved,x
        beq .still
        lda frame
        lsr
        lsr
        lsr
        and #1
        clc
        adc #1
        bne .set
.still  lda #0
.set    sta anim,x
        rts

; colore della palla: ROSSA quando una persona deve colpire (battuta o schiacciata); segno di caduta per chi riceve
BallLook  SUBROUTINE
        lda #WHITE
        sta ballCol
        lda state
        cmp #ST_TOSS
        bne .nt
        lda server
        jsr Human
        beq .mark
        lda bvyh
        bpl .mark
        lda byh
        cmp #HAND+3
        bcc .mark
        cmp #HAND+10
        bcs .mark
        bcc .red
.nt     cmp #ST_RALLY
        bne .mark
        lda next
        cmp #NX_HIT
        bne .mark
        lda team
        jsr Human
        beq .mark
        lda fT
        clc
        adc #6
        sec
        sbc tHit
        cmp #11
        bcs .mark
.red    lda #RED
        sta ballCol
.mark   lda #0
        sta MkD
        lda state
        cmp #ST_RALLY
        bne .nm
        lda next
        cmp #NX_RECV
        bne .nm
        lda team
        jsr Human
        beq .nm
        lda tx
        sec
        sbc #2
        sta markX
        lda #PAIRS-MARKROW
        sta MkD
.nm     rts

; ================================================================ dati
;                 alz.sx att.sx alz.dx att.dx
; prima linea: copie a x, x+16, x+32 (sinistra: schiacciatore 28, alzatore 44, centrale 60; destra: centrale 84,
; alzatore 100, schiacciatore 116); difensore da solo
;              1a linea sx, difensore sx, 1a linea dx, difensore dx
HomeX      .byte 28,    12,    84,    140
           .byte 44,    12,    100,   140   ; 2 contro 2: l'alzatore al posto del palleggio
Nusiz0     .byte $03, $20, $00, $20     ; P0: 3 copie (prima linea) / un giocatore + missile largo 4 (palla); 2c2
Nusiz1     .byte $20, $03, $20, $00
BackApp    .byte 8, 0, 146, 30, 0, 122  ; seconda linea: rincorsa e stacco del difensore (X-1: 0 sinistra, 2 destra)
BackTake   .byte 20, 0, 136, 56, 0, 92  ; (+3: attacco a rete del 2 contro 2)
SetTX      .byte 34, 64, 24, 60, 118, 88, 132, 96  ; alzata (sx, dx): palla alta, primo tempo, seconda linea, 2c2
SetHitT    .byte 64, 16, 64, 64
SetLT      .byte 0, 2, 0, 0
SpikeLT    .byte 1, 2, 1, 1
ServeX     .byte 2, 150
HoldOfs    .byte 6, $FE
SetBallX   .byte 46, 102                      ; dove arriva il bagher (sopra l'alzatore)
SideMin    .byte 8, 88
SideMax    .byte 68, 148
SpikeTX    .byte 112, 126, 146, 0, 44, 30, 10, 0   ; schiacciata corta/media/lunga (sinistra, destra)
DinkTX     .byte 92, 64
FreeTX     .byte 126, 30
BlockTX    .byte 44, 112                      ; muro: dove ricade la palla (campo di chi attacca)
ServeTX    .byte 100, 120, 144, 0, 56, 36, 12, 0
NetTX      .byte 70, 86
TargetPts  .byte 15, 21
BlkCh      .byte 50, 80, 110, 140
ArenaPtrs  .byte <BgI, >BgI, <Pf0I, >Pf0I, <Pf1I, >Pf1I, <Pf2I, >Pf2I, <PfcI, >PfcI, <BgB, >BgB, <Pf0B, >Pf0B, <Pf1B, >Pf1B, <Pf2B, >Pf2B, <PfcB, >PfcB
ShirtCol   .byte $44, $84, $38, $C8
LShift     .byte 2, 3, 4
GcLo       .byte <410, <202, <98
GcHi       .byte >410, >202, >98
SndC       .byte $0C, $08, $0F, $04
SndF       .byte $0C, $03, $1C, $09
SndV       .byte $0A, $0C, $0A, $08
SndT       .byte 4, 10, 7, 5

        include "data.inc"

        ORG $FFFC
        .word Reset
        .word Reset
