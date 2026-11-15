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

function Tooltip.Append(tooltip, itemID)
    if not addon.db or (not addon.Crates[itemID] and itemID ~= 248549) then
        return
    end
    if not watched[tooltip] then
        watched[tooltip] = true
        tooltip:HookScript("OnTooltipCleared", function(self)
            self.waylaidLedgerItemID = nil
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
    addon.lastCrateID = itemID
    if addon.UI and addon.UI.Update then
        addon.UI.Update()
    end
    local rows, allKnown = addon:GetRows(itemID)
    tooltip:AddLine(" ")
    tooltip:AddLine("Waylaid Ledger - fill one crate", 1, 0.82, 0)
    local hasPrice, hasEstimates = false, false
    for _, row in ipairs(rows) do
        local label = string.format("%dx %s", row.quantity, addon.Catalog.ItemName(row.itemID))
        local value, red, green, blue = "Not scanned", 0.65, 0.65, 0.65
        if row.status == "ok" then
            hasPrice = true
            value = money(row.cost)
            if row.estimated then
                hasEstimates = true
                value = "~ " .. value .. " - " .. row.sourceLabel
            end
            if row.purchased and row.purchased > row.quantity then
                value = value .. " (buy " .. row.purchased .. ")"
            end
            red, green, blue = 1, 1, 1
        elseif row.status == "short" then
            value = row.available == 0 and "None for sale" or ("Only " .. row.available .. " available")
            red, green, blue = 1, 0.45, 0.35
        end
        if row.estimated then
            if row.ageDays ~= nil then
                value = value .. (row.ageDays == 0 and " [today]" or (" [" .. row.ageDays .. "d old]"))
            else
                value = value .. " [age unknown]"
            end
            if row.scanError then
                value = value .. " - own scan failed"
            end
        elseif row.status == "unknown" and row.source ~= "own" then
            value = "No " .. row.sourceLabel .. " price"
        end
        if row.age then
            local minutes = math.floor(row.age / 60)
            value = value .. (minutes == 0 and " [<1m]" or (" [" .. minutes .. "m]"))
        end
        if row.stale or row.error then
            value = value .. (row.error and " - scan failed" or " - stale")
            red, green, blue = 0.65, 0.65, 0.65
        end
        if row.best then
            label = (allKnown and "Cheapest: " or "Lowest verified: ") .. label
            red, green, blue = 0.25, 1, 0.35
        elseif row.bestEstimate then
            label = "Lowest estimate: " .. label
            red, green, blue = 1, 0.72, 0.2
        end
        tooltip:AddDoubleLine(label, value, red, green, blue, red, green, blue)
    end
    if not hasPrice then
        tooltip:AddLine("At the auction house: /wll scan hovered", 0.75, 0.75, 0.75)
    end
    if hasEstimates then
        tooltip:AddLine("~ Unit-price estimate; quantity availability is unverified.", 0.85, 0.65, 0.3, true)
    end
    tooltip:AddLine("Full bundle for one crate; bags not deducted.", 0.6, 0.6, 0.6, true)
    tooltip:AddLine("Own scans exclude account-owned commodity price buckets.", 0.6, 0.6, 0.6, true)
    if addon.db.profile ~= "default" then
        tooltip:AddLine("Market profile: " .. addon.db.profile .. "; external prices disabled.", 0.75, 0.75, 0.75, true)
    end
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
