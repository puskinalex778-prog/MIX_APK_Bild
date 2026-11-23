class_name UIKit
extends RefCounted
## Палитра, шрифты, объёмные 3D-кнопки, карточки и фабрика элементов интерфейса
## в ярком стиле «Островов Знаний» (объединённый стиль с ostrova-znaniy).

const C_BG := Color("1f2350")
const C_BG2 := Color("2b2f5c")
const C_PANEL := Color("ffffff")
const C_PANEL2 := Color("eef0ff")
const C_TEXT := Color("1f2350")
const C_MUTED := Color("5a5f8a")
const C_LIGHT := Color("ffffff")
const C_PRIMARY := Color("5b6cff")
const C_PRIMARY_D := Color("3f4fe0")
const C_OK := Color("2fc26b")
const C_OK_L := Color("e2fcee")
const C_BAD := Color("ff5a6e")
const C_BAD_L := Color("ffe8ec")
const C_ORANGE := Color("ff7a3d")
const C_PURPLE := Color("a24df0")
const C_GOLD := Color("ffc83d")
const C_PINK := Color("ff6b9d")
const C_SKY := Color("7ec8ff")

const SUBJECT_COLORS := {
	"math": Color("5b6cff"), "rus": Color("ff7a3d"), "world": Color("2fc26b"),
	"eng": Color("a24df0"), "read": Color("1ea9bd"),
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


static func sb(color: Color, radius: int = 20, border: int = 0, border_color: Color = Color.TRANSPARENT, shadow: int = 0, pad: int = 14) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	if border > 0:
		s.set_border_width_all(border)
		s.border_color = border_color
	if shadow > 0:
		s.shadow_color = Color(0.12, 0.16, 0.47, 0.20)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, shadow * 0.55)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.65
	s.content_margin_bottom = pad * 0.65
	s.anti_aliasing = true
	return s


## Объёмная «игрушечная» 3D-кнопка/карточка с нижней кромкой (как box-shadow: 0 6px 0).
static func sb_3d(color: Color, radius: int = 20, lip: int = 6, shadow: int = 10, pad: int = 18, border_col: Color = Color.TRANSPARENT, side_border: int = 0, pressed: bool = false) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	var lip_col = border_col if border_col.a > 0.01 else color.darkened(0.24)
	var eff_lip = maxi(2, lip - 4) if pressed else lip
	s.border_color = lip_col
	s.border_width_bottom = eff_lip
	s.border_width_left = side_border
	s.border_width_right = side_border
	s.border_width_top = side_border
	if shadow > 0:
		var sh = maxi(2, int(shadow * 0.4)) if pressed else shadow
		s.shadow_color = Color(0.12, 0.16, 0.48, 0.22)
		s.shadow_size = sh
		s.shadow_offset = Vector2(0, sh * 0.55)
	s.content_margin_left = pad
	s.content_margin_right = pad
	var shift = (lip - eff_lip) if pressed else 0
	s.content_margin_top = pad * 0.6 + shift
	s.content_margin_bottom = maxf(4.0, pad * 0.6 + eff_lip - shift)
	s.anti_aliasing = true
	return s


static func build_theme() -> Theme:
	var th = Theme.new()
	th.default_font = font("body")
	th.default_font_size = 24
	# Объёмные кнопки в стиле ostrova-znaniy
	th.set_stylebox("normal", "Button", sb_3d(C_PRIMARY, 20, 6, 10, 18))
	th.set_stylebox("hover", "Button", sb_3d(C_PRIMARY.lightened(0.08), 20, 6, 12, 18))
	th.set_stylebox("pressed", "Button", sb_3d(C_PRIMARY.darkened(0.06), 20, 6, 10, 18, Color.TRANSPARENT, 0, true))
	th.set_stylebox("disabled", "Button", sb_3d(Color("a9adc4"), 20, 4, 0, 18))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", C_LIGHT)
	th.set_color("font_hover_color", "Button", C_LIGHT)
	th.set_color("font_pressed_color", "Button", C_LIGHT)
	th.set_color("font_focus_color", "Button", C_LIGHT)
	th.set_color("font_disabled_color", "Button", Color("f1f3f8"))
	th.set_font("font", "Button", font("bold"))
	th.set_font_size("font_size", "Button", 26)
	# Метки
	th.set_color("font_color", "Label", C_TEXT)
	# Панели (эффект светлого стекла)
	th.set_stylebox("panel", "PanelContainer", sb(Color(1, 1, 1, 0.92), 28, 2, Color(1, 1, 1, 0.85), 14, 22))
	th.set_stylebox("panel", "Panel", sb(Color(1, 1, 1, 0.92), 28, 2, Color(1, 1, 1, 0.85), 10, 18))
	# Поле ввода
	th.set_stylebox("normal", "LineEdit", sb(Color.WHITE, 16, 3, Color("dfe3ff"), 0, 16))
	th.set_stylebox("focus", "LineEdit", sb(Color.WHITE, 16, 3, C_PRIMARY, 0, 16))
	th.set_color("font_color", "LineEdit", C_TEXT)
	th.set_font_size("font_size", "LineEdit", 30)
	# Прогрессбар (как .pbar .track / .fill)
	th.set_stylebox("background", "ProgressBar", sb(Color(1, 1, 1, 0.58), 12, 2, Color(1, 1, 1, 0.7), 0, 0))
	th.set_stylebox("fill", "ProgressBar", sb(C_OK, 12, 0, Color.TRANSPARENT, 0, 0))
	th.set_color("font_color", "ProgressBar", C_TEXT)
	th.set_font_size("font_size", "ProgressBar", 16)
	# Скролл
	var grab = sb(Color(0.36, 0.42, 0.85, 0.45), 8, 0, Color.TRANSPARENT, 0, 4)
	th.set_stylebox("grabber", "VScrollBar", grab)
	th.set_stylebox("grabber_highlight", "VScrollBar", grab)
	th.set_stylebox("grabber_pressed", "VScrollBar", grab)
	th.set_stylebox("scroll", "VScrollBar", sb(Color(0, 0, 0, 0.06), 8, 0, Color.TRANSPARENT, 0, 4))
	# Слайдер
	th.set_stylebox("slider", "HSlider", sb(Color("ced4f0"), 8, 0, Color.TRANSPARENT, 0, 4))
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
	l.add_theme_color_override("font_shadow_color", Color(0.12, 0.14, 0.45, 0.35))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


static func apply_button_color(b: Button, color: Color, fg: Color = C_LIGHT, radius: int = 20, lip: int = 6) -> void:
	var is_glass = color.a < 0.92
	if is_glass:
		b.add_theme_stylebox_override("normal", sb(color, radius, 1, Color(1, 1, 1, 0.28), 8, 16))
		b.add_theme_stylebox_override("hover", sb(color.lightened(0.08), radius, 1, Color(1, 1, 1, 0.35), 10, 16))
		b.add_theme_stylebox_override("pressed", sb(color.darkened(0.12), radius, 1, Color(1, 1, 1, 0.2), 2, 16))
	else:
		b.add_theme_stylebox_override("normal", sb_3d(color, radius, lip, 10, 18))
		b.add_theme_stylebox_override("hover", sb_3d(color.lightened(0.07), radius, lip, 12, 18))
		b.add_theme_stylebox_override("pressed", sb_3d(color.darkened(0.06), radius, lip, 10, 18, Color.TRANSPARENT, 0, true))
		b.add_theme_stylebox_override("disabled", sb_3d(Color("a9adc4"), radius, 4, 0, 18))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, fg)


static func button(text: String, color: Color = C_PRIMARY, size: int = 26, min_size: Vector2 = Vector2(0, 72)) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", size)
	var fg = Color("5a3b00") if (color.r > 0.85 and color.g > 0.72 and color.b < 0.45) else C_LIGHT
	apply_button_color(b, color, fg)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): Audio.sfx("click"))
	if text.length() > 24:
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if min_size.x <= 0:
			b.custom_minimum_size.x = clampf(text.length() * size * 0.55, 220.0, 480.0)
	return b


static func chip_button(text: String, bg: Color = Color("f7f8ff"), fg: Color = C_TEXT, size: int = 26, border: Color = Color("c9cff0")) -> Button:
	var b = Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(80, 66)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_font_override("font", font("bold"))
	set_chip_style(b, bg, fg, border)
	if text.length() > 18:
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.x = clampf(text.length() * size * 0.3, 200.0, 420.0)
	return b


static func set_chip_style(b: Button, bg: Color, fg: Color = C_TEXT, border: Color = Color("c9cff0")) -> void:
	b.add_theme_stylebox_override("normal", sb_3d(bg, 18, 5, 6, 14, border, 2, false))
	b.add_theme_stylebox_override("hover", sb_3d(bg.lightened(0.04), 18, 5, 8, 14, border.darkened(0.08), 2, false))
	b.add_theme_stylebox_override("pressed", sb_3d(bg.darkened(0.04), 18, 5, 4, 14, border.darkened(0.12), 2, true))
	b.add_theme_stylebox_override("disabled", sb_3d(bg, 18, 4, 0, 14, border, 2, false))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, fg)


static func panel(color: Color = Color(1, 1, 1, 0.90), radius: int = 26, pad: int = 22) -> PanelContainer:
	var p = PanelContainer.new()
	var bd = Color(1, 1, 1, 0.8) if color.a < 0.99 else Color(0.87, 0.89, 1.0, 0.5)
	p.add_theme_stylebox_override("panel", sb(color, radius, 2, bd, 10, pad))
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
	var back = button("←", C_PRIMARY, 32, Vector2(76, 66))
	back.tooltip_text = "Назад"
	back.pressed.connect(on_back)
	bar.add_child(back)
	var t = title(title_text, 32)
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
		c.scale = Vector2(0.88, 0.88)
		c.modulate.a = 0.0
		var tw = c.create_tween().set_parallel(true)
		tw.tween_property(c, "scale", Vector2.ONE, 0.28).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "modulate:a", 1.0, 0.2).set_delay(delay)


static func shake(c: Control) -> void:
	if Settings.reduce_motion or not is_instance_valid(c) or not c.is_inside_tree():
		return
	var x = c.position.x
	var tw = c.create_tween()
	for i in 4:
		tw.tween_property(c, "position:x", x + (10 if i % 2 == 0 else -10), 0.05)
	tw.tween_property(c, "position:x", x, 0.05)


static func toast(parent: Node, text: String, color: Color = C_TEXT, secs: float = 2.2) -> void:
	var p = panel(color, 26, 16)
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
