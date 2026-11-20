local addon, test, equal = ...
local Shopping = addon.Shopping

test("every sort column supports both directions with unknown numeric values last", function()
    local rows = {
        { itemID = 1, name = "Bravo", purchase = 300, delivery = 100, total = 400, unitCost = 4 },
        { itemID = 2, name = "Alpha", purchase = 100, delivery = 500, total = 600, unitCost = 3 },
        { itemID = 3, name = "Charlie", purchase = 200, delivery = 200, total = 400, unitCost = 2 },
        { itemID = 4, name = "Unknown" },
    }
    local expected = {
        name = { { 2, 1, 3, 4 }, { 4, 3, 1, 2 } },
        purchase = { { 2, 3, 1, 4 }, { 1, 3, 2, 4 } },
        delivery = { { 1, 3, 2, 4 }, { 2, 3, 1, 4 } },
        total = { { 3, 1, 2, 4 }, { 2, 3, 1, 4 } },
        unitCost = { { 3, 2, 1, 4 }, { 1, 2, 3, 4 } },
    }
    for key, directions in pairs(expected) do
        for index, ids in ipairs(directions) do
            table.sort(rows, function(a, b)
                return Shopping.Compare(a, b, key, index == 2)
            end)
            for n, id in ipairs(ids) do
                equal(rows[n].itemID, id, key)
            end
            for _, row in ipairs(rows) do
                equal(Shopping.Compare(row, row, key, index == 2), false)
            end
        end
    end
    equal(Shopping.Compare(rows[1], rows[4], "invalid", false), Shopping.Less(rows[1], rows[4]))
end)

local function fixture(action)
    local old = {
        read = addon.Providers.Read,
        auctionator = Auctionator,
        source = addon.db.source,
        writSource = addon.db.writSource,
        profile = addon.db.profile,
        locale = GetLocale,
        names = C_Item.GetItemNameByID,
        request = C_Item.RequestLoadItemDataByID,
    }
    addon.db.source, addon.db.writSource, addon.db.profile = "auto", "auto", "default"
    local market = addon:GetMarket()
    old.items, old.failures = market.items, market.failures
    market.items, market.failures = {}, {}
    local f = { prices = { auctionator = {}, tsm = {} }, searches = {}, reads = 0 }
    addon.Providers.Read = function(source, id)
        f.reads = f.reads + 1
        return f.prices[source][id]
    end
    Auctionator = {
        API = {
            v1 = {
                MultiSearchAdvanced = function(caller, terms)
                    equal(caller, "WaylaidLedger")
                    equal(addon.scanner.active, false)
                    f.searches[#f.searches + 1] = terms
                end,
            },
        },
    }
    addon.scanner:SetOpen(true)
    function f.price(id, amount, source, stale)
        source = source or "auctionator"
        f.prices[source][id] =
            { source = source, sourceLabel = source, unitPrice = amount, estimated = true, stale = stale or false }
    end
    local ok, err = pcall(action, f, market)
    addon:StopScan()
    addon.autoDue = nil
    addon.autoPaused = false
    addon.scanAutomatic = false
    addon.Providers.Read, Auctionator = old.read, old.auctionator
    addon.db.source, addon.db.writSource, addon.db.profile = old.source, old.writSource, old.profile
    market.items, market.failures = old.items, old.failures
    GetLocale, C_Item.GetItemNameByID, C_Item.RequestLoadItemDataByID = old.locale, old.names, old.request
    addon:UpdateScheduler()
    assert(ok, err)
end

test("writ browse totals include one writ and the full delivery, sorted by cost per reputation", function()
    fixture(function(f)
        f.price(264050, 100)
        f.price(4245, 400)
        f.price(264037, 40)
        f.price(8069, 3)
        local entries = Shopping.Entries("writs")
        equal(#entries, 150)
        equal(entries[1].itemID, 264050)
        equal(entries[1].total, 500)
        equal(entries[2].itemID, 264037)
        equal(entries[2].delivery, 600)
        equal(entries[2].total, 640)
        equal(entries[3].total, nil)
    end)
end)
test("writ ranks compare the complete basket per reputation instead of its total", function()
    fixture(function(f)
        local saved = addon.Writs
        addon.Writs = {
            [264050] = { name = "Journeyman", requirements = { { itemID = 4245, quantity = 1 } } },
            [264077] = { name = "Expert", requirements = { { itemID = 4245, quantity = 1 } } },
            [264153] = { name = "Artisan", requirements = { { itemID = 4245, quantity = 1 } } },
        }
        local ok, err = pcall(function()
            f.price(4245, 400)
            f.price(264050, 100)
            f.price(264077, 300)
            f.price(264153, 500)
            local rows = Shopping.Entries("writs")
            equal(rows[1].itemID, 264153)
            equal(rows[1].total, 900)
            equal(rows[1].reward, 200)
            equal(rows[1].unitCost, 4.5)
            equal(rows[2].itemID, 264077)
            equal(rows[2].reward, 125)
            equal(rows[2].unitCost, 5.6)
            equal(rows[3].itemID, 264050)
            equal(rows[3].total, 500)
            equal(rows[3].reward, 75)
            f.prices.auctionator[264153] = nil
            rows = Shopping.Entries("writs")
            equal(rows[1].itemID, 264077)
            equal(rows[3].unitCost, nil)
        end)
        addon.Writs = saved
        assert(ok, err)
    end)
end)

test("crate rewards rank Artisan at 30 Favor and leave unknown future rewards unranked", function()
    fixture(function(f)
        local saved = addon.Crates
        addon.Crates = {}
        for _, id in ipairs({ 248683, 248702, 248690, 248695, 999991 }) do
            addon.Crates[id] = {
                name = "Crate " .. id,
                options = {
                    { itemID = 2770, quantity = 20 },
                    {
                        itemID = 2771,
                        quantity = 20,
                    },
                },
            }
        end
        local ok, err = pcall(function()
            f.price(2770, 1)
            f.price(248683, 10)
            f.price(248702, 30)
            f.price(248690, 60)
            f.price(248695, 1)
            f.price(999991, 1)
            local rows = Shopping.Entries("crates")
            equal(rows[1].itemID, 248695)
            equal(rows[1].total, 21)
            equal(rows[1].reward, 30)
            equal(rows[1].unitCost, 21 / 30)
            equal(rows[2].itemID, 248702)
            equal(rows[2].total, 50)
            equal(rows[2].reward, 10)
            equal(rows[2].unitCost, 5)
            equal(rows[3].itemID, 248690)
            equal(rows[3].reward, 15)
            equal(rows[4].itemID, 248683)
            equal(rows[4].total, 30)
            equal(rows[4].unitCost, 6)
            equal(rows[5].itemID, 999991)
            equal(rows[5].total, 21)
            equal(rows[5].reward, nil)
            equal(rows[5].unitCost, nil)
            local host = CreateFrame("Frame", nil, UIParent)
            host:SetSize(700, 550)
            local view = addon.BrowseUI.Create(host, "crates")
            addon.BrowseUI.Refresh(view)
            equal(#view.headers, 5)
            equal(view.headers[5].text, addon.L["Cost / Favor"])
            equal(view.headers[5].sortArrow:IsShown(), true)
            equal(view.scroll.rows[1].reward.text, string.format(addon.L["%d Favor"], 30))
            equal(view.scroll.rows[1].unitCost.text, addon.Money(1))
            equal(view.scroll.rows[5].reward.text, addon.L["Reward unknown"])
            equal(view.scroll.rows[5].unitCost.text, "—")
            host:Hide()
            addon.BrowseUI.views.crates = nil
        end)
        addon.Crates = saved
        assert(ok, err)
    end)
end)

test("reward metadata covers audited tiers without guessing new IDs or localization", function()
    for _, range in ipairs({ { 264011, 264055, 75 }, { 264056, 264115, 125 }, { 264116, 264160, 200 } }) do
        for id = range[1], range[2] do
            equal(addon.Rewards.Amount("writs", id), range[3])
        end
    end
    equal(addon.Rewards.Amount("writs", 264010), nil)
    equal(addon.Rewards.Amount("writs", 264161), nil)
    equal(addon.Rewards.Amount("crates", 248690), 15)
    equal(addon.Rewards.Amount("crates", 248691), 15)
    for _, id in ipairs({ 248695, 248696, 248697, 248698, 248699, 248711, 248712, 248713 }) do
        equal(addon.Rewards.Amount("crates", id), 30)
    end
    equal(addon.Rewards.Amount("crates", 264050), nil)
    equal(addon.Rewards.Amount("invalid", 264050), nil)
    equal(addon.Rewards.UnitCost(10, 0), nil)
    equal(addon.Rewards.UnitCost(nil, 75), nil)
    equal(addon.Rewards.UnitCost(0, 75), 0)
end)

test("efficiency sorting preserves sub-copper differences and stable ties", function()
    local rows = {
        { unitCost = 101 / 75, total = 101, name = "A", itemID = 1 },
        { unitCost = 160 / 125, total = 160, name = "Z", itemID = 2 },
        { unitCost = 101 / 75, total = 101, name = "A", itemID = 3 },
        { total = 1, name = "Unknown reward", itemID = 4 },
        { reward = 75, name = "Unknown price", itemID = 5 },
    }
    table.sort(rows, Shopping.Less)
    equal(rows[1].itemID, 2)
    equal(rows[2].itemID, 1)
    equal(rows[3].itemID, 3)
    equal(rows[4].itemID, 4)
    equal(rows[5].itemID, 5)
end)
test("crate browse selects the cheapest full option across usable scans and estimates", function()
    fixture(function(f, market)
        f.price(248683, 50)
        f.price(2771, 3)
        market.items[2770] = { kind = "item", scannedAt = time(), offers = { { quantity = 25, buyoutAmount = 250 } } }
        local entry = Shopping.Entry("crates", 248683)
        equal(entry.optionIndex, 2)
        equal(entry.delivery, 60)
        equal(entry.total, 110)
        f.price(2771, 30)
        entry = Shopping.Entry("crates", 248683)
        equal(entry.optionIndex, 1)
        equal(entry.delivery, 250)
        equal(entry.total, 300)
        equal(entry.requirements[1].quantity, 20)
    end)
end)
test("missing purchase or delivery prices never turn into zero totals", function()
    fixture(function(f)
        f.price(4245, 400)
        local entry = Shopping.Entry("writs", 264050)
        equal(entry.delivery, 400)
        equal(entry.purchase, nil)
        equal(entry.total, nil)
        equal(entry.canShop, true)
        f.price(264050, 100)
        f.prices.auctionator[4245] = nil
        entry = Shopping.Entry("writs", 264050)
        equal(entry.delivery, nil)
        equal(entry.total, nil)
        entry = Shopping.Entry("crates", 248683)
        equal(entry.canShop, false)
        equal(entry.total, nil)
        equal(Shopping.Terms(entry), nil)
    end)
end)
test("observed crate shortages cannot become the selected shopping option", function()
    fixture(function(f, market)
        f.price(2770, 1)
        f.price(2771, 3)
        market.items[2770] = { kind = "commodity", scannedAt = time(), offers = {} }
        local entry = Shopping.Entry("crates", 248683)
        equal(entry.optionIndex, 2)
        market.items[2771] = { kind = "commodity", scannedAt = time(), offers = {} }
        entry = Shopping.Entry("crates", 248683)
        equal(entry.canShop, false)
    end)
end)
test("stale totals remain labelled and numeric ties sort deterministically", function()
    fixture(function(f)
        f.price(264050, 100, "auctionator", true)
        f.price(4245, 400)
        local entry = Shopping.Entry("writs", 264050)
        equal(entry.total, 500)
        equal(entry.stale, true)
        local rows = {
            { total = 5, name = "Same", itemID = 3 },
            { total = 5, name = "Same", itemID = 1 },
            { name = "A", itemID = 4 },
            { total = 2, name = "Z", itemID = 2 },
        }
        table.sort(rows, Shopping.Less)
        equal(rows[1].itemID, 2)
        equal(rows[2].itemID, 1)
        equal(rows[3].itemID, 3)
        equal(rows[4].itemID, 4)
    end)
end)
test("purchase quotes follow writ settings and custom-profile isolation without enlarging scans", function()
    fixture(function(f)
        f.price(264050, 100)
        f.price(4245, 400)
        f.price(264050, 200, "tsm")
        f.price(4245, 500, "tsm")
        addon.db.writSource = "tsm"
        local entry = Shopping.Entry("writs", 264050)
        equal(entry.total, 700)
        addon.db.writSource = "off"
        entry = Shopping.Entry("writs", 264050)
        equal(entry.total, nil)
        addon.db.writSource = "auto"
        addon.db.profile = "neutral"
        entry = Shopping.Entry("writs", 264050)
        equal(entry.total, nil)
        addon.db.profile = "default"
        addon.db.source = "own"
        f.price(248683, 50)
        entry = Shopping.Entry("crates", 248683)
        equal(entry.purchase, nil)
        equal(entry.delivery, nil)
        local before = #addon.scanner.requests
        Shopping.Entries("writs")
        Shopping.Entries("crates")
        equal(#addon.scanner.requests, before)
        equal(#addon.Catalog.Materials(addon.Catalog.AllCrates()), 96)
    end)
end)
test("writ row shopping includes the writ plus 200 ammo and stops a running scan first", function()
    fixture(function(f)
        addon:StartScan("all")
        assert(addon.scanner.active)
        equal(addon:ShopEntry("writs", 264037), true)
        equal(#f.searches, 1)
        equal(#f.searches[1], 2)
        equal(f.searches[1][1].searchString, "Craftsman's Writ: Crafted Solid Shot")
        equal(f.searches[1][1].quantity, 1)
        equal(f.searches[1][2].searchString, "Crafted Solid Shot")
        equal(f.searches[1][2].quantity, 200)
        equal(f.searches[1][1].isExact, true)
        equal(f.searches[1][2].isExact, true)
        equal(addon.autoPaused, true)
    end)
end)
test("crate row shopping reprices on click and includes exactly one chosen alternative", function()
    fixture(function(f)
        f.price(2770, 1)
        f.price(2771, 2)
        local entry = Shopping.Entry("crates", 248683)
        equal(entry.optionIndex, 1)
        f.price(2770, 3)
        equal(addon:ShopEntry("crates", 248683), true)
        equal(#f.searches[1], 2)
        equal(f.searches[1][1].quantity, 1)
        equal(f.searches[1][1].searchString, addon.Crates[248683].name)
        equal(f.searches[1][2].searchString, "Tin Ore")
        equal(f.searches[1][2].quantity, 20)
        equal(addon.lastBasket.optionIndex, 2)
    end)
end)
test("basket shopping validates AH, addon, item and localized names before interrupting scans", function()
    fixture(function(f)
        addon.scanner:SetOpen(false)
        equal(addon:ShopEntry("writs", 264050), false)
        addon.scanner:SetOpen(true)
        local api = Auctionator
        Auctionator = nil
        equal(addon:ShopEntry("writs", 264050), false)
        Auctionator = api
        equal(addon:ShopEntry("writs", 999999), false)
        equal(addon:ShopEntry("invalid", 264050), false)
        addon:StartScan("all")
        assert(addon.scanner.active)
        GetLocale = function()
            return "esES"
        end
        local requested
        C_Item.GetItemNameByID = function() end
        C_Item.RequestLoadItemDataByID = function(id)
            requested = id
        end
        equal(addon:ShopEntry("writs", 264050), false)
        equal(requested, 264050)
        equal(addon.scanner.active, true)
        C_Item.GetItemNameByID = function(id)
            return id == 264050 and "Escrito" or "Bolsa"
        end
        equal(addon:ShopEntry("writs", 264050), true)
        equal(f.searches[1][1].searchString, "Escrito")
        equal(f.searches[1][2].searchString, "Bolsa")
    end)
end)
test("a rejected Auctionator basket preserves prices and does not restart our scanner", function()
    fixture(function(f, market)
        f.price(264050, 100)
        f.price(4245, 400)
        market.items[2770] = { kind = "commodity", scannedAt = time(), offers = {} }
        Auctionator.API.v1.MultiSearchAdvanced = function()
            error("failed handoff")
        end
        addon:StartScan("all")
        equal(addon:ShopEntry("writs", 264050), false)
        equal(addon.scanner.active, false)
        equal(addon.autoDue, nil)
        assert(market.items[2770])
        assert(addon.Providers.errors.auctionator:match("failed handoff"))
    end)
end)
test("browse rows render ranked totals, filter delivery names, and route clicks to basket shopping", function()
    fixture(function(f)
        f.price(264050, 100)
        f.price(4245, 400)
        f.price(264037, 40)
        f.price(8069, 3)
        local host = CreateFrame("Frame", nil, UIParent)
        host:SetSize(1000, 550)
        local view = addon.BrowseUI.Create(host, "writs")
        addon.BrowseUI.Refresh(view)
        equal(view.headers[5].text, addon.L["Cost / reputation"])
        equal(view.headers[5].sortArrow:IsShown(), true)
        equal(view.scroll.rows[1].unitCost.text, addon.Money(7))
        equal(view.scroll.rows[1].reward.text, string.format(addon.L["%d rep"], 75))
        equal(#view.visibleEntries, 150)
        equal(#view.scroll.rows, 10)
        equal(view.scroll.rows[1].entry.itemID, 264050)
        assert(not view.scroll.rows[1].total.text:match("~"))
        assert(view.scroll.rows[1].deliveryName.text:match("Small Silk Pack"))
        view.scroll.rows[1].scripts.OnClick(view.scroll.rows[1])
        equal(#f.searches[1], 2)
        view.search:SetText("Crafted Solid Shot")
        view.search.scripts.OnTextChanged(view.search)
        equal(#view.visibleEntries, 1)
        equal(view.scroll.rows[1].entry.itemID, 264037)
        view.scroll.rows[1].scripts.OnClick(view.scroll.rows[1])
        equal(#f.searches, 2)
        equal(f.searches[2][1].searchString, "Craftsman's Writ: Crafted Solid Shot")
        equal(f.searches[2][2].quantity, 200)
        equal(view.scroll.template, "WowScrollBoxList")
        equal(view.scrollBar.template, "WowClassicScrollBar")
        equal(view.inset.template, "InsetFrameTemplate")
        local rail = view.scrollBar.Background.Middle.color
        equal(rail[1], 0.08)
        equal(rail[2], 0.08)
        equal(rail[3], 0.08)
        equal(rail[4], 1)
        local previousEnd = 0
        for _, header in ipairs(view.headers) do
            equal(header.template, "ColumnDisplayButtonNoScriptsTemplate")
            assert(header.point[4] >= previousEnd)
            previousEnd = header.point[4] + header:GetWidth()
        end
        assert(previousEnd <= host:GetWidth() - 42)
        equal(view.scroll.rows[2]:IsShown(), false)
        equal(view.scroll.offset, 0)
        view.search:SetText("does not exist")
        view.search.scripts.OnTextChanged(view.search)
        equal(#view.visibleEntries, 0)
        equal(view.empty:IsShown(), true)
        host:Hide()
        addon.BrowseUI.views.writs = nil
    end)
end)
test(
    "clickable headers sort both tables without repricing and preserve selection through filtering and refresh",
    function()
        fixture(function(f)
            f.price(264050, 100)
            f.price(4245, 400)
            f.price(264037, 40)
            f.price(8069, 3)
            local host = CreateFrame("Frame", nil, UIParent)
            host:SetSize(900, 550)
            local view = addon.BrowseUI.Create(host, "writs")
            addon.BrowseUI.Refresh(view)
            equal(view.sortKey, "unitCost")
            equal(view.sortDescending, false)
            local reads, requests = f.reads, #addon.scanner.requests
            for index, key in ipairs({ "name", "purchase", "delivery", "total", "unitCost" }) do
                local header = view.headers[index]
                view.scroll.offset = 10
                header.scripts.OnClick(header)
                equal(view.sortKey, key)
                equal(view.sortDescending, false)
                equal(view.scroll.offset, 0)
                equal(header.text, header.sortTitle)
                equal(header.sortArrow.texture, "Interface\\Buttons\\UI-SortArrow")
                equal(header.sortArrow:GetWidth(), 9)
                equal(header.sortArrow:GetHeight(), 8)
                equal(header.sortArrow.texCoord[1], 0)
                equal(header.sortArrow.texCoord[2], 0.5625)
                equal(header.sortArrow.texCoord[3], 1)
                equal(header.sortArrow.texCoord[4], 0)
                for _, candidate in ipairs(view.headers) do
                    equal(candidate.sortArrow:IsShown(), candidate == header)
                end
                for n = 2, #view.visibleEntries do
                    equal(Shopping.Compare(view.visibleEntries[n], view.visibleEntries[n - 1], key, false), false)
                end
                header.scripts.OnClick(header)
                equal(view.sortDescending, true)
                equal(header.text, header.sortTitle)
                equal(header.sortArrow.texCoord[3], 0)
                equal(header.sortArrow.texCoord[4], 1)
                for n = 2, #view.visibleEntries do
                    equal(Shopping.Compare(view.visibleEntries[n], view.visibleEntries[n - 1], key, true), false)
                end
            end
            equal(f.reads, reads)
            equal(#addon.scanner.requests, requests)
            view.headers[2].scripts.OnClick(view.headers[2])
            equal(view.sortKey, "purchase")
            equal(view.sortDescending, false)
            view.search:SetText("Crafted Solid Shot")
            view.search.scripts.OnTextChanged(view.search)
            equal(#view.visibleEntries, 1)
            equal(view.visibleEntries[1].itemID, 264037)
            view.headers[2].scripts.OnClick(view.headers[2])
            addon.BrowseUI.Refresh(view)
            equal(view.sortKey, "purchase")
            equal(view.sortDescending, true)
            equal(#view.visibleEntries, 1)
            view.search:SetText("")
            view.search.scripts.OnTextChanged(view.search)
            equal(view.visibleEntries[1].itemID, 264050)
            equal(view.visibleEntries[2].itemID, 264037)
            equal(view.visibleEntries[3].purchase, nil)
            local other = addon.BrowseUI.Create(host, "crates")
            addon.BrowseUI.Refresh(other)
            equal(other.sortKey, "unitCost")
            equal(other.sortDescending, false)
            equal(view.sortKey, "purchase")
            equal(view.sortDescending, true)
            host:Hide()
            addon.BrowseUI.views.writs = nil
            addon.BrowseUI.views.crates = nil
        end)
    end
)

test("hidden browse panels do not read provider prices on unrelated tooltip updates", function()
    fixture(function(f)
        local host = CreateFrame("Frame", nil, UIParent)
        host:Hide()
        addon.BrowseUI.Create(host, "writs")
        addon.BrowseUI.UpdateVisible()
        equal(f.reads, 0)
        addon.BrowseUI.views.writs = nil
    end)
end)

test("row shopping requires a tab-switching API while legacy list creation stays available", function()
    fixture(function(_f)
        Auctionator.API.v1 = {
            ConvertToSearchString = function()
                return "term"
            end,
            CreateShoppingList = function() end,
        }
        equal(addon.Providers.ShoppingAvailable(), true)
        equal(addon.Providers.ShoppingAvailable(true), false)
        addon:StartScan("all")
        equal(addon:ShopEntry("writs", 264050), false)
        equal(addon.scanner.active, true)
    end)
end)

test("item hover does not rebuild the native list and recycle the button under the pointer", function()
    fixture(function(f)
        f.price(248683, 50)
        f.price(2770, 1)
        f.price(2771, 2)
        local host = CreateFrame("Frame", nil, UIParent)
        host:SetSize(1000, 550)
        local view = addon.BrowseUI.Create(host, "crates")
        addon.BrowseUI.Refresh(view)
        local calls = 0
        local original = view.scroll.SetDataProvider
        view.scroll.SetDataProvider = function(self, ...)
            calls = calls + 1
            return original(self, ...)
        end
        local oldTip = GameTooltip
        GameTooltip = CreateFrame("GameTooltip")
        GameTooltip.SetItemByID = function(tip, id)
            addon.Tooltip.Append(tip, id)
        end
        local row = view.scroll.rows[1]
        equal(row.entry.itemID, 248683)
        addon.BrowseUI.ShowTooltip(row)
        equal(calls, 0)
        equal(row.entry.itemID, 248683)
        GameTooltip = oldTip
        host:Hide()
        addon.BrowseUI.views.crates = nil
    end)
end)

test("price refresh keeps row objects until sorting or filtering actually changes the list", function()
    fixture(function(f)
        f.price(264050, 100)
        f.price(4245, 400)
        f.price(264037, 40)
        f.price(8069, 3)
        local host = CreateFrame("Frame", nil, UIParent)
        host:SetSize(1000, 550)
        local view = addon.BrowseUI.Create(host, "writs")
        addon.BrowseUI.Refresh(view)
        local row, entry, provider = view.scroll.rows[1], view.visibleEntries[1], view.scroll.provider
        local calls, original = 0, view.scroll.SetDataProvider
        view.scroll.SetDataProvider = function(self, ...)
            calls = calls + 1
            return original(self, ...)
        end
        for _ = 1, 30 do
            addon.BrowseUI.Refresh(view)
        end
        equal(calls, 0)
        equal(view.scroll.provider, provider)
        equal(row.entry, entry)
        f.price(4245, 410)
        addon.BrowseUI.Refresh(view)
        equal(calls, 0)
        equal(entry.total, 510)
        equal(row.total.text, addon.Money(510))
        equal(view.visibleEntries[1], entry)
        -- Updating daily status should repaint the existing native row.
        local oldQuestLog = C_QuestLog
        C_QuestLog = {
            IsQuestFlaggedCompleted = function(questID)
                return questID == 94250
            end,
        }
        addon.BrowseUI.Refresh(view)
        equal(row.deliveryName.text:match("^Delivered today"), "Delivered today")
        equal(view.scroll.provider, provider)
        C_QuestLog = oldQuestLog
        addon.BrowseUI.Refresh(view)
        equal(row.deliveryName.text:match("^Delivered today"), nil)
        equal(view.scroll.provider, provider)
        -- Fresh quote details must also be available after scrolling offscreen.
        view.sortKey = "name"
        addon.BrowseUI.Render(view)
        local last = view.visibleEntries[#view.visibleEntries]
        f.price(last.itemID, 123)
        local before = calls
        addon.BrowseUI.Refresh(view)
        equal(calls, before)
        equal(last.purchase, 123)
        view.scroll:ScrollToElementDataIndex(#view.visibleEntries, ScrollBoxConstants.AlignNearest, 0, true)
        equal(view.scroll:FindFrame(last).purchase.text, addon.Money(123))
        -- Return to price sorting, then make the second basket cheaper.
        view.sortKey = "unitCost"
        addon.BrowseUI.Render(view)
        f.price(4245, 900)
        addon.BrowseUI.Refresh(view)
        equal(view.visibleEntries[1].itemID, 264037)
        assert(calls > before)
        view.query = "does not exist"
        addon.BrowseUI.Render(view)
        equal(#view.visibleEntries, 0)
        equal(view.empty:IsShown(), true)
        host:Hide()
        addon.BrowseUI.views.writs = nil
    end)
end)
