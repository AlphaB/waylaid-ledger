local addon, test, equal, host = ...

local function fixture(action)
    local old = {source=addon.db.source,profile=addon.db.profile,tracking=addon.db.tracking,
        scanOnOpen=addon.db.scanOnOpen,clock=GetTime,wall=time,requests=addon.scanner.requests,
        lastExternalAt=addon.lastExternalAt,scannerNow=addon.scanner.runtime.now}
    addon:StopScan();addon.UI.frame:Hide()
    addon.db.source,addon.db.profile="own","default"
    addon.db.scanOnOpen=true
    addon.db.tracking={enabled=false,autoScan=false,bank=false,alts=false}
    local market=addon:GetMarket();old.items,old.failures=market.items,market.failures
    market.items,market.failures={},{}
    local f={now=10,wall=100000}
    GetTime=function() return f.now end;time=function() return f.wall end
    addon.scanner.runtime.now=GetTime;addon.scanner.requests={};addon.lastExternalAt=nil
    local ok,err=pcall(action,f,market)
    host.scripts.OnEvent(host,"AUCTION_HOUSE_CLOSED")
    addon.db.source,addon.db.profile,addon.db.tracking=old.source,old.profile,old.tracking
    addon.db.scanOnOpen=old.scanOnOpen
    market.items,market.failures=old.items,old.failures
    GetTime,time=old.clock,old.wall
    addon.scanner.runtime.now,addon.scanner.requests=old.scannerNow,old.requests
    addon.lastExternalAt=old.lastExternalAt
    addon.autoPaused,addon.autoDue,addon.autoReason,addon.scanAutomatic,addon.scanOnOpen=false,nil,nil,false,false
    addon:UpdateScheduler()
    assert(ok,err)
end

test("auction-open scanning starts all 96 crate materials with no visible panel or tracked inventory",function()
    fixture(function(f)
        host.scripts.OnEvent(host,"AUCTION_HOUSE_SHOW")
        equal(addon.autoReason,"open");equal(addon.autoDue,12);equal(addon.scanner.active,false)
        f.now=12.1;host.scripts.OnUpdate()
        equal(addon.scanner.active,true);equal(#addon.scanner.queue,96)
        equal(addon.scanOnOpen,true);equal(addon.scanAutomatic,true)
        addon.UI.frame:Show();addon.UI.frame:Hide();equal(addon.scanner.active,true)
        addon:StopScan();equal(addon.scanner.active,false);equal(host.scripts.OnUpdate,nil)
        addon:RequestAutoScan(true);equal(addon.autoDue,nil)
    end)
end)
test("opening scans reuse fresh prices and refresh missing, failed or stale materials only",function()
    fixture(function(f,market)
        local ids=addon.Catalog.Materials(addon.Catalog.AllCrates())
        for _,id in ipairs(ids) do market.items[id]={kind="commodity",offers={},scannedAt=f.wall} end
        host.scripts.OnEvent(host,"AUCTION_HOUSE_SHOW")
        f.now=12.1;host.scripts.OnUpdate();equal(addon.scanner.active,false)
        market.items[ids[1]]=nil
        market.items[ids[2]].scannedAt=f.wall-addon.db.maxAge-1
        market.failures[ids[3]]="failed"
        host.scripts.OnEvent(host,"AUCTION_HOUSE_SHOW")
        f.now=15;host.scripts.OnUpdate()
        equal(#addon.scanner.queue,3)
        for index=1,3 do equal(addon.scanner.queue[index],ids[index]) end
    end)
end)
test("auction-open scan is opt-in, respects provider mode, and never runs away from AH",function()
    fixture(function()
        addon.db.scanOnOpen=false;host.scripts.OnEvent(host,"AUCTION_HOUSE_SHOW")
        equal(addon.autoDue,nil)
        addon.db.scanOnOpen=true;addon.db.source="auctionator"
        host.scripts.OnEvent(host,"AUCTION_HOUSE_SHOW");equal(addon.autoDue,nil)
        addon.db.source="own";host.scripts.OnEvent(host,"AUCTION_HOUSE_CLOSED")
        addon:RequestAutoScan(true);equal(addon.autoDue,nil)
    end)
end)
test("pending opening scans wait for competing searches; active scans yield without restarting",function()
    fixture(function(f)
        host.scripts.OnEvent(host,"AUCTION_HOUSE_SHOW");equal(addon.autoDue,12)
        f.now=11;C_AuctionHouse.SendSearchQuery(C_AuctionHouse.MakeItemKey(2770),{},true)
        equal(addon.autoDue,13);equal(addon.autoReason,"open");equal(addon.scanner.active,false)
        f.now=12.5;host.scripts.OnUpdate();equal(addon.scanner.active,false)
        f.now=13.1;host.scripts.OnUpdate();equal(addon.scanner.active,true)
        C_AuctionHouse.SendSearchQuery(C_AuctionHouse.MakeItemKey(2770),{},true)
        equal(addon.autoDue,nil);equal(addon.autoReason,nil);equal(addon.autoPaused,true)
        equal(addon.scanner.active,false);equal(host.scripts.OnUpdate,nil)
        addon:RequestAutoScan(true);equal(addon.autoDue,nil)
    end)
end)
test("tab-driven refresh cannot replace an opening scan and close cancels pending work",function()
    fixture(function()
        host.scripts.OnEvent(host,"AUCTION_HOUSE_SHOW")
        local due=addon.autoDue
        addon:RequestAutoScan();equal(addon.autoReason,"open");equal(addon.autoDue,due)
        host.scripts.OnEvent(host,"AUCTION_HOUSE_CLOSED")
        equal(addon.autoDue,nil);equal(addon.autoReason,nil);equal(host.scripts.OnUpdate,nil)
    end)
end)
test("scanopen settings stop pending or active opening scans without altering tracked refresh",function()
    fixture(function(f)
        host.scripts.OnEvent(host,"AUCTION_HOUSE_SHOW")
        addon:Command("scanopen off");equal(addon.db.scanOnOpen,false);equal(addon.autoDue,nil)
        addon:Command("scanopen on");equal(addon.db.scanOnOpen,true);equal(addon.autoReason,"open")
        f.now=13;host.scripts.OnUpdate();equal(addon.scanner.active,true)
        addon:SetFeature("tracking",false);equal(addon.scanner.active,true)
        addon:SetFeature("autoscan",false);equal(addon.scanner.active,true)
        addon:SetFeature("scanopen",false);equal(addon.scanner.active,false)
        equal(addon.db.tracking.autoScan,false)
        addon.UI.ToggleSettings();equal(addon.UI.settingsChecks.scanopen:GetChecked(),false)
        addon.UI.settings:Hide()
    end)
end)
test("changing to a forced provider stops an opening scan and prevents automatic restart",function()
    fixture(function(f)
        host.scripts.OnEvent(host,"AUCTION_HOUSE_SHOW")
        f.now=13;host.scripts.OnUpdate();equal(addon.scanner.active,true)
        addon:SetSource("tsm");equal(addon.scanner.active,false);equal(addon.autoDue,nil)
        addon:RequestAutoScan(true);equal(addon.autoDue,nil)
    end)
end)

test("native browse queries on AH open do not permanently suppress the opening scan",function()
    fixture(function(f)
        C_AuctionHouse.SendSearchQuery(C_AuctionHouse.MakeItemKey(2770),{},true)
        host.scripts.OnEvent(host,"AUCTION_HOUSE_SHOW")
        equal(addon.autoPaused,false);equal(addon.autoDue,12);equal(addon.scanner.active,false)
        f.now=11;C_AuctionHouse.RequestMoreCommoditySearchResults(2770)
        equal(addon.autoDue,13)
        f.now=13.1;host.scripts.OnUpdate();equal(addon.scanner.active,true)
    end)
end)
