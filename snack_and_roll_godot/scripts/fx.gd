extends RefCounted
## Effetti speciali usa-e-getta: esplosioni di particelle e scritte
## fluttuanti (es. "+50"). Solo Godot: nessun equivalente nel BAS.


static func burst(parent: Node, pos: Vector2, color: Color, amount: int = 12, speed: float = 90.0,
		life: float = 0.6, grav: float = 300.0, size: float = 2.0, spread: float = 180.0,
		dir: Vector2 = Vector2.UP) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 0.92
	p.amount = maxi(amount, 1)
	p.lifetime = life
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, grav)
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	var g := Gradient.new()
	g.set_color(0, color)
	g.set_color(1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = g
	parent.add_child(p)
	p.emitting = true
	p.get_tree().create_timer(life + 0.4, false).timeout.connect(p.queue_free)


static func popup(parent: Node, pos: Vector2, text: String, color: Color = Color.WHITE, size: int = 11) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(80, 16)
	l.position = pos - Vector2(40, 10)
	l.z_index = 50
	parent.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 22.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.35)
	tw.chain().tween_callback(l.queue_free)
