-- Mining Optimization Module
-- Handles ore vein following, Y-level optimization, and efficiency tracking

local Optimization = {}

-- Dependencies
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local Mining = require("turtle.modules.mining")
local CONSTANTS = require("shared.constants")

-- Module state
local initialized = false
local optimization_data = {
    ore_veins = {},
    y_level_stats = {},
    pattern_efficiency = {},
    ore_predictions = {}
}

-- Ore Y-level optimal ranges (Minecraft 1.21.1)
local ORE_Y_LEVELS = {
    coal = {
        optimal = 96,
        range = {min = 0, max = 320},
        peak_range = {min = 80, max = 112}
    },
    iron = {
        optimal = 16,
        range = {min = -64, max = 320},
        peak_range = {min = -24, max = 56}
    },
    copper = {
        optimal = 48,
        range = {min = -16, max = 112},
        peak_range = {min = 40, max = 56}
    },
    gold = {
        optimal = -16,
        range = {min = -64, max = 32},
        peak_range = {min = -24, max = -8}
    },
    redstone = {
        optimal = -59,
        range = {min = -64, max = 16},
        peak_range = {min = -63, max = -55}
    },
    emerald = {
        optimal = 100,  -- Mountain biomes only
        range = {min = -16, max = 320},
        peak_range = {min = 80, max = 120}
    },
    lapis = {
        optimal = 0,
        range = {min = -64, max = 64},
        peak_range = {min = -8, max = 8}
    },
    diamond = {
        optimal = -59,
        range = {min = -64, max = 16},
        peak_range = {min = -63, max = -55}
    },
    ancient_debris = {
        optimal = 15,
        range = {min = 8, max = 119},
        peak_range = {min = 13, max = 17}
    }
}

-- Initialize the module
function Optimization.init()
    if initialized then
        return true, "Already initialized"
    end
    
    Core.debug("Initializing Optimization module")
    
    -- Load saved optimization data
    optimization_data = State.get("optimization_data", optimization_data)
    
    initialized = true
    Core.info("Optimization module initialized")
    Core.emit("optimization_initialized")
    
    return true
end

-- Enhanced ore vein following with 3D search
function Optimization.followOreVein(start_ore_type, options)
    options = options or {}
    local max_blocks = options.max_blocks or 64
    local search_radius = options.search_radius or 1  -- 1 = adjacent only, 2 = wider search
    local prioritize_clusters = options.prioritize_clusters ~= false
    
    Core.info("Starting optimized ore vein following for: " .. tostring(start_ore_type))
    
    local vein_data = {
        ore_type = start_ore_type,
        blocks_mined = 0,
        positions = {},
        cluster_centers = {},
        start_time = os.epoch("utc")
    }
    
    -- Queue of positions to check
    local to_check = {}
    local checked = {}
    local mined_positions = {}
    
    -- Helper to create position key
    local function posKey(x, y, z)
        return string.format("%d,%d,%d", x, y, z)
    end
    
    -- Helper to add position to check queue
    local function addToCheck(pos)
        local key = posKey(pos.x, pos.y, pos.z)
        if not checked[key] then
            table.insert(to_check, pos)
            checked[key] = true
        end
    end
    
    -- Start with current position
    local start_pos = Navigation.getPosition()
    addToCheck(start_pos)
    
    -- Main vein following loop
    while #to_check > 0 and vein_data.blocks_mined < max_blocks do
        -- Sort by distance to prioritize closer blocks
        if prioritize_clusters then
            table.sort(to_check, function(a, b)
                local dist_a = math.abs(a.x - start_pos.x) + 
                              math.abs(a.y - start_pos.y) + 
                              math.abs(a.z - start_pos.z)
                local dist_b = math.abs(b.x - start_pos.x) + 
                              math.abs(b.y - start_pos.y) + 
                              math.abs(b.z - start_pos.z)
                return dist_a < dist_b
            end)
        end
        
        -- Get next position
        local pos = table.remove(to_check, 1)
        
        -- Navigate to position
        local current = Navigation.getPosition()
        if current.x ~= pos.x or current.y ~= pos.y or current.z ~= pos.z then
            local success = Navigation.moveTo(pos, {use_pathfinding = true})
            if success then
        
        -- Check all 6 adjacent blocks
        local adjacent = {
            {x = 0, y = 0, z = 1, dir = "forward"},
            {x = 0, y = 0, z = -1, dir = "back"},
            {x = 0, y = 1, z = 0, dir = "up"},
            {x = 0, y = -1, z = 0, dir = "down"},
            {x = 1, y = 0, z = 0, dir = "right"},
            {x = -1, y = 0, z = 0, dir = "left"}
        }
        
        for _, offset in ipairs(adjacent) do
            local check_pos = {
                x = pos.x + offset.x,
                y = pos.y + offset.y,
                z = pos.z + offset.z
            }
            
            -- Skip if already mined
            local key = posKey(check_pos.x, check_pos.y, check_pos.z)
            if not mined_positions[key] then
                -- Determine actual direction to face
                local inspect_dir = offset.dir
                if offset.dir == "right" then
                    Navigation.turnRight()
                    inspect_dir = "forward"
                elseif offset.dir == "left" then
                    Navigation.turnLeft()
                    inspect_dir = "forward"
                elseif offset.dir == "back" then
                    Navigation.turnRight()
                    Navigation.turnRight()
                    inspect_dir = "forward"
                end
            
            -- Check for ore
            local success, block_data = Mining.inspect(inspect_dir)
            if success and block_data.is_ore then
                -- Check if it's the same ore type (or any ore if not specified)
                if not start_ore_type or block_data.ore_type == start_ore_type then
                    -- Mine the ore
                    if Mining.dig(inspect_dir) then
                        vein_data.blocks_mined = vein_data.blocks_mined + 1
                        mined_positions[key] = true
                        table.insert(vein_data.positions, check_pos)
                        
                        -- Add this position to check for more adjacent ores
                        addToCheck(check_pos)
                        
                        -- Extended search radius
                        if search_radius > 1 then
                            for dx = -search_radius, search_radius do
                                for dy = -search_radius, search_radius do
                                    for dz = -search_radius, search_radius do
                                        if math.abs(dx) + math.abs(dy) + math.abs(dz) <= search_radius then
                                            addToCheck({
                                                x = check_pos.x + dx,
                                                y = check_pos.y + dy,
                                                z = check_pos.z + dz
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
                -- Turn back to original facing
                if offset.dir == "right" then
                    Navigation.turnLeft()
                elseif offset.dir == "left" then
                    Navigation.turnRight()
                elseif offset.dir == "back" then
                    Navigation.turnRight()
                    Navigation.turnRight()
                end
            end -- end if not mined_positions
        end
            else
                Core.debug("Cannot reach ore at " .. posKey(pos.x, pos.y, pos.z))
            end -- end if success (navigation)
        end -- end if need to move
    end
    
    -- Calculate cluster centers for analysis
    if #vein_data.positions > 3 then
        local center_x, center_y, center_z = 0, 0, 0
        for _, pos in ipairs(vein_data.positions) do
            center_x = center_x + pos.x
            center_y = center_y + pos.y
            center_z = center_z + pos.z
        end
        center_x = center_x / #vein_data.positions
        center_y = center_y / #vein_data.positions
        center_z = center_z / #vein_data.positions
        
        table.insert(vein_data.cluster_centers, {
            x = center_x,
            y = center_y,
            z = center_z,
            size = #vein_data.positions
        })
    end
    
    -- Update optimization data
    if not optimization_data.ore_veins[start_ore_type] then
        optimization_data.ore_veins[start_ore_type] = {}
    end
    table.insert(optimization_data.ore_veins[start_ore_type], vein_data)
    State.set("optimization_data", optimization_data)
    
    Core.info(string.format("Vein following complete: %d blocks mined", vein_data.blocks_mined))
    Core.emit("vein_complete", vein_data)
    
    return true, vein_data
end

-- Get optimal Y level for specific ore type
function Optimization.getOptimalYLevel(ore_type)
    ore_type = ore_type:lower()
    
    if ORE_Y_LEVELS[ore_type] then
        return ORE_Y_LEVELS[ore_type].optimal, ORE_Y_LEVELS[ore_type]
    end
    
    -- Default for unknown ores
    return 0, {optimal = 0, range = {min = -64, max = 320}}
end

-- Check if current Y level is optimal for target ore
function Optimization.isYLevelOptimal(ore_type, current_y, tolerance)
    tolerance = tolerance or 8
    ore_type = ore_type:lower()
    
    if not ORE_Y_LEVELS[ore_type] then
        return true  -- Unknown ore, any level is fine
    end
    
    local ore_data = ORE_Y_LEVELS[ore_type]
    
    -- Check if in peak range
    if current_y >= ore_data.peak_range.min and current_y <= ore_data.peak_range.max then
        return true, "peak"
    end
    
    -- Check if within tolerance of optimal
    if math.abs(current_y - ore_data.optimal) <= tolerance then
        return true, "near_optimal"
    end
    
    -- Check if at least in valid range
    if current_y >= ore_data.range.min and current_y <= ore_data.range.max then
        return false, "suboptimal"
    end
    
    return false, "out_of_range"
end

-- Calculate best Y level for multiple ore types
function Optimization.calculateBestYLevel(ore_types)
    if not ore_types or #ore_types == 0 then
        return 0  -- Default level
    end
    
    -- If single ore, return its optimal
    if #ore_types == 1 then
        return Optimization.getOptimalYLevel(ore_types[1])
    end
    
    -- For multiple ores, find overlapping ranges
    local min_y = -64
    local max_y = 320
    
    -- Find intersection of all ore ranges
    for _, ore_type in ipairs(ore_types) do
        ore_type = ore_type:lower()
        if ORE_Y_LEVELS[ore_type] then
            min_y = math.max(min_y, ORE_Y_LEVELS[ore_type].range.min)
            max_y = math.min(max_y, ORE_Y_LEVELS[ore_type].range.max)
        end
    end
    
    -- If no valid intersection, use weighted average
    if min_y > max_y then
        local weighted_sum = 0
        local weight_total = 0
        
        for _, ore_type in ipairs(ore_types) do
            ore_type = ore_type:lower()
            if ORE_Y_LEVELS[ore_type] then
                -- Weight by ore value
                local weight = CONSTANTS.ORES[ore_type] and CONSTANTS.ORES[ore_type].value or 1
                weighted_sum = weighted_sum + (ORE_Y_LEVELS[ore_type].optimal * weight)
                weight_total = weight_total + weight
            end
        end
        
        return math.floor(weighted_sum / weight_total)
    end
    
    -- Find best Y within valid range
    local best_y = (min_y + max_y) / 2
    local best_score = 0
    
    for y = min_y, max_y do
        local score = 0
        
        for _, ore_type in ipairs(ore_types) do
            ore_type = ore_type:lower()
            if ORE_Y_LEVELS[ore_type] then
                local ore_data = ORE_Y_LEVELS[ore_type]
                
                -- Score based on distance from optimal
                local distance = math.abs(y - ore_data.optimal)
                local ore_score = 100 - (distance * 2)
                
                -- Bonus for being in peak range
                if y >= ore_data.peak_range.min and y <= ore_data.peak_range.max then
                    ore_score = ore_score + 50
                end
                
                -- Weight by ore value
                local weight = CONSTANTS.ORES[ore_type] and CONSTANTS.ORES[ore_type].value or 1
                score = score + (ore_score * weight)
            end
        end
        
        if score > best_score then
            best_score = score
            best_y = y
        end
    end
    
    return best_y
end

-- Track pattern efficiency
function Optimization.trackPatternEfficiency(pattern_name, stats)
    if not optimization_data.pattern_efficiency[pattern_name] then
        optimization_data.pattern_efficiency[pattern_name] = {
            runs = 0,
            total_blocks = 0,
            total_ores = 0,
            total_fuel = 0,
            total_time = 0,
            ore_types = {}
        }
    end
    
    local pattern_data = optimization_data.pattern_efficiency[pattern_name]
    
    -- Update statistics
    pattern_data.runs = pattern_data.runs + 1
    pattern_data.total_blocks = pattern_data.total_blocks + (stats.blocks_mined or 0)
    pattern_data.total_ores = pattern_data.total_ores + (stats.ores_found or 0)
    pattern_data.total_fuel = pattern_data.total_fuel + (stats.fuel_used or 0)
    pattern_data.total_time = pattern_data.total_time + (stats.time_elapsed or 0)
    
    -- Track ore types found
    if stats.ore_types then
        for ore_type, count in pairs(stats.ore_types) do
            pattern_data.ore_types[ore_type] = (pattern_data.ore_types[ore_type] or 0) + count
        end
    end
    
    -- Calculate efficiency metrics
    local efficiency = {
        ore_percentage = pattern_data.total_blocks > 0 and 
                        (pattern_data.total_ores / pattern_data.total_blocks * 100) or 0,
        fuel_per_ore = pattern_data.total_ores > 0 and 
                      (pattern_data.total_fuel / pattern_data.total_ores) or 0,
        blocks_per_minute = pattern_data.total_time > 0 and 
                           (pattern_data.total_blocks / pattern_data.total_time * 60) or 0,
        average_run_time = pattern_data.runs > 0 and 
                          (pattern_data.total_time / pattern_data.runs) or 0
    }
    
    pattern_data.efficiency = efficiency
    State.set("optimization_data", optimization_data)
    
    return efficiency
end

-- Get pattern recommendations based on target
function Optimization.recommendPattern(target)
    local recommendations = {}
    
    -- Analyze target
    if target.ore_type then
        -- Specific ore targeting
        local ore_type = target.ore_type:lower()
        local optimal_y = Optimization.getOptimalYLevel(ore_type)
        
        if ore_type == "diamond" or ore_type == "ancient_debris" then
            -- Deep ores benefit from branch mining
            table.insert(recommendations, {
                pattern = "branch",
                reason = "Efficient for deep ore exploration",
                priority = 1
            })
        elseif ore_type == "coal" or ore_type == "iron" then
            -- Common ores benefit from strip mining
            table.insert(recommendations, {
                pattern = "strip",
                reason = "Fast coverage for common ores",
                priority = 1
            })
        elseif ore_type == "emerald" then
            -- Mountain-specific ore
            table.insert(recommendations, {
                pattern = "adaptive",
                reason = "Adapts to mountain terrain",
                priority = 1
            })
        end
    end
    
    if target.area then
        -- Area clearing
        table.insert(recommendations, {
            pattern = "quarry",
            reason = "Systematic area excavation",
            priority = 1
        })
    end
    
    if target.exploration then
        -- General exploration
        table.insert(recommendations, {
            pattern = "spiral",
            reason = "Good coverage for exploration",
            priority = 2
        })
    end
    
    -- Analyze historical efficiency
    local best_efficiency = 0
    local best_pattern = nil
    
    for pattern, data in pairs(optimization_data.pattern_efficiency) do
        if data.efficiency and data.efficiency.ore_percentage > best_efficiency then
            best_efficiency = data.efficiency.ore_percentage
            best_pattern = pattern
        end
    end
    
    if best_pattern then
        table.insert(recommendations, {
            pattern = best_pattern,
            reason = string.format("Historical best: %.1f%% ore rate", best_efficiency),
            priority = 3
        })
    end
    
    -- Default recommendation
    if #recommendations == 0 then
        table.insert(recommendations, {
            pattern = "branch",
            reason = "General purpose mining",
            priority = 4
        })
    end
    
    -- Sort by priority
    table.sort(recommendations, function(a, b) return a.priority < b.priority end)
    
    return recommendations
end

-- Predict ore locations based on geological patterns
function Optimization.predictOreLocations(current_pos, ore_type, radius)
    radius = radius or 16
    ore_type = ore_type:lower()
    
    local predictions = {}
    
    -- Get historical vein data
    local vein_history = optimization_data.ore_veins[ore_type] or {}
    
    if #vein_history > 0 then
        -- Analyze vein patterns
        local avg_vein_size = 0
        local common_offsets = {}
        
        for _, vein in ipairs(vein_history) do
            avg_vein_size = avg_vein_size + #vein.positions
            
            -- Calculate offsets between ore blocks
            for i = 2, #vein.positions do
                local offset = {
                    x = vein.positions[i].x - vein.positions[i-1].x,
                    y = vein.positions[i].y - vein.positions[i-1].y,
                    z = vein.positions[i].z - vein.positions[i-1].z
                }
                
                local key = string.format("%d,%d,%d", offset.x, offset.y, offset.z)
                common_offsets[key] = (common_offsets[key] or 0) + 1
            end
        end
        
        avg_vein_size = avg_vein_size / #vein_history
        
        -- Generate predictions based on patterns
        for offset_key, frequency in pairs(common_offsets) do
            if frequency > #vein_history * 0.3 then  -- Common pattern
                local parts = {}
                for part in offset_key:gmatch("([^,]+)") do
                    table.insert(parts, tonumber(part))
                end
                
                if #parts == 3 then
                    table.insert(predictions, {
                        x = current_pos.x + parts[1],
                        y = current_pos.y + parts[2],
                        z = current_pos.z + parts[3],
                        confidence = frequency / #vein_history
                    })
                end
            end
        end
    end
    
    -- Add Y-level based predictions
    local ore_data = ORE_Y_LEVELS[ore_type]
    if ore_data then
        -- If not at optimal Y, predict at optimal level
        if math.abs(current_pos.y - ore_data.optimal) > 4 then
            table.insert(predictions, {
                x = current_pos.x,
                y = ore_data.optimal,
                z = current_pos.z,
                confidence = 0.7
            })
        end
    end
    
    -- Sort by confidence
    table.sort(predictions, function(a, b) return a.confidence > b.confidence end)
    
    -- Store predictions for analysis
    optimization_data.ore_predictions[ore_type] = predictions
    State.set("optimization_data", optimization_data)
    
    return predictions
end

-- Dynamic pattern adjustment based on real-time data
function Optimization.adjustPattern(current_pattern, real_time_stats)
    local adjustments = {}
    
    -- Check ore density
    local ore_rate = real_time_stats.blocks_mined > 0 and 
                    (real_time_stats.ores_found / real_time_stats.blocks_mined) or 0
    
    if ore_rate < 0.01 then  -- Less than 1% ore
        -- Very low density - increase spacing or speed
        adjustments.spacing = math.min((current_pattern.spacing or 3) + 1, 5)
        adjustments.speed = "fast"
        adjustments.reason = "Low ore density"
        
    elseif ore_rate > 0.05 then  -- More than 5% ore
        -- High density - decrease spacing, more thorough
        adjustments.spacing = math.max((current_pattern.spacing or 3) - 1, 1)
        adjustments.speed = "thorough"
        adjustments.vein_follow = true
        adjustments.reason = "High ore density"
    end
    
    -- Check fuel efficiency
    if real_time_stats.fuel_used and real_time_stats.distance_traveled then
        local fuel_per_block = real_time_stats.fuel_used / real_time_stats.distance_traveled
        
        if fuel_per_block > 1.5 then
            -- Inefficient fuel use - optimize path
            adjustments.optimize_path = true
            adjustments.avoid_backtracking = true
        end
    end
    
    -- Check inventory usage
    if real_time_stats.inventory_full_events and real_time_stats.inventory_full_events > 2 then
        -- Frequent inventory issues - adjust pattern
        adjustments.return_frequency = "frequent"
        adjustments.compact_mining = true
    end
    
    -- Store adjustment history
    if not optimization_data.pattern_adjustments then
        optimization_data.pattern_adjustments = {}
    end
    
    table.insert(optimization_data.pattern_adjustments, {
        timestamp = os.epoch("utc"),
        pattern = current_pattern.type,
        adjustments = adjustments,
        stats = real_time_stats
    })
    
    State.set("optimization_data", optimization_data)
    
    return adjustments
end

-- Get optimization statistics
function Optimization.getStats()
    local stats = {
        total_veins_tracked = 0,
        ore_type_stats = {},
        pattern_rankings = {},
        y_level_analysis = {}
    }
    
    -- Count veins by type
    for ore_type, veins in pairs(optimization_data.ore_veins) do
        stats.total_veins_tracked = stats.total_veins_tracked + #veins
        
        local total_size = 0
        for _, vein in ipairs(veins) do
            total_size = total_size + #vein.positions
        end
        
        stats.ore_type_stats[ore_type] = {
            vein_count = #veins,
            average_size = #veins > 0 and (total_size / #veins) or 0
        }
    end
    
    -- Rank patterns by efficiency
    local patterns = {}
    for pattern, data in pairs(optimization_data.pattern_efficiency) do
        if data.efficiency then
            table.insert(patterns, {
                name = pattern,
                efficiency = data.efficiency.ore_percentage,
                runs = data.runs
            })
        end
    end
    
    table.sort(patterns, function(a, b) return a.efficiency > b.efficiency end)
    stats.pattern_rankings = patterns
    
    -- Y-level analysis
    for ore_type, data in pairs(ORE_Y_LEVELS) do
        stats.y_level_analysis[ore_type] = {
            optimal = data.optimal,
            range = data.range,
            peak_range = data.peak_range
        }
    end
    
    return stats
end

-- Clear optimization data
function Optimization.clearData()
    optimization_data = {
        ore_veins = {},
        y_level_stats = {},
        pattern_efficiency = {},
        ore_predictions = {}
    }
    State.set("optimization_data", optimization_data)
    Core.info("Optimization data cleared")
    return true
end

-- Shutdown function
function Optimization.shutdown()
    if not initialized then
        return true
    end
    
    Core.debug("Shutting down Optimization module")
    
    -- Save final state
    State.set("optimization_data", optimization_data)
    
    initialized = false
    return true
end

return Optimization