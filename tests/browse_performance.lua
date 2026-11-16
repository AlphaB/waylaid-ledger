-- Real discovery callbacks without Auctionator FullScan/Shopping lifecycle
-- events, as seen in the user's SendBrowseQuery/database-update trace.
local now = 0
GetTime = function()
    return now
end
time = GetTime
GetLocale = function()
    return "enUS"
end
GetBuildInfo = function()
    return "1", "2", "3", 16001
end
CreateFrame = function()
    local frame = { scripts = {} }
    function frame:SetScript(key, fn)
        self.scripts[key] = fn
    end
    function frame:RegisterEvent() end
    function frame:UnregisterEvent() end
    return frame
end
local names, rows, nameReads, descriptions, snapshots = {}, {}, 0, 0, 0
C_Item = {
    GetItemNameByID = function(id)
        nameReads = nameReads + 1
        return names[id]
    end,
}
C_TooltipInfo = {
    GetItemByID = function()
        descriptions = descriptions + 1
        return { lines = { { leftText = "Deliver 3 Herb" } } }
    end,
}
C_AuctionHouse = {
    GetBrowseResults = function()
        snapshots = snapshots + 1
        return rows
    end,
}
local addon = { db = {}, Crates = {}, Writs = {}, MaterialNames = {}, WritMaterialNames = {} }
for _, module in ipairs({ "Localization", "DiscoveryLocales", "Discovery" }) do
    assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/" .. module .. ".lua"))("WaylaidLedger", addon)
end
addon.Discovery.Install()
addon.Discovery.Observe(11, "Herb")
for id = 100, 6099 do
    names[id] = id < 250 and "Craftsman's Writ: Test " .. id or "Other item " .. id
    rows[#rows + 1] = { itemKey = { itemID = id } }
end
local frame, immediateReads, maxReads = addon.Discovery.frame, 0, 0
local started = os.clock()
for _ = 1, 20 do
    local before = nameReads + snapshots
    frame.scripts.OnEvent(frame, "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
    immediateReads = immediateReads + nameReads + snapshots - before
    local ticks = 0
    while frame.scripts.OnUpdate do
        now = now + 0.3
        before = nameReads
        frame.scripts.OnUpdate()
        maxReads = math.max(maxReads, nameReads - before)
        ticks = ticks + 1
        assert(ticks < 1000, "browse discovery did not settle")
    end
end
print(
    string.format(
        "20 x 6000 browse rows: CPU %.3fs; immediate native reads %d; total name reads %d; descriptions %d; max name reads/frame %d",
        os.clock() - started,
        immediateReads,
        nameReads,
        descriptions,
        maxReads
    )
)
if VERIFY_BOUNDS then
    assert(immediateReads == 0, "browse callback synchronously read the native snapshot")
    assert(nameReads == 6000, "unchanged browse names were repeatedly queried")
    assert(descriptions == 150, "unchanged browse results repeatedly reparsed contracts")
    assert(maxReads <= 50, "browse work was not bounded per frame")
end
