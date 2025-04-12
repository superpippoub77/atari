   ;*************************************************
   ; SETTAGGIO DEL KERNEL
   ; ------------------------------------------------
   ; kernel_options :
   ; player0colors = colorazione del player 1
   ; pfcolors = colorazione del playfiled
   set kernel_options pfcolors 

   ;*************************************************
   ; ALTRI SETTAGGI
   ; ------------------------------------------------
   ; romsize = 4k, 8k (2 banhi di memoria)
   ; pal  = Versione dei colori
   ; tv = effetto crt
   set romsize 4k
   set pal


   ;*************************************************
   ; COSTANTI KERNEL (vedi poi INIZIALIZZAZIONE)
   ; ------------------------------------------------
   
   ; pfscore = abilitazione dello score
   const pfscore = 1
   ;const pfrowheight=8
   ;const noscore = 1

   ; limite dei bordi (suponendo un player di 8 pixel)
   const _pf_edge_top = 9 
   const _pf_edge_bottom = 88
   const _pf_edge_left = 1
   const _pf_edge_right = 153

   const _base_color = $16
   const _P0_color = $2C
   const _P1_color = $68

   const scorefade = 1

   
   ;*************************************************************************
   ; VARIABILI
   ; ------------------------------------------------------------------------
   ; light -> a (0 = off, 1 = on) => 0 non si vedono gli oggetti, 1 si vedono
   ; ........................................................................
   ; level -> b (1 = cucina, ...4 = ...) e 5 = Saccehtto finale
   ; scheme -> c (da 1 a 10, disposizone degli oggetti)
   ; ........................................................................
   ; diffcult -> d (1, 2, 3, 4) => levocità in cui si muovono gli oggetti
   ; ........................................................................
   ; score -> l
   ; ........................................................................
   ; speed:
   ; unit -> e
   ; decimal -> f
   ; ........................................................................
   ; timer_cp:
   ; cup -> e
   ; plate -> f
   ; timer:
   ; gocce cioccolato -> i
   ; timer healt:
   ; gocce cioccolato -> j
   ;*************************************************************************
   dim _light = a
   dim _lev_scheme = b.c
   dim _difficult = d
   dim _speed = e.f

   dim _timer_cp = g.h
   dim _timer_g = i
   ;dim _timer_h = j
   dim _start_game = k


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


   dim _pos_p1_x = 30
   dim _pos_p1_y = 56


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
   COLUP0 = _P0_color
   COLUP1 = _P1_color
   NUSIZ0 = $07 : REFP0 = 0 
   ;COLUBK = 0 
   COLUPF = $2C
   scorecolor = _base_color : pfscorecolor = _base_color
   _start_game = 0

   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0

   score = 0
   pfscore1 = 255
   pfscore2 = 255
   

   ;*************************************************
   ; TITOLO
   ; ------------------------------------------------
   ; Snack 'n' Roll
   ;*************************************************

__main_title
   playfield:
   ................................
   ....XX.........XX.......X..X....
   ...X.............X......X.X.....
   ....XX..X.XX...XXX..XXX.XX......
   ......X.XX..X.X..X.X....X.X.....
   ....XX..X...X..XXX..XXX.X..X....
   ................................
   .X.......X...............X.X....
   ...X.XX........X.XX..XX..X.X....
   ...XX..X.......XX...X..X.X.X....
   ...X...X.......X.....XX..X.X....
end

   ;***************************************************************
   ;
   ;  Sets playfield colors.
   ;
   pfcolors:
   $22
   $22
   $22
   $22
   $22
   $22
   $24
   $24
   $24
   $24
   $24
end

   ;*************************************************************************
   ; PLAYER AND SPRITE
   ; ------------------------------------------------
   ; player 0 -> Biscotto (nessun colore) => 4 x 4 pixel
   ; player 1 -> Bocca che mangia (colorata ?? dipende se voglio missile 1)
   ; missile 0 -> Sacchetto di uscita dal livello 
   ; missile 1 -> Bonus (randomico sullo schermo a tempo, se attivo)
   ; ball ->  Bolle del bollitore (un solo colore azzurro)
   ;*************************************************************************
   player0:
 %01100110
 %00100100
 %00011000
 %10100101
 %01001010
 %01010010
 %00100100
 %00011110
end

   player0:
   %01111110
   %10000001
   %10000001
   %01111110
end

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Your code to test goes here.
   ;
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````

   player0x = 40
   player0y = 56

   player0x = 20
   player0y = 56



   drawscreen

   if !joy0fire && _start_game = 0 then goto __main_title

   _start_game=1
   
__main_loop
   _pos_p1_x = player0x
   _pos_p1_y = player0y

   f=f+1
   scorecolor = f

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Your code to test goes here.
   ;
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````



   ;***************************************************************
   ;
   ;  Sets color of the score.
   ;




   ;***************************************************************
   ;
   ;  Puts temp4 in the three score digits on the left side.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Replace "player0x" with whatever you need to check.
   ;
   ;temp4 = player0x

   /* _sc1 = 0 : _sc2 = _sc2 & 15
   if temp4 >= 100 then _sc1 = _sc1 + 16 : temp4 = temp4 - 100
   if temp4 >= 100 then _sc1 = _sc1 + 16 : temp4 = temp4 - 100
   if temp4 >= 50 then _sc1 = _sc1 + 5 : temp4 = temp4 - 50
   if temp4 >= 30 then _sc1 = _sc1 + 3 : temp4 = temp4 - 30
   if temp4 >= 20 then _sc1 = _sc1 + 2 : temp4 = temp4 - 20
   if temp4 >= 10 then _sc1 = _sc1 + 1 : temp4 = temp4 - 10
   _sc2 = (temp4 * 4 * 4) | _sc2 */



   ;***************************************************************
   ;
   ;  Puts temp4 in the three score digits on the right side.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Replace "player0y" with whatever you need to check.
   ;
   ;temp4 = player0y

   /* _sc2 = _sc2 & 240 : _sc3 = 0
   if temp4 >= 100 then _sc2 = _sc2 + 1 : temp4 = temp4 - 100
   if temp4 >= 100 then _sc2 = _sc2 + 1 : temp4 = temp4 - 100
   if temp4 >= 50 then _sc3 = _sc3 + 80 : temp4 = temp4 - 50
   if temp4 >= 30 then _sc3 = _sc3 + 48 : temp4 = temp4 - 30
   if temp4 >= 20 then _sc3 = _sc3 + 32 : temp4 = temp4 - 20
   if temp4 >= 10 then _sc3 = _sc3 + 16 : temp4 = temp4 - 10
   _sc3 = _sc3 | temp4 */

   ;if f=20 then f=0

   /* if joy0left || joy0right  then player0:
   %00100100
   %00010010
   %00011100
   %10100101
   %01001010
   %01010010
   %00100100
   %01111100
end */


   /* ; aumenta il contatore ogni frame
  frame = frame + 1

  ; ogni 10 frame sposta la barriera
  if frame > 10 then frame = 0

    ; aggiorna la posizione
    posizione = posizione + 1
    if posizione > 30 then posizione = 0

    ; shifta e disegna nel playfield
    PF0 = barriera << posizione */

   if f<10 then player0:
   %01111110
   %10000001
   %10000001
   %01111110
end

   if f>10 then player0:
   %00000000
   %01111110
   %01111110
   %00000000
end


   ;***************************************************************
   ;
   ;  Moves player0 sprite with the joystick while keeping the
   ;  sprite within the playfield area.
   ;
   if joy0up && player0y > _pf_edge_top then player0y = player0y - 1

   if joy0down && player0y < _pf_edge_bottom then player0y = player0y + 1

   if joy0left && player0x > _pf_edge_left then player0x = player0x - 1

   if joy0right && player0x < _pf_edge_right then player0x = player0x + 1

   if collision(player0,playfield) then player0x = _pos_p1_x :player0y = _pos_p1_y


   COLUP0 = _P0_color 
   COLUP1 = _P1_color 
   COLUPF = $2C

   if f<10 then goto __BackGorund_Level_Begin
   if f>10 && f<20 then goto __BackGorund_Transitione_Start
   if f>20 then goto __BackGorund_Transitione_End


   if f=10 then goto __Decrease_Left_Time_Health_Bar 
   goto __Skip_Done
   
__Decrease_Left_Time_Health_Bar
   pfscore1 = pfscore1/2
   score=l+1
   ;pfpixel 6 1 flip
   goto __Skip_Done

__BackGorund_Level_Begin
   playfield:
   ................................
   ................................
   ................................
   ................................
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
   XXX...XXXXX..X.X...........XX...
   .X.....XXXX..X.X..........XXXX..
   ........XXX..X.X.XXX..XXX.......
   ...XXX...........XXXX.XXXX......
   .X.X.X.X.........XXX..XXX.......
end
   pfcolors:
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
   goto __Skip_Done

__BackGorund_Transitione_Start
   goto __Skip_Done

__BackGorund_Transitione_End
   goto __Skip_Done


__Skip_Done
   ;if f=10 then player0x = (rand&63) + (rand&31) + (rand&15) + (rand&1) + 21 : player0x = (rand/4) + (rand&31) + (rand&15) + (rand&1) + 21
   
   if f=20 then f=0 
   if pfscore1=0 && f=0 then pfscore1=255

   

   drawscreen
   goto __main_loop
