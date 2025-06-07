-- Test script for State module
-- Run this in a turtle to verify state persistence functionality

-- Add module path
package.path = package.path .. ";/turtle/modules/?.lua;/?.lua"

local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local CONSTANTS = require("shared.constants")

-- Initialize Core first
Core.init({debug = true})

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

-- Clean up any existing state files
local function cleanup()
    if fs.exists("turtle_state.dat") then
        fs.delete("turtle_state.dat")
    end
    if fs.exists("turtle_state_test.dat") then
        fs.delete("turtle_state_test.dat")
    end
    if fs.exists("backups") then
        fs.delete("backups")
    end
end

-- Start tests
print("=== State Module Tests ===")

-- Clean start
cleanup()

-- Test initialization
test("State initialization", function()
    local success, msg = State.init("turtle_state_test.dat")
    assert(success, "State init failed: " .. tostring(msg))
end)

-- Test basic get/set
test("Basic get/set operations", function()
    -- Set simple value
    State.set("test_value", 42)
    assert(State.get("test_value") == 42, "Simple get/set failed")
    
    -- Set nested value
    State.set("nested.value", "hello")
    assert(State.get("nested.value") == "hello", "Nested get/set failed")
    
    -- Test default values
    assert(State.get("nonexistent", "default") == "default", "Default value failed")
    
    -- Delete value
    State.delete("test_value")
    assert(State.get("test_value") == nil, "Delete failed")
end)

-- Test position management
test("Position management", function()
    local pos = {x = 10, y = 64, z = -20, facing = CONSTANTS.DIRECTIONS.NORTH}
    State.setPosition(pos)
    
    local retrieved = State.getPosition()
    assert(retrieved.x == 10, "Position x incorrect")
    assert(retrieved.y == 64, "Position y incorrect")
    assert(retrieved.z == -20, "Position z incorrect")
    assert(retrieved.facing == CONSTANTS.DIRECTIONS.NORTH, "Position facing incorrect")
end)

-- Test counters
test("Counter operations", function()
    State.set("blocks_mined", 0)
    
    State.incrementCounter("blocks_mined")
    assert(State.get("blocks_mined") == 1, "Increment by 1 failed")
    
    State.incrementCounter("blocks_mined", 5)
    assert(State.get("blocks_mined") == 6, "Increment by 5 failed")
end)

-- Test history management
test("History management", function()
    -- Add items to history
    for i = 1, 5 do
        State.addToHistory("test_history", "item" .. i, 3)
    end
    
    local history = State.get("test_history")
    assert(#history == 3, "History max size not enforced")
    assert(history[1] == "item3", "History item 1 wrong")
    assert(history[2] == "item4", "History item 2 wrong")
    assert(history[3] == "item5", "History item 3 wrong")
end)

-- Test save/load
test("Save and load", function()
    -- Set some test data
    State.set("save_test", "test_data")
    State.set("save_number", 123)
    State.set("save_table", {a = 1, b = 2})
    
    -- Save
    local success, msg = State.save()
    assert(success, "Save failed: " .. tostring(msg))
    
    -- Verify file exists
    assert(fs.exists("turtle_state_test.dat"), "State file not created")
    
    -- Clear current state
    State.reset()
    assert(State.get("save_test") == nil, "Reset didn't clear state")
    
    -- Load
    success, loaded = State.load()
    assert(success, "Load failed")
    
    -- Verify loaded data
    assert(State.get("save_test") == "test_data", "String not loaded correctly")
    assert(State.get("save_number") == 123, "Number not loaded correctly")
    local table_data = State.get("save_table")
    assert(table_data.a == 1 and table_data.b == 2, "Table not loaded correctly")
end)

-- Test backup functionality
test("Backup system", function()
    -- Create a backup
    local success, backup_file = State.backup()
    assert(success, "Backup failed")
    assert(fs.exists(backup_file), "Backup file not created")
    
    -- Modify state
    State.set("backup_test", "modified")
    State.save()
    
    -- Restore from backup
    success = State.restore()
    assert(success, "Restore failed")
    
    -- Check that state was restored
    assert(State.get("backup_test") ~= "modified", "Restore didn't revert changes")
end)

-- Test validation
test("State validation", function()
    local valid_state = {
        version = 1,
        position = {x = 0, y = 0, z = 0, facing = 0},
        fuel_used = 100,
        blocks_mined = 50
    }
    
    local valid, msg = State.validateState(valid_state)
    assert(valid, "Valid state failed validation: " .. tostring(msg))
    
    local invalid_state = {
        version = 1,
        position = "not a position"
    }
    
    valid, msg = State.validateState(invalid_state)
    assert(not valid, "Invalid state passed validation")
end)

-- Test auto-save
test("Auto-save functionality", function()
    -- Enable auto-save with short interval
    State.enableAutoSave(1)
    
    -- Make a change
    State.set("auto_save_test", os.epoch("utc"))
    
    -- Wait for auto-save
    os.sleep(1.5)
    
    -- Load and check
    local saved_time = State.get("last_save")
    assert(saved_time > 0, "Auto-save didn't update last_save time")
    
    -- Disable auto-save
    State.disableAutoSave()
end)

-- Test error handling
test("Error handling", function()
    -- Test save with invalid path
    local old_file = "turtle_state_test.dat"
    State.init("/invalid/path/state.dat")
    local success = State.save()
    -- Should handle gracefully
    
    -- Restore valid path
    State.init(old_file)
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