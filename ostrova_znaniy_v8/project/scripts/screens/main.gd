extends Control
## Корень приложения: тема, слои экранов, системная кнопка «Назад», пауза/восстановление,
## перерывы и уведомления о достижениях.

var screen_host: Control
var overlay_host: Control


func _ready() -> void:
	var th = UIKit.build_theme()
	get_tree().root.theme = th
	theme = th
	Settings.apply_device_scale(get_tree().root)
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)
	screen_host = Control.new()
	UIKit.full_rect(screen_host)
	add_child(screen_host)
	overlay_host = Control.new()
	overlay_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(overlay_host)
	add_child(overlay_host)
	Router.setup(screen_host, overlay_host)
	Wellbeing.break_due.connect(_on_break_due)
	Wellbeing.daily_limit_reached.connect(_on_daily_limit)
	Profiles.achievement.connect(_on_achievement)
	if not Settings.onboarding_done or not Profiles.has_profiles():
		Router.go("welcome")
	elif Profiles.list().size() > 1 or Profiles.current_id() == "":
		Router.go("profiles")
	else:
		Profiles.select(Profiles.current_id())
		Router.go("map")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_handle_back()
		NOTIFICATION_WM_CLOSE_REQUEST:
			_save_all()
			get_tree().quit()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_save_all()
			Audio.pause_all(true)
			Wellbeing.set_paused(true)
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			Audio.pause_all(false)
			Wellbeing.set_paused(false)


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		_handle_back()


func _handle_back() -> void:
	# сначала закрываем верхнее модальное окно, если оно разрешает
	if overlay_host.get_child_count() > 0:
		var top = overlay_host.get_child(overlay_host.get_child_count() - 1)
		if top.has_method("on_back"):
			top.on_back()
		elif not top.has_meta("modal_lock"):
			top.queue_free()
		return
	Router.back()


func _save_all() -> void:
	Wellbeing.flush()
	Profiles.save_progress()
	Settings.save()


func _on_break_due() -> void:
	if Router.has_overlay():
		return
	var br = load("res://scripts/screens/break_screen.gd").new()
	br.set_meta("modal_lock", true)
	Router.overlay(br)


func _on_daily_limit() -> void:
	var br = load("res://scripts/screens/break_screen.gd").new()
	br.daily_limit = true
	br.set_meta("modal_lock", true)
	Router.overlay(br)


func _on_achievement(id: String) -> void:
	var a = Achievements.info(id)
	Audio.sfx("achievement")
	UIKit.toast(overlay_host, "%s  Достижение: %s" % [a["icon"], a["title"]], Color("7048e8"), 3.0)
