local test, equal = ...
local function fixture(action)
    local saved={C_Item=C_Item,C_TooltipInfo=C_TooltipInfo,GetLocale=GetLocale,GetBuildInfo=GetBuildInfo,time=time,C_Container=C_Container}
    local a={db={},Crates={},Writs={},MaterialNames={},WritMaterialNames={}}
    local names, tips = {}, {}
    C_Item={GetItemNameByID=function(id) return names[id] end,RequestLoadItemDataByID=function() end}
    C_TooltipInfo={GetItemByID=function(id) return tips[id] end}
    GetLocale=function() return "enUS" end;GetBuildInfo=function() return "1","2","3",16001 end;time=function() return 100 end
    C_Container=nil
    assert(loadfile(PROJECT_ROOT.."/WaylaidLedger/Discovery.lua"))("WaylaidLedger",a)
    a.Discovery.Install()
    local ok,err=pcall(action,a,names,tips)
    for key,value in pairs(saved) do _G[key]=value end
    C_Container=saved.C_Container;C_TooltipInfo=saved.C_TooltipInfo
    assert(ok,err)
end

test("requirements start empty and are learned from live descriptions and exact AH names",function()
    fixture(function(a,names,tips)
        equal(next(a.Crates),nil);equal(next(a.Writs),nil)
        a.Discovery.Observe(11,"Sample Herb");a.Discovery.Observe(12,"Other Herb")
        a.Discovery.Observe(21,"Waylaid Crate: Test")
        tips[21]={lines={{leftText="Requires Level 10"},{leftText="Fill with one of the following:"},{leftText="• 17 Sample Herb\n- 9 Other Herb"}}}
        equal(a.Discovery.Read(21),true)
        equal(a.Crates[21].options[1].quantity,17);equal(a.Crates[21].options[2].itemID,12);equal(a.Crates[21].requirements,nil)
        equal(a.db.discovery.locales.enUS.crates[21],a.Crates[21])
        a.Discovery.Observe(31,"Craftsman's Writ: Test")
        tips[31]={lines={{leftText="Bring 200 Sample Herb to the quartermaster."}}}
        equal(a.Discovery.Read(31),true);equal(a.Writs[31].requirements[1].quantity,200)
    end)
end)
test("item hyperlinks resolve IDs without a preexisting item-name catalog",function()
    fixture(function(a,names,tips)
        a.Discovery.Observe(31,"Craftsman's Writ: Test")
        tips[31]={lines={{leftText="Deliver 3 |cffffffff|Hitem:11:0|h[Sample Herb]|h|r."}}}
        a.Discovery.Observe(12,"Sample Herb")
        equal(a.Discovery.Read(31),true);equal(a.Writs[31].requirements[1].itemID,11)
    end)
end)
test("unresolved or ambiguous goods never produce partial delivery definitions",function()
    fixture(function(a,names,tips)
        a.Discovery.Observe(11,"Herb");a.Discovery.Observe(12,"Ore")
        a.Discovery.Observe(21,"Waylaid Crate: Test")
        tips[21]={lines={{leftText="- 3 Herb\n- 7 Ore\n- 8 Missing"}}}
        equal(a.Discovery.Read(21),false);equal(#a.Crates[21].options,0)
        a.Discovery.Observe(13,"Missing")
        equal(a.Discovery.Read(21),true);equal(#a.Crates[21].options,3)
        a.Discovery.Observe(14,"Ore")
        equal(a.Discovery.Read(21),false);equal(#a.Crates[21].options,0)
        equal(a.Crates[21].unresolved,true)
    end)
end)
test("late item data retries requirements without keeping stale changed quantities",function()
    fixture(function(a,names,tips)
        a.Discovery.Observe(11,"Herb");a.Discovery.Observe(31,"Craftsman's Writ: Test")
        equal(a.Discovery.Read(31),false)
        tips[31]={lines={{leftText="Requires: 2 Herb"}}}
        equal(a.Discovery.Retry(),1);equal(a.Writs[31].requirements[1].quantity,2)
        tips[31]={lines={{leftText="Deliver 6 Unloaded Herb"}}}
        equal(a.Discovery.Read(31),false);equal(#a.Writs[31].requirements,0)
    end)
end)
test("rewards and use text are not treated as delivery requirements",function()
    fixture(function(a)
        a.Discovery.Observe(11,"Herb")
        equal(a.Discovery.Parse({{leftText="Use: Bring 3 Herb"},{leftText="Reward: 5 Herb"}},"writs",31),nil)
        equal(a.Discovery.Parse({{leftText="- 0 Herb"}},"writs",31),nil)
        equal(a.Discovery.Parse({{leftText="- 3 Herb\n- loading..."}},"crates",21),nil)
    end)
end)
