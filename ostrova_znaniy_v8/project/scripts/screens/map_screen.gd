extends BaseScreen
## Карта островов: персонаж ребёнка ходит к островам предметов; сюжет, мастерская
## умножения, повторение ошибок, достижения, настройки, родительский раздел.

const ISLAND_POS := {"math": Vector2(0.14, 0.38), "rus": Vector2(0.32, 0.48), "read": Vector2(0.50, 0.36), "world": Vector2(0.68, 0.48), "eng": Vector2(0.84, 0.36)}

var avatar: CharacterView
var lumik: CharacterView
var _walking = false
var _layer: Control


func setup(params: Dictionary) -> void:
	set_meta("learning", false)
	var grade = Profiles.current_grade()
	bg = Scenery.new("sky")
	UIKit.full_rect(bg)
	add_child(bg)
	for s in Content.SUBJECTS:
		var lst = Content.topics(grade, s)
		var done = 0
		for t in lst:
			if Profiles.is_done(t["id"]):
				done += 1
		bg.islands.append({"pos": ISLAND_POS[s] + Vector2(0, -0.01), "color": UIKit.SUBJECT_COLORS[s].lightened(0.35), "lit": float(done) / maxf(1, lst.size()), "scale": 0.85, "subj": s})
	Audio.music("map")
	_layer = Control.new()
	UIKit.full_rect(_layer)
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_layer)
	await get_tree().process_frame
	_build_islands()
	_build_hud()
	if params.get("intro", false) and Profiles.grade_data()["story_step"] == 0:
		get_tree().create_timer(0.6).timeout.connect(_open_story)


func _open_story() -> void:
	if is_instance_valid(self) and is_inside_tree():
		Router.go("story")


func _vp() -> Vector2:
	return get_viewport_rect().size


func _build_islands() -> void:
	var sz = _vp()
	var grade = Profiles.current_grade()
	for s in Content.SUBJECTS:
		var p: Vector2 = (ISLAND_POS[s] + Vector2(0, 0.10)) * sz
		var b = UIKit.button("%s\n%s" % [UIKit.SUBJECT_ICONS[s], UIKit.SUBJECT_ISLANDS[s]], UIKit.SUBJECT_COLORS[s], 20, Vector2(190, 92))
		b.position = p - Vector2(95, 46)
		var lst = Content.topics(grade, s)
		var done = 0
		for t in lst:
			if Profiles.is_done(t["id"]):
				done += 1
		b.tooltip_text = "%s: %d из %d тем" % [Content.SUBJECT_TITLES[s], done, lst.size()]
		var subj: String = s
		b.pressed.connect(func(): _walk_to(p + Vector2(0, 60), func(): Router.go("subject", {"subject": subj})))
		_layer.add_child(b)
		var badge_p = PanelContainer.new()
		badge_p.add_theme_stylebox_override("panel", UIKit.sb(Color(0.12, 0.14, 0.40, 0.52), 14, 1, Color(1, 1, 1, 0.22), 0, 8))
		badge_p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_p.add_child(UIKit.nowrap(UIKit.label("⭐ %d/%d" % [done, lst.size()], 16, Color.WHITE, "bold", HORIZONTAL_ALIGNMENT_CENTER)))
		badge_p.position = p + Vector2(-46, 52)
		badge_p.custom_minimum_size = Vector2(92, 0)
		_layer.add_child(badge_p)
	var pr = Profiles.current()
	avatar = CharacterView.new(str(pr.get("avatar", "kid_a")), Vector2(120, 150))
	avatar.position = Vector2(sz.x * 0.86 - 60, sz.y * 0.80 - 150)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(avatar)
	lumik = CharacterView.new("lumik", Vector2(80, 100))
	lumik.position = avatar.position + Vector2(-70, 20)
	lumik.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lumik)
	avatar.set_state("wave", 1.5)


func _walk_to(target: Vector2, then: Callable) -> void:
	if _walking:
		return
	_walking = true
	var dest = target - Vector2(60, 150)
	dest.y = clampf(dest.y, 80, _vp().y - 160)
	avatar.facing = 1.0 if dest.x >= avatar.position.x else -1.0
	avatar.set_state("walk")
	lumik.set_state("walk")
	Audio.sfx("step")
	var dur = 0.2 if Settings.reduce_motion else clampf(avatar.position.distance_to(dest) / 500.0, 0.35, 1.1)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(avatar, "position", dest, dur)
	tw.tween_property(lumik, "position", dest + Vector2(-70 * avatar.facing, 20), dur * 1.1)
	tw.chain().tween_callback(func():
		_walking = false
		avatar.set_state("idle")
		lumik.set_state("idle")
		then.call())


func _build_hud() -> void:
	var pr = Profiles.current()
	var top = UIKit.hbox(12)
	var who = UIKit.button("👤 %s · %d кл." % [pr.get("name", ""), int(pr.get("grade", 2))], Color(0.12, 0.14, 0.40, 0.58), 22, Vector2(0, 62))
	who.pressed.connect(func(): Router.go("profiles"))
	top.add_child(who)
	top.add_child(UIKit.spacer())
	var stars = PanelContainer.new()
	stars.add_theme_stylebox_override("panel", UIKit.sb(Color(0.12, 0.14, 0.40, 0.58), 18, 1, Color(1, 1, 1, 0.25), 6, 12))
	stars.add_child(UIKit.nowrap(UIKit.label("⭐ %d" % int(Profiles.progress().get("stars", 0)), 24, Color.WHITE, "bold")))
	top.add_child(stars)
	for item in [["🏆", "achievements"], ["⚙️", "settings"], ["👪", "parent"], ["ℹ️", "info"]]:
		var b = UIKit.button(item[0], Color(0.12, 0.14, 0.40, 0.58), 26, Vector2(66, 62))
		var target: String = item[1]
		b.pressed.connect(func(): Router.go(target))
		top.add_child(b)
	var hud = UIKit.vbox(0)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top)
	var sp = UIKit.spacer(false)
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(sp)
	var m = UIKit.margin(hud, 20, 14, 20, 16)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(m)
	add_child(m)
	var bottom = UIKit.hbox(14)
	var grade = Profiles.current_grade()
	var route = Content.story_route(grade)
	var step = int(Profiles.grade_data()["story_step"])
	var story = UIKit.button("📖 Сюжет: %s (%d/%d)" % [Story.CHAPTERS[grade]["title"], mini(step, route.size()), route.size()], UIKit.C_ORANGE, 22, Vector2(0, 74))
	story.pressed.connect(func(): Router.go("story"))
	bottom.add_child(story)
	var mult = UIKit.button("✖️ Мастерская умножения", UIKit.C_PURPLE, 22, Vector2(0, 74))
	mult.pressed.connect(func(): Router.go("mult"))
	bottom.add_child(mult)
	var n_err = Profiles.open_errors().size()
	var assigned: Array = Profiles.progress().get("assigned", [])
	if n_err > 0 or assigned.size() > 0:
		var rv = UIKit.button("🛠️ Работа над ошибками (%d)" % (n_err if assigned.is_empty() else assigned.size()), UIKit.C_PRIMARY, 22, Vector2(0, 74))
		rv.pressed.connect(func(): Router.go("lesson", {"mode": "assigned" if assigned.size() > 0 else "review"}))
		bottom.add_child(rv)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(bottom)


func on_root_back() -> void:
	confirm("Выйти из игры?", "Выйти", func(): get_tree().quit())
