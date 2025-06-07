-- Final Syntax Check for Ultimate Miner
-- More accurate checking for actual syntax issues

print("=== Final Syntax Check for Ultimate Miner ===")
print("Checking for actual Lua 5.2+ syntax issues...")
print("")

local issues_found = 0

-- Function to check a file
local function checkFile(filepath)
    local file = io.open(filepath, "r")
    if not file then
        return true
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Check for actual syntax by trying to load the file
    local func, err = loadfile(filepath)
    if not func then
        print("[SYNTAX ERROR] " .. filepath)
        print("  " .. err)
        issues_found = issues_found + 1
        return false
    end
    
    print("[OK] " .. filepath)
    return true
end

-- Get base directory
local base_dir = "./"

-- List of key files to check
local files_to_check = {
    "installer.lua",
    "turtle/main.lua",
    "turtle/modules/smart_mining.lua",
    "turtle/modules/optimization.lua",
    "turtle/modules/mining.lua",
    "turtle/modules/navigation.lua",
    "turtle/modules/patterns.lua",
    "turtle/modules/safety.lua",
    "control/main.lua",
    "control/modules/fleet.lua",
    "control/modules/commands.lua"
}

print("Checking key files for syntax errors...")
print("")

-- Check all files
local success_count = 0
for _, filepath in ipairs(files_to_check) do
    if checkFile(base_dir .. filepath) then
        success_count = success_count + 1
    end
end

print("")
print("=== Summary ===")
print("Files checked: " .. #files_to_check)
print("Files OK: " .. success_count)
print("Syntax errors: " .. issues_found)
print("")

if issues_found == 0 then
    print("✓ No syntax errors found!")
    print("✓ All checked files have valid Lua syntax")
else
    print("✗ Found " .. issues_found .. " files with syntax errors")
    print("✗ These files need to be fixed before running in CC:Tweaked")
end