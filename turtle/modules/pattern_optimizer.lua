-- Pattern Optimizer Module for Ultimate Miner
-- Optimizes mining patterns for efficiency and reduced movements

local pattern_optimizer = {}

-- Module information
pattern_optimizer.name = "Pattern Optimizer"
pattern_optimizer.version = "1.0.0"
pattern_optimizer.description = "Mining pattern optimization for improved efficiency"

-- Dependencies
local Core = require("turtle.modules.core")
local PerformanceConfig = require("turtle.modules.performance_config")

-- Optimization strategies
local STRATEGIES = {
    SKIP_SCAN = "skip_scan",        -- Skip already scanned areas
    SMART_TURNS = "smart_turns",    -- Minimize turning operations
    ORE_CLUSTERING = "ore_clustering", -- Group nearby ores
    DEPTH_FIRST = "depth_first",    -- Prioritize deeper mining
    FUEL_AWARE = "fuel_aware"       -- Optimize based on fuel
}

-- Pattern efficiency metrics
local pattern_metrics = {
    strip = {
        blocks_per_move = 3,
        turns_per_100_blocks = 4,
        coverage_efficiency = 0.85,
        fuel_efficiency = 0.9
    },
    branch = {
        blocks_per_move = 2.5,
        turns_per_100_blocks = 8,
        coverage_efficiency = 0.75,
        fuel_efficiency = 0.85
    },
    spiral = {
        blocks_per_move = 2,
        turns_per_100_blocks = 25,
        coverage_efficiency = 0.95,
        fuel_efficiency = 0.7
    },
    quarry = {
        blocks_per_move = 1,
        turns_per_100_blocks = 12,
        coverage_efficiency = 1.0,
        fuel_efficiency = 0.8
    }
}

-- Internal state
local optimizer_data = {
    scanned_blocks = {},  -- Hash table of scanned positions
    ore_clusters = {},    -- Detected ore clusters
    pattern_stats = {},   -- Runtime statistics
    movement_cache = {}   -- Cached movement sequences
}

-- Initialize module
function pattern_optimizer.init()
    Core.log("INFO", "Initializing Pattern Optimizer")
    
    -- Clear any old data
    optimizer_data.scanned_blocks = {}
    optimizer_data.ore_clusters = {}
    
    Core.emit("pattern_optimizer:initialized")
    return true, "Pattern Optimizer initialized"
end

-- Hash position for efficient lookup
local function hashPosition(pos)
    return string.format("%d,%d,%d", pos.x, pos.y, pos.z)
end

-- Check if position was already scanned
local function wasScanned(pos)
    return optimizer_data.scanned_blocks[hashPosition(pos)] ~= nil
end

-- Mark position as scanned
local function markScanned(pos, block_data)
    optimizer_data.scanned_blocks[hashPosition(pos)] = {
        timestamp = os.clock(),
        data = block_data
    }
end

-- Optimize strip mining pattern
function pattern_optimizer.optimizeStripPattern(options)
    local optimized = {
        length = options.length or 50,
        spacing = options.spacing or 3,
        strips = options.strips or 5,
        skip_scanned = true,
        smart_turns = true
    }
    
    -- Adjust spacing based on ore density
    if optimizer_data.pattern_stats.ore_density then
        if optimizer_data.pattern_stats.ore_density > 0.1 then
            optimized.spacing = 2  -- Closer strips for high density
        elseif optimizer_data.pattern_stats.ore_density < 0.02 then
            optimized.spacing = 4  -- Wider strips for low density
        end
    end
    
    -- Calculate optimal strip length based on fuel
    if turtle and turtle.getFuelLevel then
        local fuel = turtle.getFuelLevel()
        local fuel_per_strip = optimized.length * 2 + 10  -- Round trip + mining
        local max_strips = math.floor(fuel / fuel_per_strip)
        
        if max_strips < optimized.strips then
            -- Reduce strip length to fit fuel
            optimized.length = math.floor((fuel / optimized.strips - 10) / 2)
        end
    end
    
    return optimized
end

-- Get next efficient mining position
function pattern_optimizer.getNextPosition(current_pos, pattern_type, ore_positions)
    -- If ore positions provided, cluster them
    if ore_positions and #ore_positions > 0 then
        local clusters = pattern_optimizer.clusterOres(ore_positions)
        
        -- Find nearest cluster
        local nearest_cluster = nil
        local min_distance = math.huge
        
        for _, cluster in ipairs(clusters) do
            local dist = Core.vector.distance(current_pos, cluster.center)
            if dist < min_distance then
                min_distance = dist
                nearest_cluster = cluster
            end
        end
        
        if nearest_cluster then
            -- Return position towards cluster center
            return nearest_cluster.center
        end
    end
    
    -- Default pattern-based position
    return pattern_optimizer.getPatternPosition(current_pos, pattern_type)
end

-- Cluster nearby ores for efficient mining
function pattern_optimizer.clusterOres(ore_positions)
    local clusters = {}
    local max_cluster_radius = 5
    
    -- Simple clustering algorithm
    for _, pos in ipairs(ore_positions) do
        local added_to_cluster = false
        
        -- Check existing clusters
        for _, cluster in ipairs(clusters) do
            local dist = Core.vector.distance(pos, cluster.center)
            if dist <= max_cluster_radius then
                -- Add to cluster and update center
                table.insert(cluster.ores, pos)
                
                -- Recalculate center
                local sum_x, sum_y, sum_z = 0, 0, 0
                for _, ore_pos in ipairs(cluster.ores) do
                    sum_x = sum_x + ore_pos.x
                    sum_y = sum_y + ore_pos.y
                    sum_z = sum_z + ore_pos.z
                end
                
                cluster.center = {
                    x = math.floor(sum_x / #cluster.ores),
                    y = math.floor(sum_y / #cluster.ores),
                    z = math.floor(sum_z / #cluster.ores)
                }
                
                added_to_cluster = true
                break
            end
        end
        
        -- Create new cluster if not added
        if not added_to_cluster then
            table.insert(clusters, {
                center = pos,
                ores = {pos},
                value = 1  -- Can be weighted by ore type
            })
        end
    end
    
    -- Sort clusters by value/size
    table.sort(clusters, function(a, b)
        return #a.ores > #b.ores
    end)
    
    return clusters
end

-- Calculate movement efficiency
function pattern_optimizer.calculateEfficiency(movements, blocks_mined)
    if #movements == 0 or blocks_mined == 0 then
        return 0
    end
    
    local total_moves = #movements
    local turns = 0
    local backtracks = 0
    
    -- Count turns and backtracks
    for i = 2, #movements do
        local prev = movements[i-1]
        local curr = movements[i]
        
        -- Check for turn
        if prev.facing ~= curr.facing then
            turns = turns + 1
        end
        
        -- Check for backtrack (returning to previous position)
        if i > 2 then
            local prev_prev = movements[i-2]
            if curr.x == prev_prev.x and curr.y == prev_prev.y and curr.z == prev_prev.z then
                backtracks = backtracks + 1
            end
        end
    end
    
    -- Calculate efficiency score (0-1)
    local move_efficiency = blocks_mined / total_moves
    local turn_penalty = turns / total_moves * 0.1
    local backtrack_penalty = backtracks / total_moves * 0.2
    
    local efficiency = move_efficiency - turn_penalty - backtrack_penalty
    return math.max(0, math.min(1, efficiency))
end

-- Optimize movement sequence
function pattern_optimizer.optimizeMovements(movements)
    if #movements < 3 then
        return movements
    end
    
    local optimized = {movements[1]}
    
    for i = 2, #movements - 1 do
        local prev = movements[i-1]
        local curr = movements[i]
        local next = movements[i+1]
        
        -- Skip redundant movements (going forward then immediately back)
        if not (curr.x == prev.x and curr.y == prev.y and curr.z == prev.z and
                next.x == prev.x and next.y == prev.y and next.z == prev.z) then
            
            -- Check if we can skip this position if already scanned
            if not wasScanned(curr) then
                table.insert(optimized, curr)
            end
        end
    end
    
    -- Always include last movement
    table.insert(optimized, movements[#movements])
    
    return optimized
end

-- Get pattern-specific optimizations
function pattern_optimizer.getPatternOptimizations(pattern_type)
    local optimizations = {
        general = {
            skip_scanned = PerformanceConfig.isFeatureEnabled("skip_scanned_blocks"),
            smart_turns = true,
            fuel_aware = true
        }
    }
    
    if pattern_type == "strip" then
        optimizations.strip_specific = {
            parallel_strips = true,
            adaptive_spacing = true,
            end_turn_optimization = true
        }
    elseif pattern_type == "branch" then
        optimizations.branch_specific = {
            main_tunnel_cache = true,
            branch_skip = true,
            symmetric_branches = true
        }
    elseif pattern_type == "spiral" then
        optimizations.spiral_specific = {
            expanding_radius = true,
            corner_optimization = true,
            spiral_cache = true
        }
    elseif pattern_type == "quarry" then
        optimizations.quarry_specific = {
            layer_optimization = true,
            perimeter_first = false,
            snake_pattern = true
        }
    end
    
    return optimizations
end

-- Cache movement pattern
function pattern_optimizer.cachePattern(pattern_id, movements)
    optimizer_data.movement_cache[pattern_id] = {
        movements = movements,
        timestamp = os.clock(),
        uses = 0
    }
end

-- Get cached pattern
function pattern_optimizer.getCachedPattern(pattern_id)
    local cached = optimizer_data.movement_cache[pattern_id]
    
    if cached then
        cached.uses = cached.uses + 1
        return cached.movements
    end
    
    return nil
end

-- Update pattern statistics
function pattern_optimizer.updateStats(pattern_type, stats)
    if not optimizer_data.pattern_stats[pattern_type] then
        optimizer_data.pattern_stats[pattern_type] = {
            total_blocks = 0,
            total_moves = 0,
            total_turns = 0,
            ores_found = 0,
            fuel_used = 0,
            time_spent = 0,
            efficiency_samples = {}
        }
    end
    
    local pattern_stat = optimizer_data.pattern_stats[pattern_type]
    
    -- Update cumulative stats
    pattern_stat.total_blocks = pattern_stat.total_blocks + (stats.blocks_mined or 0)
    pattern_stat.total_moves = pattern_stat.total_moves + (stats.moves or 0)
    pattern_stat.total_turns = pattern_stat.total_turns + (stats.turns or 0)
    pattern_stat.ores_found = pattern_stat.ores_found + (stats.ores or 0)
    pattern_stat.fuel_used = pattern_stat.fuel_used + (stats.fuel or 0)
    pattern_stat.time_spent = pattern_stat.time_spent + (stats.time or 0)
    
    -- Calculate efficiency
    if stats.blocks_mined and stats.moves then
        local efficiency = pattern_optimizer.calculateEfficiency(
            stats.movements or {},
            stats.blocks_mined
        )
        table.insert(pattern_stat.efficiency_samples, efficiency)
        
        -- Keep only recent samples
        if #pattern_stat.efficiency_samples > 100 then
            table.remove(pattern_stat.efficiency_samples, 1)
        end
    end
    
    -- Update ore density
    if pattern_stat.total_blocks > 0 then
        pattern_stat.ore_density = pattern_stat.ores_found / pattern_stat.total_blocks
    end
end

-- Get optimization recommendations
function pattern_optimizer.getRecommendations(current_stats)
    local recommendations = {}
    
    -- Analyze pattern efficiency
    for pattern, stats in pairs(optimizer_data.pattern_stats) do
        if stats.efficiency_samples and #stats.efficiency_samples > 10 then
            local avg_efficiency = 0
            for _, eff in ipairs(stats.efficiency_samples) do
                avg_efficiency = avg_efficiency + eff
            end
            avg_efficiency = avg_efficiency / #stats.efficiency_samples
            
            if avg_efficiency < 0.5 then
                table.insert(recommendations, {
                    pattern = pattern,
                    issue = "low_efficiency",
                    suggestion = "Consider switching patterns or optimizing movements",
                    efficiency = avg_efficiency
                })
            end
        end
        
        -- Check ore density
        if stats.ore_density and stats.ore_density < 0.01 then
            table.insert(recommendations, {
                pattern = pattern,
                issue = "low_ore_density",
                suggestion = "Move to different Y-level or area",
                density = stats.ore_density
            })
        end
    end
    
    -- Memory optimization
    local scanned_count = 0
    for _ in pairs(optimizer_data.scanned_blocks) do
        scanned_count = scanned_count + 1
    end
    
    if scanned_count > 10000 then
        table.insert(recommendations, {
            issue = "memory_usage",
            suggestion = "Clear old scanned block data",
            count = scanned_count
        })
    end
    
    return recommendations
end

-- Clear old data
function pattern_optimizer.clearOldData(max_age)
    max_age = max_age or 3600  -- 1 hour default
    local current_time = os.clock()
    local cleared = 0
    
    -- Clear old scanned blocks
    for pos_hash, data in pairs(optimizer_data.scanned_blocks) do
        if (current_time - data.timestamp) > max_age then
            optimizer_data.scanned_blocks[pos_hash] = nil
            cleared = cleared + 1
        end
    end
    
    -- Clear old movement cache
    for pattern_id, cache in pairs(optimizer_data.movement_cache) do
        if (current_time - cache.timestamp) > max_age and cache.uses < 5 then
            optimizer_data.movement_cache[pattern_id] = nil
        end
    end
    
    return cleared
end

-- Get statistics
function pattern_optimizer.getStats()
    local stats = {
        scanned_blocks = 0,
        cached_patterns = 0,
        pattern_stats = {},
        memory_usage = 0
    }
    
    -- Count scanned blocks
    for _ in pairs(optimizer_data.scanned_blocks) do
        stats.scanned_blocks = stats.scanned_blocks + 1
    end
    
    -- Count cached patterns
    for _ in pairs(optimizer_data.movement_cache) do
        stats.cached_patterns = stats.cached_patterns + 1
    end
    
    -- Copy pattern stats
    for pattern, data in pairs(optimizer_data.pattern_stats) do
        stats.pattern_stats[pattern] = {
            efficiency = 0,
            ore_density = data.ore_density or 0,
            blocks_per_move = data.total_moves > 0 and 
                data.total_blocks / data.total_moves or 0
        }
        
        -- Calculate average efficiency
        if data.efficiency_samples and #data.efficiency_samples > 0 then
            local sum = 0
            for _, eff in ipairs(data.efficiency_samples) do
                sum = sum + eff
            end
            stats.pattern_stats[pattern].efficiency = sum / #data.efficiency_samples
        end
    end
    
    -- Estimate memory usage
    stats.memory_usage = stats.scanned_blocks * 32 + stats.cached_patterns * 256
    
    return stats
end

-- Shutdown
function pattern_optimizer.shutdown()
    Core.log("INFO", "Shutting down Pattern Optimizer")
    
    -- Clear large data structures
    optimizer_data.scanned_blocks = {}
    optimizer_data.movement_cache = {}
    
    return true
end

return pattern_optimizer