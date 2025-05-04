   ;*************************************************
   ; SETTAGGIO DEL KERNEL E OPZIONI
   ; ------------------------------------------------
   ; kernel_options :
   ; player0colors = colorazione del player 1
   ; pfcolors = colorazione del playfiled
   ; pfheights = altezza del righe del playfield
   ; romsize = 4k, 8k (2 banchi di memoria)
   ; pal  = Versione dei colori... NON FUNZIONA???
   ; tv = effetto crt (non necessario)
   set kernel_options pfcolors
   set romsize 4k
   set pal

   ;*************************************************************************
   ; COSTANTI KERNEL
   ; ------------------------------------------------------------------------
   ; pfscore = abilitazione dello score
   ;*************************************************************************
   const pfscore = 1

   ; limite dei bordi (suponendo un player di 8 pixel)
   const _P_Edge_Top = 8
   const _Edge_Bottom = 88
   const _P_Edge_Left = 10
   const _Edge_Right = 145

   const _M_Edge_Top = 2
   const _M_Edge_Left = 2

   const _base_color = $16
   const _P0_color = $2C
   const _P1_color = $30
   const frame_limit = 54

   ;*************************************************************************
   ; VARIABILI
   ; ------------------------------------------------------------------------
   ; level -> b (1 = cucina, ...4 = ...)
   ; _frame_counter -> c => corrisponde a 60 frame in 1 secondo 
   ; _seconds_counter -> => contatore dei secondi
   ; score -> l
   ; ........................................................................
   ; anination: posizone del player in movimento
   ; ........................................................................
   ; _b0_gameStart -> k (b0 = Game start/stop)
   ; _b4_gameLight -> k (b1 = Light on/off)
   ; _b5_gameWallOrRain -> k (b5 = 0 Wall / 1 Rain)
   ; _b6_palyerslowMotion -> k (b6 = 0 Non attivo / 1 Attivo)
   ;*************************************************************************

   ; level
   dim _level = b

   ; timer
   dim _frame_counter  = c
   dim _seconds_counter  = d


   dim _current_object_level = n

   ; questa variabile è usata per capire quanti "zuccheri" sono stati colpiti
   ; riparte da 0 ad ogni cambio schema/livello
   dim _sugar_count = t
   dim _current_sugar_x = v
   dim _current_sugar_y = z

   dim _speed = g
   dim _current_lamp = w

   ; FLAG DI CONFIGURAZIONE
   dim _b0_gameStart = k
   dim _b4_gameLight = k
   dim _b5_palyer1Enable = k
   dim _b6_palyerslowMotion = k
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

__inizialize
   ;*************************************************************************
   ; INIZIALIZZAZIONE
   ; ------------------------------------------------------------------------
   ; CTRLPF = P dimensione della palla e F posizione del palyfield rispett
   ; NUSIZ(0/1) = dimesione missile + dimensione player (0/1)
   ; REFP0  = Reflection Player 0
   ; COLUP(0/1) = Colore del Player (0/1)
   ; COLUBK = Colore background
   ;*************************************************************************
   ; SCORE e LIVES
   ; ------------------------------------------------------------------------
   ; pfscore1 => timer
   ; pfscore2 => lives
   ;*************************************************************************
   REFP0 = 0
   AUDV1 = 12

   ; Altezze oggeti base
   missile0height = 4 
   missile1height = 2
   ballheight = 2

   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 3 : h = 3 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0

   ; Impostazione del timer iniziale e delle vite
   pfscore1 = %11111111 : pfscore2 = %10101010

   ;*************************************************************************
   ; POSIZIONI PLAYER AND SPRITE INIZIALI
   ;*************************************************************************
   player0x = 30 : player0y = 54 
   ballx = 200   : bally = 200

__game_start
   _b0_gameStart{0} = 0 ; Gioco non attivo
   _b4_gameLight{4} = 1 ; Luci accese di default
   _b5_palyer1Enable{5} = 1
   _level = 1
   _speed = 8
   _current_sugar_x = 146 : _current_sugar_y  = 146
   score = 1000000

   ;Per evitare che si veda nella schermata di presentazione
   scorecolor = 0

   _Bit3_P0_Dir_Right{3} = 1

   ;*************************************************
   ; PLAYFIELD: TITOLO
   ; ------------------------------------------------
   ; E' visibile solo dalla riga 1 alla riga 11
   ; Snack 'n' Roll
   ; pfcolors => varaiazioni di marrone da $22 a $2B
   ;*************************************************
   playfield:
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
   ...X...X.......X.....XX..X.X....
end
   pfcolors:
   $22
   $24
   $26
   $28
   $2A
   $22
   $24
   $26
   $28
   $2A
   $2B
end
   goto __skip_to_draw_playfield
   
__main_loop
   COLUP1 = _P1_color ; TO DO DEVE SPEGNERA ANCHE BOCCA E ZUCCHERI
   COLUP0 = _P0_color 
   NUSIZ1 = $20
   CTRLPF = $21
  
   ;Se premo select inizializzo il gioco
   if switchreset && !_b0_gameStart{0} then _b0_gameStart{0} = 1 : scorecolor = _base_color : pfscorecolor = _base_color :goto __clean_playfield
   if switchselect && !_b0_gameStart{0} then _level = _level + 1 : pfhline 0 6 _level on : goto __skip_to_draw_playfield

   ;Se il gioco non è ancora iniziato skippa tutto e disegna solo il playfield
   if !_b0_gameStart{0} then goto __skip_to_draw_playfield

   ;!!!!!!!!!!!!!!!!!!! START
   if _frame_counter&7 then AUDV0 = 0 : AUDV1 = 0
   if _frame_counter>32 && _b6_palyerslowMotion{6} then AUDF0 = 30 : AUDC0 = 6: AUDV0 = 4

   ;*************************************************************************
   ; TIMER
   ;_________________________________________________________________________
   ; E' stato definita una variabile come timer per il controllo degli 
   ; oggetti e le dinamiche del playfield:
   ; _frame_counter = conteggio dei frame => frame_limit(54 al secondo)
   ; _seconds_counter = conteggio dei secondi
   ;*************************************************************************
   _frame_counter = _frame_counter + 1
   if _frame_counter > frame_limit then _frame_counter = 0 : _seconds_counter = _seconds_counter + 1

   ;*************************************************************************
   ; BOCCA (PLAYER1)
   ;_________________________________________________________________________
   ; La bocca si muove all'interno del playfield in modo randomico, 
   ; l'aggiornamento viene in base alla velocità dello schema di gioco
   ; (inizialmente 8 secondi)
   ;*************************************************************************
   temp1=_speed-1
   if _frame_counter = 0 && _seconds_counter&temp1= 1&& _b5_palyer1Enable{5} then player1x = (rand & 125) + 20 : player1y = (rand & 80) + 8

   ;*************************************************************************
   ; ZUCCHERO (MISSILE1)
   ;_________________________________________________________________________
   ; Gli zuccheri nel playfield sono 8 e verranno visualizzati uno alla volta
   ; Il player una volta che viene a contatto con lo zucchero aumenta di 10
   ; unità degli spari
   ; !!!!IMPORTANTE distruggere il missile dopo il contatto che si ottiene
   ; facendolo sparire dallo schermo missile1x = 255 e missile1y = 255
   ;*************************************************************************
   if _current_sugar_x = 146 || _seconds_counter&7= 1 then _current_sugar_x = (rand & 125) + 20 : _current_sugar_y = (rand & 80) + 8
   if _sugar_count < 8 && _current_sugar_x < 146 then missile1x = _current_sugar_x: missile1y = _current_sugar_y
   if collision(player0, missile1) then AUDV1=12 : AUDC1 = 4 : AUDF1 = 2 :missile1x = 255 : missile1y = 255 : _sugar_count = _sugar_count + 1 : score = score + 100000 : _current_sugar_x = 146

   ;*************************************************************************
   ; LUCE (PLAYFIELD)
   ;_________________________________________________________________________
   ; dopo 32 secondi la luce si spegne automaticamente per accenderla ci si 
   ; deve posizonare sotto la lampada (dal basso verso l'alto)
   ; !!IMP Cambia il colore del playfield tranne la fascia centrale
   ;*************************************************************************
   ;>>>> SPEGNIMENTO <<<<
   if _seconds_counter > 0 && _seconds_counter&31 = 0 then _b4_gameLight{4} = 0

   ;>>>> ACCENSIONE <<<<
   ; TO DO VEDO AGGIUNGERE LA POSIONE DI __current_lamp ad X (es.: %10010000, due lampade alla posizone 128 e 16)
   temp5 = (player0x-10)/4
   temp6 = (player0y-5)/8
   if !_b4_gameLight{4} && temp5 = _current_lamp then _b4_gameLight{4} = 1

   ;Background visibile
   if _b4_gameLight{4} then pfcolors:
   $28
   $26
   $20
   $22
   $20
   $02
   $05
   $9E
   $0E
   $24
   $26
end

   ; Background
   if !_b4_gameLight{4} then pfcolors:
   $0
end

   ;*************************************************************************
   ; SLOW MOTION 
   ;_________________________________________________________________________
   ; dopo 8 secondi si disattiva lo slow motion
   ;*************************************************************************
   if _seconds_counter&7 = 0 then _b6_palyerslowMotion{6} = 0

   ;*************************************************************************
   ; CONTENITORE FINALE (BALL)
   ;_________________________________________________________________________
   ; il sacchetto finale individuato come ball viene visualizzato solo dopo
   ; aver trovato gli 8 zuccherini nel playfield
   ;*************************************************************************
   if _frame_counter = frame_limit && _sugar_count = 8 && !_b5_palyer1Enable{5} then ballx = 18  : bally = 18

   ;*************************************************************************
   ; PLAYFIELD DIAMICO
   ;_________________________________________________________________________
   ;*************************************************************************

   temp5 = 1 
   x = 0
   w = 0 ; parte alta
   j = 2 ; parte bassa
   temp3 = w
__loop_objects
   temp1 = _speed - 1
   _current_object_level = (_level - 1) * 8
   if (_seconds_counter&temp1) = 0 && _frame_counter = x && (objects[_current_object_level]&temp5)> 0 then callmacro tazze_coltelli x j 3 ; TAZZE
   temp2 = _current_object_level +1
   if (_seconds_counter&temp1) = 0 && _frame_counter = (x+1) && (objects[temp2]&temp5)> 0 then callmacro tazze_coltelli x w 2 ; COLTELLI
   temp2 = _current_object_level+2
   if (_seconds_counter&temp1) = 0 && _frame_counter = (x+2) && (objects[temp2]&temp5)> 0 then callmacro cioccolato x j; MURI
   temp2 = _current_object_level+3
   if (_seconds_counter&temp1) = 0 && _frame_counter = (x+3) && (objects[temp2]&temp5)> 0 then callmacro gocce x w; GOCCE
   
   ; !!! SALVA LA POSIZONE DELLE LAMPADE PER IL DISCORSO DI ATTIVAZIONE E DISATTIVAZIONE
   temp2 = _current_object_level+ 4
   if (_seconds_counter&temp1) = 0 && _frame_counter = (x+4) && (objects[temp2]&temp5)> 0 then callmacro lampada x w : _current_lamp = x; LAMPADE
   temp2 = _current_object_level+ 5
   if (_seconds_counter&temp1) = 0 && _frame_counter = (x+5) && (objects[temp2]&temp5)> 0 then callmacro tavolo x j ; TAVOLI
   /*temp2 = _current_object_level+ 6
    if (_seconds_counter&temp1) = 0 && _frame_counter = (x+6) && (objects[temp2]&temp5)> 0 then callmacro arrivo x w ; TRAGUARDO
   */
   temp2 = _current_object_level+ 7
   if (_seconds_counter&temp1) = 0 && _frame_counter = (x+7) && (objects[temp2]&temp5)> 0 then temp4 = objects[temp2]: callmacro piano temp4; PIANO
   temp5 = temp5 * 2
   x = x + 7
   
   if temp5 = 16 && w = 0 then x = 0 : w = 6 : j = 8 : temp3 = w
   if temp5 > 0 then goto __loop_objects

__skip_oggetti

   ;*************************************************************************
   ; CHECK
   ;_________________________________________________________________________
   ; 1) ogni 16 secondi elimina uno spazio tempo
   ; 2) se lo spazio tempo è finito elimina una health
   ; 3) se non ci sono più health allora il gioco è completato o terminato
   ; 4) lampeggio in scadenza del tempo ogni frame_limit
   ;*************************************************************************

   ; ---- 4 ---- (TO DO)
   ;if _frame_counter=frame_limit && pfscore1 <=8  then COLUBK = _frame_counter & 32 : COLUBK = rand&16

   ; ---- 1 ----
   if _frame_counter = 0 && _seconds_counter & 15 = 0 then goto __decrease_timer_bar
   ; ---- 2 ----
   if pfscore1 = 0 then goto __decrease_health_bar
   ; ---- 3 ----
   if pfscore2 = 0 || _level = 10 then goto __game_over


   if !joy0up && !joy0down && !joy0left && !joy0right then goto __Skip_Joystick_Precheck
   
   _BitOp_P0_M0_Dir = _BitOp_P0_M0_Dir & %11110000

__Skip_Joystick_Precheck


   if !joy0fire || score <= 0 then goto __Skip_Fire
   if _b7_gameMissile0Moving{7} then goto __Skip_Fire

   _b7_gameMissile0Moving{7} = 1 : score = score - 10000
   AUDV1 = 12 :  AUDC1 = 4 : AUDF1 = 10 
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

   ;***************************************************************
   ;
   ;  Missile0 movement check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if missile0 isn't moving.
   ;
   if !_b7_gameMissile0Moving{7} then goto __Skip_Missile

   ;```````````````````````````````````````````````````````````````
   ;  Moves missile0 in the appropriate direction and gets
   ;  coordinates for pfpixel check.
   ;
   if _Bit4_M0_Dir_Up{4} then missile0y = missile0y - 2 : temp5 = (missile0x-18)/4 : temp6 = (missile0y-1)/8
   if _Bit5_M0_Dir_Down{5} then missile0y = missile0y + 2 : temp5 = (missile0x-18)/4 : temp6 = (missile0y)/8
   if _Bit6_M0_Dir_Left{6} then missile0x = missile0x - 2 : temp5 = (missile0x-18)/4 : temp6 = (missile0y-1)/8
   if _Bit7_M0_Dir_Right{7} then missile0x = missile0x + 2 : temp5 = (missile0x-18)/4 : temp6 = (missile0y-1)/8

   ;```````````````````````````````````````````````````````````````
   ;  Clears missile0 if it hits the edge of the screen.
   ;
   if missile0y < _M_Edge_Top then goto __Delete_Missile
   if missile0y > _Edge_Bottom then goto __Delete_Missile
   if missile0x < _M_Edge_Left then goto __Delete_Missile
   if missile0x > _Edge_Right then goto __Delete_Missile

   ;```````````````````````````````````````````````````````````````
   ;  Skips rest of section if no pfpixel shot.
   ;
   if !pfread(temp5,temp6) then goto __Skip_Missile

   ;```````````````````````````````````````````````````````````````
   ;  Deletes pfpixel.
   ;
   ;if objects[5] & 4 = 0 then goto __Delete_Missile
   if temp6 = 5 then goto __Delete_Missile
   ;if temp6 > 5 then goto __Delete_Missile
   pfpixel temp5 temp6 off : score = score + 1

__Delete_Missile

   _b7_gameMissile0Moving{7} = 0 : missile0x = 200 : missile0y = 200

__Skip_Missile

 
   ;*************************************************************************
   ; ANIMAZIONE PLAYER 0
   ; ------------------------------------------------------------------------
   ; solo se sto muovendo il joystick
   ;*************************************************************************
   if !joy0right && !joy0left && !joy0up && !joy0down && _seconds_counter then goto __skip_animation_player0

   ;*************************************************************************
   ; ANIMAZIONE PLAYER
   ;_________________________________________________________________________
   ; player 0 -> Biscotto => 8 x 4 pixel
   ; player 1 -> Bocca che mangia => 8 x 4 pixel
   ;*************************************************************************
   if _frame_counter && _frame_counter & 7 = 0 then player0:
   %00011000
   %10111101
   %01011010
   %01111110
end

   if _frame_counter  && _frame_counter & 7 <> 0 then player0:
   %00100100
   %10111101
   %01011010
   %01111110
end

__skip_animation_player0

   if _frame_counter & 8 = 0 then player1:
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
   if !_b0_gameStart{0} then goto __skip_to_draw_playfield


   ;***************************************************************
   ;
   ;  Joy0 up check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick isn't moved up.
   ;
   if !joy0up then goto __Skip_Joy0_Up

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if hitting the edge.
   ;
   if player0y <= _P_Edge_Top then goto __Skip_Joy0_Up

   ;```````````````````````````````````````````````````````````````
   ;  Stops movement if a playfield pixel is in the way.
   ;
   temp5 = (player0x-10)/4

   temp6 = (player0y-5)/8

   if temp5 < 34 then if pfread(temp5,temp6) then _b6_palyerslowMotion{6} =1 :goto __Skip_Joy0_Up

   temp4 = (player0x-17)/4

   if temp4 < 34 then if pfread(temp4,temp6) then _b6_palyerslowMotion{6} =1 :goto __Skip_Joy0_Up

   temp3 = temp5 - 1

   if temp3 < 34 then if pfread(temp3,temp6) then _b6_palyerslowMotion{6} =1 :goto __Skip_Joy0_Up

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 up.
   ;
   if _b6_palyerslowMotion{6} then if (_frame_counter & 3) = 0 then player0y = player0y - 1
   if !_b6_palyerslowMotion{6} then player0y = player0y - 1 
   _Bit0_P0_Dir_Up{0} = 1

__Skip_Joy0_Up

   ;***************************************************************
   ;
   ;  Joy0 down check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick isn't moved down.
   ;
   if !joy0down then goto __Skip_Joy0_Down

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if hitting the edge.
   ;
   if player0y >= _Edge_Bottom then goto __Skip_Joy0_Down

   ;```````````````````````````````````````````````````````````````
   ;  Stops movement if a playfield pixel is in the way.
   ;
   temp5 = (player0x-10)/4

   temp6 = (player0y)/8

   if temp5 < 34 then if pfread(temp5,temp6) then _b6_palyerslowMotion{6} = 1 :goto __Skip_Joy0_Down

   temp4 = (player0x-17)/4

   if temp4 < 34 then if pfread(temp4,temp6) then _b6_palyerslowMotion{6} = 1 :goto __Skip_Joy0_Down

   temp3 = temp5 - 1

   if temp3 < 34 then if pfread(temp3,temp6) then _b6_palyerslowMotion{6} = 1 :goto __Skip_Joy0_Down

   if _b6_palyerslowMotion{6} then if (_frame_counter & 3) = 0 then player0y = player0y + 1
   if !_b6_palyerslowMotion{6} then player0y = player0y + 1 


   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 down.
   ;
   _Bit1_P0_Dir_Down{1} = 1


__Skip_Joy0_Down

   ;***************************************************************
   ;
   ;  Joy0 left check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick isn't moved to the left.
   ;
   if !joy0left then goto __Skip_Joy0_Left

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if hitting the edge.
   ;
   if player0x <= _P_Edge_Left then goto __Skip_Joy0_Left

   ;```````````````````````````````````````````````````````````````
   ;  Stops movement if a playfield pixel is in the way.
   ;
   temp5 = (player0y-1)/8

   temp6 = (player0x-18)/4

   if temp6 < 34 then if pfread(temp6,temp5) then _b6_palyerslowMotion{6} = 1 : goto __Skip_Joy0_Left

   temp3 = (player0y-4)/8

   if temp6 < 34 then if pfread(temp6,temp3) then _b6_palyerslowMotion{6} = 1 : goto __Skip_Joy0_Left

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 left.
   ;
   if _b6_palyerslowMotion{6} then if (_frame_counter & 3) = 0 then player0x = player0x - 1
   if !_b6_palyerslowMotion{6} then player0x = player0x - 1 

   _Bit2_P0_Dir_Left{2} = 1

__Skip_Joy0_Left

   ;***************************************************************
   ;
   ;  Joy0 right check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick isn't moved to the right.
   ;
   if !joy0right then goto __Skip_Joy0_Right

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if hitting the edge.
   ;
   if player0x >= _Edge_Right then goto __Skip_Joy0_Right

   ;```````````````````````````````````````````````````````````````
   ;  Stops movement if a playfield pixel is in the way.
   ;
   temp5 = (player0y-1)/8

   temp6 = (player0x-9)/4

   if temp6 < 34 then if pfread(temp6,temp5) then _b6_palyerslowMotion{6} = 1 : goto __Skip_Joy0_Right

   temp3 = (player0y-4)/8

   if temp6 < 34 then if pfread(temp6,temp3) then _b6_palyerslowMotion{6} = 1 : goto __Skip_Joy0_Right

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 right.
   ;
   if _b6_palyerslowMotion{6} then if (_frame_counter & 3) = 0 then player0x = player0x + 1
   if !_b6_palyerslowMotion{6} then player0x = player0x + 1 

   _Bit3_P0_Dir_Right{3} = 1
__Skip_Joy0_Right

   ;*************************************************************************
   ; COLLISIONI 
   ;_________________________________________________________________________
   ; tra Biscotto e Bocca: decremento la barra della salute
   ; tra Missile e Bocca: incremento dei punti di 10 unità
   ; tra Biscotto e Zucchero : incremento dei punti e individuazione del
   ; prossimo zucchero da prendere
   ;*************************************************************************   
   if collision(player0, player1) && _frame_counter = 0 then goto __decrease_health_bar
   if collision(missile0, player1) then score = score + 10 : _b5_palyer1Enable{5} = 0 : player1x = 255 : player1y : 255
   if collision(player0, ball) then goto __change_level
   ;if collision(player0, missile1) && _sugar_count <= 8 then _sugar_count = _sugar_count + 1 : goto __increment_score
   goto __done

__decrease_timer_bar
   player1x = 200 : player1y = 200
   pfscore1 = pfscore1 * 2
   goto __done

__decrease_health_bar
   pfscore2 = pfscore2 / 4
   score = score - 1
   if pfscore2 = 0 then __game_over
   pfscore1 = 255 : _sugar_count = 0
   goto __done

__change_level
   score = score + 100 
   _level = _level + 1
   if _level > 10 then goto __game_start
   _sugar_count = 0
   if _speed < 2 then _speed = 2
   _speed = _speed - 2
   ballx = 200 : bally = 200
   player0x = 30 : player0y = 54 
   AUDV1 = 12
   AUDC1 = 6
   AUDF1 = 2 
   _b5_palyer1Enable{5} = 1
   goto __clean_playfield

__done
   goto __skip_to_draw_playfield

__game_over
   _b0_gameStart{0} = 0
   goto __skip_to_draw_playfield

__clean_playfield

   pfclear 

__skip_to_draw_playfield
   
   drawscreen
   goto __main_loop

   ;=======================================================================
   ; b0 : b1 : b2 : b3
   ;::::::::::::::::::
   ; b4 : b5 : b6 : b7
   ;=======================================================================

   ;0.TAZZE   1.COLTELLI 2.CIOCCOLATO 3.GOCCE    4.LAMPADE  5.TAVOLI   6.TRAGUARDO 7.PIANO
   ; LIVELLI (10)
   data objects
   %01000010, %00000000, %00000000,   %00000001, %00010000, %10100000, %00000000,  %00000111, 
   %01000010, %00000000, %00000000,   %00000000, %00010000, %10100000, %00000000,  %00000111,    
   %01000010, %00000000, %00000000,   %00000000, %00010000, %10100000, %00000000,  %00000111, 
   %01000010, %00000000, %00000000,   %00000000, %00010000, %10100000, %00000000,  %00000111, 
   %01000010, %00000000, %00000000,   %00000000, %00010000, %10100000, %00000000,  %00000111, 
   %01000010, %00000000, %00000000,   %00000000, %00010000, %10100000, %00000000,  %00000111
   ;%01000010, %00000000, %00000000,   %00000000, %00010000, %10100000, %00000000,  %00000111
   ;%01000010, %00000000, %00000000,   %00000000, %00010000, %10100000, %00000000,  %00000111;,
   ;%01000010, %00000000, %00000000,   %00000000, %00010000, %10100000, %00000000,  %00000111,
   ;%01000010, %00000000, %00000000,   %00000000, %00010000, %10100000, %00000000,  %00000111
   
end
   macro tazze_coltelli
      temp5 = {2} + {3} -1
      temp6 = {1} + 4
      ;TAZZA
      for y = {2} to temp5
         pfhline {1} y temp6 on
      next
      ;MANICO
      pfpixel temp6 temp5 off ; manico
end

   macro gocce
      ;u = rand&2
      o = rand&3
      y = {2} + o
      /* pfpixel {1} {2} off
      o = {2} + 1 */
      pfpixel {1} o flip
end

   macro cioccolato
      u = {1}
      o = {2} + 2
      ;BARRETTA
      pfvline u {2} o on
      u = {1} + 4
      o = {2} -2
      ;PEZZETTINO
      pfpixel u o on
end

   /* macro arrivo
      u = {1} + 3
      o = {2} + 4
      pfvline u {2} o on
end */

   macro lampada
      o = {1} + 2
      u = {2} + 1
      pfhline {1} {2} o on
      o = o - 1
      pfpixel o u on 
end

   macro tavolo
      o = {1} + 2
      u = {2} + 1
      ;TAVOLO
      pfhline {1} u o on 
      u = u + 1
      pfpixel {1} u on : pfpixel o u on
      ; SEDIA
      o = o + 2
      pfpixel o u on 
end

   macro piano
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