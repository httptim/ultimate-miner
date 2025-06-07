-- Monitor Module for Control Computer
-- Handles external monitor displays for fleet visualization

local Monitor = {}

-- Dependencies
local Core = require("control.modules.core")
local Fleet = require("control.modules.fleet")
local CONSTANTS = require("shared.constants")

-- Module state
local initialized = false
local monitors = {}
local active_display = nil
local display_mode = "overview"  -- overview, turtle_list, statistics, map
local refresh_timer = nil
local refresh_interval = 2  -- seconds

-- Find all connected monitors
local function findMonitors()
    monitors = {}
    
    -- Check all sides
    local sides = {"top", "bottom", "left", "right", "front", "back"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "monitor" then
            local mon = peripheral.wrap(side)
            table.insert(monitors, {
                side = side,
                monitor = mon,
                width = mon.getSize()
            })
            Core.debug("Found monitor on " .. side)
        end
    end
    
    -- Check for networked monitors
    local peripherals = peripheral.getNames()
    for _, name in ipairs(peripherals) do
        if peripheral.getType(name) == "monitor" then
            local mon = peripheral.wrap(name)
            table.insert(monitors, {
                side = name,
                monitor = mon,
                width = mon.getSize()
            })
            Core.debug("Found networked monitor: " .. name)
        end
    end
    
    return #monitors > 0
end

-- Select the best monitor for display
local function selectBestMonitor()
    if #monitors == 0 then
        return nil
    end
    
    -- Find the largest monitor
    local best = monitors[1]
    local best_size = 0
    
    for _, mon_data in ipairs(monitors) do
        local w, h = mon_data.monitor.getSize()
        local size = w * h
        if size > best_size then
            best = mon_data
            best_size = size
        end
    end
    
    return best
end

-- Draw header on monitor
local function drawHeader(mon, title)
    local width, height = mon.getSize()
    
    mon.setCursorPos(1, 1)
    mon.setBackgroundColor(colors.blue)
    mon.setTextColor(colors.white)
    mon.clearLine()
    
    -- Center the title
    local title_x = math.floor((width - #title) / 2)
    mon.setCursorPos(title_x, 1)
    mon.write(title)
    
    -- Reset colors
    mon.setBackgroundColor(colors.black)
    mon.setTextColor(colors.white)
end

-- Draw fleet overview
local function drawOverview(mon)
    local width, height = mon.getSize()
    drawHeader(mon, "Fleet Overview")
    
    local turtles = Fleet.getAllTurtles()
    local turtle_count = 0
    local status_count = {
        active = 0,
        idle = 0,
        offline = 0,
        error = 0
    }
    
    -- Count turtles and statuses
    for id, turtle in pairs(turtles) do
        turtle_count = turtle_count + 1
        local status = turtle.status or "offline"
        status_count[status] = (status_count[status] or 0) + 1
    end
    
    -- Draw summary
    local y = 3
    mon.setCursorPos(2, y)
    mon.write("Total Turtles: " .. turtle_count)
    
    y = y + 2
    
    -- Draw status breakdown
    local status_colors = {
        active = colors.green,
        idle = colors.yellow,
        offline = colors.red,
        error = colors.orange
    }
    
    for status, count in pairs(status_count) do
        if count > 0 then
            mon.setCursorPos(2, y)
            
            if mon.isColor() then
                mon.setTextColor(status_colors[status] or colors.white)
            end
            
            mon.write(string.format("%-8s: %3d", status:upper(), count))
            
            -- Draw bar graph
            if width > 30 then
                mon.setCursorPos(20, y)
                local bar_width = math.floor((count / turtle_count) * (width - 25))
                mon.write("[" .. string.rep("=", bar_width) .. string.rep(" ", width - 25 - bar_width) .. "]")
            end
            
            y = y + 1
        end
    end
    
    if mon.isColor() then
        mon.setTextColor(colors.white)
    end
    
    -- Draw recent activity
    if height > 12 then
        y = y + 2
        mon.setCursorPos(2, y)
        mon.write("Recent Activity:")
        y = y + 1
        
        -- Get recent events from fleet
        local events = Fleet.getRecentEvents(5)
        for _, event in ipairs(events) do
            if y < height then
                mon.setCursorPos(2, y)
                local time_str = os.date("%H:%M", event.time)
                mon.write(time_str .. " " .. event.message)
                y = y + 1
            end
        end
    end
end

-- Draw turtle list
local function drawTurtleList(mon)
    local width, height = mon.getSize()
    drawHeader(mon, "Turtle Status")
    
    local turtles = Fleet.getAllTurtles()
    local turtle_list = {}
    
    -- Convert to list for sorting
    for id, turtle in pairs(turtles) do
        turtle.id = id
        table.insert(turtle_list, turtle)
    end
    
    -- Sort by ID
    table.sort(turtle_list, function(a, b) return a.id < b.id end)
    
    -- Draw column headers
    local y = 3
    mon.setCursorPos(1, y)
    mon.write("ID   Name            Status   Fuel    Position")
    y = y + 1
    mon.setCursorPos(1, y)
    mon.write(string.rep("-", width))
    y = y + 1
    
    -- Draw turtle entries
    local visible_count = height - 5
    for i = 1, math.min(visible_count, #turtle_list) do
        local turtle = turtle_list[i]
        
        if y < height then
            mon.setCursorPos(1, y)
            
            -- ID
            mon.write(string.format("%-4d ", turtle.id))
            
            -- Name
            local name = turtle.name or ("T-" .. turtle.id)
            if #name > 15 then
                name = string.sub(name, 1, 12) .. "..."
            end
            mon.write(string.format("%-15s ", name))
            
            -- Status with color
            local status = turtle.status or "offline"
            if mon.isColor() then
                local status_colors = {
                    active = colors.green,
                    idle = colors.yellow,
                    offline = colors.red,
                    error = colors.orange
                }
                mon.setTextColor(status_colors[status] or colors.white)
            end
            mon.write(string.format("%-8s ", status))
            
            if mon.isColor() then
                mon.setTextColor(colors.white)
            end
            
            -- Fuel
            local fuel = turtle.fuel_level or 0
            if fuel == "unlimited" then
                mon.write("Unlim ")
            else
                mon.write(string.format("%-6d ", fuel))
            end
            
            -- Position
            if turtle.position then
                mon.write(string.format("%d,%d,%d", 
                    turtle.position.x or 0,
                    turtle.position.y or 0,
                    turtle.position.z or 0))
            else
                mon.write("Unknown")
            end
            
            y = y + 1
        end
    end
    
    -- Show if more turtles exist
    if #turtle_list > visible_count then
        mon.setCursorPos(1, height)
        mon.write("... and " .. (#turtle_list - visible_count) .. " more")
    end
end

-- Draw statistics
local function drawStatistics(mon)
    local width, height = mon.getSize()
    drawHeader(mon, "Fleet Statistics")
    
    -- Calculate statistics
    local stats = Fleet.getFleetStatistics()
    
    local y = 3
    
    -- Mining statistics
    mon.setCursorPos(2, y)
    mon.write("Mining Performance:")
    y = y + 1
    
    mon.setCursorPos(4, y)
    mon.write("Total Blocks: " .. (stats.total_blocks_mined or 0))
    y = y + 1
    
    mon.setCursorPos(4, y)
    mon.write("Total Ores: " .. (stats.total_ores_found or 0))
    y = y + 1
    
    mon.setCursorPos(4, y)
    local efficiency = 0
    if stats.total_blocks_mined and stats.total_blocks_mined > 0 then
        efficiency = (stats.total_ores_found / stats.total_blocks_mined) * 100
    end
    mon.write(string.format("Efficiency: %.1f%%", efficiency))
    y = y + 2
    
    -- Resource statistics
    mon.setCursorPos(2, y)
    mon.write("Resources Collected:")
    y = y + 1
    
    if stats.resources then
        for resource, count in pairs(stats.resources) do
            if y < height - 2 then
                mon.setCursorPos(4, y)
                local display_name = resource:gsub("minecraft:", ""):gsub("_", " ")
                mon.write(display_name .. ": " .. count)
                y = y + 1
            end
        end
    end
    
    -- Fleet efficiency
    y = y + 1
    if y < height - 2 then
        mon.setCursorPos(2, y)
        mon.write("Fleet Efficiency:")
        y = y + 1
        
        mon.setCursorPos(4, y)
        mon.write("Uptime: " .. string.format("%.1f%%", stats.uptime_percentage or 0))
        y = y + 1
        
        mon.setCursorPos(4, y)
        mon.write("Fuel Usage: " .. (stats.total_fuel_used or 0))
    end
end

-- Draw map view (if space permits)
local function drawMap(mon)
    local width, height = mon.getSize()
    
    if width < 30 or height < 15 then
        -- Too small for map
        mon.clear()
        mon.setCursorPos(2, 2)
        mon.write("Monitor too small for map view")
        return
    end
    
    drawHeader(mon, "Fleet Map")
    
    -- Get all turtle positions
    local turtles = Fleet.getAllTurtles()
    local positions = {}
    local min_x, max_x = math.huge, -math.huge
    local min_z, max_z = math.huge, -math.huge
    
    for id, turtle in pairs(turtles) do
        if turtle.position then
            local pos = turtle.position
            table.insert(positions, {
                id = id,
                x = pos.x,
                y = pos.y,
                z = pos.z,
                status = turtle.status
            })
            
            min_x = math.min(min_x, pos.x)
            max_x = math.max(max_x, pos.x)
            min_z = math.min(min_z, pos.z)
            max_z = math.max(max_z, pos.z)
        end
    end
    
    if #positions == 0 then
        mon.setCursorPos(2, 3)
        mon.write("No turtle positions available")
        return
    end
    
    -- Calculate scale
    local map_width = width - 4
    local map_height = height - 5
    local x_range = math.max(1, max_x - min_x)
    local z_range = math.max(1, max_z - min_z)
    local scale_x = map_width / x_range
    local scale_z = map_height / z_range
    local scale = math.min(scale_x, scale_z, 1)  -- Don't zoom in too much
    
    -- Draw border
    for y = 3, height - 2 do
        mon.setCursorPos(1, y)
        mon.write("|")
        mon.setCursorPos(width, y)
        mon.write("|")
    end
    
    mon.setCursorPos(1, 3)
    mon.write("+" .. string.rep("-", width - 2) .. "+")
    mon.setCursorPos(1, height - 2)
    mon.write("+" .. string.rep("-", width - 2) .. "+")
    
    -- Draw turtles
    local status_chars = {
        active = "*",
        idle = "o",
        offline = "x",
        error = "!"
    }
    
    local status_colors = {
        active = colors.green,
        idle = colors.yellow,
        offline = colors.red,
        error = colors.orange
    }
    
    for _, pos in ipairs(positions) do
        local map_x = math.floor((pos.x - min_x) * scale) + 2
        local map_z = math.floor((pos.z - min_z) * scale) + 4
        
        if map_x >= 2 and map_x < width and map_z >= 4 and map_z < height - 2 then
            mon.setCursorPos(map_x, map_z)
            
            if mon.isColor() then
                mon.setTextColor(status_colors[pos.status] or colors.white)
            end
            
            mon.write(status_chars[pos.status] or "?")
            
            if mon.isColor() then
                mon.setTextColor(colors.white)
            end
        end
    end
    
    -- Draw legend
    mon.setCursorPos(2, height - 1)
    mon.write("Scale: 1:" .. math.ceil(1/scale))
    
    mon.setCursorPos(width - 20, height - 1)
    mon.write("*=Active o=Idle x=Offline")
end

-- Update monitor display
local function updateDisplay()
    if not active_display or not active_display.monitor then
        return
    end
    
    local mon = active_display.monitor
    mon.clear()
    
    -- Draw based on current mode
    if display_mode == "overview" then
        drawOverview(mon)
    elseif display_mode == "turtle_list" then
        drawTurtleList(mon)
    elseif display_mode == "statistics" then
        drawStatistics(mon)
    elseif display_mode == "map" then
        drawMap(mon)
    end
end

-- Cycle display modes
function Monitor.cycleDisplay()
    local modes = {"overview", "turtle_list", "statistics", "map"}
    local current_index = 1
    
    for i, mode in ipairs(modes) do
        if mode == display_mode then
            current_index = i
            break
        end
    end
    
    display_mode = modes[(current_index % #modes) + 1]
    updateDisplay()
    
    Core.info("Monitor display mode: " .. display_mode)
end

-- Set display mode
function Monitor.setDisplayMode(mode)
    local valid_modes = {overview=true, turtle_list=true, statistics=true, map=true}
    
    if valid_modes[mode] then
        display_mode = mode
        updateDisplay()
        return true
    end
    
    return false, "Invalid display mode"
end

-- Get available monitors
function Monitor.getMonitors()
    local monitor_info = {}
    
    for _, mon_data in ipairs(monitors) do
        local w, h = mon_data.monitor.getSize()
        table.insert(monitor_info, {
            side = mon_data.side,
            width = w,
            height = h,
            color = mon_data.monitor.isColor(),
            active = mon_data == active_display
        })
    end
    
    return monitor_info
end

-- Select monitor by side/name
function Monitor.selectMonitor(side)
    for _, mon_data in ipairs(monitors) do
        if mon_data.side == side then
            active_display = mon_data
            updateDisplay()
            Core.info("Selected monitor on " .. side)
            return true
        end
    end
    
    return false, "Monitor not found"
end

-- Initialize module
function Monitor.init()
    if initialized then
        return true
    end
    
    Core.debug("Initializing Monitor module")
    
    -- Find connected monitors
    if not findMonitors() then
        Core.warn("No monitors found")
        return true  -- Not an error, just no monitors
    end
    
    -- Select the best monitor
    active_display = selectBestMonitor()
    
    if active_display then
        Core.info("Using monitor on " .. active_display.side)
        
        -- Set up the monitor
        local mon = active_display.monitor
        mon.setTextScale(1)
        if mon.isColor() then
            mon.setBackgroundColor(colors.black)
            mon.setTextColor(colors.white)
        end
        mon.clear()
        
        -- Initial display
        updateDisplay()
        
        -- Start refresh timer
        refresh_timer = os.startTimer(refresh_interval)
    end
    
    -- Register event handlers
    Core.on("fleet_update", function()
        updateDisplay()
    end)
    
    Core.on("timer", function(timer_id)
        if timer_id == refresh_timer then
            updateDisplay()
            refresh_timer = os.startTimer(refresh_interval)
        end
    end)
    
    Core.on("monitor_resize", function(side)
        -- Handle monitor resize
        for _, mon_data in ipairs(monitors) do
            if mon_data.side == side then
                mon_data.width, mon_data.height = mon_data.monitor.getSize()
                if mon_data == active_display then
                    updateDisplay()
                end
                break
            end
        end
    end)
    
    Core.on("peripheral", function(side)
        -- New peripheral attached
        if peripheral.getType(side) == "monitor" then
            Core.info("New monitor attached: " .. side)
            findMonitors()
            
            -- If we didn't have a monitor before, use this one
            if not active_display then
                active_display = selectBestMonitor()
                if active_display then
                    updateDisplay()
                end
            end
        end
    end)
    
    Core.on("peripheral_detach", function(side)
        -- Peripheral removed
        for i, mon_data in ipairs(monitors) do
            if mon_data.side == side then
                table.remove(monitors, i)
                
                -- If this was our active display, find another
                if mon_data == active_display then
                    active_display = selectBestMonitor()
                    if active_display then
                        updateDisplay()
                    else
                        Core.warn("Active monitor disconnected")
                    end
                end
                break
            end
        end
    end)
    
    initialized = true
    Core.info("Monitor module initialized")
    return true
end

-- Shutdown module
function Monitor.shutdown()
    if not initialized then
        return true
    end
    
    Core.debug("Shutting down Monitor module")
    
    -- Cancel refresh timer
    if refresh_timer then
        os.cancelTimer(refresh_timer)
        refresh_timer = nil
    end
    
    -- Clear monitors
    if active_display and active_display.monitor then
        active_display.monitor.clear()
    end
    
    monitors = {}
    active_display = nil
    initialized = false
    
    return true
end

return Monitor