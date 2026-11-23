extends TaskView
## «Построй рисунок к выражению»: ребёнок кнопками задаёт число рядов и предметов в ряду.

var rows = 1
var cols = 1
var _grid: Control
var _info: Label


func build() -> void:
	_grid = Control.new()
	_grid.custom_minimum_size = Vector2(560, 300)
	_grid.draw.connect(_draw_grid)
	add_child(_grid)
	_info = UIKit.label("", 26, UIKit.C_TEXT, "bold", HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_info)
	var ctr = UIKit.hbox(30)
	ctr.alignment = BoxContainer.ALIGNMENT_CENTER
	ctr.add_child(_stepper("Рядов", _change_rows))
	ctr.add_child(_stepper("В ряду", _change_cols))
	add_child(ctr)
	add_child(make_check_button(true))
	_upd()


func _stepper(title: String, cb: Callable) -> Control:
	var h = UIKit.hbox(8)
	h.add_child(UIKit.nowrap(UIKit.label(title, 22, UIKit.C_TEXT, "bold")))
	var m = UIKit.button("−", Color("fa5252"), 32, Vector2(70, 66))
	m.pressed.connect(cb.bind(-1))
	var p = UIKit.button("+", UIKit.C_OK, 32, Vector2(70, 66))
	p.pressed.connect(cb.bind(1))
	h.add_child(m)
	h.add_child(p)
	return h


func _change_rows(d: int) -> void:
	if locked:
		return
	rows = clampi(rows + d, 1, 6)
	_upd()


func _change_cols(d: int) -> void:
	if locked:
		return
	cols = clampi(cols + d, 1, 10)
	_upd()


func _upd() -> void:
	_info.text = "%d ряд(а/ов) по %d  →  %d · %d = %d" % [rows, cols, cols, rows, rows * cols]
	_grid.queue_redraw()
	Audio.sfx("pop")


func _draw_grid() -> void:
	var cell = minf(_grid.size.x / 10.0, _grid.size.y / 6.0)
	var o = Vector2((_grid.size.x - cell * cols) * 0.5, (_grid.size.y - cell * rows) * 0.5)
	var emoji = UIKit.font("emoji")
	for y in rows:
		for x in cols:
			var p = o + Vector2(x, y) * cell
			_grid.draw_string(emoji, p + Vector2(cell * 0.12, cell * 0.78), "🍎", HORIZONTAL_ALIGNMENT_LEFT, -1, int(cell * 0.7))


func _on_check() -> void:
	if locked:
		return
	locked = true
	var want_r = int(task.get("rows", 1))
	var want_c = int(task.get("cols", 1))
	var ok = (rows == want_r and cols == want_c) or (rows == want_c and cols == want_r)
	submitted.emit(ok, "%d×%d" % [rows, cols])


func reveal_answer() -> void:
	super.reveal_answer()
	rows = int(task.get("rows", 1))
	cols = int(task.get("cols", 1))
	_upd()
