   ;*************************************************
   ; SETTAGGIO DEL KERNEL E OPZIONI
   ; ------------------------------------------------
   ; kernel_options :
   ; player0colors = colorazione del player 1
   ; pfcolors = colorazione del playfiled
   ; pfheights = altezza del righe del playfield
   ; romsize = 4k, 8k (2 banchi di memoria)
   ; pal  = Versione dei colori
   ; tv = effetto crt (non necessario)
   set kernel_options pfcolors
   set romsize 4k
   set pal


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
   const _P_Edge_Left = 0
   const _P_Edge_Right = 153

   const _base_color = $16
   const _P0_color = $2C
   const _P1_color = $68
   
   ;*************************************************************************
   ; VARIABILI
   ; ------------------------------------------------------------------------
   ; level -> b (1 = cucina, ...4 = ...)
   ; ........................................................................
   ; diffcult -> d (1, 2, 3, 4) => levocità in cui si muovono gli oggetti
   ; ........................................................................
   ; score -> l
   ; ........................................................................
   ; anination: posizone del player in movimento
   ; ........................................................................
   ; timer_cp:
   ; cup -> e
   ; plate -> f
   ; timer:
   ; gocce cioccolato -> i
   ; timer healt:
   ; gocce cioccolato -> j
   ; _opt_b0 -> k (b0 = Game start/stop)
   ; _opt_b1 -> k (b1 = Light on/off)
   ;*************************************************************************
   dim _timer_light = a
   dim _level = b
   dim _animation = f
   dim _timer_pf = e

   dim _transaction = d

   dim _timer_cp = g.h
   dim _timer_g = i
   ;dim _timer_h = j
   dim _opt_b0 = k
   dim _opt_b1 = k

   dim _obj1 = s 
   dim _obj2 = t

   ;***************************************************************
   ;
   ;  Variable aliases go here (DIMs).
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Converts 6 digit score to 3 sets of two digits.
   ;
   ;  The 100 thousands and 10 thousands digits are held by _sc1.
   ;  The thousands and hundreds digits are held by _sc2.
   ;  The tens and ones digits are held by _sc3.
   ;

   /* dim _sc1 = score
   dim _sc2 = score+1
   dim _sc3 = score+2 */
   dim frame = 0
   dim posizione = 0


   dim _pos_p1_x = player0.x
   dim _pos_p1_y = player0.y

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
   ; pfscore1 => timer (decrementale)
   ; pfscore2 => energy (incrementale)
   ; ........................................................................
   ; lifecolor 
   ; lives = 128 => 4 lives
   ;*************************************************************************
   COLUP0 = _P0_color : COLUP1 = _P1_color : NUSIZ0 = $00 : REFP0 = 0 
   COLUBK = 0 
   ;COLUPF = $2C
   scorecolor = _base_color : pfscorecolor = _base_color

   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0

   score = 0
   pfscore1 = %11111111
   pfscore2 = %11111111
   ;*************************************************************************
   ; PLAYER AND SPRITE
   ; ------------------------------------------------------------------------
   ; player 0 -> Biscotto (nessun colore) => 4 x 4 pixel
   ; player 1 -> Bocca che mangia (colorata ?? dipende se voglio missile 1)
   ; missile 0 -> Sacchetto di uscita dal livello 
   ; missile 1 -> Bonus (randomico sullo schermo a tempo, se attivo)
   ; ball ->  Bolle del bollitore (un solo colore azzurro)
   ;*************************************************************************
   player0:
   %00111100
   %01110110
   %01111110
   %00111100
end

   player1:
   %01111110
   %10000001
   %10000001
   %01111110
end

   ;*************************************************************************
   ; POSIZIONI PLAYER AND SPRITE INIZIALI
   ;*************************************************************************
   player0x = 30 : player0y = 54 : player1x = 20 : player1y = 54

   ;Se il gioco è iniziato (bit0) = 1 non entra nella generazione del titolo
   ;if _opt_b0{0} then __main_loop

   ;*************************************************
   ; PLAYFIELD: TITOLO
   ; ------------------------------------------------
   ; Snack 'n' Roll
   ; pfcolors => varaiazioni di marrone da $22 a $2B
   ;*************************************************
__start

   _opt_b0{0} = 0
   _opt_b1{1} = 1
   _level = 0
   _animation = 0
   _timer_light = 0
   _timer_pf = 0
   _obj1 = 0
   _obj2 = 0
   playfield:
   ....XXXXXXXXX...XX.......X..X...
   ...X..............X......X.X....
   ....XX...X.XX...XXX..XXX.XX.....
   ......X..XX..X.X..X.X....X.X....
   XXXXXX...X...X..XXX..XXX.X..X...
   ................................
   ...........................X.X..
   .X.......X................X.X...
   ...X.XX........X.XX..XX..X.X....
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
   goto __skip_playfield


__main_loop

   ;Se premoo select inizializzo il gioco _opt_b0 = 1 e cambio il playfield per esempio __level_1_1
   if switchreset && !_opt_b0{0} then _opt_b0{0} = 1 : _opt_b1{1} = 1 : _timer_pf = 0 : _level = 1 : goto __select_level
   ;if switchselect && !_opt_b0{0} then _level = _level + 1 : __select_level

   if !_opt_b0{0} then goto __skip_playfield

   ;*************************************************************************
   ; ANIMAZIONE PLAYER 0
   ; ------------------------------------------------------------------------
   ; solo se sto muovendo il joystick
   ;*************************************************************************
   if joy0right || joy0left then _animation = _animation + 1
   if joy0up || joy0down then _animation = _animation + 1
   if !joy0right && !joy0left && !joy0up && !joy0down then _animation = 0 

   ;*************************************************************************
   ; ANIMAZIONE PLAYER 1
   ; ------------------------------------------------------------------------
   ; 
   ;*************************************************************************
   if _timer_pf = 30 then player1x = (rand/4) + (rand&31) + (rand&15) + (rand&1) + 21 : player1y = (rand & 31) + (rand & 15) + (rand & 3) + 20
   
   ;*************************************************************************
   ; ANIMAZIONE PLAYFIELD
   ; ------------------------------------------------------------------------
   ; 
   ;*************************************************************************
   _timer_pf = _timer_pf + 1
   if _timer_pf > 120 then _timer_pf = 0

   ;*************************************************************************
   ; LIGHT
   ; ------------------------------------------------------------------------
   ; _timer_light => tempo di accensione della lampada (30s) se attiva
   ; _data_light => array contenente l'elenco delle posizioni delle luci
   ; suddivise per livello (a coppia)
   ;*************************************************************************

   ;Accensione della lampada
   if joy0fire && !_opt_b1{1} then _opt_b1{1} =  1 : pfpixel 7 1 on

   ;Attivazione del timer solo se la lampada è attiva
   if _opt_b1{1} then _timer_light = _timer_light + 1
   
   ;Timer finito azzeramento del timer disattivazione del flag della lampada
   ;if _timer_light = 255 then _opt_b1{1} =  0 : pfpixel 1 7 off : _timer_light = 0

   ; background visibile se la lampada è accesa
   if _opt_b1{1} then pfcolors:
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
   if !_opt_b1{1} then pfcolors:
   $0
   $0
   $0
   $0
   $0
   $D4
   $0
   $0
   $0
   $0
   $0
end

__skip_light


   scorecolor = _animation

 
   if _animation<10 then player0:
   %00011000
   %11111111
   %00000000
   %11111111
end

   if _animation >10  then player0:
   %00100100
   %11111111
   %00000000
   %11111111
end



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

   if temp5 < 34 then if pfread(temp5,temp6) then goto __Skip_Joy0_Up

   temp4 = (player0x-17)/4

   if temp4 < 34 then if pfread(temp4,temp6) then goto __Skip_Joy0_Up

   temp3 = temp5 - 1

   if temp3 < 34 then if pfread(temp3,temp6) then goto __Skip_Joy0_Up

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 up.
   ;
   player0y = player0y - 1

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

   if temp5 < 34 then if pfread(temp5,temp6) then goto __Skip_Joy0_Down

   temp4 = (player0x-17)/4

   if temp4 < 34 then if pfread(temp4,temp6) then goto __Skip_Joy0_Down

   temp3 = temp5 - 1

   if temp3 < 34 then if pfread(temp3,temp6) then goto __Skip_Joy0_Down

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 down.
   ;
   player0y = player0y + 1

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

   if temp6 < 34 then if pfread(temp6,temp5) then goto __Skip_Joy0_Left

   temp3 = (player0y-4)/8

   if temp6 < 34 then if pfread(temp6,temp3) then goto __Skip_Joy0_Left

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 left.
   ;
   player0x = player0x - 1

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

   if temp6 < 34 then if pfread(temp6,temp5) then goto __Skip_Joy0_Right

   temp3 = (player0y-4)/8

   if temp6 < 34 then if pfread(temp6,temp3) then goto __Skip_Joy0_Right

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 right.
   ;
   player0x = player0x + 1

__Skip_Joy0_Right

__playfield_transaction ; y x l

   if _timer_pf > 10 && _timer_pf < 60 then pfhline 0 0 5 on : pfhline 15 0 20 on
   if _timer_pf > 12 && _timer_pf < 60 then pfhline 1 1 5 on : pfhline 16 1 20 on
   if _timer_pf > 15 && _timer_pf < 60 then pfhline 2 2 5 on : pfhline 17 2 20 on

   if _timer_pf > 60 && _timer_pf < 120 then pfhline 0 2 5 off : pfhline 15 2 20 off
   if _timer_pf > 62 && _timer_pf < 120 then pfhline 0 1 5 off : pfhline 15 1 20 off
   if _timer_pf > 65 && _timer_pf < 120 then pfhline 0 0 5 off : pfhline 15 0 20 off

   /* callmacro setplayfield_col_on _timer_pf 0 0 8 _obj1 

   ;callmacro setplayfield_col_on _timer_pf 10 0 8 1

   ;!if _timer_pf > 60 && _timer_pf < 120 then callmacro setplayfield_col_off _timer_pf 0 0 : callmacro setplayfield_col_off _timer_pf 10 0

   goto __skip_playfield

   macro setplayfield_col_on
   _obj2 = {4}
   if _timer_pf > 10 && _timer_pf < 60 && _data_object[0] < 3 then _obj2 = _obj2 + 1 : pfhline {2} _data_object[0] {4} on
   ;if _timer_pf > 60 && _timer_pf < 120 && _transaction < 2 then _transaction = _transaction - 1 : pfhline {2} temp6 {4} off 
end */

   macro setplayfield_col_off
   temp2 = {2} ; x
   temp5 = {2} + 4 ; x + length
   temp6 = {3} ; y
   if {1} = 62 then temp6 = temp6 - 1
   if {1} = 64 then temp6 = temp6 - 1
   if {1} > 60 then pfhline temp2 temp6 temp5 off
end



   if f=10 then goto __Decrease_Left_Time_Health_Bar 
   goto __Skip_Done

   ;if _animation = 20 then player0x = (rand/4) + (rand&31) + (rand&15) + (rand&1) + 21 : player0y = (rand & 31) + (rand & 15) + (rand & 3) + 20

   if collision(player0, player1) then __Decrease_Left_Time_Health_Bar




__Decrease_Left_Time_Health_Bar
   pfscore1 = pfscore1/2
   score=l+1
   ;pfpixel 6 1 flip
   goto __Skip_Done


__Skip_Done
   ;if _opt_b0{0} then goto __main_loop
   ;se il gico è già partito non deve sovrascrivere lo schermo

   goto __skip_playfield


__select_level
   if _level = 1 then playfield:
   ................................
   ................................
   ................................
   ................................
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
   XXX...XXXXX................XX...
   .......XXXX...............XXXX..
   ........XXX......XXX............
   ...XXX...........XXXX...........
   .X.X.X.X.........XXX............
end
   
   if _level = 11 then playfield:
   ................................
   ................................
   ................................
   ................................
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
   XXX...XXXXX................XX...
   .......XXXX...............XXXX..
   ........XXX......XXX............
   ...XXX...........XXXX...........
   .X.X.X.X.........XXX............
end
   
   if _level = 12 then playfield:
   ................................
   ................................
   ................................
   ................................
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
   XXX...XXXXX................XX...
   .......XXXX...............XXXX..
   ........XXX......XXX............
   ...XXX...........XXXX...........
   .X.X.X.X.........XXX............
end
   
   if _level = 2 then playfield:
   ................................
   ................................
   ................................
   ................................
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
   XXX...XXXXX................XX...
   .......XXXX...............XXXX..
   ........XXX......XXX............
   ...XXX...........XXXX...........
   .X.X.X.X.........XXX............
end
   
   if _level = 21 then playfield:
   ................................
   ................................
   ................................
   ................................
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
   XXX...XXXXX................XX...
   .......XXXX...............XXXX..
   ........XXX......XXX............
   ...XXX...........XXXX...........
   .X.X.X.X.........XXX............
end
   
   if _level = 22 then playfield:
   ................................
   ................................
   ................................
   ................................
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
   XXX...XXXXX................XX...
   .......XXXX...............XXXX..
   ........XXX......XXX............
   ...XXX...........XXXX...........
   .X.X.X.X.........XXX............
end
   
   if _level = 3 then playfield:
   ................................
   ................................
   ................................
   ................................
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
   XXX...XXXXX................XX...
   .......XXXX...............XXXX..
   ........XXX......XXX............
   ...XXX...........XXXX...........
   .X.X.X.X.........XXX............
end
   
   if _level = 31 then playfield:
   ................................
   ................................
   ................................
   ................................
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
   XXX...XXXXX................XX...
   .......XXXX...............XXXX..
   ........XXX......XXX............
   ...XXX...........XXXX...........
   .X.X.X.X.........XXX............
end
   
   if _level = 32 then playfield:
   ................................
   ................................
   ................................
   ................................
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
   XXX...XXXXX................XX...
   .......XXXX...............XXXX..
   ........XXX......XXX............
   ...XXX...........XXXX...........
   .X.X.X.X.........XXX............
end
   
   if _level = 4 then playfield:
   ................................
   ................................
   ................................
   ................................
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
   XXX...XXXXX................XX...
   .......XXXX...............XXXX..
   ........XXX......XXX............
   ...XXX...........XXXX...........
   .X.X.X.X.........XXX............
end
   
   if _level = 41 then playfield:
   ................................
   ................................
   ................................
   ................................
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
   XXX...XXXXX................XX...
   .......XXXX...............XXXX..
   ........XXX......XXX............
   ...XXX...........XXXX...........
   .X.X.X.X.........XXX............
end
   
   if _level = 42 then playfield:
   ................................
   ................................
   ................................
   ................................
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
   XXX...XXXXX................XX...
   .......XXXX...............XXXX..
   ........XXX......XXX............
   ...XXX...........XXXX...........
   .X.X.X.X.........XXX............
end

   if _level > 42 then _level = 0 : goto __start

__skip_playfield
   COLUP0 = _P0_color : COLUP1 = _P1_color
   COLUBK = 0 

   drawscreen

   goto __main_loop

   data _data_light ; il primo non si conta
   1,7,1,7,1,7,1,7
end

