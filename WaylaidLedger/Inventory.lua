local _, addon = ...

-- Account SavedVariables are snapshots, not access to logged-out characters.
-- Only crate and catalog-material counts are recorded, never a full bag dump.
addon.Inventory = { bankOpen = false }
local Inventory = addon.Inventory

local function currentID()
    if UnitGUID then
        local guid = UnitGUID("player")
        if guid then return guid end
    end
    local name = UnitName and UnitName("player")
    return name and (name .. "-" .. (GetNormalizedRealmName() or GetRealmName())) or nil
end
Inventory.CurrentID = currentID

function Inventory.ReadContainers(bagIDs, requireLoaded)
    local items = {}
    for _, bagID in ipairs(bagIDs) do
        local slots = C_Container.GetContainerNumSlots(bagID)
        if requireLoaded and slots == 0 then
            return nil -- Do not overwrite a cached bank before its slots arrive.
        end
        for slot = 1, slots do
            local itemID = C_Container.GetContainerItemID(bagID, slot)
            if itemID and (addon.Crates[itemID] or addon.Writs[itemID] or addon.MaterialNames[itemID] or addon.WritMaterialNames[itemID]) then
                local info = C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(bagID, slot)
                items[itemID] = (items[itemID] or 0) + (info and info.stackCount or 1)
            end
        end
    end
    return items
end

local function characterRecord()
    local id = currentID()
    if not id then return nil end
    local records = addon.db.inventory.characters
    local record = records[id]
    if not record then
        record = { name = UnitName and UnitName("player") or id }
        records[id] = record
    end
    record.market = addon:MarketBaseKey()
    return record
end

function Inventory.CaptureBags()
    if not addon.db.tracking.enabled then return end
    local record = characterRecord()
    if not record then return end
    local bags = {}
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 do
        bags[#bags + 1] = bag
    end
    record.bags = { items = Inventory.ReadContainers(bags), seenAt = time() }
end

function Inventory.CaptureBank()
    if not Inventory.bankOpen or not addon.db.tracking.enabled or not addon.db.tracking.bank then return end
    if not C_Bank or not C_Bank.FetchPurchasedBankTabIDs or not C_Bank.CanViewBank
        or not Enum or not Enum.BankType then
        return -- Never guess container ranges: Forever has its own bank indices.
    end
    local record = characterRecord()
    if not record then return end
    for _, bankType in ipairs({ Enum.BankType.Character, Enum.BankType.Account }) do
        if C_Bank.CanViewBank(bankType) then
            local bagIDs = C_Bank.FetchPurchasedBankTabIDs(bankType)
            local items = Inventory.ReadContainers(bagIDs, true)
            if items then
                local snapshot = { items = items, seenAt = time() }
                if bankType == Enum.BankType.Character then
                    record.bank = snapshot
                else
                    -- Shared account bank is stored once, not once per alt.
                    addon.db.inventory.sharedBanks[addon:MarketBaseKey()] = snapshot
                end
            end
        end
    end
end

function Inventory.Totals()
    local result = { items = {}, crates = {}, characters = 0, banks = 0 }
    local settings = addon.db.tracking
    if not settings.enabled then return result end
    local market, id = addon:MarketBaseKey(), currentID()
    local function include(snapshot)
        if not snapshot then return end
        for itemID, count in pairs(snapshot.items) do
            result.items[itemID] = (result.items[itemID] or 0) + count
            if addon.Crates[itemID] then
                result.crates[itemID] = (result.crates[itemID] or 0) + count
            end
        end
    end
    for characterID, record in pairs(addon.db.inventory.characters) do
        if record.market == market and (characterID == id or settings.alts) then
            result.characters = result.characters + 1
            include(record.bags)
            if settings.bank and record.bank then
                result.banks = result.banks + 1
                include(record.bank)
            end
        end
    end
    if settings.bank then
        include(addon.db.inventory.sharedBanks[market])
    end
    return result
end

function Inventory.CrateIDs()
    if not addon.db.tracking.enabled then return addon.Catalog.BagCrates() end
    local result = {}
    for itemID in pairs(Inventory.Totals().crates) do result[#result + 1] = itemID end
    table.sort(result)
    return result
end

function Inventory.ContractIDs()
    if not addon.db.tracking.enabled then return addon.Catalog.BagContracts() end
    local ids = {}
    for id in pairs(Inventory.Totals().items) do
        if addon.Crates[id] or addon.Writs[id] then ids[#ids + 1] = id end
    end
    table.sort(ids)
    return ids
end

function Inventory.Report()
    local lines = { "--- Inventory snapshots (last seen, not live offline data) ---" }
    for id, record in pairs(addon.db.inventory.characters) do
        lines[#lines + 1] = string.format("%s (%s): market=%s bags=%s bank=%s", record.name, id,
            record.market, tostring(record.bags and record.bags.seenAt), tostring(record.bank and record.bank.seenAt))
    end
    for market, bank in pairs(addon.db.inventory.sharedBanks) do
        lines[#lines + 1] = "Shared bank " .. market .. ": " .. bank.seenAt
    end
    return table.concat(lines, "\n")
end
