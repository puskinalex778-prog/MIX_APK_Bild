extends BaseScreen
## Первый запуск и создание профиля: класс → имя → пол → персонаж → знакомство
## с управлением → тип устройства.

var step = 0
var data = {"grade": 2, "name": "", "gender": "", "avatar": "kid_a", "device": "tablet"}
var adding = false
var _panel: VBoxContainer
var _lumik: CharacterView
var _name_label: Label
var _steps = ["grade", "name", "gender", "avatar", "tutorial", "device"]


func setup(params: Dictionary) -> void:
	adding = bool(params.get("add", false))
	data["device"] = Settings.device
	if adding:
		_steps.erase("device")
	make_layout("sky", 28)
	Audio.music("menu")
	var h = UIKit.hbox(20)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lumik = CharacterView.new("lumik", Vector2(260, 320))
	_lumik.size_flags_vertical = Control.SIZE_SHRINK_END
	h.add_child(_lumik)
	var card = UIKit.panel(Color(1, 0.99, 0.96, 0.96), 30, 28)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel = UIKit.vbox(18)
	card.add_child(UIKit.scroll(_panel))
	h.add_child(card)
	root.add_child(h)
	_show()


func on_back() -> bool:
	if step > 0:
		step -= 1
		_show()
		return true
	if adding:
		return false
	return true


func _clear() -> void:
	for c in _panel.get_children():
		c.queue_free()


func _heading(t: String, sub: String = "") -> void:
	_panel.add_child(UIKit.label(t, 34, UIKit.C_TEXT, "title", HORIZONTAL_ALIGNMENT_CENTER))
	if sub != "":
		_panel.add_child(UIKit.label(sub, 22, UIKit.C_MUTED, "body", HORIZONTAL_ALIGNMENT_CENTER))


func _next() -> void:
	step += 1
	if step >= _steps.size():
		_finish()
	else:
		Audio.sfx("whoosh")
		_show()


func _show() -> void:
	_clear()
	var dots = UIKit.hbox(8)
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in _steps.size():
		dots.add_child(UIKit.nowrap(UIKit.label("●" if i == step else "○", 20, UIKit.C_PRIMARY)))
	_panel.add_child(dots)
	_lumik.set_state("explain", 2.0)
	match _steps[step]:
		"grade":
			_heading("Привет! Давай знакомиться" if not adding else "Новый профиль", "В каком ты классе?")
			var row = UIKit.hbox(20)
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			for g in [2, 3, 4]:
				var b = UIKit.button("%d класс" % g, [Color("4c6ef5"), Color("e8590c"), Color("2f9e44")][g - 2], 34, Vector2(220, 150))
				var gg: int = g
				b.pressed.connect(func():
					data["grade"] = gg
					_next())
				row.add_child(b)
			_panel.add_child(row)
		"name":
			_heading("Как тебя зовут?", "Напиши имя — так тебя будут называть герои игры")
			var fp = UIKit.panel(Color.WHITE, 18, 16)
			fp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			fp.custom_minimum_size = Vector2(420, 80)
			_name_label = UIKit.label(data["name"] if data["name"] != "" else "…", 36, UIKit.C_TEXT, "bold", HORIZONTAL_ALIGNMENT_CENTER)
			fp.add_child(_name_label)
			_panel.add_child(fp)
			_panel.add_child(_name_keyboard())
			var ok = UIKit.button("Готово →", UIKit.C_OK, 28, Vector2(260, 76))
			ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			ok.pressed.connect(func():
				if data["name"].strip_edges() == "":
					UIKit.toast(self, "Напиши своё имя", UIKit.C_BAD)
					return
				_next())
			_panel.add_child(ok)
		"gender":
			_heading("Ты мальчик или девочка?", "Это нужно, чтобы герои правильно к тебе обращались")
			var row2 = UIKit.hbox(30)
			row2.alignment = BoxContainer.ALIGNMENT_CENTER
			for gd in [["boy", "👦 Мальчик", Color("4c6ef5")], ["girl", "👧 Девочка", Color("e64980")]]:
				var b2 = UIKit.button(gd[1], gd[2], 32, Vector2(280, 140))
				var val: String = gd[0]
				b2.pressed.connect(func():
					data["gender"] = val
					data["avatar"] = "kid_a" if val == "boy" else "kid_d"
					_next())
				row2.add_child(b2)
			_panel.add_child(row2)
		"avatar":
			_heading("Выбери своего героя", "Его можно поменять потом")
			var grid = GridContainer.new()
			grid.columns = 3
			grid.add_theme_constant_override("h_separation", 16)
			grid.add_theme_constant_override("v_separation", 16)
			grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			var order = ["kid_a", "kid_b", "kid_c", "kid_d", "kid_e", "kid_f"]
			for av in order:
				var cell = UIKit.panel(Color("dbe4ff") if av == data["avatar"] else Color("f8f9fa"), 22, 8)
				var ch = CharacterView.new(av, Vector2(150, 180))
				var a: String = av
				ch.tapped.connect(func():
					data["avatar"] = a
					Audio.sfx("pop")
					_show())
				if av == data["avatar"]:
					ch.set_state("wave")
				cell.add_child(ch)
				grid.add_child(cell)
			_panel.add_child(grid)
			var ok2 = UIKit.button("Этот! →", UIKit.C_OK, 28, Vector2(260, 76))
			ok2.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			ok2.pressed.connect(_next)
			_panel.add_child(ok2)
		"tutorial":
			_tutorial()
		"device":
			_heading("На чём ты играешь?", "Мы подстроим размер кнопок")
			var row3 = UIKit.hbox(30)
			row3.alignment = BoxContainer.ALIGNMENT_CENTER
			for dv in [["tablet", "📲 Планшет"], ["phone", "📱 Телефон"]]:
				var b3 = UIKit.button(dv[1], UIKit.C_PRIMARY, 32, Vector2(280, 140))
				var val2: String = dv[0]
				b3.pressed.connect(func():
					data["device"] = val2
					_next())
				row3.add_child(b3)
			_panel.add_child(row3)


func _name_keyboard() -> Control:
	var v = UIKit.vbox(6)
	for r in ["йцукенгшщзх", "фывапролджэ", "ячсмитьбюё"]:
		var h = UIKit.hbox(6)
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		for ch in r:
			var key: String = ch
			var b = UIKit.chip_button(key.to_upper() if data["name"] == "" else key, Color("f1f3ff"), UIKit.C_TEXT, 24)
			b.custom_minimum_size = Vector2(56, 60)
			b.pressed.connect(func(): _type(key))
			h.add_child(b)
		v.add_child(h)
	var h2 = UIKit.hbox(8)
	h2.alignment = BoxContainer.ALIGNMENT_CENTER
	var sp = UIKit.chip_button("пробел", Color("f1f3ff"))
	sp.custom_minimum_size = Vector2(240, 60)
	sp.pressed.connect(func(): _type(" "))
	var bs = UIKit.chip_button("⌫", Color("ffe3e3"))
	bs.custom_minimum_size = Vector2(110, 60)
	bs.pressed.connect(func(): _type("⌫"))
	h2.add_child(sp)
	h2.add_child(bs)
	v.add_child(h2)
	return v


func _type(k: String) -> void:
	Audio.sfx("tick")
	var n: String = data["name"]
	if k == "⌫":
		n = n.substr(0, maxi(0, n.length() - 1))
	elif n.length() < 20:
		if n == "" or n.ends_with(" "):
			k = k.to_upper()
		n += k
	data["name"] = n
	_name_label.text = n if n != "" else "…"


func _tutorial() -> void:
	_heading("Как играть", "Лумик покажет, как управлять игрой")
	var tips = [
		["👆", "Нажимай на ответы и кнопки пальцем."],
		["🧩", "В некоторых заданиях нужно нажать карточку, а потом место, куда её положить."],
		["💡", "Если трудно — через 15 секунд нажми на героя-помощника, и он подскажет."],
		["←", "Стрелка «назад» в углу или кнопка «Назад» телефона возвращают на предыдущий экран."],
		["🧘", "Время от времени игра предложит отдохнуть и сделать разминку — это важно для глаз и спины."],
	]
	for t in tips:
		var h = UIKit.hbox(14)
		h.add_child(UIKit.nowrap(UIKit.label(t[0], 34, UIKit.C_TEXT)))
		var l = UIKit.label(t[1], 22)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		_panel.add_child(h)
	_panel.add_child(UIKit.label("Попробуй: сколько будет 2 + 3?", 26, UIKit.C_PRIMARY, "bold", HORIZONTAL_ALIGNMENT_CENTER))
	var demo = TaskView.create({"id": "demo", "type": "choice", "prompt": "2 + 3", "answer": "5", "options": ["5", "4", "6", "23"], "explanation": "", "hint": ""})
	demo.submitted.connect(func(ok: bool, _g: String):
		if ok:
			Audio.sfx("correct")
			_lumik.set_state("happy", 2.0)
			UIKit.toast(self, "Отлично! Так и отвечают на задания.", UIKit.C_OK)
		else:
			Audio.sfx("wrong")
			_lumik.set_state("support", 2.0)
			demo.retry())
	_panel.add_child(demo)
	var ok = UIKit.button("Понятно, дальше →", UIKit.C_OK, 28, Vector2(320, 76))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(_next)
	_panel.add_child(ok)


func _finish() -> void:
	Settings.device = data["device"]
	Settings.onboarding_done = true
	Settings.save()
	Settings.apply_device_scale(get_tree().root)
	Profiles.create_profile(data["name"], data["gender"] if data["gender"] != "" else "boy", data["avatar"], data["grade"])
	Profiles.select(Profiles.current_id())
	Audio.sfx("levelup")
	Router.reset_to("map", {"intro": true})
