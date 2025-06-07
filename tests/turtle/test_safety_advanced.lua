-- Tests for Advanced Safety Features
-- Tests falling block support, cave-in prevention, and recovery systems

-- Mock turtle API
local turtle = {
    position = {x = 0, y = 64, z = 0, facing = 0},
    fuel_level = 1000,
    inventory = {},
    selected_slot = 1,
    
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
    detectDown = function() return false end,
    inspect = function() return false end,
    inspectUp = function() return false end,
    inspectDown = function() return false end,
    place = function() return true end,
    placeUp = function() return true end,
    placeDown = function() return true end,
    attack = function() return false end,
    attackUp = function() return false end,
    attackDown = function() return false end,
    select = function(slot) 
        turtle.selected_slot = slot
        return true 
    end,
    getItemDetail = function(slot)
        slot = slot or turtle.selected_slot
        if turtle.inventory[slot] then
            return turtle.inventory[slot]
        end
        return nil
    end,
    getItemCount = function(slot)
        slot = slot or turtle.selected_slot
        if turtle.inventory[slot] then
            return turtle.inventory[slot].count or 0
        end
        return 0
    end,
    getItemSpace = function(slot)
        slot = slot or turtle.selected_slot
        if turtle.inventory[slot] then
            return 64 - (turtle.inventory[slot].count or 0)
        end
        return 64
    end,
    drop = function(count) return true end,
    dropUp = function(count) return true end,
    dropDown = function(count) return true end,
    suck = function(count) return true end,
    suckUp = function(count) return true end,
    suckDown = function(count) return true end,
    refuel = function(count) return true end,
    transferTo = function(slot, count) return true end,
    compareTo = function(slot) return false end
}
_G.turtle = turtle

-- Mock peripheral API
_G.peripheral = {
    find = function(type) 
        if type == "modem" then
            return {
                open = function(channel) return true end,
                close = function(channel) return true end,
                transmit = function(channel, reply, message) return true end
            }
        end
        return nil
    end,
    getName = function(p) return "left" end
}

-- Mock rednet API
_G.rednet = {
    open = function(side) return true end,
    close = function() return true end,
    broadcast = function(message, protocol) return true end,
    receive = function(protocol, timeout) return nil end
}

-- Mock GPS API
_G.gps = {
    locate = function(timeout) return nil end
}

-- Mock vector API
_G.vector = {
    new = function(x, y, z)
        local v = {x = x or 0, y = y or 0, z = z or 0}
        return v
    end
}

-- Mock other globals
_G.os = {
    epoch = function(type) return 1000000 end,
    sleep = function(seconds) end,
    computerID = function() return 1 end,
    date = function() return "00:00:00" end,
    pullEvent = function() end,
    queueEvent = function() end,
    startTimer = function() return 1 end
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
local Safety = require("turtle.modules.safety")
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local Inventory = require("turtle.modules.inventory")

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
print("=== Advanced Safety Tests ===")
print()

Core.init({debug = false})
State.init()
Config.init()
Navigation.init({skip_gps = true})
Inventory.init()
Safety.init()

-- Test Falling Block Detection
print("Testing Falling Block Detection...")

-- Test 1: No falling block
turtle.inspectUp = function() return true, {name = "minecraft:stone"} end
local has_falling, block_name = Safety.detectFallingBlockAbove()
assert_false(has_falling, "Should not detect stone as falling block")

-- Test 2: Sand detection
turtle.inspectUp = function() return true, {name = "minecraft:sand"} end
has_falling, block_name = Safety.detectFallingBlockAbove()
assert_true(has_falling, "Should detect sand as falling block")
assert_equals("minecraft:sand", block_name, "Should return sand block name")

-- Test 3: Gravel detection
turtle.inspectUp = function() return true, {name = "minecraft:gravel"} end
has_falling, block_name = Safety.detectFallingBlockAbove()
assert_true(has_falling, "Should detect gravel as falling block")

-- Test 4: Concrete powder detection
turtle.inspectUp = function() return true, {name = "minecraft:red_concrete_powder"} end
has_falling, block_name = Safety.detectFallingBlockAbove()
assert_true(has_falling, "Should detect concrete powder as falling block")

-- Test Falling Block Support Placement
print("\nTesting Falling Block Support...")

-- Test 5: Place torch support
turtle.inspectUp = function() return true, {name = "minecraft:sand"} end
turtle.inventory[1] = {name = "minecraft:torch", count = 64}
Inventory.scanInventory()
turtle.place = function() return true end

local success, msg = Safety.placeFallingBlockSupport()
assert_true(success, "Should place torch support successfully")

-- Test 6: No support blocks available
turtle.inventory = {}
Inventory.scanInventory()
success, msg = Safety.placeFallingBlockSupport()
assert_false(success, "Should fail when no support blocks available")

-- Test Structural Integrity
print("\nTesting Structural Integrity...")

-- Test 7: Small safe excavation
local integrity = Safety.checkStructuralIntegrity({width = 3, height = 3, depth = 3})
assert_true(integrity.safe, "Small excavation should be safe")
assert_true(integrity.score >= 50, "Small excavation should have good integrity score")

-- Test 8: Large excavation needs support
integrity = Safety.checkStructuralIntegrity({width = 8, height = 3, depth = 8})
assert_true(integrity.needs_support, "Large excavation should need support")
assert_true(#integrity.issues > 0, "Large excavation should have issues")

-- Test 9: Falling blocks in ceiling
turtle.inspectUp = function() return true, {name = "minecraft:gravel"} end
-- Make it a large excavation with falling blocks to trigger unsafe
integrity = Safety.checkStructuralIntegrity({width = 8, height = 3, depth = 8})
assert_false(integrity.safe, "Large excavation with falling blocks should be unsafe")
assert_true(integrity.score < 50, "Score should be below safety threshold")

-- Test Support Pillar Planning
print("\nTesting Support Pillar Planning...")

-- Test 10: Plan pillars for area
local pillars = Safety.planSupportPillars({x1 = 0, y = 64, z1 = 0, x2 = 20, z2 = 20})
assert_true(#pillars > 0, "Should plan support pillars for large area")
assert_true(#pillars >= 9, "Should have multiple pillars for 20x20 area")

-- Test Position Recovery
print("\nTesting Position Recovery...")

-- Test 11: GPS recovery
_G.gps.locate = function(timeout) return 10, 64, 20 end
local recovered, final_pos, methods = Safety.recoverLostPosition()
assert_true(recovered, "Should recover position via GPS")
assert_equals(10, final_pos.x, "GPS X coordinate")
assert_equals(64, final_pos.y, "GPS Y coordinate")
assert_equals(20, final_pos.z, "GPS Z coordinate")

-- Test 12: State-based recovery
_G.gps.locate = function(timeout) return nil end  -- Make sure to include timeout parameter
Navigation.setPosition({x = 100, y = 100, z = 100})  -- Set a different position first
State.set("last_known_position", {x = 5, y = 60, z = 15, facing = 2})
recovered, final_pos, methods = Safety.recoverLostPosition()
assert_true(recovered, "Should recover position from state")
-- Debug output
if final_pos.x ~= 5 then
    print("  Debug: final_pos = " .. Navigation.formatPosition(final_pos))
    print("  Debug: Navigation.getPosition() = " .. Navigation.formatPosition(Navigation.getPosition()))
    print("  Debug: recovered = " .. tostring(recovered))
    print("  Debug: methods tried:")
    for _, m in ipairs(methods or {}) do
        print("    - " .. m.method .. ": " .. tostring(m.success))
    end
end
assert_equals(5, final_pos.x, "State X coordinate")

-- Test 13: Fallback to origin
State.set("last_known_position", nil)
Navigation.setPosition({x = 100, y = 100, z = 100})  -- Set a different position first
recovered, final_pos, methods = Safety.recoverLostPosition()
assert_true(recovered, "Should always recover (fallback to origin)")
assert_equals(0, final_pos.x, "Origin X coordinate")
assert_equals(64, final_pos.y, "Origin Y coordinate")

-- Test Network Reconnection
print("\nTesting Network Reconnection...")

-- Test 14: Successful reconnection
local net_success, result = Safety.reconnectNetwork()
assert_true(net_success or result == "No response", "Network reconnection should attempt")

-- Test 15: No modem available
peripheral.find = function() return nil end
net_success, result = Safety.reconnectNetwork()
assert_false(net_success, "Should fail without modem")
assert_equals("No modem available", result, "Should report no modem")

-- Test State Recovery
print("\nTesting State Recovery...")

-- Test 16: Full state recovery
peripheral.find = function(type) 
    if type == "modem" then
        return {open = function() end}
    end
end
local recovery_report = Safety.recoverState()
assert_not_nil(recovery_report, "Should return recovery report")
assert_true(recovery_report.position_recovered, "Position should be recovered")
assert_true(recovery_report.safety_verified, "Safety should be verified")

-- Test Mob Detection
print("\nTesting Mob Detection...")

-- Test 17: Spawner detection
turtle.inspect = function() return true, {name = "minecraft:spawner"} end
local has_mobs, indicators = Safety.detectMob()
assert_true(has_mobs, "Should detect spawner as mob indicator")
assert_true(#indicators > 0, "Should have mob indicators")

-- Test 18: Entity blocking detection
turtle.inspect = function() return false end
turtle.detect = function() return false end
turtle.forward = function() return false end  -- Blocked by entity
has_mobs, indicators = Safety.detectMob()
assert_true(has_mobs, "Should detect entity blocking")

-- Test Combat Protocol
print("\nTesting Combat Protocol...")

-- Test 19: Successful combat
-- Reset turtle functions after entity blocking test
turtle.detect = function() return false end
turtle.forward = function() return true end
turtle.attack = function() return true end
-- Also reset Navigation state
Navigation.setPosition({x = 0, y = 64, z = 0, facing = 0})
Navigation.setHome({x = 0, y = 64, z = 0})
local combat_success, attacks = Safety.combatProtocol()
assert_true(combat_success, "Combat should succeed when path clears")
assert_true(attacks > 0, "Should make attacks")

-- Test 20: Combat retreat
turtle.attack = function() return true end
turtle.forward = function() return false end  -- Still blocked
combat_success, attacks = Safety.combatProtocol()
assert_false(combat_success, "Should retreat when combat fails")

-- Test Pre-mining Safety Check
print("\nTesting Pre-mining Safety Check...")

-- Test 21: Safe to mine forward
-- Reset turtle state for clean test
turtle.fuel_level = 1000
turtle.inspectUp = function() return true, {name = "minecraft:stone"} end
turtle.detect = function() return false end
-- Set position and home to valid values for safety check
Navigation.setPosition({x = 0, y = 64, z = 0, facing = 0})
Navigation.setHome({x = 0, y = 64, z = 0})
local safe, reason = Safety.preMiningCheck("forward")
if not safe then
    print("  Debug: Pre-mining check failed with reason: " .. tostring(reason))
    print("  Debug: Current position: " .. Navigation.formatPosition(Navigation.getPosition()))
    print("  Debug: Fuel level: " .. turtle.getFuelLevel())
end
assert_true(safe, "Should be safe to mine forward")

-- Test 22: Unsafe to mine up (falling block)
turtle.inspectUp = function() return true, {name = "minecraft:sand"} end
turtle.inventory[1] = {name = "minecraft:torch", count = 1}
Inventory.scanInventory()
safe, reason = Safety.preMiningCheck("up")
assert_true(safe, "Should handle falling block and be safe")

-- Test Hazard Handling
print("\nTesting Hazard Handling...")

-- Test 23: Handle falling block hazard
turtle.detect = function() return false end
local handled = Safety.handleFallingBlockHazard()
assert_true(handled, "Should handle falling block hazard")

-- Test 24: Place floor below
turtle.detectDown = function() return false end
turtle.placeDown = function() return true end
turtle.inventory[1] = {name = "minecraft:cobblestone", count = 64}
Inventory.scanInventory()
local floor_placed = Safety.ensureFloorBelow()
assert_true(floor_placed, "Should place floor below")

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