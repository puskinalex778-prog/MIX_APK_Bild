class_name Scenery
extends Control
## Живой фон в стиле ostrova-znaniy: яркий градиент неба, вращающееся солнце с лучами,
## мерцающие искорки, объёмные облака, 3-слойное волнистое море и парящие острова
## с деревьями, домиками, цветочками и светящимися фонарями.

var mode = "sky"            # sky | map | calm | night
var islands: Array = []      # [{pos: Vector2 (0..1), color: Color, lit: float 0..1, subj: String}]
var _t = 0.0
var _clouds: Array = []
var _stars: Array = []
var _sky_sparkles: Array = []


func _init(m: String = "sky") -> void:
	mode = m
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var presets = [
		{"x": 0.08, "y": 0.10, "s": 1.15, "v": 0.011, "a": 0.95},
		{"x": 0.48, "y": 0.22, "s": 0.85, "v": 0.008, "a": 0.82},
		{"x": 0.78, "y": 0.38, "s": 1.25, "v": 0.006, "a": 0.72},
		{"x": 0.28, "y": 0.15, "s": 0.68, "v": 0.010, "a": 0.88},
		{"x": 0.64, "y": 0.50, "s": 0.95, "v": 0.005, "a": 0.62},
	]
	_clouds = presets
	for i in 70:
		_stars.append(Vector3(randf(), randf() * 0.62, randf()))
	for i in 16:
		_sky_sparkles.append(Vector4(randf(), randf_range(0.05, 0.56), randf() * TAU, randf_range(1.6, 3.2)))


func _process(delta: float) -> void:
	if not Settings.reduce_motion:
		_t += delta
	queue_redraw()


func _bg_name() -> String:
	return "bg/" + ("sky" if mode == "map" else mode)


func _draw() -> void:
	var W = size.x
	var H = size.y
	var bg = ArtLib.tex(_bg_name())
	if bg:
		ArtLib.draw_cover(self, bg, Rect2(Vector2.ZERO, size))
	else:
		_draw_sky(W, H)
		for cl in _clouds:
			var x = fmod(cl["x"] + _t * cl["v"], 1.32) - 0.16
			_cloud(Vector2(x * W, cl["y"] * H), cl["s"], cl["a"])
		_draw_sky_sparkles(W, H)
		_draw_sea(W, H)
	for i in islands.size():
		var isl = islands[i]
		_island(Vector2(isl["pos"].x * W, isl["pos"].y * H), isl.get("color", Color("5b6cff")),
			float(isl.get("lit", 0.0)), float(isl.get("scale", 1.0)), str(isl.get("subj", "")), i)


func _vgrad(rect: Rect2, top: Color, bottom: Color) -> void:
	draw_polygon(PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]),
		PackedColorArray([top, top, bottom, bottom]))


func _draw_sky(W: float, H: float) -> void:
	if mode == "night":
		_vgrad(Rect2(0, 0, W, H * 0.45), Color("161b48"), Color("2b3582"))
		_vgrad(Rect2(0, H * 0.45, W, H * 0.35), Color("2b3582"), Color("5b6cff"))
		for s in _stars:
			var tw = 0.5 + 0.5 * sin(_t * 2.2 + s.z * 40.0)
			var p = Vector2(s.x * W, s.y * H)
			draw_circle(p, 1.3 + tw * 1.4, Color(1, 1, 0.88, 0.45 + tw * 0.55))
		var moon = Vector2(W * 0.86, H * 0.15)
		for i in 4:
			draw_circle(moon, 72 - i * 10, Color(1, 0.96, 0.78, 0.06 + i * 0.03))
		draw_circle(moon, 40, Color("fff3bf"))
		draw_circle(moon + Vector2(14, -8), 34, Color("202863"))
	elif mode == "calm":
		# мягкий закат из .dusk (style.css)
		_vgrad(Rect2(0, 0, W, H * 0.40), Color("6a5cff"), Color("a68cff"))
		_vgrad(Rect2(0, H * 0.40, W, H * 0.35), Color("a68cff"), Color("ffb3c7"))
		_vgrad(Rect2(0, H * 0.75, W, H * 0.25), Color("ffb3c7"), Color("ffd2a8"))
		_draw_sun(Vector2(W * 0.89, H * 0.14), 0.92)
	else:
		# яркое сказочное небо из #scene (style.css)
		_vgrad(Rect2(0, 0, W, H * 0.38), Color("5f8dff"), Color("8fb8ff"))
		_vgrad(Rect2(0, H * 0.38, W, H * 0.24), Color("8fb8ff"), Color("c9e0ff"))
		_vgrad(Rect2(0, H * 0.62, W, H * 0.18), Color("c9e0ff"), Color("ffe3f0"))
		_vgrad(Rect2(0, H * 0.80, W, H * 0.20), Color("ffe3f0"), Color("ffd9c2"))
		_draw_sun(Vector2(W * 0.89, H * 0.14), 1.0)


func _draw_sun(sun: Vector2, sc: float) -> void:
	var rot = _t * 0.16
	for i in 12:
		var a = rot + TAU * i / 12.0
		var a2 = a + 0.14
		draw_colored_polygon(PackedVector2Array([sun, sun + Vector2(cos(a), sin(a)) * (115.0 * sc), sun + Vector2(cos(a2), sin(a2)) * (115.0 * sc)]), Color(1.0, 0.93, 0.58, 0.24))
	for i in 4:
		draw_circle(sun, (82 - i * 13) * sc, Color(1.0, 0.88, 0.40, 0.10 + i * 0.08))
	draw_circle(sun, 42 * sc, Color("ffb627"))
	draw_circle(sun + Vector2(-4, -4) * sc, 36 * sc, Color("ffe16b"))
	draw_circle(sun + Vector2(-12, -12) * sc, 16 * sc, Color("fffbe0"))


func _draw_sky_sparkles(W: float, H: float) -> void:
	for sp in _sky_sparkles:
		var tw = maxf(0.0, sin(_t * sp.w + sp.z))
		if tw > 0.15:
			var p = Vector2(sp.x * W, sp.y * H)
			var r = 2.0 + 3.2 * tw
			draw_circle(p, r * 2.2, Color(1, 1, 1, tw * 0.28))
			draw_circle(p, r, Color(1, 1, 1, tw * 0.92))


func _draw_sea(W: float, H: float) -> void:
	var layers = [
		{"y": H * 0.80, "col": Color("7ec8ff"), "alpha": 0.60, "amp": 12.0, "spd": 1.1, "freq": 0.016},
		{"y": H * 0.85, "col": Color("46a8f5"), "alpha": 0.80, "amp": 10.0, "spd": -1.5, "freq": 0.020},
		{"y": H * 0.91, "col": Color("2b8de6"), "alpha": 0.98, "amp": 8.0, "spd": 2.0, "freq": 0.024},
	]
	if mode == "night":
		layers[0]["col"] = Color("4c5fd5")
		layers[1]["col"] = Color("3647a8")
		layers[2]["col"] = Color("1f286b")
	for row in layers:
		var pts = PackedVector2Array()
		var n = 44
		for i in n + 1:
			var x = W * i / float(n)
			var y = row["y"] + sin(x * row["freq"] + _t * row["spd"]) * row["amp"]
			pts.append(Vector2(x, y))
		pts.append(Vector2(W, H + 4))
		pts.append(Vector2(0, H + 4))
		var col: Color = row["col"]
		col.a = row["alpha"]
		draw_colored_polygon(pts, col)


func _cloud(p: Vector2, s: float, op: float) -> void:
	var a = op if mode != "night" else 0.22
	var puffs = [Vector2(-48, 8), Vector2(-18, -14), Vector2(18, -18), Vector2(50, 6), Vector2(0, 10)]
	var rads = [26, 33, 31, 25, 30]
	for i in puffs.size():
		draw_circle(p + puffs[i] * s + Vector2(0, 8 * s), rads[i] * s, Color(0.32, 0.40, 0.78, a * 0.16))
	for i in puffs.size():
		draw_circle(p + puffs[i] * s, rads[i] * s, Color(1, 1, 1, a))


func _draw_ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in 28:
		var ang = TAU * i / 28.0
		pts.append(c + Vector2(cos(ang) * r.x, sin(ang) * r.y))
	draw_colored_polygon(pts, col)


func _island(p: Vector2, col: Color, lit: float, sc: float, subj: String, idx: int) -> void:
	var bob = sin(_t * 1.35 + idx * 1.25) * 9.0
	p.y += bob
	var w = 114.0 * sc
	var img = ArtLib.tex("islands/" + subj) if subj != "" else null
	if img:
		var sz = img.get_size() * (w * 2.3 / img.get_size().x)
		draw_texture_rect(img, Rect2(p - Vector2(sz.x * 0.5, sz.y * 0.38), sz), false)
		_lamp(p + Vector2(w * 0.62, -w * 0.25), lit, sc)
		return
	# мягкая тень под парящим островом
	_draw_ellipse(p + Vector2(0, w * 0.92 - bob * 0.4), Vector2(w * 0.78, w * 0.14), Color(0.12, 0.16, 0.48, 0.18))
	# скальная основа (многогранник как в Art.island)
	var rock = PackedVector2Array([
		p + Vector2(-w * 0.92, 4), p + Vector2(w * 0.92, 4),
		p + Vector2(w * 0.68, w * 0.32), p + Vector2(w * 0.42, w * 0.48),
		p + Vector2(w * 0.24, w * 0.74), p + Vector2(w * 0.04, w * 0.58),
		p + Vector2(-w * 0.18, w * 0.76), p + Vector2(-w * 0.38, w * 0.52),
		p + Vector2(-w * 0.66, w * 0.36),
	])
	draw_colored_polygon(rock, Color("9a6a42"))
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(0, 4), p + Vector2(w * 0.92, 4),
		p + Vector2(w * 0.68, w * 0.32), p + Vector2(w * 0.42, w * 0.48),
		p + Vector2(w * 0.24, w * 0.74), p + Vector2(w * 0.04, w * 0.58),
	]), Color("754b2c"))
	draw_line(p + Vector2(-w * 0.55, w * 0.22), p + Vector2(-w * 0.25, w * 0.27), Color(0, 0, 0, 0.18), 3.0, true)
	draw_line(p + Vector2(w * 0.20, w * 0.28), p + Vector2(w * 0.55, w * 0.22), Color(0, 0, 0, 0.18), 3.0, true)
	# верхняя цветная шапка-лужайка с бликом
	var c_dark = col.darkened(0.22)
	var c_light = col.lightened(0.16)
	_draw_ellipse(p + Vector2(0, 4), Vector2(w, w * 0.24), c_dark)
	_draw_ellipse(p + Vector2(0, -2), Vector2(w, w * 0.22), c_light)
	_draw_ellipse(p + Vector2(-w * 0.18, -8), Vector2(w * 0.54, w * 0.09), Color(1, 1, 1, 0.22))
	# дерево слева
	var tr = p + Vector2(-w * 0.52, -w * 0.06)
	draw_line(tr, tr + Vector2(0, -34 * sc), Color("8b5a2b"), 7.5 * sc, true)
	var sway = sin(_t * 1.5 + idx) * 2.0
	draw_circle(tr + Vector2(-12 + sway, -36) * sc, 14 * sc, Color("22a35a"))
	draw_circle(tr + Vector2(12 + sway, -36) * sc, 14 * sc, Color("22a35a"))
	draw_circle(tr + Vector2(sway, -48) * sc, 19 * sc, Color("48d682"))
	draw_circle(tr + Vector2(-6 + sway, -54) * sc, 5.5 * sc, Color(1, 1, 1, 0.35))
	# уютный домик в центре
	var hb = p + Vector2(0, -w * 0.04)
	var hw = 42.0 * sc
	var hh = 32.0 * sc
	draw_rect(Rect2(hb + Vector2(-hw * 0.5, -hh), Vector2(hw, hh)), Color("fff4e0"))
	var roof = PackedVector2Array([hb + Vector2(-hw * 0.65, -hh + 3), hb + Vector2(0, -hh - 26 * sc), hb + Vector2(hw * 0.65, -hh + 3)])
	draw_colored_polygon(roof, c_dark)
	var r_out = roof.duplicate()
	r_out.append(roof[0])
	draw_polyline(r_out, Color.WHITE, 3.0, true)
	draw_rect(Rect2(hb + Vector2(-hw * 0.16, -hh * 0.62), Vector2(hw * 0.32, hh * 0.62)), Color("b06b3a"))
	draw_rect(Rect2(hb + Vector2(hw * 0.20, -hh * 0.72), Vector2(hw * 0.22, hh * 0.26)), Color("ffe066") if lit > 0.0 else Color("9fb6d9"))
	# цветочки на траве
	draw_circle(p + Vector2(-w * 0.28, 2), 3.2 * sc, Color.WHITE)
	draw_circle(p + Vector2(w * 0.34, 4), 3.2 * sc, Color("ffe066"))
	draw_circle(p + Vector2(w * 0.68, 0), 2.8 * sc, Color("ff8fab"))
	draw_circle(p + Vector2(-w * 0.70, 0), 2.8 * sc, Color("ffe066"))
	# фонарь справа
	_lamp(p + Vector2(w * 0.56, -w * 0.08), lit, sc)


func _lamp(lp: Vector2, lit: float, sc: float) -> void:
	draw_line(lp, lp + Vector2(0, -42 * sc), Color("5a5f7a"), 4.5 * sc, true)
	var glow = (0.65 + 0.35 * sin(_t * 2.6)) if lit > 0.0 else 0.0
	var head = lp + Vector2(0, -48 * sc)
	if lit > 0.0:
		for i in 3:
			draw_circle(head, (28 - i * 7) * sc, Color(1.0, 0.92, 0.45, (0.16 + i * 0.10) * glow))
	draw_circle(head, 9.5 * sc, Color("5a5f7a"))
	draw_circle(head, 7.5 * sc, Color("ffe066") if lit > 0.0 else Color("8a90ad"))
	draw_circle(head + Vector2(-2.2, -2.2) * sc, 2.5 * sc, Color(1, 1, 1, 0.7))
