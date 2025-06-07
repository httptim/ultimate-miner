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

-- Falling blocks that need support
local FALLING_BLOCKS = {
    "minecraft:sand",
    "minecraft:red_sand",
    "minecraft:gravel",
    "minecraft:white_concrete_powder",
    "minecraft:orange_concrete_powder",
    "minecraft:magenta_concrete_powder",
    "minecraft:light_blue_concrete_powder",
    "minecraft:yellow_concrete_powder",
    "minecraft:lime_concrete_powder",
    "minecraft:pink_concrete_powder",
    "minecraft:gray_concrete_powder",
    "minecraft:light_gray_concrete_powder",
    "minecraft:cyan_concrete_powder",
    "minecraft:purple_concrete_powder",
    "minecraft:blue_concrete_powder",
    "minecraft:brown_concrete_powder",
    "minecraft:green_concrete_powder",
    "minecraft:red_concrete_powder",
    "minecraft:black_concrete_powder",
    "minecraft:dragon_egg",  -- Yes, it falls!
    "minecraft:anvil",
    "minecraft:chipped_anvil",
    "minecraft:damaged_anvil"
}

-- Blocks that can act as temporary supports
local SUPPORT_BLOCKS = {
    "minecraft:torch",
    "minecraft:cobblestone",
    "minecraft:stone",
    "minecraft:dirt"
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

-- Check if block is a falling type
local function isFallingBlock(block_name)
    for _, falling_block in ipairs(FALLING_BLOCKS) do
        if block_name == falling_block then
            return true
        end
    end
    return false
end

-- Detect falling blocks above
function Safety.detectFallingBlockAbove()
    local success, block_data = turtle.inspectUp()
    if success and isFallingBlock(block_data.name) then
        return true, block_data.name
    end
    return false
end

-- Place temporary support for falling blocks
function Safety.placeFallingBlockSupport()
    Core.debug("Placing support for falling blocks above")
    
    -- First check if there's actually a falling block above
    local has_falling, block_name = Safety.detectFallingBlockAbove()
    if not has_falling then
        return true, "No falling block detected"
    end
    
    Core.info("Falling block detected above: " .. block_name)
    
    -- Find a torch first (preferred support)
    local torch_slot = Inventory.findItem("minecraft:torch")
    if torch_slot then
        -- Place torch to the side as temporary support
        turtle.select(torch_slot)
        
        -- Try each direction
        for i = 1, 4 do
            if turtle.place() then
                Core.debug("Placed torch support")
                return true, "Torch support placed"
            end
            Navigation.turnRight()
        end
    end
    
    -- If no torch or can't place, try placing a solid block to the side
    for _, support_block in ipairs(SUPPORT_BLOCKS) do
        if support_block ~= "minecraft:torch" then
            local slot = Inventory.findItem(support_block)
            if slot then
                turtle.select(slot)
                -- Try to place to the side
                for i = 1, 4 do
                    if turtle.place() then
                        Core.debug("Placed " .. support_block .. " as support")
                        return true, "Support block placed"
                    end
                    Navigation.turnRight()
                end
            end
        end
    end
    
    Core.warning("Unable to place falling block support")
    return false, "No support blocks available"
end

-- Handle falling block hazard during mining
function Safety.handleFallingBlockHazard()
    Core.info("Handling falling block hazard")
    
    -- Step 1: Back away one block
    if not Navigation.back() then
        Core.warning("Cannot back away from falling block")
    end
    
    -- Step 2: Wait for blocks to fall
    Core.sleep(1.5)
    
    -- Step 3: Check if area is clear
    local clear = not turtle.detect()
    
    if clear then
        Core.info("Falling blocks settled")
        return true
    else
        -- Blocks are still there, might be more above
        Core.warning("Falling blocks may cascade")
        return false
    end
end

-- Check structural integrity for cave-in prevention
function Safety.checkStructuralIntegrity(mining_area)
    mining_area = mining_area or {width = 3, height = 3, depth = 1}
    
    local integrity_score = 100
    local issues = {}
    
    -- Check ceiling support
    if mining_area.width > 5 or mining_area.depth > 5 then
        -- Large excavations need support pillars
        integrity_score = integrity_score - 20
        table.insert(issues, "Large excavation requires support pillars")
    end
    
    -- Check for falling blocks in ceiling
    local success, block_above = turtle.inspectUp()
    if success and isFallingBlock(block_above.name) then
        integrity_score = integrity_score - 30
        table.insert(issues, "Falling blocks in ceiling")
    end
    
    -- Check surrounding stability
    local unstable_count = 0
    for i = 1, 4 do
        local ok, block = turtle.inspect()
        if ok and isFallingBlock(block.name) then
            unstable_count = unstable_count + 1
        end
        Navigation.turnRight()
    end
    
    if unstable_count > 2 then
        integrity_score = integrity_score - 20
        table.insert(issues, "Multiple unstable walls")
    end
    
    -- Check if we're in a cave (no blocks around)
    local solid_walls = 0
    for i = 1, 4 do
        if turtle.detect() then
            solid_walls = solid_walls + 1
        end
        Navigation.turnRight()
    end
    
    if solid_walls < 2 then
        integrity_score = integrity_score - 10
        table.insert(issues, "Open cave system - monitor ceiling")
    end
    
    return {
        score = integrity_score,
        safe = integrity_score >= 50,
        issues = issues,
        needs_support = mining_area.width > 5 or mining_area.depth > 5
    }
end

-- Place support pillar for cave-in prevention
function Safety.placeSupportPillar()
    Core.info("Placing support pillar")
    
    -- Find suitable pillar material
    local pillar_block = nil
    local pillar_slot = nil
    
    for _, block in ipairs(SAFE_BLOCKS) do
        pillar_slot = Inventory.findItem(block)
        if pillar_slot then
            pillar_block = block
            break
        end
    end
    
    if not pillar_slot then
        Core.warning("No blocks available for support pillar")
        return false, "No pillar materials"
    end
    
    -- Save current position
    local start_pos = Navigation.getPosition()
    
    -- Build pillar from ground up
    turtle.select(pillar_slot)
    
    -- Go down to floor
    while not turtle.detectDown() and Navigation.down() do
        -- Keep going down
    end
    
    -- Build up
    local pillar_height = 0
    repeat
        if turtle.placeDown() then
            pillar_height = pillar_height + 1
        end
    until not Navigation.up() or pillar_height >= 10
    
    -- Return to start position
    Navigation.moveTo(start_pos)
    
    Core.info("Support pillar placed with height: " .. pillar_height)
    return true, pillar_height
end

-- Plan support pillars for large excavation
function Safety.planSupportPillars(area)
    local pillars = {}
    
    -- Calculate pillar spacing (every 4-5 blocks)
    local spacing = Config.get("pillar_spacing", 4)
    
    -- Generate pillar positions
    for x = area.x1 + spacing, area.x2 - 1, spacing do
        for z = area.z1 + spacing, area.z2 - 1, spacing do
            table.insert(pillars, {
                x = x,
                y = area.y,
                z = z
            })
        end
    end
    
    return pillars
end

-- Pre-mining safety check for falling blocks
function Safety.preMiningCheck(direction)
    direction = direction or "forward"
    
    -- Special check for mining upward
    if direction == "up" then
        local has_falling = Safety.detectFallingBlockAbove()
        if has_falling then
            Core.warning("Falling block detected above - placing support")
            local success, msg = Safety.placeFallingBlockSupport()
            if not success then
                return false, "Cannot safely mine - falling blocks above"
            end
        end
    end
    
    -- Standard safety checks
    return Safety.isSafeToMove(direction)
end

-- Recovery Systems Implementation

-- Recover lost position using various methods
function Safety.recoverLostPosition()
    Core.warning("Position may be lost - attempting recovery")
    
    local recovery_methods = {}
    local recovered = false
    local final_position = nil
    
    -- Method 1: Try GPS
    Core.info("Recovery method 1: GPS location")
    local gps_success, gps_pos = Navigation.locateGPS(10)
    if gps_success then
        Core.info("GPS recovery successful")
        recovered = true
        final_position = gps_pos
        table.insert(recovery_methods, {method = "GPS", success = true, position = gps_pos})
    else
        table.insert(recovery_methods, {method = "GPS", success = false, error = "No GPS signal"})
    end
    
    -- Method 2: Use last known position from state
    if not recovered then
        Core.info("Recovery method 2: Last known position from state")
        local last_pos = State.get("last_known_position")
        if last_pos and Core.isValidPosition(last_pos) then
            -- Verify position makes sense (not too far from expected)
            Core.info("Found last position in state: " .. Navigation.formatPosition(last_pos))
            Navigation.setPosition(last_pos)
            final_position = Core.deepCopy(last_pos)  -- Make sure to copy the position
            recovered = true
            table.insert(recovery_methods, {method = "State", success = true, position = last_pos})
        else
            table.insert(recovery_methods, {method = "State", success = false, error = "No valid position in state"})
        end
    end
    
    -- Method 3: Try to find landmarks (home marker, known blocks)
    if not recovered then
        Core.info("Recovery method 3: Landmark search")
        local landmark_pos = Safety.findLandmarks()
        if landmark_pos then
            Core.info("Landmark recovery successful")
            Navigation.setPosition(landmark_pos)
            final_position = Core.deepCopy(landmark_pos)  -- Make sure to copy the position
            recovered = true
            table.insert(recovery_methods, {method = "Landmark", success = true, position = landmark_pos})
        else
            table.insert(recovery_methods, {method = "Landmark", success = false, error = "No landmarks found"})
        end
    end
    
    -- Method 4: Dead reckoning from movement history
    if not recovered then
        Core.info("Recovery method 4: Dead reckoning from history")
        local history = Navigation.getPathHistory()
        if #history > 0 then
            -- Try to reconstruct position from movement history
            local reconstructed = Safety.reconstructFromHistory(history)
            if reconstructed then
                Core.info("Dead reckoning recovery successful")
                Navigation.setPosition(reconstructed)
                final_position = Core.deepCopy(reconstructed)  -- Make sure to copy the position
                recovered = true
                table.insert(recovery_methods, {method = "Dead reckoning", success = true, position = reconstructed})
            else
                table.insert(recovery_methods, {method = "Dead reckoning", success = false, error = "Could not reconstruct"})
            end
        else
            table.insert(recovery_methods, {method = "Dead reckoning", success = false, error = "No movement history"})
        end
    end
    
    -- Method 5: Return to origin (0, 64, 0) as last resort
    if not recovered then
        Core.error("All recovery methods failed - assuming origin position")
        final_position = {x = 0, y = 64, z = 0, facing = 0}
        Navigation.setPosition(final_position)
        table.insert(recovery_methods, {method = "Origin fallback", success = true, position = final_position})
        recovered = true
    end
    
    -- Log recovery results
    Core.emit("position_recovery_complete", {
        recovered = recovered,
        position = final_position,
        methods_tried = recovery_methods
    })
    
    return recovered, final_position, recovery_methods
end

-- Find landmarks for position recovery
function Safety.findLandmarks()
    Core.debug("Searching for landmarks")
    
    -- Look for specific landmark blocks that we might have placed
    local landmark_blocks = {
        "minecraft:glowstone",  -- Often used as markers
        "minecraft:sea_lantern",
        "minecraft:beacon",
        "minecraft:gold_block"  -- Distinctive marker
    }
    
    -- Search in a small radius
    for y = -2, 2 do
        for x = -3, 3 do
            for z = -3, 3 do
                -- Move to check position
                local moved = true
                if y < 0 then
                    for i = 1, math.abs(y) do moved = moved and Navigation.down() end
                elseif y > 0 then
                    for i = 1, y do moved = moved and Navigation.up() end
                end
                
                if moved then
                    -- Check for landmark
                    local success, block = turtle.inspectDown()
                    if success then
                        for _, landmark in ipairs(landmark_blocks) do
                            if block.name == landmark then
                                Core.info("Found landmark: " .. landmark)
                                -- Check if we have stored positions for landmarks
                                local landmarks = State.get("known_landmarks", {})
                                for _, known in ipairs(landmarks) do
                                    if known.block == landmark then
                                        return known.position
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- Return to start
                if y < 0 then
                    for i = 1, math.abs(y) do Navigation.up() end
                elseif y > 0 then
                    for i = 1, y do Navigation.down() end
                end
            end
        end
    end
    
    return nil
end

-- Reconstruct position from movement history
function Safety.reconstructFromHistory(history)
    if #history == 0 then
        return nil
    end
    
    -- Find the most recent entry with a valid position
    for i = #history, 1, -1 do
        local entry = history[i]
        if entry.pos and Core.isValidPosition(entry.pos) then
            Core.debug("Found valid position in history at index " .. i)
            
            -- Calculate how many moves ago this was
            local moves_ago = #history - i
            if moves_ago < 50 then  -- Recent enough to trust
                return entry.pos
            end
        end
    end
    
    return nil
end

-- Network reconnection protocol
function Safety.reconnectNetwork()
    Core.info("Attempting network reconnection")
    
    -- Check if we have a modem
    local modem = peripheral.find("modem")
    if not modem then
        Core.warning("No modem found for network reconnection")
        return false, "No modem available"
    end
    
    -- Open standard channels
    local channels = Config.get("network_channels", {65535})
    for _, channel in ipairs(channels) do
        modem.open(channel)
    end
    
    -- Try to re-establish protocol
    if rednet then
        local protocol = Config.get("network_protocol", "ULTIMATE_MINER_V2")
        
        -- Close and reopen rednet
        rednet.close()
        Core.sleep(0.5)
        rednet.open(peripheral.getName(modem))
        
        -- Send reconnection announcement
        rednet.broadcast({
            type = "reconnect",
            id = os.computerID(),
            position = Navigation.getPosition(),
            status = "recovering",
            timestamp = os.epoch("utc")
        }, protocol)
        
        Core.info("Network reconnection broadcast sent")
        
        -- Wait for acknowledgment
        local timeout = 5
        local sender, message = rednet.receive(protocol, timeout)
        
        if sender then
            Core.info("Network reconnection acknowledged by " .. tostring(sender))
            return true, sender
        else
            Core.warning("No network response within timeout")
            return false, "No response"
        end
    end
    
    return false, "Rednet not available"
end

-- State recovery after restart
function Safety.recoverState()
    Core.info("Performing state recovery after restart")
    
    local recovery_report = {
        position_recovered = false,
        network_recovered = false,
        inventory_checked = false,
        safety_verified = false,
        issues = {}
    }
    
    -- Step 1: Recover position
    local pos_recovered, position = Safety.recoverLostPosition()
    recovery_report.position_recovered = pos_recovered
    if not pos_recovered then
        table.insert(recovery_report.issues, "Position recovery failed")
    end
    
    -- Step 2: Check fuel status
    local fuel = turtle.getFuelLevel()
    if fuel ~= "unlimited" and fuel < Config.getEmergencyFuel() then
        table.insert(recovery_report.issues, "Critical fuel level: " .. fuel)
        Safety.handleCriticalFuel(fuel)
    end
    
    -- Step 3: Scan inventory
    if Inventory and Inventory.scanInventory then
        Inventory.scanInventory()
        recovery_report.inventory_checked = true
    end
    
    -- Step 4: Perform safety check
    local safe, hazards = Safety.performSafetyCheck()
    recovery_report.safety_verified = true
    if not safe then
        for _, hazard in ipairs(hazards) do
            table.insert(recovery_report.issues, hazard.message)
        end
    end
    
    -- Step 5: Try network reconnection
    local net_success = Safety.reconnectNetwork()
    recovery_report.network_recovered = net_success
    
    -- Step 6: Load last operation state
    local last_operation = State.get("last_operation")
    if last_operation then
        Core.info("Last operation was: " .. tostring(last_operation.type))
        recovery_report.last_operation = last_operation
    end
    
    -- Save recovery report
    State.set("last_recovery", recovery_report)
    State.set("recovery_timestamp", os.epoch("utc"))
    
    Core.emit("state_recovery_complete", recovery_report)
    
    return recovery_report
end

-- Simple mob detection (limited by CC:Tweaked)
function Safety.detectMob()
    -- CC:Tweaked has limited entity detection
    -- We can only infer mob presence through:
    -- 1. Failed movements (mob blocking)
    -- 2. Specific block detection (spawners)
    -- 3. Taking damage (if peripherals available)
    
    local mob_indicators = {}
    
    -- Check for mob spawners nearby
    local spawner_check = {
        {dir = "forward", func = turtle.inspect},
        {dir = "up", func = turtle.inspectUp},
        {dir = "down", func = turtle.inspectDown}
    }
    
    for _, check in ipairs(spawner_check) do
        local success, block = check.func()
        if success and block.name == "minecraft:spawner" then
            table.insert(mob_indicators, {
                type = "spawner",
                direction = check.dir,
                danger_level = 8
            })
        end
    end
    
    -- Check if movement is being blocked (might be mob)
    local movement_blocked = false
    if not turtle.detect() and not Navigation.forward() then
        -- No block but can't move - might be entity
        movement_blocked = true
        Navigation.back()  -- Move back for safety
        table.insert(mob_indicators, {
            type = "entity_blocking",
            direction = "forward",
            danger_level = 5
        })
    end
    
    return #mob_indicators > 0, mob_indicators
end

-- Basic combat protocol (very limited in CC:Tweaked)
function Safety.combatProtocol()
    Core.warning("Potential hostile entity detected - initiating combat protocol")
    
    -- Turtle combat is limited to:
    -- 1. turtle.attack() - melee attack forward
    -- 2. turtle.attackUp() - melee attack up
    -- 3. turtle.attackDown() - melee attack down
    
    local attacks_made = 0
    local max_attempts = 10
    
    -- Try to attack and move
    for i = 1, max_attempts do
        -- Attack in front
        if turtle.attack() then
            attacks_made = attacks_made + 1
            Core.debug("Attack successful")
        end
        
        -- Try to move forward
        if Navigation.forward() then
            Core.info("Path cleared after " .. attacks_made .. " attacks")
            return true, attacks_made
        end
        
        -- If still blocked, attack more aggressively
        turtle.attackUp()
        turtle.attackDown()
        
        -- Small delay between attacks
        Core.sleep(0.2)
    end
    
    -- If we're still blocked, retreat
    Core.warning("Combat failed - retreating")
    for i = 1, 3 do
        Navigation.back()
    end
    
    return false, attacks_made
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