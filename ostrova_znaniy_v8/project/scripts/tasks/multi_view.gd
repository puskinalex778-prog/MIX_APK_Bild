extends TaskView
## Выбор нескольких правильных ответов.

var _sel = {}
var _buttons = {}


func build() -> void:
	add_child(UIKit.label("Выбери все подходящие ответы", 20, UIKit.C_MUTED, "body", HORIZONTAL_ALIGNMENT_CENTER))
	var box = UIKit.flow(12)
	box.alignment = FlowContainer.ALIGNMENT_CENTER
	for o in TaskView.shuffled(task.get("options", [])):
		var val = str(o)
		var b = UIKit.chip_button(val, Color.WHITE, UIKit.C_TEXT, 24)
		b.custom_minimum_size = Vector2(160, 76)
		b.pressed.connect(func(): _toggle(val))
		box.add_child(b)
		_buttons[val] = b
	add_child(box)
	add_child(make_check_button())


func _toggle(val: String) -> void:
	if locked:
		return
	if _sel.has(val):
		_sel.erase(val)
		UIKit.set_chip_style(_buttons[val], Color.WHITE)
	else:
		_sel[val] = true
		UIKit.set_chip_style(_buttons[val], Color("dbe4ff"), UIKit.C_TEXT, UIKit.C_PRIMARY)
	check_btn.disabled = _sel.is_empty()


func _on_check() -> void:
	if locked:
		return
	locked = true
	var given = _sel.keys()
	var ok = AnswerChecker.check_multi(task, given)
	for v in given:
		var right: bool = task["answer"].has(v)
		UIKit.set_chip_style(_buttons[v], UIKit.C_OK_L if right else UIKit.C_BAD_L, UIKit.C_TEXT, UIKit.C_OK if right else UIKit.C_BAD)
	submitted.emit(ok, ", ".join(PackedStringArray(given)))


func retry() -> void:
	locked = false
	for v in _sel.keys():
		if not task["answer"].has(v):
			_sel.erase(v)
			UIKit.set_chip_style(_buttons[v], Color.WHITE)
	check_btn.disabled = _sel.is_empty()


func reveal_answer() -> void:
	super.reveal_answer()
	for v in task["answer"]:
		if _buttons.has(v):
			UIKit.set_chip_style(_buttons[v], UIKit.C_OK_L, UIKit.C_TEXT, UIKit.C_OK)
