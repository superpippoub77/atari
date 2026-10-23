   ;*************************************************************************************************************************
   ; SETTAGGIO DEL KERNEL E OPZIONI
   ;_________________________________________________________________________________________________________________________
   ; pfcolors = colorazione del playfield
   ; romsize = 8k (2 banchi: il banco 1 contiene il gioco, il banco 2 il
   ;           caricamento dei livelli, le gocce e il muro spingibile)
   ; debug cycles = lampeggi lo sfondo in caso di cicli eccessivi
   ;*************************************************************************************************************************
   set kernel_options pfcolors
   set tv pal
   set romsize 8k
   ;set debug cycles

   ;*************************************************************************************************************************
   ; COSTANTI KERNEL
   ;_________________________________________________________________________________________________________________________
   ; pfscore = abilitazione dello score
   ;*************************************************************************************************************************
   const pfscore = 1

   ; limite dei bordi (suponendo un player di 8 pixel)
   const _P_Edge_Top = 8
   const _Edge_Bottom = 88
   const _P_Edge_Left = 10
   const _Edge_Right = 145

   const _M_Edge_Top = 2
   const _M_Edge_Left = 2

   const _P0_color = $2A ;Giallo (hue2 = giallo in PAL)
   const _P1_color = $48 ;Rosso (hue4 in PAL, luminosità media)
   ; un "secondo" di gioco = 48 frame (0,96 s a 50 Hz): 48 si divide per 8,
   ; 6, 4... e la musica resta a tempo (con 55 frame sgarrava ogni secondo)
   const frame_limit = 47

   ; numero di livelli: dopo l'ultimo si riparte dal primo con le bocche
   ; piu' veloci (un "giro" in piu')
   const _Levels = 6
   ; livello segreto: la Bocca Gigante (boss) dopo il livello 6, poi si
   ; riparte dal livello 1. Non si sceglie con Select.
   const _Boss = 7
   ; frame di attesa prima che una bocca uccisa ricompaia (circa 4 secondi)
   const _Mouth_Respawn = 200

   ;*************************************************************************************************************************
   ; VARIABILI
   ;_________________________________________________________________________________________________________________________
   ; _level => livello corrente del gioco
   ; _frame_counter => corrisponde a 55 frame in 1 secondo (PAL)
   ; _seconds_counter => secondi
   ;.........................................................................................................................
   ; _playfield_up => parte alta della section
   ; _playfield_down => parte bassa della section
   ; _playfield_section => sezione del playfield (le sezioni sono 8, vedi schema livelli)
   ; (queste tre servono solo durante il caricamento del livello)
   ;.........................................................................................................................
   ; _choco_count => numero di cioccolatini reuperati dal biscotto (ad ogni livello parte da 0)
   ;.........................................................................................................................
   ; _speed => velocià di attivazione del playfield dinamico e della bocca (parte da 8 e scende di 2 unità al cambio livello)
   ;.........................................................................................................................
   ; i flag (bit) si caratterizzano nel seguente modo: on = 1/off = 0
   ; _b0_enableStart => Game start
   ; _b4_enableLight => flag per apire se lo stato della luce
   ; _b5_enablePalyer1 => Attivazione della bocca
   ; _b6_enableSlowMotion => Opzione lentezza del biscotto
   ;.........................................................................................................................
   ; ATTENZIONE: le macro e le routine NON usano piu' le variabili di
   ; gioco (f, o, q, u) come appoggio: usano solo temp4-temp6.
   ; pfpixel/pfhline/pfvline usano internamente temp1-temp3.
   ;*************************************************************************************************************************

   ; level
   dim _level = b

   ; timer
   dim _frame_counter  = c
   dim _seconds_counter  = d

   ; bit oggetto
   dim _current_object_level = n
   dim _current_bit_object = r

   ; coordinate del playfiled dinamico
   dim _playfield_up = w
   dim _playfield_down = j
   dim _playfield_section = x

   ; questa variabile è usata per capire quanti "cioccolatini" sono stati colpiti
   dim _choco_count = t
   dim _choco_bits = e

   ; velocità corrente
   dim _speed = g

   ; FLAG DI CONFIGURAZIONE
   dim _b0_enableStart = k
   dim _b1_prevSelect = k
   dim _b4_enableLight = k
   dim _b5_enablePalyer1 = k
   dim _b6_enableSlowMotion = k
   dim _b7_gameMissile0Moving = k

   ;DIREZIONE PLAYER 0 E MISSILE 0
   dim _BitOp_P0_M0_Dir = p

   ;DIREZIONE PLAYER 0
   dim _Bit0_P0_Dir_Up = p
   dim _Bit1_P0_Dir_Down = p
   dim _Bit2_P0_Dir_Left = p
   dim _Bit3_P0_Dir_Right = p

   ;DIREZIONE MISSILE 0
   dim _Bit4_M0_Dir_Up = p
   dim _Bit5_M0_Dir_Down = p
   dim _Bit6_M0_Dir_Left = p
   dim _Bit7_M0_Dir_Right = p

   ; muri spingibili: vettore di 5 (var44-var47 e a; 255 = nessuno), colonna
   ; del muro (+ 128 se sta sul piano). Nel livello della Bocca Gigante non ci
   ; sono muri e var44-var47 servono agli sputi (wall_find non li guarda).
   ; I contatori qui sotto usano variabili che servono solo durante il
   ; caricamento del livello (j, r, n): vengono impostati dopo.
   dim _wall = var44
   ; bocche uccise: frame che mancano alla ricomparsa (0 = bocca viva)
   dim _mouth0wait = j
   dim _mouth1wait = r
   ; frame trascorsi dall'ultimo passo delle bocche
   dim _mouthTick = n
   ; giro (0 = primo passaggio dei livelli). Durante il titolo la stessa
   ; variabile serve alla modalita' attract (_attractDir).
   dim _lap = y

   dim _music_index = m
   ; effetti sonori (canale 0): effetto in corso, posizione, durata nota
   dim _sfxId = i
   dim _sfxPos = q
   dim _sfxDur = z
   dim _mouthIndex = s
   dim _mouth0x = f
   dim _mouth0y = h
   dim _mouth1x = l
   dim _mouth1y = o
   dim _attractTimer = s
   dim _ballx = u
   dim _attractDir = y
   dim _hitCooldown = v
   ; Bocca Gigante: secondo sputo, direzioni e strada fatta (riga 11
   ; del playfield, nascosta)
   dim _spit2x = var44
   dim _spit2y = var45
   dim _spitDir = var46
   dim _spitTime = var47
   ; stato dello slow motion nel frame precedente
   dim _b3_prevSlow = k
__inizialize
   ;*************************************************************************************************************************
   ; INIZIALIZZAZIONE
   ;_________________________________________________________________________________________________________________________
   ; CTRLPF = P dimensione della palla e F posizione del palyfield rispett
   ; NUSIZ(0/1) = dimesione missile + dimensione player (0/1)
   ; REFP0  = Reflection Player 0
   ; COLUP(0/1) = Colore del Player (0/1)
   ; COLUBK = Colore background
   ;.........................................................................................................................
   ; SCORE e LIVES
   ;_________________________________________________________________________________________________________________________
   ; pfscore1 => timer
   ; pfscore2 => lives
   ; score => punteggio puro
   ;*************************************************************************************************************************

   ; Altezze oggeti base
   missile0height = 4
   missile1height = 1
   ballheight = 16

   ; (il resto della RAM l'ha gia' azzerato l'avvio di batari Basic)
   g = 3 : h = 3

   ; Impostazione del timer iniziale e delle vite
   pfscore1 = %11111111 : pfscore2 = %10101010
   pfscorecolor = $08 : scorecolor = $10

   ;*************************************************************************************************************************
   ; PLAYFIELD: TITOLO
   ;_________________________________________________________________________________________________________________________
   ; E' visibile solo dalla riga 1 alla riga 11 Snack 'n' Roll
   ; pfcolors => varaiazioni di marrone da $22 a $2B
   ;*************************************************************************************************************************
   /* 
   ................................
   ....XXXXXXXXX....XX.......X..X..
   ...X...............X......X.X...
   ....XX....X.XX...XXX..XXX.XX....
   ......X...XX..X.X..X.X....X.X...
   XXXXXX...X...X..XXX..XXX.X..X...
   ................................
   .X.......X.....X..XX.......X.X..
   ...X.XX........X.X...XX...X.X...
   ...XX..X.......XX...X..X.X.X....
   ...X...X.......X.....XX..X.X.... */

__draw_title

   ; GAME RESET durante la partita: si aspetta che il tasto venga rilasciato
   ; (se no nel titolo farebbe ripartire subito la partita), poi il titolo
__reset_title
   gosub __wait_release
   goto __game_start
__wait_release
   drawscreen
   if switchreset then goto __wait_release
   return thisbank

__game_start
   ;flag
   ; se arriviamo qui da una partita vera, ridisegniamo tutto il titolo
   if !_b0_enableStart{0} then goto __skip_gameover_clear
   _b0_enableStart{0} = 0
   ; (posizioni degli oggetti: le rimette il livello che parte, il titolo
   ; ha il suo kernel)
   _choco_count = 0
   ; silenzio sugli effetti, la musica del titolo riparte da capo
   _sfxId = 0 : AUDV0 = 0 : _music_index = 0
   goto __draw_title
__skip_gameover_clear
   _b4_enableLight{4} = 1

   goto __done

__main_loop

   ;*************************************************************************************************************************
   ; TIMER
   ;_________________________________________________________________________________________________________________________
   ; _frame_counter = conteggio dei frame => frame_limit(54) poi riparte da 0
   ; _seconds_counter = conteggio dei secondi
   ;*************************************************************************************************************************
   _frame_counter = _frame_counter + 1
   if _frame_counter > frame_limit then _frame_counter = 0 : _seconds_counter = _seconds_counter + 1

   ;F2 (reset) inizia il gioco; durante la partita torna al titolo (con la scelta del livello)
   asm
 lda SWCHB
 lsr
 bcs .__reset_done
 lda _b0_enableStart
 lsr
 bcc .__reset_start
 jmp .__reset_title
end
__reset_start
   ; nuova partita dal livello scelto nel titolo (_choco_count), punti e giri a
   ; zero: parte quando il tasto viene rilasciato (se no, ancora premuto, in
   ; partita riporterebbe subito al titolo)
   gosub __wait_release
   asm
 lda _b0_enableStart
 ora #1
 sta _b0_enableStart
 ldx _choco_count
 inx
 stx _level
 lda #0
 sta _lap
 sta score
 sta score+1
 sta score+2
 sta _music_index
 jmp .__skip_to_change
end
__reset_done

   ;!!!!!!!!!!!!!!!!!!! START !!!!!!!!!!!!!!!!!!!
   ;*************************************************************************************************************************
   ; MUSICA DI SOTTOFONDO
   ;_________________________________________________________________________________________________________________________
   ; Canale 1. Ogni passo della tabella: 0 = la nota continua,
   ; 1 = pausa, altro = nuova nota (valore AUDF).
   ; Titolo: rock'n'roll (AUDC 4), un passo ogni
   ; 6 frame (una semicroma). In gioco: arpeggio leggero (AUDC 12, volume
   ; basso), un passo ogni 8 frame. Quando il tempo sta per finire
   ; (ultimi 2 segmenti) o durante la fuga finale (sacchetto visibile)
   ; la musica raddoppia il ritmo e alza il volume; col tempo in
   ; scadenza si sente anche un battito del cuore (tum-tum) ogni secondo.
   if _b0_enableStart{0} then goto __game_music
   _mouthTick = _mouthTick + 1
   if _mouthTick < 6 then goto __music_done
   _mouthTick = 0
   temp1 = titlemusic[_music_index]
   _music_index = (_music_index + 1) & 63
   AUDC1 = 4 : temp2 = 5
   goto __music_note
__game_music
   temp3 = 7
   if pfscore1 < 224 then temp3 = 3
   if bally < 200 then temp3 = 3
   temp4 = _frame_counter & temp3
   if temp4 then goto __music_done
   ; passi pari: nota (gamemusic[passo/2]); passi dispari: pausa
   asm
 lda _music_index
 lsr
 tax
 lda #1
 bcs gm_pause
 lda gamemusic,x
gm_pause
 sta temp1
end
   _music_index = (_music_index + 1) & 31
   AUDC1 = 12 : temp2 = 2
   if temp3 = 3 then temp2 = 4
   if pfscore1 >= 224 then goto __music_note
   ; battito del cuore: due colpi bassi a inizio secondo
   if _frame_counter = 0 then AUDC1 = 6 : temp1 = 24 : temp2 = 10
   if _frame_counter = 8 then AUDC1 = 6 : temp1 = 26 : temp2 = 7
__music_note
   if !temp1 then goto __music_done
   if temp1 = 1 then AUDV1 = 0 : goto __music_done
   AUDF1 = temp1 : AUDV1 = temp2
__music_done

   ;Se il gioco non è ancora iniziato skippa tutto
   if !_b0_enableStart{0} then goto __attract_mode
   goto __skip_attract

__attract_mode
   ; selettore di livello iniziale con lo switch Select (6 scelte),
   ; indicatore a segmenti nella riga libera del titolo
   ; (bit 1 di _b1_prevSelect: Select premuto nel frame prima)
   asm
 lda _b1_prevSelect
 and #%11111101
 tax
 lda SWCHB
 and #2
 bne sel_up
 txa
 ora #2
 cmp _b1_prevSelect
 beq sel_up2
 inc _choco_count
 ldy _choco_count
 cpy #_Levels
 bcc sel_up2
 ldy #0
 sty _choco_count
 bcs sel_up2
sel_up
 txa
sel_up2
 sta _b1_prevSelect
end
   ; combinazione segreta: leva in su + fuoco = Bocca Gigante (si accende
   ; un 7o segnalino; Reset la fa partire, Select torna al livello 1)
   asm
 lda SWCHA
 and #$10
 bne no_boss
 bit INPT4
 bmi no_boss
 lda #_Levels
 sta _choco_count
no_boss
end
   goto __skip_missile

__skip_attract

   ;*************************************************************************************************************************
   ; BOCCHE (PLAYER1 - inganno dell'occhio, più bocche con un solo sprite)
   ;_________________________________________________________________________________________________________________________
   ; Dal livello 4 le bocche sono 2. Un solo player1 fisico viene
   ; riposizionato ad ogni frame sulla bocca virtuale successiva.
   ; Le bocche fanno un passo ogni _speed frame (tabella mouthspeed, piu'
   ; veloce a ogni giro). Una bocca uccisa sparisce e ricompare nel suo
   ; angolo dopo _Mouth_Respawn frame.
   ;*************************************************************************************************************************
   temp1 = 1
   if _level > 3 && _level < _Boss then temp1 = 2

   if _hitCooldown then _hitCooldown = _hitCooldown - 1

   ; conto alla rovescia delle bocche uccise
   if !_mouth0wait then goto __mouth0_alive
   _mouth0wait = _mouth0wait - 1
   if !_mouth0wait then _mouth0x = 20 : _mouth0y = 8
__mouth0_alive
   if !_mouth1wait then goto __mouth1_alive
   _mouth1wait = _mouth1wait - 1
   if !_mouth1wait then _mouth1x = 140 : _mouth1y = 90
__mouth1_alive

   _mouthIndex = _mouthIndex + 1
   if _mouthIndex >= temp1 then _mouthIndex = 0

   ; passo delle bocche (tutte insieme) ogni _speed frame
   if _hitCooldown then goto __mouth_still
   _mouthTick = _mouthTick + 1
   ; fuga finale: con il sacchetto visibile le bocche vanno al doppio
   temp2 = _speed
   if bally < 200 then temp2 = _speed / 2
   if _mouthTick < temp2 then goto __mouth_still
   _mouthTick = 0
   temp6 = 0
   if !_mouth0wait then gosub __move_mouth
   temp6 = 1
   if temp1 = 2 && !_mouth1wait then gosub __move_mouth
   ; la Bocca Gigante e' larga 32 pixel: non esce a destra
   if _level = _Boss && _mouth0x > 120 then _mouth0x = 120
__mouth_still

   ; una bocca uccisa non si disegna (player1 fuori dallo schermo)
   if _mouthIndex then goto __show_mouth1
   player1x = _mouth0x : player1y = _mouth0y
   if _mouth0wait then player1y = 200
   goto __mouth_shown
__show_mouth1
   player1x = _mouth1x : player1y = _mouth1y
   if _mouth1wait then player1y = 200
__mouth_shown

   goto __skip_bocche

   ; temp6 = bocca da muovere (0 o 1)
__move_mouth
   temp3 = _mouth0x : temp4 = _mouth0y
   if temp6 then temp3=_mouth1x : temp4=_mouth1y

   ; insegue il biscotto passando sopra a qualsiasi oggetto (in tutti i
   ; livelli le bocche non vengono mai fermate dal playfield)
   if temp3 < player0x then temp3 = temp3 + 1
   if temp3 > player0x then temp3 = temp3 - 1
   if temp4 < player0y then temp4 = temp4 + 1
   if temp4 > player0y then temp4 = temp4 - 1

   if !temp6 then _mouth0x=temp3 : _mouth0y=temp4
   if temp6 then _mouth1x=temp3 : _mouth1y=temp4
   return thisbank
__skip_bocche

   ;*************************************************************************************************************************
   ; ZUCCHERINI (MISSILE1) - UNO ALLA VOLTA
   ;_________________________________________________________________________________________________________________________
   ; Gli 8 zuccherini del livello (matrice "sugar") compaiono uno alla
   ; volta, nell'ordine della tabella: si vede sempre e solo il primo non
   ; ancora raccolto, fermo e senza sfarfallio. Quando il biscotto lo
   ; prende compare il successivo.
   ; Le collisioni si leggono dopo drawscreen, quindi si riferiscono allo
   ; zuccherino disegnato nel frame appena mostrato (_prevSugarBit).
   ;*************************************************************************************************************************
   ; bit dello zuccherino mostrato = il primo bit a 0 di _choco_bits
   temp2 = _choco_bits ^ 255
   temp3 = _choco_bits + 1
   temp2 = temp2 & temp3
   if !temp2 then goto __no_sugar_hit
   if !collision(player0, missile1) then goto __no_sugar_hit
   _choco_bits = _choco_bits | temp2 : _choco_count=_choco_count+1 : score=score+50
   ; combo "partita perfetta": se nel livello non hai ancora perso una
   ; vita (barra delle vite ancora piena) lo zuccherino vale doppio
   if pfscore2 = %10101010 then score = score + 50
   if temp2 = 1 then goto __golden_sugar
   asm
 ldx #5
 jsr sfx_go1
end
   goto __no_sugar_hit
__golden_sugar
   ; super potere: bocche congelate e biscotto invulnerabile
   _hitCooldown = 120
   asm
 ldx #7
 jsr sfx_go1
end
__no_sugar_hit

   ; cerca il primo zuccherino non ancora raccolto (indice in temp4)
   temp4 = 0 : temp2 = 1
__find_sugar
   if !(_choco_bits & temp2) then goto __sugar_index_ok
   temp4 = temp4 + 1 : temp2 = temp2 * 2
   if temp4 < 8 then goto __find_sugar
   missile1y = 200
   goto __skip_all_sugar

__sugar_index_ok
   temp1 = (_level-1)*8
   temp3 = temp1 + temp4
   temp3 = sugar[temp3]
   ; colonna: x = col*16+22 -> colonne del playfield 1,5,9,...,29
   ; riga: 0-3 -> righe 0-3 (sopra il piano), 4-7 -> righe 6-9 (sotto)
   missile1x = (temp3&7)*16+22
   temp5 = temp3/8
   missile1y = temp5*8+4
   if temp5 > 3 then missile1y = missile1y + 16

__skip_all_sugar
   ; colore della bocca e dello zuccherino (COLUP1, lo stesso registro): lo
   ; zuccherino 0 (dorato) e' giallo, gli altri prendono il colore della
   ; bocca (temp4 = 8: nessuno zuccherino). Al buio
   ; bocca e zuccherino sono neri (dark0)
   asm
 ldx _mouthIndex
 lda mouthcolors,x
 ldy temp4
 bne skc_1
 lda #$2E
skc_1
 jsr dark0
 sta COLUP1
end

   ;*************************************************************************************************************************
   ; GOCCE (playfield dinamico, banco 2)
   ;*************************************************************************************************************************
   gosub __update_drops bank2
   gosub __play_sfx bank2

   ;*************************************************************************************************************************
   ; LUCE (PLAYFIELD)
   ;_________________________________________________________________________________________________________________________
   ; dopo 32 secondi la luce si spegne automaticamente; si riaccende
   ; colpendo con un cioccolatino il piano di lavoro centrale
   ; !!IMP Cambia il colore del playfield tranne la fascia centrale
   ;*************************************************************************************************************************
   ;>>>> SPEGNIMENTO <<<<
   ; solo nel frame in cui scocca il secondo 32, 64... (prima la luce
   ; veniva rispenta per tutto quel secondo e non si poteva riaccendere)
   if !_frame_counter && _seconds_counter && !(_seconds_counter&31) then _b4_enableLight{4} = 0

   ; colori del playfield (luce, buio, colori per livello): banco 2
   gosub __pf_colors bank2

   ;*************************************************************************************************************************
   ; CONTENITORE FINALE (BALL)
   ;_________________________________________________________________________________________________________________________
   ; il sacchetto finale individuato come ball viene visualizzato solo dopo aver trovato gli 8 cioccolatini nel playfield
   ; e la bocca è stata colpita
   ; _ballx viene letto dalla colonna 7 di "objects" al caricamento del livello
   ; (il bit 0 ricorda il pezzo di piano tolto, vedi __piano_hit)
   ;*************************************************************************************************************************
   if _choco_count = 8 && !_b5_enablePalyer1{5} then ballx = _ballx & 254 : bally = 28

   ;*************************************************************************************************************************
   ; CHECK
   ;_________________________________________________________________________________________________________________________
   ; 1) ogni 16 secondi elimina uno spazio tempo
   ; 2) se lo spazio tempo è finito elimina una vita
   ; 3) se non ci sono più vite allora il gioco è terminato
   ; 4) lampeggio in scadenza del tempo
   ; 5) dopo 8 secondi si disattiva lo slow motion
   ; 6) se le luce non è attiva non si vede la bocca
   ; 7) se attivo lo slowmotion allora il biscotto cambia colore
   ; 8) il lancio dei cioccolatini è disabilitato se sono in slow motion
   ; 9) aumenta la dimensione della bocca dopo il livello 3
   ;*************************************************************************************************************************
   ; ---- 9 ----
   NUSIZ1=$00
   if _level> 3 then NUSIZ1=$05
   ; Bocca Gigante: player1 largo 4 volte, sputo (missile1) largo 4
   if _level = _Boss then NUSIZ1=$27

   ; ---- 4 ----
   ; ultimi 2 segmenti di tempo: la barra lampeggia in rosso
   pfscorecolor = $08
   if pfscore1 < 224 && _frame_counter < 24 then pfscorecolor = $64
   ; ---- 5 ----
   if !(_seconds_counter&7) then _b6_enableSlowMotion{6} = 0
   ; ---- 6 ---- al buio bocca e zuccherino sono scuri (vedi __skip_all_sugar)
   ; ---- 7 ---- (colore del biscotto e del cioccolatino in temp5, poi dimcol)
   if _b6_enableSlowMotion{6} then temp5 = $20 else temp5 = _P0_color
   ; super potere / invulnerabilita': il biscotto lampeggia, piu' veloce
   ; nell'ultimo secondo, con tre bip di avviso prima della fine
   temp1 = 4
   if _hitCooldown < 48 then temp1 = 2
   temp2 = _frame_counter & temp1
   if _hitCooldown && temp2 then temp5 = $00
   asm
 lda temp5
 jsr dimcol
 sta COLUP0
end
   if _hitCooldown >= 48 || _sfxId then goto __no_power_warn
   temp1 = _hitCooldown & 15
   if temp1 = 8 then AUDC0 = 4 : AUDF0 = 6 : AUDV0 = 8
   if temp1 = 4 then AUDV0 = 0
__no_power_warn
   ; ---- 1 ----
   if !_frame_counter && !(_seconds_counter & 15) then goto __decrease_timer_bar
   ; ---- 2 ----
   if !pfscore1 then goto __decrease_health_bar
   ; ---- 3 ----
   if !pfscore2 then goto __game_start

   ; direzione del biscotto = direzione della levetta, anche se davanti
   ; c'e' un ostacolo. Prima veniva azzerata e reimpostata solo dal
   ; movimento riuscito, DOPO il controllo del fuoco: sparare tenendo
   ; premuta una direzione (o appoggiati a un oggetto) non funzionava.
   if !joy0up && !joy0down && !joy0left && !joy0right then goto __Skip_Joystick_Precheck

   _BitOp_P0_M0_Dir = _BitOp_P0_M0_Dir & %11110000
   if joy0up then _Bit0_P0_Dir_Up{0} = 1
   if joy0down then _Bit1_P0_Dir_Down{1} = 1
   if joy0left then _Bit2_P0_Dir_Left{2} = 1
   if joy0right then _Bit3_P0_Dir_Right{3} = 1

__Skip_Joystick_Precheck

   ; ---- 8 ----
   if !joy0fire then goto __Skip_Fire
   if _b7_gameMissile0Moving{7} || _b6_enableSlowMotion{6} then goto __Skip_Fire

   _b7_gameMissile0Moving{7} = 1
   asm
 ldx #1
 jsr sfx_go1
end

   ; Direzione iniziale del missile esattamente uguale a a quella del giocatore
   _Bit4_M0_Dir_Up{4} = _Bit0_P0_Dir_Up{0}
   _Bit5_M0_Dir_Down{5} = _Bit1_P0_Dir_Down{1}
   _Bit6_M0_Dir_Left{6} = _Bit2_P0_Dir_Left{2}
   _Bit7_M0_Dir_Right{7} = _Bit3_P0_Dir_Right{3}

   if _Bit4_M0_Dir_Up{4} then missile0x = player0x + 4 : missile0y = player0y - 5
   if _Bit5_M0_Dir_Down{5} then missile0x = player0x + 4 : missile0y = player0y - 1
   if _Bit6_M0_Dir_Left{6} then missile0x = player0x + 2 : missile0y = player0y - 3
   if _Bit7_M0_Dir_Right{7} then missile0x = player0x + 6 : missile0y = player0y - 3

__Skip_Fire

   ;*************************************************************************************************************************
   ; LANCIO DEI CIOCCOLATINI
   ;_________________________________________________________________________________________________________________________
   ; se attivo
   ;*************************************************************************************************************************

   ;se non è attivo salta la routine
   if !_b7_gameMissile0Moving{7} then goto __skip_missile

   if _Bit4_M0_Dir_Up{4} then missile0y = missile0y - 2 : temp5 = (missile0x-18)/4 : temp6 = (missile0y-1)/8
   if _Bit5_M0_Dir_Down{5} then missile0y = missile0y + 2 : temp5 = (missile0x-18)/4 : temp6 = (missile0y)/8
   if _Bit6_M0_Dir_Left{6} then missile0x = missile0x - 2 : temp5 = (missile0x-18)/4 : temp6 = (missile0y-1)/8
   if _Bit7_M0_Dir_Right{7} then missile0x = missile0x + 2 : temp5 = (missile0x-18)/4 : temp6 = (missile0y-1)/8

   ;se raggiunge il bordo o colpisce il divisor di mezzo si elimina
   if missile0y < _M_Edge_Top || missile0y > _Edge_Bottom then goto __delete_missile
   if missile0x > _Edge_Right || missile0x < _M_Edge_Left then goto __delete_missile
   ; a sinistra della colonna 0 (x<18) il calcolo della colonna "scavalca"
   ; e pfread leggerebbe pixel della riga sotto: li' non c'e' nulla da colpire
   if temp5 > 31 then goto __skip_missile
   ; colpito il piano di lavoro: si riaccende la luce e (una volta per
   ; livello) se ne toglie un pezzo per passare (banco 2)
   if temp6 = 5 && pfread(temp5,temp6) then _b4_enableLight{4}=1 : gosub __piano_hit bank2 : goto __delete_missile

   ;non colpisce nulla
   if !pfread(temp5,temp6) then goto __skip_missile

   ; il muro spingibile non si distrugge: ferma solo il cioccolatino.
   ; Vale dalla riga 6 in giu': anche la lampada appesa sopra il muro e'
   ; protetta, cosi' non si scavalca il muro sparando (livello 5)
   ; (if semplici: un || dentro un if annidato non viene compilato bene)
   ; (muri sul piano: colonna + 128, protetti nelle righe 0-4)
   temp1 = temp5
   if temp6 < 5 then temp1 = temp5 | 128 : goto __pw_check
   if temp6 < 6 then goto __not_push_wall
__pw_check
   asm
 lda temp1
 jsr wall_find
 bne pwc_no
 jmp .__delete_missile
pwc_no
end
__not_push_wall

   ; --- regola semplificata: solo la riga "in cima" di ogni gruppo è
   ; distruttibile (righe 0 e 2 sopra il piano, 6 e 8 sotto) ---
   temp4 = 0
   if temp6=0 || temp6=2 then temp4=1
   if temp6=6 || temp6=8 then temp4=1
   if !temp4 then goto __delete_missile

   ; colpisce il playfield
   pfpixel temp5 temp6 off : score = score + 1
   asm
 ldx #4
 jsr sfx_go1
end

__delete_missile

   _b7_gameMissile0Moving{7} = 0 : missile0y = 200

__skip_missile


   ;*************************************************************************************************************************
   ; ANIMAZIONE PLAYER
   ;_________________________________________________________________________________________________________________________
   ; player 0 -> Biscotto => 8 x 4 pixel
   ; player 1 -> Bocca che mangia => 8 x 4 pixel
   ;*************************************************************************************************************************
   if _frame_counter then player0:
   %00100100
   %10111101
   %01011010
   %01111110
end

   if !joy0right && !joy0left && !joy0up && !joy0down && _b0_enableStart{0} then goto __skip_animation_player0

   if !(_frame_counter & 7) then player0:
   %00011000
   %10111101
   %01011010
   %01111110
end

__skip_animation_player0

   ; la Bocca Gigante ha la sua grafica (banco 2)
   if _level = _Boss && _b0_enableStart{0} then goto __skip_animation_player1
   if !(_frame_counter & 7) then player1:
   %01111110
   %10000001
   %10011001
   %01100110
end

   if _frame_counter & 8 <> 0 then player1:
   %01111110
   %11111111
   %11111111
   %01100110
end
__skip_animation_player1
   if !_b0_enableStart{0} then goto __done

   ;*************************************************************************************************************************
   ; MOVIMENTO BISCOTTO
   ;_________________________________________________________________________________________________________________________

   if !joy0up || player0y <= _P_Edge_Top then goto __skip_up

   temp5 = (player0x-10)/4 : temp6 = (player0y-5)/8

   ; ostacolo in una delle tre colonne del biscotto (pfhit, banco 1)
   asm
 lda temp5
 jsr pfhit31
 bcs .__skip_up
 lda player0x
 sec
 sbc #17
 lsr
 lsr
 jsr pfhit31
 bcs .__skip_up
 ldx temp5
 dex
 txa
 jsr pfhit31
 bcs .__skip_up
end

   if _b6_enableSlowMotion{6} then if (_frame_counter & 3) <> 0 then goto __skip_up
   player0y = player0y - 1 : _Bit0_P0_Dir_Up{0} = 1

__skip_up

   if !joy0down || player0y >= _Edge_Bottom then goto __skip_down

   temp5 = (player0x-10)/4 : temp6 = (player0y)/8

   ; ostacolo in una delle tre colonne del biscotto (pfhit, banco 1)
   asm
 lda temp5
 jsr pfhit31
 bcs .__skip_down
 lda player0x
 sec
 sbc #17
 lsr
 lsr
 jsr pfhit31
 bcs .__skip_down
 ldx temp5
 dex
 txa
 jsr pfhit31
 bcs .__skip_down
end

   if _b6_enableSlowMotion{6} then if (_frame_counter & 3) <> 0 then goto __skip_down
   player0y = player0y + 1 : _Bit1_P0_Dir_Down{1} = 1
__skip_down

   if !joy0left || player0x <= _P_Edge_Left  then goto __skip_left

   temp5 = (player0y-1)/8 : temp6 = (player0x-18)/4
   temp3 = (player0y-4)/8

   ; MURI SPINGIBILI: il biscotto li spinge verso sinistra
   gosub __wall_hit
   if temp2 = 255 then goto __no_push_left
   temp4 = 255 : gosub __push_wall bank2
   goto __skip_left
__no_push_left

   asm
 lda temp5
 sta temp4
 lda temp6
 jsr pfhit32
 bcs .__skip_left
 lda temp3
 sta temp4
 lda temp6
 jsr pfhit32
 bcs .__skip_left
end

   if _b6_enableSlowMotion{6} then if (_frame_counter & 3) <> 0 then goto __skip_left
   player0x = player0x - 1 : _Bit2_P0_Dir_Left{2} = 1

__skip_left
   if !joy0right || player0x >= _Edge_Right then goto __skip_right

   temp5 = (player0y-1)/8 : temp6 = (player0x-9)/4
   temp3 = (player0y-4)/8

   ; MURI SPINGIBILI: il biscotto li spinge verso destra
   gosub __wall_hit
   if temp2 = 255 then goto __no_push_right
   temp4 = 1 : gosub __push_wall bank2
   goto __skip_right
__no_push_right

   ; colonne 32-33 sono fuori dallo schermo: pfread leggerebbe la riga sotto
   asm
 lda temp5
 sta temp4
 lda temp6
 jsr pfhit32
 bcs .__skip_right
 lda temp3
 sta temp4
 lda temp6
 jsr pfhit32
 bcs .__skip_right
end

   if _b6_enableSlowMotion{6} then if (_frame_counter & 3) <> 0 then goto __skip_right
   player0x = player0x + 1 :  _Bit3_P0_Dir_Right{3} = 1
__skip_right

   ; scossa / scivolata: suono quando inizia il rallentamento
   if _b6_enableSlowMotion{6} then goto __slow_on
   _b3_prevSlow{3} = 0
   goto __slow_sound_done
__slow_on
   if _b3_prevSlow{3} then goto __slow_sound_done
   _b3_prevSlow{3} = 1
   asm
 ldx #3
 jsr sfx_go1
end
__slow_sound_done

   goto __game_collision

   ; muro davanti al biscotto? temp6 = colonna davanti, temp5 = riga della
   ; parte bassa del biscotto. Muri sul pavimento (righe 8-10): si spingono
   ; con la parte bassa nelle righe 8-10; muri sul piano (righe 2-4, colonna
   ; + 128 in _wall): con la parte bassa nelle righe 2-4.
   ; Ritorna temp2 = quale muro (0-4) o 255.
__wall_hit
   asm
   lda temp6
   ldy temp5
   cpy #8
   bcs .wh_key
   cpy #2
   bcc .wh_none
   cpy #5
   bcs .wh_none
   ora #128
.wh_key
   jsr wall_find
   .byte $2C
.wh_none
   ldx #255
   stx temp2
   rts
; quale muro sta nella colonna A (+ 128 sul piano)? X = 0-4 e Z = 1, se no
; X = 255 e Z = 0 (nel livello della Bocca Gigante mai: var44-47 sono gli sputi)
wall_find
 ldx _level
 cpx #_Boss
 beq wf_none
 ldx #4
wf_loop
 cmp _wall,x
 beq wf_done
 dex
 bpl wf_loop
wf_none
 ldx #255
wf_done
 rts
; ostacolo nel playfield? pfhit31: A = colonna (solo se < 31), riga temp6;
; pfhit32: A = colonna (solo se < 32), riga temp4. C = 1 se il pixel e' acceso
; (e parte il rallentamento della scossa), C = 0 se no. pfread sta nel banco 2:
; ci si arriva come fa batari Basic (BS_jsr, A = colonna, Y = riga)
pfhit31
 ldy temp6
 cmp #31
 bcs ph_no
 bcc ph_rd
pfhit32
 ldy temp4
 cmp #32
 bcs ph_no
ph_rd
 sta temp7
 lda #>(ph_ret-1)
 pha
 lda #<(ph_ret-1)
 pha
 lda #>(pfread-1)
 pha
 lda #<(pfread-1)
 pha
 lda temp7
 pha
 txa
 pha
 ldx #2
 jmp BS_jsr
ph_ret
 bne ph_no
 lda _b6_enableSlowMotion
 ora #%01000000
 sta _b6_enableSlowMotion
 sec
 rts
ph_no
 clc
 rts
; colore A al buio: dimcol stessa tinta con luminosita' 2 (biscotto e
; cioccolatino, scuri ma visibili), dark0 nero (bocca e zuccherino)
dark0
 ldy #$00
 .byte $2C
dimcol
 ldy #$02
 tax
 beq dimcol_r
 lda _b4_enableLight
 and #%00010000
 bne dimcol_lit
 tya
 beq dimcol_r
 txa
 and #$F0
 ora #$02
 rts
dimcol_lit
 txa
dimcol_r
 rts
end

__game_collision
   ;*************************************************************************************************************************
   ; COLLISIONI
   ;_________________________________________________________________________________________________________________________
   ; Biscotto e Bocca: decremento la barra di una vita
   ; Missile e Bocca: incremento dei punti di 10 unità e e disabilito la bocca
   ; Biscotto e Arrivo : cambio di livello
   ;*************************************************************************************************************************
   if !_hitCooldown && collision(player0, player1) then goto __decrease_health_bar
   ; PRESSE (livello 6): il biscotto non entra mai da solo nel playfield,
   ; quindi se lo tocca e' una pressa che gli e' scesa addosso
   if _level <> _Levels || _hitCooldown then goto __no_press_hit
   if collision(player0, playfield) then goto __decrease_health_bar
__no_press_hit
   if collision(missile0, player1) then goto __destroy_mouth
   if collision(player0, ball) then goto __change_level
   goto __done

   ;*************************************************************************************************************************
   ; DINAMICHE PUNTEGGI DI GIOCO
   ;_________________________________________________________________________________________________________________________
   ; __destroy_mouth => distrugge la bocca disattivandolo e incremeta lo
   ; score di 10 punti
   ; ........................................................................
   ; __decrease_health_bar => decrementa di una vita se le fite sono finite
   ; finisce il gico
   ; ........................................................................
   ; __reset_mouth_pos => riporta la bocca nel suo angolo
   ; ........................................................................
   ; __decrease_timer_bar => decremeta la barra del tempo
   ; ........................................................................
   ; __change_level => cambia di livello
   ;
   ;*************************************************************************************************************************
__destroy_mouth
   ; il cioccolatino sparisce (prima continuava e poteva colpire due volte)
   _b7_gameMissile0Moving{7} = 0 : missile0y = 200
   ; la Bocca Gigante appena colpita (ferma) non si puo' colpire di nuovo
   if _level = _Boss && _hitCooldown then goto __done
   score = score + 10
   _b5_enablePalyer1{5} = 0
   asm
 ldx #6
 jsr sfx_go1
end
   if _level = _Boss then gosub __boss_hit bank2 : goto __done
   ; la collisione si riferisce alla bocca disegnata nel frame precedente:
   ; con due bocche e' l'altra rispetto a _mouthIndex
   if _level > 3 then _mouthIndex = _mouthIndex ^ 1
   gosub __kill_mouth
   goto __done

   ; vita persa. Nel livello 5 i muri tornano al loro posto e il biscotto
   ; riparte dall'inizio: se li hai spinti in modo da chiuderti la strada, alla
   ; prossima vita persa il rompicapo ricomincia (non resti mai bloccato)
__decrease_health_bar
  pfscore2=pfscore2/4
  pfscore1=%11111111
  _hitCooldown = 90
  if !pfscore2 then goto __game_start
  if _level = 5 then gosub __walls_home bank2
  goto __done

   ;*************************************************************************************************************************
   ; MURI DEL LIVELLO 5 AL LORO POSTO (vita persa)
   ;*************************************************************************************************************************
   ; Nel livello 5 i muri tornano al loro posto e il biscotto riparte
   ; dall'inizio: se li hai spinti in modo da chiuderti la strada, alla
   ; prossima vita persa il rompicapo ricomincia (non resti mai bloccato).


   ;*************************************************************************************************************************
   ; BONUS TEMPO (chiamato da __change_level)
   ;*************************************************************************************************************************
   ; bonus tempo: ogni segmento rimasto della barra vale 20 punti, contati
   ; uno alla volta con un tic
__time_bonus
   if !switchrightb then return thisbank
   if !pfscore1 then return thisbank
   pfscore1 = pfscore1 * 2 : score = score + 20
   asm
 lda #4
 sta AUDC0
 lda #8
 sta AUDF0
 sta AUDV0
end
   ; contatore: _mouthTick (drawscreen sovrascrive le variabili temp)
   _mouthTick = 6
__bonus_wait
   drawscreen
   if _mouthTick = 3 then AUDV0 = 0
   _mouthTick = _mouthTick - 1
   if _mouthTick then goto __bonus_wait
   goto __time_bonus

   ; la bocca _mouthIndex sparisce e ricomparira' dopo _Mouth_Respawn frame
__kill_mouth
   if !_mouthIndex then _mouth0wait = _Mouth_Respawn : _mouth0y = 200
   if _mouthIndex then _mouth1wait = _Mouth_Respawn : _mouth1y = 200
   return thisbank


   ; effetto sonoro X (se ha priorita' maggiore o uguale a quello in corso)
   asm
sfx_go1
 cpx _sfxId
 bcc sfx_go1_skip
 stx _sfxId
 lda #0
 sta _sfxPos
 sta _sfxDur
sfx_go1_skip
 rts
end

__decrease_timer_bar
   pfscore1 = pfscore1 * 2
   goto __done

__change_level
   ; bonus tempo (banco 2)
   gosub __time_bonus
   _sfxId = 0
   asm
 ldx #8
 jsr sfx_go1
end
   _level=_level+1
   ; dopo l'ultimo livello c'e' la Bocca Gigante, poi si riparte dal
   ; primo livello, un giro piu' veloce
   if _level > _Boss then _level = 1 : _lap = _lap + 1

__skip_to_change
   ; un cioccolatino ancora in volo non passa al livello nuovo (colpirebbe
   ; il piano appena disegnato)
   ; (anche il sacchetto via; la bocca da colpire e la luce accesa: bit 5
   ; e 4 di k, il bit 7 e' _b7_gameMissile0Moving)
   asm
 lda #200
 sta missile0y
 sta bally
 lda k
 and #$7F
 ora #$30
 sta k
end
   pfscorecolor = $08
   scorecolor=(scorecolor + $10) & $F0
   pfscore1=%11111111
   pfscore2=%10101010
   player0x=10:player0y=64
   _choco_count=0
   _choco_bits=0
   ; ogni livello parte con la luce accesa, tranne l'ultimo che parte al buio
   if _level=_Levels then _b4_enableLight{4}=0
   _seconds_counter = 0
   ; velocita' delle bocche: frame per passo dalla tabella, -2 per ogni
   ; giro gia' completato (minimo 2)
   temp1 = mouthspeed[_level]
   temp2 = _lap * 2
   temp3 = temp1 - 2
   _speed = 2
   if temp2 < temp3 then _speed = temp1 - temp2
   pfclear
   gosub __load_level bank2
   ; le variabili usate dal caricamento tornano a fare da contatori
   _mouth0x=20 : _mouth0y=8 : _mouth1x=140 : _mouth1y=90
   asm
 lda #0
 sta _mouth0wait
 sta _mouth1wait
 sta _mouthTick
end

__done
   ; nel titolo lo schermo lo disegna il kernel del logo (qui sotto)
   asm
 lda _b0_enableStart
 lsr
 bcs .__game_screen
 jmp title_kernel
end
__game_screen
   ; il sacchetto (ball) lampeggia: largo 8 pixel e quasi spento (1 pixel)
   ; a 8 frame alterni (CTRLPF: bit 0 il playfield riflesso del kernel,
   ; bit 4-5 la ball)
   asm
 lda _frame_counter
 and #8
 beq bag_1
 lda #$30
bag_1
 ora #$01
 sta CTRLPF
end
   drawscreen
   goto __main_loop

   asm
   ;*************************************************************************************************************************
   ; KERNEL DEL TITOLO: il logo "SNACK and ROLL" con il playfield
   ; asimmetrico (40 colonne, righe di 8 linee), i colori per riga e gli
   ; sprite riposizionati a meta' schermo: "AND" bianco fra due righe rosse,
   ; la O di ROLL e' il biscotto, a sinistra la bocca, a destra il
   ; cioccolatino; sotto il terreno e le 7 tacche del livello di partenza
   ; (la ball sopra quella scelta con Select) e la firma "by FM". Frame da
   ; 312 linee come
   ; quelli di drawscreen; la logica del titolo (musica, Select) gira
   ; durante il tempo del timer di fine schermo.
   ; Tabelle: tools/title_logo.py.
   ;*************************************************************************************************************************
title_kernel
tk_os
 lda INTIM
 bmi tk_os
 lda #2
 sta WSYNC
 sta VSYNC
 sta WSYNC
 sta WSYNC
 lsr
 sta WSYNC
 sta VSYNC
 sta VBLANK
 lda #TK_VBLANK
 sta TIM64T
 ; P0 "A" e mezza N e poi il biscotto, P1 il resto di "AND" (poi la bocca),
 ; M0 il cioccolatino,
 ; la ball sul terreno alla colonna 13 + 2 * livello
 ldx #0
 stx VDELBL
 lda #68
 jsr tk_pos
 inx
 lda #84
 jsr tk_pos
 inx
 lda #144
 jsr tk_pos
 lda _choco_count
 asl
 asl
 asl
 adc #52
 ldx #4
 jsr tk_pos
 sta WSYNC
 sta HMOVE
 lda #$35
 sta NUSIZ0
 lda #$05
 sta NUSIZ1
 lda #$0E
 sta COLUP0
 sta COLUP1
 lda #$20
 sta CTRLPF
 sta HMCLR
 ; animazioni di ROLL (puntatori alle tabelle, 8 byte piu' avanti il
 ; secondo disegno): la bocca mastica (ogni 8 frame; i suoi colori per
 ; riga 16 byte dopo il disegno), le due L ondeggiano al vento (cime
 ; piegate per 16 frame su 48). Il puntatore della seconda L sta in f-g
 ; (_mouth0x, _speed: nel titolo non servono, il livello li rimette)
 lda _frame_counter
 and #8
 clc
 adc #<tk_mouth
 sta temp1
 adc #16
 sta temp3
 lda _frame_counter
 and #16
 lsr
 tax
 adc #<ro4
 sta temp5
 txa
 adc #<ro5
 sta f
 lda #>tk_mouth
 sta temp2
 sta temp4
 sta temp6
 sta g
tk_vb
 lda INTIM
 bne tk_vb
 ; ---- SNACK: 7 righe da 8 linee, giallo piu' chiaro in alto ----
 ldx #55
tk_a
 sta WSYNC
 txa
 lsr
 lsr
 lsr
 tay
 lda sn0,y
 sta PF0
 lda sn1,y
 sta PF1
 tya
 ora #$28
 sta COLUPF
 lda sn2,y
 sta PF2
 lda sn3,y
 sta PF0
 lda sn4,y
 sta PF1
 lda sn5,y
 sta PF2
 dex
 bpl tk_a
 jsr tk_pfoff
 ldx #6
 jsr tk_skip
 ; ---- AND: righe di 4 linee, le due righe rosse ripetute a destra ----
 lda #$64
 sta COLUPF
 ldx #19
tk_b
 sta WSYNC
 txa
 lsr
 lsr
 tay
 lda tk_an,y
 sta GRP0
 lda tk_d,y
 sta GRP1
 lda tk_line,y
 sta PF1
 and #7
 sta PF2
 dex
 bpl tk_b
 jsr tk_pfoff
 ; la bocca a sinistra di ROLL
 ldx #1
 lda #16
 jsr tk_pos
 sta WSYNC
 sta HMOVE
 lda #$2C
 sta COLUP0
 lda #$66
 sta COLUPF
 ; il biscotto guarda a destra e a sinistra (specchiato a secondi alterni)
 lda _seconds_counter
 asl
 asl
 asl
 sta REFP0
 ; ---- ROLL: R e LL nel playfield (PF0 vuoto), sprite per riga ----
 ; (Y la riga, X le 8 linee della riga; il colore della bocca cambia a
 ; ogni riga; il cioccolatino nelle 3 righe in basso: con Y < 3 il
 ; carry e' spento e 0 - 0 - 1 = $FF accende ENAM0)
 ldy #6
tk_c0
 ldx #8
tk_c
 sta WSYNC
 lda (temp3),y
 sta COLUP1
 lda (temp1),y
 sta GRP1
 lda #1
 sta PF1
 lda ro2,y
 sta PF2
 lda tk_cookie,y
 sta GRP0
 lda (temp5),y
 sta PF1
 lda (f),y
 sta PF2
 cpy #3
 lda #0
 sbc #0
 sta ENAM0
 dex
 bne tk_c
 dey
 bpl tk_c0
 jsr tk_pfoff
 ; ---- terreno giallo, la ball sopra e' il livello scelto con Select ----
 lda #$2A
 sta COLUPF
 lda #2
 sta ENABL
 ldx #3
 jsr tk_skip
 stx ENABL
 dex
 stx PF0
 stx PF1
 stx PF2
 ldx #3
 jsr tk_skip
 jsr tk_pfoff
 ; ---- firma "by FM" sotto il terreno (P1 di nuovo accanto a P0) ----
 ldx #1
 lda #92
 jsr tk_pos
 sta WSYNC
 sta HMOVE
 lda #$2C
 sta COLUP1
 ldx #10
 jsr tk_skip
 ldx #19
tk_s
 sta WSYNC
 txa
 lsr
 lsr
 tay
 lda tk_by,y
 sta GRP0
 lda tk_fm,y
 sta GRP1
 dex
 bpl tk_s
 jsr tk_pfoff
 ; fine dello schermo: timer per la logica del titolo, registri come li
 ; vuole il kernel del gioco
 lda #TK_OVERSCAN+128
 sta TIM64T
 lda #1
 sta CTRLPF
 lsr
 sta NUSIZ0
 jmp .__main_loop

tk_pfoff
 lda #0
 sta PF0
 sta PF1
 sta PF2
 sta GRP0
 sta GRP1
 sta ENAM0
 sta REFP0
 rts

   ; X linee vuote (esce con X = 0)
tk_skip
 sta WSYNC
 dex
 bne tk_skip
 rts

   ; oggetto X (0 P0, 1 P1, 2 M0, 4 ball) alla posizione A
tk_pos
 sta WSYNC
 sec
tk_p1
 sbc #15
 bcs tk_p1
 eor #7
 asl
 asl
 asl
 asl
 sta HMP0,x
 sta RESP0,x
 rts

   ; timer (unita' di 64 cicli): il vblank copre anche le linee vuote in
   ; alto e arriva a 0 (attesa di INTIM = 0); quello di fine schermo ha il
   ; bit 7 acceso come in drawscreen (attesa finche' INTIM e' negativo):
   ; quello delle linee vuote in basso, poi la logica del titolo
TK_VBLANK = 86
TK_OVERSCAN = 67

   ; la bocca chiusa e le L piegate sono 8 byte dopo i disegni normali e le
   ; tre tabelle (ro4, ro5, tk_mouth con i colori) stanno nella stessa pagina: il kernel
   ; somma 0 o 8 al byte basso (senza riporto) e usa un solo byte alto
 if (ro4 >> 8) != ((tk_mouth+30) >> 8)
   echo "ERRORE: ro4, ro5 e tk_mouth non stanno nella stessa pagina"
   err
 endif
; ---- LOGO: generato da tools/title_logo.py, non modificare a mano ----
ro4
 .byte $FB,$C3,$C3,$C3,$C3,$C3,$C3,$00,$FB,$C3,$C3,$C3,$61,$61,$30
ro5
 .byte $07,$00,$00,$00,$00,$00,$00,$00,$07,$00,$00,$00,$01,$01,$03
tk_mouth
 .byte $7E,$FF,$24,$81,$5A,$FF,$66,$00,$00,$7E,$FF,$7E,$FF,$66,$00,$00,$4A,$4A,$0E,$4A,$0E,$4A,$4A,$00,$4A,$4A,$4A,$0E,$4A,$4A,$4A
sn0
 .byte $00,$E0,$00,$F0,$00,$E0,$00
sn1
 .byte $79,$0D,$0D,$39,$61,$61,$3D
sn2
 .byte $69,$69,$69,$ED,$6F,$6B,$C9
sn3
 .byte $30,$B0,$B0,$B0,$B0,$B0,$10
sn4
 .byte $F6,$86,$87,$87,$87,$86,$F6
sn5
 .byte $02,$03,$01,$00,$01,$03,$02
ro2
 .byte $09,$0D,$03,$07,$0D,$0D,$07
tk_cookie
 .byte $00,$3C,$7E,$EB,$EB,$7E,$3C
tk_an
 .byte $A4,$A4,$E5,$A6,$44
tk_d
 .byte $9C,$92,$92,$92,$9C
tk_line
 .byte $00,$00,$3F,$00,$00
tk_by
 .byte $E8,$A4,$EA,$8A,$80
tk_fm
 .byte $91,$91,$D5,$9B,$D1
; ---- fine del logo ----
end


   ;*************************************************************************************************************************
   ; MUSICHE E TABELLE DEL BANCO 1
   ;_________________________________________________________________________________________________________________________
   ; jingle => allegra
   ; melody => suspance
   ;*************************************************************************************************************************
   data mouthcolors
   $48, $6A
end

   ; frame tra un passo e l'altro delle bocche, per livello (il primo
   ; valore non si usa: i livelli partono da 1)
   data mouthspeed
   0, 12, 10, 9, 8, 8, 7, 10
end

   ;*************************************************************************************************************************
   ; POSIZIONI FISSE DEGLI ZUCCHERINI (compaiono uno alla volta, in questo ordine)
   ;_________________________________________________________________________________________________________________________
   ; Griglia 8 colonne x 8 righe (indici 0-63). 8 valori per livello.
   ; indice = riga*8 + colonna
   ;  colonna 0-7 -> colonne del playfield 1,5,9,13,17,21,25,29 (tutta la larghezza)
   ;  riga 0-3    -> righe 0-3 del playfield (sopra il piano di lavoro)
   ;  riga 4-7    -> righe 6-9 del playfield (sotto il piano di lavoro)
   ; Ogni sezione b0..b7 ha le sue 2 colonne x 4 righe: c'e' uno
   ; zuccherino per sezione, cosi' sono distribuiti su tutto lo schema.
   ; Ogni zuccherino e' fuori dagli oggetti indistruttibili oppure dentro
   ; la riga distruttibile di una tazza o di un muro di cioccolato (si buca
   ; a colpi di cioccolatino). Posizioni e ordine di comparsa scelti con
   ; snack_and_roll/tools/sugar_opt.py (simulazione Monte Carlo: tratti
   ; equilibrati, niente zuccherini nell'angolo delle bocche, probabilita'
   ; di essere morsi che cresce con il livello) e verificati con
   ; snack_and_roll/tests/sugar_layout.py
   ;*************************************************************************************************************************
   data sugar

   20, 61, 18, 34, 63, 49, 25, 23,
   43, 55, 33, 19, 36, 13, 17, 22,
   45, 57, 39, 27, 42, 21, 17, 15,
   54, 31, 43, 57, 53, 27, 17, 29,
   9, 15, 47, 43, 37, 41, 10, 13,
   57, 63, 51, 19, 53, 31, 25, 29,
end

   ; tema del titolo (semicrome, AUDC 4): rock'n'roll originale, giro di
   ; boogie in Do (Do Fa Sol) con le note staccate (Do5=29 Mi5=23 Fa5=21
   ; Sol5=19 La5=17 Sib5=16 Si5=15 Do6=14 Re6=12; 0 = continua, 1 = pausa)
   data titlemusic
   29, 1, 23, 1, 19, 1, 17, 1, 16, 1, 17, 1, 19, 1, 23, 1,
   29, 1, 23, 1, 19, 1, 17, 1, 16, 1, 17, 1, 19, 0, 0, 1,
   21, 1, 17, 1, 14, 1, 12, 1, 14, 1, 17, 1, 21, 0, 0, 1,
   19, 1, 15, 1, 12, 1, 15, 1, 14, 0, 0, 0, 0, 0, 1, 1
end

   ; musica di sottofondo in gioco (AUDC 12, volume basso): arpeggi di
   ; Do, La minore, Fa e Sol, una nota ogni due passi
   ; (Do4=19 Mi4=15 Sol4=12 La3=23 Fa3=29 Sol3=25 Si3=20 Re4=17)
   ; (solo le note: tra una nota e l'altra il lettore mette una pausa)
   data gamemusic
   19, 15, 12, 15, 23, 19, 15, 19,
   29, 23, 19, 23, 25, 20, 17, 20
end

   ; avvia un effetto sonoro se non ne sta suonando uno piu' importante

   ;#########################################################################################################################
   ;#########################################################################################################################
   ; BANCO 2: CARICAMENTO DEI LIVELLI, GOCCE, MURO SPINGIBILE
   ;#########################################################################################################################
   ;#########################################################################################################################
   bank 2

   ; grafica della Bocca Gigante: 8 righe con due file di denti. Sta
   ; all'inizio del banco perche' i dati della grafica non devono
   ; attraversare un confine di pagina (altrove si sprecano byte)
__boss_gfx
   player1:
   %00111100
   %01111110
   %11111111
   %10100101
   %10000001
   %10100101
   %11111111
   %01111110
end
   return

   ;*************************************************************************************************************************
   ; COLORI DEL PLAYFIELD (chiamato ad ogni frame dal banco 1)
   ;*************************************************************************************************************************
__pf_colors
   ; righe 0-4 sopra il piano, 5 piano, 6-10 sotto. Dal livello 3 i colori
   ; del cioccolato; nei livelli 1, 2 e 5 le lampade (paralume grigio,
   ; lampadina gialla) sono sempre dello stesso colore, e con la luce accesa
   ; la lampadina traballa: ogni tanto, a caso, un frame di giallo piu' scuro
   ; (bit del contatore dei frame mescolati: circa un frame su quattro).
   ; Al buio tutto diventa quasi nero, senza lampeggi
   if !_b4_enableLight{4} then goto __pfc_dark
   ; (in assembly con le tavolozze qui sotto: 0 normale, 1 lampadina piu'
   ; scura, 2 livello 5, 3 livello 5 con la lampadina scura, 4 cioccolato,
   ; 5 buio; la riga 0 va in COLUPF, le righe 1-10 il kernel le legge dal
   ; puntatore, a passi di 4 byte: 4 tavolozze intrecciate per blocco)
   asm
 lda _level
 cmp #5
 beq pc_l5
 ldx #4
 cmp #3
 bcs pc_set
 ldx #0
 .byte $2C
pc_l5
 ldx #2
 lda _frame_counter
 lsr
 lsr
 eor _frame_counter
 and #5
 bne pc_set
 inx
pc_set
 lda pc_row0,x
 sta COLUPF
 lda pc_lo,x
 sta pfcolortable
 lda pc_hi,x
 sta pfcolortable+1
end
   return otherbank
__pfc_dark
   asm
 ldx #5
 bne pc_set
pc_row0
 .byte $05,$05,$05,$05,$28,$02
pc_lo
 .byte <(pc_tab0-84+0),<(pc_tab0-84+1),<(pc_tab0-84+2),<(pc_tab0-84+3),<(pc_tab1-84+0),<(pc_tab1-84+1)
pc_hi
 .byte >(pc_tab0-84),>(pc_tab0-84),>(pc_tab0-84),>(pc_tab0-84),>(pc_tab1-84),>(pc_tab1-84)
   ; tavolozze intrecciate (il puntatore pc_tab-84+k non deve cambiare
   ; pagina leggendo fino a +124: il blocco comincia fra 88 e 206)
 if (<*) < 88
 ds 88-(<*)
 endif
 if (<*) > 206
 ds 256-(<*)+88
 endif
pc_tab0
 .byte $2E,$28,$2E,$28
 .byte $0E,$0E,$24,$24
 .byte $24,$24,$24,$24
 .byte $26,$26,$24,$24
 .byte $02,$02,$02,$02
 .byte $05,$05,$05,$05
 .byte $2E,$28,$2E,$28
 .byte $0E,$0E,$24,$24
 .byte $24,$24,$24,$24
 .byte $26,$26,$24,$24
 if (<*) < 88
 ds 88-(<*)
 endif
 if (<*) > 206
 ds 256-(<*)+88
 endif
pc_tab1
 .byte $26,$02,$00,$00
 .byte $24,$02,$00,$00
 .byte $26,$02,$00,$00
 .byte $24,$02,$00,$00
 .byte $02,$02,$00,$00
 .byte $28,$02,$00,$00
 .byte $26,$02,$00,$00
 .byte $24,$02,$00,$00
 .byte $26,$02,$00,$00
 .byte $24,$02,$00,$00
   ; (il kernel legge anche il byte dopo, nell'ultima linea: $FF come prima)
 .byte $FF,$FF
end
   return otherbank

   ;*************************************************************************************************************************
   ; PLAYFIELD DEL LIVELLO (eseguito una volta all'inizio del livello)
   ;_________________________________________________________________________________________________________________________
   ; _playfield_section = prima colonna della sezione (3, 10, 17, 24)
   ; _playfield_up      = riga alta della sezione (0 sopra, 6 sotto)
   ; _playfield_down    = riga di riferimento degli oggetti (2 sopra, 8 sotto)
   ;.........................................................................................................................
   ; APPOGGI: nessun oggetto resta sospeso nel vuoto.
   ;  - tazze, muri di cioccolato e tavoli della parte ALTA poggiano sul
   ;    piano di lavoro (riga 5): sotto di loro il piano viene sempre
   ;    disegnato, anche se il segmento non e' nella colonna PIANO;
   ;  - lampade, gocce e cioccolato della parte BASSA sono appesi al
   ;    piano di lavoro: sopra di loro il piano viene sempre disegnato;
   ;  - gli oggetti della parte bassa poggiano sul pavimento (riga 10),
   ;    le lampade e le gocce della parte alta sono appese al soffitto.
   ;*************************************************************************************************************************
   ; --- sottoprogrammi del caricamento livelli (in assembly) ---
   ; objbit: Y = colonna di "objects" -> A = bit della sezione corrente
   ; (0 = oggetto assente); piano_sub: A = larghezza, disegna il piano di
   ; lavoro (riga 5) dalla colonna della sezione per A+1 colonne
   asm
objbit
 tya
 clc
 adc _current_object_level
 tax
 lda objects,x
 and _current_bit_object
 rts
piano_sub
 clc
 adc _playfield_section
 sta temp3
 lda _playfield_section
 ldy #5
 ldx #0
 jmp pfhline
end

__load_level
   missile1height = 1
   ; LEVETTE DI DIFFICOLTA' (lette a ogni inizio livello, A = piu' difficile)
   ; sinistra A: bocche piu' veloci (2 frame in meno per passo; _speed
   ; vale almeno 2, quindi al massimo 0 = un passo a ogni frame)
   ; destra A: il livello parte con 6 tacche di tempo invece di 8
   ; (e niente bonus tempo, vedi __time_bonus)
   if !switchleftb then _speed = _speed - 2
   if !switchrightb then pfscore1 = %11111100
   _current_object_level = _level - 1
   _current_object_level = _current_object_level * 8
   temp2 = _current_object_level + 7 : _ballx = objects[temp2]

   ; PIANO di lavoro (colonna 6): 7 segmenti
   temp2 = _current_object_level + 6 : temp4 = objects[temp2]
   callmacro divisor

   _current_bit_object = 1
   _playfield_section = 3
   _playfield_up = 0 ; parte alta
   _playfield_down = 2 ; parte bassa

__loop_objects
   ; TAZZE
   asm
 ldy #0
 jsr objbit
 beq .__skip_tazze
end
   callmacro cup _playfield_section _playfield_down
   if _playfield_up then goto __skip_tazze
   asm
 lda #4
 jsr piano_sub
end
__skip_tazze

   ; MURI DI CIOCCOLATO
   asm
 ldy #2
 jsr objbit
 beq .__skip_muri
end
   callmacro chocolate _playfield_section _playfield_down
   temp5 = _playfield_section + 4
   if _playfield_up then pfpixel temp5 5 on : goto __skip_muri
   asm
 lda #4
 jsr piano_sub
end
__skip_muri

   ; GOCCE: qui si disegna solo il punto di appoggio delle gocce basse
   ; (la goccia che scende la anima __update_drops ad ogni frame)
   asm
 ldy #3
 jsr objbit
 beq .__skip_gocce
end
   if _playfield_up then pfpixel _playfield_section 5 on
__skip_gocce

   ; LAMPADE
   asm
 ldy #4
 jsr objbit
 beq .__skip_lampade
end
   callmacro lamp _playfield_section _playfield_up
   if !_playfield_up then goto __skip_lampade
   asm
 lda #2
 jsr piano_sub
end
__skip_lampade

   ; TAVOLO + SEDIA
   asm
 ldy #5
 jsr objbit
 beq .__skip_tavoli
end
   callmacro table _playfield_section _playfield_down
   if _playfield_up then goto __skip_tavoli
   asm
 lda #4
 jsr piano_sub
end
__skip_tavoli

   _current_bit_object = _current_bit_object * 2
   _playfield_section = _playfield_section + 7

   if !_playfield_up && _current_bit_object = 16 then _playfield_section = 3 : _playfield_up = 6 : _playfield_down = 8
   if _current_bit_object then goto __loop_objects

   ; --- BOCCA GIGANTE: niente zuccherini, lo sputo
   ; e' alto 4 righe, barra dell'energia (8 pixel) sul pavimento ---
   if _level <> _Boss then goto __no_boss_setup
   _choco_bits = 255 : missile1height = 4
   ; (var44-var47 servono anche al vettore dei muri: dopo un livello valgono
   ; 255, qui si riazzerano come all'accensione)
   asm
 lda #200
 sta _mouth1y
 sta _spit2y
 lda #0
 sta _spit2x
 sta _spitDir
 sta _spitTime
end
   pfhline 12 10 19 on
__no_boss_setup

   ; --- MURI SPINGIBILI (colonna 1 di objects) ---
   ; un muro per bit acceso, nella colonna sezione+1 (4, 11, 18, 25).
   ; Bit 4-7: sezioni basse, muro sul pavimento (righe 8-10). Al massimo
   ; 5 muri in tutto. Una lampada
   ; bassa nella stessa sezione pende proprio sopra il muro (colonna
   ; sezione+1, righe 6-7): insieme chiudono la colonna dal piano al
   ; pavimento e per passare bisogna spingere il muro.
   ; Bit 0-3: muri sul piano nelle sezioni alte b0-b3 (righe 2-4, sotto
   ; una lampada appesa al soffitto), memorizzati come colonna + 128.
   if _level = _Boss then return otherbank
   gosub __place_walls
   return otherbank
   ; vita persa nel livello 5 (dal banco 1): biscotto alla partenza e muri
   ; al loro posto
__walls_home
   ; nel livello 5 le righe 2-4 e 8-10 contengono solo i muri: si svuotano
   ; tutte e i muri si ridisegnano al loro posto (__place_walls)
   asm
 lda #64
 sta player0y
 lda #10
 sta player0x
 tay
wh_row
 sty temp6
 lda #31
 sta temp3
 lda #0
 ldx #1
 jsr pfhline
 ldy temp6
 dey
 cpy #7
 bne wh_n
 ldy #4
wh_n
 cpy #1
 bne wh_row
end
__place_walls
   asm
 lda #255
 ldx #4
wl_clear
 sta _wall,x
 dex
 bpl wl_clear
end
   ; (colonna 1 di objects del livello: _current_object_level vale solo durante
   ; il caricamento, n serve anche alle bocche)
   temp2 = _level * 8
   temp2 = temp2 - 7
   temp4 = objects[temp2]
   temp5 = 4 : temp6 = 2
__wall_loop
   if !temp4 then return
   if !(temp4 & 1) then goto __wall_next
   temp1 = temp6 + 2
   pfvline temp5 temp6 temp1 on
   temp1 = temp5
   if temp6 = 2 then temp1 = temp5 | 128
   ; nel primo posto libero del vettore
   asm
 ldx #255
wl_find
 inx
 lda _wall,x
 cmp #255
 bne wl_find
 lda temp1
 sta _wall,x
end
__wall_next
   temp4 = temp4 / 2
   temp5 = temp5 + 7
   if temp5 = 32 then temp5 = 4 : temp6 = 8
   goto __wall_loop

   ;*************************************************************************************************************************
   ; GOCCE (colonna 3 di "objects") - chiamata ad ogni frame
   ;_________________________________________________________________________________________________________________________
   ; Ogni 16 frame la goccia di ogni sezione scende di una riga: si cancella
   ; la sua colonna (5 righe) e si accende il nuovo punto, senza sfarfallio.
   ; Sopra: righe 0-4 (dal soffitto al piano). Sotto: righe 6-10 (dal piano
   ; al pavimento).
   ;*************************************************************************************************************************
__update_drops
   if _level = _Boss then goto __boss
   ; Una goccia (o pressa) per frame, a turno: quella con
   ; (colonna xor riga) & 7 = frame & 7 (le 8 hanno valori diversi).
   ; Ognuna si ridisegna ogni 8 frame, due volte per passo (16 frame).
   ; Di piu' insieme sforerebbero il tempo del frame (lo schermo balla).
   temp2 = _level - 1
   temp2 = temp2 * 8
   temp2 = temp2 + 3
   temp4 = objects[temp2]
   temp5 = 3 : temp6 = 0
__drop_loop
   if !temp4 then return otherbank
   if !(temp4 & 1) then goto __drop_next
   asm
 lda temp6
 eor temp5
 eor _frame_counter
 and #7
 beq drop_turn
 jmp .__drop_next
drop_turn
end
   if _level = _Levels then goto __press
   temp1 = temp6 + 4
   pfvline temp5 temp6 temp1 off
   ; riga della goccia (tabella dropy): un passo ogni 16 frame, sfasata
   ; per colonna; arriva fino al piano o al pavimento
   asm
 lda temp5
 and #3
 sta temp2
 lda #1
 jsr tick16
 clc
 adc temp2
 tax
 lda dropy,x
 sta temp1
end
   temp1 = temp1 + temp6
   pfpixel temp5 temp1 on
   goto __drop_next
   ; A = (secondi & A) * 3 + frame / 16: conta i passi da 16 frame
   ; (3 per secondo di gioco da 48 frame). Usa temp1.
   asm
tick16
 and _seconds_counter
 sta temp1
 asl
 adc temp1
 sta temp1
 lda _frame_counter
 lsr
 lsr
 lsr
 lsr
 clc
 adc temp1
 rts

   ; PRESSA DOPPIA (colonna 17, sopra il piano): un perno scende dal
   ; soffitto e uno sale dal piano, con le teste larghe 3 colonne; le
   ; teste stanno alla riga temp1 (0-2, la lunghezza delle altre presse
   ; dimezzata) e 4 - temp1: chiusa, si uniscono alla riga 2. Si
   ; ridisegnano le 5 righe (colonne 16-18 = bit 7-5 del byte 2 di ogni
   ; riga del playfield): per riga d = distanza dal bordo (0 1 2 1 0),
   ; perno se d < temp1, testa se d = temp1
press_double
 ldx #18
pd_loop
 txa
 lsr
 lsr
 tay
 lda pdist,y
 ldy #0
 cmp temp1
 beq pd_head
 bcs pd_set
 ldy #$40
 .byte $2C
pd_head
 ldy #$E0
 cpx #18
 bne pd_set
 ldy #$40
pd_set
 sty temp2
 lda playfield,x
 and #$1F
 ora temp2
 sta playfield,x
 txa
 sec
 sbc #4
 tax
 bcs pd_loop
 jmp .__drop_next
pdist
 .byte 0,1,2,1,0
end
   ; PRESSA (livello 6, al posto delle gocce): uno stantuffo a T, perno
   ; sottile (1 colonna) con la testa larga (3 colonne) in fondo, lungo
   ; fino a 5 righe (righe 0-4 dal soffitto, 6-10 dal piano). Ciclo di 6
   ; passi da 16 frame (due "secondi" di gioco), sfasato per colonna:
   ; presslen = riga della testa (dall'alto), pressold = quella del passo
   ; prima. Si ridisegna solo cio' che cambia (8 presse ridisegnate per
   ; intero sforerebbero il tempo del frame):
   ;   1) via la testa vecchia, 2) perno allungato o accorciato,
   ;   3) testa nuova.
   ; Una per frame, a turno (vedi __update_drops).
   ; In assembly per stare nel banco: le due righe (vecchia e nuova)
   ; restano sullo stack. pfhline/pfvline: A = colonna, Y = riga,
   ; temp3 = estremo finale, X = 0 accende / 1 spegne; usano temp1-temp3.
__press
   asm
 lda #1
 jsr tick16
 sta temp1
 lda temp5
 and #3
 clc
 adc temp1
 tax
 ; la pressa alta della colonna 17 e' doppia (vedi press_double)
 lda temp6
 bne pr_norm
 lda temp5
 cmp #17
 bne pr_norm
 lda presslen,x
 lsr
 sta temp1
 jmp press_double
pr_norm
 lda pressold,x
 clc
 adc temp6
 pha
 lda presslen,x
 clc
 adc temp6
 pha
 tsx
 cmp $0102,x
 beq press_done
 lda $0102,x
 tay
 ldx temp5
 inx
 stx temp3
 ldx #1
 lda temp5
 sec
 sbc #1
 jsr pfhline
 tsx
 lda $0101,x
 cmp $0102,x
 bcc press_up
 sta temp3
 ldy temp6
 ldx #0
 lda temp5
 jsr pfvline
 jmp press_head
press_up
 lda $0102,x
 sta temp3
 ldy $0101,x
 iny
 ldx #1
 lda temp5
 jsr pfvline
press_head
 tsx
 ldy $0101,x
 ldx temp5
 inx
 stx temp3
 ldx #0
 lda temp5
 sec
 sbc #1
 jsr pfhline
press_done
 pla
 pla
press_skip
end
__drop_next
   temp4 = temp4 / 2
   temp5 = temp5 + 7
   if temp5 = 31 then temp5 = 3 : temp6 = 6
   goto __drop_loop

   ;*************************************************************************************************************************
   ; BOCCA GIGANTE (livello segreto, boss) - chiamata ad ogni frame
   ;_________________________________________________________________________________________________________________________
   ; La bocca 0, larga 4 volte, insegue il biscotto e gli sputa contro
   ; (missile1, posizione in _mouth1x/_mouth1y, 200 = nessuno sputo: la
   ; seconda bocca nel livello del boss non c'e'). Ogni colpo di
   ; cioccolatino (_choco_count = colpi subiti) spegne un pixel della
   ; barra dell'energia, la respinge nell'angolo opposto e la rende piu'
   ; veloce e piu' cattiva. All'ottavo colpo e' sconfitta: +500 punti e
   ; compare il sacchetto.
   ;*************************************************************************************************************************
__boss
   if _choco_count < 8 then goto __boss_alive
   _mouth0wait = 250 : _mouth0y = 200 : missile1y = 200
   return otherbank
__boss_alive
   gosub __boss_gfx
   ; appena colpita (ferma per _hitCooldown) o quasi sconfitta: lampeggia
   asm
 lda _frame_counter
 and #4
 beq boss_noflash
 lda _hitCooldown
 bne boss_flash
 lda _choco_count
 cmp #5
 bcc boss_noflash
boss_flash
 lda #$0E
 sta COLUP1
boss_noflash
end
   ; frame per passo: 10 all'inizio, 3 al settimo colpo
   _speed = 10 - _choco_count
   ; --- sputo 1 (_mouth1x/_mouth1y, direzione nei bit 0-2 di _spitDir) ---
   ; uno sputo al secondo, tre al secondo dopo il quarto colpo. Parte dal
   ; centro della bocca, mirato al biscotto (8 direzioni, tabella spitaim:
   ; sinistra/centro/destra + 3 * sopra/stessa altezza/sotto)
   asm
 lda _mouth1y
 cmp #200
 bcs spit_new
 jmp spit_move
spit_new
 lda _choco_count
 cmp #4
 lda _frame_counter
 bcc spit_rate
 and #15
spit_rate
 beq spit_fire
 jmp spit2
spit_fire
 lda _mouth0x
 clc
 adc #14
 sta _mouth1x
 lda _mouth0y
 sec
 sbc #2
 sta _mouth1y
 lda #0
 sta _spitTime
 ldx #1
 lda _mouth0x
 clc
 adc #20
 cmp player0x
 bcs spit_h1
 ldx #2
spit_h1
 lda _mouth0x
 clc
 adc #4
 sta temp4
 lda player0x
 cmp temp4
 bcs spit_h2
 ldx #0
spit_h2
 lda _mouth0y
 clc
 adc #4
 cmp player0y
 bcs spit_v1
 inx
 inx
 inx
 inx
 inx
 inx
 bne spit_v3
spit_v1
 lda player0y
 clc
 adc #8
 cmp _mouth0y
 bcc spit_v3
 inx
 inx
 inx
spit_v3
 lda _spitDir
 and #$F0
 ora spitdx+16,x
 sta _spitDir
end
   asm
 ldx #1
 jsr sfx_go2
end
   ; avanza; dopo il quarto colpo, a meta' strada si divide in due sputi
   ; che si allargano (direzioni accanto a quella di partenza)
   asm
spit_move
 lda _spitDir
 and #7
 tax
 lda _mouth1x
 clc
 adc spitdx,x
 sta _mouth1x
 cmp #151
 bcs spit_kill1
 lda _mouth1y
 clc
 adc spitdx+8,x
 sta _mouth1y
 cmp #93
 bcs spit_kill1
 inc _spitTime
 lda _choco_count
 cmp #4
 bcc spit2
 lda _spitTime
 cmp #14
 bne spit2
 lda _spit2y
 cmp #200
 bcc spit2
 lda _mouth1x
 sta _spit2x
 lda _mouth1y
 sta _spit2y
 inx
 txa
 and #7
 asl
 asl
 asl
 asl
 sta temp3
 dex
 dex
 txa
 and #7
 ora temp3
 sta _spitDir
 jmp spit2
spit_kill1
 lda #200
 sta _mouth1y
spit2
 lda _spit2y
 cmp #200
 bcs spit_hit
 lda _spitDir
 lsr
 lsr
 lsr
 lsr
 tax
 lda _spit2x
 clc
 adc spitdx,x
 sta _spit2x
 cmp #151
 bcs spit_kill2
 lda _spit2y
 clc
 adc spitdx+8,x
 sta _spit2y
 cmp #93
 bcc spit_hit
spit_kill2
 lda #200
 sta _spit2y
spit_hit
 ; lo sputo che tocca il biscotto toglie una vita (via tutti e due)
 bit CXM1P
 bpl .__spit_show
 lda #200
 sta _mouth1y
 sta _spit2y
 lda _hitCooldown
 bne .__spit_show
end
   pfscore2 = pfscore2 / 4 : pfscore1 = 255 : _hitCooldown = 90
__spit_show
   ; un solo missile1: con due sputi si disegnano a frame alterni
   asm
 lda _mouth1x
 sta missile1x
 lda _mouth1y
 sta missile1y
 lda _spit2y
 cmp #200
 bcs spit_done
 lda _mouth1y
 cmp #200
 bcs spit_show2
 lda _frame_counter
 lsr
 bcs spit_done
spit_show2
 lda _spit2x
 sta missile1x
 lda _spit2y
 sta missile1y
spit_done
end
   return otherbank

   ; direzioni: 0 su, 1 su-destra, 2 destra, 3 giu'-destra, 4 giu',
   ; 5 giu'-sinistra, 6 sinistra, 7 su-sinistra
   ; spitdx: passo in x; spitdx+8: passo in y; spitdx+16: direzione
   ; verso il biscotto, (sinistra/centro/destra) + 3 * (sopra/stessa
   ; altezza/sotto)
   data spitdx
   0, 2, 2, 2, 0, 254, 254, 254
   254, 254, 0, 2, 2, 2, 0, 254
   7, 0, 1, 6, 4, 2, 5, 4, 3
end

   ; colpo di cioccolatino alla Bocca Gigante: resta ferma dov'e' per un
   ; attimo (_hitCooldown), e intanto non si puo' colpire di nuovo

   ; effetto sonoro X (se ha priorita' maggiore o uguale a quello in corso)
   asm
sfx_go2
 cpx _sfxId
 bcc sfx_go2_skip
 stx _sfxId
 lda #0
 sta _sfxPos
 sta _sfxDur
sfx_go2_skip
 rts
end



__boss_hit
   _choco_count = _choco_count + 1 : score = score + 40
   temp5 = 20 - _choco_count
   pfpixel temp5 10 off
   _hitCooldown = 30
   if _choco_count < 8 then return otherbank
   score = score + 500
   asm
 ldx #7
 jsr sfx_go2
end
   return otherbank

   ;*************************************************************************************************************************
   ; TRUCCO: PEZZO DI PIANO DI LAVORO (chiamato quando un cioccolatino lo colpisce)
   ;*************************************************************************************************************************
   ; Una volta per livello il colpo toglie un pezzo di piano largo 4 colonne
   ; (dalla colonna colpita - 1 alla + 2): si apre un passaggio tra sopra e
   ; sotto. Il bit 0 di _ballx (sempre pari, riletto a ogni livello) ricorda
   ; che il pezzo e' gia' stato tolto. temp5 = colonna colpita.
__piano_hit
   if _ballx & 1 then return
   _ballx = _ballx | 1
   temp1 = temp5 - 1 : temp2 = temp5 + 2
   if !temp5 then temp1 = 0
   if temp2 > 31 then temp2 = 31
   pfhline temp1 5 temp2 off
   asm
 ldx #4
 jsr sfx_go2
end
   return otherbank


   ;*************************************************************************************************************************
   ; MURI SPINGIBILI
   ;_________________________________________________________________________________________________________________________
   ; temp2 = quale muro (0-4)   temp4 = direzione (1 = destra, 255 = sinistra)
   ; Il muro (righe 8-10) si sposta di una colonna ogni 8 frame mentre il
   ; biscotto lo spinge, se la colonna successiva e' libera e dentro lo
   ; schermo. Spingere non attiva lo slow motion.
   ; Se nella nuova colonna c'e' una bocca, il muro la schiaccia: +10,
   ; conta come bocca colpita e la bocca ricompare dopo un po'.
   ; (pfvline/pfread usano temp1-temp3: l'indice del muro va in temp6,
   ; la vecchia colonna in temp4)
   ;*************************************************************************************************************************
__push_wall
   if _frame_counter & 7 then return otherbank
   temp6 = temp2
   temp1 = _wall[temp6]
   ; temp4 = valore vecchio, temp5 = nuovo (col + direzione; il bit 7 dei
   ; muri sul piano resta), temp6 = quale muro
   temp5 = temp1 + temp4
   temp4 = temp1
   ; In assembly: le 3 righe del muro (8-10, o 2-4 col bit 7) devono essere
   ; libere nella colonna nuova; la riga corrente sta sullo stack.
   ; pfread: A = colonna, Y = riga, risultato 0 = pixel acceso.
   asm
 lda temp5
 and #127
 cmp #32
 bcs pw_out
 ; muri sul piano (bit 7): solo nella corsia della loro sezione, colonne
 ; s..s+4 (s = 3, 10, 17, 24): due muri alti non si toccano mai
 bit temp5
 bpl pw_lane
 sec
 sbc #3
 bcc pw_out
pw_mod
 cmp #7
 bcc pw_m
 sbc #7
 bcs pw_mod
pw_m
 cmp #5
 bcs pw_out
pw_lane
 lda #8
 bit temp5
 bpl pw_base
 lda #2
pw_base
 pha
 jsr pw_read
 beq pw_busy
 jsr pw_read
 beq pw_busy
 jsr pw_read
 beq pw_busy
 tsx
 dec $0101,x
 lda $0101,x
 sta temp3
 sec
 sbc #2
 tay
 lda temp4
 and #127
 ldx #1
 jsr pfvline
 tsx
 lda $0101,x
 sta temp3
 sec
 sbc #2
 tay
 lda temp5
 and #127
 ldx #0
 jsr pfvline
 pla
 jmp .__pw_moved
pw_read
 tsx
 ldy $0103,x
 inc $0103,x
 lda temp5
 and #127
 jmp pfread
pw_busy
 pla
pw_out
end
   return otherbank
__pw_moved
   _wall[temp6] = temp5
   asm
 ldx #2
 jsr sfx_go2
end
   ; i muri sul piano non schiacciano le bocche
   if temp5 >= 128 then return otherbank

   ; --- bocche schiacciate dal muro ---
   ; il muro occupa i pixel x da temp4 a temp4+3, righe 8-10 (y >= 65)
   temp4 = temp5 * 4
   temp4 = temp4 + 17
   ; larghezza della bocca: 8 pixel, 16 dal livello 4 (NUSIZ1 doppio)
   temp3 = 7
   if _level > 3 then temp3 = 15
   ; bit 7 di temp5 / temp6 = bocca 0 / 1 schiacciata (la bocca 1 c'e'
   ; dal livello 4)
   asm
 ldx _mouth0x
 ldy _mouth0y
 lda _mouth0wait
 jsr pw_hit
 ror temp5
 lda _level
 cmp #4
 bcc pw_m1
 ldx _mouth1x
 ldy _mouth1y
 lda _mouth1wait
 jsr pw_hit
pw_m1
 ror temp6
end
   if temp5{7} then _mouth0wait = _Mouth_Respawn : _mouth0y = 200 : gosub __crushed
   if temp6{7} then _mouth1wait = _Mouth_Respawn : _mouth1y = 200 : gosub __crushed
   return otherbank
__crushed
   score = score + 10 : _b5_enablePalyer1{5} = 0
   asm
 ldx #6
 jsr sfx_go2
end
   return thisbank
   ; bocca in X (x), Y (y), A (attesa, gia' nei flag): carry = schiacciata
   asm
pw_hit
 bne pw_no
 cpy #65
 bcc pw_no
 stx temp1
 clc
 lda temp4
 adc #3
 cmp temp1
 bcc pw_no
 clc
 txa
 adc temp3
 cmp temp4
 rts
pw_no
 clc
 rts
end

   ;*************************************************************************************************************************
   ; EFFETTI SONORI (canale 0) - presi dal bbsoundtest di batari Basic
   ;_________________________________________________________________________________________________________________________
   ; _sfxId = effetto in corso (0 = nessuno), _sfxPos = posizione nella
   ; tabella, _sfxDur = frame che mancano alla nota successiva.
   ; Ogni nota: (volume*16 + AUDC), AUDF, durata. 255 = fine effetto.
   ; Generato da snack_and_roll/tests/sfx_from_soundtest.py
   ;  1 = pewpew       sparo
   ;  2 = dragit       muro spinto
   ;  3 = electrobump  scossa / scivolata (inizio rallentamento)
   ;  4 = poof1        blocco abbattuto
   ;  5 = gotthecoin   zuccherino preso
   ;  6 = explosion    bocca uccisa
   ;  7 = powerup      super potere (zuccherino dorato)
   ;  8 = oneup        cambio livello
   ;*************************************************************************************************************************
   ; lettore in assembly: una tabella con l'indirizzo di ogni effetto
   ; (sfx_lo/sfx_hi, dopo i dati); temp1-temp2 = puntatore all'effetto
__play_sfx
   asm
 lda _sfxId
 beq sfx_done
 lda _sfxDur
 beq sfx_next
 dec _sfxDur
 jmp sfx_done
sfx_next
 ldx _sfxId
 lda sfx_lo-1,x
 sta temp1
 lda sfx_hi-1,x
 sta temp2
 ldy _sfxPos
 lda (temp1),y
 cmp #255
 bne sfx_play
 lda #0
 sta _sfxId
 sta AUDV0
 beq sfx_done
sfx_play
 sta AUDC0
 lsr
 lsr
 lsr
 lsr
 sta AUDV0
 iny
 lda (temp1),y
 sta AUDF0
 iny
 lda (temp1),y
 sta _sfxDur
 dec _sfxDur
 iny
 sty _sfxPos
sfx_done
end
   return otherbank

   ; pewpew (10 note) - sparo
   data sfx_shot
   244, 28, 2, 180, 9, 2, 236, 4, 2, 244, 25, 2, 84, 7, 2, 100, 13, 2
   100, 24, 2, 52, 30, 2, 52, 9, 2, 44, 4, 2, 255
end

   ; dragit (3 note) - muro spinto
   data sfx_push
   39, 28, 2, 152, 30, 6, 55, 14, 2, 255
end

   ; electrobump (8 note) - scossa / scivolata (inizio rallentamento)
   data sfx_slow
   168, 8, 2, 172, 8, 2, 166, 8, 2, 174, 8, 2, 134, 8, 4, 110, 8, 2
   70, 8, 2, 38, 8, 2, 255
end

   ; poof1 (5 note) - blocco abbattuto
   data sfx_block
   72, 7, 2, 136, 7, 2, 168, 12, 4, 136, 13, 2, 72, 9, 2, 255
end

   ; gotthecoin (9 note) - zuccherino preso
   data sfx_sugar
   252, 4, 2, 228, 10, 2, 244, 10, 2, 148, 10, 2, 132, 10, 2, 100, 10, 2
   52, 10, 2, 148, 10, 2, 20, 10, 7, 255
end

   ; explosion (11 note) - bocca uccisa
   data sfx_mouth
   40, 1, 4, 246, 9, 4, 70, 9, 4, 54, 10, 4, 110, 4, 4, 102, 8, 4
   86, 6, 4, 54, 15, 8, 102, 12, 4, 70, 10, 4, 54, 14, 2, 255
end

   ; powerup (13 note) - super potere (zuccherino dorato)
   data sfx_power
   246, 30, 4, 252, 12, 4, 116, 18, 4, 132, 18, 4, 204, 11, 4, 156, 7, 4
   172, 7, 4, 76, 3, 8, 212, 30, 4, 132, 21, 4, 124, 6, 4, 68, 10, 4
   52, 10, 1, 255
end

   ; oneup (12 note) - cambio livello
   data sfx_level
   244, 22, 4, 36, 19, 4, 244, 18, 4, 20, 16, 4, 6, 30, 4, 132, 13, 4
   6, 30, 4, 68, 12, 4, 6, 30, 4, 36, 9, 4, 68, 9, 8, 36, 1, 2
   255
end

   asm
sfx_lo
 .byte <sfx_shot, <sfx_push, <sfx_slow, <sfx_block, <sfx_sugar, <sfx_mouth, <sfx_power, <sfx_level
sfx_hi
 .byte >sfx_shot, >sfx_push, >sfx_slow, >sfx_block, >sfx_sugar, >sfx_mouth, >sfx_power, >sfx_level
end

   ;*************************************************************************************************************************
   ; SUDDIVISIONE DEL PLAYFIELD (griglia 4x2, 8 sezioni)
   ;_________________________________________________________________________________________________________________________
   ; b0 | b1 | b2 | b3
   ;----|----|----|---
   ; b4 | b5 | b6 | b7
   ;_________________________________________________________________________________________________________________________
   ;0.TAZZE 1.MURI SPINGIBILI (ex-COLTELLI, solo b4-b7) 2.CIOCCOLATO 3.GOCCE 4.LAMPADE 5.TAVOLI+SEDIA 6.PIANO 7.ballx
   ; LIVELLI (6 + il livello segreto della Bocca Gigante)
   ; Livello 1: lampade basse in b5 e b7 (appese al piano).
   ; Livello 2: una lampada bassa in b7; nelle sezioni con le tazze una
   ; lampada chiuderebbe la colonna dal piano al pavimento e taglierebbe
   ; in due la parte bassa (in b4 chiuderebbe il biscotto alla partenza).
   ; Livello 5: cinque muri spingibili, ognuno sotto la sua lampada: sul
   ; piano in b2 e b3 (colonne 18 e 25), sul pavimento in b5, b6 e b7
   ; (colonne 11, 18 e 25). Servono almeno 4 spinte (tools/soluzione.py
   ; cerca la soluzione con meno spinte). I muri sul piano scorrono solo
   ; nella corsia della loro sezione (colonne s..s+4): i due muri alti non
   ; si toccano mai. Se le spinte chiudono la strada, alla prossima vita
   ; persa i muri tornano al loro posto (__walls_home).
   ; Gocce nella parte alta (b1, b3).
   ; Livello 6 (PRESSE, parte al buio): solo presse. La colonna 3 (gocce)
   ; diventa di presse: 4 appese al soffitto e 4 al piano (colonne 3, 10,
   ; 17, 24) che scendono fino in fondo a ritmo, sfasate da una colonna
   ; all'altra, e schiacciano il biscotto (una vita).
   ; Livello 7 (Bocca Gigante): arena vuota, il piano ha tre passaggi.

   ; presse: su, su, scende, giu' di colpo (fino in fondo), giu', risale
   ; (la pressa doppia della colonna 17 usa la meta' della lunghezza);
   ; la tabella e' periodica (9 valori = 6 + 3) per lo sfasamento 0-3
   ; gocce: scendono di 5 righe (fino al piano o al pavimento) e restano
   ; giu' un passo; periodica (9 valori = 6 + 3) per lo sfasamento 0-3
   data dropy
   0, 1, 2, 3, 4, 4, 0, 1, 2
end
   data presslen
   0, 0, 1, 4, 4, 2, 0, 0, 1
end
   data pressold
   2, 0, 0, 1, 4, 4, 2, 0, 0
end

   data objects

   %00000000, %00000000, %00000000, %00000000, %10101010, %01111010, %00100010, 18,
   %01111111, %00000000, %00000000, %00000000, %10000000, %00000000, %00101011, 136,
   %00000000, %00000000, %00110111, %00000000, %00000000, %00000000, %00001011, 18,
   %00000000, %00000000, %00000000, %11111111, %00000000, %00000000, %00101011, 136,
   %00000000, %11101100, %00000000, %00000000, %11101100, %00000000, %01111110, 136,
   %00000000, %00000000, %00000000, %11111111, %00000000, %00000000, %00101011, 136,
   %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %01010101, 136,
end

   ;*************************************************************************************************************************
   ; MACRO DEGLI OGGETTI (usano solo temp4-temp6)
   ;*************************************************************************************************************************

   ; TAZZA: blocco 5x3 (righe {2}..{2}+2) con il manico (pixel spento)
   macro cup
      temp6 = {2} + 2
      temp5 = {1} + 4
      for temp4 = {2} to temp6
         pfhline {1} temp4 temp5 on
      next
      pfpixel temp5 temp6 off
end

   ; MURO DI CIOCCOLATO: colonna {1} righe {2}..{2}+2 e colonna {1}+4
   ; righe {2}-2..{2}
   macro chocolate
      temp6 = {2} + 2
      pfvline {1} {2} temp6 on
      temp5 = {1} + 4
      temp6 = {2} - 2
      pfvline temp5 temp6 {2} on
end

   ; LAMPADA: paralume di 3 pixel nella riga {2} e lampadina sotto
   macro lamp
      temp5 = {1} + 2
      pfhline {1} {2} temp5 on
      temp5 = {1} + 1
      temp6 = {2} + 1
      pfpixel temp5 temp6 on
end

   ; TAVOLO + SEDIA: piano nella riga {2}+1, gambe e sedia nella riga {2}+2
   macro table
      temp5 = {1} + 2
      temp6 = {2} + 1
      pfhline {1} temp6 temp5 on
      temp6 = temp6 + 1
      pfpixel {1} temp6 on
      pfpixel temp5 temp6 on
      temp5 = {1} + 4
      pfpixel temp5 temp6 on
end

   ; APPOGGIO sul piano di lavoro (riga 5) dalla colonna {1} per {2}+1 pixel
   macro piano
      temp5 = {1} + {2}
      pfhline {1} 5 temp5 on
end

   ; PIANO DI LAVORO: temp4 = bit dei 7 segmenti (il primo e' 0-7, poi 4k..4k+4)
   macro divisor
      ; (in assembly: segmento k dalla colonna 4k alla 4k+4, il primo 0-7)
      asm
 lda #0
 sta temp5
 lda #7
 sta temp6
div_loop
 lsr temp4
 bcc div_skip
 lda temp6
 sta temp3
 lda temp5
 ldy #5
 ldx #0
 jsr pfhline
div_skip
 lda temp5
 clc
 adc #4
 sta temp5
 adc #4
 sta temp6
 lda temp5
 cmp #28
 bcc div_loop
end
end
