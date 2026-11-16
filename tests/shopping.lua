local addon, test, equal = ...
local Shopping = addon.Shopping

local function fixture(action)
    local old = { read=addon.Providers.Read, auctionator=Auctionator, source=addon.db.source,
        writSource=addon.db.writSource, profile=addon.db.profile, locale=GetLocale,
        names=C_Item.GetItemNameByID, request=C_Item.RequestLoadItemDataByID }
    addon.db.source, addon.db.writSource, addon.db.profile = "auto", "auto", "default"
    local market=addon:GetMarket()
    old.items,old.failures=market.items,market.failures
    market.items,market.failures={},{}
    local f={prices={auctionator={},tsm={}}, searches={}, reads=0}
    addon.Providers.Read=function(source,id) f.reads=f.reads+1;return f.prices[source][id] end
    Auctionator={API={v1={MultiSearchAdvanced=function(caller,terms)
        equal(caller,"WaylaidLedger");equal(addon.scanner.active,false)
        f.searches[#f.searches+1]=terms
    end}}}
    addon.scanner:SetOpen(true)
    function f.price(id,amount,source,stale)
        source=source or "auctionator"
        f.prices[source][id]={source=source,sourceLabel=source,unitPrice=amount,estimated=true,stale=stale or false}
    end
    local ok,err=pcall(action,f,market)
    addon:StopScan();addon.autoDue=nil;addon.autoPaused=false;addon.scanAutomatic=false
    addon.Providers.Read,Auctionator=old.read,old.auctionator
    addon.db.source,addon.db.writSource,addon.db.profile=old.source,old.writSource,old.profile
    market.items,market.failures=old.items,old.failures
    GetLocale,C_Item.GetItemNameByID,C_Item.RequestLoadItemDataByID=old.locale,old.names,old.request
    addon:UpdateScheduler()
    assert(ok,err)
end

local function find(entries,id)
    for index,entry in ipairs(entries) do if entry.itemID==id then return entry,index end end
end

test("writ browse totals include one writ and the full delivery, sorted by combined cost",function()
    fixture(function(f)
        f.price(264050,100);f.price(4245,400)
        f.price(264037,40);f.price(8069,3)
        local entries=Shopping.Entries("writs")
        equal(#entries,150);equal(entries[1].itemID,264050);equal(entries[1].total,500)
        equal(entries[2].itemID,264037);equal(entries[2].delivery,600);equal(entries[2].total,640)
        equal(entries[3].total,nil)
    end)
end)
test("crate browse selects the cheapest full option across usable scans and estimates",function()
    fixture(function(f,market)
        f.price(248683,50);f.price(2771,3)
        market.items[2770]={kind="item",scannedAt=time(),offers={{quantity=25,buyoutAmount=250}}}
        local entry=Shopping.Entry("crates",248683)
        equal(entry.optionIndex,2);equal(entry.delivery,60);equal(entry.total,110)
        f.price(2771,30)
        entry=Shopping.Entry("crates",248683)
        equal(entry.optionIndex,1);equal(entry.delivery,250);equal(entry.total,300)
        equal(entry.requirements[1].quantity,20)
    end)
end)
test("missing purchase or delivery prices never turn into zero totals",function()
    fixture(function(f)
        f.price(4245,400)
        local entry=Shopping.Entry("writs",264050)
        equal(entry.delivery,400);equal(entry.purchase,nil);equal(entry.total,nil);equal(entry.canShop,true)
        f.price(264050,100);f.prices.auctionator[4245]=nil
        entry=Shopping.Entry("writs",264050);equal(entry.delivery,nil);equal(entry.total,nil)
        entry=Shopping.Entry("crates",248683);equal(entry.canShop,false);equal(entry.total,nil)
        equal(Shopping.Terms(entry),nil)
    end)
end)
test("observed crate shortages cannot become the selected shopping option",function()
    fixture(function(f,market)
        f.price(2770,1);f.price(2771,3)
        market.items[2770]={kind="commodity",scannedAt=time(),offers={}}
        local entry=Shopping.Entry("crates",248683);equal(entry.optionIndex,2)
        market.items[2771]={kind="commodity",scannedAt=time(),offers={}}
        entry=Shopping.Entry("crates",248683);equal(entry.canShop,false)
    end)
end)
test("stale totals remain labelled and numeric ties sort deterministically",function()
    fixture(function(f)
        f.price(264050,100,"auctionator",true);f.price(4245,400)
        local entry=Shopping.Entry("writs",264050);equal(entry.total,500);equal(entry.stale,true)
        local rows={{total=5,name="Same",itemID=3},{total=5,name="Same",itemID=1},
            {name="A",itemID=4},{total=2,name="Z",itemID=2}}
        table.sort(rows,Shopping.Less)
        equal(rows[1].itemID,2);equal(rows[2].itemID,1);equal(rows[3].itemID,3);equal(rows[4].itemID,4)
    end)
end)
test("purchase quotes follow writ settings and custom-profile isolation without enlarging scans",function()
    fixture(function(f)
        f.price(264050,100);f.price(4245,400)
        f.price(264050,200,"tsm");f.price(4245,500,"tsm")
        addon.db.writSource="tsm"
        local entry=Shopping.Entry("writs",264050);equal(entry.total,700)
        addon.db.writSource="off";entry=Shopping.Entry("writs",264050);equal(entry.total,nil)
        addon.db.writSource="auto";addon.db.profile="neutral"
        entry=Shopping.Entry("writs",264050);equal(entry.total,nil)
        addon.db.profile="default";addon.db.source="own";f.price(248683,50)
        entry=Shopping.Entry("crates",248683);equal(entry.purchase,50);equal(entry.delivery,nil)
        local before=#addon.scanner.requests
        Shopping.Entries("writs");Shopping.Entries("crates")
        equal(#addon.scanner.requests,before);equal(#addon.Catalog.Materials(addon.Catalog.AllCrates()),96)
    end)
end)
test("writ row shopping includes the writ plus 200 ammo and stops a running scan first",function()
    fixture(function(f)
        addon:StartScan("all");assert(addon.scanner.active)
        equal(addon:ShopEntry("writs",264037),true)
        equal(#f.searches,1);equal(#f.searches[1],2)
        equal(f.searches[1][1].searchString,"Craftsman's Writ: Crafted Solid Shot")
        equal(f.searches[1][1].quantity,1)
        equal(f.searches[1][2].searchString,"Crafted Solid Shot");equal(f.searches[1][2].quantity,200)
        equal(f.searches[1][1].isExact,true);equal(f.searches[1][2].isExact,true)
        equal(addon.autoPaused,true)
    end)
end)
test("crate row shopping reprices on click and includes exactly one chosen alternative",function()
    fixture(function(f)
        f.price(2770,1);f.price(2771,2)
        local entry=Shopping.Entry("crates",248683);equal(entry.optionIndex,1)
        f.price(2770,3)
        equal(addon:ShopEntry("crates",248683),true)
        equal(#f.searches[1],2);equal(f.searches[1][1].quantity,1)
        equal(f.searches[1][1].searchString,addon.Crates[248683].name)
        equal(f.searches[1][2].searchString,"Tin Ore");equal(f.searches[1][2].quantity,20)
        equal(addon.lastBasket.optionIndex,2)
    end)
end)
test("basket shopping validates AH, addon, item and localized names before interrupting scans",function()
    fixture(function(f)
        addon.scanner:SetOpen(false);equal(addon:ShopEntry("writs",264050),false)
        addon.scanner:SetOpen(true)
        local api=Auctionator;Auctionator=nil;equal(addon:ShopEntry("writs",264050),false);Auctionator=api
        equal(addon:ShopEntry("writs",999999),false);equal(addon:ShopEntry("invalid",264050),false)
        addon:StartScan("all");assert(addon.scanner.active)
        GetLocale=function() return "esES" end
        local requested;C_Item.GetItemNameByID=function() end;C_Item.RequestLoadItemDataByID=function(id) requested=id end
        equal(addon:ShopEntry("writs",264050),false);equal(requested,264050);equal(addon.scanner.active,true)
        C_Item.GetItemNameByID=function(id) return id==264050 and "Escrito" or "Bolsa" end
        equal(addon:ShopEntry("writs",264050),true)
        equal(f.searches[1][1].searchString,"Escrito");equal(f.searches[1][2].searchString,"Bolsa")
    end)
end)
test("a rejected Auctionator basket preserves prices and does not restart our scanner",function()
    fixture(function(f,market)
        f.price(264050,100);f.price(4245,400)
        market.items[2770]={kind="commodity",scannedAt=time(),offers={}}
        Auctionator.API.v1.MultiSearchAdvanced=function() error("failed handoff") end
        addon:StartScan("all");equal(addon:ShopEntry("writs",264050),false)
        equal(addon.scanner.active,false);equal(addon.autoDue,nil)
        assert(market.items[2770]);assert(addon.Providers.errors.auctionator:match("failed handoff"))
    end)
end)
test("browse rows render ranked totals, filter delivery names, and route clicks to basket shopping",function()
    fixture(function(f)
        f.price(264050,100);f.price(4245,400);f.price(264037,40);f.price(8069,3)
        local host=CreateFrame("Frame",nil,UIParent);host:SetSize(1000,550)
        local view=addon.BrowseUI.Create(host,"writs");addon.BrowseUI.Refresh(view)
        equal(#view.visibleEntries,150);equal(#view.scroll.rows,10);equal(view.scroll.rows[1].entry.itemID,264050)
        assert(not view.scroll.rows[1].total.text:match("~"));assert(view.scroll.rows[1].deliveryName.text:match("Small Silk Pack"))
        view.scroll.rows[1].scripts.OnClick(view.scroll.rows[1]);equal(#f.searches[1],2)
        view.search:SetText("Crafted Solid Shot");view.search.scripts.OnTextChanged(view.search)
        equal(#view.visibleEntries,1);equal(view.scroll.rows[1].entry.itemID,264037)
        view.scroll.rows[1].scripts.OnClick(view.scroll.rows[1])
        equal(#f.searches,2);equal(f.searches[2][1].searchString,"Craftsman's Writ: Crafted Solid Shot")
        equal(f.searches[2][2].quantity,200)
        equal(view.scroll.template,"WowScrollBoxList");equal(view.scrollBar.template,"WowClassicScrollBar")
        equal(view.inset.template,"InsetFrameTemplate")
        local previousEnd=0
        for _,header in ipairs(view.headers) do
            equal(header.template,"ColumnDisplayButtonNoScriptsTemplate")
            assert(header.point[4]>=previousEnd)
            previousEnd=header.point[4]+header:GetWidth()
        end
        assert(previousEnd<=host:GetWidth()-42)
        equal(view.scroll.rows[2]:IsShown(),false);equal(view.scroll.offset,0)
        view.search:SetText("does not exist");view.search.scripts.OnTextChanged(view.search)
        equal(#view.visibleEntries,0);equal(view.empty:IsShown(),true)
        host:Hide();addon.BrowseUI.views.writs=nil
    end)
end)
test("hidden browse panels do not read provider prices on unrelated tooltip updates",function()
    fixture(function(f)
        local host=CreateFrame("Frame",nil,UIParent);host:Hide()
        addon.BrowseUI.Create(host,"writs")
        addon.BrowseUI.UpdateVisible();equal(f.reads,0)
        addon.BrowseUI.views.writs=nil
    end)
end)

test("row shopping requires a tab-switching API while legacy list creation stays available",function()
    fixture(function(f)
        Auctionator.API.v1={ConvertToSearchString=function() return "term" end,CreateShoppingList=function() end}
        equal(addon.Providers.ShoppingAvailable(),true);equal(addon.Providers.ShoppingAvailable(true),false)
        addon:StartScan("all");equal(addon:ShopEntry("writs",264050),false)
        equal(addon.scanner.active,true)
    end)
end)

test("item hover does not rebuild the native list and recycle the button under the pointer",function()
    fixture(function(f)
        f.price(248683,50);f.price(2770,1);f.price(2771,2)
        local host=CreateFrame("Frame",nil,UIParent);host:SetSize(1000,550)
        local view=addon.BrowseUI.Create(host,"crates");addon.BrowseUI.Refresh(view)
        local calls=0;local original=view.scroll.SetDataProvider
        view.scroll.SetDataProvider=function(self,...) calls=calls+1;return original(self,...) end
        local oldTip=GameTooltip;GameTooltip=CreateFrame("GameTooltip")
        GameTooltip.SetItemByID=function(tip,id) addon.Tooltip.Append(tip,id) end
        local row=view.scroll.rows[1];equal(row.entry.itemID,248683)
        addon.BrowseUI.ShowTooltip(row)
        equal(calls,0);equal(row.entry.itemID,248683)
        GameTooltip=oldTip;host:Hide();addon.BrowseUI.views.crates=nil
    end)
end)
