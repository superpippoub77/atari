extends StaticBody2D
## =====================================================================
##  BLOCCO DEL PLAYFIELD
## ---------------------------------------------------------------------
##  Equivale ai pixel del playfield del BAS (pfpixel / pfhline / pfvline).
##  - breakable : come nel BAS, solo la riga "in cima" di ogni gruppo
##                si distrugge con un cioccolatino (score + 1)
##  - sticky    : cioccolato fuso -> attiva lo slow motion
##                (BAS: pfread(...) then _b6_enableSlowMotion{6} = 1)
##  - one_way   : piattaforma attraversabile da sotto (solo Godot)
##  - crumble   : cialda che si sbriciola (trabocchetto, solo Godot)
## =====================================================================
const LAYER_SOLID := 1
const LAYER_PLATFORM := 2

var kind := "ground"
var size := Vector2(16, 16)
var breakable := false
var sticky := false
var one_way := false
var crumble := false
var legs := 0          # tavolo: 1 = gamba a sinistra, 2 = a destra
var top := false       # tazza/cioccolato: tile della riga superiore
var handle := false    # tazza: disegna il manico
var th: Dictionary = {}
var shape_rect := Rect2()

var _shape: CollisionShape2D
var _state := 0        # 0 = intero, 1 = si sta sbriciolando, 2 = sparito
var _timer := 0.0
var _shake := 0.0


func setup(p_kind: String, pos: Vector2, p_size: Vector2, opts: Dictionary, p_theme: Dictionary) -> void:
	kind = p_kind
	position = pos
	size = p_size
	th = p_theme
	breakable = opts.get("breakable", false)
	sticky = opts.get("sticky", false)
	one_way = opts.get("one_way", false)
	crumble = opts.get("crumble", false)
	legs = opts.get("legs", 0)
	top = opts.get("top", false)
	handle = opts.get("handle", false)
	shape_rect = opts.get("shape", Rect2(Vector2.ZERO, size))


func _ready() -> void:
	collision_layer = LAYER_PLATFORM if one_way else LAYER_SOLID
	collision_mask = 0
	if sticky:
		add_to_group("sticky")
	if kind == "shelf":
		add_to_group("shelf")
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = shape_rect.size
	_shape.shape = r
	_shape.position = shape_rect.position + shape_rect.size * 0.5
	_shape.one_way_collision = one_way
	add_child(_shape)
	set_physics_process(crumble)
	set_process(kind == "choco" and top)
	z_index = -2 if kind in ["ground", "ceiling", "wall"] else 0


## Chiamato dal biscotto quando ci sta sopra
func on_stood() -> void:
	if not crumble or _state != 0:
		return
	_state = 1
	_timer = 0.5
	Synth.sfx("land")


func _physics_process(delta: float) -> void:
	if _state == 1:
		_timer -= delta
		_shake = randf_range(-1.2, 1.2)
		queue_redraw()
		if _timer <= 0.0:
			_state = 2
			_timer = 3.0
			_shape.set_deferred("disabled", true)
			visible = false
			Fx.burst(get_parent(), position + size * 0.5, th.get("wood", Color.BURLYWOOD), 14, 60.0, 0.7, 400.0, 2.5)
	elif _state == 2:
		_timer -= delta
		if _timer <= 0.0:
			_state = 0
			_shake = 0.0
			_shape.set_deferred("disabled", false)
			visible = true
			queue_redraw()


## Colpito da un cioccolatino (BAS: pfpixel temp5 temp6 off)
func break_apart() -> void:
	var c: Color = Color(0.36, 0.2, 0.1) if sticky else th.get("cup", Color.WHITE)
	if kind == "table":
		c = th.get("wood", Color.BURLYWOOD)
	Fx.burst(get_parent(), position + size * 0.5, c, 16, 110.0, 0.7, 420.0, 2.5)
	queue_free()


const Fx := preload("res://scripts/fx.gd")


func _draw() -> void:
	var o := Vector2(_shake, 0)
	var w := size.x
	var h := size.y
	match kind:
		"ground":
			draw_rect(Rect2(o, size), th.floor2)
			var tiles := int(w / 16.0)
			for i in tiles:
				var c: Color = th.floor if i % 2 == 0 else th.floor.darkened(0.08)
				draw_rect(Rect2(o + Vector2(i * 16, 0), Vector2(16, 16)), c)
				draw_rect(Rect2(o + Vector2(i * 16 + 1, 17), Vector2(14, h - 18)), th.floor2.darkened(0.12))
			draw_rect(Rect2(o, Vector2(w, 2)), th.floor.lightened(0.35))
			draw_line(o + Vector2(0, 16), o + Vector2(w, 16), th.floor2.darkened(0.3), 1.0)
		"ceiling":
			draw_rect(Rect2(o, size), th.wood2)
			draw_rect(Rect2(o + Vector2(0, h - 3), Vector2(w, 3)), th.wood2.darkened(0.35))
			var n := int(w / 48.0)
			for i in n:
				var x := i * 48 + 22
				draw_rect(Rect2(o + Vector2(x, h - 7), Vector2(6, 2)), Color(0.85, 0.8, 0.6))
				draw_line(o + Vector2(i * 48, 0), o + Vector2(i * 48, h - 3), th.wood2.darkened(0.2), 1.0)
		"wall":
			draw_rect(Rect2(o, size), th.wood2.darkened(0.3))
			for j in int(h / 8.0):
				draw_line(o + Vector2(0, j * 8), o + Vector2(w, j * 8), th.wood2.darkened(0.5), 1.0)
		"cup":
			var cc: Color = th.cup
			draw_rect(Rect2(o, size), cc)
			draw_rect(Rect2(o + Vector2(0, 0), Vector2(1.5, h)), cc.darkened(0.15))
			if top:
				draw_rect(Rect2(o, Vector2(w, 3)), cc.lightened(0.4))
				draw_rect(Rect2(o + Vector2(0, 3), Vector2(w, 4)), Color(0.32, 0.17, 0.08))
				draw_rect(Rect2(o + Vector2(0, 3), Vector2(w, 1)), Color(0.55, 0.33, 0.16))
			else:
				draw_rect(Rect2(o + Vector2(0, 5), Vector2(w, 4)), th.cup2)
				draw_rect(Rect2(o + Vector2(0, h - 3), Vector2(w, 3)), cc.darkened(0.2))
			if handle:
				draw_arc(o + Vector2(w + 3, h * 0.45), 5.0, -PI / 2.0, PI / 2.0, 10, cc.darkened(0.1), 3.0)
		"choco":
			var cd := Color(0.36, 0.20, 0.10)
			draw_rect(Rect2(o, size), cd.darkened(0.25))
			for i in int(w / 8.0):
				for j in int(h / 8.0):
					var r := Rect2(o + Vector2(i * 8 + 1, j * 8 + 1), Vector2(6, 6))
					draw_rect(r, cd)
					draw_line(r.position, r.position + Vector2(6, 0), cd.lightened(0.25), 1.0)
			if top:
				draw_rect(Rect2(o + Vector2(0, -2), Vector2(w, 4)), Color(0.42, 0.24, 0.12))
				var t := Time.get_ticks_msec() / 600.0
				draw_circle(o + Vector2(w * 0.3, 2.5 + sin(t) * 1.0), 2.0, Color(0.42, 0.24, 0.12))
				draw_circle(o + Vector2(w * 0.75, 3.5 + sin(t + 1.5) * 1.5), 1.6, Color(0.42, 0.24, 0.12))
				draw_rect(Rect2(o + Vector2(1, -2), Vector2(w - 2, 1)), Color(0.6, 0.4, 0.25))
		"table":
			var wd: Color = th.wood
			draw_rect(Rect2(o, Vector2(w, 5)), wd)
			draw_line(o + Vector2(0, 0.5), o + Vector2(w, 0.5), wd.lightened(0.3), 1.0)
			draw_line(o + Vector2(0, 4.5), o + Vector2(w, 4.5), wd.darkened(0.3), 1.0)
			if legs == 1:
				draw_rect(Rect2(o + Vector2(3, 5), Vector2(3, 27)), wd.darkened(0.2))
			elif legs == 2:
				draw_rect(Rect2(o + Vector2(w - 6, 5), Vector2(3, 27)), wd.darkened(0.2))
		"chair":
			var wd2: Color = th.wood.darkened(0.1)
			draw_rect(Rect2(o + Vector2(0, 4), Vector2(w, 4)), wd2)
			draw_rect(Rect2(o + Vector2(w - 4, -14), Vector2(3, 18)), wd2)
			draw_rect(Rect2(o + Vector2(w - 6, -14), Vector2(7, 3)), wd2.lightened(0.15))
			draw_rect(Rect2(o + Vector2(2, 8), Vector2(2, 8)), wd2.darkened(0.25))
			draw_rect(Rect2(o + Vector2(w - 4, 8), Vector2(2, 8)), wd2.darkened(0.25))
		"shelf":
			var ct: Color = th.counter
			draw_rect(Rect2(o, Vector2(w, 8)), ct)
			draw_rect(Rect2(o + Vector2(0, 6), Vector2(w, 2)), ct.darkened(0.35))
			draw_rect(Rect2(o, Vector2(w, 1)), Color(1, 1, 1, 0.8))
			var vx := 7.0
			while vx < w:
				draw_line(o + Vector2(vx, 1), o + Vector2(vx + 5, 5), ct.darkened(0.12), 1.0)
				vx += 23.0
			draw_rect(Rect2(o + Vector2(2, 8), Vector2(w - 4, 2)), Color(0, 0, 0, 0.18))
		"mensola":
			var wm: Color = th.wood
			draw_rect(Rect2(o, Vector2(w, 5)), wm)
			draw_line(o + Vector2(0, 0.5), o + Vector2(w, 0.5), wm.lightened(0.3), 1.0)
			var bx := 6.0
			while bx < w - 4:
				draw_colored_polygon(PackedVector2Array([o + Vector2(bx, 5), o + Vector2(bx + 4, 5), o + Vector2(bx, 11)]), wm.darkened(0.35))
				bx += 40.0
		"wafer":
			var wf := Color(0.93, 0.76, 0.45)
			if crumble:
				wf = Color(0.88, 0.66, 0.38)
			draw_rect(Rect2(o, Vector2(w, 6)), wf)
			var x := 0.0
			while x < w:
				draw_line(o + Vector2(x, 0), o + Vector2(x + 3, 6), wf.darkened(0.2), 1.0)
				x += 4.0
			draw_rect(Rect2(o + Vector2(0, 5), Vector2(w, 1)), wf.darkened(0.35))
			if crumble:
				draw_line(o + Vector2(w * 0.3, 0), o + Vector2(w * 0.4, 6), Color(0.4, 0.25, 0.1), 1.0)
				draw_line(o + Vector2(w * 0.7, 0), o + Vector2(w * 0.62, 6), Color(0.4, 0.25, 0.1), 1.0)
		_:
			draw_rect(Rect2(o, size), Color.MAGENTA)


func _process(_delta: float) -> void:
	# il cioccolato "fuso" in cima ondeggia
	if kind == "choco" and top:
		queue_redraw()
