extends SceneTree
## Cattura alcuni screenshot (serve un display, es. xvfb-run).
##   godot --path snack_and_roll_godot -s tests/screenshots.gd -- <cartella>

var main
var out := "user://"

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	_run.call_deferred()

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _shot(name: String) -> void:
	await _frames(2)
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("salvato ", name)

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(90)
	await _shot("01_titolo")
	Input.action_press("start")
	await _frames(3)
	Input.action_release("start")
	Input.action_press("right")
	await _frames(70)
	Input.action_press("jump")
	await _frames(14)
	await _shot("02_livello1")
	Input.action_release("jump")
	await _frames(150)
	Input.action_release("right")
	await _shot("03_livello1_avanti")
	main.enable_light = false
	await _frames(20)
	await _shot("04_buio")
	main.relight()
	for lv in [2, 3, 4]:
		main.player.global_position = Vector2(main.chunks[lv - 1].origin + 40 * 16, 13 * 16)
		main.level = lv
		main.cam_x = main.player.global_position.x
		await _frames(60)
		await _shot("05_livello%d" % lv)
	main.level = 5
	main.player.global_position = Vector2(main.chunks[4].origin + 70 * 16, 13 * 16)
	main.cam_x = main.player.global_position.x
	main.enable_light = false
	await _frames(60)
	await _shot("06_livello5_buio")
	quit()
