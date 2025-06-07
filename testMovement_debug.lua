-- Debug version of testMovement to replace the broken one
-- This will help identify where it's getting stuck

local function testMovement()
    print("[DEBUG] Entering testMovement")
    
    while true do
        term.clear()
        term.setCursorPos(1, 1)
        
        print("=== Movement Test ===")
        print()
        
        -- Safely get position
        local pos_str = "Unknown"
        pcall(function()
            pos_str = Navigation.formatPosition()
        end)
        print("Current position: " .. pos_str)
        
        -- Safely get fuel
        local fuel_str = "Unknown"
        pcall(function()
            fuel_str = tostring(turtle.getFuelLevel())
        end)
        print("Fuel level: " .. fuel_str)
        
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
        print("[DEBUG] Choice: '" .. tostring(choice) .. "'")
        
        if choice == "1" then
            print("\nTesting basic movements...")
            print("Forward: " .. (Navigation.forward() and "Success" or "Failed"))
            os.sleep(0.5)
            print("Back: " .. (Navigation.back() and "Success" or "Failed"))
            
        elseif choice == "2" then
            print("\nTesting turning...")
            print("Turn right: " .. (Navigation.turnRight() and "Success" or "Failed"))
            os.sleep(0.5)
            print("Turn left: " .. (Navigation.turnLeft() and "Success" or "Failed"))
            
        elseif choice == "3" then
            print("\nTesting GPS...")
            local success, pos = Navigation.locateGPS()
            if success then
                print("GPS Position: " .. Navigation.formatPosition(pos))
            else
                print("GPS not available")
            end
            
        elseif choice == "4" then
            print("\nMove to coordinates - Not implemented in debug version")
            
        elseif choice == "5" then
            print("\nReturn home - Not implemented in debug version")
            
        elseif choice == "6" then
            print("[DEBUG] Exiting testMovement")
            return
            
        else
            print("\nInvalid choice: '" .. tostring(choice) .. "'")
        end
        
        if choice ~= "6" then
            print("\nPress any key to continue...")
            os.pullEvent("key")
        end
    end
end

-- Export for testing
return testMovement