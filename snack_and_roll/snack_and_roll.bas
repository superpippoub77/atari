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

   ;colori di default
   const _base_color = $16
   const _P0_color = $2C
   const _P1_color = $32
   
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
   ;*************************************************************************
   dim pf_animation = a
   dim _level = b
   dim frame_counter  = c
   dim seconds_counter  = d

   dim _animation = f

   dim sugar_count = t
   dim sugar_point = s

   dim _b0_gameStart = k
   dim _b4_gameLight = k

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
   COLUP0 = _P0_color : COLUP1 = _P1_color : NUSIZ0 = %00110000 : REFP0 = 0 
   COLUBK = 0 
   ;COLUPF = $2C

   a = 3 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0

   score = 10
   pfscore1 = 255 ;Tempo
   pfscore2 = %10101010 ;Salute

   ;*************************************************************************
   ; POSIZIONI PLAYER AND SPRITE INIZIALI
   ;*************************************************************************
   player0x = 30 : player0y = 54 : player1x = 0 : player1y = 20
   missile1x  = 0 : missile1y = 20

__startGame

   _b0_gameStart{0} = 0 ; Gioco non attivo
   _b4_gameLight{4} = 1 ; Luci accese di default
   _level = 0
   _animation = 0
   sugar_point=255
   missile0height=1
   ;Per evitare che si veda nella schermata di presentazione
   scorecolor = 255
   pfscorecolor = $0

   ;*************************************************
   ; PLAYFIELD: TITOLO
   ; ------------------------------------------------
   ; E' visibile solo dalla riga 1 alla riga 11
   ; Snack 'n' Roll
   ; pfcolors => varaiazioni di marrone da $22 a $2B
   ;*************************************************
   playfield:
   ................................
   ....XXXXXXXXX...XX.......X..X...
   ...X..............X......X.X....
   ....XX...X.XX...XXX..XXX.XX.....
   ......X..XX..X.X..X.X....X.X....
   XXXXXX...X...X..XXX..XXX.X..X...
   ................................
   .X.......X.................X.X.
   ...X.XX........X.XX..XX...X.X...
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
   ;Se premo select inizializzo il gioco
   if switchreset && !_b0_gameStart{0} then k = 255 : _level = 1 : sugar_count = 0 : scorecolor = _base_color : pfscorecolor = _base_color: goto __select_level
   ;if switchselect && !_b0_gameStart{0} then _level = _level + 1 : __select_level

   ;Se il gioco non è ancora iniziato skippa tutto e disegna solo il playfield
   if !_b0_gameStart{0} then goto __skip_playfield

   ;!!!!!!!!!!!!!!!!!!! START

   ;*************************************************************************
   ; TIMER
   ;_________________________________________________________________________
   ; Per ottimizzare uso un solo timer per tutti gli eventi controllando 
   ; i flag degli oggetti
   ;*************************************************************************
   frame_counter = frame_counter + 1
   if frame_counter > frame_limit then frame_counter = 0 : seconds_counter = seconds_counter + 1

   ;*************************************************************************
   ; CHECK
   ;_________________________________________________________________________
   ; 1) ogni 32 secondi elimina uno spazio tempo
   ; 2) se lo spazio tempo è finito elimina una health
   ; 3) se non ci sono più health allora il gioco è completato o terminato
   ;*************************************************************************

   if frame_counter = 0 && seconds_counter & 7 = 0 then pfscore1 = pfscore - 10
   if pfscore1 = 0 then goto __decrease_health_bar
   if pfscore2 = 0 || _level = 10 then goto __gameOver

   ;*************************************************************************
   ; ANIMAZIONE PLAYER 1 (MOUNTH)
   ;_________________________________________________________________________
   ; ogni mezzo secondo cambia randomicamente la posizone dell'oggetto
   ;*************************************************************************

   temp2 = (frame_limit/2)
   if temp2 = frame_counter then player1x = (rand/4) + (rand&31) + (rand&15) + (rand&1) + 21 : player1y = (rand & 31) + (rand & 15) + (rand & 3) + 20
   ;*************************************************************************
   ; ANIMAZIONE LIGHT
   ;_________________________________________________________________________
   ; dopo 16 secondi la luce si spegne per accenderla devo premere il
   ; pulsante !!ATTENZIONE i 20 secodi sono fittizzi perchè dipende dal 
   ; seconds_counter in quel determinato istante
   ; !!IMP Cambia il colore del background solo nella parte bassa dello 
   ; schermo (TO DO)
   ;*************************************************************************

   ;Spegnimento della luce bit = 0
   if seconds_counter && seconds_counter & 15 = 0 then _b4_gameLight{4} = 0

   ;Accensione della luce bit = 1 e decremento della barra tempo
   if joy0fire && !_b4_gameLight{4} then _b4_gameLight{4} =  1 : pfscore2 = pfscore2/2

   ;Background visibile se la lampada è accesa
   if _b4_gameLight{4} then pfcolors:
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
   $24
   $26
   $28
   $D4
   $26
   $D4
   $0
   $0
   $0
   $0
   $0
end

__skip_light


  ;*************************************************************************
   ; SUGAR
   ;_________________________________________________________________________
   ; missile 1 -> Zuccherino (8)
   ; ball ->  Bolle del bollitore (un solo colore azzurro)
   ; missile 0 -> Sacchetto di uscita dal livello 
   ; missile 1 -> Bonus (randomico sullo schermo a tempo, se attivo)
   ; ball ->  Bolle del bollitore (un solo colore azzurro)
   ;*************************************************************************

   if frame_counter <> frame_limit then goto __skip_animation_sugar
   if _level = 1 then sugar_count = _level else sugar_count = (rand&7) + 1 
   temp2 = 255 - (2 ^ x) 
   
   missile0x = _data_sugar_x[sugar_count] : missile0y = _data_sugar_y[sugar_count]
   ;a = (rand&7) + 1
   ;if frame_counter & 6 = 0 then sugar_count = 0
   ;if seconds_counter then score = seconds_counter

__skip_animation_sugar
 
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
   %00000000
   %11111111
   %11111111
   %00000000
end
   if !_b0_gameStart{0} then goto __skip_playfield

   ;*************************************************************************
   ; ANIMAZIONE PLAYFIELD
   ;_________________________________________________________________________
   ; RIGA: 0 -> 4 (partono sempre dalla colonna 3)
   ; Gocce di cioccolato:traslazione verticale
   ; Barrette di ciccolato: traslazione orizzontale
   ; RIGA: 7 -> 8
   ; Lama del coltello
   ;*************************************************************************
   ;callmacro transaction sugar_count

   ;============
   ;=  GOCCE   =
   ;============
   /* if _level >= 1 then temp3 = (rand&28) + 3 else temp3 = (rand & 9) + 3
   if frame_counter = 10 && _level >=1 then a = temp3 : pfpixel a 0 on
   if frame_counter = 15 && _level >=2 then t = temp3 + 13 : pfpixel t 0 on
   if frame_counter = 20 && _level >=1 then pfpixel a 2 on : pfpixel a 0 off 
   if frame_counter = 25 && _level >=2 then pfpixel t 2 on : pfpixel t 0 off
   if frame_counter = 30 && _level >=1 then pfpixel a 4 on : pfpixel a 2 off 
   if frame_counter = 35 && _level >=2 then pfpixel t 4 on : pfpixel t 2 off
   if frame_counter = 40 && _level >=1 then pfpixel a 4 off 
   if frame_counter = 45 && _level >=2 then pfpixel t 4 off */

   ;============
   ;=CIOCCOLATO=
   ;============
   ;pf_animation = consentei di avviare o meno il playfiled dello schermo superiore
   ;pf_animation = pf_animation - 1 : sposta la barretta orizzontalmente fino alla colonna 3
   ;dalla colonna 3 alla colonna 0 deve essere abbattuta

   if pf_animation = 3 then  callmacro chocoWall pf_animation 0 : pf_animation = 31
   if frame_counter & 31 = 0 && pf_animation > 2 then callmacro chocoWall pf_animation 0
   if frame_counter & 31 = 1 && pf_animation > 3 then pf_animation = pf_animation - 1: callmacro chocoWall pf_animation 1

   macro chocoWall
   if {2} = 1 then pfpixel {1} 2 on : pfpixel {1} 3 on : pfpixel {1} 4 on
   if {2} = 0 then pfpixel {1} 2 off : pfpixel {1} 3 off : pfpixel {1} 4 off
end
   ;if second_counter * 30 + frame_counter < 54 then a = 32 - ((second_counter * 30 + frame_counter) * 29 / 54) : pfpixel a 2 on : pfpixel a 3 on : pfpixel a 4 on

   ;next
   ;if frame_counter = 30 && _level >=1 then a = temp3 - 1 : callmacro choco a on
   ;if frame_counter = 430 && _level >=1 then a = temp3 - 1 : callmacro choco a on
   ;if frame_counter = 30 && _level >=1 then if temp3 > 3 then a = temp3 - 1 else a = 3 : callmacro choco a on



   /* macro transaction
   if frame_counter = 10 then pfhline 8 6 12 on : pfpixel {1} 0 on ;: pfpixel _data_sugar_x[sugar_count] 1 on 
   if frame_counter = 15 then pfhline 9 7 12 on : pfpixel {1} 0 off ;: pfpixel _data_sugar_x[sugar_count] 1 off : pfhline 17 8 20 off
   if frame_counter = 20 then pfhline 10 8 12 on : pfpixel {1} 2 on ;: pfpixel _data_sugar_x[sugar_count] 3 on : pfhline 17 8 20 on
   if frame_counter = 45 then pfhline 8 8 12 off : pfpixel {1} 2 off  ;: pfpixel _data_sugar_x[sugar_count] 2 off 
   if frame_counter = 50 then pfhline 8 7 12 off : pfpixel {1} 4 on ;: pfpixel _data_sugar_x[sugar_count] 4 on: pfpixel 1 3 off
   if frame_counter = 53 then pfhline 8 6 12 off : pfpixel {1} 4 off ;: pfpixel _data_sugar_x[sugar_count] 4 off
end  */

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

__timer_20

__timer_30

__timer_40

__timer_50



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


   /* macro setplayfield_col_off
   temp2 = {2} ; x
   temp5 = {2} + 4 ; x + length
   temp6 = {3} ; y
   if {1} = 62 then temp6 = temp6 - 1
   if {1} = 64 then temp6 = temp6 - 1
   if {1} > 60 then pfhline temp2 temp6 temp5 off
end */

   ; COLLISION TO DO

   ; zuccherino 0
   ;if sugar{0} = 1 then missile0x = sugar{0} : missile0y= sugar{0} : missile0 on
   /* if collision(player0, missile0) && sugar{0} && player0x = _data_sugar_x[0] && player0y = _data_sugar_y[0] then sugar{0} = 0
   if collision(player0, missile0) && sugar{1} && player0x = _data_sugar_x[1] && player0y = _data_sugar_y[1] then sugar{1} = 0
   if collision(player0, missile0) && sugar{2} && player0x = _data_sugar_x[2] && player0y = _data_sugar_y[2] then sugar{2} = 0
   if collision(player0, missile0) && sugar{3} && player0x = _data_sugar_x[3] && player0y = _data_sugar_y[3] then sugar{3} = __done0
   if collision(player0, missile0) && sugar{4} && player0x = _data_sugar_x[4] && player0y = _data_sugar_y[4] then sugar{4} = 0
   if collision(player0, missile0) && sugar{5} && player0x = _data_sugar_x[5] && player0y = _data_sugar_y[5] then sugar{5} = 0
   if collision(player0, missile0) && sugar{6} && player0x = _data_sugar_x[6] && player0y = _data_sugar_y[6] then sugar{6} = 0
   if collision(player0, missile0) && sugar{7} && player0x = _data_sugar_x[7] && player0y = _data_sugar_y[7] then sugar{7} = 0 */

   ;*************************************************************************
   ; COLLISION TRA PLAYER E ZUCCHERO
   ;_________________________________________________________________________
   ; incremento il valore del punteggio e decremento il valore energetico
   ; dello zucchero
   ;*************************************************************************   
   for x = 0 to 7
      temp2 = 255 - (2 ^ x)    ; crea maschera con 0 nella posizione x
      if collision(player0, missile0) && sugar_point & temp2 = 0 then  sugar_point = sugar_point & temp2 : goto __increment_score
   next

   ;*************************************************************************
   ; COLLISION TRA PLAYER E BOCCA 
   ;_________________________________________________________________________
   ; decremento la barra della salute
   ;*************************************************************************   
   if collision(player0, player1) && frame_counter = 0 then goto __decrease_health_bar

   ; se non ci sono collisioni non controlla decrease health
   goto __done

__decrease_health_bar
   pfscore2 = pfscore2/2
   if score then score=score-10
   goto __done

__increment_score
   score=score+10
   sugar_point = sugar_point +1

__done

   goto __skip_playfield

__gameOver
   _b0_gameStart{0} = 0
   goto __skip_playfield

__select_level

   ;*************************************************************************
   ; LIVELLO 1
   ;_________________________________________________________________________
   ; TO DO
   ;************************************************************************* 
   if _level = 1 then playfield:
   ................................
   ................................
   ................................
   ................................
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXX..........................X..
   .X..........................XXX.
   ................................
   XXX.............................
   X.X.X...........................
end


   if _level > 42 then _level = 0 : goto __startGame

__skip_playfield
   /* COLUP0 = _P0_color : COLUP1 = _P1_color
   COLUBK = 0  */
   NUSIZ0 = $20

   ;if seconds_counter & 7 > then goto __skip_animation
   x = 0
   temp4 = 1 
   temp5 = 16
__oggetti
   ; TAZZE
   ;if frame_counter & 30 > 0 && %00000000 & temp4 > 0 then callmacro row x 2 3 4 3 4 2 on
   if frame_counter & 35 > 0 && %11100000 & temp5 > 0 then callmacro row x 8 9 10 3 4 2 on
   
   ; COLTELLI
   ;if frame_counter & 20 > 0 && %00000000 & temp4 > 0 then callmacro row x 0 1 2 5 3 2 on
   ;if frame_counter & 25 > 0 && %01000000 & temp5 > 0 then callmacro row x 6 7 0 5 3 0 on

   ; LUCI
   /* temp6 = x+1
   if %00000000 & temp4 > 0 then callmacro row x 0 0 0 2 0 0 : pfpixel temp6 1 on
   if %00010000 & temp5 > 0 then callmacro row x 6 0 0 2 0 0 : pfpixel temp6 7 on

   ; TAVOLO
   temp6 = x+2
   if frame_counter & 40 > 0 && %01000000 & temp5 > 0 then callmacro row x 9 0 0 2 0 0 on: pfpixel x 10 on : pfpixel temp6 10 on
   temp6 = x+4
   if frame_counter & 45 > 0 && %01000000 & temp5 > 0 then pfpixel temp6 10 on */

   /* temp6 = x+7
   ; CUCCHIAIO
   if frame_counter & 50 > 0 && %10101000 & temp4 > 0 then pfpixel temp6 0 on : pfpixel temp6 1 on : pfpixel temp6 2 on
   if frame_counter & 55 > 0 && %10000000 & temp5 > 0 then pfpixel temp6 6 on : pfpixel temp6 7 on : pfpixel temp6 8 on */
   x = x + 7
   temp4 = temp4 * 2
   temp5 = temp5 * 2
   if x < 28 then goto __oggetti

   ; {1} = x -> posizione di partenza, {2} = y1, {3} = y2, {4} = y3
__skip_animation
   
   macro row
      if {5} > 0 then temp3 = {1} + {5} : pfhline {1} {2}  temp3 {8} ; prima riga lunga {5}
      if {6} > 0 then temp3 = {1} + {6} : pfhline {1} {3}  temp3 {8} ; seconda riga lunga {6}
      if {7} > 0 then temp3 = {1} + {7} : pfhline {1} {4}  temp3 {8} ; terza riga linga {7}
end 
   drawscreen
   goto __main_loop



   ; Array con le posizioni degli zuccherini e il relativo valore
   data _data_sugar_x
   20,30, 50, 70, 90, 110, 130, 150  ; Coordinate x degli zuccherini
end
   data _data_sugar_y
   10, 60, 10, 60, 10, 60, 10, 60  ; Coordinate y degli zuccherini
end
   data objects
      %11111111, ; 0 = Luci
      %11111111, ; 1 = Tazze -- FATTO
      %11111111, ; 2 = Cucchi
      %11111111, ; 3 = Pressa
      %11111111, ; 4 = Tavoli
      %11111111, ; 5 = Luci
      %11111111, ; 6 = Gocce
      %11111111, ; 7 = Fornello
      %11111111, ; 8 = Forchetta
      %11111111, ; 9 = Pentola
      %11111111, ; 10 = Torta
end