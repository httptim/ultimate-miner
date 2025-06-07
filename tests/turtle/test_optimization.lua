-- Tests for Mining Optimization Module
-- Tests ore vein following, Y-level optimization, and efficiency tracking

-- Mock turtle API
local turtle = {
    position = {x = 0, y = 64, z = 0, facing = 0},
    fuel_level = 10000,
    
    forward = function() return true end,
    back = function() return true end,
    up = function() return true end,
    down = function() return true end,
    turnLeft = function() return true end,
    turnRight = function() return true end,
    getFuelLevel = function() return turtle.fuel_level end,
    detect = function() return false end,
    inspect = function() return false end,
    inspectUp = function() return false end,
    inspectDown = function() return false end,
    dig = function() return true end,
    digUp = function() return true end,
    digDown = function() return true end
}
_G.turtle = turtle

-- Mock other globals
_G.os = {
    epoch = function(type) return 1000000 end,
    sleep = function(seconds) end
}
_G.fs = {
    exists = function() return false end,
    open = function() return nil end
}
_G.textutils = {
    serialize = function(data) return tostring(data) end,
    unserialize = function(str) return {} end
}

-- Make sure print is available
if not _G.print then
    _G.print = print
end

-- Load modules
package.path = package.path .. ";/Users/thultz/Desktop/Coding Projects/Minecraft/ultimate-miner/?.lua"
local Optimization = require("turtle.modules.optimization")
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local Mining = require("turtle.modules.mining")
local CONSTANTS = require("shared.constants")

-- Test suite
local tests_run = 0
local tests_passed = 0

local function assert_equals(expected, actual, message)
    tests_run = tests_run + 1
    if expected == actual then
        tests_passed = tests_passed + 1
        print("[PASS] " .. (message or "Test passed"))
    else
        print("[FAIL] " .. (message or "Test failed"))
        print("  Expected: " .. tostring(expected))
        print("  Actual: " .. tostring(actual))
    end
end

local function assert_true(value, message)
    assert_equals(true, value, message)
end

local function assert_false(value, message)
    assert_equals(false, value, message)
end

local function assert_not_nil(value, message)
    tests_run = tests_run + 1
    if value ~= nil then
        tests_passed = tests_passed + 1
        print("[PASS] " .. (message or "Value is not nil"))
    else
        print("[FAIL] " .. (message or "Value is nil"))
    end
end

local function assert_in_range(value, min, max, message)
    tests_run = tests_run + 1
    if value >= min and value <= max then
        tests_passed = tests_passed + 1
        print("[PASS] " .. (message or "Value in range"))
    else
        print("[FAIL] " .. (message or "Value out of range"))
        print("  Value: " .. tostring(value))
        print("  Expected range: " .. min .. " to " .. max)
    end
end

-- Initialize modules
print("=== Mining Optimization Tests ===")
print()

Core.init({debug = false})
State.init()
Config.init()
Navigation.init({skip_gps = true})
Mining.init()
Optimization.init()

-- Test Y-Level Optimization
print("Testing Y-Level Optimization...")

-- Test 1: Get optimal Y for diamond
local optimal_y, ore_data = Optimization.getOptimalYLevel("diamond")
assert_equals(-59, optimal_y, "Diamond optimal Y should be -59")
assert_not_nil(ore_data, "Should return ore data")
assert_equals(-64, ore_data.range.min, "Diamond min Y should be -64")
assert_equals(16, ore_data.range.max, "Diamond max Y should be 16")

-- Test 2: Get optimal Y for iron
optimal_y, ore_data = Optimization.getOptimalYLevel("iron")
assert_equals(16, optimal_y, "Iron optimal Y should be 16")

-- Test 3: Check if Y level is optimal
local is_optimal, status = Optimization.isYLevelOptimal("diamond", -59, 5)
assert_true(is_optimal, "Y -59 should be optimal for diamond")
assert_equals("peak", status, "Should be in peak range")

-- Test 4: Check suboptimal Y level
is_optimal, status = Optimization.isYLevelOptimal("diamond", 0, 5)
assert_false(is_optimal, "Y 0 should be suboptimal for diamond")
assert_equals("suboptimal", status, "Should be suboptimal")

-- Test 5: Check out of range Y level
is_optimal, status = Optimization.isYLevelOptimal("diamond", 50, 5)
assert_false(is_optimal, "Y 50 should be out of range for diamond")
assert_equals("out_of_range", status, "Should be out of range")

-- Test Multi-Ore Y Level Calculation
print("\nTesting Multi-Ore Y Level Calculation...")

-- Test 6: Calculate best Y for diamond and redstone
local best_y = Optimization.calculateBestYLevel({"diamond", "redstone"})
assert_in_range(best_y, -63, -55, "Best Y for diamond/redstone should be around -59")

-- Test 7: Calculate best Y for coal and iron
best_y = Optimization.calculateBestYLevel({"coal", "iron"})
assert_in_range(best_y, 0, 96, "Best Y for coal/iron should be in mid range")

-- Test Pattern Recommendations
print("\nTesting Pattern Recommendations...")

-- Test 8: Recommendations for diamond mining
local recommendations = Optimization.recommendPattern({ore_type = "diamond"})
assert_not_nil(recommendations, "Should return recommendations")
assert_true(#recommendations > 0, "Should have at least one recommendation")
assert_equals("branch", recommendations[1].pattern, "Should recommend branch for diamond")

-- Test 9: Recommendations for area clearing
recommendations = Optimization.recommendPattern({area = true})
assert_true(#recommendations > 0, "Should have recommendations for area")
local has_quarry = false
for _, rec in ipairs(recommendations) do
    if rec.pattern == "quarry" then
        has_quarry = true
        break
    end
end
assert_true(has_quarry, "Should recommend quarry for area clearing")

-- Test Pattern Efficiency Tracking
print("\nTesting Pattern Efficiency Tracking...")

-- Test 10: Track pattern efficiency
local efficiency = Optimization.trackPatternEfficiency("test_pattern", {
    blocks_mined = 100,
    ores_found = 5,
    fuel_used = 150,
    time_elapsed = 300
})
assert_not_nil(efficiency, "Should return efficiency data")
assert_equals(5, efficiency.ore_percentage, "Should calculate 5% ore rate")
assert_equals(30, efficiency.fuel_per_ore, "Should calculate 30 fuel per ore")

-- Test 11: Track multiple runs
efficiency = Optimization.trackPatternEfficiency("test_pattern", {
    blocks_mined = 200,
    ores_found = 15,
    fuel_used = 250,
    time_elapsed = 400
})
assert_true(efficiency.ore_percentage > 5, "Efficiency should improve with better run")

-- Test Ore Vein Following
print("\nTesting Ore Vein Following...")

-- Test 12: Basic vein following
Navigation.setPosition({x = 0, y = -59, z = 0, facing = 0})

-- Mock ore vein
local ore_positions = {
    {x = 0, y = -59, z = 1, has_ore = true},
    {x = 0, y = -59, z = 2, has_ore = true},
    {x = 1, y = -59, z = 2, has_ore = true},
    {x = 1, y = -58, z = 2, has_ore = true}
}

local inspect_count = 0
Mining.inspect = function(direction)
    inspect_count = inspect_count + 1
    
    -- Simulate finding ores based on position
    local current = Navigation.getPosition()
    for _, ore_pos in ipairs(ore_positions) do
        local match = false
        
        if direction == "forward" and 
           current.x == ore_pos.x and 
           current.y == ore_pos.y and 
           current.z == ore_pos.z - 1 then
            match = true
        elseif direction == "up" and
               current.x == ore_pos.x and
               current.y == ore_pos.y - 1 and
               current.z == ore_pos.z then
            match = true
        end
        
        if match and ore_pos.has_ore then
            return true, {
                name = "minecraft:diamond_ore",
                is_ore = true,
                ore_type = "diamond"
            }
        end
    end
    
    return false
end

local success, vein_data = Optimization.followOreVein("diamond", {
    max_blocks = 10,
    search_radius = 1
})
assert_true(success, "Vein following should succeed")
assert_not_nil(vein_data, "Should return vein data")
assert_true(vein_data.blocks_mined > 0, "Should mine some blocks")

-- Test Ore Prediction
print("\nTesting Ore Prediction...")

-- Test 13: Predict ore locations
local predictions = Optimization.predictOreLocations(
    {x = 0, y = -59, z = 0},
    "diamond",
    16
)
assert_not_nil(predictions, "Should return predictions")

-- Test Pattern Adjustment
print("\nTesting Pattern Adjustment...")

-- Test 14: Adjust pattern based on low ore density
local adjustments = Optimization.adjustPattern(
    {type = "strip", spacing = 3},
    {blocks_mined = 100, ores_found = 1, fuel_used = 100, distance_traveled = 100}
)
assert_not_nil(adjustments, "Should return adjustments")
assert_true(adjustments.spacing > 3, "Should increase spacing for low density")

-- Test 15: Adjust pattern based on high ore density
adjustments = Optimization.adjustPattern(
    {type = "strip", spacing = 3},
    {blocks_mined = 100, ores_found = 10, fuel_used = 100, distance_traveled = 100}
)
assert_true(adjustments.spacing < 3, "Should decrease spacing for high density")
assert_true(adjustments.vein_follow, "Should enable vein following")

-- Test Optimization Statistics
print("\nTesting Optimization Statistics...")

-- Test 16: Get optimization stats
local stats = Optimization.getStats()
assert_not_nil(stats, "Should return statistics")
assert_not_nil(stats.y_level_analysis, "Should have Y level analysis")
assert_not_nil(stats.pattern_rankings, "Should have pattern rankings")
assert_true(stats.total_veins_tracked >= 0, "Should track vein count")

-- Test 17: Y level analysis content
assert_not_nil(stats.y_level_analysis.diamond, "Should have diamond analysis")
assert_equals(-59, stats.y_level_analysis.diamond.optimal, "Diamond optimal should be -59")

-- Test Clear Data
print("\nTesting Clear Data...")

-- Test 18: Clear optimization data
local cleared = Optimization.clearData()
assert_true(cleared, "Should clear data successfully")

stats = Optimization.getStats()
assert_equals(0, stats.total_veins_tracked, "Should have no tracked veins after clear")

-- Test Edge Cases
print("\nTesting Edge Cases...")

-- Test 19: Unknown ore type
optimal_y = Optimization.getOptimalYLevel("unknown_ore")
assert_equals(0, optimal_y, "Unknown ore should default to Y 0")

-- Test 20: Empty ore type list
best_y = Optimization.calculateBestYLevel({})
assert_equals(0, best_y, "Empty ore list should default to Y 0")

-- Summary
print()
print("=== Test Summary ===")
print(string.format("Tests run: %d", tests_run))
print(string.format("Tests passed: %d", tests_passed))
print(string.format("Tests failed: %d", tests_run - tests_passed))
print(string.format("Success rate: %.1f%%", (tests_passed / tests_run) * 100))

if tests_passed == tests_run then
    print("\nAll tests passed!")
else
    print("\nSome tests failed!")
end