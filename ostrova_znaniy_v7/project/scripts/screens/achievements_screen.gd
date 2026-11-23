extends BaseScreen
## Достижения ребёнка.


func setup(_params: Dictionary) -> void:
	make_layout("night", 28, 0.0)
	Achievements.check_all()
	root.add_child(UIKit.top_bar("🏆 Достижения", Router.back))
	var got: Dictionary = Profiles.progress()["achievements"]
	root.add_child(UIKit.label("Получено %d из %d" % [got.size(), Achievements.LIST.size()], 24, Color.WHITE, "bold", HORIZONTAL_ALIGNMENT_CENTER))
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var i = 0
	for a in Achievements.LIST:
		var has = got.has(a["id"])
		var p = UIKit.panel(Color(1, 1, 1, 0.96) if has else Color(1, 1, 1, 0.35), 22, 14)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v = UIKit.vbox(4)
		v.add_child(UIKit.label(a["icon"] if has else "🔒", 44, UIKit.C_TEXT, "body", HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(UIKit.label(a["title"], 22, UIKit.C_TEXT, "bold", HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(UIKit.label(a["desc"], 17, UIKit.C_MUTED, "body", HORIZONTAL_ALIGNMENT_CENTER))
		p.add_child(v)
		grid.add_child(p)
		UIKit.pop_in.call_deferred(p, i * 0.03)
		i += 1
	root.add_child(UIKit.scroll(grid))
