extends RefCounted
## Disegno procedurale dei personaggi (nessuna texture esterna).
## Usato da giocatore, bocche e HUD (schermata titolo / vite).


## Il biscotto (player0 del BAS: sprite 8x4 "%00100100 %10111101 ...")
static func draw_cookie(ci: CanvasItem, pos: Vector2, r: float, base: Color, angle: float, facing: int, alpha: float = 1.0) -> void:
	var rim := base.darkened(0.38)
	rim.a = alpha
	var c := base
	c.a = alpha
	ci.draw_circle(pos, r + 1.2, rim)
	ci.draw_circle(pos, r, c)
	ci.draw_circle(pos + Vector2(-r * 0.3, -r * 0.35), r * 0.38, Color(1, 1, 1, 0.20 * alpha))
	var chip := Color(0.30, 0.15, 0.07, alpha)
	for i in 5:
		var a := angle + float(i) * TAU / 5.0
		var rr := r * (0.62 if i % 2 == 0 else 0.30)
		ci.draw_circle(pos + Vector2(cos(a), sin(a)) * rr, r * 0.16, chip)
	# occhi (non ruotano con il biscotto)
	for s in [-1.0, 1.0]:
		var ep := pos + Vector2(float(facing) * r * 0.22 + s * r * 0.33, -r * 0.12)
		ci.draw_circle(ep, r * 0.24, Color(1, 1, 1, alpha))
		ci.draw_circle(ep + Vector2(float(facing) * r * 0.09, r * 0.02), r * 0.12, Color(0.05, 0.05, 0.12, alpha))


## La bocca (player1 del BAS: "%01111110 %10000001 %10011001 %01100110")
## hw = mezza larghezza, open = 0..1 apertura
static func draw_mouth(ci: CanvasItem, pos: Vector2, hw: float, color: Color, open: float, alpha: float = 1.0) -> void:
	var col := color
	col.a = alpha
	var k := 0.8 + open * 2.6
	var dark := Color(0.18, 0.02, 0.05, alpha)
	ci.draw_rect(Rect2(pos.x - hw * 0.72, pos.y - k, hw * 1.44, k * 2.0), dark)
	var tw := hw * 1.44 / 5.0
	for i in 5:
		ci.draw_rect(Rect2(pos.x - hw * 0.72 + float(i) * tw + 0.4, pos.y - k, tw - 0.8, minf(2.4, k)), Color(1, 1, 0.94, alpha))
	var up := PackedVector2Array([
		pos + Vector2(-hw, 0), pos + Vector2(-hw * 0.62, -4.5 - k), pos + Vector2(-hw * 0.18, -6.2 - k),
		pos + Vector2(0, -4.6 - k), pos + Vector2(hw * 0.18, -6.2 - k), pos + Vector2(hw * 0.62, -4.5 - k),
		pos + Vector2(hw, 0), pos + Vector2(hw * 0.62, -k), pos + Vector2(-hw * 0.62, -k),
	])
	ci.draw_colored_polygon(up, col)
	var lo := PackedVector2Array([
		pos + Vector2(-hw, 0), pos + Vector2(-hw * 0.62, k), pos + Vector2(hw * 0.62, k),
		pos + Vector2(hw, 0), pos + Vector2(hw * 0.6, 5.5 + k), pos + Vector2(-hw * 0.6, 5.5 + k),
	])
	ci.draw_colored_polygon(lo, col)
	var hl := Color(1, 1, 1, 0.35 * alpha)
	ci.draw_line(pos + Vector2(-hw * 0.45, 3.2 + k), pos + Vector2(hw * 0.1, 3.6 + k), hl, 1.2)
	ci.draw_line(pos + Vector2(-hw * 0.55, -3.6 - k), pos + Vector2(-hw * 0.25, -4.8 - k), hl, 1.0)


## Zuccherino (missile1 del BAS)
static func draw_sugar(ci: CanvasItem, pos: Vector2, kind: int, t: float) -> void:
	var s := 4.5
	var pts := PackedVector2Array([pos + Vector2(0, -s), pos + Vector2(s, 0), pos + Vector2(0, s), pos + Vector2(-s, 0)])
	match kind:
		1:  # dorato
			var star := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + float(i) * PI / 5.0 + t * 1.5
				var rr := 7.0 if i % 2 == 0 else 3.2
				star.append(pos + Vector2(cos(a), sin(a)) * rr)
			ci.draw_colored_polygon(star, Color(1.0, 0.82, 0.2))
			ci.draw_circle(pos, 2.0, Color(1, 1, 0.8))
		2:  # chiave
			var gold := Color(0.55, 0.85, 1.0)
			ci.draw_arc(pos + Vector2(-3, 0), 3.0, 0, TAU, 12, gold, 2.0)
			ci.draw_line(pos + Vector2(0, 0), pos + Vector2(6, 0), gold, 2.0)
			ci.draw_line(pos + Vector2(4, 0), pos + Vector2(4, 3), gold, 2.0)
			ci.draw_line(pos + Vector2(6, 0), pos + Vector2(6, 3), gold, 2.0)
		_:
			ci.draw_colored_polygon(pts, Color(1, 1, 1))
			ci.draw_line(pts[0], pts[1], Color(0.75, 0.85, 1.0), 1.0)
			ci.draw_line(pts[1], pts[2], Color(0.75, 0.85, 1.0), 1.0)
			ci.draw_circle(pos + Vector2(-1.2, -1.2), 1.1, Color(0.85, 0.95, 1.0))
	# scintilla
	var sp := absf(sin(t * 3.0))
	if sp > 0.7:
		var c := Color(1, 1, 1, (sp - 0.7) * 3.0)
		var p := pos + Vector2(5, -5)
		ci.draw_line(p + Vector2(-3, 0), p + Vector2(3, 0), c, 1.0)
		ci.draw_line(p + Vector2(0, -3), p + Vector2(0, 3), c, 1.0)
