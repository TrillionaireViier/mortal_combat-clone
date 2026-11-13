extends Node2D

const FLOOR_Y := 465.0
const GRAVITY := 1450.0
const MOVE_SPEED := 310.0
const JUMP_SPEED := -650.0
const ARENA_LEFT := 55.0
const ARENA_RIGHT := 905.0

var fighters: Array[Dictionary] = []
var round_over := false
var winner_text := ""

func _ready() -> void:
	fighters = [
		_make_fighter("SCORPION", Color(1.0, 0.35, 0.12), 260.0, 1, KEY_A, KEY_D, KEY_W),
		_make_fighter("SUB-ZERO", Color(0.18, 0.62, 1.0), 700.0, -1, KEY_LEFT, KEY_RIGHT, KEY_UP)
	]
	queue_redraw()

func _make_fighter(label: String, tint: Color, start_x: float, direction: int, left_key: Key, right_key: Key, jump_key: Key) -> Dictionary:
	return {
		"label": label,
		"color": tint,
		"x": start_x,
		"feet_y": FLOOR_Y,
		"vx": 0.0,
		"vy": 0.0,
		"facing": direction,
		"health": 100.0,
		"left": left_key,
		"right": right_key,
		"jump": jump_key,
		"attack_kind": "",
		"attack_time": 0.0,
		"cooldown": 0.0,
		"attack_hit": false,
		"hitstun": 0.0,
		"flash": 0.0
	}

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if round_over:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_restart_round()
		return
	match event.keycode:
		KEY_F:
			_start_attack(0, "PUNCH")
		KEY_G:
			_start_attack(0, "KICK")
		KEY_J:
			_start_attack(1, "PUNCH")
		KEY_K:
			_start_attack(1, "KICK")
		_:
			pass

func _process(delta: float) -> void:
	if not round_over:
		for i in range(fighters.size()):
			_update_fighter(i, delta)
			_check_attack(i)
			if fighters[i]["health"] <= 0.0:
				round_over = true
				winner_text = fighters[1 - i]["label"] + " WINS!"
	queue_redraw()

func _update_fighter(index: int, delta: float) -> void:
	var fighter: Dictionary = fighters[index]
	var opponent: Dictionary = fighters[1 - index]
	fighter["facing"] = 1 if opponent["x"] >= fighter["x"] else -1
	fighter["cooldown"] = maxf(0.0, fighter["cooldown"] - delta)
	fighter["attack_time"] = maxf(0.0, fighter["attack_time"] - delta)
	fighter["hitstun"] = maxf(0.0, fighter["hitstun"] - delta)
	fighter["flash"] = maxf(0.0, fighter["flash"] - delta)

	var direction := 0.0
	if fighter["hitstun"] <= 0.0 and fighter["attack_time"] <= 0.0:
		if Input.is_key_pressed(fighter["left"]):
			 direction -= 1.0
		if Input.is_key_pressed(fighter["right"]):
			 direction += 1.0
	fighter["vx"] = direction * MOVE_SPEED
	fighter["x"] = clampf(fighter["x"] + fighter["vx"] * delta, ARENA_LEFT, ARENA_RIGHT)

	if fighter["feet_y"] < FLOOR_Y or fighter["vy"] < 0.0:
		fighter["vy"] += GRAVITY * delta
		fighter["feet_y"] = minf(FLOOR_Y, fighter["feet_y"] + fighter["vy"] * delta)
		if fighter["feet_y"] >= FLOOR_Y:
			fighter["vy"] = 0.0
	fighters[index] = fighter

func _start_attack(index: int, kind: String) -> void:
	var fighter: Dictionary = fighters[index]
	if fighter["cooldown"] > 0.0 or fighter["hitstun"] > 0.0:
		return
	fighter["attack_kind"] = kind
	fighter["attack_time"] = 0.24 if kind == "PUNCH" else 0.34
	fighter["cooldown"] = 0.43 if kind == "PUNCH" else 0.62
	fighter["attack_hit"] = false
	fighters[index] = fighter

func _check_attack(index: int) -> void:
	var fighter: Dictionary = fighters[index]
	if fighter["attack_time"] <= 0.0 or fighter["attack_hit"]:
		return
	var opponent: Dictionary = fighters[1 - index]
	var distance: float = absf(opponent["x"] - fighter["x"])
	var in_front: bool = signf(opponent["x"] - fighter["x"]) == fighter["facing"]
	var same_height: bool = absf(opponent["feet_y"] - fighter["feet_y"]) < 78.0
	var reach := 112.0 if fighter["attack_kind"] == "KICK" else 88.0
	if distance <= reach and in_front and same_height:
		var damage := 13.0 if fighter["attack_kind"] == "KICK" else 8.0
		opponent["health"] = maxf(0.0, opponent["health"] - damage)
		opponent["hitstun"] = 0.22
		opponent["flash"] = 0.16
		opponent["x"] = clampf(opponent["x"] + fighter["facing"] * 22.0, ARENA_LEFT, ARENA_RIGHT)
		fighters[1 - index] = opponent
		fighter["attack_hit"] = true
		fighters[index] = fighter

func _restart_round() -> void:
	fighters[0] = _make_fighter("SCORPION", Color(1.0, 0.35, 0.12), 260.0, 1, KEY_A, KEY_D, KEY_W)
	fighters[1] = _make_fighter("SUB-ZERO", Color(0.18, 0.62, 1.0), 700.0, -1, KEY_LEFT, KEY_RIGHT, KEY_UP)
	round_over = false
	winner_text = ""

func _draw() -> void:
	_draw_arena()
	_draw_hud()
	for fighter in fighters:
		_draw_fighter(fighter)
	if round_over:
		_draw_center_text(winner_text, 42, Color(1.0, 0.85, 0.28), Vector2(480.0, 245.0))
		_draw_center_text("ENTER TO FIGHT AGAIN", 18, Color.WHITE, Vector2(480.0, 285.0))

func _draw_arena() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color(0.035, 0.025, 0.10))
	# Moonlit skyline and distant temple silhouettes.
	draw_circle(Vector2(750, 105), 48, Color(0.85, 0.42, 0.55, 0.85))
	for i in range(10):
		var x := float(i) * 112.0 - 8.0
		var height := 75.0 + float((i * 43) % 95)
		draw_rect(Rect2(x, FLOOR_Y - height, 82, height), Color(0.10, 0.075, 0.20))
		for row in range(3):
			for col in range(2):
				draw_rect(Rect2(x + 15 + col * 34, FLOOR_Y - height + 15 + row * 25, 9, 12), Color(0.90, 0.39, 0.19, 0.55))
	draw_rect(Rect2(0, FLOOR_Y, 960, 75), Color(0.16, 0.08, 0.11))
	draw_line(Vector2(0, FLOOR_Y), Vector2(960, FLOOR_Y), Color(0.95, 0.45, 0.20), 3.0)
	for i in range(18):
		var x := float(i) * 60.0
		draw_line(Vector2(x, FLOOR_Y + 14), Vector2(x + 24, 540), Color(0.31, 0.15, 0.16, 0.7), 1.0)

func _draw_hud() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(42, 28, 380, 24), Color(0.12, 0.08, 0.10))
	draw_rect(Rect2(538, 28, 380, 24), Color(0.12, 0.08, 0.10))
	draw_rect(Rect2(42, 28, 380 * fighters[0]["health"] / 100.0, 24), Color(0.95, 0.31, 0.12))
	var right_width: float = 380.0 * fighters[1]["health"] / 100.0
	draw_rect(Rect2(918 - right_width, 28, right_width, 24), Color(0.15, 0.55, 1.0))
	draw_rect(Rect2(42, 28, 876, 24), Color(1, 1, 1, 0), false, 2.0)
	draw_string(font, Vector2(48, 23), fighters[0]["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	draw_string(font, Vector2(912, 23), fighters[1]["label"], HORIZONTAL_ALIGNMENT_RIGHT, -1, 16, Color.WHITE)
	_draw_center_text("SHADOW ARENA", 22, Color(1.0, 0.78, 0.3), Vector2(480, 39))
	draw_string(font, Vector2(48, 526), "P1: A / D MOVE   W JUMP   F PUNCH   G KICK", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.88, 0.82, 0.84))
	draw_string(font, Vector2(912, 526), "P2: ARROWS MOVE   UP JUMP   J PUNCH   K KICK", HORIZONTAL_ALIGNMENT_RIGHT, -1, 14, Color(0.88, 0.82, 0.84))

func _draw_fighter(fighter: Dictionary) -> void:
	var x: float = fighter["x"]
	var feet: float = fighter["feet_y"]
	var facing: int = fighter["facing"]
	var tint: Color = Color.WHITE if fighter["flash"] > 0.0 else fighter["color"]
	var body_top := feet - 94.0
	# Shadow, boots, torso, arms, and masked head.
	draw_ellipse(Vector2(x, FLOOR_Y + 4), Vector2(31, 8), Color(0.0, 0.0, 0.0, 0.42))
	draw_rect(Rect2(x - 20, feet - 19, 15, 19), tint.darkened(0.35))
	draw_rect(Rect2(x + 5, feet - 19, 15, 19), tint.darkened(0.35))
	draw_rect(Rect2(x - 23, body_top + 35, 46, 44), tint.darkened(0.12))
	draw_rect(Rect2(x - 27, body_top + 37, 54, 8), tint.lightened(0.12))
	draw_circle(Vector2(x, body_top + 18), 17, tint)
	draw_rect(Rect2(x - 17, body_top + 17, 34, 8), Color(0.09, 0.07, 0.12))
	draw_circle(Vector2(x + facing * 7, body_top + 19), 2.2, Color(1.0, 0.86, 0.45))
	var arm_end := Vector2(x + facing * 34, body_top + 52)
	if fighter["attack_time"] > 0.0:
		if fighter["attack_kind"] == "PUNCH":
			arm_end = Vector2(x + facing * 58, body_top + 47)
		else:
			draw_line(Vector2(x, body_top + 65), Vector2(x + facing * 51, body_top + 79), tint.lightened(0.2), 11.0)
	draw_line(Vector2(x - facing * 15, body_top + 47), Vector2(x - facing * 29, body_top + 70), tint, 9.0)
	draw_line(Vector2(x + facing * 15, body_top + 47), arm_end, tint.lightened(0.18), 10.0)
	draw_circle(arm_end, 7.0, tint.lightened(0.22))

func _draw_center_text(text: String, size: int, color: Color, at: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(at.x - text_width / 2.0, at.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
