"""Английский язык, 2 класс (Spotlight 2)."""
from eng_common import *

COLOURS = [("red", "красный", "🟥"), ("blue", "синий", "🟦"), ("green", "зелёный", "🟩"), ("yellow", "жёлтый", "🟨"), ("black", "чёрный", "⬛"), ("white", "белый", "⬜"), ("orange", "оранжевый", "🟧"), ("purple", "фиолетовый", "🟪"), ("brown", "коричневый", "🟫")]
FAMILY = [("mummy", "мама", "👩"), ("daddy", "папа", "👨"), ("grandma", "бабушка", "👵"), ("grandpa", "дедушка", "👴"), ("sister", "сестра", "👧"), ("brother", "брат", "👦"), ("family", "семья", "👪")]
ROOMS = [("bedroom", "спальня", "🛏️"), ("kitchen", "кухня", "🍳"), ("bathroom", "ванная", "🛁"), ("living room", "гостиная", "🛋️"), ("garden", "сад", "🌳"), ("house", "дом", "🏠"), ("tree house", "домик на дереве", "🌲")]
FURN = [("chair", "стул", "🪑"), ("table", "стол", "🪵"), ("bed", "кровать", "🛏️"), ("sofa", "диван", "🛋️"), ("bath", "ванна", "🛁"), ("window", "окно", "🪟"), ("door", "дверь", "🚪"), ("lamp", "лампа", "💡")]
NUMS = [("one", "один", "1️⃣"), ("two", "два", "2️⃣"), ("three", "три", "3️⃣"), ("four", "четыре", "4️⃣"), ("five", "пять", "5️⃣"), ("six", "шесть", "6️⃣"), ("seven", "семь", "7️⃣"), ("eight", "восемь", "8️⃣"), ("nine", "девять", "9️⃣"), ("ten", "десять", "🔟")]
FOOD = [("chips", "картофель фри", "🍟"), ("pizza", "пицца", "🍕"), ("burger", "бургер", "🍔"), ("cake", "торт", "🎂"), ("ice cream", "мороженое", "🍦"), ("lemonade", "лимонад", "🥤"), ("sweets", "конфеты", "🍬"), ("chocolate", "шоколад", "🍫"), ("milk", "молоко", "🥛"), ("apple", "яблоко", "🍎")]
ANIMALS = [("frog", "лягушка", "🐸"), ("fish", "рыба", "🐟"), ("chimp", "шимпанзе", "🐒"), ("horse", "лошадь", "🐴"), ("bird", "птица", "🐦"), ("cat", "кошка", "🐱"), ("dog", "собака", "🐶"), ("duck", "утка", "🦆"), ("mouse", "мышь", "🐭")]
ACTIONS = [("jump", "прыгать", "🦘"), ("swim", "плавать", "🏊"), ("run", "бегать", "🏃"), ("dance", "танцевать", "💃"), ("fly", "летать", "🕊️"), ("sing", "петь", "🎤"), ("climb", "лазать", "🧗"), ("sleep", "спать", "😴")]
CIRCUS = [("clown", "клоун", "🤡"), ("magician", "фокусник", "🎩"), ("acrobat", "акробат", "🤸"), ("circus", "цирк", "🎪"), ("lion", "лев", "🦁"), ("elephant", "слон", "🐘"), ("ball", "мяч", "⚽")]
TOYS = [("teddy bear", "плюшевый мишка", "🧸"), ("doll", "кукла", "🪆"), ("ball", "мяч", "⚽"), ("train", "поезд", "🚂"), ("car", "машинка", "🚗"), ("kite", "воздушный змей", "🪁"), ("robot", "робот", "🤖"), ("drum", "барабан", "🥁")]
BODY = [("eyes", "глаза", "👀"), ("ears", "уши", "👂"), ("nose", "нос", "👃"), ("mouth", "рот", "👄"), ("hands", "руки (кисти)", "✋"), ("feet", "ступни", "🦶"), ("head", "голова", "🙂"), ("hair", "волосы", "💇")]
APPEAR = [("big", "большой", "🐘"), ("small", "маленький", "🐭"), ("long", "длинный", "🦒"), ("short", "короткий", "📏"), ("fat", "толстый", "🐷"), ("thin", "худой", "🦩"), ("tall", "высокий", "🦒"), ("happy", "весёлый", "😀"), ("sad", "грустный", "😢")]
CLOTHES = [("hat", "шляпа", "👒"), ("coat", "пальто", "🧥"), ("jacket", "куртка", "🧥"), ("shoes", "туфли", "👞"), ("socks", "носки", "🧦"), ("dress", "платье", "👗"), ("jeans", "джинсы", "👖"), ("T-shirt", "футболка", "👕"), ("shorts", "шорты", "🩳"), ("sunglasses", "солнечные очки", "🕶️")]
WEATHER = [("sunny", "солнечно", "☀️"), ("rainy", "дождливо", "🌧️"), ("windy", "ветрено", "💨"), ("snowy", "снежно", "❄️"), ("cold", "холодно", "🥶"), ("hot", "жарко", "🥵"), ("cloudy", "облачно", "☁️")]
SEASONS = [("winter", "зима", "⛄"), ("spring", "весна", "🌷"), ("summer", "лето", "🌞"), ("autumn", "осень", "🍂")]
SUMMER = [("beach", "пляж", "🏖️"), ("sea", "море", "🌊"), ("sun", "солнце", "☀️"), ("sand", "песок", "🏝️"), ("swim", "плавать", "🏊"), ("holiday", "каникулы", "🧳"), ("shell", "ракушка", "🐚"), ("boat", "лодка", "⛵")]


def t_greetings(r):
    t = say_tasks(r, [("Hello!", "Привет!", ["Пока!", "Спасибо!"]), ("Goodbye!", "До свидания!", ["Привет!", "Как дела?"]), ("What's your name?", "Как тебя зовут?", ["Сколько тебе лет?", "Где ты живёшь?"]), ("I'm fine, thank you.", "Хорошо, спасибо.", ["Мне семь лет.", "Я люблю пиццу."])])
    t.append(ch("Как ответить на «What's your name?»", "I'm Anna.", ["I'm seven.", "I like pizza.", "Goodbye!"], "На вопрос об имени отвечаем: I'm … / My name is …", "Name — имя."))
    t.append(ch("Как поздороваться утром?", "Good morning!", ["Good night!", "Goodbye!"], "Good morning — доброе утро.", "Morning — утро."))
    t.append(match("Соедини фразу и перевод.", [("Hello!", "Привет!"), ("Goodbye!", "Пока!"), ("Thank you!", "Спасибо!"), ("How are you?", "Как дела?")], "Фразы приветствия и прощания.", "Начни с Hello."))
    t.append(order("Восстанови диалог.", ["Hello! I'm Larry.", "Hi! I'm Lulu.", "Nice to meet you!", "Goodbye!"], "Знакомство: приветствие, имя, прощание.", "Начни с приветствия."))
    t.append(build("Составь фразу: «Меня зовут Тим».", ["My", "name", "is", "Tim."], ["are"], "My name is Tim.", "My name is…"))
    t.append(fill("— What's your name? — ___ Masha.", "I'm", ["I", "Is"], "I'm = I am.", "Я — …"))
    return t


def t_alphabet(r):
    t = []
    letters = [("A a", "эй"), ("B b", "би"), ("C c", "си"), ("D d", "ди"), ("E e", "и:"), ("G g", "джи"), ("H h", "эйч"), ("J j", "джей"), ("R r", "а:"), ("Y y", "уай")]
    for l, s in r.sample(letters, 4):
        t.append(ch(f"Как называется буква «{l}»?", s, [x for _, x in letters if x != s][:3], f"Буква {l} называется [{s}].", "Пропой алфавит."))
    t.append(order("Расставь буквы по алфавиту.", ["a", "b", "c", "d", "e"], "Начало английского алфавита.", "ABC…"))
    t.append(order("Расставь буквы по алфавиту.", ["h", "i", "j", "k", "l"], "Английский алфавит.", "…HIJKL…"))
    t.append(inp("Сколько букв в английском алфавите?", 26, "В английском алфавите 26 букв.", "Меньше, чем в русском."))
    t.append(match("Соедини заглавную и строчную букву.", [("G", "g"), ("Q", "q"), ("R", "r"), ("B", "b")], "Заглавная и строчная.", "Как пишется маленькая?"))
    t.append(ch("С какой буквы начинается слово «apple»?", "a", ["e", "p"], "Apple начинается с A.", "Первая буква."))
    t.append(listen("Послушай букву и выбери её.", "B", "B", ["D", "P", "V"], "Буква B — [би].", "Послушай ещё раз."))
    t.append(fix("Найди ошибку в алфавите: «a, b, d, c».", ["a", "b", "d", "c"], 2, "c", ["e", "f"], "После b идёт c, потом d.", "ABC…"))
    return t


def t_phonics(r):
    t = []
    for w, a, d in [("cat", "a как [э]", ["a как [эй]", "a как [а:]"]), ("cake", "a как [эй]", ["a как [э]", "a как [о]"]), ("dog", "o как [о]", ["o как [оу]", "o как [у]"]), ("rose", "o как [оу]", ["o как [о]", "o как [а]"]),
                    ("pen", "e как [е]", ["e как [и:]", "e как [ай]"]), ("bike", "i как [ай]", ["i как [и]", "i как [эй]"])]:
        t.append(ch(f"Как читается гласная в слове «{w}»?", a, d, f"В слове {w} — {a}. Немая e на конце делает гласную «долгой» (как в алфавите).", "Есть ли немая e на конце?"))
    t.append(sort_("Разложи слова по звуку буквы «a».", [("[э]", ["cat", "bag", "hat"]), ("[эй]", ["cake", "name", "lake"])], "Открытый слог (с e на конце) — [эй].", "Есть ли e на конце?"))
    t.append(ch("Как читается сочетание «sh» в слове «ship»?", "[ш]", ["[с]", "[х]"], "sh = [ш]: ship, fish.", "Как в слове fish."))
    t.append(ch("Как читается сочетание «ch» в слове «chair»?", "[ч]", ["[к]", "[ш]"], "ch = [ч]: chair, chips.", "Как в слове chips."))
    for w in ["fish", "ship", "chips"]:
        pass
    t.append(listen("Послушай и выбери слово.", "ship", "ship", ["sheep", "chip", "shop"], "Ship — корабль.", "Послушай гласный звук."))
    t.append(ch("Как читается «ee» в слове «tree»?", "[и:]", ["[е]", "[ай]"], "ee = долгое [и:]: tree, green.", "Как в слове green."))
    return t


def t_colours(r):
    t = vocab_tasks(r, COLOURS, "цвета")
    t.append(ch("Какого цвета банан?", "yellow", ["blue", "red", "black"], "Банан жёлтый — yellow.", "Подумай о жёлтом."))
    t.append(ch("Какого цвета трава?", "green", ["red", "white", "purple"], "Трава зелёная — green.", "Зелёный."))
    return t


def t_family(r):
    t = vocab_tasks(r, FAMILY, "семья")
    t.append(fill("This is my ___ (мама).", "mummy", ["daddy", "sister"], "Mummy — мама.", "Мама."))
    return t


def t_rooms(r):
    t = vocab_tasks(r, ROOMS, "комнаты")
    t.append(ch("Где готовят еду?", "kitchen", ["bedroom", "bathroom", "garden"], "Готовят на кухне — kitchen.", "Кухня."))
    t.append(ch("Где спят?", "bedroom", ["kitchen", "garden", "living room"], "Спят в спальне — bedroom.", "Bed — кровать."))
    return t


def t_furniture(r):
    return vocab_tasks(r, FURN, "мебель и предметы в доме")


def t_prepositions(r):
    t = []
    for e, p, ru, em in [("The cat is in the box.", "in", "в", "📦"), ("The ball is on the table.", "on", "на", "⚽"), ("The dog is under the chair.", "under", "под", "🪑"), ("The book is on the bed.", "on", "на", "📖"), ("The mouse is in the house.", "in", "в", "🏠"), ("The ball is under the bed.", "under", "под", "🛏️")]:
        t.append(fill(e.replace(f" {p} ", " ___ "), p, [x for x in ["in", "on", "under"] if x != p], f"{p} — {ru}: {e}", "In — в, on — на, under — под.", pic={"k": "big", "e": em}))
    t.append(match("Соедини предлог и перевод.", [("in", "в"), ("on", "на"), ("under", "под")], "Предлоги места.", "Вспомни картинки."))
    t.append(listen("Послушай и выбери перевод.", "under", "under", ["in", "on"], "Under — под.", "Послушай ещё раз."))
    t.append(ch("— Where's Chuckles? — He's ___ the tree house. (в)", "in", ["on", "under"], "In — в: He's in the tree house.", "Внутри."))
    t.append(build("Составь: «Кот на стуле».", ["The", "cat", "is", "on", "the", "chair."], ["in"], "The cat is on the chair.", "На — on."))
    return t


def t_numbers10(r):
    t = vocab_tasks(r, NUMS, "числа", n_listen=3)
    t.append(inp("Сколько будет two + three? Напиши число словом по-английски.", "five", "2 + 3 = 5 — five.", "Пять.", kb="text"))
    t.append(order("Расставь числа по порядку.", ["one", "two", "three", "four", "five"], "Счёт 1–5.", "Начни с one."))
    return t


def t_age(r):
    t = say_tasks(r, [("How old are you?", "Сколько тебе лет?", ["Как тебя зовут?", "Как дела?"]), ("I'm eight.", "Мне восемь лет.", ["Меня зовут Восемь.", "Я люблю восемь."])])
    t.append(ch("Как спросить «Сколько тебе лет?»", "How old are you?", ["What's your name?", "How are you?"], "How old — сколько лет.", "Old — старый."))
    for n, w in [(7, "seven"), (8, "eight"), (9, "nine")]:
        t.append(ch(f"Как сказать «Мне {n} лет»?", f"I'm {w}.", [f"I'm {['six', 'ten', 'five'][n - 7]}.", f"My name is {w}."], f"{n} — {w}: I'm {w}.", "I'm + число."))
    t.append(order("Восстанови диалог.", ["Happy birthday!", "Thank you!", "How old are you?", "I'm seven."], "Поздравление и вопрос о возрасте.", "Начни с поздравления."))
    t.append(fill("— How ___ are you? — I'm six.", "old", ["name", "are"], "How old are you?", "Возраст."))
    t.append(build("Составь вопрос: «Сколько тебе лет?»", ["How", "old", "are", "you?"], ["is"], "How old are you?", "How old…"))
    t.append(listen("Послушай и выбери число.", "I'm ten.", "10", ["2", "7", "4"], "Ten — десять.", "Ten."))
    t.append(fix("Найди ошибку: «How old is you?»", ["How", "old", "is", "you?"], 2, "are", ["am", "be"], "С you используем are: How old are you?", "You are."))
    return t


def t_food(r):
    return vocab_tasks(r, FOOD, "еда и напитки")


def t_like(r):
    t = []
    for em, food, like in [("🍕", "pizza", True), ("🥦", "broccoli", False), ("🍦", "ice cream", True), ("🧅", "onions", False)]:
        s = f"I like {food}." if like else f"I don't like {food}."
        t.append(ch(f"Мальчик {'улыбается' if like else 'хмурится'}. Что он скажет?", s, [f"I don't like {food}." if like else f"I like {food}.", f"I {food}."], f"{s} — {'я люблю' if like else 'я не люблю'}.", "Like — нравится, don't like — не нравится.", pic={"k": "big", "e": em}))
    t.append(match("Соедини фразу и перевод.", [("I like milk.", "Я люблю молоко."), ("I don't like milk.", "Я не люблю молоко."), ("Do you like milk?", "Ты любишь молоко?")], "Like / don't like.", "Don't — не."))
    t.append(say_tasks(r, [("I like chocolate.", "Я люблю шоколад.", ["Я не люблю шоколад.", "У меня есть шоколад."])])[0])
    t.append(fill("I ___ like pizza. (не)", "don't", ["do", "not"], "I don't like — я не люблю.", "Отрицание."))
    t.append(build("Составь: «Я люблю торт».", ["I", "like", "cake."], ["don't"], "I like cake.", "I like…"))
    t.append(ch("— Do you like chips? — Yes, ___", "I do.", ["I like.", "I am."], "Краткий ответ: Yes, I do. / No, I don't.", "Do — do."))
    t.append(fix("Найди ошибку: «I not like apples».", ["I", "not", "like", "apples"], 1, "don't", ["doesn't", "no"], "Правильно: I don't like apples.", "Нужно don't."))
    return t


def t_animals(r):
    return vocab_tasks(r, ANIMALS, "животные")


def t_actions(r):
    t = vocab_tasks(r, ACTIONS, "действия")
    t.append(ch("Что умеет рыба?", "swim", ["fly", "climb", "sing"], "Fish can swim — рыба умеет плавать.", "В воде."))
    return t


def t_can(r):
    t = []
    for s, ru, ok in [("A fish can swim.", "Рыба умеет плавать.", True), ("A fish can fly.", "Рыба умеет летать.", False), ("A bird can fly.", "Птица умеет летать.", True), ("A horse can climb.", "Лошадь умеет лазать по деревьям.", False), ("A frog can jump.", "Лягушка умеет прыгать.", True)]:
        t.append(tf(f"«{s}» ({ru})", ok, f"{'Верно' if ok else 'Неверно'}: {s}", "Can — умеет, can't — не умеет."))
    t.append(fill("I can swim, but I ___ fly.", "can't", ["can", "am"], "Can't — не умею.", "Не умею."))
    t.append(match("Соедини.", [("I can", "Я умею"), ("I can't", "Я не умею"), ("Can you…?", "Ты умеешь…?")], "Модальный глагол can.", "Can't — отрицание."))
    t.append(ch("— Can you dance? — Yes, ___", "I can.", ["I do.", "I am."], "Краткий ответ: Yes, I can. / No, I can't.", "Can — can."))
    t.append(build("Составь: «Обезьянка умеет лазать».", ["The", "chimp", "can", "climb."], ["can't"], "The chimp can climb.", "Can + глагол."))
    t.append(say_tasks(r, [("I can sing.", "Я умею петь.", ["Я не умею петь.", "Я люблю петь."])])[0])
    return t


def t_circus(r):
    t = vocab_tasks(r, CIRCUS, "цирк")
    t.append(ch("Кто в цирке смешит людей?", "clown", ["magician", "lion", "ball"], "Clown — клоун.", "Смешной."))
    return t


def t_toys(r):
    return vocab_tasks(r, TOYS, "игрушки")


def t_face_body(r):
    t = vocab_tasks(r, BODY, "лицо и тело")
    t.append(ch("Чем мы видим?", "eyes", ["ears", "nose", "mouth"], "Мы видим глазами — eyes.", "Глаза."))
    return t


def t_appearance(r):
    t = vocab_tasks(r, APPEAR, "внешность")
    t.append(ch("Подбери противоположное слово к «big».", "small", ["tall", "long", "happy"], "Big — small: большой — маленький.", "Противоположность."))
    return t


def t_have_got(r):
    t = []
    for s, a in [("I ___ got blue eyes.", "have"), ("She ___ got long hair.", "has"), ("He ___ got a big nose.", "has"), ("We ___ got a cat.", "have"), ("It ___ got four legs.", "has"), ("They ___ got a ball.", "have")]:
        t.append(fill(s, a, ["has" if a == "have" else "have"], f"{'He, she, it — has got' if a == 'has' else 'I, you, we, they — have got'}: {s.replace('___', a)}", "He, she, it → has."))
    t.append(match("Соедини.", [("I", "have got"), ("He", "has got"), ("They", "have got "), ("It", "has got ")][:2] + [("We", "have"), ("She", "has")], "I/we/you/they — have, he/she/it — has.", "Кто?"))
    t.append(ch("Как сказать «У меня есть кукла»?", "I've got a doll.", ["I has got a doll.", "I got doll."], "I've got = I have got.", "I have got…"))
    t.append(build("Составь: «У него есть машинка».", ["He", "has", "got", "a", "car."], ["have"], "He has got a car.", "He — has."))
    t.append(fix("Найди ошибку: «She have got green eyes».", ["She", "have", "got", "green", "eyes"], 1, "has", ["is", "am"], "She has got.", "She — has."))
    return t


def t_clothes(r):
    return vocab_tasks(r, CLOTHES, "одежда")


def t_weather(r):
    t = vocab_tasks(r, WEATHER, "погода")
    t.append(ch("What's the weather like? ☀️", "It's sunny.", ["It's rainy.", "It's snowy."], "Солнце — It's sunny.", "Солнечно."))
    return t


def t_seasons(r):
    t = vocab_tasks(r, SEASONS, "времена года", n_listen=2)
    t.append(order("Расставь времена года по порядку, начиная с зимы.", ["winter", "spring", "summer", "autumn"], "Зима, весна, лето, осень.", "После зимы — весна."))
    t.append(ch("Когда идёт снег?", "winter", ["summer", "spring", "autumn"], "Снег идёт зимой — winter.", "Холодно."))
    t.append(ch("Когда желтеют листья?", "autumn", ["summer", "winter", "spring"], "Осенью — autumn.", "Листопад."))
    return t


def t_summer(r):
    t = vocab_tasks(r, SUMMER, "летний отдых")
    t.append(ch("Что берут на пляж в солнечный день?", "sunglasses", ["coat", "scarf", "boots"], "Солнечные очки — sunglasses.", "От солнца."))
    return t
