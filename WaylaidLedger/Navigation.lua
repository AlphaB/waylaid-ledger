local _, addon = ...
addon.Navigation = { windows = {}, ignored = {}, windowOrder = {} }
local Nav = addon.Navigation

local function available()
    return not (InCombatLockdown and InCombatLockdown())
        and SmartNavigation
        and SmartNavigation.RefreshButtonGroups
        and SmartNavigation.SetScrollFrameForFrame
        and SmartNavigation.SetTargetButtonForFrame
        and SmartNavigation.GetCurrentButton
        and InputUtil
        and InputUtil.IsGamepadUIEnabled
        and InputUtil.IsGamepadUIEnabled()
end

local function manager()
    local controls = GamepadMode and GamepadMode.FrameControlsManager
    if controls and controls.FrameShown and controls.FrameHidden and controls.GetActiveFrame then
        return controls
    end
end

function Nav.Focus(frame)
    if frame and frame:IsVisible() and available() and manager() then
        local controls = manager()
        if controls:GetActiveFrame() == frame then
            return
        end
        -- FocusFrame itself is not a security-wrapped addon entry point. Rejoin
        -- through the wrapped lifecycle so native focus activation stays secure.
        controls:FrameHidden(frame)
        controls:FrameShown(frame)
    end
end

-- Only call Blizzard's exposed, security-wrapped entry points. Never replace
-- native bindings or write SmartNavigation's internal panel/button tables.
function Nav.Refresh(owner, scroll, target)
    if not owner or not owner:IsVisible() or not available() then
        return
    end
    if owner == AuctionHouseFrame then
        Nav.auctionOwned = true
    end
    SmartNavigation:RefreshButtonGroups(owner)
    SmartNavigation:SetScrollFrameForFrame(owner, scroll)
    if target then
        SmartNavigation:SetTargetButtonForFrame(owner, target)
    end
end

function Nav.Ignore(frame)
    Nav.ignored[frame] = true
    if SmartNavigation_MarkFrameIgnored and not (InCombatLockdown and InCombatLockdown()) then
        SmartNavigation_MarkFrameIgnored(frame)
    end
end

function Nav.RefreshWindow(frame)
    local options = Nav.windows[frame]
    if not options or not available() then
        return
    end
    local current = SmartNavigation:GetCurrentButton()
    local ancestor = current
    while ancestor and ancestor ~= frame do
        ancestor = ancestor:GetParent()
    end
    -- Keep the current control when rebuilding a visible page, including after
    -- combat. A newly opened page starts at its first useful control.
    local fallback = options.target
    if type(fallback) == "function" then
        fallback = fallback()
    end
    local target = ancestor and current:IsVisible() and current or fallback
    local scroll = options.scroll
    if type(scroll) == "function" then
        scroll = scroll()
    end
    Nav.Refresh(frame, scroll, target)
end

function Nav.RegisterWindow(frame, options)
    if Nav.windows[frame] then
        return
    end
    Nav.windows[frame] = options or {}
    table.insert(Nav.windowOrder, frame)
    frame:HookScript("OnShow", function()
        -- Keep show order deterministic when gamepad initialization or combat
        -- defers registration of several overlapping windows.
        for index, window in ipairs(Nav.windowOrder) do
            if window == frame then
                table.remove(Nav.windowOrder, index)
                break
            end
        end
        table.insert(Nav.windowOrder, frame)
        if available() and manager() then
            manager():FrameShown(frame)
            Nav.RefreshWindow(frame)
        end
        if Nav.windows[frame].deferFocus and C_Timer and C_Timer.After then
            -- Settings finishes ActivateCategory/FocusContainer after the
            -- canvas OnShow, potentially selecting a hidden SettingsList row.
            -- Repair once after that native stack finishes, never while hidden.
            C_Timer.After(0, function()
                local controls = manager()
                local active = controls and controls:GetActiveFrame()
                -- A report or another dialog opened in the same tick wins.
                if frame:IsVisible() and (not active or active == frame or active == SettingsPanel) then
                    Nav.Focus(frame)
                    Nav.RefreshWindow(frame)
                end
            end)
        end
    end)
    frame:HookScript("OnHide", function()
        if available() and manager() then
            manager():FrameHidden(frame)
        end
    end)
end

-- Standalone addon windows share title-bar dragging and the same close path
-- for Escape and native controller Back. Embedded panels keep their host.
function Nav.RegisterStandaloneWindow(frame, options)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    local grip = CreateFrame("Frame", nil, frame)
    grip:SetPoint("TOPLEFT", 4, -3)
    grip:SetPoint("TOPRIGHT", -35, -3)
    grip:SetHeight(23)
    grip:EnableMouse(true)
    grip:RegisterForDrag("LeftButton")
    Nav.Ignore(grip)
    local moving
    local function stop()
        if moving then
            frame:StopMovingOrSizing()
            moving = false
        end
    end
    grip:SetScript("OnDragStart", function()
        frame:StartMoving()
        moving = true
    end)
    grip:SetScript("OnDragStop", stop)
    frame:HookScript("OnHide", stop)
    tinsert(UISpecialFrames, frame:GetName())
    frame.SmartNavigationCloseHandler = function()
        frame:Hide()
        return true
    end
    Nav.RegisterWindow(frame, options)
end

function Nav.CurrentEntry(view)
    if not available() then
        return
    end
    local button = SmartNavigation:GetCurrentButton()
    if button and button.waylaidView == view then
        return button.entry
    end
end

function Nav.UpdateAuctionScroll()
    if not available() then
        return
    end
    local button = SmartNavigation:GetCurrentButton()
    for _, view in pairs(addon.BrowseUI.views) do
        if view.host:IsVisible() then
            local owner = view.owner or AuctionHouseFrame
            local focused = button and (button == view.scroll or button.waylaidView == view)
            if owner then
                SmartNavigation:SetScrollFrameForFrame(owner, focused and view.scroll or nil)
            end
        end
    end
end

local function link(view, source, direction, target)
    if not source then
        return
    end
    SmartNavigation_AddJumpNavigationOverride(source, direction, function()
        if not available() or not view.host:IsVisible() then
            return
        end
        return target and target:IsVisible() and target or true
    end)
end

local function bindTabs(view, target)
    local directions = SMART_NAV_INPUT_DIRECTION
    local tabs = view.tabs or addon.UI.browserTabs or {}
    local auctionTab = not view.cached and addon.UI.auctionTab or nil
    link(view, auctionTab, directions.UP, target)
    link(view, auctionTab, directions.DOWN, target)
    for _, tab in pairs(tabs) do
        link(view, tab, directions.DOWN, target)
        link(view, tab, directions.UP, auctionTab)
    end
    link(view, tabs.writs, directions.RIGHT, tabs.crates)
    link(view, tabs.crates, directions.LEFT, tabs.writs)
    link(view, tabs.crates, directions.RIGHT, tabs.trips)
    link(view, tabs.trips, directions.LEFT, tabs.crates)
    return tabs[view.kind], auctionTab
end

function Nav.RefreshTripView(view, entering)
    if not available() or not view.host:IsVisible() then
        return
    end
    local owner = view.owner or AuctionHouseFrame
    if not view.cached then
        Nav.auctionOwned, Nav.auctionCleanupPending = true, false
    end
    local first = view.target()
    local current = SmartNavigation:GetCurrentButton()
    if SMART_NAV_INPUT_DIRECTION and SmartNavigation_AddJumpNavigationOverride then
        local category = bindTabs(view, first)
        for _, control in ipairs({ view.selector, view.send, view.save, view.savedButton, view.refresh }) do
            link(view, control, SMART_NAV_INPUT_DIRECTION.UP, category)
        end
    end
    Nav.Refresh(owner, view.scroll, (entering or not current or not current:IsVisible()) and first or nil)
end

function Nav.BindView(view)
    if
        not SmartNavigation_AddJumpNavigationOverride
        or not SMART_NAV_INPUT_DIRECTION
        or (InCombatLockdown and InCombatLockdown())
    then
        return
    end
    -- Enter a row directly, bypassing native geometric navigation's automatic
    -- centering of scroll-frame children before the list has focus.
    local function enter()
        if not available() or not view.host:IsVisible() then
            return
        end
        local target
        view.scroll:ForEachFrame(function(row)
            if row.entry and (not target or row.entry.listIndex < target.entry.listIndex) then
                target = row
            end
        end)
        return target or true
    end
    for _, header in ipairs(view.headers) do
        SmartNavigation_AddJumpNavigationOverride(header, SMART_NAV_INPUT_DIRECTION.DOWN, enter)
    end
    local directions = SMART_NAV_INPUT_DIRECTION
    -- Actionable headers sit between the page controls and the virtual list.
    link(view, view.search, directions.DOWN, view.headers[1])
    link(view, view.deliveredButton, directions.DOWN, view.headers[2])
    link(view, view.refreshButton, directions.DOWN, view.headers[4])
    link(view, view.settingsButton, directions.DOWN, view.headers[5])
    for index, header in ipairs(view.headers) do
        link(view, header, directions.LEFT, view.headers[index - 1])
        link(view, header, directions.RIGHT, view.headers[index + 1])
        link(
            view,
            header,
            directions.UP,
            index == 1 and view.search
                or (index == 2 and view.deliveredButton)
                or (index == 5 and view.settingsButton or view.refreshButton)
        )
    end
    local category, auctionTab = bindTabs(view, view.search)
    for _, control in ipairs({ view.search, view.refreshButton, view.settingsButton }) do
        link(view, control, directions.UP, category or auctionTab)
    end
    link(view, view.search, directions.LEFT)
    link(view, view.deliveredButton, directions.UP, category or auctionTab)
    link(view, view.search, directions.RIGHT, view.deliveredButton or view.refreshButton)
    link(view, view.deliveredButton, directions.LEFT, view.search)
    link(view, view.deliveredButton, directions.RIGHT, view.refreshButton)
    link(view, view.refreshButton, directions.LEFT, view.deliveredButton or view.search)
    link(view, view.refreshButton, directions.RIGHT, view.settingsButton)
    link(view, view.settingsButton, directions.LEFT, view.refreshButton)
    link(view, view.settingsButton, directions.RIGHT)
end

function Nav.RefreshView(view, previous, initialTarget)
    if not available() or not view.host:IsVisible() then
        return
    end
    local target
    if initialTarget then
        target = initialTarget
    elseif previous then
        for index, entry in ipairs(view.visibleEntries) do
            if entry.itemID == previous.itemID then
                view.scroll:ScrollToElementDataIndex(index, ScrollBoxConstants.AlignNearest, 0, true)
                target = view.scroll:FindFrame(entry)
                break
            end
        end
        target = target or view.search
    else
        local current = SmartNavigation:GetCurrentButton()
        if current and not current:IsVisible() then
            target = view.search
        end
    end
    if not view.cached then
        Nav.auctionOwned, Nav.auctionCleanupPending, Nav.auctionView = true, false, view
    end
    Nav.BindView(view)
    Nav.Refresh(view.owner or AuctionHouseFrame, nil, target)
    Nav.UpdateAuctionScroll()
end

function Nav.EnterView(view, target)
    if not available() or not view.host:IsVisible() then
        return
    end
    Nav.Focus(view.owner or AuctionHouseFrame)
    if view.kind == "trips" then
        Nav.RefreshTripView(view, true)
    else
        Nav.RefreshView(view, nil, target or view.search)
    end
end

function Nav.LeaveAuction()
    if not Nav.auctionOwned then
        return
    end
    Nav.auctionCleanupPending = true
    Nav.auctionView = nil
    if not available() or not AuctionHouseFrame then
        return
    end
    SmartNavigation:SetScrollFrameForFrame(AuctionHouseFrame, nil)
    SmartNavigation:SetTargetButtonForFrame(AuctionHouseFrame, nil)
end

function Nav.CleanupAuction()
    if not Nav.auctionCleanupPending or not available() or not AuctionHouseFrame then
        return
    end
    Nav.LeaveAuction()
    if AuctionHouseFrame:IsVisible() then
        SmartNavigation:RefreshButtonGroups(AuctionHouseFrame)
        local current = SmartNavigation:GetCurrentButton()
        if current and not current:IsVisible() then
            SmartNavigation:SetTargetButtonForFrame(AuctionHouseFrame, AuctionHouseFrame.Tabs[1])
            SmartNavigation:SetTargetButtonForFrame(AuctionHouseFrame, nil)
        end
    end
    Nav.auctionOwned, Nav.auctionCleanupPending = false, false
end

function Nav.BindRow(view, row)
    row.waylaidView = view
    if
        not SmartNavigation_AddJumpNavigationOverride
        or not SMART_NAV_INPUT_DIRECTION
        or (InCombatLockdown and InCombatLockdown())
    then
        return
    end
    local function move(delta)
        return function()
            if not available() then
                return
            end
            local index = row.entry.listIndex + delta
            local entry = view.visibleEntries[index]
            if not entry then
                if delta < 0 then
                    for _, header in ipairs(view.headers) do
                        if header.sortKey == view.sortKey then
                            return header
                        end
                    end
                    return view.search
                end
                return true
            end
            -- ScrollBox rows are virtual. Scroll first, then resolve the newly
            -- bound frame; using the old pool index can activate another item.
            view.scroll:ScrollToElementDataIndex(index, ScrollBoxConstants.AlignNearest, 0, true)
            return view.scroll:FindFrame(entry)
        end
    end
    SmartNavigation_AddJumpNavigationOverride(row, SMART_NAV_INPUT_DIRECTION.UP, move(-1))
    SmartNavigation_AddJumpNavigationOverride(row, SMART_NAV_INPUT_DIRECTION.DOWN, move(1))
    SmartNavigation_AddJumpNavigationOverride(row, SMART_NAV_INPUT_DIRECTION.LEFT, view.search)
    SmartNavigation_AddJumpNavigationOverride(row, SMART_NAV_INPUT_DIRECTION.RIGHT, view.settingsButton)
end

function Nav.Install()
    if not (InCombatLockdown and InCombatLockdown()) then
        for frame in pairs(Nav.ignored) do
            Nav.Ignore(frame)
        end
    end
    if
        InputUtil
        and InputUtil.RegisterForInterfaceTransitions
        and InputUtil.RegisterGamepadInit
        and not Nav.registered
    then
        Nav.registered = true
        InputUtil.RegisterForInterfaceTransitions(Nav)
        InputUtil.RegisterGamepadInit(Nav, function()
            Nav.Install()
        end)
    end
    if not available() then
        return
    end
    if SmartNavigation.RegisterCallback and Nav.callbackOwner ~= SmartNavigation then
        SmartNavigation:RegisterCallback("SelectedButtonUpdated", Nav.UpdateAuctionScroll, Nav)
        Nav.callbackOwner = SmartNavigation
    end
    Nav.CleanupAuction()
    local controls = manager()
    if controls then
        -- Complete all deferred hides before adding visible windows. Removing
        -- a stale active window afterwards can otherwise steal restored focus.
        for _, frame in ipairs(Nav.windowOrder) do
            if not frame:IsVisible() then
                controls:FrameHidden(frame)
            end
        end
        local active = controls:GetActiveFrame()
        for _, frame in ipairs(Nav.windowOrder) do
            if frame:IsVisible() then
                -- A repair must not take focus from Blizzard's buy screen or
                -- another open panel. A fresh gamepad session has no active UI.
                controls:FrameShown(frame, nil, not (active and active:IsVisible()))
                Nav.RefreshWindow(frame)
            end
        end
    end
    if addon.BrowseUI then
        for _, view in pairs(addon.BrowseUI.views) do
            view.scroll:ForEachFrame(function(row)
                Nav.BindRow(view, row)
            end)
            Nav.RefreshView(view)
        end
    end
    local trip = addon.TripPlanner and addon.TripPlanner.state
    if trip then
        Nav.RefreshTripView(trip)
    end
end
