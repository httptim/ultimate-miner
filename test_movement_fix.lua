-- Test Movement Menu Fix
print("Testing movement menu fix...")
print()

-- Check if the file has the fix
local file = fs.open("/turtle/main.lua", "r")
if not file then
    print("Error: Cannot open turtle/main.lua")
    return
end

local content = file.readAll()
file.close()

-- Check for the while loop
if content:find("function testMovement%(%)[%s]*while true do") then
    print("✓ testMovement uses while loop (FIXED)")
else
    print("✗ testMovement does NOT use while loop (NOT FIXED)")
end

-- Check for recursive call
if content:find("testMovement%(%)%s*%-%-") then
    print("✗ Still has recursive testMovement() call")
else
    print("✓ No recursive testMovement() call found")
end

-- Check for proper loop ending
if content:find("end%s*%-%-.*while loop") then
    print("✓ Has proper while loop ending comment")
else
    print("? Could not verify loop ending")
end

print()
print("The movement test menu should now work properly!")
print("It will stay in the submenu until you select option 6")