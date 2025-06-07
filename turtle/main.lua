-- Ultimate Miner - Turtle Main Program
-- Entry point for turtle mining operations

-- Bootstrap the module loader
local module_loader = require("/shared/module_loader")

-- Initialize program environment
print("Ultimate Miner v2.2.0 - Turtle")
print("Initializing...")

local modules, env_type = module_loader.init_program("turtle")

-- Now we can use require normally
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local Inventory = require("turtle.modules.inventory")
local CONSTANTS = require("shared.constants")

-- Main program state
local running = true
local initialized = false

-- Initialize all modules
local function initialize()
    print("Loading modules...")
    
    -- Initialize core systems
    local success, err = Core.init({debug = Config.get("debug_mode", false)})
    if not success then
        error("Failed to initialize Core: " .. tostring(err))
    end
    
    -- Load saved state
    success, err = State.init()
    if not success then
        error("Failed to initialize State: " .. tostring(err))
    end
    
    -- Load configuration
    success, err = Config.init()
    if not success then
        error("Failed to initialize Config: " .. tostring(err))
    end
    
    -- Enable auto-save
    State.enableAutoSave(60)
    
    -- Initialize navigation
    success, err = Navigation.init()
    if not success then
        error("Failed to initialize Navigation: " .. tostring(err))
    end
    
    -- Initialize inventory management
    success, err = Inventory.init()
    if not success then
        error("Failed to initialize Inventory: " .. tostring(err))
    end
    
    -- TODO: Initialize other modules as they are created
    -- Mining.init()
    -- Safety.init()
    -- Network.init()
    
    initialized = true
    Core.info("All modules initialized successfully")
end

-- Display turtle status
local function displayStatus()
    term.clear()
    term.setCursorPos(1, 1)
    
    print("=== Ultimate Miner - Turtle ===")
    print()
    
    -- Position
    local pos = Navigation.getPosition()
    print(string.format("Position: X:%d Y:%d Z:%d", pos.x, pos.y, pos.z))
    print(string.format("Facing: %s", 
        pos.facing == 0 and "North" or
        pos.facing == 1 and "East" or
        pos.facing == 2 and "South" or
        pos.facing == 3 and "West" or "Unknown"))
    
    -- Fuel
    print(string.format("Fuel: %d/%d", turtle.getFuelLevel(), turtle.getFuelLimit()))
    
    -- Stats
    print()
    print("Statistics:")
    print(string.format("  Blocks Mined: %d", State.get("blocks_mined", 0)))
    print(string.format("  Fuel Used: %d", State.get("fuel_used", 0)))
    print(string.format("  Uptime: %s", Core.formatDuration(
        (os.epoch("utc") - State.get("start_time", os.epoch("utc"))) / 1000
    )))
    
    -- Current task
    local task = State.get("current_task")
    if task then
        print()
        print("Current Task: " .. (task.name or "Unknown"))
    else
        print()
        print("Status: Idle")
    end
    
    print()
    print("Press Q to quit, H for help")
end

-- Main menu
local function showMenu()
    term.clear()
    term.setCursorPos(1, 1)
    
    print("=== Ultimate Miner - Main Menu ===")
    print()
    print("1. Start Mining")
    print("2. Configure Settings")
    print("3. Test Movement")
    print("4. View Statistics")
    print("5. Network Control Mode")
    print("6. Exit")
    print()
    write("Select option: ")
    
    local choice = read()
    return tonumber(choice)
end

-- Placeholder functions for menu options
local function startMining()
    print("Mining functionality not yet implemented")
    print("This will allow selection of mining patterns")
    print("Press any key to continue...")
    os.pullEvent("key")
end

local function configureSettings()
    print("Configuration interface not yet implemented")
    print("Current settings:")
    print("  Debug Mode: " .. tostring(Config.get("debug_mode")))
    print("  Safety Radius: " .. Config.get("safety_radius"))
    print("  Fuel Reserve: " .. Config.get("fuel_reserve"))
    print()
    print("Press any key to continue...")
    os.pullEvent("key")
end

local function testMovement()
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
        return
    end
    
    print("\nPress any key to continue...")
    os.pullEvent("key")
    testMovement()  -- Show menu again
end

local function viewStatistics()
    term.clear()
    term.setCursorPos(1, 1)
    
    print("=== Mining Statistics ===")
    print()
    print("Lifetime Stats:")
    print("  Blocks Mined: " .. State.get("blocks_mined", 0))
    print("  Ores Found: " .. State.get("ores_found", 0))
    print("  Fuel Used: " .. State.get("fuel_used", 0))
    print("  Distance Traveled: " .. State.get("distance_traveled", 0))
    print("  Inventory Trips: " .. State.get("inventory_trips", 0))
    print("  Errors Encountered: " .. State.get("errors_encountered", 0))
    print()
    
    local start_time = State.get("start_time", os.epoch("utc"))
    local runtime = (os.epoch("utc") - start_time) / 1000
    print("Total Runtime: " .. Core.formatDuration(runtime))
    print()
    print("Press any key to continue...")
    os.pullEvent("key")
end

local function networkMode()
    print("Network control mode not yet implemented")
    print("This will connect to a control computer")
    print("Press any key to continue...")
    os.pullEvent("key")
end

-- Main program loop
local function main()
    -- Initialize
    initialize()
    
    -- Main loop
    while running do
        local choice = showMenu()
        
        if choice == 1 then
            startMining()
        elseif choice == 2 then
            configureSettings()
        elseif choice == 3 then
            testMovement()
        elseif choice == 4 then
            viewStatistics()
        elseif choice == 5 then
            networkMode()
        elseif choice == 6 then
            running = false
        else
            print("Invalid choice")
            os.sleep(1)
        end
    end
    
    -- Cleanup
    print("Shutting down...")
    State.save()
    Config.save()
    Core.shutdown()
end

-- Error handling wrapper
local success, err = pcall(main)
if not success then
    print()
    print("Error: " .. tostring(err))
    print()
    print("Please report this error at:")
    print("https://github.com/httptim/ultimate-miner/issues")
    
    -- Try to save state even on error
    if initialized then
        pcall(function()
            State.save()
            Config.save()
        end)
    end
end