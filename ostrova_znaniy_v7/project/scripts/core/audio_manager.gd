extends Node
## Звук: фоновая музыка (с плавной сменой), эффекты интерфейса, озвучка английских слов
## (встроенные файлы или системный синтезатор речи) и чтение заданий вслух (системный TTS).

const MUSIC := {
	"menu": "res://assets/audio/music/menu.ogg",
	"map": "res://assets/audio/music/map.ogg",
	"lesson": "res://assets/audio/music/lesson.ogg",
	"break": "res://assets/audio/music/break.ogg",
}
const SFX := ["click", "correct", "wrong", "achievement", "star", "whoosh", "pop", "unlock", "chime", "step", "levelup", "tick", "sparkle"]

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active: AudioStreamPlayer
var _current_track = ""
var _sfx_players: Array[AudioStreamPlayer] = []
var _voice: AudioStreamPlayer
var _sfx_cache = {}
var _voice_index = {}
var _tts_voice_en = ""
var _tts_voice_ru = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_music_a = _make_player("Music")
	_music_b = _make_player("Music")
	_active = _music_a
	for i in 6:
		_sfx_players.append(_make_player("SFX"))
	_voice = _make_player("Speech")
	for s in SFX:
		var p = "res://assets/audio/sfx/%s.ogg" % s
		if ResourceLoader.exists(p):
			_sfx_cache[s] = load(p)
	var vi = "res://assets/audio/voice/index.json"
	if FileAccess.file_exists(vi):
		var d = JSON.parse_string(FileAccess.open(vi, FileAccess.READ).get_as_text())
		if typeof(d) == TYPE_DICTIONARY:
			_voice_index = d
	_pick_tts_voices()
	apply_settings()
	Settings.changed.connect(apply_settings)


func _ensure_buses() -> void:
	for n in ["Music", "SFX", "Speech"]:
		if AudioServer.get_bus_index(n) == -1:
			AudioServer.add_bus()
			var idx = AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, n)
			AudioServer.set_bus_send(idx, "Master")


func _make_player(bus: String) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _lin(v: float) -> float:
	return linear_to_db(maxf(v, 0.0001))


func apply_settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), _lin(Settings.master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), _lin(Settings.music_volume * 0.55))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), _lin(Settings.sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Speech"), _lin(Settings.speech_volume))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not Settings.music_on)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not Settings.sfx_on)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Speech"), not Settings.speech_on)


func music(track: String) -> void:
	if track == _current_track:
		return
	_current_track = track
	var path: String = MUSIC.get(track, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	var next = _music_b if _active == _music_a else _music_a
	next.stream = stream
	next.volume_db = -40.0
	next.play()
	var tw = create_tween().set_parallel(true)
	tw.tween_property(next, "volume_db", 0.0, 1.2)
	if _active.playing:
		tw.tween_property(_active, "volume_db", -40.0, 1.2)
		var old = _active
		tw.chain().tween_callback(old.stop)
	_active = next


func stop_music() -> void:
	_current_track = ""
	_music_a.stop()
	_music_b.stop()


func pause_all(paused: bool) -> void:
	_music_a.stream_paused = paused
	_music_b.stream_paused = paused


func sfx(name: String, pitch: float = 1.0) -> void:
	if not Settings.sfx_on or not _sfx_cache.has(name):
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = _sfx_cache[name]
			p.pitch_scale = pitch
			p.play()
			return
	_sfx_players[0].stream = _sfx_cache[name]
	_sfx_players[0].play()


# ---------------- речь ----------------
func _pick_tts_voices() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	var en = DisplayServer.tts_get_voices_for_language("en")
	if en.size() > 0:
		_tts_voice_en = en[0]
	var ru = DisplayServer.tts_get_voices_for_language("ru")
	if ru.size() > 0:
		_tts_voice_ru = ru[0]


func has_builtin_voice(text: String) -> bool:
	return _voice_index.has(text)


func tts_available(lang: String) -> bool:
	return (lang == "en" and _tts_voice_en != "") or (lang == "ru" and _tts_voice_ru != "")


## Произносит английское слово/фразу. Возвращает false, если озвучить нечем.
func speak_en(text: String) -> bool:
	if not Settings.speech_on:
		return false
	var use_system = Settings.english_voice == "system" and _tts_voice_en != ""
	if not use_system and _voice_index.has(text):
		var p = "res://assets/audio/voice/" + str(_voice_index[text])
		if ResourceLoader.exists(p):
			_voice.stream = load(p)
			_voice.play()
			return true
	if _tts_voice_en != "":
		DisplayServer.tts_stop()
		DisplayServer.tts_speak(text, _tts_voice_en, int(Settings.speech_volume * 100), 1.0, 0.9)
		return true
	if _voice_index.has(text):
		_voice.stream = load("res://assets/audio/voice/" + str(_voice_index[text]))
		_voice.play()
		return true
	return false


## Читает текст задания вслух (если в системе есть русский голос).
func speak_ru(text: String) -> bool:
	if not Settings.speech_on or _tts_voice_ru == "":
		return false
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text.replace("___", "пропуск").replace("·", "умножить на"), _tts_voice_ru, int(Settings.speech_volume * 100), 1.0, 1.0)
	return true


func stop_speech() -> void:
	_voice.stop()
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		DisplayServer.tts_stop()
