-- Test crash reporting
print("Testing Ultimate Miner crash reporting...")
print()

-- Set up paths like startup does
package.path = package.path .. ";/?;/?.lua;/?/init.lua"
package.path = package.path .. ";/shared/?.lua;/shared/?/init.lua"

-- Load error reporter
local ErrorReporter = require("shared.error_reporter")
ErrorReporter.init()

print("1. Testing error logging...")
ErrorReporter.logError("TEST", "This is a test error", "Test stack trace")
print("   Error logged")

print("\n2. Testing crash simulation...")
local function causeError()
    error("Simulated crash for testing")
end

local success, err = xpcall(causeError, function(error_msg)
    local stack = debug and debug.traceback and debug.traceback(error_msg, 2) or "No stack trace"
    
    print("\n=== SIMULATED CRASH ===")
    print("Error: " .. error_msg)
    
    -- Log it
    ErrorReporter.logError("CRASH", error_msg, stack, {test = true})
    
    -- Try upload
    print("\nUploading crash report...")
    local ok, code = ErrorReporter.uploadToPastebin("Test Crash Report")
    
    if ok then
        print("\n=== SUCCESS ===")
        print("Pastebin Code: " .. code)
        print("URL: https://pastebin.com/" .. code)
        print("\nError reporting is working!")
    else
        print("\n=== UPLOAD FAILED ===")
        print("Reason: " .. code)
        print("But error was saved locally to: /ultimate_miner_errors.log")
    end
end)

print("\nTest complete!")
print("Check /ultimate_miner_errors.log for saved errors")