class_name CharacterView
extends Control
## Анимированный персонаж из отдельных частей (голова, тело, руки, ноги, глаза, рот)
## с программной «скелетной» анимацией. Состояния: idle, walk, wave, explain, think,
## support, happy, finish. Моргание — автоматически. При отключённом движении
## персонаж показывает позы без покачиваний.

signal tapped

const KIDS := {
	"kid_a": {"skin": "f1c27d", "hair": "6d4c41", "style": "short", "shirt": "4c6ef5", "pants": "364fc7"},
	"kid_b": {"skin": "e0ac69", "hair": "212529", "style": "spiky", "shirt": "2f9e44", "pants": "495057"},
	"kid_c": {"skin": "ffdbac", "hair": "f59f00", "style": "curly", "shirt": "e8590c", "pants": "1c7ed6"},
	"kid_d": {"skin": "ffdbac", "hair": "c2410c", "style": "pigtails", "shirt": "e64980", "pants": "7048e8"},
	"kid_e": {"skin": "c68642", "hair": "212529", "style": "bun", "shirt": "fab005", "pants": "1098ad"},
	"kid_f": {"skin": "f1c27d", "hair": "8d6e63", "style": "long", "shirt": "ae3ec9", "pants": "5f3dc4"},
}
const ANIMALS := {
	"fox": {"body": "f76707", "belly": "fff4e6", "ear": "f76707", "accent": "ffffff"},
	"cat": {"body": "868e96", "belly": "f1f3f5", "ear": "868e96", "accent": "ffa8a8"},
	"raccoon": {"body": "868e96", "belly": "e9ecef", "ear": "495057", "accent": "343a40"},
	"owl": {"body": "a0522d", "belly": "f5deb3", "ear": "8b4513", "accent": "ffd43b"},
	"robot": {"body": "74c0fc", "belly": "e7f5ff", "ear": "4dabf7", "accent": "ffd43b"},
	"bear": {"body": "a47148", "belly": "f3d9b1", "ear": "8d5b34", "accent": "ffffff"},
}

@export var kind := "lumik"
var state = "idle"
var talking = false
var facing = 1.0
var _t = 0.0
var _blink = 0.0
var _next_blink = 2.0
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
		_next_blink = randf_range(2.0, 4.5)
	if _blink > 0.0:
		_blink -= delta
	queue_redraw()


func _amp() -> float:
	return 0.0 if Settings.reduce_motion else 1.0


# ---------------- рисование ----------------
func _draw() -> void:
	var s = size.y / 300.0
	var base = Vector2(size.x * 0.5, size.y * 0.97)
	var a = _amp()
	var t = _t
	var bob = sin(t * 2.2) * 3.0 * a
	var jump = 0.0
	if state == "happy" or state == "finish":
		jump = -absf(sin(t * 7.0)) * 26.0 * a
	elif state == "walk":
		bob = -absf(sin(t * 9.0)) * 6.0 * a
	# тень
	draw_set_transform(base, 0.0, Vector2(s * facing, s))
	var shadow_w = 70.0 - absf(jump) * 0.6
	_draw_ellipse(Vector2(0, -4), Vector2(shadow_w, 12), Color(0, 0, 0, 0.18))
	var root = Vector2(0, bob + jump)
	var img = ArtLib.tex("characters/" + kind)
	if img:
		_draw_image(img, root, t, a)
	else:
		_draw_vector(root, t, a)
	_draw_effects(root, t, a)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Готовая картинка персонажа: «оживляем» её покачиванием, наклоном и растяжением по состоянию.
func _draw_image(img: Texture2D, root: Vector2, t: float, a: float) -> void:
	var s = size.y / 300.0
	var base = Vector2(size.x * 0.5, size.y * 0.97)
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
			sq = Vector2(1.0 - 0.012 * sin(t * 2.2) * a, 1.0 + 0.012 * sin(t * 2.2) * a)
	var mod = Color(1, 1, 1)
	if _blink > 0.0:
		mod = Color(0.97, 0.97, 0.97)
	draw_set_transform(base + root * s, rot, Vector2(s * facing * sq.x, s * sq.y))
	ArtLib.draw_fit_bottom(self, img, Vector2(size.x / s * 0.98, 290), Vector2.ZERO, mod)
	draw_set_transform(base, 0.0, Vector2(s * facing, s))


func _draw_vector(root: Vector2, t: float, a: float) -> void:
	match kind:
		"lumik":
			_draw_lumik(root, t, a)
		"cloud":
			_draw_cloud(root, t, a)
		_:
			if KIDS.has(kind):
				_draw_kid(root, t, a)
			else:
				_draw_animal(root, t, a)


func _draw_effects(root: Vector2, t: float, a: float) -> void:
	if state == "think":
		for i in 3:
			var ph = fmod(t * 1.5 + i * 0.33, 1.0)
			draw_circle(root + Vector2(70 + i * 18, -250 - i * 16), 6 + i * 3, Color(1, 1, 1, 0.5 + 0.5 * ph))
	if state == "happy" or state == "finish":
		for sp in _sparkles:
			var ang: float = sp["a"] + t * (1.5 if state == "finish" else 0.8) * a
			var rr: float = 90 + sp["r"] * 70
			var p = root + Vector2(cos(ang) * rr, -150 + sin(ang) * rr * 0.8)
			_star(p, 9.0 * sp["s"], Color("ffd43b"))


func _draw_ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in 28:
		var ang = TAU * i / 28.0
		pts.append(c + Vector2(cos(ang) * r.x, sin(ang) * r.y))
	draw_colored_polygon(pts, col)


func _limb(from: Vector2, angle: float, length: float, width: float, col: Color, end_r: float = 0.0, end_col: Color = Color.TRANSPARENT) -> Vector2:
	var to = from + Vector2(sin(angle), cos(angle)) * length
	var oc = _ol_col(col)
	draw_line(from, to, oc, width + OUT * 2.0, true)
	draw_circle(to, width * 0.5 + OUT, oc)
	if end_r > 0.0:
		draw_circle(to, end_r + OUT, _ol_col(end_col))
	draw_line(from, to, col, width, true)
	draw_circle(from, width * 0.5, col)
	draw_circle(to, width * 0.5, col)
	# блик вдоль конечности — объём
	draw_line(from.lerp(to, 0.15) + Vector2(-width * 0.2, 0), from.lerp(to, 0.7) + Vector2(-width * 0.2, 0), Color(1, 1, 1, 0.18), width * 0.25, true)
	if end_r > 0.0:
		draw_circle(to, end_r, end_col)
		draw_circle(to + Vector2(-end_r * 0.3, -end_r * 0.3), end_r * 0.35, Color(1, 1, 1, 0.22))
	return to


func _star(c: Vector2, r: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in 10:
		var rr = r if i % 2 == 0 else r * 0.45
		var ang = -PI / 2 + i * PI / 5
		pts.append(c + Vector2(cos(ang), sin(ang)) * rr)
	draw_colored_polygon(pts, col)


## Углы рук (0 — вниз, PI — вверх) по состоянию.
func _arm_angles(t: float, a: float) -> Array:
	var l = 0.25
	var r = -0.25
	match state:
		"walk":
			l = 0.25 + sin(t * 9.0) * 0.6 * a
			r = -0.25 - sin(t * 9.0) * 0.6 * a
		"wave":
			r = -2.6 + sin(t * 10.0) * 0.35 * a
		"explain":
			r = -1.5 + sin(t * 3.0) * 0.25 * a
			l = 0.35
		"think":
			r = -2.3
			l = 0.5
		"support":
			l = 1.1
			r = -1.1
		"happy", "finish":
			l = 2.6 + sin(t * 7.0) * 0.2 * a
			r = -2.6 - sin(t * 7.0) * 0.2 * a
		_:
			l = 0.25 + sin(t * 1.3) * 0.05 * a
			r = -0.25 - sin(t * 1.3) * 0.05 * a
	return [l, r]


func _leg_angles(t: float, a: float) -> Array:
	if state == "walk":
		return [sin(t * 9.0) * 0.5 * a, -sin(t * 9.0) * 0.5 * a]
	if state == "happy" or state == "finish":
		return [0.25, -0.25]
	return [0.08, -0.08]


func _face(c: Vector2, r: float, eye_col: Color = Color("2b2d42"), mouth_col: Color = Color("2b2d42"), cheeks: bool = true) -> void:
	var look = Vector2.ZERO
	if state == "think":
		look = Vector2(4, -5)
	var ex = r * 0.36
	var ey = -r * 0.08
	var happy = state == "happy" or state == "finish"
	for side in [-1, 1]:
		var ec = c + Vector2(ex * side, ey)
		if happy:
			draw_arc(ec + Vector2(0, 4), r * 0.13, PI * 1.1, PI * 1.9, 10, eye_col, 4.0, true)
		elif _blink > 0.0:
			draw_line(ec + Vector2(-r * 0.11, 0), ec + Vector2(r * 0.11, 0), eye_col, 4.0, true)
		else:
			_draw_ellipse(ec, Vector2(r * 0.12, r * 0.16), Color.WHITE)
			draw_circle(ec + look + Vector2(0, 1), r * 0.085, eye_col)
			draw_circle(ec + look + Vector2(-2, -3), r * 0.03, Color.WHITE)
		if state == "support":
			draw_line(ec + Vector2(-r * 0.14, -r * 0.24 - side * 3), ec + Vector2(r * 0.14, -r * 0.24 + side * 3), eye_col, 3.0, true)
	if cheeks:
		draw_circle(c + Vector2(-r * 0.58, r * 0.22), r * 0.11, Color(1, 0.45, 0.5, 0.35))
		draw_circle(c + Vector2(r * 0.58, r * 0.22), r * 0.11, Color(1, 0.45, 0.5, 0.35))
	var mc = c + Vector2(0, r * 0.32)
	if (talking or state == "explain") and sin(_t * 14.0) > 0.0:
		_draw_ellipse(mc + Vector2(0, 2), Vector2(r * 0.13, r * 0.11), mouth_col)
	elif happy:
		var pts = PackedVector2Array([mc + Vector2(-r * 0.2, -3)])
		for i in 9:
			var ang = PI * i / 8.0
			pts.append(mc + Vector2(-cos(ang) * r * 0.2, sin(ang) * r * 0.2 - 3))
		draw_colored_polygon(pts, Color("c92a2a"))
	elif state == "support" or state == "think":
		draw_line(mc + Vector2(-r * 0.12, 0), mc + Vector2(r * 0.12, -2), mouth_col, 3.5, true)
	else:
		draw_arc(mc + Vector2(0, -r * 0.08), r * 0.18, PI * 0.15, PI * 0.85, 12, mouth_col, 4.0, true)


func _draw_lumik(root: Vector2, t: float, a: float) -> void:
	var c = root + Vector2(0, -130)
	var glow = 0.55 + 0.15 * sin(t * 3.0) * a
	for i in 4:
		_circ(c, 95 - i * 14, Color(1.0, 0.85, 0.3, 0.06 + i * 0.03) * Color(1, 1, 1, glow * 1.6))
	# пламя-хохолок
	var fl = sin(t * 8.0) * 4.0 * a
	_poly(PackedVector2Array([c + Vector2(-16, -58), c + Vector2(fl, -100), c + Vector2(16, -58)]), Color("ffa94d"))
	_poly(PackedVector2Array([c + Vector2(-8, -60), c + Vector2(fl * 0.6, -86), c + Vector2(8, -60)]), Color("fff3bf"))
	_circ(c, 64, Color("ffd43b"))
	_circ(c + Vector2(-18, -20), 28, Color(1, 1, 1, 0.25))
	var arms = _arm_angles(t, a)
	_limb(c + Vector2(-52, 10), arms[0], 34, 10, Color("fab005"), 9, Color("fab005"))
	_limb(c + Vector2(52, 10), arms[1], 34, 10, Color("fab005"), 9, Color("fab005"))
	var legs = _leg_angles(t, a)
	_limb(c + Vector2(-20, 58), legs[0], 30, 11, Color("f59f00"), 8, Color("e67700"))
	_limb(c + Vector2(20, 58), legs[1], 30, 11, Color("f59f00"), 8, Color("e67700"))
	_face(c + Vector2(0, 4), 60)


func _draw_cloud(root: Vector2, t: float, a: float) -> void:
	var c = root + Vector2(0, -150 + sin(t * 1.6) * 8.0 * a)
	var col = Color("f1f3f5")
	var puffs = [Vector2(-55, 10), Vector2(55, 10), Vector2(-25, -30), Vector2(25, -32), Vector2(0, 20)]
	for p in puffs:
		draw_circle(c + p, 52 + OUT, Color("868e96"))
	for p in puffs:
		draw_circle(c + p, 52, Color("ced4da"))
	for p in puffs:
		draw_circle(c + p + Vector2(-3, -5), 47, col)
	for p in puffs:
		draw_circle(c + p + Vector2(-16, -18), 12, Color(1, 1, 1, 0.8))
	var arms = _arm_angles(t, a)
	_limb(c + Vector2(-90, 20), arms[0], 28, 12, col, 10, col)
	_limb(c + Vector2(90, 20), arms[1], 28, 12, col, 10, col)
	_face(c + Vector2(0, 0), 58, Color("495057"), Color("495057"))
	# капельки, когда грустит
	if state == "support":
		_circ(c + Vector2(-30, 80 + fmod(t * 40, 30)), 5, Color("74c0fc"))


func _draw_kid(root: Vector2, t: float, a: float) -> void:
	var k: Dictionary = KIDS[kind]
	var skin = Color(k["skin"])
	var hair = Color(k["hair"])
	var shirt = Color(k["shirt"])
	var pants = Color(k["pants"])
	var legs = _leg_angles(t, a)
	var hip = root + Vector2(0, -82)
	_limb(hip + Vector2(-16, 0), legs[0], 60, 22, pants, 0)
	_limb(hip + Vector2(16, 0), legs[1], 60, 22, pants, 0)
	_draw_ellipse(hip + Vector2(-16 + sin(legs[0]) * 60, 70), Vector2(18, 9), Color("343a40"))
	_draw_ellipse(hip + Vector2(16 + sin(legs[1]) * 60, 70), Vector2(18, 9), Color("343a40"))
	# туловище
	var body = PackedVector2Array([hip + Vector2(-36, 8)])
	for i in 13:
		var ang = PI + PI * i / 12.0
		body.append(hip + Vector2(cos(ang) * 32, -66 + sin(ang) * 26))
	body.append(hip + Vector2(36, 8))
	_poly(body, shirt)
	# воротник и тень от головы
	draw_arc(hip + Vector2(0, -90), 16, PI * 0.1, PI * 0.9, 12, shirt.darkened(0.25), 5, true)
	var arms = _arm_angles(t, a)
	var sh = hip + Vector2(0, -70)
	_limb(sh + Vector2(-34, 0), arms[0], 58, 18, shirt, 11, skin)
	_limb(sh + Vector2(34, 0), arms[1], 58, 18, shirt, 11, skin)
	# голова
	var tilt = 0.0
	if state == "support":
		tilt = 0.12
	elif state == "think":
		tilt = -0.08
	var hc = hip + Vector2(0, -150)
	var hr = 56.0
	# волосы сзади
	match k["style"]:
		"long":
			_rect(Rect2(hc + Vector2(-58, -10), Vector2(116, 80)), hair)
		"pigtails":
			_circ(hc + Vector2(-66, 10), 22, hair)
			_circ(hc + Vector2(66, 10), 22, hair)
		"bun":
			_circ(hc + Vector2(0, -64), 24, hair)
	_circ(hc + Vector2(-54, 4), 12, skin)
	_circ(hc + Vector2(54, 4), 12, skin)
	_circ(hc, hr, skin)
	# волосы спереди
	match k["style"]:
		"spiky":
			var pts = PackedVector2Array()
			for i in 9:
				var x = -56 + i * 14
				pts.append(hc + Vector2(x, -18 if i % 2 == 0 else -44))
			pts.append(hc + Vector2(58, -10))
			pts.append(hc + Vector2(-58, -10))
			_poly(pts, hair)
			draw_arc(hc, hr, PI * 1.05, PI * 1.95, 20, hair, 18, true)
		"curly":
			for i in 7:
				_circ(hc + Vector2(-48 + i * 16, -42 + absf(i - 3) * 5), 17, hair)
		_:
			draw_arc(hc + Vector2(0, 2), hr - 6, PI * 1.02, PI * 1.98, 24, hair, 26, true)
			_circ(hc + Vector2(-20, -44), 18, hair)
	_face(hc + Vector2(0, 8), hr * 0.95)


func _draw_animal(root: Vector2, t: float, a: float) -> void:
	var p: Dictionary = ANIMALS.get(kind, ANIMALS["bear"])
	var bodyc = Color(p["body"])
	var belly = Color(p["belly"])
	var earc = Color(p["ear"])
	var acc = Color(p["accent"])
	var legs = _leg_angles(t, a)
	var hip = root + Vector2(0, -70)
	# хвост
	if kind == "fox" or kind == "cat" or kind == "raccoon":
		var wag = sin(t * 3.0) * 0.3 * a
		var tail_end = hip + Vector2(-70, -40 + wag * 30)
		draw_line(hip + Vector2(-20, -10), tail_end, bodyc, 20, true)
		_circ(tail_end, 13, belly if kind == "fox" else (Color("343a40") if kind == "raccoon" else bodyc))
	if kind != "owl" and kind != "robot":
		_limb(hip + Vector2(-18, 0), legs[0], 46, 22, bodyc, 13, bodyc.darkened(0.15))
		_limb(hip + Vector2(18, 0), legs[1], 46, 22, bodyc, 13, bodyc.darkened(0.15))
	elif kind == "robot":
		_limb(hip + Vector2(-20, 0), legs[0], 48, 16, Color("adb5bd"), 14, Color("495057"))
		_limb(hip + Vector2(20, 0), legs[1], 48, 16, Color("adb5bd"), 14, Color("495057"))
	else:
		_poly(PackedVector2Array([hip + Vector2(-26, 40), hip + Vector2(-16, 52), hip + Vector2(-6, 40)]), Color("f59f00"))
		_poly(PackedVector2Array([hip + Vector2(6, 40), hip + Vector2(16, 52), hip + Vector2(26, 40)]), Color("f59f00"))
	# туловище
	if kind == "robot":
		_rect(Rect2(hip + Vector2(-46, -86), Vector2(92, 90)), bodyc)
		_rect(Rect2(hip + Vector2(-30, -70), Vector2(60, 40)), belly)
		for i in 3:
			_circ(hip + Vector2(-16 + i * 16, -50), 6, [Color("ff6b6b"), Color("ffd43b"), Color("69db7c")][i] if fmod(_t * 2 + i, 3.0) > 1.0 else Color("dee2e6"))
	else:
		_draw_ellipse(hip + Vector2(0, -40), Vector2(48, 54), bodyc)
		_draw_ellipse(hip + Vector2(0, -32), Vector2(30, 38), belly)
	var arms = _arm_angles(t, a)
	var sh = hip + Vector2(0, -72)
	if kind == "owl":
		_limb(sh + Vector2(-44, 0), arms[0] * 0.8, 44, 24, earc, 0)
		_limb(sh + Vector2(44, 0), arms[1] * 0.8, 44, 24, earc, 0)
	elif kind == "robot":
		_limb(sh + Vector2(-50, 0), arms[0], 50, 14, Color("adb5bd"), 12, Color("495057"))
		_limb(sh + Vector2(50, 0), arms[1], 50, 14, Color("adb5bd"), 12, Color("495057"))
	else:
		_limb(sh + Vector2(-40, 0), arms[0], 46, 18, bodyc, 11, bodyc.darkened(0.12))
		_limb(sh + Vector2(40, 0), arms[1], 46, 18, bodyc, 11, bodyc.darkened(0.12))
	# голова
	var hc = hip + Vector2(0, -150)
	var hr = 58.0
	match kind:
		"fox", "cat":
			for side in [-1, 1]:
				_poly(PackedVector2Array([hc + Vector2(side * 20, -46), hc + Vector2(side * 52, -92), hc + Vector2(side * 56, -24)]), earc)
				_poly(PackedVector2Array([hc + Vector2(side * 28, -46), hc + Vector2(side * 50, -80), hc + Vector2(side * 52, -34)]), acc if kind == "cat" else Color("343a40"))
		"raccoon", "bear":
			_circ(hc + Vector2(-44, -42), 20, earc)
			_circ(hc + Vector2(44, -42), 20, earc)
			_circ(hc + Vector2(-44, -42), 10, belly)
			_circ(hc + Vector2(44, -42), 10, belly)
		"owl":
			_poly(PackedVector2Array([hc + Vector2(-50, -30), hc + Vector2(-46, -80), hc + Vector2(-20, -50)]), earc)
			_poly(PackedVector2Array([hc + Vector2(50, -30), hc + Vector2(46, -80), hc + Vector2(20, -50)]), earc)
		"robot":
			draw_line(hc + Vector2(0, -56), hc + Vector2(0, -86), Color("495057"), 5, true)
			_circ(hc + Vector2(0, -90), 10, acc if sin(_t * 4.0) > 0 else acc.darkened(0.4))
	if kind == "robot":
		_rect(Rect2(hc + Vector2(-58, -54), Vector2(116, 100)), bodyc)
		_rect(Rect2(hc + Vector2(-46, -42), Vector2(92, 76)), Color("1b264d"))
		_face(hc + Vector2(0, -2), 50, Color("69db7c"), Color("69db7c"), false)
		return
	_circ(hc, hr, bodyc)
	if kind == "fox":
		_poly(PackedVector2Array([hc + Vector2(-50, 10), hc + Vector2(0, 52), hc + Vector2(50, 10), hc + Vector2(0, 0)]), belly)
	if kind == "raccoon":
		_draw_ellipse(hc + Vector2(-22, 0), Vector2(26, 18), acc)
		_draw_ellipse(hc + Vector2(22, 0), Vector2(26, 18), acc)
	if kind == "owl":
		_circ(hc + Vector2(-22, 0), 24, belly)
		_circ(hc + Vector2(22, 0), 24, belly)
		_poly(PackedVector2Array([hc + Vector2(-7, 18), hc + Vector2(7, 18), hc + Vector2(0, 32)]), acc)
		# очки совы-библиотекаря
		draw_arc(hc + Vector2(-22, 0), 26, 0, TAU, 24, Color("495057"), 3, true)
		draw_arc(hc + Vector2(22, 0), 26, 0, TAU, 24, Color("495057"), 3, true)
	_face(hc + Vector2(0, 6), hr * 0.92, Color("2b2d42"), Color("2b2d42"), kind != "owl")
	_circ(hc + Vector2(0, 24), 7, Color("343a40"))
	if kind == "cat" or kind == "fox":
		for side in [-1, 1]:
			for i in 2:
				draw_line(hc + Vector2(side * 18, 28 + i * 8), hc + Vector2(side * 52, 24 + i * 12), Color(0.2, 0.2, 0.2, 0.6), 2, true)


# ---------- мультяшная обводка и объём ----------
const OUT := 3.5   # толщина контура (в единицах рисунка 300 px высотой)


func _ol_col(col: Color) -> Color:
	var c = col.darkened(0.55)
	c.s = minf(1.0, c.s * 1.1)
	c.a = col.a
	return c


## Круг с контуром и бликом (мелкие и полупрозрачные — без контура).
func _circ(c: Vector2, r: float, col: Color) -> void:
	if r < 8.0 or col.a < 0.95:
		draw_circle(c, r, col)
		return
	draw_circle(c, r + OUT, _ol_col(col))
	draw_circle(c, r, col)
	if r >= 18.0:
		# мягкая тень снизу и блик сверху — объём
		draw_circle(c + Vector2(r * 0.12, r * 0.14), r * 0.86, Color(col.darkened(0.12), 0.55))
		draw_circle(c + Vector2(-r * 0.05, -r * 0.06), r * 0.8, col)
		draw_circle(c + Vector2(-r * 0.35, -r * 0.4), r * 0.22, Color(1, 1, 1, 0.28))


func _poly(pts: PackedVector2Array, col: Color) -> void:
	if col.a >= 0.95 and pts.size() >= 3:
		var closed = pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, _ol_col(col), OUT * 2.0, true)
	draw_colored_polygon(pts, col)


func _rect(r: Rect2, col: Color) -> void:
	if col.a >= 0.95:
		draw_rect(r.grow(OUT), _ol_col(col))
	draw_rect(r, col)
	if r.size.x > 30 and col.a >= 0.95:
		draw_rect(Rect2(r.position + Vector2(4, 4), Vector2(r.size.x - 8, r.size.y * 0.18)), Color(1, 1, 1, 0.16))
