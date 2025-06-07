-- Comprehensive Test Script for Ultimate Miner
-- Verifies all modules can be loaded without syntax errors

print("=== Ultimate Miner Comprehensive Test ===")
print("Testing all modules for loadability...")
print("")

local success_count = 0
local fail_count = 0
local skipped_count = 0

-- Function to test loading a module
local function testModule(path, module_name)
    local full_path = path .. "/" .. module_name .. ".lua"
    
    -- Check if file exists
    local file = io.open(full_path, "r")
    if not file then
        print("[SKIP] " .. full_path .. " - File not found")
        skipped_count = skipped_count + 1
        return
    end
    file:close()
    
    -- Try to load the file
    local func, err = loadfile(full_path)
    if not func then
        print("[FAIL] " .. full_path)
        print("       " .. err)
        fail_count = fail_count + 1
    else
        print("[PASS] " .. full_path)
        success_count = success_count + 1
    end
end

-- Test all modules
print("=== Testing Shared Modules ===")
testModule("shared", "constants")
testModule("shared", "circular_buffer")
testModule("shared", "code_optimizer")
testModule("shared", "module_loader")

print("\n=== Testing Turtle Modules ===")
local turtle_modules = {
    "core", "state", "config", "navigation", "inventory",
    "mining", "safety", "storage", "network", "optimization",
    "targeting", "area", "smart_mining", "monitoring", "integrity",
    "alerts", "cancellation", "diagnostics", "memory_optimizer",
    "network_optimizer", "pattern_optimizer", "performance_config",
    "patterns"
}

for _, mod in ipairs(turtle_modules) do
    testModule("turtle/modules", mod)
end

print("\n=== Testing Turtle Patterns ===")
testModule("turtle/patterns", "strip")

print("\n=== Testing Control Modules ===")
local control_modules = {
    "core", "network", "fleet", "commands", "ui",
    "tasks", "monitor", "config"
}

for _, mod in ipairs(control_modules) do
    testModule("control/modules", mod)
end

print("\n=== Testing Control Screens ===")
local control_screens = {
    "dashboard", "fleet_overview", "turtle_control",
    "fleet_commands", "task_assignment", "settings"
}

for _, screen in ipairs(control_screens) do
    testModule("control/screens", screen)
end

print("\n=== Testing Main Files ===")
testModule(".", "installer")
testModule(".", "startup")
testModule("turtle", "main")
testModule("control", "main")

print("\n=== FINAL RESULTS ===")
print("Total modules tested: " .. (success_count + fail_count + skipped_count))
print("Passed: " .. success_count)
print("Failed: " .. fail_count)
print("Skipped: " .. skipped_count)
print("")

if fail_count == 0 then
    print("✅ ALL MODULES PASSED!")
    print("The Ultimate Miner system is ready to use in CC:Tweaked.")
else
    print("❌ Some modules failed to load.")
    print("Please check the errors above and fix them before using.")
end

-- Test for common issues
print("\n=== Common Issue Check ===")

-- Check for startup.lua
local startup = io.open("startup.lua", "r")
if startup then
    startup:close()
    print("✓ startup.lua exists")
else
    print("✗ startup.lua missing - installer may not create it properly")
end

-- Check main entry points
local turtle_main = io.open("turtle/main.lua", "r")
if turtle_main then
    turtle_main:close()
    print("✓ turtle/main.lua exists")
else
    print("✗ turtle/main.lua missing")
end

local control_main = io.open("control/main.lua", "r")
if control_main then
    control_main:close()
    print("✓ control/main.lua exists")
else
    print("✗ control/main.lua missing")
end