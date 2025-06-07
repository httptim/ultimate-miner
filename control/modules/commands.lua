-- Command Dispatcher Module
-- Handles command execution and task management for turtles

local Commands = {}
local Core = require("control.modules.core")
local Network = require("control.modules.network")
local Fleet = require("control.modules.fleet")

-- Available commands
Commands.available = {}
Commands.initialized = false

-- Initialize command dispatcher
function Commands.init()
    if Commands.initialized then
        Core.log("INFO", "Commands already initialized")
        return true, "Already initialized"
    end
    
    -- Register default commands
    Commands.registerDefaultCommands()
    
    Commands.initialized = true
    Core.log("INFO", "Command dispatcher initialized")
    
    return true, "Commands initialized successfully"
end

-- Register default commands
function Commands.registerDefaultCommands()
    -- Movement commands
    Commands.register("move_to", {
        description = "Move turtle to specific coordinates",
        parameters = {
            x = "number",
            y = "number", 
            z = "number",
            use_pathfinding = "boolean (optional)"
        },
        handler = Commands.handleMoveTo
    })
    
    Commands.register("return_home", {
        description = "Return turtle to home position",
        parameters = {},
        handler = Commands.handleReturnHome
    })
    
    -- Mining commands
    Commands.register("mine_pattern", {
        description = "Execute a mining pattern",
        parameters = {
            pattern = "string (strip|branch|spiral|quarry|adaptive)",
            options = "table (pattern-specific options)"
        },
        handler = Commands.handleMinePattern
    })
    
    Commands.register("mine_area", {
        description = "Mine a specific area",
        parameters = {
            x1 = "number",
            y1 = "number",
            z1 = "number",
            x2 = "number",
            y2 = "number",
            z2 = "number"
        },
        handler = Commands.handleMineArea
    })
    
    Commands.register("mine_ore", {
        description = "Mine for specific ore type",
        parameters = {
            ore_type = "string",
            max_blocks = "number (optional)"
        },
        handler = Commands.handleMineOre
    })
    
    -- Control commands
    Commands.register("emergency_stop", {
        description = "Emergency stop the turtle",
        parameters = {
            reason = "string (optional)"
        },
        handler = Commands.handleEmergencyStop
    })
    
    Commands.register("pause", {
        description = "Pause current operation",
        parameters = {},
        handler = Commands.handlePause
    })
    
    Commands.register("resume", {
        description = "Resume paused operation",
        parameters = {},
        handler = Commands.handleResume
    })
    
    -- Status commands
    Commands.register("get_status", {
        description = "Request current status",
        parameters = {},
        handler = Commands.handleGetStatus
    })
    
    Commands.register("get_inventory", {
        description = "Request inventory summary",
        parameters = {},
        handler = Commands.handleGetInventory
    })
    
    -- Maintenance commands
    Commands.register("refuel", {
        description = "Refuel turtle from inventory",
        parameters = {
            target_level = "number (optional)"
        },
        handler = Commands.handleRefuel
    })
    
    Commands.register("deposit_items", {
        description = "Deposit items to nearby storage",
        parameters = {
            categories = "table (optional)"
        },
        handler = Commands.handleDepositItems
    })
    
    Commands.register("update_config", {
        description = "Update turtle configuration",
        parameters = {
            config = "table"
        },
        handler = Commands.handleUpdateConfig
    })
    
    Core.log("INFO", "Registered " .. #Core.tableKeys(Commands.available) .. " default commands")
end

-- Register a new command
function Commands.register(name, command_def)
    if Commands.available[name] then
        Core.log("WARNING", "Overwriting existing command: " .. name)
    end
    
    Commands.available[name] = {
        name = name,
        description = command_def.description or "No description",
        parameters = command_def.parameters or {},
        handler = command_def.handler,
        requires_online = command_def.requires_online ~= false  -- Default true
    }
    
    Core.log("DEBUG", "Registered command: " .. name)
    return true
end

-- Execute a command on a turtle
function Commands.execute(turtle_id, command_name, parameters)
    local command = Commands.available[command_name]
    if not command then
        return false, "Unknown command: " .. command_name
    end
    
    local turtle = Fleet.getTurtle(turtle_id)
    if not turtle then
        return false, "Turtle not found: " .. turtle_id
    end
    
    if command.requires_online and turtle.status ~= "online" then
        return false, "Turtle not online"
    end
    
    -- Validate parameters
    local validation_err = Commands.validateParameters(command.parameters, parameters)
    if validation_err then
        return false, validation_err
    end
    
    -- Execute handler if local
    if command.handler then
        return command.handler(turtle_id, parameters)
    end
    
    -- Otherwise send to turtle
    return Network.sendCommand(turtle_id, command_name, parameters)
end

-- Validate command parameters
function Commands.validateParameters(schema, params)
    for param_name, param_type in pairs(schema) do
        local optional = string.find(param_type, "optional")
        local base_type = string.match(param_type, "(%w+)")
        
        if not optional and params[param_name] == nil then
            return "Missing required parameter: " .. param_name
        end
        
        if params[param_name] ~= nil then
            local actual_type = type(params[param_name])
            if base_type ~= actual_type then
                return "Invalid type for " .. param_name .. ": expected " .. base_type .. ", got " .. actual_type
            end
        end
    end
    
    return nil
end

-- Command Handlers

function Commands.handleMoveTo(turtle_id, params)
    Core.log("INFO", "Moving turtle " .. turtle_id .. " to " .. params.x .. "," .. params.y .. "," .. params.z)
    
    return Network.sendCommand(turtle_id, "move_to", {
        target = {x = params.x, y = params.y, z = params.z},
        use_pathfinding = params.use_pathfinding ~= false
    })
end

function Commands.handleReturnHome(turtle_id, params)
    Core.log("INFO", "Returning turtle " .. turtle_id .. " to home")
    
    return Network.sendCommand(turtle_id, "return_home", {})
end

function Commands.handleMinePattern(turtle_id, params)
    Core.log("INFO", "Starting " .. params.pattern .. " mining on turtle " .. turtle_id)
    
    -- Update turtle task
    Fleet.assignTask(turtle_id, {
        type = "mine_pattern",
        pattern = params.pattern,
        options = params.options
    })
    
    return true
end

function Commands.handleMineArea(turtle_id, params)
    Core.log("INFO", "Assigning area mining to turtle " .. turtle_id)
    
    Fleet.assignTask(turtle_id, {
        type = "mine_area",
        area = {
            x1 = params.x1, y1 = params.y1, z1 = params.z1,
            x2 = params.x2, y2 = params.y2, z2 = params.z2
        }
    })
    
    return true
end

function Commands.handleMineOre(turtle_id, params)
    Core.log("INFO", "Starting ore mining for " .. params.ore_type .. " on turtle " .. turtle_id)
    
    Fleet.assignTask(turtle_id, {
        type = "mine_ore",
        ore_type = params.ore_type,
        max_blocks = params.max_blocks
    })
    
    return true
end

function Commands.handleEmergencyStop(turtle_id, params)
    Core.log("CRITICAL", "Emergency stopping turtle " .. turtle_id .. ": " .. (params.reason or "Manual stop"))
    
    return Network.sendCommand(turtle_id, "emergency_stop", {
        reason = params.reason or "Control computer emergency stop"
    })
end

function Commands.handlePause(turtle_id, params)
    Core.log("INFO", "Pausing turtle " .. turtle_id)
    
    return Network.sendCommand(turtle_id, "pause", {})
end

function Commands.handleResume(turtle_id, params)
    Core.log("INFO", "Resuming turtle " .. turtle_id)
    
    return Network.sendCommand(turtle_id, "resume", {})
end

function Commands.handleGetStatus(turtle_id, params)
    Core.log("DEBUG", "Requesting status from turtle " .. turtle_id)
    
    return Network.requestStatus(turtle_id)
end

function Commands.handleGetInventory(turtle_id, params)
    Core.log("DEBUG", "Requesting inventory from turtle " .. turtle_id)
    
    return Network.sendCommand(turtle_id, "get_inventory", {})
end

function Commands.handleRefuel(turtle_id, params)
    Core.log("INFO", "Refueling turtle " .. turtle_id)
    
    return Network.sendCommand(turtle_id, "refuel", {
        target_level = params.target_level
    })
end

function Commands.handleDepositItems(turtle_id, params)
    Core.log("INFO", "Depositing items from turtle " .. turtle_id)
    
    return Network.sendCommand(turtle_id, "deposit_items", {
        categories = params.categories or {"ore", "valuable", "building"}
    })
end

function Commands.handleUpdateConfig(turtle_id, params)
    Core.log("INFO", "Updating config for turtle " .. turtle_id)
    
    return Network.sendCommand(turtle_id, "update_config", {
        config = params.config
    })
end

-- Execute command on multiple turtles
function Commands.executeMultiple(turtle_ids, command_name, parameters)
    local results = {}
    local success_count = 0
    
    for _, turtle_id in ipairs(turtle_ids) do
        local success, err = Commands.execute(turtle_id, command_name, parameters)
        results[turtle_id] = {success = success, error = err}
        if success then
            success_count = success_count + 1
        end
    end
    
    Core.log("INFO", "Executed " .. command_name .. " on " .. success_count .. "/" .. #turtle_ids .. " turtles")
    
    return results
end

-- Execute command on all online turtles
function Commands.executeAll(command_name, parameters)
    local online_turtles = Fleet.getOnlineTurtles()
    local turtle_ids = {}
    
    for id, _ in pairs(online_turtles) do
        table.insert(turtle_ids, id)
    end
    
    return Commands.executeMultiple(turtle_ids, command_name, parameters)
end

-- Get list of available commands
function Commands.getAvailable()
    local list = {}
    
    for name, command in pairs(Commands.available) do
        table.insert(list, {
            name = name,
            description = command.description,
            parameters = command.parameters
        })
    end
    
    table.sort(list, function(a, b) return a.name < b.name end)
    
    return list
end

-- Send command directly to turtle (wrapper for consistency)
function Commands.sendToTurtle(turtle_id, message)
    return Commands.sendCommand(turtle_id, message.type or message.command, message)
end

-- Shutdown
function Commands.shutdown()
    Core.log("INFO", "Command dispatcher shutting down")
    Commands.initialized = false
    return true
end

return Commands