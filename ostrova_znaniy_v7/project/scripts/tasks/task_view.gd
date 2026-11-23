class_name TaskView
extends VBoxContainer
## Базовый класс интерактивного задания. Конкретные механики — в наследниках.

signal submitted(correct: bool, given: String)

var task: Dictionary = {}
var locked = false
var check_btn: Button


static func create(t: Dictionary) -> TaskView:
	var v: TaskView
	match str(t.get("type", "")):
		"choice", "tf", "fill", "listen":
			v = load("res://scripts/tasks/choice_view.gd").new()
		"multi":
			v = load("res://scripts/tasks/multi_view.gd").new()
		"input":
			v = load("res://scripts/tasks/input_view.gd").new()
		"match":
			v = load("res://scripts/tasks/match_view.gd").new()
		"sort":
			v = load("res://scripts/tasks/sort_view.gd").new()
		"order", "build":
			v = load("res://scripts/tasks/order_view.gd").new()
		"fix":
			v = load("res://scripts/tasks/fix_view.gd").new()
		"array_build":
			v = load("res://scripts/tasks/array_build_view.gd").new()
		_:
			v = load("res://scripts/tasks/choice_view.gd").new()
	v.task = t
	v.add_theme_constant_override("separation", 14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.build()
	return v


func build() -> void:
	pass


## Показ правильного ответа после второй неудачной попытки.
func reveal_answer() -> void:
	locked = true
	if check_btn:
		check_btn.disabled = true


## Подготовка ко второй попытке.
func retry() -> void:
	locked = false
	if check_btn:
		check_btn.disabled = false


func make_check_button(enabled: bool = false) -> Button:
	check_btn = UIKit.button("Проверить ✔", UIKit.C_OK, 28, Vector2(260, 76))
	check_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	check_btn.disabled = not enabled
	check_btn.pressed.connect(_on_check)
	return check_btn


func _on_check() -> void:
	pass


static func shuffled(arr: Array) -> Array:
	var a = arr.duplicate()
	a.shuffle()
	return a


## Перемешивание, гарантирующее, что порядок отличается от исходного (если это возможно).
static func shuffled_not_same(arr: Array) -> Array:
	if arr.size() < 2:
		return arr.duplicate()
	for i in 10:
		var a = shuffled(arr)
		if a != arr:
			return a
	var b = arr.duplicate()
	b.reverse()
	return b
