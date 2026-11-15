local _, addon = ...
addon.Tooltip = {}
local Tooltip = addon.Tooltip
local watched = setmetatable({}, { __mode = "k" })

local function money(copper)
    if GetMoneyString then
        return GetMoneyString(copper, true)
    end
    return string.format("%dg %ds %dc", math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100)
end
addon.Money = money

local OUTDATED_AFTER = 12 * 60 * 60

function Tooltip.IsOutdated(row)
    if not row or (row.status ~= "ok" and row.status ~= "short") then return false end
    -- Own scans have exact ages. Auctionator exposes whole scan-day buckets;
    -- a previous day warrants a cautious notice, not an invented timestamp.
    if row.age then return row.age > OUTDATED_AFTER end
    return row.ageDays ~= nil and row.ageDays > 0
end

function Tooltip.AddAgeWarning(tooltip, rows)
    if tooltip.waylaidLedgerAgeWarning == true then return end
    for _, row in ipairs(rows) do
        if Tooltip.IsOutdated(row) then
            tooltip:AddLine("Price data might be outdated.", 0.6, 0.6, 0.6)
            tooltip.waylaidLedgerAgeWarning = true
            return
        end
    end
end

local function appendRows(tooltip, rows, detailed)
    local owned = addon.Inventory.Totals().items
    for _, row in ipairs(rows) do
        local label = string.format("%dx %s", row.quantity, addon.Catalog.ItemName(row.itemID))
        if (owned[row.itemID] or 0) > 0 then label = label .. " (" .. owned[row.itemID] .. " owned)" end
        local value, red, green, blue = "Not scanned", 0.65, 0.65, 0.65
        if row.status == "ok" then
            value = (row.estimated and "~ " or "") .. money(row.cost)
            red, green, blue = 1, 1, 1
            if row.purchased and row.purchased > row.quantity then value = value .. " (buy " .. row.purchased .. ")" end
        elseif row.status == "short" then
            value = row.available == 0 and "None listed" or ("Only " .. row.available)
            red, green, blue = 1, 0.45, 0.35
        elseif row.source ~= "own" then value = "No price" end
        if row.stale or row.error then
            if row.error then value = value .. " failed" end
            red, green, blue = 0.65, 0.65, 0.65
        elseif row.best then red, green, blue = 0.25, 1, 0.35
        elseif row.bestEstimate then red, green, blue = 1, 0.72, 0.2 end
        if detailed then
            value = value .. " - " .. (row.sourceLabel or row.source)
            if row.age then value = value .. ", " .. math.floor(row.age / 60) .. "m"
            elseif row.ageDays ~= nil then value = value .. ", " .. row.ageDays .. "d"
            elseif row.estimated then value = value .. ", age unknown" end
            if row.scanError then value = value .. ", own scan failed" end
        end
        tooltip:AddDoubleLine(label, value, red, green, blue, red, green, blue)
    end
end

function Tooltip.Append(tooltip, itemID)
    local writ = addon.Writs[itemID]
    if not addon.db or (writ and addon.db.writSource == "off")
        or (not writ and not addon.Crates[itemID] and itemID ~= 248549) then
        return
    end
    if not watched[tooltip] then
        watched[tooltip] = true
        tooltip:HookScript("OnTooltipCleared", function(self)
            self.waylaidLedgerItemID, self.waylaidLedgerAgeWarning = nil, nil
        end)
    end
    if tooltip.waylaidLedgerItemID == itemID then
        return
    end
    tooltip.waylaidLedgerItemID = itemID
    if itemID == 248549 then
        tooltip:AddLine(" ")
        tooltip:AddLine("Waylaid Ledger", 1, 0.82, 0)
        tooltip:AddLine("Identify this shipment first to compare its filling costs.", 0.75, 0.75, 0.75, true)
        return
    end
    if writ then
        addon.lastWritID = itemID
        local rows, total = addon.WritPricing.Rows(itemID)
        local detailed = addon.db.tooltipDetails or (IsShiftKeyDown and IsShiftKeyDown())
        tooltip:AddLine(" ")
        tooltip:AddLine("Waylaid Ledger - delivery estimate", 1, 0.82, 0)
        appendRows(tooltip, rows, detailed)
        if #rows > 1 then
            tooltip:AddDoubleLine("Total", total and ("~ " .. money(total)) or "Incomplete prices",
                0.75, 0.75, 0.75, 0.75, 0.75, 0.75)
        end
        Tooltip.AddAgeWarning(tooltip, rows)
        return
    end
    addon.lastCrateID = itemID
    if addon.UI and addon.UI.Update then
        addon.UI.Update()
    end
    local rows = addon:GetRows(itemID)
    local detailed = addon.db.tooltipDetails or (IsShiftKeyDown and IsShiftKeyDown())
    tooltip:AddLine(" ")
    tooltip:AddLine("Waylaid Ledger", 1, 0.82, 0)
    appendRows(tooltip, rows, detailed)
    Tooltip.AddAgeWarning(tooltip, rows)
end

function Tooltip.Refresh()
    for tooltip in pairs(watched) do
        if tooltip.waylaidLedgerItemID and tooltip:IsShown() and tooltip.RebuildFromTooltipInfo then
            tooltip.waylaidLedgerItemID, tooltip.waylaidLedgerAgeWarning = nil, nil
            tooltip:RebuildFromTooltipInfo()
        end
    end
end

function Tooltip.Install()
    if TooltipDataProcessor and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            local itemID = data and data.id
            if issecretvalue and issecretvalue(itemID) then
                return
            end
            if type(itemID) == "number" then
                Tooltip.Append(tooltip, itemID)
            end
        end)
        return true
    end
    -- Legacy fallback helps diagnose clients without the modern tooltip handler.
    if GameTooltip and GameTooltip:HasScript("OnTooltipSetItem") then
        GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
            local _, link = tooltip:GetItem()
            local itemID = link and tonumber(link:match("item:(%d+)"))
            if itemID then
                Tooltip.Append(tooltip, itemID)
            end
        end)
        return true
    end
    return false
end
