"""Английский язык, 3 класс (Spotlight 3)."""
from eng_common import *

SUPPLIES = [("pen", "ручка", "🖊️"), ("pencil", "карандаш", "✏️"), ("rubber", "ластик", "🧽"), ("ruler", "линейка", "📏"), ("book", "книга", "📕"), ("bag", "сумка", "🎒"), ("pencil case", "пенал", "🗃️"), ("glue", "клей", "🧴")]
N20 = [("eleven", "одиннадцать", "1️⃣"), ("twelve", "двенадцать", ""), ("thirteen", "тринадцать", ""), ("fourteen", "четырнадцать", ""), ("fifteen", "пятнадцать", ""), ("sixteen", "шестнадцать", ""), ("seventeen", "семнадцать", ""), ("eighteen", "восемнадцать", ""), ("nineteen", "девятнадцать", ""), ("twenty", "двадцать", "")]
SUBJECTS = [("English", "английский язык", "🇬🇧"), ("Maths", "математика", "➗"), ("Art", "рисование", "🎨"), ("Music", "музыка", "🎵"), ("PE", "физкультура", "⚽"), ("Science", "естествознание", "🔬"), ("Russian", "русский язык", "📝"), ("Geography", "география", "🌍")]
FAMILY = [("mother", "мать", "👩"), ("father", "отец", "👨"), ("grandmother", "бабушка", "👵"), ("grandfather", "дедушка", "👴"), ("baby", "малыш", "👶"), ("uncle", "дядя", "🧔"), ("aunt", "тётя", "👩‍🦰"), ("cousin", "двоюродный брат / сестра", "🧒")]
FOOD = [("bread", "хлеб", "🍞"), ("cheese", "сыр", "🧀"), ("eggs", "яйца", "🥚"), ("milk", "молоко", "🥛"), ("juice", "сок", "🧃"), ("banana", "банан", "🍌"), ("tomato", "помидор", "🍅"), ("carrot", "морковь", "🥕"), ("rice", "рис", "🍚"), ("meat", "мясо", "🥩")]
TOYS = [("doll", "кукла", "🪆"), ("puppet", "кукла-марионетка", "🎎"), ("rocking horse", "лошадка-качалка", "🐴"), ("soldier", "солдатик", "💂"), ("ballerina", "балерина", "🩰"), ("jack-in-the-box", "игрушка-попрыгунчик", "🎁"), ("teddy bear", "плюшевый мишка", "🧸"), ("shelf", "полка", "📚")]
ANIMALS = [("mouse", "мышь", "🐭"), ("rabbit", "кролик", "🐰"), ("tail", "хвост", "🐒"), ("legs", "ноги", "🦵"), ("body", "тело", "🧍"), ("head", "голова", "🙂"), ("tortoise", "черепаха", "🐢"), ("parrot", "попугай", "🦜"), ("horse", "лошадь", "🐴")]
N50 = [("twenty", "двадцать", ""), ("thirty", "тридцать", ""), ("forty", "сорок", ""), ("fifty", "пятьдесят", ""), ("twenty-one", "двадцать один", ""), ("thirty-five", "тридцать пять", ""), ("forty-two", "сорок два", ""), ("forty-eight", "сорок восемь", "")]
HOME = [("bedroom", "спальня", "🛏️"), ("kitchen", "кухня", "🍳"), ("bathroom", "ванная", "🛁"), ("living room", "гостиная", "🛋️"), ("hall", "прихожая", "🚪"), ("armchair", "кресло", "💺"), ("fridge", "холодильник", "🧊"), ("cooker", "плита", "🔥"), ("wardrobe", "шкаф для одежды", "🗄️"), ("mirror", "зеркало", "🪞")]
PARK = [("play football", "играть в футбол", "⚽"), ("ride a bike", "кататься на велосипеде", "🚲"), ("fly a kite", "запускать змея", "🪁"), ("skip", "прыгать через скакалку", "🪢"), ("play chess", "играть в шахматы", "♟️"), ("read a book", "читать книгу", "📖"), ("swing", "качаться на качелях", "🎠"), ("walk the dog", "гулять с собакой", "🐕")]
DAYS = [("Monday", "понедельник", ""), ("Tuesday", "вторник", ""), ("Wednesday", "среда", ""), ("Thursday", "четверг", ""), ("Friday", "пятница", ""), ("Saturday", "суббота", ""), ("Sunday", "воскресенье", "")]
ROUTINE = [("get up", "вставать", "⏰"), ("have breakfast", "завтракать", "🥣"), ("go to school", "идти в школу", "🏫"), ("have lunch", "обедать", "🍲"), ("do homework", "делать уроки", "📚"), ("play", "играть", "🧸"), ("have dinner", "ужинать", "🍽️"), ("go to bed", "ложиться спать", "🛏️")]
TIMES = [("morning", "утро", "🌅"), ("afternoon", "день (после полудня)", "🌞"), ("evening", "вечер", "🌇"), ("night", "ночь", "🌙")]


def t_supplies(r):
    return vocab_tasks(r, SUPPLIES, "школьные принадлежности")


def t_numbers20(r):
    t = vocab_tasks(r, N20, "числа 11–20", n_listen=4)
    t.append(inp("Сколько будет ten + five? Напиши словом.", "fifteen", "10 + 5 = 15 — fifteen.", "Пятнадцать.", kb="text"))
    t.append(order("Расставь числа по порядку.", ["eleven", "twelve", "thirteen", "fourteen"], "11, 12, 13, 14.", "Начни с eleven."))
    return t


def t_subjects(r):
    return vocab_tasks(r, SUBJECTS, "школьные предметы")


def t_to_be(r):
    t = []
    for s, a in [("I ___ a pupil.", "am"), ("She ___ my friend.", "is"), ("They ___ in the classroom.", "are"), ("You ___ nine.", "are"), ("It ___ a red pen.", "is"), ("We ___ happy.", "are")]:
        t.append(fill(s, a, [x for x in ["am", "is", "are"] if x != a], f"I — am, he/she/it — is, we/you/they — are: {s.replace('___', a)}", "Кто подлежащее?"))
    t.append(ch("Как сказать «Я не учитель»?", "I'm not a teacher.", ["I not a teacher.", "I isn't a teacher."], "Отрицание: am not / isn't / aren't.", "Not после am."))
    t.append(ch("Как задать вопрос «Он твой брат?»", "Is he your brother?", ["He is your brother?", "Are he your brother?"], "В вопросе is ставим в начало.", "Is он…?"))
    t.append(build("Составь вопрос: «Ты ученик?»", ["Are", "you", "a", "pupil?"], ["Is"], "Are you a pupil?", "You — are."))
    t.append(fix("Найди ошибку: «They is my friends».", ["They", "is", "my", "friends"], 1, "are", ["am", "be"], "They are.", "They — are."))
    t.append(match("Соедини местоимение и форму to be.", [("I", "am"), ("he", "is"), ("we", "are")], "Формы глагола to be.", "Вспомни таблицу."))
    return t


def t_family(r):
    return vocab_tasks(r, FAMILY, "члены семьи")


def t_possessives(r):
    t = []
    for s, a, d, ru in [("This is ___ bag. (мой)", "my", ["your", "his"], "мой"), ("Is this ___ pen? (твой)", "your", ["my", "her"], "твой"), ("Tom is my friend. ___ dog is big. (его)", "His", ["Her", "Our"], "его"),
                        ("Anna has a cat. ___ cat is white. (её)", "Her", ["His", "Their"], "её"), ("We have a house. ___ house is new. (наш)", "Our", ["Their", "My"], "наш"), ("They have a car. ___ car is red. (их)", "Their", ["Our", "His"], "их")]:
        t.append(fill(s, a, d, f"{a} — {ru}.", "My, your, his, her, our, their."))
    t.append(match("Соедини местоимение и притяжательную форму.", [("I", "my"), ("he", "his"), ("she", "her"), ("they", "their")], "Притяжательные местоимения.", "Чей?"))
    t.append(ch("Как сказать «их бабушка»?", "their grandmother", ["they grandmother", "there grandmother"], "Их — their.", "Their."))
    t.append(fix("Найди ошибку: «She is my sister. His name is Kate».", ["She", "is", "my", "sister.", "His", "name"], 4, "Her", ["Their", "Our"], "О девочке — her: Her name is Kate.", "Она — её."))
    t.append(listen("Послушай и выбери перевод.", "This is our house.", "Это наш дом.", ["Это их дом.", "Это мой дом."], "Our — наш.", "Our."))
    return t


def t_plurals(r):
    t = []
    for one, many in [("cat", "cats"), ("box", "boxes"), ("bus", "buses"), ("baby", "babies"), ("pen", "pens"), ("fox", "foxes")]:
        t.append(ch(f"Множественное число от «{one}»:", many, [one + "s" if many != one + "s" else one + "es", one + "ies" if not one.endswith("y") else one + "s"], f"{one} — {many}. После s, x, sh, ch — -es; согласная + y → -ies.", "Посмотри на последнюю букву."))
    t.append(sort_("Разложи по окончанию.", [("-s", ["dogs", "books"]), ("-es", ["boxes", "dresses"]), ("-ies", ["babies", "cherries"])], "Правила образования мн. ч.", "Последняя буква слова."))
    t.append(fill("one dog — two ___", "dogs", ["doges", "dog"], "Обычно прибавляем -s.", "Просто -s."))
    t.append(fix("Найди ошибку: «I have three boxs».", ["I", "have", "three", "boxs"], 3, "boxes", ["boxies", "box"], "После x — -es: boxes.", "Окончание -es."))
    t.append(inp("Напиши множественное число: «bus».", "buses", "После s — -es.", "Прибавь -es.", kb="text"))
    return t


def t_food(r):
    return vocab_tasks(r, FOOD, "продукты")


def t_likes(r):
    t = []
    for s, a, d in [("I ___ bananas.", "like", ["likes"]), ("He ___ cheese.", "likes", ["like"]), ("She ___ milk.", "likes", ["like"]), ("They ___ pizza.", "like", ["likes"]), ("My dad ___ tea.", "likes", ["like"])]:
        t.append(fill(s, a, d, "He, she, it — likes (с -s); I, you, we, they — like.", "Третье лицо — -s."))
    t.append(ch("Как сказать «Она не любит рис»?", "She doesn't like rice.", ["She don't like rice.", "She not likes rice."], "He/she/it — doesn't like.", "Doesn't."))
    t.append(ch("— Does he like eggs? — Yes, he ___", "does", ["do", "likes"], "Краткий ответ: Yes, he does.", "Does — does."))
    t.append(build("Составь вопрос: «Ты любишь сыр?»", ["Do", "you", "like", "cheese?"], ["Does"], "Do you like cheese?", "Do you…?"))
    t.append(fix("Найди ошибку: «My sister like apples».", ["My", "sister", "like", "apples"], 2, "likes", ["liking", "liked"], "Sister — she: likes.", "Третье лицо."))
    t.append(listen("Послушай и выбери перевод.", "He likes chocolate.", "Он любит шоколад.", ["Он не любит шоколад.", "Я люблю шоколад."], "He likes — он любит.", "He likes."))
    return t


def t_some_any(r):
    t = []
    for s, a, d in [("There is ___ milk in the fridge.", "some", ["any"]), ("Is there ___ juice?", "any", ["some"]), ("There aren't ___ eggs.", "any", ["some"]), ("I've got ___ apples.", "some", ["any"]), ("Have you got ___ bread?", "any", ["some"]), ("We need ___ cheese.", "some", ["any"])]:
        t.append(fill(s, a, d, "Some — в утверждениях, any — в вопросах и отрицаниях.", "Это утверждение, вопрос или отрицание?"))
    t.append(sort_("Some или any?", [("some", ["I want ___ tea.", "There are ___ cakes."]), ("any", ["Are there ___ sweets?", "I haven't got ___ milk."])], "Правило some/any.", "Вопрос или отрицание — any."))
    t.append(ch("Где обычно используется «any»?", "в вопросах и отрицаниях", ["только в утверждениях", "всегда с числами"], "Any — в вопросах и отрицаниях.", "Правило."))
    t.append(fix("Найди ошибку: «Is there some water?»", ["Is", "there", "some", "water?"], 2, "any", ["a", "an"], "В вопросе — any.", "Вопрос."))
    t.append(tf("«There are some oranges» — правильное предложение.", True, "Утверждение — some.", "Утверждение?"))
    return t


def t_toys_room(r):
    return vocab_tasks(r, TOYS, "игрушки и комната")


def t_demonstratives(r):
    t = []
    for s, a, d, why in [("___ is my doll. (это, рядом)", "This", ["These", "That"], "один предмет рядом — this"), ("___ are my books. (эти, рядом)", "These", ["This", "Those"], "много рядом — these"),
                         ("___ is a plane. (тот, далеко)", "That", ["This", "Those"], "один далеко — that"), ("___ are birds. (те, далеко)", "Those", ["That", "These"], "много далеко — those")]:
        t.append(fill(s, a, d, why.capitalize() + ".", "Один или много? Рядом или далеко?"))
    t.append(match("Соедини.", [("this", "этот (рядом)"), ("that", "тот (далеко)"), ("these", "эти (рядом)"), ("those", "те (далеко)")], "Указательные местоимения.", "Много — these/those."))
    t.append(ch("Как сказать «Эти куклы»?", "these dolls", ["this dolls", "those doll"], "These + мн. ч.", "Много и рядом."))
    t.append(fix("Найди ошибку: «This are my toys».", ["This", "are", "my", "toys"], 0, "These", ["That", "It"], "Много игрушек — these.", "Много."))
    t.append(listen("Послушай и выбери перевод.", "That is my house.", "Вон там мой дом.", ["Это мои дома.", "Эти дома мои."], "That — тот, вон тот.", "That."))
    t.append(tf("«Those» используют для нескольких предметов далеко.", True, "Those — те (далеко).", "Много и далеко."))
    return t


def t_articles(r):
    t = []
    for w, a in [("apple", "an"), ("ball", "a"), ("elephant", "an"), ("doll", "a"), ("orange", "an"), ("umbrella", "an"), ("car", "a"), ("egg", "an")]:
        t.append(ch(f"Какой артикль нужен: ___ {w}?", a, ["an" if a == "a" else "a"], f"Перед гласным звуком — an, перед согласным — a: {a} {w}.", "Слово начинается с гласного звука?"))
    t.append(sort_("a или an?", [("a", ["a cat", "a book"]), ("an", ["an ant", "an ice cream"])], "An — перед гласными звуками.", "Первый звук."))
    t.append(fix("Найди ошибку: «I've got a orange».", ["I've", "got", "a", "orange"], 2, "an", ["the", "some"], "Orange начинается с гласной: an orange.", "Гласный звук."))
    return t


def t_animal_body(r):
    t = vocab_tasks(r, ANIMALS, "животные и части тела")
    t.append(ch("What has a long tail?", "a mouse", ["a tortoise", "a fish"], "У мышки длинный хвост.", "Tail — хвост."))
    return t


def t_numbers50(r):
    t = vocab_tasks(r, N50, "числа до 50", n_listen=4)
    t.append(inp("Сколько будет twenty + twenty? Напиши словом.", "forty", "20 + 20 = 40 — forty.", "Сорок (без u!).", kb="text"))
    t.append(order("Расставь числа по возрастанию.", ["twenty", "thirty", "forty", "fifty"], "20, 30, 40, 50.", "Начни с twenty."))
    return t


def t_can_have(r):
    t = []
    for s, a, d in [("A rabbit ___ jump.", "can", ["has"]), ("A tortoise ___ got a shell.", "has", ["have"]), ("Birds ___ got wings.", "have", ["has"]), ("A fish ___ swim.", "can", ["have"]), ("My dog ___ got a long tail.", "has", ["have"])]:
        t.append(fill(s, a, d, "Can — умеет; have/has got — есть, имеет.", "Умеет или имеет?"))
    t.append(ch("Как сказать «Мой попугай умеет говорить»?", "My parrot can talk.", ["My parrot has talk.", "My parrot cans talk."], "Can + глагол без изменений.", "Can talk."))
    t.append(tf("«Mice can fly.» — верно.", False, "Мыши не умеют летать: Mice can't fly.", "Умеет ли мышь летать?"))
    t.append(build("Составь: «У черепахи четыре ноги».", ["A", "tortoise", "has", "got", "four", "legs."], ["have"], "A tortoise has got four legs.", "It — has."))
    t.append(fix("Найди ошибку: «A horse can runs fast».", ["A", "horse", "can", "runs", "fast"], 3, "run", ["running", "ran"], "После can глагол без -s.", "Can + глагол."))
    t.append(say_tasks(r, [("It can climb trees.", "Оно умеет лазать по деревьям.", ["У него есть деревья.", "Оно не умеет лазать."])])[0])
    return t


def t_irregular_plurals(r):
    t = []
    for one, many in [("mouse", "mice"), ("foot", "feet"), ("tooth", "teeth"), ("man", "men"), ("woman", "women"), ("child", "children"), ("sheep", "sheep"), ("fish", "fish")]:
        t.append(ch(f"Множественное число от «{one}»:", many, [one + "s", one + "es"], f"{one} — {many} (исключение).", "Это слово-исключение."))
    t.append(match("Соедини.", [("mouse", "mice"), ("tooth", "teeth"), ("foot", "feet"), ("child", "children")], "Исключения мн. ч.", "Запомни."))
    t.append(fix("Найди ошибку: «I can see three mouses».", ["I", "can", "see", "three", "mouses"], 4, "mice", ["mices", "mouse"], "Mouse — mice.", "Исключение."))
    t.append(inp("Напиши множественное число: «tooth».", "teeth", "Tooth — teeth.", "Как foot — feet.", kb="text"))
    return t


def t_rooms_furniture(r):
    return vocab_tasks(r, HOME, "комнаты и мебель")


def t_prepositions(r):
    t = []
    for s, a, ru in [("The cat is ___ the sofa. (на)", "on", "на"), ("The ball is ___ the bed. (под)", "under", "под"), ("The lamp is ___ the bed. (рядом с)", "next to", "рядом с"), ("The dog is ___ the house. (перед)", "in front of", "перед"), ("The garden is ___ the house. (позади)", "behind", "позади"), ("The book is ___ the bag. (в)", "in", "в")]:
        t.append(fill(s, a, [x for x in ["in", "on", "under", "next to", "behind", "in front of"] if x != a][:2], f"{a} — {ru}.", "Вспомни предлоги места."))
    t.append(match("Соедини предлог и перевод.", [("behind", "позади"), ("next to", "рядом с"), ("in front of", "перед"), ("under", "под")], "Предлоги места.", "Вспомни картинки."))
    t.append(ch("Where is the mouse? 🐭 (под столом)", "It's under the table.", ["It's on the table.", "It's in the table."], "Под — under.", "Под."))
    t.append(listen("Послушай и выбери перевод.", "The chair is next to the table.", "Стул рядом со столом.", ["Стул под столом.", "Стул на столе."], "Next to — рядом.", "Next to."))
    return t


def t_there_is(r):
    t = []
    for s, a in [("There ___ a sofa in the room.", "is"), ("There ___ two chairs.", "are"), ("There ___ a lamp on the table.", "is"), ("There ___ three windows.", "are"), ("___ there a fridge in the kitchen?", "Is"), ("___ there any books?", "Are")]:
        t.append(fill(s, a, ["are" if a.lower() == "is" else "is"] if a.islower() else ["Are" if a == "Is" else "Is"], "There is — один предмет, there are — несколько.", "Один или много?"))
    t.append(ch("Как сказать «В комнате есть кровать»?", "There is a bed in the room.", ["There are a bed in the room.", "It is bed in room."], "Один предмет — there is.", "Один."))
    t.append(fix("Найди ошибку: «There is four chairs».", ["There", "is", "four", "chairs"], 1, "are", ["am", "be"], "Много — there are.", "Четыре стула."))
    t.append(build("Составь: «На кухне есть плита».", ["There", "is", "a", "cooker", "in", "the", "kitchen."], ["are"], "There is a cooker in the kitchen.", "There is…"))
    t.append(tf("«There are a mirror» — правильно.", False, "Один предмет — there is a mirror.", "Один или много?"))
    return t


def t_park(r):
    return vocab_tasks(r, PARK, "занятия в парке")


def t_present_cont(r):
    t = []
    for s, a, d in [("I ___ reading a book.", "am", ["is", "are"]), ("She ___ playing chess.", "is", ["am", "are"]), ("They ___ flying a kite.", "are", ["is", "am"]), ("He is ___ (ride) a bike.", "riding", ["rides", "ride"]), ("We are ___ (swim).", "swimming", ["swiming", "swim"])]:
        t.append(fill(s, a, d, "Present Continuous: am/is/are + глагол с -ing — действие происходит сейчас.", "Что происходит сейчас?"))
    t.append(ch("Что значит «He is watching TV»?", "Он сейчас смотрит телевизор.", ["Он всегда смотрит телевизор.", "Он смотрел телевизор вчера."], "Present Continuous — сейчас.", "-ing — сейчас."))
    t.append(ch("Как задать вопрос «Ты сейчас играешь?»", "Are you playing?", ["Do you playing?", "You are play?"], "Вопрос: Are you + -ing?", "Are в начало."))
    t.append(build("Составь: «Мама готовит обед».", ["Mum", "is", "cooking", "lunch."], ["cooks"], "Mum is cooking lunch.", "Is + -ing."))
    t.append(fix("Найди ошибку: «The children is playing football».", ["The", "children", "is", "playing", "football"], 2, "are", ["am", "be"], "Children — они: are.", "Children — много."))
    t.append(listen("Послушай и выбери перевод.", "She is skipping.", "Она прыгает через скакалку.", ["Она спит.", "Она читает."], "Skip — прыгать через скакалку.", "Skipping."))
    return t


def t_days(r):
    t = vocab_tasks(r, DAYS, "дни недели", n_listen=3, extra_spell=True)
    t.append(order("Расставь дни недели по порядку.", ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"], "Порядок дней.", "Начни с понедельника."))
    t.append(ch("Какой день идёт после Friday?", "Saturday", ["Thursday", "Sunday", "Monday"], "После пятницы — суббота.", "Выходной."))
    return t


def t_routine(r):
    t = vocab_tasks(r, ROUTINE, "режим дня")
    t.append(order("Расставь дела по порядку.", ["get up", "have breakfast", "go to school", "do homework", "go to bed"], "Обычный день школьника.", "Начни с подъёма."))
    return t


def t_times_of_day(r):
    t = vocab_tasks(r, TIMES, "время суток", n_listen=2)
    t.append(ch("Когда говорят «Good night»?", "night", ["morning", "afternoon"], "Good night — спокойной ночи.", "Перед сном."))
    t.append(ch("Когда мы завтракаем?", "in the morning", ["at night", "in the evening"], "Завтрак — утром.", "Утро."))
    t.append(order("Расставь части суток.", ["morning", "afternoon", "evening", "night"], "Утро, день, вечер, ночь.", "Начни с утра."))
    t.append(fill("I go to bed at ___ .", "night", ["morning", "lunch"], "Спать ложимся ночью.", "Ночь."))
    return t


def t_present_simple(r):
    t = []
    for s, a, d in [("I ___ (get) up at 7 o'clock.", "get", ["gets"]), ("He ___ (go) to school every day.", "goes", ["go"]), ("She ___ (watch) TV in the evening.", "watches", ["watch"]), ("We ___ (play) on Sundays.", "play", ["plays"]), ("My cat ___ (sleep) a lot.", "sleeps", ["sleep"])]:
        t.append(fill(s, a, d, "Present Simple — регулярные действия; he/she/it + -s/-es.", "Он/она — прибавь -s."))
    t.append(ch("Какое предложение о том, что бывает всегда (регулярно)?", "I always have breakfast at 8.", ["I am having breakfast now.", "Look! I am eating."], "Present Simple — регулярные действия.", "Always."))
    t.append(sort_("Present Simple или Present Continuous?", [("Present Simple", ["He reads every day.", "We go to school on Mondays."]), ("Present Continuous", ["He is reading now.", "Look! They are running."])], "Каждый день — Simple, сейчас — Continuous.", "Сейчас или обычно?"))
    t.append(fix("Найди ошибку: «She go to bed at 9».", ["She", "go", "to", "bed"], 1, "goes", ["going", "gos"], "She goes.", "Третье лицо."))
    t.append(build("Составь: «Я делаю уроки вечером».", ["I", "do", "my", "homework", "in", "the", "evening."], ["does"], "I do my homework in the evening.", "I do…"))
    return t
