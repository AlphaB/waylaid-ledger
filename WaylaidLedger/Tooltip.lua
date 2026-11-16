local _, addon = ...
local L = addon.L
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

local function appendRows(tooltip, rows, detailed, compare)
    local best = compare and addon.Pricing.LowestKnown(rows) or nil
    local owned = addon.Inventory.Totals().items
    for _, row in ipairs(rows) do
        local label = string.format("%dx %s", row.quantity, addon.Catalog.ItemName(row.itemID))
        if (owned[row.itemID] or 0) > 0 then label = label .. string.format(L[" (%d owned)"], owned[row.itemID]) end
        local value, red, green, blue = L["Not scanned"], 0.65, 0.65, 0.65
        if row.status == "ok" then
            value = money(row.cost)
            red, green, blue = 1, 1, 1
            if row.purchased and row.purchased > row.quantity then value = value .. string.format(L[" (buy %d)"], row.purchased) end
        elseif row.status == "short" then
            value = row.available == 0 and L["None listed"] or string.format(L["Only %d"], row.available)
            red, green, blue = 1, 0.45, 0.35
        elseif row.source ~= "own" then value = L["No price"] end
        if row.stale or row.error then
            if row.error then value = value .. L[" failed"] end
            red, green, blue = 0.65, 0.65, 0.65
        end
        local winner = best and row.status == "ok" and not row.error and row.cost == best.cost
        if winner then
            red, green, blue = 0.25, 1, 0.35
        end
        if detailed then
            value = value .. " - " .. (row.sourceLabel or row.source)
            if row.age then value = value .. ", " .. string.format(L["%dm"], math.floor(row.age / 60))
            elseif row.ageDays ~= nil then value = value .. ", " .. string.format(L["%dd"], row.ageDays)
            elseif row.estimated then value = value .. L[", age unknown"] end
            if row.scanError then value = value .. L[", own scan failed"] end
        end
        if winner then
            -- GetMoneyString can embed white color codes that override the
            -- FontString RGB. Preserve coin textures and explicitly tint digits.
            value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            local color = "|cff40ff59"
            value = color .. value .. "|r"
        end
        tooltip:AddDoubleLine(label, value, red, green, blue, red, green, blue)
    end
end

function Tooltip.Append(tooltip, itemID, data)
    if tooltip.waylaidLedgerItemID == itemID then return end
    addon.Discovery.Observe(itemID)
    addon.Discovery.Read(itemID, data and data.lines and data)
    local writ = addon.Writs[itemID]
    if not addon.db or (writ and addon.db.writSource == "off")
        or (not writ and not addon.Crates[itemID] and itemID ~= 248549) then
        return
    end
    if not watched[tooltip] then
        watched[tooltip] = true
        tooltip:HookScript("OnTooltipCleared", function(self)
            self.waylaidLedgerItemID = nil
        end)
    end
    tooltip.waylaidLedgerItemID = itemID
    if itemID == 248549 then
        tooltip:AddLine(" ")
        tooltip:AddLine("Waylaid Ledger", 1, 0.82, 0)
        tooltip:AddLine(L["Identify this shipment first to compare its filling costs."], 0.75, 0.75, 0.75, true)
        return
    end
    addon.lastContractID = itemID
    local definition = writ or addon.Crates[itemID]
    if definition and definition.unresolved then
        tooltip:AddLine(" ")
        tooltip:AddLine("Waylaid Ledger", 1, 0.82, 0)
        tooltip:AddLine(L["Delivery requirements unresolved. Run a full AH scan, then hover this item again."], 0.75, 0.75, 0.75, true)
        return
    end
    if writ then
        addon.lastWritID = itemID
        local rows, total = addon.WritPricing.Rows(itemID)
        local detailed = addon.db.tooltipDetails or (IsShiftKeyDown and IsShiftKeyDown())
        tooltip:AddLine(" ")
        tooltip:AddLine(L["Waylaid Ledger - delivery estimate"], 1, 0.82, 0)
        appendRows(tooltip, rows, detailed)
        if #rows > 1 then
            tooltip:AddDoubleLine(L["Total"], total and money(total) or L["Incomplete prices"],
                0.75, 0.75, 0.75, 0.75, 0.75, 0.75)
        end
        return
    end
    addon.lastCrateID = itemID
    if addon.UI and addon.UI.Update then
        addon.UI.Update(false)
    end
    local rows = addon:GetRows(itemID)
    local detailed = addon.db.tooltipDetails or (IsShiftKeyDown and IsShiftKeyDown())
    tooltip:AddLine(" ")
    tooltip:AddLine("Waylaid Ledger", 1, 0.82, 0)
    appendRows(tooltip, rows, detailed, true)
end

function Tooltip.Refresh()
    for tooltip in pairs(watched) do
        if tooltip.waylaidLedgerItemID and tooltip:IsShown() and tooltip.RebuildFromTooltipInfo then
            tooltip.waylaidLedgerItemID = nil
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
                Tooltip.Append(tooltip, itemID, data)
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
