local addon, test, equal = ...

-- Optional contract checks execute the unmodified API Lua from real release
-- ZIPs supplied to run.py. Internal services and WoW UI are stubbed; the public
-- functions, argument validation and handoff behavior are the upstream code.
if UPSTREAM_AUCTIONATOR then
    test("released Auctionator event bus reports scan progress without importing its snapshot", function()
        local saved = Auctionator
        local a = {}
        local ok, err = pcall(function()
            Auctionator = {
                API = { v1 = {}, InternalVerifyID = function() end },
                FullScan = {},
                IncrementalScan = { Events = { PricesProcessed = "prices" } },
                Debug = { Message = function() end },
                Utilities = {
                    Slice = function(values, first, last)
                        local copy = {}
                        for index = first, last do
                            copy[#copy + 1] = values[index]
                        end
                        return copy
                    end,
                },
            }
            local env = setmetatable({
                Auctionator = Auctionator,
                CreateAndInitFromMixin = function(mixin)
                    local instance = setmetatable({}, { __index = mixin })
                    instance:Init()
                    return instance
                end,
            }, { __index = _G })
            for _, path in ipairs({
                "Source/Utilities/EventBusMixin.lua",
                "Source_ModernAH/FullScan/Events.lua",
                "Source_ModernAH/API/v1/RegisterForDBUpdate.lua",
            }) do
                setfenv(assert(loadstring(UPSTREAM_AUCTIONATOR[path], path)), env)()
            end
            assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/Localization.lua"))("WaylaidLedger", a)
            assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/Providers.lua"))("WaylaidLedger", a)
            a.Providers.Install()
            local bus, events, source = Auctionator.EventBus, Auctionator.FullScan.Events, {}
            bus:RegisterSource(source, "test")
            bus:Fire(source, events.ScanStart)
            assert(a.Providers.scan)
            bus:Fire(source, events.ScanProgress, 0.42)
            equal(a.Providers.scan.percent, 42)
            bus:Fire(source, "prices")
            assert(a.Providers.scan)
            bus:Fire(source, events.ScanComplete, { { replicateInfo = {} } })
            equal(a.Providers.scan, nil)
            bus:Fire(source, events.ScanStart)
            bus:Fire(source, events.ScanFailed)
            equal(a.Providers.scan, nil)
        end)
        Auctionator = saved
        assert(ok, err)
    end)
    test("adapter calls actual Auctionator release price, age, callback and shopping APIs", function()
        local callback, terms, listItems, searched, shoppingClicks
        shoppingClicks = 0
        local list = {
            AppendItems = function(_, items)
                listItems = items
            end,
        }
        Auctionator = {
            API = { v1 = {} },
            Database = {
                GetPrice = function(_, key)
                    equal(key, "2770")
                    return 125
                end,
                GetPriceAge = function(_, key)
                    equal(key, "2770")
                    return 2
                end,
            },
            Utilities = {
                VerifyListTypes = function(values)
                    return values
                end,
            },
            Search = {
                ReconstituteAdvancedSearch = function(term)
                    equal(term.isExact, true)
                    equal(term.quantity, 20)
                    equal(term.searchString, "Copper Ore")
                    terms = term
                    return "exact copper ore;20"
                end,
            },
            Shopping = {
                ListManager = {
                    GetIndexForName = function() end,
                    Create = function() end,
                    GetByName = function()
                        return list
                    end,
                },
                Tab = { Events = { ListSearchRequested = "search" } },
            },
            IncrementalScan = { Events = { PricesProcessed = "prices" } },
            FullScan = { Events = { ScanComplete = "complete" } },
        }
        Auctionator.API.InternalVerifyID = function(caller)
            equal(caller, "WaylaidLedger")
        end
        Auctionator.API.ComposeError = function(_, message)
            error(message)
        end
        Auctionator.EventBus = {
            Register = function(_, receiver, events)
                callback = function()
                    receiver:ReceiveEvent()
                end
                equal(events[1], "prices")
                equal(events[2], "complete")
            end,
            RegisterSource = function(self)
                return self
            end,
            Fire = function(self, _, event)
                equal(event, "search")
                searched = true
                return self
            end,
            UnregisterSource = function(self)
                return self
            end,
        }
        AuctionatorTabs_Shopping = {
            Click = function()
                shoppingClicks = shoppingClicks + 1
            end,
        }
        AUCTIONATOR_L_TEMPORARY_LOWER_CASE = "temporary"
        for _, path in ipairs({
            "Source/API/v1/GetAuctionPrice.lua",
            "Source/API/v1/GetAuctionAge.lua",
            "Source/API/v1/MultiSearch.lua",
            "Source_ModernAH/API/v1/RegisterForDBUpdate.lua",
        }) do
            assert(loadstring(UPSTREAM_AUCTIONATOR[path], path))()
        end
        addon.Providers.Invalidate()
        addon.Providers.boundAPI = nil
        addon.Providers.Install()
        assert(callback)
        local quote = addon.Providers.Read("auctionator", 2770)
        equal(quote.unitPrice, 125)
        equal(quote.ageDays, 2)
        equal(quote.stale, true)
        callback()
        local ok = addon.Providers.Search(
            { { searchString = "Copper Ore", categoryKey = "", isExact = true, quantity = 20 } },
            "Test list"
        )
        equal(ok, true)
        assert(searched)
        assert(terms)
        equal(listItems[1], "exact copper ore;20")
        equal(shoppingClicks, 1)
        local basketTerms = {}
        Auctionator.Search.ReconstituteAdvancedSearch = function(term)
            equal(term.isExact, true)
            basketTerms[#basketTerms + 1] = term
            return term.searchString .. ";" .. term.quantity
        end
        Auctionator.Database.GetPrice = function(_, id)
            return ({ ["264037"] = 40, ["8069"] = 3, ["248683"] = 50, ["2770"] = 4, ["2771"] = 2 })[id]
        end
        Auctionator.Database.GetPriceAge = function()
            return 0
        end
        addon.db.writSource, addon.db.source = "auto", "auto"
        addon.scanner:SetOpen(true)
        addon.Providers.Invalidate()
        equal(addon:ShopEntry("writs", 264037), true)
        equal(shoppingClicks, 2)
        equal(#basketTerms, 2)
        equal(basketTerms[1].searchString, "Craftsman's Writ: Crafted Solid Shot")
        equal(basketTerms[1].quantity, 1)
        equal(basketTerms[2].searchString, "Crafted Solid Shot")
        equal(basketTerms[2].quantity, 200)
        local market = addon:GetMarket()
        market.items, market.failures = {}, {}
        basketTerms = {}
        equal(addon:ShopEntry("crates", 248683), true)
        equal(shoppingClicks, 3)
        equal(#basketTerms, 2)
        equal(basketTerms[1].searchString, addon.Crates[248683].name)
        equal(basketTerms[1].quantity, 1)
        equal(basketTerms[2].searchString, "Tin Ore")
        equal(basketTerms[2].quantity, 20)
        basketTerms = {}
        equal(addon.Providers.ScanItems({ 8069, 264037 }, { [8069] = 200, [264037] = 1 }), true)
        equal(shoppingClicks, 4)
        equal(#basketTerms, 2)
        equal(basketTerms[1].searchString, "Crafted Solid Shot")
        equal(basketTerms[1].quantity, 200)
        equal(basketTerms[2].searchString, "Craftsman's Writ: Crafted Solid Shot")
        equal(basketTerms[2].quantity, 1)
        Auctionator = nil
        addon.Providers.boundAPI = nil
        addon.Providers.Invalidate()
    end)
end

if UPSTREAM_TSM then
    test("adapter calls actual TSM release API with valid item strings and price keys", function()
        local calls = {}
        local services = {
            CallbackRegistry = {
                NewWithKeys = function()
                    return {}
                end,
            },
            ["Item.ItemString"] = {
                Get = function(value)
                    return value:match("^i:%d+$")
                end,
            },
            ["Price.CustomPrice"] = {
                GetValue = function(key, itemString)
                    calls[#calls + 1] = { key, itemString }
                    return key == "DBMinBuyout" and 125 or 250
                end,
            },
            ["Service.AddonSettings"] = { RegisterOnLoad = function() end },
        }
        local app = {}
        function app:Init()
            return {}
        end
        function app:Include(name)
            return services[name] or {}
        end
        function app:IncludeClassType(name)
            return services[name] or {}
        end
        function app:From()
            return self
        end
        strmatch = string.match
        assert(loadstring(UPSTREAM_TSM, "TradeSkillMaster/App/API.lua"))("TradeSkillMaster", { App = app })
        addon.db.tsmKey = "DBMinBuyout"
        addon.Providers.Invalidate()
        equal(addon.Providers.Read("tsm", 2770).unitPrice, 125)
        equal(calls[1][1], "DBMinBuyout")
        equal(calls[1][2], "i:2770")
        addon.db.tsmKey = "DBMarket"
        addon.Providers.Invalidate()
        equal(addon.Providers.Read("tsm", 2770).unitPrice, 250)
        equal(calls[2][1], "DBMarket")
        addon.db.tsmKey = "DBMinBuyout"
        TSM_API = nil
        addon.Providers.Invalidate()
    end)
end

if UPSTREAM_TSM_GROUP_IMPORT then
    test("TSM export parses through the released TSM group/item-list parser", function()
        local class = { __private = {}, __static = {} }
        local services = {
            Group = {
                GetRootPath = function()
                    return ""
                end,
                GetParent = function()
                    return nil
                end,
            },
            ["Item.ItemString"] = {
                Get = function(value)
                    return value:match("^i:%d+$") and value or nil
                end,
            },
            ["Lua.String"] = {
                SplitIterator = function(value)
                    return value:gmatch("[^,]+")
                end,
            },
            ["Util.Log"] = {
                Err = function(message)
                    error(message)
                end,
            },
        }
        local lib = {
            DefineClassType = function()
                return class
            end,
        }
        function lib:Include(name)
            return services[name] or {}
        end
        function lib:IncludeClassType()
            return {}
        end
        function lib:From()
            return self
        end
        local oldStub = LibStub
        LibStub = function()
            return {}
        end
        gsub = string.gsub
        strmatch = string.match
        strtrim = function(s)
            return s:match("^%s*(.-)%s*$")
        end
        local ok, err = pcall(function()
            assert(
                loadstring(
                    UPSTREAM_TSM_GROUP_IMPORT,
                    "TradeSkillMaster/LibTSMTypes/Source/ImportExport/GroupImport.lua"
                )
            )("TradeSkillMaster", { LibTSMTypes = lib })
            local items, groups, invalid =
                class.__private:_DecodeGroupExportHelper("group:Waylaid Ledger - writs,i:8069,i:264037")
            equal(items["i:8069"], "Waylaid Ledger - writs")
            equal(items["i:264037"], "Waylaid Ledger - writs")
            equal(groups["Waylaid Ledger - writs"], true)
            equal(invalid, 0)
        end)
        LibStub = oldStub
        assert(ok, err)
    end)
end
