local _, addon = ...
addon.BrowseUI = { views = {} }
local Browse = addon.BrowseUI
local ROW_HEIGHT = 40

local function text(parent, font, justify)
    local label = parent:CreateFontString(nil, "OVERLAY", font)
    label:SetJustifyH(justify or "LEFT")
    label:SetWordWrap(false)
    return label
end

local function amount(value, estimated)
    return value and ((estimated and "~ " or "") .. addon.Money(value)) or "—"
end

local function quoteLabel(quote)
    if not quote or quote.status ~= "ok" then return "No price" end
    return amount(quote.cost, quote.estimated) .. " - " .. (quote.sourceLabel or quote.source)
        .. (quote.stale and " (stale)" or "")
end

function Browse.ShowTooltip(row)
    if not GameTooltip then return end
    local entry = row.entry
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(entry.itemID)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Purchase + delivery", 1, 0.82, 0)
    GameTooltip:AddDoubleLine("Purchase (1)", quoteLabel(entry.purchaseQuote), 1, 1, 1, 1, 1, 1)
    for _, quote in ipairs(entry.deliveryRows) do
        GameTooltip:AddDoubleLine(quote.quantity .. "x " .. addon.Catalog.ItemName(quote.itemID),
            quoteLabel(quote), 0.85, 0.85, 0.85, 0.85, 0.85, 0.85)
    end
    GameTooltip:AddDoubleLine("Total", amount(entry.total, true) .. (entry.stale and " (stale)" or ""),
        1, 0.82, 0, 1, 0.82, 0)
    if entry.kind == "crates" then
        GameTooltip:AddLine("Uses the lowest known filling cost; other options may lack prices.", 0.7, 0.7, 0.7, true)
    end
    GameTooltip:AddLine("Full quantities; owned items are not deducted. Cached prices do not verify stock.", 0.7, 0.7, 0.7, true)
    GameTooltip:AddLine(entry.reason or "Click to search this complete basket in Auctionator.", 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
end

local function createRow(view)
    local row = CreateFrame("Button", nil, view.content)
    row:SetHeight(ROW_HEIGHT)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(28, 28)
    row.icon:SetPoint("LEFT", 4, 0)
    row.name = text(row, "GameFontHighlightSmall")
    row.name:SetPoint("TOPLEFT", 40, -5)
    row.deliveryName = text(row, "GameFontDisableSmall")
    row.deliveryName:SetPoint("TOPLEFT", 40, -22)
    row.purchase = text(row, "GameFontHighlightSmall", "RIGHT")
    row.delivery = text(row, "GameFontHighlightSmall", "RIGHT")
    row.total = text(row, "GameFontHighlightSmall", "RIGHT")
    row:SetScript("OnClick", function(self) addon:ShopEntry(self.entry.kind, self.entry.itemID) end)
    row:SetScript("OnEnter", Browse.ShowTooltip)
    row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    return row
end

function Browse.Layout(view)
    local width = math.max(550, view.host:GetWidth() - 50)
    view.content:SetWidth(width)
    view.summary:SetWidth(math.max(40, view.host:GetWidth() - 470))
    local column = math.min(135, width * 0.19)
    for index, label in ipairs(view.headers) do
        label:ClearAllPoints()
        if index == 1 then label:SetPoint("TOPLEFT", 15, -55)
        else label:SetPoint("TOPRIGHT", view.host, "TOPLEFT", width + 15 - (4 - index) * column, -55) end
    end
    for index, row in ipairs(view.rows) do
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
        row:SetWidth(width)
        row.name:SetWidth(width - 3 * column - 46)
        row.deliveryName:SetWidth(width - 3 * column - 46)
        for n, label in ipairs({ row.purchase, row.delivery, row.total }) do
            label:ClearAllPoints()
            label:SetPoint("RIGHT", row, "RIGHT", -(3 - n) * column, 0)
            label:SetWidth(column - 6)
        end
    end
end

function Browse.Render(view)
    local query = (view.query or ""):lower()
    local visible, priced = {}, 0
    for _, entry in ipairs(view.entries or {}) do
        if query == "" or entry.name:lower():find(query, 1, true)
            or addon.Shopping.DeliveryLabel(entry):lower():find(query, 1, true) then
            visible[#visible + 1] = entry
            if entry.total then priced = priced + 1 end
        end
    end
    view.visibleEntries = visible
    for index, entry in ipairs(visible) do
        local row = view.rows[index]
        if not row then row = createRow(view); view.rows[index] = row end
        row.entry = entry
        row.name:SetText(entry.name)
        row.deliveryName:SetText(addon.Shopping.DeliveryLabel(entry))
        row.purchase:SetText(amount(entry.purchase, true))
        local estimated = false
        for _, quote in ipairs(entry.deliveryRows) do estimated = estimated or quote.estimated or false end
        row.delivery:SetText(amount(entry.delivery, estimated))
        row.total:SetText(amount(entry.total, true) .. (entry.stale and " *" or ""))
        local color = entry.stale and 0.55 or (entry.total and 1 or 0.7)
        for _, label in ipairs({ row.name, row.purchase, row.delivery, row.total }) do label:SetTextColor(color, color, color) end
        local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(entry.itemID)
        row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        -- Keep hover explanations available when a basket cannot be selected.
        row:SetEnabled(true)
        row:Show()
    end
    for index = #visible + 1, #view.rows do view.rows[index]:Hide() end
    view.content:SetHeight(math.max(1, #visible * ROW_HEIGHT))
    local maxScroll = math.max(0, #visible * ROW_HEIGHT - view.scroll:GetHeight())
    view.scroll:SetVerticalScroll(math.min(view.scroll:GetVerticalScroll() or 0, maxScroll))
    view.summary:SetText(string.format("%d priced / %d items - lowest total first", priced, #visible))
    view.empty:SetShown(#visible == 0)
    local policy = view.kind == "writs" and addon.db.writSource or addon.db.source
    view.footer:SetText("Prices: " .. policy .. ". Purchase uses Auctionator/TSM. ~ estimate | * stale | — missing. Stock may differ.")
    Browse.Layout(view)
end

function Browse.Refresh(view)
    view.entries = addon.Shopping.Entries(view.kind)
    Browse.Render(view)
end

function Browse.UpdateVisible()
    if Browse.updating or not addon.scanner.open
        or (AuctionHouseFrame and not AuctionHouseFrame:IsShown()) then return end
    Browse.updating = true
    for _, view in pairs(Browse.views) do
        if view.host:IsShown() then Browse.Refresh(view) end
    end
    Browse.updating = false
end

function Browse.Create(host, kind)
    local view = { host = host, kind = kind, rows = {}, headers = {} }
    Browse.views[kind] = view
    local search = CreateFrame("EditBox", nil, host, "SearchBoxTemplate")
    search:SetSize(220, 22)
    search:SetPoint("TOPLEFT", 20, -12)
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function(self)
        SearchBoxTemplate_OnTextChanged(self)
        view.query = self:GetText() or ""
        view.scroll:SetVerticalScroll(0)
        Browse.Render(view)
    end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    view.search = search
    view.summary = text(host, "GameFontDisableSmall")
    view.summary:SetPoint("TOPLEFT", 255, -17)
    local refresh = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
    refresh:SetSize(75, 22); refresh:SetPoint("TOPRIGHT", -100, -12); refresh:SetText("Refresh")
    refresh:SetScript("OnClick", function() addon.Providers.Invalidate(); Browse.Refresh(view) end)
    local settings = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
    settings:SetSize(75, 22); settings:SetPoint("TOPRIGHT", -15, -12); settings:SetText("Settings")
    settings:SetScript("OnClick", function() addon.UI.ToggleSettings() end)
    for index, title in ipairs({"Item / delivery goods", "Purchase", "Delivery", "Total"}) do
        view.headers[index] = text(host, "GameFontNormalSmall", index == 1 and "LEFT" or "RIGHT")
        view.headers[index]:SetText(title)
    end
    view.scroll = CreateFrame("ScrollFrame", nil, host, "UIPanelScrollFrameTemplate")
    view.scroll:SetPoint("TOPLEFT", 15, -77)
    view.scroll:SetPoint("BOTTOMRIGHT", -35, 44)
    view.content = CreateFrame("Frame", nil, view.scroll)
    view.content:SetSize(800, 1)
    view.scroll:SetScrollChild(view.content)
    view.empty = text(host, "GameFontDisable")
    view.empty:SetPoint("TOPLEFT", 25, -100); view.empty:SetText("No matching items."); view.empty:Hide()
    view.footer = text(host, "GameFontDisableSmall")
    view.footer:SetPoint("BOTTOMLEFT", 15, 14); view.footer:SetPoint("BOTTOMRIGHT", -15, 14)
    host:SetScript("OnSizeChanged", function() Browse.Layout(view) end)
    return view
end
