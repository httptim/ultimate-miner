-- Safety Module
-- Handles hazard detection, emergency protocols, and turtle preservation

local Safety = {}

-- Dependencies
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local Inventory = require("turtle.modules.inventory")
local CONSTANTS = require("shared.constants")

-- Module state
local initialized = false
local safety_status = {
    last_check = 0,
    hazards_detected = 0,
    emergency_stops = 0,
    close_calls = 0
}

-- Hazard types
local HAZARD_TYPES = {
    LAVA = "lava",
    WATER = "water",
    VOID = "void",
    LOW_FUEL = "low_fuel",
    NO_FUEL = "no_fuel",
    FULL_INVENTORY = "full_inventory",
    FALLING_BLOCK = "falling_block",
    MOB = "mob",
    EXPLOSION = "explosion",
    BOUNDARY = "boundary"
}

-- Dangerous blocks/fluids
local DANGEROUS_BLOCKS = {
    -- Lava
    ["minecraft:lava"] = {hazard = HAZARD_TYPES.LAVA, danger_level = 10},
    ["minecraft:flowing_lava"] = {hazard = HAZARD_TYPES.LAVA, danger_level = 10},
    ["minecraft:lava_cauldron"] = {hazard = HAZARD_TYPES.LAVA, danger_level = 8},
    
    -- Water (less dangerous but can push)
    ["minecraft:water"] = {hazard = HAZARD_TYPES.WATER, danger_level = 3},
    ["minecraft:flowing_water"] = {hazard = HAZARD_TYPES.WATER, danger_level = 3},
    ["minecraft:water_cauldron"] = {hazard = HAZARD_TYPES.WATER, danger_level = 2},
    
    -- Fire
    ["minecraft:fire"] = {hazard = HAZARD_TYPES.LAVA, danger_level = 7},
    ["minecraft:soul_fire"] = {hazard = HAZARD_TYPES.LAVA, danger_level = 7},
    
    -- Other dangers
    ["minecraft:magma_block"] = {hazard = HAZARD_TYPES.LAVA, danger_level = 5},
    ["minecraft:cactus"] = {hazard = HAZARD_TYPES.MOB, danger_level = 2},
    ["minecraft:sweet_berry_bush"] = {hazard = HAZARD_TYPES.MOB, danger_level = 1},
    ["minecraft:wither_rose"] = {hazard = HAZARD_TYPES.MOB, danger_level = 3}
}

-- Safe blocks for emergency placement
local SAFE_BLOCKS = {
    "minecraft:cobblestone",
    "minecraft:stone",
    "minecraft:dirt",
    "minecraft:netherrack",
    "minecraft:cobbled_deepslate"
}

-- Initialize the module
function Safety.init()
    if initialized then
        return true, "Already initialized"
    end
    
    Core.debug("Initializing Safety module")
    
    -- Load saved safety status
    safety_status = State.get("safety_status", safety_status)
    
    -- Register event handlers
    Core.on("fuel_critical", function(data)
        Safety.handleCriticalFuel(data.fuel_level)
    end)
    
    Core.on("inventory_full", function()
        Safety.handleFullInventory()
    end)
    
    initialized = true
    Core.info("Safety module initialized")
    Core.emit("safety_initialized")
    
    return true
end

-- Check for hazards in a direction
function Safety.checkHazard(direction)
    direction = direction or "forward"
    
    -- Get inspect function
    local inspect_func
    if direction == "up" then
        inspect_func = turtle.inspectUp
    elseif direction == "down" then
        inspect_func = turtle.inspectDown
    else
        inspect_func = turtle.inspect
    end
    
    -- Inspect the block
    local success, block_data = inspect_func()
    if not success then
        -- No block, check for void below
        if direction == "down" then
            return {
                safe = false,
                hazard = HAZARD_TYPES.VOID,
                danger_level = 8,
                message = "Void detected below"
            }
        end
        return {safe = true}
    end
    
    -- Check if it's a dangerous block
    local danger = DANGEROUS_BLOCKS[block_data.name]
    if danger then
        safety_status.hazards_detected = safety_status.hazards_detected + 1
        State.set("safety_status", safety_status)
        
        return {
            safe = false,
            hazard = danger.hazard,
            danger_level = danger.danger_level,
            block_name = block_data.name,
            message = "Hazard detected: " .. block_data.name
        }
    end
    
    return {safe = true}
end

-- Comprehensive safety check
function Safety.performSafetyCheck()
    local hazards = {}
    local safe = true
    
    -- Check fuel
    local fuel_level = turtle.getFuelLevel()
    if fuel_level ~= "unlimited" then
        local fuel_reserve = Config.get("fuel_reserve", CONSTANTS.DEFAULTS.FUEL_RESERVE)
        local emergency_fuel = Config.get("emergency_fuel", CONSTANTS.DEFAULTS.EMERGENCY_FUEL)
        
        if fuel_level <= emergency_fuel then
            safe = false
            table.insert(hazards, {
                hazard = HAZARD_TYPES.NO_FUEL,
                danger_level = 10,
                message = "Critical fuel level: " .. fuel_level
            })
        elseif fuel_level <= fuel_reserve then
            safe = false
            table.insert(hazards, {
                hazard = HAZARD_TYPES.LOW_FUEL,
                danger_level = 6,
                message = "Low fuel level: " .. fuel_level
            })
        end
    end
    
    -- Check inventory
    if Inventory.isFull() then
        table.insert(hazards, {
            hazard = HAZARD_TYPES.FULL_INVENTORY,
            danger_level = 4,
            message = "Inventory is full"
        })
    end
    
    -- Check surroundings
    local directions = {"forward", "up", "down"}
    for _, dir in ipairs(directions) do
        local hazard = Safety.checkHazard(dir)
        if not hazard.safe then
            safe = false
            table.insert(hazards, hazard)
        end
    end
    
    -- Check boundaries
    local pos = Navigation.getPosition()
    local safety_radius = Config.get("safety_radius", CONSTANTS.DEFAULTS.SAFETY_RADIUS)
    local home = Navigation.getHome()
    
    if home and safety_radius > 0 then
        local distance = math.abs(pos.x - home.x) + math.abs(pos.y - home.y) + math.abs(pos.z - home.z)
        if distance > safety_radius then
            safe = false
            table.insert(hazards, {
                hazard = HAZARD_TYPES.BOUNDARY,
                danger_level = 5,
                message = "Outside safety boundary"
            })
        end
    end
    
    safety_status.last_check = os.epoch("utc")
    State.set("safety_status", safety_status)
    
    return safe, hazards
end

-- Handle lava hazard
function Safety.handleLavaHazard(direction)
    Core.warn("Lava hazard detected " .. direction)
    
    -- Emit alert
    Core.emit("hazard_detected", {
        type = HAZARD_TYPES.LAVA,
        direction = direction
    })
    
    -- Try to place a block to contain it
    if direction ~= "down" then -- Don't place blocks below us
        local safe_block = Inventory.findItem(SAFE_BLOCKS[1])
        if safe_block then
            turtle.select(safe_block)
            
            local place_func
            if direction == "up" then
                place_func = turtle.placeUp
            elseif direction == "forward" then
                place_func = turtle.place
            end
            
            if place_func and place_func() then
                Core.info("Placed block to contain lava")
                safety_status.close_calls = safety_status.close_calls + 1
                State.set("safety_status", safety_status)
                return true
            end
        end
    end
    
    -- Back away if possible
    if Navigation.back() then
        Core.info("Backed away from lava")
        return true
    end
    
    return false
end

-- Handle water hazard
function Safety.handleWaterHazard(direction)
    Core.debug("Water detected " .. direction)
    
    -- Water is less dangerous, but can push turtle
    -- Try to place a block if moving through
    if Config.get("block_water", true) then
        local safe_block = Inventory.findItem(SAFE_BLOCKS[1])
        if safe_block then
            turtle.select(safe_block)
            
            local place_func
            if direction == "up" then
                place_func = turtle.placeUp
            elseif direction == "down" then
                place_func = turtle.placeDown
            else
                place_func = turtle.place
            end
            
            if place_func() then
                Core.debug("Placed block to stop water flow")
                return true
            end
        end
    end
    
    return true -- Water is generally safe to continue
end

-- Handle critical fuel
function Safety.handleCriticalFuel(fuel_level)
    Core.error("CRITICAL: Fuel level at " .. tostring(fuel_level))
    
    -- Try to refuel immediately
    local refueled = Inventory.consumeFuel()
    if refueled then
        Core.info("Emergency refuel successful")
        return true
    end
    
    -- Emit emergency
    Core.emit("emergency", {
        type = "critical_fuel",
        fuel_level = fuel_level
    })
    
    -- Try to return home
    local home = Navigation.getHome()
    if home then
        Core.warn("Attempting emergency return to home")
        local success = Navigation.returnHome()
        if success then
            safety_status.close_calls = safety_status.close_calls + 1
            State.set("safety_status", safety_status)
        end
        return success
    end
    
    return false
end

-- Handle full inventory
function Safety.handleFullInventory()
    Core.warn("Inventory full - attempting to make space")
    
    -- First try to compact
    Inventory.compact()
    
    -- If still full, try to drop junk
    if Inventory.isFull() then
        local made_space = Inventory.makeSpace(4, {"tool", "valuable", "ore", "fuel"})
        if made_space then
            Core.info("Made space by dropping items")
            return true
        end
    end
    
    -- If still full, might need to return to storage
    if Inventory.isFull() then
        Core.emit("need_storage", {
            urgency = "high"
        })
        return false
    end
    
    return true
end

-- Emergency stop
function Safety.emergencyStop(reason)
    Core.error("EMERGENCY STOP: " .. tostring(reason))
    
    safety_status.emergency_stops = safety_status.emergency_stops + 1
    State.set("safety_status", safety_status)
    
    -- Stop all movement
    Navigation.emergencyStop()
    
    -- Save state immediately
    State.save()
    
    -- Emit emergency event
    Core.emit("emergency_stop", {
        reason = reason,
        position = Navigation.getPosition(),
        fuel = turtle.getFuelLevel(),
        timestamp = os.epoch("utc")
    })
    
    return true
end

-- Check if safe to proceed in direction
function Safety.isSafeToMove(direction)
    -- Check basic hazards
    local hazard = Safety.checkHazard(direction)
    if not hazard.safe then
        -- Handle specific hazards
        if hazard.hazard == HAZARD_TYPES.LAVA then
            Safety.handleLavaHazard(direction)
            return false, "Lava hazard"
        elseif hazard.hazard == HAZARD_TYPES.WATER then
            -- Water is usually okay, just log it
            Core.debug("Water in path")
        elseif hazard.hazard == HAZARD_TYPES.VOID and direction == "down" then
            return false, "Void below"
        end
    end
    
    -- Check fuel for movement
    local fuel = turtle.getFuelLevel()
    if fuel ~= "unlimited" then
        local min_fuel = Config.get("emergency_fuel", CONSTANTS.DEFAULTS.EMERGENCY_FUEL)
        if fuel <= min_fuel then
            return false, "Insufficient fuel"
        end
    end
    
    -- Check if we're within boundaries
    local pos = Navigation.getPosition()
    local safety_radius = Config.get("safety_radius", CONSTANTS.DEFAULTS.SAFETY_RADIUS)
    local home = Navigation.getHome()
    
    if home and safety_radius > 0 then
        -- Calculate where we would be after movement
        local new_pos = {x = pos.x, y = pos.y, z = pos.z}
        
        if direction == "forward" then
            -- Adjust based on facing
            if pos.facing == CONSTANTS.DIRECTIONS.NORTH then
                new_pos.z = new_pos.z - 1
            elseif pos.facing == CONSTANTS.DIRECTIONS.SOUTH then
                new_pos.z = new_pos.z + 1
            elseif pos.facing == CONSTANTS.DIRECTIONS.EAST then
                new_pos.x = new_pos.x + 1
            elseif pos.facing == CONSTANTS.DIRECTIONS.WEST then
                new_pos.x = new_pos.x - 1
            end
        elseif direction == "up" then
            new_pos.y = new_pos.y + 1
        elseif direction == "down" then
            new_pos.y = new_pos.y - 1
        end
        
        local new_distance = math.abs(new_pos.x - home.x) + math.abs(new_pos.y - home.y) + math.abs(new_pos.z - home.z)
        if new_distance > safety_radius then
            return false, "Would exceed safety boundary"
        end
    end
    
    return true
end

-- Place safety block below
function Safety.ensureFloorBelow()
    -- Check if there's a block below
    local has_block = turtle.detectDown()
    if has_block then
        return true
    end
    
    -- Try to place a safe block
    local safe_block = nil
    for _, block_name in ipairs(SAFE_BLOCKS) do
        safe_block = Inventory.findItem(block_name)
        if safe_block then
            break
        end
    end
    
    if safe_block then
        turtle.select(safe_block)
        if turtle.placeDown() then
            Core.debug("Placed safety floor")
            return true
        end
    end
    
    Core.warn("Unable to ensure floor below")
    return false
end

-- Get safety statistics
function Safety.getStats()
    return {
        hazards_detected = safety_status.hazards_detected,
        emergency_stops = safety_status.emergency_stops,
        close_calls = safety_status.close_calls,
        last_check = safety_status.last_check,
        time_since_check = os.epoch("utc") - safety_status.last_check
    }
end

-- Set safety boundary
function Safety.setSafetyRadius(radius)
    Config.set("safety_radius", radius)
    Core.info("Safety radius set to " .. radius)
    return true
end

-- Check void below (useful for mining)
function Safety.checkVoidBelow(max_depth)
    max_depth = max_depth or 5
    local depth = 0
    
    -- Save current position
    local start_pos = Navigation.getPosition()
    
    -- Check downward
    while depth < max_depth do
        if turtle.detectDown() then
            -- Found solid ground at this depth
            break
        end
        
        -- Try to move down
        if Navigation.down() then
            depth = depth + 1
        else
            -- Can't move down but no block detected - something's wrong
            break
        end
    end
    
    -- Return to start position
    for i = 1, depth do
        Navigation.up()
    end
    
    return depth < max_depth, depth
end

-- Monitor health if available
function Safety.checkHealth()
    -- Note: CC:Tweaked doesn't have direct health access
    -- This is a placeholder for potential peripheral support
    return true, "Health monitoring not available"
end

-- Reset safety statistics
function Safety.resetStats()
    safety_status = {
        last_check = os.epoch("utc"),
        hazards_detected = 0,
        emergency_stops = 0,
        close_calls = 0
    }
    State.set("safety_status", safety_status)
    Core.emit("safety_stats_reset")
    return true
end

-- Shutdown function
function Safety.shutdown()
    if not initialized then
        return true
    end
    
    Core.debug("Shutting down Safety module")
    initialized = false
    
    return true
end

return Safety