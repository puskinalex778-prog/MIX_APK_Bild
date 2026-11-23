extends TaskView
## Сортировка по группам: нажми карточку, затем корзину. Нажатие на карточку в корзине
## возвращает её назад.

var _pool: HFlowContainer
var _bins = []         # [{box: HFlowContainer, panel}]
var _place = {}        # item -> cat index (-1 — не разложено)
var _cards = {}
var _sel = ""


func build() -> void:
	add_child(UIKit.label("Нажми карточку, а потом группу, куда её положить", 20, UIKit.C_MUTED, "body", HORIZONTAL_ALIGNMENT_CENTER))
	_pool = UIKit.flow(10)
	_pool.alignment = FlowContainer.ALIGNMENT_CENTER
	add_child(_pool)
	for it in TaskView.shuffled(task.get("items", [])):
		var txt = str(it[0])
		_place[txt] = -1
		var b = UIKit.chip_button(txt, Color.WHITE, UIKit.C_TEXT, 22)
		b.custom_minimum_size = Vector2(110, 64)
		b.pressed.connect(func(): _tap_card(txt))
		_cards[txt] = b
		_pool.add_child(b)
	var row = UIKit.hbox(14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cats: Array = task.get("cats", [])
	var palette = [Color("e7f5ff"), Color("fff4e6"), Color("ebfbee"), Color("f8f0fc")]
	for i in cats.size():
		var p = UIKit.panel(palette[i % palette.size()], 20, 14)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.custom_minimum_size = Vector2(0, 170)
		var v = UIKit.vbox(8)
		var hb = UIKit.button("⬇ " + str(cats[i]), Color("5c7cfa"), 22, Vector2(0, 58))
		var idx = i
		hb.pressed.connect(func(): _tap_bin(idx))
		v.add_child(hb)
		var f = UIKit.flow(8)
		v.add_child(f)
		p.add_child(v)
		row.add_child(p)
		_bins.append({"box": f, "panel": p})
	add_child(row)
	add_child(make_check_button())


func _tap_card(txt: String) -> void:
	if locked:
		return
	if _place[txt] >= 0:
		_place[txt] = -1
		_cards[txt].reparent(_pool)
		_sel = ""
	else:
		_sel = txt
	_restyle()


func _tap_bin(i: int) -> void:
	if locked or _sel == "":
		return
	_place[_sel] = i
	_cards[_sel].reparent(_bins[i]["box"])
	_sel = ""
	Audio.sfx("pop")
	_restyle()


func _restyle() -> void:
	var all = true
	for t in _cards:
		if t == _sel:
			UIKit.set_chip_style(_cards[t], Color("dbe4ff"), UIKit.C_TEXT, UIKit.C_PRIMARY)
		else:
			UIKit.set_chip_style(_cards[t], Color.WHITE)
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
			_place[t] = -1
			_cards[t].reparent(_pool)
	_restyle()


func reveal_answer() -> void:
	super.reveal_answer()
	for it in task["items"]:
		var t = str(it[0])
		_place[t] = int(it[1])
		_cards[t].reparent(_bins[int(it[1])]["box"])
		UIKit.set_chip_style(_cards[t], UIKit.C_OK_L, UIKit.C_TEXT, UIKit.C_OK)
