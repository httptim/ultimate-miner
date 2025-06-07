-- Individual Turtle Control Screen
-- Direct control interface for a single turtle

local TurtleControl = {}

-- Dependencies
local Core = require("control.modules.core")
local UI = require("control.modules.ui")
local Fleet = require("control.modules.fleet")
local Commands = require("control.modules.commands")
local Network = require("control.modules.network")
local CONSTANTS = require("shared.constants")

-- Screen state
local turtle_id = nil
local turtle_data = nil
local selected_option = 1
local command_history = {}
local max_history = 50
local auto_refresh = true
local last_update = 0

-- Menu options
local menu_options = {
    {name = "Movement Control", action = "movement"},
    {name = "Mining Operations", action = "mining"},
    {name = "Inventory Management", action = "inventory"},
    {name = "Send Custom Command", action = "custom"},
    {name = "View Logs", action = "logs"},
    {name = "Emergency Stop", action = "stop"},
    {name = "Recall to Base", action = "recall"},
    {name = "Toggle Auto-Refresh", action = "toggle_refresh"},
    {name = "Back to Fleet Overview", action = "back"}
}

-- Draw turtle status
local function drawStatus(x, y, width, height)
    UI.drawBox(x, y, width, height, "Turtle #" .. turtle_id .. " Status")
    
    if not turtle_data then
        term.setCursorPos(x + 2, y + 2)
        write("No data available")
        return
    end
    
    local row = y + 2
    
    -- Basic info
    term.setCursorPos(x + 2, row)
    write("Name: " .. (turtle_data.name or "Turtle-" .. turtle_id))
    row = row + 1
    
    -- Status with color
    term.setCursorPos(x + 2, row)
    write("Status: ")
    local status_color = colors.white
    if turtle_data.status == "active" then
        status_color = colors.green
    elseif turtle_data.status == "idle" then
        status_color = colors.yellow
    elseif turtle_data.status == "offline" then
        status_color = colors.red
    elseif turtle_data.status == "error" then
        status_color = colors.orange
    end
    
    if term.isColor() then
        term.setTextColor(status_color)
    end
    write(turtle_data.status or "unknown")
    if term.isColor() then
        term.setTextColor(colors.white)
    end
    row = row + 2
    
    -- Position
    term.setCursorPos(x + 2, row)
    if turtle_data.position then
        write(string.format("Position: X:%d Y:%d Z:%d", 
            turtle_data.position.x or 0,
            turtle_data.position.y or 0,
            turtle_data.position.z or 0))
    else
        write("Position: Unknown")
    end
    row = row + 1
    
    term.setCursorPos(x + 2, row)
    write("Facing: " .. (turtle_data.facing or "unknown"))
    row = row + 2
    
    -- Resources
    term.setCursorPos(x + 2, row)
    local fuel = turtle_data.fuel_level or 0
    if fuel == "unlimited" then
        write("Fuel: Unlimited")
    else
        local fuel_percent = 0
        if turtle_data.fuel_limit and turtle_data.fuel_limit > 0 then
            fuel_percent = math.floor((fuel / turtle_data.fuel_limit) * 100)
        end
        write(string.format("Fuel: %d/%d (%d%%)", 
            fuel, 
            turtle_data.fuel_limit or 0,
            fuel_percent))
    end
    row = row + 1
    
    term.setCursorPos(x + 2, row)
    local used_slots = 16 - (turtle_data.free_slots or 16)
    local inventory_percent = math.floor((used_slots / 16) * 100)
    write(string.format("Inventory: %d/16 slots (%d%%)", used_slots, inventory_percent))
    row = row + 2
    
    -- Current task
    term.setCursorPos(x + 2, row)
    if turtle_data.current_task then
        write("Current Task:")
        row = row + 1
        term.setCursorPos(x + 4, row)
        write("Type: " .. (turtle_data.current_task.type or "unknown"))
        row = row + 1
        
        if turtle_data.current_task.description then
            term.setCursorPos(x + 4, row)
            write("Desc: " .. string.sub(turtle_data.current_task.description, 1, width - 8))
            row = row + 1
        end
        
        if turtle_data.current_task.progress then
            term.setCursorPos(x + 4, row)
            write("Progress: " .. turtle_data.current_task.progress .. "%")
            row = row + 1
        end
    else
        write("Current Task: None")
        row = row + 1
    end
    row = row + 1
    
    -- Last update
    term.setCursorPos(x + 2, row)
    local time_since = os.epoch("utc") - (turtle_data.last_update or os.epoch("utc"))
    write("Last Update: " .. math.floor(time_since / 1000) .. "s ago")
    
    -- Auto-refresh indicator
    if auto_refresh then
        term.setCursorPos(x + width - 12, row)
        if term.isColor() then
            term.setTextColor(colors.green)
        end
        write("[AUTO-REFRESH]")
        if term.isColor() then
            term.setTextColor(colors.white)
        end
    end
end

-- Draw command menu
local function drawMenu(x, y, width, height)
    UI.drawBox(x, y, width, height, "Commands")
    
    local visible_items = height - 2
    local start_index = math.max(1, selected_option - visible_items + 1)
    local end_index = math.min(#menu_options, start_index + visible_items - 1)
    
    for i = start_index, end_index do
        local option = menu_options[i]
        local row = y + 1 + (i - start_index)
        
        term.setCursorPos(x + 2, row)
        if i == selected_option then
            UI.setColors(colors.black, colors.white)
            write("> " .. option.name .. string.rep(" ", width - 4 - #option.name))
        else
            UI.setColors(colors.white, colors.black)
            write("  " .. option.name)
        end
    end
    
    UI.setColors(colors.white, colors.black)
end

-- Draw command history
local function drawHistory(x, y, width, height)
    UI.drawBox(x, y, width, height, "Command History")
    
    local visible_items = height - 2
    local start_index = math.max(1, #command_history - visible_items + 1)
    
    for i = start_index, #command_history do
        local entry = command_history[i]
        local row = y + 1 + (i - start_index)
        
        term.setCursorPos(x + 2, row)
        
        -- Time
        if term.isColor() then
            term.setTextColor(colors.gray)
        end
        write(os.date("%H:%M ", entry.time))
        
        -- Command
        if term.isColor() then
            term.setTextColor(colors.yellow)
        end
        write(entry.command .. " ")
        
        -- Result
        if term.isColor() then
            if entry.success then
                term.setTextColor(colors.green)
            else
                term.setTextColor(colors.red)
            end
        end
        
        local result_text = entry.result
        local max_result_len = width - 15 - #entry.command
        if #result_text > max_result_len then
            result_text = string.sub(result_text, 1, max_result_len - 3) .. "..."
        end
        write(result_text)
    end
    
    if term.isColor() then
        term.setTextColor(colors.white)
    end
end

-- Execute menu action
local function executeAction(action)
    if action == "movement" then
        -- Movement control submenu
        return "movement_control", {turtle_id = turtle_id}
    elseif action == "mining" then
        -- Mining operations submenu
        return "mining_operations", {turtle_id = turtle_id}
    elseif action == "inventory" then
        -- Inventory management submenu
        return "inventory_management", {turtle_id = turtle_id}
    elseif action == "custom" then
        -- Custom command input
        UI.drawFooter("Enter command (or ESC to cancel):")
        term.setCursorPos(1, UI.getHeight())
        local input = read()
        
        if input and input ~= "" then
            local success, result = Commands.sendToTurtle(turtle_id, {
                type = "custom",
                command = input
            })
            
            table.insert(command_history, {
                time = os.epoch("utc") / 1000,
                command = input,
                success = success,
                result = result or "No response"
            })
            
            if #command_history > max_history then
                table.remove(command_history, 1)
            end
        end
        return true
    elseif action == "logs" then
        -- View turtle logs
        return "turtle_logs", {turtle_id = turtle_id}
    elseif action == "stop" then
        -- Emergency stop
        local success, result = Commands.sendToTurtle(turtle_id, {
            type = "emergency_stop"
        })
        
        table.insert(command_history, {
            time = os.epoch("utc") / 1000,
            command = "Emergency Stop",
            success = success,
            result = result or "Sent"
        })
        
        if #command_history > max_history then
            table.remove(command_history, 1)
        end
        return true
    elseif action == "recall" then
        -- Recall to base
        local success, result = Commands.sendToTurtle(turtle_id, {
            type = "recall_base"
        })
        
        table.insert(command_history, {
            time = os.epoch("utc") / 1000,
            command = "Recall to Base",
            success = success,
            result = result or "Sent"
        })
        
        if #command_history > max_history then
            table.remove(command_history, 1)
        end
        return true
    elseif action == "toggle_refresh" then
        -- Toggle auto-refresh
        auto_refresh = not auto_refresh
        return true
    elseif action == "back" then
        -- Back to fleet overview
        return "back"
    end
    
    return false
end

-- Handle input
function TurtleControl.handleInput(event, key, x, y)
    if event == "key" then
        if key == keys.up then
            if selected_option > 1 then
                selected_option = selected_option - 1
            end
            return true
        elseif key == keys.down then
            if selected_option < #menu_options then
                selected_option = selected_option + 1
            end
            return true
        elseif key == keys.enter then
            local option = menu_options[selected_option]
            return executeAction(option.action)
        elseif key == keys.r then
            -- Manual refresh
            Fleet.requestTurtleStatus(turtle_id)
            return true
        elseif key == keys.b or key == keys.backspace then
            return "back"
        end
    elseif event == "mouse_click" then
        -- Check if clicked on menu
        local menu_y_start = 3
        local menu_height = math.floor(UI.getHeight() * 0.4)
        
        if x <= math.floor(UI.getWidth() * 0.5) and 
           y >= menu_y_start and 
           y < menu_y_start + menu_height then
            local clicked_option = y - menu_y_start
            if clicked_option >= 1 and clicked_option <= #menu_options then
                selected_option = clicked_option
                return executeAction(menu_options[selected_option].action)
            end
        end
    end
    
    return false
end

-- Draw screen
function TurtleControl.draw()
    local width, height = UI.getWidth(), UI.getHeight()
    
    -- Clear screen
    UI.clear()
    
    -- Draw header
    UI.drawHeader("Turtle Control - #" .. turtle_id)
    
    -- Layout
    local menu_height = math.floor(height * 0.4)
    local status_width = math.floor(width * 0.5)
    local history_height = height - menu_height - 3
    
    -- Draw sections
    drawStatus(status_width + 1, 3, width - status_width, height - 3)
    drawMenu(1, 3, status_width, menu_height)
    drawHistory(1, menu_height + 3, status_width, history_height)
    
    -- Update turtle data if auto-refresh is on
    if auto_refresh and os.epoch("utc") - last_update > 5000 then
        Fleet.requestTurtleStatus(turtle_id)
        last_update = os.epoch("utc")
    end
end

-- Initialize screen
function TurtleControl.init(data)
    if not data or not data.turtle_id then
        return false, "No turtle ID provided"
    end
    
    turtle_id = data.turtle_id
    turtle_data = Fleet.getTurtle(turtle_id)
    selected_option = 1
    command_history = {}
    auto_refresh = true
    last_update = os.epoch("utc")
    
    -- Request fresh status
    Fleet.requestTurtleStatus(turtle_id)
    
    -- Register for turtle updates
    Core.on("turtle_update", function(event_data)
        if event_data.id == turtle_id then
            turtle_data = event_data.data
        end
    end)
    
    return true
end

-- Cleanup
function TurtleControl.cleanup()
    -- Unregister event listener
    Core.removeListener("turtle_update")
end

return TurtleControl