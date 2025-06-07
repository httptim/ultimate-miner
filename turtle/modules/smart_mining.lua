-- Ultimate Miner - Smart Mining Module
-- Intelligent mining strategies with adaptive optimization and scarcity handling

local SmartMining = {}

-- Dependencies
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local Mining = require("turtle.modules.mining")
local Optimization = require("turtle.modules.optimization")
local Targeting = require("turtle.modules.targeting")
local Area = require("turtle.modules.area")

-- Constants
local SCARCITY_THRESHOLD = 0.01 -- Less than 1% ore rate = scarce
local EFFICIENCY_WINDOW = 1000 -- Blocks to analyze for efficiency
local ADAPTATION_INTERVAL = 500 -- Blocks between pattern adaptations
local MAX_DEPTH_STRATEGIES = 5 -- Number of depth strategies to try

-- Module state
local initialized = false
local mining_stats = {
    total_blocks = 0,
    ore_blocks = 0,
    by_ore_type = {},
    by_y_level = {},
    pattern_efficiency = {},
    depth_strategies = {},
    last_adaptation = 0
}
local current_strategy = nil
local scarcity_mode = false

-- Initialize module
function SmartMining.init()
    if initialized then
        return true, "Already initialized"
    end
    
    Core.log("INFO", "Initializing Smart Mining module")
    
    -- Load saved stats
    local saved_stats = State.get("smart_mining_stats", {})
    if saved_stats and type(saved_stats) == "table" then
        mining_stats = saved_stats
    end
    
    -- Initialize modules we depend on
    Targeting.init()
    Area.init()
    
    initialized = true
    Core.emit("smart_mining:initialized")
    return true
end

-- Analyze Y-level distribution and optimize
function SmartMining.optimizeYLevel(target_ores)
    if not initialized then
        return false, "Module not initialized"
    end
    
    target_ores = target_ores or {"diamond", "iron", "gold"}
    
    -- Get current position
    local pos = Navigation.getPosition()
    if not pos then
        return false, "Cannot determine position"
    end
    
    -- Analyze ore distribution from stats
    local y_scores = {}
    for y = -64, 320 do
        y_scores[y] = 0
        
        -- Calculate score based on target ores
        for _, ore in ipairs(target_ores) do
            local ore_data = Optimization.getOptimalYLevel(ore)
            if ore_data then
                -- Score based on distance from optimal Y
                local distance = math.abs(y - ore_data.optimal_y)
                local in_range = y >= ore_data.y_range[1] and y <= ore_data.y_range[2]
                
                if in_range then
                    -- Higher score for being closer to optimal
                    local score = 100 - (distance * 2)
                    -- Weight by ore value
                    score = score * (ore_data.value or 1)
                    y_scores[y] = y_scores[y] + score
                end
            end
        end
        
        -- Bonus for actual findings at this Y level
        local y_stats = mining_stats.by_y_level[tostring(y)]
        if y_stats and y_stats.total > 0 then
            local ore_rate = y_stats.ores / y_stats.total
            y_scores[y] = y_scores[y] + (ore_rate * 1000)
        end
    end
    
    -- Find best Y level
    local best_y = pos.y
    local best_score = -1
    for y, score in pairs(y_scores) do
        if score > best_score then
            best_score = score
            best_y = y
        end
    end
    
    Core.log("INFO", string.format("Optimal Y level for targets: %d (score: %.2f)", best_y, best_score))
    
    -- Move to optimal Y if significantly different
    if math.abs(pos.y - best_y) > 3 then
        Core.log("INFO", "Moving to optimal Y level: " .. best_y)
        local target = {x = pos.x, y = best_y, z = pos.z}
        Navigation.moveTo(target, {use_pathfinding = true})
    end
    
    return true, best_y
end

-- Handle resource scarcity
function SmartMining.handleScarcity(ore_type)
    if not initialized then
        return false, "Module not initialized"
    end
    
    Core.log("WARNING", "Resource scarcity detected for: " .. (ore_type or "general"))
    scarcity_mode = true
    
    -- Calculate current ore rate
    local ore_rate = mining_stats.ore_blocks / math.max(1, mining_stats.total_blocks)
    
    -- Strategies for scarcity
    local strategies = {
        -- 1. Expand search radius
        expand_radius = function()
            Core.log("INFO", "Expanding search radius")
            Config.set("mining.search_radius", (Config.get("mining.search_radius", 32) * 1.5))
            return "expanded_radius"
        end,
        
        -- 2. Change Y level
        change_depth = function()
            Core.log("INFO", "Trying alternative depth")
            local current_y = Navigation.getPosition().y
            local alternatives = SmartMining.getAlternativeDepths(ore_type, current_y)
            if #alternatives > 0 then
                local target = {x = Navigation.getPosition().x, y = alternatives[1], z = Navigation.getPosition().z}
                Navigation.moveTo(target)
                return "changed_depth"
            end
            return nil
        end,
        
        -- 3. Switch pattern
        switch_pattern = function()
            Core.log("INFO", "Switching to exploration pattern")
            current_strategy = {
                pattern = "spiral",
                options = {max_radius = 64, layers = 3}
            }
            return "switched_pattern"
        end,
        
        -- 4. Move to new area
        relocate = function()
            Core.log("INFO", "Relocating to unexplored area")
            local pos = Navigation.getPosition()
            local offset = 100 + math.random(50)
            local angle = math.random() * 2 * math.pi
            local target = {
                x = pos.x + math.floor(math.cos(angle) * offset),
                y = pos.y,
                z = pos.z + math.floor(math.sin(angle) * offset)
            }
            Navigation.moveTo(target, {use_pathfinding = true})
            return "relocated"
        end,
        
        -- 5. Target different ore
        change_target = function()
            if ore_type then
                Core.log("INFO", "Switching to more common ore")
                local alternatives = {"iron", "coal", "copper"}
                for _, alt in ipairs(alternatives) do
                    if alt ~= ore_type then
                        Targeting.addTarget(alt, 64, {priority = 8})
                        return "changed_target"
                    end
                end
            end
            return nil
        end
    }
    
    -- Try strategies in order
    local applied_strategies = {}
    for name, strategy in pairs(strategies) do
        local result = strategy()
        if result then
            table.insert(applied_strategies, result)
            
            -- Test effectiveness after each strategy
            Mining.executePattern("strip", {length = 50, strips = 1})
            local new_rate = mining_stats.ore_blocks / math.max(1, mining_stats.total_blocks)
            
            if new_rate > ore_rate * 1.5 then
                Core.log("INFO", "Scarcity strategy successful: " .. result)
                scarcity_mode = false
                break
            end
        end
    end
    
    Core.emit("smart_mining:scarcity_handled", {
        ore_type = ore_type,
        strategies = applied_strategies,
        success = not scarcity_mode
    })
    
    return true, applied_strategies
end

-- Get alternative depths for an ore
function SmartMining.getAlternativeDepths(ore_type, current_y)
    local ore_info = Targeting.getResourceInfo(ore_type)
    if not ore_info then
        return {}
    end
    
    local alternatives = {}
    local y_range = ore_info.y_range
    local optimal = ore_info.optimal_y
    
    -- Add optimal if not current
    if math.abs(current_y - optimal) > 5 then
        table.insert(alternatives, optimal)
    end
    
    -- Add levels with good historical results
    for y_str, stats in pairs(mining_stats.by_y_level) do
        local y = tonumber(y_str)
        if y and y >= y_range[1] and y <= y_range[2] then
            if stats.ores > 0 and math.abs(y - current_y) > 5 then
                local rate = stats.ores / stats.total
                if rate > SCARCITY_THRESHOLD then
                    table.insert(alternatives, y)
                end
            end
        end
    end
    
    -- Sort by expected effectiveness
    table.sort(alternatives, function(a, b)
        local dist_a = math.abs(a - optimal)
        local dist_b = math.abs(b - optimal)
        return dist_a < dist_b
    end)
    
    return alternatives
end

-- Adapt mining pattern based on conditions
function SmartMining.adaptPattern()
    if not initialized then
        return false, "Module not initialized"
    end
    
    -- Check if it's time to adapt
    if mining_stats.total_blocks - mining_stats.last_adaptation < ADAPTATION_INTERVAL then
        return false, "Too soon to adapt"
    end
    
    mining_stats.last_adaptation = mining_stats.total_blocks
    
    -- Analyze recent efficiency
    local recent_stats = SmartMining.getRecentStats(EFFICIENCY_WINDOW)
    local ore_rate = recent_stats.ores / math.max(1, recent_stats.blocks)
    
    Core.log("INFO", string.format("Analyzing efficiency: %.2f%% ore rate", ore_rate * 100))
    
    -- Determine best pattern
    local recommendations = Optimization.recommendPattern({
        ore_rate = ore_rate,
        area = Area.getAreaStats(),
        target = Targeting.getCurrentTarget(),
        scarcity = scarcity_mode
    })
    
    if #recommendations > 0 then
        local best = recommendations[1]
        
        -- Check if different from current
        if not current_strategy or current_strategy.pattern ~= best.pattern then
            Core.log("INFO", string.format("Adapting pattern to: %s (score: %.2f)", 
                best.pattern, best.score))
            
            current_strategy = {
                pattern = best.pattern,
                options = best.options or {},
                reason = best.reason
            }
            
            -- Track pattern efficiency
            if not mining_stats.pattern_efficiency[best.pattern] then
                mining_stats.pattern_efficiency[best.pattern] = {
                    uses = 0,
                    total_ore_rate = 0,
                    total_blocks = 0
                }
            end
            
            Core.emit("smart_mining:pattern_adapted", current_strategy)
            return true, current_strategy
        end
    end
    
    return false, "No adaptation needed"
end

-- Execute smart mining session
function SmartMining.mine(options)
    if not initialized then
        return false, "Module not initialized"
    end
    
    options = options or {}
    local session_start = os.epoch("utc") / 1000
    local blocks_mined = 0
    local ores_found = {}
    
    Core.log("INFO", "Starting smart mining session")
    
    -- Initial optimization
    if options.target_ores then
        SmartMining.optimizeYLevel(options.target_ores)
    end
    
    -- Main mining loop
    while true do
        -- Check area assignment
        local area_stats = Area.getAreaStats()
        if area_stats and area_stats.progress.saturation > 0.9 then
            Core.log("INFO", "Area saturated, requesting new assignment")
            Core.emit("smart_mining:area_saturated", area_stats)
            break
        end
        
        -- Check resource targets
        local current_target = Targeting.getCurrentTarget()
        if current_target then
            -- Process resource target
            local success, result = Targeting.processNext()
            if success then
                Core.log("INFO", "Resource target completed")
                continue
            end
        end
        
        -- Adapt pattern if needed
        SmartMining.adaptPattern()
        
        -- Execute current strategy
        local pattern = current_strategy and current_strategy.pattern or "strip"
        local pattern_options = current_strategy and current_strategy.options or {
            length = 50,
            strips = 3,
            torch_interval = 8
        }
        
        -- Add smart callbacks
        pattern_options.on_block_mined = function(pos, block_data)
            blocks_mined = blocks_mined + 1
            
            -- Update statistics
            SmartMining.updateStats(pos, block_data)
            
            -- Check for scarcity
            if blocks_mined % 100 == 0 then
                local recent = SmartMining.getRecentStats(200)
                if recent.ores / math.max(1, recent.blocks) < SCARCITY_THRESHOLD then
                    SmartMining.handleScarcity(current_target and current_target.resource)
                end
            end
            
            -- Track ores
            if block_data.is_ore then
                local ore_type = block_data.ore_type or "unknown"
                ores_found[ore_type] = (ores_found[ore_type] or 0) + 1
            end
        end
        
        -- Execute pattern
        local success, err = Mining.executePattern(pattern, pattern_options)
        
        if not success then
            Core.log("ERROR", "Pattern execution failed: " .. tostring(err))
            -- Try recovery
            if err:find("fuel") then
                break
            elseif err:find("inventory") then
                -- Return to storage
                Core.emit("smart_mining:storage_needed")
                break
            else
                -- Try different pattern
                SmartMining.adaptPattern()
            end
        end
        
        -- Check termination conditions
        if options.max_blocks and blocks_mined >= options.max_blocks then
            Core.log("INFO", "Block limit reached")
            break
        end
        
        if options.timeout then
            local elapsed = (os.epoch("utc") / 1000) - session_start
            if elapsed > options.timeout then
                Core.log("INFO", "Session timeout reached")
                break
            end
        end
    end
    
    -- Save statistics
    State.set("smart_mining_stats", mining_stats)
    State.save()
    
    -- Return session results
    local session_time = (os.epoch("utc") / 1000) - session_start
    return true, {
        blocks_mined = blocks_mined,
        ores_found = ores_found,
        time_seconds = session_time,
        blocks_per_minute = (blocks_mined / session_time) * 60,
        final_strategy = current_strategy
    }
end

-- Update mining statistics
function SmartMining.updateStats(pos, block_data)
    mining_stats.total_blocks = mining_stats.total_blocks + 1
    
    -- Track by Y level
    local y_key = tostring(pos.y)
    if not mining_stats.by_y_level[y_key] then
        mining_stats.by_y_level[y_key] = {total = 0, ores = 0}
    end
    mining_stats.by_y_level[y_key].total = mining_stats.by_y_level[y_key].total + 1
    
    -- Track ores
    if block_data.is_ore then
        mining_stats.ore_blocks = mining_stats.ore_blocks + 1
        mining_stats.by_y_level[y_key].ores = mining_stats.by_y_level[y_key].ores + 1
        
        local ore_type = block_data.ore_type or "unknown"
        mining_stats.by_ore_type[ore_type] = (mining_stats.by_ore_type[ore_type] or 0) + 1
    end
    
    -- Update pattern efficiency
    if current_strategy and current_strategy.pattern then
        local pattern_stats = mining_stats.pattern_efficiency[current_strategy.pattern]
        if pattern_stats then
            pattern_stats.total_blocks = pattern_stats.total_blocks + 1
            if block_data.is_ore then
                pattern_stats.total_ore_rate = pattern_stats.total_ore_rate + 
                    (1 / math.max(1, pattern_stats.total_blocks))
            end
        end
    end
end

-- Get recent statistics
function SmartMining.getRecentStats(window_size)
    window_size = window_size or EFFICIENCY_WINDOW
    
    -- This is simplified - in a real implementation we'd track a rolling window
    local recent_blocks = math.min(window_size, mining_stats.total_blocks)
    local recent_ores = math.floor(mining_stats.ore_blocks * (recent_blocks / math.max(1, mining_stats.total_blocks)))
    
    return {
        blocks = recent_blocks,
        ores = recent_ores,
        ore_rate = recent_ores / math.max(1, recent_blocks)
    }
end

-- Get efficiency report
function SmartMining.getEfficiencyReport()
    local report = {
        total_blocks = mining_stats.total_blocks,
        total_ores = mining_stats.ore_blocks,
        overall_rate = mining_stats.ore_blocks / math.max(1, mining_stats.total_blocks),
        by_ore_type = mining_stats.by_ore_type,
        pattern_efficiency = {},
        best_y_levels = {},
        scarcity_mode = scarcity_mode
    }
    
    -- Calculate pattern efficiency
    for pattern, stats in pairs(mining_stats.pattern_efficiency) do
        if stats.total_blocks > 0 then
            report.pattern_efficiency[pattern] = {
                blocks_mined = stats.total_blocks,
                average_ore_rate = stats.total_ore_rate / stats.uses,
                uses = stats.uses
            }
        end
    end
    
    -- Find best Y levels
    local y_rates = {}
    for y_str, stats in pairs(mining_stats.by_y_level) do
        if stats.total > 50 then -- Minimum sample size
            local rate = stats.ores / stats.total
            table.insert(y_rates, {
                y = tonumber(y_str),
                rate = rate,
                samples = stats.total
            })
        end
    end
    table.sort(y_rates, function(a, b) return a.rate > b.rate end)
    
    for i = 1, math.min(5, #y_rates) do
        table.insert(report.best_y_levels, y_rates[i])
    end
    
    return report
end

-- Reset statistics
function SmartMining.resetStats()
    mining_stats = {
        total_blocks = 0,
        ore_blocks = 0,
        by_ore_type = {},
        by_y_level = {},
        pattern_efficiency = {},
        depth_strategies = {},
        last_adaptation = 0
    }
    
    State.set("smart_mining_stats", mining_stats)
    State.save()
    
    return true
end

-- Shutdown module
function SmartMining.shutdown()
    if not initialized then
        return true
    end
    
    Core.log("INFO", "Shutting down Smart Mining module")
    
    -- Save statistics
    State.set("smart_mining_stats", mining_stats)
    State.save()
    
    initialized = false
    return true
end

return SmartMining