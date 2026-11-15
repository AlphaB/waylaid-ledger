local addon, test, equal = ...

local function fixture(action)
    local old={source=addon.db.source,profile=addon.db.profile,details=addon.db.tooltipDetails,
        shift=IsShiftKeyDown,auctionator=Auctionator,tsm=TSM_API,wall=time}
    addon.db.source,addon.db.profile,addon.db.tooltipDetails="own","default",false
    IsShiftKeyDown=function() return false end;time=function() return 100000 end
    local market=addon:GetMarket();old.items,old.failures=market.items,market.failures
    market.items,market.failures={},{}
    local ok,err=pcall(action,market)
    addon.db.source,addon.db.profile,addon.db.tooltipDetails=old.source,old.profile,old.details
    IsShiftKeyDown,Auctionator,TSM_API,time=old.shift,old.auctionator,old.tsm,old.wall
    market.items,market.failures=old.items,old.failures
    addon.Providers.Invalidate()
    assert(ok,err)
end
local function snapshot(age)
    return {kind="commodity",offers={{quantity=100,unitPrice=10}},scannedAt=time()-age}
end
local function noticeCount(tip)
    local count=0
    for _,line in ipairs(tip.lines) do
        if line[1]=="Price data might be outdated." then count=count+1;equal(line[2],0.6);equal(line[3],0.6);equal(line[4],0.6) end
    end
    return count
end

test("compact tooltips contain prices only, without badges, legends or usage footers",function()
    fixture(function(market)
        market.items[2770],market.items[2771]=snapshot(0),snapshot(0)
        local tip=CreateFrame("GameTooltip");addon.Tooltip.Append(tip,248683)
        equal(#tip.lines,4);equal(noticeCount(tip),0)
        for _,line in ipairs(tip.lines) do
            assert(not line[1]:match("~ estimate") and not line[1]:match("Full bundle"))
            if type(line[2])=="string" then assert(not line[2]:match("%[[ASTM]%]") and not line[2]:match(" stale")) end
        end
    end)
end)
test("outdated notice appears strictly after 12 hours for own scan prices and only once",function()
    fixture(function(market)
        market.items[2770],market.items[2771]=snapshot(43200),snapshot(43200)
        local boundary=CreateFrame("GameTooltip");addon.Tooltip.Append(boundary,248683)
        equal(noticeCount(boundary),0)
        market.items[2770],market.items[2771]=snapshot(43201),snapshot(90000)
        local old=CreateFrame("GameTooltip");addon.Tooltip.Append(old,248683)
        equal(noticeCount(old),1);equal(#old.lines,5)
        addon.Tooltip.Append(old,248683);equal(noticeCount(old),1)
        addon.Tooltip.AddAgeWarning(old,{{status="ok",age=90000}});equal(noticeCount(old),1)
        old.scripts.OnTooltipCleared(old);old.lines={}
        market.items[2770],market.items[2771]=snapshot(0),snapshot(0)
        addon.Tooltip.Append(old,248683);equal(noticeCount(old),0)
    end)
end)
test("scan freshness cutoff does not produce a 12-hour warning for a 31-minute quote",function()
    fixture(function(market)
        market.items[2770],market.items[2771]=snapshot(1860),snapshot(1860)
        local tip=CreateFrame("GameTooltip");addon.Tooltip.Append(tip,248683)
        equal(noticeCount(tip),0);equal(#tip.lines,4)
    end)
end)
test("Auctionator previous-day prices get a cautious notice without invented hourly age",function()
    fixture(function()
        addon.db.source="auctionator"
        Auctionator={API={v1={GetAuctionPriceByItemID=function() return 10 end,GetAuctionAgeByItemID=function() return 1 end}}}
        addon.Providers.Invalidate()
        local tip=CreateFrame("GameTooltip");addon.Tooltip.Append(tip,248683)
        equal(noticeCount(tip),1);assert(not tip.lines[3][2]:match("%[A%]"))
        Auctionator.API.v1.GetAuctionAgeByItemID=function() return 0 end;addon.Providers.Invalidate()
        tip=CreateFrame("GameTooltip");addon.Tooltip.Append(tip,248683);equal(noticeCount(tip),0)
    end)
end)
test("unknown provider age stays unknown and no timestamp is fabricated",function()
    fixture(function()
        addon.db.source="tsm";Auctionator=nil
        TSM_API={GetCustomPriceValue=function() return 10 end};addon.Providers.Invalidate()
        local tip=CreateFrame("GameTooltip");addon.Tooltip.Append(tip,248683)
        equal(noticeCount(tip),0);equal(#tip.lines,4)
        IsShiftKeyDown=function() return true end
        tip=CreateFrame("GameTooltip");addon.Tooltip.Append(tip,248683)
        assert(tip.lines[3][2]:match("age unknown"));equal(#tip.lines,4)
    end)
end)
test("purchase age is checked in basket hover without restoring the old gray footer",function()
    fixture(function()
        local oldTip=GameTooltip;GameTooltip=CreateFrame("GameTooltip")
        local row={entry={itemID=264050,kind="writs",deliveryRows={{itemID=4245,quantity=1,status="ok",cost=50,
            source="auctionator",sourceLabel="Auctionator",estimated=true,ageDays=0}},
            purchaseQuote={status="ok",cost=100,source="auctionator",sourceLabel="Auctionator",estimated=true,ageDays=1},total=150}}
        addon.BrowseUI.ShowTooltip(row)
        equal(noticeCount(GameTooltip),1)
        for _,line in ipairs(GameTooltip.lines) do assert(not line[1]:match("Click to search") and not line[1]:match("Full quantities")) end
        GameTooltip=oldTip
    end)
end)

test("old sold-out scan results receive the same outdated-data notice",function()
    fixture(function(market)
        market.items[2770]={kind="commodity",offers={},scannedAt=time()-43201}
        market.items[2771]={kind="commodity",offers={},scannedAt=time()-43201}
        local tip=CreateFrame("GameTooltip");addon.Tooltip.Append(tip,248683)
        equal(noticeCount(tip),1);equal(tip.lines[3][2],"None listed")
    end)
end)
