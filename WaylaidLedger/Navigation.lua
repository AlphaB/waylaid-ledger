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
    Nav.Refresh(frame, options.scroll, target)
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
    local view = Nav.auctionView
    if not Nav.auctionOwned or not AuctionHouseFrame or not available() then
        return
    end
    local button = SmartNavigation:GetCurrentButton()
    local focused = view and view.host:IsVisible() and button and (button == view.scroll or button.waylaidView == view)
    SmartNavigation:SetScrollFrameForFrame(AuctionHouseFrame, focused and view.scroll or nil)
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
    local function link(source, direction, target)
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
    local directions = SMART_NAV_INPUT_DIRECTION
    -- Actionable headers sit between the page controls and the virtual list.
    link(view.search, directions.DOWN, view.headers[1])
    link(view.refreshButton, directions.DOWN, view.headers[4])
    link(view.settingsButton, directions.DOWN, view.headers[5])
    for index, header in ipairs(view.headers) do
        link(header, directions.LEFT, view.headers[index - 1])
        link(header, directions.RIGHT, view.headers[index + 1])
        link(
            header,
            directions.UP,
            index == 1 and view.search or (index == 5 and view.settingsButton or view.refreshButton)
        )
    end
    local tabs = addon.UI.browserTabs or {}
    local category = tabs[view.kind]
    local auctionTab = addon.UI.auctionTab
    -- Auction tabs sit below the page, category tabs above it. Bind both
    -- explicitly: geometric navigation can pick a native scroll child instead.
    link(auctionTab, directions.UP, view.search)
    link(auctionTab, directions.DOWN, view.search)
    for _, tab in pairs(tabs) do
        link(tab, directions.DOWN, view.search)
        link(tab, directions.UP, auctionTab)
    end
    link(tabs.writs, directions.RIGHT, tabs.crates)
    link(tabs.crates, directions.LEFT, tabs.writs)
    for _, control in ipairs({ view.search, view.refreshButton, view.settingsButton }) do
        link(control, directions.UP, category or auctionTab)
    end
    link(view.search, directions.LEFT)
    link(view.search, directions.RIGHT, view.refreshButton)
    link(view.refreshButton, directions.LEFT, view.search)
    link(view.refreshButton, directions.RIGHT, view.settingsButton)
    link(view.settingsButton, directions.LEFT, view.refreshButton)
    link(view.settingsButton, directions.RIGHT)
end

function Nav.RefreshView(view, previous, enterPage)
    if not available() or not view.host:IsVisible() then
        return
    end
    local target
    if enterPage then
        target = view.search
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
    Nav.auctionOwned, Nav.auctionCleanupPending, Nav.auctionView = true, false, view
    Nav.BindView(view)
    Nav.Refresh(AuctionHouseFrame, nil, target)
    Nav.UpdateAuctionScroll()
end

function Nav.EnterView(view)
    if not available() or not view.host:IsVisible() then
        return
    end
    Nav.Focus(AuctionHouseFrame)
    Nav.RefreshView(view, nil, true)
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
end
