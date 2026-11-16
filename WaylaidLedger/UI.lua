local _, addon = ...
addon.UI = {}
local UI = addon.UI

local function button(parent, text, x, y, width, action)
    local control = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    control:SetSize(width, 25)
    control:SetPoint("TOPLEFT", x, y)
    control:SetText(text)
    control:SetScript("OnClick", action)
    return control
end

local SOURCE_ORDER = { "auto", "own", "auctionator", "tsm" }
local SOURCE_LABELS = { auto = "Auto", own = "Own scans", auctionator = "Auctionator", tsm = "TSM", off = "Off" }

function UI.Update(refreshBrowse)
    if refreshBrowse ~= false and addon.BrowseUI then addon.BrowseUI.UpdateVisible() end
    UI.UpdateSettings()
end

local TAB_ID = "WaylaidLedger"

function UI.IsScanPanelVisible()
    return (AuctionHouseFrame and AuctionHouseFrame:IsShown()
        and UI.auctionHost and UI.auctionHost:IsShown() and UI.auctionHosts.crates:IsShown()) or false
end

local function pausePanelScan()
    if UI.IsScanPanelVisible() then return end
    if addon.autoReason ~= "open" then addon.autoDue, addon.autoReason = nil, nil end
    if addon.scanAutomatic and not addon.scanOnOpen and addon.scanner.active then
        addon:StopScan("Automatic refresh paused after leaving the crates list.")
    end
    addon:UpdateScheduler()
end

function UI.SelectBrowserTab(kind)
    if not UI.auctionHosts or not UI.auctionHosts[kind] then return end
    addon.db.browserTab = kind
    for category, page in pairs(UI.auctionHosts) do
        page:SetShown(category == kind)
        if category == kind then PanelTemplates_SelectTab(UI.browserTabs[category])
        else PanelTemplates_DeselectTab(UI.browserTabs[category]) end
    end
    addon.BrowseUI.Refresh(addon.BrowseUI.views[kind])
    if kind == "crates" then addon:RequestAutoScan() else pausePanelScan() end
end

function UI.AttachAuction()
    if UI.auctionHost or not AuctionHouseFrame or not LibStub then return end
    local lib = LibStub:GetLibrary("LibAHTab-1-0", true)
    if not lib then return end
    local host = CreateFrame("Frame", nil, AuctionHouseFrame)
    host:SetPoint("TOPLEFT", AuctionHouseFrame, "TOPLEFT", 10, -35)
    host:SetPoint("BOTTOMRIGHT", AuctionHouseFrame, "BOTTOMRIGHT", -10, 34)
    UI.auctionHost, UI.auctionHosts, UI.browserTabs, UI.tabLibrary = host, {}, {}, lib
    local previous
    for _, kind in ipairs({ "writs", "crates" }) do
        local category = kind
        local tab = CreateFrame("Button", nil, host, "PanelTopTabButtonTemplate")
        tab:SetText(category == "writs" and "Craftsman's Writs" or "Waylaid Crates")
        PanelTemplates_TabResize(tab, 18)
        if previous then tab:SetPoint("TOPLEFT", previous, "TOPRIGHT", 3, 0)
        else tab:SetPoint("TOPLEFT", 10, 0) end
        tab:SetScript("OnClick", function() UI.SelectBrowserTab(category) end)
        UI.browserTabs[category], previous = tab, tab
        local page = CreateFrame("Frame", nil, host)
        page:SetPoint("TOPLEFT", 0, -32)
        page:SetPoint("BOTTOMRIGHT")
        page:Hide()
        UI.auctionHosts[category] = page
        addon.BrowseUI.Create(page, category)
        if category == "crates" then page:SetScript("OnHide", pausePanelScan) end
    end
    host:SetScript("OnShow", function()
        UI.SelectBrowserTab(UI.auctionHosts[addon.db.browserTab] and addon.db.browserTab or "crates")
    end)
    host:SetScript("OnHide", pausePanelScan)
    lib:CreateTab(TAB_ID, host, "Waylaid", "Waylaid Ledger")
end

function UI.AuctionClosed()
    if UI.auctionHost then UI.auctionHost:Hide() end
end

function UI.Toggle()
    UI.Update()
    if addon.scanner.open and AuctionHouseFrame then
        UI.AttachAuction()
        if UI.auctionHost then
            if UI.auctionHost:IsShown() then
                AuctionHouseFrame:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
            else UI.tabLibrary:SetSelected(TAB_ID) end
            return
        end
    end
    UI.ToggleSettings()
end

local function label(parent, value, x, y, width, font)
    local text = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", x, y)
    text:SetWidth(width)
    text:SetJustifyH("LEFT")
    text:SetText(value)
    return text
end

local function hint(control, title, description)
    control:HookScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(title, 1, 0.82, 0)
        GameTooltip:AddLine(description, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    control:HookScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end

local function choice(parent, title, y, values, labels, get, set, description)
    label(parent, title, 18, y - 6, 115)
    local control = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    control:SetSize(155, 25)
    control:SetPoint("TOPLEFT", 135, y)
    control:SetupMenu(function(_, root)
        for _, value in ipairs(values) do
            root:CreateRadio(labels[value], function() return get() == value end, function() set(value) end)
        end
    end)
    hint(control, title, description)
    return control
end

function UI.UpdateSettings()
    if not UI.settingsChecks then return end
    UI.crateSourceButton:GenerateMenu()
    UI.writSourceButton:GenerateMenu()
    UI.settingsTSM:GenerateMenu()
    UI.settingsTSM:SetEnabled(addon.db.source == "auto" or addon.db.source == "tsm"
        or addon.db.writSource == "auto" or addon.db.writSource == "tsm")
    for feature, control in pairs(UI.settingsChecks) do
        local enabled
        if feature == "minimap" then enabled = not addon.db.minimap.hide
        elseif feature == "scanopen" then enabled = addon.db.scanOnOpen
        elseif feature == "details" then enabled = addon.db.tooltipDetails
        else enabled = addon.db.tracking[({tracking="enabled",banks="bank",alts="alts",autoscan="autoScan"})[feature]] end
        control:SetChecked(enabled and true or false)
        local available = (feature ~= "banks" and feature ~= "alts" and feature ~= "autoscan") or addon.db.tracking.enabled
        if feature == "autoscan" or feature == "scanopen" then
            available = available and (addon.db.source == "auto" or addon.db.source == "own")
        end
        control:SetEnabled(available)
        local tint = available and 1 or 0.5
        control.label:SetTextColor(tint, tint, tint)
    end
end

function UI.RegisterSettings()
    if UI.settingsCategory then return true end
    if not Settings or not Settings.RegisterCanvasLayoutCategory or not Settings.RegisterAddOnCategory then return false end
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(620, 500)
    frame:Hide()
    label(frame, "Waylaid Ledger", 18, -16, 570, "GameFontNormalLarge")
    UI.settings, UI.settingsChecks = frame, {}
    label(frame, "Prices", 18, -54, 270, "GameFontNormal")
    UI.crateSourceButton = choice(frame, "Crate prices", -78, SOURCE_ORDER, SOURCE_LABELS,
        function() return addon.db.source end, function(value) addon:SetSource(value) end,
        "Auto uses own scans, then Auctionator and TSM estimates. A specific source uses only that source.")
    UI.writSourceButton = choice(frame, "Writ prices", -112, {"auto", "own", "auctionator", "tsm", "off"}, SOURCE_LABELS,
        function() return addon.db.writSource end, function(value) addon:SetWritSource(value) end,
        "Choose prices for writ purchases and deliveries. Off hides writ prices.")
    UI.settingsTSM = choice(frame, "TSM price", -146, {"DBMinBuyout", "DBMarket"},
        {DBMinBuyout="Minimum buyout", DBMarket="Market value"},
        function() return addon.db.tsmKey end, function(value) addon:SetTSMKey(value) end,
        "Used by both lists when TSM supplies prices. Market value is a historical estimate.")
    label(frame, "Display", 18, -202, 270, "GameFontNormal")
    label(frame, "Automatic scans", 18, -306, 270, "GameFontNormal")
    label(frame, "Inventory", 320, -54, 270, "GameFontNormal")
    for _, option in ipairs({
        {"minimap", "Show minimap button", 18, -226, "Left-click opens the auction list at the AH, or settings elsewhere. Right-click always opens settings."},
        {"details", "Always show tooltip details", 18, -260, "Show price sources and ages. With this off, hold Shift for details."},
        {"autoscan", "Refresh tracked crate prices", 18, -330, "Refresh missing or stale tracked crate materials while the Crates tab is visible at the AH. Requires inventory tracking and Auto or Own scans."},
        {"scanopen", "Scan on auction-house open", 18, -370, "Refresh missing or stale crate materials after opening the AH, even without the Crates tab visible. Uses Auto or Own scans."},
        {"tracking", "Remember inventory", 320, -78, "Remember crate, writ and delivery-item counts for bag and tracked scans. Prices do not subtract owned inventory."},
        {"banks", "Include visited banks", 320, -112, "Include last-seen character and shared-bank contents in tracked scans."},
        {"alts", "Include remembered characters", 320, -146, "Include last-seen inventory from other characters on this realm and faction."},
    }) do
        local feature = option[1]
        local control = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        control:SetPoint("TOPLEFT", option[3] - 3, option[4])
        control:SetMotionScriptsWhileDisabled(true)
        control.label = label(control, option[2], 32, -8, 232)
        control:SetScript("OnClick", function(self) addon:SetFeature(feature, self:GetChecked() and true or false) end)
        hint(control, option[2], option[5])
        UI.settingsChecks[feature] = control
    end
    label(frame, "Visit each character and bank to update its last-seen inventory.", 320, -190, 270, "GameFontDisableSmall")
    label(frame, "Tools", 320, -262, 270, "GameFontNormal")
    button(frame, "Inventory snapshots", 320, -290, 270, function() UI.ShowReport(addon.Inventory.Report()) end)
    button(frame, "Copy diagnostics", 320, -324, 270, function() UI.ShowReport(addon:Report()) end)
    button(frame, "Clear remembered inventory", 320, -358, 270, function()
        addon.db.inventory = { characters = {}, sharedBanks = {} }
        addon.Inventory.CaptureBags(); addon.Inventory.CaptureBank(); UI.Update()
    end)
    label(frame, "Refresh and Stop are in the auction list. Advanced tools: /wll help", 18, -438, 570, "GameFontDisableSmall")
    frame:SetScript("OnShow", UI.UpdateSettings)
    UI.settingsCategory = Settings.RegisterCanvasLayoutCategory(frame, "Waylaid Ledger")
    Settings.RegisterAddOnCategory(UI.settingsCategory)
    UI.UpdateSettings()
    return true
end

function UI.ToggleSettings()
    if UI.RegisterSettings() then Settings.OpenToCategory(UI.settingsCategory:GetID())
    else addon:Print("WoW's AddOns settings are unavailable on this client.") end
end

function UI.ShowReport(text, title)
    if not UI.report then
        local frame = CreateFrame("Frame", "WaylaidLedgerReportFrame", UIParent, "BasicFrameTemplateWithInset")
        frame:SetSize(640, 440)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("FULLSCREEN_DIALOG")
        frame.TitleText:SetText("Waylaid Ledger - select and copy with Ctrl+C / Cmd+C")
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
        edit:SetScript("OnEscapePressed", function() frame:Hide() end)
        scroll:SetScrollChild(edit)
        UI.report, UI.reportEdit = frame, edit
    end
    UI.report.TitleText:SetText(title or "Waylaid Ledger - select and copy with Ctrl+C / Cmd+C")
    UI.reportEdit:SetText(text)
    UI.report:Show()
    UI.reportEdit:SetFocus()
    UI.reportEdit:HighlightText()
end
