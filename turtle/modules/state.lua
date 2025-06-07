-- State Module
-- Manages persistent state storage with backup and recovery

local Core = require("turtle.modules.core")
local CONSTANTS = require("shared.constants")

local State = {}

-- Module state
local current_state = {}
local state_file = "turtle_state.dat"
local backup_dir = "backups"
local max_backups = 3
local state_version = 1
local initialized = false

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
function State.init(filename)
    if filename then
        state_file = filename
    end
    
    -- Create backup directory if it doesn't exist
    if not fs.exists(backup_dir) then
        fs.makeDir(backup_dir)
    end
    
    -- Try to load existing state
    local success, loaded_state = State.load()
    if success and loaded_state then
        current_state = loaded_state
        Core.info("State loaded successfully from " .. state_file)
    else
        -- Initialize with defaults
        current_state = Core.deepCopy(DEFAULT_STATE)
        Core.info("State initialized with defaults")
        
        -- Save initial state
        State.save()
    end
    
    initialized = true
    return true, "State module initialized"
end

-- Calculate simple checksum for data validation
local function calculateChecksum(data)
    local str = textutils.serialize(data)
    local sum = 0
    for i = 1, #str do
        sum = sum + string.byte(str, i)
    end
    return sum % 65536  -- 16-bit checksum
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

-- Save state to disk with atomic write
function State.save()
    if not initialized then
        return false, "State module not initialized"
    end
    
    -- Update last save time
    current_state.last_save = os.epoch("utc")
    
    -- Add checksum
    local state_with_checksum = Core.deepCopy(current_state)
    state_with_checksum.checksum = calculateChecksum(current_state)
    
    -- Serialize state
    local serialized = textutils.serialize(state_with_checksum)
    if not serialized then
        return false, "Failed to serialize state"
    end
    
    -- Write to temporary file first (atomic write)
    local temp_file = state_file .. ".tmp"
    local file, err = fs.open(temp_file, "w")
    if not file then
        Core.error("Failed to open temp file for writing: " .. tostring(err))
        return false, "Failed to open temp file"
    end
    
    file.write(serialized)
    file.close()
    
    -- Create backup of current state file if it exists
    if fs.exists(state_file) then
        State.backup()
    end
    
    -- Move temp file to actual state file (atomic operation)
    if fs.exists(state_file) then
        fs.delete(state_file)
    end
    fs.move(temp_file, state_file)
    
    Core.debug("State saved successfully")
    return true, "State saved"
end

-- Load state from disk
function State.load()
    -- Check if state file exists
    if not fs.exists(state_file) then
        Core.debug("No state file found at " .. state_file)
        return false, "No state file found"
    end
    
    -- Read file
    local file, err = fs.open(state_file, "r")
    if not file then
        Core.error("Failed to open state file: " .. tostring(err))
        return false, "Failed to open state file"
    end
    
    local content = file.readAll()
    file.close()
    
    if not content or content == "" then
        Core.error("State file is empty")
        return false, "State file is empty"
    end
    
    -- Deserialize
    local state = textutils.unserialize(content)
    if not state then
        Core.error("Failed to deserialize state")
        -- Try to restore from backup
        return State.restore()
    end
    
    -- Verify checksum
    local saved_checksum = state.checksum
    state.checksum = nil  -- Remove checksum before validation
    
    local calculated_checksum = calculateChecksum(state)
    if saved_checksum ~= calculated_checksum then
        Core.error("State checksum mismatch! File may be corrupted")
        -- Try to restore from backup
        return State.restore()
    end
    
    -- Validate state
    local valid, err = State.validateState(state)
    if not valid then
        Core.error("State validation failed: " .. err)
        return State.restore()
    end
    
    -- Migrate if needed
    state, migrated = migrateState(state)
    if migrated then
        -- Save migrated state
        current_state = state
        State.save()
    end
    
    return true, state
end

-- Reset state to defaults
function State.reset()
    current_state = Core.deepCopy(DEFAULT_STATE)
    Core.info("State reset to defaults")
    return State.save()
end

-- Create backup of current state
function State.backup()
    if not fs.exists(state_file) then
        return false, "No state file to backup"
    end
    
    -- Generate backup filename with timestamp
    local timestamp = os.epoch("utc")
    local backup_file = fs.combine(backup_dir, "state_" .. timestamp .. ".bak")
    
    -- Copy current state to backup
    fs.copy(state_file, backup_file)
    
    -- Manage backup rotation
    local backups = fs.list(backup_dir)
    table.sort(backups)
    
    -- Remove old backups if we exceed max_backups
    while #backups > max_backups do
        local oldest = table.remove(backups, 1)
        fs.delete(fs.combine(backup_dir, oldest))
        Core.debug("Removed old backup: " .. oldest)
    end
    
    Core.debug("Backup created: " .. backup_file)
    return true, backup_file
end

-- Restore from backup
function State.restore(backup_file)
    -- If no specific backup file provided, use most recent
    if not backup_file then
        local backups = fs.list(backup_dir)
        if #backups == 0 then
            Core.error("No backups available to restore")
            return false, "No backups available"
        end
        
        -- Sort to get most recent
        table.sort(backups)
        backup_file = fs.combine(backup_dir, backups[#backups])
        Core.info("Restoring from most recent backup: " .. backup_file)
    end
    
    -- Check backup exists
    if not fs.exists(backup_file) then
        return false, "Backup file not found: " .. backup_file
    end
    
    -- Copy backup to state file
    if fs.exists(state_file) then
        fs.delete(state_file)
    end
    fs.copy(backup_file, state_file)
    
    -- Try to load the restored state
    return State.load()
end

-- Data operation functions
function State.set(key, value)
    if not initialized then
        return false
    end
    
    -- Handle nested keys (e.g., "position.x")
    local keys = {}
    for k in string.gmatch(key, "[^.]+") do
        table.insert(keys, k)
    end
    
    -- Navigate to the parent table
    local current = current_state
    for i = 1, #keys - 1 do
        if type(current[keys[i]]) ~= "table" then
            current[keys[i]] = {}
        end
        current = current[keys[i]]
    end
    
    -- Set the value
    current[keys[#keys]] = value
    
    Core.debug("State updated: " .. key .. " = " .. tostring(value))
    return true
end

function State.get(key, default)
    if not initialized then
        return default
    end
    
    -- Handle nested keys
    local keys = {}
    for k in string.gmatch(key, "[^.]+") do
        table.insert(keys, k)
    end
    
    -- Navigate to the value
    local current = current_state
    for _, k in ipairs(keys) do
        if type(current) ~= "table" or current[k] == nil then
            return default
        end
        current = current[k]
    end
    
    return current
end

function State.delete(key)
    return State.set(key, nil)
end

-- Convenience functions for common operations
function State.getPosition()
    return State.get("position", {x = 0, y = 0, z = 0, facing = 0})
end

function State.setPosition(pos)
    if Core.isValidPosition(pos) then
        State.set("position", pos)
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
    Core.info("Auto-save enabled with interval: " .. auto_save_interval .. "s")
end

function State.disableAutoSave()
    if auto_save_timer then
        os.cancelTimer(auto_save_timer)
        auto_save_timer = nil
        Core.info("Auto-save disabled")
    end
end

return State