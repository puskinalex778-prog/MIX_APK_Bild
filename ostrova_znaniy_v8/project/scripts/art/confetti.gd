class_name ConfettiBurst
extends Control
## Лёгкий оверлей конфетти (разноцветные прямоугольники и звёздочки с физикой),
## перенесённый из прототипа ostrova-znaniy.

const COLORS := [
	Color("ff5a6e"), Color("ffc83d"), Color("2fc26b"),
	Color("5b6cff"), Color("a24df0"), Color("3fd6c8"), Color("ff7a3d"),
]

var _parts: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process(false)


func burst(origin: Vector2, count: int = 55, spread: float = 1.0) -> void:
	if Settings.reduce_motion:
		return
	for k in count:
		var ang = randf() * TAU
		var spd = randf_range(240.0, 560.0) * spread
		_parts.append({
			"pos": origin,
			"vel": Vector2(cos(ang) * spd, sin(ang) * spd - 360.0 * spread),
			"rot": randf() * TAU,
			"vrot": randf_range(-9.0, 9.0),
			"w": randf_range(8.0, 15.0),
			"h": randf_range(5.0, 10.0),
			"col": COLORS[k % COLORS.size()],
			"star": randf() < 0.32,
			"life": randf_range(1.3, 2.2),
			"max_life": 2.2,
		})
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var dt = minf(delta, 0.05)
	var alive: Array = []
	for p in _parts:
		p["life"] -= dt
		if p["life"] <= 0.0:
			continue
		p["vel"].y += 980.0 * dt
		p["vel"].x *= pow(0.45, dt)
		p["pos"] += p["vel"] * dt
		p["rot"] += p["vrot"] * dt
		alive.append(p)
	_parts = alive
	if _parts.is_empty():
		set_process(false)
	queue_redraw()


func _draw() -> void:
	for p in _parts:
		var alpha = clampf(p["life"] / 0.45, 0.0, 1.0)
		var col: Color = p["col"]
		col.a = alpha
		draw_set_transform(p["pos"], p["rot"], Vector2.ONE)
		if p["star"]:
			var pts = PackedVector2Array()
			for i in 10:
				var r = 9.0 if i % 2 == 0 else 4.2
				var a = -PI * 0.5 + i * PI / 5.0
				pts.append(Vector2(cos(a) * r, sin(a) * r))
			draw_colored_polygon(pts, col)
		else:
			var w: float = p["w"]
			var h: float = p["h"]
			draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func burst_on(host: Node, origin: Vector2, count: int = 55, spread: float = 1.0) -> void:
	if Settings.reduce_motion or not is_instance_valid(host) or not host.is_inside_tree():
		return
	var root = host.get_tree().root
	var layer = root.get_node_or_null("ConfettiLayer") as CanvasLayer
	var ctrl: ConfettiBurst
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "ConfettiLayer"
		layer.layer = 95
		ctrl = ConfettiBurst.new()
		ctrl.name = "Burst"
		layer.add_child(ctrl)
		root.add_child(layer)
	else:
		ctrl = layer.get_node_or_null("Burst") as ConfettiBurst
		if ctrl == null:
			ctrl = ConfettiBurst.new()
			ctrl.name = "Burst"
			layer.add_child(ctrl)
	ctrl.burst(origin, count, spread)
