-- Test Framework for Ultimate Miner Phase 10
-- Simple but comprehensive testing framework for CC:Tweaked

local test_framework = {}

-- Test state
local test_state = {
    tests = {},
    results = {},
    current_suite = nil,
    verbose = false
}

-- ANSI color codes (if supported)
local colors = {
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    reset = "\27[0m"
}

-- Check if colors are supported
local function supportsColor()
    return term and term.isColor and term.isColor()
end

-- Print with color
local function printColor(text, color)
    if supportsColor() and colors[color] then
        print(colors[color] .. text .. colors.reset)
    else
        print(text)
    end
end

-- Create test suite
function test_framework.suite(name)
    test_state.current_suite = name
    test_state.tests[name] = test_state.tests[name] or {}
    return test_framework
end

-- Add test to current suite
function test_framework.test(name, test_func)
    if not test_state.current_suite then
        error("No test suite selected. Use suite() first.")
    end
    
    table.insert(test_state.tests[test_state.current_suite], {
        name = name,
        func = test_func
    })
    
    return test_framework
end

-- Assertion functions
test_framework.assert = {}

function test_framework.assert.equals(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s\nExpected: %s\nActual: %s",
            message or "Values not equal",
            tostring(expected),
            tostring(actual)
        ))
    end
end

function test_framework.assert.notEquals(actual, expected, message)
    if actual == expected then
        error(string.format("%s\nValue should not equal: %s",
            message or "Values should not be equal",
            tostring(expected)
        ))
    end
end

function test_framework.assert.isTrue(value, message)
    if value ~= true then
        error(message or "Expected true, got " .. tostring(value))
    end
end

function test_framework.assert.isFalse(value, message)
    if value ~= false then
        error(message or "Expected false, got " .. tostring(value))
    end
end

function test_framework.assert.isNil(value, message)
    if value ~= nil then
        error(message or "Expected nil, got " .. tostring(value))
    end
end

function test_framework.assert.notNil(value, message)
    if value == nil then
        error(message or "Expected non-nil value")
    end
end

function test_framework.assert.tableEquals(actual, expected, message)
    local function deepEquals(t1, t2)
        if type(t1) ~= "table" or type(t2) ~= "table" then
            return t1 == t2
        end
        
        for k, v in pairs(t1) do
            if not deepEquals(v, t2[k]) then
                return false
            end
        end
        
        for k in pairs(t2) do
            if t1[k] == nil then
                return false
            end
        end
        
        return true
    end
    
    if not deepEquals(actual, expected) then
        error(string.format("%s\nTables are not equal",
            message or "Table comparison failed"
        ))
    end
end

function test_framework.assert.contains(table, value, message)
    for _, v in pairs(table) do
        if v == value then
            return
        end
    end
    error(message or "Table does not contain value: " .. tostring(value))
end

function test_framework.assert.throws(func, message)
    local success, err = pcall(func)
    if success then
        error(message or "Expected function to throw an error")
    end
end

function test_framework.assert.doesNotThrow(func, message)
    local success, err = pcall(func)
    if not success then
        error(string.format("%s\nError: %s",
            message or "Function should not throw",
            tostring(err)
        ))
    end
end

-- Mock creation
function test_framework.mock(object)
    local mock = {}
    local calls = {}
    
    setmetatable(mock, {
        __index = function(t, k)
            return function(...)
                calls[k] = calls[k] or {}
                table.insert(calls[k], {...})
                
                -- Return mock value if set
                if object and object[k] then
                    return object[k]
                end
            end
        end
    })
    
    mock._calls = calls
    mock._wasCalled = function(method)
        return calls[method] ~= nil and #calls[method] > 0
    end
    mock._callCount = function(method)
        return calls[method] and #calls[method] or 0
    end
    mock._lastCall = function(method)
        return calls[method] and calls[method][#calls[method]] or nil
    end
    mock._reset = function()
        calls = {}
        mock._calls = calls
    end
    
    return mock
end

-- Spy on existing function
function test_framework.spy(object, method)
    local original = object[method]
    local calls = {}
    
    object[method] = function(...)
        table.insert(calls, {...})
        return original(...)
    end
    
    return {
        restore = function()
            object[method] = original
        end,
        calls = calls,
        callCount = function()
            return #calls
        end,
        lastCall = function()
            return calls[#calls]
        end
    }
end

-- Run specific test
local function runTest(suite_name, test)
    local start_time = os.clock()
    local success, error_msg = pcall(test.func)
    local duration = os.clock() - start_time
    
    local result = {
        suite = suite_name,
        name = test.name,
        success = success,
        error = error_msg,
        duration = duration
    }
    
    table.insert(test_state.results, result)
    
    if test_state.verbose then
        if success then
            printColor("  ✓ " .. test.name .. " (" .. string.format("%.3f", duration) .. "s)", "green")
        else
            printColor("  ✗ " .. test.name, "red")
            printColor("    " .. tostring(error_msg), "red")
        end
    end
    
    return success
end

-- Run all tests
function test_framework.run(options)
    options = options or {}
    test_state.verbose = options.verbose ~= false
    test_state.results = {}
    
    local total_tests = 0
    local passed_tests = 0
    local failed_tests = 0
    local total_duration = 0
    
    printColor("\nRunning Ultimate Miner Tests...\n", "blue")
    
    for suite_name, tests in pairs(test_state.tests) do
        if test_state.verbose then
            printColor(suite_name .. ":", "yellow")
        end
        
        for _, test in ipairs(tests) do
            total_tests = total_tests + 1
            
            if runTest(suite_name, test) then
                passed_tests = passed_tests + 1
            else
                failed_tests = failed_tests + 1
            end
        end
        
        if test_state.verbose then
            print("")  -- Empty line between suites
        end
    end
    
    -- Calculate total duration
    for _, result in ipairs(test_state.results) do
        total_duration = total_duration + result.duration
    end
    
    -- Print summary
    printColor(string.rep("-", 40), "blue")
    print(string.format("Tests: %d total, %d passed, %d failed",
        total_tests, passed_tests, failed_tests))
    print(string.format("Duration: %.3fs", total_duration))
    
    if failed_tests > 0 then
        printColor("\nFailed tests:", "red")
        for _, result in ipairs(test_state.results) do
            if not result.success then
                printColor(string.format("  %s > %s", result.suite, result.name), "red")
                print("    " .. tostring(result.error))
            end
        end
    else
        printColor("\nAll tests passed!", "green")
    end
    
    return {
        total = total_tests,
        passed = passed_tests,
        failed = failed_tests,
        duration = total_duration,
        results = test_state.results
    }
end

-- Get test results
function test_framework.getResults()
    return test_state.results
end

-- Clear all tests
function test_framework.clear()
    test_state.tests = {}
    test_state.results = {}
    test_state.current_suite = nil
end

-- Export results to file
function test_framework.exportResults(filename)
    filename = filename or "/logs/test_results.txt"
    
    local file = fs.open(filename, "w")
    if not file then
        return false, "Failed to open file"
    end
    
    file.writeLine("Ultimate Miner Test Results")
    file.writeLine("Generated: " .. os.date())
    file.writeLine(string.rep("=", 40))
    file.writeLine("")
    
    -- Group results by suite
    local suites = {}
    for _, result in ipairs(test_state.results) do
        suites[result.suite] = suites[result.suite] or {}
        table.insert(suites[result.suite], result)
    end
    
    -- Write results by suite
    for suite_name, results in pairs(suites) do
        file.writeLine(suite_name .. ":")
        
        for _, result in ipairs(results) do
            local status = result.success and "PASS" or "FAIL"
            file.writeLine(string.format("  [%s] %s (%.3fs)",
                status, result.name, result.duration))
            
            if not result.success then
                file.writeLine("    Error: " .. tostring(result.error))
            end
        end
        
        file.writeLine("")
    end
    
    -- Write summary
    local total = #test_state.results
    local passed = 0
    local total_duration = 0
    
    for _, result in ipairs(test_state.results) do
        if result.success then
            passed = passed + 1
        end
        total_duration = total_duration + result.duration
    end
    
    file.writeLine("Summary:")
    file.writeLine(string.format("  Total: %d", total))
    file.writeLine(string.format("  Passed: %d", passed))
    file.writeLine(string.format("  Failed: %d", total - passed))
    file.writeLine(string.format("  Duration: %.3fs", total_duration))
    
    file.close()
    return true
end

return test_framework