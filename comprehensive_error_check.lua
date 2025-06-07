-- Comprehensive Error Check for Ultimate Miner
print("=== Ultimate Miner Comprehensive Error Check ===")
print()

local errors_found = 0
local warnings_found = 0

-- Helper function to check file
local function checkFile(path, checks)
    print("Checking " .. path .. "...")
    
    if not fs.exists(path) then
        print("  ✗ File not found!")
        errors_found = errors_found + 1
        return
    end
    
    local file = fs.open(path, "r")
    local content = file.readAll()
    file.close()
    
    for _, check in ipairs(checks) do
        if check.type == "error" then
            if content:find(check.pattern) then
                print("  ✗ ERROR: " .. check.message)
                errors_found = errors_found + 1
            elseif check.inverse then
                print("  ✓ " .. check.message)
            end
        elseif check.type == "warning" then
            if content:find(check.pattern) then
                print("  ⚠ WARNING: " .. check.message)
                warnings_found = warnings_found + 1
            end
        elseif check.type == "required" then
            if not content:find(check.pattern) then
                print("  ✗ ERROR: Missing " .. check.message)
                errors_found = errors_found + 1
            else
                print("  ✓ Has " .. check.message)
            end
        end
    end
end

-- Check 1: Core scheduling functions that don't exist
print("\n1. Checking for non-existent Core functions...")
checkFile("/turtle/modules/monitoring.lua", {
    {type = "error", pattern = "Core%.schedule_repeating_task", message = "Still has Core.schedule_repeating_task"},
    {type = "required", pattern = "function Monitoring%.tick", message = "tick function"}
})

checkFile("/turtle/modules/alerts.lua", {
    {type = "error", pattern = "Core%.schedule_repeating_task", message = "Still has Core.schedule_repeating_task"},
    {type = "required", pattern = "function Alerts%.tick", message = "tick function"}
})

checkFile("/turtle/modules/cancellation.lua", {
    {type = "error", pattern = "Core%.schedule_repeating_task", message = "Still has Core.schedule_repeating_task"},
    {type = "required", pattern = "function Cancellation%.tick", message = "tick function"}
})

-- Check 2: collectgarbage usage
print("\n2. Checking for collectgarbage usage...")
local files_with_collectgarbage = {
    "/turtle/modules/memory_optimizer.lua",
    "/turtle/modules/diagnostics.lua",
    "/shared/error_reporter.lua"
}

for _, path in ipairs(files_with_collectgarbage) do
    checkFile(path, {
        {type = "error", pattern = "collectgarbage%s*%(", message = "Still uses collectgarbage"}
    })
end

-- Check 3: State.load vs State.loadFile
print("\n3. Checking State.load usage...")
checkFile("/turtle/modules/monitoring.lua", {
    {type = "error", pattern = "State%.load%(\"monitoring\"", message = "Uses State.load instead of State.loadFile"},
    {type = "required", pattern = "State%.loadFile", message = "State.loadFile usage"}
})

-- Check 4: Menu recursion issues
print("\n4. Checking for menu recursion...")
checkFile("/turtle/main.lua", {
    {type = "warning", pattern = "testMovement%(%)%s*%-%-.*menu", message = "testMovement recursive call"},
    {type = "warning", pattern = "startMining%(%)%s*%-%-.*menu", message = "startMining recursive call"},
    {type = "required", pattern = "local ticks_enabled", message = "tick control flag"},
    {type = "required", pattern = "while true do.*Movement Test", message = "testMovement while loop"}
})

-- Check 5: Installer device type issue
print("\n5. Checking installer...")
checkFile("/installer.lua", {
    {type = "required", pattern = "if install_type == \"computer\" then", message = "computer to control conversion"}
})

-- Check 6: Invalid Lua syntax
print("\n6. Checking for invalid Lua syntax...")
local syntax_patterns = {
    {pattern = "%bcontinue%s", message = "continue statement"},
    {pattern = "%bgoto%s+", message = "goto statement"},
    {pattern = "::[%w_]+::", message = "label syntax"},
    {pattern = "!=[^=]", message = "!= operator (should be ~=)"}
}

local files_to_syntax_check = {
    "/turtle/main.lua",
    "/turtle/modules/mining.lua",
    "/turtle/modules/navigation.lua",
    "/turtle/modules/optimization.lua",
    "/turtle/modules/patterns.lua",
    "/turtle/modules/smart_mining.lua"
}

for _, path in ipairs(files_to_syntax_check) do
    local checks = {}
    for _, pattern in ipairs(syntax_patterns) do
        table.insert(checks, {type = "error", pattern = pattern.pattern, message = pattern.message})
    end
    checkFile(path, checks)
end

-- Check 7: Error handling setup
print("\n7. Checking error handling...")
checkFile("/turtle/main.lua", {
    {type = "required", pattern = "ErrorHandler%.setupGlobalHandler", message = "error handler setup"},
    {type = "required", pattern = "local success, err = xpcall%(main", message = "main wrapped in xpcall"}
})

-- Summary
print("\n=== SUMMARY ===")
print("Errors found: " .. errors_found)
print("Warnings found: " .. warnings_found)

if errors_found == 0 and warnings_found == 0 then
    print("\n✅ All checks passed! System appears to be properly configured.")
else
    print("\n❌ Issues found. Please address the errors above.")
    print("\nCommon fixes:")
    print("1. Run: lua clean_install.lua")
    print("2. Or manually fix the specific issues listed above")
end