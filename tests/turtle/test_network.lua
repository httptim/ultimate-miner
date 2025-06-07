-- Tests for Network Module
-- Tests network communication and protocol handling

-- Mock globals
_G.os = {
    getComputerID = function() return 1 end,
    epoch = function(type) return 1000000 end,
    sleep = function(seconds) end,
    pullEvent = function() return nil end,
    pullEventRaw = function() return nil end,
    startTimer = function(seconds) return 1 end,
    cancelTimer = function(id) end,
    date = function(format, time) return "2024-01-01 12:00:00" end,
    queueEvent = function(event, ...) end,
    computerID = function() return 1 end
}

_G.turtle = {
    getFuelLevel = function() return 1000 end,
    getFuelLimit = function() return 20000 end
}

-- Mock rednet API
local rednet_open = false
local sent_messages = {}
local broadcast_messages = {}

_G.rednet = {
    open = function(side)
        rednet_open = true
        return true
    end,
    close = function(side)
        rednet_open = false
        return true
    end,
    send = function(recipient, message, protocol)
        table.insert(sent_messages, {
            recipient = recipient,
            message = message,
            protocol = protocol
        })
        return true
    end,
    broadcast = function(message, protocol)
        table.insert(broadcast_messages, {
            message = message,
            protocol = protocol
        })
        return true
    end,
    receive = function(protocol, timeout)
        -- Simulate no messages by default
        return nil, nil, nil
    end
}

-- Mock peripheral API
local mock_modem = {
    isWireless = function() return true end,
    isOpen = function(channel) return true end,
    open = function(channel) return true end,
    close = function(channel) return true end,
    closeAll = function() return true end,
    transmit = function(channel, reply, msg) return true end
}

_G.peripheral = {
    find = function(ptype, filter)
        if ptype == "modem" then
            if filter then
                -- Test filter function
                if filter("mock", mock_modem) then
                    return mock_modem
                end
                return nil
            end
            return mock_modem
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

-- Mock other requirements
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
local Network = require("turtle.modules.network")
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
print("=== Network Module Tests ===")
print()

Core.init({debug = false})
State.init()
Config.init()

-- Test Network Initialization
print("Testing Network Initialization...")

-- Test 1: Initialize network
local success, err = Network.init()
assert_true(success, "Network should initialize successfully")
assert_true(rednet_open, "Rednet should be opened")

-- Test 2: Double initialization
success, err = Network.init()
assert_true(success, "Double init should succeed with message")

-- Test Connection Management
print("\nTesting Connection Management...")

-- Reset message tracking
sent_messages = {}
broadcast_messages = {}

-- Test 3: Connect to network
success, err = Network.connect()
assert_true(success, "Should connect successfully")
assert_true(#broadcast_messages > 0, "Should broadcast presence on connect")
-- Find the turtle_online message (might not be first due to heartbeat)
local found_online = false
for _, msg in ipairs(broadcast_messages) do
    if msg.message.type == "turtle_online" then
        found_online = true
        break
    end
end
assert_true(found_online, "Should send turtle_online message")

-- Test 4: Check connection status
local is_connected = Network.isConnected()
assert_true(is_connected, "Should be connected after connect()")

-- Test 5: Disconnect from network
broadcast_messages = {}
success = Network.disconnect()
assert_true(success, "Should disconnect successfully")
assert_true(#broadcast_messages > 0, "Should broadcast offline message")
assert_equals("turtle_offline", broadcast_messages[1].message.type, "Should send turtle_offline message")

-- Test 6: Check disconnected status
is_connected = Network.isConnected()
assert_false(is_connected, "Should not be connected after disconnect")

-- Test Message Sending
print("\nTesting Message Sending...")

-- Reconnect for message tests
Network.connect()
sent_messages = {}
broadcast_messages = {}

-- Test 7: Send message to specific recipient
success = Network.send(5, {type = "test", data = "hello"})
assert_true(success, "Should send message successfully")
assert_equals(1, #sent_messages, "Should have sent one message")
assert_equals(5, sent_messages[1].recipient, "Should send to correct recipient")
assert_equals("ULTIMATE_MINER_V2", sent_messages[1].protocol, "Should use correct protocol")

-- Test 8: Broadcast message
success = Network.broadcast({type = "test_broadcast", data = "world"})
assert_true(success, "Should broadcast successfully")
assert_equals(1, #broadcast_messages, "Should have broadcast one message")
assert_equals("ULTIMATE_MINER_V2", broadcast_messages[1].protocol, "Should use correct protocol")

-- Test Protocol and Handlers
print("\nTesting Protocol and Handlers...")

-- Test 9: Register message handler
local handler_called = false
local handler_data = nil
success = Network.registerHandler("test_message", function(sender, data)
    handler_called = true
    handler_data = data
end)
assert_true(success, "Should register handler successfully")

-- Test 10: Invalid handler registration
success = Network.registerHandler("bad_handler", "not a function")
assert_false(success, "Should reject non-function handler")

-- Test Status Reporting
print("\nTesting Status Reporting...")

sent_messages = {}
broadcast_messages = {}

-- Test 11: Send status update
success = Network.sendStatus({
    current_task = "mining",
    blocks_mined = 100
})
assert_true(success, "Should send status successfully")
assert_true(#broadcast_messages > 0, "Should broadcast status when no control computer")

-- Test 12: Set control computer
Network.setControlComputer(10)
assert_equals(10, Network.getControlComputer(), "Should set control computer ID")

-- Test 13: Send status to control computer
sent_messages = {}
broadcast_messages = {}
success = Network.sendStatus({
    current_task = "returning",
    fuel_level = 500
})
assert_true(success, "Should send status to control computer")
assert_equals(1, #sent_messages, "Should send to specific computer")
assert_equals(10, sent_messages[1].recipient, "Should send to control computer")
assert_equals(0, #broadcast_messages, "Should not broadcast when control computer known")

-- Test Network Statistics
print("\nTesting Network Statistics...")

-- Test 14: Get network stats
local stats = Network.getStats()
assert_not_nil(stats, "Should return statistics")
assert_true(stats.connected, "Should show connected status")
assert_equals(1, stats.computer_id, "Should have correct computer ID")
assert_equals("ULTIMATE_MINER_V2", stats.protocol, "Should show correct protocol")
assert_equals("wireless", stats.modem_type, "Should identify modem type")
assert_equals(10, stats.control_computer, "Should show control computer ID")

-- Test Discovery Mechanism
print("\nTesting Discovery Mechanism...")

-- Test 15: Discover services (with timeout)
local old_pullEvent = os.pullEvent
local event_count = 0
os.pullEvent = function()
    event_count = event_count + 1
    if event_count == 1 then
        -- Simulate discovery response
        return "rednet_message", 20, {
            type = "discover_response",
            service = "control_computer",
            info = {name = "Main Control"},
            distance = 50
        }, "ULTIMATE_MINER_V2"
    else
        -- Simulate timeout
        return "timer", 1
    end
end

local services = Network.discover("control_computer", 1)
assert_not_nil(services, "Should return services list")
assert_equals(1, #services, "Should find one service")
assert_equals(20, services[1].id, "Should have correct service ID")

os.pullEvent = old_pullEvent

-- Test Heartbeat System
print("\nTesting Heartbeat System...")

-- Test 16: Heartbeat should be active after connect
broadcast_messages = {}
sent_messages = {}

-- Simulate timer event for heartbeat
event_count = 0
os.pullEvent = function()
    event_count = event_count + 1
    if event_count == 1 then
        return "timer", 1  -- Heartbeat timer
    end
    return nil
end

-- This should trigger a heartbeat
Core.emit("timer", 1)

-- Restore pullEvent
os.pullEvent = old_pullEvent

-- Check that heartbeat was sent
assert_true(#sent_messages > 0 or #broadcast_messages > 0, "Should send heartbeat")

-- Test Edge Cases
print("\nTesting Edge Cases...")

-- Test 17: Receive timeout
local success, data = Network.receive(0.1)
assert_false(success, "Should timeout when no messages")

-- Test 18: Send without connection
Network.disconnect()
success = Network.sendStatus({test = "data"})
assert_false(success, "Should fail to send status when disconnected")

-- Test 19: Custom protocol
Network.shutdown()
success = Network.init("CUSTOM_PROTOCOL")
assert_true(success, "Should initialize with custom protocol")
local stats = Network.getStats()
assert_equals("CUSTOM_PROTOCOL", stats.protocol, "Should use custom protocol")

-- Test Shutdown
print("\nTesting Shutdown...")

-- Test 20: Shutdown network
success = Network.shutdown()
assert_true(success, "Should shutdown successfully")
assert_false(rednet_open, "Should close rednet")

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