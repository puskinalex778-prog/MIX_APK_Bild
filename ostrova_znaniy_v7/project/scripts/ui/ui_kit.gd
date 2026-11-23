class_name UIKit
extends RefCounted
## Палитра, шрифты, тема и фабрика типовых элементов интерфейса.

const C_BG := Color("1b264d")
const C_BG2 := Color("24346b")
const C_PANEL := Color("fffaf0")
const C_PANEL2 := Color("eef3ff")
const C_TEXT := Color("2b2d42")
const C_MUTED := Color("6c7293")
const C_LIGHT := Color("ffffff")
const C_PRIMARY := Color("4c6ef5")
const C_PRIMARY_D := Color("364fc7")
const C_OK := Color("37b24d")
const C_OK_L := Color("d3f9d8")
const C_BAD := Color("f76707")
const C_BAD_L := Color("ffe8cc")
const C_GOLD := Color("fcc419")
const C_PINK := Color("f783ac")
const C_SKY := Color("74c0fc")

const SUBJECT_COLORS := {
	"math": Color("4c6ef5"), "rus": Color("e8590c"), "world": Color("2f9e44"),
	"eng": Color("ae3ec9"), "read": Color("1098ad"),
}
const SUBJECT_ICONS := {"math": "🔢", "rus": "📝", "world": "🌍", "eng": "🇬🇧", "read": "📚"}
const SUBJECT_ISLANDS := {
	"math": "Остров Чисел", "rus": "Остров Слов", "world": "Зелёный остров",
	"eng": "Порт Hello", "read": "Остров Сказок",
}

static var _fonts := {}
static var ui_scale := 1.0


static func font(kind: String = "body") -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var emoji: FontFile = load("res://assets/fonts/NotoColorEmoji.ttf")
	var path = "res://assets/fonts/NotoSans-Regular.ttf"
	match kind:
		"bold":
			path = "res://assets/fonts/NotoSans-Bold.ttf"
		"title":
			path = "res://assets/fonts/Comfortaa-Bold.ttf"
		"round":
			path = "res://assets/fonts/Comfortaa-Regular.ttf"
		"emoji":
			_fonts[kind] = emoji
			return emoji
	var base: FontFile = load(path)
	var fv = FontVariation.new()
	fv.base_font = base
	var fb: Array[Font] = [emoji]
	if kind == "title" or kind == "round":
		fb.insert(0, load("res://assets/fonts/NotoSans-Bold.ttf"))
	fv.fallbacks = fb
	_fonts[kind] = fv
	return fv


static func sb(color: Color, radius: int = 18, border: int = 0, border_color: Color = Color.TRANSPARENT, shadow: int = 0, pad: int = 14) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	if border > 0:
		s.set_border_width_all(border)
		s.border_color = border_color
	if shadow > 0:
		s.shadow_color = Color(0, 0, 0, 0.18)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, shadow * 0.5)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	s.anti_aliasing = true
	return s


static func build_theme() -> Theme:
	var th = Theme.new()
	th.default_font = font("body")
	th.default_font_size = 24
	# Кнопки
	th.set_stylebox("normal", "Button", sb(C_PRIMARY, 20, 0, Color.TRANSPARENT, 4, 18))
	th.set_stylebox("hover", "Button", sb(C_PRIMARY.lightened(0.08), 20, 0, Color.TRANSPARENT, 5, 18))
	th.set_stylebox("pressed", "Button", sb(C_PRIMARY_D, 20, 0, Color.TRANSPARENT, 1, 18))
	th.set_stylebox("disabled", "Button", sb(Color("adb5bd"), 20, 0, Color.TRANSPARENT, 0, 18))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", C_LIGHT)
	th.set_color("font_hover_color", "Button", C_LIGHT)
	th.set_color("font_pressed_color", "Button", C_LIGHT)
	th.set_color("font_focus_color", "Button", C_LIGHT)
	th.set_color("font_disabled_color", "Button", Color("f1f3f5"))
	th.set_font("font", "Button", font("bold"))
	th.set_font_size("font_size", "Button", 26)
	# Метки
	th.set_color("font_color", "Label", C_TEXT)
	# Панели
	th.set_stylebox("panel", "PanelContainer", sb(C_PANEL, 26, 0, Color.TRANSPARENT, 8, 22))
	th.set_stylebox("panel", "Panel", sb(C_PANEL, 26))
	# Поле ввода
	th.set_stylebox("normal", "LineEdit", sb(Color.WHITE, 16, 3, Color("bac8ff"), 0, 16))
	th.set_stylebox("focus", "LineEdit", sb(Color.WHITE, 16, 3, C_PRIMARY, 0, 16))
	th.set_color("font_color", "LineEdit", C_TEXT)
	th.set_font_size("font_size", "LineEdit", 30)
	# Прогресс
	th.set_stylebox("background", "ProgressBar", sb(Color("dee2e6"), 12, 0, Color.TRANSPARENT, 0, 0))
	th.set_stylebox("fill", "ProgressBar", sb(C_OK, 12, 0, Color.TRANSPARENT, 0, 0))
	th.set_color("font_color", "ProgressBar", C_TEXT)
	th.set_font_size("font_size", "ProgressBar", 16)
	# Скролл
	var grab = sb(Color(1, 1, 1, 0.5), 8, 0, Color.TRANSPARENT, 0, 4)
	th.set_stylebox("grabber", "VScrollBar", grab)
	th.set_stylebox("grabber_highlight", "VScrollBar", grab)
	th.set_stylebox("grabber_pressed", "VScrollBar", grab)
	th.set_stylebox("scroll", "VScrollBar", sb(Color(0, 0, 0, 0.08), 8, 0, Color.TRANSPARENT, 0, 4))
	# Слайдер
	th.set_stylebox("slider", "HSlider", sb(Color("ced4da"), 8, 0, Color.TRANSPARENT, 0, 4))
	th.set_stylebox("grabber_area", "HSlider", sb(C_PRIMARY, 8, 0, Color.TRANSPARENT, 0, 4))
	th.set_stylebox("grabber_area_highlight", "HSlider", sb(C_PRIMARY, 8, 0, Color.TRANSPARENT, 0, 4))
	# Чекбокс
	th.set_color("font_color", "CheckButton", C_TEXT)
	th.set_color("font_hover_color", "CheckButton", C_TEXT)
	th.set_color("font_pressed_color", "CheckButton", C_TEXT)
	th.set_color("font_hover_pressed_color", "CheckButton", C_TEXT)
	th.set_stylebox("normal", "CheckButton", StyleBoxEmpty.new())
	th.set_stylebox("hover", "CheckButton", StyleBoxEmpty.new())
	th.set_stylebox("pressed", "CheckButton", StyleBoxEmpty.new())
	th.set_stylebox("focus", "CheckButton", StyleBoxEmpty.new())
	th.set_font_size("font_size", "CheckButton", 24)
	# Подсказки
	th.set_stylebox("panel", "TooltipPanel", sb(C_TEXT, 10))
	return th


# ---------- фабрика элементов ----------
static func label(text: String, size: int = 24, color: Color = C_TEXT, kind: String = "body", align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_override("font", font(kind))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func nowrap(l: Label) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l


static func title(text: String, size: int = 40, color: Color = C_LIGHT) -> Label:
	var l = label(text, size, color, "title", HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_constant_override("outline_size", 0)
	return l


static func button(text: String, color: Color = C_PRIMARY, size: int = 26, min_size: Vector2 = Vector2(0, 72)) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", size)
	if color != C_PRIMARY:
		b.add_theme_stylebox_override("normal", sb(color, 20, 0, Color.TRANSPARENT, 4, 18))
		b.add_theme_stylebox_override("hover", sb(color.lightened(0.08), 20, 0, Color.TRANSPARENT, 5, 18))
		b.add_theme_stylebox_override("pressed", sb(color.darkened(0.15), 20, 0, Color.TRANSPARENT, 1, 18))
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): Audio.sfx("click"))
	if text.length() > 24:
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if min_size.x <= 0:
			# без минимальной ширины перенос сжал бы кнопку до одной буквы в строке
			b.custom_minimum_size.x = clampf(text.length() * size * 0.55, 220.0, 480.0)
	return b


static func chip_button(text: String, bg: Color = Color.WHITE, fg: Color = C_TEXT, size: int = 26, border: Color = Color("bac8ff")) -> Button:
	var b = Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(64, 64)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_font_override("font", font("bold"))
	set_chip_style(b, bg, fg, border)
	if text.length() > 18:
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# ширина под 2–3 строки текста, чтобы слова не разрывались посередине
		b.custom_minimum_size.x = clampf(text.length() * size * 0.3, 200.0, 420.0)
	return b


static func set_chip_style(b: Button, bg: Color, fg: Color = C_TEXT, border: Color = Color("bac8ff")) -> void:
	b.add_theme_stylebox_override("normal", sb(bg, 18, 3, border, 3, 16))
	b.add_theme_stylebox_override("hover", sb(bg.lightened(0.05), 18, 3, border.darkened(0.1), 4, 16))
	b.add_theme_stylebox_override("pressed", sb(bg.darkened(0.08), 18, 3, border.darkened(0.2), 1, 16))
	b.add_theme_stylebox_override("disabled", sb(bg, 18, 3, border, 0, 16))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, fg)


static func panel(color: Color = C_PANEL, radius: int = 26, pad: int = 22) -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", sb(color, radius, 0, Color.TRANSPARENT, 8, pad))
	return p


static func vbox(sep: int = 12) -> VBoxContainer:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep: int = 12) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func flow(sep: int = 10) -> HFlowContainer:
	var f = HFlowContainer.new()
	f.add_theme_constant_override("h_separation", sep)
	f.add_theme_constant_override("v_separation", sep)
	return f


static func margin(child: Control, l: int, t: int, r: int, b: int) -> MarginContainer:
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	if child:
		m.add_child(child)
	return m


static func scroll(child: Control) -> ScrollContainer:
	var s = ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(child)
	s.add_to_group("touch_scroll")   # прокрутка пальцем поверх кнопок (TouchScroll)
	return s


static func spacer(h: bool = true) -> Control:
	var c = Control.new()
	if h:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func full_rect(c: Control) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0
	return c


static func top_bar(title_text: String, on_back: Callable, extra: Array = []) -> HBoxContainer:
	var bar = hbox(14)
	var back = button("←", Color("5c7cfa"), 34, Vector2(84, 72))
	back.tooltip_text = "Назад"
	back.pressed.connect(on_back)
	bar.add_child(back)
	var t = title(title_text, 34)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.clip_text = true
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(t)
	for e in extra:
		bar.add_child(e)
	return bar


static func pop_in(node: CanvasItem, delay: float = 0.0) -> void:
	if Settings.reduce_motion or not node.is_inside_tree():
		return
	if node is Control:
		var c = node as Control
		c.pivot_offset = c.size * 0.5
		c.scale = Vector2(0.85, 0.85)
		c.modulate.a = 0.0
		var tw = c.create_tween().set_parallel(true)
		tw.tween_property(c, "scale", Vector2.ONE, 0.28).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "modulate:a", 1.0, 0.2).set_delay(delay)


static func shake(c: Control) -> void:
	if Settings.reduce_motion:
		return
	var x = c.position.x
	var tw = c.create_tween()
	for i in 4:
		tw.tween_property(c, "position:x", x + (10 if i % 2 == 0 else -10), 0.05)
	tw.tween_property(c, "position:x", x, 0.05)


static func toast(parent: Node, text: String, color: Color = C_TEXT, secs: float = 2.2) -> void:
	var p = panel(color, 22, 18)
	var l = label(text, 24, Color.WHITE, "bold", HORIZONTAL_ALIGNMENT_CENTER)
	p.add_child(l)
	p.set_anchors_preset(Control.PRESET_CENTER_TOP)
	p.position = Vector2(0, 20)
	p.custom_minimum_size = Vector2(420, 0)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	await parent.get_tree().process_frame
	if not is_instance_valid(p):
		return
	p.position.x = (parent.get_viewport().get_visible_rect().size.x - p.size.x) * 0.5
	p.position.y = 24
	var tw = p.create_tween()
	tw.tween_interval(secs)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)


static func gender_word(boy: String, girl: String) -> String:
	var pr: Dictionary = Profiles.current()
	if pr.get("gender", "boy") == "girl":
		return girl
	return boy
