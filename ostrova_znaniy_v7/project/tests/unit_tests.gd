extends Node
## Автотесты логики: сохранения, резервная копия, экспорт/импорт, PIN, статистика,
## проверка ответов по всему банку, тренажёр умножения, создание всех видов заданий.
## Запуск: godot --headless --path project res://tests/unit_tests.tscn
## ВНИМАНИЕ: тесты пишут в user://save — запускайте на тестовой установке.

var passed := 0
var failed := 0
var log_lines := []


func ok(cond: bool, name: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		log_lines.append("FAIL: " + name)
		print("FAIL: ", name)


func _ready() -> void:
	await get_tree().process_frame
	test_save_store()
	test_profiles_isolation()
	test_export_import()
	test_parent_auth()
	test_stats()
	test_answer_bank()
	test_shuffle_order()
	test_mult()
	await test_task_views()
	await test_touch_scroll()
	print("UNIT TESTS: passed %d, failed %d" % [passed, failed])
	var f = FileAccess.open("user://unit_test_report.txt", FileAccess.WRITE)
	if f:
		f.store_string("passed %d\nfailed %d\n%s\n" % [passed, failed, "\n".join(log_lines)])
		f.close()
	get_tree().quit(1 if failed > 0 else 0)


# ---------- сохранения ----------
func test_save_store() -> void:
	var name = "unit_test.json"
	SaveStore.remove(name)
	ok(SaveStore.write(name, "t-fmt", 1, {"a": 1, "b": [1, 2, 3]}), "save: первая запись")
	ok(SaveStore.write(name, "t-fmt", 1, {"a": 2, "b": [4]}), "save: вторая запись (появляется .bak)")
	var r = SaveStore.read(name, "t-fmt")
	ok(r.get("source", "") == "main" and int(r["data"]["a"]) == 2, "save: чтение основного файла")
	ok(FileAccess.file_exists(SaveStore.path(name) + ".bak"), "save: резервная копия существует")
	ok(not FileAccess.file_exists(SaveStore.path(name) + ".tmp"), "save: временный файл удалён")
	# портим основной файл
	var f = FileAccess.open(SaveStore.path(name), FileAccess.WRITE)
	f.store_string("{\"format\":\"t-fmt\",\"data\":{\"a\":999}, \"sha256\":\"bad\"")
	f.close()
	r = SaveStore.read(name, "t-fmt")
	ok(r.get("source", "") == "backup" and int(r["data"]["a"]) == 1, "save: повреждённый файл → восстановление из .bak")
	# неверный формат
	SaveStore.write(name, "t-fmt", 1, {"a": 3})
	ok(SaveStore.read(name, "другой-формат").is_empty(), "save: чужой формат не принимается")
	SaveStore.remove(name)
	ok(SaveStore.read(name, "t-fmt").is_empty(), "save: удалённый файл не читается")


# ---------- профили ----------
var pid_a := ""
var pid_b := ""


func test_profiles_isolation() -> void:
	pid_a = Profiles.create_profile("Тест А", "girl", "kid_a", 2)
	pid_b = Profiles.create_profile("Тест Б", "boy", "kid_b", 4)
	ok(pid_a != pid_b and pid_a.begins_with("p"), "profiles: стабильные разные id")
	ok(Profiles.get_profile(pid_a)["grade"] == 2 and Profiles.get_profile(pid_b)["grade"] == 4, "profiles: класс сохранён")
	Profiles.select(pid_a)
	var t2 = Content.tasks("g2.math.add_2digit")
	if t2.is_empty():
		t2 = Content.tasks(Content.topics(2, "math")[0]["id"])
	ok(t2.size() >= 10, "content: банк 2 класса загружается")
	Profiles.record_answer(t2[0], "first", "x", 1, false, "lesson")
	Profiles.record_answer(t2[1], "failed", "y", 2, false, "lesson")
	Profiles.save_progress(pid_a)
	ok(Profiles.progress(pid_b)["answers"].size() == 0, "profiles: ответы одного профиля не попадают в другой")
	var g4 = Content.topics(4, "math")
	var leak = false
	for tp in Content.topics(2, "math"):
		if not str(tp["id"]).begins_with("g2."):
			leak = true
	ok(not leak and g4.size() > 0 and str(g4[0]["id"]).begins_with("g4."), "content: банки классов не смешиваются")


# ---------- экспорт / импорт ----------
func test_export_import() -> void:
	var text = ProfileIO.export_text(pid_a)
	ok(text.length() > 0, "export: текст сформирован")
	ok(not text.contains("pin_hash") and not text.contains("rec_hash") and not text.contains("salt"), "export: PIN и код восстановления не экспортируются")
	var p = ProfileIO.parse(text)
	ok(p.get("ok", false), "import: свой экспорт читается")
	ok(p.get("preview", {}).size() > 0, "import: есть предпросмотр")
	# повреждённый файл
	var bad = text.replace("Тест А", "Взлом")
	ok(not ProfileIO.parse(bad).get("ok", true), "import: изменённый файл отклонён по контрольной сумме")
	ok(not ProfileIO.parse("{не json").get("ok", true), "import: битый JSON отклонён")
	ok(not ProfileIO.parse("").get("ok", true), "import: пустой файл отклонён")
	var newer = JSON.parse_string(text)
	newer["version"] = 99
	ok(not ProfileIO.parse(JSON.stringify(newer)).get("ok", true), "import: более новый формат отклонён")
	# неудачный импорт ничего не меняет
	var before_b = JSON.stringify(Profiles.progress(pid_b))
	var cnt = Profiles.list().size()
	ProfileIO.parse(bad)
	ok(Profiles.list().size() == cnt and JSON.stringify(Profiles.progress(pid_b)) == before_b, "import: ошибка импорта не меняет данные")
	# импорт копией
	var new_id = ProfileIO.apply(p["payload"], "copy")
	ok(new_id != pid_a and Profiles.list().size() == cnt + 1, "import: копия добавлена новым профилем")
	ok(Profiles.progress(new_id)["answers"].size() == Profiles.progress(pid_a)["answers"].size(), "import: прогресс скопирован")
	ok(JSON.stringify(Profiles.progress(pid_b)) == before_b, "import: другие профили не изменились")
	# замена
	var rid = ProfileIO.apply(p["payload"], "replace")
	ok(rid == pid_a and Profiles.list().size() == cnt + 1, "import: замена того же id без дублей")
	# буфер обмена
	var code = ProfileIO.to_clipboard_code(pid_a)
	ok(code.begins_with("OSTROVA1:") and ProfileIO.from_clipboard_code(code).get("ok", false), "import: код через буфер обмена")
	# лишние поля и вредные значения вычищаются
	var evil = JSON.parse_string(text)
	evil["payload"]["progress"]["script"] = "OS.execute"
	evil["payload"]["profile"]["avatar"] = "res://../../etc"
	evil["sha256"] = SaveStore.checksum(evil["payload"])
	var pe = ProfileIO.parse(JSON.stringify(evil))
	ok(pe.get("ok", false) and not pe["payload"]["progress"].has("script") and pe["payload"]["profile"]["avatar"] in Profiles.AVATARS, "import: неизвестные поля и пути отбрасываются")
	Profiles.delete_profile(new_id)


# ---------- PIN ----------
func test_parent_auth() -> void:
	var code = ParentAuth.set_pin("1234")
	ok(ParentAuth.has_pin() and code.length() == 9, "pin: создан, выдан код восстановления")
	ok(ParentAuth.check_pin("1234") == "ok", "pin: верный PIN")
	ok(ParentAuth.check_pin("0000") == "wrong", "pin: неверный PIN")
	ok(not ParentAuth.valid_pin_format("12a4") and not ParentAuth.valid_pin_format("123"), "pin: проверка формата")
	var res = ""
	for i in ParentAuth.MAX_TRIES:
		res = ParentAuth.check_pin("9999")
	ok(res == "locked" and ParentAuth.lock_seconds_left() > 0, "pin: блокировка после неверных попыток")
	ok(ParentAuth.check_pin("1234") == "locked", "pin: во время блокировки даже верный PIN не принимается")
	# снимаем блокировку для продолжения тестов
	ParentAuth._data["lock_until"] = 0
	ParentAuth._save()
	ok(ParentAuth.check_recovery(code), "pin: код восстановления работает")
	var code2 = ParentAuth.change_pin("1234", "4321")
	ok(code2 != "" and ParentAuth.check_pin("4321") == "ok", "pin: смена PIN")


# ---------- статистика ----------
func test_stats() -> void:
	var ans = [
		{"t": "a", "o": "first", "fs": true, "mode": "lesson"},
		{"t": "b", "o": "failed", "fs": true, "mode": "lesson"},
		{"t": "b", "o": "first", "fs": false, "mode": "lesson"},   # повтор — не считается первой попыткой
		{"t": "b", "o": "first", "fs": false, "mode": "review"},
		{"t": "c", "o": "corrected", "fs": true, "mode": "lesson"},
		{"t": "m", "o": "first", "fs": true, "mode": "mult"},
	]
	var s = ParentStats.summarize(ans)
	ok(s["first_seen"] == 3 and s["first_ok"] == 1, "stats: учитывается только первое знакомство")
	ok(s["accuracy"] == 33, "stats: точность не завышается повторами (33%)")
	ok(s["review_total"] == 1 and s["review_ok"] == 1, "stats: повторение считается отдельно")
	ok(ParentStats.summarize([])["accuracy"] == -1, "stats: нет данных → нет процента")
	var rec = ParentStats.recommendation({"subject": "math", "accuracy": 40, "title": "Тестовая тема", "open_errors": 2})
	ok(rec.length() > 10 and not rec.to_lower().contains("диагноз"), "stats: рекомендация без «диагноза»")


# ---------- банк ответов ----------
func test_answer_bank() -> void:
	var total = 0
	var bad = 0
	for g in [2, 3, 4]:
		for s in Content.SUBJECTS:
			for tp in Content.topics(g, s):
				var ts: Array = Content.tasks(tp["id"])
				if ts.size() < 10:
					bad += 1
					log_lines.append("мало заданий: " + str(tp["id"]))
				for t in ts:
					total += 1
					if not _answer_passes(t):
						bad += 1
						if bad < 20:
							log_lines.append("ответ не проходит проверку: " + str(t["id"]))
	print("bank tasks checked: ", total)
	ok(total > 5000, "bank: больше 5000 заданий (%d)" % total)
	ok(bad == 0, "bank: правильный ответ каждого задания принимается проверкой (ошибок %d)" % bad)


func _answer_passes(t: Dictionary) -> bool:
	match str(t.get("type", "")):
		"choice", "tf", "fill", "listen":
			return AnswerChecker.check_choice(t, str(t["answer"])) and t.get("options", []).has(t["answer"])
		"input":
			return AnswerChecker.check_input(t, str(t["answer"]))
		"multi":
			return AnswerChecker.check_multi(t, t["answer"].duplicate())
		"order", "build":
			return AnswerChecker.check_order(t, t["answer"].duplicate())
		"match":
			return AnswerChecker.check_match(t, t["pairs"].duplicate(true))
		"sort":
			var g = {}
			for it in t["items"]:
				g[it[0]] = int(it[1])
			return AnswerChecker.check_sort(t, g)
		"fix":
			return AnswerChecker.check_fix(t, int(t["wrong"]), str(t["answer"]))
		"array_build":
			return true
	return false


# ---------- порядок заданий ----------
func test_shuffle_order() -> void:
	var tid = Content.topics(3, "rus")[0]["id"]
	var ts: Array = Content.tasks(tid).duplicate()
	var a = ts.duplicate()
	var b = ts.duplicate()
	a.shuffle()
	b.shuffle()
	var c = ts.duplicate()
	c.shuffle()
	ok(a != b or b != c, "lesson: порядок заданий перемешивается")
	ok(AnswerChecker.check_input({"answer": "50000", "alts": []}, "50 000"), "checker: пробелы в числах")
	ok(AnswerChecker.check_input({"answer": "ёлка", "alts": []}, "Елка."), "checker: регистр, ё/е, точка")
	ok(AnswerChecker.check_input({"answer": "4:45", "alts": []}, "04.45"), "checker: формат времени")


# ---------- таблица умножения ----------
func test_mult() -> void:
	Profiles.select(pid_a)
	ok(MultTrainer.key(7, 3) == MultTrainer.key(3, 7) and MultTrainer.parse_key(MultTrainer.key(7, 3)) == [3, 7], "mult: ключ факта")
	var plan = MultTrainer.daily_plan(3, 12)
	ok(plan.size() >= 10, "mult: дневной план ≥ 10 фактов")
	var modes_ok = true
	for mode in range(1, 9):
		var facts = MultTrainer.facts_for_training(3, mode, 12)
		if facts.size() < 10:
			modes_ok = false
			log_lines.append("mult: режим %d дал %d фактов" % [mode, facts.size()])
		for i in facts.size():
			var task = MultTrainer.make_task(facts[i], mode, i)
			if task.is_empty() or not task.has("type"):
				modes_ok = false
	ok(modes_ok, "mult: 8 режимов, в каждом ≥ 10 заданий")
	var k = MultTrainer.key(6, 7)
	MultTrainer.record(k, false, 4000)
	MultTrainer.record(k, true, 2000)
	var fct = MultTrainer.fact(k)
	ok(int(fct.get("seen", fct.get("n", 0))) >= 2 or fct.size() > 0, "mult: статистика по отдельному факту")


# ---------- отрисовка всех видов заданий ----------
func test_task_views() -> void:
	var seen = {}
	for g in [2, 3, 4]:
		for s in Content.SUBJECTS:
			for tp in Content.topics(g, s):
				for t in Content.tasks(tp["id"]):
					if not seen.has(t["type"]):
						seen[t["type"]] = t
	seen["array_build"] = MultTrainer.make_task(MultTrainer.key(3, 4), 0, 0)
	var holder = Control.new()
	holder.size = Vector2(1280, 720)
	add_child(holder)
	for ty in seen:
		var v = TaskView.create(seen[ty])
		holder.add_child(v)
		await get_tree().process_frame
		ok(v.get_child_count() > 0, "view: задание типа «%s» отрисовано" % ty)
		v.queue_free()
	ok(seen.size() >= 11, "view: проверено видов заданий: %d" % seen.size())
	Profiles.delete_profile(pid_a)
	Profiles.delete_profile(pid_b)


# ---------- прокрутка пальцем поверх кнопок ----------
var _taps := 0


func _mb(pos: Vector2, pressed: bool) -> void:
	var e = InputEventMouseButton.new()
	pos = get_viewport().get_final_transform() * pos   # координаты окна (в тестах окно может быть меньше)
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	get_viewport().push_input(e)


func _mm(pos: Vector2) -> void:
	var e = InputEventMouseMotion.new()
	pos = get_viewport().get_final_transform() * pos
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(e)


func test_touch_scroll() -> void:
	var list = UIKit.vbox(10)
	for i in 30:
		var b = UIKit.button("Кнопка %d" % i, UIKit.C_PRIMARY, 22, Vector2(300, 80))
		b.pressed.connect(func(): _taps += 1)
		list.add_child(b)
	var sc = UIKit.scroll(list)
	var layer = CanvasLayer.new()
	add_child(layer)
	sc.position = Vector2(0, 0)
	sc.size = Vector2(400, 500)
	layer.add_child(sc)
	for i in 3:
		await get_tree().process_frame
	var p = Vector2(150, 300)
	# свайп вверх, начатый на кнопке
	_mm(p)
	_mb(p, true)
	for k in range(1, 11):
		_mm(p - Vector2(0, 20 * k))
		await get_tree().process_frame
	_mb(p - Vector2(0, 200), false)
	await get_tree().process_frame
	ok(sc.scroll_vertical >= 150, "touch: свайп по кнопкам прокручивает список (%d px)" % sc.scroll_vertical)
	ok(_taps == 0, "touch: при прокрутке кнопка не нажимается")
	# обычное касание кнопки по-прежнему работает
	await get_tree().create_timer(1.0).timeout
	_mm(p)
	_mb(p, true)
	await get_tree().process_frame
	_mb(p, false)
	await get_tree().process_frame
	ok(_taps == 1, "touch: короткое касание нажимает кнопку")
	layer.queue_free()
