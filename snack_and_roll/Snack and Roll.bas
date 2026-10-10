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
   const frame_limit = 54

   ; muro spingibile (livello 5): colonna di partenza e corsia libera
   const _Push_Start = 12
   const _Push_Min = 8
   const _Push_Max = 16

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

   dim _music_index = m
   dim _sugarIndex = i
   dim _mouthIndex = a
   dim _mouth0x = f
   dim _mouth0y = h
   dim _mouth1x = l
   dim _mouth1y = o
   dim _prevSugarBit = q
   dim _attractTimer = s
   dim _pushCol = s
   dim _ballx = u
   dim _attractDir = y
   dim _hitCooldown = v
   dim _hasKey = z
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
   if switchreset && !_b0_enableStart{0} then _b0_enableStart{0} = 1 : _level = _choco_count+1 : _speed = 8 : score = 0 : goto __handle_level_select
   goto __skip_level_select

__handle_level_select
   temp1 = (_level-1)*2
   _speed = 0
   if _level<5 then _speed=8-temp1
   goto __skip_to_change
__skip_level_select

   ;!!!!!!!!!!!!!!!!!!! START !!!!!!!!!!!!!!!!!!!
   ;*************************************************************************************************************************
   ; MUSICA DI SOTTOFONDO
   ;_________________________________________________________________________________________________________________________
   ; le tabelle hanno 20 note (indici 0-19)
   if _music_index > 19 then _music_index = 0
   if !_b0_enableStart{0} && !(_frame_counter&15) then AUDF1 = jingle[_music_index] : AUDV1 = 2: _music_index = _music_index + 1
   if _b0_enableStart{0} && !(_frame_counter&3) then AUDF1 = melody[_music_index] : AUDV1 = 2 : _music_index = _music_index + 1

   ;Se il gioco non è ancora iniziato skippa tutto
   if !_b0_enableStart{0} then goto __attract_mode
   goto __skip_attract

__attract_mode
   if !(_frame_counter&3) then _attractTimer = _attractTimer + 1
   if _attractTimer >= 55 && _attractTimer <= 70 then goto __attract_paused
   if !_attractDir && !(_frame_counter&3) then player0x = player0x + 1
   if _attractDir && !(_frame_counter&3) then player0x = player0x - 1
   if player0x > 140 then _attractDir = 1
   if player0x < 10 then _attractDir = 0 : _attractTimer = 0
__attract_paused
   player0y=53 : player1y=53 : player1x = player0x - 15 : COLUP1=_P1_color : COLUP0=_P0_color

   ; selettore di livello iniziale con lo switch Select (5 scelte),
   ; indicatore a segmenti nella riga libera del titolo
   if switchselect && !_b1_prevSelect{1} then _choco_count = _choco_count + 1 : if _choco_count = 5 then _choco_count = 0
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
   ;*************************************************************************************************************************
   temp1 = 1
   if _level > 3 then temp1 = 2

   if _hitCooldown then _hitCooldown = _hitCooldown - 1

   _mouthIndex = _mouthIndex + 1
   if _mouthIndex >= temp1 then _mouthIndex = 0

   if !_hitCooldown && !(_frame_counter & (_speed-1)) then gosub __move_current_mouth

   if !_mouthIndex then player1x = _mouth0x : player1y = _mouth0y
   if _mouthIndex then player1x = _mouth1x : player1y = _mouth1y

   COLUP1 = mouthcolors[_mouthIndex]

   goto __skip_bocche

__move_current_mouth
   temp3 = _mouth0x : temp4 = _mouth0y
   if _mouthIndex then temp3=_mouth1x : temp4=_mouth1y

   ; insegue il biscotto
   if temp3 < player0x then temp3 = temp3 + 1
   if temp3 > player0x then temp3 = temp3 - 1
   if temp4 < player0y then temp4 = temp4 + 1
   if temp4 > player0y then temp4 = temp4 - 1

   ; la bocca 0 (livelli 1-4) non attraversa gli oggetti: controlla la
   ; posizione NUOVA (il centro della bocca) prima di spostarsi
   if _mouthIndex || _level > 4 then goto __mouth_free
   temp5 = 0
   if temp3 > 13 then temp5 = (temp3-13)/4
   temp6 = (temp4-2)/8
   if temp6<>5 && pfread(temp5,temp6) then temp3=_mouth0x : temp4=_mouth0y
__mouth_free

   if !_mouthIndex then _mouth0x=temp3 : _mouth0y=temp4
   if _mouthIndex then _mouth1x=temp3 : _mouth1y=temp4
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
   if !collision(player0, missile1) then goto __no_sugar_hit
   if _choco_bits & _prevSugarBit then goto __no_sugar_hit
   _choco_bits = _choco_bits | _prevSugarBit : _choco_count=_choco_count+1 : score=score+50 : callmacro sound 12 4 2
   if _prevSugarBit=1 then _hitCooldown=120
   if _prevSugarBit=2 then _hasKey=1
__no_sugar_hit

   ; cerca il primo zuccherino non ancora raccolto
   _sugarIndex = 0 : temp2 = 1
__find_sugar
   if !(_choco_bits & temp2) then goto __sugar_index_ok
   _sugarIndex = _sugarIndex + 1 : temp2 = temp2 * 2
   if _sugarIndex < 8 then goto __find_sugar
   missile1y = 200 : _prevSugarBit = 0
   goto __skip_all_sugar

__sugar_index_ok
   temp1 = (_level-1)*8
   temp3 = temp1 + _sugarIndex
   temp3 = sugar[temp3]
   missile1x = (temp3&7)*8+20
   missile1y = (temp3/8)*8+8
   _prevSugarBit = temp2
   ; lo zuccherino 0 (dorato) e' giallo, gli altri prendono il colore della bocca
   if !_sugarIndex then COLUP1 = $1E

__skip_all_sugar

   ;*************************************************************************************************************************
   ; GOCCE (playfield dinamico, banco 2)
   ;*************************************************************************************************************************
   gosub __update_drops bank2

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
   if _level > 3 && !_hasKey then temp4 = 0
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
   if !pfscore2 || _level > 5 then goto __game_start

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
   callmacro sound 12 4 10

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
   if temp6 = 5 && pfread(temp5,temp6) then _b4_enableLight{4}=1 : goto __delete_missile

   ;non colpisce nulla
   if !pfread(temp5,temp6) then goto __skip_missile

   ; il muro spingibile non si distrugge: ferma solo il cioccolatino
   if _level > 4 && temp5 = _pushCol && temp6 > 7 then goto __delete_missile

   ; --- regola semplificata: solo la riga "in cima" di ogni gruppo è
   ; distruttibile (righe 0 e 2 sopra il piano, 6 e 8 sotto) ---
   temp4 = 0
   if temp6=0 || temp6=2 then temp4=1
   if temp6=6 || temp6=8 then temp4=1
   if !temp4 then goto __delete_missile

   ; colpisce il playfield
   pfpixel temp5 temp6 off : score = score + 1

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

   ; MURO SPINGIBILE (livello 5): il biscotto lo spinge verso sinistra
   if _level < 5 then goto __no_push_left
   if temp6 <> _pushCol then goto __no_push_left
   if temp5 < 8 then goto __no_push_left
   temp4 = 255 : gosub __push_wall bank2
   goto __skip_left
__no_push_left

   if temp6 < 34 then if pfread(temp6,temp5) then _b6_enableSlowMotion{6} = 1 : goto __skip_left

   if temp6 < 34 then if pfread(temp6,temp3) then _b6_enableSlowMotion{6} = 1 : goto __skip_left

   if _b6_enableSlowMotion{6} then if (_frame_counter & 3) <> 0 then goto __skip_left
   player0x = player0x - 1 : _Bit2_P0_Dir_Left{2} = 1

__skip_left
   if !joy0right || player0x >= _Edge_Right then goto __skip_right

   temp5 = (player0y-1)/8 : temp6 = (player0x-9)/4
   temp3 = (player0y-4)/8

   ; MURO SPINGIBILE (livello 5): il biscotto lo spinge verso destra
   if _level < 5 then goto __no_push_right
   if temp6 <> _pushCol then goto __no_push_right
   if temp5 < 8 then goto __no_push_right
   temp4 = 1 : gosub __push_wall bank2
   goto __skip_right
__no_push_right

   if temp6 < 34 then if pfread(temp6,temp5) then _b6_enableSlowMotion{6} = 1 : goto __skip_right

   if temp6 < 34 then if pfread(temp6,temp3) then _b6_enableSlowMotion{6} = 1 : goto __skip_right

   if _b6_enableSlowMotion{6} then if (_frame_counter & 3) <> 0 then goto __skip_right
   player0x = player0x + 1 :  _Bit3_P0_Dir_Right{3} = 1
__skip_right

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
   AUDV1=10
   ; il cioccolatino sparisce (prima continuava e poteva colpire due volte)
   _b7_gameMissile0Moving{7} = 0 : missile0y = 200
   ; la collisione si riferisce alla bocca disegnata nel frame precedente:
   ; con due bocche e' l'altra rispetto a _mouthIndex
   if _level > 3 then _mouthIndex = _mouthIndex ^ 1
   gosub __reset_mouth_pos
   goto __done

__decrease_health_bar
  pfscore2=pfscore2/4
  pfscore1=%11111111
  _hitCooldown = 90
  if !pfscore2 then goto __game_start
  goto __done

__reset_mouth_pos
   if !_mouthIndex then _mouth0x=20 : _mouth0y=8
   if _mouthIndex then _mouth1x=140 : _mouth1y=90
   return

__decrease_timer_bar
   pfscore1 = pfscore1 * 2
   goto __done

__change_level
   _level=_level+1
   if _speed<2 then goto __skip_to_change
   _speed=_speed-2

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
   _choco_bits=0 : _prevSugarBit=0 : _hasKey=0
   _pushCol=_Push_Start
   _mouth0x=20 : _mouth0y=8 : _mouth1x=140 : _mouth1y=90
   ; ogni livello parte con la luce accesa, tranne il 5 che parte al buio
   _b4_enableLight{4}=1
   if _level=5 then _b4_enableLight{4}=0
   _seconds_counter = 0
   pfclear
   ; oltre l'ultimo livello non c'e' niente da caricare (si torna al titolo)
   if _level < 6 then gosub __load_level bank2

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

   ;*************************************************************************************************************************
   ; POSIZIONI FISSE DEGLI ZUCCHERINI (compaiono uno alla volta, in questo ordine)
   ;_________________________________________________________________________________________________________________________
   ; Griglia 8 colonne x 8 righe (indici 0-63). 8 valori per livello.
   ; indice = riga*8 + colonna (es. 15 = riga 1, colonna 7)
   ; missile1x = colonna*8+20 , missile1y = riga*8+8
   ; La riga dello zuccherino coincide con la riga del playfield: la riga
   ; 5 (valori 40-47) e' quella del piano di lavoro e non va usata.
   ; Le posizioni sono state verificate una per una: nessuna cade dentro
   ; un oggetto, sul piano, in una colonna di gocce o in un punto
   ; irraggiungibile. Corrette rispetto alla versione precedente:
   ; L1: 42->50  L2: 34->10, 40->48  L3: 7->31, 17->9, 33->1, 40->56
   ; L4: 1->33, 9->8, 40->56, 57->58  L5: 40->32
   ;*************************************************************************************************************************
   data sugar

   0, 10, 18, 24, 34, 50, 48, 56,
   0, 8, 16, 24, 10, 48, 50, 58,
   31, 8, 9, 24, 1, 56, 48, 61,
   33, 8, 18, 30, 39, 56, 48, 58,
   0, 8, 18, 31, 38, 32, 48, 56,
end

   data jingle
   30, 28, 26, 24, 22, 20, 18, 16, 18, 20, 22, 24, 26, 28, 30, 28, 26, 24, 22, 20
end
   data melody
   16, 18, 16, 20, 18, 20, 22, 20, 18, 16, 18, 20, 22, 20, 18, 16, 18, 16, 20, 22
end

   macro sound
   AUDV1 = {1}
   AUDF1 = {3}
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

   ; --- muro spingibile (livello 5): poggia sul pavimento, righe 8-10 ---
   if _level > 4 then pfvline _pushCol 8 10 on

   return otherbank

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
   ; MURO SPINGIBILE (livello 5)
   ;_________________________________________________________________________________________________________________________
   ; temp4 = direzione (1 = destra, 255 = sinistra)
   ; Il muro (colonna _pushCol, righe 8-10) si sposta di una colonna ogni
   ; 8 frame mentre il biscotto lo spinge, se la colonna successiva e'
   ; libera e resta nella corsia _Push_Min.._Push_Max. Spingere non
   ; attiva lo slow motion.
   ;*************************************************************************************************************************
__push_wall
   if _frame_counter & 7 then return otherbank
   temp5 = _pushCol + temp4
   if temp5 < _Push_Min || temp5 > _Push_Max then return otherbank
   if pfread(temp5, 8) then return otherbank
   if pfread(temp5, 9) then return otherbank
   if pfread(temp5, 10) then return otherbank
   pfvline _pushCol 8 10 off
   _pushCol = temp5
   pfvline _pushCol 8 10 on
   AUDV1 = 6 : AUDF1 = 28
   return otherbank

   ;*************************************************************************************************************************
   ; SUDDIVISIONE DEL PLAYFIELD (griglia 4x2, 8 sezioni)
   ;_________________________________________________________________________________________________________________________
   ; b0 | b1 | b2 | b3
   ;----|----|----|---
   ; b4 | b5 | b6 | b7
   ;_________________________________________________________________________________________________________________________
   ;0.TAZZE 1.(inutilizzato, ex-COLTELLI) 2.CIOCCOLATO 3.GOCCE 4.LAMPADE 5.TAVOLI+SEDIA 6.PIANO 7.ballx
   ; LIVELLI (5)
   ; Livello 1: lampade basse in b5 e b7 (appese al piano).
   ; Livello 2: una lampada bassa in b7; nelle sezioni con le tazze una
   ; lampada chiuderebbe la colonna dal piano al pavimento e taglierebbe
   ; in due la parte bassa (in b4 chiuderebbe il biscotto alla partenza).
   ; Livello 5: un solo tavolo in basso (sezione b4) per lasciare la
   ; corsia libera (colonne 8-16) al muro spingibile.

   data objects

   %00000000, %00000000, %00000000, %00000000, %10101010, %01111010, %00100010, 18,
   %01111111, %00000000, %00000000, %00000000, %10000000, %00000000, %00101011, 136,
   %00000000, %00000000, %00110111, %00000000, %00000000, %00000000, %00001011, 18,
   %00000000, %00000000, %10101010, %01010101, %00000000, %00000000, %00101011, 136,
   %11000000, %00000000, %00000011, %00001100, %00010000, %00010000, %00101011, 18,
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
