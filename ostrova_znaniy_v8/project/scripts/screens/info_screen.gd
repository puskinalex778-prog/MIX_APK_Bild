extends BaseScreen
## Вкладка «Информация»: об игре, учебники-источники, права на ресурсы, данные и приватность.


func setup(_params: Dictionary) -> void:
	make_layout("sky", 28, 0.35)
	root.add_child(UIKit.top_bar("ℹ️ Информация", Router.back))
	var card = UIKit.panel(Color(1, 1, 1, 0.97), 26, 24)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v = UIKit.vbox(12)
	card.add_child(UIKit.scroll(v))
	root.add_child(card)
	v.add_child(UIKit.label("«Острова Знаний», версия %s" % ProjectSettings.get_setting("application/config/version", "1.0.0"), 28, UIKit.C_TEXT, "title"))
	v.add_child(UIKit.label("Обучающая игра для 2–4 классов: математика, русский язык, окружающий мир, английский язык, литературное чтение, мастерская таблицы умножения.", 20))
	v.add_child(UIKit.label("Учебные программы (оглавления)", 24, UIKit.C_PRIMARY, "bold"))
	for g in Content.registry.get("grades", []):
		for s in g["subjects"]:
			v.add_child(UIKit.label("• %d класс, %s: %s" % [int(g["grade"]), s["title"], s["source"]], 17))
	v.add_child(UIKit.label("Задания составлены по темам этих учебников; тексты учебников в игре не воспроизводятся.", 17, UIKit.C_MUTED))
	v.add_child(UIKit.label("Ресурсы и права", 24, UIKit.C_PRIMARY, "bold"))
	for line in [
		"Шрифты Comfortaa и Noto Sans — SIL Open Font License 1.1.",
		"Эмодзи Noto Color Emoji (Google) — SIL Open Font License 1.1.",
		"Персонажи, фоны и рисунки нарисованы программно специально для этой игры.",
		"Музыка и звуковые эффекты синтезированы программно специально для этой игры.",
		"Английская озвучка — синтезатор речи eSpeak NG (GPL v3; в игре — только сгенерированные аудиофайлы).",
		"Игровой движок Godot Engine — лицензия MIT.",
	]:
		v.add_child(UIKit.label("• " + line, 17))
	v.add_child(UIKit.label("Данные", 24, UIKit.C_PRIMARY, "bold"))
	v.add_child(UIKit.label("Все данные хранятся только на этом устройстве и никуда не отправляются. Игра работает без интернета. Родительский PIN хранится в виде хэша; сами файлы прогресса не зашифрованы. Экспортированный файл профиля тоже не зашифрован и содержит имя ребёнка и историю обучения.", 17))
	v.add_child(UIKit.label("Перерывы", 24, UIKit.C_PRIMARY, "bold"))
	v.add_child(UIKit.label("По умолчанию перерыв предлагается через 10 минут (2 класс) или 15 минут (3–4 классы) непрерывных занятий, дневной лимит — 40 или 50 минут. Ориентир — нормы СанПиН 1.2.3685-21 для электронных средств обучения. Родитель может изменить значения.", 17))
	if Content.load_errors.size() > 0:
		v.add_child(UIKit.label("Предупреждения загрузки: " + "; ".join(PackedStringArray(Content.load_errors.slice(0, 5))), 15, UIKit.C_BAD))
