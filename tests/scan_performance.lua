-- Synthetic stress benchmark: run with scan_performance.py. Timings describe
-- Lua work in this harness, not WoW client FPS or native API costs.
local frames, now = {}, 0
GetTime = function()
    return now
end
GetLocale = function()
    return "enUS"
end
GetBuildInfo = function()
    return "1", "2", "3", 16001
end
time = function()
    return 1000 + now
end
CreateFrame = function()
    local frame = { scripts = {} }
    function frame:SetScript(key, fn)
        self.scripts[key] = fn
    end
    function frame:RegisterEvent() end
    frames[#frames + 1] = frame
    return frame
end
hooksecurefunc = function(object, key, fn)
    local original = object[key]
    object[key] = function(...)
        original(...)
        fn(...)
    end
end
C_Item = { RequestLoadItemDataByID = function() end }
C_TooltipInfo = {
    GetItemByID = function(id)
        if id == 21 then
            return { lines = { { leftText = "Deliver 20 Test Herb" } } }
        end
    end,
}
local market = { items = {}, failures = {} }
local addon = {
    db = { maxAge = 1800, markets = { test = market } },
    Crates = {},
    Writs = {},
    MaterialNames = {},
    WritMaterialNames = {},
}
function addon:GetMarket()
    return market
end
for _, name in ipairs({ "Localization", "DiscoveryLocales", "Discovery", "Scanner", "BulkScan" }) do
    assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/" .. name .. ".lua"))("WaylaidLedger", addon)
end
addon.Discovery.Install()
local rowCount = 100000
local api = {
    IsThrottledMessageSystemReady = function()
        return true
    end,
    ReplicateItems = function() end,
    GetNumReplicateItems = function()
        return rowCount
    end,
    GetReplicateItemInfo = function(index)
        local id = 1000 + index % 20000
        local name = "Unrelated auction item " .. id
        if index % 20000 == 0 then
            id, name = 21, "Craftsman's Writ: Test"
        end
        if index % 20000 == 1 then
            id, name = 11, "Test Herb"
        end
        return name, nil, 10, 1, nil, 1, nil, 1, 1, 100, nil, nil, nil, nil, nil, 0, id, true
    end,
}
local scanner = addon.Scanner.New(api, { now = GetTime, wallTime = time }, {})
scanner:SetOpen(true)
addon.BulkScan.Install(scanner)
local function size(t)
    local n = 0
    for _ in pairs(t) do
        n = n + 1
    end
    return n
end
local function pump()
    local active = false
    now = now + 1 / 60
    for _, frame in ipairs(frames) do
        if frame.scripts.OnUpdate then
            frame.scripts.OnUpdate()
            active = true
        end
    end
    return active
end
collectgarbage("collect")
local baseline = collectgarbage("count")
local peak, elapsed = baseline, 0
for _ = 1, 3 do
    now = now + 901
    local started = os.clock()
    assert(scanner:Start({}))
    local frame = addon.BulkScan.engine.frame
    frame.scripts.OnEvent(frame, "REPLICATE_ITEM_LIST_UPDATE")
    local ticks = 0
    while pump() do
        ticks = ticks + 1
        assert(ticks < 10000, "scan did not finish")
        peak = math.max(peak, collectgarbage("count"))
    end
    elapsed = elapsed + os.clock() - started
end
collectgarbage("collect")
local retained = collectgarbage("count") - baseline
print(
    string.format(
        "3 x %d auctions: CPU %.3fs; peak growth %.0f KiB; retained growth %.0f KiB; saved prices %d; saved names %d",
        rowCount,
        elapsed,
        peak - baseline,
        retained,
        size(market.items),
        size(addon.Discovery.store.names)
    )
)
assert(addon.Writs[21].requirements[1].itemID == 11)
assert(market.items[11].unitPrice == 10)
if VERIFY_BOUNDS then
    assert(size(market.items) == 2, "unrelated prices were retained")
    assert(size(addon.Discovery.store.names) == 2, "unrelated names were retained")
    assert(retained < 512, "scan memory did not return near baseline")
end
