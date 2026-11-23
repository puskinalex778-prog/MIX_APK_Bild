extends Node
## Настройки приложения (общие для устройства). Сохраняются в user://save/settings.json

signal changed

const FORMAT := "ostrova-settings"
const VERSION := 1

var music_on = true
var sfx_on = true
var speech_on = true
var music_volume = 0.6
var sfx_volume = 0.8
var speech_volume = 1.0
var master_volume = 1.0
var reduce_motion = false
var english_voice = "builtin"   # builtin | system
var device = "tablet"           # tablet | phone
var onboarding_done = false


func _ready() -> void:
	load_settings()


func to_dict() -> Dictionary:
	return {
		"music_on": music_on, "sfx_on": sfx_on, "speech_on": speech_on,
		"music_volume": music_volume, "sfx_volume": sfx_volume, "speech_volume": speech_volume,
		"master_volume": master_volume, "reduce_motion": reduce_motion, "english_voice": english_voice,
		"device": device, "onboarding_done": onboarding_done,
	}


func from_dict(d: Dictionary) -> void:
	music_on = bool(d.get("music_on", music_on))
	sfx_on = bool(d.get("sfx_on", sfx_on))
	speech_on = bool(d.get("speech_on", speech_on))
	music_volume = clampf(float(d.get("music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(d.get("sfx_volume", sfx_volume)), 0.0, 1.0)
	speech_volume = clampf(float(d.get("speech_volume", speech_volume)), 0.0, 1.0)
	master_volume = clampf(float(d.get("master_volume", master_volume)), 0.0, 1.0)
	reduce_motion = bool(d.get("reduce_motion", reduce_motion))
	english_voice = str(d.get("english_voice", english_voice))
	if english_voice not in ["builtin", "system"]:
		english_voice = "builtin"
	device = str(d.get("device", device))
	if device not in ["tablet", "phone"]:
		device = "tablet"
	onboarding_done = bool(d.get("onboarding_done", onboarding_done))


func load_settings() -> void:
	var r = SaveStore.read("settings.json", FORMAT)
	if not r.is_empty():
		from_dict(r["data"])


func save() -> void:
	SaveStore.write("settings.json", FORMAT, VERSION, to_dict())
	changed.emit()


func apply_device_scale(win: Window) -> void:
	# На телефоне элементы крупнее: уменьшаем «виртуальный» размер экрана.
	win.content_scale_factor = 1.18 if device == "phone" else 1.0
