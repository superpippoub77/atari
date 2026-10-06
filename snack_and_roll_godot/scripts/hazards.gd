extends RefCounted
## =====================================================================
##  OGGETTI DINAMICI E TRABOCCHETTI
## ---------------------------------------------------------------------
##  Classi interne per non moltiplicare i file:
##   DropSource / Drop  - GOCCE (colonna 3 di "objects"): nel BAS un
##                        pixel che scende ciclicamente (macro choco_drops)
##   Lamp               - LAMPADE (colonna 4, macro lamp)
##   Gate               - cancello di fine livello (solo Godot)
##   PushBlock          - muro spingibile (BAS: _pushCol, livello >= 5)
##   Steam              - vapore delle tazze (solo Godot)
##   Knife              - coltelli a scatto (EXT_KNIVES, solo Godot)
##   Pit                - pozza di cioccolata bollente (EXT_PITS, solo Godot)
## =====================================================================

const Fx := preload("res://scripts/fx.gd")


# ---------------------------------------------------------------------
class DropSource:
	extends Node2D
	var main
	var hanging := false   # parte bassa: tubo che scende dal soffitto
	var period := 1.7
	var _t := 0.0

	func _ready() -> void:
		z_index = -1
		_t = fposmod(position.x * 0.013, period)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t >= period:
			_t = 0.0
			var d := Drop.new()
			d.main = main
			d.position = position + Vector2(0, 7)
			get_parent().add_child(d)
		queue_redraw()

	func _draw() -> void:
		var choc := Color(0.38, 0.21, 0.10)
		if hanging:
			draw_rect(Rect2(-3, -position.y + 16, 6, position.y - 18), Color(0.55, 0.55, 0.6))
			draw_rect(Rect2(-5, -6, 10, 5), Color(0.62, 0.62, 0.68))
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(-7, -8), Vector2(7, -8), Vector2(2, 2), Vector2(-2, 2)]), choc)
		var k := _t / period
		draw_circle(Vector2(0, 1 + k * 4.0), 1.2 + k * 1.8, choc.lightened(0.1))


class Drop:
	extends Area2D
	var main
	var vy := 0.0
	var dead := false

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 1 | 2 | 4
		monitorable = false
		var cs := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 3.0
		cs.shape = c
		add_child(cs)
		body_entered.connect(_on_body)

	func _physics_process(delta: float) -> void:
		vy = minf(vy + 520.0 * delta, 380.0)
		position.y += vy * delta
		if position.y > 300.0:
			queue_free()
		queue_redraw()

	func _on_body(body: Node) -> void:
		if dead:
			return
		if body == main.player:
			main.set_slow_motion()
		dead = true
		Fx.burst(get_parent(), global_position, Color(0.42, 0.24, 0.12), 6, 50.0, 0.35, 300.0, 1.8)
		queue_free.call_deferred()

	func _draw() -> void:
		var c := Color(0.42, 0.23, 0.11)
		draw_circle(Vector2(0, 1), 3.0, c)
		draw_colored_polygon(PackedVector2Array([Vector2(-2.6, 0), Vector2(0, -6), Vector2(2.6, 0)]), c)
		draw_circle(Vector2(-1, 0), 0.9, Color(0.8, 0.6, 0.45))


# ---------------------------------------------------------------------
class Lamp:
	extends Node2D
	## BAS: il missile che colpisce il piano riaccende la luce; dal README
	## "per accenderla ci si deve posizionare sotto la lamp". Qui basta
	## toccarla o colpirla con un cioccolatino.
	var main
	var top_y := 16.0
	var lit := true
	var light: PointLight2D
	var area: Area2D
	var _t := 0.0

	func _ready() -> void:
		add_to_group("lamps")
		light = PointLight2D.new()
		light.texture = main.light_tex
		light.texture_scale = 1.1
		light.color = Color(1.0, 0.85, 0.55)
		light.energy = 0.45
		light.position = Vector2(0, 6)
		add_child(light)
		area = Area2D.new()
		area.collision_layer = 32
		area.collision_mask = 4
		area.add_to_group("lamp_area")
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(40, 16)
		cs.shape = r
		cs.position = Vector2(0, 2)
		area.add_child(cs)
		add_child(area)
		area.body_entered.connect(_on_body)

	func _on_body(body: Node) -> void:
		if body == main.player:
			main.relight()

	func set_lit(on: bool) -> void:
		if on == lit:
			return
		lit = on
		light.energy = 0.45 if on else 0.0
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		if not lit:
			queue_redraw()

	func _draw() -> void:
		draw_line(Vector2(0, top_y - position.y), Vector2(0, -6), Color(0.2, 0.2, 0.2), 1.0)
		var shade := PackedVector2Array([Vector2(-8, -6), Vector2(8, -6), Vector2(20, 6), Vector2(-20, 6)])
		draw_colored_polygon(shade, Color(0.85, 0.3, 0.25))
		draw_line(Vector2(-20, 6), Vector2(20, 6), Color(0.6, 0.18, 0.15), 2.0)
		var bulb := Color(1.0, 0.95, 0.65) if lit else Color(0.3, 0.3, 0.32)
		if not lit and fmod(_t, 1.2) < 0.1:
			bulb = Color(0.8, 0.75, 0.5)
		draw_circle(Vector2(0, 8), 4.0, bulb)
		if lit:
			draw_circle(Vector2(0, 8), 7.0, Color(1, 0.95, 0.6, 0.25))


# ---------------------------------------------------------------------
class Gate:
	extends StaticBody2D
	var h := 224.0
	var is_open := false
	var lift := 0.0
	var _shape: CollisionShape2D
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 1
		collision_mask = 0
		_shape = CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(16, h)
		_shape.shape = r
		_shape.position = Vector2(8, h * 0.5)
		add_child(_shape)

	func open() -> void:
		if is_open:
			return
		is_open = true
		_shape.set_deferred("disabled", true)
		create_tween().tween_property(self, "lift", h - 10.0, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	func close() -> void:
		if not is_open:
			return
		is_open = false
		_shape.set_deferred("disabled", false)
		create_tween().tween_property(self, "lift", 0.0, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var vis := h - lift
		draw_rect(Rect2(-2, 0, 20, 6), Color(0.5, 0.5, 0.55))
		if vis > 0.0:
			draw_rect(Rect2(1, 0, 14, vis), Color(1, 1, 1))
			var y := -fmod(_t * 6.0, 12.0) - lift
			while y < vis:
				var y0 := maxf(y, 0.0)
				var y1 := minf(y + 6.0, vis)
				if y1 > y0:
					draw_rect(Rect2(1, y0, 14, y1 - y0), Color(0.9, 0.15, 0.2))
				y += 12.0
			draw_rect(Rect2(0, vis - 4, 16, 4), Color(0.5, 0.5, 0.55))
		if is_open:
			var a := 0.5 + 0.5 * sin(_t * 6.0)
			draw_colored_polygon(PackedVector2Array([Vector2(22, 190), Vector2(32, 198), Vector2(22, 206)]), Color(1, 1, 0.5, a))


# ---------------------------------------------------------------------
class PushBlock:
	extends StaticBody2D
	## BAS: temp5 = (player0x-18)/4 : if temp5 = (_pushCol-1) ... _pushCol+1
	var origin_x := 0.0
	var min_x := 0.0
	var max_x := 0.0
	var size := Vector2(32, 48)

	func _ready() -> void:
		collision_layer = 1
		collision_mask = 1 | 2
		add_to_group("pushable")
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = size
		cs.shape = r
		cs.position = size * 0.5
		add_child(cs)
		origin_x = position.x

	func push(dx: float) -> void:
		var nx := clampf(position.x + dx, min_x, max_x)
		var motion := Vector2(nx - position.x, 0)
		if motion.x == 0.0:
			return
		if not test_move(global_transform, motion):
			position.x = nx

	## BAS: if temp5=_pushCol then _pushCol=0 (colpito dal cioccolatino)
	func knock_back() -> void:
		create_tween().tween_property(self, "position:x", origin_x, 0.4).set_trans(Tween.TRANS_QUAD)

	func _draw() -> void:
		var cd := Color(0.33, 0.18, 0.09)
		draw_rect(Rect2(Vector2.ZERO, size), cd.darkened(0.3))
		for i in 4:
			for j in 6:
				var r := Rect2(Vector2(i * 8 + 1, j * 8 + 1), Vector2(6, 6))
				draw_rect(r, cd)
				draw_line(r.position, r.position + Vector2(6, 0), cd.lightened(0.3), 1.0)
		draw_rect(Rect2(4, 18, 24, 12), Color(0.95, 0.85, 0.6))
		draw_colored_polygon(PackedVector2Array([Vector2(8, 24), Vector2(13, 20), Vector2(13, 28)]), cd)
		draw_colored_polygon(PackedVector2Array([Vector2(24, 24), Vector2(19, 20), Vector2(19, 28)]), cd)


# ---------------------------------------------------------------------
class Steam:
	extends Area2D
	## Vapore bollente che esce dalle tazze: ti spara verso l'alto.
	var main
	var period := 3.2
	var active_time := 1.0
	var _t := 0.0
	var _active := false
	var _particles: CPUParticles2D
	var width := 64.0
	var height := 64.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 4
		monitorable = false
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(width, height)
		cs.shape = r
		cs.position = Vector2(0, -height * 0.5)
		add_child(cs)
		_t = fposmod(position.x * 0.007, period)
		_particles = CPUParticles2D.new()
		_particles.amount = 26
		_particles.lifetime = 0.9
		_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		_particles.emission_rect_extents = Vector2(width * 0.35, 2)
		_particles.direction = Vector2.UP
		_particles.spread = 12.0
		_particles.initial_velocity_min = 50.0
		_particles.initial_velocity_max = 90.0
		_particles.gravity = Vector2(0, -20)
		_particles.scale_amount_min = 3.0
		_particles.scale_amount_max = 6.0
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.55))
		g.set_color(1, Color(1, 1, 1, 0.0))
		_particles.color_ramp = g
		_particles.emitting = false
		add_child(_particles)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t >= period:
			_t = 0.0
		var was := _active
		_active = _t < active_time
		_particles.emitting = _active
		if _active and not was and _near_camera():
			Synth.sfx("steam")
		if _active and main.player != null:
			for b in get_overlapping_bodies():
				if b == main.player and b.velocity.y > -250.0:
					b.launch(-440.0)

	func _near_camera() -> bool:
		return absf(global_position.x - main.cam_x) < 260.0

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		# piccoli sbuffi di avvertimento prima del getto
		if not _active and _t > period - 0.6:
			var k := (_t - (period - 0.6)) / 0.6
			draw_circle(Vector2(-6, -4 - k * 6.0), 2.0 + k * 2.0, Color(1, 1, 1, 0.35 * k))
			draw_circle(Vector2(7, -3 - k * 8.0), 1.5 + k * 2.0, Color(1, 1, 1, 0.35 * k))


# ---------------------------------------------------------------------
class Knife:
	extends Area2D
	## Ripresa della colonna "COLTELLI" del BAS: lame che scattano dal
	## pavimento. Toccarle quando sono fuori costa una vita.
	var main
	var period := 2.4
	var _t := 0.0
	var up := 0.0   # 0 = nascosto, 1 = fuori

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 4
		monitorable = false
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(12, 14)
		cs.shape = r
		cs.position = Vector2(0, -7)
		add_child(cs)
		_t = fposmod(position.x * 0.011, period)

	func _physics_process(delta: float) -> void:
		var prev := up
		_t = fmod(_t + delta, period)
		if _t < 1.3:
			up = 0.0
		elif _t < 1.45:
			up = (_t - 1.3) / 0.15
		elif _t < 2.1:
			up = 1.0
		else:
			up = maxf(0.0, 1.0 - (_t - 2.1) / 0.2)
		if prev < 0.5 and up >= 0.5 and absf(global_position.x - main.cam_x) < 260.0:
			Synth.sfx("knife")
		if up > 0.6 and main.player != null:
			for b in get_overlapping_bodies():
				if b == main.player:
					main.hurt_player(global_position.x)
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(-8, -1, 16, 2), Color(0.15, 0.1, 0.08))
		var warn := _t > 0.95 and _t < 1.3
		if warn:
			draw_rect(Rect2(-6, -2, 12, 1), Color(1, 0.3, 0.2, 0.8))
		var hgt := up * 16.0
		if hgt > 0.5:
			var steel := Color(0.85, 0.88, 0.95)
			for x in [-4.0, 3.0]:
				draw_colored_polygon(PackedVector2Array([Vector2(x - 2.5, 0), Vector2(x + 2.5, 0), Vector2(x + 0.5, -hgt), Vector2(x - 2.5, -hgt * 0.75)]), steel)
				draw_line(Vector2(x - 2.0, -1), Vector2(x - 2.0, -hgt * 0.75), Color(1, 1, 1), 1.0)


# ---------------------------------------------------------------------
class Pit:
	extends Area2D
	## Pozza di cioccolata bollente: cadere dentro costa una vita.
	var main
	var width := 48.0
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 4
		monitorable = false
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(width, 30)
		cs.shape = r
		cs.position = Vector2(width * 0.5, 22)
		add_child(cs)
		var l := PointLight2D.new()
		l.texture = main.light_tex
		l.texture_scale = 0.7
		l.color = Color(1.0, 0.5, 0.2)
		l.energy = 0.55
		l.position = Vector2(width * 0.5, 8)
		add_child(l)

	func _physics_process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if main.player != null:
			for b in get_overlapping_bodies():
				if b == main.player:
					main.player_fell()

	func _draw() -> void:
		draw_rect(Rect2(0, 8, width, 30), Color(0.30, 0.13, 0.05))
		var pts := PackedVector2Array()
		var x := 0.0
		while x <= width:
			pts.append(Vector2(x, 8 + sin(x * 0.3 + _t * 4.0) * 1.5))
			x += 4.0
		pts.append(Vector2(width, 20))
		pts.append(Vector2(0, 20))
		draw_colored_polygon(pts, Color(0.55, 0.26, 0.10))
		for i in 3:
			var bx := fposmod(float(i) * 17.0 + _t * 9.0, width)
			var k := fmod(_t * 1.3 + float(i) * 0.37, 1.0)
			draw_arc(Vector2(bx, 10 - k * 3.0), 1.0 + k * 2.0, PI, TAU, 6, Color(0.85, 0.5, 0.25, 1.0 - k), 1.0)
