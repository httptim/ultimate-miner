-- Test Y bounds check directly
print("=== Y Bounds Test ===")
print()

-- Load constants
local CONSTANTS = require("shared.constants")

-- Test values
local test_y_values = {65, 64, 0, -1, -58, -59, -60}

print("MIN_SAFE_Y = " .. CONSTANTS.LIMITS.MIN_SAFE_Y)
print("MAX_SAFE_Y = " .. CONSTANTS.LIMITS.MAX_SAFE_Y)
print()

print("Testing Y values after moving down:")
print("Current Y | After Down | Below MIN? | Result")
print("----------|------------|------------|-------")

for _, current_y in ipairs(test_y_values) do
    local future_y = current_y - 1
    local below_min = future_y < CONSTANTS.LIMITS.MIN_SAFE_Y
    local result = below_min and "BLOCKED" or "ALLOWED"
    
    print(string.format("%9d | %10d | %10s | %s", 
        current_y, future_y, tostring(below_min), result))
end

print()
print("According to this logic:")
print("- At Y=65, moving down to Y=64 should be ALLOWED")
print("- At Y=-58, moving down to Y=-59 should be ALLOWED") 
print("- At Y=-59, moving down to Y=-60 should be BLOCKED")

-- Now test the actual Navigation module
print("\n=== Testing Navigation Module ===")
local ok, result = pcall(function()
    local Navigation = require("turtle.modules.navigation")
    
    -- Force a specific position for testing
    print("\nTrying to manually set position to Y=65...")
    local success = Navigation.setManualPosition(0, 65, 0, 0)
    print("Set position result: " .. tostring(success))
    
    local pos = Navigation.getPosition()
    print("Current position: " .. Navigation.formatPosition(pos))
    
    -- Try to move down
    print("\nAttempting Navigation.down()...")
    local move_success, move_err = Navigation.down()
    print("Result: " .. tostring(move_success))
    if move_err then
        print("Error: " .. move_err)
    end
    
    -- Get position again
    local new_pos = Navigation.getPosition()
    print("New position: " .. Navigation.formatPosition(new_pos))
end)

if not ok then
    print("Error testing Navigation: " .. tostring(result))
end