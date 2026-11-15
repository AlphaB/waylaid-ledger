local addonName, addon = ...
addon.version = "0.2.0"
local frame = CreateFrame("Frame")
local SCHEMA_VERSION = 1
local SOURCES = { auto = true, auctionator = true, tsm = true, own = true }
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

function addon:MarketKey()
    -- Realm/faction isolation is deliberately conservative, even where multiple
    -- realms share an AH. Profiles let neutral/different houses be kept separate.
    return table.concat({ tostring(GetCurrentRegion and GetCurrentRegion() or 0),
        GetNormalizedRealmName() or GetRealmName() or "unknown",
        UnitFactionGroup("player") or "unknown", tostring(WOW_PROJECT_ID or 0), self.db.profile }, ":")
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
    self.Providers.Invalidate()
    self.UI.Update()
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
    self.scanner:Stop("Stopped to hand the search to Auctionator.")
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

function addon:StartScan(scope)
    local crateIDs
    if scope == "all" then
        crateIDs = self.Catalog.AllCrates()
    elseif scope == "hovered" then
        crateIDs = self.lastCrateID and { self.lastCrateID } or {}
    elseif scope == "bags" then
        crateIDs = self.Catalog.BagCrates()
    else
        self:Print("Use /wll scan bags, /wll scan hovered, or /wll scan all.")
        return
    end
    if not self.scanner.active then
        self.scanMarket = self:GetMarket()
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
    elseif command == "stop" then
        self.scanner:Stop()
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
            self.scanner:Stop("Stopped to clear this market's prices.")
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
            self.scanner:Stop("Stopped because the market profile changed.")
            self.db.profile = rest
            self.Providers.Invalidate()
            self:Print("Market profile: " .. rest .. ". Scan this auction house to populate its prices.")
            self.Tooltip.Refresh()
        else
            self:Print("Use a profile name of 1-40 letters, digits, underscores or hyphens.")
        end
    else
        self:Print("/wll - window | scan bags/hovered/all | source auto/auctionator/tsm/own | tsmkey DBMinBuyout/DBMarket")
        self:Print("search - all alternatives | shop [option number] | stop | report | debug | inspect [item ID] | market <name> | clear")
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
            if scanner.active then
                local elapsed = 0
                frame:SetScript("OnUpdate", function(_, delta)
                    elapsed = elapsed + delta
                    if elapsed >= 0.1 then
                        elapsed = 0
                        scanner:Tick()
                    end
                end)
            else
                frame:SetScript("OnUpdate", nil)
                addon.Tooltip.Refresh()
                if scanner.message then
                    addon:Print(scanner.message)
                end
            end
        end,
    })
    addon.UI.Create()
    addon.Providers.Install()
    if not addon.Tooltip.Install() then
        addon:Print("No supported tooltip hook found. Use /wll report to collect diagnostics.")
    end
    for _, method in ipairs({ "SendSearchQuery", "SendSellSearchQuery", "SendBrowseQuery", "SearchForItemKeys", "ReplicateItems" }) do
        if api[method] then
            hooksecurefunc(api, method, function() addon.scanner:ExternalQuery() end)
        end
    end
    for _, event in ipairs({ "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "COMMODITY_SEARCH_RESULTS_UPDATED",
        "COMMODITY_SEARCH_RESULTS_ADDED", "ITEM_SEARCH_RESULTS_UPDATED", "ITEM_SEARCH_RESULTS_ADDED" }) do
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
        elseif addon.initialized and (argument == "Auctionator" or argument == "TradeSkillMaster") then
            addon.Providers.Invalidate()
            addon.Providers.Install()
            addon.UI.Update()
            addon.Tooltip.Refresh()
        end
        return
    end
    local scanner = addon.scanner
    if event == "AUCTION_HOUSE_SHOW" then
        scanner:SetOpen(true)
        addon.UI.Update()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        scanner:SetOpen(false)
        addon.UI.Update()
    elseif event == "COMMODITY_SEARCH_RESULTS_UPDATED" or event == "COMMODITY_SEARCH_RESULTS_ADDED" then
        scanner:Results("commodity", argument)
    elseif event == "ITEM_SEARCH_RESULTS_UPDATED" or event == "ITEM_SEARCH_RESULTS_ADDED" then
        scanner:Results("item", argument)
    end
end)
