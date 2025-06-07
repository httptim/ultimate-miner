-- Diagnose Navigation position issue
print("=== Navigation Diagnostic ===")
print()

-- Load modules
local Navigation = require("turtle.modules.navigation")
local CONSTANTS = require("shared.constants")

-- Get GPS position
print("1. GPS Position:")
local gps_x, gps_y, gps_z = gps.locate(5)
if gps_x then
    print("   X: " .. gps_x)
    print("   Y: " .. gps_y)
    print("   Z: " .. gps_z)
else
    print("   No GPS signal")
end

-- Get Navigation position
print("\n2. Navigation Position:")
local nav_pos = Navigation.getPosition()
if nav_pos then
    print("   X: " .. nav_pos.x)
    print("   Y: " .. nav_pos.y)
    print("   Z: " .. nav_pos.z)
    print("   Facing: " .. tostring(nav_pos.facing))
else
    print("   Not initialized")
end

-- Check bounds
print("\n3. Y Bounds:")
print("   MIN_SAFE_Y: " .. CONSTANTS.LIMITS.MIN_SAFE_Y)
print("   MAX_SAFE_Y: " .. CONSTANTS.LIMITS.MAX_SAFE_Y)

-- Test what would happen if we go down
print("\n4. Down Movement Check:")
if nav_pos then
    local future_y = nav_pos.y - 1
    print("   Current Y: " .. nav_pos.y)
    print("   After down: " .. future_y)
    print("   Would be below MIN_SAFE_Y? " .. tostring(future_y < CONSTANTS.LIMITS.MIN_SAFE_Y))
end

-- Try Navigation.down() with debug
print("\n5. Attempting Navigation.down():")
local old_debug = _G.DEBUG_MODE
_G.DEBUG_MODE = true  -- Enable debug output

local success, err = Navigation.down()
print("   Result: " .. tostring(success))
if err then
    print("   Error: " .. err)
end

_G.DEBUG_MODE = old_debug

-- Direct turtle test
print("\n6. Direct turtle.down() test:")
local turtle_success = turtle.down()
print("   Result: " .. tostring(turtle_success))
if turtle_success then
    turtle.up()  -- Move back
end

-- Check for Safety module interference
print("\n7. Safety Module Check:")
local ok, Safety = pcall(require, "turtle.modules.safety")
if ok and Safety then
    if Safety.isSafeToMove then
        local safe, reason = Safety.isSafeToMove("down")
        print("   Safety check: " .. tostring(safe))
        if reason then
            print("   Reason: " .. reason)
        end
    else
        print("   Safety module loaded but no isSafeToMove function")
    end
else
    print("   Safety module not loaded")
end

print("\n=== Summary ===")
if nav_pos and gps_y then
    if math.abs(nav_pos.y - gps_y) > 1 then
        print("⚠ Navigation Y (" .. nav_pos.y .. ") doesn't match GPS Y (" .. gps_y .. ")")
        print("  This suggests position tracking is wrong!")
    end
end

if not success and turtle_success then
    print("⚠ Navigation blocks movement but turtle can move")
    print("  This suggests a Navigation/Safety check issue")
end