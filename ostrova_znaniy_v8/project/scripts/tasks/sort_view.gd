extends TaskView
## Сортировка по группам с перетаскиванием пальцем (как в ostrova-znaniy)
## и запасным режимом «нажми карточку, потом группу».

const ZONE_BG := [Color("e6efff"), Color("fff2e4"), Color("e5fbef"), Color("f6e9ff")]
const ZONE_HDR := [Color("5b6cff"), Color("ff7a3d"), Color("25b061"), Color("a24df0")]

var _pool_panel: PanelContainer
var _pool: HFlowContainer
var _bins: Array = []        # [{box: HFlowContainer, panel: PanelContainer, bg: Color, hdr: Color}]
var _place := {}             # item_txt -> cat index (-1 — в пуле)
var _cards := {}             # item_txt -> Button
var _sel := ""
var _drag: DragHelper


func build() -> void:
	_drag = DragHelper.new()
	_drag.is_locked = func() -> bool: return locked
	_drag.on_drop = _on_drop
	_drag.on_tap = _tap_card
	add_child(_drag)

	add_child(UIKit.label("Перетащи пальцем карточку в нужную группу (или нажми карточку, потом группу)", 20, UIKit.C_MUTED, "body", HORIZONTAL_ALIGNMENT_CENTER))

	_pool_panel = PanelContainer.new()
	_pool_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pool_panel.custom_minimum_size = Vector2(0, 86)
	_set_pool_style(false)
	_pool = UIKit.flow(10)
	_pool.alignment = FlowContainer.ALIGNMENT_CENTER
	_pool.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pool_panel.add_child(_pool)
	_pool_panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and _sel != "":
			_move_card(_sel, -1)
			_sel = ""
			_restyle())
	add_child(_pool_panel)
	_drag.register_zone(_pool_panel, -1, _set_pool_style)

	for it in TaskView.shuffled(task.get("items", [])):
		var txt = str(it[0])
		_place[txt] = -1
		var b = UIKit.chip_button(txt, Color("ffffff"), UIKit.C_TEXT, 22)
		b.custom_minimum_size = Vector2(104, 64)
		_cards[txt] = b
		_pool.add_child(b)
		_drag.register_card(b, txt)

	var cats: Array = task.get("cats", [])
	var row = UIKit.hbox(14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in cats.size():
		var bg = ZONE_BG[i % ZONE_BG.size()]
		var hdr = ZONE_HDR[i % ZONE_HDR.size()]
		var p = PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.custom_minimum_size = Vector2(0, 178)
		var idx = i
		var set_hover = func(over: bool): _set_zone_style(p, bg, hdr, over)
		set_hover.call(false)
		p.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_tap_bin(idx))
		var v = UIKit.vbox(10)
		var hb = UIKit.button("⬇ " + str(cats[i]), hdr, 22, Vector2(0, 56))
		hb.pressed.connect(func(): _tap_bin(idx))
		v.add_child(hb)
		var f = UIKit.flow(8)
		f.alignment = FlowContainer.ALIGNMENT_CENTER
		f.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(f)
		p.add_child(v)
		row.add_child(p)
		_bins.append({"box": f, "panel": p, "bg": bg, "hdr": hdr})
		_drag.register_zone(p, idx, set_hover)
	add_child(row)
	add_child(make_check_button())


func _set_pool_style(over: bool) -> void:
	var bg = Color(0.36, 0.42, 1.0, 0.16 if over else 0.08)
	var bd = UIKit.C_PRIMARY if over else Color(0.36, 0.42, 1.0, 0.30)
	_pool_panel.add_theme_stylebox_override("panel", UIKit.sb(bg, 22, 3 if over else 2, bd, 0, 12))


func _set_zone_style(p: PanelContainer, bg: Color, hdr: Color, over: bool) -> void:
	var border = hdr if over else bg.darkened(0.08)
	p.add_theme_stylebox_override("panel", UIKit.sb(bg.lightened(0.03) if over else bg, 24, 4 if over else 2, border, 12 if over else 4, 12))


func _on_drop(card_id: Variant, zone_id: Variant) -> bool:
	var txt = str(card_id)
	var target = int(zone_id)
	if not _cards.has(txt) or _place[txt] == target:
		return false
	_sel = ""
	_move_card(txt, target)
	_restyle()
	return true


func _move_card(txt: String, target: int) -> void:
	_place[txt] = target
	var card: Button = _cards[txt]
	if target < 0:
		card.reparent(_pool)
	else:
		card.reparent(_bins[target]["box"])


func _tap_card(card_id: Variant) -> void:
	if locked:
		return
	var txt = str(card_id)
	if _place[txt] >= 0:
		_move_card(txt, -1)
		_sel = ""
		Audio.sfx("tap")
	elif _sel == txt:
		_sel = ""
		Audio.sfx("tap")
	else:
		_sel = txt
		Audio.sfx("tap")
	_restyle()


func _tap_bin(i: int) -> void:
	if locked or _sel == "":
		return
	_move_card(_sel, i)
	DragHelper._bounce(_cards[_sel])
	_sel = ""
	Audio.sfx("drop")
	_restyle()


func _restyle() -> void:
	var all = true
	for t in _cards:
		if t == _sel:
			UIKit.set_chip_style(_cards[t], Color("eef0ff"), UIKit.C_TEXT, UIKit.C_PRIMARY)
		else:
			UIKit.set_chip_style(_cards[t], Color("ffffff"), UIKit.C_TEXT, Color("c9cff0"))
		if _place[t] < 0:
			all = false
	check_btn.disabled = not all


func _on_check() -> void:
	if locked:
		return
	locked = true
	var ok = AnswerChecker.check_sort(task, _place)
	var want = {}
	for it in task["items"]:
		want[str(it[0])] = int(it[1])
	var parts = PackedStringArray()
	for t in _cards:
		var right: bool = want[t] == _place[t]
		UIKit.set_chip_style(_cards[t], UIKit.C_OK_L if right else UIKit.C_BAD_L, UIKit.C_TEXT, UIKit.C_OK if right else UIKit.C_BAD)
		if not right:
			UIKit.shake(_cards[t])
		if _place[t] >= 0:
			parts.append("%s→%s" % [t, task["cats"][_place[t]]])
	submitted.emit(ok, ", ".join(parts))


func retry() -> void:
	locked = false
	var want = {}
	for it in task["items"]:
		want[str(it[0])] = int(it[1])
	for t in _cards:
		if want[t] != _place[t]:
			_move_card(t, -1)
	_restyle()


func reveal_answer() -> void:
	super.reveal_answer()
	for it in task["items"]:
		var t = str(it[0])
		_move_card(t, int(it[1]))
		UIKit.set_chip_style(_cards[t], UIKit.C_OK_L, UIKit.C_TEXT, UIKit.C_OK)
