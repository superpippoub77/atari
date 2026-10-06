extends Node2D
## =====================================================================
##  SNACK 'N' ROLL - versione Godot 4 (platform 2D a scorrimento)
## ---------------------------------------------------------------------
##  Porting di "Snack and Roll.bas" (batari Basic, Atari 2600).
##  Questo script e' l'equivalente di __main_loop: contiene TUTTE le
##  variabili del BAS con lo stesso significato (vedi PORTING.md) e le
##  stesse regole. Le parti marcate "solo Godot" sono estensioni.
## =====================================================================

const D := preload("res://scripts/snack_data.gd")
const Builder := preload("res://scripts/level_builder.gd")
const PlayerScript := preload("res://scripts/player.gd")
const MouthScript := preload("res://scripts/mouth.gd")
const ProjectileScript := preload("res://scripts/projectile.gd")
const HudScript := preload("res://scripts/hud.gd")
const BgScript := preload("res://scripts/background.gd")
const Fx := preload("res://scripts/fx.gd")
const TouchScript := preload("res://scripts/touch_controls.gd")

const SAVE_PATH := "user://snack_and_roll.cfg"

## "title" | "playing" | "gameover" | "victory"   (BAS: _b0_enableStart)
var state := "title"

# ---------------------------------------------------------------------
# VARIABILI DEL BAS (stesso nome, stesso significato)
# ---------------------------------------------------------------------
var level := 1               # _level          (b)
var frame_counter := 0       # _frame_counter  (c)
var seconds_counter := 0     # _seconds_counter(d)
var choco_count := 0         # _choco_count    (t) - sul titolo: livello scelto - 1
var choco_bits := 0          # _choco_bits     (e)
var speed := D.START_SPEED   # _speed          (g)
var enable_light := true     # _b4_enableLight
var enable_player1 := true   # _b5_enablePalyer1 (true = bocca non ancora colpita)
var slow_motion := false     # _b6_enableSlowMotion
var missile_moving := false  # _b7_gameMissile0Moving
var hit_cooldown := 0        # _hitCooldown    (v)
var has_key := false         # _hasKey         (z)
var music_index := 0         # _music_index    (m)
var attract_x := 10          # player0x nella modalita' attract
var attract_dir := 0         # _attractDir     (y)
var attract_timer := 0       # _attractTimer   (s)
var score := 0               # score
var scorecolor := 0x10       # scorecolor
var pfscore1 := D.PFSCORE1_FULL   # barra del tempo
var pfscore2 := D.PFSCORE2_FULL   # vite

# ---------------------------------------------------------------------
# solo Godot
# ---------------------------------------------------------------------
var world: Node2D
var camera: Camera2D
var canvas_mod: CanvasModulate
var hud
var background
var touch
var player = null
var mouths: Array = []
var chunks: Array = []
var in_transition := false
var golden_rush := false
var light_tex: Texture2D
var cam_x := 240.0
var shake_amt := 0.0
var state_timer := 0.0
var hiscore := 0
var last_score := 0
var _hint_mouth_shown := false
var _title_t := 0.0
var _fall_lock := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	_setup_input()
	light_tex = _make_light_texture()
	canvas_mod = CanvasModulate.new()
	add_child(canvas_mod)
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = HudScript.new()
	hud.main = self
	layer.add_child(hud)
	touch = TouchScript.new()
	touch.main = self
	layer.add_child(touch)
	_load_hiscore()
	_go_title()


# =====================================================================
# __main_loop
# =====================================================================
func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	# --- TIMER ---
	frame_counter += 1
	var new_second := false
	if frame_counter > D.FRAME_LIMIT:
		frame_counter = 0
		if state != "playing" or not in_transition:
			seconds_counter += 1
			new_second = true

	match state:
		"title":
			_title_tick(delta)
		"playing":
			_game_tick(new_second)
		_:
			state_timer -= delta
			if state_timer <= 0.0 or (state_timer < 2.5 and Input.is_action_just_pressed("start")):
				_go_title()
	_music_tick()
	_update_camera(delta)
	_update_light_visuals()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and state == "playing":
		get_tree().paused = not get_tree().paused
	elif event.is_action_pressed("mute"):
		Synth.toggle_mute()


# ---------------------------------------------------------------------
# TITOLO / ATTRACT MODE  (BAS: __attract_mode)
# ---------------------------------------------------------------------
func _title_tick(delta: float) -> void:
	_title_t += delta
	if frame_counter % 4 == 0:
		attract_timer = (attract_timer + 1) & 0xFF
	if not (attract_timer >= 55 and attract_timer <= 70):
		if frame_counter % 4 == 0:
			attract_x += -1 if attract_dir else 1
		if attract_x > 140:
			attract_dir = 1
		if attract_x < 10:
			attract_dir = 0
			attract_timer = 0
	# BAS: switchselect -> _choco_count + 1 (0..4)
	if Input.is_action_just_pressed("select"):
		choco_count = (choco_count + 1) % D.MAX_LEVEL
		Synth.sfx("select")
		_build_world()
	# BAS: switchreset -> inizia la partita
	if Input.is_action_just_pressed("start"):
		_start_game()


func _go_title() -> void:
	get_tree().paused = false
	state = "title"
	in_transition = false
	enable_light = true      # BAS: __game_start -> _b4_enableLight{4} = 1
	slow_motion = false
	hit_cooldown = 0
	choco_count = 0          # BAS: missile1y = 200 : _choco_count = 0
	music_index = 0
	attract_x = 10
	attract_dir = 0
	attract_timer = 0
	hud.clear_messages()
	_build_world()
	player = null


func _start_game() -> void:
	Synth.sfx("start")
	# BAS: _level = _choco_count+1 : _speed = 8 : score = 0
	level = choco_count + 1
	score = 0
	scorecolor = 0x10
	# BAS: __handle_level_select
	speed = D.speed_for_level(level)
	enable_light = true
	_build_world()
	state = "playing"
	_skip_to_change()
	var ck: Dictionary = chunks[level - 1]
	player = PlayerScript.new()
	player.main = self
	player.position = ck.checkpoint
	world.add_child(player)
	cam_x = ck.origin + D.VIEW_W * 0.5
	_begin_level()


# ---------------------------------------------------------------------
# GIOCO
# ---------------------------------------------------------------------
func _game_tick(new_second: bool) -> void:
	if player == null:
		return
	if _fall_lock > 0:
		_fall_lock -= 1
	# BAS: if _hitCooldown then _hitCooldown = _hitCooldown - 1
	if hit_cooldown > 0:
		hit_cooldown -= 1
		if hit_cooldown == 0:
			golden_rush = false
	player.slow = slow_motion
	player.blink = hit_cooldown > 0 and not golden_rush

	if in_transition:
		var ck: Dictionary = chunks[level - 1]
		if player.global_position.x > ck.origin + 3.5 * D.TILE:
			chunks[level - 2].gate.close()
			_begin_level()
	elif new_second:
		_on_second()

	# --- CONTENITORE FINALE (BAS: temp4 / ballx) ---
	if not in_transition:
		var key_ok := level <= 3 or has_key
		var bag = chunks[level - 1].bag
		if choco_count >= 8 and not enable_player1 and key_ok and not bag.shown:
			bag.appear()
			Synth.sfx("bag")
			hud.show_message("IL SACCHETTO E' APPARSO!", Color(1, 0.85, 0.35))
		elif choco_count >= 8 and enable_player1 and not _hint_mouth_shown:
			_hint_mouth_shown = true
			hud.show_message("Ora colpisci una Bocca con un cioccolatino!", Color(1, 0.6, 0.6), 3.0, false)

	# --- LANCIO (BAS: joy0fire, non in slow motion, uno alla volta) ---
	if Input.is_action_just_pressed("fire") and not missile_moving and not slow_motion and not player.frozen:
		_fire()

	# --- COLLISIONI bocca/biscotto (BAS: !_hitCooldown && collision(player0, player1)) ---
	if hit_cooldown == 0:
		for m in mouths:
			if m.touches(player):
				decrease_health_bar()
				break

	if player.global_position.y > D.VIEW_H + 24:
		player_fell()


## Controlli eseguiti a ogni cambio di secondo (BAS: CHECK 1, 4, 5 e LUCE)
func _on_second() -> void:
	# LUCE: dopo 32 secondi si spegne
	if seconds_counter % 32 == 0 and enable_light:
		enable_light = false
		Synth.sfx("lightoff")
		hud.show_message("LUCE SPENTA!", Color(1, 0.5, 0.5))
		hud.show_message("Spara sul piano di lavoro o tocca una lampada", Color(1, 1, 1, 0.9), 3.0, false)
	# 5) ogni 8 secondi finisce lo slow motion
	if seconds_counter % 8 == 0:
		slow_motion = false
	# 1) ogni 16 secondi si perde una tacca di tempo
	if seconds_counter % 16 == 0:
		_decrease_timer_bar()


# ---------------------------------------------------------------------
# DINAMICHE PUNTEGGI DI GIOCO (stesse label del BAS)
# ---------------------------------------------------------------------

## __decrease_timer_bar
func _decrease_timer_bar() -> void:
	pfscore1 = (pfscore1 << 1) & 0xFF
	# 2) se la barra e' finita si perde una vita
	if pfscore1 == 0:
		decrease_health_bar()


## __decrease_health_bar
func decrease_health_bar() -> void:
	if state != "playing":
		return
	pfscore2 = pfscore2 >> 2
	pfscore1 = D.PFSCORE1_FULL
	hit_cooldown = D.HIT_COOLDOWN_HURT
	golden_rush = false
	shake(7.0)
	Synth.sfx("hurt")
	if player:
		Fx.burst(world, player.global_position, D.pal(D.P0_COLOR), 18, 120.0, 0.7, 400.0, 2.5)
	# 3) senza vite il gioco e' finito
	if pfscore2 == 0:
		_game_over()


## __destroy_mouth
func destroy_mouth(m) -> void:
	score += 10
	enable_player1 = false
	Synth.sfx("mouth")
	shake(4.0)
	Fx.burst(world, m.global_position, D.pal(D.MOUTH_COLORS[m.index % 2]), 24, 150.0, 0.8, 300.0, 3.0)
	Fx.popup(world, m.global_position, "+10", Color(1, 0.6, 0.6))
	# __reset_mouth_pos
	m.global_position = mouth_reset_pos(m.index)


## BAS: if !_mouthIndex then _mouth0x=20 : _mouth0y=8  else 140,90
func mouth_reset_pos(index: int) -> Vector2:
	var left := cam_x - D.VIEW_W * 0.5
	if index == 0:
		return Vector2(left + 30.0, 40.0)
	return Vector2(left + D.VIEW_W - 30.0, 225.0)


## ZUCCHERINI: collision(player0, missile1)
func collect_sugar(s) -> void:
	if not is_instance_valid(s) or state != "playing":
		return
	var bit: int = D.BITTABLE[s.index]
	if choco_bits & bit:
		return
	choco_bits |= bit
	choco_count += 1
	score += 50
	Synth.sfx("sugar")
	Fx.burst(world, s.global_position, Color(1, 1, 1), 14, 90.0, 0.5, 100.0, 2.0)
	Fx.popup(world, s.global_position, "+50", Color(1, 1, 0.8))
	if bit == 1:
		# BAS: if _prevSugarBit=1 then _hitCooldown=120
		hit_cooldown = D.HIT_COOLDOWN_GOLDEN
		golden_rush = true
		Synth.sfx("golden")
		hud.show_message("SUGAR RUSH! Bocche congelate", Color(1, 0.85, 0.3), 2.0, false)
	elif bit == 2:
		# BAS: if _prevSugarBit=2 then _hasKey=1
		has_key = true
		if level > 3:
			Synth.sfx("key")
			hud.show_message("HAI LA CHIAVE!", Color(0.55, 0.85, 1.0), 2.0, false)


## Il cioccolatino colpisce un pixel distruttibile (score + 1)
func break_block(b) -> void:
	score += 1
	Synth.sfx("break")
	b.break_apart()


## BAS: if temp6 = 5 && pfread(...) then _b4_enableLight{4}=1
func relight() -> void:
	if enable_light or state != "playing":
		return
	enable_light = true
	Synth.sfx("lighton")
	hud.show_message("LUCE!", Color(1, 1, 0.6), 1.2)


func set_slow_motion() -> void:
	if slow_motion or state != "playing":
		return
	slow_motion = true
	Synth.sfx("slow")
	hud.show_message("Cioccolato appiccicoso: rallentato!", Color(0.9, 0.6, 0.35), 1.8, false)


## Trabocchetti (coltelli): come la bocca, costano una vita
func hurt_player(from_x: float) -> void:
	if hit_cooldown > 0 or state != "playing":
		return
	decrease_health_bar()
	if player and state == "playing":
		player.knockback(from_x)


## Caduta in una pozza: si perde una vita e si riparte dal checkpoint
func player_fell() -> void:
	if state != "playing" or player == null or _fall_lock > 0:
		return
	_fall_lock = 15
	Synth.sfx("fall")
	Fx.burst(world, player.global_position, Color(0.6, 0.3, 0.1), 20, 140.0, 0.8, 300.0, 3.0)
	var idx := clampi(int(floor(player.global_position.x / D.CHUNK_PX)), 0, D.MAX_LEVEL - 1)
	idx = clampi(idx, level - 2 if in_transition else level - 1, level - 1)
	player.respawn(chunks[idx].checkpoint)
	decrease_health_bar()


func _fire() -> void:
	missile_moving = true
	var dir := Vector2(player.facing, 0)
	if Input.is_action_pressed("aim_up"):
		dir = Vector2.UP
	elif Input.is_action_pressed("aim_down") and not player.is_on_floor():
		dir = Vector2.DOWN
	var p := ProjectileScript.new()
	p.main = self
	p.dir = dir
	p.position = player.global_position + dir * 6.0
	world.add_child(p)
	Synth.sfx("shoot")


func on_missile_done() -> void:
	missile_moving = false


## __change_level (il biscotto tocca il sacchetto)
func change_level() -> void:
	if state != "playing" or in_transition:
		return
	Synth.sfx("level")
	var old: Dictionary = chunks[level - 1]
	Fx.burst(world, old.bag.global_position, Color(1, 0.85, 0.4), 40, 180.0, 1.0, 150.0, 3.0)
	old.bag.hide_bag()
	level += 1
	# BAS: if _speed<2 then goto __skip_to_change : _speed=_speed-2
	if speed >= 2:
		speed -= 2
	# BAS: if _level > 5 then goto __game_start
	if level > D.MAX_LEVEL:
		_victory()
		return
	_skip_to_change()
	old.gate.open()
	in_transition = true
	_clear_mouths()
	hud.show_message("LIVELLO COMPLETATO!", Color(0.6, 1, 0.6))
	hud.show_message("Il cancello e' aperto: vai a destra  >>>", Color(1, 1, 1), 3.0, false)


## __skip_to_change
func _skip_to_change() -> void:
	scorecolor = (scorecolor + 0x10) & 0xF0
	pfscore1 = D.PFSCORE1_FULL
	pfscore2 = D.PFSCORE2_FULL
	enable_player1 = true
	choco_count = 0
	choco_bits = 0
	has_key = false
	_hint_mouth_shown = false
	missile_moving = false
	# BAS: _pushCol=13
	var ck: Dictionary = chunks[level - 1]
	if ck.push:
		ck.push.position.x = ck.push.origin_x
	# BAS: if _level=5 then _b4_enableLight{4}=0
	if level == 5:
		enable_light = false
	seconds_counter = 0


## solo Godot: il livello "parte" quando il biscotto entra nel suo tratto
func _begin_level() -> void:
	in_transition = false
	seconds_counter = 0
	frame_counter = 0
	_spawn_mouths()
	var th: Dictionary = D.theme(level)
	hud.show_message("LIVELLO %d" % level, Color(1, 0.9, 0.5), 2.5)
	hud.show_message(th.name, Color(1, 1, 1, 0.9), 2.5, false)


func _spawn_mouths() -> void:
	_clear_mouths()
	for i in D.mouth_count(level):
		var m := MouthScript.new()
		m.main = self
		m.index = i
		m.ghost = D.mouth_is_ghost(level, i)
		m.double = D.mouth_double(level)
		m.px_speed = D.mouth_speed(speed)
		m.position = mouth_reset_pos(i)
		world.add_child(m)
		mouths.append(m)


func _clear_mouths() -> void:
	for m in mouths:
		if is_instance_valid(m):
			m.queue_free()
	mouths.clear()


func _game_over() -> void:
	state = "gameover"
	state_timer = 6.0
	last_score = score
	_save_hiscore()
	Synth.sfx("gameover")
	if player:
		player.frozen = true
	_clear_mouths()


func _victory() -> void:
	state = "victory"
	state_timer = 8.0
	last_score = score
	_save_hiscore()
	Synth.sfx("victory")
	_clear_mouths()
	if player:
		player.frozen = true
		for i in 6:
			var p: Vector2 = player.global_position + Vector2(randf_range(-150, 150), randf_range(-120, -20))
			Fx.burst(world, p, Color.from_hsv(randf(), 0.7, 1.0), 30, 160.0, 1.2, 120.0, 3.0)


# ---------------------------------------------------------------------
# MUSICHE (BAS: jingle sul titolo, melody in gioco)
# ---------------------------------------------------------------------
func _music_tick() -> void:
	if music_index >= D.MELODY.size():
		music_index = 0
	if state == "title" and frame_counter % D.MUSIC_STEP_TITLE == 0:
		Synth.note(D.JINGLE[music_index])
		music_index += 1
	elif state == "playing" and frame_counter % D.MUSIC_STEP_GAME == 0:
		Synth.note(D.MELODY[music_index])
		music_index += 1


# ---------------------------------------------------------------------
# MONDO, CAMERA, LUCE
# ---------------------------------------------------------------------
func _build_world() -> void:
	_clear_mouths()
	if world:
		remove_child(world)
		world.queue_free()
	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	move_child(world, 0)
	background = BgScript.new()
	background.main = self
	world.add_child(background)
	chunks = []
	for lv in range(1, D.MAX_LEVEL + 1):
		var b := Builder.new(world, self, lv, float(lv - 1) * D.CHUNK_PX, lv == 1)
		chunks.append(b.build())
	missile_moving = false


func current_theme() -> Dictionary:
	if state == "title":
		return D.theme(choco_count + 1)
	return D.theme(clampi(int(floor(cam_x / D.CHUNK_PX)) + 1, 1, D.MAX_LEVEL))


func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount)


func _update_camera(delta: float) -> void:
	var half := D.VIEW_W * 0.5
	if state == "title":
		var ox: float = chunks[choco_count].origin
		cam_x = ox + half + (0.5 - 0.5 * cos(_title_t * 0.12)) * (D.CHUNK_PX - D.VIEW_W)
	elif player:
		var li := clampi(level, 1, D.MAX_LEVEL) - 1
		var lim_l: float = chunks[li - 1].origin if in_transition and li > 0 else chunks[li].origin
		var lim_r: float = chunks[li].origin + D.CHUNK_PX
		var target: float = player.global_position.x + player.facing * 40.0
		target = clampf(target, lim_l + half, lim_r - half)
		cam_x = lerpf(cam_x, target, 1.0 - exp(-6.0 * delta))
	shake_amt = move_toward(shake_amt, 0.0, 25.0 * delta)
	var sh := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt
	camera.position = Vector2(cam_x, D.VIEW_H * 0.5) + sh


## BAS: pfcolors normali / nero, con un fotogramma di flash ogni 32
func _update_light_visuals() -> void:
	var dark := not enable_light and state != "title"
	var target := Color(1, 1, 1)
	if dark:
		target = Color(0.07, 0.06, 0.11)
		if frame_counter % 32 < 2:
			target = Color(0.45, 0.42, 0.55)   # flash: si intravede tutto
	canvas_mod.color = canvas_mod.color.lerp(target, 0.25 if not dark or target.r < 0.2 else 1.0)
	if player:
		player.light.energy = 1.3 if dark else 0.0
	get_tree().call_group("lamps", "set_lit", enable_light)


func _make_light_texture() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 256
	t.height = 256
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


# ---------------------------------------------------------------------
# INPUT (equivalenti degli switch/joystick dell'Atari)
# ---------------------------------------------------------------------
func _setup_input() -> void:
	_bind("left", [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT], [JOY_AXIS_LEFT_X, -1.0])
	_bind("right", [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT], [JOY_AXIS_LEFT_X, 1.0])
	_bind("aim_up", [KEY_UP, KEY_W], [JOY_BUTTON_DPAD_UP], [JOY_AXIS_LEFT_Y, -1.0])
	_bind("aim_down", [KEY_DOWN, KEY_S], [JOY_BUTTON_DPAD_DOWN], [JOY_AXIS_LEFT_Y, 1.0])
	_bind("jump", [KEY_SPACE, KEY_Z, KEY_K], [JOY_BUTTON_A], [])
	_bind("fire", [KEY_X, KEY_J, KEY_CTRL], [JOY_BUTTON_X, JOY_BUTTON_B], [])   # joy0fire
	_bind("start", [KEY_ENTER, KEY_KP_ENTER, KEY_F2], [JOY_BUTTON_START], [])   # switchreset
	_bind("select", [KEY_TAB, KEY_F1], [JOY_BUTTON_BACK], [])                   # switchselect
	_bind("pause", [KEY_P, KEY_ESCAPE], [], [])
	_bind("mute", [KEY_M], [], [])


func _bind(action: String, keys: Array, buttons: Array, axis: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.4)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	for b in buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = b
		InputMap.action_add_event(action, jb)
	if axis.size() == 2:
		var jm := InputEventJoypadMotion.new()
		jm.axis = axis[0]
		jm.axis_value = axis[1]
		InputMap.action_add_event(action, jm)


func _load_hiscore() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		hiscore = int(cf.get_value("score", "hiscore", 0))


func _save_hiscore() -> void:
	if score <= hiscore:
		return
	hiscore = score
	var cf := ConfigFile.new()
	cf.set_value("score", "hiscore", hiscore)
	cf.save(SAVE_PATH)
