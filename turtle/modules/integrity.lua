-- Data Integrity Module
-- Triple backup system with checksum validation and atomic writes

local Core = require("turtle.modules.core")

local Integrity = {}

-- Constants
local BACKUP_COUNT = 3
local CHECKSUM_ALGORITHM = "crc32"
local VERSION = "2.4.0"
local TEMP_SUFFIX = ".tmp"
local BACKUP_SUFFIX = ".bak"

-- CRC32 implementation for checksum
local CRC32 = {}
CRC32.table = {}

-- Initialize CRC32 table
function CRC32.init()
    for i = 0, 255 do
        local c = i
        for j = 0, 7 do
            if bit32.band(c, 1) == 1 then
                c = bit32.bxor(bit32.rshift(c, 1), 0xEDB88320)
            else
                c = bit32.rshift(c, 1)
            end
        end
        CRC32.table[i] = c
    end
end

-- Calculate CRC32 checksum
function CRC32.calculate(data)
    if #CRC32.table == 0 then
        CRC32.init()
    end
    
    local crc = 0xFFFFFFFF
    for i = 1, #data do
        local byte = string.byte(data, i)
        local idx = bit32.band(bit32.bxor(crc, byte), 0xFF)
        crc = bit32.bxor(bit32.rshift(crc, 8), CRC32.table[idx])
    end
    
    return bit32.bxor(crc, 0xFFFFFFFF)
end

-- Initialize integrity system
function Integrity.init()
    Core.log("INFO", "Initializing data integrity system")
    
    -- Initialize CRC32 table
    CRC32.init()
    
    -- Check and migrate existing data
    Integrity.migrateData()
    
    return true
end

-- Atomic write operation
function Integrity.atomicWrite(filepath, data)
    local temp_path = filepath .. TEMP_SUFFIX
    
    -- Serialize data if it's a table
    local content
    if type(data) == "table" then
        content = textutils.serialize(data)
    else
        content = tostring(data)
    end
    
    -- Calculate checksum
    local checksum = CRC32.calculate(content)
    
    -- Create data package with metadata
    local package = {
        version = VERSION,
        checksum = checksum,
        timestamp = os.clock(),
        data = data
    }
    
    local package_content = textutils.serialize(package)
    
    -- Write to temporary file
    local file = fs.open(temp_path, "w")
    if not file then
        Core.log("ERROR", "Failed to open temp file for atomic write: " .. temp_path)
        return false, "Failed to open temp file"
    end
    
    file.write(package_content)
    file.close()
    
    -- Verify temp file
    local verify_file = fs.open(temp_path, "r")
    if not verify_file then
        Core.log("ERROR", "Failed to verify temp file: " .. temp_path)
        fs.delete(temp_path)
        return false, "Failed to verify temp file"
    end
    
    local verify_content = verify_file.readAll()
    verify_file.close()
    
    -- Verify content matches
    if verify_content ~= package_content then
        Core.log("ERROR", "Temp file content mismatch")
        fs.delete(temp_path)
        return false, "Content verification failed"
    end
    
    -- Atomic rename (move temp to actual)
    fs.delete(filepath)  -- Delete old file if exists
    fs.move(temp_path, filepath)
    
    -- Create backups
    Integrity.createBackups(filepath, package_content)
    
    Core.log("DEBUG", "Atomic write completed: " .. filepath)
    return true
end

-- Create triple backups
function Integrity.createBackups(filepath, content)
    for i = 1, BACKUP_COUNT do
        local backup_path = filepath .. BACKUP_SUFFIX .. i
        
        -- Rotate backups
        if i > 1 then
            local prev_backup = filepath .. BACKUP_SUFFIX .. (i - 1)
            if fs.exists(prev_backup) then
                fs.delete(backup_path)
                fs.copy(prev_backup, backup_path)
            end
        end
    end
    
    -- Write new backup
    local first_backup = filepath .. BACKUP_SUFFIX .. "1"
    local file = fs.open(first_backup, "w")
    if file then
        file.write(content)
        file.close()
        Core.log("DEBUG", "Created backup: " .. first_backup)
    end
end

-- Read with checksum validation
function Integrity.read(filepath)
    -- Try main file first
    local success, data = Integrity.readAndValidate(filepath)
    if success then
        return true, data
    end
    
    Core.log("WARNING", "Main file corrupted, trying backups: " .. filepath)
    
    -- Try backups
    for i = 1, BACKUP_COUNT do
        local backup_path = filepath .. BACKUP_SUFFIX .. i
        if fs.exists(backup_path) then
            success, data = Integrity.readAndValidate(backup_path)
            if success then
                Core.log("INFO", "Recovered from backup " .. i .. ": " .. filepath)
                
                -- Restore main file from backup
                fs.delete(filepath)
                fs.copy(backup_path, filepath)
                
                return true, data
            end
        end
    end
    
    Core.log("ERROR", "All backups corrupted for: " .. filepath)
    return false, "All files corrupted"
end

-- Read and validate single file
function Integrity.readAndValidate(filepath)
    if not fs.exists(filepath) then
        return false, "File not found"
    end
    
    local file = fs.open(filepath, "r")
    if not file then
        return false, "Failed to open file"
    end
    
    local content = file.readAll()
    file.close()
    
    -- Parse package
    local success, package = pcall(textutils.unserialize, content)
    if not success then
        Core.log("ERROR", "Failed to deserialize: " .. filepath)
        return false, "Deserialization failed"
    end
    
    -- Check structure
    if type(package) ~= "table" or not package.data or not package.checksum then
        Core.log("ERROR", "Invalid package structure: " .. filepath)
        return false, "Invalid structure"
    end
    
    -- Validate checksum
    local data_content
    if type(package.data) == "table" then
        data_content = textutils.serialize(package.data)
    else
        data_content = tostring(package.data)
    end
    
    local calculated_checksum = CRC32.calculate(data_content)
    
    if calculated_checksum ~= package.checksum then
        Core.log("ERROR", "Checksum mismatch: " .. filepath)
        Core.log("ERROR", "Expected: " .. package.checksum .. ", Got: " .. calculated_checksum)
        return false, "Checksum mismatch"
    end
    
    return true, package.data, package
end

-- Version migration system
function Integrity.migrateData()
    Core.log("INFO", "Checking for data migration needs")
    
    local state_dir = "/state"
    if not fs.exists(state_dir) then
        return
    end
    
    -- Get all state files
    local files = fs.list(state_dir)
    local migrated = 0
    
    for _, filename in ipairs(files) do
        if not filename:match("%.bak") and not filename:match("%.tmp") then
            local filepath = fs.combine(state_dir, filename)
            local success, data, package = Integrity.readAndValidate(filepath)
            
            if success and package then
                -- Check version
                if not package.version or package.version < VERSION then
                    Core.log("INFO", "Migrating " .. filename .. " from version " .. 
                            (package.version or "unknown") .. " to " .. VERSION)
                    
                    -- Perform migration
                    local migrated_data = Integrity.migrateDataStructure(data, package.version)
                    
                    -- Save with new version
                    Integrity.atomicWrite(filepath, migrated_data)
                    migrated = migrated + 1
                end
            elseif fs.exists(filepath) then
                -- Try to read as legacy format
                local file = fs.open(filepath, "r")
                if file then
                    local content = file.readAll()
                    file.close()
                    
                    local legacy_success, legacy_data = pcall(textutils.unserialize, content)
                    if legacy_success and legacy_data then
                        Core.log("INFO", "Converting legacy file: " .. filename)
                        
                        -- Save in new format
                        Integrity.atomicWrite(filepath, legacy_data)
                        migrated = migrated + 1
                    end
                end
            end
        end
    end
    
    if migrated > 0 then
        Core.log("INFO", "Migrated " .. migrated .. " files to version " .. VERSION)
    end
end

-- Migrate data structure based on version
function Integrity.migrateDataStructure(data, from_version)
    -- Add migration logic here based on version changes
    -- Example migrations:
    
    if not from_version or from_version < "2.0.0" then
        -- Migrate from pre-2.0 structure
        if data.position and not data.position.dimension then
            data.position.dimension = "overworld"
        end
    end
    
    if not from_version or from_version < "2.3.0" then
        -- Migrate from pre-2.3 structure
        if data.mining and not data.mining.patterns then
            data.mining.patterns = {
                current = data.mining.pattern or "strip"
            }
        end
    end
    
    return data
end

-- Corruption recovery
function Integrity.recoverCorrupted(filepath)
    Core.log("WARNING", "Attempting corruption recovery for: " .. filepath)
    
    -- Try each backup
    for i = 1, BACKUP_COUNT do
        local backup_path = filepath .. BACKUP_SUFFIX .. i
        
        if fs.exists(backup_path) then
            -- Try to read raw content
            local file = fs.open(backup_path, "r")
            if file then
                local content = file.readAll()
                file.close()
                
                -- Attempt partial recovery
                local recovered_data = Integrity.attemptPartialRecovery(content)
                if recovered_data then
                    Core.log("INFO", "Partial recovery successful from backup " .. i)
                    
                    -- Save recovered data
                    Integrity.atomicWrite(filepath, recovered_data)
                    return true, recovered_data
                end
            end
        end
    end
    
    -- If all else fails, return default data structure
    Core.log("ERROR", "Full recovery failed, returning defaults")
    local defaults = Integrity.getDefaultData(filepath)
    
    -- Save defaults
    Integrity.atomicWrite(filepath, defaults)
    return true, defaults
end

-- Attempt partial recovery from corrupted content
function Integrity.attemptPartialRecovery(content)
    -- Try different recovery strategies
    
    -- Strategy 1: Find JSON-like structures
    local start_pos = content:find("{")
    local end_pos = content:reverse():find("}")
    
    if start_pos and end_pos then
        end_pos = #content - end_pos + 1
        local subset = content:sub(start_pos, end_pos)
        
        local success, data = pcall(textutils.unserialize, subset)
        if success and type(data) == "table" then
            Core.log("INFO", "Recovered data using subset extraction")
            return data
        end
    end
    
    -- Strategy 2: Try to fix common corruption patterns
    local fixed_content = content
    
    -- Fix truncated strings
    fixed_content = fixed_content:gsub('"[^"]*$', '""')
    
    -- Fix unclosed brackets
    local open_braces = select(2, fixed_content:gsub("{", ""))
    local close_braces = select(2, fixed_content:gsub("}", ""))
    
    if open_braces > close_braces then
        fixed_content = fixed_content .. string.rep("}", open_braces - close_braces)
    end
    
    local success, data = pcall(textutils.unserialize, fixed_content)
    if success and type(data) == "table" then
        Core.log("INFO", "Recovered data using corruption fixes")
        return data
    end
    
    return nil
end

-- Get default data structure based on filename
function Integrity.getDefaultData(filepath)
    local filename = fs.getName(filepath)
    
    -- Return appropriate defaults based on file
    if filename == "position.json" then
        return {
            x = 0, y = 0, z = 0,
            facing = 0,
            dimension = "overworld"
        }
    elseif filename == "mining.json" then
        return {
            patterns = {current = "strip"},
            statistics = {blocks_mined = 0},
            active = false
        }
    elseif filename == "inventory.json" then
        return {
            last_update = os.clock(),
            slots = {}
        }
    else
        return {}
    end
end

-- Verify all state files
function Integrity.verifyAll()
    local state_dir = "/state"
    if not fs.exists(state_dir) then
        return true, {}
    end
    
    local files = fs.list(state_dir)
    local results = {}
    local all_valid = true
    
    for _, filename in ipairs(files) do
        if not filename:match("%.bak") and not filename:match("%.tmp") then
            local filepath = fs.combine(state_dir, filename)
            local success, _, package = Integrity.readAndValidate(filepath)
            
            results[filename] = {
                valid = success,
                version = package and package.version or "unknown",
                checksum = package and package.checksum or 0
            }
            
            if not success then
                all_valid = false
            end
        end
    end
    
    return all_valid, results
end

-- Get backup status
function Integrity.getBackupStatus(filepath)
    local status = {
        main = fs.exists(filepath),
        backups = {}
    }
    
    for i = 1, BACKUP_COUNT do
        local backup_path = filepath .. BACKUP_SUFFIX .. i
        status.backups[i] = {
            exists = fs.exists(backup_path),
            size = fs.exists(backup_path) and fs.getSize(backup_path) or 0
        }
    end
    
    return status
end

-- Clean up old backups
function Integrity.cleanup()
    Core.log("INFO", "Cleaning up old backups")
    
    local state_dir = "/state"
    if not fs.exists(state_dir) then
        return
    end
    
    local files = fs.list(state_dir)
    local cleaned = 0
    
    for _, filename in ipairs(files) do
        -- Remove temp files
        if filename:match("%.tmp$") then
            fs.delete(fs.combine(state_dir, filename))
            cleaned = cleaned + 1
        end
        
        -- Remove excess backups
        local backup_num = filename:match("%.bak(%d+)$")
        if backup_num and tonumber(backup_num) > BACKUP_COUNT then
            fs.delete(fs.combine(state_dir, filename))
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        Core.log("INFO", "Cleaned up " .. cleaned .. " files")
    end
end

return Integrity