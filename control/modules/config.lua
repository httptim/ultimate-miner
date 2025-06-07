-- Configuration Module for Control Computer
-- Manages persistent configuration and settings

local Config = {}

-- Dependencies
local Core = require("control.modules.core")

-- Module state
local initialized = false
local config_data = {}
local config_file = "/data/control/config.json"
local backup_dir = "/data/control/backups/"
local max_backups = 3
local dirty = false
local auto_save_timer = nil
local auto_save_interval = 300  -- 5 minutes

-- Default configuration
local DEFAULT_CONFIG = {
    -- Network settings
    network = {
        protocol = "ULTIMATE_MINER_V2",
        channel = 65535,
        heartbeat_interval = 10,
        timeout = 30,
        discovery_interval = 60,
        message_batching = true,
        batch_size = 10,
        compression = true
    },
    
    -- Display settings
    display = {
        refresh_rate = 2,
        show_offline = true,
        compact_mode = false,
        color_scheme = "default",
        show_coordinates = true,
        monitor_scale = 1
    },
    
    -- Fleet management
    fleet = {
        max_turtles = 20,
        auto_assign = true,
        load_balancing = "round_robin",
        emergency_recall_distance = 1000,
        naming_pattern = "Miner-%ID%",
        group_size = 5,
        task_timeout = 3600
    },
    
    -- Performance settings
    performance = {
        message_batching = true,
        batch_size = 10,
        compression = true,
        history_limit = 100,
        log_level = "INFO",
        gc_interval = 300,
        cache_size = 50
    },
    
    -- Storage settings
    storage = {
        auto_save = true,
        save_interval = 300,
        backup_count = 3,
        data_path = "/data/control/",
        log_retention = 7  -- days
    },
    
    -- UI settings
    ui = {
        theme = "default",
        animations = true,
        sound_enabled = false,
        confirm_dangerous = true,
        tooltip_delay = 1
    },
    
    -- Security settings
    security = {
        require_confirmation = true,
        allow_remote_control = true,
        trusted_computers = {},
        command_whitelist = {},
        max_command_rate = 10  -- per second
    }
}

-- Deep copy table
local function deepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Merge tables recursively
local function mergeTables(base, override)
    if type(base) ~= "table" or type(override) ~= "table" then
        return override
    end
    
    local result = deepCopy(base)
    
    for k, v in pairs(override) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = mergeTables(result[k], v)
        else
            result[k] = v
        end
    end
    
    return result
end

-- Validate configuration values
local function validateConfig(config)
    -- Network validation
    if config.network then
        config.network.channel = math.max(1, math.min(65535, config.network.channel or 65535))
        config.network.heartbeat_interval = math.max(5, math.min(60, config.network.heartbeat_interval or 10))
        config.network.timeout = math.max(10, math.min(300, config.network.timeout or 30))
    end
    
    -- Fleet validation
    if config.fleet then
        config.fleet.max_turtles = math.max(1, math.min(50, config.fleet.max_turtles or 20))
        config.fleet.emergency_recall_distance = math.max(100, math.min(5000, config.fleet.emergency_recall_distance or 1000))
    end
    
    -- Performance validation
    if config.performance then
        config.performance.batch_size = math.max(5, math.min(50, config.performance.batch_size or 10))
        config.performance.history_limit = math.max(50, math.min(500, config.performance.history_limit or 100))
    end
    
    return config
end

-- Create backup of current config
local function createBackup()
    if not fs.exists(config_file) then
        return true
    end
    
    -- Ensure backup directory exists
    if not fs.exists(backup_dir) then
        fs.makeDir(backup_dir)
    end
    
    -- Generate backup filename with timestamp
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local backup_file = backup_dir .. "config_" .. timestamp .. ".json"
    
    -- Copy current config to backup
    fs.copy(config_file, backup_file)
    
    -- Clean old backups
    local backups = fs.list(backup_dir)
    table.sort(backups)
    
    while #backups > max_backups do
        fs.delete(backup_dir .. backups[1])
        table.remove(backups, 1)
    end
    
    Core.debug("Created config backup: " .. backup_file)
    return true
end

-- Load configuration from file
local function loadConfig()
    -- Ensure data directory exists
    local data_dir = fs.getDir(config_file)
    if not fs.exists(data_dir) then
        fs.makeDir(data_dir)
    end
    
    -- Start with default config
    config_data = deepCopy(DEFAULT_CONFIG)
    
    -- Load saved config if exists
    if fs.exists(config_file) then
        local file = fs.open(config_file, "r")
        if file then
            local content = file.readAll()
            file.close()
            
            local success, saved_config = pcall(textutils.unserializeJSON, content)
            if success and saved_config then
                -- Merge with defaults
                config_data = mergeTables(config_data, saved_config)
                Core.debug("Loaded configuration from " .. config_file)
            else
                Core.error("Failed to parse config file, using defaults")
                createBackup()  -- Backup the corrupted file
            end
        end
    else
        Core.info("No config file found, using defaults")
    end
    
    -- Validate configuration
    config_data = validateConfig(config_data)
    
    return true
end

-- Save configuration to file
local function saveConfig()
    -- Create backup before saving
    createBackup()
    
    -- Ensure directory exists
    local dir = fs.getDir(config_file)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    -- Serialize configuration
    local content = textutils.serializeJSON(config_data)
    
    -- Write to temporary file first
    local temp_file = config_file .. ".tmp"
    local file = fs.open(temp_file, "w")
    if file then
        file.write(content)
        file.close()
        
        -- Move temp file to actual config file
        fs.delete(config_file)
        fs.move(temp_file, config_file)
        
        dirty = false
        Core.debug("Saved configuration to " .. config_file)
        Core.emit("config_saved")
        return true
    else
        Core.error("Failed to save configuration")
        return false
    end
end

-- Get configuration value
function Config.get(key, default)
    if not initialized then
        return default
    end
    
    -- Support dot notation (e.g., "network.protocol")
    local parts = {}
    for part in string.gmatch(key, "[^.]+") do
        table.insert(parts, part)
    end
    
    local value = config_data
    for _, part in ipairs(parts) do
        if type(value) == "table" and value[part] ~= nil then
            value = value[part]
        else
            return default
        end
    end
    
    return value
end

-- Set configuration value
function Config.set(key, value)
    if not initialized then
        return false, "Config not initialized"
    end
    
    -- Support dot notation
    local parts = {}
    for part in string.gmatch(key, "[^.]+") do
        table.insert(parts, part)
    end
    
    -- Navigate to the parent table
    local current = config_data
    for i = 1, #parts - 1 do
        local part = parts[i]
        if type(current[part]) ~= "table" then
            current[part] = {}
        end
        current = current[part]
    end
    
    -- Set the value
    local last_part = parts[#parts]
    local old_value = current[last_part]
    current[last_part] = value
    
    -- Mark as dirty
    dirty = true
    
    -- Emit change event
    Core.emit("config_changed", {
        key = key,
        old_value = old_value,
        new_value = value
    })
    
    Core.debug("Config set: " .. key .. " = " .. tostring(value))
    return true
end

-- Get entire configuration section
function Config.getSection(section)
    if not initialized then
        return {}
    end
    
    if type(config_data[section]) == "table" then
        return deepCopy(config_data[section])
    end
    
    return {}
end

-- Set entire configuration section
function Config.setSection(section, data)
    if not initialized then
        return false, "Config not initialized"
    end
    
    if type(data) ~= "table" then
        return false, "Section data must be a table"
    end
    
    local old_section = config_data[section]
    config_data[section] = deepCopy(data)
    
    -- Validate new configuration
    config_data = validateConfig(config_data)
    
    dirty = true
    
    Core.emit("config_section_changed", {
        section = section,
        old_value = old_section,
        new_value = config_data[section]
    })
    
    return true
end

-- Reset configuration to defaults
function Config.reset(section)
    if not initialized then
        return false, "Config not initialized"
    end
    
    if section then
        -- Reset specific section
        if DEFAULT_CONFIG[section] then
            config_data[section] = deepCopy(DEFAULT_CONFIG[section])
            dirty = true
            Core.info("Reset config section: " .. section)
            return true
        else
            return false, "Unknown config section"
        end
    else
        -- Reset entire configuration
        createBackup()  -- Backup current config
        config_data = deepCopy(DEFAULT_CONFIG)
        dirty = true
        Core.info("Reset entire configuration to defaults")
        return true
    end
end

-- Export configuration
function Config.export(filename)
    if not initialized then
        return false, "Config not initialized"
    end
    
    local file = fs.open(filename, "w")
    if file then
        file.write(textutils.serializeJSON(config_data))
        file.close()
        Core.info("Exported configuration to " .. filename)
        return true
    else
        return false, "Failed to open export file"
    end
end

-- Import configuration
function Config.import(filename)
    if not initialized then
        return false, "Config not initialized"
    end
    
    if not fs.exists(filename) then
        return false, "Import file not found"
    end
    
    local file = fs.open(filename, "r")
    if file then
        local content = file.readAll()
        file.close()
        
        local success, imported_config = pcall(textutils.unserializeJSON, content)
        if success and imported_config then
            -- Backup current config
            createBackup()
            
            -- Merge with defaults to ensure all keys exist
            config_data = mergeTables(DEFAULT_CONFIG, imported_config)
            config_data = validateConfig(config_data)
            
            dirty = true
            Core.info("Imported configuration from " .. filename)
            return true
        else
            return false, "Failed to parse import file"
        end
    else
        return false, "Failed to read import file"
    end
end

-- Save configuration if dirty
function Config.save()
    if not initialized then
        return false, "Config not initialized"
    end
    
    if dirty then
        return saveConfig()
    end
    
    return true
end

-- Check if configuration has unsaved changes
function Config.isDirty()
    return dirty
end

-- Get list of available backups
function Config.getBackups()
    if not fs.exists(backup_dir) then
        return {}
    end
    
    local backups = {}
    local files = fs.list(backup_dir)
    
    for _, file in ipairs(files) do
        if file:match("^config_%d+_%d+%.json$") then
            local timestamp = file:match("config_(%d+_%d+)%.json")
            local year, month, day, hour, min, sec = timestamp:match("(%d%d%d%d)(%d%d)(%d%d)_(%d%d)(%d%d)(%d%d)")
            
            table.insert(backups, {
                filename = file,
                timestamp = timestamp,
                date = string.format("%s-%s-%s %s:%s:%s", year, month, day, hour, min, sec),
                path = backup_dir .. file
            })
        end
    end
    
    -- Sort by timestamp (newest first)
    table.sort(backups, function(a, b) return a.timestamp > b.timestamp end)
    
    return backups
end

-- Restore from backup
function Config.restoreBackup(backup_file)
    if not initialized then
        return false, "Config not initialized"
    end
    
    local backup_path = backup_dir .. backup_file
    if not fs.exists(backup_path) then
        return false, "Backup file not found"
    end
    
    -- Create backup of current config first
    createBackup()
    
    -- Copy backup to config file
    fs.copy(backup_path, config_file)
    
    -- Reload configuration
    loadConfig()
    
    Core.info("Restored configuration from backup: " .. backup_file)
    return true
end

-- Initialize module
function Config.init()
    if initialized then
        return true
    end
    
    Core.debug("Initializing Config module")
    
    -- Load configuration
    if not loadConfig() then
        return false, "Failed to load configuration"
    end
    
    -- Set up auto-save timer
    if config_data.storage.auto_save then
        auto_save_timer = os.startTimer(config_data.storage.save_interval)
    end
    
    -- Register event handlers
    Core.on("timer", function(timer_id)
        if timer_id == auto_save_timer then
            if dirty then
                Config.save()
            end
            auto_save_timer = os.startTimer(config_data.storage.save_interval)
        end
    end)
    
    Core.on("terminate", function()
        -- Save on program termination
        if dirty then
            Config.save()
        end
    end)
    
    initialized = true
    Core.info("Config module initialized")
    return true
end

-- Shutdown module
function Config.shutdown()
    if not initialized then
        return true
    end
    
    Core.debug("Shutting down Config module")
    
    -- Cancel auto-save timer
    if auto_save_timer then
        os.cancelTimer(auto_save_timer)
        auto_save_timer = nil
    end
    
    -- Save any pending changes
    if dirty then
        saveConfig()
    end
    
    initialized = false
    return true
end

return Config