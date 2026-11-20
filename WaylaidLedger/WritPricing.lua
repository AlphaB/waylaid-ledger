local _, addon = ...

-- Writ objectives are cumulative finished goods, priced from the same own
-- snapshots and optional providers used by crate alternatives.
addon.WritPricing = {}
function addon.WritPricing.Rows(itemID)
    local writ = addon.Writs[itemID]
    if not writ or addon.db.writSource == "off" then
        return {}
    end
    local rows = addon:ResolveRows(writ.requirements, addon.db.writSource)
    local total, complete, stale = 0, true, false
    for _, row in ipairs(rows) do
        -- Requirements are cumulative; no individual requirement is a winner.
        row.best, row.bestEstimate = false, false
        if row.status == "ok" and not row.error then
            total = total + row.cost
            stale = stale or row.stale or false
        else
            complete = false
        end
    end
    if writ.unresolved or #writ.requirements == 0 then
        return {}, nil
    end
    return rows, complete and total or nil, stale
end

local WritPricing = addon.WritPricing
local DAY = 86400
local HISTORY_DAYS = 14

function WritPricing.CompletedToday(itemID)
    local writ = addon.Writs[itemID]
    local isCompleted = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
    return writ and writ.questID and isCompleted and isCompleted(writ.questID) == true
end

-- One observation per UTC day and scan type per auction market. Bulk scans
-- estimate a unit price, while targeted scans price the cheapest buyable lot.
function WritPricing.RecordPrice(market, itemID, snapshot)
    if not addon.Writs[itemID] or snapshot.error then
        return
    end
    local quote = addon.Pricing.Quote(snapshot, 1)
    if quote.status ~= "ok" or quote.cost <= 0 then
        return
    end
    market.writPrices = market.writPrices or {}
    local item = market.writPrices[itemID] or {}
    market.writPrices[itemID] = item
    local source = snapshot.kind == "estimate" and "replicate" or "own"
    local days = item[source] or {}
    item[source] = days
    local day = math.floor(snapshot.scannedAt / DAY)
    for previous in pairs(days) do
        if previous < day - HISTORY_DAYS then
            days[previous] = nil
        end
    end
    days[day] = quote.cost
end

function WritPricing.Discount(market, itemID, quote, now)
    if
        not quote
        or quote.status ~= "ok"
        or quote.stale
        or quote.error
        or (quote.source ~= "own" and quote.source ~= "replicate")
    then
        return
    end
    local item = market.writPrices and market.writPrices[itemID]
    local days = item and item[quote.source]
    if not days then
        return
    end
    local today, prices = math.floor(now / DAY), {}
    -- Exclude the current observation's day even if the quote is from yesterday.
    local quoteDay = math.floor((now - (quote.age or 0)) / DAY)
    for day, price in pairs(days) do
        if day >= today - HISTORY_DAYS and day < quoteDay then
            prices[#prices + 1] = price
        end
    end
    if #prices < 3 then
        return
    end
    table.sort(prices)
    local median = (prices[math.floor((#prices + 1) / 2)] + prices[math.ceil((#prices + 1) / 2)]) / 2
    local discount = math.floor(100 * (median - quote.cost) / median + 0.000001)
    if discount >= 10 then
        return discount, math.floor(median + 0.5)
    end
end
