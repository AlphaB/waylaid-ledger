local addon, test, equal, host = ...
local Inventory = addon.Inventory

local function inventoryFixture(fn)
    local old = {guid=UnitGUID,name=UnitName,container=C_Container,bank=C_Bank,enums=Enum.BankType,
        inventory=addon.db.inventory,tracking=addon.db.tracking,source=addon.db.source,now=GetTime,
        profile=addon.db.profile,visible=addon.UI.IsScanPanelVisible}
    local f = {guid="Player-Main",name="Main",bags={},capacities={},charTabs={6},sharedTabs={15}}
    UnitGUID=function() return f.guid end;UnitName=function() return f.name end
    GetTime=function() return 10 end
    C_Container={GetContainerNumSlots=function(id) return f.capacities[id] or #(f.bags[id] or {}) end,
        GetContainerItemID=function(id,slot) local row=f.bags[id] and f.bags[id][slot];return row and row.id end,
        GetContainerItemInfo=function(id,slot) local row=f.bags[id] and f.bags[id][slot];return row and {stackCount=row.count} end}
    Enum.BankType={Character=0,Account=2}
    C_Bank={CanViewBank=function() return true end,FetchPurchasedBankTabIDs=function(kind)
        return kind==0 and f.charTabs or f.sharedTabs
    end}
    addon.db.inventory={characters={},sharedBanks={}}
    addon.db.tracking={enabled=true,bank=true,alts=true,autoScan=true}
    addon.db.profile="default";Inventory.bankOpen=false
    addon.UI.IsScanPanelVisible=function() return true end
    local ok,err=pcall(fn,f)
    addon.scanner:Stop();addon.autoDue=nil;addon.autoPaused=false;addon.scanAutomatic=false
    Inventory.bankOpen=false
    UnitGUID,UnitName,C_Container,C_Bank,Enum.BankType=old.guid,old.name,old.container,old.bank,old.enums
    addon.db.inventory,addon.db.tracking,addon.db.source,addon.db.profile=old.inventory,old.tracking,old.source,old.profile
    GetTime=old.now;addon.UI.IsScanPanelVisible=old.visible;addon:UpdateScheduler()
    assert(ok,err)
end

test("inventory records stack counts and ignores unrelated items",function()
    inventoryFixture(function(f)
        f.bags[0]={{id=248683,count=2},{id=2770,count=17},{id=999,count=20}}
        Inventory.CaptureBags()
        local items=Inventory.Totals().items
        equal(items[248683],2);equal(items[2770],17);equal(items[999],nil)
        equal(Inventory.CrateIDs()[1],248683)
    end)
end)
test("bank snapshots require a visit and unavailable slots cannot erase saved contents",function()
    inventoryFixture(function(f)
        Inventory.CaptureBags();f.bags[6]={{id=248684,count=3}};f.capacities[15]=2
        Inventory.CaptureBank();equal(Inventory.Totals().items[248684],nil)
        Inventory.bankOpen=true;Inventory.CaptureBank();equal(Inventory.Totals().items[248684],3)
        f.bags[6]={};Inventory.CaptureBank();equal(Inventory.Totals().items[248684],3)
        f.capacities[6]=2;Inventory.CaptureBank();equal(Inventory.Totals().items[248684],nil)
    end)
end)
test("alt snapshots are isolated by market and shared bank is counted once",function()
    inventoryFixture(function(f)
        f.bags[0]={{id=248683,count=2}};f.bags[6]={{id=2770,count=10}};f.bags[15]={{id=248685,count=4}}
        Inventory.CaptureBags();Inventory.bankOpen=true;Inventory.CaptureBank()
        f.guid,f.name="Player-Alt","Alt";f.bags[0]={{id=248684,count=3}}
        Inventory.CaptureBags();Inventory.CaptureBank()
        local totals=Inventory.Totals()
        equal(totals.items[248683],2);equal(totals.items[248684],3);equal(totals.items[248685],4)
        equal(totals.items[2770],20);equal(totals.characters,2)
        addon.db.tracking.alts=false;totals=Inventory.Totals()
        equal(totals.items[248683],nil);equal(totals.items[248684],3);equal(totals.items[248685],4)
        addon.db.tracking.bank=false;equal(Inventory.Totals().items[248685],nil)
        local original=UnitFactionGroup;UnitFactionGroup=function() return "Horde" end
        equal(next(Inventory.Totals().items),nil);UnitFactionGroup=original
    end)
end)
test("disabling tracking stops capture and hides remembered counts without deleting snapshots",function()
    inventoryFixture(function(f)
        f.bags[0]={{id=248683,count=2}};Inventory.CaptureBags()
        addon:SetFeature("tracking",false);f.bags[0]={};Inventory.CaptureBags()
        equal(next(Inventory.Totals().items),nil)
        equal(addon.db.inventory.characters[f.guid].bags.items[248683],2)
        addon:SetFeature("tracking",true);equal(Inventory.Totals().items[248683],nil)
    end)
end)
test("automatic refresh scans only missing or failed tracked materials",function()
    inventoryFixture(function(f)
        f.bags[0]={{id=248683,count=1}};Inventory.CaptureBags()
        addon.db.source="own";addon.scanner:SetOpen(true)
        addon.autoPaused=false;addon.lastExternalAt=nil
        local market=addon:GetMarket();local oldItems,oldFailures=market.items,market.failures
        market.items={[2770]={kind="commodity",offers={},scannedAt=time()},[2771]={kind="commodity",offers={},scannedAt=time()}}
        market.failures={}
        addon:AutoScan();equal(addon.scanner.active,false)
        market.failures[2771]="timeout";addon:AutoScan();equal(addon.scanner.active,true)
        equal(#addon.scanner.queue,1);equal(addon.scanner.queue[1],2771)
        addon:StopScan();addon:RequestAutoScan();equal(addon.autoDue,nil)
        market.items,market.failures=oldItems,oldFailures
    end)
end)
test("auto refresh is opt-out and never queries away from AH or in forced provider mode",function()
    inventoryFixture(function(f)
        f.bags[0]={{id=248683,count=1}};Inventory.CaptureBags()
        addon.scanner:SetOpen(false);addon:RequestAutoScan();equal(addon.autoDue,nil)
        addon.scanner:SetOpen(true);addon.db.source="auctionator";addon:RequestAutoScan();equal(addon.autoDue,nil)
        addon.db.source="own";addon.autoPaused=false;addon:RequestAutoScan();assert(addon.autoDue)
        addon:SetFeature("autoscan",false);equal(addon.autoDue,nil);equal(addon.scanner.active,false)
    end)
end)
test("96 serial queries no longer pay the fixed 0.8-second delay",function()
    local f=TEST_SCANNER_FIXTURE();local ids={}
    for i=1,96 do ids[i]=i end
    f.full=true;f.scanner:Start(ids)
    for i=1,96 do
        f.scanner:Results("commodity",i)
        if i<96 then f.now=f.now+0.051;f.scanner:Tick() end
    end
    equal(f.scanner.completed,96);assert(f.now<5);equal(#f.calls,96)
end)
test("rolling request budget persists across restarts and waits for expiry",function()
    local f=TEST_SCANNER_FIXTURE();local ids={}
    for i=1,101 do ids[i]=i end
    f.full=true;f.scanner:Start(ids)
    for i=1,100 do
        f.scanner:Results("commodity",i);f.now=f.now+0.051;f.scanner:Tick()
    end
    equal(#f.calls,100);equal(f.scanner.active,true)
    f.scanner:Stop();f.scanner:Start({101});equal(#f.calls,100)
    f.now=60.11;f.scanner:Tick();equal(#f.calls,101)
end)
test("externally observed auction queries consume the shared budget",function()
    local f=TEST_SCANNER_FIXTURE()
    for i=1,100 do f.scanner:ExternalQuery() end
    f.scanner:Start({1});equal(#f.calls,0)
    f.now=60.11;f.scanner:Tick();equal(#f.calls,1)
end)
test("waiting to request another page is not mistaken for a response timeout",function()
    local f=TEST_SCANNER_FIXTURE();f.scanner:Start({1});f.scanner:Results("commodity",1)
    f.ready=false;f.now=16;f.scanner:Tick()
    equal(f.scanner.pending.attempt,1);equal(f.scanner.pending.action,"more")
end)
test("one outer auction tab contains native internal category tabs without changing Blizzard tabs",function()
    local lib=LibStub("LibAHTab-1-0")
    local oldState=lib.internalState
    local oldAH,oldMode=AuctionHouseFrame,AuctionHouseFrameDisplayMode
    local oldResize,oldSelect,oldDeselect=PanelTemplates_TabResize,PanelTemplates_SelectTab,PanelTemplates_DeselectTab
    local ok,err=pcall(function()
        lib.internalState=nil
        PanelTemplates_TabResize=function() end
        PanelTemplates_SelectTab=function(tab) tab.selected=true end
        PanelTemplates_DeselectTab=function(tab) tab.selected=false end
        AuctionHouseFrame=CreateFrame("Frame",nil,UIParent)
        AuctionHouseFrame.Tabs={CreateFrame("Button"),CreateFrame("Button"),CreateFrame("Button")}
        AuctionHouseFrame.SetDisplayMode=function(self,mode) self.displayMode=mode end
        AuctionHouseFrame.SetTitle=function(self,title) self.title=title end
        AuctionHouseFrameDisplayMode={Buy={"BuyFrame"}}
        addon.scanAutomatic=false;addon.scanner:SetOpen(true);addon.db.browserTab="crates"
        addon.UI.AttachAuction();assert(addon.UI.auctionHost)
        equal(#AuctionHouseFrame.Tabs,3);equal(#lib.internalState.Tabs,1)
        equal(addon.UI.browserTabs.writs.text,"Craftsman's Writs")
        equal(lib:DoesIDExist("WaylaidLedger"),true);equal(lib:DoesIDExist("WaylaidLedgerWrits"),false)
        addon.UI.Toggle();equal(addon.UI.auctionHosts.crates:GetParent(),addon.UI.auctionHost)
        equal(addon.UI.auctionHost:IsShown(),true);equal(addon.UI.frame,nil)
        local writHost=addon.UI.auctionHosts.writs
        addon.UI.browserTabs.writs.scripts.OnClick()
        equal(writHost:IsShown(),true);equal(addon.UI.auctionHost:IsShown(),true)
        equal(addon.UI.auctionHosts.crates:IsShown(),false);equal(addon.db.browserTab,"writs")
        equal(addon.UI.IsScanPanelVisible(),false)
        local writView=addon.BrowseUI.views.writs
        writView.search:SetText("Crafted Solid Shot");writView.search.scripts.OnTextChanged(writView.search)
        equal(#writView.visibleEntries,1)
        addon.UI.SelectBrowserTab("crates");addon.UI.SelectBrowserTab("writs")
        equal(writView.search:GetText(),"Crafted Solid Shot");equal(#writView.visibleEntries,1)
        equal(#lib.internalState.Tabs,1)
        addon.UI.SelectBrowserTab("crates");addon.scanAutomatic=true
        addon.scanMarket=addon:GetMarket();addon.scanner:Start({2770});assert(addon.scanner.active)
        addon.UI.SelectBrowserTab("writs")
        equal(addon.scanner.active,false);equal(addon.autoDue,nil)
        addon.scanAutomatic=false
        addon.UI.browserTabs.crates.scripts.OnClick();equal(writHost:IsShown(),false)
        equal(addon.UI.IsScanPanelVisible(),true)
        local other=CreateFrame("Frame",nil,AuctionHouseFrame)
        lib:CreateTab("OtherAddonTest",other,"Other")
        lib:SetSelected("OtherAddonTest");equal(addon.UI.auctionHost:IsShown(),false);equal(other:IsShown(),true)
        addon.UI.Toggle();equal(addon.UI.auctionHost:IsShown(),true);equal(other:IsShown(),false)
        addon.UI.Toggle();equal(addon.UI.auctionHost:IsShown(),false)
        addon.UI.AuctionClosed();equal(addon.UI.auctionHost:IsShown(),false)
    end)
    lib.internalState=oldState
    AuctionHouseFrame,AuctionHouseFrameDisplayMode=oldAH,oldMode
    PanelTemplates_TabResize,PanelTemplates_SelectTab,PanelTemplates_DeselectTab=oldResize,oldSelect,oldDeselect
    addon.UI.auctionHost,addon.UI.tabLibrary,addon.UI.auctionHosts,addon.UI.browserTabs=nil,nil,nil,nil
    addon.BrowseUI.views={};addon.autoDue=nil;addon:UpdateScheduler()
    assert(ok,err)
end)
test("minimap visibility, settings click, dragging and saved angle work",function()
    local oldMap,oldCursor=Minimap,GetCursorPosition
    Minimap=CreateFrame("Frame",nil,UIParent);Minimap:SetSize(140,140)
    Minimap.GetCenter=function() return 100,100 end;Minimap.GetEffectiveScale=function() return 1 end
    GetCursorPosition=function() return 200,100 end
    addon.MinimapButton.Create();local button=addon.MinimapButton.frame
    addon:SetFeature("minimap",false);equal(button:IsShown(),false)
    addon:SetFeature("minimap",true);equal(button:IsShown(),true)
    button.scripts.OnDragStart(button);button.scripts.OnUpdate()
    equal(addon.db.minimap.angle,0);equal(button.point[4],78);equal(button.point[5],0)
    button.scripts.OnDragStop(button);equal(button.scripts.OnUpdate,nil)
    addon.scanner:SetOpen(false)
    button.scripts.OnClick(button,"LeftButton");assert(addon.UI.settings:IsShown());equal(addon.UI.frame,nil)
    addon.UI.settings:Hide()
    button.scripts.OnClick(button,"RightButton");assert(addon.UI.settings:IsShown())
    addon.UI.settings:Hide();button:Hide();addon.MinimapButton.frame=nil
    Minimap,GetCursorPosition=oldMap,oldCursor
end)
test("compact scan and Auctionator prices share layout without source badges",function()
    local oldSource,oldA,oldDetails=addon.db.source,Auctionator,addon.db.tooltipDetails
    local market=addon:GetMarket();local oldItems,oldFailures=market.items,market.failures
    market.items={[2770]={kind="commodity",offers={{quantity=20,unitPrice=125}},scannedAt=time()},
        [2771]={kind="commodity",offers={{quantity=20,unitPrice=250}},scannedAt=time()}}
    market.failures={};addon.db.source="own";addon.db.tooltipDetails=false
    local own=CreateFrame("GameTooltip");addon.Tooltip.Append(own,248683)
    Auctionator={API={v1={GetAuctionPriceByItemID=function(_,id) return id==2770 and 125 or 250 end,GetAuctionAgeByItemID=function() return 0 end}}}
    addon.db.source="auctionator";addon.Providers.Invalidate()
    local imported=CreateFrame("GameTooltip");addon.Tooltip.Append(imported,248683)
    equal(own.lines[3][1],imported.lines[3][1]);equal(#own.lines,#imported.lines)
    local function plain(value) return value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("~ ", "") end
    equal(plain(own.lines[3][2]),plain(imported.lines[3][2]))
    assert(#imported.lines[3][2] - #own.lines[3][2] <= 2)
    addon.db.source,Auctionator,addon.db.tooltipDetails=oldSource,oldA,oldDetails
    market.items,market.failures=oldItems,oldFailures;addon.Providers.Invalidate()
end)
test("Shift reveals price age without making the compact default wider",function()
    local oldShift,oldDetails=IsShiftKeyDown,addon.db.tooltipDetails
    addon.db.tooltipDetails=false;IsShiftKeyDown=function() return true end
    local tooltip=CreateFrame("GameTooltip");addon.Tooltip.Append(tooltip,248683)
    equal(#tooltip.lines,2+#addon.Crates[248683].options)
    assert(tooltip.lines[3][2]:match(" %- "))
    IsShiftKeyDown,addon.db.tooltipDetails=oldShift,oldDetails
end)
