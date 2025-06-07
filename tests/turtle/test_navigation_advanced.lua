-- Tests for Advanced Navigation Features
-- Tests GPS integration, pathfinding, and emergency protocols

-- Mock turtle API
local turtle = {
    position = {x = 0, y = 64, z = 0, facing = 0},
    fuel_level = 1000,
    
    forward = function() return true end,
    back = function() return true end,
    up = function() return true end,
    down = function() return true end,
    turnLeft = function() return true end,
    turnRight = function() return true end,
    getFuelLevel = function() return turtle.fuel_level end,
    getFuelLimit = function() return 20000 end,
    detect = function() return false end,
    detectUp = function() return false end,
    detectDown = function() return false end
}
_G.turtle = turtle

-- Mock GPS API
local gps = {
    locate = function(timeout)
        -- Simulate GPS availability
        if _G.gps_available then
            return turtle.position.x, turtle.position.y, turtle.position.z
        end
        return nil
    end
}
_G.gps = gps

-- Mock vector API
_G.vector = {
    new = function(x, y, z)
        local v = {x = x or 0, y = y or 0, z = z or 0}
        local mt = {
            __add = function(a, b) return vector.new(a.x + b.x, a.y + b.y, a.z + b.z) end,
            __sub = function(a, b) return vector.new(a.x - b.x, a.y - b.y, a.z - b.z) end,
            __mul = function(a, b) 
                if type(b) == "number" then
                    return vector.new(a.x * b, a.y * b, a.z * b)
                else
                    return vector.new(a.x * b.x, a.y * b.y, a.z * b.z)
                end
            end,
            __tostring = function(v) return string.format("(%d,%d,%d)", v.x, v.y, v.z) end
        }
        
        v.length = function(self) 
            return math.sqrt(self.x^2 + self.y^2 + self.z^2)
        end
        
        v.normalize = function(self)
            local len = self:length()
            if len == 0 then return vector.new(0, 0, 0) end
            return vector.new(self.x / len, self.y / len, self.z / len)
        end
        
        v.dot = function(self, other)
            return self.x * other.x + self.y * other.y + self.z * other.z
        end
        
        v.cross = function(self, other)
            return vector.new(
                self.y * other.z - self.z * other.y,
                self.z * other.x - self.x * other.z,
                self.x * other.y - self.y * other.x
            )
        end
        
        setmetatable(v, mt)
        return v
    end
}

-- Mock other globals
_G.os = {
    epoch = function(type) return 1000000 end,
    sleep = function(seconds) end,
    pullEvent = function() end,
    queueEvent = function() end,
    date = function() return "00:00:00" end,
    startTimer = function() return 1 end,
    computerID = function() return 1 end
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

-- Make sure print is available
if not _G.print then
    _G.print = print
end

-- Load modules
package.path = package.path .. ";/Users/thultz/Desktop/Coding Projects/Minecraft/ultimate-miner/?.lua"
local Navigation = require("turtle.modules.navigation")
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")

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
print("=== Advanced Navigation Tests ===")
print()

Core.init({debug = false})
State.init()
Config.init()

-- Test GPS Integration
print("Testing GPS Integration...")

-- Test 1: GPS locate with available GPS
_G.gps_available = true
Navigation.init({skip_gps = true})

local success, pos = Navigation.locateGPS()
assert_true(success, "GPS locate should succeed when available")
assert_equals(0, pos.x, "GPS X coordinate should match")
assert_equals(64, pos.y, "GPS Y coordinate should match")
assert_equals(0, pos.z, "GPS Z coordinate should match")

-- Test 2: GPS locate without GPS
_G.gps_available = false
success, pos = Navigation.locateGPS()
assert_false(success, "GPS locate should fail when unavailable")

-- Test 3: Manual position setting
success = Navigation.setManualPosition(100, 50, -200, "north")
assert_true(success, "Manual position setting should succeed")
local current_pos = Navigation.getPosition()
assert_equals(100, current_pos.x, "Manual X position")
assert_equals(50, current_pos.y, "Manual Y position")
assert_equals(-200, current_pos.z, "Manual Z position")
assert_equals(0, current_pos.facing, "Manual facing direction")

-- Test 4: GPS recovery attempt
print("\nTesting GPS Recovery...")
_G.gps_available = false
success = Navigation.recoverGPS()
assert_false(success, "GPS recovery should fail when GPS unavailable")

-- Test A* Pathfinding
print("\nTesting A* Pathfinding...")

-- Reset position
Navigation.setManualPosition(0, 64, 0, 0)

-- Test 5: Simple path calculation
local path = Navigation.pathTo({x = 5, y = 64, z = 0})
assert_not_nil(path, "Path should be calculated")
assert_true(#path > 1, "Path should have multiple waypoints")
assert_equals(0, path[1].x, "Path should start at current position")
assert_equals(5, path[#path].x, "Path should end at target")

-- Test 6: Path with obstacles (simulated by avoid list)
path = Navigation.pathTo({x = 2, y = 64, z = 2}, {
    avoid = {["1,64,0"] = true, ["0,64,1"] = true}
})
assert_not_nil(path, "Path should route around obstacles")

-- Test 7: Path caching
local path2 = Navigation.pathTo({x = 5, y = 64, z = 0})
assert_equals(path, path2, "Cached path should be returned")

-- Test Emergency Protocols
print("\nTesting Emergency Protocols...")

-- Test 8: Emergency condition detection
Navigation.setHome({x = 0, y = 64, z = 0})
Navigation.setManualPosition(450, 64, 0, 0)
local emergency_needed, reason = Navigation.checkEmergencyConditions()
assert_false(emergency_needed, "Emergency not needed with sufficient fuel")

-- Test 9: Low fuel emergency
turtle.fuel_level = 100
emergency_needed, reason = Navigation.checkEmergencyConditions()
assert_true(emergency_needed, "Emergency needed with low fuel")
assert_true(string.find(reason, "fuel"), "Reason should mention fuel")

-- Test 10: Emergency return activation
success = Navigation.activateEmergencyReturn("Test emergency")
assert_true(success, "Emergency return should activate")

-- Test Path History
print("\nTesting Path History...")

-- Reset for history tests
Navigation.init()
Navigation.setManualPosition(0, 64, 0, 0)

-- Test 11: Path history tracking
Navigation.forward()
Navigation.up()
Navigation.turnRight()
Navigation.forward()

local history = Navigation.getPathHistory()
assert_true(#history >= 3, "Path history should track movements")

-- Test 12: Path history statistics
local stats = Navigation.getPathHistoryStats()
assert_not_nil(stats, "History stats should be available")
assert_true(stats.total_moves >= 3, "Total moves should be tracked")
assert_true(stats.unique_positions > 0, "Unique positions should be tracked")

-- Test 13: Backtracking
Navigation.setManualPosition(5, 64, 5, 0)
Navigation.clearPathHistory()
Navigation.forward()
Navigation.turnLeft()
Navigation.forward()

success = Navigation.backtrack(2)
assert_true(success, "Backtracking should succeed")

-- Test Safety Bounds
print("\nTesting Safety Bounds...")

-- Test 14: Y bounds checking
local within_bounds = Navigation.isWithinBounds({x = 0, y = -65, z = 0})
assert_false(within_bounds, "Position below bedrock should be out of bounds")

within_bounds = Navigation.isWithinBounds({x = 0, y = 320, z = 0})
assert_false(within_bounds, "Position above build limit should be out of bounds")

-- Test 15: Safety radius checking
Navigation.setHome({x = 0, y = 64, z = 0})
within_bounds = Navigation.isWithinBounds({x = 600, y = 64, z = 0})
assert_false(within_bounds, "Position outside safety radius should be out of bounds")

-- Test Movement Options
print("\nTesting Movement Options...")

-- Test 16: Movement with pathfinding option
Navigation.setManualPosition(0, 64, 0, 0)
success = Navigation.moveTo({x = 3, y = 66, z = 3}, {use_pathfinding = true})
assert_true(success, "Movement with pathfinding should succeed")

-- Test 17: Movement with fuel check disabled
turtle.fuel_level = 10
success = Navigation.moveTo({x = 0, y = 64, z = 0}, {fuel_check = false})
assert_true(success, "Movement without fuel check should proceed")

-- Test 18: Already at destination
success = Navigation.moveTo({x = 0, y = 64, z = 0})
assert_true(success, "Movement to current position should succeed immediately")

-- Test Navigation Stats
print("\nTesting Navigation Stats...")

-- Test 19: Get navigation statistics
local nav_stats = Navigation.getStats()
assert_not_nil(nav_stats, "Navigation stats should be available")
assert_not_nil(nav_stats.position, "Stats should include position")
assert_not_nil(nav_stats.gps_available, "Stats should include GPS status")
assert_not_nil(nav_stats.emergency_mode, "Stats should include emergency mode")

-- Test 20: Clear path cache
Navigation.clearPathCache()
nav_stats = Navigation.getStats()
assert_equals(0, nav_stats.path_cache_size, "Path cache should be cleared")

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