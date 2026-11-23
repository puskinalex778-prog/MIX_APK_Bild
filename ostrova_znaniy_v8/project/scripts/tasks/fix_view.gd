extends TaskView
## «Найди и исправь ошибку»: нажми неверную часть, затем выбери исправление.

var _tokens = []
var _picked = -1
var _opts_box: HFlowContainer
var _repl = ""
var _opt_buttons = {}


func build() -> void:
	add_child(UIKit.label("1) Нажми, где ошибка.  2) Выбери, как исправить.", 20, UIKit.C_MUTED, "body", HORIZONTAL_ALIGNMENT_CENTER))
	var line = UIKit.flow(8)
	line.alignment = FlowContainer.ALIGNMENT_CENTER
	var toks: Array = task.get("tokens", [])
	for i in toks.size():
		var b = UIKit.chip_button(str(toks[i]), Color("fffdf5"), UIKit.C_TEXT, 28, Color("ffe066"))
		b.custom_minimum_size = Vector2(60, 72)
		var idx = i
		b.pressed.connect(func(): _pick_token(idx))
		line.add_child(b)
		_tokens.append(b)
	add_child(line)
	_opts_box = UIKit.flow(12)
	_opts_box.alignment = FlowContainer.ALIGNMENT_CENTER
	_opts_box.visible = false
	add_child(_opts_box)
	for o in TaskView.shuffled(task.get("options", [])):
		var val = str(o)
		var ob = UIKit.chip_button(val, Color.WHITE, UIKit.C_TEXT, 26)
		ob.custom_minimum_size = Vector2(120, 70)
		ob.pressed.connect(func(): _pick_repl(val))
		_opts_box.add_child(ob)
		_opt_buttons[val] = ob
	add_child(make_check_button())


func _pick_token(i: int) -> void:
	if locked:
		return
	_picked = i
	for j in _tokens.size():
		UIKit.set_chip_style(_tokens[j], Color("ffe3e3") if j == i else Color("fffdf5"), UIKit.C_TEXT, UIKit.C_BAD if j == i else Color("ffe066"))
	_opts_box.visible = true
	check_btn.disabled = _repl == ""


func _pick_repl(v: String) -> void:
	if locked:
		return
	_repl = v
	for k in _opt_buttons:
		UIKit.set_chip_style(_opt_buttons[k], Color("dbe4ff") if k == v else Color.WHITE, UIKit.C_TEXT, UIKit.C_PRIMARY if k == v else Color("bac8ff"))
	check_btn.disabled = _picked < 0


func _on_check() -> void:
	if locked:
		return
	locked = true
	var ok = AnswerChecker.check_fix(task, _picked, _repl)
	var given = "«%s» → «%s»" % [task["tokens"][_picked] if _picked >= 0 else "?", _repl]
	submitted.emit(ok, given)


func retry() -> void:
	locked = false
	_repl = ""
	for k in _opt_buttons:
		UIKit.set_chip_style(_opt_buttons[k], Color.WHITE)
	check_btn.disabled = true


func reveal_answer() -> void:
	super.reveal_answer()
	var w = int(task.get("wrong", 0))
	if w < _tokens.size():
		_tokens[w].text = "%s → %s" % [task["tokens"][w], task.get("answer", "")]
		UIKit.set_chip_style(_tokens[w], UIKit.C_OK_L, UIKit.C_TEXT, UIKit.C_OK)
	_opts_box.visible = false
