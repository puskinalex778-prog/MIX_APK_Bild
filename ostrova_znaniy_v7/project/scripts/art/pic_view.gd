class_name PicView
extends Control
## Рисунки к заданиям, построенные векторно по описанию из банка заданий
## (группы предметов, массивы, часы, линейка, диаграммы, фигуры, схемы движения и т. д.).

var spec = {}
var _font: Font
var _bold: Font
var _emoji: Font
var _t = 0.0


func _init(s: Dictionary = {}) -> void:
	spec = s
	custom_minimum_size = Vector2(560, _height_for(s))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = UIKit.font("body")
	_bold = UIKit.font("bold")
	_emoji = UIKit.font("emoji")


static func _height_for(s: Dictionary) -> float:
	match str(s.get("k", "")):
		"big":
			return 200
		"emoji", "coins", "segment", "ruler", "column":
			return 170 if s.get("k") != "column" else 200
		"bars":
			return 260
		"clock", "circle", "fraction", "compass", "therm", "scale":
			return 230
		"array", "groups":
			return clampf(60.0 + float(s.get("r", s.get("g", 2))) * 52.0, 160.0, 380.0)
	return 240


func _process(delta: float) -> void:
	if spec.get("k") in ["motion", "compass"] and not Settings.reduce_motion:
		_t += delta
		queue_redraw()


func _txt(p: Vector2, text: String, size: int = 22, col: Color = UIKit.C_TEXT, center: bool = true, bold: bool = false) -> void:
	var f = _bold if bold else _font
	var w = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(f, p - Vector2(w * 0.5 if center else 0.0, -size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _emo(p: Vector2, e: String, size: int = 40) -> void:
	var w = _emoji.get_string_size(e, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(_emoji, p - Vector2(w * 0.5, -size * 0.35), e, HORIZONTAL_ALIGNMENT_LEFT, -1, size)


func _draw() -> void:
	var W = size.x
	var H = size.y
	draw_style_box(UIKit.sb(Color("f8f9ff"), 20, 2, Color("dbe4ff")), Rect2(Vector2.ZERO, size))
	var c = Vector2(W * 0.5, H * 0.5)
	var k = str(spec.get("k", ""))
	match k:
		"big":
			_emo(c, str(spec.get("e", "❓")), 120)
		"emoji":
			var items: Array = spec.get("items", [])
			var n = items.size()
			var step = minf(80.0, (W - 40) / maxf(1, n))
			for i in n:
				_emo(Vector2(W * 0.5 + (i - (n - 1) * 0.5) * step, H * 0.5), str(items[i]), int(step * 0.7))
		"groups":
			_draw_groups(W, H)
		"array":
			var r = int(spec.get("r", 2))
			var cc = int(spec.get("c", 3))
			var cell = minf((W - 60) / cc, (H - 40) / r)
			cell = minf(cell, 60)
			var origin = Vector2((W - cell * cc) * 0.5, (H - cell * r) * 0.5)
			for y in r:
				for x in cc:
					_emo(origin + Vector2(x + 0.5, y + 0.5) * cell, str(spec.get("e", "⭐")), int(cell * 0.75))
		"tens":
			_draw_tens(W, H)
		"ruler", "segment":
			_draw_ruler(W, H)
		"clock":
			_draw_clock(c, minf(W, H) * 0.42, int(spec.get("h", 3)), int(spec.get("m", 0)))
		"polyline":
			_draw_polyline(W, H)
		"polygon":
			_draw_polygon(W, H)
		"rect":
			var w = float(spec.get("w", 4))
			var h = float(spec.get("h", 2))
			var sc = minf((W - 160) / w, (H - 80) / h)
			var rr = Rect2(c - Vector2(w, h) * sc * 0.5, Vector2(w, h) * sc)
			draw_rect(rr, Color("d0ebff"))
			draw_rect(rr, UIKit.C_PRIMARY, false, 4)
			var u = str(spec.get("u", "см"))
			_txt(Vector2(rr.get_center().x, rr.position.y - 18), "%s %s" % [_num(w), u], 22, UIKit.C_TEXT, true, true)
			_txt(Vector2(rr.end.x + 46, rr.get_center().y), "%s %s" % [_num(h), u], 22, UIKit.C_TEXT, true, true)
		"angle":
			_draw_angle(c, float(spec.get("deg", 90)))
		"bars":
			_draw_bars(W, H)
		"coins":
			_draw_coins(W, H)
		"column":
			_draw_column(W, H)
		"symmetry":
			_draw_symmetry(c, H)
		"circle":
			var R = minf(W, H) * 0.38
			draw_circle(c, R, Color("e7f5ff"))
			draw_arc(c, R, 0, TAU, 64, UIKit.C_PRIMARY, 4, true)
			draw_circle(c, 5, UIKit.C_TEXT)
			_txt(c + Vector2(-14, 16), "O", 20)
			var show = str(spec.get("show", "radius"))
			if show == "diameter":
				draw_line(c - Vector2(R, 0), c + Vector2(R, 0), UIKit.C_BAD, 4, true)
				_txt(c + Vector2(0, -16), "d = ?", 22, UIKit.C_BAD, true, true)
			else:
				draw_line(c, c + Vector2(R, 0), UIKit.C_BAD, 4, true)
				_txt(c + Vector2(R * 0.5, -16), "r = %s см" % str(spec.get("r", "")), 22, UIKit.C_BAD, true, true)
		"fraction":
			var parts = int(spec.get("parts", 4))
			var sh = int(spec.get("shaded", 1))
			var R2 = minf(W, H) * 0.38
			for i in parts:
				var a0 = -PI / 2 + TAU * i / parts
				var a1 = -PI / 2 + TAU * (i + 1) / parts
				var pts = PackedVector2Array([c])
				for j in 13:
					var ang = a0 + (a1 - a0) * j / 12.0
					pts.append(c + Vector2(cos(ang), sin(ang)) * R2)
				draw_colored_polygon(pts, Color("ffa94d") if i < sh else Color("fff4e6"))
				draw_line(c, c + Vector2(cos(a0), sin(a0)) * R2, Color("495057"), 2, true)
			draw_arc(c, R2, 0, TAU, 64, Color("495057"), 3, true)
		"grid":
			_draw_grid(W, H, int(spec.get("w", 3)), int(spec.get("h", 2)))
		"paletka":
			_draw_paletka(W, H)
		"tri":
			_draw_tri(W, H)
		"letters":
			_draw_letters(W, H)
		"motion":
			_draw_motion(W, H)
		"blocks":
			_draw_blocks(W, H)
		"scale":
			_draw_scale(c, W, H)
		"compass":
			_draw_compass(c, minf(W, H) * 0.4)
		"therm":
			_draw_therm(c, H, int(spec.get("t", 10)))


func _num(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, round(v)) else str(v)


func _draw_groups(W: float, H: float) -> void:
	var g = int(spec.get("g", 3))
	var n = int(spec.get("n", 4))
	var e = str(spec.get("e", "🍎"))
	var cols = mini(g, 5)
	var rows = int(ceil(g / float(cols)))
	var bw = (W - 30) / cols
	var bh = (H - 20) / rows
	for i in g:
		var bx = 15 + (i % cols) * bw
		var by = 10 + (i / cols) * bh
		var r = Rect2(bx + 6, by + 6, bw - 12, bh - 12)
		draw_style_box(UIKit.sb(Color("fff9db"), 18, 3, Color("fcc419")), r)
		var per_row = mini(n, 3 if bw < 160 else 5)
		var prow = int(ceil(n / float(per_row)))
		var cell = minf(r.size.x / per_row, r.size.y / prow)
		for j in n:
			var p = r.position + Vector2((j % per_row + 0.5) * r.size.x / per_row, (j / per_row + 0.5) * r.size.y / prow)
			_emo(p, e, int(minf(cell * 0.8, 44)))


func _draw_tens(W: float, H: float) -> void:
	var tens = int(spec.get("tens", 0))
	var ones = int(spec.get("ones", 0))
	var x = 30.0
	for i in tens:
		for j in 10:
			draw_rect(Rect2(x, 20 + j * ((H - 40) / 10.0), 18, (H - 40) / 10.0 - 2), Color("ffa94d"))
		draw_rect(Rect2(x - 2, 18, 22, H - 36), Color("e8590c"), false, 2)
		x += 30
		if x > W - 120:
			break
	x += 20
	for i in ones:
		draw_rect(Rect2(x + (i % 5) * 26, H * 0.5 - 30 + (i / 5) * 30, 22, 22), Color("74c0fc"))


func _draw_ruler(W: float, H: float) -> void:
	var mm = int(spec.get("mm", 50))
	var total_cm = int(ceil(mm / 10.0)) + 1
	var scale = minf((W - 60) / (total_cm * 10.0), 9.0)
	var x0 = (W - total_cm * 10 * scale) * 0.5
	var y = H * 0.62
	draw_rect(Rect2(x0 - 10, y, total_cm * 10 * scale + 20, 50), Color("fff3bf"))
	for i in range(total_cm * 10 + 1):
		var x = x0 + i * scale
		var hh = 24.0 if i % 10 == 0 else (16.0 if i % 5 == 0 else 9.0)
		draw_line(Vector2(x, y), Vector2(x, y + hh), Color("495057"), 2 if i % 10 == 0 else 1)
		if i % 10 == 0:
			_txt(Vector2(x, y + 38), str(i / 10), 16)
	draw_line(Vector2(x0, y - 28), Vector2(x0 + mm * scale, y - 28), UIKit.C_BAD, 6, true)
	draw_circle(Vector2(x0, y - 28), 6, UIKit.C_BAD)
	draw_circle(Vector2(x0 + mm * scale, y - 28), 6, UIKit.C_BAD)


func _draw_clock(c: Vector2, R: float, h: int, m: int) -> void:
	draw_circle(c, R + 8, Color("4c6ef5"))
	draw_circle(c, R, Color.WHITE)
	for i in 60:
		var ang = TAU * i / 60.0 - PI / 2
		var inner = R * (0.86 if i % 5 == 0 else 0.93)
		draw_line(c + Vector2(cos(ang), sin(ang)) * inner, c + Vector2(cos(ang), sin(ang)) * R * 0.98, Color("495057"), 3 if i % 5 == 0 else 1)
	for i in range(1, 13):
		var ang = TAU * i / 12.0 - PI / 2
		_txt(c + Vector2(cos(ang), sin(ang)) * R * 0.72, str(i), int(R * 0.17), UIKit.C_TEXT, true, true)
	var ma = TAU * m / 60.0 - PI / 2
	var ha = TAU * ((h % 12) + m / 60.0) / 12.0 - PI / 2
	draw_line(c, c + Vector2(cos(ha), sin(ha)) * R * 0.5, Color("212529"), 8, true)
	draw_line(c, c + Vector2(cos(ma), sin(ma)) * R * 0.8, Color("e8590c"), 5, true)
	draw_circle(c, 8, Color("212529"))


func _draw_polyline(W: float, H: float) -> void:
	var segs: Array = spec.get("segs", [3, 4])
	var total = 0.0
	for s in segs:
		total += float(s)
	var scale = (W - 100) / maxf(total * 0.75, 1.0)
	var p = Vector2(50, H * 0.7)
	var up = true
	for s in segs:
		var len = float(s) * scale
		var ang = deg_to_rad(-35 if up else 35)
		var q = p + Vector2(cos(ang), sin(ang)) * len
		if q.y < 30:
			q.y = 30
		draw_line(p, q, UIKit.C_PRIMARY, 5, true)
		draw_circle(p, 6, UIKit.C_TEXT)
		_txt((p + q) * 0.5 + Vector2(0, -22 if up else 22), "%s см" % _num(float(s)), 20, UIKit.C_TEXT, true, true)
		p = q
		up = not up
	draw_circle(p, 6, UIKit.C_TEXT)


func _draw_polygon(W: float, H: float) -> void:
	var sides: Array = spec.get("sides", [3, 4, 5])
	var n = sides.size()
	var c = Vector2(W * 0.5, H * 0.52)
	var R = minf(W, H) * 0.36
	var pts = PackedVector2Array()
	for i in n:
		var ang = -PI / 2 + TAU * i / n
		pts.append(c + Vector2(cos(ang) * R * 1.3, sin(ang) * R))
	draw_colored_polygon(pts, Color("e7f5ff"))
	for i in n:
		var a = pts[i]
		var b = pts[(i + 1) % n]
		draw_line(a, b, UIKit.C_PRIMARY, 4, true)
		var mid = (a + b) * 0.5
		var out = (mid - c).normalized() * 26
		_txt(mid + out, "%s см" % _num(float(sides[i])), 19, UIKit.C_TEXT, true, true)


func _draw_angle(c: Vector2, deg: float) -> void:
	var o = c + Vector2(-90, 60)
	var L = 170.0
	draw_line(o, o + Vector2(L, 0), UIKit.C_TEXT, 5, true)
	var a = deg_to_rad(-deg)
	draw_line(o, o + Vector2(cos(a), sin(a)) * L, UIKit.C_TEXT, 5, true)
	if is_equal_approx(deg, 90):
		draw_rect(Rect2(o + Vector2(0, -26), Vector2(26, 26)), UIKit.C_BAD, false, 3)
	else:
		draw_arc(o, 40, a, 0, 24, UIKit.C_BAD, 3, true)
	draw_circle(o, 6, UIKit.C_TEXT)


func _draw_bars(W: float, H: float) -> void:
	var labels: Array = spec.get("labels", [])
	var values: Array = spec.get("values", [])
	var maxv = 1.0
	for v in values:
		maxv = maxf(maxv, float(v))
	var step = 1.0
	for s in [1, 2, 5, 10, 20, 50, 100]:
		if maxv / s <= 10:
			step = s
			break
	var top = ceil(maxv / step) * step
	var x0 = 60.0
	var y0 = H - 40.0
	var hgt = H - 80.0
	_txt(Vector2(W * 0.5, 18), str(spec.get("title", "")), 20, UIKit.C_MUTED, true, true)
	var v = 0.0
	while v <= top + 0.01:
		var y = y0 - hgt * v / top
		draw_line(Vector2(x0, y), Vector2(W - 20, y), Color("dee2e6"), 1)
		_txt(Vector2(x0 - 24, y), _num(v), 16, UIKit.C_MUTED)
		v += step
	var n = labels.size()
	var bw = (W - x0 - 30) / maxf(n, 1)
	var cols = [Color("4c6ef5"), Color("f76707"), Color("37b24d"), Color("ae3ec9"), Color("1098ad"), Color("f59f00")]
	for i in n:
		var hv = hgt * float(values[i]) / top
		var r = Rect2(x0 + i * bw + bw * 0.18, y0 - hv, bw * 0.64, hv)
		draw_rect(r, cols[i % cols.size()])
		_txt(Vector2(r.get_center().x, y0 + 18), str(labels[i]), 18)


func _draw_coins(W: float, H: float) -> void:
	var list = []
	for r in spec.get("rub", []):
		list.append([str(r) + " ₽", Color("ced4da") if int(r) < 10 else Color("ffd43b"), 34 + int(r) * 0.8])
	for k in spec.get("kop", []):
		list.append([str(k) + " к.", Color("e8a33d"), 28.0])
	var x = W * 0.5 - (list.size() - 1) * 50
	for it in list:
		draw_circle(Vector2(x, H * 0.5), it[2] + 3, it[1].darkened(0.3))
		draw_circle(Vector2(x, H * 0.5), it[2], it[1])
		_txt(Vector2(x, H * 0.5), it[0], 20, UIKit.C_TEXT, true, true)
		x += 100


func _draw_column(W: float, H: float) -> void:
	var a = str(spec.get("a", ""))
	var b = str(spec.get("b", ""))
	var op = str(spec.get("op", "+"))
	var size_px = 40
	var cw = 30.0
	var width = maxi(a.length(), b.length()) + 1
	var x_right = W * 0.5 + width * cw * 0.5
	for i in a.length():
		_txt(Vector2(x_right - (a.length() - i - 0.5) * cw, 50), a[i], size_px, UIKit.C_TEXT, true, true)
	for i in b.length():
		_txt(Vector2(x_right - (b.length() - i - 0.5) * cw, 100), b[i], size_px, UIKit.C_TEXT, true, true)
	_txt(Vector2(x_right - (width + 0.2) * cw, 75), op, size_px, UIKit.C_BAD, true, true)
	draw_line(Vector2(x_right - width * cw, 130), Vector2(x_right + 6, 130), UIKit.C_TEXT, 3)
	_txt(Vector2(x_right - width * cw * 0.5, 165), "?", size_px, UIKit.C_MUTED, true, true)


func _draw_symmetry(c: Vector2, H: float) -> void:
	var shape = str(spec.get("shape", "heart"))
	var sym = bool(spec.get("sym", true))
	var col = Color("f783ac")
	match shape:
		"butterfly":
			for side in [-1, 1]:
				draw_circle(c + Vector2(side * 50, -25), 45, Color("9775fa"))
				draw_circle(c + Vector2(side * 38, 40), 32, Color("b197fc"))
			draw_line(c + Vector2(0, -70), c + Vector2(0, 75), Color("343a40"), 8, true)
		"heart":
			draw_circle(c + Vector2(-35, -20), 42, col)
			draw_circle(c + Vector2(35, -20), 42, col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-75, -5), c + Vector2(75, -5), c + Vector2(0, 80)]), col)
		"leaf":
			_leaf(c)
		"flag_l":
			draw_rect(Rect2(c + Vector2(-70, -70), Vector2(12, 150)), Color("495057"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-58, -70), c + Vector2(70, -40), c + Vector2(-58, -5)]), Color("fa5252"))
		"cloud_a":
			draw_circle(c + Vector2(-50, 10), 34, Color("74c0fc"))
			draw_circle(c + Vector2(-5, -20), 46, Color("74c0fc"))
			draw_circle(c + Vector2(50, 25), 24, Color("74c0fc"))
	# ось
	for i in 12:
		var y0 = c.y - 100 + i * 18
		draw_line(Vector2(c.x, y0), Vector2(c.x, y0 + 10), UIKit.C_PRIMARY, 3)


func _leaf(c: Vector2) -> void:
	var pts = PackedVector2Array()
	for i in 25:
		var t = PI * i / 24.0
		pts.append(c + Vector2(sin(t) * 60, -cos(t) * 85))
	for i in 25:
		var t = PI * i / 24.0
		pts.append(c + Vector2(-sin(PI - t) * 60, -cos(PI - t) * 85))
	draw_colored_polygon(pts, Color("51cf66"))
	draw_line(c + Vector2(0, -85), c + Vector2(0, 95), Color("2b8a3e"), 4)


func _draw_grid(W: float, H: float, w: int, h: int) -> void:
	var cell = minf((W - 80) / (w + 2), (H - 40) / (h + 1))
	cell = minf(cell, 48)
	var gw = w + 2
	var gh = h + 1
	var o = Vector2((W - gw * cell) * 0.5, (H - gh * cell) * 0.5)
	for y in gh:
		for x in gw:
			draw_rect(Rect2(o + Vector2(x, y) * cell, Vector2(cell, cell)), Color("dee2e6"), false, 1)
	draw_rect(Rect2(o + Vector2(1, 0.5) * cell, Vector2(w, h) * cell), Color(0.3, 0.43, 0.96, 0.35))
	draw_rect(Rect2(o + Vector2(1, 0.5) * cell, Vector2(w, h) * cell), UIKit.C_PRIMARY, false, 3)


func _draw_paletka(W: float, H: float) -> void:
	var cell = 26.0
	var o = Vector2(W * 0.5 - 7 * cell, 20)
	var c = Vector2(W * 0.5, H * 0.5)
	var pts = PackedVector2Array()
	for i in 40:
		var ang = TAU * i / 40.0
		var rr = 1.0 + 0.18 * sin(ang * 3.0)
		pts.append(c + Vector2(cos(ang) * 110 * rr, sin(ang) * 80 * rr))
	draw_colored_polygon(pts, Color("b2f2bb"))
	for y in int((H - 40) / cell):
		for x in 14:
			draw_rect(Rect2(o + Vector2(x, y) * cell, Vector2(cell, cell)), Color(0.2, 0.3, 0.6, 0.35), false, 1)


func _draw_tri(W: float, H: float) -> void:
	var c = Vector2(W * 0.5, H * 0.55)
	var pts: PackedVector2Array
	if spec.has("angles"):
		var ang: Array = spec["angles"]
		var big = float(ang.max())
		if big > 90.5:
			pts = PackedVector2Array([c + Vector2(-150, 60), c + Vector2(150, 60), c + Vector2(-90, -20)])
		elif big > 89.5:
			pts = PackedVector2Array([c + Vector2(-110, 70), c + Vector2(110, 70), c + Vector2(-110, -80)])
			draw_rect(Rect2(c + Vector2(-110, 46), Vector2(24, 24)), UIKit.C_BAD, false, 3)
		else:
			pts = PackedVector2Array([c + Vector2(-100, 70), c + Vector2(100, 70), c + Vector2(10, -90)])
		draw_colored_polygon(pts, Color("fff3bf"))
		for i in 3:
			draw_line(pts[i], pts[(i + 1) % 3], UIKit.C_TEXT, 4, true)
		return
	var sides: Array = spec.get("sides", [3, 4, 5])
	pts = PackedVector2Array([c + Vector2(-120, 70), c + Vector2(120, 70), c + Vector2(0, -85)])
	if sides[0] != sides[1] and sides[1] != sides[2] and sides[0] != sides[2]:
		pts[2] = c + Vector2(-50, -85)
	draw_colored_polygon(pts, Color("e7f5ff"))
	var labels = [sides[2], sides[0], sides[1]]
	for i in 3:
		var a = pts[i]
		var b = pts[(i + 1) % 3]
		draw_line(a, b, UIKit.C_PRIMARY, 4, true)
		var mid = (a + b) * 0.5
		_txt(mid + (mid - c).normalized() * 26, "%s см" % str(labels[i]), 19, UIKit.C_TEXT, true, true)


func _draw_letters(W: float, H: float) -> void:
	var labels: Array = spec.get("labels", ["A", "B", "C"])
	var c = Vector2(W * 0.5, H * 0.55)
	var pts = PackedVector2Array()
	if str(spec.get("shape", "tri")) == "tri":
		pts = PackedVector2Array([c + Vector2(-130, 70), c + Vector2(130, 70), c + Vector2(0, -85)])
	else:
		pts = PackedVector2Array([c + Vector2(-150, 60), c + Vector2(-150, -70), c + Vector2(150, -70), c + Vector2(150, 60)])
	draw_colored_polygon(pts, Color("f3f0ff"))
	for i in pts.size():
		draw_line(pts[i], pts[(i + 1) % pts.size()], Color("7048e8"), 4, true)
		draw_circle(pts[i], 6, UIKit.C_TEXT)
		_txt(pts[i] + (pts[i] - c).normalized() * 26, str(labels[i % labels.size()]), 26, UIKit.C_TEXT, true, true)


func _draw_motion(W: float, H: float) -> void:
	var ty = str(spec.get("type", "one"))
	var y = H * 0.55
	draw_line(Vector2(40, y), Vector2(W - 40, y), Color("adb5bd"), 4)
	var a = 0.5 + 0.5 * sin(_t * 1.5)
	var v1 = spec.get("v1")
	var v2 = spec.get("v2")
	match ty:
		"meet":
			_emo(Vector2(60 + a * (W * 0.35 - 60), y - 30), "🚗", 46)
			_emo(Vector2(W - 60 - a * (W * 0.35 - 60), y - 30), "🚙", 46)
			_txt(Vector2(W * 0.25, y + 30), "%s км/ч →" % str(v1), 20)
			_txt(Vector2(W * 0.75, y + 30), "← %s км/ч" % str(v2), 20)
		"opposite":
			_emo(Vector2(W * 0.5 - a * (W * 0.35), y - 30), "🚗", 46)
			_emo(Vector2(W * 0.5 + a * (W * 0.35), y - 30), "🚙", 46)
			_txt(Vector2(W * 0.25, y + 30), "← %s км/ч" % str(v1), 20)
			_txt(Vector2(W * 0.75, y + 30), "%s км/ч →" % str(v2), 20)
		"chase", "lag":
			_emo(Vector2(80 + a * W * 0.3, y - 30), "🐕" if ty == "chase" else "🚴", 46)
			_emo(Vector2(260 + a * W * 0.25, y - 30), "🐈" if ty == "chase" else "🚲", 46)
			_txt(Vector2(W * 0.5, y + 30), "%s и %s, одно направление →" % [str(v1), str(v2)], 20)
		_:
			_emo(Vector2(60 + a * (W - 120), y - 30), "🚌", 46)
			_txt(Vector2(W * 0.5, y + 30), "%s км/ч, %s ч" % [str(v1), str(spec.get("t", ""))], 20)
	draw_circle(Vector2(40, y), 8, UIKit.C_TEXT)
	draw_circle(Vector2(W - 40, y), 8, UIKit.C_TEXT)


func _draw_blocks(W: float, H: float) -> void:
	var h = int(spec.get("h", 1))
	var d = int(spec.get("d", 0))
	var u = int(spec.get("u", 0))
	var x = 20.0
	var s = 9.0
	for i in h:
		draw_rect(Rect2(x, 30, s * 10, s * 10), Color("ffc078"))
		for g in range(1, 10):
			draw_line(Vector2(x + g * s, 30), Vector2(x + g * s, 30 + s * 10), Color(1, 1, 1, 0.6), 1)
			draw_line(Vector2(x, 30 + g * s), Vector2(x + s * 10, 30 + g * s), Color(1, 1, 1, 0.6), 1)
		x += s * 10 + 10
		if x > W - 200:
			break
	x += 10
	for i in d:
		draw_rect(Rect2(x, 30, s, s * 10), Color("74c0fc"))
		x += s + 5
	x += 14
	for i in u:
		draw_rect(Rect2(x + (i % 3) * (s + 4), 30 + (i / 3) * (s + 4), s, s), Color("69db7c"))


func _draw_scale(c: Vector2, W: float, H: float) -> void:
	draw_line(c + Vector2(0, 80), c + Vector2(0, -40), Color("495057"), 8)
	draw_line(c + Vector2(-170, -40), c + Vector2(170, -40), Color("495057"), 6)
	draw_rect(Rect2(c + Vector2(-60, 80), Vector2(120, 14)), Color("495057"))
	for side in [-1, 1]:
		draw_line(c + Vector2(side * 160, -40), c + Vector2(side * 160, 10), Color("868e96"), 2)
		draw_arc(c + Vector2(side * 160, 10), 50, 0, PI, 16, Color("868e96"), 4)
	var ws: Array = spec.get("weights", [])
	var x = c.x - 190
	for w in ws:
		draw_rect(Rect2(Vector2(x, c.y - 30), Vector2(56, 40)), Color("343a40"))
		_txt(Vector2(x + 28, c.y - 10), "%s г" % str(w), 16, Color.WHITE, true, true)
		x += 62
	_txt(c + Vector2(160, -6), "?", 40, UIKit.C_BAD, true, true)


func _draw_compass(c: Vector2, R: float) -> void:
	draw_circle(c, R + 6, Color("495057"))
	draw_circle(c, R, Color("f8f9fa"))
	var names = ["С", "В", "Ю", "З"]
	for i in 4:
		var ang = -PI / 2 + i * PI / 2
		_txt(c + Vector2(cos(ang), sin(ang)) * R * 0.78, names[i], 26, UIKit.C_TEXT, true, true)
	var wob = sin(_t * 2.0) * 0.06
	var a = -PI / 2 + wob
	var tip = c + Vector2(cos(a), sin(a)) * R * 0.6
	var tail = c - Vector2(cos(a), sin(a)) * R * 0.6
	var side = Vector2(-sin(a), cos(a)) * 12
	draw_colored_polygon(PackedVector2Array([tip, c + side, c - side]), Color("fa5252"))
	draw_colored_polygon(PackedVector2Array([tail, c + side, c - side]), Color("4c6ef5"))
	draw_circle(c, 7, UIKit.C_TEXT)


func _draw_therm(c: Vector2, H: float, temp: int) -> void:
	var top = 20.0
	var bottom = H - 50
	draw_rect(Rect2(c.x - 14, top, 28, bottom - top), Color.WHITE)
	draw_rect(Rect2(c.x - 14, top, 28, bottom - top), Color("495057"), false, 2)
	var zero = top + (bottom - top) * 0.5
	var px_per = (bottom - top) / 80.0
	var y = zero - temp * px_per
	draw_rect(Rect2(c.x - 8, y, 16, bottom - y), Color("fa5252"))
	draw_circle(Vector2(c.x, bottom + 12), 22, Color("fa5252"))
	for t in range(-40, 41, 10):
		var yy = zero - t * px_per
		draw_line(Vector2(c.x + 16, yy), Vector2(c.x + 30, yy), Color("495057"), 2)
		_txt(Vector2(c.x + 56, yy), ("+" if t > 0 else "") + str(t), 16)
