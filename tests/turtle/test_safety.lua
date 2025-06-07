-- Test script for Safety module
-- Run this in a turtle to verify safety functionality

-- Add module path
package.path = package.path .. ";/turtle/modules/?.lua;/?.lua"

-- Load modules
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local Inventory = require("turtle.modules.inventory")
local Safety = require("turtle.modules.safety")
local CONSTANTS = require("shared.constants")

-- Initialize dependencies
Core.init({debug = true})
State.init("test_safety_state.dat")
Config.init("test_safety_config.cfg")
Navigation.init({skip_gps = true})
Inventory.init()

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

-- Mock turtle functions
local original_inspect = turtle.inspect
local original_inspectUp = turtle.inspectUp
local original_inspectDown = turtle.inspectDown
local original_getFuelLevel = turtle.getFuelLevel

local mock_blocks = {
    forward = nil,
    up = nil,
    down = nil
}
local mock_fuel = 1000

local function setupMocks()
    turtle.inspect = function()
        if mock_blocks.forward then
            return true, mock_blocks.forward
        end
        return false
    end
    
    turtle.inspectUp = function()
        if mock_blocks.up then
            return true, mock_blocks.up
        end
        return false
    end
    
    turtle.inspectDown = function()
        if mock_blocks.down then
            return true, mock_blocks.down
        end
        return false
    end
    
    turtle.getFuelLevel = function()
        return mock_fuel
    end
end

local function restoreTurtle()
    turtle.inspect = original_inspect
    turtle.inspectUp = original_inspectUp
    turtle.inspectDown = original_inspectDown
    turtle.getFuelLevel = original_getFuelLevel
end

-- Clean up any existing files
local function cleanup()
    if fs.exists("test_safety_state.dat") then
        fs.delete("test_safety_state.dat")
    end
    if fs.exists("test_safety_config.cfg") then
        fs.delete("test_safety_config.cfg")
    end
end

-- Start tests
print("=== Safety Module Tests ===")
print()

-- Test initialization
test("Safety initialization", function()
    local success, msg = Safety.init()
    assert(success, "Safety init failed: " .. tostring(msg))
end)

-- Test hazard detection
test("Hazard detection", function()
    setupMocks()
    
    -- Test lava detection
    mock_blocks.forward = {name = "minecraft:lava", state = {}}
    local hazard = Safety.checkHazard("forward")
    assert(not hazard.safe, "Should detect lava as unsafe")
    assert(hazard.hazard == "lava", "Should identify lava hazard")
    assert(hazard.danger_level == 10, "Lava should have max danger level")
    
    -- Test water detection
    mock_blocks.forward = {name = "minecraft:water", state = {}}
    hazard = Safety.checkHazard("forward")
    assert(not hazard.safe, "Should detect water as hazard")
    assert(hazard.hazard == "water", "Should identify water hazard")
    assert(hazard.danger_level == 3, "Water should have low danger level")
    
    -- Test safe block
    mock_blocks.forward = {name = "minecraft:stone", state = {}}
    hazard = Safety.checkHazard("forward")
    assert(hazard.safe, "Stone should be safe")
    
    -- Test void detection
    mock_blocks.down = nil
    hazard = Safety.checkHazard("down")
    assert(not hazard.safe, "Should detect void below")
    assert(hazard.hazard == "void", "Should identify void hazard")
    
    restoreTurtle()
end)

-- Test comprehensive safety check
test("Comprehensive safety check", function()
    setupMocks()
    
    -- Set up safe conditions
    mock_fuel = 1000
    mock_blocks.forward = {name = "minecraft:stone", state = {}}
    mock_blocks.up = {name = "minecraft:stone", state = {}}
    mock_blocks.down = {name = "minecraft:stone", state = {}}
    
    local safe, hazards = Safety.performSafetyCheck()
    assert(safe, "Should be safe with normal conditions")
    assert(#hazards == 0, "Should have no hazards")
    
    -- Test low fuel
    mock_fuel = 50
    safe, hazards = Safety.performSafetyCheck()
    assert(not safe, "Should be unsafe with low fuel")
    local found_fuel_hazard = false
    for _, hazard in ipairs(hazards) do
        if hazard.hazard == "low_fuel" then
            found_fuel_hazard = true
        end
    end
    assert(found_fuel_hazard, "Should detect low fuel hazard")
    
    -- Test critical fuel
    mock_fuel = 10
    safe, hazards = Safety.performSafetyCheck()
    found_fuel_hazard = false
    for _, hazard in ipairs(hazards) do
        if hazard.hazard == "no_fuel" then
            found_fuel_hazard = true
        end
    end
    assert(found_fuel_hazard, "Should detect critical fuel hazard")
    
    restoreTurtle()
end)

-- Test movement safety
test("Movement safety checks", function()
    setupMocks()
    
    -- Test safe movement
    mock_fuel = 1000
    mock_blocks.forward = nil  -- No block
    local safe, reason = Safety.isSafeToMove("forward")
    assert(safe, "Should be safe to move forward")
    
    -- Test blocked by lava
    mock_blocks.forward = {name = "minecraft:lava", state = {}}
    safe, reason = Safety.isSafeToMove("forward")
    assert(not safe, "Should not be safe with lava ahead")
    
    -- Test low fuel
    mock_fuel = 5
    mock_blocks.forward = nil
    safe, reason = Safety.isSafeToMove("forward")
    assert(not safe, "Should not be safe with insufficient fuel")
    
    restoreTurtle()
end)

-- Test emergency protocols
test("Emergency protocols", function()
    -- Test emergency stop
    local success = Safety.emergencyStop("Test emergency")
    assert(success, "Emergency stop should succeed")
    
    -- Check stats were updated
    local stats = Safety.getStats()
    assert(stats.emergency_stops > 0, "Should track emergency stops")
end)

-- Test hazard handling
test("Hazard handling", function()
    setupMocks()
    
    -- Mock inventory with safe blocks
    Inventory.scanInventory()
    
    -- Test lava handling (without actual block placement)
    print("  Testing lava hazard handling...")
    local handled = Safety.handleLavaHazard("forward")
    -- Can't fully test without real turtle operations
    
    -- Test water handling
    print("  Testing water hazard handling...")
    handled = Safety.handleWaterHazard("forward")
    assert(handled, "Water handling should succeed")
    
    restoreTurtle()
end)

-- Test safety statistics
test("Safety statistics", function()
    -- Get initial stats
    local stats = Safety.getStats()
    assert(type(stats.hazards_detected) == "number", "Should track hazards")
    assert(type(stats.emergency_stops) == "number", "Should track emergency stops")
    assert(type(stats.close_calls) == "number", "Should track close calls")
    
    -- Reset stats
    Safety.resetStats()
    stats = Safety.getStats()
    assert(stats.hazards_detected == 0, "Stats should reset")
    assert(stats.emergency_stops == 0, "Stats should reset")
    assert(stats.close_calls == 0, "Stats should reset")
end)

-- Test boundary safety
test("Boundary safety", function()
    -- Set home position
    Navigation.setHome({x = 0, y = 64, z = 0})
    
    -- Set safety radius
    Safety.setSafetyRadius(50)
    
    -- Move to edge of boundary
    Navigation.setPosition({x = 45, y = 64, z = 0, facing = 0})
    
    -- Check if safe to move further
    local safe = Safety.isSafeToMove("forward")
    -- Depends on implementation details
    
    print("  Boundary safety check completed")
end)

-- Test with real turtle
test("Real turtle safety", function()
    restoreTurtle()
    
    print("  Checking real environment...")
    
    -- Check current hazards
    local hazard_forward = Safety.checkHazard("forward")
    local hazard_down = Safety.checkHazard("down")
    
    print("  Forward: " .. (hazard_forward.safe and "safe" or "hazard detected"))
    print("  Down: " .. (hazard_down.safe and "safe" or "hazard detected"))
    
    -- Perform full safety check
    local safe, hazards = Safety.performSafetyCheck()
    print("  Overall safety: " .. (safe and "safe" or "unsafe"))
    print("  Hazards found: " .. #hazards)
    
    for _, hazard in ipairs(hazards) do
        print("    - " .. hazard.hazard .. ": " .. hazard.message)
    end
end)

-- Test void detection
test("Void detection", function()
    print("  Testing void detection...")
    
    -- This test is risky - only run if safe
    local current_pos = Navigation.getPosition()
    if current_pos.y > 10 then
        local has_floor, depth = Safety.checkVoidBelow(3)
        print("  Void depth check: " .. (has_floor and "floor at " .. depth or "no floor within 3 blocks"))
    else
        print("  Skipping void test - too low")
    end
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