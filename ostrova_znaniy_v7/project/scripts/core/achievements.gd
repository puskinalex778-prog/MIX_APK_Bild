class_name Achievements
extends RefCounted
## Список достижений и проверка условий.

const LIST := [
	{"id": "first_lesson", "icon": "🌟", "title": "Первая искра", "desc": "Пройди первую тему"},
	{"id": "five_topics", "icon": "🔥", "title": "Пять фонариков", "desc": "Пройди 5 тем"},
	{"id": "twenty_topics", "icon": "🏮", "title": "Светлый путь", "desc": "Пройди 20 тем"},
	{"id": "fifty_topics", "icon": "🗼", "title": "Хранитель маяка", "desc": "Пройди 50 тем"},
	{"id": "perfect", "icon": "💎", "title": "Без единой ошибки", "desc": "Пройди тему, ответив верно с первой попытки на все задания"},
	{"id": "stars_10", "icon": "⭐", "title": "Звездочёт", "desc": "Собери 10 звёзд"},
	{"id": "stars_50", "icon": "🌠", "title": "Звездопад", "desc": "Собери 50 звёзд"},
	{"id": "stars_150", "icon": "🌌", "title": "Млечный путь", "desc": "Собери 150 звёзд"},
	{"id": "fixer", "icon": "🛠️", "title": "Работа над ошибками", "desc": "Исправь 5 ошибок при повторении"},
	{"id": "fixer_25", "icon": "🧰", "title": "Мастер исправлений", "desc": "Исправь 25 ошибок при повторении"},
	{"id": "break_taker", "icon": "🧘", "title": "Умею отдыхать", "desc": "Сделай разминку во время перерыва"},
	{"id": "mult_explorer", "icon": "🔍", "title": "Исследователь умножения", "desc": "Изучи, как устроено умножение"},
	{"id": "mult_20", "icon": "✖️", "title": "Двадцать фактов", "desc": "Освой 20 фактов таблицы умножения"},
	{"id": "mult_all", "icon": "🏆", "title": "Таблица покорена", "desc": "Освой все факты таблицы умножения"},
	{"id": "subject_math", "icon": "🔢", "title": "Мастер Острова Чисел", "desc": "Пройди все темы математики своего класса"},
	{"id": "subject_rus", "icon": "📝", "title": "Мастер Острова Слов", "desc": "Пройди все темы русского языка своего класса"},
	{"id": "subject_world", "icon": "🌍", "title": "Мастер Зелёного острова", "desc": "Пройди все темы окружающего мира своего класса"},
	{"id": "subject_eng", "icon": "⚓", "title": "Капитан Порта Hello", "desc": "Пройди все темы английского языка своего класса"},
	{"id": "subject_read", "icon": "📚", "title": "Хранитель сказок", "desc": "Пройди все темы литературного чтения своего класса"},
	{"id": "story_end", "icon": "👑", "title": "Свет вернулся!", "desc": "Пройди весь сюжет своего класса"},
	{"id": "days_3", "icon": "📅", "title": "Три дня подряд", "desc": "Занимайся три дня подряд"},
]


static func info(id: String) -> Dictionary:
	for a in LIST:
		if a["id"] == id:
			return a
	return {"id": id, "icon": "🏅", "title": id, "desc": ""}


static func check_all() -> Array:
	var got = []
	var pr: Dictionary = Profiles.progress()
	var grade = Profiles.current_grade()
	var done = 0
	for g in pr["grades"]:
		for t in pr["grades"][g]["topics"]:
			if pr["grades"][g]["topics"][t]["status"] == "done":
				done += 1
	var rules = {"first_lesson": done >= 1, "five_topics": done >= 5, "twenty_topics": done >= 20, "fifty_topics": done >= 50,
		"stars_10": int(pr.get("stars", 0)) >= 10, "stars_50": int(pr.get("stars", 0)) >= 50, "stars_150": int(pr.get("stars", 0)) >= 150}
	var fixed = 0
	for e in pr["errors"].values():
		if e["status"] == "fixed" and int(e.get("repeats", 0)) > 0:
			fixed += 1
	rules["fixer"] = fixed >= 5
	rules["fixer_25"] = fixed >= 25
	var mf = MultTrainer.mastered_facts(grade).size()
	rules["mult_20"] = mf >= 20
	rules["mult_all"] = mf >= 55
	for s in Content.SUBJECTS:
		var all_done = true
		var lst = Content.topics(grade, s)
		for t in lst:
			if not Profiles.is_done(t["id"]):
				all_done = false
				break
		rules["subject_" + s] = all_done and lst.size() > 0
	var days: Dictionary = pr.get("daily", {})
	var streak = 0
	var now = int(Time.get_unix_time_from_system())
	for i in 3:
		var dkey = Time.get_date_string_from_unix_time(now - i * 86400)
		if float(days.get(dkey, 0.0)) > 0.5:
			streak += 1
	rules["days_3"] = streak >= 3
	for k in rules:
		if rules[k] and Profiles.award(k):
			got.append(k)
	return got
