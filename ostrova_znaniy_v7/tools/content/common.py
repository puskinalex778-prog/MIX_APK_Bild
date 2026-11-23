"""Общие функции для генерации банка заданий.

Каждое задание — словарь со стабильными полями. Идентификатор задаётся
в build_content.py как <id темы>-<порядковый номер>, порядок задаётся
источником (детерминированный генератор или авторский файл), поэтому id
стабильны между пересборками.
"""
import random

TYPES = {"choice", "multi", "input", "fill", "match", "sort", "order", "build", "fix", "tf", "listen"}


def _base(t, prompt, expl, hint, skill=None, pic=None, text=None, audio=None):
    d = {"type": t, "prompt": prompt.strip(), "explanation": expl.strip(), "hint": (hint or "").strip()}
    if skill:
        d["skill"] = skill
    if pic:
        d["pic"] = pic
    if text:
        d["text"] = text.strip()
    if audio:
        d["audio"] = audio
    return d


def _uniq(seq):
    out = []
    for s in seq:
        s = str(s)
        if s not in out:
            out.append(s)
    return out


def ch(prompt, answer, distractors, expl, hint=None, **kw):
    answer = str(answer)
    opts = [answer] + [d for d in _uniq(distractors) if d != answer]
    d = _base("choice", prompt, expl, hint, **kw)
    d["answer"] = answer
    d["options"] = opts[:6]
    return d


def tf(prompt, is_true, expl, hint=None, **kw):
    d = _base("tf", prompt, expl, hint, **kw)
    d["answer"] = "Верно" if is_true else "Неверно"
    d["options"] = ["Верно", "Неверно"]
    return d


def multi(prompt, correct, wrong, expl, hint=None, **kw):
    d = _base("multi", prompt, expl, hint, **kw)
    d["answer"] = _uniq(correct)
    d["options"] = _uniq(list(correct) + [w for w in wrong if str(w) not in [str(c) for c in correct]])
    return d


def inp(prompt, answer, expl, hint=None, alts=(), kb="num", **kw):
    d = _base("input", prompt, expl, hint, **kw)
    d["answer"] = str(answer)
    d["alts"] = [str(a) for a in alts if str(a) != str(answer)]
    d["kb"] = kb
    return d


def fill(prompt, answer, distractors, expl, hint=None, **kw):
    assert "___" in prompt, prompt
    d = ch(prompt, answer, distractors, expl, hint, **kw)
    d["type"] = "fill"
    return d


def match(prompt, pairs, expl, hint=None, **kw):
    d = _base("match", prompt, expl, hint, **kw)
    d["pairs"] = [[str(a), str(b)] for a, b in pairs]
    return d


def sort_(prompt, cats, expl, hint=None, **kw):
    """cats: list of (category_name, [items])"""
    d = _base("sort", prompt, expl, hint, **kw)
    d["cats"] = [c for c, _ in cats]
    items = []
    for i, (_, its) in enumerate(cats):
        for it in its:
            items.append([str(it), i])
    d["items"] = items
    return d


def order(prompt, items, expl, hint=None, **kw):
    d = _base("order", prompt, expl, hint, **kw)
    d["answer"] = [str(i) for i in items]
    return d


def build(prompt, tokens, extra, expl, hint=None, joiner=" ", **kw):
    d = _base("build", prompt, expl, hint, **kw)
    d["answer"] = [str(t) for t in tokens]
    d["extra"] = [str(e) for e in extra]
    d["joiner"] = joiner
    return d


def fix(prompt, tokens, wrong_idx, correct, options, expl, hint=None, **kw):
    d = _base("fix", prompt, expl, hint, **kw)
    d["tokens"] = [str(t) for t in tokens]
    d["wrong"] = wrong_idx
    d["answer"] = str(correct)
    opts = [str(correct)] + [str(o) for o in options if str(o) != str(correct)]
    d["options"] = _uniq(opts)[:4]
    return d


def listen(prompt, say, answer, distractors, expl, hint=None, **kw):
    d = ch(prompt, answer, distractors, expl, hint, **kw)
    d["type"] = "listen"
    d["audio"] = say
    return d


def rng_for(key):
    return random.Random("v1:" + key)


def near(n, r, k=3, lo=0):
    """Правдоподобные неверные числа рядом с n."""
    cands = []
    for delta in (1, -1, 10, -10, 2, -2, 5, -5, 9, -9, 11, -11, 3, -3):
        v = n + delta
        if v >= lo and v != n and v not in cands:
            cands.append(v)
    r.shuffle(cands)
    # ставим «типичные» ошибки (±1, ±10) первыми с вероятностью
    pri = [c for c in cands if abs(c - n) in (1, 10)]
    rest = [c for c in cands if c not in pri]
    out = (pri[:2] + rest)[:k]
    return [str(x) for x in out]


def plural(n, one, few, many):
    n = abs(n)
    if n % 10 == 1 and n % 100 != 11:
        return one
    if 2 <= n % 10 <= 4 and not 12 <= n % 100 <= 14:
        return few
    return many
