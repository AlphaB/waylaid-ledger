local addon, test, equal, host = ...
local Providers, Pricing = addon.Providers, addon.Pricing

local function fresh(offers, at)
    return { kind = "commodity", offers = offers, scannedAt = at or 100 }
end
local crate =
    { options = { { itemID = 1, quantity = 20 }, { itemID = 2, quantity = 10 }, { itemID = 3, quantity = 5 } } }
local function estimate(source, price, days)
    return { source = source, sourceLabel = source, unitPrice = price, ageDays = days, stale = days ~= nil and days > 0 }
end
local function resolve(snapshots, mode, lookup, failures)
    return Pricing.Resolve(crate, snapshots or {}, 100, 30, failures or {}, mode or "auto", lookup or function() end)
end

local function reset()
    Auctionator, TSM_API = nil, nil
    Providers.boundAPI, Providers.errors = nil, {}
    Providers.Invalidate()
    addon.scanner:Stop()
    addon.db.source, addon.db.tsmKey, addon.db.profile = "auto", "DBMinBuyout", "default"
    local market = addon:GetMarket()
    market.items, market.failures = {}, {}
    addon.lastCrateID, addon.lastContractID = nil, nil
    addon.scanner:SetOpen(true)
end

local function fakeAuctionator(prices)
    local state = { reads = 0, callbacks = 0, searches = {} }
    local api = {}
    api.GetAuctionPriceByItemID = function(caller, id)
        equal(caller, "WaylaidLedger")
        state.reads = state.reads + 1
        return prices[id]
    end
    api.GetAuctionAgeByItemID = function(caller)
        equal(caller, "WaylaidLedger")
        return state.days or 0
    end
    api.RegisterForDBUpdate = function(caller, callback)
        equal(caller, "WaylaidLedger")
        state.callbacks = state.callbacks + 1
        state.callback = callback
    end
    api.MultiSearchAdvanced = function(caller, terms)
        equal(caller, "WaylaidLedger")
        state.searches[#state.searches + 1] = terms
        if state.onSearch then
            state.onSearch()
        end
    end
    Auctionator = { API = { v1 = api } }
    state.api = api
    return state
end

test("older Auctionator scans finish through the public callback or timeout without starting our scanner", function()
    reset()
    local f = fakeAuctionator({})
    local oldTime, oldBus = GetTime, Providers.boundScanBus
    local now = 0
    GetTime = function()
        return now
    end
    Providers.boundScanBus = nil
    local ok, err = pcall(function()
        Auctionator.FullScan = true -- Unsupported progress adapter must be harmless.
        Providers.Install()
        addon.autoReason, addon.autoDue = "open", 2
        Providers.BeginExternalScan()
        assert(Providers.scan)
        equal(addon.autoDue, nil)
        f.callback()
        equal(Providers.scan, nil)
        equal(addon.scanner.active, false)
        Providers.BeginExternalScan()
        now = 121
        Providers.frame.scripts.OnUpdate()
        equal(Providers.scan, nil)
        equal(addon.autoDue, nil)
        equal(addon.autoPaused, true)
    end)
    Providers.scan, Providers.refreshAt = nil, nil
    Providers.frame:SetScript("OnUpdate", nil)
    GetTime, Providers.boundScanBus = oldTime, oldBus
    assert(ok, err)
end)

test("auto resolver prefers fresh depth scans and preserves observed shortages", function()
    local queries = 0
    local rows, known = resolve(
        {
            [1] = fresh({ { quantity = 20, unitPrice = 10 } }),
            [2] = fresh({}),
            [3] = fresh({ { quantity = 5, unitPrice = 20 } }),
        },
        "auto",
        function()
            queries = queries + 1
            return estimate("auctionator", 1, 0)
        end
    )
    equal(queries, 0)
    equal(known, true)
    equal(rows[1].cost, 200)
    equal(rows[2].status, "short")
    equal(rows[3].best, true)
    equal(rows[1].best, false)
end)
test("auto imports Auctionator then TSM per item without comparing provider minima", function()
    local queries = {}
    local rows, known = resolve({}, "auto", function(source, id)
        queries[#queries + 1] = source .. id
        if source == "auctionator" and id ~= 2 then
            return estimate(source, 10, 0)
        end
        if source == "tsm" then
            return estimate(source, 1)
        end
    end)
    equal(known, false)
    equal(rows[1].source, "auctionator")
    equal(rows[1].cost, 200)
    equal(rows[2].source, "tsm")
    equal(rows[2].cost, 10)
    equal(rows[2].available, nil)
    equal(rows[1].best, false)
    equal(rows[2].bestEstimate, true)
    equal(table.concat(queries, ","), "auctionator1,auctionator2,tsm2,auctionator3")
end)
test("auto can use a TSM estimate ahead of a known-old Auctionator estimate", function()
    local rows = resolve({}, "auto", function(source)
        return source == "auctionator" and estimate(source, 1, 2) or estimate(source, 10)
    end)
    equal(rows[1].source, "tsm")
    equal(rows[1].cost, 200)
end)
test("cached estimates remain eligible; all tied lowest costs highlight amber", function()
    local rows = resolve({}, "auctionator", function(source, id)
        return estimate(source, id == 1 and 1 or (id == 2 and 2 or 4), id == 1 and 1 or 0)
    end)
    equal(rows[1].stale, true)
    equal(rows[1].bestEstimate, true)
    equal(rows[2].bestEstimate, true)
    equal(rows[3].bestEstimate, true)
end)
test("resolved options highlight the single lowest known cost across sources", function()
    local rows, known = resolve({ [1] = fresh({ { quantity = 20, unitPrice = 10 } }) }, "auto", function(source)
        return estimate(source, 1, 0)
    end)
    equal(known, false)
    equal(rows[1].best, false)
    equal(rows[1].bestEstimate, false)
    equal(rows[3].best, false)
    equal(rows[3].bestEstimate, true)
end)
test("forced source never silently falls back to another addon or own scans", function()
    local rows = resolve({ [1] = fresh({ { quantity = 20, unitPrice = 10 } }) }, "tsm", function(source)
        equal(source, "tsm")
        return nil
    end)
    equal(rows[1].status, "unknown")
    equal(rows[1].source, "tsm")
    rows = resolve({}, "own", function()
        error("provider must not be queried")
    end)
    equal(rows[1].status, "unknown")
    equal(rows[1].source, "own")
end)
test("auto can replace a failed or stale scan with a labelled estimate", function()
    local rows = resolve({ [1] = fresh({ { quantity = 20, unitPrice = 1 } }, 1) }, "auto", function(source)
        return estimate(source, 2, 0)
    end, { [1] = "timeout" })
    equal(rows[1].estimated, true)
    equal(rows[1].cost, 40)
    equal(rows[1].scanError, "timeout")
    equal(rows[1].age, nil)
    equal(rows[1].best, false)
end)
test("optional providers absent, malformed globals and missing prices are safe", function()
    reset()
    equal(Providers.Available("auctionator"), false)
    equal(Providers.Available("tsm"), false)
    equal(Providers.Read("auctionator", 1), nil)
    equal(Providers.ShoppingAvailable(), false)
    Auctionator = { API = true }
    TSM_API = true
    equal(Providers.Read("auctionator", 1), nil)
    equal(Providers.Read("tsm", 1), nil)
    fakeAuctionator({})
    equal(Providers.Read("auctionator", 1), nil)
end)
test("Auctionator values use copper and age in days without pretending minute freshness", function()
    reset()
    local f = fakeAuctionator({ [1] = 125 })
    f.days = 2
    local price = Providers.Read("auctionator", 1)
    equal(price.unitPrice, 125)
    equal(price.ageDays, 2)
    equal(price.stale, true)
    equal(price.scannedAt, nil)
    equal(price.age, nil)
end)
test("provider cache is short-lived, caches misses and invalidates on DB updates", function()
    reset()
    local prices = { [1] = 10 }
    local f = fakeAuctionator(prices)
    local originalTime = GetTime
    local now = 0
    GetTime = function()
        return now
    end
    Providers.Install()
    Providers.Install()
    equal(f.callbacks, 1)
    equal(Providers.Read("auctionator", 1).unitPrice, 10)
    prices[1] = 20
    equal(Providers.Read("auctionator", 1).unitPrice, 10)
    equal(f.reads, 1)
    f.callback()
    equal(Providers.Read("auctionator", 1).unitPrice, 20)
    equal(f.reads, 2)
    now = 16
    Providers.Read("auctionator", 1)
    equal(f.reads, 3)
    Providers.Read("auctionator", 2)
    Providers.Read("auctionator", 2)
    equal(f.reads, 4)
    GetTime = originalTime
end)
test("Auctionator callback bursts invalidate prices immediately but defer redraws without discovery retries", function()
    reset()
    local prices = { [1] = 10 }
    local f = fakeAuctionator(prices)
    local oldTime, oldUI, oldTooltip, oldRetry = GetTime, addon.UI.Update, addon.Tooltip.Refresh, addon.Discovery.Retry
    local now, updates, refreshes, retries = 0, 0, 0, 0
    GetTime = function()
        return now
    end
    addon.UI.Update = function()
        updates = updates + 1
    end
    addon.Tooltip.Refresh = function()
        refreshes = refreshes + 1
    end
    addon.Discovery.Retry = function()
        retries = retries + 1
    end
    local ok, err = pcall(function()
        Providers.Install()
        equal(Providers.Read("auctionator", 1).unitPrice, 10)
        prices[1] = 20
        f.callback()
        equal(Providers.Read("auctionator", 1).unitPrice, 20)
        for _ = 1, 600 do
            f.callback()
            now = now + 1 / 60
            Providers.frame.scripts.OnUpdate()
        end
        equal(updates, 0)
        equal(refreshes, 0)
        equal(retries, 0)
        now = now + 0.3
        Providers.frame.scripts.OnUpdate()
        equal(updates, 1)
        equal(refreshes, 1)
        equal(retries, 0)
        equal(Providers.frame.scripts.OnUpdate, nil)
    end)
    GetTime, addon.UI.Update, addon.Tooltip.Refresh, addon.Discovery.Retry = oldTime, oldUI, oldTooltip, oldRetry
    Providers.frame:SetScript("OnUpdate", nil)
    Providers.refreshAt = nil
    assert(ok, err)
end)
test("list Refresh reloads provider prices without auction queries or clearing snapshots", function()
    reset()
    local oldWrit = addon.db.writSource
    addon.db.writSource = "auto"
    local prices = { [264050] = 100, [4245] = 400, [264037] = 40, [8069] = 3 }
    fakeAuctionator(prices)
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(1000, 550)
    local view = addon.BrowseUI.Create(frame, "writs")
    addon.BrowseUI.Refresh(view)
    equal(view.visibleEntries[1].itemID, 264050)
    equal(view.visibleEntries[1].total, 500)
    prices[4245] = 900
    addon.BrowseUI.Refresh(view)
    equal(view.visibleEntries[1].total, 500)
    local before = #addon.scanner.requests
    local snapshot = { kind = "commodity", offers = {}, scannedAt = time() }
    addon:GetMarket().items[2770] = snapshot
    view.refreshButton.scripts.OnClick()
    equal(view.visibleEntries[1].itemID, 264037)
    equal(view.visibleEntries[1].total, 640)
    equal(view.visibleEntries[2].itemID, 264050)
    equal(view.visibleEntries[2].total, 1000)
    equal(view.scroll.retainScrollPosition, true)
    equal(#addon.scanner.requests, before)
    equal(addon.scanner.active, false)
    equal(addon:GetMarket().items[2770], snapshot)
    addon:StopScan()
    frame:Hide()
    addon.BrowseUI.views.writs = nil
    addon.db.writSource = oldWrit
end)
test("replacement provider API and market context invalidate cached values", function()
    reset()
    fakeAuctionator({ [1] = 10 })
    equal(Providers.Read("auctionator", 1).unitPrice, 10)
    local f = fakeAuctionator({ [1] = 20 })
    equal(Providers.Read("auctionator", 1).unitPrice, 20)
    local oldFaction = UnitFactionGroup
    UnitFactionGroup = function()
        return "Horde"
    end
    Providers.Read("auctionator", 1)
    equal(f.reads, 2)
    UnitFactionGroup = oldFaction
end)
test("TSM uses the configured source, i:ID strings, and unknown data age", function()
    reset()
    local calls = {}
    TSM_API = {
        GetCustomPriceValue = function(key, itemString)
            calls[#calls + 1] = { key, itemString }
            return 123
        end,
    }
    local price = Providers.Read("tsm", 2770)
    equal(calls[1][1], "DBMinBuyout")
    equal(calls[1][2], "i:2770")
    equal(price.unitPrice, 123)
    equal(price.ageDays, nil)
    equal(price.scannedAt, nil)
    addon:SetTSMKey("dbmarket")
    price = Providers.Read("tsm", 2770)
    equal(calls[2][1], "DBMarket")
    equal(price.sourceLabel, "TSM market")
    addon:SetTSMKey("crafting")
    equal(addon.db.tsmKey, "DBMarket")
end)
test("provider exceptions, bad prices and invalid TSM sources cannot crash tooltips", function()
    reset()
    local f = fakeAuctionator({})
    f.api.GetAuctionPriceByItemID = function()
        error("Auctionator not ready")
    end
    equal(Providers.Read("auctionator", 1), nil)
    assert(Providers.errors.auctionator:match("not ready"))
    for _, value in ipairs({ 0, -1, math.huge, 0 / 0, "123" }) do
        f.api.GetAuctionPriceByItemID = function()
            return value
        end
        Providers.Invalidate()
        equal(Providers.Read("auctionator", 1), nil)
    end
    TSM_API = {
        GetCustomPriceValue = function()
            return nil, "Unknown source"
        end,
    }
    equal(Providers.Read("tsm", 1), nil)
    equal(Providers.errors.tsm, "Unknown source")
    f.api.GetAuctionPriceByItemID = function()
        return 10
    end
    f.api.GetAuctionAgeByItemID = function()
        error("age unavailable")
    end
    Providers.Invalidate()
    local price = Providers.Read("auctionator", 1)
    equal(price.unitPrice, 10)
    equal(price.ageDays, nil)
end)
test("late addon load installs the public price-update callback once", function()
    reset()
    local f = fakeAuctionator({ [2770] = 10 })
    assert(host.events.ADDON_LOADED)
    host.scripts.OnEvent(host, "ADDON_LOADED", "Auctionator")
    equal(f.callbacks, 1)
    equal(Providers.boundAPI, f.api)
    host.scripts.OnEvent(host, "ADDON_LOADED", "TradeSkillMaster")
    equal(f.callbacks, 1)
end)
test("custom market profiles cannot consume unscoped external prices", function()
    reset()
    local f = fakeAuctionator({ [2770] = 1, [2771] = 1 })
    addon.db.profile = "neutral"
    local rows = addon:GetRows(248683)
    equal(rows[1].status, "unknown")
    equal(f.reads, 0)
    addon:GetMarket().items[2770] = fresh({ { quantity = 20, unitPrice = 2 } })
    rows = addon:GetRows(248683)
    equal(rows[1].cost, 40)
    equal(rows[1].source, "own")
end)
test("source settings persist and explicit unavailable source stays unknown", function()
    reset()
    addon.lastCrateID = 248683
    addon:Command("source tsm")
    equal(addon.db.source, "tsm")
    addon:Command("source invalid")
    equal(addon.db.source, "tsm")
    addon:GetMarket().items[2770] = fresh({ { quantity = 20, unitPrice = 1 } })
    equal(addon:GetRows(248683)[1].status, "unknown")
    addon:SetWritSource("tsm")
    addon:SetFeature("scanopen", true)
    local settings = WaylaidLedgerDB
    -- Simulate reload using the same production modules and persisted table.
    local originalCallback, originalFrame, originalReport, originalSlash =
        TooltipDataProcessor.callback, WaylaidLedgerFrame, WaylaidLedgerReportFrame, SlashCmdList.WAYLAIDLEDGER
    local reloaded = {}
    for _, name in ipairs({
        "Localization",
        "Locales",
        "Data",
        "WritData",
        "Catalog",
        "Inventory",
        "Pricing",
        "Providers",
        "WritPricing",
        "Shopping",
        "Scanner",
        "Navigation",
        "NativeShopping",
        "Tooltip",
        "UI",
        "BrowseUI",
        "Minimap",
        "Core",
    }) do
        assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/" .. name .. ".lua"))("WaylaidLedger", reloaded)
    end
    for _, name in ipairs({ "DiscoveryLocales", "Discovery", "BulkScan" }) do
        assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/" .. name .. ".lua"))("WaylaidLedger", reloaded)
    end
    -- Core registers ADDON_LOADED on the newly created unnamed frame. Locate it
    -- via the mock registry exposed by spec.lua rather than changing production.
    local newHost = TEST_FRAMES[#TEST_FRAMES]
    newHost.scripts.OnEvent(newHost, "ADDON_LOADED", "WaylaidLedger")
    equal(reloaded.db, settings)
    equal(reloaded.db.source, "tsm")
    equal(reloaded.db.writSource, "tsm")
    equal(reloaded.db.scanOnOpen, true)
    equal(reloaded:GetMarket().items[2770].offers[1].unitPrice, 1)
    TooltipDataProcessor.callback = originalCallback
    WaylaidLedgerFrame, WaylaidLedgerReportFrame, SlashCmdList.WAYLAIDLEDGER =
        originalFrame, originalReport, originalSlash
    addon:SetFeature("scanopen", false)
end)
test("Auctionator shopping hands off after stopping our scan, with exact quantities", function()
    reset()
    local f = fakeAuctionator({ [2770] = 1, [2771] = 2 })
    addon.lastCrateID = 248683
    addon.UI.Update()
    addon:StartScan("hovered")
    assert(addon.scanner.active)
    f.onSearch = function()
        equal(addon.scanner.active, false)
    end
    equal(addon:Shop(true), true)
    equal(#f.searches, 1)
    equal(#f.searches[1], 2)
    equal(f.searches[1][1].searchString, "Copper Ore")
    equal(f.searches[1][1].quantity, 20)
    equal(f.searches[1][1].isExact, true)
    equal(f.searches[1][2].searchString, "Tin Ore")
    equal(addon:Shop(false, 2), true)
    equal(#f.searches[2], 1)
    equal(f.searches[2][1].searchString, "Tin Ore")
end)
test("shopping rejects unavailable addon, closed AH, bad options and missing crate", function()
    reset()
    equal(addon:Shop(true), false)
    addon.lastCrateID = 248683
    equal(addon:Shop(true), false)
    local f = fakeAuctionator({})
    addon.scanner:SetOpen(false)
    equal(addon:Shop(true), false)
    addon.scanner:SetOpen(true)
    equal(addon:Shop(false, 0), false)
    equal(addon:Shop(false, 3), false)
    equal(addon:Shop(false, 1.5), false)
    addon:Command("shop invalid")
    equal(#f.searches, 0)
end)
test("localized searches wait for actual item names and keep an existing scan running", function()
    reset()
    local f = fakeAuctionator({})
    addon.lastCrateID = 248683
    local originalLocale, originalName, originalLoad = GetLocale, C_Item.GetItemNameByID, C_Item.RequestLoadItemDataByID
    GetLocale = function()
        return "esES"
    end
    local requested = {}
    C_Item.RequestLoadItemDataByID = function(id)
        requested[#requested + 1] = id
    end
    addon:StartScan("hovered")
    equal(addon:Shop(true), false)
    equal(addon.scanner.active, true)
    equal(requested[1], 2770)
    equal(#f.searches, 0)
    C_Item.GetItemNameByID = function(id)
        return id == 2770 and "Mena de cobre" or "Mena de estaño"
    end
    equal(addon:Shop(true), true)
    equal(f.searches[1][1].searchString, "Mena de cobre")
    GetLocale, C_Item.GetItemNameByID, C_Item.RequestLoadItemDataByID = originalLocale, originalName, originalLoad
end)
test("older Auctionator shopping API converts quantities to an addon-managed list", function()
    reset()
    local f = fakeAuctionator({})
    f.api.MultiSearchAdvanced = nil
    local created
    f.api.ConvertToSearchString = function(caller, term)
        equal(caller, "WaylaidLedger")
        return term.searchString .. ":" .. term.quantity
    end
    f.api.CreateShoppingList = function(caller, name, terms)
        created = { caller, name, terms }
    end
    addon.lastCrateID = 248683
    equal(addon:Shop(false, 2), true)
    equal(created[1], "WaylaidLedger")
    assert(created[2]:match("248683.*option 2"))
    equal(created[3][1], "Tin Ore:20")
    f.api.ConvertToSearchString = function()
        error("conversion failed")
    end
    equal(addon:Shop(false, 1), false)
end)
test("shopping exceptions are reported without restarting or losing our completed prices", function()
    reset()
    local f = fakeAuctionator({})
    f.api.MultiSearchAdvanced = function()
        error("search blocked")
    end
    addon.lastCrateID = 248683
    local market = addon:GetMarket()
    market.items[2770] = fresh({ { quantity = 20, unitPrice = 1 } })
    addon:StartScan("hovered")
    equal(addon:Shop(true), false)
    equal(addon.scanner.active, false)
    equal(market.items[2770].offers[1].unitPrice, 1)
    assert(Providers.errors.auctionator:match("search blocked"))
end)
test("estimated tooltip winners use green and plain prices", function()
    reset()
    TSM_API = {
        GetCustomPriceValue = function(_, itemString)
            return itemString == "i:2770" and 1 or 2
        end,
    }
    local tooltip = CreateFrame("GameTooltip")
    TooltipDataProcessor.callback(tooltip, { id = 248683 })
    assert(not tooltip.lines[3][2]:match("~"))
    assert(not tooltip.lines[3][2]:match("%[T%]"))
    assert(not tooltip.lines[3][2]:match("age unknown"))
    equal(tooltip.lines[3][3], 0.25)
    equal(tooltip.lines[3][4], 1)
    for _, line in ipairs(tooltip.lines) do
        assert(not line[1]:match("^Cheapest:"))
    end
end)
test("legacy shop command defaults to the current lowest known option", function()
    reset()
    local calls = fakeAuctionator({ [2770] = 10, [2771] = 1 })
    addon.lastCrateID = 248683
    addon.scanner:SetOpen(true)
    equal(addon:Shop(false), true)
    assert(calls.searches[1][1].searchString:find("Tin", 1, true))
end)
test("diagnostics include provider policy, per-row provenance, and API errors", function()
    reset()
    fakeAuctionator({ [2770] = 5 })
    addon.lastCrateID = 248683
    local report = addon:Report()
    assert(report:find(addon.version, 1, true))
    assert(report:match("Price policy: auto"))
    assert(report:match("source=auctionator estimated=true ageDays=0"))
    Providers.errors.tsm = "not ready"
    report = addon:Report()
    assert(report:match("TSM last error: not ready"))
end)
reset()
