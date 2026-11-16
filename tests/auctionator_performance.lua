-- Synthetic external-scan traffic through production tooltip/UI/event adapters.
-- Input tables are reused; memory is allocation pressure with GC paused, not
-- WoW's per-addon memory attribution or retained SavedVariables size.
local now, frames = 0, {}
date = function()
    return "12:00:00"
end
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
GetTime = function()
    return now
end
time = function()
    return 1000 + now
end
GetLocale = function()
    return "enUS"
end
GetBuildInfo = function()
    return "1", "2", "3", 16001
end
local function frame()
    local f = { scripts = {}, events = {} }
    function f:SetScript(key, fn)
        self.scripts[key] = fn
    end
    function f:HookScript(key, fn)
        self.scripts[key] = fn
    end
    function f:RegisterEvent(event)
        self.events[event] = true
    end
    function f:UnregisterEvent(event)
        self.events[event] = nil
    end
    function f:IsShown()
        return true
    end
    function f:IsVisible()
        return true
    end
    function f:AddLine() end
    function f:AddDoubleLine() end
    frames[#frames + 1] = f
    return f
end
CreateFrame = frame
local names = { [21] = "Waylaid Crate: Test", [31] = "Craftsman's Writ: Test", [11] = "Herb", [12] = "Ore" }
C_Item = {
    GetItemNameByID = function(id)
        return names[id]
    end,
    RequestLoadItemDataByID = function() end,
}
C_TooltipInfo = {
    GetItemByID = function()
        return nil
    end,
}
TooltipDataProcessor = {
    AddTooltipPostCall = function(_, callback)
        TooltipDataProcessor.callback = callback
    end,
}
Enum = { TooltipDataType = { Item = 0 } }
local addon = {
    db = {
        debug = true,
        log = {},
        source = "auto",
        writSource = "auto",
        tsmKey = "DBMinBuyout",
        maxAge = 1800,
        markets = {},
    },
    Crates = {
        [21] = { name = names[21], options = { { itemID = 11, quantity = 20 }, { itemID = 12, quantity = 10 } } },
    },
    Writs = { [31] = { name = names[31], requirements = { { itemID = 11, quantity = 20 } } } },
    MaterialNames = { [11] = names[11], [12] = names[12] },
    WritMaterialNames = {},
    Inventory = {
        Totals = function()
            return { items = {} }
        end,
    },
    Catalog = {
        ItemName = function(id)
            return names[id]
        end,
    },
    scanner = { active = false, open = true },
}
for _, name in ipairs({
    "Localization",
    "Locales",
    "DiscoveryLocales",
    "Discovery",
    "Pricing",
    "Tooltip",
    "UI",
    "Providers",
    "WritPricing",
    "Core",
}) do
    assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/" .. name .. ".lua"))("WaylaidLedger", addon)
end
local quotes, menus, lists = 0, 0, 0
local offers = {}
for _ = 1, 20 do
    offers[#offers + 1] = { quantity = 2, buyoutAmount = 10 }
end
local snapshots = {
    [11] = { kind = "item", scannedAt = 1000, offers = offers },
    [12] = { kind = "item", scannedAt = 1000, offers = offers },
}
function addon:ResolveRows(options, source)
    quotes = quotes + 1
    return self.Pricing.Resolve({ options = options }, snapshots, time(), 1800, {}, source, function()
        return nil
    end)
end
function addon:GetRows(id)
    return self:ResolveRows(self.Crates[id].options, self.db.source)
end
local control = {
    GenerateMenu = function()
        menus = menus + 1
    end,
    SetEnabled = function() end,
}
addon.UI.settings = {
    IsShown = function()
        return false
    end,
    IsVisible = function()
        return false
    end,
}
addon.UI.settingsChecks = {}
addon.UI.crateSourceButton, addon.UI.writSourceButton, addon.UI.settingsTSM = control, control, control
addon.BrowseUI = {
    UpdateScanStatus = function() end,
    UpdateVisible = function()
        lists = lists + 1
    end,
}
local dbUpdate
local listeners = {}
Auctionator = {
    API = {
        v1 = {
            RegisterForDBUpdate = function(_, callback)
                dbUpdate = callback
            end,
        },
    },
    FullScan = {
        Events = { ScanStart = "start", ScanProgress = "progress", ScanComplete = "complete", ScanFailed = "failed" },
    },
    Shopping = {
        Tab = {
            Events = {
                SearchStart = "shopping start",
                SearchIncrementalUpdate = "shopping update",
                SearchEnd = "shopping end",
            },
        },
    },
    EventBus = {
        Register = function(_, listener, events)
            for _, event in ipairs(events) do
                listeners[event] = listener
            end
        end,
    },
}
addon.Discovery.Install()
addon.Tooltip.Install()
addon.Providers.Install()
local startEvent = SHOPPING_SCAN and "shopping start" or "start"
if listeners[startEvent] then
    listeners[startEvent]:ReceiveEvent(startEvent)
end
local tooltip, data = frame(), { id = 21 }
local discovery, deliveries = addon.Discovery.frame, 0
collectgarbage("collect")
local baseline = collectgarbage("count")
collectgarbage("stop")
local events = { "ITEM_DATA_LOAD_RESULT", "TOOLTIP_DATA_UPDATE" }
local started = os.clock()
for index = 1, 20000 do
    now = index / 1000
    for _, event in ipairs(events) do
        if discovery.events[event] then
            deliveries = deliveries + 1
            discovery.scripts.OnEvent(discovery, event, 21, true)
        end
    end
    if tooltip.scripts.OnTooltipCleared then
        tooltip.scripts.OnTooltipCleared(tooltip)
    end
    data.id = index % 2 == 0 and 21 or 31
    TooltipDataProcessor.callback(tooltip, data)
    if index % 100 == 0 then
        dbUpdate()
        addon.UI.Update()
    end
    if addon.Providers.frame and addon.Providers.frame.scripts.OnUpdate then
        addon.Providers.frame.scripts.OnUpdate()
    end
end
local elapsed, allocated = os.clock() - started, collectgarbage("count") - baseline
collectgarbage("restart")
collectgarbage("collect")
local retained = collectgarbage("count") - baseline
print(
    string.format(
        "Auctionator traffic: CPU %.3fs; allocated %.0f KiB; retained %.0f KiB; quotes %d; menus %d; list rebuilds %d; discovery callbacks %d",
        elapsed,
        allocated,
        retained,
        quotes,
        menus,
        lists,
        deliveries
    )
)
if VERIFY_BOUNDS then
    assert(quotes == 0, "tooltips repriced during an external scan")
    assert(menus == 0, "hidden settings menus rebuilt during an external scan")
    assert(lists == 0, "lists rebuilt during an external scan")
    assert(deliveries == 0, "discovery still subscribed to external event storms")
    assert(allocated < 128, "external scan generated excessive garbage")
    assert(retained < 128, "external scan retained unexpected data")
end
