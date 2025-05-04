    set romsize 32k

    const fontstyle = SQUISH ; Shorter font to save lines
    const extendedtxt = 1
    const textbank = 8
    

    dim CurrentSound = a
    dim JoystickHeldBit0 = b
    dim SoundPlayingBit1 = b
    dim SoundDataLoc = c ; d also used
    dim SoundChannel = e
    dim SoundVolume = f
    dim SoundFrequency = g
    dim SoundDuration = h
    dim CurrentSoundAdjusted = i
    dim TextIndex = z

    dim sc2 = score+0
    dim sc1 = score+1
    dim sc0 = score+2


    sc2 = $AA
    sc1 = $A0

    scorecolor = $AA
    TextColor = $0F
    COLUPF = $00
    CTRLPF = $21
    ballheight = $FF

Main
    if !joy0left && !joy0right then goto ____no_joystick
    if JoystickHeldBit0{0} then goto ____done_joystick
    JoystickHeldBit0{0} = 1
    if !joy0left then goto ____skip_decrease_sound
    if CurrentSound then goto ____skip_wrap_left
    score = 116
    TextIndex = 120
    TextColor = $FF
    CurrentSound = #total_sounds - 1
    goto ____done_decrease_sound
____skip_wrap_left
    score = score - 1
    CurrentSound = CurrentSound - 1
    TextIndex = TextIndex - 1
    for temp5 = 0 to #skipped_text_lines_length-1
        if TextIndex = skipped_text_lines[temp5] then TextIndex = TextIndex - 1
    next
    TextColor = TextColor - $10
    goto ____done_decrease_sound
____skip_decrease_sound
    CurrentSound = CurrentSound + 1
    TextIndex = TextIndex + 1
    for temp5 = 0 to #skipped_text_lines_length-1
        if TextIndex = skipped_text_lines[temp5] then TextIndex = TextIndex + 1
    next
    score = score + 1
    TextColor = TextColor + $10
    if CurrentSound < #total_sounds then goto ____skip_wrap_right
    CurrentSound = 0
    TextIndex = 0
    score = 0
    TextColor = $0F
____skip_wrap_right
____done_decrease_sound
    sc2 = $AA
    sc1 = sc1|$A0
    goto ____done_joystick
____no_joystick
    JoystickHeldBit0{0} = 0
____done_joystick

    if !SoundPlayingBit1{1} then goto ____skip_sound_player
    if CurrentSound >= 114 then gosub PlaySound7 bank7 : goto ____skip_sound_player
    if CurrentSound >= 95 then gosub PlaySound6 bank6 : goto ____skip_sound_player
    if CurrentSound >= 76 then gosub PlaySound5 bank5 : goto ____skip_sound_player
    if CurrentSound >= 57 then gosub PlaySound4 bank4 : goto ____skip_sound_player
    if CurrentSound >= 38 then gosub PlaySound3 bank3 : goto ____skip_sound_player
    if CurrentSound >= 19 then gosub PlaySound2 bank2 : goto ____skip_sound_player
    gosub PlaySound1
____skip_sound_player

    if !joy0fire || SoundPlayingBit1{1} then goto ____skip_start_sound
    if CurrentSound >= 114 then gosub InitSound7 bank7 : goto ____skip_start_sound
    if CurrentSound >= 95 then gosub InitSound6 bank6 : goto ____skip_start_sound
    if CurrentSound >= 76 then gosub InitSound5 bank5 : goto ____skip_start_sound
    if CurrentSound >= 57 then gosub InitSound4 bank4 : goto ____skip_start_sound
    if CurrentSound >= 38 then gosub InitSound3 bank3 : goto ____skip_start_sound
    if CurrentSound >= 19 then gosub InitSound2 bank2 : goto ____skip_start_sound
    gosub InitSound1
____skip_start_sound

    drawscreen
    goto Main
; End Main

PlaySound1
    if SoundDuration then SoundDuration = SoundDuration - 1
    if SoundDuration then return thisbank
    SoundVolume = sread(SoundDataLoc)
    if SoundVolume <> $FF then goto ____skip_end_sound1
    SoundPlayingBit1{1} = 0
    AUDC0 = 0 : AUDV0 = 0 : COLUPF = 0
    bally = 200 ; offscreen
    return thisbank
____skip_end_sound1
    SoundChannel = sread(SoundDataLoc)
    SoundFrequency = sread(SoundDataLoc)
    SoundDuration = sread(SoundDataLoc)
    AUDC0 = SoundChannel
    AUDV0 = SoundVolume
    AUDF0 = SoundFrequency
    gosub SoundVisual
    return thisbank
; End PlaySound1

InitSound1
    if SoundPlayingBit1{1} then goto ____skip_sound_init_1
    on CurrentSound gosub Init_salvolasershot Init_spaceinvshoot Init_berzerkrobotdeath Init_echo1 Init_echo2 Init_jumpman Init_cavalry Init_alientrill1 Init_alientrill2 Init_pitfalljump Init_advpickup Init_advdrop Init_advbite Init_advdragonslain Init_bling Init_dropmedium Init_electrobump Init_explosion Init_humanoid
    SoundPlayingBit1{1} = 1
____skip_sound_init_1
    return thisbank
; End InitSound1



SoundVisual
    bally = 88
    ballx = multiply_by_5[SoundFrequency]
    if !SoundVolume then COLUPF = 0 else COLUPF = (SoundChannel * 16) + SoundVolume
    return
; End SoundVisual

    data multiply_by_5
    0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60
    65, 70, 75, 80, 85, 90, 95, 100, 105, 110, 115
    120, 125, 130, 135, 140, 145, 150, 155
end

    data skipped_text_lines
    21, 42, 85, 106
end

Init_salvolasershot
    sdata sfx_salvolasershot = SoundDataLoc
    $8, $8, $04
    2
    $7, $8, $05
    2
    $7, $8, $04
    2
    $7, $8, $05
    2
    $7, $8, $06
    2
    $6, $8, $07
    2
    $6, $8, $06
    2
    $6, $8, $07
    2
    $6, $8, $08
    2
    $6, $8, $09
    2
    $6, $8, $08
    2
    $6, $8, $09
    2
    $4, $8, $0a
    2
    $4, $8, $09
    2
    $4, $8, $0a
    2
    $4, $8, $0b
    2
    $4, $8, $0a
    2
    $4, $8, $0b
    2
    $4, $8, $0c
    2
    $2, $8, $0b
    2
    $2, $8, $0c
    2
    $2, $8, $0d
    2
    $FF
end
    return
; End Init_salvolasershot

Init_spaceinvshoot
    sdata sfx_spaceinvshoot = SoundDataLoc
    $8, $8, $18
    4
    $5, $8, $19
    4
    $5, $8, $19
    4
    $5, $8, $19
    4
    $5, $8, $19
    4
    $2, $8, $1C
    4
    $2, $8, $1C
    4
    $2, $8, $1C
    4
    $2, $8, $1C
    4
    $2, $8, $1C
    4
    $1, $8, $1E
    4
    $1, $8, $1E
    4
    $1, $8, $1E
    4
    $1, $8, $1E
    4
    $1, $8, $1E
    4
    $FF
end
    return
; End Init_spaceinvshoot

Init_berzerkrobotdeath
    sdata sfx_berzerkrobotdeath = SoundDataLoc
    $F, $8, $00
    1
    $E, $8, $01
    1
    $D, $8, $02
    1
    $C, $8, $03
    1
    $B, $8, $04
    1
    $A, $8, $05
    1
    $9, $8, $06
    1
    $8, $8, $07
    1
    $7, $8, $08
    1
    $6, $8, $09
    1
    $5, $8, $0a
    1
    $4, $8, $0b
    1
    $3, $8, $0c
    1
    $2, $8, $0d
    1
    $1, $8, $0e
    1
    $FF
end
    return
; End Init_berzerkrobotdeath

Init_echo1
    sdata sfx_echo1 = SoundDataLoc
    $a, $6, $18
    9
    $a, $6, $08
    9
    $0, $0, $01
    9
    $5, $6, $18
    9
    $5, $6, $08
    9
    $0, $0, $01
    9
    $2, $6, $18
    9
    $2, $6, $08
    9
    $FF
end
    return
; End Init_echo1

Init_echo2
    sdata sfx_echo2 = SoundDataLoc
    $A, $4, $1F
    5
    $0, $0, $01
    5
    $5, $4, $1F
    5
    $0, $0, $01
    5
    $2, $4, $1F
    5
    $FF
end
    return
; End Init_echo2

Init_jumpman
    sdata sfx_jumpman = SoundDataLoc
    $8, $4, $1E
    5
    $8, $4, $1B
    5
    $8, $4, $18
    5
    $8, $4, $11
    5
    $8, $4, $16
    5
    $FF
end
    return
; End Init_jumpman

Init_cavalry
    sdata sfx_cavalry = SoundDataLoc
    $8, $4, $1D
    6
    $8, $4, $1A
    6
    $8, $4, $17
    6
    $8, $4, $13
    6
    $8, $4, $17
    6
    $8, $4, $13
    6
    $8, $4, $13
    6
    $FF
end
    return
; End Init_cavalry

Init_alientrill1
    sdata sfx_alientrill1 = SoundDataLoc
    $8, $4, $1B
    2
    $8, $4, $1E
    2
    $8, $4, $1B
    2
    $8, $4, $1E
    2
    $8, $4, $18
    2
    $FF
end
    return
; End Init_alientrill1

Init_alientrill2
    sdata sfx_alientrill2 = SoundDataLoc
    $8, $4, $18
    2
    $8, $4, $1E
    2
    $8, $4, $18
    2
    $8, $4, $1E
    2
    $8, $4, $14
    2
    $FF
end
    return
; End Init_alientrill2

Init_pitfalljump
    sdata sfx_pitfalljump = SoundDataLoc
    $4, $1, $06
    4
    $4, $1, $04
    4
    $4, $1, $03
    4
    $4, $1, $02
    4
    $4, $1, $04
    4
    $FF
end
    return
; End Init_pitfalljump

Init_advpickup
    sdata sfx_advpickup = SoundDataLoc
    $8, $6, $03
    3
    $8, $6, $02
    3
    $8, $6, $01
    3
    $8, $6, $00
    3
    $FF
end
    return
; End Init_advpickup

Init_advdrop
    sdata sfx_advdrop = SoundDataLoc
    $8, $6, $00
    3
    $8, $6, $01
    3
    $8, $6, $02
    3
    $8, $6, $03
    3
    $FF
end
    return
; End Init_advdrop

Init_advbite
    sdata sfx_advbite = SoundDataLoc
    $F, $3, $1F
    3
    $E, $8, $1F
    3
    $D, $3, $1F
    3
    $C, $8, $1F
    3
    $B, $3, $1F
    3
    $A, $8, $1F
    3
    $9, $3, $1F
    3
    $8, $8, $1F
    3
    $7, $3, $1F
    3
    $6, $8, $1F
    3
    $5, $3, $1F
    3
    $4, $8, $1F
    3
    $3, $3, $1F
    3
    $2, $8, $1F
    3
    $1, $3, $1F
    3
    $FF
end
    return
; End Init_advbite

Init_advdragonslain
    sdata sfx_advdragonslain = SoundDataLoc
    $F, $4, $10
    3
    $E, $4, $11
    3
    $D, $4, $12
    3
    $C, $4, $13
    3
    $B, $4, $14
    3
    $A, $4, $15
    3
    $9, $4, $16
    3
    $8, $4, $17
    3
    $7, $4, $18
    3
    $6, $4, $19
    3
    $5, $4, $1A
    3
    $4, $4, $1B
    3
    $3, $4, $1C
    3
    $2, $4, $1D
    3
    $1, $4, $1E
    3
    $FF
end
    return
; End Init_advdragonslain

Init_bling
    sdata sfx_bling = SoundDataLoc
    $7, $4, $1c
    1
    $7, $4, $1b
    1
    $5, $f, $04
    1
    $9, $4, $15
    1
    $7, $4, $16
    1
    $4, $f, $03
    1
    $8, $4, $11
    1
    $8, $4, $11
    1
    $4, $4, $11
    1
    $9, $4, $0e
    1
    $7, $4, $0e
    1
    $4, $4, $0e
    1
    $7, $4, $1c
    1
    $5, $4, $1b
    1
    $4, $4, $1c
    1
    $2, $4, $1b
    1
    $FF
end
    return
; End Init_bling

Init_dropmedium
    sdata sfx_dropmedium = SoundDataLoc
    $0, $4, $00
    1
    $c, $6, $03
    1
    $f, $c, $0d
    1
    $4, $4, $1b
    1
    $0, $c, $06
    1
    $0, $6, $00
    1
    $0, $6, $07
    1
    $0, $c, $10
    1
    $0, $c, $0d
    1
    $0, $c, $10
    1
    $0, $6, $03
    1
    $0, $c, $10
    1
    $0, $4, $1b
    1
    $0, $c, $10
    1
    $0, $c, $10
    1
    $0, $6, $03
    1
    $FF
end
    return
; End Init_dropmedium

Init_electrobump
    sdata sfx_electrobump = SoundDataLoc
    $a, $8, $08
    2
    $a, $c, $08
    2
    $a, $6, $08
    2
    $a, $e, $08
    2
    $8, $6, $08
    2
    $8, $6, $08
    2
    $6, $e, $08
    2
    $4, $6, $08
    2
    $2, $6, $08
    2
    $FF
end
    return
; End Init_electrobump

Init_explosion
    sdata sfx_explosion = SoundDataLoc
    $2, $8, $01
    1
    $5, $c, $0b
    1
    $8, $6, $04
    1
    $f, $e, $03
    1
    $f, $6, $09
    1
    $f, $6, $0d
    1
    $f, $e, $04
    1
    $8, $6, $0f
    1
    $4, $6, $09
    1
    $3, $1, $16
    1
    $4, $6, $0c
    1
    $5, $6, $09
    1
    $3, $6, $0a
    1
    $5, $6, $09
    1
    $8, $6, $0d
    1
    $4, $6, $09
    1
    $6, $e, $04
    1
    $5, $6, $0f
    1
    $7, $6, $0f
    1
    $7, $e, $04
    1
    $6, $6, $08
    1
    $8, $e, $03
    1
    $6, $6, $0f
    1
    $5, $6, $09
    1
    $5, $6, $06
    1
    $5, $e, $03
    1
    $6, $6, $0e
    1
    $5, $e, $02
    1
    $3, $6, $0f
    1
    $6, $6, $0e
    1
    $5, $6, $09
    1
    $5, $6, $0c
    1
    $3, $6, $0f
    1
    $8, $e, $04
    1
    $3, $6, $0c
    1
    $3, $6, $0f
    1
    $6, $6, $0c
    1
    $4, $6, $0f
    1
    $5, $6, $0f
    1
    $3, $6, $0f
    1
    $4, $6, $0a
    1
    $3, $6, $0f
    1
    $3, $6, $08
    1
    $3, $6, $0c
    1
    $3, $6, $0e
    1
    $3, $6, $08
    1
    $FF
end
    return
; End Init_explosion

Init_humanoid
    sdata sfx_humanoid = SoundDataLoc
    $5, $2, $01
    1
    $3, $6, $0f
    1
    $6, $4, $15
    1
    $6, $4, $19
    1
    $5, $1, $0a
    1
    $8, $4, $14
    1
    $8, $4, $17
    1
    $7, $f, $04
    1
    $7, $4, $13
    1
    $a, $4, $16
    1
    $9, $4, $1b
    1
    $7, $1, $15
    1
    $9, $4, $15
    1
    $9, $4, $18
    1
    $7, $4, $15
    1
    $8, $4, $14
    1
    $8, $4, $17
    1
    $7, $4, $1b
    1
    $9, $4, $13
    1
    $b, $4, $16
    1
    $9, $4, $1a
    1
    $6, $f, $03
    1
    $6, $4, $15
    1
    $6, $4, $18
    1
    $5, $f, $04
    1
    $4, $4, $09
    1
    $6, $4, $0b
    1
    $6, $4, $0d
    1
    $5, $4, $09
    1
    $5, $4, $0b
    1
    $5, $4, $0d
    1
    $6, $4, $0a
    1
    $6, $4, $15
    1
    $6, $4, $18
    1
    $6, $4, $1c
    1
    $FF
end
    return
; End Init_humanoid


    bank 2 

Init_transporter
    sdata sfx_transporter = SoundDataLoc
    $0, $4, $00
    1
    $2, $4, $09
    1
    $1, $c, $02
    1
    $4, $c, $02
    1
    $2, $c, $02
    1
    $a, $4, $06
    1
    $4, $4, $06
    1
    $3, $c, $01
    1
    $3, $4, $04
    1
    $6, $4, $04
    1
    $4, $4, $0a
    1
    $4, $4, $03
    1
    $5, $c, $01
    1
    $8, $4, $06
    1
    $4, $c, $01
    1
    $2, $4, $06
    1
    $4, $4, $04
    1
    $9, $4, $04
    1
    $5, $4, $0a
    1
    $7, $4, $03
    1
    $6, $4, $06
    1
    $7, $4, $06
    1
    $3, $4, $06
    1
    $8, $4, $04
    1
    $a, $4, $03
    1
    $6, $4, $03
    1
    $6, $c, $00
    1
    $5, $4, $0a
    1
    $5, $c, $00
    1
    $f, $c, $02
    1
    $5, $4, $07
    1
    $7, $4, $09
    1
    $a, $4, $07
    1
    $4, $4, $0d
    1
    $c, $4, $10
    1
    $a, $c, $02
    1
    $2, $4, $07
    1
    $5, $6, $00
    1
    $b, $c, $02
    1
    $6, $4, $0c
    1
    $3, $4, $0c
    1
    $1, $c, $00
    1
    $4, $4, $06
    1
    $2, $4, $07
    1
    $1, $4, $06
    1
    $2, $4, $06
    1
    $1, $c, $04
    1
    $3, $4, $07
    1
    $1, $c, $01
    1
    $1, $4, $06
    1
    $1, $4, $06
    1
    $1, $4, $07
    1
    $0, $4, $07
    1
    $0, $c, $05
    1
    $0, $4, $07
    1
    $0, $4, $0c
    1
    $0, $6, $0f
    1
    $0, $4, $00
    1
    $0, $4, $00
    1
    $0, $4, $00
    1
    $0, $4, $00
    1
    $0, $4, $00
    1
    $0, $4, $00
    1
    $FF
end
    return
; End Init_transporter

Init_twinkle
    sdata sfx_twinkle = SoundDataLoc
    $0, $4, $00
    1
    $3, $c, $02
    1
    $e, $4, $0d
    1
    $d, $4, $10
    1
    $8, $4, $1b
    1
    $d, $c, $04
    1
    $a, $4, $0a
    1
    $f, $4, $09
    1
    $b, $4, $0c
    1
    $d, $4, $10
    1
    $2, $c, $02
    1
    $7, $4, $1b
    1
    $6, $4, $1b
    1
    $8, $4, $0c
    1
    $8, $c, $02
    1
    $b, $4, $0a
    1
    $9, $6, $00
    1
    $7, $4, $16
    1
    $b, $4, $1b
    1
    $8, $4, $18
    1
    $5, $c, $03
    1
    $b, $4, $09
    1
    $a, $4, $09
    1
    $7, $6, $00
    1
    $c, $4, $16
    1
    $a, $4, $1b
    1
    $b, $4, $18
    1
    $7, $c, $04
    1
    $8, $4, $09
    1
    $5, $4, $0c
    1
    $f, $c, $05
    1
    $d, $c, $06
    1
    $8, $c, $0b
    1
    $b, $4, $12
    1
    $c, $4, $0d
    1
    $b, $4, $09
    1
    $7, $4, $0c
    1
    $b, $c, $05
    1
    $8, $c, $06
    1
    $4, $c, $0b
    1
    $6, $4, $12
    1
    $5, $4, $0c
    1
    $2, $4, $09
    1
    $4, $4, $0c
    1
    $2, $4, $12
    1
    $2, $4, $18
    1
    $1, $4, $1e
    1
    $1, $4, $12
    1
    $FF
end
    return
; End Init_twinkle

Init_electroswitch
    sdata sfx_electroswitch = SoundDataLoc
    $F, $4, $06
    3
    $8, $4, $0C
    3
    $4, $4, $18
    3
    $2, $4, $31
    3
    $FF
end
    return
; End Init_electroswitch

Init_nonobounce
    sdata sfx_nonobounce = SoundDataLoc
    $4, $c, $0f
    2
    $8, $e, $00
    2
    $8, $c, $10
    2
    $6, $6, $02
    2
    $6, $c, $10
    2
    $6, $6, $02
    2
    $8, $e, $00
    2
    $8, $c, $10
    2
    $8, $6, $02
    2
    $6, $c, $0f
    2
    $6, $c, $10
    2
    $6, $6, $02
    2
    $6, $c, $10
    2
    $4, $c, $0f
    2
    $4, $c, $10
    2
    $4, $c, $0f
    2
    $4, $e, $00
    2
    $4, $c, $10
    2
    $2, $c, $10
    2
    $FF
end
    return
; End Init_nonobounce

Init_70stvcomputer
    sdata sfx_70stvcomputer = SoundDataLoc
    $6, $8, $01
    2
    $8, $8, $01
    2
    $8, $1, $0c
    2
    $6, $9, $0b
    2
    $8, $1, $03
    2
    $8, $f, $04
    2
    $8, $1, $10
    2
    $8, $4, $16
    2
    $8, $7, $06
    2
    $8, $8, $01
    2
    $8, $4, $1f
    2
    $8, $6, $01
    2
    $8, $c, $0b
    2
    $8, $8, $01
    2
    $8, $9, $0e
    2
    $8, $c, $0e
    2
    $8, $e, $00
    2
    $8, $8, $01
    2
    $8, $9, $08
    2
    $8, $9, $0c
    2
    $8, $c, $0c
    2
    $8, $1, $0c
    2
    $8, $8, $01
    2
    $8, $c, $0a
    2
    $8, $1, $06
    2
    $8, $9, $0c
    2
    $8, $4, $10
    2
    $8, $9, $0f
    2
    $8, $1, $03
    2
    $8, $1, $1c
    2
    $8, $1, $15
    2
    $8, $9, $0c
    2
    $8, $7, $07
    2
    $8, $8, $01
    2
    $8, $7, $00
    2
    $8, $8, $01
    2
    $8, $f, $01
    2
    $8, $c, $0d
    2
    $8, $c, $0b
    2
    $8, $8, $01
    2
    $8, $f, $01
    2
    $8, $c, $0d
    2
    $8, $c, $0b
    2
    $8, $8, $01
    2
    $8, $1, $1a
    2
    $6, $9, $0d
    2
    $6, $1, $08
    2
    $6, $1, $1b
    2
    $6, $f, $04
    2
    $6, $f, $02
    2
    $6, $1, $08
    2
    $6, $7, $04
    2
    $6, $4, $1f
    2
    $6, $1, $1a
    2
    $6, $7, $02
    2
    $6, $1, $04
    2
    $4, $1, $04
    2
    $4, $7, $07
    2
    $2, $c, $0c
    2
    $2, $c, $0a
    2
    $1, $c, $0a
    2
    $FF
end
    return
; End Init_70stvcomputer

Init_alienlife
    sdata sfx_alienlife = SoundDataLoc
    $4, $4, $16
    2
    $7, $4, $16
    2
    $f, $4, $16
    2
    $e, $4, $16
    2
    $7, $c, $04
    2
    $7, $4, $0d
    2
    $4, $c, $03
    2
    $4, $c, $03
    2
    $2, $c, $04
    2
    $4, $c, $05
    2
    $4, $4, $12
    2
    $2, $4, $12
    2
    $4, $c, $05
    2
    $2, $c, $05
    2
    $2, $c, $05
    2
    $2, $4, $10
    2
    $1, $6, $00
    2
    $FF
end
    return
; End Init_alienlife

Init_chirp
    sdata sfx_chirp = SoundDataLoc
    $e, $4, $07
    1
    $e, $4, $0a
    1
    $e, $4, $0c
    1
    $f, $4, $09
    1
    $e, $4, $0a
    1
    $1, $4, $07
    1
    $0, $4, $09
    1
    $FF
end
    return
; End Init_chirp

Init_plonk
    sdata sfx_plonk = SoundDataLoc
    $d, $1, $13
    1
    $f, $1, $12
    1
    $d, $4, $0d
    1
    $b, $1, $12
    1
    $5, $1, $12
    1
    $3, $7, $06
    1
    $2, $f, $0a
    1
    $1, $7, $09
    1
    $0, $f, $10
    1
    $0, $c, $1b
    1
    $0, $e, $0b
    1
    $0, $6, $09
    1
    $1, $1, $12
    1
    $1, $7, $0a
    1
    $FF
end
    return
; End Init_plonk

Init_spawn
    sdata sfx_spawn = SoundDataLoc
    $e, $4, $16
    2
    $e, $4, $15
    2
    $e, $4, $15
    2
    $e, $4, $12
    2
    $e, $4, $0e
    2
    $e, $4, $0c
    2
    $e, $4, $0e
    2
    $e, $4, $12
    2
    $a, $4, $15
    2
    $8, $4, $15
    2
    $FF
end
    return
; End Init_spawn

Init_maser
    sdata sfx_maser = SoundDataLoc
    $a, $4, $14
    1
    $f, $4, $16
    1
    $d, $4, $19
    1
    $f, $7, $0b
    1
    $f, $7, $0c
    1
    $d, $7, $00
    1
    $e, $4, $0f
    1
    $a, $1, $06
    1
    $b, $4, $17
    1
    $a, $7, $0a
    1
    $a, $1, $16
    1
    $3, $7, $19
    1
    $2, $c, $10
    1
    $0, $c, $17
    1
    $2, $f, $15
    1
    $2, $7, $1f
    1
    $FF
end
    return
; End Init_maser

Init_rubbermallet
    sdata sfx_rubbermallet = SoundDataLoc
    $f, $7, $1c
    1
    $f, $7, $1b
    1
    $f, $7, $1c
    1
    $f, $c, $1a
    1
    $f, $c, $12
    1
    $e, $7, $1e
    1
    $e, $c, $17
    1
    $8, $7, $1d
    1
    $8, $c, $12
    1
    $9, $7, $18
    1
    $8, $c, $17
    1
    $7, $c, $12
    1
    $4, $c, $1b
    1
    $1, $c, $14
    1
    $1, $1, $13
    1
    $FF
end
    return
; End Init_rubbermallet

Init_alienkitty
    sdata sfx_alienkitty = SoundDataLoc
    $1, $6, $01
    1
    $3, $1, $16
    1
    $6, $4, $18
    1
    $f, $4, $19
    1
    $e, $7, $0e
    1
    $c, $4, $19
    1
    $c, $4, $19
    1
    $c, $4, $18
    1
    $a, $4, $17
    1
    $a, $1, $15
    1
    $a, $4, $06
    1
    $a, $f, $19
    1
    $6, $4, $06
    1
    $4, $4, $17
    1
    $4, $4, $17
    1
    $3, $4, $17
    1
    $3, $c, $1a
    1
    $2, $4, $0c
    1
    $2, $4, $19
    1
    $1, $4, $17
    1
    $FF
end
    return
; End Init_alienkitty

Init_electropunch
    sdata sfx_electropunch = SoundDataLoc
    $f, $6, $07
    1
    $8, $6, $0f
    1
    $a, $4, $1e
    1
    $8, $6, $0f
    1
    $6, $4, $12
    1
    $5, $6, $0f
    1
    $6, $6, $0f
    1
    $3, $4, $0c
    1
    $1, $6, $07
    1
    $3, $4, $0a
    1
    $1, $c, $02
    1
    $FF
end
    return
; End Init_electropunch

Init_drip
    sdata sfx_drip = SoundDataLoc
    $f, $c, $17
    1
    $a, $c, $17
    1
    $a, $c, $0d
    1
    $7, $6, $1e
    1
    $1, $c, $12
    1
    $0, $6, $1e
    1
    $2, $6, $1e
    1
    $0, $6, $03
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $1, $6, $03
    1
    $2, $6, $03
    1
    $1, $c, $12
    1
    $0, $c, $10
    1
    $0, $6, $1e
    1
    $1, $6, $1e
    1
    $FF
end
    return
; End Init_drip

Init_ribbit
    sdata sfx_ribbit = SoundDataLoc
    $4, $6, $0c
    1
    $f, $6, $19
    1
    $f, $6, $19
    1
    $f, $6, $19
    1
    $9, $6, $0c
    1
    $f, $6, $19
    1
    $f, $6, $19
    1
    $6, $6, $08
    1
    $f, $6, $19
    1
    $f, $6, $19
    1
    $f, $6, $19
    1
    $f, $6, $19
    1
    $7, $6, $08
    1
    $f, $6, $19
    1
    $d, $6, $19
    1
    $f, $6, $19
    1
    $c, $6, $19
    1
    $d, $6, $19
    1
    $5, $6, $19
    1
    $9, $6, $19
    1
    $3, $6, $19
    1
    $4, $6, $19
    1
    $FF
end
    return
; End Init_ribbit

Init_wolfwhistle
    sdata sfx_wolfwhistle = SoundDataLoc
    $2, $4, $12
    1
    $4, $4, $12
    1
    $3, $4, $12
    1
    $5, $4, $12
    1
    $6, $c, $05
    1
    $7, $4, $10
    1
    $5, $4, $0f
    1
    $6, $4, $0f
    1
    $7, $4, $0d
    1
    $6, $4, $0c
    1
    $8, $c, $03
    1
    $6, $4, $0a
    1
    $9, $4, $09
    1
    $9, $4, $09
    1
    $9, $c, $02
    1
    $c, $c, $02
    1
    $8, $c, $02
    1
    $d, $c, $02
    1
    $a, $4, $07
    1
    $a, $4, $07
    1
    $b, $4, $07
    1
    $f, $4, $07
    1
    $a, $4, $07
    1
    $f, $4, $06
    1
    $8, $4, $06
    1
    $5, $4, $06
    1
    $4, $4, $06
    1
    $4, $4, $06
    1
    $1, $4, $06
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $b, $4, $1c
    1
    $f, $c, $0b
    1
    $f, $c, $0d
    1
    $4, $c, $0d
    1
    $f, $c, $0c
    1
    $f, $c, $0a
    1
    $f, $c, $0a
    1
    $f, $4, $1e
    1
    $f, $4, $1b
    1
    $f, $4, $16
    1
    $f, $4, $13
    1
    $e, $4, $10
    1
    $b, $4, $0c
    1
    $9, $4, $0a
    1
    $9, $4, $0a
    1
    $8, $c, $02
    1
    $a, $c, $02
    1
    $a, $c, $02
    1
    $8, $c, $02
    1
    $1, $c, $02
    1
    $7, $c, $02
    1
    $7, $c, $02
    1
    $8, $c, $02
    1
    $4, $c, $02
    1
    $3, $4, $09
    1
    $3, $c, $03
    1
    $3, $c, $04
    1
    $2, $4, $13
    1
    $2, $4, $18
    1
    $2, $c, $0b
    1
    $2, $c, $1b
    1
    $2, $6, $0a
    1
    $FF
end
    return
; End Init_wolfwhistle

Init_cabwhistle
    sdata sfx_cabwhistle = SoundDataLoc
    $3, $4, $0a
    1
    $4, $4, $09
    1
    $4, $c, $02
    1
    $4, $4, $07
    1
    $5, $4, $06
    1
    $5, $4, $06
    1
    $6, $4, $06
    1
    $7, $4, $06
    1
    $6, $4, $06
    1
    $5, $4, $06
    1
    $6, $4, $07
    1
    $4, $c, $02
    1
    $a, $c, $02
    1
    $a, $4, $09
    1
    $b, $4, $0a
    1
    $b, $4, $0a
    1
    $f, $4, $0a
    1
    $b, $c, $03
    1
    $f, $c, $03
    1
    $f, $c, $03
    1
    $f, $c, $03
    1
    $f, $c, $03
    1
    $8, $c, $03
    1
    $f, $c, $03
    1
    $f, $c, $03
    1
    $f, $c, $03
    1
    $f, $c, $03
    1
    $9, $c, $03
    1
    $d, $4, $0a
    1
    $a, $4, $0a
    1
    $6, $4, $09
    1
    $7, $4, $09
    1
    $4, $c, $02
    1
    $3, $c, $02
    1
    $3, $4, $07
    1
    $2, $4, $07
    1
    $3, $4, $06
    1
    $3, $4, $06
    1
    $6, $4, $06
    1
    $6, $4, $06
    1
    $2, $4, $06
    1
    $FF
end
    return
; End Init_cabwhistle

Init_jumpo
    sdata sfx_jumpo = SoundDataLoc
    $3, $c, $1e
    1
    $1, $c, $1e
    1
    $6, $c, $1e
    1
    $6, $c, $1e
    1
    $4, $c, $1e
    1
    $3, $6, $1e
    1
    $5, $c, $1e
    1
    $a, $c, $1e
    1
    $6, $c, $1e
    1
    $6, $6, $1e
    1
    $6, $c, $1e
    1
    $4, $c, $1b
    1
    $2, $c, $1b
    1
    $8, $c, $1b
    1
    $b, $c, $1b
    1
    $c, $c, $1b
    1
    $a, $c, $1b
    1
    $4, $c, $1b
    1
    $5, $c, $1b
    1
    $7, $c, $1e
    1
    $7, $c, $1e
    1
    $2, $c, $10
    1
    $4, $c, $1e
    1
    $3, $c, $1e
    1
    $1, $c, $10
    1
    $6, $c, $1e
    1
    $6, $c, $1e
    1
    $4, $6, $07
    1
    $5, $6, $07
    1
    $b, $6, $07
    1
    $e, $6, $07
    1
    $e, $6, $07
    1
    $a, $6, $07
    1
    $5, $c, $17
    1
    $FF
end
    return
; End Init_jumpo

Init_pulsecannon
    sdata sfx_pulsecannon = SoundDataLoc
    $a, $c, $1e
    1
    $f, $6, $07
    1
    $f, $6, $07
    1
    $f, $6, $1e
    1
    $b, $c, $17
    1
    $b, $c, $1b
    1
    $f, $c, $1e
    1
    $f, $6, $07
    1
    $f, $6, $07
    1
    $8, $6, $1e
    1
    $6, $c, $17
    1
    $f, $c, $1b
    1
    $f, $c, $1e
    1
    $f, $6, $07
    1
    $f, $6, $07
    1
    $a, $6, $0a
    1
    $a, $c, $17
    1
    $4, $c, $1e
    1
    $9, $6, $1e
    1
    $5, $4, $1b
    1
    $f, $6, $07
    1
    $9, $6, $0a
    1
    $d, $c, $17
    1
    $9, $c, $1b
    1
    $5, $6, $0a
    1
    $3, $c, $17
    1
    $FF
end
    return
; End Init_pulsecannon

PlaySound2
    if SoundDuration then SoundDuration = SoundDuration - 1
    if SoundDuration then return otherbank
    SoundVolume = sread(SoundDataLoc)
    if SoundVolume <> $FF then goto ____skip_end_sound2
    SoundPlayingBit1{1} = 0
    AUDC0 = 0 : AUDV0 = 0 : COLUPF = 0
    bally = 200 ; offscreen
    return otherbank
____skip_end_sound2
    SoundChannel = sread(SoundDataLoc)
    SoundFrequency = sread(SoundDataLoc)
    SoundDuration = sread(SoundDataLoc)
    AUDC0 = SoundChannel
    AUDV0 = SoundVolume
    AUDF0 = SoundFrequency
    gosub SoundVisual bank1
    return otherbank
; End PlaySound2

InitSound2
    if SoundPlayingBit1{1} then goto ____skip_sound_init_2
    CurrentSoundAdjusted = CurrentSound - 19
    on CurrentSoundAdjusted gosub Init_transporter Init_twinkle Init_electroswitch Init_nonobounce Init_70stvcomputer Init_alienlife Init_chirp Init_plonk Init_spawn Init_maser Init_rubbermallet Init_alienkitty Init_electropunch Init_drip Init_ribbit Init_wolfwhistle Init_cabwhistle Init_jumpo Init_pulsecannon
    SoundPlayingBit1{1} = 1
____skip_sound_init_2
    return otherbank
; End InitSound2


    bank 3 

Init_spring
    sdata sfx_spring = SoundDataLoc
    $f, $c, $0d
    1
    $d, $c, $0d
    1
    $b, $c, $10
    1
    $f, $c, $10
    1
    $6, $c, $1e
    1
    $5, $c, $0e
    1
    $c, $c, $0e
    1
    $f, $c, $12
    1
    $d, $c, $12
    1
    $f, $c, $10
    1
    $f, $c, $0e
    1
    $f, $c, $0d
    1
    $a, $c, $12
    1
    $b, $6, $07
    1
    $7, $c, $1e
    1
    $f, $c, $10
    1
    $e, $c, $10
    1
    $d, $c, $0e
    1
    $7, $c, $17
    1
    $8, $6, $07
    1
    $7, $c, $1e
    1
    $8, $c, $10
    1
    $a, $c, $0e
    1
    $d, $c, $0d
    1
    $6, $c, $0d
    1
    $5, $c, $1e
    1
    $3, $4, $1c
    1
    $8, $c, $0d
    1
    $b, $c, $0c
    1
    $6, $c, $0c
    1
    $8, $c, $0e
    1
    $4, $c, $1b
    1
    $a, $c, $0c
    1
    $3, $c, $0c
    1
    $7, $c, $0a
    1
    $4, $c, $0d
    1
    $7, $c, $0d
    1
    $5, $c, $0b
    1
    $5, $c, $0a
    1
    $3, $4, $1e
    1
    $FF
end
    return
; End Init_spring

Init_buzzbomb
    sdata sfx_buzzbomb = SoundDataLoc
    $5, $6, $03
    1
    $f, $6, $0f
    1
    $f, $6, $0f
    1
    $b, $6, $07
    1
    $f, $6, $07
    1
    $f, $6, $0f
    1
    $e, $6, $07
    1
    $f, $6, $0f
    1
    $a, $6, $0f
    1
    $f, $6, $0f
    1
    $a, $c, $1b
    1
    $8, $6, $0f
    1
    $7, $6, $03
    1
    $6, $6, $07
    1
    $7, $6, $03
    1
    $5, $6, $0f
    1
    $5, $6, $07
    1
    $4, $6, $0f
    1
    $4, $6, $07
    1
    $2, $6, $07
    1
    $2, $6, $0f
    1
    $1, $c, $1b
    1
    $FF
end
    return
; End Init_buzzbomb

Init_bassbump
    sdata sfx_bassbump = SoundDataLoc
    $f, $c, $1b
    1
    $c, $6, $0f
    1
    $e, $6, $07
    1
    $f, $6, $0f
    1
    $f, $6, $0f
    1
    $f, $6, $0f
    1
    $6, $6, $07
    1
    $f, $6, $0f
    1
    $4, $c, $1b
    1
    $5, $6, $0f
    1
    $6, $6, $0f
    1
    $1, $6, $07
    1
    $3, $6, $0f
    1
    $FF
end
    return
; End Init_bassbump

Init_hophop
    sdata sfx_hophop = SoundDataLoc
    $2, $c, $04
    1
    $3, $6, $0f
    1
    $6, $4, $10
    1
    $9, $c, $04
    1
    $9, $6, $00
    1
    $b, $6, $1e
    1
    $9, $6, $1e
    1
    $9, $c, $0c
    1
    $b, $4, $15
    1
    $7, $c, $03
    1
    $a, $c, $04
    1
    $c, $4, $15
    1
    $f, $4, $0c
    1
    $f, $6, $1e
    1
    $c, $6, $1e
    1
    $9, $6, $1e
    1
    $c, $4, $13
    1
    $f, $4, $10
    1
    $f, $4, $10
    1
    $f, $4, $10
    1
    $a, $c, $0c
    1
    $8, $c, $0c
    1
    $2, $c, $0e
    1
    $4, $6, $1e
    1
    $2, $6, $1e
    1
    $1, $6, $1e
    1
    $FF
end
    return
; End Init_hophop

Init_distressed
    sdata sfx_distressed = SoundDataLoc
    $2, $6, $00
    1
    $1, $6, $00
    1
    $9, $4, $0f
    1
    $a, $6, $00
    1
    $b, $c, $04
    1
    $b, $4, $0f
    1
    $9, $4, $12
    1
    $b, $4, $0c
    1
    $f, $4, $15
    1
    $f, $4, $15
    1
    $e, $c, $03
    1
    $f, $4, $0c
    1
    $f, $c, $0c
    1
    $b, $4, $0d
    1
    $7, $c, $04
    1
    $5, $6, $00
    1
    $4, $6, $00
    1
    $3, $6, $00
    1
    $2, $6, $00
    1
    $FF
end
    return
; End Init_distressed

Init_ouch
    sdata sfx_ouch = SoundDataLoc
    $f, $c, $07
    1
    $f, $c, $07
    1
    $f, $c, $07
    1
    $7, $4, $18
    1
    $4, $4, $19
    1
    $9, $c, $07
    1
    $f, $4, $19
    1
    $d, $4, $19
    1
    $f, $4, $19
    1
    $f, $4, $19
    1
    $f, $4, $1b
    1
    $f, $4, $1b
    1
    $f, $4, $1b
    1
    $f, $4, $1b
    1
    $9, $4, $1b
    1
    $5, $4, $1b
    1
    $3, $4, $1b
    1
    $2, $4, $1b
    1
    $1, $4, $1c
    1
    $1, $4, $1c
    1
    $1, $4, $1c
    1
    $2, $4, $1b
    1
    $0, $4, $19
    1
    $0, $4, $1b
    1
    $1, $4, $19
    1
    $FF
end
    return
; End Init_ouch

Init_laserrecoil
    sdata sfx_laserrecoil = SoundDataLoc
    $f, $c, $06
    1
    $f, $4, $16
    1
    $f, $4, $16
    1
    $f, $4, $1e
    1
    $f, $c, $0b
    1
    $f, $c, $0b
    1
    $f, $6, $1e
    1
    $c, $6, $1e
    1
    $9, $4, $16
    1
    $9, $4, $1e
    1
    $f, $4, $1e
    1
    $f, $c, $0b
    1
    $f, $c, $0e
    1
    $4, $c, $0d
    1
    $5, $c, $07
    1
    $3, $4, $1b
    1
    $2, $c, $0b
    1
    $3, $c, $10
    1
    $2, $6, $03
    1
    $FF
end
    return
; End Init_laserrecoil

Init_electrosplosion
    sdata sfx_electrosplosion = SoundDataLoc
    $f, $6, $0f
    2
    $a, $6, $07
    2
    $f, $6, $07
    2
    $6, $6, $03
    2
    $f, $6, $07
    2
    $8, $6, $0f
    2
    $6, $6, $07
    2
    $a, $6, $0f
    2
    $f, $6, $0f
    2
    $6, $6, $0f
    2
    $5, $6, $07
    2
    $d, $6, $0f
    2
    $a, $6, $0f
    2
    $5, $c, $1b
    2
    $c, $6, $0f
    2
    $9, $6, $0f
    2
    $d, $6, $0f
    2
    $f, $6, $0f
    2
    $4, $6, $0f
    2
    $6, $6, $0f
    2
    $f, $6, $0f
    2
    $5, $6, $07
    2
    $6, $6, $0f
    2
    $1, $6, $0f
    2
    $1, $6, $07
    2
    $0, $6, $0f
    2
    $3, $6, $0f
    2
    $1, $6, $0f
    2
    $1, $6, $0f
    2
    $FF
end
    return
; End Init_electrosplosion

Init_hophip
    sdata sfx_hophip = SoundDataLoc
    $f, $4, $1e
    1
    $d, $4, $12
    1
    $f, $4, $12
    1
    $c, $c, $05
    1
    $a, $4, $10
    1
    $f, $c, $05
    1
    $f, $c, $05
    1
    $4, $c, $05
    1
    $7, $c, $05
    1
    $f, $c, $05
    1
    $f, $c, $05
    1
    $3, $c, $05
    1
    $c, $4, $10
    1
    $1, $4, $10
    1
    $9, $4, $10
    1
    $b, $4, $10
    1
    $5, $4, $10
    1
    $2, $4, $10
    1
    $7, $4, $10
    1
    $7, $4, $10
    1
    $3, $4, $10
    1
    $2, $4, $10
    1
    $1, $4, $10
    1
    $FF
end
    return
; End Init_hophip

Init_hophipquick
    sdata sfx_hophipquick = SoundDataLoc
    $f, $4, $1e
    1
    $f, $4, $12
    1
    $c, $c, $05
    1
    $f, $c, $05
    1
    $f, $c, $05
    1
    $7, $c, $05
    1
    $f, $c, $05
    1
    $3, $c, $05
    1
    $c, $4, $10
    1
    $9, $4, $10
    1
    $b, $4, $10
    1
    $2, $4, $10
    1
    $7, $4, $10
    1
    $3, $4, $10
    1
    $2, $4, $10
    1
    $FF
end
    return
; End Init_hophipquick

Init_bassbump2
    sdata sfx_bassbump2 = SoundDataLoc
    $f, $6, $1e
    1
    $f, $6, $1e
    1
    $f, $6, $1e
    1
    $f, $6, $1e
    1
    $f, $6, $1e
    1
    $5, $c, $17
    1
    $c, $6, $1e
    1
    $8, $6, $1e
    1
    $7, $6, $07
    1
    $6, $c, $1e
    1
    $3, $c, $12
    1
    $0, $6, $1e
    1
    $1, $6, $1e
    1
    $1, $6, $1e
    1
    $1, $6, $1e
    1
    $1, $6, $1e
    1
    $FF
end
    return
; End Init_bassbump2

Init_pickupprize
    sdata sfx_pickupprize = SoundDataLoc
    $c, $c, $0a
    1
    $f, $6, $1e
    1
    $e, $c, $0b
    1
    $d, $6, $1e
    1
    $f, $c, $0c
    1
    $e, $6, $1e
    1
    $c, $6, $1e
    1
    $5, $c, $0b
    1
    $5, $4, $16
    1
    $a, $4, $13
    1
    $3, $4, $09
    1
    $a, $4, $13
    1
    $6, $4, $13
    1
    $3, $4, $13
    1
    $2, $4, $09
    1
    $a, $4, $12
    1
    $6, $4, $12
    1
    $7, $4, $12
    1
    $2, $4, $12
    1
    $1, $4, $09
    1
    $3, $4, $13
    1
    $1, $4, $12
    1
    $FF
end
    return
; End Init_pickupprize

Init_distressed2
    sdata sfx_distressed2 = SoundDataLoc
    $f, $c, $12
    1
    $f, $c, $12
    1
    $f, $6, $1e
    1
    $f, $c, $03
    1
    $b, $6, $1e
    1
    $c, $6, $1e
    1
    $8, $c, $03
    1
    $e, $4, $0c
    1
    $a, $4, $0c
    1
    $a, $4, $0c
    1
    $8, $6, $1e
    1
    $8, $6, $1e
    1
    $9, $6, $1e
    1
    $5, $6, $1e
    1
    $9, $c, $04
    1
    $3, $6, $1e
    1
    $6, $6, $00
    1
    $3, $4, $0f
    1
    $3, $4, $10
    1
    $1, $4, $10
    1
    $1, $c, $05
    1
    $1, $4, $12
    1
    $1, $4, $12
    1
    $1, $4, $13
    1
    $FF
end
    return
; End Init_distressed2

Init_pewpew
    sdata sfx_pewpew = SoundDataLoc
    $f, $4, $1c
    1
    $f, $4, $1c
    1
    $b, $4, $09
    1
    $a, $c, $03
    1
    $e, $c, $04
    1
    $c, $4, $12
    1
    $f, $4, $19
    1
    $f, $4, $1c
    1
    $5, $4, $07
    1
    $5, $4, $09
    1
    $6, $4, $0d
    1
    $5, $4, $0c
    1
    $6, $4, $18
    1
    $5, $4, $1c
    1
    $3, $4, $1e
    1
    $3, $4, $07
    1
    $3, $4, $09
    1
    $2, $4, $0c
    1
    $2, $c, $04
    1
    $1, $c, $06
    1
    $FF
end
    return
; End Init_pewpew

Init_denied
    sdata sfx_denied = SoundDataLoc
    $d, $c, $0e
    1
    $a, $c, $10
    1
    $c, $c, $10
    1
    $5, $6, $1e
    1
    $9, $6, $1e
    1
    $7, $c, $12
    1
    $b, $c, $12
    1
    $f, $c, $12
    1
    $b, $c, $12
    1
    $7, $c, $12
    1
    $5, $6, $03
    1
    $4, $6, $03
    1
    $9, $6, $03
    1
    $3, $6, $1e
    1
    $7, $c, $12
    1
    $7, $c, $12
    1
    $5, $c, $12
    1
    $5, $6, $1e
    1
    $3, $c, $1f
    1
    $2, $c, $1f
    1
    $1, $c, $1f
    1
    $FF
end
    return
; End Init_denied

Init_teleported
    sdata sfx_teleported = SoundDataLoc
    $f, $4, $1c
    1
    $f, $6, $00
    1
    $f, $4, $0c
    1
    $f, $c, $03
    1
    $f, $4, $0a
    1
    $f, $4, $0a
    1
    $f, $c, $04
    1
    $f, $4, $10
    1
    $f, $4, $07
    1
    $f, $c, $06
    1
    $f, $c, $06
    1
    $f, $c, $05
    1
    $f, $4, $0f
    1
    $d, $c, $01
    1
    $f, $4, $15
    1
    $d, $4, $0d
    1
    $f, $c, $03
    1
    $d, $c, $03
    1
    $d, $c, $03
    1
    $f, $4, $0d
    1
    $e, $c, $04
    1
    $f, $4, $10
    1
    $f, $4, $10
    1
    $a, $c, $05
    1
    $f, $4, $15
    1
    $f, $4, $12
    1
    $f, $4, $12
    1
    $d, $c, $05
    1
    $b, $4, $16
    1
    $b, $4, $16
    1
    $b, $4, $0d
    1
    $a, $4, $12
    1
    $7, $4, $10
    1
    $9, $4, $0d
    1
    $a, $c, $03
    1
    $c, $4, $0d
    1
    $a, $4, $0d
    1
    $a, $c, $05
    1
    $9, $4, $0f
    1
    $9, $4, $12
    1
    $9, $6, $00
    1
    $c, $4, $10
    1
    $b, $4, $10
    1
    $6, $4, $15
    1
    $8, $4, $15
    1
    $5, $4, $1c
    1
    $5, $c, $03
    1
    $5, $c, $03
    1
    $4, $4, $0a
    1
    $4, $c, $03
    1
    $6, $4, $0d
    1
    $6, $4, $0d
    1
    $3, $c, $02
    1
    $4, $4, $07
    1
    $4, $c, $06
    1
    $5, $4, $12
    1
    $3, $4, $12
    1
    $2, $c, $01
    1
    $3, $c, $01
    1
    $4, $4, $0d
    1
    $5, $4, $0d
    1
    $1, $4, $07
    1
    $1, $c, $02
    1
    $1, $4, $0a
    1
    $2, $c, $03
    1
    $3, $c, $03
    1
    $2, $4, $0d
    1
    $0, $c, $02
    1
    $1, $c, $03
    1
    $1, $4, $0a
    1
    $1, $4, $07
    1
    $1, $c, $02
    1
    $1, $4, $07
    1
    $1, $c, $01
    1
    $1, $4, $0d
    1
    $1, $4, $0d
    1
    $FF
end
    return
; End Init_teleported

Init_alienklaxon
    sdata sfx_alienklaxon = SoundDataLoc
    $f, $6, $1e
    1
    $f, $6, $1e
    1
    $f, $6, $1e
    1
    $e, $6, $1e
    1
    $7, $6, $1e
    1
    $c, $4, $1c
    1
    $c, $6, $00
    1
    $f, $4, $1e
    1
    $f, $c, $0a
    1
    $f, $c, $0a
    1
    $d, $6, $1e
    1
    $9, $4, $16
    1
    $f, $6, $1e
    1
    $b, $6, $1e
    1
    $f, $6, $1e
    1
    $f, $c, $0b
    1
    $a, $6, $1e
    1
    $d, $c, $0c
    1
    $c, $4, $13
    1
    $f, $c, $0d
    1
    $8, $6, $1e
    1
    $4, $c, $02
    1
    $7, $4, $12
    1
    $3, $6, $07
    1
    $f, $c, $0e
    1
    $f, $c, $0e
    1
    $e, $c, $0e
    1
    $f, $c, $10
    1
    $f, $c, $10
    1
    $d, $c, $10
    1
    $7, $6, $1e
    1
    $6, $6, $1e
    1
    $8, $6, $1e
    1
    $7, $6, $1e
    1
    $f, $c, $12
    1
    $f, $6, $03
    1
    $7, $4, $1e
    1
    $f, $c, $12
    1
    $d, $c, $12
    1
    $7, $c, $0e
    1
    $1, $6, $1e
    1
    $2, $6, $1e
    1
    $4, $6, $1e
    1
    $4, $c, $0a
    1
    $9, $c, $0a
    1
    $8, $4, $1e
    1
    $8, $4, $1c
    1
    $6, $4, $1b
    1
    $5, $4, $19
    1
    $2, $6, $1e
    1
    $1, $4, $04
    1
    $0, $6, $1e
    1
    $1, $4, $04
    1
    $2, $c, $06
    1
    $4, $c, $06
    1
    $1, $c, $06
    1
    $4, $4, $12
    1
    $2, $6, $1e
    1
    $1, $c, $05
    1
    $0, $4, $04
    1
    $1, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $00
    1
    $1, $c, $04
    1
    $1, $c, $04
    1
    $1, $c, $04
    1
    $FF
end
    return
; End Init_alienklaxon

Init_crystalchimes
    sdata sfx_crystalchimes = SoundDataLoc
    $5, $4, $03
    1
    $f, $4, $03
    1
    $5, $4, $0c
    1
    $d, $4, $0c
    1
    $f, $4, $0c
    1
    $b, $4, $0c
    1
    $f, $4, $0c
    1
    $f, $4, $0c
    1
    $b, $4, $06
    1
    $c, $4, $0c
    1
    $b, $4, $0c
    1
    $a, $4, $06
    1
    $d, $c, $03
    1
    $b, $c, $03
    1
    $a, $c, $03
    1
    $8, $c, $03
    1
    $9, $4, $06
    1
    $f, $c, $03
    1
    $d, $c, $03
    1
    $8, $4, $06
    1
    $c, $c, $03
    1
    $7, $4, $0a
    1
    $a, $4, $0a
    1
    $d, $4, $0a
    1
    $4, $c, $03
    1
    $7, $4, $0a
    1
    $6, $4, $06
    1
    $8, $4, $0a
    1
    $c, $4, $0a
    1
    $7, $4, $06
    1
    $4, $4, $0a
    1
    $5, $4, $0a
    1
    $6, $4, $06
    1
    $2, $6, $1e
    1
    $5, $4, $06
    1
    $6, $4, $0a
    1
    $6, $4, $0a
    1
    $5, $4, $06
    1
    $7, $4, $0a
    1
    $4, $4, $06
    1
    $5, $4, $0a
    1
    $6, $4, $0a
    1
    $5, $4, $06
    1
    $1, $6, $1e
    1
    $4, $4, $06
    1
    $4, $4, $0a
    1
    $4, $4, $0a
    1
    $2, $4, $0a
    1
    $2, $4, $0a
    1
    $3, $4, $06
    1
    $3, $4, $0a
    1
    $5, $4, $0a
    1
    $2, $4, $06
    1
    $4, $4, $0a
    1
    $3, $4, $0a
    1
    $2, $4, $0a
    1
    $3, $4, $0a
    1
    $2, $4, $0a
    1
    $3, $4, $0a
    1
    $3, $4, $0a
    1
    $1, $4, $06
    1
    $3, $4, $0a
    1
    $1, $4, $0a
    1
    $2, $4, $0a
    1
    $1, $4, $0a
    1
    $1, $4, $06
    1
    $1, $4, $0a
    1
    $1, $4, $0a
    1
    $FF
end
    return
; End Init_crystalchimes

Init_oneup
    sdata sfx_oneup = SoundDataLoc
    $f, $4, $16
    1
    $f, $4, $16
    1
    $8, $4, $16
    1
    $4, $4, $13
    1
    $2, $4, $13
    1
    $1, $6, $12
    1
    $1, $6, $12
    1
    $f, $4, $12
    1
    $f, $4, $12
    1
    $8, $4, $12
    1
    $4, $4, $11
    1
    $2, $4, $10
    1
    $1, $4, $10
    1
    $1, $4, $10
    1
    $8, $4, $0a
    1
    $8, $4, $0a
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $8, $4, $0d
    1
    $8, $4, $0d
    1
    $8, $4, $0d
    1
    $6, $4, $0d
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $8, $4, $0c
    1
    $4, $4, $0c
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $6, $4, $09
    1
    $2, $4, $01
    1
    $4, $4, $09
    1
    $2, $4, $09
    1
    $4, $4, $09
    1
    $4, $4, $09
    1
    $2, $4, $01
    1
    $4, $4, $09
    1
    $0, $4, $01
    1
    $4, $4, $09
    1
    $2, $4, $01
    1
    $4, $4, $09
    1
    $2, $4, $09
    1
    $2, $4, $09
    1
    $4, $4, $09
    1
    $2, $4, $01
    1
    $1, $4, $01
    1
    $FF
end
    return
; End Init_oneup

PlaySound3
    if SoundDuration then SoundDuration = SoundDuration - 1
    if SoundDuration then return otherbank
    SoundVolume = sread(SoundDataLoc)
    if SoundVolume <> $FF then goto ____skip_end_sound3
    SoundPlayingBit1{1} = 0
    AUDC0 = 0 : AUDV0 = 0 : COLUPF = 0
    bally = 200 ; offscreen
    return otherbank
____skip_end_sound3
    SoundChannel = sread(SoundDataLoc)
    SoundFrequency = sread(SoundDataLoc)
    SoundDuration = sread(SoundDataLoc)
    AUDC0 = SoundChannel
    AUDV0 = SoundVolume
    AUDF0 = SoundFrequency
    gosub SoundVisual bank1
    return otherbank
; End PlaySound3

InitSound3
    if SoundPlayingBit1{1} then goto ____skip_sound_init_3
    CurrentSoundAdjusted = CurrentSound - 38
    on CurrentSoundAdjusted gosub Init_spring Init_buzzbomb Init_bassbump Init_hophop Init_distressed Init_ouch Init_laserrecoil Init_electrosplosion Init_hophip Init_hophipquick Init_bassbump2 Init_pickupprize Init_distressed2 Init_pewpew Init_denied Init_teleported Init_alienklaxon Init_crystalchimes Init_oneup
    SoundPlayingBit1{1} = 1
____skip_sound_init_3
    return otherbank
; End InitSound3


    bank 4 

Init_babywah
    sdata sfx_babywah = SoundDataLoc
    $b, $4, $0d
    1
    $f, $4, $0d
    1
    $5, $4, $0d
    1
    $c, $4, $19
    1
    $d, $4, $19
    1
    $f, $4, $0c
    1
    $f, $4, $19
    1
    $7, $4, $0c
    1
    $f, $4, $18
    1
    $f, $4, $18
    1
    $f, $c, $03
    1
    $f, $c, $07
    1
    $f, $c, $07
    1
    $f, $c, $07
    1
    $f, $c, $07
    1
    $7, $c, $03
    1
    $9, $c, $03
    1
    $6, $c, $03
    1
    $c, $4, $18
    1
    $c, $4, $18
    1
    $c, $4, $18
    1
    $4, $4, $1b
    1
    $6, $4, $0d
    1
    $4, $4, $1c
    1
    $3, $6, $0a
    1
    $2, $4, $12
    1
    $5, $4, $10
    1
    $6, $c, $05
    1
    $7, $4, $12
    1
    $4, $c, $06
    1
    $3, $c, $07
    1
    $2, $4, $19
    1
    $1, $4, $1c
    1
    $FF
end
    return
; End Init_babywah

Init_gotthecoin
    sdata sfx_gotthecoin = SoundDataLoc
    $f, $c, $04
    1
    $f, $c, $04
    1
    $e, $4, $0a
    1
    $f, $4, $0a
    1
    $f, $4, $0a
    1
    $d, $4, $0a
    1
    $9, $4, $0a
    1
    $9, $4, $0a
    1
    $8, $4, $0a
    1
    $7, $4, $0a
    1
    $6, $4, $0a
    1
    $5, $4, $0a
    1
    $3, $4, $0a
    1
    $7, $4, $0a
    1
    $9, $4, $0a
    1
    $3, $4, $0a
    1
    $1, $4, $0a
    1
    $1, $4, $0a
    1
    $1, $4, $0a
    1
    $0, $4, $0a
    1
    $1, $4, $0a
    1
    $1, $4, $0a
    1
    $1, $4, $0a
    1
    $FF
end
    return
; End Init_gotthecoin

Init_babyribbit
    sdata sfx_babyribbit = SoundDataLoc
    $f, $4, $1e
    1
    $f, $4, $1c
    1
    $e, $4, $1c
    1
    $e, $4, $0c
    1
    $e, $4, $1c
    1
    $6, $c, $0a
    1
    $0, $c, $0e
    1
    $0, $6, $1e
    1
    $6, $4, $18
    1
    $b, $4, $18
    1
    $b, $4, $16
    1
    $7, $4, $08
    1
    $4, $4, $04
    1
    $2, $4, $00
    1
    $1, $4, $00
    1
    $FF
end
    return
; End Init_babyribbit

Init_squeek
    sdata sfx_squeek = SoundDataLoc
    $f, $c, $06
    1
    $f, $4, $15
    1
    $f, $c, $06
    1
    $f, $c, $06
    1
    $f, $4, $0a
    1
    $f, $4, $0a
    1
    $f, $4, $0c
    1
    $f, $4, $0d
    1
    $f, $c, $03
    1
    $d, $c, $06
    1
    $7, $c, $03
    1
    $6, $4, $0d
    1
    $4, $c, $06
    1
    $8, $4, $15
    1
    $3, $c, $06
    1
    $5, $c, $06
    1
    $4, $4, $15
    1
    $4, $4, $15
    1
    $4, $c, $06
    1
    $3, $c, $06
    1
    $1, $c, $03
    1
    $2, $4, $15
    1
    $3, $c, $06
    1
    $3, $c, $06
    1
    $0, $4, $0c
    1
    $2, $4, $15
    1
    $1, $4, $15
    1
    $FF
end
    return
; End Init_squeek

Init_whoa
    sdata sfx_whoa = SoundDataLoc
    $6, $c, $10
    1
    $7, $c, $0e
    1
    $a, $c, $0c
    1
    $e, $c, $0b
    1
    $f, $4, $1e
    1
    $c, $c, $04
    1
    $e, $4, $1b
    1
    $9, $4, $0d
    1
    $b, $4, $0d
    1
    $8, $4, $19
    1
    $b, $4, $0c
    1
    $5, $4, $18
    1
    $e, $4, $0c
    1
    $9, $4, $0c
    1
    $a, $c, $07
    1
    $8, $c, $03
    1
    $d, $4, $16
    1
    $a, $4, $16
    1
    $b, $4, $0a
    1
    $f, $4, $16
    1
    $c, $4, $16
    1
    $c, $4, $16
    1
    $d, $c, $07
    1
    $f, $c, $07
    1
    $9, $c, $07
    1
    $a, $4, $0c
    1
    $e, $4, $19
    1
    $b, $4, $1b
    1
    $b, $4, $1c
    1
    $f, $4, $1e
    1
    $8, $c, $0a
    1
    $9, $c, $0c
    1
    $f, $c, $0d
    1
    $9, $c, $0d
    1
    $d, $c, $10
    1
    $f, $c, $12
    1
    $c, $6, $03
    1
    $4, $6, $03
    1
    $2, $6, $1e
    1
    $1, $c, $17
    1
    $2, $c, $1e
    1
    $1, $c, $1b
    1
    $FF
end
    return
; End Init_whoa

Init_gotthering
    sdata sfx_gotthering = SoundDataLoc
    $f, $4, $09
    1
    $a, $4, $09
    1
    $8, $4, $09
    1
    $4, $4, $09
    1
    $a, $4, $0a
    1
    $8, $4, $0a
    1
    $4, $4, $0a
    1
    $2, $4, $0a
    1
    $1, $4, $0a
    1
    $1, $4, $0a
    1
    $a, $4, $06
    1
    $f, $4, $06
    1
    $f, $4, $06
    1
    $f, $4, $06
    1
    $f, $4, $06
    1
    $b, $4, $06
    1
    $f, $4, $06
    1
    $9, $4, $06
    1
    $4, $4, $06
    1
    $c, $4, $06
    1
    $f, $4, $06
    1
    $5, $4, $06
    1
    $f, $4, $06
    1
    $3, $4, $06
    1
    $a, $4, $06
    1
    $8, $4, $06
    1
    $1, $4, $06
    1
    $5, $4, $06
    1
    $a, $4, $06
    1
    $1, $4, $06
    1
    $a, $4, $06
    1
    $5, $4, $06
    1
    $4, $4, $06
    1
    $5, $4, $06
    1
    $1, $4, $06
    1
    $FF
end
    return
; End Init_gotthering

Init_yahoo
    sdata sfx_yahoo = SoundDataLoc
    $2, $c, $01
    1
    $8, $4, $18
    1
    $f, $c, $07
    1
    $f, $4, $16
    1
    $5, $c, $03
    1
    $6, $4, $0a
    1
    $8, $4, $15
    1
    $4, $4, $18
    1
    $4, $4, $18
    1
    $4, $4, $1c
    1
    $4, $4, $1c
    1
    $2, $4, $1c
    1
    $2, $c, $0b
    1
    $1, $4, $19
    1
    $0, $4, $19
    1
    $1, $4, $1c
    1
    $3, $4, $1b
    1
    $6, $4, $19
    1
    $4, $4, $18
    1
    $6, $4, $1e
    1
    $f, $4, $19
    1
    $f, $4, $18
    1
    $f, $4, $18
    1
    $b, $4, $18
    1
    $f, $4, $18
    1
    $f, $4, $18
    1
    $f, $4, $18
    1
    $5, $4, $18
    1
    $8, $4, $18
    1
    $f, $4, $19
    1
    $8, $4, $1b
    1
    $6, $4, $1b
    1
    $f, $4, $1c
    1
    $f, $4, $1c
    1
    $8, $4, $1e
    1
    $e, $4, $1e
    1
    $b, $4, $1e
    1
    $8, $c, $0a
    1
    $f, $c, $0a
    1
    $f, $c, $0b
    1
    $e, $c, $0b
    1
    $9, $c, $0b
    1
    $6, $c, $0c
    1
    $2, $c, $0c
    1
    $3, $c, $0d
    1
    $3, $c, $0d
    1
    $1, $c, $0d
    1
    $0, $c, $0e
    1
    $0, $c, $17
    1
    $FF
end
    return
; End Init_yahoo

Init_warcry
    sdata sfx_warcry = SoundDataLoc
    $4, $6, $0f
    1
    $3, $c, $0a
    1
    $f, $4, $1c
    1
    $f, $4, $1e
    1
    $f, $4, $1e
    1
    $f, $4, $1c
    1
    $f, $4, $1b
    1
    $b, $c, $02
    1
    $8, $4, $0c
    1
    $f, $4, $18
    1
    $f, $4, $0c
    1
    $f, $c, $02
    1
    $f, $4, $18
    1
    $f, $4, $18
    1
    $f, $4, $0c
    1
    $f, $4, $07
    1
    $c, $4, $0c
    1
    $f, $c, $02
    1
    $f, $4, $18
    1
    $f, $c, $02
    1
    $f, $4, $0c
    1
    $9, $4, $0c
    1
    $f, $4, $19
    1
    $f, $c, $02
    1
    $f, $4, $1b
    1
    $f, $4, $1b
    1
    $f, $c, $02
    1
    $f, $4, $1c
    1
    $b, $4, $0d
    1
    $f, $4, $09
    1
    $8, $c, $04
    1
    $e, $4, $1e
    1
    $f, $4, $1e
    1
    $b, $4, $1e
    1
    $a, $4, $1e
    1
    $8, $4, $1e
    1
    $7, $4, $1e
    1
    $6, $4, $1e
    1
    $4, $4, $1f
    1
    $3, $4, $1f
    1
    $2, $4, $1f
    1
    $1, $4, $1f
    1
    $FF
end
    return
; End Init_warcry

Init_downthepipe
    sdata sfx_downthepipe = SoundDataLoc
    $f, $6, $1e
    1
    $f, $6, $1e
    1
    $8, $4, $18
    1
    $d, $c, $0c
    1
    $b, $c, $12
    1
    $6, $6, $0a
    1
    $a, $4, $18
    1
    $b, $c, $0c
    1
    $f, $6, $03
    1
    $e, $c, $1e
    1
    $f, $6, $1e
    1
    $f, $6, $0f
    1
    $2, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $07
    1
    $f, $6, $1e
    1
    $f, $6, $1e
    1
    $8, $4, $18
    1
    $d, $c, $0c
    1
    $b, $c, $12
    1
    $6, $6, $0a
    1
    $a, $4, $18
    1
    $b, $c, $0c
    1
    $f, $6, $03
    1
    $e, $c, $1e
    1
    $f, $6, $1e
    1
    $f, $6, $0f
    1
    $2, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $07
    1
    $f, $6, $1e
    1
    $f, $6, $1e
    1
    $8, $4, $18
    1
    $d, $c, $0c
    1
    $b, $c, $12
    1
    $6, $6, $0a
    1
    $a, $4, $18
    1
    $b, $c, $0c
    1
    $f, $6, $03
    1
    $e, $c, $1e
    1
    $f, $6, $1e
    1
    $f, $6, $0f
    1
    $2, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $07
    1
    $FF
end
    return
; End Init_downthepipe

Init_powerup
    sdata sfx_powerup = SoundDataLoc
    $f, $6, $1e
    1
    $f, $4, $1c
    1
    $f, $c, $0c
    1
    $f, $c, $0c
    1
    $f, $c, $0c
    1
    $f, $4, $1c
    1
    $a, $4, $1b
    1
    $9, $4, $16
    1
    $7, $4, $12
    1
    $e, $4, $12
    1
    $8, $4, $12
    1
    $3, $4, $0d
    1
    $8, $4, $12
    1
    $f, $4, $12
    1
    $f, $c, $0b
    1
    $f, $c, $0b
    1
    $c, $c, $0b
    1
    $6, $4, $1c
    1
    $c, $4, $1c
    1
    $f, $c, $07
    1
    $9, $c, $07
    1
    $a, $c, $05
    1
    $7, $4, $18
    1
    $f, $c, $07
    1
    $a, $c, $07
    1
    $c, $c, $05
    1
    $5, $c, $05
    1
    $3, $6, $1e
    1
    $4, $c, $03
    1
    $4, $c, $03
    1
    $4, $c, $03
    1
    $8, $c, $02
    1
    $4, $c, $03
    1
    $2, $6, $1e
    1
    $e, $c, $0a
    1
    $f, $c, $0a
    1
    $d, $4, $1e
    1
    $8, $4, $19
    1
    $b, $4, $15
    1
    $f, $4, $15
    1
    $8, $4, $15
    1
    $7, $4, $0f
    1
    $7, $4, $15
    1
    $c, $4, $15
    1
    $7, $c, $06
    1
    $2, $4, $0f
    1
    $4, $6, $00
    1
    $0, $c, $01
    1
    $4, $4, $0a
    1
    $8, $4, $0a
    1
    $3, $4, $0a
    1
    $3, $4, $07
    1
    $3, $4, $0a
    1
    $FF
end
    return
; End Init_powerup

Init_falling
    sdata sfx_falling = SoundDataLoc
    $0, $4, $0f
    1
    $3, $c, $03
    1
    $4, $4, $0c
    1
    $b, $4, $0c
    1
    $b, $4, $0c
    1
    $a, $4, $0d
    1
    $f, $4, $0d
    1
    $f, $c, $04
    1
    $f, $c, $04
    1
    $a, $c, $04
    1
    $f, $6, $00
    1
    $b, $4, $0f
    1
    $8, $4, $10
    1
    $c, $6, $00
    1
    $f, $c, $04
    1
    $d, $c, $04
    1
    $8, $4, $0d
    1
    $c, $c, $04
    1
    $b, $c, $05
    1
    $7, $c, $05
    1
    $6, $c, $06
    1
    $c, $4, $12
    1
    $f, $4, $12
    1
    $f, $4, $12
    1
    $f, $4, $10
    1
    $f, $4, $10
    1
    $9, $4, $10
    1
    $7, $4, $13
    1
    $7, $4, $13
    1
    $b, $4, $15
    1
    $f, $c, $06
    1
    $f, $4, $13
    1
    $f, $4, $13
    1
    $8, $4, $12
    1
    $c, $c, $05
    1
    $7, $c, $05
    1
    $6, $4, $16
    1
    $5, $4, $16
    1
    $2, $c, $07
    1
    $5, $c, $07
    1
    $8, $4, $15
    1
    $f, $4, $15
    1
    $b, $4, $15
    1
    $7, $4, $13
    1
    $6, $4, $16
    1
    $4, $4, $16
    1
    $6, $4, $18
    1
    $5, $4, $19
    1
    $2, $4, $1b
    1
    $1, $4, $18
    1
    $2, $4, $16
    1
    $6, $4, $16
    1
    $1, $c, $06
    1
    $5, $4, $16
    1
    $1, $4, $16
    1
    $1, $4, $1c
    1
    $FF
end
    return
; End Init_falling

Init_eek
    sdata sfx_eek = SoundDataLoc
    $4, $6, $1e
    1
    $3, $c, $10
    1
    $b, $4, $1e
    1
    $f, $4, $1c
    1
    $f, $4, $0d
    1
    $f, $c, $03
    1
    $f, $c, $03
    1
    $f, $c, $03
    1
    $f, $4, $0a
    1
    $f, $4, $0a
    1
    $f, $4, $0a
    1
    $f, $4, $0a
    1
    $f, $4, $0a
    1
    $f, $4, $0a
    1
    $8, $4, $0a
    1
    $f, $4, $0a
    1
    $7, $4, $0a
    1
    $f, $4, $0a
    1
    $c, $4, $0a
    1
    $f, $c, $03
    1
    $f, $c, $03
    1
    $f, $4, $0c
    1
    $6, $c, $04
    1
    $2, $4, $0c
    1
    $1, $c, $06
    1
    $1, $c, $06
    1
    $FF
end
    return
; End Init_eek

Init_uhoh
    sdata sfx_uhoh = SoundDataLoc
    $1, $6, $07
    1
    $3, $c, $1e
    1
    $4, $c, $1e
    1
    $4, $c, $17
    1
    $6, $6, $0a
    1
    $a, $c, $0a
    1
    $f, $6, $07
    1
    $f, $4, $1e
    1
    $f, $4, $19
    1
    $f, $4, $19
    1
    $7, $4, $1b
    1
    $7, $4, $18
    1
    $4, $4, $18
    1
    $2, $c, $07
    1
    $0, $4, $16
    1
    $0, $4, $16
    1
    $0, $4, $16
    1
    $0, $6, $0f
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $6, $1e
    1
    $0, $4, $19
    1
    $1, $4, $1e
    1
    $a, $4, $1e
    1
    $f, $4, $1c
    1
    $f, $4, $1c
    1
    $f, $4, $1e
    1
    $f, $c, $1b
    1
    $f, $c, $0d
    1
    $e, $c, $0d
    1
    $f, $c, $0e
    1
    $f, $c, $0e
    1
    $f, $c, $0e
    1
    $f, $c, $0e
    1
    $f, $c, $0e
    1
    $d, $c, $0e
    1
    $a, $c, $1b
    1
    $a, $c, $04
    1
    $b, $c, $1b
    1
    $a, $c, $0e
    1
    $a, $c, $0e
    1
    $a, $c, $1b
    1
    $a, $c, $0d
    1
    $6, $c, $0d
    1
    $4, $c, $0e
    1
    $4, $c, $0e
    1
    $2, $c, $0e
    1
    $FF
end
    return
; End Init_uhoh

Init_anotherup
    sdata sfx_anotherup = SoundDataLoc
    $f, $c, $06
    1
    $8, $c, $06
    1
    $f, $c, $06
    1
    $f, $c, $06
    1
    $a, $c, $06
    1
    $a, $4, $15
    1
    $9, $c, $06
    1
    $f, $4, $10
    1
    $7, $c, $02
    1
    $f, $4, $10
    1
    $d, $4, $10
    1
    $9, $4, $10
    1
    $b, $4, $10
    1
    $d, $4, $0d
    1
    $6, $4, $06
    1
    $c, $4, $0d
    1
    $a, $4, $0d
    1
    $6, $4, $0d
    1
    $c, $4, $0d
    1
    $c, $c, $06
    1
    $f, $c, $06
    1
    $f, $c, $06
    1
    $a, $c, $06
    1
    $6, $c, $06
    1
    $f, $c, $06
    1
    $d, $4, $10
    1
    $d, $4, $10
    1
    $a, $4, $10
    1
    $a, $4, $10
    1
    $6, $4, $10
    1
    $4, $c, $04
    1
    $8, $4, $0d
    1
    $8, $4, $0d
    1
    $3, $4, $06
    1
    $9, $4, $0d
    1
    $5, $4, $0d
    1
    $4, $c, $04
    1
    $5, $c, $06
    1
    $5, $c, $06
    1
    $9, $c, $06
    1
    $b, $c, $06
    1
    $9, $c, $06
    1
    $4, $c, $06
    1
    $4, $4, $10
    1
    $3, $4, $10
    1
    $2, $4, $10
    1
    $4, $4, $10
    1
    $3, $4, $10
    1
    $2, $4, $10
    1
    $FF
end
    return
; End Init_anotherup

Init_bubbleup
    sdata sfx_bubbleup = SoundDataLoc
    $f, $4, $1e
    1
    $f, $4, $1e
    1
    $e, $c, $12
    1
    $6, $4, $19
    1
    $f, $c, $10
    1
    $d, $c, $10
    1
    $f, $4, $1c
    1
    $e, $4, $1c
    1
    $f, $c, $10
    1
    $f, $c, $10
    1
    $f, $c, $10
    1
    $a, $4, $1b
    1
    $e, $4, $1b
    1
    $b, $4, $1b
    1
    $f, $c, $0e
    1
    $e, $c, $0e
    1
    $7, $c, $10
    1
    $c, $4, $19
    1
    $8, $4, $19
    1
    $7, $c, $0d
    1
    $7, $c, $0e
    1
    $d, $c, $0d
    1
    $8, $c, $0d
    1
    $6, $4, $18
    1
    $4, $c, $07
    1
    $7, $c, $0d
    1
    $b, $c, $0d
    1
    $1, $4, $13
    1
    $4, $4, $16
    1
    $6, $4, $16
    1
    $3, $4, $16
    1
    $4, $c, $0c
    1
    $6, $c, $0c
    1
    $4, $c, $0c
    1
    $3, $4, $15
    1
    $3, $4, $15
    1
    $1, $c, $06
    1
    $2, $c, $0b
    1
    $4, $c, $0b
    1
    $2, $c, $0b
    1
    $FF
end
    return
; End Init_bubbleup

Init_jump1
    sdata sfx_jump1 = SoundDataLoc
    $f, $6, $03
    1
    $f, $c, $12
    1
    $f, $c, $12
    1
    $f, $c, $10
    1
    $f, $c, $10
    1
    $5, $c, $10
    1
    $9, $c, $0d
    1
    $5, $c, $0e
    1
    $f, $c, $0c
    1
    $c, $c, $0c
    1
    $c, $c, $0b
    1
    $3, $c, $0b
    1
    $5, $4, $1e
    1
    $4, $4, $1c
    1
    $3, $4, $1c
    1
    $2, $4, $1c
    1
    $2, $4, $19
    1
    $2, $4, $18
    1
    $1, $c, $07
    1
    $FF
end
    return
; End Init_jump1

Init_plainlaser
    sdata sfx_plainlaser = SoundDataLoc
    $6, $4, $10
    1
    $8, $4, $13
    1
    $8, $4, $16
    1
    $7, $4, $16
    1
    $9, $4, $1c
    1
    $f, $c, $0b
    1
    $f, $c, $0d
    1
    $f, $c, $0e
    1
    $f, $c, $0e
    1
    $f, $c, $12
    1
    $d, $6, $03
    1
    $a, $c, $1e
    1
    $c, $c, $1e
    1
    $4, $6, $0a
    1
    $FF
end
    return
; End Init_plainlaser

Init_aliencoo
    sdata sfx_aliencoo = SoundDataLoc
    $f, $4, $1e
    1
    $f, $4, $1c
    1
    $f, $4, $1e
    1
    $e, $4, $1c
    1
    $f, $4, $1e
    1
    $5, $4, $1e
    1
    $f, $4, $1c
    1
    $3, $4, $1e
    1
    $f, $4, $1c
    1
    $4, $4, $1c
    1
    $f, $4, $1e
    1
    $2, $4, $1c
    1
    $e, $4, $1e
    1
    $3, $4, $1e
    1
    $5, $4, $1e
    1
    $1, $4, $1e
    1
    $FF
end
    return
; End Init_aliencoo

Init_simplebuzz
    sdata sfx_simplebuzz = SoundDataLoc
    $0, $6, $1e
    1
    $1, $6, $0a
    1
    $2, $6, $1e
    1
    $4, $6, $1e
    1
    $5, $6, $1e
    1
    $f, $6, $0f
    1
    $f, $6, $0f
    1
    $f, $6, $0f
    1
    $d, $6, $0f
    1
    $f, $6, $0f
    1
    $f, $6, $0f
    1
    $f, $6, $0f
    1
    $f, $6, $0f
    1
    $8, $6, $07
    1
    $6, $6, $07
    1
    $6, $6, $0f
    1
    $4, $6, $0f
    1
    $2, $6, $0f
    1
    $FF
end
    return
; End Init_simplebuzz

PlaySound4
    if SoundDuration then SoundDuration = SoundDuration - 1
    if SoundDuration then return otherbank
    SoundVolume = sread(SoundDataLoc)
    if SoundVolume <> $FF then goto ____skip_end_sound4
    SoundPlayingBit1{1} = 0
    AUDC0 = 0 : AUDV0 = 0 : COLUPF = 0
    bally = 200 ; offscreen
    return otherbank
____skip_end_sound4
    SoundChannel = sread(SoundDataLoc)
    SoundFrequency = sread(SoundDataLoc)
    SoundDuration = sread(SoundDataLoc)
    AUDC0 = SoundChannel
    AUDV0 = SoundVolume
    AUDF0 = SoundFrequency
    gosub SoundVisual bank1
    return otherbank
; End PlaySound4

InitSound4
    if SoundPlayingBit1{1} then goto ____skip_sound_init_4
    CurrentSoundAdjusted = CurrentSound - 57
    on CurrentSoundAdjusted gosub Init_babywah Init_gotthecoin Init_babyribbit Init_squeek Init_whoa Init_gotthering Init_yahoo Init_warcry Init_downthepipe Init_powerup Init_falling Init_eek Init_uhoh Init_anotherup Init_bubbleup Init_jump1 Init_plainlaser Init_aliencoo Init_simplebuzz
    SoundPlayingBit1{1} = 1
____skip_sound_init_4
    return otherbank
; End InitSound4


    bank 5 

Init_jump2
    sdata sfx_jump2 = SoundDataLoc
    $c, $c, $10
    1
    $f, $c, $10
    1
    $f, $c, $0f
    1
    $f, $c, $0f
    1
    $7, $6, $00
    1
    $f, $c, $0e
    1
    $d, $c, $0e
    1
    $7, $c, $0e
    1
    $f, $c, $0f
    1
    $8, $c, $0f
    1
    $8, $c, $11
    1
    $6, $c, $12
    1
    $8, $6, $03
    1
    $7, $c, $15
    1
    $4, $c, $15
    1
    $6, $c, $17
    1
    $6, $6, $04
    1
    $1, $6, $04
    1
    $1, $c, $17
    1
    $FF
end
    return
; End Init_jump2

Init_jump3
    sdata sfx_jump3 = SoundDataLoc
    $7, $c, $17
    2
    $f, $c, $1b
    2
    $9, $c, $1b
    2
    $d, $c, $17
    2
    $f, $c, $17
    2
    $b, $c, $0d
    2
    $d, $c, $0c
    2
    $a, $c, $0a
    2
    $9, $4, $1c
    2
    $f, $4, $1b
    2
    $7, $4, $1b
    2
    $4, $4, $18
    2
    $c, $4, $1b
    2
    $4, $c, $0a
    2
    $3, $c, $0b
    2
    $3, $c, $0c
    2
    $1, $c, $0d
    2
    $FF
end
    return
; End Init_jump3

Init_dunno
    sdata sfx_dunno = SoundDataLoc
    $4, $c, $0b
    1
    $b, $c, $0a
    1
    $f, $c, $0a
    1
    $f, $c, $0a
    1
    $f, $c, $0a
    1
    $d, $c, $0a
    1
    $f, $c, $0a
    1
    $c, $c, $0b
    1
    $f, $c, $0b
    1
    $d, $c, $0b
    1
    $7, $c, $0b
    1
    $b, $c, $0b
    1
    $8, $c, $0b
    1
    $3, $c, $08
    1
    $6, $c, $0b
    1
    $8, $c, $0b
    1
    $9, $c, $0b
    1
    $6, $c, $0b
    1
    $5, $c, $0c
    1
    $4, $c, $0b
    1
    $3, $c, $0b
    1
    $2, $c, $0b
    1
    $FF
end
    return
; End Init_dunno

Init_snore
    sdata sfx_snore = SoundDataLoc
    $1, $c, $0c
    1
    $3, $c, $17
    1
    $6, $6, $03
    1
    $4, $6, $0a
    1
    $4, $6, $0a
    1
    $3, $6, $07
    1
    $c, $6, $1e
    1
    $f, $6, $0f
    1
    $f, $6, $0f
    1
    $f, $6, $0a
    1
    $f, $6, $0f
    1
    $f, $4, $0d
    1
    $f, $6, $0f
    1
    $f, $6, $0f
    1
    $e, $6, $0a
    1
    $c, $6, $00
    1
    $d, $4, $0d
    1
    $4, $6, $0a
    1
    $3, $6, $0f
    1
    $4, $6, $0a
    1
    $1, $6, $1e
    1
    $1, $6, $0a
    1
    $FF
end
    return
; End Init_snore

Init_uncovered
    sdata sfx_uncovered = SoundDataLoc
    $2, $c, $1e
    1
    $6, $c, $1b
    1
    $c, $c, $1b
    1
    $e, $c, $1b
    1
    $c, $c, $1b
    1
    $4, $c, $0c
    1
    $f, $c, $17
    1
    $5, $c, $17
    1
    $7, $c, $1b
    1
    $5, $c, $17
    1
    $f, $c, $17
    1
    $f, $c, $17
    1
    $f, $c, $17
    1
    $f, $6, $03
    1
    $f, $6, $03
    1
    $a, $6, $1e
    1
    $c, $c, $17
    1
    $f, $c, $10
    1
    $f, $c, $10
    1
    $7, $c, $10
    1
    $3, $c, $10
    1
    $3, $c, $17
    1
    $7, $c, $12
    1
    $4, $6, $03
    1
    $2, $6, $03
    1
    $1, $c, $0e
    1
    $2, $c, $12
    1
    $3, $c, $12
    1
    $1, $6, $03
    1
    $1, $6, $03
    1
    $1, $c, $10
    1
    $1, $c, $12
    1
    $1, $c, $10
    1
    $1, $c, $10
    1
    $FF
end
    return
; End Init_uncovered

Init_doorpound
    sdata sfx_doorpound = SoundDataLoc
    $f, $6, $0f
    1
    $f, $c, $1e
    1
    $f, $6, $0f
    1
    $f, $6, $1e
    1
    $f, $6, $0a
    1
    $b, $6, $07
    1
    $f, $6, $0f
    1
    $c, $6, $0f
    1
    $a, $6, $07
    1
    $9, $6, $07
    1
    $b, $6, $0f
    1
    $7, $6, $1e
    1
    $6, $6, $0a
    1
    $8, $6, $0a
    1
    $6, $6, $0f
    1
    $5, $6, $0a
    1
    $3, $6, $1e
    1
    $2, $6, $0f
    1
    $FF
end
    return
; End Init_doorpound

Init_distressed3
    sdata sfx_distressed3 = SoundDataLoc
    $c, $c, $05
    1
    $e, $4, $1b
    1
    $d, $4, $1b
    1
    $6, $4, $1b
    1
    $7, $4, $0d
    1
    $5, $4, $1b
    1
    $b, $4, $1b
    1
    $6, $4, $1b
    1
    $9, $4, $1c
    1
    $7, $4, $0d
    1
    $b, $4, $1c
    1
    $e, $4, $1c
    1
    $9, $4, $1c
    1
    $8, $6, $07
    1
    $7, $6, $07
    1
    $5, $4, $1c
    1
    $b, $4, $1e
    1
    $b, $4, $1e
    1
    $a, $4, $1e
    1
    $9, $4, $1e
    1
    $4, $6, $0a
    1
    $3, $4, $1e
    1
    $3, $c, $0a
    1
    $3, $6, $0a
    1
    $2, $c, $0a
    1
    $3, $c, $0a
    1
    $1, $c, $0b
    1
    $1, $c, $0a
    1
    $FF
end
    return
; End Init_distressed3

Init_eek2
    sdata sfx_eek2 = SoundDataLoc
    $1, $6, $1e
    1
    $a, $4, $0a
    1
    $f, $4, $0a
    1
    $f, $4, $09
    1
    $e, $4, $13
    1
    $f, $4, $09
    1
    $f, $4, $09
    1
    $f, $4, $09
    1
    $a, $4, $09
    1
    $f, $4, $09
    1
    $c, $4, $09
    1
    $f, $4, $09
    1
    $f, $4, $0a
    1
    $c, $4, $0a
    1
    $f, $c, $03
    1
    $a, $4, $0c
    1
    $5, $4, $0d
    1
    $2, $4, $09
    1
    $1, $c, $03
    1
    $FF
end
    return
; End Init_eek2

Init_rubberhammer
    sdata sfx_rubberhammer = SoundDataLoc
    $8, $6, $00
    1
    $f, $4, $1c
    1
    $f, $6, $1e
    1
    $f, $4, $1b
    1
    $f, $4, $1e
    1
    $f, $4, $1e
    1
    $f, $c, $0c
    1
    $f, $c, $0c
    1
    $b, $6, $1e
    1
    $8, $c, $0a
    1
    $5, $c, $0a
    1
    $6, $4, $1e
    1
    $5, $4, $1c
    1
    $3, $4, $1c
    1
    $1, $c, $0e
    1
    $1, $4, $1b
    1
    $FF
end
    return
; End Init_rubberhammer

Init_alienbuzz
    sdata sfx_alienbuzz = SoundDataLoc
    $4, $c, $0d
    1
    $8, $c, $0c
    1
    $b, $c, $0c
    1
    $5, $c, $12
    1
    $a, $c, $12
    1
    $f, $c, $0d
    1
    $f, $c, $0c
    1
    $f, $c, $0c
    1
    $f, $c, $0b
    1
    $e, $c, $0c
    1
    $f, $c, $0c
    1
    $f, $c, $0d
    1
    $f, $c, $0c
    1
    $f, $c, $0c
    1
    $f, $c, $0c
    1
    $f, $c, $0f
    1
    $f, $c, $0c
    1
    $f, $c, $0c
    1
    $d, $c, $0c
    1
    $9, $c, $0d
    1
    $f, $c, $0d
    1
    $6, $c, $0d
    1
    $f, $c, $0c
    1
    $5, $c, $0c
    1
    $1, $c, $0d
    1
    $1, $c, $0d
    1
    $1, $c, $0c
    1
    $0, $c, $0d
    1
    $1, $c, $0c
    1
    $FF
end
    return
; End Init_alienbuzz

Init_anotherjumpman
    sdata sfx_anotherjumpman = SoundDataLoc
    $f, $c, $0c
    1
    $f, $c, $0e
    1
    $f, $c, $0e
    1
    $f, $c, $0d
    1
    $f, $4, $1c
    1
    $f, $4, $1b
    1
    $c, $4, $1b
    1
    $f, $4, $18
    1
    $f, $4, $1c
    1
    $f, $c, $0a
    1
    $f, $c, $0b
    1
    $f, $c, $0b
    1
    $f, $4, $1e
    1
    $f, $4, $1b
    1
    $d, $4, $1b
    1
    $9, $4, $18
    1
    $e, $4, $1b
    1
    $f, $4, $1e
    1
    $f, $c, $0a
    1
    $7, $c, $0b
    1
    $f, $c, $0a
    1
    $e, $4, $1b
    1
    $d, $4, $19
    1
    $f, $4, $18
    1
    $f, $4, $18
    1
    $f, $4, $1e
    1
    $a, $4, $1e
    1
    $f, $c, $0b
    1
    $f, $c, $0b
    1
    $b, $4, $1c
    1
    $8, $4, $19
    1
    $9, $4, $18
    1
    $7, $4, $18
    1
    $4, $4, $1e
    1
    $3, $4, $1e
    1
    $1, $c, $0c
    1
    $1, $c, $0c
    1
    $FF
end
    return
; End Init_anotherjumpman

Init_anotherjumpdies
    sdata sfx_anotherjumpdies = SoundDataLoc
    $3, $4, $0f
    1
    $7, $4, $10
    1
    $5, $4, $10
    1
    $2, $4, $0f
    1
    $2, $4, $0a
    1
    $6, $4, $0c
    1
    $3, $4, $0c
    1
    $5, $4, $0d
    1
    $4, $4, $0d
    1
    $2, $6, $07
    1
    $4, $c, $04
    1
    $7, $c, $04
    1
    $3, $c, $04
    1
    $2, $4, $09
    1
    $1, $4, $09
    1
    $3, $4, $10
    1
    $7, $4, $0f
    1
    $4, $4, $0f
    1
    $2, $4, $0a
    1
    $2, $4, $0a
    1
    $6, $4, $10
    1
    $6, $4, $10
    1
    $2, $c, $05
    1
    $1, $c, $03
    1
    $1, $c, $03
    1
    $3, $4, $12
    1
    $4, $4, $12
    1
    $4, $4, $12
    1
    $4, $4, $0c
    1
    $5, $4, $0c
    1
    $7, $4, $13
    1
    $7, $4, $13
    1
    $1, $4, $13
    1
    $2, $4, $0c
    1
    $3, $4, $0d
    1
    $8, $4, $15
    1
    $6, $4, $15
    1
    $4, $4, $16
    1
    $2, $4, $0d
    1
    $6, $c, $04
    1
    $5, $c, $04
    1
    $5, $c, $07
    1
    $f, $c, $07
    1
    $9, $c, $07
    1
    $3, $6, $07
    1
    $2, $6, $00
    1
    $2, $c, $04
    1
    $3, $4, $18
    1
    $b, $4, $18
    1
    $a, $4, $18
    1
    $3, $4, $1b
    1
    $4, $4, $10
    1
    $5, $4, $10
    1
    $3, $4, $10
    1
    $8, $4, $19
    1
    $a, $4, $1b
    1
    $8, $4, $1b
    1
    $2, $c, $05
    1
    $7, $4, $12
    1
    $6, $4, $12
    1
    $7, $4, $1c
    1
    $d, $4, $1c
    1
    $9, $4, $1e
    1
    $5, $4, $13
    1
    $c, $4, $13
    1
    $6, $4, $13
    1
    $4, $c, $0b
    1
    $e, $4, $1e
    1
    $d, $4, $1e
    1
    $6, $c, $0a
    1
    $4, $4, $15
    1
    $c, $4, $15
    1
    $a, $4, $15
    1
    $2, $4, $15
    1
    $FF
end
    return
; End Init_anotherjumpdies

Init_longgongsilver
    sdata sfx_longgongsilver = SoundDataLoc
    $b, $c, $1b
    1
    $7, $c, $06
    1
    $f, $c, $1b
    1
    $d, $6, $0a
    1
    $b, $c, $1b
    1
    $f, $6, $0a
    1
    $c, $6, $0a
    1
    $a, $c, $12
    1
    $f, $c, $1b
    1
    $b, $c, $12
    1
    $f, $c, $1b
    1
    $f, $c, $1b
    1
    $c, $c, $12
    1
    $f, $c, $1b
    1
    $d, $6, $0a
    1
    $7, $c, $12
    1
    $f, $6, $0a
    1
    $f, $c, $1b
    1
    $7, $6, $0a
    1
    $f, $c, $1b
    1
    $6, $6, $0a
    1
    $f, $c, $1b
    1
    $f, $6, $0a
    1
    $7, $c, $06
    1
    $e, $6, $0a
    1
    $f, $c, $1b
    1
    $8, $c, $12
    1
    $f, $c, $1b
    1
    $c, $c, $1b
    1
    $f, $c, $1b
    1
    $e, $c, $1b
    1
    $8, $c, $12
    1
    $c, $6, $0a
    1
    $d, $c, $1b
    1
    $8, $c, $12
    1
    $f, $c, $1b
    1
    $f, $c, $1b
    1
    $a, $c, $1b
    1
    $f, $c, $1b
    1
    $a, $6, $0a
    1
    $8, $6, $0a
    1
    $f, $6, $0a
    1
    $9, $c, $1b
    1
    $c, $6, $0a
    1
    $f, $c, $1b
    1
    $5, $c, $06
    1
    $f, $c, $1b
    1
    $b, $6, $0a
    1
    $6, $c, $12
    1
    $c, $6, $0a
    1
    $8, $c, $1b
    1
    $a, $c, $12
    1
    $d, $c, $1b
    1
    $6, $c, $1b
    1
    $c, $c, $1b
    1
    $b, $c, $1b
    1
    $4, $c, $1b
    1
    $6, $6, $0a
    1
    $7, $6, $0a
    1
    $4, $6, $0a
    1
    $9, $c, $1b
    1
    $7, $c, $1b
    1
    $6, $c, $1b
    1
    $7, $c, $1b
    1
    $7, $c, $12
    1
    $6, $c, $1b
    1
    $7, $c, $12
    1
    $5, $c, $12
    1
    $5, $6, $0a
    1
    $6, $c, $1b
    1
    $2, $c, $0a
    1
    $8, $c, $1b
    1
    $3, $6, $0a
    1
    $4, $c, $1b
    1
    $6, $6, $0a
    1
    $2, $c, $12
    1
    $2, $c, $1b
    1
    $5, $c, $1b
    1
    $2, $c, $12
    1
    $5, $c, $1b
    1
    $4, $6, $0a
    1
    $2, $c, $1b
    1
    $4, $c, $1b
    1
    $1, $c, $1b
    1
    $3, $c, $12
    1
    $4, $6, $0a
    1
    $2, $c, $1b
    1
    $1, $c, $1b
    1
    $4, $c, $1b
    1
    $2, $6, $0a
    1
    $2, $c, $1b
    1
    $2, $6, $0a
    1
    $FF
end
    return
; End Init_longgongsilver

Init_strum
    sdata sfx_strum = SoundDataLoc
    $9, $c, $0c
    1
    $f, $c, $0c
    1
    $f, $c, $0c
    1
    $f, $c, $0c
    1
    $f, $c, $0c
    1
    $f, $4, $1e
    1
    $e, $4, $1e
    1
    $f, $c, $07
    1
    $f, $c, $07
    1
    $b, $c, $07
    1
    $b, $4, $1e
    1
    $c, $c, $07
    1
    $9, $c, $0c
    1
    $7, $c, $07
    1
    $6, $c, $07
    1
    $5, $c, $07
    1
    $4, $c, $07
    1
    $4, $c, $07
    1
    $3, $c, $07
    1
    $3, $c, $07
    1
    $2, $c, $07
    1
    $2, $c, $07
    1
    $1, $c, $07
    1
    $1, $c, $07
    1
    $FF
end
    return
; End Init_strum

Init_dropped
    sdata sfx_dropped = SoundDataLoc
    $f, $6, $0a
    1
    $f, $6, $0a
    1
    $6, $6, $0a
    1
    $2, $4, $0c
    1
    $1, $c, $1b
    1
    $f, $6, $07
    1
    $f, $6, $0a
    1
    $f, $6, $0a
    1
    $7, $6, $0a
    1
    $6, $4, $07
    1
    $4, $4, $07
    1
    $f, $6, $07
    1
    $d, $6, $07
    1
    $e, $4, $07
    1
    $6, $4, $07
    1
    $3, $4, $07
    1
    $9, $6, $0a
    1
    $f, $6, $0a
    1
    $f, $4, $07
    1
    $5, $4, $07
    1
    $5, $4, $07
    1
    $8, $c, $1b
    1
    $d, $4, $07
    1
    $7, $4, $07
    1
    $7, $4, $07
    1
    $3, $4, $07
    1
    $7, $4, $07
    1
    $5, $4, $07
    1
    $3, $4, $07
    1
    $1, $4, $07
    1
    $FF
end
    return
; End Init_dropped

Init_alienaggressor
    sdata sfx_alienaggressor = SoundDataLoc
    $1, $c, $1b
    1
    $2, $6, $0f
    1
    $3, $6, $0f
    1
    $2, $6, $1e
    1
    $1, $6, $1e
    1
    $2, $c, $1b
    1
    $6, $c, $17
    1
    $9, $c, $17
    1
    $d, $c, $17
    1
    $d, $6, $07
    1
    $6, $4, $16
    1
    $d, $c, $17
    1
    $f, $c, $17
    1
    $d, $4, $1c
    1
    $f, $4, $1c
    1
    $8, $c, $07
    1
    $f, $4, $18
    1
    $9, $4, $18
    1
    $a, $c, $03
    1
    $c, $c, $03
    1
    $f, $4, $0c
    1
    $f, $4, $0c
    1
    $8, $c, $06
    1
    $c, $4, $18
    1
    $9, $c, $0a
    1
    $5, $6, $07
    1
    $5, $6, $07
    1
    $3, $6, $08
    1
    $1, $6, $09
    1
    $0, $6, $00
    1
    $2, $6, $07
    1
    $1, $6, $08
    1
    $FF
end
    return
; End Init_alienaggressor

Init_electroswitch2
    sdata sfx_electroswitch2 = SoundDataLoc
    $b, $c, $05
    1
    $c, $c, $17
    1
    $b, $4, $0c
    1
    $b, $4, $07
    1
    $f, $4, $0c
    1
    $8, $4, $0c
    1
    $9, $4, $12
    1
    $f, $4, $12
    1
    $8, $c, $1b
    1
    $9, $6, $0a
    1
    $2, $6, $0a
    1
    $1, $c, $1b
    1
    $FF
end
    return
; End Init_electroswitch2

Init_gooditem
    sdata sfx_gooditem = SoundDataLoc
    $f, $c, $07
    1
    $4, $c, $06
    1
    $f, $c, $07
    1
    $f, $c, $07
    1
    $f, $c, $07
    1
    $8, $c, $06
    1
    $9, $c, $06
    1
    $c, $c, $06
    1
    $d, $c, $07
    1
    $e, $c, $06
    1
    $c, $c, $06
    1
    $d, $4, $12
    1
    $d, $4, $12
    1
    $4, $4, $1b
    1
    $6, $c, $06
    1
    $c, $4, $12
    1
    $b, $4, $12
    1
    $4, $4, $10
    1
    $4, $c, $04
    1
    $c, $4, $12
    1
    $c, $4, $12
    1
    $a, $4, $10
    1
    $3, $4, $12
    1
    $9, $c, $06
    1
    $e, $4, $12
    1
    $d, $4, $10
    1
    $7, $c, $04
    1
    $6, $c, $04
    1
    $7, $4, $0d
    1
    $a, $4, $10
    1
    $a, $4, $10
    1
    $5, $4, $10
    1
    $4, $c, $04
    1
    $6, $4, $10
    1
    $b, $4, $10
    1
    $5, $4, $10
    1
    $8, $4, $0d
    1
    $7, $c, $03
    1
    $9, $c, $04
    1
    $5, $c, $04
    1
    $a, $4, $0c
    1
    $7, $4, $0a
    1
    $4, $4, $09
    1
    $8, $4, $0d
    1
    $5, $4, $0d
    1
    $7, $c, $03
    1
    $FF
end
    return
; End Init_gooditem

Init_babyribbithop
    sdata sfx_babyribbithop = SoundDataLoc
    $4, $c, $0c
    1
    $4, $c, $17
    1
    $6, $c, $04
    1
    $d, $4, $0d
    1
    $c, $4, $0d
    1
    $f, $4, $0a
    1
    $9, $4, $09
    1
    $f, $6, $1e
    1
    $f, $6, $1e
    1
    $d, $4, $09
    1
    $9, $c, $10
    1
    $7, $4, $09
    1
    $6, $6, $0a
    1
    $FF
end
    return
; End Init_babyribbithop

PlaySound5
    if SoundDuration then SoundDuration = SoundDuration - 1
    if SoundDuration then return otherbank
    SoundVolume = sread(SoundDataLoc)
    if SoundVolume <> $FF then goto ____skip_end_sound5
    SoundPlayingBit1{1} = 0
    AUDC0 = 0 : AUDV0 = 0 : COLUPF = 0
    bally = 200 ; offscreen
    return otherbank
____skip_end_sound5
    SoundChannel = sread(SoundDataLoc)
    SoundFrequency = sread(SoundDataLoc)
    SoundDuration = sread(SoundDataLoc)
    AUDC0 = SoundChannel
    AUDV0 = SoundVolume
    AUDF0 = SoundFrequency
    gosub SoundVisual bank1
    return otherbank
; End PlaySound5

InitSound5
    if SoundPlayingBit1{1} then goto ____skip_sound_init_5
    CurrentSoundAdjusted = CurrentSound - 76
    on CurrentSoundAdjusted gosub Init_jump2 Init_jump3 Init_dunno Init_snore Init_uncovered Init_doorpound Init_distressed3 Init_eek2 Init_rubberhammer Init_alienbuzz Init_anotherjumpman Init_anotherjumpdies Init_longgongsilver Init_strum Init_dropped Init_alienaggressor Init_electroswitch2 Init_gooditem Init_babyribbithop
    SoundPlayingBit1{1} = 1
____skip_sound_init_5
    return otherbank
; End InitSound5


    bank 6 

Init_distressed4
    sdata sfx_distressed4 = SoundDataLoc
    $4, $4, $1b
    1
    $a, $4, $1c
    1
    $f, $4, $1c
    1
    $f, $4, $1b
    1
    $f, $4, $1c
    1
    $f, $4, $1c
    1
    $f, $4, $19
    1
    $f, $4, $1c
    1
    $f, $4, $1c
    1
    $f, $4, $1c
    1
    $9, $4, $1c
    1
    $f, $4, $1c
    1
    $f, $4, $1c
    1
    $f, $4, $1c
    1
    $9, $4, $1c
    1
    $f, $4, $1c
    1
    $f, $4, $1c
    1
    $f, $4, $1c
    1
    $9, $4, $1c
    1
    $f, $4, $1c
    1
    $f, $4, $1c
    1
    $8, $4, $1d
    1
    $2, $4, $1d
    1
    $1, $4, $1d
    1
    $0, $4, $1d
    1
    $2, $4, $1d
    1
    $1, $4, $1d
    1
    $FF
end
    return
; End Init_distressed4

Init_hahaha
    sdata sfx_hahaha = SoundDataLoc
    $1, $7, $0a
    1
    $1, $1, $07
    1
    $2, $7, $09
    1
    $1, $f, $1f
    1
    $1, $7, $07
    1
    $1, $f, $12
    1
    $1, $7, $08
    1
    $1, $4, $0b
    1
    $1, $6, $08
    1
    $1, $4, $12
    1
    $1, $4, $0b
    1
    $1, $6, $16
    1
    $1, $6, $07
    1
    $c, $4, $12
    1
    $d, $4, $11
    1
    $d, $4, $10
    1
    $d, $4, $13
    1
    $5, $4, $15
    1
    $3, $7, $07
    1
    $1, $4, $13
    1
    $6, $4, $1c
    1
    $b, $4, $17
    1
    $8, $4, $15
    1
    $8, $1, $17
    1
    $9, $6, $01
    1
    $5, $7, $0a
    1
    $4, $c, $0d
    1
    $1, $7, $16
    1
    $7, $1, $04
    1
    $b, $4, $1d
    1
    $9, $6, $00
    1
    $d, $f, $1b
    1
    $d, $1, $04
    1
    $6, $1, $19
    1
    $1, $f, $0a
    1
    $3, $6, $02
    1
    $7, $c, $0c
    1
    $c, $c, $0a
    1
    $f, $4, $1f
    1
    $7, $4, $11
    1
    $a, $c, $0b
    1
    $b, $1, $09
    1
    $7, $c, $0a
    1
    $1, $1, $12
    1
    $0, $7, $0a
    1
    $8, $c, $0c
    1
    $d, $4, $11
    1
    $c, $c, $0a
    1
    $a, $4, $11
    1
    $9, $c, $0b
    1
    $9, $4, $12
    1
    $9, $1, $04
    1
    $7, $f, $1c
    1
    $8, $4, $13
    1
    $7, $4, $14
    1
    $7, $4, $14
    1
    $6, $c, $0c
    1
    $6, $4, $14
    1
    $5, $c, $0c
    1
    $6, $1, $09
    1
    $8, $7, $02
    1
    $4, $7, $09
    1
    $2, $6, $02
    1
    $FF
end
    return
; End Init_hahaha

Init_yeah
    sdata sfx_yeah = SoundDataLoc
    $3, $c, $15
    1
    $3, $c, $12
    1
    $3, $c, $14
    1
    $4, $7, $1a
    1
    $a, $6, $02
    1
    $e, $4, $1c
    1
    $e, $4, $18
    1
    $f, $4, $17
    1
    $f, $6, $13
    1
    $e, $6, $0d
    1
    $e, $7, $0e
    1
    $d, $e, $0f
    1
    $b, $6, $12
    1
    $9, $7, $11
    1
    $7, $7, $0e
    1
    $2, $7, $09
    1
    $3, $6, $02
    1
    $3, $c, $16
    1
    $3, $c, $17
    1
    $2, $c, $15
    1
    $2, $c, $17
    1
    $1, $c, $18
    1
    $1, $c, $18
    1
    $FF
end
    return
; End Init_yeah

Init_arfarf
    sdata sfx_arfarf = SoundDataLoc
    $1, $c, $0d
    1
    $7, $c, $0c
    1
    $d, $4, $12
    1
    $c, $7, $08
    1
    $c, $4, $1b
    1
    $d, $4, $1b
    1
    $f, $4, $19
    1
    $d, $4, $12
    1
    $e, $4, $12
    1
    $e, $4, $12
    1
    $d, $1, $07
    1
    $d, $c, $0a
    1
    $2, $4, $1f
    1
    $0, $1, $09
    1
    $3, $c, $0b
    1
    $9, $c, $0b
    1
    $d, $f, $12
    1
    $d, $4, $0f
    1
    $c, $4, $1c
    1
    $d, $4, $1b
    1
    $e, $4, $1a
    1
    $d, $4, $19
    1
    $e, $4, $19
    1
    $d, $1, $06
    1
    $d, $6, $01
    1
    $d, $c, $0a
    1
    $FF
end
    return
; End Init_arfarf

Init_activate
    sdata sfx_activate = SoundDataLoc
    $1, $7, $0b
    1
    $6, $7, $1f
    1
    $7, $c, $13
    1
    $d, $4, $15
    1
    $e, $4, $1c
    1
    $d, $4, $16
    1
    $d, $c, $0d
    1
    $b, $c, $12
    1
    $d, $4, $14
    1
    $f, $4, $1f
    1
    $d, $4, $1b
    1
    $d, $4, $1b
    1
    $6, $4, $1b
    1
    $5, $c, $15
    1
    $7, $7, $1e
    1
    $d, $7, $0e
    1
    $e, $6, $01
    1
    $d, $4, $13
    1
    $d, $7, $1e
    1
    $b, $c, $10
    1
    $d, $4, $14
    1
    $e, $c, $0b
    1
    $d, $4, $1b
    1
    $c, $4, $1a
    1
    $5, $f, $12
    1
    $FF
end
    return
; End Init_activate

Init_hahaha2
    sdata sfx_hahaha2 = SoundDataLoc
    $0, $f, $14
    2
    $2, $7, $06
    2
    $e, $4, $0a
    2
    $f, $4, $0b
    2
    $f, $6, $00
    2
    $7, $4, $0b
    2
    $4, $4, $10
    2
    $2, $4, $0d
    2
    $2, $4, $10
    2
    $f, $4, $10
    2
    $f, $4, $0f
    2
    $7, $4, $0d
    2
    $2, $6, $00
    2
    $4, $4, $10
    2
    $2, $6, $00
    2
    $f, $6, $00
    2
    $f, $6, $00
    2
    $f, $6, $00
    2
    $9, $4, $10
    2
    $8, $4, $0c
    2
    $7, $6, $00
    2
    $6, $4, $11
    2
    $5, $4, $10
    2
    $4, $6, $00
    2
    $3, $4, $10
    2
    $2, $6, $00
    2
    $1, $4, $0b
    2
    $FF
end
    return
; End Init_hahaha2

Init_wilhelm
    sdata sfx_wilhelm = SoundDataLoc
    $2, $7, $1d
    1
    $c, $6, $05
    1
    $f, $7, $07
    1
    $f, $6, $17
    1
    $f, $7, $08
    1
    $f, $6, $07
    1
    $f, $6, $00
    1
    $f, $7, $02
    1
    $f, $7, $06
    1
    $f, $4, $0b
    1
    $f, $6, $17
    1
    $f, $1, $0e
    1
    $f, $7, $07
    1
    $f, $6, $0d
    1
    $f, $7, $0c
    1
    $f, $7, $07
    1
    $f, $7, $03
    1
    $f, $4, $0a
    1
    $f, $1, $0a
    1
    $f, $7, $05
    1
    $f, $4, $0a
    1
    $f, $6, $0c
    1
    $f, $4, $0a
    1
    $f, $4, $0a
    1
    $f, $1, $09
    1
    $f, $4, $0a
    1
    $f, $6, $1b
    1
    $f, $4, $0a
    1
    $f, $1, $0a
    1
    $f, $4, $0a
    1
    $f, $4, $0a
    1
    $f, $f, $13
    1
    $f, $6, $00
    1
    $f, $4, $0a
    1
    $f, $1, $10
    1
    $f, $4, $13
    1
    $f, $7, $08
    1
    $f, $1, $09
    1
    $f, $1, $18
    1
    $f, $4, $0a
    1
    $f, $4, $15
    1
    $f, $4, $13
    1
    $f, $4, $15
    1
    $f, $4, $15
    1
    $f, $4, $15
    1
    $f, $4, $15
    1
    $f, $4, $16
    1
    $f, $4, $17
    1
    $f, $1, $0e
    1
    $9, $4, $19
    1
    $7, $7, $0a
    1
    $7, $4, $15
    1
    $4, $6, $00
    1
    $9, $4, $13
    1
    $c, $4, $12
    1
    $4, $4, $12
    1
    $4, $4, $16
    1
    $4, $7, $08
    1
    $4, $7, $07
    1
    $4, $7, $08
    1
    $2, $f, $1b
    1
    $2, $4, $13
    1
    $2, $7, $09
    1
    $2, $7, $0b
    1
    $FF
end
    return
; End Init_wilhelm

Init_poof1
    sdata sfx_poof1 = SoundDataLoc
    $4, $8, $07
    1
    $6, $8, $07
    1
    $8, $8, $07
    1
    $8, $8, $09
    1
    $a, $8, $0c
    1
    $a, $8, $09
    1
    $a, $8, $0c
    1
    $a, $8, $09
    1
    $8, $8, $0d
    1
    $6, $8, $0e
    1
    $4, $8, $09
    1
    $2, $8, $09
    1
    $FF
end
    return
; End Init_poof1

Init_poof2
    sdata sfx_poof2 = SoundDataLoc
    $4, $8, $0a
    1
    $6, $8, $12
    1
    $8, $8, $09
    1
    $8, $8, $11
    1
    $a, $8, $08
    1
    $a, $8, $10
    1
    $a, $8, $07
    1
    $a, $8, $0F
    1
    $8, $8, $06
    1
    $6, $8, $0E
    1
    $4, $8, $05
    1
    $2, $8, $0D
    1
    $FF
end
    return
; End Init_poof2

Init_dragit
    sdata sfx_dragit = SoundDataLoc
    $2, $7, $1c
    1
    $6, $7, $02
    1
    $9, $8, $1e
    1
    $9, $8, $11
    1
    $9, $8, $1e
    1
    $6, $7, $11
    1
    $9, $8, $1e
    1
    $6, $7, $11
    1
    $3, $7, $0e
    1
    $2, $7, $06
    1
    $FF
end
    return
; End Init_dragit

Init_roarcheep
    sdata sfx_roarcheep = SoundDataLoc
    $0, $6, $0a
    1
    $1, $f, $0e
    1
    $9, $e, $12
    1
    $7, $e, $0a
    1
    $e, $f, $0a
    1
    $f, $7, $1b
    1
    $c, $6, $1b
    1
    $e, $f, $13
    1
    $d, $f, $15
    1
    $f, $e, $0f
    1
    $f, $f, $19
    1
    $7, $f, $0d
    1
    $8, $e, $0e
    1
    $8, $f, $0f
    1
    $9, $1, $0a
    1
    $b, $e, $0d
    1
    $c, $7, $19
    1
    $f, $f, $10
    1
    $f, $7, $16
    1
    $f, $4, $10
    1
    $f, $4, $17
    1
    $e, $4, $15
    1
    $f, $7, $1b
    1
    $c, $6, $1f
    1
    $b, $f, $12
    1
    $4, $6, $1a
    1
    $4, $1, $1f
    1
    $9, $e, $0a
    1
    $b, $e, $0f
    1
    $7, $e, $0f
    1
    $6, $e, $0f
    1
    $5, $e, $0f
    1
    $3, $e, $0f
    1
    $1, $e, $0f
    1
    $FF
end
    return
; End Init_roarcheep

Init_roarroar
    sdata sfx_roarroar = SoundDataLoc
    $0, $f, $1d
    1
    $3, $6, $07
    1
    $6, $f, $13
    1
    $9, $6, $05
    1
    $c, $c, $1e
    1
    $f, $6, $06
    1
    $f, $c, $1e
    1
    $f, $c, $1e
    1
    $f, $6, $05
    1
    $f, $c, $1e
    1
    $f, $c, $1f
    1
    $f, $c, $1f
    1
    $f, $c, $1f
    1
    $f, $f, $0f
    1
    $f, $6, $05
    1
    $f, $c, $1e
    1
    $f, $7, $1a
    1
    $f, $6, $05
    1
    $f, $c, $17
    1
    $f, $f, $0a
    1
    $f, $c, $18
    1
    $f, $c, $18
    1
    $f, $6, $05
    1
    $f, $6, $08
    1
    $f, $6, $04
    1
    $c, $6, $05
    1
    $6, $c, $1d
    1
    $3, $6, $05
    1
    $3, $c, $17
    1
    $3, $c, $17
    1
    $3, $c, $17
    1
    $2, $c, $1c
    1
    $2, $c, $1c
    1
    $2, $c, $17
    1
    $1, $6, $06
    1
    $1, $f, $0c
    1
    $FF
end
    return
; End Init_roarroar

Init_deeproar
    sdata sfx_deeproar = SoundDataLoc
    $2, $6, $0f
    1
    $a, $6, $0b
    1
    $f, $6, $1f
    1
    $f, $f, $14
    1
    $f, $6, $0c
    1
    $f, $6, $13
    1
    $f, $6, $0d
    1
    $f, $6, $17
    1
    $f, $6, $16
    1
    $f, $6, $17
    1
    $f, $f, $14
    1
    $f, $6, $13
    1
    $f, $6, $16
    1
    $f, $f, $13
    1
    $f, $6, $16
    1
    $f, $6, $13
    1
    $f, $6, $17
    1
    $f, $f, $13
    1
    $f, $6, $13
    1
    $f, $6, $13
    1
    $f, $f, $14
    1
    $f, $6, $16
    1
    $f, $6, $0d
    1
    $f, $6, $17
    1
    $f, $f, $13
    1
    $f, $6, $13
    1
    $f, $6, $13
    1
    $f, $f, $14
    1
    $f, $6, $17
    1
    $f, $6, $0d
    1
    $f, $f, $14
    1
    $f, $f, $14
    1
    $f, $6, $0d
    1
    $f, $6, $17
    1
    $f, $f, $14
    1
    $f, $6, $13
    1
    $f, $6, $13
    1
    $f, $6, $0d
    1
    $f, $6, $17
    1
    $f, $6, $17
    1
    $c, $f, $13
    1
    $a, $f, $14
    1
    $a, $f, $14
    1
    $a, $6, $17
    1
    $a, $6, $17
    1
    $a, $f, $13
    1
    $7, $6, $0d
    1
    $7, $6, $13
    1
    $7, $6, $17
    1
    $7, $6, $13
    1
    $7, $6, $13
    1
    $7, $6, $0d
    1
    $5, $6, $0d
    1
    $5, $6, $17
    1
    $2, $6, $17
    1
    $2, $6, $0d
    1
    $2, $6, $0d
    1
    $2, $6, $0d
    1
    $2, $f, $1c
    1
    $2, $f, $1d
    1
    $2, $6, $0d
    1
    $2, $6, $0d
    1
    $2, $6, $0c
    1
    $2, $6, $0d
    1
    $2, $f, $1b
    1
    $2, $6, $17
    1
    $2, $6, $0d
    1
    $2, $f, $13
    1
    $2, $f, $13
    1
    $2, $6, $0c
    1
    $FF
end
    return
; End Init_deeproar

Init_echobang
    sdata sfx_echobang = SoundDataLoc
    $f, $7, $19
    1
    $f, $7, $13
    1
    $f, $6, $1a
    1
    $f, $1, $1a
    1
    $f, $7, $17
    1
    $f, $c, $10
    1
    $f, $7, $14
    1
    $f, $7, $04
    1
    $f, $7, $0e
    1
    $f, $1, $1b
    1
    $f, $1, $1b
    1
    $f, $7, $1e
    1
    $f, $7, $12
    1
    $f, $6, $09
    1
    $f, $f, $17
    1
    $f, $6, $11
    1
    $b, $7, $09
    1
    $e, $7, $09
    1
    $b, $f, $0b
    1
    $c, $f, $0e
    1
    $9, $7, $1a
    1
    $9, $f, $13
    1
    $b, $f, $14
    1
    $7, $e, $0c
    1
    $7, $7, $18
    1
    $7, $7, $19
    1
    $6, $f, $0b
    1
    $7, $7, $1a
    1
    $3, $7, $1a
    1
    $3, $7, $1f
    1
    $6, $6, $18
    1
    $4, $6, $17
    1
    $4, $6, $14
    1
    $1, $7, $15
    1
    $FF
end
    return
; End Init_echobang

Init_tom
    sdata sfx_tom = SoundDataLoc
    $4, $6, $19
    1
    $4, $e, $0b
    1
    $8, $6, $1a
    1
    $f, $f, $18
    1
    $f, $f, $15
    1
    $f, $c, $1e
    1
    $f, $c, $1e
    1
    $f, $c, $1e
    1
    $f, $f, $10
    1
    $f, $f, $12
    1
    $c, $c, $1e
    1
    $8, $c, $1e
    1
    $8, $c, $1e
    1
    $4, $c, $1e
    1
    $4, $c, $1e
    1
    $4, $6, $06
    1
    $FF
end
    return
; End Init_tom

Init_clopclop
    sdata sfx_clopclop = SoundDataLoc
    $8, $4, $1e
    1
    $b, $4, $1c
    1
    $d, $4, $15
    1
    $d, $c, $1a
    1
    $d, $c, $17
    1
    $d, $4, $1c
    1
    $d, $4, $16
    1
    $d, $4, $10
    1
    $d, $c, $17
    1
    $d, $c, $10
    1
    $2, $c, $10
    1
    $d, $4, $13
    1
    $d, $6, $04
    1
    $d, $c, $17
    1
    $c, $4, $1c
    1
    $c, $4, $17
    1
    $d, $4, $10
    1
    $d, $c, $16
    1
    $b, $c, $10
    1
    $2, $c, $0b
    1
    $FF
end
    return
; End Init_clopclop

Init_museboom
    sdata sfx_museboom = SoundDataLoc
    $b, $4, $15
    1
    $b, $c, $12
    1
    $d, $4, $1e
    1
    $b, $4, $16
    1
    $c, $6, $04
    1
    $d, $c, $1c
    1
    $b, $c, $0a
    1
    $c, $4, $15
    1
    $a, $c, $1a
    1
    $d, $c, $0c
    1
    $a, $c, $13
    1
    $a, $4, $15
    1
    $a, $c, $1a
    1
    $9, $6, $05
    1
    $9, $c, $0b
    1
    $d, $4, $16
    1
    $8, $c, $13
    1
    $d, $c, $13
    1
    $d, $c, $0b
    1
    $b, $6, $06
    1
    $9, $c, $1d
    1
    $b, $c, $10
    1
    $c, $4, $1e
    1
    $a, $6, $05
    1
    $b, $6, $05
    1
    $a, $c, $0b
    1
    $d, $4, $1c
    1
    $b, $6, $05
    1
    $c, $c, $18
    1
    $c, $c, $0c
    1
    $d, $7, $1b
    1
    $d, $c, $15
    1
    $b, $c, $14
    1
    $d, $c, $0b
    1
    $b, $c, $1e
    1
    $c, $c, $1b
    1
    $c, $c, $0b
    1
    $d, $c, $0d
    1
    $9, $c, $1a
    1
    $9, $c, $15
    1
    $a, $c, $0a
    1
    $7, $6, $06
    1
    $9, $c, $17
    1
    $8, $c, $10
    1
    $7, $c, $1b
    1
    $6, $6, $06
    1
    $7, $c, $17
    1
    $7, $c, $0c
    1
    $7, $6, $06
    1
    $7, $f, $0e
    1
    $7, $c, $14
    1
    $4, $c, $10
    1
    $5, $c, $1a
    1
    $4, $c, $12
    1
    $3, $c, $1c
    1
    $3, $c, $14
    1
    $3, $c, $1e
    1
    $2, $7, $1d
    1
    $1, $6, $08
    1
    $1, $c, $16
    1
    $1, $c, $15
    1
    $FF
end
    return
; End Init_museboom

Init_bigboom
    sdata sfx_bigboom = SoundDataLoc
    $f, $7, $1d
    1
    $f, $6, $1e
    1
    $f, $6, $00
    1
    $f, $7, $14
    1
    $f, $f, $13
    1
    $f, $7, $1b
    1
    $f, $7, $0e
    1
    $f, $7, $1b
    1
    $f, $7, $0f
    1
    $f, $7, $10
    1
    $f, $6, $10
    1
    $f, $7, $16
    1
    $f, $f, $0d
    1
    $f, $c, $1e
    1
    $f, $1, $16
    1
    $f, $1, $17
    1
    $f, $7, $10
    1
    $f, $f, $10
    1
    $d, $7, $15
    1
    $f, $7, $1a
    1
    $f, $1, $1a
    1
    $f, $7, $1a
    1
    $f, $f, $14
    1
    $f, $7, $16
    1
    $f, $7, $16
    1
    $f, $7, $15
    1
    $f, $7, $17
    1
    $f, $f, $13
    1
    $f, $f, $13
    1
    $f, $f, $19
    1
    $c, $7, $18
    1
    $c, $6, $0b
    1
    $d, $1, $1e
    1
    $d, $1, $10
    1
    $f, $7, $14
    1
    $c, $6, $16
    1
    $c, $7, $17
    1
    $c, $1, $1a
    1
    $d, $6, $12
    1
    $c, $7, $17
    1
    $c, $f, $0b
    1
    $9, $7, $19
    1
    $b, $7, $19
    1
    $9, $f, $0b
    1
    $b, $e, $0d
    1
    $b, $e, $0d
    1
    $9, $f, $19
    1
    $6, $f, $0e
    1
    $8, $c, $1b
    1
    $8, $f, $18
    1
    $5, $7, $13
    1
    $5, $1, $1a
    1
    $8, $f, $17
    1
    $8, $6, $16
    1
    $5, $6, $0c
    1
    $6, $f, $1c
    1
    $8, $6, $16
    1
    $6, $6, $0b
    1
    $4, $6, $12
    1
    $5, $f, $0f
    1
    $6, $7, $11
    1
    $5, $6, $09
    1
    $5, $6, $10
    1
    $5, $6, $10
    1
    $5, $6, $10
    1
    $4, $f, $11
    1
    $4, $f, $15
    1
    $5, $7, $1e
    1
    $4, $1, $16
    1
    $4, $1, $16
    1
    $4, $f, $1a
    1
    $2, $f, $19
    1
    $2, $f, $1e
    1
    $2, $f, $1b
    1
    $2, $f, $1e
    1
    $2, $f, $1c
    1
    $1, $f, $0d
    1
    $2, $6, $0f
    1
    $1, $6, $0e
    1
    $1, $f, $18
    1
    $2, $6, $0b
    1
    $1, $f, $16
    1
    $1, $f, $17
    1
    $1, $6, $13
    1
    $1, $e, $0f
    1
    $FF
end
    return
; End Init_bigboom

Init_thud
    sdata sfx_thud = SoundDataLoc
    $f, $7, $1e
    1
    $e, $7, $1e
    1
    $e, $f, $12
    1
    $e, $7, $1f
    1
    $c, $f, $1f
    1
    $9, $f, $0f
    1
    $7, $f, $0e
    1
    $7, $f, $11
    1
    $4, $f, $10
    1
    $4, $e, $11
    1
    $2, $e, $0c
    1
    $FF
end
    return
; End Init_thud

PlaySound6
    if SoundDuration then SoundDuration = SoundDuration - 1
    if SoundDuration then return otherbank
    SoundVolume = sread(SoundDataLoc)
    if SoundVolume <> $FF then goto ____skip_end_sound6
    SoundPlayingBit1{1} = 0
    AUDC0 = 0 : AUDV0 = 0 : COLUPF = 0
    bally = 200 ; offscreen
    return otherbank
____skip_end_sound6
    SoundChannel = sread(SoundDataLoc)
    SoundFrequency = sread(SoundDataLoc)
    SoundDuration = sread(SoundDataLoc)
    AUDC0 = SoundChannel
    AUDV0 = SoundVolume
    AUDF0 = SoundFrequency
    gosub SoundVisual bank1
    return otherbank
; End PlaySound6

InitSound6
    if SoundPlayingBit1{1} then goto ____skip_sound_init_6
    CurrentSoundAdjusted = CurrentSound - 95
    on CurrentSoundAdjusted gosub Init_distressed4 Init_hahaha Init_yeah Init_arfarf Init_activate Init_hahaha2 Init_wilhelm Init_poof1 Init_poof2 Init_dragit Init_roarcheep Init_roarroar Init_deeproar Init_echobang Init_tom Init_clopclop Init_museboom Init_bigboom Init_thud
    SoundPlayingBit1{1} = 1
____skip_sound_init_6
    return otherbank
; End InitSound6


    bank 7 

Init_bump
    sdata sfx_bump = SoundDataLoc
    $0, $f, $0b
    1
    $b, $6, $0c
    1
    $f, $6, $0a
    1
    $f, $6, $0b
    1
    $e, $6, $0a
    1
    $d, $f, $15
    1
    $c, $6, $0e
    1
    $b, $6, $0d
    1
    $a, $f, $19
    1
    $9, $f, $16
    1
    $8, $f, $19
    1
    $7, $6, $10
    1
    $6, $c, $0d
    1
    $5, $c, $19
    1
    $4, $c, $1c
    1
    $3, $c, $1e
    1
    $2, $6, $06
    1
    $1, $6, $06
    1
    $FF
end
    return
; End Init_bump

Init_shouty
    sdata sfx_shouty = SoundDataLoc
    $1, $4, $19
    1
    $4, $4, $19
    1
    $9, $4, $12
    1
    $9, $4, $12
    1
    $9, $4, $12
    1
    $7, $4, $11
    1
    $7, $4, $11
    1
    $8, $4, $12
    1
    $8, $4, $12
    1
    $7, $4, $12
    1
    $7, $4, $12
    1
    $b, $4, $12
    1
    $9, $4, $0f
    1
    $9, $4, $0f
    1
    $9, $4, $0f
    1
    $9, $4, $0f
    1
    $8, $4, $12
    1
    $b, $4, $11
    1
    $b, $4, $0f
    1
    $d, $4, $11
    1
    $e, $4, $11
    1
    $e, $4, $11
    1
    $d, $4, $12
    1
    $f, $4, $11
    1
    $f, $4, $11
    1
    $f, $4, $11
    1
    $f, $4, $11
    1
    $c, $4, $11
    1
    $b, $4, $11
    1
    $b, $4, $11
    1
    $b, $4, $12
    1
    $a, $4, $11
    1
    $b, $4, $11
    1
    $b, $4, $12
    1
    $d, $4, $12
    1
    $d, $4, $12
    1
    $a, $4, $0f
    1
    $a, $4, $12
    1
    $7, $4, $12
    1
    $6, $4, $15
    1
    $6, $4, $15
    1
    $4, $4, $19
    1
    $2, $4, $1b
    1
    $1, $6, $01
    1
    $1, $6, $0d
    1
    $FF
end
    return
; End Init_shouty

Init_quack
    sdata sfx_quack = SoundDataLoc
    $8, $6, $15
    1
    $9, $6, $15
    1
    $A, $6, $15
    1
    $B, $6, $14
    1
    $C, $6, $14
    1
    $D, $6, $14
    1
    $E, $6, $14
    1
    $F, $6, $13
    1
    $F, $6, $13
    1
    $F, $6, $13
    1
    $F, $6, $13
    1
    $F, $6, $13
    1
    $FF
end
    return
; End Init_quack

PlaySound7
    if SoundDuration then SoundDuration = SoundDuration - 1
    if SoundDuration then return otherbank
    SoundVolume = sread(SoundDataLoc)
    if SoundVolume <> $FF then goto ____skip_end_sound7
    SoundPlayingBit1{1} = 0
    AUDC0 = 0 : AUDV0 = 0 : COLUPF = 0
    bally = 200 ; offscreen
    return otherbank
____skip_end_sound7
    SoundChannel = sread(SoundDataLoc)
    SoundFrequency = sread(SoundDataLoc)
    SoundDuration = sread(SoundDataLoc)
    AUDC0 = SoundChannel
    AUDV0 = SoundVolume
    AUDF0 = SoundFrequency
    gosub SoundVisual bank1
    return otherbank
; End PlaySound7

InitSound7
    if SoundPlayingBit1{1} then goto ____skip_sound_init_7
    CurrentSoundAdjusted = CurrentSound - 114
    on CurrentSoundAdjusted gosub Init_bump Init_shouty Init_quack
    SoundPlayingBit1{1} = 1
____skip_sound_init_7
    return otherbank
; End InitSound7

    bank 8

    const total_sounds = 117
    data text_strings
    __S, __A, __L, __V, __O, __L, __A, __S, __E, __R, __S, __H
    __S, __P, __A, __C, __E, __I, __N, __V, __S, __H, __O, __O
    __B, __E, __R, __Z, __E, __R, __K, __R, __O, __B, __O, __T
    __E, __C, __H, __O, __1, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __E, __C, __H, __O, __2, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __J, __U, __M, __P, __M, __A, __N, _sp, _sp, _sp, _sp, _sp
    __C, __A, __V, __A, __L, __R, __Y, _sp, _sp, _sp, _sp, _sp
    __A, __L, __I, __E, __N, __T, __R, __I, __L, __L, __1, _sp
    __A, __L, __I, __E, __N, __T, __R, __I, __L, __L, __2, _sp
    __P, __I, __T, __F, __A, __L, __L, __J, __U, __M, __P, _sp
    __A, __D, __V, __P, __I, __C, __K, __U, __P, _sp, _sp, _sp
    __A, __D, __V, __D, __R, __O, __P, _sp, _sp, _sp, _sp, _sp
    __A, __D, __V, __B, __I, __T, __E, _sp, _sp, _sp, _sp, _sp
    __A, __D, __V, __D, __R, __A, __G, __O, __N, __S, __L, __A
    __B, __L, __I, __N, __G, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __D, __R, __O, __P, __M, __E, __D, __I, __U, __M, _sp, _sp
    __E, __L, __E, __C, __T, __R, __O, __B, __U, __M, __P, _sp
    __E, __X, __P, __L, __O, __S, __I, __O, __N, _sp, _sp, _sp
    __H, __U, __M, __A, __N, __O, __I, __D, _sp, _sp, _sp, _sp
    __T, __R, __A, __N, __S, __P, __O, __R, __T, __E, __R, _sp
    __T, __W, __I, __N, __K, __L, __E, _sp, _sp, _sp, _sp, _sp
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    __E, __L, __E, __C, __T, __R, __O, __S, __W, __I, __T, __C
    __N, __O, __N, __O, __B, __O, __U, __N, __C, __E, _sp, _sp
    __7, __0, __S, __T, __V, __C, __O, __M, __P, __U, __T, __E
    __A, __L, __I, __E, __N, __L, __I, __F, __E, _sp, _sp, _sp
    __C, __H, __I, __R, __P, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __P, __L, __O, __N, __K, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __S, __P, __A, __W, __N, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __M, __A, __S, __E, __R, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __R, __U, __B, __B, __E, __R, __M, __A, __L, __L, __E, __T
    __A, __L, __I, __E, __N, __K, __I, __T, __T, __Y, _sp, _sp
    __E, __L, __E, __C, __T, __R, __O, __P, __U, __N, __C, __H
    __D, __R, __I, __P, _sp, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __R, __I, __B, __B, __I, __T, _sp, _sp, _sp, _sp, _sp, _sp
    __W, __O, __L, __F, __W, __H, __I, __S, __T, __L, __E, _sp
    __C, __A, __B, __W, __H, __I, __S, __T, __L, __E, _sp, _sp
    __J, __U, __M, __P, __O, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __P, __U, __L, __S, __E, __C, __A, __N, __N, __O, __N, _sp
    __S, __P, __R, __I, __N, __G, _sp, _sp, _sp, _sp, _sp, _sp
    __B, __U, __Z, __Z, __B, __O, __M, __B, _sp, _sp, _sp, _sp
    __B, __A, __S, __S, __B, __U, __M, __P, _sp, _sp, _sp, _sp
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    __H, __O, __P, __H, __O, __P, _sp, _sp, _sp, _sp, _sp, _sp
    __D, __I, __S, __T, __R, __E, __S, __S, __E, __D, _sp, _sp
    __O, __U, __C, __H, _sp, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __L, __A, __S, __E, __R, __R, __E, __C, __O, __I, __L, _sp
    __E, __L, __E, __C, __T, __R, __O, __S, __P, __L, __O, __S
    __H, __O, __P, __H, __I, __P, _sp, _sp, _sp, _sp, _sp, _sp
    __H, __O, __P, __H, __I, __P, __Q, __U, __I, __C, __K, _sp
    __B, __A, __S, __S, __B, __U, __M, __P, __2, _sp, _sp, _sp
    __P, __I, __C, __K, __U, __P, __P, __R, __I, __Z, __E, _sp
    __D, __I, __S, __T, __R, __E, __S, __S, __E, __D, __2, _sp
    __P, __E, __W, __P, __E, __W, _sp, _sp, _sp, _sp, _sp, _sp
    __D, __E, __N, __I, __E, __D, _sp, _sp, _sp, _sp, _sp, _sp
    __T, __E, __L, __E, __P, __O, __R, __T, __E, __D, _sp, _sp
    __A, __L, __I, __E, __N, __K, __L, __A, __X, __O, __N, _sp
    __C, __R, __Y, __S, __T, __A, __L, __C, __H, __I, __M, __E
    __O, __N, __E, __U, __P, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __B, __A, __B, __Y, __W, __A, __H, _sp, _sp, _sp, _sp, _sp
    __G, __O, __T, __T, __H, __E, __C, __O, __I, __N, _sp, _sp
    __B, __A, __B, __Y, __R, __I, __B, __B, __I, __T, _sp, _sp
    __S, __Q, __U, __E, __E, __K, _sp, _sp, _sp, _sp, _sp, _sp
    __W, __H, __O, __A, _sp, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __G, __O, __T, __T, __H, __E, __R, __I, __N, __G, _sp, _sp
    __Y, __A, __H, __O, __O, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __W, __A, __R, __C, __R, __Y, _sp, _sp, _sp, _sp, _sp, _sp
    __D, __O, __W, __N, __T, __H, __E, __P, __I, __P, __E, _sp
    __P, __O, __W, __E, __R, __U, __P, _sp, _sp, _sp, _sp, _sp
    __F, __A, __L, __L, __I, __N, __G, _sp, _sp, _sp, _sp, _sp
    __E, __E, __K, _sp, _sp, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __U, __H, __O, __H, _sp, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __A, __N, __O, __T, __H, __E, __R, __U, __P, _sp, _sp, _sp
    __B, __U, __B, __B, __L, __E, __U, __P, _sp, _sp, _sp, _sp
    __J, __U, __M, __P, __1, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __P, __L, __A, __I, __N, __L, __A, __S, __E, __R, _sp, _sp
    __A, __L, __I, __E, __N, __C, __O, __O, _sp, _sp, _sp, _sp
    __S, __I, __M, __P, __L, __E, __B, __U, __Z, __Z, _sp, _sp
    __J, __U, __M, __P, __2, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __J, __U, __M, __P, __3, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __D, __U, __N, __N, __O, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __S, __N, __O, __R, __E, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __U, __N, __C, __O, __V, __E, __R, __E, __D, _sp, _sp, _sp
    __D, __O, __O, __R, __P, __O, __U, __N, __D, _sp, _sp, _sp
    __D, __I, __S, __T, __R, __E, __S, __S, __E, __D, __3, _sp
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    __E, __E, __K, __2, _sp, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __R, __U, __B, __B, __E, __R, __H, __A, __M, __M, __E, __R
    __A, __L, __I, __E, __N, __B, __U, __Z, __Z, _sp, _sp, _sp
    __A, __N, __O, __T, __H, __E, __R, __J, __U, __M, __P, __M
    __A, __N, __O, __T, __H, __E, __R, __J, __U, __M, __P, __D
    __L, __O, __N, __G, __G, __O, __N, __G, __S, __I, __L, __V
    __S, __T, __R, __U, __M, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __D, __R, __O, __P, __P, __E, __D, _sp, _sp, _sp, _sp, _sp
    __A, __L, __I, __E, __N, __A, __G, __G, __R, __E, __S, __S
    __E, __L, __E, __C, __T, __R, __O, __S, __W, __I, __T, __C
    __G, __O, __O, __D, __I, __T, __E, __M, _sp, _sp, _sp, _sp
    __B, __A, __B, __Y, __R, __I, __B, __B, __I, __T, __H, __O
    __D, __I, __S, __T, __R, __E, __S, __S, __E, __D, __4, _sp
    __H, __A, __H, __A, __H, __A, _sp, _sp, _sp, _sp, _sp, _sp
    __Y, __E, __A, __H, _sp, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __A, __R, __F, __A, __R, __F, _sp, _sp, _sp, _sp, _sp, _sp
    __A, __C, __T, __I, __V, __A, __T, __E, _sp, _sp, _sp, _sp
    __H, __A, __H, __A, __H, __A, __2, _sp, _sp, _sp, _sp, _sp
    __W, __I, __L, __H, __E, __L, __M, _sp, _sp, _sp, _sp, _sp
    __P, __O, __O, __F, __1, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    __P, __O, __O, __F, __2, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __D, __R, __A, __G, __I, __T, _sp, _sp, _sp, _sp, _sp, _sp
    __R, __O, __A, __R, __C, __H, __E, __E, __P, _sp, _sp, _sp
    __R, __O, __A, __R, __R, __O, __A, __R, _sp, _sp, _sp, _sp
    __D, __E, __E, __P, __R, __O, __A, __R, _sp, _sp, _sp, _sp
    __E, __C, __H, __O, __B, __A, __N, __G, _sp, _sp, _sp, _sp
    __T, __O, __M, _sp, _sp, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __C, __L, __O, __P, __C, __L, __O, __P, _sp, _sp, _sp, _sp
    __M, __U, __S, __E, __B, __O, __O, __M, _sp, _sp, _sp, _sp
    __B, __I, __G, __B, __O, __O, __M, _sp, _sp, _sp, _sp, _sp
    __T, __H, __U, __D, _sp, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __B, __U, __M, __P, _sp, _sp, _sp, _sp, _sp, _sp, _sp, _sp
    __S, __H, __O, __U, __T, __Y, _sp, _sp, _sp, _sp, _sp, _sp
    __Q, __U, __A, __C, __K, _sp, _sp, _sp, _sp, _sp, _sp, _sp
end

    inline text12a.asm
    inline text12b.asm
