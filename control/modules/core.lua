-- Core Control Module
-- Provides device detection and initialization for control computer

local Core = {}

-- Module information
Core.VERSION = "1.0.0"
Core.NAME = "Control Core"

-- Device capabilities
Core.capabilities = {
    is_computer = false,
    is_advanced = false,
    has_color = false,
    screen_width = 0,
    screen_height = 0,
    has_mouse = false,
    has_touch = false,
    has_speaker = false,
    modem_sides = {}
}

-- Logging
Core.log_level = "INFO"
Core.log_file = "/control/logs/control.log"

-- Initialize the core module
function Core.init()
    -- Detect device type
    Core.detectDevice()
    
    -- Initialize logging
    Core.initLogging()
    
    -- Set up base directories
    Core.setupDirectories()
    
    Core.log("INFO", "Control Core initialized")
    Core.log("INFO", "Device type: " .. (Core.capabilities.is_advanced and "Advanced" or "Standard") .. " Computer")
    
    return true, "Core initialized successfully"
end

-- Detect device capabilities
function Core.detectDevice()
    -- Check if we're running on a computer (not a turtle)
    Core.capabilities.is_computer = not turtle
    
    if not Core.capabilities.is_computer then
        error("Control software must run on a computer, not a turtle")
    end
    
    -- Check for advanced computer
    Core.capabilities.is_advanced = term.isColor and term.isColor() or false
    Core.capabilities.has_color = Core.capabilities.is_advanced
    
    -- Get screen dimensions
    Core.capabilities.screen_width, Core.capabilities.screen_height = term.getSize()
    
    -- Check for mouse support (advanced computers have mouse)
    Core.capabilities.has_mouse = Core.capabilities.is_advanced
    
    -- Check for touch support (monitors with touch)
    -- This would need to be detected when a monitor is attached
    Core.capabilities.has_touch = false
    
    -- Check for speaker
    Core.capabilities.has_speaker = peripheral.find("speaker") ~= nil
    
    -- Find all modem sides
    Core.capabilities.modem_sides = {}
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
        if peripheral.getType(side) == "modem" then
            table.insert(Core.capabilities.modem_sides, side)
        end
    end
end

-- Initialize logging system
function Core.initLogging()
    -- Create logs directory if it doesn't exist
    local log_dir = fs.getDir(Core.log_file)
    if not fs.exists(log_dir) then
        fs.makeDir(log_dir)
    end
end

-- Setup required directories
function Core.setupDirectories()
    local dirs = {
        "/control/logs",
        "/control/data",
        "/control/config",
        "/control/backups"
    }
    
    for _, dir in ipairs(dirs) do
        if not fs.exists(dir) then
            fs.makeDir(dir)
        end
    end
end

-- Logging function
function Core.log(level, message)
    local levels = {DEBUG = 1, INFO = 2, WARNING = 3, ERROR = 4, CRITICAL = 5}
    local current_level = levels[Core.log_level] or 2
    local msg_level = levels[level] or 2
    
    if msg_level >= current_level then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S", os.epoch("local") / 1000)
        local log_entry = string.format("[%s] [%s] %s", timestamp, level, message)
        
        -- Print to console
        if Core.capabilities.has_color then
            local colors_map = {
                DEBUG = colors.gray,
                INFO = colors.white,
                WARNING = colors.yellow,
                ERROR = colors.red,
                CRITICAL = colors.magenta
            }
            term.setTextColor(colors_map[level] or colors.white)
        end
        print(log_entry)
        if Core.capabilities.has_color then
            term.setTextColor(colors.white)
        end
        
        -- Write to log file
        local file = fs.open(Core.log_file, "a")
        if file then
            file.writeLine(log_entry)
            file.close()
        end
    end
end

-- Event system
Core.event_handlers = {}

-- Register an event handler
function Core.on(event, handler)
    if not Core.event_handlers[event] then
        Core.event_handlers[event] = {}
    end
    table.insert(Core.event_handlers[event], handler)
    return #Core.event_handlers[event]
end

-- Remove an event handler
function Core.off(event, handler_id)
    if Core.event_handlers[event] and Core.event_handlers[event][handler_id] then
        table.remove(Core.event_handlers[event], handler_id)
        return true
    end
    return false
end

-- Emit an event
function Core.emit(event, ...)
    if Core.event_handlers[event] then
        for _, handler in ipairs(Core.event_handlers[event]) do
            local success, err = pcall(handler, ...)
            if not success then
                Core.log("ERROR", "Event handler error for " .. event .. ": " .. tostring(err))
            end
        end
    end
end

-- Utility functions
function Core.sleep(seconds)
    os.sleep(seconds or 0)
end

function Core.tableContains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

function Core.deepCopy(tbl)
    if type(tbl) ~= "table" then
        return tbl
    end
    
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = Core.deepCopy(v)
    end
    
    return copy
end

function Core.tableKeys(tbl)
    local keys = {}
    for k, _ in pairs(tbl or {}) do
        table.insert(keys, k)
    end
    return keys
end

-- Get device capabilities
function Core.getCapabilities()
    return Core.deepCopy(Core.capabilities)
end

-- Format time duration
function Core.formatDuration(seconds)
    if seconds < 60 then
        return string.format("%.1fs", seconds)
    elseif seconds < 3600 then
        return string.format("%.1fm", seconds / 60)
    else
        return string.format("%.1fh", seconds / 3600)
    end
end

-- Shutdown
function Core.shutdown()
    Core.log("INFO", "Control Core shutting down")
    Core.emit("shutdown")
    return true
end

return Core