-- Test script for Config module
-- Run this in a turtle to verify configuration functionality

-- Add module path
package.path = package.path .. ";/turtle/modules/?.lua;/?.lua"

local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local CONSTANTS = require("shared.constants")

-- Initialize dependencies
Core.init({debug = true})
State.init("test_state.dat")

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

-- Clean up any existing config files
local function cleanup()
    if fs.exists("turtle_config.cfg") then
        fs.delete("turtle_config.cfg")
    end
    if fs.exists("turtle_config_test.cfg") then
        fs.delete("turtle_config_test.cfg")
    end
    if fs.exists("test_state.dat") then
        fs.delete("test_state.dat")
    end
end

-- Start tests
print("=== Config Module Tests ===")

-- Clean start
cleanup()

-- Test initialization
test("Config initialization", function()
    local success, msg = Config.init("turtle_config_test.cfg")
    assert(success, "Config init failed: " .. tostring(msg))
end)

-- Test get with defaults
test("Get with defaults", function()
    -- Get existing default
    local safety_radius = Config.get("safety_radius")
    assert(safety_radius == CONSTANTS.DEFAULTS.SAFETY_RADIUS, "Default value not returned")
    
    -- Get with custom default
    local custom = Config.get("nonexistent", "custom_default")
    assert(custom == "custom_default", "Custom default not returned")
    
    -- Get all config
    local all_config = Config.get()
    assert(type(all_config) == "table", "Get all config failed")
end)

-- Test set and validation
test("Set with validation", function()
    -- Set valid number
    local success = Config.set("torch_interval", 10)
    assert(success, "Valid set failed")
    assert(Config.get("torch_interval") == 10, "Value not set correctly")
    
    -- Try to set invalid type
    success = Config.set("torch_interval", "not a number")
    assert(not success, "Invalid type was accepted")
    
    -- Try to set out of range
    success = Config.set("torch_interval", 100)
    assert(not success, "Out of range value was accepted")
    
    -- Set boolean
    success = Config.set("debug_mode", true)
    assert(success, "Boolean set failed")
end)

-- Test convenience functions
test("Convenience functions", function()
    Config.set("debug_mode", true)
    assert(Config.isDebugMode() == true, "isDebugMode failed")
    
    Config.set("safety_radius", 200)
    assert(Config.getSafetyRadius() == 200, "getSafetyRadius failed")
    
    assert(type(Config.getFuelReserve()) == "number", "getFuelReserve failed")
    assert(type(Config.getEmergencyFuel()) == "number", "getEmergencyFuel failed")
end)

-- Test save/load
test("Save and load", function()
    -- Set some custom values
    Config.set("safety_radius", 150)
    Config.set("debug_mode", true)
    Config.set("strip_spacing", 4)
    
    -- Save
    local success = Config.save()
    assert(success, "Save failed")
    assert(fs.exists("turtle_config_test.cfg"), "Config file not created")
    
    -- Reset to defaults
    Config.reset()
    assert(Config.get("safety_radius") == CONSTANTS.DEFAULTS.SAFETY_RADIUS, "Reset failed")
    
    -- Load
    success = Config.load()
    assert(success, "Load failed")
    
    -- Verify loaded values
    assert(Config.get("safety_radius") == 150, "Loaded value incorrect")
    assert(Config.get("debug_mode") == true, "Loaded boolean incorrect")
    assert(Config.get("strip_spacing") == 4, "Loaded number incorrect")
end)

-- Test merge
test("Config merge", function()
    local new_config = {
        safety_radius = 300,
        fuel_reserve = 1000,
        invalid_key = "should warn"
    }
    
    local success, errors = Config.merge(new_config)
    assert(success, "Merge failed")
    assert(Config.get("safety_radius") == 300, "Merge didn't update value")
    assert(Config.get("fuel_reserve") == 1000, "Merge didn't update second value")
end)

-- Test schema
test("Schema operations", function()
    local schema = Config.getSchema()
    assert(type(schema) == "table", "Get schema failed")
    assert(schema.safety_radius ~= nil, "Schema missing default key")
    
    -- Add custom schema entry
    Config.setSchema({
        custom_setting = {
            type = "string",
            default = "test",
            description = "Custom test setting"
        }
    })
    
    -- Should now accept the custom setting
    local success = Config.set("custom_setting", "custom_value")
    assert(success, "Custom schema setting failed")
end)

-- Test validation
test("Config validation", function()
    -- Current config should be valid
    local valid, errors = Config.validate()
    assert(valid, "Valid config failed validation")
    
    -- Force an invalid value (bypass set validation)
    local all_config = Config.get()
    all_config.safety_radius = -100  -- Invalid!
    
    -- This would fail validation if we could set it directly
end)

-- Test export/import
test("Export and import", function()
    -- Set some values
    Config.set("safety_radius", 250)
    Config.set("debug_mode", false)
    
    -- Export
    local export_string = Config.export()
    assert(type(export_string) == "string", "Export failed")
    
    -- Reset
    Config.reset()
    assert(Config.get("safety_radius") == CONSTANTS.DEFAULTS.SAFETY_RADIUS, "Reset before import failed")
    
    -- Import
    local success = Config.import(export_string)
    assert(success, "Import failed")
    assert(Config.get("safety_radius") == 250, "Imported value incorrect")
end)

-- Test change handlers
test("Change handlers", function()
    local handler_called = false
    local received_key = nil
    local received_value = nil
    
    -- Register handler
    Config.onChange("safety_.*", function(key, value)
        handler_called = true
        received_key = key
        received_value = value
    end)
    
    -- Change a matching config
    Config.set("safety_radius", 175)
    
    -- Give event time to process
    os.sleep(0.1)
    
    assert(handler_called, "Change handler not called")
    assert(received_key == "safety_radius", "Wrong key received")
    assert(received_value == 175, "Wrong value received")
end)

-- Test table configs
test("Table configuration values", function()
    -- Test ore priority (table value)
    local ore_priority = Config.get("ore_priority")
    assert(type(ore_priority) == "table", "Table config not returned")
    assert(#ore_priority > 0, "Ore priority empty")
    assert(ore_priority[1] == "diamond", "Ore priority order wrong")
    
    -- Set new priority
    local new_priority = {"emerald", "diamond", "gold"}
    Config.set("ore_priority", new_priority)
    
    local updated = Config.get("ore_priority")
    assert(updated[1] == "emerald", "Table config not updated")
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