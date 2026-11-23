extends BaseScreen
## Список разделов и тем предмета. Открытые темы можно проходить в любом порядке;
## закрытую тему открывает только родитель (в родительском разделе).

var subject = "math"


func setup(params: Dictionary) -> void:
	subject = str(params.get("subject", "math"))
	make_layout("sky", 24, 0.25)
	var grade = Profiles.current_grade()
	root.add_child(UIKit.top_bar("%s %s" % [UIKit.SUBJECT_ICONS[subject], Content.SUBJECT_TITLES[subject]], Router.back))
	var mentor_row = UIKit.hbox(12)
	var mentor = CharacterView.new(Story.CHARACTERS[subject]["kind"], Vector2(130, 150))
	mentor.set_state("wave", 1.5)
	mentor_row.add_child(mentor)
	var hello = UIKit.panel(Color(1, 1, 1, 0.92), 22, 16)
	hello.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hello.add_child(UIKit.label("%s: «Выбирай открытую тему! Темы с замком откроются по порядку, когда пройдёшь предыдущие. Для возврата к сюжету нажми «Сюжет»." % Story.CHARACTERS[subject]["name"], 22))
	mentor_row.add_child(hello)
	var to_story = UIKit.button("📖 Сюжет", Color("f08c00"), 22, Vector2(160, 70))
	to_story.pressed.connect(func(): Router.go("story"))
	mentor_row.add_child(to_story)
	root.add_child(mentor_row)
	var list = UIKit.vbox(14)
	for c in Content.sections(grade, subject):
		var sec = UIKit.label(c["title"], 26, Color.WHITE, "title")
		list.add_child(sec)
		var grid = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for t in c["topics"]:
			if Content.tasks(t["id"]).is_empty():
				continue
			grid.add_child(_topic_card(t))
		list.add_child(grid)
	root.add_child(UIKit.scroll(list))


func _topic_card(t: Dictionary) -> Control:
	var tid: String = t["id"]
	var open = Profiles.is_topic_open(tid)
	var st = Profiles.topic_state(tid)
	var col = Color.WHITE if open else Color("dee2e6")
	var b = UIKit.chip_button("", col, UIKit.C_TEXT, 22, UIKit.SUBJECT_COLORS[subject] if open else Color("adb5bd"))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(240, 92)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.clip_text = true
	var stars = ""
	for i in 3:
		stars += "★" if i < int(st["stars"]) else "☆"
	var status = "🔒 " if not open else ("✅ " if st["status"] == "done" else ("▶ " if st["status"] == "started" else ""))
	b.text = "%s%s\n%s  ·  %d заданий" % [status, t["title"], stars, Content.tasks(tid).size()]
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		if open:
			Router.go("lesson", {"topic": tid, "mode": "lesson"})
		else:
			Audio.sfx("wrong")
			UIKit.toast(self, "Эта тема откроется после предыдущей. Открыть её раньше может родитель.", UIKit.C_TEXT, 3.0))
	return b
