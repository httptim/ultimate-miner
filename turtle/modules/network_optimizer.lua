-- Network Optimizer Module for Ultimate Miner
-- Reduces network traffic through batching, compression, and smart protocols

local network_optimizer = {}

-- Module information
network_optimizer.name = "Network Optimizer"
network_optimizer.version = "1.0.0"
network_optimizer.description = "Network traffic optimization and reduction"

-- Dependencies
local Core = require("turtle.modules.core")
local PerformanceConfig = require("turtle.modules.performance_config")

-- Constants
local MESSAGE_TYPES = {
    BATCH = "batch",
    COMPRESSED = "compressed",
    DELTA = "delta",
    HEARTBEAT = "heartbeat_lite"
}

local COMPRESSION_THRESHOLD = 100  -- Bytes
local BATCH_TIMEOUT = 2  -- Seconds
local MAX_BATCH_SIZE = 10  -- Messages

-- Internal state
local optimizer_data = {
    message_queue = {},
    batch_timer = nil,
    last_status = {},
    stats = {
        messages_sent = 0,
        messages_batched = 0,
        bytes_saved = 0,
        compression_ratio = 0
    },
    heartbeat_data = {
        last_full = 0,
        delta_count = 0
    }
}

-- Initialize module
function network_optimizer.init()
    Core.log("INFO", "Initializing Network Optimizer")
    
    -- Load performance settings
    optimizer_data.batch_timeout = PerformanceConfig.get("performance.status_batch_interval", BATCH_TIMEOUT)
    optimizer_data.max_batch = PerformanceConfig.get("performance.batch_size", MAX_BATCH_SIZE)
    
    Core.emit("network_optimizer:initialized")
    return true, "Network Optimizer initialized"
end

-- Simple string compression using run-length encoding for repeated patterns
local function compressString(str)
    if #str < COMPRESSION_THRESHOLD then
        return str, false
    end
    
    -- Simple pattern replacement for common Minecraft terms
    local compressed = str
    local replacements = {
        ["minecraft:"] = "mc:",
        ["deepslate_"] = "ds_",
        ["_ore"] = "_o",
        ["position"] = "pos",
        ["inventory"] = "inv",
        ["status"] = "st",
        ["heartbeat"] = "hb",
        ["mining"] = "mn",
        ["navigation"] = "nav"
    }
    
    for pattern, replacement in pairs(replacements) do
        compressed = compressed:gsub(pattern, replacement)
    end
    
    -- Check if compression was effective
    local saved = #str - #compressed
    if saved > 10 then
        return compressed, true
    end
    
    return str, false
end

-- Decompress string
local function decompressString(str, was_compressed)
    if not was_compressed then
        return str
    end
    
    local decompressed = str
    local replacements = {
        ["mc:"] = "minecraft:",
        ["ds_"] = "deepslate_",
        ["_o"] = "_ore",
        ["pos"] = "position",
        ["inv"] = "inventory", 
        ["st"] = "status",
        ["hb"] = "heartbeat",
        ["mn"] = "mining",
        ["nav"] = "navigation"
    }
    
    for pattern, replacement in pairs(replacements) do
        decompressed = decompressed:gsub(pattern, replacement)
    end
    
    return decompressed
end

-- Calculate delta between two tables
local function calculateDelta(old, new)
    local delta = {}
    local has_changes = false
    
    for k, v in pairs(new) do
        if type(v) ~= type(old[k]) or v ~= old[k] then
            delta[k] = v
            has_changes = true
        elseif type(v) == "table" then
            local sub_delta = calculateDelta(old[k] or {}, v)
            if next(sub_delta) then
                delta[k] = sub_delta
                has_changes = true
            end
        end
    end
    
    -- Check for removed keys
    for k in pairs(old) do
        if new[k] == nil then
            delta[k] = false  -- Marker for deletion
            has_changes = true
        end
    end
    
    return has_changes and delta or nil
end

-- Apply delta to base data
local function applyDelta(base, delta)
    local result = Core.deepCopy(base)
    
    for k, v in pairs(delta) do
        if v == false then
            result[k] = nil
        elseif type(v) == "table" and type(result[k]) == "table" then
            result[k] = applyDelta(result[k], v)
        else
            result[k] = v
        end
    end
    
    return result
end

-- Queue message for batching
function network_optimizer.queueMessage(recipient, message)
    -- Check if batching is enabled
    if not PerformanceConfig.get("performance.status_batch_interval") then
        return false  -- Send immediately
    end
    
    -- Add to queue
    table.insert(optimizer_data.message_queue, {
        recipient = recipient,
        message = message,
        timestamp = os.clock()
    })
    
    -- Start batch timer if not running
    if not optimizer_data.batch_timer then
        optimizer_data.batch_timer = os.startTimer(optimizer_data.batch_timeout)
    end
    
    -- Check if batch is full
    if #optimizer_data.message_queue >= optimizer_data.max_batch then
        network_optimizer.sendBatch()
    end
    
    return true  -- Message queued
end

-- Send batched messages
function network_optimizer.sendBatch()
    if #optimizer_data.message_queue == 0 then
        return
    end
    
    -- Cancel timer
    if optimizer_data.batch_timer then
        os.cancelTimer(optimizer_data.batch_timer)
        optimizer_data.batch_timer = nil
    end
    
    -- Group messages by recipient
    local batches = {}
    for _, queued in ipairs(optimizer_data.message_queue) do
        local recipient = queued.recipient or "broadcast"
        if not batches[recipient] then
            batches[recipient] = {}
        end
        table.insert(batches[recipient], queued.message)
    end
    
    -- Send batches
    for recipient, messages in pairs(batches) do
        local batch_message = {
            type = MESSAGE_TYPES.BATCH,
            messages = messages,
            count = #messages
        }
        
        -- Try to compress
        local serialized = textutils.serialize(batch_message)
        local compressed, was_compressed = compressString(serialized)
        
        if was_compressed then
            batch_message = {
                type = MESSAGE_TYPES.COMPRESSED,
                data = compressed,
                original_size = #serialized
            }
            optimizer_data.stats.bytes_saved = optimizer_data.stats.bytes_saved + (#serialized - #compressed)
        end
        
        -- Send via network module
        Core.emit("network:send", {
            recipient = recipient == "broadcast" and nil or tonumber(recipient),
            message = batch_message
        })
        
        optimizer_data.stats.messages_batched = optimizer_data.stats.messages_batched + #messages
    end
    
    optimizer_data.stats.messages_sent = optimizer_data.stats.messages_sent + 1
    
    -- Clear queue
    optimizer_data.message_queue = {}
end

-- Optimize heartbeat messages
function network_optimizer.optimizeHeartbeat(status_data)
    local current_time = os.clock()
    
    -- Send full heartbeat every 10th message or every 60 seconds
    if optimizer_data.heartbeat_data.delta_count >= 10 or 
       (current_time - optimizer_data.heartbeat_data.last_full) > 60 then
        
        optimizer_data.last_status = Core.deepCopy(status_data)
        optimizer_data.heartbeat_data.last_full = current_time
        optimizer_data.heartbeat_data.delta_count = 0
        
        return {
            type = MESSAGE_TYPES.HEARTBEAT,
            full = true,
            data = status_data
        }
    end
    
    -- Calculate delta
    local delta = calculateDelta(optimizer_data.last_status, status_data)
    
    if not delta then
        -- No changes, send minimal heartbeat
        return {
            type = MESSAGE_TYPES.HEARTBEAT,
            minimal = true,
            id = os.getComputerID()
        }
    end
    
    -- Send delta update
    optimizer_data.heartbeat_data.delta_count = optimizer_data.heartbeat_data.delta_count + 1
    optimizer_data.last_status = Core.deepCopy(status_data)
    
    return {
        type = MESSAGE_TYPES.DELTA,
        delta = delta,
        base_time = optimizer_data.heartbeat_data.last_full
    }
end

-- Process received optimized message
function network_optimizer.processMessage(message)
    if not message.type then
        return message  -- Not optimized
    end
    
    if message.type == MESSAGE_TYPES.BATCH then
        -- Extract batched messages
        local messages = {}
        for _, msg in ipairs(message.messages or {}) do
            table.insert(messages, msg)
        end
        return messages
        
    elseif message.type == MESSAGE_TYPES.COMPRESSED then
        -- Decompress
        local decompressed = decompressString(message.data, true)
        local decoded = textutils.unserialize(decompressed)
        return network_optimizer.processMessage(decoded)
        
    elseif message.type == MESSAGE_TYPES.DELTA then
        -- Apply delta to last known state
        if optimizer_data.last_status then
            return applyDelta(optimizer_data.last_status, message.delta)
        end
        return nil  -- Need full update
        
    elseif message.type == MESSAGE_TYPES.HEARTBEAT then
        if message.full then
            return message.data
        elseif message.minimal then
            return {id = message.id, alive = true}
        end
    end
    
    return message
end

-- Get optimization statistics
function network_optimizer.getStats()
    local total_messages = optimizer_data.stats.messages_sent + optimizer_data.stats.messages_batched
    
    return {
        messages_sent = optimizer_data.stats.messages_sent,
        messages_batched = optimizer_data.stats.messages_batched,
        batch_ratio = total_messages > 0 and 
            (optimizer_data.stats.messages_batched / total_messages * 100) or 0,
        bytes_saved = optimizer_data.stats.bytes_saved,
        compression_ratio = optimizer_data.stats.compression_ratio,
        queue_size = #optimizer_data.message_queue,
        heartbeat_optimized = optimizer_data.heartbeat_data.delta_count > 0
    }
end

-- Handle timer events
function network_optimizer.handleTimer(timer_id)
    if timer_id == optimizer_data.batch_timer then
        network_optimizer.sendBatch()
    end
end

-- Force flush all queued messages
function network_optimizer.flush()
    if #optimizer_data.message_queue > 0 then
        network_optimizer.sendBatch()
    end
end

-- Configure optimization settings
function network_optimizer.configure(settings)
    if settings.batch_timeout then
        optimizer_data.batch_timeout = settings.batch_timeout
    end
    if settings.max_batch_size then
        optimizer_data.max_batch = settings.max_batch_size
    end
    if settings.compression_threshold then
        COMPRESSION_THRESHOLD = settings.compression_threshold
    end
end

-- Reset statistics
function network_optimizer.resetStats()
    optimizer_data.stats = {
        messages_sent = 0,
        messages_batched = 0,
        bytes_saved = 0,
        compression_ratio = 0
    }
end

-- Shutdown
function network_optimizer.shutdown()
    Core.log("INFO", "Shutting down Network Optimizer")
    
    -- Send any remaining messages
    network_optimizer.flush()
    
    -- Cancel timers
    if optimizer_data.batch_timer then
        os.cancelTimer(optimizer_data.batch_timer)
    end
    
    return true
end

return network_optimizer