-- Test script for Navigation module
-- Run this in a turtle to verify navigation functionality

-- Add module path
package.path = package.path .. ";/turtle/modules/?.lua;/?.lua"

-- Load modules
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local CONSTANTS = require("shared.constants")

-- Initialize dependencies
Core.init({debug = true})
State.init("test_navigation_state.dat")
Config.init("test_navigation_config.cfg")

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

-- Clean up any existing files
local function cleanup()
    if fs.exists("test_navigation_state.dat") then
        fs.delete("test_navigation_state.dat")
    end
    if fs.exists("test_navigation_config.cfg") then
        fs.delete("test_navigation_config.cfg")
    end
end

-- Start tests
print("=== Navigation Module Tests ===")
print("Note: Some tests require turtle movement")
print("Ensure turtle has fuel and clear space")
print()

-- Test initialization
test("Navigation initialization", function()
    local success, msg = Navigation.init({skip_gps = true})
    assert(success, "Navigation init failed: " .. tostring(msg))
end)

-- Test position management
test("Position management", function()
    -- Get initial position
    local pos = Navigation.getPosition()
    assert(pos, "Failed to get position")
    assert(type(pos.x) == "number", "Position x not a number")
    assert(type(pos.y) == "number", "Position y not a number")
    assert(type(pos.z) == "number", "Position z not a number")
    assert(type(pos.facing) == "number", "Position facing not a number")
    
    -- Set position
    local new_pos = {x = 100, y = 64, z = 200, facing = CONSTANTS.DIRECTIONS.EAST}
    assert(Navigation.setPosition(new_pos), "Failed to set position")
    
    -- Verify position was set
    local check_pos = Navigation.getPosition()
    assert(check_pos.x == 100, "Position x not set correctly")
    assert(check_pos.y == 64, "Position y not set correctly")
    assert(check_pos.z == 200, "Position z not set correctly")
    assert(check_pos.facing == CONSTANTS.DIRECTIONS.EAST, "Facing not set correctly")
end)

-- Test home position
test("Home position", function()
    -- Set home
    local home = {x = 0, y = 64, z = 0}
    assert(Navigation.setHome(home), "Failed to set home")
    
    -- Get home
    local retrieved_home = Navigation.getHome()
    assert(retrieved_home, "Failed to get home")
    assert(retrieved_home.x == 0, "Home x incorrect")
    assert(retrieved_home.y == 64, "Home y incorrect")
    assert(retrieved_home.z == 0, "Home z incorrect")
    
    -- Set home to current position
    assert(Navigation.setHome(), "Failed to set home to current")
end)

-- Test turning
test("Turning functions", function()
    -- Get initial facing
    local initial_pos = Navigation.getPosition()
    local initial_facing = initial_pos.facing
    
    -- Test turn right
    if Navigation.turnRight() then
        local pos = Navigation.getPosition()
        assert(pos.facing == (initial_facing + 1) % 4, "Turn right facing incorrect")
    else
        print("  Warning: Turn right failed (blocked?)")
    end
    
    -- Test turn left
    if Navigation.turnLeft() then
        local pos = Navigation.getPosition()
        assert(pos.facing == initial_facing, "Turn left didn't restore facing")
    else
        print("  Warning: Turn left failed (blocked?)")
    end
    
    -- Test face specific direction
    if Navigation.face(CONSTANTS.DIRECTIONS.NORTH) then
        local pos = Navigation.getPosition()
        assert(pos.facing == CONSTANTS.DIRECTIONS.NORTH, "Face north failed")
    end
end)

-- Test movement (if space available)
test("Basic movement", function()
    print("  Attempting movement tests...")
    
    local start_pos = Navigation.getPosition()
    local moved = false
    
    -- Try forward
    if Navigation.forward() then
        moved = true
        local pos = Navigation.getPosition()
        print("  Moved forward successfully")
        
        -- Move back
        if Navigation.back() then
            local back_pos = Navigation.getPosition()
            assert(back_pos.x == start_pos.x and back_pos.z == start_pos.z, 
                "Didn't return to start position")
        end
    else
        print("  Warning: Forward movement blocked")
    end
    
    -- Try up/down if we have fuel
    if turtle.getFuelLevel() > 10 or turtle.getFuelLevel() == "unlimited" then
        if Navigation.up() then
            moved = true
            print("  Moved up successfully")
            Navigation.down()
        else
            print("  Warning: Upward movement blocked")
        end
    end
    
    if not moved then
        print("  Skipping movement tests - turtle is blocked")
    end
end)

-- Test distance calculations
test("Distance and fuel calculations", function()
    local current = Navigation.getPosition()
    local target = {x = current.x + 10, y = current.y + 5, z = current.z + 3}
    
    -- Test distance
    local distance = Navigation.getDistance(target)
    assert(distance == 18, "Distance calculation incorrect: " .. tostring(distance))
    
    -- Test fuel estimate
    local fuel = Navigation.estimateFuel(target)
    assert(fuel >= distance, "Fuel estimate too low")
end)

-- Test GPS (if available)
test("GPS functions", function()
    local success, result = Navigation.locateGPS()
    if success then
        print("  GPS available at: " .. Navigation.formatPosition(result))
        
        -- Test calibration
        if turtle.getFuelLevel() > 5 or turtle.getFuelLevel() == "unlimited" then
            local cal_success = Navigation.calibrateGPS()
            if cal_success then
                print("  GPS calibration successful")
            else
                print("  GPS calibration failed")
            end
        end
    else
        print("  GPS not available - skipping GPS tests")
    end
end)

-- Test path history
test("Path history", function()
    -- Clear history first
    Navigation.clearPathHistory()
    
    -- Make some movements (if possible)
    Navigation.turnRight()
    Navigation.turnLeft()
    
    -- Get history
    local history = Navigation.getPathHistory()
    assert(type(history) == "table", "Path history not a table")
    
    if #history > 0 then
        assert(history[1].pos, "History entry missing position")
        assert(history[1].time, "History entry missing time")
        assert(history[1].action, "History entry missing action")
    end
end)

-- Test safety features
test("Safety features", function()
    -- Test emergency stop
    assert(Navigation.emergencyStop(), "Emergency stop failed")
    
    -- Test fuel monitoring
    local fuel_level = turtle.getFuelLevel()
    if fuel_level ~= "unlimited" then
        print("  Current fuel: " .. fuel_level)
        
        -- Set very high emergency fuel to trigger safety
        Config.set("emergency_fuel", fuel_level + 100)
        
        -- Try to move - should fail due to fuel
        local success = Navigation.forward()
        assert(not success, "Movement succeeded with insufficient fuel")
        
        -- Reset emergency fuel
        Config.set("emergency_fuel", CONSTANTS.DEFAULTS.EMERGENCY_FUEL)
    else
        print("  Unlimited fuel - skipping fuel safety test")
    end
end)

-- Test moveTo (simple pathfinding)
test("MoveTo pathfinding", function()
    print("  Testing simple pathfinding...")
    
    local start = Navigation.getPosition()
    local target = {
        x = start.x + 2,
        y = start.y,
        z = start.z + 2,
        facing = start.facing
    }
    
    -- Check if we have enough fuel
    local fuel_needed = Navigation.estimateFuel(target)
    local current_fuel = turtle.getFuelLevel()
    
    if current_fuel == "unlimited" or current_fuel > fuel_needed + 10 then
        local success, err = Navigation.moveTo(target, {fuel_check = true})
        if success then
            print("  Successfully moved to target")
            -- Return to start
            Navigation.moveTo(start)
        else
            print("  MoveTo failed: " .. tostring(err))
        end
    else
        print("  Insufficient fuel for pathfinding test")
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
Core.shutdown()