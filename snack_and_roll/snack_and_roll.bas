   ;***************************************************************
   ;
   ;  Multicolored sprite and multicolored playfield.
   ;
   set kernel_options player1colors pfcolors

   ;***************************************************************
   ;
   ;  The game will have 8 banks (32k/4k = 8 banks).
   ;
   set romsize 4k
   set pal


   const pfscore = 1

   ;***************************************************************
   ;
   ;  Defines the edges of the playfield for an 8 x 8 sprite.
   ;  If your sprite is a different size, you'll need to adjust
   ;  the numbers.
   ;
   const _P_Edge_Top = 9
   const _P_Edge_Bottom = 88
   const _P_Edge_Left = 1
   const _P_Edge_Right = 153

   ;const noscore = 1

   ;```````````````````````````````````````````````````````````````
   ;  Assigns a variable to the score background.
   ;
   dim _SC_Back = var45




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
   dim _sc1 = score
   dim _sc2 = score+1
   dim _sc3 = score+2
   dim _addpl = %00010000

   dim frame = 0
   dim posizione = 0
   dim barriera = %0000011111

   ;*************************************************
   ; INIZIALIZZAZIONE
   ; ------------------------------------------------
   ; CTRLPF = Control Playfield, Ball, Collisions
   ; NUSIZ0 = dimesione missile + dimensione player
   ; REFP0  = Reflection Player 0
   ; COLUP0 = Colore del Player 0
   ; COLUBK = Colore background
   ;*************************************************
   CTRLPF = $21 : NUSIZ0 = $07 : REFP0 = 0 : COLUBK = 0 : scorecolor = 0 : _SC_Back = 0 : pfscorecolor = 0
   ;
   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0

   ;*************************************************
   ; TITOLO
   ; ------------------------------------------------
   ; Snack 'n' Roll
   ;*************************************************

__Title_Screen_Playfield
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
   ...XX..X.......XX...XXXX.X.X....
   ...X...X.......X.....XX..X.X....
end

   ;***************************************************************
   ;
   ;  Sets playfield colors.
   ;
   pfcolors:
   $22
   $24
   $26
   $28
   $28
   $26
   $24
   $22
   $24
   $28
   $26
end

   player1:
 %01100110
 %00100100
 %00011000
 %10100101
 %01001010
 %01010010
 %00100100
 %00011110
end

   player1color:
   $24
   $26
   $28
   $2A
   $2C
   $2A
   $24
   $24
end
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Your code to test goes here.
   ;
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````

   COLUBK = 0
   COLUPF = $0E

   player1x = 20
   player1y = 53
   scorecolor = $5C

__Main_Loop

   ;COLUP0 = $26
   
   f=f+1
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
   temp4 = player0x

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
   temp4 = player0y

   /* _sc2 = _sc2 & 240 : _sc3 = 0
   if temp4 >= 100 then _sc2 = _sc2 + 1 : temp4 = temp4 - 100
   if temp4 >= 100 then _sc2 = _sc2 + 1 : temp4 = temp4 - 100
   if temp4 >= 50 then _sc3 = _sc3 + 80 : temp4 = temp4 - 50
   if temp4 >= 30 then _sc3 = _sc3 + 48 : temp4 = temp4 - 30
   if temp4 >= 20 then _sc3 = _sc3 + 32 : temp4 = temp4 - 20
   if temp4 >= 10 then _sc3 = _sc3 + 16 : temp4 = temp4 - 10
   _sc3 = _sc3 | temp4 */

   if f=20 then f=0

   if joy0left || joy0right  then player1:
   %00100100
   %00010010
   %00011100
   %10100101
   %01001010
   %01010010
   %00100100
   %01111100
end


   /* ; aumenta il contatore ogni frame
  frame = frame + 1

  ; ogni 10 frame sposta la barriera
  if frame > 10 then frame = 0

    ; aggiorna la posizione
    posizione = posizione + 1
    if posizione > 30 then posizione = 0

    ; shifta e disegna nel playfield
    PF0 = barriera << posizione */


   ;***************************************************************
   ;
   ;  Moves player0 sprite with the joystick while keeping the
   ;  sprite within the playfield area.
   ;
   if joy0up && player1y > _P_Edge_Top then player1y = player1y - 1

   if joy0down && player1y < _P_Edge_Bottom then player1y = player1y + 1

   if joy0left && player1x > _P_Edge_Left then player1x = player1x - 1

   if joy0right && player1x < _P_Edge_Right then player1x = player1x + 1


   ;***************************************************************
   ;
   ;  Displays the screen.
   ;
   drawscreen


   goto __Main_Loop
