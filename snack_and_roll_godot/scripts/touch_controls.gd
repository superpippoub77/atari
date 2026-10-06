extends Node2D
## =====================================================================
##  CONTROLLI TOUCH (versione mobile, solo Godot)
## ---------------------------------------------------------------------
##  Pulsanti virtuali che premono le stesse azioni della tastiera
##  (left, right, jump, fire, aim_up, pause). Sul titolo: tocca un
##  numero per scegliere il livello, tocca altrove per iniziare.
##  Compaiono solo su schermi touch (o dopo il primo tocco).
## =====================================================================

const D := preload("res://scripts/snack_data.gd")

var main
## nome azione -> [centro, raggio, etichetta]
var buttons := {
	"left": [Vector2(40, 226), 26.0, "<"],
	"right": [Vector2(102, 226), 26.0, ">"],
	"aim_up": [Vector2(366, 176), 18.0, "^"],
	"fire": [Vector2(380, 230), 24.0, "SPARA"],
	"jump": [Vector2(440, 196), 28.0, "SALTA"],
	"pause": [Vector2(464, 44), 12.0, "II"],
}
var _touches := {}   # indice del dito -> azione premuta ("" se nessuna)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = DisplayServer.is_touchscreen_available()


func _button_at(p: Vector2) -> String:
	for action in buttons:
		var b: Array = buttons[action]
		# area di tocco un po' piu' grande del disegno
		if p.distance_to(b[0]) <= b[1] + 10.0:
			return action
	return ""


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		visible = true
		if event.pressed:
			_on_press(event.index, event.position)
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		if main.state != "playing" or not _touches.has(event.index):
			return
		var now := _button_at(event.position)
		if now == "pause":
			now = ""
		var before: String = _touches[event.index]
		if now != before:
			if before != "":
				Input.action_release(before)
			if now != "":
				Input.action_press(now)
			_touches[event.index] = now


func _on_press(index: int, p: Vector2) -> void:
	match main.state:
		"title":
			for i in D.MAX_LEVEL:
				var r := Rect2(D.VIEW_W * 0.5 - 70 + i * 28, 152, 22, 16).grow(5)
				if r.has_point(p):
					if main.choco_count != i:
						main.choco_count = i
						Synth.sfx("select")
						main._build_world()
					return
			main._start_game()
		"gameover", "victory":
			if main.state_timer < 2.5:
				main._go_title()
		_:
			var a := _button_at(p)
			if a == "pause":
				get_tree().paused = not get_tree().paused
				return
			if get_tree().paused:
				get_tree().paused = false
				return
			_touches[index] = a
			if a != "":
				Input.action_press(a)


func _release(index: int) -> void:
	if not _touches.has(index):
		return
	var a: String = _touches[index]
	if a != "":
		Input.action_release(a)
	_touches.erase(index)


func release_all() -> void:
	for i in _touches.keys():
		_release(i)


func _process(_delta: float) -> void:
	if main.state != "playing" and not _touches.is_empty():
		release_all()
	queue_redraw()


func _draw() -> void:
	if main.state != "playing":
		return
	var f := ThemeDB.fallback_font
	for action in buttons:
		var b: Array = buttons[action]
		var held := Input.is_action_pressed(action)
		var c := Color(1, 1, 1, 0.32 if held else 0.14)
		draw_circle(b[0], b[1], c)
		draw_arc(b[0], b[1], 0, TAU, 32, Color(1, 1, 1, 0.45), 1.5)
		var label: String = b[2]
		var size := 9 if label.length() > 2 else 16
		draw_string(f, b[0] + Vector2(-40, size * 0.35), label, HORIZONTAL_ALIGNMENT_CENTER, 80, size, Color(1, 1, 1, 0.8))
