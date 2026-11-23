extends BaseScreen
## Прохождение заданий: урок по теме, шаг сюжета, работа над ошибками, задания от родителя.
## До 2 попыток на задание. Подсказка — по нажатию на героя, но не раньше чем через 15 с.
## Исходы: first (верно с первой попытки), corrected (исправил после ошибки),
## hint (решил после подсказки), failed (не решил — показан ответ).

const HINT_DELAY := 15.0
const SESSION_SIZE := 12

var mode = "lesson"      # lesson | story | review | assigned
var topic_id = ""
var queue: Array = []
var idx = 0
var tries = 0
var hint_used = false
var task_time = 0.0
var started_at = 0.0
var solved = 0
var first_ok = 0
var results: Array = []

var mentor: CharacterView
var hint_btn: Button
var bubble: PanelContainer
var bubble_label: Label
var card_box: VBoxContainer
var progress: ProgressBar
var progress_lbl: Label
var feedback: PanelContainer
var view: TaskView
var _scroll: ScrollContainer


func setup(params: Dictionary) -> void:
	set_meta("learning", true)
	mode = str(params.get("mode", "lesson"))
	topic_id = str(params.get("topic", ""))
	started_at = Time.get_unix_time_from_system()
	queue = _build_queue(params)
	make_layout("calm", 18, 0.0)
	Audio.music("lesson")
	var subj = "math"
	if topic_id != "":
		subj = Content.topic_info(topic_id).get("subject", "math")
	elif queue.size() > 0:
		subj = str(queue[0].get("subject", "math"))
	var title = Content.topic_info(topic_id).get("title", "") if topic_id != "" else ("Работа над ошибками" if mode == "review" else "Задания от родителей")
	var bar = UIKit.top_bar(title, Router.back)
	progress = ProgressBar.new()
	progress.custom_minimum_size = Vector2(220, 26)
	progress.show_percentage = false
	progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progress_lbl = UIKit.nowrap(UIKit.label("", 22, Color.WHITE, "bold"))
	bar.add_child(progress_lbl)
	bar.add_child(progress)
	var speak = UIKit.button("🔈", Color("1098ad"), 28, Vector2(72, 64))
	speak.tooltip_text = "Прочитать задание вслух"
	speak.pressed.connect(_read_aloud)
	bar.add_child(speak)
	root.add_child(bar)
	var body = UIKit.hbox(14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left = UIKit.vbox(8)
	left.custom_minimum_size = Vector2(190, 0)
	bubble = UIKit.panel(Color.WHITE, 18, 12)
	bubble_label = UIKit.label("", 19)
	bubble_label.custom_minimum_size = Vector2(170, 0)
	bubble.add_child(bubble_label)
	bubble.visible = false
	left.add_child(bubble)
	left.add_child(UIKit.spacer(false))
	mentor = CharacterView.new(Story.CHARACTERS.get(subj, {"kind": "lumik"})["kind"], Vector2(180, 220))
	mentor.tapped.connect(_on_mentor_tap)
	left.add_child(mentor)
	hint_btn = UIKit.button("💡 15", Color("adb5bd"), 22, Vector2(180, 60))
	hint_btn.pressed.connect(_on_mentor_tap)
	left.add_child(hint_btn)
	body.add_child(left)
	var card = UIKit.panel(Color(1, 1, 1, 0.97), 28, 22)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_box = UIKit.vbox(14)
	_scroll = UIKit.scroll(card_box)
	card.add_child(_scroll)
	body.add_child(card)
	root.add_child(body)
	feedback = UIKit.panel(Color.WHITE, 22, 16)
	feedback.visible = false
	root.add_child(feedback)
	if queue.is_empty():
		_show_empty()
	else:
		_show_task()


func _build_queue(params: Dictionary) -> Array:
	var out = []
	match mode:
		"review":
			for tid in TaskView.shuffled(Profiles.open_errors()):
				var t = Content.task(tid)
				if not t.is_empty():
					out.append(t)
				if out.size() >= SESSION_SIZE:
					break
		"assigned":
			var ids: Array = Profiles.progress().get("assigned", [])
			for tid in ids:
				var t2 = Content.task(str(tid))
				if not t2.is_empty() and int(t2.get("grade", 0)) == Profiles.current_grade():
					out.append(t2)
			out = TaskView.shuffled(out)
		_:
			var all: Array = Content.tasks(topic_id)
			var seen = Profiles.seen_tasks()
			var errs: Dictionary = Profiles.progress()["errors"]
			var unseen = []
			var weak = []
			var rest = []
			for t in all:
				if not seen.has(t["id"]):
					unseen.append(t)
				elif errs.has(t["id"]) and errs[t["id"]]["status"] != "fixed":
					weak.append(t)
				else:
					rest.append(t)
			unseen.shuffle()
			weak.shuffle()
			rest.shuffle()
			out = unseen + weak + rest
			var n = SESSION_SIZE if params.get("full", false) == false else all.size()
			out = out.slice(0, mini(n, out.size()))
			out.shuffle()
	return out


func _process(delta: float) -> void:
	if queue.is_empty() or idx >= queue.size() or feedback.visible:
		return
	task_time += delta
	var left = HINT_DELAY - task_time
	if left > 0.0:
		hint_btn.text = "💡 %d" % int(ceil(left))
	elif hint_btn.text != "💡 Подсказка":
		hint_btn.text = "💡 Подсказка"
		UIKit.apply_button_color(hint_btn, UIKit.C_GOLD, Color("5a3b00"), 20, 6)
		mentor.set_state("wave", 1.2)


func _show_task() -> void:
	for c in card_box.get_children():
		c.queue_free()
	feedback.visible = false
	bubble.visible = false
	tries = 0
	hint_used = false
	task_time = 0.0
	hint_btn.text = "💡 15"
	UIKit.apply_button_color(hint_btn, Color("a9adc4"), Color.WHITE, 20, 6)
	var t: Dictionary = queue[idx]
	progress.max_value = queue.size()
	progress.value = idx
	progress_lbl.text = "%d / %d" % [idx + 1, queue.size()]
	if mode in ["review", "assigned"]:
		card_box.add_child(UIKit.label(Content.topic_info(t["topic"]).get("title", ""), 18, UIKit.C_MUTED, "bold"))
	if t.has("text"):
		var tp = UIKit.panel(Color("fff9db"), 16, 16)
		var tl = UIKit.label(str(t["text"]), 22, UIKit.C_TEXT, "body")
		tp.add_child(tl)
		card_box.add_child(tp)
	var pl = UIKit.label(str(t.get("prompt", "")), 30, UIKit.C_TEXT, "bold", HORIZONTAL_ALIGNMENT_CENTER)
	card_box.add_child(pl)
	if t.has("pic"):
		var pv = PicView.new(t["pic"])
		pv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_box.add_child(pv)
	view = TaskView.create(t)
	view.submitted.connect(_on_submitted)
	card_box.add_child(view)
	mentor.set_state("idle")
	UIKit.pop_in(pl)
	_scroll.scroll_vertical = 0


func _on_mentor_tap() -> void:
	if feedback.visible or queue.is_empty() or idx >= queue.size():
		return
	if task_time < HINT_DELAY:
		mentor.set_state("think", 1.5)
		bubble_label.text = "Подумай сам%s ещё %d с. Если не получится — я помогу!" % [UIKit.gender_word("", "а"), int(ceil(HINT_DELAY - task_time))]
		bubble.visible = true
		return
	hint_used = true
	mentor.set_state("explain", 3.0)
	mentor.talking = true
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(mentor):
			mentor.talking = false)
	bubble_label.text = "💡 " + str(queue[idx].get("hint", "Подумай ещё раз."))
	bubble.visible = true
	UIKit.pop_in(bubble)
	Audio.sfx("sparkle")


func _on_submitted(ok: bool, given: String) -> void:
	var t: Dictionary = queue[idx]
	tries += 1
	if ok:
		Audio.sfx("correct")
		mentor.set_state("happy", 1.6)
		ConfettiBurst.burst_on(self, get_viewport_rect().size * Vector2(0.56, 0.45), 48, 0.9)
		var outcome = "first"
		if hint_used:
			outcome = "hint"
		elif tries > 1:
			outcome = "corrected"
		solved += 1
		if outcome == "first":
			first_ok += 1
		_record(t, outcome, given)
		_feedback(true, ["Верно!", "Отлично!", "Молодец!" if UIKit.gender_word("b", "g") == "b" else "Умница!", "Так держать!", "Супер!"][randi() % 5], str(t.get("explanation", "")))
	elif tries < 2:
		Audio.sfx("wrong")
		mentor.set_state("support", 2.0)
		_feedback_retry()
	else:
		Audio.sfx("wrong")
		mentor.set_state("support", 2.5)
		view.reveal_answer()
		_record(t, "failed", given)
		_feedback(false, "Ничего страшного! Вот правильный ответ:", "Ответ: %s\n%s" % [AnswerChecker.answer_text(t), str(t.get("explanation", ""))])


func _record(t: Dictionary, outcome: String, given: String) -> void:
	var m = mode
	if mode == "lesson" or mode == "story":
		m = mode
	Profiles.record_answer(t, outcome, given, tries, hint_used, m)
	results.append({"t": t["id"], "o": outcome})


func _clear_feedback() -> void:
	for c in feedback.get_children():
		c.queue_free()


func _feedback_retry() -> void:
	_clear_feedback()
	feedback.add_theme_stylebox_override("panel", UIKit.sb(UIKit.C_BAD_L, 22, 3, UIKit.C_BAD, 4, 16))
	var h = UIKit.hbox(16)
	var l = UIKit.label("Не совсем так. Попробуй ещё раз! Можно нажать на помощника за подсказкой.", 24, UIKit.C_TEXT, "bold")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var b = UIKit.button("Ещё раз ↺", UIKit.C_BAD, 26, Vector2(220, 70))
	b.pressed.connect(func():
		feedback.visible = false
		view.retry())
	h.add_child(b)
	feedback.add_child(h)
	feedback.visible = true
	UIKit.pop_in(feedback)


func _feedback(ok: bool, head: String, text: String) -> void:
	_clear_feedback()
	feedback.add_theme_stylebox_override("panel", UIKit.sb(UIKit.C_OK_L if ok else Color("fff3bf"), 22, 3, UIKit.C_OK if ok else Color("f59f00"), 4, 16))
	var h = UIKit.hbox(16)
	var v = UIKit.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UIKit.label(head, 28, UIKit.C_OK if ok else Color("e67700"), "title"))
	var expl = UIKit.label(text, 21)
	v.add_child(expl)
	h.add_child(v)
	var last = idx >= queue.size() - 1
	var b = UIKit.button("Готово ✓" if last else "Дальше →", UIKit.C_PRIMARY, 26, Vector2(220, 76))
	b.pressed.connect(_next)
	h.add_child(b)
	feedback.add_child(h)
	feedback.visible = true
	UIKit.pop_in(feedback)


func _next() -> void:
	idx += 1
	Audio.sfx("whoosh")
	if idx >= queue.size():
		_finish()
	else:
		_show_task()


func _finish() -> void:
	var minutes = (Time.get_unix_time_from_system() - started_at) / 60.0
	var res = {"stars": 0, "newly_done": false}
	if topic_id != "" and mode in ["lesson", "story"]:
		res = Profiles.finish_lesson(topic_id, solved, first_ok, queue.size(), minutes, mode)
		if first_ok == queue.size() and queue.size() >= 10:
			Profiles.award("perfect")
	else:
		if mode == "assigned":
			Profiles.progress()["assigned"] = []
		Profiles.progress()["sessions"].append({"topic": mode, "ts": int(Time.get_unix_time_from_system()), "min": snappedf(minutes, 0.1),
			"total": queue.size(), "solved": solved, "first": first_ok, "mode": mode})
		Profiles.save_progress()
	if mode == "story" and res.get("newly_done", false):
		var gd = Profiles.grade_data()
		gd["story_step"] = int(gd["story_step"]) + 1
		Profiles.save_progress()
	Achievements.check_all()
	_show_result(res)


func _show_result(res: Dictionary) -> void:
	for c in card_box.get_children():
		c.queue_free()
	feedback.visible = false
	bubble.visible = false
	progress.value = queue.size()
	mentor.set_state("finish")
	Audio.sfx("star" if res.get("stars", 0) > 0 or topic_id == "" else "chime")
	if res.get("stars", 0) > 0 or topic_id == "":
		ConfettiBurst.burst_on(self, get_viewport_rect().size * Vector2(0.55, 0.35), 95, 1.15)
	var stars = int(res.get("stars", 0))
	if topic_id != "":
		var srow = UIKit.label("★".repeat(stars) + "☆".repeat(3 - stars), 72, Color("fab005"), "bold", HORIZONTAL_ALIGNMENT_CENTER)
		card_box.add_child(srow)
		UIKit.pop_in(srow)
	var head = "Тема пройдена!" if res.get("newly_done", false) else ("Хорошая работа!" if solved * 10 >= queue.size() * 6 else "Попробуем ещё раз?")
	if topic_id == "":
		head = "Повторение завершено!"
	card_box.add_child(UIKit.label(head, 40, UIKit.C_TEXT, "title", HORIZONTAL_ALIGNMENT_CENTER))
	var corrected = 0
	var hinted = 0
	for r in results:
		if r["o"] == "corrected":
			corrected += 1
		elif r["o"] == "hint":
			hinted += 1
	card_box.add_child(UIKit.label("С первой попытки: %d из %d\nИсправлено после ошибки: %d   С подсказкой: %d" % [first_ok, queue.size(), corrected, hinted], 24, UIKit.C_TEXT, "body", HORIZONTAL_ALIGNMENT_CENTER))
	if topic_id != "" and not res.get("newly_done", false) and not Profiles.is_done(topic_id):
		card_box.add_child(UIKit.label("Чтобы пройти тему, нужно решить не меньше 6 заданий из 10.", 20, UIKit.C_MUTED, "body", HORIZONTAL_ALIGNMENT_CENTER))
	var row = UIKit.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if mode == "story":
		var nb = UIKit.button("📖 Дальше по сюжету", Color("f08c00"), 24, Vector2(300, 76))
		nb.pressed.connect(func(): Router.go("story", {}, true))
		row.add_child(nb)
	if topic_id != "":
		var again = UIKit.button("↺ Ещё раз", Color("5c7cfa"), 24, Vector2(220, 76))
		again.pressed.connect(func(): Router.go("lesson", {"topic": topic_id, "mode": mode}, true))
		row.add_child(again)
	var back = UIKit.button("🗺️ На карту", UIKit.C_OK, 24, Vector2(220, 76))
	back.pressed.connect(func(): Router.reset_to("map"))
	row.add_child(back)
	card_box.add_child(row)
	queue_redraw()
	queue = []


func _show_empty() -> void:
	card_box.add_child(UIKit.label("Здесь пока нечего повторять — ошибок нет! 🎉", 30, UIKit.C_TEXT, "title", HORIZONTAL_ALIGNMENT_CENTER))
	var b = UIKit.button("🗺️ На карту", UIKit.C_OK, 24, Vector2(240, 76))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): Router.reset_to("map"))
	card_box.add_child(b)


func _read_aloud() -> void:
	if queue.is_empty() or idx >= queue.size():
		return
	var t: Dictionary = queue[idx]
	var txt = str(t.get("text", "")) + " " + str(t.get("prompt", ""))
	if not Audio.speak_ru(txt):
		UIKit.toast(self, "Чтение вслух недоступно: в системе нет русского голоса или речь выключена.", UIKit.C_TEXT, 3.0)


func on_back() -> bool:
	if queue.is_empty() or idx >= queue.size():
		return false
	confirm("Выйти из задания? Ответы уже сохранены, но тема не будет засчитана.", "Выйти", func():
		queue = []
		Router.back())
	return true
