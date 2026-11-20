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

local function unitAmount(value)
    -- A positive fraction of a copper must not appear as a free reward.
    return value and addon.Money(math.ceil(value)) or "—"
end

local function unitTitle(kind)
    return kind == "writs" and L["Cost / reputation"] or L["Cost / Favor"]
end

local function rewardLabel(entry)
    if not entry.reward then
        return L["Reward unknown"]
    end
    return string.format(entry.kind == "writs" and L["%d rep"] or L["%d Favor"], entry.reward)
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
    if entry.kind == "writs" and GameTooltip.waylaidLedgerItemID ~= entry.itemID then
        addon.Tooltip.AppendWritInfo(GameTooltip, entry.itemID, entry.purchaseQuote)
    end
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
    GameTooltip:AddLine(rewardLabel(entry), 1, 1, 1)
    GameTooltip:AddDoubleLine(unitTitle(entry.kind), unitAmount(entry.unitCost), 1, 0.82, 0, 1, 0.82, 0)
    GameTooltip:AddLine(L["Base rewards; bonuses and gold rewards are excluded."], 0.85, 0.85, 0.85, true)
    if not entry.reward then
        GameTooltip:AddLine(L["Reward unverified; excluded from cost-per-reward ranking."], 0.85, 0.85, 0.85, true)
    end
    if row.waylaidView and row.waylaidView.cached then
        GameTooltip:AddLine(L["Open the auction house to shop."], 0.85, 0.85, 0.85, true)
    end
    GameTooltip:Show()
end

local function layoutRow(row, width)
    local column = math.min(125, width * 0.16)
    row.name:SetWidth(math.max(80, width - 4 * column - 46))
    row.deliveryName:SetWidth(math.max(80, width - 4 * column - 46))
    for index, label in ipairs({ row.purchase, row.delivery, row.total, row.unitCost }) do
        label:ClearAllPoints()
        if index == 4 then
            label:SetPoint("TOPRIGHT", row, "TOPRIGHT", -6, -3)
        else
            label:SetPoint("RIGHT", row, "RIGHT", -(4 - index) * column - 6, 0)
        end
        label:SetWidth(column - 10)
    end
    row.reward:SetWidth(column - 10)
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
        row.unitCost = text(row, "GameFontHighlightSmall", "RIGHT")
        row.reward = text(row, "GameFontDisableSmall", "RIGHT")
        row.reward:SetPoint("TOPRIGHT", row, "TOPRIGHT", -6, -18)
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
    local detail = addon.Shopping.DeliveryLabel(entry)
    if entry.discount then
        detail = string.format(L["%d%% below usual"], entry.discount) .. " · " .. detail
    end
    if entry.completedToday then
        detail = L["Delivered today"] .. " · " .. detail
    end
    row.deliveryName:SetText(detail)
    row.purchase:SetText(amount(entry.purchase))
    row.delivery:SetText(amount(entry.delivery))
    row.total:SetText(amount(entry.total))
    row.unitCost:SetText(unitAmount(entry.unitCost))
    row.reward:SetText(rewardLabel(entry))
    local unitColor = entry.unitCost and 1 or 0.65
    row.unitCost:SetTextColor(unitColor, unitColor, unitColor)
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
    local column = math.min(125, width * 0.16)
    view.summary:SetWidth(math.max(1, view.host:GetWidth() - (view.tripButton and 645 or 430)))
    for index, header in ipairs(view.headers) do
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", view.inset, "TOPLEFT", index == 1 and 4 or (width - (6 - index) * column + 4), -3)
        header:SetWidth(index == 1 and (width - 4 * column) or column)
        local selected = header.sortKey == view.sortKey
        -- Native sort texture: font glyph coverage varies between client locales.
        header.sortArrow:SetShown(selected)
        header.sortArrow:SetTexCoord(0, 0.5625, view.sortDescending and 0 or 1, view.sortDescending and 1 or 0)
        addon.Localization.ButtonText(header, header.sortTitle, selected and 15 or 0)
        local font = header:GetFontString()
        if font then
            font:SetWidth(math.max(1, header:GetWidth() - (selected and 27 or 12)))
        end
    end
    view.scroll:ForEachFrame(function(row)
        layoutRow(row, width)
    end)
end

function Browse.ScanStatus()
    local external = addon.Providers.scan
    if external then
        return external.percent and string.format(L["Auctionator: %d%%"], external.percent)
            or L["Another addon is scanning."],
            true,
            true
    end
    local scanner = addon.scanner
    local job = addon.BulkScan.engine and addon.BulkScan.engine.job
    if job then
        if job.resolving then
            local done, total = addon.Discovery.Progress()
            if total == 0 then
                return L["Finishing full scan"], true
            end
            return string.format(L["Descriptions %d/%d"], done, total), true
        end
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
    local status, busy, external
    if not view.cached then
        status, busy, external = Browse.ScanStatus()
    end
    view.summary:SetText(
        status or string.format(L["%d priced / %d items"], view.priced or 0, #(view.visibleEntries or {}))
    )
    addon.Localization.ButtonText(view.refreshButton, busy and not external and L["Stop"] or L["Refresh"])
    view.refreshButton:SetEnabled(not external)
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
    local visible, priced, hiddenDelivered = {}, 0, false
    for _, entry in ipairs(view.entries or {}) do
        if
            query == ""
            or addon.DiscoveryLocales.Key(entry.name):find(query, 1, true)
            or addon.DiscoveryLocales.Key(addon.Shopping.DeliveryLabel(entry)):find(query, 1, true)
        then
            if entry.completedToday and not view.showDelivered then
                hiddenDelivered = true
            else
                visible[#visible + 1] = entry
                if entry.total then
                    priced = priced + 1
                end
            end
        end
    end
    table.sort(visible, function(left, right)
        return addon.Shopping.Compare(left, right, view.sortKey, view.sortDescending)
    end)
    for index, entry in ipairs(visible) do
        entry.listIndex = index
    end
    -- Replacing a ScrollBox provider releases/reacquires every visible button,
    -- even when the same items remain in the same order. Preserve the existing
    -- entry objects (also used by offscreen rows) and repaint prices in place.
    local old = view.visibleEntries
    local sameOrder = old ~= nil and #old == #visible
    if sameOrder then
        for index, entry in ipairs(visible) do
            if old[index].itemID ~= entry.itemID then
                sameOrder = false
                break
            end
        end
    end
    if sameOrder then
        for index, entry in ipairs(visible) do
            local current = old[index]
            if current ~= entry then
                for key in pairs(current) do
                    current[key] = nil
                end
                for key, value in pairs(entry) do
                    current[key] = value
                end
            end
        end
        view.scroll:ForEachFrame(function(row)
            initializeRow(view, row, row.entry)
        end)
    else
        view.visibleEntries = visible
        view.scroll:SetDataProvider(CreateDataProvider(visible), true)
    end
    view.priced = priced
    Browse.UpdateStatus(view)
    view.empty:SetText(
        hiddenDelivered and L["Matching writs were delivered today. Select Show delivered to see them."]
            or L["No matching items. Clear or change the search."]
    )
    view.empty:SetShown(#visible == 0)
    Browse.Layout(view)
    if not sameOrder or resetFocus then
        addon.Navigation.RefreshView(view, previous)
    end
end

function Browse.Sort(view, key)
    if not addon.Shopping.SortKeys[key] then
        return
    end
    view.sortDescending = view.sortKey == key and not view.sortDescending or false
    view.sortKey = key
    view.scroll:ScrollToBegin()
    Browse.Render(view)
end

function Browse.Refresh(view)
    if addon.Providers.scan then
        Browse.UpdateStatus(view)
        return -- Keep existing rows while Auctionator's database is changing.
    end
    view.entries = addon.Shopping.Entries(view.kind)
    Browse.Render(view)
end

function Browse.UpdateVisible()
    if Browse.updating then
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

function Browse.Create(host, kind, cachedOwner)
    local view = { host = host, kind = kind, headers = {}, sortKey = "unitCost", sortDescending = false }
    view.cached, view.owner = cachedOwner ~= nil, cachedOwner
    Browse.views[cachedOwner and ("cached_" .. kind) or kind] = view
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
    view.summary:SetPoint("TOPLEFT", kind == "writs" and 461 or 215, -13)
    if kind == "writs" then
        local delivered = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
        delivered:SetSize(135, 22)
        delivered:SetPoint("TOPLEFT", 210, -8)
        addon.Localization.ButtonText(delivered, L["Show delivered"])
        delivered:SetScript("OnClick", function(self)
            view.showDelivered = not view.showDelivered
            addon.Localization.ButtonText(self, view.showDelivered and L["Hide delivered"] or L["Show delivered"])
            view.scroll:ScrollToBegin()
            Browse.Render(view)
        end)
        view.deliveredButton = delivered
        local trips = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
        trips:SetSize(100, 22)
        trips:SetPoint("TOPLEFT", 352, -8)
        addon.Localization.ButtonText(trips, L["Writ trips"])
        trips:SetScript("OnClick", function()
            addon.WritTrips.Open(view)
        end)
        view.tripButton = trips
    end
    local refresh = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
    refresh:SetMotionScriptsWhileDisabled(true)
    refresh:SetSize(75, 22)
    refresh:SetPoint("TOPRIGHT", -100, -8)
    addon.Localization.ButtonText(refresh, L["Refresh"])
    refresh:SetScript("OnClick", function()
        if view.cached then
            addon.Providers.Invalidate()
            Browse.Refresh(view)
            return
        end
        local _, busy, external = Browse.ScanStatus()
        if external then
            return
        end
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
        local _, busy, external = Browse.ScanStatus()
        local title = L["Refresh prices"]
        if not view.cached and external then
            title = L["Another addon is scanning."]
        elseif not view.cached and busy then
            title = L["Stop scan"]
        end
        GameTooltip:AddLine(title, 1, 0.82, 0)
        if view.cached then
            GameTooltip:AddLine(
                L["Saved prices. Visit the auction house for current prices and purchases."],
                1,
                1,
                1,
                true
            )
        elseif external then
            GameTooltip:AddLine(L["Wait for the other addon's scan to finish before refreshing prices."], 1, 1, 1, true)
        elseif busy then
            GameTooltip:AddLine(
                L["Stop Waylaid's scan or snapshot processing; keep saved prices. Other addons' scans continue."],
                1,
                1,
                1,
                true
            )
        elseif addon:RefreshPriceProvider(view.kind) then
            GameTooltip:AddLine(L["Reload cached provider prices. Scan in that addon for newer data."], 1, 1, 1, true)
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
    view.settingsButton = settings
    view.inset = CreateFrame("Frame", nil, host, "InsetFrameTemplate")
    view.inset:SetPoint("TOPLEFT", 10, -40)
    view.inset:SetPoint("BOTTOMRIGHT", -10, -4)
    for index, title in ipairs({ L["Item / delivery goods"], L["Purchase"], L["Delivery"], L["Total"], unitTitle(kind) }) do
        local header = CreateFrame("Button", nil, view.inset, "ColumnDisplayButtonNoScriptsTemplate")
        header.sortKey = ({ "name", "purchase", "delivery", "total", "unitCost" })[index]
        header.sortTitle = title
        header:SetText(title)
        header.sortArrow = header:CreateTexture(nil, "OVERLAY")
        header.sortArrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
        header.sortArrow:SetSize(9, 8)
        header.sortArrow:SetPoint("RIGHT", header, "RIGHT", -6, 0)
        header.sortArrow:Hide()
        header:EnableMouse(true)
        header:SetScript("OnClick", function(self)
            Browse.Sort(view, self.sortKey)
        end)
        header:SetScript("OnEnter", function(self)
            if not GameTooltip then
                return
            end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.sortTitle, 1, 0.82, 0)
            GameTooltip:AddLine(L["Click to sort; click again to reverse."], 1, 1, 1, true)
            GameTooltip:Show()
        end)
        header:SetScript("OnLeave", function()
            if GameTooltip then
                GameTooltip:Hide()
            end
        end)
        view.headers[index] = header
    end
    view.scroll = CreateFrame("Frame", nil, view.inset, "WowScrollBoxList")
    view.scroll:SetPoint("TOPLEFT", 4, -29)
    view.scroll:SetPoint("BOTTOMRIGHT", -26, 4)
    view.scrollBar = CreateFrame("EventFrame", nil, view.inset, "WowClassicScrollBar")
    -- Arrow/thumb buttons are mouse controls, not selectable list entries.
    addon.Navigation.Ignore(view.scrollBar)
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
    view.empty:SetText(L["No matching items. Clear or change the search."])
    view.empty:Hide()
    host:SetScript("OnSizeChanged", function()
        Browse.Layout(view)
    end)
    return view
end
