local _, addon = ...

-- Complete acquisition baskets share the same source policy for the contract
-- purchase and finished delivery goods, including quantity-aware own scans.
addon.Shopping = {}
local Shopping = addon.Shopping

local function purchaseQuote(kind, itemID)
    local mode = kind == "writs" and addon.db.writSource or addon.db.source
    if mode == "off" then
        return nil
    end
    return addon:ResolveRows({ { itemID = itemID, quantity = 1 } }, mode)[1]
end

function Shopping.Entry(kind, itemID)
    local definition = kind == "writs" and addon.Writs[itemID] or (kind == "crates" and addon.Crates[itemID])
    if not definition then
        return nil
    end
    local entry =
        { kind = kind, itemID = itemID, name = addon.Catalog.ItemName(itemID), requirements = {}, deliveryRows = {} }
    entry.purchaseQuote = purchaseQuote(kind, itemID)
    if entry.purchaseQuote and entry.purchaseQuote.status == "ok" then
        entry.purchase = entry.purchaseQuote.cost
        entry.stale = entry.purchaseQuote.stale or false
    end
    if definition.unresolved then
        entry.reason = definition.reason or "Delivery requirements unresolved. Run a full AH scan."
        entry.canShop = false
        return entry
    end
    if kind == "writs" then
        entry.deliveryRows, entry.delivery, entry.deliveryStale = addon.WritPricing.Rows(itemID)
        entry.requirements = definition.requirements
        if addon.db.writSource == "off" then
            entry.reason = "Writ prices are disabled in settings."
        end
    else
        local rows = addon:GetRows(itemID)
        local best, index = addon.Pricing.LowestKnown(rows)
        entry.deliveryRows = best and { best } or {}
        if best then
            entry.delivery, entry.deliveryStale, entry.optionIndex = best.cost, best.stale, index
            entry.requirements = { definition.options[index] }
        else
            entry.reason = "Scan crate materials or update Auctionator/TSM prices to choose a filling option."
        end
    end
    entry.stale = entry.stale or entry.deliveryStale or false
    if entry.purchase and entry.delivery then
        entry.total = entry.purchase + entry.delivery
    end
    entry.canShop = #entry.requirements > 0
    local mode = kind == "writs" and addon.db.writSource or addon.db.source
    if (mode == "auto" or mode == "own") and (not entry.purchaseQuote or entry.purchaseQuote.status ~= "ok") then
        local snapshot = addon:GetMarket().items[itemID]
        if snapshot and snapshot.kind == "estimate" then
            entry.purchaseQuote = addon.Pricing.Resolve(
                { options = { { itemID = itemID, quantity = 1 } } },
                { [itemID] = snapshot },
                time(),
                addon.db.maxAge,
                {},
                "own",
                function() end
            )[1]
            entry.purchase = entry.purchaseQuote.cost
            entry.stale = entry.stale or entry.purchaseQuote.stale
            if entry.delivery then
                entry.total = entry.purchase + entry.delivery
            end
        end
    end
    return entry
end

function Shopping.Less(left, right)
    if left.total ~= nil and right.total == nil then
        return true
    end
    if left.total == nil and right.total ~= nil then
        return false
    end
    if left.total ~= right.total then
        return left.total < right.total
    end
    if left.name ~= right.name then
        return left.name < right.name
    end
    return left.itemID < right.itemID
end

function Shopping.Entries(kind)
    local definitions = kind == "writs" and addon.Writs or addon.Crates
    local entries = {}
    for itemID in pairs(definitions) do
        entries[#entries + 1] = Shopping.Entry(kind, itemID)
    end
    table.sort(entries, Shopping.Less)
    return entries
end

function Shopping.DeliveryLabel(entry)
    local names = {}
    for _, requirement in ipairs(entry.requirements) do
        names[#names + 1] = requirement.quantity .. "x " .. addon.Catalog.ItemName(requirement.itemID)
    end
    return #names > 0 and table.concat(names, ", ") or "Delivery price unavailable"
end

function Shopping.Terms(entry)
    if not entry or not entry.canShop then
        return nil, entry and entry.reason or "Unknown item."
    end
    local requirements = { { itemID = entry.itemID, quantity = 1 } }
    for _, requirement in ipairs(entry.requirements) do
        requirements[#requirements + 1] = requirement
    end
    local terms = {}
    for _, requirement in ipairs(requirements) do
        local name = addon.Catalog.SearchName(requirement.itemID)
        if not name then
            return nil, "An item name is still loading. Try the search again in a moment."
        end
        terms[#terms + 1] = { searchString = name, categoryKey = "", isExact = true, quantity = requirement.quantity }
    end
    return terms
end
