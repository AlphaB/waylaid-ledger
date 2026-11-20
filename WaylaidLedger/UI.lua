local _, addon = ...
local L = addon.L
addon.UI = {}
local UI = addon.UI

local function button(parent, text, x, y, width, action)
    local control = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    control:SetSize(width, 25)
    control:SetPoint("TOPLEFT", x, y)
    addon.Localization.ButtonText(control, L[text])
    control:SetScript("OnClick", action)
    return control
end

local SOURCE_ORDER = { "auto", "own", "auctionator", "tsm" }
local SOURCE_LABELS = { auto = "Auto", own = "Own scans", auctionator = "Auctionator", tsm = "TSM", off = "Off" }

function UI.Update(refreshBrowse)
    if addon.TripPlanner then
        addon.TripPlanner.UpdateShopping()
    end
    if addon.Providers and addon.Providers.scan then
        UI.UpdateSettings() -- Explicit settings changes still apply if the page is visible.
        return -- Completion refreshes once; progress has its own status-only path.
    end
    if addon.Trace then
        addon:Trace(
            "ui.update",
            5,
            "UI update requested; browse=%s tab=%s",
            tostring(refreshBrowse ~= false),
            tostring(addon.db and addon.db.browserTab)
        )
    end
    if refreshBrowse ~= false and addon.BrowseUI then
        addon.BrowseUI.UpdateVisible()
    end
    UI.UpdateSettings()
end

local TAB_ID = "WaylaidLedger"

function UI.IsScanPanelVisible()
    return (
        AuctionHouseFrame
        and AuctionHouseFrame:IsShown()
        and UI.auctionHost
        and UI.auctionHost:IsShown()
        and UI.auctionHosts.crates:IsShown()
    ) or false
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

function UI.SelectBrowserTab(kind, browser, saved)
    browser = browser or UI.auctionHost
    if not browser or not browser.pages[kind] then
        return
    end
    browser.activeTab = kind
    if kind ~= "trips" then
        addon.db.browserTab = kind
    end
    UI.switchingBrowser = true
    for category, page in pairs(browser.pages) do
        page:SetShown(category == kind)
        if category == kind then
            PanelTemplates_SelectTab(browser.tabs[category])
        else
            PanelTemplates_DeselectTab(browser.tabs[category])
        end
    end
    UI.switchingBrowser = false
    local view = browser.views[kind]
    if kind == "trips" then
        addon.TripPlanner.Activate(view, saved)
    else
        addon.BrowseUI.Refresh(view)
    end
    addon.Navigation.EnterView(view)
end

-- Both containers use exactly the same category controls and list implementation.
function UI.CreateBrowser(host, cached)
    host.pages, host.tabs, host.views = {}, {}, {}
    local previous
    local categories = addon.TripPlanner and { "writs", "crates", "trips" } or { "writs", "crates" }
    for _, kind in ipairs(categories) do
        local category = kind
        local tab = CreateFrame("Button", nil, host, "PanelTopTabButtonTemplate")
        tab:SetText(
            category == "trips" and L["Writ trips"]
                or category == "writs" and L["Craftsman's Writs"]
                or L["Waylaid Crates"]
        )
        PanelTemplates_TabResize(tab, 18)
        if previous then
            tab:SetPoint("TOPLEFT", previous, "TOPRIGHT", 3, 0)
        else
            tab:SetPoint("TOPLEFT", 10, 0)
        end
        tab:SetScript("OnClick", function()
            UI.SelectBrowserTab(category, host)
        end)
        host.tabs[category], previous = tab, tab
        local page = CreateFrame("Frame", nil, host)
        page:SetPoint("TOPLEFT", 0, -32)
        page:SetPoint("BOTTOMRIGHT")
        page:Hide()
        host.pages[category] = page
        if category == "trips" then
            host.views[category] = addon.TripPlanner.Create(page, cached and host or nil)
        else
            host.views[category] = addon.BrowseUI.Create(page, category, cached and host or nil)
        end
        host.views[category].tabs = host.tabs
        if not cached and category == "crates" then
            page:SetScript("OnHide", pausePanelScan)
        end
    end
end

function UI.OpenCachedBrowser()
    if not UI.cachedBrowser then
        local frame = CreateFrame("Frame", "WaylaidLedgerBrowserFrame", UIParent, "BasicFrameTemplateWithInset")
        frame:Hide()
        frame:SetSize(1000, 600)
        frame:SetPoint("CENTER")
        frame.TitleText:SetText(L["Waylaid Ledger - saved prices"])
        UI.cachedBrowser = frame
        UI.CreateBrowser(frame, true)
        -- Leave room for the native title bar and close button.
        frame.tabs.writs:ClearAllPoints()
        frame.tabs.writs:SetPoint("TOPLEFT", 20, -30)
        for _, page in pairs(frame.pages) do
            page:ClearAllPoints()
            page:SetPoint("TOPLEFT", 10, -62)
            page:SetPoint("BOTTOMRIGHT", -10, 12)
        end
        frame:SetScript("OnShow", function()
            UI.SelectBrowserTab(frame.activeTab == "trips" and "trips" or addon.db.browserTab or "crates", frame)
        end)
        addon.Navigation.RegisterStandaloneWindow(frame, {
            target = function()
                local view = frame.views[frame.activeTab or addon.db.browserTab or "crates"]
                return view.target and view.target() or view.search
            end,
            scroll = function()
                return frame.views[frame.activeTab or addon.db.browserTab or "crates"].scroll
            end,
        })
    end
    UI.cachedBrowser:Show()
    local browser = UI.cachedBrowser
    addon.Navigation.EnterView(browser.views[browser.activeTab or addon.db.browserTab])
end

function UI.OpenSavedTrip()
    if addon.scanner.open and AuctionHouseFrame then
        UI.AttachAuction()
        if UI.auctionHost then
            UI.tabLibrary:SetSelected(TAB_ID)
            UI.SelectBrowserTab("trips", UI.auctionHost, true)
            return
        end
    end
    UI.OpenCachedBrowser()
    UI.SelectBrowserTab("trips", UI.cachedBrowser, true)
end

function UI.AttachAuction()
    if addon.scanner.open and UI.cachedBrowser then
        UI.cachedBrowser:Hide()
    end
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
    UI.CreateBrowser(host)
    UI.auctionHosts, UI.browserTabs = host.pages, host.tabs
    host:SetScript("OnShow", function()
        UI.SelectBrowserTab(host.activeTab == "trips" and "trips" or addon.db.browserTab or "crates", host)
    end)
    host:SetScript("OnHide", function()
        pausePanelScan()
        addon.Navigation.LeaveAuction()
    end)
    lib:CreateTab(TAB_ID, host, L["Waylaid"], "Waylaid Ledger")
    UI.auctionTab = lib:GetButton(TAB_ID)
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
    if UI.cachedBrowser and UI.cachedBrowser:IsShown() then
        UI.cachedBrowser:Hide()
    else
        UI.OpenCachedBrowser()
    end
end

local function label(parent, value, x, y, width, font)
    local text = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", x, y)
    text:SetWidth(width)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(true)
    text:SetText(L[value])
    return text
end

local function hint(control, title, description)
    control:HookScript("OnEnter", function(self)
        if not GameTooltip then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L[title], 1, 0.82, 0)
        GameTooltip:AddLine(L[description], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    control:HookScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
end

local function choice(parent, title, y, values, labels, get, set, description)
    label(parent, title, 18, y - 6, 115)
    local control = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    control:SetSize(155, 25)
    control:SetPoint("TOPLEFT", 135, y)
    control:SetupMenu(function(_, root)
        for _, value in ipairs(values) do
            root:CreateRadio(L[labels[value]], function()
                return get() == value
            end, function()
                set(value)
            end)
        end
    end)
    hint(control, title, description)
    return control
end

function UI.UpdateSettings()
    if not UI.settingsChecks or not UI.settings:IsVisible() then
        return
    end
    UI.crateSourceButton:GenerateMenu()
    UI.writSourceButton:GenerateMenu()
    UI.settingsTSM:GenerateMenu()
    UI.settingsTSM:SetEnabled(
        addon.db.source == "auto"
            or addon.db.source == "tsm"
            or addon.db.writSource == "auto"
            or addon.db.writSource == "tsm"
    )
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
        local available = (feature ~= "banks" and feature ~= "alts" and feature ~= "autoscan")
            or addon.db.tracking.enabled
        if feature == "autoscan" or feature == "scanopen" then
            available = available and (addon.db.source == "auto" or addon.db.source == "own")
        end
        control:SetEnabled(available)
        local tint = available and 1 or 0.5
        control.label:SetTextColor(tint, tint, tint)
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
    UI.settingsTitle = label(frame, "Waylaid Ledger", 18, -16, 570, "GameFontNormalLarge")
    UI.settingsTitle:SetText("Waylaid Ledger  v" .. addon.version)
    UI.settings, UI.settingsChecks = frame, {}
    label(frame, "Prices", 18, -54, 270, "GameFontNormal")
    UI.crateSourceButton = choice(frame, "Crate prices", -78, SOURCE_ORDER, SOURCE_LABELS, function()
        return addon.db.source
    end, function(value)
        addon:SetSource(value)
    end, "Auto uses own scans and optional providers. Forced sources use only that provider.")
    UI.writSourceButton = choice(
        frame,
        "Writ prices",
        -112,
        { "auto", "own", "auctionator", "tsm", "off" },
        SOURCE_LABELS,
        function()
            return addon.db.writSource
        end,
        function(value)
            addon:SetWritSource(value)
        end,
        "Choose a price source for writ purchases and deliveries."
    )
    UI.settingsTSM = choice(
        frame,
        "TSM price",
        -146,
        { "DBMinBuyout", "DBMarket" },
        { DBMinBuyout = "Minimum buyout", DBMarket = "Market value" },
        function()
            return addon.db.tsmKey
        end,
        function(value)
            addon:SetTSMKey(value)
        end,
        "Applies to both lists when TSM supplies prices."
    )
    label(frame, "Display", 18, -202, 270, "GameFontNormal")
    label(frame, "Automatic scans", 18, -306, 270, "GameFontNormal")
    label(
        frame,
        "Lists use saved prices. Refresh reloads prices; scanning requires the AH.",
        18,
        -378,
        270,
        "GameFontDisableSmall"
    )
    label(frame, "Inventory", 320, -54, 270, "GameFontNormal")
    for _, option in ipairs({
        {
            "minimap",
            "Show minimap button",
            18,
            -226,
            "Left-click opens the lists anywhere. Right-click opens settings.",
        },
        { "details", "Always show detailed price tooltips", 18, -260, "Hold Shift for details when disabled." },
        {
            "scanopen",
            "Scan on auction-house open",
            18,
            -330,
            "Scan on AH open with Own scans, or Auto without an available price provider. May start a full scan.",
        },
        {
            "tracking",
            "Remember inventory",
            320,
            -78,
            "Remember bags and visited banks across characters. Prices do not subtract owned items.",
        },
        { "banks", "Include visited banks", 320, -112, "Include visited character and shared banks" },
        { "alts", "Include remembered characters", 320, -146, "Include remembered characters on this realm/faction" },
    }) do
        local feature = option[1]
        local control = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        control:SetPoint("TOPLEFT", option[3] - 3, option[4])
        control:SetMotionScriptsWhileDisabled(true)
        control.label = label(control, option[2], 32, -8, 232)
        control:SetScript("OnClick", function(self)
            addon:SetFeature(feature, self:GetChecked() and true or false)
        end)
        hint(control, option[2], option[5])
        UI.settingsChecks[feature] = control
    end
    label(
        frame,
        "Offline inventory is last seen. Log into characters and revisit banks to refresh it.",
        320,
        -190,
        270,
        "GameFontDisableSmall"
    )
    label(frame, "Time value (gold/hour)", 320, -232, 145)
    local timeValue = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    timeValue:SetSize(66, 22)
    timeValue:SetPoint("TOPLEFT", 475, -225)
    timeValue:SetAutoFocus(false)
    timeValue:SetMaxLetters(12)
    UI.tripTimeValue = timeValue
    local function applyTimeValue()
        local value = addon.WritTrips.ParseGoldPerHour(timeValue:GetText())
        if value then
            addon.db.tripGoldPerHour = value
        else
            addon:Print(L["Enter a gold-per-hour value from 0 to 1,000,000."])
        end
        timeValue:SetText(tostring(addon.WritTrips.GoldPerHour()))
        timeValue:ClearFocus()
    end
    timeValue:SetScript("OnEnterPressed", applyTimeValue)
    timeValue:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(addon.WritTrips.GoldPerHour()))
        self:ClearFocus()
    end)
    UI.applyTripTimeValue = button(frame, "Apply", 550, -225, 56, applyTimeValue)
    label(frame, "Tools", 320, -262, 270, "GameFontNormal")
    button(frame, "Inventory snapshots", 320, -290, 270, function()
        UI.ShowReport(addon.Inventory.Report())
    end)
    button(frame, "Copy diagnostics", 320, -324, 270, function()
        UI.ShowReport(addon:Report())
    end)
    button(frame, "Clear remembered inventory", 320, -358, 270, function()
        addon.db.inventory = { characters = {}, sharedBanks = {} }
        addon.Inventory.CaptureBags()
        addon.Inventory.CaptureBank()
        UI.Update()
    end)
    label(
        frame,
        "Refresh is in each list; Stop appears during Waylaid scans. Advanced tools: /wll help",
        18,
        -438,
        570,
        "GameFontDisableSmall"
    )
    frame:SetScript("OnShow", function()
        timeValue:SetText(tostring(addon.WritTrips.GoldPerHour()))
        UI.UpdateSettings()
    end)
    -- Native SettingsPanel enters its standard list, not custom canvases.
    -- Own a separate native scope and close the parent panel on Back.
    frame.SmartNavigationCloseHandler = function()
        HideUIPanel(SettingsPanel)
        return true
    end
    addon.Navigation.RegisterWindow(frame, { target = UI.crateSourceButton, deferFocus = true })
    UI.settingsCategory = Settings.RegisterCanvasLayoutCategory(frame, "Waylaid Ledger")
    Settings.RegisterAddOnCategory(UI.settingsCategory)
    UI.UpdateSettings()
    return true
end

function UI.ToggleSettings()
    if UI.RegisterSettings() then
        Settings.OpenToCategory(UI.settingsCategory:GetID())
        addon.Navigation.Focus(UI.settings)
        addon.Navigation.RefreshWindow(UI.settings)
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
        addon.Navigation.RegisterStandaloneWindow(frame, { scroll = scroll, target = edit })
        frame:HookScript("OnHide", function()
            edit:ClearFocus()
        end)
        UI.reportScroll = scroll
    end
    UI.report.TitleText:SetText(title or L["Waylaid Ledger - select and copy with Ctrl+C / Cmd+C"])
    UI.reportEdit:SetText(text)
    UI.reportScroll:SetVerticalScroll(0)
    UI.report:Show()
    addon.Navigation.Focus(UI.report)
    addon.Navigation.RefreshWindow(UI.report)
    UI.reportEdit:SetFocus()
    UI.reportEdit:HighlightText()
end
