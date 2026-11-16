local addon, test, equal = ...

local function fixture(action)
    local oldTooltip = GameTooltip
    GameTooltip = CreateFrame("GameTooltip")
    local oldScanner, oldEngine, oldExternal = addon.scanner, addon.BulkScan.engine, addon.Providers.scan
    local parent = CreateFrame("Frame", nil, UIParent)
    parent:SetSize(1000, 550)
    local oldViews = addon.BrowseUI.views
    addon.BrowseUI.views = {}
    local view = addon.BrowseUI.Create(parent, "crates")
    view.entries = {}
    addon.scanner = { active = true, bulkMode = true, index = 1, queue = {} }
    addon.BulkScan.engine, addon.Providers.scan = nil, nil
    local ok, err = pcall(action, view)
    addon.scanner, addon.BulkScan.engine, addon.BrowseUI.views, addon.Providers.scan =
        oldScanner, oldEngine, oldViews, oldExternal
    GameTooltip = oldTooltip
    assert(ok, err)
end

test("full-scan lists never display the empty per-item queue as 1/0", function()
    fixture(function(view)
        addon.BrowseUI.Render(view)
        equal(view.summary.text, "Full scan: waiting")
        equal(view.refreshButton.text, "Stop")
        addon.BulkScan.engine = { job = { own = true, received = true, index = 250, count = 6000 } }
        addon.BrowseUI.UpdateScanStatus()
        equal(view.summary.text, "Auctions 250/6000")
        addon.BulkScan.engine.job.index, addon.BulkScan.engine.job.count = 0, 0
        addon.BrowseUI.UpdateScanStatus()
        equal(view.summary.text, "Finishing full scan")
    end)
end)

test("Auctionator progress updates status without rebuilding rows or offering to stop its scan", function()
    fixture(function(view)
        addon.scanner.active = false
        addon.Providers.scan = {}
        addon.BrowseUI.Render(view)
        equal(view.summary.text, "Another addon is scanning.")
        equal(view.refreshButton.text, "Refresh")
        equal(view.refreshButton.enabled, false)
        GameTooltip.lines = {}
        view.refreshButton.scripts.OnEnter(view.refreshButton)
        equal(GameTooltip.lines[1][1], "Another addon is scanning.")
        equal(GameTooltip.lines[2][1], "Wait for the other addon's scan to finish before refreshing prices.")
        local entries = view.visibleEntries
        addon.Providers.scan.percent = 42
        addon.BrowseUI.UpdateScanStatus()
        equal(view.summary.text, "Auctionator: 42%")
        equal(view.visibleEntries, entries)
        addon.Providers.scan = nil
        addon.BrowseUI.UpdateScanStatus()
        equal(view.summary.text, "0 priced / 0 items")
        equal(view.refreshButton.enabled, true)
    end)
end)

test("own scans display delivery resolution progress after reading auction rows", function()
    fixture(function(view)
        addon.BulkScan.engine = { job = { own = true, resolving = true, index = 6000, count = 6000 } }
        local original = addon.Discovery.Progress
        addon.Discovery.Progress = function()
            return 5, 180
        end
        local ok, err = pcall(function()
            addon.BrowseUI.UpdateScanStatus()
            equal(view.summary.text, "Descriptions 5/180")
            equal(view.refreshButton.text, "Stop")
        end)
        addon.Discovery.Progress = original
        assert(ok, err)
    end)
end)

test("detailed scans retain per-item progress and never overflow their item total", function()
    fixture(function(view)
        addon.scanner.bulkMode, addon.scanner.queue, addon.scanner.index = false, { 11, 12 }, 2
        addon.BrowseUI.Render(view)
        equal(view.summary.text, "Items 2/2")
        addon.scanner.index = 3
        addon.BrowseUI.UpdateScanStatus()
        equal(view.summary.text, "Items 2/2")
    end)
end)
