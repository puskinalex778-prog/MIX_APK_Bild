class_name ParentAuth
extends RefCounted
## Родительский PIN. Хранится только хэш SHA-256 с солью (это не шифрование данных:
## файлы прогресса не зашифрованы). Ограничение частых попыток: после 5 неверных
## вводов блокировка на 60 с, далее время блокировки удваивается (до 15 минут).
## Восстановление: одноразовый код восстановления, который показывается при создании PIN.

const FORMAT := "ostrova-parent"
const VERSION := 1
const MAX_TRIES := 5

static var _data := {}
static var _loaded := false


static func _load() -> void:
	if _loaded:
		return
	var r = SaveStore.read("parent.json", FORMAT)
	_data = r.get("data", {}) if not r.is_empty() else {}
	_loaded = true


static func _save() -> void:
	SaveStore.write("parent.json", FORMAT, VERSION, _data)


static func reset_cache() -> void:
	_loaded = false
	_data = {}


static func has_pin() -> bool:
	_load()
	return _data.get("pin_hash", "") != ""


static func _hash(secret: String, salt: String) -> String:
	var s = salt + ":" + secret
	for i in 2000:
		s = s.sha256_text()
	return s


static func _rand_hex(n: int) -> String:
	return Crypto.new().generate_random_bytes(n).hex_encode()


static func valid_pin_format(pin: String) -> bool:
	if pin.length() != 4:
		return false
	for ch in pin:
		if not ch in "0123456789":
			return false
	return true


## Создаёт PIN и возвращает код восстановления (показать один раз).
static func set_pin(pin: String) -> String:
	_load()
	var salt = _rand_hex(8)
	_data["salt"] = salt
	_data["pin_hash"] = _hash(pin, salt)
	var alphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
	var bytes = Crypto.new().generate_random_bytes(8)
	var code = ""
	for b in bytes:
		code += alphabet[b % alphabet.length()]
	code = code.substr(0, 4) + "-" + code.substr(4, 4)
	_data["rec_salt"] = _rand_hex(8)
	_data["rec_hash"] = _hash(code.replace("-", ""), _data["rec_salt"])
	_data["tries"] = 0
	_data["lock_until"] = 0
	_data["lock_level"] = 0
	_save()
	return code


static func change_pin(old_pin: String, new_pin: String) -> String:
	if check_pin(old_pin) != "ok":
		return ""
	return set_pin(new_pin)


static func lock_seconds_left() -> int:
	_load()
	return maxi(0, int(_data.get("lock_until", 0)) - int(Time.get_unix_time_from_system()))


## "ok" | "wrong" | "locked"
static func check_pin(pin: String) -> String:
	_load()
	if lock_seconds_left() > 0:
		return "locked"
	if _hash(pin, _data.get("salt", "")) == _data.get("pin_hash", "-"):
		_data["tries"] = 0
		_data["lock_level"] = 0
		_save()
		return "ok"
	_data["tries"] = int(_data.get("tries", 0)) + 1
	if int(_data["tries"]) >= MAX_TRIES:
		var lvl = int(_data.get("lock_level", 0))
		var secs = mini(60 * int(pow(2, lvl)), 900)
		_data["lock_until"] = int(Time.get_unix_time_from_system()) + secs
		_data["lock_level"] = lvl + 1
		_data["tries"] = 0
		_save()
		return "locked"
	_save()
	return "wrong"


static func tries_left() -> int:
	_load()
	return MAX_TRIES - int(_data.get("tries", 0))


static func check_recovery(code: String) -> bool:
	_load()
	if lock_seconds_left() > 0:
		return false
	var c = code.strip_edges().to_upper().replace("-", "").replace(" ", "")
	var ok = _hash(c, _data.get("rec_salt", "")) == _data.get("rec_hash", "-")
	if not ok:
		_data["tries"] = int(_data.get("tries", 0)) + 1
		if int(_data["tries"]) >= MAX_TRIES:
			_data["lock_until"] = int(Time.get_unix_time_from_system()) + 300
			_data["tries"] = 0
		_save()
	return ok


# --- родительские настройки (интервал перерывов, дневной лимит) ---
static func get_setting(key: String, def):
	_load()
	return _data.get("settings", {}).get(key, def)


static func set_setting(key: String, value) -> void:
	_load()
	if not _data.has("settings"):
		_data["settings"] = {}
	_data["settings"][key] = value
	_save()
