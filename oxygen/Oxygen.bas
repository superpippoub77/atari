   ;*************************************************************************************************************************
   ; OXYGEN 2600 - Classified Operation
   ;_________________________________________________________________________________________________________________________
   ; Versione Atari 2600 (8K, F8, PAL) del gioco Phaser OXYGEN: esci dalla
   ; base, attraversa il settore (4 stanze, una per schermo) prima che
   ; finisca l'ossigeno, raccogli le 2 chiavi e attiva l'interruttore O2
   ; nella base finale (il suo cancello si apre solo con tutte e due le
   ; chiavi). Nelle basi l'ossigeno non cala e la bombola lo ricarica
   ; (base sicura +15 s, standard +10 s, militare tutto).
   ; Le stanze vengono da levels/*.json, convertite da tools/convert_levels.py
   ; nel file rooms.asm (banco 2).
   ;*************************************************************************************************************************
   set kernel_options pfcolors
   set tv pal
   set romsize 8k

   const pfscore = 1

   ;*************************************************************************************************************************
   ; VARIABILI
   ;*************************************************************************************************************************
   dim _level = a             ; livello 0-11
   dim _room = b              ; stanza 0-3 (bit 0 = colonna, bit 1 = riga del mondo)
   dim _frame = c
   dim _o2 = d                ; ossigeno in quarti di secondo
   dim _o2tick = e
   ; flag: bit 0 dentro una base, bit 1 colpo del giocatore in volo, bit 2-3
   ; chiavi 1 e 2, bit 4 colpo nemico in volo, bit 5 luce che traballa,
   ; bit 7 al caricamento metti il giocatore nella base di partenza
   dim _flags = f
   dim _dir = g               ; bit 0-2 direzione del giocatore, bit 4-6 del suo colpo
   dim _shotLife = h
   dim _ex = i                ; nemici: x (i, j), y (k, l), info (m, n)
   dim _ey = k
   ; info: bit 0-1 tipo (0 guardia, 1 cecchino, 2 drone, 3 pesante),
   ; bit 2-4 punti vita, bit 5 in allarme, bit 6 pattuglia verso destra,
   ; bit 7 vivo
   dim _einfo = m
   dim _bulletDir = o         ; bit 0-2 direzione del colpo nemico, bit 3 veloce
   dim _shootTimer = p
   dim _mux = q               ; bit 0 nemico mostrato ora, bit 1 nel frame prima
   dim _dead = r              ; nemici uccisi nel livello: bit stanza*2+posto
   dim _base = s              ; base attuale (stanza*4+numero), 255 nessuna
   dim _baseInfo = t          ; info della base attuale (bit 4-5 tipo)
   dim _canCool = u           ; bombola vuota per un po' (a passi di 4 frame)
   dim _sfxTime = v
   dim _sfxId = w
   dim _diff = x              ; difficolta' 0-3
   dim _hitCool = y
   dim _ball = z              ; oggetto della ball: 0 niente, 1-2 chiave, 3 bombola, 4 interruttore
   dim _patrol = var44        ; x di partenza della pattuglia (var44, var45)
   ; var46, var47 (e h, o, p, e): appoggio del caricatore delle stanze

   ;*************************************************************************************************************************
   ; TITOLO
   ;*************************************************************************************************************************
__title
   _flags = 0 : AUDV0 = 0 : _sfxTime = 0
   player0y = 200 : player1y = 200 : missile0y = 200 : missile1y = 200 : bally = 200
   missile0height = 2 : missile1height = 2 : ballheight = 5
   ; ball larga 4 pixel (bit 4-5), playfield riflesso come vuole il kernel (bit 0)
   CTRLPF = $21
   playfield:
   ................................
   .XXXX.X..X.X..X.XXXX.XXXX.X..X..
   .X..X.X..X.X..X.X....X....XX.X..
   .X..X..XX...XX..X.XX.XXX..X.XX..
   .X..X.X..X...X..X..X.X....X..X..
   .XXXX.X..X...X..XXXX.XXXX.X..X..
   ................................
   ............XXX.XX..............
   ............X.X...X.............
   ............X.X..X..............
   ............XXX.XXX.............
end
   pfcolors:
   $9E
   $9C
   $9A
   $98
   $96
   $94
   $5C
   $5A
   $58
   $56
   $54
end
   pfscore1 = 0 : pfscore2 = 0
__title_release
   COLUBK = 0
   drawscreen
   if joy0fire || switchreset then goto __title_release
__title_wait
   COLUBK = 0
   scorecolor = $0E
   drawscreen
   if !joy0fire && !switchreset then goto __title_wait

   ;*************************************************************************************************************************
   ; NUOVA PARTITA
   ;*************************************************************************************************************************
   score = 0 : _level = 0
   pfscore2 = %00101010
__new_level
   ; difficolta' dalle levette: B B normal, sinistra A hard, destra A
   ; beginner, A A expert
   _diff = 1
   if !switchleftb then _diff = 2
   if !switchrightb then _diff = 0
   if !switchleftb && !switchrightb then _diff = 3
   _flags = 0
   _dead = 0
   gosub __level_start bank2
   callmacro sfx 6

   ;*************************************************************************************************************************
   ; CICLO PRINCIPALE
   ;*************************************************************************************************************************
__main
   _frame = _frame + 1
   COLUBK = $00

   ; ---- giocatore: movimento con i muri ----
   gosub __move_player

   ; ---- passaggio da una stanza all'altra ----
   if player0x < 11 && _room{0} then _room = _room - 1 : player0x = 144 : gosub __enter_room
   if player0x > 144 && !_room{0} then _room = _room + 1 : player0x = 11 : gosub __enter_room
   if player0y < 9 && _room{1} then _room = _room - 2 : player0y = 87 : gosub __enter_room
   if player0y > 87 && !_room{1} then _room = _room + 2 : player0y = 9 : gosub __enter_room

   ; ---- sparo del giocatore (nella direzione in cui cammina) ----
   if !joy0fire || _flags{1} then goto __no_fire
   _flags{1} = 1 : _shotLife = 40
   temp1 = _dir & 7 : _dir = temp1 * 16 : _dir = _dir | temp1
   missile0x = player0x + 4 : missile0y = player0y - 3
   callmacro sfx 1
__no_fire
   if !_flags{1} then goto __no_shot
   temp1 = _dir / 16
   missile0x = missile0x + dx3[temp1] : missile0y = missile0y + dy3[temp1]
   _shotLife = _shotLife - 1
   if !_shotLife then gosub __shot_off
   if missile0x > 156 || missile0y > 92 then gosub __shot_off
   if collision(missile0, playfield) then gosub __shot_off
__no_shot

   ; ---- nemici ----
   gosub __enemies

   ; ---- il colpo del giocatore colpisce il nemico disegnato nel frame prima ----
   if !collision(missile0, player1) then goto __no_enemy_hit
   if !_flags{1} then goto __no_enemy_hit
   gosub __shot_off
   temp6 = _mux & 1
   gosub __hit_enemy
__no_enemy_hit

   ; ---- colpo nemico sul giocatore: -3 secondi di ossigeno ----
   if !collision(missile1, player0) then goto __no_player_hit
   if _hitCool then goto __no_player_hit
   _flags{4} = 0 : missile1y = 200 : _hitCool = 60
   if _o2 > 12 then _o2 = _o2 - 12 else _o2 = 0
   callmacro sfx 2
__no_player_hit
   if _hitCool then _hitCool = _hitCool - 1

   ; ---- oggetti: chiave, bombola, interruttore ----
   if collision(player0, ball) then gosub __touch_ball

   ; ---- dentro o fuori da una base (ogni 4 frame) ----
   temp1 = _frame & 3
   if !temp1 then gosub __base_check bank2
   if _canCool && !temp1 then _canCool = _canCool - 1

   ; ---- ossigeno: cala solo fuori dalle basi ----
   if _flags{0} then goto __o2_done
   _o2tick = _o2tick + 1
   if _o2tick < o2rate[_diff] then goto __o2_done
   _o2tick = 0
   if _o2 then _o2 = _o2 - 1
   if !_o2 then goto __lose_life
__o2_done
   gosub __o2_bar

   ; ---- disegno ----
   gosub __draw_sprites
   gosub __sfx_update
   drawscreen
   if switchreset then goto __title
   goto __main

   ;*************************************************************************************************************************
   ; VITA PERSA: si riparte dalla base di partenza con l'ossigeno pieno
   ; (chiavi e nemici uccisi restano)
   ;*************************************************************************************************************************
__lose_life
   callmacro sfx 5
   pfscore2 = pfscore2 / 4
   if !pfscore2 then goto __game_over
   gosub __shot_off
   gosub __level_start bank2
   goto __main

__game_over
   ; qualche secondo con lo schermo rosso, poi il titolo (il punteggio resta)
   _o2tick = 150
__go_wait
   COLUBK = $42
   gosub __sfx_update
   drawscreen
   _o2tick = _o2tick - 1
   if _o2tick then goto __go_wait
   goto __title

   ;*************************************************************************************************************************
   ; ROUTINE DEL BANCO 1
   ;*************************************************************************************************************************
__shot_off
   _flags{1} = 0 : missile0y = 200
   return

__enter_room
   _flags{1} = 0 : missile0y = 200 : _flags{4} = 0 : missile1y = 200
   gosub __load_room bank2
   return

   ; movimento del giocatore (sprite 8 pixel x 7 righe): la direzione
   ; resta quella della levetta anche contro un muro (per sparare).
   ; (pfread usa temp1 e temp2: argomenti in temp3/temp4, risultato in temp6,
   ; direzione in temp5)
__move_player
   temp5 = 255
   if !joy0up || player0y < 9 then goto __mp_down
   temp3 = (player0x - 10) / 4 : temp4 = (player0y - 8) / 8
   gosub __solid3
   if !temp6 then player0y = player0y - 1
   temp5 = 0
__mp_down
   if !joy0down || player0y > 87 then goto __mp_left
   temp3 = (player0x - 10) / 4 : temp4 = player0y / 8
   gosub __solid3
   if !temp6 then player0y = player0y + 1
   temp5 = 4
__mp_left
   if !joy0left || player0x < 11 then goto __mp_right
   temp3 = (player0x - 18) / 4
   gosub __solid_v
   if !temp6 then player0x = player0x - 1
   temp1 = 6
   if !temp5 then temp1 = 7
   if temp5 = 4 then temp1 = 5
   temp5 = temp1
__mp_right
   if !joy0right || player0x > 144 then goto __mp_done
   temp3 = (player0x - 9) / 4
   gosub __solid_v
   if !temp6 then player0x = player0x + 1
   temp1 = 2
   if !temp5 then temp1 = 1
   if temp5 = 4 then temp1 = 3
   temp5 = temp1
__mp_done
   if temp5 < 8 then _dir = (_dir & %11110000) | temp5
   return

   ; muro su una delle colonne temp3, temp3-1, temp3-2 nella riga temp4 -> temp6
__solid3
   temp6 = 0
   if temp3 < 32 then if pfread(temp3, temp4) then temp6 = 1
   temp3 = temp3 - 1
   if temp3 < 32 then if pfread(temp3, temp4) then temp6 = 1
   temp3 = temp3 - 1
   if temp3 < 32 then if pfread(temp3, temp4) then temp6 = 1
   return

   ; muro nella colonna temp3, alla riga della parte alta o bassa del giocatore
__solid_v
   temp6 = 0
   if temp3 > 31 then return
   temp4 = (player0y - 1) / 8
   if pfread(temp3, temp4) then temp6 = 1
   temp4 = (player0y - 7) / 8
   if pfread(temp3, temp4) then temp6 = 1
   return

   ;*************************************************************************************************************************
   ; NEMICI: due posti, un solo sprite a frame alterni. Guardia: pattuglia,
   ; in allarme insegue e spara. Cecchino: fermo, spara spesso e veloce.
   ; Drone: veloce, vola sopra i muri. Pesante: lento e resistente.
   ;*************************************************************************************************************************
__enemies
   if _shootTimer then _shootTimer = _shootTimer - 1
   temp6 = 0
   gosub __enemy_one
   temp6 = 1
   gosub __enemy_one
   ; colpo nemico
   if !_flags{4} then return
   temp1 = _bulletDir & 7
   missile1x = missile1x + dx2[temp1] : missile1y = missile1y + dy2[temp1]
   if _bulletDir{3} then missile1x = missile1x + dx1[temp1] : missile1y = missile1y + dy1[temp1]
   if missile1x > 156 || missile1y > 92 then _flags{4} = 0 : missile1y = 200
   if collision(missile1, playfield) then _flags{4} = 0 : missile1y = 200
   return

__enemy_one
   temp5 = _einfo[temp6]
   if !temp5{7} then return
   temp4 = temp5 & 3
   temp1 = _ex[temp6] : temp2 = _ey[temp6]
   ; allarme: giocatore entro ~60 pixel (distanza "a scacchiera" / 2)
   if player0x > temp1 then temp3 = player0x - temp1 else temp3 = temp1 - player0x
   if player0y > temp2 then temp3 = temp3 + player0y - temp2 else temp3 = temp3 + temp2 - player0y
   temp5{5} = 0
   if temp3 < 60 then temp5{5} = 1
   _einfo[temp6] = temp5
   ; sparo mirato (8 direzioni)
   if !temp5{5} then goto __eo_move
   if _shootTimer then goto __eo_move
   if _flags{4} then goto __eo_move
   _shootTimer = shoottime[temp4] + (_frame & 31)
   _flags{4} = 1
   missile1x = temp1 + 4 : missile1y = temp2 - 3
   ; mira: (sinistra/centro/destra) + 3 * (sopra/stessa altezza/sotto)
   asm
 ldx #1
 lda temp1
 clc
 adc #6
 cmp player0x
 bcs aim_1
 ldx #2
aim_1
 lda player0x
 clc
 adc #6
 cmp temp1
 bcs aim_2
 ldx #0
aim_2
 lda temp2
 clc
 adc #6
 cmp player0y
 bcs aim_3
 inx
 inx
 inx
 inx
 inx
 inx
 jmp aim_5
aim_3
 lda player0y
 clc
 adc #6
 cmp temp2
 bcc aim_5
 inx
 inx
 inx
aim_5
 lda aimdir,x
 sta _bulletDir
end
   if temp4 = 1 then _bulletDir{3} = 1
   callmacro sfx 1
__eo_move
   ; il cecchino resta fermo
   if temp4 = 1 then return
   ; velocita': k frame su 4 (tabella per tipo e difficolta'), 1 in pattuglia
   temp3 = temp4 * 4 + _diff
   temp3 = espeed[temp3]
   if !temp5{5} then temp3 = 1
   temp2 = _frame & 3
   if temp2 >= temp3 then return
   temp1 = _ex[temp6] : temp2 = _ey[temp6]
   if temp5{5} then goto __eo_chase
   ; pattuglia: avanti e indietro di 20 pixel
   if temp5{6} then temp1 = temp1 + 1 else temp1 = temp1 - 1
   temp3 = _patrol[temp6]
   temp3 = temp1 - temp3
   temp3 = temp3 + 20
   if temp3 > 40 then goto __eo_turn
   goto __eo_try
__eo_chase
   if player0x > temp1 then temp1 = temp1 + 1
   if player0x < temp1 then temp1 = temp1 - 1
   if player0y > temp2 then temp2 = temp2 + 1
   if player0y < temp2 then temp2 = temp2 - 1
__eo_try
   if temp1 < 12 || temp1 > 143 then goto __eo_turn
   if temp2 < 10 || temp2 > 86 then goto __eo_turn
   ; muri (il drone vola sopra); pfread usa temp1/temp2: la nuova
   ; posizione aspetta in var46/var47
   var46 = temp1 : var47 = temp2
   if temp4 = 2 then goto __eo_ok
   temp3 = (temp1 - 13) / 4 : temp4 = (temp2 - 4) / 8
   if pfread(temp3, temp4) then goto __eo_turn
__eo_ok
   _ex[temp6] = var46 : _ey[temp6] = var47
   return
__eo_turn
   temp5 = _einfo[temp6] ^ %01000000
   _einfo[temp6] = temp5
   return

   ; il colpo del giocatore colpisce il nemico temp6
__hit_enemy
   temp5 = _einfo[temp6]
   if !temp5{7} then return
   temp5 = temp5 - 4
   _einfo[temp6] = temp5
   temp4 = temp5 & %00011100
   if temp4 then score = score + 100 : callmacro sfx 2 : return
   ; ucciso: resta morto fino al livello dopo
   _einfo[temp6] = 0
   temp1 = _room * 2 + temp6
   _dead = _dead | bitmask[temp1]
   score = score + 500
   callmacro sfx 3
   return

   ;*************************************************************************************************************************
   ; OGGETTI (ball): chiavi, bombola, interruttore
   ;*************************************************************************************************************************
__touch_ball
   if _ball = 1 then _flags{2} = 1 : goto __got_key
   if _ball = 2 then _flags{3} = 1 : goto __got_key
   if _ball = 3 then goto __canister
   if _ball <> 4 then return
   if !_flags{2} || !_flags{3} then return
   ; interruttore O2: livello finito
   score = score + 5000
   callmacro sfx 7
   bally = 200
   ; (attesa con _o2tick: drawscreen cancella le variabili temp)
   _o2tick = 100
__clear_wait
   gosub __sfx_update
   drawscreen
   _o2tick = _o2tick - 1
   if _o2tick then goto __clear_wait
   _level = _level + 1
   if _level > 11 then _level = 0
   goto __new_level

__got_key
   score = score + 300
   callmacro sfx 4
   ; si ridisegna la stanza: sparisce la chiave e, con tutte e due, si
   ; apre il cancello della base finale (se e' in questa stanza)
   gosub __load_room bank2
   return

__canister
   if !_flags{0} || _canCool then return
   temp2 = o2max[_diff]
   if _o2 >= temp2 then return
   temp1 = _baseInfo / 16 & 3
   if temp1 = 2 then _o2 = temp2
   if temp1 = 1 then _o2 = _o2 + 40
   if !temp1 then _o2 = _o2 + 60
   if _o2 > temp2 then _o2 = temp2
   score = score + 200
   callmacro sfx 4
   _canCool = 100
   return

   ;*************************************************************************************************************************
   ; BARRA DELL'OSSIGENO (pfscore1, 8 tacche) con il colore della bussola
   ; dell'originale: verde oltre meta', gialla, rossa sotto un quarto
   ;*************************************************************************************************************************
__o2_bar
   temp1 = 0 : temp2 = _o2
   temp3 = o2step[_diff]
__ob_loop
   if !temp2 then goto __ob_done
   if temp1 = 8 then goto __ob_done
   temp1 = temp1 + 1
   if temp2 > temp3 then temp2 = temp2 - temp3 else temp2 = 0
   goto __ob_loop
__ob_done
   pfscore1 = o2bits[temp1]
   pfscorecolor = $58
   if temp1 < 5 then pfscorecolor = $2C
   if temp1 > 2 then return
   pfscorecolor = $46
   ; allarme: un bip ogni mezzo secondo fuori dalla base
   if _flags{0} then return
   temp2 = _frame & 31
   if !temp2 && !_sfxTime then callmacro sfx 8
   return

   ;*************************************************************************************************************************
   ; SPRITE: astronauta (lampeggia dopo un colpo), nemico di turno, luce
   ;*************************************************************************************************************************
__draw_sprites
   player0:
   %01100110
   %00100100
   %01111110
   %00111100
   %01011010
   %01111110
   %00111100
end
   COLUP0 = $0E
   if _hitCool && _frame{2} then COLUP0 = $04
   ; la bombola vuota lampeggia
   if _ball = 3 && _canCool && _frame{3} then bally = 200
   if _ball = 3 && _canCool && !_frame{3} then gosub __ball_back bank2
   ; nemico: si alternano i due posti vivi
   _mux = (_mux & 1) * 2
   temp6 = _mux / 2
   temp6 = temp6 ^ 1
   temp5 = _einfo[temp6]
   if !temp5{7} then temp6 = temp6 ^ 1 : temp5 = _einfo[temp6]
   _mux = _mux | temp6
   if !temp5{7} then player1y = 200 : goto __ds_light
   player1x = _ex[temp6] : player1y = _ey[temp6]
   temp4 = temp5 & 3
   COLUP1 = ecolor[temp4]
   if temp5{5} && _frame{3} then COLUP1 = $4E
   on temp4 goto __gfx_guard __gfx_sniper __gfx_drone __gfx_heavy
__gfx_guard
   player1:
   %01100110
   %00100100
   %00111100
   %01111110
   %00111100
   %00011000
   %00111100
end
   goto __ds_light
__gfx_sniper
   player1:
   %00100100
   %00100100
   %00111100
   %11111111
   %00111100
   %00111100
   %00011000
end
   goto __ds_light
__gfx_drone
   player1:
   %00000000
   %10000001
   %01011010
   %00111100
   %01111110
   %10011001
   %00000000
end
   goto __ds_light
__gfx_heavy
   player1:
   %11100111
   %01100110
   %11111111
   %11111111
   %11111111
   %01111110
   %00111100
end
__ds_light
   ; colori della stanza; luce che traballa (livello 2): ogni tanto, a
   ; caso, tutto piu' scuro
   pfcolors:
   $96
   $98
   $96
   $94
   $96
   $98
   $96
   $94
   $96
   $98
   $96
end
   if !_flags{5} then return
   temp1 = _frame / 4
   temp1 = temp1 ^ _frame
   temp1 = temp1 & 9
   if temp1 then return
   pfcolors:
   $92
   $92
   $92
   $90
   $92
   $92
   $92
   $92
   $90
   $92
   $92
end
   COLUP1 = $04
   return

   ;*************************************************************************************************************************
   ; EFFETTI SONORI (canale 0): frequenza = partenza + o - tempo rimasto
   ;*************************************************************************************************************************
   macro sfx
   _sfxId = {1} : _sfxTime = sfxdur[{1}]
end

__sfx_update
   if !_sfxTime then AUDV0 = 0 : return
   _sfxTime = _sfxTime - 1
   temp1 = _sfxId
   AUDC0 = sfxc[temp1]
   temp2 = sfxf[temp1]
   if sfxup[temp1] then temp2 = temp2 + _sfxTime else temp2 = temp2 - _sfxTime
   AUDF0 = temp2
   AUDV0 = 8
   return

   ;*************************************************************************************************************************
   ; TABELLE
   ;*************************************************************************************************************************
   ; ossigeno (quarti di secondo) e frame per ogni quarto: beginner 45 s
   ; e 0,5/s, normal 30 s e 0,9/s, hard 22 s e 1,3/s, expert 15 s e 1,8/s
   data o2max
   180, 120, 88, 60
end
   data o2rate
   25, 14, 10, 7
end
   data o2step
   23, 15, 11, 8
end
   data o2bits
   %00000000, %10000000, %11000000, %11100000, %11110000, %11111000, %11111100, %11111110, %11111111
end
   ; direzioni: 0 su, 1 su-destra, 2 destra, 3 giu'-destra, 4 giu', 5 giu'-sinistra, 6 sinistra, 7 su-sinistra
   data dx3
   0, 3, 3, 3, 0, 253, 253, 253
end
   data dy3
   253, 253, 0, 3, 3, 3, 0, 253
end
   data dx2
   0, 2, 2, 2, 0, 254, 254, 254
end
   data dy2
   254, 254, 0, 2, 2, 2, 0, 254
end
   data dx1
   0, 1, 1, 1, 0, 255, 255, 255
end
   data dy1
   255, 255, 0, 1, 1, 1, 0, 255
end
   ; (sinistra/centro/destra) + 3 * (sopra/stessa altezza/sotto)
   data aimdir
   7, 0, 1, 6, 4, 2, 5, 4, 3
end
   ; velocita' in allarme (frame su 4 in cui si muove) per tipo x difficolta'
   data espeed
   2, 3, 4, 4, 0, 0, 0, 0, 3, 4, 4, 4, 1, 2, 2, 3
end
   data shoottime
   70, 45, 90, 60
end
   ; colori: guardia rossa, cecchino viola, drone azzurro, pesante arancio
   data ecolor
   $46, $A8, $9C, $2A
end
   data bitmask
   1, 2, 4, 8, 16, 32, 64, 128
end
   ; effetti: 1 sparo, 2 colpito, 3 esplosione, 4 chiave/ricarica,
   ; 5 vita persa, 6 inizio livello, 7 livello finito, 8 allarme ossigeno,
   ; 9 porta della base
   data sfxdur
   0, 8, 10, 24, 12, 40, 20, 40, 4, 8
end
   data sfxc
   0, 8, 2, 8, 4, 6, 4, 4, 12, 1
end
   data sfxf
   0, 4, 20, 8, 8, 10, 4, 4, 6, 20
end
   data sfxup
   0, 1, 1, 1, 1, 1, 1, 1, 0, 0
end

   ;#########################################################################################################################
   ; BANCO 2: STANZE, BASI, OGGETTI
   ;#########################################################################################################################
   bank 2

   ; inizio livello o vita persa: stanza di partenza, giocatore al centro
   ; della base di partenza, ossigeno pieno
__level_start
   temp1 = level_info[_level]
   _room = temp1 & 3
   _flags{5} = 0
   if temp1{2} then _flags{5} = 1
   _flags{7} = 1
   _base = 255 : _canCool = 0 : _o2tick = 0 : _hitCool = 0
   _o2 = o2max_b2[_diff]
   gosub __load_room
   return otherbank

   data o2max_b2
   180, 120, 88, 60
end

   ; disegna la stanza _room del livello _level, sistema nemici e oggetti
__load_room
   pfclear
   if !_room{0} then pfvline 0 0 10 on
   if _room{0} then pfvline 31 0 10 on
   if !_room{1} then pfhline 0 0 31 on
   if _room{1} then pfhline 0 10 31 on
   _einfo = 0 : _einfo[1] = 0 : _ball = 0 : bally = 200
   _shootTimer = 60
   asm
   jsr load_room
end
   _flags{7} = 0
   return otherbank

   ; ritorno della bombola vuota (lampeggia)
__ball_back
   asm
   jsr find_ball
end
   return otherbank

   ; ogni 4 frame: il giocatore e' dentro una base? (entrando in una base
   ; nuova +200; uscendo parte il conto alla rovescia dell'ossigeno)
__base_check
   asm
   jsr base_check
end
   if temp1 = 255 then goto __bc_out
   temp2 = _room * 4 + temp1
   if _flags{0} && temp2 = _base then return otherbank
   if temp2 <> _base then score = score + 200 : _sfxId = 9 : _sfxTime = 8
   _flags{0} = 1 : _base = temp2 : _baseInfo = temp3
   return otherbank
__bc_out
   if !_flags{0} then return otherbank
   _flags{0} = 0 : _sfxId = 9 : _sfxTime = 8
   return otherbank

   ;*************************************************************************************************************************
   ; CARICATORE DELLE STANZE (assembly). Puntatore all'elenco in temp5/temp6,
   ; posizione in temp4; pfhline/pfvline usano temp1-temp3.
   ; Appoggio: var46 c0, var47 r0, h c1, o r1, p info della base, e
   ; contatore delle basi (bit 0-3) e dei nemici (bit 4-7).
   ;*************************************************************************************************************************
   asm
load_room
 jsr room_ptr
 lda #0
 sta temp4
 sta e
lr_loop
 ldy temp4
 lda (temp5),y
 bne lr_item
 rts
lr_item
 cmp #3
 bne lr_notbase
 jmp lr_base
lr_notbase
 cmp #4
 bne lr_notenemy
 jmp lr_enemy
lr_notenemy
 cmp #5
 bne lr_wall
 jmp lr_key
lr_wall
 pha
 jsr read3
 pla
 cmp #1
 bne lr_vwall
 ; muro orizzontale: riga temp1, colonne temp2..temp3
 ldx #0
 ldy temp1
 lda temp2
 jsr pfhline
 jmp lr_loop
lr_vwall
 ; muro verticale: colonna temp1, righe temp2..temp3
 ldx #0
 ldy temp2
 lda temp1
 jsr pfvline
 jmp lr_loop

lr_base
 ldy temp4
 iny
 lda (temp5),y
 sta var46
 iny
 lda (temp5),y
 sta var47
 iny
 lda (temp5),y
 sta h
 iny
 lda (temp5),y
 sta o
 iny
 lda (temp5),y
 sta p
 iny
 sty temp4
 ; pareti
 lda h
 sta temp3
 ldx #0
 ldy var47
 lda var46
 jsr pfhline
 lda h
 sta temp3
 ldx #0
 ldy o
 lda var46
 jsr pfhline
 lda o
 sta temp3
 ldx #0
 ldy var47
 lda var46
 jsr pfvline
 lda o
 sta temp3
 ldx #0
 ldy var47
 lda h
 jsr pfvline
 ; porte (la base finale ha il cancello chiuso senza le 2 chiavi)
 lda p
 and #$40
 beq lr_doors
 lda _flags
 and #$0C
 cmp #$0C
 bne lr_nodoors
lr_doors
 lda p
 and #1
 beq lr_d2
 ldy var47
 jsr door_h
lr_d2
 lda p
 and #2
 beq lr_d3
 ldy o
 jsr door_h
lr_d3
 lda p
 and #4
 beq lr_d4
 lda var46
 jsr door_v
lr_d4
 lda p
 and #8
 beq lr_nodoors
 lda h
 jsr door_v
lr_nodoors
 ; oggetto della base: interruttore nella base finale, se no la bombola
 lda p
 and #$40
 beq lr_can
 lda #4
 sta _ball
 jsr ball_center
 jmp lr_start
lr_can
 lda _ball
 bne lr_start
 lda #3
 sta _ball
 jsr ball_center
lr_start
 ; base di partenza (inizio livello o vita persa): giocatore al centro
 lda p
 bpl lr_bnext
 lda _flags
 bpl lr_bnext
 jsr mid_c
 sec
 sbc #1
 asl
 asl
 clc
 adc #17
 sta player0x
 jsr mid_r
 asl
 asl
 asl
 clc
 adc #8
 sta player0y
 lda _flags
 ora #1
 sta _flags
 lda _room
 asl
 asl
 sta temp1
 lda e
 and #$0F
 clc
 adc temp1
 sta _base
 lda p
 sta _baseInfo
lr_bnext
 inc e
 jmp lr_loop

lr_enemy
 jsr read3
 ; posto = numero del nemico nella stanza (al massimo 2)
 lda e
 lsr
 lsr
 lsr
 lsr
 tax
 lda e
 clc
 adc #$10
 sta e
 cpx #2
 bcs lr_en_skip
 ; ucciso prima?
 stx var47
 lda _room
 asl
 ora var47
 tay
 lda bitmask_b2,y
 and _dead
 bne lr_en_skip
 lda temp2
 asl
 asl
 clc
 adc #17
 sta _ex,x
 sta _patrol,x
 lda temp3
 asl
 asl
 asl
 clc
 adc #8
 sta _ey,x
 ; punti vita dalla tabella (tipo x difficolta')
 lda temp1
 asl
 asl
 clc
 adc _diff
 tay
 lda ehp,y
 asl
 asl
 ora temp1
 ora #$C0
 sta _einfo,x
lr_en_skip
 jmp lr_loop

lr_key
 jsr read3
 ; chiave temp1 (0 o 1) non ancora presa: e' lei l'oggetto della stanza
 ldx temp1
 lda _flags
 and keybit,x
 bne lr_key_done
 inx
 stx _ball
 lda temp2
 asl
 asl
 clc
 adc #18
 sta ballx
 lda temp3
 asl
 asl
 asl
 clc
 adc #5
 sta bally
lr_key_done
 jmp lr_loop

 ; porte: orizzontale nella riga Y (3 colonne al centro), verticale nella
 ; colonna A (2 righe al centro)
door_h
 sty temp1
 jsr mid_c
 sta temp2
 clc
 adc #1
 sta temp3
 ldx #1
 ldy temp1
 lda temp2
 sec
 sbc #1
 jmp pfhline
door_v
 sta temp2
 jsr mid_r
 sta temp3
 sta temp1
 inc temp3
 ldx #1
 ldy temp1
 lda temp2
 jmp pfvline

mid_c
 lda var46
 clc
 adc h
 lsr
 rts
mid_r
 lda var47
 clc
 adc o
 lsr
 rts

ball_center
 jsr mid_c
 asl
 asl
 clc
 adc #18
 sta ballx
 jsr mid_r
 asl
 asl
 asl
 clc
 adc #5
 sta bally
 rts

 ; puntatore all'elenco della stanza
room_ptr
 lda _level
 asl
 asl
 ora _room
 tax
 lda room_lo,x
 sta temp5
 lda room_hi,x
 sta temp6
 rts

 ; legge i 3 byte dopo il codice in temp1, temp2, temp3
read3
 ldy temp4
 iny
 lda (temp5),y
 sta temp1
 iny
 lda (temp5),y
 sta temp2
 iny
 lda (temp5),y
 sta temp3
 iny
 sty temp4
 rts

 ; rimette la bombola (prima base non finale della stanza) al suo posto
find_ball
 jsr room_ptr
 ldy #0
fb_loop
 lda (temp5),y
 cmp #3
 bne fb_none
 iny
 lda (temp5),y
 sta var46
 iny
 lda (temp5),y
 sta var47
 iny
 lda (temp5),y
 sta h
 iny
 lda (temp5),y
 sta o
 iny
 lda (temp5),y
 iny
 and #$40
 bne fb_loop
 jmp ball_center
fb_none
 rts

 ; base che contiene il centro del giocatore: temp1 = numero (255 se
 ; nessuna), temp3 = info
base_check
 jsr room_ptr
 lda player0x
 sec
 sbc #13
 lsr
 lsr
 sta temp2
 lda player0y
 sec
 sbc #4
 lsr
 lsr
 lsr
 sta temp3
 ldx #0
 ldy #0
bc_loop
 lda (temp5),y
 cmp #3
 bne bc_none
 iny
 ; c0 < colonna
 lda (temp5),y
 cmp temp2
 bcs bc_next4
 iny
 ; r0 < riga
 lda (temp5),y
 cmp temp3
 bcs bc_next3
 iny
 ; colonna < c1
 lda temp2
 cmp (temp5),y
 bcs bc_next2
 iny
 ; riga < r1
 lda temp3
 cmp (temp5),y
 bcs bc_next1
 iny
 lda (temp5),y
 sta temp3
 stx temp1
 rts
bc_next4
 iny
bc_next3
 iny
bc_next2
 iny
bc_next1
 iny
 iny
 inx
 jmp bc_loop
bc_none
 lda #255
 sta temp1
 rts

keybit
 .byte 4, 8
bitmask_b2
 .byte 1, 2, 4, 8, 16, 32, 64, 128
end

   ; punti vita per tipo x difficolta' (guardia, cecchino, drone, pesante)
   data ehp
   2, 3, 4, 5, 1, 2, 3, 4, 1, 1, 2, 3, 4, 5, 6, 7
end

   inline rooms.asm
