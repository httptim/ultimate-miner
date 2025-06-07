-- Verify the navigation Y bounds fix
print("=== Navigation Y Bounds Fix Verification ===")
print()

-- Load modules
local Navigation = require("turtle.modules.navigation")
local CONSTANTS = require("shared.constants")
local State = require("turtle.modules.state")

-- Step 1: Check current position
print("1. Current position check:")
local pos = Navigation.getPosition()
print("   Position: " .. Navigation.formatPosition(pos))
print("   Y value: " .. tostring(pos.y) .. " (type: " .. type(pos.y) .. ")")

-- Step 2: Get GPS and sync
print("\n2. GPS sync:")
local success, gps_pos = Navigation.locateGPS()
if success then
    print("   GPS successful")
    local new_pos = Navigation.getPosition()
    print("   New position: " .. Navigation.formatPosition(new_pos))
    print("   Y type after GPS: " .. type(new_pos.y))
else
    print("   GPS not available")
end

-- Step 3: Test movement calculation
print("\n3. Movement calculation test:")
local current_y = tonumber(pos.y) or pos.y
local future_y = current_y - 1
print("   Current Y: " .. current_y .. " (type: " .. type(current_y) .. ")")
print("   Future Y (after down): " .. future_y)
print("   MIN_SAFE_Y: " .. CONSTANTS.LIMITS.MIN_SAFE_Y)
print("   Would block? " .. tostring(future_y < CONSTANTS.LIMITS.MIN_SAFE_Y))

-- Step 4: Try actual movement
print("\n4. Attempting Navigation.down():")
local move_success, move_err = Navigation.down()
print("   Result: " .. tostring(move_success))
if move_err then
    print("   Error: " .. move_err)
end

-- Step 5: Verify position after attempt
local final_pos = Navigation.getPosition()
print("\n5. Final position: " .. Navigation.formatPosition(final_pos))

-- Step 6: Direct turtle test for comparison
print("\n6. Direct turtle.down() test:")
local turtle_success = turtle.down()
print("   Result: " .. tostring(turtle_success))
if turtle_success then
    turtle.up()  -- Move back
    print("   (Moved back up)")
end

-- Summary
print("\n=== Summary ===")
if current_y > 0 and CONSTANTS.LIMITS.MIN_SAFE_Y < 0 then
    if move_success then
        print("✓ Fix successful! Navigation now allows movement from positive Y values")
    else
        if turtle_success then
            print("✗ Fix incomplete - Navigation still blocks valid movement")
            print("  Error was: " .. tostring(move_err))
        else
            print("⚠ Movement blocked by physical obstacle, not Navigation logic")
        end
    end
else
    print("⚠ Test conditions not ideal - turtle may be at negative Y")
end

-- Test state persistence
print("\n7. Testing state persistence:")
State.save()
print("   State saved")

-- Reload and check
State.load()
local reloaded_pos = State.getPosition()
print("   Reloaded Y: " .. tostring(reloaded_pos.y) .. " (type: " .. type(reloaded_pos.y) .. ")")

if type(reloaded_pos.y) == "string" then
    print("   ⚠ WARNING: Y is still being saved as string!")
end