local addon, test, equal = ...

test("settings register once on WoW's AddOns page and every entry point opens that category",function()
    local category=addon.UI.settingsCategory
    assert(category);equal(category.name,"Waylaid Ledger")
    local count=#Settings.categories
    addon.UI.RegisterSettings();addon.UI.RegisterSettings();equal(#Settings.categories,count)
    addon:Command("settings");equal(Settings.opened,category:GetID())
    equal(addon.UI.settings:GetParent(),SettingsPanel);equal(addon.UI.settings:IsVisible(),true)
    -- Slash and minimap both use the same registered-page opener.
    addon.UI.ToggleSettings();equal(Settings.opened,category:GetID())
    HideUIPanel(SettingsPanel);equal(addon.UI.settings:IsVisible(),false)
end)
test("settings dropdowns persist explicit crate, writ, TSM and scan preferences",function()
    local oldSource,oldWrit,oldTSM,oldScan=addon.db.source,addon.db.writSource,addon.db.tsmKey,addon.db.scanOnOpen
    for index,value in ipairs({"auto","own","auctionator","tsm"}) do
        addon.UI.crateSourceButton.choices[index].choose()
        equal(addon.db.source,value);equal(WaylaidLedgerDB.source,value)
        equal(addon.UI.crateSourceButton.choices[index].selected(),true)
    end
    for index,value in ipairs({"auto","own","auctionator","tsm","off"}) do
        addon.UI.writSourceButton.choices[index].choose()
        equal(addon.db.writSource,value);equal(WaylaidLedgerDB.writSource,value)
    end
    addon.UI.settingsTSM.choices[2].choose();equal(addon.db.tsmKey,"DBMarket")
    local check=addon.UI.settingsChecks.scanopen
    check:SetChecked(not oldScan);check.scripts.OnClick(check)
    equal(addon.db.scanOnOpen,not oldScan);equal(WaylaidLedgerDB.scanOnOpen,not oldScan)
    addon:SetFeature("scanopen",oldScan);addon:SetSource(oldSource);addon:SetWritSource(oldWrit);addon:SetTSMKey(oldTSM)
end)
test("slash settings use the same labels and obsolete controls open official settings",function()
    local oldSource=addon.db.source
    addon:Command("source own");equal(addon.UI.crateSourceButton.text,"Own scans")
    addon:Command("controls");equal(Settings.opened,addon.UI.settingsCategory:GetID())
    equal(addon.UI.frame,nil);equal(addon.UI.refreshModeButton,nil)
    addon:SetSource(oldSource)
end)
test("tracking dependencies disable without losing saved preferences",function()
    local old=addon.db.tracking.enabled
    addon:SetFeature("tracking",false)
    for _,feature in ipairs({"banks","alts","autoscan"}) do equal(addon.UI.settingsChecks[feature].enabled,false) end
    addon:SetFeature("tracking",true)
    for _,feature in ipairs({"banks","alts","autoscan"}) do equal(addon.UI.settingsChecks[feature].enabled,true) end
    addon:SetFeature("tracking",old)
end)
test("automatic scan controls reflect price-source dependencies without changing preferences",function()
    local oldSource,oldWrit=addon.db.source,addon.db.writSource
    local oldScan=addon.db.scanOnOpen
    addon:SetSource("auctionator");addon:SetWritSource("off")
    equal(addon.UI.settingsChecks.scanopen.enabled,false)
    equal(addon.UI.settingsChecks.autoscan.enabled,false)
    equal(addon.UI.settingsTSM.enabled,false)
    equal(addon.db.scanOnOpen,oldScan)
    addon:SetSource("own");equal(addon.UI.settingsChecks.scanopen.enabled,true)
    addon:SetWritSource("tsm");equal(addon.UI.settingsTSM.enabled,true)
    addon:SetSource(oldSource);addon:SetWritSource(oldWrit)
end)
