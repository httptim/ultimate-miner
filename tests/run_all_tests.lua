-- Ultimate Miner Test Runner
-- Runs all available tests and provides a summary

-- Add module path
package.path = package.path .. ";/turtle/modules/?.lua;/?.lua"

print("=== Ultimate Miner Test Suite ===")
print("Running all tests...\n")

-- List of test files to run
local tests = {
    {name = "Core Module", file = "/tests/turtle/test_core.lua"},
    {name = "State Module", file = "/tests/turtle/test_state.lua"},
    {name = "Config Module", file = "/tests/turtle/test_config.lua"}
}

-- Track overall results
local total_tests = 0
local total_passed = 0
local total_failed = 0

-- Run each test
for _, test in ipairs(tests) do
    print("\n" .. string.rep("=", 40))
    print("Running: " .. test.name)
    print(string.rep("=", 40))
    
    if fs.exists(test.file) then
        -- Run the test file
        local success, err = pcall(function()
            shell.run(test.file)
        end)
        
        if not success then
            print("Test crashed: " .. tostring(err))
            total_failed = total_failed + 1
        end
        
        total_tests = total_tests + 1
    else
        print("Test file not found: " .. test.file)
        total_failed = total_failed + 1
        total_tests = total_tests + 1
    end
    
    -- Small pause between tests
    os.sleep(0.5)
end

-- Summary
print("\n" .. string.rep("=", 40))
print("=== OVERALL TEST SUMMARY ===")
print(string.rep("=", 40))
print("Total test suites: " .. total_tests)
print("Test suites passed: " .. (total_tests - total_failed))
print("Test suites failed: " .. total_failed)

if total_failed == 0 then
    print("\nAll test suites completed successfully! ✓")
else
    print("\nSome test suites failed! ✗")
end

print("\nNote: Run individual test files for detailed results.")