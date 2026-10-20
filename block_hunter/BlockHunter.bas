   ;*************************************************************************************************************************
   ; BLOCK HUNTER 2600
   ;_________________________________________________________________________________________________________________________
   ; Versione Atari 2600 (8K con Superchip, F8SC, PAL) di Block Hunter: si
   ; scende in miniera in 6 livelli; in ogni livello si raccolgono gli
   ; oggetti (uno alla volta, gemme, chiave, dinamite, cuori, assi) e poi si
   ; esce dall'uscita. Rocce che cadono, massi che rotolano dai bordi e si
   ; spaccano, buche, sabbia che rallenta, porte, pipistrello, ragno,
   ; serpente e fantasma.
   ;
   ; Il playfield ha 22 righe di 4 linee (pfres = 22, nella RAM della
   ; Superchip): una casella del gioco e' 2x2 pixel del playfield (8x8) e
   ; il suo tipo e' scritto nel motivo dei 4 pixel (vedi get_pat).
   ; Coordinate: PX, PY = pixel del giocatore dall'angolo del playfield
   ; (la casella tx, ty comincia a 8*tx, 8*ty); player0x = PX+17,
   ; player0y = PY+8.
   ;*************************************************************************************************************************
   set kernel_options pfcolors
   set tv pal
   set romsize 8kSC
   const pfres = 22
   const pfscore = 1

   dim level = a
   dim nlives = b
   dim dyn = c
   dim frame = d
   dim pdir = e
   dim jumpt = f
   dim jdir = g
   dim invul = h
   dim slow = i
   dim planks = j
   ; flags: bit 0 chiave, bit 1 uscita aperta, bit 2 dinamite in volo,
   ; bit 5 in cammino, bit 6 pulsante tenuto, bit 7 guarda a sinistra
   dim flags = k
   dim itemi = l
   dim itemt = m
   dim dynd = n
   dim dynl = o
   dim sfxid = p
   dim sfxt = q
   dim rockt = r
   dim rockw = s
   dim rockp = t
   dim bldt = u
   dim bldm = v
   dim mux = w
   dim enq = x
   ; fase: 0 gioco, 1 disegno della mappa, 2 inizio livello, 3 partita
   ; finita, 4 livello finito, 5 torna al titolo
   dim phase = y
   dim rng = z
   dim PX = var0
   dim PY = var1
   dim DX = var2
   dim DY = var3
   dim lvlo = var4
   dim lvhi = var5
   ; nemici (2 posti): x, y, info (bit 0-1 tipo, 2-4 direzione, 5-6 voli
   ; del pipistrello, 7 vivo), velocita', timer del cambio, stato
   ; (riposo del pipistrello, attesa prima di rientrare), partenza
   dim ex = var6
   dim ey = var8
   dim et = var10
   dim etm = var12
   dim ect = var14
   dim est = var16
   dim espawn = var18
   ; massi (4 posti): casella (riga*16+colonna, 0 vuoto), info (bit 0-1
   ; direzione, bit 2 pezzo, bit 3 rotolamento, bit 4-7 motivo sotto)
   dim bpos = var20
   dim binfo = var24
   dim lflags = var28
   dim lrock = var29
   dim lbside = var30
   dim lbevery = var31
   dim startpos = var32
   dim exitpos = var33
   dim nen = var34
   dim nitems = var35
   dim lbg = var36
   dim itempos = var37
   dim phaset = var38
   dim expl = var39
   dim lightt = var40
   dim muspos = var41
   dim must = var42
   dim gp_v = var43
   dim sp_p = var44
   dim sp_v = var45
   dim tA = var46
   dim tB = var47

   ;*************************************************************************************************************************
   ; TITOLO
   ;*************************************************************************************************************************
   ; all'accensione la RAM della Superchip e' a caso: livello di partenza 1
   w000 = 0 : w001 = 0
__title
   gosub __title_init bank2
__title_loop
   gosub __title_frame bank2
   drawscreen
   if switchselect then goto __title_select
   w001 = 0
   if !joy0fire && !switchreset then goto __title_loop
__start
   AUDV0 = 0 : AUDV1 = 0
   drawscreen
   if joy0fire || switchreset then goto __start
   asm
 jsr new_game
end
__game
   asm
 jsr game_frame
end
   gosub __world bank2
   drawscreen
   if switchreset then goto __start
   if phase = 5 then goto __title
   goto __game

__title_select
   ; Select: livello di partenza (le tacche a destra)
   if r001 then goto __title_loop
   w001 = 1
   temp1 = r000 + 1
   if temp1 > 5 then temp1 = 0
   w000 = temp1
   goto __title_loop

   asm
   ;*************************************************************************************************************************
   ; ROUTINE DELLE CASELLE usate da tutti e due i banchi (una copia per
   ; banco: TILEW 1 in questo, TILEW 2 nel banco 2; le etichette finiscono
   ; per 1 o 2)
   ;*************************************************************************************************************************
 MAC TILEW
   ; casella A (riga*16+colonna) -> A = 8*colonna, Y = 8*riga
pos_xy{1}
 pha
 and #$F0
 lsr
 tay
 pla
 and #$0F
 asl
 asl
 asl
 rts

   ; A = motivo, X = tx, Y = ty
set_pat{1}
 sta sp_p
 tya
 asl
 asl
 asl
 ora txb{1},x
 tay
 lda sp_p
 lsr
 lsr
 jsr sp_row{1}
 iny
 iny
 iny
 iny
 lda sp_p
sp_row{1}
 and #3
 sta sp_v
 lda mL{1},x
 ora mR{1},x
 eor #$FF
 and playfield,y
 lsr sp_v
 bcc sp_1{1}
 ora mR{1},x
sp_1{1}
 lsr sp_v
 bcc sp_2{1}
 ora mL{1},x
sp_2{1}
 sta playfield-128,y
 rts

txb{1}
 .byte 0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3
mL{1}
 .byte $80,$20,$08,$02,$01,$04,$10,$40,$80,$20,$08,$02,$01,$04,$10,$40
mR{1}
 .byte $40,$10,$04,$01,$02,$08,$20,$80,$40,$10,$04,$01,$02,$08,$20,$80
 ENDM

 TILEW 1
pos_xy = pos_xy1
set_pat = set_pat1
txb = txb1
mL = mL1
mR = mR1
   ;*************************************************************************************************************************
   ; NUOVA PARTITA E NUOVO LIVELLO
   ;*************************************************************************************************************************
new_game
 lda #0
 sta score
 sta score+1
 sta score+2
 sta flags
 lda #5
 sta nlives
 lda #6
 sta dyn
 lda r000
 sta level
 lda rng
 bne ng_1
 lda #$5A
 sta rng
ng_1
 lda #6
 sta phase
 rts

   ; giocatore sulla casella di partenza
start_pos
 lda startpos
 jsr pos_xy
 sta PX
 sty PY
 lda #4
 sta pdir
 rts

   ; oggetto di turno (dopo l'ultimo: l'uscita)
load_item
 lda itemi
 cmp nitems
 bcc li_1
 lda #5
 sta itemt
 lda exitpos
 sta itempos
 lda flags
 ora #2
 sta flags
 rts
li_1
 asl
 tay
 lda r011,y
 sta itemt
 lda r012,y
 sta itempos
 rts

   ; nemico successivo della coda nel posto X (se la coda e' finita il
   ; posto resta vuoto)
spawn_next
 lda #0
 sta et,x
 sta est,x
 lda enq
 cmp nen
 bcs sn_done
 inc enq
 asl
 tay
 lda r003,y
 ora #$80
 sta et,x
 lda r004,y
 sta espawn,x
 jsr enemy_home
sn_done
 rts

   ; il nemico X torna alla sua casella di partenza
enemy_home
 lda espawn,x
 stx tA
 jsr pos_xy
 ldx tA
 sta ex,x
 tya
 sta ey,x
 lda #20
 sta ect,x
 lda #0
 sta est,x
 lda et,x
 and #$83
 sta et,x
 rts

   ;*************************************************************************************************************************
   ; UN FRAME DI GIOCO
   ;*************************************************************************************************************************
game_frame
 inc frame
 jsr rnd8
 lda phase
 beq gf_play
 ; fasi 1 e 6 (mappa da disegnare): nel banco 2
 cmp #2
 bcc gf_draw0
 cmp #6
 bne gf_n1
gf_draw0
 jmp gf_draw
gf_n1
 dec phaset
 bne gf_draw0
 cmp #2
 bne gf_n2
 lda #0
 sta phase
 beq gf_draw0
gf_n2
 cmp #4
 bne gf_n4
 ; livello finito: il successivo (dopo il sesto si ricomincia, +1 vita)
 inc level
 lda level
 cmp #6
 bcc gf_n3
 lda #0
 sta level
 jsr life_up
gf_n3
 lda #6
 sta phase
 jmp gf_draw
gf_n4
 ; partita finita: al titolo
 lda #5
 sta phase
 rts

gf_play
 lda invul
 beq gp_1
 dec invul
gp_1
 lda slow
 beq gp_2
 dec slow
gp_2
 lda expl
 beq gp_3
 dec expl
gp_3
 jsr input
 lda jumpt
 beq gp_walk
 jsr jump_step
 jmp gp_4
gp_walk
 jsr move_player
 jsr tile_effects
gp_4
 jsr dyn_step
 ldx #0
 jsr enemy_step
 ldx #1
 jsr enemy_step
 jsr contacts
 jsr rocks_step
 jsr boulders_step
 ; (continua nel disegno)

   ;*************************************************************************************************************************
   ; DISEGNO: sprite, colori, barre
   ;*************************************************************************************************************************
gf_draw
 ; giocatore
 lda PX
 clc
 adc #17
 sta player0x
 lda PY
 clc
 adc #8
 sta player0y
 ldx #7
 stx player0height
 lda pdir
 tax
 lda dirspr,x
 tay
 lda flags
 and #$20
 beq gd_1
 lda frame
 and #8
 beq gd_1
 iny
gd_1
 lda jumpt
 beq gd_2
 ldy #6
gd_2
 lda phase
 cmp #3
 bne gd_3
 ldy #7
gd_3
 lda hero_lo,y
 sta player0pointerlo
 lda #>spr_hero_r0
 sta player0pointerhi
 lda pdir
 cmp #5
 lda #0
 bcc gd_4
 lda #8
gd_4
 sta REFP0
 lda #$2E
 ldx invul
 beq gd_5
 lda frame
 and #4
 beq gd_5a
 lda #$26
 bne gd_5
gd_5a
 lda #$2E
gd_5
 sta COLUP0
 ; dinamite (missile 0)
 lda flags
 and #4
 beq gd_6
 lda DX
 clc
 adc #17
 sta missile0x
 lda DY
 clc
 adc #10
 sta missile0y
 jmp gd_7
gd_6
 lda #200
 sta missile0y
gd_7
 lda #2
 sta missile0height
 lda #$10
 sta NUSIZ0
 ; oggetto di turno (ball)
 jsr draw_item
 ; barre: dinamite a sinistra, vite a destra (nemici, colori e suoni
 ; nel banco 2)
 ldx dyn
 cpx #9
 bcc gd_8
 ldx #8
gd_8
 lda bars,x
 sta pfscore1
 ldx nlives
 cpx #9
 bcc gd_9
 ldx #8
gd_9
 lda bars,x
 sta pfscore2
 lda #$2A
 sta pfscorecolor
 ; all'inizio del livello a sinistra il numero del livello (tacche azzurre)
 lda phase
 beq gd_10
 cmp #3
 bcs gd_10
 ldx level
 lda bars+1,x
 sta pfscore1
 lda #$9A
 sta pfscorecolor
gd_10
 lda #$0E
 sta scorecolor
 rts

   ; sprite del giocatore per direzione (0 su ... 7 su-sinistra)
dirspr
 .byte 2,2,0,4,4,4,0,2
hero_lo
 .byte <spr_hero_r0,<spr_hero_r1,<spr_hero_u0,<spr_hero_u1,<spr_hero_d0,<spr_hero_d1,<spr_hero_j,<spr_hero_x

   ; oggetto: la ball nella meta' alta della casella (colore della riga
   ; chiara); larghezza e altezza per tipo, gemme e uscita lampeggiano
draw_item
 lda phase
 cmp #2
 bcs di_off
 cmp #1
 beq di_off
 ldx itemt
 lda itemblink,x
 and frame
 bne di_off
 lda itempos
 jsr pos_xy
 clc
 adc itemdx,x
 adc #17
 sta ballx
 tya
 clc
 adc itemdy,x
 sta bally
 lda itemh,x
 sta ballheight
 lda itemw,x
 ora #1
 sta CTRLPF
 rts
di_off
 lda #200
 sta bally
 lda #$21
 sta CTRLPF
 rts

   ; tipi: 0 gemma, 1 chiave, 2 cassa, 3 cuore, 4 asse, 5 uscita
itemw
 .byte $20,$10,$30,$20,$30,$30
itemdx
 .byte 2,3,0,2,0,0
itemdy
 .byte 4,4,4,4,6,4
itemh
 .byte 3,3,3,3,1,3
itemblink
 .byte 16,0,0,4,0,32

bars
 .byte %00000000,%10000000,%11000000,%11100000,%11110000,%11111000,%11111100,%11111110,%11111111

   ;*************************************************************************************************************************
   ; CASELLE DEL PLAYFIELD
   ; Una casella (tx 0-15, ty 0-10) e' fatta dai pixel 2tx e 2tx+1 delle
   ; righe 2ty e 2ty+1. Motivo: bit 3 alto-sinistra, 2 alto-destra, 1
   ; basso-sinistra, 0 basso-destra.
   ;   0 pavimento   15 muro    3 buca      9 sabbia     10 porta
   ;   7 roccia o masso (11 masso che rotola, 2 pezzo di masso)
   ;   1 buca coperta dall'asse / ombra della roccia che cade
   ;*************************************************************************************************************************
   ; A = tx, Y = ty -> A = motivo (X = tx)
get_pat
 tax
 tya
 asl
 asl
 asl
 ora txb,x
 tay
 jsr gp_row
 asl
 asl
 sta tB
 iny
 iny
 iny
 iny
 jsr gp_row
 ora tB
 rts
gp_row
 lda #0
 sta gp_v
 lda playfield,y
 and mL,x
 cmp #1
 rol gp_v
 lda playfield,y
 and mR,x
 cmp #1
 rol gp_v
 lda gp_v
 rts

   ; casella A (riga*16+colonna): motivo e scrittura
pat_pos
 pha
 lsr
 lsr
 lsr
 lsr
 tay
 pla
 and #$0F
 jmp get_pat
set_pos
 sta tB
 txa
 pha
 lsr
 lsr
 lsr
 lsr
 tay
 pla
 and #$0F
 tax
 lda tB
 jmp set_pat

   ; motivo nel punto (A = x, Y = y in pixel)
pat_at
 lsr
 lsr
 lsr
 sta temp7
 tya
 lsr
 lsr
 lsr
 sta sp_v
 tay
 lda temp7
 jmp get_pat

   ; passabile per il giocatore nel punto A, Y -> Z = 0 se si passa
pass_at
 jsr pat_at
 sta tA
 tax
 lda pass,x
 and #1
 rts

   ; per motivo: bit 0 passa il giocatore (e la dinamite e il serpente),
   ; bit 1 passa il ragno, bit 2 rotola il masso, bit 3 roccia o masso
pass
 .byte 7,7,8,1,0,0,0,8,0,5,0,8,0,0,0,0

end

   asm
   ;*************************************************************************************************************************
   ; COMANDI: pulsante con la levetta = salto di 2 caselle, pulsante con
   ; la levetta al centro = dinamite nella direzione in cui guardi
   ;*************************************************************************************************************************
input
 lda INPT4
 bmi in_rel
 lda flags
 and #$40
 bne in_done
 lda flags
 ora #$40
 sta flags
 lda jumpt
 bne in_done
 lda SWCHA
 lsr
 lsr
 lsr
 lsr
 tax
 lda dirtab,x
 bmi in_dyn
 ; salto: direzione cardinale (con la diagonale vince l'orizzontale)
 tax
 lda jcard,x
 jmp try_jump
in_dyn
 jmp throw_dyn
in_rel
 lda flags
 and #$BF
 sta flags
in_done
 rts

   ; levetta (SWCHA/16) -> direzione 0-7, $FF al centro
dirtab
 .byte $FF,$FF,$FF,$FF,$FF,3,1,2,$FF,5,7,6,$FF,4,0,$FF
jcard
 .byte 0,1,1,1,2,3,3,3
   ; direzioni 0-7 (0 su, in senso orario)
dx1
 .byte 0,1,1,1,0,255,255,255
dy1
 .byte 255,255,0,1,1,1,0,255
dx3
 .byte 0,3,3,3,0,253,253,253
dy3
 .byte 253,253,0,3,3,3,0,253
   ; direzioni cardinali 0-3 (su, destra, giu', sinistra)
cdx
 .byte 0,1,0,255
cdy
 .byte 255,0,1,0
cpos
 .byte $F0,1,$10,$FF

   ; salto nella direzione cardinale A: la casella in mezzo non deve
   ; essere muro o porta, quella d'arrivo libera
try_jump
 sta jdir
 tax
 lda cdx,x
 asl
 asl
 asl
 sta temp1
 lda cdy,x
 asl
 asl
 asl
 sta temp2
 ; in mezzo (centro + 8)
 lda PX
 clc
 adc #4
 adc temp1
 pha
 lda PY
 clc
 adc #4
 adc temp2
 tay
 pla
 jsr pat_at
 cmp #15
 beq tj_no
 cmp #10
 beq tj_no
 ; arrivo (+16): i 4 angoli
 lda PX
 clc
 adc temp1
 adc temp1
 sta temp3
 cmp #113
 bcs tj_no
 lda PY
 clc
 adc temp2
 adc temp2
 sta temp4
 cmp #73
 bcs tj_no
 jsr box_free
 bne tj_no
 lda #8
 sta jumpt
 lda #6
 jmp sfx
tj_no
 rts

   ; i 4 angoli del riquadro del giocatore in temp3, temp4 sono liberi? (Z = 1)
box_free
 lda temp3
 clc
 adc #1
 ldy temp4
 iny
 jsr pass_at
 beq bf_no
 lda temp3
 clc
 adc #6
 ldy temp4
 iny
 jsr pass_at
 beq bf_no
 lda temp4
 clc
 adc #6
 tay
 lda temp3
 clc
 adc #1
 jsr pass_at
 beq bf_no
 lda temp4
 clc
 adc #6
 tay
 lda temp3
 clc
 adc #6
 jsr pass_at
 beq bf_no
 lda #0
 rts
bf_no
 lda #1
 rts

jump_step
 dec jumpt
 ldx jdir
 lda cdx,x
 asl
 clc
 adc PX
 sta PX
 lda cdy,x
 asl
 clc
 adc PY
 sta PY
 lda jumpt
 bne js_1
 jmp tile_effects
js_1
 rts

   ;*************************************************************************************************************************
   ; MOVIMENTO: un pixel per frame (sulla sabbia uno ogni 2); riquadro di
   ; 6x6 pixel; contro uno spigolo il giocatore scivola nel passaggio
   ;*************************************************************************************************************************
move_player
 lda flags
 and #$DF
 sta flags
 lda SWCHA
 lsr
 lsr
 lsr
 lsr
 tax
 lda dirtab,x
 bmi mp_done
 sta pdir
 lda flags
 ora #$20
 sta flags
 lda slow
 beq mp_go
 lda frame
 lsr
 bcs mp_done
mp_go
 ldx pdir
 lda dx1,x
 beq mp_v
 sta temp6
 ; orizzontale: bordo d'arrivo
 bmi mp_l
 lda PX
 clc
 adc #7
 bne mp_h
mp_l
 lda PX
mp_h
 jsr hmove
mp_v
 ldx pdir
 lda dy1,x
 beq mp_done
 sta temp6
 bmi mp_u
 lda PY
 clc
 adc #7
 bne mp_vv
mp_u
 lda PY
mp_vv
 jmp vmove
mp_done
 rts

   ; movimento orizzontale di temp6 (+1/-1) con il bordo nella colonna A
hmove
 sta temp3
 ldy PY
 iny
 jsr pass_at
 sta temp1
 jsr door_try
 lda PY
 clc
 adc #6
 tay
 lda temp3
 jsr pass_at
 sta temp2
 jsr door_try
 lda temp1
 and temp2
 beq hm_1
 lda PX
 clc
 adc temp6
 sta PX
 rts
hm_1
 ; scivola verso il lato libero se lo spigolo e' a meno di 5 pixel
 lda temp1
 beq hm_2
 ; sopra libero: sale
 lda PY
 clc
 adc #6
 and #7
 cmp #4
 bcs hm_3
 dec PY
 rts
hm_2
 lda temp2
 beq hm_3
 lda PY
 and #7
 cmp #4
 bcc hm_3
 inc PY
hm_3
 rts

   ; movimento verticale di temp6 con il bordo nella riga A
vmove
 sta temp4
 tay
 lda PX
 clc
 adc #1
 jsr pass_at
 sta temp1
 jsr door_try
 ldy temp4
 lda PX
 clc
 adc #6
 jsr pass_at
 sta temp2
 jsr door_try
 lda temp1
 and temp2
 beq vm_1
 lda PY
 clc
 adc temp6
 sta PY
 rts
vm_1
 lda temp1
 beq vm_2
 lda PX
 clc
 adc #6
 and #7
 cmp #4
 bcs vm_3
 dec PX
 rts
vm_2
 lda temp2
 beq vm_3
 lda PX
 and #7
 cmp #4
 bcc vm_3
 inc PX
vm_3
 rts

   ; dopo pass_at: se il motivo (tA) e' una porta e c'e' la chiave, si apre
   ; (pat_at lascia la casella in temp7, sp_v)
door_try
 lda tA
 cmp #10
 bne dt_no
 lda flags
 lsr
 bcc dt_no
 ldx temp7
 ldy sp_v
 lda #0
 jsr set_pat
 lda #4
 jmp sfx
dt_no
 rts

   ; effetti della casella sotto il centro del giocatore
tile_effects
 lda PX
 clc
 adc #4
 sta temp3
 lsr
 lsr
 lsr
 sta temp1
 lda PY
 clc
 adc #4
 tay
 lsr
 lsr
 lsr
 asl
 asl
 asl
 asl
 ora temp1
 sta temp2
 lda temp3
 jsr pat_at
 cmp #3
 bne te_1
 ; buca: con l'asse si copre, se no si cade
 lda planks
 beq te_fall
 dec planks
 lda #1
 ldy temp2
 ldx temp1
 tya
 lsr
 lsr
 lsr
 lsr
 tay
 lda #1
 jsr set_pat
 lda #4
 jmp sfx
te_fall
 lda #9
 jsr sfx
 jsr hurt_force
 jmp start_pos
te_1
 cmp #9
 bne te_2
 lda #150
 sta slow
te_2
 lda temp2
 cmp itempos
 bne te_3
 jmp collect
te_3
 rts

   ; raccoglie l'oggetto di turno
collect
 lda itemt
 cmp #5
 bne co_1
 ; uscita: livello finito
 lda #$01
 ldx #1
 jsr add_score
 lda #4
 sta phase
 lda #100
 sta phaset
 lda #16
 sta muspos
 lda #1
 sta must
 rts
co_1
 tax
 beq co_gem
 dex
 beq co_key
 dex
 beq co_box
 dex
 beq co_life
 inc planks
 bne co_next
co_gem
 lda #$50
 jsr add_score0
 jmp co_next
co_key
 lda flags
 ora #1
 sta flags
 bne co_next
co_box
 lda dyn
 clc
 adc #3
 cmp #9
 bcc co_b
 lda #8
co_b
 sta dyn
 jmp co_next
co_life
 jsr life_up
co_next
 inc itemi
 jsr load_item
 lda #3
 jmp sfx

life_up
 lda nlives
 cmp #8
 bcs lu_1
 inc nlives
lu_1
 rts

   ; punti: A = BCD da sommare alle unita' (add_score0) o, con X = 1,
   ; alle centinaia
add_score0
 ldx #0
add_score
 sed
 cpx #1
 bne as_u
 clc
 adc score+1
 sta score+1
 jmp as_t
as_u
 clc
 adc score+2
 sta score+2
 lda score+1
 adc #0
 sta score+1
as_t
 lda score
 adc #0
 sta score
 cld
 rts

   ; -20 punti (non sotto zero)
minus20
 sed
 sec
 lda score+2
 sbc #$20
 sta score+2
 lda score+1
 sbc #0
 sta score+1
 lda score
 sbc #0
 sta score
 cld
 bcs m2_1
 lda #0
 sta score
 sta score+1
 sta score+2
m2_1
 rts

   ; colpito: una vita in meno e qualche secondo di invulnerabilita'
   ; (durante il salto e l'invulnerabilita' non succede niente)
hurt
 lda invul
 ora jumpt
 bne hu_no
hurt_force
 lda #110
 sta invul
 lda #5
 jsr sfx
 dec nlives
 bne hu_no
 lda #3
 sta phase
 lda #150
 sta phaset
 lda #24
 sta muspos
 lda #1
 sta must
hu_no
 rts
end

   asm
   ;*************************************************************************************************************************
   ; DINAMITE: va dritta (3 pixel per frame) ed esplode contro un muro, una
   ; roccia, un masso o una porta; rocce e massi nelle 3x3 caselle intorno
   ; saltano (+10 ciascuno)
   ;*************************************************************************************************************************
throw_dyn
 lda flags
 and #4
 bne td_no
 lda dyn
 beq td_no
 dec dyn
 lda flags
 ora #4
 sta flags
 lda PX
 clc
 adc #3
 sta DX
 lda PY
 clc
 adc #3
 sta DY
 lda pdir
 sta dynd
 lda #40
 sta dynl
 lda #1
 jmp sfx
td_no
 rts

dyn_step
 lda flags
 and #4
 beq ds_no
 dec dynl
 beq dyn_off
 ldx dynd
 lda DX
 clc
 adc dx3,x
 sta DX
 cmp #118
 bcs dyn_boom
 cmp #8
 bcc dyn_boom
 lda DY
 clc
 adc dy3,x
 sta DY
 cmp #78
 bcs dyn_boom
 cmp #8
 bcc dyn_boom
 ldy DY
 iny
 lda DX
 clc
 adc #1
 jsr pass_at
 bne ds_no
 ; contro qualcosa di solido: esplode nella casella
 lda tA
 cmp #2
 beq ds_rock
 cmp #7
 beq ds_rock
 cmp #11
 bne dyn_boom
ds_rock
 jsr explode_rocks
dyn_boom
 lda #6
 sta expl
 lda #2
 jsr sfx
dyn_off
 lda flags
 and #$FB
 sta flags
ds_no
 rts

   ; le rocce nelle 3x3 caselle intorno al punto della dinamite saltano
explode_rocks
 lda DY
 clc
 adc #1
 lsr
 lsr
 lsr
 sec
 sbc #1
 sta temp5
 lda DX
 clc
 adc #1
 lsr
 lsr
 lsr
 sec
 sbc #1
 sta temp4
 lda #8
 sta temp3
er_loop
 ldx temp3
 lda er_dx,x
 clc
 adc temp4
 beq er_next
 cmp #15
 bcs er_next
 sta temp1
 lda er_dy,x
 clc
 adc temp5
 beq er_next
 cmp #10
 bcs er_next
 sta temp2
 tay
 lda temp1
 jsr get_pat
 tax
 lda pass,x
 and #8
 beq er_next
 ; e' un masso? torna il motivo che aveva sotto
 lda temp2
 asl
 asl
 asl
 asl
 ora temp1
 jsr boulder_at
 bcc er_rock
 jsr boulder_remove
 jmp er_pts
er_rock
 lda #0
 ldx temp1
 ldy temp2
 jsr set_pat
er_pts
 lda #$10
 jsr add_score0
er_next
 dec temp3
 bpl er_loop
 rts
er_dx
 .byte 0,1,1,1,0,255,255,255,0
er_dy
 .byte 255,255,0,1,1,1,0,255,0

   ;*************************************************************************************************************************
   ; NEMICI
   ; pipistrello: vola sopra i muri, cambia direzione a caso, dopo 4 voli
   ;   riposa 2 secondi; ti ruba una gemma (se no toglie una vita)
   ; ragno: va di casella in casella, ti insegue se sei vicino, evita buche
   ;   e sabbia; -20 punti e una vita
   ; serpente: di casella in casella a caso; il morso toglie una vita e
   ;   fa ricominciare il livello; ucciso, torna dopo un po'
   ; fantasma: passa i muri, la dinamite non gli fa niente
   ;*************************************************************************************************************************
enemy_step
 lda et,x
 bmi es_alive
 ; posto vuoto o nemico morto in attesa
 lda est,x
 beq es_wait0
 dec est,x
 bne es_ret
 lda et,x
 and #3
 cmp #2
 bne es_next
 ; il serpente torna
 lda et,x
 ora #$80
 sta et,x
 jmp enemy_home
es_next
 jmp spawn_next
es_wait0
es_ret
 rts
es_alive
 lda phase
 bne es_ret
 lda et,x
 and #3
 tay
 lda etm,x
 clc
 adc espeed,y
 sta etm,x
 bcc es_ret
 cpy #1
 beq es_grid
 cpy #2
 beq es_grid
 ; ----- volanti: pipistrello (0) e fantasma (3)
 lda est,x
 beq es_f1
 dec est,x
 rts
es_f1
 dec ect,x
 bne es_fmove
 lda #35
 sta ect,x
 jsr rnd8
 cmp #110
 bcs es_fmove
 ; nuova direzione a caso
 and #7
 asl
 asl
 sta tA
 lda et,x
 and #$E3
 ora tA
 sta et,x
 tya
 bne es_fmove
 ; pipistrello: dopo 4 voli riposa
 lda et,x
 clc
 adc #$20
 and #$60
 sta tA
 lda et,x
 and #$9F
 ora tA
 sta et,x
 lda tA
 bne es_fmove
 lda #100
 sta est,x
 rts
es_fmove
 lda et,x
 lsr
 lsr
 and #7
 tay
 lda ex,x
 clc
 adc dx1,y
 cmp #8
 bcc es_bounce
 cmp #113
 bcs es_bounce
 sta ex,x
 lda ey,x
 clc
 adc dy1,y
 cmp #8
 bcc es_bounce
 cmp #73
 bcs es_bounce
 sta ey,x
 rts
es_bounce
 lda et,x
 eor #$10
 sta et,x
 rts

 ; ----- di casella in casella: ragno (1) e serpente (2)
es_grid
 lda ex,x
 ora ey,x
 and #7
 beq es_choose
 jmp es_gmove
es_choose
 stx temp6
 cpy #2
 beq es_snake
 ; ragno: insegue entro 8 caselle
 lda PX
 sec
 sbc ex,x
 sta temp1
 bcs es_s1
 eor #$FF
 adc #1
es_s1
 sta temp3
 lda PY
 sec
 sbc ey,x
 sta temp2
 bcs es_s2
 eor #$FF
 adc #1
es_s2
 sta temp4
 cmp #64
 bcs es_rnd
 lda temp3
 cmp #64
 bcs es_rnd
 ; asse principale verso il giocatore, poi l'altro
 lda temp3
 cmp temp4
 bcc es_sv
 jsr es_hdir
 jsr es_try
 bcs es_go
 jsr es_vdir
 jsr es_try
 bcs es_go
 bcc es_rnd
es_sv
 jsr es_vdir
 jsr es_try
 bcs es_go
 jsr es_hdir
 jsr es_try
 bcs es_go
 bcc es_rnd
es_snake
 ; serpente: tiene la direzione, ogni tanto cambia
 jsr rnd8
 and #7
 beq es_rnd
 ldx temp6
 lda et,x
 lsr
 lsr
 lsr
 and #3
 jsr es_try
 bcs es_go
es_rnd
 ; direzione libera a caso (al massimo 4 prove)
 jsr rnd8
 and #3
 sta temp5
 lda #4
 sta temp4
es_r1
 lda temp5
 jsr es_try
 bcs es_go
 inc temp5
 lda temp5
 and #3
 sta temp5
 dec temp4
 bne es_r1
 ldx temp6
 rts
es_go
 ; A = direzione cardinale -> bit 2-4 (0, 2, 4, 6)
 ldx temp6
 asl
 asl
 asl
 sta tA
 lda et,x
 and #$E3
 ora tA
 sta et,x
es_gmove
 lda et,x
 lsr
 lsr
 and #7
 tay
 lda ex,x
 clc
 adc dx1,y
 sta ex,x
 lda ey,x
 clc
 adc dy1,y
 sta ey,x
 rts

 ; direzione cardinale verso il giocatore: orizzontale (temp1) o verticale (temp2)
es_hdir
 lda temp1
 bmi es_h1
 lda #1
 rts
es_h1
 lda #3
 rts
es_vdir
 lda temp2
 bmi es_v1
 lda #2
 rts
es_v1
 lda #0
 rts

 ; si puo' andare nella direzione A? (C = 1 si', A resta la direzione)
es_try
 sta temp7
 ldx temp6
 tay
 lda ex,x
 lsr
 lsr
 lsr
 clc
 adc cdx,y
 pha
 lda ey,x
 lsr
 lsr
 lsr
 clc
 adc cdy,y
 tay
 pla
 jsr get_pat
 tax
 lda pass,x
 sta tA
 ldx temp6
 lda et,x
 and #3
 cmp #1
 bne es_t1
 lsr tA
es_t1
 lsr tA
 lda temp7
 rts

   ; velocita' (frazione di pixel per frame): pipistrello, ragno, serpente, fantasma
espeed
 .byte 128,128,85,90

   ;*************************************************************************************************************************
   ; CONTATTI (collisioni del frame prima, con il nemico mostrato allora)
   ;*************************************************************************************************************************
contacts
 lda mux
 and #1
 tax
 ; dinamite contro il nemico
 bit CXM0P
 bpl ct_1
 lda flags
 and #4
 beq ct_1
 lda et,x
 bpl ct_1
 and #3
 cmp #3
 beq ct_1
 tay
 lda killpts,y
 jsr add_score0
 lda et,x
 and #$7F
 sta et,x
 lda #100
 sta est,x
 jsr dyn_boom
ct_1
 bit CXPPMM
 bpl ct_no
 lda et,x
 bpl ct_no
 lda invul
 ora jumpt
 bne ct_no
 lda et,x
 and #3
 beq ct_bat
 cmp #2
 beq ct_snake
 cmp #1
 bne ct_hurt
 jsr minus20
ct_hurt
 jmp hurt
ct_bat
 ; il pipistrello ruba l'ultima gemma presa (torna al suo posto)
 ldy itemi
 beq ct_hurt
 dey
 tya
 asl
 tay
 lda r011,y
 bne ct_hurt
 dec itemi
 lda flags
 and #$FD
 sta flags
 jsr load_item
 lda #60
 sta invul
 lda #8
 jmp sfx
ct_snake
 ; morso: una vita e si ricomincia il livello
 jsr hurt
 lda phase
 bne ct_no
 lda #6
 sta phase
ct_no
 rts

killpts
 .byte $12,$20,$20,$00
end

   asm
   ;*************************************************************************************************************************
   ; ROCCE CHE CADONO: ogni tanto su una casella di pavimento con le 4
   ; vicine di pavimento (cosi' non chiudono mai un passaggio); prima
   ; lampeggia l'ombra per un secondo, poi la roccia resta li'
   ;*************************************************************************************************************************
rocks_step
 lda lrock
 beq rs_no
 lda rockw
 beq rs_wait
 dec rockw
 beq rs_land
 ; ombra che lampeggia (se nel frattempo e' arrivato un masso, niente)
 lda rockp
 jsr pat_pos
 cmp #2
 bcs rs_cancel
 lda rockw
 lsr
 lsr
 and #1
 ldx rockp
 jmp set_pos
rs_cancel
 lda #0
 sta rockw
 rts
rs_land
 lda rockp
 jsr pat_pos
 cmp #2
 bcs rs_cancel
 lda #7
 ldx rockp
 jsr set_pos
 lda #7
 jsr sfx
 lda lrock
 sta rockt
 lda rockp
 jsr hits_player
 bcc rs_no
 jmp hurt
rs_wait
 lda rockt
 beq rs_pick
 lda frame
 and #15
 bne rs_no
 dec rockt
rs_no
 rts
rs_pick
 ; casella a caso: colonna 1-14, riga 1-9
 jsr rnd8
 and #$0F
 beq rs_no
 cmp #15
 beq rs_no
 sta temp1
 jsr rnd8
 and #$0F
 beq rs_no
 cmp #10
 bcs rs_no
 sta temp2
 asl
 asl
 asl
 asl
 ora temp1
 sta temp3
 cmp exitpos
 beq rs_no
 ldy nitems
rs_it
 dey
 bmi rs_it2
 tya
 asl
 tax
 lda r012,x
 cmp temp3
 bne rs_it
 rts
rs_it2
 ; la casella e le 4 vicine devono essere pavimento
 ldx #4
rs_n
 stx temp4
 lda temp3
 clc
 adc rs_off,x
 jsr pat_pos
 bne rs_no
 ldx temp4
 dex
 bpl rs_n
 lda temp3
 sta rockp
 lda #50
 sta rockw
 rts
rs_off
 .byte 0,1,$FF,16,$F0

   ; la casella A tocca il riquadro del giocatore? (C = 1)
hits_player
 ldx #7
 .byte $2C
near_player
 ldx #24
 stx gp_v
 jsr pos_xy
 sec
 sbc PX
 bcs hp_1
 eor #$FF
 adc #1
hp_1
 cmp gp_v
 bcs hp_no
 tya
 sec
 sbc PY
 bcs hp_2
 eor #$FF
 adc #1
hp_2
 cmp gp_v
 bcs hp_no
 sec
 rts
hp_no
 clc
 rts

   ;*************************************************************************************************************************
   ; MASSI: entrano dai lati del livello e rotolano di casella in casella;
   ; contro un ostacolo si spaccano in 2 pezzi che vanno di lato (i pezzi
   ; si sbriciolano), nelle buche cadono. Toccano il giocatore: una vita.
   ;*************************************************************************************************************************
boulders_step
 lda lbside
 and #$0F
 beq bs_no
 lda frame
 and #15
 bne bs_move
 dec bldt
 bne bs_move
 lda lbevery
 sta bldt
 jsr boulder_spawn
bs_move
 inc bldm
 lda lbside
 lsr
 lsr
 lsr
 and #$1E
 cmp bldm
 bcs bs_hit
 lda #0
 sta bldm
 ldx #3
bs_loop
 lda bpos,x
 beq bs_l1
 stx temp6
 jsr boulder_move
 ldx temp6
bs_l1
 dex
 bpl bs_loop
bs_hit
 ; un masso sul giocatore
 ldx #3
bs_h1
 lda bpos,x
 beq bs_h2
 stx temp6
 jsr hits_player
 ldx temp6
 bcc bs_h2
 lda invul
 ora jumpt
 bne bs_h2
 jsr boulder_remove
 jmp hurt
bs_h2
 dex
 bpl bs_h1
bs_no
 rts

   ; un nuovo masso da un lato a caso fra quelli del livello
boulder_spawn
 ldx #3
bsp_1
 lda bpos,x
 beq bsp_2
 dex
 bpl bsp_1
 rts
bsp_2
 stx temp6
 jsr rnd8
 and #3
 tay
 lda #4
 sta temp5
bsp_3
 lda lbside
 and sidebit,y
 bne bsp_4
 iny
 tya
 and #3
 tay
 dec temp5
 bne bsp_3
 rts
bsp_4
 sty temp4
 ; corsia a caso
 jsr rnd8
 and #$0F
 ldy temp4
 cpy #2
 bcs bsp_v
 ; da sinistra o da destra: riga 1-9
 cmp #9
 bcc bsp_r
 sbc #8
bsp_r
 clc
 adc #1
 asl
 asl
 asl
 asl
 ora sidecol,y
 jmp bsp_5
bsp_v
 ; dall'alto o dal basso: colonna 1-14
 cmp #14
 bcc bsp_c
 sbc #13
bsp_c
 clc
 adc #1
 ora sidecol,y
bsp_5
 sta temp3
 ; lontano dal giocatore e su una casella dove si rotola
 jsr near_player
 bcs bsp_no
 lda temp3
 jsr pat_pos
 tax
 lda pass,x
 and #4
 beq bsp_no
 ldx temp6
 lda temp3
 sta bpos,x
 ldy temp4
 lda sidedir,y
 sta binfo,x
 lda temp3
 jsr pat_pos
 asl
 asl
 asl
 asl
 ldx temp6
 ora binfo,x
 sta binfo,x
 lda #7
 ldx temp3
 jmp set_pos
bsp_no
 lda #1
 sta bldt
 rts
   ; lati L R U D: bit, colonna o riga d'ingresso, direzione
sidebit
 .byte 1,2,4,8
sidecol
 .byte 1,14,$10,$90
sidedir
 .byte 1,3,2,0

   ; il masso X va avanti di una casella
boulder_move
 lda binfo,x
 and #3
 tay
 lda bpos,x
 clc
 adc cpos,y
 sta temp3
 jsr pat_pos
 sta temp2
 cmp #3
 beq bm_fall
 tax
 lda pass,x
 and #4
 beq bm_block
 ; avanti: rimette il motivo di prima, si segna quello nuovo
 ldx temp6
 jsr boulder_restore
 ldx temp6
 lda temp3
 sta bpos,x
 lda binfo,x
 and #$0F
 eor #8
 sta tA
 lda temp2
 asl
 asl
 asl
 asl
 ora tA
 sta binfo,x
 jmp boulder_draw
bm_fall
 lda #9
 jsr sfx
 ldx temp6
 jmp boulder_remove
bm_block
 ; contro un ostacolo: il masso intero si spacca, il pezzo si sbriciola
 ldx temp6
 lda binfo,x
 and #7
 sta temp5
 lda bpos,x
 sta temp4
 jsr boulder_remove
 lda #8
 jsr sfx
 lda temp5
 and #4
 bne bm_done
 ; pezzi nelle due caselle di lato
 lda temp5
 clc
 adc #1
 jsr bm_piece
 lda temp5
 clc
 adc #3
 jmp bm_piece
bm_done
 rts
   ; pezzo nella direzione A (0-3) dalla casella temp4
bm_piece
 and #3
 sta temp1
 tay
 lda temp4
 clc
 adc cpos,y
 sta temp3
 jsr pat_pos
 sta temp2
 tax
 lda pass,x
 and #4
 beq bp_no
 ldx #3
bp_1
 lda bpos,x
 beq bp_2
 dex
 bpl bp_1
bp_no
 rts
bp_2
 lda temp3
 sta bpos,x
 lda temp2
 asl
 asl
 asl
 asl
 ora temp1
 ora #4
 sta binfo,x
 stx temp6
   ; disegna il masso X (intero: 7 o 11 a passi alterni; pezzo: 2)
boulder_draw
 ldy #2
 lda binfo,x
 and #4
 bne bd_1
 ldy #7
 lda binfo,x
 and #8
 beq bd_1
 ldy #11
bd_1
 tya
 pha
 lda bpos,x
 tax
 pla
 jmp set_pos

   ; toglie il masso X rimettendo il motivo che aveva sotto
boulder_remove
 jsr boulder_restore
 ldx temp6
 lda #0
 sta bpos,x
 rts
boulder_restore
 lda binfo,x
 lsr
 lsr
 lsr
 lsr
 pha
 lda bpos,x
 tax
 pla
 jmp set_pos

   ; c'e' un masso nella casella A? (C = 1, X = posto, anche in temp6)
boulder_at
 ldx #3
ba_1
 cmp bpos,x
 beq ba_yes
 dex
 bpl ba_1
 clc
 rts
ba_yes
 stx temp6
 sec
 rts

   ;*************************************************************************************************************************
   ; NUMERI A CASO (LFSR a 8 bit)
   ;*************************************************************************************************************************
rnd8
 lda rng
 lsr
 bcc ra_1
 eor #$B4
ra_1
 sta rng
 rts

   ;*************************************************************************************************************************
   ; SUONI: effetti sul canale 0, musica sul canale 1
   ;*************************************************************************************************************************
sfx
 sta sfxid
 tax
 lda sfxdur,x
 sta sfxt
 rts
sfxdur
 .byte 0,6,20,10,8,30,8,10,10,24

end

   bank 2

__title_init
   asm
 jsr title_init
end
   return otherbank
__title_frame
   asm
 jsr title_frame
end
   return otherbank
__world
   asm
 jsr world
end
   return otherbank

   asm
 TILEW 2

   ;*************************************************************************************************************************
   ; OGNI FRAME, dopo la logica del banco 1: inizio del livello e disegno
   ; della mappa, nemico da mostrare, colori, suoni
   ;*************************************************************************************************************************
world
 lda phase
 cmp #6
 bne wo_1
 jsr init_level
wo_1
 lda phase
 cmp #1
 bne wo_2
 jsr load_row
 inc phaset
 lda phaset
 cmp #10
 bcc wo_2
 lda #2
 sta phase
 lda #60
 sta phaset
wo_2
 jsr draw_enemy
 jsr colors
 jsr sfx_update
 jmp music

   ;*************************************************************************************************************************
   ; TITOLO: scritta nel playfield con l'arcobaleno che scorre, musica
   ;*************************************************************************************************************************
title_init
 ldx #87
ti_copy
 lda title_pf,x
 sta playfield-128,x
 dex
 bpl ti_copy
 lda #0
 sta phase
 sta AUDV0
 lda #254
 sta muspos
 lda #1
 sta must
 ldx #200
 stx player0y
 stx player1y
 stx missile0y
 stx missile1y
 stx bally
 rts

title_frame
 inc frame
 ; arcobaleno: lo spostamento (pari, 0-20) cresce ogni 4 frame
 lda frame
 lsr
 lsr
 and #$1F
 cmp #21
 bcc tf_1
 sbc #21
tf_1
 and #$FE
 asl
 asl
 sta temp1
 lda #<(rainbow_ptr+88)
 sec
 sbc temp1
 sta pfcolortable
 lda #>rainbow_ptr
 sta pfcolortable+1
 lda #$0E
 sta COLUPF
 lda #0
 sta COLUBK
 lda #$21
 sta CTRLPF
 lda #$1E
 sta scorecolor
 ; livello di partenza: tacche a destra
 ldx r000
 inx
 lda bars2,x
 sta pfscore2
 lda #0
 sta pfscore1
 lda #$2C
 sta pfscorecolor
 jmp music

   ;*************************************************************************************************************************
   ; INIZIO DEL LIVELLO (o ripresa dopo il morso del serpente): legge
   ; l'intestazione, copia nella Superchip la coda dei nemici (w003) e gli
   ; oggetti (w011), svuota il playfield con il bordo di muro; la mappa si
   ; disegna poi una riga per frame (fase 1)
   ;*************************************************************************************************************************
init_level
 ldx level
 lda lv_lo,x
 sta lvlo
 lda lv_hi,x
 sta lvhi
 ldy #0
 lda (lvlo),y
 sta startpos
 iny
 lda (lvlo),y
 sta exitpos
 iny
 lda (lvlo),y
 sta lflags
 iny
 lda (lvlo),y
 sta lbg
 iny
 lda (lvlo),y
 sta lrock
 sta rockt
 iny
 lda (lvlo),y
 sta lbside
 iny
 lda (lvlo),y
 sta lbevery
 sta bldt
 iny
 lda (lvlo),y
 sta nen
 asl
 sta tA
 ldx #0
il_e
 cpx tA
 bcs il_e2
 iny
 lda (lvlo),y
 sta w003,x
 inx
 bne il_e
il_e2
 iny
 lda (lvlo),y
 sta nitems
 asl
 sta tA
 ldx #0
il_i
 cpx tA
 bcs il_i2
 iny
 lda (lvlo),y
 sta w011,x
 inx
 bne il_i
il_i2
 iny
 sty w002
 ; playfield: bordo di muro, dentro vuoto
 ldx #87
il_clr
 lda #$FF
 cpx #8
 bcc il_c1
 cpx #80
 bcs il_c1
 txa
 and #3
 tay
 lda border,y
il_c1
 sta playfield-128,x
 dex
 bpl il_clr
 ; stato del livello
 lda #0
 sta itemi
 sta rockw
 sta jumpt
 sta slow
 sta planks
 sta expl
 sta enq
 sta bldm
 sta et
 sta et+1
 sta bpos
 sta bpos+1
 sta bpos+2
 sta bpos+3
 lda flags
 and #$40
 sta flags
 ; i nemici entrano al primo frame di gioco
 lda #1
 sta est
 sta est+1
 ; giocatore sulla partenza
 lda startpos
 jsr pos_xy2
 sta PX
 sty PY
 lda #4
 sta pdir
 ; primo oggetto (o subito l'uscita)
 lda r011
 sta itemt
 lda r012
 sta itempos
 lda nitems
 bne il_it
 lda #5
 sta itemt
 lda exitpos
 sta itempos
 lda flags
 ora #2
 sta flags
il_it
 lda #1
 sta phase
 sta phaset
 lda #8
 sta muspos
 lda #1
 sta must
 rts

border
 .byte $C0,0,0,$C0
   ; codice della mappa -> motivo
codepat
 .byte 0,15,3,9,7,10

   ; disegna la riga phaset (1-9) della mappa
load_row
 lda phaset
 cmp #10
 bcs lr_done
 sta tA
 ; nibble = (riga-1)*14 + (colonna-1)
 sec
 sbc #1
 sta tB
 asl
 asl
 asl
 asl
 sec
 sbc tB
 sbc tB
 sta tB
 lda #1
 sta temp5
lr_loop
 lda tB
 lsr
 clc
 adc r002
 tay
 lda tB
 lsr
 lda (lvlo),y
 bcs lr_lo
 lsr
 lsr
 lsr
 lsr
lr_lo
 and #$0F
 tay
 lda codepat,y
 beq lr_next
 ldx temp5
 ldy tA
 jsr set_pat2
lr_next
 inc tB
 inc temp5
 lda temp5
 cmp #15
 bcc lr_loop
lr_done
 rts

   ; nemico da mostrare: si alternano i due posti vivi (bit 0 di mux:
   ; mostrato ora, bit 1: nel frame prima, per le collisioni)
draw_enemy
 lda mux
 and #1
 asl
 sta mux
 lsr
 eor #1
 tax
 lda et,x
 bmi de_1
 txa
 eor #1
 tax
 lda et,x
 bmi de_1
 lda #200
 sta player1y
 rts
de_1
 txa
 ora mux
 sta mux
 lda phase
 bne de_off
 lda ex,x
 clc
 adc #17
 sta player1x
 lda ey,x
 clc
 adc #8
 sta player1y
 lda #7
 sta player1height
 lda et,x
 and #3
 tay
 lda ecolor,y
 sta COLUP1
 tya
 asl
 sta tA
 lda frame
 lsr
 lsr
 lsr
 and #1
 ora tA
 tay
 ; pipistrello che riposa: ali chiuse
 lda et,x
 and #3
 bne de_2
 lda est,x
 beq de_2
 ldy #1
de_2
 lda enemy_lo,y
 sta player1pointerlo
 lda #>spr_bat0
 sta player1pointerhi
 ; guarda a sinistra se va a sinistra
 lda et,x
 lsr
 lsr
 and #7
 cmp #5
 lda #0
 bcc de_3
 lda #8
de_3
 sta REFP1
 rts
de_off
 lda #200
 sta player1y
 rts

enemy_lo
 .byte <spr_bat0,<spr_bat1,<spr_spider0,<spr_spider1,<spr_snake0,<spr_snake1,<spr_ghost0,<spr_ghost1
   ; pipistrello viola, ragno azzurro, serpente verde, fantasma bianco
ecolor
 .byte $AC,$9E,$56,$0E

   ; tavolozza del livello; luce che traballa (ogni tanto resta solo la
   ; lampada); buio con la lampada intorno al giocatore e qualche lampo
colors
 lda lflags
 lsr
 lsr
 and #3
 tax
 lda lflags
 and #3
 beq co_set
 cmp #1
 bne co_dark
 lda rng
 and #$0F
 bne co_set
 beq co_lamp
co_dark
 lda lightt
 beq co_d1
 dec lightt
 bne co_set
co_d1
 lda rng
 cmp #$80
 bne co_lamp
 lda #3
 sta lightt
co_lamp
 ; striscia della lampada centrata sulla riga del giocatore
 lda PY
 clc
 adc #4
 lsr
 lsr
 and #$FE
 asl
 asl
 sta tA
 lda #<(dark_ptr+88)
 sec
 sbc tA
 sta pfcolortable
 lda #>dark_ptr
 sta pfcolortable+1
 lda #$00
 beq co_bg0
co_set
 lda pal_lo,x
 sta pfcolortable
 lda pal_hi,x
 sta pfcolortable+1
 lda pal_row0,x
co_bg0
 sta COLUPF
 lda lbg
 ldy phase
 cpy #3
 bne co_b1
 lda #$62
co_b1
 ldy expl
 beq co_b2
 lda #$4A
co_b2
 sta COLUBK
 rts

bars2
 .byte %00000000,%10000000,%11000000,%11100000,%11110000,%11111000,%11111100,%11111110

sfx_update
 lda sfxt
 bne su_1
 sta AUDV0
 rts
su_1
 dec sfxt
 ldx sfxid
 lda sfxc,x
 sta AUDC0
 lda sfxf,x
 clc
 adc sfxt
 ldy sfxup,x
 bne su_2
 lda sfxf,x
 sec
 sbc sfxt
su_2
 sta AUDF0
 lda #8
 sta AUDV0
 rts
   ; 1 lancio, 2 esplosione, 3 oggetto, 4 porta/asse, 5 colpito, 6 salto,
   ; 7 roccia, 8 masso che si spacca, 9 caduta
sfxc
 .byte 0,8,8,4,12,6,4,2,8,4
sfxf
 .byte 0,6,8,4,10,10,8,20,12,8
sfxup
 .byte 0,0,1,0,1,1,0,1,1,1
   ; musica: muspos = nota attuale, must = frame che restano; le melodie
   ; sono elenchi (frequenza, durata) finiti da durata 0 (fine) o 255 (da capo)
music
 lda must
 beq mu_off
 dec must
 bne mu_play
 inc muspos
 inc muspos
 ldx muspos
 lda melody+1,x
 beq mu_end
 cmp #255
 bne mu_new
 lda melody,x
 sta muspos
 tax
 lda melody+1,x
mu_new
 sta must
mu_play
 ldx muspos
 lda melody,x
 beq mu_rest
 sta AUDF1
 lda #12
 sta AUDC1
 lda must
 cmp #3
 lda #6
 bcs mu_v
 lda #2
mu_v
 sta AUDV1
 rts
mu_end
 lda #0
 sta must
mu_off
mu_rest
 lda #0
 sta AUDV1
 rts
melody
 ; 0: titolo (da capo)
 .byte 15,12, 12,12, 10,12, 12,12, 0,255
 ; (10) inizio livello
 .byte 15,8, 12,8, 10,16, 0,0
 ; (18) livello finito
 .byte 10,8, 8,8, 7,24, 0,0
 ; (26) partita finita
 .byte 20,16, 23,16, 26,32, 0,0

 include levels.asm
 include pal.inc
 include title.inc
 include gfx.asm
end
