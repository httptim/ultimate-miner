-- Ultimate Miner - Resource Targeting Module
-- Handles specific ore targeting, quantity goals, and resource queuing

local Targeting = {}

-- Dependencies
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local Mining = require("turtle.modules.mining")
local Inventory = require("turtle.modules.inventory")
local Optimization = require("turtle.modules.optimization")

-- Constants
local DEFAULT_MAX_SEARCH_RADIUS = 128
local DEFAULT_SEARCH_TIMEOUT = 300 -- 5 minutes per resource
local STATE_KEY = "resource_targets"
local PROGRESS_KEY = "target_progress"

-- Module state
local initialized = false
local resource_queue = {}
local current_target = nil
local progress_data = {}
local search_stats = {
    blocks_searched = 0,
    time_searching = 0,
    resources_found = {}
}

-- Resource definitions with preferred Y levels
local RESOURCE_DATA = {
    diamond = {
        name = "Diamond",
        blocks = {"minecraft:diamond_ore", "minecraft:deepslate_diamond_ore"},
        optimal_y = -59,
        y_range = {-64, 16},
        value = 10
    },
    iron = {
        name = "Iron",
        blocks = {"minecraft:iron_ore", "minecraft:deepslate_iron_ore", "minecraft:raw_iron_block"},
        optimal_y = 16,
        y_range = {-64, 320},
        value = 3
    },
    gold = {
        name = "Gold",
        blocks = {"minecraft:gold_ore", "minecraft:deepslate_gold_ore", "minecraft:raw_gold_block"},
        optimal_y = -16,
        y_range = {-64, 32},
        value = 5
    },
    coal = {
        name = "Coal",
        blocks = {"minecraft:coal_ore", "minecraft:deepslate_coal_ore"},
        optimal_y = 96,
        y_range = {0, 320},
        value = 1
    },
    copper = {
        name = "Copper",
        blocks = {"minecraft:copper_ore", "minecraft:deepslate_copper_ore", "minecraft:raw_copper_block"},
        optimal_y = 48,
        y_range = {-16, 112},
        value = 2
    },
    redstone = {
        name = "Redstone",
        blocks = {"minecraft:redstone_ore", "minecraft:deepslate_redstone_ore"},
        optimal_y = -59,
        y_range = {-64, 16},
        value = 4
    },
    emerald = {
        name = "Emerald",
        blocks = {"minecraft:emerald_ore", "minecraft:deepslate_emerald_ore"},
        optimal_y = 100,
        y_range = {-16, 320},
        value = 15,
        biome_specific = true
    },
    lapis = {
        name = "Lapis Lazuli",
        blocks = {"minecraft:lapis_ore", "minecraft:deepslate_lapis_ore"},
        optimal_y = 0,
        y_range = {-64, 64},
        value = 6
    },
    ancient_debris = {
        name = "Ancient Debris",
        blocks = {"minecraft:ancient_debris"},
        optimal_y = 15,
        y_range = {8, 119},
        value = 50,
        blast_resistant = true
    }
}

-- Initialize module
function Targeting.init()
    if initialized then
        return true, "Already initialized"
    end
    
    Core.log("INFO", "Initializing Resource Targeting module")
    
    -- Load saved state
    local saved_queue = State.get(STATE_KEY, {})
    local saved_progress = State.get(PROGRESS_KEY, {})
    
    if saved_queue and type(saved_queue) == "table" then
        resource_queue = saved_queue
    end
    
    if saved_progress and type(saved_progress) == "table" then
        progress_data = saved_progress
    end
    
    -- Resume current target if any
    if #resource_queue > 0 then
        current_target = resource_queue[1]
        Core.log("INFO", "Resumed resource target: " .. tostring(current_target.resource))
    end
    
    initialized = true
    Core.emit("targeting:initialized")
    return true
end

-- Add a resource target to the queue
function Targeting.addTarget(resource_type, quantity, options)
    if not initialized then
        return false, "Module not initialized"
    end
    
    if not RESOURCE_DATA[resource_type] then
        return false, "Unknown resource type: " .. tostring(resource_type)
    end
    
    if type(quantity) ~= "number" or quantity <= 0 then
        return false, "Invalid quantity"
    end
    
    options = options or {}
    
    local target = {
        id = os.epoch("utc"),
        resource = resource_type,
        quantity = quantity,
        priority = options.priority or 5,
        search_radius = options.search_radius or DEFAULT_MAX_SEARCH_RADIUS,
        timeout = options.timeout or DEFAULT_SEARCH_TIMEOUT,
        pattern = options.pattern or "adaptive",
        added_time = os.epoch("utc") / 1000,
        status = "pending"
    }
    
    -- Initialize progress data
    if not progress_data[target.id] then
        progress_data[target.id] = {
            gathered = 0,
            blocks_mined = 0,
            veins_found = 0,
            search_time = 0,
            start_time = nil,
            end_time = nil
        }
    end
    
    -- Insert based on priority
    local inserted = false
    for i, existing in ipairs(resource_queue) do
        if target.priority > existing.priority then
            table.insert(resource_queue, i, target)
            inserted = true
            break
        end
    end
    
    if not inserted then
        table.insert(resource_queue, target)
    end
    
    -- Save state
    State.set(STATE_KEY, resource_queue)
    State.set(PROGRESS_KEY, progress_data)
    State.save()
    
    Core.log("INFO", string.format("Added resource target: %s x%d (priority: %d)", 
        resource_type, quantity, target.priority))
    Core.emit("targeting:target_added", target)
    
    return true, target.id
end

-- Remove a target from the queue
function Targeting.removeTarget(target_id)
    if not initialized then
        return false, "Module not initialized"
    end
    
    for i, target in ipairs(resource_queue) do
        if target.id == target_id then
            table.remove(resource_queue, i)
            
            -- Clear current target if it matches
            if current_target and current_target.id == target_id then
                current_target = nil
            end
            
            -- Save state
            State.set(STATE_KEY, resource_queue)
            State.save()
            
            Core.emit("targeting:target_removed", target)
            return true
        end
    end
    
    return false, "Target not found"
end

-- Get current targets
function Targeting.getTargets()
    if not initialized then
        return {}
    end
    
    local targets = {}
    for _, target in ipairs(resource_queue) do
        local progress = progress_data[target.id] or {}
        table.insert(targets, {
            id = target.id,
            resource = target.resource,
            quantity = target.quantity,
            gathered = progress.gathered or 0,
            remaining = target.quantity - (progress.gathered or 0),
            priority = target.priority,
            status = target.status,
            progress_percent = math.floor(((progress.gathered or 0) / target.quantity) * 100)
        })
    end
    
    return targets
end

-- Get current active target
function Targeting.getCurrentTarget()
    return current_target
end

-- Get progress for a specific target
function Targeting.getProgress(target_id)
    if not progress_data[target_id] then
        return nil
    end
    
    local target = nil
    for _, t in ipairs(resource_queue) do
        if t.id == target_id then
            target = t
            break
        end
    end
    
    if not target then
        return nil
    end
    
    local progress = progress_data[target_id]
    return {
        target = target,
        gathered = progress.gathered or 0,
        remaining = target.quantity - (progress.gathered or 0),
        blocks_mined = progress.blocks_mined or 0,
        veins_found = progress.veins_found or 0,
        search_time = progress.search_time or 0,
        efficiency = (progress.gathered or 0) / math.max(1, progress.blocks_mined or 1),
        complete = (progress.gathered or 0) >= target.quantity
    }
end

-- Process the next target in queue
function Targeting.processNext()
    if not initialized then
        return false, "Module not initialized"
    end
    
    if #resource_queue == 0 then
        return false, "No targets in queue"
    end
    
    -- Get next target
    current_target = resource_queue[1]
    current_target.status = "active"
    
    local progress = progress_data[current_target.id]
    if not progress.start_time then
        progress.start_time = os.epoch("utc") / 1000
    end
    
    Core.log("INFO", string.format("Processing target: %s x%d", 
        current_target.resource, current_target.quantity))
    Core.emit("targeting:processing_target", current_target)
    
    -- Execute mining for this resource
    local success, result = Targeting.mineForResource(current_target)
    
    if success then
        -- Target completed
        current_target.status = "completed"
        progress.end_time = os.epoch("utc") / 1000
        
        -- Remove from queue
        table.remove(resource_queue, 1)
        current_target = nil
        
        Core.log("INFO", "Target completed successfully")
        Core.emit("targeting:target_completed", current_target, result)
    else
        -- Target failed or incomplete
        if result == "timeout" then
            current_target.status = "timeout"
        elseif result == "cancelled" then
            current_target.status = "cancelled"
        else
            current_target.status = "failed"
        end
        
        Core.log("WARNING", "Target processing failed: " .. tostring(result))
        Core.emit("targeting:target_failed", current_target, result)
    end
    
    -- Save state
    State.set(STATE_KEY, resource_queue)
    State.set(PROGRESS_KEY, progress_data)
    State.save()
    
    return success, result
end

-- Mine for a specific resource target
function Targeting.mineForResource(target)
    local resource_data = RESOURCE_DATA[target.resource]
    if not resource_data then
        return false, "Invalid resource"
    end
    
    local progress = progress_data[target.id]
    local start_time = os.epoch("utc") / 1000
    
    -- Move to optimal Y level if needed
    local current_pos = Navigation.getPosition()
    if current_pos then
        local optimal_y = resource_data.optimal_y
        if math.abs(current_pos.y - optimal_y) > 5 then
            Core.log("INFO", string.format("Moving to optimal Y level %d for %s", 
                optimal_y, resource_data.name))
            
            local move_target = {
                x = current_pos.x,
                y = optimal_y,
                z = current_pos.z
            }
            
            Navigation.moveTo(move_target, {
                use_pathfinding = true,
                fuel_check = true
            })
        end
    end
    
    -- Start adaptive mining for this resource
    local mining_result = Mining.startAdaptiveMining({
        target_ore = target.resource,
        max_blocks = target.search_radius * 10,
        return_home = false,
        on_ore_found = function(ore_type, count)
            if ore_type == target.resource then
                progress.gathered = (progress.gathered or 0) + count
                progress.veins_found = (progress.veins_found or 0) + 1
                
                -- Check if target is complete
                if progress.gathered >= target.quantity then
                    return "complete"
                end
                
                -- Check timeout
                local elapsed = (os.epoch("utc") / 1000) - start_time
                if elapsed > target.timeout then
                    return "timeout"
                end
            end
        end
    })
    
    -- Update search time
    progress.search_time = (progress.search_time or 0) + ((os.epoch("utc") / 1000) - start_time)
    
    -- Save progress
    State.set(PROGRESS_KEY, progress_data)
    State.save()
    
    if progress.gathered >= target.quantity then
        return true, {
            gathered = progress.gathered,
            time_taken = progress.search_time,
            efficiency = progress.gathered / math.max(1, progress.blocks_mined)
        }
    else
        return false, mining_result or "incomplete"
    end
end

-- Clear all targets
function Targeting.clearTargets()
    if not initialized then
        return false, "Module not initialized"
    end
    
    resource_queue = {}
    current_target = nil
    progress_data = {}
    
    State.set(STATE_KEY, resource_queue)
    State.set(PROGRESS_KEY, progress_data)
    State.save()
    
    Core.emit("targeting:targets_cleared")
    return true
end

-- Get resource information
function Targeting.getResourceInfo(resource_type)
    return RESOURCE_DATA[resource_type]
end

-- Get all available resources
function Targeting.getAvailableResources()
    local resources = {}
    for key, data in pairs(RESOURCE_DATA) do
        table.insert(resources, {
            type = key,
            name = data.name,
            optimal_y = data.optimal_y,
            y_range = data.y_range,
            value = data.value,
            special = data.biome_specific or data.blast_resistant or false
        })
    end
    table.sort(resources, function(a, b) return a.value > b.value end)
    return resources
end

-- Calculate estimated time for a resource target
function Targeting.estimateTime(resource_type, quantity)
    local resource_data = RESOURCE_DATA[resource_type]
    if not resource_data then
        return nil
    end
    
    -- Base estimates (blocks per ore)
    local rarity_factor = {
        diamond = 100,
        emerald = 150,
        ancient_debris = 200,
        gold = 50,
        redstone = 40,
        lapis = 45,
        iron = 30,
        copper = 25,
        coal = 20
    }
    
    local blocks_per_ore = rarity_factor[resource_type] or 50
    local mining_speed = 2 -- blocks per second average
    
    local estimated_blocks = quantity * blocks_per_ore
    local estimated_seconds = estimated_blocks / mining_speed
    
    return {
        seconds = estimated_seconds,
        blocks = estimated_blocks,
        formatted = Core.formatDuration(estimated_seconds)
    }
end

-- Get statistics
function Targeting.getStats()
    local total_gathered = {}
    local total_time = 0
    local completed_targets = 0
    
    for id, progress in pairs(progress_data) do
        if progress.end_time then
            completed_targets = completed_targets + 1
            total_time = total_time + (progress.search_time or 0)
        end
        
        -- Find resource type for this target
        for _, target in ipairs(resource_queue) do
            if target.id == id then
                local resource = target.resource
                total_gathered[resource] = (total_gathered[resource] or 0) + (progress.gathered or 0)
                break
            end
        end
    end
    
    return {
        active_targets = #resource_queue,
        completed_targets = completed_targets,
        total_search_time = total_time,
        resources_gathered = total_gathered,
        current_target = current_target and {
            resource = current_target.resource,
            progress = progress_data[current_target.id]
        } or nil
    }
end

-- Shutdown module
function Targeting.shutdown()
    if not initialized then
        return true
    end
    
    Core.log("INFO", "Shutting down Resource Targeting module")
    
    -- Save current state
    State.set(STATE_KEY, resource_queue)
    State.set(PROGRESS_KEY, progress_data)
    State.save()
    
    initialized = false
    return true
end

return Targeting