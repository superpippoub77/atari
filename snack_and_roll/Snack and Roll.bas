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

   ; muri spingibili (fino a 3 per livello, 255 = nessuno). _pushCol2/3 e i
   ; contatori qui sotto usano variabili che servono solo durante il
   ; caricamento del livello (w, x, j, r, n): vengono impostati dopo.
   dim _pushCol2 = w
   dim _pushCol3 = x
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
   dim _mouthIndex = a
   dim _mouth0x = f
   dim _mouth0y = h
   dim _mouth1x = l
   dim _mouth1y = o
   dim _attractTimer = s
   dim _pushCol = s
   dim _ballx = u
   dim _attractDir = y
   dim _hitCooldown = v
   ; chiave (zuccherino 1) e stato dello slow motion nel frame precedente
   dim _b2_hasKey = k
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

   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 3 : h = 3 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : w = 0 : x = 0 : y = 0

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
   playfield:
   ................................
   ...XXX..X..X...XX....XX...X..X..
   ..X.....XX.X..X..X..X..X..X.X...
   ...XX...X.XX..XXXX..X.....XX....
   .....X..X..X..X..X..X..X..X.X...
   ..XXX...X..X..X..X...XX...X..X..
   ................................
   X......X.X.X..XX..X.X...X...XXX.
   ..X.XX...XX..X..X.X.X...XX.XX...
   ..XX.X...X...X..X.X.X...X.X.XX..
   ..X..X...X....XX..X.X...X...X...
end
   pfcolors:
   $20
   $21
   $22
   $23
   $24
   $20
   $9E
   $28
   $26
   $24
   $22
end

__game_start
   ;flag
   ; se arriviamo qui da una partita vera, ridisegniamo tutto il titolo
   if !_b0_enableStart{0} then goto __skip_gameover_clear
   _b0_enableStart{0} = 0
   missile1y = 200 : _choco_count = 0 : bally = 200 : missile0y = 200
   ; silenzio sugli effetti, la musica del titolo riparte da capo
   _sfxId = 0 : AUDV0 = 0 : _music_index = 0
   goto __draw_title
__skip_gameover_clear
   _b0_enableStart{0} = 0
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

   ;F2 (reset) inizia il gioco
   if switchreset && !_b0_enableStart{0} then _b0_enableStart{0} = 1 : _level = _choco_count+1 : _lap = 0 : score = 0 : _music_index = 0 : goto __skip_to_change

   ;!!!!!!!!!!!!!!!!!!! START !!!!!!!!!!!!!!!!!!!
   ;*************************************************************************************************************************
   ; MUSICA DI SOTTOFONDO
   ;_________________________________________________________________________________________________________________________
   ; Canale 1. Ogni passo della tabella: 0 = la nota continua,
   ; 1 = pausa, altro = nuova nota (valore AUDF).
   ; Titolo: tema "avventura" stile Indiana Jones (AUDC 4), un passo ogni
   ; 6 frame (una semicroma). In gioco: arpeggio leggero (AUDC 12, volume
   ; basso), un passo ogni 8 frame.
   if _b0_enableStart{0} then goto __game_music
   _mouthTick = _mouthTick + 1
   if _mouthTick < 6 then goto __music_done
   _mouthTick = 0
   temp1 = titlemusic[_music_index]
   _music_index = _music_index + 1
   if _music_index >= 92 then _music_index = 0
   AUDC1 = 4 : temp2 = 5
   goto __music_note
__game_music
   if _frame_counter & 7 then goto __music_done
   temp1 = gamemusic[_music_index]
   _music_index = (_music_index + 1) & 31
   AUDC1 = 12 : temp2 = 2
__music_note
   if !temp1 then goto __music_done
   if temp1 = 1 then AUDV1 = 0 : goto __music_done
   AUDF1 = temp1 : AUDV1 = temp2
__music_done

   ;Se il gioco non è ancora iniziato skippa tutto
   if !_b0_enableStart{0} then goto __attract_mode
   goto __skip_attract

__attract_mode
   ; scorrimento continuo: il biscotto entra sempre da destra e attraversa
   ; lo schermo verso sinistra inseguito dalla bocca, senza pause e senza
   ; tornare indietro; uscito a sinistra rientra da destra
   if !(_frame_counter&1) then player0x = player0x - 1
   if player0x < 2 || player0x > 150 then player0x = 150
   player0y=53 : player1y=53 : player1x = player0x + 15 : COLUP1=_P1_color : COLUP0=_P0_color
   ; la bocca, ancora fuori dallo schermo a destra, non si disegna
   if player1x > 152 then player1y = 200

   ; selettore di livello iniziale con lo switch Select (6 scelte),
   ; indicatore a segmenti nella riga libera del titolo
   if switchselect && !_b1_prevSelect{1} then _choco_count = _choco_count + 1 : if _choco_count = _Levels then _choco_count = 0
   _b1_prevSelect{1} = 0
   if switchselect then _b1_prevSelect{1} = 1
   pfhline 1 6 9 off
   temp1=_choco_count*2+1
   pfpixel temp1 6 on

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
   if _level > 3 then temp1 = 2

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
   if _mouthTick < _speed then goto __mouth_still
   _mouthTick = 0
   temp6 = 0
   if !_mouth0wait then gosub __move_mouth
   temp6 = 1
   if temp1 = 2 && !_mouth1wait then gosub __move_mouth
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

   COLUP1 = mouthcolors[_mouthIndex]

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
   return
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
   if temp2 = 2 then _b2_hasKey{2} = 1
   if temp2 = 1 then goto __golden_sugar
   callmacro sfx 5
   goto __no_sugar_hit
__golden_sugar
   ; super potere: bocche congelate e biscotto invulnerabile
   _hitCooldown = 120
   callmacro sfx 7
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
   ; lo zuccherino 0 (dorato) e' giallo, gli altri prendono il colore della bocca
   if !temp4 then COLUP1 = $1E

__skip_all_sugar

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

   ; temp1 = "mostra i colori normali questo frame" - vero se
   ; la luce è accesa, oppure se è il fotogramma di flash col buio
   temp1 = 0
   if _b4_enableLight{4} then temp1 = 1
   if !(_frame_counter&31) then temp1 = 1

   ;Background visibile con effetto flash se il flag della lamp è spento
   if temp1 && _level<3 then pfcolors:
   $05
   $9E
   $0E
   $24
   $26
   $02
   $05
   $9E
   $0E
   $24
   $26
end
   if temp1 && _level>2 then pfcolors:
   $28
   $26
   $20
   $22
   $20
   $02
   $28
   $26
   $20
   $22
   $20
end

   ; Background
   if !_b4_enableLight{4} && _frame_counter&7 then pfcolors:
   0
end

   ;*************************************************************************************************************************
   ; CONTENITORE FINALE (BALL)
   ;_________________________________________________________________________________________________________________________
   ; il sacchetto finale individuato come ball viene visualizzato solo dopo aver trovato gli 8 cioccolatini nel playfield
   ; e la bocca è stata colpita (dal livello 4 serve anche la chiave)
   ; _ballx viene letto dalla colonna 7 di "objects" al caricamento del livello
   ;*************************************************************************************************************************
   temp4 = 1
   if _level > 3 && !_b2_hasKey{2} then temp4 = 0
   if _choco_count = 8 && !_b5_enablePalyer1{5} && temp4 then ballx = _ballx : bally = 28

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

   ; ---- 4 ----
   if _frame_counter=frame_limit && pfscore1 <=8 then pfscorecolor = rand&2
   ; ---- 5 ----
   if !(_seconds_counter&7) then _b6_enableSlowMotion{6} = 0
   ; ---- 6 ----
   if !_b4_enableLight{4} then COLUP1 = $0
   ; ---- 7 ----
   if _b6_enableSlowMotion{6} then COLUP0 = $20 else COLUP0 = _P0_color
   if _hitCooldown && _frame_counter&4 then COLUP0 = $00
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
   callmacro sfx 1

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
   if temp6 = 5 && pfread(temp5,temp6) then _b4_enableLight{4}=1 : goto __delete_missile

   ;non colpisce nulla
   if !pfread(temp5,temp6) then goto __skip_missile

   ; il muro spingibile non si distrugge: ferma solo il cioccolatino
   ; (if semplici: un || dentro un if annidato non viene compilato bene)
   if temp6 < 8 then goto __not_push_wall
   if temp5 = _pushCol then goto __delete_missile
   if temp5 = _pushCol2 then goto __delete_missile
   if temp5 = _pushCol3 then goto __delete_missile
__not_push_wall

   ; --- regola semplificata: solo la riga "in cima" di ogni gruppo è
   ; distruttibile (righe 0 e 2 sopra il piano, 6 e 8 sotto) ---
   temp4 = 0
   if temp6=0 || temp6=2 then temp4=1
   if temp6=6 || temp6=8 then temp4=1
   if !temp4 then goto __delete_missile

   ; colpisce il playfield
   pfpixel temp5 temp6 off : score = score + 1
   callmacro sfx 4

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
   if !_b0_enableStart{0} then goto __done

   ;*************************************************************************************************************************
   ; MOVIMENTO BISCOTTO
   ;_________________________________________________________________________________________________________________________

   if !joy0up || player0y <= _P_Edge_Top then goto __skip_up

   temp5 = (player0x-10)/4 : temp6 = (player0y-5)/8

   if temp5 < 31 then if pfread(temp5,temp6) then _b6_enableSlowMotion{6} =1 :goto __skip_up

   temp4 = (player0x-17)/4

   if temp4 < 31 then if pfread(temp4,temp6) then _b6_enableSlowMotion{6} =1 :goto __skip_up

   temp3 = temp5 - 1

   if temp3 < 31 then if pfread(temp3,temp6) then _b6_enableSlowMotion{6} =1 :goto __skip_up

   if _b6_enableSlowMotion{6} then if (_frame_counter & 3) <> 0 then goto __skip_up
   player0y = player0y - 1 : _Bit0_P0_Dir_Up{0} = 1

__skip_up

   if !joy0down || player0y >= _Edge_Bottom then goto __skip_down

   temp5 = (player0x-10)/4 : temp6 = (player0y)/8

   if temp5 < 31 then if pfread(temp5,temp6) then _b6_enableSlowMotion{6} = 1 :goto __skip_down

   temp4 = (player0x-17)/4

   if temp4 < 31 then if pfread(temp4,temp6) then _b6_enableSlowMotion{6} = 1 :goto __skip_down

   temp3 = temp5 - 1

   if temp3 < 31 then if pfread(temp3,temp6) then _b6_enableSlowMotion{6} = 1 :goto __skip_down

   if _b6_enableSlowMotion{6} then if (_frame_counter & 3) <> 0 then goto __skip_down
   player0y = player0y + 1 : _Bit1_P0_Dir_Down{1} = 1
__skip_down

   if !joy0left || player0x <= _P_Edge_Left  then goto __skip_left

   temp5 = (player0y-1)/8 : temp6 = (player0x-18)/4
   temp3 = (player0y-4)/8

   ; MURI SPINGIBILI: il biscotto li spinge verso sinistra
   if temp5 < 8 then goto __no_push_left
   temp2 = 255
   if temp6 = _pushCol then temp2 = 0
   if temp6 = _pushCol2 then temp2 = 1
   if temp6 = _pushCol3 then temp2 = 2
   if temp2 = 255 then goto __no_push_left
   temp4 = 255 : gosub __push_wall bank2
   goto __skip_left
__no_push_left

   if temp6 < 32 then if pfread(temp6,temp5) then _b6_enableSlowMotion{6} = 1 : goto __skip_left

   if temp6 < 32 then if pfread(temp6,temp3) then _b6_enableSlowMotion{6} = 1 : goto __skip_left

   if _b6_enableSlowMotion{6} then if (_frame_counter & 3) <> 0 then goto __skip_left
   player0x = player0x - 1 : _Bit2_P0_Dir_Left{2} = 1

__skip_left
   if !joy0right || player0x >= _Edge_Right then goto __skip_right

   temp5 = (player0y-1)/8 : temp6 = (player0x-9)/4
   temp3 = (player0y-4)/8

   ; MURI SPINGIBILI: il biscotto li spinge verso destra
   if temp5 < 8 then goto __no_push_right
   temp2 = 255
   if temp6 = _pushCol then temp2 = 0
   if temp6 = _pushCol2 then temp2 = 1
   if temp6 = _pushCol3 then temp2 = 2
   if temp2 = 255 then goto __no_push_right
   temp4 = 1 : gosub __push_wall bank2
   goto __skip_right
__no_push_right

   ; colonne 32-33 sono fuori dallo schermo: pfread leggerebbe la riga sotto
   if temp6 < 32 then if pfread(temp6,temp5) then _b6_enableSlowMotion{6} = 1 : goto __skip_right

   if temp6 < 32 then if pfread(temp6,temp3) then _b6_enableSlowMotion{6} = 1 : goto __skip_right

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
   callmacro sfx 3
__slow_sound_done

__game_collision
   ;*************************************************************************************************************************
   ; COLLISIONI
   ;_________________________________________________________________________________________________________________________
   ; Biscotto e Bocca: decremento la barra di una vita
   ; Missile e Bocca: incremento dei punti di 10 unità e e disabilito la bocca
   ; Biscotto e Arrivo : cambio di livello
   ;*************************************************************************************************************************
   if !_hitCooldown && collision(player0, player1) then goto __decrease_health_bar
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
   score = score + 10
   _b5_enablePalyer1{5} = 0
   callmacro sfx 6
   ; il cioccolatino sparisce (prima continuava e poteva colpire due volte)
   _b7_gameMissile0Moving{7} = 0 : missile0y = 200
   ; la collisione si riferisce alla bocca disegnata nel frame precedente:
   ; con due bocche e' l'altra rispetto a _mouthIndex
   if _level > 3 then _mouthIndex = _mouthIndex ^ 1
   gosub __kill_mouth
   goto __done

__decrease_health_bar
  pfscore2=pfscore2/4
  pfscore1=%11111111
  _hitCooldown = 90
  if !pfscore2 then goto __game_start
  goto __done

   ; la bocca _mouthIndex sparisce e ricomparira' dopo _Mouth_Respawn frame
__kill_mouth
   if !_mouthIndex then _mouth0wait = _Mouth_Respawn : _mouth0y = 200
   if _mouthIndex then _mouth1wait = _Mouth_Respawn : _mouth1y = 200
   return

__decrease_timer_bar
   pfscore1 = pfscore1 * 2
   goto __done

__change_level
   callmacro sfx 8
   _level=_level+1
   ; dopo l'ultimo livello si riparte dal primo, un giro piu' veloce
   if _level > _Levels then _level = 1 : _lap = _lap + 1

__skip_to_change
   pfscorecolor = $08
   scorecolor=(scorecolor + $10) & $F0
   pfscore1=%11111111
   pfscore2=%10101010
   bally=200
   missile0y=200
   player0x=10:player0y=64
   _b5_enablePalyer1{5}=1
   _b7_gameMissile0Moving{7}=0
   _choco_count=0
   _choco_bits=0 : _b2_hasKey{2}=0
   ; ogni livello parte con la luce accesa, tranne l'ultimo che parte al buio
   _b4_enableLight{4}=1
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
   _mouth0wait = 0 : _mouth1wait = 0 : _mouthTick = 0

__done

   drawscreen
   goto __main_loop

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
   0, 12, 10, 9, 8, 8, 7
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
   ; a colpi di cioccolatino). Ordine di comparsa: si parte in basso a
   ; sinistra e si attraversa lo schermo alternando sotto e sopra.
   ; Posizioni calcolate e verificate con snack_and_roll/tests/sugar_layout.py
   ;*************************************************************************************************************************
   data sugar

   49, 9, 58, 10, 37, 29, 54, 22,
   49, 17, 51, 19, 52, 20, 39, 22,
   33, 25, 42, 18, 53, 21, 62, 14,
   56, 8, 35, 27, 37, 21, 55, 14,
   33, 9, 34, 10, 37, 29, 46, 22,
   40, 16, 43, 11, 52, 13, 54, 31,
end

   ; tema del titolo (semicrome, AUDC 4): Mi Fa Sol Do... Re Mi Fa...
   ; Sol La Si Fa... La Si Do Re Mi...   (Mi5=23 Fa5=21 Sol5=19 La5=17
   ; Si5=15 Do6=14 Re5=26 Re6=12 Mi6=11 Fa6=10; 0 = continua, 1 = pausa)
   data titlemusic
   23, 0, 0, 21, 19, 0, 0, 0, 14, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
   26, 0, 0, 23, 21, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
   19, 0, 0, 17, 15, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
   17, 0, 0, 15, 14, 0, 0, 0, 12, 0, 0, 0, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
   1, 1, 1, 1, 1, 1, 1, 1
end

   ; musica di sottofondo in gioco (AUDC 12, volume basso): arpeggi di
   ; Do, La minore, Fa e Sol, una nota ogni due passi
   ; (Do4=19 Mi4=15 Sol4=12 La3=23 Fa3=29 Sol3=25 Si3=20 Re4=17)
   data gamemusic
   19, 1, 15, 1, 12, 1, 15, 1,
   23, 1, 19, 1, 15, 1, 19, 1,
   29, 1, 23, 1, 19, 1, 23, 1,
   25, 1, 20, 1, 17, 1, 20, 1
end

   ; avvia un effetto sonoro se non ne sta suonando uno piu' importante
   macro sfx
   if _sfxId <= {1} then _sfxId = {1} : _sfxPos = 0 : _sfxDur = 0
end

   ;#########################################################################################################################
   ;#########################################################################################################################
   ; BANCO 2: CARICAMENTO DEI LIVELLI, GOCCE, MURO SPINGIBILE
   ;#########################################################################################################################
   ;#########################################################################################################################
   bank 2

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
__load_level
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
   if !(objects[_current_object_level]&_current_bit_object) then goto __skip_tazze
   callmacro cup _playfield_section _playfield_down
   if _playfield_up then goto __skip_tazze
   callmacro piano _playfield_section 4
__skip_tazze

   ; MURI DI CIOCCOLATO
   temp2 = _current_object_level+2
   if !(objects[temp2]&_current_bit_object) then goto __skip_muri
   callmacro chocolate _playfield_section _playfield_down
   temp5 = _playfield_section + 4
   if _playfield_up then pfpixel temp5 5 on : goto __skip_muri
   callmacro piano _playfield_section 4
__skip_muri

   ; GOCCE: qui si disegna solo il punto di appoggio delle gocce basse
   ; (la goccia che scende la anima __update_drops ad ogni frame)
   temp2 = _current_object_level+3
   if !(objects[temp2]&_current_bit_object) then goto __skip_gocce
   if _playfield_up then pfpixel _playfield_section 5 on
__skip_gocce

   ; LAMPADE
   temp2 = _current_object_level+4
   if !(objects[temp2]&_current_bit_object) then goto __skip_lampade
   callmacro lamp _playfield_section _playfield_up
   if !_playfield_up then goto __skip_lampade
   callmacro piano _playfield_section 2
__skip_lampade

   ; TAVOLO + SEDIA
   temp2 = _current_object_level+5
   if !(objects[temp2]&_current_bit_object) then goto __skip_tavoli
   callmacro table _playfield_section _playfield_down
   if _playfield_up then goto __skip_tavoli
   callmacro piano _playfield_section 4
__skip_tavoli

   _current_bit_object = _current_bit_object * 2
   _playfield_section = _playfield_section + 7

   if !_playfield_up && _current_bit_object = 16 then _playfield_section = 3 : _playfield_up = 6 : _playfield_down = 8
   if _current_bit_object then goto __loop_objects

   ; --- MURI SPINGIBILI (colonna 1 di objects, sezioni basse b4-b7) ---
   ; un muro per bit acceso, nella colonna sezione+2 (5, 12, 19, 26),
   ; poggiato sul pavimento (righe 8-10). Al massimo 3 muri.
   _pushCol = 255 : _pushCol2 = 255 : _pushCol3 = 255
   temp2 = _current_object_level + 1
   temp4 = objects[temp2]
   temp4 = temp4 / 16
   temp5 = 5
__wall_loop
   if !temp4 then return otherbank
   if !(temp4 & 1) then goto __wall_next
   pfvline temp5 8 10 on
   if _pushCol = 255 then _pushCol = temp5 : goto __wall_next
   if _pushCol2 = 255 then _pushCol2 = temp5 : goto __wall_next
   _pushCol3 = temp5
__wall_next
   temp4 = temp4 / 2
   temp5 = temp5 + 7
   goto __wall_loop

   ;*************************************************************************************************************************
   ; GOCCE (colonna 3 di "objects") - chiamata ad ogni frame
   ;_________________________________________________________________________________________________________________________
   ; Ogni 8 frame la goccia di ogni sezione scende di una riga: si cancella
   ; la sua colonna (4 righe) e si accende il nuovo punto, senza sfarfallio.
   ; Sopra: righe 0-3 (appese al soffitto). Sotto: righe 6-9 (appese al piano).
   ;*************************************************************************************************************************
__update_drops
   if _frame_counter & 7 then return otherbank
   temp2 = _level - 1
   temp2 = temp2 * 8
   temp2 = temp2 + 3
   temp4 = objects[temp2]
   temp5 = 3 : temp6 = 0
__drop_loop
   if !temp4 then return otherbank
   if !(temp4 & 1) then goto __drop_next
   temp1 = temp6 + 3
   pfvline temp5 temp6 temp1 off
   temp1 = _frame_counter / 8
   temp1 = temp1 + temp5
   temp1 = temp1 & 3
   temp1 = temp1 + temp6
   pfpixel temp5 temp1 on
__drop_next
   temp4 = temp4 / 2
   temp5 = temp5 + 7
   if temp5 = 31 then temp5 = 3 : temp6 = 6
   goto __drop_loop

   ;*************************************************************************************************************************
   ; MURI SPINGIBILI
   ;_________________________________________________________________________________________________________________________
   ; temp2 = quale muro (0, 1, 2)   temp4 = direzione (1 = destra, 255 = sinistra)
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
   temp1 = _pushCol
   if temp6 = 1 then temp1 = _pushCol2
   if temp6 = 2 then temp1 = _pushCol3
   temp5 = temp1 + temp4
   if temp5 > 31 then return otherbank
   ; pfread/pfvline usano temp1-temp3: la vecchia colonna va in temp4
   temp4 = temp1
   if pfread(temp5, 8) then return otherbank
   if pfread(temp5, 9) then return otherbank
   if pfread(temp5, 10) then return otherbank
   pfvline temp4 8 10 off
   pfvline temp5 8 10 on
   if temp6 = 0 then _pushCol = temp5
   if temp6 = 1 then _pushCol2 = temp5
   if temp6 = 2 then _pushCol3 = temp5
   callmacro sfx 2

   ; --- bocche schiacciate dal muro ---
   ; il muro occupa i pixel x da temp4 a temp4+3, righe 8-10 (y >= 65)
   temp4 = temp5 * 4
   temp4 = temp4 + 17
   ; larghezza della bocca: 8 pixel, 16 dal livello 4 (NUSIZ1 doppio)
   temp3 = 7
   if _level > 3 then temp3 = 15
   if _mouth0wait then goto __crush_mouth1
   if _mouth0y < 65 then goto __crush_mouth1
   temp2 = temp4 + 3
   if _mouth0x > temp2 then goto __crush_mouth1
   temp2 = _mouth0x + temp3
   if temp2 < temp4 then goto __crush_mouth1
   _mouth0wait = _Mouth_Respawn : _mouth0y = 200
   score = score + 10 : _b5_enablePalyer1{5} = 0
   callmacro sfx 6
__crush_mouth1
   if _level < 4 then return otherbank
   if _mouth1wait then return otherbank
   if _mouth1y < 65 then return otherbank
   temp2 = temp4 + 3
   if _mouth1x > temp2 then return otherbank
   temp2 = _mouth1x + temp3
   if temp2 < temp4 then return otherbank
   _mouth1wait = _Mouth_Respawn : _mouth1y = 200
   score = score + 10 : _b5_enablePalyer1{5} = 0
   callmacro sfx 6
   return otherbank

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
__play_sfx
   if !_sfxId then return otherbank
   if _sfxDur then _sfxDur = _sfxDur - 1 : return otherbank
   temp6 = _sfxPos
   on _sfxId goto __sfx_none __sfx_shot __sfx_push __sfx_slow __sfx_block __sfx_sugar __sfx_mouth __sfx_power __sfx_level
__sfx_none
   return otherbank
__sfx_shot
   temp1 = sfx_shot[temp6] : temp6 = temp6 + 1
   temp2 = sfx_shot[temp6] : temp6 = temp6 + 1
   temp3 = sfx_shot[temp6]
   goto __sfx_note
__sfx_push
   temp1 = sfx_push[temp6] : temp6 = temp6 + 1
   temp2 = sfx_push[temp6] : temp6 = temp6 + 1
   temp3 = sfx_push[temp6]
   goto __sfx_note
__sfx_slow
   temp1 = sfx_slow[temp6] : temp6 = temp6 + 1
   temp2 = sfx_slow[temp6] : temp6 = temp6 + 1
   temp3 = sfx_slow[temp6]
   goto __sfx_note
__sfx_block
   temp1 = sfx_block[temp6] : temp6 = temp6 + 1
   temp2 = sfx_block[temp6] : temp6 = temp6 + 1
   temp3 = sfx_block[temp6]
   goto __sfx_note
__sfx_sugar
   temp1 = sfx_sugar[temp6] : temp6 = temp6 + 1
   temp2 = sfx_sugar[temp6] : temp6 = temp6 + 1
   temp3 = sfx_sugar[temp6]
   goto __sfx_note
__sfx_mouth
   temp1 = sfx_mouth[temp6] : temp6 = temp6 + 1
   temp2 = sfx_mouth[temp6] : temp6 = temp6 + 1
   temp3 = sfx_mouth[temp6]
   goto __sfx_note
__sfx_power
   temp1 = sfx_power[temp6] : temp6 = temp6 + 1
   temp2 = sfx_power[temp6] : temp6 = temp6 + 1
   temp3 = sfx_power[temp6]
   goto __sfx_note
__sfx_level
   temp1 = sfx_level[temp6] : temp6 = temp6 + 1
   temp2 = sfx_level[temp6] : temp6 = temp6 + 1
   temp3 = sfx_level[temp6]
   goto __sfx_note
__sfx_note
   if temp1 = 255 then _sfxId = 0 : AUDV0 = 0 : return otherbank
   AUDV0 = temp1 / 16 : AUDC0 = temp1 & 15 : AUDF0 = temp2
   _sfxDur = temp3 - 1
   _sfxPos = _sfxPos + 3
   return otherbank

   ; pewpew (20 note) - sparo
   data sfx_shot
   244, 28, 1, 244, 28, 1, 180, 9, 1, 172, 3, 1, 236, 4, 1, 196, 18, 1
   244, 25, 1, 244, 28, 1, 84, 7, 1, 84, 9, 1, 100, 13, 1, 84, 12, 1
   100, 24, 1, 84, 28, 1, 52, 30, 1, 52, 7, 1, 52, 9, 1, 36, 12, 1
   44, 4, 1, 28, 6, 1, 255
end

   ; dragit (10 note) - muro spinto
   data sfx_push
   39, 28, 1, 103, 2, 1, 152, 30, 1, 152, 17, 1, 152, 30, 1, 103, 17, 1
   152, 30, 1, 103, 17, 1, 55, 14, 1, 39, 6, 1, 255
end

   ; electrobump (9 note) - scossa / scivolata (inizio rallentamento)
   data sfx_slow
   168, 8, 2, 172, 8, 2, 166, 8, 2, 174, 8, 2, 134, 8, 2, 134, 8, 2
   110, 8, 2, 70, 8, 2, 38, 8, 2, 255
end

   ; poof1 (12 note) - blocco abbattuto
   data sfx_block
   72, 7, 1, 104, 7, 1, 136, 7, 1, 136, 9, 1, 168, 12, 1, 168, 9, 1
   168, 12, 1, 168, 9, 1, 136, 13, 1, 104, 14, 1, 72, 9, 1, 40, 9, 1
   255
end

   ; gotthecoin (23 note) - zuccherino preso
   data sfx_sugar
   252, 4, 1, 252, 4, 1, 228, 10, 1, 244, 10, 1, 244, 10, 1, 212, 10, 1
   148, 10, 1, 148, 10, 1, 132, 10, 1, 116, 10, 1, 100, 10, 1, 84, 10, 1
   52, 10, 1, 116, 10, 1, 148, 10, 1, 52, 10, 1, 20, 10, 1, 20, 10, 1
   20, 10, 1, 4, 10, 1, 20, 10, 1, 20, 10, 1, 20, 10, 1, 255
end

   ; explosion (46 note) - bocca uccisa
   data sfx_mouth
   40, 1, 1, 92, 11, 1, 134, 4, 1, 254, 3, 1, 246, 9, 1, 246, 13, 1
   254, 4, 1, 134, 15, 1, 70, 9, 1, 49, 22, 1, 70, 12, 1, 86, 9, 1
   54, 10, 1, 86, 9, 1, 134, 13, 1, 70, 9, 1, 110, 4, 1, 86, 15, 1
   118, 15, 1, 126, 4, 1, 102, 8, 1, 142, 3, 1, 102, 15, 1, 86, 9, 1
   86, 6, 1, 94, 3, 1, 102, 14, 1, 94, 2, 1, 54, 15, 1, 102, 14, 1
   86, 9, 1, 86, 12, 1, 54, 15, 1, 142, 4, 1, 54, 12, 1, 54, 15, 1
   102, 12, 1, 70, 15, 1, 86, 15, 1, 54, 15, 1, 70, 10, 1, 54, 15, 1
   54, 8, 1, 54, 12, 1, 54, 14, 1, 54, 8, 1, 255
end

   ; powerup (53 note) - super potere (zuccherino dorato)
   data sfx_power
   246, 30, 1, 244, 28, 1, 252, 12, 1, 252, 12, 1, 252, 12, 1, 244, 28, 1
   164, 27, 1, 148, 22, 1, 116, 18, 1, 228, 18, 1, 132, 18, 1, 52, 13, 1
   132, 18, 1, 244, 18, 1, 252, 11, 1, 252, 11, 1, 204, 11, 1, 100, 28, 1
   196, 28, 1, 252, 7, 1, 156, 7, 1, 172, 5, 1, 116, 24, 1, 252, 7, 1
   172, 7, 1, 204, 5, 1, 92, 5, 1, 54, 30, 1, 76, 3, 1, 76, 3, 1
   76, 3, 1, 140, 2, 1, 76, 3, 1, 38, 30, 1, 236, 10, 1, 252, 10, 1
   212, 30, 1, 132, 25, 1, 180, 21, 1, 244, 21, 1, 132, 21, 1, 116, 15, 1
   116, 21, 1, 196, 21, 1, 124, 6, 1, 36, 15, 1, 70, 0, 1, 12, 1, 1
   68, 10, 1, 132, 10, 1, 52, 10, 1, 52, 7, 1, 52, 10, 1, 255
end

   ; oneup (50 note) - cambio livello
   data sfx_level
   244, 22, 1, 244, 22, 1, 132, 22, 1, 68, 19, 1, 36, 19, 1, 22, 18, 1
   22, 18, 1, 244, 18, 1, 244, 18, 1, 132, 18, 1, 68, 17, 1, 36, 16, 1
   20, 16, 1, 20, 16, 1, 132, 10, 1, 132, 10, 1, 6, 30, 1, 6, 30, 1
   6, 30, 1, 6, 30, 1, 132, 13, 1, 132, 13, 1, 132, 13, 1, 100, 13, 1
   6, 30, 1, 6, 30, 1, 6, 30, 1, 132, 12, 1, 68, 12, 1, 6, 30, 1
   6, 30, 1, 6, 30, 1, 6, 30, 1, 100, 9, 1, 36, 1, 1, 68, 9, 1
   36, 9, 1, 68, 9, 1, 68, 9, 1, 36, 1, 1, 68, 9, 1, 4, 1, 1
   68, 9, 1, 36, 1, 1, 68, 9, 1, 36, 9, 1, 36, 9, 1, 68, 9, 1
   36, 1, 1, 20, 1, 1, 255
end


   ;*************************************************************************************************************************
   ; SUDDIVISIONE DEL PLAYFIELD (griglia 4x2, 8 sezioni)
   ;_________________________________________________________________________________________________________________________
   ; b0 | b1 | b2 | b3
   ;----|----|----|---
   ; b4 | b5 | b6 | b7
   ;_________________________________________________________________________________________________________________________
   ;0.TAZZE 1.MURI SPINGIBILI (ex-COLTELLI, solo b4-b7) 2.CIOCCOLATO 3.GOCCE 4.LAMPADE 5.TAVOLI+SEDIA 6.PIANO 7.ballx
   ; LIVELLI (6)
   ; Livello 1: lampade basse in b5 e b7 (appese al piano).
   ; Livello 2: una lampada bassa in b7; nelle sezioni con le tazze una
   ; lampada chiuderebbe la colonna dal piano al pavimento e taglierebbe
   ; in due la parte bassa (in b4 chiuderebbe il biscotto alla partenza).
   ; Livello 5: solo muri spingibili (3, nelle sezioni b5, b6, b7).
   ; Livello 6: un solo tavolo in basso (sezione b4) per lasciare la
   ; corsia libera (colonne 8-16) al muro spingibile in b5.

   data objects

   %00000000, %00000000, %00000000, %00000000, %10101010, %01111010, %00100010, 18,
   %01111111, %00000000, %00000000, %00000000, %10000000, %00000000, %00101011, 136,
   %00000000, %00000000, %00110111, %00000000, %00000000, %00000000, %00001011, 18,
   %00000000, %00000000, %10101010, %01010101, %00000000, %00000000, %00101011, 136,
   %00000000, %11100000, %00000000, %00000000, %00000000, %00000000, %00011011, 136,
   %11000000, %00100000, %00000011, %00001100, %00010000, %00010000, %00101011, 18,
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
      temp5 = 0
      temp6 = 7
__divisor_loop
      if temp4 & 1 then pfhline temp5 5 temp6 on
      temp4 = temp4 / 2
      temp5 = temp5 + 4
      temp6 = temp5 + 4
      if temp5 < 28 then goto __divisor_loop
end
