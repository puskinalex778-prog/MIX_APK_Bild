class_name BaseScreen
extends Control
## Общая основа экранов: фон, поля, корневой вертикальный контейнер.

var bg: Scenery
var root: VBoxContainer


func make_layout(bg_mode: String = "sky", pad: int = 28, dim: float = 0.0) -> VBoxContainer:
	bg = Scenery.new(bg_mode)
	UIKit.full_rect(bg)
	add_child(bg)
	if dim > 0.0:
		var d = ColorRect.new()
		d.color = Color(0.1, 0.12, 0.25, dim)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIKit.full_rect(d)
		add_child(d)
	root = UIKit.vbox(16)
	var m = UIKit.margin(root, pad, pad - 8, pad, pad - 8)
	UIKit.full_rect(m)
	add_child(m)
	return root


func confirm(text: String, yes_text: String, on_yes: Callable, no_text: String = "Отмена") -> void:
	var ov = ColorRect.new()
	ov.color = Color(0, 0, 0, 0.5)
	var center = CenterContainer.new()
	UIKit.full_rect(center)
	ov.add_child(center)
	var p = UIKit.panel(UIKit.C_PANEL, 26, 28)
	p.custom_minimum_size = Vector2(620, 0)
	var v = UIKit.vbox(18)
	v.add_child(UIKit.label(text, 26, UIKit.C_TEXT, "bold", HORIZONTAL_ALIGNMENT_CENTER))
	var h = UIKit.hbox(16)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var no = UIKit.button(no_text, Color("868e96"), 24, Vector2(220, 70))
	no.pressed.connect(ov.queue_free)
	var yes = UIKit.button(yes_text, UIKit.C_BAD, 24, Vector2(220, 70))
	yes.pressed.connect(func():
		ov.queue_free()
		on_yes.call())
	h.add_child(no)
	h.add_child(yes)
	v.add_child(h)
	p.add_child(v)
	center.add_child(p)
	Router.overlay(ov)
	UIKit.pop_in(p)
