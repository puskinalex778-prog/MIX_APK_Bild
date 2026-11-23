extends Node
## Забота о здоровье: учёт активного времени, перерывы и дневной лимит.
## Значения по умолчанию взяты из СанПиН 1.2.3685-21 (непрерывная работа с электронными
## средствами обучения): планшет — 10 мин (1–2 классы), 15 мин (3–4 классы);
## суммарно в день (ПК) — 40 мин (1–2), 50 мин (3–4). Родитель может изменить значения.

signal break_due
signal daily_limit_reached

var active = false          # идёт учебная активность (урок, тренировка)
var _since_break = 0.0      # секунд с последнего перерыва
var _accum = 0.0
var _paused = false
var _limit_fired = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func default_interval(grade: int) -> int:
	return 10 if grade <= 2 else 15


func default_daily(grade: int) -> int:
	return 40 if grade <= 2 else 50


func interval_min() -> int:
	return int(ParentAuth.get_setting("break_interval", default_interval(Profiles.current_grade())))


func daily_limit_min() -> int:
	return int(ParentAuth.get_setting("daily_limit", default_daily(Profiles.current_grade())))


func breaks_enabled() -> bool:
	return bool(ParentAuth.get_setting("breaks_enabled", true))


func set_paused(p: bool) -> void:
	_paused = p


func _process(delta: float) -> void:
	if not active or _paused or Profiles.current_id() == "":
		return
	_since_break += delta
	_accum += delta
	if _accum >= 30.0:
		Profiles.add_minutes(_accum / 60.0)
		_accum = 0.0
		Profiles.save_progress()
	if breaks_enabled() and _since_break >= interval_min() * 60.0:
		_since_break = 0.0
		break_due.emit()
	var lim = daily_limit_min()
	if lim > 0 and not _limit_fired and Profiles.minutes_today() >= lim:
		_limit_fired = true
		daily_limit_reached.emit()


func break_taken() -> void:
	_since_break = 0.0


func minutes_since_break() -> float:
	return _since_break / 60.0


func reset_limit_flag() -> void:
	_limit_fired = false


func flush() -> void:
	if _accum > 0.0:
		Profiles.add_minutes(_accum / 60.0)
		_accum = 0.0
