-- Quick fix for testMovement
-- This replaces the broken testMovement with a simple working version

local function createFixedTestMovement()
    return [[
local function testMovement()
    while true do
        term.clear()
        term.setCursorPos(1, 1)
        
        print("=== Movement Test ===")
        print()
        print("Current position: " .. Navigation.formatPosition())
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
        
        local choice = read()
        
        if choice == "3" then
            -- GPS Test
            print("\nTesting GPS...")
            local success, pos = Navigation.locateGPS()
            if success then
                print("GPS Position: " .. Navigation.formatPosition(pos))
            else
                print("GPS not available")
            end
        elseif choice == "6" then
            -- Exit
            return
        else
            print("\nOption " .. choice .. " - Coming soon!")
        end
        
        if choice ~= "6" then
            print("\nPress any key to continue...")
            os.pullEvent("key")
        end
    end
end
]]
end

print("Quick Fix for testMovement")
print()
print("The testMovement function has broken indentation.")
print("Here's a simple working version you can use:")
print()
print("1. Edit /turtle/main.lua")
print("2. Find 'local function testMovement()'")  
print("3. Delete everything from that line until the matching 'end'")
print("4. Replace with this working version:")
print()
print(createFixedTestMovement())
print()
print("This simplified version will at least let you test GPS (option 3)")