-- Fix for the testMovement menu issue
-- Run this to patch the main.lua file

print("Fixing testMovement menu issue...")

-- Read current main.lua
local file = fs.open("/turtle/main.lua", "r")
if not file then
    print("Error: Cannot open /turtle/main.lua")
    return
end
local content = file.readAll()
file.close()

-- Find and replace the testMovement function
local fixed_function = [[
local function testMovement()
    while true do
        -- Clear screen and reset cursor
        term.clear()
        term.setCursorPos(1, 1)
        
        print("=== Movement Test ===")
        print()
        
        -- Get current state safely
        local pos_str = "Unknown"
        local ok, pos = pcall(function() return Navigation.getPosition() end)
        if ok and pos then
            pos_str = string.format("X:%d Y:%d Z:%d", pos.x, pos.y, pos.z)
        end
        print("Current position: " .. pos_str)
        print("Fuel level: " .. tostring(turtle.getFuelLevel()))
        
        print()
        print("Options:")
        print("1. Test basic movements")
        print("2. Test turning")
        print("3. Test GPS location")
        print("4. Move to coordinates")
        print("5. Return home")
        print("6. Back to menu")
        print()
        write("Select option: ")
        
        -- Read choice and trim whitespace
        local choice = read()
        choice = choice:match("^%s*(.-)%s*$") -- Trim whitespace
        
        -- Handle choices
        if choice == "1" then
            print("\nTesting basic movements...")
            local tests = {
                {"Forward", Navigation.forward},
                {"Back", Navigation.back},
                {"Up", Navigation.up},
                {"Down", Navigation.down}
            }
            for _, test in ipairs(tests) do
                local ok, result = pcall(test[2])
                print(test[1] .. ": " .. (ok and result and "Success" or "Failed"))
                os.sleep(0.5)
            end
            
        elseif choice == "2" then
            print("\nTesting turning...")
            for i = 1, 4 do
                local ok, result = pcall(Navigation.turnRight)
                print("Turn right " .. i .. ": " .. (ok and result and "Success" or "Failed"))
                os.sleep(0.5)
            end
            
        elseif choice == "3" then
            print("\nTesting GPS...")
            local ok, success, pos = pcall(Navigation.locateGPS)
            if ok and success then
                print("GPS Position: X:" .. pos.x .. " Y:" .. pos.y .. " Z:" .. pos.z)
            else
                print("GPS not available")
            end
            
        elseif choice == "4" then
            print("\nMove to coordinates")
            write("X: ")
            local x = tonumber(read())
            write("Y: ")
            local y = tonumber(read())
            write("Z: ")
            local z = tonumber(read())
            
            if x and y and z then
                print("\nMoving to X:" .. x .. " Y:" .. y .. " Z:" .. z)
                local ok, success = pcall(Navigation.moveTo, {x=x, y=y, z=z})
                if ok and success then
                    print("Arrived at destination!")
                else
                    print("Movement failed")
                end
            else
                print("Invalid coordinates")
            end
            
        elseif choice == "5" then
            print("\nReturning home...")
            local ok, success = pcall(Navigation.returnHome)
            if ok and success then
                print("Arrived home!")
            else
                print("Failed to return home")
            end
            
        elseif choice == "6" then
            break -- Exit the while loop
        else
            print("\nInvalid option: " .. choice)
        end
        
        -- Wait for key press before continuing
        if choice ~= "6" then
            print("\nPress any key to continue...")
            os.pullEvent("key")
        end
    end
end]]

-- Check if we can find the function
local start_pos = content:find("local function testMovement%(%)") 
if not start_pos then
    print("Error: Cannot find testMovement function")
    return
end

-- Find the end of the function
local end_pos = start_pos
local depth = 0
local i = start_pos

while i <= #content do
    if content:sub(i, i+7) == "function" then
        depth = depth + 1
    elseif content:sub(i, i+2) == "end" and (i+3 > #content or content:sub(i+3, i+3):match("%s")) then
        depth = depth - 1
        if depth == 0 then
            end_pos = i + 2
            break
        end
    end
    i = i + 1
end

-- Replace the function
local new_content = content:sub(1, start_pos - 1) .. fixed_function .. content:sub(end_pos + 1)

-- Write the fixed file
file = fs.open("/turtle/main_fixed.lua", "w")
file.write(new_content)
file.close()

print("Fixed file written to /turtle/main_fixed.lua")
print()
print("To apply the fix:")
print("mv /turtle/main_fixed.lua /turtle/main.lua")
print()
print("Or test it first:")
print("lua /turtle/main_fixed.lua")