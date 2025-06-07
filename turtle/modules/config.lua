-- Config Module
-- Handles configuration management with defaults and validation

local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local CONSTANTS = require("shared.constants")

local Config = {}

-- Module state
local config = {}
local config_schema = {}
local initialized = false
local config_file = "turtle_config.cfg"

-- Default configuration schema with types and validation
local DEFAULT_SCHEMA = {
    -- Safety settings
    safety_radius = {
        type = "number",
        default = CONSTANTS.DEFAULTS.SAFETY_RADIUS,
        min = 10,
        max = 1000,
        description = "Maximum distance from home before returning"
    },
    fuel_reserve = {
        type = "number",
        default = CONSTANTS.DEFAULTS.FUEL_RESERVE,
        min = 100,
        max = 5000,
        description = "Fuel to keep in reserve for emergencies"
    },
    emergency_fuel = {
        type = "number",
        default = CONSTANTS.DEFAULTS.EMERGENCY_FUEL,
        min = 50,
        max = 1000,
        description = "Critical fuel level that triggers emergency return"
    },
    
    -- Mining settings
    torch_interval = {
        type = "number",
        default = CONSTANTS.DEFAULTS.TORCH_INTERVAL,
        min = 4,
        max = 16,
        description = "Blocks between torch placements"
    },
    strip_spacing = {
        type = "number",
        default = CONSTANTS.DEFAULTS.STRIP_SPACING,
        min = 2,
        max = 8,
        description = "Spacing between strip mining tunnels"
    },
    branch_length = {
        type = "number",
        default = CONSTANTS.DEFAULTS.BRANCH_LENGTH,
        min = 10,
        max = 200,
        description = "Length of branch mining tunnels"
    },
    quarry_size = {
        type = "number",
        default = CONSTANTS.DEFAULTS.QUARRY_SIZE,
        min = 4,
        max = 64,
        description = "Default quarry size (square)"
    },
    
    -- Network settings
    heartbeat_interval = {
        type = "number",
        default = CONSTANTS.DEFAULTS.HEARTBEAT_INTERVAL,
        min = 1,
        max = 30,
        description = "Seconds between heartbeat messages"
    },
    status_update_interval = {
        type = "number",
        default = CONSTANTS.DEFAULTS.STATUS_UPDATE_INTERVAL,
        min = 5,
        max = 60,
        description = "Seconds between status updates"
    },
    network_timeout = {
        type = "number",
        default = CONSTANTS.DEFAULTS.NETWORK_TIMEOUT,
        min = 10,
        max = 300,
        description = "Network operation timeout in seconds"
    },
    
    -- Performance settings
    max_path_history = {
        type = "number",
        default = CONSTANTS.DEFAULTS.MAX_PATH_HISTORY,
        min = 100,
        max = 5000,
        description = "Maximum path history entries to keep"
    },
    yield_interval = {
        type = "number",
        default = CONSTANTS.DEFAULTS.YIELD_INTERVAL,
        min = 10,
        max = 200,
        description = "Operations between yields to prevent timeout"
    },
    
    -- Feature toggles
    debug_mode = {
        type = "boolean",
        default = CONSTANTS.DEFAULTS.DEBUG_MODE,
        description = "Enable debug logging"
    },
    auto_refuel = {
        type = "boolean",
        default = true,
        description = "Automatically refuel from inventory"
    },
    ore_vein_mining = {
        type = "boolean",
        default = true,
        description = "Mine entire ore veins when found"
    },
    auto_torch = {
        type = "boolean",
        default = true,
        description = "Automatically place torches while mining"
    },
    safe_mining = {
        type = "boolean",
        default = true,
        description = "Enable all safety checks"
    },
    use_pathfinding = {
        type = "boolean",
        default = true,
        description = "Use A* pathfinding for navigation"
    },
    
    -- Navigation settings
    max_distance_from_home = {
        type = "number",
        default = 500,
        min = 50,
        max = 2000,
        description = "Maximum allowed distance from home position"
    },
    gps_check_interval = {
        type = "number",
        default = 300,
        min = 60,
        max = 3600,
        description = "Seconds between GPS position checks"
    },
    path_cache_size = {
        type = "number",
        default = 100,
        min = 10,
        max = 500,
        description = "Maximum cached pathfinding routes"
    },
    emergency_dig_mode = {
        type = "boolean",
        default = true,
        description = "Allow digging during emergency return"
    },
    
    -- Mining priorities
    ore_priority = {
        type = "table",
        default = {"diamond", "emerald", "gold", "iron", "redstone", "lapis", "coal", "copper"},
        description = "Ore mining priority order"
    },
    
    -- Custom patterns
    custom_patterns = {
        type = "table",
        default = {},
        description = "User-defined mining patterns"
    }
}

-- Initialize config module
function Config.init(filename)
    if filename then
        config_file = filename
    end
    
    -- Set up schema
    config_schema = DEFAULT_SCHEMA
    
    -- Load config from file or state
    local loaded = Config.load()
    if not loaded then
        -- Initialize with defaults
        config = {}
        for key, schema_entry in pairs(config_schema) do
            config[key] = schema_entry.default
        end
        Core.info("Config initialized with defaults")
    end
    
    -- Apply debug mode immediately
    if config.debug_mode then
        Core.init({debug = true})
    end
    
    initialized = true
    return true, "Config module initialized"
end

-- Validate a single config value
local function validateValue(key, value, schema_entry)
    -- Check type
    if type(value) ~= schema_entry.type then
        return false, string.format("Invalid type for %s: expected %s, got %s", 
            key, schema_entry.type, type(value))
    end
    
    -- Type-specific validation
    if schema_entry.type == "number" then
        if schema_entry.min and value < schema_entry.min then
            return false, string.format("%s must be at least %d", key, schema_entry.min)
        end
        if schema_entry.max and value > schema_entry.max then
            return false, string.format("%s must be at most %d", key, schema_entry.max)
        end
    elseif schema_entry.type == "string" then
        if schema_entry.pattern and not string.match(value, schema_entry.pattern) then
            return false, string.format("%s does not match required pattern", key)
        end
        if schema_entry.choices and not Core.tableContains(schema_entry.choices, value) then
            return false, string.format("%s must be one of: %s", key, table.concat(schema_entry.choices, ", "))
        end
    elseif schema_entry.type == "table" then
        if schema_entry.validate then
            return schema_entry.validate(value)
        end
    end
    
    return true
end

-- Get a config value
function Config.get(key, default)
    if not initialized then
        Core.warning("Config accessed before initialization")
        return default
    end
    
    -- Return nested config if no specific key
    if not key then
        return Core.deepCopy(config)
    end
    
    -- Handle nested keys
    local keys = {}
    for k in string.gmatch(key, "[^.]+") do
        table.insert(keys, k)
    end
    
    local current = config
    for _, k in ipairs(keys) do
        if type(current) ~= "table" or current[k] == nil then
            return default
        end
        current = current[k]
    end
    
    return current
end

-- Set a config value
function Config.set(key, value)
    if not initialized then
        return false, "Config module not initialized"
    end
    
    -- Check if key exists in schema
    local schema_entry = config_schema[key]
    if not schema_entry then
        Core.warning("Setting unregistered config key: " .. key)
    else
        -- Validate value
        local valid, err = validateValue(key, value, schema_entry)
        if not valid then
            return false, err
        end
    end
    
    -- Set the value
    config[key] = value
    
    -- Handle special cases
    if key == "debug_mode" then
        Core.init({debug = value})
    end
    
    Core.debug("Config updated: " .. key .. " = " .. tostring(value))
    
    -- Emit config change event
    Core.emit("config.changed", {key = key, value = value})
    
    return true
end

-- Save config to file
function Config.save()
    if not initialized then
        return false, "Config module not initialized"
    end
    
    -- Serialize config
    local serialized = textutils.serialize(config)
    if not serialized then
        return false, "Failed to serialize config"
    end
    
    -- Write to file
    local file, err = fs.open(config_file, "w")
    if not file then
        Core.error("Failed to open config file for writing: " .. tostring(err))
        return false, "Failed to open config file"
    end
    
    file.write(serialized)
    file.close()
    
    -- Also save to state
    State.set("config", config)
    
    Core.info("Config saved to " .. config_file)
    return true
end

-- Load config from file
function Config.load()
    -- Try loading from file first
    if fs.exists(config_file) then
        local file, err = fs.open(config_file, "r")
        if file then
            local content = file.readAll()
            file.close()
            
            if content and content ~= "" then
                local loaded_config = textutils.unserialize(content)
                if loaded_config then
                    config = loaded_config
                    Core.info("Config loaded from " .. config_file)
                    return true
                end
            end
        end
    end
    
    -- Try loading from state as fallback
    local state_config = State.get("config")
    if state_config and type(state_config) == "table" then
        config = state_config
        Core.info("Config loaded from state")
        return true
    end
    
    return false
end

-- Merge new config values
function Config.merge(new_config)
    if not initialized then
        return false, "Config module not initialized"
    end
    
    local errors = {}
    
    for key, value in pairs(new_config) do
        local success, err = Config.set(key, value)
        if not success then
            table.insert(errors, key .. ": " .. err)
        end
    end
    
    if #errors > 0 then
        return false, errors
    end
    
    return true
end

-- Reset config to defaults
function Config.reset()
    if not initialized then
        return false, "Config module not initialized"
    end
    
    config = {}
    for key, schema_entry in pairs(config_schema) do
        config[key] = schema_entry.default
    end
    
    Core.info("Config reset to defaults")
    return Config.save()
end

-- Validate entire config
function Config.validate()
    local errors = {}
    
    for key, value in pairs(config) do
        local schema_entry = config_schema[key]
        if schema_entry then
            local valid, err = validateValue(key, value, schema_entry)
            if not valid then
                table.insert(errors, err)
            end
        end
    end
    
    if #errors > 0 then
        return false, errors
    end
    
    return true, "Config is valid"
end

-- Set custom schema
function Config.setSchema(new_schema)
    config_schema = Core.mergeTables(config_schema, new_schema)
    Core.debug("Config schema updated")
    return true
end

-- Get config schema (for UI generation)
function Config.getSchema()
    return Core.deepCopy(config_schema)
end

-- Export config as string (for sharing)
function Config.export()
    local export_data = {
        version = CONSTANTS.VERSION,
        config = config
    }
    return textutils.serialize(export_data)
end

-- Import config from string
function Config.import(import_string)
    local import_data = textutils.unserialize(import_string)
    if not import_data or not import_data.config then
        return false, "Invalid import data"
    end
    
    -- Check version compatibility
    if import_data.version and import_data.version ~= CONSTANTS.VERSION then
        Core.warning("Importing config from different version: " .. import_data.version)
    end
    
    return Config.merge(import_data.config)
end

-- Register config change handler
function Config.onChange(key_pattern, handler)
    return Core.on("config.changed", function(data)
        if string.match(data.key, key_pattern) then
            handler(data.key, data.value)
        end
    end)
end

-- Convenience functions for common configs
function Config.isDebugMode()
    return Config.get("debug_mode", false)
end

function Config.getSafetyRadius()
    return Config.get("safety_radius", CONSTANTS.DEFAULTS.SAFETY_RADIUS)
end

function Config.getFuelReserve()
    return Config.get("fuel_reserve", CONSTANTS.DEFAULTS.FUEL_RESERVE)
end

function Config.getEmergencyFuel()
    return Config.get("emergency_fuel", CONSTANTS.DEFAULTS.EMERGENCY_FUEL)
end

return Config