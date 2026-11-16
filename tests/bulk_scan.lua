local test,equal=...
local function fixture(action)
    local saved={CreateFrame=CreateFrame,hooksecurefunc=hooksecurefunc,debugprofilestop=debugprofilestop}
    local frames={}
    CreateFrame=function()
        local f={scripts={},events={}}
        function f:SetScript(key,fn) self.scripts[key]=fn end
        function f:RegisterEvent(key) self.events[key]=true end
        frames[#frames+1]=f;return f
    end
    hooksecurefunc=function(t,k,fn) local old=t[k];t[k]=function(...) old(...);fn(...) end end
    local market={items={},failures={}}
    local f={now=0,wall=1000,rows={},calls=0,observed={},retries=0}
    local a={db={maxAge=1800,replication={oldRealm=1000}},GetMarket=function() return market end,
        Discovery={Observe=function(id,name) f.observed[id]=name end,Retry=function() f.retries=f.retries+1;return 0 end,Bags=function() end}}
    for _,name in ipairs({"Localization","Locales","Scanner","BulkScan","Pricing"}) do assert(loadfile(PROJECT_ROOT.."/WaylaidLedger/"..name..".lua"))("WaylaidLedger",a) end
    local api={IsThrottledMessageSystemReady=function() return true end,
        ReplicateItems=function() f.calls=f.calls+1 end,GetNumReplicateItems=function() return #f.rows end,
        GetReplicateItemInfo=function(index) return unpack(f.rows[index+1],1,18) end}
    f.scanner=a.Scanner.New(api,{now=function() return f.now end,wallTime=function() return f.wall end},{})
    a.scanner=f.scanner;f.scanner:SetOpen(true);a.BulkScan.Install(f.scanner)
    f.frame=frames[1];f.market=market;f.addon=a;f.api=api
    function f.row(id,name,count,buyout)
        local row={[1]=name,[3]=count,[10]=buyout,[17]=id,[18]=true};return row
    end
    function f.deliver()
        f.frame.scripts.OnEvent(f.frame,"REPLICATE_ITEM_LIST_UPDATE")
        while f.frame.scripts.OnUpdate do f.frame.scripts.OnUpdate() end
    end
    local ok,err=pcall(action,f)
    CreateFrame,hooksecurefunc=saved.CreateFrame,saved.hooksecurefunc
    debugprofilestop=saved.debugprofilestop
    assert(ok,err)
end

test("6000 auctions use one request and bounded processing batches",function()
    fixture(function(f)
        for index=1,6000 do f.rows[index]=f.row(index,"Item "..index,10,100) end
        equal(f.scanner:Start({}),true);equal(f.calls,1)
        f.frame.scripts.OnEvent(f.frame,"REPLICATE_ITEM_LIST_UPDATE")
        equal(f.scanner.active,true);equal(next(f.observed),nil)
        f.scanner:Tick();equal(next(f.observed),nil)
        f.frame.scripts.OnUpdate()
        equal(f.observed[250],"Item 250");equal(f.observed[251],nil)
        local batches=1
        while f.frame.scripts.OnUpdate do f.frame.scripts.OnUpdate();batches=batches+1 end
        equal(batches,24);equal(f.scanner.completed,6000);equal(f.calls,1)
        local quote=f.addon.Pricing.Quote(f.market.items[6000],200)
        equal(quote.cost,2000);equal(quote.estimated,true);equal(quote.available,nil)
    end)
end)
test("bulk snapshots use correct buyout tuple index and retain minimum unit prices",function()
    fixture(function(f)
        f.rows={f.row(11,"Herb",20,100),f.row(11,"Herb",5,50),f.row(12,"Ore",1,0)}
        f.scanner:Start({11,12});f.deliver()
        equal(f.market.items[11].unitPrice,5);equal(f.market.items[12],nil)
        equal(f.observed[12],"Ore");equal(f.retries,1)
        equal(f.addon.Pricing.Quote(f.market.items[11],200).cost,1000)
        equal(f.addon.Pricing.Quote(f.market.items[12],1).status,"unknown")
    end)
end)
test("fresh exact shortages survive full-scan estimates",function()
    fixture(function(f)
        f.market.items[11]={kind="commodity",offers={},scannedAt=f.wall}
        f.rows={f.row(11,"Herb",20,100)}
        f.scanner:Start({11});f.deliver()
        equal(f.addon.Pricing.Quote(f.market.items[11],1).status,"short")
    end)
end)
test("manual full scans ignore old persisted lockouts and can refresh immediately",function()
    fixture(function(f)
        equal(f.addon.db.replication,nil)
        f.addon.db.replication={oldRealm=f.wall}
        f.rows={f.row(11,"Herb",20,100)}
        equal(f.scanner:Start({11}),true);equal(f.calls,1)
        equal(f.scanner:Start({11}),false);equal(f.calls,1)
        f.deliver();equal(f.market.items[11].unitPrice,5)
        f.rows={f.row(11,"Herb",20,200)}
        equal(f.scanner:Start({11}),true);equal(f.calls,2)
        f.deliver();equal(f.market.items[11].unitPrice,10)
    end)
end)
test("another addon's bulk response is reused without sending a second query",function()
    fixture(function(f)
        f.rows={f.row(11,"Herb",20,100)}
        f.api.ReplicateItems();equal(f.scanner.active,false)
        f.deliver();equal(f.market.items[11].unitPrice,5);equal(f.calls,1)
        equal(f.scanner:Start({11}),true);equal(f.calls,2)
    end)
end)
test("cancelled and closed full scans ignore late responses",function()
    fixture(function(f)
        f.rows={f.row(11,"Herb",20,100)}
        f.scanner:Start({});f.scanner:Stop()
        f.frame.scripts.OnEvent(f.frame,"REPLICATE_ITEM_LIST_UPDATE")
        equal(next(f.market.items),nil);equal(f.frame.scripts.OnUpdate,nil)
        f.scanner:Start({})
        f.frame.scripts.OnEvent(f.frame,"AUCTION_HOUSE_CLOSED")
        f.frame.scripts.OnEvent(f.frame,"REPLICATE_ITEM_LIST_UPDATE")
        equal(next(f.market.items),nil)
    end)
end)
test("full scan times out without recording missing items as sold out",function()
    fixture(function(f)
        f.scanner:Start({});f.now=31;f.scanner:Tick()
        equal(f.scanner.active,false);equal(next(f.market.items),nil);equal(f.frame.scripts.OnUpdate,nil)
    end)
end)

test("a request waiting for readiness can be retried immediately after timing out",function()
    fixture(function(f)
        f.api.IsThrottledMessageSystemReady=function() return false end
        f.scanner:Start({});equal(f.calls,0)
        f.now=31;f.scanner:Tick();equal(f.scanner.active,false)
        equal(f.addon.db.replication,nil)
        f.api.IsThrottledMessageSystemReady=function() return true end
        equal(f.scanner:Start({}),true);equal(f.calls,1)
    end)
end)
test("replicate read errors end the job without committing incomplete prices",function()
    fixture(function(f)
        f.api.GetReplicateItemInfo=function() error("data unavailable") end
        f.rows={f.row(11,"Herb",20,100)}
        f.scanner:Start({});f.deliver()
        equal(f.scanner.active,false);equal(next(f.market.items),nil)
    end)
end)

test("slow replication reads yield on elapsed time without timing out a progressing scan",function()
    fixture(function(f)
        local elapsed,reads=0,0
        debugprofilestop=function() return elapsed end
        local read=f.api.GetReplicateItemInfo
        f.api.GetReplicateItemInfo=function(index)
            elapsed=elapsed+2;reads=reads+1
            return read(index)
        end
        for id=1,100 do f.rows[id]=f.row(id,"Item "..id,10,100) end
        f.scanner:Start({})
        f.frame.scripts.OnEvent(f.frame,"REPLICATE_ITEM_LIST_UPDATE")
        equal(reads,0)
        for frame=1,100 do
            f.now=frame
            f.scanner:Tick();equal(reads,frame-1)
            f.frame.scripts.OnUpdate();equal(reads,frame)
        end
        equal(f.scanner.completed,100);equal(f.scanner.active,false)
        equal(f.market.items[100].unitPrice,10);equal(f.calls,1)
    end)
end)
