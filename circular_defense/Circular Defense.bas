   ;*************************************************************************************************************************
   ; CIRCULAR DEFENSE - Atari 2600 (batari Basic, PAL)
   ;_________________________________________________________________________________________________________________________
   ; Il cannone al centro spara verso la citta': 12 blocchi su un anello.
   ; Lo scudo gira da solo attorno al cannone e ferma i proiettili.
   ;   levetta destra   = lo scudo gira piu' veloce
   ;   levetta sinistra = lo scudo gira all'indietro
   ;   fuoco            = freno (lo scudo rallenta)
   ; Ogni proiettile fermato vale 1 punto; ogni 10 si passa all'ondata
   ; successiva (proiettili piu' veloci, cannone piu' rapido). Un
   ; proiettile che arriva all'anello distrugge il blocco piu' vicino.
   ; Distrutti tutti i blocchi: CITTA' DISTRUTTA (game over).
   ; Fuoco o Reset per iniziare.
   ; Levette di difficolta' (A = piu' difficile):
   ;   sinistra A = proiettili piu' veloci
   ;   destra A   = il cannone parte piu' rapido
   ;*************************************************************************************************************************

   set tv pal
   set romsize 4k
   const pfscore = 1

   ; centro dello schermo (coordinate dei missili) e attese del cannone
   const _X0 = 82
   const _Y0 = 44
   const _Spawn_Start = 75
   const _Spawn_Fast = 50
   const _Spawn_Min = 30

   ;*************************************************************************************************************************
   ; VARIABILI
   ;_________________________________________________________________________________________________________________________
   ; Proiettili: posizione 8.8 (parte intera = coordinata del missile),
   ; direzione (blocco verso cui vanno, 0-11) e passo (0-63; 255 = libero).
   ; Proiettile 0 = missile1 (giallo come il cannone),
   ; proiettile 1 = missile0 (colore dello scudo).
   ;*************************************************************************************************************************
   dim _angle = a
   dim _frame = b
   dim _wave = c
   dim _spawnT = d
   dim _alive0 = e
   dim _alive1 = f
   dim _state = g
   dim _b0_playing = g
   dim _b1_over = g
   ; ultimo colpo sparato dal proiettile 1 (0 = dal proiettile 0)
   dim _b2_last = g
   dim _b7_prevFire = g
   dim _acc = h
   dim _b0x = i.j
   dim _b0y = k.l
   dim _b0d = m
   dim _b0t = n
   dim _b1x = o.p
   dim _b1y = q.r
   dim _b1d = s
   dim _b1t = t
   dim _vel = u.v
   dim _interval = w
   dim _sfxId = x
   dim _sfxT = y
   dim _blocked = z

   scorecolor = $0E
   pfscorecolor = $2C
   missile0height = 4
   missile1height = 4

   gosub __draw_city
   _b0t = 255 : _b1t = 255
   _wave = 1

   ;*************************************************************************************************************************
   ; CICLO PRINCIPALE
   ;*************************************************************************************************************************
__main
   _frame = _frame + 1

   ; colori: la citta' lampeggia in rosso dopo il game over
   COLUPF = $9C
   temp1 = _frame & 16
   if _b1_over{1} && temp1 then COLUPF = $46
   ; il difensore pulsa
   temp1 = _frame / 4
   temp1 = temp1 & 6
   COLUP0 = $56 + temp1
   COLUP1 = $2E
   ; il cannone lampeggia appena spara
   if _sfxId = 1 then COLUP1 = $46
   ; missili larghi 4 pixel (i proiettili sono quadrati 4x4);
   ; il cannone (player1) e' largo il doppio: 16 pixel
   NUSIZ0 = $20 : NUSIZ1 = $25

   ;---------------------------------------------------------------------------
   ; FUOCO / RESET: inizio partita (fuoco premuto dopo averlo rilasciato)
   ;---------------------------------------------------------------------------
   if _b0_playing{0} then goto __no_start
   if switchreset then goto __new_game
   if !joy0fire then _b7_prevFire{7} = 0 : goto __no_start
   if _b7_prevFire{7} then goto __no_start
   goto __new_game
__no_start
   if joy0fire then _b7_prevFire{7} = 1

   ;---------------------------------------------------------------------------
   ; SCUDO: gira da solo (1,5 unita' per frame, 256 unita' = un giro)
   ;---------------------------------------------------------------------------
   temp1 = 1 + (_frame & 1)
   if !_b0_playing{0} then temp1 = _frame & 1 : goto __rotate
   if joy0fire then temp1 = _frame & 1
   if joy0right then temp1 = 3 + (_frame & 1)
   if joy0left then temp1 = 254 - (_frame & 1)
__rotate
   _angle = _angle + temp1
   temp2 = _angle / 4
   player0x = shx[temp2] : player0y = shy[temp2]
   player1x = _X0 - 8 : player1y = _Y0 + 10

   ; direzione della canna: verso l'ultimo colpo; in attesa segue lo scudo
   temp1 = _b0d
   if _b2_last{2} then temp1 = _b1d
   temp2 = dir8[temp1]
   if !_b0_playing{0} then temp2 = _angle / 32
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

   if !_b0_playing{0} then goto __show

   ;---------------------------------------------------------------------------
   ; CANNONE: un proiettile ogni _interval frame, se c'e' un posto libero
   ;---------------------------------------------------------------------------
   _spawnT = _spawnT + 1
   if _spawnT < _interval then goto __no_spawn
   ; direzione a caso tra i 12 blocchi
   temp1 = rand
__mod12
   if temp1 >= 12 then temp1 = temp1 - 12 : goto __mod12
   if _b0t <> 255 then goto __try_slot1
   _b0d = temp1 : _b0t = 0 : i = _X0 : j = 0 : k = _Y0 : l = 0 : _b2_last{2} = 0
   goto __spawned
__try_slot1
   if _b1t <> 255 then goto __no_spawn
   _b1d = temp1 : _b1t = 0 : o = _X0 : p = 0 : q = _Y0 : r = 0 : _b2_last{2} = 1
__spawned
   _spawnT = 0
   if _interval > _Spawn_Min then _interval = _interval - 1
   if _sfxId < 2 then _sfxId = 1 : _sfxT = 6
__no_spawn

   ;---------------------------------------------------------------------------
   ; PROIETTILI: (6 + ondata)/8 passi per frame, 2 in piu' con la levetta
   ; sinistra in A. Un passo = 1/64 della strada dal centro all'anello.
   ;---------------------------------------------------------------------------
   temp1 = 6 + _wave
   if temp1 > 30 then temp1 = 30
   if !switchleftb then temp1 = temp1 + 2
   _acc = _acc + temp1
__move_loop
   if _acc < 8 then goto __show
   _acc = _acc - 8
   if _b0t = 255 then goto __move1
   temp1 = _b0d
   u = vxh[temp1] : v = vxl[temp1] : _b0x = _b0x + _vel
   u = vyh[temp1] : v = vyl[temp1] : _b0y = _b0y + _vel
   _b0t = _b0t + 1
   if _b0t < 64 then goto __move1
   _b0t = 255 : temp6 = _b0d : gosub __hit_city
__move1
   if _b1t = 255 then goto __move_loop
   temp1 = _b1d
   u = vxh[temp1] : v = vxl[temp1] : _b1x = _b1x + _vel
   u = vyh[temp1] : v = vyl[temp1] : _b1y = _b1y + _vel
   _b1t = _b1t + 1
   if _b1t < 64 then goto __move_loop
   _b1t = 255 : temp6 = _b1d : gosub __hit_city
   goto __move_loop

   ;---------------------------------------------------------------------------
   ; DISEGNO E SUONI
   ;---------------------------------------------------------------------------
__show
   ; il quadrato 4x4 e' centrato sulla posizione del proiettile
   missile1x = i - 2 : missile1y = k + 2
   if _b0t = 255 then missile1y = 200
   missile0x = o - 2 : missile0y = q + 2
   if _b1t = 255 then missile0y = 200

   gosub __sound

   drawscreen

   ;---------------------------------------------------------------------------
   ; SCUDO CONTRO PROIETTILI (collisioni del frame appena disegnato)
   ;---------------------------------------------------------------------------
   if !_b0_playing{0} then goto __main
   if !collision(player0, missile1) then goto __no_block0
   if _b0t = 255 then goto __no_block0
   _b0t = 255 : gosub __blocked
__no_block0
   if !collision(player0, missile0) then goto __main
   if _b1t = 255 then goto __main
   _b1t = 255 : gosub __blocked
   goto __main

   ;*************************************************************************************************************************
   ; NUOVA PARTITA
   ;*************************************************************************************************************************
__new_game
   _state = 1 : _b7_prevFire{7} = 1
   score = 0
   _wave = 1 : _blocked = 0 : _acc = 0 : _spawnT = 0
   _interval = _Spawn_Start
   if !switchrightb then _interval = _Spawn_Fast
   _b0t = 255 : _b1t = 255
   pfscore1 = %00000001
   gosub __draw_city
   _sfxId = 0 : _sfxT = 0
   goto __main

   ;*************************************************************************************************************************
   ; PROIETTILE FERMATO DALLO SCUDO: +1 punto, ogni 10 un'ondata in piu'
   ;*************************************************************************************************************************
__blocked
   score = score + 1
   _blocked = _blocked + 1
   if _blocked < 10 then goto __blocked_snd
   _blocked = 0 : _wave = _wave + 1
   ; barra delle ondate: un segmento in piu' (fino a 8)
   pfscore1 = pfscore1 * 2 | 1
__blocked_snd
   if _sfxId < 3 then _sfxId = 2 : _sfxT = 8
   return

   ;*************************************************************************************************************************
   ; PROIETTILE ARRIVATO ALL'ANELLO (temp6 = direzione): distrugge il
   ; blocco vivo piu' vicino (stesso blocco, poi +1, -1, +2, -2, ...)
   ; (pfpixel usa temp1-temp3: qui si usano temp4-temp6)
   ;*************************************************************************************************************************
__hit_city
   temp4 = 0
__hc_loop
   temp5 = temp6 + near[temp4]
   if temp5 >= 12 then temp5 = temp5 - 12
   temp1 = bitmask[temp5]
   if temp5 >= 8 then goto __hc_hi
   temp2 = _alive0 & temp1
   if temp2 then _alive0 = _alive0 ^ temp1 : goto __hc_destroy
   goto __hc_next
__hc_hi
   temp2 = _alive1 & temp1
   if temp2 then _alive1 = _alive1 ^ temp1 : goto __hc_destroy
__hc_next
   temp4 = temp4 + 1
   if temp4 < 12 then goto __hc_loop
   return
__hc_destroy
   temp4 = blkcol[temp5] : temp6 = blkrow[temp5]
   pfpixel temp4 temp6 off
   temp4 = temp4 + 1
   pfpixel temp4 temp6 off
   if _sfxId < 4 then _sfxId = 3 : _sfxT = 18
   if _alive0 || _alive1 then return
   ; CITTA' DISTRUTTA
   _state = 2 : _b7_prevFire{7} = 1
   _b0t = 255 : _b1t = 255
   _sfxId = 4 : _sfxT = 50
   return

   ;*************************************************************************************************************************
   ; ANELLO DELLA CITTA': 12 blocchi di 2 pixel
   ;*************************************************************************************************************************
__draw_city
   pfclear
   _alive0 = 255 : _alive1 = 15
   temp5 = 0
__dc_loop
   temp4 = blkcol[temp5] : temp6 = blkrow[temp5]
   pfpixel temp4 temp6 on
   temp4 = temp4 + 1
   pfpixel temp4 temp6 on
   temp5 = temp5 + 1
   if temp5 < 12 then goto __dc_loop
   return

   ;*************************************************************************************************************************
   ; EFFETTI SONORI (canale 0): 1 sparo, 2 proiettile fermato,
   ; 3 blocco colpito, 4 citta' distrutta. _sfxT = frame che restano.
   ;*************************************************************************************************************************
__sound
   if !_sfxT then AUDV0 = 0 : return
   _sfxT = _sfxT - 1
   on _sfxId goto __snd_none __snd_shot __snd_block __snd_city __snd_over
__snd_none
   AUDV0 = 0 : return
__snd_shot
   ; colpo secco che scende di tono
   temp1 = _sfxT * 2
   AUDC0 = 4 : AUDF0 = 20 - temp1 : AUDV0 = 6
   return
__snd_block
   ; due note che salgono
   AUDC0 = 4 : AUDV0 = 8 : AUDF0 = 8
   if _sfxT > 4 then AUDF0 = 17
   return
__snd_city
   ; boato che si spegne
   AUDC0 = 8 : AUDF0 = 31 - _sfxT : AUDV0 = _sfxT / 2
   return
__snd_over
   ; lunga sirena che scende
   temp1 = _sfxT / 2
   AUDC0 = 12 : AUDF0 = 31 - temp1 : AUDV0 = _sfxT / 4
   return

   ;*************************************************************************************************************************
   ; TABELLE (generate da tools/gen_tables.py)
   ;*************************************************************************************************************************
   ; ordine di ricerca del blocco piu' vicino: 0, +1, -1, +2, -2, ...
   data near
   0, 1, 11, 2, 10, 3, 9, 4, 8, 5, 7, 6
end
   ; direzione della canna (8 disegni) per ognuna delle 12 direzioni di tiro
   data dir8
   0, 1, 1, 2, 3, 3, 4, 5, 5, 6, 7, 7
end
   data bitmask
   1, 2, 4, 8, 16, 32, 64, 128, 1, 2, 4, 8
end
   ; anello della citta': 12 blocchi (2 pixel del playfield), d*30 gradi
   data blkcol
   29, 27, 22, 15, 8, 3, 1, 3, 8, 15, 22, 27
end
   data blkrow
   5, 8, 9, 10, 9, 8, 5, 2, 1, 0, 1, 2
end
   ; velocita' 8.8 (complemento a due): dal centro al blocco in 64 passi
   data vxh
   0, 0, 0, 0, 255, 255, 255, 255, 255, 0, 0, 0
end
   data vxl
   224, 192, 112, 0, 144, 64, 32, 64, 144, 0, 112, 192
end
   data vyh
   0, 0, 0, 0, 0, 0, 0, 255, 255, 255, 255, 255
end
   data vyl
   0, 96, 128, 160, 128, 96, 0, 160, 128, 96, 128, 160
end
   ; orbita dello scudo: 64 posizioni (angolo/4)
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
