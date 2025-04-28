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

   ;****************************************************************
   ;
   ;  Some multiplication operations require you to include
   ;  a module.
   ;
   ;include div_mul.asm

   ;*************************************************************************
   ; COSTANTI KERNEL
   ; ------------------------------------------------------------------------
   ; pfscore = abilitazione dello score
   ; scorefade = effetto fade nello score
   ;*************************************************************************
   const pfscore = 1
   const scorefade = 1
   ;const pfrowheight=6
   ;const noscore = 1

   ; limite dei bordi (suponendo un player di 8 pixel)
   const _P_Edge_Top = 0
   const _P_Edge_Bottom = 88 ; 11 X 8 ???
   const _P_Edge_Left = 10
   const _P_Edge_Right = 145

   const _M_Edge_Top = 2
   const _M_Edge_Bottom = 88
   const _M_Edge_Left = 2
   const _M_Edge_Right = 145

   ;colori di default
   const _base_color = $16
   const _P0_color = $2C
   const _P1_color = $36
   
   const frame_limit = 54
   ;*************************************************************************
   ; VARIABILI
   ; ------------------------------------------------------------------------
   ; level -> b (1 = cucina, ...4 = ...)
   ; frame_counter -> c => corrisponde a 60 frame in 1 secondo 
   ; seconds_counter -> => contatore dei secondi
   ; score -> l
   ; ........................................................................
   ; anination: posizone del player in movimento
   ; ........................................................................
   ; _b0_gameStart -> k (b0 = Game start/stop)
   ; _b4_gameLight -> k (b1 = Light on/off)
   ; _b5_gameWallOrRain -> k (b5 = 0 Wall / 1 Rain)
   ; _b6_palyerslowMotion -> k (b6 = 0 Non attivo / 1 Attivo)
   ;*************************************************************************
   ;dim _SC_Back = w
   dim speedx = i
   dim speedy = q
   dim _level = b
   dim frame_counter  = c
   dim seconds_counter  = d

   dim _animation = f

   ; questa variabile è usata per capire quanti "zuccheri" sono stati colpiti
   ; riparte da 0 ad ogni cambio schema/livello
   dim sugar_count = t
   dim current_sugar = v

   dim _velocita = g

   dim shoot = l

   ;```````````````````````````````````````````````````````````````
   ;  Converted ball coordinates for playfield.
   ;
   dim _pf_x = n
   dim _pf_y = o


   dim _b0_gameStart = k
   dim _b4_gameLight = k
   dim _b5_gameWallOrRain = k
   dim _b6_palyerslowMotion = k
   dim _b7_gameMissile0Moving = k



   dim _BitOp_P0_M0_Dir = p
   dim _Bit0_P0_Dir_Up = p
   dim _Bit1_P0_Dir_Down = p
   dim _Bit2_P0_Dir_Left = p
   dim _Bit3_P0_Dir_Right = p
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
   ; SCORE AND LIVES
   ; ------------------------------------------------------------------------
   ; pfscore1 => timer
   ; pfscore2 => energy
   ;*************************************************************************
   REFP0 = 0

   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 3 : h = 3 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0

   pfscore1 = %11111111 : pfscore2 = %10101010

   ;*************************************************************************
   ; POSIZIONI PLAYER AND SPRITE INIZIALI
   ;*************************************************************************
   player0x = 30 : player0y = 54 : player1y = 0 : player1x = 1 : ballx = 18 :bally = 18

__startGame
   _b0_gameStart{0} = 0 ; Gioco non attivo
   _b4_gameLight{4} = 1 ; Luci accese di default
   _b5_gameWallOrRain{5} = 0 ; Wall attivo
   _level = 1
   _animation = 0
   speedx = 1: speedy = 1

   _velocita = 8


   ;Per evitare che si veda nella schermata di presentazione
   scorecolor = 255
   pfscorecolor = $0

   ; non si vedono
   ;missile0y = 222
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
   /* pfheights:
   4
   4
   4
   4
   8
   8
   4
   2
   2
   2
   8
end */
      goto __skip_to_draw_playfield
   
__main_loop
   COLUP1 = _P1_color 
   COLUP0 = _P0_color 
   NUSIZ1 = $20
   ;COLUBK = 0 
   ;Se premo select inizializzo il gioco
   if switchreset && !_b0_gameStart{0} then _b0_gameStart{0} = 1 : pfscorecolor = _base_color :goto __playfield
   ;if switchselect && !_b0_gameStart{0} then _level = _level + 1 : goto __playfield

   ;Se il gioco non è ancora iniziato skippa tutto e disegna solo il playfield
   if !_b0_gameStart{0} then goto __skip_to_draw_playfield

   ;!!!!!!!!!!!!!!!!!!! START

   ;*************************************************************************
   ; TIMER
   ;_________________________________________________________________________
   ; E' stato definito un solo timer per il controllo degli oggetti e
   ; playfield:
   ; frame_counter = 0 a frame_limit(54) (circa 54 frame al secondo)
   ; seconds_counter = 1 a ...
   ;*************************************************************************
   frame_counter = frame_counter + 1
   if frame_counter > frame_limit then frame_counter = 0 : seconds_counter = seconds_counter + 1

   ;*************************************************************************
   ; BOCCA (PLAYER1)
   ;_________________________________________________________________________
   ; La bocca si muove su e giù dentro le mura di cioccolato in protezione 
   ; della "pillola" magica, il giocatore è costrattto ad abbattere tutto
   ; il muro di ciccolato per poter accedere alla pillola ma una volta che
   ; sblocca il muro la bocca può uscire ed inseguire il giocatore
   ; Il movimento avviene ogni 2 millisecondi 
   ;-------------------------------------------------------------------------
   ; speedx = può essere da 1 a 2 in modo randomico
   ; speedy = può essere da 1 a 2 in modo randomico
   ;*************************************************************************

   ; >>> ASSE X PRIMA DI MUOVERE <<<
   temp5 = (player1x-10)/4
   if temp5 < 0 then temp5 = 0
   temp6 = (player1y-5)/8
   if temp6 < 0 then temp6 = 0

   if pfread(temp5,temp6) then speedx = 0 - speedx  ; Cambia direzione

   player1x = player1x + speedx  ; SOLO DOPO aggiorna

   ; Check confini schermo
   if player1x <= 18 then speedx = (rand & 1) + 1
   if player1x >= 140 then speedx = 0-((rand & 1) + 1)

   ; >>> ASSE Y PRIMA DI MUOVERE <<<
   temp5 = (player1x-10)/4
   temp6 = (player1y-5)/8
   if temp5 < 0 then temp5 = 0
   if temp6 < 0 then temp6 = 0

   if pfread(temp5,temp6) then speedy = 0 - speedy  ; Cambia direzione

   player1y = player1y + speedy  ; SOLO DOPO aggiorna

   ; Check confini schermo
   if player1y <= 5 then speedy = (rand & 1) + 1
   if player1y >= 40 then speedy = 0-((rand & 1) + 1)

   ;*************************************************************************
   ; ZUCCHERO (MISSILE1)
   ;_________________________________________________________________________
   ; Gli zuccheri nel playfield sono 8 e verranno visualizzati uno alla volta
   ; Il player una volta che viene a contatto con lo zucchero aumenta di una
   ; unità e si passa al prossimo zucchero da catturare
   ; !!!!IMPORTANTE distruggere il missile dopo il contatto che si ottiene
   ; facendolo sparire dallo schermo missile1x = 255 e missile1y = 255
   ;*************************************************************************
   if sugar_count <= 7 && current_sugar = 0 then current_sugar = (rand & 127) +10: missile1x =  current_sugar : missile1y = (rand & 62) + 10
   if collision(player0, missile1) then missile1x = 255 : missile1y = 255 : current_sugar = 0 : sugar_count = sugar_count + 1 : score = score + 160000 : goto __done

   ;*************************************************************************
   ; LUCE (PLAYFIELD)
   ;_________________________________________________________________________
   ; dopo 16 secondi la luce si spegne automaticamente per accenderla ci si 
   ; deve posizonare sotto la lampada (dal basso verso l'alto)
   ; !!IMP Cambia il colore del playfield tranne la fascia centrale
   ;*************************************************************************
   ;>>>> SPEGNIMENTO <<<<
   if seconds_counter && seconds_counter & 30 = 0 then _b4_gameLight{4} = 0

   ;>>>> ACCENSIONE <<<<
   temp5 = (player0x-10)/4
   temp6 = (player0y-5)/8
   if !_b4_gameLight{4} && pfread(temp5,temp6) then _b4_gameLight{4} =  1

   ;*************************************************************************
   ; SLOW MOTION 
   ;_________________________________________________________________________
   ; dopo 8 secondi si disattiva lo slow motion
   if seconds_counter & 7 = 0 then _b6_palyerslowMotion{6} = 0

   ;*************************************************************************
   ; PLAYFIELD
   ;_________________________________________________________________________
   ; RIGA: 0 -> 4 (partono sempre dalla colonna 3)
   ; Gocce di cioccolato:traslazione verticale
   ; Barrette di ciccolato: traslazione orizzontale
   ; RIGA: 7 -> 8
   ; Lama del coltello
   ;*************************************************************************

   ; velocità

   ; TAZZE Livello alto
   /* temp5 = 1
   for x = 0 to 21 step 7 ; massimo 4 iterazioni
      temp5 = temp5 * 2
   next

   ; TAZZE Livello basso
   for x = 0 to 28 step 7
      ;if (seconds_counter & temp4) = 0 && frame_counter = x && objects[0] & temp5 > 0 then callmacro tazze x 8 9 10 3 4 2
      temp5 = temp5 * 2
   next */
   ;temp4 = 0;3 - _level   ; VELOCITA'
   temp5 = 1            ; INDICE PER PIANO SUPERIORE %00001111 : 2^0 = 1  -> 2^1 = 2  -> 2^2 = 4  -> 2^3 = 8
   x = 0
   w = 0 ; parte alta
   j = 2 ; parte bassa
__loop_objects
   temp1 = _velocita - 1
   temp2 = _level -1
   if (seconds_counter&temp1) = 0 && frame_counter = x && (objects[temp2]&temp5)> 0 then callmacro tazze x j 3 ; TAZZE
   temp2 = temp2 + 1
   if (seconds_counter&temp1) = 0 && frame_counter = (x+1) && (objects[temp2]&temp5)> 0 then callmacro tazze x w 2 ; COLTELLI
   temp2 = temp2+ 1
   if (seconds_counter&temp1) = 0 && frame_counter = (x+2) && (objects[temp2]&temp5)> 0 then callmacro chocoWall x j ; MURI
   ; TODO GOCCE

/*   ;============
   ;=  GOCCE   =
   ;============
   if !_b5_gameWallOrRain{5} then goto __skip_rain
   if _level >= 1 then temp3 = (rand&28) + 3 else temp3 = (rand & 9) + 3
   if frame_counter = 10 && _level >=1 then a = temp3 : pfpixel a 0 on
   if frame_counter = 15 && _level >=2 then t = temp3 + 13 : pfpixel t 0 on
   if frame_counter = 20 && _level >=1 then pfpixel a 2 on : pfpixel a 0 off 
   if frame_counter = 25 && _level >=2 then pfpixel t 2 on : pfpixel t 0 off
   if frame_counter = 30 && _level >=1 then pfpixel a 4 on : pfpixel a 2 off 
   if frame_counter = 35 && _level >=2 then pfpixel t 4 on : pfpixel t 2 off
   if frame_counter = 40 && _level >=1 then pfpixel a 4 off 
   if frame_counter = 45 && _level >=2 then pfpixel t 4 off
   */

   temp5 = temp5 * 2
   x = x + 7
   
   if temp5 = 16 && w = 0 then x = 0 : w = 6 : j = 8
   if temp5 > 0 then goto __loop_objects

  ; if (seconds_counter & temp4) = 0 && frame_counter = x && 
   
   ;if objects[temp1] & temp5 > 0 then callmacro tazze x 8 3
   ;if (seconds_counter & temp4) = 0 then if frame_counter+1 = x && temp2 & temp5 > 0 then callmacro tazze x 8 3

   ;temp2 = objects[_level] ; -> Coltelli
   ;if (seconds_counter & temp4) = 0 then if frame_counter = x && temp3 & temp6 > 0 then callmacro tazze x 6 3 if frame_counter = x + 10  && temp3 & temp5 > 0 then callmacro tazze x 0 2

   ;temp1 = _level +1 ; -> Coltelli

   ;Tazze
   /* if (seconds_counter & temp4) = 0 && frame_counter = x && objects[5] & temp6 > 0 then callmacro tazze x 8 3 
   if (seconds_counter & temp4) = 0 && frame_counter = x + 10 && objects[6] & temp6 > 0 then callmacro tazze x 6 2 */

   ;if (seconds_counter & temp4) = 0 && frame_counter = x && objects[0] & temp6 > 0 then callmacro tazze x 8 3
   ;Coltello
   /* if (seconds_counter & temp4) = 0 && frame_counter = x && objects[1] & temp5 > 0 then callmacro tazze x 0 2 
   if (seconds_counter & temp4) = 0 && frame_counter = x && objects[1] & temp6 > 0 then callmacro tazze x 8 2 */

   /* temp4 = objects[1]
   temp5 = 16
   for x = 0 to 28 step 7
      if frame_counter = x && temp4 & temp5 > 0 then callmacro tazze x 6 7 8 5 3 0
      temp5 = temp5 * 2
   next */

   /* ;goto __increment_score
   temp4 = objects[0]
   temp5 = 16
   ; COLTELLI */

__skip_oggetti

/*
   ;============
   ;=  GOCCE   =
   ;============
   if !_b5_gameWallOrRain{5} then goto __skip_rain
   if _level >= 1 then temp3 = (rand&28) + 3 else temp3 = (rand & 9) + 3
   if frame_counter = 10 && _level >=1 then a = temp3 : pfpixel a 0 on
   if frame_counter = 15 && _level >=2 then t = temp3 + 13 : pfpixel t 0 on
   if frame_counter = 20 && _level >=1 then pfpixel a 2 on : pfpixel a 0 off 
   if frame_counter = 25 && _level >=2 then pfpixel t 2 on : pfpixel t 0 off
   if frame_counter = 30 && _level >=1 then pfpixel a 4 on : pfpixel a 2 off 
   if frame_counter = 35 && _level >=2 then pfpixel t 4 on : pfpixel t 2 off
   if frame_counter = 40 && _level >=1 then pfpixel a 4 off 
   if frame_counter = 45 && _level >=2 then pfpixel t 4 off
*/
__skip_rain
/*
   ;============
   ;=CIOCCOLATO=
   ;============
   if _b5_gameWallOrRain{5} then goto __skip_wall
   if wall1 = 3 then callmacro chocoWall wall1 0 : wall1 = 31
   if frame_counter & 31 = 0 && wall1 > 2 then callmacro chocoWall wall1 0
   if frame_counter & 31 = 1 && wall1 > 3 then wall1 = wall1 - 1: callmacro chocoWall wall1 1

   ;=== Muro 2 === (parte quando wall1 arriva a 20)
   if wall2 = 3 then callmacro chocoWall wall2 0 : wall2 = 0
   if wall1 = 20 && wall2 = 0 then wall2 = 31
   if frame_counter & 31 = 0 && wall2 > 2 && _level > 1 then callmacro chocoWall wall2 0
   if frame_counter & 31 = 1 && wall2 > 3 && _level > 1 then wall2 = wall2 - 1 : callmacro chocoWall wall2 1

   macro chocoWall
   if {2} = 1 then pfpixel {1} 2 on : pfpixel {1} 3 on : pfpixel {1} 4 on
   if {2} = 0 then pfpixel {1} 2 off : pfpixel {1} 3 off : pfpixel {1} 4 off
end
*/
__skip_wall


   ;*************************************************************************
   ; CHECK
   ;_________________________________________________________________________
   ; 1) ogni 16 secondi elimina uno spazio tempo
   ; 2) se lo spazio tempo è finito elimina una health
   ; 3) se non ci sono più health allora il gioco è completato o terminato
   ; 4) fire check
   ;*************************************************************************

   if frame_counter = 0 && seconds_counter & 15 = 0 then goto __decrease_timer_bar
   if pfscore1 = 0 then goto __decrease_health_bar
   if pfscore2 = 0 || _level = 10 then goto __gameOver
   if frame_counter&32 && pfscore1<8 then COLUBK = 10 : goto __skip_bck
   COLUBK = 0

__skip_bck

   if !joy0up && !joy0down && !joy0left && !joy0right then goto __Skip_Joystick_Precheck
   
   _BitOp_P0_M0_Dir = _BitOp_P0_M0_Dir & %11110000

__Skip_Joystick_Precheck


   ;***************************************************************
   ;
   ;  Fire button check.
   ;  
   ;  Turns on missile1 movement if fire button is pressed and
   ;  missile1 is not moving.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if the fire button is not pressed.
   ;Se non 
   if !joy0fire || score <= 0 then goto __Skip_Fire

   ;```````````````````````````````````````````````````````````````
   ;  If missile0 is moving, skip this subsection.
   ;
   if _b7_gameMissile0Moving{7} then goto __Skip_Fire

   ;```````````````````````````````````````````````````````````````
   ;  Turns on missile0 movement.
   ;
   _b7_gameMissile0Moving{7} = 1 : score = score - 10000 

   ;```````````````````````````````````````````````````````````````
   ;  Takes a 'snapshot' of player0 direction so missile0 will
   ;  stay on track until it hits something.
   ;
   _Bit4_M0_Dir_Up{4} = _Bit0_P0_Dir_Up{0}
   _Bit5_M0_Dir_Down{5} = _Bit1_P0_Dir_Down{1}
   _Bit6_M0_Dir_Left{6} = _Bit2_P0_Dir_Left{2}
   _Bit7_M0_Dir_Right{7} = _Bit3_P0_Dir_Right{3}

   ;```````````````````````````````````````````````````````````````
   ;  Sets up starting position of missile0.
   ;
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
   if missile0y > _M_Edge_Bottom then goto __Delete_Missile
   if missile0x < _M_Edge_Left then goto __Delete_Missile
   if missile0x > _M_Edge_Right then goto __Delete_Missile

   ;```````````````````````````````````````````````````````````````
   ;  Skips rest of section if no pfpixel shot.
   ;
   if !pfread(temp5,temp6) then goto __Skip_Missile

   ;```````````````````````````````````````````````````````````````
   ;  Deletes pfpixel.
   ;
   ;if objects[5] & 4 = 0 then goto __Delete_Missile
   if temp6 = 5 then goto __Delete_Missile
   if temp6 > 5 then goto __Delete_Missile
   pfpixel temp5 temp6 off

__Delete_Missile

   ;```````````````````````````````````````````````````````````````
   ;  Clears missile0 moving bit and moves missile0 off the screen.
   ;
   _b7_gameMissile0Moving{7} = 0 : missile0x = 200 : missile0y = 200

__Skip_Missile


   /* ; LANCIO DEL MISSILE
   ; Se joy0fire è premuto o shoot è già attivo, salta l'inizializzazione
   if !joy0fire then goto __skip_missile
   if (shoot & %10000000) <> 0 then goto __skip_missile

   ; SPARO: inizializza il missile
   shoot = %10000000               ; Missile attivo
   missile0x = player0x            ; Allinea il missile con il giocatore
   missile0y = player0y            ; Allinea il missile con il giocatore

   ; Imposta la direzione in base al joystick
   if joy0left then shoot = shoot | %00001000
   if joy0right then shoot = shoot | %00010000
   if joy0up then shoot = shoot | %00100000
   if joy0down then shoot = shoot | %01000000

__skip_missile

   ; MOVIMENTO DEL MISSILE (ogni 4 frame per rallentare un po’)
   ;if frame_counter & 7 <> 0 then goto __skip_movement
   ;if (shoot & %10000000) = 0 then goto __skip_movement   ; Se il missile non è sparato, salta il movimento

   ; MOVIMENTO DEL MISSILE
   temp1 = shoot & %00000111       ; Estrai la distanza dal missile
   temp1 = temp1 + 1               ; Aumenta la distanza
   shoot = (shoot & %11111000) | temp1  ; Aggiorna la distanza nel missile

   ; Muovi orizzontalmente
   if (shoot & %00011000) = %00001000 then missile0x = missile0x - 1  ; Sinistra
   if joy0left then missile0x = missile0x + 1  ; Destra

   ; Muovi verticalmente
   if (shoot & %01100000) = %00100000 then missile0y = missile0y - 1  ; Su
   if (shoot & %01100000) = %01000000 then missile0y = missile0y + 1  ; Giù

   ; Se il missile ha raggiunto la distanza massima, spegnilo
   ;if temp1 >= 128 then shoot = 0

__skip_movement */

   ;if collision(playfield,missile0) then temp5 = (missile0x-17)/4 : temp6 = (missile0y-missile0height)/8: pfpixel temp5 temp6 off : shoot = 0 : missile0y = 222 
   
   /* ;```````````````````````````````````````````````````````````````
   ;  Missile0 y coordinate conversion.
   ;
   
   temp5 = missile0height + 3 : _pf_y = (missile0y-temp5)/3

   ;```````````````````````````````````````````````````````````````
   ;  Missile0 x coordinate conversion.
   ;
   _pf_x = (missile0x-17)/4

   ;```````````````````````````````````````````````````````````````
   ;  If a block is there, skip this subsection.
   ;
   if !pfread(_pf_x,_pf_y) then goto __Skip_miss0_to_pf_Coll

   ;```````````````````````````````````````````````````````````````
   ;  Deletes pfpixel.
   ;
   pfpixel _pf_x _pf_y off

   ;```````````````````````````````````````````````````````````````
   ;  Moves missile0 off the screen.
   ;
   missile0y = 222  */

;__Skip_miss0_to_pf_Coll

   

   ;Background visibile se la lampada è accesa
   if _b4_gameLight{4} || frame_counter & 7 = 0 then pfcolors:
   $24
   $26
   $28
   $D4
   $26
   $D4
   $05
   $9E
   $0E
   $24
   $26
end

   ; background spento se la lampada no è accesa
   if !_b4_gameLight{4} then pfcolors:
   $0
end

__skip_light


 
   ;*************************************************************************
   ; ANIMAZIONE PLAYER 0
   ; ------------------------------------------------------------------------
   ; solo se sto muovendo il joystick
   ;*************************************************************************
   if !joy0right && !joy0left && !joy0up && !joy0down && seconds_counter then goto __skip_animation_player0
   
   ;*************************************************************************
   ; ANIMAZIONE PLAYER
   ;_________________________________________________________________________
   ; player 0 -> Biscotto => 8 x 4 pixel
   ; player 1 -> Bocca che mangia => 8 x 4 pixel
   ;*************************************************************************

   if frame_counter && frame_counter & 7 = 0 then player0:
   %00011000
   %10111101
   %01011010
   %01111110
end

   if frame_counter && frame_counter & 8 = 0 then player0:
   %00100100
   %10111101
   %01011010
   %01111110
end

__skip_animation_player0

   if frame_counter & 15 = 0 then player1:
   %01111110
   %10000001
   %10011001
   %01100110
end

   if frame_counter & 31 = 0 then player1:
   %01111110
   %11111111
   %11111111
   %01100110
end
   if !_b0_gameStart{0} then goto __skip_to_draw_playfield



   ;if second_counter * 30 + frame_counter < 54 then a = 32 - ((second_counter * 30 + frame_counter) * 29 / 54) : pfpixel a 2 on : pfpixel a 3 on : pfpixel a 4 on

   ;next
   ;if frame_counter = 30 && _level >=1 then a = temp3 - 1 : callmacro choco a on
   ;if frame_counter = 430 && _level >=1 then a = temp3 - 1 : callmacro choco a on
   ;if frame_counter = 30 && _level >=1 then if temp3 > 3 then a = temp3 - 1 else a = 3 : callmacro choco a on

; !!!!!!!!!!!!!!!!!!!!!!! TAZZE

      /* if objects[0] & 7 = 0 then pfhline 6 8 9 on : pfhline 6 9 10 on : pfhline 6 10 8 on ; Tazza
      if objects[0] & 7 = 0 then pfhline 6 8 9 on : pfhline 6 9 10 on : pfhline 6 10 8 on ; Tazza
      if objects[0] & 7 = 0 then pfhline 6 8 9 on : pfhline 6 9 10 on : pfhline 6 10 8 on ; Tazza
      if objects[0] & 7 = 0 then pfhline 6 8 9 on : pfhline 6 9 10 on : pfhline 6 10 8 on ; Tazza
      if objects[0] & 7 = 0 then pfhline 6 8 9 on : pfhline 6 9 10 on : pfhline 6 10 8 on ; Tazza */

         ;if objects[1] & temp2 = 0 then pfhline v 6 2 on ; Luce
         ;if objects[3] & temp2 = 0 then pfhline v 6 3 on : pfpixel 2 7 on; Pressa

      /* if objects[4] & v = 0 then pfhline 2 9 4 on : pfpixel 0 10 on : pfpixel 2 10 on : pfpixel 4 10 on; Tavolo
      if objects[5] & v = 0 then pfhline 0 6 2 on : pfpixel 1 7 on; Luce
      if objects[6] & v = 0 then pfhline 0 6 2 on ; Luce
      if objects[7] & v = 0 then pfhline 0 6 2 on ; Luce
      if objects[8] & v = 0 then pfhline 0 6 2 on ; Luce
      if objects[9] & v = 0 then pfhline 0 6 2 on ; Luce
      if objects[10] & v = 0 then pfhline 0 6 2 on ; Luce
      if objects[11] & v = 0 then pfhline 0 6 2 on ; Luce */
      /* v = v * 2
      if v < 128 then goto __timer_10
      v = 1 */
__skip_timer_10
   ;goto __done

   /* temp2 = 1
   for x = 0 to 7
      callmacro timer_10 0 temp2 0
      temp2 = temp2 * 2
   next

   macro timer_10
      temp3 = {2}
      temp4 = objects[{1}]
      if temp4 & temp3 > 0 then pfhline {3} 6 4 on ; Coltello
      if temp4 & temp3 > 0 then pfhline {3} 6 2 on ; Luce
      if temp4 & temp3 > 0 then pfhline {3} 6 2 on ; Luce
      if temp4 & temp3 > 0 then pfhline {3} 6 2 on ; Luce
      if temp4 & temp3 > 0 then pfhline {3} 6 2 on ; Luce
end */

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
   if _b6_palyerslowMotion{6} then if (frame_counter & 3) = 0 then player0y = player0y - 1
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
   if player0y >= _P_Edge_Bottom then goto __Skip_Joy0_Down

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

   if _b6_palyerslowMotion{6} then if (frame_counter & 3) = 0 then player0y = player0y + 1
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
   if _b6_palyerslowMotion{6} then if (frame_counter & 3) = 0 then player0x = player0x - 1
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
   if player0x >= _P_Edge_Right then goto __Skip_Joy0_Right

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
   if _b6_palyerslowMotion{6} then if (frame_counter & 3) = 0 then player0x = player0x + 1
   if !_b6_palyerslowMotion{6} then player0x = player0x + 1 

   _Bit3_P0_Dir_Right{3} = 1
__Skip_Joy0_Right

   ;*************************************************************************
   ; COLLISION TRA PLAYER E ZUCCHERO
   ;_________________________________________________________________________
   ; incremento il valore del punteggio e decremento il valore energetico
   ; dello zucchero
   ;*************************************************************************   
   /* for x = 0 to 7
      temp2 = 255 - (2 ^ x)    ; crea maschera con 0 nella posizione x
      if collision(player0, missile1) && sugar_point & temp2 = 0 then  sugar_point = sugar_point & temp2 : goto __increment_score
   next */

   ;*************************************************************************
   ; COLLISIONI 
   ;_________________________________________________________________________
   ; tra Biscotto e Bocca: decremento la barra della salute
   ; tra Missile e Bocca: incremento dei punti di una unità
   ; tra Biscotto e Zucchero : incremento dei punti e individuazione del
   ; prossimo zucchero da prendere
   ;*************************************************************************   
   if collision(player0, player1) && frame_counter = 0 then goto __decrease_health_bar
   if collision(missile0, player1) && frame_counter = 0 then score = score + 10 
   if collision(player0, ball) && frame_counter = 0 then goto __change_level
   ;if collision(player0, missile1) && sugar_count <= 8 then sugar_count = sugar_count + 1 : goto __increment_score
   goto __done

__decrease_timer_bar
   pfscore1 = pfscore1 * 2
   goto __done

__decrease_health_bar
   pfscore2 = pfscore2 / 4
   if score > 0 then score = score - 1
   goto __done
/* 
__increment_score
   score=score+1 */

__change_level
   score = score + 100 
   _level = _level + 1
   if _level > 10 then goto __startGame
   sugar_count = 0
   if _velocita < 2 then _velocita = 2
   _velocita = _velocita - 2

__done
   goto __skip_to_draw_playfield

__gameOver
   _b0_gameStart{0} = 0
   goto __skip_to_draw_playfield

__playfield

   ;*************************************************************************
   ; PLAYFIELD LIVELLI
   ;_________________________________________________________________________
   ; Uno generico per semplificare
   ;************************************************************************* 
   if _level = 1 then playfield:
   ..X.............................
   ..X.............................
   ..X.............................
   ..X.............................
   ..X.............................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXX...
   XXX..........................X..
   .X..........................XXX.
   ................................
   XXX.............................
   X.X.X...........................
end



__skip_to_draw_playfield



   drawscreen
   goto __main_loop

   ; Array con le posizioni degli zuccherini e il relativo valore %11111111
   data _data_sugar_x
   46,68,90,112,46,68,90,112  ; Coordinate x degli zuccherini
end
   data _data_sugar_y
   82, 62, 82, 62, 26, 26, 26, 26  ; Coordinate y degli zuccherini
end
      ; TAZZE, ; COLTELLI ; GOCCE, MURI ; VIE DI ACCESSO
   data objects
         %00100000, %10000000, %00000100, %10000000, %11111111;,
         /* %01000000, %10000000, %00001110, %10000000, %11111111,
         %01000000, %10000000, %01100011, %10000000, %11111111,
         %01000000, %10000000, %01100011, %10000000, %11111111,
         %01000000, %10000000, %01100011, %10000000, %11111111,
         %01000000, %10000000, %01100011, %10000000, %11111111,
         %01000000, %10000000, %01100011, %10000000, %11111111,
         %01000000, %10000000, %01100011, %10000000, %11111111,
         %01000000, %10000000, %01100011, %10000000, %11111111,
         %01000000, %10000000, %01100011, %10000000, %11111111 ;LIVELLO 2 */
end

   data divisor
   28,64,32,16,8,4,2,1
   ;128,64,32,16,8,4,2,1
end
   ;=======================================================================
   ; XXXX
   ; XXXXX
   ; XXXX
   ;-----------------------------------------------------------------------
   ; {1} = posizione iniziale colonna
   ; {2} = posizione iniziale riga
   ; {3} = numero di righe
   ; esegue un ciclo in base la numero di righe che deve disegnare
   ; assegna un pixel per il manico
   ;=======================================================================
   macro tazze
      temp5 = {2} + {3} -1
      temp6 = {1} + 4
      for y = {2} to temp5
         pfhline {1} y temp6 flip
      next
      pfpixel temp6 temp5 flip ; manico

      /*temp4 = {2}
      pfhline {1} temp4 {2} flip : temp4 = temp4 + 1
      temp3 = {1} + {2} + 1
      pfhline {1} temp4 temp3 flip : temp4 = temp4 + 1 ; prima riga lunga {5}
      pfhline {1} temp4 {2} flip ; seconda riga lunga {6}
     if {5} > 0 then temp3 = {1} + {5} : pfhline {1} {2} temp3 flip ; prima riga lunga {5}
      if {6} > 0 then temp3 = {1} + {6} : pfhline {1} {3} temp3 flip ; seconda riga lunga {6}
      if {7} > 0 then temp3 = {1} + {7} : pfhline {1} {4} temp3 flip ; terza riga linga {7}
      */
end

   macro chocoWall
   u = {1}
   o = {2} + 2
   pfvline u {2} o on
   u = {1} + 4
   o = {2} -2
   pfpixel u o on
end
   ; {1} = Sezione dello score
   ; {2} = Tipologia che corrisponde al punteggio da aggiungere

