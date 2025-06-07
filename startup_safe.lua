-- Ultimate Miner Safe Startup Script
-- This version has better error handling for startup issues

-- Detect device type
local device_type = turtle and "turtle" or "computer"

-- Set up proper module paths
package.path = package.path .. ";/?;/?.lua;/?/init.lua"
package.path = package.path .. ";/shared/?.lua;/shared/?/init.lua"

if device_type == "turtle" then
    package.path = package.path .. ";/turtle/?.lua;/turtle/?/init.lua"
    package.path = package.path .. ";/turtle/modules/?.lua"
    
    -- Try to run the turtle main program with error handling
    print("Starting Ultimate Miner v3.0.0 - Turtle")
    local success, err = pcall(function()
        shell.run("/turtle/main.lua")
    end)
    
    if not success then
        print("Error starting Ultimate Miner:")
        print(err)
        print("")
        print("Common fixes:")
        print("1. Re-run installer: rm -rf turtle control shared && wget run https://raw.githubusercontent.com/httptim/ultimate-miner/main/installer.lua")
        print("2. Check if all files downloaded correctly")
        print("3. Make sure you're using a Mining Turtle")
    end
else
    package.path = package.path .. ";/control/?.lua;/control/?/init.lua"
    package.path = package.path .. ";/control/modules/?.lua"
    
    -- Try to run the control main program with error handling
    print("Starting Ultimate Miner v3.0.0 - Control Computer")
    local success, err = pcall(function()
        shell.run("/control/main.lua")
    end)
    
    if not success then
        print("Error starting Ultimate Miner:")
        print(err)
        print("")
        print("Common fixes:")
        print("1. Re-run installer: rm -rf turtle control shared && wget run https://raw.githubusercontent.com/httptim/ultimate-miner/main/installer.lua")
        print("2. Check if all files downloaded correctly")
        print("3. Make sure wireless modem is attached")
    end
end