-- Fix for Navigation Y bounds check
-- This patches the navigation module to add debugging and fix potential issues

print("=== Applying Navigation Y Check Fix ===")
print()

-- Load the navigation module
local Navigation = require("turtle.modules.navigation")
local CONSTANTS = require("shared.constants")
local Core = require("turtle.modules.core")

-- Store original down function
local original_down = Navigation.down

-- Create a patched version with debugging
Navigation.down = function()
    -- Get current position
    local pos = Navigation.getPosition()
    
    -- Debug output
    print("[DEBUG] Navigation.down() called")
    print("[DEBUG] Current position: " .. Navigation.formatPosition(pos))
    print("[DEBUG] Current Y: " .. tostring(pos.y) .. " (type: " .. type(pos.y) .. ")")
    print("[DEBUG] MIN_SAFE_Y: " .. tostring(CONSTANTS.LIMITS.MIN_SAFE_Y) .. " (type: " .. type(CONSTANTS.LIMITS.MIN_SAFE_Y) .. ")")
    
    -- Calculate future position
    local future_y = tonumber(pos.y) - 1  -- Ensure it's a number
    print("[DEBUG] Future Y after down: " .. tostring(future_y))
    
    -- Check bounds
    local min_y = tonumber(CONSTANTS.LIMITS.MIN_SAFE_Y)  -- Ensure it's a number
    local would_be_below = future_y < min_y
    print("[DEBUG] Would be below MIN_SAFE_Y? " .. tostring(would_be_below))
    print("[DEBUG] Comparison: " .. future_y .. " < " .. min_y .. " = " .. tostring(would_be_below))
    
    -- Call original function
    local success, err = original_down()
    
    print("[DEBUG] Original down() result: " .. tostring(success) .. ", error: " .. tostring(err))
    
    return success, err
end

print("Navigation.down() has been patched with debugging")
print("Try running a turtle program that moves down to see the debug output")
print()

-- Also create a direct test function
function testDownMovement()
    print("=== Testing Down Movement ===")
    
    -- Get current state
    local pos = Navigation.getPosition()
    print("Current position: " .. Navigation.formatPosition(pos))
    
    -- Try to move down
    print("\nAttempting to move down...")
    local success, err = Navigation.down()
    
    print("\nResult: " .. tostring(success))
    if err then
        print("Error: " .. err)
    end
    
    -- Get new position
    local new_pos = Navigation.getPosition()
    print("New position: " .. Navigation.formatPosition(new_pos))
    
    return success, err
end

-- Export the test function
_G.testDownMovement = testDownMovement

print("Run testDownMovement() to test the movement")
print()

-- Also check if there's a number conversion issue
print("Type checks:")
print("- Current Y type: " .. type(Navigation.getPosition().y))
print("- MIN_SAFE_Y type: " .. type(CONSTANTS.LIMITS.MIN_SAFE_Y))

-- Try to fix by ensuring position Y is a number
local pos = Navigation.getPosition()
if type(pos.y) == "string" then
    print("\n⚠ WARNING: Y position is a string, converting to number")
    Navigation.setManualPosition(pos.x, tonumber(pos.y), pos.z, pos.facing)
end