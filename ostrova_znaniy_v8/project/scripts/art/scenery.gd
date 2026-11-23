class_name Scenery
extends Control
## Анимированный фон: небо с плавным градиентом, солнце с лучами, дальние горы,
## облака с объёмом, море с бликами и парящие острова с деревьями и домиками.
## Если есть картинки assets/art/bg/<mode>.png или assets/art/islands/<предмет>.png —
## используются они (см. ArtLib).

var mode = "sky"            # sky | map | calm | night
var islands: Array = []      # [{pos: Vector2 (0..1), color: Color, lit: float 0..1, subj: String}]
var _t = 0.0
var _clouds: Array = []
var _stars: Array = []
var _sparkles: Array = []


func _init(m: String = "sky") -> void:
	mode = m
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 6:
		_clouds.append({"x": randf(), "y": randf_range(0.05, 0.32), "s": randf_range(0.6, 1.25), "v": randf_range(0.004, 0.012)})
	for i in 70:
		_stars.append(Vector3(randf(), randf() * 0.62, randf()))
	for i in 18:
		_sparkles.append(Vector3(randf(), randf_range(0.76, 0.98), randf() * TAU))


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
			var x = fmod(cl["x"] + _t * cl["v"], 1.25) - 0.12
			_cloud(Vector2(x * W, cl["y"] * H), cl["s"])
		_draw_sea(W, H)
	for isl in islands:
		_island(Vector2(isl["pos"].x * W, isl["pos"].y * H), isl.get("color", Color("51cf66")), float(isl.get("lit", 0.0)),
			float(isl.get("scale", 1.0)), str(isl.get("subj", "")))


func _vgrad(rect: Rect2, top: Color, bottom: Color) -> void:
	draw_polygon(PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]),
		PackedColorArray([top, top, bottom, bottom]))


func _draw_sky(W: float, H: float) -> void:
	var top = Color("3a8ee6")
	var mid = Color("8ec9ff")
	var bottom = Color("e3f3ff")
	if mode == "night":
		top = Color("0f1739")
		mid = Color("24306b")
		bottom = Color("4c5fd5")
	elif mode == "calm":
		top = Color("9775fa")
		mid = Color("e599f7")
		bottom = Color("ffe8cc")
	_vgrad(Rect2(0, 0, W, H * 0.45), top, mid)
	_vgrad(Rect2(0, H * 0.45, W, H * 0.3), mid, bottom)
	if mode == "night":
		for s in _stars:
			var tw = 0.5 + 0.5 * sin(_t * 2.0 + s.z * 40.0)
			var p = Vector2(s.x * W, s.y * H)
			draw_circle(p, 1.2 + tw * 1.2, Color(1, 1, 0.85, 0.45 + tw * 0.5))
			if s.z > 0.85:
				draw_line(p - Vector2(5, 0), p + Vector2(5, 0), Color(1, 1, 0.9, 0.4 * tw), 1.0, true)
				draw_line(p - Vector2(0, 5), p + Vector2(0, 5), Color(1, 1, 0.9, 0.4 * tw), 1.0, true)
		var moon = Vector2(W * 0.85, H * 0.15)
		for i in 4:
			draw_circle(moon, 70 - i * 9, Color(1, 0.97, 0.8, 0.05 + i * 0.03))
		draw_circle(moon, 40, Color("fff3bf"))
		draw_circle(moon + Vector2(14, -8), 34, Color(top.lerp(mid, 0.3), 1.0))
	else:
		var sun = Vector2(W * 0.88, H * 0.14)
		var rot = _t * 0.15
		for i in 12:
			var a = rot + TAU * i / 12.0
			var a2 = a + 0.12
			draw_colored_polygon(PackedVector2Array([sun, sun + Vector2(cos(a), sin(a)) * 120, sun + Vector2(cos(a2), sin(a2)) * 120]), Color(1, 0.95, 0.6, 0.18))
		for i in 4:
			draw_circle(sun, 80 - i * 12, Color(1, 0.9, 0.45, 0.08 + i * 0.07))
		draw_circle(sun, 46, Color("ffd43b"))
		draw_circle(sun + Vector2(-10, -10), 34, Color("ffe066"))
		draw_circle(sun + Vector2(-16, -16), 12, Color(1, 1, 1, 0.45))
	# дальние горы у горизонта (два плана)
	var horizon = H * 0.72
	for layer in 2:
		var col = Color("a5d8ff") if layer == 0 else Color("74c0fc")
		if mode == "night":
			col = Color("2c3a80") if layer == 0 else Color("364fc7")
		elif mode == "calm":
			col = Color("d0bfff") if layer == 0 else Color("b197fc")
		var pts = PackedVector2Array([Vector2(0, horizon)])
		var n = 14
		for i in n + 1:
			var x = W * i / float(n)
			var h = (40 + 30 * sin(i * 1.7 + layer * 2.0) + 20 * sin(i * 0.6 + layer)) * (1.3 if layer == 0 else 0.8)
			pts.append(Vector2(x, horizon - h))
		pts.append(Vector2(W, horizon))
		draw_colored_polygon(pts, col)


func _draw_sea(W: float, H: float) -> void:
	var sea_y = H * 0.72
	var top = Color("4dabf7")
	var bottom = Color("1864ab")
	if mode == "night":
		top = Color("364fc7")
		bottom = Color("1b264d")
	elif mode == "calm":
		top = Color("91a7ff")
		bottom = Color("5c7cfa")
	_vgrad(Rect2(0, sea_y, W, H - sea_y), top, bottom)
	draw_rect(Rect2(0, sea_y, W, 3), Color(1, 1, 1, 0.5))
	for row in 5:
		var y = sea_y + 12 + row * 22
		var pts = PackedVector2Array()
		for i in 49:
			var x = W * i / 48.0
			pts.append(Vector2(x, y + sin(x * (0.028 + row * 0.004) + _t * (1.3 + row * 0.25) + row) * (3 + row)))
		draw_polyline(pts, Color(1, 1, 1, 0.28 - row * 0.045), 3.0 - row * 0.3, true)
	for sp in _sparkles:
		var tw = maxf(0.0, sin(_t * 2.5 + sp.z))
		if tw > 0.6:
			var p = Vector2(sp.x * W, sp.y * H)
			var r = 6.0 * tw
			draw_line(p - Vector2(r, 0), p + Vector2(r, 0), Color(1, 1, 1, tw * 0.8), 2.0, true)
			draw_line(p - Vector2(0, r * 0.6), p + Vector2(0, r * 0.6), Color(1, 1, 1, tw * 0.8), 2.0, true)


func _cloud(p: Vector2, s: float) -> void:
	var a = 0.92 if mode != "night" else 0.25
	var puffs = [Vector2(-42, 6), Vector2(-14, -16), Vector2(20, -20), Vector2(46, 4), Vector2(0, 10)]
	var rads = [26, 32, 30, 24, 30]
	for i in puffs.size():
		draw_circle(p + puffs[i] * s + Vector2(0, 6 * s), rads[i] * s, Color(0.75, 0.82, 0.92, a * 0.7))
	for i in puffs.size():
		draw_circle(p + puffs[i] * s, rads[i] * s, Color(1, 1, 1, a))
	draw_circle(p + Vector2(-16, -24) * s, 10 * s, Color(1, 1, 1, a))


func _island(p: Vector2, col: Color, lit: float, sc: float, subj: String) -> void:
	var bob = sin(_t * 1.2 + p.x * 0.01) * 6.0
	p.y += bob
	var w = 120.0 * sc
	var img = ArtLib.tex("islands/" + subj) if subj != "" else null
	if img:
		var sz = img.get_size() * (w * 2.3 / img.get_size().x)
		draw_texture_rect(img, Rect2(p - Vector2(sz.x * 0.5, sz.y * 0.38), sz), false)
		_lamp(p + Vector2(w * 0.62, -w * 0.25), lit, sc)
		return
	# тень на воде
	draw_set_transform(p + Vector2(0, w * 1.25 - bob), 0.0, Vector2(1.0, 0.18))
	draw_circle(Vector2.ZERO, w * 0.8, Color(0, 0, 0.2, 0.12))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# скала: слои камня
	var rock = PackedVector2Array([p + Vector2(-w, 0), p + Vector2(w, 0), p + Vector2(w * 0.7, w * 0.35), p + Vector2(w * 0.35, w * 0.62),
		p + Vector2(0, w * 0.92), p + Vector2(-w * 0.4, w * 0.6), p + Vector2(-w * 0.75, w * 0.3)])
	var closed = rock.duplicate()
	closed.append(rock[0])
	draw_polyline(closed, Color("5c3d22"), 5.0, true)
	draw_colored_polygon(rock, Color("b07d4f"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, 0), p + Vector2(w, 0), p + Vector2(w * 0.7, w * 0.35), p + Vector2(w * 0.35, w * 0.62), p + Vector2(0, w * 0.92)]), Color("8d5b34"))
	for i in 3:
		var yy = w * (0.18 + i * 0.2)
		draw_line(p + Vector2(-w * (0.85 - i * 0.22), yy), p + Vector2(w * (0.8 - i * 0.22), yy + 4), Color(0.3, 0.18, 0.1, 0.35), 3.0, true)
	draw_circle(p + Vector2(-w * 0.35, w * 0.2), w * 0.06, Color(1, 1, 1, 0.18))
	# трава с кромкой
	var pts = PackedVector2Array()
	for i in 25:
		var ang = PI + PI * i / 24.0
		pts.append(p + Vector2(cos(ang) * w, sin(ang) * w * 0.3))
	var g_closed = pts.duplicate()
	g_closed.append(pts[0])
	draw_polyline(g_closed, col.darkened(0.45), 5.0, true)
	draw_colored_polygon(pts, col)
	draw_rect(Rect2(p + Vector2(-w, -3), Vector2(w * 2, 12)), col.darkened(0.2))
	for i in 9:
		var x = -w * 0.95 + i * w * 0.235
		draw_colored_polygon(PackedVector2Array([p + Vector2(x, 8), p + Vector2(x + 9, 8), p + Vector2(x + 4, 22 + (i % 3) * 5)]), col.darkened(0.2))
	draw_arc(p + Vector2(-w * 0.2, -w * 0.06), w * 0.55, PI * 1.15, PI * 1.5, 12, Color(1, 1, 1, 0.3), 5.0, true)
	# дерево
	var tr = p + Vector2(-w * 0.55, -w * 0.12)
	draw_line(tr, tr + Vector2(0, -36 * sc), Color("6f4518"), 8 * sc, true)
	var sway = sin(_t * 1.5 + p.x) * 2.0
	for c in [Vector2(-14, -40), Vector2(14, -40), Vector2(0, -58)]:
		draw_circle(tr + (c + Vector2(sway, 0)) * sc, 20 * sc + 3, Color("1b5e20"))
	for c in [Vector2(-14, -40), Vector2(14, -40), Vector2(0, -58)]:
		draw_circle(tr + (c + Vector2(sway, 0)) * sc, 20 * sc, Color("40c057"))
	draw_circle(tr + Vector2(-6 + sway, -64) * sc, 7 * sc, Color(1, 1, 1, 0.3))
	# домик в цвете острова
	var hb = p + Vector2(-w * 0.05, -w * 0.18)
	var hw = 34.0 * sc
	draw_rect(Rect2(hb + Vector2(-hw * 0.5, -hw * 0.8), Vector2(hw, hw * 0.8)).grow(2.5), Color("5c3d22"))
	draw_rect(Rect2(hb + Vector2(-hw * 0.5, -hw * 0.8), Vector2(hw, hw * 0.8)), Color("fff4e6"))
	var roof = PackedVector2Array([hb + Vector2(-hw * 0.7, -hw * 0.75), hb + Vector2(0, -hw * 1.35), hb + Vector2(hw * 0.7, -hw * 0.75)])
	var r_closed = roof.duplicate()
	r_closed.append(roof[0])
	draw_polyline(r_closed, col.darkened(0.6), 5.0, true)
	draw_colored_polygon(roof, col.darkened(0.25))
	draw_rect(Rect2(hb + Vector2(-hw * 0.12, -hw * 0.42), Vector2(hw * 0.24, hw * 0.42)), Color("8d5b34"))
	draw_rect(Rect2(hb + Vector2(hw * 0.18, -hw * 0.62), Vector2(hw * 0.2, hw * 0.18)), Color("ffd43b") if lit > 0.0 else Color("a5d8ff"))
	_lamp(p + Vector2(w * 0.58, -w * 0.22), lit, sc)


func _lamp(lp: Vector2, lit: float, sc: float) -> void:
	draw_line(lp, lp + Vector2(0, -40 * sc), Color("343a40"), 5, true)
	var glow = lit * (0.8 + 0.2 * sin(_t * 3.0))
	var head = lp + Vector2(0, -50 * sc)
	if lit > 0.0:
		for i in 3:
			draw_circle(head, (36 - i * 8) * sc, Color(1, 0.85, 0.3, (0.12 + i * 0.08) * glow))
	draw_circle(head, 13 * sc, Color("343a40"))
	draw_circle(head, 10 * sc, Color("ffd43b") if lit > 0.0 else Color("868e96"))
	draw_circle(head + Vector2(-3, -3) * sc, 3 * sc, Color(1, 1, 1, 0.6))
