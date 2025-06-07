-- Syntax Verification Script for Ultimate Miner (Standard Lua)
-- Checks all Lua files for common syntax issues

print("=== Ultimate Miner Syntax Verification ===")
print("Checking for Lua 5.2+ features not supported in CC:Tweaked...")
print("")

local issues_found = 0

-- Function to check a file for syntax issues
local function checkFile(filepath)
    local file = io.open(filepath, "r")
    if not file then
        print("[ERROR] Cannot open: " .. filepath)
        return false
    end
    
    local content = file:read("*all")
    file:close()
    
    local line_num = 0
    local has_issues = false
    
    -- Check each line
    for line in content:gmatch("[^\n]+") do
        line_num = line_num + 1
        
        -- Check for continue statement (standalone word)
        if line:match("%bcontinue%s") or line:match("%bcontinue$") or line:match("%bcontinue%)") then
            print("[ISSUE] " .. filepath .. ":" .. line_num .. " - Found 'continue' statement")
            has_issues = true
            issues_found = issues_found + 1
        end
        
        -- Check for goto statement
        if line:match("%bgoto%s+%w+") then
            print("[ISSUE] " .. filepath .. ":" .. line_num .. " - Found 'goto' statement")
            has_issues = true
            issues_found = issues_found + 1
        end
        
        -- Check for labels (::label::)
        if line:match("::[%w_]+::") then
            print("[ISSUE] " .. filepath .. ":" .. line_num .. " - Found label (::)")
            has_issues = true
            issues_found = issues_found + 1
        end
        
        -- Check for 0x hex literals (not supported in Lua 5.1)
        if line:match("0x[0-9a-fA-F]+") then
            print("[WARNING] " .. filepath .. ":" .. line_num .. " - Found hex literal (may not work)")
        end
    end
    
    if not has_issues then
        print("[OK] " .. filepath)
    end
    
    return not has_issues
end

-- Helper to check if file exists
local function file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

-- Get the base directory
local base_dir = arg[0]:match("(.*[/\\])") or "./"
if base_dir:match("verify_syntax_standard%.lua$") then
    base_dir = base_dir:gsub("verify_syntax_standard%.lua$", "")
end

-- List of all Lua files to check
local files_to_check = {
    -- Shared modules
    "shared/constants.lua",
    "shared/circular_buffer.lua",
    "shared/code_optimizer.lua",
    "shared/module_loader.lua",
    
    -- Turtle modules
    "turtle/main.lua",
    "turtle/modules/core.lua",
    "turtle/modules/state.lua",
    "turtle/modules/config.lua",
    "turtle/modules/navigation.lua",
    "turtle/modules/inventory.lua",
    "turtle/modules/mining.lua",
    "turtle/modules/safety.lua",
    "turtle/modules/storage.lua",
    "turtle/modules/network.lua",
    "turtle/modules/optimization.lua",
    "turtle/modules/targeting.lua",
    "turtle/modules/area.lua",
    "turtle/modules/smart_mining.lua",
    "turtle/modules/monitoring.lua",
    "turtle/modules/integrity.lua",
    "turtle/modules/alerts.lua",
    "turtle/modules/cancellation.lua",
    "turtle/modules/diagnostics.lua",
    "turtle/modules/memory_optimizer.lua",
    "turtle/modules/network_optimizer.lua",
    "turtle/modules/pattern_optimizer.lua",
    "turtle/modules/performance_config.lua",
    "turtle/modules/patterns.lua",
    "turtle/patterns/strip.lua",
    
    -- Control modules
    "control/main.lua",
    "control/modules/core.lua",
    "control/modules/network.lua",
    "control/modules/fleet.lua",
    "control/modules/commands.lua",
    "control/modules/ui.lua",
    "control/modules/tasks.lua",
    "control/modules/monitor.lua",
    "control/modules/config.lua",
    
    -- Control screens
    "control/screens/dashboard.lua",
    "control/screens/fleet_overview.lua",
    "control/screens/turtle_control.lua",
    "control/screens/fleet_commands.lua",
    "control/screens/task_assignment.lua",
    "control/screens/settings.lua",
    
    -- Other files
    "installer.lua",
    "startup.lua"
}

print("Checking " .. #files_to_check .. " files...")
print("")

-- Check all files
local success_count = 0
local checked_count = 0
for _, filepath in ipairs(files_to_check) do
    local full_path = base_dir .. filepath
    if file_exists(full_path) then
        if checkFile(full_path) then
            success_count = success_count + 1
        end
        checked_count = checked_count + 1
    else
        print("[SKIP] " .. filepath .. " (file not found)")
    end
end

print("")
print("=== Summary ===")
print("Files found: " .. checked_count .. " / " .. #files_to_check)
print("Files OK: " .. success_count)
print("Issues found: " .. issues_found)
print("")

if issues_found == 0 then
    print("✓ No syntax issues found!")
    print("✓ All files should be compatible with CC:Tweaked")
else
    print("✗ Found " .. issues_found .. " syntax issues that need fixing")
    print("✗ Please fix these issues before running the program")
end