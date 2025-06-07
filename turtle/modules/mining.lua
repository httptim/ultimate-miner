-- Mining Module
-- Handles block breaking, ore detection, and mining operations
-- Integrates with Patterns and Optimization modules for advanced mining

local Mining = {}

-- Dependencies
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local Inventory = require("turtle.modules.inventory")
local CONSTANTS = require("shared.constants")

-- Lazy-load pattern modules to avoid circular dependencies
local Patterns = nil
local Optimization = nil

-- Module state
local initialized = false
local blocks_mined = 0
local ores_found = 0
local mining_stats = {
    by_type = {},
    start_time = 0
}

-- Falling block types that need special handling
local FALLING_BLOCKS = {
    ["minecraft:sand"] = true,
    ["minecraft:red_sand"] = true,
    ["minecraft:gravel"] = true,
    ["minecraft:concrete_powder"] = true,
    ["minecraft:anvil"] = true,
    ["minecraft:pointed_dripstone"] = true
}

-- Blocks to never mine (for safety)
local PROTECTED_BLOCKS = {
    ["minecraft:bedrock"] = true,
    ["minecraft:command_block"] = true,
    ["minecraft:chain_command_block"] = true,
    ["minecraft:repeating_command_block"] = true,
    ["minecraft:structure_block"] = true,
    ["minecraft:barrier"] = true,
    ["minecraft:spawner"] = true,
    ["minecraft:end_portal_frame"] = true
}

-- Valuable blocks that should trigger special handling
local VALUABLE_BLOCKS = {
    ["minecraft:diamond_ore"] = true,
    ["minecraft:deepslate_diamond_ore"] = true,
    ["minecraft:emerald_ore"] = true,
    ["minecraft:deepslate_emerald_ore"] = true,
    ["minecraft:ancient_debris"] = true,
    ["minecraft:spawner"] = true
}

-- Initialize the module
function Mining.init()
    if initialized then
        return true, "Already initialized"
    end
    
    Core.debug("Initializing Mining module")
    
    -- Load saved mining stats
    mining_stats = State.get("mining_stats", mining_stats)
    blocks_mined = State.get("blocks_mined", 0)
    ores_found = State.get("ores_found", 0)
    
    mining_stats.start_time = mining_stats.start_time or os.epoch("utc")
    
    initialized = true
    Core.info("Mining module initialized")
    Core.emit("mining_initialized")
    
    return true
end

-- Helper function to check if a block is an ore
local function isOre(block_data)
    if not block_data or not block_data.name then
        return false
    end
    
    -- Check against ore constants
    for ore_type, ore_data in pairs(CONSTANTS.ORES) do
        if block_data.name == ore_data.stone or block_data.name == ore_data.deepslate then
            return true, ore_type, ore_data
        end
    end
    
    -- Also check if the name contains "ore" for modded ores
    if block_data.name:find("ore") then
        return true, "unknown", {name = "unknown", value = 1}
    end
    
    return false
end

-- Update mining statistics
local function updateStats(block_name, is_ore)
    blocks_mined = blocks_mined + 1
    State.set("blocks_mined", blocks_mined)
    
    if is_ore then
        ores_found = ores_found + 1
        State.set("ores_found", ores_found)
    end
    
    -- Track by type
    if not mining_stats.by_type[block_name] then
        mining_stats.by_type[block_name] = 0
    end
    mining_stats.by_type[block_name] = mining_stats.by_type[block_name] + 1
    
    State.set("mining_stats", mining_stats)
end

-- Inspect a block in a direction
function Mining.inspect(direction)
    direction = direction or "forward"
    
    local inspect_func
    if direction == "up" then
        inspect_func = turtle.inspectUp
    elseif direction == "down" then
        inspect_func = turtle.inspectDown
    else
        inspect_func = turtle.inspect
    end
    
    local success, data = inspect_func()
    if not success then
        return false, data or "No block detected"
    end
    
    -- Check if it's an ore
    local is_ore, ore_type, ore_data = isOre(data)
    if is_ore then
        data.is_ore = true
        data.ore_type = ore_type
        data.ore_data = ore_data
    end
    
    -- Check if it's protected
    if PROTECTED_BLOCKS[data.name] then
        data.is_protected = true
    end
    
    -- Check if it's falling
    if FALLING_BLOCKS[data.name] then
        data.is_falling = true
    end
    
    -- Check if it's valuable
    if VALUABLE_BLOCKS[data.name] then
        data.is_valuable = true
    end
    
    return true, data
end

-- Detect if there's a block in a direction
function Mining.detect(direction)
    direction = direction or "forward"
    
    if direction == "up" then
        return turtle.detectUp()
    elseif direction == "down" then
        return turtle.detectDown()
    else
        return turtle.detect()
    end
end

-- Compare block with selected inventory slot
function Mining.compare(direction)
    direction = direction or "forward"
    
    if direction == "up" then
        return turtle.compareUp()
    elseif direction == "down" then
        return turtle.compareDown()
    else
        return turtle.compare()
    end
end

-- Dig a single block with safety checks
function Mining.dig(direction)
    direction = direction or "forward"
    
    -- Check if there's a block to mine
    if not Mining.detect(direction) then
        return true, "No block to mine"
    end
    
    -- Inspect the block first
    local success, block_data = Mining.inspect(direction)
    if success then
        -- Check if protected
        if block_data.is_protected then
            Core.warn("Attempted to mine protected block: " .. block_data.name)
            Core.emit("protected_block_encountered", block_data)
            return false, "Protected block"
        end
        
        -- Special handling for valuable blocks
        if block_data.is_valuable then
            Core.info("Found valuable block: " .. block_data.name)
            Core.emit("valuable_block_found", block_data)
        end
        
        -- Check inventory space
        if Inventory.isFull() then
            Core.debug("Inventory full, attempting to make space")
            local made_space = Inventory.makeSpace(1)
            if not made_space then
                Core.emit("mining_inventory_full")
                return false, "Inventory full"
            end
        end
    end
    
    -- Select appropriate dig function
    local dig_func
    if direction == "up" then
        dig_func = turtle.digUp
    elseif direction == "down" then
        dig_func = turtle.digDown
    else
        dig_func = turtle.dig
    end
    
    -- Handle falling blocks
    local is_falling = block_data and block_data.is_falling
    local attempts = 0
    local max_attempts = is_falling and 10 or 1
    
    repeat
        success = dig_func()
        if success then
            if block_data then
                updateStats(block_data.name, block_data.is_ore)
                Core.emit("block_mined", {
                    name = block_data.name,
                    direction = direction,
                    is_ore = block_data.is_ore,
                    ore_type = block_data.ore_type
                })
            end
            
            -- For falling blocks, wait a moment and check again
            if is_falling then
                os.sleep(0.5)
                if not Mining.detect(direction) then
                    break
                end
            end
        else
            break
        end
        
        attempts = attempts + 1
    until not is_falling or attempts >= max_attempts
    
    return success, success and "Block mined" or "Failed to mine block"
end

-- Dig forward with movement
function Mining.digMove(direction)
    direction = direction or "forward"
    
    -- First dig the block
    local success, msg = Mining.dig(direction)
    if not success and msg ~= "No block to mine" then
        return false, msg
    end
    
    -- Then move
    local move_func
    if direction == "up" then
        move_func = Navigation.up
    elseif direction == "down" then
        move_func = Navigation.down
    elseif direction == "back" then
        move_func = Navigation.back
    else
        move_func = Navigation.forward
    end
    
    success, msg = move_func()
    if not success then
        return false, "Failed to move: " .. tostring(msg)
    end
    
    return true, "Dug and moved " .. direction
end

-- Mine all adjacent ores (vein mining)
function Mining.mineVein(max_blocks)
    max_blocks = max_blocks or 64
    local mined = 0
    local positions_to_check = {}
    local checked_positions = {}
    
    -- Helper to generate position key
    local function posKey(pos)
        return string.format("%d,%d,%d", pos.x, pos.y, pos.z)
    end
    
    -- Add current position to check
    local current_pos = Navigation.getPosition()
    table.insert(positions_to_check, current_pos)
    
    while #positions_to_check > 0 and mined < max_blocks do
        local pos = table.remove(positions_to_check, 1)
        local key = posKey(pos)
        
        -- Skip if already checked
        if checked_positions[key] then
            goto continue
        end
        checked_positions[key] = true
        
        -- Move to position if not there
        local current = Navigation.getPosition()
        if current.x ~= pos.x or current.y ~= pos.y or current.z ~= pos.z then
            local success = Navigation.moveTo(pos)
            if not success then
                goto continue
            end
        end
        
        -- Check all 6 directions
        local directions = {
            {dir = "forward", dx = 0, dy = 0, dz = 1},
            {dir = "back", dx = 0, dy = 0, dz = -1},
            {dir = "up", dx = 0, dy = 1, dz = 0},
            {dir = "down", dx = 0, dy = -1, dz = 0},
            {dir = "left", dx = -1, dy = 0, dz = 0},
            {dir = "right", dx = 1, dy = 0, dz = 0}
        }
        
        for _, dir_info in ipairs(directions) do
            -- For left/right, we need to turn
            if dir_info.dir == "left" then
                Navigation.turnLeft()
                dir_info.dir = "forward"
            elseif dir_info.dir == "right" then
                Navigation.turnRight()
                dir_info.dir = "forward"
            end
            
            -- Check for ore
            local success, block_data = Mining.inspect(dir_info.dir)
            if success and block_data.is_ore then
                -- Mine it
                if Mining.dig(dir_info.dir) then
                    mined = mined + 1
                    
                    -- Add new position to check
                    local new_pos = {
                        x = pos.x + dir_info.dx,
                        y = pos.y + dir_info.dy,
                        z = pos.z + dir_info.dz,
                        facing = current.facing
                    }
                    table.insert(positions_to_check, new_pos)
                end
            end
            
            -- Turn back if we turned
            if dir_info.dx == -1 then
                Navigation.turnRight()
            elseif dir_info.dx == 1 then
                Navigation.turnLeft()
            end
        end
        
        ::continue::
    end
    
    Core.info("Vein mining complete. Mined " .. mined .. " blocks")
    Core.emit("vein_mining_complete", {blocks_mined = mined})
    
    return true, mined
end

-- Mine a single layer around the turtle
function Mining.mineAround()
    local mined = 0
    
    -- Mine all four sides
    for i = 1, 4 do
        if Mining.dig("forward") then
            mined = mined + 1
        end
        Navigation.turnRight()
    end
    
    -- Mine up and down
    if Mining.dig("up") then
        mined = mined + 1
    end
    if Mining.dig("down") then
        mined = mined + 1
    end
    
    return true, mined
end

-- Create a 3x3 tunnel
function Mining.mine3x3(length)
    length = length or 1
    local start_pos = Navigation.getPosition()
    
    for i = 1, length do
        -- Mine middle row
        Mining.dig("forward")
        if not Navigation.forward() then
            return false, "Movement blocked at length " .. i
        end
        
        -- Mine left column
        Navigation.turnLeft()
        Mining.dig("forward")
        Mining.dig("up")
        Mining.dig("down")
        
        -- Mine right column
        Navigation.turnRight()
        Navigation.turnRight()
        Mining.dig("forward")
        Mining.dig("up")
        Mining.dig("down")
        
        -- Return to center
        Navigation.turnLeft()
        
        -- Mine center column up/down
        Mining.dig("up")
        Mining.dig("down")
        
        -- Check fuel
        if turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() < 100 then
            Core.warn("Low fuel during 3x3 mining")
            if not Inventory.consumeFuel(500) then
                return false, "Insufficient fuel"
            end
        end
        
        -- Check inventory
        if Inventory.getFreeSlots() < 2 then
            local made_space = Inventory.makeSpace(2)
            if not made_space then
                Core.warn("Inventory full during 3x3 mining")
                return false, "Inventory full"
            end
        end
    end
    
    return true, length
end

-- Get mining statistics
function Mining.getStats()
    local runtime = (os.epoch("utc") - mining_stats.start_time) / 1000
    local blocks_per_minute = runtime > 0 and (blocks_mined / runtime * 60) or 0
    
    return {
        blocks_mined = blocks_mined,
        ores_found = ores_found,
        ore_percentage = blocks_mined > 0 and (ores_found / blocks_mined * 100) or 0,
        runtime_seconds = runtime,
        blocks_per_minute = blocks_per_minute,
        by_type = mining_stats.by_type
    }
end

-- Execute a mining pattern
function Mining.executePattern(pattern_type, options)
    -- Lazy load Patterns module
    if not Patterns then
        Patterns = require("turtle.modules.patterns")
        Patterns.init()
    end
    
    Core.info("Executing mining pattern: " .. pattern_type)
    return Patterns.execute(pattern_type, options)
end

-- Mine for specific ore with optimization
function Mining.mineForOre(ore_type, options)
    options = options or {}
    
    -- Lazy load Optimization module
    if not Optimization then
        Optimization = require("turtle.modules.optimization")
        Optimization.init()
    end
    
    Core.info("Mining for specific ore: " .. ore_type)
    
    -- Get optimal Y level
    local optimal_y, y_data = Optimization.getOptimalYLevel(ore_type)
    local current_pos = Navigation.getPosition()
    
    -- Move to optimal Y level if needed
    if math.abs(current_pos.y - optimal_y) > 8 then
        Core.info(string.format("Moving to optimal Y level %d for %s", optimal_y, ore_type))
        Navigation.moveTo({
            x = current_pos.x,
            y = optimal_y,
            z = current_pos.z
        })
    end
    
    -- Get pattern recommendation
    local recommendations = Optimization.recommendPattern({ore_type = ore_type})
    local pattern = options.pattern or recommendations[1].pattern
    
    -- Execute pattern with ore-specific options
    local pattern_options = {
        target_ore = ore_type,
        length = options.length or 50,
        torch_interval = 8,
        return_home = options.return_home
    }
    
    return Mining.executePattern(pattern, pattern_options)
end

-- Enhanced vein mining with optimization
function Mining.mineVeinOptimized(ore_type, max_blocks)
    -- Lazy load Optimization module
    if not Optimization then
        Optimization = require("turtle.modules.optimization")
        Optimization.init()
    end
    
    return Optimization.followOreVein(ore_type, {
        max_blocks = max_blocks or 64,
        search_radius = 2,
        prioritize_clusters = true
    })
end

-- Start adaptive mining
function Mining.startAdaptiveMining(options)
    -- Lazy load modules
    if not Patterns then
        Patterns = require("turtle.modules.patterns")
        Patterns.init()
    end
    
    if not Optimization then
        Optimization = require("turtle.modules.optimization")
        Optimization.init()
    end
    
    Core.info("Starting adaptive mining")
    
    -- If targeting multiple ores, calculate best Y level
    if options.ore_types and #options.ore_types > 1 then
        local best_y = Optimization.calculateBestYLevel(options.ore_types)
        local current_pos = Navigation.getPosition()
        
        if math.abs(current_pos.y - best_y) > 8 then
            Core.info(string.format("Moving to optimal Y level %d for multiple ores", best_y))
            Navigation.moveTo({
                x = current_pos.x,
                y = best_y,
                z = current_pos.z
            })
        end
    end
    
    return Patterns.adaptiveMine(options)
end

-- Get available mining patterns
function Mining.getPatterns()
    -- Lazy load Patterns module
    if not Patterns then
        Patterns = require("turtle.modules.patterns")
        Patterns.init()
    end
    
    return Patterns.getAvailablePatterns()
end

-- Get mining recommendations
function Mining.getRecommendations(target)
    -- Lazy load Optimization module
    if not Optimization then
        Optimization = require("turtle.modules.optimization")
        Optimization.init()
    end
    
    return Optimization.recommendPattern(target)
end

-- Check if we can mine in a direction
function Mining.canMine(direction)
    if not Mining.detect(direction) then
        return true, "No block"
    end
    
    local success, block_data = Mining.inspect(direction)
    if not success then
        return false, "Inspection failed"
    end
    
    if block_data.is_protected then
        return false, "Protected block"
    end
    
    return true, "Can mine"
end

-- Find nearest ore (simple scan)
function Mining.findOre(radius)
    radius = radius or 3
    local current_pos = Navigation.getPosition()
    local ores = {}
    
    -- Scan in a cube around current position
    for dx = -radius, radius do
        for dy = -radius, radius do
            for dz = -radius, radius do
                -- Skip current position
                if dx == 0 and dy == 0 and dz == 0 then
                    goto continue
                end
                
                -- Calculate target position
                local target = {
                    x = current_pos.x + dx,
                    y = current_pos.y + dy,
                    z = current_pos.z + dz
                }
                
                -- This is a simplified check - in reality we'd need to move to scan
                -- For now, just check immediate surroundings
                if math.abs(dx) <= 1 and math.abs(dy) <= 1 and math.abs(dz) <= 1 then
                    local dir = nil
                    if dx == 0 and dy == 0 and dz == 1 then dir = "forward"
                    elseif dx == 0 and dy == 1 and dz == 0 then dir = "up"
                    elseif dx == 0 and dy == -1 and dz == 0 then dir = "down"
                    end
                    
                    if dir then
                        local success, block_data = Mining.inspect(dir)
                        if success and block_data.is_ore then
                            table.insert(ores, {
                                position = target,
                                direction = dir,
                                ore_type = block_data.ore_type,
                                name = block_data.name
                            })
                        end
                    end
                end
                
                ::continue::
            end
        end
    end
    
    return ores
end

-- Reset mining statistics
function Mining.resetStats()
    blocks_mined = 0
    ores_found = 0
    mining_stats = {
        by_type = {},
        start_time = os.epoch("utc")
    }
    
    State.set("blocks_mined", blocks_mined)
    State.set("ores_found", ores_found)
    State.set("mining_stats", mining_stats)
    
    Core.emit("mining_stats_reset")
    return true
end

-- Shutdown function
function Mining.shutdown()
    if not initialized then
        return true
    end
    
    Core.debug("Shutting down Mining module")
    initialized = false
    
    return true
end

return Mining