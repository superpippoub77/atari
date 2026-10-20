; ============================================================================ logica della partita (banco 0)
;  Chiamata una volta per fotogramma dal banco 1 (FarLogic, nell'overscan): stati, battuta, bagher, alzata,
;  attacco, muro, fisica della palla, suoni. I giocatori (corsa, salto, animazione) restano nel banco 1.
; ================================================================ logica (overscan)
Logic  SUBROUTINE              ; (fotogramma, casuale, console e joystick: nel banco 1, prima di FarLogic)
        lda showT
        beq .nst
        dec showT
        bne .nst
        lda msg                 ; finita la scritta: dopo LEVEL n viene VS squadra, poi il punteggio
        cmp #MSG_LEVEL
        bcc .clr
        cmp #MSG_VS
        bcs .clr
        adc #MSG_VS-MSG_LEVEL   ; (C = 0)
        jsr Say
        bne .nst
.clr    lda #0
        sta msg
.nst    inc fT
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
.n2     jsr Bounce              ; dopo il punto la palla rimbalza e rotola
        inc stateT
        lda state
        cmp #ST_POINT
        bne .n3
        lda stateT
        cmp #90
        bcc .play
        jsr AfterPoint
        jmp .play
.n3     ; fine partita. Campionato: vinto -> livello successivo, perso -> col pulsante si rigioca il
        ; livello (CONTINUE), se no dopo qualche secondo il titolo (come alla fine delle altre partite)
        jsr Champ0
        bcc .wait
        ldx winner
        bne .lost
        cmp #5
        bcs .wait               ; campioni: titolo
        lda press
        bmi .next
        lda stateT
        cmp #250
        bcc .play
.next   lda mode
        clc
        adc #$10
        sta mode
        bne .again
.lost   lda press
        bpl .wait
.again  lda #1
        sta req
        jmp B0Entry
.wait   lda stateT
        cmp #250
        bcc .play
        lda #0
        sta req
        jmp B0Entry
.play   ; (colore della palla nel banco 1 dopo il ritorno; i giocatori si muovono nel VBLANK: vedi Setup)
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

; la squadra A è comandata da una persona? (Z = 0 sì)  usa temp4
Human0  SUBROUTINE
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
        ; scritta: GAME SET; nel campionato YOU WIN!, CHAMPIONS! dopo l'ultimo livello o GAME OVER
        jsr Champ0
        ldy #MSG_GAMESET
        bcc .say2
        ldy #MSG_OVER
        cpx #0
        bne .say2
        ldy #MSG_WIN
        cmp #5
        bcc .say2
        ldy #MSG_CHAMP
.say2   sty msg
        lda #250
        sta showT
        lda #ST_OVER
        jmp Halt
.goOn   jmp StartServe

; punto alla squadra A (rally point: batte chi fa il punto)
Point  SUBROUTINE
        tax
        inc score,x
        stx server
        lda demo
        bne .quiet
        lda #4
        sta AUDC1
        lda #10
        sta AUDV1
        lda #45
        sta sndT1
.quiet  lda #ST_POINT
        jmp Halt

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
        jsr BallStep
        jmp .chk
; un passo della palla: posizione += velocità, gravità
BallStep
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
        rts
.chk    lda byh
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
        ldx #MSG_OUT
        jsr SayX
        jmp Point
.inX    ; a terra
        lda byh
        cmp #FLOOR
        bcc .land
        cmp #200
        bcc .air
.land   ldy #2
        jsr Sound
        ldx #3                  ; la palla rimbalza anche dopo il punto (Halt azzera la velocità)
.sv     lda bvxl,x
        sta temp,x
        dex
        bpl .sv
        lda lastSide
        eor #1
        ldx #MSG_OUT
        ldy bxh
        cpy #3
        bcc .say                ; oltre la linea di fondo: fuori
        cpy #153
        bcs .say
        tya
        clc
        adc #2
        cmp #80
        lda #0
        rol
        eor #1                  ; A = squadra che fa il punto
        cmp lastSide            ; ace: punto di chi batte, palla mai toccata (setType = $FF dalla battuta)
        bne .pt
        ldx next
        bne .pt                 ; (NX_RECV = 0)
        ldx setType
        inx
        bne .pt
        ldx #MSG_ACE
.say    jsr SayX
.pt     jsr Point
        ldx #3
.rs     lda temp,x
        sta bvxl,x
        dex
        bpl .rs
        jmp Rebound
.air    ; rete: la palla tocca il nastro e cade
        lda byh
        cmp #NETTOP+1
        bcs .noNet
        lda bxh
        cmp #74                 ; la palla (4 pixel) tocca la rete (pixel 76-83): zona simmetrica 74..81
        bcc .noNet
        cmp #82
        bcs .noNet
        lda #73                 ; torna nella metà da cui arriva
        ldx bvxh
        bpl .fromL
        lda #83
.fromL  sta bxh
        ; la rete frena la palla (come nel gioco completo): vx = -(vx/8 + vx/16), vy = vy/4 + vy/16 se
        ; scende (0 se sale), poi una spinta verso il basso
        ldx #0
        stx temp                ; somma
        lda #3
        ldy #1
        jsr Scale
        jsr Neg0
        ldx #2
        lda bvyh
        bmi .dn
        lda #0
        sta bvyl
        sta bvyh
        beq .vy
.dn     lda #2
        ldy #2
        jsr Scale
.vy     lda bvyl
        sec
        sbc #$20
        sta bvyl
        bcs .netDone
        dec bvyh
.netDone
        ldx #MSG_NET
        jsr SayX
        lda #NX_NONE
        sta next
        lda #0
        sta blockPend
        ldy #2
        jmp Sound
.noNet  rts

; palla dopo il punto: rimbalza e rotola finché non si ferma (o esce dallo schermo)
Bounce  SUBROUTINE
        lda bvxl
        ora bvxh
        ora bvyl
        ora bvyh
        beq .rts
        jsr BallStep
        lda bxh
        cmp #156
        bcs .stop
        lda byh                 ; contro la rete torna indietro, più piano
        cmp #NETTOP+1
        bcs .nn
        lda bxh
        cmp #74
        bcc .nn
        cmp #82
        bcs .nn
        lda #73
        ldx bvxh
        bpl .l
        lda #82
.l      sta bxh
        ldx #0
        stx temp
        jsr Neg0
        lda #1
        ldy #2
        jsr Scale
.nn     lda byh
        cmp #FLOOR
        bcc Rebound
        cmp #200
        bcs Rebound
.rts    rts
.stop   lda #0
        sta bvxl
        sta bvxh
        sta bvyl
        sta bvyh
        rts
; la palla tocca terra (dal gioco completo: vy = -0,45 vy, vx = 0,6 vx): vy = -(vy/2 - vy/16),
; vx = vx/2 + vx/8; sotto una soglia smette di saltare, poi rotola frenando fino a fermarsi
Rebound lda #FLOOR
        sta byh
        lda #0
        sta byl
        ldx #2
        jsr Neg0
        lda #$FF
        sta temp                ; differenza
        lda #1
        ldy #3
        jsr Scale
        lda bvyh
        bne .bnc
        lda bvyl
        cmp #$50
        bcs .bnc
        lda #0
        sta bvyl
        beq .vx
.bnc    ldy #2
        jsr Sound
.vx     ldx #0
        stx temp                ; somma
        lda #1
        ldy #2
        jsr Scale
        lda bvxh                ; quasi ferma (|vx| < 1/8): si ferma
        beq .hi0
        cmp #$FF
        bne .r2
        lda bvxl
        cmp #$E0
        bcs .zero
.r2     rts
.hi0    lda bvxl
        cmp #$20
        bcs .r2
.zero   lda #0
        sta bvxl
        sta bvxh
        rts

; velocità X (0 = vx, 2 = vy) cambiata di segno
Neg0    lda #0
        sec
        sbc bvxl,x
        sta bvxl,x
        lda #0
        sbc bvxh,x
        sta bvxh,x
        rts
; velocità X: v' = v/2^A + v/2^(A+Y) (temp = 0) oppure v/2^A - v/2^(A+Y) (temp = $FF); usa temp2, temp3
Scale   SUBROUTINE
        sta temp3
.s1     lda bvxh,x              ; v/2 con segno
        cmp #$80
        ror bvxh,x
        ror bvxl,x
        dec temp3
        bne .s1
        lda bvxl,x
        sta temp2
        lda bvxh,x
        sta temp3
.s2     lda bvxh,x
        cmp #$80
        ror bvxh,x
        ror bvxl,x
        dey
        bne .s2
        lda temp
        bne .sub
        clc
        lda temp2
        adc bvxl,x
        sta bvxl,x
        lda temp3
        adc bvxh,x
        sta bvxh,x
        rts
.sub    sec
        lda temp2
        sbc bvxl,x
        sta bvxl,x
        lda temp3
        sbc bvxh,x
        sta bvxh,x
        rts

; ---------------------------------------------------------------- battuta
ServeState  SUBROUTINE
        inc stateT
        jsr HoldBall
        lda server
        jsr Human0
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
        jsr Human0
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
        lda #$FF                ; battuta: la palla non è ancora stata toccata (ace)
        sta setType
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
; livello del computer (Y = 0-3) dalle levette; nel campionato almeno quello del livello. Usa temp4
Diff    SUBROUTINE
        lda SWCHB
        asl
        rol
        rol
        and #3
        tay
        lda mode
        and #2
        ora demo
        bne .d
        sty temp4
        lda mode
        lsr
        lsr
        lsr
        lsr
        tay
        lda LevDiff,y
        cmp temp4
        bcs .k
        lda temp4
.k      tay
.d      rts

; scritta A per un secondo (Say) o X (SayX, A invariato); esce con Z = 0
Say     tax
SayX    stx msg
        ldx #60
        stx showT
        rts

; campionato? (1 PLAYER, non in dimostrazione): C = 1 e A = livello (0-5); X e Y invariati
Champ0  SUBROUTINE
        lda mode
        and #2
        ora demo
        bne .no
        lda mode
        lsr
        lsr
        lsr
        lsr
        sec
        rts
.no     clc
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
        ; palla veloce: il computer sbaglia di più (gioco completo: penalità di ricezione per la velocità)
        lda bvxh
        bpl .ps
        eor #$FF
.ps     cmp #2
        bcc .slow
        lda aiErr               ; errore x 1,5
        cmp #$80
        ror
        clc
        adc aiErr
        sta aiErr
.slow   rts

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
        beq .go
        rts
.go
        lda team
        asl
        tax                     ; la prima linea: l'alzatore palleggia
        lda #10
        jsr SetPose
        lda mode                ; 2 contro 2: alza sempre al difensore, che attacca a rete
        and #4
        beq .four
        lda #3
        bne .typ
.four   ; tipo di alzata: persona = joystick (giù primo tempo, verso il fondo seconda linea), computer a caso
        lda team
        jsr Human0
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
.quick  jsr Jump0                ; primo tempo: la prima linea stacca subito
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
        lda setType             ; 4 contro 4: se la prima linea si e' spostata per l'alzata,
        cmp #2                  ; la palla va dove ora c'e' chi attacca (non dalla seconda linea)
        bcs .nd
        lda team
        asl
        tay
        lda px,y
        sec
        sbc HomeX0,y
        clc
        adc tx
        sta tx
.nd     lda #HITH
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
        jsr Jump0                ; stacco: in cima al salto quando arriva la palla
.nj     ; muro: l'alzatore avversario salta col pulsante (persona) o da solo (computer)
        lda team
        eor #1
        jsr Human0
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
        jsr Jump0
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
        jsr Jump0
.blkDone
        ; colpo
        lda team
        jsr Human0
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
        sta temp3               ; qualità del colpo (0 = tempo perfetto)
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
        ldx #0                  ; computer: ogni tanto una schiacciata potente
        cmp #216
        bcs .aq
        ldx #2
.aq     stx temp3
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
.dink   lda #MSG_DINK
        jsr Say
        ldy team
        lda DinkTX,y
        sta tx
        ldy #1
        lda #3
        bne .launch
; schiacciata: A = 0 corta, 1 media, 2 lunga
.spike  sta temp
        ldx setType             ; primo tempo veloce (16 fotogrammi), palla alta e seconda linea 32
        ldy SpikeLT,x
        lda SpikeMsg,x          ; SPIKE! / QUICK! / BACK SPIKE
        ; qualità del colpo (come nel gioco completo): in perfetto tempo la schiacciata è potente
        ; (16 fotogrammi, POWER HIT!), al limite del tempo una volta su due finisce in rete
        ldx temp3
        bne .q1
        ldy #2
        lda #MSG_POWER
.q1     jsr Say
        lda temp3
        cmp #4
        bne .sp2
        lda rand
        bpl .sp2
        ldy team
        lda NetTX,y
        sta tx
        ldy #1
        lda #5
        bne .launch
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
        jsr Human0
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
        lda #MSG_BLOCK
        jsr Say
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
        lda #11                 ; muro: braccia tese
        jsr SetPose
        ldy #1
        jmp Sound

; ---------------------------------------------------------------- giocatori: obiettivi, movimento, salto, animazione

; copia per il banco 0 di Jump (serve anche ai giocatori, nel banco 1)
Jump0   SUBROUTINE
        lda pz,x
        bne .no
        lda #1
        sta pvz,x
        lda #$28
        sta pvzf,x
        lda #0
        sta pzf,x
.no     rts

; tabelle della logica
SetTX      .byte 34, 64, 24, 60, 118, 88, 132, 96  ; alzata (sx, dx): palla alta, primo tempo, seconda linea, 2c2
SetHitT    .byte 64, 16, 64, 64
SetLT      .byte 0, 2, 0, 0
SpikeLT    .byte 1, 2, 1, 1
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
SpikeMsg   .byte MSG_SPIKE, MSG_SPIKE+2, MSG_SPIKE+3, MSG_SPIKE   ; palla alta, primo tempo, seconda linea, 2c2
; campionato: CHINA, BRAZIL, USA, CUBA, JAPAN, USSR
LevDiff    .byte 0, 1, 1, 2, 2, 3          ; livello minimo del computer
LevBeach   .byte 0, 1, 0, 1, 0, 0          ; 1 = spiaggia
TargetPts  .byte 15, 21
BlkCh      .byte 50, 80, 110, 140
LShift     .byte 2, 3, 4
GcLo       .byte <410, <202, <98
GcHi       .byte >410, >202, >98
SndC       .byte $0C, $08, $0F, $04
SndF       .byte $0C, $03, $1C, $09
SndV       .byte $0A, $0C, $0A, $08
SndT       .byte 4, 10, 7, 5
