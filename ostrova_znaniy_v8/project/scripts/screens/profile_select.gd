extends BaseScreen
## Выбор детского профиля (несколько детей на одном устройстве).


func setup(_params: Dictionary) -> void:
	make_layout("sky", 32)
	Audio.music("menu")
	root.add_child(UIKit.title("Кто сегодня играет?", 44))
	var flow = UIKit.flow(24)
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for p in Profiles.list():
		var card = UIKit.panel(Color(1, 1, 1, 0.95), 26, 16)
		var v = UIKit.vbox(6)
		var ch = CharacterView.new(str(p["avatar"]), Vector2(170, 200))
		var pid: String = p["id"]
		ch.tapped.connect(func(): _pick(pid))
		v.add_child(ch)
		v.add_child(UIKit.label(str(p["name"]), 28, UIKit.C_TEXT, "title", HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(UIKit.label("%d класс" % int(p["grade"]), 20, UIKit.C_MUTED, "body", HORIZONTAL_ALIGNMENT_CENTER))
		var b = UIKit.button("Играть", UIKit.C_OK, 24, Vector2(170, 60))
		b.pressed.connect(func(): _pick(pid))
		v.add_child(b)
		card.add_child(v)
		flow.add_child(card)
	root.add_child(UIKit.scroll(flow))
	var bottom = UIKit.hbox(16)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	var add = UIKit.button("➕ Новый профиль", Color("7048e8"), 24, Vector2(300, 70))
	add.pressed.connect(func(): Router.go("welcome", {"add": true}))
	bottom.add_child(add)
	var par = UIKit.button("👪 Для родителей", Color("495057"), 24, Vector2(300, 70))
	par.pressed.connect(func(): Router.go("parent"))
	bottom.add_child(par)
	root.add_child(bottom)


func _pick(id: String) -> void:
	Profiles.select(id)
	Wellbeing.reset_limit_flag()
	Router.reset_to("map")


func on_root_back() -> void:
	confirm("Выйти из игры?", "Выйти", func(): get_tree().quit())
