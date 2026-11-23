extends Node
## Загружает все скрипты проекта и сообщает об ошибках компиляции (запуск с автозагрузками).

func _ready() -> void:
	var bad := 0
	var files := []
	_collect("res://scripts", files)
	for f in files:
		var s = load(f)
		if s == null or not (s is GDScript) or not s.can_instantiate():
			print("FAIL ", f)
			bad += 1
	print("CHECKED %d scripts, failed %d" % [files.size(), bad])
	get_tree().quit(1 if bad > 0 else 0)


func _collect(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		_collect(dir + "/" + sub, out)
