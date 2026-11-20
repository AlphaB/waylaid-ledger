local addon, test, equal = ...
local Trips = addon.WritTrips

test("the shortest open delivery order can beat taking the nearest recipient first", function()
    local a, b, c = { point = { x = 7, y = 0 } }, { point = { x = -14, y = 0 } }, { point = { x = 70, y = 0 } }
    local order, seconds = Trips.Walk({ x = 0, y = 0 }, { a, b, c })
    equal(seconds, 14)
    equal(order[1].recipient, b)
    equal(order[2].recipient, a)
    equal(order[3].recipient, c)
    equal(order[1].extra, 4)
    equal(order[2].extra, 0)
    equal(order[3].extra, 10)
end)

test("trip pricing spends shared inventory once and keeps the basket when an addition is unpriceable", function()
    local plan = { count = 0, rep = 0, required = {}, basket = {} }
    local owned = { [264050] = 1, [264037] = 1, [4245] = 1 }
    local function quote(id, count)
        if id == 4245 and count <= 3 then
            return { cost = count * 50, stale = true }
        end
    end
    local first = { itemID = 264050, canShop = true, reward = 75, requirements = { { itemID = 4245, quantity = 2 } } }
    local second = { itemID = 264037, canShop = true, reward = 75, requirements = { { itemID = 4245, quantity = 2 } } }
    equal(Trips.AddWrit(plan, first, owned, quote), true)
    equal(plan.basket[4245].quantity, 1)
    equal(Trips.AddWrit(plan, second, owned, quote), true)
    equal(plan.basket[4245].quantity, 3)
    equal(plan.basket[4245].cost, 150)
    equal(plan.basket[4245].stale, true)
    equal(Trips.AddWrit(plan, first, owned, quote), false)
    equal(plan.basket[4245].quantity, 3)
    equal(plan.count, 2)
    equal(plan.rep, 150)
end)

test("trip recommendations use known local flight stops and skip completed writs", function()
    local oldMap, oldTaxi, oldVector, oldEnum, oldQuest = C_Map, C_TaxiMap, CreateVector2D, Enum, C_QuestLog
    local oldWrits, oldDestinations = addon.Writs, addon.WritDestinations
    CreateVector2D = function(x, y)
        return {
            GetXY = function()
                return x, y
            end,
        }
    end
    Enum = { UIMapType = { Continent = 2 }, FlightPathFaction = { Neutral = 0, Horde = 1, Alliance = 2 } }
    C_Map = {
        GetBestMapForUnit = function()
            return 100
        end,
        GetPlayerMapPosition = function()
            return CreateVector2D(0, 0)
        end,
        GetMapInfo = function(id)
            return { name = "Test Zone", parentMapID = 1, mapType = id == 1 and 2 or 3 }
        end,
        GetWorldPosFromMapPos = function(id, pos)
            local x, y = pos:GetXY()
            return id == 200 and 8 or 0, CreateVector2D(x * 7000, y * 7000)
        end,
    }
    C_TaxiMap = {
        GetTaxiNodesForMap = function(id)
            equal(id, 1)
            return {
                {
                    nodeID = 9,
                    faction = 2,
                    isUndiscovered = false,
                    name = "Departure",
                    position = CreateVector2D(0, 0),
                },
                {
                    nodeID = 4,
                    faction = 0,
                    isUndiscovered = false,
                    name = "Landing",
                    position = CreateVector2D(0.5, 0),
                },
                {
                    nodeID = 1,
                    faction = 0,
                    isUndiscovered = true,
                    name = "Undiscovered",
                    position = CreateVector2D(0.51, 0),
                },
                {
                    nodeID = 2,
                    faction = 1,
                    isUndiscovered = false,
                    name = "Hostile",
                    position = CreateVector2D(0.51, 0),
                },
            }
        end,
    }
    addon.WritDestinations = {
        { name = "First", mapID = 100, x = 0.51, y = 0, writs = { 264037, 264049, 264050, 264086 } },
        { name = "Second", mapID = 100, x = 0.54, y = 0, writs = { 264087 } },
        { name = "Third", mapID = 100, x = 0.59, y = 0, writs = { 264056 } },
        { name = "Local", mapID = 100, x = 0.01, y = 0, writs = { 264011 } },
        { name = "Other continent", mapID = 200, x = 0.51, y = 0, writs = { 264088 } },
        { name = "Too far from a flight stop", mapID = 100, x = 0.8, y = 0, writs = { 264089 } },
    }
    addon.Writs = {
        [264011] = { questID = 94004, requirements = { { itemID = 3391, quantity = 1 } } },
        [264049] = { questID = 94249, requirements = { { itemID = 8069, quantity = 50 } } },
        [264056] = { questID = 94256, requirements = { { itemID = 9624, quantity = 1 } } },
        [264037] = { questID = 94237, requirements = { { itemID = 8069, quantity = 200 } } },
        [264050] = { questID = 94250, requirements = { { itemID = 4245, quantity = 1 } } },
        [264086] = { questID = 94286, requirements = { { itemID = 4852, quantity = 1 } } },
        [264087] = { questID = 94287, requirements = { { itemID = 10500, quantity = 1 } } },
        [264088] = { questID = 94288, requirements = { { itemID = 10514, quantity = 1 } } },
        [264089] = { questID = 94289, requirements = { { itemID = 10498, quantity = 1 } } },
    }
    C_QuestLog = {
        IsQuestFlaggedCompleted = function(id)
            return id == 94250
        end,
    }
    local context = Trips.FlightContext()
    equal(#context.nodes, 2)
    local function quote(id, quantity)
        return { cost = ((id == 264049 or id == 264011) and 1000 or id == 264056 and 5000 or 1) * quantity }
    end
    local owned = { [264086] = 1, [4852] = 1 }
    local plans = Trips.Build(context, owned, quote, 6)
    equal(#plans, 2)
    local plan = plans[1]
    equal(plan.stop.name, "Landing")
    equal(plan.departure.name, "Departure")
    equal(plan.count, 3)
    equal(plan.rep, 325)
    equal(plan.cost, 203)
    equal(plan.order[1].recipient.destination.name, "First")
    equal(plan.order[2].recipient.destination.name, "Second")
    equal(#plan.writs[plan.order[1].recipient], 2)
    assert(math.abs(plan.seconds - 220) < 1e-9)
    equal(#plan.additions, 2)
    equal(plan.additions[1].candidate.itemID, 264049)
    equal(plan.additions[1].candidate.reward, 75)
    equal(plan.additions[1].cost, 1050)
    equal(plan.additions[1].seconds, 10)
    equal(plan.additions[2].candidate.itemID, 264056)
    equal(plan.additions[2].cost, 5001)
    assert(math.abs(plan.additions[2].seconds - 60) < 1e-9)
    local faster = Trips.Build(context, owned, quote, 100)
    equal(faster[1].stop.name, "Departure")
    local report = Trips.Describe(plans, 6)
    assert(report:find("325 rep", 1, true))
    assert(report:find("adds 10 sec", 1, true))
    assert(report:find("adds 40 sec", 1, true))
    assert(report:find("200x Crafted Solid Shot", 1, true))
    assert(report:find("Effective cost per rep", 1, true))
    assert(report:find("extra cost 0g 10s 50c · +10 sec · +75 rep", 1, true))
    C_Map, C_TaxiMap, CreateVector2D, Enum, C_QuestLog = oldMap, oldTaxi, oldVector, oldEnum, oldQuest
    addon.Writs, addon.WritDestinations = oldWrits, oldDestinations
end)

test("effective reputation cost prices time in copper using the player's hourly rate", function()
    equal(Trips.EffectiveCost(30000, 300, 250, 6), 140)
    equal(Trips.EffectiveCost(20000, 1200, 250, 6), 160)
    equal(Trips.EffectiveCost(20000, 1200, 250, 0), 80)
    equal(Trips.ParseGoldPerHour("6,5"), 6.5)
    equal(Trips.ParseGoldPerHour("0"), 0)
    equal(Trips.ParseGoldPerHour("-2"), nil)
    equal(Trips.ParseGoldPerHour("1e99"), nil)
end)
