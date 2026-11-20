-- Synthetic catalogs for legacy pricing/UI regressions. They are injected only
-- by the test harness and are not distributed with the addon. No web imports.
local addon = ...
addon.Crates = {
    [248682] = {
        name = "Waylaid Crate: Test Herbs",
        options = {
            { itemID = 2447, quantity = 20 },
            { itemID = 765, quantity = 20 },
            { itemID = 2449, quantity = 20 },
            { itemID = 785, quantity = 20 },
            { itemID = 2450, quantity = 20 },
        },
    },
    [248683] = {
        name = "Waylaid Crate: Test Ore",
        options = {
            { itemID = 2770, quantity = 20 },
            {
                itemID = 2771,
                quantity = 20,
            },
        },
    },
    [248684] = {
        name = "Waylaid Crate: Test Textiles",
        options = { { itemID = 2589, quantity = 7 }, {
            itemID = 2318,
            quantity = 9,
        } },
    },
    [248685] = {
        name = "Waylaid Crate: Test Curiosities",
        options = { { itemID = 800001, quantity = 3 }, { itemID = 800002, quantity = 4 } },
    },
}
addon.MaterialNames = {
    [2447] = "Test Herb A",
    [765] = "Test Herb B",
    [2449] = "Test Herb C",
    [785] = "Test Herb D",
    [2450] = "Test Herb E",
    [2770] = "Copper Ore",
    [2771] = "Tin Ore",
    [2589] = "Test Cloth",
    [2318] = "Test Leather",
    [800001] = "Test Material A",
    [800002] = "Test Material B",
}
local nextID = 810000
for index = 1, 26 do
    local options = {}
    for n = 1, (index <= 7 and 4 or 3) do
        nextID = nextID + 1
        options[n] = { itemID = nextID, quantity = n + 2 }
        addon.MaterialNames[nextID] = "Synthetic Material " .. nextID
    end
    addon.Crates[820000 + index] = { name = "Waylaid Crate: Synthetic " .. index, options = options }
end
addon.Writs = {
    [264050] = {
        name = "Craftsman's Writ: Small Silk Pack",
        questID = 94250,
        requirements = { { itemID = 4245, quantity = 1 } },
    },
    [264037] = {
        name = "Craftsman's Writ: Crafted Solid Shot",
        questID = 94237,
        requirements = { { itemID = 8069, quantity = 200 } },
    },
}
addon.WritMaterialNames = { [4245] = "Small Silk Pack", [8069] = "Crafted Solid Shot" }
for index = 1, 148 do
    local material = index == 1 and 2447 or (index == 2 and 765 or 830000 + index)
    addon.Writs[840000 + index] =
        { name = "Craftsman's Writ: Synthetic " .. index, requirements = { { itemID = material, quantity = 1 } } }
    addon.WritMaterialNames[material] = addon.MaterialNames[material] or ("Synthetic Goods " .. index)
end
