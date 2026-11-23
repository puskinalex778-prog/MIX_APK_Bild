class_name CharacterView
extends Control
## Анимированный персонаж с выразительной векторной графикой и живыми анимациями
## в стиле ostrova-znaniy (дыхание, плавное моргание, взмахи крыльев Лумика,
## мигающая антенна Робика, радостный прыжок, покачивание при ошибке).

signal tapped

const KIDS := {
	"kid_a": {"skin": "f6bf98", "skin_l": "ffe3cc", "hair": "7a4524", "style": "short", "shirt": "169c92", "shirt_l": "3fd6c8", "pants": "3647a8", "pack": "ffb347"},
	"kid_b": {"skin": "e5b081", "skin_l": "f7cfa8", "hair": "2c2f48", "style": "spiky", "shirt": "25b061", "shirt_l": "4fd88b", "pants": "3d456b", "pack": "ff7a3d"},
	"kid_c": {"skin": "f8c9a0", "skin_l": "ffe8d1", "hair": "e68a19", "style": "curly", "shirt": "ff7a3d", "shirt_l": "ffa265", "pants": "2f56b8", "pack": "3fd6c8"},
	"kid_d": {"skin": "f8c9a0", "skin_l": "ffe8d1", "hair": "b8471c", "style": "pigtails", "shirt": "e64980", "shirt_l": "ff7aa8", "pants": "5b45c7", "pack": "ffd23f"},
	"kid_e": {"skin": "d1945c", "skin_l": "e8b580", "hair": "23264a", "style": "bun", "shirt": "f5a623", "shirt_l": "ffd23f", "pants": "168fa0", "pack": "ff5a6e"},
	"kid_f": {"skin": "f6bf98", "skin_l": "ffe3cc", "hair": "7a4524", "style": "long", "shirt": "8e3be0", "shirt_l": "c37bff", "pants": "3f4fe0", "pack": "4fd88b"},
}
const ANIMALS := {
	"fox": {"body": "ff7a3d", "belly": "fff4e6", "ear": "e8590c", "accent": "ffffff"},
	"cat": {"body": "8d99ae", "belly": "f3f5ff", "ear": "6c768f", "accent": "ff8fab"},
	"raccoon": {"body": "8d99ae", "belly": "eef0ff", "ear": "484d6d", "accent": "2b2f5c"},
	"owl": {"body": "a8683a", "belly": "fff0d1", "ear": "7d4a26", "accent": "ffd23f"},
	"robot": {"body": "5b6cff", "belly": "eef1ff", "ear": "9fb2ff", "accent": "ffd23f"},
	"bear": {"body": "b0754a", "belly": "f7dfbe", "ear": "8a5632", "accent": "ffffff"},
}

@export var kind := "lumik"
var state = "idle"
var talking = false
var facing = 1.0
var _t = 0.0
var _blink = 0.0
var _next_blink = 2.4
var _state_t = 0.0
var _sparkles: Array = []


func _init(k: String = "lumik", sz: Vector2 = Vector2(220, 260)) -> void:
	kind = k
	custom_minimum_size = sz
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	gui_input.connect(_on_input)


func _on_input(ev: InputEvent) -> void:
	if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
		tapped.emit()


func set_state(s: String, duration: float = 0.0) -> void:
	state = s
	_state_t = 0.0
	if s == "finish" or s == "happy":
		_sparkles.clear()
		for i in 12:
			_sparkles.append({"a": randf() * TAU, "r": randf_range(0.3, 1.0), "s": randf_range(0.6, 1.2)})
	if duration > 0.0 and is_inside_tree():
		var my = s
		get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(self) and state == my:
				set_state("idle"))


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	_state_t += delta
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.16
		_next_blink = randf_range(2.6, 4.8)
	if _blink > 0.0:
		_blink -= delta
	queue_redraw()


func _amp() -> float:
	return 0.0 if Settings.reduce_motion else 1.0


func _sc() -> float:
	return size.y / 300.0


func _base_xf_origin() -> Vector2:
	return Vector2(size.x * 0.5, size.y * 0.96)


# ---------------- рисование ----------------
func _draw() -> void:
	var s = _sc()
	var base = _base_xf_origin()
	var a = _amp()
	var t = _t
	var bob = sin(t * 2.1) * (8.0 if kind in ["lumik", "robot", "cloud"] else 2.5) * a
	var jump = 0.0
	var shake_x = 0.0
	var breathe_sq = Vector2.ONE
	if state == "happy" or state == "finish":
		jump = -absf(sin(t * 7.5)) * 28.0 * a
		breathe_sq = Vector2(1.0 + 0.04 * sin(t * 15.0) * a, 1.0 - 0.04 * sin(t * 15.0) * a)
	elif state == "support" and _state_t < 0.65:
		shake_x = sin(_state_t * 36.0) * 10.0 * (1.0 - _state_t / 0.65) * a
	elif state == "walk":
		bob = -absf(sin(t * 9.5)) * 8.0 * a
	else:
		breathe_sq = Vector2(1.0 + 0.015 * sin(t * 1.85) * a, 1.0 - 0.015 * sin(t * 1.85) * a)

	# тень на земле
	draw_set_transform(base, 0.0, Vector2(s * facing, s))
	var shadow_w = clampf(68.0 - absf(jump) * 0.65 - absf(bob) * 0.4, 34.0, 74.0)
	_draw_ellipse(Vector2(shake_x * 0.5, -4), Vector2(shadow_w, 12), Color(0.08, 0.12, 0.35, 0.20))

	var root = Vector2(shake_x, bob + jump)
	var img = ArtLib.tex("characters/" + kind)
	if img:
		_draw_image(img, root, t, a)
	else:
		draw_set_transform(base + root * s, 0.0, Vector2(s * facing * breathe_sq.x, s * breathe_sq.y))
		_draw_vector(Vector2.ZERO, t, a)
	draw_set_transform(base, 0.0, Vector2(s * facing, s))
	_draw_effects(root, t, a)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_image(img: Texture2D, root: Vector2, t: float, a: float) -> void:
	var s = _sc()
	var base = _base_xf_origin()
	var rot = 0.0
	var sq = Vector2.ONE
	match state:
		"walk":
			rot = sin(t * 9.0) * 0.06 * a
		"wave", "explain":
			rot = sin(t * 4.0) * 0.05 * a
		"think":
			rot = -0.06
		"support":
			rot = 0.05
		"happy", "finish":
			sq = Vector2(1.0 + 0.05 * sin(t * 14.0) * a, 1.0 - 0.05 * sin(t * 14.0) * a)
		_:
			sq = Vector2(1.0 - 0.014 * sin(t * 2.0) * a, 1.0 + 0.014 * sin(t * 2.0) * a)
	draw_set_transform(base + root * s, rot, Vector2(s * facing * sq.x, s * sq.y))
	ArtLib.draw_fit_bottom(self, img, Vector2(size.x / s * 0.98, 290), Vector2.ZERO, Color.WHITE)
	draw_set_transform(base, 0.0, Vector2(s * facing, s))


func _draw_vector(root: Vector2, t: float, a: float) -> void:
	match kind:
		"lumik":
			_draw_lumik(root, t, a)
		"cloud":
			_draw_cloud(root, t, a)
		"robot":
			_draw_robot(root, t, a)
		_:
			if KIDS.has(kind):
				_draw_kid(root, t, a)
			else:
				_draw_animal(root, t, a)


func _draw_effects(root: Vector2, t: float, a: float) -> void:
	if state == "think":
		for i in 3:
			var ph = fmod(t * 1.5 + i * 0.33, 1.0)
			draw_circle(root + Vector2(68 + i * 18, -245 - i * 16), 6 + i * 3, Color(1, 1, 1, 0.55 + 0.45 * ph))
	if state == "happy" or state == "finish":
		for sp in _sparkles:
			var ang: float = sp["a"] + t * (1.6 if state == "finish" else 0.9) * a
			var rr: float = 86 + sp["r"] * 68
			var p = root + Vector2(cos(ang) * rr, -150 + sin(ang) * rr * 0.8)
			_star(p, 9.5 * sp["s"], Color("ffd23f"))


func _draw_ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in 28:
		var ang = TAU * i / 28.0
		pts.append(c + Vector2(cos(ang) * r.x, sin(ang) * r.y))
	draw_colored_polygon(pts, col)


func _draw_round_rect(rect: Rect2, rad: float, col: Color, outline: Color = Color.TRANSPARENT, out_w: float = 0.0) -> void:
	var r = minf(rad, minf(rect.size.x, rect.size.y) * 0.5)
	if out_w > 0.0 and outline.a > 0.01:
		_draw_round_rect(rect.grow(out_w), r + out_w, outline)
	var pts = PackedVector2Array()
	var corners = [
		[Vector2(rect.end.x - r, rect.position.y + r), -PI * 0.5, 0.0],
		[Vector2(rect.end.x - r, rect.end.y - r), 0.0, PI * 0.5],
		[Vector2(rect.position.x + r, rect.end.y - r), PI * 0.5, PI],
		[Vector2(rect.position.x + r, rect.position.y + r), PI, PI * 1.5],
	]
	for cc in corners:
		for i in 6:
			var ang = lerpf(cc[1], cc[2], i / 5.0)
			pts.append(cc[0] + Vector2(cos(ang) * r, sin(ang) * r))
	draw_colored_polygon(pts, col)


func _limb(from: Vector2, angle: float, length: float, width: float, col: Color, end_r: float = 0.0, end_col: Color = Color.TRANSPARENT) -> Vector2:
	var to = from + Vector2(sin(angle), cos(angle)) * length
	draw_line(from, to, col, width, true)
	draw_circle(from, width * 0.5, col)
	draw_circle(to, width * 0.5, col)
	draw_line(from.lerp(to, 0.15) + Vector2(-width * 0.18, 0), from.lerp(to, 0.72) + Vector2(-width * 0.18, 0), Color(1, 1, 1, 0.22), width * 0.22, true)
	if end_r > 0.0:
		draw_circle(to, end_r, end_col)
		draw_circle(to + Vector2(-end_r * 0.28, -end_r * 0.28), end_r * 0.32, Color(1, 1, 1, 0.26))
	return to


func _star(c: Vector2, r: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in 10:
		var rr = r if i % 2 == 0 else r * 0.45
		var ang = -PI / 2 + i * PI / 5
		pts.append(c + Vector2(cos(ang), sin(ang)) * rr)
	draw_colored_polygon(pts, col)


func _arm_angles(t: float, a: float) -> Array:
	var l = 0.22
	var r = -0.22
	match state:
		"walk":
			l = 0.22 + sin(t * 9.5) * 0.65 * a
			r = -0.22 - sin(t * 9.5) * 0.65 * a
		"wave":
			r = -2.55 + sin(t * 10.0) * 0.35 * a
		"explain":
			r = -1.55 + sin(t * 3.5) * 0.25 * a
			l = 0.32
		"think":
			r = -2.25
			l = 0.48
		"support":
			l = 1.0
			r = -1.0
		"happy", "finish":
			l = 2.65 + sin(t * 8.0) * 0.22 * a
			r = -2.65 - sin(t * 8.0) * 0.22 * a
		_:
			l = 0.22 + sin(t * 1.4) * 0.05 * a
			r = -0.22 - sin(t * 1.4) * 0.05 * a
	return [l, r]


func _leg_angles(t: float, a: float) -> Array:
	if state == "walk":
		return [sin(t * 9.5) * 0.52 * a, -sin(t * 9.5) * 0.52 * a]
	if state == "happy" or state == "finish":
		return [0.22, -0.22]
	return [0.06, -0.06]


func _face(c: Vector2, r: float, eye_col: Color = Color("23264a"), mouth_col: Color = Color("23264a"), cheeks: bool = true, white_sclera: bool = false) -> void:
	var look = Vector2(4, -5) if state == "think" else Vector2.ZERO
	var ex = r * 0.36
	var ey = -r * 0.06
	var happy = state == "happy" or state == "finish"
	var blink_k = 0.12 if _blink > 0.0 else 1.0
	for side in [-1, 1]:
		var ec = c + Vector2(ex * side, ey)
		if happy:
			draw_arc(ec + Vector2(0, 4), r * 0.14, PI * 1.1, PI * 1.9, 10, eye_col, 4.5, true)
		else:
			if white_sclera:
				_draw_ellipse(ec, Vector2(r * 0.15, r * 0.18 * blink_k), Color.WHITE)
				if blink_k > 0.3:
					draw_circle(ec + look + Vector2(1, 1), r * 0.085, eye_col)
					draw_circle(ec + look + Vector2(3, -3), r * 0.032, Color.WHITE)
			else:
				_draw_ellipse(ec + look, Vector2(r * 0.125, r * 0.165 * blink_k), eye_col)
				if blink_k > 0.3:
					draw_circle(ec + look + Vector2(3.5, -5.0), r * 0.045, Color.WHITE)
		if state == "support":
			draw_line(ec + Vector2(-r * 0.14, -r * 0.24 - side * 3), ec + Vector2(r * 0.14, -r * 0.24 + side * 3), eye_col, 3.2, true)
	if cheeks:
		_draw_ellipse(c + Vector2(-r * 0.58, r * 0.24), Vector2(r * 0.15, r * 0.095), Color(1.0, 0.56, 0.53, 0.55))
		_draw_ellipse(c + Vector2(r * 0.58, r * 0.24), Vector2(r * 0.15, r * 0.095), Color(1.0, 0.56, 0.53, 0.55))
	var mc = c + Vector2(0, r * 0.34)
	if (talking or state == "explain") and sin(_t * 14.0) > 0.0:
		_draw_ellipse(mc + Vector2(0, 2), Vector2(r * 0.14, r * 0.11), Color("ff7a7a"))
		draw_arc(mc + Vector2(0, -1), r * 0.14, 0, TAU, 16, mouth_col, 3.0, true)
	elif happy:
		var pts = PackedVector2Array([mc + Vector2(-r * 0.22, -3)])
		for i in 9:
			var ang = PI * i / 8.0
			pts.append(mc + Vector2(-cos(ang) * r * 0.22, sin(ang) * r * 0.22 - 3))
		draw_colored_polygon(pts, Color("ff7a7a"))
		draw_arc(mc + Vector2(0, -3), r * 0.22, 0.05, PI - 0.05, 12, mouth_col, 3.5, true)
	elif state == "support" or state == "think":
		draw_line(mc + Vector2(-r * 0.12, 0), mc + Vector2(r * 0.12, -2), mouth_col, 3.5, true)
	else:
		var pts2 = PackedVector2Array([mc + Vector2(-r * 0.19, -2)])
		for i in 9:
			var ang = PI * i / 8.0
			pts2.append(mc + Vector2(-cos(ang) * r * 0.19, sin(ang) * r * 0.14 - 2))
		draw_colored_polygon(pts2, Color("ff7a7a"))
		draw_arc(mc + Vector2(0, -4), r * 0.19, PI * 0.12, PI * 0.88, 12, mouth_col, 3.5, true)


# ---------------- Лумик (светлячок из art.js) ----------------
func _draw_lumik(root: Vector2, t: float, a: float) -> void:
	var c = root + Vector2(0, -126)
	var pulse = 0.78 + 0.22 * sin(t * 3.5) * a
	var belly = c + Vector2(0, 44)
	# золотой ореол фонарика
	for i in 5:
		draw_circle(belly, 92 - i * 15, Color(1.0, 0.92, 0.45, (0.05 + i * 0.045) * pulse))
	# быстро машущие голубые крылышки с белой кромкой
	var flap = sin(t * 28.0) * 0.28 * a if state in ["happy", "finish", "walk", "wave", "explain"] else sin(t * 16.0) * 0.20 * a
	for side in [-1, 1]:
		var pivot = c + Vector2(side * 24, -12)
		var wing_pts = PackedVector2Array()
		var ang_base = side * (0.45 + flap)
		for i in 22:
			var th = TAU * i / 22.0
			var lx = cos(th) * 44.0 + side * 32.0
			var ly = sin(th) * 24.0 - 12.0
			var rx = lx * cos(ang_base) - ly * sin(ang_base)
			var ry = lx * sin(ang_base) + ly * cos(ang_base)
			wing_pts.append(pivot + Vector2(rx, ry))
		draw_colored_polygon(wing_pts, Color(0.82, 0.92, 1.0, 0.78))
		var cl = wing_pts.duplicate()
		cl.append(wing_pts[0])
		draw_polyline(cl, Color(1, 1, 1, 0.92), 3.0, true)
	# светящееся брюшко-фонарик
	_draw_ellipse(belly, Vector2(44, 50), Color("ff9f1c"))
	_draw_ellipse(belly + Vector2(-3, -4), Vector2(38, 43), Color("ffe14d"))
	_draw_ellipse(belly + Vector2(-8, -10), Vector2(22, 24), Color(1.0, 0.99, 0.88, 0.88 * pulse))
	draw_arc(belly + Vector2(0, -10), 36, PI * 0.16, PI * 0.84, 14, Color(0.88, 0.54, 0.0, 0.45), 3.5, true)
	# оранжевая грудка
	_draw_ellipse(c + Vector2(0, -6), Vector2(38, 28), Color("ff7a3d"))
	_draw_ellipse(c + Vector2(-6, -12), Vector2(18, 10), Color(1, 1, 1, 0.22))
	# голова (тёмно-индиго) и усики с жёлтыми шариками
	var hc = c + Vector2(0, -54)
	var wob = sin(t * 4.5) * 4.0 * a
	for side in [-1, 1]:
		var tip = hc + Vector2(side * 44 + wob * side, -58)
		draw_line(hc + Vector2(side * 14, -34), tip, Color("2b2f5c"), 5.0, true)
		draw_circle(tip, 10.5, Color("ffd23f"))
		draw_circle(tip + Vector2(-3, -3), 3.5, Color(1, 1, 1, 0.7))
	draw_circle(hc, 42, Color("2b2f5c"))
	draw_circle(hc + Vector2(-6, -7), 34, Color("484e82"))
	draw_circle(hc + Vector2(-14, -18), 10, Color(1, 1, 1, 0.18))
	_face(hc + Vector2(0, 4), 44, Color("1b1f3b"), Color.WHITE, false, true)


# ---------------- Робик (робот-помощник из art.js) ----------------
func _draw_robot(root: Vector2, t: float, a: float) -> void:
	var c = root + Vector2(0, -135)
	var arms = _arm_angles(t, a)
	var legs = _leg_angles(t, a)
	# ноги
	_limb(c + Vector2(-22, 80), legs[0], 34, 20, Color("8b9be8"), 10, Color("5b6cff"))
	_limb(c + Vector2(22, 80), legs[1], 34, 20, Color("8b9be8"), 10, Color("5b6cff"))
	# руки
	_limb(c + Vector2(-60, 12), arms[0], 54, 18, Color("8b9be8"), 12, Color("5b6cff"))
	_limb(c + Vector2(60, 12), arms[1], 54, 18, Color("8b9be8"), 12, Color("5b6cff"))
	# белый округлый корпус с панелькой и 3 индикаторами
	_draw_round_rect(Rect2(c + Vector2(-52, 2), Vector2(104, 82)), 26, Color("dfe4ff"))
	_draw_round_rect(Rect2(c + Vector2(-48, 2), Vector2(96, 72)), 24, Color("ffffff"))
	_draw_round_rect(Rect2(c + Vector2(-30, 22), Vector2(60, 32)), 12, Color("eef1ff"), Color("c9d1ff"), 2.0)
	var leds = [Color("ff7a3d"), Color("ffd23f"), Color("2fc26b")]
	for i in 3:
		var lit = fmod(t * 2.4 + i * 0.9, 3.0) > 0.7
		draw_circle(c + Vector2(-16 + i * 16, 38), 6.5, leds[i] if lit else Color("cfd5f2"))
	# шея
	_draw_round_rect(Rect2(c + Vector2(-22, -10), Vector2(44, 16)), 6, Color("8b9be8"))
	# антенна с мигающей лампочкой
	draw_line(c + Vector2(0, -106), c + Vector2(0, -132), Color("5b6cff"), 5.5, true)
	var ant_col = Color("ff5a6e") if sin(t * 4.2) > 0.0 else Color("ffd23f")
	draw_circle(c + Vector2(0, -134), 16, Color(ant_col, 0.25))
	draw_circle(c + Vector2(0, -134), 9.5, ant_col)
	draw_circle(c + Vector2(-3, -137), 3.0, Color(1, 1, 1, 0.75))
	# округлая индиго-голова и тёмный экран-визор
	_draw_round_rect(Rect2(c + Vector2(-64, -106), Vector2(128, 98)), 32, Color("5b6cff"))
	_draw_round_rect(Rect2(c + Vector2(-60, -104), Vector2(120, 86)), 30, Color("7f93ff"))
	_draw_round_rect(Rect2(c + Vector2(-48, -90), Vector2(96, 68)), 22, Color("1b1f3b"))
	# мятно-зелёные глаза-капсулы и улыбка
	var mint = Color("5dffa8")
	var blink_h = 3.5 if _blink > 0.0 else 22.0
	var happy = state == "happy" or state == "finish"
	for side in [-1, 1]:
		var ex = c.x + side * 22.0
		var ey = c.y - 60.0
		if happy:
			draw_arc(Vector2(ex, ey + 4), 11.0, PI * 1.1, PI * 1.9, 10, mint, 4.5, true)
		else:
			_draw_round_rect(Rect2(ex - 8.5, ey - blink_h * 0.5, 17.0, blink_h), 8.0, mint)
	if (talking or state == "explain") and sin(t * 14.0) > 0.0:
		_draw_ellipse(c + Vector2(0, -37), Vector2(12, 8), mint)
	elif state == "support":
		draw_arc(c + Vector2(0, -30), 12.0, PI * 1.15, PI * 1.85, 10, mint, 4.0, true)
	else:
		draw_arc(c + Vector2(0, -45), 15.0, PI * 0.15, PI * 0.85, 12, mint, 4.2, true)


# ---------------- Облако (из art.js) ----------------
func _draw_cloud(root: Vector2, t: float, a: float) -> void:
	var c = root + Vector2(0, -148)
	var puffs = [Vector2(-68, 12), Vector2(68, 12), Vector2(-34, -30), Vector2(30, -34), Vector2(0, 18), Vector2(0, -10)]
	var rads = [44, 44, 48, 52, 52, 50]
	for i in puffs.size():
		draw_circle(c + puffs[i] + Vector2(0, 10), rads[i], Color(0.78, 0.84, 0.98, 0.7))
	for i in puffs.size():
		draw_circle(c + puffs[i], rads[i], Color("eef2ff"))
	for i in puffs.size():
		draw_circle(c + puffs[i] + Vector2(-4, -6), rads[i] * 0.92, Color.WHITE)
	var blink_k = 0.12 if _blink > 0.0 else 1.0
	for side in [-1, 1]:
		var ec = c + Vector2(side * 28, -4)
		_draw_ellipse(ec, Vector2(9, 12 * blink_k), Color("2b2f5c"))
		if blink_k > 0.3:
			draw_circle(ec + Vector2(3, -4), 3.2, Color.WHITE)
	_draw_ellipse(c + Vector2(-44, 16), Vector2(12, 7), Color("ffb3c1"))
	_draw_ellipse(c + Vector2(44, 16), Vector2(12, 7), Color("ffb3c1"))
	_draw_ellipse(c + Vector2(0, 20), Vector2(10, 7.5), Color("ff9fb3"))
	draw_arc(c + Vector2(0, 28), 14, PI * 0.15, PI * 0.85, 12, Color("2b2f5c"), 3.8, true)


# ---------------- Герой-ученик (в стиле art.js Art.hero) ----------------
func _draw_kid(root: Vector2, t: float, a: float) -> void:
	var k: Dictionary = KIDS[kind]
	var skin = Color(k["skin"])
	var skin_l = Color(k["skin_l"])
	var hair = Color(k["hair"])
	var shirt = Color(k["shirt"])
	var shirt_l = Color(k["shirt_l"])
	var pants = Color(k["pants"])
	var pack = Color(k["pack"])
	var legs = _leg_angles(t, a)
	var hip = root + Vector2(0, -82)
	# жёлтый рюкзак за спиной
	_draw_round_rect(Rect2(hip + Vector2(-54, -78), Vector2(30, 58)), 14, pack)
	# ноги и яркие кроссовки с белой подошвой
	var lf = _limb(hip + Vector2(-16, 0), legs[0], 62, 22, pants)
	var rf = _limb(hip + Vector2(16, 0), legs[1], 62, 22, pants)
	_draw_round_rect(Rect2(lf + Vector2(-18, -2), Vector2(36, 16)), 8, Color("ff6b4a"))
	_draw_round_rect(Rect2(lf + Vector2(-19, 8), Vector2(38, 8)), 4, Color.WHITE)
	_draw_round_rect(Rect2(rf + Vector2(-18, -2), Vector2(36, 16)), 8, Color("ff6b4a"))
	_draw_round_rect(Rect2(rf + Vector2(-19, 8), Vector2(38, 8)), 4, Color.WHITE)
	# кофта с бликом, белым воротничком и кармашком
	_draw_round_rect(Rect2(hip + Vector2(-46, -86), Vector2(92, 92)), 32, shirt)
	_draw_round_rect(Rect2(hip + Vector2(-44, -86), Vector2(88, 66)), 30, shirt_l)
	draw_arc(hip + Vector2(0, -82), 20, PI * 0.12, PI * 0.88, 12, Color(1, 1, 1, 0.72), 4.0, true)
	_draw_round_rect(Rect2(hip + Vector2(-24, -36), Vector2(48, 22)), 10, Color(0, 0, 0, 0.12))
	# руки
	var arms = _arm_angles(t, a)
	var sh = hip + Vector2(0, -70)
	_limb(sh + Vector2(-42, 0), arms[0], 56, 20, shirt_l, 12, skin_l)
	_limb(sh + Vector2(42, 0), arms[1], 56, 20, shirt_l, 12, skin_l)
	# голова и волосы
	var hc = hip + Vector2(0, -142)
	var hr = 54.0
	match k["style"]:
		"long":
			_draw_round_rect(Rect2(hc + Vector2(-58, -14), Vector2(116, 86)), 24, hair)
		"pigtails":
			draw_circle(hc + Vector2(-64, 8), 22, hair)
			draw_circle(hc + Vector2(64, 8), 22, hair)
		"bun":
			draw_circle(hc + Vector2(0, -64), 24, hair)
	draw_circle(hc + Vector2(-52, 6), 12, skin)
	draw_circle(hc + Vector2(52, 6), 12, skin)
	draw_circle(hc, hr, skin)
	draw_circle(hc + Vector2(-4, -4), hr * 0.92, skin_l)
	# причёска спереди
	match k["style"]:
		"spiky":
			var pts = PackedVector2Array()
			for i in 9:
				pts.append(hc + Vector2(-54 + i * 13.5, -18 if i % 2 == 0 else -48))
			pts.append(hc + Vector2(56, -8))
			pts.append(hc + Vector2(-56, -8))
			draw_colored_polygon(pts, hair)
			draw_arc(hc, hr, PI * 1.05, PI * 1.95, 20, hair, 18, true)
		"curly":
			for i in 7:
				draw_circle(hc + Vector2(-46 + i * 15.5, -42 + absf(i - 3) * 5), 17, hair)
		_:
			draw_arc(hc + Vector2(0, 2), hr - 4, PI * 1.02, PI * 1.98, 24, hair, 28, true)
			draw_circle(hc + Vector2(-18, -42), 20, hair)
			draw_circle(hc + Vector2(14, -56), 13, hair)
	_face(hc + Vector2(0, 8), hr * 0.96)


# ---------------- Зверята-наставники (лиса, кот, енот, сова, медведь) ----------------
func _draw_animal(root: Vector2, t: float, a: float) -> void:
	var p: Dictionary = ANIMALS.get(kind, ANIMALS["bear"])
	var bodyc = Color(p["body"])
	var belly = Color(p["belly"])
	var earc = Color(p["ear"])
	var acc = Color(p["accent"])
	var legs = _leg_angles(t, a)
	var hip = root + Vector2(0, -72)
	if kind in ["fox", "cat", "raccoon"]:
		var wag = sin(t * 3.5) * 0.35 * a
		var tail_end = hip + Vector2(-68, -38 + wag * 28)
		draw_line(hip + Vector2(-18, -8), tail_end, bodyc, 22, true)
		draw_circle(tail_end, 13, belly if kind == "fox" else (Color("2b2f5c") if kind == "raccoon" else bodyc))
	if kind != "owl":
		_limb(hip + Vector2(-18, 0), legs[0], 46, 22, bodyc, 13, bodyc.darkened(0.15))
		_limb(hip + Vector2(18, 0), legs[1], 46, 22, bodyc, 13, bodyc.darkened(0.15))
	else:
		draw_colored_polygon(PackedVector2Array([hip + Vector2(-26, 38), hip + Vector2(-16, 52), hip + Vector2(-6, 38)]), Color("ffc83d"))
		draw_colored_polygon(PackedVector2Array([hip + Vector2(6, 38), hip + Vector2(16, 52), hip + Vector2(26, 38)]), Color("ffc83d"))
	_draw_ellipse(hip + Vector2(0, -40), Vector2(48, 54), bodyc)
	_draw_ellipse(hip + Vector2(0, -32), Vector2(30, 38), belly)
	var arms = _arm_angles(t, a)
	var sh = hip + Vector2(0, -72)
	if kind == "owl":
		_limb(sh + Vector2(-44, 0), arms[0] * 0.8, 44, 24, earc)
		_limb(sh + Vector2(44, 0), arms[1] * 0.8, 44, 24, earc)
	else:
		_limb(sh + Vector2(-40, 0), arms[0], 46, 18, bodyc, 11, bodyc.darkened(0.12))
		_limb(sh + Vector2(40, 0), arms[1], 46, 18, bodyc, 11, bodyc.darkened(0.12))
	var hc = hip + Vector2(0, -148)
	var hr = 56.0
	match kind:
		"fox", "cat":
			for side in [-1, 1]:
				draw_colored_polygon(PackedVector2Array([hc + Vector2(side * 20, -44), hc + Vector2(side * 52, -90), hc + Vector2(side * 54, -22)]), earc)
				draw_colored_polygon(PackedVector2Array([hc + Vector2(side * 28, -44), hc + Vector2(side * 49, -78), hc + Vector2(side * 50, -32)]), acc if kind == "cat" else Color("2b2f5c"))
		"raccoon", "bear":
			for side in [-1, 1]:
				draw_circle(hc + Vector2(side * 44, -40), 20, earc)
				draw_circle(hc + Vector2(side * 44, -40), 11, belly)
		"owl":
			for side in [-1, 1]:
				draw_colored_polygon(PackedVector2Array([hc + Vector2(side * 50, -28), hc + Vector2(side * 44, -78), hc + Vector2(side * 18, -48)]), earc)
	draw_circle(hc, hr, bodyc)
	draw_circle(hc + Vector2(-12, -16), hr * 0.25, Color(1, 1, 1, 0.14))
	if kind == "fox":
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-48, 10), hc + Vector2(0, 50), hc + Vector2(48, 10), hc + Vector2(0, 0)]), belly)
	elif kind == "raccoon":
		_draw_ellipse(hc + Vector2(-22, 0), Vector2(26, 18), acc)
		_draw_ellipse(hc + Vector2(22, 0), Vector2(26, 18), acc)
	elif kind == "owl":
		draw_circle(hc + Vector2(-22, 0), 24, belly)
		draw_circle(hc + Vector2(22, 0), 24, belly)
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-7, 18), hc + Vector2(7, 18), hc + Vector2(0, 32)]), acc)
		draw_arc(hc + Vector2(-22, 0), 26, 0, TAU, 24, Color("3f4fe0"), 3.2, true)
		draw_arc(hc + Vector2(22, 0), 26, 0, TAU, 24, Color("3f4fe0"), 3.2, true)
	_face(hc + Vector2(0, 6), hr * 0.92, Color("23264a"), Color("23264a"), kind != "owl")
	draw_circle(hc + Vector2(0, 24), 7, Color("23264a"))
	if kind in ["cat", "fox"]:
		for side in [-1, 1]:
			for i in 2:
				draw_line(hc + Vector2(side * 18, 28 + i * 8), hc + Vector2(side * 50, 24 + i * 12), Color(0.15, 0.16, 0.3, 0.55), 2.2, true)
