local addon, test, equal = ...

local function fixture(action)
    local oldScanner, oldEngine = addon.scanner, addon.BulkScan.engine
    local parent = CreateFrame("Frame", nil, UIParent)
    parent:SetSize(1000, 550)
    local oldViews = addon.BrowseUI.views
    addon.BrowseUI.views = {}
    local view = addon.BrowseUI.Create(parent, "crates")
    view.entries = {}
    addon.scanner = { active = true, bulkMode = true, index = 1, queue = {} }
    addon.BulkScan.engine = nil
    local ok, err = pcall(action, view)
    addon.scanner, addon.BulkScan.engine, addon.BrowseUI.views = oldScanner, oldEngine, oldViews
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

test("shared snapshots show progress while the own scanner is idle and restore list counts", function()
    fixture(function(view)
        addon.scanner.active = false
        addon.BulkScan.engine = { job = { own = false } }
        addon.BrowseUI.Render(view)
        equal(view.summary.text, "Shared scan: waiting")
        equal(view.refreshButton.text, "Stop")
        addon.BulkScan.engine.job = { own = false, received = true, index = 500, count = 12000 }
        addon.BrowseUI.UpdateScanStatus()
        equal(view.summary.text, "Auctions 500/12000")
        addon.BulkScan.engine.job = nil
        addon.BrowseUI.UpdateScanStatus()
        equal(view.summary.text, "0 priced / 0 items")
        equal(view.refreshButton.text, "Refresh")
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
