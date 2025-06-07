-- State Module
-- Manages persistent state storage with backup and recovery

local Core = require("turtle.modules.core")
local CONSTANTS = require("shared.constants")
local Integrity = require("turtle.modules.integrity")

local State = {}

-- Module state
local current_state = {}
local state_dir = "/state"
local state_version = 1
local initialized = false
local state_files = {}

-- Default state structure
local DEFAULT_STATE = {
    version = state_version,
    position = {x = 0, y = 0, z = 0, facing = CONSTANTS.DIRECTIONS.NORTH},
    home = nil,
    fuel_used = 0,
    blocks_mined = 0,
    ores_found = {},
    start_time = os.epoch("utc"),
    last_save = os.epoch("utc"),
    current_task = nil,
    inventory_trips = 0,
    errors_encountered = 0,
    path_history = {},  -- Will be converted to circular buffer
    config = {}
}

-- Initialize state module
function State.init()
    -- Initialize integrity system first
    Integrity.init()
    
    -- Create state directory if it doesn't exist
    if not fs.exists(state_dir) then
        fs.makeDir(state_dir)
    end
    
    -- Define state files
    state_files = {
        main = fs.combine(state_dir, "main.json"),
        position = fs.combine(state_dir, "position.json"),
        mining = fs.combine(state_dir, "mining.json"),
        inventory = fs.combine(state_dir, "inventory.json"),
        network = fs.combine(state_dir, "network.json")
    }
    
    -- Load all state components
    current_state = {}
    for name, filepath in pairs(state_files) do
        local success, data = State.loadFile(name)
        if success then
            current_state[name] = data
        else
            -- Initialize with defaults for this component
            current_state[name] = State.getDefaultsForComponent(name)
        end
    end
    
    -- Ensure main state has required fields
    if not current_state.main then
        current_state.main = Core.deepCopy(DEFAULT_STATE)
    end
    
    initialized = true
    Core.log("INFO", "State module initialized with integrity protection")
    return true, "State module initialized"
end

-- Get default data for component
function State.getDefaultsForComponent(name)
    local defaults = {
        main = Core.deepCopy(DEFAULT_STATE),
        position = {
            x = 0, y = 0, z = 0,
            facing = CONSTANTS.DIRECTIONS.NORTH,
            confidence = 1.0,
            last_gps = nil
        },
        mining = {
            current_pattern = nil,
            blocks_mined = 0,
            ores_found = {},
            efficiency = 0,
            active = false
        },
        inventory = {
            last_update = os.clock(),
            slots = {},
            fuel_level = 0
        },
        network = {
            connected = false,
            last_heartbeat = 0,
            control_id = nil
        }
    }
    return defaults[name] or {}
end

-- Validate state structure
function State.validateState(state)
    if not state or type(state) ~= "table" then
        return false, "State must be a table"
    end
    
    -- Check required fields
    if not state.version then
        return false, "Missing version field"
    end
    
    if not Core.isValidPosition(state.position) then
        return false, "Invalid position data"
    end
    
    -- Validate numeric fields
    local numeric_fields = {"fuel_used", "blocks_mined", "inventory_trips", "errors_encountered"}
    for _, field in ipairs(numeric_fields) do
        if state[field] and type(state[field]) ~= "number" then
            return false, "Invalid " .. field .. " value"
        end
    end
    
    return true, "State is valid"
end

-- Migrate state from older versions
local function migrateState(state)
    local migrated = false
    
    -- Version 0 -> 1: Add new fields
    if state.version == nil or state.version < 1 then
        state.version = 1
        state.errors_encountered = state.errors_encountered or 0
        state.path_history = state.path_history or {}
        state.config = state.config or {}
        migrated = true
        Core.info("Migrated state from version " .. (state.version or 0) .. " to 1")
    end
    
    -- Future migrations would go here
    -- if state.version < 2 then ... end
    
    return state, migrated
end

-- Save specific component to disk with atomic write
function State.saveFile(name)
    if not initialized then
        return false, "State module not initialized"
    end
    
    local filepath = state_files[name]
    if not filepath then
        return false, "Unknown state component: " .. name
    end
    
    local data = current_state[name]
    if not data then
        return false, "No data for component: " .. name
    end
    
    -- Use integrity module for atomic write with checksum
    local success, err = Integrity.atomicWrite(filepath, data)
    if not success then
        Core.log("ERROR", "Failed to save " .. name .. ": " .. err)
        return false, err
    end
    
    Core.log("DEBUG", "Saved state component: " .. name)
    return true
end

-- Save all state components or specific component
function State.save(component_name, data)
    if not initialized then
        return false, "State module not initialized"
    end
    
    -- If specific component provided
    if component_name and data then
        current_state[component_name] = data
        return State.saveFile(component_name)
    end
    
    -- Otherwise save all components
    -- Update last save time in main state
    if current_state.main then
        current_state.main.last_save = os.epoch("utc")
    end
    
    -- Save each component
    local failures = {}
    for name, _ in pairs(state_files) do
        local success, err = State.saveFile(name)
        if not success then
            table.insert(failures, name .. ": " .. err)
        end
    end
    
    if #failures > 0 then
        Core.log("ERROR", "Failed to save some state components: " .. table.concat(failures, ", "))
        return false, "Partial save failure"
    end
    
    Core.log("DEBUG", "All state components saved successfully")
    return true, "State saved"
end

-- Save all state (alias for compatibility)
function State.saveAll()
    return State.save()
end

-- Load specific state file
function State.loadFile(name)
    local filepath = state_files[name]
    if not filepath then
        return false, "Unknown state component: " .. name
    end
    
    -- Use integrity module for read with checksum validation
    local success, data = Integrity.read(filepath)
    if not success then
        -- Try corruption recovery
        success, data = Integrity.recoverCorrupted(filepath)
        if not success then
            Core.log("WARNING", "Failed to load " .. name .. ", using defaults")
            return false, "Load failed"
        end
    end
    
    return true, data
end

-- Load all state components
function State.load()
    if not initialized then
        -- Initialize first
        State.init()
        return true, current_state
    end
    
    -- Load each component
    local loaded_count = 0
    for name, _ in pairs(state_files) do
        local success, data = State.loadFile(name)
        if success then
            current_state[name] = data
            loaded_count = loaded_count + 1
        else
            -- Use defaults for failed component
            current_state[name] = State.getDefaultsForComponent(name)
        end
    end
    
    -- Count total state files
    local total_files = 0
    for _, _ in pairs(state_files) do
        total_files = total_files + 1
    end
    
    Core.log("INFO", "Loaded " .. loaded_count .. "/" .. total_files .. " state components")
    return true, current_state
end

-- Reset state to defaults
function State.reset()
    -- Reset all components to defaults
    for name, _ in pairs(state_files) do
        current_state[name] = State.getDefaultsForComponent(name)
    end
    
    Core.log("INFO", "State reset to defaults")
    return State.save()
end

-- Verify all state files
function State.verify()
    return Integrity.verifyAll()
end

-- Restore state from backups if corrupted
function State.restore()
    Core.log("WARNING", "Attempting state restoration from backups")
    
    local restored_count = 0
    for name, filepath in pairs(state_files) do
        local success, data = Integrity.recoverCorrupted(filepath)
        if success then
            current_state[name] = data
            restored_count = restored_count + 1
        else
            -- Use defaults if recovery failed
            current_state[name] = State.getDefaultsForComponent(name)
        end
    end
    
    Core.log("INFO", "Restored " .. restored_count .. " state components")
    return restored_count > 0
end

-- Data operation functions
function State.set(key, value)
    if not initialized then
        return false
    end
    
    -- Handle component-based keys (e.g., "main.position.x" or "position.x")
    local keys = {}
    for k in string.gmatch(key, "[^.]+") do
        table.insert(keys, k)
    end
    
    -- Determine component
    local component = "main"  -- Default component
    local start_idx = 1
    
    -- Check if first key is a known component
    if state_files[keys[1]] then
        component = keys[1]
        start_idx = 2
    end
    
    -- Ensure component exists
    if not current_state[component] then
        current_state[component] = State.getDefaultsForComponent(component)
    end
    
    -- Navigate to the parent table
    local current = current_state[component]
    for i = start_idx, #keys - 1 do
        if type(current[keys[i]]) ~= "table" then
            current[keys[i]] = {}
        end
        current = current[keys[i]]
    end
    
    -- Set the value
    if #keys >= start_idx then
        current[keys[#keys]] = value
    else
        -- Setting entire component
        current_state[component] = value
    end
    
    Core.log("DEBUG", "State updated: " .. key .. " = " .. tostring(value))
    return true
end

function State.get(key, default)
    if not initialized then
        return default
    end
    
    -- Handle component-based keys
    local keys = {}
    for k in string.gmatch(key, "[^.]+") do
        table.insert(keys, k)
    end
    
    -- Determine component
    local component = "main"
    local start_idx = 1
    
    -- Check if first key is a known component
    if state_files[keys[1]] then
        component = keys[1]
        start_idx = 2
    end
    
    -- Check component exists
    if not current_state[component] then
        return default
    end
    
    -- Navigate to the value
    local current = current_state[component]
    for i = start_idx, #keys do
        if type(current) ~= "table" or current[keys[i]] == nil then
            return default
        end
        current = current[keys[i]]
    end
    
    return current
end

function State.delete(key)
    return State.set(key, nil)
end

-- Convenience functions for common operations
function State.getPosition()
    local pos = State.get("position", {x = 0, y = 0, z = 0, facing = 0})
    -- Ensure numeric values
    if pos then
        pos.x = tonumber(pos.x) or 0
        pos.y = tonumber(pos.y) or 0
        pos.z = tonumber(pos.z) or 0
        pos.facing = tonumber(pos.facing) or 0
    end
    return pos
end

function State.setPosition(pos)
    if Core.isValidPosition(pos) then
        -- Ensure numeric values before saving
        local clean_pos = {
            x = tonumber(pos.x) or pos.x,
            y = tonumber(pos.y) or pos.y,
            z = tonumber(pos.z) or pos.z,
            facing = tonumber(pos.facing) or pos.facing
        }
        State.set("position", clean_pos)
        -- Also save position component immediately for safety
        State.save("position", current_state.position)
        return true
    end
    return false
end

function State.incrementCounter(counter_name, amount)
    amount = amount or 1
    local current = State.get(counter_name, 0)
    State.set(counter_name, current + amount)
    return current + amount
end

function State.addToHistory(history_name, item, max_items)
    max_items = max_items or CONSTANTS.DEFAULTS.MAX_PATH_HISTORY
    local history = State.get(history_name, {})
    
    -- Ensure it's a table
    if type(history) ~= "table" then
        history = {}
    end
    
    -- Add item
    table.insert(history, item)
    
    -- Trim to max size
    while #history > max_items do
        table.remove(history, 1)
    end
    
    State.set(history_name, history)
end

-- Get the entire state (for debugging/inspection)
function State.getAll()
    return Core.deepCopy(current_state)
end

-- Auto-save functionality
local auto_save_timer = nil
local auto_save_interval = 60  -- Save every minute

function State.enableAutoSave(interval)
    auto_save_interval = interval or 60
    
    if auto_save_timer then
        os.cancelTimer(auto_save_timer)
    end
    
    local function scheduleAutoSave()
        auto_save_timer = os.startTimer(auto_save_interval)
    end
    
    -- Start auto-save loop
    Core.on("timer", function(timer_id)
        if timer_id == auto_save_timer then
            State.save()
            scheduleAutoSave()
        end
    end)
    
    scheduleAutoSave()
    Core.log("INFO", "Auto-save enabled with interval: " .. auto_save_interval .. "s")
end

function State.disableAutoSave()
    if auto_save_timer then
        os.cancelTimer(auto_save_timer)
        auto_save_timer = nil
        Core.log("INFO", "Auto-save disabled")
    end
end

return State