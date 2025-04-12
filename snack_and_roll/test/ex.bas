   COLUBK = 132 
   COLUPF = 30

   playfield:
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
end

__Main_Loop

   PF2 = %10000000

   drawscreen

   goto __Main_Loop