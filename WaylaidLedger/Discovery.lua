local _, addon = ...

-- Requirements are learned from the client's item descriptions, never a web
-- catalog. Indexes contain localized names observed in bags, tooltips or the AH.
addon.Discovery = { names = {}, pending = {}, candidates = {} }
local Discovery = addon.Discovery

local function text(value)
    if issecretvalue and issecretvalue(value) then return nil end
    if type(value) ~= "string" then return nil end
    return value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", "")
        :gsub("\194\160", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function kindOf(name)
    if name:match("^Waylaid Crate:%s*%S") then return "crates" end
    if name:match("^Craftsman's Writ:%s*%S") then return "writs" end
end

function Discovery.Observe(itemID, name)
    if type(itemID) ~= "number" or itemID <= 0 then return end
    name = text(name or (C_Item and C_Item.GetItemNameByID(itemID)))
    if not name or name == "" then
        if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID) end
        return
    end
    local previous = Discovery.names[name]
    -- Never guess between distinct items that have the same localized name.
    Discovery.names[name] = previous == nil and itemID or (previous == itemID and itemID or false)
    if Discovery.store then Discovery.store.names[itemID] = name end
    local kind = kindOf(name)
    if kind then
        local definitions = kind == "crates" and addon.Crates or addon.Writs
        definitions[itemID] = definitions[itemID] or { name = name, unresolved = true,
            [kind == "crates" and "options" or "requirements"] = {} }
        definitions[itemID].name = name
        Discovery.candidates[itemID] = kind
        Discovery.pending[itemID] = true
    end
end

local function cleanName(name)
    return text(name):gsub("[%.;]$", ""):gsub("^%[", ""):gsub("%]$", "")
end

local function resolve(name, linkID)
    name = cleanName(name)
    if linkID then
        local actual = C_Item and C_Item.GetItemNameByID(linkID)
        if actual then Discovery.Observe(linkID, actual) end
        return linkID
    end
    -- Strip display brackets and sentence punctuation, not apostrophes in names.
    return Discovery.names[name] or nil
end

-- Accept explicit list entries and delivery sentences. Item names are resolved
-- exactly; partial/missing objectives invalidate the entire definition.
function Discovery.Parse(lines, kind, ownID)
    local result, seen = {}, {}
    for _, raw in ipairs(lines or {}) do
        local source = type(raw) == "table" and raw.leftText or raw
        local linked = {}
        -- Hyperlinks provide authoritative IDs even before the AH name index exists.
        if type(source) == "string" and not (issecretvalue and issecretvalue(source)) then
            for id, label in source:gmatch("|Hitem:(%d+).-|h(.-)|h") do
                local name = cleanName(label)
                id = tonumber(id)
                local previous = linked[name]
                linked[name] = previous == nil and id or (previous == id and id or false)
                Discovery.Observe(id, name)
            end
        end
        local value = text(source)
        if value then
            for line in (value .. "\n"):gmatch("([^\n]*)\n") do
                line = line:gsub("^%s+", ""):gsub("%s+$", "")
                local lower = line:lower()
                local body = line:match("^%-%s*(.+)") or line:match("^•%s*(.+)")
                if not body and not lower:match("^use:") and not lower:match("reward") then
                    local start = lower:find("deliver%s+") or lower:find("bring%s+")
                        or lower:find("requires?[:%s]+%d")
                    if start then
                        local clause = line:sub(start)
                        body = clause:match("^[^%s:]+[:%s]+(.+)")
                        -- These suffixes describe the recipient, not the item.
                        if body then body = body:gsub("%s+to%s+.+$", "") end
                    end
                end
                if body then
                    local quantity, name = body:match("^(%d+)%s*[xX]?%s+(.+)$")
                    if not quantity then name, quantity = body:match("^(.+)%s+[xX]%s*(%d+)[%.;]?$" ) end
                    if quantity then
                        quantity = tonumber(quantity)
                        local linkID = linked[cleanName(name)]
                        local itemID = resolve(name, linkID)
                        if not itemID or itemID == ownID or quantity <= 0 or quantity > 1000 or seen[itemID] then
                            return nil, "Unresolved or ambiguous delivery: " .. body
                        end
                        seen[itemID] = true
                        result[#result + 1] = { itemID = itemID, quantity = quantity }
                    elseif body:match("%d") or line:match("^%-") or line:match("^•") then
                        return nil, "Unrecognized delivery: " .. body
                    end
                end
            end
        end
    end
    if #result == 0 then return nil, "Delivery description is not loaded or its format is unsupported." end
    if kind == "crates" and #result < 2 then return nil, "Incomplete crate alternatives." end
    return result
end

function Discovery.Read(itemID, data)
    local kind = Discovery.candidates[itemID]
    if not kind then return false end
    if not data and C_TooltipInfo and C_TooltipInfo.GetItemByID then
        data = C_TooltipInfo.GetItemByID(itemID)
    end
    if not data then
        if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID) end
        return false
    end
    local definitions = kind == "crates" and addon.Crates or addon.Writs
    local definition = definitions[itemID]
    local requirements, reason = Discovery.Parse(data.lines, kind, itemID)
    if not requirements then
        Discovery.pending[itemID] = true
        definition.unresolved, definition.reason = true, reason
        -- A changed, incomplete live description must not retain old quantities.
        definition[kind == "crates" and "options" or "requirements"] = {}
        definition[kind == "crates" and "requirements" or "options"] = nil
        return false
    end
    definition[kind == "crates" and "options" or "requirements"] = requirements
    definition[kind == "crates" and "requirements" or "options"] = nil
    definition.unresolved, definition.reason = nil, nil
    definition.learnedAt, definition.build = time(), select(4, GetBuildInfo())
    for _, requirement in ipairs(requirements) do
        local name = Discovery.store and Discovery.store.names[requirement.itemID]
        if name then
            local names = kind == "crates" and addon.MaterialNames or addon.WritMaterialNames
            names[requirement.itemID] = name
        end
    end
    Discovery.pending[itemID] = nil
    return true
end

function Discovery.Retry(limit)
    local ids = {}
    for itemID in pairs(Discovery.pending) do ids[#ids + 1] = itemID end
    table.sort(ids)
    local learned = 0
    for index = 1, math.min(#ids, limit or #ids) do
        if Discovery.Read(ids[index]) then learned = learned + 1 end
    end
    return learned
end

function Discovery.Bags()
    if not C_Container then return end
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID then Discovery.Observe(itemID) end
        end
    end
    Discovery.Retry()
end

function Discovery.Install()
    local locale, build = GetLocale(), select(4, GetBuildInfo())
    addon.db.discovery = addon.db.discovery or { locales = {} }
    local root = addon.db.discovery
    root.locales = root.locales or {}
    local store = root.locales[locale]
    if not store or store.build ~= build then
        store = { build = build, names = {}, crates = {}, writs = {} }
        root.locales[locale] = store
    end
    Discovery.store = store
    -- Keep stable table references for the UI and inventory modules.
    for itemID, definition in pairs(store.crates) do addon.Crates[itemID] = definition end
    for itemID, definition in pairs(store.writs) do addon.Writs[itemID] = definition end
    store.crates, store.writs = addon.Crates, addon.Writs
    for itemID, name in pairs(store.names) do Discovery.Observe(itemID, name) end
    Discovery.Bags()
    local frame = CreateFrame("Frame")
    Discovery.frame = frame
    for _, event in ipairs({"ITEM_DATA_LOAD_RESULT", "TOOLTIP_DATA_UPDATE", "BAG_UPDATE_DELAYED",
        "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", "AUCTION_HOUSE_BROWSE_RESULTS_ADDED"}) do frame:RegisterEvent(event) end
    frame:SetScript("OnEvent", function(_, event, itemID, success)
        local touched = false
        if event == "ITEM_DATA_LOAD_RESULT" then
            if not success then return end
            Discovery.Observe(itemID)
            touched = Discovery.candidates[itemID] ~= nil
        elseif event == "BAG_UPDATE_DELAYED" then
            Discovery.Bags()
            touched = true
        elseif event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" or event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
            if C_AuctionHouse and C_AuctionHouse.GetBrowseResults then
                for _, row in ipairs(C_AuctionHouse.GetBrowseResults() or {}) do
                    if row.itemKey then Discovery.Observe(row.itemKey.itemID) end
                end
            end
        end
        if Discovery.Retry() > 0 or touched then
            if addon.UI then addon.UI.Update() end
            if addon.Tooltip then addon.Tooltip.Refresh() end
        end
    end)
end
