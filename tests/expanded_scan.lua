local addon, test, equal, host = ...

local function fixture(action)
    local old={scanner=addon.scanner,clock=GetTime,wall=time,source=addon.db.source,writ=addon.db.writSource,
        profile=addon.db.profile,follow=addon.db.refreshAuctionator,auctionator=Auctionator,
        views=addon.BrowseUI.views,external=addon.lastExternalAt}
    addon:StopScan()
    addon.db.source,addon.db.writSource,addon.db.profile="auto","auto","default"
    addon.db.refreshAuctionator=true;addon.BrowseUI.views={};addon.lastExternalAt=nil
    local market=addon:GetMarket();old.items,old.failures=market.items,market.failures
    market.items,market.failures={},{}
    local f=TEST_SCANNER_FIXTURE();f.full=true;f.rows={{quantity=1000,unitPrice=10}};f.searches={}
    GetTime=function() return f.now end;time=function() return 100000+f.now end
    f.scanner.callbacks=old.scanner.callbacks;f.scanner.runtime.wallTime=time
    addon.scanner=f.scanner
    Auctionator={API={v1={GetAuctionPriceByItemID=function() return 1 end,
        GetAuctionAgeByItemID=function() return 0 end,MultiSearchAdvanced=function(_,terms)
            equal(addon.scanner.active,false);f.searches[#f.searches+1]=terms
        end}}}
    addon.Providers.Invalidate()
    function f.view(kind,query)
        local parent=CreateFrame("Frame",nil,UIParent);parent:SetSize(1000,550)
        local view=addon.BrowseUI.Create(parent,kind);addon.BrowseUI.Refresh(view)
        view.query=query or "";addon.BrowseUI.Render(view)
        return view
    end
    function f.complete()
        while addon.scanner.active do
            addon.scanner:Tick()
            local pending=addon.scanner.pending
            if pending and pending.sentAt then addon.scanner:Results("commodity",pending.itemID) end
            f.now=f.now+0.1
            assert(f.now<30,"test scope unexpectedly large")
        end
    end
    local ok,err=pcall(action,f,market)
    addon:StopScan();addon.scanner=old.scanner
    GetTime,time=old.clock,old.wall
    addon.db.source,addon.db.writSource,addon.db.profile=old.source,old.writ,old.profile
    addon.db.refreshAuctionator,Auctionator=old.follow,old.auctionator
    market.items,market.failures=old.items,old.failures
    addon.BrowseUI.views,addon.lastExternalAt=old.views,old.external
    addon.autoPaused=false;addon:UpdateScheduler();addon.Providers.Invalidate()
    assert(ok,err)
end

test("expanded catalogs produce 300 writ, 126 crate and 424 deduplicated complete-basket scan IDs",function()
    local writs=addon.Catalog.ScanItems(addon.Catalog.AllContracts("writs"))
    local crates=addon.Catalog.ScanItems(addon.Catalog.AllContracts("crates"))
    local all=addon.Catalog.ScanItems(addon.Catalog.AllContracts("all"))
    equal(#writs,300);equal(#crates,126);equal(#all,424)
    local ids,quantities=addon.Catalog.ScanItems({264037,264037})
    equal(#ids,2);equal(quantities[264037],1);equal(quantities[8069],200)
    ids=addon.Catalog.ScanItems({248683});equal(#ids,3)
end)
test("own writ estimates use full depth and include the actual outlay for a writ stack",function()
    fixture(function(f,market)
        addon.db.writSource="own";Auctionator=nil
        market.items[8069]={kind="commodity",scannedAt=time(),offers={{quantity=100,unitPrice=10},{quantity=100,unitPrice=20}}}
        market.items[264037]={kind="item",scannedAt=time(),offers={{quantity=2,buyoutAmount=5000}}}
        local entry=addon.Shopping.Entry("writs",264037)
        equal(entry.purchase,5000);equal(entry.delivery,3000);equal(entry.total,8000)
        equal(entry.deliveryRows[1].source,"own");equal(entry.purchaseQuote.purchased,2)
        market.items[8069].offers={{quantity=199,unitPrice=10}}
        entry=addon.Shopping.Entry("writs",264037);equal(entry.delivery,nil);equal(entry.total,nil)
        addon.db.writSource="auto"
        equal(addon.WritPricing.Rows(264037)[1].status,"short")
        addon.db.profile="neutral";addon.db.writSource="own"
        local other=addon:GetMarket();other.items=market.items
        equal(addon.Shopping.Entry("writs",264037).purchase,5000)
    end)
end)
test("Refresh scans the filtered contract and delivery, then hands the frozen scope to Auctionator",function()
    fixture(function(f,market)
        local view=f.view("writs","Crafted Solid Shot")
        view.refreshButton.scripts.OnClick()
        equal(#addon.scanner.queue,2);equal(view.refreshButton.text,"Stop")
        equal(addon.refreshJob.quantities[8069],200)
        view.query="Small Silk Pack";addon.BrowseUI.Render(view)
        f.complete();assert(market.items[8069]);assert(market.items[264037])
        equal(#f.searches,0);assert(addon.providerDue)
        f.now=f.now+1;host.scripts.OnUpdate()
        equal(#f.searches,1);equal(#f.searches[1],2)
        equal(f.searches[1][1].searchString,"Crafted Solid Shot");equal(f.searches[1][1].quantity,200)
        equal(f.searches[1][2].searchString,"Craftsman's Writ: Crafted Solid Shot");equal(f.searches[1][2].quantity,1)
        equal(addon.scanner.active,false);equal(addon.providerDue,nil)
    end)
end)
test("Refresh always reruns own queries even when prices are fresh; empty filters do not query",function()
    fixture(function(f,market)
        addon.db.refreshAuctionator=false
        local view=f.view("writs","Small Silk Pack")
        market.items[4245]={kind="commodity",offers={},scannedAt=time()}
        market.items[264050]={kind="commodity",offers={},scannedAt=time()}
        equal(addon:RefreshList(view),true);equal(#addon.scanner.queue,2)
        f.complete();equal(addon.providerDue,nil);equal(#f.searches,0)
        view.query="no such writ";addon.BrowseUI.Render(view)
        local requests=#addon.scanner.requests
        equal(addon:RefreshList(view),false);equal(#addon.scanner.requests,requests)
    end)
end)
test("the Refresh Stop button cancels both own work and the optional follow-up",function()
    fixture(function(f)
        local view=f.view("writs","Small Silk Pack")
        view.refreshButton.scripts.OnClick();equal(addon.scanner.active,true)
        view.refreshButton.scripts.OnClick();equal(addon.scanner.active,false)
        equal(addon.refreshJob,nil);equal(addon.providerDue,nil);equal(#f.searches,0)
        addon:RefreshList(view);f.complete();assert(addon.providerDue)
        addon:StopScan();equal(addon.providerDue,nil);equal(host.scripts.OnUpdate,nil)
    end)
end)
test("closing the AH or a competing query cannot launch a deferred provider scan",function()
    fixture(function(f)
        local view=f.view("writs","Small Silk Pack")
        addon:RefreshList(view);f.complete();assert(addon.providerDue)
        C_AuctionHouse.SendSearchQuery(C_AuctionHouse.MakeItemKey(2770),{},true)
        equal(addon.providerDue,nil);equal(#f.searches,0)
        addon:RefreshList(view);f.complete();assert(addon.providerDue)
        host.scripts.OnEvent(host,"AUCTION_HOUSE_CLOSED")
        equal(addon.providerDue,nil);equal(addon.pendingProviderScan,nil);equal(#f.searches,0)
    end)
end)
test("TSM exports exactly the filtered scope and never attempts to start TSM",function()
    fixture(function(f)
        f.view("writs","Crafted Solid Shot")
        addon:ExportTSM("writs")
        local exported=addon.UI.reportEdit.text
        equal(exported,"group:Waylaid Ledger - writs,i:8069,i:264037")
        equal(#f.calls,0);equal(#f.searches,0)
    end)
end)
test("manual scope commands support contracts in writs, crates and the combined catalog",function()
    fixture(function(f)
        addon:Command("scan writs");equal(#addon.scanner.queue,300)
        addon:StopScan();addon:Command("scan crates");equal(#addon.scanner.queue,126)
        addon:StopScan();addon:Command("scan all");equal(#addon.scanner.queue,424)
        addon:StopScan();addon.lastContractID=264037;addon:Command("scan hovered")
        equal(#addon.scanner.queue,2);addon.lastContractID=nil
    end)
end)
test("bag selection and inventory snapshots recognize writs and finished delivery goods",function()
    local original=C_Container
    C_Container={GetContainerNumSlots=function(id) return id==0 and 3 or 0 end,
        GetContainerItemID=function(_,slot) return ({264037,8069,999})[slot] end,
        GetContainerItemInfo=function() return {stackCount=2} end}
    local ids=addon.Catalog.BagContracts();equal(#ids,1);equal(ids[1],264037)
    local items=addon.Inventory.ReadContainers({0});equal(items[264037],2);equal(items[8069],2);equal(items[999],nil)
    C_Container=original
end)
test("equipment scans use the zero-level variant query and retain valid gear listings",function()
    local f=TEST_SCANNER_FIXTURE();f.api.GetItemKeyInfo=function() return {isEquipment=true} end
    local queries=0
    f.api.SendSellSearchQuery=function(key,_,separate)
        queries=queries+1;equal(key.itemLevel,0);equal(key.itemSuffix,0);equal(separate,true)
    end
    f.scanner:Start({10025});equal(queries,1);equal(#f.calls,0)
    f.full=true;f.rows={{itemKey={itemID=10025,itemLevel=50,itemSuffix=0},auctionID=1,quantity=1,buyoutAmount=250}}
    f.scanner:Results("item",f.api.MakeItemKey(10025))
    equal(addon.Pricing.Quote(f.saved[10025],1).cost,250)
end)
test("uncached item classification waits for loading rather than saving a false shortage",function()
    local f=TEST_SCANNER_FIXTURE();local loaded,loads=false,0
    f.api.GetItemKeyInfo=function() return loaded and {isEquipment=false} or nil end
    f.scanner.runtime.loadItem=function() loads=loads+1 end
    f.scanner:Start({4245});equal(#f.calls,0);equal(loads,1);equal(f.saved[4245],nil)
    f.now=1;f.scanner:Tick();equal(loads,1);equal(#f.calls,0)
    loaded=true;f.scanner:Tick();equal(#f.calls,1)
end)
test("missing gear query capability records a failure without claiming no listings",function()
    local f=TEST_SCANNER_FIXTURE();f.api.GetItemKeyInfo=function() return {isEquipment=true} end
    f.scanner:Start({10025});assert(f.failed[10025]);equal(f.saved[10025],nil)
end)
test("the full 424-item queue obeys rolling throttles without timing out between windows",function()
    local f=TEST_SCANNER_FIXTURE();local ids=addon.Catalog.ScanItems(addon.Catalog.AllContracts())
    f.full=true;f.scanner:Start(ids)
    for _=1,10000 do
        if not f.scanner.active then break end
        f.scanner:Tick()
        if f.scanner.pending and f.scanner.pending.sentAt then f.scanner:Results("commodity",f.scanner.pending.itemID) end
        f.now=f.now+0.1
    end
    equal(f.scanner.completed,424);equal(f.scanner.failed,0);equal(#f.calls,424)
    assert(f.now>=180)
end)

test("local item classification can identify gear before auction-key metadata is available",function()
    local f=TEST_SCANNER_FIXTURE();f.api.GetItemKeyInfo=function() return nil end
    f.scanner.runtime.isEquipment=function() return true end
    local count=0;f.api.SendSellSearchQuery=function() count=count+1 end
    f.scanner:Start({10025});equal(count,1);equal(f.saved[10025],nil)
end)
