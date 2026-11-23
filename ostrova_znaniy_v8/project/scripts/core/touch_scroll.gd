extends Node
## Прокрутка пальцем (свайпом) для всех списков игры.
## Стандартный ScrollContainer не прокручивается, если палец лёг на кнопку или карточку:
## кнопка «забирает» касание. Здесь касание отслеживается глобально: если палец сдвинулся
## дальше порога, список прокручивается вслед за пальцем (с инерцией), а нажатие кнопки
## под пальцем отменяется — случайных нажатий при прокрутке не бывает.
## Списки регистрируются в группе "touch_scroll" (это делает UIKit.scroll()).

const GROUP := "touch_scroll"
const THRESHOLD := 14.0        # px до начала прокрутки (меньше — это нажатие)
const FRICTION := 4.5          # затухание инерции, 1/с
const MIN_SPEED := 30.0        # px/с — ниже инерция останавливается

var _sc: ScrollContainer = null
var _pressed := false
var _dragging := false
var _start := Vector2.ZERO
var _last := Vector2.ZERO
var _start_scroll := Vector2.ZERO
var _vel := Vector2.ZERO
var _last_t := 0
var _inertia: ScrollContainer = null
var _synthetic := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func _input(event: InputEvent) -> void:
	if _synthetic:
		return
	# собственное перетаскивание ScrollContainer по касанию отключаем — его заменяет этот модуль
	if event is InputEventScreenDrag and _pressed:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin(event.position)
		else:
			_end()
	elif event is InputEventMouseMotion and _pressed and _sc != null:
		_move(event.position)
		if _dragging:
			get_viewport().set_input_as_handled()


func _begin(pos: Vector2) -> void:
	_stop_inertia()
	_pressed = true
	_dragging = false
	_sc = _find_scroll(pos)
	if _sc and _blocked_at(_sc, pos):
		_sc = null   # палец на ползунке, полосе прокрутки или поле ввода — им прокрутка не мешает
	_start = pos
	_last = pos
	_last_t = Time.get_ticks_msec()
	_vel = Vector2.ZERO
	if _sc:
		_start_scroll = Vector2(_sc.scroll_horizontal, _sc.scroll_vertical)


func _move(pos: Vector2) -> void:
	var d = pos - _start
	if not _dragging:
		var v_ok = _can_v(_sc) and absf(d.y) > THRESHOLD and absf(d.y) >= absf(d.x)
		var h_ok = _can_h(_sc) and absf(d.x) > THRESHOLD and absf(d.x) > absf(d.y)
		if not (v_ok or h_ok):
			return
		_dragging = true
		_start = pos
		_start_scroll = Vector2(_sc.scroll_horizontal, _sc.scroll_vertical)
		_cancel_press()
		return
	if _can_v(_sc):
		_sc.scroll_vertical = int(_start_scroll.y - (pos.y - _start.y))
	if _can_h(_sc):
		_sc.scroll_horizontal = int(_start_scroll.x - (pos.x - _start.x))
	var now = Time.get_ticks_msec()
	var dt = maxf(0.001, (now - _last_t) / 1000.0)
	_vel = _vel.lerp((pos - _last) / dt, 0.4)
	_last = pos
	_last_t = now


func _end() -> void:
	_pressed = false
	if _dragging and _sc and is_instance_valid(_sc) and _vel.length() > MIN_SPEED * 4 and not Settings.reduce_motion:
		_inertia = _sc
		set_process(true)
	_dragging = false


## Отменяет нажатие кнопки под пальцем: отправляем ей движение «за пределы»,
## после чего отпускание пальца уже не считается нажатием.
func _cancel_press() -> void:
	var ev = InputEventMouseMotion.new()
	ev.position = Vector2(-100000, -100000)
	ev.global_position = ev.position
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	_synthetic = true
	get_viewport().push_input(ev)
	_synthetic = false


func _process(delta: float) -> void:
	if _inertia == null or not is_instance_valid(_inertia) or not _inertia.is_visible_in_tree():
		_stop_inertia()
		return
	if _can_v(_inertia):
		_inertia.scroll_vertical = int(_inertia.scroll_vertical - _vel.y * delta)
	if _can_h(_inertia):
		_inertia.scroll_horizontal = int(_inertia.scroll_horizontal - _vel.x * delta)
	_vel *= maxf(0.0, 1.0 - FRICTION * delta)
	if _vel.length() < MIN_SPEED:
		_stop_inertia()


func _stop_inertia() -> void:
	_inertia = null
	_vel = Vector2.ZERO
	set_process(false)


func _can_v(sc: ScrollContainer) -> bool:
	return sc != null and sc.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and sc.get_v_scroll_bar().max_value > sc.size.y + 1


func _can_h(sc: ScrollContainer) -> bool:
	return sc != null and sc.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and sc.get_h_scroll_bar().max_value > sc.size.x + 1


## Самый «глубокий» видимый список под пальцем, который действительно можно прокрутить.
func _find_scroll(pos: Vector2) -> ScrollContainer:
	var best: ScrollContainer = null
	var best_depth = -1
	for n in get_tree().get_nodes_in_group(GROUP):
		var sc = n as ScrollContainer
		if sc == null or not sc.is_visible_in_tree() or not sc.get_global_rect().has_point(pos):
			continue
		if not (_can_v(sc) or _can_h(sc)):
			continue
		var depth = str(sc.get_path()).count("/")
		if depth > best_depth:
			best = sc
			best_depth = depth
	return best


func _blocked_at(node: Node, pos: Vector2) -> bool:
	for c in node.get_children(true):
		if c is Control and c.is_visible_in_tree():
			if (c is Range or c is LineEdit or c is TextEdit or c.is_in_group("drag_card")) and c.get_global_rect().has_point(pos):
				return true
			if _blocked_at(c, pos):
				return true
	return false
