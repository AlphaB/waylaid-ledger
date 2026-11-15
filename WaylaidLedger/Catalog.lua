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
