extends Area2D
## =====================================================================
##  CIOCCOLATINO LANCIATO  (missile0 del BAS - "LANCIO DEI CIOCCOLATINI")
## ---------------------------------------------------------------------
##  - parte nella direzione del biscotto (_Bit4.._Bit7_M0_Dir_*)
##  - uno solo alla volta (_b7_gameMissile0Moving)
##  - colpisce il PIANO centrale o una lampada -> riaccende la luce
##  - colpisce la riga alta di un oggetto -> lo distrugge (score + 1)
##  - colpisce la bocca -> __destroy_mouth (score + 10)
##  - colpisce il muro spingibile -> torna indietro (BAS: _pushCol = 0)
## =====================================================================

const SPEED := 300.0

var main
var dir := Vector2.RIGHT
var life := 1.4
var dead := false
var _spin := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2 | 8 | 32
	monitorable = false
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 3.5
	cs.shape = c
	add_child(cs)
	body_entered.connect(_on_body)
	area_entered.connect(_on_area)
	var trail := CPUParticles2D.new()
	trail.local_coords = false
	trail.amount = 16
	trail.lifetime = 0.25
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_min = 0.0
	trail.initial_velocity_max = 6.0
	trail.scale_amount_min = 1.5
	trail.scale_amount_max = 2.5
	var g := Gradient.new()
	g.set_color(0, Color(0.55, 0.32, 0.16, 0.9))
	g.set_color(1, Color(0.55, 0.32, 0.16, 0.0))
	trail.color_ramp = g
	add_child(trail)


func _physics_process(delta: float) -> void:
	if dead:
		return
	position += dir * SPEED * delta
	_spin += delta * 18.0
	life -= delta
	queue_redraw()
	# BAS: se raggiunge il bordo si elimina
	var cam_x: float = main.cam_x
	if life <= 0.0 or absf(global_position.x - cam_x) > 260.0 or global_position.y < -8.0 or global_position.y > 280.0:
		_finish(false)


func _on_body(body: Node) -> void:
	if dead:
		return
	if body.is_in_group("mouth"):
		main.destroy_mouth(body)
	elif body.is_in_group("shelf"):
		main.relight()
	elif body.get("breakable") == true:
		main.break_block(body)
	elif body.is_in_group("pushable"):
		body.knock_back()
	elif body.is_in_group("player"):
		return
	_finish(true)


func _on_area(area: Area2D) -> void:
	if dead:
		return
	if area.is_in_group("lamp_area"):
		main.relight()
		_finish(true)


func _finish(hit: bool) -> void:
	dead = true
	main.on_missile_done()
	if hit:
		Fx.burst(get_parent(), global_position, Color(0.45, 0.25, 0.12), 8, 70.0, 0.4, 250.0, 2.0)
		Synth.sfx("splash")
	queue_free()


const Fx := preload("res://scripts/fx.gd")


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.2, Color(0.22, 0.11, 0.05))
	draw_circle(Vector2.ZERO, 3.4, Color(0.45, 0.25, 0.12))
	var a := Vector2(cos(_spin), sin(_spin)) * 1.6
	draw_circle(a, 1.0, Color(0.85, 0.65, 0.45))
	draw_line(-a * 1.8, a * 1.8, Color(0.3, 0.15, 0.07), 1.0)
