local test, equal = ...
local function fixture(action)
    local saved = { CreateFrame = CreateFrame, hooksecurefunc = hooksecurefunc, debugprofilestop = debugprofilestop }
    local frames = {}
    CreateFrame = function()
        local f = { scripts = {}, events = {} }
        function f:SetScript(key, fn)
            self.scripts[key] = fn
        end
        function f:RegisterEvent(key)
            self.events[key] = true
        end
        frames[#frames + 1] = f
        return f
    end
    hooksecurefunc = function(t, k, fn)
        local old = t[k]
        t[k] = function(...)
            old(...)
            fn(...)
        end
    end
    local market = { items = {}, failures = {} }
    local f = { now = 0, wall = 1000, rows = {}, calls = 0, observed = {}, retries = 0 }
    local a = {
        Writs = {},
        db = { maxAge = 1800, replication = { oldRealm = 1000 } },
        GetMarket = function()
            return market
        end,
        Discovery = {
            Observe = function(id, name)
                f.observed[id] = name
            end,
            Retry = function()
                f.retries = f.retries + 1
                return 0
            end,
            Bags = function() end,
            Prune = function() end,
            IsWorking = function()
                return f.resolving
            end,
            Scope = function()
                return f.scope or f.observed
            end,
        },
    }
    for _, name in ipairs({ "Localization", "Locales", "Scanner", "BulkScan", "Pricing", "WritPricing" }) do
        assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/" .. name .. ".lua"))("WaylaidLedger", a)
    end
    local api = {
        IsThrottledMessageSystemReady = function()
            return true
        end,
        ReplicateItems = function()
            f.calls = f.calls + 1
        end,
        GetNumReplicateItems = function()
            return #f.rows
        end,
        GetReplicateItemInfo = function(index)
            return unpack(f.rows[index + 1], 1, 18)
        end,
    }
    f.scanner = a.Scanner.New(api, {
        now = function()
            return f.now
        end,
        wallTime = function()
            return f.wall
        end,
    }, {})
    a.scanner = f.scanner
    f.scanner:SetOpen(true)
    a.BulkScan.Install(f.scanner)
    f.frame = frames[1]
    f.market = market
    f.addon = a
    f.api = api
    function f.row(id, name, count, buyout)
        local row = { [1] = name, [3] = count, [10] = buyout, [17] = id, [18] = true }
        return row
    end
    function f.deliver()
        f.frame.scripts.OnEvent(f.frame, "REPLICATE_ITEM_LIST_UPDATE")
        while f.frame.scripts.OnUpdate do
            f.frame.scripts.OnUpdate()
        end
    end
    local ok, err = pcall(action, f)
    CreateFrame, hooksecurefunc = saved.CreateFrame, saved.hooksecurefunc
    debugprofilestop = saved.debugprofilestop
    assert(ok, err)
end

test("6000 auctions use one request and bounded processing batches", function()
    fixture(function(f)
        for index = 1, 6000 do
            f.rows[index] = f.row(index, "Item " .. index, 10, 100)
        end
        equal(f.scanner:Start({}), true)
        equal(f.calls, 1)
        f.frame.scripts.OnEvent(f.frame, "REPLICATE_ITEM_LIST_UPDATE")
        equal(f.scanner.active, true)
        equal(next(f.observed), nil)
        f.scanner:Tick()
        equal(next(f.observed), nil)
        f.frame.scripts.OnUpdate()
        equal(f.observed[250], "Item 250")
        equal(f.observed[251], nil)
        local batches = 1
        while f.frame.scripts.OnUpdate do
            f.frame.scripts.OnUpdate()
            batches = batches + 1
        end
        equal(batches, 25)
        equal(f.scanner.completed, 6000)
        equal(f.calls, 1)
        local quote = f.addon.Pricing.Quote(f.market.items[6000], 200)
        equal(quote.cost, 2000)
        equal(quote.estimated, true)
        equal(quote.available, nil)
    end)
end)
test("duplicate auctions do not allocate a Lua tuple table for every row", function()
    fixture(function(f)
        local row = f.row(11, "Herb", 10, 100)
        for index = 1, 30000 do
            f.rows[index] = row
        end
        f.scanner:Start({})
        collectgarbage("collect")
        collectgarbage("stop")
        local before = collectgarbage("count")
        local ok, err = pcall(function()
            f.deliver()
            assert(collectgarbage("count") - before < 256, "scan allocated per-auction temporary objects")
            equal(f.market.items[11].unitPrice, 10)
        end)
        collectgarbage("restart")
        assert(ok, err)
    end)
end)
test("bulk snapshots use correct buyout tuple index and retain minimum unit prices", function()
    fixture(function(f)
        f.rows = { f.row(11, "Herb", 20, 100), f.row(11, "Herb", 5, 50), f.row(12, "Ore", 1, 0) }
        f.scanner:Start({ 11, 12 })
        f.deliver()
        equal(f.market.items[11].unitPrice, 5)
        equal(f.market.items[12], nil)
        equal(f.observed[12], "Ore")
        equal(f.retries, 1)
        equal(f.addon.Pricing.Quote(f.market.items[11], 200).cost, 1000)
        equal(f.addon.Pricing.Quote(f.market.items[12], 1).status, "unknown")
    end)
end)
test("fresh exact shortages survive full-scan estimates", function()
    fixture(function(f)
        f.market.items[11] = { kind = "commodity", offers = {}, scannedAt = f.wall }
        f.rows = { f.row(11, "Herb", 20, 100) }
        f.scanner:Start({ 11 })
        f.deliver()
        equal(f.addon.Pricing.Quote(f.market.items[11], 1).status, "short")
    end)
end)
test("full scans ignore old guessed lockouts but respect observed responses", function()
    fixture(function(f)
        equal(f.addon.db.replication, nil)
        f.addon.db.replication = { oldRealm = f.wall }
        f.rows = { f.row(11, "Herb", 20, 100) }
        equal(f.scanner:Start({ 11 }), true)
        equal(f.calls, 1)
        equal(f.scanner:Start({ 11 }), false)
        equal(f.calls, 1)
        f.deliver()
        equal(f.market.items[11].unitPrice, 5)
        f.rows = { f.row(11, "Herb", 20, 200) }
        local ok, reason = f.scanner:Start({ 11 })
        equal(ok, false)
        assert(reason:find("900 seconds", 1, true))
        equal(f.calls, 1)
        f.wall = f.wall + 901
        equal(f.scanner:Start({ 11 }), true)
        equal(f.calls, 2)
        f.deliver()
        equal(f.market.items[11].unitPrice, 10)
    end)
end)
test("another addon's bulk response is not duplicated or retained", function()
    fixture(function(f)
        f.rows = { f.row(11, "Herb", 20, 100) }
        f.api.ReplicateItems()
        equal(f.scanner.active, false)
        f.deliver()
        equal(f.market.items[11], nil)
        equal(next(f.observed), nil)
        equal(f.calls, 1)
        equal(f.scanner:Start({ 11 }), false)
        equal(f.calls, 1)
        equal(f.addon.db.lastReplicateResponseAt, f.wall)
    end)
end)
test("Auctionator's saved request timestamp guards reloads and ignores invalid clock values", function()
    local original = Auctionator
    local ok, err = pcall(function()
        fixture(function(f)
            Auctionator = { SavedState = { TimeOfLastReplicateScan = f.wall - 100 } }
            local started, reason = f.scanner:Start({})
            equal(started, false)
            assert(reason:find("800 seconds", 1, true))
            equal(f.calls, 0)
            Auctionator.SavedState.TimeOfLastReplicateScan = "bad timestamp"
            equal(f.addon.BulkScan.RemainingCooldown(f.wall), 0)
            Auctionator.SavedState.TimeOfLastReplicateScan = f.wall + 10000
            equal(f.addon.BulkScan.RemainingCooldown(f.wall), 0)
            Auctionator.SavedState = false
            f.addon.db.lastReplicateResponseAt = f.wall - 50
            equal(f.addon.BulkScan.RemainingCooldown(f.wall), 850)
            -- The guard is addon-wide, not reset by switching a market profile.
            f.addon.db.profile = "neutral"
            equal(f.scanner:Start({}), false)
        end)
    end)
    Auctionator = original
    assert(ok, err)
end)
test("an external snapshot arriving while waiting for readiness prevents a duplicate request", function()
    fixture(function(f)
        f.api.IsThrottledMessageSystemReady = function()
            return false
        end
        equal(f.scanner:Start({}), true)
        f.frame.scripts.OnEvent(f.frame, "REPLICATE_ITEM_LIST_UPDATE")
        f.api.IsThrottledMessageSystemReady = function()
            return true
        end
        f.scanner:Tick()
        equal(f.calls, 0)
        equal(f.scanner.active, false)
        equal(f.frame.scripts.OnUpdate, nil)
        equal(next(f.market.items), nil)
        assert(f.scanner.message:find("cooldown", 1, true))
    end)
end)
test("bulk commits only the scope resolved from descriptions and can be cancelled before commit", function()
    fixture(function(f)
        f.rows = { f.row(11, "Herb", 20, 100), f.row(12, "Unrelated", 1, 100), f.row(31, "Writ", 1, 50) }
        f.resolving = true
        f.scope = { [31] = true }
        f.scanner:Start({})
        f.frame.scripts.OnEvent(f.frame, "REPLICATE_ITEM_LIST_UPDATE")
        f.frame.scripts.OnUpdate()
        f.frame.scripts.OnUpdate()
        equal(next(f.market.items), nil)
        f.scope[11] = true
        f.resolving = false
        f.frame.scripts.OnUpdate()
        equal(f.market.items[11].unitPrice, 5)
        equal(f.market.items[31].unitPrice, 50)
        equal(f.market.items[12], nil)
        equal(f.scanner.completed, 2)
        f.market.items = {}
        f.wall = f.wall + 901
        assert(f.scanner:Start({}))
        f.frame.scripts.OnEvent(f.frame, "REPLICATE_ITEM_LIST_UPDATE")
        f.frame.scripts.OnUpdate()
        f.scanner:Stop()
        equal(f.frame.scripts.OnUpdate, nil)
        equal(next(f.market.items), nil)
    end)
end)
test("stalled delivery resolution times out without committing a snapshot", function()
    fixture(function(f)
        f.rows = { f.row(11, "Herb", 20, 100) }
        f.resolving = true
        f.scanner:Start({})
        f.frame.scripts.OnEvent(f.frame, "REPLICATE_ITEM_LIST_UPDATE")
        f.frame.scripts.OnUpdate()
        f.frame.scripts.OnUpdate()
        f.now = 31
        f.frame.scripts.OnUpdate()
        equal(f.frame.scripts.OnUpdate, nil)
        equal(f.scanner.active, false)
        equal(next(f.market.items), nil)
    end)
end)
test("cancelled and closed full scans ignore late responses", function()
    fixture(function(f)
        f.rows = { f.row(11, "Herb", 20, 100) }
        f.scanner:Start({})
        f.scanner:Stop()
        f.frame.scripts.OnEvent(f.frame, "REPLICATE_ITEM_LIST_UPDATE")
        equal(next(f.market.items), nil)
        equal(f.frame.scripts.OnUpdate, nil)
        f.wall = f.wall + 901
        equal(f.scanner:Start({}), true)
        f.frame.scripts.OnEvent(f.frame, "AUCTION_HOUSE_CLOSED")
        f.frame.scripts.OnEvent(f.frame, "REPLICATE_ITEM_LIST_UPDATE")
        equal(next(f.market.items), nil)
    end)
end)
test("full scan times out without recording missing items as sold out", function()
    fixture(function(f)
        f.scanner:Start({})
        f.now = 31
        f.scanner:Tick()
        equal(f.scanner.active, false)
        assert(f.scanner.message:find("No auction snapshot response", 1, true))
        equal(f.addon.db.lastReplicateResponseAt, nil)
        equal(next(f.market.items), nil)
        equal(f.frame.scripts.OnUpdate, nil)
    end)
end)

test("a request waiting for readiness can be retried immediately after timing out", function()
    fixture(function(f)
        f.api.IsThrottledMessageSystemReady = function()
            return false
        end
        f.scanner:Start({})
        equal(f.calls, 0)
        f.now = 31
        f.scanner:Tick()
        equal(f.scanner.active, false)
        equal(f.addon.db.replication, nil)
        f.api.IsThrottledMessageSystemReady = function()
            return true
        end
        equal(f.scanner:Start({}), true)
        equal(f.calls, 1)
    end)
end)
test("replicate read errors end the job without committing incomplete prices", function()
    fixture(function(f)
        f.api.GetReplicateItemInfo = function()
            error("data unavailable")
        end
        f.rows = { f.row(11, "Herb", 20, 100) }
        f.scanner:Start({})
        f.deliver()
        equal(f.scanner.active, false)
        equal(next(f.market.items), nil)
    end)
end)

test("slow replication reads yield on elapsed time without timing out a progressing scan", function()
    fixture(function(f)
        local elapsed, reads = 0, 0
        debugprofilestop = function()
            return elapsed
        end
        local read = f.api.GetReplicateItemInfo
        f.api.GetReplicateItemInfo = function(index)
            elapsed = elapsed + 2
            reads = reads + 1
            return read(index)
        end
        for id = 1, 100 do
            f.rows[id] = f.row(id, "Item " .. id, 10, 100)
        end
        f.scanner:Start({})
        f.frame.scripts.OnEvent(f.frame, "REPLICATE_ITEM_LIST_UPDATE")
        equal(reads, 0)
        for frame = 1, 100 do
            f.now = frame
            f.scanner:Tick()
            equal(reads, frame - 1)
            f.frame.scripts.OnUpdate()
            equal(reads, frame)
        end
        f.frame.scripts.OnUpdate()
        equal(f.scanner.completed, 100)
        equal(f.scanner.active, false)
        equal(f.market.items[100].unitPrice, 10)
        equal(f.calls, 1)
    end)
end)
