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
        print("1. Test basic movements (forward, back, up, down)")
        print("2. Test turning (left, right, face direction)")
        print("3. Test GPS location")
        print("4. Move to specific coordinates")
        print("5. Return home")
        print("6. Back to menu")
        print()
        write("Select option: ")
        
        local choice = read()
        
        if choice == "1" then
            print("\nTesting basic movements...")
            
            print("Forward: " .. (Navigation.forward() and "Success" or "Failed"))
            os.sleep(0.5)
            
            print("Back: " .. (Navigation.back() and "Success" or "Failed"))
            os.sleep(0.5)
            
            print("Up: " .. (Navigation.up() and "Success" or "Failed"))
            os.sleep(0.5)
            
            print("Down: " .. (Navigation.down() and "Success" or "Failed"))
            
            print("\nFinal position: " .. Navigation.formatPosition())
            
        elseif choice == "2" then
            print("\nTesting turning...")
            
            print("Turn right: " .. (Navigation.turnRight() and "Success" or "Failed"))
            os.sleep(0.5)
            
            print("Turn right: " .. (Navigation.turnRight() and "Success" or "Failed"))
            os.sleep(0.5)
            
            print("Turn left: " .. (Navigation.turnLeft() and "Success" or "Failed"))
            os.sleep(0.5)
            
            print("Turn left: " .. (Navigation.turnLeft() and "Success" or "Failed"))
            os.sleep(0.5)
            
            print("\nFacing North...")
            Navigation.face(CONSTANTS.DIRECTIONS.NORTH)
            
            print("\nFinal facing: " .. Navigation.getFacing())
            
        elseif choice == "3" then
            print("\nTesting GPS...")
            local success, pos = Navigation.locateGPS()
            if success then
                print("GPS Position: " .. Navigation.formatPosition(pos))
                
                print("\nCalibrating GPS (requires movement)...")
                if Navigation.calibrateGPS() then
                    print("Calibration successful!")
                    print("Facing: " .. Navigation.getFacing())
                else
                    print("Calibration failed")
                end
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
                local target = {x = x, y = y, z = z}
                print("\nMoving to " .. Navigation.formatPosition(target))
                
                local success, err = Navigation.moveTo(target)
                if success then
                    print("Arrived at destination!")
                else
                    print("Movement failed: " .. tostring(err))
                end
            else
                print("Invalid coordinates")
            end
            
        elseif choice == "5" then
            print("\nReturning home...")
            local success, err = Navigation.returnHome()
            if success then
                print("Arrived home!")
            else
                print("Failed to return home: " .. tostring(err))
            end
            
        elseif choice == "6" then
            return  -- Exit the loop and return to main menu
        end
        
        if choice ~= "6" then
            print("\nPress any key to continue...")
            os.pullEvent("key")
        end
    end  -- End of while loop
end