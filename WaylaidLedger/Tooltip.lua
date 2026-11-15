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

local function appendRows(tooltip, rows, detailed, isWrit)
    local owned = addon.Inventory.Totals().items
    local sources, hasPrice = {}, false
    for _, row in ipairs(rows) do
        local code = row.source == "auctionator" and "A" or (row.source == "tsm"
            and (addon.db.tsmKey == "DBMarket" and "M" or "T") or (row.source == "own" and "S" or "?"))
        sources[code] = true
        local label = string.format("%dx %s", row.quantity, addon.Catalog.ItemName(row.itemID))
        if (owned[row.itemID] or 0) > 0 then label = label .. " (" .. owned[row.itemID] .. " owned)" end
        local value, red, green, blue = "Not scanned", 0.65, 0.65, 0.65
        if row.status == "ok" then
            hasPrice = true
            value = (row.estimated and "~ " or "") .. money(row.cost)
            red, green, blue = 1, 1, 1
            if row.purchased and row.purchased > row.quantity then value = value .. " (buy " .. row.purchased .. ")" end
        elseif row.status == "short" then
            value = row.available == 0 and "None listed" or ("Only " .. row.available)
            red, green, blue = 1, 0.45, 0.35
        elseif code ~= "S" then value = "No price" end
        value = value .. " [" .. code .. "]"
        if row.stale or row.error then
            value = value .. (row.error and " failed" or " stale")
            red, green, blue = 0.65, 0.65, 0.65
        elseif row.best then red, green, blue = 0.25, 1, 0.35
        elseif row.bestEstimate then red, green, blue = 1, 0.72, 0.2 end
        if detailed then
            if row.age then value = value .. " - " .. math.floor(row.age / 60) .. "m"
            elseif row.ageDays ~= nil then value = value .. " - " .. row.ageDays .. "d"
            elseif row.estimated then value = value .. " - age unknown" end
            if row.scanError then value = value .. " - own scan failed" end
        end
        tooltip:AddDoubleLine(label, value, red, green, blue, red, green, blue)
    end
    local legend = {}
    for _, entry in ipairs({{"S","Scan"},{"A","Auctionator"},{"T","TSM"},{"M","TSM market"},{"?","Auctionator/TSM"}}) do
        if sources[entry[1]] then legend[#legend + 1] = entry[1] .. ": " .. entry[2] end
    end
    tooltip:AddLine(table.concat(legend, " | ") .. " | ~ estimate", 0.65, 0.65, 0.65, true)
    if detailed then
        if not isWrit then tooltip:AddLine("Green: lowest scanned | Amber: lowest estimated", 0.65, 0.65, 0.65, true) end
        tooltip:AddLine("Full bundle; owned items are not deducted. Estimates do not verify stock.", 0.65, 0.65, 0.65, true)
        if addon.db.profile ~= "default" then
            tooltip:AddLine("Profile: " .. addon.db.profile .. "; external prices disabled.", 0.65, 0.65, 0.65, true)
        end
    elseif not hasPrice then
        tooltip:AddLine(isWrit and "No provider price. Update Auctionator/TSM data." or "At the AH: /wll scan hovered", 0.65, 0.65, 0.65)
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
    if writ then
        addon.lastWritID = itemID
        local rows, total, stale = addon.WritPricing.Rows(itemID)
        local detailed = addon.db.tooltipDetails or (IsShiftKeyDown and IsShiftKeyDown())
        tooltip:AddLine(" ")
        tooltip:AddLine("Waylaid Ledger - delivery estimate", 1, 0.82, 0)
        appendRows(tooltip, rows, detailed, true)
        if #rows > 1 then
            tooltip:AddDoubleLine("Total", total and ("~ " .. money(total) .. (stale and " stale" or "")) or "Incomplete prices",
                0.75, 0.75, 0.75, 0.75, 0.75, 0.75)
        end
        if detailed then
            tooltip:AddLine("Finished goods only; excludes the writ price and quest rewards.", 0.65, 0.65, 0.65, true)
        end
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
    appendRows(tooltip, rows, detailed, false)

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
