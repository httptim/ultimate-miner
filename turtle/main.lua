-- Ultimate Miner - Turtle Main Program
-- Entry point for turtle mining operations

-- Bootstrap the module loader
local module_loader = require("/shared/module_loader")

-- Initialize program environment
print("Ultimate Miner v3.0.0 - Turtle")
print("Initializing...")

local modules, env_type = module_loader.init_program("turtle")

-- Now that paths are set up, initialize error handling
local ErrorHandler = require("shared.error_handler")
ErrorHandler.setupGlobalHandler()

-- Now we can use require normally
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local Inventory = require("turtle.modules.inventory")
local Mining = require("turtle.modules.mining")
local Safety = require("turtle.modules.safety")
local Storage = require("turtle.modules.storage")
local Network = require("turtle.modules.network")
local Optimization = require("turtle.modules.optimization")
local Targeting = require("turtle.modules.targeting")
local Area = require("turtle.modules.area")
local SmartMining = require("turtle.modules.smart_mining")
local Integrity = require("turtle.modules.integrity")
local Monitoring = require("turtle.modules.monitoring")
local Alerts = require("turtle.modules.alerts")
local Cancellation = require("turtle.modules.cancellation")
local Diagnostics = require("turtle.modules.diagnostics")
-- Phase 10 optimization modules
local MemoryOptimizer = require("turtle.modules.memory_optimizer")
local NetworkOptimizer = require("turtle.modules.network_optimizer")
local PatternOptimizer = require("turtle.modules.pattern_optimizer")
local PerformanceConfig = require("turtle.modules.performance_config")
local CircularBuffer = require("shared.circular_buffer")
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
    
    -- Initialize mining operations
    success, err = Mining.init()
    if not success then
        error("Failed to initialize Mining: " .. tostring(err))
    end
    
    -- Initialize safety systems
    success, err = Safety.init()
    if not success then
        error("Failed to initialize Safety: " .. tostring(err))
    end
    
    -- Initialize storage integration
    success, err = Storage.init()
    if not success then
        error("Failed to initialize Storage: " .. tostring(err))
    end
    
    -- Initialize network module
    success, err = Network.init()
    if not success then
        print("Warning: Network not available - " .. tostring(err))
    end
    
    -- Initialize optimization module
    success, err = Optimization.init()
    if not success then
        error("Failed to initialize Optimization: " .. tostring(err))
    end
    
    -- Initialize Phase 8 modules
    success, err = Targeting.init()
    if not success then
        error("Failed to initialize Targeting: " .. tostring(err))
    end
    
    success, err = Area.init()
    if not success then
        error("Failed to initialize Area: " .. tostring(err))
    end
    
    success, err = SmartMining.init()
    if not success then
        error("Failed to initialize SmartMining: " .. tostring(err))
    end
    
    -- Initialize Phase 9 production modules
    -- Note: Integrity is already initialized by State module
    
    success, err = Monitoring.init()
    if not success then
        error("Failed to initialize Monitoring: " .. tostring(err))
    end
    
    success, err = Alerts.init()
    if not success then
        error("Failed to initialize Alerts: " .. tostring(err))
    end
    
    success, err = Cancellation.init()
    if not success then
        error("Failed to initialize Cancellation: " .. tostring(err))
    end
    
    success, err = Diagnostics.init()
    if not success then
        error("Failed to initialize Diagnostics: " .. tostring(err))
    end
    
    -- Initialize Phase 10 optimization modules
    success, err = MemoryOptimizer.init()
    if not success then
        error("Failed to initialize MemoryOptimizer: " .. tostring(err))
    end
    
    success, err = NetworkOptimizer.init()
    if not success then
        error("Failed to initialize NetworkOptimizer: " .. tostring(err))
    end
    
    success, err = PatternOptimizer.init()
    if not success then
        error("Failed to initialize PatternOptimizer: " .. tostring(err))
    end
    
    -- Performance config doesn't need init
    -- Start memory monitoring
    MemoryOptimizer.startMonitoring(30)
    
    initialized = true
    Core.log("INFO", "All modules initialized successfully")
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
    print("6. Error Report")
    print("7. Exit")
    print()
    write("Select option: ")
    
    local choice = read()
    return tonumber(choice)
end

-- Mining menu
local function startMining()
    term.clear()
    term.setCursorPos(1, 1)
    
    print("=== Mining Operations ===")
    print()
    print("1. Strip Mining")
    print("2. Single Block Test")
    print("3. 3x3 Tunnel")
    print("4. Vein Mining Test")
    print("5. Back to Main Menu")
    print()
    write("Select option: ")
    
    local choice = read()
    
    if choice == "1" then
        -- Strip mining
        print("\nStrip Mining Configuration")
        write("Number of strips (default 1): ")
        local strips = tonumber(read()) or 1
        
        write("Strip length (default 16): ")
        local length = tonumber(read()) or 16
        
        -- Load strip mining pattern
        local StripMining = require("turtle.patterns.strip")
        StripMining.init({
            strip_length = length,
            strip_spacing = 2,
            mine_height = 1,
            torch_spacing = 8,
            check_ores_sides = true,
            vein_mine = true,
            auto_store = true
        })
        
        print("\nStarting strip mining...")
        local success, results = StripMining.execute(strips)
        
        if success then
            print("\nMining complete!")
            print("Blocks mined: " .. results.blocks_mined)
            print("Ores found: " .. results.ores_found)
            print("Efficiency: " .. string.format("%.1f%%", results.efficiency))
        else
            print("\nMining failed or was interrupted")
        end
        
    elseif choice == "2" then
        -- Single block test
        print("\nTesting single block mining...")
        local success, msg = Mining.dig("forward")
        print("Result: " .. (success and "Success" or "Failed") .. " - " .. msg)
        
    elseif choice == "3" then
        -- 3x3 tunnel
        write("\nTunnel length: ")
        local length = tonumber(read()) or 10
        
        print("Mining 3x3 tunnel...")
        local success, blocks = Mining.mine3x3(length)
        print("Result: " .. (success and "Success" or "Failed"))
        print("Blocks mined: " .. tostring(blocks))
        
    elseif choice == "4" then
        -- Vein mining test
        print("\nChecking for ore vein...")
        local ores = Mining.findOre(1)
        
        if #ores > 0 then
            print("Found " .. #ores .. " ore(s) nearby")
            print("Mining vein...")
            local success, count = Mining.mineVein(64)
            print("Mined " .. count .. " ore blocks")
        else
            print("No ores found nearby")
        end
        
    elseif choice == "5" then
        return
    end
    
    print("\nPress any key to continue...")
    os.pullEvent("key")
    startMining()  -- Show menu again
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

-- Background tick runner
local function runTicks()
    while running do
        -- Run tick functions for modules that need periodic updates
        pcall(function()
            if Monitoring and Monitoring.tick then
                Monitoring.tick()
            end
            if Alerts and Alerts.tick then
                Alerts.tick()
            end
            if Cancellation and Cancellation.tick then
                Cancellation.tick()
            end
        end)
        os.sleep(1) -- Check every second
    end
end

-- Main program loop
local function main()
    -- Initialize
    initialize()
    
    -- Start background tick runner in parallel
    parallel.waitForAny(
        function()
            -- Main menu loop
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
                    ErrorHandler.createErrorReport()
                elseif choice == 7 then
                    running = false
                else
                    print("Invalid choice")
                    os.sleep(1)
                end
            end
        end,
        runTicks  -- Run ticks in parallel
    )
    
    -- Cleanup
    print("Shutting down...")
    State.save()
    Config.save()
    Core.shutdown()
end

-- Error handling wrapper
local success, err = xpcall(main, function(error_msg)
    -- Get stack trace
    local stack = debug and debug.traceback and debug.traceback(error_msg, 2) or "No stack trace available"
    return {message = error_msg, stack = stack}
end)

if not success then
    print()
    print("=== CRITICAL ERROR ===")
    print("Error: " .. tostring(err.message or err))
    print()
    
    -- Try to log the error
    local logged = false
    if ErrorHandler then
        local ok = pcall(function()
            -- Ensure error reporter is loaded
            local ErrorReporter = require("shared.error_reporter")
            ErrorReporter.init()
            
            -- Log the error
            ErrorReporter.logError(
                "CRASH",
                tostring(err.message or err),
                err.stack,
                {
                    module = "turtle_main",
                    initialized = initialized
                }
            )
            
            -- Try to upload
            print("Creating error report...")
            local upload_ok, code = ErrorReporter.uploadToPastebin("Ultimate Miner Crash Report")
            if upload_ok then
                print()
                print("=== ERROR REPORT UPLOADED ===")
                print("Pastebin Code: " .. code)
                print("URL: https://pastebin.com/" .. code)
                print()
                print("Please include this code when reporting!")
                logged = true
            else
                print("Upload failed, error saved locally")
                logged = true
            end
        end)
        
        if not ok then
            print("Failed to create error report")
        end
    end
    
    -- Fallback logging
    if not logged then
        local file = fs.open("/ultimate_miner_crash.log", "w")
        if file then
            file.writeLine("Ultimate Miner Crash Report")
            file.writeLine("Time: " .. os.date())
            file.writeLine("Error: " .. tostring(err.message or err))
            if err.stack then
                file.writeLine("Stack trace:")
                file.writeLine(err.stack)
            end
            file.close()
            print("Crash saved to: /ultimate_miner_crash.log")
        end
    end
    
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
    
    print()
    print("Press any key to exit...")
    os.pullEvent("key")
end