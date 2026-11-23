class_name DragHelper
extends Node
## Перетаскивание карточек пальцем (и мышью) с плавающей тенью-призраком,
## наклоном при движении, подсветкой целевой зоны и сохранением режима
## «нажми карточку, потом место» как запасного варианта.

const DRAG_THRESHOLD := 9.0

var on_drop: Callable        # func(card_id: Variant, zone_id: Variant) -> bool
var on_tap: Callable         # func(card_id: Variant)
var is_locked: Callable      # func() -> bool

var _zones: Array = []       # [{node: Control, id: Variant, hover: Callable}]
var _cards: Array = []       # [{node: Control, id: Variant}]
var _drag_card: Control = null
var _drag_id: Variant = null
var _start_pos := Vector2.ZERO
var _grab_offset := Vector2.ZERO
var _moved := false
var _ghost_layer: CanvasLayer = null
var _ghost: PanelContainer = null
var _hovered_zone: Dictionary = {}


func _exit_tree() -> void:
	_clear_ghost()


func register_card(card: Control, card_id: Variant) -> void:
	card.add_to_group("drag_card")
	_cards.append({"node": card, "id": card_id})
	card.gui_input.connect(func(ev: InputEvent): _on_card_gui_input(ev, card, card_id))


func register_zone(zone: Control, zone_id: Variant, hover_cb: Callable = Callable()) -> void:
	_zones.append({"node": zone, "id": zone_id, "hover": hover_cb})


func _locked() -> bool:
	return is_locked.is_valid() and bool(is_locked.call())


func _on_card_gui_input(ev: InputEvent, card: Control, card_id: Variant) -> void:
	if _locked():
		return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		if _drag_card != null:
			return
		var gpos = card.get_global_mouse_position()
		_drag_card = card
		_drag_id = card_id
		_start_pos = gpos
		_grab_offset = gpos - card.get_global_rect().position
		_moved = false
		_hovered_zone = {}
		get_viewport().set_input_as_handled()


func _input(ev: InputEvent) -> void:
	if _drag_card == null:
		return
	if not is_instance_valid(_drag_card) or _locked():
		_cancel_drag()
		return
	if ev is InputEventScreenDrag:
		get_viewport().set_input_as_handled()
		return
	if ev is InputEventMouseMotion:
		var gpos = _drag_card.get_global_mouse_position()
		var delta = gpos - _start_pos
		if not _moved:
			if delta.length() < DRAG_THRESHOLD:
				return
			_begin_ghost(gpos)
		_update_ghost(gpos, delta)
		get_viewport().set_input_as_handled()
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
		var gpos = _drag_card.get_global_mouse_position()
		_finish_drag(gpos)
		get_viewport().set_input_as_handled()


func _begin_ghost(gpos: Vector2) -> void:
	_moved = true
	Audio.sfx("pick")
	if _drag_card is BaseButton:
		(_drag_card as BaseButton).button_pressed = false
	var rect = _drag_card.get_global_rect()
	_drag_card.modulate.a = 0.25
	_ghost_layer = CanvasLayer.new()
	_ghost_layer.layer = 100
	get_tree().root.add_child(_ghost_layer)
	_ghost = PanelContainer.new()
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st = UIKit.sb_3d(Color("ffffff"), 18, 5, 16, 12, Color("5b6cff"), 3)
	_ghost.add_theme_stylebox_override("panel", st)
	_ghost.size = rect.size
	_ghost.custom_minimum_size = rect.size
	_ghost.pivot_offset = rect.size * 0.5
	var txt = ""
	if _drag_card is Button:
		txt = (_drag_card as Button).text
	elif _drag_card.has_meta("drag_text"):
		txt = str(_drag_card.get_meta("drag_text"))
	var lbl = UIKit.label(txt, 24, UIKit.C_TEXT, "bold", HORIZONTAL_ALIGNMENT_CENTER)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.add_child(lbl)
	_ghost.position = gpos - _grab_offset
	_ghost.scale = Vector2(1.08, 1.08)
	_ghost_layer.add_child(_ghost)


func _update_ghost(gpos: Vector2, delta: Vector2) -> void:
	if _ghost == null:
		return
	_ghost.position = gpos - _grab_offset
	if not Settings.reduce_motion:
		_ghost.rotation = deg_to_rad(clampf(delta.x / 22.0, -8.0, 8.0))
	var hit = _find_zone(gpos)
	if hit.get("node") != _hovered_zone.get("node"):
		_set_zone_hover(_hovered_zone, false)
		_hovered_zone = hit
		_set_zone_hover(_hovered_zone, true)


func _finish_drag(gpos: Vector2) -> void:
	var card = _drag_card
	var cid = _drag_id
	var was_moved = _moved
	var zone = _find_zone(gpos) if was_moved else {}
	_set_zone_hover(_hovered_zone, false)
	_hovered_zone = {}
	_drag_card = null
	_drag_id = null
	_moved = false
	_clear_ghost()
	if is_instance_valid(card):
		card.modulate.a = 1.0
	if not was_moved:
		if on_tap.is_valid():
			on_tap.call(cid)
		return
	var placed = false
	if not zone.is_empty() and on_drop.is_valid():
		placed = bool(on_drop.call(cid, zone["id"]))
	if placed:
		Audio.sfx("drop")
		if is_instance_valid(card):
			_bounce(card)
	elif is_instance_valid(card):
		_bounce(card, 0.94)


func _cancel_drag() -> void:
	_set_zone_hover(_hovered_zone, false)
	_hovered_zone = {}
	if is_instance_valid(_drag_card):
		_drag_card.modulate.a = 1.0
	_drag_card = null
	_drag_id = null
	_moved = false
	_clear_ghost()


func _clear_ghost() -> void:
	if is_instance_valid(_ghost_layer):
		_ghost_layer.queue_free()
	_ghost_layer = null
	_ghost = null


func _find_zone(gpos: Vector2) -> Dictionary:
	# Ищем самую специфичную (последнюю/глубокую) зону под пальцем
	var best: Dictionary = {}
	var best_area := INF
	for z in _zones:
		var node: Control = z["node"]
		if not is_instance_valid(node) or not node.is_visible_in_tree():
			continue
		var r = node.get_global_rect().grow(6.0)
		if r.has_point(gpos):
			var area = r.size.x * r.size.y
			if area <= best_area:
				best_area = area
				best = z
	return best


func _set_zone_hover(z: Dictionary, on: bool) -> void:
	if z.is_empty():
		return
	var cb: Callable = z.get("hover", Callable())
	if cb.is_valid():
		cb.call(on)


static func _bounce(c: Control, from_scale: float = 1.12) -> void:
	if Settings.reduce_motion or not is_instance_valid(c) or not c.is_inside_tree():
		return
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2(from_scale, from_scale)
	var tw = c.create_tween()
	tw.tween_property(c, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
