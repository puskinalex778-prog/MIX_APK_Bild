"""Общие приёмы для заданий по русскому языку."""
from common import *


def gaps(r, words, prompt_tpl, expl_tpl, hint, n=4, options=None):
    """words: [(word_with_gap '_', answer_letter, explanation_detail)]"""
    out = []
    for w, a, det in r.sample(words, min(n, len(words))):
        opts = options or sorted({a, *[o for o in ("а", "о", "е", "и", "я") if o != a][:2]})
        out.append(fill(prompt_tpl.format(w=w.replace("_", "___")), a, [o for o in opts if o != a], expl_tpl.format(full=w.replace("_", a), det=det), hint))
    return out


def classify(r, prompt, cats, n_per=3, expl="", hint=""):
    """cats: [(name, [words])] -> одно задание на сортировку"""
    picked = [(name, r.sample(ws, min(n_per, len(ws)))) for name, ws in cats]
    return sort_(prompt, picked, expl, hint)


def pick_one(r, prompt_tpl, cat_words, all_cats, n, expl_tpl, hint):
    """Задания «к какой группе относится слово»: cat_words [(word, cat)]"""
    out = []
    for w, c in r.sample(cat_words, min(n, len(cat_words))):
        out.append(ch(prompt_tpl.format(w=w), c, [x for x in all_cats if x != c], expl_tpl.format(w=w, c=c), hint))
    return out
