; ============================================================================
;  SPIKE FEVER 2600 - pallavolo in stile POWER SPIKES per Atari 2600 (VCS)
;  Cartuccia da 16K (bank switching F6, 4 banchi da 4K)    by SpikeCode AI
;
;  BANCO 0: ciclo principale, logica di gioco e dei menu
;  BANCO 1: kernel della partita, sprite, colori delle nazionali, 6 arene (paesaggi)
;  BANCO 2: kernel delle schermate: titolo (logo come Power Spikes), scelta della squadra,
;           presentazione del livello, game over, campione; scritte e bandiere
;  BANCO 3: libero
;  I salti tra i banchi passano dagli "stub" agli stessi indirizzi in ogni banco ($FFC0-$FFE5):
;  leggere $1FF6/$1FF7/$1FF8 seleziona il banco 0/1/2 e l'istruzione successiva arriva dal nuovo banco.
;
;  GIOCO (2 contro 2: alzatore + attaccante, come in Power Spikes)
;    battuta : pulsante = lancio; quando la palla è ROSSA di nuovo = colpo.  Al lancio: SU = battuta altissima
;              (towering), VERSO LA RETE = battuta in salto, niente = battuta normale.  Al colpo: verso la rete
;              = corta, verso il fondo = lunga.
;    ricezione: muovi il ricevitore sul segno giallo; se la palla è lontana premi il pulsante = TUFFO.
;    alzata  : GIÙ = primo tempo (veloce), VERSO IL FONDO = seconda linea, VERSO LA RETE + pulsante =
;              palleggio di seconda dell'alzatore (sorpresa), niente = palla alta.
;    attacco : pulsante quando la palla è ROSSA.  SU = pallonetto, GIÙ = schiacciata potente (fuori se
;              sbagli il tempo), verso la rete = corta, verso il fondo = lunga.  Senza pulsante: palla facile.
;    muro    : quando attaccano gli avversari premi il pulsante (salta il tuo alzatore).
;  1 GIOCATORE: 6 livelli (set a 11, in spiaggia a 15) contro Cina, Brasile, USA, Cuba, Giappone, URSS in 6 paesaggi
;               (palestra, Copacabana, arena di Los Angeles, Caraibi al tramonto, monte Fuji, Mosca);
;               Brasile e Cuba si giocano sulla sabbia (beach volley).
;  2 GIOCATORI: ognuno sceglie la nazionale, poi si sceglie l'arena.
;  GAME RESET = schermata del titolo.  GAME SELECT (nel titolo) = 1 o 2 giocatori.
;
;  KERNEL DELLA PARTITA (banco 1): 24 righe in alto (punteggio nei colori delle maglie o titolo nella
;  dimostrazione) + area di gioco a 2 righe (168 righe): riga A fondo/PF0/PF1/giocatore sinistro/palla,
;  riga B PF2/colore PF/segno di caduta/giocatore destro. I compagni di squadra si alternano a 30 Hz.
;  Compilazione: python3 gen_data.py && node build.js  -> spikefever2600.bin (16384 byte)
; ============================================================================
        processor 6502
        include "vcs.h"
        include "macro.h"

PH      = 12
BH      = 2
PAIRS   = 84
FLOOR   = 8
NETTOP  = 22
HAND    = FLOOR+PH+1
HITH    = FLOOR+PH+9
DIGH    = FLOOR+5
GRAV    = $0D
MARKROW = 5
MARKCOL = $1E
WHITE   = $0E
RED     = $44

; schermate
SC_TITLE  = 0
SC_SELECT = 1
SC_INTRO  = 2
SC_GAME   = 3
SC_OVER   = 4
SC_CHAMP  = 5
; stati della partita
ST_SERVE = 0
ST_TOSS  = 1
ST_RALLY = 2
ST_POINT = 3
ST_OVER  = 4
; prossimo tocco
NX_RECV = 0
NX_SET  = 1
NX_HIT  = 2
NX_NONE = 3
; fotogrammi degli sprite
FR_JUMP  = 3
FR_BUMP  = 4
FR_SPIKE = 5
FR_DIVE  = 6

; ---------------------------------------------------------------- RAM
        SEG.U vars
        ORG $80
frame   ds 1
rand    ds 1
screen  ds 1
menuSel ds 1            ; titolo: 0 = 1 giocatore, 1 = 2 giocatori
twoP    ds 1
selStep ds 1            ; scelta: 0 nazione P1, 1 nazione P2, 2 arena
nat     ds 2            ; nazione della squadra sinistra e destra
level   ds 1
arena   ds 1
beach   ds 1
demo    ds 1
idleT   ds 1
state   ds 1
stateT  ds 1
score   ds 2
server  ds 1
winner  ds 1
next    ds 1
team    ds 1
fT      ds 1
tHit    ds 1            ; fotogramma del colpo d'attacco (64 palla alta / seconda linea, 32 primo tempo)
lastSide ds 1
tx      ds 1
th      ds 1
blockPend ds 1
aiErr   ds 1
skill   ds 1            ; bravura del computer (livello)
setType ds 1            ; 0 alta, 1 primo tempo, 2 seconda linea
serveKind ds 1          ; 0 normale, 1 in salto, 2 altissima
recvPen ds 1            ; ricezione più difficile (battute speciali, schiacciate potenti)
dumpReq ds 1
px      ds 4            ; giocatori: 0 alzatore sx, 1 attaccante sx, 2 alzatore dx, 3 attaccante dx
jT      ds 4            ; fotogramma del salto (0 = a terra)
animT   ds 4
pose    ds 4
anim    ds 4
moved   ds 1            ; bit = giocatore che si è mosso
joy     ds 2
joyOld  ds 2
joyNew  ds 2
press   ds 2
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
sndT0   ds 1
sndT1   ds 1
; puntatori del kernel (nelle schermate: puntatori delle scritte/bandiere)
P0Ptr   ds 2
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
RAMEND
; alias per le schermate (banco 2)
T0P = P0Ptr
T1P = P0Col
T2P = P1Ptr
T3P = P1Col
T4P = P0D               ; (P0D,P1D)
T5P = BlD               ; (BlD,MkD)
TCP = BgPtr
tRows = Pf0Ptr
tLines = Pf0Ptr+1

; stub per cambiare banco: identici in tutti i banchi
        MAC STUBS
        lda $1FF7               ; $FFC0 -> banco 1
        jsr GameKernel          ; $FFC3 (eseguito nel banco 1)
        lda $1FF6               ; $FFC6 -> banco 0
        rts                     ; $FFC9 (eseguito nel banco 0)
        ds 6, 0
        lda $1FF8               ; $FFD0 -> banco 2
        jsr ScreenKernel        ; $FFD3 (banco 2)
        lda $1FF6               ; $FFD6 -> banco 0
        rts                     ; $FFD9 (banco 0)
        ds 6, 0
        lda $1FF6               ; $FFE0 accensione: banco 0
        jmp Reset0              ; $FFE3
        ENDM

; ============================================================================ BANCO 0
        SEG code
        ORG $0000
        RORG $F000

Reset0:
        CLEAN_START
        lda #$A7
        sta rand
        lda #5
        sta nat+1
        jsr GoTitle

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
        lda screen
        cmp #SC_GAME
        bne .noSetup
        jsr GameSetup
.noSetup
.vb     lda INTIM
        bne .vb
        sta WSYNC
        sta VBLANK
        lda screen
        cmp #SC_GAME
        bne .scr
        jsr CallGame
        jmp .os
.scr    jsr CallScreen
.os     sta WSYNC
        lda #2
        sta VBLANK
        lda #0
        sta GRP0
        sta GRP1
        sta ENAM0
        sta ENAM1
        sta PF0
        sta PF1
        sta PF2
        lda #35
        sta TIM64T
        jsr Logic
.ow     lda INTIM
        bne .ow
        jmp MainLoop

CallGame   = $FFC0
CallScreen = $FFD0

; ---------------------------------------------------------------- preparazione della partita (VBLANK)
GameSetup  SUBROUTINE
        jsr Players
        lda #$30
        sta NUSIZ0
        lda #$20
        sta NUSIZ1
        lda #0
        sta REFP0
        lda #8
        sta REFP1
        ; scenario dell'arena: 5 puntatori
        lda arena
        asl
        sta temp
        asl
        asl
        clc
        adc temp                ; arena * 10
        tay
        ldx #0
.ar     lda ArenaPtrs,y
        sta BgPtr,x
        iny
        inx
        cpx #10
        bne .ar
        ; compagno di squadra da disegnare in questo fotogramma
        lda frame
        and #1
        tax
        ldy #0
        jsr SetupPlayer
        lda frame
        and #1
        ora #2
        tax
        ldy #1
        jsr SetupPlayer
        lda #PAIRS
        sec
        sbc byh
        sta BlD
        ldx nat
        lda ShirtCol,x
        sta COLUP0
        ldx nat+1
        lda ShirtCol,x
        sta COLUP1
        lda state
        cmp #ST_OVER
        bne .nb
        lda frame
        and #16
        beq .nb
        ldx winner
        lda #WHITE
        sta COLUP0,x
.nb     lda frame
        and #1
        tax
        lda px,x
        ldx #0
        jsr PosObject
        lda frame
        and #1
        tax
        lda px+2,x
        ldx #1
        jsr PosObject
        lda markX
        ldx #2
        jsr PosObject
        lda bxh
        ldx #3
        jsr PosObject
        sta WSYNC
        sta HMOVE
        rts

; X = giocatore, Y = sprite (0/1): puntatori di grafica e colori (nazione, scarpe o piedi nudi)
SetupPlayer  SUBROUTINE
        tya
        asl
        asl
        sta temp3
        lda jT,x
        stx temp4
        tax
        lda JumpZ,x
        clc
        adc #FLOOR
        sta temp                ; coppia più bassa
        lda #PAIRS
        sec
        sbc temp
        sta P0D,y
        ldx temp4
        lda anim,x
        tax
        lda ColOfs,x
        pha
        lda FrameOfs,x
        clc
        adc #<Gfx
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
        sta temp2               ; offset dei colori
        lda nat,y
        asl
        ora beach
        tax
        lda NatColLo,x
        clc
        adc temp2
        sta temp4
        lda NatColHi,x
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

; righe del punteggio della squadra X
ScoreDigits  SUBROUTINE
        lda score,x
        ldy #0
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
        lda FontLo,y
        asl
        asl
        asl
        asl
        .byte $2C
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

; ---------------------------------------------------------------- logica (overscan)
Logic  SUBROUTINE
        inc frame
        lda rand
        lsr
        bcc .ne
        eor #$B4
.ne     sta rand
        jsr ReadInput
        ; GAME RESET: torna al titolo
        lda SWCHB
        lsr
        bcs .nr
        jsr GoTitle
.nr     inc stateT
        lda screen
        asl
        tax
        lda ScreenLogic+1,x
        pha
        lda ScreenLogic,x
        pha
        rts                     ; salta alla logica della schermata (indirizzo-1 in tabella)
LogicDone
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

ScreenLogic
        .word TitleLogic-1, SelectLogic-1, IntroLogic-1, GameLogic-1, OverLogic-1, ChampLogic-1

GoTitle  SUBROUTINE
        lda #SC_TITLE
SetScreen
        sta screen
        lda #0
        sta stateT
        sta idleT
        sta demo
        rts

; ---------------------------------------------------------------- titolo
TitleLogic  SUBROUTINE
        lda frame
        and #3
        bne .ni
        inc idleT
.ni     lda idleT
        cmp #250                ; circa 17 secondi senza toccare nulla: dimostrazione
        bcc .nd
        jmp StartDemo
.nd     ; SELECT o joystick su/giù: 1 o 2 giocatori
        lda SWCHB
        and #2
        eor #2
        tax
        cpx selOld
        stx selOld
        beq .nsel
        cpx #0
        beq .nsel
        jmp .toggle
.nsel   lda joyNew
        and #$30
        beq .nt
.toggle lda menuSel
        eor #1
        sta menuSel
        lda #0
        sta idleT
        ldy #4
        jsr Sound
.nt     lda press
        beq .done
        lda menuSel
        sta twoP
        lda #0
        sta selStep
        ldy #4
        jsr Sound
        lda #SC_SELECT
        jsr SetScreen
.done   jmp LogicDone

StartDemo
        lda rand
        and #7
        sta nat
        lda rand
        lsr
        lsr
        lsr
        and #7
        clc
        adc #2
        sta nat+1
        cmp nat
        bne .d1
        inc nat+1
.d1     lda frame
        and #3
        clc
        adc rand
        and #3
        clc
        adc #1                  ; arene 1-4 nella dimostrazione
        sta arena
        tax
        lda ArenaBeach,x
        sta beach
        lda #3
        sta skill
        lda #SC_GAME
        jsr SetScreen
        lda #1
        sta demo
        jsr NewGame
        jmp LogicDone

; ---------------------------------------------------------------- scelta della squadra / arena
SelectLogic  SUBROUTINE
        ldx selStep
        cpx #2
        beq .arena
        ; nazione del giocatore selStep (joystick e pulsante del giocatore)
        lda joyNew,x
        bpl .nr
        inc nat,x
        lda nat,x
        cmp #NNAT
        bcc .snd
        lda #0
        sta nat,x
        beq .snd
.nr     and #$40
        beq .fire
        dec nat,x
        bpl .snd
        lda #NNAT-1
        sta nat,x
.snd    ldy #4
        jsr Sound
.fire   lda press,x
        beq .done
        ldy #3
        jsr Sound
        lda twoP
        beq StartArcade
        inc selStep
        lda #0
        sta stateT
        beq .done
.arena  lda joyNew
        bpl .ar2
        inc arena
        lda arena
        cmp #NARENA
        bcc .as
        lda #0
        sta arena
        beq .as
.ar2    and #$40
        beq .af
        dec arena
        bpl .as
        lda #NARENA-1
        sta arena
.as     ldy #4
        jsr Sound
.af     lda press
        beq .done
        ldx arena
        lda ArenaBeach,x
        sta beach
        lda #4
        sta skill
        lda #SC_GAME
        jsr SetScreen
        jsr NewGame
.done   jmp LogicDone

StartArcade
        lda #0
        sta level
        jsr SetupLevel
        lda #SC_INTRO
        jsr SetScreen
        jmp LogicDone

; avversario e arena del livello (se il giocatore ha scelto la stessa nazione dell'avversario, l'avversario cambia)
SetupLevel  SUBROUTINE
        ldx level
        lda LevelNat,x
        cmp nat
        bne .ok
        lda nat
        eor #1
.ok     sta nat+1
        lda LevelArena,x
        sta arena
        tay
        lda ArenaBeach,y
        sta beach
        stx skill
        rts

; ---------------------------------------------------------------- presentazione del livello
IntroLogic  SUBROUTINE
        lda stateT
        cmp #20
        bcc .done
        lda press
        bne .go
        lda stateT
        cmp #220
        bcc .done
.go     lda #SC_GAME
        jsr SetScreen
        jsr NewGame
.done   jmp LogicDone

; ---------------------------------------------------------------- game over (continua?) e campione
OverLogic  SUBROUTINE
        lda stateT
        cmp #30
        bcc .done
        lda press
        beq .wait
        jsr SetupLevel          ; si rigioca lo stesso livello
        lda #SC_INTRO
        jsr SetScreen
        jmp LogicDone
.wait   lda stateT
        cmp #250
        bcc .done
        jsr GoTitle
.done   jmp LogicDone

ChampLogic  SUBROUTINE
        lda stateT
        cmp #60
        bcc .done
        lda press
        bne .t
        lda stateT
        cmp #250
        bcc .done
.t      jsr GoTitle
.done   jmp LogicDone

; ---------------------------------------------------------------- partita
GameLogic  SUBROUTINE
        lda demo                ; nella dimostrazione il pulsante riporta al titolo
        beq .play
        lda press
        beq .play
        jsr GoTitle
        jmp LogicDone
.play   dec stateT              ; (lo stato della partita usa il suo contatore)
        inc fT
        lda state
        cmp #ST_SERVE
        bne .n0
        jsr ServeState
        jmp .end
.n0     cmp #ST_TOSS
        bne .n1
        jsr TossState
        jmp .end
.n1     cmp #ST_RALLY
        bne .n2
        jsr RallyState
        jmp .end
.n2     inc stateT
        cmp #ST_POINT
        bne .n3
        lda stateT
        cmp #90
        bcc .end
        jsr AfterPoint
        jmp .end
.n3     lda stateT
        cmp #160
        bcc .end
        jsr MatchEnd
.end    jsr BallLook
        lda frame               ; punteggio: una squadra per fotogramma (qui c'è più tempo che nel VBLANK)
        and #1
        tax
        jsr ScoreDigits
        jmp LogicDone

; fine partita: avanti di livello, game over, campione, oppure titolo dopo la dimostrazione
MatchEnd  SUBROUTINE
        lda demo
        beq .real
        jmp GoTitle
.real   lda twoP
        bne .champ
        lda winner
        bne .lost
        inc level
        lda level
        cmp #NLEVEL
        bcs .champ
        jsr SetupLevel
        lda #SC_INTRO
        jmp SetScreen
.lost   lda #SC_OVER
        jmp SetScreen
.champ  lda #SC_CHAMP
        jmp SetScreen

; joystick e pulsanti (squadra destra = secondo joystick); joyNew = direzioni appena premute
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
.btn    lda joy,x
        tay
        eor joyOld,x
        and joy,x
        sta joyNew,x
        tya
        sta joyOld,x
        lda INPT4,x
        eor #$80
        and #$80
        tay
        eor fireOld,x
        and #$80
        sta temp
        tya
        sta fireOld,x
        and temp
        sta press,x
        dex
        bpl .btn
        rts

; la squadra A è comandata da una persona? (Z = 0 sì)
Human  SUBROUTINE
        sta temp4
        lda demo
        bne .cpu
        lda temp4
        beq .yes
        lda twoP
        rts
.yes    lda #1
        rts
.cpu    lda #0
        rts

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
        lda #0
        sta jT,x
        dex
        bpl .pos
StartServe
        lda #ST_SERVE
        sta state
        lda #0
        sta stateT
        sta fT
        sta blockPend
        sta bvxl
        sta bvxh
        sta bvyl
        sta bvyh
        sta dumpReq
        lda #NX_NONE
        sta next
        lda server
        sta lastSide
        rts

AfterPoint  SUBROUTINE
        ldy beach               ; set a 15 (palazzetto) o 21 (spiaggia)
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
        sta state
        lda #0
        sta stateT
        rts
.goOn   jmp StartServe

Point  SUBROUTINE
        tax
        inc score,x
        stx server
        lda #ST_POINT
        sta state
        lda #0
        sta stateT
        sta blockPend
        sta bvxl
        sta bvxh
        sta bvyl
        sta bvyh
        lda #NX_NONE
        sta next
        lda demo
        bne .q
        lda #4
        sta AUDC1
        lda #10
        sta AUDV1
        lda #45
        sta sndT1
.q      rts

; suono: Y = 0 bagher, 1 schiacciata, 2 rete/terra, 3 battuta, 4 alzata/menu, 5 muro
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

; traiettoria verso (tx, th) in T fotogrammi: Y = 0 (64), 1 (32), 2 (16), 3 (128)
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
        lda bxh
        cmp #156
        bcc .inX
.outP   lda lastSide
        eor #1
        jmp Point
.inX    lda byh
        cmp #FLOOR
        bcc .land
        cmp #200
        bcc .air
.land   ldy #2
        jsr Sound
        lda bxh
        cmp #3
        bcc .outP
        cmp #153
        bcs .outP
        clc
        adc #2
        cmp #80
        lda #0
        rol
        eor #1
        jmp Point
.air    lda byh
        cmp #NETTOP+1
        bcs .noNet
        lda bxh
        cmp #74
        bcc .noNet
        cmp #82
        bcs .noNet
        lda bvxh
        bmi .fromR
        lda #73
        sta bxh
        lda #$FF
        sta bvxh
        lda #$C0
        sta bvxl
        bne .nd
.fromR  lda #83
        sta bxh
        lda #0
        sta bvxh
        lda #$40
        sta bvxl
.nd     lda #NX_NONE
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
        beq .no
        ; tipo di battuta dal joystick al lancio: su = altissima, verso la rete = in salto
        ldy joy,x
        tya
        and #$10
        beq .notUp
        lda #2
        bne .kind
.notUp  tya
        cpx #0
        beq .j0
        asl                     ; squadra destra: la rete è a sinistra
.j0     bpl .k0
        lda #1
        bne .kind
.k0     lda #0
        beq .kind
.ai     lda stateT
        cmp #60
        bcc .no
        lda rand
        and #7
        tay
        lda AiServe,y
.kind   sta serveKind
        lda #ST_TOSS
        sta state
        lda #1
        sta bvyh
        lda #$10
        sta bvyl
        lda #0
        sta bvxl
        sta bvxh
        sta stateT
        lda serveKind
        cmp #1
        bne .snd
        lda #$60                ; battuta in salto: la palla va avanti con la rincorsa
        sta bvxl
        lda server
        beq .snd
        lda #$A0
        sta bvxl
        lda #$FF
        sta bvxh
.snd    ldy #4
        jmp Sound
.no     rts

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
        ; battuta in salto: il battitore segue la palla e stacca
        lda serveKind
        cmp #1
        bne .nj
        lda server
        asl
        ora #1
        tax
        lda bxh
        ldy server
        sec
        sbc HoldOfs,y
        sta px,x
        lda stateT
        cmp #15
        bne .nj
        jsr Jump
.nj     inc stateT
        lda byh
        cmp #HAND-2
        bcs .up
        lda server
        eor #1
        jmp Point
.up     lda bvyh
        bpl .done
        ldy serveKind           ; finestra del colpo: più alta per la battuta in salto
        lda server
        jsr Human
        beq .ai
        ldx server
        lda press,x
        beq .done
        lda byh
        cmp WinLo,y
        bcc .bad
        cmp WinHi,y
        bcs .bad
        lda #0
        beq Serve
.bad    lda rand
        and #1
        beq Serve
        lda #2
        bne Serve
.ai     lda byh
        cmp WinAI,y
        bcs .done
        lda rand
        cmp #14
        lda #0
        bcs Serve
        lda #2
        bne Serve
.done   rts

; battuta: A = 0 buona, 2 in rete
Serve   sta temp3
        ldx server
        lda #1
        sta temp2
        lda joy,x
        cpx #0
        beq .j0
        asl
.j0     bpl .notNet
        lda #0
        sta temp2
        beq .dirOk
.notNet lda joy,x
        cpx #0
        bne .j1
        asl
.j1     bpl .dirOk
        lda #2
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
        lda NetTX,x
.ok     sta tx
        lda #FLOOR
        sta th
        ldy serveKind
        lda ServeT,y
        tay
        jsr Launch
        lda #ST_RALLY
        sta state
        lda server
        sta lastSide
        eor #1
        sta team
        lda #NX_RECV
        sta next
        ldy serveKind
        lda ServePen,y
        sta recvPen
        jsr AiError
        lda server
        asl
        ora #1
        tax
        lda #FR_SPIKE
        jsr SetPose
        ldy #3
        jmp Sound

; errore di piazzamento del computer in ricezione: più piccolo ai livelli alti e con la difficoltà A
AiError  SUBROUTINE
        lda rand
        and #15
        sec
        sbc #8
        ldx skill
        cpx #3
        bcc .k
        cmp #$80
        ror
.k      bit SWCHB
        bpl .k2
        cmp #$80
        ror
.k2     sta aiErr
        rts

SetPose  SUBROUTINE
        sta pose,x
        lda #12
        sta animT,x
        rts

; ---------------------------------------------------------------- scambio
RallyState  SUBROUTINE
        jsr MoveBall
        lda state
        cmp #ST_RALLY
        bne .done
        lda blockPend
        beq .nb
        lda bxh
        sec
        sbc #70
        cmp #13
        bcs .nb
        jmp Block
.nb     lda next
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

; bagher (o tuffo) del ricevitore della squadra "team"
Recv    SUBROUTINE
        jmp .start
.no0    rts
.start  lda byh
        cmp #DIGH+1
        bcs .no0
        lda bvyh
        bpl .no0
        lda team
        asl
        ora #1
        tax
        lda jT,x
        bne .no0
        lda bxh
        sec
        sbc px,x
        sec
        sbc #2                  ; dx = centro palla - centro giocatore
        sta temp2               ; dx con segno
        bpl .pos
        eor #$FF
        clc
        adc #1
.pos    sta temp                ; |dx|
        cmp #10
        bcc .dig
        cmp #23
        bcs .no0
        ; tuffo: la persona preme il pulsante, il computer ci prova da solo
        lda team
        jsr Human
        beq .aiDive
        ldy team
        lda press,y
        beq .no0
        bne .dive
.aiDive lda skill
        asl
        asl
        asl
        asl
        adc #70
        cmp rand
        bcc .no
.dive   lda temp2               ; il ricevitore si allunga verso la palla
        clc
        adc px,x
        sta px,x
        lda temp
        sec
        sbc #6
        sta temp
        lda #FR_DIVE
        jsr SetPose
        jmp .pass
.dig    lda #FR_BUMP
        jsr SetPose
.pass   lda temp
        clc
        adc recvPen
        sta temp
        lda #0
        sta recvPen
        sta dumpReq
        ldy team
        lda SetBallX,y
        sta tx
        lda temp
        sec
        sbc #3
        bcc .exact
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
.clamp  ldy team
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

; alzata: alta, primo tempo, seconda linea o palleggio di seconda (sorpresa)
SetBall SUBROUTINE
        ; la persona chiede il palleggio di seconda con VERSO LA RETE + pulsante mentre la palla arriva
        lda team
        jsr Human
        beq .nreq
        ldy team
        lda press,y
        beq .nreq
        lda joy,y
        cpy #0
        beq .q0
        asl
.q0     bpl .nreq
        sta dumpReq
.nreq   lda fT
        cmp #64
        beq .now
        rts
.now    lda team
        asl
        tax
        lda bxh
        sec
        sbc px,x
        clc
        adc #8
        cmp #18
        bcc .ok
        lda #NX_NONE            ; l'alzatore non è arrivato: la palla cade
        sta next
        rts
.ok     lda #FR_JUMP
        jsr SetPose
        ; tipo di alzata
        lda team
        jsr Human
        beq .ai
        lda dumpReq
        bne .dump
        ldy team
        lda joy,y
        and #$20
        bne .quick              ; giù: primo tempo
        lda joy,y
        cpy #0
        bne .b1
        asl
.b1     bmi .back               ; verso il fondo: seconda linea
        lda #0
        beq .typ
.ai     lda rand
        cmp skill
        bcc .dumpAi
        cmp #50
        bcc .quick
        cmp #110
        bcc .back
        lda #0
        beq .typ
.dumpAi lda skill
        cmp #2
        bcs .dump
        lda #0
        beq .typ
.quick  lda #1
        bne .typ
.back   lda #2
.typ    sta setType
        tay
        lda SetTH,y
        sta th
        lda team
        asl
        asl
        clc
        adc setType
        tax
        lda SetTX,x
        sta tx
        lda SetHitT,y
        sta tHit
        lda SetLT,y
        tay
        jsr Launch
        lda #NX_HIT
        sta next
        lda #0
        sta blockPend
        ldy #4
        jmp Sound
.dump   ; l'alzatore schiaccia di seconda appena oltre la rete
        ldy team
        lda DumpTX,y
        sta tx
        lda #FLOOR
        sta th
        ldy #1
        jsr Launch
        lda team
        asl
        tax
        lda #FR_SPIKE
        jsr SetPose
        lda team
        sta lastSide
        eor #1
        sta team
        lda #NX_RECV
        sta next
        jsr AiError
        ldy #1
        jmp Sound

; attacco
Attack  SUBROUTINE
        lda team
        asl
        ora #1
        tax                     ; X = attaccante
        lda tHit
        sec
        sbc #16
        cmp fT
        bne .nj
        jsr Jump                ; stacco: in cima al salto quando arriva la palla
.nj     ; muro avversario
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
        lda skill
        asl
        asl
        asl
        asl
        adc #60
        cmp rand
        bcc .blkDone
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
        sbc tHit                ; anticipo (-) o ritardo (+)
        clc
        adc #8
        cmp #15
        bcs .late               ; fuori dalla finestra
        sec
        sbc #8
        bpl .pp
        eor #$FF
        clc
        adc #1
.pp     sta temp3               ; errore di tempo
        ldy team
        lda joy,y
        and #$10
        beq .ndk
        jmp .dink
.ndk
        lda joy,y
        and #$20
        bne .power
        lda temp3
        cmp #6
        bcs .soft
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
        bcc .free
        rts
.ai     lda fT
        cmp tHit
        bne .done
        lda rand
        cmp #10
        bcc .free
        cmp #45
        bcc .dink
        cmp #95
        bcc .powerAi
        and #3
        cmp #3
        bne .spike
        lda #1
        bne .spike
.powerAi
        lda #0
        sta temp3
.power  lda temp3               ; potente: tempo sbagliato = fuori
        cmp #3
        bcc .pw
        ldy team
        lda OutTX,y
        sta tx
        ldy #2
        lda #FR_SPIKE
        bne .launch
.pw     ldy team
        lda PowerTX,y
        sta tx
        ldy #2
        lda #FR_SPIKE+$80       ; (bit 7: potente, muro più difficile)
        bne .launch
.done   rts
.free   ldy team
        lda FreeTX,y
        sta tx
        ldy #0
        lda #FR_JUMP
        bne .launch
.soft   lda #1
        sta temp
        ldy #1
        lda #FR_SPIKE
        bne .spk2
.dink   ldy team
        lda DinkTX,y
        sta tx
        ldy #1
        lda #FR_JUMP
        bne .launch
.spike  sta temp
        ldy #2                  ; schiacciata normale: 16 fotogrammi
        lda setType
        cmp #2
        bne .nb
        ldy #1                  ; seconda linea: più lunga (32)
.nb     lda #FR_SPIKE
.spk2   pha
        lda team
        asl
        asl
        clc
        adc temp
        tax
        lda SpikeTX,x
        sta tx
        pla
.launch sta temp2               ; posa (+ bit 7 = potente)
        lda #FLOOR
        sta th
        jsr Launch
        lda team
        asl
        ora #1
        tax
        lda temp2
        and #$7F
        jsr SetPose
        ; muro: l'alzatore avversario in aria (salto tra 6 e 26)?
        lda temp2
        and #$7F
        cmp #FR_SPIKE
        bne .noBlock
        lda team
        eor #1
        asl
        tax
        lda jT,x
        cmp #6
        bcc .noBlock
        cmp #27
        bcs .noBlock
        lda team
        eor #1
        jsr Human
        beq .aiCh
        lda #140
        bne .chance
.aiCh   lda skill
        asl
        asl
        asl
        asl
        adc #50
.chance ldy setType             ; primo tempo e seconda linea si murano meno
        cpy #1
        bne .c2
        lsr
.c2     cpy #2
        bne .c3
        lsr
        sta temp
        lsr
        adc temp
.c3     bit temp2
        bpl .c4
        lsr                     ; potente: metà
.c4     cmp rand
        bcc .noBlock
        lda #1
        sta blockPend
.noBlock
        lda team
        sta lastSide
        eor #1
        sta team
        lda #NX_RECV
        sta next
        ; ricezione più difficile dopo il primo tempo e la schiacciata potente
        lda #0
        bit temp2
        bpl .np
        lda #3
.np     ldy setType
        cpy #1
        bne .nq
        clc
        adc #1
.nq     sta recvPen
        jsr AiError
        ldy #1
        lda temp2
        and #$7F
        cmp #FR_SPIKE
        beq .snd
        ldy #0
.snd    jmp Sound

Block   SUBROUTINE
        lda #0
        sta blockPend
        lda team
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
        lda #FR_JUMP
        jsr SetPose
        ldy #5
        jmp Sound

; ---------------------------------------------------------------- giocatori
Players  SUBROUTINE
        lda #0
        sta moved
        ldx #3
.loop   stx temp3
        jsr Target
        ldx temp3
        sta temp2               ; obiettivo (non temp4: lo usa Human)
        ; persona: il ricevitore della squadra che riceve si muove col joystick
        lda screen
        cmp #SC_GAME
        bne .auto
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
        cmp temp2
        beq .phys
        bcs .gl
        jsr StepRight
        jsr Fast
        bne .phys
        lda px,x
        cmp temp2
        bcs .phys
        jsr StepRight
        jmp .phys
.gl     jsr StepLeft
        jsr Fast
        bne .phys
        lda px,x
        cmp temp2
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

; Z = 1 se il giocatore X corre veloce (alzatori, attaccante del primo tempo)
Fast    ldx temp3
        txa
        and #1
        beq .yes
        lda next
        cmp #NX_HIT
        bne .no
        lda setType
        cmp #1
        bne .no
        txa
        lsr
        cmp team
        bne .no
.yes    lda #0
        rts
.no     lda #1
        rts

StepRight
        lda frame
        and #1
        sec
        adc px,x
        jmp ClampX
StepLeft
        lda frame
        and #1
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
        pha
        lda BitOf,x
        ora moved
        sta moved
        pla
.nm     sta px,x
        rts

; obiettivo del giocatore temp3 (A = x)
Target  SUBROUTINE
        ldx temp3
        lda screen
        cmp #SC_GAME
        bne .stay
        lda state
        cmp #ST_RALLY
        beq .rally
        cmp #ST_TOSS
        beq .serve
        cmp #ST_SERVE
        bne .stay
.serve  txa
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
.home   lda HomeX,x
        rts
.rally  txa
        lsr
        cmp team
        beq .mine
        txa
        and #1
        bne .home
        lda next
        cmp #NX_SET
        bcc .home
        lda BlockX,x
        rts
.mine   txa
        and #1
        beq .setter
        lda next
        cmp #NX_RECV
        bne .notR
        lda tx
        sec
        sbc #2
        clc
        adc aiErr
        cmp #200
        bcc .okR
        lda #2
.okR    rts
.notR   cmp #NX_HIT
        beq .atk
        cmp #NX_SET
        bne .home
        lda ApproachX-1,x
        rts
.atk    ; rincorsa secondo il tipo di alzata
        lda setType
        asl
        asl
        clc
        adc temp3               ; tipo*4 + giocatore (1 o 3)
        tay
        lda fT
        cmp #24
        bcs .run
        lda AppTab-1,y
        rts
.run    lda TakeTab-1,y
        rts
.setter lda next
        cmp #NX_SET
        bne .home
        lda tx
        sec
        sbc #2
        rts

Jump    SUBROUTINE
        lda jT,x
        bne .no
        lda #1
        sta jT,x
.no     rts

; salto (da tabella) e fotogramma dell'animazione del giocatore X
Physics SUBROUTINE
        lda jT,x
        beq .g
        inc jT,x
        lda jT,x
        cmp #32
        bcc .g
        lda #0
        sta jT,x
.g      lda animT,x
        beq .nt
        dec animT,x
        lda pose,x
        bne .set
.nt     lda screen
        cmp #SC_GAME
        bne .nsv
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
        lda jT,x
        bne .nsv
        lda #FR_JUMP
        bne .set
.nsv    lda state
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
.nov    lda jT,x
        beq .onG
        lda #FR_JUMP
        bne .set
.onG    lda moved
        and BitOf,x
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

; palla ROSSA quando una persona deve colpire; segno di caduta per chi riceve
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
        ldy serveKind
        lda byh
        cmp WinLo,y
        bcc .mark
        cmp WinHi,y
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

; ---------------------------------------------------------------- dati del banco 0
BitOf      .byte 1, 2, 4, 8
;                 alz.sx att.sx alz.dx att.dx
HomeX      .byte 60,    22,    92,    130
ApproachX  .byte 28,    0,     124
BlockX     .byte 66,    0,     86
; rincorsa e stacco per tipo di alzata (indice tipo*4 + giocatore-1: 0 = att. sx, 2 = att. dx)
AppTab     .byte 28, 0, 124, 0,   52, 0, 100, 0,   14, 0, 136, 0
TakeTab    .byte 54, 0, 98, 0,    56, 0, 96, 0,    34, 0, 118, 0
ServeX     .byte 2, 150
HoldOfs    .byte 6, $FE
SetBallX   .byte 62, 94
SideMin    .byte 8, 88
SideMax    .byte 68, 148
; alzata: x della palla per squadra*4 + tipo (alta, primo tempo, seconda linea), altezza, tempo
SetTX      .byte 60, 64, 40, 0,   96, 92, 116, 0
SetTH      .byte HITH, HITH, HITH+1
SetHitT    .byte 64, 32, 64
SetLT      .byte 0, 1, 0
DumpTX     .byte 90, 66
SpikeTX    .byte 112, 126, 146, 0, 44, 30, 10, 0
PowerTX    .byte 120, 36
OutTX      .byte 158, 158
DinkTX     .byte 92, 64
FreeTX     .byte 126, 30
BlockTX    .byte 44, 112
ServeTX    .byte 100, 120, 144, 0, 56, 36, 12, 0
NetTX      .byte 70, 86
AiServe    .byte 0, 0, 1, 0, 1, 2, 0, 1      ; battute del computer: normale, in salto, altissima
ServeT     .byte 0, 1, 3                ; tempo della battuta: normale 64, in salto 32, altissima 128
ServePen   .byte 0, 2, 3
WinLo      .byte HAND+3, HAND+7, HAND+3
WinHi      .byte HAND+10, HAND+13, HAND+10
WinAI      .byte HAND+6, HAND+10, HAND+6
TargetPts  .byte 11, 15                  ; punti del set: palazzetto, spiaggia
LShift     .byte 2, 3, 4, 1
GcLo       .byte <410, <202, <98, <826
GcHi       .byte >410, >202, >98, >826
SndC       .byte $0C, $08, $0F, $04, $0C, $06
SndF       .byte $0C, $03, $1C, $09, $08, $14
SndV       .byte $0A, $0C, $0A, $08, $08, $0C
SndT       .byte 4, 10, 7, 5, 4, 8

        include "bank0.inc"

        ORG $0FC0
        RORG $FFC0
        STUBS
        ORG $0FFC
        RORG $FFFC
        .word $FFE0, $FFE0

; ============================================================================ BANCO 1: kernel della partita
        ORG $1000
        RORG $F000

GameKernel  SUBROUTINE
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
        sta WSYNC               ; riga 1
        lda demo
        beq .score
        lda #0
        sta CTRLPF
        ldx #0
.trow   ldy #4
.tline  sta WSYNC
        lda TCol,x
        sta COLUPF
        lda TL0,x
        sta PF0
        lda TL1,x
        sta PF1
        lda TL2,x
        sta PF2
        lda TR0,x
        sta PF0
        lda TR1,x
        sta PF1
        nop
        lda TR2,x
        sta PF2
        dey
        bne .tline
        inx
        cpx #5
        bne .trow
        jmp .topDone
.score  lda #2
        sta CTRLPF
        ldx #0
.srow   ldy #4
.sline  sta WSYNC
        lda ScoreGfx,x
        sta PF1
        SLEEP 30
        lda ScoreGfx+5,x
        sta PF1
        dey
        bne .sline
        inx
        cpx #5
        bne .srow
.topDone
        sta WSYNC
        lda #0
        sta PF0
        sta PF1
        sta PF2
        lda #$21
        sta CTRLPF
        sta WSYNC

        ldy #PAIRS-1
GameLoop
        sta WSYNC               ; --- riga A
        lda (BgPtr),y
        sta COLUBK
        lda (Pf0Ptr),y
        sta PF0
        lda (Pf1Ptr),y
        sta PF1
        lda #PH-1
        dcp P0D
        bcs .draw0
        lda #0
        sta GRP0
        lda #MARKCOL
        sta COLUP0
        jmp .p0done
.draw0  lda (P0Ptr),y
        sta GRP0
        lda (P0Col),y
        sta COLUP0
.p0done lda #BH-1
        dcp BlD
        lda #0
        rol
        rol
        sta ENAM1
        sta WSYNC               ; --- riga B
        lda (Pf2Ptr),y
        sta PF2
        lda (PfcPtr),y
        sta COLUPF
        lda #0
        dcp MkD
        lda #0
        rol
        rol
        sta ENAM0
        lda #PH-1
        dcp P1D
        bcs .draw1
        lda #0
        sta GRP1
        lda ballCol
        sta COLUP1
        dey
        bpl GameLoop
        rts
.draw1  lda (P1Ptr),y
        sta GRP1
        lda (P1Col),y
        sta COLUP1
        dey
        bpl GameLoop
        rts

        include "bank1.inc"

        ORG $1FC0
        RORG $FFC0
        STUBS
        ORG $1FFC
        RORG $FFFC
        .word $FFE0, $FFE0

; ============================================================================ BANCO 2: schermate
        ORG $2000
        RORG $F000

ScreenKernel  SUBROUTINE
        lda #0
        sta COLUBK
        sta GRP0
        sta GRP1
        sta ENAM0
        sta ENAM1
        sta PF0
        sta PF1
        sta PF2
        sta CTRLPF
        sta REFP0
        sta REFP1
        lda screen
        asl
        tax
        lda ScreenDraw+1,x
        pha
        lda ScreenDraw,x
        pha
        rts
ScreenDraw
        .word DrawTitle-1, DrawSelect-1, DrawIntro-1, 0, DrawOver-1, DrawChamp-1

; A righe vuote
Blank   SUBROUTINE
        tax
.b      sta WSYNC
        dex
        bne .b
        rts

; prepara la scritta A (colori: Y = 0 bianco, 1 giallo, 2 arancio, 3 grigio)
SetStr  SUBROUTINE
        sta WSYNC
        tax
        lda StrLo,x
        sta T0P
        lda StrHi,x
        sta T0P+1
        lda #5
        sta tRows
        lda #5
        jmp SetCols
; prepara il logo A (0 = SPIKE, 1 = FEVER)
SetLogo
        sta WSYNC
        tax
        lda LogoLo,x
        sta T0P
        lda LogoHi,x
        sta T0P+1
        lda #9
        sta tRows
        ldy #4
        lda #9
; puntatori delle 6 colonne (passo A) e dei colori (tabella Y)
SetCols
        sta temp
        ldx #0
.c      lda T0P,x
        clc
        adc temp
        sta T0P+2,x
        lda T0P+1,x
        adc #0
        sta T0P+3,x
        inx
        inx
        cpx #10
        bne .c
        lda ColTabLo,y
        sta TCP
        lda ColTabHi,y
        sta TCP+1
        ldy #0
        lda (TCP),y
        sta COLUPF
        rts

; disegna le righe della scritta (tRows righe da tLines linee), playfield asimmetrico
DrawRows  SUBROUTINE
        ldy #0
.row    ldx tLines
.line   sta WSYNC               ; 0
        lda (T0P),y             ; 5
        sta PF0                 ; 8
        lda (T1P),y             ; 13
        sta PF1                 ; 16
        lda (T2P),y             ; 21
        sta PF2                 ; 24
        lda (T3P),y             ; 29
        sta PF0                 ; 32  (28..49)
        lda (T4P),y             ; 37
        sta PF1                 ; 40  (39..54)
        nop                     ; 42
        lda (T5P),y             ; 47
        sta PF2                 ; 50  (50..65)
        lda (TCP),y
        sta COLUPF
        dex
        bne .line
        iny
        cpy tRows
        bne .row
        sta WSYNC
        lda #0
        sta PF0
        sta PF1
        sta PF2
        rts

; scritta completa: A = scritta, Y = colore, righe alte X linee
Text    SUBROUTINE
        stx tLines
        jsr SetStr
        jmp DrawRows

; bandiera della nazione A (12 righe da 4 linee): fondo, PF, COLUP0/COLUP1 (modo SCORE + riflesso)
DrawFlag  SUBROUTINE
        sta WSYNC
        tax
        lda FlagLo,x
        sta T0P
        lda FlagHi,x
        sta T0P+1
        lda #12
        sta temp
        ldx #0
.c      lda T0P,x
        clc
        adc temp
        sta T0P+2,x
        lda T0P+1,x
        adc #0
        sta T0P+3,x
        inx
        inx
        cpx #10
        bne .c
        lda #3
        sta CTRLPF
        ldy #0
.row    ldx #4
.line   sta WSYNC
        lda (T0P),y
        sta COLUBK
        lda (T1P),y
        sta PF0
        lda (T2P),y
        sta PF1
        lda (T3P),y
        sta PF2
        lda (T4P),y
        sta COLUP0
        lda (T5P),y
        sta COLUP1
        dex
        bne .line
        iny
        cpy #12
        bne .row
        sta WSYNC
        lda #0
        sta COLUBK
        sta PF0
        sta PF1
        sta PF2
        sta CTRLPF
        rts

; ---------------------------------------------------------------- titolo (come Power Spikes: logo grande sfumato)
DrawTitle  SUBROUTINE
        lda #3
        jsr Blank
        lda #0
        jsr SetLogo
        lda #3
        sta tLines
        jsr DrawRows            ; SPIKE
        lda #3
        jsr Blank
        lda #1
        jsr SetLogo
        lda #3
        sta tLines
        jsr DrawRows            ; FEVER
        sta WSYNC
        lda #$2A                ; filetto arancio sotto il logo
        sta COLUBK
        sta WSYNC
        sta WSYNC
        lda #0
        sta COLUBK
        ; quadro: schiacciata contro muro sopra la rete
        lda #52
        ldx #0
        jsr PosObj2
        lda #84
        ldx #1
        jsr PosObj2
        lda #66
        ldx #3
        jsr PosObj2
        sta WSYNC
        sta HMOVE
        lda #$05
        sta NUSIZ0
        lda #$25
        sta NUSIZ1
        lda #8
        sta REFP1
        lda #1
        sta CTRLPF
        lda #$80
        sta PF2
        lda #$06
        sta COLUPF
        lda #$82
        sta COLUBK
        lda #WHITE
        sta COLUP1
        lda #2
        sta ENAM1               ; la palla sopra la mano
        lda #4
        jsr Blank
        lda #0
        sta ENAM1
        ldx #PH-1
.prow   ldy #4
.pl     sta WSYNC
        lda TGfx+5*PH,x
        sta GRP0
        lda TCols,x
        sta COLUP0
        lda TGfx+3*PH,x
        sta GRP1
        lda TCols+PH,x
        sta COLUP1
        dey
        bne .pl
        dex
        bpl .prow
        sta WSYNC
        lda #0
        sta GRP0
        sta GRP1
        sta PF2
        lda #$2C
        sta COLUBK
        sta WSYNC
        sta WSYNC
        lda #0
        sta COLUBK
        sta CTRLPF
        sta NUSIZ0
        sta NUSIZ1
        sta REFP1
        lda #3
        jsr Blank
        ; menu: 1 PLAYER / 2 PLAYERS (quello scelto in giallo)
        ldy #1
        lda menuSel
        beq .m1
        ldy #3
.m1     lda #S_1P
        ldx #2
        jsr Text
        lda #2
        jsr Blank
        ldy #3
        lda menuSel
        beq .m2
        ldy #1
.m2     lda #S_2P
        ldx #2
        jsr Text
        lda #3
        jsr Blank
        lda #S_SC
        ldy #2
        ldx #2
        jsr Text
        lda #TITLE_PAD
        jmp Blank

; ---------------------------------------------------------------- scelta della squadra o dell'arena
DrawSelect  SUBROUTINE
        lda #8
        jsr Blank
        lda #S_SEL
        ldy #1
        ldx #3
        jsr Text
        lda #2
        jsr Blank
        lda selStep
        clc
        adc #S_P1
        cmp #S_P1+2
        bcc .p
        lda #S_ARENA
.p      ldy #0
        ldx #2
        jsr Text
        lda #8
        jsr Blank
        lda selStep
        cmp #2
        beq .ar
        tax
        lda nat,x
        pha
        jsr DrawFlag
        lda #8
        jsr Blank
        pla
        clc
        adc #S_NAT
        ldy #0
        ldx #3
        jsr Text
        jmp .fire
.ar     lda #60
        jsr Blank
        lda arena
        clc
        adc #S_ARN
        ldy #2
        ldx #3
        jsr Text
.fire   lda #8
        jsr Blank
        lda frame
        and #32
        beq .on
        lda #15
        jsr Blank
        jmp .end
.on     lda #S_FIRE
        ldy #1
        ldx #2
        jsr Text
.end    lda #SELECT_PAD
        jmp Blank

; ---------------------------------------------------------------- presentazione del livello
DrawIntro  SUBROUTINE
        lda #8
        jsr Blank
        lda level
        clc
        adc #S_STAGE
        ldy #1
        ldx #3
        jsr Text
        lda #6
        jsr Blank
        lda #S_VS
        ldy #0
        ldx #2
        jsr Text
        lda #6
        jsr Blank
        lda nat+1
        jsr DrawFlag
        lda #6
        jsr Blank
        lda nat+1
        clc
        adc #S_NAT
        ldy #0
        ldx #3
        jsr Text
        lda #4
        jsr Blank
        lda arena
        clc
        adc #S_ARN
        ldy #2
        ldx #2
        jsr Text
        lda #INTRO_PAD
        jmp Blank

; ---------------------------------------------------------------- game over
DrawOver  SUBROUTINE
        lda #20
        jsr Blank
        lda #S_OVER
        ldy #2
        ldx #4
        jsr Text
        lda #10
        jsr Blank
        lda nat
        jsr DrawFlag
        lda #10
        jsr Blank
        lda frame
        and #16
        beq .on
        lda #15
        jsr Blank
        jmp .e
.on     lda #S_CONT
        ldy #0
        ldx #2
        jsr Text
.e      lda #6
        jsr Blank
        lda #S_FIRE
        ldy #1
        ldx #2
        jsr Text
        lda #OVER_PAD
        jmp Blank

; ---------------------------------------------------------------- campione / vincitore
DrawChamp  SUBROUTINE
        lda #14
        jsr Blank
        lda #S_CHAMP
        ldx twoP
        beq .c
        lda #S_WIN
.c      ldy #1
        ldx #4
        jsr Text
        lda #10
        jsr Blank
        ldx winner
        lda twoP
        bne .w
        ldx #0
.w      lda nat,x
        pha
        jsr DrawFlag
        lda #8
        jsr Blank
        pla
        clc
        adc #S_NAT
        ldy #0
        ldx #3
        jsr Text
        lda #8
        jsr Blank
        lda #S_SC
        ldy #2
        ldx #2
        jsr Text
        lda #CHAMP_PAD
        jmp Blank

PosObj2  SUBROUTINE
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

; righe vuote finali di ogni schermata (per arrivare esattamente a 192)
TITLE_PAD  = 5
SELECT_PAD = 34
INTRO_PAD  = 38
OVER_PAD   = 37
CHAMP_PAD  = 38

ColTabLo   .byte <TxtWhite, <TxtYellow, <TxtOrange, <TxtGrey, <LogoCol
ColTabHi   .byte >TxtWhite, >TxtYellow, >TxtOrange, >TxtGrey, >LogoCol
LogoLo     .byte <LogoA, <LogoB
LogoHi     .byte >LogoA, >LogoB

        include "bank2.inc"

        ORG $2FC0
        RORG $FFC0
        STUBS
        ORG $2FFC
        RORG $FFFC
        .word $FFE0, $FFE0

; ============================================================================ BANCO 3: libero
        ORG $3000
        RORG $F000
        .byte 0
        ORG $3FC0
        RORG $FFC0
        STUBS
        ORG $3FFC
        RORG $FFFC
        .word $FFE0, $FFE0
