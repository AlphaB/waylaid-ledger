local addon, test, equal = ...

local locales = {
    { "enUS", "Settings", "Own scans" },
    { "enGB", "Settings", "Own scans" },
    { "deDE", "Einstellungen", "Eigene Scans" },
    { "frFR", "Options", "Mes analyses" },
    { "esES", "Opciones", "Análisis propios" },
    { "esMX", "Opciones", "Análisis propios" },
    { "ptBR", "Configurações", "Buscas próprias" },
    { "ruRU", "Настройки", "Свои сканирования" },
    { "koKR", "설정", "자체 검색" },
    { "zhTW", "設定", "自行掃描" },
}

local function formatArguments(value)
    local arguments, types = {}, {}
    -- All translated templates currently use unnumbered %d/%s placeholders.
    for kind in value:gmatch("%%([a-zA-Z])") do
        assert(kind == "d" or kind == "s", "Unsupported placeholder: " .. value)
        types[#types + 1] = kind
        arguments[#arguments + 1] = kind == "d" and 7 or "sample"
    end
    return table.concat(types), arguments
end

test("every control key has a complete, format-compatible translation in every official locale", function()
    local originalLocale = GetLocale
    local ok, err = pcall(function()
        for _, sample in ipairs(locales) do
            local locale = sample[1]
            GetLocale = function()
                return locale
            end
            local dictionary = assert(addon.Locales[locale], locale)
            equal(addon.L["Settings"], sample[2])
            equal(addon.L["Own scans"], sample[3])
            for _, key in ipairs(LOCALIZATION_KEYS) do
                if locale ~= "enUS" and locale ~= "enGB" then
                    assert(type(dictionary[key]) == "string" and dictionary[key] ~= "", locale .. " missing: " .. key)
                end
                local expected, args = formatArguments(key)
                equal(formatArguments(addon.L[key]), expected, locale .. " format: " .. key)
                assert(pcall(string.format, addon.L[key], unpack(args)), locale .. " cannot format: " .. key)
            end
        end
        GetLocale = function()
            return "unknown"
        end
        equal(addon.L["Settings"], "Settings")
        GetLocale = function()
            return "deDE"
        end
        equal(addon.L["A future untranslated label"], "A future untranslated label")
    end)
    GetLocale = originalLocale
    assert(ok, err)
end)

for _, sample in ipairs(locales) do
    test(sample[1] .. " boots localized controls and preserves settings and shopping quantities", function()
        local saved = {}
        local globals = {
            "GetLocale",
            "WaylaidLedgerDB",
            "C_AuctionHouse",
            "C_Container",
            "AuctionHouseFrame",
            "WaylaidLedgerFrame",
            "WaylaidLedgerReportFrame",
            "WaylaidLedgerBasketFrame",
            "WaylaidLedgerMinimapButton",
            "GameTooltip",
            "Minimap",
        }
        for _, key in ipairs(globals) do
            saved[key] = _G[key]
        end
        local callback, slash = TooltipDataProcessor.callback, SlashCmdList.WAYLAIDLEDGER
        local categoryCount, specialCount = #Settings.categories, #UISpecialFrames
        local ok, err = pcall(function()
            GetLocale = function()
                return sample[1]
            end
            WaylaidLedgerDB = nil
            C_AuctionHouse = TEST_SCANNER_FIXTURE().api
            C_AuctionHouse.GetItemKeyInfo = function()
                return { isCommodity = true }
            end
            C_Container = {
                GetContainerNumSlots = function()
                    return 0
                end,
            }
            AuctionHouseFrame = CreateFrame("Frame", nil, UIParent)
            GameTooltip = CreateFrame("GameTooltip", nil, UIParent)
            Minimap = CreateFrame("Frame", nil, UIParent)
            local a = {}
            -- Follow the actual install manifest, including the locale load order.
            for line in io.lines(PROJECT_ROOT .. "/WaylaidLedger/WaylaidLedger.toc") do
                if line:match("%.lua$") and not line:match("^Libs/") then
                    assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/" .. line))("WaylaidLedger", a)
                end
            end
            local host = TEST_FRAMES[#TEST_FRAMES]
            host.scripts.OnEvent(host, "ADDON_LOADED", "WaylaidLedger")
            equal(a.initialized, true)
            assert(a.UI.settingsChecks.scanopen)
            a.UI.ToggleSettings()
            equal(a.UI.crateSourceButton.text, a.L["Auto"])
            a:SetSource("own")
            equal(a.db.source, "own")
            equal(a.UI.crateSourceButton.text, sample[3])
            a.UI.settingsChecks.scanopen:SetChecked(true)
            a.UI.settingsChecks.scanopen.scripts.OnClick(a.UI.settingsChecks.scanopen)
            equal(WaylaidLedgerDB.scanOnOpen, true)
            a:Command("controls")
            equal(a.UI.settings:IsShown(), true)
            equal(a.UI.frame, nil)
            a.scanner:SetOpen(true)
            local view = a.BrowseUI.Create(CreateFrame("Frame", nil, UIParent), "crates")
            equal(view.refreshButton.text, a.L["Refresh"])
            equal(view.scanButton, nil)
            equal(view.stopButton, nil)
            equal(view.headers[2].text, a.L["Purchase"])
            a.BrowseUI.Refresh(view)
            equal(view.empty.text, a.L["No matching items. For first-time discovery, run /wll scan all at the AH."])
            local nativeAvailable = a.NativeShopping.Available
            a.NativeShopping.Available = function()
                return true
            end
            equal(a.NativeShopping.Show({ { itemID = 8069, quantity = 200 } }), true)
            equal(a.NativeShopping.buttons[1].requirement.quantity, 200)
            equal(a.NativeShopping.frame.TitleText.text, a.L["Waylaid shopping basket"])
            a.NativeShopping.Available = nativeAvailable
            assert(a.MinimapButton.frame)
            GameTooltip.lines = {}
            a.MinimapButton.frame.scripts.OnEnter(a.MinimapButton.frame)
            equal(GameTooltip.lines[2][1], a.L["Left-click: auction list"])
            -- A writ-only inventory still supports the advanced hovered-scan command.
            a.Writs[31] = { name = "Test writ", requirements = { { itemID = 11, quantity = 200 } } }
            a.lastCrateID, a.lastContractID = nil, 31
            a.UI.Update(false)
            a:Command("scan hovered")
            equal(#a.scanner.queue, 2)
            equal(a.scanner.queue[1], 11)
            equal(a.scanner.queue[2], 31)
            a:StopScan()
            a.Crates[21] =
                { name = "Test crate", options = { { itemID = 11, quantity = 1 }, { itemID = 12, quantity = 2 } } }
            a.MaterialNames[11], a.MaterialNames[12] = "Test goods A", "Test goods B"
            local tip = CreateFrame("GameTooltip", nil, UIParent)
            a.Tooltip.Append(tip, 21)
            equal(tip.lines[3][2], a.L["Not scanned"])
            a:Command("source auto")
            equal(a.db.source, "auto")
            a:Command("writsource off")
            equal(a.db.writSource, "off")
            equal(a.UI.writSourceButton.text, a.L["Off"])
        end)
        for _, key in ipairs(globals) do
            _G[key] = saved[key]
        end
        TooltipDataProcessor.callback, SlashCmdList.WAYLAIDLEDGER = callback, slash
        while #Settings.categories > categoryCount do
            table.remove(Settings.categories)
        end
        while #UISpecialFrames > specialCount do
            table.remove(UISpecialFrames)
        end
        assert(ok, err)
    end)
end

test("localized list filtering keeps accented and Cyrillic names intact", function()
    local previous = addon.BrowseUI.views.crates
    local view = addon.BrowseUI.Create(CreateFrame("Frame", nil, UIParent), "crates")
    view.entries = {
        { itemID = 1, name = "églantine", requirements = {} },
        { itemID = 2, name = "мироцвет", requirements = {} },
    }
    for _, row in ipairs({ { "ÉGLANTINE", 1 }, { "МИРОЦВЕТ", 2 } }) do
        view.query = row[1]
        addon.BrowseUI.Render(view, true)
        equal(#view.visibleEntries, 1)
        equal(view.visibleEntries[1].itemID, row[2])
    end
    addon.BrowseUI.views.crates = previous
end)
