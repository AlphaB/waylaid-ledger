local test, equal = ...
local function fixture(action)
    local saved = {
        C_Item = C_Item,
        C_TooltipInfo = C_TooltipInfo,
        GetLocale = GetLocale,
        GetBuildInfo = GetBuildInfo,
        time = time,
        C_Container = C_Container,
        debugprofilestop = debugprofilestop,
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
        return "enUS"
    end
    GetBuildInfo = function()
        return "1", "2", "3", 16001
    end
    time = function()
        return 100
    end
    C_Container = nil
    assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/Discovery.lua"))("WaylaidLedger", a)
    a.Discovery.Install()
    function a.drain()
        local frames = 0
        while a.Discovery.frame.scripts.OnUpdate do
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

test("requirements start empty and are learned from live descriptions and exact AH names", function()
    fixture(function(a, _names, tips)
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
test("item hyperlinks resolve IDs without a preexisting item-name catalog", function()
    fixture(function(a, _names, tips)
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
    fixture(function(a, _names, tips)
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
        equal(a.Discovery.names["Crafted Solid Shot"], 8069)
        equal(a.db.discovery.locales.enUS.crates, a.Crates)
    end)
end)
test("unresolved or ambiguous goods never produce partial delivery definitions", function()
    fixture(function(a, _names, tips)
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
    fixture(function(a, _names, tips)
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
    fixture(function(a, names, _tips)
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
    fixture(function(a, _names, tips)
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
    fixture(function(a, _names, _tips)
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
