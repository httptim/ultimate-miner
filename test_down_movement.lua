-- Test why turtle can't move down
print("=== Down Movement Test ===")
print()

-- Test 1: Current position
print("1. Current Y position:")
local x, y, z = gps.locate(5)
if x then
    print("   GPS Y: " .. y)
else
    print("   No GPS available")
end

-- Test 2: Direct turtle.down()
print("\n2. Testing direct turtle.down():")
local success, err = turtle.down()
if success then
    print("   ✓ Turtle moved down successfully")
    turtle.up() -- Move back up
else
    print("   ✗ Failed: " .. tostring(err))
end

-- Test 3: Check fuel
print("\n3. Fuel level: " .. turtle.getFuelLevel())

-- Test 4: Check Navigation module
print("\n4. Testing Navigation module:")
-- Load constants
local CONSTANTS = require("shared.constants")
print("   MIN_SAFE_Y: " .. CONSTANTS.LIMITS.MIN_SAFE_Y)
print("   MAX_SAFE_Y: " .. CONSTANTS.LIMITS.MAX_SAFE_Y)

-- Test 5: Check what's below
print("\n5. Checking block below:")
local has_block, data = turtle.inspectDown()
if has_block then
    print("   Block below: " .. data.name)
else
    print("   No block below (air or void)")
end

-- Test 6: Try to load Navigation and check position
print("\n6. Navigation module test:")
local ok = pcall(function()
    local Navigation = require("turtle.modules.navigation")
    if Navigation.getPosition then
        local pos = Navigation.getPosition()
        print("   Navigation Y: " .. (pos and pos.y or "unknown"))
        
        -- Check if safety is blocking
        if pos and pos.y <= -64 then
            print("   ⚠ At or below MIN_SAFE_Y limit!")
        end
    end
end)
if not ok then
    print("   Could not load Navigation module")
end

print("\n=== Diagnosis ===")
if y and y <= -64 then
    print("The turtle is at Y=" .. y .. ", which is at or below the")
    print("safety limit of Y=-64. The Navigation module prevents")
    print("movement below this level for safety.")
    print("\nTo fix: Move the turtle up to Y > -64")
elseif not success then
    print("Direct turtle.down() failed, suggesting a physical block")
    print("or bedrock is preventing movement.")
else
    print("Check the error messages above for the cause.")
end