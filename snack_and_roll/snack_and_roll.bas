   ;*************************************************************************************************************************
   ; SETTAGGIO DEL KERNEL E OPZIONI
   ;_________________________________________________________________________________________________________________________
   ; pfcolors = colorazione del playfield
   ; romsize = 4k
   ; debug cycles = lampeggi lo sfondo in caso di cicli eccessivi
   ;*************************************************************************************************************************
   set kernel_options pfcolors
   set romsize 4k
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

   const _P0_color = $2C
   const _P1_color = $30
   const frame_limit = 54

   ;****************************************************************
   ;
   ;  PAL colors.
   ;
   ;  Use this when you want to instantly convert your NTSC colors
   ;  to PAL-60 (if you were already using the NTSC constants). Or
   ;  if you're making a PAL-60 game, use these constants so you
   ;  can quickly and easily swap them out for NTSC colors.
   ;
   const _00 = $00 ; Black
   const _02 = $02 ; Very dark gray
   const _04 = $04 ; Dark gray
   const _06 = $06 ; Gray
   const _08 = $08 ; Light gray
   const _0A = $0A ; Very light gray
   const _0C = $0C ; Near white
   const _0E = $0E ; White
   const _10 = $20 ; Dark blue-gray
   const _12 = $22 ; Slate blue
   const _14 = $24 ; Medium blue
   const _16 = $26 ; Blue
   const _18 = $28 ; Sky blue
   const _1A = $2A ; Light sky blue
   const _1C = $2C ; Powder blue
   const _1E = $2E ; Very light blue
   const _20 = $40 ; Dark green
   const _22 = $42 ; Green
   const _24 = $44 ; Medium green
   const _26 = $46 ; Lime green
   const _28 = $48 ; Light green
   const _2A = $4A ; Pale green
   const _2C = $4C ; Pastel green
   const _2E = $4E ; Mint green
   const _30 = $40 ; Dark green
   const _32 = $42 ; Green
   const _34 = $44 ; Medium green
   const _36 = $46 ; Lime green
   const _38 = $48 ; Light green
   const _3A = $4A ; Pale green
   const _3C = $4C ; Pastel green
   const _3E = $4E ; Mint green
   const _40 = $60 ; Dark yellow-green
   const _42 = $62 ; Olive green
   const _44 = $64 ; Yellow-green
   const _46 = $66 ; Chartreuse
   const _48 = $68 ; Bright yellow-green
   const _4A = $6A ; Pale yellow-green
   const _4C = $6C ; Pastel yellow-green
   const _4E = $6E ; Light lime
   const _50 = $80 ; Dark orange
   const _52 = $82 ; Orange
   const _54 = $84 ; Medium orange
   const _56 = $86 ; Orange-gold
   const _58 = $88 ; Goldenrod
   const _5A = $8A ; Light orange
   const _5C = $8C ; Pale orange
   const _5E = $8E ; Peach
   const _60 = $A0 ; Brown
   const _62 = $A2 ; Medium brown
   const _64 = $A4 ; Copper
   const _66 = $A6 ; Tan
   const _68 = $A8 ; Light brown
   const _6A = $AA ; Pale tan
   const _6C = $AC ; Sand
   const _6E = $AE ; Beige
   const _70 = $C0 ; Dark red
   const _72 = $C2 ; Red
   const _74 = $C4 ; Tomato red
   const _76 = $C6 ; Coral
   const _78 = $C8 ; Salmon
   const _7A = $CA ; Light red
   const _7C = $CC ; Pink
   const _7E = $CE ; Light pink
   const _80 = $D0 ; Dark magenta
   const _82 = $D2 ; Magenta
   const _84 = $D4 ; Orchid
   const _86 = $D6 ; Violet
   const _88 = $D8 ; Light violet
   const _8A = $DA ; Pale magenta
   const _8C = $DC ; Pink-mauve
   const _8E = $DE ; Light mauve
   const _90 = $B0 ; Dark purple
   const _92 = $B2 ; Purple
   const _94 = $B4 ; Medium purple
   const _96 = $B6 ; Lavender
   const _98 = $B8 ; Light lavender
   const _9A = $BA ; Very light purple
   const _9C = $BC ; Pale lavender
   const _9E = $BE ; Lilac
   const _A0 = $90 ; Navy blue
   const _A2 = $92 ; Deep blue
   const _A4 = $94 ; Blue
   const _A6 = $96 ; Azure
   const _A8 = $98 ; Light blue
   const _AA = $9A ; Pale blue
   const _AC = $9C ; Pastel blue
   const _AE = $9E ; Baby blue
   const _B0 = $70 ; Teal
   const _B2 = $72 ; Cyan
   const _B4 = $74 ; Aqua
   const _B6 = $76 ; Light aqua
   const _B8 = $78 ; Pale aqua
   const _BA = $7A ; Ice blue
   const _BC = $7C ; Powder blue
   const _BE = $7E ; Sky blue
   const _C0 = $50 ; Dark turquoise
   const _C2 = $52 ; Turquoise
   const _C4 = $54 ; Medium turquoise
   const _C6 = $56 ; Light turquoise
   const _C8 = $58 ; Pale turquoise
   const _CA = $5A ; Icy turquoise
   const _CC = $5C ; Frost blue
   const _CE = $5E ; Icy blue
   const _D0 = $30 ; Dark sea green
   const _D2 = $32 ; Sea green
   const _D4 = $34 ; Light sea green
   const _D6 = $36 ; Pale sea green
   const _D8 = $38 ; Mint
   const _DA = $3A ; Pale mint
   const _DC = $3C ; Frost green
   const _DE = $3E ; Icy mint
   const _E0 = $20 ; Dark blue-gray
   const _E2 = $22 ; Slate blue
   const _E4 = $24 ; Medium blue
   const _E6 = $26 ; Blue
   const _E8 = $28 ; Sky blue
   const _EA = $2A ; Light sky blue
   const _EC = $2C ; Powder blue
   const _EE = $2E ; Very light blue
   const _F0 = $40 ; Dark green
   const _F2 = $42 ; Green
   const _F4 = $44 ; Medium green
   const _F6 = $46 ; Lime green
   const _F8 = $48 ; Light green
   const _FA = $4A ; Pale green
   const _FC = $4C ; Pastel green
   const _FE = $4E ; Mint green



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
   ; _current_choco_x => coordinate temporanee del cioccolatino da catturare (colonna)
   ; _current_choco_y => coordinate temporanee del cioccolatino da catturare (riga)
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
   dim _current_choco_x = v
   dim _current_choco_y = z

   ; velocità corrente
   dim _speed = g

   ; FLAG DI CONFIGURAZIONE
   dim _b0_enableStart = k
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
   ; score => suddiviso in due parti 00|0000, la prima parte 00 sono i lanci a disposizione gli utili 0000 punti 
   ;*************************************************************************************************************************

   ; Altezze oggeti base
   missile0height = 4 
   missile1height = 2
   ballheight = 16

   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 3 : h = 3 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0

   ; Impostazione del timer iniziale e delle vite
   pfscore1 = %11111111 : pfscore2 = %10101010

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
   $2B
   $22
   $24
   $26
   $28
   $2B
   $2A
   $28
   $26
   $24
   $22
end

__game_start
   ;flag
   _b0_enableStart{0} = 0
   _b2_loadPlayfield{2} = 0
   _b4_enableLight{4} = 1
   _b5_enablePalyer1{5} = 1

   ;velocià e livello
   _level = 1
   _speed = 8

   ; 10 lanci a dispozione per il biscotto iniziali
   score = 100000

   ;Per evitare che si veda nella schermata del titolo
   scorecolor = 0

   _Bit3_P0_Dir_Right{3} = 1
   
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

   ;F2 inizio il gioco mentre F1 seleziono il livello
   if switchreset then _b0_enableStart{0} = 1 : _level = 1 : _speed = 8 : goto __skip_to_change
   if switchselect && !_b0_enableStart{0} && _frame_counter=frame_limit then pfpixel _level 6 on : goto __change_level

   ;!!!!!!!!!!!!!!!!!!! START !!!!!!!!!!!!!!!!!!!
   ;*************************************************************************************************************************
   ; MUSICA DI SOTTOFONDO
   ;_________________________________________________________________________________________________________________________
   if _music_index > 20 then _music_index = 0
   if _frame_counter&15 = 0 && !_b0_enableStart{0} then AUDF1 = jingle[_music_index] : AUDC1 = 4 :  AUDV1 = 2: _music_index = _music_index + 1
   if _frame_counter&3 = 0 && _b0_enableStart{0} then AUDV0 = 0 : AUDF1 = melody[_music_index] : AUDC1 = melody[_music_index] :  AUDV1 = 2 : _music_index = _music_index + 1

   ;Se il gioco non è ancora iniziato skippa tutto
   if !_b0_enableStart{0} then goto __done

   ;*************************************************************************************************************************
   ; BOCCA (PLAYER1)
   ;_________________________________________________________________________________________________________________________
   ; La bocca si muove all'interno del playfield in modo randomico, 
   ; l'aggiornamento viene in base alla velocità dello schema di gioco
   ; (inizialmente 8 secondi)
   ;*************************************************************************************************************************
   if _frame_counter = 0 && _seconds_counter&(_speed-1)= 1 && _b5_enablePalyer1{5} then player1x = (rand & 125) + 20 : player1y = (rand & 80) + 8

   ;*************************************************************************************************************************
   ; CIOCCOLATO (MISSILE1)
   ;_________________________________________________________________________________________________________________________
   ; I cioccolatini nel playfield sono 8 e verranno visualizzati uno alla volta.Il player una volta che viene a contatto con 
   ; il cioccolato aumenta di 10 spari
   ;*************************************************************************************************************************
   if missile1y = 200 || _seconds_counter&15 = 0 then _current_choco_x = (rand & 125) + 20 : _current_choco_y = (rand & 80) + 8
   if _choco_count < 8 && _current_choco_x < 146 && _frame_counter=frame_limit then missile1x = _current_choco_x: missile1y = _current_choco_y
   if collision(player0, missile1) then callmacro sound 12 4 2 : missile1y = 200 : _choco_count = _choco_count + 1 : score = score + 100000

   ;*************************************************************************************************************************
   ; LUCE (PLAYFIELD)
   ;_________________________________________________________________________________________________________________________
   ; dopo 32 secondi la luce si spegne automaticamente per accenderla ci si 
   ; deve posizonare sotto la lamp (dal basso verso l'alto)
   ; !!IMP Cambia il colore del playfield tranne la fascia centrale
   ;*************************************************************************************************************************
   ;>>>> SPEGNIMENTO <<<<
   if _seconds_counter && (_seconds_counter&31 = 0) then _b4_enableLight{4} = 0

   ;Background visibile con effetto flash se il flag della lamp è spento
   if _b4_enableLight{4} || _frame_counter&31 = 0 then pfcolors:
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
   if !_b4_enableLight{4} && _frame_counter&7 then pfcolors:
   0
end

   ;*************************************************************************************************************************
   ; CONTENITORE FINALE (BALL)
   ;_________________________________________________________________________________________________________________________
   ; il sacchetto finale individuato come ball viene visualizzato solo dopo aver trovato gli 8 cioccolatini nel playfield
   ; e la bocca è stata colpita
   ;*************************************************************************************************************************
   if _choco_count = 8 && !_b5_enablePalyer1{5} then ballx = door[_level] : bally = 28

   ;*************************************************************************************************************************
   ; PLAYFIELD DIAMICO
   ;_________________________________________________________________________________________________________________________
   ; _playfield_section sezione del playfield
   ; _playfield_up = 0 parte alta della sezione
   ; _playfield_down = 2 parte bassa della sezione
   ;*************************************************************************************************************************
   _current_bit_object = 1 
   _playfield_section = 1
   _playfield_up = 0 ; parte alta
   _playfield_down = 2 ; parte bassa

   ;if _b2_loadPlayfield{2} then goto __skip_oggetti
__loop_objects
   temp1 = _speed - 1
   _current_object_level = (_level - 1) * 8
   ;
   if _b2_loadPlayfield{2} then goto __skip_to_dynamic_objects

   if (objects[_current_object_level]&_current_bit_object)> 0 then callmacro cup_knife _playfield_section _playfield_down 3 ; TAZZE
   temp2 = _current_object_level +1
   if (objects[temp2]&_current_bit_object)> 0 then callmacro cup_knife _playfield_section _playfield_up 2 ; COLTELLI
   temp2 = _current_object_level+2
   if (objects[temp2]&_current_bit_object)> 0 then callmacro chocolate _playfield_section _playfield_down; MURI
   
   ; !!! SALVA LA POSIZONE DELLE LAMPADE PER IL DISCORSO DI ATTIVAZIONE E DISATTIVAZIONE
   temp2 = _current_object_level+ 4
   if (objects[temp2]&_current_bit_object)> 0 then callmacro lamp _playfield_section _playfield_up ; LAMPADE
   temp2 = _current_object_level+ 5
   if (objects[temp2]&_current_bit_object)> 0 then callmacro table _playfield_section _playfield_down ; TAVOLI
   temp2 = _current_object_level+ 6
   if (objects[temp2]&_current_bit_object)> 0 then temp4 = objects[temp2]: callmacro divisor temp4; PIANO

__skip_to_dynamic_objects
   temp2 = _current_object_level+3
   if (objects[temp2]&_current_bit_object)> 0 then callmacro choco_drops _playfield_section _playfield_up; GOCCE


   _current_bit_object = _current_bit_object * 2
   _playfield_section = _playfield_section + 7
   
   if _current_bit_object = 16 && _playfield_up = 0 then _playfield_section = 1 : _playfield_up = 6 : _playfield_down = 8
   if _current_bit_object > 0 then goto __loop_objects
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
   NUSIZ1=$20
   if _level> 6 then NUSIZ1=$25
   if _level> 12 then NUSIZ1=$27

   ; ---- 4 ----
   if _frame_counter&15 && pfscore1 <=8 then pfscorecolor = rand&16
   ; ---- 5 ----
   if _seconds_counter&7 = 0 then _b6_enableSlowMotion{6} = 0
   ; ---- 6 ----
   if !_b4_enableLight{5} then COLUP1 = _00 else COLUP1 = _P1_color
   ; ---- 7 ----
   if _b6_enableSlowMotion{6} then COLUP0 = _E0 else COLUP0 = _P0_color
   ; ---- 1 ----
   if _frame_counter = 0 && _seconds_counter & 15 = 0 then goto __decrease_timer_bar
   ; ---- 2 ----
   if pfscore1 = 0 then goto __decrease_health_bar
   ; ---- 3 ----
   if pfscore2 = 0 || _level > 20 then goto __game_start

   if !joy0up && !joy0down && !joy0left && !joy0right then goto __Skip_Joystick_Precheck

   _BitOp_P0_M0_Dir = _BitOp_P0_M0_Dir & %11110000

__Skip_Joystick_Precheck

   ; ---- 8 ----
   if !joy0fire || score <= 0 then goto __Skip_Fire
   if _b7_gameMissile0Moving{7} || _b6_enableSlowMotion{6} then goto __Skip_Fire

   _b7_gameMissile0Moving{7} = 1 : score = score - 10000
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
   if temp6 = 5 then _b4_enableLight{4}=1 : goto __delete_missile
   if missile0y < _M_Edge_Top || missile0y > _Edge_Bottom then goto __delete_missile
   if missile0x > _Edge_Right || missile0x < _M_Edge_Left then goto __delete_missile

   ;non colpisce nulla
   if !pfread(temp5,temp6) then goto __skip_missile

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

   if !joy0right && !joy0left && !joy0up && !joy0down then goto __skip_animation_player0

   if _frame_counter & 7 = 0 then player0:
   %00011000
   %10111101
   %01011010
   %01111110
end

__skip_animation_player0

   if _frame_counter & 7 = 0 then player1:
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
   if collision(player0, player1) then goto __decrease_health_bar
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
   goto __delete_mouth

__decrease_health_bar
  pfscore2=pfscore2/4
  if pfscore2 = 0 then goto __game_start

__delete_mouth 
  player1y=200
  goto __done

__decrease_timer_bar
   pfscore1 = pfscore1 * 2
   goto __done

__change_level
   _level=_level+1
   if _speed<2 then goto __skip_to_change
   _speed=_speed-2
   if !_b0_enableStart{0} then goto __main_loop

__skip_to_change
   pfscorecolor = _0C
   scorecolor=(scorecolor + $10) & $F0
   pfscore1=%11111111
   bally=200
   player0x=10:player0y=64
   _b2_loadPlayfield{2}=0
   _b5_enablePalyer1{5}=1
   _choco_count=0
   _seconds_counter = 0
   pfclear

__done
   
   drawscreen
   goto __main_loop

   ;*************************************************************************************************************************
   ; SUDDIVISIONE DEL PLAYFIELD E DOOR
   ;_________________________________________________________________________________________________________________________
   ; b0 | b1 | b2 | b3
   ;----|----|----|---
   ; b4 | b5 | b6 | b7
   ;_________________________________________________________________________________________________________________________
   ;0.TAZZE 1.COLTELLI 2.CIOCCOLATO 3.GOCCE 4.LAMPADE 5.TAVOLI 7.PIANO
   ; LIVELLI (20)

   data objects
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111, 
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,   
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,   
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,   
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,   
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,   
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,   
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,   
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111,
   %10100100,%00000000,%00000000,%00000000,%00010000,%01011000,%01111111 
end

   ;il primo valore indica solo che non è attivo
   data door
   200,18,156,18,156,18,156,18,156,18,156,18,156,18,156,18,156,18,156,18,156
end
   ;*************************************************************************************************************************
   ; MUSICHE
   ;_________________________________________________________________________________________________________________________
   ; jingle => allegra
   ; melody => suspance
   ;_________________________________________________________________________________________________________________________
   data jingle
   16, 18, 20, 22, 24, 22, 20, 18, 16, 18, 20, 22, 20, 18, 16, 18, 16, 16, 18, 16
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
      ;o = rand&3
      y = rand&3
      u = {1} + rand&3
      pfpixel {1} y flip
end

   macro chocolate
      o = {2} + 2
      ;BARRETTE
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
      ;table
      pfhline {1} u o on 
      u = u + 1
      pfpixel {1} u on : pfpixel o u on
      ; SEDIA
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
   AUDC1 = {2}
   AUDF1 = {3}
end 