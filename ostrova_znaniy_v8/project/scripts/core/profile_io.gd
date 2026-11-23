class_name ProfileIO
extends RefCounted
## Экспорт и импорт детского профиля.
## Файл — JSON без исполняемого кода и путей к ресурсам. Родительский PIN не экспортируется.
## Файл НЕ зашифрован: содержит имя ребёнка и историю обучения.

const FORMAT := "ostrova-profile-export"
const VERSION := 1
const MIN_COMPAT := 1
const MAX_BYTES := 4 * 1024 * 1024
const ALLOWED_PROGRESS_KEYS := ["grades", "answers", "errors", "sessions", "mult", "achievements", "assigned", "daily", "stars"]


static func file_name_for(profile: Dictionary) -> String:
	var n = str(profile.get("name", "profile"))
	var safe = ""
	for ch in n:
		if ch.is_valid_identifier() or ch in "0123456789" or (ch.unicode_at(0) >= 0x0400 and ch.unicode_at(0) <= 0x04FF):
			safe += ch
	if safe == "":
		safe = "profile"
	var d = Time.get_date_string_from_system()
	return "ostrova_%s_%s.json" % [safe, d]


static func export_text(profile_id: String) -> String:
	var p: Dictionary = Profiles.get_profile(profile_id)
	if p.is_empty():
		return ""
	var prog: Dictionary = Profiles.progress(profile_id).duplicate(true)
	var clean = {}
	for k in ALLOWED_PROGRESS_KEYS:
		if prog.has(k):
			clean[k] = prog[k]
	var payload = {
		"profile": {"id": p["id"], "name": p["name"], "gender": p["gender"], "avatar": p["avatar"], "grade": p["grade"],
			"created": p.get("created", 0)},
		"progress": clean,
	}
	var wrapper = {"format": FORMAT, "version": VERSION, "app_version": ProjectSettings.get_setting("application/config/version", "1.0.0"),
		"exported_at": Time.get_datetime_string_from_system(), "sha256": SaveStore.checksum(payload), "payload": payload}
	return JSON.stringify(wrapper, "\t")


## Разбор и проверка. Возвращает {"ok": bool, "error": "...", "payload": {...}, "preview": {...}}
static func parse(text: String) -> Dictionary:
	if text.length() == 0:
		return {"ok": false, "error": "Файл пустой."}
	if text.to_utf8_buffer().size() > MAX_BYTES:
		return {"ok": false, "error": "Файл слишком большой (больше 4 МБ)."}
	var j = JSON.parse_string(text)
	if typeof(j) != TYPE_DICTIONARY:
		return {"ok": false, "error": "Файл повреждён или это не файл профиля."}
	if j.get("format", "") != FORMAT:
		return {"ok": false, "error": "Это не файл профиля «Островов Знаний»."}
	var ver = int(j.get("version", 0))
	if ver > VERSION:
		return {"ok": false, "error": "Файл создан более новой версией игры (формат %d). Обновите игру." % ver}
	if ver < MIN_COMPAT:
		return {"ok": false, "error": "Формат файла устарел и не поддерживается."}
	var payload = j.get("payload")
	if typeof(payload) != TYPE_DICTIONARY:
		return {"ok": false, "error": "В файле нет данных профиля."}
	if j.get("sha256", "") != SaveStore.checksum(payload):
		return {"ok": false, "error": "Контрольная сумма не совпадает: файл повреждён или изменён."}
	var res = sanitize(payload)
	if not res["ok"]:
		return res
	return {"ok": true, "payload": res["payload"], "preview": preview(res["payload"])}


## Строгая очистка: только известные поля и типы.
static func sanitize(payload: Dictionary) -> Dictionary:
	var p = payload.get("profile")
	if typeof(p) != TYPE_DICTIONARY:
		return {"ok": false, "error": "Нет описания профиля."}
	var id = str(p.get("id", ""))
	var re = RegEx.new()
	re.compile("^p[0-9a-f]{16}$")
	if re.search(id) == null:
		return {"ok": false, "error": "Неверный идентификатор профиля."}
	var prof = {
		"id": id, "name": Profiles.sanitize_name(str(p.get("name", ""))),
		"gender": "girl" if str(p.get("gender", "")) == "girl" else "boy",
		"avatar": str(p.get("avatar", "")) if str(p.get("avatar", "")) in Profiles.AVATARS else Profiles.AVATARS[0],
		"grade": clampi(int(p.get("grade", 2)), 2, 4), "created": int(p.get("created", 0)),
	}
	var pr = payload.get("progress", {})
	if typeof(pr) != TYPE_DICTIONARY:
		return {"ok": false, "error": "Нет данных прогресса."}
	var prog = {}
	for k in ALLOWED_PROGRESS_KEYS:
		if pr.has(k):
			prog[k] = pr[k]
	prog = _deep_clean(prog, 0)
	return {"ok": true, "payload": {"profile": prof, "progress": prog}}


## Оставляет только числа, строки (≤500 символов), bool, массивы и словари (глубина ≤ 6).
static func _deep_clean(v, depth: int):
	if depth > 6:
		return null
	match typeof(v):
		TYPE_DICTIONARY:
			var out = {}
			for k in v:
				var ck = _deep_clean(v[k], depth + 1)
				if ck != null:
					out[str(k).substr(0, 80)] = ck
			return out
		TYPE_ARRAY:
			var arr = []
			for x in v:
				var cx = _deep_clean(x, depth + 1)
				if cx != null:
					arr.append(cx)
			return arr
		TYPE_STRING:
			return str(v).substr(0, 500)
		TYPE_INT, TYPE_FLOAT, TYPE_BOOL:
			return v
		_:
			return null


static func preview(payload: Dictionary) -> Dictionary:
	var prof: Dictionary = payload["profile"]
	var prog: Dictionary = payload["progress"]
	var done = 0
	for g in prog.get("grades", {}):
		var topics = prog["grades"][g].get("topics", {})
		if typeof(topics) == TYPE_DICTIONARY:
			for t in topics:
				if typeof(topics[t]) == TYPE_DICTIONARY and topics[t].get("status", "") == "done":
					done += 1
	return {"name": prof["name"], "grade": prof["grade"], "topics_done": done, "answers": prog.get("answers", []).size(),
		"stars": int(prog.get("stars", 0)), "exists": not Profiles.get_profile(prof["id"]).is_empty()}


## mode: "replace" — заменить профиль с тем же id; "copy" — добавить как новый профиль.
## Другие профили не затрагиваются.
static func apply(payload: Dictionary, mode: String) -> String:
	var prof: Dictionary = payload["profile"].duplicate(true)
	var prog: Dictionary = payload["progress"].duplicate(true)
	var target_id: String = prof["id"]
	if mode == "copy" or Profiles.get_profile(target_id).is_empty():
		if not Profiles.get_profile(target_id).is_empty():
			target_id = Profiles.new_id()
		var arr: Array = Profiles.list()
		prof["id"] = target_id
		if mode == "copy" and not Profiles.get_profile(payload["profile"]["id"]).is_empty():
			prof["name"] = Profiles.sanitize_name(prof["name"] + " (копия)")
		prof["updated"] = Time.get_unix_time_from_system()
		arr.append(prof)
		Profiles.save_index()
	else:
		Profiles.update_profile(target_id, prof)
	prog["profile_id"] = target_id
	Profiles.replace_progress(target_id, prog)
	return target_id


# ---------- файловые операции ----------
static func write_file(path: String, text: String) -> bool:
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.close()
	return true


static func read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "Файл не найден."}
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"ok": false, "error": "Нет доступа к файлу."}
	if f.get_length() > MAX_BYTES:
		f.close()
		return {"ok": false, "error": "Файл слишком большой (больше 4 МБ)."}
	var t = f.get_as_text()
	f.close()
	return {"ok": true, "text": t}


## Компактный текстовый код профиля для переноса через буфер обмена (запасной способ).
static func to_clipboard_code(profile_id: String) -> String:
	var t = export_text(profile_id)
	return "OSTROVA1:" + Marshalls.raw_to_base64(t.to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP))


static func from_clipboard_code(code: String) -> Dictionary:
	code = code.strip_edges()
	if not code.begins_with("OSTROVA1:"):
		return {"ok": false, "error": "Это не код профиля. Код должен начинаться с OSTROVA1:"}
	var raw = Marshalls.base64_to_raw(code.substr(9))
	if raw.size() == 0 or raw.size() > MAX_BYTES:
		return {"ok": false, "error": "Код повреждён."}
	var dec = raw.decompress_dynamic(MAX_BYTES, FileAccess.COMPRESSION_GZIP)
	if dec.size() == 0:
		return {"ok": false, "error": "Код повреждён."}
	return parse(dec.get_string_from_utf8())
