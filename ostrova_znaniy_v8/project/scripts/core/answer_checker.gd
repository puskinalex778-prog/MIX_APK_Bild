class_name AnswerChecker
extends RefCounted
## Проверка ответов. Ответ ребёнка сравнивается с правильным и допустимыми альтернативами
## после нормализации (регистр, ё/е, пробелы, точка в конце, пробелы-разделители в числах).


static func norm(s: String) -> String:
	s = s.strip_edges().to_lower().replace("ё", "е")
	s = s.replace(" ", " ")
	while s.contains("  "):
		s = s.replace("  ", " ")
	while s.ends_with(".") or s.ends_with("!"):
		s = s.substr(0, s.length() - 1).strip_edges()
	# числа вида "50 000" -> "50000"
	var digits_only = true
	for ch in s:
		if not (ch in "0123456789 "):
			digits_only = false
			break
	if digits_only:
		s = s.replace(" ", "")
	# время "4.45" -> "4:45", "04:45" -> "4:45"
	var re = RegEx.new()
	re.compile("^0?(\\d{1,2})[.:](\\d{2})$")
	var m = re.search(s)
	if m:
		s = "%d:%s" % [int(m.get_string(1)), m.get_string(2)]
	return s


static func check_input(task: Dictionary, given: String) -> bool:
	var g = norm(given)
	if g == "":
		return false
	if g == norm(str(task.get("answer", ""))):
		return true
	for a in task.get("alts", []):
		if g == norm(str(a)):
			return true
	return false


static func check_choice(task: Dictionary, given: String) -> bool:
	return given == str(task.get("answer", ""))


static func check_multi(task: Dictionary, given: Array) -> bool:
	var ans: Array = task.get("answer", [])
	if given.size() != ans.size():
		return false
	for a in ans:
		if not given.has(a):
			return false
	return true


static func check_order(task: Dictionary, given: Array) -> bool:
	var ans: Array = task.get("answer", [])
	if given.size() != ans.size():
		return false
	for i in ans.size():
		if norm(str(given[i])) != norm(str(ans[i])):
			return false
	return true


## pairs: [[left, right], ...] — сравнение по тексту (одинаковые правые тексты взаимозаменяемы)
static func check_match(task: Dictionary, given: Array) -> bool:
	var want = {}
	for p in task.get("pairs", []):
		want[norm(p[0])] = norm(p[1])
	if given.size() != want.size():
		return false
	for p in given:
		if want.get(norm(p[0]), "\u0000") != norm(p[1]):
			return false
	return true


## given: {item_text: cat_index}
static func check_sort(task: Dictionary, given: Dictionary) -> bool:
	for it in task.get("items", []):
		if int(given.get(it[0], -1)) != int(it[1]):
			return false
	return true


static func check_fix(task: Dictionary, picked_index: int, replacement: String) -> bool:
	return picked_index == int(task.get("wrong", -1)) and replacement == str(task.get("answer", ""))


## Текст правильного ответа для журнала ошибок и экрана разбора.
static func answer_text(task: Dictionary) -> String:
	match str(task.get("type", "")):
		"multi":
			return ", ".join(PackedStringArray(task.get("answer", [])))
		"order":
			return " → ".join(PackedStringArray(task.get("answer", [])))
		"build":
			return str(task.get("joiner", " ")).join(PackedStringArray(task.get("answer", [])))
		"match":
			var parts = PackedStringArray()
			for p in task.get("pairs", []):
				parts.append("%s — %s" % [p[0], p[1]])
			return "; ".join(parts)
		"sort":
			var cats: Array = task.get("cats", [])
			var groups = {}
			for it in task.get("items", []):
				var c: String = cats[int(it[1])]
				if not groups.has(c):
					groups[c] = PackedStringArray()
				groups[c].append(it[0])
			var parts2 = PackedStringArray()
			for c in groups:
				parts2.append("%s: %s" % [c, ", ".join(groups[c])])
			return "; ".join(parts2)
		"fix":
			var toks: Array = task.get("tokens", [])
			var w = int(task.get("wrong", 0))
			return "«%s» → «%s»" % [toks[w] if w < toks.size() else "?", task.get("answer", "")]
		_:
			return str(task.get("answer", ""))
