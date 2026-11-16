-- Exercise the work after ScanComplete, with the shipped catalog and persisted
-- detailed prices. The earlier scan benchmark stopped while Ledger was paused.
local now, frames = 4000, {}
GetTime = function()
    return now
end
time = GetTime
GetLocale = function()
    return "enUS"
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
local addon = {}
for _, name in ipairs({
    "Localization",
    "Locales",
    "Data",
    "WritData",
    "Rewards",
    "Catalog",
    "Pricing",
    "Providers",
    "WritPricing",
    "Shopping",
    "UI",
    "Core",
}) do
    assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/" .. name .. ".lua"))("WaylaidLedger", addon)
end
addon.db = { source = "auto", writSource = "auto", profile = "default", tsmKey = "DBMinBuyout", maxAge = 1800 }
addon.scanner = { active = false }
function addon:MarketKey()
    return "test"
end
local market = { items = {}, failures = {} }
function addon:GetMarket()
    return market
end
local offers = {}
for index = 1, 20000 do
    offers[index] = { quantity = 1 + index % 5, buyoutAmount = 10 + index % 7 }
end
for _, definitions in ipairs({ addon.Crates, addon.Writs }) do
    for id, definition in pairs(definitions) do
        market.items[id] = { kind = "estimate", unitPrice = 100, scannedAt = 1 }
        for _, requirement in ipairs(definition.options or definition.requirements) do
            market.items[requirement.itemID] = { kind = "item", offers = offers, scannedAt = 1 }
        end
    end
end
local listeners, refreshes, discarded = {}, 0, 0
Auctionator = {
    API = {
        v1 = {
            GetAuctionPriceByItemID = function()
                return 7
            end,
            GetAuctionAgeByItemID = function()
                return 0
            end,
            RegisterForDBUpdate = function() end,
        },
    },
    FullScan = {
        Events = { ScanStart = "start", ScanProgress = "progress", ScanComplete = "complete", ScanFailed = "failed" },
    },
    EventBus = {
        Register = function(_, listener, events)
            for _, event in ipairs(events) do
                listeners[event] = listener
            end
        end,
    },
}
local quote = addon.Pricing.Quote
addon.Pricing.Quote = function(snapshot, required)
    if snapshot and snapshot.kind == "item" then
        discarded = discarded + 1
    end
    return quote(snapshot, required)
end
local function reprice()
    for _, kind in ipairs({ "writs", "crates" }) do
        local entries = addon.Shopping.Entries(kind)
        assert(#entries == (kind == "writs" and 150 or 30))
        for _, entry in ipairs(entries) do
            assert(entry.purchase == 7 and entry.total and not entry.stale)
            for _, row in ipairs(entry.deliveryRows) do
                assert(row.source == "auctionator")
            end
        end
    end
    refreshes = refreshes + 1
end
addon.BrowseUI = { UpdateScanStatus = function() end, UpdateVisible = reprice }
addon.UI.UpdateSettings = function() end
addon.Providers.Install()
listeners.start:ReceiveEvent("start")
addon.UI.Update()
assert(refreshes == 0)
local started = os.clock()
listeners.complete:ReceiveEvent("complete", {})
now = now + 0.3
for _, frame in ipairs(frames) do
    if frame.scripts.OnUpdate then
        frame.scripts.OnUpdate()
    end
end
assert(refreshes == 1)
print(
    string.format(
        "Auctionator completion: CPU %.3fs; discarded detailed quotes %d; refreshed catalog rows 180",
        os.clock() - started,
        discarded
    )
)
if VERIFY_BOUNDS then
    assert(discarded == 0, "completion priced stale order books before discarding them")
end
