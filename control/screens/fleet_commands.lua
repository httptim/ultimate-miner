-- Fleet Commands Screen
-- Interface for sending commands to multiple turtles

local FleetCommands = {}

-- Dependencies
local Core = require("control.modules.core")
local UI = require("control.modules.ui")
local Fleet = require("control.modules.fleet")
local Commands = require("control.modules.commands")
local CONSTANTS = require("shared.constants")

-- Screen state
local selected_turtles = {}
local command_category = 1
local selected_command = 1
local command_params = {}
local execution_results = {}

-- Command categories
local command_categories = {
    {
        name = "Movement",
        commands = {
            {name = "Move Forward", type = "move", direction = "forward"},
            {name = "Move Back", type = "move", direction = "back"},
            {name = "Move Up", type = "move", direction = "up"},
            {name = "Move Down", type = "move", direction = "down"},
            {name = "Turn Left", type = "turn", direction = "left"},
            {name = "Turn Right", type = "turn", direction = "right"},
            {name = "Go to Position", type = "goto", needs_params = true},
            {name = "Return Home", type = "return_home"}
        }
    },
    {
        name = "Mining",
        commands = {
            {name = "Strip Mine", type = "mine", pattern = "strip", needs_params = true},
            {name = "Branch Mine", type = "mine", pattern = "branch", needs_params = true},
            {name = "Quarry", type = "mine", pattern = "quarry", needs_params = true},
            {name = "Tunnel 3x3", type = "mine", pattern = "tunnel3x3", needs_params = true},
            {name = "Mine Block", type = "dig", direction = "forward"},
            {name = "Mine Vein", type = "mine_vein"},
            {name = "Stop Mining", type = "stop_mining"}
        }
    },
    {
        name = "Control",
        commands = {
            {name = "Emergency Stop", type = "emergency_stop"},
            {name = "Pause Operations", type = "pause"},
            {name = "Resume Operations", type = "resume"},
            {name = "Refuel", type = "refuel"},
            {name = "Deposit Items", type = "deposit"},
            {name = "Update Status", type = "status_update"},
            {name = "Reboot", type = "reboot"}
        }
    },
    {
        name = "Configuration",
        commands = {
            {name = "Set Home Position", type = "set_home"},
            {name = "Set Mining Pattern", type = "set_pattern", needs_params = true},
            {name = "Enable Vein Mining", type = "config", key = "vein_mining", value = true},
            {name = "Disable Vein Mining", type = "config", key = "vein_mining", value = false},
            {name = "Set Torch Interval", type = "config", key = "torch_interval", needs_params = true},
            {name = "Enable Debug Mode", type = "config", key = "debug_mode", value = true},
            {name = "Disable Debug Mode", type = "config", key = "debug_mode", value = false}
        }
    }
}

-- Get parameter input for command
local function getCommandParams(command)
    local params = {}
    
    UI.drawFooter("Enter parameters for " .. command.name)
    
    if command.type == "goto" then
        term.setCursorPos(1, UI.getHeight() - 2)
        write("X coordinate: ")
        params.x = tonumber(read()) or 0
        
        write("Y coordinate: ")
        params.y = tonumber(read()) or 0
        
        write("Z coordinate: ")
        params.z = tonumber(read()) or 0
        
    elseif command.type == "mine" then
        term.setCursorPos(1, UI.getHeight() - 2)
        
        if command.pattern == "strip" then
            write("Number of strips: ")
            params.strips = tonumber(read()) or 1
            
            write("Strip length: ")
            params.length = tonumber(read()) or 32
            
        elseif command.pattern == "branch" then
            write("Main tunnel length: ")
            params.main_length = tonumber(read()) or 100
            
            write("Branch length: ")
            params.branch_length = tonumber(read()) or 20
            
        elseif command.pattern == "quarry" then
            write("Width: ")
            params.width = tonumber(read()) or 16
            
            write("Length: ")
            params.length = tonumber(read()) or 16
            
            write("Depth (empty for bedrock): ")
            local depth_input = read()
            params.depth = depth_input ~= "" and tonumber(depth_input) or nil
            
        elseif command.pattern == "tunnel3x3" then
            write("Tunnel length: ")
            params.length = tonumber(read()) or 50
        end
        
    elseif command.type == "config" and command.key == "torch_interval" then
        write("Torch interval (blocks): ")
        params.value = tonumber(read()) or 8
        
    elseif command.type == "set_pattern" then
        write("Pattern (strip/branch/spiral/quarry): ")
        params.pattern = read() or "strip"
    end
    
    return params
end

-- Draw turtle selection
local function drawTurtleSelection(x, y, width, height)
    UI.drawBox(x, y, width, height, "Target Turtles")
    
    local row = y + 2
    
    -- Show selected turtles
    if #selected_turtles == 0 then
        term.setCursorPos(x + 2, row)
        write("All turtles in fleet")
    else
        term.setCursorPos(x + 2, row)
        write("Selected: " .. #selected_turtles .. " turtle(s)")
        row = row + 1
        
        -- List selected turtle IDs
        local id_list = {}
        for _, id in ipairs(selected_turtles) do
            table.insert(id_list, tostring(id))
        end
        
        term.setCursorPos(x + 2, row)
        local id_string = table.concat(id_list, ", ")
        if #id_string > width - 4 then
            id_string = string.sub(id_string, 1, width - 7) .. "..."
        end
        write(id_string)
    end
    
    row = row + 2
    term.setCursorPos(x + 2, row)
    UI.setColors(colors.gray, colors.black)
    write("Press T to select turtles")
    UI.setColors(colors.white, colors.black)
end

-- Draw command selection
local function drawCommandSelection(x, y, width, height)
    UI.drawBox(x, y, width, height, "Commands")
    
    local category = command_categories[command_category]
    local row = y + 2
    
    -- Category name
    term.setCursorPos(x + 2, row)
    UI.setColors(colors.yellow, colors.black)
    write("Category: " .. category.name)
    UI.setColors(colors.white, colors.black)
    row = row + 1
    
    term.setCursorPos(x + 2, row)
    UI.setColors(colors.gray, colors.black)
    write("Use < > to change category")
    UI.setColors(colors.white, colors.black)
    row = row + 2
    
    -- Commands
    local visible_commands = height - 6
    local start_idx = math.max(1, selected_command - visible_commands + 1)
    
    for i = start_idx, math.min(#category.commands, start_idx + visible_commands - 1) do
        local cmd = category.commands[i]
        term.setCursorPos(x + 2, row)
        
        if i == selected_command then
            UI.setColors(colors.black, colors.white)
            write("> " .. cmd.name .. string.rep(" ", width - 4 - #cmd.name))
        else
            UI.setColors(colors.white, colors.black)
            write("  " .. cmd.name)
        end
        
        row = row + 1
    end
    
    UI.setColors(colors.white, colors.black)
end

-- Draw execution results
local function drawResults(x, y, width, height)
    UI.drawBox(x, y, width, height, "Execution Results")
    
    if #execution_results == 0 then
        term.setCursorPos(x + 2, y + 2)
        write("No commands executed yet")
        return
    end
    
    local visible_results = height - 2
    local start_idx = math.max(1, #execution_results - visible_results + 1)
    local row = y + 2
    
    for i = start_idx, #execution_results do
        local result = execution_results[i]
        
        term.setCursorPos(x + 2, row)
        
        -- Time
        if term.isColor() then
            term.setTextColor(colors.gray)
        end
        write(os.date("%H:%M ", result.time))
        
        -- Command
        if term.isColor() then
            term.setTextColor(colors.yellow)
        end
        write(result.command .. " ")
        
        -- Target count
        if term.isColor() then
            term.setTextColor(colors.lightGray)
        end
        write("(" .. result.target_count .. ") ")
        
        -- Success rate
        if term.isColor() then
            if result.success_rate == 100 then
                term.setTextColor(colors.green)
            elseif result.success_rate > 50 then
                term.setTextColor(colors.yellow)
            else
                term.setTextColor(colors.red)
            end
        end
        write(result.success_rate .. "%")
        
        row = row + 1
    end
    
    if term.isColor() then
        term.setTextColor(colors.white)
    end
end

-- Execute command on selected turtles
local function executeCommand()
    local category = command_categories[command_category]
    local command = category.commands[selected_command]
    
    -- Get parameters if needed
    local params = command_params
    if command.needs_params then
        params = getCommandParams(command)
        if not params then
            return false
        end
    end
    
    -- Build command message
    local message = {
        type = command.type,
        timestamp = os.epoch("utc")
    }
    
    -- Add command-specific data
    for k, v in pairs(command) do
        if k ~= "name" and k ~= "needs_params" then
            message[k] = v
        end
    end
    
    -- Add parameters
    if params then
        for k, v in pairs(params) do
            message[k] = v
        end
    end
    
    -- Get target turtles
    local targets = selected_turtles
    if #targets == 0 then
        targets = Fleet.getAllTurtleIDs()
    end
    
    -- Send command
    local success_count = 0
    for _, turtle_id in ipairs(targets) do
        local success = Commands.sendToTurtle(turtle_id, message)
        if success then
            success_count = success_count + 1
        end
    end
    
    -- Record result
    table.insert(execution_results, {
        time = os.epoch("utc") / 1000,
        command = command.name,
        target_count = #targets,
        success_count = success_count,
        success_rate = math.floor((success_count / #targets) * 100)
    })
    
    -- Limit history
    if #execution_results > 50 then
        table.remove(execution_results, 1)
    end
    
    Core.info(string.format("Command sent to %d/%d turtles", success_count, #targets))
    return true
end

-- Handle input
function FleetCommands.handleInput(event, key, x, y)
    if event == "key" then
        if key == keys.up then
            if selected_command > 1 then
                selected_command = selected_command - 1
            end
            return true
        elseif key == keys.down then
            local category = command_categories[command_category]
            if selected_command < #category.commands then
                selected_command = selected_command + 1
            end
            return true
        elseif key == keys.left then
            if command_category > 1 then
                command_category = command_category - 1
                selected_command = 1
            end
            return true
        elseif key == keys.right then
            if command_category < #command_categories then
                command_category = command_category + 1
                selected_command = 1
            end
            return true
        elseif key == keys.enter then
            executeCommand()
            return true
        elseif key == keys.t then
            -- Turtle selection
            return "turtle_selection", {
                selected = selected_turtles,
                callback = function(new_selection)
                    selected_turtles = new_selection
                end
            }
        elseif key == keys.c then
            -- Clear results
            execution_results = {}
            return true
        elseif key == keys.b or key == keys.backspace then
            return "back"
        end
    elseif event == "mouse_click" then
        -- Check command list click
        local cmd_y_start = 7
        local category = command_categories[command_category]
        
        if x >= 2 and x <= UI.getWidth() / 2 and
           y >= cmd_y_start and y < cmd_y_start + #category.commands then
            selected_command = y - cmd_y_start + 1
            executeCommand()
            return true
        end
    end
    
    return false
end

-- Draw screen
function FleetCommands.draw()
    local width, height = UI.getWidth(), UI.getHeight()
    
    -- Clear screen
    UI.clear()
    
    -- Draw header
    UI.drawHeader("Fleet Commands")
    
    -- Layout
    local left_width = math.floor(width * 0.5)
    local right_width = width - left_width
    local top_height = 8
    
    -- Draw sections
    drawTurtleSelection(1, 3, left_width, top_height)
    drawCommandSelection(1, 3 + top_height, left_width, height - top_height - 3)
    drawResults(left_width + 1, 3, right_width, height - 3)
    
    -- Draw footer with controls
    UI.drawFooter("Up/Down: Select | </>: Category | Enter: Execute | T: Select Turtles | C: Clear | B: Back")
end

-- Initialize screen
function FleetCommands.init(data)
    selected_turtles = data and data.selected_turtles or {}
    command_category = 1
    selected_command = 1
    command_params = {}
    
    return true
end

-- Cleanup
function FleetCommands.cleanup()
    -- Nothing to cleanup
end

return FleetCommands