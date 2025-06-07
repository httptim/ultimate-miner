-- Test script for Core module
-- Run this in a turtle to verify core functionality

-- Add module path
package.path = package.path .. ";/turtle/modules/?.lua;/?.lua"

local Core = require("turtle.modules.core")
local CONSTANTS = require("shared.constants")

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

-- Start tests
print("=== Core Module Tests ===")

-- Test initialization
test("Core initialization", function()
    local success, msg = Core.init({debug = true})
    assert(success, "Core init failed: " .. tostring(msg))
end)

-- Test logging
test("Logging functions", function()
    Core.debug("Debug message")
    Core.info("Info message")
    Core.warning("Warning message")
    Core.error("Error message")
    Core.critical("Critical message")
    -- If we get here without crashing, logging works
end)

-- Test event system
test("Event system", function()
    local event_fired = false
    local event_data = nil
    
    -- Register handler
    local handler_id = Core.on("test.event", function(data)
        event_fired = true
        event_data = data
    end)
    
    assert(handler_id, "Handler registration failed")
    
    -- Emit event
    Core.emit("test.event", {test = true})
    
    -- Give event time to process
    os.sleep(0.1)
    
    assert(event_fired, "Event not fired")
    assert(event_data and event_data.test, "Event data not received")
    
    -- Test unregistering
    local removed = Core.off("test.event", handler_id)
    assert(removed, "Handler removal failed")
end)

-- Test vector operations
test("Vector operations", function()
    local v1 = Core.vector.new(1, 2, 3)
    local v2 = Core.vector.new(4, 5, 6)
    
    -- Test addition
    local v3 = Core.vector.add(v1, v2)
    assert(v3.x == 5 and v3.y == 7 and v3.z == 9, "Vector addition failed")
    
    -- Test subtraction
    local v4 = Core.vector.subtract(v2, v1)
    assert(v4.x == 3 and v4.y == 3 and v4.z == 3, "Vector subtraction failed")
    
    -- Test distance
    local dist = Core.vector.distance(v1, v2)
    assert(math.abs(dist - 5.196) < 0.01, "Distance calculation failed")
    
    -- Test Manhattan distance
    local manhattan = Core.vector.manhattan(v1, v2)
    assert(manhattan == 9, "Manhattan distance failed")
    
    -- Test equals
    local v5 = Core.vector.new(1, 2, 3)
    assert(Core.vector.equals(v1, v5), "Vector equals failed")
end)

-- Test utility functions
test("Table utilities", function()
    local tbl = {1, 2, 3, "hello"}
    assert(Core.tableContains(tbl, "hello"), "tableContains failed")
    assert(not Core.tableContains(tbl, "world"), "tableContains false positive")
    
    -- Test deep copy
    local original = {a = 1, b = {c = 2, d = {e = 3}}}
    local copy = Core.deepCopy(original)
    copy.b.c = 99
    assert(original.b.c == 2, "Deep copy modified original")
    assert(copy.b.c == 99, "Deep copy didn't work")
    
    -- Test merge tables
    local base = {a = 1, b = 2}
    local override = {b = 3, c = 4}
    local merged = Core.mergeTables(base, override)
    assert(merged.a == 1 and merged.b == 3 and merged.c == 4, "Merge tables failed")
end)

-- Test math utilities
test("Math utilities", function()
    assert(Core.clamp(5, 0, 10) == 5, "Clamp middle failed")
    assert(Core.clamp(-5, 0, 10) == 0, "Clamp min failed")
    assert(Core.clamp(15, 0, 10) == 10, "Clamp max failed")
    
    assert(Core.round(3.14159, 2) == 3.14, "Round failed")
    assert(Core.round(3.5) == 4, "Round integer failed")
end)

-- Test ID generation
test("ID generation", function()
    local id1 = Core.generateId("test")
    local id2 = Core.generateId("test")
    assert(id1 ~= id2, "Generated IDs not unique")
    assert(string.find(id1, "test_"), "ID prefix not applied")
end)

-- Test error handling
test("Error handling", function()
    local success, result = Core.try(function()
        return 42
    end)
    assert(success and result == 42, "Try with success failed")
    
    local success2, err = Core.try(function()
        error("Test error")
    end)
    assert(not success2, "Try with error didn't fail")
    assert(string.find(err, "Test error"), "Error message not preserved")
end)

-- Test circular buffer
test("Circular buffer", function()
    local buffer = Core.createCircularBuffer(3)
    
    buffer:add("a")
    buffer:add("b")
    buffer:add("c")
    buffer:add("d")  -- Should overwrite "a"
    
    assert(buffer:get(1) == "b", "Circular buffer item 1 wrong")
    assert(buffer:get(2) == "c", "Circular buffer item 2 wrong")
    assert(buffer:get(3) == "d", "Circular buffer item 3 wrong")
    assert(buffer:getLast() == "d", "Circular buffer getLast wrong")
    
    local array = buffer:toArray()
    assert(#array == 3, "Circular buffer array size wrong")
end)

-- Test error messages
test("Error messages", function()
    local msg = Core.getErrorMessage(CONSTANTS.ERRORS.NO_FUEL)
    assert(msg == "no fuel", "Error message lookup failed")
    
    local error_obj = Core.makeError(CONSTANTS.ERRORS.NO_FUEL, "Tank empty")
    assert(not error_obj.success, "Error object success wrong")
    assert(error_obj.error_code == CONSTANTS.ERRORS.NO_FUEL, "Error code wrong")
    assert(error_obj.details == "Tank empty", "Error details wrong")
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
Core.shutdown()