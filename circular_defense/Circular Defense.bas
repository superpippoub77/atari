   ;*************************************************************************************************************************
   ; CIRCULAR DEFENSE - Atari 2600 (batari Basic, PAL, 8K F8)
   ;_________________________________________________________________________________________________________________________
   ; Il cannone al centro spara contro 6 citta' disposte su un anello. Il
   ; difensore gira attorno al cannone e para i colpi: si muove SOLO se lo
   ; muovi tu.
   ;   PADDLE (predefinito): il difensore va all'angolo della manopola
   ;     (tutta la corsa del paddle = un giro); pulsante = inizio partita.
   ;   JOYSTICK: destra/sinistra = gira in senso orario/antiorario,
   ;     con il fuoco premuto gira al doppio; fuoco = inizio partita.
   ;   Game Select (fuori partita) cambia controller: la barra in basso a
   ;   destra e' accesa col paddle.
   ; Ogni colpo non parato toglie un pezzetto della citta' colpita (prima
   ; i palazzi, poi la base); una citta' senza pezzetti e' distrutta e i
   ; colpi diretti li' vanno sulla citta' piu' vicina.
   ; 8 livelli: ogni livello chiede di parare un certo numero di colpi.
   ; Velocita' e frequenza crescono; dal livello 2 due colpi insieme, nei
   ; livelli 4, 7, 8 colpi DEVIATI (a meta' strada cambiano bersaglio),
   ; nei livelli 6 e 8 il BUIO (i colpi si vedono a tratti).
   ; Fine livello: 5 punti per ogni pezzetto di citta' rimasto.
   ; Dopo l'8 livello: VITTORIA (+500). Tutte le citta' distrutte: GAME OVER.
   ; Levette di difficolta' (A = piu' difficile): sinistra A = colpi piu'
   ; veloci; destra A = il cannone spara piu' spesso.
   ;*************************************************************************************************************************

   set tv pal
   ; paddle letti dal kernel (richiede no_blank_lines; usa la memoria del
   ; missile0: il secondo proiettile e' la ball)
   set kernel_options no_blank_lines readpaddle
   set romsize 8k
   const pfscore = 1

   ; centro dello schermo (coordinate dei missili)
   const _X0 = 82
   const _Y0 = 44
   const _Levels = 8
   const _Spawn_Min = 25

   ;*************************************************************************************************************************
   ; VARIABILI
   ;_________________________________________________________________________________________________________________________
   ; Proiettili: posizione 8.8, velocita' (indice 0-17 nelle tabelle vx/vy:
   ; 0-5 verso una citta', 6-17 deviati) e passo (0-63; 255 = libero).
   ; Proiettile 0 = missile1, proiettile 1 = ball.
   ;*************************************************************************************************************************
   dim _angle = a
   dim _frame = b
   dim _level = c
   dim _spawnT = d
   dim _alive = e
   dim _quota = f
   dim _state = g
   ; bit 0 in partita, 1 game over, 2 ultimo colpo dal proiettile 1,
   ; 3 vittoria, 5 controllo col paddle, 6 Select gia' premuto,
   ; 7 pulsante gia' premuto
   dim _b0_playing = g
   dim _b1_over = g
   dim _b2_last = g
   dim _b3_victory = g
   dim _b5_paddle = g
   dim _b6_prevSel = g
   dim _b7_prevFire = g
   dim _acc = h
   dim _b0x = i.j
   dim _b0y = k.l
   dim _b0v = m
   dim _b0t = n
   dim _b1x = o.p
   dim _b1y = q.r
   dim _b1v = s
   dim _b1t = t
   dim _vel = u.v
   dim _interval = w
   dim _sfxId = x
   dim _sfxT = y
   dim _music = z

   scorecolor = $0E
   pfscorecolor = $2C
   missile1height = 4
   _state = %00100000
   _b0t = 255 : _b1t = 255
   gosub __draw_title bank2

   ;*************************************************************************************************************************
   ; CICLO PRINCIPALE
   ;*************************************************************************************************************************
__main
   _frame = _frame + 1

   ; colori del playfield: titolo che pulsa, citta' azzurre, game over
   ; rosso, vittoria dorata
   temp1 = _frame / 8
   temp1 = temp1 & 6
   COLUPF = $9C
   if !_state{0} then COLUPF = $26 + temp1
   if _b1_over{1} then COLUPF = $44 + temp1
   if _b3_victory{3} then COLUPF = $28 + temp1
   ; il difensore pulsa; il cannone e' oro, rosso appena spara
   temp1 = _frame / 4
   temp1 = temp1 & 6
   COLUP0 = $56 + temp1
   COLUP1 = $2C
   if _sfxId = 1 then COLUP1 = $46
   ; missile1 largo 4 pixel, cannone a doppia larghezza; ball larga 4
   ; (bit 0 = playfield riflesso, serve al kernel)
   NUSIZ0 = 0 : NUSIZ1 = $25
   CTRLPF = $21 : ballheight = 4

   ;---------------------------------------------------------------------------
   ; PULSANTE (fuoco del joystick o pulsante del paddle sinistro, che arriva
   ; sullo stesso filo del joystick a destra) e GAME SELECT
   ;---------------------------------------------------------------------------
   temp1 = 0
   if joy0fire then temp1 = 1
   if !_b5_paddle{5} then goto __fire_read
   temp1 = 0
   if joy0right then temp1 = 1
__fire_read
   if _b0_playing{0} then goto __fire_done
   if switchreset then goto __new_game
   if !temp1 then _b7_prevFire{7} = 0 : goto __select
   if _b7_prevFire{7} then goto __select
   ; titolo -> partita; game over / vittoria -> titolo
   if !_state{1} && !_state{3} then goto __new_game
   goto __to_title
__fire_done
__select
   if temp1 then _b7_prevFire{7} = 1
   if _b0_playing{0} then goto __no_select
   if !switchselect then _b6_prevSel{6} = 0 : goto __no_select
   if _b6_prevSel{6} then goto __no_select
   _b6_prevSel{6} = 1
   _state = _state ^ %00100000
__no_select
   pfscore2 = 0
   if _b5_paddle{5} then pfscore2 = %11111111

   ;---------------------------------------------------------------------------
   ; DIFENSORE: si muove solo se lo muovi tu
   ;---------------------------------------------------------------------------
   if !_b5_paddle{5} then goto __joy_move
   ; paddle (letto dal kernel durante drawscreen): posizione assoluta
   temp1 = paddle
   if temp1 > 79 then temp1 = 79
   _angle = padangle[temp1]
   goto __place
__joy_move
   temp1 = 0
   if joy0right then temp1 = 3
   if joy0left then temp1 = 253
   if !joy0fire then goto __joy_add
   if joy0right then temp1 = 6
   if joy0left then temp1 = 250
__joy_add
   _angle = _angle + temp1
__place
   temp2 = _angle / 4
   player0x = shx[temp2] : player0y = shy[temp2]

   ;---------------------------------------------------------------------------
   ; CANNONE: canna verso l'ultimo colpo (nel titolo e' nascosto)
   ;---------------------------------------------------------------------------
   player1x = _X0 - 8 : player1y = _Y0 + 10
   if !_state{0} && !_state{1} then player1y = 200
   temp1 = _b0v
   if _b2_last{2} then temp1 = _b1v
   temp2 = aim8[temp1]
   ; >>> generato da tools/gen_sprites.py
   ; --- torretta del cannone: la canna punta verso l'ultimo colpo ---
   ; (generato da tools/gen_sprites.py)
   on temp2 goto __cannon0 __cannon1 __cannon2 __cannon3 __cannon4 __cannon5 __cannon6 __cannon7
__cannon0
   ; canna verso destra
   player1:
   %00000000
   %00000000
   %00000000
   %00000000
   %00000000
   %00011000
   %00011000
   %00111100
   %00111111
   %00111111
   %00111111
   %00111111
   %00111100
   %00011000
   %00011000
   %00000000
   %00000000
   %00000000
   %00000000
   %00000000
end
   goto __cannon_done
__cannon1
   ; canna verso basso-destra
   player1:
   %00000000
   %00000000
   %00000010
   %00000010
   %00000110
   %00011110
   %00011110
   %00111100
   %00111100
   %00111100
   %00111100
   %00111100
   %00111100
   %00011000
   %00011000
   %00000000
   %00000000
   %00000000
   %00000000
   %00000000
end
   goto __cannon_done
__cannon2
   ; canna verso basso
   player1:
   %00011000
   %00011000
   %00011000
   %00011000
   %00011000
   %00011000
   %00011000
   %00111100
   %00111100
   %00111100
   %00111100
   %00111100
   %00111100
   %00011000
   %00011000
   %00000000
   %00000000
   %00000000
   %00000000
   %00000000
end
   goto __cannon_done
__cannon3
   ; canna verso basso-sinistra
   player1:
   %00000000
   %00000000
   %01000000
   %01000000
   %01100000
   %01111000
   %01111000
   %00111100
   %00111100
   %00111100
   %00111100
   %00111100
   %00111100
   %00011000
   %00011000
   %00000000
   %00000000
   %00000000
   %00000000
   %00000000
end
   goto __cannon_done
__cannon4
   ; canna verso sinistra
   player1:
   %00000000
   %00000000
   %00000000
   %00000000
   %00000000
   %00011000
   %00011000
   %00111100
   %11111100
   %11111100
   %11111100
   %11111100
   %00111100
   %00011000
   %00011000
   %00000000
   %00000000
   %00000000
   %00000000
   %00000000
end
   goto __cannon_done
__cannon5
   ; canna verso alto-sinistra
   player1:
   %00000000
   %00000000
   %00000000
   %00000000
   %00000000
   %00011000
   %00011000
   %00111100
   %00111100
   %00111100
   %00111100
   %00111100
   %00111100
   %01111000
   %01111000
   %01100000
   %01000000
   %01000000
   %00000000
   %00000000
end
   goto __cannon_done
__cannon6
   ; canna verso alto
   player1:
   %00000000
   %00000000
   %00000000
   %00000000
   %00000000
   %00011000
   %00011000
   %00111100
   %00111100
   %00111100
   %00111100
   %00111100
   %00111100
   %00011000
   %00011000
   %00011000
   %00011000
   %00011000
   %00011000
   %00011000
end
   goto __cannon_done
__cannon7
   ; canna verso alto-destra
   player1:
   %00000000
   %00000000
   %00000000
   %00000000
   %00000000
   %00011000
   %00011000
   %00111100
   %00111100
   %00111100
   %00111100
   %00111100
   %00111100
   %00011110
   %00011110
   %00000110
   %00000010
   %00000010
   %00000000
   %00000000
end
__cannon_done

   ; --- difensore: due fotogrammi alternati (luci che girano) ---
   if _frame & 8 then goto __shield_b
   player0:
   %00111100
   %01000010
   %10011001
   %10111101
   %10111101
   %10011001
   %01000010
   %00111100
end
   goto __shield_done
__shield_b
   player0:
   %00100100
   %01100110
   %00011000
   %10111101
   %10111101
   %00011000
   %01100110
   %00100100
end
__shield_done
   ; <<< fine

   if !_b0_playing{0} then goto __show

   ;---------------------------------------------------------------------------
   ; CANNONE: un colpo ogni _interval frame, se c'e' un posto libero
   ; (dal livello 2 due colpi insieme)
   ;---------------------------------------------------------------------------
   _spawnT = _spawnT + 1
   if _spawnT < _interval then goto __no_spawn
   temp1 = rand
__mod6
   if temp1 >= 6 then temp1 = temp1 - 6 : goto __mod6
   if _b0t <> 255 then goto __try_slot1
   _b0v = temp1 : _b0t = 0 : i = _X0 : j = 0 : k = _Y0 : l = 0 : _b2_last{2} = 0
   goto __spawned
__try_slot1
   temp2 = lvmax[_level]
   if temp2 < 2 then goto __no_spawn
   if _b1t <> 255 then goto __no_spawn
   _b1v = temp1 : _b1t = 0 : o = _X0 : p = 0 : q = _Y0 : r = 0 : _b2_last{2} = 1
__spawned
   _spawnT = 0
   if _interval > _Spawn_Min then _interval = _interval - 1
   if _sfxId < 2 then _sfxId = 1 : _sfxT = 6
__no_spawn

   ;---------------------------------------------------------------------------
   ; PROIETTILI: velocita' del livello (ottavi di passo per frame), 2 in
   ; piu' con la levetta sinistra in A. Al passo 32, nei livelli con i
   ; colpi deviati, meta' dei colpi cambia bersaglio.
   ;---------------------------------------------------------------------------
   temp1 = lvspeed[_level]
   if !switchleftb then temp1 = temp1 + 2
   _acc = _acc + temp1
__move_loop
   if _acc < 8 then goto __show
   _acc = _acc - 8
   if _b0t = 255 then goto __move1
   temp1 = _b0v
   u = vxh[temp1] : v = vxl[temp1] : _b0x = _b0x + _vel
   u = vyh[temp1] : v = vyl[temp1] : _b0y = _b0y + _vel
   _b0t = _b0t + 1
   if _b0t <> 32 then goto __b0_end
   temp6 = _b0v
   gosub __deviate
   _b0v = temp6
__b0_end
   if _b0t < 64 then goto __move1
   _b0t = 255 : temp6 = tcity[_b0v] : gosub __hit_city bank2
__move1
   if _b1t = 255 then goto __move_loop
   temp1 = _b1v
   u = vxh[temp1] : v = vxl[temp1] : _b1x = _b1x + _vel
   u = vyh[temp1] : v = vyl[temp1] : _b1y = _b1y + _vel
   _b1t = _b1t + 1
   if _b1t <> 32 then goto __b1_end
   temp6 = _b1v
   gosub __deviate
   _b1v = temp6
__b1_end
   if _b1t < 64 then goto __move_loop
   _b1t = 255 : temp6 = tcity[_b1v] : gosub __hit_city bank2
   goto __move_loop

   ;---------------------------------------------------------------------------
   ; DISEGNO, SUONI E MUSICA
   ;---------------------------------------------------------------------------
__show
   missile1x = i - 2 : missile1y = k + 2
   if _b0t = 255 then missile1y = 200
   ballx = o - 2 : bally = q + 2
   if _b1t = 255 then bally = 200
   ; BUIO: i colpi si vedono un frame su quattro
   temp1 = lvflags[_level] & 2
   if !temp1 || !_b0_playing{0} then goto __lit
   temp1 = _frame & 3
   if temp1 then missile1y = 200 : bally = 200
__lit

   gosub __sound bank2

   ; paddle da leggere: il primo della porta sinistra
   currentpaddle = 0
   drawscreen

   ;---------------------------------------------------------------------------
   ; DIFENSORE CONTRO PROIETTILI: confronto delle posizioni fatto dal
   ; programma (non con le collisioni del TIA, che vedono solo cio' che e'
   ; disegnato: al buio i colpi sono nascosti 3 frame su 4). Parato se il
   ; centro del colpo e' a meno di 6 pixel dal centro del difensore.
   ;---------------------------------------------------------------------------
   if !_b0_playing{0} then goto __main
   if _b0t = 255 then goto __no_block0
   temp1 = player0x + 4
   temp1 = i - temp1
   if temp1 > 127 then temp1 = 0 - temp1
   if temp1 >= 6 then goto __no_block0
   temp1 = player0y - 4
   temp1 = k - temp1
   if temp1 > 127 then temp1 = 0 - temp1
   if temp1 >= 6 then goto __no_block0
   _b0t = 255 : gosub __blocked
__no_block0
   if !_b0_playing{0} then goto __main
   if _b1t = 255 then goto __main
   temp1 = player0x + 4
   temp1 = o - temp1
   if temp1 > 127 then temp1 = 0 - temp1
   if temp1 >= 6 then goto __main
   temp1 = player0y - 4
   temp1 = q - temp1
   if temp1 > 127 then temp1 = 0 - temp1
   if temp1 >= 6 then goto __main
   _b1t = 255 : gosub __blocked
   goto __main

   ;*************************************************************************************************************************
   ; COLPI DEVIATI (temp6 = velocita' attuale, 0-5): nei livelli con il
   ; flag 1, al passo 32 un colpo su due prende la velocita' 6 + 2*d + s
   ; e finisce sulla citta' vicina (tabella tcity)
   ;*************************************************************************************************************************
__deviate
   temp1 = lvflags[_level] & 1
   if !temp1 then return
   temp1 = rand
   temp2 = temp1 & 1
   if !temp2 then return
   temp2 = temp1 & 2
   temp2 = temp2 / 2
   temp6 = temp6 * 2
   temp6 = temp6 + 6
   temp6 = temp6 + temp2
   return

   ;*************************************************************************************************************************
   ; COLPO PARATO: +10; finita la quota del livello si passa al successivo
   ;*************************************************************************************************************************
__blocked
   score = score + 10
   if _sfxId < 3 then _sfxId = 2 : _sfxT = 12
   _quota = _quota - 1
   if _quota then return
   ; LIVELLO SUPERATO: bonus per i pezzetti rimasti, poi livello successivo
   _b0t = 255 : _b1t = 255 : missile1y = 200 : bally = 200
   gosub __level_bonus bank2
   _level = _level + 1
   if _level > _Levels then goto __victory
   gosub __start_level
   return

__victory
   _state = _state & %00100000
   _state = _state | %10001000
   score = score + 500
   _music = 0
   gosub __draw_victory bank2
   return

   ;*************************************************************************************************************************
   ; NUOVA PARTITA, INIZIO LIVELLO, RITORNO AL TITOLO
   ;*************************************************************************************************************************
__new_game
   _state = _state & %00100000
   _state = _state | %10000001
   score = 0
   _level = 1
   pfscore1 = 0
   gosub __draw_cities bank2
   gosub __start_level
   goto __main

__start_level
   _quota = lvquota[_level]
   _interval = lvint[_level]
   if !switchrightb then _interval = _interval - 15
   _spawnT = 0 : _acc = 0 : _b0t = 255 : _b1t = 255
   ; barra dei livelli: un segmento in piu'
   pfscore1 = pfscore1 * 2
   pfscore1 = pfscore1 | 1
   _sfxId = 5 : _sfxT = 30
   return

__to_title
   _state = _state & %00100000
   _state = _state | %10000000
   _b0t = 255 : _b1t = 255 : _music = 0
   gosub __draw_title bank2
   goto __main

   ;*************************************************************************************************************************
   ; LIVELLI (indice 1-8; lo 0 non si usa)
   ;_________________________________________________________________________________________________________________________
   ; lvspeed = ottavi di passo per frame (64 passi dal centro alla citta')
   ; lvint   = frame tra un colpo e l'altro all'inizio del livello
   ; lvmax   = colpi in volo insieme
   ; lvflags = bit 0 colpi deviati, bit 1 buio
   ; lvquota = colpi da parare per superare il livello
   ;*************************************************************************************************************************
   data lvspeed
   0, 6, 7, 8, 8, 10, 10, 12, 14
end
   data lvint
   0, 80, 70, 65, 60, 55, 50, 45, 40
end
   data lvmax
   0, 1, 2, 2, 2, 2, 2, 2, 2
end
   data lvflags
   0, 0, 0, 0, 1, 0, 2, 1, 3
end
   data lvquota
   0, 8, 10, 12, 12, 14, 14, 16, 20
end

   ; >>> generato da tools/gen_tables.py bank1
   ; velocita' 8.8 dei proiettili: 0-5 verso la citta', 6-17 deviati
   data vxh
   0, 0, 255, 255, 0, 0, 255, 0, 254, 1, 255, 0, 0, 255, 1, 254, 0, 255
end
   data vxl
   192, 0, 64, 64, 0, 192, 64, 192, 128, 128, 64, 192, 192, 64, 128, 128, 192, 64
end
   data vyh
   0, 0, 0, 255, 255, 255, 0, 254, 0, 0, 254, 0, 255, 1, 255, 255, 1, 255
end
   data vyl
   96, 128, 96, 160, 128, 160, 160, 224, 64, 64, 224, 160, 96, 32, 192, 192, 32, 96
end
   ; citta' colpita alla fine del volo e direzione della canna (0-7)
   data tcity
   0, 1, 2, 3, 4, 5, 1, 5, 2, 0, 3, 1, 4, 2, 5, 3, 0, 4
end
   data aim8
   1, 2, 3, 5, 6, 7, 1, 1, 2, 2, 3, 3, 5, 5, 6, 6, 7, 7
end
   ; orbita del difensore: 64 posizioni (angolo/4)
   data shx
   106, 106, 105, 105, 104, 103, 101, 100, 98, 96, 94, 91, 89, 86, 83, 81,
   78, 75, 73, 70, 67, 65, 62, 60, 58, 56, 55, 53, 52, 51, 51, 50,
   50, 50, 51, 51, 52, 53, 55, 56, 58, 60, 62, 65, 67, 70, 73, 75,
   78, 81, 83, 86, 89, 91, 94, 96, 98, 100, 101, 103, 104, 105, 105, 106
end
   data shy
   48, 50, 52, 54, 56, 57, 59, 61, 62, 63, 65, 66, 66, 67, 68, 68,
   68, 68, 68, 67, 66, 66, 65, 63, 62, 61, 59, 57, 56, 54, 52, 50,
   48, 46, 44, 42, 40, 39, 37, 35, 34, 33, 31, 30, 30, 29, 28, 28,
   28, 28, 28, 29, 30, 30, 31, 33, 34, 35, 37, 39, 40, 42, 44, 46
end
   ; paddle (0-77) -> angolo del difensore: tutta la corsa = un giro
   data padangle
   0, 3, 7, 10, 13, 16, 20, 23, 26, 30, 33, 36, 39, 43, 46, 49,
   53, 56, 59, 62, 66, 69, 72, 75, 79, 82, 85, 89, 92, 95, 98, 102,
   105, 108, 112, 115, 118, 121, 125, 128, 131, 135, 138, 141, 144, 148, 151, 154,
   158, 161, 164, 167, 171, 174, 177, 181, 184, 187, 190, 194, 197, 200, 203, 207,
   210, 213, 217, 220, 223, 226, 230, 233, 236, 240, 243, 246, 249, 253, 255, 255
end
   ; <<< fine

   bank 2

   ;*************************************************************************************************************************
   ; CITTA'
   ;_________________________________________________________________________________________________________________________
   ; 6 citta' di 2 righe (palazzi + base), 8 pezzetti ciascuna nelle tabelle
   ; pcol/prow (dal piu' alto; colonna 255 = posto vuoto). _alive: un bit
   ; per citta' ancora in piedi.
   ; (pfpixel/pfread usano temp1-temp3: qui le coordinate passano in u e v)
   ;*************************************************************************************************************************
__draw_cities
   pfclear
   _alive = %00111111
   temp5 = 0
__dc_loop
   u = pcol[temp5] : v = prow[temp5]
   if u <> 255 then pfpixel u v on
   temp5 = temp5 + 1
   if temp5 < 48 then goto __dc_loop
   return otherbank

   ;-------------------------------------------------------------------------
   ; colpo arrivato sulla citta' temp6: toglie il primo pezzetto rimasto;
   ; se la citta' e' gia' distrutta, colpisce la piu' vicina ancora in piedi
   ;-------------------------------------------------------------------------
__hit_city
   temp4 = 0
__hc_search
   temp5 = temp6 + near6[temp4]
   if temp5 >= 6 then temp5 = temp5 - 6
   temp1 = bitmask[temp5]
   temp1 = temp1 & _alive
   if temp1 then goto __hc_city
   temp4 = temp4 + 1
   if temp4 < 6 then goto __hc_search
   return otherbank
__hc_city
   ; temp5 = citta', temp6 = pezzetto, temp4 = fine dei suoi pezzetti
   temp6 = temp5 * 8
   temp4 = temp6 + 8
__hc_piece
   u = pcol[temp6] : v = prow[temp6]
   if u = 255 then goto __hc_next
   if pfread(u, v) then goto __hc_remove
__hc_next
   temp6 = temp6 + 1
   if temp6 < temp4 then goto __hc_piece
   goto __hc_dead
__hc_remove
   u = pcol[temp6] : v = prow[temp6]
   pfpixel u v off
   if _sfxId < 4 then _sfxId = 3 : _sfxT = 18
   ; resta qualcosa di questa citta'?
__hc_left
   temp6 = temp6 + 1
   if temp6 >= temp4 then goto __hc_dead
   u = pcol[temp6] : v = prow[temp6]
   if u = 255 then goto __hc_left
   if pfread(u, v) then return otherbank
   goto __hc_left
__hc_dead
   temp1 = bitmask[temp5]
   temp1 = temp1 ^ 255
   _alive = _alive & temp1
   if _alive then return otherbank
   ; TUTTE LE CITTA' DISTRUTTE
   _state = _state & %00100000
   _state = _state | %10000010
   _b0t = 255 : _b1t = 255
   _sfxId = 4 : _sfxT = 63
   goto __draw_gameover

   ;-------------------------------------------------------------------------
   ; fine livello: 5 punti per ogni pezzetto di citta' rimasto, contati uno
   ; alla volta con un tic (drawscreen cambia le variabili temp: il
   ; contatore e' _spawnT)
   ;-------------------------------------------------------------------------
__level_bonus
   _spawnT = 0
__lb_loop
   u = pcol[_spawnT] : v = prow[_spawnT]
   if u = 255 then goto __lb_next
   if !pfread(u, v) then goto __lb_next
   score = score + 5
   AUDC0 = 4 : AUDF0 = 6 : AUDV0 = 8
   _acc = 4
__lb_wait
   currentpaddle = 0
   drawscreen
   AUDV0 = 0
   _acc = _acc - 1
   if _acc then goto __lb_wait
__lb_next
   _spawnT = _spawnT + 1
   if _spawnT < 48 then goto __lb_loop
   _acc = 0
   return otherbank

   ;*************************************************************************************************************************
   ; SCRITTE (generate da tools/gen_text.py)
   ;*************************************************************************************************************************
   ; >>> generato da tools/gen_text.py
   ; SCRITTA DEL TITOLO
__draw_title
   playfield:
   .XX.XXX.XX...XX.X.X.X....X..XX..
   X....X..X.X.X...X.X.X...X.X.X.X.
   X....X..XX..X...X.X.X...XXX.XX..
   X....X..X.X.X...X.X.X...X.X.X.X.
   .XX.XXX.X.X..XX.XXX.XXX.X.X.X.X.
   ................................
   ..XX..XXX.XXX.XXX.XX...XX.XXX...
   ..X.X.X...X...X...X.X.X...X.....
   ..X.X.XX..XX..XX..X.X..X..XX....
   ..X.X.X...X...X...X.X...X.X.....
   ..XX..XXX.X...XXX.X.X.XX..XXX...
end
   return otherbank

   ; GAME OVER: tutte le citta' distrutte
__draw_gameover
   playfield:
   .........XX..X..X.X.XXX.........
   ........X...X.X.XXX.X...........
   ........X.X.XXX.XXX.XX..........
   ........X.X.X.X.X.X.X...........
   .........XX.X.X.X.X.XXX.........
   ................................
   .........X..X.X.XXX.XX..........
   ........X.X.X.X.X...X.X.........
   ........X.X.X.X.XX..XX..........
   ........X.X.X.X.X...X.X.........
   .........X...X..XXX.X.X.........
end
   return otherbank

   ; VITTORIA: superati tutti gli 8 livelli
__draw_victory
   playfield:
   ................................
   ................................
   ................................
   X.X.XXX.XXX.XXX..X..XX..XXX..X..
   X.X..X...X...X..X.X.X.X..X..X.X.
   X.X..X...X...X..X.X.XX...X..XXX.
   X.X..X...X...X..X.X.X.X..X..X.X.
   .X..XXX..X...X...X..X.X.XXX.X.X.
   ................................
   ................................
   ................................
end
   return otherbank
   ; <<< fine

   ;*************************************************************************************************************************
   ; EFFETTI SONORI (canale 0) e MUSICA (canale 1)
   ;_________________________________________________________________________________________________________________________
   ; effetti: 1 sparo, 2 colpo parato, 3 citta' colpita, 4 game over,
   ; 5 inizio livello. _sfxT = frame che restano.
   ; musica: tema del titolo (in loop) e fanfara della vittoria (una volta);
   ; un passo ogni 8 frame. 0 = la nota continua, 1 = pausa, 255 = fine.
   ;*************************************************************************************************************************
__sound
   gosub __music
   if !_sfxT then AUDV0 = 0 : _sfxId = 0 : return otherbank
   _sfxT = _sfxT - 1
   on _sfxId goto __snd_none __snd_shot __snd_block __snd_city __snd_over __snd_level
__snd_none
   AUDV0 = 0 : return otherbank
__snd_shot
   ; colpo secco che scende di tono
   temp1 = _sfxT * 2
   AUDC0 = 4 : AUDF0 = 20 - temp1 : AUDV0 = 6
   return otherbank
__snd_block
   ; due note che salgono
   AUDC0 = 4 : AUDV0 = 8 : AUDF0 = 8
   if _sfxT > 6 then AUDF0 = 17
   return otherbank
__snd_city
   ; crollo: rumore che si spegne
   AUDC0 = 8 : AUDF0 = 31 - _sfxT : AUDV0 = _sfxT / 2
   return otherbank
__snd_over
   ; lunga sirena che scende
   temp1 = _sfxT / 2
   AUDC0 = 12 : AUDF0 = 31 - temp1 : AUDV0 = _sfxT / 4
   return otherbank
__snd_level
   ; arpeggio che sale: nuovo livello
   temp1 = _sfxT / 8
   AUDC0 = 4 : AUDF0 = lvjingle[temp1] : AUDV0 = 7
   return otherbank

__music
   ; titolo: tema in loop; vittoria: fanfara; in partita: niente musica
   if _b0_playing{0} || _b1_over{1} then AUDV1 = 0 : return
   if _frame & 7 then return
   if _b3_victory{3} then goto __music_victory
   temp1 = titletune[_music]
   _music = _music + 1
   if _music >= 64 then _music = 0
   goto __music_note
__music_victory
   temp1 = victorytune[_music]
   if temp1 = 255 then AUDV1 = 0 : return
   _music = _music + 1
__music_note
   if !temp1 then return
   if temp1 = 1 then AUDV1 = 0 : return
   AUDC1 = 4 : AUDF1 = temp1 : AUDV1 = 5
   return

   ; arpeggio del nuovo livello (indice = frame rimasti / 8: si parte dal
   ; piu' grave e si sale)
   data lvjingle
   11, 14, 19, 23
end

   ; tema del titolo (AUDC 4: Do5=29 Re5=26 Mi5=23 Fa5=21 Sol5=19 La5=17
   ; Si5=15 Do6=14 Re6=12 Mi6=11)
   data titletune
   29, 0, 23, 0, 19, 0, 0, 0, 14, 0, 0, 0, 19, 0, 23, 0,
   17, 0, 0, 0, 21, 0, 17, 0, 14, 0, 0, 0, 0, 0, 1, 1,
   15, 0, 19, 0, 12, 0, 0, 0, 15, 0, 19, 0, 14, 0, 0, 0,
   14, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1
end

   ; fanfara della vittoria
   data victorytune
   19, 1, 19, 1, 19, 1, 14, 0, 0, 0, 11, 0, 12, 14, 0, 0,
   12, 0, 11, 0, 0, 0, 0, 0, 1, 255
end

   ; ordine di ricerca della citta' piu' vicina: 0, +1, -1, +2, -2, +3
   data near6
   0, 1, 5, 2, 4, 3
end
   data bitmask
   1, 2, 4, 8, 16, 32
end

   ; >>> generato da tools/gen_tables.py bank2
   ; pezzetti delle 6 citta' (8 per citta', dal piu' alto; 255 = vuoto)
   data pcol
   27, 26, 27, 29, 26, 27, 28, 29, 16, 14, 16, 17, 14, 15, 16, 17,
   4, 2, 4, 5, 2, 3, 4, 5, 3, 2, 3, 5, 2, 3, 4, 5,
   16, 14, 15, 17, 14, 15, 16, 17, 27, 26, 28, 29, 26, 27, 28, 29
end
   data prow
   7, 8, 8, 8, 9, 9, 9, 9, 8, 9, 9, 9, 10, 10, 10, 10,
   7, 8, 8, 8, 9, 9, 9, 9, 1, 2, 2, 2, 3, 3, 3, 3,
   0, 1, 1, 1, 2, 2, 2, 2, 1, 2, 2, 2, 3, 3, 3, 3
end
   ; <<< fine
