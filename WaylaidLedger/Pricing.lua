local _, addon = ...
local L = addon.L

-- Pure pricing functions. All money is integer copper. Snapshots contain only
-- buyable auctions, with current-character owned quantities removed by Scanner.
addon.Pricing = {}
local Pricing = addon.Pricing

-- Compare displayed, known costs even when every cached quote is old. Unknown,
-- insufficient and failed results must never win. Ties keep catalog order.
function Pricing.LowestKnown(rows)
    local best, bestIndex
    for index, row in ipairs(rows) do
        if row.status == "ok" and not row.error and row.cost and (not best or row.cost < best.cost) then
            best, bestIndex = row, index
        end
    end
    return best, bestIndex
end

function Pricing.Quote(snapshot, required)
    if not snapshot then
        return { status = "unknown" }
    end
    if snapshot.kind == "estimate" then
        return { status = "ok", cost = math.ceil(snapshot.unitPrice * required), estimated = true }
    end
    local available = 0
    for _, offer in ipairs(snapshot.offers) do
        available = available + offer.quantity
    end
    if available < required then
        return { status = "short", available = available }
    end

    if snapshot.kind == "commodity" then
        local remaining, cost = required, 0
        -- The scanner normalizes offers in ascending unit-price order.
        for _, offer in ipairs(snapshot.offers) do
            local take = math.min(remaining, offer.quantity)
            cost = cost + take * offer.unitPrice
            remaining = remaining - take
            if remaining == 0 then
                break
            end
        end
        return { status = "ok", cost = cost, purchased = required, available = available }
    end

    -- Item auctions are indivisible. Dynamic programming finds the minimum cash
    -- outlay to buy at least the requested count, including unavoidable excess.
    -- Capping the terminal state at required makes this O(offers * required).
    local costs, quantities = { [0] = 0 }, { [0] = 0 }
    for _, offer in ipairs(snapshot.offers) do
        for count = required - 1, 0, -1 do
            if costs[count] then
                local nextCount = math.min(required, count + offer.quantity)
                local nextCost = costs[count] + offer.buyoutAmount
                local nextQuantity = quantities[count] + offer.quantity
                if
                    not costs[nextCount]
                    or nextCost < costs[nextCount]
                    or (nextCost == costs[nextCount] and nextQuantity < quantities[nextCount])
                then
                    costs[nextCount] = nextCost
                    quantities[nextCount] = nextQuantity
                end
            end
        end
    end
    return { status = "ok", cost = costs[required], purchased = quantities[required], available = available }
end

function Pricing.Evaluate(crate, snapshots, now, maxAge, failures)
    local rows, bestCost, allKnown = {}, nil, true
    for _, option in ipairs(crate.options) do
        local snapshot = snapshots[option.itemID]
        local quote = Pricing.Quote(snapshot, option.quantity)
        quote.itemID, quote.quantity = option.itemID, option.quantity
        quote.age = snapshot and math.max(0, now - snapshot.scannedAt) or nil
        quote.stale = quote.age and quote.age > maxAge or false
        quote.error = (failures and failures[option.itemID]) or (snapshot and snapshot.error) or nil
        if quote.status == "unknown" or quote.stale or quote.error then
            allKnown = false
        end
        if quote.status == "ok" and not quote.stale and not quote.error then
            bestCost = bestCost and math.min(bestCost, quote.cost) or quote.cost
        end
        rows[#rows + 1] = quote
    end
    for _, row in ipairs(rows) do
        row.best = bestCost ~= nil and row.status == "ok" and not row.stale and not row.error and row.cost == bestCost
    end
    return rows, allKnown
end

-- Resolve each option using an explicit source policy. In Auto, a fresh scan
-- (including known shortages) takes precedence over any imported estimate.
-- The lookup is injected so provider behavior can be tested independently.
function Pricing.Resolve(crate, snapshots, now, maxAge, failures, mode, lookup)
    -- Forced providers never use the order book. In particular, do not run the
    -- stack-selection DP over a potentially large saved snapshot just to discard it.
    local scanRows = (mode == "own" or mode == "auto") and Pricing.Evaluate(crate, snapshots, now, maxAge, failures)
    local rows, allVerified = {}, true
    for index, option in ipairs(crate.options) do
        local scan = scanRows and scanRows[index]
            or { itemID = option.itemID, quantity = option.quantity, status = "unknown" }
        scan.source, scan.sourceLabel =
            scan.estimated and "replicate" or "own", scan.estimated and L["AH full scan"] or L["Own scan"]
        scan.best = false
        local freshScan = scan.status ~= "unknown" and not scan.stale and not scan.error
        local row = scan
        if mode ~= "own" and not (mode == "auto" and freshScan) then
            local sources = mode == "auto" and { "auctionator", "tsm" } or { mode }
            local estimate, staleEstimate
            for _, source in ipairs(sources) do
                local candidate = lookup(source, scan.itemID)
                if candidate then
                    if not candidate.stale then
                        estimate = candidate
                        break
                    end
                    staleEstimate = staleEstimate or candidate
                end
            end
            estimate = estimate or staleEstimate
            if estimate then
                row = {
                    itemID = scan.itemID,
                    quantity = scan.quantity,
                    status = "ok",
                    estimated = true,
                    cost = math.ceil(estimate.unitPrice * scan.quantity),
                    source = estimate.source,
                    sourceLabel = estimate.sourceLabel,
                    ageDays = estimate.ageDays,
                    stale = estimate.stale,
                    scanError = mode == "auto" and scan.error or nil,
                }
            elseif mode ~= "auto" then
                row = {
                    itemID = scan.itemID,
                    quantity = scan.quantity,
                    status = "unknown",
                    source = mode,
                    sourceLabel = mode == "auctionator" and "Auctionator" or "TSM",
                }
            end
        end
        if row.estimated or row.status == "unknown" or row.stale or row.error then
            allVerified = false
        end
        rows[index] = row
    end
    local best = Pricing.LowestKnown(rows)
    for _, row in ipairs(rows) do
        local winner = best ~= nil and row.status == "ok" and not row.error and row.cost == best.cost
        row.best = winner and not row.estimated and not row.stale or false
        row.bestEstimate = winner and (row.estimated or row.stale) or false
    end
    return rows, allVerified
end
