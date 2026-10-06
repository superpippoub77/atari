extends CharacterBody2D
## =====================================================================
##  LA BOCCA  (player1 del BAS - __move_current_mouth)
## ---------------------------------------------------------------------
##  Insegue il biscotto muovendosi di un passo su ciascun asse
##  (if temp3 < player0x then temp3 = temp3 + 1 ...).
##  - bocca 0, livelli < 5: e' bloccata dagli oggetti del playfield
##  - bocca 1 (e tutte dal livello 5): "fantasma", attraversa tutto
##  - livello > 3: NUSIZ1 = $05 -> doppia larghezza
##  - _hitCooldown > 0: la bocca resta ferma
##  - luce spenta: COLUP1 = $0 -> invisibile (qui: nel buio, visibile
##    solo vicino alla luce del biscotto)
## =====================================================================

const D := preload("res://scripts/snack_data.gd")
const Art := preload("res://scripts/art.gd")

var main
var index := 0
var ghost := false
var double := false
var px_speed := 24.0
var chomp := 0.0
var hurt: Area2D
var _bob := 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 8
	collision_mask = 0 if ghost else 1
	add_to_group("mouth")
	var hw := 18.0 if double else 9.0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(hw * 2.0, 12.0)
	cs.shape = r
	add_child(cs)
	hurt = Area2D.new()
	hurt.collision_layer = 0
	hurt.collision_mask = 4
	hurt.monitorable = false
	var hcs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(hw * 2.0 - 4.0, 9.0)
	hcs.shape = hr
	hurt.add_child(hcs)
	add_child(hurt)
	_bob = randf() * TAU


func touches(body: Node) -> bool:
	return is_instance_valid(body) and hurt.overlaps_body(body)


func _physics_process(delta: float) -> void:
	chomp += delta * (9.0 if main.hit_cooldown == 0 else 2.0)
	_bob += delta * 3.0
	queue_redraw()
	if main.player == null or not is_instance_valid(main.player):
		return
	# BAS: if !_hitCooldown && ... then gosub __move_current_mouth
	if main.hit_cooldown > 0 or main.player.frozen:
		return
	var d: Vector2 = main.player.global_position - global_position
	var step := Vector2(_axis(d.x), _axis(d.y)) * px_speed
	if ghost:
		global_position += step * delta
	else:
		velocity = step
		move_and_slide()
	# solo Godot: se resta troppo indietro rientra dal bordo dello schermo
	if d.length() > 560.0:
		global_position = main.mouth_reset_pos(index)


func _axis(v: float) -> float:
	if v > 2.0:
		return 1.0
	if v < -2.0:
		return -1.0
	return 0.0


func _draw() -> void:
	var hw := 18.0 if double else 9.0
	var col: Color = D.pal(D.MOUTH_COLORS[index % D.MOUTH_COLORS.size()]).lightened(0.15)
	var open := absf(sin(chomp))
	var y := sin(_bob) * 1.5
	if main.hit_cooldown > 0:
		col = col.lerp(Color(0.6, 0.8, 1.0), 0.5)
	if ghost:
		col.a = 0.9
	Art.draw_mouth(self, Vector2(0, y), hw, col, open, col.a)
