local _, addon = ...

-- Writ objectives are a bundle of finished goods, not alternative ingredients.
-- Keep them out of the quantity-aware scanner and read optional providers only.
addon.WritPricing = {}
function addon.WritPricing.Rows(itemID)
    local writ = addon.Writs[itemID]
    if not writ or addon.db.writSource == "off" then return {} end
    local rows = addon.Pricing.Resolve({ options = writ.requirements }, {}, time(), addon.db.maxAge,
        {}, addon.db.writSource, function(source, requiredID)
            if addon.db.profile ~= "default" then return nil end
            return addon.Providers.Read(source, requiredID)
        end)
    local total, complete, stale = 0, true, false
    for _, row in ipairs(rows) do
        -- Requirements are cumulative; no individual requirement is a winner.
        row.best, row.bestEstimate = false, false
        if row.source == "own" then row.source, row.sourceLabel = "providers", "Auctionator/TSM" end
        if row.status == "ok" then
            total = total + row.cost
            stale = stale or row.stale or false
        else complete = false end
    end
    return rows, complete and total or nil, stale
end
