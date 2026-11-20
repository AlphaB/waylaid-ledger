local _, addon = ...
local L = addon.L
local Trips = addon.WritTrips
local Planner = {}
addon.TripPlanner = Planner

local function font(parent, template, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY", template)
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetWordWrap(true)
    return label
end

local function shoppingBlocker()
    if not addon.scanner.open then
        return L["Open the auction house to shop."]
    end
    if not addon.Providers.ShoppingAvailable(true) then
        return L["Auctionator's shopping API is unavailable. Install/enable a compatible Auctionator release."]
    end
    if addon.Providers.scan then
        return L["Another addon is scanning."]
    end
end

function Planner.UpdateShopping()
    local state = Planner.state
    if state and state.window:IsShown() and not state.saved then
        state.send:SetEnabled(shoppingBlocker() == nil)
    end
end

local function layoutScroll(state, height, resetScroll)
    state.content:SetHeight(height)
    local scroll = state.scroll
    local position = resetScroll and 0 or scroll:GetVerticalScroll()
    scroll:SetVerticalScroll(math.min(position, math.max(0, height - scroll:GetHeight())))
    addon.Navigation.RefreshWindow(state.window)
end

local function update(state, resetScroll)
    local trip = state.plans[state.index]
    local plan = trip and Trips.Recalculate(trip, state.selected[trip])
    state.selector:SetShown(plan ~= nil)
    state.save:SetShown(plan ~= nil)
    local saved = Trips.Saved()
    addon.Localization.ButtonText(state.save, saved and L["Replace saved trip"] or L["Save trip"])
    state.savedButton:SetEnabled(saved ~= nil)
    addon.Localization.ButtonText(state.savedButton, L["Saved trip"])
    state.savedDetails:Hide()
    state.send:SetShown(plan ~= nil)
    state.send:SetEnabled(shoppingBlocker() == nil)
    state.summary:SetText(plan and Trips.Summary(plan) or state.status)
    state.totals:SetText(plan and Trips.Totals(plan) or "")
    state.note:SetShown(plan ~= nil)
    if trip then
        state.note:SetText(
            string.format(L["Time value · %s per hour"], addon.Money(math.floor(trip.goldPerHour * 10000 + 0.5)))
                .. "    "
                .. L["Uses saved prices and your bags. Flight fares are separate."]
        )
    end
    state.heading:SetShown(plan ~= nil)
    state.empty:SetShown(plan ~= nil and #plan.additions == 0)
    state.details:SetText(plan and Trips.Describe(plan) or "")

    local offset = 25
    for index, addition in ipairs(plan and plan.additions or {}) do
        local row = state.rows[index]
        if not row then
            row = CreateFrame("CheckButton", nil, state.content, "UICheckButtonTemplate")
            row:SetSize(26, 26)
            row.label = font(row, "GameFontHighlightSmall", 30, -4, 308)
            row:SetScript("OnClick", function(self)
                local current = state.plans[state.index]
                state.selected[current][self.itemID] = self:GetChecked() and true or nil
                update(state)
            end)
            state.rows[index] = row
        end
        row.itemID = addition.candidate.itemID
        row:SetChecked(state.selected[trip][row.itemID] == true)
        row.label:SetText(Trips.OptionLabel(addition))
        local height = math.max(44, (row.label:GetStringHeight() or 0) + 12)
        row:SetHitRectInsets(0, -312, 0, 26 - height)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", state.content, "TOPLEFT", 0, -offset)
        row:Show()
        offset = offset + height
    end
    for index = (plan and #plan.additions or 0) + 1, #state.rows do
        state.rows[index]:Hide()
    end
    local height = math.max(offset, (state.details:GetStringHeight() or 0) + 30)
    layoutScroll(state, height, resetScroll)
    return plan
end

local function updateSaved(state, resetScroll)
    local saved = Trips.Saved()
    local summary, nextStop, details
    if saved then
        summary, nextStop, details = Trips.SavedRoute(saved)
    end
    state.summary:SetText(summary or L["No writ trip saved for this character."])
    state.totals:SetText(nextStop or "")
    state.note:Hide()
    state.heading:Hide()
    state.empty:Hide()
    state.details:SetText("")
    state.savedDetails:SetText(details or "")
    state.savedDetails:Show()
    state.selector:Hide()
    state.send:Hide()
    state.save:Hide()
    state.savedButton:SetEnabled(true)
    addon.Localization.ButtonText(state.savedButton, L["Plan trips"])
    for _, row in ipairs(state.rows) do
        row:Hide()
    end
    local height = (state.savedDetails:GetStringHeight() or 0) + 30
    layoutScroll(state, height, resetScroll)
end

function Planner.QuestTurnedIn(questID)
    local changed = Trips.RecordTurnIn(questID)
    local state = Planner.state
    if changed and state and state.saved and state.window:IsShown() then
        updateSaved(state)
    end
end

local function sendShopping(state)
    local blocked = shoppingBlocker()
    if blocked then
        addon:Print(blocked)
        return
    end
    local trip = state.plans[state.index]
    if not trip then
        return
    end
    trip.owned = Trips.ReadBags()
    local plan = update(state)
    if #plan.basket == 0 then
        addon:Print(L["You have everything in your bags."])
        return
    end
    local terms, reason = addon.Shopping.BasketTerms(plan.basket)
    if not terms then
        addon:Print(reason)
    elseif addon:SendBasketToAuctionator(terms) then
        -- Auctionator now owns the auction tab and controller focus.
        state.returnView = nil
        state.window:Hide()
    end
end

local function create()
    local window = CreateFrame("Frame", "WaylaidLedgerTripPlannerFrame", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(800, 555)
    window:SetPoint("CENTER")
    window:SetFrameStrata("FULLSCREEN_DIALOG")
    window.TitleText:SetText(L["Writ trips"])
    window:Hide()

    local state = { window = window, rows = {}, plans = {}, selected = {}, index = 1 }
    local close = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    close:SetSize(95, 24)
    close:SetPoint("TOPRIGHT", -16, -34)
    addon.Localization.ButtonText(close, L["Close"])
    close:SetScript("OnClick", function()
        window:Hide()
    end)
    state.close = close

    local send = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    send:SetSize(245, 24)
    send:SetPoint("RIGHT", close, "LEFT", -10, 0)
    addon.Localization.ButtonText(send, L["Send to Auctionator"])
    send:SetMotionScriptsWhileDisabled(true)
    send:SetScript("OnClick", function()
        sendShopping(state)
    end)
    send:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(
                shoppingBlocker() or L["Search for the items and quantities still missing from your bags."],
                1,
                1,
                1,
                true
            )
            GameTooltip:Show()
        end
    end)
    send:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    state.send = send

    local selector = CreateFrame("DropdownButton", nil, window, "WowStyle1DropdownTemplate")
    selector:SetSize(365, 25)
    selector:SetPoint("TOPLEFT", 16, -34)
    selector:SetupMenu(function(_, menu)
        for i, trip in ipairs(state.plans) do
            local index = i
            menu:CreateRadio(trip.stop.name, function()
                return state.index == index
            end, function()
                state.index = index
                update(state, true)
            end)
        end
    end)
    state.selector = selector

    local function action(label, x, callback)
        local control = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
        control:SetSize(155, 24)
        control:SetPoint("TOPLEFT", x, -65)
        addon.Localization.ButtonText(control, L[label])
        control:SetScript("OnClick", callback)
        return control
    end
    state.save = action("Save trip", 16, function()
        local plan = update(state)
        if plan and Trips.Save(plan) then
            state.savedButton:SetEnabled(true)
            addon.Localization.ButtonText(state.save, L["Replace saved trip"])
            addon:Print(L["Trip saved. Open it with /wll trip."])
        end
    end)
    state.savedButton = action("Saved trip", 181, function()
        if state.saved then
            if #state.plans > 0 then
                state.saved = false
                update(state, true)
            else
                Trips.Open(state.returnView)
            end
        else
            state.saved = true
            updateSaved(state, true)
        end
    end)

    state.summary = font(window, "GameFontNormal", 16, -101, 752)
    state.totals = font(window, "GameFontHighlight", 16, -123, 752)
    state.note = font(window, "GameFontDisableSmall", 16, -146, 752)
    local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -172)
    scroll:SetPoint("BOTTOMRIGHT", -35, 16)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(745, 1)
    scroll:SetScrollChild(content)
    state.scroll, state.content = scroll, content
    state.heading = font(content, "GameFontNormal", 0, 0, 340)
    state.heading:SetText(L["Optional writs"])
    state.empty = font(content, "GameFontDisableSmall", 0, -25, 340)
    state.empty:SetText(L["No optional writs for this trip."])
    state.details = font(content, "GameFontHighlightSmall", 365, 0, 380)
    state.details:SetSpacing(3)
    state.savedDetails = font(content, "GameFontHighlight", 0, 0, 745)
    state.savedDetails:SetSpacing(5)

    addon.Navigation.RegisterStandaloneWindow(window, {
        target = function()
            if state.saved or Trips.Saved() and #state.plans == 0 then
                return state.savedButton
            end
            return #state.plans > 0 and selector or close
        end,
        scroll = scroll,
    })
    window:HookScript("OnHide", function()
        local view = state.returnView
        state.returnView = nil
        if view then
            addon.Navigation.EnterView(view, view.tripButton)
        end
    end)
    return state
end

function Planner.Open(view, plans, status)
    local state = Planner.state or create()
    Planner.state = state
    state.returnView, state.plans, state.status, state.index = view, plans, status, 1
    state.selected, state.saved = {}, false
    for _, trip in ipairs(plans) do
        state.selected[trip] = {}
    end
    state.selector:SetShown(#plans > 0)
    state.selector:GenerateMenu()
    update(state, true)
    state.window:Show()
    addon.Navigation.Focus(state.window)
    addon.Navigation.RefreshWindow(state.window)
end

function Planner.OpenSaved()
    local state = Planner.state or create()
    Planner.state = state
    if not state.window:IsShown() then
        state.plans, state.selected, state.index = {}, {}, 1
    end
    state.saved = true
    updateSaved(state, true)
    state.window:Show()
    addon.Navigation.Focus(state.window)
    addon.Navigation.RefreshWindow(state.window)
end
