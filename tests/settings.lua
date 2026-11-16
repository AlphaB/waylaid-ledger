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
test("the registered settings page edits persisted crate, writ, TSM and scan preferences",function()
    local oldSource,oldWrit,oldTSM,oldScan=addon.db.source,addon.db.writSource,addon.db.tsmKey,addon.db.scanOnOpen
    addon.UI.crateSourceButton.scripts.OnClick()
    assert(addon.db.source~=oldSource)
    equal(addon.UI.crateSourceButton.text,"Crate prices: "..({auto="Auto",auctionator="Auctionator",tsm="TSM",own="Own scans"})[addon.db.source])
    addon.UI.writSourceButton.scripts.OnClick();assert(addon.db.writSource~=oldWrit)
    addon.UI.settingsTSM.scripts.OnClick();assert(addon.db.tsmKey~=oldTSM)
    local check=addon.UI.settingsChecks.scanopen
    check:SetChecked(not oldScan);check.scripts.OnClick(check)
    equal(addon.db.scanOnOpen,not oldScan)
    equal(WaylaidLedgerDB.scanOnOpen,not oldScan)
    addon:SetFeature("scanopen",oldScan);addon:SetSource(oldSource);addon:SetWritSource(oldWrit);addon:SetTSMKey(oldTSM)
end)
test("source changes through slash commands also refresh official settings labels",function()
    local oldSource=addon.db.source
    addon:Command("source own");equal(addon.UI.crateSourceButton.text,"Crate prices: Own scans")
    addon:SetSource(oldSource)
end)
