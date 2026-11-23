extends BaseScreen
## Мастерская таблицы умножения: исследование (группы, массивы, перестановка множителей,
## связь с делением), программа запоминания по этапам, 8 режимов практики, трудные факты.

var area: VBoxContainer
var view_name = "hub"
var mentor: CharacterView
# исследование
var ex_groups = 3
var ex_items = 4
var ex_as_array = false
var ex_built = 99
var ex_canvas: Control
var ex_info: Label
# тренировка
var tr_tasks: Array = []
var tr_idx = 0
var tr_right = 0
var tr_t0 = 0.0
var tr_tries = 0
var tr_title = ""


func setup(_params: Dictionary) -> void:
	set_meta("learning", true)
	make_layout("calm", 20, 0.0)
	Audio.music("lesson")
	root.add_child(UIKit.top_bar("✖️ Мастерская умножения", Router.back))
	var body = UIKit.hbox(12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mentor = CharacterView.new("robot", Vector2(170, 210))
	mentor.size_flags_vertical = Control.SIZE_SHRINK_END
	body.add_child(mentor)
	var card = UIKit.panel(Color(1, 1, 1, 0.97), 26, 20)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area = UIKit.vbox(14)
	card.add_child(UIKit.scroll(area))
	body.add_child(card)
	root.add_child(body)
	_hub()


func on_back() -> bool:
	if view_name != "hub":
		_hub()
		return true
	return false


func _clear(name: String) -> void:
	view_name = name
	for c in area.get_children():
		c.queue_free()


func _h(t: String, size: int = 30) -> void:
	area.add_child(UIKit.label(t, size, UIKit.C_TEXT, "title", HORIZONTAL_ALIGNMENT_CENTER))


func _p(t: String, size: int = 22, col: Color = UIKit.C_TEXT) -> Label:
	var l = UIKit.label(t, size, col, "body", HORIZONTAL_ALIGNMENT_CENTER)
	area.add_child(l)
	return l


# ---------------- главная ----------------
func _hub() -> void:
	_clear("hub")
	mentor.set_state("wave", 1.5)
	var grade = Profiles.current_grade()
	_h("Таблица умножения")
	_p("Цвет клетки показывает, насколько хорошо ты знаешь факт: серый — ещё не встречался, красный — нужно повторить, жёлтый — запоминается, зелёный — знаешь твёрдо.", 19, UIKit.C_MUTED)
	area.add_child(_heatmap(grade))
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for it in [["🔍 Как устроено умножение", Color("1098ad"), _explorer], ["📅 Программа запоминания", Color("f08c00"), _program],
			["🎯 Практика (8 режимов)", Color("4c6ef5"), _practice_menu], ["🧩 Трудные факты", Color("e8590c"), _hard]]:
		var b = UIKit.button(it[0], it[1], 24, Vector2(0, 84))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(it[2])
		grid.add_child(b)
	area.add_child(grid)
	if grade == 2:
		var tabs = MultTrainer.allowed_tables(grade)
		_p("Во 2 классе доступны таблицы, до которых ты дошёл в учебном маршруте: ×%s." % ", ×".join(PackedStringArray(tabs.map(func(x): return str(x)))), 18, UIKit.C_MUTED)


func _heatmap(grade: int) -> Control:
	var g = GridContainer.new()
	g.columns = 11
	g.add_theme_constant_override("h_separation", 3)
	g.add_theme_constant_override("v_separation", 3)
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for y in range(0, 11):
		for x in range(0, 11):
			var l = Label.new()
			l.custom_minimum_size = Vector2(48, 34)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			l.add_theme_font_size_override("font_size", 15)
			var bgc = Color("e9ecef")
			if y == 0 and x == 0:
				l.text = "×"
				bgc = Color("bac8ff")
			elif y == 0 or x == 0:
				l.text = str(maxi(x, y))
				bgc = Color("bac8ff")
			else:
				l.text = str(x * y)
				var k = MultTrainer.key(x, y)
				if not MultTrainer.fact_allowed(k, grade):
					bgc = Color("f8f9fa")
					l.add_theme_color_override("font_color", Color("ced4da"))
				else:
					var f: Dictionary = MultTrainer.fact(k)
					if int(f["seen"]) == 0:
						bgc = Color("dee2e6")
					elif int(f["box"]) <= 1:
						bgc = Color("ffc9c9")
					elif int(f["box"]) <= 3:
						bgc = Color("ffec99")
					else:
						bgc = Color("b2f2bb")
			var sbx = UIKit.sb(bgc, 6, 0, Color.TRANSPARENT, 0, 2)
			l.add_theme_stylebox_override("normal", sbx)
			g.add_child(l)
	return g


# ---------------- исследование ----------------
func _explorer() -> void:
	_clear("explorer")
	MultTrainer.data()["explored"] = true
	Profiles.save_progress()
	Profiles.award("mult_explorer")
	mentor.set_state("explain", 3.0)
	_h("Как устроено умножение")
	_p("Умножение — это сложение одинаковых групп. Меняй число групп и число предметов в группе.", 21)
	ex_canvas = Control.new()
	ex_canvas.custom_minimum_size = Vector2(700, 300)
	ex_canvas.draw.connect(_draw_explorer)
	area.add_child(ex_canvas)
	ex_info = UIKit.label("", 26, UIKit.C_TEXT, "bold", HORIZONTAL_ALIGNMENT_CENTER)
	area.add_child(ex_info)
	var row = UIKit.hbox(20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(_stepper("Групп", _chg_groups))
	row.add_child(_stepper("В группе", _chg_items))
	area.add_child(row)
	var row2 = UIKit.hbox(12)
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	var step = UIKit.button("▶ Построить по шагам", Color("1098ad"), 20, Vector2(0, 66))
	step.pressed.connect(_build_steps)
	var arr = UIKit.button("▦ Группы ↔ ряды", Color("7048e8"), 20, Vector2(0, 66))
	arr.pressed.connect(func():
		ex_as_array = not ex_as_array
		_upd_ex())
	var swap = UIKit.button("⇄ Поменять множители", Color("f08c00"), 20, Vector2(0, 66))
	swap.pressed.connect(func():
		var t = ex_groups
		ex_groups = ex_items
		ex_items = t
		ex_groups = clampi(ex_groups, 1, 9)
		ex_items = clampi(ex_items, 1, 9)
		_upd_ex()
		UIKit.toast(self, "Предметов столько же! От перестановки множителей произведение не меняется.", UIKit.C_OK, 3.0))
	var div = UIKit.button("➗ А теперь деление", UIKit.C_OK, 20, Vector2(0, 66))
	div.pressed.connect(func():
		var total = ex_groups * ex_items
		UIKit.toast(self, "%d разложили в %d групп(ы) поровну — по %d. Значит %d : %d = %d, а %d : %d = %d." % [total, ex_groups, ex_items, total, ex_groups, ex_items, total, ex_items, ex_groups], UIKit.C_PRIMARY, 5.0))
	for b in [step, arr, swap, div]:
		row2.add_child(b)
	area.add_child(row2)
	ex_built = 99
	_upd_ex()


func _stepper(title: String, cb: Callable) -> Control:
	var h = UIKit.hbox(8)
	h.add_child(UIKit.nowrap(UIKit.label(title, 22, UIKit.C_TEXT, "bold")))
	var m = UIKit.button("−", Color("fa5252"), 30, Vector2(66, 62))
	m.pressed.connect(cb.bind(-1))
	var p = UIKit.button("+", UIKit.C_OK, 30, Vector2(66, 62))
	p.pressed.connect(cb.bind(1))
	h.add_child(m)
	h.add_child(p)
	return h


func _chg_groups(d: int) -> void:
	ex_groups = clampi(ex_groups + d, 1, 9)
	ex_built = 99
	_upd_ex()


func _chg_items(d: int) -> void:
	ex_items = clampi(ex_items + d, 1, 9)
	ex_built = 99
	_upd_ex()


func _upd_ex() -> void:
	var shown = mini(ex_built, ex_groups)
	var parts = PackedStringArray()
	for i in shown:
		parts.append(str(ex_items))
	var sum_txt = " + ".join(parts) if shown > 0 else "0"
	ex_info.text = "%s = %d\n%d · %d = %d   (%d взять %d раз)" % [sum_txt, shown * ex_items, ex_items, shown, shown * ex_items, ex_items, shown]
	ex_canvas.queue_redraw()
	Audio.sfx("pop")


func _build_steps() -> void:
	ex_built = 0
	_upd_ex()
	for i in ex_groups:
		await get_tree().create_timer(0.7 if not Settings.reduce_motion else 0.2).timeout
		if not is_instance_valid(ex_canvas) or view_name != "explorer":
			return
		ex_built = i + 1
		_upd_ex()
	mentor.set_state("happy", 1.5)


func _draw_explorer() -> void:
	var c = ex_canvas
	var emoji = UIKit.font("emoji")
	var shown = mini(ex_built, ex_groups)
	if ex_as_array:
		var cell = minf(c.size.x / 10.0, c.size.y / 9.5)
		var o = Vector2((c.size.x - cell * ex_items) * 0.5, (c.size.y - cell * ex_groups) * 0.5)
		for y in shown:
			c.draw_rect(Rect2(o + Vector2(-6, y * cell + 2), Vector2(cell * ex_items + 12, cell - 4)), Color("fff3bf"))
			for x in ex_items:
				c.draw_string(emoji, o + Vector2(x * cell + cell * 0.1, y * cell + cell * 0.8), "🍎", HORIZONTAL_ALIGNMENT_LEFT, -1, int(cell * 0.7))
		return
	var cols = mini(ex_groups, 5)
	var bw = c.size.x / cols
	var rows = int(ceil(ex_groups / float(cols)))
	var bh = c.size.y / rows
	for i in shown:
		var r = Rect2((i % cols) * bw + 6, (i / cols) * bh + 6, bw - 12, bh - 12)
		c.draw_style_box(UIKit.sb(Color("e7f5ff"), 16, 3, Color("74c0fc")), r)
		var per = 3
		for j in ex_items:
			var p = r.position + Vector2((j % per + 0.5) * r.size.x / per, (j / per + 0.55) * r.size.y / 3.2)
			c.draw_string(emoji, p - Vector2(14, -12), "🍓", HORIZONTAL_ALIGNMENT_LEFT, -1, 28)


# ---------------- программа ----------------
func _program() -> void:
	_clear("program")
	var grade = Profiles.current_grade()
	var cur = MultTrainer.current_stage(grade)
	_h("Программа запоминания")
	_p("Учим таблицу по шагам: сначала лёгкие факты и приёмы, потом трудные. Каждый день — короткая тренировка: повторяем то, что пора повторить, и добавляем 3–4 новых факта. Выучить всё за один день не нужно!", 20, UIKit.C_MUTED)
	var today = UIKit.button("▶ Тренировка дня (12 заданий)", UIKit.C_OK, 26, Vector2(0, 84))
	today.pressed.connect(func(): _start_training(8 if MultTrainer.mastered_facts(grade).size() > 20 else 1, MultTrainer.daily_plan(grade, 12), "Тренировка дня"))
	area.add_child(today)
	for i in MultTrainer.STAGES.size():
		var st: Dictionary = MultTrainer.STAGES[i]
		var avail = MultTrainer.stage_available(i, grade)
		var pct = int(MultTrainer.stage_progress(i) * 100)
		var p = UIKit.panel(Color("ebfbee") if pct >= 80 else (Color("fff9db") if i == cur else Color("f8f9fa")), 18, 14)
		var v = UIKit.vbox(4)
		var head = "%s Шаг %d. %s — %d%%" % ["✅" if pct >= 80 else ("▶" if i == cur else ("🔒" if not avail else "•")), i + 1, st["title"], pct]
		v.add_child(UIKit.label(head, 22, UIKit.C_TEXT, "bold"))
		v.add_child(UIKit.label("Приём: " + st["tip"], 19))
		if avail and i > 0:
			var b = UIKit.button("Тренировать этот шаг", Color("5c7cfa"), 18, Vector2(260, 54))
			var idx = i
			b.pressed.connect(func(): _start_training(1, MultTrainer.stage_facts(idx), st["title"]))
			v.add_child(b)
		elif i == 0:
			var b0 = UIKit.button("Открыть исследование", Color("1098ad"), 18, Vector2(260, 54))
			b0.pressed.connect(_explorer)
			v.add_child(b0)
		elif not avail:
			v.add_child(UIKit.label("Откроется, когда в учебном маршруте ты дойдёшь до этой таблицы.", 17, UIKit.C_MUTED))
		p.add_child(v)
		area.add_child(p)


# ---------------- практика ----------------
func _practice_menu() -> void:
	_clear("practice")
	_h("Практика")
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var grade = Profiles.current_grade()
	for m in MultTrainer.MODES:
		var b = UIKit.button("%d. %s" % [m["id"], m["title"]], Color("4c6ef5"), 22, Vector2(0, 78))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var mid: int = m["id"]
		b.pressed.connect(func(): _start_training(mid, [], m["title"]))
		grid.add_child(b)
	area.add_child(grid)
	_p("В каждой тренировке не меньше 10 заданий. Смешанное повторение берёт уже освоенные факты.", 18, UIKit.C_MUTED)


func _hard() -> void:
	_clear("hard")
	var grade = Profiles.current_grade()
	var hard = MultTrainer.hard_facts(grade, 10)
	_h("Трудные факты")
	if hard.is_empty():
		_p("Пока трудных фактов нет. Потренируйся — и они появятся здесь, если что-то будет получаться не сразу.", 22)
		return
	var flow = UIKit.flow(10)
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	for k in hard:
		var f: Dictionary = MultTrainer.fact(k)
		var ab = MultTrainer.parse_key(k)
		var p = UIKit.panel(Color("fff5f5"), 16, 12)
		p.add_child(UIKit.label("%d × %d = %d\nверно %d · ошибок %d" % [ab[0], ab[1], ab[0] * ab[1], int(f["right"]), int(f["wrong"])], 20, UIKit.C_TEXT, "bold", HORIZONTAL_ALIGNMENT_CENTER))
		flow.add_child(p)
	area.add_child(flow)
	var b = UIKit.button("▶ Повторить трудные факты", Color("e8590c"), 24, Vector2(0, 80))
	b.pressed.connect(func(): _start_training(8, hard, "Трудные факты"))
	area.add_child(b)


# ---------------- тренировка ----------------
func _start_training(mode: int, facts: Array, title: String) -> void:
	var grade = Profiles.current_grade()
	var list = MultTrainer.facts_for_training(grade, mode, 12, facts)
	tr_tasks = []
	for i in list.size():
		tr_tasks.append(MultTrainer.make_task(list[i], mode, i))
	tr_idx = 0
	tr_right = 0
	tr_title = title
	_show_tr()


func _show_tr() -> void:
	_clear("training")
	if tr_idx >= tr_tasks.size():
		_tr_finish()
		return
	var t: Dictionary = tr_tasks[tr_idx]
	tr_tries = 0
	tr_t0 = Time.get_ticks_msec()
	_p("%s · %d / %d" % [tr_title, tr_idx + 1, tr_tasks.size()], 20, UIKit.C_MUTED)
	area.add_child(UIKit.label(str(t["prompt"]), 40, UIKit.C_TEXT, "title", HORIZONTAL_ALIGNMENT_CENTER))
	if t.has("pic"):
		var pv = PicView.new(t["pic"])
		pv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		area.add_child(pv)
	var v = TaskView.create(t)
	v.submitted.connect(func(ok: bool, given: String): _tr_answer(v, ok, given))
	area.add_child(v)
	var hint = UIKit.button("💡 Приём", Color("fab005"), 20, Vector2(180, 58))
	hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hint.pressed.connect(func():
		tr_tries = maxi(tr_tries, 1)
		t["_hint"] = true
		mentor.set_state("explain", 2.0)
		UIKit.toast(self, "💡 " + str(t.get("hint", "")), UIKit.C_TEXT, 4.0))
	area.add_child(hint)


func _tr_answer(v: TaskView, ok: bool, given: String) -> void:
	var t: Dictionary = tr_tasks[tr_idx]
	var ms = Time.get_ticks_msec() - int(tr_t0)
	var first = tr_tries == 0 and not t.get("_hint", false)
	tr_tries += 1
	if ok:
		Audio.sfx("correct")
		mentor.set_state("happy", 1.2)
		MultTrainer.record(str(t["fact"]), first, ms)
		Profiles.record_answer(t, "first" if first else ("hint" if t.get("_hint", false) else "corrected"), given, tr_tries, t.get("_hint", false), "mult")
		if first:
			tr_right += 1
		await get_tree().create_timer(0.7).timeout
		tr_idx += 1
		_show_tr()
	elif tr_tries < 2:
		Audio.sfx("wrong")
		mentor.set_state("support", 1.5)
		UIKit.toast(self, "Попробуй ещё раз. 💡 " + str(t.get("hint", "")), UIKit.C_BAD, 3.0)
		v.retry()
	else:
		Audio.sfx("wrong")
		v.reveal_answer()
		MultTrainer.record(str(t["fact"]), false, ms)
		Profiles.record_answer(t, "failed", given, tr_tries, t.get("_hint", false), "mult")
		var nb = UIKit.button("Понятно → %s" % str(t.get("explanation", "")), UIKit.C_PRIMARY, 20, Vector2(0, 70))
		nb.pressed.connect(func():
			tr_idx += 1
			_show_tr())
		area.add_child(nb)


func _tr_finish() -> void:
	Profiles.save_progress()
	Achievements.check_all()
	mentor.set_state("finish")
	Audio.sfx("levelup")
	_h("Тренировка завершена!", 36)
	_p("С первой попытки: %d из %d" % [tr_right, tr_tasks.size()], 26)
	area.add_child(_heatmap(Profiles.current_grade()))
	var b = UIKit.button("В мастерскую", UIKit.C_OK, 24, Vector2(260, 76))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_hub)
	area.add_child(b)
