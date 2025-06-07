-- Navigation Module
-- Handles turtle movement, pathfinding, and GPS integration

local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local CONSTANTS = require("shared.constants")
local Safety = nil  -- Lazy load to avoid circular dependency

local Navigation = {}

-- Module state
local initialized = false
local position = {x = 0, y = 0, z = 0, facing = CONSTANTS.DIRECTIONS.NORTH}
local home_position = nil
local gps_available = false
local gps_last_check = 0
local gps_check_interval = 300  -- 5 minutes
local movement_history = nil  -- Circular buffer
local fuel_per_move = 1
local path_cache = {}  -- Cache for A* pathfinding
local emergency_mode = false
local return_path = nil  -- Path back to home for emergencies

-- Initialize navigation module
function Navigation.init(options)
    options = options or {}
    
    -- Load position from state
    position = State.getPosition() or {x = 0, y = 0, z = 0, facing = CONSTANTS.DIRECTIONS.NORTH}
    home_position = State.get("home_position")
    
    -- Initialize movement history buffer
    movement_history = Core.createCircularBuffer(Config.get("max_path_history", CONSTANTS.DEFAULTS.MAX_PATH_HISTORY))
    
    -- Try to get GPS position
    if not options.skip_gps then
        Navigation.locateGPS()
    end
    
    -- Set initial home if not set
    if not home_position then
        Navigation.setHome()
    end
    
    initialized = true
    Core.info("Navigation module initialized at " .. Navigation.formatPosition(position))
    return true, "Navigation initialized"
end

-- Format position for display
function Navigation.formatPosition(pos)
    pos = pos or position
    if pos.facing ~= nil then
        return string.format("X:%d Y:%d Z:%d F:%d", pos.x, pos.y, pos.z, pos.facing)
    else
        return string.format("X:%d Y:%d Z:%d", pos.x, pos.y, pos.z)
    end
end

-- Update position based on movement direction
local function updatePosition(direction, amount)
    amount = amount or 1
    
    if direction == "forward" then
        local vec = CONSTANTS.DIRECTION_VECTORS[position.facing]
        position.x = position.x + (vec.x * amount)
        position.z = position.z + (vec.z * amount)
    elseif direction == "back" then
        local vec = CONSTANTS.DIRECTION_VECTORS[position.facing]
        position.x = position.x - (vec.x * amount)
        position.z = position.z - (vec.z * amount)
    elseif direction == "up" then
        position.y = position.y + amount
    elseif direction == "down" then
        position.y = position.y - amount
    end
    
    -- Save updated position
    State.setPosition(position)
    
    -- Add to movement history
    if movement_history then
        movement_history:add({
            pos = Core.deepCopy(position),
            time = os.epoch("utc"),
            action = direction
        })
    end
    
    -- Update statistics
    State.incrementCounter("distance_traveled", amount)
end

-- Check if movement is safe
local function checkMovementSafety(direction)
    -- Lazy load Safety module if available
    if not Safety and package.loaded["turtle.modules.safety"] then
        Safety = require("turtle.modules.safety")
    end
    
    -- Use Safety module check if available
    if Safety and Safety.isSafeToMove then
        local safe, reason = Safety.isSafeToMove(direction)
        if not safe then
            return false, reason
        end
    end
    
    -- Check fuel
    local fuel = turtle.getFuelLevel()
    if fuel ~= "unlimited" and fuel < Config.getEmergencyFuel() then
        Core.emit("safety.fuel_critical", {level = fuel, required = Config.getEmergencyFuel()})
        return false, "Critical fuel level"
    end
    
    -- Check bounds
    local future_pos = Core.deepCopy(position)
    
    if direction == "forward" then
        local vec = CONSTANTS.DIRECTION_VECTORS[position.facing]
        future_pos.x = future_pos.x + vec.x
        future_pos.z = future_pos.z + vec.z
    elseif direction == "back" then
        local vec = CONSTANTS.DIRECTION_VECTORS[position.facing]
        future_pos.x = future_pos.x - vec.x
        future_pos.z = future_pos.z - vec.z
    elseif direction == "up" then
        future_pos.y = future_pos.y + 1
    elseif direction == "down" then
        future_pos.y = future_pos.y - 1
    end
    
    -- Check Y bounds
    if future_pos.y < CONSTANTS.LIMITS.MIN_SAFE_Y then
        return false, "Below minimum safe Y level"
    elseif future_pos.y > CONSTANTS.LIMITS.MAX_SAFE_Y then
        return false, "Above maximum safe Y level"
    end
    
    -- Check safety radius from home
    if home_position and Config.get("safe_mining") then
        local distance = Core.vector.distance(
            Core.vector.new(home_position.x, home_position.y, home_position.z),
            Core.vector.new(future_pos.x, future_pos.y, future_pos.z)
        )
        
        if distance > Config.getSafetyRadius() then
            Core.emit("safety.boundary_violation", {position = future_pos, distance = distance})
            return false, "Outside safety radius"
        end
    end
    
    return true
end

-- Basic movement functions with safety and tracking
function Navigation.forward()
    if not initialized then
        return false, "Navigation not initialized"
    end
    
    -- Safety check
    local safe, reason = checkMovementSafety("forward")
    if not safe then
        return false, reason
    end
    
    -- Attempt movement
    local success, err = turtle.forward()
    
    if success then
        updatePosition("forward")
        State.incrementCounter("fuel_used", fuel_per_move)
        Core.debug("Moved forward to " .. Navigation.formatPosition())
        return true
    else
        Core.emit("navigation.path_blocked", {position = position, reason = err or "unknown"})
        return false, err or "Movement blocked"
    end
end

function Navigation.back()
    if not initialized then
        return false, "Navigation not initialized"
    end
    
    -- Safety check
    local safe, reason = checkMovementSafety("back")
    if not safe then
        return false, reason
    end
    
    -- Attempt movement
    local success, err = turtle.back()
    
    if success then
        updatePosition("back")
        State.incrementCounter("fuel_used", fuel_per_move)
        Core.debug("Moved back to " .. Navigation.formatPosition())
        return true
    else
        Core.emit("navigation.path_blocked", {position = position, reason = err or "unknown"})
        return false, err or "Movement blocked"
    end
end

function Navigation.up()
    if not initialized then
        return false, "Navigation not initialized"
    end
    
    -- Safety check
    local safe, reason = checkMovementSafety("up")
    if not safe then
        return false, reason
    end
    
    -- Attempt movement
    local success, err = turtle.up()
    
    if success then
        updatePosition("up")
        State.incrementCounter("fuel_used", fuel_per_move)
        Core.debug("Moved up to " .. Navigation.formatPosition())
        return true
    else
        Core.emit("navigation.path_blocked", {position = position, reason = err or "unknown"})
        return false, err or "Movement blocked"
    end
end

function Navigation.down()
    if not initialized then
        return false, "Navigation not initialized"
    end
    
    -- Safety check
    local safe, reason = checkMovementSafety("down")
    if not safe then
        return false, reason
    end
    
    -- Attempt movement
    local success, err = turtle.down()
    
    if success then
        updatePosition("down")
        State.incrementCounter("fuel_used", fuel_per_move)
        Core.debug("Moved down to " .. Navigation.formatPosition())
        return true
    else
        Core.emit("navigation.path_blocked", {position = position, reason = err or "unknown"})
        return false, err or "Movement blocked"
    end
end

function Navigation.turnLeft()
    if not initialized then
        return false, "Navigation not initialized"
    end
    
    local success, err = turtle.turnLeft()
    
    if success then
        position.facing = (position.facing - 1) % 4
        State.setPosition(position)
        Core.debug("Turned left, now facing " .. position.facing)
        return true
    else
        return false, err or "Turn failed"
    end
end

function Navigation.turnRight()
    if not initialized then
        return false, "Navigation not initialized"
    end
    
    local success, err = turtle.turnRight()
    
    if success then
        position.facing = (position.facing + 1) % 4
        State.setPosition(position)
        Core.debug("Turned right, now facing " .. position.facing)
        return true
    else
        return false, err or "Turn failed"
    end
end

-- Face a specific direction
function Navigation.face(target_facing)
    if not initialized then
        return false, "Navigation not initialized"
    end
    
    target_facing = target_facing % 4
    
    -- Calculate shortest turn
    local current = position.facing
    local diff = (target_facing - current + 4) % 4
    
    if diff == 0 then
        return true  -- Already facing correct direction
    elseif diff == 1 then
        return Navigation.turnRight()
    elseif diff == 2 then
        -- 180 degree turn, either direction works
        Navigation.turnRight()
        return Navigation.turnRight()
    elseif diff == 3 then
        return Navigation.turnLeft()
    end
end

-- Position management
function Navigation.getPosition()
    return Core.deepCopy(position)
end

function Navigation.setPosition(pos)
    if not Core.isValidPosition(pos) then
        return false
    end
    
    position = Core.deepCopy(pos)
    position.facing = pos.facing or CONSTANTS.DIRECTIONS.NORTH
    State.setPosition(position)
    
    Core.info("Position manually set to " .. Navigation.formatPosition())
    return true
end

function Navigation.setHome(pos)
    if pos and not Core.isValidPosition(pos) then
        return false
    end
    
    home_position = pos or Core.deepCopy(position)
    State.set("home_position", home_position)
    
    Core.info("Home position set to " .. Navigation.formatPosition(home_position))
    return true
end

function Navigation.getHome()
    return home_position and Core.deepCopy(home_position) or nil
end

-- GPS integration with enhanced features
function Navigation.locateGPS(timeout, silent)
    timeout = timeout or 5
    
    -- Check if we need to refresh GPS
    local now = os.epoch("utc") / 1000
    if gps_available and (now - gps_last_check) < gps_check_interval then
        return true, position  -- Use cached GPS
    end
    
    -- Try to get GPS position
    local x, y, z = gps.locate(timeout)
    
    if x then
        -- Compare with current position for validation
        local old_pos = Core.deepCopy(position)
        position.x = x
        position.y = y
        position.z = z
        -- Note: GPS doesn't provide facing, so we keep current facing
        
        -- Validate the GPS reading
        if gps_available then
            local drift = Core.vector.manhattan(
                Core.vector.new(old_pos.x, old_pos.y, old_pos.z),
                Core.vector.new(x, y, z)
            )
            
            -- Check for unreasonable GPS drift
            if drift > 100 then
                Core.warning("GPS drift detected: " .. drift .. " blocks")
                -- Could be chunk loading or GPS error
                if not silent then
                    Core.emit("navigation.gps_drift", {old = old_pos, new = position, drift = drift})
                end
            end
        end
        
        State.setPosition(position)
        gps_available = true
        gps_last_check = now
        
        if not silent then
            Core.info("GPS location acquired: " .. Navigation.formatPosition())
        end
        return true, position
    else
        -- GPS failed, but we might have a last known position
        if gps_available then
            Core.warning("Lost GPS signal, using dead reckoning")
            gps_available = false
            Core.emit("navigation.gps_lost", {last_position = position})
        elseif not silent then
            Core.warning("GPS not available")
        end
        return false, "GPS not available"
    end
end

-- Attempt to recover GPS by triangulation
function Navigation.recoverGPS()
    Core.info("Attempting GPS recovery...")
    
    -- First try standard GPS
    if Navigation.locateGPS(10, true) then
        return true, "GPS recovered"
    end
    
    -- Try moving to get a better signal
    local movements = {
        {dir = "up", reverse = "down"},
        {dir = "forward", reverse = "back"},
        {dir = "turnRight", reverse = "turnLeft"}
    }
    
    for _, move in ipairs(movements) do
        -- Try movement
        if Navigation[move.dir] and Navigation[move.dir]() then
            -- Try GPS again
            if Navigation.locateGPS(5, true) then
                -- Move back
                Navigation[move.reverse]()
                Core.info("GPS recovered after movement")
                return true, "GPS recovered"
            end
            -- Move back
            Navigation[move.reverse]()
        end
    end
    
    return false, "GPS recovery failed"
end

-- Manual position setting with validation
function Navigation.setManualPosition(x, y, z, facing)
    if not (type(x) == "number" and type(y) == "number" and type(z) == "number") then
        return false, "Invalid coordinates"
    end
    
    -- Validate facing
    if facing ~= nil then
        if type(facing) == "string" then
            -- Convert string to direction constant
            facing = CONSTANTS.DIRECTIONS[facing:upper()]
        end
        if type(facing) ~= "number" or facing < 0 or facing > 3 then
            return false, "Invalid facing direction"
        end
    else
        facing = position.facing
    end
    
    local old_pos = Core.deepCopy(position)
    position.x = x
    position.y = y
    position.z = z
    position.facing = facing
    
    State.setPosition(position)
    Core.info("Position manually set from " .. Navigation.formatPosition(old_pos) .. " to " .. Navigation.formatPosition())
    
    -- Mark GPS as unavailable since we're using manual positioning
    gps_available = false
    
    return true, position
end

function Navigation.calibrateGPS()
    if not Navigation.locateGPS() then
        return false, "GPS not available"
    end
    
    -- Try to determine facing by moving
    local start_pos = Navigation.getPosition()
    
    -- Try moving forward
    if turtle.forward() then
        -- Get new GPS position
        local x, y, z = gps.locate(5)
        if x then
            -- Calculate facing based on movement
            local dx = x - start_pos.x
            local dz = z - start_pos.z
            
            if math.abs(dx) > math.abs(dz) then
                position.facing = dx > 0 and CONSTANTS.DIRECTIONS.EAST or CONSTANTS.DIRECTIONS.WEST
            else
                position.facing = dz > 0 and CONSTANTS.DIRECTIONS.SOUTH or CONSTANTS.DIRECTIONS.NORTH
            end
            
            -- Move back
            turtle.back()
            
            State.setPosition(position)
            Core.info("GPS calibration complete, facing: " .. position.facing)
            return true
        else
            turtle.back()
            return false, "Lost GPS during calibration"
        end
    else
        return false, "Cannot move to calibrate"
    end
end

-- Distance and fuel calculations
function Navigation.getDistance(target)
    if not Core.isValidPosition(target) then
        return nil
    end
    
    return Core.vector.manhattan(
        Core.vector.new(position.x, position.y, position.z),
        Core.vector.new(target.x, target.y, target.z)
    )
end

function Navigation.estimateFuel(target)
    local distance = Navigation.getDistance(target)
    if not distance then
        return nil
    end
    
    -- Add some buffer for turning and obstacles
    return math.ceil(distance * 1.2)
end

function Navigation.getFacing()
    return position.facing
end

-- A* Pathfinding Node
local function createNode(pos, g, h, parent)
    return {
        pos = pos,
        g = g or 0,  -- Cost from start
        h = h or 0,  -- Heuristic cost to end
        f = (g or 0) + (h or 0),  -- Total cost
        parent = parent
    }
end

-- Generate hash for position (for pathfinding cache)
local function positionHash(pos)
    return string.format("%d,%d,%d", pos.x, pos.y, pos.z)
end

-- Get neighboring positions
local function getNeighbors(pos)
    local neighbors = {}
    
    -- All 6 directions
    local directions = {
        {x = 0, y = 1, z = 0, cost = 1},   -- up
        {x = 0, y = -1, z = 0, cost = 1},  -- down
        {x = 1, y = 0, z = 0, cost = 1},   -- east
        {x = -1, y = 0, z = 0, cost = 1},  -- west
        {x = 0, y = 0, z = 1, cost = 1},   -- south
        {x = 0, y = 0, z = -1, cost = 1}   -- north
    }
    
    for _, dir in ipairs(directions) do
        local neighbor = {
            x = pos.x + dir.x,
            y = pos.y + dir.y,
            z = pos.z + dir.z
        }
        
        -- Check bounds
        if neighbor.y >= CONSTANTS.LIMITS.MIN_SAFE_Y and 
           neighbor.y <= CONSTANTS.LIMITS.MAX_SAFE_Y then
            table.insert(neighbors, {pos = neighbor, cost = dir.cost})
        end
    end
    
    return neighbors
end

-- A* pathfinding algorithm
function Navigation.pathTo(target, options)
    if not Core.isValidPosition(target) then
        return nil, "Invalid target position"
    end
    
    options = options or {}
    local max_distance = options.max_distance or 500
    local avoid_list = options.avoid or {}
    
    -- Check cache
    local cache_key = positionHash(position) .. "->" .. positionHash(target)
    if path_cache[cache_key] and not options.no_cache then
        Core.debug("Using cached path")
        return path_cache[cache_key]
    end
    
    -- Initialize A*
    local open_set = {}
    local closed_set = {}
    local came_from = {}
    
    local start_node = createNode(position, 0, Navigation.getDistance(target))
    open_set[positionHash(position)] = start_node
    
    local iterations = 0
    local max_iterations = options.max_iterations or 1000
    
    while next(open_set) do
        iterations = iterations + 1
        if iterations > max_iterations then
            Core.warning("Pathfinding exceeded max iterations")
            return nil, "Path too complex"
        end
        
        -- Find node with lowest f score
        local current_hash = nil
        local current_node = nil
        for hash, node in pairs(open_set) do
            if not current_node or node.f < current_node.f then
                current_hash = hash
                current_node = node
            end
        end
        
        -- Check if we reached the target
        if Core.vector.equals(
            Core.vector.new(current_node.pos.x, current_node.pos.y, current_node.pos.z),
            Core.vector.new(target.x, target.y, target.z)
        ) then
            -- Reconstruct path
            local path = {}
            local node = current_node
            while node do
                table.insert(path, 1, Core.deepCopy(node.pos))
                node = node.parent
            end
            
            -- Cache the path
            path_cache[cache_key] = path
            
            return path
        end
        
        -- Move current from open to closed
        open_set[current_hash] = nil
        closed_set[current_hash] = true
        
        -- Check all neighbors
        for _, neighbor_data in ipairs(getNeighbors(current_node.pos)) do
            local neighbor = neighbor_data.pos
            local neighbor_hash = positionHash(neighbor)
            
            -- Skip if in closed set or avoid list
            if not (closed_set[neighbor_hash] or avoid_list[neighbor_hash]) then
            
            -- Calculate tentative g score
            local tentative_g = current_node.g + neighbor_data.cost
            
            -- Check if we need to update or add this neighbor
            local neighbor_node = open_set[neighbor_hash]
            if not neighbor_node then
                -- New node
                neighbor_node = createNode(
                    neighbor,
                    tentative_g,
                    Navigation.getDistance(target),
                    current_node
                )
                open_set[neighbor_hash] = neighbor_node
            elseif tentative_g < neighbor_node.g then
                -- Better path found
                neighbor_node.g = tentative_g
                neighbor_node.f = neighbor_node.g + neighbor_node.h
                neighbor_node.parent = current_node
            end
            end -- end if not in closed/avoid set
        end
        
        -- Yield periodically
        if iterations % 10 == 0 then
            Core.yield()
        end
    end
    
    return nil, "No path found"
end

-- Enhanced movement with pathfinding
function Navigation.moveTo(target, options)
    if not initialized then
        return false, "Navigation not initialized"
    end
    
    if not Core.isValidPosition(target) then
        return false, "Invalid target position"
    end
    
    options = options or {}
    
    -- Check if we're already at the target
    if position.x == target.x and position.y == target.y and position.z == target.z then
        if target.facing then
            Navigation.face(target.facing)
        end
        return true, "Already at destination"
    end
    
    -- Check fuel
    if options.fuel_check ~= false then
        local needed = Navigation.estimateFuel(target)
        local current = turtle.getFuelLevel()
        
        if current ~= "unlimited" and current < needed + Config.getFuelReserve() then
            return false, "Insufficient fuel"
        end
    end
    
    Core.info("Moving to " .. Navigation.formatPosition(target))
    
    -- Try A* pathfinding first if requested
    if options.use_pathfinding or Config.get("use_pathfinding", true) then
        local path, err = Navigation.pathTo(target, options)
        
        if path then
            Core.debug("Following A* path with " .. #path .. " waypoints")
            
            -- Follow the path
            for i = 2, #path do  -- Skip first position (current)
                local waypoint = path[i]
                
                -- Move to waypoint using simple movement
                local success, move_err = Navigation.moveToSimple(waypoint)
                if not success then
                    -- Path blocked, try to recalculate
                    if options.recalculate_on_block then
                        Core.debug("Path blocked, recalculating...")
                        return Navigation.moveTo(target, Core.mergeTables(options, {no_cache = true}))
                    end
                    return false, move_err
                end
                
                -- Check for emergency conditions
                if emergency_mode then
                    return false, "Emergency mode activated"
                end
            end
            
            -- Face target direction if specified
            if target.facing then
                Navigation.face(target.facing)
            end
            
            Core.info("Arrived at destination via pathfinding")
            return true
        else
            Core.debug("Pathfinding failed: " .. err .. ", falling back to simple movement")
        end
    end
    
    -- Fall back to simple movement
    return Navigation.moveToSimple(target)
end

-- Simple movement without pathfinding
function Navigation.moveToSimple(target)
    -- Move to target Y first (safer)
    while position.y ~= target.y do
        Core.yield()
        
        if position.y < target.y then
            if not Navigation.up() then
                return false, "Path blocked moving up"
            end
        else
            if not Navigation.down() then
                return false, "Path blocked moving down"
            end
        end
    end
    
    -- Move X
    while position.x ~= target.x do
        Core.yield()
        
        -- Face the right direction
        if position.x < target.x then
            Navigation.face(CONSTANTS.DIRECTIONS.EAST)
        else
            Navigation.face(CONSTANTS.DIRECTIONS.WEST)
        end
        
        if not Navigation.forward() then
            return false, "Path blocked on X axis"
        end
    end
    
    -- Move Z
    while position.z ~= target.z do
        Core.yield()
        
        -- Face the right direction
        if position.z < target.z then
            Navigation.face(CONSTANTS.DIRECTIONS.SOUTH)
        else
            Navigation.face(CONSTANTS.DIRECTIONS.NORTH)
        end
        
        if not Navigation.forward() then
            return false, "Path blocked on Z axis"
        end
    end
    
    -- Face target direction if specified
    if target.facing then
        Navigation.face(target.facing)
    end
    
    Core.info("Arrived at destination")
    return true
end

-- Return to home position
function Navigation.returnHome()
    if not home_position then
        return false, "No home position set"
    end
    
    Core.info("Returning home...")
    Core.emit("navigation.returning_home", {from = position, to = home_position})
    
    local success, err = Navigation.moveTo(home_position)
    
    if success then
        Core.emit("navigation.home_reached", {position = home_position})
    end
    
    return success, err
end

-- Path history
function Navigation.getPathHistory()
    if movement_history then
        return movement_history:toArray()
    end
    return {}
end

function Navigation.clearPathHistory()
    if movement_history then
        movement_history:clear()
    end
end

-- Emergency functions
function Navigation.emergencyStop()
    Core.critical("Emergency stop activated!")
    emergency_mode = true
    Core.emit("navigation.emergency_stop", {position = position, reason = "Manual stop"})
    return true
end

function Navigation.getLastPosition()
    if movement_history then
        local last = movement_history:getLast()
        return last and last.pos or nil
    end
    return nil
end

-- Enhanced path history functions
function Navigation.getPathHistoryStats()
    if not movement_history then
        return nil
    end
    
    local history = movement_history:toArray()
    local stats = {
        total_moves = #history,
        unique_positions = 0,
        most_visited = nil,
        furthest_from_home = 0,
        time_span = 0
    }
    
    if #history == 0 then
        return stats
    end
    
    -- Calculate statistics
    local position_counts = {}
    local first_time = history[1].time
    local last_time = history[#history].time
    
    for _, entry in ipairs(history) do
        local hash = positionHash(entry.pos)
        position_counts[hash] = (position_counts[hash] or 0) + 1
        
        -- Check distance from home
        if home_position then
            local dist = Navigation.getDistance(entry.pos)
            stats.furthest_from_home = math.max(stats.furthest_from_home, dist)
        end
    end
    
    -- Count unique positions
    for _ in pairs(position_counts) do
        stats.unique_positions = stats.unique_positions + 1
    end
    
    -- Find most visited position
    local max_visits = 0
    for hash, count in pairs(position_counts) do
        if count > max_visits then
            max_visits = count
            stats.most_visited = hash
        end
    end
    
    stats.time_span = (last_time - first_time) / 1000  -- Convert to seconds
    
    return stats
end

-- Emergency return protocols
function Navigation.activateEmergencyReturn(reason)
    if emergency_mode then
        return false, "Already in emergency mode"
    end
    
    Core.critical("EMERGENCY RETURN ACTIVATED: " .. tostring(reason))
    emergency_mode = true
    
    Core.emit("navigation.emergency_return", {
        position = position,
        reason = reason,
        fuel = turtle.getFuelLevel(),
        home = home_position
    })
    
    -- Try to get GPS fix first
    Navigation.locateGPS(2, true)
    
    -- Calculate path home
    if home_position then
        return_path = Navigation.pathTo(home_position, {
            max_iterations = 2000,
            fuel_check = false,  -- We're already in emergency
            use_pathfinding = true
        })
        
        if return_path then
            Core.info("Emergency path calculated with " .. #return_path .. " steps")
            return true, return_path
        else
            Core.error("Failed to calculate emergency return path")
            -- Try simple movement as last resort
            return Navigation.returnHomeEmergency()
        end
    else
        return false, "No home position set"
    end
end

-- Emergency return home (simple, reliable movement)
function Navigation.returnHomeEmergency()
    if not home_position then
        return false, "No home position set"
    end
    
    Core.info("Attempting emergency return to home...")
    
    -- Disable normal safety checks for emergency
    local old_safety = Config.get("safe_mining")
    Config.set("safe_mining", false)
    
    -- Try to move home with basic movement
    local success = true
    local steps = 0
    
    -- Move Y first (get to safe altitude)
    while position.y < home_position.y and steps < 1000 do
        if not turtle.up() then
            -- Try to dig if blocked
            if turtle.detectUp() then
                turtle.digUp()
            end
            if not turtle.up() then
                success = false
                break
            end
        end
        updatePosition("up")
        steps = steps + 1
        Core.yield()
    end
    
    -- Then try X and Z
    if success then
        success = Navigation.moveToSimple(home_position)
    end
    
    -- Restore safety setting
    Config.set("safe_mining", old_safety)
    
    if success then
        emergency_mode = false
        Core.info("Emergency return successful")
        Core.emit("navigation.emergency_return_complete", {position = position})
    else
        Core.error("Emergency return failed")
    end
    
    return success
end

-- Check if emergency return is needed
function Navigation.checkEmergencyConditions()
    -- Check fuel
    local fuel = turtle.getFuelLevel()
    if fuel ~= "unlimited" then
        local fuel_home = home_position and Navigation.estimateFuel(home_position) or 0
        
        if fuel < fuel_home + Config.getEmergencyFuel() then
            Core.warning("Low fuel detected: " .. fuel .. " (need " .. (fuel_home + Config.getEmergencyFuel()) .. " for safe return)")
            return true, "Critical fuel level"
        end
    end
    
    -- Check distance from home
    if home_position and Config.get("max_distance_from_home") then
        local distance = Navigation.getDistance(home_position)
        local max_distance = Config.get("max_distance_from_home")
        
        if distance > max_distance then
            Core.warning("Too far from home: " .. distance .. " blocks")
            return true, "Exceeded maximum distance from home"
        end
    end
    
    return false
end

-- Clear path cache
function Navigation.clearPathCache()
    path_cache = {}
    Core.debug("Path cache cleared")
end

-- Get navigation statistics
function Navigation.getStats()
    return {
        position = Core.deepCopy(position),
        home = home_position and Core.deepCopy(home_position) or nil,
        gps_available = gps_available,
        emergency_mode = emergency_mode,
        path_cache_size = Core.tableSize(path_cache),
        history_size = movement_history and movement_history.size or 0
    }
end

-- Check if position is within safety bounds
function Navigation.isWithinBounds(pos)
    pos = pos or position
    
    -- Check Y bounds
    if pos.y < CONSTANTS.LIMITS.MIN_SAFE_Y or pos.y > CONSTANTS.LIMITS.MAX_SAFE_Y then
        return false, "Outside Y bounds"
    end
    
    -- Check safety radius from home
    if home_position and Config.get("safety_radius") then
        local distance = Core.vector.manhattan(
            Core.vector.new(home_position.x, home_position.y, home_position.z),
            Core.vector.new(pos.x, pos.y, pos.z)
        )
        
        if distance > Config.get("safety_radius") then
            return false, "Outside safety radius"
        end
    end
    
    return true
end

-- Backtrack along path history
function Navigation.backtrack(steps)
    if not movement_history or movement_history.size == 0 then
        return false, "No movement history available"
    end
    
    steps = math.min(steps or 1, movement_history.size)
    Core.info("Backtracking " .. steps .. " steps")
    
    local history = movement_history:toArray()
    local success = true
    
    -- Move backwards through history
    for i = #history - 1, math.max(1, #history - steps), -1 do
        local target = history[i].pos
        
        if not Navigation.moveToSimple(target) then
            Core.warning("Backtrack failed at step " .. (#history - i))
            success = false
            break
        end
    end
    
    return success
end

return Navigation