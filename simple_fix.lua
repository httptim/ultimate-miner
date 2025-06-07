-- Simple fix for the menu issue
-- The problem is likely the parallel tick runner interfering with read()

print("Simple fix for menu issue")
print()
print("The issue is that the background tick runner is interfering")
print("with the read() function in submenus.")
print()
print("Quick fix options:")
print()
print("1. Disable background ticks temporarily:")
print("   Comment out the parallel.waitForAny in main()")
print("   Just run the menu loop without ticks")
print()
print("2. Or run this command to start without ticks:")
print("   /turtle/main.lua --no-ticks")
print()
print("3. Or use this simple test movement function:")
print()

-- Create a simple test file
local test_content = [[
-- Simple movement test without interference
term.clear()
term.setCursorPos(1,1)
print("=== Simple Movement Test ===")
print()

-- Test GPS
print("Testing GPS...")
local ok, x, y, z = pcall(gps.locate, 5)
if ok and x then
    print("GPS: X=" .. math.floor(x) .. " Y=" .. math.floor(y) .. " Z=" .. math.floor(z))
else
    print("GPS not available")
end

print()
print("Done! Press any key...")
os.pullEvent("key")
]]

local file = fs.open("/test_gps_simple.lua", "w")
file.write(test_content)
file.close()

print("Created: /test_gps_simple.lua")
print()
print("This avoids the menu system entirely.")
print("Run it with: lua /test_gps_simple.lua")