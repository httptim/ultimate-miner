-- Core Module
-- Provides fundamental utilities used by all other modules

local CONSTANTS = require("shared.constants")

local Core = {}

-- Module state
local event_handlers = {}
local event_id_counter = 0
local log_file = nil
local log_level = CONSTANTS.LOG_LEVELS.INFO
local debug_mode = false

-- Initialize the core module
function Core.init(options)
    options = options or {}
    
    -- Set debug mode
    debug_mode = options.debug or CONSTANTS.DEFAULTS.DEBUG_MODE
    
    -- Set log level
    if options.log_level then
        log_level = options.log_level
    elseif debug_mode then
        log_level = CONSTANTS.LOG_LEVELS.DEBUG
    end
    
    -- Initialize log file if requested
    if options.log_file then
        local file, err = fs.open(options.log_file, "w")
        if file then
            log_file = file
            Core.log("INFO", "Core module initialized with logging to " .. options.log_file)
        else
            print("Warning: Could not open log file: " .. tostring(err))
        end
    end
    
    Core.log("INFO", "Core module initialized")
    return true, "Core initialized successfully"
end

-- Shutdown the core module
function Core.shutdown()
    if log_file then
        log_file.close()
        log_file = nil
    end
end

-- Logging Functions
function Core.log(level, message)
    local level_num = CONSTANTS.LOG_LEVELS[level] or CONSTANTS.LOG_LEVELS.INFO
    
    -- Check if we should log this level
    if level_num < log_level then
        return
    end
    
    -- Format timestamp
    local time = os.date("%H:%M:%S")
    local formatted = string.format("[%s] [%s] %s", time, level, message)
    
    -- Always print errors and above
    if level_num >= CONSTANTS.LOG_LEVELS.ERROR or debug_mode then
        print(formatted)
    end
    
    -- Write to log file if available
    if log_file then
        log_file.writeLine(formatted)
        log_file.flush()
    end
end

-- Convenience logging functions
function Core.debug(message) Core.log("DEBUG", message) end
function Core.info(message) Core.log("INFO", message) end
function Core.warning(message) Core.log("WARNING", message) end
function Core.error(message) Core.log("ERROR", message) end
function Core.critical(message) Core.log("CRITICAL", message) end

-- Event System
function Core.emit(event_name, data)
    Core.debug("Emitting event: " .. event_name)
    
    -- Queue the event for os.pullEvent to receive
    os.queueEvent("core_event", event_name, data)
    
    -- Also call registered handlers directly
    if event_handlers[event_name] then
        for id, handler in pairs(event_handlers[event_name]) do
            local success, err = pcall(handler, data)
            if not success then
                Core.error("Event handler error for " .. event_name .. ": " .. tostring(err))
            end
        end
    end
end

function Core.on(event_name, handler)
    if type(handler) ~= "function" then
        return nil
    end
    
    -- Initialize event handler table if needed
    if not event_handlers[event_name] then
        event_handlers[event_name] = {}
    end
    
    -- Generate unique handler ID
    event_id_counter = event_id_counter + 1
    local handler_id = event_id_counter
    
    -- Store handler
    event_handlers[event_name][handler_id] = handler
    
    Core.debug("Registered handler " .. handler_id .. " for event " .. event_name)
    return handler_id
end

function Core.off(event_name, handler_id)
    if event_handlers[event_name] and event_handlers[event_name][handler_id] then
        event_handlers[event_name][handler_id] = nil
        Core.debug("Unregistered handler " .. handler_id .. " for event " .. event_name)
        return true
    end
    return false
end

-- Vector Operations (extends built-in vector API)
Core.vector = {}

-- Create a new vector
function Core.vector.new(x, y, z)
    return vector.new(x or 0, y or 0, z or 0)
end

-- Add two vectors
function Core.vector.add(v1, v2)
    return v1 + v2
end

-- Subtract two vectors
function Core.vector.subtract(v1, v2)
    return v1 - v2
end

-- Calculate distance between two vectors
function Core.vector.distance(v1, v2)
    return (v1 - v2):length()
end

-- Check if two vectors are equal
function Core.vector.equals(v1, v2)
    return v1.x == v2.x and v1.y == v2.y and v1.z == v2.z
end

-- Convert direction to vector
function Core.vector.fromDirection(direction)
    return CONSTANTS.DIRECTION_VECTORS[direction] or {x = 0, y = 0, z = 0}
end

-- Get Manhattan distance (for fuel calculations)
function Core.vector.manhattan(v1, v2)
    return math.abs(v1.x - v2.x) + math.abs(v1.y - v2.y) + math.abs(v1.z - v2.z)
end

-- Utility Functions

-- Smart sleep that yields to prevent "too long without yielding"
function Core.sleep(seconds)
    if seconds <= 0 then
        os.sleep(0)  -- Just yield
    else
        os.sleep(seconds)
    end
end

-- Check if table contains a value
function Core.tableContains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- Deep copy a table
function Core.deepCopy(original)
    local copy
    if type(original) == 'table' then
        copy = {}
        for key, value in pairs(original) do
            copy[Core.deepCopy(key)] = Core.deepCopy(value)
        end
        setmetatable(copy, Core.deepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

-- Merge tables (shallow merge)
function Core.mergeTables(base, override)
    local result = {}
    
    -- Copy base table
    for k, v in pairs(base or {}) do
        result[k] = v
    end
    
    -- Override with new values
    for k, v in pairs(override or {}) do
        result[k] = v
    end
    
    return result
end

-- Clamp a value between min and max
function Core.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Round a number to specified decimal places
function Core.round(value, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(value * mult + 0.5) / mult
end

-- Generate a unique ID
local id_counter = 0
function Core.generateId(prefix)
    id_counter = id_counter + 1
    return (prefix or "id") .. "_" .. os.computerID() .. "_" .. id_counter .. "_" .. os.epoch("utc")
end

-- Get table size (counts all keys, not just numeric)
function Core.tableSize(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do
        count = count + 1
    end
    return count
end

-- Get keys from a table
function Core.tableKeys(tbl)
    local keys = {}
    for k, _ in pairs(tbl or {}) do
        table.insert(keys, k)
    end
    return keys
end

-- Format time duration
function Core.formatDuration(seconds)
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds / 60), seconds % 60)
    else
        return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

-- Validate position table
function Core.isValidPosition(pos)
    return pos and 
           type(pos.x) == "number" and 
           type(pos.y) == "number" and 
           type(pos.z) == "number"
end

-- Error handling wrapper
function Core.try(func, error_handler)
    local success, result = pcall(func)
    if success then
        return true, result
    else
        if error_handler then
            error_handler(result)
        end
        return false, result
    end
end

-- Yield periodically in long loops
local yield_counter = 0
function Core.yield()
    yield_counter = yield_counter + 1
    if yield_counter >= CONSTANTS.DEFAULTS.YIELD_INTERVAL then
        yield_counter = 0
        os.sleep(0)
        return true
    end
    return false
end

-- Get error message from error code
function Core.getErrorMessage(code)
    for name, value in pairs(CONSTANTS.ERRORS) do
        if value == code then
            return name:gsub("_", " "):lower()
        end
    end
    return "unknown error"
end

-- Create a formatted error response
function Core.makeError(code, details)
    return {
        success = false,
        error_code = code,
        error = Core.getErrorMessage(code),
        details = details or ""
    }
end

-- Create a success response
function Core.makeSuccess(data)
    return {
        success = true,
        data = data
    }
end

-- Circular buffer implementation for history tracking
function Core.createCircularBuffer(max_size)
    local buffer = {
        data = {},
        max_size = max_size or CONSTANTS.DEFAULTS.MAX_PATH_HISTORY,
        head = 1,
        size = 0
    }
    
    function buffer:add(item)
        self.data[self.head] = item
        self.head = (self.head % self.max_size) + 1
        self.size = math.min(self.size + 1, self.max_size)
    end
    
    function buffer:get(index)
        if index < 1 or index > self.size then
            return nil
        end
        local actual_index = ((self.head - self.size + index - 2) % self.max_size) + 1
        return self.data[actual_index]
    end
    
    function buffer:getLast()
        if self.size == 0 then return nil end
        local last_index = ((self.head - 2) % self.max_size) + 1
        return self.data[last_index]
    end
    
    function buffer:toArray()
        local result = {}
        for i = 1, self.size do
            result[i] = self:get(i)
        end
        return result
    end
    
    function buffer:clear()
        self.data = {}
        self.head = 1
        self.size = 0
    end
    
    return buffer
end

return Core