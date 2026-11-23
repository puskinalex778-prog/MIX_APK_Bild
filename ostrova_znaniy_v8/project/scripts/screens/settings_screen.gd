extends BaseScreen
## Настройки звука, речи, движения и устройства. Сохраняются сразу.


func setup(_params: Dictionary) -> void:
	make_layout("sky", 28, 0.3)
	root.add_child(UIKit.top_bar("⚙️ Настройки", Router.back))
	var card = UIKit.panel(Color(1, 1, 1, 0.97), 26, 24)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v = UIKit.vbox(14)
	card.add_child(UIKit.scroll(v))
	root.add_child(card)
	v.add_child(_toggle("🎵 Музыка", Settings.music_on, func(b): Settings.music_on = b))
	v.add_child(_slider("Громкость музыки", Settings.music_volume, func(x): Settings.music_volume = x))
	v.add_child(_toggle("🔔 Звуковые эффекты", Settings.sfx_on, func(b): Settings.sfx_on = b))
	v.add_child(_slider("Громкость эффектов", Settings.sfx_volume, func(x): Settings.sfx_volume = x))
	v.add_child(_toggle("🗣️ Речь (английские слова, чтение заданий)", Settings.speech_on, func(b): Settings.speech_on = b))
	v.add_child(_slider("Громкость речи", Settings.speech_volume, func(x): Settings.speech_volume = x))
	v.add_child(_slider("🔊 Общая громкость", Settings.master_volume, func(x): Settings.master_volume = x))
	v.add_child(_toggle("🐢 Меньше движения (без лишней анимации)", Settings.reduce_motion, func(b): Settings.reduce_motion = b))
	v.add_child(_toggle("🤖 Английский голос системы (если установлен) вместо встроенного", Settings.english_voice == "system", func(b): Settings.english_voice = "system" if b else "builtin"))
	var dev = UIKit.hbox(12)
	dev.add_child(UIKit.nowrap(UIKit.label("Устройство:", 24, UIKit.C_TEXT, "bold")))
	for d in [["tablet", "📲 Планшет"], ["phone", "📱 Телефон"]]:
		var b = UIKit.button(d[1], UIKit.C_PRIMARY if Settings.device == d[0] else Color("adb5bd"), 22, Vector2(200, 64))
		var val: String = d[0]
		b.pressed.connect(func():
			Settings.device = val
			Settings.save()
			Settings.apply_device_scale(get_tree().root)
			Router.go("settings", {}, true))
		dev.add_child(b)
	v.add_child(dev)
	var test = UIKit.button("▶ Проверить звук", Color("1098ad"), 22, Vector2(260, 64))
	test.pressed.connect(func():
		Audio.sfx("correct")
		Audio.speak_en("Hello! Let's learn English!"))
	v.add_child(test)
	v.add_child(UIKit.label("Озвучка заданий на русском использует системный синтезатор речи телефона (если он установлен).", 18, UIKit.C_MUTED))


func _toggle(text: String, val: bool, cb: Callable) -> Control:
	var c = CheckButton.new()
	c.text = text
	c.button_pressed = val
	c.add_theme_font_size_override("font_size", 24)
	c.toggled.connect(func(b):
		cb.call(b)
		Settings.save()
		Audio.sfx("click"))
	return c


func _slider(text: String, val: float, cb: Callable) -> Control:
	var h = UIKit.hbox(12)
	var l = UIKit.label(text, 20, UIKit.C_MUTED)
	l.custom_minimum_size = Vector2(300, 0)
	h.add_child(l)
	var s = HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = val
	s.custom_minimum_size = Vector2(360, 44)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(x):
		cb.call(x)
		Audio.apply_settings())
	s.drag_ended.connect(func(_c): Settings.save())
	h.add_child(s)
	return h
