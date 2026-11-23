"""Английский язык, 4 класс (Spotlight 4)."""
from eng_common import *

APPEAR = [("tall", "высокий", "🦒"), ("short", "низкий", "🐭"), ("thin", "худой", "🦩"), ("plump", "полный", "🐼"), ("curly hair", "кудрявые волосы", "👩‍🦱"), ("straight hair", "прямые волосы", "👱"), ("kind", "добрый", "😊"), ("funny", "смешной", "😄"), ("clever", "умный", "🧠"), ("friendly", "дружелюбный", "🤝")]
BELONG = [("watch", "часы (наручные)", "⌚"), ("camera", "фотоаппарат", "📷"), ("phone", "телефон", "📱"), ("backpack", "рюкзак", "🎒"), ("glasses", "очки", "👓"), ("umbrella", "зонт", "☂️"), ("keys", "ключи", "🔑"), ("wallet", "кошелёк", "👛")]
N100 = [("sixty", "шестьдесят", ""), ("seventy", "семьдесят", ""), ("eighty", "восемьдесят", ""), ("ninety", "девяносто", ""), ("a hundred", "сто", "💯"), ("sixty-five", "шестьдесят пять", ""), ("seventy-two", "семьдесят два", ""), ("ninety-nine", "девяносто девять", "")]
JOBS = [("doctor", "врач", "🧑‍⚕️"), ("teacher", "учитель", "🧑‍🏫"), ("vet", "ветеринар", "🐾"), ("pilot", "лётчик", "🧑‍✈️"), ("fireman", "пожарный", "🧑‍🚒"), ("policeman", "полицейский", "👮"), ("cook", "повар", "🧑‍🍳"), ("postman", "почтальон", "📮"), ("nurse", "медсестра", "💉"), ("farmer", "фермер", "🧑‍🌾")]
PLACES = [("hospital", "больница", "🏥"), ("school", "школа", "🏫"), ("café", "кафе", "☕"), ("police station", "полицейский участок", "🚓"), ("fire station", "пожарная часть", "🚒"), ("baker's", "булочная", "🥖"), ("post office", "почта", "🏤"), ("farm", "ферма", "🚜"), ("vet's", "ветлечебница", "🐕")]
FOOD = [("flour", "мука", "🌾"), ("butter", "масло", "🧈"), ("sugar", "сахар", "🍬"), ("eggs", "яйца", "🥚"), ("tea", "чай", "🍵"), ("coffee", "кофе", "☕"), ("lemons", "лимоны", "🍋"), ("cherries", "вишни", "🍒"), ("biscuits", "печенье", "🍪"), ("jam", "варенье", "🫙")]
WILD = [("giraffe", "жираф", "🦒"), ("hippo", "бегемот", "🦛"), ("crocodile", "крокодил", "🐊"), ("zebra", "зебра", "🦓"), ("monkey", "обезьяна", "🐒"), ("tiger", "тигр", "🐅"), ("penguin", "пингвин", "🐧"), ("kangaroo", "кенгуру", "🦘"), ("snake", "змея", "🐍"), ("bear", "медведь", "🐻")]
MONTHS = [("January", "январь", ""), ("February", "февраль", ""), ("March", "март", ""), ("April", "апрель", ""), ("May", "май", ""), ("June", "июнь", ""), ("July", "июль", ""), ("August", "август", ""), ("September", "сентябрь", ""), ("October", "октябрь", ""), ("November", "ноябрь", ""), ("December", "декабрь", "")]
FEEL = [("happy", "счастливый", "😀"), ("sad", "грустный", "😢"), ("tired", "уставший", "😴"), ("hungry", "голодный", "🤤"), ("thirsty", "хочет пить", "🥵"), ("scared", "испуганный", "😨"), ("angry", "сердитый", "😠"), ("bored", "скучающий", "🥱")]
FUN = [("theme park", "парк развлечений", "🎢"), ("rollercoaster", "американские горки", "🎢"), ("big wheel", "колесо обозрения", "🎡"), ("merry-go-round", "карусель", "🎠"), ("zoo", "зоопарк", "🦁"), ("aquarium", "аквариум", "🐠"), ("museum", "музей", "🏛️"), ("party", "праздник", "🎉")]
COUNTRIES = [("Russia", "Россия", "🇷🇺"), ("England", "Англия", "🏴"), ("France", "Франция", "🇫🇷"), ("Italy", "Италия", "🇮🇹"), ("Spain", "Испания", "🇪🇸"), ("China", "Китай", "🇨🇳"), ("Egypt", "Египет", "🇪🇬"), ("the USA", "США", "🇺🇸")]
HOLI = [("beach", "пляж", "🏖️"), ("mountains", "горы", "⛰️"), ("camping", "поход с палаткой", "⛺"), ("swimsuit", "купальник", "👙"), ("suitcase", "чемодан", "🧳"), ("sunny", "солнечно", "☀️"), ("rainy", "дождливо", "🌧️"), ("raincoat", "плащ", "🧥"), ("boots", "сапоги", "👢"), ("map", "карта", "🗺️")]


def t_appearance(r):
    return vocab_tasks(r, APPEAR, "внешность и характер")


def t_belongings(r):
    return vocab_tasks(r, BELONG, "личные вещи")


def t_numbers100(r):
    t = vocab_tasks(r, N100, "числа до 100", n_listen=4)
    t.append(inp("Сколько будет fifty + fifty? Напиши словом.", "a hundred", "50 + 50 = 100 — a hundred.", "Сто.", alts=["one hundred", "hundred"], kb="text"))
    t.append(order("Расставь по возрастанию.", ["sixty", "seventy", "eighty", "ninety"], "60, 70, 80, 90.", "Начни с sixty."))
    return t


def t_prepositions(r):
    t = []
    for s, a, ru in [("The cat is ___ the box. (в)", "in", "в"), ("The lamp is ___ the table. (на)", "on", "на"), ("The ball is ___ the chair. (под)", "under", "под"), ("The tree is ___ the house. (позади)", "behind", "позади"),
                     ("The dog is ___ the door. (перед)", "in front of", "перед"), ("The bank is ___ the café and the shop. (между)", "between", "между")]:
        t.append(fill(s, a, [x for x in ["in", "on", "under", "behind", "in front of", "between", "next to"] if x != a][:2], f"{a} — {ru}.", "Вспомни предлоги места."))
    t.append(match("Соедини предлог и перевод.", [("between", "между"), ("behind", "позади"), ("next to", "рядом"), ("in front of", "перед")], "Предлоги места.", "Вспомни картинки."))
    t.append(listen("Послушай и выбери перевод.", "The park is between the school and the hospital.", "Парк между школой и больницей.", ["Парк за школой.", "Парк перед больницей."], "Between — между.", "Between."))
    t.append(fix("Найди ошибку: «The book is in front the bag».", ["The", "book", "is", "in front", "the", "bag"], 3, "in front of", ["in", "front"], "Правильно: in front of.", "Не забудь of."))
    return t


def t_havegot_pc(r):
    t = []
    for s, a, d in [("She ___ got green eyes.", "has", ["have"]), ("They ___ got a dog.", "have", ["has"]), ("Look! He ___ running.", "is", ["are"]), ("We ___ playing now.", "are", ["is"]), ("I ___ wearing a hat now.", "am", ["is"])]:
        t.append(fill(s, a, d, "He/she/it has got; am/is/are + -ing — сейчас.", "Кто подлежащее?"))
    t.append(sort_("Разложи.", [("have got", ["I've got a cat.", "He hasn't got a bike."]), ("Present Continuous", ["She is reading.", "They are dancing."])], "Обладание и действие сейчас.", "Есть -ing?"))
    t.append(ch("Как сказать «У неё нет брата»?", "She hasn't got a brother.", ["She haven't got a brother.", "She isn't got a brother."], "She hasn't got.", "Has not."))
    t.append(fix("Найди ошибку: «He are wearing a cap».", ["He", "are", "wearing", "a", "cap"], 1, "is", ["am", "be"], "He is.", "He — is."))
    t.append(build("Составь: «Что ты сейчас делаешь?»", ["What", "are", "you", "doing?"], ["do"], "What are you doing?", "Are + -ing."))
    return t


def t_jobs(r):
    return vocab_tasks(r, JOBS, "профессии")


def t_workplaces(r):
    t = vocab_tasks(r, PLACES, "места в городе")
    t.append(ch("Где работает врач?", "hospital", ["farm", "school", "café"], "Doctor works at a hospital.", "Больница."))
    return t


def t_clock(r):
    t = []
    for h, m, s in [(3, 0, "It's three o'clock."), (7, 30, "It's half past seven."), (9, 15, "It's quarter past nine."), (4, 45, "It's quarter to five."), (12, 0, "It's twelve o'clock.")]:
        t.append(ch("What's the time?", s, r.sample(["It's three o'clock.", "It's half past seven.", "It's quarter past nine.", "It's quarter to five.", "It's twelve o'clock.", "It's half past two."], 4)[:3] if False else
                    [x for x in ["It's three o'clock.", "It's half past seven.", "It's quarter past nine.", "It's quarter to five.", "It's twelve o'clock."] if x != s][:3],
                    f"{h}:{m:02d} — {s}", "o'clock — ровно, half past — половина, quarter past — четверть после, quarter to — без четверти.", pic={"k": "clock", "h": h, "m": m}))
    t.append(match("Соедини.", [("o'clock", "ровно"), ("half past", "половина"), ("quarter past", "четверть после"), ("quarter to", "без четверти")], "Время по-английски.", "Вспомни часы."))
    t.append(listen("Послушай и выбери время.", "It's half past ten.", "10:30", ["10:15", "9:30", "11:30"], "Half past ten — 10:30.", "Half past — половина."))
    t.append(ch("Как спросить «Который час?»", "What's the time?", ["How old are you?", "What's your name?"], "What's the time? / What time is it?", "Time — время."))
    t.append(fix("Найди ошибку: 6:30 — «It's half to six».", ["It's", "half", "to", "six"], 2, "past", ["of", "on"], "6:30 — half past six.", "Половина после."))
    return t


def t_frequency(r):
    t = []
    for s, a in [("Я всегда чищу зубы. — I ___ brush my teeth.", "always"), ("Я обычно хожу в школу пешком. — I ___ walk to school.", "usually"), ("Иногда я играю в шахматы. — I ___ play chess.", "sometimes"), ("Я никогда не опаздываю. — I ___ come late.", "never")]:
        t.append(fill(s, a, [x for x in ["always", "usually", "sometimes", "never"] if x != a][:3], f"{a} — {dict(always='всегда', usually='обычно', sometimes='иногда', never='никогда')[a]}.", "Как часто?"))
    t.append(order("Расставь от «всегда» до «никогда».", ["always", "usually", "sometimes", "never"], "100% → 0%.", "Начни с always."))
    t.append(match("Соедини.", [("always", "всегда"), ("usually", "обычно"), ("sometimes", "иногда"), ("never", "никогда")], "Наречия частотности.", "Как часто?"))
    t.append(ch("Где ставится наречие частотности?", "перед смысловым глаголом: I often play", ["в конце всегда", "перед подлежащим"], "He always gets up early.", "Перед глаголом."))
    t.append(fix("Найди ошибку: «She goes always to bed at 9».", ["She", "goes", "always", "to", "bed"], 1, "always goes", ["go", "going"], "Наречие перед глаголом: She always goes.", "Порядок слов."))
    t.append(listen("Послушай и выбери перевод.", "He never watches TV.", "Он никогда не смотрит телевизор.", ["Он всегда смотрит телевизор.", "Он иногда смотрит телевизор."], "Never — никогда.", "Never."))
    t.append(build("Составь: «Я обычно встаю в 7».", ["I", "usually", "get", "up", "at", "7."], ["always"], "I usually get up at 7.", "Usually — обычно."))
    return t


def t_have_to(r):
    t = []
    for s, a, d in [("I ___ to do my homework.", "have", ["has"]), ("She ___ to feed the cat.", "has", ["have"]), ("A doctor ___ to help people.", "has", ["have"]), ("We ___ to wear a uniform.", "have", ["has"])]:
        t.append(fill(s, a, d, "Have to / has to — нужно, приходится (he/she/it — has to).", "Кто подлежащее?"))
    t.append(ch("Что значит «I have to get up early»?", "Мне нужно рано вставать.", ["Я люблю рано вставать.", "Я умею рано вставать."], "Have to — должен, приходится.", "Обязанность."))
    t.append(ch("Как сказать «Ему не нужно спешить»?", "He doesn't have to hurry.", ["He hasn't to hurry.", "He don't have to hurry."], "Отрицание: doesn't have to.", "Doesn't."))
    t.append(match("Соедини профессию и обязанность.", [("fireman", "has to put out fires"), ("postman", "has to deliver letters"), ("vet", "has to help animals")], "Have to — обязанности.", "Что должен делать?"))
    t.append(fix("Найди ошибку: «He have to work today».", ["He", "have", "to", "work"], 1, "has", ["having", "is"], "He has to.", "He — has."))
    t.append(build("Составь вопрос: «Тебе нужно убирать комнату?»", ["Do", "you", "have", "to", "tidy", "your", "room?"], ["Does"], "Do you have to tidy your room?", "Do you have to…"))
    t.append(tf("«She has to go to school on Monday» — правильно.", True, "She has to.", "Проверь форму."))
    return t


def t_shop_food(r):
    return vocab_tasks(r, FOOD, "продукты")


def t_containers(r):
    t = []
    for w, c, ru in [("milk", "carton", "пакет молока"), ("jam", "jar", "банка варенья"), ("biscuits", "packet", "пачка печенья"), ("beans", "tin", "консервная банка фасоли"), ("water", "bottle", "бутылка воды"), ("chocolate", "bar", "плитка шоколада"), ("bread", "loaf", "буханка хлеба")]:
        t.append(fill(f"a ___ of {w}", c, [x for x in ["carton", "jar", "packet", "tin", "bottle", "bar", "loaf"] if x != c][:2], f"a {c} of {w} — {ru}.", "Во что упаковано?"))
    t.append(match("Соедини.", [("a jar of", "банка (стеклянная)"), ("a tin of", "консервная банка"), ("a carton of", "картонный пакет")], "Ёмкости.", "Из чего упаковка?"))
    t.append(listen("Послушай и выбери перевод.", "a bottle of lemonade", "бутылка лимонада", ["банка лимонада", "пакет лимонада"], "Bottle — бутылка.", "Bottle."))
    t.append(fix("Найди ошибку: «a loaf of milk».", ["a", "loaf", "of", "milk"], 1, "carton", ["bar", "loafs"], "Молоко — в пакете: a carton of milk.", "Loaf — для хлеба."))
    return t


def t_count_uncount(r):
    t = []
    for s, a, d in [("How ___ apples?", "many", ["much"]), ("How ___ milk?", "much", ["many"]), ("There isn't ___ sugar.", "much", ["many"]), ("There aren't ___ eggs.", "many", ["much"]), ("I've got ___ sweets. (много)", "a lot of", ["much"])]:
        t.append(fill(s, a, d, "Many — с исчисляемыми (apples), much — с неисчисляемыми (milk); a lot of — с любыми.", "Можно ли посчитать?"))
    t.append(sort_("Исчисляемые или нет?", [("Исчисляемые", ["apple", "egg", "banana"]), ("Неисчисляемые", ["milk", "sugar", "water"])], "Неисчисляемые нельзя посчитать штуками.", "Можно сказать «два …»?"))
    t.append(ch("Что употребляется и с исчисляемыми, и с неисчисляемыми?", "a lot of", ["many", "much"], "A lot of — много чего угодно.", "Универсальное."))
    t.append(fix("Найди ошибку: «How much bananas do you want?»", ["How", "much", "bananas"], 1, "many", ["lot", "few"], "Bananas исчисляемые — many.", "Можно посчитать."))
    t.append(tf("«How much water?» — правильно.", True, "Water неисчисляемое — much.", "Water."))
    return t


def t_may_i(r):
    t = say_tasks(r, [("May I have some juice, please?", "Можно мне сока, пожалуйста?", ["Я люблю сок.", "У меня нет сока."]), ("Can I help you?", "Чем могу помочь?", ["Помоги мне!", "Можно войти?"])])
    t.append(ch("Как вежливо попросить печенье?", "May I have a biscuit, please?", ["Give biscuit!", "I biscuit."], "May I… please? — вежливая просьба.", "May I…"))
    t.append(ch("Как вежливо ответить на просьбу согласием?", "Yes, of course. Here you are.", ["No!", "Go away."], "Here you are — вот, пожалуйста.", "Вежливо."))
    t.append(order("Восстанови диалог в магазине.", ["Can I help you?", "May I have a carton of milk, please?", "Here you are.", "Thank you!"], "Диалог в магазине.", "Начни с продавца."))
    t.append(build("Составь: «Можно мне чашку чая?»", ["May", "I", "have", "a", "cup", "of", "tea?"], ["Can't"], "May I have a cup of tea?", "May I have…"))
    t.append(fill("___ I come in?", "May", ["Do", "Am"], "May I come in? — Можно войти?", "Разрешение."))
    t.append(fix("Найди ошибку: «May I has some cake?»", ["May", "I", "has", "some", "cake?"], 2, "have", ["am", "is"], "После may — have.", "May I have."))
    t.append(tf("«Here you are» говорят, когда что-то протягивают.", True, "Here you are — возьмите, пожалуйста.", "Протягивая."))
    return t


def t_wild_animals(r):
    return vocab_tasks(r, WILD, "дикие животные")


def t_months(r):
    t = vocab_tasks(r, MONTHS, "месяцы", n_listen=3)
    t.append(order("Расставь весенние месяцы.", ["March", "April", "May"], "Март, апрель, май.", "Начни с марта."))
    t.append(ch("В каком месяце Новый год?", "January", ["June", "March", "October"], "1 января — Новый год.", "Первый месяц."))
    return t


def t_comparative(r):
    t = []
    for adj, comp in [("big", "bigger"), ("tall", "taller"), ("small", "smaller"), ("fast", "faster"), ("happy", "happier"), ("fat", "fatter")]:
        t.append(ch(f"Сравнительная степень от «{adj}»:", comp, [adj + "er" if comp != adj + "er" else adj + "est", "more " + adj], f"{adj} — {comp}.", "Обычно прибавляем -er; y → i; удваиваем согласную после краткой гласной."))
    t.append(fill("An elephant is ___ than a mouse.", "bigger", ["big", "biggest"], "Сравнение двух: bigger than.", "Сравниваем двоих."))
    t.append(ch("Как сказать «лучше»?", "better", ["gooder", "more good"], "Good — better (исключение).", "Исключение."))
    t.append(fix("Найди ошибку: «A giraffe is taller then a horse».", ["taller", "then", "a", "horse"], 1, "than", ["that", "this"], "Сравнение — than.", "Than."))
    t.append(build("Составь: «Тигр быстрее черепахи».", ["A", "tiger", "is", "faster", "than", "a", "tortoise."], ["fastest"], "A tiger is faster than a tortoise.", "-er than."))
    return t


def t_must(r):
    t = []
    for s, ok in [("You must feed the animals at the zoo.", False), ("You mustn't feed the animals at the zoo.", True), ("You must cross the road at the zebra crossing.", True), ("You must shout in the library.", False)]:
        t.append(tf(f"Правило: «{s}»", ok, "Must — должен, mustn't — нельзя.", "Это хорошее правило?"))
    t.append(match("Соедини.", [("must", "должен"), ("mustn't", "нельзя")], "Must / mustn't.", "Запрет — mustn't."))
    t.append(fill("You ___ be quiet in the library. (должен)", "must", ["mustn't", "can't to"], "Must — должен.", "Обязанность."))
    t.append(fill("You ___ run in the classroom. (нельзя)", "mustn't", ["must", "have"], "Mustn't — нельзя.", "Запрет."))
    t.append(ch("Что значит «You mustn't touch»?", "Трогать нельзя.", ["Нужно трогать.", "Можно трогать."], "Mustn't — запрет.", "Не…"))
    t.append(fix("Найди ошибку: «You must to wash your hands».", ["You", "must", "to", "wash"], 2, "—", ["can", "do"], "После must глагол без to: You must wash your hands.", "Лишнее слово.") if False else
             fix("Найди ошибку: «You must washing your hands».", ["You", "must", "washing", "your", "hands"], 2, "wash", ["washes", "to washing"], "После must глагол без изменений.", "Must + глагол."))
    t.append(build("Составь: «Ты должен слушать учителя».", ["You", "must", "listen", "to", "the", "teacher."], ["mustn't"], "You must listen to the teacher.", "Must."))
    return t


def t_ps_vs_pc(r):
    t = []
    for s, a, d in [("Look! The monkey ___ (climb) a tree.", "is climbing", ["climbs"]), ("Monkeys ___ (climb) trees every day.", "climb", ["are climbing"]), ("Listen! The bird ___ (sing).", "is singing", ["sings"]),
                    ("Penguins ___ (eat) fish.", "eat", ["are eating"]), ("Now the elephant ___ (drink) water.", "is drinking", ["drinks"])]:
        t.append(fill(s, a, d, "Look!/Listen!/now — Present Continuous; привычки и факты — Present Simple.", "Сейчас или всегда?"))
    t.append(sort_("Разложи маркеры времени.", [("Present Simple", ["every day", "usually", "often"]), ("Present Continuous", ["now", "Look!", "at the moment"])], "Слова-подсказки времени.", "Сейчас или регулярно?"))
    t.append(ch("Какое предложение о том, что происходит сейчас?", "The kangaroo is jumping.", ["Kangaroos jump.", "The kangaroo jumps every day."], "Is jumping — сейчас.", "-ing."))
    t.append(fix("Найди ошибку: «Look! The baby sleeps now».", ["Look!", "The", "baby", "sleeps", "now"], 3, "is sleeping", ["sleep", "slept"], "Now — Present Continuous.", "Сейчас."))
    t.append(tf("«Giraffes eat leaves» — Present Simple.", True, "Факт — Present Simple.", "Это факт."))
    return t


def t_ordinals(r):
    t = []
    for n, w in [(1, "first"), (2, "second"), (3, "third"), (5, "fifth"), (12, "twelfth"), (20, "twentieth")]:
        t.append(ch(f"Порядковое числительное для {n}:", w, [x for x in ["first", "second", "third", "fifth", "twelfth", "twentieth", "fiveth"] if x != w][:3], f"{n} — {w}.", "1st, 2nd, 3rd — особые формы."))
    t.append(match("Соедини.", [("1st", "first"), ("2nd", "second"), ("3rd", "third"), ("4th", "fourth")], "Порядковые числительные.", "Особые первые три."))
    t.append(listen("Послушай и выбери дату.", "the first of September", "1 сентября", ["3 сентября", "1 ноября", "21 сентября"], "The first of September — 1 сентября.", "First, September."))
    t.append(ch("Как сказать «Мой день рождения 10 мая»?", "My birthday is on the tenth of May.", ["My birthday is ten May.", "My birthday is in the ten May."], "On the tenth of May.", "On the …th of …"))
    t.append(fix("Найди ошибку: «the fiveth of June».", ["the", "fiveth", "of", "June"], 1, "fifth", ["five", "fivth"], "Five — fifth.", "Особая форма."))
    return t


def t_feelings(r):
    t = vocab_tasks(r, FEEL, "чувства")
    t.append(ch("Мальчик хочет есть. He is…", "hungry", ["thirsty", "tired", "bored"], "Hungry — голодный.", "Хочет есть."))
    return t


def t_was_were(r):
    t = []
    for s, a in [("I ___ at home yesterday.", "was"), ("They ___ at the zoo.", "were"), ("She ___ happy.", "was"), ("We ___ tired.", "were"), ("You ___ at school.", "were"), ("It ___ sunny yesterday.", "was")]:
        t.append(fill(s, a, ["were" if a == "was" else "was"], "I/he/she/it — was; we/you/they — were.", "Кто подлежащее?"))
    t.append(ch("Как спросить «Где ты был вчера?»", "Where were you yesterday?", ["Where was you yesterday?", "Where are you yesterday?"], "You — were.", "You were."))
    t.append(ch("Как сказать «Я не был грустным»?", "I wasn't sad.", ["I weren't sad.", "I not was sad."], "Was not = wasn't.", "Wasn't."))
    t.append(fix("Найди ошибку: «We was at the party».", ["We", "was", "at", "the", "party"], 1, "were", ["is", "are"], "We were.", "We — were."))
    t.append(build("Составь: «Он был в парке».", ["He", "was", "in", "the", "park."], ["were"], "He was in the park.", "He — was."))
    return t


def t_past_regular(r):
    t = []
    for v, p in [("play", "played"), ("watch", "watched"), ("dance", "danced"), ("stop", "stopped"), ("cry", "cried"), ("jump", "jumped"), ("visit", "visited")]:
        t.append(ch(f"Прошедшее время глагола «{v}»:", p, [v + "ed" if p != v + "ed" else v + "d", v + "s"], f"{v} — {p}.", "Правильные глаголы: -ed (dance → danced, stop → stopped, cry → cried)."))
    t.append(fill("Yesterday I ___ (help) my mum.", "helped", ["help", "helps"], "Yesterday — Past Simple: helped.", "Вчера."))
    t.append(sort_("Как читается окончание -ed?", [("[t]", ["jumped", "watched"]), ("[d]", ["played", "cleaned"]), ("[id]", ["wanted", "visited"])], "Чтение -ed зависит от последнего звука.", "Послушай последний звук."))
    t.append(fix("Найди ошибку: «Last week we visit our granny».", ["Last", "week", "we", "visit", "our"], 3, "visited", ["visits", "visiting"], "Last week — Past Simple.", "Прошлое."))
    t.append(listen("Послушай и выбери перевод.", "She cooked dinner.", "Она приготовила ужин.", ["Она готовит ужин.", "Она приготовит ужин."], "Cooked — прошедшее время.", "-ed."))
    return t


def t_past_neg_q(r):
    t = []
    for s, a, d in [("I ___ watch TV yesterday.", "didn't", ["don't", "wasn't"]), ("___ you play football yesterday?", "Did", ["Do", "Were"]), ("She didn't ___ the window.", "open", ["opened", "opens"]), ("Did he ___ his friend?", "call", ["called", "calls"])]:
        t.append(fill(s, a, d, "Past Simple: отрицание didn't + глагол, вопрос Did + подлежащее + глагол (без -ed).", "После did глагол без -ed."))
    t.append(ch("— Did you like the film? — Yes, ___", "I did.", ["I liked.", "I do."], "Краткий ответ: Yes, I did. / No, I didn't.", "Did — did."))
    t.append(build("Составь вопрос: «Ты убрал комнату?»", ["Did", "you", "tidy", "your", "room?"], ["tidied"], "Did you tidy your room?", "Did + глагол."))
    t.append(fix("Найди ошибку: «He didn't played chess».", ["He", "didn't", "played", "chess"], 2, "play", ["plays", "playing"], "После didn't — play.", "Без -ed."))
    t.append(sort_("Разложи предложения.", [("Отрицание", ["I didn't jump.", "They didn't walk."]), ("Вопрос", ["Did you jump?", "Did they walk?"])], "Didn't — отрицание, Did…? — вопрос.", "Где вопросительный знак?"))
    t.append(order("Расставь слова в вопросе.", ["Did", "she", "visit", "London?"], "Did + подлежащее + глагол.", "Начни с Did."))
    t.append(tf("«Did you watched TV?» — правильно.", False, "Правильно: Did you watch TV?", "После did глагол без -ed."))
    return t


def t_entertainment(r):
    return vocab_tasks(r, FUN, "развлечения")


def t_superlative(r):
    t = []
    for adj, sup in [("big", "the biggest"), ("tall", "the tallest"), ("small", "the smallest"), ("funny", "the funniest"), ("good", "the best"), ("fast", "the fastest")]:
        t.append(ch(f"Превосходная степень от «{adj}»:", sup, ["the " + adj + "er", adj + "est" if sup != "the " + adj + "est" else "the most " + adj], f"{adj} — {sup}.", "The + -est (good → the best)."))
    t.append(fill("The giraffe is ___ animal in the zoo. (самый высокий)", "the tallest", ["taller", "tall"], "Самый — the + -est.", "Самый."))
    t.append(sort_("Сравнительная или превосходная?", [("Сравнительная", ["bigger", "better"]), ("Превосходная", ["the biggest", "the best"])], "-er — сравнение двоих, the -est — самый.", "Самый или «чем»?"))
    t.append(fix("Найди ошибку: «It's the goodest day of my life».", ["the", "goodest", "day"], 1, "best", ["better", "most good"], "Good — the best.", "Исключение."))
    t.append(build("Составь: «Это самый смешной клоун».", ["He", "is", "the", "funniest", "clown."], ["funnier"], "He is the funniest clown.", "The + -iest."))
    return t


def t_past_irregular(r):
    t = []
    for v, p in [("go", "went"), ("see", "saw"), ("have", "had"), ("eat", "ate"), ("make", "made"), ("buy", "bought"), ("swim", "swam"), ("fly", "flew")]:
        t.append(ch(f"Прошедшее время неправильного глагола «{v}»:", p, [v + "ed", v + "s"], f"{v} — {p} (нужно запомнить).", "Неправильный глагол."))
    t.append(match("Соедини.", [("go", "went"), ("see", "saw"), ("eat", "ate"), ("have", "had")], "Неправильные глаголы.", "Запомни формы."))
    t.append(fix("Найди ошибку: «Yesterday we goed to the theme park».", ["Yesterday", "we", "goed", "to"], 2, "went", ["go", "gone"], "Go — went.", "Неправильный."))
    t.append(listen("Послушай и выбери перевод.", "We saw a big lion.", "Мы видели большого льва.", ["Мы видим большого льва.", "Мы увидим льва."], "Saw — прошедшее от see.", "Saw."))
    return t


def t_countries(r):
    t = vocab_tasks(r, COUNTRIES, "страны")
    t.append(ch("В какой стране находится Лондон?", "England", ["France", "Italy", "China"], "London — столица Англии (Великобритании).", "Биг-Бен."))
    return t


def t_holiday_types(r):
    t = vocab_tasks(r, HOLI, "отдых, погода, одежда")
    t.append(ch("Идёт дождь. Что надеть?", "raincoat", ["swimsuit", "sunglasses", "shorts"], "Raincoat — плащ.", "От дождя."))
    return t


def t_going_to(r):
    t = []
    for s, a, d in [("I ___ going to visit my granny.", "am", ["is", "are"]), ("She ___ going to swim.", "is", ["am", "are"]), ("They ___ going to fly to Spain.", "are", ["is", "am"]), ("We are going ___ play tennis.", "to", ["for", "at"])]:
        t.append(fill(s, a, d, "Be going to — собираться (планы): am/is/are + going to + глагол.", "Am, is или are?"))
    t.append(ch("Что значит «I'm going to buy a kite»?", "Я собираюсь купить воздушного змея.", ["Я купил змея.", "Я иду в магазин змеев."], "Be going to — план.", "Собираться."))
    t.append(build("Составь: «Мы собираемся пойти в поход».", ["We", "are", "going", "to", "go", "camping."], ["is"], "We are going to go camping.", "Are going to…"))
    t.append(fix("Найди ошибку: «He are going to read».", ["He", "are", "going", "to", "read"], 1, "is", ["am", "be"], "He is going to.", "He — is."))
    t.append(ch("Как спросить «Что ты собираешься делать?»", "What are you going to do?", ["What you going do?", "What do you going?"], "What are you going to do?", "Are you going to…"))
    t.append(listen("Послушай и выбери перевод.", "They are going to play football.", "Они собираются играть в футбол.", ["Они играли в футбол.", "Они играют в футбол каждый день."], "Going to — собираются.", "План."))
    t.append(tf("«Be going to» говорят о планах на будущее.", True, "Да, это планы.", "Будущее."))
    return t


def t_will(r):
    t = []
    for s, a, d in [("I think it ___ rain tomorrow.", "will", ["is", "am"]), ("I ___ help you!", "'ll", ["am", "is"]), ("She ___ be ten next year.", "will", ["is going", "was"]), ("It ___ be sunny tomorrow. (не будет)", "won't", ["will", "don't"])]:
        t.append(fill(s, a, d, "Will — будущее (предсказание, решение в момент речи), won't = will not.", "Будущее."))
    t.append(ch("Что значит «I'll call you»?", "Я позвоню тебе.", ["Я звоню тебе.", "Я звонил тебе."], "I'll = I will.", "Будущее."))
    t.append(sort_("Will или going to?", [("Решение сейчас / предсказание", ["I'll open the window.", "It will be cold."]), ("Заранее принятый план", ["I'm going to visit Paris.", "We're going to paint the room."])], "Will — решение сейчас; going to — план.", "Заранее или сейчас?"))
    t.append(fix("Найди ошибку: «Tomorrow I will to go to the zoo».", ["I", "will", "to", "go"], 2, "—", ["be", "am"], "После will — глагол без to: I will go.", "Лишнее слово.") if False else
             fix("Найди ошибку: «Tomorrow she wills come».", ["Tomorrow", "she", "wills", "come"], 2, "will", ["willing", "would"], "Will не изменяется: she will come.", "Без -s."))
    t.append(build("Составь: «Завтра будет солнечно».", ["It", "will", "be", "sunny", "tomorrow."], ["is"], "It will be sunny tomorrow.", "Will be."))
    t.append(tf("«Won't» — это «will not».", True, "Won't = will not.", "Отрицание."))
    return t
