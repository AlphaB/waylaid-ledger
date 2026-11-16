local test, equal = ...

test("bundled install discovers additional crates and writs using one bulk scan", function()
    local saved = {
        C_AuctionHouse = C_AuctionHouse,
        C_Item = C_Item,
        C_TooltipInfo = C_TooltipInfo,
        C_Container = C_Container,
        WaylaidLedgerDB = WaylaidLedgerDB,
        Auctionator = Auctionator,
        TSM_API = TSM_API,
        WaylaidLedgerFrame = WaylaidLedgerFrame,
        WaylaidLedgerReportFrame = WaylaidLedgerReportFrame,
        callback = TooltipDataProcessor.callback,
        slash = SlashCmdList.WAYLAIDLEDGER,
    }
    local a = {}
    local f = TEST_SCANNER_FIXTURE()
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
            "Data",
            "WritData",
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
        a.UI.frame:Show()
        a.autoReason, a.autoPaused, a.lastExternalAt = "panel", false, nil
        a:StartScan("all")
        equal(requests, 1)
        equal(a.scanner.bulkMode, true)
        local frame = a.BulkScan.engine.frame
        frame.scripts.OnEvent(frame, "REPLICATE_ITEM_LIST_UPDATE")
        while frame.scripts.OnUpdate do
            frame.scripts.OnUpdate()
        end
        while a.Discovery.frame.scripts.OnUpdate do
            a.Discovery.frame.scripts.OnUpdate()
        end
        equal(a.scanner.active, false)
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
        equal(a.BulkScan.engine.job.own, false)
        frame.scripts.OnEvent(frame, "REPLICATE_ITEM_LIST_UPDATE")
        while frame.scripts.OnUpdate do
            frame.scripts.OnUpdate()
        end
        while a.Discovery.frame.scripts.OnUpdate do
            a.Discovery.frame.scripts.OnUpdate()
        end
        a:StartScan("deep")
        equal(#a.scanner.queue, 428)
        equal(a.scanner.bulkMode, false)
        a:StopScan()
        a.db.source = "auto"
        a:GetMarket().bulkAt = nil
        a.autoReason, a.autoPaused, a.lastExternalAt = "panel", false, nil
        local beforeAuto = requests
        a:AutoScan()
        equal(requests, beforeAuto + 1)
        equal(a.scanner.bulkMode, true)
        host.scripts.OnEvent(host, "AUCTION_HOUSE_CLOSED")
    end)
    for key, value in pairs(saved) do
        if key ~= "callback" and key ~= "slash" then
            _G[key] = value
        end
    end
    C_TooltipInfo = saved.C_TooltipInfo
    Auctionator = saved.Auctionator
    TSM_API = saved.TSM_API
    TooltipDataProcessor.callback = saved.callback
    SlashCmdList.WAYLAIDLEDGER = saved.slash
    assert(ok, err)
end)
