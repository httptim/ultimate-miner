-- Alerts Module
-- Progress notifications, error reporting with solutions, and priority-based alerts

local Core = require("turtle.modules.core")
local Network = require("turtle.modules.network")

local Alerts = {}

-- Alert priorities
local PRIORITY = {
    CRITICAL = 1,
    HIGH = 2,
    MEDIUM = 3,
    LOW = 4,
    INFO = 5
}

-- Alert types
local ALERT_TYPES = {
    ERROR = "error",
    WARNING = "warning",
    PROGRESS = "progress",
    SUCCESS = "success",
    INFO = "info"
}

-- Alert storage
local alerts_data = {
    queue = {},           -- Priority queue of pending alerts
    history = {},         -- Recent alert history
    max_history = 100,    -- Maximum history entries
    
    -- Progress tracking
    progress = {
        active = {},      -- Active progress operations
        completed = {}    -- Recently completed operations
    },
    
    -- Error solutions database
    error_solutions = {},
    
    -- Notification settings
    settings = {
        enabled = true,
        min_priority = PRIORITY.INFO,
        network_alerts = true,
        local_display = true,
        alert_sound = true
    }
}

-- Initialize alerts system
function Alerts.init()
    Core.log("INFO", "Initializing alerts system")
    
    -- Load error solutions database
    Alerts.loadErrorSolutions()
    
    -- Register event handlers
    Core.on("alert", function(alert_type, message, priority, data)
        Alerts.create(alert_type, message, priority, data)
    end)
    
    Core.on("progress_update", function(operation_id, progress, message)
        Alerts.updateProgress(operation_id, progress, message)
    end)
    
    Core.on("error", function(error_type, error_msg)
        Alerts.createError(error_type, error_msg)
    end)
    
    -- Initialize last process time
    alerts_data.last_process = os.epoch("utc")
    
    return true
end

-- Load error solutions database
function Alerts.loadErrorSolutions()
    -- Common error patterns and solutions
    alerts_data.error_solutions = {
        -- Movement errors
        ["Movement obstructed"] = {
            solutions = {
                "Check for blocks in the way",
                "Ensure turtle has permission to break blocks",
                "Try alternative path",
                "Use 'dig' before moving"
            },
            priority = PRIORITY.MEDIUM
        },
        
        ["Out of fuel"] = {
            solutions = {
                "Add fuel items to inventory",
                "Return to base for refueling",
                "Enable fuel finding mode",
                "Check fuel settings in config"
            },
            priority = PRIORITY.CRITICAL
        },
        
        ["Lost position"] = {
            solutions = {
                "Use GPS to recalibrate position",
                "Return to known landmark",
                "Reset to home position",
                "Enable position recovery mode"
            },
            priority = PRIORITY.HIGH
        },
        
        -- Inventory errors
        ["Inventory full"] = {
            solutions = {
                "Return to storage",
                "Drop non-valuable items",
                "Compact stackable items",
                "Check inventory filter settings"
            },
            priority = PRIORITY.HIGH
        },
        
        ["No storage found"] = {
            solutions = {
                "Place chest at home position",
                "Configure storage location",
                "Check storage peripheral connection",
                "Verify storage coordinates"
            },
            priority = PRIORITY.HIGH
        },
        
        -- Network errors
        ["Network disconnected"] = {
            solutions = {
                "Check modem attachment",
                "Verify control computer is running",
                "Check wireless range",
                "Restart network module"
            },
            priority = PRIORITY.MEDIUM
        },
        
        ["No response from control"] = {
            solutions = {
                "Ensure control computer is online",
                "Check network protocol version",
                "Verify channel configuration",
                "Restart both turtle and control"
            },
            priority = PRIORITY.MEDIUM
        },
        
        -- Mining errors
        ["Bedrock reached"] = {
            solutions = {
                "Change mining direction",
                "Move to new area",
                "Adjust Y-level settings",
                "Switch mining pattern"
            },
            priority = PRIORITY.LOW
        },
        
        ["Unbreakable block"] = {
            solutions = {
                "Avoid protected areas",
                "Check for claim boundaries",
                "Report block type for whitelist",
                "Try different tool if available"
            },
            priority = PRIORITY.MEDIUM
        },
        
        -- Safety errors
        ["Hazard detected"] = {
            solutions = {
                "Enable safety protocols",
                "Avoid hazardous areas",
                "Use protective measures",
                "Report hazard location"
            },
            priority = PRIORITY.HIGH
        },
        
        ["Emergency stop activated"] = {
            solutions = {
                "Check for critical issues",
                "Review recent alerts",
                "Manually clear emergency state",
                "Restart after resolving issues"
            },
            priority = PRIORITY.CRITICAL
        }
    }
end

-- Create alert
function Alerts.create(alert_type, message, priority, data)
    priority = priority or PRIORITY.INFO
    
    -- Check if alerts are enabled
    if not alerts_data.settings.enabled then
        return
    end
    
    -- Check priority threshold
    if priority > alerts_data.settings.min_priority then
        return
    end
    
    -- Create alert object
    local alert = {
        id = os.clock() .. "_" .. math.random(1000),
        type = alert_type,
        message = message,
        priority = priority,
        timestamp = os.clock(),
        data = data or {},
        processed = false
    }
    
    -- Add to queue
    table.insert(alerts_data.queue, alert)
    
    -- Sort by priority
    table.sort(alerts_data.queue, function(a, b)
        return a.priority < b.priority
    end)
    
    -- Log critical alerts
    if priority <= PRIORITY.HIGH then
        Core.log("ALERT", string.format("[%s] %s", alert_type:upper(), message))
    end
    
    -- Immediate processing for critical alerts
    if priority == PRIORITY.CRITICAL then
        Alerts.processAlert(alert)
    end
    
    return alert.id
end

-- Create error alert with solutions
function Alerts.createError(error_type, error_msg)
    local solutions = nil
    local priority = PRIORITY.HIGH
    
    -- Find matching error solution
    for pattern, solution_data in pairs(alerts_data.error_solutions) do
        if error_msg:find(pattern) then
            solutions = solution_data.solutions
            priority = solution_data.priority
            break
        end
    end
    
    -- Create error alert
    local alert_data = {
        error_type = error_type,
        error_message = error_msg,
        solutions = solutions or {"Check logs for details", "Contact support if issue persists"}
    }
    
    Alerts.create(ALERT_TYPES.ERROR, error_msg, priority, alert_data)
end

-- Progress notification system
function Alerts.startProgress(operation_id, operation_name, total)
    local progress_op = {
        id = operation_id,
        name = operation_name,
        total = total or 100,
        current = 0,
        start_time = os.clock(),
        last_update = os.clock(),
        message = "Starting " .. operation_name
    }
    
    alerts_data.progress.active[operation_id] = progress_op
    
    -- Create initial notification
    Alerts.create(ALERT_TYPES.PROGRESS, progress_op.message, PRIORITY.INFO, {
        operation_id = operation_id,
        progress = 0
    })
    
    return operation_id
end

-- Update progress
function Alerts.updateProgress(operation_id, current, message)
    local progress_op = alerts_data.progress.active[operation_id]
    if not progress_op then
        return
    end
    
    progress_op.current = current
    progress_op.last_update = os.clock()
    
    if message then
        progress_op.message = message
    end
    
    -- Calculate percentage
    local percentage = math.floor((current / progress_op.total) * 100)
    
    -- Calculate ETA
    local elapsed = os.clock() - progress_op.start_time
    local rate = current / elapsed
    local remaining = progress_op.total - current
    local eta = rate > 0 and (remaining / rate) or 0
    
    -- Create progress update alert
    local update_message = string.format("%s: %d%% (ETA: %ds)", 
                                       progress_op.name, percentage, math.floor(eta))
    
    -- Only send updates at intervals
    if percentage % 10 == 0 or current >= progress_op.total then
        Alerts.create(ALERT_TYPES.PROGRESS, update_message, PRIORITY.LOW, {
            operation_id = operation_id,
            progress = percentage,
            eta = eta
        })
    end
    
    -- Complete if done
    if current >= progress_op.total then
        Alerts.completeProgress(operation_id, "Completed: " .. progress_op.name)
    end
end

-- Complete progress operation
function Alerts.completeProgress(operation_id, message)
    local progress_op = alerts_data.progress.active[operation_id]
    if not progress_op then
        return
    end
    
    -- Calculate duration
    local duration = os.clock() - progress_op.start_time
    
    -- Move to completed
    progress_op.completed_time = os.clock()
    progress_op.duration = duration
    alerts_data.progress.completed[operation_id] = progress_op
    alerts_data.progress.active[operation_id] = nil
    
    -- Create completion alert
    local complete_msg = message or ("Completed: " .. progress_op.name)
    complete_msg = complete_msg .. string.format(" (took %.1fs)", duration)
    
    Alerts.create(ALERT_TYPES.SUCCESS, complete_msg, PRIORITY.INFO, {
        operation_id = operation_id,
        duration = duration
    })
end

-- Process alert queue
function Alerts.processQueue()
    local processed = 0
    local max_per_cycle = 5
    
    while #alerts_data.queue > 0 and processed < max_per_cycle do
        local alert = alerts_data.queue[1]
        
        if not alert.processed then
            Alerts.processAlert(alert)
            alert.processed = true
            processed = processed + 1
        end
        
        -- Remove from queue
        table.remove(alerts_data.queue, 1)
        
        -- Add to history
        table.insert(alerts_data.history, 1, alert)
        
        -- Limit history size
        while #alerts_data.history > alerts_data.max_history do
            table.remove(alerts_data.history)
        end
    end
end

-- Process individual alert
function Alerts.processAlert(alert)
    -- Local display
    if alerts_data.settings.local_display then
        Alerts.displayLocal(alert)
    end
    
    -- Network notification
    if alerts_data.settings.network_alerts and Network.isConnected() then
        Alerts.sendNetworkAlert(alert)
    end
    
    -- Sound notification for high priority
    if alerts_data.settings.alert_sound and alert.priority <= PRIORITY.HIGH then
        Alerts.playAlertSound(alert.priority)
    end
    
    -- Special handling by type
    if alert.type == ALERT_TYPES.ERROR and alert.data.solutions then
        Alerts.displaySolutions(alert.data.solutions)
    end
end

-- Display alert locally
function Alerts.displayLocal(alert)
    -- Color coding by type
    local colors_map = {
        [ALERT_TYPES.ERROR] = colors.red,
        [ALERT_TYPES.WARNING] = colors.yellow,
        [ALERT_TYPES.SUCCESS] = colors.green,
        [ALERT_TYPES.PROGRESS] = colors.lightBlue,
        [ALERT_TYPES.INFO] = colors.white
    }
    
    local color = colors_map[alert.type] or colors.white
    
    -- Format message
    local prefix = string.format("[%s]", alert.type:upper())
    
    -- Print with color if available
    if term.isColor and term.isColor() then
        term.setTextColor(color)
    end
    
    print(prefix .. " " .. alert.message)
    
    if term.isColor and term.isColor() then
        term.setTextColor(colors.white)
    end
end

-- Display error solutions
function Alerts.displaySolutions(solutions)
    if not solutions or #solutions == 0 then
        return
    end
    
    print("Possible solutions:")
    for i, solution in ipairs(solutions) do
        print(" " .. i .. ". " .. solution)
    end
end

-- Send network alert
function Alerts.sendNetworkAlert(alert)
    Network.sendStatus({
        type = "alert",
        alert = {
            id = alert.id,
            type = alert.type,
            message = alert.message,
            priority = alert.priority,
            timestamp = alert.timestamp,
            data = alert.data
        }
    })
end

-- Play alert sound
function Alerts.playAlertSound(priority)
    -- Use computer speaker if available
    local speaker = peripheral.find("speaker")
    if speaker then
        if priority == PRIORITY.CRITICAL then
            speaker.playNote("harp", 2, 6)
            os.sleep(0.1)
            speaker.playNote("harp", 2, 6)
        elseif priority == PRIORITY.HIGH then
            speaker.playNote("bell", 1, 12)
        else
            speaker.playNote("hat", 1, 20)
        end
    end
end

-- Get active progress operations
function Alerts.getActiveProgress()
    local active = {}
    
    for id, op in pairs(alerts_data.progress.active) do
        local percentage = math.floor((op.current / op.total) * 100)
        table.insert(active, {
            id = id,
            name = op.name,
            progress = percentage,
            message = op.message,
            duration = os.clock() - op.start_time
        })
    end
    
    return active
end

-- Get alert history
function Alerts.getHistory(count, filter_type, min_priority)
    count = count or 50
    local filtered = {}
    
    for _, alert in ipairs(alerts_data.history) do
        local matches = true
        
        if filter_type and alert.type ~= filter_type then
            matches = false
        end
        
        if min_priority and alert.priority > min_priority then
            matches = false
        end
        
        if matches then
            table.insert(filtered, alert)
            if #filtered >= count then
                break
            end
        end
    end
    
    return filtered
end

-- Configure alert settings
function Alerts.configure(settings)
    for key, value in pairs(settings) do
        if alerts_data.settings[key] ~= nil then
            alerts_data.settings[key] = value
        end
    end
end

-- Clear alerts
function Alerts.clear()
    alerts_data.queue = {}
    Core.log("INFO", "Alert queue cleared")
end

-- Get priority name
function Alerts.getPriorityName(priority)
    for name, value in pairs(PRIORITY) do
        if value == priority then
            return name
        end
    end
    return "UNKNOWN"
end

-- Tick function to be called periodically from main loop
function Alerts.tick()
    local current_time = os.epoch("utc")
    
    -- Check if alert processing is due (every 1 second)
    if current_time - (alerts_data.last_process or 0) >= 1000 then
        Alerts.processQueue()
        alerts_data.last_process = current_time
    end
end

-- Shutdown
function Alerts.shutdown()
    Core.log("INFO", "Shutting down alerts system")
    
    -- Process any remaining alerts
    while #alerts_data.queue > 0 do
        Alerts.processQueue()
    end
end

-- Export constants
Alerts.PRIORITY = PRIORITY
Alerts.TYPES = ALERT_TYPES

return Alerts