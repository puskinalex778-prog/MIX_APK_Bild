extends Node
## Переходы между экранами со стеком «назад» и анимацией.

const SCREENS := {
	"welcome": "res://scripts/screens/welcome_screen.gd",
	"profiles": "res://scripts/screens/profile_select.gd",
	"map": "res://scripts/screens/map_screen.gd",
	"subject": "res://scripts/screens/subject_screen.gd",
	"lesson": "res://scripts/screens/lesson_screen.gd",
	"story": "res://scripts/screens/story_screen.gd",
	"mult": "res://scripts/screens/mult_screen.gd",
	"settings": "res://scripts/screens/settings_screen.gd",
	"parent": "res://scripts/screens/parent_screen.gd",
	"info": "res://scripts/screens/info_screen.gd",
	"achievements": "res://scripts/screens/achievements_screen.gd",
	"break": "res://scripts/screens/break_screen.gd",
}

var host: Control
var overlay_host: Control
var _stack: Array = []   # [{name, params}]
var _current: Control
var busy = false


func setup(h: Control, o: Control) -> void:
	host = h
	overlay_host = o


func current_name() -> String:
	return _stack.back()["name"] if _stack.size() > 0 else ""


func go(name: String, params: Dictionary = {}, replace: bool = false) -> void:
	if replace and _stack.size() > 0:
		_stack.pop_back()
	_stack.append({"name": name, "params": params})
	_show(name, params, 1)


func reset_to(name: String, params: Dictionary = {}) -> void:
	_stack.clear()
	go(name, params)


func back() -> void:
	if _current and _current.has_method("on_back") and _current.on_back():
		return  # экран сам обработал «назад»
	if _stack.size() <= 1:
		if _current and _current.has_method("on_root_back"):
			_current.on_root_back()
		return
	_stack.pop_back()
	var top: Dictionary = _stack.back()
	_show(top["name"], top["params"], -1)


func _show(name: String, params: Dictionary, dir: int) -> void:
	var script = load(SCREENS[name])
	var scr: Control = script.new()
	UIKit.full_rect(scr)
	scr.set_meta("screen_name", name)
	var old = _current
	_current = scr
	host.add_child(scr)
	if scr.has_method("setup"):
		scr.setup(params)
	Wellbeing.active = scr.has_meta("learning") and scr.get_meta("learning")
	if old and is_instance_valid(old):
		if Settings.reduce_motion:
			old.queue_free()
		else:
			var w = host.get_viewport_rect().size.x
			scr.position.x = w * 0.25 * dir
			scr.modulate.a = 0.0
			var tw = scr.create_tween().set_parallel(true)
			tw.tween_property(scr, "position:x", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tw.tween_property(scr, "modulate:a", 1.0, 0.2)
			old.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var tw2 = old.create_tween()
			tw2.tween_property(old, "modulate:a", 0.0, 0.18)
			tw2.tween_callback(old.queue_free)


func current_screen() -> Control:
	return _current


## Показывает модальное окно поверх экрана (перерыв, подтверждения).
func overlay(node: Control) -> void:
	UIKit.full_rect(node)
	overlay_host.add_child(node)


func has_overlay() -> bool:
	return overlay_host.get_child_count() > 0
