local _, addon = ...
local L = addon.L
addon.UI = {}
local UI = addon.UI

local function button(parent, text, x, y, width, action)
    local control = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    control:SetSize(width, 25)
    control:SetPoint("TOPLEFT", x, y)
    addon.Localization.ButtonText(control, text)
    control:SetScript("OnClick", action)
    return control
end

local SOURCE_ORDER = { "auto", "auctionator", "tsm", "own" }
local SOURCE_LABELS = { auto = "Auto", auctionator = "Auctionator", tsm = "TSM", own = "Own scans" }

function UI.Create()
    local frame = CreateFrame("Frame", "WaylaidLedgerFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(570, 510)
    frame:SetPoint("CENTER")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame.TitleText:SetText("Waylaid Ledger")
    tinsert(UISpecialFrames, "WaylaidLedgerFrame")
    UI.frame = frame
    UI.panel = CreateFrame("Frame", nil, frame)
    UI.panel:SetPoint("TOPLEFT", 5, -25)
    UI.panel:SetSize(550, 475)
    local panel = UI.panel

    local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    intro:SetPoint("TOPLEFT", 15, -14)
    intro:SetWidth(510)
    intro:SetJustifyH("LEFT")
    intro:SetText(
        L["Crate prices and shopping. Green: lowest known filling cost. Click an option to choose a different bundle."]
    )

    UI.source = button(panel, "", 15, -80, 245, function()
        for index, source in ipairs(SOURCE_ORDER) do
            if source == addon.db.source then
                addon:SetSource(SOURCE_ORDER[index % #SOURCE_ORDER + 1])
                return
            end
        end
    end)
    UI.tsmKey = button(panel, "", 275, -80, 245, function()
        addon:SetTSMKey(addon.db.tsmKey == "DBMinBuyout" and "DBMarket" or "DBMinBuyout")
    end)
    UI.bags = button(panel, L["Scan bags"], 15, -114, 160, function()
        addon:StartScan("bags")
    end)
    UI.hovered = button(panel, L["Scan hovered"], 187, -114, 160, function()
        addon:StartScan("hovered")
    end)
    UI.all = button(panel, L["Full AH scan"], 359, -114, 160, function()
        addon:StartScan("all")
    end)
    UI.stop = button(panel, L["Stop scan"], 15, -147, 160, function()
        addon:StopScan()
    end)
    button(panel, L["Copy diagnostics"], 187, -147, 160, function()
        UI.ShowReport(addon:Report())
    end)

    button(panel, L["Settings"], 359, -147, 160, function()
        UI.ToggleSettings()
    end)

    UI.crate = button(panel, L["Hover a crate"], 15, -180, 505, function()
        local ids = addon.Inventory.CrateIDs()
        if #ids == 0 then
            return
        end
        local selected = 0
        for index, id in ipairs(ids) do
            if id == addon.lastCrateID then
                selected = index
            end
        end
        addon.lastCrateID = ids[selected % #ids + 1]
        UI.Update()
    end)
    UI.crate:SetScript("OnEnter", function(self)
        if addon.lastCrateID and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(addon.lastCrateID)
            GameTooltip:Show()
        end
    end)
    UI.crate:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    UI.option = button(panel, L["Hover a crate to choose a bundle"], 15, -212, 505, function()
        local crate = addon.lastCrateID and addon.Crates[addon.lastCrateID]
        if crate and not crate.unresolved and #crate.options > 0 then
            UI.optionIndex = UI.optionIndex % #crate.options + 1
            UI.Update()
        end
    end)
    UI.search = button(panel, L["Search all alternatives"], 15, -247, 245, function()
        addon:Shop(true)
    end)
    UI.shop = button(panel, L["Shop selected option"], 275, -247, 245, function()
        addon:Shop(false)
    end)

    UI.status = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    UI.status:SetPoint("TOPLEFT", 15, -289)
    UI.status:SetWidth(510)
    UI.status:SetJustifyH("LEFT")
    UI.tracked = button(panel, L["Scan tracked crates"], 15, -349, 245, function()
        addon:StartScan("tracked")
    end)
    button(panel, L["Inventory snapshots"], 275, -349, 245, function()
        UI.ShowReport(addon.Inventory.Report())
    end)
    UI.inventory = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    UI.inventory:SetPoint("TOPLEFT", 15, -387)
    UI.inventory:SetWidth(510)
    UI.inventory:SetJustifyH("LEFT")
    local footer = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetPoint("TOPLEFT", 15, -431)
    footer:SetWidth(510)
    footer:SetJustifyH("LEFT")
    footer:SetText(
        L["Auto refresh scans only missing/stale tracked requirements while this panel is open. Stop pauses it for this auction visit."]
    )
    panel:SetScript("OnShow", function()
        if addon.initialized then
            UI.Update()
            addon:RequestAutoScan()
        end
    end)
    frame:SetScript("OnHide", function()
        if UI.switchingBrowser then
            return
        end
        if addon.initialized and not UI.IsScanPanelVisible() then
            if addon.autoReason ~= "open" then
                addon.autoDue, addon.autoReason = nil, nil
            end
            if addon.scanAutomatic and not addon.scanOnOpen and addon.scanner.active then
                addon:StopScan(L["Automatic refresh paused after closing the panel."])
            end
            addon:UpdateScheduler()
        end
    end)
    frame:Hide()
    addon.Navigation.RegisterWindow(frame)
end

function UI.Update(refreshBrowse)
    if not UI.frame then
        return
    end
    if refreshBrowse ~= false and addon.BrowseUI then
        addon.BrowseUI.UpdateVisible()
    end
    local scanner = addon.scanner
    addon.Localization.ButtonText(UI.source, string.format(L["Prices: %s (change)"], L[SOURCE_LABELS[addon.db.source]]))
    addon.Localization.ButtonText(
        UI.tsmKey,
        addon.db.tsmKey == "DBMarket" and L["TSM: Market value (change)"] or L["TSM: Min buyout (change)"]
    )
    UI.tsmKey:SetEnabled(addon.Providers.Available("tsm"))
    if scanner.active and scanner.bulkMode then
        UI.status:SetText(scanner.message or L["Reading the auction-house snapshot..."])
    elseif scanner.active then
        local itemID = scanner.pending and scanner.pending.itemID or scanner.queue[scanner.index]
        UI.status:SetText(
            string.format(
                L["Scanning %d/%d: %s\n%d updated, %d failed. Hover again for updated prices."],
                scanner.index,
                #scanner.queue,
                addon.Catalog.ItemName(itemID),
                scanner.completed,
                scanner.failed
            )
        )
    else
        UI.status:SetText(
            (
                scanner.message
                or (scanner.open and L["Auction house open. Ready to scan."] or L["Open an auction house to scan."])
            )
                .. string.format(
                    L["\nProfile: %s; Auctionator: %s; TSM: %s"],
                    addon.db.profile,
                    addon.Providers.Available("auctionator") and L["ready"] or L["unavailable"],
                    addon.Providers.Available("tsm") and L["ready"] or L["unavailable"]
                )
        )
    end
    if not addon.lastCrateID then
        addon.lastCrateID = addon.Inventory.CrateIDs()[1]
    end
    local crateID = addon.lastCrateID
    local crate = crateID and addon.Crates[crateID]
    if crate and not crate.unresolved and #crate.options > 0 then
        local rows = addon:GetRows(crateID)
        if UI.selectedCrateID ~= crateID then
            UI.selectedCrateID, UI.optionIndex = crateID, 1
            local _, bestIndex = addon.Pricing.LowestKnown(rows)
            UI.optionIndex = bestIndex or 1
        end
        local selected = crate.options[UI.optionIndex]
        local quote = rows[UI.optionIndex]
        addon.Localization.ButtonText(
            UI.crate,
            string.format(L["%s (cycle tracked crates)"], addon.Catalog.ItemName(crateID))
        )
        local price = quote.cost and (" - " .. addon.Money(quote.cost)) or ""
        if quote.stale or quote.error then
            price = price .. (quote.error and L[" (scan failed)"] or L[" (stale)"])
        end
        addon.Localization.ButtonText(
            UI.option,
            string.format(
                L["Option %d/%d: %dx %s%s"],
                UI.optionIndex,
                #crate.options,
                selected.quantity,
                addon.Catalog.ItemName(selected.itemID),
                price
            )
        )
    else
        addon.Localization.ButtonText(UI.crate, L["Hover an identified crate to choose a bundle."])
    end
    local canShop = scanner.open
        and crate ~= nil
        and (addon.Providers.ShoppingAvailable() or addon.NativeShopping.Available())
    UI.search:SetEnabled(canShop)
    UI.shop:SetEnabled(canShop)
    UI.option:SetEnabled(crate ~= nil and not crate.unresolved and #crate.options > 0)
    UI.bags:SetEnabled(scanner.open and not scanner.active)
    UI.hovered:SetEnabled(scanner.open and not scanner.active and (addon.lastContractID ~= nil or crate ~= nil))
    UI.all:SetEnabled(scanner.open and not scanner.active)
    UI.stop:SetEnabled(scanner.active)
    UI.tracked:SetEnabled(scanner.open and not scanner.active)
    local totals = addon.Inventory.Totals()
    local crateCount = 0
    for _, count in pairs(totals.crates) do
        crateCount = crateCount + count
    end
    UI.inventory:SetText(
        string.format(
            L["Remembered: %d crates, %d characters, %d visited banks.\nBags update on login; bank contents update when visited."],
            crateCount,
            totals.characters,
            totals.banks
        )
    )
    UI.UpdateSettings()
end

local TAB_ID = "WaylaidLedger"

function UI.IsPanelVisible()
    return (UI.frame and UI.frame:IsShown())
        or (AuctionHouseFrame and AuctionHouseFrame:IsShown() and UI.auctionHost and UI.auctionHost:IsShown())
        or false
end

function UI.IsScanPanelVisible()
    return (UI.frame and UI.frame:IsShown())
        or (AuctionHouseFrame and AuctionHouseFrame:IsShown() and UI.auctionHost and UI.auctionHost:IsShown() and UI.auctionHosts.crates:IsShown())
        or false
end

function UI.VisibleBrowserTab()
    if
        not AuctionHouseFrame
        or not AuctionHouseFrame:IsVisible()
        or not UI.auctionHost
        or not UI.auctionHost:IsVisible()
    then
        return nil
    end
    for kind, page in pairs(UI.auctionHosts) do
        if page:IsVisible() then
            return kind
        end
    end
end

local function pausePanelScan()
    if UI.switchingBrowser then
        return
    end
    if addon.scanBrowser or addon.autoReason == "browse" then
        if not UI.VisibleBrowserTab() then
            addon.autoDue, addon.autoReason = nil, nil
            if addon.scanBrowser and addon.scanner.active then
                addon:StopScan(L["Automatic refresh paused after leaving the list."])
            end
            addon:UpdateScheduler()
        end
        return
    end
    if UI.IsScanPanelVisible() then
        return
    end
    if addon.autoReason ~= "open" then
        addon.autoDue, addon.autoReason = nil, nil
    end
    if addon.scanAutomatic and not addon.scanOnOpen and addon.scanner.active then
        addon:StopScan(L["Automatic refresh paused after leaving the crates list."])
    end
    addon:UpdateScheduler()
end

function UI.SelectBrowserTab(kind)
    if not UI.auctionHosts or not UI.auctionHosts[kind] then
        return
    end
    if
        addon.scanAutomatic
        and not addon.scanOnOpen
        and addon.scanner.active
        and ((addon.scanBrowser and addon.db.browserTab ~= kind) or (not addon.scanBrowser and kind == "writs"))
    then
        addon:StopScan(L["Automatic refresh paused after changing category."])
        addon.autoPaused = false
    end
    addon.db.browserTab = kind
    UI.switchingBrowser = true
    for category, page in pairs(UI.auctionHosts) do
        page:SetShown(category == kind)
        if category == kind then
            PanelTemplates_SelectTab(UI.browserTabs[category])
        else
            PanelTemplates_DeselectTab(UI.browserTabs[category])
        end
    end
    UI.frame:Hide()
    UI.switchingBrowser = false
    addon.BrowseUI.Refresh(addon.BrowseUI.views[kind])
    if kind == "crates" then
        addon:RequestAutoScan()
    else
        pausePanelScan()
    end
    addon:RequestBrowseScan()
    addon.Navigation.RefreshView(addon.BrowseUI.views[kind])
end

function UI.AttachAuction()
    if UI.auctionHost or not AuctionHouseFrame or not LibStub then
        return
    end
    local lib = LibStub:GetLibrary("LibAHTab-1-0", true)
    if not lib then
        return
    end
    local host = CreateFrame("Frame", nil, AuctionHouseFrame)
    host:SetPoint("TOPLEFT", AuctionHouseFrame, "TOPLEFT", 10, -35)
    host:SetPoint("BOTTOMRIGHT", AuctionHouseFrame, "BOTTOMRIGHT", -10, 34)
    UI.auctionHost, UI.auctionHosts, UI.browserTabs, UI.tabLibrary = host, {}, {}, lib
    local previous
    for _, kind in ipairs({ "writs", "crates" }) do
        local category = kind
        local tab = CreateFrame("Button", nil, host, "PanelTopTabButtonTemplate")
        tab:SetText(category == "writs" and L["Craftsman's Writs"] or L["Waylaid Crates"])
        PanelTemplates_TabResize(tab, 18)
        if previous then
            tab:SetPoint("TOPLEFT", previous, "TOPRIGHT", 3, 0)
        else
            tab:SetPoint("TOPLEFT", 10, 0)
        end
        tab:SetScript("OnClick", function()
            UI.SelectBrowserTab(category)
        end)
        UI.browserTabs[category], previous = tab, tab
        local page = CreateFrame("Frame", nil, host)
        page:SetPoint("TOPLEFT", 0, -32)
        page:SetPoint("BOTTOMRIGHT")
        page:Hide()
        UI.auctionHosts[category] = page
        addon.BrowseUI.Create(page, category)
        if category == "crates" then
            page:SetScript("OnHide", pausePanelScan)
        end
    end
    host:SetScript("OnShow", function()
        UI.SelectBrowserTab(UI.auctionHosts[addon.db.browserTab] and addon.db.browserTab or "crates")
    end)
    host:SetScript("OnHide", function()
        pausePanelScan()
        addon.Navigation.LeaveAuction()
    end)
    lib:CreateTab(TAB_ID, host, L["Waylaid"], "Waylaid Ledger")
    hooksecurefunc(AuctionHouseFrame, "SetDisplayMode", function()
        -- LibAHTab hides our host during mode changes. Rebuild only after all
        -- native children have reached their final visibility.
        if not host:IsVisible() then
            addon.Navigation.LeaveAuction()
        end
        addon.Navigation.CleanupAuction()
        addon.NativeShopping.CancelIfHidden()
    end)
end

function UI.AuctionClosed()
    if UI.auctionHost then
        UI.auctionHost:Hide()
    end
    UI.frame:Hide()
end

function UI.OpenControls()
    UI.Update()
    UI.frame:Show()
    addon:RequestAutoScan()
end

function UI.Toggle()
    UI.Update()
    if addon.scanner.open and AuctionHouseFrame then
        UI.AttachAuction()
        if UI.auctionHost then
            if UI.auctionHost:IsShown() then
                AuctionHouseFrame:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
            else
                UI.tabLibrary:SetSelected(TAB_ID)
            end
            return
        end
    end
    UI.frame:SetShown(not UI.frame:IsShown())
    if UI.frame:IsShown() then
        addon:RequestAutoScan()
    end
end

function UI.UpdateSettings()
    if not UI.settingsChecks then
        return
    end
    addon.Localization.ButtonText(
        UI.refreshModeButton,
        addon.db.refreshAuctionator and L["Refresh: Own + Auctionator"] or L["Refresh: Own scan"]
    )
    addon.Localization.ButtonText(
        UI.writSourceButton,
        string.format(L["Writ prices: %s"], L[SOURCE_LABELS[addon.db.writSource] or L["Off"]])
    )
    addon.Localization.ButtonText(
        UI.crateSourceButton,
        string.format(L["Crate prices: %s"], L[SOURCE_LABELS[addon.db.source]])
    )
    addon.Localization.ButtonText(UI.settingsTSM, string.format(L["TSM price: %s"], addon.db.tsmKey))
    for feature, control in pairs(UI.settingsChecks) do
        local enabled
        if feature == "minimap" then
            enabled = not addon.db.minimap.hide
        elseif feature == "scanopen" then
            enabled = addon.db.scanOnOpen
        elseif feature == "details" then
            enabled = addon.db.tooltipDetails
        else
            enabled =
                addon.db.tracking[({ tracking = "enabled", banks = "bank", alts = "alts", autoscan = "autoScan" })[feature]]
        end
        control:SetChecked(enabled and true or false)
    end
end

function UI.RegisterSettings()
    if UI.settingsCategory then
        return true
    end
    if not Settings or not Settings.RegisterCanvasLayoutCategory or not Settings.RegisterAddOnCategory then
        return false
    end
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(620, 500)
    frame:Hide()
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -16)
    title:SetText("Waylaid Ledger")
    UI.settings, UI.settingsChecks = frame, {}
    for index, option in ipairs({
        { "minimap", L["Show minimap button"] },
        { "tracking", L["Remember crate and material inventory"] },
        { "banks", L["Include visited character and shared banks"] },
        { "alts", L["Include remembered characters on this realm/faction"] },
        { "autoscan", L["Auto refresh tracked prices in the Crates list"] },
        { "scanopen", L["Auto-scan crate prices on auction open (Auto/Own)"] },
        { "details", L["Always show detailed price tooltips"] },
    }) do
        local feature = option[1]
        local control = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        control:SetPoint("TOPLEFT", 15, -48 - (index - 1) * 30)
        local label = control:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", control, "RIGHT", 3, 0)
        label:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
        label:SetJustifyH("LEFT")
        label:SetWordWrap(true)
        label:SetText(option[2])
        control:SetScript("OnClick", function(self)
            addon:SetFeature(feature, self:GetChecked() and true or false)
        end)
        UI.settingsChecks[feature] = control
    end
    UI.crateSourceButton = button(frame, L["Crate prices"], 18, -272, 220, function()
        for index, source in ipairs(SOURCE_ORDER) do
            if source == addon.db.source then
                addon:SetSource(SOURCE_ORDER[index % #SOURCE_ORDER + 1])
                break
            end
        end
        UI.UpdateSettings()
    end)
    UI.writSourceButton = button(frame, L["Writ prices"], 250, -272, 220, function()
        local sources = { auto = "auctionator", auctionator = "tsm", tsm = "own", own = "off", off = "auto" }
        addon:SetWritSource(sources[addon.db.writSource])
    end)
    UI.settingsTSM = button(frame, L["TSM price"], 18, -306, 220, function()
        addon:SetTSMKey(addon.db.tsmKey == "DBMarket" and "DBMinBuyout" or "DBMarket")
        UI.UpdateSettings()
    end)
    button(frame, L["Scan controls"], 250, -306, 220, function()
        HideUIPanel(SettingsPanel)
        UI.OpenControls()
    end)
    button(frame, L["Copy diagnostics"], 18, -340, 220, function()
        UI.ShowReport(addon:Report())
    end)
    button(frame, L["Clear remembered inventory"], 250, -340, 220, function()
        addon.db.inventory = { characters = {}, sharedBanks = {} }
        addon.Inventory.CaptureBags()
        addon.Inventory.CaptureBank()
        UI.Update()
    end)
    UI.refreshModeButton = button(frame, L["Refresh mode"], 18, -374, 220, function()
        addon:SetFeature("auctionatorfollowup", not addon.db.refreshAuctionator)
    end)
    button(frame, L["TSM group export"], 250, -374, 220, function()
        addon:ExportTSM()
    end)
    local note = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", 18, -420)
    note:SetPoint("TOPRIGHT", -18, -420)
    note:SetJustifyH("LEFT")
    note:SetText(
        L["Offline inventory is a last-seen snapshot. Log into each character and visit their bank once to update it."]
    )
    frame:SetScript("OnShow", UI.UpdateSettings)
    UI.settingsCategory = Settings.RegisterCanvasLayoutCategory(frame, "Waylaid Ledger")
    Settings.RegisterAddOnCategory(UI.settingsCategory)
    UI.UpdateSettings()
    return true
end

function UI.ToggleSettings()
    if UI.RegisterSettings() then
        Settings.OpenToCategory(UI.settingsCategory:GetID())
    else
        addon:Print(L["WoW's AddOns settings are unavailable on this client."])
    end
end

function UI.ShowReport(text, title)
    if not UI.report then
        local frame = CreateFrame("Frame", "WaylaidLedgerReportFrame", UIParent, "BasicFrameTemplateWithInset")
        frame:SetSize(640, 440)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("FULLSCREEN_DIALOG")
        frame.TitleText:SetText(L["Waylaid Ledger - select and copy with Ctrl+C / Cmd+C"])
        frame:SetClampedToScreen(true)
        tinsert(UISpecialFrames, "WaylaidLedgerReportFrame")
        local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 15, -38)
        scroll:SetPoint("BOTTOMRIGHT", -35, 15)
        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(580)
        edit:SetAutoFocus(false)
        edit:SetScript("OnEscapePressed", function()
            frame:Hide()
        end)
        scroll:SetScrollChild(edit)
        UI.report, UI.reportEdit = frame, edit
        frame:Hide()
        addon.Navigation.RegisterWindow(frame)
    end
    UI.report.TitleText:SetText(title or L["Waylaid Ledger - select and copy with Ctrl+C / Cmd+C"])
    UI.reportEdit:SetText(text)
    UI.report:Show()
    UI.reportEdit:SetFocus()
    UI.reportEdit:HighlightText()
end
