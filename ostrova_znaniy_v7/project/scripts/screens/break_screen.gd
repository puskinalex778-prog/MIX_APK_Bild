extends Control
## Перерыв: гимнастика для глаз (следим за звёздочкой), разминка с анимированным
## героем и минута отдыха с закрытыми глазами. Также экран дневного лимита.

var daily_limit = false
var steps = []
var si = -1
var left = 0.0
var hero: CharacterView
var title_lbl: Label
var text_lbl: Label
var timer_lbl: Label
var eye_area: Control
var star_pos = Vector2.ZERO
var caught = 0
var done_btn: Button
var skip_btn: Button
var _elapsed = 0.0
var _pin = ""
var _pin_lbl: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	Wellbeing.set_paused(true)
	Audio.music("break")
	var bg = Scenery.new("calm")
	UIKit.full_rect(bg)
	add_child(bg)
	var dim = ColorRect.new()
	dim.color = Color(0.1, 0.1, 0.25, 0.35)
	UIKit.full_rect(dim)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var v = UIKit.vbox(12)
	var m = UIKit.margin(v, 30, 20, 30, 20)
	UIKit.full_rect(m)
	add_child(m)
	title_lbl = UIKit.title("", 40)
	v.add_child(title_lbl)
	text_lbl = UIKit.label("", 26, Color.WHITE, "bold", HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(text_lbl)
	var mid = UIKit.hbox(10)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero = CharacterView.new(str(Profiles.current().get("avatar", "kid_a")), Vector2(260, 320))
	hero.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_child(hero)
	eye_area = Control.new()
	eye_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eye_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	eye_area.draw.connect(_draw_eyes)
	eye_area.gui_input.connect(_eye_input)
	mid.add_child(eye_area)
	v.add_child(mid)
	timer_lbl = UIKit.label("", 34, Color("ffe066"), "title", HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(timer_lbl)
	var row = UIKit.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	done_btn = UIKit.button("Сделал%s! →" % UIKit.gender_word("", "а"), UIKit.C_OK, 26, Vector2(280, 76))
	done_btn.pressed.connect(_next)
	row.add_child(done_btn)
	skip_btn = UIKit.button("Пропустить разминку", Color("868e96"), 20, Vector2(260, 64))
	skip_btn.pressed.connect(_close)
	skip_btn.visible = false
	row.add_child(skip_btn)
	v.add_child(row)
	if daily_limit:
		_limit_view(v)
		return
	var g = UIKit.gender_word("", "а")
	steps = [
		{"t": "Пора отдохнуть!", "x": "Ты хорошо позанимал%s. Глазам и спине нужен перерыв. Выпрямись и сядь удобно." % ("ся" if g == "" else "ась"), "s": 6, "pose": "wave", "eye": ""},
		{"t": "Глаза: влево-вправо", "x": "Следи за звёздочкой только глазами, голову не поворачивай. Можно ловить её пальцем!", "s": 14, "pose": "idle", "eye": "lr"},
		{"t": "Глаза: вверх-вниз", "x": "Звёздочка летает вверх и вниз. Следи за ней глазами.", "s": 12, "pose": "idle", "eye": "ud"},
		{"t": "Глаза: по кругу", "x": "Теперь звёздочка кружится. Медленно води глазами по кругу.", "s": 12, "pose": "idle", "eye": "circle"},
		{"t": "Поморгай", "x": "Быстро поморгай 10 раз, а потом посмотри вдаль, в окно.", "s": 10, "pose": "happy", "eye": "blink"},
		{"t": "Потянись!", "x": "Встань, подними руки вверх и потянись, как будто достаёшь до облака.", "s": 12, "pose": "happy", "eye": ""},
		{"t": "Наклоны", "x": "Руки на пояс. Наклонись влево, потом вправо. Повтори 4 раза.", "s": 14, "pose": "bend", "eye": ""},
		{"t": "Приседания", "x": "Присядь 5 раз, руки вперёд.", "s": 14, "pose": "squat", "eye": ""},
		{"t": "Плечи", "x": "Покрути плечами вперёд и назад по 4 раза.", "s": 10, "pose": "wave", "eye": ""},
		{"t": "Отдых для глаз", "x": "Закрой глаза ладошками и посиди спокойно. Слушай музыку.", "s": 12, "pose": "think", "eye": "dark"},
	]
	_next()


func _limit_view(v: VBoxContainer) -> void:
	title_lbl.text = "На сегодня достаточно!"
	text_lbl.text = "Ты занимал%s %d минут — это дневная норма. Глазам и голове нужен отдых. Возвращайся завтра!" % ["ся" if UIKit.gender_word("b", "g") == "b" else "ась", int(Profiles.minutes_today())]
	hero.set_state("wave")
	done_btn.text = "Выйти из игры"
	done_btn.pressed.disconnect(_next)
	done_btn.pressed.connect(func(): get_tree().quit())
	var pp = UIKit.panel(Color(1, 1, 1, 0.95), 20, 14)
	var pv = UIKit.vbox(8)
	pv.add_child(UIKit.label("Для родителей: введите PIN, чтобы продлить на 20 минут", 18, UIKit.C_TEXT, "bold", HORIZONTAL_ALIGNMENT_CENTER))
	_pin_lbl = UIKit.label("····", 30, UIKit.C_TEXT, "title", HORIZONTAL_ALIGNMENT_CENTER)
	pv.add_child(_pin_lbl)
	var h = UIKit.hbox(6)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	for d in "1234567890":
		var b = UIKit.chip_button(d, Color("f1f3ff"), UIKit.C_TEXT, 22)
		b.custom_minimum_size = Vector2(52, 52)
		var dd: String = d
		b.pressed.connect(func(): _pin_digit(dd))
		h.add_child(b)
	pv.add_child(h)
	pp.add_child(pv)
	pp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(pp)


func _pin_digit(d: String) -> void:
	if not ParentAuth.has_pin():
		UIKit.toast(self, "PIN ещё не создан. Создайте его в родительском разделе.", UIKit.C_BAD)
		return
	_pin += d
	_pin_lbl.text = "•".repeat(_pin.length()) + "·".repeat(4 - _pin.length())
	if _pin.length() == 4:
		var r = ParentAuth.check_pin(_pin)
		_pin = ""
		_pin_lbl.text = "····"
		if r == "ok":
			ParentAuth.set_setting("daily_limit", Wellbeing.daily_limit_min() + 20)
			Wellbeing.reset_limit_flag()
			_close()
		elif r == "locked":
			UIKit.toast(self, "Слишком много попыток. Подождите %d с." % ParentAuth.lock_seconds_left(), UIKit.C_BAD)
		else:
			UIKit.toast(self, "Неверный PIN", UIKit.C_BAD)


func on_back() -> void:
	pass  # перерыв нельзя закрыть кнопкой «Назад»


func _next() -> void:
	si += 1
	if si >= steps.size():
		Profiles.award("break_taker")
		_close()
		return
	var st: Dictionary = steps[si]
	title_lbl.text = st["t"]
	text_lbl.text = st["x"]
	left = float(st["s"])
	caught = 0
	hero.set_state("idle" if st["pose"] in ["bend", "squat"] else st["pose"])
	hero.rotation = 0.0
	hero.scale = Vector2.ONE
	done_btn.disabled = true
	Audio.sfx("chime")
	eye_area.queue_redraw()


func _process(delta: float) -> void:
	if daily_limit or si < 0 or si >= steps.size():
		return
	_elapsed += delta
	skip_btn.visible = _elapsed > 25.0
	left -= delta
	timer_lbl.text = "%d" % int(ceil(maxf(left, 0.0))) if left > 0.0 else "Готово!"
	if left <= 0.0:
		done_btn.disabled = false
	var st: Dictionary = steps[si]
	var t = _elapsed
	if not Settings.reduce_motion:
		hero.pivot_offset = Vector2(hero.size.x * 0.5, hero.size.y)
		match st["pose"]:
			"bend":
				hero.rotation = sin(t * 2.0) * 0.3
			"squat":
				hero.scale = Vector2(1.0, 1.0 - absf(sin(t * 2.5)) * 0.22)
	var sz = eye_area.size
	var c = sz * 0.5
	match st["eye"]:
		"lr":
			star_pos = c + Vector2(sin(t * 1.4) * sz.x * 0.4, 0)
		"ud":
			star_pos = c + Vector2(0, sin(t * 1.4) * sz.y * 0.38)
		"circle":
			star_pos = c + Vector2(cos(t * 1.3) * sz.x * 0.32, sin(t * 1.3) * sz.y * 0.32)
		_:
			star_pos = Vector2(-100, -100)
	eye_area.queue_redraw()


func _draw_eyes() -> void:
	if si < 0 or si >= steps.size():
		return
	var st: Dictionary = steps[si]
	if st["eye"] == "dark":
		eye_area.draw_rect(Rect2(Vector2.ZERO, eye_area.size), Color(0, 0, 0.1, 0.35))
		return
	if st["eye"] in ["lr", "ud", "circle"]:
		var pts = PackedVector2Array()
		for i in 10:
			var rr = 34.0 if i % 2 == 0 else 15.0
			var ang = -PI / 2 + i * PI / 5 + _elapsed
			pts.append(star_pos + Vector2(cos(ang), sin(ang)) * rr)
		eye_area.draw_circle(star_pos, 48, Color(1, 0.9, 0.3, 0.25))
		eye_area.draw_colored_polygon(pts, Color("ffd43b"))
		eye_area.draw_string(UIKit.font("bold"), Vector2(10, 30), "Поймано: %d" % caught, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)


func _eye_input(ev: InputEvent) -> void:
	var pressed = (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed)
	if pressed and ev.position.distance_to(star_pos) < 60:
		caught += 1
		Audio.sfx("sparkle", 1.0 + caught * 0.05)


func _close() -> void:
	Wellbeing.break_taken()
	Wellbeing.set_paused(false)
	var scr = Router.current_screen()
	if scr and scr.has_meta("learning") and scr.get_meta("learning"):
		Audio.music("lesson")
	else:
		Audio.music("map")
	queue_free()
