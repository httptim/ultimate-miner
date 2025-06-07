-- Fleet Management Module
-- Manages turtle registration, status tracking, and coordination

local Fleet = {}
local Core = require("control.modules.core")
local Network = require("control.modules.network")

-- Configuration
Fleet.HEARTBEAT_TIMEOUT = 30  -- Seconds before marking turtle as offline
Fleet.STATUS_CHECK_INTERVAL = 5  -- How often to check turtle statuses

-- State
Fleet.initialized = false
Fleet.turtles = {}  -- [id] = turtle_data
Fleet.status_timer = nil

-- Turtle data structure
-- {
--   id = number,
--   name = string,
--   status = "online|offline|busy|error",
--   last_heartbeat = timestamp,
--   position = {x, y, z, facing},
--   fuel_level = number,
--   fuel_limit = number,
--   current_task = string,
--   task_progress = table,
--   inventory_summary = table,
--   registered_time = timestamp,
--   total_blocks_mined = number,
--   errors = table (array of recent errors)
-- }

-- Initialize fleet management
function Fleet.init()
    if Fleet.initialized then
        Core.log("INFO", "Fleet already initialized")
        return true, "Already initialized"
    end
    
    -- Register network handlers
    Fleet.registerHandlers()
    
    -- Start status monitoring
    Fleet.startStatusMonitoring()
    
    -- Load saved fleet data
    Fleet.loadFleetData()
    
    Fleet.initialized = true
    Core.log("INFO", "Fleet management initialized")
    
    return true, "Fleet initialized successfully"
end

-- Register network message handlers
function Fleet.registerHandlers()
    -- Handle turtle coming online
    Network.registerHandler("turtle_online", function(sender, message)
        Fleet.registerTurtle(sender, {
            name = message.name or "Turtle " .. sender,
            position = message.position,
            fuel_level = message.fuel_level,
            fuel_limit = message.fuel_limit
        })
    end)
    
    -- Handle turtle going offline
    Network.registerHandler("turtle_offline", function(sender, message)
        Fleet.unregisterTurtle(sender, message.reason)
    end)
    
    -- Handle heartbeat
    Network.registerHandler("heartbeat", function(sender, message)
        Fleet.updateHeartbeat(sender, message)
    end)
    
    -- Handle status updates
    Network.registerHandler("status_update", function(sender, message)
        Fleet.updateStatus(sender, message)
    end)
    
    -- Handle task completion
    Network.registerHandler("task_complete", function(sender, message)
        Fleet.handleTaskComplete(sender, message)
    end)
    
    -- Handle errors
    Network.registerHandler("error", function(sender, message)
        Fleet.handleError(sender, message)
    end)
    
    Core.log("INFO", "Fleet network handlers registered")
end

-- Register a new turtle
function Fleet.registerTurtle(id, info)
    if Fleet.turtles[id] then
        Core.log("INFO", "Turtle " .. id .. " re-registered")
    else
        Core.log("INFO", "New turtle registered: " .. id)
    end
    
    Fleet.turtles[id] = {
        id = id,
        name = info.name or "Turtle " .. id,
        status = "online",
        last_heartbeat = os.epoch("utc"),
        position = info.position or {x = 0, y = 0, z = 0, facing = 0},
        fuel_level = info.fuel_level or 0,
        fuel_limit = info.fuel_limit or 20000,
        current_task = "idle",
        task_progress = {},
        inventory_summary = info.inventory_summary or {},
        registered_time = Fleet.turtles[id] and Fleet.turtles[id].registered_time or os.epoch("utc"),
        total_blocks_mined = Fleet.turtles[id] and Fleet.turtles[id].total_blocks_mined or 0,
        errors = {}
    }
    
    -- Emit event
    Core.emit("fleet:turtle_joined", id, Fleet.turtles[id])
    
    -- Save fleet data
    Fleet.saveFleetData()
    
    return true
end

-- Unregister a turtle
function Fleet.unregisterTurtle(id, reason)
    if not Fleet.turtles[id] then
        return false, "Turtle not registered"
    end
    
    Core.log("INFO", "Turtle " .. id .. " going offline: " .. (reason or "Unknown"))
    
    Fleet.turtles[id].status = "offline"
    Fleet.turtles[id].last_offline = os.epoch("utc")
    
    -- Emit event
    Core.emit("fleet:turtle_left", id, reason)
    
    -- Save fleet data
    Fleet.saveFleetData()
    
    return true
end

-- Update turtle heartbeat
function Fleet.updateHeartbeat(id, data)
    if not Fleet.turtles[id] then
        -- Auto-register if not known
        Fleet.registerTurtle(id, data)
    end
    
    local turtle = Fleet.turtles[id]
    turtle.last_heartbeat = os.epoch("utc")
    turtle.status = "online"
    
    -- Update data from heartbeat
    if data.position then turtle.position = data.position end
    if data.fuel_level then turtle.fuel_level = data.fuel_level end
    if data.fuel_limit then turtle.fuel_limit = data.fuel_limit end
    if data.current_task then turtle.current_task = data.current_task end
    if data.task_progress then turtle.task_progress = data.task_progress end
    if data.inventory_summary then turtle.inventory_summary = data.inventory_summary end
    
    return true
end

-- Update turtle status
function Fleet.updateStatus(id, status)
    if not Fleet.turtles[id] then
        return false, "Turtle not registered"
    end
    
    local turtle = Fleet.turtles[id]
    
    -- Update all provided fields
    for key, value in pairs(status) do
        if key ~= "id" and key ~= "type" and key ~= "timestamp" then
            turtle[key] = value
        end
    end
    
    -- Update last contact time
    turtle.last_heartbeat = os.epoch("utc")
    
    -- Emit event
    Core.emit("fleet:status_update", id, status)
    
    return true
end

-- Get turtle by ID
function Fleet.getTurtle(id)
    return Fleet.turtles[id]
end

-- Get all turtles
function Fleet.getAllTurtles()
    return Fleet.turtles
end

-- Get online turtles
function Fleet.getOnlineTurtles()
    local online = {}
    for id, turtle in pairs(Fleet.turtles) do
        if turtle.status == "online" then
            online[id] = turtle
        end
    end
    return online
end

-- Get turtle count by status
function Fleet.getStatusCounts()
    local counts = {
        online = 0,
        offline = 0,
        busy = 0,
        error = 0,
        total = 0
    }
    
    for _, turtle in pairs(Fleet.turtles) do
        counts.total = counts.total + 1
        counts[turtle.status] = (counts[turtle.status] or 0) + 1
    end
    
    return counts
end

-- Start status monitoring
function Fleet.startStatusMonitoring()
    Fleet.status_timer = os.startTimer(Fleet.STATUS_CHECK_INTERVAL)
    
    -- Register timer handler
    Core.on("timer", function(timer_id)
        if timer_id == Fleet.status_timer then
            Fleet.checkTurtleStatuses()
            Fleet.status_timer = os.startTimer(Fleet.STATUS_CHECK_INTERVAL)
        end
    end)
    
    Core.log("INFO", "Status monitoring started")
end

-- Check all turtle statuses
function Fleet.checkTurtleStatuses()
    local current_time = os.epoch("utc")
    local timeout_threshold = current_time - (Fleet.HEARTBEAT_TIMEOUT * 1000)
    
    for id, turtle in pairs(Fleet.turtles) do
        if turtle.status == "online" and turtle.last_heartbeat < timeout_threshold then
            Core.log("WARNING", "Turtle " .. id .. " timed out")
            turtle.status = "offline"
            Core.emit("fleet:turtle_timeout", id)
        end
    end
end

-- Assign task to turtle
function Fleet.assignTask(turtle_id, task)
    local turtle = Fleet.turtles[turtle_id]
    if not turtle then
        return false, "Turtle not registered"
    end
    
    if turtle.status ~= "online" then
        return false, "Turtle not online"
    end
    
    -- Send task command
    local success = Network.sendCommand(turtle_id, "execute_task", task)
    if success then
        turtle.current_task = task.type or "unknown"
        turtle.task_progress = {
            started = os.epoch("utc"),
            task = task
        }
        Core.emit("fleet:task_assigned", turtle_id, task)
    end
    
    return success
end

-- Handle task completion
function Fleet.handleTaskComplete(id, result)
    local turtle = Fleet.turtles[id]
    if not turtle then
        return
    end
    
    Core.log("INFO", "Turtle " .. id .. " completed task: " .. turtle.current_task)
    
    -- Update turtle state
    turtle.current_task = "idle"
    turtle.task_progress = {}
    
    -- Update statistics
    if result.blocks_mined then
        turtle.total_blocks_mined = turtle.total_blocks_mined + result.blocks_mined
    end
    
    -- Emit event
    Core.emit("fleet:task_completed", id, result)
    
    -- Save data
    Fleet.saveFleetData()
end

-- Handle turtle error
function Fleet.handleError(id, error_data)
    local turtle = Fleet.turtles[id]
    if not turtle then
        return
    end
    
    Core.log("ERROR", "Turtle " .. id .. " error: " .. (error_data.message or "Unknown"))
    
    -- Add to error history
    table.insert(turtle.errors, {
        timestamp = os.epoch("utc"),
        message = error_data.message,
        task = turtle.current_task,
        position = error_data.position or turtle.position
    })
    
    -- Keep only last 10 errors
    while #turtle.errors > 10 do
        table.remove(turtle.errors, 1)
    end
    
    -- Update status
    turtle.status = "error"
    
    -- Emit event
    Core.emit("fleet:turtle_error", id, error_data)
end

-- Send command to all online turtles
function Fleet.broadcastCommand(command, data)
    local sent_count = 0
    
    for id, turtle in pairs(Fleet.turtles) do
        if turtle.status == "online" then
            if Network.sendCommand(id, command, data) then
                sent_count = sent_count + 1
            end
        end
    end
    
    Core.log("INFO", "Broadcast command '" .. command .. "' to " .. sent_count .. " turtles")
    
    return sent_count
end

-- Emergency stop all turtles
function Fleet.emergencyStopAll(reason)
    Core.log("CRITICAL", "Emergency stopping all turtles: " .. (reason or "Unknown"))
    
    -- Use network emergency stop
    Network.emergencyStopAll(reason)
    
    -- Update all turtle statuses
    for id, turtle in pairs(Fleet.turtles) do
        if turtle.status == "online" then
            turtle.current_task = "emergency_stopped"
            turtle.task_progress = {
                reason = reason,
                timestamp = os.epoch("utc")
            }
        end
    end
    
    return true
end

-- Save fleet data to disk
function Fleet.saveFleetData()
    local data = {
        version = 1,
        turtles = Fleet.turtles,
        saved_time = os.epoch("utc")
    }
    
    local file = fs.open("/control/data/fleet.dat", "w")
    if file then
        file.write(textutils.serialize(data))
        file.close()
        return true
    end
    
    return false
end

-- Load fleet data from disk
function Fleet.loadFleetData()
    if not fs.exists("/control/data/fleet.dat") then
        return false
    end
    
    local file = fs.open("/control/data/fleet.dat", "r")
    if file then
        local content = file.readAll()
        file.close()
        
        local data = textutils.unserialize(content)
        if data and data.version == 1 then
            Fleet.turtles = data.turtles or {}
            
            -- Mark all as offline initially
            for id, turtle in pairs(Fleet.turtles) do
                turtle.status = "offline"
            end
            
            Core.log("INFO", "Loaded fleet data with " .. #Core.tableKeys(Fleet.turtles) .. " turtles")
            return true
        end
    end
    
    return false
end

-- Get fleet statistics
function Fleet.getStats()
    local stats = {
        counts = Fleet.getStatusCounts(),
        total_blocks_mined = 0,
        total_fuel_used = 0,
        oldest_turtle = nil,
        newest_turtle = nil
    }
    
    for id, turtle in pairs(Fleet.turtles) do
        stats.total_blocks_mined = stats.total_blocks_mined + (turtle.total_blocks_mined or 0)
        
        if not stats.oldest_turtle or turtle.registered_time < stats.oldest_turtle.registered_time then
            stats.oldest_turtle = {id = id, time = turtle.registered_time}
        end
        
        if not stats.newest_turtle or turtle.registered_time > stats.newest_turtle.registered_time then
            stats.newest_turtle = {id = id, time = turtle.registered_time}
        end
    end
    
    return stats
end

-- Request status update from all turtles
function Fleet.requestStatusUpdate()
    return Fleet.broadcastCommand("status_update", {})
end

-- Get all turtle IDs
function Fleet.getAllTurtleIDs()
    local ids = {}
    for id, _ in pairs(Fleet.turtles) do
        table.insert(ids, id)
    end
    return ids
end

-- Get available turtles (idle or online)
function Fleet.getAvailableTurtles()
    local available = {}
    for id, turtle in pairs(Fleet.turtles) do
        if turtle.status == "idle" or turtle.status == "online" then
            table.insert(available, id)
        end
    end
    return available
end

-- Request status from specific turtle
function Fleet.requestTurtleStatus(turtle_id)
    return Commands.sendCommand(turtle_id, "status_update", {})
end

-- Get recent events (for monitor display)
function Fleet.getRecentEvents(count)
    -- TODO: Implement event tracking
    return {}
end

-- Get fleet statistics (enhanced version for monitor)
function Fleet.getFleetStatistics()
    local stats = Fleet.getStats()
    
    -- Add resource breakdown
    stats.resources = {}
    stats.uptime_percentage = 0
    stats.total_ores_found = 0
    
    local online_count = 0
    for id, turtle in pairs(Fleet.turtles) do
        if turtle.status ~= "offline" then
            online_count = online_count + 1
        end
        
        -- Aggregate ore counts
        if turtle.ores_found then
            stats.total_ores_found = stats.total_ores_found + turtle.ores_found
        end
    end
    
    local total_count = Fleet.getTurtleCount()
    if total_count > 0 then
        stats.uptime_percentage = (online_count / total_count) * 100
    end
    
    return stats
end

-- Shutdown fleet management
function Fleet.shutdown()
    Core.log("INFO", "Fleet management shutting down")
    
    -- Save data
    Fleet.saveFleetData()
    
    -- Cancel timers
    if Fleet.status_timer then
        os.cancelTimer(Fleet.status_timer)
    end
    
    Fleet.initialized = false
    
    return true
end

return Fleet