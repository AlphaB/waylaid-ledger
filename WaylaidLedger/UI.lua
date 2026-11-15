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
    frame:SetSize(540, 400)
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

    local intro = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    intro:SetPoint("TOPLEFT", 15, -39)
    intro:SetWidth(510)
    intro:SetJustifyH("LEFT")
    intro:SetText("Hover a crate to compare bundles. Green: lowest verified scan cost. Amber: lowest estimate. Keep auction searches idle during our scans.")

    UI.source = button(frame, "", 15, -80, 245, function()
        for index, source in ipairs(SOURCE_ORDER) do
            if source == addon.db.source then
                addon:SetSource(SOURCE_ORDER[index % #SOURCE_ORDER + 1])
                return
            end
        end
    end)
    UI.tsmKey = button(frame, "", 275, -80, 245, function()
        addon:SetTSMKey(addon.db.tsmKey == "DBMinBuyout" and "DBMarket" or "DBMinBuyout")
    end)
    UI.bags = button(frame, "Scan bags", 15, -114, 160, function() addon:StartScan("bags") end)
    UI.hovered = button(frame, "Scan hovered", 187, -114, 160, function() addon:StartScan("hovered") end)
    UI.all = button(frame, "Scan all (96)", 359, -114, 160, function() addon:StartScan("all") end)
    UI.stop = button(frame, "Stop scan", 15, -147, 160, function() addon.scanner:Stop() end)
    button(frame, "Copy diagnostics", 187, -147, 160, function() UI.ShowReport(addon:Report()) end)

    UI.crate = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    UI.crate:SetPoint("TOPLEFT", 15, -187)
    UI.crate:SetWidth(510)
    UI.crate:SetJustifyH("LEFT")
    UI.option = button(frame, "Hover a crate to choose a bundle", 15, -212, 505, function()
        local crate = addon.lastCrateID and addon.Crates[addon.lastCrateID]
        if crate then
            UI.optionIndex = UI.optionIndex % #crate.options + 1
            UI.Update()
        end
    end)
    UI.search = button(frame, "Search all alternatives", 15, -247, 245, function() addon:Shop(true) end)
    UI.shop = button(frame, "Shop selected option", 275, -247, 245, function() addon:Shop(false) end)

    UI.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    UI.status:SetPoint("TOPLEFT", 15, -289)
    UI.status:SetWidth(510)
    UI.status:SetJustifyH("LEFT")
    local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetPoint("BOTTOMLEFT", 15, 15)
    footer:SetWidth(510)
    footer:SetJustifyH("LEFT")
    footer:SetText("Shopping opens Auctionator; buy only one bundle. Click the option to cycle. Our scan prices become stale after 30 minutes. /wll help")
    frame:Hide()
end

function UI.Update()
    if not UI.frame then
        return
    end
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
        UI.crate:SetText(addon.Catalog.ItemName(crateID))
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
end

function UI.Toggle()
    UI.Update()
    UI.frame:SetShown(not UI.frame:IsShown())
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
