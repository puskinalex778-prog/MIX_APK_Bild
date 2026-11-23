extends Node
## Детские профили и их прогресс. Каждый профиль имеет устойчивый случайный id
## (имя можно менять, имена могут совпадать). Прогресс хранится отдельно по классам.

signal profile_changed
signal achievement(id: String)

const INDEX_FORMAT := "ostrova-profiles"
const PROGRESS_FORMAT := "ostrova-progress"
const INDEX_VERSION := 1
const PROGRESS_VERSION := 2
const MAX_ANSWERS := 6000
const AVATARS := ["kid_a", "kid_b", "kid_c", "kid_d", "kid_e", "kid_f"]

var _index = {"profiles": [], "current": ""}
var _progress = {}   # id -> dict


func _ready() -> void:
	load_index()


# ---------------- индекс профилей ----------------
func load_index() -> void:
	var r = SaveStore.read("profiles.json", INDEX_FORMAT)
	if not r.is_empty() and typeof(r["data"]) == TYPE_DICTIONARY:
		_index = r["data"]
	if not _index.has("profiles"):
		_index["profiles"] = []
	if not _index.has("current"):
		_index["current"] = ""


func save_index() -> void:
	SaveStore.write("profiles.json", INDEX_FORMAT, INDEX_VERSION, _index)


static func new_id() -> String:
	var bytes = Crypto.new().generate_random_bytes(8)
	return "p" + bytes.hex_encode()


func list() -> Array:
	return _index["profiles"]


func has_profiles() -> bool:
	return _index["profiles"].size() > 0


func get_profile(id: String) -> Dictionary:
	for p in _index["profiles"]:
		if p["id"] == id:
			return p
	return {}


func current_id() -> String:
	return _index.get("current", "")


func current() -> Dictionary:
	return get_profile(current_id())


func current_grade() -> int:
	return int(current().get("grade", 2))


func select(id: String) -> void:
	if get_profile(id).is_empty():
		return
	_index["current"] = id
	save_index()
	Content.preload_grade(current_grade())
	profile_changed.emit()


func sanitize_name(n: String) -> String:
	n = n.strip_edges().replace("\n", " ")
	if n.length() > 24:
		n = n.substr(0, 24)
	return n if n != "" else "Ученик"


func create_profile(name: String, gender: String, avatar: String, grade: int) -> String:
	var id = new_id()
	while not get_profile(id).is_empty():
		id = new_id()
	var p = {
		"id": id, "name": sanitize_name(name), "gender": gender if gender in ["boy", "girl"] else "boy",
		"avatar": avatar if avatar in AVATARS else AVATARS[0], "grade": clampi(grade, 2, 4),
		"created": Time.get_unix_time_from_system(), "updated": Time.get_unix_time_from_system(),
	}
	_index["profiles"].append(p)
	_index["current"] = id
	save_index()
	_progress[id] = _new_progress(id)
	save_progress(id)
	profile_changed.emit()
	return id


func update_profile(id: String, fields: Dictionary) -> void:
	var p = get_profile(id)
	if p.is_empty():
		return
	if fields.has("name"):
		p["name"] = sanitize_name(str(fields["name"]))
	if fields.has("gender") and fields["gender"] in ["boy", "girl"]:
		p["gender"] = fields["gender"]
	if fields.has("avatar") and fields["avatar"] in AVATARS:
		p["avatar"] = fields["avatar"]
	if fields.has("grade"):
		p["grade"] = clampi(int(fields["grade"]), 2, 4)
	p["updated"] = Time.get_unix_time_from_system()
	save_index()
	profile_changed.emit()


func delete_profile(id: String) -> void:
	var arr: Array = _index["profiles"]
	for i in arr.size():
		if arr[i]["id"] == id:
			arr.remove_at(i)
			break
	_progress.erase(id)
	SaveStore.remove("progress_%s.json" % id)
	if _index["current"] == id:
		_index["current"] = arr[0]["id"] if arr.size() > 0 else ""
	save_index()
	profile_changed.emit()


# ---------------- прогресс ----------------
func _new_progress(id: String) -> Dictionary:
	return {"profile_id": id, "grades": {}, "answers": [], "errors": {}, "sessions": [], "mult": {}, "achievements": {},
		"assigned": [], "daily": {}, "stars": 0}


func migrate(p: Dictionary, from_version: int) -> Dictionary:
	# v1 -> v2: добавлены поля assigned (задания от родителя) и daily (минуты по дням)
	if from_version < 2:
		if not p.has("assigned"):
			p["assigned"] = []
		if not p.has("daily"):
			p["daily"] = {}
	for k in ["grades", "errors", "mult", "achievements", "daily"]:
		if typeof(p.get(k)) != TYPE_DICTIONARY:
			p[k] = {}
	for k in ["answers", "sessions", "assigned"]:
		if typeof(p.get(k)) != TYPE_ARRAY:
			p[k] = []
	return p


func progress(id: String = "") -> Dictionary:
	if id == "":
		id = current_id()
	if id == "":
		return _new_progress("")
	if not _progress.has(id):
		var r = SaveStore.read("progress_%s.json" % id, PROGRESS_FORMAT)
		if r.is_empty():
			_progress[id] = _new_progress(id)
		else:
			_progress[id] = migrate(r["data"], int(r["version"]))
	return _progress[id]


func save_progress(id: String = "") -> void:
	if id == "":
		id = current_id()
	if id == "" or not _progress.has(id):
		return
	SaveStore.write("progress_%s.json" % id, PROGRESS_FORMAT, PROGRESS_VERSION, _progress[id])


func replace_progress(id: String, data: Dictionary) -> void:
	_seen.erase(id)
	_progress[id] = migrate(data, PROGRESS_VERSION)
	save_progress(id)


func grade_data(grade: int = 0, id: String = "") -> Dictionary:
	if grade == 0:
		grade = current_grade()
	var pr = progress(id)
	var key = str(grade)
	if not pr["grades"].has(key):
		pr["grades"][key] = {"topics": {}, "story_step": 0, "story_seen": []}
	return pr["grades"][key]


func topic_state(topic_id: String, id: String = "") -> Dictionary:
	var info = Content.topic_info(topic_id)
	var gd = grade_data(int(info.get("grade", current_grade())), id)
	if not gd["topics"].has(topic_id):
		gd["topics"][topic_id] = {"status": "new", "stars": 0, "best": 0, "sessions": 0, "parent_unlocked": false, "last": 0}
	return gd["topics"][topic_id]


## Тема открыта, если она первая в предмете, предыдущая пройдена или её открыл родитель.
func is_topic_open(topic_id: String, id: String = "") -> bool:
	var info = Content.topic_info(topic_id)
	if info.is_empty():
		return false
	var st = topic_state(topic_id, id)
	if st["parent_unlocked"] or st["status"] in ["started", "done"]:
		return true
	var list = Content.topics(info["grade"], info["subject"])
	for i in list.size():
		if list[i]["id"] == topic_id:
			if i == 0:
				return true
			return topic_state(list[i - 1]["id"], id)["status"] == "done"
	return false


func unlock_by_parent(topic_id: String, id: String = "") -> void:
	topic_state(topic_id, id)["parent_unlocked"] = true
	save_progress(id)


func is_done(topic_id: String, id: String = "") -> bool:
	return topic_state(topic_id, id)["status"] == "done"


var _seen = {}   # кэш (не сохраняется): id профиля -> {task_id: true}


func seen_tasks() -> Dictionary:
	var id = current_id()
	if not _seen.has(id):
		var s = {}
		for a in progress()["answers"]:
			s[a["t"]] = true
		_seen[id] = s
	return _seen[id]


## outcome: first | corrected | hint | failed ; mode: lesson | story | review | assigned | mult
func record_answer(task: Dictionary, outcome: String, given: String, tries: int, hint_used: bool, mode: String) -> void:
	var pr = progress()
	var seen = seen_tasks()
	var first_seen = not seen.has(task["id"])
	seen[task["id"]] = true
	var rec = {"t": task["id"], "topic": task.get("topic", ""), "subj": task.get("subject", ""), "g": task.get("grade", 0),
		"ts": int(Time.get_unix_time_from_system()), "o": outcome, "tries": tries, "hint": hint_used, "mode": mode,
		"fs": first_seen, "given": given.substr(0, 120)}
	pr["answers"].append(rec)
	if pr["answers"].size() > MAX_ANSWERS:
		pr["answers"] = pr["answers"].slice(pr["answers"].size() - MAX_ANSWERS)
	var errs: Dictionary = pr["errors"]
	var correct_text = AnswerChecker.answer_text(task)
	if outcome != "first":
		# ошибка (или решение не с первой попытки) попадает в журнал
		if not errs.has(task["id"]):
			errs[task["id"]] = {"topic": task.get("topic", ""), "subj": task.get("subject", ""), "g": task.get("grade", 0),
				"prompt": str(task.get("prompt", "")).substr(0, 200), "given": given.substr(0, 120), "correct": correct_text.substr(0, 160),
				"explanation": str(task.get("explanation", "")).substr(0, 300), "first_ts": rec["ts"], "last_ts": rec["ts"],
				"count": 1, "repeats": 0, "repeat_ok": 0, "status": "open", "kind": outcome}
		else:
			var e: Dictionary = errs[task["id"]]
			e["count"] = int(e["count"]) + (0 if mode in ["review", "assigned"] else 1)
			e["last_ts"] = rec["ts"]
			e["given"] = given.substr(0, 120)
			if mode in ["review", "assigned"]:
				e["repeats"] = int(e["repeats"]) + 1
				e["status"] = "open"
				e["repeat_ok"] = 0
	elif errs.has(task["id"]):
		var e2: Dictionary = errs[task["id"]]
		e2["last_ts"] = rec["ts"]
		if mode in ["review", "assigned"]:
			e2["repeats"] = int(e2["repeats"]) + 1
			e2["repeat_ok"] = int(e2.get("repeat_ok", 0)) + 1
			e2["status"] = "fixed" if int(e2["repeat_ok"]) >= 2 else "improving"
		else:
			e2["repeat_ok"] = int(e2.get("repeat_ok", 0)) + 1
			e2["status"] = "fixed" if int(e2["repeat_ok"]) >= 2 else "improving"
	# сохраняем после каждого ответа: при внезапном закрытии теряется не больше одного ответа
	save_progress()


func finish_lesson(topic_id: String, solved: int, first_ok: int, total: int, minutes: float, mode: String) -> Dictionary:
	var st = topic_state(topic_id)
	var was_done: bool = st["status"] == "done"
	st["sessions"] = int(st["sessions"]) + 1
	st["last"] = int(Time.get_unix_time_from_system())
	var ratio = float(solved) / maxf(1.0, float(total))
	var first_ratio = float(first_ok) / maxf(1.0, float(total))
	var stars = 0
	if ratio >= 0.6:
		stars = 1
		if first_ratio >= 0.7:
			stars = 2
		if first_ratio >= 0.9:
			stars = 3
	st["best"] = maxi(int(st["best"]), int(round(ratio * 100)))
	if stars > int(st["stars"]):
		progress()["stars"] = int(progress().get("stars", 0)) + stars - int(st["stars"])
		st["stars"] = stars
	if ratio >= 0.6:
		st["status"] = "done"
	elif st["status"] != "done":
		st["status"] = "started"
	progress()["sessions"].append({"topic": topic_id, "ts": int(Time.get_unix_time_from_system()), "min": snappedf(minutes, 0.1),
		"total": total, "solved": solved, "first": first_ok, "mode": mode})
	if progress()["sessions"].size() > 1500:
		progress()["sessions"] = progress()["sessions"].slice(-1500)
	save_progress()
	return {"stars": stars, "newly_done": (not was_done) and st["status"] == "done", "ratio": ratio}


func add_minutes(minutes: float) -> void:
	var d: Dictionary = progress()["daily"]
	var key = Time.get_date_string_from_system()
	d[key] = snappedf(float(d.get(key, 0.0)) + minutes, 0.01)


func minutes_today() -> float:
	return float(progress()["daily"].get(Time.get_date_string_from_system(), 0.0))


func open_errors(grade: int = 0) -> Array:
	if grade == 0:
		grade = current_grade()
	var out = []
	var errs: Dictionary = progress()["errors"]
	for tid in errs:
		var e: Dictionary = errs[tid]
		if int(e.get("g", 0)) == grade and e["status"] != "fixed" and str(e.get("topic", "")) != "mult":
			out.append(tid)
	return out


func award(ach_id: String) -> bool:
	var a: Dictionary = progress()["achievements"]
	if a.has(ach_id):
		return false
	a[ach_id] = int(Time.get_unix_time_from_system())
	save_progress()
	achievement.emit(ach_id)
	return true
