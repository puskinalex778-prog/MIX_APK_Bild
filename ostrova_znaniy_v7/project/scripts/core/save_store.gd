class_name SaveStore
extends RefCounted
## Надёжная запись JSON-файлов: временный файл → проверка → замена,
## резервная копия предыдущей версии (.bak), контрольная сумма SHA-256.
## Формат файла: {"format": "...", "version": N, "saved_at": ..., "sha256": "...", "data": {...}}

const ROOT := "user://save"


static func ensure_dir() -> void:
	if not DirAccess.dir_exists_absolute(ROOT):
		DirAccess.make_dir_recursive_absolute(ROOT)


static func path(name: String) -> String:
	return ROOT + "/" + name


static func checksum(data) -> String:
	# нормализуем через круговое преобразование (int/float в JSON неразличимы)
	var canon = JSON.parse_string(JSON.stringify(data))
	return JSON.stringify(canon, "", true).sha256_text()


static func write(name: String, format: String, version: int, data) -> bool:
	ensure_dir()
	var p = path(name)
	var tmp = p + ".tmp"
	var wrapper = {"format": format, "version": version, "saved_at": Time.get_unix_time_from_system(), "sha256": checksum(data), "data": data}
	var text = JSON.stringify(wrapper)
	var f = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("SaveStore: не удалось открыть " + tmp)
		return false
	f.store_string(text)
	f.flush()
	f.close()
	# проверяем записанное
	var check = _read_raw(tmp)
	if check.is_empty() or check.get("sha256", "") != wrapper["sha256"]:
		push_error("SaveStore: проверка записи не прошла для " + name)
		DirAccess.remove_absolute(tmp)
		return false
	if FileAccess.file_exists(p):
		var bak = p + ".bak"
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(bak)
		DirAccess.rename_absolute(p, bak)
	var err = DirAccess.rename_absolute(tmp, p)
	if err != OK:
		push_error("SaveStore: rename error %d" % err)
		return false
	return true


static func _read_raw(p: String) -> Dictionary:
	if not FileAccess.file_exists(p):
		return {}
	var f = FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}
	var txt = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func _valid(w: Dictionary, format: String) -> bool:
	if w.is_empty() or w.get("format", "") != format or not w.has("data"):
		return false
	return w.get("sha256", "") == checksum(w["data"])


## Возвращает {"data": ..., "version": N, "source": "main"|"backup"} или {} если ничего нет.
static func read(name: String, format: String) -> Dictionary:
	var p = path(name)
	var w = _read_raw(p)
	if _valid(w, format):
		return {"data": w["data"], "version": int(w.get("version", 1)), "source": "main"}
	var b = _read_raw(p + ".bak")
	if _valid(b, format):
		push_warning("SaveStore: основной файл %s повреждён, восстановлено из резервной копии" % name)
		return {"data": b["data"], "version": int(b.get("version", 1)), "source": "backup"}
	if FileAccess.file_exists(p):
		# сохраняем повреждённый файл для анализа, чтобы не перезаписать молча
		DirAccess.rename_absolute(p, p + ".corrupt_%d" % int(Time.get_unix_time_from_system()))
	return {}


static func remove(name: String) -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var p = path(name) + suffix
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
