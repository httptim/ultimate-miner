-- Performance Configuration Module for Ultimate Miner
-- Central configuration for memory and performance optimization

local performance_config = {}

-- Module information
performance_config.name = "Performance Config"
performance_config.version = "1.0.0"
performance_config.description = "Centralized performance and memory optimization settings"

-- Optimization settings
performance_config.settings = {
    -- Memory management
    memory = {
        -- Path history limits
        path_history_size = 500,  -- Reduced from 1000
        path_cache_size = 20,     -- Cache for frequently used paths
        
        -- Operation history
        operation_history_size = 100,  -- Recent operations to track
        
        -- Inventory cache
        inventory_cache_ttl = 60,  -- Seconds before cache refresh
        
        -- Alert queue
        alert_queue_size = 50,     -- Maximum alerts to queue
        alert_history_size = 100,  -- Alert history to maintain
        
        -- Monitoring samples
        monitoring_samples = 100,  -- Performance samples to keep
        resource_hotspots = 10,    -- Hotspot locations to track
        
        -- Network buffers
        message_queue_size = 30,   -- Pending messages
        heartbeat_history = 10,    -- Recent heartbeats to track
    },
    
    -- Performance settings
    performance = {
        -- Operation yields
        yield_frequency = 50,      -- Operations before yielding
        
        -- Batch processing
        batch_size = 16,          -- Items to process per batch
        
        -- Update intervals (seconds)
        metric_update_interval = 5,
        health_check_interval = 30,
        gc_interval = 60,         -- Garbage collection
        
        -- Pathfinding limits
        pathfinding_max_iterations = 5000,  -- Reduced from 10000
        pathfinding_cache_enabled = true,
        
        -- Mining optimizations
        vein_search_limit = 64,   -- Maximum blocks in vein
        ore_scan_radius = 16,     -- Radius for ore detection
        
        -- Network optimizations
        heartbeat_interval = 10,  -- Increased from 5
        status_batch_interval = 15,  -- Batch status updates
        
        -- Diagnostics
        diagnostic_lightweight = true,  -- Run lighter diagnostics
    },
    
    -- Lazy loading configuration
    lazy_loading = {
        -- Modules to load on demand
        on_demand_modules = {
            "diagnostics",
            "smart_mining",
            "area"
        },
        
        -- Features to enable/disable
        features = {
            advanced_pathfinding = true,
            vein_clustering = true,
            hotspot_tracking = true,
            detailed_metrics = false,  -- Disable for memory savings
            debug_logging = false,
        }
    },
    
    -- Memory thresholds for adaptive behavior
    thresholds = {
        -- Memory usage percentages
        critical = 90,  -- Emergency optimizations
        high = 75,      -- Start reducing features
        medium = 60,    -- Normal optimizations
        low = 40,       -- All features enabled
        
        -- Operation counts before cleanup
        operations_before_gc = 100,
        blocks_before_compact = 1000,
    }
}

-- Get setting with fallback
function performance_config.get(path, default)
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    
    local current = performance_config.settings
    for _, part in ipairs(parts) do
        if type(current) == "table" and current[part] ~= nil then
            current = current[part]
        else
            return default
        end
    end
    
    return current
end

-- Update setting
function performance_config.set(path, value)
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    
    local current = performance_config.settings
    for i = 1, #parts - 1 do
        local part = parts[i]
        if type(current[part]) ~= "table" then
            current[part] = {}
        end
        current = current[part]
    end
    
    current[parts[#parts]] = value
end

-- Apply memory-saving profile
function performance_config.applyLowMemoryProfile()
    -- Reduce all limits
    performance_config.set("memory.path_history_size", 250)
    performance_config.set("memory.path_cache_size", 10)
    performance_config.set("memory.operation_history_size", 50)
    performance_config.set("memory.alert_queue_size", 25)
    performance_config.set("memory.monitoring_samples", 50)
    
    -- Disable non-essential features
    performance_config.set("lazy_loading.features.detailed_metrics", false)
    performance_config.set("lazy_loading.features.hotspot_tracking", false)
    performance_config.set("lazy_loading.features.vein_clustering", false)
    
    -- Increase GC frequency
    performance_config.set("performance.gc_interval", 30)
    performance_config.set("thresholds.operations_before_gc", 50)
end

-- Apply performance profile
function performance_config.applyHighPerformanceProfile()
    -- Increase limits for better performance
    performance_config.set("memory.path_history_size", 1000)
    performance_config.set("memory.path_cache_size", 50)
    performance_config.set("performance.batch_size", 32)
    
    -- Enable all features
    performance_config.set("lazy_loading.features.detailed_metrics", true)
    performance_config.set("lazy_loading.features.hotspot_tracking", true)
    performance_config.set("lazy_loading.features.advanced_pathfinding", true)
    
    -- Reduce update frequencies
    performance_config.set("performance.metric_update_interval", 10)
    performance_config.set("performance.health_check_interval", 60)
end

-- Get recommended settings based on memory usage
function performance_config.getAdaptiveSettings(memory_percentage)
    if memory_percentage >= performance_config.settings.thresholds.critical then
        return "critical", {
            action = "applyLowMemoryProfile",
            reduce = {"path_history", "caches", "features"},
            disable = {"detailed_metrics", "hotspot_tracking"}
        }
    elseif memory_percentage >= performance_config.settings.thresholds.high then
        return "high", {
            action = "reduceNonEssential", 
            reduce = {"history_sizes", "cache_sizes"},
            maintain = {"core_features"}
        }
    elseif memory_percentage >= performance_config.settings.thresholds.medium then
        return "medium", {
            action = "normalOperation",
            optimize = {"gc_frequency", "batch_sizes"}
        }
    else
        return "low", {
            action = "fullFeatures",
            enable = {"all_features", "detailed_tracking"}
        }
    end
end

-- Export current configuration
function performance_config.export()
    return performance_config.settings
end

-- Import configuration
function performance_config.import(config)
    if type(config) == "table" then
        performance_config.settings = config
        return true
    end
    return false
end

-- Check if feature is enabled
function performance_config.isFeatureEnabled(feature)
    return performance_config.get("lazy_loading.features." .. feature, false)
end

-- Check if module should be lazy loaded
function performance_config.shouldLazyLoad(module_name)
    local on_demand = performance_config.get("lazy_loading.on_demand_modules", {})
    for _, module in ipairs(on_demand) do
        if module == module_name then
            return true
        end
    end
    return false
end

return performance_config