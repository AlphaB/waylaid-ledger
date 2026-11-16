local _, addon = ...

-- Complete client descriptions update the bundled delivery fallback. Indexes
-- contain localized names observed in bags, tooltips or the auction house.
addon.Discovery = { names = {}, pending = {}, candidates = {} }
local Discovery = addon.Discovery
local BATCH, BUDGET_MS = 5, 2
local queue, queued, cursor = {}, {}, 1
local retryRequested, dirty = false, false
local reading, tooltipItems, itemTooltips = {}, {}, {}
local process

local function wake()
    if Discovery.frame then Discovery.frame:SetScript("OnUpdate", process) end
end

local function enqueue(itemID)
    if not queued[itemID] then
        queue[#queue + 1], queued[itemID] = itemID, true
    end
    wake()
end

local function text(value)
    if issecretvalue and issecretvalue(value) then return nil end
    if type(value) ~= "string" then return nil end
    return value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub("|cn[%w_]+:", ""):gsub("|n", "\n")
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
        return false
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
    return previous == nil or (previous ~= false and previous ~= itemID)
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
            -- The crate's spell description can contain its entire list in one
            -- tooltip line, with named colors and inline bullets.
            if kind == "crates" and value:lower():find("fill the crate with", 1, true) then
                value = value:gsub("^.-[Ll]ist:%s*", "")
                value = value:gsub("%s+%-%s+", "\n- "):gsub("%s+•%s*", "\n• ")
            end
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
    if not kind or reading[itemID] then return false end
    reading[itemID] = true
    if not data and C_TooltipInfo and C_TooltipInfo.GetItemByID then
        data = C_TooltipInfo.GetItemByID(itemID)
    end
    local oldInstance = itemTooltips[itemID]
    if oldInstance then tooltipItems[oldInstance] = nil end
    local instance = data and data.dataInstanceID
    if instance and not (issecretvalue and issecretvalue(instance)) then
        tooltipItems[instance], itemTooltips[itemID] = itemID, instance
    else
        itemTooltips[itemID] = nil
    end
    if not data then
        if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID) end
        reading[itemID] = nil
        return false
    end
    local definitions = kind == "crates" and addon.Crates or addon.Writs
    local definition = definitions[itemID]
    local requirements, reason = Discovery.Parse(data.lines, kind, itemID)
    reading[itemID] = nil
    if not requirements then
        -- Loading text and generic writ flavor text contain no objectives.
        -- Their absence cannot disprove a known bundle. Explicit invalid or
        -- partial objectives still invalidate it below.
        local known = definition[kind == "crates" and "options" or "requirements"]
        if reason == "Delivery description is not loaded or its format is unsupported."
            and not definition.unresolved and known and #known > 0 then
            Discovery.pending[itemID] = nil
            return false
        end
        Discovery.pending[itemID] = true
        definition.unresolved, definition.reason = true, reason
        -- A changed, incomplete live description must not retain old quantities.
        definition[kind == "crates" and "options" or "requirements"] = {}
        definition[kind == "crates" and "requirements" or "options"] = nil
        return false
    end
    definition[kind == "crates" and "options" or "requirements"] = requirements
    definition[kind == "crates" and "requirements" or "options"] = nil
    definition.unresolved, definition.reason, definition.fallback = nil, nil, nil
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

-- Events only request work. A full scan can load thousands of unrelated items;
-- never parse the entire pending catalog inside each item/tooltip callback.
function Discovery.Retry()
    retryRequested = true
    wake()
end

process = function()
    -- Plain-name requirements need the complete market name index first.
    if addon.BulkScan and addon.BulkScan.engine and addon.BulkScan.engine.job then return end
    if retryRequested then
        retryRequested = false
        for itemID in pairs(Discovery.pending) do enqueue(itemID) end
    end
    local started = debugprofilestop and debugprofilestop()
    local attempts = 0
    while cursor <= #queue and attempts < BATCH do
        local itemID = queue[cursor]
        cursor = cursor + 1
        if Discovery.pending[itemID] then
            Discovery.Read(itemID)
            dirty = true
            attempts = attempts + 1
        end
        queued[itemID] = nil
        if started and debugprofilestop() - started >= BUDGET_MS then break end
    end
    if cursor <= #queue or retryRequested then return end
    queue, queued, cursor = {}, {}, 1
    Discovery.frame:SetScript("OnUpdate", nil)
    -- One redraw per wave, including invalidated definitions. Failed parses stay
    -- pending but sleep until new item data, names or a later scan arrive.
    if dirty then
        dirty = false
        if addon.UI then addon.UI.Update() end
        if addon.Tooltip then addon.Tooltip.Refresh() end
    end
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
    for _, pair in ipairs({{store.crates, addon.Crates}, {store.writs, addon.Writs}}) do
        for itemID, definition in pairs(pair[1]) do
            -- Recover known rows invalidated by the discovery-only release.
            if not definition.unresolved or not pair[2][itemID] then pair[2][itemID] = definition end
        end
    end
    store.crates, store.writs = addon.Crates, addon.Writs
    for itemID, name in pairs(store.names) do Discovery.Observe(itemID, name) end
    local english = locale == "enUS" or locale == "enGB"
    for _, names in ipairs({addon.MaterialNames, addon.WritMaterialNames}) do
        for itemID, name in pairs(names) do Discovery.Observe(itemID, english and name or nil) end
    end
    for _, definitions in ipairs({addon.Crates, addon.Writs}) do
        for itemID, definition in pairs(definitions) do
            Discovery.Observe(itemID, english and definition.name or nil)
        end
    end
    Discovery.Bags()
    local frame = CreateFrame("Frame")
    Discovery.frame = frame
    if retryRequested then wake() end
    for _, event in ipairs({"ITEM_DATA_LOAD_RESULT", "TOOLTIP_DATA_UPDATE", "BAG_UPDATE_DELAYED",
        "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", "AUCTION_HOUSE_BROWSE_RESULTS_ADDED"}) do frame:RegisterEvent(event) end
    frame:SetScript("OnEvent", function(_, event, itemID, success)
        if event == "ITEM_DATA_LOAD_RESULT" then
            if not success then return end
            local changed = Discovery.Observe(itemID)
            if Discovery.candidates[itemID] then
                enqueue(itemID)
            elseif changed then
                Discovery.Retry()
            end
        elseif event == "TOOLTIP_DATA_UPDATE" then
            if issecretvalue and issecretvalue(itemID) then return end
            -- This event carries a tooltip instance ID, not an item ID.
            local candidate = tooltipItems[itemID]
            if not candidate or reading[candidate] then return end
            Discovery.pending[candidate] = true
            enqueue(candidate)
        elseif event == "BAG_UPDATE_DELAYED" then
            Discovery.Bags()
        elseif event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" or event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
            if C_AuctionHouse and C_AuctionHouse.GetBrowseResults then
                for _, row in ipairs(C_AuctionHouse.GetBrowseResults() or {}) do
                    if row.itemKey then Discovery.Observe(row.itemKey.itemID) end
                end
            end
            Discovery.Retry()
        end
    end)
end
