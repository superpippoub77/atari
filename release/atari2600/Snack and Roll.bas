   ;*************************************************************************************************************************
   ; SETTAGGIO DEL KERNEL E OPZIONI
   ;_________________________________________________________________________________________________________________________
   ; pfcolors = colorazione del playfield
   ; romsize = 4k (default)
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

   ; v1-fix: per testare in fretta un livello specifico, cambia questo
   ; numero (1-18) e ricompila - si parte direttamente da lì premendo
   ; Reset. Per il gioco "vero" da consegnare, rimettilo a 1.

   ;*************************************************************************************************************************
   ; VARIABILI
   ;_________________________________________________________________________________________________________________________
   ; _level => livello corrente del gioco
   ; _frame_counter => corrisponde a 60 frame in 1 secondo 
   ; _seconds_counter => secondi
   ;.........................................................................................................................
   ; _playfield_up => parte alta della section
   ; _playfield_down => parte bassa della section 
   ; _playfield_section => sezione del playfield (le sezioni sono 8, vedi schema livelli)
   ;.........................................................................................................................
   ; _choco_count => numero di cioccolatini reuperati dal biscotto (ad ogni livello parte da 0)
   ;.........................................................................................................................
   ; _speed => velocià di attivazione del playfield dinamico e della bocca (parte da 8 e scende di 2 unità al cambio livello)
   ;.........................................................................................................................
   ; i flag (bit) si caratterizzano nel seguente modo: on = 1/off = 0
   ; _b0_enableStart => Game start
   ; _b2_loadPlayfield => Caricamento del playfield dinamico
   ; _b4_enableLight => flag per apire se lo stato della luce
   ; _b5_enablePalyer1 => Attivazione della bocca
   ; _b6_enableSlowMotion => Opzione lentezza del biscotto
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
   dim _b2_loadPlayfield = k
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
   dim _ammo = u
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
   ; score => punteggio puro. Le munizioni sono separate (_ammo)
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
   ; v1-fix: se arriviamo qui da una partita vera, ridisegniamo tutto
   ; il titolo (altrimenti al primo avvio lo cancellerebbe/duplicherebbe)
   if !_b0_enableStart{0} then goto __skip_gameover_clear
   _b0_enableStart{0} = 0
   missile1y = 200 : _choco_count = 0
   goto __draw_title
__skip_gameover_clear
   _b0_enableStart{0} = 0
   _b4_enableLight{4} = 1

   ; v1-fix: non azzeriamo più il punteggio né lo nascondiamo qui -
   ; resta visibile quello dell'ultima partita nella schermata del
   ; titolo. Si azzera solo quando si preme reset per iniziarne una
   ; nuova (vedi sotto).

   goto __done
   
__main_loop

   ;*************************************************************************************************************************
   ; TIMER
   ;_________________________________________________________________________________________________________________________
   ; E' stato definita una variabile come timer per il controllo degli 
   ; oggetti e le dinamiche del playfield:
   ; _frame_counter = conteggio dei frame => frame_limit(54 al secondo)
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
   if _music_index > 20 then _music_index = 0
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

   ; v1-fix: selettore di livello iniziale con lo switch Select -
   ; 7 scelte (0,2,4,6,8,10,12), indicatore a segmenti nella riga
   ; libera, un pixel nero di distanza tra un segmento e l'altro
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
   ; Il numero di bocche aumenta di 1 ogni 6 livelli (1,2 - poi resta a 2,
   ; ridotto da un massimo di 4 per motivi di spazio ROM). Ognuna ha una
   ; posizione propria che si aggiorna in modo randomico (stessa cadenza
   ; di prima) e un colore proprio dalla tabella "mouthcolors". Un solo
   ; player1 fisico viene riposizionato ad ogni frame sulla bocca virtuale
   ; successiva - troppo veloce per l'occhio, sembrano tutte presenti
   ; insieme.
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

   ; v1-fix: insegue il biscotto invece di muoversi a caso
   if temp3 < player0x then temp3 = temp3 + 1
   if temp3 > player0x then temp3 = temp3 - 1
   if temp4 < player0y then temp4 = temp4 + 1
   if temp4 > player0y then temp4 = temp4 - 1

   ; v1-fix: controlla la posizione NUOVA (dove sta per andare), non
   ; quella vecchia - altrimenti restava incastrata per sempre
   if !_mouthIndex && _level < 5 then temp5=temp3/4 : temp6=temp4/8 : if temp6<>5 && pfread(temp5,temp6) then temp3=_mouth0x : temp4=_mouth0y

   if !_mouthIndex then _mouth0x=temp3 : _mouth0y=temp4
   if _mouthIndex then _mouth1x=temp3 : _mouth1y=temp4
   return
__skip_bocche

   ;*************************************************************************************************************************
   ; ZUCCHERINI (MISSILE1 - inganno dell'occhio)
   ;_________________________________________________________________________________________________________________________
   ; Un solo missile1, riposizionato su una zucchero diverso ad ogni
   ; frame (60 volte al secondo) - troppo veloce perché l'occhio se ne
   ; accorga, sembrano tutti presenti insieme. Le posizioni vengono
   ; dalla matrice "sugar" (8 per livello). Quelle già raccolte vengono
   ; saltate nel giro.
   ;*************************************************************************************************************************
   temp1 = (_level-1)*8

   ; v1-fix: l'hardware registra le collisioni con un frame di
   ; ritardo rispetto a quando spostiamo lo sprite - controllarla PRIMA
   ; di spostarci (usando il bit dello zuccherino mostrato l'ULTIMO
   ; frame, _prevSugarBit) assicura di segnare come raccolto l'indice
   ; giusto, invece di uno vicino per sbaglio (bug: altrimenti quello
   ; giusto non risultava mai preso e continuava a farsi ripescare)
   if collision(player0, missile1) then _choco_bits = _choco_bits | _prevSugarBit : _choco_count=_choco_count+1 : score=score+50 : callmacro sound 12 4 2 : if _prevSugarBit=1 then _hitCooldown=120
   if collision(player0, missile1) && _prevSugarBit=2 then _hasKey=1

   ; avanza all'indice successivo, saltando quelli già raccolti
   for y = 0 to 7
      _sugarIndex = _sugarIndex + 1
      if _sugarIndex > 7 then _sugarIndex = 0
      temp2 = bittable[_sugarIndex]
      if !(_choco_bits & temp2) then goto __sugar_index_ok
   next
   missile1y = 200
   goto __skip_all_sugar

__sugar_index_ok
   temp3 = temp1 + _sugarIndex
   temp3 = sugar[temp3]
   missile1x = (temp3&7)*8+20
   missile1y = (temp3/8)*8+8
   if !_sugarIndex then COLUP1 = $1E
   _prevSugarBit = temp2

__skip_all_sugar

   ;*************************************************************************************************************************
   ; LUCE (PLAYFIELD)
   ;_________________________________________________________________________________________________________________________
   ; dopo 32 secondi la luce si spegne automaticamente per accenderla ci si 
   ; deve posizonare sotto la lamp (dal basso verso l'alto)
   ; !!IMP Cambia il colore del playfield tranne la fascia centrale
   ;*************************************************************************************************************************
   ;>>>> SPEGNIMENTO <<<<
   if _seconds_counter && !(_seconds_counter&31) then _b4_enableLight{4} = 0

   ; v1-fix: temp1 = "mostra i colori normali questo frame" - vero se
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
   ; e la bocca è stata colpita
   ;*************************************************************************************************************************
   temp4 = 1
   if _level > 3 && !_hasKey then temp4 = 0
   if _choco_count = 8 && !_b5_enablePalyer1{5} && temp4 then temp2= _current_object_level+7:ballx = objects[temp2] : bally = 28

   ;*************************************************************************************************************************
   ; PLAYFIELD DIAMICO
   ;_________________________________________________________________________________________________________________________
   ; _playfield_section sezione del playfield
   ; _playfield_up = 0 parte alta della sezione
   ; _playfield_down = 2 parte bassa della sezione
   ;*************************************************************************************************************************
   _current_bit_object = 1 
   _playfield_section = 3
   _playfield_up = 0 ; parte alta
   _playfield_down = 2 ; parte bassa

   ;if _b2_loadPlayfield{2} then goto __skip_oggetti
__loop_objects
   _current_object_level = _level - 1
   _current_object_level = _current_object_level * 8

   if _b2_loadPlayfield{2} then goto __skip_to_dynamic_objects

   if !(objects[_current_object_level]&_current_bit_object) then goto __skip_tazze
   callmacro cup_knife _playfield_section _playfield_down 3 ; TAZZE
__skip_tazze
   temp2 = _current_object_level+2
   if !(objects[temp2]&_current_bit_object) then goto __skip_muri
   callmacro chocolate _playfield_section _playfield_down; MURI
__skip_muri

   ; --- muro spingibile (uno per livello, posizione dinamica) ---
   if _level<5 then goto __skip_pushwall
   temp5 = (player0x-18)/4
   if temp5 = (_pushCol-1) && !joy0right then _pushCol = _pushCol+1
   if temp5 = (_pushCol+5) && !joy0left then _pushCol = _pushCol-1
   if _pushCol>24 then _pushCol=24
   o = _playfield_down + 2
   pfvline _pushCol _playfield_down o on
   u = _pushCol + 4
   o = _playfield_down - 2
   pfvline u o _playfield_down on
__skip_pushwall

   ; !!! SALVA LA POSIZONE DELLE LAMPADE PER IL DISCORSO DI ATTIVAZIONE E DISATTIVAZIONE
   temp2 = _current_object_level+ 4
   if !(objects[temp2]&_current_bit_object) then goto __skip_lampade
   callmacro lamp _playfield_section _playfield_up ; LAMPADE
__skip_lampade
   temp2 = _current_object_level+ 5
   if !(objects[temp2]&_current_bit_object) then goto __skip_tavoli
   callmacro table _playfield_section _playfield_down ; TAVOLO+SEDIA
__skip_tavoli
   temp2 = _current_object_level+ 6
   if !(objects[temp2]&_current_bit_object) then goto __skip_piano
   temp4 = objects[temp2]: callmacro divisor temp4; PIANO
__skip_piano

__skip_to_dynamic_objects
   temp2 = _current_object_level+3
   if !(objects[temp2]&_current_bit_object) then goto __skip_gocce
   callmacro choco_drops _playfield_section; GOCCE
__skip_gocce

   _current_bit_object = _current_bit_object * 2
   _playfield_section = _playfield_section + 7
   
   if !_playfield_up && _current_bit_object = 16 then _playfield_section = 3 : _playfield_up = 6 : _playfield_down = 8
   if _current_bit_object then goto __loop_objects
   _b2_loadPlayfield{2} = 1
__skip_oggetti

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
   ; 8) il lancio dei cioccolatini è disabilitato se non ho più scorte o sono in slow motion
   ; 9) aumenta la dimensione della bocca dopo il livello 6 e dopo il livello 12
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

   if !joy0up && !joy0down && !joy0left && !joy0right then goto __Skip_Joystick_Precheck

   _BitOp_P0_M0_Dir = _BitOp_P0_M0_Dir & %11110000

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
   if temp6 = 5 && pfread(temp5,temp6) then _b4_enableLight{4}=1 : goto __delete_missile
   if missile0y < _M_Edge_Top || missile0y > _Edge_Bottom then goto __delete_missile
   if missile0x > _Edge_Right || missile0x < _M_Edge_Left then goto __delete_missile

   ;non colpisce nulla
   if !pfread(temp5,temp6) then goto __skip_missile

   ; --- regola semplificata: solo la riga "in cima" di ogni gruppo è
   ; distruttibile, più le colonne specifiche della sedia ---
   q = 0
   if temp6>5 then q=6
   f = q+2
   temp4 = 0
   if temp6=q || temp6=f then temp4=1
   if !temp4 then goto __skip_missile

   ; colpisce il playfield
   if temp5=_pushCol then _pushCol=0
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

   if temp6 < 34 then if pfread(temp6,temp5) then _b6_enableSlowMotion{6} = 1 : goto __skip_left

   temp3 = (player0y-4)/8

   if temp6 < 34 then if pfread(temp6,temp3) then _b6_enableSlowMotion{6} = 1 : goto __skip_left

   if _b6_enableSlowMotion{6} then if (_frame_counter & 3) <> 0 then goto __skip_left
   player0x = player0x - 1 : _Bit2_P0_Dir_Left{2} = 1

__skip_left
   if !joy0right || player0x >= _Edge_Right then goto __skip_right
   
   temp5 = (player0y-1)/8 : temp6 = (player0x-9)/4

   if temp6 < 34 then if pfread(temp6,temp5) then _b6_enableSlowMotion{6} = 1 : goto __skip_right

   temp3 = (player0y-4)/8

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
   ; __delete_mouth => cancella dallo schermo il player 1
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
   if !_b0_enableStart{0} then goto __main_loop

__skip_to_change
   pfscorecolor = $08
   scorecolor=(scorecolor + $10) & $F0
   pfscore1=%11111111
   pfscore2=%10101010
   bally=200
   player0x=10:player0y=64
   _b2_loadPlayfield{2}=0
   _b5_enablePalyer1{5}=1
   _choco_count=0
   _choco_bits=0 : _prevSugarBit=0 : _hasKey=0
   _pushCol=13
   if _level=5 then _b4_enableLight{4}=0
   _seconds_counter = 0
   pfclear

__done
   
   drawscreen
   goto __main_loop

   ;*************************************************************************************************************************
   ; SUDDIVISIONE DEL PLAYFIELD (griglia 4x2, 8 sezioni)
   ;_________________________________________________________________________________________________________________________
   ; b0 | b1 | b2 | b3
   ;----|----|----|---
   ; b4 | b5 | b6 | b7
   ;_________________________________________________________________________________________________________________________
   ;0.TAZZE 1.(inutilizzato, ex-COLTELLI) 2.CIOCCOLATO 3.GOCCE 4.LAMPADE 5.TAVOLI+SEDIA 6.PIANO 7.ballx
   ; LIVELLI (12)

   data objects

   %00000000, %00000000, %00000000, %00000000, %00001010, %01111010, %00100010, 18,
   %01111111, %00000000, %00000000, %00000000, %00000000, %00000000, %00101011, 136,
   %00000000, %00000000, %00110111, %00000000, %00000000, %00000000, %00001011, 18,
   %00000000, %00000000, %10101010, %01010101, %00000000, %00000000, %00101011, 136,
   %11000000, %00000000, %00000011, %00001100, %00010000, %00110000, %00101011, 18,
end

   ;*************************************************************************************************************************
   ; MUSICHE
   ;_________________________________________________________________________________________________________________________
   ; jingle => allegra
   ; melody => suspance
   ;_________________________________________________________________________________________________________________________
   ;*************************************************************************************************************************
   data mouthcolors
   $48, $6A
end

   data bittable
   1, 2, 4, 8, 16, 32, 64, 128
end

   ;*************************************************************************************************************************
   ; POSIZIONI FISSE DEGLI ZUCCHERINI
   ;_________________________________________________________________________________________________________________________
   ; Griglia 8 colonne x 8 righe (indici 0-63). 8 valori per livello (18
   ; livelli). indice = riga*8 + colonna (es. 15 = riga 1, colonna 7)
   ; Valori 32-39 (riga 4) esclusi apposta: cadrebbero sul muro
   ; divisorio centrale (PIANO).
   ;*************************************************************************************************************************
   data sugar

   0, 10, 18, 24, 34, 42, 48, 56,
   0, 8, 16, 24, 34, 40, 50, 58,
   7, 8, 17, 24, 33, 40, 48, 61,
   1, 9, 18, 30, 39, 40, 48, 57,
   0, 8, 18, 31, 38, 40, 48, 56,
end

   data jingle
   30, 28, 26, 24, 22, 20, 18, 16, 18, 20, 22, 24, 26, 28, 30, 28, 26, 24, 22, 20
end
   data melody
   16, 18, 16, 20, 18, 20, 22, 20, 18, 16, 18, 20, 22, 20, 18, 16, 18, 16, 20, 22
end

   macro cup_knife
      temp5 = {2} + {3} -1
      temp6 = {1} + 4
      ;TAZZA
      for y = {2} to temp5
         pfhline {1} y temp6 on
      next
      ;MANICO
      pfpixel temp6 temp5 off
end


   macro choco_drops
      y = _frame_counter/8
      y = y + {1}
      y = y&3
      y = y + _playfield_up
      pfpixel {1} y flip
end

   macro chocolate
      o = {2} + 2
      pfvline {1} {2} o on
      u = {1} + 4
      o = {2} -2
      pfvline u o {2} on
end

   macro lamp
      o = {1} + 2
      u = {2} + 1
      pfhline {1} {2} o on
      o = o - 1
      pfpixel o u on 
end

   macro table
      o = {1} + 2
      u = {2} + 1
      ;piano del tavolo
      pfhline {1} u o on
      u = u + 1
      ;gambe
      pfpixel {1} u on : pfpixel o u on
      ; sedia
      o = o + 2
      pfpixel o u on
end

   macro divisor
   o = 1
   f = 0
   q = 7
   for u = 0 to 6
      if ({1} & o) <> 0 then pfhline f 5 q on
      o = o * 2
      f = f + 4
      q = f + 4
   next
end

   macro sound
   AUDV1 = {1}
   AUDF1 = {3}
end 