local addonName, addon = ...
local L = addon.L
addon.version = "0.8.4"
local frame = CreateFrame("Frame")
local SCHEMA_VERSION = 1
local SOURCES = { auto = true, auctionator = true, tsm = true, own = true }
local WRIT_SOURCES = { auto = true, auctionator = true, tsm = true, own = true, off = true }
local TSM_KEYS = { dbminbuyout = "DBMinBuyout", dbmarket = "DBMarket" }

function addon:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Waylaid Ledger:|r " .. message)
end

function addon:Log(message)
    local log = self.db.log
    local entry = date("%H:%M:%S") .. " " .. message:sub(1, 1000)
    log[#log + 1] = entry
    if #log > 100 then
        table.remove(log, 1)
    end
    if self.db.debug then
        self:Print(entry)
    end
end

-- Fixed call-site keys, never item IDs. Disabled diagnostics do no formatting;
-- event storms retain only one counter per category, not individual messages.
function addon:Trace(key, interval, format, ...)
    if not self.db or not self.db.debug then
        return
    end
    local suppressed = 0
    if interval > 0 then
        self.traceState = self.traceState or {}
        local now, previous = GetTime(), self.traceState[key]
        if previous and now - previous.at < interval then
            previous.suppressed = previous.suppressed + 1
            return
        end
        suppressed = previous and previous.suppressed or 0
        self.traceState[key] = { at = now, suppressed = 0 }
    end
    local message = "[" .. key .. "] " .. string.format(format, ...)
    if suppressed > 0 then
        message = message .. string.format(" (%d similar events suppressed)", suppressed)
    end
    self:Log(message)
end

function addon:TraceState()
    self:Trace(
        "state",
        0,
        "v%s; source=%s; writSource=%s; scanOnOpen=%s; AH=%s; ownActive=%s; paused=%s; Auctionator=%s; progressEvents=%s; DBcallback=%s",
        self.version,
        self.db.source,
        self.db.writSource,
        tostring(self.db.scanOnOpen),
        tostring(self.scanner.open),
        tostring(self.scanner.active),
        tostring(self.autoPaused),
        tostring(self.Providers.scan ~= nil),
        tostring(self.Providers.boundScanBus ~= nil),
        tostring(self.Providers.boundAPI ~= nil)
    )
end

function addon:MarketBaseKey()
    -- Realm/faction isolation is deliberately conservative, even where multiple
    -- realms share an AH. Profiles let neutral/different houses be kept separate.
    return table.concat({
        tostring(GetCurrentRegion and GetCurrentRegion() or 0),
        GetNormalizedRealmName() or GetRealmName() or "unknown",
        UnitFactionGroup("player") or "unknown",
        tostring(WOW_PROJECT_ID or 0),
    }, ":")
end

function addon:MarketKey()
    return self:MarketBaseKey() .. ":" .. self.db.profile
end

function addon:UpdateScheduler()
    if self.scanner.active or self.autoDue or self.providerDue then
        frame:SetScript("OnUpdate", function()
            if addon.autoDue and GetTime() >= addon.autoDue then
                addon.autoDue = nil
                addon:AutoScan()
            end
            if addon.providerDue and GetTime() >= addon.providerDue then
                local job = addon.pendingProviderScan
                addon.providerDue, addon.pendingProviderScan = nil, nil
                if job and not addon.scanner.active and addon.scanner.open and addon:MarketKey() == job.market then
                    addon:StartAuctionatorScan(job.items, job.quantities)
                end
            end
            addon.scanner:Tick()
            if not addon.scanner.active and not addon.autoDue and not addon.providerDue then
                frame:SetScript("OnUpdate", nil)
            end
        end)
    else
        frame:SetScript("OnUpdate", nil)
    end
end

-- Automatic scanning is an explicit AH-open preference. Browsing lists,
-- changing a source and receiving bag/item events must never launch queries.
function addon:CanAutoScan(reason)
    return reason == "open"
        and self.db.scanOnOpen
        and not self.autoPaused
        and not self.providerDue
        and self.scanner.open
        and not self.scanner.active
        and not self.Providers.scan
        and (self.db.source == "auto" or self.db.source == "own")
end

function addon:RequestBrowseScan()
    -- Kept for older integrations; tab selection only displays cached prices.
end

function addon:RequestAutoScan(onOpen)
    if not onOpen or not self:CanAutoScan("open") then
        if onOpen then
            self:Trace(
                "auto",
                0,
                "AH-open scan skipped; enabled=%s source=%s paused=%s ownActive=%s external=%s followup=%s",
                tostring(self.db.scanOnOpen),
                self.db.source,
                tostring(self.autoPaused),
                tostring(self.scanner.active),
                tostring(self.Providers.scan ~= nil),
                tostring(self.providerDue ~= nil)
            )
        end
        return
    end
    self.autoReason, self.autoDue = "open", GetTime() + 2
    self:Trace("auto", 0, "AH-open scan scheduled after 2 seconds of quiet")
    self:UpdateScheduler()
end

function addon:AutoScan()
    local reason = self.autoReason
    self.autoReason = nil
    if not self:CanAutoScan(reason) then
        return
    end
    if self.lastExternalAt and GetTime() - self.lastExternalAt < 2 then
        self.autoReason, self.autoDue = reason, self.lastExternalAt + 2
        return
    end
    self.Inventory.CaptureBags()
    local market, items = self:GetMarket(), {}
    for _, itemID in ipairs(self.Catalog.Materials(self.Catalog.AllCrates())) do
        local snapshot = market.items[itemID]
        if not snapshot or market.failures[itemID] or time() - snapshot.scannedAt > self.db.maxAge then
            items[#items + 1] = itemID
        end
    end
    if #items > 0 then
        self:BeginScan(items, reason, "crates")
    else
        self:Trace("auto", 0, "Scan skipped: all material prices are fresh")
    end
end

-- All scopes use one lifecycle and retain which preference governs the work.
function addon:BeginScan(items, jobOrReason, category)
    if self.Providers.scan then
        self:Trace("scan.rejected", 2, "Own scan blocked while Auctionator is scanning")
        return false
    end
    if not self.scanner.open then
        self:Print(L["Open the auction house first."])
        return false
    end
    if self.scanner.active then
        self:Print(L["A scan is already running. Stop it before starting another."])
        return false
    end
    local job = type(jobOrReason) == "table" and jobOrReason or nil
    local reason = type(jobOrReason) == "string" and jobOrReason or "manual"
    self.scanContext = { reason = reason, category = category or (job and job.kind) or "all" }
    self:Trace("scan.request", 0, "reason=%s scope=%s materials=%d", reason, self.scanContext.category, #items)
    self.NativeShopping.pendingQuantity = nil
    self.scanMarket = self:GetMarket()
    self.scanAutomatic, self.scanOnOpen, self.scanBrowser = reason ~= "manual", reason == "open", reason == "browse"
    self.autoPaused, self.autoDue, self.autoReason = false, nil, nil
    self.pendingProviderScan, self.providerDue, self.refreshJob = nil, nil, job
    local ok, message = self.scanner:Start(items)
    if not ok then
        self.refreshJob = nil
        self:Print(message)
    end
    self.UI.Update()
    return ok
end

function addon:StopScan(message)
    self.scanContext = nil
    self.refreshJob, self.pendingProviderScan, self.providerDue = nil, nil, nil
    self.autoPaused, self.autoDue, self.autoReason, self.scanOnOpen, self.scanBrowser = true, nil, nil, false, false
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
            self:StopScan(L["Auction-open scan disabled."])
        elseif enabled then
            self.autoPaused = false
            self:RequestAutoScan(true)
        end
    elseif feature == "auctionatorfollowup" then
        self.db.refreshAuctionator = enabled
        if not enabled then
            self.pendingProviderScan, self.providerDue = nil, nil
        end
        if self.refreshJob then
            self.refreshJob.auctionator = enabled
                and self.db.profile == "default"
                and self.Providers.ShoppingAvailable(true)
        end
    elseif feature == "details" then
        self.db.tooltipDetails = enabled
    else
        local keys = { tracking = "enabled", banks = "bank", alts = "alts", autoscan = "autoScan" }
        self.db.tracking[keys[feature]] = enabled
        if not enabled and (feature == "tracking" or feature == "autoscan") then
            if self.autoReason ~= "open" then
                self.autoDue, self.autoReason = nil, nil
            end
            if self.scanAutomatic and not self.scanOnOpen and not self.scanBrowser then
                self:StopScan(L["Automatic refresh disabled."])
            end
        end
        self.Inventory.CaptureBags()
        self.Inventory.CaptureBank()
        if enabled then
            self.autoPaused = false
        end
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

function addon:ResolveRows(options, source)
    local market = self:GetMarket()
    return self.Pricing.Resolve(
        { options = options },
        market.items,
        time(),
        self.db.maxAge,
        market.failures,
        source,
        function(provider, itemID)
            if self.db.profile ~= "default" then
                return nil
            end
            return self.Providers.Read(provider, itemID)
        end
    )
end

function addon:GetRows(crateID)
    return self:ResolveRows(self.Crates[crateID].options, self.db.source)
end

function addon:SetSource(source)
    if not SOURCES[source] then
        self:Print(L["Use /wll source auto, auctionator, tsm, or own."])
        return
    end
    self.db.source = source
    self:SourceChanged("crates")
end

function addon:SetWritSource(source)
    if not WRIT_SOURCES[source] then
        self:Print(L["Use /wll writsource auto, auctionator, tsm, own, or off."])
        return
    end
    self.db.writSource = source
    self:SourceChanged("writs")
end

function addon:SourceChanged(category)
    local source = self.Shopping.Source(category)
    if source ~= "auto" and source ~= "own" then
        local pendingCategory = self.autoReason == "browse" and self.UI.VisibleBrowserTab()
            or (self.autoReason and "crates")
        if pendingCategory == category then
            self.autoDue, self.autoReason = nil, nil
        end
        if self.scanAutomatic and self.scanContext and self.scanContext.category == category then
            self:StopScan(L["Automatic scan stopped for the selected price source."])
            -- A source change cancels only its category, not the whole AH visit.
            self.autoPaused = false
        end
    end
    self.Providers.Invalidate()
    self.UI.Update()
    self.Tooltip.Refresh()
    self:RequestAutoScan()
    self:RequestBrowseScan()
    self:UpdateScheduler()
end

function addon:SetTSMKey(key)
    local normalized = TSM_KEYS[key:lower()]
    if not normalized then
        self:Print(L["Use /wll tsmkey DBMinBuyout or DBMarket."])
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
        self:Print(L["Hover an identified Waylaid Crate first."])
        return false
    end
    if not self.scanner.open then
        self:Print(L["Open the auction house to shop."])
        return false
    end
    if not optionIndex then
        local _, best = self.Pricing.LowestKnown(self:GetRows(self.lastCrateID))
        optionIndex = best or 1
    end
    if not allOptions and (optionIndex ~= math.floor(optionIndex) or not crate.options[optionIndex]) then
        self:Print(string.format(L["Choose an option between 1 and %d."], #crate.options))
        return false
    end
    local terms, requirements = {}, {}
    for index, option in ipairs(crate.options) do
        if allOptions or index == optionIndex then
            requirements[#requirements + 1] = option
            if self.Providers.ShoppingAvailable() then
                local name = self.Catalog.SearchName(option.itemID)
                if not name then
                    self:Print(L["An item name is still loading. Try the search again in a moment."])
                    return false
                end
                terms[#terms + 1] =
                    { searchString = name, categoryKey = "", isExact = true, quantity = option.quantity }
            end
        end
    end
    if not self.Providers.ShoppingAvailable() then
        if not self.NativeShopping.Available() then
            self:Print(L["The auction house's buying UI is unavailable."])
            return false
        end
        self:StopScan(L["Stopped to open the built-in shopping basket."])
        return self.NativeShopping.Show(requirements, allOptions)
    end
    -- MultiSearchAdvanced starts Auctionator's own query queue. Never run both
    -- scanners concurrently, even if its first query is deferred until later.
    self:StopScan(L["Stopped to hand the search to Auctionator."])
    self.NativeShopping.Close()
    local listName = "Waylaid Ledger - "
        .. self.lastCrateID
        .. (allOptions and " - alternatives" or (" - option " .. optionIndex))
    local ok, reason = self.Providers.Search(terms, listName)
    if not ok then
        self:Print(reason)
        return false
    end
    self:Log("Auctionator handoff: " .. #terms .. " search terms")
    self:Print(
        allOptions and L["Searching all alternatives in Auctionator. Buy only one bundle to fill the crate."]
            or L["Opened the selected bundle in Auctionator. Review the listings before buying."]
    )
    return true
end

function addon:ShopEntry(kind, itemID)
    if not self.scanner.open then
        self:Print(L["Open the auction house to shop."])
        return false
    end
    -- Reprice on click so a stale row cannot select an obsolete filling option.
    local entry = self.Shopping.Entry(kind, itemID)
    if not self.Providers.ShoppingAvailable(true) then
        local requirements, reason = self.Shopping.Requirements(entry)
        if not requirements then
            self:Print(reason)
            return false
        end
        if not self.NativeShopping.Available() then
            self:Print(L["The auction house's buying UI is unavailable."])
            return false
        end
        self:StopScan(L["Stopped to open the built-in shopping basket."])
        local ok, errorMessage = self.NativeShopping.Show(requirements)
        if not ok then
            self:Print(errorMessage)
            return false
        end
        self.lastBasket = entry
        return true
    end
    local terms, reason = self.Shopping.Terms(entry)
    if not terms then
        self:Print(reason)
        return false
    end
    self:StopScan(L["Stopped to hand the complete basket to Auctionator."])
    self.NativeShopping.Close()
    local ok, errorMessage = self.Providers.Search(terms, "Waylaid Ledger - basket - " .. itemID, true)
    if not ok then
        self:Print(errorMessage)
        return false
    end
    self.lastBasket = entry
    self:Log("Basket handoff: " .. kind .. " " .. itemID .. "; " .. #terms .. " search terms")
    return true
end

function addon:ListScope(kind)
    kind = kind or self.db.browserTab or "crates"
    local view = self.BrowseUI.views[kind]
    if view and view.visibleEntries then
        local ids = {}
        for _, entry in ipairs(view.visibleEntries) do
            ids[#ids + 1] = entry.itemID
        end
        return self.Catalog.ScanItems(ids)
    end
    return self.Catalog.ScanItems(self.Catalog.AllContracts(kind))
end

function addon:RefreshPriceProvider(kind)
    if self.db.profile ~= "default" then
        return nil
    end
    local source = self.Shopping.Source(kind or self.db.browserTab or "crates")
    if source == "auto" then
        for _, provider in ipairs({ "auctionator", "tsm" }) do
            if self.Providers.Available(provider) then
                return provider
            end
        end
    elseif (source == "auctionator" or source == "tsm") and self.Providers.Available(source) then
        return source
    end
end

-- nil delegates to own scanning; true/false is a handled provider refresh.
function addon:RefreshProviderPrices(kind)
    local provider = self:RefreshPriceProvider(kind)
    if not provider then
        return nil
    end
    if not self.scanner.open then
        self:Print(L["Open the auction house first."])
        return false
    end
    if self.Providers.scan or self.scanner.active then
        self:Print(self.Providers.scan and L["Another addon is scanning."] or L["Stop the current scan first."])
        return false
    end
    self:StopScan()
    self.Providers.Invalidate()
    self.UI.Update()
    self.Tooltip.Refresh()
    local label = provider == "auctionator" and "Auctionator" or "TSM"
    self:Trace("refresh.provider", 0, "Reloading %s cached prices; no auction query", label)
    self:Print(string.format(L["Reloaded %s cached prices. Run a scan in that addon for newer data."], label))
    return true
end

function addon:RefreshList(view)
    local refreshed = self:RefreshProviderPrices(view and view.kind)
    if refreshed ~= nil then
        return refreshed
    end
    if not self.scanner.open then
        self:Print(L["Open the auction house first."])
        return false
    end
    local kind = view and view.kind or self.db.browserTab or "crates"
    local items, quantities = self:ListScope(kind)
    if #items == 0 then
        self:Print(L["No matching writs or crates to scan."])
        return false
    end
    self:StopScan(L["Starting a new scoped refresh."])
    self.Providers.Invalidate()
    local job = {
        kind = kind,
        items = items,
        quantities = quantities,
        market = self:MarketKey(),
        auctionator = self.db.refreshAuctionator and self.db.profile == "default" and self.Providers.ShoppingAvailable(
            true
        ),
    }
    local ok = self:BeginScan(items, job)
    if ok then
        local source = kind == "writs" and self.db.writSource or self.db.source
        self:Print(
            string.format(
                L["Refreshing %d unique items for the current %s list."],
                #items,
                L[kind == "writs" and L["Craftsman's Writs"] or L["Waylaid Crates"]]
            )
        )
        if source ~= "auto" and source ~= "own" then
            self:Print(L["Select Auto or Own to display our scan results; the selected provider keeps its own data."])
        end
    end
    return ok
end

function addon:StartAuctionatorScan(items, quantities)
    if #items == 0 then
        self:Print(L["No matching items to scan."])
        return false
    end
    if not self.scanner.open then
        self:Print(L["Open the auction house first."])
        return false
    end
    if self.db.profile ~= "default" then
        self:Print(L["Auctionator scans are disabled for custom market profiles."])
        return false
    end
    if not self.Providers.ShoppingAvailable(true) then
        self:Print(L["Auctionator's limited-search API is unavailable."])
        return false
    end
    local terms, reason = self.Providers.ScanTerms(items, quantities)
    if not terms then
        self:Print(reason)
        return false
    end
    self:StopScan(L["Handing the limited item search to Auctionator."])
    local ok, searchReason = self.Providers.Search(terms, "Waylaid Ledger - scoped refresh", true)
    if not ok then
        self:Print(searchReason)
        return false
    end
    self:Print(string.format(L["Started a limited search in Auctionator Shopping (%d items)."], #items))
    return true
end

function addon:ExportTSM(kind)
    local items = self:ListScope(kind)
    if #items == 0 then
        self:Print(L["No matching items to export."])
        return
    end
    local parts = { "group:Waylaid Ledger - " .. (kind or self.db.browserTab or "crates") }
    for _, id in ipairs(items) do
        parts[#parts + 1] = "i:" .. id
    end
    self.UI.ShowReport(
        table.concat(parts, ","),
        L["TSM import - copy, import into a group, then run its Shopping scan"]
    )
    self:Print(
        string.format(L["Exported %d items. Import into TSM and start its group Shopping scan manually."], #items)
    )
end

function addon:StartScan(scope)
    local contracts
    if scope == "all" or scope == "writs" or scope == "crates" then
        contracts = self.Catalog.AllContracts(scope)
    elseif scope == "hovered" then
        local id = self.lastContractID or self.lastCrateID
        contracts = id and { id } or {}
    elseif scope == "tracked" then
        self.Inventory.CaptureBags()
        contracts = self.Inventory.ContractIDs()
    elseif scope == "bags" then
        contracts = self.Catalog.BagContracts()
    else
        self:Print(L["Use /wll scan bags, hovered, tracked, all, crates, or writs."])
        return false
    end
    local items = self.Catalog.ScanItems(contracts)
    return self:BeginScan(items, "manual", scope == "writs" and "writs" or (scope == "crates" and "crates" or "all"))
end

function addon:StartBrowseScan(kind)
    if not self.scanner.open or self.scanner.active then
        self:Print(self.scanner.active and L["Stop the current scan first."] or L["Open the auction house first."])
        return false
    end
    local items = self.Shopping.ScanItems(kind, true)
    if #items == 0 then
        self:Print(L["Choose Auto or Own scans for this category in Settings."])
        return false
    end
    return self:BeginScan(items, "manual", kind)
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
        string.format(
            "Catalog: %d learned crates / %d delivery items; cached: %d; stale after: %ds",
            #self.Catalog.AllCrates(),
            #self.Catalog.Materials(self.Catalog.AllCrates()),
            count,
            self.db.maxAge
        ),
        "Auction API: " .. tostring(C_AuctionHouse and type(C_AuctionHouse.SendSearchQuery)),
        "Modern tooltips: " .. tostring(TooltipDataProcessor ~= nil),
        "Auction house open: " .. tostring(self.scanner.open),
        "Scanner: " .. (self.scanner.message or "Idle"),
        "Debug chat: " .. tostring(self.db.debug == true),
        "Auctionator scan: " .. tostring(self.Providers.scan ~= nil) .. "; progress events: " .. tostring(
            self.Providers.boundScanBus ~= nil
        ) .. "; percent: " .. tostring(self.Providers.scan and self.Providers.scan.percent),
        "Scan scope: " .. tostring(self.scanContext and self.scanContext.category) .. "; reason: " .. tostring(
            self.scanContext and self.scanContext.reason
        ),
        "Last hovered crate: " .. tostring(self.lastCrateID),
        "Writ source: " .. self.db.writSource .. "; last hovered writ: " .. tostring(self.lastWritID),
        string.format(
            "Tracking: enabled=%s banks=%s alts=%s autoRefresh=%s paused=%s",
            tostring(self.db.tracking.enabled),
            tostring(self.db.tracking.bank),
            tostring(self.db.tracking.alts),
            tostring(self.db.tracking.autoScan),
            tostring(self.autoPaused)
        ),
        "AH tab: "
            .. tostring(self.UI.auctionHost ~= nil)
            .. "; active: "
            .. tostring(self.db.browserTab)
            .. "; minimap hidden: "
            .. tostring(self.db.minimap.hide),
        "Last basket: " .. tostring(self.lastBasket and self.lastBasket.itemID) .. "; total: " .. tostring(
            self.lastBasket and self.lastBasket.total
        ),
        "Auctionator after Refresh: " .. tostring(self.db.refreshAuctionator) .. "; pending: " .. tostring(
            self.providerDue ~= nil
        ),
        "Auction-open scan: " .. tostring(self.db.scanOnOpen) .. "; pending reason: " .. tostring(self.autoReason),
        "Scan requests retained in rolling window: " .. #self.scanner.requests,
        "Full-scan cooldown remaining: " .. self.BulkScan.RemainingCooldown(time()) .. "s",
        "Price policy: " .. self.db.source .. "; TSM key: " .. self.db.tsmKey,
        "Auctionator price API: "
            .. tostring(self.Providers.Available("auctionator"))
            .. "; shopping API: "
            .. tostring(self.Providers.ShoppingAvailable())
            .. "; update callback: "
            .. tostring(self.Providers.boundAPI ~= nil),
        "TSM price API: " .. tostring(self.Providers.Available("tsm")),
        "Provider prices enabled for this profile: " .. tostring(self.db.profile == "default"),
        "Auctionator last error: " .. tostring(self.Providers.errors.auctionator),
        "TSM last error: " .. tostring(self.Providers.errors.tsm),
    }
    if rows then
        for _, row in ipairs(rows) do
            lines[#lines + 1] = string.format(
                "  %d x %d %s: %s cost=%s available=%s age=%s error=%s",
                row.quantity,
                row.itemID,
                self.Catalog.ItemName(row.itemID),
                row.status,
                tostring(row.cost),
                tostring(row.available),
                tostring(row.age),
                tostring(row.error)
            )
            lines[#lines + 1] = string.format(
                "    source=%s estimated=%s ageDays=%s stale=%s scanError=%s",
                tostring(row.source),
                tostring(row.estimated),
                tostring(row.ageDays),
                tostring(row.stale),
                tostring(row.scanError)
            )
        end
    end
    lines[#lines + 1] = self.Inventory.Report()
    if self.Providers.scan then
        local scan = self.Providers.scan
        lines[#lines + 1] = string.format(
            "External scan elapsed: %.1fs; last activity: %.1fs ago; ignored discovery events: %d",
            GetTime() - scan.startedAt,
            GetTime() - scan.updatedAt,
            scan.ignoredEvents
        )
    end
    for key, state in pairs(self.traceState or {}) do
        if state.suppressed > 0 then
            lines[#lines + 1] = string.format("Debug messages suppressed since last %s: %d", key, state.suppressed)
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
    elseif command == "refresh" then
        self:RefreshList({ kind = rest ~= "" and rest:lower() or (self.db.browserTab or "crates") })
    elseif command == "auctionscan" then
        local items, quantities = self:ListScope(rest ~= "" and rest:lower() or nil)
        self:StartAuctionatorScan(items, quantities)
    elseif command == "tsmexport" then
        self:ExportTSM(rest ~= "" and rest:lower() or nil)
    elseif command == "source" then
        if rest == "" then
            self:Print(string.format(L["Price source: %s. Options: auto, auctionator, tsm, own."], self.db.source))
        else
            self:SetSource(rest:lower())
        end
    elseif command == "writsource" then
        if rest == "" then
            self:Print(
                string.format(L["Writ source: %s. Options: auto, auctionator, tsm, own, off."], self.db.writSource)
            )
        else
            self:SetWritSource(rest:lower())
        end
    elseif command == "tsmkey" then
        if rest == "" then
            self:Print(string.format(L["TSM source: %s. Options: DBMinBuyout, DBMarket."], self.db.tsmKey))
        else
            self:SetTSMKey(rest)
        end
    elseif command == "search" then
        self:Shop(true)
    elseif command == "shop" then
        if rest ~= "" and not tonumber(rest) then
            self:Print(L["Use /wll shop [option number]."])
        else
            self:Shop(false, tonumber(rest))
        end
    elseif command == "settings" or command == "controls" then
        self.UI.ToggleSettings()
    elseif command == "inventory" then
        self.UI.ShowReport(self.Inventory.Report())
    elseif
        command == "minimap"
        or command == "tracking"
        or command == "banks"
        or command == "alts"
        or command == "autoscan"
        or command == "scanopen"
        or command == "auctionatorfollowup"
        or command == "details"
    then
        rest = rest:lower()
        if rest ~= "on" and rest ~= "off" then
            self:Print(string.format(L["Use /wll %s on or off, or /wll settings."], command))
        else
            self:SetFeature(command, rest == "on")
        end
    elseif command == "stop" then
        self:StopScan()
    elseif command == "debug" then
        rest = rest:lower()
        if rest ~= "" and rest ~= "on" and rest ~= "off" then
            self:Print(string.format(L["Use /wll %s on or off, or /wll settings."], command))
            return
        end
        if rest == "" then
            self.db.debug = not self.db.debug
        else
            self.db.debug = rest == "on"
        end
        self.traceState = nil
        self:Print((self.db.debug and L["Debug logging enabled."] or L["Debug logging disabled."]))
        self:TraceState()
    elseif command == "report" then
        self.UI.ShowReport(self:Report())
    elseif command == "inspect" then
        local itemID = tonumber(rest:match("item:(%d+)") or rest) or self.lastCrateID
        self:Inspect(itemID)
    elseif command == "clear" then
        if self.scanner.active then
            self:StopScan(L["Stopped to clear this market's prices."])
        end
        local market = self:GetMarket()
        market.items, market.failures = {}, {}
        self.Providers.Invalidate()
        self:Print(L["Cached prices cleared for this market profile."])
        self.Tooltip.Refresh()
    elseif command == "market" then
        if rest == "" then
            self:Print(string.format(L["Current profile: %s. Change with /wll market <name>."], self.db.profile))
        elseif #rest <= 40 and rest:match("^[%w_-]+$") then
            self:StopScan(L["Stopped because the market profile changed."])
            self.db.profile = rest
            self.Providers.Invalidate()
            self:Print(string.format(L["Market profile: %s. Scan this auction house to populate its prices."], rest))
            self.Tooltip.Refresh()
        else
            self:Print(L["Use a profile name of 1-40 letters, digits, underscores or hyphens."])
        end
    else
        self:Print(
            "/wll - auction list/settings | scan bags/hovered/crates/writs/all | source auto/auctionator/tsm/own | tsmkey DBMinBuyout/DBMarket"
        )
        self:Print(
            "search | shop [option number] | stop | report | debug [on|off] | inspect [item ID] | market <name> | clear"
        )
        self:Print(
            "writsource auto/own/auctionator/tsm/off | refresh [crates/writs/all] | auctionscan [scope] | tsmexport [scope] | settings | controls | inventory | minimap/tracking/banks/alts/autoscan/scanopen/details on/off | scan tracked"
        )
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
        if type(addon.db.tracking[key]) ~= "boolean" then
            addon.db.tracking[key] = true
        end
    end
    if type(addon.db.refreshAuctionator) ~= "boolean" then
        addon.db.refreshAuctionator = true
    end
    if type(addon.db.scanOnOpen) ~= "boolean" then
        addon.db.scanOnOpen = false
    end
    addon.db.minimap = addon.db.minimap or { angle = 225, hide = false }
    addon.db.minimap.angle = tonumber(addon.db.minimap.angle) or 225
    addon.db.writSource = WRIT_SOURCES[addon.db.writSource] and addon.db.writSource or "auto"
    addon.db.source = SOURCES[addon.db.source] and addon.db.source or "auto"
    addon.db.tsmKey = TSM_KEYS[tostring(addon.db.tsmKey):lower()] or "DBMinBuyout"
    addon.Discovery.Install()
    local api = C_AuctionHouse
    if not api or not api.SendSearchQuery or not api.MakeItemKey then
        addon:Print(L["This client has no supported C_AuctionHouse API. Please send its /dump GetBuildInfo() output."])
        return
    end
    addon.scanner = addon.Scanner.New(api, {
        now = GetTime,
        wallTime = time,
        loadItem = function(id)
            if C_Item and C_Item.RequestLoadItemDataByID then
                C_Item.RequestLoadItemDataByID(id)
            end
        end,
        isEquipment = function(id)
            local getInfo = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
            if not getInfo then
                return nil
            end
            local _, _, _, _, _, classID = getInfo(id)
            if classID == nil then
                return nil
            end
            local classes = Enum and Enum.ItemClass
            return classID == (classes and classes.Weapon or 2) or classID == (classes and classes.Armor or 4)
        end,
    }, {
        saved = function(itemID, snapshot)
            addon.scanMarket.items[itemID] = snapshot
            addon.scanMarket.failures[itemID] = nil
        end,
        failed = function(itemID, reason)
            addon.scanMarket.failures[itemID] = reason
        end,
        log = function(message)
            addon:Log(message)
        end,
        changed = function(scanner)
            addon.UI.Update()
            if not scanner.active then
                addon.scanOnOpen = false
                local job = addon.refreshJob
                addon.refreshJob = nil
                if job and scanner.index > #scanner.queue and job.auctionator and scanner.open then
                    addon.pendingProviderScan, addon.providerDue = job, GetTime() + 0.1
                end
                addon.Tooltip.Refresh()
                if scanner.message and not addon.scanAutomatic then
                    addon:Print(scanner.message)
                end
                if not addon.scanBrowser then
                    addon:RequestBrowseScan()
                end
            end
            addon:UpdateScheduler()
        end,
    })
    addon.Navigation.Install()
    addon.UI.RegisterSettings()
    addon.MinimapButton.Create()
    addon.Inventory.CaptureBags()
    addon.Providers.Install()
    if not addon.Tooltip.Install() then
        addon:Print(L["No supported tooltip hook found. Use /wll report to collect diagnostics."])
    end
    for _, method in ipairs({
        "SendSearchQuery",
        "SendSellSearchQuery",
        "SendBrowseQuery",
        "SearchForItemKeys",
        "ReplicateItems",
        "RequestMoreCommoditySearchResults",
        "RequestMoreItemSearchResults",
    }) do
        if api[method] then
            hooksecurefunc(api, method, function(argument)
                if not addon.scanner.issuing then
                    if method == "ReplicateItems" then
                        addon.Providers.BeginExternalScan("external ReplicateItems hook")
                    end
                    addon.NativeShopping.ExternalQuery(method, argument)
                    addon.lastExternalAt = GetTime()
                    addon:Trace(
                        "external.query",
                        5,
                        "%s; ownActive=%s pendingAuto=%s",
                        method,
                        tostring(addon.scanner.active),
                        tostring(addon.autoReason)
                    )
                    if addon.scanner.active then
                        addon.autoPaused, addon.autoDue, addon.autoReason = true, nil, nil
                    elseif addon.pendingProviderScan then
                        addon.pendingProviderScan, addon.providerDue, addon.autoPaused = nil, nil, true
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
    for _, event in ipairs({
        "AUCTION_HOUSE_SHOW",
        "AUCTION_HOUSE_CLOSED",
        "COMMODITY_SEARCH_RESULTS_UPDATED",
        "COMMODITY_SEARCH_RESULTS_ADDED",
        "ITEM_SEARCH_RESULTS_UPDATED",
        "ITEM_SEARCH_RESULTS_ADDED",
        "AUCTION_HOUSE_THROTTLED_SYSTEM_READY",
        "PLAYER_LOGIN",
        "PLAYER_ENTERING_WORLD",
        "BAG_UPDATE_DELAYED",
        "BANKFRAME_OPENED",
        "BANKFRAME_CLOSED",
        "BANK_TABS_CHANGED",
        "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED",
        "MODIFIER_STATE_CHANGED",
        "PLAYER_LOGOUT",
        "PLAYER_REGEN_ENABLED",
    }) do
        frame:RegisterEvent(event)
    end
    addon.BulkScan.Install(addon.scanner)
    SLASH_WAYLAIDLEDGER1, SLASH_WAYLAIDLEDGER2 = "/wll", "/waylaidledger"
    SlashCmdList.WAYLAIDLEDGER = function(text)
        addon:Command(text)
    end
    addon:Log("Loaded on interface " .. tostring(select(4, GetBuildInfo())))
    addon.initialized = true
    addon:Print(L["Loaded. /wll opens the auction list at the AH, or settings elsewhere."])
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
        elseif
            addon.initialized
            and (argument == "Blizzard_GamepadSmartNavigation" or argument == "Blizzard_GamepadSharedUtility")
        then
            addon.Navigation.Install()
        end
        return
    end
    local scanner = addon.scanner
    if not scanner then
        return
    end
    if event == "AUCTION_HOUSE_SHOW" then
        scanner:SetOpen(true)
        addon:Trace("auction.house", 0, "Opened")
        addon:TraceState()
        addon.autoPaused, addon.autoDue, addon.autoReason = addon.Providers.scan ~= nil, nil, nil
        addon.Inventory.CaptureBags()
        addon.UI.AttachAuction()
        addon.UI.Update()
        addon:RequestAutoScan(true)
        addon:RequestAutoScan()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        addon:Trace("auction.house", 0, "Closed")
        addon.Providers.EndExternalScan("auction house closed")
        addon.autoDue, addon.autoReason, addon.scanOnOpen = nil, nil, false
        addon.refreshJob, addon.pendingProviderScan, addon.providerDue = nil, nil, nil
        scanner:SetOpen(false)
        addon.NativeShopping.Close()
        addon.UI.AuctionClosed()
        addon.UI.Update()
        addon:UpdateScheduler()
    elseif event == "AUCTION_HOUSE_THROTTLED_SYSTEM_READY" then
        scanner:Tick()
    elseif event == "PLAYER_REGEN_ENABLED" then
        addon.Navigation.Install()
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
        if argument == "LSHIFT" or argument == "RSHIFT" then
            addon.Tooltip.Refresh()
        end
    elseif event == "COMMODITY_SEARCH_RESULTS_UPDATED" or event == "COMMODITY_SEARCH_RESULTS_ADDED" then
        addon.NativeShopping.Results(argument)
        scanner:Results("commodity", argument)
    elseif event == "ITEM_SEARCH_RESULTS_UPDATED" or event == "ITEM_SEARCH_RESULTS_ADDED" then
        scanner:Results("item", argument)
    end
end)
