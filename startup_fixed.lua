-- Ultimate Miner Startup Script (Fixed)
-- This properly starts the Ultimate Miner without looping

-- Detect device type
local device_type = turtle and "turtle" or "computer"

-- Set up proper module paths
package.path = package.path .. ";/?;/?.lua;/?/init.lua"
package.path = package.path .. ";/shared/?.lua;/shared/?/init.lua"

if device_type == "turtle" then
    package.path = package.path .. ";/turtle/?.lua;/turtle/?/init.lua"
    package.path = package.path .. ";/turtle/modules/?.lua"
    
    -- Run the turtle main program
    print("Starting Ultimate Miner v3.0.0 - Turtle")
    shell.run("/turtle/main.lua")
else
    package.path = package.path .. ";/control/?.lua;/control/?/init.lua"
    package.path = package.path .. ";/control/modules/?.lua"
    
    -- Run the control main program
    print("Starting Ultimate Miner v3.0.0 - Control Computer")
    shell.run("/control/main.lua")
end