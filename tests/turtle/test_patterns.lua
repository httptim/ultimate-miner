-- Tests for Mining Patterns Module
-- Tests all mining patterns and their configurations

-- Mock turtle API
local turtle = {
    position = {x = 0, y = 64, z = 0, facing = 0},
    fuel_level = 10000,
    inventory = {},
    selected_slot = 1,
    
    forward = function() 
        turtle.position.z = turtle.position.z + 1
        turtle.fuel_level = turtle.fuel_level - 1
        return true 
    end,
    back = function() 
        turtle.position.z = turtle.position.z - 1
        turtle.fuel_level = turtle.fuel_level - 1
        return true 
    end,
    up = function() 
        turtle.position.y = turtle.position.y + 1
        turtle.fuel_level = turtle.fuel_level - 1
        return true 
    end,
    down = function() 
        turtle.position.y = turtle.position.y - 1
        turtle.fuel_level = turtle.fuel_level - 1
        return true 
    end,
    turnLeft = function() 
        turtle.position.facing = (turtle.position.facing - 1) % 4
        return true 
    end,
    turnRight = function() 
        turtle.position.facing = (turtle.position.facing + 1) % 4
        return true 
    end,
    getFuelLevel = function() return turtle.fuel_level end,
    getFuelLimit = function() return 20000 end,
    detect = function() return false end,
    detectUp = function() return false end,
    detectDown = function() return false end,
    inspect = function() return false end,
    inspectUp = function() return false end,
    inspectDown = function() return false end,
    dig = function() return true end,
    digUp = function() return true end,
    digDown = function() return true end,
    place = function() return true end,
    placeUp = function() return true end,
    placeDown = function() return true end,
    select = function(slot) 
        turtle.selected_slot = slot
        return true 
    end,
    getSelectedSlot = function() return turtle.selected_slot end,
    getItemDetail = function(slot)
        slot = slot or turtle.selected_slot
        return turtle.inventory[slot]
    end,
    getItemCount = function(slot)
        slot = slot or turtle.selected_slot
        if turtle.inventory[slot] then
            return turtle.inventory[slot].count or 0
        end
        return 0
    end,
    getItemSpace = function(slot)
        return 64
    end,
    drop = function() return true end,
    refuel = function() return true end,
    transferTo = function() return true end
}
_G.turtle = turtle

-- Mock other globals
_G.os = {
    epoch = function(type) return 1000000 end,
    sleep = function(seconds) end,
    pullEvent = function() end
}
_G.fs = {
    exists = function() return false end,
    open = function() return nil end,
    makeDir = function() return true end,
    getDir = function(path) return "" end
}
_G.textutils = {
    serialize = function(data) return tostring(data) end,
    unserialize = function(str) return {} end
}
_G.peripheral = {
    find = function() return nil end
}

-- Make sure print is available
if not _G.print then
    _G.print = print
end

-- Load modules
package.path = package.path .. ";/Users/thultz/Desktop/Coding Projects/Minecraft/ultimate-miner/?.lua"
local Patterns = require("turtle.modules.patterns")
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local Mining = require("turtle.modules.mining")
local Inventory = require("turtle.modules.inventory")
local Safety = require("turtle.modules.safety")

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

-- Initialize modules
print("=== Mining Patterns Tests ===")
print()

Core.init({debug = false})
State.init()
Config.init()
Navigation.init({skip_gps = true})
Mining.init()
Inventory.init()
Safety.init()
Patterns.init()

-- Test Pattern Availability
print("Testing Pattern Availability...")

-- Test 1: Get available patterns
local patterns = Patterns.getAvailablePatterns()
assert_not_nil(patterns, "Should return patterns list")
assert_true(#patterns >= 6, "Should have at least 6 patterns")

-- Test 2: Check pattern types
local pattern_types = {}
for _, pattern in ipairs(patterns) do
    pattern_types[pattern.type] = true
end

assert_true(pattern_types["strip"], "Should have strip pattern")
assert_true(pattern_types["branch"], "Should have branch pattern")
assert_true(pattern_types["spiral"], "Should have spiral pattern")
assert_true(pattern_types["quarry"], "Should have quarry pattern")
assert_true(pattern_types["tunnel_3x3"], "Should have 3x3 tunnel pattern")
assert_true(pattern_types["adaptive"], "Should have adaptive pattern")

-- Test Strip Mining Pattern
print("\nTesting Strip Mining Pattern...")

-- Test 3: Basic strip mining
turtle.position = {x = 0, y = 64, z = 0, facing = 0}
turtle.fuel_level = 1000
turtle.inventory[1] = {name = "minecraft:torch", count = 64}

local success = Patterns.execute("strip", {
    length = 10,
    spacing = 3,
    strips = 2,
    torch_interval = 5,
    return_home = false
})
assert_true(success, "Strip mining should execute successfully")

-- Test 4: Get pattern statistics
local stats = Patterns.getStats()
assert_not_nil(stats, "Should return pattern statistics")
assert_true(stats.total_blocks > 0, "Should have mined blocks")
assert_equals("strip", stats.current_pattern, "Current pattern should be strip")

-- Test Branch Mining Pattern
print("\nTesting Branch Mining Pattern...")

-- Test 5: Basic branch mining
turtle.position = {x = 0, y = 64, z = 0, facing = 0}
turtle.fuel_level = 2000

success = Patterns.execute("branch", {
    main_length = 20,
    branch_length = 5,
    branch_spacing = 10,
    torch_interval = 8,
    return_home = false
})
assert_true(success, "Branch mining should execute successfully")

-- Test Spiral Mining Pattern
print("\nTesting Spiral Mining Pattern...")

-- Test 6: Basic spiral mining
turtle.position = {x = 0, y = 64, z = 0, facing = 0}
turtle.fuel_level = 2000

success = Patterns.execute("spiral", {
    max_radius = 5,
    layers = 1,
    torch_interval = 8,
    return_home = false
})
assert_true(success, "Spiral mining should execute successfully")

-- Test Quarry Pattern
print("\nTesting Quarry Pattern...")

-- Test 7: Small quarry
turtle.position = {x = 0, y = 64, z = 0, facing = 0}
turtle.fuel_level = 5000
turtle.inventory[1] = {name = "minecraft:cobblestone", count = 64}

-- Mock bedrock detection
local original_inspect = Mining.inspect
Mining.inspect = function(direction)
    if direction == "down" and turtle.position.y < 1 then
        return true, {name = "minecraft:bedrock", is_protected = true}
    end
    return false
end

success = Patterns.execute("quarry", {
    width = 4,
    length = 4,
    depth = 5,
    return_home = false
})
assert_true(success, "Quarry pattern should execute successfully")

-- Restore original inspect
Mining.inspect = original_inspect

-- Test 3x3 Tunnel Pattern
print("\nTesting 3x3 Tunnel Pattern...")

-- Test 8: Short tunnel
turtle.position = {x = 0, y = 64, z = 0, facing = 0}
turtle.fuel_level = 1000

success = Patterns.execute("tunnel_3x3", {
    length = 5,
    torch_interval = 8,
    support_interval = 16,
    return_home = false
})
assert_true(success, "3x3 tunnel pattern should execute successfully")

-- Test Adaptive Mining Pattern
print("\nTesting Adaptive Mining Pattern...")

-- Test 9: Basic adaptive mining
turtle.position = {x = 0, y = 64, z = 0, facing = 0}
turtle.fuel_level = 2000

-- Mock ore detection for adaptive pattern
local ore_counter = 0
Mining.inspect = function(direction)
    ore_counter = ore_counter + 1
    if ore_counter % 5 == 0 then
        -- Simulate finding ore occasionally
        return true, {
            name = "minecraft:iron_ore",
            is_ore = true,
            ore_type = "iron"
        }
    end
    return false
end

success = Patterns.execute("adaptive", {
    max_blocks = 50,
    base_pattern = "branch",
    return_home = false
})
assert_true(success, "Adaptive mining should execute successfully")

-- Test Pattern Statistics
print("\nTesting Pattern Statistics...")

-- Test 10: Final statistics
stats = Patterns.getStats()
assert_not_nil(stats, "Should return final statistics")
assert_true(stats.total_blocks > 0, "Should have total blocks mined")
assert_true(stats.fuel_used > 0, "Should have fuel usage tracked")
assert_true(stats.runtime_seconds >= 0, "Should have runtime tracked")

-- Test Pattern with Torch Placement
print("\nTesting Torch Placement...")

-- Test 11: Torch placement in patterns
turtle.position = {x = 0, y = 64, z = 0, facing = 0}
turtle.fuel_level = 500
turtle.inventory[1] = {name = "minecraft:torch", count = 64}

local torch_placed = false
turtle.place = function()
    torch_placed = true
    return true
end
turtle.placeDown = function()
    torch_placed = true
    return true
end

success = Patterns.execute("strip", {
    length = 8,
    strips = 1,
    torch_interval = 4,
    return_home = false
})

assert_true(success, "Pattern with torches should execute")
assert_true(torch_placed, "Should have placed torches")

-- Test Pattern Stop
print("\nTesting Pattern Stop...")

-- Test 12: Stop pattern
success = Patterns.stop()
assert_true(success, "Should stop current pattern")

-- Test Invalid Pattern
print("\nTesting Invalid Pattern...")

-- Test 13: Invalid pattern type
success = Patterns.execute("invalid_pattern", {})
assert_false(success, "Invalid pattern should fail")

-- Test Pattern Options
print("\nTesting Pattern Options...")

-- Test 14: Pattern with custom options
turtle.position = {x = 0, y = 64, z = 0, facing = 0}
turtle.fuel_level = 1000

success = Patterns.execute("strip", {
    length = 5,
    spacing = 2,
    strips = 1,
    torch_interval = 3,
    return_home = true  -- Should return to start
})
assert_true(success, "Pattern with custom options should work")

-- Check if returned home
local final_pos = Navigation.getPosition()
assert_equals(0, final_pos.x, "Should return to start X")
assert_equals(64, final_pos.y, "Should return to start Y")

-- Test Pattern Efficiency
print("\nTesting Pattern Efficiency...")

-- Test 15: Check efficiency metrics
stats = Patterns.getStats()
if stats.total_blocks > 0 then
    assert_true(stats.blocks_per_minute >= 0, "Should calculate blocks per minute")
    assert_true(stats.efficiency >= 0, "Should calculate efficiency")
end

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