extends TaskView
## Ввод числа или слова. Встроенная экранная клавиатура (цифры, время, русская или
## английская раскладка) — не зависит от системной клавиатуры телефона.

var _field: Label
var _value = ""
var _layout = "num"


func build() -> void:
	_layout = str(task.get("kb", "num"))
	if _layout == "text":
		_layout = "en" if str(task.get("subject", "")) == "eng" else "ru"
	var fp = UIKit.panel(Color.WHITE, 18, 16)
	fp.add_theme_stylebox_override("panel", UIKit.sb(Color.WHITE, 18, 4, UIKit.C_PRIMARY, 0, 16))
	fp.custom_minimum_size = Vector2(320, 86)
	fp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_field = UIKit.label("", 40, UIKit.C_TEXT, "bold", HORIZONTAL_ALIGNMENT_CENTER)
	_field.custom_minimum_size = Vector2(280, 0)
	fp.add_child(_field)
	add_child(fp)
	_refresh()
	add_child(_keyboard())
	add_child(make_check_button())


func _keyboard() -> Control:
	var rows: Array
	match _layout:
		"num":
			rows = [["1", "2", "3", "4", "5"], ["6", "7", "8", "9", "0"], ["⌫"]]
		"time":
			rows = [["1", "2", "3", "4", "5", "6"], ["7", "8", "9", "0", ":", "⌫"]]
		"en":
			rows = ["qwertyuiop".split(""), "asdfghjkl".split(""), ["z", "x", "c", "v", "b", "n", "m", "'", "⌫"], ["␣"]]
		_:
			rows = ["йцукенгшщзх".split(""), "фывапролджэ".split(""), ["я", "ч", "с", "м", "и", "т", "ь", "б", "ю", "ъ", "ё", "⌫"], ["-", "␣"]]
	var v = UIKit.vbox(8)
	var key_w = 92 if _layout in ["num", "time"] else 60
	for r in rows:
		var h = UIKit.hbox(8)
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		for k in r:
			var key = str(k)
			var b = UIKit.chip_button(key, Color("f1f3ff") if key != "⌫" else Color("ffe3e3"), UIKit.C_TEXT, 30 if key_w > 70 else 24)
			b.custom_minimum_size = Vector2(key_w if key != "␣" else 320, 72 if key_w > 70 else 64)
			b.pressed.connect(func(): _press(key))
			h.add_child(b)
		v.add_child(h)
	return v


func _press(k: String) -> void:
	if locked:
		return
	Audio.sfx("tick")
	if k == "⌫":
		_value = _value.substr(0, maxi(0, _value.length() - 1))
	elif k == "␣":
		if _value.length() > 0 and not _value.ends_with(" "):
			_value += " "
	elif _value.length() < 24:
		_value += k
	_refresh()


func _refresh() -> void:
	_field.text = _value if _value != "" else "…"
	_field.add_theme_color_override("font_color", UIKit.C_TEXT if _value != "" else Color("adb5bd"))
	if check_btn:
		check_btn.disabled = _value.strip_edges() == ""


func _on_check() -> void:
	if locked:
		return
	locked = true
	var ok = AnswerChecker.check_input(task, _value)
	_field.add_theme_color_override("font_color", UIKit.C_OK if ok else UIKit.C_BAD)
	submitted.emit(ok, _value)


func retry() -> void:
	locked = false
	_value = ""
	_refresh()


func reveal_answer() -> void:
	super.reveal_answer()
	_field.text = str(task.get("answer", ""))
	_field.add_theme_color_override("font_color", UIKit.C_OK)
