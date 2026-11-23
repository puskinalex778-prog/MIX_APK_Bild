extends BaseScreen
## Сюжетный режим: диалоги персонажей между темами. Темы, уже пройденные отдельно,
## засчитываются и в сюжете (возврат к сюжету в любой момент).

var lines: Array = []
var li = 0
var topic_id = ""
var finale = false
var speaker_view: CharacterView
var hero: CharacterView
var lumik: CharacterView
var name_lbl: Label
var text_lbl: Label
var next_btn: Button
var speaker_slot: Control


func setup(_params: Dictionary) -> void:
	var grade = Profiles.current_grade()
	var route = Content.story_route(grade)
	var gd = Profiles.grade_data()
	var step = int(gd["story_step"])
	while step < route.size() and Profiles.is_done(route[step]):
		step += 1
	gd["story_step"] = step
	Profiles.save_progress()
	make_layout("night" if step >= route.size() else "calm", 24, 0.0)
	Audio.music("menu")
	root.add_child(UIKit.top_bar("📖 %s · шаг %d из %d" % [Story.CHAPTERS[grade]["title"], mini(step + 1, route.size()), route.size()], Router.back))
	if step >= route.size():
		finale = true
		lines = Story.FINALE.get(grade, Story.FINALE[2])
		Profiles.award("story_end")
	else:
		topic_id = route[step]
		lines = Story.lines_before(step, topic_id, grade)
	var stage = UIKit.hbox(10)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero = CharacterView.new(str(Profiles.current().get("avatar", "kid_a")), Vector2(220, 280))
	hero.size_flags_vertical = Control.SIZE_SHRINK_END
	lumik = CharacterView.new("lumik", Vector2(150, 190))
	lumik.size_flags_vertical = Control.SIZE_SHRINK_END
	stage.add_child(hero)
	stage.add_child(lumik)
	stage.add_child(UIKit.spacer())
	speaker_slot = UIKit.hbox(0)
	speaker_slot.size_flags_vertical = Control.SIZE_SHRINK_END
	stage.add_child(speaker_slot)
	root.add_child(stage)
	var box = UIKit.panel(Color(1, 1, 1, 0.96), 26, 22)
	var v = UIKit.vbox(6)
	name_lbl = UIKit.label("", 24, UIKit.C_PRIMARY, "title")
	text_lbl = UIKit.label("", 28, UIKit.C_TEXT, "body")
	text_lbl.custom_minimum_size = Vector2(0, 80)
	v.add_child(name_lbl)
	v.add_child(text_lbl)
	var h = UIKit.hbox(12)
	h.add_child(UIKit.spacer())
	var skip = UIKit.button("Пропустить ⏭", Color("868e96"), 20, Vector2(200, 64))
	skip.pressed.connect(func():
		li = lines.size() - 1
		_show_line())
	h.add_child(skip)
	next_btn = UIKit.button("Дальше →", UIKit.C_PRIMARY, 26, Vector2(240, 70))
	next_btn.pressed.connect(_advance)
	h.add_child(next_btn)
	v.add_child(h)
	box.add_child(v)
	root.add_child(box)
	_show_line()


func _show_line() -> void:
	var ln: Array = lines[li]
	var who: String = ln[0]
	var info: Dictionary = Story.CHARACTERS.get(who, {"name": "?", "kind": "lumik"})
	name_lbl.text = info["name"]
	text_lbl.text = Story.fill(str(ln[1]))
	lumik.talking = who == "lumik"
	if who == "lumik":
		lumik.set_state("explain", 2.5)
	for c in speaker_slot.get_children():
		c.queue_free()
	if who != "lumik":
		speaker_view = CharacterView.new(info["kind"], Vector2(230, 280))
		speaker_view.facing = -1.0
		speaker_view.talking = true
		speaker_view.set_state("explain", 2.5)
		speaker_slot.add_child(speaker_view)
		get_tree().create_timer(2.5).timeout.connect(func():
			if is_instance_valid(speaker_view):
				speaker_view.talking = false)
	hero.set_state("happy" if finale else "idle", 1.5)
	if li == lines.size() - 1:
		next_btn.text = "🗺️ На карту" if finale else "Начать тему ▶"
		UIKit.apply_button_color(next_btn, UIKit.C_OK, Color.WHITE, 20, 6)
		if finale:
			Audio.sfx("star")
			ConfettiBurst.burst_on(self, get_viewport_rect().size * Vector2(0.5, 0.35), 110, 1.2)
	Audio.sfx("pop")
	UIKit.pop_in(text_lbl)


func _advance() -> void:
	if li < lines.size() - 1:
		li += 1
		_show_line()
		return
	lumik.talking = false
	if finale:
		Router.reset_to("map")
	else:
		Router.go("lesson", {"topic": topic_id, "mode": "story"}, true)
