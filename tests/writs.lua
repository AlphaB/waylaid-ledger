local addon, test, equal = ...

local function fixture(action)
    local originalRead, source, profile = addon.Providers.Read, addon.db.writSource, addon.db.profile
    local prices = { auctionator = {}, tsm = {} }
    addon.db.writSource, addon.db.profile = "auto", "default"
    addon.Providers.Read = function(provider, id)
        return prices[provider][id]
    end
    local ok, err = pcall(action, prices)
    addon.Providers.Read, addon.db.writSource, addon.db.profile = originalRead, source, profile
    if not ok then
        error(err)
    end
end
local function price(source, unitPrice, stale)
    return {
        source = source,
        unitPrice = unitPrice,
        stale = stale,
        ageDays = source == "auctionator" and (stale and 2 or 0) or nil,
    }
end

test("synthetic writs have positive delivery requirements and do not expand crate scans", function()
    local count, items, newItems = 0, {}, 0
    for writID, writ in pairs(addon.Writs) do
        count = count + 1
        for _, requirement in ipairs(writ.requirements) do
            assert(requirement.itemID ~= writID and requirement.quantity > 0)
            assert(addon.WritMaterialNames[requirement.itemID])
            items[requirement.itemID] = true
        end
        equal(#addon.Catalog.Materials({ writID }), 0)
    end
    for id in pairs(items) do
        if not addon.MaterialNames[id] then
            newItems = newItems + 1
        end
    end
    equal(count, 150)
    equal(newItems, 148)
    equal(#addon.Catalog.AllCrates(), 30)
    equal(#addon.Catalog.Materials(addon.Catalog.AllCrates()), 96)
    equal(addon.Writs[264050].requirements[1].itemID, 4245)
    equal(addon.Writs[264050].requirements[1].quantity, 1)
end)
test("writ Auto reads providers even when the crate source is Own, without querying AH", function()
    fixture(function(prices)
        local oldSource = addon.db.source
        addon.db.source = "own"
        prices.auctionator[4245] = price("auctionator", 12345)
        local before = #addon.scanner.requests
        local rows, total = addon.WritPricing.Rows(264050)
        equal(rows[1].source, "auctionator")
        equal(total, 12345)
        equal(rows[1].estimated, true)
        equal(rows[1].bestEstimate, false)
        equal(rows[1].best, false)
        equal(#addon.scanner.requests, before)
        addon.db.source = oldSource
    end)
end)
test("writ delivery estimate multiplies the full ammo quantity", function()
    fixture(function(prices)
        local found
        for id, writ in pairs(addon.Writs) do
            local requirement = writ.requirements[1]
            if requirement.quantity == 200 then
                found = true
                prices.tsm[requirement.itemID] = price("tsm", 3)
                local rows, total = addon.WritPricing.Rows(id)
                equal(rows[1].quantity, 200)
                equal(total, 600)
            end
        end
        assert(found)
    end)
end)
test("writ provider fallback, stale age and forced-source behavior match crates", function()
    fixture(function(prices)
        prices.auctionator[4245] = price("auctionator", 5, true)
        prices.tsm[4245] = price("tsm", 9)
        local rows, total, stale = addon.WritPricing.Rows(264050)
        equal(rows[1].source, "tsm")
        equal(total, 9)
        equal(stale, false)
        addon.db.writSource = "auctionator"
        rows, total, stale = addon.WritPricing.Rows(264050)
        equal(total, 5)
        equal(stale, true)
        equal(rows[1].ageDays, 2)
        prices.auctionator[4245] = nil
        rows, total = addon.WritPricing.Rows(264050)
        equal(rows[1].status, "unknown")
        equal(total, nil)
        addon.db.writSource = "auto"
        addon.db.profile = "neutral"
        rows, total = addon.WritPricing.Rows(264050)
        equal(total, nil)
        equal(rows[1].source, "own")
    end)
end)
test("a partially priced writ bundle never gets a fabricated full total", function()
    fixture(function(prices)
        addon.Writs[999999] = { requirements = { { itemID = 4245, quantity = 1 }, { itemID = 999998, quantity = 2 } } }
        prices.auctionator[4245] = price("auctionator", 10)
        local rows, total = addon.WritPricing.Rows(999999)
        equal(#rows, 2)
        equal(rows[1].cost, 10)
        equal(total, nil)
        prices.tsm[999998] = price("tsm", 20)
        rows, total = addon.WritPricing.Rows(999999)
        equal(total, 50)
        addon.Writs[999999] = nil
    end)
end)
test("writ hover is compact, suppresses duplicates and preserves the selected crate", function()
    fixture(function(prices)
        prices.auctionator[4245] = price("auctionator", 12345)
        local oldCrate = addon.lastCrateID
        local tip = CreateFrame("GameTooltip")
        addon.Tooltip.Append(tip, 264050)
        equal(#tip.lines, 3)
        equal(tip.lines[3][1], "1x Small Silk Pack")
        assert(not tip.lines[3][2]:match("~"))
        assert(not tip.lines[3][2]:match("%[A%]"))
        equal(addon.lastCrateID, oldCrate)
        equal(addon.lastWritID, 264050)
        addon.Tooltip.Append(tip, 264050)
        equal(#tip.lines, 3)
        addon.db.writSource = "off"
        local disabled = CreateFrame("GameTooltip")
        addon.Tooltip.Append(disabled, 264050)
        equal(#disabled.lines, 0)
    end)
end)
test("writ source setting persists, rejects invalid sources and is visible in settings", function()
    local oldSource = addon.db.writSource
    addon:Command("writsource tsm")
    equal(addon.db.writSource, "tsm")
    addon:Command("writsource invalid")
    equal(addon.db.writSource, "tsm")
    addon.UI.ToggleSettings()
    equal(addon.UI.writSourceButton.text, "TSM")
    addon.UI.settings:Hide()
    addon:SetWritSource(oldSource)
end)
