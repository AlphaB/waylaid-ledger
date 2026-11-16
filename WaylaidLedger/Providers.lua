local _, addon = ...
local L = addon.L

-- Price and shopping adapters use released public APIs. Provider values
-- are estimates, never fabricated order-book snapshots or exact scan times.
addon.Providers = { cache = {}, errors = {}, boundAPI = nil }
local Providers = addon.Providers
local CALLER = "WaylaidLedger"
local CACHE_SECONDS = 15
local MAX_UNIT_PRICE = 9007199254740 -- Keep even a 1000-unit bundle within exact integer range.

local function trace(...)
    if addon.Trace then
        addon:Trace(...)
    end
end

local function auctionatorAPI()
    return type(Auctionator) == "table"
            and type(Auctionator.API) == "table"
            and type(Auctionator.API.v1) == "table"
            and Auctionator.API.v1
        or nil
end

local function tsmAPI()
    return type(TSM_API) == "table" and TSM_API or nil
end

function Providers.Available(source)
    local api = source == "auctionator" and auctionatorAPI() or (source == "tsm" and tsmAPI() or nil)
    local method = source == "auctionator" and "GetAuctionPriceByItemID" or "GetCustomPriceValue"
    return api ~= nil and type(api[method]) == "function"
end

function Providers.ShoppingAvailable(requireTabSwitch)
    local api = auctionatorAPI()
    return api ~= nil
        and (
            type(api.MultiSearchAdvanced) == "function"
            or (
                not requireTabSwitch
                and type(api.ConvertToSearchString) == "function"
                and type(api.CreateShoppingList) == "function"
            )
        )
end

function Providers.Invalidate()
    Providers.cache = {}
end

local function validPrice(price)
    return type(price) == "number" and price > 0 and price == price and price <= MAX_UNIT_PRICE
end

function Providers.Read(source, itemID)
    if not Providers.Available(source) then
        return nil
    end
    local api = source == "auctionator" and auctionatorAPI() or tsmAPI()
    local key = table.concat({ addon:MarketKey(), source, tostring(itemID), addon.db.tsmKey }, ":")
    local now = GetTime()
    local cached = Providers.cache[key]
    if cached and cached.api == api and now - cached.readAt < CACHE_SECONDS then
        return cached.value
    end

    local ok, price, reason
    if source == "auctionator" then
        ok, price = pcall(api.GetAuctionPriceByItemID, CALLER, itemID)
    else
        -- Base-item estimates for catalogued materials and finished writ goods.
        ok, price, reason = pcall(api.GetCustomPriceValue, addon.db.tsmKey, "i:" .. itemID)
    end
    local value
    if not ok then
        Providers.errors[source] = tostring(price)
    elseif validPrice(price) then
        Providers.errors[source] = nil
        value = {
            source = source,
            unitPrice = price,
            estimated = true,
            sourceLabel = source == "auctionator" and "Auctionator"
                or (addon.db.tsmKey == "DBMarket" and L["TSM market"] or L["TSM min buyout"]),
        }
        if source == "auctionator" and type(api.GetAuctionAgeByItemID) == "function" then
            local ageOK, days = pcall(api.GetAuctionAgeByItemID, CALLER, itemID)
            if ageOK and type(days) == "number" and days >= 0 and days < math.huge then
                value.ageDays = math.floor(days)
                value.stale = value.ageDays > 0
            elseif not ageOK then
                Providers.errors[source] = "Price age: " .. tostring(days)
            end
        end
        -- Reading TSM now says nothing about its underlying AuctionDB scan age.
    elseif reason then
        Providers.errors[source] = tostring(reason)
    elseif price ~= nil then
        Providers.errors[source] = "Invalid or non-positive price returned."
    end
    Providers.cache[key] = { api = api, readAt = now, value = value }
    if Providers.errors[source] then
        trace("provider.error", 5, "%s item=%d: %s", source, itemID, Providers.errors[source])
    end
    return value
end

local processUpdates
local function wake()
    if not Providers.frame then
        Providers.frame = CreateFrame("Frame")
    end
    Providers.frame:SetScript("OnUpdate", processUpdates)
end

function Providers.ScheduleRefresh()
    Providers.refreshAt = GetTime() + 0.25
    wake()
end

function Providers.BeginExternalScan(origin)
    if Providers.scan then
        return
    end
    Providers.scan = { updatedAt = GetTime(), startedAt = GetTime(), ignoredEvents = 0 }
    if addon.traceState then
        addon.traceState["auctionator.progress"] = nil
    end
    trace(
        "auctionator.start",
        0,
        "Detected via %s; ownActive=%s; own scans and description reads suspended",
        origin or "adapter",
        tostring(addon.scanner and addon.scanner.active == true)
    )
    addon.autoPaused, addon.autoDue, addon.autoReason = true, nil, nil
    addon.pendingProviderScan, addon.providerDue = nil, nil
    if addon.scanner and addon.scanner.active then
        addon:StopScan()
    end
    if addon.UpdateScheduler and addon.scanner then
        addon:UpdateScheduler()
    end
    if addon.Discovery and addon.Discovery.frame then
        addon.Discovery.frame:SetScript("OnUpdate", nil)
    end
    if addon.BrowseUI then
        addon.BrowseUI.UpdateScanStatus()
    end
    wake()
end

function Providers.EndExternalScan(reason)
    if not Providers.scan then
        return
    end
    local scan = Providers.scan
    trace(
        "auctionator.end",
        0,
        "%s; elapsed=%.1fs lastProgress=%s%% ignoredDiscoveryEvents=%d; retry descriptions and refresh cached prices",
        reason or "adapter ended",
        GetTime() - scan.startedAt,
        tostring(scan.percent or "unknown"),
        scan.ignoredEvents
    )
    Providers.scan = nil
    Providers.Invalidate()
    -- One retry after the item-data stream has settled, never an own AH query.
    if addon.Discovery then
        addon.Discovery.Retry(true)
    end
    if addon.BrowseUI then
        addon.BrowseUI.UpdateScanStatus()
    end
    Providers.ScheduleRefresh()
end

processUpdates = function()
    if Providers.scan then
        -- Compatibility fallback for missing completion/failure events. Never
        -- restart an automatic own scan when the external scan ends or times out.
        if GetTime() - Providers.scan.updatedAt > 120 then
            Providers.EndExternalScan("watchdog: no progress for 120 seconds (completion unconfirmed)")
        end
        return
    end
    if Providers.refreshAt and GetTime() < Providers.refreshAt then
        return
    end
    if addon.BulkScan and addon.BulkScan.engine and addon.BulkScan.engine.job then
        return
    end
    Providers.frame:SetScript("OnUpdate", nil)
    Providers.refreshAt = nil
    trace("provider.refresh", 2, "Applying deferred price/UI refresh")
    if addon.Tooltip then
        addon.Tooltip.Refresh()
    end
    if addon.UI then
        addon.UI.Update()
    end
end

function Providers.Install()
    local api = auctionatorAPI()
    if api and Providers.boundAPI ~= api and type(api.RegisterForDBUpdate) == "function" then
        local ok, errorMessage = pcall(api.RegisterForDBUpdate, CALLER, function()
            trace(
                "auctionator.database",
                5,
                "Price database updated; externalActive=%s",
                tostring(Providers.scan ~= nil)
            )
            Providers.Invalidate()
            -- Older Auctionator builds expose only the public DB callback.
            if not Providers.boundScanBus then
                Providers.EndExternalScan("database callback (no scan-event adapter)")
            end
            Providers.ScheduleRefresh()
        end)
        if ok then
            Providers.boundAPI = api
            trace("provider.adapter", 0, "Auctionator database callback registered")
        else
            Providers.errors.auctionator = "Update callback: " .. tostring(errorMessage)
            trace("provider.adapter", 0, "%s", Providers.errors.auctionator)
        end
    end
    -- Optional, guarded compatibility adapter: Auctionator's public DB callback
    -- has no progress payload. Its scan event bus supplies progress and failure
    -- without reading, copying or retaining the raw auction snapshot.
    local bus = type(Auctionator) == "table" and Auctionator.EventBus
    local fullScan = type(Auctionator) == "table" and Auctionator.FullScan
    local events = type(fullScan) == "table" and fullScan.Events
    if
        type(bus) ~= "table"
        or type(bus.Register) ~= "function"
        or type(events) ~= "table"
        or Providers.boundScanBus == bus
    then
        return
    end
    for _, key in ipairs({ "ScanStart", "ScanProgress", "ScanComplete", "ScanFailed" }) do
        if type(events[key]) ~= "string" then
            return
        end
    end
    local listener = {
        ReceiveEvent = function(_, event, progress)
            if event == events.ScanStart then
                Providers.BeginExternalScan("Auctionator ScanStart")
            elseif event == events.ScanProgress and Providers.scan then
                Providers.scan.updatedAt = GetTime()
                if type(progress) == "number" and progress == progress then
                    local percent = math.floor(math.max(0, math.min(1, progress)) * 100)
                    if percent ~= Providers.scan.percent then
                        Providers.scan.percent = percent
                        trace(
                            "auctionator.progress",
                            5,
                            "%d%%; elapsed=%.1fs ignoredDiscoveryEvents=%d",
                            percent,
                            GetTime() - Providers.scan.startedAt,
                            Providers.scan.ignoredEvents
                        )
                        if addon.BrowseUI then
                            addon.BrowseUI.UpdateScanStatus()
                        end
                    end
                end
            elseif event == events.ScanComplete or event == events.ScanFailed then
                Providers.EndExternalScan(event == events.ScanComplete and "ScanComplete" or "ScanFailed")
            end
        end,
    }
    local ok, errorMessage = pcall(
        bus.Register,
        bus,
        listener,
        { events.ScanStart, events.ScanProgress, events.ScanComplete, events.ScanFailed }
    )
    if ok then
        Providers.boundScanBus = bus
        trace("provider.adapter", 0, "Auctionator scan/progress events registered")
    else
        Providers.errors.auctionator = "Scan events: " .. tostring(errorMessage)
        trace("provider.adapter", 0, "%s", Providers.errors.auctionator)
    end
end

function Providers.Search(terms, listName, requireTabSwitch)
    local api = auctionatorAPI()
    if not Providers.ShoppingAvailable(requireTabSwitch) then
        return false, L["Auctionator's shopping API is unavailable. Install/enable a compatible Auctionator release."]
    end
    local ok, errorMessage
    if type(api.MultiSearchAdvanced) == "function" then
        ok, errorMessage = pcall(api.MultiSearchAdvanced, CALLER, terms)
    else
        local strings = {}
        for _, term in ipairs(terms) do
            local converted, searchString = pcall(api.ConvertToSearchString, CALLER, term)
            if not converted or type(searchString) ~= "string" then
                return false, string.format(L["Auctionator could not convert the search: %s"], tostring(searchString))
            end
            strings[#strings + 1] = searchString
        end
        ok, errorMessage = pcall(api.CreateShoppingList, CALLER, listName, strings)
    end
    if not ok then
        Providers.errors.auctionator = "Shopping: " .. tostring(errorMessage)
        return false, string.format(L["Auctionator could not start the search: %s"], tostring(errorMessage))
    end
    return true
end

-- This public API opens Auctionator Shopping and starts an exact-item search.
-- It is a limited scan handoff, not a silent/full-database scan or a purchase.
function Providers.ScanTerms(items, quantities)
    local terms = {}
    for _, id in ipairs(items) do
        local name = addon.Catalog.SearchName(id)
        if not name then
            return nil, L["Item names are loading; retry the Auctionator scan shortly."]
        end
        terms[#terms + 1] = { searchString = name, categoryKey = "", isExact = true, quantity = quantities[id] or 1 }
    end
    if #terms == 0 then
        return nil, L["No matching items to scan."]
    end
    return terms
end

function Providers.ScanItems(items, quantities)
    local terms, reason = Providers.ScanTerms(items, quantities)
    if not terms then
        return false, reason
    end
    return Providers.Search(terms, "Waylaid Ledger - scoped refresh", true)
end
