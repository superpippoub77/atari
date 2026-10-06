extends Area2D
## =====================================================================
##  SACCHETTO FINALE  (ball del BAS - "CONTENITORE FINALE")
## ---------------------------------------------------------------------
##  BAS: if _choco_count = 8 && !_b5_enablePalyer1{5} && temp4 then
##         ballx = objects[...+7] : bally = 28
##  Appare dopo 8 zuccherini + bocca colpita (+ chiave dal livello 4).
##  Toccarlo -> __change_level.
## =====================================================================

var main
var shown := false
var taken := false
var _t := 0.0
var _light: PointLight2D


func _ready() -> void:
	collision_layer = 16
	collision_mask = 4
	monitorable = false
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(20, 24)
	cs.shape = r
	add_child(cs)
	body_entered.connect(_on_body)
	_light = PointLight2D.new()
	_light.texture = main.light_tex
	_light.texture_scale = 0.8
	_light.color = Color(1.0, 0.85, 0.4)
	_light.energy = 0.0
	add_child(_light)
	visible = false


func appear() -> void:
	if shown:
		return
	shown = true
	visible = true
	scale = Vector2(0.1, 0.1)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_light.energy = 0.9
	# se il biscotto ci sta gia' sopra
	for b in get_overlapping_bodies():
		_on_body(b)


func hide_bag() -> void:
	visible = false
	_light.energy = 0.0


func _process(delta: float) -> void:
	_t += delta
	if shown:
		queue_redraw()


func _on_body(body: Node) -> void:
	if not shown or taken or body != main.player:
		return
	taken = true
	main.change_level.call_deferred()


func _draw() -> void:
	if not shown:
		return
	var a := 0.18 + 0.08 * sin(_t * 3.0)
	draw_rect(Rect2(-14, -120, 28, 120), Color(1, 0.9, 0.5, a * 0.5))
	draw_circle(Vector2(0, 0), 20.0 + sin(_t * 3.0) * 2.0, Color(1, 0.85, 0.4, a))
	var y := sin(_t * 2.0) * 2.0
	var body := PackedVector2Array([Vector2(-10, -9 + y), Vector2(10, -9 + y), Vector2(12, 12 + y), Vector2(-12, 12 + y)])
	draw_colored_polygon(body, Color(0.78, 0.6, 0.38))
	draw_rect(Rect2(-10, -13 + y, 20, 5), Color(0.68, 0.5, 0.3))
	for i in 5:
		draw_line(Vector2(-10 + i * 5, -13 + y), Vector2(-8 + i * 5, -8 + y), Color(0.55, 0.4, 0.22), 1.0)
	draw_circle(Vector2(0, 2 + y), 5.5, Color(0.9, 0.65, 0.25))
	draw_circle(Vector2(-2, 1 + y), 1.0, Color(0.3, 0.15, 0.07))
	draw_circle(Vector2(2, 3 + y), 1.0, Color(0.3, 0.15, 0.07))
	draw_circle(Vector2(1, -0.5 + y), 0.9, Color(0.3, 0.15, 0.07))
	for i in 3:
		var ang := _t * 2.0 + float(i) * TAU / 3.0
		var p := Vector2(cos(ang) * 16.0, sin(ang) * 8.0 + y)
		draw_circle(p, 1.3, Color(1, 1, 0.7, 0.9))
