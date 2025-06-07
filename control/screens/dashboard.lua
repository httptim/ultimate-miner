-- Dashboard Screen
-- Main monitoring interface for turtle fleet

local Dashboard = {}
local UI = require("control.modules.ui")
local Fleet = require("control.modules.fleet")
local Commands = require("control.modules.commands")
local Core = require("control.modules.core")

-- State
Dashboard.selected_menu = 1
Dashboard.menu_items = {
    "Fleet Overview",
    "Individual Control",
    "Fleet Commands",
    "Task Assignment",
    "Settings",
    "Exit"
}

-- Create dashboard screen
function Dashboard.create()
    local screen = {
        name = "dashboard",
        render = Dashboard.render,
        refresh = Dashboard.refresh,
        onKey = Dashboard.onKey,
        onChar = Dashboard.onChar,
        onEnter = Dashboard.onEnter,
        onExit = Dashboard.onExit
    }
    
    if UI.has_mouse then
        screen.onMouseClick = Dashboard.onMouseClick
        screen.onMouseScroll = Dashboard.onMouseScroll
    end
    
    return screen
end

-- Render dashboard
function Dashboard.render()
    -- Header
    UI.drawHeader("Ultimate Miner Control Center", "Fleet Management System v1.0")
    
    -- Fleet status summary
    local stats = Fleet.getStatusCounts()
    local y = 4
    
    UI.drawText(2, y, "Fleet Status:", UI.colors.header)
    y = y + 1
    
    UI.drawText(4, y, "Online:  " .. stats.online, UI.colors.success)
    UI.drawText(20, y, "Offline: " .. stats.offline, UI.colors.error)
    UI.drawText(36, y, "Total:   " .. stats.total, UI.colors.text)
    y = y + 2
    
    -- Main menu
    UI.drawText(2, y, "Main Menu:", UI.colors.header)
    y = y + 1
    
    UI.drawMenu(Dashboard.menu_items, Dashboard.selected_menu, y)
    
    -- Recent activity (if space permits)
    if UI.height > 20 then
        y = y + #Dashboard.menu_items + 2
        UI.drawText(2, y, "Recent Activity:", UI.colors.header)
        y = y + 1
        
        -- Show last few turtle status updates
        local turtles = Fleet.getAllTurtles()
        local recent = {}
        
        for id, turtle in pairs(turtles) do
            table.insert(recent, {
                id = id,
                name = turtle.name,
                status = turtle.status,
                task = turtle.current_task,
                time = turtle.last_heartbeat
            })
        end
        
        -- Sort by most recent
        table.sort(recent, function(a, b) return a.time > b.time end)
        
        -- Display up to 5 recent
        for i = 1, math.min(5, #recent) do
            local t = recent[i]
            local time_ago = math.floor((os.epoch("utc") - t.time) / 1000)
            
            UI.drawText(4, y, t.name .. ":", UI.colors.text)
            UI.drawStatus(20, y, t.status)
            UI.drawText(30, y, t.task, UI.colors.text)
            UI.drawText(45, y, time_ago .. "s ago", UI.colors.border)
            y = y + 1
        end
    end
    
    -- Footer
    UI.drawFooter("Use arrows to navigate, Enter to select, Q to quit")
end

-- Refresh dashboard (called periodically)
function Dashboard.refresh()
    Dashboard.render()
end

-- Handle key input
function Dashboard.onKey(key)
    if key == keys.up then
        Dashboard.selected_menu = math.max(1, Dashboard.selected_menu - 1)
        UI.render()
    elseif key == keys.down then
        Dashboard.selected_menu = math.min(#Dashboard.menu_items, Dashboard.selected_menu + 1)
        UI.render()
    elseif key == keys.enter then
        Dashboard.selectMenuItem(Dashboard.selected_menu)
    elseif key == keys.q then
        Dashboard.selectMenuItem(#Dashboard.menu_items)  -- Exit
    end
end

-- Handle character input
function Dashboard.onChar(char)
    local num = tonumber(char)
    if num and num >= 1 and num <= #Dashboard.menu_items then
        Dashboard.selected_menu = num
        Dashboard.selectMenuItem(num)
    end
end

-- Handle mouse click
function Dashboard.onMouseClick(button, x, y)
    -- Check if click is on a menu item
    local menu_start_y = 8
    for i, item in ipairs(Dashboard.menu_items) do
        local item_y = menu_start_y + i - 1
        if y == item_y and x >= 2 and x <= #item + 4 then
            Dashboard.selected_menu = i
            Dashboard.selectMenuItem(i)
            return
        end
    end
end

-- Handle mouse scroll
function Dashboard.onMouseScroll(direction, x, y)
    if direction == -1 then  -- Scroll up
        Dashboard.selected_menu = math.max(1, Dashboard.selected_menu - 1)
    else  -- Scroll down
        Dashboard.selected_menu = math.min(#Dashboard.menu_items, Dashboard.selected_menu + 1)
    end
    UI.render()
end

-- Select menu item
function Dashboard.selectMenuItem(index)
    local item = Dashboard.menu_items[index]
    
    if item == "Fleet Overview" then
        local FleetOverview = require("control.screens.fleet_overview")
        UI.pushScreen(FleetOverview.create())
    elseif item == "Individual Control" then
        local TurtleControl = require("control.screens.turtle_control")
        UI.pushScreen(TurtleControl.create())
    elseif item == "Fleet Commands" then
        local FleetCommands = require("control.screens.fleet_commands")
        UI.pushScreen(FleetCommands.create())
    elseif item == "Task Assignment" then
        local TaskAssignment = require("control.screens.task_assignment")
        UI.pushScreen(TaskAssignment.create())
    elseif item == "Settings" then
        local Settings = require("control.screens.settings")
        UI.pushScreen(Settings.create())
    elseif item == "Error Report" then
        local ErrorHandler = require("shared.error_handler")
        ErrorHandler.createErrorReport()
        UI.render()
    elseif item == "Exit" then
        if UI.confirm("Are you sure you want to exit?") then
            Core.emit("exit")
        end
    end
end

-- On enter screen
function Dashboard.onEnter()
    UI.startRefresh(1)  -- Refresh every second
end

-- On exit screen
function Dashboard.onExit()
    UI.stopRefresh()
end

return Dashboard