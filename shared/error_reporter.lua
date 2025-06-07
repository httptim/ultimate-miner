-- Error Reporter Module
-- Captures errors to file and uploads to pastebin

local ErrorReporter = {}

-- Configuration
local ERROR_LOG_FILE = "/ultimate_miner_errors.log"
local MAX_ERROR_SIZE = 50000  -- Max size before rotation
local PASTEBIN_API = "https://pastebin.com/api/api_post.php"

-- Module state
local error_buffer = {}
local error_count = 0
local session_id = tostring(os.epoch("utc"))

-- Initialize error reporter
function ErrorReporter.init()
    -- Create or append to error log
    local file = fs.open(ERROR_LOG_FILE, fs.exists(ERROR_LOG_FILE) and "a" or "w")
    if file then
        file.writeLine("\n=== Ultimate Miner Error Log ===")
        file.writeLine("Session: " .. session_id)
        file.writeLine("Started: " .. os.date())
        file.writeLine("Version: 3.0.0")
        file.writeLine("Device: " .. (turtle and "Turtle" or "Computer"))
        file.writeLine("=====================================\n")
        file.close()
    end
    
    return true
end

-- Log an error
function ErrorReporter.logError(error_type, message, stack_trace, context)
    error_count = error_count + 1
    
    local error_entry = {
        id = error_count,
        timestamp = os.epoch("utc"),
        date = os.date(),
        type = error_type or "UNKNOWN",
        message = message or "No message provided",
        stack = stack_trace,
        context = context or {},
        device = turtle and "turtle" or "computer"
    }
    
    -- Add to buffer
    table.insert(error_buffer, error_entry)
    
    -- Write to file
    local file = fs.open(ERROR_LOG_FILE, "a")
    if file then
        file.writeLine(string.format("[ERROR #%d] %s", error_entry.id, error_entry.date))
        file.writeLine("Type: " .. error_entry.type)
        file.writeLine("Message: " .. error_entry.message)
        
        if error_entry.stack then
            file.writeLine("Stack trace:")
            file.writeLine(error_entry.stack)
        end
        
        if error_entry.context and next(error_entry.context) then
            file.writeLine("Context:")
            for k, v in pairs(error_entry.context) do
                file.writeLine("  " .. tostring(k) .. ": " .. tostring(v))
            end
        end
        
        file.writeLine("---")
        file.close()
    end
    
    -- Check file size and rotate if needed
    if fs.exists(ERROR_LOG_FILE) and fs.getSize(ERROR_LOG_FILE) > MAX_ERROR_SIZE then
        ErrorReporter.rotateLog()
    end
    
    -- Print to console
    print("[ERROR] " .. error_entry.message)
    print("Error logged to: " .. ERROR_LOG_FILE)
    
    return error_entry.id
end

-- Rotate log file
function ErrorReporter.rotateLog()
    if fs.exists(ERROR_LOG_FILE) then
        local backup_name = ERROR_LOG_FILE .. ".old"
        if fs.exists(backup_name) then
            fs.delete(backup_name)
        end
        fs.move(ERROR_LOG_FILE, backup_name)
    end
end

-- Upload errors to pastebin
function ErrorReporter.uploadToPastebin(title)
    if not http then
        return false, "HTTP API not enabled"
    end
    
    title = title or "Ultimate Miner Error Report - " .. os.date()
    
    -- Read error log
    if not fs.exists(ERROR_LOG_FILE) then
        return false, "No error log found"
    end
    
    local file = fs.open(ERROR_LOG_FILE, "r")
    if not file then
        return false, "Cannot read error log"
    end
    
    local content = file.readAll()
    file.close()
    
    -- Add system information
    local report = "=== Ultimate Miner Error Report ===\n"
    report = report .. "Version: 3.0.0\n"
    report = report .. "Session: " .. session_id .. "\n"
    report = report .. "Device: " .. (turtle and "Turtle" or "Computer") .. "\n"
    report = report .. "Error Count: " .. error_count .. "\n"
    report = report .. "\n" .. content
    
    print("Uploading error report to pastebin...")
    
    -- Upload to pastebin
    local response = http.post(
        PASTEBIN_API,
        "api_dev_key=" .. textutils.urlEncode("0b2f1315f464e2a5e8eab609951c8a59") ..  -- Public API key
        "&api_option=paste" ..
        "&api_paste_code=" .. textutils.urlEncode(report) ..
        "&api_paste_name=" .. textutils.urlEncode(title) ..
        "&api_paste_format=lua" ..
        "&api_paste_private=1" ..  -- Unlisted
        "&api_paste_expire_date=1W"  -- Expire in 1 week
    )
    
    if response then
        local paste_id = response.readAll()
        response.close()
        
        -- Extract paste ID from URL if full URL is returned
        local paste_code = paste_id:match("pastebin%.com/(.+)$") or paste_id
        
        -- Save paste info
        local info_file = fs.open("/pastebin_info.txt", "w")
        if info_file then
            info_file.writeLine("=== Pastebin Upload Info ===")
            info_file.writeLine("URL: https://pastebin.com/" .. paste_code)
            info_file.writeLine("Code: " .. paste_code)
            info_file.writeLine("Uploaded: " .. os.date())
            info_file.writeLine("Errors: " .. error_count)
            info_file.close()
        end
        
        return true, paste_code
    else
        return false, "Failed to upload to pastebin"
    end
end

-- Get error summary
function ErrorReporter.getSummary()
    local summary = {
        total_errors = error_count,
        session_id = session_id,
        log_file = ERROR_LOG_FILE,
        errors_by_type = {}
    }
    
    -- Count errors by type
    for _, error in ipairs(error_buffer) do
        local error_type = error.type
        summary.errors_by_type[error_type] = (summary.errors_by_type[error_type] or 0) + 1
    end
    
    return summary
end

-- Clear error log
function ErrorReporter.clearLog()
    error_buffer = {}
    error_count = 0
    
    if fs.exists(ERROR_LOG_FILE) then
        fs.delete(ERROR_LOG_FILE)
    end
    
    return true
end

-- Get recent errors
function ErrorReporter.getRecentErrors(count)
    count = count or 10
    local recent = {}
    
    local start_idx = math.max(1, #error_buffer - count + 1)
    for i = start_idx, #error_buffer do
        table.insert(recent, error_buffer[i])
    end
    
    return recent
end

-- Create crash report
function ErrorReporter.createCrashReport(error_msg, stack_trace)
    print("\n=== CRASH DETECTED ===")
    print("Creating crash report...")
    
    -- Log the crash
    ErrorReporter.logError("CRASH", error_msg, stack_trace, {
        memory_used = collectgarbage("count"),
        uptime = os.clock()
    })
    
    -- Try to upload to pastebin
    local success, result = ErrorReporter.uploadToPastebin("Ultimate Miner Crash Report")
    
    if success then
        print("\n=== CRASH REPORT UPLOADED ===")
        print("Pastebin URL: https://pastebin.com/" .. result)
        print("Pastebin Code: " .. result)
        print("\nPlease report this code at:")
        print("https://github.com/httptim/ultimate-miner/issues")
    else
        print("\n=== CRASH REPORT SAVED ===")
        print("Error log saved to: " .. ERROR_LOG_FILE)
        print("Upload failed: " .. result)
        print("\nPlease manually share the error log at:")
        print("https://github.com/httptim/ultimate-miner/issues")
    end
    
    print("\nPress any key to continue...")
    os.pullEvent("key")
    
    return success, result
end

return ErrorReporter