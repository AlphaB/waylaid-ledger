local _, addon = ...

-- Base repeatable rewards, researched on Wowhead on 2026-11-16, with the
-- user-selected 30 Favor reward for all Artisan crates.
-- This metadata never adds items to the discovered delivery catalog.
-- Sources and reward assumptions: docs/REWARDS.md.
addon.Rewards = {}
local Rewards = addon.Rewards

local favor = {
    [248682] = 5,
    [248683] = 5,
    [248684] = 5,
    [248685] = 5,
    [248686] = 10,
    [248687] = 10,
    [248688] = 10,
    [248689] = 10,
    -- Earthly and Flowering Expert herbs have the same base reward.
    [248690] = 15,
    [248691] = 15,
    [248692] = 15,
    [248693] = 15,
    [248694] = 15,
    -- User-selected Artisan reward, including Earthly and Flowering herbs.
    [248695] = 30,
    [248696] = 30,
    [248697] = 30,
    [248698] = 30,
    [248699] = 30,
    -- Fabrics, Ingots and Parts produce the higher-reward sealed crate.
    [248702] = 10,
    [248703] = 10,
    [248704] = 10,
    [248705] = 20,
    [248706] = 20,
    [248707] = 20,
    [248708] = 30,
    [248709] = 30,
    [248710] = 30,
    [248711] = 30,
    [248712] = 30,
    [248713] = 30,
}

local reputation = {}
-- These bounded groups cover all 150 individually matched entries in the
-- Wowhead writ guide. Do not extrapolate rewards to IDs outside these groups.
for id = 264011, 264055 do
    reputation[id] = 75
end
for id = 264056, 264115 do
    reputation[id] = 125
end
for id = 264116, 264160 do
    reputation[id] = 200
end

function Rewards.Amount(kind, itemID)
    if kind == "crates" then
        return favor[itemID]
    end
    if kind == "writs" then
        return reputation[itemID]
    end
end

function Rewards.UnitCost(total, reward)
    if total ~= nil and reward and reward > 0 then
        return total / reward
    end
end
