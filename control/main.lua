-- Ultimate Miner - Control Computer Main Program
-- Entry point for fleet management and control interface

-- Bootstrap the module loader
local module_loader = require("/shared/module_loader")

-- Initialize program environment
print("Ultimate Miner v3.0.0 - Control Computer")
print("Initializing...")

local modules, env_type = module_loader.init_program("control")

-- Now that paths are set up, initialize error handling
local ErrorHandler = require("shared.error_handler")
ErrorHandler.setupGlobalHandler()

-- Now we can use require normally
local CONSTANTS = require("shared.constants")

-- Load control modules
local Core = require("control.modules.core")
local Network = require("control.modules.network")
local Fleet = require("control.modules.fleet")
local Commands = require("control.modules.commands")
local UI = require("control.modules.ui")
local Tasks = require("control.modules.tasks")

-- Main program state
local running = true
local initialized = false
local fleet_data = {}
local selected_turtle = nil

-- Initialize all modules
local function initialize()
    print("Loading modules...")
    
    -- Initialize core first
    local success, err = Core.init()
    if not success then
        error("Failed to initialize core: " .. err)
    end
    
    -- Initialize network
    success, err = Network.init()
    if not success then
        error("Failed to initialize network: " .. err)
    end
    
    -- Initialize fleet management
    success, err = Fleet.init()
    if not success then
        error("Failed to initialize fleet: " .. err)
    end
    
    -- Initialize command dispatcher
    success, err = Commands.init()
    if not success then
        error("Failed to initialize commands: " .. err)
    end
    
    -- Initialize UI
    success, err = UI.init()
    if not success then
        error("Failed to initialize UI: " .. err)
    end
    
    -- Initialize task management
    success, err = Tasks.init()
    if not success then
        error("Failed to initialize tasks: " .. err)
    end
    
    -- Register global event handlers
    Core.on("exit", function()
        running = false
    end)
    
    initialized = true
    Core.log("INFO", "Control system initialized successfully")
end


-- Event loop
local function eventLoop()
    Core.log("INFO", "Starting event loop")
    
    while running do
        local event_data = {os.pullEvent()}
        local event = event_data[1]
        
        -- Remove event name from data
        table.remove(event_data, 1)
        
        -- Emit to core event system
        Core.emit(event, table.unpack(event_data))
        
        -- Handle specific events
        if event == "terminate" then
            Core.log("INFO", "Received terminate signal")
            running = false
        end
    end
end

-- Shutdown all systems
local function shutdown()
    Core.log("INFO", "Shutting down control system")
    
    -- Shutdown in reverse order
    Tasks.shutdown()
    UI.shutdown()
    Commands.shutdown()
    Fleet.shutdown()
    Network.shutdown()
    Core.shutdown()
    
    -- Clear screen
    term.clear()
    term.setCursorPos(1, 1)
    
    print("Control system shut down successfully")
end

-- Main program loop
local function main()
    -- Initialize
    initialize()
    
    -- Show dashboard UI
    local Dashboard = require("control.screens.dashboard")
    UI.showScreen(Dashboard.create())
    
    -- Run event loop
    eventLoop()
    
    -- Cleanup
    shutdown()
end

-- Error handling wrapper
local function errorHandler(err)
    print()
    print("Error: " .. tostring(err))
    print("Stack trace:")
    print(debug.traceback())
    
    -- Try to log if possible
    pcall(function()
        if Core and Core.log then
            Core.log("CRITICAL", "Fatal error: " .. err)
        end
    end)
    
    print()
    print("Please report this error at:")
    print("https://github.com/httptim/ultimate-miner/issues")
end

-- Run with error handling
local success, err = xpcall(main, errorHandler)

if not success then
    print("Control system crashed")
    print("Check logs for details")
end