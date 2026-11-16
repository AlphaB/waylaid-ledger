local _, addon = ...

addon.Catalog = {}
local Catalog = addon.Catalog

function Catalog.Materials(crateIDs)
    local unique, result = {}, {}
    for _, crateID in ipairs(crateIDs) do
        local crate = addon.Crates[crateID]
        if crate then
            for _, option in ipairs(crate.options) do
                unique[option.itemID] = true
            end
        end
    end
    for itemID in pairs(unique) do
        result[#result + 1] = itemID
    end
    table.sort(result)
    return result
end

function Catalog.AllCrates()
    local result = {}
    for itemID in pairs(addon.Crates) do
        result[#result + 1] = itemID
    end
    table.sort(result)
    return result
end

function Catalog.BagCrates()
    local unique, result = {}, {}
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID and addon.Crates[itemID] then
                unique[itemID] = true
            end
        end
    end
    for itemID in pairs(unique) do
        result[#result + 1] = itemID
    end
    table.sort(result)
    return result
end

-- Every scan item is keyed by ID. Delivery options are alternatives for crates
-- and cumulative objectives for writs; both need all their quotes to compare.
function Catalog.AllContracts(kind)
    local ids = {}
    for _, definitions in ipairs({ addon.Crates, addon.Writs }) do
        for id in pairs(definitions) do
            if not kind or kind == "all" or (kind == "crates" and addon.Crates[id])
                or (kind == "writs" and addon.Writs[id]) then ids[#ids + 1] = id end
        end
    end
    table.sort(ids)
    return ids
end

function Catalog.ScanItems(contractIDs)
    local quantities, items = {}, {}
    for _, id in ipairs(contractIDs) do
        local contract = addon.Crates[id] or addon.Writs[id]
        if contract then
            quantities[id] = math.max(quantities[id] or 0, 1)
            for _, required in ipairs(contract.options or contract.requirements) do
                quantities[required.itemID] = math.max(quantities[required.itemID] or 0, required.quantity)
            end
        end
    end
    for id in pairs(quantities) do items[#items + 1] = id end
    table.sort(items)
    return items, quantities
end

function Catalog.BagContracts()
    local found, ids = {}, {}
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local id = C_Container.GetContainerItemID(bag, slot)
            if addon.Crates[id] or addon.Writs[id] then found[id] = true end
        end
    end
    for id in pairs(found) do ids[#ids + 1] = id end
    table.sort(ids)
    return ids
end

function Catalog.ItemName(itemID)
    return (C_Item and C_Item.GetItemNameByID(itemID))
        or addon.MaterialNames[itemID]
        or addon.WritMaterialNames[itemID]
        or (addon.Writs[itemID] and addon.Writs[itemID].name)
        or (addon.Crates[itemID] and addon.Crates[itemID].name)
        or ("Item " .. itemID)
end

function Catalog.SearchName(itemID)
    local name = C_Item and C_Item.GetItemNameByID(itemID)
    if name then
        return name
    end
    if C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
    end
    -- Discovery stores only names observed in this client locale/build. Unlike
    -- the old English catalog fallback these are valid localized search terms.
    local store = addon.Discovery and addon.Discovery.locale == GetLocale() and addon.Discovery.store
    local observed = store and store.names[itemID]
    if type(observed) == "string" and observed ~= "" then return observed end
    -- Shopping is name-based. An English display fallback is unsuitable for a
    -- localized auction search; wait for the client's name on other locales.
    local locale = GetLocale()
    if locale == "enUS" or locale == "enGB" then
        return addon.MaterialNames[itemID] or addon.WritMaterialNames[itemID]
            or (addon.Writs[itemID] and addon.Writs[itemID].name)
            or (addon.Crates[itemID] and addon.Crates[itemID].name)
    end
    return nil
end
