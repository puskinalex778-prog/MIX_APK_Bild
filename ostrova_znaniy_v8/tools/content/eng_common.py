"""Общие генераторы для английского языка (Spotlight 2–4)."""
from common import *


def vocab_tasks(r, words, topic_ru, n_listen=3, extra_spell=True):
    """words: [(english, russian, emoji)] -> разнообразные задания по лексике (≥9)."""
    t = []
    ws = list(words)
    r.shuffle(ws)
    en_all = [w[0] for w in words]
    ru_all = [w[1] for w in words]
    for en, ru, em in ws[:n_listen]:
        t.append(listen("Послушай и выбери слово.", en, en, r.sample([x for x in en_all if x != en], min(3, len(en_all) - 1)),
                        f"Ты услышал(а) «{en}» — это «{ru}».", "Нажми на кнопку со звуком ещё раз.", pic=None))
    for en, ru, em in ws[n_listen:n_listen + 2]:
        t.append(ch(f"Как переводится слово «{en}»?", ru, r.sample([x for x in ru_all if x != ru], min(3, len(ru_all) - 1)), f"{en} — {ru}.", f"Тема: {topic_ru}."))
    for en, ru, em in ws[n_listen + 2:n_listen + 4]:
        t.append(ch(f"Как по-английски «{ru}»?", en, r.sample([x for x in en_all if x != en], min(3, len(en_all) - 1)), f"«{ru}» — {en}.", f"Тема: {topic_ru}."))
    pic_words = [w for w in ws if w[2]]
    for en, ru, em in pic_words[:2]:
        t.append(ch("Что на картинке? Выбери слово.", en, r.sample([x for x in en_all if x != en], min(3, len(en_all) - 1)), f"На картинке {ru} — {en}.", "Вспомни, как это называется по-английски.", pic={"k": "big", "e": em}))
    if extra_spell:
        cand = [w for w in ws if " " not in w[0] and len(w[0]) <= 8]
        if cand:
            en, ru, em = cand[-1]
            t.append(inp(f"Напиши по-английски: «{ru}».", en, f"«{ru}» — {en}.", f"Слово начинается на «{en[0]}» и в нём {len(en)} букв.", kb="text"))
    if len(ws) >= 4:
        t.append(match("Соедини английское слово и перевод.", [(w[0], w[1]) for w in r.sample(ws, 4)], "Повтори слова темы.", "Начни с самого знакомого слова."))
    return t


def say_tasks(r, items):
    """items: [(english phrase, russian meaning, [distractor meanings])] — задания на понимание фраз на слух."""
    return [listen("Послушай фразу. Что она значит?", en, ru, ds, f"«{en}» — {ru}.", "Послушай ещё раз и вспомни слова.") for en, ru, ds in items]
