-- Global Error Handler for Ultimate Miner
-- Wraps main functions with error catching and reporting

local ErrorHandler = {}
local ErrorReporter = nil  -- Lazy load to avoid circular dependencies

-- Initialize error reporter on first use
local function ensureErrorReporter()
    if not ErrorReporter then
        ErrorReporter = require("shared.error_reporter")
        ensureErrorReporter().init()
    end
    return ErrorReporter
end

-- Wrap a function with error handling
function ErrorHandler.wrap(func, context_name)
    return function(...)
        local args = {...}
        local success, result = xpcall(
            function() return func(table.unpack(args)) end,
            function(err)
                -- Get stack trace (if debug library available)
                local stack = debug and debug.traceback and debug.traceback(err, 2) or "Stack trace unavailable"
                
                -- Log the error
                ensureErrorReporter().logError(
                    "RUNTIME",
                    err,
                    stack,
                    {
                        context = context_name,
                        args = textutils.serialize(args)
                    }
                )
                
                -- Re-throw for normal error handling
                error(err, 0)
            end
        )
        
        if success then
            return result
        else
            error(result, 0)
        end
    end
end

-- Protected call with error logging
function ErrorHandler.pcall(func, ...)
    local args = {...}
    local success, result = xpcall(
        function() return func(table.unpack(args)) end,
        function(err)
            local stack = debug and debug.traceback and debug.traceback(err, 2) or "Stack trace unavailable"
            ensureErrorReporter().logError("PCALL", err, stack)
            return err
        end
    )
    
    return success, result
end

-- Create error report command
function ErrorHandler.createErrorReport()
    local summary = ensureErrorReporter().getSummary()
    
    print("\n=== Error Report Summary ===")
    print("Total Errors: " .. summary.total_errors)
    print("Session ID: " .. summary.session_id)
    print("Log File: " .. summary.log_file)
    
    if summary.total_errors > 0 then
        print("\nErrors by Type:")
        for error_type, count in pairs(summary.errors_by_type) do
            print("  " .. error_type .. ": " .. count)
        end
        
        print("\nUploading to pastebin...")
        local success, code = ensureErrorReporter().uploadToPastebin()
        
        if success then
            print("\n=== UPLOAD SUCCESSFUL ===")
            print("Pastebin URL: https://pastebin.com/" .. code)
            print("Pastebin Code: " .. code)
            print("\nShare this code when reporting issues!")
            
            -- Also save to file for easy access
            local file = fs.open("/error_report_code.txt", "w")
            if file then
                file.writeLine("Ultimate Miner Error Report")
                file.writeLine("Pastebin Code: " .. code)
                file.writeLine("URL: https://pastebin.com/" .. code)
                file.writeLine("Generated: " .. os.date())
                file.close()
            end
        else
            print("\n=== UPLOAD FAILED ===")
            print("Reason: " .. code)
            print("Error log saved locally at: " .. summary.log_file)
        end
    else
        print("\nNo errors logged in this session!")
    end
    
    print("\nPress any key to continue...")
    os.pullEvent("key")
end

-- Global error handler setup
function ErrorHandler.setupGlobalHandler()
    -- Override error function to capture all errors
    local original_error = error
    _G.error = function(message, level)
        -- Log the error
        local stack = debug and debug.traceback and debug.traceback(message, (level or 1) + 1) or "Stack trace unavailable"
        ensureErrorReporter().logError("ERROR", tostring(message), stack)
        
        -- Call original error
        original_error(message, level)
    end
    
    -- Add crash handler
    _G.crashWithReport = function(error_msg)
        ensureErrorReporter().createCrashReport(error_msg, debug and debug.traceback and debug.traceback() or "Stack trace unavailable")
    end
end

return ErrorHandler