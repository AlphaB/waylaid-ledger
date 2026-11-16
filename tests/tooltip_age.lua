local addon, test, equal = ...

local function fixture(action)
    local old = {
        source = addon.db.source,
        profile = addon.db.profile,
        details = addon.db.tooltipDetails,
        shift = IsShiftKeyDown,
        auctionator = Auctionator,
        tsm = TSM_API,
        wall = time,
    }
    addon.db.source, addon.db.profile, addon.db.tooltipDetails = "own", "default", false
    IsShiftKeyDown = function()
        return false
    end
    time = function()
        return 100000
    end
    local market = addon:GetMarket()
    old.items, old.failures = market.items, market.failures
    market.items, market.failures = {}, {}
    local ok, err = pcall(action, market)
    addon.db.source, addon.db.profile, addon.db.tooltipDetails = old.source, old.profile, old.details
    IsShiftKeyDown, Auctionator, TSM_API, time = old.shift, old.auctionator, old.tsm, old.wall
    market.items, market.failures = old.items, old.failures
    addon.Providers.Invalidate()
    assert(ok, err)
end
local function snapshot(age)
    return { kind = "commodity", offers = { { quantity = 100, unitPrice = 10 } }, scannedAt = time() - age }
end
local function checkNoNotice(tip)
    for _, line in ipairs(tip.lines) do
        assert(not line[1]:lower():match("outdated"))
        if type(line[2]) == "string" then
            assert(not line[2]:lower():match("outdated"))
        end
    end
end
local function highlighted(line)
    return (line[3] == 0.25 and line[4] == 1) or (line[3] == 1 and line[4] == 0.72)
end

test("compact tooltips contain prices only, without badges, legends or age notifications", function()
    fixture(function(market)
        market.items[2770], market.items[2771] = snapshot(0), snapshot(0)
        local tip = CreateFrame("GameTooltip")
        addon.Tooltip.Append(tip, 248683)
        equal(#tip.lines, 4)
        checkNoNotice(tip)
        for _, line in ipairs(tip.lines) do
            assert(not line[1]:match("~ estimate") and not line[1]:match("Full bundle"))
            if type(line[2]) == "string" then
                assert(not line[2]:match("%[[ASTM]%]"))
            end
        end
    end)
end)
test("cached prices retain their cheapest highlight at any age without a notification", function()
    fixture(function(market)
        for _, age in ipairs({ 0, 1860, 43200, 43201, 90000 }) do
            market.items[2770], market.items[2771] = snapshot(age), snapshot(age)
            market.items[2771].offers[1].unitPrice = 20
            local tip = CreateFrame("GameTooltip")
            addon.Tooltip.Append(tip, 248683)
            equal(#tip.lines, 4)
            checkNoNotice(tip)
            equal(highlighted(tip.lines[3]), true)
            equal(highlighted(tip.lines[4]), false)
            if age > addon.db.maxAge then
                equal(tip.lines[3][3], 0.25)
                equal(tip.lines[3][4], 1)
                assert(not tip.lines[3][2]:match("~"))
            else
                equal(tip.lines[3][3], 0.25)
            end
        end
    end)
end)
test("Auctionator previous-day prices still highlight the cheapest option without an age notice", function()
    fixture(function()
        addon.db.source = "auctionator"
        Auctionator = {
            API = {
                v1 = {
                    GetAuctionPriceByItemID = function(_, id)
                        return id == 2770 and 10 or 20
                    end,
                    GetAuctionAgeByItemID = function()
                        return 2
                    end,
                },
            },
        }
        addon.Providers.Invalidate()
        local tip = CreateFrame("GameTooltip")
        addon.Tooltip.Append(tip, 248683)
        equal(#tip.lines, 4)
        checkNoNotice(tip)
        equal(highlighted(tip.lines[3]), true)
        equal(highlighted(tip.lines[4]), false)
    end)
end)
test("unknown provider age remains unknown and does not suppress cheapest highlighting", function()
    fixture(function()
        addon.db.source = "tsm"
        Auctionator = nil
        TSM_API = {
            GetCustomPriceValue = function(_, item)
                return item == "i:2770" and 10 or 20
            end,
        }
        addon.Providers.Invalidate()
        local tip = CreateFrame("GameTooltip")
        addon.Tooltip.Append(tip, 248683)
        equal(highlighted(tip.lines[3]), true)
        checkNoNotice(tip)
        IsShiftKeyDown = function()
            return true
        end
        tip = CreateFrame("GameTooltip")
        addon.Tooltip.Append(tip, 248683)
        assert(tip.lines[3][2]:match("age unknown"))
        equal(#tip.lines, 4)
    end)
end)
test("native money color codes cannot override the winner tint and coin icons remain intact", function()
    fixture(function(market)
        market.items[2770], market.items[2771] = snapshot(0), snapshot(0)
        market.items[2771].offers[1].unitPrice = 20
        local original = GetMoneyString
        GetMoneyString = function(value)
            return "|cffffffff" .. value .. "|r|Tcoin:12|t"
        end
        local tip = CreateFrame("GameTooltip")
        addon.Tooltip.Append(tip, 248683)
        GetMoneyString = original
        assert(tip.lines[3][2]:match("^|cff40ff59"))
        assert(not tip.lines[3][2]:match("|cffffffff"))
        assert(tip.lines[3][2]:match("|Tcoin:12|t"))
    end)
end)
test("cached cheapest ties highlight together and failed or insufficient costs never win", function()
    fixture(function(market)
        market.items[2770], market.items[2771] = snapshot(90000), snapshot(90000)
        local tip = CreateFrame("GameTooltip")
        addon.Tooltip.Append(tip, 248683)
        equal(highlighted(tip.lines[3]), true)
        equal(highlighted(tip.lines[4]), true)
        market.failures[2770] = "timeout"
        market.items[2771].offers = {}
        tip = CreateFrame("GameTooltip")
        addon.Tooltip.Append(tip, 248683)
        equal(highlighted(tip.lines[3]), false)
        equal(highlighted(tip.lines[4]), false)
        checkNoNotice(tip)
    end)
end)
test("tooltip and shopping agree on the lowest known filling cost", function()
    fixture(function(market)
        market.items[2770], market.items[2771] = snapshot(90000), snapshot(0)
        market.items[2771].offers[1].unitPrice = 20
        local tip = CreateFrame("GameTooltip")
        addon.Tooltip.Append(tip, 248683)
        equal(highlighted(tip.lines[3]), true)
        equal(highlighted(tip.lines[4]), false)
        local entry = addon.Shopping.Entry("crates", 248683)
        equal(entry.optionIndex, 1)
        equal(entry.delivery, 200)
    end)
end)
test("basket hover has no outdated-data notification even when purchase prices are old", function()
    fixture(function()
        local oldTip = GameTooltip
        GameTooltip = CreateFrame("GameTooltip")
        local row = {
            entry = {
                itemID = 264050,
                kind = "writs",
                deliveryRows = {
                    {
                        itemID = 4245,
                        quantity = 1,
                        status = "ok",
                        cost = 50,
                        source = "auctionator",
                        sourceLabel = "Auctionator",
                        estimated = true,
                        ageDays = 2,
                    },
                },
                purchaseQuote = {
                    status = "ok",
                    cost = 100,
                    source = "auctionator",
                    sourceLabel = "Auctionator",
                    estimated = true,
                    ageDays = 2,
                },
                total = 150,
            },
        }
        addon.BrowseUI.ShowTooltip(row)
        checkNoNotice(GameTooltip)
        for _, line in ipairs(GameTooltip.lines) do
            assert(not line[1]:match("Click to search") and not line[1]:match("Full quantities"))
        end
        GameTooltip = oldTip
    end)
end)
