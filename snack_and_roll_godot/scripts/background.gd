extends Node2D
## Sfondo a parallasse disegnato proceduralmente (solo Godot).
## Tre piani: piastrelle del muro, finestre, mensole con barattoli.
## Il tema cambia in base al livello in cui si trova la telecamera.

const D := preload("res://scripts/snack_data.gd")

var main
var _t := 0.0


func _ready() -> void:
	z_index = -50


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _layer_start(cx: float, factor: float, period: float) -> float:
	# posizione nel mondo del primo elemento ripetuto visibile
	var left := cx - D.VIEW_W * 0.5
	var off := fposmod(cx * factor, period)
	return left - off - period


func _draw() -> void:
	var cx: float = main.cam_x
	var th: Dictionary = main.current_theme()
	var left := cx - D.VIEW_W * 0.5 - 8.0
	var w := D.VIEW_W + 16.0
	draw_rect(Rect2(left, 0, w, 280), th.wall)

	# --- piastrelle (parallasse 0.25) ---
	var tile := 24.0
	var x := _layer_start(cx, 0.25, tile)
	var row := 0
	while row < 12:
		var y := 6.0 + row * tile
		var xx := x
		var i := 0
		while xx < left + w + tile:
			if (i + row) % 2 == 0:
				draw_rect(Rect2(xx + 1, y + 1, tile - 2, tile - 2), th.wall2)
			xx += tile
			i += 1
		row += 1
	xx_lines(x, left + w + tile, tile, th.grout)

	# --- finestre (parallasse 0.35) ---
	var period := 380.0
	x = _layer_start(cx, 0.35, period)
	while x < left + w + period:
		_window(Vector2(x + 70, 40), th)
		x += period

	# --- mensole e barattoli (parallasse 0.55) ---
	var p2 := 260.0
	x = _layer_start(cx, 0.55, p2)
	var k := int(floor((cx * 0.55) / p2))
	var shade: Color = th.wood2
	shade.a = 0.35
	while x < left + w + p2:
		var sy := 120.0 + float(posmod(k, 3)) * 8.0
		draw_rect(Rect2(x + 20, sy, 120, 4), shade)
		for j in 4:
			var jx := x + 30 + j * 28
			var hgt := 14.0 + float(posmod(k * 7 + j * 3, 5)) * 3.0
			var jar: Color = th.grout
			jar.a = 0.35
			draw_rect(Rect2(jx, sy - hgt, 16, hgt), jar)
			draw_rect(Rect2(jx + 2, sy - hgt - 3, 12, 3), shade)
		# mobili bassi
		var cab: Color = th.wood2
		cab.a = 0.18
		draw_rect(Rect2(x + 160, 196, 90, 44), cab)
		draw_line(Vector2(x + 205, 198), Vector2(x + 205, 238), shade, 1.0)
		x += p2
		k += 1
	# velo scuro: lo sfondo resta dietro ai primi piani
	draw_rect(Rect2(left, 0, w, 280), Color(0.05, 0.03, 0.08, 0.22))


func xx_lines(x0: float, x1: float, step: float, col: Color) -> void:
	var c := col
	c.a = 0.5
	var x := x0
	while x < x1:
		draw_line(Vector2(x, 0), Vector2(x, 280), c, 1.0)
		x += step
	for r in 13:
		var y := 6.0 + r * step
		draw_line(Vector2(x0, y), Vector2(x1, y), c, 1.0)


func _window(p: Vector2, th: Dictionary) -> void:
	var r := Rect2(p, Vector2(96, 72))
	draw_rect(r.grow(5), th.wood)
	draw_rect(r, th.sky)
	if th.night:
		draw_circle(p + Vector2(70, 20), 9.0, Color(1, 0.97, 0.8))
		draw_circle(p + Vector2(74, 17), 8.0, th.sky)
		for i in 7:
			var sp := p + Vector2(fposmod(i * 37.0, 92.0) + 2.0, fposmod(i * 23.0, 64.0) + 4.0)
			var a := 0.5 + 0.5 * sin(_t * 2.0 + i)
			draw_rect(Rect2(sp, Vector2(1.5, 1.5)), Color(1, 1, 1, a))
	else:
		draw_circle(p + Vector2(24, 22), 10.0, Color(1, 0.95, 0.6, 0.9))
		var cloud_x := fposmod(_t * 6.0, 130.0) - 30.0
		for i in 3:
			var cp := p + Vector2(cloud_x + i * 9.0, 46 + (i % 2) * -4.0)
			if cp.x > p.x + 4 and cp.x < p.x + 92:
				draw_circle(cp, 7.0, Color(1, 1, 1, 0.85))
	draw_rect(Rect2(p + Vector2(46, 0), Vector2(4, 72)), th.wood)
	draw_rect(Rect2(p + Vector2(0, 34), Vector2(96, 4)), th.wood)
	draw_rect(Rect2(p + Vector2(-8, 74), Vector2(112, 6)), th.wood2)
