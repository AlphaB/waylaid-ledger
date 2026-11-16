local _, addon = ...

-- Language formats only: item IDs, names and quantities still come from the
-- client. Prefixes checked against localized Forever item tooltips (2026-11-16).
-- Battle.net lists enUS/enGB, esES/esMX, ptBR, deDE, frFR, ruRU, koKR and zhTW.
local english = {
    crates = "Waylaid Crate",
    writs = "Craftsman's Writ",
    delivery = { "deliver", "bring" },
    required = { "requires", "require" },
    recipient = { " to " },
    excluded = { "use:", "reward:", "rewards:" },
}
addon.DiscoveryLocales = {
    enUS = english,
    enGB = english,
    deDE = {
        crates = "Abgefangene Kiste",
        writs = "Handwerksverfügung",
        delivery = { "liefert", "liefere", "bringt", "bringe" },
        required = { "benötigt" },
        recipient = { " an " },
        excluded = { "benutzen:", "belohnung:" },
    },
    frFR = {
        crates = "Caisse détournée",
        writs = "Commission d'artisan",
        delivery = { "livrez", "livrer", "apportez", "apporter" },
        required = { "requis", "nécessite" },
        recipient = { " à " },
        excluded = { "utilise:", "utiliser:", "récompense:" },
        wrappers = { "pousses de ", "pousses d'" },
    },
    esES = {
        crates = "Cajón saqueado",
        writs = "Libranza del artesano",
        delivery = { "entrega", "entregar", "lleva", "llevar" },
        required = { "requiere", "necesitas" },
        recipient = { " a " },
        excluded = { "uso:", "recompensa:" },
        wrappers = { "de " },
    },
    esMX = {
        crates = "Cajón arrebatado",
        writs = "Libranza del artesano",
        delivery = { "entrega", "entregar", "lleva", "llevar" },
        required = { "requiere", "necesitas" },
        recipient = { " a " },
        excluded = { "uso:", "recompensa:" },
    },
    ptBR = {
        crates = "Caixote Extraviado",
        writs = "Escritura do Artífice",
        delivery = { "entregue", "entregar", "traga", "trazer" },
        required = { "requer" },
        recipient = { " para " },
        excluded = { "uso:", "recompensa:" },
    },
    ruRU = {
        crates = "Перехваченный ящик",
        writs = "Задание мастера",
        delivery = { "доставьте", "доставить", "принесите", "принести" },
        required = { "требуется" },
        excluded = { "использование:", "награда:" },
        metadata = { "^требуется %d+%-й ур%.$", "^требуется %d+ ур%.$" },
    },
    koKR = {
        crates = "잘못 놓인 보급품",
        writs = "장인의 계약서",
        delivery = { "전달", "배달" },
        required = { "필요" },
        excluded = { "사용 효과:", "보상:" },
    },
    zhTW = {
        crates = "遭攔截的木箱",
        writs = "工匠令狀",
        delivery = { "交付", "交回", "帶來", "送交" },
        required = { "需要" },
        excluded = { "使用:", "獎勵:" },
        compact = true,
        wrappers = { "份" },
    },
}

-- Lua 5.1's lower() only folds ASCII. Fold the alphabets used by the supported
-- locales explicitly; never strip accents or stem/guess inflected item names.
local upper =
    "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÑÒÓÔÕÖØÙÚÛÜÝŒŸАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
local lower =
    "àáâãäåæçèéêëìíîïñòóôõöøùúûüýœÿабвгдеёжзийклмнопрстуфхцчшщъыьэюя"
local folded, letters = {}, {}
for letter in lower:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    letters[#letters + 1] = letter
end
local index = 0
for letter in upper:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    index = index + 1
    folded[letter] = letters[index]
end
for byte = 65, 90 do
    folded[string.char(byte)] = string.char(byte + 32)
end

function addon.DiscoveryLocales.Key(value)
    local key = value:gsub("’", "'"):gsub("‘", "'"):gsub("[\194-\244][\128-\191]*", folded):gsub("[A-Z]", folded)
    return key
end
