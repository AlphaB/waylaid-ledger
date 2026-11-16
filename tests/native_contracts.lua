local _, test, equal = ...
if not UPSTREAM_FOREVER_UI then
    return
end

-- Run release-source list/display methods in an isolated environment. Only
-- rendering, transport, and the event registry are stand-ins; quantity clamping,
-- native lifecycle callbacks and refresh broadcasts are the unmodified client.
local function fixture()
    local env = setmetatable({}, { __index = _G })
    local noop = function() end
    env.CreateFromMixins = function(...)
        local result = {}
        for index = 1, select("#", ...) do
            for key, value in pairs(select(index, ...) or {}) do
                result[key] = value
            end
        end
        return result
    end
    env.AuctionHouseItemListMixin = { RefreshScrollFrame = noop, OnShow = noop }
    env.AuctionHouseSystemMixin, env.AuctionHouseSortOrderSystemMixin = {}, {}
    env.AuctionHouseFrameMixin = { Event = { CommoditiesQuantitySelectionChanged = "quantity" } }
    env.AuctionHouseSearchContext = { BuyCommodities = "commodity", BuyItems = "item" }
    env.AuctionHouseFrameDisplayMode = { Buy = "browse", CommoditiesBuy = "commodity" }
    env.FrameUtil = { RegisterFrameForEvents = noop, UnregisterFrameForEvents = noop }
    env.hooksecurefunc = function(owner, method, callback)
        local original = owner[method]
        owner[method] = function(...)
            original(...)
            callback(...)
        end
    end
    env.GetMoney = function()
        return 1000000
    end
    local state = { stock = { [2770] = 100, [8069] = 0 }, full = {}, queries = {} }
    env.C_AuctionHouse = {
        MakeItemKey = function(id)
            return { itemID = id }
        end,
        GetItemKeyInfo = function()
            return { isCommodity = true }
        end,
        IsThrottledMessageSystemReady = function()
            return true
        end,
        HasSearchResults = function(key)
            return state.stock[key.itemID] ~= nil
        end,
        GetCommoditySearchResultsQuantity = function(id)
            return state.stock[id] or 0
        end,
        HasFullCommoditySearchResults = function(id)
            return state.full[id] or false
        end,
        GetNumCommoditySearchResults = function()
            return 0
        end,
        RequestMoreCommoditySearchResults = noop,
    }
    env.AuctionHouseUtil = {
        AggregateSearchResultsByQuantity = function(id, quantity)
            local selected = math.min(state.stock[id] or 0, quantity)
            return selected, selected * 5, 1, false
        end,
        SanitizeAuctionHousePrice = function(value)
            return value
        end,
    }
    for _, name in ipairs({ "Blizzard_AuctionHouseCommoditiesList.lua", "Blizzard_AuctionHouseCommoditiesBuyFrame.lua" }) do
        setfenv(assert(loadstring(UPSTREAM_FOREVER_UI[name], name)), env)()
    end
    local function amount()
        return {
            value = 0,
            GetAmount = function(self)
                return self.value
            end,
            SetAmount = function(self, value)
                self.value = value
            end,
        }
    end
    local list = setmetatable(
        {
            quantitySelected = 1,
            isInitialized = true,
            ScrollBox = {
                HasView = function()
                    return false
                end,
                GetDataIndexEnd = function()
                    return 0
                end,
            },
            SetHighlightCallback = noop,
            SetDataProvider = noop,
            DirtyScrollFrame = noop,
            Reset = noop,
        },
        { __index = env.AuctionHouseCommoditiesBuyListMixin }
    )
    local display = setmetatable({
        QuantityInput = {
            value = 1,
            SetQuantity = function(self, value)
                self.value = value
            end,
            GetQuantity = function(self)
                return self.value
            end,
        },
        ItemDisplay = {
            SetItem = function(self, id)
                self.id = id
            end,
            GetItemID = function(self)
                return self.id
            end,
        },
        UnitPrice = amount(),
        TotalPrice = amount(),
        BuyButton = { SetDisableTooltip = noop },
        Layout = noop,
        RegisterEvent = noop,
        UnregisterEvent = noop,
    }, { __index = env.AuctionHouseCommoditiesBuyDisplayMixin })
    local buy = setmetatable(
        { BuyDisplay = display, ItemList = list, shown = false },
        { __index = env.AuctionHouseCommoditiesBuyFrameMixin }
    )
    buy.IsShown = function(self)
        return self.shown
    end
    list.GetParent, display.GetParent = function()
        return buy
    end, function()
        return buy
    end
    local callbacks = {}
    local ah = { CommoditiesBuyFrame = buy, Tabs = { {} } }
    env.AuctionHouseFrame = ah
    buy.GetAuctionHouseFrame = function()
        return ah
    end
    function ah:RegisterCallback(event, callback, owner)
        callbacks[owner] = callback
    end
    function ah:UnregisterCallback(event, owner)
        callbacks[owner] = nil
    end
    function ah:TriggerEvent(event, quantity)
        equal(event, "quantity")
        for owner, callback in pairs(callbacks) do
            callback(owner, quantity)
        end
    end
    function ah:SetDisplayMode(mode)
        if self.mode == mode then
            return
        end
        if buy.shown then
            display:OnHide()
            list:OnHide()
            buy.shown = false
        end
        self.mode = mode
        if mode == "commodity" then
            buy.shown = true
            display:OnShow()
            list:OnShow()
        end
    end
    function ah:SelectBrowseResult(result)
        -- Same ordering as the client's SelectBrowseResult: SetItemID runs
        -- before OnShow resets the previous item's resultsLoaded flag.
        buy:SetItemIDAndPrice(result.itemKey.itemID, result.minPrice)
        self:SetDisplayMode("commodity")
    end
    local isolated = {
        scanner = {
            open = true,
            BudgetReady = function()
                return true
            end,
        },
        StopScan = noop,
        Navigation = { Focus = noop, Refresh = noop },
    }
    for _, name in ipairs({ "Localization", "Locales" }) do
        setfenv(assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/" .. name .. ".lua")), env)("WaylaidLedger", isolated)
    end
    setfenv(assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/NativeShopping.lua")), env)("WaylaidLedger", isolated)
    local native = isolated.NativeShopping
    function ah:QueryItem(context, key)
        equal(context, "commodity")
        state.queries[#state.queries + 1] = key.itemID
        native.ExternalQuery("SendSearchQuery", key)
    end
    function state.receive(id, stock, full)
        state.stock[id], state.full[id] = stock, full
        native.Results(id)
        display:OnEvent("COMMODITY_SEARCH_RESULTS_RECEIVED", id)
        list:OnEvent("COMMODITY_SEARCH_RESULTS_RECEIVED", id)
        list:RefreshScrollFrame()
    end
    state.env, state.ah = env, ah
    return native, list, display, state
end

if UPSTREAM_FOREVER_UI["Blizzard_AuctionHouseFrame.lua"] then
    test("native gear handoff routes through Forever's actual item-variant query contract", function()
        local native, _, _, state = fixture()
        local env, ah = state.env, state.ah
        local source = UPSTREAM_FOREVER_UI["Blizzard_AuctionHouseFrame.lua"]
        local query = assert(source:match("(function AuctionHouseFrameMixin:QueryItem%b()%s*.-\nend)"))
        env.AreSortTypesLoaded = function()
            return true
        end
        env.GetSortTypes = function()
            return {}
        end
        setfenv(assert(loadstring(query, "Forever/QueryItem")), env)()
        ah.QueryItem = env.AuctionHouseFrameMixin.QueryItem
        ah.activeSearches, ah.ItemBuyFrame = {}, { ItemList = {} }
        env.C_AuctionHouse.GetItemKeyInfo = function()
            return { isCommodity = false, isEquipment = true }
        end
        local sellQueries, ordinaryQueries = 0, 0
        env.C_AuctionHouse.SendSellSearchQuery = function(key)
            equal(key.itemID, 4245)
            sellQueries = sellQueries + 1
        end
        env.C_AuctionHouse.SendSearchQuery = function()
            ordinaryQueries = ordinaryQueries + 1
        end
        equal(native.OpenItem({ itemID = 4245, quantity = 1 }), true)
        equal(sellQueries, 1)
        equal(ordinaryQueries, 0)
        equal(ah.activeSearches[env.AuctionHouseSearchContext.BuyItems][3], true)
    end)
end

test("native shopping preserves 200 units through actual Forever cached-zero list and display refreshes", function()
    local native, list, display, state = fixture()
    equal(native.OpenItem({ itemID = 2770, quantity = 20 }), true)
    state.receive(2770, 100, true)
    equal(display:GetQuantitySelected(), 20)
    equal(native.pendingQuantity, nil)
    equal(native.OpenItem({ itemID = 8069, quantity = 200 }), true)
    -- A genuine client side effect absent from the ordinary UI mock.
    equal(list.quantityCappedAtZero, true)
    equal(display:GetQuantitySelected(), 200)
    equal(list.quantitySelected, 200)
    state.receive(8069, 1000, true)
    equal(display:GetQuantitySelected(), 200)
    equal(list.quantitySelected, 200)
    equal(native.pendingQuantity, nil)
    list:RefreshScrollFrame()
    equal(display:GetQuantitySelected(), 200)
    equal(#state.queries, 2)
end)

test("native shopping retains intent through partial Forever results and relinquishes it after fulfillment", function()
    local native, list, display, state = fixture()
    equal(native.OpenItem({ itemID = 8069, quantity = 200 }), true)
    state.receive(8069, 50, false)
    -- The clamped list queues another dirty refresh to synchronize its display.
    list:RefreshScrollFrame()
    equal(display:GetQuantitySelected(), 50)
    assert(native.pendingQuantity)
    state.receive(8069, 1000, true)
    equal(display:GetQuantitySelected(), 200)
    equal(native.pendingQuantity, nil)
    -- Once fulfilled, later list refreshes must respect manual adjustments.
    list:GetAuctionHouseFrame():TriggerEvent("quantity", 7)
    list:RefreshScrollFrame()
    equal(display:GetQuantitySelected(), 7)
end)
