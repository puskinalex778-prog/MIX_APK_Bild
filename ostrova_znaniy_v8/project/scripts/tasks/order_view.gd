extends TaskView
## Восстановление порядка и составление ответа из карточек с перетаскиванием пальцем
## в пронумерованные окошки (и запасным режимом нажатия по очереди).

var _pool_panel: PanelContainer
var _pool: HFlowContainer
var _slots: Array = []       # [{panel: PanelContainer, holder: CenterContainer, card: Button}]
var _all: Array = []         # все кнопки карточек
var _card_slot := {}         # Button -> int (-1 = в пуле)
var _sel: Button = null
var _drag: DragHelper


func build() -> void:
	_drag = DragHelper.new()
	_drag.is_locked = func() -> bool: return locked
	_drag.on_drop = _on_drop
	_drag.on_tap = _tap_card
	add_child(_drag)

	var is_build = str(task.get("type")) == "build"
	add_child(UIKit.label(
		"Перетащи карточки в окошки по порядку (или нажимай по очереди)" if not is_build else "Перетащи нужные карточки в окошки (лишние не нужны)",
		20, UIKit.C_MUTED, "body", HORIZONTAL_ALIGNMENT_CENTER))

	var ans: Array = task.get("answer", [])
	var slot_flow = UIKit.flow(8)
	slot_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	slot_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in ans.size():
		if i > 0 and not is_build:
			var arr = UIKit.nowrap(UIKit.label("›", 28, Color("9aa3e0"), "bold", HORIZONTAL_ALIGNMENT_CENTER))
			arr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot_flow.add_child(arr)
		var slot_p = PanelContainer.new()
		slot_p.custom_minimum_size = Vector2(96, 78)
		var idx = i
		var set_hover = func(over: bool): _set_slot_style(idx, over)
		slot_p.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_tap_slot(idx))
		var v = UIKit.vbox(2)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		var num_lbl = UIKit.nowrap(UIKit.label(str(i + 1), 14, UIKit.C_PRIMARY, "bold", HORIZONTAL_ALIGNMENT_CENTER))
		var holder = CenterContainer.new()
		holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(num_lbl)
		v.add_child(holder)
		slot_p.add_child(v)
		slot_flow.add_child(slot_p)
		_slots.append({"panel": slot_p, "holder": holder, "card": null, "num": num_lbl})
		_set_slot_style(idx, false)
		_drag.register_zone(slot_p, idx, set_hover)
	add_child(slot_flow)

	_pool_panel = PanelContainer.new()
	_pool_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pool_panel.custom_minimum_size = Vector2(0, 86)
	_set_pool_style(false)
	_pool = UIKit.flow(10)
	_pool.alignment = FlowContainer.ALIGNMENT_CENTER
	_pool.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pool_panel.add_child(_pool)
	_pool_panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and _sel != null:
			_place_card(_sel, -1)
			_sel = null
			_restyle())
	add_child(_pool_panel)
	_drag.register_zone(_pool_panel, -1, _set_pool_style)

	var items: Array = ans.duplicate()
	items.append_array(task.get("extra", []))
	for txt in TaskView.shuffled_not_same(items):
		var b = UIKit.chip_button(str(txt), Color("ffffff"), UIKit.C_TEXT, 24)
		b.custom_minimum_size = Vector2(78, 64)
		b.set_meta("txt", str(txt))
		_pool.add_child(b)
		_all.append(b)
		_card_slot[b] = -1
		_drag.register_card(b, b)
	add_child(make_check_button())


func _set_pool_style(over: bool) -> void:
	var bg = Color(0.36, 0.42, 1.0, 0.16 if over else 0.08)
	var bd = UIKit.C_PRIMARY if over else Color(0.36, 0.42, 1.0, 0.30)
	_pool_panel.add_theme_stylebox_override("panel", UIKit.sb(bg, 22, 3 if over else 2, bd, 0, 12))


func _set_slot_style(idx: int, over: bool) -> void:
	var s = _slots[idx]
	var filled = s["card"] != null
	if over:
		s["panel"].add_theme_stylebox_override("panel", UIKit.sb(Color("eef0ff"), 20, 3, UIKit.C_PRIMARY, 6, 6))
	elif filled:
		s["panel"].add_theme_stylebox_override("panel", UIKit.sb(Color(0.36, 0.42, 1.0, 0.06), 20, 2, Color(0.36, 0.42, 1.0, 0.18), 0, 4))
	else:
		s["panel"].add_theme_stylebox_override("panel", UIKit.sb(Color(1, 1, 1, 0.72), 20, 3, Color("b8c0f5"), 0, 6))


func _on_drop(card_id: Variant, zone_id: Variant) -> bool:
	var b = card_id as Button
	if b == null:
		return false
	var target = int(zone_id)
	var cur = int(_card_slot.get(b, -1))
	if cur == target:
		return false
	_sel = null
	_place_card(b, target)
	_restyle()
	return true


func _place_card(b: Button, target: int) -> void:
	var src = int(_card_slot.get(b, -1))
	if src >= 0:
		_slots[src]["card"] = null
	if target < 0:
		_card_slot[b] = -1
		b.reparent(_pool)
	else:
		var old: Button = _slots[target]["card"]
		if old != null and old != b:
			if src >= 0:
				_slots[src]["card"] = old
				_card_slot[old] = src
				old.reparent(_slots[src]["holder"])
			else:
				_card_slot[old] = -1
				old.reparent(_pool)
		_slots[target]["card"] = b
		_card_slot[b] = target
		b.reparent(_slots[target]["holder"])


func _tap_card(card_id: Variant) -> void:
	if locked:
		return
	var b = card_id as Button
	if b == null:
		return
	var cur = int(_card_slot.get(b, -1))
	if cur >= 0:
		_place_card(b, -1)
		_sel = null
		Audio.sfx("tap")
	else:
		var empty_idx = _first_empty_slot()
		if empty_idx >= 0:
			_place_card(b, empty_idx)
			DragHelper._bounce(b)
			_sel = null
			Audio.sfx("drop")
		else:
			_sel = b if _sel != b else null
			Audio.sfx("tap")
	_restyle()


func _tap_slot(idx: int) -> void:
	if locked or _sel == null:
		return
	_place_card(_sel, idx)
	DragHelper._bounce(_sel)
	_sel = null
	Audio.sfx("drop")
	_restyle()


func _first_empty_slot() -> int:
	for i in _slots.size():
		if _slots[i]["card"] == null:
			return i
	return -1


func _restyle() -> void:
	var filled = 0
	for i in _slots.size():
		_set_slot_style(i, false)
		if _slots[i]["card"] != null:
			filled += 1
	for b in _all:
		if b == _sel:
			UIKit.set_chip_style(b, Color("eef0ff"), UIKit.C_TEXT, UIKit.C_PRIMARY)
		else:
			UIKit.set_chip_style(b, Color("ffffff"), UIKit.C_TEXT, Color("c9cff0"))
	check_btn.disabled = filled != _slots.size()


func _given() -> Array:
	var g = []
	for s in _slots:
		if s["card"] != null:
			g.append(s["card"].get_meta("txt"))
	return g


func _on_check() -> void:
	if locked:
		return
	locked = true
	var g = _given()
	var ok = AnswerChecker.check_order(task, g)
	var ans: Array = task["answer"]
	for i in _slots.size():
		var b: Button = _slots[i]["card"]
		if b == null:
			continue
		var right = i < ans.size() and AnswerChecker.norm(str(b.get_meta("txt"))) == AnswerChecker.norm(str(ans[i]))
		UIKit.set_chip_style(b, UIKit.C_OK_L if right else UIKit.C_BAD_L, UIKit.C_TEXT, UIKit.C_OK if right else UIKit.C_BAD)
		if not right:
			UIKit.shake(b)
	submitted.emit(ok, str(task.get("joiner", " ")).join(PackedStringArray(g)) if str(task.get("type")) == "build" else " → ".join(PackedStringArray(g)))


func retry() -> void:
	locked = false
	var ans: Array = task["answer"]
	for i in _slots.size():
		var b: Button = _slots[i]["card"]
		if b != null:
			var right = i < ans.size() and AnswerChecker.norm(str(b.get_meta("txt"))) == AnswerChecker.norm(str(ans[i]))
			if not right:
				_place_card(b, -1)
	_restyle()


func reveal_answer() -> void:
	super.reveal_answer()
	for b in _all:
		_place_card(b, -1)
	var used = {}
	var ans: Array = task["answer"]
	for i in ans.size():
		var txt = str(ans[i])
		for b in _all:
			if not used.has(b) and AnswerChecker.norm(str(b.get_meta("txt"))) == AnswerChecker.norm(txt):
				used[b] = true
				_place_card(b, i)
				UIKit.set_chip_style(b, UIKit.C_OK_L, UIKit.C_TEXT, UIKit.C_OK)
				break
	for i in _slots.size():
		_set_slot_style(i, false)
