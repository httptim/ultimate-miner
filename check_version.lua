-- Version Check Script
-- Checks if the installed files have the latest fixes

print("=== Ultimate Miner Version Check ===")
print()

local issues = 0

-- Check 1: Monitoring module
print("1. Checking monitoring.lua...")
if fs.exists("/turtle/modules/monitoring.lua") then
    local file = fs.open("/turtle/modules/monitoring.lua", "r")
    local content = file.readAll()
    file.close()
    
    if content:find("schedule_repeating_task") then
        print("   ✗ OLD VERSION - Still has schedule_repeating_task")
        print("     Line 94 should not call Core.schedule_repeating_task")
        issues = issues + 1
    else
        print("   ✓ UPDATED - No schedule_repeating_task found")
    end
    
    if content:find("function Monitoring%.tick") then
        print("   ✓ Has tick function")
    else
        print("   ✗ Missing tick function")
        issues = issues + 1
    end
else
    print("   ✗ File not found")
    issues = issues + 1
end

-- Check 2: Memory optimizer
print("\n2. Checking memory_optimizer.lua...")
if fs.exists("/turtle/modules/memory_optimizer.lua") then
    local file = fs.open("/turtle/modules/memory_optimizer.lua", "r")
    local content = file.readAll()
    file.close()
    
    if content:find('collectgarbage%("collect"%)') or content:find('collectgarbage%("count"%)') then
        print("   ✗ OLD VERSION - Still uses collectgarbage")
        issues = issues + 1
    else
        print("   ✓ UPDATED - No collectgarbage calls")
    end
else
    print("   ✗ File not found")
    issues = issues + 1
end

-- Check 3: Main turtle program
print("\n3. Checking turtle/main.lua...")
if fs.exists("/turtle/main.lua") then
    local file = fs.open("/turtle/main.lua", "r")
    local content = file.readAll()
    file.close()
    
    if content:find("function runTicks") then
        print("   ✓ Has runTicks function")
    else
        print("   ✗ Missing runTicks function")
        issues = issues + 1
    end
    
    if content:find("parallel%.waitForAny") then
        print("   ✓ Uses parallel execution")
    else
        print("   ✗ Not using parallel execution")
        issues = issues + 1
    end
else
    print("   ✗ File not found")
    issues = issues + 1
end

-- Check 4: Error handler
print("\n4. Checking error handling...")
if fs.exists("/shared/error_handler.lua") then
    print("   ✓ Error handler exists")
else
    print("   ✗ Error handler missing")
    issues = issues + 1
end

-- Summary
print("\n=== Summary ===")
if issues == 0 then
    print("✓ All files appear to be updated!")
    print("✓ You have the latest version")
else
    print("✗ Found " .. issues .. " issues")
    print("✗ You appear to have old files")
    print()
    print("To fix:")
    print("1. Run: lua clean_install.lua")
    print("2. Or manually: rm -rf turtle control shared")
    print("3. Then run the installer again")
end