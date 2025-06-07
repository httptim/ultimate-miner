-- Memory Optimizer Module for Ultimate Miner
-- Analyzes and optimizes memory usage across all modules

local memory_optimizer = {}

-- Module information
memory_optimizer.name = "Memory Optimizer"
memory_optimizer.version = "1.0.0"
memory_optimizer.description = "Memory analysis and optimization utilities"

-- Dependencies
local Core = require("turtle.modules.core")

-- Constants
local MEMORY_THRESHOLDS = {
    CRITICAL = 0.9,  -- 90% memory usage
    WARNING = 0.75,  -- 75% memory usage
    SAFE = 0.5      -- 50% memory usage
}

local OPTIMIZATION_STRATEGIES = {
    CLEAR_CACHES = 1,
    REDUCE_HISTORY = 2,
    COMPACT_TABLES = 3,
    UNLOAD_MODULES = 4,
    GARBAGE_COLLECT = 5
}

-- Internal state
local optimizer_data = {
    memory_samples = {},
    max_samples = 100,
    optimization_history = {},
    module_memory = {},
    gc_frequency = 100,  -- Operations between garbage collections
    operation_count = 0
}

-- Get current memory usage
local function getMemoryUsage()
    -- CC:Tweaked doesn't have collectgarbage, so we estimate
    -- based on table sizes and approximate memory usage
    local usage = 0
    local max_memory = 2048 * 1024  -- Assume 2MB limit
    
    -- Estimate memory usage by counting objects
    local object_count = 0
    local string_bytes = 0
    
    -- Count global objects (rough estimate)
    for k, v in pairs(_G) do
        object_count = object_count + 1
        if type(k) == "string" then
            string_bytes = string_bytes + #k
        end
        if type(v) == "string" then
            string_bytes = string_bytes + #v
        end
    end
    
    -- Very rough estimate: each object ~100 bytes, strings as counted
    usage = (object_count * 100) + string_bytes
    
    return {
        used = usage,
        max = max_memory,
        percentage = (usage / max_memory) * 100,
        free = max_memory - usage
    }
end

-- Calculate table memory usage (approximate)
local function calculateTableMemory(tbl, visited)
    visited = visited or {}
    if visited[tbl] then return 0 end
    visited[tbl] = true
    
    local size = 0
    
    for k, v in pairs(tbl) do
        -- Key size
        if type(k) == "string" then
            size = size + #k + 24  -- String overhead
        else
            size = size + 8  -- Number/boolean
        end
        
        -- Value size
        if type(v) == "string" then
            size = size + #v + 24
        elseif type(v) == "table" then
            size = size + calculateTableMemory(v, visited)
        elseif type(v) == "function" then
            size = size + 128  -- Approximate function size
        else
            size = size + 8
        end
    end
    
    return size + 32  -- Table overhead
end

-- Analyze module memory usage
local function analyzeModuleMemory()
    local modules = {
        "Navigation", "Mining", "Inventory", "Safety", "Storage",
        "Network", "Optimization", "Targeting", "Area", "SmartMining",
        "Monitoring", "Integrity", "Alerts", "Cancellation", "Diagnostics"
    }
    
    local memory_map = {}
    
    for _, module_name in ipairs(modules) do
        local module_path = "turtle.modules." .. module_name:lower()
        if package.loaded[module_path] then
            local module = package.loaded[module_path]
            if type(module) == "table" then
                memory_map[module_name] = calculateTableMemory(module)
            end
        end
    end
    
    return memory_map
end

-- Initialize module
function memory_optimizer.init()
    Core.log("INFO", "Initializing Memory Optimizer")
    
    -- Take initial memory sample
    table.insert(optimizer_data.memory_samples, getMemoryUsage())
    
    -- Analyze initial module memory
    optimizer_data.module_memory = analyzeModuleMemory()
    
    Core.emit("memory_optimizer:initialized")
    return true, "Memory Optimizer initialized"
end

-- Record memory sample
function memory_optimizer.recordSample()
    local sample = getMemoryUsage()
    sample.timestamp = os.clock()
    
    -- Maintain circular buffer
    table.insert(optimizer_data.memory_samples, sample)
    if #optimizer_data.memory_samples > optimizer_data.max_samples then
        table.remove(optimizer_data.memory_samples, 1)
    end
    
    -- Check thresholds
    if sample.percentage >= MEMORY_THRESHOLDS.CRITICAL * 100 then
        Core.emit("memory:critical", sample)
        memory_optimizer.performOptimization(OPTIMIZATION_STRATEGIES.CLEAR_CACHES)
        memory_optimizer.performOptimization(OPTIMIZATION_STRATEGIES.REDUCE_HISTORY)
    elseif sample.percentage >= MEMORY_THRESHOLDS.WARNING * 100 then
        Core.emit("memory:warning", sample)
        memory_optimizer.performOptimization(OPTIMIZATION_STRATEGIES.GARBAGE_COLLECT)
    end
    
    return sample
end

-- Get memory statistics
function memory_optimizer.getStats()
    local current = getMemoryUsage()
    local samples = optimizer_data.memory_samples
    
    -- Calculate averages
    local avg_usage = 0
    local peak_usage = 0
    
    for _, sample in ipairs(samples) do
        avg_usage = avg_usage + sample.percentage
        if sample.percentage > peak_usage then
            peak_usage = sample.percentage
        end
    end
    
    if #samples > 0 then
        avg_usage = avg_usage / #samples
    end
    
    return {
        current = current,
        average_percentage = avg_usage,
        peak_percentage = peak_usage,
        samples_collected = #samples,
        module_memory = optimizer_data.module_memory,
        optimization_count = #optimizer_data.optimization_history
    }
end

-- Perform memory optimization
function memory_optimizer.performOptimization(strategy)
    Core.log("INFO", "Performing memory optimization: " .. strategy)
    
    local before = getMemoryUsage()
    local actions_taken = {}
    
    if strategy == OPTIMIZATION_STRATEGIES.CLEAR_CACHES then
        -- Clear navigation path cache
        if Navigation and Navigation.clearPathCache then
            Navigation.clearPathCache()
            table.insert(actions_taken, "Cleared navigation path cache")
        end
        
        -- Clear inventory cache
        if Inventory and Inventory.scanInventory then
            Inventory.scanInventory()  -- Force rescan clears old cache
            table.insert(actions_taken, "Cleared inventory cache")
        end
        
        -- Clear optimization data
        if Optimization and Optimization.clearData then
            Optimization.clearData()
            table.insert(actions_taken, "Cleared optimization data")
        end
        
    elseif strategy == OPTIMIZATION_STRATEGIES.REDUCE_HISTORY then
        -- Reduce navigation history
        if Navigation and Navigation.getPathHistory then
            local history = Navigation.getPathHistory()
            if #history > 250 then
                -- Keep only recent 250 moves
                while #history > 250 do
                    table.remove(history, 1)
                end
                table.insert(actions_taken, "Reduced navigation history")
            end
        end
        
        -- Reduce monitoring history
        if Monitoring and Monitoring.save then
            Monitoring.save()  -- Saves and clears old data
            table.insert(actions_taken, "Reduced monitoring history")
        end
        
        -- Clear old alerts
        if Alerts and Alerts.clear then
            Alerts.clear()
            table.insert(actions_taken, "Cleared alert queue")
        end
        
    elseif strategy == OPTIMIZATION_STRATEGIES.COMPACT_TABLES then
        -- Compact large tables by rebuilding them
        optimizer_data.memory_samples = compactTable(optimizer_data.memory_samples)
        table.insert(actions_taken, "Compacted memory samples")
        
    elseif strategy == OPTIMIZATION_STRATEGIES.UNLOAD_MODULES then
        -- Unload rarely used modules (carefully!)
        local rarely_used = {"diagnostics"}
        for _, module_name in ipairs(rarely_used) do
            local module_path = "turtle.modules." .. module_name
            if package.loaded[module_path] then
                package.loaded[module_path] = nil
                table.insert(actions_taken, "Unloaded " .. module_name)
            end
        end
        
    elseif strategy == OPTIMIZATION_STRATEGIES.GARBAGE_COLLECT then
        -- CC:Tweaked doesn't have collectgarbage
        -- Instead, we can clear some internal caches
        optimizer_data.memory_samples = compactTable(optimizer_data.memory_samples)
        table.insert(actions_taken, "Cleared internal caches")
    end
    
    local after = getMemoryUsage()
    local freed = before.used - after.used
    
    -- Record optimization
    table.insert(optimizer_data.optimization_history, {
        timestamp = os.clock(),
        strategy = strategy,
        freed_bytes = freed,
        freed_percentage = (freed / before.max) * 100,
        actions = actions_taken
    })
    
    Core.emit("memory:optimized", {
        strategy = strategy,
        freed = freed,
        actions = actions_taken
    })
    
    return true, freed, actions_taken
end

-- Compact table helper
function compactTable(tbl)
    local new_table = {}
    for i, v in ipairs(tbl) do
        new_table[i] = v
    end
    return new_table
end

-- Increment operation counter
function memory_optimizer.trackOperation()
    optimizer_data.operation_count = optimizer_data.operation_count + 1
    
    -- Periodic cache clearing (CC:Tweaked doesn't have collectgarbage)
    if optimizer_data.operation_count >= optimizer_data.gc_frequency then
        -- Clear old optimization history entries
        if #optimizer_data.optimization_history > 50 then
            local new_history = {}
            for i = #optimizer_data.optimization_history - 49, #optimizer_data.optimization_history do
                table.insert(new_history, optimizer_data.optimization_history[i])
            end
            optimizer_data.optimization_history = new_history
        end
        optimizer_data.operation_count = 0
    end
end

-- Get optimization recommendations
function memory_optimizer.getRecommendations()
    local stats = memory_optimizer.getStats()
    local recommendations = {}
    
    if stats.current.percentage > 80 then
        table.insert(recommendations, {
            priority = "HIGH",
            action = "Reduce active operations or return to base",
            reason = "Memory usage critical (" .. math.floor(stats.current.percentage) .. "%)"
        })
    elseif stats.current.percentage > 60 then
        table.insert(recommendations, {
            priority = "MEDIUM",
            action = "Clear caches and reduce history sizes",
            reason = "Memory usage elevated (" .. math.floor(stats.current.percentage) .. "%)"
        })
    end
    
    -- Check module memory
    local total_module_memory = 0
    for _, size in pairs(stats.module_memory) do
        total_module_memory = total_module_memory + size
    end
    
    if total_module_memory > 512 * 1024 then  -- 512KB
        table.insert(recommendations, {
            priority = "MEDIUM",
            action = "Consider unloading unused modules",
            reason = "Module memory usage high (" .. math.floor(total_module_memory / 1024) .. "KB)"
        })
    end
    
    -- History size recommendations
    if Navigation and Navigation.getPathHistoryStats then
        local history_stats = Navigation.getPathHistoryStats()
        if history_stats.count > 500 then
            table.insert(recommendations, {
                priority = "LOW",
                action = "Reduce path history size to 500 entries",
                reason = "Path history using excessive memory (" .. history_stats.count .. " entries)"
            })
        end
    end
    
    return recommendations
end

-- Monitor memory automatically
function memory_optimizer.startMonitoring(interval)
    interval = interval or 30  -- Default 30 seconds
    
    local function monitor()
        while true do
            memory_optimizer.recordSample()
            os.sleep(interval)
        end
    end
    
    -- Start monitoring in background
    Core.on("timer", function(timer_id)
        if timer_id == optimizer_data.monitor_timer then
            memory_optimizer.recordSample()
            optimizer_data.monitor_timer = os.startTimer(interval)
        end
    end)
    
    optimizer_data.monitor_timer = os.startTimer(interval)
end

-- Export memory report
function memory_optimizer.exportReport(filename)
    filename = filename or "/logs/memory_report.txt"
    
    local report = {
        "Ultimate Miner Memory Report",
        "Generated: " .. os.date(),
        string.rep("=", 40),
        "",
        "Current Memory Status:",
        ""
    }
    
    local stats = memory_optimizer.getStats()
    
    table.insert(report, string.format("Memory Usage: %.1f%% (%.1fKB / %.1fKB)",
        stats.current.percentage,
        stats.current.used / 1024,
        stats.current.max / 1024))
    table.insert(report, string.format("Average Usage: %.1f%%", stats.average_percentage))
    table.insert(report, string.format("Peak Usage: %.1f%%", stats.peak_percentage))
    table.insert(report, "")
    table.insert(report, "Module Memory Usage:")
    
    for module, size in pairs(stats.module_memory) do
        table.insert(report, string.format("  %s: %.1fKB", module, size / 1024))
    end
    
    table.insert(report, "")
    table.insert(report, "Optimization History:")
    
    for i, opt in ipairs(optimizer_data.optimization_history) do
        table.insert(report, string.format("  #%d: Strategy %d freed %.1fKB (%.1f%%)",
            i, opt.strategy, opt.freed_bytes / 1024, opt.freed_percentage))
    end
    
    table.insert(report, "")
    table.insert(report, "Recommendations:")
    
    local recommendations = memory_optimizer.getRecommendations()
    for _, rec in ipairs(recommendations) do
        table.insert(report, string.format("  [%s] %s", rec.priority, rec.action))
        table.insert(report, "    Reason: " .. rec.reason)
    end
    
    -- Write report
    local file = fs.open(filename, "w")
    if file then
        file.write(table.concat(report, "\n"))
        file.close()
        return true, filename
    end
    
    return false, "Failed to write report"
end

-- Shutdown
function memory_optimizer.shutdown()
    Core.log("INFO", "Shutting down Memory Optimizer")
    
    -- Stop monitoring
    if optimizer_data.monitor_timer then
        os.cancelTimer(optimizer_data.monitor_timer)
    end
    
    -- Final cleanup - clear internal data
    optimizer_data.memory_samples = {}
    optimizer_data.optimization_history = {}
    
    return true
end

return memory_optimizer