local _, addon = ...
local L = addon.L
addon.WritTrips = {}
local Trips = addon.WritTrips

-- Straight-line estimates in world yards, with a fixed allowance for each hand-in.
local RUN_SPEED, TAXI_SPEED = 7, 25
local HAND_IN_SECONDS, TAKEOFF_SECONDS = 10, 10
local MAX_WALK_SECONDS, MAX_RECIPIENTS = 180, 8
local DEFAULT_GOLD_PER_HOUR = 6

function Trips.ParseGoldPerHour(value)
    local gold = tonumber(type(value) == "string" and (value:gsub(",", ".")) or value)
    if gold and gold >= 0 and gold <= 1000000 then
        return math.floor(gold * 10000 + 0.5) / 10000
    end
end

function Trips.GoldPerHour()
    return Trips.ParseGoldPerHour(addon.db.tripGoldPerHour) or DEFAULT_GOLD_PER_HOUR
end

function Trips.EffectiveCost(cost, seconds, rep, goldPerHour)
    return (cost + seconds * goldPerHour * 10000 / 3600) / rep
end

local function yards(a, b)
    return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
end

-- Shortest open walk from the landing point through a subset of recipients.
-- Memoization shares work between the full route and leave-one-out estimates.
function Trips.Walk(start, recipients)
    local points, bit, distance, memo, choices = { [0] = start }, {}, {}, {}, {}
    for i, recipient in ipairs(recipients) do
        points[i], bit[i] = recipient.point, 2 ^ (i - 1)
    end
    for i, point in pairs(points) do
        distance[i], memo[i], choices[i] = {}, { [0] = 0 }, {}
        for j, target in ipairs(points) do
            distance[i][j] = yards(point, target) / RUN_SPEED
        end
    end
    local function best(index, remaining)
        if memo[index][remaining] then
            return memo[index][remaining]
        end
        local seconds, nextIndex = math.huge, nil
        for j, flag in ipairs(bit) do
            if remaining % (2 * flag) >= flag then
                local estimate = distance[index][j] + best(j, remaining - flag)
                if estimate < seconds then
                    seconds, nextIndex = estimate, j
                end
            end
        end
        memo[index][remaining], choices[index][remaining] = seconds, nextIndex
        return seconds
    end
    local all = 2 ^ #recipients - 1
    local seconds, order = best(0, all), {}
    local remaining, previous = all, 0
    while remaining > 0 do
        local index = choices[previous][remaining]
        order[#order + 1] = {
            recipient = recipients[index],
            leg = distance[previous][index],
            extra = math.max(0, seconds - best(0, all - bit[index])),
        }
        previous, remaining = index, remaining - bit[index]
    end
    return order, seconds
end

local function worldPoint(mapID, pos)
    if pos then
        local continent, world = C_Map.GetWorldPosFromMapPos(mapID, pos)
        if continent and world then
            local x, y = world:GetXY()
            return { continent = continent, x = x, y = y }
        end
    end
end

local function continentMap(mapID)
    while mapID and mapID > 0 do
        local map = C_Map.GetMapInfo(mapID)
        if not map then
            return
        end
        if map.mapType == Enum.UIMapType.Continent then
            return mapID
        end
        mapID = map.parentMapID
    end
end

local function nearest(point, nodes)
    local index, distance
    for i, node in ipairs(nodes) do
        if point.continent == node.point.continent then
            local candidate = yards(point, node.point)
            if not distance or candidate < distance then
                index, distance = i, candidate
            end
        end
    end
    return index, distance
end

function Trips.FlightContext()
    if not (C_Map and C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap and CreateVector2D and Enum and Enum.UIMapType) then
        return
    end
    local mapID = C_Map.GetBestMapForUnit("player")
    local continent = continentMap(mapID)
    local player = continent and worldPoint(mapID, C_Map.GetPlayerMapPosition(mapID, "player"))
    if not player then
        return
    end
    local faction = UnitFactionGroup("player")
    local flightFactions = Enum.FlightPathFaction
    if not (flightFactions and flightFactions[faction]) then
        return
    end
    local nodes = {}
    for _, node in ipairs(C_TaxiMap.GetTaxiNodesForMap(continent) or {}) do
        if
            node.isUndiscovered == false
            and (node.faction == flightFactions.Neutral or node.faction == flightFactions[faction])
        then
            local point = worldPoint(continent, node.position)
            if point and point.continent == player.continent then
                nodes[#nodes + 1] = { id = node.nodeID, name = node.name, point = point }
            end
        end
    end
    table.sort(nodes, function(a, b)
        return a.id < b.id
    end)
    local departure, distance = nearest(player, nodes)
    if departure then
        return { player = player, faction = faction, nodes = nodes, departure = departure, distance = distance }
    end
end

-- Price the cumulative shopping quantities after subtracting bags once.
-- Reject an addition whose missing goods cannot be priced at that quantity.
function Trips.AddWrit(plan, writ, owned, quote)
    local requests = addon.Shopping.Requirements(writ)
    if not requests then
        return false
    end
    local additions, prices = {}, {}
    for _, item in ipairs(requests) do
        additions[item.itemID] = (additions[item.itemID] or 0) + item.quantity
    end
    for itemID, quantity in pairs(additions) do
        local required = (plan.required[itemID] or 0) + quantity
        local missing = math.max(0, required - (owned[itemID] or 0))
        if missing > 0 then
            local price = quote(itemID, missing)
            if not price then
                return false
            end
            prices[itemID] = { itemID = itemID, quantity = missing, cost = price.cost, stale = price.stale }
        end
    end
    for itemID, quantity in pairs(additions) do
        plan.required[itemID] = (plan.required[itemID] or 0) + quantity
        plan.basket[itemID] = prices[itemID]
    end
    plan.rep = plan.rep + writ.reward
    plan.count = plan.count + 1
    return true
end

local function recipientFor(destination, context)
    if destination.faction and destination.faction ~= context.faction then
        return
    end
    local point = worldPoint(destination.mapID, CreateVector2D(destination.x, destination.y))
    if point then
        local node, distance = nearest(point, context.nodes)
        if node and distance <= MAX_WALK_SECONDS * RUN_SPEED then
            return node, { destination = destination, point = point, distance = distance }
        end
    end
end

local function collect(context)
    local groups = {}
    for _, destination in ipairs(addon.WritDestinations) do
        local node, recipient = recipientFor(destination, context)
        if node then
            groups[node] = groups[node] or {}
            table.insert(groups[node], recipient)
        end
    end
    return groups
end

local function priceReader()
    local byItem = {}
    local source = addon.Shopping.Source("writs")
    return function(itemID, quantity)
        local byQuantity = byItem[itemID] or {}
        byItem[itemID] = byQuantity
        if byQuantity[quantity] == nil then
            local price = addon:ResolveRows({ { itemID = itemID, quantity = quantity } }, source)[1]
            byQuantity[quantity] = price and price.status == "ok" and not price.error and price or false
        end
        return byQuantity[quantity]
    end
end

local function candidatesFor(groups)
    table.sort(groups, function(a, b)
        return a.distance < b.distance or (a.distance == b.distance and a.destination.name < b.destination.name)
    end)
    local recipients, candidates = {}, {}
    for _, recipient in ipairs(groups) do
        local previous = #candidates
        for _, itemID in ipairs(recipient.destination.writs) do
            local writ = addon.Writs[itemID]
            local reward = addon.Rewards.Amount("writs", itemID)
            if
                reward
                and writ
                and not writ.unresolved
                and #writ.requirements > 0
                and not addon.WritPricing.CompletedToday(itemID)
            then
                candidates[#candidates + 1] = {
                    itemID = itemID,
                    requirements = writ.requirements,
                    reward = reward,
                    canShop = true,
                    recipient = recipient,
                    flag = 2 ^ #recipients,
                }
            end
        end
        if #candidates > previous then
            recipients[#recipients + 1] = recipient
            if #recipients == MAX_RECIPIENTS then
                break
            end
        end
    end
    return recipients, candidates
end

local function copy(values)
    local result = {}
    for key, value in pairs(values) do
        result[key] = value
    end
    return result
end

local function contains(mask, flag)
    return mask % (2 * flag) >= flag
end

local function walkReader(start, recipients)
    local cache = {}
    return function(mask)
        if not cache[mask] then
            local visited = {}
            for index, recipient in ipairs(recipients) do
                if contains(mask, 2 ^ (index - 1)) then
                    visited[#visited + 1] = recipient
                end
            end
            local order, seconds = Trips.Walk(start, visited)
            cache[mask] = { order = order, seconds = seconds }
        end
        return cache[mask]
    end
end

local function better(a, b)
    if a.effective ~= b.effective then
        return a.effective < b.effective
    elseif a.rep ~= b.rep then
        return a.rep > b.rep
    elseif a.seconds ~= b.seconds then
        return a.seconds < b.seconds
    end
    return a.cost < b.cost
end

local function recommend(candidates, walk, travel, owned, quote, goldPerHour)
    local plan = { count = 0, rep = 0, cost = 0, seconds = 0, mask = 0, required = {}, basket = {}, chosen = {} }
    while true do
        local best, additions = nil, {}
        for _, candidate in ipairs(candidates) do
            if not plan.chosen[candidate.itemID] then
                local mask = contains(plan.mask, candidate.flag) and plan.mask or plan.mask + candidate.flag
                local localTime = walk(mask).seconds + (plan.count + 1) * HAND_IN_SECONDS
                local trial = {
                    count = plan.count,
                    rep = plan.rep,
                    cost = 0,
                    localTime = localTime,
                    seconds = travel + localTime,
                    mask = mask,
                    required = copy(plan.required),
                    basket = copy(plan.basket),
                }
                local addition = {
                    candidate = candidate,
                    seconds = trial.seconds - plan.seconds,
                    effective = math.huge,
                }
                if Trips.AddWrit(trial, candidate, owned, quote) then
                    for _, item in pairs(trial.basket) do
                        trial.cost = trial.cost + item.cost
                        trial.stale = trial.stale or item.stale
                    end
                    trial.effective = Trips.EffectiveCost(trial.cost, trial.seconds, trial.rep, goldPerHour)
                    addition.cost = trial.cost - plan.cost
                    addition.stale = trial.stale
                    addition.effective =
                        Trips.EffectiveCost(addition.cost, addition.seconds, candidate.reward, goldPerHour)
                    if not best or better(trial, best) then
                        best = trial
                        trial.candidate = candidate
                    end
                end
                additions[#additions + 1] = addition
            end
        end
        if not best or (plan.count > 0 and not better(best, plan)) then
            if plan.count > 0 then
                table.sort(additions, function(a, b)
                    return a.effective < b.effective
                        or (a.effective == b.effective and a.candidate.itemID < b.candidate.itemID)
                end)
                plan.additions = additions
                for _, addition in ipairs(additions) do
                    plan.stale = plan.stale or addition.stale
                end
                return plan
            end
            return
        end
        best.chosen = plan.chosen
        best.chosen[best.candidate.itemID] = best.candidate
        plan = best
    end
end

function Trips.Build(context, owned, quote, goldPerHour)
    local plans = {}
    local departure = context.nodes[context.departure]
    for index, group in pairs(collect(context)) do
        local stop = context.nodes[index]
        local isLocal = index == context.departure
        local departureWalk = isLocal and 0 or context.distance / RUN_SPEED
        local flight = isLocal and 0 or (yards(departure.point, stop.point) / TAXI_SPEED + TAKEOFF_SECONDS)
        local recipients, candidates = candidatesFor(group)
        local walk = walkReader(isLocal and context.player or stop.point, recipients)
        local plan = recommend(candidates, walk, departureWalk + flight, owned, quote, goldPerHour)
        if plan then
            plan.stop, plan.departure, plan.departureWalk, plan.flight = stop, departure, departureWalk, flight
            plan.order = walk(plan.mask).order
            plan.writs = {}
            for _, candidate in ipairs(candidates) do
                if plan.chosen[candidate.itemID] then
                    local recipient = candidate.recipient
                    plan.writs[recipient] = plan.writs[recipient] or {}
                    table.insert(plan.writs[recipient], candidate.itemID)
                end
            end
            plans[#plans + 1] = plan
        end
    end
    table.sort(plans, function(a, b)
        if better(a, b) then
            return true
        elseif better(b, a) then
            return false
        end
        return a.stop.id < b.stop.id
    end)
    return plans
end

local function duration(seconds)
    local rounded = math.ceil(seconds - 1e-9)
    if rounded < 60 then
        return string.format(L["%d sec"], rounded)
    end
    return string.format(L["%d min %d sec"], math.floor(rounded / 60), rounded % 60)
end

function Trips.Describe(plans, goldPerHour)
    local lines = {
        L["Trips are ranked by effective cost per rep, including the value of your time. Check terrain and flight connections."],
        string.format(L["Time value · %s per hour"], addon.Money(math.floor(goldPerHour * 10000 + 0.5))),
        L["Uses saved prices and your bags. Flight fares are separate."],
        L["Add-on estimates compare each writ with the suggested trip on its own."],
    }
    for _, plan in ipairs(plans) do
        lines[#lines + 1] = ""
        lines[#lines + 1] = string.format(
            L["%s · %d writs · %d rep · about %s"],
            plan.stop.name,
            plan.count,
            plan.rep,
            duration(plan.seconds)
        )
        lines[#lines + 1] =
            string.format(L["Effective cost per rep · %s"], addon.Money(math.ceil(plan.effective - 1e-9)))
        if plan.flight > 0 then
            lines[#lines + 1] = string.format(
                L["Run %s to %s, then fly about %s to %s."],
                duration(plan.departureWalk),
                plan.departure.name,
                duration(plan.flight),
                plan.stop.name
            )
        end
        lines[#lines + 1] = string.format(L["Deliveries on foot and hand-ins · %s"], duration(plan.localTime))
        for i, step in ipairs(plan.order) do
            local dest = step.recipient.destination
            local zone = C_Map.GetMapInfo(dest.mapID)
            lines[#lines + 1] = string.format(
                L["%d. %s · %s %s · %s on foot"],
                i,
                dest.name,
                zone and zone.name or plan.stop.name,
                string.format("%.1f, %.1f", 100 * dest.x, 100 * dest.y),
                duration(step.leg)
            )
            local writs = plan.writs[step.recipient]
            for _, id in ipairs(writs) do
                local extra = HAND_IN_SECONDS + (#writs == 1 and step.extra or 0)
                local added = plan.count == 1 and plan.seconds or extra
                lines[#lines + 1] = "    "
                    .. string.format(L["%s · adds %s"], addon.Catalog.ItemName(id), duration(added))
            end
        end
        lines[#lines + 1] = string.format(L["What to buy · %s"], addon.Money(plan.cost))
        if plan.stale then
            lines[#lines + 1] = L["Some saved prices are old."]
        end
        local items = {}
        for _, item in pairs(plan.basket) do
            items[#items + 1] = item
        end
        table.sort(items, function(a, b)
            return a.itemID < b.itemID
        end)
        if #items == 0 then
            lines[#lines + 1] = L["You have everything in your bags."]
        end
        for _, item in ipairs(items) do
            lines[#lines + 1] = string.format(
                "    %dx %s · %s",
                item.quantity,
                addon.Catalog.ItemName(item.itemID),
                addon.Money(item.cost)
            )
        end
        if #plan.additions > 0 then
            lines[#lines + 1] = L["Optional writs"]
            for _, addition in ipairs(plan.additions) do
                local candidate = addition.candidate
                local price = addition.cost and addon.Money(addition.cost) or L["No price"]
                lines[#lines + 1] = "    "
                    .. string.format(
                        L["%s at %s · extra cost %s · +%s · +%d rep"],
                        addon.Catalog.ItemName(candidate.itemID),
                        candidate.recipient.destination.name,
                        price,
                        duration(addition.seconds),
                        candidate.reward
                    )
            end
        end
    end
    return table.concat(lines, "\n")
end

function Trips.Open(view)
    if addon.Providers.scan then
        addon.UI.ShowReport(L["Another addon is scanning."], L["Writ trips"], view)
        return
    end
    local context = Trips.FlightContext()
    local report = L["No discovered flight stops found on your current continent."]
    if context then
        local bags = {}
        for id = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 do
            bags[#bags + 1] = id
        end
        local goldPerHour = Trips.GoldPerHour()
        local plans = Trips.Build(context, addon.Inventory.ReadContainers(bags), priceReader(), goldPerHour)
        report = #plans > 0 and Trips.Describe(plans, goldPerHour)
            or L["No trips found. Refresh writ prices or try another continent."]
    end
    addon.UI.ShowReport(report, L["Writ trips"], view)
end
