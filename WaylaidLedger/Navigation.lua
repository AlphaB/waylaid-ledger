local _, addon = ...
addon.Navigation = { windows = {}, ignored = {} }
local Nav = addon.Navigation

local function available()
    return not (InCombatLockdown and InCombatLockdown())
        and SmartNavigation
        and InputUtil
        and InputUtil.IsGamepadUIEnabled
        and InputUtil.IsGamepadUIEnabled()
end

function Nav.Focus(frame)
    if frame and frame:IsVisible() and available() and GamepadMode and GamepadMode.FrameControlsManager then
        local manager = GamepadMode.FrameControlsManager
        if manager:GetActiveFrame() == frame then
            return
        end
        -- FocusFrame itself is not a security-wrapped addon entry point. Rejoin
        -- through the wrapped lifecycle so native focus activation stays secure.
        manager:FrameHidden(frame)
        manager:FrameShown(frame)
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

function Nav.RegisterWindow(frame)
    if Nav.windows[frame] then
        return
    end
    Nav.windows[frame] = true
    frame:HookScript("OnShow", function()
        if available() and GamepadMode and GamepadMode.FrameControlsManager then
            GamepadMode.FrameControlsManager:FrameShown(frame)
            Nav.Refresh(frame)
        end
    end)
    frame:HookScript("OnHide", function()
        if available() and GamepadMode and GamepadMode.FrameControlsManager then
            GamepadMode.FrameControlsManager:FrameHidden(frame)
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

function Nav.RefreshView(view, previous)
    if not available() or not view.host:IsVisible() then
        return
    end
    local target
    if previous then
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
    Nav.auctionOwned, Nav.auctionCleanupPending = true, false
    Nav.Refresh(AuctionHouseFrame, view.scroll, target)
end

function Nav.LeaveAuction()
    if not Nav.auctionOwned then
        return
    end
    Nav.auctionCleanupPending = true
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
                return delta < 0 and view.search or true
            end
            -- ScrollBox rows are virtual. Scroll first, then resolve the newly
            -- bound frame; using the old pool index can activate another item.
            view.scroll:ScrollToElementDataIndex(index, ScrollBoxConstants.AlignNearest, 0, true)
            return view.scroll:FindFrame(entry)
        end
    end
    SmartNavigation_AddJumpNavigationOverride(row, SMART_NAV_INPUT_DIRECTION.UP, move(-1))
    SmartNavigation_AddJumpNavigationOverride(row, SMART_NAV_INPUT_DIRECTION.DOWN, move(1))
end

function Nav.Install()
    if not (InCombatLockdown and InCombatLockdown()) then
        for frame in pairs(Nav.ignored) do
            Nav.Ignore(frame)
        end
    end
    if InputUtil and InputUtil.RegisterForInterfaceTransitions and not Nav.registered then
        Nav.registered = true
        InputUtil.RegisterForInterfaceTransitions(Nav)
        InputUtil.RegisterGamepadInit(Nav, function()
            Nav.Install()
        end)
    end
    if not available() then
        return
    end
    Nav.CleanupAuction()
    for frame in pairs(Nav.windows) do
        if GamepadMode and GamepadMode.FrameControlsManager then
            if frame:IsVisible() then
                GamepadMode.FrameControlsManager:FrameShown(frame)
                Nav.Refresh(frame)
            else
                -- A hide during combat was deferred; remove stale focus entries
                -- before processing visible windows on the next safe transition.
                GamepadMode.FrameControlsManager:FrameHidden(frame)
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
