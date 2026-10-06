extends Area2D
## =====================================================================
##  ZUCCHERINO  (missile1 del BAS - "ZUCCHERINI")
## ---------------------------------------------------------------------
##  Nel BAS un solo missile1 viene riposizionato a turno sugli 8
##  zuccherini (inganno dell'occhio). Qui ogni zuccherino e' un nodo.
##  index 0 = dorato, index 1 = chiave (vedi main.collect_sugar)
## =====================================================================

const Art := preload("res://scripts/art.gd")

var main
var index := 0
var draw_kind := 0     # 0 normale, 1 dorato, 2 chiave
var collected := false
var _t := 0.0
var _base_y := 0.0


func _ready() -> void:
	collision_layer = 16
	collision_mask = 4
	monitorable = false
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 6.0
	cs.shape = c
	add_child(cs)
	body_entered.connect(_on_body)
	_t = float(index) * 0.7
	_base_y = position.y


func _process(delta: float) -> void:
	_t += delta
	if not collected:
		position.y = _base_y + sin(_t * 2.5) * 2.0
	queue_redraw()


func _on_body(body: Node) -> void:
	if collected or body != main.player:
		return
	collected = true
	main.collect_sugar(self)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(2.2, 2.2), 0.25)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(queue_free)


func _draw() -> void:
	# alone luminoso
	var glow := Color(1, 1, 1, 0.10 + 0.05 * sin(_t * 4.0))
	if draw_kind == 1:
		glow = Color(1, 0.85, 0.3, 0.18)
	elif draw_kind == 2:
		glow = Color(0.5, 0.85, 1.0, 0.18)
	draw_circle(Vector2.ZERO, 9.0, glow)
	Art.draw_sugar(self, Vector2.ZERO, draw_kind, _t)
