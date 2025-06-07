-- Test script for Inventory module
-- Run this in a turtle to verify inventory management functionality

-- Add module path
package.path = package.path .. ";/turtle/modules/?.lua;/?.lua"

-- Load modules
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Inventory = require("turtle.modules.inventory")
local CONSTANTS = require("shared.constants")

-- Initialize dependencies
Core.init({debug = true})
State.init("test_inventory_state.dat")
Config.init("test_inventory_config.cfg")

-- Test counters
local tests_passed = 0
local tests_failed = 0

-- Helper function for tests
local function test(name, func)
    print("\nTesting: " .. name)
    local success, err = pcall(func)
    if success then
        print("  ✓ PASSED")
        tests_passed = tests_passed + 1
    else
        print("  ✗ FAILED: " .. tostring(err))
        tests_failed = tests_failed + 1
    end
end

-- Mock some turtle functions for testing
local original_getItemDetail = turtle.getItemDetail
local mock_inventory = {}

local function setupMockInventory()
    -- Mock inventory with various items
    mock_inventory = {
        [1] = {name = "minecraft:diamond_pickaxe", count = 1, damage = 100, maxDamage = 1561, displayName = "Diamond Pickaxe"},
        [2] = {name = "minecraft:coal", count = 32, displayName = "Coal"},
        [3] = {name = "minecraft:iron_ore", count = 12, displayName = "Iron Ore"},
        [4] = {name = "minecraft:cobblestone", count = 64, displayName = "Cobblestone"},
        [5] = {name = "minecraft:diamond", count = 3, displayName = "Diamond"},
        [6] = nil, -- Empty slot
        [7] = {name = "minecraft:gravel", count = 20, displayName = "Gravel"},
        [8] = {name = "minecraft:torch", count = 48, displayName = "Torch"},
        [9] = nil, -- Empty slot
        [10] = {name = "minecraft:deepslate_iron_ore", count = 8, displayName = "Deepslate Iron Ore"}
    }
    
    -- Override getItemDetail
    turtle.getItemDetail = function(slot, detailed)
        if slot < 1 or slot > 16 then
            error("Slot out of range: " .. slot)
        end
        return mock_inventory[slot]
    end
end

local function restoreTurtle()
    turtle.getItemDetail = original_getItemDetail
end

-- Clean up any existing files
local function cleanup()
    if fs.exists("test_inventory_state.dat") then
        fs.delete("test_inventory_state.dat")
    end
    if fs.exists("test_inventory_config.cfg") then
        fs.delete("test_inventory_config.cfg")
    end
end

-- Start tests
print("=== Inventory Module Tests ===")
print("Note: Using mock inventory for testing")
print()

-- Test initialization
test("Inventory initialization", function()
    setupMockInventory()
    local success, msg = Inventory.init()
    assert(success, "Inventory init failed: " .. tostring(msg))
    restoreTurtle()
end)

-- Test item classification
test("Item classification", function()
    assert(Inventory.classifyItem("minecraft:diamond_pickaxe") == "tool", "Failed to classify tool")
    assert(Inventory.classifyItem("minecraft:coal") == "fuel", "Failed to classify fuel")
    assert(Inventory.classifyItem("minecraft:iron_ore") == "ore", "Failed to classify ore")
    assert(Inventory.classifyItem("minecraft:cobblestone") == "building", "Failed to classify building")
    assert(Inventory.classifyItem("minecraft:diamond") == "ore", "Failed to classify diamond as ore")
    assert(Inventory.classifyItem("minecraft:gravel") == "building", "Failed to classify gravel")
    assert(Inventory.classifyItem("minecraft:unknown_item") == "junk", "Failed to classify unknown as junk")
end)

-- Test inventory scanning
test("Inventory scanning", function()
    setupMockInventory()
    local inventory = Inventory.scanInventory()
    assert(inventory[1], "Failed to scan slot 1")
    assert(inventory[1].category == "tool", "Failed to categorize pickaxe")
    assert(inventory[2].category == "fuel", "Failed to categorize coal")
    assert(inventory[3].category == "ore", "Failed to categorize iron ore")
    assert(inventory[6] == nil, "Empty slot should be nil")
    restoreTurtle()
end)

-- Test inventory queries
test("Inventory queries", function()
    setupMockInventory()
    Inventory.scanInventory()
    
    -- Test getItemCount
    assert(Inventory.getItemCount("minecraft:coal") == 32, "Incorrect coal count")
    assert(Inventory.getItemCount("minecraft:diamond") == 3, "Incorrect diamond count")
    assert(Inventory.getItemCount("minecraft:not_present") == 0, "Non-existent item should return 0")
    
    -- Test findItem
    local slot, count = Inventory.findItem("minecraft:coal")
    assert(slot == 2, "Failed to find coal in slot 2")
    assert(count == 32, "Incorrect coal count from findItem")
    
    -- Test slot counts
    assert(Inventory.getUsedSlots() == 8, "Incorrect used slot count")
    assert(Inventory.getFreeSlots() == 8, "Incorrect free slot count")
    assert(not Inventory.isFull(), "Inventory should not be full")
    
    restoreTurtle()
end)

-- Test item categorization
test("Get items by category", function()
    setupMockInventory()
    Inventory.scanInventory()
    
    local tools = Inventory.getItemsByCategory("tool")
    assert(tools[1], "Should find tool in slot 1")
    assert(tools[1].name == "minecraft:diamond_pickaxe", "Tool should be diamond pickaxe")
    
    local ores = Inventory.getItemsByCategory("ore")
    local ore_count = 0
    for _, _ in pairs(ores) do
        ore_count = ore_count + 1
    end
    assert(ore_count == 3, "Should find 3 ore stacks (iron ore, diamond, deepslate iron)")
    
    local fuel = Inventory.getItemsByCategory("fuel")
    assert(fuel[2], "Should find fuel in slot 2")
    
    restoreTurtle()
end)

-- Test inventory summary
test("Inventory summary", function()
    setupMockInventory()
    Inventory.scanInventory()
    
    local summary = Inventory.getSummary()
    assert(summary.total_items > 0, "Total items should be greater than 0")
    assert(summary.free_slots == 8, "Should have 8 free slots")
    assert(summary.used_slots == 8, "Should have 8 used slots")
    assert(summary.has_tools == true, "Should detect tools")
    assert(summary.fuel_count == 32, "Should count 32 fuel items")
    assert(summary.categories["ore"], "Should have ore category")
    assert(summary.categories["ore"].count == 23, "Should have 23 ore items total")
    
    restoreTurtle()
end)

-- Test tool checking
test("Tool checking", function()
    setupMockInventory()
    Inventory.scanInventory()
    
    local tools = Inventory.checkTools()
    assert(#tools == 1, "Should find 1 tool")
    assert(tools[1].name == "minecraft:diamond_pickaxe", "Tool should be diamond pickaxe")
    assert(tools[1].slot == 1, "Tool should be in slot 1")
    assert(tools[1].damage == 100, "Tool damage should be 100")
    assert(tools[1].max_damage == 1561, "Tool max damage should be 1561")
    
    local health = tools[1].health
    assert(health and health > 0.9 and health < 1, "Tool health should be between 0.9 and 1")
    
    restoreTurtle()
end)

-- Test with actual turtle inventory (if available)
test("Real inventory operations", function()
    print("  Testing with actual turtle inventory...")
    
    -- Use real turtle functions
    restoreTurtle()
    
    -- Scan real inventory
    local inventory = Inventory.scanInventory()
    print("  Found " .. Inventory.getUsedSlots() .. " used slots")
    
    -- Test finding empty slot
    local empty_slot = Inventory.findEmptySlot()
    if empty_slot then
        print("  Found empty slot: " .. empty_slot)
    else
        print("  No empty slots available")
    end
    
    -- Test summary on real inventory
    local summary = Inventory.getSummary()
    print("  Total items: " .. summary.total_items)
    for category, data in pairs(summary.categories) do
        print("    " .. category .. ": " .. data.count .. " items in " .. data.items .. " slots")
    end
end)

-- Test custom patterns
test("Custom item patterns", function()
    -- Add custom patterns via config
    Config.set("custom_item_patterns", {
        valuable = {"minecraft:nether_star"},
        special = {"minecraft:custom_item", "modded:*_ore"}
    })
    
    -- Reinitialize to load custom patterns
    setupMockInventory()
    Inventory.init()
    
    assert(Inventory.classifyItem("minecraft:nether_star") == "valuable", "Failed to classify custom valuable")
    assert(Inventory.classifyItem("minecraft:custom_item") == "special", "Failed to classify custom special")
    assert(Inventory.classifyItem("modded:copper_ore") == "special", "Failed to match wildcard pattern")
    
    restoreTurtle()
end)

-- Summary
print("\n=== Test Summary ===")
print("Passed: " .. tests_passed)
print("Failed: " .. tests_failed)
print("Total:  " .. (tests_passed + tests_failed))

if tests_failed > 0 then
    print("\nSome tests failed!")
else
    print("\nAll tests passed!")
end

-- Cleanup
cleanup()
restoreTurtle()
Core.shutdown()