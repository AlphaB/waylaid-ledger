local _, addon = ...

-- Event-driven, single-flight auction scanner. Injected dependencies keep its
-- state machine testable without a game client or network connection.
addon.Scanner = {}
local Scanner = addon.Scanner
Scanner.__index = Scanner

local INTERVAL = 0.05 -- Courtesy gap only; server readiness gates every request.
local WINDOW = 60.1
local REQUEST_LIMIT = 100 -- Rolling window, retained across stop/restart and external queries.
local RESPONSE_TIMEOUT = 15
local JOB_TIMEOUT = 90

function Scanner.New(api, runtime, callbacks)
    return setmetatable({
        api = api,
        runtime = runtime,
        callbacks = callbacks,
        active = false,
        open = false,
        nextSend = 0,
        requests = {},
    }, Scanner)
end

function Scanner:Notify()
    if self.callbacks.changed then
        self.callbacks.changed(self)
    end
end

function Scanner:Log(message)
    if self.callbacks.log then
        self.callbacks.log(message)
    end
end

function Scanner:SetOpen(open)
    self.open = open
    if open and not self.active then
        self.message = "Auction house open. Ready to scan."
    end
    if not open then
        self:Stop("Auction house closed; completed prices were kept.")
    end
end

function Scanner:Start(itemIDs)
    if not self.open then
        return false, "Open the auction house first."
    end
    if self.active then
        return false, "A scan is already running. Stop it before starting another."
    end
    if #itemIDs == 0 then
        return false, "No matching writs or crates to scan."
    end
    self.queue, self.index, self.completed, self.failed = {}, 1, 0, 0
    local seen = {}
    for _, itemID in ipairs(itemIDs) do
        if not seen[itemID] then
            seen[itemID] = true
            self.queue[#self.queue + 1] = itemID
        end
    end
    self.active, self.pending, self.message = true, nil, "Scanning..."
    self:Log("Start scan: " .. #self.queue .. " materials")
    self:Notify()
    self:Tick()
    return true
end

function Scanner:Stop(message)
    if not self.active then
        return
    end
    self.active, self.pending = false, nil
    self.message = message or "Scan stopped; completed prices were kept."
    self:Log(self.message)
    self:Notify()
end

function Scanner:ExternalQuery()
    if self.issuing then
        return
    end
    self:RecordRequest()
    if self.active then
        self:Stop("Scan stopped because another auction search started. Scan again when the auction house is idle.")
    end
end

function Scanner:Fail(reason)
    local pending = self.pending
    self.failed = self.failed + 1
    self:Log("Item " .. pending.itemID .. ": " .. reason)
    if self.callbacks.failed then
        self.callbacks.failed(pending.itemID, reason)
    end
    self:Advance()
end

function Scanner:Advance()
    self.index, self.pending = self.index + 1, nil
    if self.index > #self.queue then
        self.active = false
        self.message = string.format("Scan finished: %d materials updated, %d failed.", self.completed, self.failed)
        self:Log(self.message)
    end
    self:Notify()
end

function Scanner:BudgetReady(now)
    while self.requests[1] and now - self.requests[1] >= WINDOW do
        table.remove(self.requests, 1)
    end
    return #self.requests < REQUEST_LIMIT
end

function Scanner:RecordRequest()
    local now = self.runtime.now()
    self:BudgetReady(now)
    self.requests[#self.requests + 1] = now
end

function Scanner:Send(method, argument, ...)
    self:RecordRequest()
    self.nextSend = self.runtime.now() + INTERVAL
    self.issuing = true
    local ok, result = pcall(self.api[method], argument, ...)
    self.issuing = false
    if not ok then
        self:Log(method .. " failed: " .. tostring(result))
        return false, tostring(result)
    end
    return true
end

function Scanner:Tick()
    if not self.active then
        return
    end
    local now = self.runtime.now()
    if not self.pending then
        local itemID = self.queue[self.index]
        self.pending = {
            itemID = itemID,
            key = self.api.MakeItemKey(itemID),
            startedAt = now,
            attempt = 1,
            action = "search",
        }
    end
    local pending = self.pending
    if now - pending.startedAt > JOB_TIMEOUT then
        self:Fail("Timed out waiting for auction data or server throttle.")
        return
    end
    if pending.sentAt and now - pending.sentAt > RESPONSE_TIMEOUT then
        if pending.attempt < 2 then
            pending.attempt, pending.action, pending.sentAt = 2, "search", nil
            pending.kind = nil
            self:Log("Retry item " .. pending.itemID)
        else
            self:Fail("No complete response after retry.")
            return
        end
    end
    if
        not pending.action
        or now < self.nextSend
        or not self:BudgetReady(now)
        or not self.api.IsThrottledMessageSystemReady()
    then
        return
    end
    local action = pending.action
    if action == "search" and (self.api.GetItemKeyInfo or self.runtime.isEquipment) and not pending.infoChecked then
        local ok, info = true, nil
        if self.api.GetItemKeyInfo then
            ok, info = pcall(self.api.GetItemKeyInfo, pending.key)
        end
        if not ok then
            self:Fail("Could not read item classification: " .. tostring(info))
            return
        end
        if not info and self.runtime.isEquipment then
            local classified, equipment = pcall(self.runtime.isEquipment, pending.itemID)
            if not classified then
                self:Fail("Could not classify item: " .. tostring(equipment))
                return
            end
            if equipment ~= nil then
                info = { isEquipment = equipment }
            end
        end
        if not info then
            if not pending.metadataRequested and self.runtime.loadItem then
                self.runtime.loadItem(pending.itemID)
                pending.metadataRequested = true
            end
            return -- Wait for classification; do not mistake unqueried gear for sold out.
        end
        pending.infoChecked = true
        pending.searchMethod = info.isEquipment and "SendSellSearchQuery" or "SendSearchQuery"
        if not self.api[pending.searchMethod] then
            self:Fail("Required equipment search API unavailable.")
            return
        end
    end
    -- Set the state before sending: event callbacks may run synchronously.
    pending.action, pending.sentAt = nil, now
    local ok, errorMessage
    if action == "search" then
        ok, errorMessage = self:Send(pending.searchMethod or "SendSearchQuery", pending.key, {}, true)
    elseif pending.kind == "commodity" then
        ok, errorMessage = self:Send("RequestMoreCommoditySearchResults", pending.itemID)
    else
        ok, errorMessage = self:Send("RequestMoreItemSearchResults", pending.key)
    end
    if not ok and self.pending == pending then
        self:Fail(errorMessage)
    end
end

function Scanner:ReadSnapshot(kind)
    local pending, offers = self.pending, {}
    if kind == "commodity" then
        for index = 1, self.api.GetNumCommoditySearchResults(pending.itemID) do
            local row = self.api.GetCommoditySearchResultInfo(pending.itemID, index)
            if not row then
                return nil, "Incomplete commodity row."
            end
            if row.itemID and row.itemID ~= pending.itemID then
                return nil, "Commodity response item mismatch."
            end
            -- Mixed account-owned price buckets do not expose a separate account
            -- quantity. Exclude that whole bucket conservatively rather than
            -- advertise stock the player cannot purchase.
            local quantity = math.max(0, row.quantity - (row.numOwnerItems or 0))
            if row.containsAccountItem then
                quantity = 0
            end
            if quantity > 0 and row.unitPrice and row.unitPrice > 0 then
                offers[#offers + 1] = { quantity = quantity, unitPrice = row.unitPrice }
            end
        end
        table.sort(offers, function(a, b)
            return a.unitPrice < b.unitPrice
        end)
    else
        local seen = {}
        for index = 1, self.api.GetNumItemSearchResults(pending.key) do
            local row = self.api.GetItemSearchResultInfo(pending.key, index)
            if not row then
                return nil, "Incomplete item row."
            end
            if row.itemKey.itemID ~= pending.itemID then
                return nil, "Auction response item mismatch."
            end
            if
                not seen[row.auctionID]
                and not row.containsOwnerItem
                and not row.containsAccountItem
                and row.buyoutAmount
                and row.buyoutAmount > 0
                and row.quantity > 0
            then
                seen[row.auctionID] = true
                offers[#offers + 1] = { quantity = row.quantity, buyoutAmount = row.buyoutAmount }
            end
        end
    end
    return { kind = kind, offers = offers, scannedAt = self.runtime.wallTime() }
end

function Scanner:Results(kind, item)
    local pending = self.pending
    if not self.active or not pending or not pending.sentAt then
        return
    end
    local itemID = type(item) == "table" and item.itemID or item
    if itemID ~= pending.itemID then
        return -- Late/unrelated events must never populate the current item.
    end
    if
        type(item) == "table"
        and (
            (item.itemLevel or 0) ~= (pending.key.itemLevel or 0)
            or (item.itemSuffix or 0) ~= (pending.key.itemSuffix or 0)
            or (item.battlePetSpeciesID or 0) ~= (pending.key.battlePetSpeciesID or 0)
        )
    then
        return
    end
    local full
    if kind == "commodity" then
        full = self.api.HasFullCommoditySearchResults(pending.itemID)
    else
        full = self.api.HasFullItemSearchResults(pending.key)
    end
    pending.kind = kind
    if not full then
        -- More than one event may describe a page; queue only one next request.
        pending.action, pending.sentAt = "more", nil
        return
    end
    local snapshot, errorMessage = self:ReadSnapshot(kind)
    if not snapshot then
        self:Fail(errorMessage)
        return
    end
    self.callbacks.saved(pending.itemID, snapshot)
    self.completed = self.completed + 1
    self:Log("Item " .. pending.itemID .. ": " .. #snapshot.offers .. " buyable price rows")
    self:Advance()
end
