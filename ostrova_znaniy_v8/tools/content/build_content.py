#!/usr/bin/env python3
"""Сборка учебного контента.

1. Разбирает tools/registry.txt -> project/data/curriculum/registry.json
2. Для каждой темы берёт задания из генератора (math_g2.t_<код> и т.п.)
   или из авторского файла dsl/g<класс>_<предмет>.txt
3. Присваивает устойчивые id, класс, предмет, тему; пишет
   project/data/content/g<класс>_<предмет>.json
4. Строит карту покрытия пунктов реестра (data/curriculum/coverage.json)

Запуск: python3 build_content.py   (из папки tools/content)
"""
import importlib
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
PROJECT = os.path.join(ROOT, "project")
sys.path.insert(0, HERE)
import common  # noqa: E402

SUBJ_ORDER = ["math", "rus", "world", "eng", "read"]
CONTENT_VERSION = 1


def parse_registry(path):
    reg = {"version": 1, "grades": []}
    g = s = c = None
    order = 0
    for raw in open(path, encoding="utf-8"):
        line = raw.rstrip("\n")
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        tag, _, rest = line.partition(" ")
        parts = [p.strip() for p in rest.split("|")]
        if tag == "G":
            g = {"grade": int(parts[0]), "subjects": []}
            reg["grades"].append(g)
        elif tag == "S":
            s = {"code": parts[0], "title": parts[1], "source": parts[2], "sections": []}
            g["subjects"].append(s)
        elif tag == "C":
            c = {"code": parts[0], "title": parts[1], "id": f"g{g['grade']}.{s['code']}.{parts[0]}", "topics": []}
            s["sections"].append(c)
        elif tag == "T":
            order += 1
            items = [i.strip() for i in parts[2].split(";")] if len(parts) > 2 and parts[2] else [parts[1]]
            c["topics"].append({"id": f"g{g['grade']}.{s['code']}.{parts[0]}", "code": parts[0], "title": parts[1],
                                "items": items, "order": order})
        else:
            raise ValueError("Неизвестная строка реестра: " + line)
    return reg


# ---------------- DSL для авторских заданий ----------------
SPLIT = re.compile(r"\s+\|\s+")


def _list(s):
    return [x.strip() for x in s.split(";") if x.strip()]


def parse_dsl(path):
    """Возвращает {topic_id: [task,...]}."""
    out = {}
    cur = None
    passage = None
    pic = None
    header_prefix = None
    for ln, raw in enumerate(open(path, encoding="utf-8"), 1):
        line = raw.rstrip("\n")
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        try:
            if line.startswith("@@"):
                header_prefix = line[2:].strip()  # например g2.world
                continue
            if line.startswith("@"):
                tid = line[1:].strip()
                if header_prefix and not re.match(r"^g\d\.", tid):
                    tid = header_prefix + "." + tid
                cur = tid
                out.setdefault(cur, [])
                passage = None
                continue
            covers = None
            m = re.match(r"^\{([\d,]+)\}\s*", line)
            if m:
                covers = [int(x) for x in m.group(1).split(",")]
                line = line[m.end():]
            kind, _, body = line.partition(" ")
            if kind == "x":
                passage = body.strip() or None
                continue
            if kind == "k":
                pic = json.loads(body)
                continue
            f = SPLIT.split(body.strip())
            kw = {}
            if passage:
                kw["text"] = passage
            if pic:
                kw["pic"] = pic
                pic = None
            def H(i):
                return f[i] if len(f) > i else None
            if kind == "c":
                t = common.ch(f[0], f[1], _list(f[2]), f[3], H(4), **kw)
            elif kind == "t":
                t = common.tf(f[0], f[1].strip().upper().startswith("В"), f[2], H(3), **kw)
            elif kind == "m":
                t = common.multi(f[0], _list(f[1]), _list(f[2]), f[3], H(4), **kw)
            elif kind == "i":
                ans = _list(f[1])
                kb = "num" if re.fullmatch(r"-?\d+", ans[0]) else "text"
                t = common.inp(f[0], ans[0], f[2], H(3), alts=ans[1:], kb=kb, **kw)
            elif kind == "p":
                pairs = [tuple(x.split("=", 1)) for x in _list(f[1])]
                t = common.match(f[0], [(a.strip(), b.strip()) for a, b in pairs], f[2], H(3), **kw)
            elif kind == "s":
                cats = []
                for chunk in _list(f[1]):
                    name, _, its = chunk.partition(":")
                    cats.append((name.strip(), [i.strip() for i in its.split(",") if i.strip()]))
                t = common.sort_(f[0], cats, f[2], H(3), **kw)
            elif kind == "o":
                t = common.order(f[0], _list(f[1]), f[2], H(3), **kw)
            elif kind == "f":
                t = common.fill(f[0], f[1], _list(f[2]), f[3], H(4), **kw)
            elif kind == "b":
                toks = [x.replace("_", " ") for x in f[1].split()]
                extra = [x.replace("_", " ") for x in f[2].split()] if f[2] != "-" else []
                t = common.build(f[0], toks, extra, f[3], H(4), **kw)
            elif kind == "e":
                f1 = re.sub(r"\*([^*]+)\*", lambda m_: "*" + m_.group(1).replace(" ", "_") + "*", f[1])
                toks = f1.split()
                wi = [i for i, x in enumerate(toks) if x.startswith("*") and "*" in x[1:]][0]
                toks = [x.replace("*", "").replace("_", " ") for x in toks]
                t = common.fix(f[0], toks, wi, f[2], _list(f[3]), f[4], H(5), **kw)
            elif kind == "l":
                t = common.listen(f[0], f[1], f[2], _list(f[3]), f[4], H(5), **kw)
            else:
                raise ValueError("неизвестный тип строки: " + kind)
            if covers:
                t["covers"] = covers
            out[cur].append(t)
        except Exception as e:  # noqa
            raise SystemExit(f"{path}:{ln}: ошибка разбора: {e}\n  {raw}")
    return out


# ---------------- подсказки ----------------
def _first_sentence(s):
    m = re.match(r"(.+?[.!?])(\s|$)", s)
    return (m.group(1) if m else s).strip()


def auto_hint(t):
    """Подсказка из объяснения: ответ скрывается многоточием."""
    expl = _first_sentence(t["explanation"])
    ans = t.get("answer")
    words = []
    if isinstance(ans, list):
        words = [str(a) for a in ans]
    elif ans is not None:
        words = [str(ans)]
    masked = expl
    hit = False
    for w in words:
        if w and len(w) >= 2 and w.lower() in masked.lower():
            masked = re.sub(re.escape(w), "…", masked, flags=re.I)
            hit = True
    if hit:
        return "Вспомни: " + masked
    generic = {
        "choice": "Сначала убери варианты, которые точно не подходят.",
        "tf": "Подумай, всегда ли так бывает.",
        "multi": "Правильных ответов может быть несколько — проверь каждый.",
        "match": "Начни с пары, в которой уверен больше всего.",
        "sort": "Для каждого слова спроси себя: к какой группе оно относится?",
        "order": "Найди, что происходит самым первым.",
        "fill": "Прочитай предложение целиком с каждым вариантом.",
        "build": "Подумай, с чего должно начинаться.",
        "fix": "Прочитай медленно и найди слово, которое не подходит.",
        "input": "Перечитай вопрос и подумай ещё раз.",
        "listen": "Послушай ещё раз — нажми на кнопку со звуком.",
    }
    return generic.get(t["type"], "Подумай ещё раз.")


# ---------------- сборка ----------------
def norm(s):
    return s.lower().replace("ё", "е")


STOP = {"чисел", "числа", "число", "числе", "через", "слова", "слов", "имён", "имени", "весь", "разные", "виды", "видов", "общее", "понятие", "правила", "правило"}
SYN = {"делен": [":", "раздел"], "умнож": ["·"], "сложен": ["+"], "вычитан": ["−"], "сравнен": ["…", ">", "<", "больше"], "скобк": ["("],
       "увеличен": ["увелич"], "уменьшен": ["уменьш"], "образован": ["запиши", "дес."], "рубл": ["р."], "копейк": ["к."]}


def item_keywords(item):
    """Список вариантов: пункт покрыт, если в задании встречается хотя бы один."""
    q = re.findall(r"«([^»]+)»", item)
    src = norm(q[0]) if q else norm(item)
    words = [w for w in re.findall(r"[\w–-]+", src) if len(w) >= 2]
    sig = [w for w in words if len(w) >= 4 and w not in STOP] or words or [src]
    if q:
        sig = sig[:1]
    out = []
    for w in sig:
        stem = w[: max(4, len(w) - 2)] if len(w) > 5 else w
        out.append(stem)
        for k, v in SYN.items():
            if stem.startswith(k) or k.startswith(stem):
                out.extend(v)
    return out


def task_text(t):
    parts = [t.get("prompt", ""), t.get("explanation", ""), t.get("text", ""), " ".join(map(str, t.get("options", []))),
             str(t.get("answer", "")), " ".join(t.get("cats", [])), " ".join(i[0] for i in t.get("items", [])),
             " ".join(" ".join(p) for p in t.get("pairs", []))]
    return norm(" ".join(parts))


def build():
    reg = parse_registry(os.path.join(ROOT, "tools", "registry.txt"))
    dsl = {}
    dsl_dir = os.path.join(HERE, "dsl")
    for fn in sorted(os.listdir(dsl_dir)) if os.path.isdir(dsl_dir) else []:
        if fn.endswith(".txt"):
            for k, v in parse_dsl(os.path.join(dsl_dir, fn)).items():
                dsl.setdefault(k, []).extend(v)
    os.makedirs(os.path.join(PROJECT, "data", "content"), exist_ok=True)
    coverage = {}
    known_topics = set()
    for g in reg["grades"]:
        gr = g["grade"]
        for s in g["subjects"]:
            mod = None
            try:
                mod = importlib.import_module(f"{s['code']}_g{gr}")
            except ModuleNotFoundError:
                pass
            bank = {"version": CONTENT_VERSION, "grade": gr, "subject": s["code"], "topics": {}}
            for c in s["sections"]:
                for tp in c["topics"]:
                    known_topics.add(tp["id"])
                    tasks = []
                    gen = getattr(mod, "t_" + tp["code"], None) if mod else None
                    if gen:
                        tasks.extend(gen(common.rng_for(tp["id"])))
                    tasks.extend(dsl.get(tp["id"], []))
                    out = []
                    for i, t in enumerate(tasks, 1):
                        t = dict(t)
                        t["id"] = f"{tp['id']}-{i:03d}"
                        t["grade"] = gr
                        t["subject"] = s["code"]
                        t["topic"] = tp["id"]
                        t.setdefault("skill", tp["title"])
                        if not t.get("hint"):
                            t["hint"] = auto_hint(t)
                            t["hint_auto"] = True
                        out.append(t)
                    bank["topics"][tp["id"]] = out
                    tp["count"] = len(out)
                    # покрытие пунктов
                    cov = []
                    texts = [task_text(t) for t in out]
                    for idx, item in enumerate(tp["items"], 1):
                        kws = item_keywords(item)
                        ids = [out[k]["id"] for k, tx in enumerate(texts) if any(kw in tx for kw in kws) or idx in out[k].get("covers", [])]
                        if len(tp["items"]) == 1 and not ids:
                            ids = [t["id"] for t in out]  # тема из одного пункта покрывается всеми её заданиями
                        cov.append({"item": item, "keywords": kws, "tasks": ids})
                    coverage[tp["id"]] = cov
            with open(os.path.join(PROJECT, "data", "content", f"g{gr}_{s['code']}.json"), "w", encoding="utf-8") as fh:
                json.dump(bank, fh, ensure_ascii=False, separators=(",", ":"))
    unknown = [k for k in dsl if k not in known_topics]
    if unknown:
        raise SystemExit("В авторских файлах есть темы, которых нет в реестре: " + ", ".join(unknown))
    with open(os.path.join(PROJECT, "data", "curriculum", "registry.json"), "w", encoding="utf-8") as fh:
        json.dump(reg, fh, ensure_ascii=False, indent=1)
    with open(os.path.join(PROJECT, "data", "curriculum", "coverage.json"), "w", encoding="utf-8") as fh:
        json.dump(coverage, fh, ensure_ascii=False, indent=0)
    return reg


if __name__ == "__main__":
    build()
    print("ok")
