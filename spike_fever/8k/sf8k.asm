; ============================================================================
;  SPIKE FEVER 2600 8K - pallavolo 4 contro 4 in stile POWER SPIKES per Atari 2600 (VCS), cartuccia da 8K (F8)
;  Banco 0: titolo con il logo grande SPIKE / FEVER, il quadro animato della schiacciata e il menu.
;  Banco 1: la partita della versione 4K, con 12 pose dei giocatori (corsa a 4 passi, discesa dal salto,
;           seguito della schiacciata, palleggio, muro).
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
;  In alto: punteggio nei colori delle squadre (il titolo ha la sua schermata nel banco 0).
;  La palla è il missile dello sprite che nel fotogramma mostra un giocatore solo; il segno di caduta è l'oggetto ball.
;  La palla è il missile 1 (colore ballCol: bianca, ROSSA quando bisogna colpire).
;  Compilazione: python3 gen_data.py ; node build.js  -> sf8k.bin (8192 byte)
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
req     = tHit          ; banco 0: 0 = titolo, 1 = nuova partita (letto subito, all'ingresso nel banco 0)
idle    = aiErr         ; titolo: tempo senza tasti (a passi di 64 fotogrammi); in partita si ricalcola
RAMEND

; ---------------------------------------------------------------- ROM
        SEG code
        include "bank0.asm"

; ============================================================================ BANCO 1: la partita
        ORG $1000
        RORG $F000

; ingresso dal banco 0 (nuova partita: punteggi e posizioni gia' azzerati)
GameEntry:                      ; (stack, REFP1 e battuta preparati nel banco 0)

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
        jmp FarLogic            ; logica nel banco 0, poi torna a Overscan
Overscan
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
; la squadra A è comandata da una persona? (Z = 0 sì)  usa temp4 (copia: Human0 nel banco 0)
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
        beq .nt
        cmp #5                  ; schiacciata: nella seconda meta' il seguito del colpo
        bne .set
        ldy animT,x
        cpy #6
        bcs .set
        lda #9
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
        lda pvz,x               ; in salto: sale (braccia su) o scende (gambe raccolte)
        bmi .fall
        lda #3
        bne .set
.fall   lda #8
        bne .set
.onG    lda moved,x
        beq .still
        lda frame               ; corsa: 4 passi
        lsr
        lsr
        lsr
        and #3
        tay
        lda RunSeq,y
        bne .set
.still  lda #0
.set    sta anim,x
        rts


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
ServeX     .byte 2, 150
ArenaPtrs  .byte <BgI, >BgI, <Pf0I, >Pf0I, <Pf1I, >Pf1I, <Pf2I, >Pf2I, <PfcI, >PfcI, <BgB, >BgB, <Pf0B, >Pf0B, <Pf1B, >Pf1B, <Pf2B, >Pf2B, <PfcB, >PfcB
ShirtCol   .byte $44, $84, $38, $C8

        include "data.inc"

; passaggi tra i banchi (stessi indirizzi nei due banchi: lda $FFF8 / $FFF9 cambia banco e il
; programma continua all'istruzione dopo, nell'altro banco)
        ORG $1FD0
        RORG $FFD0
FarLogic lda $FFF8              ; -> banco 0, $FFD3: jsr Logic, poi torna qui a $FFD9
        ds 6, $EA
        jmp Overscan
        ORG $1FE0
        RORG $FFE0
ToBank0 lda $FFF8               ; -> banco 0, $FFE3: jmp B0Entry
        nop
        nop
        nop
ToBank1 lda $FFF9               ; -> banco 1, $FFE9
        jmp GameEntry
Start1  lda $FFF8               ; accensione nel banco 1: -> banco 0, $FFEF
        ORG $1FFC
        RORG $FFFC
        .word Start1
        .word Start1
