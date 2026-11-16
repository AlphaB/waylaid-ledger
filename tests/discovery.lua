local test, equal = ...
local function fixture(action, locale)
    local saved = {
        C_Item = C_Item,
        C_TooltipInfo = C_TooltipInfo,
        GetLocale = GetLocale,
        GetBuildInfo = GetBuildInfo,
        time = time,
        C_Container = C_Container,
        debugprofilestop = debugprofilestop,
        GetTime = GetTime,
    }
    local a = { db = {}, Crates = {}, Writs = {}, MaterialNames = {}, WritMaterialNames = {} }
    local names, tips = {}, {}
    C_Item = {
        GetItemNameByID = function(id)
            return names[id]
        end,
        RequestLoadItemDataByID = function() end,
    }
    C_TooltipInfo = {
        GetItemByID = function(id)
            return tips[id]
        end,
    }
    GetLocale = function()
        return locale or "enUS"
    end
    GetBuildInfo = function()
        return "1", "2", "3", 16001
    end
    time = function()
        return 100
    end
    C_Container = nil
    local now = 0
    GetTime = function()
        return now
    end
    function a.advance(seconds)
        now = now + seconds
    end
    assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/Localization.lua"))("WaylaidLedger", a)
    assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/Locales.lua"))("WaylaidLedger", a)
    assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/DiscoveryLocales.lua"))("WaylaidLedger", a)
    assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/Discovery.lua"))("WaylaidLedger", a)
    a.Discovery.Install()
    function a.drain()
        local frames = 0
        while a.Discovery.frame.scripts.OnUpdate do
            a.advance(0.3)
            frames = frames + 1
            assert(frames < 1000, "discovery retries did not sleep")
            a.Discovery.frame.scripts.OnUpdate()
        end
        return frames
    end
    local ok, err = pcall(action, a, names, tips)
    for key, value in pairs(saved) do
        _G[key] = value
    end
    C_Container = saved.C_Container
    C_TooltipInfo = saved.C_TooltipInfo
    debugprofilestop = saved.debugprofilestop
    assert(ok, err)
end

test("item loads spread over a scan do not continually reparse unresolved contracts", function()
    fixture(function(a, names)
        local reads = 0
        C_TooltipInfo.GetItemByID = function()
            reads = reads + 1
            return { lines = {} }
        end
        for id = 100, 279 do
            a.Discovery.Observe(id, "Craftsman's Writ: Test " .. id)
        end
        a.Discovery.Retry()
        a.drain()
        equal(reads, 180)
        reads = 0
        local frame = a.Discovery.frame
        for index = 1, 600 do
            local id = 1000 + index
            names[id] = "Unrelated auction item " .. index
            frame.scripts.OnEvent(frame, "ITEM_DATA_LOAD_RESULT", id, true)
            a.advance(1 / 60)
            if frame.scripts.OnUpdate then
                frame.scripts.OnUpdate()
            end
        end
        equal(reads, 0, "delivery retries must wait for the item-load burst to settle")
        a.drain()
        equal(reads, 0)
    end)
end)

test("candidate loads across frames wait for quiet and still read the latest description", function()
    fixture(function(a, names, tips)
        names[31] = "Craftsman's Writ: Test"
        a.Discovery.Observe(11, "Herb")
        a.Discovery.Observe(31)
        tips[31] = { lines = { { leftText = "Deliver 3 Herb" } } }
        a.Discovery.Retry()
        a.drain()
        local reads = 0
        C_TooltipInfo.GetItemByID = function(id)
            reads = reads + 1
            return tips[id]
        end
        local frame = a.Discovery.frame
        for _ = 1, 600 do
            frame.scripts.OnEvent(frame, "ITEM_DATA_LOAD_RESULT", 31, true)
            a.advance(1 / 60)
            frame.scripts.OnUpdate()
        end
        equal(reads, 0)
        tips[31] = { lines = { { leftText = "Deliver 9 Herb" } } }
        a.drain()
        equal(reads, 1)
        equal(a.Writs[31].requirements[1].quantity, 9)
        equal(frame.scripts.OnUpdate, nil)
    end)
end)

test("upgrade prunes whole-market estimates and names without losing contracts or ambiguity", function()
    fixture(function(a)
        local exact = { kind = "commodity", offers = {}, scannedAt = 100 }
        local known = { kind = "estimate", unitPrice = 5, scannedAt = 100 }
        a.db.markets = {
            first = {
                items = { [11] = known, [900] = { kind = "estimate" }, [901] = exact },
                failures = {
                    [900] = "timeout",
                },
            },
            second = { items = { [11] = known, [902] = { kind = "estimate" } }, failures = {} },
        }
        a.db.discovery.locales.enUS = {
            build = 16001,
            names = { [11] = "Herb", [12] = "Herb", [31] = "Craftsman's Writ: Test", [900] = "Unrelated item" },
            crates = {},
            writs = { [31] = { name = "Craftsman's Writ: Test", requirements = { { itemID = 11, quantity = 3 } } } },
        }
        a.Discovery.Install()
        equal(a.db.markets.first.items[11], known)
        equal(a.db.markets.first.items[901], exact)
        equal(a.db.markets.first.items[900], nil)
        equal(a.db.markets.first.failures[900], nil)
        equal(a.db.markets.second.items[902], nil)
        equal(a.db.markets.second.items[11], known)
        equal(a.Discovery.store.names[900], nil)
        equal(a.Discovery.store.names[11], "Herb")
        equal(a.Discovery.names.Herb, nil)
        equal(a.Discovery.names.herb, false)
        equal(a.Writs[31].requirements[1].quantity, 3)
        a.Discovery.Prune()
        equal(a.Discovery.names.herb, false)
    end)
end)

test("requirements start empty and are learned from live descriptions and exact AH names", function()
    fixture(function(a, _, tips)
        equal(next(a.Crates), nil)
        equal(next(a.Writs), nil)
        a.Discovery.Observe(11, "Sample Herb")
        a.Discovery.Observe(12, "Other Herb")
        a.Discovery.Observe(21, "Waylaid Crate: Test")
        tips[21] = {
            lines = {
                { leftText = "Requires Level 10" },
                { leftText = "Fill with one of the following:" },
                { leftText = "• 17 Sample Herb\n- 9 Other Herb" },
            },
        }
        equal(a.Discovery.Read(21), true)
        equal(a.Crates[21].options[1].quantity, 17)
        equal(a.Crates[21].options[2].itemID, 12)
        equal(a.Crates[21].requirements, nil)
        equal(a.db.discovery.locales.enUS.crates[21], a.Crates[21])
        a.Discovery.Observe(31, "Craftsman's Writ: Test")
        tips[31] = { lines = { { leftText = "Bring 200 Sample Herb to the quartermaster." } } }
        equal(a.Discovery.Read(31), true)
        equal(a.Writs[31].requirements[1].quantity, 200)
    end)
end)

-- Prefixes are from localized item samples; delivery clauses are constructed
-- format regressions, not recordings from a live localized game client.
local locales = {
    { "enUS", "Waylaid Crate", "Craftsman's Writ", "Peacebloom", "Bring 200 Peacebloom to the quartermaster." },
    { "enGB", "Waylaid Crate", "Craftsman's Writ", "Peacebloom", "Deliver 200 Peacebloom." },
    { "deDE", "Abgefangene Kiste", "Handwerksverfügung", "Silberblatt", "Liefert 200 Silberblatt an den Kunden." },
    {
        "frFR",
        "Caisse détournée ",
        "Commission d’artisan ",
        "Pacifique",
        "Apportez 200 Pacifique à l'intendant.",
    },
    { "esES", "Cajón saqueado", "Libranza del artesano", "Flor de paz", "Entrega 200 Flor de paz a la intendente." },
    { "esMX", "Cajón arrebatado", "Libranza del artesano", "Flor de paz", "Lleva 200 Flor de paz a la intendente." },
    {
        "ptBR",
        "Caixote Extraviado",
        "Escritura do Artífice",
        "Botão-da-paz",
        "Entregue 200 Botão-da-paz para o cliente.",
    },
    {
        "ruRU",
        "Перехваченный ящик",
        "Задание мастера",
        "Мироцвет",
        "Принесите 200 Мироцвет.",
    },
    { "koKR", "잘못 놓인 보급품", "장인의 계약서", "평온초", "전달: 200 평온초" },
    { "zhTW", "遭攔截的木箱", "工匠令狀", "寧神花", "交付200份寧神花。" },
}
for _, sample in ipairs(locales) do
    local locale, crate, writ, material, clause = unpack(sample)
    test(locale .. " discovers localized contracts and parses complete bundles", function()
        fixture(function(a, _, tips)
            a.Discovery.Observe(11, material)
            a.Discovery.Observe(12, "Other Material")
            a.Discovery.Observe(21, crate .. ": Test")
            a.Discovery.Observe(31, writ .. ": Test")
            tips[21] = { lines = { { leftText = "- 20 " .. material .. "\n• Other Material × 10" } } }
            tips[31] = { lines = { { leftText = clause } } }
            equal(a.Discovery.Read(21), true)
            equal(a.Discovery.Read(31), true)
            equal(#a.Crates[21].options, 2)
            equal(a.Crates[21].options[1].itemID, 11)
            equal(a.Crates[21].options[2].quantity, 10)
            equal(a.Writs[31].requirements[1].quantity, 200)
            equal(a.db.discovery.locales[locale].crates[21], a.Crates[21])
            tips[21] = { lines = { { leftText = "- 20 " .. material .. "\n- 10 Unknown Material" } } }
            equal(a.Discovery.Read(21), false)
            equal(#a.Crates[21].options, 0)
            tips[31] = { lines = { { leftText = "- 0 " .. material } } }
            equal(a.Discovery.Read(31), false)
            equal(#a.Writs[31].requirements, 0)
        end, locale)
    end)
end

test("localized wrappers, Unicode spacing and lowercase names resolve exactly", function()
    for _, row in ipairs({
        { "frFR", "Églantine", "- 20 pousses d’églantine" },
        { "esES", "Flor de paz", "- 20 de flor de paz" },
        { "zhTW", "寧神花", "- 20份寧神花" },
        { "ruRU", "Мироцвет", "- 20 мироцвет" },
        { "koKR", "평온초", "- 20 평온초" },
    }) do
        fixture(function(a)
            a.Discovery.Observe(11, row[2])
            local result = a.Discovery.Parse({ row[3] }, "writs", 31)
            equal(result[1].itemID, 11)
            equal(result[1].quantity, 20)
        end, row[1])
    end
end)

test("Unicode case and apostrophe collisions stay ambiguous and links disambiguate", function()
    fixture(function(a)
        a.Discovery.Observe(11, "Églantine")
        a.Discovery.Observe(12, "églantine")
        equal(a.Discovery.Parse({ "- 20 églantine" }, "writs", 31), nil)
        local result = a.Discovery.Parse({ "- 20 |Hitem:11|h[Églantine]|h" }, "writs", 31)
        equal(result[1].itemID, 11)
        a.Discovery.Observe(13, "L’herbe")
        a.Discovery.Observe(14, "L'herbe")
        equal(a.Discovery.Parse({ "- 20 L’herbe" }, "writs", 31), nil)
    end, "frFR")
end)

test("localized metadata, unidentified crates and unsupported locales never invent objectives", function()
    for _, sample in ipairs(locales) do
        fixture(function(a)
            a.Discovery.Observe(21, sample[2])
            equal(a.Crates[21], nil)
            a.Discovery.Observe(11, sample[4])
            for _, excluded in ipairs(a.DiscoveryLocales[sample[1]].excluded) do
                equal(a.Discovery.Parse({ excluded .. " 200 " .. sample[4] }, "writs", 31), nil)
            end
        end, sample[1])
    end
    fixture(function(a)
        a.Discovery.Observe(21, "Waylaid Crate: Test")
        equal(a.Crates[21], nil)
        equal(a.Discovery.Parse({ "- 20 Herb" }, "writs", 31), nil)
    end, "itIT")
end)

test("inflected localized names remain unresolved without authoritative item links", function()
    fixture(function(a)
        a.Discovery.Observe(11, "Friedensblume")
        equal(a.Discovery.Parse({ "- 20 Friedensblumen" }, "writs", 31), nil)
        local result = a.Discovery.Parse({ "- 20 |Hitem:11|h[Friedensblumen]|h" }, "writs", 31)
        equal(result[1].itemID, 11)
    end, "deDE")
end)

test("Russian level metadata does not invalidate valid delivery lists", function()
    fixture(function(a)
        a.Discovery.Observe(11, "Мироцвет")
        a.Discovery.Observe(12, "Сребролист")
        local result = a.Discovery.Parse(
            { "Требуется 10-й ур.", "- 20 мироцвет\n- 10 сребролист" },
            "crates",
            21
        )
        equal(#result, 2)
        equal(result[1].quantity, 20)
    end, "ruRU")
end)

test("shopping reuses observed names from the current locale when item data is not cached", function()
    for _, sample in ipairs(locales) do
        fixture(function(a)
            assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/Catalog.lua"))("WaylaidLedger", a)
            a.Discovery.Observe(11, sample[4])
            equal(a.Catalog.SearchName(11), sample[4])
            equal(a.Catalog.SearchName(999), nil)
        end, sample[1])
    end
end)

test("quantity markers do not consume an item's leading X", function()
    fixture(function(a)
        a.Discovery.Observe(11, "X-52 Material")
        for _, line in ipairs({ "- 20 X-52 Material", "- 20 x X-52 Material", "- 20× X-52 Material" }) do
            local result = a.Discovery.Parse({ line }, "writs", 31)
            equal(result[1].itemID, 11)
            equal(result[1].quantity, 20)
        end
    end)
end)
test("item hyperlinks resolve IDs without a preexisting item-name catalog", function()
    fixture(function(a, _, tips)
        a.Discovery.Observe(31, "Craftsman's Writ: Test")
        tips[31] = { lines = { { leftText = "Deliver 3 |cffffffff|Hitem:11:0|h[Sample Herb]|h|r." } } }
        a.Discovery.Observe(12, "Sample Herb")
        equal(a.Discovery.Read(31), true)
        equal(a.Writs[31].requirements[1].itemID, 11)
    end)
end)
test("crate Use descriptions accept named colors, inline lists and escaped newlines", function()
    fixture(function(a)
        a.Discovery.Observe(11, "Herb")
        a.Discovery.Observe(12, "Ore")
        for _, line in ipairs({
            "Use: Fill the crate with any bundle from the following list:|cnIQ1: - 20 Herb - 10 Ore|r",
            "Use: Fill the crate with any bundle from the following list:|n|cnIQ1:- 20 Herb|n- 10 Ore|r",
        }) do
            local requirements = a.Discovery.Parse({ { leftText = line } }, "crates", 21)
            assert(requirements)
            equal(#requirements, 2)
            equal(requirements[1].quantity, 20)
            equal(requirements[2].itemID, 12)
        end
        equal(
            a.Discovery.Parse(
                { { leftText = "Use: Fill the crate with any bundle from the following list: - 20 Herb - 10 Missing" } },
                "crates",
                21
            ),
            nil
        )
    end)
end)

test("generic writ text preserves fallback quantities and complete objectives replace them", function()
    fixture(function(a, _, tips)
        a.Discovery.Observe(11, "Herb")
        a.Discovery.Observe(31, "Craftsman's Writ: Test")
        local definition = a.Writs[31]
        definition.requirements = { { itemID = 11, quantity = 200 } }
        definition.fallback, definition.unresolved = true, nil
        tips[31] = {
            lines = {
                {
                    leftText = "A pending crafting order. Acquire the requested items and deliver them to the customer for a reward.",
                },
            },
        }
        equal(a.Discovery.Read(31), false)
        equal(definition.requirements[1].quantity, 200)
        equal(definition.unresolved, nil)
        equal(a.Discovery.pending[31], nil)
        tips[31] = { lines = { { leftText = "Bring 100 Herb to the customer." } } }
        equal(a.Discovery.Read(31), true)
        equal(definition.requirements[1].quantity, 100)
        equal(definition.fallback, nil)
        tips[31] = { lines = { { leftText = "Loading..." } } }
        equal(a.Discovery.Read(31), false)
        equal(definition.requirements[1].quantity, 100)
        tips[31] = { lines = { { leftText = "Bring 50 Missing Herb to the customer." } } }
        equal(a.Discovery.Read(31), false)
        equal(#definition.requirements, 0)
    end)
end)

test("upgrade restores unresolved bundled rows while retaining learned and additional contracts", function()
    fixture(function(a)
        assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/Data.lua"))("WaylaidLedger", a)
        assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/WritData.lua"))("WaylaidLedger", a)
        local learned = {
            name = "Waylaid Crate: Apprentice Herbs",
            options = { { itemID = 2447, quantity = 9 }, { itemID = 765, quantity = 8 } },
        }
        a.db.discovery.locales.enUS = {
            build = 16001,
            names = {},
            crates = {
                [248682] = learned,
                [248683] = { name = "Waylaid Crate: Apprentice Ore", unresolved = true, options = {} },
                [21] = { name = "Waylaid Crate: Extra", unresolved = true, options = {} },
            },
            writs = {
                [264037] = { name = "Craftsman's Writ: Crafted Solid Shot", unresolved = true, requirements = {} },
            },
        }
        a.Discovery.Install()
        equal(a.Crates[248682], learned)
        equal(a.Crates[248682].options[1].quantity, 9)
        equal(a.Crates[248683].unresolved, nil)
        equal(a.Crates[248683].options[1].quantity, 20)
        equal(a.Writs[264037].unresolved, nil)
        equal(a.Writs[264037].requirements[1].quantity, 200)
        assert(a.Crates[21])
        equal(a.Discovery.names[a.DiscoveryLocales.Key("Crafted Solid Shot")], 8069)
        equal(a.db.discovery.locales.enUS.crates, a.Crates)
    end)
end)
test("unresolved or ambiguous goods never produce partial delivery definitions", function()
    fixture(function(a, _, tips)
        a.Discovery.Observe(11, "Herb")
        a.Discovery.Observe(12, "Ore")
        a.Discovery.Observe(21, "Waylaid Crate: Test")
        tips[21] = { lines = { { leftText = "- 3 Herb\n- 7 Ore\n- 8 Missing" } } }
        equal(a.Discovery.Read(21), false)
        equal(#a.Crates[21].options, 0)
        a.Discovery.Observe(13, "Missing")
        equal(a.Discovery.Read(21), true)
        equal(#a.Crates[21].options, 3)
        a.Discovery.Observe(14, "Ore")
        equal(a.Discovery.Read(21), false)
        equal(#a.Crates[21].options, 0)
        equal(a.Crates[21].unresolved, true)
    end)
end)
test("late item data retries requirements without keeping stale changed quantities", function()
    fixture(function(a, _, tips)
        a.Discovery.Observe(11, "Herb")
        a.Discovery.Observe(31, "Craftsman's Writ: Test")
        equal(a.Discovery.Read(31), false)
        tips[31] = { lines = { { leftText = "Requires: 2 Herb" } } }
        a.Discovery.Retry()
        equal(#a.Writs[31].requirements, 0)
        a.drain()
        equal(a.Writs[31].requirements[1].quantity, 2)
        tips[31] = { lines = { { leftText = "Deliver 6 Unloaded Herb" } } }
        equal(a.Discovery.Read(31), false)
        equal(#a.Writs[31].requirements, 0)
    end)
end)
test("rewards and use text are not treated as delivery requirements", function()
    fixture(function(a)
        a.Discovery.Observe(11, "Herb")
        equal(
            a.Discovery.Parse({ { leftText = "Use: Bring 3 Herb" }, { leftText = "Reward: 5 Herb" } }, "writs", 31),
            nil
        )
        equal(a.Discovery.Parse({ { leftText = "- 0 Herb" } }, "writs", 31), nil)
        equal(a.Discovery.Parse({ { leftText = "- 3 Herb\n- loading..." } }, "crates", 21), nil)
    end)
end)

test("full-scan event bursts coalesce into bounded discovery work and one redraw", function()
    fixture(function(a, names, _)
        debugprofilestop = nil
        local reads, updates, refreshes = 0, 0, 0
        a.UI = {
            Update = function()
                updates = updates + 1
            end,
        }
        a.Tooltip = {
            Refresh = function()
                refreshes = refreshes + 1
            end,
        }
        C_TooltipInfo.GetItemByID = function()
            reads = reads + 1
            return { lines = {} }
        end
        names[11] = "Herb"
        a.Discovery.Observe(11)
        for id = 100, 279 do
            a.Discovery.Observe(id, "Craftsman's Writ: Test " .. id)
        end
        local frame = a.Discovery.frame
        for event = 1, 1000 do
            frame.scripts.OnEvent(frame, "TOOLTIP_DATA_UPDATE", 900000 + event)
            frame.scripts.OnEvent(frame, "ITEM_DATA_LOAD_RESULT", 11, true)
            a.Discovery.Retry()
        end
        equal(reads, 0)
        equal(updates, 0)
        equal(refreshes, 0)
        local frames = 0
        while frame.scripts.OnUpdate do
            local before = reads
            frame.scripts.OnUpdate()
            frames = frames + 1
            assert(reads - before <= 5, "too many descriptions parsed in one frame")
            assert(frames < 100, "unresolved descriptions retried without new data")
        end
        equal(reads, 180)
        equal(frames, 36)
        equal(updates, 1)
        equal(refreshes, 1)
        assert(next(a.Discovery.pending))
        frame.scripts.OnEvent(frame, "ITEM_DATA_LOAD_RESULT", 11, true)
        equal(frame.scripts.OnUpdate, nil)
    end)
end)

test("tooltip updates retry only their candidate and ignore obsolete instances and reentry", function()
    fixture(function(a, _, tips)
        a.Discovery.Observe(11, "Herb")
        for id = 31, 32 do
            a.Discovery.Observe(id, "Craftsman's Writ: Test " .. id)
            tips[id] = { dataInstanceID = id + 1000, lines = { { leftText = "Deliver 3 Unloaded Herb" } } }
        end
        local reads = {}
        local frame = a.Discovery.frame
        C_TooltipInfo.GetItemByID = function(id)
            reads[id] = (reads[id] or 0) + 1
            frame.scripts.OnEvent(frame, "TOOLTIP_DATA_UPDATE", tips[id].dataInstanceID)
            return tips[id]
        end
        a.Discovery.Retry()
        a.drain()
        equal(reads[31], 1)
        equal(reads[32], 1)
        tips[31] = { dataInstanceID = 2031, lines = { { leftText = "Deliver 3 Herb" } } }
        for _ = 1, 100 do
            frame.scripts.OnEvent(frame, "TOOLTIP_DATA_UPDATE", 1031)
        end
        equal(reads[31], 1)
        a.drain()
        equal(reads[31], 2)
        equal(reads[32], 1)
        equal(a.Writs[31].requirements[1].quantity, 3)
        assert(a.Discovery.pending[32])
        equal(frame.scripts.OnUpdate, nil)
        frame.scripts.OnEvent(frame, "TOOLTIP_DATA_UPDATE", 1031)
        equal(frame.scripts.OnUpdate, nil)
        tips[31].lines = { { leftText = "Deliver 8 Herb" } }
        frame.scripts.OnEvent(frame, "TOOLTIP_DATA_UPDATE", 2031)
        a.drain()
        equal(reads[31], 3)
        equal(reads[32], 1)
        equal(a.Writs[31].requirements[1].quantity, 8)
    end)
end)

test("late delivery names coalesce retries and candidate item loads stay targeted", function()
    fixture(function(a, names, tips)
        local reads = {}
        C_TooltipInfo.GetItemByID = function(id)
            reads[id] = (reads[id] or 0) + 1
            return tips[id]
        end
        for id = 31, 32 do
            names[id] = "Craftsman's Writ: Test " .. id
            a.Discovery.Observe(id)
            tips[id] = { lines = { { leftText = "Deliver 6 Herb" } } }
        end
        a.Discovery.Retry()
        a.drain()
        equal(reads[31], 1)
        equal(reads[32], 1)
        names[11] = "Herb"
        local frame = a.Discovery.frame
        for _ = 1, 100 do
            frame.scripts.OnEvent(frame, "ITEM_DATA_LOAD_RESULT", 11, true)
        end
        equal(reads[31], 1)
        a.drain()
        equal(a.Writs[31].requirements[1].quantity, 6)
        equal(a.Writs[32].requirements[1].quantity, 6)
        tips[31].lines = { { leftText = "Deliver 9 Herb" } }
        frame.scripts.OnEvent(frame, "ITEM_DATA_LOAD_RESULT", 31, true)
        a.drain()
        equal(reads[31], 3)
        equal(reads[32], 2)
        equal(a.Writs[31].requirements[1].quantity, 9)
    end)
end)

test("slow discovery reads yield at the time budget and wait for the full name index", function()
    fixture(function(a, _, _)
        local reads, elapsed = 0, 0
        debugprofilestop = function()
            return elapsed
        end
        C_TooltipInfo.GetItemByID = function()
            reads = reads + 1
            elapsed = elapsed + 2
            return { lines = {} }
        end
        for id = 31, 35 do
            a.Discovery.Observe(id, "Craftsman's Writ: Test " .. id)
        end
        a.BulkScan = { engine = { job = {} } }
        a.Discovery.Retry()
        for _ = 1, 10 do
            a.Discovery.frame.scripts.OnUpdate()
        end
        equal(reads, 0)
        a.BulkScan.engine.job = nil
        a.Discovery.frame.scripts.OnUpdate()
        equal(reads, 1)
        equal(a.drain(), 4)
        equal(reads, 5)
    end)
end)

test("tooltip hooks reuse supplied descriptions and skip repeated appends", function()
    fixture(function(a)
        local callback = TooltipDataProcessor.callback
        assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/Tooltip.lua"))("WaylaidLedger", a)
        a.Tooltip.Install()
        local ok, err = pcall(function()
            local reads = 0
            C_Item.GetItemNameByID = function()
                return "Craftsman's Writ: Test"
            end
            C_TooltipInfo.GetItemByID = function()
                error("should reuse the displayed description")
            end
            local parse = a.Discovery.Parse
            a.Discovery.Parse = function(...)
                reads = reads + 1
                return parse(...)
            end
            local tooltip = CreateFrame("GameTooltip")
            local data = { id = 31, dataInstanceID = 1031, lines = { { leftText = "Loading..." } } }
            TooltipDataProcessor.callback(tooltip, data)
            equal(reads, 1)
            equal(a.Writs[31].unresolved, true)
            TooltipDataProcessor.callback(tooltip, data)
            equal(reads, 1)
        end)
        TooltipDataProcessor.callback = callback
        assert(ok, err)
    end)
end)
