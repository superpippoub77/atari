extends RefCounted
## =====================================================================
##  SNACK 'N' ROLL - TABELLE DATI
## ---------------------------------------------------------------------
##  Porting 1:1 dei blocchi "data" e delle costanti di Snack and Roll.bas
##  (batari Basic, Atari 2600). I valori sono IDENTICI a quelli del BAS:
##  se modifichi un livello nel BAS, copia la riga qui e il livello
##  Godot cambia di conseguenza (e viceversa).
##
##  Le tabelle marcate "EXT_" esistono solo nella versione Godot
##  (trabocchetti aggiuntivi). Non hanno un equivalente nel BAS e
##  possono essere ignorate in un porting all'indietro.
## =====================================================================

# ---------------------------------------------------------------------
# COSTANTI KERNEL (BAS: const ...)
# ---------------------------------------------------------------------
const P0_COLOR := 0x2A        # _P0_color  - biscotto (giallo PAL)
const P1_COLOR := 0x48        # _P1_color  - bocca (rosso PAL)
## BAS: frame_limit = 54 (PAL, 50 Hz). In Godot la fisica gira a 60 Hz,
## quindi usiamo 59 per avere ancora "un secondo" = un secondo reale.
const FRAME_LIMIT := 59
const MAX_LEVEL := 5          # BAS: if _level > 5 then goto __game_start
const START_SPEED := 8        # BAS: _speed = 8
const HIT_COOLDOWN_HURT := 90     # BAS: __decrease_health_bar -> _hitCooldown = 90
const HIT_COOLDOWN_GOLDEN := 120  # BAS: zuccherino 0 -> _hitCooldown = 120
const PFSCORE1_FULL := 0xFF   # barra del tempo (8 tacche)
const PFSCORE2_FULL := 0xAA   # %10101010 -> 4 vite (si divide per 4)
const PUSH_COL_START := 13    # BAS: _pushCol = 13
const PUSH_COL_MAX := 24      # BAS: if _pushCol>24 then _pushCol=24

## Cadenza musica in frame (BAS: !(_frame_counter&15) / !(_frame_counter&3))
const MUSIC_STEP_TITLE := 16
const MUSIC_STEP_GAME := 4

# ---------------------------------------------------------------------
# GEOMETRIA DEL MONDO (solo Godot)
# ---------------------------------------------------------------------
## Ogni livello del BAS (1 schermata 32x11 di playfield) diventa un
## "chunk" orizzontale di 128x17 tile da 16 px. I 5 chunk sono messi uno
## dopo l'altro: il mondo si attraversa tutto scorrendo verso destra.
const TILE := 16
const CHUNK_W := 128                 # tile per livello
const CHUNK_PX := CHUNK_W * TILE     # 2048 px
const SECTION_W := 32                # 4 sezioni orizzontali per livello
const VIEW_W := 480
const VIEW_H := 270
const UPPER_BASE := 9   # riga del "piano di lavoro" (divisor, riga 5 del playfield)
const LOWER_BASE := 15  # riga del pavimento

# ---------------------------------------------------------------------
# data objects  (8 byte per livello)
# ---------------------------------------------------------------------
## Colonne: 0.TAZZE 1.(ex-COLTELLI, inutilizzato) 2.CIOCCOLATO 3.GOCCE
##          4.LAMPADE 5.TAVOLI+SEDIA 6.PIANO 7.ballx
## Per le colonne 0-5 ogni bit e' una sezione del playfield:
##     b0 | b1 | b2 | b3      (parte alta, sopra il piano di lavoro)
##    ----|----|----|----
##     b4 | b5 | b6 | b7      (parte bassa, sul pavimento)
## Colonna 6 (PIANO): bit 0..6 = 7 segmenti del piano di lavoro centrale.
## Colonna 7 (ballx): coordinata X del sacchetto finale.
const OBJ_CUPS := 0
const OBJ_KNIVES := 1
const OBJ_CHOCOLATE := 2
const OBJ_DROPS := 3
const OBJ_LAMPS := 4
const OBJ_TABLES := 5
const OBJ_DIVISOR := 6
const OBJ_BALLX := 7

const OBJECTS := [
	[0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00001010, 0b01111010, 0b00100010, 18],
	[0b01111111, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00101011, 136],
	[0b00000000, 0b00000000, 0b00110111, 0b00000000, 0b00000000, 0b00000000, 0b00001011, 18],
	[0b00000000, 0b00000000, 0b10101010, 0b01010101, 0b00000000, 0b00000000, 0b00101011, 136],
	[0b11000000, 0b00000000, 0b00000011, 0b00001100, 0b00010000, 0b00110000, 0b00101011, 18],
]

# ---------------------------------------------------------------------
# data sugar - posizioni fisse degli zuccherini (8 per livello)
# ---------------------------------------------------------------------
## Griglia 8 colonne x 8 righe: indice = riga*8 + colonna.
## Zuccherino 0 = "dorato" (congela le bocche, _hitCooldown = 120)
## Zuccherino 1 = "chiave" (_hasKey = 1, serve dal livello 4)
const SUGAR := [
	0, 10, 18, 24, 34, 42, 48, 56,
	0, 8, 16, 24, 34, 40, 50, 58,
	7, 8, 17, 24, 33, 40, 48, 61,
	1, 9, 18, 30, 39, 40, 48, 57,
	0, 8, 18, 31, 38, 40, 48, 56,
]

const BITTABLE := [1, 2, 4, 8, 16, 32, 64, 128]
const MOUTH_COLORS := [0x48, 0x6A]

const JINGLE := [30, 28, 26, 24, 22, 20, 18, 16, 18, 20, 22, 24, 26, 28, 30, 28, 26, 24, 22, 20]
const MELODY := [16, 18, 16, 20, 18, 20, 22, 20, 18, 16, 18, 20, 22, 20, 18, 16, 18, 16, 20, 22]

# ---------------------------------------------------------------------
# PLAYFIELD DEL TITOLO (BAS: __draw_title) + pfcolors
# ---------------------------------------------------------------------
const TITLE_ROWS := [
	"................................",
	"...XXX..X..X...XX....XX...X..X..",
	"..X.....XX.X..X..X..X..X..X.X...",
	"...XX...X.XX..XXXX..X.....XX....",
	".....X..X..X..X..X..X..X..X.X...",
	"..XXX...X..X..X..X...XX...X..X..",
	"................................",
	"X......X.X.X..XX..X.X...X...XXX.",
	"..X.XX...XX..X..X.X.X...XX.XX...",
	"..XX.X...X...X..X.X.X...X.X.XX..",
	"..X..X...X....XX..X.X...X...X...",
]
const TITLE_COLORS := [0x20, 0x21, 0x22, 0x23, 0x24, 0x20, 0x9E, 0x28, 0x26, 0x24, 0x22]

# ---------------------------------------------------------------------
# EXT_ - TRABOCCHETTI AGGIUNTIVI (solo Godot)
# ---------------------------------------------------------------------
## Pozze di cioccolata bollente nel pavimento: [colonna_tile, larghezza]
const EXT_PITS := [
	[],
	[[61, 3]],
	[[29, 3], [93, 3]],
	[[29, 3], [61, 3], [93, 3]],
	[[29, 3], [61, 3], [93, 3]],
]
## Coltelli a scatto (riprende la colonna "COLTELLI" rimasta vuota nel
## BAS): stessa codifica a bit delle sezioni. Solo sezioni basse (b4-b7).
const EXT_KNIVES := [0b00000000, 0b00000000, 0b01000000, 0b10100000, 0b01010000]
## Cialde che si sbriciolano dopo che ci sei salito sopra
const EXT_CRUMBLE := [false, false, true, true, true]

## Velocita' delle bocche (px/s) in funzione di _speed del BAS.
## Nel BAS la bocca fa 1 passo ogni _speed frame (8,6,4,2); con _speed=0
## il passo diventa rarissimo (bug del BAS): qui lo trattiamo come il piu'
## veloce.
const MOUTH_SPEED_BY_SPEED := {8: 24.0, 6: 32.0, 4: 42.0, 2: 54.0, 0: 62.0}

## Temi grafici dei livelli (solo Godot). Il BAS usa pfcolors azzurri
## per i livelli 1-2 e marroni dal 3 in poi: qui ne seguiamo lo spirito.
const THEMES := [
	{"name": "CUCINA", "wall": Color(0.62, 0.83, 0.90), "wall2": Color(0.80, 0.93, 0.97), "grout": Color(0.47, 0.68, 0.78),
	 "floor": Color(0.91, 0.87, 0.78), "floor2": Color(0.72, 0.64, 0.50), "wood": Color(0.66, 0.44, 0.24), "wood2": Color(0.45, 0.28, 0.13),
	 "counter": Color(0.95, 0.94, 0.90), "cup": Color(0.97, 0.97, 0.98), "cup2": Color(0.85, 0.25, 0.30), "sky": Color(0.50, 0.78, 1.0), "night": false},
	{"name": "DISPENSA", "wall": Color(0.62, 0.86, 0.74), "wall2": Color(0.82, 0.95, 0.87), "grout": Color(0.44, 0.68, 0.56),
	 "floor": Color(0.90, 0.84, 0.72), "floor2": Color(0.66, 0.56, 0.42), "wood": Color(0.70, 0.47, 0.26), "wood2": Color(0.48, 0.30, 0.14),
	 "counter": Color(0.93, 0.92, 0.86), "cup": Color(0.98, 0.93, 0.80), "cup2": Color(0.24, 0.46, 0.80), "sky": Color(1.0, 0.70, 0.45), "night": false},
	{"name": "PASTICCERIA", "wall": Color(0.88, 0.69, 0.48), "wall2": Color(0.95, 0.82, 0.62), "grout": Color(0.70, 0.50, 0.32),
	 "floor": Color(0.62, 0.40, 0.24), "floor2": Color(0.45, 0.27, 0.14), "wood": Color(0.55, 0.33, 0.16), "wood2": Color(0.36, 0.20, 0.09),
	 "counter": Color(0.98, 0.90, 0.80), "cup": Color(1.0, 0.85, 0.90), "cup2": Color(0.60, 0.25, 0.45), "sky": Color(0.95, 0.50, 0.40), "night": false},
	{"name": "FABBRICA DEL CIOCCOLATO", "wall": Color(0.42, 0.27, 0.19), "wall2": Color(0.52, 0.35, 0.24), "grout": Color(0.30, 0.18, 0.12),
	 "floor": Color(0.36, 0.22, 0.14), "floor2": Color(0.25, 0.14, 0.08), "wood": Color(0.62, 0.40, 0.20), "wood2": Color(0.40, 0.24, 0.10),
	 "counter": Color(0.85, 0.75, 0.62), "cup": Color(0.92, 0.88, 0.80), "cup2": Color(0.80, 0.55, 0.15), "sky": Color(0.35, 0.25, 0.55), "night": true},
	{"name": "CUCINA DI MEZZANOTTE", "wall": Color(0.24, 0.20, 0.38), "wall2": Color(0.31, 0.27, 0.48), "grout": Color(0.16, 0.13, 0.27),
	 "floor": Color(0.30, 0.26, 0.40), "floor2": Color(0.20, 0.17, 0.29), "wood": Color(0.45, 0.30, 0.22), "wood2": Color(0.28, 0.18, 0.12),
	 "counter": Color(0.75, 0.74, 0.85), "cup": Color(0.85, 0.85, 0.95), "cup2": Color(0.45, 0.80, 0.70), "sky": Color(0.08, 0.08, 0.22), "night": true},
]


# ---------------------------------------------------------------------
# FUNZIONI DI SUPPORTO (riproducono la logica del BAS)
# ---------------------------------------------------------------------

## BAS: __handle_level_select -> _speed = 8-(_level-1)*2 se _level<5, altrimenti 0
static func speed_for_level(level: int) -> int:
	if level < 5:
		return 8 - (level - 1) * 2
	return 0


static func mouth_speed(speed: int) -> float:
	return MOUTH_SPEED_BY_SPEED.get(speed, 62.0)


## BAS: temp1 = 1 : if _level > 3 then temp1 = 2   (numero di bocche)
static func mouth_count(level: int) -> int:
	return 2 if level > 3 else 1


## BAS: NUSIZ1=$05 (bocca a doppia larghezza) se _level > 3
static func mouth_double(level: int) -> bool:
	return level > 3


## BAS: la bocca 0 viene bloccata dal playfield solo se _level < 5
static func mouth_is_ghost(level: int, index: int) -> bool:
	return index != 0 or level >= 5


static func objects_for(level: int) -> Array:
	return OBJECTS[clampi(level - 1, 0, OBJECTS.size() - 1)]


static func sugar_for(level: int, index: int) -> int:
	return SUGAR[(level - 1) * 8 + index]


## Numero di bit accesi (tacche della barra tempo / vite)
static func bit_count(v: int) -> int:
	var n := 0
	while v > 0:
		n += v & 1
		v >>= 1
	return n


## Approssimazione della palette PAL dell'Atari 2600 ($HL: H = tinta, L = luminosita')
static func pal(v: int) -> Color:
	var hues := [
		Color(0.5, 0.5, 0.5), Color(0.5, 0.5, 0.5), Color(0.85, 0.62, 0.12), Color(0.55, 0.62, 0.05),
		Color(0.85, 0.30, 0.22), Color(0.20, 0.62, 0.20), Color(0.85, 0.25, 0.50), Color(0.10, 0.62, 0.42),
		Color(0.62, 0.25, 0.75), Color(0.12, 0.55, 0.65), Color(0.48, 0.30, 0.85), Color(0.15, 0.45, 0.85),
		Color(0.30, 0.34, 0.90), Color(0.15, 0.40, 0.88), Color(0.5, 0.5, 0.5), Color(0.5, 0.5, 0.5),
	]
	var base: Color = hues[(v >> 4) & 0x0F]
	var lum := float(v & 0x0E) / 14.0
	var c := base * (0.25 + 0.95 * lum)
	c = c.lerp(Color.WHITE, maxf(0.0, lum - 0.55) * 0.7)
	c.a = 1.0
	return c


static func theme(level: int) -> Dictionary:
	return THEMES[clampi(level - 1, 0, THEMES.size() - 1)]
