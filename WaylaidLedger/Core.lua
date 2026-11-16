local addonName, addon = ...
addon.version = "0.6.0"
local frame = CreateFrame("Frame")
local SCHEMA_VERSION = 1
local SOURCES = { auto = true, auctionator = true, tsm = true, own = true }
local WRIT_SOURCES = { auto = true, auctionator = true, tsm = true, off = true }
local TSM_KEYS = { dbminbuyout = "DBMinBuyout", dbmarket = "DBMarket" }

function addon:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Waylaid Ledger:|r " .. message)
end

function addon:Log(message)
    local log = self.db.log
    log[#log + 1] = date("%H:%M:%S") .. " " .. message
    if #log > 100 then
        table.remove(log, 1)
    end
    if self.db.debug then
        self:Print(message)
    end
end

function addon:MarketBaseKey()
    -- Realm/faction isolation is deliberately conservative, even where multiple
    -- realms share an AH. Profiles let neutral/different houses be kept separate.
    return table.concat({ tostring(GetCurrentRegion and GetCurrentRegion() or 0),
        GetNormalizedRealmName() or GetRealmName() or "unknown",
        UnitFactionGroup("player") or "unknown", tostring(WOW_PROJECT_ID or 0) }, ":")
end

function addon:MarketKey()
    return self:MarketBaseKey() .. ":" .. self.db.profile
end

function addon:UpdateScheduler()
    if self.scanner.active or self.autoDue then
        frame:SetScript("OnUpdate", function()
            if addon.autoDue and GetTime() >= addon.autoDue then
                addon.autoDue = nil
                addon:AutoScan()
            end
            addon.scanner:Tick()
            if not addon.scanner.active and not addon.autoDue then
                frame:SetScript("OnUpdate", nil)
            end
        end)
    else
        frame:SetScript("OnUpdate", nil)
    end
end

function addon:CanAutoScan(reason)
    if self.autoPaused or not self.scanner.open or self.scanner.active
        or (self.db.source ~= "auto" and self.db.source ~= "own") then return false end
    if reason == "open" then return self.db.scanOnOpen end
    return self.db.tracking.enabled and self.db.tracking.autoScan and self.UI.IsScanPanelVisible()
end

function addon:RequestAutoScan(onOpen)
    -- An opening scan has priority over tab-driven refresh until it starts or
    -- is cancelled. The delay lets another addon's startup scan take the house.
    if not onOpen and self.autoReason == "open" then return end
    local reason = onOpen and "open" or "panel"
    if not self:CanAutoScan(reason) then return end
    self.autoReason = reason
    self.autoDue = GetTime() + (onOpen and 2 or 0.5)
    self:UpdateScheduler()
end

function addon:AutoScan()
    local reason = self.autoReason or "panel"
    self.autoReason = nil
    if not self:CanAutoScan(reason) then return end
    local quietPeriod = reason == "open" and 2 or 1
    if self.lastExternalAt and GetTime() - self.lastExternalAt < quietPeriod then
        self.autoReason, self.autoDue = reason, self.lastExternalAt + quietPeriod
        return
    end
    self.Inventory.CaptureBags()
    local crateIDs = reason == "open" and self.Catalog.AllCrates() or self.Inventory.CrateIDs()
    local market, items = self:GetMarket(), {}
    for _, itemID in ipairs(self.Catalog.Materials(crateIDs)) do
        local snapshot = market.items[itemID]
        if not snapshot or market.failures[itemID] or time() - snapshot.scannedAt > self.db.maxAge then
            items[#items + 1] = itemID
        end
    end
    if #items == 0 then return end
    self.scanMarket, self.scanAutomatic, self.scanOnOpen = market, true, reason == "open"
    self.scanner:Start(items)
end

function addon:StopScan(message)
    self.autoPaused, self.autoDue, self.autoReason, self.scanOnOpen = true, nil, nil, false
    self.scanner:Stop(message)
    self:UpdateScheduler()
end

function addon:SetFeature(feature, enabled)
    if feature == "minimap" then
        self.db.minimap.hide = not enabled
        self.MinimapButton.Create()
        self.MinimapButton.Update()
    elseif feature == "scanopen" then
        self.db.scanOnOpen = enabled
        if not enabled and (self.autoReason == "open" or self.scanOnOpen) then
            self:StopScan("Auction-open scan disabled.")
        elseif enabled then
            self.autoPaused = false
            self:RequestAutoScan(true)
        end
    elseif feature == "details" then
        self.db.tooltipDetails = enabled
    else
        local keys = { tracking = "enabled", banks = "bank", alts = "alts", autoscan = "autoScan" }
        self.db.tracking[keys[feature]] = enabled
        if not enabled and (feature == "tracking" or feature == "autoscan") then
            if self.autoReason ~= "open" then self.autoDue, self.autoReason = nil, nil end
            if self.scanAutomatic and not self.scanOnOpen then self:StopScan("Automatic refresh disabled.") end
        end
        self.Inventory.CaptureBags()
        self.Inventory.CaptureBank()
        if enabled then self.autoPaused = false end
    end
    self:UpdateScheduler()
    self.UI.Update()
    self.UI.UpdateSettings()
    self.Tooltip.Refresh()
    self:RequestAutoScan()
end

function addon:GetMarket()
    local key = self:MarketKey()
    local market = self.db.markets[key]
    if not market then
        market = { items = {}, failures = {} }
        self.db.markets[key] = market
    end
    market.failures = market.failures or {}
    return market
end

function addon:GetRows(crateID)
    local market = self:GetMarket()
    return self.Pricing.Resolve(self.Crates[crateID], market.items, time(), self.db.maxAge,
        market.failures, self.db.source, function(source, itemID)
            -- Providers do not expose the house identity for our custom market
            -- profiles. Avoid mixing a faction-house estimate into a neutral scan.
            if self.db.profile ~= "default" then
                return nil
            end
            return self.Providers.Read(source, itemID)
        end)
end

function addon:SetSource(source)
    if not SOURCES[source] then
        self:Print("Use /wll source auto, auctionator, tsm, or own.")
        return
    end
    self.db.source = source
    if source ~= "auto" and source ~= "own" then
        self.autoDue, self.autoReason = nil, nil
        if self.scanAutomatic then self:StopScan("Automatic scan paused for the selected provider.") end
        self:UpdateScheduler()
    end
    self.Providers.Invalidate()
    self.UI.Update()
    self.Tooltip.Refresh()
    self:RequestAutoScan()
end

function addon:SetWritSource(source)
    if not WRIT_SOURCES[source] then
        self:Print("Use /wll writsource auto, auctionator, tsm, or off.")
        return
    end
    self.db.writSource = source
    self.Providers.Invalidate()
    self.UI.UpdateSettings()
    self.Tooltip.Refresh()
end

function addon:SetTSMKey(key)
    local normalized = TSM_KEYS[key:lower()]
    if not normalized then
        self:Print("Use /wll tsmkey DBMinBuyout or DBMarket.")
        return
    end
    self.db.tsmKey = normalized
    self.Providers.Invalidate()
    self.UI.Update()
    self.Tooltip.Refresh()
end

function addon:Shop(allOptions, optionIndex)
    local crate = self.lastCrateID and self.Crates[self.lastCrateID]
    if not crate then
        self:Print("Hover an identified Waylaid Crate first.")
        return false
    end
    if not self.scanner.open then
        self:Print("Open the auction house to search with Auctionator.")
        return false
    end
    if not self.Providers.ShoppingAvailable() then
        self:Print("Auctionator's shopping API is unavailable. Install/enable a compatible Auctionator release.")
        return false
    end
    optionIndex = optionIndex or self.UI.optionIndex or 1
    if not allOptions and (optionIndex ~= math.floor(optionIndex) or not crate.options[optionIndex]) then
        self:Print("Choose an option between 1 and " .. #crate.options .. ".")
        return false
    end
    local terms = {}
    for index, option in ipairs(crate.options) do
        if allOptions or index == optionIndex then
            local name = self.Catalog.SearchName(option.itemID)
            if not name then
                self:Print("An item name is still loading. Try the search again in a moment.")
                return false
            end
            terms[#terms + 1] = { searchString = name, categoryKey = "", isExact = true, quantity = option.quantity }
        end
    end
    -- MultiSearchAdvanced starts Auctionator's own query queue. Never run both
    -- scanners concurrently, even if its first query is deferred until later.
    self:StopScan("Stopped to hand the search to Auctionator.")
    local listName = "Waylaid Ledger - " .. self.lastCrateID
        .. (allOptions and " - alternatives" or (" - option " .. optionIndex))
    local ok, reason = self.Providers.Search(terms, listName)
    if not ok then
        self:Print(reason)
        return false
    end
    self:Log("Auctionator handoff: " .. #terms .. " search terms")
    self:Print(allOptions and "Searching all alternatives in Auctionator. Buy only one bundle to fill the crate."
        or "Opened the selected bundle in Auctionator. Review the listings before buying.")
    return true
end

function addon:ShopEntry(kind, itemID)
    if not self.scanner.open then
        self:Print("Open the auction house to search with Auctionator.")
        return false
    end
    if not self.Providers.ShoppingAvailable(true) then
        self:Print("Auctionator's row-shopping API is unavailable. Update/enable Auctionator.")
        return false
    end
    -- Reprice on click so a stale row cannot select an obsolete filling option.
    local entry = self.Shopping.Entry(kind, itemID)
    local terms, reason = self.Shopping.Terms(entry)
    if not terms then self:Print(reason); return false end
    self:StopScan("Stopped to hand the complete basket to Auctionator.")
    local ok, errorMessage = self.Providers.Search(terms, "Waylaid Ledger - basket - " .. itemID, true)
    if not ok then self:Print(errorMessage); return false end
    self.lastBasket = entry
    self:Log("Basket handoff: " .. kind .. " " .. itemID .. "; " .. #terms .. " search terms")
    return true
end

function addon:StartScan(scope)
    local crateIDs
    if scope == "all" then
        crateIDs = self.Catalog.AllCrates()
    elseif scope == "hovered" then
        crateIDs = self.lastCrateID and { self.lastCrateID } or {}
    elseif scope == "tracked" then
        self.Inventory.CaptureBags()
        crateIDs = self.Inventory.CrateIDs()
    elseif scope == "bags" then
        crateIDs = self.Catalog.BagCrates()
    else
        self:Print("Use /wll scan bags, hovered, tracked, or all.")
        return
    end
    if not self.scanner.active then
        self.scanMarket = self:GetMarket()
        self.scanAutomatic, self.autoPaused, self.autoDue, self.autoReason, self.scanOnOpen = false, false, nil, nil, false
    end
    local ok, message = self.scanner:Start(self.Catalog.Materials(crateIDs))
    if not ok then
        self:Print(message)
    end
    self.UI.Update()
end

function addon:Report()
    local version, build, buildDate, interface = GetBuildInfo()
    local market, count = self:GetMarket(), 0
    for _ in pairs(market.items) do
        count = count + 1
    end
    local rows = self.lastCrateID and self:GetRows(self.lastCrateID) or nil
    local lines = {
        "Waylaid Ledger " .. self.version,
        string.format("Client %s build %s (%s), interface %s", version, build, buildDate, interface),
        "Locale " .. GetLocale() .. "; market " .. self:MarketKey(),
        string.format("Catalog: 30 crates / 96 materials; cached: %d; stale after: %ds", count, self.db.maxAge),
        "Auction API: " .. tostring(C_AuctionHouse and type(C_AuctionHouse.SendSearchQuery)),
        "Modern tooltips: " .. tostring(TooltipDataProcessor ~= nil),
        "Auction house open: " .. tostring(self.scanner.open),
        "Scanner: " .. (self.scanner.message or "Idle"),
        "Last hovered crate: " .. tostring(self.lastCrateID),
        "Writ source: " .. self.db.writSource .. "; last hovered writ: " .. tostring(self.lastWritID),
        string.format("Tracking: enabled=%s banks=%s alts=%s autoRefresh=%s paused=%s",
            tostring(self.db.tracking.enabled), tostring(self.db.tracking.bank), tostring(self.db.tracking.alts),
            tostring(self.db.tracking.autoScan), tostring(self.autoPaused)),
        "AH tab: " .. tostring(self.UI.auctionHost ~= nil) .. "; active: " .. tostring(self.db.browserTab) .. "; minimap hidden: " .. tostring(self.db.minimap.hide),
        "Last basket: " .. tostring(self.lastBasket and self.lastBasket.itemID)
            .. "; total: " .. tostring(self.lastBasket and self.lastBasket.total),
        "Auction-open scan: " .. tostring(self.db.scanOnOpen) .. "; pending reason: " .. tostring(self.autoReason),
        "Scan requests retained in rolling window: " .. #self.scanner.requests,
        "Price policy: " .. self.db.source .. "; TSM key: " .. self.db.tsmKey,
        "Auctionator price API: " .. tostring(self.Providers.Available("auctionator"))
            .. "; shopping API: " .. tostring(self.Providers.ShoppingAvailable())
            .. "; update callback: " .. tostring(self.Providers.boundAPI ~= nil),
        "TSM price API: " .. tostring(self.Providers.Available("tsm")),
        "Provider prices enabled for this profile: " .. tostring(self.db.profile == "default"),
        "Auctionator last error: " .. tostring(self.Providers.errors.auctionator),
        "TSM last error: " .. tostring(self.Providers.errors.tsm),
    }
    if rows then
        for _, row in ipairs(rows) do
            lines[#lines + 1] = string.format("  %d x %d %s: %s cost=%s available=%s age=%s error=%s",
                row.quantity, row.itemID, self.Catalog.ItemName(row.itemID), row.status, tostring(row.cost),
                tostring(row.available), tostring(row.age), tostring(row.error))
            lines[#lines + 1] = string.format("    source=%s estimated=%s ageDays=%s stale=%s scanError=%s",
                tostring(row.source), tostring(row.estimated), tostring(row.ageDays), tostring(row.stale), tostring(row.scanError))
        end
    end
    lines[#lines + 1] = self.Inventory.Report()
    lines[#lines + 1] = "--- Recent scan log ---"
    for _, entry in ipairs(self.db.log) do
        lines[#lines + 1] = entry
    end
    return table.concat(lines, "\n")
end

function addon:Inspect(itemID)
    if not itemID then
        self:Print("Use /wll inspect <item ID> or hover a crate first.")
        return
    end
    local lines = { "In-game item tooltip: " .. itemID }
    local data = C_TooltipInfo and C_TooltipInfo.GetItemByID(itemID)
    if data then
        for _, line in ipairs(data.lines or {}) do
            for _, field in ipairs({ "leftText", "rightText" }) do
                local value = line[field]
                if not (issecretvalue and issecretvalue(value)) and type(value) == "string" then
                    lines[#lines + 1] = value
                end
            end
        end
    else
        lines[#lines + 1] = "Item not cached. Hover it in game and try again."
        if C_Item and C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(itemID)
        end
    end
    self.UI.ShowReport(table.concat(lines, "\n"))
end

function addon:Command(text)
    local command, rest = (text or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command = command:lower()
    if command == "" then
        self.UI.Toggle()
    elseif command == "scan" then
        self:StartScan(rest == "" and "bags" or rest:lower())
    elseif command == "source" then
        if rest == "" then
            self:Print("Price source: " .. self.db.source .. ". Options: auto, auctionator, tsm, own.")
        else
            self:SetSource(rest:lower())
        end
    elseif command == "writsource" then
        if rest == "" then self:Print("Writ source: " .. self.db.writSource .. ". Options: auto, auctionator, tsm, off.")
        else self:SetWritSource(rest:lower()) end
    elseif command == "tsmkey" then
        if rest == "" then
            self:Print("TSM source: " .. self.db.tsmKey .. ". Options: DBMinBuyout, DBMarket.")
        else
            self:SetTSMKey(rest)
        end
    elseif command == "search" then
        self:Shop(true)
    elseif command == "shop" then
        if rest ~= "" and not tonumber(rest) then
            self:Print("Use /wll shop [option number].")
        else
            self:Shop(false, tonumber(rest))
        end
    elseif command == "controls" then
        self.UI.OpenControls()
    elseif command == "settings" then
        self.UI.ToggleSettings()
    elseif command == "inventory" then
        self.UI.ShowReport(self.Inventory.Report())
    elseif command == "minimap" or command == "tracking" or command == "banks" or command == "alts"
        or command == "autoscan" or command == "scanopen" or command == "details" then
        rest = rest:lower()
        if rest ~= "on" and rest ~= "off" then
            self:Print("Use /wll " .. command .. " on or off, or /wll settings.")
        else
            self:SetFeature(command, rest == "on")
        end
    elseif command == "stop" then
        self:StopScan()
    elseif command == "debug" then
        self.db.debug = not self.db.debug
        self:Print("Debug logging " .. (self.db.debug and "enabled." or "disabled."))
    elseif command == "report" then
        self.UI.ShowReport(self:Report())
    elseif command == "inspect" then
        local itemID = tonumber(rest:match("item:(%d+)") or rest) or self.lastCrateID
        self:Inspect(itemID)
    elseif command == "clear" then
        if self.scanner.active then
            self:StopScan("Stopped to clear this market's prices.")
        end
        local market = self:GetMarket()
        market.items, market.failures = {}, {}
        self.Providers.Invalidate()
        self:Print("Cached prices cleared for this market profile.")
        self.Tooltip.Refresh()
    elseif command == "market" then
        if rest == "" then
            self:Print("Current profile: " .. self.db.profile .. ". Change with /wll market <name>.")
        elseif #rest <= 40 and rest:match("^[%w_-]+$") then
            self:StopScan("Stopped because the market profile changed.")
            self.db.profile = rest
            self.Providers.Invalidate()
            self:Print("Market profile: " .. rest .. ". Scan this auction house to populate its prices.")
            self.Tooltip.Refresh()
        else
            self:Print("Use a profile name of 1-40 letters, digits, underscores or hyphens.")
        end
    else
        self:Print("/wll - window | scan bags/hovered/all | source auto/auctionator/tsm/own | tsmkey DBMinBuyout/DBMarket")
        self:Print("search | shop [option number] | stop | report | debug | inspect [item ID] | market <name> | clear")
        self:Print("writsource auto/auctionator/tsm/off | settings | controls | inventory | minimap/tracking/banks/alts/autoscan/scanopen/details on/off | scan tracked")
    end
    self.UI.Update()
end

local function initialize()
    if type(WaylaidLedgerDB) ~= "table" or WaylaidLedgerDB.schema ~= SCHEMA_VERSION then
        WaylaidLedgerDB = { schema = SCHEMA_VERSION, markets = {}, log = {} }
    end
    addon.db = WaylaidLedgerDB
    addon.db.markets = type(addon.db.markets) == "table" and addon.db.markets or {}
    addon.db.log = type(addon.db.log) == "table" and addon.db.log or {}
    addon.db.profile = type(addon.db.profile) == "string" and addon.db.profile or "default"
    addon.db.maxAge = tonumber(addon.db.maxAge) or 1800
    addon.db.inventory = addon.db.inventory or { characters = {}, sharedBanks = {} }
    addon.db.inventory.characters = addon.db.inventory.characters or {}
    addon.db.inventory.sharedBanks = addon.db.inventory.sharedBanks or {}
    addon.db.tracking = addon.db.tracking or {}
    for _, key in ipairs({ "enabled", "bank", "alts", "autoScan" }) do
        if type(addon.db.tracking[key]) ~= "boolean" then addon.db.tracking[key] = true end
    end
    if type(addon.db.scanOnOpen) ~= "boolean" then addon.db.scanOnOpen = false end
    addon.db.minimap = addon.db.minimap or { angle = 225, hide = false }
    addon.db.minimap.angle = tonumber(addon.db.minimap.angle) or 225
    addon.db.writSource = WRIT_SOURCES[addon.db.writSource] and addon.db.writSource or "auto"
    addon.db.source = SOURCES[addon.db.source] and addon.db.source or "auto"
    addon.db.tsmKey = TSM_KEYS[tostring(addon.db.tsmKey):lower()] or "DBMinBuyout"
    local api = C_AuctionHouse
    if not api or not api.SendSearchQuery or not api.MakeItemKey then
        addon:Print("This client has no supported C_AuctionHouse API. Please send its /dump GetBuildInfo() output.")
        return
    end
    addon.scanner = addon.Scanner.New(api, { now = GetTime, wallTime = time }, {
        saved = function(itemID, snapshot)
            addon.scanMarket.items[itemID] = snapshot
            addon.scanMarket.failures[itemID] = nil
        end,
        failed = function(itemID, reason)
            addon.scanMarket.failures[itemID] = reason
        end,
        log = function(message) addon:Log(message) end,
        changed = function(scanner)
            addon.UI.Update()
            addon:UpdateScheduler()
            if not scanner.active then
                addon.scanOnOpen = false
                addon.Tooltip.Refresh()
                if scanner.message and not addon.scanAutomatic then addon:Print(scanner.message) end
            end
        end,
    })
    addon.UI.Create()
    addon.UI.RegisterSettings()
    addon.MinimapButton.Create()
    addon.Inventory.CaptureBags()
    addon.Providers.Install()
    if not addon.Tooltip.Install() then
        addon:Print("No supported tooltip hook found. Use /wll report to collect diagnostics.")
    end
    for _, method in ipairs({ "SendSearchQuery", "SendSellSearchQuery", "SendBrowseQuery", "SearchForItemKeys", "ReplicateItems",
        "RequestMoreCommoditySearchResults", "RequestMoreItemSearchResults" }) do
        if api[method] then
            hooksecurefunc(api, method, function()
                if not addon.scanner.issuing then
                    addon.lastExternalAt = GetTime()
                    if addon.scanner.active then
                        addon.autoPaused, addon.autoDue, addon.autoReason = true, nil, nil
                    elseif addon.autoReason == "open" then
                        -- Initial Blizzard browse queries also pass here. Wait
                        -- for a quiet house instead of cancelling every opening.
                        addon.autoDue = addon.lastExternalAt + 2
                    end
                    addon:UpdateScheduler()
                end
                addon.scanner:ExternalQuery()
            end)
        end
    end
    for _, event in ipairs({ "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "COMMODITY_SEARCH_RESULTS_UPDATED",
        "COMMODITY_SEARCH_RESULTS_ADDED", "ITEM_SEARCH_RESULTS_UPDATED", "ITEM_SEARCH_RESULTS_ADDED",
        "AUCTION_HOUSE_THROTTLED_SYSTEM_READY", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED",
        "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "BANK_TABS_CHANGED", "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED",
        "MODIFIER_STATE_CHANGED", "PLAYER_LOGOUT" }) do
        frame:RegisterEvent(event)
    end
    SLASH_WAYLAIDLEDGER1, SLASH_WAYLAIDLEDGER2 = "/wll", "/waylaidledger"
    SlashCmdList.WAYLAIDLEDGER = function(text) addon:Command(text) end
    addon:Log("Loaded on interface " .. tostring(select(4, GetBuildInfo())))
    addon.initialized = true
    addon:Print("Loaded. /wll opens scans, price sources, and Auctionator shopping.")
end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, argument)
    if event == "ADDON_LOADED" then
        if argument == addonName then
            initialize()
        elseif addon.initialized and argument == "Blizzard_AuctionHouseUI" then
            addon.UI.AttachAuction()
        elseif addon.initialized and (argument == "Auctionator" or argument == "TradeSkillMaster") then
            addon.Providers.Invalidate()
            addon.Providers.Install()
            addon.UI.Update()
            addon.Tooltip.Refresh()
        end
        return
    end
    local scanner = addon.scanner
    if not scanner then return end
    if event == "AUCTION_HOUSE_SHOW" then
        scanner:SetOpen(true)
        addon.autoPaused, addon.autoDue, addon.autoReason = false, nil, nil
        addon.Inventory.CaptureBags()
        addon.UI.AttachAuction()
        addon.UI.Update()
        addon:RequestAutoScan(true)
        addon:RequestAutoScan()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        addon.autoDue, addon.autoReason, addon.scanOnOpen = nil, nil, false
        scanner:SetOpen(false)
        addon.UI.AuctionClosed()
        addon.UI.Update()
        addon:UpdateScheduler()
    elseif event == "AUCTION_HOUSE_THROTTLED_SYSTEM_READY" then
        scanner:Tick()
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        addon.Inventory.CaptureBags()
        addon.MinimapButton.Create()
        addon.UI.Update()
        addon:RequestAutoScan()
    elseif event == "BAG_UPDATE_DELAYED" then
        addon.Inventory.CaptureBags()
        addon.Inventory.CaptureBank()
        addon.UI.Update()
        addon:RequestAutoScan()
    elseif event == "BANKFRAME_OPENED" then
        addon.Inventory.bankOpen = true
        addon.Inventory.CaptureBank()
    elseif event == "BANKFRAME_CLOSED" then
        addon.Inventory.bankOpen = false
    elseif event == "BANK_TABS_CHANGED" or event == "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED" then
        addon.Inventory.CaptureBank()
    elseif event == "PLAYER_LOGOUT" then
        addon.Inventory.CaptureBags()
        addon.Inventory.CaptureBank()
    elseif event == "MODIFIER_STATE_CHANGED" then
        if argument == "LSHIFT" or argument == "RSHIFT" then addon.Tooltip.Refresh() end
    elseif event == "COMMODITY_SEARCH_RESULTS_UPDATED" or event == "COMMODITY_SEARCH_RESULTS_ADDED" then
        scanner:Results("commodity", argument)
    elseif event == "ITEM_SEARCH_RESULTS_UPDATED" or event == "ITEM_SEARCH_RESULTS_ADDED" then
        scanner:Results("item", argument)
    end
end)
