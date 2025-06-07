-- UI Module for Control Computer
-- Provides adaptive user interface for standard and advanced computers

local UI = {}
local Core = require("control.modules.core")

-- Configuration
UI.initialized = false
UI.current_screen = nil
UI.screen_stack = {}
UI.input_handlers = {}
UI.refresh_timer = nil
UI.refresh_interval = 1  -- Seconds

-- Display properties
UI.width = 0
UI.height = 0
UI.is_color = false
UI.is_advanced = false
UI.has_mouse = false

-- Color scheme
UI.colors = {
    background = colors.black,
    text = colors.white,
    header = colors.blue,
    header_text = colors.white,
    selected = colors.lightBlue,
    selected_text = colors.black,
    success = colors.green,
    warning = colors.yellow,
    error = colors.red,
    border = colors.gray
}

-- Initialize UI
function UI.init()
    if UI.initialized then
        Core.log("INFO", "UI already initialized")
        return true, "Already initialized"
    end
    
    -- Get display capabilities
    UI.detectDisplay()
    
    -- Set up color scheme for standard computers
    if not UI.is_color then
        UI.colors = {
            background = colors.black,
            text = colors.white,
            header = colors.white,
            header_text = colors.black,
            selected = colors.white,
            selected_text = colors.black,
            success = colors.white,
            warning = colors.white,
            error = colors.white,
            border = colors.white
        }
    end
    
    -- Register input handlers
    UI.registerInputHandlers()
    
    UI.initialized = true
    Core.log("INFO", "UI initialized for " .. (UI.is_advanced and "advanced" or "standard") .. " computer")
    
    return true, "UI initialized successfully"
end

-- Detect display capabilities
function UI.detectDisplay()
    local capabilities = Core.getCapabilities()
    
    UI.width = capabilities.screen_width
    UI.height = capabilities.screen_height
    UI.is_color = capabilities.has_color
    UI.is_advanced = capabilities.is_advanced
    UI.has_mouse = capabilities.has_mouse
    
    Core.log("INFO", "Display: " .. UI.width .. "x" .. UI.height .. 
             " Color: " .. tostring(UI.is_color) ..
             " Mouse: " .. tostring(UI.has_mouse))
end

-- Register input handlers
function UI.registerInputHandlers()
    -- Keyboard handler
    Core.on("key", function(key)
        if UI.current_screen and UI.current_screen.onKey then
            UI.current_screen.onKey(key)
        end
    end)
    
    -- Character handler
    Core.on("char", function(char)
        if UI.current_screen and UI.current_screen.onChar then
            UI.current_screen.onChar(char)
        end
    end)
    
    -- Mouse handler (advanced computers only)
    if UI.has_mouse then
        Core.on("mouse_click", function(button, x, y)
            if UI.current_screen and UI.current_screen.onMouseClick then
                UI.current_screen.onMouseClick(button, x, y)
            end
        end)
        
        Core.on("mouse_scroll", function(direction, x, y)
            if UI.current_screen and UI.current_screen.onMouseScroll then
                UI.current_screen.onMouseScroll(direction, x, y)
            end
        end)
    end
    
    -- Timer handler for refresh
    Core.on("timer", function(timer_id)
        if timer_id == UI.refresh_timer then
            UI.refresh()
            UI.refresh_timer = os.startTimer(UI.refresh_interval)
        end
    end)
end

-- Clear screen
function UI.clear()
    term.setBackgroundColor(UI.colors.background)
    term.setTextColor(UI.colors.text)
    term.clear()
    term.setCursorPos(1, 1)
end

-- Draw header
function UI.drawHeader(title, subtitle)
    term.setBackgroundColor(UI.colors.header)
    term.setTextColor(UI.colors.header_text)
    
    -- Clear header area
    for y = 1, 2 do
        term.setCursorPos(1, y)
        term.write(string.rep(" ", UI.width))
    end
    
    -- Draw title
    term.setCursorPos(math.floor((UI.width - #title) / 2) + 1, 1)
    term.write(title)
    
    -- Draw subtitle if provided
    if subtitle then
        term.setCursorPos(math.floor((UI.width - #subtitle) / 2) + 1, 2)
        term.write(subtitle)
    end
    
    term.setBackgroundColor(UI.colors.background)
    term.setTextColor(UI.colors.text)
end

-- Draw footer
function UI.drawFooter(text)
    term.setBackgroundColor(UI.colors.header)
    term.setTextColor(UI.colors.header_text)
    
    term.setCursorPos(1, UI.height)
    term.write(string.rep(" ", UI.width))
    
    term.setCursorPos(math.floor((UI.width - #text) / 2) + 1, UI.height)
    term.write(text)
    
    term.setBackgroundColor(UI.colors.background)
    term.setTextColor(UI.colors.text)
end

-- Draw menu
function UI.drawMenu(items, selected, start_y)
    start_y = start_y or 4
    
    for i, item in ipairs(items) do
        local y = start_y + i - 1
        if y > UI.height - 2 then break end  -- Leave room for footer
        
        term.setCursorPos(2, y)
        
        if i == selected then
            term.setBackgroundColor(UI.colors.selected)
            term.setTextColor(UI.colors.selected_text)
            term.write("> " .. item .. string.rep(" ", UI.width - #item - 4))
            term.setBackgroundColor(UI.colors.background)
            term.setTextColor(UI.colors.text)
        else
            term.write("  " .. item)
        end
    end
end

-- Draw table
function UI.drawTable(headers, rows, start_y, selected_row)
    start_y = start_y or 4
    local col_widths = {}
    local total_width = UI.width - 4  -- Leave margins
    
    -- Calculate column widths
    local base_width = math.floor(total_width / #headers)
    for i = 1, #headers do
        col_widths[i] = base_width
    end
    
    -- Draw headers
    term.setCursorPos(2, start_y)
    term.setTextColor(UI.colors.header)
    for i, header in ipairs(headers) do
        local text = string.sub(header, 1, col_widths[i] - 1)
        term.write(text .. string.rep(" ", col_widths[i] - #text))
    end
    term.setTextColor(UI.colors.text)
    
    -- Draw separator
    term.setCursorPos(2, start_y + 1)
    term.write(string.rep("-", total_width))
    
    -- Draw rows
    local row_y = start_y + 2
    for row_idx, row in ipairs(rows) do
        if row_y > UI.height - 2 then break end
        
        term.setCursorPos(2, row_y)
        
        if row_idx == selected_row then
            term.setBackgroundColor(UI.colors.selected)
            term.setTextColor(UI.colors.selected_text)
        end
        
        for i, value in ipairs(row) do
            local text = tostring(value)
            text = string.sub(text, 1, col_widths[i] - 1)
            term.write(text .. string.rep(" ", col_widths[i] - #text))
        end
        
        if row_idx == selected_row then
            term.setBackgroundColor(UI.colors.background)
            term.setTextColor(UI.colors.text)
        end
        
        row_y = row_y + 1
    end
end

-- Draw progress bar
function UI.drawProgressBar(x, y, width, progress, max)
    local percent = math.min(1, progress / max)
    local filled = math.floor(width * percent)
    
    term.setCursorPos(x, y)
    term.setBackgroundColor(UI.colors.border)
    term.write(string.rep(" ", width))
    
    if filled > 0 then
        term.setCursorPos(x, y)
        term.setBackgroundColor(UI.colors.success)
        term.write(string.rep(" ", filled))
    end
    
    term.setBackgroundColor(UI.colors.background)
    
    -- Draw percentage text
    local percent_text = string.format("%d%%", percent * 100)
    term.setCursorPos(x + math.floor((width - #percent_text) / 2), y)
    term.setTextColor(UI.colors.text)
    term.write(percent_text)
end

-- Draw status indicator
function UI.drawStatus(x, y, status)
    term.setCursorPos(x, y)
    
    local color_map = {
        online = UI.colors.success,
        offline = UI.colors.error,
        busy = UI.colors.warning,
        error = UI.colors.error
    }
    
    term.setTextColor(color_map[status] or UI.colors.text)
    term.write("[" .. string.upper(status) .. "]")
    term.setTextColor(UI.colors.text)
end

-- Draw text with color
function UI.drawText(x, y, text, color)
    term.setCursorPos(x, y)
    if color then
        term.setTextColor(color)
    end
    term.write(text)
    if color then
        term.setTextColor(UI.colors.text)
    end
end

-- Draw centered text
function UI.drawCenteredText(y, text, color)
    local x = math.floor((UI.width - #text) / 2) + 1
    UI.drawText(x, y, text, color)
end

-- Draw box
function UI.drawBox(x, y, width, height, title)
    -- Top border
    term.setCursorPos(x, y)
    term.write("+" .. string.rep("-", width - 2) .. "+")
    
    -- Title if provided
    if title then
        term.setCursorPos(x + 2, y)
        term.write(" " .. title .. " ")
    end
    
    -- Sides
    for i = 1, height - 2 do
        term.setCursorPos(x, y + i)
        term.write("|")
        term.setCursorPos(x + width - 1, y + i)
        term.write("|")
    end
    
    -- Bottom border
    term.setCursorPos(x, y + height - 1)
    term.write("+" .. string.rep("-", width - 2) .. "+")
end

-- Show screen
function UI.showScreen(screen)
    if UI.current_screen and UI.current_screen.onExit then
        UI.current_screen.onExit()
    end
    
    UI.current_screen = screen
    
    if screen.onEnter then
        screen.onEnter()
    end
    
    UI.render()
end

-- Push screen onto stack
function UI.pushScreen(screen)
    if UI.current_screen then
        table.insert(UI.screen_stack, UI.current_screen)
    end
    UI.showScreen(screen)
end

-- Pop screen from stack
function UI.popScreen()
    if #UI.screen_stack > 0 then
        local screen = table.remove(UI.screen_stack)
        UI.showScreen(screen)
    end
end

-- Render current screen
function UI.render()
    if UI.current_screen and UI.current_screen.render then
        UI.clear()
        UI.current_screen.render()
    end
end

-- Refresh screen
function UI.refresh()
    if UI.current_screen and UI.current_screen.refresh then
        UI.current_screen.refresh()
    else
        UI.render()
    end
end

-- Start refresh timer
function UI.startRefresh(interval)
    UI.refresh_interval = interval or 1
    UI.refresh_timer = os.startTimer(UI.refresh_interval)
end

-- Stop refresh timer
function UI.stopRefresh()
    if UI.refresh_timer then
        os.cancelTimer(UI.refresh_timer)
        UI.refresh_timer = nil
    end
end

-- Prompt for input
function UI.prompt(message, default)
    term.write(message .. " ")
    if default then
        term.write("[" .. default .. "] ")
    end
    
    local input = read()
    if input == "" and default then
        return default
    end
    return input
end

-- Show message
function UI.showMessage(message, color, duration)
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()
    
    term.setBackgroundColor(UI.colors.background)
    term.setTextColor(color or UI.colors.text)
    
    local y = math.floor(UI.height / 2)
    term.setCursorPos(1, y - 1)
    term.clearLine()
    term.setCursorPos(1, y)
    term.clearLine()
    term.setCursorPos(1, y + 1)
    term.clearLine()
    
    UI.drawCenteredText(y, message, color)
    
    if duration then
        os.sleep(duration)
        UI.render()
    end
    
    term.setBackgroundColor(old_bg)
    term.setTextColor(old_fg)
end

-- Confirm dialog
function UI.confirm(message)
    UI.showMessage(message .. " (Y/N)", UI.colors.warning)
    
    while true do
        local event, key = os.pullEvent("key")
        if key == keys.y then
            return true
        elseif key == keys.n then
            return false
        end
    end
end

-- Get screen dimensions
function UI.getSize()
    return UI.width, UI.height
end

-- Check if color display
function UI.isColor()
    return UI.is_color
end

-- Check if advanced computer
function UI.isAdvanced()
    return UI.is_advanced
end

-- Shutdown
function UI.shutdown()
    Core.log("INFO", "UI shutting down")
    
    UI.stopRefresh()
    UI.clear()
    UI.initialized = false
    
    return true
end

return UI