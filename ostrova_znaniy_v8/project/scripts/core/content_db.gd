extends Node
## Доступ к учебному реестру и банку заданий.
## Банк загружается строго для выбранного класса; каждое задание дополнительно
## проверяется на соответствие классу/предмету/теме, чтобы исключить смешивание.

const SUBJECTS := ["math", "rus", "world", "eng", "read"]
const SUBJECT_TITLES := {"math": "Математика", "rus": "Русский язык", "world": "Окружающий мир", "eng": "Английский язык", "read": "Литературное чтение"}

var registry = {}
var _banks = {}          # "g2_math" -> {topic_id: [tasks]}
var _topic_index = {}    # topic_id -> {grade, subject, section, title, order, idx}
var _task_index = {}     # task_id -> task
var load_errors: Array[String] = []


func _ready() -> void:
	_load_registry()


func _load_json(path: String):
	if not FileAccess.file_exists(path):
		load_errors.append("Нет файла " + path)
		return null
	var f = FileAccess.open(path, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if d == null:
		load_errors.append("Не читается " + path)
	return d


func _load_registry() -> void:
	var d = _load_json("res://data/curriculum/registry.json")
	if typeof(d) != TYPE_DICTIONARY:
		return
	registry = d
	for g in registry.get("grades", []):
		var gr = int(g["grade"])
		for s in g["subjects"]:
			var idx = 0
			for c in s["sections"]:
				for t in c["topics"]:
					_topic_index[t["id"]] = {"grade": gr, "subject": s["code"], "section": c["title"], "section_id": c["id"],
						"title": t["title"], "order": int(t["order"]), "idx": idx, "items": t.get("items", [])}
					idx += 1


func grade_entry(grade: int) -> Dictionary:
	for g in registry.get("grades", []):
		if int(g["grade"]) == grade:
			return g
	return {}


func subject_entry(grade: int, subject: String) -> Dictionary:
	for s in grade_entry(grade).get("subjects", []):
		if s["code"] == subject:
			return s
	return {}


func sections(grade: int, subject: String) -> Array:
	return subject_entry(grade, subject).get("sections", [])


## Темы предмета по порядку (только темы, в которых есть задания).
func topics(grade: int, subject: String) -> Array:
	var out = []
	for c in sections(grade, subject):
		for t in c["topics"]:
			if tasks(t["id"]).size() > 0:
				out.append(t)
	return out


func topic_info(topic_id: String) -> Dictionary:
	return _topic_index.get(topic_id, {})


func _ensure_bank(grade: int, subject: String) -> void:
	var key = "g%d_%s" % [grade, subject]
	if _banks.has(key):
		return
	var d = _load_json("res://data/content/%s.json" % key)
	var bank = {}
	if typeof(d) == TYPE_DICTIONARY and int(d.get("grade", -1)) == grade and str(d.get("subject", "")) == subject:
		for tid in d["topics"]:
			var clean = []
			for t in d["topics"][tid]:
				# защита от смешивания классов и предметов
				if int(t.get("grade", -1)) == grade and str(t.get("subject", "")) == subject and str(t.get("topic", "")) == tid:
					clean.append(t)
					_task_index[t["id"]] = t
				else:
					load_errors.append("Отброшено чужое задание " + str(t.get("id", "?")))
			bank[tid] = clean
	else:
		load_errors.append("Банк %s не соответствует классу/предмету" % key)
	_banks[key] = bank


func tasks(topic_id: String) -> Array:
	var info = topic_info(topic_id)
	if info.is_empty():
		return []
	_ensure_bank(info["grade"], info["subject"])
	return _banks["g%d_%s" % [info["grade"], info["subject"]]].get(topic_id, [])


func task(task_id: String) -> Dictionary:
	if _task_index.has(task_id):
		return _task_index[task_id]
	var topic_id = task_id.rsplit("-", true, 1)[0]
	tasks(topic_id)
	return _task_index.get(task_id, {})


func preload_grade(grade: int) -> void:
	for s in SUBJECTS:
		_ensure_bank(grade, s)


func source_of(grade: int, subject: String) -> String:
	return subject_entry(grade, subject).get("source", "")


## Сюжетный маршрут: темы всех предметов по очереди (математика, русский, мир, английский, чтение…)
func story_route(grade: int) -> Array:
	var lists = []
	var longest = 0
	for s in SUBJECTS:
		var l = topics(grade, s)
		lists.append(l)
		longest = maxi(longest, l.size())
	var route = []
	for i in longest:
		for l in lists:
			if i < l.size():
				route.append(l[i]["id"])
	return route
