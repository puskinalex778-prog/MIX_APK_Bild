extends TaskView
## Сопоставление: нажми элемент слева, затем пару справа. Повторное нажатие снимает пару.

const PAIR_COLORS := ["ffd8a8", "b2f2bb", "a5d8ff", "eebefa", "ffec99", "fcc2d7", "c5f6fa"]

var _left = {}    # text -> Button
var _right = {}
var _pairs = {}   # left -> right
var _sel_left = ""


func build() -> void:
	add_child(UIKit.label("Нажми слово слева, а потом его пару справа", 20, UIKit.C_MUTED, "body", HORIZONTAL_ALIGNMENT_CENTER))
	var cols = UIKit.hbox(40)
	cols.alignment = BoxContainer.ALIGNMENT_CENTER
	var lv = UIKit.vbox(10)
	var rv = UIKit.vbox(10)
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lefts = []
	var rights = []
	for p in task.get("pairs", []):
		lefts.append(str(p[0]))
		rights.append(str(p[1]))
	lefts = TaskView.shuffled(lefts)
	rights = TaskView.shuffled_not_same(rights)
	for l in lefts:
		var b = UIKit.chip_button(l, Color.WHITE, UIKit.C_TEXT, 22)
		b.custom_minimum_size = Vector2(0, 70)
		b.pressed.connect(func(): _tap_left(l))
		lv.add_child(b)
		_left[l] = b
	for r in rights:
		var b2 = UIKit.chip_button(r, Color.WHITE, UIKit.C_TEXT, 22)
		b2.custom_minimum_size = Vector2(0, 70)
		b2.pressed.connect(func(): _tap_right(r))
		rv.add_child(b2)
		_right[r] = b2
	cols.add_child(lv)
	cols.add_child(rv)
	add_child(cols)
	add_child(make_check_button())


func _tap_left(l: String) -> void:
	if locked:
		return
	if _pairs.has(l):
		_pairs.erase(l)
		_restyle()
		return
	_sel_left = l
	_restyle()


func _tap_right(r: String) -> void:
	if locked or _sel_left == "":
		return
	for k in _pairs.keys():
		if _pairs[k] == r:
			_pairs.erase(k)
	_pairs[_sel_left] = r
	_sel_left = ""
	Audio.sfx("pop")
	_restyle()


func _restyle() -> void:
	var i = 0
	var color_of = {}
	for l in _pairs:
		color_of[l] = Color(PAIR_COLORS[i % PAIR_COLORS.size()])
		i += 1
	for l in _left:
		if color_of.has(l):
			UIKit.set_chip_style(_left[l], color_of[l], UIKit.C_TEXT, color_of[l].darkened(0.3))
		elif l == _sel_left:
			UIKit.set_chip_style(_left[l], Color("dbe4ff"), UIKit.C_TEXT, UIKit.C_PRIMARY)
		else:
			UIKit.set_chip_style(_left[l], Color.WHITE)
	for r in _right:
		var used = false
		for l in _pairs:
			if _pairs[l] == r:
				UIKit.set_chip_style(_right[r], color_of[l], UIKit.C_TEXT, color_of[l].darkened(0.3))
				used = true
		if not used:
			UIKit.set_chip_style(_right[r], Color.WHITE)
	check_btn.disabled = _pairs.size() != _left.size()


func _on_check() -> void:
	if locked:
		return
	locked = true
	var given = []
	var parts = PackedStringArray()
	for l in _pairs:
		given.append([l, _pairs[l]])
		parts.append("%s — %s" % [l, _pairs[l]])
	var ok = AnswerChecker.check_match(task, given)
	if not ok:
		var want = {}
		for p in task["pairs"]:
			want[str(p[0])] = str(p[1])
		for l in _pairs:
			if want[l] != _pairs[l]:
				UIKit.set_chip_style(_left[l], UIKit.C_BAD_L, UIKit.C_TEXT, UIKit.C_BAD)
	submitted.emit(ok, "; ".join(parts))


func retry() -> void:
	locked = false
	var want = {}
	for p in task["pairs"]:
		want[str(p[0])] = str(p[1])
	for l in _pairs.keys():
		if want[l] != _pairs[l]:
			_pairs.erase(l)
	_restyle()


func reveal_answer() -> void:
	super.reveal_answer()
	_pairs.clear()
	for p in task["pairs"]:
		_pairs[str(p[0])] = str(p[1])
	_restyle()
	check_btn.disabled = true
