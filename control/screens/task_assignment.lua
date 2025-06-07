-- Task Assignment Screen
-- Create and assign mining tasks to turtles

local TaskAssignment = {}

-- Dependencies
local Core = require("control.modules.core")
local UI = require("control.modules.ui")
local Fleet = require("control.modules.fleet")
local Tasks = require("control.modules.tasks")
local CONSTANTS = require("shared.constants")

-- Screen state
local current_mode = "resource"  -- resource, area, pattern
local selected_field = 1
local task_config = {
    -- Resource targeting
    resource = {
        ore_type = "diamond",
        quantity = 64,
        priority = "normal"
    },
    -- Area mining
    area = {
        x1 = 0, y1 = -59, z1 = 0,
        x2 = 100, y2 = -40, z2 = 100,
        pattern = "strip"
    },
    -- Pattern mining
    pattern = {
        type = "strip",
        params = {
            strips = 5,
            length = 50,
            spacing = 3
        }
    },
    -- Assignment
    assignment = {
        mode = "auto",  -- auto, manual, balanced
        turtles = {}
    }
}

-- Task modes
local task_modes = {
    {id = "resource", name = "Resource Targeting", desc = "Mine specific resources"},
    {id = "area", name = "Area Mining", desc = "Mine within boundaries"},
    {id = "pattern", name = "Pattern Mining", desc = "Execute mining pattern"}
}

-- Resource types
local resource_types = {
    "diamond", "iron", "gold", "copper", "emerald",
    "redstone", "lapis", "coal", "ancient_debris", "any_ore"
}

-- Priority levels
local priority_levels = {
    {id = "low", name = "Low", color = colors.gray},
    {id = "normal", name = "Normal", color = colors.white},
    {id = "high", name = "High", color = colors.yellow},
    {id = "urgent", name = "Urgent", color = colors.red}
}

-- Mining patterns
local mining_patterns = {
    "strip", "branch", "spiral", "quarry", "tunnel3x3", "adaptive"
}

-- Draw mode selection
local function drawModeSelection(x, y, width, height)
    UI.drawBox(x, y, width, height, "Task Type")
    
    local row = y + 2
    for i, mode in ipairs(task_modes) do
        term.setCursorPos(x + 2, row)
        
        if mode.id == current_mode then
            UI.setColors(colors.black, colors.white)
            write("> " .. mode.name .. string.rep(" ", width - 4 - #mode.name))
        else
            UI.setColors(colors.white, colors.black)
            write("  " .. mode.name)
        end
        
        row = row + 1
        term.setCursorPos(x + 4, row)
        UI.setColors(colors.gray, colors.black)
        write(mode.desc)
        UI.setColors(colors.white, colors.black)
        row = row + 2
    end
end

-- Draw resource targeting config
local function drawResourceConfig(x, y, width, height)
    UI.drawBox(x, y, width, height, "Resource Targeting Configuration")
    
    local fields = {
        {name = "Ore Type", value = task_config.resource.ore_type},
        {name = "Quantity", value = tostring(task_config.resource.quantity)},
        {name = "Priority", value = task_config.resource.priority}
    }
    
    local row = y + 2
    for i, field in ipairs(fields) do
        term.setCursorPos(x + 2, row)
        
        if current_mode == "resource" and selected_field == i then
            UI.setColors(colors.black, colors.white)
        else
            UI.setColors(colors.white, colors.black)
        end
        
        write(field.name .. ": " .. field.value)
        
        if current_mode == "resource" and selected_field == i then
            write(string.rep(" ", width - 4 - #field.name - #field.value - 2))
        end
        
        row = row + 2
    end
    
    UI.setColors(colors.white, colors.black)
    
    -- Instructions
    row = row + 1
    term.setCursorPos(x + 2, row)
    UI.setColors(colors.gray, colors.black)
    write("Enter to edit, Tab to switch modes")
    UI.setColors(colors.white, colors.black)
end

-- Draw area mining config
local function drawAreaConfig(x, y, width, height)
    UI.drawBox(x, y, width, height, "Area Mining Configuration")
    
    local fields = {
        {name = "Start X", value = tostring(task_config.area.x1)},
        {name = "Start Y", value = tostring(task_config.area.y1)},
        {name = "Start Z", value = tostring(task_config.area.z1)},
        {name = "End X", value = tostring(task_config.area.x2)},
        {name = "End Y", value = tostring(task_config.area.y2)},
        {name = "End Z", value = tostring(task_config.area.z2)},
        {name = "Pattern", value = task_config.area.pattern}
    }
    
    local row = y + 2
    for i, field in ipairs(fields) do
        term.setCursorPos(x + 2, row)
        
        if current_mode == "area" and selected_field == i then
            UI.setColors(colors.black, colors.white)
        else
            UI.setColors(colors.white, colors.black)
        end
        
        write(field.name .. ": " .. field.value)
        
        if current_mode == "area" and selected_field == i then
            write(string.rep(" ", width - 4 - #field.name - #field.value - 2))
        end
        
        row = row + 1
    end
    
    UI.setColors(colors.white, colors.black)
    
    -- Area size calculation
    row = row + 1
    term.setCursorPos(x + 2, row)
    local volume = (task_config.area.x2 - task_config.area.x1 + 1) *
                   (task_config.area.y2 - task_config.area.y1 + 1) *
                   (task_config.area.z2 - task_config.area.z1 + 1)
    UI.setColors(colors.gray, colors.black)
    write("Volume: " .. volume .. " blocks")
    UI.setColors(colors.white, colors.black)
end

-- Draw pattern mining config
local function drawPatternConfig(x, y, width, height)
    UI.drawBox(x, y, width, height, "Pattern Mining Configuration")
    
    local row = y + 2
    
    -- Pattern type
    term.setCursorPos(x + 2, row)
    if current_mode == "pattern" and selected_field == 1 then
        UI.setColors(colors.black, colors.white)
    else
        UI.setColors(colors.white, colors.black)
    end
    write("Pattern: " .. task_config.pattern.type)
    if current_mode == "pattern" and selected_field == 1 then
        write(string.rep(" ", width - 4 - 9 - #task_config.pattern.type))
    end
    row = row + 2
    
    UI.setColors(colors.white, colors.black)
    
    -- Pattern-specific parameters
    if task_config.pattern.type == "strip" then
        local params = {
            {name = "Strips", value = tostring(task_config.pattern.params.strips)},
            {name = "Length", value = tostring(task_config.pattern.params.length)},
            {name = "Spacing", value = tostring(task_config.pattern.params.spacing)}
        }
        
        for i, param in ipairs(params) do
            term.setCursorPos(x + 2, row)
            
            if current_mode == "pattern" and selected_field == i + 1 then
                UI.setColors(colors.black, colors.white)
            else
                UI.setColors(colors.white, colors.black)
            end
            
            write(param.name .. ": " .. param.value)
            
            if current_mode == "pattern" and selected_field == i + 1 then
                write(string.rep(" ", width - 4 - #param.name - #param.value - 2))
            end
            
            row = row + 1
        end
    elseif task_config.pattern.type == "quarry" then
        local params = {
            {name = "Width", value = tostring(task_config.pattern.params.width or 16)},
            {name = "Length", value = tostring(task_config.pattern.params.length or 16)},
            {name = "Depth", value = task_config.pattern.params.depth and tostring(task_config.pattern.params.depth) or "Bedrock"}
        }
        
        for i, param in ipairs(params) do
            term.setCursorPos(x + 2, row)
            
            if current_mode == "pattern" and selected_field == i + 1 then
                UI.setColors(colors.black, colors.white)
            else
                UI.setColors(colors.white, colors.black)
            end
            
            write(param.name .. ": " .. param.value)
            
            if current_mode == "pattern" and selected_field == i + 1 then
                write(string.rep(" ", width - 4 - #param.name - #param.value - 2))
            end
            
            row = row + 1
        end
    end
    
    UI.setColors(colors.white, colors.black)
end

-- Draw assignment options
local function drawAssignment(x, y, width, height)
    UI.drawBox(x, y, width, height, "Task Assignment")
    
    local row = y + 2
    
    -- Assignment mode
    term.setCursorPos(x + 2, row)
    write("Mode: ")
    
    local modes = {"auto", "manual", "balanced"}
    for i, mode in ipairs(modes) do
        if mode == task_config.assignment.mode then
            UI.setColors(colors.black, colors.yellow)
        else
            UI.setColors(colors.white, colors.black)
        end
        write(" " .. mode .. " ")
        UI.setColors(colors.white, colors.black)
    end
    row = row + 2
    
    -- Available turtles
    term.setCursorPos(x + 2, row)
    local available = Fleet.getAvailableTurtles()
    write("Available: " .. #available .. " turtles")
    row = row + 1
    
    -- Selected turtles (for manual mode)
    if task_config.assignment.mode == "manual" then
        term.setCursorPos(x + 2, row)
        write("Selected: " .. #task_config.assignment.turtles .. " turtles")
        
        if #task_config.assignment.turtles > 0 then
            row = row + 1
            term.setCursorPos(x + 4, row)
            UI.setColors(colors.gray, colors.black)
            local turtle_list = table.concat(task_config.assignment.turtles, ", ")
            if #turtle_list > width - 6 then
                turtle_list = string.sub(turtle_list, 1, width - 9) .. "..."
            end
            write(turtle_list)
            UI.setColors(colors.white, colors.black)
        end
    end
    
    row = row + 2
    
    -- Create button
    local button_text = " Create Task "
    local button_x = x + math.floor((width - #button_text) / 2)
    term.setCursorPos(button_x, row)
    UI.setColors(colors.black, colors.green)
    write(button_text)
    UI.setColors(colors.white, colors.black)
    
    -- Instructions
    row = row + 2
    term.setCursorPos(x + 2, row)
    UI.setColors(colors.gray, colors.black)
    if task_config.assignment.mode == "manual" then
        write("Press S to select turtles")
    end
    UI.setColors(colors.white, colors.black)
end

-- Edit field value
local function editField()
    UI.drawFooter("Enter new value (ESC to cancel):")
    term.setCursorPos(1, UI.getHeight())
    
    local new_value = read()
    if not new_value or new_value == "" then
        return
    end
    
    if current_mode == "resource" then
        if selected_field == 1 then
            -- Ore type - validate
            for _, ore in ipairs(resource_types) do
                if ore == new_value then
                    task_config.resource.ore_type = new_value
                    break
                end
            end
        elseif selected_field == 2 then
            -- Quantity
            local num = tonumber(new_value)
            if num and num > 0 then
                task_config.resource.quantity = num
            end
        elseif selected_field == 3 then
            -- Priority
            for _, priority in ipairs(priority_levels) do
                if priority.id == new_value then
                    task_config.resource.priority = new_value
                    break
                end
            end
        end
    elseif current_mode == "area" then
        if selected_field <= 6 then
            -- Coordinates
            local num = tonumber(new_value)
            if num then
                local fields = {"x1", "y1", "z1", "x2", "y2", "z2"}
                task_config.area[fields[selected_field]] = num
            end
        elseif selected_field == 7 then
            -- Pattern
            for _, pattern in ipairs(mining_patterns) do
                if pattern == new_value then
                    task_config.area.pattern = new_value
                    break
                end
            end
        end
    elseif current_mode == "pattern" then
        if selected_field == 1 then
            -- Pattern type
            for _, pattern in ipairs(mining_patterns) do
                if pattern == new_value then
                    task_config.pattern.type = new_value
                    -- Reset params
                    task_config.pattern.params = {}
                    break
                end
            end
        else
            -- Pattern parameters
            local num = tonumber(new_value)
            if num and num > 0 then
                if task_config.pattern.type == "strip" then
                    local params = {"strips", "length", "spacing"}
                    task_config.pattern.params[params[selected_field - 1]] = num
                elseif task_config.pattern.type == "quarry" then
                    local params = {"width", "length", "depth"}
                    if selected_field - 1 <= #params then
                        task_config.pattern.params[params[selected_field - 1]] = num
                    end
                end
            end
        end
    end
end

-- Create task
local function createTask()
    local task = {
        type = current_mode,
        created_at = os.epoch("utc"),
        status = "pending"
    }
    
    -- Add mode-specific data
    if current_mode == "resource" then
        task.ore_type = task_config.resource.ore_type
        task.quantity = task_config.resource.quantity
        task.priority = task_config.resource.priority
    elseif current_mode == "area" then
        task.area = {
            x1 = task_config.area.x1,
            y1 = task_config.area.y1,
            z1 = task_config.area.z1,
            x2 = task_config.area.x2,
            y2 = task_config.area.y2,
            z2 = task_config.area.z2
        }
        task.pattern = task_config.area.pattern
    elseif current_mode == "pattern" then
        task.pattern = task_config.pattern.type
        task.params = task_config.pattern.params
    end
    
    -- Get assigned turtles
    local assigned_turtles = {}
    if task_config.assignment.mode == "auto" then
        -- Auto-assign to available turtles
        assigned_turtles = Fleet.getAvailableTurtles()
    elseif task_config.assignment.mode == "manual" then
        -- Use manually selected turtles
        assigned_turtles = task_config.assignment.turtles
    elseif task_config.assignment.mode == "balanced" then
        -- Balance across available turtles
        assigned_turtles = Fleet.getAvailableTurtles()
        -- TODO: Implement load balancing
    end
    
    -- Create task
    local task_id = Tasks.createTask(task, assigned_turtles)
    
    if task_id then
        Core.info("Task created: " .. task_id)
        Core.info("Assigned to " .. #assigned_turtles .. " turtles")
        return true
    else
        Core.error("Failed to create task")
        return false
    end
end

-- Handle input
function TaskAssignment.handleInput(event, key, x, y)
    if event == "key" then
        if key == keys.tab then
            -- Switch modes
            local mode_index = 1
            for i, mode in ipairs(task_modes) do
                if mode.id == current_mode then
                    mode_index = i
                    break
                end
            end
            mode_index = (mode_index % #task_modes) + 1
            current_mode = task_modes[mode_index].id
            selected_field = 1
            return true
        elseif key == keys.up then
            if selected_field > 1 then
                selected_field = selected_field - 1
            end
            return true
        elseif key == keys.down then
            -- Get max fields for current mode
            local max_fields = 3  -- resource
            if current_mode == "area" then
                max_fields = 7
            elseif current_mode == "pattern" then
                if task_config.pattern.type == "strip" then
                    max_fields = 4
                elseif task_config.pattern.type == "quarry" then
                    max_fields = 4
                else
                    max_fields = 1
                end
            end
            
            if selected_field < max_fields then
                selected_field = selected_field + 1
            end
            return true
        elseif key == keys.enter then
            editField()
            return true
        elseif key == keys.a then
            -- Toggle assignment mode
            local modes = {"auto", "manual", "balanced"}
            local current_index = 1
            for i, mode in ipairs(modes) do
                if mode == task_config.assignment.mode then
                    current_index = i
                    break
                end
            end
            task_config.assignment.mode = modes[(current_index % #modes) + 1]
            return true
        elseif key == keys.s and task_config.assignment.mode == "manual" then
            -- Select turtles
            return "turtle_selection", {
                selected = task_config.assignment.turtles,
                callback = function(new_selection)
                    task_config.assignment.turtles = new_selection
                end
            }
        elseif key == keys.c then
            -- Create task
            if createTask() then
                return "task_list"
            end
            return true
        elseif key == keys.b or key == keys.backspace then
            return "back"
        end
    elseif event == "mouse_click" then
        -- Check mode selection
        local mode_y = 3
        for i, mode in ipairs(task_modes) do
            if y >= mode_y + (i-1)*3 and y < mode_y + i*3 then
                current_mode = mode.id
                selected_field = 1
                return true
            end
        end
        
        -- Check create button
        if y == UI.getHeight() - 8 then
            if createTask() then
                return "task_list"
            end
            return true
        end
    end
    
    return false
end

-- Draw screen
function TaskAssignment.draw()
    local width, height = UI.getWidth(), UI.getHeight()
    
    -- Clear screen
    UI.clear()
    
    -- Draw header
    UI.drawHeader("Task Assignment")
    
    -- Layout
    local mode_width = math.floor(width * 0.3)
    local config_width = width - mode_width
    local config_height = height - 14
    
    -- Draw sections
    drawModeSelection(1, 3, mode_width, 12)
    
    if current_mode == "resource" then
        drawResourceConfig(mode_width + 1, 3, config_width, config_height)
    elseif current_mode == "area" then
        drawAreaConfig(mode_width + 1, 3, config_width, config_height)
    elseif current_mode == "pattern" then
        drawPatternConfig(mode_width + 1, 3, config_width, config_height)
    end
    
    drawAssignment(mode_width + 1, height - 11, config_width, 11)
    
    -- Draw footer
    UI.drawFooter("Tab: Switch Mode | Up/Down: Select | Enter: Edit | A: Assignment | C: Create | B: Back")
end

-- Initialize screen
function TaskAssignment.init(data)
    selected_field = 1
    
    -- Reset to defaults or load from data
    if data and data.preset then
        -- Load preset configuration
        -- TODO: Implement preset loading
    end
    
    return true
end

-- Cleanup
function TaskAssignment.cleanup()
    -- Nothing to cleanup
end

return TaskAssignment