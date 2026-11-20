local addon, test, equal, host = ...

-- These tests use the production windows and callbacks. Unlike the older
-- navigation stub, registering an already shown frame cannot refocus it.
local function fixture(action)
    local names = {
        "SmartNavigation",
        "InputUtil",
        "GamepadMode",
        "InCombatLockdown",
        "SmartNavigation_MarkFrameIgnored",
        "SettingsPanel",
        "HideUIPanel",
        "C_Timer",
    }
    local saved = {}
    for _, name in ipairs(names) do
        saved[name] = _G[name]
    end
    local nav = addon.Navigation
    local registered = nav.registered
    for frame in pairs(nav.windows) do
        frame:Hide()
    end
    local f = { enabled = true, shown = {}, calls = {}, groups = {}, targets = {}, scrolls = {} }
    local deferred = {}
    C_Timer = {
        After = function(_, callback)
            deferred[#deferred + 1] = callback
        end,
    }
    function f.flush()
        local callbacks = deferred
        deferred = {}
        for _, callback in ipairs(callbacks) do
            callback()
        end
    end
    local function safe()
        assert(not f.combat, "native mutation during combat")
        assert(f.enabled, "native mutation with gamepad UI off")
    end
    local manager = {}
    function manager:GetActiveFrame()
        return f.active
    end
    function manager:FrameShown(frame, _, shouldFocus)
        safe()
        f.calls[#f.calls + 1] = { "show", frame }
        if f.shown[frame] then
            return false
        end
        f.shown[frame] = true
        if shouldFocus ~= false then
            f.active, f.current = frame, f.targets[frame]
        end
        return true
    end
    function manager:FrameHidden(frame)
        safe()
        f.calls[#f.calls + 1] = { "hide", frame }
        f.shown[frame] = nil
        if f.active == frame then
            f.active, f.current = nil, nil
        end
    end
    local function forbidden()
        error("unwrapped native focus function called")
    end
    manager.FocusFrame = forbidden
    SmartNavigation = {
        GetCurrentButton = function()
            return f.current
        end,
        RefreshButtonGroups = function(_, frame)
            safe()
            f.groups[frame] = true
        end,
        SetScrollFrameForFrame = function(_, frame, scroll)
            safe()
            f.scrolls[frame] = scroll
        end,
        SetTargetButtonForFrame = function(_, frame, target)
            safe()
            f.targets[frame] = target
            if target and f.active == frame then
                f.current = target
            end
        end,
        SelectButton = forbidden,
        EnterFocusGroup = forbidden,
        LeaveFocusGroup = forbidden,
    }
    InputUtil = {
        IsGamepadUIEnabled = function()
            return f.enabled
        end,
        RegisterForInterfaceTransitions = function() end,
        RegisterGamepadInit = function(_, callback)
            f.init = callback
        end,
    }
    InCombatLockdown = function()
        return f.combat
    end
    SmartNavigation_MarkFrameIgnored = function()
        assert(not f.combat)
    end
    GamepadMode = { FrameControlsManager = manager }
    SettingsPanel = CreateFrame("Frame", nil, UIParent)
    SettingsPanel:Hide()
    -- The real engine propagates visibility changes to descendants. The shared
    -- UI stub does not, so explicitly deliver the canvas hide callback here.
    HideUIPanel = function(frame)
        frame:Hide()
        if frame == SettingsPanel then
            addon.UI.settings:Hide()
        end
    end
    nav.registered = nil
    nav.Install()
    local ok, message = pcall(action, f, nav)
    f.combat, f.enabled = false, true
    for frame in pairs(nav.windows) do
        frame:Hide()
    end
    for _, name in ipairs(names) do
        _G[name] = saved[name]
    end
    nav.registered = registered
    assert(ok, message)
end

test("controller settings owns a native focus scope and Back closes the whole settings panel", function()
    fixture(function(f, nav)
        addon.UI.ToggleSettings()
        equal(addon.UI.settingsTitle:GetText(), "Waylaid Ledger  v" .. addon.version)
        equal(f.active, addon.UI.settings)
        equal(f.current, addon.UI.crateSourceButton)
        assert(f.groups[addon.UI.settings])
        assert(nav.windows[addon.UI.settings])
        -- This works on the official AddOns page too, without the slash opener.
        HideUIPanel(SettingsPanel)
        equal(f.shown[addon.UI.settings], nil)
        Settings.OpenToCategory(addon.UI.settingsCategory:GetID())
        equal(addon.UI.settingsTitle:GetText(), "Waylaid Ledger  v" .. addon.version)
        equal(f.current, addon.UI.crateSourceButton)
        equal(f.active, addon.UI.settings)
        equal(addon.UI.settings:SmartNavigationCloseHandler(), true)
        equal(SettingsPanel:IsShown(), false)
        equal(f.shown[addon.UI.settings], nil)
    end)
end)

test("settings repairs native category focus after layout and cancels delayed focus when closed", function()
    fixture(function(f)
        Settings.OpenToCategory(addon.UI.settingsCategory:GetID())
        -- Native ActivateCategory runs FocusContainer after canvas OnShow.
        f.active = SettingsPanel
        f.current = CreateFrame("Button", nil, SettingsPanel)
        f.flush()
        equal(f.active, addon.UI.settings)
        equal(f.current, addon.UI.crateSourceButton)
        HideUIPanel(SettingsPanel)
        addon.UI.ToggleSettings()
        addon.UI.ShowReport("Opened in the same tick")
        f.flush()
        equal(f.active, addon.UI.report)
        HideUIPanel(SettingsPanel)
        Settings.OpenToCategory(addon.UI.settingsCategory:GetID())
        HideUIPanel(SettingsPanel)
        local other = CreateFrame("Frame", nil, UIParent)
        f.active = other
        f.flush()
        equal(f.active, other)
    end)
end)

test("all settings checkboxes and source buttons activate through the same native click callbacks", function()
    fixture(function(f)
        addon.UI.ToggleSettings()
        local count = 0
        for _, check in pairs(addon.UI.settingsChecks) do
            local before = check:GetChecked()
            f.current = check
            check:SetChecked(not before) -- native CheckButton click toggles first
            check:GetScript("OnClick")(check, "LeftButton")
            equal(check:GetChecked(), not before)
            check:SetChecked(before)
            check:GetScript("OnClick")(check, "LeftButton")
            count = count + 1
        end
        equal(count, 6)
        local source, writSource, tsmKey = addon.db.source, addon.db.writSource, addon.db.tsmKey
        for _, button in ipairs({ addon.UI.crateSourceButton, addon.UI.writSourceButton, addon.UI.settingsTSM }) do
            f.current = button
            for _, option in ipairs(button.choices) do
                if not option.selected() then
                    option.choose()
                    break
                end
            end
            equal(f.current, button)
        end
        assert(addon.db.source ~= source and addon.db.writSource ~= writSource and addon.db.tsmKey ~= tsmKey)
        addon:SetSource(source)
        addon:SetWritSource(writSource)
        addon:SetTSMKey(tsmKey)
    end)
end)

test("settings and reports can be reopened and reports register right-stick scrolling", function()
    fixture(function(f)
        addon.UI.ToggleSettings()
        addon.UI.ShowReport("Controller diagnostic report")
        equal(f.active, addon.UI.report)
        equal(f.current, addon.UI.reportEdit)
        equal(f.scrolls[addon.UI.report], addon.UI.reportEdit:GetParent())
        addon.UI.ToggleSettings()
        equal(f.active, addon.UI.settings)
        addon.UI.ShowReport("Updated report")
        equal(f.active, addon.UI.report)
        addon:Command("controls")
        equal(f.active, addon.UI.settings)
        equal(f.current, addon.UI.crateSourceButton)
        addon.UI.ToggleSettings()
        addon:Command("controls")
        equal(f.active, addon.UI.settings)
    end)
end)

test("the empty writ trip planner opens from the browser and restores the trip button on Back", function()
    fixture(function(f)
        addon.db.browserTab = "writs"
        addon.UI.OpenCachedBrowser()
        local browser = addon.UI.cachedBrowser
        local view = browser.views.writs
        view.tripButton.scripts.OnClick()
        local state = addon.TripPlanner.state
        equal(f.active, state.window)
        equal(f.current, state.close)
        equal(f.scrolls[state.window], state.scroll)
        equal(state.window.SmartNavigationCloseHandler(), true)
        equal(f.active, browser)
        equal(f.current, view.tripButton)
    end)
end)

test("late controller activation restores visible windows in show order and preserves other native focus", function()
    fixture(function(f, nav)
        f.enabled = false
        addon:Command("controls")
        addon.UI.ToggleSettings()
        addon.UI.ShowReport("Late initialization")
        equal(f.active, nil)
        f.enabled = true
        f.init()
        equal(f.active, addon.UI.report)
        equal(f.current, addon.UI.reportEdit)
        local other = CreateFrame("Frame", nil, UIParent)
        f.active, f.current = other, CreateFrame("Button", nil, other)
        local current = f.current
        nav.Install()
        equal(f.active, other)
        equal(f.current, current)
        -- Simulate a mouse/gamepad transition resetting Blizzard's frame list.
        f.shown, f.active, f.current = {}, nil, nil
        f.init()
        equal(f.active, addon.UI.report)
    end)
end)

test("combat defers settings and report navigation and processes every hide before restoring windows", function()
    fixture(function(f, nav)
        addon.UI.ToggleSettings()
        f.combat = true
        HideUIPanel(SettingsPanel)
        addon.UI.ShowReport("Shown during combat")
        f.calls = {}
        nav.Install()
        equal(#f.calls, 0)
        f.combat = false
        host:GetScript("OnEvent")(host, "PLAYER_REGEN_ENABLED")
        equal(f.shown[addon.UI.settings], nil)
        equal(f.active, addon.UI.report)
        local sawShow = false
        for _, call in ipairs(f.calls) do
            if call[1] == "show" then
                sawShow = true
            else
                assert(not sawShow, "hide after show")
            end
        end
    end)
end)

test("partial or absent native controller APIs leave mouse UI operational and retry initialization", function()
    fixture(function(f, nav)
        local input, smart, manager = InputUtil, SmartNavigation, GamepadMode.FrameControlsManager
        InputUtil = {
            RegisterForInterfaceTransitions = function()
                error("incomplete transition API used")
            end,
        }
        nav.registered = nil
        nav.Install()
        equal(nav.registered, nil)
        InputUtil = input
        SmartNavigation = {}
        addon.UI.ToggleSettings()
        addon.UI.ShowReport("No native navigation yet")
        nav.Install()
        equal(f.active, nil)
        SmartNavigation = smart
        GamepadMode.FrameControlsManager = {}
        nav.Install()
        equal(f.active, nil)
        GamepadMode.FrameControlsManager = manager
        nav.Install()
        equal(f.active, addon.UI.report)
    end)
end)

test("cached browser restores controller focus after late activation, combat and reopening over a report", function()
    fixture(function(f, nav)
        f.enabled = false
        addon.UI.OpenCachedBrowser()
        local browser = addon.UI.cachedBrowser
        equal(f.shown[browser], nil)
        f.enabled = true
        nav.Install()
        equal(f.shown[browser], true)
        equal(f.current, browser.views[addon.db.browserTab].search)
        addon.UI.ShowReport("Cached browser focus")
        equal(f.active, addon.UI.report)
        addon.UI.OpenCachedBrowser()
        equal(f.active, browser)
        equal(f.current, browser.views[addon.db.browserTab].search)
        f.combat = true
        browser.SmartNavigationCloseHandler()
        equal(f.shown[browser], true)
        f.combat = false
        host.scripts.OnEvent(host, "PLAYER_REGEN_ENABLED")
        equal(f.shown[browser], nil)
        f.combat = true
        addon.UI.OpenCachedBrowser()
        equal(f.shown[browser], nil)
        f.combat = false
        host.scripts.OnEvent(host, "PLAYER_REGEN_ENABLED")
        equal(f.shown[browser], true)
        assert(f.groups[browser])
    end)
end)

if not UPSTREAM_NAVIGATION then
    return
end

test("Forever source discovers every options action and report editor in its registered navigation scope", function()
    fixture(function(f, nav)
        local env = setmetatable({}, { __index = _G })
        local wrapped = {}
        local helper = {
            RegisterKey = function() end,
            SetSecureValue = function(_, frame, key, value)
                frame[key] = value
            end,
            WrapFunction = function(_, fn)
                wrapped[fn] = true
                return fn
            end,
        }
        env.securecallfunction = function(fn, ...)
            return fn(...)
        end
        env.secureexecuterange = function(items, fn)
            for i, item in ipairs(items) do
                fn(i, item)
            end
        end
        env.issecure = function()
            return true
        end
        env.C_RestrictedActions = {
            IsAddOnRestrictionActive = function()
                return false
            end,
        }
        env.Enum = { AddOnRestrictionType = { Combat = 1 } }
        env.CallbackRegistryMixin = { GenerateCallbackEvents = function() end }
        env.CreateFromMixins = function(base)
            return setmetatable({}, { __index = base })
        end
        env.import = function()
            return helper
        end
        local function loadSource(name)
            return setfenv(assert(loadstring(UPSTREAM_NAVIGATION[name], name)), env)()
        end
        local utility = loadSource("Utility.lua")
        env.import = function(name)
            return name == ".Utility" and utility or helper
        end
        loadSource("SmartNavigation.lua")
        local native = env.SmartNavigationMixin
        for _, method in ipairs({ "RefreshButtonGroups", "SetTargetButtonForFrame", "SetScrollFrameForFrame" }) do
            assert(wrapped[native[method]], method .. " is no longer a wrapped addon entry point")
        end
        local panels = {}
        local smart = setmetatable({
            GetPanelInfo = function(_, frame)
                return panels[frame]
            end,
            SelectButton = function(_, target)
                f.current = target
            end,
            SetRightStickScrollingEnabled = function(_, value)
                f.scrolling = value
            end,
        }, { __index = native })
        local function inspect(frame)
            panels[frame] = { frame = frame }
            smart.activeInfo = panels[frame]
            smart:RefreshButtonGroups(frame)
            local found = {}
            utility.ForEachButtonInGroup(panels[frame].buttonGroups.mainGroup, function(button)
                found[button] = true
            end)
            return found
        end
        addon.UI.ToggleSettings()
        local found = inspect(addon.UI.settings)
        local count = 0
        for _, child in ipairs({ addon.UI.settings:GetChildren() }) do
            if child:GetScript("OnClick") or child:IsObjectType("DropdownButton") then
                assert(found[child], "settings action missing from native focus group")
                count = count + 1
            end
        end
        equal(count, 13)
        assert(found[addon.UI.tripTimeValue], "trip time input missing from native focus group")
        smart:SetTargetButtonForFrame(addon.UI.settings, nav.windows[addon.UI.settings].target)
        equal(f.current, addon.UI.crateSourceButton)
        -- Execute native ActivateCategory -> FocusContainer after the real
        -- canvas OnShow. Its standard-list fallback can pick a hidden row.
        loadSource("Blizzard_SettingsPanel.lua")
        env.SmartNavigation = smart
        local hidden = CreateFrame("CheckButton", nil, SettingsPanel)
        hidden:Hide()
        local panel = setmetatable({
            SelectCategory = function()
                Settings.OpenToCategory(addon.UI.settingsCategory:GetID())
            end,
            GetFirstSmartNavFocusableSettingFrame = function()
                return hidden
            end,
        }, { __index = env.SettingsPanelMixin })
        panel:ActivateCategory(addon.UI.settingsCategory)
        equal(f.current, hidden)
        f.flush()
        equal(f.current, addon.UI.crateSourceButton)
        addon.UI.ShowReport("Native contract")
        found = inspect(addon.UI.report)
        assert(found[addon.UI.reportEdit])
        smart:SetScrollFrameForFrame(addon.UI.report, nav.windows[addon.UI.report].scroll)
        equal(f.scrolling, true)
        -- Loading the focus manager verifies the two addon lifecycle entry points
        -- retain security wrappers; hardware/security execution still needs WoW.
        env.GamepadMode = {}
        env.CreateAndInitFromMixin = function(mixin)
            return mixin
        end
        loadSource("FrameControlsManager.lua")
        assert(wrapped[env.GamepadFrameControlsManagerMixin.FrameShown])
        assert(wrapped[env.GamepadFrameControlsManagerMixin.FrameHidden])
        addon.UI.OpenCachedBrowser()
        local browser = addon.UI.cachedBrowser
        assert(nav.windows[browser])
        for _, kind in ipairs({ "writs", "crates" }) do
            addon.UI.SelectBrowserTab(kind, browser)
            local actions = inspect(browser)
            local view = browser.views[kind]
            for _, control in ipairs({
                browser.tabs.writs,
                browser.tabs.crates,
                view.search,
                view.refreshButton,
                view.settingsButton,
            }) do
                assert(actions[control], "cached browser action missing from native discovery")
            end
            if kind == "writs" then
                assert(actions[view.deliveredButton], "delivered filter missing from native discovery")
                assert(actions[view.tripButton], "writ trips missing from native discovery")
            end
            for _, header in ipairs(view.headers) do
                assert(actions[header], "cached sort header missing from native discovery")
            end
            view.scroll:ForEachFrame(function(row)
                assert(actions[row], "cached row missing from native discovery")
            end)
            smart:SetScrollFrameForFrame(browser, view.scroll)
            equal(f.scrolling, true)
        end
        local candidate = {
            itemID = 264050,
            reward = 75,
            requirements = {},
            canShop = true,
            flag = 1,
            recipient = { destination = { name = "Recipient" } },
        }
        local trip = {
            stop = { name = "Flight Stop" },
            count = 1,
            rep = 75,
            mask = 0,
            required = {},
            chosen = {},
            owned = {},
            candidates = { candidate },
            additions = { { candidate = candidate } },
            departureWalk = 0,
            flight = 0,
            goldPerHour = 6,
            seconds = 10,
            walk = function()
                return { order = {}, seconds = 0 }
            end,
            quote = function()
                return { cost = 100 }
            end,
        }
        addon.TripPlanner.Open(browser.views.writs, { trip }, "")
        local planner = addon.TripPlanner.state
        local plannerActions = inspect(planner.window)
        assert(plannerActions[planner.send], "trip shopping action missing from native discovery")
        assert(plannerActions[planner.selector], "trip selector missing from native discovery")
        assert(plannerActions[planner.rows[1]], "optional writ missing from native discovery")
        assert(plannerActions[planner.close], "planner close missing from native discovery")
        planner.rows[1]:SetChecked(true)
        planner.rows[1].scripts.OnClick(planner.rows[1])
        assert(planner.summary:GetText():find("150 rep", 1, true))
        planner.window.SmartNavigationCloseHandler()
        -- Every named addon dialog instantiated by the production UI must have
        -- a native focus lifecycle, and every action in it must be discoverable.
        local seen = {}
        for _, frame in ipairs(TEST_FRAMES) do
            local name = rawget(frame, "name")
            if
                name
                and not seen[name]
                and name:match("^WaylaidLedger")
                and frame:IsObjectType("Frame")
                and not frame:IsObjectType("Button")
            then
                -- Reload tests create same-name copies owned by another addon
                -- instance; inspect the original production instance only.
                seen[name] = true
                assert(nav.windows[frame], name .. " has no controller registration")
                local actions = inspect(frame)
                local function checkChildren(parent)
                    for _, child in ipairs({ parent:GetChildren() }) do
                        if
                            child:IsVisible()
                            and child:IsEnabled()
                            and (
                                child:GetScript("OnClick")
                                or child:IsObjectType("EditBox")
                                or child:IsObjectType("DropdownButton")
                            )
                        then
                            assert(actions[child], name .. " has an unreachable control")
                        end
                        checkChildren(child)
                    end
                end
                checkChildren(frame)
            end
        end
    end)
end)
