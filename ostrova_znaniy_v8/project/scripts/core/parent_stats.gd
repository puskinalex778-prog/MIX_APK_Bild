class_name ParentStats
extends RefCounted
## Расчёт статистики для родителя. Точность первых ответов считается только по первому
## знакомству ребёнка с заданием в уроке/сюжете (поле fs), поэтому повторные тренировки
## и исправления её не завышают.

const TIPS := {
	"math": "Решите вместе 3–4 похожих задания, проговаривая каждый шаг вслух. Используйте предметы: счётные палочки, монеты, линейку, часы.",
	"rus": "Проговорите правило своими словами и подберите вместе 5–6 примеров. Для орфограмм ищите проверочные слова; пишите слова на карточках.",
	"world": "Обсудите тему на прогулке или по картинкам в энциклопедии; попросите ребёнка объяснить её вам, как учитель.",
	"eng": "Повторяйте слова вслух по 5 минут в день, используйте карточки с картинками и игру «покажи и назови».",
	"read": "Прочитайте произведение (или отрывок) вместе, обсудите героев и их поступки, попросите пересказать по плану.",
}


static func summarize(answers: Array) -> Dictionary:
	var s = {"answers": 0, "first_seen": 0, "first_ok": 0, "corrected": 0, "hint": 0, "failed": 0, "review_ok": 0, "review_total": 0, "hints_used": 0}
	for a in answers:
		s["answers"] += 1
		if a.get("hint", false):
			s["hints_used"] += 1
		var o: String = a.get("o", "")
		if a.get("mode", "") in ["review", "assigned"]:
			s["review_total"] += 1
			if o == "first":
				s["review_ok"] += 1
			continue
		if a.get("mode", "") == "mult":
			continue
		if a.get("fs", false):
			s["first_seen"] += 1
			if o == "first":
				s["first_ok"] += 1
		if o == "corrected":
			s["corrected"] += 1
		elif o == "hint":
			s["hint"] += 1
		elif o == "failed":
			s["failed"] += 1
	s["accuracy"] = int(round(100.0 * s["first_ok"] / s["first_seen"])) if s["first_seen"] > 0 else -1
	return s


static func by_topic(pid: String, grade: int) -> Dictionary:
	var out = {}
	for a in Profiles.progress(pid)["answers"]:
		if int(a.get("g", 0)) != grade:
			continue
		var t: String = a.get("topic", "")
		if not out.has(t):
			out[t] = []
		out[t].append(a)
	return out


static func subject_overview(pid: String, grade: int) -> Array:
	var bt = by_topic(pid, grade)
	var res = []
	for s in Content.SUBJECTS:
		var topics = Content.topics(grade, s)
		var done = 0
		var started = 0
		var all = []
		for t in topics:
			var st = Profiles.topic_state(t["id"], pid)
			if st["status"] == "done":
				done += 1
			elif st["status"] == "started":
				started += 1
			all.append_array(bt.get(t["id"], []))
		var sm = summarize(all)
		sm["subject"] = s
		sm["topics"] = topics.size()
		sm["done"] = done
		sm["started"] = started
		res.append(sm)
	return res


static func topic_rows(pid: String, grade: int, subject: String) -> Array:
	var bt = by_topic(pid, grade)
	var rows = []
	for t in Content.topics(grade, subject):
		var st = Profiles.topic_state(t["id"], pid)
		var sm = summarize(bt.get(t["id"], []))
		sm["id"] = t["id"]
		sm["title"] = t["title"]
		sm["status"] = st["status"]
		sm["stars"] = st["stars"]
		sm["sessions"] = st["sessions"]
		sm["open"] = Profiles.is_topic_open(t["id"], pid)
		sm["parent_unlocked"] = st["parent_unlocked"]
		rows.append(sm)
	return rows


static func difficult(pid: String, grade: int) -> Array:
	var out = []
	var errs: Dictionary = Profiles.progress(pid)["errors"]
	for s in Content.SUBJECTS:
		for r in topic_rows(pid, grade, s):
			var open_err = 0
			for tid in errs:
				if errs[tid]["topic"] == r["id"] and errs[tid]["status"] != "fixed":
					open_err += 1
			r["open_errors"] = open_err
			r["subject"] = s
			if (r["first_seen"] >= 5 and r["accuracy"] < 60) or open_err >= 3:
				out.append(r)
	out.sort_custom(func(a, b): return a["accuracy"] < b["accuracy"])
	return out


static func mastered(pid: String, grade: int) -> Array:
	var out = []
	for s in Content.SUBJECTS:
		for r in topic_rows(pid, grade, s):
			if r["status"] == "done" and r["first_seen"] >= 8 and r["accuracy"] >= 85:
				r["subject"] = s
				out.append(r)
	return out


static func recommendation(row: Dictionary) -> String:
	var s: String = row.get("subject", "math")
	var acc: int = row.get("accuracy", -1)
	var why = "точность первых ответов %d%%" % acc if acc >= 0 else "много ошибок"
	if row.get("open_errors", 0) > 0:
		why += ", неисправленных ошибок: %d" % row["open_errors"]
	return "Повторить тему «%s» (%s: %s). Как помочь: %s Затем запустите в игре повторение этой темы." % [row["title"], Content.SUBJECT_TITLES[s], why, TIPS[s]]


static func fmt_time(ts: int) -> String:
	if ts <= 0:
		return "—"
	var d = Time.get_datetime_dict_from_unix_time(ts + _tz_offset())
	return "%02d.%02d.%d %02d:%02d" % [d["day"], d["month"], d["year"], d["hour"], d["minute"]]


static func _tz_offset() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60
