#!/usr/bin/env python3
"""Генерирует таблицы документации из данных проекта: реестр программы, таблицу соответствия
«оглавление учебника → темы и задания игры», источники и сводку чисел для отчёта.
Все числа считаются из файлов project/data, а не вписываются вручную."""
import json, os, glob, csv, collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P = os.path.join(ROOT, "project")
DOCS = os.path.join(ROOT, "docs")
SUBJ = {"math": "Математика", "rus": "Русский язык", "world": "Окружающий мир", "eng": "Английский язык", "read": "Литературное чтение"}

reg = json.load(open(os.path.join(P, "data/curriculum/registry.json"), encoding="utf-8"))
cov = json.load(open(os.path.join(P, "data/curriculum/coverage.json"), encoding="utf-8"))
banks = {}
for f in glob.glob(os.path.join(P, "data/content/*.json")):
    b = json.load(open(f, encoding="utf-8"))
    banks[(b["grade"], b["subject"])] = b

# ---------- сводка ----------
stats = collections.OrderedDict()
types = collections.Counter()
total_tasks = total_topics = total_items = covered_items = with_pic = with_audio = with_text = auto_hints = 0
ids = set()
dup_ids = 0
for g in reg["grades"]:
    for s in g["subjects"]:
        b = banks[(g["grade"], s["code"])]
        nt = sum(len(c["topics"]) for c in s["sections"])
        tasks = [t for ts in b["topics"].values() for t in ts]
        mn = min(len(ts) for ts in b["topics"].values())
        stats[(g["grade"], s["code"])] = {"sections": len(s["sections"]), "topics": nt, "tasks": len(tasks), "min": mn}
        total_topics += nt
        total_tasks += len(tasks)
        for t in tasks:
            types[t["type"]] += 1
            with_pic += 1 if t.get("pic") else 0
            with_audio += 1 if t.get("audio") else 0
            with_text += 1 if t.get("text") else 0
            auto_hints += 1 if t.get("hint_auto") else 0
            if t["id"] in ids:
                dup_ids += 1
            ids.add(t["id"])
        for c in s["sections"]:
            for tp in c["topics"]:
                for it in cov.get(tp["id"], []):
                    total_items += 1
                    covered_items += 1 if it["tasks"] else 0

voice = len([f for f in os.listdir(os.path.join(P, "assets/audio/voice")) if f.endswith(".ogg")])
sfx = len([f for f in os.listdir(os.path.join(P, "assets/audio/sfx")) if f.endswith(".ogg")])
music = len([f for f in os.listdir(os.path.join(P, "assets/audio/music")) if f.endswith(".ogg")])
scripts = len(glob.glob(os.path.join(P, "scripts/**/*.gd"), recursive=True))
summary = {"topics": total_topics, "tasks": total_tasks, "items": total_items, "items_covered": covered_items,
           "types": dict(types), "with_pic": with_pic, "with_audio": with_audio, "with_text": with_text,
           "auto_hints": auto_hints, "duplicate_ids": dup_ids, "voice_files": voice, "sfx_files": sfx,
           "music_files": music, "gd_scripts": scripts,
           "by_grade_subject": {f"{g}.{s}": v for (g, s), v in stats.items()}}
json.dump(summary, open(os.path.join(DOCS, "numbers.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)

# ---------- реестр программы ----------
out = ["# Реестр учебной программы (2–4 классы)", "",
       "Сформирован автоматически из `project/data/curriculum/registry.json`. Идентификатор темы стабилен "
       "(`g<класс>.<предмет>.<код>`) и никогда не переназначается другой теме.", "",
       "| Класс | Предмет | Разделов | Тем | Заданий | Мин. заданий в теме |", "|---|---|---|---|---|---|"]
for (g, s), v in stats.items():
    out.append(f"| {g} | {SUBJ[s]} | {v['sections']} | {v['topics']} | {v['tasks']} | {v['min']} |")
out.append(f"| **Итого** | | | **{total_topics}** | **{total_tasks}** | |")
for g in reg["grades"]:
    out += ["", f"## {g['grade']} класс"]
    for s in g["subjects"]:
        out += ["", f"### {SUBJ[s['code']]}", f"Учебник: {s['source']}", ""]
        for c in s["sections"]:
            out.append(f"**{c['title']}**")
            out.append("")
            for tp in c["topics"]:
                out.append(f"- `{tp['id']}` — {tp['title']} ({tp['count']} заданий; пункты: {'; '.join(tp['items'])})")
            out.append("")
open(os.path.join(DOCS, "04_РЕЕСТР_ПРОГРАММЫ.md"), "w", encoding="utf-8").write("\n".join(out))

# ---------- соответствие ----------
with open(os.path.join(DOCS, "05_СООТВЕТСТВИЕ_УЧЕБНИКИ_ИГРА.csv"), "w", encoding="utf-8-sig", newline="") as fh:
    w = csv.writer(fh, delimiter=";")
    w.writerow(["Класс", "Предмет", "Раздел учебника", "Тема учебника", "Пункт оглавления", "ID темы в игре", "Заданий в теме", "Заданий на пункт", "ID заданий (первые 8)"])
    for g in reg["grades"]:
        for s in g["subjects"]:
            for c in s["sections"]:
                for tp in c["topics"]:
                    for it in cov.get(tp["id"], []):
                        w.writerow([g["grade"], SUBJ[s["code"]], c["title"], tp["title"], it["item"], tp["id"], tp["count"], len(it["tasks"]), ", ".join(it["tasks"][:8])])
md = ["# Соответствие оглавлений учебников и содержания игры", "",
      "Полная таблица (каждый пункт оглавления → тема игры → номера заданий): `05_СООТВЕТСТВИЕ_УЧЕБНИКИ_ИГРА.csv` "
      "(открывается в Excel/LibreOffice, разделитель «;»).", "",
      f"Пунктов оглавлений: **{total_items}**, покрыто заданиями: **{covered_items}** ({100*covered_items//max(1,total_items)}%).", "",
      "Пункт считается покрытым, если хотя бы одно задание темы относится к нему (по ключевым словам или по явной пометке автора). "
      "Проверку выполняет `tools/content/validate_content.py`; непокрытый пункт — это ошибка, и сборка банка заданий её не пропускает."]
open(os.path.join(DOCS, "05_СООТВЕТСТВИЕ_УЧЕБНИКИ_ИГРА.md"), "w", encoding="utf-8").write("\n".join(md))

# ---------- источники ----------
src = ["# Источники оглавлений и издания", "",
       "Программа игры составлена по оглавлениям учебников, перечисленных ниже (федеральный перечень, УМК «Школа России» и «Английский в фокусе»). "
       "В игру не скопированы тексты, упражнения или иллюстрации учебников: все задания написаны заново, литературные произведения "
       "представлены вопросами по содержанию без воспроизведения охраняемых текстов.", ""]
for g in reg["grades"]:
    src.append(f"## {g['grade']} класс")
    for s in g["subjects"]:
        src.append(f"- **{SUBJ[s['code']]}**: {s['source']}")
    src.append("")
src += ["Год издания указан по актуальным выпускам издательства «Просвещение»; состав тем в соседних годах выпуска совпадает. "
        "Если у ребёнка другое издание, порядок тем может отличаться — темы в игре можно проходить в любом порядке, а родитель может открыть любую тему.",
        "", "Сведения об авторах и учебниках в самой игре показываются только во вкладке «Информация» (кнопка ℹ️ на карте)."]
open(os.path.join(DOCS, "06_ИСТОЧНИКИ_И_ИЗДАНИЯ.md"), "w", encoding="utf-8").write("\n".join(src))
print(json.dumps({k: v for k, v in summary.items() if k != "by_grade_subject"}, ensure_ascii=False, indent=1))
