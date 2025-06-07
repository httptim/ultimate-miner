-- Fleet Overview Screen
-- Displays detailed information about all turtles in the fleet

local FleetOverview = {}

-- Dependencies
local Core = require("control.modules.core")
local UI = require("control.modules.ui")
local Fleet = require("control.modules.fleet")
local Network = require("control.modules.network")
local CONSTANTS = require("shared.constants")

-- Screen state
local selected_turtle = 1
local scroll_offset = 0
local sort_by = "id"  -- id, name, status, fuel, position
local filter_status = "all"  -- all, active, idle, offline, error

-- Get sorted turtle list
local function getSortedTurtles()
    local turtles = Fleet.getAllTurtles()
    local turtle_list = {}
    
    -- Convert to list and apply filter
    for id, turtle in pairs(turtles) do
        if filter_status == "all" or turtle.status == filter_status then
            turtle.id = id
            table.insert(turtle_list, turtle)
        end
    end
    
    -- Sort list
    table.sort(turtle_list, function(a, b)
        if sort_by == "id" then
            return a.id < b.id
        elseif sort_by == "name" then
            return (a.name or "") < (b.name or "")
        elseif sort_by == "status" then
            return a.status < b.status
        elseif sort_by == "fuel" then
            return (a.fuel_level or 0) > (b.fuel_level or 0)
        elseif sort_by == "position" then
            local pos_a = a.position or {x=0, y=0, z=0}
            local pos_b = b.position or {x=0, y=0, z=0}
            return pos_a.y < pos_b.y  -- Sort by depth
        end
    end)
    
    return turtle_list
end

-- Draw turtle list
local function drawTurtleList(x, y, width, height)
    local turtles = getSortedTurtles()
    local visible_count = height - 2  -- Account for header and border
    
    -- Draw header
    UI.drawBox(x, y, width, height, "Fleet Overview")
    
    -- Column headers
    term.setCursorPos(x + 2, y + 2)
    write("ID")
    term.setCursorPos(x + 8, y + 2)
    write("Name")
    term.setCursorPos(x + 25, y + 2)
    write("Status")
    term.setCursorPos(x + 35, y + 2)
    write("Fuel")
    term.setCursorPos(x + 42, y + 2)
    write("Position")
    
    -- Draw separator
    term.setCursorPos(x + 1, y + 3)
    write(string.rep("-", width - 2))
    
    -- Draw turtle entries
    for i = 1, math.min(visible_count, #turtles - scroll_offset) do
        local turtle = turtles[scroll_offset + i]
        if turtle then
            local row_y = y + 3 + i
            
            -- Highlight selected
            if scroll_offset + i == selected_turtle then
                UI.setColors(colors.black, colors.white)
                term.setCursorPos(x + 1, row_y)
                write(string.rep(" ", width - 2))
            else
                UI.setColors(colors.white, colors.black)
            end
            
            -- Draw turtle info
            term.setCursorPos(x + 2, row_y)
            write(string.format("%-5d", turtle.id))
            
            term.setCursorPos(x + 8, row_y)
            write(string.sub(turtle.name or "Turtle-" .. turtle.id, 1, 15))
            
            -- Status with color
            term.setCursorPos(x + 25, row_y)
            local status_color = colors.white
            if turtle.status == "active" then
                status_color = colors.green
            elseif turtle.status == "idle" then
                status_color = colors.yellow
            elseif turtle.status == "offline" then
                status_color = colors.red
            elseif turtle.status == "error" then
                status_color = colors.orange
            end
            
            if term.isColor() then
                term.setTextColor(status_color)
            end
            write(string.format("%-8s", turtle.status or "unknown"))
            
            if term.isColor() then
                term.setTextColor(colors.white)
            end
            
            -- Fuel level
            term.setCursorPos(x + 35, row_y)
            local fuel = turtle.fuel_level or 0
            if fuel == "unlimited" then
                write("Unlim")
            else
                write(string.format("%-5d", fuel))
            end
            
            -- Position
            term.setCursorPos(x + 42, row_y)
            if turtle.position then
                write(string.format("%d,%d,%d", 
                    turtle.position.x or 0,
                    turtle.position.y or 0,
                    turtle.position.z or 0))
            else
                write("Unknown")
            end
        end
    end
    
    -- Reset colors
    UI.setColors(colors.white, colors.black)
    
    -- Scroll indicators
    if scroll_offset > 0 then
        term.setCursorPos(x + width - 3, y + 4)
        write("^")
    end
    
    if scroll_offset + visible_count < #turtles then
        term.setCursorPos(x + width - 3, y + height - 1)
        write("v")
    end
end

-- Draw turtle details
local function drawTurtleDetails(x, y, width, height)
    UI.drawBox(x, y, width, height, "Turtle Details")
    
    local turtles = getSortedTurtles()
    local turtle = turtles[selected_turtle]
    
    if not turtle then
        term.setCursorPos(x + 2, y + 2)
        write("No turtle selected")
        return
    end
    
    local row = y + 2
    
    -- Basic info
    term.setCursorPos(x + 2, row)
    write("ID: " .. turtle.id)
    row = row + 1
    
    term.setCursorPos(x + 2, row)
    write("Name: " .. (turtle.name or "Turtle-" .. turtle.id))
    row = row + 1
    
    term.setCursorPos(x + 2, row)
    write("Status: " .. (turtle.status or "unknown"))
    row = row + 2
    
    -- Position
    term.setCursorPos(x + 2, row)
    if turtle.position then
        write(string.format("Position: %d, %d, %d", 
            turtle.position.x or 0,
            turtle.position.y or 0,
            turtle.position.z or 0))
    else
        write("Position: Unknown")
    end
    row = row + 1
    
    term.setCursorPos(x + 2, row)
    write("Facing: " .. (turtle.facing or "unknown"))
    row = row + 2
    
    -- Resources
    term.setCursorPos(x + 2, row)
    local fuel = turtle.fuel_level or 0
    if fuel == "unlimited" then
        write("Fuel: Unlimited")
    else
        write("Fuel: " .. fuel .. "/" .. (turtle.fuel_limit or "?"))
    end
    row = row + 1
    
    term.setCursorPos(x + 2, row)
    write("Inventory: " .. (16 - (turtle.free_slots or 16)) .. "/16 slots")
    row = row + 2
    
    -- Current task
    term.setCursorPos(x + 2, row)
    if turtle.current_task then
        write("Task: " .. (turtle.current_task.type or "unknown"))
        row = row + 1
        
        if turtle.current_task.progress then
            term.setCursorPos(x + 2, row)
            write("Progress: " .. turtle.current_task.progress .. "%")
        end
    else
        write("Task: None")
    end
    row = row + 2
    
    -- Statistics
    if turtle.stats then
        term.setCursorPos(x + 2, row)
        write("Blocks Mined: " .. (turtle.stats.blocks_mined or 0))
        row = row + 1
        
        term.setCursorPos(x + 2, row)
        write("Ores Found: " .. (turtle.stats.ores_found or 0))
        row = row + 1
        
        term.setCursorPos(x + 2, row)
        write("Distance: " .. (turtle.stats.distance_traveled or 0))
    end
end

-- Draw controls
local function drawControls(x, y, width, height)
    UI.drawBox(x, y, width, height, "Controls")
    
    local controls = {
        {"Up/Down", "Select turtle"},
        {"Enter", "Control turtle"},
        {"S", "Sort options"},
        {"F", "Filter status"},
        {"R", "Refresh"},
        {"C", "Send command"},
        {"E", "Emergency stop"},
        {"B", "Back to menu"}
    }
    
    local row = y + 2
    for _, control in ipairs(controls) do
        term.setCursorPos(x + 2, row)
        UI.setColors(colors.yellow, colors.black)
        write(control[1])
        UI.setColors(colors.white, colors.black)
        write(" - " .. control[2])
        row = row + 1
    end
end

-- Handle input
function FleetOverview.handleInput(event, key, x, y)
    local turtles = getSortedTurtles()
    
    if event == "key" then
        if key == keys.up then
            if selected_turtle > 1 then
                selected_turtle = selected_turtle - 1
                -- Adjust scroll
                if selected_turtle <= scroll_offset then
                    scroll_offset = math.max(0, selected_turtle - 1)
                end
            end
            return true
        elseif key == keys.down then
            if selected_turtle < #turtles then
                selected_turtle = selected_turtle + 1
                -- Adjust scroll
                local visible_height = UI.getHeight() - 10
                if selected_turtle > scroll_offset + visible_height then
                    scroll_offset = selected_turtle - visible_height
                end
            end
            return true
        elseif key == keys.enter then
            -- Switch to individual turtle control
            local turtle = turtles[selected_turtle]
            if turtle then
                return "turtle_control", {turtle_id = turtle.id}
            end
        elseif key == keys.s then
            -- Cycle sort options
            local sort_options = {"id", "name", "status", "fuel", "position"}
            local current_index = 1
            for i, option in ipairs(sort_options) do
                if option == sort_by then
                    current_index = i
                    break
                end
            end
            sort_by = sort_options[(current_index % #sort_options) + 1]
            selected_turtle = 1
            scroll_offset = 0
            return true
        elseif key == keys.f then
            -- Cycle filter options
            local filter_options = {"all", "active", "idle", "offline", "error"}
            local current_index = 1
            for i, option in ipairs(filter_options) do
                if option == filter_status then
                    current_index = i
                    break
                end
            end
            filter_status = filter_options[(current_index % #filter_options) + 1]
            selected_turtle = 1
            scroll_offset = 0
            return true
        elseif key == keys.r then
            -- Refresh fleet status
            Fleet.requestStatusUpdate()
            return true
        elseif key == keys.c then
            -- Send command to selected turtle
            local turtle = turtles[selected_turtle]
            if turtle then
                return "fleet_commands", {selected_turtles = {turtle.id}}
            end
        elseif key == keys.e then
            -- Emergency stop
            Fleet.emergencyStopAll()
            Core.info("Emergency stop sent to all turtles")
            return true
        elseif key == keys.b then
            -- Back to dashboard
            return "back"
        end
    elseif event == "mouse_click" then
        -- Handle mouse clicks on turtle list
        local list_y_start = 5
        local list_height = UI.getHeight() - 10
        
        if y >= list_y_start and y < list_y_start + list_height then
            local clicked_index = scroll_offset + (y - list_y_start) + 1
            if clicked_index <= #turtles then
                selected_turtle = clicked_index
                return true
            end
        end
    end
    
    return false
end

-- Draw screen
function FleetOverview.draw()
    local width, height = UI.getWidth(), UI.getHeight()
    
    -- Clear screen
    UI.clear()
    
    -- Draw header
    UI.drawHeader("Fleet Overview - " .. #getSortedTurtles() .. " turtles")
    
    -- Layout
    local list_width = math.floor(width * 0.6)
    local details_width = width - list_width - 1
    
    -- Draw sections
    drawTurtleList(1, 3, list_width, height - 10)
    drawTurtleDetails(list_width + 1, 3, details_width, height - 20)
    drawControls(list_width + 1, height - 17, details_width, 10)
    
    -- Draw footer
    UI.drawFooter("Sort: " .. sort_by .. " | Filter: " .. filter_status)
end

-- Initialize screen
function FleetOverview.init()
    selected_turtle = 1
    scroll_offset = 0
    
    -- Request fresh status
    Fleet.requestStatusUpdate()
    
    return true
end

-- Cleanup
function FleetOverview.cleanup()
    -- Nothing to cleanup
end

return FleetOverview