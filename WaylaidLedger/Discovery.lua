local _, addon = ...

-- Complete client descriptions update the bundled delivery fallback. Indexes
-- contain localized names observed in bags, tooltips or the auction house.
addon.Discovery = { names = {}, pending = {}, candidates = {}, progress = 0 }
local Discovery = addon.Discovery
local Locales = addon.DiscoveryLocales
local BATCH, BUDGET_MS = 5, 2
local queue, queued, cursor = {}, {}, 1
local retryRequested, dirty = false, false
local waveDone, waveTotal = 0, 0
local requested = {}
local retryAt
local QUIET_SECONDS = 0.25
local EVENTS = {
    "ITEM_DATA_LOAD_RESULT",
    "TOOLTIP_DATA_UPDATE",
    "BAG_UPDATE_DELAYED",
    "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED",
    "AUCTION_HOUSE_BROWSE_RESULTS_ADDED",
}
local reading, tooltipItems, itemTooltips = {}, {}, {}
local neededNames = {}
local process

local function wake()
    if Discovery.frame and not Discovery.suspended then
        Discovery.frame:SetScript("OnUpdate", process)
    end
end

local function enqueue(itemID)
    if not queued[itemID] then
        if #queue == 0 then
            waveDone, waveTotal = 0, 0
        end
        waveTotal = waveTotal + 1
        queue[#queue + 1], queued[itemID] = itemID, true
    end
    wake()
end

local function text(value)
    if issecretvalue and issecretvalue(value) then
        return nil
    end
    if type(value) ~= "string" then
        return nil
    end
    return value
        :gsub("|c%x%x%x%x%x%x%x%x", "")
        :gsub("|r", "")
        :gsub("|cn[%w_]+:", "")
        :gsub("|n", "\n")
        :gsub("|H.-|h(.-)|h", "%1")
        :gsub("|T.-|t", "")
        :gsub("\194\160", " ")
        :gsub(" ", " ")
        :gsub("　", " ")
        :gsub("：", ":")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
end

local prefixLocale, prefixes
local function kindOf(key)
    local locale = GetLocale()
    if prefixLocale ~= locale then
        prefixLocale, prefixes = locale, {}
        local formats = Locales[locale]
        if formats then
            -- English fallback text can be supplied by partially localized clients.
            for _, format in ipairs({ formats, Locales.enUS }) do
                for _, kind in ipairs({ "crates", "writs" }) do
                    prefixes[#prefixes + 1] = { kind = kind, pattern = "^" .. Locales.Key(format[kind]) .. "%s*:%s*%S" }
                end
            end
        end
    end
    for _, prefix in ipairs(prefixes) do
        if key:match(prefix.pattern) then
            return prefix.kind
        end
    end
end

function Discovery.Observe(itemID, name, relevantOnly)
    if type(itemID) ~= "number" or itemID <= 0 then
        return
    end
    name = name or (C_Item and C_Item.GetItemNameByID(itemID))
    if issecretvalue and issecretvalue(name) then
        return false
    end
    if Discovery.store and Discovery.store.names[itemID] == name and name ~= nil then
        if Discovery.candidates[itemID] then
            Discovery.pending[itemID] = true
        end
        return false
    end
    name = text(name)
    if not name or name == "" then
        if not relevantOnly and C_Item and C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(itemID)
        end
        return false
    end
    local key = Locales.Key(name)
    local kind = kindOf(key)
    if
        relevantOnly
        and not kind
        and not neededNames[key]
        and Discovery.names[key] == nil
        and not addon.MaterialNames[itemID]
        and not addon.WritMaterialNames[itemID]
    then
        return false
    end
    local previous = Discovery.names[key]
    -- Never guess between distinct items that have the same localized name.
    Discovery.names[key] = previous == nil and itemID or (previous == itemID and itemID or false)
    if Discovery.store then
        Discovery.store.names[itemID] = name
    end
    if kind then
        local definitions = kind == "crates" and addon.Crates or addon.Writs
        definitions[itemID] = definitions[itemID]
            or { name = name, unresolved = true, [kind == "crates" and "options" or "requirements"] = {} }
        definitions[itemID].name = name
        Discovery.candidates[itemID] = kind
        Discovery.pending[itemID] = true
    end
    return previous == nil or (previous ~= false and previous ~= itemID)
end

local function stripName(name)
    return text(name):gsub("。$", ""):gsub("；$", ""):gsub("[%.;]$", ""):gsub("^%[", ""):gsub("%]$", "")
end

local function cleanName(name)
    return Locales.Key(stripName(name))
end

local function resolve(name, linkID)
    name = cleanName(name)
    neededNames[name] = true
    if linkID then
        local actual = C_Item and C_Item.GetItemNameByID(linkID)
        if actual then
            Discovery.Observe(linkID, actual)
        end
        return linkID
    end
    -- Strip display brackets and sentence punctuation, not apostrophes in names.
    return Discovery.names[name] or nil
end

local function deliveryBody(line, formats)
    local value = Locales.Key(line)
    for _, format in ipairs({ formats, Locales.enUS }) do
        for _, pattern in ipairs(format.metadata or {}) do
            if value:match(pattern) then
                return nil
            end
        end
        for _, excluded in ipairs(format.excluded) do
            -- Allow the French space before a colon, including normalized NBSP.
            local prefix = excluded:gsub(":$", "%%s*:")
            if value:match("^" .. prefix) then
                return nil
            end
        end
    end
    for _, format in ipairs({ formats, Locales.enUS }) do
        for _, command in ipairs(format.delivery) do
            local body = value:match("^" .. command .. "[:%s]+(.+)$")
            if not body and format.compact then
                body = value:match("^" .. command .. "%s*:?%s*(%d.+)$")
            end
            if body then
                return body
            end
        end
        for _, command in ipairs(format.required) do
            -- Do not interpret level/skill requirements as delivery objectives.
            local body = value:match("^" .. command .. "[:%s]+(%d.+)$")
            if not body and format.compact then
                body = value:match("^" .. command .. "%s*:?%s*(%d.+)$")
            end
            if body then
                return body
            end
        end
    end
end

local function quantityAndName(body, formats)
    body = body:gsub("×", "x")
    local quantity, name = body:match("^(%d+)%s+[xX]%s+(.+)$")
    if not quantity then
        quantity, name = body:match("^(%d+)%s+(.+)$")
    end
    if not quantity then
        quantity, name = body:match("^(%d+)%s*[xX]%s*(.+)$")
    end
    if not quantity and formats.compact then
        quantity, name = body:match("^(%d+)%s*(%D.+)$")
    end
    if not quantity then
        name, quantity = body:match("^(.+)%s+[xX]%s*(%d+)[%.;]?$")
    end
    return quantity and tonumber(quantity), name
end

local function resolveDelivery(name, linked, formats)
    local key = cleanName(name)
    local itemID = resolve(key, linked[key])
    if itemID then
        return itemID
    end
    for _, wrapper in ipairs(formats.wrappers or {}) do
        if key:sub(1, #wrapper) == wrapper then
            local stripped = key:sub(#wrapper + 1)
            itemID = resolve(stripped, linked[stripped])
            if itemID then
                return itemID
            end
        end
    end
    for _, format in ipairs({ formats, Locales.enUS }) do
        for _, recipient in ipairs(format.recipient or {}) do
            local start = key:find(recipient, 1, true)
            if start then
                local stripped = key:sub(1, start - 1)
                itemID = resolve(stripped, linked[stripped])
                if itemID then
                    return itemID
                end
            end
        end
    end
end

-- Accept explicit list entries and delivery sentences. Item names are resolved
-- exactly; partial/missing objectives invalidate the entire definition.
function Discovery.Parse(lines, kind, ownID)
    local formats = Locales[GetLocale()]
    if not formats then
        return nil, "Unsupported client locale: " .. tostring(GetLocale())
    end
    local result, seen = {}, {}
    for _, raw in ipairs(lines or {}) do
        local source = type(raw) == "table" and raw.leftText or raw
        local linked = {}
        -- Hyperlinks provide authoritative IDs even before the AH name index exists.
        if type(source) == "string" and not (issecretvalue and issecretvalue(source)) then
            for id, label in source:gmatch("|Hitem:(%d+).-|h(.-)|h") do
                local name = stripName(label)
                local key = cleanName(name)
                id = tonumber(id)
                local previous = linked[key]
                linked[key] = previous == nil and id or (previous == id and id or false)
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
                local body = line:match("^%-%s*(.+)") or line:match("^•%s*(.+)")
                if not body then
                    body = deliveryBody(line, formats)
                end
                if body then
                    local quantity, name = quantityAndName(body, formats)
                    if quantity then
                        local itemID = resolveDelivery(name, linked, formats)
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
    if #result == 0 then
        return nil, "Delivery description is not loaded or its format is unsupported."
    end
    if kind == "crates" and #result < 2 then
        return nil, "Incomplete crate alternatives."
    end
    return result
end

function Discovery.Read(itemID, data)
    local kind = Discovery.candidates[itemID]
    if Discovery.suspended or not kind or reading[itemID] then
        return false
    end
    reading[itemID] = true
    if not data and C_TooltipInfo and C_TooltipInfo.GetItemByID then
        data = C_TooltipInfo.GetItemByID(itemID)
    end
    local oldInstance = itemTooltips[itemID]
    if oldInstance then
        tooltipItems[oldInstance] = nil
    end
    local instance = data and data.dataInstanceID
    if instance and not (issecretvalue and issecretvalue(instance)) then
        tooltipItems[instance], itemTooltips[itemID] = itemID, instance
    else
        itemTooltips[itemID] = nil
    end
    if not data then
        if not requested[itemID] and C_Item and C_Item.RequestLoadItemDataByID then
            requested[itemID] = true
            C_Item.RequestLoadItemDataByID(itemID)
        end
        reading[itemID] = nil
        return false
    end
    requested[itemID] = nil
    local definitions = kind == "crates" and addon.Crates or addon.Writs
    local definition = definitions[itemID]
    local requirements, reason = Discovery.Parse(data.lines, kind, itemID)
    reading[itemID] = nil
    if not requirements then
        -- Loading text and generic writ flavor text contain no objectives.
        -- Their absence cannot disprove a known bundle. Explicit invalid or
        -- partial objectives still invalidate it below.
        local known = definition[kind == "crates" and "options" or "requirements"]
        if
            reason == "Delivery description is not loaded or its format is unsupported."
            and not definition.unresolved
            and known
            and #known > 0
        then
            Discovery.pending[itemID] = nil
            return false
        end
        Discovery.pending[itemID] = true
        local changed = not definition.unresolved or definition.reason ~= reason or (known and #known > 0)
        if changed then
            definition.unresolved, definition.reason = true, reason
            -- A changed, incomplete live description must not retain old quantities.
            definition[kind == "crates" and "options" or "requirements"] = {}
            definition[kind == "crates" and "requirements" or "options"] = nil
        end
        return false, changed
    end
    local known = definition[kind == "crates" and "options" or "requirements"] or {}
    local changed = definition.unresolved or definition.fallback or #known ~= #requirements
    for index, requirement in ipairs(requirements) do
        local old = known[index]
        if not old or old.itemID ~= requirement.itemID or old.quantity ~= requirement.quantity then
            changed = true
        end
    end
    Discovery.pending[itemID] = nil
    if not changed then
        return true, false
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
    return true, true
end

function Discovery.Progress()
    return waveDone, waveTotal
end

-- Events only request work. A full scan can load thousands of unrelated items;
-- never parse the entire pending catalog inside each item/tooltip callback.
function Discovery.Retry(defer)
    retryRequested = true
    retryAt = defer and GetTime() + QUIET_SECONDS or nil
    wake()
end

function Discovery.IsWorking()
    return retryRequested or cursor <= #queue
end

-- Only contracts and their delivery goods belong in the saved price database.
-- The full market name index is temporary, needed to resolve new descriptions
-- regardless of whether their goods occur before or after them in the snapshot.
function Discovery.Scope()
    local scope = {}
    for _, names in ipairs({ addon.MaterialNames, addon.WritMaterialNames }) do
        for id in pairs(names) do
            scope[id] = true
        end
    end
    for _, definitions in ipairs({ addon.Crates, addon.Writs }) do
        for id, definition in pairs(definitions) do
            scope[id] = true
            for _, requirement in ipairs(definition.options or definition.requirements or {}) do
                scope[requirement.itemID] = true
            end
        end
    end
    return scope
end

function Discovery.Prune()
    local scope = Discovery.Scope()
    local store = Discovery.store
    if store then
        local names, keys, index = {}, {}, {}
        for id in pairs(scope) do
            if store.names[id] then
                keys[Locales.Key(store.names[id])] = true
            end
        end
        for id, name in pairs(store.names) do
            local key = Locales.Key(name)
            -- Preserve collisions with relevant names; pruning must never turn
            -- an ambiguous delivery into a seemingly authoritative item ID.
            if scope[id] or keys[key] or neededNames[key] then
                names[id] = name
                local previous = index[key]
                index[key] = previous == nil and id or (previous == id and id or false)
            end
        end
        store.names, Discovery.names = names, index
    end
    -- Also clean snapshots written by older releases, across market profiles.
    -- Replace the tables so their oversized Lua hash capacity can be collected.
    for _, market in pairs(addon.db.markets or {}) do
        local items, failures = {}, {}
        for id, snapshot in pairs(market.items or {}) do
            if scope[id] or snapshot.kind ~= "estimate" then
                items[id] = snapshot
            end
        end
        for id, reason in pairs(market.failures or {}) do
            if scope[id] or items[id] then
                failures[id] = reason
            end
        end
        market.items, market.failures = items, failures
    end
end

process = function()
    if addon.Providers and addon.Providers.scan then
        Discovery.frame:SetScript("OnUpdate", nil)
        return
    end
    -- Plain-name requirements need the complete market name index first.
    local job = addon.BulkScan and addon.BulkScan.engine and addon.BulkScan.engine.job
    if job and not job.resolving then
        return
    end
    if retryAt and GetTime() < retryAt then
        return
    end
    retryAt = nil
    if retryRequested then
        retryRequested = false
        for itemID in pairs(Discovery.pending) do
            enqueue(itemID)
        end
    end
    local started = debugprofilestop and debugprofilestop()
    local attempts = 0
    while cursor <= #queue and attempts < BATCH do
        local itemID = queue[cursor]
        cursor = cursor + 1
        if Discovery.pending[itemID] then
            local _, changed = Discovery.Read(itemID)
            Discovery.progress = Discovery.progress + 1
            dirty = dirty or changed
            attempts = attempts + 1
        end
        queued[itemID] = nil
        waveDone = waveDone + 1
        if started and debugprofilestop() - started >= BUDGET_MS then
            break
        end
    end
    if job and job.resolving and addon.BrowseUI then
        addon.BrowseUI.UpdateScanStatus()
    end
    if cursor <= #queue or retryRequested then
        -- Events can arrive between batches. Do not retain an ever-growing
        -- consumed prefix while a long scan keeps adding targeted retries.
        if cursor > 100 and cursor > #queue / 2 then
            local remaining = {}
            for index = cursor, #queue do
                remaining[#remaining + 1] = queue[index]
            end
            queue, cursor = remaining, 1
        end
        return
    end
    queue, queued, cursor = {}, {}, 1
    Discovery.frame:SetScript("OnUpdate", nil)
    if addon.Trace and addon.db and addon.db.debug then
        local unresolved = 0
        for _ in pairs(Discovery.pending) do
            unresolved = unresolved + 1
        end
        addon:Trace(
            "discovery.wave",
            5,
            "%d/%d descriptions; unresolved=%d changed=%s; sleeping until new data",
            waveDone,
            waveTotal,
            unresolved,
            tostring(dirty)
        )
    end
    -- One redraw per wave, including invalidated definitions. Failed parses stay
    -- pending but sleep until new item data, names or a later scan arrive.
    if dirty then
        dirty = false
        if addon.UI then
            addon.UI.Update()
        end
        if addon.Tooltip then
            addon.Tooltip.Refresh()
        end
    end
end

function Discovery.Bags()
    if not C_Container then
        return
    end
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID then
                Discovery.Observe(itemID)
            end
        end
    end
    Discovery.Retry()
end

function Discovery.SetSuspended(suspended)
    if Discovery.suspended == suspended then
        return
    end
    local wasSuspended = Discovery.suspended
    Discovery.suspended = suspended
    local frame = Discovery.frame
    if not frame then
        return
    end
    for _, event in ipairs(EVENTS) do
        if suspended then
            frame:UnregisterEvent(event)
        else
            frame:RegisterEvent(event)
        end
    end
    if suspended then
        frame:SetScript("OnUpdate", nil)
    elseif wasSuspended then
        -- Item/bag events missed during the scan are reconciled once at the end.
        Discovery.Bags()
    end
end

function Discovery.Install()
    local locale, build = GetLocale(), select(4, GetBuildInfo())
    Discovery.locale = locale
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
    for _, pair in ipairs({ { store.crates, addon.Crates }, { store.writs, addon.Writs } }) do
        for itemID, definition in pairs(pair[1]) do
            -- Recover known rows invalidated by the discovery-only release.
            if not definition.unresolved or not pair[2][itemID] then
                pair[2][itemID] = definition
            end
        end
    end
    store.crates, store.writs = addon.Crates, addon.Writs
    Discovery.Prune()
    -- Prune rebuilt the name index; Observe still needs to register candidates.
    local savedNames = store.names
    store.names = {}
    for itemID, name in pairs(savedNames) do
        Discovery.Observe(itemID, name)
    end
    local english = locale == "enUS" or locale == "enGB"
    for _, names in ipairs({ addon.MaterialNames, addon.WritMaterialNames }) do
        for itemID, name in pairs(names) do
            Discovery.Observe(itemID, english and name or nil)
        end
    end
    for _, definitions in ipairs({ addon.Crates, addon.Writs }) do
        for itemID, definition in pairs(definitions) do
            Discovery.Observe(itemID, english and definition.name or nil)
        end
    end
    Discovery.Bags()
    local frame = CreateFrame("Frame")
    Discovery.frame = frame
    if retryRequested then
        wake()
    end
    Discovery.suspended = nil
    Discovery.SetSuspended(addon.Providers and addon.Providers.scan ~= nil or false)
    frame:SetScript("OnEvent", function(_, event, itemID, success)
        -- Auctionator may load every AH item and update tooltips repeatedly.
        -- Keep our discovery idle until its completion callback, even when its
        -- row loop finishes before its price database has been processed.
        if addon.Providers and addon.Providers.scan then
            if addon.db and addon.db.debug then
                local scan = addon.Providers.scan
                scan.ignoredEvents = (scan.ignoredEvents or 0) + 1
            end
            return
        end
        if event == "ITEM_DATA_LOAD_RESULT" then
            if not success then
                return
            end
            local changed = Discovery.Observe(itemID, nil, true)
            if Discovery.candidates[itemID] then
                enqueue(itemID)
                retryAt = GetTime() + QUIET_SECONDS
            elseif changed then
                Discovery.Retry(true)
            end
        elseif event == "TOOLTIP_DATA_UPDATE" then
            if issecretvalue and issecretvalue(itemID) then
                return
            end
            -- This event carries a tooltip instance ID, not an item ID.
            local candidate = tooltipItems[itemID]
            if not candidate or reading[candidate] then
                return
            end
            Discovery.pending[candidate] = true
            enqueue(candidate)
            retryAt = GetTime() + QUIET_SECONDS
        elseif event == "BAG_UPDATE_DELAYED" then
            Discovery.Bags()
        elseif event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" or event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
            if C_AuctionHouse and C_AuctionHouse.GetBrowseResults then
                for _, row in ipairs(C_AuctionHouse.GetBrowseResults() or {}) do
                    if row.itemKey then
                        Discovery.Observe(row.itemKey.itemID)
                    end
                end
            end
            Discovery.Retry()
        end
    end)
end
