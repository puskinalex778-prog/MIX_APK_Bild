extends Node
## Визуальная проверка: проходит по экранам и сохраняет скриншоты в user://shots.

var main: Node
var n := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://shots")
	var only := OS.get_environment("SHOTS")
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(1.5)
	await _shot("00_start")
	if not Profiles.has_profiles():
		Settings.onboarding_done = true
		Profiles.create_profile("Аня", "girl", "kid_d", int(OS.get_environment("GRADE") if OS.get_environment("GRADE") != "" else "2"))
	Profiles.select(Profiles.current_id())
	Router.reset_to("welcome")
	await _wait(1.0)
	await _shot("01_welcome")
	Router.reset_to("map")
	await _wait(1.5)
	await _shot("02_map")
	Router.go("story")
	await _wait(1.2)
	await _shot("03_story")
	Router.go("subject", {"subject": "math"})
	await _wait(1.0)
	await _shot("04_subject")
	var subj := ["math", "rus", "world", "eng", "read"]
	for s in subj:
		var tl := Content.topics(Profiles.current_grade(), s)
		if tl.is_empty():
			continue
		Router.go("lesson", {"topic": tl[min(3, tl.size() - 1)]["id"], "mode": "lesson"})
		await _wait(1.0)
		await _shot("05_lesson_" + s)
	# по одному заданию каждого типа
	var seen := {}
	for s in subj:
		for t in Content.topics(Profiles.current_grade(), s):
			for task in Content.tasks(t["id"]):
				var ty: String = task["type"] + ("_pic_" + str(task["pic"]["k"]) if task.has("pic") else "")
				if seen.has(ty):
					continue
				seen[ty] = true
				var scr = Router.current_screen()
				if scr and scr.has_method("_show_task"):
					scr.queue = [task]
					scr.idx = 0
					scr._show_task()
					await _wait(0.6)
					await _shot("06_type_" + ty)
	Router.go("mult")
	await _wait(1.0)
	await _shot("07_mult")
	var m = Router.current_screen()
	m._explorer()
	await _wait(0.8)
	await _shot("08_mult_explorer")
	m._program()
	await _wait(0.5)
	await _shot("09_mult_program")
	m._start_training(4, [], "test")
	await _wait(0.5)
	await _shot("10_mult_training")
	Router.go("parent")
	await _wait(0.8)
	await _shot("11_parent_pin")
	var p = Router.current_screen()
	p._dashboard()
	await _wait(0.6)
	await _shot("12_parent_overview")
	for tb in ["topics", "errors", "skills", "io", "settings", "profiles"]:
		p.tab = tb
		p._dashboard()
		await _wait(0.5)
		await _shot("13_parent_" + tb)
	Router.go("settings")
	await _wait(0.6)
	await _shot("14_settings")
	Router.go("achievements")
	await _wait(0.8)
	await _shot("15_achievements")
	Router.go("info")
	await _wait(0.6)
	await _shot("16_info")
	var br = load("res://scripts/screens/break_screen.gd").new()
	Router.overlay(br)
	await _wait(0.5)
	br._next()
	await _wait(1.5)
	await _shot("17_break")
	br.queue_free()
	print("SHOTS DONE ", n)
	get_tree().quit()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://shots/%s.png" % name)
	n += 1
