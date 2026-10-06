extends RefCounted
## =====================================================================
##  COSTRUTTORE DEI LIVELLI  (BAS: "PLAYFIELD DINAMICO" / __loop_objects)
## ---------------------------------------------------------------------
##  Il BAS legge la riga di "objects" del livello e, per ogni bit acceso,
##  disegna l'oggetto nella sezione corrispondente (macro cup_knife,
##  chocolate, choco_drops, lamp, table, divisor).
##  Qui facciamo lo stesso, ma ogni livello diventa un tratto orizzontale
##  di 128 tile (4 sezioni da 32) del mondo a scorrimento:
##
##   riga 0          soffitto (pensili)
##   righe 1..8      parte ALTA  (bit 0-3) - sopra il piano di lavoro
##   riga 9          PIANO DI LAVORO (colonna 6, 7 segmenti)
##   righe 10..14    parte BASSA (bit 4-7)
##   righe 15..16    pavimento (con eventuali pozze EXT_PITS)
##   colonna 127     cancello verso il livello successivo
## =====================================================================

const D := preload("res://scripts/snack_data.gd")
const Block := preload("res://scripts/block.gd")
const SugarScript := preload("res://scripts/sugar.gd")
const BagScript := preload("res://scripts/bag.gd")
const H := preload("res://scripts/hazards.gd")

const T := D.TILE

var world: Node2D
var main
var level := 1
var ox := 0.0
var first := false
var th: Dictionary
var grid := {}
var info := {}


func _init(p_world: Node2D, p_main, p_level: int, p_origin: float, p_first: bool) -> void:
	world = p_world
	main = p_main
	level = p_level
	ox = p_origin
	first = p_first
	th = D.theme(level)


func build() -> Dictionary:
	var obj: Array = D.objects_for(level)
	var li := level - 1
	info = {
		"level": level, "origin": ox, "sugars": [], "lamps": [],
		"gate": null, "bag": null, "push": null,
		"checkpoint": Vector2(ox + 3.5 * T, 14.0 * T),
	}

	# --- struttura fissa: soffitto, pavimento, muro iniziale ---
	_rect(0, 0, D.CHUNK_W, 1, "ceiling")
	if first:
		_rect(-1, 0, 1, 17, "wall")
	_build_ground(D.EXT_PITS[li])

	# --- PIANO (colonna 6): BAS macro divisor, 7 segmenti ---
	var divisor: int = obj[D.OBJ_DIVISOR]
	for k in 7:
		if divisor & (1 << k):
			_rect(k * 18 + 1, D.UPPER_BASE, 16, 1, "shelf", {"one_way": true, "shape": Rect2(0, 0, 16 * T, 8)})

	# --- oggetti per sezione (BAS: _current_bit_object = 1,2,4..128) ---
	for bit_i in 8:
		var bit := 1 << bit_i
		var sx := (bit_i % 4) * D.SECTION_W
		var upper := bit_i < 4
		var base := D.UPPER_BASE if upper else D.LOWER_BASE
		var has_struct := false
		if obj[D.OBJ_CUPS] & bit:
			_cup(sx + 8, base)
			has_struct = true
		if obj[D.OBJ_CHOCOLATE] & bit:
			_chocolate(sx, base)
			has_struct = true
		if obj[D.OBJ_TABLES] & bit:
			_table(sx + 17, base)
			has_struct = true
		if obj[D.OBJ_DROPS] & bit:
			_drops(sx + 12, upper)
		if obj[D.OBJ_LAMPS] & bit:
			_lamp(sx + 4, upper)
		if not upper and (D.EXT_KNIVES[li] & bit):
			_knife(sx + 27)
		if upper and has_struct:
			# mensola sotto gli oggetti della parte alta dove manca il piano
			_platform_run(sx + 5, sx + 26, D.UPPER_BASE, "mensola", false)

	# --- muro spingibile (BAS: if _level<5 then goto __skip_pushwall) ---
	if level >= 5:
		_push_block()

	# --- zuccherini (data sugar) ---
	for i in 8:
		_sugar(i, D.sugar_for(level, i))

	# --- sacchetto finale (colonna 7 = ballx) ---
	_bag(obj[D.OBJ_BALLX])

	# --- cancello verso il livello successivo ---
	var g := H.Gate.new()
	g.position = Vector2(ox + (D.CHUNK_W - 1) * T, T)
	g.h = 14.0 * T
	world.add_child(g)
	info.gate = g
	return info


# ---------------------------------------------------------------------
# primitive
# ---------------------------------------------------------------------
func _mark(tx: int, ty: int, tw: int, thh: int) -> void:
	for x in range(tx, tx + tw):
		for y in range(ty, ty + thh):
			grid[Vector2i(x, y)] = true


func _rect(tx: int, ty: int, tw: int, thh: int, kind: String, opts: Dictionary = {}) -> Node:
	var b := Block.new()
	var sz := Vector2(tw * T, thh * T)
	var o := opts.duplicate()
	if not o.has("shape"):
		o["shape"] = Rect2(Vector2.ZERO, sz)
	b.setup(kind, Vector2(ox + tx * T, ty * T), sz, o, th)
	world.add_child(b)
	_mark(tx, ty, tw, thh)
	return b


func _platform_run(x0: int, x1: int, row: int, kind: String, crumble: bool) -> void:
	var x := x0
	while x <= x1:
		if grid.has(Vector2i(x, row)):
			x += 1
			continue
		var start := x
		while x <= x1 and not grid.has(Vector2i(x, row)):
			x += 1
		var w := x - start
		var hgt := 6 if kind == "wafer" else 5
		if crumble:
			# le cialde fragili sono separate a pezzi da 1 tile
			for k in w:
				_rect(start + k, row, 1, 1, kind, {"one_way": true, "crumble": true, "shape": Rect2(0, 0, T, hgt)})
		else:
			_rect(start, row, w, 1, kind, {"one_way": true, "shape": Rect2(0, 0, w * T, hgt)})


func _build_ground(pits: Array) -> void:
	var holes := {}
	for p in pits:
		for k in p[1]:
			holes[int(p[0]) + k] = true
		var pit := H.Pit.new()
		pit.main = main
		pit.width = float(p[1]) * T
		pit.position = Vector2(ox + float(p[0]) * T, D.LOWER_BASE * T)
		world.add_child(pit)
	var x := 0
	while x < D.CHUNK_W:
		if holes.has(x):
			x += 1
			continue
		var start := x
		while x < D.CHUNK_W and not holes.has(x):
			x += 1
		_rect(start, D.LOWER_BASE, x - start, 2, "ground")


# ---------------------------------------------------------------------
# oggetti (le macro del BAS)
# ---------------------------------------------------------------------

## BAS macro cup_knife (TAZZE): blocco 5x3 con manico
func _cup(x: int, base: int) -> void:
	for k in 5:
		_rect(x + k, base - 3, 1, 1, "cup", {"breakable": true, "top": true})
	_rect(x, base - 2, 5, 2, "cup", {"handle": true})
	var s := H.Steam.new()
	s.main = main
	s.width = 3.0 * T
	s.height = 4.5 * T
	s.position = Vector2(ox + (x + 2.5) * T, (base - 3) * T)
	world.add_child(s)


## BAS macro chocolate (MURI): due colonne, la seconda rialzata di 2
func _chocolate(sx: int, base: int) -> void:
	for col in [[sx + 6, base - 3], [sx + 14, base - 5]]:
		var cx: int = col[0]
		var cy: int = col[1]
		for k in 2:
			_rect(cx + k, cy, 1, 1, "choco", {"breakable": true, "sticky": true, "top": true})
		_rect(cx, cy + 1, 2, 2, "choco", {"sticky": true})


## BAS macro table: piano del tavolo + gambe + sedia
func _table(x: int, base: int) -> void:
	for k in 5:
		var l := 0
		if k == 0:
			l = 1
		elif k == 4:
			l = 2
		_rect(x + k, base - 2, 1, 1, "table", {"breakable": true, "one_way": true, "legs": l, "shape": Rect2(0, 0, T, 6)})
	_rect(x + 6, base - 1, 2, 1, "chair", {"shape": Rect2(0, 4, 2 * T, 12)})


## BAS macro choco_drops (GOCCE)
func _drops(x: int, upper: bool) -> void:
	var d := H.DropSource.new()
	d.main = main
	d.hanging = not upper
	var y := 1.5 * T if upper else (D.UPPER_BASE + 1.5) * T
	d.position = Vector2(ox + (x + 0.5) * T, y)
	world.add_child(d)


## BAS macro lamp (LAMPADE)
func _lamp(x: int, upper: bool) -> void:
	var l := H.Lamp.new()
	l.main = main
	var y := 2.4 * T if upper else (D.UPPER_BASE + 1.9) * T
	l.position = Vector2(ox + (x + 1.5) * T, y)
	l.top_y = T
	world.add_child(l)
	info.lamps.append(l)


func _knife(x: int) -> void:
	var k := H.Knife.new()
	k.main = main
	k.position = Vector2(ox + (x + 0.5) * T, D.LOWER_BASE * T)
	world.add_child(k)


func _push_block() -> void:
	# BAS: _pushCol = 13 (colonna del playfield) -> tile del chunk
	var p := H.PushBlock.new()
	var tx := D.PUSH_COL_START * 4 - 10
	p.position = Vector2(ox + tx * T, (D.LOWER_BASE - 3) * T - 0.5)
	p.min_x = ox + 33.0 * T
	p.max_x = ox + float(D.PUSH_COL_MAX * 4 - 10) * T
	world.add_child(p)
	info.push = p


## BAS: missile1x = (temp3&7)*8+20 : missile1y = (temp3/8)*8+8
func _sugar(index: int, v: int) -> void:
	var c := v & 7
	var r := v >> 3
	var x := c * 16 + 4
	var y := 0.0
	if r < 4:
		y = 3.0 + r * 1.5
	elif r == 4:
		y = 7.5
	else:
		y = 10.5 + (r - 5) * 1.75
	if r <= 4:
		_platform_run(x - 1, x + 1, D.UPPER_BASE, "wafer", D.EXT_CRUMBLE[level - 1])
	# se cade dentro un oggetto lo spostiamo verso l'alto
	var guard := 0
	while grid.has(Vector2i(x, int(floor(y)))) and guard < 8:
		y -= 1.0
		guard += 1
	var s := SugarScript.new()
	s.main = main
	s.index = index
	if index == 0:
		s.draw_kind = 1
	elif index == 1 and level > 3:
		s.draw_kind = 2
	s.position = Vector2(ox + (x + 0.5) * T, y * T)
	world.add_child(s)
	info.sugars.append(s)


## BAS: ballx = objects[...+7] (18 = sinistra, 136 = destra) : bally = 28
func _bag(ballx: int) -> void:
	var bx := clampi(int(float(ballx - 10) * D.CHUNK_W / 140.0), 4, D.CHUNK_W - 8)
	_platform_run(bx - 2, bx + 2, D.UPPER_BASE, "mensola", false)
	var b := BagScript.new()
	b.main = main
	b.position = Vector2(ox + (bx + 0.5) * T, D.UPPER_BASE * T - 13.0)
	world.add_child(b)
	info.bag = b
