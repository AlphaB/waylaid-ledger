local addon, test, equal, host = ...

local function fixture(action)
    local old = {
        auctionator = Auctionator,
        tsm = TSM_API,
        ah = AuctionHouseFrame,
        contexts = AuctionHouseSearchContext,
        ahMixin = AuctionHouseFrameMixin,
        owned = addon.Navigation.auctionOwned,
        cleanup = addon.Navigation.auctionCleanupPending,
        modes = AuctionHouseFrameDisplayMode,
        source = addon.db.source,
        writSource = addon.db.writSource,
        profile = addon.db.profile,
        clock = GetTime,
        nav = SmartNavigation,
        input = InputUtil,
        gamepad = GamepadMode,
        combat = InCombatLockdown,
        ignored = SmartNavigation_MarkFrameIgnored,
        jump = SmartNavigation_AddJumpNavigationOverride,
        directions = SMART_NAV_INPUT_DIRECTION,
        registered = addon.Navigation.registered,
        views = addon.BrowseUI.views,
        uiHost = addon.UI.auctionHost,
        hosts = addon.UI.auctionHosts,
        browserTab = addon.db.browserTab,
        read = addon.Providers.Read,
    }
    addon:StopScan()
    Auctionator, TSM_API = nil, nil
    addon.db.source, addon.db.writSource, addon.db.profile = "auto", "auto", "default"
    addon.Providers.Invalidate()
    local market = addon:GetMarket()
    old.items, old.failures = market.items, market.failures
    market.items, market.failures = {}, {}
    local f = { now = 1000, queries = {}, commodity = true, ready = true, navCalls = {}, targets = {} }
    GetTime = function()
        return f.now
    end
    -- Exercise the real scanner, event routing, saved cache and API hooks.
    local api = addon.scanner.api
    old.now, old.requests = addon.scanner.runtime.now, addon.scanner.requests
    addon.scanner.runtime.now = GetTime
    addon.scanner.requests = {}
    old.keyInfo = api.GetItemKeyInfo
    old.full, old.num, old.row, old.ready, old.quantity =
        api.HasFullCommoditySearchResults,
        api.GetNumCommoditySearchResults,
        api.GetCommoditySearchResultInfo,
        api.IsThrottledMessageSystemReady,
        api.GetCommoditySearchResultsQuantity
    api.GetItemKeyInfo = function()
        if not f.infoMissing then
            return { isCommodity = f.commodity, isEquipment = f.equipment }
        end
    end
    api.IsThrottledMessageSystemReady = function()
        return f.ready
    end
    api.GetCommoditySearchResultsQuantity = function()
        return f.stock or 1000
    end
    AuctionHouseSearchContext = { BuyCommodities = 1, BuyItems = 2 }
    AuctionHouseFrameDisplayMode = { Buy = "browse", CommoditiesBuy = "commodity", ItemBuy = "item" }
    AuctionHouseFrameMixin = { Event = { CommoditiesQuantitySelectionChanged = "quantity" } }
    AuctionHouseFrame = CreateFrame("Frame", nil, UIParent)
    AuctionHouseFrame.Tabs = { CreateFrame("Button", nil, AuctionHouseFrame) }
    AuctionHouseFrame.SetDisplayMode = function(_, mode)
        f.mode = mode
    end
    AuctionHouseFrame.CommoditiesBuyFrame = {
        BuyDisplay = {
            SetQuantitySelected = function(_, quantity)
                f.quantity = quantity
            end,
        },
        ItemList = { quantitySelected = 1, RefreshScrollFrame = function() end },
        IsShown = function()
            return true
        end,
    }
    AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay.GetItemID = function()
        return f.selected
    end
    AuctionHouseFrame.TriggerEvent = function(_, event, quantity)
        equal(event, "quantity")
        AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay:SetQuantitySelected(quantity)
        AuctionHouseFrame.CommoditiesBuyFrame.ItemList.quantitySelected = quantity
    end
    AuctionHouseFrame.ItemBuyFrame = {}
    AuctionHouseFrame.SelectBrowseResult = function(_, result)
        f.selected = result.itemKey.itemID
    end
    AuctionHouseFrame.QueryItem = function(_, context, key, byItemID)
        f.queries[#f.queries + 1] = { context = context, id = key.itemID, byItemID = byItemID }
        addon.scanner:ExternalQuery()
    end
    function f.snapshot(id, quantity, price, age)
        market.items[id] = {
            kind = "commodity",
            scannedAt = time() - (age or 0),
            offers = {
                { quantity = quantity, unitPrice = price },
            },
        }
    end
    function f.browser(kind)
        addon.UI.auctionHost = CreateFrame("Frame", nil, AuctionHouseFrame)
        local page = CreateFrame("Frame", nil, addon.UI.auctionHost)
        page:SetSize(900, 550)
        addon.UI.auctionHosts = { [kind] = page }
        addon.db.browserTab = kind
        addon.BrowseUI.views = {}
        f.focus = AuctionHouseFrame
        return addon.BrowseUI.Create(page, kind)
    end
    function f.navigation()
        f.hiddenFrames = {}
        f.shownFrames = {}
        f.focus = AuctionHouseFrame
        f.last = {}
        f.targetsByOwner = {}
        InputUtil = {
            IsGamepadUIEnabled = function()
                return true
            end,
            RegisterForInterfaceTransitions = function() end,
            RegisterGamepadInit = function(_, callback)
                f.transition = callback
            end,
        }
        InCombatLockdown = function()
            return f.combat or false
        end
        SMART_NAV_INPUT_DIRECTION = { UP = "up", DOWN = "down" }
        SmartNavigation_MarkFrameIgnored = function(frame)
            frame.navIgnored = true
        end
        SmartNavigation_AddJumpNavigationOverride = function(row, direction, callback)
            row.overrides = rawget(row, "overrides") or {}
            row.overrides[direction] = callback
        end
        SmartNavigation = {
            GetCurrentButton = function()
                return f.current
            end,
            RefreshButtonGroups = function(_, owner)
                f.navCalls[#f.navCalls + 1] = owner
            end,
            SetScrollFrameForFrame = function(_, owner, scroll)
                f.scrollOwner, f.scroll = owner, scroll
            end,
            SetTargetButtonForFrame = function(_, owner, target)
                f.target = target
                f.targetsByOwner[owner] = target
                if target then
                    f.targets[#f.targets + 1] = target
                    if f.focus == owner then
                        f.current = target
                    end
                end
            end,
        }
        GamepadMode = {
            FrameControlsManager = {
                GetActiveFrame = function()
                    return f.focus
                end,
                FrameShown = function(_, frame)
                    f.shown = frame
                    f.shownFrames[frame] = true
                    if f.focus then
                        f.last[f.focus] = f.current
                    end
                    f.focus = frame
                    f.current = f.last[frame] or f.targetsByOwner[frame]
                end,
                FrameHidden = function(_, frame)
                    f.hidden = frame
                    f.hiddenFrames[frame] = true
                end,
                FocusFrame = function()
                    error("unwrapped FocusFrame must not be called")
                end,
            },
        }
        addon.Navigation.registered = nil
        addon.Navigation.Install()
    end
    addon.scanner:SetOpen(true)
    addon.autoPaused = false
    addon.lastExternalAt = nil
    local ok, err = pcall(action, f, market)
    addon:StopScan()
    addon.NativeShopping.Close()
    addon.scanner.api.GetItemKeyInfo = old.keyInfo
    api.HasFullCommoditySearchResults, api.GetNumCommoditySearchResults, api.GetCommoditySearchResultInfo, api.IsThrottledMessageSystemReady =
        old.full, old.num, old.row, old.ready
    api.GetCommoditySearchResultsQuantity = old.quantity
    addon.scanner.runtime.now, addon.scanner.requests = old.now, old.requests
    Auctionator, TSM_API, AuctionHouseFrame, AuctionHouseSearchContext = old.auctionator, old.tsm, old.ah, old.contexts
    AuctionHouseFrameMixin = old.ahMixin
    AuctionHouseFrameDisplayMode = old.modes
    addon.Navigation.auctionOwned, addon.Navigation.auctionCleanupPending = old.owned, old.cleanup
    addon.db.source, addon.db.writSource, addon.db.profile = old.source, old.writSource, old.profile
    market.items, market.failures = old.items, old.failures
    GetTime, SmartNavigation, InputUtil, GamepadMode, InCombatLockdown =
        old.clock, old.nav, old.input, old.gamepad, old.combat
    SmartNavigation_MarkFrameIgnored, SmartNavigation_AddJumpNavigationOverride = old.ignored, old.jump
    SMART_NAV_INPUT_DIRECTION, addon.Navigation.registered = old.directions, old.registered
    addon.BrowseUI.views, addon.UI.auctionHost, addon.UI.auctionHosts = old.views, old.uiHost, old.hosts
    addon.db.browserTab, addon.Providers.Read = old.browserTab, old.read
    addon.autoPaused = false
    addon.Providers.Invalidate()
    addon:UpdateScheduler()
    assert(ok, err)
end

test("standalone scan catalogs cover purchases, all alternatives and all writ goods exactly once", function()
    fixture(function()
        equal(#addon.Shopping.ScanItems("writs"), 300)
        equal(#addon.Shopping.ScanItems("crates"), 126)
        local ids = addon.Shopping.ScanItems("crates", false, 248683)
        equal(#ids, 3)
        equal(ids[1], 2770)
        equal(ids[2], 2771)
        equal(ids[3], 248683)
        equal(#addon.Shopping.ScanItems("writs", false, 264037), 2)
    end)
end)

test("native equipment baskets query all item variants while commodities keep their exact query", function()
    fixture(function(f)
        f.commodity, f.equipment = false, true
        equal(addon.NativeShopping.OpenItem({ itemID = 4245, quantity = 1 }), true)
        equal(f.queries[1].byItemID, true)
        f.commodity, f.equipment = true, false
        equal(addon.NativeShopping.OpenItem({ itemID = 8069, quantity = 200 }), true)
        equal(f.queries[2].byItemID, false)
        equal(f.quantity, 200)
    end)
end)

test("pending native quantities follow matching fresh responses and cancel on competing searches", function()
    fixture(function(f)
        addon.NativeShopping.OpenItem({ itemID = 8069, quantity = 200 })
        local list = AuctionHouseFrame.CommoditiesBuyFrame.ItemList
        equal(addon.NativeShopping.pendingQuantity.quantity, 200)
        addon.NativeShopping.Results(2770)
        list:RefreshScrollFrame()
        equal(addon.NativeShopping.pendingQuantity.responded, nil)
        addon.NativeShopping.ExternalQuery("RequestMoreCommoditySearchResults", 8069)
        assert(addon.NativeShopping.pendingQuantity)
        f.stock = 100
        addon.NativeShopping.Results(8069)
        list:RefreshScrollFrame()
        equal(f.quantity, 200)
        assert(addon.NativeShopping.pendingQuantity)
        f.stock = 1000
        addon.NativeShopping.Results(8069)
        list:RefreshScrollFrame()
        equal(f.quantity, 200)
        equal(addon.NativeShopping.pendingQuantity, nil)
        addon.NativeShopping.OpenItem({ itemID = 8069, quantity = 200 })
        addon.NativeShopping.ExternalQuery("SendSearchQuery", { itemID = 2770 })
        equal(addon.NativeShopping.pendingQuantity, nil)
        addon.NativeShopping.OpenItem({ itemID = 8069, quantity = 200 })
        f.selected = 2770
        addon.NativeShopping.CancelIfHidden()
        equal(addon.NativeShopping.pendingQuantity, nil)
    end)
end)

test("Auto scans only provider misses, stale estimates and failed snapshots while Own ignores providers", function()
    fixture(function(f, market)
        addon.Providers.Read = function(source, id)
            if source == "auctionator" and id == 2770 then
                return { unitPrice = 1 }
            end
            if source == "tsm" and id == 2771 then
                return { unitPrice = 2, stale = true }
            end
        end
        f.snapshot(248683, 1, 10)
        local ids = addon.Shopping.ScanItems("crates", false, 248683)
        equal(#ids, 1)
        equal(ids[1], 2771)
        addon.db.source = "own"
        equal(#addon.Shopping.ScanItems("crates", false, 248683), 2)
        market.failures[248683] = "timeout"
        equal(#addon.Shopping.ScanItems("crates", false, 248683), 3)
        addon.db.source = "auctionator"
        equal(#addon.Shopping.ScanItems("crates"), 0)
        addon.db.writSource = "off"
        equal(#addon.Shopping.ScanItems("writs"), 0)
    end)
end)

test("own writ and purchase prices use real depth, shortages, failures and market isolation", function()
    fixture(function(f, market)
        addon.db.writSource = "own"
        f.snapshot(264037, 1, 50)
        market.items[8069] = {
            kind = "commodity",
            scannedAt = time(),
            offers = { { quantity = 100, unitPrice = 2 }, { quantity = 100, unitPrice = 4 } },
        }
        local entry = addon.Shopping.Entry("writs", 264037)
        equal(entry.purchase, 50)
        equal(entry.delivery, 600)
        equal(entry.total, 650)
        equal(entry.purchaseQuote.source, "own")
        equal(entry.deliveryRows[1].source, "own")
        market.items[8069].offers[2] = nil
        equal(addon.Shopping.Entry("writs", 264037).total, nil)
        f.snapshot(8069, 200, 2)
        market.failures[264037] = "timeout"
        equal(addon.Shopping.Entry("writs", 264037).total, nil)
        market.failures[264037] = nil
        market.failures[8069] = "timeout"
        equal(addon.Shopping.Entry("writs", 264037).total, nil)
        market.failures[8069] = nil
        addon.db.profile = "neutral"
        equal(addon.Shopping.Entry("writs", 264037).total, nil)
        addon.db.profile = "default"
        equal(addon.Shopping.Entry("writs", 264037).total, 450)
    end)
end)

test("opening the Writs list queues fallback scanning independently of crate source and tracking", function()
    fixture(function(f, market)
        f.browser("writs")
        addon.db.source = "tsm"
        addon:RequestBrowseScan()
        equal(addon.autoReason, "browse")
        f.now = f.now + 1
        host.scripts.OnUpdate()
        equal(addon.scanner.active, true)
        equal(#addon.scanner.queue, 300)
        local id = addon.scanner.pending.itemID
        host.scripts.OnEvent(host, "COMMODITY_SEARCH_RESULTS_UPDATED", id)
        -- The initial API fixture isn't full; incomplete results cannot be saved.
        equal(market.items[id], nil)
        addon:StopScan()
        addon:RequestBrowseScan()
        equal(addon.autoDue, nil)
        addon.autoPaused = false
        addon:RequestBrowseScan()
        assert(addon.autoDue)
        host.scripts.OnEvent(host, "AUCTION_HOUSE_CLOSED")
        equal(addon.autoDue, nil)
        equal(addon.scanner.active, false)
        equal(host.scripts.OnUpdate, nil)
    end)
end)

test(
    "full standalone writ scan populates ranked baskets through production events and shares the rolling budget",
    function()
        fixture(function(f)
            local api = addon.scanner.api
            api.HasFullCommoditySearchResults = function()
                return true
            end
            api.GetNumCommoditySearchResults = function()
                return 1
            end
            api.GetCommoditySearchResultInfo = function()
                return { quantity = 1000, unitPrice = 3 }
            end
            f.browser("writs")
            addon:RequestBrowseScan()
            f.now = f.now + 1
            host.scripts.OnUpdate()
            local count, waits = 0, 0
            while addon.scanner.active do
                local pending = addon.scanner.pending
                if pending and pending.sentAt then
                    host.scripts.OnEvent(host, "COMMODITY_SEARCH_RESULTS_UPDATED", pending.itemID)
                    count = count + 1
                elseif #addon.scanner.requests >= 100 then
                    f.now = f.now + 60.2
                    waits = waits + 1
                end
                f.now = f.now + 0.051
                if host.scripts.OnUpdate then
                    host.scripts.OnUpdate()
                end
                assert(count <= 300)
            end
            equal(count, 300)
            equal(waits, 2)
            equal(addon.Shopping.Entry("writs", 264037).total, 603)
            equal(#addon.Shopping.ScanItems("writs"), 0)
            for _, entry in ipairs(addon.Shopping.Entries("writs")) do
                assert(entry.total)
            end
            equal(host.scripts.OnUpdate, nil)
        end)
    end
)

test("native baskets keep full quantities and open Blizzard buy screens without Auctionator", function()
    fixture(function(f)
        equal(addon:ShopEntry("writs", 264037), true, "show basket")
        equal(#addon.NativeShopping.requirements, 2)
        equal(addon.NativeShopping.requirements[1].itemID, 264037)
        equal(addon.NativeShopping.requirements[2].quantity, 200)
        equal(addon:StartBrowseScan("writs"), true, "start scan")
        f.now = f.now + 1
        local ok = addon.NativeShopping.OpenItem(addon.NativeShopping.requirements[2])
        equal(ok, true, "open item")
        equal(f.selected, 8069)
        equal(f.quantity, 200)
        local list = AuctionHouseFrame.CommoditiesBuyFrame.ItemList
        equal(list.quantitySelected, 200)
        -- This is the event that the native results list publishes after its
        -- asynchronous refresh; it must not revert the display to one.
        AuctionHouseFrame:TriggerEvent("quantity", list.quantitySelected)
        equal(f.quantity, 200)
        equal(f.queries[1].context, AuctionHouseSearchContext.BuyCommodities)
        equal(f.mode, AuctionHouseFrameDisplayMode.Buy)
        equal(addon.scanner.active, false)
        equal(addon.autoPaused, true)
        f.commodity = false
        equal(addon.NativeShopping.OpenItem({ itemID = 264037, quantity = 1 }), true, "open writ")
        equal(f.queries[2].context, AuctionHouseSearchContext.BuyItems)
        equal(f.queries[2].id, 264037)
        host.scripts.OnEvent(host, "AUCTION_HOUSE_CLOSED")
        equal(addon.NativeShopping.frame:IsShown(), false)
    end)
end)

test(
    "native shopping validates uncached item data, readiness and the shared budget before interrupting scans",
    function()
        fixture(function(f)
            addon:StartBrowseScan("crates")
            f.infoMissing = true
            equal(addon.NativeShopping.OpenItem({ itemID = 2770, quantity = 20 }), false)
            equal(addon.scanner.active, true)
            equal(#f.queries, 0)
            f.infoMissing = false
            f.ready = false
            equal(addon.NativeShopping.OpenItem({ itemID = 2770, quantity = 20 }), false)
            equal(addon.scanner.active, true)
            f.ready = true
            for _ = 1, 100 do
                addon.scanner:RecordRequest()
            end
            equal(addon.NativeShopping.OpenItem({ itemID = 2770, quantity = 20 }), false)
            equal(addon.scanner.active, true)
            f.now = f.now + 60.2
            equal(addon.NativeShopping.OpenItem({ itemID = 2770, quantity = 20 }), true)
            equal(addon.scanner.active, false)
        end)
    end
)

test("native crate shopping reprices alternatives and legacy commands have a built-in fallback", function()
    fixture(function(f)
        f.snapshot(2770, 20, 10)
        f.snapshot(2771, 20, 3)
        equal(addon:ShopEntry("crates", 248683), true)
        equal(#addon.NativeShopping.requirements, 2)
        equal(addon.NativeShopping.requirements[2].itemID, 2771)
        addon.lastCrateID = 248683
        equal(addon:Shop(true), true)
        equal(#addon.NativeShopping.requirements, 2)
        equal(addon:Shop(false, 1), true)
        equal(#addon.NativeShopping.requirements, 1)
        equal(addon.NativeShopping.requirements[1].itemID, 2770)
    end)
end)

test("native controller can move through virtual rows and retains item identity across price resorting", function()
    fixture(function(f)
        f.navigation()
        local view = f.browser("writs")
        addon.BrowseUI.Refresh(view)
        equal(view.headers[1].navIgnored, true)
        equal(f.scroll, view.scroll)
        equal(f.scrollOwner, AuctionHouseFrame)
        f.current = view.scroll.rows[1]
        for index = 2, 25 do
            f.current = f.current.overrides.down()
            equal(f.current.entry.listIndex, index)
        end
        local itemID = f.current.entry.itemID
        f.snapshot(itemID, 1, 1)
        for _, requirement in ipairs(addon.Writs[itemID].requirements) do
            f.snapshot(requirement.itemID, 1000, 1)
        end
        addon.BrowseUI.Refresh(view)
        equal(f.current.entry.itemID, itemID)
        equal(f.current.entry.listIndex, 1)
        local clicked
        local shop = addon.ShopEntry
        addon.ShopEntry = function(_, _, id)
            clicked = id
        end
        f.current.scripts.OnClick(f.current)
        addon.ShopEntry = shop
        equal(clicked, itemID)
        view.search:SetText("no such writ")
        view.search.scripts.OnTextChanged(view.search)
        equal(#view.visibleEntries, 0)
        equal(f.current, view.search)
    end)
end)

test("controller windows register on show and hide, support late gamepad load and defer combat changes", function()
    fixture(function(f)
        local window = CreateFrame("Frame", nil, UIParent)
        window:Hide()
        addon.Navigation.RegisterWindow(window)
        f.navigation()
        window:Show()
        equal(f.shown, window)
        window:Hide()
        equal(f.hidden, window)
        window:Show()
        f.shown = nil
        f.shownFrames = {}
        f.transition()
        equal(f.shownFrames[window], true)
        local count = #f.navCalls
        f.combat = true
        addon.Navigation.Refresh(window)
        equal(#f.navCalls, count)
        f.hidden = nil
        f.hiddenFrames = {}
        window:Hide()
        equal(f.hidden, nil)
        f.combat = false
        host.scripts.OnEvent(host, "PLAYER_REGEN_ENABLED")
        equal(f.hiddenFrames[window], true)
    end)
end)

test("controller handoff uses wrapped lifecycle methods and leaving Waylaid clears owned scroll and targets", function()
    fixture(function(f)
        f.navigation()
        local view = f.browser("writs")
        addon.BrowseUI.Refresh(view)
        equal(f.scroll, view.scroll)
        f.current = view.scroll.rows[1]
        view.host:Hide()
        addon.Navigation.LeaveAuction()
        addon.Navigation.CleanupAuction()
        equal(f.scroll, nil)
        equal(f.target, nil)
        equal(f.current, AuctionHouseFrame.Tabs[1])
        f.focus = addon.NativeShopping.frame
        addon.Navigation.Focus(AuctionHouseFrame)
        equal(f.hidden, AuctionHouseFrame)
        equal(f.shown, AuctionHouseFrame)
        equal(f.focus, AuctionHouseFrame)
        f.hidden = nil
        addon.Navigation.Focus(AuctionHouseFrame)
        equal(f.hidden, nil)
    end)
end)

test("native basket handoff sets its cursor target after activating the auction panel", function()
    fixture(function(f)
        f.navigation()
        local view = f.browser("writs")
        addon.BrowseUI.Refresh(view)
        f.current = view.scroll.rows[1]
        equal(addon:ShopEntry("writs", 264037), true)
        view.host:Hide()
        addon.Navigation.LeaveAuction()
        addon.Navigation.CleanupAuction()
        addon.NativeShopping.OpenItem({ itemID = 8069, quantity = 200 })
        equal(f.focus, AuctionHouseFrame)
        equal(f.current, AuctionHouseFrame.Tabs[1])
        equal(addon.Navigation.auctionOwned, true)
        addon.Navigation.LeaveAuction()
        addon.Navigation.CleanupAuction()
        equal(f.scroll, nil)
        equal(f.target, nil)
    end)
end)

test("changing a crate price preference cannot stop or pause an independent writ scan", function()
    fixture(function(f)
        f.browser("writs")
        addon.db.writSource = "own"
        addon:RequestBrowseScan()
        f.now = f.now + 1
        host.scripts.OnUpdate()
        equal(addon.scanner.active, true)
        equal(addon.scanContext.category, "writs")
        addon:SetSource("tsm")
        equal(addon.scanner.active, true)
        equal(addon.autoPaused, false)
        addon:SetWritSource("tsm")
        equal(addon.scanner.active, false)
        equal(addon.autoDue, nil)
    end)
end)
