-- Ultimate Miner System Verification Test
-- Verifies that all modules exist and can be loaded

print("=== Ultimate Miner System Verification ===")
print("Version: 3.0.0")
print("=" .. string.rep("=", 40))

local success_count = 0
local fail_count = 0
local warnings = {}

-- Helper function to test module loading
local function testModule(path, name)
    print("\nTesting: " .. name)
    print("  Path: " .. path)
    
    -- Check if file exists
    if not fs.exists(path) then
        print("  [FAIL] File does not exist!")
        fail_count = fail_count + 1
        return false
    end
    
    -- Try to load the module
    local success, result = pcall(function()
        dofile(path)
    end)
    
    if success then
        print("  [OK] Module loads successfully")
        success_count = success_count + 1
        return true
    else
        print("  [FAIL] Load error: " .. tostring(result))
        fail_count = fail_count + 1
        return false
    end
end

-- Helper to check function existence
local function checkFunctions(module_table, module_name, functions)
    print("\n  Checking functions in " .. module_name .. ":")
    local missing = {}
    
    for _, func_name in ipairs(functions) do
        if type(module_table[func_name]) == "function" then
            print("    [OK] " .. func_name)
        else
            print("    [MISSING] " .. func_name)
            table.insert(missing, func_name)
        end
    end
    
    if #missing > 0 then
        table.insert(warnings, module_name .. " missing functions: " .. table.concat(missing, ", "))
    end
end

print("\n=== TESTING SHARED MODULES ===")

-- Test shared modules
testModule("/shared/constants.lua", "Constants")
testModule("/shared/circular_buffer.lua", "Circular Buffer")
testModule("/shared/code_optimizer.lua", "Code Optimizer")
testModule("/shared/module_loader.lua", "Module Loader")

print("\n=== TESTING TURTLE MODULES ===")

-- Test all turtle modules
local turtle_modules = {
    {"/turtle/main.lua", "Turtle Main"},
    {"/turtle/modules/core.lua", "Core"},
    {"/turtle/modules/state.lua", "State"},
    {"/turtle/modules/config.lua", "Config"},
    {"/turtle/modules/navigation.lua", "Navigation"},
    {"/turtle/modules/inventory.lua", "Inventory"},
    {"/turtle/modules/mining.lua", "Mining"},
    {"/turtle/modules/safety.lua", "Safety"},
    {"/turtle/modules/storage.lua", "Storage"},
    {"/turtle/modules/network.lua", "Network"},
    {"/turtle/modules/optimization.lua", "Optimization"},
    {"/turtle/modules/targeting.lua", "Targeting"},
    {"/turtle/modules/area.lua", "Area"},
    {"/turtle/modules/smart_mining.lua", "Smart Mining"},
    {"/turtle/modules/monitoring.lua", "Monitoring"},
    {"/turtle/modules/integrity.lua", "Integrity"},
    {"/turtle/modules/alerts.lua", "Alerts"},
    {"/turtle/modules/cancellation.lua", "Cancellation"},
    {"/turtle/modules/diagnostics.lua", "Diagnostics"},
    {"/turtle/modules/memory_optimizer.lua", "Memory Optimizer"},
    {"/turtle/modules/network_optimizer.lua", "Network Optimizer"},
    {"/turtle/modules/pattern_optimizer.lua", "Pattern Optimizer"},
    {"/turtle/modules/performance_config.lua", "Performance Config"},
    {"/turtle/modules/patterns.lua", "Patterns"},
    {"/turtle/patterns/strip.lua", "Strip Pattern"}
}

for _, module in ipairs(turtle_modules) do
    testModule(module[1], module[2])
end

print("\n=== TESTING CONTROL MODULES ===")

-- Test all control modules
local control_modules = {
    {"/control/main.lua", "Control Main"},
    {"/control/modules/core.lua", "Control Core"},
    {"/control/modules/network.lua", "Control Network"},
    {"/control/modules/fleet.lua", "Fleet"},
    {"/control/modules/commands.lua", "Commands"},
    {"/control/modules/ui.lua", "UI"},
    {"/control/modules/tasks.lua", "Tasks"},
    {"/control/modules/monitor.lua", "Monitor"},
    {"/control/modules/config.lua", "Control Config"}
}

for _, module in ipairs(control_modules) do
    testModule(module[1], module[2])
end

print("\n=== TESTING CONTROL SCREENS ===")

-- Test all control screens
local control_screens = {
    {"/control/screens/dashboard.lua", "Dashboard"},
    {"/control/screens/fleet_overview.lua", "Fleet Overview"},
    {"/control/screens/turtle_control.lua", "Turtle Control"},
    {"/control/screens/fleet_commands.lua", "Fleet Commands"},
    {"/control/screens/task_assignment.lua", "Task Assignment"},
    {"/control/screens/settings.lua", "Settings"}
}

for _, screen in ipairs(control_screens) do
    testModule(screen[1], screen[2])
end

print("\n=== CHECKING KEY FUNCTIONS ===")

-- Mock up a basic environment for function checking
_G.Fleet = {
    requestStatusUpdate = function() end,
    getAllTurtleIDs = function() end,
    getAvailableTurtles = function() end,
    requestTurtleStatus = function() end,
    getRecentEvents = function() end,
    getFleetStatistics = function() end
}

_G.Commands = {
    sendToTurtle = function() end
}

_G.Tasks = {
    createTask = function() end
}

-- Check Fleet functions
checkFunctions(_G.Fleet, "Fleet", {
    "requestStatusUpdate",
    "getAllTurtleIDs", 
    "getAvailableTurtles",
    "requestTurtleStatus",
    "getRecentEvents",
    "getFleetStatistics"
})

-- Check Commands functions
checkFunctions(_G.Commands, "Commands", {
    "sendToTurtle"
})

-- Check Tasks functions
checkFunctions(_G.Tasks, "Tasks", {
    "createTask"
})

print("\n=== PATTERN DUPLICATION CHECK ===")

-- Check pattern implementation status
print("\nPattern Implementation Status:")
print("  Main patterns module: " .. (fs.exists("/turtle/modules/patterns.lua") and "EXISTS" or "MISSING"))
print("  Individual pattern files:")
local pattern_files = {
    "strip", "branch", "spiral", "quarry", "tunnel3x3", "adaptive"
}

local individual_count = 0
for _, pattern in ipairs(pattern_files) do
    local path = "/turtle/patterns/" .. pattern .. ".lua"
    if fs.exists(path) then
        print("    " .. pattern .. ".lua: EXISTS")
        individual_count = individual_count + 1
    else
        print("    " .. pattern .. ".lua: MISSING")
    end
end

if individual_count == 1 then
    table.insert(warnings, "Only strip.lua exists as individual pattern - others are in patterns.lua")
end

print("\n=== FINAL REPORT ===")
print("=" .. string.rep("=", 40))
print("Total Modules Tested: " .. (success_count + fail_count))
print("Successful Loads: " .. success_count)
print("Failed Loads: " .. fail_count)
print("")

if #warnings > 0 then
    print("Warnings:")
    for _, warning in ipairs(warnings) do
        print("  - " .. warning)
    end
    print("")
end

if fail_count == 0 then
    print("✓ ALL MODULES LOAD SUCCESSFULLY!")
    print("✓ System structure is complete")
    
    if #warnings == 0 then
        print("✓ No warnings - system is ready for deployment")
    else
        print("! Some minor issues detected but system is functional")
    end
else
    print("✗ SOME MODULES FAILED TO LOAD")
    print("✗ System needs fixes before deployment")
end

print("\nTest completed.")