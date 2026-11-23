extends BaseScreen
## Родительский кабинет. Вход по PIN (создание с подтверждением, смена, ограничение попыток,
## восстановление по коду). Статистика по каждому ребёнку, журнал ошибок, рекомендации,
## управление темами и профилями, экспорт/импорт профиля, настройки перерывов.

var pid = ""
var grade = 2
var tab = "overview"
var content_box: VBoxContainer
var pin_buf = ""
var pin_first = ""
var pin_mode = "enter"     # enter | create | confirm | recovery | change_old
var pin_label: Label
var pin_msg: Label
var _file_dialog: FileDialog
var _import_payload = {}


func setup(_params: Dictionary) -> void:
	make_layout("night", 24, 0.2)
	Audio.music("menu")
	root.add_child(UIKit.top_bar("👪 Для родителей", Router.back))
	var card = UIKit.panel(Color(1, 1, 1, 0.98), 24, 20)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_box = UIKit.vbox(12)
	card.add_child(content_box)
	root.add_child(card)
	pid = Profiles.current_id()
	if pid == "" and Profiles.has_profiles():
		pid = Profiles.list()[0]["id"]
	grade = int(Profiles.get_profile(pid).get("grade", 2))
	_pin_view("enter" if ParentAuth.has_pin() else "create")


func _clear_box() -> void:
	for c in content_box.get_children():
		c.queue_free()


# ===================== PIN =====================
func _pin_view(m: String) -> void:
	_clear_box()
	pin_mode = m
	pin_buf = ""
	var titles = {"enter": "Введите родительский PIN", "create": "Придумайте PIN из 4 цифр", "confirm": "Повторите PIN",
		"recovery": "Введите код восстановления", "change_old": "Введите текущий PIN"}
	content_box.add_child(UIKit.label(titles[m], 30, UIKit.C_TEXT, "title", HORIZONTAL_ALIGNMENT_CENTER))
	if m == "create":
		content_box.add_child(UIKit.label("PIN защищает родительский раздел от случайного входа ребёнка. Это не шифрование данных.", 18, UIKit.C_MUTED, "body", HORIZONTAL_ALIGNMENT_CENTER))
	pin_label = UIKit.label("", 48, UIKit.C_TEXT, "title", HORIZONTAL_ALIGNMENT_CENTER)
	content_box.add_child(pin_label)
	pin_msg = UIKit.label("", 20, UIKit.C_BAD, "bold", HORIZONTAL_ALIGNMENT_CENTER)
	content_box.add_child(pin_msg)
	if m == "recovery":
		content_box.add_child(_letter_pad())
	else:
		content_box.add_child(_digit_pad())
	if m == "enter":
		var forgot = UIKit.button("Забыли PIN?", Color("868e96"), 20, Vector2(220, 56))
		forgot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		forgot.pressed.connect(func(): _pin_view("recovery"))
		content_box.add_child(forgot)
		var lk = ParentAuth.lock_seconds_left()
		if lk > 0:
			pin_msg.text = "Слишком много неверных попыток. Подождите %d с." % lk
	if m == "recovery":
		content_box.add_child(UIKit.label("Код восстановления показывался один раз при создании PIN (формат XXXX-XXXX). Если код утерян, восстановить доступ можно только очисткой данных приложения в настройках Android — при этом удалится весь прогресс (сначала сделайте экспорт профилей, если это возможно).", 16, UIKit.C_MUTED, "body", HORIZONTAL_ALIGNMENT_CENTER))
	_upd_pin_label()


func _digit_pad() -> Control:
	var g = GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for k in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", "✓"]:
		var b = UIKit.chip_button(k, Color("f1f3ff"), UIKit.C_TEXT, 30)
		b.custom_minimum_size = Vector2(110, 70)
		var kk: String = k
		b.pressed.connect(func(): _pin_key(kk))
		g.add_child(b)
	return g


func _letter_pad() -> Control:
	var v = UIKit.vbox(6)
	for row in ["ABCDEFGHJK", "MNPQRSTUVW", "XYZ234567", "89-"]:
		var h = UIKit.hbox(6)
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		for ch in row:
			var b = UIKit.chip_button(ch, Color("f1f3ff"), UIKit.C_TEXT, 22)
			b.custom_minimum_size = Vector2(56, 56)
			var cc: String = ch
			b.pressed.connect(func(): _pin_key(cc))
			h.add_child(b)
		v.add_child(h)
	var h2 = UIKit.hbox(8)
	h2.alignment = BoxContainer.ALIGNMENT_CENTER
	for k in ["⌫", "✓"]:
		var b2 = UIKit.chip_button(k, Color("ffe3e3") if k == "⌫" else UIKit.C_OK_L, UIKit.C_TEXT, 26)
		b2.custom_minimum_size = Vector2(120, 60)
		var kk: String = k
		b2.pressed.connect(func(): _pin_key(kk))
		h2.add_child(b2)
	v.add_child(h2)
	return v


func _upd_pin_label() -> void:
	if pin_mode == "recovery":
		pin_label.text = pin_buf if pin_buf != "" else "____-____"
	else:
		pin_label.text = "●".repeat(pin_buf.length()) + "○".repeat(4 - pin_buf.length())


func _pin_key(k: String) -> void:
	if k == "⌫":
		pin_buf = pin_buf.substr(0, maxi(0, pin_buf.length() - 1))
	elif k == "✓":
		_pin_submit()
		return
	elif (pin_mode == "recovery" and pin_buf.length() < 9) or pin_buf.length() < 4:
		pin_buf += k
	_upd_pin_label()
	if pin_mode != "recovery" and pin_buf.length() == 4:
		_pin_submit()


func _pin_submit() -> void:
	match pin_mode:
		"enter", "change_old":
			if not ParentAuth.valid_pin_format(pin_buf):
				return
			var r = ParentAuth.check_pin(pin_buf)
			if r == "ok":
				Audio.sfx("unlock")
				if pin_mode == "change_old":
					_pin_view("create")
				else:
					_dashboard()
			elif r == "locked":
				pin_msg.text = "Слишком много неверных попыток. Подождите %d с." % ParentAuth.lock_seconds_left()
				pin_buf = ""
			else:
				pin_msg.text = "Неверный PIN. Осталось попыток: %d" % ParentAuth.tries_left()
				pin_buf = ""
				Audio.sfx("wrong")
		"create":
			if not ParentAuth.valid_pin_format(pin_buf):
				return
			pin_first = pin_buf
			_pin_view("confirm")
		"confirm":
			if pin_buf != pin_first:
				pin_msg.text = "PIN не совпадает. Придумайте заново."
				pin_first = ""
				await get_tree().create_timer(1.2).timeout
				_pin_view("create")
				return
			var code = ParentAuth.set_pin(pin_buf)
			_show_recovery(code)
		"recovery":
			if ParentAuth.check_recovery(pin_buf):
				Audio.sfx("unlock")
				_pin_view("create")
			else:
				pin_msg.text = "Код неверный." if ParentAuth.lock_seconds_left() == 0 else "Слишком много попыток, подождите."
				pin_buf = ""
	_upd_pin_label()


func _show_recovery(code: String) -> void:
	_clear_box()
	content_box.add_child(UIKit.label("PIN сохранён", 32, UIKit.C_OK, "title", HORIZONTAL_ALIGNMENT_CENTER))
	content_box.add_child(UIKit.label("Запишите код восстановления. Он понадобится, если вы забудете PIN. Код показывается только один раз.", 22, UIKit.C_TEXT, "body", HORIZONTAL_ALIGNMENT_CENTER))
	content_box.add_child(UIKit.label(code, 54, UIKit.C_PRIMARY, "title", HORIZONTAL_ALIGNMENT_CENTER))
	var b = UIKit.button("Я записал(а) код →", UIKit.C_OK, 26, Vector2(340, 76))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_dashboard)
	content_box.add_child(b)


# ===================== кабинет =====================
func _dashboard() -> void:
	_clear_box()
	var h = UIKit.hbox(16)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var menu = UIKit.vbox(8)
	menu.custom_minimum_size = Vector2(250, 0)
	if Profiles.has_profiles():
		menu.add_child(UIKit.label("Ребёнок:", 18, UIKit.C_MUTED, "bold"))
		for p in Profiles.list():
			var b = UIKit.button("%s (%d кл.)" % [p["name"], int(p["grade"])], UIKit.C_PRIMARY if p["id"] == pid else Color("adb5bd"), 19, Vector2(0, 54))
			var id: String = p["id"]
			b.pressed.connect(func():
				pid = id
				grade = int(Profiles.get_profile(id)["grade"])
				_dashboard())
			menu.add_child(b)
	menu.add_child(HSeparator.new())
	for t in [["overview", "📊 Обзор"], ["topics", "📚 Темы"], ["errors", "❗ Ошибки"], ["history", "🕒 История"], ["skills", "🎯 Навыки и советы"],
			["profiles", "👤 Профили"], ["io", "💾 Экспорт / импорт"], ["settings", "⚙️ Настройки"]]:
		var tb = UIKit.button(t[1], Color("495057") if tab != t[0] else Color("7048e8"), 19, Vector2(0, 54))
		var key: String = t[0]
		tb.pressed.connect(func():
			tab = key
			_dashboard())
		menu.add_child(tb)
	h.add_child(UIKit.scroll(menu))
	menu.get_parent().custom_minimum_size = Vector2(260, 0)
	menu.get_parent().size_flags_horizontal = Control.SIZE_FILL
	var page = UIKit.vbox(12)
	var sc = UIKit.scroll(page)
	sc.size_flags_stretch_ratio = 3.0
	h.add_child(sc)
	content_box.add_child(h)
	if pid == "" and tab not in ["profiles", "io", "settings"]:
		page.add_child(UIKit.label("Профилей пока нет. Создайте профиль ребёнка во вкладке «Профили» или на экране выбора.", 22))
		return
	match tab:
		"overview":
			_overview(page)
		"topics":
			_topics(page)
		"errors":
			_errors(page)
		"history":
			_history(page)
		"skills":
			_skills(page)
		"profiles":
			_profiles(page)
		"io":
			_io(page)
		"settings":
			_settings(page)


func _h(page: Control, t: String) -> void:
	page.add_child(UIKit.label(t, 28, UIKit.C_TEXT, "title"))


func _row(page: Control, cols: Array, bold: bool = false, bgc: Color = Color.TRANSPARENT) -> void:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.sb(bgc, 8, 0, Color.TRANSPARENT, 0, 8))
	var h = UIKit.hbox(8)
	for c in cols:
		var l = UIKit.label(str(c[0]), 17, UIKit.C_TEXT, "bold" if bold else "body")
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.size_flags_stretch_ratio = float(c[1])
		h.add_child(l)
	p.add_child(h)
	page.add_child(p)


func _pct(v: int) -> String:
	return "—" if v < 0 else "%d%%" % v


func _overview(page: VBoxContainer) -> void:
	var p = Profiles.get_profile(pid)
	_h(page, "Обзор: %s, %d класс" % [p["name"], grade])
	var prog = Profiles.progress(pid)
	var mins = 0.0
	for d in prog["daily"]:
		mins += float(prog["daily"][d])
	page.add_child(UIKit.label("Всего занятий: %d · Времени в игре: %d мин · Сегодня: %d мин · Звёзд: %d · Достижений: %d" % [prog["sessions"].size(), int(mins), int(float(prog["daily"].get(Time.get_date_string_from_system(), 0.0))), int(prog.get("stars", 0)), prog["achievements"].size()], 19))
	page.add_child(UIKit.label("Точность первых ответов считается только по первому знакомству с заданием. Исправления, подсказки и повторные тренировки показаны отдельно и точность не завышают. Небольшое число ответов — это не диагностика способностей.", 16, UIKit.C_MUTED))
	_row(page, [["Предмет", 3], ["Темы: пройдено / начато / всего", 3], ["Точность 1-х ответов", 2], ["Исправлено после ошибки", 2], ["С подсказкой", 2], ["Не решено", 1.5], ["Повторение: верно", 2]], true, Color("e7f5ff"))
	for s in ParentStats.subject_overview(pid, grade):
		_row(page, [[Content.SUBJECT_TITLES[s["subject"]], 3], ["%d / %d / %d" % [s["done"], s["started"], s["topics"]], 3], [_pct(s["accuracy"]) + " (%d)" % s["first_seen"], 2],
			[s["corrected"], 2], [s["hint"], 2], [s["failed"], 1.5], ["%d из %d" % [s["review_ok"], s["review_total"]], 2]])
	var mf = 0
	for k in prog["mult"].get("facts", {}):
		if int(prog["mult"]["facts"][k]["box"]) >= 2:
			mf += 1
	page.add_child(UIKit.label("Таблица умножения: освоено фактов — %d (по коробкам интервального повторения)." % mf, 19))


func _topics(page: VBoxContainer) -> void:
	_h(page, "Темы и результаты")
	page.add_child(UIKit.label("«Открыть» — дать доступ к теме не по порядку. «Повторить» — назначить ребёнку задания темы.", 16, UIKit.C_MUTED))
	for s in Content.SUBJECTS:
		page.add_child(UIKit.label(Content.SUBJECT_TITLES[s], 24, UIKit.SUBJECT_COLORS[s], "bold"))
		_row(page, [["Тема", 5], ["Статус", 2], ["Точн.", 1.2], ["Ответов", 1.2], ["Подсказок", 1.3], ["Занятий", 1.2], ["", 2.5]], true, Color("f1f3f5"))
		for r in ParentStats.topic_rows(pid, grade, s):
			var p = PanelContainer.new()
			p.add_theme_stylebox_override("panel", UIKit.sb(Color.TRANSPARENT, 6, 0, Color.TRANSPARENT, 0, 6))
			var h = UIKit.hbox(8)
			var status: String = {"new": "не начата", "started": "начата", "done": "пройдена ★%d" % int(r["stars"])}.get(r["status"], r["status"])
			if not r["open"]:
				status = "🔒 закрыта"
			for c in [[r["title"], 5], [status, 2], [_pct(r["accuracy"]), 1.2], [r["answers"], 1.2], [r["hints_used"], 1.3], [r["sessions"], 1.2]]:
				var l = UIKit.label(str(c[0]), 16)
				l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				l.size_flags_stretch_ratio = float(c[1])
				h.add_child(l)
			var act = UIKit.hbox(4)
			act.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			act.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			act.size_flags_stretch_ratio = 2.5
			var tid: String = r["id"]
			if not r["open"]:
				var ob = UIKit.button("Открыть", Color("f08c00"), 15, Vector2(0, 44))
				ob.pressed.connect(func():
					Profiles.unlock_by_parent(tid, pid)
					UIKit.toast(self, "Тема открыта", UIKit.C_OK)
					_dashboard())
				act.add_child(ob)
			var rb = UIKit.button("Повторить", Color("1098ad"), 15, Vector2(0, 44))
			rb.pressed.connect(func(): _assign_topic(tid))
			act.add_child(rb)
			h.add_child(act)
			p.add_child(h)
			page.add_child(p)


func _assign_topic(tid: String) -> void:
	var ids = []
	var errs: Dictionary = Profiles.progress(pid)["errors"]
	var tasks: Array = Content.tasks(tid)
	for t in tasks:
		if errs.has(t["id"]) and errs[t["id"]]["status"] != "fixed":
			ids.append(t["id"])
	for t in TaskView.shuffled(tasks):
		if ids.size() >= 10:
			break
		if not ids.has(t["id"]):
			ids.append(t["id"])
	Profiles.unlock_by_parent(tid, pid)
	Profiles.progress(pid)["assigned"] = ids
	Profiles.save_progress(pid)
	UIKit.toast(self, "Назначено %d заданий. Ребёнок увидит кнопку «Работа над ошибками» на карте." % ids.size(), UIKit.C_OK, 3.5)


func _errors(page: VBoxContainer) -> void:
	_h(page, "Журнал ошибок")
	var errs: Dictionary = Profiles.progress(pid)["errors"]
	var list = []
	for tid in errs:
		if int(errs[tid].get("g", 0)) == grade:
			list.append([tid, errs[tid]])
	list.sort_custom(func(a, b): return int(a[1]["last_ts"]) > int(b[1]["last_ts"]))
	page.add_child(UIKit.label("Записей: %d. Сюда попадают задания, решённые не с первой попытки, после подсказки или не решённые. Статус «исправлено» ставится после двух верных повторений." % list.size(), 16, UIKit.C_MUTED))
	var sel_row = UIKit.hbox(10)
	var pick_btn = UIKit.button("Назначить 10 самых трудных", Color("e8590c"), 18, Vector2(0, 56))
	pick_btn.pressed.connect(func():
		var ids = []
		for e in list:
			if e[1]["status"] != "fixed" and e[1]["topic"] != "mult":
				ids.append(e[0])
			if ids.size() >= 10:
				break
		Profiles.progress(pid)["assigned"] = ids
		Profiles.save_progress(pid)
		UIKit.toast(self, "Назначено заданий: %d" % ids.size(), UIKit.C_OK))
	sel_row.add_child(pick_btn)
	page.add_child(sel_row)
	var kinds = {"corrected": "исправил(а) сам(а)", "hint": "решил(а) с подсказкой", "failed": "не решил(а)"}
	var stat = {"open": "не исправлено", "improving": "исправляется", "fixed": "исправлено ✅"}
	for e in list.slice(0, 150):
		var d: Dictionary = e[1]
		var p = UIKit.panel(Color("fff5f5") if d["status"] == "open" else (Color("fff9db") if d["status"] == "improving" else Color("ebfbee")), 14, 12)
		var v = UIKit.vbox(2)
		var tinfo = Content.topic_info(str(d["topic"]))
		var subj = Content.SUBJECT_TITLES.get(str(d.get("subj", "")), "Таблица умножения")
		v.add_child(UIKit.label("%s · %s" % [subj, tinfo.get("title", "Мастерская умножения")], 16, UIKit.C_MUTED, "bold"))
		v.add_child(UIKit.label("Условие: " + str(d["prompt"]), 18))
		v.add_child(UIKit.label("Ответ ребёнка: %s   →   Правильно: %s" % [d["given"], d["correct"]], 18, UIKit.C_TEXT, "bold"))
		v.add_child(UIKit.label("Объяснение: " + str(d["explanation"]), 16))
		v.add_child(UIKit.label("Первый раз: %s · Последний: %s · Ошибок: %d · Повторений: %d · Первый итог: %s · Статус: %s" % [ParentStats.fmt_time(int(d["first_ts"])), ParentStats.fmt_time(int(d["last_ts"])), int(d["count"]), int(d["repeats"]), kinds.get(d.get("kind", ""), "—"), stat.get(d["status"], d["status"])], 15, UIKit.C_MUTED))
		p.add_child(v)
		page.add_child(p)


func _history(page: VBoxContainer) -> void:
	_h(page, "История занятий")
	var ses: Array = Profiles.progress(pid)["sessions"].duplicate()
	ses.reverse()
	_row(page, [["Когда", 2.2], ["Что", 4], ["Режим", 1.6], ["Заданий", 1.2], ["С 1-й попытки", 1.6], ["Решено", 1.2], ["Мин", 1]], true, Color("e7f5ff"))
	var modes = {"lesson": "тема", "story": "сюжет", "review": "ошибки", "assigned": "от родителя"}
	for s in ses.slice(0, 120):
		var title: String = Content.topic_info(str(s["topic"])).get("title", "Работа над ошибками")
		_row(page, [[ParentStats.fmt_time(int(s["ts"])), 2.2], [title, 4], [modes.get(s.get("mode", ""), s.get("mode", "")), 1.6], [s["total"], 1.2], [s["first"], 1.6], [s["solved"], 1.2], [s["min"], 1]])
	if ses.is_empty():
		page.add_child(UIKit.label("Занятий пока не было.", 20))


func _skills(page: VBoxContainer) -> void:
	_h(page, "Трудные темы и рекомендации")
	var diff = ParentStats.difficult(pid, grade)
	if diff.is_empty():
		page.add_child(UIKit.label("Трудных тем не найдено (нужно хотя бы 5 первых ответов по теме, чтобы делать выводы).", 19))
	for r in diff.slice(0, 12):
		var p = UIKit.panel(Color("fff4e6"), 14, 12)
		var v = UIKit.vbox(6)
		v.add_child(UIKit.label(ParentStats.recommendation(r), 18))
		var h = UIKit.hbox(8)
		var tid: String = r["id"]
		var b = UIKit.button("Назначить повторение темы", Color("1098ad"), 16, Vector2(0, 48))
		b.pressed.connect(func(): _assign_topic(tid))
		h.add_child(b)
		v.add_child(h)
		p.add_child(v)
		page.add_child(p)
	_h(page, "Освоенные темы")
	var m = ParentStats.mastered(pid, grade)
	if m.is_empty():
		page.add_child(UIKit.label("Пока нет тем с устойчивым результатом (пройдена, ≥ 8 первых ответов, точность ≥ 85%).", 18))
	for r in m:
		page.add_child(UIKit.label("✅ %s — %s, точность %d%%" % [Content.SUBJECT_TITLES[r["subject"]], r["title"], r["accuracy"]], 18))
	_h(page, "Таблица умножения: трудные факты")
	var cur = Profiles.current_id()
	if cur == pid:
		var hard = MultTrainer.hard_facts(grade, 8)
		page.add_child(UIKit.label(", ".join(PackedStringArray(hard.map(func(k): return str(k).replace("×", " × ")))) if hard.size() > 0 else "Нет данных.", 19))
	else:
		page.add_child(UIKit.label("Выберите этого ребёнка на экране профилей, чтобы увидеть трудные факты таблицы.", 17, UIKit.C_MUTED))


func _profiles(page: VBoxContainer) -> void:
	_h(page, "Профили детей")
	for p in Profiles.list():
		var row = UIKit.hbox(8)
		var nl = UIKit.label("%s · %d класс · %s" % [p["name"], int(p["grade"]), "девочка" if p["gender"] == "girl" else "мальчик"], 20)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nl)
		var id: String = p["id"]
		for g in [2, 3, 4]:
			var gb = UIKit.button("%d кл." % g, UIKit.C_PRIMARY if int(p["grade"]) == g else Color("adb5bd"), 16, Vector2(80, 48))
			var gg: int = g
			gb.pressed.connect(func():
				Profiles.update_profile(id, {"grade": gg})
				if id == pid:
					grade = gg
				UIKit.toast(self, "Класс изменён. Прогресс каждого класса хранится отдельно.", UIKit.C_OK, 3.0)
				_dashboard())
			row.add_child(gb)
		var ren = UIKit.button("Имя", Color("1098ad"), 16, Vector2(80, 48))
		ren.pressed.connect(func(): _rename(id))
		row.add_child(ren)
		var del = UIKit.button("Удалить", Color("fa5252"), 16, Vector2(100, 48))
		del.pressed.connect(func(): confirm("Удалить профиль «%s» и весь его прогресс? Это нельзя отменить." % p["name"], "Удалить", func():
			Profiles.delete_profile(id)
			pid = Profiles.current_id()
			_dashboard()))
		row.add_child(del)
		page.add_child(row)
	var add = UIKit.button("➕ Добавить профиль", Color("7048e8"), 20, Vector2(300, 60))
	add.pressed.connect(func(): Router.go("welcome", {"add": true}))
	page.add_child(add)


func _rename(id: String) -> void:
	var ov = ColorRect.new()
	ov.color = Color(0, 0, 0, 0.5)
	var c = CenterContainer.new()
	UIKit.full_rect(c)
	ov.add_child(c)
	var p = UIKit.panel(UIKit.C_PANEL, 22, 22)
	var v = UIKit.vbox(10)
	v.add_child(UIKit.label("Новое имя", 26, UIKit.C_TEXT, "title"))
	var le = LineEdit.new()
	le.text = Profiles.get_profile(id).get("name", "")
	le.max_length = 24
	le.custom_minimum_size = Vector2(420, 64)
	v.add_child(le)
	var ok = UIKit.button("Сохранить", UIKit.C_OK, 22, Vector2(220, 60))
	ok.pressed.connect(func():
		Profiles.update_profile(id, {"name": le.text})
		ov.queue_free()
		_dashboard())
	v.add_child(ok)
	p.add_child(v)
	c.add_child(p)
	Router.overlay(ov)


func _settings(page: VBoxContainer) -> void:
	_h(page, "Перерывы и время")
	page.add_child(UIKit.label("По умолчанию — нормы СанПиН 1.2.3685-21: перерыв каждые 10 мин (2 класс) / 15 мин (3–4 классы), до 40 / 50 мин в день.", 16, UIKit.C_MUTED))
	var cb = CheckButton.new()
	cb.text = "Предлагать перерывы с разминкой"
	cb.button_pressed = Wellbeing.breaks_enabled()
	cb.toggled.connect(func(b): ParentAuth.set_setting("breaks_enabled", b))
	page.add_child(cb)
	page.add_child(_num_setting("Перерыв каждые, мин", "break_interval", Wellbeing.interval_min(), 5, 30, 5))
	page.add_child(_num_setting("Дневной лимит, мин (0 — без лимита)", "daily_limit", Wellbeing.daily_limit_min(), 0, 180, 10))
	_h(page, "Безопасность")
	var chg = UIKit.button("Сменить PIN", Color("495057"), 20, Vector2(240, 60))
	chg.pressed.connect(func(): _pin_view("change_old"))
	page.add_child(chg)


func _num_setting(title: String, key: String, val: int, lo: int, hi: int, step: int) -> Control:
	var h = UIKit.hbox(10)
	var tl = UIKit.label(title, 20)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tl)
	var lbl = UIKit.nowrap(UIKit.label(str(val), 26, UIKit.C_TEXT, "bold"))
	lbl.custom_minimum_size = Vector2(60, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var m = UIKit.button("−", Color("fa5252"), 24, Vector2(60, 54))
	var p = UIKit.button("+", UIKit.C_OK, 24, Vector2(60, 54))
	m.pressed.connect(func():
		var v = clampi(int(lbl.text) - step, lo, hi)
		lbl.text = str(v)
		ParentAuth.set_setting(key, v))
	p.pressed.connect(func():
		var v = clampi(int(lbl.text) + step, lo, hi)
		lbl.text = str(v)
		ParentAuth.set_setting(key, v))
	h.add_child(m)
	h.add_child(lbl)
	h.add_child(p)
	return h


# ===================== экспорт / импорт =====================
func _io(page: VBoxContainer) -> void:
	_h(page, "Экспорт профиля")
	page.add_child(UIKit.label("⚠️ Файл не зашифрован: в нём имя ребёнка и история обучения. Родительский PIN в файл не попадает. Храните файл в надёжном месте.", 17, UIKit.C_BAD))
	if pid != "":
		var name = str(Profiles.get_profile(pid).get("name", ""))
		var ex = UIKit.button("💾 Сохранить файл профиля «%s»" % name, UIKit.C_PRIMARY, 20, Vector2(0, 60))
		ex.pressed.connect(_export_file)
		page.add_child(ex)
		var cp = UIKit.button("📋 Скопировать профиль как текстовый код (запасной способ)", Color("1098ad"), 18, Vector2(0, 56))
		cp.pressed.connect(func():
			DisplayServer.clipboard_set(ProfileIO.to_clipboard_code(pid))
			UIKit.toast(self, "Код скопирован. Вставьте его в мессенджер или заметки, чтобы перенести.", UIKit.C_OK, 3.5))
		page.add_child(cp)
	_h(page, "Импорт профиля")
	page.add_child(UIKit.label("Импорт добавит профиль или заменит профиль с тем же идентификатором (после подтверждения). Другие профили не изменятся. Повреждённый файл ничего не меняет.", 17, UIKit.C_MUTED))
	var im = UIKit.button("📂 Выбрать файл профиля", UIKit.C_OK, 20, Vector2(0, 60))
	im.pressed.connect(_import_file)
	page.add_child(im)
	var pc = UIKit.button("📋 Вставить текстовый код из буфера обмена", Color("1098ad"), 18, Vector2(0, 56))
	pc.pressed.connect(func(): _preview_import(ProfileIO.from_clipboard_code(DisplayServer.clipboard_get())))
	page.add_child(pc)


func _export_file() -> void:
	var text = ProfileIO.export_text(pid)
	var fname = ProfileIO.file_name_for(Profiles.get_profile(pid))
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		DisplayServer.file_dialog_show("Сохранить профиль", OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS), fname, false,
			DisplayServer.FILE_DIALOG_MODE_SAVE_FILE, PackedStringArray(["*.json ; Профиль"]),
			func(status: bool, paths: PackedStringArray, _f: int):
				if not status or paths.is_empty():
					UIKit.toast(self, "Сохранение отменено", UIKit.C_TEXT)
					return
				if ProfileIO.write_file(paths[0], text):
					UIKit.toast(self, "Файл сохранён", UIKit.C_OK)
				else:
					_export_fallback(text, fname))
	else:
		_export_fallback(text, fname)


func _export_fallback(text: String, fname: String) -> void:
	var saved = []
	for dir in [OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS), OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS), "user://exports"]:
		if dir == "":
			continue
		if dir.begins_with("user://") and not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
		var p: String = dir.path_join(fname)
		if ProfileIO.write_file(p, text):
			saved.append(ProjectSettings.globalize_path(p))
			break
	if saved.size() > 0:
		UIKit.toast(self, "Файл сохранён: " + saved[0], UIKit.C_OK, 5.0)
	else:
		DisplayServer.clipboard_set(ProfileIO.to_clipboard_code(pid))
		UIKit.toast(self, "Не удалось записать файл. Профиль скопирован в буфер обмена как текстовый код.", UIKit.C_BAD, 5.0)


func _import_file() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		DisplayServer.file_dialog_show("Открыть профиль", OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS), "", false,
			DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, PackedStringArray(["*.json ; Профиль"]),
			func(status: bool, paths: PackedStringArray, _f: int):
				if not status or paths.is_empty():
					UIKit.toast(self, "Импорт отменён", UIKit.C_TEXT)
					return
				_read_and_preview(paths[0]))
		return
	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.filters = PackedStringArray(["*.json ; Профиль"])
	_file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	_file_dialog.size = Vector2i(900, 600)
	_file_dialog.file_selected.connect(_read_and_preview)
	_file_dialog.canceled.connect(func(): UIKit.toast(self, "Импорт отменён", UIKit.C_TEXT))
	add_child(_file_dialog)
	_file_dialog.popup_centered()


func _read_and_preview(path: String) -> void:
	var r = ProfileIO.read_file(path)
	if not r["ok"]:
		UIKit.toast(self, r["error"], UIKit.C_BAD, 4.0)
		return
	_preview_import(ProfileIO.parse(r["text"]))


func _preview_import(res: Dictionary) -> void:
	if not res.get("ok", false):
		Audio.sfx("wrong")
		UIKit.toast(self, "Импорт невозможен: " + str(res.get("error", "")), UIKit.C_BAD, 5.0)
		return
	_import_payload = res["payload"]
	var pv: Dictionary = res["preview"]
	var txt = "Профиль: %s, %d класс\nПройдено тем: %d · Ответов: %d · Звёзд: %d" % [pv["name"], pv["grade"], pv["topics_done"], pv["answers"], pv["stars"]]
	if pv["exists"]:
		confirm(txt + "\n\nТакой профиль уже есть на устройстве. Заменить его данными из файла? (Можно отменить и импортировать как копию.)", "Заменить", func(): _do_import("replace"), "Как копию")
		await get_tree().process_frame
		# кнопка «Как копию» закрывает окно; сразу предложим копию отдельной кнопкой на странице
		tab = "io"
	else:
		confirm(txt + "\n\nДобавить этот профиль?", "Добавить", func(): _do_import("copy"))
	_copy_option(pv)


func _copy_option(pv: Dictionary) -> void:
	if not pv["exists"]:
		return
	await get_tree().create_timer(0.1).timeout
	var b = UIKit.button("Импортировать «%s» как отдельный новый профиль" % pv["name"], Color("7048e8"), 18, Vector2(0, 56))
	b.pressed.connect(func(): _do_import("copy"))
	content_box.add_child(b)


func _do_import(mode: String) -> void:
	var id = ProfileIO.apply(_import_payload, mode)
	Audio.sfx("levelup")
	UIKit.toast(self, "Профиль импортирован", UIKit.C_OK)
	pid = id
	grade = int(Profiles.get_profile(id).get("grade", 2))
	_dashboard()
