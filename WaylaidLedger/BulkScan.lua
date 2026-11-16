local _, addon = ...
local L = addon.L

-- The same public replication API used by Auctionator's full scan. A snapshot
-- supplies minimum-unit-price estimates, not verified stock or stack outlay.
addon.BulkScan = {}
local BulkScan = addon.BulkScan
local TIMEOUT, BATCH = 30, 250
local BUDGET_MS = 2

function BulkScan.Supported(api)
    return type(api.ReplicateItems) == "function" and type(api.GetNumReplicateItems) == "function"
        and type(api.GetReplicateItemInfo) == "function"
end

function BulkScan.Install(scanner)
    if not BulkScan.Supported(scanner.api) then return end
    local frame = CreateFrame("Frame")
    -- Older versions persisted a guessed replication lockout. Let the client's
    -- readiness signal and the response timeout govern new requests instead.
    addon.db.replication = nil
    local engine = { scanner = scanner, frame = frame }
    BulkScan.engine = engine
    local start, stop, tick = scanner.Start, scanner.Stop, scanner.Tick
    local function redraw()
        scanner:Notify()
        if addon.Tooltip then addon.Tooltip.Refresh() end
    end
    local function updateStatus()
        if addon.BrowseUI then addon.BrowseUI.UpdateScanStatus() end
    end
    local function cancel()
        engine.job = nil
        frame:SetScript("OnUpdate", nil)
        updateStatus()
    end
    local function finish(message)
        local job = engine.job
        if not job then return end
        local own = job.own
        cancel()
        if own then
            scanner.active, scanner.bulkMode = false, false
            scanner.message = message
            scanner:Log(message)
        end
        redraw()
    end
    local function process()
        local job = engine.job
        if not job then return end
        local now = scanner.runtime.now()
        if now - (job.progressAt or job.startedAt) > TIMEOUT then
            -- Preserve completed estimates; never mark absent/partial rows sold out.
            finish(L["Full scan did not complete. Retry when the auction house is idle."])
            return
        end
        if not job.received then return end
        local api = scanner.api
        local limit = math.min(job.index + BATCH, job.count)
        local started = debugprofilestop and debugprofilestop()
        for index = job.index, limit - 1 do
            local ok, info = pcall(function() return { api.GetReplicateItemInfo(index) } end)
            if not ok then finish(string.format(L["Full scan data could not be read: %s"], tostring(info))); return end
            local name, quantity, buyout, itemID = info[1], info[3], info[10], info[17]
            if type(itemID) == "number" and itemID > 0 then
                if not job.seen[itemID] then
                    job.seen[itemID] = true
                    addon.Discovery.Observe(itemID, name)
                end
                if type(quantity) == "number" and quantity > 0 and type(buyout) == "number"
                    and quantity < 1000000000 and quantity == math.floor(quantity)
                    and buyout > 0 and buyout < 9007199254740 then
                    local price = buyout / quantity
                    local old = job.prices[itemID]
                    if not old or price < old then job.prices[itemID] = price end
                end
            end
            job.index = index + 1
            if started and debugprofilestop() - started >= BUDGET_MS then break end
        end
        job.progressAt = now
        if job.index < job.count then
            if job.own then scanner.message = string.format(L["Reading full scan: %d / %d auctions"], job.index, job.count) end
            updateStatus()
            return
        end
        -- Resolve names only after indexing the entire market, so row order does
        -- not make a requirement fail when its goods appear later in the scan.
        addon.Discovery.Retry()
        local count = 0
        for itemID, price in pairs(job.prices) do
            local previous = job.market.items[itemID]
            if not previous or previous.kind == "estimate" or previous.error
                or job.at - previous.scannedAt > addon.db.maxAge or job.market.failures[itemID] then
                job.market.items[itemID] = { kind = "estimate", unitPrice = price, scannedAt = job.at }
                job.market.failures[itemID] = nil
            end
            count = count + 1
        end
        job.market.bulkAt = job.at
        if job.own then scanner.completed = count end
        finish(string.format(L["Full scan finished: %d item prices. Delivery requirements learned from game descriptions."], count))
    end
    local function observe(own)
        engine.job = { own = own, market = addon:GetMarket(), startedAt = scanner.runtime.now(),
            at = scanner.runtime.wallTime(), prices = {}, seen = {}, index = 0 }
        frame:SetScript("OnUpdate", process)
        updateStatus()
    end
    function scanner:Start(itemIDs, detailed)
        if detailed then
            if engine.job then return false, L["Wait for the full scan to finish or stop it first."] end
            self.bulkMode = false
            return start(self, itemIDs)
        end
        if not self.open then return false, L["Open the auction house first."] end
        if self.active or engine.job then return false, L["An auction scan is already running."] end
        -- A bulk refresh must not launch a redundant per-item provider scan.
        addon.refreshJob, addon.pendingProviderScan, addon.providerDue = nil, nil, nil
        self.queue, self.pending, self.index = {}, nil, 1
        self.completed, self.failed, self.active, self.bulkMode = 0, 0, true, true
        self.message = L["Requesting one full auction-house snapshot..."]
        observe(true)
        engine.job.waiting = true
        redraw()
        self:Tick()
        return true
    end
    function scanner:Stop(message)
        self.bulkMode = false
        cancel()
        return stop(self, message)
    end
    function scanner:Tick()
        local job = engine.job
        if not job or not job.own then return tick(self) end
        if job.waiting and self.api.IsThrottledMessageSystemReady() then
            job.waiting = nil
            local ok, reason = self:Send("ReplicateItems")
            if not ok then
                finish(string.format(L["Full scan could not start: %s"], tostring(reason)))
            end
        end
        -- Only the bulk frame processes rows, once per rendered frame. The core
        -- scheduler also calls Tick; doing work here doubles the frame budget.
        if engine.job and self.runtime.now() - (job.progressAt or job.startedAt) > TIMEOUT then
            finish("Full scan did not complete. Retry when the auction house is idle.")
        end
    end
    frame:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
    frame:RegisterEvent("AUCTION_HOUSE_CLOSED")
    frame:SetScript("OnEvent", function(_, event, itemID, success)
        if event == "REPLICATE_ITEM_LIST_UPDATE" then
            local job = engine.job
            if not job or job.received or job.waiting then return end
            local ok, count = pcall(scanner.api.GetNumReplicateItems)
            if not ok or type(count) ~= "number" or count < 0 or count ~= math.floor(count) then
                finish(L["Full scan returned an invalid auction count."])
                return
            end
            job.received, job.count, job.at = true, count, scanner.runtime.wallTime()
            job.progressAt = scanner.runtime.now()
            updateStatus()
        elseif event == "AUCTION_HOUSE_CLOSED" then
            if engine.job and engine.job.own then scanner:Stop(L["Auction house closed; completed prices were kept."])
            else cancel() end
        end
    end)
    local beginScan, refreshList = addon.BeginScan, addon.RefreshList
    local function prepareManual(self, category)
        self.scanMarket, self.scanAutomatic = self:GetMarket(), false
        self.scanOnOpen, self.scanBrowser = false, false
        self.scanContext = { reason = "manual", category = category or "all" }
        self.refreshJob, self.pendingProviderScan, self.providerDue = nil, nil, nil
        self.autoPaused, self.autoDue, self.autoReason = false, nil, nil
        if self.NativeShopping then self.NativeShopping.pendingQuantity = nil end
    end
    local function manualSnapshot(self, category)
        -- A rejected second request must not change an active scan's ownership.
        if scanner.open and not scanner.active and not engine.job then prepareManual(self, category) end
        local ok, reason = scanner:Start({})
        if not ok then self:Print(reason) end
        self.UI.Update()
        return ok
    end
    if beginScan then
        function addon:BeginScan(items, job, category)
            if #items > 0 then return beginScan(self, items, job, category) end
            -- First use has no derived item scope yet; replication discovers it.
            return manualSnapshot(self, category or (type(job) == "table" and job.kind))
        end
    end
    if refreshList then
        function addon:RefreshList(view)
            if view and view.visibleEntries and #view.visibleEntries == 0
                and (next(self.Crates) ~= nil or next(self.Writs) ~= nil) then
                self:Print(L["No matching writs or crates to scan."])
                return false
            end
            self.Providers.Invalidate()
            return manualSnapshot(self, view and view.kind or self.db.browserTab)
        end
    end
    local canAutoScan, autoScan, startScan = addon.CanAutoScan, addon.AutoScan, addon.StartScan
    if canAutoScan then
        function addon:CanAutoScan(reason)
            if engine.job then return false end
            return canAutoScan(self, reason)
        end
    end
    if autoScan then
        function addon:AutoScan()
            -- A first scan must work before any item IDs or requirements exist.
            local reason = self.autoReason
            local needsDiscovery = not self:GetMarket().bulkAt or next(self.Discovery.pending) ~= nil
            if reason and self:CanAutoScan(reason) and needsDiscovery then
                local quiet = reason == "open" and 2 or 1
                if self.lastExternalAt and GetTime() - self.lastExternalAt < quiet then
                    self.autoDue = self.lastExternalAt + quiet
                    return
                end
                self.autoReason, self.autoDue = nil, nil
                self.scanAutomatic, self.scanMarket = true, self:GetMarket()
                self.scanOnOpen, self.scanBrowser = reason == "open", reason == "browse"
                self.scanContext = { reason = reason, category = reason == "browse"
                    and self.UI.VisibleBrowserTab and self.UI.VisibleBrowserTab() or "crates" }
                if self.NativeShopping then self.NativeShopping.pendingQuantity = nil end
                scanner:Start({})
                return
            end
            return autoScan(self)
        end
    end
    if startScan then
        function addon:StartScan(scope)
            if scope == "deep" then
                if scanner.open and not scanner.active and not engine.job then prepareManual(self, "all") end
                local ids, unique = {}, {}
                for _, definitions in ipairs({ self.Crates, self.Writs }) do
                    for id, definition in pairs(definitions) do
                        unique[id] = true
                        for _, requirement in ipairs(definition.requirements or definition.options) do
                            unique[requirement.itemID] = true
                        end
                    end
                end
                for id in pairs(unique) do ids[#ids + 1] = id end
                table.sort(ids)
                local ok, reason = scanner:Start(ids, true)
                if not ok then self:Print(reason) end
                return ok
            end
            return startScan(self, scope)
        end
    end
    -- Passive observation reuses Auctionator's replication response without
    -- reading its private database or starting a competing full scan.
    hooksecurefunc(scanner.api, "ReplicateItems", function()
        if not scanner.issuing then
            cancel()
            observe(false)
        end
    end)
end
