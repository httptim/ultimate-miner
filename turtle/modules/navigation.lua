-- Navigation Module
-- Handles turtle movement, pathfinding, and GPS integration

local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local CONSTANTS = require("shared.constants")

local Navigation = {}

-- Module state
local initialized = false
local position = {x = 0, y = 0, z = 0, facing = CONSTANTS.DIRECTIONS.NORTH}
local home_position = nil
local gps_available = false
local movement_history = nil  -- Circular buffer
local fuel_per_move = 1

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
    return string.format("X:%d Y:%d Z:%d F:%d", pos.x, pos.y, pos.z, pos.facing)
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

-- GPS integration
function Navigation.locateGPS()
    -- Check for GPS
    local x, y, z = gps.locate(5)  -- 5 second timeout
    
    if x then
        position.x = x
        position.y = y
        position.z = z
        -- Note: GPS doesn't provide facing, so we keep current facing
        
        State.setPosition(position)
        gps_available = true
        
        Core.info("GPS location acquired: " .. Navigation.formatPosition())
        return true, position
    else
        gps_available = false
        Core.warning("GPS not available")
        return false, "GPS not available"
    end
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

-- Simple pathfinding (will be expanded later)
function Navigation.moveTo(target, options)
    if not initialized then
        return false, "Navigation not initialized"
    end
    
    if not Core.isValidPosition(target) then
        return false, "Invalid target position"
    end
    
    options = options or {}
    
    -- Check fuel
    if options.fuel_check ~= false then
        local needed = Navigation.estimateFuel(target)
        local current = turtle.getFuelLevel()
        
        if current ~= "unlimited" and current < needed + Config.getFuelReserve() then
            return false, "Insufficient fuel"
        end
    end
    
    Core.info("Moving to " .. Navigation.formatPosition(target))
    
    -- Simple movement for now (will implement A* later)
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
    -- Currently just stops, but could be expanded
    return true
end

function Navigation.getLastPosition()
    if movement_history then
        local last = movement_history:getLast()
        return last and last.pos or nil
    end
    return nil
end

return Navigation