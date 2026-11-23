extends TaskView
## Выбор одного ответа; также «верно/неверно», вставка в пропуск и задания на слух.

var _buttons = {}


func build() -> void:
	if str(task.get("type")) == "listen":
		var row = UIKit.hbox(16)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		var play = UIKit.button("🔊 Послушать", Color("ae3ec9"), 30, Vector2(300, 90))
		play.pressed.connect(func():
			if not Audio.speak_en(str(task.get("audio", ""))):
				UIKit.toast(self, "Звук недоступен: включите речь в настройках", UIKit.C_BAD))
		row.add_child(play)
		add_child(row)
		play.ready.connect(func(): get_tree().create_timer(0.4).timeout.connect(func():
			if is_instance_valid(self):
				Audio.speak_en(str(task.get("audio", "")))))
	var opts: Array = task.get("options", [])
	if str(task.get("type")) != "tf":
		opts = TaskView.shuffled(opts)
	var long = false
	for o in opts:
		if str(o).length() > 22:
			long = true
	var box: Container
	if long:
		box = UIKit.vbox(12)
	else:
		box = GridContainer.new()
		(box as GridContainer).columns = 2 if opts.size() != 3 else 3
		box.add_theme_constant_override("h_separation", 14)
		box.add_theme_constant_override("v_separation", 14)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for o in opts:
		var b = UIKit.chip_button(str(o), Color.WHITE, UIKit.C_TEXT, 28 if not long else 24)
		b.custom_minimum_size = Vector2(0, 84)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var val = str(o)
		b.pressed.connect(func(): _pick(val))
		box.add_child(b)
		_buttons[val] = b
	add_child(box)


func _pick(val: String) -> void:
	if locked:
		return
	var ok = AnswerChecker.check_choice(task, val)
	var b: Button = _buttons[val]
	if ok:
		UIKit.set_chip_style(b, UIKit.C_OK_L, UIKit.C_TEXT, UIKit.C_OK)
	else:
		UIKit.set_chip_style(b, UIKit.C_BAD_L, UIKit.C_TEXT, UIKit.C_BAD)
		b.disabled = true
		UIKit.shake(b)
	locked = true
	submitted.emit(ok, val)


func retry() -> void:
	locked = false


func reveal_answer() -> void:
	locked = true
	var a = str(task.get("answer", ""))
	if _buttons.has(a):
		UIKit.set_chip_style(_buttons[a], UIKit.C_OK_L, UIKit.C_TEXT, UIKit.C_OK)
