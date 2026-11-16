local _, addon = ...

-- Writ objectives are a bundle of finished goods, not alternative ingredients.
-- Resolve their full quantities, including the 200-unit ammunition objective.
addon.WritPricing = {}
function addon.WritPricing.Rows(itemID)
    local writ = addon.Writs[itemID]
    if not writ or addon.db.writSource == "off" then return {} end
    local market = addon:GetMarket()
    local rows = addon.Pricing.Resolve({ options = writ.requirements }, market.items, time(), addon.db.maxAge,
        market.failures, addon.db.writSource, function(source, requiredID)
            if addon.db.profile ~= "default" then return nil end
            return addon.Providers.Read(source, requiredID)
        end)
    local total, complete, stale = 0, true, false
    for _, row in ipairs(rows) do
        -- Requirements are cumulative; no individual requirement is a winner.
        row.best, row.bestEstimate = false, false
        if row.status == "ok" and not row.error then
            total = total + row.cost
            stale = stale or row.stale or false
        else complete = false end
    end
    if writ.unresolved or #writ.requirements == 0 then return {}, nil end
    return rows, complete and total or nil, stale
end
