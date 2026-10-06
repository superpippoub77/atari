extends CharacterBody2D
## =====================================================================
##  BISCO, IL BISCOTTO  (player0 del BAS)
## ---------------------------------------------------------------------
##  BAS: __skip_up/__skip_down/__skip_left/__skip_right muovono il
##  biscotto di 1 pixel in 8 direzioni. Qui diventa un platform:
##  corsa, salto, "roll" (doppio salto), rotolamento.
##  Lo slow motion del BAS (_b6_enableSlowMotion: si muove 1 frame su 4)
##  riduce velocita' e salto.
## =====================================================================

const D := preload("res://scripts/snack_data.gd")
const Art := preload("res://scripts/art.gd")
const Fx := preload("res://scripts/fx.gd")

const SPEED := 125.0
const SLOW_FACTOR := 0.4
const ACCEL := 1100.0
const AIR_ACCEL := 820.0
const FRICTION := 1300.0
const GRAVITY := 980.0
const JUMP_V := -370.0
const ROLL_JUMP_V := -325.0
const MAX_FALL := 470.0
const COYOTE := 0.1
const BUFFER := 0.12
const RADIUS := 7.0
const PUSH_SPEED := 50.0

var main
var facing := 1            # BAS: _Bit2_P0_Dir_Left / _Bit3_P0_Dir_Right
var slow := false          # BAS: _b6_enableSlowMotion
var blink := false         # BAS: _hitCooldown && _frame_counter&4
var frozen := false
var can_double := true
var coyote_t := 0.0
var buffer_t := 0.0
var roll_angle := 0.0
var squash := Vector2.ONE
var was_on_floor := false
var launch_v := 0.0
var light: PointLight2D
var _blink_t := 0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 2
	floor_snap_length = 4.0
	floor_max_angle = deg_to_rad(50.0)
	add_to_group("player")
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = RADIUS
	cs.shape = c
	add_child(cs)
	light = PointLight2D.new()
	light.texture = main.light_tex
	light.texture_scale = 0.6
	light.energy = 0.0
	light.color = Color(1.0, 0.86, 0.62)
	add_child(light)


func _physics_process(delta: float) -> void:
	_blink_t += 1
	if frozen:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		move_and_slide()
		queue_redraw()
		return
	var dir := Input.get_axis("left", "right")
	var max_speed := SPEED * (SLOW_FACTOR if slow else 1.0)
	if dir > 0.1:
		facing = 1
	elif dir < -0.1:
		facing = -1
	var on_floor := is_on_floor()
	if on_floor:
		coyote_t = COYOTE
		can_double = true
	else:
		coyote_t -= delta
	if Input.is_action_just_pressed("jump"):
		buffer_t = BUFFER
	else:
		buffer_t -= delta

	var accel := ACCEL if on_floor else AIR_ACCEL
	if absf(dir) > 0.1:
		velocity.x = move_toward(velocity.x, dir * max_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, (FRICTION if on_floor else AIR_ACCEL * 0.5) * delta)
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)

	var jmul := 0.8 if slow else 1.0
	if buffer_t > 0.0 and coyote_t > 0.0:
		_jump(JUMP_V * jmul, false)
	elif buffer_t > 0.0 and can_double and not on_floor:
		can_double = false
		_jump(ROLL_JUMP_V * jmul, true)
	if Input.is_action_just_released("jump") and velocity.y < -120.0:
		velocity.y *= 0.55
	if launch_v != 0.0:
		velocity.y = launch_v
		launch_v = 0.0
		can_double = true
		squash = Vector2(0.7, 1.35)

	move_and_slide()

	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var other = col.get_collider()
		if other == null:
			continue
		var n := col.get_normal()
		# BAS: if pfread(...) then _b6_enableSlowMotion{6} = 1
		if other.is_in_group("sticky"):
			main.set_slow_motion()
		if other.is_in_group("pushable") and absf(n.x) > 0.7 and absf(dir) > 0.1 and signf(dir) == -signf(n.x):
			other.push(signf(dir) * PUSH_SPEED * delta)
		if n.y < -0.7 and other.has_method("on_stood"):
			other.on_stood()

	if is_on_floor() and not was_on_floor:
		squash = Vector2(1.35, 0.7)
		Fx.burst(get_parent(), global_position + Vector2(0, RADIUS), Color(1, 1, 1, 0.6), 6, 40.0, 0.35, 60.0, 1.5)
	was_on_floor = is_on_floor()
	roll_angle += velocity.x * delta / RADIUS
	squash = squash.lerp(Vector2.ONE, minf(1.0, 12.0 * delta))
	queue_redraw()


func _jump(v: float, is_roll: bool) -> void:
	velocity.y = v
	buffer_t = 0.0
	coyote_t = 0.0
	squash = Vector2(0.72, 1.3)
	Synth.sfx("double" if is_roll else "jump")
	var c := Color(1.0, 0.85, 0.4, 0.8) if is_roll else Color(1, 1, 1, 0.6)
	Fx.burst(get_parent(), global_position + Vector2(0, RADIUS), c, 8 if is_roll else 5, 50.0, 0.35, 80.0, 1.6)


## Spinta verso l'alto (vapore delle tazze)
func launch(v: float) -> void:
	launch_v = v


func knockback(from_x: float) -> void:
	velocity = Vector2(signf(global_position.x - from_x) * 160.0, -220.0)


func respawn(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	frozen = false


func _draw() -> void:
	var col: Color = D.pal(D.P0_COLOR)
	if slow:
		col = Color(0.55, 0.32, 0.16)   # BAS: COLUP0 = $20 in slow motion
	var alpha := 1.0
	if blink and (_blink_t / 4) % 2 == 0:
		alpha = 0.25                     # BAS: COLUP0 = $00 a frame alterni
	if frozen:
		col = col.darkened(0.4)
	draw_set_transform(Vector2(0, (1.0 - squash.y) * RADIUS), 0.0, squash)
	Art.draw_cookie(self, Vector2.ZERO, RADIUS, col, roll_angle, facing, alpha)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if slow:
		var t := Time.get_ticks_msec() / 300.0
		for i in 3:
			var p := Vector2(-RADIUS + i * RADIUS, RADIUS + 1.0 + absf(sin(t + i)) * 2.0)
			draw_circle(p, 1.4, Color(0.35, 0.18, 0.08, 0.9))
