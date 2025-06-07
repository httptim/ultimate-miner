-- Simplified testMovement replacement
-- Copy this function to replace the broken one in turtle/main.lua

local function testMovement()
    -- Disable background ticks while in this menu
    local old_ticks = ticks_enabled
    ticks_enabled = false
    
    local running_menu = true
    while running_menu do
        term.clear()
        term.setCursorPos(1, 1)
        
        print("=== Movement Test ===")
        print()
        
        -- Safe position display
        local pos_str = "Unknown"
        pcall(function()
            local pos = Navigation.getPosition()
            if pos then
                pos_str = string.format("X:%d Y:%d Z:%d", pos.x or 0, pos.y or 0, pos.z or 0)
            end
        end)
        print("Position: " .. pos_str)
        print("Fuel: " .. tostring(turtle.getFuelLevel()))
        
        print()
        print("1. Test movements")
        print("2. Test turning")
        print("3. Test GPS")
        print("4. Exit")
        print()
        write("Choice: ")
        
        local input = read()
        local choice = tostring(input):match("^%s*(.-)%s*$") -- Trim whitespace
        
        print() -- New line after choice
        
        if choice == "1" then
            print("Testing movements...")
            print("Forward: " .. tostring(turtle.forward()))
            os.sleep(0.5)
            print("Back: " .. tostring(turtle.back()))
            os.sleep(0.5)
            print("Up: " .. tostring(turtle.up()))
            os.sleep(0.5)
            print("Down: " .. tostring(turtle.down()))
            
        elseif choice == "2" then
            print("Testing turns...")
            for i = 1, 4 do
                print("Turn " .. i .. ": " .. tostring(turtle.turnRight()))
                os.sleep(0.5)
            end
            
        elseif choice == "3" then
            print("Testing GPS...")
            local x, y, z = gps.locate(5)
            if x then
                print(string.format("GPS: X:%.1f Y:%.1f Z:%.1f", x, y, z))
            else
                print("GPS not available")
            end
            
        elseif choice == "4" then
            running_menu = false
            
        else
            print("Invalid choice: '" .. choice .. "'")
        end
        
        if running_menu and choice ~= "4" then
            print()
            print("Press any key to continue...")
            os.pullEvent("key")
        end
    end
    
    -- Restore tick state
    ticks_enabled = old_ticks
    print("Returning to main menu...")
    os.sleep(0.5)
end

-- Instructions
print([[
=== Simple testMovement Replacement ===

The current testMovement has issues. To fix:

1. Edit /turtle/main.lua
2. Find the testMovement function (around line 342)
3. Delete the entire function from "local function testMovement()" to its "end"
4. Replace with the simplified version above

Or run this automatic fix:
lua fix_testMovement.lua
]])