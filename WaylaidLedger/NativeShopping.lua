local _, addon = ...
local L = addon.L
addon.NativeShopping = {}
local Native = addon.NativeShopping

local function quantityEvent(quantity)
    AuctionHouseFrame:TriggerEvent(AuctionHouseFrameMixin.Event.CommoditiesQuantitySelectionChanged, quantity)
end

function Native.CancelIfHidden()
    if Native.pendingQuantity and (not addon.scanner.open or not AuctionHouseFrame.CommoditiesBuyFrame:IsShown()
        or AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay:GetItemID() ~= Native.pendingQuantity.itemID) then
        Native.pendingQuantity = nil
    end
end

function Native.Results(itemID)
    Native.CancelIfHidden()
    local pending = Native.pendingQuantity
    if pending and pending.itemID == itemID then pending.responded = true end
end

function Native.ExternalQuery(method, argument)
    if Native.issuing or not Native.pendingQuantity then return end
    if method == "RequestMoreCommoditySearchResults" and argument == Native.pendingQuantity.itemID then return end
    Native.pendingQuantity = nil
end

-- Native refresh can replace a quantity with 1 after cached empty results.
-- Reapply this basket's intent only after a matching fresh response has passed
-- through the native list, without touching its private loaded/capped flags.
function Native.AfterRefresh(list)
    Native.CancelIfHidden()
    local pending = Native.pendingQuantity
    if not pending or not pending.responded then return end
    if list ~= AuctionHouseFrame.CommoditiesBuyFrame.ItemList then return end
    pending.responded = false
    local full = C_AuctionHouse.HasFullCommoditySearchResults(pending.itemID)
    local available = C_AuctionHouse.GetCommoditySearchResultsQuantity(pending.itemID)
    if full or available >= pending.quantity then Native.pendingQuantity = nil end
    quantityEvent(pending.quantity)
end

local function watchQuantity(itemID, quantity)
    local list = AuctionHouseFrame.CommoditiesBuyFrame.ItemList
    if Native.boundList ~= list then
        hooksecurefunc(list, "RefreshScrollFrame", function() Native.AfterRefresh(list) end)
        Native.boundList = list
    end
    Native.pendingQuantity = { itemID = itemID, quantity = quantity }
end

function Native.Available()
    return AuctionHouseFrame and type(AuctionHouseFrame.SelectBrowseResult) == "function"
        and type(AuctionHouseFrame.QueryItem) == "function"
        and type(AuctionHouseFrame.SetDisplayMode) == "function"
        and C_AuctionHouse and type(C_AuctionHouse.GetItemKeyInfo) == "function"
end

-- Uses Blizzard's buy screens and confirmation flow; no purchase API is called.
function Native.OpenItem(requirement)
    if not addon.scanner.open or not Native.Available() then return false, L["Open the auction house first."] end
    local key = C_AuctionHouse.MakeItemKey(requirement.itemID)
    local info = C_AuctionHouse.GetItemKeyInfo(key)
    if not info then
        if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(requirement.itemID) end
        return false, L["Item information is loading. Try again in a moment."]
    end
    if not C_AuctionHouse.IsThrottledMessageSystemReady() or not addon.scanner:BudgetReady(GetTime()) then
        return false, L["Auction searches are throttled. Try again shortly."]
    end
    addon:StopScan(L["Stopped to open a basket item in the auction house."])
    Native.pendingQuantity = nil
    local context = info.isCommodity and AuctionHouseSearchContext.BuyCommodities or AuctionHouseSearchContext.BuyItems
    -- Return through the native browse screen to reset visible buy controls.
    -- Cached quantity flags can still survive SetItemID; AfterRefresh restores
    -- the desired amount once the matching fresh results have been processed.
    AuctionHouseFrame:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
    AuctionHouseFrame:SelectBrowseResult({ itemKey = key, minPrice = 0 })
    if info.isCommodity then
        watchQuantity(requirement.itemID, requirement.quantity)
    end
    Native.issuing = true
    local ok, reason = pcall(AuctionHouseFrame.QueryItem, AuctionHouseFrame, context, key, info.isEquipment == true)
    Native.issuing = false
    if not ok then Native.pendingQuantity = nil; return false, string.format(L["Could not open the auction search: %s"], tostring(reason)) end
    if info.isCommodity then
        quantityEvent(requirement.quantity)
    end
    -- Keep the checklist open beside the buy screen, but return controller focus
    -- to the auction window so its listings and confirmation remain reachable.
    local buyFrame = info.isCommodity and AuctionHouseFrame.CommoditiesBuyFrame or AuctionHouseFrame.ItemBuyFrame
    addon.Navigation.Focus(AuctionHouseFrame)
    addon.Navigation.Refresh(AuctionHouseFrame, buyFrame.ItemList and buyFrame.ItemList.ScrollBox,
        AuctionHouseFrame.Tabs[1])
    return true
end

function Native.Show(requirements, alternatives)
    if not Native.Available() then return false, L["The auction house's buying UI is unavailable."] end
    if not Native.frame then
        local frame = CreateFrame("Frame", "WaylaidLedgerBasketFrame", UIParent, "BasicFrameTemplateWithInset")
        frame:Hide()
        frame:SetWidth(340)
        frame:SetPoint("TOPLEFT", AuctionHouseFrame, "TOPRIGHT", 6, 0)
        frame:SetClampedToScreen(true)
        frame:SetFrameStrata("DIALOG")
        frame.TitleText:SetText(L["Waylaid shopping basket"])
        tinsert(UISpecialFrames, "WaylaidLedgerBasketFrame")
        Native.frame, Native.buttons = frame, {}
        frame:HookScript("OnHide", function() Native.pendingQuantity = nil end)
        Native.note = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        Native.note:SetPoint("TOPLEFT", 14, -32)
        Native.note:SetWidth(310); Native.note:SetJustifyH("LEFT")
        Native.note:SetWordWrap(true)
        addon.Navigation.RegisterWindow(frame)
    end
    Native.requirements = requirements
    Native.note:SetText(alternatives and L["Compare these alternatives; buy only one bundle."]
        or L["Open each item and buy the quantity shown. Purchases use the auction house's confirmation."])
    local noteHeight = Native.note.GetStringHeight and Native.note:GetStringHeight() or 0
    local firstRow = 32 + math.max(50, (noteHeight or 0) + 12)
    for index, requirement in ipairs(requirements) do
        local button = Native.buttons[index]
        if not button then
            button = CreateFrame("Button", nil, Native.frame, "UIPanelButtonTemplate")
            button:SetSize(310, 30)
            button:SetScript("OnClick", function(self)
                local ok, reason = Native.OpenItem(self.requirement)
                if not ok then addon:Print(reason) end
            end)
            Native.buttons[index] = button
        end
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", 14, -firstRow - (index - 1) * 36)
        button.requirement = requirement
        addon.Localization.ButtonText(button, requirement.quantity .. "x " .. addon.Catalog.ItemName(requirement.itemID))
        button:Show()
    end
    for index = #requirements + 1, #Native.buttons do Native.buttons[index]:Hide() end
    Native.frame:SetHeight(firstRow + 14 + #requirements * 36)
    Native.frame:Show()
    addon.Navigation.Refresh(Native.frame, nil, Native.buttons[1])
    return true
end

function Native.Close()
    Native.pendingQuantity = nil
    if Native.frame then Native.frame:Hide() end
end
