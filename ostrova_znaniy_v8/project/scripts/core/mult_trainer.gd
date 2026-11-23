class_name MultTrainer
extends RefCounted
## Мастерская таблицы умножения: логика программы запоминания, интервальное
## повторение (коробки Лейтнера) и генерация заданий восьми режимов.
## Факт хранится без учёта порядка множителей: «6 × 7» = «7 × 6» (переместительное свойство
## уменьшает объём запоминания с 64 до 36 фактов для 2…9).

const INTERVAL_DAYS := [0, 0, 1, 3, 7, 14]   # по номеру коробки 0..5
const STAGES := [
	{"id": "s1", "title": "Что такое умножение", "tip": "Умножение — это сложение одинаковых групп. 3 · 4 — это 3 взять 4 раза: 3 + 3 + 3 + 3.", "tables": []},
	{"id": "s2", "title": "Молниеносные: ×1, ×10 и ×0", "tip": "×1 — число не меняется. ×10 — припиши нуль. ×0 — всегда 0.", "tables": [1, 10]},
	{"id": "s3", "title": "×2 — удваиваем", "tip": "Умножить на 2 — значит сложить число с самим собой: 7 · 2 = 7 + 7.", "tables": [2]},
	{"id": "s4", "title": "×5 — половина от ×10", "tip": "a · 5 — это половина от a · 10. 8 · 5 = 80 : 2 = 40. Ответы оканчиваются на 0 или 5.", "tables": [5]},
	{"id": "s5", "title": "×3 — удвой и добавь ещё раз", "tip": "a · 3 = a · 2 + a. 7 · 3 = 14 + 7 = 21.", "tables": [3]},
	{"id": "s6", "title": "×4 — дважды удвой", "tip": "a · 4 = удвоить, а потом ещё раз удвоить. 6 · 4: 6 → 12 → 24.", "tables": [4]},
	{"id": "s7", "title": "×9 — десять без одного", "tip": "a · 9 = a · 10 − a. 7 · 9 = 70 − 7 = 63. Сумма цифр ответа всегда 9.", "tables": [9]},
	{"id": "s8", "title": "Квадраты", "tip": "6 · 6 = 36, 7 · 7 = 49, 8 · 8 = 64. Представь квадрат из клеток.", "tables": ["sq"]},
	{"id": "s9", "title": "Последние трудные факты", "tip": "6 · 7 = 42, 6 · 8 = 48, 7 · 8 = 56 (5-6-7-8: «56 = 7 · 8»).", "tables": ["hard"]},
]
const MODES := [
	{"id": 1, "title": "Найди произведение"},
	{"id": 2, "title": "Пропущенный множитель"},
	{"id": 3, "title": "Найди частное"},
	{"id": 4, "title": "Выражение к рисунку"},
	{"id": 5, "title": "Построй рисунок"},
	{"id": 6, "title": "Текстовая задача"},
	{"id": 7, "title": "Найди ошибку"},
	{"id": 8, "title": "Смешанное повторение"},
]

static var rng := RandomNumberGenerator.new()


static func key(a: int, b: int) -> String:
	return "%d×%d" % [mini(a, b), maxi(a, b)]


static func parse_key(k: String) -> Array:
	var p = k.split("×")
	return [int(p[0]), int(p[1])]


static func stage_facts(stage_idx: int) -> Array:
	var st: Dictionary = STAGES[stage_idx]
	var out = []
	var tabs: Array = st["tables"]
	if tabs.is_empty():
		return out
	if tabs[0] is String:
		if tabs[0] == "sq":
			return [key(6, 6), key(7, 7), key(8, 8), key(3, 3), key(4, 4)]
		return [key(6, 7), key(6, 8), key(7, 8)]
	var covered = {}
	for si in stage_idx:
		for f in stage_facts(si):
			covered[f] = true
	for t in tabs:
		for m in range(1, 11):
			var k = key(t, m)
			if not covered.has(k) and not out.has(k):
				out.append(k)
	return out


## Какие таблицы доступны по программе класса: во 2 классе — таблицы, до которых
## ребёнок дошёл в учебном маршруте (или открытые родителем); в 3–4 — все.
static func allowed_tables(grade: int) -> Array:
	if grade >= 3:
		return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	var out = [1, 10]
	for k in [2, 3, 4, 5, 6, 7, 8, 9]:
		var tid = "g2.math.x%d" % k
		if Profiles.is_topic_open(tid):
			out.append(k)
	if not out.has(2):
		out.append(2)
	return out


static func fact_allowed(k: String, grade: int) -> bool:
	var ab = parse_key(k)
	var tabs = allowed_tables(grade)
	return tabs.has(ab[0]) or tabs.has(ab[1])


static func data() -> Dictionary:
	var m: Dictionary = Profiles.progress()["mult"]
	if not m.has("facts"):
		m["facts"] = {}
	if not m.has("stage"):
		m["stage"] = 1
	if not m.has("explored"):
		m["explored"] = false
	return m


static func fact(k: String) -> Dictionary:
	var f: Dictionary = data()["facts"]
	if not f.has(k):
		f[k] = {"box": 0, "right": 0, "wrong": 0, "seen": 0, "last": 0, "due": 0, "ms": 0}
	return f[k]


static func today() -> int:
	return int(Time.get_unix_time_from_system() / 86400)


static func record(k: String, correct: bool, ms: int) -> void:
	var f = fact(k)
	f["seen"] = int(f["seen"]) + 1
	f["last"] = int(Time.get_unix_time_from_system())
	f["ms"] = int((int(f["ms"]) * 0.7 + ms * 0.3)) if int(f["ms"]) > 0 else ms
	if correct:
		f["right"] = int(f["right"]) + 1
		if ms < 6000:
			f["box"] = mini(5, int(f["box"]) + 1)
		else:
			f["box"] = maxi(1, int(f["box"]))
	else:
		f["wrong"] = int(f["wrong"]) + 1
		f["box"] = 1
	f["due"] = today() + INTERVAL_DAYS[int(f["box"])]


static func stage_progress(stage_idx: int) -> float:
	var fs = stage_facts(stage_idx)
	if fs.is_empty():
		return 1.0 if data().get("explored", false) else 0.0
	var ok = 0
	for k in fs:
		if int(fact(k)["box"]) >= 2:
			ok += 1
	return float(ok) / fs.size()


static func current_stage(grade: int) -> int:
	for i in STAGES.size():
		var fs = stage_facts(i)
		var allowed = true
		for k in fs:
			if not fact_allowed(k, grade):
				allowed = false
		if not allowed:
			return i
		if stage_progress(i) < 0.8:
			return i
	return STAGES.size() - 1


static func stage_available(stage_idx: int, grade: int) -> bool:
	for k in stage_facts(stage_idx):
		if not fact_allowed(k, grade):
			return false
	return true


static func mastered_facts(grade: int) -> Array:
	var out = []
	for k in data()["facts"]:
		if int(data()["facts"][k]["box"]) >= 2 and fact_allowed(k, grade):
			out.append(k)
	return out


static func hard_facts(grade: int, n: int = 10) -> Array:
	var arr = []
	for k in data()["facts"]:
		var f: Dictionary = data()["facts"][k]
		if int(f["seen"]) > 0 and fact_allowed(k, grade):
			arr.append([k, int(f["wrong"]) * 3 - int(f["box"]) * 2 + (1 if int(f["ms"]) > 6000 else 0)])
	arr.sort_custom(func(x, y): return x[1] > y[1])
	var out = []
	for x in arr:
		if x[1] > 0 or int(data()["facts"][x[0]]["box"]) <= 1:
			out.append(x[0])
		if out.size() >= n:
			break
	return out


## План тренировки дня: повторение «созревших» фактов + до 4 новых из текущего этапа.
static func daily_plan(grade: int, size: int = 12) -> Array:
	var due = []
	for k in data()["facts"]:
		var f: Dictionary = data()["facts"][k]
		if int(f["seen"]) > 0 and int(f["due"]) <= today() and fact_allowed(k, grade):
			due.append(k)
	due.shuffle()
	var plan = due.slice(0, size - 4)
	# этап 0 — только объяснение без фактов, поэтому тренировка начинается минимум с этапа 1
	var st = maxi(1, current_stage(grade))
	var news = []
	for i in range(0, st + 1):
		for k in stage_facts(i):
			if int(fact(k)["seen"]) == 0 and fact_allowed(k, grade) and not plan.has(k):
				news.append(k)
	plan.append_array(news.slice(0, 4))
	# добиваем до нужного размера фактами текущего и пройденных этапов
	var pool = []
	for i in range(0, st + 1):
		for k in stage_facts(i):
			if fact_allowed(k, grade) and not plan.has(k):
				pool.append(k)
	pool.shuffle()
	for k in pool:
		if plan.size() >= size:
			break
		plan.append(k)
	return plan


## Факты для режима: для смешанного — освоенные, иначе — по плану/этапу.
static func facts_for_training(grade: int, mode: int, n: int = 12, only: Array = []) -> Array:
	var src: Array = only.duplicate()
	if src.is_empty():
		if mode == 8:
			src = mastered_facts(grade)
			if src.size() < 6:
				src = daily_plan(grade, n)
		else:
			src = daily_plan(grade, n)
	var allowed_src = []
	for k in src:
		if fact_allowed(k, grade):
			allowed_src.append(k)
	src = allowed_src
	if src.is_empty():
		src = [key(2, 2), key(2, 3), key(2, 4), key(2, 5), key(2, 6), key(2, 7), key(2, 8), key(2, 9), key(1, 2), key(2, 10)]
	src.shuffle()
	# без повторов внутри тренировки, пока хватает разных фактов
	var out = []
	var i = 0
	while out.size() < n:
		out.append(src[i % src.size()])
		i += 1
	return out


const ITEMS := [["🍎", "яблок", "яблоко", "яблока"], ["⭐", "звёзд", "звезда", "звезды"], ["🍓", "ягод", "ягода", "ягоды"],
	["🐟", "рыбок", "рыбка", "рыбки"], ["🎈", "шариков", "шарик", "шарика"], ["🍄", "грибов", "гриб", "гриба"]]
const STORIES := [
	["В %d коробках по %d карандашей. Сколько всего карандашей?", "mul"],
	["На %d тарелках лежит по %d печенья. Сколько печенья всего?", "mul"],
	["Светлячок Лумик развесил гирлянды. Гирлянд — %d, огоньков в каждой — %d. Сколько всего огоньков?", "mul"],
	["%d детей принесли по %d каштана. Сколько каштанов собрали?", "mul"],
	["%d конфет разложили поровну в %d пакета. Сколько конфет в каждом?", "div"],
	["%d наклеек разделили поровну между %d друзьями. Сколько получил каждый?", "div"],
	["%d листов раздали по %d каждому ученику. Скольким ученикам хватило?", "div2"],
]


static func make_task(k: String, mode: int, idx: int) -> Dictionary:
	var ab = parse_key(k)
	var a: int = ab[0]
	var b: int = ab[1]
	if rng.randi() % 2 == 0:
		var tmp = a
		a = b
		b = tmp
	var p = a * b
	var m = mode
	if m == 8:
		m = [1, 2, 3, 4, 6, 7][rng.randi() % 6]
	var t = {"id": "mult.%s.m%d.%d" % [k, m, idx], "fact": k, "mode": m, "topic": "mult", "subject": "math",
		"grade": Profiles.current_grade(), "skill": "Таблица умножения: " + k.replace("×", " × ")}
	match m:
		1:
			t.merge({"type": "input", "kb": "num", "prompt": "%d · %d = ?" % [a, b], "answer": str(p),
				"explanation": "%d · %d = %d. Это %d раз(а) по %d." % [a, b, p, b, a], "hint": _hint(a, b)})
		2:
			t.merge({"type": "input", "kb": "num", "prompt": "%d · ? = %d" % [a, p], "answer": str(b),
				"explanation": "%d · %d = %d, значит пропущен множитель %d (%d : %d = %d)." % [a, b, p, b, p, a, b], "hint": "Чтобы найти множитель, раздели %d на %d." % [p, a]})
		3:
			if a == 0:
				a = 1
			t.merge({"type": "input", "kb": "num", "prompt": "%d : %d = ?" % [p, a], "answer": str(b),
				"explanation": "%d : %d = %d, потому что %d · %d = %d." % [p, a, b, a, b, p], "hint": "Вспомни: %d умножить на сколько будет %d?" % [a, p]})
		4:
			var r = mini(a, 6)
			var c = b
			var opts = ["%d · %d" % [c, r], "%d + %d" % [c, r], "%d · %d" % [c, r + 1] if r < 9 else "%d · %d" % [c + 1, r], "%d · %d" % [c, c]]
			var uniq = []
			for o in opts:
				if not uniq.has(o):
					uniq.append(o)
			t.merge({"type": "choice", "prompt": "Какое выражение подходит к рисунку?", "answer": uniq[0], "options": uniq,
				"pic": {"k": "array", "r": r, "c": c, "e": ITEMS[rng.randi() % ITEMS.size()][0]},
				"explanation": "%d рядов по %d — это %d · %d = %d." % [r, c, c, r, c * r], "hint": "Сколько рядов и сколько предметов в каждом ряду?"})
			t["fact"] = key(r, c)
		5:
			var a5 = mini(a, 6)
			var b5 = mini(b, 9)
			t.merge({"type": "array_build", "prompt": "Построй рисунок к выражению %d · %d (%d раз по %d)." % [b5, a5, a5, b5], "rows": a5, "cols": b5,
				"answer": "%d×%d" % [a5, b5], "explanation": "%d · %d: %d ряда(ов) по %d. Можно и наоборот — %d рядов по %d: произведение то же (%d)." % [b5, a5, a5, b5, b5, a5, a5 * b5],
				"hint": "Сделай %d ряда, в каждом по %d." % [a5, b5]})
			t["fact"] = key(a5, b5)
		6:
			var st: Array = STORIES[rng.randi() % STORIES.size()]
			if st[1] == "mul":
				t.merge({"type": "input", "kb": "num", "prompt": st[0] % [a, b], "answer": str(p), "explanation": "По %d взяли %d раз(а): %d · %d = %d." % [b, a, b, a, p], "hint": "Одинаковые группы — умножение."})
			elif st[1] == "div":
				var d = a if a > 0 else 1
				t.merge({"type": "input", "kb": "num", "prompt": st[0] % [p, d], "answer": str(p / d), "explanation": "%d : %d = %d." % [p, d, p / d], "hint": "Поровну — значит деление."})
			else:
				var d2 = b if b > 0 else 1
				t.merge({"type": "input", "kb": "num", "prompt": st[0] % [p, d2], "answer": str(p / d2), "explanation": "%d : %d = %d." % [p, d2, p / d2], "hint": "Сколько раз по %d помещается в %d?" % [d2, p]})
		7:
			var wrong = p + [a, -a, b, 1, -1, 10][rng.randi() % 6]
			if wrong == p or wrong < 0:
				wrong = p + 2
			var opts7 = [str(p), str(wrong), str(p + a + 1)]
			t.merge({"type": "fix", "prompt": "Найди ошибку и исправь её.", "tokens": [str(a), "·", str(b), "=", str(wrong)], "wrong": 4,
				"answer": str(p), "options": opts7, "explanation": "%d · %d = %d, а не %d." % [a, b, p, wrong], "hint": _hint(a, b)})
	return t


static func _hint(a: int, b: int) -> String:
	var lo = mini(a, b)
	var hi = maxi(a, b)
	match lo:
		0:
			return "При умножении на 0 всегда получается 0."
		1:
			return "При умножении на 1 число не меняется."
		2:
			return "Удвой: %d + %d." % [hi, hi]
		5:
			return "Половина от %d · 10 = %d." % [hi, hi * 10]
		9:
			return "%d · 10 − %d." % [hi, hi]
	if hi == 9:
		return "%d · 10 − %d." % [lo, lo]
	if hi == 10:
		return "Припиши нуль к %d." % lo
	if hi == 5:
		return "Половина от %d · 10." % lo
	if lo == 3:
		return "Удвой %d и добавь ещё %d." % [hi, hi]
	if lo == 4:
		return "Удвой %d, а потом ещё раз удвой." % hi
	if lo == hi:
		return "Квадрат: %d рядов по %d." % [lo, lo]
	return "Вспомни %d · %d = %d и добавь ещё %d." % [lo, hi - 1, lo * (hi - 1), lo]
