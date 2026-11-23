class_name ArtLib
extends RefCounted
## Подключение готовых картинок вместо рисованной кодом графики.
## Если в папке res://assets/art/ лежит файл с нужным именем (png, webp или jpg),
## игра показывает его; если нет — рисует персонажа/фон/остров программно.
## Список имён и требования — docs/10_ГРАФИКА_GPT_IMAGE.md

const ROOT := "res://assets/art/"
const EXTS := ["png", "webp", "jpg"]

static var _cache := {}


## name без расширения, например "characters/lumik", "bg/sky", "islands/math".
static func tex(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var t: Texture2D = null
	for e in EXTS:
		var p = ROOT + name + "." + e
		if ResourceLoader.exists(p):
			t = load(p) as Texture2D
			if t:
				break
	_cache[name] = t
	return t


static func has(name: String) -> bool:
	return tex(name) != null


## Рисует текстуру «с обрезкой по размеру» (как background-size: cover).
static func draw_cover(ci: CanvasItem, t: Texture2D, rect: Rect2) -> void:
	var ts = t.get_size()
	var k = maxf(rect.size.x / ts.x, rect.size.y / ts.y)
	var src_size = rect.size / k
	var src = Rect2((ts - src_size) * 0.5, src_size)
	ci.draw_texture_rect_region(t, rect, src)


## Рисует текстуру, вписанную в прямоугольник с сохранением пропорций, по низу (для персонажей).
static func draw_fit_bottom(ci: CanvasItem, t: Texture2D, box: Vector2, bottom_center: Vector2, modulate: Color = Color.WHITE) -> void:
	var ts = t.get_size()
	var k = minf(box.x / ts.x, box.y / ts.y)
	var sz = ts * k
	ci.draw_texture_rect(t, Rect2(bottom_center - Vector2(sz.x * 0.5, sz.y), sz), false, modulate)
