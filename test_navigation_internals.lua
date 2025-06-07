-- Test Navigation internals
print("=== Navigation Internals Test ===")
print()

-- We'll need to patch the navigation module to expose checkMovementSafety
local Navigation = require("turtle.modules.navigation")
local CONSTANTS = require("shared.constants")

-- First, let's check current position
print("1. Current state:")
local pos = Navigation.getPosition()
print("   Position: " .. Navigation.formatPosition(pos))
print("   MIN_SAFE_Y: " .. CONSTANTS.LIMITS.MIN_SAFE_Y)
print()

-- Test the logic directly
print("2. Testing Y bounds logic:")
local test_cases = {
    {current = 65, direction = "down", expected = "allowed"},
    {current = -58, direction = "down", expected = "allowed"},
    {current = -59, direction = "down", expected = "blocked"},
    {current = 320, direction = "up", expected = "blocked"},
}

for _, test in ipairs(test_cases) do
    local future_y = test.current + (test.direction == "up" and 1 or -1)
    local blocked = false
    local reason = nil
    
    if future_y < CONSTANTS.LIMITS.MIN_SAFE_Y then
        blocked = true
        reason = "Below minimum safe Y level"
    elseif future_y > CONSTANTS.LIMITS.MAX_SAFE_Y then
        blocked = true
        reason = "Above maximum safe Y level"
    end
    
    local result = blocked and "blocked" or "allowed"
    local status = result == test.expected and "✓" or "✗"
    
    print(string.format("   %s Y=%d, %s: future=%d, result=%s (expected=%s)",
        status, test.current, test.direction, future_y, result, test.expected))
    
    if reason and blocked then
        print("      Reason: " .. reason)
    end
end

print()
print("3. Testing actual Navigation.down() behavior:")

-- Try to force position to Y=65 and test
local success = Navigation.setManualPosition(pos.x, 65, pos.z, pos.facing)
print("   Set position to Y=65: " .. tostring(success))

local new_pos = Navigation.getPosition()
print("   Confirmed position: " .. Navigation.formatPosition(new_pos))

-- Enable debug mode if possible
if _G then
    _G.DEBUG_MODE = true
end

-- Try moving down
print("   Attempting Navigation.down()...")
local move_success, move_err = Navigation.down()
print("   Result: " .. tostring(move_success))
if move_err then
    print("   Error: " .. move_err)
end

-- Check position after attempt
local final_pos = Navigation.getPosition()
print("   Final position: " .. Navigation.formatPosition(final_pos))

print()
print("4. Direct turtle test:")
local turtle_success = turtle.down()
print("   turtle.down(): " .. tostring(turtle_success))
if turtle_success then
    turtle.up()  -- Move back
end

print()
print("=== Analysis ===")
if new_pos.y == 65 and not move_success and move_err == "Below minimum safe Y level" then
    print("BUG CONFIRMED: Navigation is incorrectly blocking movement from Y=65")
    print("The logic should allow movement from Y=65 to Y=64")
    print("since 64 > -59 (MIN_SAFE_Y)")
end