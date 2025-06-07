-- Monitoring Module
-- Advanced monitoring and analytics for production environments

local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Network = require("turtle.modules.network")

local Monitoring = {}
local monitoring_data = {
    -- Health monitoring
    health = {
        last_check = 0,
        last_heartbeat = 0,
        status = "healthy",
        issues = {}
    },
    
    -- Performance metrics
    performance = {
        operations = {},  -- Circular buffer for recent operations
        current_index = 1,
        max_operations = 1000,
        
        -- Aggregate metrics
        totals = {
            blocks_mined = 0,
            blocks_moved = 0,
            items_collected = 0,
            fuel_consumed = 0,
            errors_encountered = 0,
            time_mining = 0,
            time_moving = 0,
            time_idle = 0
        },
        
        -- Real-time metrics
        current = {
            operation_start = nil,
            operation_type = nil,
            blocks_per_minute = 0,
            fuel_efficiency = 0,
            success_rate = 100
        }
    },
    
    -- Resource discovery analytics
    resources = {
        discoveries = {},  -- Resource type -> discovery data
        ore_density = {},  -- Y-level -> ore density map
        vein_sizes = {},   -- Resource type -> vein size stats
        hotspots = {}      -- High-value areas
    },
    
    -- Historical data
    history = {
        sessions = {},     -- Mining session history
        daily_stats = {},  -- Daily aggregates
        max_sessions = 100
    }
}

-- Constants
local HEALTH_CHECK_INTERVAL = 30
local HEARTBEAT_TIMEOUT = 60
local GHOST_DETECTION_TIMEOUT = 300
local METRIC_UPDATE_INTERVAL = 5

-- Initialize monitoring system
function Monitoring.init()
    Core.log("INFO", "Initializing monitoring system")
    
    -- Load historical data
    local success, saved_data = State.loadFile("monitoring")
    
    -- Ensure saved_data is a table
    if not success or type(saved_data) ~= "table" then
        saved_data = {}
    end
    
    -- Merge saved data
    if saved_data.performance then
        monitoring_data.performance.totals = saved_data.performance.totals or monitoring_data.performance.totals
    end
    
    if saved_data.resources then
        monitoring_data.resources = saved_data.resources
    end
    
    if saved_data.history then
        monitoring_data.history = saved_data.history
    end
    
    -- Start monitoring timers
    Core.schedule_repeating_task("health_check", HEALTH_CHECK_INTERVAL, function()
        Monitoring.performHealthCheck()
    end)
    
    Core.schedule_repeating_task("metric_update", METRIC_UPDATE_INTERVAL, function()
        Monitoring.updateMetrics()
    end)
    
    -- Register event handlers
    Core.on("operation_start", function(op_type)
        Monitoring.startOperation(op_type)
    end)
    
    Core.on("operation_complete", function(op_type, success, data)
        Monitoring.completeOperation(op_type, success, data)
    end)
    
    Core.on("resource_discovered", function(resource_type, count, position)
        Monitoring.recordResourceDiscovery(resource_type, count, position)
    end)
    
    Core.on("error", function(error_type, error_msg)
        Monitoring.recordError(error_type, error_msg)
    end)
    
    return true
end

-- Health detection system
function Monitoring.performHealthCheck()
    local health_issues = {}
    local is_healthy = true
    
    -- Check fuel level
    local fuel_level = turtle.getFuelLevel()
    local fuel_limit = turtle.getFuelLimit()
    
    if fuel_level == "unlimited" then
        -- Unlimited fuel, no issue
    elseif fuel_level < 100 then
        table.insert(health_issues, {
            type = "low_fuel",
            severity = fuel_level < 20 and "critical" or "warning",
            message = "Fuel level low: " .. fuel_level,
            solution = "Refuel turtle or return to base"
        })
        if fuel_level < 20 then
            is_healthy = false
        end
    end
    
    -- Check inventory space
    local empty_slots = 0
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            empty_slots = empty_slots + 1
        end
    end
    
    if empty_slots < 2 then
        table.insert(health_issues, {
            type = "inventory_full",
            severity = empty_slots == 0 and "critical" or "warning",
            message = "Inventory nearly full: " .. empty_slots .. " empty slots",
            solution = "Return to storage or drop items"
        })
        if empty_slots == 0 then
            is_healthy = false
        end
    end
    
    -- Check movement capability
    local can_move = Monitoring.checkMovementHealth()
    if not can_move then
        table.insert(health_issues, {
            type = "movement_blocked",
            severity = "critical",
            message = "Turtle cannot move in any direction",
            solution = "Manual intervention required"
        })
        is_healthy = false
    end
    
    -- Check network connectivity
    local network_healthy = Network.isConnected()
    if not network_healthy then
        table.insert(health_issues, {
            type = "network_disconnected",
            severity = "warning",
            message = "Network connection lost",
            solution = "Check modem and control computer"
        })
    end
    
    -- Update health status
    monitoring_data.health.last_check = os.clock()
    monitoring_data.health.status = is_healthy and "healthy" or "unhealthy"
    monitoring_data.health.issues = health_issues
    
    -- Emit health status
    Core.emit("health_status", is_healthy, health_issues)
    
    -- Send to control if connected
    if network_healthy then
        Network.sendStatus({
            type = "health_report",
            healthy = is_healthy,
            issues = health_issues
        })
    end
    
    -- Log critical issues
    for _, issue in ipairs(health_issues) do
        if issue.severity == "critical" then
            Core.log("ERROR", "Critical health issue: " .. issue.message)
        end
    end
    
    return is_healthy, health_issues
end

-- Check movement health
function Monitoring.checkMovementHealth()
    -- Try each direction
    local directions = {
        {turtle.forward, turtle.back},
        {turtle.up, turtle.down},
        {turtle.turnRight, turtle.turnRight}  -- Turn test
    }
    
    for _, pair in ipairs(directions) do
        -- Try forward direction
        if pair[1]() then
            pair[2]()  -- Return to original position
            return true
        end
        
        -- Try reverse direction
        if pair[2] and pair[2]() then
            pair[1]()  -- Return to original position
            return true
        end
    end
    
    return false
end

-- Ghost turtle detection
function Monitoring.detectGhostState()
    local last_heartbeat = monitoring_data.health.last_heartbeat
    local current_time = os.clock()
    
    -- Check if we haven't sent a heartbeat in too long
    if current_time - last_heartbeat > GHOST_DETECTION_TIMEOUT then
        Core.log("WARNING", "Possible ghost turtle detected - no heartbeat for " .. 
                          (current_time - last_heartbeat) .. " seconds")
        
        -- Attempt recovery
        Monitoring.attemptGhostRecovery()
        return true
    end
    
    -- Check if turtle is responsive
    local responsive = turtle.getFuelLevel() ~= nil
    if not responsive then
        Core.log("ERROR", "Turtle API not responding - ghost state detected")
        return true
    end
    
    return false
end

-- Attempt to recover from ghost state
function Monitoring.attemptGhostRecovery()
    Core.log("INFO", "Attempting ghost recovery")
    
    -- Force state save
    State.saveAll()
    
    -- Attempt network reconnection
    Network.reconnect()
    
    -- Reset operation state
    monitoring_data.performance.current.operation_start = nil
    monitoring_data.performance.current.operation_type = nil
    
    -- Emit recovery event
    Core.emit("ghost_recovery_attempted")
end

-- Performance metric tracking
function Monitoring.startOperation(operation_type)
    monitoring_data.performance.current.operation_start = os.clock()
    monitoring_data.performance.current.operation_type = operation_type
end

function Monitoring.completeOperation(operation_type, success, data)
    local start_time = monitoring_data.performance.current.operation_start
    if not start_time then
        return
    end
    
    local duration = os.clock() - start_time
    
    -- Record operation
    local operation = {
        type = operation_type,
        success = success,
        duration = duration,
        timestamp = os.clock(),
        data = data or {}
    }
    
    -- Add to circular buffer
    local ops = monitoring_data.performance.operations
    local idx = monitoring_data.performance.current_index
    
    ops[idx] = operation
    monitoring_data.performance.current_index = (idx % monitoring_data.performance.max_operations) + 1
    
    -- Update totals
    local totals = monitoring_data.performance.totals
    
    if operation_type == "mine" and success then
        totals.blocks_mined = totals.blocks_mined + 1
        totals.time_mining = totals.time_mining + duration
    elseif operation_type == "move" and success then
        totals.blocks_moved = totals.blocks_moved + 1
        totals.time_moving = totals.time_moving + duration
        totals.fuel_consumed = totals.fuel_consumed + 1
    elseif not success then
        totals.errors_encountered = totals.errors_encountered + 1
    end
    
    -- Clear current operation
    monitoring_data.performance.current.operation_start = nil
    monitoring_data.performance.current.operation_type = nil
end

-- Update real-time metrics
function Monitoring.updateMetrics()
    local current = monitoring_data.performance.current
    local totals = monitoring_data.performance.totals
    
    -- Calculate blocks per minute
    local recent_ops = Monitoring.getRecentOperations(60)  -- Last minute
    local recent_mines = 0
    
    for _, op in ipairs(recent_ops) do
        if op.type == "mine" and op.success then
            recent_mines = recent_mines + 1
        end
    end
    
    current.blocks_per_minute = recent_mines
    
    -- Calculate fuel efficiency
    if totals.fuel_consumed > 0 then
        current.fuel_efficiency = totals.blocks_mined / totals.fuel_consumed
    end
    
    -- Calculate success rate
    local total_ops = #Monitoring.getRecentOperations(300)  -- Last 5 minutes
    local successful_ops = 0
    
    for _, op in ipairs(Monitoring.getRecentOperations(300)) do
        if op.success then
            successful_ops = successful_ops + 1
        end
    end
    
    if total_ops > 0 then
        current.success_rate = (successful_ops / total_ops) * 100
    end
    
    -- Update heartbeat
    monitoring_data.health.last_heartbeat = os.clock()
end

-- Get recent operations
function Monitoring.getRecentOperations(seconds)
    local cutoff = os.clock() - seconds
    local recent = {}
    
    for i = 1, monitoring_data.performance.max_operations do
        local op = monitoring_data.performance.operations[i]
        if op and op.timestamp > cutoff then
            table.insert(recent, op)
        end
    end
    
    return recent
end

-- Resource discovery analytics
function Monitoring.recordResourceDiscovery(resource_type, count, position)
    -- Update discovery data
    local discoveries = monitoring_data.resources.discoveries
    
    if not discoveries[resource_type] then
        discoveries[resource_type] = {
            total_found = 0,
            locations = {},
            vein_sizes = {},
            first_found = os.clock(),
            last_found = os.clock()
        }
    end
    
    local resource_data = discoveries[resource_type]
    resource_data.total_found = resource_data.total_found + count
    resource_data.last_found = os.clock()
    
    -- Record location
    table.insert(resource_data.locations, {
        pos = position,
        count = count,
        timestamp = os.clock()
    })
    
    -- Update vein size statistics
    table.insert(resource_data.vein_sizes, count)
    
    -- Update ore density map
    if position and position.y then
        local y_level = position.y
        local density = monitoring_data.resources.ore_density
        
        if not density[y_level] then
            density[y_level] = {}
        end
        
        density[y_level][resource_type] = (density[y_level][resource_type] or 0) + 1
    end
    
    -- Check for hotspot
    Monitoring.updateHotspots(resource_type, position)
    
    -- Emit discovery event
    Core.emit("resource_analytics_updated", resource_type, count, position)
end

-- Update hotspot detection
function Monitoring.updateHotspots(resource_type, position)
    if not position then return end
    
    local hotspots = monitoring_data.resources.hotspots
    local hotspot_radius = 16
    
    -- Check if near existing hotspot
    local found_hotspot = false
    
    for _, hotspot in ipairs(hotspots) do
        local distance = math.sqrt(
            (position.x - hotspot.center.x)^2 +
            (position.y - hotspot.center.y)^2 +
            (position.z - hotspot.center.z)^2
        )
        
        if distance <= hotspot_radius then
            -- Update existing hotspot
            hotspot.resources[resource_type] = (hotspot.resources[resource_type] or 0) + 1
            hotspot.last_updated = os.clock()
            found_hotspot = true
            break
        end
    end
    
    -- Create new hotspot if needed
    if not found_hotspot then
        table.insert(hotspots, {
            center = position,
            resources = {[resource_type] = 1},
            discovered = os.clock(),
            last_updated = os.clock()
        })
    end
end

-- Record errors
function Monitoring.recordError(error_type, error_msg)
    monitoring_data.performance.totals.errors_encountered = 
        monitoring_data.performance.totals.errors_encountered + 1
    
    -- Add to recent operations as failed
    Monitoring.completeOperation("error", false, {
        type = error_type,
        message = error_msg
    })
end

-- Get performance report
function Monitoring.getPerformanceReport()
    local totals = monitoring_data.performance.totals
    local current = monitoring_data.performance.current
    
    return {
        totals = totals,
        current = {
            blocks_per_minute = current.blocks_per_minute,
            fuel_efficiency = current.fuel_efficiency,
            success_rate = current.success_rate
        },
        uptime = os.clock()
    }
end

-- Get resource analytics
function Monitoring.getResourceAnalytics()
    local analytics = {
        discoveries = {},
        ore_density = monitoring_data.resources.ore_density,
        hotspots = monitoring_data.resources.hotspots
    }
    
    -- Summarize discoveries
    for resource, data in pairs(monitoring_data.resources.discoveries) do
        analytics.discoveries[resource] = {
            total = data.total_found,
            average_vein_size = Monitoring.calculateAverage(data.vein_sizes),
            locations_found = #data.locations,
            discovery_rate = data.total_found / (os.clock() - data.first_found)
        }
    end
    
    return analytics
end

-- Calculate average
function Monitoring.calculateAverage(values)
    if #values == 0 then return 0 end
    
    local sum = 0
    for _, v in ipairs(values) do
        sum = sum + v
    end
    
    return sum / #values
end

-- Create session summary
function Monitoring.createSessionSummary()
    local session = {
        start_time = monitoring_data.session_start or os.clock(),
        end_time = os.clock(),
        performance = Monitoring.getPerformanceReport(),
        resources = Monitoring.getResourceAnalytics(),
        health_issues = #monitoring_data.health.issues
    }
    
    -- Add to history
    local history = monitoring_data.history.sessions
    table.insert(history, 1, session)
    
    -- Limit history size
    while #history > monitoring_data.history.max_sessions do
        table.remove(history)
    end
    
    return session
end

-- Save monitoring data
function Monitoring.save()
    -- Create summary for current session
    Monitoring.createSessionSummary()
    
    -- Save data
    State.save("monitoring", {
        performance = {
            totals = monitoring_data.performance.totals
        },
        resources = monitoring_data.resources,
        history = monitoring_data.history
    })
end

-- Get current health status
function Monitoring.getHealthStatus()
    return monitoring_data.health.status, monitoring_data.health.issues
end

-- Check if ghost state
function Monitoring.isGhost()
    return Monitoring.detectGhostState()
end

-- Get current metrics
function Monitoring.getMetrics()
    return monitoring_data.performance.current
end

-- Get historical data
function Monitoring.getHistory()
    return monitoring_data.history
end

-- Shutdown monitoring
function Monitoring.shutdown()
    Core.log("INFO", "Shutting down monitoring system")
    
    -- Save final data
    Monitoring.save()
    
    -- Cancel scheduled tasks
    Core.cancel_task("health_check")
    Core.cancel_task("metric_update")
end

return Monitoring