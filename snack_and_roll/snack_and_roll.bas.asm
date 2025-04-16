; Provided under the CC0 license. See the included LICENSE.txt for details.

 processor 6502
 include "vcs.h"
 include "macro.h"
 include "2600basic.h"
 include "2600basic_variable_redefs.h"
 ifconst bankswitch
  if bankswitch == 8
     ORG $1000
     RORG $D000
  endif
  if bankswitch == 16
     ORG $1000
     RORG $9000
  endif
  if bankswitch == 32
     ORG $1000
     RORG $1000
  endif
  if bankswitch == 64
     ORG $1000
     RORG $1000
  endif
 else
   ORG $F000
 endif

 ifconst bankswitch_hotspot
 if bankswitch_hotspot = $083F ; 0840 bankswitching hotspot
   .byte 0 ; stop unexpected bankswitches
 endif
 endif
; Provided under the CC0 license. See the included LICENSE.txt for details.

start
 sei
 cld
 ldy #0
 lda $D0
 cmp #$2C               ;check RAM location #1
 bne MachineIs2600
 lda $D1
 cmp #$A9               ;check RAM location #2
 bne MachineIs2600
 dey
MachineIs2600
 ldx #0
 txa
clearmem
 inx
 txs
 pha
 bne clearmem
 sty temp1
 ifnconst multisprite
 ifconst pfrowheight
 lda #pfrowheight
 else
 ifconst pfres
 lda #(96/pfres)
 else
 lda #8
 endif
 endif
 sta playfieldpos
 endif
 ldx #5
initscore
 lda #<scoretable
 sta scorepointers,x 
 dex
 bpl initscore
 lda #1
 sta CTRLPF
 ora INTIM
 sta rand

 ifconst multisprite
   jsr multisprite_setup
 endif

 ifnconst bankswitch
   jmp game
 else
   lda #>(game-1)
   pha
   lda #<(game-1)
   pha
   pha
   pha
   ldx #1
   jmp BS_jsr
 endif
; Provided under the CC0 license. See the included LICENSE.txt for details.

     ; This is a 2-line kernel!
     ifnconst vertical_reflect
kernel
     endif
     sta WSYNC
     lda #255
     sta TIM64T

     lda #1
     sta VDELBL
     sta VDELP0
     ldx ballheight
     inx
     inx
     stx temp4
     lda player1y
     sta temp3

     ifconst shakescreen
         jsr doshakescreen
     else
         ldx missile0height
         inx
     endif

     inx
     stx stack1

     lda bally
     sta stack2

     lda player0y
     ldx #0
     sta WSYNC
     stx GRP0
     stx GRP1
     stx PF1L
     stx PF2
     stx CXCLR
     ifconst readpaddle
         stx paddle
     else
         sleep 3
     endif

     sta temp2,x

     ;store these so they can be retrieved later
     ifnconst pfres
         ldx #128-44+(4-pfwidth)*12
     else
         ldx #132-pfres*pfwidth
     endif

     dec player0y

     lda missile0y
     sta temp5
     lda missile1y
     sta temp6

     lda playfieldpos
     sta temp1
     
     ifconst pfrowheight
         lda #pfrowheight+2
     else
         ifnconst pfres
             lda #10
         else
             lda #(96/pfres)+2 ; try to come close to the real size
         endif
     endif
     clc
     sbc playfieldpos
     sta playfieldpos
     jmp .startkernel

.skipDrawP0
     lda #0
     tay
     jmp .continueP0

.skipDrawP1
     lda #0
     tay
     jmp .continueP1

.kerloop     ; enter at cycle 59??

continuekernel
     sleep 2
continuekernel2
     lda ballheight
     
     ifconst pfres
         ldy playfield+pfres*pfwidth-132,x
         sty PF1L ;3
         ldy playfield+pfres*pfwidth-131-pfadjust,x
         sty PF2L ;3
         ldy playfield+pfres*pfwidth-129,x
         sty PF1R ; 3 too early?
         ldy playfield+pfres*pfwidth-130-pfadjust,x
         sty PF2R ;3
     else
         ldy playfield-48+pfwidth*12+44-128,x
         sty PF1L ;3
         ldy playfield-48+pfwidth*12+45-128-pfadjust,x ;4
         sty PF2L ;3
         ldy playfield-48+pfwidth*12+47-128,x ;4
         sty PF1R ; 3 too early?
         ldy playfield-48+pfwidth*12+46-128-pfadjust,x;4
         sty PF2R ;3
     endif

     ; should be playfield+$38 for width=2

     dcp bally
     rol
     rol
     ; rol
     ; rol
goback
     sta ENABL 
.startkernel
     lda player1height ;3
     dcp player1y ;5
     bcc .skipDrawP1 ;2
     ldy player1y ;3
     lda (player1pointer),y ;5; player0pointer must be selected carefully by the compiler
     ; so it doesn't cross a page boundary!

.continueP1
     sta GRP1 ;3

     ifnconst player1colors
         lda missile1height ;3
         dcp missile1y ;5
         rol;2
         rol;2
         sta ENAM1 ;3
     else
         lda (player1color),y
         sta COLUP1
         ifnconst playercolors
             sleep 7
         else
             lda.w player0colorstore
             sta COLUP0
         endif
     endif

     ifconst pfres
         lda playfield+pfres*pfwidth-132,x 
         sta PF1L ;3
         lda playfield+pfres*pfwidth-131-pfadjust,x 
         sta PF2L ;3
         lda playfield+pfres*pfwidth-129,x 
         sta PF1R ; 3 too early?
         lda playfield+pfres*pfwidth-130-pfadjust,x 
         sta PF2R ;3
     else
         lda playfield-48+pfwidth*12+44-128,x ;4
         sta PF1L ;3
         lda playfield-48+pfwidth*12+45-128-pfadjust,x ;4
         sta PF2L ;3
         lda playfield-48+pfwidth*12+47-128,x ;4
         sta PF1R ; 3 too early?
         lda playfield-48+pfwidth*12+46-128-pfadjust,x;4
         sta PF2R ;3
     endif 
     ; sleep 3

     lda player0height
     dcp player0y
     bcc .skipDrawP0
     ldy player0y
     lda (player0pointer),y
.continueP0
     sta GRP0

     ifnconst no_blank_lines
         ifnconst playercolors
             lda missile0height ;3
             dcp missile0y ;5
             sbc stack1
             sta ENAM0 ;3
         else
             lda (player0color),y
             sta player0colorstore
             sleep 6
         endif
         dec temp1
         bne continuekernel
     else
         dec temp1
         beq altkernel2
         ifconst readpaddle
             ldy currentpaddle
             lda INPT0,y
             bpl noreadpaddle
             inc paddle
             jmp continuekernel2
noreadpaddle
             sleep 2
             jmp continuekernel
         else
             ifnconst playercolors 
                 ifconst PFcolors
                     txa
                     tay
                     lda (pfcolortable),y
                     ifnconst backgroundchange
                         sta COLUPF
                     else
                         sta COLUBK
                     endif
                     jmp continuekernel
                 else
                     ifconst kernelmacrodef
                         kernelmacro
                     else
                         sleep 12
                     endif
                 endif
             else
                 lda (player0color),y
                 sta player0colorstore
                 sleep 4
             endif
             jmp continuekernel
         endif
altkernel2
         txa
         ifnconst vertical_reflect
             sbx #256-pfwidth
         else
             sbx #256-pfwidth/2
         endif
         bmi lastkernelline
         ifconst pfrowheight
             lda #pfrowheight
         else
             ifnconst pfres
                 lda #8
             else
                 lda #(96/pfres) ; try to come close to the real size
             endif
         endif
         sta temp1
         jmp continuekernel
     endif

altkernel

     ifconst PFmaskvalue
         lda #PFmaskvalue
     else
         lda #0
     endif
     sta PF1L
     sta PF2


     ;sleep 3

     ;28 cycles to fix things
     ;minus 11=17

     ; lax temp4
     ; clc
     txa
     ifnconst vertical_reflect
         sbx #256-pfwidth
     else
         sbx #256-pfwidth/2
     endif

     bmi lastkernelline

     ifconst PFcolorandheight
         ifconst pfres
             ldy playfieldcolorandheight-131+pfres*pfwidth,x
         else
             ldy playfieldcolorandheight-87,x
         endif
         ifnconst backgroundchange
             sty COLUPF
         else
             sty COLUBK
         endif
         ifconst pfres
             lda playfieldcolorandheight-132+pfres*pfwidth,x
         else
             lda playfieldcolorandheight-88,x
         endif
         sta.w temp1
     endif
     ifconst PFheights
         lsr
         lsr
         tay
         lda (pfheighttable),y
         sta.w temp1
     endif
     ifconst PFcolors
         tay
         lda (pfcolortable),y
         ifnconst backgroundchange
             sta COLUPF
         else
             sta COLUBK
         endif
         ifconst pfrowheight
             lda #pfrowheight
         else
             ifnconst pfres
                 lda #8
             else
                 lda #(96/pfres) ; try to come close to the real size
             endif
         endif
         sta temp1
     endif
     ifnconst PFcolorandheight
         ifnconst PFcolors
             ifnconst PFheights
                 ifnconst no_blank_lines
                     ; read paddle 0
                     ; lo-res paddle read
                     ; bit INPT0
                     ; bmi paddleskipread
                     ; inc paddle0
                     ;donepaddleskip
                     sleep 10
                     ifconst pfrowheight
                         lda #pfrowheight
                     else
                         ifnconst pfres
                             lda #8
                         else
                             lda #(96/pfres) ; try to come close to the real size
                         endif
                     endif
                     sta temp1
                 endif
             endif
         endif
     endif
     

     lda ballheight
     dcp bally
     sbc temp4


     jmp goback


     ifnconst no_blank_lines
lastkernelline
         ifnconst PFcolors
             sleep 10
         else
             ldy #124
             lda (pfcolortable),y
             sta COLUPF
         endif

         ifconst PFheights
             ldx #1
             ;sleep 4
             sleep 3 ; this was over 1 cycle
         else
             ldx playfieldpos
             ;sleep 3
             sleep 2 ; this was over 1 cycle
         endif

         jmp enterlastkernel

     else
lastkernelline
         
         ifconst PFheights
             ldx #1
             ;sleep 5
             sleep 4 ; this was over 1 cycle
         else
             ldx playfieldpos
             ;sleep 4
             sleep 3 ; this was over 1 cycle
         endif

         cpx #0
         bne .enterfromNBL
         jmp no_blank_lines_bailout
     endif

     if ((<*)>$d5)
         align 256
     endif
     ; this is a kludge to prevent page wrapping - fix!!!

.skipDrawlastP1
     lda #0
     tay ; added so we don't cross a page
     jmp .continuelastP1

.endkerloop     ; enter at cycle 59??
     
     nop

.enterfromNBL
     ifconst pfres
         ldy.w playfield+pfres*pfwidth-4
         sty PF1L ;3
         ldy.w playfield+pfres*pfwidth-3-pfadjust
         sty PF2L ;3
         ldy.w playfield+pfres*pfwidth-1
         sty PF1R ; possibly too early?
         ldy.w playfield+pfres*pfwidth-2-pfadjust
         sty PF2R ;3
     else
         ldy.w playfield-48+pfwidth*12+44
         sty PF1L ;3
         ldy.w playfield-48+pfwidth*12+45-pfadjust
         sty PF2L ;3
         ldy.w playfield-48+pfwidth*12+47
         sty PF1R ; possibly too early?
         ldy.w playfield-48+pfwidth*12+46-pfadjust
         sty PF2R ;3
     endif

enterlastkernel
     lda ballheight

     ; tya
     dcp bally
     ; sleep 4

     ; sbc stack3
     rol
     rol
     sta ENABL 

     lda player1height ;3
     dcp player1y ;5
     bcc .skipDrawlastP1
     ldy player1y ;3
     lda (player1pointer),y ;5; player0pointer must be selected carefully by the compiler
     ; so it doesn't cross a page boundary!

.continuelastP1
     sta GRP1 ;3

     ifnconst player1colors
         lda missile1height ;3
         dcp missile1y ;5
     else
         lda (player1color),y
         sta COLUP1
     endif

     dex
     ;dec temp4 ; might try putting this above PF writes
     beq endkernel


     ifconst pfres
         ldy.w playfield+pfres*pfwidth-4
         sty PF1L ;3
         ldy.w playfield+pfres*pfwidth-3-pfadjust
         sty PF2L ;3
         ldy.w playfield+pfres*pfwidth-1
         sty PF1R ; possibly too early?
         ldy.w playfield+pfres*pfwidth-2-pfadjust
         sty PF2R ;3
     else
         ldy.w playfield-48+pfwidth*12+44
         sty PF1L ;3
         ldy.w playfield-48+pfwidth*12+45-pfadjust
         sty PF2L ;3
         ldy.w playfield-48+pfwidth*12+47
         sty PF1R ; possibly too early?
         ldy.w playfield-48+pfwidth*12+46-pfadjust
         sty PF2R ;3
     endif

     ifnconst player1colors
         rol;2
         rol;2
         sta ENAM1 ;3
     else
         ifnconst playercolors
             sleep 7
         else
             lda.w player0colorstore
             sta COLUP0
         endif
     endif
     
     lda.w player0height
     dcp player0y
     bcc .skipDrawlastP0
     ldy player0y
     lda (player0pointer),y
.continuelastP0
     sta GRP0



     ifnconst no_blank_lines
         lda missile0height ;3
         dcp missile0y ;5
         sbc stack1
         sta ENAM0 ;3
         jmp .endkerloop
     else
         ifconst readpaddle
             ldy currentpaddle
             lda INPT0,y
             bpl noreadpaddle2
             inc paddle
             jmp .endkerloop
noreadpaddle2
             sleep 4
             jmp .endkerloop
         else ; no_blank_lines and no paddle reading
             pla
             pha ; 14 cycles in 4 bytes
             pla
             pha
             ; sleep 14
             jmp .endkerloop
         endif
     endif


     ; ifconst donepaddleskip
         ;paddleskipread
         ; this is kind of lame, since it requires 4 cycles from a page boundary crossing
         ; plus we get a lo-res paddle read
         ; bmi donepaddleskip
     ; endif

.skipDrawlastP0
     lda #0
     tay
     jmp .continuelastP0

     ifconst no_blank_lines
no_blank_lines_bailout
         ldx #0
     endif

endkernel
     ; 6 digit score routine
     stx PF1
     stx PF2
     stx PF0
     clc

     ifconst pfrowheight
         lda #pfrowheight+2
     else
         ifnconst pfres
             lda #10
         else
             lda #(96/pfres)+2 ; try to come close to the real size
         endif
     endif

     sbc playfieldpos
     sta playfieldpos
     txa

     ifconst shakescreen
         bit shakescreen
         bmi noshakescreen2
         ldx #$3D
noshakescreen2
     endif

     sta WSYNC,x

     ; STA WSYNC ;first one, need one more
     sta REFP0
     sta REFP1
     STA GRP0
     STA GRP1
     ; STA PF1
     ; STA PF2
     sta HMCLR
     sta ENAM0
     sta ENAM1
     sta ENABL

     lda temp2 ;restore variables that were obliterated by kernel
     sta player0y
     lda temp3
     sta player1y
     ifnconst player1colors
         lda temp6
         sta missile1y
     endif
     ifnconst playercolors
         ifnconst readpaddle
             lda temp5
             sta missile0y
         endif
     endif
     lda stack2
     sta bally

     ; strangely, this isn't required any more. might have
     ; resulted from the no_blank_lines score bounce fix
     ;ifconst no_blank_lines
         ;sta WSYNC
     ;endif

     lda INTIM
     clc
     ifnconst vblank_time
         adc #43+12+87
     else
         adc #vblank_time+12+87

     endif
     ; sta WSYNC
     sta TIM64T

     ifconst minikernel
         jsr minikernel
     endif

     ; now reassign temp vars for score pointers

     ; score pointers contain:
     ; score1-5: lo1,lo2,lo3,lo4,lo5,lo6
     ; swap lo2->temp1
     ; swap lo4->temp3
     ; swap lo6->temp5
     ifnconst noscore
         lda scorepointers+1
         ; ldy temp1
         sta temp1
         ; sty scorepointers+1

         lda scorepointers+3
         ; ldy temp3
         sta temp3
         ; sty scorepointers+3


         sta HMCLR
         tsx
         stx stack1 
         ldx #$E0
         stx HMP0

         LDA scorecolor 
         STA COLUP0
         STA COLUP1
         ifconst scorefade
             STA stack2
         endif
         ifconst pfscore
             lda pfscorecolor
             sta COLUPF
         endif
         sta WSYNC
         ldx #0
         STx GRP0
         STx GRP1 ; seems to be needed because of vdel

         lda scorepointers+5
         ; ldy temp5
         sta temp5,x
         ; sty scorepointers+5
         lda #>scoretable
         sta scorepointers+1
         sta scorepointers+3
         sta scorepointers+5
         sta temp2
         sta temp4
         sta temp6
         LDY #7
         STY VDELP0
         STA RESP0
         STA RESP1


         LDA #$03
         STA NUSIZ0
         STA NUSIZ1
         STA VDELP1
         LDA #$F0
         STA HMP1
         lda (scorepointers),y
         sta GRP0
         STA HMOVE ; cycle 73 ?
         jmp beginscore


         if ((<*)>$d4)
             align 256 ; kludge that potentially wastes space! should be fixed!
         endif

loop2
         lda (scorepointers),y ;+5 68 204
         sta GRP0 ;+3 71 213 D1 -- -- --
         ifconst pfscore
             lda.w pfscore1
             sta PF1
         else
             ifconst scorefade
                 sleep 2
                 dec stack2 ; decrement the temporary scorecolor
             else
                 sleep 7
             endif
         endif
         ; cycle 0
beginscore
         lda (scorepointers+$8),y ;+5 5 15
         sta GRP1 ;+3 8 24 D1 D1 D2 --
         lda (scorepointers+$6),y ;+5 13 39
         sta GRP0 ;+3 16 48 D3 D1 D2 D2
         lax (scorepointers+$2),y ;+5 29 87
         txs
         lax (scorepointers+$4),y ;+5 36 108
         ifconst scorefade
             lda stack2
         else
             sleep 3
         endif

         ifconst pfscore
             lda pfscore2
             sta PF1
         else
             ifconst scorefade
                 sta COLUP0
                 sta COLUP1
             else
                 sleep 6
             endif
         endif

         lda (scorepointers+$A),y ;+5 21 63
         stx GRP1 ;+3 44 132 D3 D3 D4 D2!
         tsx
         stx GRP0 ;+3 47 141 D5 D3! D4 D4
         sta GRP1 ;+3 50 150 D5 D5 D6 D4!
         sty GRP0 ;+3 53 159 D4* D5! D6 D6
         dey
         bpl loop2 ;+2 60 180

         ldx stack1 
         txs
         ; lda scorepointers+1
         ldy temp1
         ; sta temp1
         sty scorepointers+1

         LDA #0 
         sta PF1
         STA GRP0
         STA GRP1
         STA VDELP0
         STA VDELP1;do we need these
         STA NUSIZ0
         STA NUSIZ1

         ; lda scorepointers+3
         ldy temp3
         ; sta temp3
         sty scorepointers+3

         ; lda scorepointers+5
         ldy temp5
         ; sta temp5
         sty scorepointers+5
     endif ;noscore
    ifconst readpaddle
        lda #%11000010
    else
        ifconst qtcontroller
            lda qtcontroller
            lsr    ; bit 0 in carry
            lda #4
            ror    ; carry into top of A
        else
            lda #2
        endif ; qtcontroller
    endif ; readpaddle
 sta WSYNC
 sta VBLANK
 RETURN
     ifconst shakescreen
doshakescreen
         bit shakescreen
         bmi noshakescreen
         sta WSYNC
noshakescreen
         ldx missile0height
         inx
         rts
     endif

; Provided under the CC0 license. See the included LICENSE.txt for details.

; playfield drawing routines
; you get a 32x12 bitmapped display in a single color :)
; 0-31 and 0-11

pfclear ; clears playfield - or fill with pattern
 ifconst pfres
 ldx #pfres*pfwidth-1
 else
 ldx #47-(4-pfwidth)*12 ; will this work?
 endif
pfclear_loop
 ifnconst superchip
 sta playfield,x
 else
 sta playfield-128,x
 endif
 dex
 bpl pfclear_loop
 RETURN
 
setuppointers
 stx temp2 ; store on.off.flip value
 tax ; put x-value in x 
 lsr
 lsr
 lsr ; divide x pos by 8 
 sta temp1
 tya
 asl
 if pfwidth=4
  asl ; multiply y pos by 4
 endif ; else multiply by 2
 clc
 adc temp1 ; add them together to get actual memory location offset
 tay ; put the value in y
 lda temp2 ; restore on.off.flip value
 rts

pfread
;x=xvalue, y=yvalue
 jsr setuppointers
 lda setbyte,x
 and playfield,y
 eor setbyte,x
; beq readzero
; lda #1
; readzero
 RETURN

pfpixel
;x=xvalue, y=yvalue, a=0,1,2
 jsr setuppointers

 ifconst bankswitch
 lda temp2 ; load on.off.flip value (0,1, or 2)
 beq pixelon_r  ; if "on" go to on
 lsr
 bcs pixeloff_r ; value is 1 if true
 lda playfield,y ; if here, it's "flip"
 eor setbyte,x
 ifconst superchip
 sta playfield-128,y
 else
 sta playfield,y
 endif
 RETURN
pixelon_r
 lda playfield,y
 ora setbyte,x
 ifconst superchip
 sta playfield-128,y
 else
 sta playfield,y
 endif
 RETURN
pixeloff_r
 lda setbyte,x
 eor #$ff
 and playfield,y
 ifconst superchip
 sta playfield-128,y
 else
 sta playfield,y
 endif
 RETURN

 else
 jmp plotpoint
 endif

pfhline
;x=xvalue, y=yvalue, a=0,1,2, temp3=endx
 jsr setuppointers
 jmp noinc
keepgoing
 inx
 txa
 and #7
 bne noinc
 iny
noinc
 jsr plotpoint
 cpx temp3
 bmi keepgoing
 RETURN

pfvline
;x=xvalue, y=yvalue, a=0,1,2, temp3=endx
 jsr setuppointers
 sty temp1 ; store memory location offset
 inc temp3 ; increase final x by 1 
 lda temp3
 asl
 if pfwidth=4
   asl ; multiply by 4
 endif ; else multiply by 2
 sta temp3 ; store it
 ; Thanks to Michael Rideout for fixing a bug in this code
 ; right now, temp1=y=starting memory location, temp3=final
 ; x should equal original x value
keepgoingy
 jsr plotpoint
 iny
 iny
 if pfwidth=4
   iny
   iny
 endif
 cpy temp3
 bmi keepgoingy
 RETURN

plotpoint
 lda temp2 ; load on.off.flip value (0,1, or 2)
 beq pixelon  ; if "on" go to on
 lsr
 bcs pixeloff ; value is 1 if true
 lda playfield,y ; if here, it's "flip"
 eor setbyte,x
  ifconst superchip
 sta playfield-128,y
 else
 sta playfield,y
 endif
 rts
pixelon
 lda playfield,y
 ora setbyte,x
 ifconst superchip
 sta playfield-128,y
 else
 sta playfield,y
 endif
 rts
pixeloff
 lda setbyte,x
 eor #$ff
 and playfield,y
 ifconst superchip
 sta playfield-128,y
 else
 sta playfield,y
 endif
 rts

setbyte
 ifnconst pfcenter
 .byte $80
 .byte $40
 .byte $20
 .byte $10
 .byte $08
 .byte $04
 .byte $02
 .byte $01
 endif
 .byte $01
 .byte $02
 .byte $04
 .byte $08
 .byte $10
 .byte $20
 .byte $40
 .byte $80
 .byte $80
 .byte $40
 .byte $20
 .byte $10
 .byte $08
 .byte $04
 .byte $02
 .byte $01
 .byte $01
 .byte $02
 .byte $04
 .byte $08
 .byte $10
 .byte $20
 .byte $40
 .byte $80
; Provided under the CC0 license. See the included LICENSE.txt for details.

pfscroll ;(a=0 left, 1 right, 2 up, 4 down, 6=upup, 12=downdown)
 bne notleft
;left
 ifconst pfres
 ldx #pfres*4
 else
 ldx #48
 endif
leftloop
 lda playfield-1,x
 lsr

 ifconst superchip
 lda playfield-2,x
 rol
 sta playfield-130,x
 lda playfield-3,x
 ror
 sta playfield-131,x
 lda playfield-4,x
 rol
 sta playfield-132,x
 lda playfield-1,x
 ror
 sta playfield-129,x
 else
 rol playfield-2,x
 ror playfield-3,x
 rol playfield-4,x
 ror playfield-1,x
 endif

 txa
 sbx #4
 bne leftloop
 RETURN

notleft
 lsr
 bcc notright
;right

 ifconst pfres
 ldx #pfres*4
 else
 ldx #48
 endif
rightloop
 lda playfield-4,x
 lsr
 ifconst superchip
 lda playfield-3,x
 rol
 sta playfield-131,x
 lda playfield-2,x
 ror
 sta playfield-130,x
 lda playfield-1,x
 rol
 sta playfield-129,x
 lda playfield-4,x
 ror
 sta playfield-132,x
 else
 rol playfield-3,x
 ror playfield-2,x
 rol playfield-1,x
 ror playfield-4,x
 endif
 txa
 sbx #4
 bne rightloop
  RETURN

notright
 lsr
 bcc notup
;up
 lsr
 bcc onedecup
 dec playfieldpos
onedecup
 dec playfieldpos
 beq shiftdown 
 bpl noshiftdown2 
shiftdown
  ifconst pfrowheight
 lda #pfrowheight
 else
 ifnconst pfres
   lda #8
 else
   lda #(96/pfres) ; try to come close to the real size
 endif
 endif

 sta playfieldpos
 lda playfield+3
 sta temp4
 lda playfield+2
 sta temp3
 lda playfield+1
 sta temp2
 lda playfield
 sta temp1
 ldx #0
up2
 lda playfield+4,x
 ifconst superchip
 sta playfield-128,x
 lda playfield+5,x
 sta playfield-127,x
 lda playfield+6,x
 sta playfield-126,x
 lda playfield+7,x
 sta playfield-125,x
 else
 sta playfield,x
 lda playfield+5,x
 sta playfield+1,x
 lda playfield+6,x
 sta playfield+2,x
 lda playfield+7,x
 sta playfield+3,x
 endif
 txa
 sbx #252
 ifconst pfres
 cpx #(pfres-1)*4
 else
 cpx #44
 endif
 bne up2

 lda temp4
 
 ifconst superchip
 ifconst pfres
 sta playfield+pfres*4-129
 lda temp3
 sta playfield+pfres*4-130
 lda temp2
 sta playfield+pfres*4-131
 lda temp1
 sta playfield+pfres*4-132
 else
 sta playfield+47-128
 lda temp3
 sta playfield+46-128
 lda temp2
 sta playfield+45-128
 lda temp1
 sta playfield+44-128
 endif
 else
 ifconst pfres
 sta playfield+pfres*4-1
 lda temp3
 sta playfield+pfres*4-2
 lda temp2
 sta playfield+pfres*4-3
 lda temp1
 sta playfield+pfres*4-4
 else
 sta playfield+47
 lda temp3
 sta playfield+46
 lda temp2
 sta playfield+45
 lda temp1
 sta playfield+44
 endif
 endif
noshiftdown2
 RETURN


notup
;down
 lsr
 bcs oneincup
 inc playfieldpos
oneincup
 inc playfieldpos
 lda playfieldpos

  ifconst pfrowheight
 cmp #pfrowheight+1
 else
 ifnconst pfres
   cmp #9
 else
   cmp #(96/pfres)+1 ; try to come close to the real size
 endif
 endif

 bcc noshiftdown 
 lda #1
 sta playfieldpos

 ifconst pfres
 lda playfield+pfres*4-1
 sta temp4
 lda playfield+pfres*4-2
 sta temp3
 lda playfield+pfres*4-3
 sta temp2
 lda playfield+pfres*4-4
 else
 lda playfield+47
 sta temp4
 lda playfield+46
 sta temp3
 lda playfield+45
 sta temp2
 lda playfield+44
 endif

 sta temp1

 ifconst pfres
 ldx #(pfres-1)*4
 else
 ldx #44
 endif
down2
 lda playfield-1,x
 ifconst superchip
 sta playfield-125,x
 lda playfield-2,x
 sta playfield-126,x
 lda playfield-3,x
 sta playfield-127,x
 lda playfield-4,x
 sta playfield-128,x
 else
 sta playfield+3,x
 lda playfield-2,x
 sta playfield+2,x
 lda playfield-3,x
 sta playfield+1,x
 lda playfield-4,x
 sta playfield,x
 endif
 txa
 sbx #4
 bne down2

 lda temp4
 ifconst superchip
 sta playfield-125
 lda temp3
 sta playfield-126
 lda temp2
 sta playfield-127
 lda temp1
 sta playfield-128
 else
 sta playfield+3
 lda temp3
 sta playfield+2
 lda temp2
 sta playfield+1
 lda temp1
 sta playfield
 endif
noshiftdown
 RETURN
; Provided under the CC0 license. See the included LICENSE.txt for details.

;standard routines needed for pretty much all games
; just the random number generator is left - maybe we should remove this asm file altogether?
; repositioning code and score pointer setup moved to overscan
; read switches, joysticks now compiler generated (more efficient)

randomize
	lda rand
	lsr
 ifconst rand16
	rol rand16
 endif
	bcc noeor
	eor #$B4
noeor
	sta rand
 ifconst rand16
	eor rand16
 endif
	RETURN
; Provided under the CC0 license. See the included LICENSE.txt for details.

drawscreen
     ifconst debugscore
         ldx #14
         lda INTIM ; display # cycles left in the score

         ifconst mincycles
             lda mincycles 
             cmp INTIM
             lda mincycles
             bcc nochange
             lda INTIM
             sta mincycles
nochange
         endif

         ; cmp #$2B
         ; bcs no_cycles_left
         bmi cycles_left
         ldx #64
         eor #$ff ;make negative
cycles_left
         stx scorecolor
         and #$7f ; clear sign bit
         tax
         lda scorebcd,x
         sta score+2
         lda scorebcd1,x
         sta score+1
         jmp done_debugscore 
scorebcd
         .byte $00, $64, $28, $92, $56, $20, $84, $48, $12, $76, $40
         .byte $04, $68, $32, $96, $60, $24, $88, $52, $16, $80, $44
         .byte $08, $72, $36, $00, $64, $28, $92, $56, $20, $84, $48
         .byte $12, $76, $40, $04, $68, $32, $96, $60, $24, $88
scorebcd1
         .byte 0, 0, 1, 1, 2, 3, 3, 4, 5, 5, 6
         .byte 7, 7, 8, 8, 9, $10, $10, $11, $12, $12, $13
         .byte $14, $14, $15, $16, $16, $17, $17, $18, $19, $19, $20
         .byte $21, $21, $22, $23, $23, $24, $24, $25, $26, $26
done_debugscore
     endif

     ifconst debugcycles
         lda INTIM ; if we go over, it mucks up the background color
         ; cmp #$2B
         ; BCC overscan
         bmi overscan
         sta COLUBK
         bcs doneoverscan
     endif

overscan
     ifconst interlaced
         PHP
         PLA 
         EOR #4 ; flip interrupt bit
         PHA
         PLP
         AND #4 ; isolate the interrupt bit
         TAX ; save it for later
     endif

overscanloop
     lda INTIM ;wait for sync
     bmi overscanloop
doneoverscan

     ;do VSYNC

     ifconst interlaced
         CPX #4
         BNE oddframevsync
     endif

     lda #2
     sta WSYNC
     sta VSYNC
     STA WSYNC
     STA WSYNC
     lsr
     STA WSYNC
     STA VSYNC
     sta VBLANK
     ifnconst overscan_time
         lda #37+128
     else
         lda #overscan_time+128
     endif
     sta TIM64T

     ifconst interlaced
         jmp postsync 

oddframevsync
         sta WSYNC

         LDA ($80,X) ; 11 waste
         LDA ($80,X) ; 11 waste
         LDA ($80,X) ; 11 waste

         lda #2
         sta VSYNC
         sta WSYNC
         sta WSYNC
         sta WSYNC

         LDA ($80,X) ; 11 waste
         LDA ($80,X) ; 11 waste
         LDA ($80,X) ; 11 waste

         lda #0
         sta VSYNC
         sta VBLANK
         ifnconst overscan_time
             lda #37+128
         else
             lda #overscan_time+128
         endif
         sta TIM64T

postsync
     endif

     ifconst legacy
         if legacy < 100
             ldx #4
adjustloop
             lda player0x,x
             sec
             sbc #14 ;?
             sta player0x,x
             dex
             bpl adjustloop
         endif
     endif
     if ((<*)>$e9)&&((<*)<$fa)
         repeat ($fa-(<*))
         nop
         repend
     endif
     sta WSYNC
     ldx #4
     SLEEP 3
HorPosLoop     ; 5
     lda player0x,X ;+4 9
     sec ;+2 11
DivideLoop
     sbc #15
     bcs DivideLoop;+4 15
     sta temp1,X ;+4 19
     sta RESP0,X ;+4 23
     sta WSYNC
     dex
     bpl HorPosLoop;+5 5
     ; 4

     ldx #4
     ldy temp1,X
     lda repostable-256,Y
     sta HMP0,X ;+14 18

     dex
     ldy temp1,X
     lda repostable-256,Y
     sta HMP0,X ;+14 32

     dex
     ldy temp1,X
     lda repostable-256,Y
     sta HMP0,X ;+14 46

     dex
     ldy temp1,X
     lda repostable-256,Y
     sta HMP0,X ;+14 60

     dex
     ldy temp1,X
     lda repostable-256,Y
     sta HMP0,X ;+14 74

     sta WSYNC
     
     sta HMOVE ;+3 3


     ifconst legacy
         if legacy < 100
             ldx #4
adjustloop2
             lda player0x,x
             clc
             adc #14 ;?
             sta player0x,x
             dex
             bpl adjustloop2
         endif
     endif




     ;set score pointers
     lax score+2
     jsr scorepointerset
     sty scorepointers+5
     stx scorepointers+2
     lax score+1
     jsr scorepointerset
     sty scorepointers+4
     stx scorepointers+1
     lax score
     jsr scorepointerset
     sty scorepointers+3
     stx scorepointers

vblk
     ; run possible vblank bB code
     ifconst vblank_bB_code
         jsr vblank_bB_code
     endif
vblk2
     LDA INTIM
     bmi vblk2
     jmp kernel
     

     .byte $80,$70,$60,$50,$40,$30,$20,$10,$00
     .byte $F0,$E0,$D0,$C0,$B0,$A0,$90
repostable

scorepointerset
     and #$0F
     asl
     asl
     asl
     adc #<scoretable
     tay 
     txa
     ; and #$F0
     ; lsr
     asr #$F0
     adc #<scoretable
     tax
     rts
game
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L00 ;  set kernel_options pfcolors

.L01 ;  set romsize 4k

.L02 ;  set pal

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L03 ;  const pfscore  =  1

.L04 ;  const scorefade  =  1

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L05 ;  const _P_Edge_Top  =  0

.L06 ;  const _P_Edge_Bottom  =  88

.L07 ;  const _P_Edge_Left  =  0

.L08 ;  const _P_Edge_Right  =  153

.
 ; 

.
 ; 

.L09 ;  const _base_color  =  $16

.L010 ;  const _P0_color  =  $2C

.L011 ;  const _P1_color  =  $32

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L012 ;  dim _timer_light  =  a

.L013 ;  dim _level  =  b

.L014 ;  dim _animation  =  f

.L015 ;  dim _timer_pf  =  e

.
 ; 

.L016 ;  dim frame_counter  =  c

.L017 ;  dim seconds_counter  =  d

.
 ; 

.L018 ;  dim sugar  =  s

.L019 ;  dim sugar_count  =  t

.
 ; 

.L020 ;  dim _b0_gameStart  =  k

.L021 ;  dim _b4_gameLight  =  k

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.__inizialize
 ; __inizialize

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L022 ;  COLUP0  =  _P0_color  :  COLUP1  =  _P1_color  :  NUSIZ0  =  $00  :  REFP0  =  0

	LDA #_P0_color
	STA COLUP0
	LDA #_P1_color
	STA COLUP1
	LDA #$00
	STA NUSIZ0
	LDA #0
	STA REFP0
.L023 ;  COLUBK  =  0

	LDA #0
	STA COLUBK
.
 ; 

.L024 ;  scorecolor  =  _base_color  :  pfscorecolor  =  _base_color

	LDA #_base_color
	STA scorecolor
	STA pfscorecolor
.
 ; 

.L025 ;  a  =  0  :  b  =  0  :  c  =  0  :  d  =  0  :  e  =  0  :  f  =  0  :  g  =  0  :  h  =  0  :  i  =  0

	LDA #0
	STA a
	STA b
	STA c
	STA d
	STA e
	STA f
	STA g
	STA h
	STA i
.L026 ;  j  =  0  :  k  =  0  :  l  =  0  :  m  =  0  :  n  =  0  :  o  =  0  :  p  =  0  :  q  =  0  :  r  =  0

	LDA #0
	STA j
	STA k
	STA l
	STA m
	STA n
	STA o
	STA p
	STA q
	STA r
.L027 ;  s  =  255  :  t  =  0  :  u  =  0  :  v  =  0  :  w  =  0  :  x  =  0  :  y  =  0  :  z  =  0

	LDA #255
	STA s
	LDA #0
	STA t
	STA u
	STA v
	STA w
	STA x
	STA y
	STA z
.
 ; 

.L028 ;  score  =  0

	LDA #$00
	STA score+2
	LDA #$00
	STA score+1
	LDA #$00
	STA score
.L029 ;  pfscore1  =  255

	LDA #255
	STA pfscore1
.L030 ;  pfscore2  =  255

	LDA #255
	STA pfscore2
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L031 ;  player0x  =  30  :  player0y  =  54  :  player1x  =  20  :  player1y  =  54

	LDA #30
	STA player0x
	LDA #54
	STA player0y
	LDA #20
	STA player1x
	LDA #54
	STA player1y
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.__startGame
 ; __startGame

.
 ; 

.L032 ;  _b0_gameStart{0}  =  0

	LDA _b0_gameStart
	AND #254
	STA _b0_gameStart
.L033 ;  _b4_gameLight{4}  =  1

	LDA _b4_gameLight
	ORA #16
	STA _b4_gameLight
.L034 ;  _level  =  0

	LDA #0
	STA _level
.
 ; 

.L035 ;  _animation  =  0

	LDA #0
	STA _animation
.L036 ;  _timer_light  =  0

	LDA #0
	STA _timer_light
.L037 ;  _timer_pf  =  0

	LDA #0
	STA _timer_pf
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L038 ;  playfield:

  ifconst pfres
	  ldx #(11>pfres)*(pfres*pfwidth-1)+(11<=pfres)*43
  else
	  ldx #((11*pfwidth-1)*((11*pfwidth-1)<47))+(47*((11*pfwidth-1)>=47))
  endif
	jmp pflabel0
PF_data0
	.byte %00001111, %00011111
	if (pfwidth>2)
	.byte %11000000, %00010010
 endif
	.byte %00010000, %00000000
	if (pfwidth>2)
	.byte %00100000, %00001010
 endif
	.byte %00001100, %00011010
	if (pfwidth>2)
	.byte %11100111, %00000110
 endif
	.byte %00000010, %10100110
	if (pfwidth>2)
	.byte %00101000, %00001010
 endif
	.byte %11111100, %00100010
	if (pfwidth>2)
	.byte %11100111, %00010010
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00101000
 endif
	.byte %01000000, %00000010
	if (pfwidth>2)
	.byte %00000000, %00010100
 endif
	.byte %00010110, %10000000
	if (pfwidth>2)
	.byte %01100110, %00001010
 endif
	.byte %00011001, %10000000
	if (pfwidth>2)
	.byte %10001001, %00001010
 endif
	.byte %00010001, %10000000
	if (pfwidth>2)
	.byte %00000110, %00001010
 endif
pflabel0
	lda PF_data0,x
	sta playfield,x
	dex
	bpl pflabel0
.L039 ;  pfcolors:

 lda # $22
 sta COLUPF
 ifconst pfres
 lda #>(pfcolorlabel13-132+pfres*pfwidth)
 else
 lda #>(pfcolorlabel13-84)
 endif
 sta pfcolortable+1
 ifconst pfres
 lda #<(pfcolorlabel13-132+pfres*pfwidth)
 else
 lda #<(pfcolorlabel13-84)
 endif
 sta pfcolortable
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L040 ;  goto __skip_playfield

 jmp .__skip_playfield

.
 ; 

.__main_loop
 ; __main_loop

.
 ; 

.
 ; 

.L041 ;  if switchreset  &&  !_b0_gameStart{0} then _b0_gameStart{0}  =  1  :  _b4_gameLight{4}  =  1  :  _timer_pf  =  0  :  _level  =  1  :  sugar  =  0  :  sugar_count  =  0  :  goto __select_level

 lda #1
 bit SWCHB
	BNE .skipL041
.condpart0
	LDA _b0_gameStart
	LSR
	BCS .skip0then
.condpart1
	LDA _b0_gameStart
	ORA #1
	STA _b0_gameStart
	LDA _b4_gameLight
	ORA #16
	STA _b4_gameLight
	LDA #0
	STA _timer_pf
	LDA #1
	STA _level
	LDA #0
	STA sugar
	STA sugar_count
 jmp .__select_level

.skip0then
.skipL041
.
 ; 

.
 ; 

.
 ; 

.L042 ;  if !_b0_gameStart{0} then goto __skip_playfield

	LDA _b0_gameStart
	LSR
	BCS .skipL042
.condpart2
 jmp .__skip_playfield

.skipL042
.
 ; 

.
 ; 

.
 ; 

.L043 ;  frame_counter  =  frame_counter  +  1

	INC frame_counter
.L044 ;  if frame_counter  =  60 then frame_counter  =  0  :  seconds_counter  =  seconds_counter  +  1

	LDA frame_counter
	CMP #60
     BNE .skipL044
.condpart3
	LDA #0
	STA frame_counter
	INC seconds_counter
.skipL044
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L045 ;  if joy0right  ||  joy0left then _animation  =  _animation  +  1

 bit SWCHA
	BMI .skipL045
.condpart4
 jmp .condpart5
.skipL045
 bit SWCHA
	BVS .skip1OR
.condpart5
	INC _animation
.skip1OR
.L046 ;  if joy0up  ||  joy0down then _animation  =  _animation  +  1

 lda #$10
 bit SWCHA
	BNE .skipL046
.condpart6
 jmp .condpart7
.skipL046
 lda #$20
 bit SWCHA
	BNE .skip2OR
.condpart7
	INC _animation
.skip2OR
.L047 ;  if !joy0right  &&  !joy0left  &&  !joy0up  &&  !joy0down then _animation  =  0

 bit SWCHA
	BPL .skipL047
.condpart8
 bit SWCHA
	BVC .skip8then
.condpart9
 lda #$10
 bit SWCHA
	BEQ .skip9then
.condpart10
 lda #$20
 bit SWCHA
	BEQ .skip10then
.condpart11
	LDA #0
	STA _animation
.skip10then
.skip9then
.skip8then
.skipL047
.L048 ;  if _animation  =  10 then _animation  =  0

	LDA _animation
	CMP #10
     BNE .skipL048
.condpart12
	LDA #0
	STA _animation
.skipL048
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L049 ;  if frame_counter  =  30 then player1x  =   ( rand / 4 )   +   ( rand & 31 )   +   ( rand & 15 )   +   ( rand & 1 )   +  21  :  player1y  =   ( rand  &  31 )   +   ( rand  &  15 )   +   ( rand  &  3 )   +  20

	LDA frame_counter
	CMP #30
     BNE .skipL049
.condpart13
; complex statement detected
 jsr randomize
	lsr
	lsr
	PHA
 jsr randomize
	AND #31
	TSX
	INX
	TXS
	CLC
	ADC $00,x
	PHA
 jsr randomize
	AND #15
	TSX
	INX
	TXS
	CLC
	ADC $00,x
	PHA
 jsr randomize
	AND #1
	TSX
	INX
	TXS
	CLC
	ADC $00,x
	CLC
	ADC #21
	STA player1x
; complex statement detected
 jsr randomize
	AND #31
	PHA
 jsr randomize
	AND #15
	TSX
	INX
	TXS
	CLC
	ADC $00,x
	PHA
 jsr randomize
	AND #3
	TSX
	INX
	TXS
	CLC
	ADC $00,x
	CLC
	ADC #20
	STA player1y
.skipL049
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L050 ;  if joy0fire  &&  !_b4_gameLight{4} then _b4_gameLight{4}  =  1

 bit INPT4
	BMI .skipL050
.condpart14
	LDA _b4_gameLight
	AND #16
	BNE .skip14then
.condpart15
	LDA _b4_gameLight
	ORA #16
	STA _b4_gameLight
.skip14then
.skipL050
.
 ; 

.
 ; 

.L051 ;  if seconds_counter  =  20  &&  _b4_gameLight{4} then _b4_gameLight{4}  =  0

	LDA seconds_counter
	CMP #20
     BNE .skipL051
.condpart16
	LDA _b4_gameLight
	AND #16
	BEQ .skip16then
.condpart17
	LDA _b4_gameLight
	AND #239
	STA _b4_gameLight
.skip16then
.skipL051
.
 ; 

.
 ; 

.L052 ;  if _b4_gameLight{4} then pfcolors:

	LDA _b4_gameLight
	AND #16
	BEQ .skipL052
.condpart18
 lda # $24
 sta COLUPF
 ifconst pfres
 lda #>(pfcolorlabel13-131+pfres*pfwidth)
 else
 lda #>(pfcolorlabel13-83)
 endif
 sta pfcolortable+1
 ifconst pfres
 lda #<(pfcolorlabel13-131+pfres*pfwidth)
 else
 lda #<(pfcolorlabel13-83)
 endif
 sta pfcolortable
.skipL052
.
 ; 

.L053 ;  if !_b4_gameLight{4} then pfcolors:

	LDA _b4_gameLight
	AND #16
	BNE .skipL053
.condpart19
 lda # $24
 sta COLUPF
 ifconst pfres
 lda #>(pfcolorlabel13-130+pfres*pfwidth)
 else
 lda #>(pfcolorlabel13-82)
 endif
 sta pfcolortable+1
 ifconst pfres
 lda #<(pfcolorlabel13-130+pfres*pfwidth)
 else
 lda #<(pfcolorlabel13-82)
 endif
 sta pfcolortable
.skipL053
.
 ; 

.__skip_light
 ; __skip_light

.
 ; 

.L054 ;  scorecolor  =  _animation

	LDA _animation
	STA scorecolor
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L055 ;  if _animation < 5 then player0:

	LDA _animation
	CMP #5
     BCS .skipL055
.condpart20
	LDX #<player20then_0
	STX player0pointerlo
	LDA #>player20then_0
	STA player0pointerhi
	LDA #3
	STA player0height
.skipL055
.
 ; 

.L056 ;  if _animation  > 5 then player0:

	LDA #5
	CMP _animation
     BCS .skipL056
.condpart21
	LDX #<player21then_0
	STX player0pointerlo
	LDA #>player21then_0
	STA player0pointerhi
	LDA #3
	STA player0height
.skipL056
.
 ; 

.L057 ;  if _timer_pf  >  0  &&  _timer_pf  <  20 then player1:

	LDA #0
	CMP _timer_pf
     BCS .skipL057
.condpart22
	LDA _timer_pf
	CMP #20
     BCS .skip22then
.condpart23
	LDX #<player23then_1
	STX player1pointerlo
	LDA #>player23then_1
	STA player1pointerhi
	LDA #3
	STA player1height
.skip22then
.skipL057
.
 ; 

.L058 ;  if _timer_pf  >  20  &&  _timer_pf  <  40 then player1:

	LDA #20
	CMP _timer_pf
     BCS .skipL058
.condpart24
	LDA _timer_pf
	CMP #40
     BCS .skip24then
.condpart25
	LDX #<player25then_1
	STX player1pointerlo
	LDA #>player25then_1
	STA player1pointerhi
	LDA #3
	STA player1height
.skip24then
.skipL058
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L059 ;  if frame_counter  &  7  =  0 then missile0x  =  _data_sugar_x[sugar_count]  :  missile0y  =  _data_sugar_y[sugar_count]  :  missile0 on  :  sugar_count  =  sugar_count  +  1

; complex condition detected
	LDA frame_counter
	AND #7
	CMP #0
     BNE .skipL059
.condpart26
	LDX sugar_count
	LDA _data_sugar_x,x
	STA missile0x
	LDX sugar_count
	LDA _data_sugar_y,x
	STA missile0y
.skipL059
.L060 ;  if frame_counter  >  56 then sugar_count  =  0

	LDA #56
	CMP frame_counter
     BCS .skipL060
.condpart27
	LDA #0
	STA sugar_count
.skipL060
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L061 ;  if frame_counter  =  10 then pfhline 8 6 12 on  :  pfpixel 1 0 on  :  pfpixel _data_sugar_x[sugar_count] 1 on

	LDA frame_counter
	CMP #10
     BNE .skipL061
.condpart28
	LDX #0
	LDA #12
	STA temp3
	LDY #6
	LDA #8
 jsr pfhline
	LDX #0
	LDY #0
	LDA #1
 jsr pfpixel
	LDX #0
	LDY #1
	LDX sugar_count
	LDA _data_sugar_x,x
 jsr pfpixel
.skipL061
.L062 ;  if frame_counter  =  15 then pfhline 9 7 12 on  :  pfpixel 1 0 off  :  pfpixel _data_sugar_x[sugar_count] 1 off  :  pfhline 17 8 20 off

	LDA frame_counter
	CMP #15
     BNE .skipL062
.condpart29
	LDX #0
	LDA #12
	STA temp3
	LDY #7
	LDA #9
 jsr pfhline
	LDX #1
	LDY #0
	LDA #1
 jsr pfpixel
	LDX #1
	LDY #1
	LDX sugar_count
	LDA _data_sugar_x,x
 jsr pfpixel
	LDX #1
	LDA #20
	STA temp3
	LDY #8
	LDA #17
 jsr pfhline
.skipL062
.L063 ;  if frame_counter  =  20 then pfhline 10 8 12 on  :  pfpixel 1 2 on  :  pfpixel _data_sugar_x[sugar_count] 3 on  :  pfhline 17 8 20 on

	LDA frame_counter
	CMP #20
     BNE .skipL063
.condpart30
	LDX #0
	LDA #12
	STA temp3
	LDY #8
	LDA #10
 jsr pfhline
	LDX #0
	LDY #2
	LDA #1
 jsr pfpixel
	LDX #0
	LDY #3
	LDX sugar_count
	LDA _data_sugar_x,x
 jsr pfpixel
	LDX #0
	LDA #20
	STA temp3
	LDY #8
	LDA #17
 jsr pfhline
.skipL063
.L064 ;  if frame_counter  =  45  &&  _timer_pf  <  120 then pfhline 8 8 12 off  :  pfpixel _data_sugar_x[sugar_count] 2 off

	LDA frame_counter
	CMP #45
     BNE .skipL064
.condpart31
	LDA _timer_pf
	CMP #120
     BCS .skip31then
.condpart32
	LDX #1
	LDA #12
	STA temp3
	LDY #8
	LDA #8
 jsr pfhline
	LDX #1
	LDY #2
	LDX sugar_count
	LDA _data_sugar_x,x
 jsr pfpixel
.skip31then
.skipL064
.L065 ;  if frame_counter  =  50  &&  _timer_pf  <  120 then pfhline 8 7 12 off  :  pfpixel _data_sugar_x[sugar_count] 4 on :  pfpixel 1 3 off

	LDA frame_counter
	CMP #50
     BNE .skipL065
.condpart33
	LDA _timer_pf
	CMP #120
     BCS .skip33then
.condpart34
	LDX #1
	LDA #12
	STA temp3
	LDY #7
	LDA #8
 jsr pfhline
	LDX #0
	LDY #4
	LDX sugar_count
	LDA _data_sugar_x,x
 jsr pfpixel
	LDX #1
	LDY #3
	LDA #1
 jsr pfpixel
.skip33then
.skipL065
.L066 ;  if frame_counter  =  55  &&  _timer_pf  <  120 then pfhline 8 6 12 off  :  pfpixel _data_sugar_x[sugar_count] 4 off

	LDA frame_counter
	CMP #55
     BNE .skipL066
.condpart35
	LDA _timer_pf
	CMP #120
     BCS .skip35then
.condpart36
	LDX #1
	LDA #12
	STA temp3
	LDY #6
	LDA #8
 jsr pfhline
	LDX #1
	LDY #4
	LDX sugar_count
	LDA _data_sugar_x,x
 jsr pfpixel
.skip35then
.skipL066
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L067 ;  if !joy0up then goto __Skip_Joy0_Up

 lda #$10
 bit SWCHA
	BEQ .skipL067
.condpart37
 jmp .__Skip_Joy0_Up

.skipL067
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L068 ;  if player0y  <=  _P_Edge_Top then goto __Skip_Joy0_Up

	LDA #_P_Edge_Top
	CMP player0y
     BCC .skipL068
.condpart38
 jmp .__Skip_Joy0_Up

.skipL068
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L069 ;  temp5  =   ( player0x - 10 )  / 4

; complex statement detected
	LDA player0x
	SEC
	SBC #10
	lsr
	lsr
	STA temp5
.
 ; 

.L070 ;  temp6  =   ( player0y - 5 )  / 8

; complex statement detected
	LDA player0y
	SEC
	SBC #5
	lsr
	lsr
	lsr
	STA temp6
.
 ; 

.L071 ;  if temp5  <  34 then if pfread ( temp5 , temp6 )  then goto __Skip_Joy0_Up

	LDA temp5
	CMP #34
     BCS .skipL071
.condpart39
	LDA temp5
	LDY temp6
 jsr pfread
	BNE .skip39then
.condpart40
 jmp .__Skip_Joy0_Up

.skip39then
.skipL071
.
 ; 

.L072 ;  temp4  =   ( player0x - 17 )  / 4

; complex statement detected
	LDA player0x
	SEC
	SBC #17
	lsr
	lsr
	STA temp4
.
 ; 

.L073 ;  if temp4  <  34 then if pfread ( temp4 , temp6 )  then goto __Skip_Joy0_Up

	LDA temp4
	CMP #34
     BCS .skipL073
.condpart41
	LDA temp4
	LDY temp6
 jsr pfread
	BNE .skip41then
.condpart42
 jmp .__Skip_Joy0_Up

.skip41then
.skipL073
.
 ; 

.L074 ;  temp3  =  temp5  -  1

	LDA temp5
	SEC
	SBC #1
	STA temp3
.
 ; 

.L075 ;  if temp3  <  34 then if pfread ( temp3 , temp6 )  then goto __Skip_Joy0_Up

	LDA temp3
	CMP #34
     BCS .skipL075
.condpart43
	LDA temp3
	LDY temp6
 jsr pfread
	BNE .skip43then
.condpart44
 jmp .__Skip_Joy0_Up

.skip43then
.skipL075
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L076 ;  player0y  =  player0y  -  1

	DEC player0y
.
 ; 

.__Skip_Joy0_Up
 ; __Skip_Joy0_Up

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L077 ;  if !joy0down then goto __Skip_Joy0_Down

 lda #$20
 bit SWCHA
	BEQ .skipL077
.condpart45
 jmp .__Skip_Joy0_Down

.skipL077
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L078 ;  if player0y  >=  _P_Edge_Bottom then goto __Skip_Joy0_Down

	LDA player0y
	CMP #_P_Edge_Bottom
     BCC .skipL078
.condpart46
 jmp .__Skip_Joy0_Down

.skipL078
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L079 ;  temp5  =   ( player0x - 10 )  / 4

; complex statement detected
	LDA player0x
	SEC
	SBC #10
	lsr
	lsr
	STA temp5
.
 ; 

.L080 ;  temp6  =   ( player0y )  / 8

; complex statement detected
	LDA player0y
	lsr
	lsr
	lsr
	STA temp6
.
 ; 

.L081 ;  if temp5  <  34 then if pfread ( temp5 , temp6 )  then goto __Skip_Joy0_Down

	LDA temp5
	CMP #34
     BCS .skipL081
.condpart47
	LDA temp5
	LDY temp6
 jsr pfread
	BNE .skip47then
.condpart48
 jmp .__Skip_Joy0_Down

.skip47then
.skipL081
.
 ; 

.L082 ;  temp4  =   ( player0x - 17 )  / 4

; complex statement detected
	LDA player0x
	SEC
	SBC #17
	lsr
	lsr
	STA temp4
.
 ; 

.L083 ;  if temp4  <  34 then if pfread ( temp4 , temp6 )  then goto __Skip_Joy0_Down

	LDA temp4
	CMP #34
     BCS .skipL083
.condpart49
	LDA temp4
	LDY temp6
 jsr pfread
	BNE .skip49then
.condpart50
 jmp .__Skip_Joy0_Down

.skip49then
.skipL083
.
 ; 

.L084 ;  temp3  =  temp5  -  1

	LDA temp5
	SEC
	SBC #1
	STA temp3
.
 ; 

.L085 ;  if temp3  <  34 then if pfread ( temp3 , temp6 )  then goto __Skip_Joy0_Down

	LDA temp3
	CMP #34
     BCS .skipL085
.condpart51
	LDA temp3
	LDY temp6
 jsr pfread
	BNE .skip51then
.condpart52
 jmp .__Skip_Joy0_Down

.skip51then
.skipL085
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L086 ;  player0y  =  player0y  +  1

	INC player0y
.
 ; 

.__Skip_Joy0_Down
 ; __Skip_Joy0_Down

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L087 ;  if !joy0left then goto __Skip_Joy0_Left

 bit SWCHA
	BVC .skipL087
.condpart53
 jmp .__Skip_Joy0_Left

.skipL087
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L088 ;  if player0x  <=  _P_Edge_Left then goto __Skip_Joy0_Left

	LDA #_P_Edge_Left
	CMP player0x
     BCC .skipL088
.condpart54
 jmp .__Skip_Joy0_Left

.skipL088
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L089 ;  temp5  =   ( player0y - 1 )  / 8

; complex statement detected
	LDA player0y
	SEC
	SBC #1
	lsr
	lsr
	lsr
	STA temp5
.
 ; 

.L090 ;  temp6  =   ( player0x - 18 )  / 4

; complex statement detected
	LDA player0x
	SEC
	SBC #18
	lsr
	lsr
	STA temp6
.
 ; 

.L091 ;  if temp6  <  34 then if pfread ( temp6 , temp5 )  then goto __Skip_Joy0_Left

	LDA temp6
	CMP #34
     BCS .skipL091
.condpart55
	LDA temp6
	LDY temp5
 jsr pfread
	BNE .skip55then
.condpart56
 jmp .__Skip_Joy0_Left

.skip55then
.skipL091
.
 ; 

.L092 ;  temp3  =   ( player0y - 4 )  / 8

; complex statement detected
	LDA player0y
	SEC
	SBC #4
	lsr
	lsr
	lsr
	STA temp3
.
 ; 

.L093 ;  if temp6  <  34 then if pfread ( temp6 , temp3 )  then goto __Skip_Joy0_Left

	LDA temp6
	CMP #34
     BCS .skipL093
.condpart57
	LDA temp6
	LDY temp3
 jsr pfread
	BNE .skip57then
.condpart58
 jmp .__Skip_Joy0_Left

.skip57then
.skipL093
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L094 ;  player0x  =  player0x  -  1

	DEC player0x
.
 ; 

.__Skip_Joy0_Left
 ; __Skip_Joy0_Left

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L095 ;  if !joy0right then goto __Skip_Joy0_Right

 bit SWCHA
	BPL .skipL095
.condpart59
 jmp .__Skip_Joy0_Right

.skipL095
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L096 ;  if player0x  >=  _P_Edge_Right then goto __Skip_Joy0_Right

	LDA player0x
	CMP #_P_Edge_Right
     BCC .skipL096
.condpart60
 jmp .__Skip_Joy0_Right

.skipL096
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L097 ;  temp5  =   ( player0y - 1 )  / 8

; complex statement detected
	LDA player0y
	SEC
	SBC #1
	lsr
	lsr
	lsr
	STA temp5
.
 ; 

.L098 ;  temp6  =   ( player0x - 9 )  / 4

; complex statement detected
	LDA player0x
	SEC
	SBC #9
	lsr
	lsr
	STA temp6
.
 ; 

.L099 ;  if temp6  <  34 then if pfread ( temp6 , temp5 )  then goto __Skip_Joy0_Right

	LDA temp6
	CMP #34
     BCS .skipL099
.condpart61
	LDA temp6
	LDY temp5
 jsr pfread
	BNE .skip61then
.condpart62
 jmp .__Skip_Joy0_Right

.skip61then
.skipL099
.
 ; 

.L0100 ;  temp3  =   ( player0y - 4 )  / 8

; complex statement detected
	LDA player0y
	SEC
	SBC #4
	lsr
	lsr
	lsr
	STA temp3
.
 ; 

.L0101 ;  if temp6  <  34 then if pfread ( temp6 , temp3 )  then goto __Skip_Joy0_Right

	LDA temp6
	CMP #34
     BCS .skipL0101
.condpart63
	LDA temp6
	LDY temp3
 jsr pfread
	BNE .skip63then
.condpart64
 jmp .__Skip_Joy0_Right

.skip63then
.skipL0101
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L0102 ;  player0x  =  player0x  +  1

	INC player0x
.
 ; 

.__Skip_Joy0_Right
 ; __Skip_Joy0_Right

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L0103 ;  if collision(player0,missile0)  &&  sugar{0}  &&  player0x  =  _data_sugar_x[0]  &&  player0y  =  _data_sugar_y[0] then sugar{0}  =  0

	bit 	CXM0P
	BVC .skipL0103
.condpart65
	LDA sugar
	LSR
	BCC .skip65then
.condpart66
	LDA player0x
	LDX #0
	CMP _data_sugar_x,x
     BNE .skip66then
.condpart67
	LDA player0y
	LDX #0
	CMP _data_sugar_y,x
     BNE .skip67then
.condpart68
	LDA sugar
	AND #254
	STA sugar
.skip67then
.skip66then
.skip65then
.skipL0103
.L0104 ;  if collision(player0,missile0)  &&  sugar{0}  &&  player0x  =  _data_sugar_x[1]  &&  player0y  =  _data_sugar_y[1] then sugar{1}  =  0

	bit 	CXM0P
	BVC .skipL0104
.condpart69
	LDA sugar
	LSR
	BCC .skip69then
.condpart70
	LDA player0x
	LDX #1
	CMP _data_sugar_x,x
     BNE .skip70then
.condpart71
	LDA player0y
	LDX #1
	CMP _data_sugar_y,x
     BNE .skip71then
.condpart72
	LDA sugar
	AND #253
	STA sugar
.skip71then
.skip70then
.skip69then
.skipL0104
.L0105 ;  if collision(player0,missile0)  &&  sugar{0}  &&  player0x  =  _data_sugar_x[2]  &&  player0y  =  _data_sugar_y[2] then sugar{2}  =  0

	bit 	CXM0P
	BVC .skipL0105
.condpart73
	LDA sugar
	LSR
	BCC .skip73then
.condpart74
	LDA player0x
	LDX #2
	CMP _data_sugar_x,x
     BNE .skip74then
.condpart75
	LDA player0y
	LDX #2
	CMP _data_sugar_y,x
     BNE .skip75then
.condpart76
	LDA sugar
	AND #251
	STA sugar
.skip75then
.skip74then
.skip73then
.skipL0105
.L0106 ;  if collision(player0,missile0)  &&  sugar{0}  &&  player0x  =  _data_sugar_x[3]  &&  player0y  =  _data_sugar_y[3] then sugar{3}  =  0

	bit 	CXM0P
	BVC .skipL0106
.condpart77
	LDA sugar
	LSR
	BCC .skip77then
.condpart78
	LDA player0x
	LDX #3
	CMP _data_sugar_x,x
     BNE .skip78then
.condpart79
	LDA player0y
	LDX #3
	CMP _data_sugar_y,x
     BNE .skip79then
.condpart80
	LDA sugar
	AND #247
	STA sugar
.skip79then
.skip78then
.skip77then
.skipL0106
.L0107 ;  if collision(player0,missile0)  &&  sugar{0}  &&  player0x  =  _data_sugar_x[4]  &&  player0y  =  _data_sugar_y[4] then sugar{4}  =  0

	bit 	CXM0P
	BVC .skipL0107
.condpart81
	LDA sugar
	LSR
	BCC .skip81then
.condpart82
	LDA player0x
	LDX #4
	CMP _data_sugar_x,x
     BNE .skip82then
.condpart83
	LDA player0y
	LDX #4
	CMP _data_sugar_y,x
     BNE .skip83then
.condpart84
	LDA sugar
	AND #239
	STA sugar
.skip83then
.skip82then
.skip81then
.skipL0107
.L0108 ;  if collision(player0,missile0)  &&  sugar{0}  &&  player0x  =  _data_sugar_x[5]  &&  player0y  =  _data_sugar_y[5] then sugar{5}  =  0

	bit 	CXM0P
	BVC .skipL0108
.condpart85
	LDA sugar
	LSR
	BCC .skip85then
.condpart86
	LDA player0x
	LDX #5
	CMP _data_sugar_x,x
     BNE .skip86then
.condpart87
	LDA player0y
	LDX #5
	CMP _data_sugar_y,x
     BNE .skip87then
.condpart88
	LDA sugar
	AND #223
	STA sugar
.skip87then
.skip86then
.skip85then
.skipL0108
.L0109 ;  if collision(player0,missile0)  &&  sugar{0}  &&  player0x  =  _data_sugar_x[6]  &&  player0y  =  _data_sugar_y[6] then sugar{6}  =  0

	bit 	CXM0P
	BVC .skipL0109
.condpart89
	LDA sugar
	LSR
	BCC .skip89then
.condpart90
	LDA player0x
	LDX #6
	CMP _data_sugar_x,x
     BNE .skip90then
.condpart91
	LDA player0y
	LDX #6
	CMP _data_sugar_y,x
     BNE .skip91then
.condpart92
	LDA sugar
	AND #191
	STA sugar
.skip91then
.skip90then
.skip89then
.skipL0109
.L0110 ;  if collision(player0,missile0)  &&  sugar{0}  &&  player0x  =  _data_sugar_x[7]  &&  player0y  =  _data_sugar_y[7] then sugar{7}  =  0

	bit 	CXM0P
	BVC .skipL0110
.condpart93
	LDA sugar
	LSR
	BCC .skip93then
.condpart94
	LDA player0x
	LDX #7
	CMP _data_sugar_x,x
     BNE .skip94then
.condpart95
	LDA player0y
	LDX #7
	CMP _data_sugar_y,x
     BNE .skip95then
.condpart96
	LDA sugar
	AND #127
	STA sugar
.skip95then
.skip94then
.skip93then
.skipL0110
.
 ; 

.
 ; 

.
 ; 

.
 ; 

.L0111 ;  if collision(player0,player1)  &&  frame_counter  =  0 then goto __Decrease_Health_Bar

	bit 	CXPPMM
	BPL .skipL0111
.condpart97
	LDA frame_counter
	CMP #0
     BNE .skip97then
.condpart98
 jmp .__Decrease_Health_Bar

.skip97then
.skipL0111
.L0112 ;  goto __Skip_Done

 jmp .__Skip_Done

.
 ; 

.__Decrease_Health_Bar
 ; __Decrease_Health_Bar

.L0113 ;  pfscore2  =  pfscore2 / 2

	LDA pfscore2
	lsr
	STA pfscore2
.L0114 ;  if score  >  0 then score = l - 1

	LDA #0
	CMP score
     BCS .skipL0114
.condpart99
	SED
	SEC
	LDA score+2
	SBC #$01
	STA score+2
	LDA score+1
	SBC #$00
	STA score+1
	LDA score
	SBC #$00
	STA score
	CLD
.skipL0114
.
 ; 

.
 ; 

.__Skip_Done
 ; __Skip_Done

.
 ; 

.L0115 ;  goto __skip_playfield

 jmp .__skip_playfield

.
 ; 

.
 ; 

.__select_level
 ; __select_level

.L0116 ;  if _level  =  1 then playfield:

	LDA _level
	CMP #1
     BNE .skipL0116
.condpart100
  ifconst pfres
	  ldx #(11>pfres)*(pfres*pfwidth-1)+(11<=pfres)*43
  else
	  ldx #((11*pfwidth-1)*((11*pfwidth-1)<47))+(47*((11*pfwidth-1)>=47))
  endif
	jmp pflabel1
PF_data1
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %11111111, %11111111
	if (pfwidth>2)
	.byte %11111111, %10111111
 endif
	.byte %11100000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00011000
 endif
	.byte %01000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00111100
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00011100, %00000000
	if (pfwidth>2)
	.byte %01111100, %00000000
 endif
	.byte %01010101, %00000000
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
pflabel1
	lda PF_data1,x
	sta playfield,x
	dex
	bpl pflabel1
.skipL0116
.
 ; 

.L0117 ;  if _level  =  11 then playfield:

	LDA _level
	CMP #11
     BNE .skipL0117
.condpart101
  ifconst pfres
	  ldx #(11>pfres)*(pfres*pfwidth-1)+(11<=pfres)*43
  else
	  ldx #((11*pfwidth-1)*((11*pfwidth-1)<47))+(47*((11*pfwidth-1)>=47))
  endif
	jmp pflabel2
PF_data2
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %11111111, %11111111
	if (pfwidth>2)
	.byte %11111111, %01111111
 endif
	.byte %11100011, %00000111
	if (pfwidth>2)
	.byte %00000000, %00011000
 endif
	.byte %00000001, %00000111
	if (pfwidth>2)
	.byte %00000000, %00111100
 endif
	.byte %00000000, %00000111
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
	.byte %00011100, %00000000
	if (pfwidth>2)
	.byte %01111000, %00000000
 endif
	.byte %01010101, %00000000
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
pflabel2
	lda PF_data2,x
	sta playfield,x
	dex
	bpl pflabel2
.skipL0117
.
 ; 

.L0118 ;  if _level  =  12 then playfield:

	LDA _level
	CMP #12
     BNE .skipL0118
.condpart102
  ifconst pfres
	  ldx #(11>pfres)*(pfres*pfwidth-1)+(11<=pfres)*43
  else
	  ldx #((11*pfwidth-1)*((11*pfwidth-1)<47))+(47*((11*pfwidth-1)>=47))
  endif
	jmp pflabel3
PF_data3
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %11111111, %11111111
	if (pfwidth>2)
	.byte %11111111, %01111111
 endif
	.byte %11100011, %00000111
	if (pfwidth>2)
	.byte %00000000, %00011000
 endif
	.byte %00000001, %00000111
	if (pfwidth>2)
	.byte %00000000, %00111100
 endif
	.byte %00000000, %00000111
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
	.byte %00011100, %00000000
	if (pfwidth>2)
	.byte %01111000, %00000000
 endif
	.byte %01010101, %00000000
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
pflabel3
	lda PF_data3,x
	sta playfield,x
	dex
	bpl pflabel3
.skipL0118
.
 ; 

.L0119 ;  if _level  =  2 then playfield:

	LDA _level
	CMP #2
     BNE .skipL0119
.condpart103
  ifconst pfres
	  ldx #(11>pfres)*(pfres*pfwidth-1)+(11<=pfres)*43
  else
	  ldx #((11*pfwidth-1)*((11*pfwidth-1)<47))+(47*((11*pfwidth-1)>=47))
  endif
	jmp pflabel4
PF_data4
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %11111111, %11111111
	if (pfwidth>2)
	.byte %11111111, %01111111
 endif
	.byte %11100011, %00000111
	if (pfwidth>2)
	.byte %00000000, %00011000
 endif
	.byte %00000001, %00000111
	if (pfwidth>2)
	.byte %00000000, %00111100
 endif
	.byte %00000000, %00000111
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
	.byte %00011100, %00000000
	if (pfwidth>2)
	.byte %01111000, %00000000
 endif
	.byte %01010101, %00000000
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
pflabel4
	lda PF_data4,x
	sta playfield,x
	dex
	bpl pflabel4
.skipL0119
.
 ; 

.L0120 ;  if _level  =  21 then playfield:

	LDA _level
	CMP #21
     BNE .skipL0120
.condpart104
  ifconst pfres
	  ldx #(11>pfres)*(pfres*pfwidth-1)+(11<=pfres)*43
  else
	  ldx #((11*pfwidth-1)*((11*pfwidth-1)<47))+(47*((11*pfwidth-1)>=47))
  endif
	jmp pflabel5
PF_data5
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %11111111, %11111111
	if (pfwidth>2)
	.byte %11111111, %01111111
 endif
	.byte %11100011, %00000111
	if (pfwidth>2)
	.byte %00000000, %00011000
 endif
	.byte %00000001, %00000111
	if (pfwidth>2)
	.byte %00000000, %00111100
 endif
	.byte %00000000, %00000111
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
	.byte %00011100, %00000000
	if (pfwidth>2)
	.byte %01111000, %00000000
 endif
	.byte %01010101, %00000000
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
pflabel5
	lda PF_data5,x
	sta playfield,x
	dex
	bpl pflabel5
.skipL0120
.
 ; 

.L0121 ;  if _level  =  22 then playfield:

	LDA _level
	CMP #22
     BNE .skipL0121
.condpart105
  ifconst pfres
	  ldx #(11>pfres)*(pfres*pfwidth-1)+(11<=pfres)*43
  else
	  ldx #((11*pfwidth-1)*((11*pfwidth-1)<47))+(47*((11*pfwidth-1)>=47))
  endif
	jmp pflabel6
PF_data6
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %11111111, %11111111
	if (pfwidth>2)
	.byte %11111111, %01111111
 endif
	.byte %11100011, %00000111
	if (pfwidth>2)
	.byte %00000000, %00011000
 endif
	.byte %00000001, %00000111
	if (pfwidth>2)
	.byte %00000000, %00111100
 endif
	.byte %00000000, %00000111
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
	.byte %00011100, %00000000
	if (pfwidth>2)
	.byte %01111000, %00000000
 endif
	.byte %01010101, %00000000
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
pflabel6
	lda PF_data6,x
	sta playfield,x
	dex
	bpl pflabel6
.skipL0121
.
 ; 

.L0122 ;  if _level  =  3 then playfield:

	LDA _level
	CMP #3
     BNE .skipL0122
.condpart106
  ifconst pfres
	  ldx #(11>pfres)*(pfres*pfwidth-1)+(11<=pfres)*43
  else
	  ldx #((11*pfwidth-1)*((11*pfwidth-1)<47))+(47*((11*pfwidth-1)>=47))
  endif
	jmp pflabel7
PF_data7
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %11111111, %11111111
	if (pfwidth>2)
	.byte %11111111, %01111111
 endif
	.byte %11100011, %00000111
	if (pfwidth>2)
	.byte %00000000, %00011000
 endif
	.byte %00000001, %00000111
	if (pfwidth>2)
	.byte %00000000, %00111100
 endif
	.byte %00000000, %00000111
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
	.byte %00011100, %00000000
	if (pfwidth>2)
	.byte %01111000, %00000000
 endif
	.byte %01010101, %00000000
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
pflabel7
	lda PF_data7,x
	sta playfield,x
	dex
	bpl pflabel7
.skipL0122
.
 ; 

.L0123 ;  if _level  =  31 then playfield:

	LDA _level
	CMP #31
     BNE .skipL0123
.condpart107
  ifconst pfres
	  ldx #(11>pfres)*(pfres*pfwidth-1)+(11<=pfres)*43
  else
	  ldx #((11*pfwidth-1)*((11*pfwidth-1)<47))+(47*((11*pfwidth-1)>=47))
  endif
	jmp pflabel8
PF_data8
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %11111111, %11111111
	if (pfwidth>2)
	.byte %11111111, %01111111
 endif
	.byte %11100011, %00000111
	if (pfwidth>2)
	.byte %00000000, %00011000
 endif
	.byte %00000001, %00000111
	if (pfwidth>2)
	.byte %00000000, %00111100
 endif
	.byte %00000000, %00000111
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
	.byte %00011100, %00000000
	if (pfwidth>2)
	.byte %01111000, %00000000
 endif
	.byte %01010101, %00000000
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
pflabel8
	lda PF_data8,x
	sta playfield,x
	dex
	bpl pflabel8
.skipL0123
.
 ; 

.L0124 ;  if _level  =  32 then playfield:

	LDA _level
	CMP #32
     BNE .skipL0124
.condpart108
  ifconst pfres
	  ldx #(11>pfres)*(pfres*pfwidth-1)+(11<=pfres)*43
  else
	  ldx #((11*pfwidth-1)*((11*pfwidth-1)<47))+(47*((11*pfwidth-1)>=47))
  endif
	jmp pflabel9
PF_data9
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %11111111, %11111111
	if (pfwidth>2)
	.byte %11111111, %01111111
 endif
	.byte %11100011, %00000111
	if (pfwidth>2)
	.byte %00000000, %00011000
 endif
	.byte %00000001, %00000111
	if (pfwidth>2)
	.byte %00000000, %00111100
 endif
	.byte %00000000, %00000111
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
	.byte %00011100, %00000000
	if (pfwidth>2)
	.byte %01111000, %00000000
 endif
	.byte %01010101, %00000000
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
pflabel9
	lda PF_data9,x
	sta playfield,x
	dex
	bpl pflabel9
.skipL0124
.
 ; 

.L0125 ;  if _level  =  4 then playfield:

	LDA _level
	CMP #4
     BNE .skipL0125
.condpart109
  ifconst pfres
	  ldx #(11>pfres)*(pfres*pfwidth-1)+(11<=pfres)*43
  else
	  ldx #((11*pfwidth-1)*((11*pfwidth-1)<47))+(47*((11*pfwidth-1)>=47))
  endif
	jmp pflabel10
PF_data10
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %11111111, %11111111
	if (pfwidth>2)
	.byte %11111111, %01111111
 endif
	.byte %11100011, %00000111
	if (pfwidth>2)
	.byte %00000000, %00011000
 endif
	.byte %00000001, %00000111
	if (pfwidth>2)
	.byte %00000000, %00111100
 endif
	.byte %00000000, %00000111
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
	.byte %00011100, %00000000
	if (pfwidth>2)
	.byte %01111000, %00000000
 endif
	.byte %01010101, %00000000
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
pflabel10
	lda PF_data10,x
	sta playfield,x
	dex
	bpl pflabel10
.skipL0125
.
 ; 

.L0126 ;  if _level  =  41 then playfield:

	LDA _level
	CMP #41
     BNE .skipL0126
.condpart110
  ifconst pfres
	  ldx #(11>pfres)*(pfres*pfwidth-1)+(11<=pfres)*43
  else
	  ldx #((11*pfwidth-1)*((11*pfwidth-1)<47))+(47*((11*pfwidth-1)>=47))
  endif
	jmp pflabel11
PF_data11
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %11111111, %11111111
	if (pfwidth>2)
	.byte %11111111, %01111111
 endif
	.byte %11100011, %00000111
	if (pfwidth>2)
	.byte %00000000, %00011000
 endif
	.byte %00000001, %00000111
	if (pfwidth>2)
	.byte %00000000, %00111100
 endif
	.byte %00000000, %00000111
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
	.byte %00011100, %00000000
	if (pfwidth>2)
	.byte %01111000, %00000000
 endif
	.byte %01010101, %00000000
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
pflabel11
	lda PF_data11,x
	sta playfield,x
	dex
	bpl pflabel11
.skipL0126
.
 ; 

.L0127 ;  if _level  =  42 then playfield:

	LDA _level
	CMP #42
     BNE .skipL0127
.condpart111
  ifconst pfres
	  ldx #(11>pfres)*(pfres*pfwidth-1)+(11<=pfres)*43
  else
	  ldx #((11*pfwidth-1)*((11*pfwidth-1)<47))+(47*((11*pfwidth-1)>=47))
  endif
	jmp pflabel12
PF_data12
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %00000000, %00000000
	if (pfwidth>2)
	.byte %00000000, %00000000
 endif
	.byte %11111111, %11111111
	if (pfwidth>2)
	.byte %11111111, %01111111
 endif
	.byte %11100011, %00000111
	if (pfwidth>2)
	.byte %00000000, %00011000
 endif
	.byte %00000001, %00000111
	if (pfwidth>2)
	.byte %00000000, %00111100
 endif
	.byte %00000000, %00000111
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
	.byte %00011100, %00000000
	if (pfwidth>2)
	.byte %01111000, %00000000
 endif
	.byte %01010101, %00000000
	if (pfwidth>2)
	.byte %01110000, %00000000
 endif
pflabel12
	lda PF_data12,x
	sta playfield,x
	dex
	bpl pflabel12
.skipL0127
.
 ; 

.L0128 ;  if _level  >  42 then _level  =  0  :  goto __startGame

	LDA #42
	CMP _level
     BCS .skipL0128
.condpart112
	LDA #0
	STA _level
 jmp .__startGame

.skipL0128
.
 ; 

.__skip_playfield
 ; __skip_playfield

.L0129 ;  COLUP0  =  _P0_color  :  COLUP1  =  _P1_color

	LDA #_P0_color
	STA COLUP0
	LDA #_P1_color
	STA COLUP1
.L0130 ;  COLUBK  =  0

	LDA #0
	STA COLUBK
.
 ; 

.L0131 ;  drawscreen

 jsr drawscreen
.
 ; 

.L0132 ;  goto __main_loop

 jmp .__main_loop

.
 ; 

.
 ; 

.L0133 ;  data _data_sugar_x

	JMP .skipL0133
_data_sugar_x
	.byte    20, 40, 60, 50, 90, 30, 120, 80  ; Coordinate x degli zuccherini

.skipL0133
.L0134 ;  data _data_sugar_y

	JMP .skipL0134
_data_sugar_y
	.byte    10, 20, 30, 40, 50, 60, 70, 80  ; Coordinate y degli zuccherini

.skipL0134
.
 ; 

 ifconst pfres
 if (<*) > (254-pfres*pfwidth)
	align 256
	endif
 if (<*) < (136-pfres*pfwidth)
	repeat ((136-pfres*pfwidth)-(<*))
	.byte 0
	repend
	endif
 else
 if (<*) > 206
	align 256
	endif
 if (<*) < 88
	repeat (88-(<*))
	.byte 0
	repend
	endif
 endif
pfcolorlabel13
 .byte  $24, $26, $26,0
 .byte  $26, $28, $28,0
 .byte  $28, $D4, $D4,0
 .byte  $2A, $26, $26,0
 .byte  $22, $D4, $D4,0
 .byte  $24, $05, $0,0
 .byte  $26, $9E, $0,0
 .byte  $28, $0E, $0,0
 .byte  $2A, $24, $0,0
 .byte  $2B, $26, $0,0
 if (<*) > (<(*+3))
	repeat ($100-<*)
	.byte 0
	repend
	endif
player20then_0
	.byte    %00100100
	.byte    %00111100
	.byte    %11111111
	.byte    %01111110
 if (<*) > (<(*+3))
	repeat ($100-<*)
	.byte 0
	repend
	endif
player21then_0
	.byte    %01100110
	.byte    %00111100
	.byte    %11111111
	.byte    %01111110
 if (<*) > (<(*+3))
	repeat ($100-<*)
	.byte 0
	repend
	endif
player23then_1
	.byte    %01111110
	.byte    %10000001
	.byte    %10011001
	.byte    %01100110
 if (<*) > (<(*+3))
	repeat ($100-<*)
	.byte 0
	repend
	endif
player25then_1
	.byte    %00000000
	.byte    %11111111
	.byte    %11111111
	.byte    %00000000
 if ECHOFIRST
       echo "    ",[(scoretable - *)]d , "bytes of ROM space left")
 endif 
ECHOFIRST = 1
 
 
 
; Provided under the CC0 license. See the included LICENSE.txt for details.

; feel free to modify the score graphics - just keep each digit 8 high
; and keep the conditional compilation stuff intact
 ifconst ROM2k
   ORG $F7AC-8
 else
   ifconst bankswitch
     if bankswitch == 8
       ORG $2F94-bscode_length
       RORG $FF94-bscode_length
     endif
     if bankswitch == 16
       ORG $4F94-bscode_length
       RORG $FF94-bscode_length
     endif
     if bankswitch == 32
       ORG $8F94-bscode_length
       RORG $FF94-bscode_length
     endif
     if bankswitch == 64
       ORG  $10F80-bscode_length
       RORG $1FF80-bscode_length
     endif
   else
     ORG $FF9C
   endif
 endif

; font equates
.21stcentury = 1
alarmclock = 2     
handwritten = 3    
interrupted = 4    
retroputer = 5    
whimsey = 6
tiny = 7
hex = 8

 ifconst font
   if font == hex
     ORG . - 48
   endif
 endif

scoretable

 ifconst font
  if font == .21stcentury
    include "score_graphics.asm.21stcentury"
  endif
  if font == alarmclock
    include "score_graphics.asm.alarmclock"
  endif
  if font == handwritten
    include "score_graphics.asm.handwritten"
  endif
  if font == interrupted
    include "score_graphics.asm.interrupted"
  endif
  if font == retroputer
    include "score_graphics.asm.retroputer"
  endif
  if font == whimsey
    include "score_graphics.asm.whimsey"
  endif
  if font == tiny
    include "score_graphics.asm.tiny"
  endif
  if font == hex
    include "score_graphics.asm.hex"
  endif
 else ; default font

       .byte %00111100
       .byte %01100110
       .byte %01100110
       .byte %01100110
       .byte %01100110
       .byte %01100110
       .byte %01100110
       .byte %00111100

       .byte %01111110
       .byte %00011000
       .byte %00011000
       .byte %00011000
       .byte %00011000
       .byte %00111000
       .byte %00011000
       .byte %00001000

       .byte %01111110
       .byte %01100000
       .byte %01100000
       .byte %00111100
       .byte %00000110
       .byte %00000110
       .byte %01000110
       .byte %00111100

       .byte %00111100
       .byte %01000110
       .byte %00000110
       .byte %00000110
       .byte %00011100
       .byte %00000110
       .byte %01000110
       .byte %00111100

       .byte %00001100
       .byte %00001100
       .byte %01111110
       .byte %01001100
       .byte %01001100
       .byte %00101100
       .byte %00011100
       .byte %00001100

       .byte %00111100
       .byte %01000110
       .byte %00000110
       .byte %00000110
       .byte %00111100
       .byte %01100000
       .byte %01100000
       .byte %01111110

       .byte %00111100
       .byte %01100110
       .byte %01100110
       .byte %01100110
       .byte %01111100
       .byte %01100000
       .byte %01100010
       .byte %00111100

       .byte %00110000
       .byte %00110000
       .byte %00110000
       .byte %00011000
       .byte %00001100
       .byte %00000110
       .byte %01000010
       .byte %00111110

       .byte %00111100
       .byte %01100110
       .byte %01100110
       .byte %01100110
       .byte %00111100
       .byte %01100110
       .byte %01100110
       .byte %00111100

       .byte %00111100
       .byte %01000110
       .byte %00000110
       .byte %00111110
       .byte %01100110
       .byte %01100110
       .byte %01100110
       .byte %00111100 

       ifnconst DPC_kernel_options
 
         .byte %00000000
         .byte %00000000
         .byte %00000000
         .byte %00000000
         .byte %00000000
         .byte %00000000
         .byte %00000000
         .byte %00000000 

       endif

 endif

 ifconst ROM2k
   ORG $F7FC
 else
   ifconst bankswitch
     if bankswitch == 8
       ORG $2FF4-bscode_length
       RORG $FFF4-bscode_length
     endif
     if bankswitch == 16
       ORG $4FF4-bscode_length
       RORG $FFF4-bscode_length
     endif
     if bankswitch == 32
       ORG $8FF4-bscode_length
       RORG $FFF4-bscode_length
     endif
     if bankswitch == 64
       ORG  $10FE0-bscode_length
       RORG $1FFE0-bscode_length
     endif
   else
     ORG $FFFC
   endif
 endif
; Provided under the CC0 license. See the included LICENSE.txt for details.

 ifconst bankswitch
   if bankswitch == 8
     ORG $2FFC
     RORG $FFFC
   endif
   if bankswitch == 16
     ORG $4FFC
     RORG $FFFC
   endif
   if bankswitch == 32
     ORG $8FFC
     RORG $FFFC
   endif
   if bankswitch == 64
     ORG  $10FF0
     RORG $1FFF0
     lda $ffe0 ; we use wasted space to assist stella with EF format auto-detection
     ORG  $10FF8
     RORG $1FFF8
     ifconst superchip 
       .byte "E","F","S","C"
     else
       .byte "E","F","E","F"
     endif
     ORG  $10FFC
     RORG $1FFFC
   endif
 else
   ifconst ROM2k
     ORG $F7FC
   else
     ORG $FFFC
   endif
 endif
 .word (start & $ffff)
 .word (start & $ffff)
