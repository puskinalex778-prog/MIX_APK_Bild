extends TaskView
## Сопоставление пар с перетаскиванием пальцем (как .pairs в ostrova-znaniy):
## перетащи карточку из нижнего пула в окошко напротив её пары
## (или нажми карточку, а потом окошко).

var _pool_panel: PanelContainer
var _pool: HFlowContainer
var _slots := {}             # left_txt -> {panel: PanelContainer, holder: CenterContainer, card: Button}
var _card_slot := {}         # Button -> left_txt ("" = в пуле)
var _all_cards: Array = []   # правые карточки
var _left_order: Array = []
var _sel: Button = null
var _drag: DragHelper


func build() -> void:
	_drag = DragHelper.new()
	_drag.is_locked = func() -> bool: return locked
	_drag.on_drop = _on_drop
	_drag.on_tap = _tap_card
	add_child(_drag)

	add_child(UIKit.label("Перетащи каждую карточку к её паре (или нажми карточку, потом окошко)", 20, UIKit.C_MUTED, "body", HORIZONTAL_ALIGNMENT_CENTER))

	var lefts = []
	var rights = []
	var max_len = 0
	for p in task.get("pairs", []):
		var lt = str(p[0])
		var rt = str(p[1])
		lefts.append(lt)
		rights.append(rt)
		max_len = maxi(max_len, maxi(lt.length(), rt.length()))
	lefts = TaskView.shuffled(lefts)
	rights = TaskView.shuffled_not_same(rights)
	_left_order = lefts

	var grid = GridContainer.new()
	grid.columns = 2 if (lefts.size() >= 4 and max_len <= 16) else 1
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for l in lefts:
		var row_p = PanelContainer.new()
		row_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_p.add_theme_stylebox_override("panel", UIKit.sb(Color(1, 1, 1, 0.78), 22, 2, Color("dfe3ff"), 4, 10))
		var h = UIKit.hbox(10)
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		var left_box = PanelContainer.new()
		left_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left_box.custom_minimum_size = Vector2(120, 66)
		left_box.add_theme_stylebox_override("panel", UIKit.sb(Color("eef0ff"), 16, 0, Color.TRANSPARENT, 0, 10))
		var ll = UIKit.label(l, 22, UIKit.C_TEXT, "bold", HORIZONTAL_ALIGNMENT_CENTER)
		ll.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		left_box.add_child(ll)
		h.add_child(left_box)
		var arr = UIKit.nowrap(UIKit.label("→", 24, Color("9aa3e0"), "bold", HORIZONTAL_ALIGNMENT_CENTER))
		arr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(arr)
		var slot_p = PanelContainer.new()
		slot_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_p.custom_minimum_size = Vector2(140, 68)
		var l_key: String = l
		var set_hover = func(over: bool): _set_slot_style(l_key, over)
		slot_p.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_tap_slot(l_key))
		var holder = CenterContainer.new()
		holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		slot_p.add_child(holder)
		h.add_child(slot_p)
		row_p.add_child(h)
		grid.add_child(row_p)
		_slots[l_key] = {"panel": slot_p, "holder": holder, "card": null}
		_set_slot_style(l_key, false)
		_drag.register_zone(slot_p, l_key, set_hover)
	add_child(grid)

	_pool_panel = PanelContainer.new()
	_pool_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pool_panel.custom_minimum_size = Vector2(0, 84)
	_set_pool_style(false)
	_pool = UIKit.flow(10)
	_pool.alignment = FlowContainer.ALIGNMENT_CENTER
	_pool.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pool_panel.add_child(_pool)
	_pool_panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and _sel != null:
			_place_card(_sel, "")
			_sel = null
			_restyle())
	add_child(_pool_panel)
	_drag.register_zone(_pool_panel, "", _set_pool_style)

	for r in rights:
		var b = UIKit.chip_button(r, Color("ffffff"), UIKit.C_TEXT, 22)
		b.custom_minimum_size = Vector2(110, 62)
		b.set_meta("txt", r)
		_pool.add_child(b)
		_all_cards.append(b)
		_card_slot[b] = ""
		_drag.register_card(b, b)
	add_child(make_check_button())


func _set_pool_style(over: bool) -> void:
	var bg = Color(0.36, 0.42, 1.0, 0.16 if over else 0.08)
	var bd = UIKit.C_PRIMARY if over else Color(0.36, 0.42, 1.0, 0.30)
	_pool_panel.add_theme_stylebox_override("panel", UIKit.sb(bg, 22, 3 if over else 2, bd, 0, 12))


func _set_slot_style(l_key: String, over: bool) -> void:
	var s = _slots[l_key]
	var filled = s["card"] != null
	if over:
		s["panel"].add_theme_stylebox_override("panel", UIKit.sb(Color("eef0ff"), 18, 3, UIKit.C_PRIMARY, 6, 4))
	elif filled:
		s["panel"].add_theme_stylebox_override("panel", UIKit.sb(Color(0.36, 0.42, 1.0, 0.05), 18, 2, Color(0.36, 0.42, 1.0, 0.16), 0, 4))
	else:
		s["panel"].add_theme_stylebox_override("panel", UIKit.sb(Color(1, 1, 1, 0.72), 18, 3, Color("b8c0f5"), 0, 6))


func _on_drop(card_id: Variant, zone_id: Variant) -> bool:
	var b = card_id as Button
	if b == null:
		return false
	var target = str(zone_id)
	var cur = str(_card_slot.get(b, ""))
	if cur == target:
		return false
	_sel = null
	_place_card(b, target)
	_restyle()
	return true


func _place_card(b: Button, target: String) -> void:
	var src = str(_card_slot.get(b, ""))
	if src != "" and _slots.has(src):
		_slots[src]["card"] = null
	if target == "":
		_card_slot[b] = ""
		b.reparent(_pool)
	else:
		var old: Button = _slots[target]["card"]
		if old != null and old != b:
			if src != "" and _slots.has(src):
				_slots[src]["card"] = old
				_card_slot[old] = src
				old.reparent(_slots[src]["holder"])
			else:
				_card_slot[old] = ""
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
	var cur = str(_card_slot.get(b, ""))
	if cur != "":
		_place_card(b, "")
		_sel = null
		Audio.sfx("tap")
	elif _sel == b:
		_sel = null
		Audio.sfx("tap")
	else:
		_sel = b
		Audio.sfx("tap")
	_restyle()


func _tap_slot(l_key: String) -> void:
	if locked or _sel == null:
		return
	_place_card(_sel, l_key)
	DragHelper._bounce(_sel)
	_sel = null
	Audio.sfx("drop")
	_restyle()


func _restyle() -> void:
	var filled = 0
	for l_key in _slots:
		_set_slot_style(l_key, false)
		if _slots[l_key]["card"] != null:
			filled += 1
	for b in _all_cards:
		if b == _sel:
			UIKit.set_chip_style(b, Color("eef0ff"), UIKit.C_TEXT, UIKit.C_PRIMARY)
		else:
			UIKit.set_chip_style(b, Color("ffffff"), UIKit.C_TEXT, Color("c9cff0"))
	check_btn.disabled = filled != _slots.size()


func _on_check() -> void:
	if locked:
		return
	locked = true
	var given = []
	var parts = PackedStringArray()
	var want = {}
	for p in task["pairs"]:
		want[str(p[0])] = str(p[1])
	for l_key in _left_order:
		var b: Button = _slots[l_key]["card"]
		if b == null:
			continue
		var r_txt = str(b.get_meta("txt"))
		given.append([l_key, r_txt])
		parts.append("%s — %s" % [l_key, r_txt])
		var right = want.get(l_key, "") == r_txt
		UIKit.set_chip_style(b, UIKit.C_OK_L if right else UIKit.C_BAD_L, UIKit.C_TEXT, UIKit.C_OK if right else UIKit.C_BAD)
		if not right:
			UIKit.shake(b)
	var ok = AnswerChecker.check_match(task, given)
	submitted.emit(ok, "; ".join(parts))


func retry() -> void:
	locked = false
	var want = {}
	for p in task["pairs"]:
		want[str(p[0])] = str(p[1])
	for l_key in _left_order:
		var b: Button = _slots[l_key]["card"]
		if b != null and want.get(l_key, "") != str(b.get_meta("txt")):
			_place_card(b, "")
	_restyle()


func reveal_answer() -> void:
	super.reveal_answer()
	for b in _all_cards:
		_place_card(b, "")
	var used = {}
	for p in task["pairs"]:
		var l_key = str(p[0])
		var r_txt = str(p[1])
		for b in _all_cards:
			if not used.has(b) and str(b.get_meta("txt")) == r_txt:
				used[b] = true
				_place_card(b, l_key)
				UIKit.set_chip_style(b, UIKit.C_OK_L, UIKit.C_TEXT, UIKit.C_OK)
				break
	for l_key in _slots:
		_set_slot_style(l_key, false)
	check_btn.disabled = true
