-- Debug Y position issue
print("=== Y Position Debug ===")
print()

-- Load modules
local CONSTANTS = require("shared.constants")
local Navigation = require("turtle.modules.navigation")
local Core = require("turtle.modules.core")

-- Initialize Navigation if needed
if not Navigation.getPosition() then
    print("Initializing Navigation...")
    Navigation.init()
end

-- Get all position info
print("1. GPS Check:")
local gps_x, gps_y, gps_z = gps.locate(5)
print("   GPS X: " .. tostring(gps_x))
print("   GPS Y: " .. tostring(gps_y))
print("   GPS Z: " .. tostring(gps_z))
print("   GPS Y type: " .. type(gps_y))

print("\n2. Navigation Position:")
local pos = Navigation.getPosition()
print("   Nav X: " .. tostring(pos.x))
print("   Nav Y: " .. tostring(pos.y))
print("   Nav Z: " .. tostring(pos.z))
print("   Nav Y type: " .. type(pos.y))

print("\n3. Constants Check:")
print("   MIN_SAFE_Y: " .. CONSTANTS.LIMITS.MIN_SAFE_Y)
print("   MIN_SAFE_Y type: " .. type(CONSTANTS.LIMITS.MIN_SAFE_Y))
print("   MAX_SAFE_Y: " .. CONSTANTS.LIMITS.MAX_SAFE_Y)

print("\n4. Movement Calculation:")
local future_y = pos.y - 1
print("   Current Y: " .. pos.y)
print("   Future Y (after down): " .. future_y)
print("   MIN_SAFE_Y: " .. CONSTANTS.LIMITS.MIN_SAFE_Y)
print("   future_y < MIN_SAFE_Y: " .. tostring(future_y < CONSTANTS.LIMITS.MIN_SAFE_Y))
print("   Comparison: " .. future_y .. " < " .. CONSTANTS.LIMITS.MIN_SAFE_Y .. " = " .. tostring(future_y < CONSTANTS.LIMITS.MIN_SAFE_Y))

print("\n5. Manual Comparison:")
print("   Is 64 < -59? " .. tostring(64 < -59))
print("   Is pos.y positive? " .. tostring(pos.y > 0))
print("   Is MIN_SAFE_Y negative? " .. tostring(CONSTANTS.LIMITS.MIN_SAFE_Y < 0))

-- Check if something is modifying the constants
print("\n6. Direct Constant Access:")
local constants_module = require("shared.constants")
print("   Direct MIN_SAFE_Y: " .. constants_module.LIMITS.MIN_SAFE_Y)

-- Try to move down with detailed output
print("\n7. Attempting down movement with debug:")
-- Temporarily override checkMovementSafety to add debug output
local old_check = Navigation.checkMovementSafety
if not old_check then
    print("   checkMovementSafety is not exposed")
else
    print("   checkMovementSafety exists")
end

-- Check what Navigation.down() returns
local success, err = Navigation.down()
print("   Success: " .. tostring(success))
print("   Error: " .. tostring(err))

print("\n=== Analysis ===")
if pos.y and CONSTANTS.LIMITS.MIN_SAFE_Y then
    if pos.y > 0 and CONSTANTS.LIMITS.MIN_SAFE_Y < 0 then
        print("Y position is positive (" .. pos.y .. ") and MIN_SAFE_Y is negative (" .. CONSTANTS.LIMITS.MIN_SAFE_Y .. ")")
        print("The check (future_y < MIN_SAFE_Y) should be: " .. (pos.y - 1) .. " < " .. CONSTANTS.LIMITS.MIN_SAFE_Y)
        print("This should evaluate to: " .. tostring((pos.y - 1) < CONSTANTS.LIMITS.MIN_SAFE_Y))
        
        if not success and err == "Below minimum safe Y level" then
            print("\n⚠ ERROR: The safety check is incorrectly blocking movement!")
            print("This suggests a logic error in the safety check.")
        end
    end
end