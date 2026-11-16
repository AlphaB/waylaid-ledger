local _, addon = ...
local L = addon.L
addon.BrowseUI = { views = {} }
local Browse = addon.BrowseUI
local ROW_HEIGHT = 34

local function text(parent, font, justify)
    local label = parent:CreateFontString(nil, "OVERLAY", font)
    label:SetJustifyH(justify or "LEFT")
    label:SetWordWrap(false)
    return label
end

local function amount(value)
    return value and addon.Money(value) or "—"
end

local function quoteLabel(quote)
    if not quote or quote.status ~= "ok" then
        return L["No price"]
    end
    return amount(quote.cost) .. " - " .. (quote.sourceLabel or quote.source)
end

function Browse.ShowTooltip(row)
    if not GameTooltip then
        return
    end
    local entry = row.entry
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(entry.itemID)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["Purchase + delivery"], 1, 0.82, 0)
    GameTooltip:AddDoubleLine(L["Purchase (1)"], quoteLabel(entry.purchaseQuote), 1, 1, 1, 1, 1, 1)
    for _, quote in ipairs(entry.deliveryRows) do
        GameTooltip:AddDoubleLine(
            quote.quantity .. "x " .. addon.Catalog.ItemName(quote.itemID),
            quoteLabel(quote),
            0.85,
            0.85,
            0.85,
            0.85,
            0.85,
            0.85
        )
    end
    GameTooltip:AddDoubleLine(L["Total"], amount(entry.total), 1, 0.82, 0, 1, 0.82, 0)
    GameTooltip:Show()
end

local function layoutRow(row, width)
    local column = math.min(135, width * 0.19)
    row.name:SetWidth(math.max(80, width - 3 * column - 46))
    row.deliveryName:SetWidth(math.max(80, width - 3 * column - 46))
    for index, label in ipairs({ row.purchase, row.delivery, row.total }) do
        label:ClearAllPoints()
        label:SetPoint("RIGHT", row, "RIGHT", -(3 - index) * column - 6, 0)
        label:SetWidth(column - 10)
    end
end

local function initializeRow(view, row, entry)
    -- The native ScrollBox recycles buttons. Scripts must read the currently
    -- bound entry rather than closing over the first item shown by this button.
    if row.waylaidInitialized ~= true then
        row.waylaidInitialized = true
        row:SetHeight(ROW_HEIGHT)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.stripe = row:CreateTexture(nil, "BACKGROUND")
        row.stripe:SetAllPoints()
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(24, 24)
        row.icon:SetPoint("LEFT", 6, 0)
        row.iconBorder = row:CreateTexture(nil, "OVERLAY")
        row.iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        row.iconBorder:SetSize(40, 40)
        row.iconBorder:SetPoint("CENTER", row.icon, "CENTER")
        row.name = text(row, "GameFontHighlightSmall")
        row.name:SetPoint("TOPLEFT", 40, -3)
        row.deliveryName = text(row, "GameFontDisableSmall")
        row.deliveryName:SetPoint("TOPLEFT", 40, -18)
        row.purchase = text(row, "GameFontHighlightSmall", "RIGHT")
        row.delivery = text(row, "GameFontHighlightSmall", "RIGHT")
        row.total = text(row, "GameFontHighlightSmall", "RIGHT")
        row:SetScript("OnClick", function(self)
            addon:ShopEntry(self.entry.kind, self.entry.itemID)
        end)
        row:SetScript("OnEnter", Browse.ShowTooltip)
        row:SetScript("OnLeave", function()
            if GameTooltip then
                GameTooltip:Hide()
            end
        end)
    end
    row.entry = entry
    addon.Navigation.BindRow(view, row)
    row.stripe:SetColorTexture(0, 0, 0, entry.listIndex % 2 == 0 and 0.22 or 0.06)
    row.name:SetText(entry.name)
    row.deliveryName:SetText(addon.Shopping.DeliveryLabel(entry))
    row.purchase:SetText(amount(entry.purchase))
    row.delivery:SetText(amount(entry.delivery))
    row.total:SetText(amount(entry.total))
    local color = entry.total and 1 or 0.65
    for _, label in ipairs({ row.name, row.purchase, row.delivery, row.total }) do
        label:SetTextColor(color, color, color)
    end
    local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(entry.itemID)
    row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    layoutRow(row, view.scroll:GetWidth())
end

function Browse.Layout(view)
    local width = math.max(500, view.host:GetWidth() - 50)
    local column = math.min(135, width * 0.19)
    view.summary:SetWidth(math.max(40, view.host:GetWidth() - 470))
    for index, header in ipairs(view.headers) do
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", view.inset, "TOPLEFT", index == 1 and 4 or (width - (5 - index) * column + 4), -3)
        header:SetWidth(index == 1 and (width - 3 * column) or column)
        addon.Localization.ButtonText(header, header:GetText())
    end
    view.scroll:ForEachFrame(function(row)
        layoutRow(row, width)
    end)
end

function Browse.ScanStatus()
    local scanner = addon.scanner
    local job = addon.BulkScan.engine and addon.BulkScan.engine.job
    if job then
        if job.received and job.count > 0 then
            return string.format(L["Auctions %d/%d"], job.index, job.count), true
        end
        if job.received then
            return L["Finishing full scan"], true
        end
        return job.own and L["Full scan: waiting"] or L["Shared scan: waiting"], true
    end
    if scanner.active then
        local count = #(scanner.queue or {})
        if count > 0 and not scanner.bulkMode then
            return string.format(L["Items %d/%d"], math.min(scanner.index or 1, count), count), true
        end
        return L["Full scan: waiting"], true
    end
end

function Browse.UpdateStatus(view)
    local status, busy = Browse.ScanStatus()
    view.summary:SetText(
        status or string.format(L["%d priced / %d items"], view.priced or 0, #(view.visibleEntries or {}))
    )
    addon.Localization.ButtonText(view.refreshButton, busy and L["Stop"] or L["Refresh"])
end

function Browse.UpdateScanStatus()
    for _, view in pairs(Browse.views) do
        if view.host:IsVisible() then
            Browse.UpdateStatus(view)
        end
    end
end

function Browse.Render(view, resetFocus)
    local previous = not resetFocus and addon.Navigation.CurrentEntry(view)
    local query = addon.DiscoveryLocales.Key(view.query or "")
    local visible, priced = {}, 0
    for _, entry in ipairs(view.entries or {}) do
        if
            query == ""
            or addon.DiscoveryLocales.Key(entry.name):find(query, 1, true)
            or addon.DiscoveryLocales.Key(addon.Shopping.DeliveryLabel(entry)):find(query, 1, true)
        then
            visible[#visible + 1] = entry
            entry.listIndex = #visible
            if entry.total then
                priced = priced + 1
            end
        end
    end
    view.visibleEntries = visible
    view.scroll:SetDataProvider(CreateDataProvider(visible), true)
    view.priced = priced
    Browse.UpdateStatus(view)
    view.empty:SetShown(#visible == 0)
    Browse.Layout(view)
    addon.Navigation.RefreshView(view, previous)
end

function Browse.Refresh(view)
    view.entries = addon.Shopping.Entries(view.kind)
    Browse.Render(view)
end

function Browse.UpdateVisible()
    if Browse.updating or not addon.scanner.open or (AuctionHouseFrame and not AuctionHouseFrame:IsShown()) then
        return
    end
    Browse.updating = true
    for _, view in pairs(Browse.views) do
        if view.host:IsVisible() then
            Browse.Refresh(view)
        end
    end
    Browse.updating = false
end

function Browse.Create(host, kind)
    local view = { host = host, kind = kind, headers = {} }
    Browse.views[kind] = view
    local search = CreateFrame("EditBox", nil, host, "SearchBoxTemplate")
    search:SetSize(180, 22)
    search:SetPoint("TOPLEFT", 20, -8)
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function(self)
        SearchBoxTemplate_OnTextChanged(self)
        view.query = self:GetText() or ""
        view.scroll:ScrollToBegin()
        Browse.Render(view, true)
    end)
    search:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    view.search = search
    view.summary = text(host, "GameFontDisableSmall")
    view.summary:SetPoint("TOPLEFT", 215, -13)
    local refresh = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
    refresh:SetSize(75, 22)
    refresh:SetPoint("TOPRIGHT", -100, -8)
    addon.Localization.ButtonText(refresh, L["Refresh"])
    refresh:SetScript("OnClick", function()
        local _, busy = Browse.ScanStatus()
        if busy then
            addon:StopScan()
        else
            addon:RefreshList(view)
        end
    end)
    refresh:SetScript("OnEnter", function(self)
        if not GameTooltip then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local _, busy = Browse.ScanStatus()
        GameTooltip:AddLine(busy and L["Stop scan"] or L["Refresh prices"], 1, 0.82, 0)
        if busy then
            GameTooltip:AddLine(
                L["Stop Waylaid's scan or snapshot processing; keep saved prices. Other addons' scans continue."],
                1,
                1,
                1,
                true
            )
        elseif addon.BulkScan.Supported(addon.scanner.api) then
            GameTooltip:AddLine(
                L["Request one full auction-house snapshot to update both lists. The search filter only changes the displayed rows."],
                1,
                1,
                1,
                true
            )
        else
            GameTooltip:AddLine(L["Scan purchases and delivery goods for the filtered list."], 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    refresh:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    view.refreshButton = refresh
    local settings = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
    settings:SetSize(75, 22)
    settings:SetPoint("TOPRIGHT", -15, -8)
    addon.Localization.ButtonText(settings, L["Settings"])
    settings:SetScript("OnClick", function()
        addon.UI.ToggleSettings()
    end)
    view.inset = CreateFrame("Frame", nil, host, "InsetFrameTemplate")
    view.inset:SetPoint("TOPLEFT", 10, -40)
    view.inset:SetPoint("BOTTOMRIGHT", -10, -4)
    for index, title in ipairs({ L["Item / delivery goods"], L["Purchase"], L["Delivery"], L["Total (lowest first)"] }) do
        local header = CreateFrame("Button", nil, view.inset, "ColumnDisplayButtonNoScriptsTemplate")
        header:SetText(title)
        header:EnableMouse(false)
        addon.Navigation.Ignore(header)
        view.headers[index] = header
    end
    view.scroll = CreateFrame("Frame", nil, view.inset, "WowScrollBoxList")
    view.scroll:SetPoint("TOPLEFT", 4, -29)
    view.scroll:SetPoint("BOTTOMRIGHT", -26, 4)
    view.scrollBar = CreateFrame("EventFrame", nil, view.inset, "WowClassicScrollBar")
    -- Avoid the classic middle atlas rendering as a green strip on Forever.
    -- Only the decorative rail changes; native thumb/arrow behavior is retained.
    view.scrollBar.Background.Middle:SetColorTexture(0.08, 0.08, 0.08, 1)
    view.scrollBar:SetPoint("TOPLEFT", view.scroll, "TOPRIGHT", 5, 20)
    view.scrollBar:SetPoint("BOTTOMLEFT", view.scroll, "BOTTOMRIGHT", 5, -4)
    local list = CreateScrollBoxListLinearView()
    list:SetElementExtent(ROW_HEIGHT)
    list:SetElementInitializer("Button", function(row, entry)
        initializeRow(view, row, entry)
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(view.scroll, view.scrollBar, list)
    view.empty = text(view.inset, "GameFontDisable")
    view.empty:SetPoint("TOPLEFT", 18, -55)
    view.empty:SetText(L["No matching items. For first-time discovery, run /wll scan all at the AH."])
    view.empty:Hide()
    host:SetScript("OnSizeChanged", function()
        Browse.Layout(view)
    end)
    return view
end
