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
    intro:SetText("Crate prices and shopping. Green: scanned cost. Amber: estimate. Click an option to choose a different bundle.")

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
    UI.bags = button(panel, "Scan bags", 15, -114, 160, function() addon:StartScan("bags") end)
    UI.hovered = button(panel, "Scan hovered", 187, -114, 160, function() addon:StartScan("hovered") end)
    UI.all = button(panel, "Scan all (96)", 359, -114, 160, function() addon:StartScan("all") end)
    UI.stop = button(panel, "Stop scan", 15, -147, 160, function() addon:StopScan() end)
    button(panel, "Copy diagnostics", 187, -147, 160, function() UI.ShowReport(addon:Report()) end)

    button(panel, "Settings", 359, -147, 160, function() UI.ToggleSettings() end)

    UI.crate = button(panel, "Hover a crate", 15, -180, 505, function()
        local ids = addon.Inventory.CrateIDs()
        if #ids == 0 then return end
        local selected = 0
        for index, id in ipairs(ids) do if id == addon.lastCrateID then selected = index end end
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
    UI.crate:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    UI.option = button(panel, "Hover a crate to choose a bundle", 15, -212, 505, function()
        local crate = addon.lastCrateID and addon.Crates[addon.lastCrateID]
        if crate then
            UI.optionIndex = UI.optionIndex % #crate.options + 1
            UI.Update()
        end
    end)
    UI.search = button(panel, "Search all alternatives", 15, -247, 245, function() addon:Shop(true) end)
    UI.shop = button(panel, "Shop selected option", 275, -247, 245, function() addon:Shop(false) end)

    UI.status = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    UI.status:SetPoint("TOPLEFT", 15, -289)
    UI.status:SetWidth(510)
    UI.status:SetJustifyH("LEFT")
    UI.tracked = button(panel, "Scan tracked crates", 15, -349, 245, function() addon:StartScan("tracked") end)
    button(panel, "Inventory snapshots", 275, -349, 245, function() UI.ShowReport(addon.Inventory.Report()) end)
    UI.inventory = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    UI.inventory:SetPoint("TOPLEFT", 15, -387)
    UI.inventory:SetWidth(510)
    UI.inventory:SetJustifyH("LEFT")
    local footer = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetPoint("TOPLEFT", 15, -431)
    footer:SetWidth(510)
    footer:SetJustifyH("LEFT")
    footer:SetText("Auto refresh scans only missing/stale tracked requirements while this panel is open. Stop pauses it for this auction visit.")
    panel:SetScript("OnShow", function()
        if addon.initialized then UI.Update(); addon:RequestAutoScan() end
    end)
    frame:SetScript("OnHide", function()
        if addon.initialized and not UI.IsScanPanelVisible() then
            if addon.autoReason ~= "open" then addon.autoDue, addon.autoReason = nil, nil end
            if addon.scanAutomatic and not addon.scanOnOpen and addon.scanner.active then addon:StopScan("Automatic refresh paused after closing the panel.") end
            addon:UpdateScheduler()
        end
    end)
    frame:Hide()
end

function UI.Update()
    if not UI.frame then
        return
    end
    if addon.BrowseUI then addon.BrowseUI.UpdateVisible() end
    local scanner = addon.scanner
    UI.source:SetText("Prices: " .. SOURCE_LABELS[addon.db.source] .. " (change)")
    UI.tsmKey:SetText(addon.db.tsmKey == "DBMarket" and "TSM: Market value (change)" or "TSM: Min buyout (change)")
    UI.tsmKey:SetEnabled(addon.Providers.Available("tsm"))
    if scanner.active then
        local itemID = scanner.pending and scanner.pending.itemID or scanner.queue[scanner.index]
        UI.status:SetText(string.format("Scanning %d/%d: %s\n%d updated, %d failed. Hover again for updated prices.",
            scanner.index, #scanner.queue, addon.Catalog.ItemName(itemID), scanner.completed, scanner.failed))
    else
        UI.status:SetText((scanner.message or (scanner.open and "Auction house open. Ready to scan." or "Open an auction house to scan."))
            .. "\nProfile: " .. addon.db.profile .. "; Auctionator: "
            .. (addon.Providers.Available("auctionator") and "ready" or "unavailable") .. "; TSM: "
            .. (addon.Providers.Available("tsm") and "ready" or "unavailable"))
    end
    if not addon.lastCrateID then
        addon.lastCrateID = addon.Inventory.CrateIDs()[1]
    end
    local crateID = addon.lastCrateID
    local crate = crateID and addon.Crates[crateID]
    if crate then
        local rows = addon:GetRows(crateID)
        if UI.selectedCrateID ~= crateID then
            UI.selectedCrateID, UI.optionIndex = crateID, 1
            -- Prefer a verified winner, then the lowest usable estimate.
            local estimatedIndex
            for index, row in ipairs(rows) do
                if row.best then
                    UI.optionIndex = index
                    estimatedIndex = nil
                    break
                elseif row.bestEstimate and not estimatedIndex then
                    estimatedIndex = index
                end
            end
            UI.optionIndex = estimatedIndex or UI.optionIndex
        end
        local selected = crate.options[UI.optionIndex]
        local quote = rows[UI.optionIndex]
        UI.crate:SetText(addon.Catalog.ItemName(crateID) .. " (cycle tracked crates)")
        local price = quote.cost and (" - " .. (quote.estimated and "~ " or "") .. addon.Money(quote.cost)) or ""
        if quote.stale or quote.error then
            price = price .. (quote.error and " (scan failed)" or " (stale)")
        end
        UI.option:SetText(string.format("Option %d/%d: %dx %s%s", UI.optionIndex, #crate.options,
            selected.quantity, addon.Catalog.ItemName(selected.itemID), price))
    else
        UI.crate:SetText("Hover an identified crate to choose a bundle.")
    end
    local canShop = scanner.open and crate ~= nil and addon.Providers.ShoppingAvailable()
    UI.search:SetEnabled(canShop)
    UI.shop:SetEnabled(canShop)
    UI.option:SetEnabled(crate ~= nil)
    UI.bags:SetEnabled(scanner.open and not scanner.active)
    UI.hovered:SetEnabled(scanner.open and not scanner.active and crate ~= nil)
    UI.all:SetEnabled(scanner.open and not scanner.active)
    UI.stop:SetEnabled(scanner.active)
    UI.tracked:SetEnabled(scanner.open and not scanner.active)
    local totals = addon.Inventory.Totals()
    local crateCount = 0
    for _, count in pairs(totals.crates) do crateCount = crateCount + count end
    UI.inventory:SetText(string.format("Remembered: %d crates, %d characters, %d visited banks.\nBags update on login; bank contents update when visited.",
        crateCount, totals.characters, totals.banks))
end

local TAB_IDS = { crates = "WaylaidLedgerCrates", writs = "WaylaidLedgerWrits" }

function UI.IsPanelVisible()
    if UI.frame and UI.frame:IsShown() then return true end
    for _, host in pairs(UI.auctionHosts or {}) do
        if AuctionHouseFrame and AuctionHouseFrame:IsShown() and host:IsShown() then return true end
    end
    return false
end

function UI.IsScanPanelVisible()
    return (UI.frame and UI.frame:IsShown()) or (AuctionHouseFrame and AuctionHouseFrame:IsShown() and UI.auctionHost and UI.auctionHost:IsShown()) or false
end

function UI.AttachAuction()
    if UI.auctionHosts or not AuctionHouseFrame or not LibStub then return end
    local lib = LibStub:GetLibrary("LibAHTab-1-0", true)
    if not lib then return end
    UI.auctionHosts, UI.tabLibrary = {}, lib
    for _, kind in ipairs({ "writs", "crates" }) do
        local category = kind
        local host = CreateFrame("Frame", nil, AuctionHouseFrame)
        host:SetPoint("TOPLEFT", AuctionHouseFrame, "TOPLEFT", 10, -35)
        host:SetPoint("BOTTOMRIGHT", AuctionHouseFrame, "BOTTOMRIGHT", -10, 10)
        UI.auctionHosts[category] = host
        local view = addon.BrowseUI.Create(host, category)
        host:SetScript("OnShow", function()
            addon.db.browserTab = category
            UI.frame:Hide()
            addon.BrowseUI.Refresh(view)
            if category == "crates" then addon:RequestAutoScan() end
        end)
        host:SetScript("OnHide", function()
            if category == "crates" then
                if addon.autoReason ~= "open" then addon.autoDue, addon.autoReason = nil, nil end
                if addon.scanAutomatic and not addon.scanOnOpen and addon.scanner.active then
                    addon:StopScan("Automatic refresh paused after leaving the crates tab.")
                end
                addon:UpdateScheduler()
            end
        end)
        local title = category == "writs" and "Writs" or "Waylaid Crates"
        lib:CreateTab(TAB_IDS[category], host, title, "Waylaid Ledger - " .. title)
    end
    UI.auctionHost = UI.auctionHosts.crates
end

function UI.AuctionClosed()
    for _, host in pairs(UI.auctionHosts or {}) do host:Hide() end
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
        if UI.auctionHosts then
            if UI.auctionHosts.crates:IsShown() or UI.auctionHosts.writs:IsShown() then
                AuctionHouseFrame:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
            else
                local kind = TAB_IDS[addon.db.browserTab] and addon.db.browserTab or "crates"
                UI.tabLibrary:SetSelected(TAB_IDS[kind])
            end
            return
        end
    end
    UI.frame:SetShown(not UI.frame:IsShown())
    if UI.frame:IsShown() then addon:RequestAutoScan() end
end

function UI.UpdateSettings()
    if not UI.settingsChecks then return end
    if UI.writSourceButton then UI.writSourceButton:SetText("Writ prices: " .. addon.db.writSource) end
    for feature, control in pairs(UI.settingsChecks) do
        local enabled
        if feature == "minimap" then enabled = not addon.db.minimap.hide
        elseif feature == "scanopen" then enabled = addon.db.scanOnOpen
        elseif feature == "details" then enabled = addon.db.tooltipDetails
        else enabled = addon.db.tracking[({tracking="enabled",banks="bank",alts="alts",autoscan="autoScan"})[feature]] end
        control:SetChecked(enabled and true or false)
    end
end

function UI.ToggleSettings()
    if not UI.settings then
        local frame = CreateFrame("Frame", "WaylaidLedgerSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
        frame:SetSize(480, 500)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetClampedToScreen(true)
        frame.TitleText:SetText("Waylaid Ledger settings")
        tinsert(UISpecialFrames, "WaylaidLedgerSettingsFrame")
        UI.settings, UI.settingsChecks = frame, {}
        for index, option in ipairs({
            {"minimap", "Show minimap button"}, {"tracking", "Remember crate and material inventory"},
            {"banks", "Include visited character and shared banks"}, {"alts", "Include remembered characters on this realm/faction"},
            {"autoscan", "Auto refresh tracked prices in the Crates tab"},
            {"scanopen", "Auto-scan crate prices on auction open (Auto/Own)"}, {"details", "Always show detailed price tooltips"},
        }) do
            local feature = option[1]
            local control = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
            control:SetPoint("TOPLEFT", 15, -35 - (index - 1) * 35)
            local label = control:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            label:SetPoint("LEFT", control, "RIGHT", 3, 0)
            label:SetText(option[2])
            control:SetScript("OnClick", function(self) addon:SetFeature(feature, self:GetChecked() and true or false) end)
            UI.settingsChecks[feature] = control
        end
        UI.writSourceButton = button(frame, "Writ prices", 18, -290, 210, function()
            local sources = { auto = "auctionator", auctionator = "tsm", tsm = "off", off = "auto" }
            addon:SetWritSource(sources[addon.db.writSource])
        end)
        button(frame, "Scan controls / diagnostics", 18, -325, 230, function() UI.OpenControls(); frame:Hide() end)
        local note = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        note:SetPoint("TOPLEFT", 18, -365)
        note:SetWidth(440)
        note:SetJustifyH("LEFT")
        note:SetText("Offline characters are last-seen snapshots. Log into each character and visit their bank once. No auction queries run away from the auction house.")
        button(frame, "Clear remembered inventory", 18, -440, 230, function()
            addon.db.inventory = { characters = {}, sharedBanks = {} }
            addon.Inventory.CaptureBags()
            addon.Inventory.CaptureBank()
            UI.Update()
        end)
        frame:Hide()
    end
    UI.UpdateSettings()
    UI.settings:SetShown(not UI.settings:IsShown())
end

function UI.ShowReport(text)
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
    UI.reportEdit:SetText(text)
    UI.report:Show()
    UI.reportEdit:SetFocus()
    UI.reportEdit:HighlightText()
end
