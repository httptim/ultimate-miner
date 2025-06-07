-- Test Error Reporting System
-- Run this to test the error logging and pastebin upload

print("=== Ultimate Miner Error Reporting Test ===")
print()

-- Load error handler
local ErrorReporter = require("shared.error_reporter")
local ErrorHandler = require("shared.error_handler")

-- Initialize
ErrorReporter.init()
print("Error reporter initialized")

-- Test 1: Log some errors
print("\n1. Testing error logging...")
ErrorReporter.logError("TEST", "This is a test error", "Test stack trace", {test = true})
ErrorReporter.logError("NETWORK", "Failed to connect to turtle", nil, {turtle_id = 123})
ErrorReporter.logError("MINING", "Cannot mine bedrock", "at mining.lua:42", {pos = "10,64,20"})
print("   Logged 3 test errors")

-- Test 2: Show summary
print("\n2. Error summary:")
local summary = ErrorReporter.getSummary()
print("   Total errors: " .. summary.total_errors)
print("   Log file: " .. summary.log_file)

-- Test 3: Test upload
print("\n3. Testing pastebin upload...")
print("   (This requires HTTP API to be enabled)")
print()
write("Upload error report to pastebin? (y/n): ")
local answer = read()

if answer:lower() == "y" then
    local success, code = ErrorReporter.uploadToPastebin("Ultimate Miner Test Report")
    if success then
        print("\n=== SUCCESS ===")
        print("Pastebin URL: https://pastebin.com/" .. code)
        print("Pastebin Code: " .. code)
        print("\nYou can view the error report at the URL above!")
    else
        print("\n=== FAILED ===")
        print("Error: " .. code)
        print("Make sure HTTP API is enabled in ComputerCraft config")
    end
else
    print("Upload skipped")
end

-- Test 4: Show how to use in code
print("\n4. Example usage in your code:")
print("   ErrorHandler.createErrorReport()  -- Creates full report")
print("   crashWithReport('Error message')  -- For crashes")
print()
print("Test complete! Error log saved at: " .. summary.log_file)