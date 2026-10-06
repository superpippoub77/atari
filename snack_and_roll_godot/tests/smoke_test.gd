extends SceneTree
## Test automatico di fumo: verifica che le regole portate dal BAS
## funzionino. Uso:
##   godot --headless --path snack_and_roll_godot -s tests/smoke_test.gd

var main
var failures := 0


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		print("  FAIL ", what)
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _tap(index: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	# le coordinate del tocco sono in pixel della finestra
	e.position = root.get_final_transform() * pos
	e.pressed = pressed
	Input.parse_input_event(e)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(30)
	_check(main.state == "title", "parte dalla schermata del titolo")
	_check(main.chunks.size() == 5, "5 livelli costruiti nel mondo")

	# --- avvio partita (switchreset) ---
	Input.action_press("start")
	await _frames(2)
	Input.action_release("start")
	await _frames(5)
	_check(main.state == "playing", "Invio/F2 avvia la partita")
	_check(main.level == 1 and main.speed == 8, "livello 1, _speed = 8")
	_check(main.mouths.size() == 1, "1 bocca al livello 1")
	_check(main.pfscore2 == 0xAA, "4 vite (%10101010)")

	# --- corsa e salto ---
	var x0: float = main.player.global_position.x
	Input.action_press("right")
	await _frames(40)
	Input.action_press("jump")
	await _frames(10)
	Input.action_release("jump")
	await _frames(20)
	Input.action_release("right")
	_check(main.player.global_position.x > x0 + 50.0, "il biscotto corre a destra")
	await _frames(40)
	_check(main.player.is_on_floor(), "il biscotto atterra sul pavimento")

	# --- sparo ---
	main.hit_cooldown = 0
	Input.action_press("fire")
	await _frames(2)
	Input.action_release("fire")
	_check(main.missile_moving, "lancio del cioccolatino")
	await _frames(90)
	_check(not main.missile_moving, "il cioccolatino sparisce")

	# --- zuccherini ---
	var ck: Dictionary = main.chunks[0]
	for s in ck.sugars:
		if is_instance_valid(s):
			main.collect_sugar(s)
	_check(main.choco_count == 8 and main.choco_bits == 0xFF, "8 zuccherini raccolti")
	_check(main.score >= 400, "score + 50 per zuccherino")
	_check(main.hit_cooldown > 0, "zuccherino dorato -> _hitCooldown")
	await _frames(5)
	_check(not ck.bag.shown, "senza colpire la bocca il sacchetto non appare")

	# --- bocca colpita ---
	main.destroy_mouth(main.mouths[0])
	await _frames(3)
	_check(not main.enable_player1, "bocca colpita (_b5_enablePalyer1 = 0)")
	_check(ck.bag.shown, "il sacchetto appare")

	# --- cambio livello ---
	main.player.global_position = ck.bag.global_position
	await _frames(5)
	_check(main.level == 2 and main.in_transition, "il sacchetto porta al livello 2")
	_check(main.speed == 6, "_speed scende di 2")
	_check(main.choco_count == 0 and main.pfscore1 == 0xFF, "contatori azzerati (__skip_to_change)")
	_check(ck.gate.is_open, "il cancello si apre")
	main.player.global_position = Vector2(main.chunks[1].origin + 6 * 16, 13 * 16)
	await _frames(5)
	_check(not main.in_transition and main.mouths.size() == 1, "livello 2 iniziato dopo il cancello")
	await _frames(40)
	_check(not ck.gate.is_open, "il cancello si richiude alle spalle")

	# --- timer e luce ---
	main.seconds_counter = 31
	main.frame_counter = 59
	await _frames(2)
	_check(not main.enable_light, "dopo 32 secondi la luce si spegne")
	main.relight()
	_check(main.enable_light, "la luce si riaccende")
	var bar: int = main.pfscore1
	main.seconds_counter = 15
	main.frame_counter = 59
	await _frames(2)
	_check(main.pfscore1 == ((bar << 1) & 0xFF), "ogni 16 secondi si perde una tacca")

	# --- pozza: livello 2 ha una pozza a x=61 ---
	main.hit_cooldown = 0
	var lives_before: int = main.pfscore2
	main.player.global_position = Vector2(main.chunks[1].origin + 62.5 * 16, 15.5 * 16)
	await _frames(10)
	_check(main.pfscore2 == lives_before >> 2, "la pozza toglie una vita")
	_check(main.player.global_position.y < 15 * 16, "respawn al checkpoint")

	# --- game over ---
	main.hit_cooldown = 0
	while main.state == "playing":
		main.hit_cooldown = 0
		main.decrease_health_bar()
	_check(main.state == "gameover", "senza vite -> game over")
	main.state_timer = 0.0
	await _frames(3)
	_check(main.state == "title", "dopo il game over torna al titolo")

	# --- selezione livello + vittoria ---
	for i in 4:
		Input.action_press("select")
		await _frames(2)
		Input.action_release("select")
		await _frames(2)
	_check(main.choco_count == 4, "Tab/F1 sceglie il livello 5")
	Input.action_press("start")
	await _frames(2)
	Input.action_release("start")
	await _frames(5)
	_check(main.level == 5 and main.speed == 0, "partenza dal livello 5, _speed = 0")
	_check(not main.enable_light, "il livello 5 inizia al buio")
	_check(main.mouths.size() == 2, "2 bocche dal livello 4")
	_check(main.chunks[4].push != null, "muro spingibile al livello 5")
	await _frames(120)
	main.change_level()
	await _frames(3)
	_check(main.state == "victory", "oltre il livello 5 -> vittoria")

	# --- controlli touch (versione mobile) ---
	main._go_title()
	await _frames(3)
	_tap(0, Vector2(240 - 70 + 1 * 28 + 11, 160), true)
	_tap(0, Vector2(240 - 70 + 1 * 28 + 11, 160), false)
	await _frames(2)
	_check(main.choco_count == 1, "touch: tocco sul numero 2 sceglie il livello 2")
	_tap(0, Vector2(240, 60), true)
	_tap(0, Vector2(240, 60), false)
	await _frames(3)
	_check(main.state == "playing" and main.level == 2, "touch: tocco sul titolo avvia la partita")
	_tap(1, Vector2(440, 196), true)
	await _frames(2)
	_check(Input.is_action_pressed("jump"), "touch: il pulsante SALTA preme jump")
	_tap(1, Vector2(440, 196), false)
	await _frames(2)
	_check(not Input.is_action_pressed("jump"), "touch: rilasciando si rilascia jump")

	print("")
	print("RISULTATO: ", "TUTTO OK" if failures == 0 else "%d FALLIMENTI" % failures)
	quit(1 if failures > 0 else 0)
