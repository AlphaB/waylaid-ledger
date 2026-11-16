local _, addon = ...

-- Optional-addon adapters use only the released public APIs. Provider values
-- are estimates, never fabricated order-book snapshots or exact scan times.
addon.Providers = { cache = {}, errors = {}, boundAPI = nil }
local Providers = addon.Providers
local CALLER = "WaylaidLedger"
local CACHE_SECONDS = 15
local MAX_UNIT_PRICE = 9007199254740 -- Keep even a 1000-unit bundle within exact integer range.

local function auctionatorAPI()
    return type(Auctionator) == "table" and type(Auctionator.API) == "table"
        and type(Auctionator.API.v1) == "table" and Auctionator.API.v1 or nil
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
    return api ~= nil and (type(api.MultiSearchAdvanced) == "function"
        or (not requireTabSwitch and type(api.ConvertToSearchString) == "function" and type(api.CreateShoppingList) == "function"))
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
        value = { source = source, unitPrice = price, estimated = true,
            sourceLabel = source == "auctionator" and "Auctionator"
                or (addon.db.tsmKey == "DBMarket" and "TSM market" or "TSM min buyout") }
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
    return value
end

function Providers.Install()
    local api = auctionatorAPI()
    if api and Providers.boundAPI ~= api and type(api.RegisterForDBUpdate) == "function" then
        local ok, errorMessage = pcall(api.RegisterForDBUpdate, CALLER, function()
            Providers.Invalidate()
            if addon.Discovery then addon.Discovery.Retry() end
            if addon.Tooltip then
                addon.Tooltip.Refresh()
            end
            if addon.UI then
                addon.UI.Update()
            end
        end)
        if ok then
            Providers.boundAPI = api
        else
            Providers.errors.auctionator = "Update callback: " .. tostring(errorMessage)
        end
    end
end

function Providers.Search(terms, listName, requireTabSwitch)
    local api = auctionatorAPI()
    if not Providers.ShoppingAvailable(requireTabSwitch) then
        return false, "Auctionator's shopping API is unavailable. Install/enable a compatible Auctionator release."
    end
    local ok, errorMessage
    if type(api.MultiSearchAdvanced) == "function" then
        ok, errorMessage = pcall(api.MultiSearchAdvanced, CALLER, terms)
    else
        local strings = {}
        for _, term in ipairs(terms) do
            local converted, searchString = pcall(api.ConvertToSearchString, CALLER, term)
            if not converted or type(searchString) ~= "string" then
                return false, "Auctionator could not convert the search: " .. tostring(searchString)
            end
            strings[#strings + 1] = searchString
        end
        ok, errorMessage = pcall(api.CreateShoppingList, CALLER, listName, strings)
    end
    if not ok then
        Providers.errors.auctionator = "Shopping: " .. tostring(errorMessage)
        return false, "Auctionator could not start the search: " .. tostring(errorMessage)
    end
    return true
end

-- This public API opens Auctionator Shopping and starts an exact-item search.
-- It is a limited scan handoff, not a silent/full-database scan or a purchase.
function Providers.ScanTerms(items, quantities)
    local terms = {}
    for _, id in ipairs(items) do
        local name = addon.Catalog.SearchName(id)
        if not name then return nil, "Item names are loading; retry the Auctionator scan shortly." end
        terms[#terms + 1] = { searchString = name, categoryKey = "", isExact = true, quantity = quantities[id] or 1 }
    end
    if #terms == 0 then return nil, "No matching items to scan." end
    return terms
end

function Providers.ScanItems(items, quantities)
    local terms, reason = Providers.ScanTerms(items, quantities)
    if not terms then return false, reason end
    return Providers.Search(terms, "Waylaid Ledger - scoped refresh", true)
end
