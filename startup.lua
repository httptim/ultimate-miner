-- Ultimate Miner Startup Script
-- Safe startup with error handling

-- Detect device type
local device_type = turtle and "turtle" or "computer"

-- Set up proper module paths
package.path = package.path .. ";/?;/?.lua;/?/init.lua"
package.path = package.path .. ";/shared/?.lua;/shared/?/init.lua"

if device_type == "turtle" then
    package.path = package.path .. ";/turtle/?.lua;/turtle/?/init.lua"
    package.path = package.path .. ";/turtle/modules/?.lua"
    
    -- Run the turtle main program with error catching
    print("Starting Ultimate Miner v3.0.0 - Turtle")
    local ok = shell.run("/turtle/main.lua")
    if not ok then
        print("\nFailed to start Ultimate Miner")
        print("Run: lua test_startup.lua")
        print("to diagnose the issue")
    end
else
    package.path = package.path .. ";/control/?.lua;/control/?/init.lua"
    package.path = package.path .. ";/control/modules/?.lua"
    
    -- Run the control main program with error catching
    print("Starting Ultimate Miner v3.0.0 - Control Computer")
    local ok = shell.run("/control/main.lua")
    if not ok then
        print("\nFailed to start Ultimate Miner")
        print("Run: lua test_startup.lua")
        print("to diagnose the issue")
    end
end