-- Settings Screen
-- Configuration options for the control computer

local Settings = {}

-- Dependencies
local Core = require("control.modules.core")
local UI = require("control.modules.ui")
local Network = require("control.modules.network")
local Fleet = require("control.modules.fleet")
local CONSTANTS = require("shared.constants")

-- Screen state
local selected_category = 1
local selected_setting = 1
local unsaved_changes = false

-- Settings categories
local settings_categories = {
    {
        name = "Network",
        settings = {
            {
                key = "network.protocol",
                name = "Protocol",
                type = "string",
                value = "ULTIMATE_MINER_V2",
                description = "Network protocol identifier"
            },
            {
                key = "network.channel",
                name = "Channel",
                type = "number",
                value = 65535,
                min = 1,
                max = 65535,
                description = "Rednet channel for communication"
            },
            {
                key = "network.heartbeat_interval",
                name = "Heartbeat Interval",
                type = "number",
                value = 10,
                min = 5,
                max = 60,
                unit = "seconds",
                description = "How often turtles send status updates"
            },
            {
                key = "network.timeout",
                name = "Connection Timeout",
                type = "number",
                value = 30,
                min = 10,
                max = 300,
                unit = "seconds",
                description = "Time before marking turtle as offline"
            },
            {
                key = "network.discovery_interval",
                name = "Discovery Interval",
                type = "number",
                value = 60,
                min = 30,
                max = 300,
                unit = "seconds",
                description = "How often to scan for new turtles"
            }
        }
    },
    {
        name = "Display",
        settings = {
            {
                key = "display.refresh_rate",
                name = "Refresh Rate",
                type = "number",
                value = 2,
                min = 0.5,
                max = 10,
                unit = "seconds",
                description = "Screen update frequency"
            },
            {
                key = "display.show_offline",
                name = "Show Offline Turtles",
                type = "boolean",
                value = true,
                description = "Display offline turtles in fleet overview"
            },
            {
                key = "display.compact_mode",
                name = "Compact Mode",
                type = "boolean",
                value = false,
                description = "Use compact display for small screens"
            },
            {
                key = "display.color_scheme",
                name = "Color Scheme",
                type = "choice",
                value = "default",
                choices = {"default", "high_contrast", "monochrome"},
                description = "UI color scheme"
            },
            {
                key = "display.show_coordinates",
                name = "Show Coordinates",
                type = "boolean",
                value = true,
                description = "Display turtle coordinates in lists"
            }
        }
    },
    {
        name = "Fleet Management",
        settings = {
            {
                key = "fleet.max_turtles",
                name = "Max Turtles",
                type = "number",
                value = 20,
                min = 1,
                max = 50,
                description = "Maximum number of turtles to manage"
            },
            {
                key = "fleet.auto_assign",
                name = "Auto-Assign Tasks",
                type = "boolean",
                value = true,
                description = "Automatically assign tasks to idle turtles"
            },
            {
                key = "fleet.load_balancing",
                name = "Load Balancing",
                type = "choice",
                value = "round_robin",
                choices = {"round_robin", "least_loaded", "closest", "manual"},
                description = "Task distribution strategy"
            },
            {
                key = "fleet.emergency_recall",
                name = "Emergency Recall Distance",
                type = "number",
                value = 1000,
                min = 100,
                max = 5000,
                unit = "blocks",
                description = "Max distance for emergency recall"
            },
            {
                key = "fleet.naming_pattern",
                name = "Turtle Naming",
                type = "string",
                value = "Miner-%ID%",
                description = "Pattern for turtle names (%ID% = turtle ID)"
            }
        }
    },
    {
        name = "Performance",
        settings = {
            {
                key = "performance.message_batching",
                name = "Message Batching",
                type = "boolean",
                value = true,
                description = "Batch network messages for efficiency"
            },
            {
                key = "performance.batch_size",
                name = "Batch Size",
                type = "number",
                value = 10,
                min = 5,
                max = 50,
                description = "Maximum messages per batch"
            },
            {
                key = "performance.compression",
                name = "Message Compression",
                type = "boolean",
                value = true,
                description = "Compress large network messages"
            },
            {
                key = "performance.history_limit",
                name = "History Limit",
                type = "number",
                value = 100,
                min = 50,
                max = 500,
                description = "Maximum command history entries"
            },
            {
                key = "performance.log_level",
                name = "Log Level",
                type = "choice",
                value = "INFO",
                choices = {"DEBUG", "INFO", "WARNING", "ERROR"},
                description = "Logging verbosity"
            }
        }
    },
    {
        name = "Storage",
        settings = {
            {
                key = "storage.auto_save",
                name = "Auto-Save",
                type = "boolean",
                value = true,
                description = "Automatically save configuration"
            },
            {
                key = "storage.save_interval",
                name = "Save Interval",
                type = "number",
                value = 300,
                min = 60,
                max = 3600,
                unit = "seconds",
                description = "How often to auto-save"
            },
            {
                key = "storage.backup_count",
                name = "Backup Count",
                type = "number",
                value = 3,
                min = 0,
                max = 10,
                description = "Number of config backups to keep"
            },
            {
                key = "storage.data_path",
                name = "Data Path",
                type = "string",
                value = "/data/control/",
                description = "Path for storing data files"
            }
        }
    }
}

-- Load current settings
local function loadSettings()
    -- TODO: Load from config file
    -- For now, using defaults
end

-- Save settings
local function saveSettings()
    -- TODO: Save to config file
    Core.info("Settings saved")
    unsaved_changes = false
end

-- Draw category list
local function drawCategories(x, y, width, height)
    UI.drawBox(x, y, width, height, "Categories")
    
    for i, category in ipairs(settings_categories) do
        local row = y + 1 + (i - 1) * 2
        term.setCursorPos(x + 2, row)
        
        if i == selected_category then
            UI.setColors(colors.black, colors.white)
            write("> " .. category.name .. string.rep(" ", width - 4 - #category.name))
        else
            UI.setColors(colors.white, colors.black)
            write("  " .. category.name)
        end
    end
    
    UI.setColors(colors.white, colors.black)
end

-- Draw settings list
local function drawSettings(x, y, width, height)
    local category = settings_categories[selected_category]
    UI.drawBox(x, y, width, height, category.name .. " Settings")
    
    local visible_settings = math.floor((height - 2) / 3)
    local start_idx = math.max(1, selected_setting - visible_settings + 1)
    
    local row = y + 2
    for i = start_idx, math.min(#category.settings, start_idx + visible_settings - 1) do
        local setting = category.settings[i]
        
        -- Setting name
        term.setCursorPos(x + 2, row)
        if i == selected_setting then
            UI.setColors(colors.black, colors.white)
        else
            UI.setColors(colors.white, colors.black)
        end
        write(setting.name)
        
        -- Setting value
        local value_str = ""
        if setting.type == "boolean" then
            value_str = setting.value and "Enabled" or "Disabled"
            if i == selected_setting then
                write(": " .. value_str)
                write(string.rep(" ", width - 4 - #setting.name - #value_str - 2))
            else
                write(": ")
                if term.isColor() then
                    term.setTextColor(setting.value and colors.green or colors.red)
                end
                write(value_str)
                if term.isColor() then
                    term.setTextColor(colors.white)
                end
            end
        elseif setting.type == "number" then
            value_str = tostring(setting.value)
            if setting.unit then
                value_str = value_str .. " " .. setting.unit
            end
            write(": " .. value_str)
            if i == selected_setting then
                write(string.rep(" ", width - 4 - #setting.name - #value_str - 2))
            end
        elseif setting.type == "string" then
            value_str = setting.value
            if #value_str > 20 then
                value_str = string.sub(value_str, 1, 17) .. "..."
            end
            write(": " .. value_str)
            if i == selected_setting then
                write(string.rep(" ", width - 4 - #setting.name - #value_str - 2))
            end
        elseif setting.type == "choice" then
            value_str = setting.value
            write(": " .. value_str)
            if i == selected_setting then
                write(string.rep(" ", width - 4 - #setting.name - #value_str - 2))
            end
        end
        
        UI.setColors(colors.white, colors.black)
        
        -- Description
        row = row + 1
        term.setCursorPos(x + 4, row)
        UI.setColors(colors.gray, colors.black)
        local desc = setting.description
        if #desc > width - 6 then
            desc = string.sub(desc, 1, width - 9) .. "..."
        end
        write(desc)
        UI.setColors(colors.white, colors.black)
        
        row = row + 2
    end
    
    -- Scroll indicators
    if start_idx > 1 then
        term.setCursorPos(x + width - 3, y + 2)
        write("^")
    end
    
    if start_idx + visible_settings - 1 < #category.settings then
        term.setCursorPos(x + width - 3, y + height - 1)
        write("v")
    end
end

-- Draw controls
local function drawControls(x, y, width, height)
    UI.drawBox(x, y, width, height, "Controls")
    
    local controls = {
        {"Up/Down", "Navigate"},
        {"Left/Right", "Categories"},
        {"Enter", "Edit setting"},
        {"Space", "Toggle boolean"},
        {"S", "Save changes"},
        {"R", "Reset to defaults"},
        {"B", "Back to menu"}
    }
    
    local row = y + 2
    for _, control in ipairs(controls) do
        if row >= y + height - 1 then break end
        
        term.setCursorPos(x + 2, row)
        UI.setColors(colors.yellow, colors.black)
        write(control[1])
        UI.setColors(colors.white, colors.black)
        write(" - " .. control[2])
        row = row + 1
    end
    
    -- Unsaved changes indicator
    if unsaved_changes then
        term.setCursorPos(x + 2, y + height - 2)
        UI.setColors(colors.orange, colors.black)
        write("* Unsaved changes")
        UI.setColors(colors.white, colors.black)
    end
end

-- Edit setting value
local function editSetting()
    local category = settings_categories[selected_category]
    local setting = category.settings[selected_setting]
    
    if setting.type == "boolean" then
        -- Toggle boolean
        setting.value = not setting.value
        unsaved_changes = true
    elseif setting.type == "number" then
        -- Edit number
        UI.drawFooter("Enter new value (" .. setting.min .. "-" .. setting.max .. "):")
        term.setCursorPos(1, UI.getHeight())
        local input = read()
        
        if input and input ~= "" then
            local num = tonumber(input)
            if num and num >= setting.min and num <= setting.max then
                setting.value = num
                unsaved_changes = true
            else
                Core.warn("Invalid value. Must be between " .. setting.min .. " and " .. setting.max)
            end
        end
    elseif setting.type == "string" then
        -- Edit string
        UI.drawFooter("Enter new value:")
        term.setCursorPos(1, UI.getHeight())
        local input = read()
        
        if input and input ~= "" then
            setting.value = input
            unsaved_changes = true
        end
    elseif setting.type == "choice" then
        -- Cycle through choices
        local current_idx = 1
        for i, choice in ipairs(setting.choices) do
            if choice == setting.value then
                current_idx = i
                break
            end
        end
        
        current_idx = (current_idx % #setting.choices) + 1
        setting.value = setting.choices[current_idx]
        unsaved_changes = true
    end
end

-- Reset to defaults
local function resetToDefaults()
    UI.drawFooter("Reset all settings to defaults? (Y/N)")
    local event, key = os.pullEvent("key")
    
    if key == keys.y then
        -- Reset all settings
        for _, category in ipairs(settings_categories) do
            for _, setting in ipairs(category.settings) do
                -- TODO: Load default values from somewhere
                Core.info("Settings reset to defaults")
                unsaved_changes = true
            end
        end
    end
end

-- Handle input
function Settings.handleInput(event, key, x, y)
    if event == "key" then
        if key == keys.up then
            if selected_setting > 1 then
                selected_setting = selected_setting - 1
            end
            return true
        elseif key == keys.down then
            local category = settings_categories[selected_category]
            if selected_setting < #category.settings then
                selected_setting = selected_setting + 1
            end
            return true
        elseif key == keys.left then
            if selected_category > 1 then
                selected_category = selected_category - 1
                selected_setting = 1
            end
            return true
        elseif key == keys.right then
            if selected_category < #settings_categories then
                selected_category = selected_category + 1
                selected_setting = 1
            end
            return true
        elseif key == keys.enter or key == keys.space then
            editSetting()
            return true
        elseif key == keys.s then
            saveSettings()
            return true
        elseif key == keys.r then
            resetToDefaults()
            return true
        elseif key == keys.b or key == keys.backspace then
            if unsaved_changes then
                UI.drawFooter("Save changes before exiting? (Y/N/C)")
                local event2, key2 = os.pullEvent("key")
                if key2 == keys.y then
                    saveSettings()
                    return "back"
                elseif key2 == keys.n then
                    return "back"
                else
                    return true  -- Cancel
                end
            else
                return "back"
            end
        end
    elseif event == "mouse_click" then
        -- Check category click
        if x <= 20 then
            local clicked_category = math.floor((y - 3) / 2) + 1
            if clicked_category >= 1 and clicked_category <= #settings_categories then
                selected_category = clicked_category
                selected_setting = 1
                return true
            end
        end
    end
    
    return false
end

-- Draw screen
function Settings.draw()
    local width, height = UI.getWidth(), UI.getHeight()
    
    -- Clear screen
    UI.clear()
    
    -- Draw header
    UI.drawHeader("Settings" .. (unsaved_changes and " *" or ""))
    
    -- Layout
    local category_width = 20
    local settings_width = width - category_width - 10
    local controls_height = 10
    
    -- Draw sections
    drawCategories(1, 3, category_width, height - 3)
    drawSettings(category_width + 1, 3, settings_width, height - controls_height - 3)
    drawControls(category_width + 1, height - controls_height, settings_width, controls_height)
    
    -- Draw footer
    UI.drawFooter("Navigate: Arrows | Edit: Enter | Save: S | Reset: R | Back: B")
end

-- Initialize screen
function Settings.init()
    selected_category = 1
    selected_setting = 1
    unsaved_changes = false
    
    -- Load current settings
    loadSettings()
    
    return true
end

-- Cleanup
function Settings.cleanup()
    -- Prompt to save if there are unsaved changes
    if unsaved_changes then
        -- This should be handled in handleInput for proper UI
    end
end

return Settings