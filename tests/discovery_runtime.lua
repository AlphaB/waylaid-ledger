local test, equal = ...

test("bundled install discovers additional crates and writs using one bulk scan", function()
    local saved = {
        C_AuctionHouse = C_AuctionHouse,
        time = time,
        C_Item = C_Item,
        C_TooltipInfo = C_TooltipInfo,
        C_Container = C_Container,
        WaylaidLedgerDB = WaylaidLedgerDB,
        Auctionator = Auctionator,
        TSM_API = TSM_API,
        WaylaidLedgerFrame = WaylaidLedgerFrame,
        WaylaidLedgerReportFrame = WaylaidLedgerReportFrame,
        LibStub = LibStub,
        AuctionHouseFrame = AuctionHouseFrame,
        AuctionHouseFrameDisplayMode = AuctionHouseFrameDisplayMode,
        callback = TooltipDataProcessor.callback,
        slash = SlashCmdList.WAYLAIDLEDGER,
    }
    local a = {}
    local f = TEST_SCANNER_FIXTURE()
    f.wall = 1000
    time = function()
        return f.wall
    end
    local names = {
        [21] = "Waylaid Crate: Runtime Test",
        [31] = "Craftsman's Writ: Runtime Test",
        [11] = "Sample Herb",
        [12] = "Other Herb",
    }
    local records = { { 21, 1, 100 }, { 31, 1, 20 }, { 11, 10, 50 }, { 12, 10, 100 } }
    local requests = 0
    f.api.ReplicateItems = function()
        requests = requests + 1
    end
    f.api.GetNumReplicateItems = function()
        return #records
    end
    f.api.GetReplicateItemInfo = function(index)
        local r = records[index + 1]
        return names[r[1]], nil, r[2], 1, nil, 1, nil, 1, 1, r[3], nil, nil, nil, nil, nil, 0, r[1], true
    end
    local marketKey = table.concat(
        { GetCurrentRegion(), GetNormalizedRealmName(), UnitFactionGroup("player"), WOW_PROJECT_ID, "default" },
        ":"
    )
    local cached = {
        items = {
            [248683] = { kind = "estimate", unitPrice = 50, scannedAt = time() },
            [2770] = { kind = "estimate", unitPrice = 5, scannedAt = time() },
            [2771] = { kind = "estimate", unitPrice = 6, scannedAt = time() },
            [264037] = { kind = "estimate", unitPrice = 20, scannedAt = time() },
            [8069] = { kind = "estimate", unitPrice = 2, scannedAt = time() },
        },
        failures = {},
    }
    local settings = { schema = 1, markets = { [marketKey] = cached }, source = "own", writSource = "own" }
    C_AuctionHouse = f.api
    Auctionator = nil
    TSM_API = nil
    WaylaidLedgerDB = settings
    C_Container = {
        GetContainerNumSlots = function()
            return 0
        end,
    }
    C_Item = {
        GetItemNameByID = function(id)
            return names[id]
        end,
        RequestLoadItemDataByID = function() end,
    }
    C_TooltipInfo = {
        GetItemByID = function(id)
            if id == 21 then
                return { lines = { { leftText = "- 17 Sample Herb\n- 9 Other Herb" } } }
            end
            if id == 31 then
                return { lines = { { leftText = "Bring 200 Sample Herb to the quartermaster." } } }
            end
        end,
    }
    local ok, err = pcall(function()
        for _, name in ipairs({
            "Localization",
            "Locales",
            "Data",
            "WritData",
            "DiscoveryLocales",
            "Discovery",
            "Catalog",
            "Inventory",
            "Pricing",
            "BulkScan",
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
            local chunk = loadfile(PROJECT_ROOT .. "/WaylaidLedger/" .. name .. ".lua")
            if chunk then
                chunk("WaylaidLedger", a)
            end
        end
        local host = TEST_FRAMES[#TEST_FRAMES]
        host.scripts.OnEvent(host, "ADDON_LOADED", "WaylaidLedger")
        LibStub = {
            GetLibrary = function()
                return {
                    CreateTab = function(_, _, panel)
                        panel:Hide()
                    end,
                }
            end,
        }
        AuctionHouseFrame = CreateFrame("Frame", nil, UIParent)
        AuctionHouseFrame.Tabs = { CreateFrame("Button", nil, AuctionHouseFrame) }
        AuctionHouseFrameDisplayMode = { Buy = "buy" }
        equal(#a.Catalog.AllCrates(), 30)
        equal(#a.Catalog.AllContracts("writs"), 150)
        equal(a.db, settings)
        equal(a:GetMarket(), cached)
        local savedCrate = a.Shopping.Entry("crates", 248683)
        equal(savedCrate.delivery, 100)
        equal(savedCrate.total, 150)
        local savedWrit = a.Shopping.Entry("writs", 264037)
        equal(savedWrit.delivery, 400)
        equal(savedWrit.total, 420)
        equal(requests, 0)
        host.scripts.OnEvent(host, "AUCTION_HOUSE_SHOW")
        equal(a.UI.frame, nil)
        local listHost = CreateFrame("Frame", nil, UIParent)
        listHost:SetSize(1000, 550)
        local view = a.BrowseUI.Create(listHost, "crates")
        a.BrowseUI.Refresh(view)
        a.autoReason, a.autoPaused, a.lastExternalAt = "panel", false, nil
        a:StartScan("all")
        equal(requests, 1)
        equal(a.scanner.bulkMode, true)
        equal(view.summary.text, "Full scan: waiting")
        equal(view.refreshButton.text, "Stop")
        local frame = a.BulkScan.engine.frame
        frame.scripts.OnEvent(frame, "REPLICATE_ITEM_LIST_UPDATE")
        equal(view.summary.text, "Auctions 0/4")
        while frame.scripts.OnUpdate do
            frame.scripts.OnUpdate()
            if a.Discovery.frame.scripts.OnUpdate then
                a.Discovery.frame.scripts.OnUpdate()
            end
        end
        while a.Discovery.frame.scripts.OnUpdate do
            a.Discovery.frame.scripts.OnUpdate()
        end
        equal(a.scanner.active, false)
        equal(view.refreshButton.text, "Refresh")
        local crate = a.Shopping.Entry("crates", 21)
        equal(crate.purchase, 100)
        equal(crate.delivery, 85)
        equal(crate.total, 185)
        equal(crate.purchaseQuote.estimated, true)
        equal(crate.deliveryRows[1].source, "replicate")
        local writ = a.Shopping.Entry("writs", 31)
        equal(writ.purchase, 20)
        equal(writ.delivery, 1000)
        equal(writ.total, 1020)
        local tip = CreateFrame("GameTooltip")
        a.Tooltip.Append(tip, 21)
        assert(#tip.lines > 2)
        a:SetSource("tsm")
        equal(a:GetRows(21)[1].status, "unknown")
        local before = requests
        equal(a:StartScan("all"), false)
        equal(requests, before)
        f.wall = f.wall + 901
        equal(a:StartScan("all"), true)
        equal(requests, before + 1)
        a:StopScan()
        if a.RefreshList then
            equal(a:RefreshList(), true)
            equal(a.refreshJob, nil)
            equal(a.pendingProviderScan, nil)
        else
            a:StartScan("all")
        end
        equal(a.scanner.active, true)
        C_AuctionHouse.ReplicateItems()
        equal(a.scanner.active, false)
        equal(a.BulkScan.engine.job, nil)
        equal(view.summary.text, "Another addon is scanning.")
        equal(view.refreshButton.text, "Refresh")
        frame.scripts.OnEvent(frame, "REPLICATE_ITEM_LIST_UPDATE")
        equal(frame.scripts.OnUpdate, nil)
        view.refreshButton.scripts.OnClick()
        assert(a.Providers.scan)
        a.Providers.EndExternalScan()
        equal(a.Providers.scan, nil)
        a:StartScan("deep")
        equal(#a.scanner.queue, 428)
        equal(a.scanner.bulkMode, false)
        a:StopScan()
        a.db.source = "auto"
        a:GetMarket().bulkAt = nil
        a.UI.auctionHost:Show()
        a.UI.SelectBrowserTab("writs")
        local beforeAuto = requests
        for _ = 1, 20 do
            a.UI.SelectBrowserTab("crates")
            a.UI.SelectBrowserTab("writs")
        end
        equal(requests, beforeAuto)
        equal(a.autoDue, nil)
        a.db.scanOnOpen = true
        f.wall = f.wall + 901
        a.autoReason, a.autoPaused, a.lastExternalAt = "open", false, nil
        a:AutoScan()
        equal(requests, beforeAuto + 1)
        equal(a.scanner.bulkMode, true)
        equal(a.scanBrowser, false)
        equal(a:RefreshList(a.BrowseUI.views.writs), false)
        equal(a.scanBrowser, false)
        equal(a.scanAutomatic, true)
        equal(a.scanContext.reason, "open")
        frame.scripts.OnEvent(frame, "REPLICATE_ITEM_LIST_UPDATE")
        while frame.scripts.OnUpdate do
            frame.scripts.OnUpdate()
            if a.Discovery.frame.scripts.OnUpdate then
                a.Discovery.frame.scripts.OnUpdate()
            end
        end
        while a.Discovery.frame.scripts.OnUpdate do
            a.Discovery.frame.scripts.OnUpdate()
        end
        equal(a.scanner.active, false)
        -- A completed automatic opening scan must not own the next manual refresh.
        f.wall = f.wall + 901
        equal(a:RefreshList(a.BrowseUI.views.writs), true)
        equal(a.scanAutomatic, false)
        equal(a.scanBrowser, false)
        equal(a.scanOnOpen, false)
        equal(a.scanContext.reason, "manual")
        a.UI.auctionHost:Hide()
        equal(a.scanner.active, true, "leaving the list must preserve the explicit refresh")
        a:StopScan()
        a.scanBrowser, a.scanOnOpen = true, true
        a.NativeShopping.pendingQuantity = { itemID = 11, quantity = 200 }
        equal(a:BeginScan({}, "manual", "writs"), true)
        equal(a.scanBrowser, false)
        equal(a.scanOnOpen, false)
        equal(a.NativeShopping.pendingQuantity, nil)
        equal(a.scanContext.reason, "manual")
        equal(a.scanContext.category, "writs")
        host.scripts.OnEvent(host, "AUCTION_HOUSE_CLOSED")

        -- Replay Auctionator autoscan through the real core hooks and both
        -- event streams, with tab navigation while the scan owns the AH.
        local listener, dbUpdate
        local events =
            { ScanStart = "start", ScanProgress = "progress", ScanComplete = "complete", ScanFailed = "failed" }
        Auctionator = {
            API = {
                v1 = {
                    RegisterForDBUpdate = function(_, callback)
                        dbUpdate = callback
                    end,
                    GetAuctionPriceByItemID = function()
                        return 42
                    end,
                },
            },
            FullScan = { Events = events },
            EventBus = {
                Register = function(_, receiver)
                    listener = receiver
                end,
            },
        }
        a.Providers.Install()
        a:Command("debug on")
        a.db.scanOnOpen = true
        host.scripts.OnEvent(host, "AUCTION_HOUSE_SHOW")
        assert(a.autoDue)
        listener:ReceiveEvent(events.ScanStart)
        C_AuctionHouse.ReplicateItems()
        local externalRequests = requests
        equal(a.autoDue, nil)
        equal(a.scanner.active, false)
        equal(a.BulkScan.engine.job, nil)
        local rowsRead, descriptions, redraws = 0, 0, 0
        local oldRows, oldRead, oldUpdate = f.api.GetReplicateItemInfo, a.Discovery.Read, a.UI.Update
        f.api.GetReplicateItemInfo = function(...)
            rowsRead = rowsRead + 1
            return oldRows(...)
        end
        a.Discovery.Read = function(...)
            descriptions = descriptions + 1
            return oldRead(...)
        end
        a.UI.Update = function(...)
            redraws = redraws + 1
            return oldUpdate(...)
        end
        frame.scripts.OnEvent(frame, "REPLICATE_ITEM_LIST_UPDATE")
        a.UI.auctionHost:Show()
        for _ = 1, 20 do
            a.UI.SelectBrowserTab("writs")
            a.UI.SelectBrowserTab("crates")
        end
        equal(requests, externalRequests)
        equal(a.autoDue, nil)
        equal(a:StartScan("all"), false)
        local discovery = a.Discovery.frame
        local rendersBefore = redraws
        collectgarbage("collect")
        local memoryBefore = collectgarbage("count")
        for tick = 1, 600 do
            for id = 1, 100 do
                discovery.scripts.OnEvent(discovery, "ITEM_DATA_LOAD_RESULT", 10000 + tick * 100 + id, true)
                discovery.scripts.OnEvent(discovery, "TOOLTIP_DATA_UPDATE", 1000 + id)
            end
            listener:ReceiveEvent(events.ScanProgress, 0.2 + tick / 600 * 0.79)
            a.Providers.frame.scripts.OnUpdate()
            if discovery.scripts.OnUpdate then
                discovery.scripts.OnUpdate()
            end
        end
        collectgarbage("collect")
        assert(collectgarbage("count") - memoryBefore < 512, "external scan retained market data")
        equal(rowsRead, 0)
        equal(descriptions, 0)
        equal(redraws, rendersBefore)
        equal(a.BrowseUI.views.crates.summary.text, "Auctionator: 99%")
        equal(a.BrowseUI.views.crates.refreshButton.enabled, false)
        equal(frame.scripts.OnUpdate, nil)
        equal(requests, externalRequests)
        dbUpdate()
        assert(a.Providers.scan, "price callbacks must not unlock an active full scan")
        listener:ReceiveEvent(events.ScanComplete, { { replicateInfo = {} } })
        local diagnostics = table.concat(a.db.log, "\n")
        assert(diagnostics:find("[auctionator.progress]", 1, true))
        assert(diagnostics:find("ScanComplete", 1, true))
        assert(diagnostics:find("ignoredDiscoveryEvents=120000", 1, true))
        assert(#a.db.log < 60, "diagnostics flooded the log during Auctionator's event storm")
        equal(a.Providers.scan, nil)
        equal(a.autoDue, nil)
        equal(requests, externalRequests)
        equal(a.BrowseUI.views.crates.refreshButton.enabled, true)
        -- Refresh after autoscan reuses public prices, never requests another snapshot.
        for _, source in ipairs({ "auto", "auctionator" }) do
            a.db.source, a.db.writSource = source, source
            equal(a:RefreshList(a.BrowseUI.views.crates), true)
            equal(a:RefreshList(a.BrowseUI.views.writs), true)
            equal(requests, externalRequests)
            equal(rowsRead, 0)
            equal(a.scanner.active, false)
            equal(a.BulkScan.engine.job, nil)
            equal(a.autoDue, nil)
        end
        equal(a:GetRows(21)[1].source, "auctionator")
        equal(a:GetRows(21)[1].cost, 17 * 42)
        -- Failure and AH closure also release status, without resuming queries.
        listener:ReceiveEvent(events.ScanStart)
        listener:ReceiveEvent(events.ScanFailed)
        assert(a.db.log[#a.db.log]:find("ScanFailed", 1, true))
        equal(a.Providers.scan, nil)
        equal(a.autoDue, nil)
        listener:ReceiveEvent(events.ScanStart)
        host.scripts.OnEvent(host, "AUCTION_HOUSE_CLOSED")
        assert(table.concat(a.db.log, "\n"):find("auction house closed; elapsed=", 1, true))
        equal(a.Providers.scan, nil)
        equal(a.autoDue, nil)
        f.api.GetReplicateItemInfo, a.Discovery.Read, a.UI.Update = oldRows, oldRead, oldUpdate
    end)
    for key, value in pairs(saved) do
        if key ~= "callback" and key ~= "slash" then
            _G[key] = value
        end
    end
    C_TooltipInfo = saved.C_TooltipInfo
    Auctionator = saved.Auctionator
    TSM_API = saved.TSM_API
    AuctionHouseFrame, AuctionHouseFrameDisplayMode = saved.AuctionHouseFrame, saved.AuctionHouseFrameDisplayMode
    TooltipDataProcessor.callback = saved.callback
    SlashCmdList.WAYLAIDLEDGER = saved.slash
    assert(ok, err)
end)
