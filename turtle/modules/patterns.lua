-- Mining Patterns Module
-- Implements various mining patterns including strip, branch, spiral, quarry, and adaptive mining

local Patterns = {}

-- Dependencies
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local Mining = require("turtle.modules.mining")
local Inventory = require("turtle.modules.inventory")
local Safety = require("turtle.modules.safety")
local CONSTANTS = require("shared.constants")

-- Module state
local initialized = false
local current_pattern = nil
local pattern_state = {}
local pattern_stats = {
    total_blocks = 0,
    ore_blocks = 0,
    efficiency = 0,
    fuel_used = 0,
    time_started = 0
}

-- Pattern types
local PATTERN_TYPES = {
    STRIP = "strip",
    BRANCH = "branch",
    SPIRAL = "spiral",
    QUARRY = "quarry",
    TUNNEL_3X3 = "tunnel_3x3",
    ADAPTIVE = "adaptive"
}

-- Initialize the module
function Patterns.init()
    if initialized then
        return true, "Already initialized"
    end
    
    Core.debug("Initializing Patterns module")
    
    -- Load saved pattern state
    pattern_state = State.get("pattern_state", {})
    pattern_stats = State.get("pattern_stats", pattern_stats)
    
    initialized = true
    Core.info("Patterns module initialized")
    Core.emit("patterns_initialized")
    
    return true
end

-- Helper function to save pattern state
local function savePatternState()
    State.set("pattern_state", pattern_state)
    State.set("pattern_stats", pattern_stats)
    State.save()
end

-- Helper function to update pattern statistics
local function updateStats(blocks_mined, ores_found, fuel_used)
    pattern_stats.total_blocks = pattern_stats.total_blocks + (blocks_mined or 0)
    pattern_stats.ore_blocks = pattern_stats.ore_blocks + (ores_found or 0)
    pattern_stats.fuel_used = pattern_stats.fuel_used + (fuel_used or 0)
    
    if pattern_stats.total_blocks > 0 then
        pattern_stats.efficiency = (pattern_stats.ore_blocks / pattern_stats.total_blocks) * 100
    end
    
    savePatternState()
end

-- Helper function to place torch
local function placeTorch()
    local torch_slot = Inventory.findItem("minecraft:torch")
    if torch_slot then
        local prev_slot = turtle.getSelectedSlot()
        turtle.select(torch_slot)
        
        -- Try to place torch (try down first, then walls)
        local placed = false
        if not turtle.detectDown() then
            placed = turtle.placeDown()
        else
            -- Try walls
            for i = 1, 4 do
                if not placed and not turtle.detect() then
                    placed = turtle.place()
                end
                if not placed then
                    Navigation.turnRight()
                end
            end
        end
        
        turtle.select(prev_slot)
        return placed
    end
    return false
end

-- Strip Mining Pattern
-- Creates parallel tunnels with configurable spacing
function Patterns.stripMine(options)
    options = options or {}
    local length = options.length or 50
    local spacing = options.spacing or 3
    local strips = options.strips or 5
    local torch_interval = options.torch_interval or 8
    local return_home = options.return_home ~= false
    
    Core.info("Starting strip mining pattern")
    pattern_stats.time_started = os.epoch("utc")
    
    -- Save starting position
    local start_pos = Navigation.getPosition()
    local fuel_start = turtle.getFuelLevel()
    
    -- Main strip mining loop
    for strip = 1, strips do
        Core.info(string.format("Mining strip %d of %d", strip, strips))
        
        -- Mine forward for the specified length
        for block = 1, length do
            -- Safety check
            local safe, reason = Safety.preMiningCheck("forward")
            if not safe then
                Core.warn("Strip mining stopped: " .. reason)
                break
            end
            
            -- Mine forward
            if not Mining.digMove("forward") then
                Core.warn("Cannot continue strip mining - blocked at block " .. block)
                break
            end
            
            -- Check for ores on sides and above/below
            local ores_found = 0
            
            -- Check up
            local success, data = Mining.inspect("up")
            if success and data.is_ore then
                Mining.dig("up")
                ores_found = ores_found + 1
            end
            
            -- Check down
            success, data = Mining.inspect("down")
            if success and data.is_ore then
                Mining.dig("down")
                ores_found = ores_found + 1
            end
            
            -- Check sides
            Navigation.turnLeft()
            success, data = Mining.inspect("forward")
            if success and data.is_ore then
                Mining.mineVein(16)  -- Limited vein mining
                ores_found = ores_found + 1
            end
            
            Navigation.turnRight()
            Navigation.turnRight()
            success, data = Mining.inspect("forward")
            if success and data.is_ore then
                Mining.mineVein(16)
                ores_found = ores_found + 1
            end
            
            Navigation.turnLeft()  -- Face forward again
            
            -- Place torch if needed
            if block % torch_interval == 0 then
                placeTorch()
            end
            
            -- Update stats
            updateStats(1, ores_found, 1)
            
            -- Save progress periodically
            if block % 10 == 0 then
                pattern_state.strip_progress = {
                    strip = strip,
                    block = block,
                    position = Navigation.getPosition()
                }
                savePatternState()
            end
        end
        
        -- Return to start of strip
        Navigation.turnRight()
        Navigation.turnRight()
        for i = 1, length do
            Navigation.forward()
        end
        Navigation.turnLeft()
        Navigation.turnLeft()
        
        -- Move to next strip position (unless last strip)
        if strip < strips then
            -- Move to the side for spacing
            Navigation.turnRight()
            for i = 1, spacing + 1 do
                if not Mining.digMove("forward") then
                    Core.warn("Cannot reach next strip position")
                    break
                end
            end
            Navigation.turnLeft()
        end
    end
    
    -- Return to starting position if requested
    if return_home then
        Core.info("Returning to starting position")
        Navigation.moveTo(start_pos)
    end
    
    -- Calculate fuel used
    local fuel_end = turtle.getFuelLevel()
    if fuel_start ~= "unlimited" and fuel_end ~= "unlimited" then
        updateStats(0, 0, fuel_start - fuel_end)
    end
    
    Core.info("Strip mining pattern complete")
    Core.emit("pattern_complete", {
        pattern = PATTERN_TYPES.STRIP,
        stats = pattern_stats
    })
    
    return true
end

-- Branch Mining Pattern
-- Creates a main tunnel with branches extending from both sides
function Patterns.branchMine(options)
    options = options or {}
    local main_length = options.main_length or 100
    local branch_length = options.branch_length or 20
    local branch_spacing = options.branch_spacing or 5
    local torch_interval = options.torch_interval or 8
    local return_home = options.return_home ~= false
    
    Core.info("Starting branch mining pattern")
    pattern_stats.time_started = os.epoch("utc")
    
    -- Save starting position
    local start_pos = Navigation.getPosition()
    local fuel_start = turtle.getFuelLevel()
    
    -- Mine main tunnel
    Core.info("Mining main tunnel")
    local main_blocks = 0
    
    for block = 1, main_length do
        -- Safety check
        local safe, reason = Safety.preMiningCheck("forward")
        if not safe then
            Core.warn("Branch mining stopped: " .. reason)
            break
        end
        
        -- Mine 3-high tunnel for main corridor
        Mining.dig("up")
        Mining.dig("down") 
        if not Mining.digMove("forward") then
            Core.warn("Cannot continue main tunnel - blocked at block " .. block)
            break
        end
        
        main_blocks = main_blocks + 1
        
        -- Place torch in main tunnel
        if block % torch_interval == 0 then
            placeTorch()
        end
        
        -- Create branches at intervals
        if block % branch_spacing == 0 and block < main_length - 5 then
            Core.info(string.format("Creating branches at block %d", block))
            
            -- Left branch
            Navigation.turnLeft()
            for branch_block = 1, branch_length do
                if not Mining.digMove("forward") then
                    break
                end
                
                -- Check for ores above and below
                local success, data = Mining.inspect("up")
                if success and data.is_ore then
                    Mining.mineVein(16)
                end
                
                success, data = Mining.inspect("down")
                if success and data.is_ore then
                    Mining.mineVein(16)
                end
                
                -- Place torch in branch
                if branch_block % torch_interval == 0 then
                    placeTorch()
                end
                
                updateStats(1, 0, 1)
            end
            
            -- Return to main tunnel
            Navigation.turnRight()
            Navigation.turnRight()
            for i = 1, branch_length do
                Navigation.forward()
            end
            
            -- Right branch
            for branch_block = 1, branch_length do
                if not Mining.digMove("forward") then
                    break
                end
                
                -- Check for ores
                local success, data = Mining.inspect("up")
                if success and data.is_ore then
                    Mining.mineVein(16)
                end
                
                success, data = Mining.inspect("down")
                if success and data.is_ore then
                    Mining.mineVein(16)
                end
                
                -- Place torch
                if branch_block % torch_interval == 0 then
                    placeTorch()
                end
                
                updateStats(1, 0, 1)
            end
            
            -- Return to main tunnel
            Navigation.turnRight()
            Navigation.turnRight()
            for i = 1, branch_length do
                Navigation.forward()
            end
            Navigation.turnLeft()
        end
        
        -- Update stats
        updateStats(1, 0, 1)
        
        -- Save progress
        if block % 10 == 0 then
            pattern_state.branch_progress = {
                main_block = block,
                position = Navigation.getPosition()
            }
            savePatternState()
        end
    end
    
    -- Return to starting position
    if return_home then
        Core.info("Returning to starting position")
        Navigation.moveTo(start_pos)
    end
    
    -- Calculate fuel used
    local fuel_end = turtle.getFuelLevel()
    if fuel_start ~= "unlimited" and fuel_end ~= "unlimited" then
        updateStats(0, 0, fuel_start - fuel_end)
    end
    
    Core.info("Branch mining pattern complete")
    Core.emit("pattern_complete", {
        pattern = PATTERN_TYPES.BRANCH,
        stats = pattern_stats
    })
    
    return true
end

-- Spiral Mining Pattern
-- Mines in an expanding spiral pattern
function Patterns.spiralMine(options)
    options = options or {}
    local max_radius = options.max_radius or 32
    local layers = options.layers or 1
    local torch_interval = options.torch_interval or 8
    local return_home = options.return_home ~= false
    
    Core.info("Starting spiral mining pattern")
    pattern_stats.time_started = os.epoch("utc")
    
    -- Save starting position
    local start_pos = Navigation.getPosition()
    local fuel_start = turtle.getFuelLevel()
    
    -- Mine each layer
    for layer = 1, layers do
        Core.info(string.format("Mining layer %d of %d", layer, layers))
        
        -- Move to layer if not first
        if layer > 1 then
            for i = 1, 3 do  -- 3 blocks between layers
                if not Mining.digMove("down") then
                    Core.warn("Cannot reach next layer")
                    return false
                end
            end
        end
        
        -- Spiral outward
        local steps = 1
        local torch_counter = 0
        
        while steps <= max_radius * 2 do
            -- Mine two legs of the spiral
            for leg = 1, 2 do
                for step = 1, steps do
                    -- Safety check
                    local safe, reason = Safety.preMiningCheck("forward")
                    if not safe then
                        Core.warn("Spiral mining stopped: " .. reason)
                        break
                    end
                    
                    -- Mine and move
                    if not Mining.digMove("forward") then
                        Core.warn("Spiral blocked")
                        break
                    end
                    
                    -- Check for ores above and below
                    local success, data = Mining.inspect("up")
                    if success and data.is_ore then
                        Mining.dig("up")
                    end
                    
                    success, data = Mining.inspect("down")
                    if success and data.is_ore then
                        Mining.dig("down")
                    end
                    
                    -- Place torch
                    torch_counter = torch_counter + 1
                    if torch_counter % torch_interval == 0 then
                        placeTorch()
                    end
                    
                    updateStats(1, 0, 1)
                end
                
                -- Turn for next leg
                Navigation.turnRight()
            end
            
            -- Increase step size for next iteration
            steps = steps + 1
            
            -- Save progress
            pattern_state.spiral_progress = {
                layer = layer,
                steps = steps,
                position = Navigation.getPosition()
            }
            savePatternState()
        end
    end
    
    -- Return to starting position
    if return_home then
        Core.info("Returning to starting position")
        Navigation.moveTo(start_pos)
    end
    
    -- Calculate fuel used
    local fuel_end = turtle.getFuelLevel()
    if fuel_start ~= "unlimited" and fuel_end ~= "unlimited" then
        updateStats(0, 0, fuel_start - fuel_end)
    end
    
    Core.info("Spiral mining pattern complete")
    Core.emit("pattern_complete", {
        pattern = PATTERN_TYPES.SPIRAL,
        stats = pattern_stats
    })
    
    return true
end

-- Quarry Pattern
-- Excavates a rectangular area layer by layer
function Patterns.quarry(options)
    options = options or {}
    local width = options.width or 16
    local length = options.length or 16
    local depth = options.depth or nil  -- nil means mine to bedrock
    local return_home = options.return_home ~= false
    
    Core.info(string.format("Starting quarry pattern (%dx%d)", width, length))
    pattern_stats.time_started = os.epoch("utc")
    
    -- Save starting position
    local start_pos = Navigation.getPosition()
    local fuel_start = turtle.getFuelLevel()
    
    -- Check structural integrity for large excavations
    local integrity = Safety.checkStructuralIntegrity({
        width = width,
        height = 3,
        depth = length
    })
    
    if not integrity.safe then
        Core.warn("Large excavation may be unsafe - planning support pillars")
        -- Plan support pillars
        local pillars = Safety.planSupportPillars({
            x1 = start_pos.x,
            y = start_pos.y,
            z1 = start_pos.z,
            x2 = start_pos.x + width,
            z2 = start_pos.z + length
        })
        pattern_state.quarry_pillars = pillars
    end
    
    -- Mine layers
    local current_depth = 0
    local hit_bedrock = false
    
    while not hit_bedrock and (not depth or current_depth < depth) do
        Core.info(string.format("Mining layer at depth %d", current_depth))
        
        -- Mine the layer in a snake pattern
        for row = 1, length do
            -- Determine direction based on row (snake pattern)
            local forward = (row % 2 == 1)
            
            for col = 1, width do
                -- Check if this is a pillar location
                local is_pillar = false
                if pattern_state.quarry_pillars then
                    local current_x = start_pos.x + (forward and col - 1 or width - col)
                    local current_z = start_pos.z + row - 1
                    
                    for _, pillar in ipairs(pattern_state.quarry_pillars) do
                        if pillar.x == current_x and pillar.z == current_z then
                            is_pillar = true
                            break
                        end
                    end
                end
                
                -- Skip if pillar location
                if not is_pillar then
                    -- Mine down
                    local success, data = Mining.inspect("down")
                    if success and data.name == "minecraft:bedrock" then
                        hit_bedrock = true
                        Core.info("Hit bedrock at depth " .. current_depth)
                        break
                    end
                    
                    Mining.dig("down")
                end
                
                -- Move to next position (except last column)
                if col < width then
                    if not Mining.digMove("forward") then
                        Core.warn("Quarry blocked")
                        return false
                    end
                end
                
                updateStats(1, 0, 1)
            end
            
            if hit_bedrock then
                break
            end
            
            -- Move to next row (except last row)
            if row < length then
                if forward then
                    Navigation.turnRight()
                    if not Mining.digMove("forward") then
                        return false
                    end
                    Navigation.turnRight()
                else
                    Navigation.turnLeft()
                    if not Mining.digMove("forward") then
                        return false
                    end
                    Navigation.turnLeft()
                end
            end
        end
        
        if hit_bedrock then
            break
        end
        
        -- Move down to next layer
        if not depth or current_depth < depth - 1 then
            if not Navigation.down() then
                Core.warn("Cannot move to next layer")
                break
            end
            current_depth = current_depth + 1
            
            -- Return to starting corner for next layer
            local facing_adjustment = (length % 2 == 0) and 2 or 0
            for i = 1, facing_adjustment do
                Navigation.turnRight()
            end
            
            for i = 1, width - 1 do
                Navigation.forward()
            end
            Navigation.turnRight()
            for i = 1, length - 1 do
                Navigation.forward()
            end
            Navigation.turnRight()
        end
        
        -- Save progress
        pattern_state.quarry_progress = {
            depth = current_depth,
            position = Navigation.getPosition()
        }
        savePatternState()
    end
    
    -- Return to surface and starting position
    if return_home then
        Core.info("Returning to starting position")
        -- First go up
        for i = 1, current_depth do
            Navigation.up()
        end
        -- Then return to start
        Navigation.moveTo(start_pos)
    end
    
    -- Calculate fuel used
    local fuel_end = turtle.getFuelLevel()
    if fuel_start ~= "unlimited" and fuel_end ~= "unlimited" then
        updateStats(0, 0, fuel_start - fuel_end)
    end
    
    Core.info("Quarry pattern complete")
    Core.emit("pattern_complete", {
        pattern = PATTERN_TYPES.QUARRY,
        stats = pattern_stats
    })
    
    return true
end

-- Enhanced 3x3 Tunnel Mining
-- Creates a 3x3 tunnel with proper support
function Patterns.tunnel3x3(options)
    options = options or {}
    local length = options.length or 50
    local torch_interval = options.torch_interval or 8
    local support_interval = options.support_interval or 16
    local return_home = options.return_home ~= false
    
    Core.info("Starting 3x3 tunnel pattern")
    pattern_stats.time_started = os.epoch("utc")
    
    -- Save starting position
    local start_pos = Navigation.getPosition()
    local fuel_start = turtle.getFuelLevel()
    
    -- Mine tunnel
    for block = 1, length do
        -- Mine 3x3 cross-section
        -- Start at bottom left
        Mining.dig("down")
        Navigation.down()
        Mining.dig("forward")
        Navigation.forward()
        
        -- Mine bottom row
        Navigation.turnRight()
        Mining.dig("forward")
        Navigation.forward()
        Mining.dig("forward")
        Navigation.forward()
        
        -- Mine middle row
        Navigation.up()
        Navigation.turnRight()
        Navigation.turnRight()
        Mining.dig("forward")
        Navigation.forward()
        Mining.dig("forward")
        Navigation.forward()
        
        -- Mine top row
        Navigation.up()
        Navigation.turnRight()
        Navigation.turnRight()
        Mining.dig("forward")
        Navigation.forward()
        Mining.dig("forward")
        Navigation.forward()
        
        -- Return to center position
        Navigation.down()
        Navigation.turnLeft()
        Navigation.forward()
        Navigation.turnLeft()
        
        -- Place torch
        if block % torch_interval == 0 then
            placeTorch()
        end
        
        -- Place support if needed
        if block % support_interval == 0 then
            Core.info("Placing tunnel support")
            -- This would place support beams/pillars
            -- Implementation depends on available materials
        end
        
        updateStats(9, 0, 1)  -- 9 blocks per cross-section
        
        -- Save progress
        if block % 10 == 0 then
            pattern_state.tunnel_progress = {
                block = block,
                position = Navigation.getPosition()
            }
            savePatternState()
        end
    end
    
    -- Return to starting position
    if return_home then
        Core.info("Returning to starting position")
        Navigation.moveTo(start_pos)
    end
    
    -- Calculate fuel used
    local fuel_end = turtle.getFuelLevel()
    if fuel_start ~= "unlimited" and fuel_end ~= "unlimited" then
        updateStats(0, 0, fuel_start - fuel_end)
    end
    
    Core.info("3x3 tunnel pattern complete")
    Core.emit("pattern_complete", {
        pattern = PATTERN_TYPES.TUNNEL_3X3,
        stats = pattern_stats
    })
    
    return true
end

-- Adaptive Mining Pattern
-- Dynamically adjusts pattern based on ore density and type
function Patterns.adaptiveMine(options)
    options = options or {}
    local target_ore = options.target_ore or nil  -- nil means any ore
    local max_blocks = options.max_blocks or 1000
    local base_pattern = options.base_pattern or PATTERN_TYPES.BRANCH
    local return_home = options.return_home ~= false
    
    Core.info("Starting adaptive mining pattern")
    pattern_stats.time_started = os.epoch("utc")
    
    -- Save starting position
    local start_pos = Navigation.getPosition()
    local fuel_start = turtle.getFuelLevel()
    
    -- Adaptive state
    local ore_density_history = {}
    local blocks_since_ore = 0
    local current_pattern = base_pattern
    local pattern_switches = 0
    
    -- Main adaptive loop
    local blocks_mined = 0
    while blocks_mined < max_blocks do
        -- Scan surroundings for ore density
        local ore_count = 0
        local scan_positions = {
            {dir = "forward"}, {dir = "up"}, {dir = "down"}
        }
        
        -- Quick scan
        for _, scan in ipairs(scan_positions) do
            local success, data = Mining.inspect(scan.dir)
            if success and data.is_ore then
                if not target_ore or data.ore_type == target_ore then
                    ore_count = ore_count + 1
                end
            end
        end
        
        -- Turn and scan sides
        Navigation.turnLeft()
        local success, data = Mining.inspect("forward")
        if success and data.is_ore then
            if not target_ore or data.ore_type == target_ore then
                ore_count = ore_count + 1
            end
        end
        
        Navigation.turnRight()
        Navigation.turnRight()
        success, data = Mining.inspect("forward")
        if success and data.is_ore then
            if not target_ore or data.ore_type == target_ore then
                ore_count = ore_count + 1
            end
        end
        
        Navigation.turnLeft()  -- Face forward again
        
        -- Update density history
        table.insert(ore_density_history, ore_count)
        if #ore_density_history > 10 then
            table.remove(ore_density_history, 1)
        end
        
        -- Calculate average density
        local avg_density = 0
        for _, density in ipairs(ore_density_history) do
            avg_density = avg_density + density
        end
        avg_density = avg_density / #ore_density_history
        
        -- Adapt pattern based on density
        if avg_density > 2 then
            -- High density - switch to thorough mining
            if current_pattern ~= PATTERN_TYPES.SPIRAL then
                Core.info("High ore density detected - switching to spiral pattern")
                current_pattern = PATTERN_TYPES.SPIRAL
                pattern_switches = pattern_switches + 1
            end
            
            -- Mine thoroughly in area
            Mining.mineVein(32)
            blocks_mined = blocks_mined + 32
            
        elseif avg_density > 0.5 then
            -- Medium density - branch pattern
            if current_pattern ~= PATTERN_TYPES.BRANCH then
                Core.info("Medium ore density - using branch pattern")
                current_pattern = PATTERN_TYPES.BRANCH
                pattern_switches = pattern_switches + 1
            end
            
            -- Mine a short branch
            for i = 1, 10 do
                if Mining.digMove("forward") then
                    blocks_mined = blocks_mined + 1
                else
                    break
                end
            end
            
        else
            -- Low density - move quickly
            if current_pattern ~= PATTERN_TYPES.STRIP then
                Core.info("Low ore density - using strip pattern")
                current_pattern = PATTERN_TYPES.STRIP
                pattern_switches = pattern_switches + 1
            end
            
            -- Move forward quickly
            for i = 1, 5 do
                if Mining.digMove("forward") then
                    blocks_mined = blocks_mined + 1
                else
                    break
                end
            end
        end
        
        -- Update blocks since ore
        if ore_count > 0 then
            blocks_since_ore = 0
        else
            blocks_since_ore = blocks_since_ore + 1
        end
        
        -- If no ore for too long, change direction
        if blocks_since_ore > 20 then
            Core.info("No ore found recently - changing direction")
            Navigation.turnRight()
            blocks_since_ore = 0
        end
        
        -- Update stats
        updateStats(1, ore_count, 1)
        
        -- Save progress
        if blocks_mined % 50 == 0 then
            pattern_state.adaptive_progress = {
                blocks = blocks_mined,
                pattern = current_pattern,
                density = avg_density,
                position = Navigation.getPosition()
            }
            savePatternState()
        end
        
        -- Check if we should stop
        if target_ore and ore_count > 0 then
            local mined_stats = Mining.getStats()
            if mined_stats.by_type[target_ore] and 
               mined_stats.by_type[target_ore] >= (options.target_amount or 64) then
                Core.info("Target ore amount reached")
                break
            end
        end
    end
    
    -- Return to starting position
    if return_home then
        Core.info("Returning to starting position")
        Navigation.moveTo(start_pos)
    end
    
    -- Calculate fuel used
    local fuel_end = turtle.getFuelLevel()
    if fuel_start ~= "unlimited" and fuel_end ~= "unlimited" then
        updateStats(0, 0, fuel_start - fuel_end)
    end
    
    Core.info("Adaptive mining pattern complete")
    Core.emit("pattern_complete", {
        pattern = PATTERN_TYPES.ADAPTIVE,
        stats = pattern_stats,
        pattern_switches = pattern_switches
    })
    
    return true
end

-- Execute a mining pattern by name
function Patterns.execute(pattern_type, options)
    if not initialized then
        return false, "Patterns module not initialized"
    end
    
    -- Reset stats for new pattern
    pattern_stats = {
        total_blocks = 0,
        ore_blocks = 0,
        efficiency = 0,
        fuel_used = 0,
        time_started = os.epoch("utc")
    }
    
    current_pattern = pattern_type
    
    -- Execute the appropriate pattern
    if pattern_type == PATTERN_TYPES.STRIP then
        return Patterns.stripMine(options)
    elseif pattern_type == PATTERN_TYPES.BRANCH then
        return Patterns.branchMine(options)
    elseif pattern_type == PATTERN_TYPES.SPIRAL then
        return Patterns.spiralMine(options)
    elseif pattern_type == PATTERN_TYPES.QUARRY then
        return Patterns.quarry(options)
    elseif pattern_type == PATTERN_TYPES.TUNNEL_3X3 then
        return Patterns.tunnel3x3(options)
    elseif pattern_type == PATTERN_TYPES.ADAPTIVE then
        return Patterns.adaptiveMine(options)
    else
        return false, "Unknown pattern type: " .. tostring(pattern_type)
    end
end

-- Get available patterns
function Patterns.getAvailablePatterns()
    return {
        {
            type = PATTERN_TYPES.STRIP,
            name = "Strip Mining",
            description = "Parallel tunnels with configurable spacing"
        },
        {
            type = PATTERN_TYPES.BRANCH,
            name = "Branch Mining",
            description = "Main tunnel with side branches"
        },
        {
            type = PATTERN_TYPES.SPIRAL,
            name = "Spiral Mining",
            description = "Expanding spiral pattern"
        },
        {
            type = PATTERN_TYPES.QUARRY,
            name = "Quarry",
            description = "Rectangular excavation layer by layer"
        },
        {
            type = PATTERN_TYPES.TUNNEL_3X3,
            name = "3x3 Tunnel",
            description = "Large tunnel for transportation"
        },
        {
            type = PATTERN_TYPES.ADAPTIVE,
            name = "Adaptive Mining",
            description = "Dynamically adjusts based on ore density"
        }
    }
end

-- Get current pattern statistics
function Patterns.getStats()
    local runtime = (os.epoch("utc") - pattern_stats.time_started) / 1000
    return {
        current_pattern = current_pattern,
        total_blocks = pattern_stats.total_blocks,
        ore_blocks = pattern_stats.ore_blocks,
        efficiency = pattern_stats.efficiency,
        fuel_used = pattern_stats.fuel_used,
        runtime_seconds = runtime,
        blocks_per_minute = runtime > 0 and (pattern_stats.total_blocks / runtime * 60) or 0
    }
end

-- Resume interrupted pattern
function Patterns.resume()
    if not pattern_state or not pattern_state.current_pattern then
        return false, "No pattern to resume"
    end
    
    Core.info("Resuming " .. pattern_state.current_pattern .. " pattern")
    
    -- Load pattern-specific state and continue
    -- This would need pattern-specific resume logic
    
    return false, "Pattern resume not yet implemented"
end

-- Stop current pattern
function Patterns.stop()
    if current_pattern then
        Core.info("Stopping " .. current_pattern .. " pattern")
        current_pattern = nil
        savePatternState()
        return true
    end
    return false, "No pattern running"
end

-- Shutdown function
function Patterns.shutdown()
    if not initialized then
        return true
    end
    
    Core.debug("Shutting down Patterns module")
    
    -- Save final state
    savePatternState()
    
    initialized = false
    return true
end

return Patterns