local passed = 0
local function equal(actual, expected, message)
    assert(actual == expected, (message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function test(name, fn)
    local ok, errorMessage = pcall(fn)
    assert(ok, name .. ": " .. tostring(errorMessage))
    passed = passed + 1
    print("PASS " .. name)
end
local addon = {}
local function loadModule(name)
    local chunk = assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/" .. name .. ".lua"))
    chunk("WaylaidLedger", addon)
end
for _, name in ipairs({ "Data", "Catalog", "Pricing", "Providers", "Scanner" }) do loadModule(name) end
local P = addon.Pricing
local function commodity(offers, at) return {kind="commodity", offers=offers, scannedAt=at or 100} end
local function item(offers) return {kind="item", offers=offers, scannedAt=100} end

test("catalog has 30 crates and 96 valid, unique materials", function()
    local crates = addon.Catalog.AllCrates()
    equal(#crates, 30)
    equal(#addon.Catalog.Materials(crates), 96)
    equal(#addon.Catalog.Materials({248682,248682}), 5)
    for _, id in ipairs(crates) do
        for _, option in ipairs(addon.Crates[id].options) do
            assert(addon.MaterialNames[option.itemID])
            assert(option.quantity > 0 and option.quantity == math.floor(option.quantity))
        end
    end
end)
test("commodity cost consumes depth rather than multiplying cheapest unit", function()
    local result = P.Quote(commodity({{quantity=3,unitPrice=10},{quantity=30,unitPrice=20}}),20)
    equal(result.cost,370);equal(result.purchased,20)
end)
test("unknown, empty and insufficient stock remain distinct", function()
    equal(P.Quote(nil,20).status,"unknown")
    local empty = P.Quote(commodity({}),20)
    equal(empty.status,"short");equal(empty.available,0)
    local short = P.Quote(commodity({{quantity=19,unitPrice=1}}),20)
    equal(short.status,"short");equal(short.available,19);equal(short.cost,nil)
end)
test("item auctions use minimum actual outlay, not unit price", function()
    local result=P.Quote(item({{quantity=20,buyoutAmount=1000},{quantity=6,buyoutAmount=400},{quantity=4,buyoutAmount=300}}),10)
    equal(result.cost,700);equal(result.purchased,10)
end)
test("single item auction cannot be reused", function()
    local result=P.Quote(item({{quantity=6,buyoutAmount=1},{quantity=20,buyoutAmount=100}}),10)
    equal(result.cost,100);equal(result.purchased,20)
end)
test("item quote counts excess units and prefers fewer on a cost tie", function()
    local result=P.Quote(item({{quantity=20,buyoutAmount=100},{quantity=10,buyoutAmount=100}}),10)
    equal(result.purchased,10);equal(result.cost,100)
end)
test("dynamic programming matches exhaustive subsets", function()
    math.randomseed(121)
    for iteration=1,200 do
        local offers={}
        for i=1,8 do offers[i]={quantity=math.random(1,20),buyoutAmount=math.random(1,100)} end
        local required=math.random(1,45)
        local best,bestQuantity=nil,nil
        for mask=0,255 do
            local bits,quantity,cost=mask,0,0
            for i=1,8 do
                if bits%2==1 then quantity=quantity+offers[i].quantity;cost=cost+offers[i].buyoutAmount end
                bits=math.floor(bits/2)
            end
            if quantity>=required and (not best or cost<best or (cost==best and quantity<bestQuantity)) then
                best,bestQuantity=cost,quantity
            end
        end
        local quote=P.Quote(item(offers),required)
        equal(quote.cost,best)
        if best then equal(quote.purchased,bestQuantity) else equal(quote.status,"short") end
    end
end)
local crate={options={{itemID=1,quantity=10},{itemID=2,quantity=10},{itemID=3,quantity=10}}}
test("all tied lowest fresh options highlighted, missing alternative stays unknown", function()
    local rows,known=P.Evaluate(crate,{[1]=commodity({{quantity=10,unitPrice=1}}),[2]=commodity({{quantity=10,unitPrice=1}})},100,1800)
    equal(known,false);equal(rows[1].best,true);equal(rows[2].best,true);equal(rows[3].best,false)
end)
test("stale and failed prices never win", function()
    local snapshots={[1]=commodity({{quantity=10,unitPrice=1}},1),[2]=commodity({{quantity=10,unitPrice=2}},2000),[3]=commodity({{quantity=10,unitPrice=3}},2000)}
    local rows,known=P.Evaluate(crate,snapshots,2000,1800,{[2]="timeout"})
    equal(known,false);equal(rows[1].best,false);equal(rows[2].best,false);equal(rows[3].best,true)
    equal(rows[1].stale,true);equal(rows[2].error,"timeout")
end)
test("fresh sold-out alternatives count as known",function()
    local rows,known=P.Evaluate(crate,{[1]=commodity({}),[2]=commodity({}),[3]=commodity({{quantity=10,unitPrice=1}})},100,1800)
    equal(known,true);equal(rows[3].best,true)
end)

local function scannerFixture()
    local state={now=0,ready=true,full=false,rows={},calls={},saved={},failed={},logs={}}
    local api={}
    api.MakeItemKey=function(id) return {itemID=id,itemLevel=0,itemSuffix=0,battlePetSpeciesID=0} end
    api.IsThrottledMessageSystemReady=function() return state.ready end
    api.SendSearchQuery=function(key,sorts,separate)
        equal(separate,true)
        state.calls[#state.calls+1]={method="search",id=key.itemID,at=state.now}
    end
    api.RequestMoreCommoditySearchResults=function(id) state.calls[#state.calls+1]={method="commodityPage",id=id,at=state.now} end
    api.RequestMoreItemSearchResults=function(key) state.calls[#state.calls+1]={method="itemPage",id=key.itemID,at=state.now} end
    api.HasFullCommoditySearchResults=function() return state.full end
    api.HasFullItemSearchResults=function() return state.full end
    api.GetNumCommoditySearchResults=function() return #state.rows end
    api.GetNumItemSearchResults=function() return #state.rows end
    api.GetCommoditySearchResultInfo=function(_,index) return state.rows[index] end
    api.GetItemSearchResultInfo=function(_,index) return state.rows[index] end
    local scanner=addon.Scanner.New(api,{now=function() return state.now end,wallTime=function() return 1000+state.now end},{
        saved=function(id,snapshot) state.saved[id]=snapshot end,
        failed=function(id,why) state.failed[id]=why end,
        log=function(message) state.logs[#state.logs+1]=message end,
    })
    state.scanner,state.api=scanner,api
    scanner:SetOpen(true)
    return state
end

test("scanner requires auction house and nonempty queue",function()
    local f=scannerFixture();f.scanner:SetOpen(false)
    equal(f.scanner:Start({1}),false)
    f.scanner:SetOpen(true);equal(f.scanner:Start({}),false)
end)
test("deduplicated queue is serialized and paced",function()
    local f=scannerFixture();f.scanner:Start({1,1,2})
    equal(#f.calls,1);equal(f.calls[1].id,1)
    f.full=true;f.scanner:Results("commodity",1)
    f.now=0.7;f.scanner:Tick();equal(#f.calls,1)
    f.now=0.8;f.scanner:Tick();equal(#f.calls,2);equal(f.calls[2].id,2)
    f.scanner:Results("commodity",2)
    equal(f.scanner.active,false);equal(f.scanner.completed,2);equal(f.scanner.failed,0)
end)
test("incomplete commodity results are paginated and saved only when full",function()
    local f=scannerFixture();f.scanner:Start({1});f.rows={{quantity=5,unitPrice=10}}
    f.scanner:Results("commodity",1);equal(f.saved[1],nil)
    f.scanner:Results("commodity",1)
    f.now=0.8;f.scanner:Tick();equal(#f.calls,2);equal(f.calls[2].method,"commodityPage")
    f.rows={{quantity=5,unitPrice=10},{quantity=20,unitPrice=20}};f.full=true
    f.scanner:Results("commodity",1)
    equal(P.Quote(f.saved[1],10).cost,150)
end)
test("wrong ID and wrong item key events are ignored",function()
    local f=scannerFixture();f.scanner:Start({1});f.full=true
    f.scanner:Results("commodity",2)
    f.scanner:Results("item",{itemID=1,itemLevel=10})
    equal(f.scanner.completed,0);equal(f.saved[1],nil)
end)
test("owned commodity amounts removed, account buckets excluded, tiers sorted",function()
    local f=scannerFixture();f.scanner:Start({1});f.full=true
    f.rows={{quantity=20,numOwnerItems=5,unitPrice=20},{quantity=10,numOwnerItems=0,unitPrice=1,containsAccountItem=true},{quantity=5,unitPrice=10}}
    f.scanner:Results("commodity",1)
    equal(#f.saved[1].offers,2);equal(f.saved[1].offers[1].unitPrice,10)
    equal(P.Quote(f.saved[1],20).cost,350)
end)
test("item scanner excludes bids, owned auctions, and duplicates",function()
    local f=scannerFixture();local key=f.api.MakeItemKey(1)
    f.scanner:Start({1});f.full=true
    f.rows={{itemKey=key,auctionID=1,quantity=10,buyoutAmount=300},{itemKey=key,auctionID=1,quantity=10,buyoutAmount=300},
        {itemKey=key,auctionID=2,quantity=10,buyoutAmount=1,containsOwnerItem=true},{itemKey=key,auctionID=3,quantity=10,buyoutAmount=1,containsAccountItem=true},
        {itemKey=key,auctionID=4,quantity=10,buyoutAmount=0}}
    f.scanner:Results("item",key)
    equal(#f.saved[1].offers,1);equal(P.Quote(f.saved[1],10).cost,300)
end)
test("item results pagination uses full item keys",function()
    local f=scannerFixture();local key=f.api.MakeItemKey(1)
    f.scanner:Start({1});f.scanner:Results("item",key)
    f.now=0.8;f.scanner:Tick();equal(f.calls[2].method,"itemPage")
    f.full=true;f.scanner:Results("item",key)
    equal(f.saved[1].kind,"item")
end)
test("throttle blocks requests until ready",function()
    local f=scannerFixture();f.ready=false;f.scanner:Start({1})
    equal(#f.calls,0);f.now=2;f.scanner:Tick();equal(#f.calls,0)
    f.ready=true;f.scanner:Tick();equal(#f.calls,1)
end)
test("no-response timeout retries once then records failure",function()
    local f=scannerFixture();f.scanner:Start({1})
    f.now=16;f.scanner:Tick();equal(#f.calls,2)
    f.now=32;f.scanner:Tick();equal(f.scanner.active,false);equal(f.scanner.failed,1);assert(f.failed[1])
end)
test("stuck throttle eventually times out",function()
    local f=scannerFixture();f.ready=false;f.scanner:Start({1})
    f.now=91;f.scanner:Tick();equal(f.scanner.active,false);equal(f.scanner.failed,1)
end)
test("closing or stopping preserves completed data and rejects late events",function()
    local f=scannerFixture();f.scanner:Start({1,2});f.full=true;f.scanner:Results("commodity",1)
    f.now=1;f.scanner:Tick();f.scanner:SetOpen(false);f.scanner:Results("commodity",2)
    assert(f.saved[1]);equal(f.saved[2],nil);equal(f.scanner.active,false)
end)
test("competing searches stop scanning, own query hooks do not",function()
    local f=scannerFixture()
    local original=f.api.SendSearchQuery
    f.api.SendSearchQuery=function(...) original(...);f.scanner:ExternalQuery() end
    f.scanner:Start({1});equal(f.scanner.active,true)
    f.api.SendSearchQuery(f.api.MakeItemKey(2),{},true);equal(f.scanner.active,false)
end)
test("API errors mark failure without crashing scanner",function()
    local f=scannerFixture();f.api.SendSearchQuery=function() error("blocked") end
    f.scanner:Start({1});equal(f.scanner.failed,1);equal(f.scanner.active,false);assert(f.failed[1]:match("blocked"))
end)

-- Minimal UI/event host to load the entire addon, exercise the bootstrap and
-- render real tooltip strings. Production modules themselves are unmodified.
local frames={}
TEST_FRAMES=frames
local methods={}
function methods:SetScript(key,fn) self.scripts[key]=fn end
function methods:HookScript(key,fn)
    local old=self.scripts[key]
    self.scripts[key]=function(...) if old then old(...) end;fn(...) end
end
function methods:RegisterEvent(event) self.events[event]=true end
function methods:UnregisterEvent(event) self.events[event]=nil end
function methods:CreateFontString() return setmetatable({scripts={},events={}}, {__index=methods}) end
function methods:SetText(text) self.text=text end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetShown(shown) self.shown=shown end
function methods:AddLine(text,...) self.lines[#self.lines+1]={text,...} end
function methods:AddDoubleLine(left,right,...) self.lines[#self.lines+1]={left,right,...} end
function methods:HasScript() return true end
setmetatable(methods,{__index=function() return function() end end})
function CreateFrame(kind,name)
    local f=setmetatable({scripts={},events={},shown=false,lines={}}, {__index=methods})
    f.TitleText=f:CreateFontString()
    frames[#frames+1]=f
    if name then _G[name]=f end
    return f
end
UIParent={};UISpecialFrames={};SlashCmdList={};tinsert=table.insert
C_Item={GetItemNameByID=function() return nil end,RequestLoadItemDataByID=function() end}
GetTime=function() return 0 end;time=function() return 100 end;date=function() return "12:00:00" end
GetCurrentRegion=function() return 3 end;GetNormalizedRealmName=function() return "TestRealm" end;GetRealmName=GetNormalizedRealmName
UnitFactionGroup=function() return "Alliance" end;WOW_PROJECT_ID=1
GetBuildInfo=function() return "1.60.1","70790","Nov 2026",16001 end;GetLocale=function() return "enUS" end
DEFAULT_CHAT_FRAME={AddMessage=function() end}
TooltipDataProcessor={AddTooltipPostCall=function(_,callback) TooltipDataProcessor.callback=callback end}
Enum={TooltipDataType={Item=0}}
C_AuctionHouse=scannerFixture().api
function hooksecurefunc(tbl,key,callback)
    local original=tbl[key]
    tbl[key]=function(...) original(...);callback(...) end
end
NUM_TOTAL_EQUIPPED_BAG_SLOTS=5
local bags={[0]={248682,248683,248682,999},[5]={248684}}
C_Container={GetContainerNumSlots=function(bag) return bags[bag] and #bags[bag] or 0 end,
    GetContainerItemID=function(bag,slot) return bags[bag][slot] end}
for _, name in ipairs({"Tooltip","UI","Core"}) do loadModule(name) end
local host=frames[1]
host.scripts.OnEvent(host,"ADDON_LOADED","WaylaidLedger")

test("full addon bootstrap, bag enumeration and event registration",function()
    equal(addon.db.schema,1);equal(addon.db.maxAge,1800)
    equal(#addon.Catalog.BagCrates(),3)
    assert(host.events.AUCTION_HOUSE_SHOW)
    assert(type(SlashCmdList.WAYLAIDLEDGER)=="function")
    host.scripts.OnEvent(host,"AUCTION_HOUSE_SHOW");equal(addon.scanner.open,true)
    addon:Command("scan bags");equal(addon.scanner.active,true);equal(#addon.scanner.queue,9)
    assert(host.scripts.OnUpdate)
    addon:Command("stop");equal(host.scripts.OnUpdate,nil)
end)
test("tooltip lists every bundle, highlights cheapest and avoids duplicates",function()
    local tooltip=CreateFrame("GameTooltip","TestTooltip")
    local market=addon:GetMarket()
    for i,option in ipairs(addon.Crates[248682].options) do
        market.items[option.itemID]=commodity({{quantity=100,unitPrice=i*10}})
    end
    TooltipDataProcessor.callback(tooltip,{id=248682})
    local count=#tooltip.lines;equal(count,9)
    local best=0
    for _,line in ipairs(tooltip.lines) do if line[1]:match("^Cheapest:") then best=best+1 end end
    equal(best,1);equal(addon.lastCrateID,248682)
    TooltipDataProcessor.callback(tooltip,{id=248682});equal(#tooltip.lines,count)
    tooltip.scripts.OnTooltipCleared(tooltip);tooltip.lines={}
    TooltipDataProcessor.callback(tooltip,{id=248683})
    assert(tooltip.lines[3][2]:match("Not scanned"))
end)
test("unknown alternatives are labelled lowest verified, failures remain visible",function()
    local tooltip=CreateFrame("GameTooltip")
    local market=addon:GetMarket();market.items[2770]=commodity({{quantity=100,unitPrice=1}});market.failures[2771]="timeout"
    TooltipDataProcessor.callback(tooltip,{id=248683})
    equal(tooltip.lines[3][1]:sub(1,16),"Lowest verified:")
    assert(tooltip.lines[4][2]:match("scan failed"))
end)
test("unidentified crates explain identification without guessing a filling price",function()
    local tooltip=CreateFrame("GameTooltip")
    local previous=addon.lastCrateID
    TooltipDataProcessor.callback(tooltip,{id=248549})
    equal(#tooltip.lines,3);assert(tooltip.lines[3][1]:match("Identify"))
    equal(addon.lastCrateID,previous)
end)
test("cache profiles and factions are isolated, profile switch stops scan",function()
    local old=addon:GetMarket();old.items[999]={}
    addon:Command("scan hovered");assert(addon.scanner.active)
    addon:Command("market neutral");equal(addon.scanner.active,false);equal(addon:GetMarket().items[999],nil)
    addon:Command("market default");equal(addon:GetMarket(),old)
    UnitFactionGroup=function() return "Horde" end
    equal(addon:GetMarket().items[999],nil)
    UnitFactionGroup=function() return "Alliance" end
end)
test("diagnostic report and current-profile clear work",function()
    addon.lastCrateID=248682
    local report=addon:Report()
    assert(report:match("16001"));assert(report:match("248682"));assert(report:match("Recent scan log"))
    addon:Command("report");assert(addon.UI.report:IsShown())
    addon:Command("clear");equal(next(addon:GetMarket().items),nil)
end)
assert(loadfile(PROJECT_ROOT .. "/tests/integrations.lua"))(addon, test, equal, host)
assert(loadfile(PROJECT_ROOT .. "/tests/upstream_contracts.lua"))(addon, test, equal)
print(string.format("\n%d tests passed on %s",passed,_VERSION))
