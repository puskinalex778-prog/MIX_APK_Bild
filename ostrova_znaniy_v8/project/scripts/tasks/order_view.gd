extends TaskView
## Восстановление последовательности и составление выражения/предложения из карточек.
## Нажимай карточки по порядку; нажатие на карточку в строке ответа возвращает её.

var _pool: HFlowContainer
var _line: HFlowContainer
var _seq: Array = []      # кнопки в строке ответа
var _all: Array = []


func build() -> void:
	var is_build = str(task.get("type")) == "build"
	add_child(UIKit.label("Нажимай карточки по порядку" if not is_build else "Составь ответ из карточек (лишние не нужны)", 20, UIKit.C_MUTED, "body", HORIZONTAL_ALIGNMENT_CENTER))
	var lp = UIKit.panel(Color("f1f3ff"), 18, 12)
	lp.custom_minimum_size = Vector2(0, 92)
	_line = UIKit.flow(8)
	_line.alignment = FlowContainer.ALIGNMENT_CENTER
	lp.add_child(_line)
	add_child(lp)
	_pool = UIKit.flow(10)
	_pool.alignment = FlowContainer.ALIGNMENT_CENTER
	add_child(_pool)
	var items: Array = task.get("answer", []).duplicate()
	items.append_array(task.get("extra", []))
	for txt in TaskView.shuffled_not_same(items):
		var b = UIKit.chip_button(str(txt), Color.WHITE, UIKit.C_TEXT, 24)
		b.custom_minimum_size = Vector2(70, 66)
		b.set_meta("txt", str(txt))
		b.pressed.connect(func(): _tap(b))
		_pool.add_child(b)
		_all.append(b)
	add_child(make_check_button())


func _tap(b: Button) -> void:
	if locked:
		return
	if _seq.has(b):
		_seq.erase(b)
		b.reparent(_pool)
	else:
		_seq.append(b)
		b.reparent(_line)
		Audio.sfx("pop")
	check_btn.disabled = _seq.size() != task.get("answer", []).size()


func _given() -> Array:
	var g = []
	for b in _seq:
		g.append(b.get_meta("txt"))
	return g


func _on_check() -> void:
	if locked:
		return
	locked = true
	var g = _given()
	var ok = AnswerChecker.check_order(task, g)
	var ans: Array = task["answer"]
	for i in _seq.size():
		var right = i < ans.size() and AnswerChecker.norm(g[i]) == AnswerChecker.norm(str(ans[i]))
		UIKit.set_chip_style(_seq[i], UIKit.C_OK_L if right else UIKit.C_BAD_L, UIKit.C_TEXT, UIKit.C_OK if right else UIKit.C_BAD)
	submitted.emit(ok, str(task.get("joiner", " ")).join(PackedStringArray(g)) if str(task.get("type")) == "build" else " → ".join(PackedStringArray(g)))


func retry() -> void:
	locked = false
	for b in _seq:
		b.reparent(_pool)
		UIKit.set_chip_style(b, Color.WHITE)
	_seq.clear()
	check_btn.disabled = true


func reveal_answer() -> void:
	super.reveal_answer()
	for b in _seq:
		b.reparent(_pool)
	_seq.clear()
	var used = {}
	for txt in task["answer"]:
		for b in _all:
			if not used.has(b) and AnswerChecker.norm(b.get_meta("txt")) == AnswerChecker.norm(str(txt)):
				used[b] = true
				b.reparent(_line)
				_seq.append(b)
				UIKit.set_chip_style(b, UIKit.C_OK_L, UIKit.C_TEXT, UIKit.C_OK)
				break
