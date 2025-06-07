-- Test Control System
-- Tests the control computer modules

-- Mock globals
_G.os = {
    getComputerID = function() return 100 end,
    epoch = function(type) return 1000000 end,
    sleep = function(seconds) end,
    pullEvent = function() return nil end,
    pullEventRaw = function() return nil end,
    startTimer = function(seconds) return 1 end,
    cancelTimer = function(id) end,
    date = function(format, time) return "2024-01-01 12:00:00" end,
    queueEvent = function(event, ...) end,
    computerID = function() return 100 end
}

-- Mock turtle API (should not exist on control computer)
_G.turtle = nil

-- Mock term API
_G.term = {
    clear = function() end,
    setCursorPos = function(x, y) end,
    write = function(text) end,
    getSize = function() return 51, 19 end,
    isColor = function() return true end,
    setTextColor = function(color) end,
    setBackgroundColor = function(color) end,
    getTextColor = function() return colors.white end,
    getBackgroundColor = function() return colors.black end,
    clearLine = function() end
}

-- Mock colors
_G.colors = {
    white = 1,
    orange = 2,
    magenta = 4,
    lightBlue = 8,
    yellow = 16,
    lime = 32,
    pink = 64,
    gray = 128,
    lightGray = 256,
    cyan = 512,
    purple = 1024,
    blue = 2048,
    brown = 4096,
    green = 8192,
    red = 16384,
    black = 32768
}

-- Mock peripheral
local mock_modem = {
    isWireless = function() return true end,
    isOpen = function(channel) return true end,
    open = function(channel) return true end,
    close = function(channel) return true end,
    closeAll = function() return true end,
    transmit = function(channel, reply, msg) return true end,
    getRange = function() return 64 end
}

_G.peripheral = {
    find = function(ptype, filter)
        if ptype == "modem" then
            return mock_modem
        elseif ptype == "speaker" then
            return nil
        end
        return nil
    end,
    isPresent = function(side)
        return side == "back"
    end,
    getType = function(side)
        if side == "back" then
            return "modem"
        end
        return nil
    end,
    wrap = function(side)
        if side == "back" then
            return mock_modem
        end
        return nil
    end
}

-- Mock rednet
_G.rednet = {
    open = function(side) return true end,
    close = function(side) return true end,
    send = function(recipient, message, protocol) return true end,
    broadcast = function(message, protocol) return true end,
    receive = function(protocol, timeout) return nil, nil, nil end,
    host = function(protocol, hostname) return true end,
    unhost = function(protocol) return true end
}

-- Mock file system
_G.fs = {
    exists = function(path) return false end,
    makeDir = function(path) return true end,
    open = function(path, mode)
        return {
            write = function(data) end,
            writeLine = function(line) end,
            readAll = function() return "{}" end,
            close = function() end
        }
    end,
    getDir = function(path) return "" end
}

-- Mock textutils
_G.textutils = {
    serialize = function(data) return tostring(data) end,
    unserialize = function(str) return {} end
}

-- Mock debug
_G.debug = {
    traceback = function() return "stack trace" end
}

-- Mock read function
_G.read = function() return "" end

-- Mock keys
_G.keys = {
    up = 200,
    down = 208,
    left = 203,
    right = 205,
    enter = 28,
    q = 16,
    y = 21,
    n = 49,
    leftCtrl = 29
}

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

-- Make print available
if not _G.print then
    _G.print = print
end

-- Load modules
package.path = package.path .. ";/Users/thultz/Desktop/Coding Projects/Minecraft/ultimate-miner/?.lua"

print("=== Control System Tests ===")
print()

-- Test Core Module
print("Testing Core Module...")
local Core = require("control.modules.core")

-- Test 1: Initialize core
local success, err = Core.init()
assert_true(success, "Core should initialize successfully")
assert_false(Core.capabilities.is_computer == false, "Should detect as computer, not turtle")
assert_true(Core.capabilities.is_advanced, "Should detect as advanced computer")
assert_true(Core.capabilities.has_color, "Should have color support")
assert_equals(51, Core.capabilities.screen_width, "Should have correct screen width")
assert_equals(19, Core.capabilities.screen_height, "Should have correct screen height")

-- Test Network Module
print("\nTesting Network Module...")
local Network = require("control.modules.network")

-- Test 2: Initialize network
success, err = Network.init()
assert_true(success, "Network should initialize successfully")

-- Test 3: Network stats
local stats = Network.getStats()
assert_not_nil(stats, "Should return network stats")
assert_true(stats.initialized, "Network should be initialized")
assert_equals(100, stats.computer_id, "Should have correct computer ID")
assert_equals("ULTIMATE_MINER_V2", stats.protocol, "Should use correct protocol")

-- Test Fleet Module
print("\nTesting Fleet Module...")
local Fleet = require("control.modules.fleet")

-- Test 4: Initialize fleet
success, err = Fleet.init()
assert_true(success, "Fleet should initialize successfully")

-- Test 5: Register turtle
success = Fleet.registerTurtle(1, {
    name = "Test Turtle",
    position = {x = 0, y = 64, z = 0, facing = 0},
    fuel_level = 1000,
    fuel_limit = 20000
})
assert_true(success, "Should register turtle successfully")

-- Test 6: Get turtle
local turtle = Fleet.getTurtle(1)
assert_not_nil(turtle, "Should retrieve registered turtle")
assert_equals("Test Turtle", turtle.name, "Should have correct turtle name")
assert_equals("online", turtle.status, "Should be online")

-- Test 7: Fleet status counts
local counts = Fleet.getStatusCounts()
assert_equals(1, counts.total, "Should have 1 turtle total")
assert_equals(1, counts.online, "Should have 1 turtle online")

-- Test Commands Module
print("\nTesting Commands Module...")
local Commands = require("control.modules.commands")

-- Test 8: Initialize commands
success, err = Commands.init()
assert_true(success, "Commands should initialize successfully")

-- Test 9: Get available commands
local available = Commands.getAvailable()
assert_not_nil(available, "Should return available commands")
assert_true(#available > 0, "Should have registered commands")

-- Test 10: Command validation
local validation_err = Commands.validateParameters(
    {x = "number", y = "number", z = "number"},
    {x = 10, y = 20, z = 30}
)
assert_equals(nil, validation_err, "Should validate correct parameters")

validation_err = Commands.validateParameters(
    {x = "number", y = "number", z = "number"},
    {x = 10, y = "not a number", z = 30}
)
assert_not_nil(validation_err, "Should reject invalid parameters")

-- Test UI Module
print("\nTesting UI Module...")
local UI = require("control.modules.ui")

-- Test 11: Initialize UI
success, err = UI.init()
assert_true(success, "UI should initialize successfully")
assert_equals(51, UI.width, "Should have correct UI width")
assert_equals(19, UI.height, "Should have correct UI height")
assert_true(UI.is_color, "Should detect color support")
assert_true(UI.is_advanced, "Should detect advanced computer")

-- Test Integration
print("\nTesting Integration...")

-- Test 12: Fleet command execution
success = Commands.execute(1, "get_status", {})
assert_true(success, "Should execute command on online turtle")

-- Test 13: Emergency stop all
success = Fleet.emergencyStopAll("Test emergency")
assert_true(success, "Should execute emergency stop")

-- Test 14: Network broadcast
success = Network.broadcast({
    type = "test_broadcast",
    data = "test"
})
assert_true(success, "Should broadcast message")

-- Cleanup
print("\nCleaning up...")
UI.shutdown()
Commands.shutdown()
Fleet.shutdown()
Network.shutdown()
Core.shutdown()

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