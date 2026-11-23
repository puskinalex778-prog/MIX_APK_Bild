#!/usr/bin/env python3
"""Проверка банка заданий. Пишет отчёт docs/validation_report.json и .md.
Код возврата 1, если найдены ошибки (ERROR). Предупреждения (WARN) не валят сборку.

Запуск: python3 validate_content.py [--strict]
"""
import json
import os
import re
import sys
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
PROJECT = os.path.join(ROOT, "project")
MIN_TASKS = 10
PIC_KINDS = {"groups", "array", "tens", "ruler", "clock", "polyline", "polygon", "rect", "angle", "bars", "coins", "column",
             "symmetry", "circle", "fraction", "grid", "tri", "motion", "blocks", "scale", "emoji", "big", "letters", "compass",
             "therm", "paletka", "segment"}
SUBJ = {"math": "Математика", "rus": "Русский язык", "world": "Окружающий мир", "eng": "Английский язык", "read": "Литературное чтение"}


def exact(s):
    return re.sub(r"\s+", " ", str(s)).strip()


def norm(s):
    return re.sub(r"\s+", " ", str(s).lower().replace("ё", "е")).strip()


def eval_math(prompt):
    m = re.match(r"^(?:Вычисли(?: столбиком)?|Найди значение выражения):?\s*(.+?)\.?$", prompt)
    if not m:
        return None
    e = m.group(1).replace("·", "*").replace("−", "-").replace("×", "*").replace(":", "/").replace(" ", "")
    if not re.fullmatch(r"[\d+\-*/()]+", e):
        return None
    try:
        v = eval(e)  # только цифры и знаки, проверено регуляркой
    except Exception:
        return "ERR"
    if abs(v - round(v)) > 1e-9:
        return "FRAC"
    return int(round(v))


def check_task(t, errs, warns):
    tid = t.get("id", "?")
    E = lambda m: errs.append(f"{tid}: {m}")
    W = lambda m: warns.append(f"{tid}: {m}")
    for k in ("id", "grade", "subject", "topic", "skill", "type", "prompt", "explanation", "hint"):
        if not str(t.get(k, "")).strip():
            E(f"нет поля {k}")
    ty = t.get("type")
    if ty in ("choice", "fill", "tf", "listen"):
        opts = t.get("options", [])
        if len(opts) < 2:
            E("меньше 2 вариантов")
        if t.get("answer") not in opts:
            E("ответ не среди вариантов")
        if len(set(map(exact, opts))) != len(opts):
            E("повтор вариантов")
        if ty == "fill" and "___" not in t["prompt"]:
            E("нет пропуска ___")
        if ty == "listen" and not t.get("audio"):
            E("нет текста для озвучки")
    elif ty == "multi":
        opts = t.get("options", [])
        ans = t.get("answer", [])
        if not ans or any(a not in opts for a in ans):
            E("ответы не среди вариантов")
        if len(opts) - len(ans) < 1:
            E("нет неверных вариантов")
        if len(set(map(exact, opts))) != len(opts):
            E("повтор вариантов")
    elif ty == "input":
        if not str(t.get("answer", "")).strip():
            E("пустой ответ")
        v = eval_math(t["prompt"])
        if v == "ERR" or v == "FRAC":
            E(f"выражение не вычисляется нацело")
        elif v is not None and str(v) != str(t["answer"]):
            E(f"неверный ответ: {t['answer']} ≠ {v}")
    elif ty == "match":
        pairs = t.get("pairs", [])
        if len(pairs) < 3 and len(pairs) < 2:
            E("мало пар")
        L = [norm(a) for a, _ in pairs]
        R = [norm(b) for _, b in pairs]
        if len(set(L)) != len(L) or len(set(R)) != len(R):
            E("повтор в парах")
    elif ty == "sort":
        cats = t.get("cats", [])
        items = t.get("items", [])
        if len(cats) < 2 or len(items) < 3:
            E("мало групп или элементов")
        used = {i[1] for i in items}
        if len(used) < 2:
            E("используется одна группа")
        if len(set(norm(i[0]) for i in items)) != len(items):
            E("повтор элементов")
    elif ty == "order":
        a = t.get("answer", [])
        if len(a) < 3:
            E("меньше 3 элементов")
        if len(set(map(norm, a))) != len(a):
            E("повтор элементов в последовательности")
    elif ty == "build":
        if len(t.get("answer", [])) < 2:
            E("мало элементов")
    elif ty == "fix":
        toks = t.get("tokens", [])
        w = t.get("wrong", -1)
        if not (0 <= w < len(toks)):
            E("неверный индекс ошибки")
        elif exact(toks[w]) == exact(t.get("answer")):
            E("исправление совпадает с ошибкой")
        if t.get("answer") not in t.get("options", []):
            E("исправление не среди вариантов")
    else:
        E(f"неизвестный тип {ty}")
    pic = t.get("pic")
    if pic and pic.get("k") not in PIC_KINDS:
        E(f"неизвестный рисунок {pic.get('k')}")
    # подсказка не должна выдавать ответ
    ans = t.get("answer")
    if ty in ("choice", "input", "fill") and isinstance(ans, str) and len(ans) >= 3 and norm(ans) in norm(t.get("hint", "")) and not t.get("hint_auto"):
        W("подсказка содержит ответ")
    if len(t.get("prompt", "")) > 400:
        W("очень длинное условие")


def main():
    reg = json.load(open(os.path.join(PROJECT, "data", "curriculum", "registry.json"), encoding="utf-8"))
    cov = json.load(open(os.path.join(PROJECT, "data", "curriculum", "coverage.json"), encoding="utf-8"))
    errs, warns = [], []
    ids = Counter()
    summary = {"grades": {}, "totals": {}}
    topic_rows = []
    order_prev = 0
    reading_works = 0
    auto_hints = 0
    all_tasks = 0
    voice_dir = os.path.join(PROJECT, "assets", "audio", "voice")
    voice_index = {}
    vi_path = os.path.join(voice_dir, "index.json")
    if os.path.exists(vi_path):
        voice_index = json.load(open(vi_path, encoding="utf-8"))
    for g in reg["grades"]:
        gr = g["grade"]
        gsum = {}
        for s in g["subjects"]:
            path = os.path.join(PROJECT, "data", "content", f"g{gr}_{s['code']}.json")
            bank = json.load(open(path, encoding="utf-8"))
            if bank["grade"] != gr or bank["subject"] != s["code"]:
                errs.append(f"{path}: неверный класс/предмет в файле")
            n_topics = n_tasks = 0
            min_t = 10 ** 9
            secs = 0
            for c in s["sections"]:
                secs += 1
                for tp in c["topics"]:
                    if tp["order"] <= order_prev:
                        errs.append(f"{tp['id']}: нарушен порядок тем")
                    order_prev = tp["order"]
                    tasks = bank["topics"].get(tp["id"])
                    if tasks is None:
                        errs.append(f"{tp['id']}: тема отсутствует в банке")
                        tasks = []
                    n_topics += 1
                    n_tasks += len(tasks)
                    all_tasks += len(tasks)
                    min_t = min(min_t, len(tasks))
                    if s["code"] == "read":
                        reading_works += len(tp["items"])
                    if len(tasks) < MIN_TASKS:
                        errs.append(f"{tp['id']}: заданий {len(tasks)} < {MIN_TASKS}")
                    keys = Counter()
                    for t in tasks:
                        ids[t.get("id")] += 1
                        if t.get("grade") != gr or not t.get("topic", "").startswith(f"g{gr}.{s['code']}."):
                            errs.append(f"{t.get('id')}: задание чужого класса/предмета")
                        if t.get("topic") != tp["id"]:
                            errs.append(f"{t.get('id')}: принадлежит другой теме")
                        check_task(t, errs, warns)
                        if t.get("hint_auto"):
                            auto_hints += 1
                        k = norm(t.get("prompt")) + "|" + json.dumps(t.get("pic"), sort_keys=True, ensure_ascii=False) + "|" + norm(t.get("text", "")) + "|" + norm(json.dumps(t.get("answer", t.get("pairs", t.get("items"))), ensure_ascii=False))
                        keys[k] += 1
                        if t.get("type") == "listen":
                            a = t.get("audio")
                            if voice_index and a not in voice_index:
                                errs.append(f"{t['id']}: нет аудиофайла для «{a}»")
                            elif voice_index and not os.path.exists(os.path.join(voice_dir, voice_index[a])):
                                errs.append(f"{t['id']}: файл {voice_index[a]} отсутствует")
                    for k, v in keys.items():
                        if v > 1:
                            errs.append(f"{tp['id']}: дословный дубль задания ×{v}: {k[:80]}")
                    types = Counter(t["type"] for t in tasks)
                    if len(types) < 3 and len(tasks) >= MIN_TASKS:
                        warns.append(f"{tp['id']}: мало разных механик ({dict(types)})")
                    unc = [ci["item"] for ci in cov.get(tp["id"], []) if not ci["tasks"]]
                    for u in unc:
                        errs.append(f"{tp['id']}: пункт «{u}» не покрыт заданиями")
                    topic_rows.append({"id": tp["id"], "title": tp["title"], "section": c["title"], "grade": gr, "subject": s["code"],
                                       "tasks": len(tasks), "types": dict(types), "items": len(tp["items"]), "uncovered": unc})
            gsum[s["code"]] = {"sections": secs, "topics": n_topics, "tasks": n_tasks, "min_tasks_in_topic": min_t}
        summary["grades"][gr] = gsum
    for i, n in ids.items():
        if n > 1:
            errs.append(f"{i}: идентификатор повторяется {n} раз")
    summary["totals"] = {
        "textbooks": sum(len(g["subjects"]) for g in reg["grades"]),
        "sections": sum(len(s["sections"]) for g in reg["grades"] for s in g["subjects"]),
        "topics": len(topic_rows),
        "reading_works_items": reading_works,
        "tasks": all_tasks,
        "min_tasks_in_topic": min(r["tasks"] for r in topic_rows) if topic_rows else 0,
        "topics_below_min": sum(1 for r in topic_rows if r["tasks"] < MIN_TASKS),
        "uncovered_items": sum(len(r["uncovered"]) for r in topic_rows),
        "auto_hints": auto_hints,
        "errors": len(errs),
        "warnings": len(warns),
    }
    out = {"summary": summary, "errors": errs, "warnings": warns, "topics": topic_rows}
    os.makedirs(os.path.join(ROOT, "docs"), exist_ok=True)
    json.dump(out, open(os.path.join(ROOT, "docs", "validation_report.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(json.dumps(summary, ensure_ascii=False, indent=1))
    print(f"ERRORS: {len(errs)}  WARNINGS: {len(warns)}")
    for e in errs[:60]:
        print("  E", e)
    if "-v" in sys.argv:
        for w in warns[:60]:
            print("  W", w)
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
