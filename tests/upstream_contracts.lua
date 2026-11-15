local addon, test, equal = ...

-- Optional contract checks execute the unmodified API Lua from real release
-- ZIPs supplied to run.py. Internal services and WoW UI are stubbed; the public
-- functions, argument validation and handoff behavior are the upstream code.
if UPSTREAM_AUCTIONATOR then
    test("adapter calls actual Auctionator release price, age, callback and shopping APIs", function()
        local callback, terms, listItems, searched
        local list = { AppendItems=function(_,items) listItems=items end }
        Auctionator = { API={v1={}},
            Database={GetPrice=function(_,key) equal(key,"2770");return 125 end,
                GetPriceAge=function(_,key) equal(key,"2770");return 2 end},
            Utilities={VerifyListTypes=function(values) return values end},
            Search={ReconstituteAdvancedSearch=function(term)
                equal(term.isExact,true);equal(term.quantity,20);equal(term.searchString,"Copper Ore")
                terms=term;return "exact copper ore;20"
            end},
            Shopping={ListManager={GetIndexForName=function() end,Create=function() end,
                GetByName=function() return list end},
                Tab={Events={ListSearchRequested="search"}}},
            IncrementalScan={Events={PricesProcessed="prices"}},FullScan={Events={ScanComplete="complete"}},
        }
        Auctionator.API.InternalVerifyID=function(caller) equal(caller,"WaylaidLedger") end
        Auctionator.API.ComposeError=function(_,message) error(message) end
        Auctionator.EventBus={Register=function(_,receiver,events)
                callback=function() receiver:ReceiveEvent() end
                equal(events[1],"prices");equal(events[2],"complete")
            end,
            RegisterSource=function(self) return self end,
            Fire=function(self,_,event) equal(event,"search");searched=true;return self end,
            UnregisterSource=function(self) return self end}
        AuctionatorTabs_Shopping={Click=function() end}
        AUCTIONATOR_L_TEMPORARY_LOWER_CASE="temporary"
        for _,path in ipairs({"Source/API/v1/GetAuctionPrice.lua","Source/API/v1/GetAuctionAge.lua",
            "Source/API/v1/MultiSearch.lua","Source_ModernAH/API/v1/RegisterForDBUpdate.lua"}) do
            assert(loadstring(UPSTREAM_AUCTIONATOR[path],path))()
        end
        addon.Providers.Invalidate();addon.Providers.boundAPI=nil
        addon.Providers.Install();assert(callback)
        local quote=addon.Providers.Read("auctionator",2770)
        equal(quote.unitPrice,125);equal(quote.ageDays,2);equal(quote.stale,true)
        callback()
        local ok=addon.Providers.Search({{searchString="Copper Ore",categoryKey="",isExact=true,quantity=20}},"Test list")
        equal(ok,true);assert(searched);assert(terms);equal(listItems[1],"exact copper ore;20")
        Auctionator=nil;addon.Providers.boundAPI=nil;addon.Providers.Invalidate()
    end)
end

if UPSTREAM_TSM then
    test("adapter calls actual TSM release API with valid item strings and price keys", function()
        local calls={}
        local services={
            CallbackRegistry={NewWithKeys=function() return {} end},
            ["Item.ItemString"]={Get=function(value) return value:match("^i:%d+$") end},
            ["Price.CustomPrice"]={GetValue=function(key,itemString)
                calls[#calls+1]={key,itemString};return key=="DBMinBuyout" and 125 or 250
            end},
            ["Service.AddonSettings"]={RegisterOnLoad=function() end},
        }
        local app={}
        function app:Init() return {} end
        function app:Include(name) return services[name] or {} end
        function app:IncludeClassType(name) return services[name] or {} end
        function app:From() return self end
        strmatch=string.match
        assert(loadstring(UPSTREAM_TSM,"TradeSkillMaster/App/API.lua"))("TradeSkillMaster",{App=app})
        addon.db.tsmKey="DBMinBuyout";addon.Providers.Invalidate()
        equal(addon.Providers.Read("tsm",2770).unitPrice,125)
        equal(calls[1][1],"DBMinBuyout");equal(calls[1][2],"i:2770")
        addon.db.tsmKey="DBMarket";addon.Providers.Invalidate()
        equal(addon.Providers.Read("tsm",2770).unitPrice,250)
        equal(calls[2][1],"DBMarket")
        addon.db.tsmKey="DBMinBuyout";TSM_API=nil;addon.Providers.Invalidate()
    end)
end
