local _, addon = ...

-- Writ objectives are cumulative finished goods, priced from the same own
-- snapshots and optional providers used by crate alternatives.
addon.WritPricing = {}
function addon.WritPricing.Rows(itemID)
    local writ = addon.Writs[itemID]
    if not writ or addon.db.writSource == "off" then return {} end
    local rows = addon:ResolveRows(writ.requirements, addon.db.writSource)
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
