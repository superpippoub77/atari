extends Node2D
## =====================================================================
##  HUD + SCHERMATA DEL TITOLO
## ---------------------------------------------------------------------
##  BAS: pfscore1 (barra del tempo, sinistra), pfscore2 (vite, destra),
##  score (al centro, colore scorecolor che cambia a ogni livello).
##  Il titolo ridisegna il playfield originale "Snack 'n' Roll" con i
##  suoi pfcolors e la modalita' attract (biscotto inseguito dalla bocca).
## =====================================================================

const D := preload("res://scripts/snack_data.gd")
const Art := preload("res://scripts/art.gd")

var main
var msgs: Array = []
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_message(text: String, color: Color = Color.WHITE, dur: float = 2.2, big: bool = true) -> void:
	var keep: Array = []
	for m in msgs:
		if m.big != big:
			keep.append(m)
	msgs = keep
	msgs.append({"text": text, "color": color, "t": 0.0, "dur": dur, "big": big})


func clear_messages() -> void:
	msgs.clear()


func _process(delta: float) -> void:
	_t += delta
	var keep: Array = []
	for m in msgs:
		m.t += delta
		if m.t < m.dur:
			keep.append(m)
	msgs = keep
	queue_redraw()


# ---------------------------------------------------------------------
func _text(s: String, pos: Vector2, size: int, col: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	var f := ThemeDB.fallback_font
	draw_string_outline(f, pos, s, align, width, size, 4, Color(0, 0, 0, 0.85 * col.a))
	draw_string(f, pos, s, align, width, size, col)


func _center(s: String, y: float, size: int, col: Color) -> void:
	_text(s, Vector2(0, y), size, col, HORIZONTAL_ALIGNMENT_CENTER, D.VIEW_W)


func _draw() -> void:
	match main.state:
		"title":
			_draw_title()
		_:
			_draw_game()
			if main.state == "gameover":
				_draw_end("GAME OVER", Color(1, 0.35, 0.3), "Le bocche hanno mangiato Bisco...")
			elif main.state == "victory":
				_draw_end("HAI VINTO!", Color(1, 0.85, 0.3), "Il Dispenser Supremo di Biscotti e' tuo!")
	_draw_messages()
	if main.get_tree().paused:
		draw_rect(Rect2(0, 0, D.VIEW_W, D.VIEW_H), Color(0, 0, 0, 0.55))
		_center("PAUSA", 130, 28, Color.WHITE)
		_center("P / ESC per continuare  -  M audio on/off", 155, 10, Color(1, 1, 1, 0.8))


# ---------------------------------------------------------------------
# HUD di gioco
# ---------------------------------------------------------------------
func _draw_game() -> void:
	draw_rect(Rect2(0, 0, D.VIEW_W, 24), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(0, 24, D.VIEW_W, 1), Color(1, 1, 1, 0.12))

	# --- pfscore1: barra del tempo ---
	_text("TEMPO", Vector2(6, 10), 8, Color(1, 1, 1, 0.75))
	var segs := D.bit_count(main.pfscore1)
	var warn: bool = segs <= 2 and int(_t * 5.0) % 2 == 0
	for i in 8:
		var c := Color(1, 0.82, 0.4) if i < segs else Color(1, 1, 1, 0.12)
		if i < segs and warn:
			c = Color(1, 0.3, 0.3)
		draw_rect(Rect2(6 + i * 8, 13, 6, 7), c)

	# --- score ---
	var sc: Color = D.pal((main.scorecolor & 0xF0) | 0x0C)
	_text("%06d" % main.score, Vector2(0, 18), 16, sc, HORIZONTAL_ALIGNMENT_CENTER, D.VIEW_W)

	# --- pfscore2: vite ---
	var lives := D.bit_count(main.pfscore2)
	_text("VITE", Vector2(400, 10), 8, Color(1, 1, 1, 0.75))
	for i in 4:
		Art.draw_cookie(self, Vector2(408 + i * 16, 16), 5.0, D.pal(D.P0_COLOR), 0.0, 1, 1.0 if i < lives else 0.15)

	# --- seconda riga: stato del livello ---
	var y := 38.0
	_text("LIV %d" % main.level, Vector2(6, y), 11, Color(1, 1, 1))
	for i in 8:
		var got: bool = (main.choco_bits & D.BITTABLE[i]) != 0
		var p := Vector2(58 + i * 12, y - 4)
		if got:
			var kind := 0
			if i == 0:
				kind = 1
			elif i == 1 and main.level > 3:
				kind = 2
			draw_set_transform(p, 0, Vector2(0.7, 0.7))
			Art.draw_sugar(self, Vector2.ZERO, kind, 0.0)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		else:
			draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), Color(1, 1, 1, 0.18))
	var ix := 160.0
	# bocca colpita (BAS: !_b5_enablePalyer1)
	var mouth_ok: bool = not main.enable_player1
	Art.draw_mouth(self, Vector2(ix + 8, y - 4), 7.0, D.pal(D.P1_COLOR) if mouth_ok else Color(1, 1, 1, 0.25), 0.3, 1.0 if mouth_ok else 0.4)
	if mouth_ok:
		draw_line(Vector2(ix + 1, y - 10), Vector2(ix + 15, y + 2), Color(0.3, 1, 0.4), 2.0)
	ix += 24
	if main.level > 3:
		var kc := Color(0.55, 0.85, 1.0) if main.has_key else Color(1, 1, 1, 0.2)
		draw_arc(Vector2(ix + 3, y - 4), 3.0, 0, TAU, 10, kc, 2.0)
		draw_line(Vector2(ix + 6, y - 4), Vector2(ix + 13, y - 4), kc, 2.0)
		draw_line(Vector2(ix + 11, y - 4), Vector2(ix + 11, y - 1), kc, 2.0)
		ix += 22
	# luce
	var lit: bool = main.enable_light
	draw_circle(Vector2(ix + 6, y - 6), 4.5, Color(1, 0.95, 0.5) if lit else Color(0.3, 0.3, 0.35))
	draw_rect(Rect2(ix + 3.5, y - 2, 5, 3), Color(0.6, 0.6, 0.65))
	if not lit:
		_text("BUIO!", Vector2(ix + 14, y), 9, Color(1, 0.5, 0.5, 0.6 + 0.4 * sin(_t * 8.0)))
		ix += 34
	ix += 16
	if main.slow_motion:
		_text("APPICCICATO", Vector2(ix, y), 9, Color(0.85, 0.55, 0.3))
		ix += 70
	if main.hit_cooldown > 0 and main.golden_rush:
		_text("SUGAR RUSH!", Vector2(ix, y), 9, Color(1, 0.85, 0.3, 0.6 + 0.4 * sin(_t * 12.0)))

	_text("Z/Spazio salta (2x = roll)  X spara  Su = spara in alto", Vector2(6, 264), 7, Color(1, 1, 1, 0.35))


func _draw_end(title: String, col: Color, sub: String) -> void:
	draw_rect(Rect2(0, 60, D.VIEW_W, 130), Color(0, 0, 0, 0.6))
	var s := 1.0 + 0.04 * sin(_t * 4.0)
	draw_set_transform(Vector2(D.VIEW_W * 0.5, 110), 0, Vector2(s, s))
	_text(title, Vector2(-D.VIEW_W * 0.5, 0), 34, col, HORIZONTAL_ALIGNMENT_CENTER, D.VIEW_W)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	_center(sub, 134, 11, Color(1, 1, 1, 0.9))
	_center("PUNTEGGIO %06d     RECORD %06d" % [main.score, main.hiscore], 158, 12, Color(1, 1, 1))
	_center("Invio per tornare al titolo", 180, 9, Color(1, 1, 1, 0.6))


# ---------------------------------------------------------------------
# Titolo (BAS: __draw_title + __attract_mode)
# ---------------------------------------------------------------------
func _draw_title() -> void:
	draw_rect(Rect2(0, 0, D.VIEW_W, D.VIEW_H), Color(0.05, 0.02, 0.05, 0.72))
	var bw := 13.0
	var bh := 8.0
	var x0 := (D.VIEW_W - 32.0 * bw) * 0.5
	var y0 := 18.0
	for r in D.TITLE_ROWS.size():
		var line: String = D.TITLE_ROWS[r]
		var base: Color = D.pal(D.TITLE_COLORS[r]).lightened(0.45)
		for c in 32:
			var on := line[c] == "X"
			# BAS: pfpixel temp1 6 on -> indicatore del livello iniziale (riga 6)
			if r == 6 and c == main.choco_count * 2 + 1:
				on = true
			if not on:
				continue
			var wave := 0.5 + 0.5 * sin(_t * 3.0 - c * 0.35 + r * 0.2)
			var col := base.lerp(Color(1, 0.9, 0.6), wave * 0.35)
			var rr := Rect2(x0 + c * bw, y0 + r * bh, bw - 1.0, bh - 1.0)
			draw_rect(Rect2(rr.position + Vector2(2, 2), rr.size), Color(0, 0, 0, 0.5))
			draw_rect(rr, col)
			draw_rect(Rect2(rr.position, Vector2(rr.size.x, 1.5)), Color(1, 1, 1, 0.35))

	_center("Bisco il biscotto contro le Bocche della Cucina", 122, 10, Color(1, 0.9, 0.7))

	# selettore livello iniziale (BAS: switchselect -> _choco_count 0..4)
	_center("LIVELLO INIZIALE", 146, 10, Color(1, 1, 1, 0.8))
	for i in D.MAX_LEVEL:
		var sel: bool = i == main.choco_count
		var r := Rect2(D.VIEW_W * 0.5 - 70 + i * 28, 152, 22, 16)
		draw_rect(r, Color(1, 0.8, 0.35) if sel else Color(1, 1, 1, 0.15))
		_text(str(i + 1), r.position + Vector2(0, 12), 11, Color(0.15, 0.08, 0.02) if sel else Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var th: Dictionary = D.theme(main.choco_count + 1)
	_center(th.name, 182, 9, Color(1, 1, 1, 0.6))

	# attract mode: il biscotto passeggia, la bocca lo insegue 15 px dietro
	var ay := 214.0
	draw_rect(Rect2(0, ay + 8, D.VIEW_W, 2), Color(1, 1, 1, 0.15))
	var px: float = 30.0 + main.attract_x * 2.8
	var mx: float = 30.0 + (main.attract_x - 15) * 2.8
	var facing: int = -1 if main.attract_dir else 1
	Art.draw_cookie(self, Vector2(px, ay), 7.0, D.pal(D.P0_COLOR), main.attract_x * 0.4 * facing, facing)
	Art.draw_mouth(self, Vector2(mx, ay), 9.0, D.pal(D.P1_COLOR), absf(sin(_t * 8.0)))

	var blink := 0.55 + 0.45 * sin(_t * 4.0)
	_center("INVIO / F2 (RESET) = GIOCA      TAB / F1 (SELECT) = LIVELLO", 244, 10, Color(1, 1, 0.8, blink))
	_center("ULTIMO %06d   -   RECORD %06d" % [main.last_score, main.hiscore], 262, 9, Color(1, 1, 1, 0.6))


# ---------------------------------------------------------------------
func _draw_messages() -> void:
	var toast_y := 58.0
	for m in msgs:
		var a := clampf((m.dur - m.t) / 0.4, 0.0, 1.0)
		var col: Color = m.color
		col.a *= a
		if m.big:
			var pop := 1.0 + maxf(0.0, 0.35 - m.t) * 1.6
			draw_set_transform(Vector2(D.VIEW_W * 0.5, 105), 0, Vector2(pop, pop))
			_text(m.text, Vector2(-D.VIEW_W * 0.5, 0), 22, col, HORIZONTAL_ALIGNMENT_CENTER, D.VIEW_W)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		else:
			_center(m.text, toast_y, 10, col)
			toast_y += 13.0
