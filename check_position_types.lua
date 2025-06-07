-- Check if position values are strings instead of numbers
print("=== Position Type Check ===")
print()

-- Direct GPS check
print("1. Direct GPS check:")
local x, y, z = gps.locate(5)
print("   GPS values: x=" .. tostring(x) .. ", y=" .. tostring(y) .. ", z=" .. tostring(z))
print("   Types: x=" .. type(x) .. ", y=" .. type(y) .. ", z=" .. type(z))

-- Navigation module check
print("\n2. Navigation module check:")
local Navigation = require("turtle.modules.navigation")
local pos = Navigation.getPosition()
print("   Position: " .. Navigation.formatPosition(pos))
print("   Y value: " .. tostring(pos.y))
print("   Y type: " .. type(pos.y))

-- Constants check
print("\n3. Constants check:")
local CONSTANTS = require("shared.constants")
print("   MIN_SAFE_Y: " .. tostring(CONSTANTS.LIMITS.MIN_SAFE_Y))
print("   MIN_SAFE_Y type: " .. type(CONSTANTS.LIMITS.MIN_SAFE_Y))

-- Test comparison
print("\n4. Test comparisons:")
local y_num = tonumber(pos.y) or pos.y
local min_num = tonumber(CONSTANTS.LIMITS.MIN_SAFE_Y) or CONSTANTS.LIMITS.MIN_SAFE_Y

print("   pos.y (" .. tostring(pos.y) .. ") < MIN_SAFE_Y (" .. tostring(CONSTANTS.LIMITS.MIN_SAFE_Y) .. ") = " .. tostring(pos.y < CONSTANTS.LIMITS.MIN_SAFE_Y))
print("   After conversion: " .. tostring(y_num) .. " < " .. tostring(min_num) .. " = " .. tostring(y_num < min_num))

-- Check if string comparison is the issue
if type(pos.y) == "string" or type(CONSTANTS.LIMITS.MIN_SAFE_Y) == "string" then
    print("\n⚠ WARNING: String comparison detected!")
    print("String comparisons can give unexpected results with negative numbers")
    
    -- Example of the problem
    print("\nExample of string comparison issue:")
    print('"65" < "-59" = ' .. tostring("65" < "-59"))  -- This would be false
    print('65 < -59 = ' .. tostring(65 < -59))  -- This would be false
    print('"65" < "0" = ' .. tostring("65" < "0"))  -- This could be true!
end

-- State check
print("\n5. State storage check:")
local State = require("turtle.modules.state")
local stored_pos = State.getPosition()
print("   Stored position: x=" .. tostring(stored_pos.x) .. ", y=" .. tostring(stored_pos.y) .. ", z=" .. tostring(stored_pos.z))
print("   Stored Y type: " .. type(stored_pos.y))

-- Check if JSON serialization is causing issues
print("\n6. JSON serialization test:")
local test_pos = {x = 10, y = 65, z = 20}
local textutils = require("textutils")
local json_str = textutils.serialiseJSON(test_pos)
print("   Original: " .. textutils.serialize(test_pos))
print("   JSON: " .. json_str)
local decoded = textutils.unserialiseJSON(json_str)
print("   Decoded: " .. textutils.serialize(decoded))
print("   Decoded Y type: " .. type(decoded.y))

print("\n=== Diagnosis ===")
if type(pos.y) == "string" then
    print("The Y coordinate is being stored as a string instead of a number!")
    print("This causes comparison issues, especially with negative numbers.")
    print("The fix is to ensure all position values are converted to numbers.")
end